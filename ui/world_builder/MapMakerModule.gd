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

## Terrain3DManager reference
var terrain_3d_manager = null  # Terrain3DManager - type hint removed


func _ready() -> void:
	"""Initialize MapMakerModule."""
	print("DEBUG: MapMakerModule._ready() called")
	_setup_ui()
	_setup_viewport()
	_setup_generator()
	_setup_renderer()
	_setup_editor()
	_setup_marker_manager()
	_setup_keyboard_shortcuts()
	print("DEBUG: MapMakerModule._ready() complete")


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
	map_viewport_container.visible = true
	map_viewport_container.gui_input.connect(_on_viewport_container_input)
	map_viewport_container.resized.connect(_on_viewport_container_resized)
	map_viewport_container.add_child(map_viewport)
	
	map_canvas.add_child(map_viewport_container)
	print("DEBUG: Viewport container added to canvas, visible:", map_viewport_container.visible)
	
	# Setup camera and root
	map_root = Node2D.new()
	map_root.name = "MapRoot"
	map_viewport.add_child(map_root)
	print("DEBUG: MapRoot added to viewport")
	
	map_camera = Camera2D.new()
	map_camera.name = "MapCamera"
	map_camera.enabled = true
	map_camera.zoom = Vector2(0.5, 0.5)  # Start zoomed out
	map_root.add_child(map_camera)
	print("DEBUG: Camera added, enabled:", map_camera.enabled, " zoom:", map_camera.zoom)
	
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


func _setup_parchment_overlay() -> void:
	"""Setup parchment-style background overlay."""
	if map_canvas == null:
		return
	
	# Create ColorRect for parchment overlay (behind viewport)
	var parchment_overlay: ColorRect = ColorRect.new()
	parchment_overlay.name = "ParchmentOverlay"
	parchment_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parchment_overlay.color = Color(1.0, 1.0, 1.0, 1.0)
	parchment_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let input pass through
	
	# Create shader material
	var shader: Shader = load("res://shaders/parchment.gdshader")
	if shader != null:
		var shader_material: ShaderMaterial = ShaderMaterial.new()
		shader_material.shader = shader
		
		# Load parchment texture (if available, otherwise will use default)
		var parchment_texture_path: String = "res://assets/textures/ui/parchment_background.png"
		if ResourceLoader.exists(parchment_texture_path):
			var parchment_texture: Texture2D = load(parchment_texture_path)
			shader_material.set_shader_parameter("parchment_texture", parchment_texture)
		else:
			# Fallback: create a simple beige texture
			var fallback_img: Image = Image.create(256, 256, false, Image.FORMAT_RGB8)
			fallback_img.fill(Color(0.85, 0.75, 0.65, 1.0))  # Parchment beige
			var fallback_texture: ImageTexture = ImageTexture.new()
			fallback_texture.set_image(fallback_img)
			shader_material.set_shader_parameter("parchment_texture", fallback_texture)
			push_warning("MapMakerModule: Parchment texture not found at " + parchment_texture_path + ", using fallback")
		
		parchment_overlay.material = shader_material
	else:
		push_error("MapMakerModule: Failed to load parchment shader")
	
	# Add as first child (behind viewport container)
	map_canvas.add_child(parchment_overlay)
	# Move to back by setting z_index (lower z_index renders first/behind)
	parchment_overlay.z_index = -1


func _setup_ui() -> void:
	"""Setup UI panels and controls."""
	# Create main container (no split - params are in left sidebar now)
	var main_container: VBoxContainer = VBoxContainer.new()
	main_container.name = "MainContainer"
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(main_container)
	
	# Create toolbar panel
	toolbar_panel = Panel.new()
	toolbar_panel.name = "ToolbarPanel"
	toolbar_panel.custom_minimum_size = Vector2(0, 50)
	main_container.add_child(toolbar_panel)
	
	# Create map canvas (fills remaining space)
	map_canvas = Control.new()
	map_canvas.name = "MapCanvas"
	map_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	map_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(map_canvas)
	
	# Create parchment overlay (behind everything)
	_setup_parchment_overlay()
	
	_create_toolbar()
	# Note: Parameter controls are now in WorldBuilderUI left sidebar, not here


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
	
	# Generate 3D World button
	var generate_3d_sep: Control = Control.new()
	generate_3d_sep.custom_minimum_size = Vector2(20, 0)
	toolbar.add_child(generate_3d_sep)
	
	var generate_3d_btn: Button = Button.new()
	generate_3d_btn.name = "Generate3DButton"
	generate_3d_btn.text = "Generate 3D World"
	generate_3d_btn.tooltip_text = "Turn your hand-drawn parchment map into the real 3D world"
	generate_3d_btn.pressed.connect(_on_generate_3d_button_pressed)
	toolbar.add_child(generate_3d_btn)


func _create_params_panel() -> void:
	"""Create parameters panel for generation settings - DEPRECATED: Controls now in left sidebar."""
	# This function is kept for compatibility but no longer creates UI
	# Parameter controls are now created in WorldBuilderUI._create_step_map_gen_editor()
	pass


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
	print("DEBUG: initialize_from_step_data called - seed:", seed_value, " width:", width, " height:", height)
	if is_initialized:
		print("DEBUG: Already initialized, skipping")
		return
	
	# Create world map data
	world_map_data = WorldMapData.new()
	world_map_data.seed = seed_value
	world_map_data.world_width = width
	world_map_data.world_height = height
	
	# Create heightmap image (use power-of-2 for better performance, but match aspect ratio)
	var map_size_x: int = max(512, _next_power_of_2(int(width)))
	var map_size_y: int = max(512, _next_power_of_2(int(height)))
	print("DEBUG: Creating heightmap image size:", map_size_x, "x", map_size_y)
	world_map_data.create_heightmap(map_size_x, map_size_y)
	print("DEBUG: Heightmap created, image is null:", world_map_data.heightmap_image == null)
	if world_map_data.heightmap_image != null:
		print("DEBUG: Heightmap image size:", world_map_data.heightmap_image.get_size())
	
	# Update render target sprite scale to match world size
	var render_target: Sprite2D = map_root.get_node_or_null("RenderTarget") as Sprite2D
	print("DEBUG: Render target found:", render_target != null)
	if render_target != null and render_target.texture != null:
		var tex_size: Vector2 = render_target.texture.get_size()
		print("DEBUG: Render target texture size:", tex_size)
		if tex_size.x > 0 and tex_size.y > 0:
			render_target.scale = Vector2(float(width) / tex_size.x, float(height) / tex_size.y)
			print("DEBUG: Render target scale set to:", render_target.scale)
	
	# Connect components
	if map_renderer != null:
		print("DEBUG: Setting world_map_data to renderer")
		map_renderer.set_world_map_data(world_map_data)
	else:
		print("DEBUG: ERROR - map_renderer is null!")
	if map_editor != null:
		map_editor.set_world_map_data(world_map_data)
	if marker_manager != null:
		marker_manager.set_world_map_data(world_map_data)
	
	# Generate initial map
	generate_map()
	
	is_initialized = true
	print("DEBUG: initialize_from_step_data complete, is_initialized:", is_initialized)


func generate_map() -> void:
	"""Generate map using current parameters."""
	if world_map_data == null:
		print("DEBUG: generate_map() - world_map_data is null, aborting")
		return
	
	print("DEBUG: MapMakerModule: Generating map...")
	if map_generator == null:
		print("DEBUG: ERROR - map_generator is null!")
		return
	
	map_generator.generate_map(world_map_data, false)  # Synchronous for now
	print("DEBUG: Generation complete, checking heightmap...")
	if world_map_data.heightmap_image != null:
		var sample_pos: Vector2i = Vector2i(100, 100)
		var size: Vector2i = world_map_data.heightmap_image.get_size()
		if sample_pos.x < size.x and sample_pos.y < size.y:
			var sample_color: Color = world_map_data.heightmap_image.get_pixel(sample_pos.x, sample_pos.y)
			print("DEBUG: Heightmap sample at (100,100): r=", sample_color.r, " (should be > 0)")
	
	# Generate biome preview
	print("DEBUG: Generating biome preview...")
	map_generator.generate_biome_preview(world_map_data)
	if world_map_data.biome_preview_image != null:
		print("DEBUG: Biome preview generated, size:", world_map_data.biome_preview_image.get_size())
	
	# Refresh renderer
	print("DEBUG: Refreshing renderer...")
	if map_renderer != null:
		map_renderer.refresh()
	else:
		print("DEBUG: ERROR - map_renderer is null, cannot refresh!")
	
	print("DEBUG: MapMakerModule: Map generation complete")


func regenerate_map(params: Dictionary) -> bool:
	"""
	Regenerate map with new parameters from dictionary.
	
	Custom MapMakerModule is the default and preferred 2D preview renderer.
	This method reconfigures and regenerates the map with provided parameters.
	
	Args:
		params: Dictionary containing generation parameters:
			- seed (int): Generation seed
			- width (int): Map width
			- height (int): Map height
			- noise_frequency (float): Noise frequency
			- noise_octaves (int): Noise octaves
			- noise_persistence (float): Noise persistence
			- noise_lacunarity (float): Noise lacunarity
			- sea_level (float): Sea level (0.0-1.0)
			- erosion_enabled (bool): Enable erosion
			- noise_type (int, optional): FastNoiseLite noise type
	
	Returns:
		bool: True if regeneration succeeded, False on failure
	"""
	MythosLogger.info("UI/MapMakerModule", "regenerate_map() called", {"params_keys": params.keys()})
	
	# Validate required parameters
	if not params.has("seed") or not params.has("width") or not params.has("height"):
		MythosLogger.error("UI/MapMakerModule", "regenerate_map() missing required parameters (seed, width, height)")
		return false
	
	# Initialize or update world_map_data
	if world_map_data == null:
		world_map_data = WorldMapData.new()
		is_initialized = false
	
	# Update basic parameters
	world_map_data.seed = params.get("seed", world_map_data.seed)
	world_map_data.world_width = params.get("width", world_map_data.world_width)
	world_map_data.world_height = params.get("height", world_map_data.world_height)
	world_map_data.landmass_type = params.get("landmass_type", world_map_data.landmass_type)
	
	# Update noise parameters
	world_map_data.noise_frequency = params.get("noise_frequency", world_map_data.noise_frequency)
	world_map_data.noise_octaves = params.get("noise_octaves", world_map_data.noise_octaves)
	world_map_data.noise_persistence = params.get("noise_persistence", world_map_data.noise_persistence)
	world_map_data.noise_lacunarity = params.get("noise_lacunarity", world_map_data.noise_lacunarity)
	world_map_data.sea_level = params.get("sea_level", world_map_data.sea_level)
	world_map_data.erosion_enabled = params.get("erosion_enabled", world_map_data.erosion_enabled)
	world_map_data.biome_temperature_noise_frequency = params.get("temperature_noise_frequency", world_map_data.biome_temperature_noise_frequency)
	world_map_data.biome_moisture_noise_frequency = params.get("moisture_noise_frequency", world_map_data.biome_moisture_noise_frequency)
	world_map_data.temperature_bias = params.get("temperature_bias", world_map_data.temperature_bias)
	world_map_data.moisture_bias = params.get("moisture_bias", world_map_data.moisture_bias)
	
	if params.has("noise_type"):
		world_map_data.noise_type = params.get("noise_type", world_map_data.noise_type)
	
	# Update MapGenerator biome transition width if provided
	if params.has("biome_transition_width") and map_generator != null:
		map_generator.biome_transition_width = params.get("biome_transition_width", 0.05)
	
	# Check if heightmap needs to be recreated (size changed or not initialized)
	var map_size_x: int = max(512, _next_power_of_2(int(world_map_data.world_width)))
	var map_size_y: int = max(512, _next_power_of_2(int(world_map_data.world_height)))
	var needs_recreate: bool = false
	
	if not is_initialized or world_map_data.heightmap_image == null:
		needs_recreate = true
	else:
		# Check if size changed
		var existing_size: Vector2i = world_map_data.heightmap_image.get_size()
		if existing_size.x != map_size_x or existing_size.y != map_size_y:
			needs_recreate = true
		else:
			# Size is same, but we still need to clear old data for regeneration
			# Clear the existing heightmap to remove old map data
			world_map_data.heightmap_image.fill(Color.BLACK)
			MythosLogger.debug("UI/MapMakerModule", "Cleared existing heightmap for regeneration")
	
	# Recreate heightmap if needed
	if needs_recreate:
		world_map_data.create_heightmap(map_size_x, map_size_y)
		
		# Update render target sprite scale
		var render_target: Sprite2D = map_root.get_node_or_null("RenderTarget") as Sprite2D
		if render_target != null and render_target.texture != null:
			var tex_size: Vector2 = render_target.texture.get_size()
			if tex_size.x > 0 and tex_size.y > 0:
				render_target.scale = Vector2(float(world_map_data.world_width) / tex_size.x, float(world_map_data.world_height) / tex_size.y)
		
		# Connect components if not already done
		if map_renderer != null:
			map_renderer.set_world_map_data(world_map_data)
		if map_editor != null:
			map_editor.set_world_map_data(world_map_data)
		if marker_manager != null:
			marker_manager.set_world_map_data(world_map_data)
		
		is_initialized = true
	else:
		# Ensure components are connected even if not recreating
		if map_renderer != null and map_renderer.world_map_data != world_map_data:
			map_renderer.set_world_map_data(world_map_data)
		if map_editor != null and map_editor.world_map_data != world_map_data:
			map_editor.set_world_map_data(world_map_data)
		if marker_manager != null and marker_manager.world_map_data != world_map_data:
			marker_manager.set_world_map_data(world_map_data)
	
	# Clear old map data before generating new map
	# This ensures the old map is completely removed before new generation
	if world_map_data.heightmap_image != null:
		world_map_data.heightmap_image.fill(Color.BLACK)
		MythosLogger.debug("UI/MapMakerModule", "Cleared existing heightmap before regeneration")
	
	# Clear biome preview image to force regeneration
	world_map_data.biome_preview_image = null
	
	# Attempt generation with error handling
	var generation_success: bool = false
	if map_generator == null:
		MythosLogger.error("UI/MapMakerModule", "regenerate_map() - map_generator is null")
		return false
	
	# Try to generate map
	MythosLogger.debug("UI/MapMakerModule", "Starting map generation", {
		"seed": world_map_data.seed,
		"size": Vector2i(world_map_data.world_width, world_map_data.world_height)
	})
	
	map_generator.generate_map(world_map_data, false)  # Synchronous
	
	# Validate generation result
	if world_map_data.heightmap_image == null:
		MythosLogger.error("UI/MapMakerModule", "regenerate_map() - heightmap_image is null after generation")
		return false
	
	# Check if heightmap has valid data (not all zeros)
	var sample_pos: Vector2i = Vector2i(min(100, world_map_data.heightmap_image.get_width() - 1), min(100, world_map_data.heightmap_image.get_height() - 1))
	var sample_color: Color = world_map_data.heightmap_image.get_pixel(sample_pos.x, sample_pos.y)
	if sample_color.r <= 0.0:
		MythosLogger.warn("UI/MapMakerModule", "regenerate_map() - heightmap appears empty (sample is zero)")
		# Don't fail here - might be valid for very low maps
	
	# Generate biome preview
	map_generator.generate_biome_preview(world_map_data)
	if world_map_data.biome_preview_image == null:
		MythosLogger.warn("UI/MapMakerModule", "regenerate_map() - biome_preview_image is null after generation")
		# Non-fatal, but log warning
	
	# Refresh renderer to display new map (this will update textures and force redraw)
	if map_renderer != null:
		# Force renderer to update with new data
		map_renderer.set_world_map_data(world_map_data)  # Ensure renderer has latest data
		map_renderer.refresh()  # This updates textures and triggers redraw
		generation_success = true
		
		# Force viewport update to ensure new map is displayed
		if map_viewport != null:
			map_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			# Then set back to always update
			call_deferred("_set_viewport_update_always")
	else:
		MythosLogger.error("UI/MapMakerModule", "regenerate_map() - map_renderer is null, cannot refresh")
		return false
	
	MythosLogger.info("UI/MapMakerModule", "regenerate_map() completed successfully")
	return generation_success


func _set_viewport_update_always() -> void:
	"""Helper to set viewport update mode back to always."""
	if map_viewport != null:
		map_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS


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
	
	# Update value label if it exists (for external controls)
	var value_label: Label = param_controls.get(param_name + "_value") as Label
	if value_label != null:
		value_label.text = str(value)
	
	# Auto-regenerate if parameter changed (optional - can be disabled)
	# generate_map()


func connect_external_param_control(param_name: String, control: Control, value_label: Label = null) -> void:
	"""Connect an external control (from WorldBuilderUI) to parameter change handler."""
	param_controls[param_name] = control
	if value_label != null:
		param_controls[param_name + "_value"] = value_label


func get_world_map_data() -> WorldMapData:
	"""Get world map data (for export to Step 3)."""
	return world_map_data


func set_terrain_manager(manager) -> void:  # manager: Terrain3DManager - type hint removed
	"""Set terrain manager reference for 3D generation."""
	terrain_3d_manager = manager


func _on_generate_3d_button_pressed() -> void:
	"""Handle Generate 3D World button press."""
	if world_map_data == null or world_map_data.heightmap_image == null:
		push_error("MapMakerModule: No heightmap to generate from!")
		# Try to show notification via parent WorldBuilderUI if available
		var parent_ui: Node = get_parent()
		while parent_ui != null:
			if parent_ui.has_method("_show_notification"):
				parent_ui._show_notification("No heightmap available! Generate a map first.", Color.RED)
				break
			parent_ui = parent_ui.get_parent()
		return
	
	if terrain_3d_manager == null:
		push_error("MapMakerModule: Terrain3DManager not set! Cannot generate 3D terrain.")
		# Try to find it in the scene tree
		var world_root: Node = get_tree().get_first_node_in_group("world_root")
		if world_root == null:
			world_root = get_tree().root.get_node_or_null("WorldRoot")
		if world_root != null:
			var manager: Node = world_root.get_node_or_null("Terrain3DManager")
			if manager != null:
				terrain_3d_manager = manager
				print("MapMakerModule: Found Terrain3DManager in scene tree")
			else:
				push_error("MapMakerModule: Terrain3DManager not found in scene tree")
				return
		else:
			push_error("MapMakerModule: WorldRoot not found in scene tree")
			return
	
	# Optional: Save EXR for debugging
	var save_path: String = "user://exports/last_hand_drawn_heightmap.exr"
	DirAccess.make_dir_recursive_absolute("user://exports/")
	var save_result: Error = world_map_data.heightmap_image.save_exr(save_path, true)
	if save_result == OK:
		print("MapMakerModule: Saved heightmap to ", save_path)
	else:
		push_warning("MapMakerModule: Failed to save heightmap EXR: ", save_result)
	
	# Calculate world size (assuming 1 pixel = 1 meter)
	var size_x: float = float(world_map_data.heightmap_image.get_width())
	var size_z: float = float(world_map_data.heightmap_image.get_height())
	var center_pos: Vector3 = Vector3(-size_x / 2.0, 0.0, -size_z / 2.0)
	
	# Call the new method
	terrain_3d_manager.generate_from_heightmap(
		world_map_data.heightmap_image.duplicate(),  # duplicate to be safe
		-50.0,
		300.0,
		center_pos
	)
	
	# Switch to 3D preview step (if WorldBuilderUI exists)
	var world_builder_ui: Control = get_tree().get_first_node_in_group("world_builder_ui")
	if world_builder_ui == null:
		# Try to find it by name or by traversing up the tree
		world_builder_ui = get_tree().root.find_child("WorldBuilderUI", true, false) as Control
		if world_builder_ui == null:
			# Try parent
			var parent_node: Node = get_parent()
			while parent_node != null:
				if parent_node.name == "WorldBuilderUI" or parent_node.has_method("_update_step_display"):
					world_builder_ui = parent_node as Control
					break
				parent_node = parent_node.get_parent()
	
	if world_builder_ui != null:
		# Set current_step to 2 (Terrain step) and update display
		if world_builder_ui.has("current_step"):
			world_builder_ui.current_step = 2  # Step 2 is "Terrain" (0-indexed: 0=Seed, 1=2D Map, 2=Terrain)
			if world_builder_ui.has_method("_update_step_display"):
				world_builder_ui._update_step_display()
			print("MapMakerModule: Switched to Terrain preview step")
	
	# Show success message
	print("MapMakerModule: 3D world generated from parchment drawing!")
	# Try to show notification if method exists
	if world_builder_ui != null and world_builder_ui.has_method("_show_notification"):
		world_builder_ui._show_notification("3D world generated from your parchment drawing!", Color.GREEN)


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


func _setup_keyboard_shortcuts() -> void:
	"""Setup keyboard shortcuts for map editor."""
	# Ctrl+Enter to generate 3D world
	# This will be handled in _unhandled_key_input()


func _next_power_of_2(value: int) -> int:
	"""Calculate the next power of 2 greater than or equal to value."""
	if value <= 0:
		return 1
	var power: int = 1
	while power < value:
		power *= 2
	return power


func _unhandled_key_input(event: InputEvent) -> void:
	"""Handle keyboard shortcuts."""
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed:
			# Ctrl+Enter to generate 3D world
			if key_event.keycode == KEY_ENTER and (key_event.ctrl_pressed or key_event.meta_pressed):
				_on_generate_3d_button_pressed()
				get_viewport().set_input_as_handled()