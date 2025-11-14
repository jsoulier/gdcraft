class_name Block extends Node

enum Type {
	GRASS,
	DIRT,
	STONE,
	WATER,
	LOG,
	LEAVES,
	SAND,
	COUNT,
	EMPTY,
}

enum Face {
	FORWARD,
	BACK,
	LEFT,
	RIGHT,
	UP,
	DOWN,
	COUNT,
}

static func get_normal(face: Face) -> Vector3i:
	match face:
		# TODO: why are these reversed?
		Face.FORWARD:
			return Vector3i.BACK
		Face.BACK:
			return Vector3i.FORWARD
		Face.LEFT:
			return Vector3i.LEFT
		Face.RIGHT:
			return Vector3i.RIGHT
		Face.UP:
			return Vector3i.UP
		Face.DOWN:
			return Vector3i.DOWN
	return Vector3i.FORWARD

static func get_vertices(face: Face) -> Array[Vector3]:
	match face:
		Face.FORWARD:
			return [Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 0, 1), Vector3(0, 0, 1)]
		Face.BACK:
			return [Vector3(1, 1, 0), Vector3(0, 1, 0), Vector3(0, 0, 0), Vector3(1, 0, 0)]
		Face.LEFT:
			return [Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(0, 0, 1), Vector3(0, 0, 0)]
		Face.RIGHT:
			return [Vector3(1, 1, 1), Vector3(1, 1, 0), Vector3(1, 0, 0), Vector3(1, 0, 1)]
		Face.UP:
			return [Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(0, 1, 1)]
		Face.DOWN:
			return [Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, 0)]

	return [Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0)]

static func get_face_index(type: Type, face: Face) -> Vector2:
	match type:
		Type.GRASS:
			match face:
				Face.UP:
					return Vector2(0, 0)
				Face.DOWN:
					return Vector2(1, 0)
				_:
					return Vector2(2, 0)
		Type.DIRT:
			return Vector2(1, 0)
		Type.STONE:
			return Vector2(3, 0)
		Type.WATER:
			return Vector2(4, 0)
		Type.LOG:
			match face:
				Face.UP, Face.DOWN:
					return Vector2(5, 0)
				_:
					return Vector2(6, 0)
		Type.LEAVES:
			return Vector2(7, 0)
		Type.SAND:
			return Vector2(8, 0)
	return Vector2i(0, 0)

static func get_texcoords(face: Face) -> Array[Vector2]:
	match face:
		Face.FORWARD:
			return [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		Face.BACK:
			return [Vector2(1, 0), Vector2(0, 0), Vector2(0, 1), Vector2(1, 1)]
		Face.LEFT:
			return [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		Face.RIGHT:
			return [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		Face.UP:
			return [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		Face.DOWN:
			return [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	return [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]

static func is_transparent(type: Type) -> bool:
	match type:
		Type.WATER:
			return true
	return false

static func get_indices() -> Array[int]:
	return [0, 1, 2, 0, 2, 3]

static func is_visible(lhs: Type, rhs: Type) -> bool:
	return not is_transparent(lhs) and is_transparent(rhs)

static func _test_is_visible():
	assert(not is_visible(Type.GRASS, Type.GRASS))
	assert(not is_visible(Type.GRASS, Type.DIRT))
	assert(not is_visible(Type.DIRT, Type.DIRT))
	assert(not is_visible(Type.DIRT, Type.GRASS))
	assert(is_visible(Type.GRASS, Type.WATER))
	assert(is_visible(Type.DIRT, Type.WATER))
	assert(not is_visible(Type.WATER, Type.WATER))
	assert(not is_visible(Type.WATER, Type.GRASS))
