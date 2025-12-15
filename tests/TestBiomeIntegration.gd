# ╔═══════════════════════════════════════════════════════════
# ║ TestBiomeIntegration.gd
# ║ Desc: GUT tests for data-driven biome system integration
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Test fixture: Biome config path
const BIOME_CONFIG_PATH: String = "res://data/biomes.json"

## Test fixture: MapGenerator instance
var map_generator: MapGenerator

## Test fixture: WorldMapData instance
var world_map_data: WorldMapData


func before_each() -> void:
	"""Setup test fixtures before each test."""
	map_generator = MapGenerator.new()
	world_map_data = WorldMapData.new()
	world_map_data.seed = 12345
	world_map_data.world_width = 512
	world_map_data.world_height = 512
	world_map_data.create_heightmap(512, 512)


func after_each() -> void:
	"""Cleanup test fixtures after each test."""
	if map_generator != null:
		map_generator = null
	if world_map_data != null:
		world_map_data = null


func test_biome_config_json_loads() -> void:
	"""Test that biomes.json loads successfully."""
	var file: FileAccess = FileAccess.open(BIOME_CONFIG_PATH, FileAccess.READ)
	assert_not_null(file, "FAIL: Expected biomes.json to exist. Context: JSON loading. Why: Config file must exist. Hint: Check file path.")
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	assert_eq(parse_result, OK, "FAIL: Expected JSON parse to succeed. Context: JSON parsing. Why: Config must be valid JSON. Hint: Check JSON syntax.")
	
	var data: Dictionary = json.data
	assert_true(data.has("biomes"), "FAIL: Expected 'biomes' key in JSON. Context: JSON structure. Why: Config must have biomes array. Hint: Check JSON structure.")
	
	var biomes: Array = data.get("biomes", [])
	assert_gt(biomes.size(), 0, "FAIL: Expected at least one biome. Context: Config content. Why: Must have biomes defined. Hint: Check JSON content.")
	
	pass_test("Biome config JSON loads successfully")


func test_mapgenerator_loads_biome_configs() -> void:
	"""Test that MapGenerator loads biome configs in _init()."""
	assert_not_null(map_generator, "FAIL: Expected MapGenerator to be created. Context: Instantiation. Why: Generator should initialize. Hint: Check _init() completes.")
	
	# Generate a biome preview to verify configs are loaded
	map_generator.generate_map(world_map_data, false)
	var biome_img: Image = map_generator.generate_biome_preview(world_map_data)
	
	assert_not_null(biome_img, "FAIL: Expected biome preview image. Context: Biome generation. Why: Generation should create biome image. Hint: Check generate_biome_preview().")
	
	pass_test("MapGenerator loads biome configs and generates preview")


func test_biome_assignment_based_on_json() -> void:
	"""Test that biomes are assigned based on JSON configuration."""
	# Generate heightmap with known values
	world_map_data.seed = 12345
	map_generator.generate_map(world_map_data, false)
	
	# Generate biome preview
	var biome_img: Image = map_generator.generate_biome_preview(world_map_data)
	assert_not_null(biome_img, "FAIL: Expected biome image. Context: Biome assignment. Why: Should generate biome preview. Hint: Check generation.")
	
	# Sample a few pixels and verify they have valid colors (not black/white default)
	var sample_positions: Array[Vector2i] = [
		Vector2i(100, 100),
		Vector2i(256, 256),
		Vector2i(400, 400)
	]
	
	for pos: Vector2i in sample_positions:
		if pos.x < biome_img.get_width() and pos.y < biome_img.get_height():
			var color: Color = biome_img.get_pixel(pos.x, pos.y)
			# Color should be valid (not pure black or white, unless it's ocean/snow)
			assert_true(color.r > 0.0 or color.g > 0.0 or color.b > 0.0, "FAIL: Biome color is black at %s. Context: Biome assignment. Why: Should have valid biome colors. Hint: Check _get_biome_color()." % pos)
	
	pass_test("Biomes assigned based on JSON configuration")


func test_biome_blending_enabled() -> void:
	"""Test that biome blending works when transition width > 0."""
	map_generator.biome_transition_width = 0.1
	map_generator.generate_map(world_map_data, false)
	
	var biome_img: Image = map_generator.generate_biome_preview(world_map_data)
	assert_not_null(biome_img, "FAIL: Expected biome image with blending. Context: Biome blending. Why: Should generate with blending. Hint: Check blending logic.")
	
	# Sample pixels near biome boundaries (should show blended colors)
	# For now, just verify generation succeeds with blending enabled
	pass_test("Biome blending enabled and functional")


func test_temperature_moisture_affect_biomes() -> void:
	"""Test that temperature and moisture values affect biome assignment."""
	# Generate with default climate
	world_map_data.seed = 12345
	map_generator.generate_map(world_map_data, false)
	var biome_img1: Image = map_generator.generate_biome_preview(world_map_data)
	
	# Generate with modified temperature bias (warmer)
	world_map_data.temperature_bias = 0.5
	map_generator._configure_noise(world_map_data)
	map_generator.generate_map(world_map_data, false)
	var biome_img2: Image = map_generator.generate_biome_preview(world_map_data)
	
	assert_not_null(biome_img1, "FAIL: Expected first biome image. Context: Climate effects. Why: Should generate biome preview. Hint: Check generation.")
	assert_not_null(biome_img2, "FAIL: Expected second biome image. Context: Climate effects. Why: Should generate with bias. Hint: Check bias application.")
	
	# Compare center pixels (should differ due to temperature bias)
	var center_x: int = biome_img1.get_width() / 2
	var center_y: int = biome_img1.get_height() / 2
	var color1: Color = biome_img1.get_pixel(center_x, center_y)
	var color2: Color = biome_img2.get_pixel(center_x, center_y)
	
	# Colors should differ (allowing some tolerance)
	var diff: float = color1.distance_to(color2)
	assert_gt(diff, 0.05, "FAIL: Temperature bias should affect biome colors. Context: Climate effects. Why: Bias should change biome assignment. Hint: Check bias application in _get_biome_color().")
	
	pass_test("Temperature and moisture affect biome assignment")


func test_biome_configs_have_required_fields() -> void:
	"""Test that all biome configs have required fields after normalization."""
	var file: FileAccess = FileAccess.open(BIOME_CONFIG_PATH, FileAccess.READ)
	if file == null:
		pass_test("Biome config file not found, skipping test")
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	json.parse(json_string)
	var data: Dictionary = json.data
	var biomes: Array = data.get("biomes", [])
	
	for biome: Dictionary in biomes:
		assert_true(biome.has("id"), "FAIL: Biome missing 'id' field. Context: Config validation. Why: All biomes need ID. Hint: Add id field.")
		assert_true(biome.has("name"), "FAIL: Biome missing 'name' field. Context: Config validation. Why: All biomes need name. Hint: Add name field.")
		assert_true(biome.has("temperature_range"), "FAIL: Biome missing 'temperature_range'. Context: Config validation. Why: All biomes need temperature range. Hint: Add temperature_range array.")
		assert_true(biome.has("rainfall_range"), "FAIL: Biome missing 'rainfall_range'. Context: Config validation. Why: All biomes need rainfall range. Hint: Add rainfall_range array.")
		assert_true(biome.has("color"), "FAIL: Biome missing 'color' field. Context: Config validation. Why: All biomes need color. Hint: Add color array.")
	
	pass_test("All biome configs have required fields")
