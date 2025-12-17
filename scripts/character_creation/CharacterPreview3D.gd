# ╔═══════════════════════════════════════════════════════════
# ║ CharacterPreview3D.gd
# ║ Desc: Manages 3D character model preview in SubViewport
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name CharacterPreview3D
extends Node3D

## Signal emitted when character model changes
signal character_model_changed()

## Current character model instance
var character_model: Node3D = null

## Preview camera reference
var preview_camera: Camera3D = null

## Rotation state for drag interaction
var is_rotating: bool = false
var last_mouse_pos: Vector2 = Vector2.ZERO

## Character appearance data
var appearance_data: Dictionary = {}


func _ready() -> void:
	"""Initialize 3D preview system."""
	MythosLogger.verbose("UI/CharacterCreation/Preview3D", "_ready() called")
	_setup_camera()
	_create_placeholder_model()
	MythosLogger.info("UI/CharacterCreation/Preview3D", "3D preview system initialized")


func _setup_camera() -> void:
	"""Setup preview camera."""
	preview_camera = get_node_or_null("../PreviewCamera")
	if preview_camera == null:
		MythosLogger.warn("UI/CharacterCreation/Preview3D", "PreviewCamera not found")
		return
	
	# Position camera for character preview
	preview_camera.transform.origin = Vector3(0, 1.6, 2.5)  # Eye level, slightly back
	preview_camera.look_at(Vector3(0, 1.6, 0), Vector3.UP)
	MythosLogger.debug("UI/CharacterCreation/Preview3D", "Camera positioned for character preview")


func _create_placeholder_model() -> void:
	"""Create placeholder character model (temporary until models are available)."""
	# Remove existing model if any
	if character_model != null:
		character_model.queue_free()
		character_model = null
	
	# Create a simple placeholder (cylinder for body, sphere for head)
	var body: MeshInstance3D = MeshInstance3D.new()
	body.mesh = CylinderMesh.new()
	body.mesh.height = 1.6
	body.mesh.top_radius = 0.3
	body.mesh.bottom_radius = 0.3
	body.position = Vector3(0, 0.8, 0)
	body.material_override = StandardMaterial3D.new()
	body.material_override.albedo_color = Color(0.8, 0.7, 0.6, 1.0)  # Skin tone
	
	var head: MeshInstance3D = MeshInstance3D.new()
	head.mesh = SphereMesh.new()
	head.mesh.radius = 0.2
	head.position = Vector3(0, 1.6, 0)
	head.material_override = StandardMaterial3D.new()
	head.material_override.albedo_color = Color(0.8, 0.7, 0.6, 1.0)
	
	character_model = Node3D.new()
	character_model.name = "CharacterModel"
	character_model.add_child(body)
	character_model.add_child(head)
	add_child(character_model)
	
	MythosLogger.debug("UI/CharacterCreation/Preview3D", "Placeholder character model created")


func update_appearance(data: Dictionary) -> void:
	"""Update character appearance based on appearance data."""
	appearance_data = data.duplicate()
	
	# TODO: Update model materials/textures based on appearance data
	# For now, placeholder model doesn't change
	
	character_model_changed.emit()
	MythosLogger.debug("UI/CharacterCreation/Preview3D", "Appearance updated")


func set_race(race_id: String) -> void:
	"""Set character race (affects model selection)."""
	# TODO: Load race-specific model when available
	MythosLogger.debug("UI/CharacterCreation/Preview3D", "Race set to: %s" % race_id)


func rotate_model(delta_angle: float) -> void:
	"""Rotate character model around Y axis."""
	if character_model != null:
		character_model.rotate_y(deg_to_rad(delta_angle))


func _input(event: InputEvent) -> void:
	"""Handle input for model rotation."""
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			is_rotating = mouse_event.pressed
			if is_rotating:
				last_mouse_pos = mouse_event.position
	
	elif event is InputEventMouseMotion and is_rotating:
		var mouse_event: InputEventMouseMotion = event as InputEventMouseMotion
		var delta: Vector2 = mouse_event.position - last_mouse_pos
		var rotation_speed: float = 0.5  # Degrees per pixel
		rotate_model(delta.x * rotation_speed)
		last_mouse_pos = mouse_event.position
