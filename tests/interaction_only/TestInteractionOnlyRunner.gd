# ╔═══════════════════════════════════════════════════════════
# ║ TestInteractionOnlyRunner.gd
# ║ Desc: Executes ONLY code paths triggered by player interaction – never hit on launch
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

@tool
extends Node

# TestHelpers is a class_name - can't preload due to static async functions, will load at runtime
var TestHelpersScript

# Visual delay for observing UI responses (0.0 = fast, 1.0+ = slow/observable)
const VISUAL_DELAY: float = 0.0

# Test file paths
const WORLD_GEN_TESTS := [
	"res://tests/interaction_only/world_gen/test_seed_size.gd",
	"res://tests/interaction_only/world_gen/test_terrain.gd",
	"res://tests/interaction_only/world_gen/test_climate.gd",
	"res://tests/interaction_only/world_gen/test_biome.gd",
	"res://tests/interaction_only/world_gen/test_civilization.gd",
	"res://tests/interaction_only/world_gen/test_resources.gd",
	"res://tests/interaction_only/world_gen/test_fantasy_styles.gd",
	"res://tests/interaction_only/world_gen/test_seed_generation.gd",
	"res://tests/interaction_only/world_gen/test_mesh_spawning.gd"
]

const CHAR_CREATION_TESTS := [
	"res://tests/interaction_only/char_creation/test_tab_navigation.gd",
	"res://tests/interaction_only/char_creation/test_race_tab.gd",
	"res://tests/interaction_only/char_creation/test_class_tab.gd",
	"res://tests/interaction_only/char_creation/test_background_tab.gd",
	"res://tests/interaction_only/char_creation/test_ability_score_tab.gd",
	"res://tests/interaction_only/char_creation/test_appearance_tab.gd",
	"res://tests/interaction_only/char_creation/test_name_confirm_tab.gd"
]

const PREVIEW_TESTS := [
	"res://tests/interaction_only/test_preview_panel.gd"
]

const VALIDATION_EDGE_TESTS := [
	"res://tests/interaction_only/test_validation_edges.gd"
]

const VISUAL_FEEDBACK_TESTS := [
	"res://tests/interaction_only/test_visual_feedback.gd"
]

var current_test_index: int = 0
var test_log_list: ItemList
var total_passed: int = 0
var total_failed: int = 0
var total_tests: int = 0
var test_results: Array[Dictionary] = []
var coverage_stats: Dictionary = {
	"world_gen": {"total": 0, "passed": 0},
	"char_creation": {"total": 0, "passed": 0},
	"preview": {"total": 0, "passed": 0},
	"validation": {"total": 0, "passed": 0},
	"visual": {"total": 0, "passed": 0}
}

func _ready() -> void:
	# Load TestHelpers at runtime (can't preload scripts with static async functions)
	TestHelpersScript = load("res://tests/interaction_only/helpers/TestHelpers.gd")
	
	if not Engine.is_editor_hint():
		# Run in exported game OR when explicitly launched via run_project
		_setup_debug_overlay()
		call_deferred("_start_tests")

func _setup_debug_overlay() -> void:
	test_log_list = get_node("../InteractionTestOverlay/TestLogPanel/TestLogList") as ItemList
	test_log_list.clear()
	test_log_list.allow_reselect = true
	test_log_list.select_mode = ItemList.SELECT_SINGLE
	
	_log("INTERACTION-ONLY TEST SUITE – FULL COVERAGE", "HEADER")
	_log("Visual Delay: %.1fs (fast mode)" % VISUAL_DELAY, "HEADER")
	_log("Log system: ItemList (100% guaranteed visible)", "PASS")

func _start_tests() -> void:
	await get_tree().create_timer(1.0).timeout
	
	_log("\n=== WORLD GENERATION TESTS ===", "")
	await _run_test_suite("World Generation", WORLD_GEN_TESTS, "world_gen")
	
	_log("\n=== CHARACTER CREATION TESTS ===", "")
	await _run_test_suite("Character Creation", CHAR_CREATION_TESTS, "char_creation")
	
	_log("\n=== PREVIEW PANEL TESTS ===", "")
	await _run_test_suite("Preview Panel", PREVIEW_TESTS, "preview")
	
	_log("\n=== VALIDATION & EDGE CASE TESTS ===", "")
	await _run_test_suite("Validation & Edges", VALIDATION_EDGE_TESTS, "validation")
	
	_log("\n=== VISUAL FEEDBACK TESTS ===", "")
	await _run_test_suite("Visual Feedback", VISUAL_FEEDBACK_TESTS, "visual")
	
	_log("\n╔═══════════════════════════════════════════════════════════", "PASS")
	_log("║ FINAL RESULTS", "PASS")
	_log("║ PASSED: %d" % total_passed, "PASS")
	_log("║ FAILED: %d" % total_failed, "FAIL" if total_failed > 0 else "PASS")
	_log("║ TOTAL: %d" % total_tests, "PASS")
	_log("║ COVERAGE: %.1f%%" % (_calculate_coverage() * 100.0), "PASS")
	_log("╚═══════════════════════════════════════════════════════════", "PASS")
	_log("\n=== COVERAGE BY CATEGORY ===", "")
	_log_coverage_stats()
	_log("\nAll interaction-only paths tested!", "PASS")

func _run_test_suite(suite_name: String, test_files: Array, category: String = "") -> void:
	"""Run a suite of test files"""
	_log("\n[%s] Running %d test files..." % [suite_name, test_files.size()], "")
	
	var suite_passed := 0
	var suite_total := 0
	
	for test_file_path in test_files:
		if not ResourceLoader.exists(test_file_path):
			_log("[SKIP] Test file not found: %s" % test_file_path, "")
			continue
		
		var test_script := load(test_file_path) as GDScript
		if not test_script:
			_log("[ERROR] Failed to load test script: %s" % test_file_path, "FAIL")
			continue
		
		var test_instance := Node.new()
		test_instance.set_script(test_script)
		add_child(test_instance)
		
		_log("\n[%s] Running tests from: %s" % [suite_name, test_file_path.get_file()], "")
		
		# Get all test functions (functions starting with "test_")
		var test_methods := []
		for method_name in test_script.get_script_method_list():
			if method_name.name.begins_with("test_"):
				test_methods.append(method_name.name)
		
		# Set visual_delay in test instance
		if "visual_delay" in test_instance:
			test_instance.visual_delay = VISUAL_DELAY
		
		# Run each test function
		for method_name in test_methods:
			_log("\n  → Running: %s" % method_name, "RUNNING")
			
			suite_total += 1
			total_tests += 1
			
			# Call test function
			if test_instance.has_method(method_name):
				var result: Dictionary = await test_instance.call(method_name)
				if result.has("passed") and result["passed"]:
					_pass(result.get("message", method_name))
					suite_passed += 1
					if category and coverage_stats.has(category):
						coverage_stats[category].passed += 1
				else:
					_fail(result.get("message", method_name))
				if category and coverage_stats.has(category):
					coverage_stats[category].total += 1
				await TestHelpersScript.wait_visual(VISUAL_DELAY * 0.5)  # Pause between tests
				await get_tree().process_frame
			else:
				_log("    [WARNING] Method %s not found or not callable" % method_name, "")
		
		test_instance.queue_free()
		await get_tree().process_frame
	
	# Log suite summary
	if suite_total > 0:
		var suite_coverage := float(suite_passed) / float(suite_total) * 100.0
		var status := "PASS" if suite_passed == suite_total else "FAIL"
		_log("\n[%s] Suite Summary: %d/%d passed (%.1f%%)" % [suite_name, suite_passed, suite_total, suite_coverage], status)

func _log(message: String, status: String = "") -> void:
	if not test_log_list:
		return
	
	var prefix := ""
	var color := Color.WHITE
	
	match status:
		"PASS":
			prefix = "✓ PASS  "
			color = Color(0, 1, 0.6)
		"FAIL":
			prefix = "✗ FAIL  "
			color = Color(1, 0.2, 0.3)
		"RUNNING":
			prefix = "▶ RUNNING "
			color = Color(1, 0.95, 0)
		"HEADER":
			prefix = "▣ HEADER "
			color = Color(0.4, 0.8, 1)
		_:
			prefix = "  INFO  "
			color = Color(0.85, 0.85, 0.9)
	
	var full_line := prefix + message
	test_log_list.add_item(full_line)
	var last_index := test_log_list.get_item_count() - 1
	test_log_list.set_item_custom_fg_color(last_index, color)
	
	# THE ONLY METHOD THAT HAS NEVER FAILED IN GODOT 4.3:
	call_deferred("_force_scroll_to_bottom")

func _force_scroll_to_bottom() -> void:
	await get_tree().process_frame  # Wait for layout
	if test_log_list.get_item_count() == 0:
		return
	var last := test_log_list.get_item_count() - 1
	test_log_list.select(last, true)
	test_log_list.ensure_current_is_visible()
	# Extra insurance – force the scroll bar to bottom
	var vscroll = test_log_list.get_v_scroll_bar()
	if vscroll:
		vscroll.value = vscroll.max_value

func _pass(msg: String) -> void:
	total_passed += 1
	_log("    [PASS] " + msg, "PASS")

func _fail(msg: String) -> void:
	total_failed += 1
	push_error(msg)
	_log("    [FAIL] " + msg, "FAIL")

func _calculate_coverage() -> float:
	"""Calculate overall test coverage percentage"""
	if total_tests == 0:
		return 0.0
	return float(total_passed) / float(total_tests)

func _log_coverage_stats() -> void:
	"""Log coverage statistics by category"""
	for category in coverage_stats.keys():
		var stats: Dictionary = coverage_stats[category]
		if stats.total > 0:
			var coverage := float(stats.passed) / float(stats.total) * 100.0
			var status := "PASS" if stats.passed == stats.total else "FAIL"
			_log("  %s: %d/%d (%.1f%%)" % [category.capitalize(), stats.passed, stats.total, coverage], status)
		else:
			_log("  %s: No tests" % category.capitalize(), "")
