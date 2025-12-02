class_name Block

enum Type {
	GRASS,
	DIRT,
	STONE,
	WATER,
	LOG,
	LEAVES,
	SAND,
	BUSH,
	POPPY,
	DANDELION,
	DAISY,
	CORNFLOWER,
	MARIGOLD,
	LAVENDER,
	RED_TORCH,
	YELLOW_TORCH,
	GREEN_TORCH,
	BLUE_TORCH,
	CYAN_TORCH,
	MAGENTA_TORCH,
	WHITE_TORCH,
	PLANKS,
	GLASS,
	COUNT,
	EMPTY,
}

static var _INDICES = PackedInt32Array([0, 1, 2, 0, 2, 3])
static var _TORCH_LIGHT_STRENGTH = Vector3(5, 0.02, 1.0)

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

static var _SPRITE_VERTICES = PackedVector3Array([
	Vector3(0, 1, 1), Vector3(1, 1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1),
	Vector3(1, 1, 0), Vector3(0, 1, 1), Vector3(0, 0, 1), Vector3(1, 0, 0),
	Vector3(1, 1, 1), Vector3(0, 1, 0), Vector3(0, 0, 0), Vector3(1, 0, 1),
	Vector3(0, 1, 0), Vector3(1, 1, 1), Vector3(1, 0, 1), Vector3(0, 0, 0),
])

static var _SPRITE_TEXCOORDS = PackedVector2Array([
	Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1),
	Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1),
	Vector2(1, 0), Vector2(0, 0), Vector2(0, 1), Vector2(1, 1),
	Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1),
])

static var _SPRITE_NORMALS = PackedVector3Array([
	Vector3(0, 1, 0),
	Vector3(0, 1, 0),
	Vector3(0, 1, 0),
	Vector3(0, 1, 0),
])

static func get_indices() -> PackedInt32Array:
	return _INDICES

static func get_vertex(_type: Type, face: Face.Type, index: int) -> Vector3:
	if is_sprite(_type):
		assert(face < 4)
		return _SPRITE_VERTICES[face * 4 + index]
	assert(face < Face.Type.COUNT)
	return _VERTICES[face * 4 + index]

static func get_texcoord2(_type: Type, face: Face.Type, index: int) -> Vector2:
	if is_sprite(_type):
		assert(face < 4)
		return _SPRITE_TEXCOORDS[face * 4 + index]
	assert(face < Face.Type.COUNT)
	return _TEXCOORDS[face * 4 + index]

static func get_normal(_type: Type, face: Face.Type) -> Vector3i:
	if is_sprite(_type):
		assert(face < 4)
		return _SPRITE_NORMALS[face]
	assert(face < Face.Type.COUNT)
	return Face.get_vector(face)

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
		Type.BUSH:
			return Vector2(9, 0)
		Type.POPPY:
			return Vector2(10, 0)
		Type.DANDELION:
			return Vector2(11, 0)
		Type.DAISY:
			return Vector2(12, 0)
		Type.CORNFLOWER:
			return Vector2(13, 0)
		Type.MARIGOLD:
			return Vector2(14, 0)
		Type.LAVENDER:
			return Vector2(15, 0)
		Type.YELLOW_TORCH:
			return Vector2(0, 1)
		Type.RED_TORCH:
			return Vector2(1, 1)
		Type.BLUE_TORCH:
			return Vector2(2, 1)
		Type.GREEN_TORCH:
			return Vector2(3, 1)
		Type.CYAN_TORCH:
			return Vector2(4, 1)
		Type.MAGENTA_TORCH:
			return Vector2(5, 1)
		Type.WHITE_TORCH:
			return Vector2(6, 1)
		Type.PLANKS:
			return Vector2(7, 1)
		Type.GLASS:
			return Vector2(8, 1)
	return Vector2.ZERO

static func is_transparent(type: Type) -> bool:
	match type:
		Type.WATER:
			return true
		Type.GLASS:
			return true
	return false

static func is_sprite(type: Type) -> bool:
	match type:
		Type.BUSH:
			return true
		Type.POPPY:
			return true
		Type.DANDELION:
			return true
		Type.DAISY:
			return true
		Type.CORNFLOWER:
			return true
		Type.MARIGOLD:
			return true
		Type.LAVENDER:
			return true
		Type.YELLOW_TORCH:
			return true
		Type.RED_TORCH:
			return true
		Type.BLUE_TORCH:
			return true
		Type.GREEN_TORCH:
			return true
		Type.CYAN_TORCH:
			return true
		Type.MAGENTA_TORCH:
			return true
		Type.WHITE_TORCH:
			return true
	return false

static func is_light(type: Type) -> bool:
	match type:
		Type.YELLOW_TORCH:
			return true
		Type.RED_TORCH:
			return true
		Type.BLUE_TORCH:
			return true
		Type.GREEN_TORCH:
			return true
		Type.CYAN_TORCH:
			return true
		Type.MAGENTA_TORCH:
			return true
		Type.WHITE_TORCH:
			return true
	return false

static func get_light_color(type: Type) -> Color:
	match type:
		Type.YELLOW_TORCH:
			return Color(1.0, 1.0, 0.0)
		Type.RED_TORCH:
			return Color(1.0, 0.0, 0.0)
		Type.BLUE_TORCH:
			return Color(0.0, 0.0, 1.0)
		Type.GREEN_TORCH:
			return Color(0.0, 1.0, 0.0)
		Type.CYAN_TORCH:
			return Color(0.0, 1.0, 1.0)
		Type.MAGENTA_TORCH:
			return Color(1.0, 0.0, 1.0)
		Type.WHITE_TORCH:
			return Color(1.0, 1.0, 1.0)
	return Color()

static func get_light_strength(type: Type) -> Vector3:
	match type:
		Type.YELLOW_TORCH:
			return _TORCH_LIGHT_STRENGTH
		Type.RED_TORCH:
			return _TORCH_LIGHT_STRENGTH
		Type.BLUE_TORCH:
			return _TORCH_LIGHT_STRENGTH
		Type.GREEN_TORCH:
			return _TORCH_LIGHT_STRENGTH
		Type.CYAN_TORCH:
			return _TORCH_LIGHT_STRENGTH
		Type.MAGENTA_TORCH:
			return _TORCH_LIGHT_STRENGTH
		Type.WHITE_TORCH:
			return _TORCH_LIGHT_STRENGTH
	return Vector3.ZERO

static func is_exposed(lhs: Type, rhs: Type) -> bool:
	assert(lhs != Type.EMPTY)
	assert(!is_sprite(lhs))
	if rhs == Type.EMPTY or is_sprite(rhs):
		return true
	if not is_transparent(lhs) and is_transparent(rhs):
		return true
	return false
