class_name Block extends Node

enum Type {
	GRASS,
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

static func get_normal(face: Face) -> Vector3:
	match face:
		Face.FORWARD:
			return Vector3.FORWARD
		Face.BACK:
			return Vector3.BACK
		Face.LEFT:
			return Vector3.LEFT
		Face.RIGHT:
			return Vector3.RIGHT
		Face.UP:
			return Vector3.UP
		Face.DOWN:
			return Vector3.DOWN
	return Vector3.FORWARD

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
				Face.FORWARD, Face.BACK, Face.LEFT, Face.RIGHT:
					return Vector2(2, 0)
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

static func get_indices() -> Array[int]:
	return [0, 1, 2, 0, 2, 3]

static func is_visible(_lhs: Type, _rhs: Type) -> bool:
	return true