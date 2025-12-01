class_name Block

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

static var _INDICES = PackedInt32Array([0, 1, 2, 0, 2, 3])

static func get_vertex(_type: Type, face: Face.Type, index: int) -> Vector3:
	return _VERTICES[face * 4 + index]

static func get_texcoord2(_type: Type, face: Face.Type, index: int) -> Vector2:
	return _TEXCOORDS[face * 4 + index]

static func get_normal(_type: Type, face: Face.Type) -> Vector3i:
	return Face.get_vector(face)

static func get_indices() -> PackedInt32Array:
	return _INDICES

static func get_texcoord(type: Type, face: Face.Type) -> Vector2:
	match type:
		Type.GRASS:
			match face:
				Face.Type.UP:
					return Vector2(0, 0)
				Face.Type.DOWN:
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
				Face.Type.UP, Face.Type.DOWN:
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
	match _type:
		pass
	return false

static func is_exposed(lhs: Type, rhs: Type) -> bool:
	assert(lhs != Type.EMPTY)
	assert(!is_sprite(lhs))
	if rhs == Type.EMPTY:
		return true
	if not is_transparent(lhs) and is_transparent(rhs):
		return true
	return false
