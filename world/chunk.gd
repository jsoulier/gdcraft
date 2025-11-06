class_name Chunk extends StaticBody3D

const WIDTH = 32
const HEIGHT = 32
const SIZE = Vector3i(WIDTH, HEIGHT, WIDTH)

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
	var chunk_position = Vector3(_index * SIZE)
	var vertices: Array[Vector3] = []
	for index in _blocks:
		var block_type = _blocks[index]
		for i in range(Block.Face.COUNT):
			var block_position = Vector3(index)
			var face = i as Block.Face
			var normal = Block.get_normal(face)
			# TODO: look up neighbour
			if not Block.is_visible(block_type, block_type):
				continue
			# TODO: check if a face should be emitted
			var block_vertices = Block.get_vertices(face)
			var block_face_index = Block.get_face_index(block_type, face)
			var block_texcoords2 = Block.get_texcoords(face)
			surface_tool.set_normal(Vector3(normal))
			var start = vertices.size()
			for j in range(4):
				var vertex = chunk_position + block_position + block_vertices[j]
				# TODO: in the shader, convert uvs to a texture layer index
				surface_tool.set_uv(block_face_index)
				surface_tool.set_uv2(block_texcoords2[j])
				surface_tool.add_vertex(vertex)
				vertices.append(vertex)
			surface_tool.add_index(start)
			surface_tool.add_index(start + 1)
			surface_tool.add_index(start + 2)
			surface_tool.add_index(start)
			surface_tool.add_index(start + 2)
			surface_tool.add_index(start + 3)
	var array_mesh = surface_tool.commit()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = array_mesh
	mesh_instance.material_override = _world.material
	add_child.call_deferred(mesh_instance)
	#var polygon_shape = ConcavePolygonShape3D.new()
	#polygon_shape.data = collider_vertices
	#var collision_shape = CollisionShape3D.new()
	#collision_shape.shape = polygon_shape
	#add_child.call_deferred(collision_shape)
