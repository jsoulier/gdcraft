extends Node3D

# should always be even
const LOAD_WIDTH = 2 # +1 for center
const LOAD_HEIGHT = 2 # +1 for center
@warning_ignore_start("integer_division")
const LOAD_HALF_WIDTH = LOAD_WIDTH / 2
const LOAD_HALF_HEIGHT = LOAD_HEIGHT / 2
@warning_ignore_restore("integer_division")

@onready var _player = get_node("Player")
var _chunks: Dictionary[Vector3i, Chunk] = {}
var _player_chunk_index: Vector3i = Vector3i.MAX
var generator: Generator = null
var material: ShaderMaterial = null
var _spritesheet: Texture2DArray = null

func _ready() -> void:
	_spritesheet = Spritesheet.get_spritesheet()
	material = ShaderMaterial.new()
	material.shader = preload("res://world/chunk.gdshader")
	#material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.set_shader_parameter("spritesheet", _spritesheet)

func set_generator(type: Generator.Type) -> void:
	generator = Generator.new(type)

func _process(_delta: float) -> void:
	var chunk_index = Vector3i(_player.position) / Chunk.SIZE
	if _player_chunk_index == chunk_index:
		return
	_player_chunk_index = chunk_index
	for x in range(-LOAD_HALF_WIDTH, LOAD_HALF_WIDTH + 1):
		for z in range(-LOAD_HALF_WIDTH, LOAD_HALF_WIDTH + 1):
			for y in range(-LOAD_HALF_HEIGHT, LOAD_HALF_HEIGHT + 1):
				var index = _player_chunk_index + Vector3i(x, y, z)
				if not _chunks.has(index):
					_chunks[index] = Chunk.new(self, index)
