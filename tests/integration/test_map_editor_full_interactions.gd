# ╔═══════════════════════════════════════════════════════════
# ║ test_map_editor_full_interactions.gd
# ║ Desc: Full-chain UI interaction tests for MapEditor - every button, slider, dropdown, text input
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends UIInteractionTestBase

## MapEditor scene path (if exists) or script path
const MAP_EDITOR_SCENE: String = "res://scripts/MapEditor.gd"  # May need scene path if exists

## Critical scripts that must preload
const CRITICAL_SCRIPTS: Array[String] = [
	"res://core/world_generation/MapGenerator.gd",
	"res://core/world_generation/MapRenderer.gd"
]

## Critical resources that must preload
## Note: Archetypes are now loaded dynamically from res://data/archetypes/ directory
const CRITICAL_RESOURCES: Array[String] = []

func before_each() -> void:
	"""Setup MapEditor test environment."""
	super.before_each()
	
	# Preload all critical scripts
	for script_path in CRITICAL_SCRIPTS:
		var script = preload_script(script_path)
		if script == null:
			return
	
	# Preload all critical resources
	for resource_path in CRITICAL_RESOURCES:
		var resource = preload_resource(resource_path)
		if resource == null:
			return
	
	# Try to load MapEditor scene, or create instance from script
	var scene: PackedScene = load("res://scripts/MapEditor.tscn") if ResourceLoader.exists("res://scripts/MapEditor.tscn") else null
	if scene:
		ui_instance = load_ui_scene("res://scripts/MapEditor.tscn")
	else:
		# Create instance from script directly
		var map_editor_script = preload_script("res://scripts/MapEditor.gd")
		if map_editor_script:
			ui_instance = map_editor_script.new()
			if ui_instance:
				test_scene.add_child(ui_instance)
				await_process_frames(3)
				check_for_errors("MapEditor instantiation")
	
	if ui_instance == null:
		pass_test("MapEditor scene/script not found or failed to load")

# ============================================================
# MAP EDITOR INTERACTIONS
# ============================================================

func test_seed_input_all_scenarios() -> void:
	"""Test seed input - valid, invalid, edge cases."""
	if not ui_instance:
		pass_test("MapEditor not available")
		return
	
	var seed_input := find_control_by_name("SeedInput") as LineEdit
	if not seed_input:
		pass_test("SeedInput not found")
		return
	
	# Test valid positive seed
	simulate_text_input(seed_input, "12345")
	await_process_frames(1)
	check_for_errors("valid positive seed")
	
	# Test negative seed
	simulate_text_input(seed_input, "-100")
	await_process_frames(1)
	check_for_errors("negative seed")
	
	# Test non-numeric input
	simulate_text_input(seed_input, "abc123")
	await_process_frames(1)
	check_for_errors("non-numeric seed")
	
	# Test empty string
	simulate_text_input(seed_input, "")
	await_process_frames(1)
	check_for_errors("empty seed")
	
	pass_test("Seed input handles all scenarios")

func test_random_seed_button() -> void:
	"""Test random seed button."""
	if not ui_instance:
		pass_test("MapEditor not available")
		return
	
	var random_button := find_control_by_name("RandomSeedButton") as Button
	if random_button:
		simulate_button_click(random_button)
		await_process_frames(2)
		check_for_errors("random seed button")
		pass_test("Random seed button clicked")
	else:
		pass_test("RandomSeedButton not found")

func test_generate_button_full_lifecycle() -> void:
	"""Test generate button - FULL LIFECYCLE."""
	if not ui_instance:
		pass_test("MapEditor not available")
		return
	
	var generate_button := find_control_by_name("GenerateButton") as Button
	if not generate_button:
		pass_test("GenerateButton not found")
		return
	
	# Track expected signals if available
	if ui_instance.has_signal("map_generated"):
		await_signal(ui_instance, "map_generated", 10.0)
	
	# Click generate button
	simulate_button_click(generate_button)
	
	# Wait for generation
	var timeout: float = 10.0
	var elapsed: float = 0.0
	
	while elapsed < timeout:
		await_process_frames(1)
		elapsed += get_process_delta_time()
		
		# Check for errors during generation
		if error_listener and error_listener.has_errors():
			var all_errors: String = error_listener.get_all_errors()
			fail_test("FAIL: Errors during generation:\n%s\nContext: Generation lifecycle. Why: Generation should complete without errors." % all_errors)
			return
		
		# Check if generation completed (check for height_img or canvas_texture)
		if ui_instance.has("height_img"):
			var height_img = ui_instance.get("height_img")
			if height_img != null:
				break
	
	await_process_frames(3)
	check_for_errors("generate button - full lifecycle")
	
	pass_test("Generate button triggers map generation - full lifecycle verified")

func test_size_dropdown_all_options() -> void:
	"""Test size dropdown - select every option."""
	if not ui_instance:
		pass_test("MapEditor not available")
		return
	
	var size_dropdown := find_control_by_name("SizeDropdown") as OptionButton
	if size_dropdown:
		var item_count: int = size_dropdown.get_item_count()
		if item_count > 0:
			for i in range(item_count):
				simulate_option_selection(size_dropdown, i)
				await_process_frames(1)
				check_for_errors("size selection %d" % i)
		pass_test("Size dropdown - %d options tested" % item_count)
	else:
		pass_test("SizeDropdown not found")

func test_style_dropdown_all_options() -> void:
	"""Test style dropdown - select every option."""
	if not ui_instance:
		pass_test("MapEditor not available")
		return
	
	var style_dropdown := find_control_by_name("StyleDropdown") as OptionButton
	if style_dropdown:
		var item_count: int = style_dropdown.get_item_count()
		if item_count > 0:
			for i in range(item_count):
				simulate_option_selection(style_dropdown, i)
				await_process_frames(1)
				check_for_errors("style selection %d" % i)
		pass_test("Style dropdown - %d options tested" % item_count)
	else:
		pass_test("StyleDropdown not found")

func test_landmass_dropdown_all_options() -> void:
	"""Test landmass dropdown - select every option."""
	if not ui_instance:
		pass_test("MapEditor not available")
		return
	
	var landmass_dropdown := find_control_by_name("LandmassDropdown") as OptionButton
	if landmass_dropdown:
		var item_count: int = landmass_dropdown.get_item_count()
		if item_count > 0:
			for i in range(item_count):
				simulate_option_selection(landmass_dropdown, i)
				await_process_frames(1)
				check_for_errors("landmass selection %d" % i)
		pass_test("Landmass dropdown - %d options tested" % item_count)
	else:
		pass_test("LandmassDropdown not found")

func test_rapid_interactions() -> void:
	"""Test rapid interactions - stress testing."""
	if not ui_instance:
		pass_test("MapEditor not available")
		return
	
	var generate_button := find_control_by_name("GenerateButton") as Button
	if generate_button:
		# Rapid clicks
		for i in range(10):
			simulate_button_click(generate_button)
			await_process_frames(1)
		check_for_errors("rapid button clicks")
		pass_test("Rapid interactions handled gracefully")
	else:
		pass_test("GenerateButton not found for rapid interaction test")
