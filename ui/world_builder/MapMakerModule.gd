# ╔═══════════════════════════════════════════════════════════
# ║ MapMakerModule.gd
# ║ Desc: Main module for 2D Map Maker - integrates generator, renderer, editor, markers
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Control
class_name MapMakerModule

## World map data resource
var world_map_data: WorldMapData

## Map generator
var map_generator: MapGenerator

## Map renderer
var map_renderer: MapRenderer

## Map editor
var map_editor: MapEditor

## Marker manager
var marker_manager: MarkerManager

## Map viewport and camera
var map_viewport: SubViewport
var map_camera: Camera2D
var map_viewport_container: SubViewportContainer

## UI references
var map_canvas: Control
var toolbar_panel: Panel
var params_panel: Panel

## Generation parameters UI
var param_controls: Dictionary = {}

## Current view mode
var current_view_mode: MapRenderer.ViewMode = MapRenderer.ViewMode.BIOMES

## Is map initialized
var is_initialized: bool = false

## Map root node
var map_root: Node2D


func _ready() -> void:
	"""Initialize MapMakerModule."""
	_setup_ui()
	_setup_viewport()
	_setup_generator()
	_setup_renderer()
	_setup_editor()
	_setup_marker_manager()


func _setup_viewport() -> void:
	"""Setup map viewport and camera."""
	if map_canvas == null:
		push_error("MapMakerModule: map_canvas is null")
		return
	
	map_viewport = SubViewport.new()
	map_viewport.name = "MapViewport"
	map_viewport.size = Vector2i(1920, 1080)
	map_viewport.transparent_bg = false
	map_viewport.handle_input_locally = true  # Handle input in viewport
	map_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	map_viewport_container = SubViewportContainer.new()
	map_viewport_container.name = "MapViewportContainer"
	map_viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_viewport_container.stretch = true
	map_viewport_container.gui_input.connect(_on_viewport_container_input)
	map_viewport_container.resized.connect(_on_viewport_container_resized)
	map_viewport_container.add_child(map_viewport)
	
	map_canvas.add_child(map_viewport_container)
	
	# Setup camera and root
	map_root = Node2D.new()
	map_root.name = "MapRoot"
	map_viewport.add_child(map_root)
	
	map_camera = Camera2D.new()
	map_camera.name = "MapCamera"
	map_camera.enabled = true
	map_camera.zoom = Vector2(0.5, 0.5)  # Start zoomed out
	map_root.add_child(map_camera)
	
	# Update viewport size to match container
	call_deferred("_update_viewport_size")


func _setup_generator() -> void:
	"""Setup map generator."""
	map_generator = MapGenerator.new()


func _setup_renderer() -> void:
	"""Setup map renderer."""
	if map_root == null:
		push_error("MapMakerModule: map_root is null")
		return
	
	map_renderer = MapRenderer.new()
	map_renderer.name = "MapRenderer"
	map_root.add_child(map_renderer)
	
	# Create render target using Sprite2D with shader material (ColorRect doesn't support materials properly)
	var render_target: Sprite2D = Sprite2D.new()
	render_target.name = "RenderTarget"
	render_target.position = Vector2.ZERO
	
	# Create a large texture for the sprite (will be updated by renderer)
	# Use a reasonable default size, will be updated when map data is set
	var texture: ImageTexture = ImageTexture.new()
	var placeholder_img: Image = Image.create(1024, 1024, false, Image.FORMAT_RGB8)
	placeholder_img.fill(Color(0.1, 0.2, 0.4, 1.0))  # Dark blue for ocean
	texture.set_image(placeholder_img)
	render_target.texture = texture
	
	# Scale will be set when world_map_data is available
	# For now, use a default scale
	render_target.scale = Vector2(1000.0 / 1024.0, 1000.0 / 1024.0)
	
	map_root.add_child(render_target)
	map_renderer.setup_render_target(render_target)


func _setup_editor() -> void:
	"""Setup map editor."""
	map_editor = MapEditor.new()
	
	# Add editor to viewport root
	var map_root: Node2D = map_viewport.get_node_or_null("MapRoot")
	if map_root != null:
		map_root.add_child(map_editor)


func _setup_marker_manager() -> void:
	"""Setup marker manager."""
	if map_root == null:
		return
	
	marker_manager = MarkerManager.new()
	marker_manager.name = "MarkerManager"
	map_root.add_child(marker_manager)


func _setup_ui() -> void:
	"""Setup UI panels and controls."""
	# Create main container with split layout
	var main_container: HSplitContainer = HSplitContainer.new()
	main_container.name = "MainContainer"
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(main_container)
	
	# Create left side (map canvas)
	var map_container: VBoxContainer = VBoxContainer.new()
	map_container.name = "MapContainer"
	main_container.add_child(map_container)
	
	# Create toolbar panel
	toolbar_panel = Panel.new()
	toolbar_panel.name = "ToolbarPanel"
	toolbar_panel.custom_minimum_size = Vector2(0, 50)
	map_container.add_child(toolbar_panel)
	
	# Create map canvas
	map_canvas = Control.new()
	map_canvas.name = "MapCanvas"
	map_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	map_container.add_child(map_canvas)
	
	# Create right side (params panel)
	params_panel = Panel.new()
	params_panel.name = "ParamsPanel"
	params_panel.custom_minimum_size = Vector2(300, 0)
	main_container.add_child(params_panel)
	
	_create_toolbar()
	_create_params_panel()


func _create_toolbar() -> void:
	"""Create toolbar with view mode and tool buttons."""
	var toolbar: HBoxContainer = HBoxContainer.new()
	toolbar.name = "Toolbar"
	toolbar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	toolbar.add_theme_constant_override("separation", 5)
	toolbar_panel.add_child(toolbar)
	
	# View mode buttons
	var view_label: Label = Label.new()
	view_label.text = "View:"
	toolbar.add_child(view_label)
	
	var heightmap_btn: Button = Button.new()
	heightmap_btn.text = "Heightmap"
	heightmap_btn.pressed.connect(func(): set_view_mode(MapRenderer.ViewMode.HEIGHTMAP))
	toolbar.add_child(heightmap_btn)
	
	var biomes_btn: Button = Button.new()
	biomes_btn.text = "Biomes"
	biomes_btn.pressed.connect(func(): set_view_mode(MapRenderer.ViewMode.BIOMES))
	toolbar.add_child(biomes_btn)
	
	# Tool buttons
	var tool_sep: Control = Control.new()
	tool_sep.custom_minimum_size = Vector2(20, 0)
	toolbar.add_child(tool_sep)
	
	var tool_label: Label = Label.new()
	tool_label.text = "Tools:"
	toolbar.add_child(tool_label)
	
	var raise_btn: Button = Button.new()
	raise_btn.text = "Raise"
	raise_btn.pressed.connect(func(): map_editor.set_tool(MapEditor.EditTool.RAISE))
	toolbar.add_child(raise_btn)
	
	var lower_btn: Button = Button.new()
	lower_btn.text = "Lower"
	lower_btn.pressed.connect(func(): map_editor.set_tool(MapEditor.EditTool.LOWER))
	toolbar.add_child(lower_btn)
	
	var smooth_btn: Button = Button.new()
	smooth_btn.text = "Smooth"
	smooth_btn.pressed.connect(func(): map_editor.set_tool(MapEditor.EditTool.SMOOTH))
	toolbar.add_child(smooth_btn)
	
	# Regenerate button
	var regen_sep: Control = Control.new()
	regen_sep.custom_minimum_size = Vector2(20, 0)
	toolbar.add_child(regen_sep)
	
	var regen_btn: Button = Button.new()
	regen_btn.text = "Regenerate"
	regen_btn.pressed.connect(_on_regenerate_pressed)
	toolbar.add_child(regen_btn)


func _create_params_panel() -> void:
	"""Create parameters panel for generation settings."""
	var params_scroll: ScrollContainer = ScrollContainer.new()
	params_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	params_panel.add_child(params_scroll)
	
	var params_vbox: VBoxContainer = VBoxContainer.new()
	params_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	params_scroll.add_child(params_vbox)
	
	# Noise frequency
	_create_param_slider(params_vbox, "Noise Frequency", "noise_frequency", 0.001, 0.1, 0.0005, 0.0001)
	
	# Octaves
	_create_param_spinbox(params_vbox, "Octaves", "noise_octaves", 1, 8, 4)
	
	# Persistence
	_create_param_slider(params_vbox, "Persistence", "noise_persistence", 0.0, 1.0, 0.5, 0.01)
	
	# Lacunarity
	_create_param_slider(params_vbox, "Lacunarity", "noise_lacunarity", 1.0, 4.0, 2.0, 0.1)
	
	# Sea level
	_create_param_slider(params_vbox, "Sea Level", "sea_level", 0.0, 1.0, 0.4, 0.01)
	
	# Erosion
	var erosion_check: CheckBox = CheckBox.new()
	erosion_check.text = "Enable Erosion"
	erosion_check.button_pressed = true
	erosion_check.toggled.connect(func(pressed): _on_param_changed("erosion_enabled", pressed))
	params_vbox.add_child(erosion_check)
	param_controls["erosion_enabled"] = erosion_check


func _create_param_slider(parent: VBoxContainer, label_text: String, param_name: String, min_val: float, max_val: float, default_val: float, step: float) -> void:
	"""Create a parameter slider control."""
	var container: HBoxContainer = HBoxContainer.new()
	
	var label: Label = Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size = Vector2(150, 0)
	container.add_child(label)
	
	var slider: HSlider = HSlider.new()
	slider.name = param_name
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step
	slider.value = default_val
	slider.value_changed.connect(func(v): _on_param_changed(param_name, v))
	container.add_child(slider)
	
	var value_label: Label = Label.new()
	value_label.name = param_name + "_value"
	value_label.custom_minimum_size = Vector2(80, 0)
	value_label.text = str(default_val)
	container.add_child(value_label)
	
	parent.add_child(container)
	param_controls[param_name] = slider
	param_controls[param_name + "_value"] = value_label


func _create_param_spinbox(parent: VBoxContainer, label_text: String, param_name: String, min_val: int, max_val: int, default_val: int) -> void:
	"""Create a parameter spinbox control."""
	var container: HBoxContainer = HBoxContainer.new()
	
	var label: Label = Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size = Vector2(150, 0)
	container.add_child(label)
	
	var spinbox: SpinBox = SpinBox.new()
	spinbox.name = param_name
	spinbox.min_value = min_val
	spinbox.max_value = max_val
	spinbox.value = default_val
	spinbox.value_changed.connect(func(v): _on_param_changed(param_name, int(v)))
	container.add_child(spinbox)
	
	parent.add_child(container)
	param_controls[param_name] = spinbox


func initialize_from_step_data(seed_value: int, width: int, height: int) -> void:
	"""Initialize map from Step 1 data (seed, size)."""
	if is_initialized:
		return
	
	# Create world map data
	world_map_data = WorldMapData.new()
	world_map_data.seed = seed_value
	world_map_data.world_width = width
	world_map_data.world_height = height
	
	# Create heightmap image (use power-of-2 for better performance, but match aspect ratio)
	var map_size_x: int = max(512, next_power_of_2(int(width)))
	var map_size_y: int = max(512, next_power_of_2(int(height)))
	world_map_data.create_heightmap(map_size_x, map_size_y)
	
	# Update render target sprite scale to match world size
	var render_target: Sprite2D = map_root.get_node_or_null("RenderTarget") as Sprite2D
	if render_target != null and render_target.texture != null:
		var tex_size: Vector2 = render_target.texture.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			render_target.scale = Vector2(float(width) / tex_size.x, float(height) / tex_size.y)
	
	# Connect components
	if map_renderer != null:
		map_renderer.set_world_map_data(world_map_data)
	if map_editor != null:
		map_editor.set_world_map_data(world_map_data)
	if marker_manager != null:
		marker_manager.set_world_map_data(world_map_data)
	
	# Generate initial map
	generate_map()
	
	is_initialized = true


func generate_map() -> void:
	"""Generate map using current parameters."""
	if world_map_data == null:
		return
	
	print("MapMakerModule: Generating map...")
	map_generator.generate_map(world_map_data, false)  # Synchronous for now
	
	# Generate biome preview
	map_generator.generate_biome_preview(world_map_data)
	
	# Refresh renderer
	map_renderer.refresh()
	
	print("MapMakerModule: Map generation complete")


func set_view_mode(mode: MapRenderer.ViewMode) -> void:
	"""Set map view mode."""
	current_view_mode = mode
	if map_renderer != null:
		map_renderer.set_view_mode(mode)


func _on_regenerate_pressed() -> void:
	"""Handle regenerate button press."""
	generate_map()


func _on_param_changed(param_name: String, value: Variant) -> void:
	"""Handle parameter change."""
	if world_map_data == null:
		return
	
	# Update world_map_data parameter
	match param_name:
		"noise_frequency":
			world_map_data.noise_frequency = float(value)
		"noise_octaves":
			world_map_data.noise_octaves = int(value)
		"noise_persistence":
			world_map_data.noise_persistence = float(value)
		"noise_lacunarity":
			world_map_data.noise_lacunarity = float(value)
		"sea_level":
			world_map_data.sea_level = float(value)
		"erosion_enabled":
			world_map_data.erosion_enabled = bool(value)
	
	# Update value label if it exists
	var value_label: Label = param_controls.get(param_name + "_value") as Label
	if value_label != null:
		value_label.text = str(value)
	
	# Auto-regenerate if parameter changed (optional - can be disabled)
	# generate_map()


func get_world_map_data() -> WorldMapData:
	"""Get world map data (for export to Step 3)."""
	return world_map_data


func _on_viewport_container_resized() -> void:
	"""Handle viewport container resize."""
	_update_viewport_size()


func _update_viewport_size() -> void:
	"""Update viewport size to match container."""
	if map_viewport_container != null and map_viewport != null:
		var container_size: Vector2 = map_viewport_container.size
		if container_size.x > 0 and container_size.y > 0:
			map_viewport.size = Vector2i(int(container_size.x), int(container_size.y))


func _on_viewport_container_input(event: InputEvent) -> void:
	"""Handle input events from viewport container."""
	if map_viewport_container == null or not map_viewport_container.is_visible_in_tree():
		return
	
	# Handle mouse input for editing
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		var world_pos: Vector2 = _screen_to_world_position(mouse_event.position)
		
		if mouse_event.pressed:
			if mouse_event.button_index == MOUSE_BUTTON_LEFT:
				if map_editor != null:
					map_editor.start_paint(world_pos)
			elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
				# Right-click for marker placement (future)
				pass
			elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
				if map_camera != null:
					map_camera.zoom *= 1.2
			elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if map_camera != null:
					map_camera.zoom /= 1.2
		else:
			if mouse_event.button_index == MOUSE_BUTTON_LEFT:
				if map_editor != null:
					map_editor.end_paint()
				if map_renderer != null:
					map_renderer.refresh()
	
	elif event is InputEventMouseMotion:
		var mouse_event: InputEventMouseMotion = event as InputEventMouseMotion
		var world_pos: Vector2 = _screen_to_world_position(mouse_event.position)
		
		# Handle pan with middle mouse or right-click drag
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			if map_camera != null:
				map_camera.position -= mouse_event.relative / map_camera.zoom
		elif map_editor != null:
			# Handle painting
			map_editor.continue_paint(world_pos)
			if map_editor.is_painting and map_renderer != null:
				map_renderer.refresh()


func _screen_to_world_position(screen_pos: Vector2) -> Vector2:
	"""Convert screen position to world position."""
	if map_camera == null or map_viewport == null or map_viewport_container == null:
		return Vector2.ZERO
	
	# Get local position within viewport container
	var local_pos: Vector2 = map_viewport_container.get_local_mouse_position()
	
	# Convert to viewport coordinates
	var viewport_size: Vector2 = map_viewport.size
	var container_size: Vector2 = map_viewport_container.size
	
	# Scale local position to viewport coordinates
	var viewport_pos: Vector2 = (local_pos / container_size) * viewport_size
	
	# Convert viewport position to world coordinates using camera
	# Camera2D's get_global_mouse_position() works in viewport coordinates
	# We need to convert from viewport pixel space to world space
	var camera_pos: Vector2 = map_camera.position
	var screen_center: Vector2 = viewport_size / 2.0
	var world_offset: Vector2 = (viewport_pos - screen_center) / map_camera.zoom
	var world_pos: Vector2 = camera_pos + world_offset
	
	return world_pos