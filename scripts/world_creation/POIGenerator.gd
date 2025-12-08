# ╔═══════════════════════════════════════════════════════════
# ║ POIGenerator.gd
# ║ Desc: Point-of-Interest placement (cities, towns, ruins, resources)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
class_name POIGenerator
extends RefCounted

## Generate POIs for world.
##
## Args:
## 	world_data: WorldData resource with biome_metadata, generated_mesh, and params
##
## Stores result in world_data.poi_metadata (Array[Dictionary])
static func generate_pois(world_data) -> void:
	if not world_data:
		return
	
	# Get parameters
	var poi_density: float = world_data.params.get("poi_density", 0.3)  # 0.0-1.0
	var min_distance: int = world_data.params.get("min_poi_distance", 80)
	var enable_cities: bool = world_data.params.get("enable_cities", true)
	var enable_towns: bool = world_data.params.get("enable_towns", true)
	var enable_ruins: bool = world_data.params.get("enable_ruins", true)
	var enable_resources: bool = world_data.params.get("enable_resources", true)
	
	if poi_density <= 0.0:
		return  # No POIs if density is 0
	
	# Get world size from biome metadata
	if world_data.biome_metadata.is_empty():
		return
	
	# Estimate grid size from metadata
	var max_x: int = 0
	var max_y: int = 0
	for biome_data in world_data.biome_metadata:
		max_x = max(max_x, biome_data.get("x", 0))
		max_y = max(max_y, biome_data.get("y", 0))
	
	var grid_size: Vector2i = Vector2i(max_x + 1, max_y + 1)
	
	# Get mesh for 3D positions
	var mesh: Mesh = world_data.generated_mesh
	if not mesh or mesh.get_surface_count() == 0:
		return
	
	var arrays: Array = mesh.surface_get_arrays(0)
	if arrays.size() <= Mesh.ARRAY_VERTEX:
		return
	
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if vertices.is_empty():
		return
	
	# Create RNG for deterministic placement
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = world_data.seed + 4000
	
	# Track placed POIs for distance checking
	var placed_pois: Array = []  # Array of Vector2i positions
	var poi_array: Array = []  # Array to collect all POIs
	
	# Generate cities (if enabled)
	if enable_cities:
		var city_count: int = int(grid_size.x * grid_size.y * poi_density * 0.05)  # ~5% of density
		city_count = max(1, city_count)  # At least 1
		_generate_pois_of_type(world_data, "city", city_count, grid_size, vertices, placed_pois, min_distance, rng, poi_array)
	
	# Generate towns (if enabled)
	if enable_towns:
		var town_count: int = int(grid_size.x * grid_size.y * poi_density * 0.15)  # ~15% of density
		town_count = max(2, town_count)  # At least 2
		_generate_pois_of_type(world_data, "town", town_count, grid_size, vertices, placed_pois, min_distance, rng, poi_array)
	
	# Generate ruins (if enabled)
	if enable_ruins:
		var ruin_count: int = int(grid_size.x * grid_size.y * poi_density * 0.1)  # ~10% of density
		ruin_count = max(1, ruin_count)  # At least 1
		_generate_pois_of_type(world_data, "ruin", ruin_count, grid_size, vertices, placed_pois, min_distance, rng, poi_array)
	
	# Generate resource nodes (if enabled)
	if enable_resources:
		var resource_count: int = int(grid_size.x * grid_size.y * poi_density * 0.2)  # ~20% of density
		resource_count = max(3, resource_count)  # At least 3
		_generate_pois_of_type(world_data, "resource", resource_count, grid_size, vertices, placed_pois, min_distance, rng, poi_array)
	
	# Assign POI array to world_data (direct assignment)
	world_data.poi_metadata = poi_array
	print("POIGenerator: Generated ", poi_array.size(), " POIs")

## Generate POIs of a specific type.
static func _generate_pois_of_type(world_data, poi_type: String, count: int, grid_size: Vector2i, vertices: PackedVector3Array, placed_pois: Array, min_distance: int, rng: RandomNumberGenerator, poi_array: Array) -> void:
	var attempts: int = 0
	var max_attempts: int = count * 50  # Try many times before giving up
	
	for i in range(count):
		var placed: bool = false
		var attempt: int = 0
		
		while not placed and attempt < max_attempts:
			attempt += 1
			attempts += 1
			
			# Random position
			var x: int = rng.randi_range(0, grid_size.x - 1)
			var y: int = rng.randi_range(0, grid_size.y - 1)
			var pos: Vector2i = Vector2i(x, y)
			
			# Check minimum distance
			var too_close: bool = false
			for placed_pos in placed_pois:
				if pos.distance_to(placed_pos) < min_distance:
					too_close = true
					break
			
			if too_close:
				continue
			
			# Check biome suitability
			var biome_data: Dictionary = _get_biome_at(world_data, x, y)
			if not biome_data.is_empty():
				if _is_suitable_biome(poi_type, biome_data):
					# Place POI
					var poi: Dictionary = _create_poi(poi_type, x, y, biome_data, vertices, grid_size)
					poi_array.append(poi)
					placed_pois.append(pos)
					placed = true

## Get biome data at grid coordinates.
static func _get_biome_at(world_data, x: int, y: int) -> Dictionary:
	for biome_data in world_data.biome_metadata:
		if biome_data.get("x", -1) == x and biome_data.get("y", -1) == y:
			return biome_data
	return {}

## Check if biome is suitable for POI type.
static func _is_suitable_biome(poi_type: String, biome_data: Dictionary) -> bool:
	var biome: String = biome_data.get("biome", "plains")
	
	match poi_type:
		"city", "town":
			# Prefer plains, grassland, coast (avoid extreme biomes)
			return biome in ["plains", "grassland", "coast", "forest"]
		"ruin":
			# Can be anywhere, but prefer mountains, forests, deserts
			return biome in ["mountain", "forest", "desert", "jungle", "tundra"]
		"resource":
			# Biome-specific resources
			return true  # Resources can be anywhere
		_:
			return true

## Create POI dictionary.
static func _create_poi(poi_type: String, x: int, y: int, biome_data: Dictionary, vertices: PackedVector3Array, grid_size: Vector2i) -> Dictionary:
	# Get 3D position from mesh vertices
	var position: Vector3 = Vector3.ZERO
	var vertex_idx: int = y * grid_size.x + x
	if vertex_idx >= 0 and vertex_idx < vertices.size():
		position = vertices[vertex_idx]
	
	# Generate name based on type and biome
	var name: String = _generate_poi_name(poi_type, biome_data)
	
	var poi: Dictionary = {
		"type": poi_type,
		"position": position,
		"biome": biome_data.get("biome", "plains"),
		"name": name,
		"x": x,
		"y": y
	}
	
	# Add type-specific metadata
	match poi_type:
		"city":
			poi["population"] = randi_range(5000, 50000)
		"town":
			poi["population"] = randi_range(500, 5000)
		"ruin":
			poi["age"] = randi_range(100, 2000)  # Years old
		"resource":
			poi["resource_type"] = _get_resource_type(biome_data)
	
	return poi

## Generate POI name based on type and biome.
static func _generate_poi_name(poi_type: String, biome_data: Dictionary) -> String:
	var biome: String = biome_data.get("biome", "plains")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	var prefixes: Array = []
	var suffixes: Array = []
	
	match poi_type:
		"city":
			prefixes = ["Grand", "Royal", "Capital", "Great", "Fort"]
			suffixes = ["burg", "port", "haven", "gate", "keep", "hall"]
		"town":
			prefixes = ["New", "Old", "West", "East", "North", "South", "Little"]
			suffixes = ["ville", "ton", "ford", "bridge", "mill", "field"]
		"ruin":
			prefixes = ["Ancient", "Lost", "Forgotten", "Abandoned", "Old"]
			suffixes = ["Ruins", "Tower", "Temple", "Fortress", "Keep", "Sanctuary"]
		"resource":
			prefixes = ["Iron", "Gold", "Copper", "Crystal", "Magic"]
			suffixes = ["Mine", "Quarry", "Deposit", "Vein", "Source"]
	
	var prefix: String = prefixes[rng.randi() % prefixes.size()] if prefixes.size() > 0 else ""
	var suffix: String = suffixes[rng.randi() % suffixes.size()] if suffixes.size() > 0 else ""
	
	if prefix != "" and suffix != "":
		return prefix + " " + suffix
	elif prefix != "":
		return prefix
	elif suffix != "":
		return suffix
	else:
		return poi_type.capitalize()

## Get resource type based on biome.
static func _get_resource_type(biome_data: Dictionary) -> String:
	var biome: String = biome_data.get("biome", "plains")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	match biome:
		"mountain":
			return ["iron", "gold", "silver", "crystal"][rng.randi() % 4]
		"forest":
			return ["wood", "herbs", "game"][rng.randi() % 3]
		"desert", "cold_desert":
			return ["salt", "gem", "oil"][rng.randi() % 3]
		"swamp":
			return ["peat", "herbs", "rare_plants"][rng.randi() % 3]
		"coast":
			return ["fish", "pearls", "salt"][rng.randi() % 3]
		_:
			return ["stone", "clay", "herbs"][rng.randi() % 3]
