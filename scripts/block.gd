class_name Block extends Node

enum Type {
	GRASS,
	DIRT,
	STONE,
	WATER,
	LOG,
	LEAVES,
	SAND,
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

static var _VERTICES = PackedVector3Array([
	Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 0, 1), Vector3(0, 0, 1),
	Vector3(1, 1, 0), Vector3(0, 1, 0), Vector3(0, 0, 0), Vector3(1, 0, 0),
	Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(0, 0, 1), Vector3(0, 0, 0),
	Vector3(1, 1, 1), Vector3(1, 1, 0), Vector3(1, 0, 0), Vector3(1, 0, 1),
	Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(0, 1, 1),
	Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, 0)
])

static var _TEXCOORDS = PackedVector2Array([
	Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1),
	Vector2(1, 0), Vector2(0, 0), Vector2(0, 1), Vector2(1, 1),
	Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1),
	Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1),
	Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1),
	Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)
])

static var _NORMALS = [
	Vector3i.BACK,
	Vector3i.FORWARD,
	Vector3i.LEFT,
	Vector3i.RIGHT,
	Vector3i.UP,
	Vector3i.DOWN
]

static var _INDICES = PackedInt32Array([0, 1, 2, 0, 2, 3])

static func get_vertex(_type: Type, face: Face, index: int) -> Vector3:
	return _VERTICES[face * 4 + index]

static func get_texcoord2(_type: Type, face: Face, index: int) -> Vector2:
	return _TEXCOORDS[face * 4 + index]

static func get_normal(_type: Type, face: Face) -> Vector3i:
	return _NORMALS[face]

static func get_indices(_type: Type, _face: Face) -> PackedInt32Array:
	return _INDICES

static func get_texcoord(type: Type, face: Face) -> Vector2:
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
	return Vector2(0, 0)

static func is_transparent(type: Type) -> bool:
	match type:
		Type.WATER:
			return true
	return false

static func is_sprite(_type: Type) -> bool:
	return false

static func is_visible(lhs: Type, rhs: Type) -> bool:
	assert(lhs != Type.EMPTY)
	if rhs == Type.EMPTY:
		return true
	if is_sprite(lhs):
		return true
	return not is_transparent(lhs) and is_transparent(rhs)
