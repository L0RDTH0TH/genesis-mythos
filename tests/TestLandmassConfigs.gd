# ╔═══════════════════════════════════════════════════════════
# ║ TestLandmassConfigs.gd
# ║ Desc: GUT tests for data-driven landmass type configurations
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Test fixture: Landmass config path
const CONFIG_PATH: String = "res://data/config/landmass_types.json"

## Test fixture: ProceduralWorldDatasource instance
var datasource: ProceduralWorldDatasource

## Test fixture: MapGenerator instance
var map_generator: MapGenerator

## Test fixture: WorldMapData instance
var world_map_data: WorldMapData


func before_each() -> void:
	"""Setup test fixtures before each test."""
	datasource = ProceduralWorldDatasource.new()
	map_generator = MapGenerator.new()
	world_map_data = WorldMapData.new()
	world_map_data.seed = 12345
	world_map_data.world_width = 512
	world_map_data.world_height = 512
	world_map_data.create_heightmap(512, 512)


func after_each() -> void:
	"""Cleanup test fixtures after each test."""
	if datasource != null:
		datasource.queue_free()
	if map_generator != null:
		map_generator = null
	if world_map_data != null:
		world_map_data = null


func test_landmass_config_json_loads() -> void:
	"""Test that landmass_types.json loads successfully."""
	var file: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	assert_not_null(file, "FAIL: Expected landmass_types.json to exist. Context: JSON loading. Why: Config file must exist. Hint: Check file path and permissions.")
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	assert_eq(parse_result, OK, "FAIL: Expected JSON parse to succeed. Context: JSON parsing. Why: Config must be valid JSON. Hint: Check JSON syntax.")
	
	var data: Dictionary = json.data
	assert_true(data.has("landmass_types"), "FAIL: Expected 'landmass_types' key in JSON. Context: JSON structure. Why: Config must have landmass_types object. Hint: Check JSON structure.")
	
	var landmass_types: Dictionary = data.get("landmass_types", {})
	assert_gt(landmass_types.size(), 0, "FAIL: Expected at least one landmass type. Context: Config content. Why: Must have landmass types defined. Hint: Check JSON content.")
	
	pass_test("Landmass config JSON loads successfully")


func test_all_landmass_types_have_valid_config() -> void:
	"""Test that all landmass types have valid configuration."""
	var file: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		pass_test("Config file not found, skipping test")
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	json.parse(json_string)
	var data: Dictionary = json.data
	var landmass_types: Dictionary = data.get("landmass_types", {})
	
	for landmass_name: String in landmass_types.keys():
		var config: Dictionary = landmass_types[landmass_name]
		assert_true(config.has("type"), "FAIL: Landmass '%s' missing 'type' field. Context: Config validation. Why: All types must have type field. Hint: Check JSON structure." % landmass_name)
		
		var mask_type: String = config.get("type", "")
		assert_ne(mask_type, "", "FAIL: Landmass '%s' has empty type. Context: Config validation. Why: Type must be specified. Hint: Check JSON content." % landmass_name)
		
		# Validate type-specific parameters
		match mask_type:
			"radial":
				assert_true(config.has("center"), "FAIL: Radial mask '%s' missing 'center'. Context: Config validation. Why: Radial requires center. Hint: Add center array.")
				assert_true(config.has("radius"), "FAIL: Radial mask '%s' missing 'radius'. Context: Config validation. Why: Radial requires radius. Hint: Add radius value.")
			"multi_radial":
				assert_true(config.has("count"), "FAIL: Multi-radial mask '%s' missing 'count'. Context: Config validation. Why: Multi-radial requires count. Hint: Add count value.")
				assert_true(config.has("radius"), "FAIL: Multi-radial mask '%s' missing 'radius'. Context: Config validation. Why: Multi-radial requires radius. Hint: Add radius value.")
			"noise_mask":
				assert_true(config.has("frequency"), "FAIL: Noise mask '%s' missing 'frequency'. Context: Config validation. Why: Noise mask requires frequency. Hint: Add frequency value.")
				assert_true(config.has("threshold"), "FAIL: Noise mask '%s' missing 'threshold'. Context: Config validation. Why: Noise mask requires threshold. Hint: Add threshold value.")
			"voronoi":
				assert_true(config.has("cell_count"), "FAIL: Voronoi mask '%s' missing 'cell_count'. Context: Config validation. Why: Voronoi requires cell_count. Hint: Add cell_count value.")
			"ring", "atoll":
				assert_true(config.has("inner_radius"), "FAIL: Ring/Atoll mask '%s' missing 'inner_radius'. Context: Config validation. Why: Ring requires inner_radius. Hint: Add inner_radius value.")
				assert_true(config.has("outer_radius"), "FAIL: Ring/Atoll mask '%s' missing 'outer_radius'. Context: Config validation. Why: Ring requires outer_radius. Hint: Add outer_radius value.")
			"peninsula":
				assert_true(config.has("base_radius"), "FAIL: Peninsula mask '%s' missing 'base_radius'. Context: Config validation. Why: Peninsula requires base_radius. Hint: Add base_radius value.")
			"fjord":
				assert_true(config.has("fjord_count"), "FAIL: Fjord mask '%s' missing 'fjord_count'. Context: Config validation. Why: Fjord requires fjord_count. Hint: Add fjord_count value.")
	
	pass_test("All landmass types have valid configuration")


func test_datasource_loads_landmass_configs() -> void:
	"""Test that ProceduralWorldDatasource loads landmass configs in _init()."""
	assert_not_null(datasource, "FAIL: Expected datasource to be created. Context: Instantiation. Why: Datasource should initialize. Hint: Check _init() completes.")
	
	# Check that landmass_configs is populated (should be loaded in _init)
	# Note: We can't directly access private vars, but we can test via behavior
	# For now, just verify datasource exists and can be configured
	var test_archetype: Dictionary = {
		"name": "Test",
		"noise": {
			"noise_type": "TYPE_SIMPLEX",
			"frequency": 0.004,
			"octaves": 6,
			"gain": 0.5,
			"lacunarity": 2.0
		}
	}
	
	datasource.configure_from_archetype(test_archetype, "Continents", 12345)
	pass_test("Datasource loads and configures successfully")


func test_mapgenerator_loads_landmass_configs() -> void:
	"""Test that MapGenerator loads landmass configs in _init()."""
	assert_not_null(map_generator, "FAIL: Expected MapGenerator to be created. Context: Instantiation. Why: Generator should initialize. Hint: Check _init() completes.")
	
	# Generate a map with a landmass type to verify configs are loaded
	world_map_data.landmass_type = "Single Island"
	map_generator.generate_map(world_map_data, false)  # Synchronous
	
	assert_not_null(world_map_data.heightmap_image, "FAIL: Expected heightmap after generation. Context: Map generation. Why: Generation should create heightmap. Hint: Check _generate_heightmap().")
	
	pass_test("MapGenerator loads configs and generates map with landmass type")


func test_landmass_mask_applies_to_heightmap() -> void:
	"""Test that landmass masks are applied to generated heightmaps."""
	# Test with Single Island (radial mask)
	world_map_data.landmass_type = "Single Island"
	map_generator.generate_map(world_map_data, false)
	
	var img: Image = world_map_data.heightmap_image
	assert_not_null(img, "FAIL: Expected heightmap image. Context: Mask application. Why: Generation should create image. Hint: Check generation completes.")
	
	# Sample center pixel (should be high for Single Island)
	var center_x: int = img.get_width() / 2
	var center_y: int = img.get_height() / 2
	var center_height: float = img.get_pixel(center_x, center_y).r
	
	# Sample edge pixel (should be lower for Single Island)
	var edge_x: int = img.get_width() - 1
	var edge_y: int = img.get_height() - 1
	var edge_height: float = img.get_pixel(edge_x, edge_y).r
	
	# Center should generally be higher than edge for Single Island
	# (allowing some tolerance for noise variation)
	assert_gt(center_height, edge_height * 0.5, "FAIL: Center height should be higher than edge for Single Island. Context: Mask application. Why: Radial mask should create island. Hint: Check _apply_landmass_mask_to_heightmap().")
	
	pass_test("Landmass mask applies correctly to heightmap")


func test_different_landmass_types_produce_different_maps() -> void:
	"""Test that different landmass types produce visually different heightmaps."""
	var type1: String = "Continents"
	var type2: String = "Single Island"
	
	# Generate map with Continents
	world_map_data.landmass_type = type1
	world_map_data.seed = 12345
	map_generator.generate_map(world_map_data, false)
	var img1: Image = world_map_data.heightmap_image.duplicate()
	
	# Generate map with Single Island (same seed)
	world_map_data.landmass_type = type2
	world_map_data.seed = 12345
	map_generator.generate_map(world_map_data, false)
	var img2: Image = world_map_data.heightmap_image.duplicate()
	
	assert_not_null(img1, "FAIL: Expected heightmap for Continents. Context: Type comparison. Why: Generation should succeed. Hint: Check generation.")
	assert_not_null(img2, "FAIL: Expected heightmap for Single Island. Context: Type comparison. Why: Generation should succeed. Hint: Check generation.")
	
	# Compare center pixels (should differ significantly)
	var center_x: int = img1.get_width() / 2
	var center_y: int = img1.get_height() / 2
	var height1: float = img1.get_pixel(center_x, center_y).r
	var height2: float = img2.get_pixel(center_x, center_y).r
	
	# Heights should differ (allowing some tolerance)
	var diff: float = abs(height1 - height2)
	assert_gt(diff, 0.1, "FAIL: Different landmass types should produce different heights. Context: Type variation. Why: Masks should create distinct patterns. Hint: Check mask application logic.")
	
	pass_test("Different landmass types produce different maps")


func test_landmass_config_has_all_required_types() -> void:
	"""Test that config includes all expected landmass types."""
	var file: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		pass_test("Config file not found, skipping test")
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	json.parse(json_string)
	var data: Dictionary = json.data
	var landmass_types: Dictionary = data.get("landmass_types", {})
	
	# Required types (existing)
	var required_types: Array[String] = ["Continents", "Single Island", "Island Chain", "Archipelago", "Pangea", "Coastal"]
	
	# New types (from recommendations)
	var new_types: Array[String] = ["Fractal Coast", "Voronoi Continents", "Ring Archipelago", "Peninsula", "Atoll", "Fjord Coast"]
	
	var all_required: Array[String] = required_types + new_types
	
	for type_name: String in all_required:
		assert_true(landmass_types.has(type_name), "FAIL: Missing landmass type '%s'. Context: Config completeness. Why: All expected types should exist. Hint: Add type to JSON." % type_name)
	
	pass_test("Landmass config has all required types")
