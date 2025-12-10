# ╔═══════════════════════════════════════════════════════════
# ║ creative_fly_camera.gd
# ║ Desc: Free-flying camera with WASD movement and mouse look
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Camera3D

@export_group("Movement Settings")
@export var move_speed: float = 20.0
@export var fast_move_speed: float = 50.0
@export var mouse_sensitivity: float = 0.003

var rotation_x: float = 0.0
var rotation_y: float = 0.0
var is_mouse_captured: bool = false

func _ready() -> void:
	"""Initialize camera rotation from current transform."""
	var forward: Vector3 = -transform.basis.z
	rotation_y = atan2(forward.x, forward.z)
	rotation_x = -asin(forward.y)

func _input(event: InputEvent) -> void:
	"""Handle input events for mouse capture and rotation."""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				is_mouse_captured = true
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				is_mouse_captured = false
	
	if event is InputEventMouseMotion and is_mouse_captured:
		rotation_y -= event.relative.x * mouse_sensitivity
		rotation_x -= event.relative.y * mouse_sensitivity
		rotation_x = clamp(rotation_x, -PI / 2, PI / 2)

func _process(delta: float) -> void:
	"""Update camera position and rotation each frame."""
	_handle_movement(delta)
	_update_rotation()

func _handle_movement(delta: float) -> void:
	"""Handle WASD movement input."""
	var speed: float = fast_move_speed if Input.is_action_pressed("ui_accept") else move_speed
	var direction: Vector3 = Vector3.ZERO
	
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direction -= transform.basis.z
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direction += transform.basis.z
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction -= transform.basis.x
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction += transform.basis.x
	
	if Input.is_key_pressed(KEY_Q):
		direction -= transform.basis.y
	if Input.is_key_pressed(KEY_E):
		direction += transform.basis.y
	
	if direction.length() > 0:
		direction = direction.normalized()
		global_position += direction * speed * delta

func _update_rotation() -> void:
	"""Update camera rotation based on mouse input."""
	transform.basis = Basis()
	rotate_object_local(Vector3.RIGHT, rotation_x)
	rotate_object_local(Vector3.UP, rotation_y)
