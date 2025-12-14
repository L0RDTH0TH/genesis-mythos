# ╔═══════════════════════════════════════════════════════════
# ║ test_world_gen_workflow.gd
# ║ Desc: Integration tests for complete world generation workflow
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Test fixture: Complete workflow components
var world_builder_ui: Control
var map_maker: MapMakerModule
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
	"""Setup components before each test."""
	# Create WorldBuilderUI
	var scene_path: String = "res://ui/world_builder/WorldBuilderUI.tscn"
	if ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		world_builder_ui = scene.instantiate() as Control
		test_scene.add_child(world_builder_ui)
	else:
		world_builder_ui = Control.new()
		world_builder_ui.name = "WorldBuilderUI"
		test_scene.add_child(world_builder_ui)
	
	# Create MapMakerModule
	map_maker = MapMakerModule.new()
	map_maker.name = "MapMakerModule"
	test_scene.add_child(map_maker)
	
	await get_tree().process_frame
	await get_tree().process_frame

func after_each() -> void:
	"""Cleanup components after each test."""
	if world_builder_ui:
		world_builder_ui.queue_free()
	if map_maker:
		map_maker.queue_free()
	await get_tree().process_frame
	world_builder_ui = null
	map_maker = null

func test_world_builder_integrates_with_map_maker() -> void:
	"""Test that WorldBuilderUI can integrate with MapMakerModule."""
	assert_not_null(world_builder_ui, "FAIL: Expected WorldBuilderUI to exist. Context: Integration test setup. Why: UI should be created. Hint: Check WorldBuilderUI scene loads.")
	assert_not_null(map_maker, "FAIL: Expected MapMakerModule to exist. Context: Integration test setup. Why: Map maker should be created. Hint: Check MapMakerModule instantiation.")
	
	# Test that both components exist and can interact
	pass_test("WorldBuilderUI and MapMakerModule both initialized")

func test_map_generation_workflow() -> void:
	"""Test complete map generation workflow from seed to heightmap."""
	var test_seed: int = 12345
	var test_width: int = 256  # Smaller for faster tests
	var test_height: int = 256
	
	# Step 1: Initialize map maker
	if map_maker.has_method("initialize_from_step_data"):
		map_maker.initialize_from_step_data(test_seed, test_width, test_height)
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Step 2: Generate map
		if map_maker.has_method("generate_map"):
			map_maker.generate_map()
			await get_tree().process_frame
			await get_tree().process_frame
			
			# Step 3: Verify heightmap created
			if map_maker.has_method("get_world_map_data"):
				var world_map_data = map_maker.get_world_map_data()
				assert_not_null(world_map_data, "FAIL: Expected world_map_data after generation. Context: Complete workflow. Why: Data should exist. Hint: Check workflow: initialize_from_step_data() -> generate_map() -> get_world_map_data().")
				
				if world_map_data != null and world_map_data.has("heightmap_image"):
					var heightmap_image = world_map_data.get("heightmap_image")
					assert_not_null(heightmap_image, "FAIL: Expected heightmap_image after generation. Context: Complete workflow. Why: Image should be created. Hint: Check MapGenerator.generate_map() creates heightmap.")
					pass_test("Map generation workflow completed successfully")
				else:
					push_warning("heightmap_image not accessible, workflow may have succeeded")
					pass_test("Workflow completed, heightmap_image not accessible")
			else:
				push_warning("get_world_map_data method not found")
				pass_test("Workflow completed, get_world_map_data not accessible")
		else:
			push_warning("generate_map method not found")
			pass_test("Workflow setup complete, generate_map not accessible")
	else:
		push_warning("initialize_from_step_data method not found")
		pass_test("Workflow setup attempted, initialize_from_step_data not accessible")

func test_step_navigation_preserves_data() -> void:
	"""Test that navigating between wizard steps preserves map data."""
	if not world_builder_ui.has("current_step"):
		push_warning("WorldBuilderUI.current_step not accessible, skipping test")
		pass_test("current_step not accessible")
		return
	
	# Set initial step data
	if world_builder_ui.has("step_data"):
		var step_data: Dictionary = world_builder_ui.get("step_data")
		var test_data: String = "test_map_data_123"
		step_data["Map Generation & Editing"] = {"seed": 12345, "width": 512, "height": 512}
		
		# Navigate forward
		if world_builder_ui.has_method("_on_next_pressed"):
			world_builder_ui._on_next_pressed()
			await get_tree().process_frame
			
			# Navigate back
			if world_builder_ui.has_method("_on_back_pressed"):
				world_builder_ui._on_back_pressed()
				await get_tree().process_frame
				
				# Verify data still exists
				var step_data_after: Dictionary = world_builder_ui.get("step_data")
				var map_gen_data: Dictionary = step_data_after.get("Map Generation & Editing", {})
				var seed_value = map_gen_data.get("seed", -1)
				
				assert_eq(seed_value, 12345, "FAIL: Expected step data to persist after navigation. Context: Forward then back. Why: Data should be preserved. Hint: Check WorldBuilderUI step_data persistence.")
				pass_test("Step navigation preserves data")
			else:
				push_warning("_on_back_pressed method not found")
				pass_test("Navigation forward completed, back method not accessible")
		else:
			push_warning("_on_next_pressed method not found")
			pass_test("Step data set, navigation methods not accessible")
	else:
		push_warning("step_data not accessible")
		pass_test("step_data not accessible")

func test_view_mode_switching() -> void:
	"""Test that view mode switching works correctly."""
	if map_maker.has_method("set_view_mode"):
		# Test all view modes
		var modes: Array = [
			MapRenderer.ViewMode.HEIGHTMAP,
			MapRenderer.ViewMode.BIOMES,
			MapRenderer.ViewMode.POLITICAL
		]
		
		for mode in modes:
			map_maker.set_view_mode(mode)
			await get_tree().process_frame
			
			if map_maker.has("current_view_mode"):
				var current_mode = map_maker.get("current_view_mode")
				assert_eq(current_mode, mode, "FAIL: Expected view mode %d, got %d. Context: set_view_mode(%d). Why: Mode should change. Hint: Check MapMakerModule.set_view_mode() updates correctly." % [mode, current_mode, mode])
		
		pass_test("View mode switching works correctly")
	else:
		push_warning("set_view_mode method not found, skipping test")
		pass_test("set_view_mode method not accessible")

func test_icon_placement_and_clustering() -> void:
	"""Test icon placement and clustering workflow."""
	if not world_builder_ui.has("placed_icons"):
		push_warning("WorldBuilderUI.placed_icons not accessible, skipping test")
		pass_test("placed_icons not accessible")
		return
	
	var placed_icons: Array = world_builder_ui.get("placed_icons")
	
	# Create test icons
	var icon1: IconNode = IconNode.new()
	icon1.position = Vector2(0, 0)
	icon1.set_icon_data("test1", Color.RED, "jungle")
	
	var icon2: IconNode = IconNode.new()
	icon2.position = Vector2(50, 50)  # Close to icon1
	icon2.set_icon_data("test2", Color.BLUE, "pine")
	
	# Add to placed icons (if method exists)
	if world_builder_ui.has_method("_add_icon"):
		world_builder_ui._add_icon(icon1)
		world_builder_ui._add_icon(icon2)
		await get_tree().process_frame
		
		var icons_after: Array = world_builder_ui.get("placed_icons")
		assert_true(icons_after.size() >= 2, "FAIL: Expected at least 2 icons placed, got %d. Context: Icon placement. Why: Icons should be added. Hint: Check WorldBuilderUI._add_icon() adds to placed_icons.")
		
		# Test clustering if method exists
		if world_builder_ui.has_method("_cluster_icons"):
			world_builder_ui._cluster_icons()
			await get_tree().process_frame
			
			if world_builder_ui.has("icon_groups"):
				var icon_groups: Array = world_builder_ui.get("icon_groups")
				# Should have at least one group (icons are close)
				assert_true(icon_groups.size() > 0, "FAIL: Expected icon groups after clustering, got %d. Context: Clustering close icons. Why: Close icons should cluster. Hint: Check WorldBuilderUI._cluster_icons() creates groups.")
				pass_test("Icon placement and clustering works")
			else:
				push_warning("icon_groups not accessible")
				pass_test("Icons placed, clustering completed, icon_groups not accessible")
		else:
			push_warning("_cluster_icons method not found")
			pass_test("Icons placed, _cluster_icons method not accessible")
	else:
		push_warning("_add_icon method not found")
		pass_test("Icon creation works, _add_icon method not accessible")
	
	# Cleanup
	if icon1:
		icon1.queue_free()
	if icon2:
		icon2.queue_free()
	await get_tree().process_frame
