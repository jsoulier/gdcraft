class_name Chunk extends StaticBody3D

enum Flag {
	NONE = 0,
	GENERATE = 0x01,
	MESH = 0x02,
	UNLOAD = 0x04,
}

const _WIDTH = 32
const _HEIGHT = 32
const _SIZE = Vector3i(_WIDTH, _HEIGHT, _WIDTH)

var _blocks: Dictionary[Vector3i, Block.Type] = {}
var _world = null
var _index: Vector3i
var _flags = Flag.NONE

func _init(world, index: Vector3i) -> void:
	_world = world
	_index = index
	set_flag(Flag.GENERATE)
	set_flag(Flag.MESH)

func generate() -> void:
	assert(has_flag(Flag.GENERATE))
	clear_flag(Flag.GENERATE)
	_blocks = _world.generator.generate(_index)

func mesh() -> void:
	assert(!has_flag(Flag.GENERATE))
	assert(has_flag(Flag.MESH))
	clear_flag(Flag.MESH)
	if _world.is_ancestor_of(self):
		_world.remove_child(self)
		for child in get_children():
			remove_child(child)
			child.queue_free()
	# TODO: threadpool for create
	_mesh()
	_world.add_child(self)

func _in_bounds(index: Vector3i) -> bool:
	return \
		index.x >= 0 and \
		index.y >= 0 and \
		index.z >= 0 and \
		index.x < _SIZE.x and \
		index.y < _SIZE.y and \
		index.z < _SIZE.z

func get_block(index: Vector3i) -> Block.Type:
	return _blocks.get(index, Block.Type.COUNT)

func _get_local_position(index: Vector3i) -> Vector3i:
	return (index % _SIZE + _SIZE) % _SIZE

func set_flag(flag: Flag) -> void:
	_flags = (_flags | flag) as Flag

func clear_flag(flag: Flag) -> void:
	_flags = (_flags & (~flag as int)) as Flag

func has_flag(flag: Flag) -> bool:
	return bool(_flags & flag)

func _mesh() -> void:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var chunk_position = Vector3(_index * _SIZE)
	var chunk_vertices: Array[Vector3] = []
	for index in _blocks:
		var block_type = _blocks[index]
		for i in range(Block.Face.COUNT):
			var first_index = chunk_vertices.size()
			var block_position = Vector3(index)
			var block_face = i as Block.Face
			if block_position.y == 0 and block_face == Block.Face.DOWN:
				continue
			var block_normal = Block.get_normal(block_face)
			var neighbor_position = index + block_normal
			var neighbor_type = Block.Type.COUNT
			if _in_bounds(neighbor_position):
				neighbor_type = get_block(neighbor_position)
			else:
				var neighbor_chunk_index = _index + block_normal
				var neighbor_chunk = _world.get_chunk(neighbor_chunk_index)
				if neighbor_chunk != null && not neighbor_chunk.has_flag(Flag.GENERATE):
					var local_position = _get_local_position(neighbor_position)
					neighbor_type = neighbor_chunk.get_block(local_position)
			if neighbor_type != Block.Type.COUNT:
				if not Block.is_visible(block_type, neighbor_type):
					continue
			var block_vertices = Block.get_vertices(block_face)
			var block_face_index = Block.get_face_index(block_type, block_face)
			var block_texcoords = Block.get_texcoords(block_face)
			var block_indices = Block.get_indices()
			assert(block_vertices.size() == 4)
			assert(block_texcoords.size() == 4)
			assert(block_indices.size() == 6)
			surface_tool.set_normal(block_normal)
			for j in range(4):
				var vertex = chunk_position + block_position + block_vertices[j]
				surface_tool.set_uv(block_face_index)
				surface_tool.set_uv2(block_texcoords[j])
				surface_tool.add_vertex(vertex)
				chunk_vertices.append(vertex)
			for j in range(6):
				surface_tool.add_index(first_index + block_indices[j])
	var array_mesh = surface_tool.commit()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = array_mesh
	mesh_instance.material_override = _world.chunk_material
	add_child.call_deferred(mesh_instance)
