extends CharacterBody3D

@export var walk_speed = 5.0
@export var sprint_speed = 200.0
@export var rotate_speed = 0.001
@onready var _camera = get_node("Camera3D")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("unfocus"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * rotate_speed)
			_camera.rotate_x(-event.relative.y * rotate_speed)

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
	direction = (_camera.global_transform.basis * direction).normalized()
	direction = (direction + up).normalized()
	velocity = direction * speed
	move_and_slide()
