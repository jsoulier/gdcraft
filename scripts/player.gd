extends CharacterBody3D

@export var walk_speed = 5.0
@export var sprint_speed = 50.0
@export var rotate_speed = 0.001
var _raycast_break_position: Vector3i
var _raycast_place_position: Vector3i
var _block_type = Block.Type.GRASS
@onready var _head = $Head
@onready var _raycast = $Head/RayCast3D
@onready var _raycast_block = $RayCastBlock
@onready var _collision_shape = $CollisionShape3D

signal switch_block(type: Block.Type)
signal set_block(index: Vector3i, type: Block.Type)

func _ready() -> void:
	_switch_block(0)
	_collision_shape.disabled = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _switch_block(delta: int) -> void:
	var count := Block.Type.COUNT
	_block_type = ((_block_type + delta + count) % count) as Block.Type
	emit_signal(&"switch_block", _block_type)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if _raycast.is_colliding():
			if event.is_action_pressed(&"place"):
				emit_signal(&"set_block", _raycast_place_position, _block_type)
			elif event.is_action_pressed(&"break"):
				emit_signal(&"set_block", _raycast_break_position, Block.Type.EMPTY)
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_switch_block(-event.factor)
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_switch_block(event.factor)
	elif event.is_action_pressed(&"unfocus"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * rotate_speed)
			_head.rotate_x(-event.relative.y * rotate_speed)

func _physics_process(_delta) -> void:
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
