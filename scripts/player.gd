class_name Player
extends CharacterBody3D

signal switch_block(type: Block.Type)
signal set_block(index: Vector3i, type: Block.Type)

@export var walk_speed = 10.0
@export var sprint_speed = 100.0
@export var rotate_speed = 0.001
@onready var _head = $Head
@onready var _raycast = $Head/RayCast3D
@onready var _raycast_block = $RayCastBlock
var _raycast_break_position: Vector3i
var _raycast_place_position: Vector3i
var _block_type = Block.Type.GRASS

func _init() -> void:
	position.y = 30

func _ready() -> void:
	_switch_block(0)

func _switch_block(delta: int) -> void:
	var count = Block.Type.COUNT
	_block_type = (_block_type + delta + count) as Block.Type
	_block_type = (_block_type % count) as Block.Type
	switch_block.emit(_block_type)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * rotate_speed)
			_head.rotate_x(-event.relative.y * rotate_speed)
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if _raycast.is_colliding():
			if event.is_action_pressed(&"place"):
				set_block.emit(_raycast_place_position, _block_type)
			elif event.is_action_pressed(&"break"):
				set_block.emit(_raycast_break_position, Block.Type.EMPTY)
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_switch_block(-event.factor)
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_switch_block(event.factor)
	elif event.is_action_pressed(&"unfocus"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(_delta) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var direction = Vector3.ZERO
		var up = Vector3.ZERO
		var speed = walk_speed
		if Input.is_action_pressed(&"right"):
			direction.x += 1
		if Input.is_action_pressed(&"left"):
			direction.x -= 1
		if Input.is_action_pressed(&"back"):
			direction.z += 1
		if Input.is_action_pressed(&"forward"):
			direction.z -= 1
		if Input.is_action_pressed(&"jump"):
			up.y += 1
		if Input.is_action_pressed(&"crouch"):
			up.y -= 1
		if Input.is_action_pressed(&"sprint"):
			speed = sprint_speed
		direction = direction.normalized()
		direction = (_head.global_transform.basis * direction).normalized()
		direction = (direction + up).normalized()
		velocity = direction * speed
		move_and_slide()
	_raycast_block.visible = _raycast.is_colliding()
	if not _raycast.is_colliding():
		return
	var ray_position = _raycast.get_collision_point()
	var ray_normal = _raycast.get_collision_normal()
	var block_position = Vector3i((ray_position - ray_normal / 2).floor())
	_raycast_block.global_position = Vector3(block_position) + Vector3(0.5, 0.5, 0.5) 
	_raycast_break_position = block_position
	_raycast_place_position = Vector3i((ray_position + ray_normal / 2).floor())
