# ╔═══════════════════════════════════════════════════════════
# ║ CharacterPreviewCamera.gd
# ║ Desc: Simple orbit + zoom camera for character appearance preview
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

@tool
class_name CharacterPreviewCamera

extends Camera3D

@export_group("Camera Settings")
@export var target: Node3D
@export var zoom_speed: float = 10.0
@export var orbit_speed: float = 120.0
@export var min_distance: float = 1.5
@export var max_distance: float = 5.0
@export var zoom_smoothing: float = 12.0
@export var orbit_smoothing: float = 10.0

var current_distance: float = 3.0
var target_distance: float = 3.0
var current_yaw_degrees: float = 0.0
var target_yaw_degrees: float = 0.0

var is_dragging: bool = false

func _ready() -> void:
	# Auto-find target if not assigned
	if not target:
		target = get_node_or_null("../CharacterRoot") as Node3D
		if not target:
			# Try direct sibling reference
			target = get_node_or_null("CharacterRoot") as Node3D
		if not target:
			push_warning("CharacterPreviewCamera: No target assigned and CharacterRoot not found!")
			return
	
	var initial_distance: float = (min_distance + max_distance) * 0.5
	current_distance = initial_distance
	target_distance = initial_distance
	_update_camera_position()

func _input(event: InputEvent) -> void:
	if not target:
		return
		
	# Mouse wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_distance = max(min_distance, target_distance - zoom_speed * 0.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_distance = min(max_distance, target_distance + zoom_speed * 0.1)
			
		# Right mouse drag start/stop
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_dragging = event.pressed
			if is_dragging:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Right mouse drag orbit
	if event is InputEventMouseMotion and is_dragging:
		target_yaw_degrees -= event.relative.x * 0.3

func _process(delta: float) -> void:
	if not target:
		return
	
	_handle_keyboard_input(delta)
	_smooth_values(delta)
	_update_camera_position()

func _handle_keyboard_input(delta: float) -> void:
	print("[CAMERA INPUT OK] W:", Input.is_action_pressed("cam_zoom_in"), " S:", Input.is_action_pressed("cam_zoom_out"), " A:", Input.is_action_pressed("cam_orbit_left"), " D:", Input.is_action_pressed("cam_orbit_right"))
	if Input.is_action_pressed("cam_zoom_in"):  # W
		target_distance = max(min_distance, target_distance - zoom_speed * delta)
	if Input.is_action_pressed("cam_zoom_out"):  # S
		target_distance = min(max_distance, target_distance + zoom_speed * delta)
	if Input.is_action_pressed("cam_orbit_left"):  # A
		target_yaw_degrees += orbit_speed * delta
	if Input.is_action_pressed("cam_orbit_right"):  # D
		target_yaw_degrees -= orbit_speed * delta

func _smooth_values(delta: float) -> void:
	current_distance = lerpf(current_distance, target_distance, zoom_smoothing * delta)
	current_yaw_degrees = lerpf(current_yaw_degrees, target_yaw_degrees, orbit_smoothing * delta)

func _update_camera_position() -> void:
	var yaw_rad: float = deg_to_rad(current_yaw_degrees)
	var offset: Vector3 = Vector3(
		cos(yaw_rad) * current_distance,
		1.6,  # eye level
		sin(yaw_rad) * current_distance
	)
	
	global_position = target.global_position + offset
	look_at(target.global_position + Vector3(0, 1.4, 0), Vector3.UP)

# Optional: Auto-focus when target changes in editor
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not target:
		warnings.append("Target node (character root) must be assigned!")
	return warnings

