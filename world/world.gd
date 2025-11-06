extends Node3D

const _LOAD_WIDTH = 2 # +1 for center
const _LOAD_HEIGHT = 2 # +1 for center
@warning_ignore_start("integer_division")
const _LOAD_HALF_WIDTH = _LOAD_WIDTH / 2
const _LOAD_HALF_HEIGHT = _LOAD_HEIGHT / 2
@warning_ignore_restore("integer_division")

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

func _process(_delta: float) -> void:
	var chunk_index = Vector3i(_player.position) / Chunk._SIZE
	if _player_chunk_index == chunk_index:
		return
	_player_chunk_index = chunk_index
	for x in range(-_LOAD_HALF_WIDTH, _LOAD_HALF_WIDTH + 1):
		for z in range(-_LOAD_HALF_WIDTH, _LOAD_HALF_WIDTH + 1):
			for y in range(-_LOAD_HALF_HEIGHT, _LOAD_HALF_HEIGHT + 1):
				var index = _player_chunk_index + Vector3i(x, y, z)
				if not _chunks.has(index):
					_chunks[index] = Chunk.new(self, index)
