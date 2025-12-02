class_name Chunk
extends StaticBody3D

const WIDTH = 10
const HEIGHT = 128
const SIZE = Vector3i(WIDTH, HEIGHT, WIDTH)

enum Flag {
	NONE       = 0,
	GENERATING = 0b00000001,
	GENERATED  = 0b00000010,
	EXPOSED    = 0b00000100,
	MESHING    = 0b00001000,
	MESHED     = 0b00010000,
	WORKING    = GENERATING | MESHING,
}

enum MeshType {
	OPAQUE,
	TRANSPARENT,
	SPRITE,
	COUNT,
}

var _world = null
var _index: Vector3i
var _flags = Flag.NONE
var _all_blocks: Dictionary[Vector3i, Block.Type] = {}
var _exposed_blocks: Dictionary[Vector3i, bool] = {}
var _lights: Dictionary[Vector3i, OmniLight3D] = {}

func _init(world, index: Vector3i) -> void:
	_world = world
	_index = index

func set_flag(flag: Flag) -> void:
	assert(not has_flag(flag))
	_flags = (_flags | flag) as Flag
	
func clear_flag(flag: Flag) -> void:
	assert(has_flag(flag))
	_flags = (_flags & ~flag) as Flag
	
func has_flag(flag: Flag) -> bool:
	assert(flag as int > 0)
	return _flags & flag

static func in_bounds(index: Vector3i) -> bool:
	return index.x >= 0 and index.x < SIZE.x and index.y >= 0 \
		and index.y < SIZE.y and index.z >= 0 and index.z < SIZE.z

func get_block(index: Vector3i) -> Block.Type:
	assert(in_bounds(index))
	return _all_blocks.get(index, Block.Type.EMPTY)

func _get_local_position(index: Vector3i) -> Vector3i:
	# TODO: same as (index - face * SIZE)
	return (index % SIZE + SIZE) % SIZE

func _get_block(index: Vector3i, face: Vector3i) -> Block.Type:
	index += face 
	if in_bounds(index):
		return get_block(index)
	assert(face.y != -1)
	if face.y == 1:
		return Block.Type.EMPTY
	var neighbor_chunk_index = _index + face
	var neighbor_chunk = _world.get_chunk(neighbor_chunk_index)
	assert(neighbor_chunk.has_flag(Flag.GENERATED))
	var neighbor_index = _get_local_position(index)
	return neighbor_chunk.get_block(neighbor_index)

func _expose_neighbor(index: Vector3i, face: Vector3i) -> void:
	assert(in_bounds(index))
	index += face
	assert(not in_bounds(index))
	if face.y != 0:
		return
	var neighbor_chunk_index = _index + face
	var neighbor_chunk = _world.get_chunk(neighbor_chunk_index)
	assert(not neighbor_chunk.has_flag(Flag.WORKING))
	assert(neighbor_chunk.has_flag(Flag.GENERATED))
	var neighbor_index = _get_local_position(index)
	if neighbor_chunk.get_block(neighbor_index) != Block.Type.EMPTY:
		# TODO: not accurate
		neighbor_chunk._exposed_blocks[neighbor_index] = false

func _exposed(index: Vector3i) -> bool:
	assert(in_bounds(index))
	var block = _all_blocks.get(index, Block.Type.EMPTY)
	if block == Block.Type.EMPTY:
		return false
	if Block.is_sprite(block):
		return true
	for face in range(Face.Type.COUNT):
		if _skip_face(index, face):
			continue
		var vector = Face.get_vector(face)
		var neighbor_block = _get_block(index, vector)
		if Block.is_exposed(block, neighbor_block):
			_exposed_blocks[index] = false
			return true
	return false

func set_block(index: Vector3i, type: Block.Type) -> void:
	assert(has_flag(Flag.GENERATED))
	assert(has_flag(Flag.EXPOSED))
	assert(has_flag(Flag.MESHED))
	assert(not has_flag(Flag.WORKING))
	assert(in_bounds(index))
	if type == Block.Type.EMPTY:
		_all_blocks.erase(index)
	else:
		_all_blocks[index] = type
	if _exposed(index):
		_exposed_blocks[index] = false
	else:
		_exposed_blocks.erase(index)
	for face in range(Face.Type.COUNT):
		var vector = Face.get_vector(face)
		var neighbor_index = index + vector
		if not in_bounds(neighbor_index):
			_expose_neighbor(index, vector)
			continue
		_exposed_blocks.erase(neighbor_index)
		if _exposed(neighbor_index):
			_exposed_blocks[neighbor_index] = false
	set_light(index, type)
	clear_flag(Chunk.Flag.MESHED)

func set_light(index: Vector3i, type: Block.Type) -> void:
	var light = _lights.get(index, null)
	if light:
		remove_child(light)
	_lights.erase(index)
	if not Block.is_light(type):
		return
	light = OmniLight3D.new()
	light.light_color = Block.get_light_color(type)
	light.position = Vector3(_index * SIZE + index) + Vector3.ONE / 2
	var strength = Block.get_light_strength(type)
	light.omni_range = strength.x
	light.omni_attenuation = strength.y
	light.light_energy = strength.z
	add_child.call_deferred(light)
	_lights[index] = light

func generate() -> void:
	assert(!has_flag(Flag.GENERATED))
	assert(!has_flag(Flag.MESHED))
	assert(!has_flag(Flag.WORKING))
	set_flag(Flag.GENERATING)
	var task_id = WorkerThreadPool.add_task(_generate)
	_world.add_task_id(task_id)

func mesh(async: bool, force = false) -> void:
	assert(has_flag(Flag.GENERATED))
	assert(!has_flag(Flag.WORKING))
	if force and has_flag(Flag.MESHED):
		clear_flag(Flag.MESHED)
	assert(!has_flag(Flag.MESHED))
	for child in get_children():
		if child is OmniLight3D:
			continue
		remove_child(child)
		child.queue_free()
	set_flag(Flag.MESHING)
	if not async:
		_mesh()
		return
	var task_id = WorkerThreadPool.add_task(_mesh)
	_world.add_task_id(task_id)

func _generate() -> void:
	_all_blocks = _world.generator.generate(_index)
	var blocks = _world.database.get_blocks(_index)
	for block in blocks:
		assert(block.type != Block.Type.EMPTY)
		var index = Vector3i(block.block_x, block.block_y, block.block_z)
		assert(in_bounds(index))
		_all_blocks[index] = block.type
		set_light(index, block.type)
	_end_generate.call_deferred(WorkerThreadPool.get_caller_task_id())

func _mesh() -> void:
	if not has_flag(Flag.EXPOSED):
		_expose()
	var _meshes = []
	for type in range(MeshType.COUNT):
		_meshes.append(_create_mesh_arrays())
	for index in _exposed_blocks:
		var block = _all_blocks.get(index, Block.Type.EMPTY)
		assert(block != Block.Type.EMPTY)
		if Block.is_sprite(block):
			for face in range(4):
				_emit_face(_meshes[MeshType.SPRITE], index, block, face)
			continue
		for face in range(Face.Type.COUNT):
			if _skip_face(index, face):
				continue
			var vector = Face.get_vector(face)
			var neighbor_block = _get_block(index, vector)
			if not Block.is_exposed(block, neighbor_block):
				continue
			if not Block.is_transparent(block):
				_emit_face(_meshes[MeshType.OPAQUE], index, block, face)
			else:
				_emit_face(_meshes[MeshType.TRANSPARENT], index, block, face)
	for type in range(MeshType.COUNT):
		var mesh_instance = _create_mesh_instance(_meshes[type], type)
		if not mesh_instance:
			continue
		if type == MeshType.SPRITE:
			mesh_instance.cast_shadow = false
		add_child.call_deferred(mesh_instance)
	var collision_shape = _create_collision_shape(_meshes[MeshType.OPAQUE])
	add_child.call_deferred(collision_shape)
	_end_mesh.call_deferred(WorkerThreadPool.get_caller_task_id())

func _end_generate(task_id: int) -> void:
	clear_flag(Flag.GENERATING)
	set_flag(Flag.GENERATED)
	assert(not has_flag(Flag.MESHING))
	assert(not has_flag(Flag.MESHED))
	assert(task_id > 0)
	_world.remove_task_id(task_id)

func _end_mesh(task_id: int) -> void:
	assert(not has_flag(Flag.GENERATING))
	assert(has_flag(Flag.GENERATED))
	clear_flag(Flag.MESHING)
	set_flag(Flag.MESHED)
	if task_id > 0:
		_world.remove_task_id(task_id)

func _expose() -> void:
	assert(has_flag(Flag.GENERATED))
	assert(not has_flag(Flag.EXPOSED))
	assert(not has_flag(Flag.MESHED))
	assert(_exposed_blocks.is_empty())
	for index in _all_blocks:
		var block = _all_blocks.get(index)
		assert(block != Block.Type.EMPTY)
		if _exposed(index):
			_exposed_blocks[index] = false
	set_flag(Flag.EXPOSED)

func _emit_face(arrays: Array, index: Vector3i, type: Block.Type, face: Face.Type) -> void:
	var start_index = arrays[Mesh.ARRAY_VERTEX].size()
	var location = Vector3(_index * SIZE + index)
	for i in range(4):
		arrays[Mesh.ARRAY_VERTEX].append(location + Block.get_vertex(type, face, i))
		arrays[Mesh.ARRAY_NORMAL].append(Block.get_normal(type, face))
		arrays[Mesh.ARRAY_TEX_UV].append(Block.get_texcoord(type, face))
		arrays[Mesh.ARRAY_TEX_UV2].append(Block.get_texcoord2(type, face, i))
	for i in Block.get_indices():
		arrays[Mesh.ARRAY_INDEX].append(start_index + i)

func _skip_face(index: Vector3i, face: Face.Type):
	return index.y == 0 and _index.y == 0 and face == Face.Type.DOWN

func _create_mesh_arrays() -> Array:
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([])
	arrays[Mesh.ARRAY_TEX_UV2] = PackedVector2Array([])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([])
	return arrays

func _create_mesh_instance(arrays: Array, type: MeshType) -> MeshInstance3D:
	var array_mesh = ArrayMesh.new()
	if arrays[Mesh.ARRAY_VERTEX].is_empty():
		return null
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = array_mesh
	match type:
		MeshType.OPAQUE:
			mesh_instance.material_override = GDCraftResources.opaque_material
		MeshType.TRANSPARENT:
			mesh_instance.material_override = GDCraftResources.transparent_material
		MeshType.SPRITE:
			mesh_instance.material_override = GDCraftResources.sprite_material
	return mesh_instance

func _create_collision_shape(arrays: Array) -> CollisionShape3D:
	var vertices = PackedVector3Array()
	for i in range(0, arrays[Mesh.ARRAY_VERTEX].size(), 4):
		for j in Block.get_indices():
			vertices.append(arrays[Mesh.ARRAY_VERTEX][i + j])
	var concave_polygon_shape = ConcavePolygonShape3D.new()
	concave_polygon_shape.set_faces(vertices)
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = concave_polygon_shape
	return collision_shape
