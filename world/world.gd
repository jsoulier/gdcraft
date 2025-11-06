extends Node3D

const _WIDTH = 2 # +1 for center
const _HEIGHT = 2 # +1 for center
const _SIZE = Vector3i(_WIDTH, _HEIGHT, _WIDTH)
@warning_ignore("integer_division")
const _HALF_SIZE = _SIZE / 2

@onready var _player = get_node("Player")
var _chunk_shader = preload("res://world/chunk.gdshader")
var _chunks: Dictionary[Vector3i, Chunk] = {}
var _player_chunk_index: Vector3i = Vector3i.MAX
var generator: Generator = null
var chunk_material: ShaderMaterial = null

func _ready() -> void:
	chunk_material = ShaderMaterial.new()
	chunk_material.shader = _chunk_shader
	chunk_material.set_shader_parameter("spritesheet", Spritesheet.get_spritesheet())

func set_generator(type: Generator.Type) -> void:
	generator = Generator.new(type)

func get_chunk(index: Vector3i) -> Chunk:
	return _chunks.get(index, null)

func _process(_delta: float) -> void:
	var chunk_index = Vector3i(_player.position) / Chunk._SIZE
	if _player_chunk_index == chunk_index:
		return
	_player_chunk_index = chunk_index
	for x in range(-_HALF_SIZE.x, _HALF_SIZE.x + 1):
		for z in range(-_HALF_SIZE.z, _HALF_SIZE.z + 1):
			for y in range(-_HALF_SIZE.y, _HALF_SIZE.y + 1):
				var index = _player_chunk_index + Vector3i(x, y, z)
				if not _chunks.has(index):
					_chunks[index] = Chunk.new(self, index)