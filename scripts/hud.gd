extends Node

@onready var _stats = $Stats
@onready var _fps_label = $Stats/FPS
@onready var _process_label = $Stats/Process
@onready var _physics_process_label = $Stats/PhysicsProcess
@onready var _static_memory_used_label = $Stats/StaticMemoryUsed
@onready var _video_memory_used_label = $Stats/VideoMemoryUsed
@onready var _draw_calls_label = $Stats/DrawCalls
@onready var _primitives_label = $Stats/Primitives
@onready var _block_texture: TextureRect = $BlockH/BlockV/Texture
@onready var _block_label: Label = $BlockH/BlockV/Label

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed(&"debug"):
			_stats.visible = not _stats.visible

func _process(_delta: float) -> void:
	var fps =  Performance.get_monitor(Performance.Monitor.TIME_FPS)
	var process =  Performance.get_monitor(Performance.Monitor.TIME_PROCESS)
	var physics_process =  Performance.get_monitor(Performance.Monitor.TIME_PHYSICS_PROCESS)
	var static_memory_used = Performance.get_monitor(Performance.Monitor.MEMORY_STATIC)
	var video_memory_used = Performance.get_monitor(Performance.Monitor.RENDER_VIDEO_MEM_USED)
	var draw_calls = Performance.get_monitor(Performance.Monitor.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives = Performance.get_monitor(Performance.Monitor.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	_fps_label.text = "FPS: " + str(fps)
	_process_label.text = "Process: " + str(process * 1000) + " ms"
	_physics_process_label.text = "Physics Process: " + str(physics_process * 1000) + " ms"
	_static_memory_used_label.text = "Static Memory Used: " + str(int(static_memory_used / 1024 / 1024)) + " mb"
	_video_memory_used_label.text = "Video Memory Used: " + str(int(video_memory_used / 1024 / 1024)) + " mb"
	_draw_calls_label.text = "Draw Calls: " + str(int(draw_calls))
	_primitives_label.text = "Primitives: " + str(int(primitives))

func _on_player_switch_block(type: Block.Type) -> void:
	var size = GDCraftResources.SIZE
	var texcoord = Block.get_texcoord(type, Face.Type.FORWARD) * size
	_block_texture.texture.region = Rect2(texcoord.x, texcoord.y, size, size)
	var text: String = Block.Type.keys()[type].replace("_", " ")
	var strings: PackedStringArray = text.split(" ")
	for i in range(strings.size()):
		strings[i] = strings[i].capitalize()
	_block_label.text = " ".join(strings)
