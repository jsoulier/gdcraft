extends Node

@onready var _fps_label: Label = $Stats/FPS
@onready var _process_label: Label = $Stats/Process
@onready var _physics_process_label: Label = $Stats/PhysicsProcess
@onready var _static_memory_used_label: Label = $Stats/StaticMemoryUsed
@onready var _video_memory_used_label: Label = $Stats/VideoMemoryUsed
@onready var _draw_calls_label: Label = $Stats/DrawCalls
@onready var _primitives_label: Label = $Stats/Primitives

func _process(_delta: float) -> void:
	var fps =  Performance.get_monitor(Performance.Monitor.TIME_FPS)
	var process =  Performance.get_monitor(Performance.Monitor.TIME_PROCESS)
	var physics_process =  Performance.get_monitor(Performance.Monitor.TIME_PHYSICS_PROCESS)
	var static_memory_used = Performance.get_monitor(Performance.Monitor.MEMORY_STATIC)
	var video_memory_used = Performance.get_monitor(Performance.Monitor.RENDER_VIDEO_MEM_USED)
	var draw_calls = Performance.get_monitor(Performance.Monitor.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives = Performance.get_monitor(Performance.Monitor.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	_fps_label.text = "FPS: " + str(fps)
	_process_label.text = "Process: " + str(process) + " Seconds"
	_physics_process_label.text = "Physics Process: " + str(physics_process) + " Seconds"
	_static_memory_used_label.text = "Static Memory Used: " + str(int(static_memory_used / 1024 / 1024)) + " Mb"
	_video_memory_used_label.text = "Video Memory Used: " + str(int(video_memory_used / 1024 / 1024)) + " Mb"
	_draw_calls_label.text = "Draw Calls: " + str(int(draw_calls))
	_primitives_label.text = "Primitives: " + str(int(primitives))

func _on_player_switch_block(type: Block.Type) -> void:
	pass
