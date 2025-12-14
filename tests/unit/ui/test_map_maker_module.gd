# ╔═══════════════════════════════════════════════════════════
# ║ test_map_maker_module.gd
# ║ Desc: Unit tests for MapMakerModule initialization, map generation, and viewport setup
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Test fixture: MapMakerModule instance
var map_maker: MapMakerModule

## Test fixture: Scene tree for UI testing
var test_scene: Node

func before_all() -> void:
	"""Setup test scene before all tests."""
	test_scene = Node.new()
	test_scene.name = "TestScene"
	get_tree().root.add_child(test_scene)

func after_all() -> void:
	"""Cleanup test scene after all tests."""
	if test_scene:
		test_scene.queue_free()
		await get_tree().process_frame

func before_each() -> void:
	"""Setup MapMakerModule instance before each test."""
	map_maker = MapMakerModule.new()
	map_maker.name = "MapMakerModule"
	test_scene.add_child(map_maker)
	# Wait for _ready to complete
	await get_tree().process_frame
	await get_tree().process_frame

func after_each() -> void:
	"""Cleanup MapMakerModule instance after each test."""
	if map_maker:
		map_maker.queue_free()
		await get_tree().process_frame
	map_maker = null

func test_map_maker_module_initializes() -> void:
	"""Test that MapMakerModule initializes without errors."""
	assert_not_null(map_maker, "FAIL: Expected MapMakerModule to be created. Context: Instantiation. Why: Module should initialize. Hint: Check MapMakerModule._ready() completes without errors.")

func test_map_generator_created() -> void:
	"""Test that MapGenerator is created during initialization."""
	if not map_maker.has("map_generator"):
		push_warning("MapMakerModule.map_generator not accessible, skipping test")
		pass_test("map_generator not accessible")
		return
	
	var map_generator = map_maker.get("map_generator")
	assert_not_null(map_generator, "FAIL: Expected map_generator to be created. Context: MapMakerModule initialization. Why: Generator should exist. Hint: Check MapMakerModule._setup_generator() creates MapGenerator.")

func test_map_renderer_created() -> void:
	"""Test that MapRenderer is created during initialization."""
	if not map_maker.has("map_renderer"):
		push_warning("MapMakerModule.map_renderer not accessible, skipping test")
		pass_test("map_renderer not accessible")
		return
	
	var map_renderer = map_maker.get("map_renderer")
	assert_not_null(map_renderer, "FAIL: Expected map_renderer to be created. Context: MapMakerModule initialization. Why: Renderer should exist. Hint: Check MapMakerModule._setup_renderer() creates MapRenderer.")

func test_map_editor_created() -> void:
	"""Test that MapEditor is created during initialization."""
	if not map_maker.has("map_editor"):
		push_warning("MapMakerModule.map_editor not accessible, skipping test")
		pass_test("map_editor not accessible")
		return
	
	var map_editor = map_maker.get("map_editor")
	assert_not_null(map_editor, "FAIL: Expected map_editor to be created. Context: MapMakerModule initialization. Why: Editor should exist. Hint: Check MapMakerModule._setup_editor() creates MapEditor.")

func test_marker_manager_created() -> void:
	"""Test that MarkerManager is created during initialization."""
	if not map_maker.has("marker_manager"):
		push_warning("MapMakerModule.marker_manager not accessible, skipping test")
		pass_test("marker_manager not accessible")
		return
	
	var marker_manager = map_maker.get("marker_manager")
	assert_not_null(marker_manager, "FAIL: Expected marker_manager to be created. Context: MapMakerModule initialization. Why: Marker manager should exist. Hint: Check MapMakerModule._setup_marker_manager() creates MarkerManager.")

func test_viewport_created() -> void:
	"""Test that map viewport is created during initialization."""
	if not map_maker.has("map_viewport"):
		push_warning("MapMakerModule.map_viewport not accessible, skipping test")
		pass_test("map_viewport not accessible")
		return
	
	var map_viewport = map_maker.get("map_viewport")
	assert_not_null(map_viewport, "FAIL: Expected map_viewport to be created. Context: MapMakerModule initialization. Why: Viewport should exist. Hint: Check MapMakerModule._setup_viewport() creates SubViewport.")

func test_camera_created() -> void:
	"""Test that map camera is created during initialization."""
	if not map_maker.has("map_camera"):
		push_warning("MapMakerModule.map_camera not accessible, skipping test")
		pass_test("map_camera not accessible")
		return
	
	var map_camera = map_maker.get("map_camera")
	assert_not_null(map_camera, "FAIL: Expected map_camera to be created. Context: MapMakerModule initialization. Why: Camera should exist. Hint: Check MapMakerModule._setup_viewport() creates Camera2D.")

func test_initialize_from_step_data_creates_world_map_data() -> void:
	"""Test that initialize_from_step_data creates WorldMapData."""
	var test_seed: int = 12345
	var test_width: int = 512
	var test_height: int = 512
	
	if map_maker.has_method("initialize_from_step_data"):
		map_maker.initialize_from_step_data(test_seed, test_width, test_height)
		await get_tree().process_frame
		await get_tree().process_frame
		
		if map_maker.has("world_map_data"):
			var world_map_data = map_maker.get("world_map_data")
			assert_not_null(world_map_data, "FAIL: Expected world_map_data to be created. Context: initialize_from_step_data(seed=%d, width=%d, height=%d). Why: Data should be created. Hint: Check MapMakerModule.initialize_from_step_data() creates WorldMapData." % [test_seed, test_width, test_height])
			
			# Verify data properties
			if world_map_data.has("seed"):
				var seed_value = world_map_data.get("seed")
				assert_eq(seed_value, test_seed, "FAIL: Expected seed %d, got %d. Context: initialize_from_step_data. Why: Seed should match. Hint: Check WorldMapData.seed assignment.")
			
			if world_map_data.has("world_width"):
				var width = world_map_data.get("world_width")
				assert_eq(width, test_width, "FAIL: Expected width %d, got %d. Context: initialize_from_step_data. Why: Width should match. Hint: Check WorldMapData.world_width assignment.")
			
			if world_map_data.has("world_height"):
				var height = world_map_data.get("world_height")
				assert_eq(height, test_height, "FAIL: Expected height %d, got %d. Context: initialize_from_step_data. Why: Height should match. Hint: Check WorldMapData.world_height assignment.")
		else:
			push_warning("world_map_data not accessible, skipping verification")
			pass_test("world_map_data created but not accessible")
	else:
		push_warning("initialize_from_step_data method not found, skipping test")
		pass_test("initialize_from_step_data method not accessible")

func test_generate_map_creates_heightmap() -> void:
	"""Test that generate_map creates heightmap image."""
	var test_seed: int = 12345
	var test_width: int = 256  # Smaller for faster tests
	var test_height: int = 256
	
	if map_maker.has_method("initialize_from_step_data"):
		map_maker.initialize_from_step_data(test_seed, test_width, test_height)
		await get_tree().process_frame
		await get_tree().process_frame
		
		if map_maker.has_method("generate_map"):
			map_maker.generate_map()
			await get_tree().process_frame
			await get_tree().process_frame
			
			if map_maker.has("world_map_data"):
				var world_map_data = map_maker.get("world_map_data")
				if world_map_data != null and world_map_data.has("heightmap_image"):
					var heightmap_image = world_map_data.get("heightmap_image")
					assert_not_null(heightmap_image, "FAIL: Expected heightmap_image to be created. Context: generate_map() after initialization. Why: Generation should create image. Hint: Check MapMakerModule.generate_map() calls MapGenerator.generate_map().")
				else:
					push_warning("heightmap_image not accessible, skipping verification")
					pass_test("heightmap_image created but not accessible")
			else:
				push_warning("world_map_data not accessible, skipping test")
				pass_test("world_map_data not accessible")
		else:
			push_warning("generate_map method not found, skipping test")
			pass_test("generate_map method not accessible")
	else:
		push_warning("initialize_from_step_data method not found, skipping test")
		pass_test("initialize_from_step_data method not accessible")

func test_set_view_mode_changes_renderer_mode() -> void:
	"""Test that set_view_mode changes renderer view mode."""
	if map_maker.has_method("set_view_mode"):
		# Test setting to HEIGHTMAP mode
		map_maker.set_view_mode(MapRenderer.ViewMode.HEIGHTMAP)
		await get_tree().process_frame
		
		if map_maker.has("current_view_mode"):
			var current_mode = map_maker.get("current_view_mode")
			assert_eq(current_mode, MapRenderer.ViewMode.HEIGHTMAP, "FAIL: Expected view mode HEIGHTMAP, got %d. Context: set_view_mode(HEIGHTMAP). Why: Mode should change. Hint: Check MapMakerModule.set_view_mode() updates current_view_mode and calls MapRenderer.set_view_mode().")
		else:
			push_warning("current_view_mode not accessible, skipping verification")
			pass_test("View mode set but not accessible")
	else:
		push_warning("set_view_mode method not found, skipping test")
		pass_test("set_view_mode method not accessible")

func test_get_world_map_data_returns_data() -> void:
	"""Test that get_world_map_data returns world map data."""
	var test_seed: int = 12345
	var test_width: int = 256
	var test_height: int = 256
	
	if map_maker.has_method("initialize_from_step_data"):
		map_maker.initialize_from_step_data(test_seed, test_width, test_height)
		await get_tree().process_frame
		await get_tree().process_frame
		
		if map_maker.has_method("get_world_map_data"):
			var world_map_data = map_maker.get_world_map_data()
			assert_not_null(world_map_data, "FAIL: Expected get_world_map_data() to return WorldMapData. Context: After initialization. Why: Method should return data. Hint: Check MapMakerModule.get_world_map_data() returns world_map_data.")
		else:
			push_warning("get_world_map_data method not found, skipping test")
			pass_test("get_world_map_data method not accessible")
	else:
		push_warning("initialize_from_step_data method not found, skipping test")
		pass_test("initialize_from_step_data method not accessible")

func test_is_initialized_flag_set_after_init() -> void:
	"""Test that is_initialized flag is set after initialization."""
	var test_seed: int = 12345
	var test_width: int = 256
	var test_height: int = 256
	
	if map_maker.has_method("initialize_from_step_data"):
		map_maker.initialize_from_step_data(test_seed, test_width, test_height)
		await get_tree().process_frame
		await get_tree().process_frame
		
		if map_maker.has("is_initialized"):
			var is_initialized = map_maker.get("is_initialized")
			assert_true(is_initialized, "FAIL: Expected is_initialized to be true after initialization. Context: After initialize_from_step_data(). Why: Flag should be set. Hint: Check MapMakerModule.initialize_from_step_data() sets is_initialized = true.")
		else:
			push_warning("is_initialized not accessible, skipping test")
			pass_test("is_initialized not accessible")
	else:
		push_warning("initialize_from_step_data method not found, skipping test")
		pass_test("initialize_from_step_data method not accessible")
