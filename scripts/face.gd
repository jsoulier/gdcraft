class_name Face

enum Type {
	FORWARD,
	BACK,
	LEFT,
	RIGHT,
	UP,
	DOWN,
	COUNT,
}

static var _VECTORS = [
	Vector3i.BACK,
	Vector3i.FORWARD,
	Vector3i.LEFT,
	Vector3i.RIGHT,
	Vector3i.UP,
	Vector3i.DOWN
]

static func get_vector(face: Type) -> Vector3i:
	return _VECTORS[face]
