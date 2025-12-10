# ╔═══════════════════════════════════════════════════════════
# ║ WorldRoot.gd
# ║ Desc: Main scene root – orchestrates all managers at startup
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
extends Node3D

@onready var terrain_manager: Node3D = $Terrain3DManager

## World builder UI instance
var world_builder_ui = null

## Path to terrain generation config
const TERRAIN_CONFIG_PATH: String = "res://data/config/terrain_generation.json"


func _remove_splash_screen() -> void:
	"""Search for and remove any splash screen labels."""
	var labels: Array[Node] = []
	_find_labels_recursive(self, labels)
	
	for label: Label in labels:
		if label.text.contains("Baldur") or label.text.contains("Character Creation"):
			print("WorldRoot: Removing splash label: ", label.text)
			label.queue_free()


func _find_labels_recursive(node: Node, labels: Array) -> void:
	"""Recursively find all Label nodes."""
	if node is Label:
		labels.append(node)
	
	for child: Node in node.get_children():
		_find_labels_recursive(child, labels)


func _ensure_lighting_and_camera() -> void:
	"""Ensure proper lighting and camera setup for visibility."""
	# Check if camera exists and is current
	var camera: Camera3D = get_node_or_null("MainCamera")
	if camera == null:
		push_warning("WorldRoot: MainCamera not found, creating one")
		camera = Camera3D.new()
		camera.name = "MainCamera"
		camera.transform.origin = Vector3(0, 10, 20)
		camera.look_at(Vector3.ZERO, Vector3.UP)
		camera.current = true
		camera.fov = 70.0
		camera.near = 0.05
		camera.far = 5000.0
		add_child(camera, true)
		print("WorldRoot: Created MainCamera at ", camera.transform.origin)
	else:
		if not camera.current:
			camera.current = true
			print("WorldRoot: Set MainCamera as current")
	
	# Check if light exists
	var light: DirectionalLight3D = get_node_or_null("DirectionalLight3D")
	if light == null:
		push_warning("WorldRoot: DirectionalLight3D not found, creating one")
		light = DirectionalLight3D.new()
		light.name = "DirectionalLight3D"
		light.transform.basis = Basis.from_euler(Vector3(deg_to_rad(-45), deg_to_rad(45), 0))
		light.light_color = Color(1, 0.863, 0.706, 1)
		light.light_energy = 12.0
		light.shadow_enabled = true
		add_child(light, true)
		print("WorldRoot: Created DirectionalLight3D")
	else:
		# Ensure light is properly configured
		if light.light_energy < 1.0:
			light.light_energy = 12.0
		if not light.shadow_enabled:
			light.shadow_enabled = true
		print("WorldRoot: DirectionalLight3D verified (energy: ", light.light_energy, ")")


func _ready() -> void:
	_remove_splash_screen()
	_ensure_lighting_and_camera()
	# Terrain3DManager now creates and configures the terrain itself in its own _ready()
	# Nothing else needed here unless you want to trigger procedural generation later
	_setup_world_builder_ui()
	print("WorldRoot: Setup complete - splash removed, terrain visible, UI added")


# Optional: expose for later procedural calls
func regenerate_world() -> void:
	if terrain_manager and terrain_manager.has_method("generate_initial_terrain"):
		terrain_manager.generate_initial_terrain()


func _setup_world_builder_ui() -> void:
	"""Setup and display the world builder UI overlay."""
	print("WorldRoot: Setting up WorldBuilderUI...")
	
	# Load and instance WorldBuilderUI scene
	var ui_scene: PackedScene = load("res://ui/world_builder/WorldBuilderUI.tscn")
	if ui_scene == null:
		push_error("WorldRoot: Failed to load WorldBuilderUI scene")
		return
	
	world_builder_ui = ui_scene.instantiate()
	if world_builder_ui == null:
		push_error("WorldRoot: Failed to instantiate WorldBuilderUI")
		return
	
	print("WorldRoot: WorldBuilderUI instantiated successfully")
	
	# Verify it's the correct type
	if not world_builder_ui.has_method("set_terrain_manager"):
		push_error("WorldRoot: Instantiated node is not WorldBuilderUI")
		return
	
	# Add UI to scene tree as a CanvasLayer child for proper overlay
	var canvas_layer: CanvasLayer = CanvasLayer.new()
	canvas_layer.name = "UICanvasLayer"
	add_child(canvas_layer, true)
	canvas_layer.add_child(world_builder_ui, true)
	
	print("WorldRoot: WorldBuilderUI added to scene tree")
	
	# Apply project theme
	var theme: Theme = load("res://themes/bg3_theme.tres")
	if theme != null:
		world_builder_ui.theme = theme
		print("WorldRoot: Theme applied to WorldBuilderUI")
	else:
		push_warning("WorldRoot: Failed to load bg3_theme.tres")
	
	# Connect UI to terrain manager
	if terrain_manager:
		world_builder_ui.set_terrain_manager(terrain_manager)
		print("WorldRoot: Terrain manager connected to WorldBuilderUI")
	
	# Position UI - make it larger and more visible (80% width, 80% height)
	world_builder_ui.anchor_left = 0.0
	world_builder_ui.anchor_top = 0.0
	world_builder_ui.anchor_right = 0.8
	world_builder_ui.anchor_bottom = 0.8
	world_builder_ui.offset_left = 10.0
	world_builder_ui.offset_top = 10.0
	
	# Ensure UI is visible
	world_builder_ui.visible = true
	world_builder_ui.mouse_filter = Control.MOUSE_FILTER_PASS
	
	print("WorldRoot: WorldBuilderUI positioned and made visible")
	print("WorldRoot: UI size: ", world_builder_ui.size, " position: ", world_builder_ui.position)
