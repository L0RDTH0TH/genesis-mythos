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


func _init() -> void:
	"""Initialize MapRenderer."""
	Logger.verbose("World/Rendering", "MapRenderer._init() called")
	# Create shader material
	var shader: Shader = load("res://shaders/map_renderer.gdshader")
	Logger.debug("World/Rendering", "Shader loaded", {"loaded": shader != null})
	if shader != null:
		shader_material = ShaderMaterial.new()
		shader_material.shader = shader
		Logger.info("World/Rendering", "Shader material created and assigned")
	else:
		Logger.error("World/Rendering", "Failed to load map_renderer shader from res://shaders/map_renderer.gdshader")


func setup_render_target(target: Node) -> void:
	"""Setup rendering target (TextureRect, ColorRect, or Sprite2D)."""
	Logger.verbose("World/Rendering", "setup_render_target() called", {"target_type": target.get_class() if target else "null"})
	render_target = target
	
	if render_target != null and shader_material != null:
		if render_target is TextureRect:
			(render_target as TextureRect).material = shader_material
			Logger.debug("World/Rendering", "Shader material applied to TextureRect")
		elif render_target is ColorRect:
			(render_target as ColorRect).material = shader_material
			Logger.debug("World/Rendering", "Shader material applied to ColorRect")
		elif render_target is Sprite2D:
			(render_target as Sprite2D).material = shader_material
			Logger.debug("World/Rendering", "Shader material applied to Sprite2D")
		elif render_target.has_method("set_material"):
			render_target.set("material", shader_material)
			Logger.debug("World/Rendering", "Shader material applied via set_material()")
	else:
		if render_target == null:
			Logger.warn("World/Rendering", "Cannot setup render target - target is null")
		if shader_material == null:
			Logger.warn("World/Rendering", "Cannot setup render target - shader_material is null")


func set_world_map_data(data: WorldMapData) -> void:
	"""Set world map data and update textures."""
	Logger.verbose("World/Rendering", "set_world_map_data() called")
	world_map_data = data
	_update_textures()


func _update_textures() -> void:
	"""Update shader textures from world_map_data."""
	Logger.verbose("World/Rendering", "_update_textures() called")
	if world_map_data == null:
		Logger.error("World/Rendering", "world_map_data is null")
		return
	if world_map_data.heightmap_image == null:
		Logger.error("World/Rendering", "heightmap_image is null")
		return
	
	var image_size: Vector2i = world_map_data.heightmap_image.get_size()
	Logger.debug("World/Rendering", "Updating textures", {"heightmap_size": image_size})
	
	# Update heightmap texture
	if heightmap_texture == null:
		heightmap_texture = ImageTexture.new()
	
	heightmap_texture.set_image(world_map_data.heightmap_image)
	Logger.debug("World/Rendering", "Heightmap texture created", {"size": heightmap_texture.get_size()})
	
	# Update biome texture
	if world_map_data.biome_preview_image != null:
		if biome_texture == null:
			biome_texture = ImageTexture.new()
		biome_texture.set_image(world_map_data.biome_preview_image)
		Logger.debug("World/Rendering", "Biome texture updated from preview image")
	else:
		# Generate biome preview if not exists
		Logger.verbose("World/Rendering", "Generating biome preview image")
		# Remove type hint to avoid parse-time dependency on MapGenerator
		var generator = MapGenerator.new()
		var biome_img: Image = generator.generate_biome_preview(world_map_data)
		if biome_img != null:
			if biome_texture == null:
				biome_texture = ImageTexture.new()
			biome_texture.set_image(biome_img)
			Logger.debug("World/Rendering", "Biome texture generated", {"size": biome_img.get_size()})
		else:
			Logger.warn("World/Rendering", "Failed to generate biome preview image")
	
	# Create empty rivers texture (for now)
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
		Logger.debug("World/Rendering", "Rivers texture created", {"size": rivers_img.get_size()})
	
	# Apply textures to shader
	if shader_material != null:
		Logger.verbose("World/Rendering", "Applying textures to shader material")
		shader_material.set_shader_parameter("heightmap_texture", heightmap_texture)
		shader_material.set_shader_parameter("biome_texture", biome_texture if biome_texture != null else heightmap_texture)
		shader_material.set_shader_parameter("rivers_texture", rivers_texture)
		shader_material.set_shader_parameter("sea_level", world_map_data.sea_level)
		shader_material.set_shader_parameter("light_direction", light_direction)
		Logger.debug("World/Rendering", "Shader parameters set", {
			"render_target": render_target != null,
			"render_target_type": render_target.get_class() if render_target else "null"
		})
		if render_target != null and render_target is Sprite2D:
			var sprite: Sprite2D = render_target as Sprite2D
			Logger.verbose("World/Rendering", "Sprite2D render target", {
				"has_material": sprite.material != null,
				"has_texture": sprite.texture != null
			})
	else:
		Logger.error("World/Rendering", "shader_material is null!")


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
	Logger.verbose("World/Rendering", "set_view_mode() called", {"mode": mode_name})
	current_view_mode = mode
	
	if shader_material != null:
		match mode:
			ViewMode.HEIGHTMAP:
				shader_material.set_shader_parameter("show_heightmap", true)
				shader_material.set_shader_parameter("show_biomes", false)
				Logger.debug("World/Rendering", "View mode set to HEIGHTMAP")
			ViewMode.BIOMES:
				shader_material.set_shader_parameter("show_heightmap", false)
				shader_material.set_shader_parameter("show_biomes", true)
				Logger.debug("World/Rendering", "View mode set to BIOMES")
			ViewMode.POLITICAL:
				shader_material.set_shader_parameter("show_heightmap", false)
				shader_material.set_shader_parameter("show_biomes", true)  # Placeholder
				Logger.debug("World/Rendering", "View mode set to POLITICAL (placeholder)")
	else:
		Logger.warn("World/Rendering", "Cannot set view mode - shader_material is null")


func set_rivers_visible(visible: bool) -> void:
	"""Toggle river overlay visibility."""
	if shader_material != null:
		shader_material.set_shader_parameter("show_rivers", visible)


func set_light_direction(direction: Vector2) -> void:
	"""Set light direction for hillshading (normalized 0-1)."""
	light_direction = Vector2(clamp(direction.x, 0.0, 1.0), clamp(direction.y, 0.0, 1.0))
	if shader_material != null:
		shader_material.set_shader_parameter("light_direction", light_direction)


func refresh() -> void:
	"""Refresh rendering (call after map data changes)."""
	Logger.verbose("World/Rendering", "refresh() called")
	_update_textures()
	
	if render_target != null:
		var target_type: String = render_target.get_class()
		Logger.debug("World/Rendering", "Render target exists", {
			"type": target_type,
			"visible": render_target.visible if render_target.has_method("is_visible_in_tree") else "N/A"
		})
		# Update texture if using Sprite2D
		if render_target is Sprite2D:
			var sprite: Sprite2D = render_target as Sprite2D
			Logger.verbose("World/Rendering", "Updating Sprite2D texture", {"has_material": sprite.material != null})
			# Sprite2D uses the material for shader, but we still need a base texture
			# The shader will use the textures we set in the material
			if biome_texture != null:
				sprite.texture = biome_texture
				Logger.debug("World/Rendering", "Set sprite texture to biome_texture", {"size": biome_texture.get_size()})
			elif heightmap_texture != null:
				sprite.texture = heightmap_texture
				Logger.debug("World/Rendering", "Set sprite texture to heightmap_texture", {"size": heightmap_texture.get_size()})
			Logger.verbose("World/Rendering", "Sprite2D updated", {
				"position": sprite.position,
				"scale": sprite.scale
			})
		elif render_target is TextureRect:
			# Force texture update
			var tex: TextureRect = render_target as TextureRect
			if heightmap_texture != null:
				tex.texture = heightmap_texture
				Logger.debug("World/Rendering", "TextureRect texture updated")
	else:
		Logger.error("World/Rendering", "render_target is null!")