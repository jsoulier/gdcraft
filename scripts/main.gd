class_name Main
extends Node

const WORLD = preload("res://scenes/world.tscn")

func _ready() -> void:
	add_child(WORLD.instantiate())
