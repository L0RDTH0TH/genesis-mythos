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
	# Create shader material
	var shader: Shader = load("res://shaders/map_renderer.gdshader")
	if shader != null:
		shader_material = ShaderMaterial.new()
		shader_material.shader = shader
	else:
		push_error("MapRenderer: Failed to load map_renderer shader")


func setup_render_target(target: Node) -> void:
	"""Setup rendering target (TextureRect, ColorRect, or Sprite2D)."""
	render_target = target
	
	if render_target != null and shader_material != null:
		if render_target is TextureRect:
			(render_target as TextureRect).material = shader_material
		elif render_target is ColorRect:
			(render_target as ColorRect).material = shader_material
		elif render_target is Sprite2D:
			(render_target as Sprite2D).material = shader_material
		elif render_target.has_method("set_material"):
			render_target.set("material", shader_material)


func set_world_map_data(data: WorldMapData) -> void:
	"""Set world map data and update textures."""
	world_map_data = data
	_update_textures()


func _update_textures() -> void:
	"""Update shader textures from world_map_data."""
	if world_map_data == null or world_map_data.heightmap_image == null:
		return
	
	# Update heightmap texture
	if heightmap_texture == null:
		heightmap_texture = ImageTexture.new()
	
	heightmap_texture.set_image(world_map_data.heightmap_image)
	
	# Update biome texture
	if world_map_data.biome_preview_image != null:
		if biome_texture == null:
			biome_texture = ImageTexture.new()
		biome_texture.set_image(world_map_data.biome_preview_image)
	else:
		# Generate biome preview if not exists
		var generator: MapGenerator = MapGenerator.new()
		var biome_img: Image = generator.generate_biome_preview(world_map_data)
		if biome_img != null:
			if biome_texture == null:
				biome_texture = ImageTexture.new()
			biome_texture.set_image(biome_img)
	
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
	
	# Apply textures to shader
	if shader_material != null:
		shader_material.set_shader_parameter("heightmap_texture", heightmap_texture)
		shader_material.set_shader_parameter("biome_texture", biome_texture != null ? biome_texture : heightmap_texture)
		shader_material.set_shader_parameter("rivers_texture", rivers_texture)
		shader_material.set_shader_parameter("sea_level", world_map_data.sea_level)
		shader_material.set_shader_parameter("light_direction", light_direction)


func set_view_mode(mode: ViewMode) -> void:
	"""Change view mode (heightmap, biomes, political)."""
	current_view_mode = mode
	
	if shader_material != null:
		match mode:
			ViewMode.HEIGHTMAP:
				shader_material.set_shader_parameter("show_heightmap", true)
				shader_material.set_shader_parameter("show_biomes", false)
			ViewMode.BIOMES:
				shader_material.set_shader_parameter("show_heightmap", false)
				shader_material.set_shader_parameter("show_biomes", true)
			ViewMode.POLITICAL:
				shader_material.set_shader_parameter("show_heightmap", false)
				shader_material.set_shader_parameter("show_biomes", true)  # Placeholder


func set_rivers_visible(visible: bool) -> void:
	"""Toggle river overlay visibility."""
	if shader_material != null:
		shader_material.set_shader_parameter("show_rivers", visible)


func set_light_direction(direction: Vector2) -> void:
	"""Set light direction for hillshading (normalized 0-1)."""
	light_direction = direction.clamped(Vector2(0.0, 0.0), Vector2(1.0, 1.0))
	if shader_material != null:
		shader_material.set_shader_parameter("light_direction", light_direction)


func refresh() -> void:
	"""Refresh rendering (call after map data changes)."""
	_update_textures()
	
	if render_target != null:
		# Update texture if using Sprite2D
		if render_target is Sprite2D:
			var sprite: Sprite2D = render_target as Sprite2D
			# Sprite2D uses the material for shader, but we still need a base texture
			# The shader will use the textures we set in the material
			if biome_texture != null:
				sprite.texture = biome_texture
			elif heightmap_texture != null:
				sprite.texture = heightmap_texture
		elif render_target is TextureRect:
			# Force texture update
			var tex: TextureRect = render_target as TextureRect
			if heightmap_texture != null:
				tex.texture = heightmap_texture