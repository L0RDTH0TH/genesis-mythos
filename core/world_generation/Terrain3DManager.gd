# ╔═══════════════════════════════════════════════════════════
# ║ Terrain3DManager.gd
# ║ Desc: Manages Terrain3D lifecycle and runtime modifications
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name Terrain3DManager
extends RefCounted

## Signal emitted when terrain generation completes
signal terrain_generated(terrain)

## Signal emitted when terrain parameters change
signal terrain_updated()

## Reference to the active terrain node
var terrain = null

## Current generation parameters
var generation_params: Dictionary = {}


## Initialize terrain with basic configuration
func initialize_terrain(parent: Node, data_directory: String = "user://terrain3d/"):
	# Terrain3D is from GDExtension addon - use call() to avoid parse-time errors
	# Check if Terrain3D class is available
	if not ClassDB.class_exists("Terrain3D"):
		push_error("Terrain3DManager: Terrain3D class not found - ensure addon is loaded")
		return null
	
	# Use ClassDB to instantiate (works for GDExtension classes)
	var new_terrain = ClassDB.instantiate("Terrain3D")
	if new_terrain == null:
		push_error("Terrain3DManager: Failed to instantiate Terrain3D - addon may not be loaded")
		return null
	new_terrain.name = "Terrain3D"
	new_terrain.data_directory = data_directory
	new_terrain.region_size = 1024
	new_terrain.mesh_size = 64
	new_terrain.vertex_spacing = 1.0
	
	# Ensure terrain has a visible material
	if new_terrain.material == null:
		var default_material: StandardMaterial3D = StandardMaterial3D.new()
		default_material.albedo_color = Color(0.4, 0.5, 0.3, 1.0)  # Greenish terrain color
		default_material.roughness = 0.8
		default_material.metallic = 0.0
		new_terrain.material = default_material
		print("Terrain3DManager: Applied default StandardMaterial3D for visibility")
	
	parent.add_child(new_terrain, true)
	terrain = new_terrain
	
	return terrain


## Generate terrain from noise parameters
func generate_from_noise(
	noise_seed: int = 0,
	frequency: float = 0.0005,
	min_height: float = 0.0,
	max_height: float = 150.0,
	image_size: int = 2048
) -> void:
	if terrain == null:
		push_error("Terrain3DManager: No terrain initialized")
		return
	
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = frequency
	
	var height_image: Image = Image.create_empty(image_size, image_size, false, Image.FORMAT_RF)
	
	for x in height_image.get_width():
		for y in height_image.get_height():
			var noise_value: float = noise.get_noise_2d(x, y)
			# Normalize to 0-1 range
			var normalized: float = (noise_value + 1.0) / 2.0
			height_image.set_pixel(x, y, Color(normalized, 0.0, 0.0, 1.0))
	
	# Import heightmap
	var origin: Vector3 = Vector3(-terrain.region_size / 2.0, 0.0, -terrain.region_size / 2.0)
	terrain.data.import_images([height_image, null, null], origin, min_height, max_height)
	
	generation_params = {
		"noise_seed": noise_seed,
		"frequency": frequency,
		"min_height": min_height,
		"max_height": max_height
	}
	
	terrain_generated.emit(terrain)
	terrain_updated.emit()


## Modify height scale of existing terrain
func scale_heights(scale_factor: float) -> void:
	if terrain == null:
		push_error("Terrain3DManager: No terrain initialized")
		return
	
	var terrain_data = terrain.data
	var region_location: Vector2i = Vector2i(0, 0)
	var region = terrain_data.get_region(region_location)
	
	if region == null:
		push_warning("Terrain3DManager: Region not found at " + str(region_location))
		return
	
	var height_map: Image = region.get_height_map()
	
	for x in height_map.get_width():
		for y in height_map.get_height():
			var current_height: Color = height_map.get_pixel(x, y)
			var new_height: float = clamp(current_height.r * scale_factor, 0.0, 1.0)
			height_map.set_pixel(x, y, Color(new_height, 0.0, 0.0, 1.0))
	
	region.set_height_map(height_map)
	region.update_height()
	terrain.update_maps()
	
	terrain_updated.emit()


## Get height at world position
func get_height_at(position: Vector3) -> float:
	if terrain == null:
		return 0.0
	
	return terrain.get_height(position)


## Get surface normal at world position
func get_normal_at(position: Vector3) -> Vector3:
	if terrain == null:
		return Vector3.UP
	
	return terrain.get_normal(position)


## Update material shader parameter
func set_material_param(param_name: String, value: Variant) -> void:
	if terrain == null:
		push_error("Terrain3DManager: No terrain initialized")
		return
	
	terrain.material.set_shader_param(param_name, value)


## Enable dynamic collision
func enable_dynamic_collision(enabled: bool = true) -> void:
	if terrain == null:
		push_error("Terrain3DManager: No terrain initialized")
		return
	
	if enabled:
		terrain.collision.mode = 1  # Terrain3DCollision.DYNAMIC_RUNTIME
	else:
		terrain.collision.mode = 0  # Terrain3DCollision.STATIC


## Apply biome map to terrain (stub for future implementation)
func apply_biome_map(biome_type: String, blending: float, color: Color) -> void:
	if terrain == null:
		push_error("Terrain3DManager: No terrain initialized")
		return
	
	# TODO: Implement biome map application using Terrain3D control maps
	push_warning("Terrain3DManager: Biome map application not yet implemented")
	terrain_updated.emit()


## Place structure on terrain (stub for future implementation)
func place_structure(structure_type: String, position: Vector3, scale: float = 1.0) -> void:
	if terrain == null:
		push_error("Terrain3DManager: No terrain initialized")
		return
	
	# TODO: Implement structure placement using Terrain3D instancer or manual node placement
	push_warning("Terrain3DManager: Structure placement not yet implemented")


## Remove all structures (stub for future implementation)
func remove_all_structures() -> void:
	if terrain == null:
		push_error("Terrain3DManager: No terrain initialized")
		return
	
	# TODO: Implement structure removal
	push_warning("Terrain3DManager: Structure removal not yet implemented")


## Update environment settings (stub for future implementation)
func update_environment(time_of_day: float, fog_density: float, wind_strength: float, weather: String, sky_color: Color, ambient_light: Color) -> void:
	if terrain == null:
		push_error("Terrain3DManager: No terrain initialized")
		return
	
	# TODO: Implement environment updates via WorldEnvironment node
	push_warning("Terrain3DManager: Environment updates not yet implemented")


## Export heightmap as PNG
func export_heightmap(path: String) -> bool:
	if terrain == null:
		push_error("Terrain3DManager: No terrain initialized")
		return false
	
	var terrain_data = terrain.data
	var region_location: Vector2i = Vector2i(0, 0)
	var region = terrain_data.get_region(region_location)
	
	if region == null:
		push_warning("Terrain3DManager: Region not found at " + str(region_location))
		return false
	
	var height_map: Image = region.get_height_map()
	if height_map == null:
		push_error("Terrain3DManager: Failed to get height map")
		return false
	
	# Convert to RGB format for PNG export
	var export_image: Image = Image.create(height_map.get_width(), height_map.get_height(), false, Image.FORMAT_RGB8)
	for x in height_map.get_width():
		for y in height_map.get_height():
			var height_value: float = height_map.get_pixel(x, y).r
			export_image.set_pixel(x, y, Color(height_value, height_value, height_value, 1.0))
	
	var error: Error = export_image.save_png(path)
	if error != OK:
		push_error("Terrain3DManager: Failed to save heightmap to " + path)
		return false
	
	print("Terrain3DManager: Exported heightmap to " + path)
	return true


## Cleanup terrain
func cleanup() -> void:
	if terrain != null and is_instance_valid(terrain):
		terrain.queue_free()
		terrain = null
