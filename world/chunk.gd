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
		_world.remove_child(self)
		_blocks = _world.generator.generate(_index)
	else:
		for child in get_children():
			remove_child(child)
			child.queue_free()
	# TODO: threadpool for create
	_create()
	_world.add_child(self)

func _create() -> void:
	var surface_tool = SurfaceTool.new()
	var chunk_position = _index * SIZE
	var collider_vertices: Array[Vector3] = []
	for index in _blocks:
		var block_type = _blocks[index]
		for i in range(Block.Face.COUNT):
			var face = i as Block.Face
			var normal = Block.get_normal(face)
			# TODO: look up neighbour
			if Block.is_visible(block_type, block_type):
				continue
			# TODO: check if a face should be emitted
			var vertices = Block.get_vertices(face)
			surface_tool.set_normal(Vector3(normal))
			for vertex in vertices:
				vertex += chunk_position
				surface_tool.add_vertex(vertex)
				collider_vertices.append(vertex)
	surface_tool.index()
	var array_mesh = surface_tool.commit()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = array_mesh
	add_child.call_deferred(mesh_instance)
	var polygon_shape = ConcavePolygonShape3D.new()
	polygon_shape.data = collider_vertices
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = polygon_shape
	add_child.call_deferred(collision_shape)
