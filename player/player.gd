extends CharacterBody3D

@export var speed = 2.0
@export var sensitivity = 0.001
@onready var _camera = get_node("Camera3D")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("unfocus"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * sensitivity)
			_camera.rotate_x(-event.relative.y * sensitivity)

func _physics_process(_delta) -> void:
	var direction = Vector3.ZERO
	if Input.is_action_pressed("right"):
		direction.x += 1
	if Input.is_action_pressed("left"):
		direction.x -= 1
	if Input.is_action_pressed("back"):
		direction.z += 1
	if Input.is_action_pressed("forward"):
		direction.z -= 1
	direction = direction.normalized()
	direction = (transform.basis * direction).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	move_and_slide()
