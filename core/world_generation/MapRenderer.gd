# ╔═══════════════════════════════════════════════════════════
# ║ MapRenderer.gd
# ║ Desc: Renders map using ShaderMaterial for efficient display (hillshading, biomes, overlays)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node2D
class_name MapRenderer

## Reference to world map data
var world_map_data: WorldMapData

## Rendering view mode (0=heightmap, 1=biomes, 2=political)
enum ViewMode { HEIGHTMAP, BIOMES, POLITICAL }
var current_view_mode: ViewMode = ViewMode.BIOMES

## Refresh mode for adaptive throttling
enum RefreshMode { INTERACTIVE, GENERATION, REGENERATION }
@export var current_refresh_mode: RefreshMode = RefreshMode.INTERACTIVE

## Mode-specific refresh intervals (milliseconds)
const MIN_REFRESH_MS: Dictionary = {
	RefreshMode.INTERACTIVE: 100,      # 10 refreshes/sec for light brushing
	RefreshMode.GENERATION: 16,        # ~60 refreshes/sec for full initial gen
	RefreshMode.REGENERATION: 33       # ~30 refreshes/sec for heavy brush re-sims
}

## TextureRect, ColorRect, or Sprite2D for rendering
var render_target: Node

## Shader material for map rendering
var shader_material: ShaderMaterial

## Texture resources
var heightmap_texture: ImageTexture
var biome_texture: ImageTexture
var rivers_texture: ImageTexture

## Camera for pan/zoom
var camera: Camera2D

## Light direction for hillshading
var light_direction: Vector2 = Vector2(0.5, 0.5)

## Refresh throttling to prevent excessive refresh calls
var last_refresh_time: int = 0
var pending_refresh: bool = false

## PROFILING: Data accumulation
var profiling_refresh_calls: int = 0
var profiling_refresh_over_1ms: int = 0
var profiling_refresh_over_10ms: int = 0
var profiling_refresh_times: Array[float] = []


func _init() -> void:
	"""Initialize MapRenderer."""
	MythosLogger.verbose("World/Rendering", "MapRenderer._init() called")
	# Create shader material
	var shader: Shader = load("res://shaders/map_renderer.gdshader")
	MythosLogger.debug("World/Rendering", "Shader loaded", {"loaded": shader != null})
	if shader != null:
		shader_material = ShaderMaterial.new()
		shader_material.shader = shader
		MythosLogger.info("World/Rendering", "Shader material created and assigned")
	else:
		MythosLogger.error("World/Rendering", "Failed to load map_renderer shader from res://shaders/map_renderer.gdshader")


func setup_render_target(target: Node) -> void:
	"""Setup rendering target (TextureRect, ColorRect, or Sprite2D)."""
	MythosLogger.verbose("World/Rendering", "setup_render_target() called", {"target_type": target.get_class() if target else "null"})
	render_target = target
	
	if render_target != null and shader_material != null:
		if render_target is TextureRect:
			(render_target as TextureRect).material = shader_material
			MythosLogger.debug("World/Rendering", "Shader material applied to TextureRect")
		elif render_target is ColorRect:
			(render_target as ColorRect).material = shader_material
			MythosLogger.debug("World/Rendering", "Shader material applied to ColorRect")
		elif render_target is Sprite2D:
			(render_target as Sprite2D).material = shader_material
			MythosLogger.debug("World/Rendering", "Shader material applied to Sprite2D")
		elif render_target.has_method("set_material"):
			render_target.set("material", shader_material)
			MythosLogger.debug("World/Rendering", "Shader material applied via set_material()")
	else:
		if render_target == null:
			MythosLogger.warn("World/Rendering", "Cannot setup render target - target is null")
		if shader_material == null:
			MythosLogger.warn("World/Rendering", "Cannot setup render target - shader_material is null")


func set_world_map_data(data: WorldMapData) -> void:
	"""Set world map data and update textures."""
	MythosLogger.verbose("World/Rendering", "set_world_map_data() called")
	world_map_data = data
	_update_textures()


func _update_textures() -> void:
	"""Update shader textures from world_map_data."""
	MythosLogger.verbose("World/Rendering", "_update_textures() called")
	if world_map_data == null:
		MythosLogger.error("World/Rendering", "world_map_data is null")
		return
	if world_map_data.heightmap_image == null:
		MythosLogger.error("World/Rendering", "heightmap_image is null")
		return
	
	var image_size: Vector2i = world_map_data.heightmap_image.get_size()
	MythosLogger.debug("World/Rendering", "Updating textures", {"heightmap_size": image_size})
	
	# Update heightmap texture - use update() if same image reference (faster, non-blocking)
	if heightmap_texture == null:
		heightmap_texture = ImageTexture.new()
		heightmap_texture.set_image(world_map_data.heightmap_image)
		MythosLogger.debug("World/Rendering", "Heightmap texture created", {"size": heightmap_texture.get_size()})
	else:
		var current_image: Image = heightmap_texture.get_image()
		if current_image == world_map_data.heightmap_image:
			# Same image reference - use update() instead of set_image() (faster, non-blocking)
			heightmap_texture.update()
			MythosLogger.debug("World/Rendering", "Heightmap texture updated via update()", {"size": heightmap_texture.get_size()})
		else:
			# Different image reference, need full update (blocking, but necessary)
			heightmap_texture.set_image(world_map_data.heightmap_image)
			MythosLogger.debug("World/Rendering", "Heightmap texture updated via set_image()", {"size": heightmap_texture.get_size()})
	
	# Update biome texture - use update() if same image reference (optimization)
	var biome_image: Image = null
	if world_map_data.biome_preview_image != null:
		biome_image = world_map_data.biome_preview_image
	else:
		# Generate biome preview if not exists
		MythosLogger.verbose("World/Rendering", "Generating biome preview image")
		# Remove type hint to avoid parse-time dependency on MapGenerator
		var generator = MapGenerator.new()
		biome_image = generator.generate_biome_preview(world_map_data)
		if biome_image == null:
			MythosLogger.warn("World/Rendering", "Failed to generate biome preview image")
	
	if biome_image != null:
		if biome_texture == null:
			biome_texture = ImageTexture.new()
			biome_texture.set_image(biome_image)
			MythosLogger.debug("World/Rendering", "Biome texture created", {"size": biome_image.get_size()})
		else:
			var current_image: Image = biome_texture.get_image()
			if current_image == biome_image:
				# Same image reference - use update() instead of set_image() (faster, non-blocking)
				biome_texture.update()
				MythosLogger.debug("World/Rendering", "Biome texture updated via update()", {"size": biome_image.get_size()})
			else:
				# Different image reference, need full update (blocking, but necessary)
				biome_texture.set_image(biome_image)
				MythosLogger.debug("World/Rendering", "Biome texture updated via set_image()", {"size": biome_image.get_size()})
	
	# Create empty rivers texture (for now) - only create once, reuse
	if rivers_texture == null:
		rivers_texture = ImageTexture.new()
		var rivers_img: Image = Image.create(
			world_map_data.heightmap_image.get_size().x,
			world_map_data.heightmap_image.get_size().y,
			false,
			Image.FORMAT_RF
		)
		rivers_img.fill(Color.BLACK)
		rivers_texture.set_image(rivers_img)
		MythosLogger.debug("World/Rendering", "Rivers texture created", {"size": rivers_img.get_size()})
	# Note: Rivers texture is static (all black), so no update needed
	
	# Apply textures to shader
	if shader_material != null:
		MythosLogger.verbose("World/Rendering", "Applying textures to shader material")
		shader_material.set_shader_parameter("heightmap_texture", heightmap_texture)
		shader_material.set_shader_parameter("biome_texture", biome_texture if biome_texture != null else heightmap_texture)
		shader_material.set_shader_parameter("rivers_texture", rivers_texture)
		shader_material.set_shader_parameter("sea_level", world_map_data.sea_level)
		shader_material.set_shader_parameter("light_direction", light_direction)
		MythosLogger.debug("World/Rendering", "Shader parameters set", {
			"render_target": render_target != null,
			"render_target_type": render_target.get_class() if render_target else "null"
		})
		if render_target != null and render_target is Sprite2D:
			var sprite: Sprite2D = render_target as Sprite2D
			MythosLogger.verbose("World/Rendering", "Sprite2D render target", {
				"has_material": sprite.material != null,
				"has_texture": sprite.texture != null
			})
	else:
		MythosLogger.error("World/Rendering", "shader_material is null!")


func set_view_mode(mode: ViewMode) -> void:
	"""Change view mode (heightmap, biomes, political)."""
	var mode_name: String
	match mode:
		ViewMode.HEIGHTMAP:
			mode_name = "HEIGHTMAP"
		ViewMode.BIOMES:
			mode_name = "BIOMES"
		ViewMode.POLITICAL:
			mode_name = "POLITICAL"
	MythosLogger.verbose("World/Rendering", "set_view_mode() called", {"mode": mode_name})
	current_view_mode = mode
	
	if shader_material != null:
		match mode:
			ViewMode.HEIGHTMAP:
				shader_material.set_shader_parameter("show_heightmap", true)
				shader_material.set_shader_parameter("show_biomes", false)
				MythosLogger.debug("World/Rendering", "View mode set to HEIGHTMAP")
			ViewMode.BIOMES:
				shader_material.set_shader_parameter("show_heightmap", false)
				shader_material.set_shader_parameter("show_biomes", true)
				MythosLogger.debug("World/Rendering", "View mode set to BIOMES")
			ViewMode.POLITICAL:
				shader_material.set_shader_parameter("show_heightmap", false)
				shader_material.set_shader_parameter("show_biomes", true)  # Placeholder
				MythosLogger.debug("World/Rendering", "View mode set to POLITICAL (placeholder)")
	else:
		MythosLogger.warn("World/Rendering", "Cannot set view mode - shader_material is null")


func set_rivers_visible(visible: bool) -> void:
	"""Toggle river overlay visibility."""
	if shader_material != null:
		shader_material.set_shader_parameter("show_rivers", visible)


func set_light_direction(direction: Vector2) -> void:
	"""Set light direction for hillshading (normalized 0-1)."""
	light_direction = Vector2(clamp(direction.x, 0.0, 1.0), clamp(direction.y, 0.0, 1.0))
	if shader_material != null:
		shader_material.set_shader_parameter("light_direction", light_direction)


func set_refresh_mode(mode: RefreshMode) -> void:
	"""Set refresh mode for adaptive throttling.
	
	Args:
		mode: RefreshMode enum value (INTERACTIVE, GENERATION, REGENERATION)
	"""
	current_refresh_mode = mode
	MythosLogger.debug("World/Rendering", "Refresh mode set", {"mode": _refresh_mode_to_string(mode)})


func _refresh_mode_to_string(mode: RefreshMode) -> String:
	"""Convert RefreshMode enum to string."""
	match mode:
		RefreshMode.INTERACTIVE:
			return "INTERACTIVE"
		RefreshMode.GENERATION:
			return "GENERATION"
		RefreshMode.REGENERATION:
			return "REGENERATION"
		_:
			return "UNKNOWN"


func refresh(batched_changes: Dictionary = {}) -> void:
	"""Refresh rendering (call after map data changes).
	
	Args:
		batched_changes: Optional dictionary of batched changes for bulk updates (future optimization)
	"""
	var now: int = Time.get_ticks_msec()
	
	# Get mode-specific minimum interval
	var min_interval: int = MIN_REFRESH_MS.get(current_refresh_mode, MIN_REFRESH_MS[RefreshMode.INTERACTIVE])
	
	# Throttle refreshes - skip if called too frequently (prevents blocking)
	if now - last_refresh_time < min_interval:
		pending_refresh = true
		# Schedule deferred refresh if not already scheduled
		if not has_node("RefreshThrottleTimer"):
			var timer: Timer = Timer.new()
			timer.name = "RefreshThrottleTimer"
			timer.wait_time = (min_interval - (now - last_refresh_time)) / 1000.0
			timer.one_shot = true
			timer.timeout.connect(_do_pending_refresh)
			add_child(timer)
			timer.start()
		return
	
	last_refresh_time = now
	pending_refresh = false
	_do_actual_refresh()


func _do_pending_refresh() -> void:
	"""Handle pending refresh after throttle interval."""
	if pending_refresh:
		pending_refresh = false
		last_refresh_time = Time.get_ticks_msec()
		_do_actual_refresh()


func _do_actual_refresh() -> void:
	"""Actually perform the refresh operation.
	
	Deferred to avoid blocking main thread with expensive texture uploads.
	"""
	# Defer expensive texture operations to avoid blocking main thread
	# This prevents 100ms+ stalls that cause low FPS
	call_deferred("_do_actual_refresh_deferred")


func _do_actual_refresh_deferred() -> void:
	"""Actually perform the refresh operation (deferred to avoid blocking)."""
	# PROFILING: Time refresh operation
	var refresh_start: int = Time.get_ticks_usec()
	profiling_refresh_calls += 1
	
	MythosLogger.verbose("World/Rendering", "refresh() called (deferred)")
	_update_textures()
	
	if render_target != null:
		var target_type: String = render_target.get_class()
		MythosLogger.debug("World/Rendering", "Render target exists", {
			"type": target_type,
			"visible": render_target.visible if render_target.has_method("is_visible_in_tree") else "N/A"
		})
		# Update texture if using Sprite2D
		if render_target is Sprite2D:
			var sprite: Sprite2D = render_target as Sprite2D
			MythosLogger.verbose("World/Rendering", "Updating Sprite2D texture", {"has_material": sprite.material != null})
			# Sprite2D uses the material for shader, but we still need a base texture
			# The shader will use the textures we set in the material
			if biome_texture != null:
				sprite.texture = biome_texture
				MythosLogger.debug("World/Rendering", "Set sprite texture to biome_texture", {"size": biome_texture.get_size()})
			elif heightmap_texture != null:
				sprite.texture = heightmap_texture
				MythosLogger.debug("World/Rendering", "Set sprite texture to heightmap_texture", {"size": heightmap_texture.get_size()})
			MythosLogger.verbose("World/Rendering", "Sprite2D updated", {
				"position": sprite.position,
				"scale": sprite.scale
			})
		elif render_target is TextureRect:
			# Force texture update
			var tex: TextureRect = render_target as TextureRect
			if heightmap_texture != null:
				tex.texture = heightmap_texture
				MythosLogger.debug("World/Rendering", "TextureRect texture updated")
	else:
		MythosLogger.error("World/Rendering", "render_target is null!")
	
	# PROFILING: Report refresh time if >1ms
	var refresh_time: int = Time.get_ticks_usec() - refresh_start
	var refresh_time_ms: float = refresh_time / 1000.0
	profiling_refresh_times.append(refresh_time_ms)
	if profiling_refresh_times.size() > 1000:  # Keep last 1000 samples
		profiling_refresh_times.pop_front()
	
	# Send timing to Performance Monitor overlay
	if PerformanceMonitorSingleton.monitor_instance:
		PerformanceMonitorSingleton.set_refresh_time(refresh_time_ms)
	
	if refresh_time > 1000:  # >1ms
		profiling_refresh_over_1ms += 1
		print("PROFILING: MapRenderer._do_actual_refresh() took: ", refresh_time_ms, " ms")
	if refresh_time > 10000:  # >10ms
		profiling_refresh_over_10ms += 1


func get_profiling_summary() -> Dictionary:
	"""Get profiling data summary."""
	var avg_time: float = 0.0
	var max_time: float = 0.0
	if profiling_refresh_times.size() > 0:
		var sum: float = 0.0
		for time in profiling_refresh_times:
			sum += time
			if time > max_time:
				max_time = time
		avg_time = sum / profiling_refresh_times.size()
	
	return {
		"refresh_calls": profiling_refresh_calls,
		"refresh_over_1ms": profiling_refresh_over_1ms,
		"refresh_over_10ms": profiling_refresh_over_10ms,
		"avg_time_ms": avg_time,
		"max_time_ms": max_time,
		"time_samples_count": profiling_refresh_times.size()
	}