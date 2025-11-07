class_name Chunk extends StaticBody3D

enum Flag {
	NONE = 0,
	GENERATE = 0x01,
	MESH = 0x02,
	UNLOAD = 0x04,
}

const WIDTH = 32
const HEIGHT = 32
const SIZE = Vector3i(WIDTH, HEIGHT, WIDTH)

var _blocks: PackedInt32Array
var _world = null
var _index: Vector3i
var _flags = Flag.NONE
var task_id = 0

func _init(world, index: Vector3i) -> void:
	_world = world
	_index = index
	set_flag(Flag.GENERATE)
	set_flag(Flag.MESH)
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if task_id >= 1:
			WorkerThreadPool.wait_for_task_completion(task_id)
			task_id = 0

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
	task_id = WorkerThreadPool.add_task(_mesh, true)

func _in_bounds(index: Vector3i) -> bool:
	return \
		index.x >= 0 and \
		index.y >= 0 and \
		index.z >= 0 and \
		index.x < SIZE.x and \
		index.y < SIZE.y and \
		index.z < SIZE.z

static func get_block_index(index: Vector3i) -> int:
	return index.x + index.y * WIDTH + index.z * WIDTH * HEIGHT

func get_block(index: Vector3i) -> Block.Type:
	return _blocks[get_block_index(index)] as Block.Type

func _get_local_position(index: Vector3i) -> Vector3i:
	return (index % SIZE + SIZE) % SIZE

func set_flag(flag: Flag) -> void:
	_flags = (_flags | flag) as Flag

func clear_flag(flag: Flag) -> void:
	_flags = (_flags & (~flag as int)) as Flag

func has_flag(flag: Flag) -> bool:
	return bool(_flags & flag)

func _mesh() -> void:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var chunk_position = Vector3(_index * SIZE)
	var chunk_vertices: Array[Vector3] = []
	for x in range(Chunk.WIDTH):
		for y in range(Chunk.HEIGHT):
			for z in range(Chunk.WIDTH):
				var index = Vector3i(x, y, z)
				var block_type = get_block(index)
				if block_type == Block.Type.EMPTY:
					continue
				for i in range(Block.Face.COUNT):
					var first_index = chunk_vertices.size()
					var block_position = Vector3(index)
					var block_face = i as Block.Face
					if block_position.y == 0 and block_face == Block.Face.DOWN:
						continue
					var block_normal = Block.get_normal(block_face)
					var neighbor_position = index + block_normal
					var neighbor_type = Block.Type.EMPTY
					if _in_bounds(neighbor_position):
						neighbor_type = get_block(neighbor_position)
					else:
						var neighbor_chunk_index = _index + block_normal
						var neighbor_chunk = _world.get_chunk(neighbor_chunk_index)
						if neighbor_chunk != null && not neighbor_chunk.has_flag(Flag.GENERATE):
							var local_position = _get_local_position(neighbor_position)
							neighbor_type = neighbor_chunk.get_block(local_position)
					if neighbor_type != Block.Type.EMPTY:
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
	_world.add_child.call_deferred(self)
