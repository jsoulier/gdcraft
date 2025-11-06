extends Node3D

var world_type = preload("res://world/world.tscn")

func _ready() -> void:
	var world = world_type.instantiate()
	world.set_generator(Generator.Type.ONE)
	add_child(world)
