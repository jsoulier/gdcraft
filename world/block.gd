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

static func get_normal(face: Face) -> Vector3i:
	match face:
		Face.FORWARD:
			return Vector3i.FORWARD
		Face.BACK:
			return Vector3i.BACK
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
			return [Vector3(0.0, 0.0, 1.0), Vector3(0.0, 0.0, 1.0), Vector3(0.0, 0.0, 1.0), Vector3(0.0, 0.0, 1.0)]
		Face.BACK:
			return [Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 0.0)]
		Face.LEFT:
			return [Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 0.0)]
		Face.RIGHT:
			return [Vector3(1.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0)]
		Face.UP:
			return [Vector3(0.0, 1.0, 0.0), Vector3(0.0, 1.0, 0.0), Vector3(0.0, 1.0, 0.0), Vector3(0.0, 1.0, 0.0)]
		Face.DOWN:
			return [Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 0.0)]
	return []

static func is_visible(_lhs: Type, _rhs: Type) -> bool:
	return true
