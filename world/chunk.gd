class_name Chunk extends StaticBody3D

const _WIDTH = 32
const _HEIGHT = 32
const _SIZE = Vector3i(_WIDTH, _HEIGHT, _WIDTH)

var _blocks: Dictionary[Vector3i, Block.Type] = {}
var _world = null
var _index: Vector3i

func _init(world, index: Vector3i) -> void:
	_world = world
	_index = index
	create(true)

func create(new_chunk: bool) -> void:
	if new_chunk:
		_blocks = _world.generator.generate(_index)
	else:
		_world.remove_child(self)
		for child in get_children():
			remove_child(child)
			child.queue_free()
	# TODO: threadpool for create
	_create()
	_world.add_child(self)

func _create() -> void:
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
			var block_normal = Block.get_normal(block_face)
			# TODO: look up neighbour
			if not Block.is_visible(block_type, block_type):
				continue
			# TODO: check if a face should be emitted
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