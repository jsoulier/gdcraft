extends CharacterBody3D

@export var walk_speed = 5.0
@export var sprint_speed = 50.0
@export var rotate_speed = 0.001
var _raycast_break_position: Vector3i
var _raycast_place_position: Vector3i
@onready var _head = $Head
@onready var _raycast = $Head/RayCast3D
@onready var _raycast_block = $RayCastBlock
@onready var _world = $".."

func _ready() -> void:
	# TODO: remove
	position.y = 30

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if _raycast.is_colliding():
			if event.is_action_pressed("place"):
				_world.set_block(_raycast_place_position, Block.Type.GRASS)
			elif event.is_action_pressed("break"):
				_world.set_block(_raycast_break_position, Block.Type.EMPTY)
	elif event.is_action_pressed("unfocus"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * rotate_speed)
			_head.rotate_x(-event.relative.y * rotate_speed)

func _physics_process(_delta) -> void:
	var direction = Vector3.ZERO
	var up = Vector3.ZERO
	var speed = walk_speed
	if Input.is_action_pressed("right"):
		direction.x += 1
	if Input.is_action_pressed("left"):
		direction.x -= 1
	if Input.is_action_pressed("back"):
		direction.z += 1
	if Input.is_action_pressed("forward"):
		direction.z -= 1
	if Input.is_action_pressed("jump"):
		up.y += 1
	if Input.is_action_pressed("crouch"):
		up.y -= 1
	if Input.is_action_pressed("sprint"):
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
