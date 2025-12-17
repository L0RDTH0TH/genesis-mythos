# ╔═══════════════════════════════════════════════════════════
# ║ UIInteractionTestBase.gd
# ║ Desc: Base class for all UI interaction tests - provides error detection, await helpers, and assertions
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest
class_name UIInteractionTestBase

## Preload TestErrorListener
const TestErrorListener = preload("res://tests/helpers/TestErrorListener.gd")

## Global error listener instance
var error_listener: TestErrorListener

## Captured debug output (errors, warnings, prints)
var debug_output: Array[String] = []

## Error patterns to detect in output
var error_patterns: Array[String] = [
	"ERROR",
	"Parse Error",
	"Failed to load",
	"Invalid call",
	"Nonexistent function",
	"Attempt to call",
	"Null instance",
	"is null",
	"Null reference",
	"Script error",
	"Resource load failed",
	"Thread error",
	"Assertion failed",
	"FATAL",
	"CRASH"
]

## Warning patterns (tracked but don't fail by default)
var warning_patterns: Array[String] = [
	"WARNING",
	"Warning",
	"Deprecated"
]

## Tracked scripts (for parse error detection)
var tracked_scripts: Dictionary = {}  # path -> GDScript

## Tracked resources (for load failure detection)
var tracked_resources: Dictionary = {}  # path -> Resource

## Expected signals (signal_name -> timeout_time)
var expected_signals: Dictionary = {}

## Tracked threads
var tracked_threads: Array[Thread] = []

## Test scene root
var test_scene: Node

## UI scene instance being tested
var ui_instance: Node

func before_each() -> void:
	"""Setup error detection before each test."""
	error_listener = TestErrorListener.get_instance()
	error_listener.clear()
	debug_output.clear()
	tracked_scripts.clear()
	tracked_resources.clear()
	expected_signals.clear()
	tracked_threads.clear()
	
	# Create test scene if not exists
	if not test_scene:
		test_scene = Node.new()
		test_scene.name = "TestScene"
		get_tree().root.add_child(test_scene)

func after_each() -> void:
	"""Final error sweep after each test."""
	# Wait for any async operations
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Final error check
	assert_no_errors_logged("final sweep after test completion")
	
	# Cleanup
	if ui_instance:
		ui_instance.queue_free()
		await get_tree().process_frame
	ui_instance = null

func after_all() -> void:
	"""Cleanup test scene after all tests."""
	if test_scene:
		test_scene.queue_free()
		await get_tree().process_frame
	test_scene = null

# ============================================================
# ERROR DETECTION METHODS
# ============================================================

func capture_debug_output() -> void:
	"""Capture current debug output from Godot (if available via MCP or other means)."""
	# Note: In Godot, we can't directly capture print() output programmatically
	# But we can check error_listener and scan for errors in known places
	pass

func preload_script(script_path: String) -> GDScript:
	"""Preload a script and track it for parse error detection. Returns null if load fails."""
	var script: GDScript = load(script_path) as GDScript
	if script == null:
		error_listener.capture_script_error(script_path, "Failed to load script")
		fail_test("FAIL: Script failed to preload: %s\nContext: Pre-interaction script validation. Why: Script must load before interaction. Hint: Check for parse errors in %s." % [script_path, script_path])
		return null
	
	# Check if script can be instantiated (catches some parse errors)
	if script.can_instantiate():
		var test_instance = script.new()
		if test_instance == null:
			error_listener.capture_script_error(script_path, "Failed to instantiate")
			fail_test("FAIL: Script failed to instantiate: %s\nContext: Pre-interaction script validation. Why: Script must be instantiable. Hint: Check _init() method in %s." % [script_path, script_path])
			return null
		# Clean up test instance
		if test_instance is RefCounted:
			pass  # Auto-freed
		elif test_instance is Node:
			test_instance.queue_free()
	
	tracked_scripts[script_path] = script
	return script

func preload_resource(resource_path: String) -> Resource:
	"""Preload a resource and track it for load failure detection. Returns null if load fails."""
	var resource: Resource = load(resource_path)
	if resource == null:
		error_listener.capture_resource_load_failure(resource_path)
		fail_test("FAIL: Resource failed to preload: %s\nContext: Pre-interaction resource validation. Why: Resource must load before interaction. Hint: Check file exists and is valid: %s." % [resource_path, resource_path])
		return null
	
	tracked_resources[resource_path] = resource
	return resource

func check_for_errors(context: String) -> void:
	"""Check for errors after an interaction. Fails test if any errors detected."""
	# Check error listener
	if error_listener and error_listener.has_errors():
		var all_errors: String = error_listener.get_all_errors()
		fail_test("FAIL: Errors detected during %s:\n%s\nContext: Full lifecycle error detection. Why: Interactions should complete without errors. Hint: Check script compilation, resource loading, signal emissions, and null references." % [context, all_errors])
		return
	
	# Check for missing expected signals
	var missing_signals: Array[String] = error_listener.check_expected_signals() if error_listener else []
	if missing_signals.size() > 0:
		fail_test("FAIL: Missing expected signals during %s: %s\nContext: Signal tracking. Why: Expected signals should fire within timeout. Hint: Check signal connections and async operations." % [context, str(missing_signals)])
		return
	
	# Check for active threads (potential leaks)
	var active_threads: Array[Thread] = error_listener.check_threads_complete() if error_listener else []
	if active_threads.size() > 0:
		fail_test("FAIL: Active threads detected during %s: %d threads still running\nContext: Thread lifecycle. Why: Threads should complete or be cleaned up. Hint: Check thread.wait_to_finish() calls." % [context, active_threads.size()])
		return

func assert_no_errors_logged(context: String = "test completion") -> void:
	"""Assert that no errors were logged during the test. Final check before test passes."""
	check_for_errors(context)

# ============================================================
# AWAIT HELPERS
# ============================================================

func await_process_frames(count: int = 1) -> void:
	"""Await multiple process frames."""
	for i in range(count):
		await get_tree().process_frame

func await_physics_frames(count: int = 1) -> void:
	"""Await multiple physics frames."""
	for i in range(count):
		await get_tree().physics_frame

func await_signal(source: Object, signal_name: String, timeout_seconds: float = 10.0) -> bool:
	"""Await a signal with timeout. Returns true if signal fired, false if timeout."""
	if not source.has_signal(signal_name):
		fail_test("FAIL: Signal '%s' does not exist on %s\nContext: Signal awaiting. Why: Signal must exist to await. Hint: Check signal name and source object." % [signal_name, str(source)])
		return false
	
	var signal_fired: bool = false
	var timeout_reached: bool = false
	
	var callable: Callable = func():
		signal_fired = true
	
	source.connect(signal_name, callable)
	
	# Wait with timeout
	var elapsed: float = 0.0
	while not signal_fired and elapsed < timeout_seconds:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	
	if not signal_fired:
		fail_test("FAIL: Signal '%s' did not fire within %.1f seconds\nContext: Signal awaiting. Why: Signal should fire within timeout. Hint: Check signal emission and async operations." % [signal_name, timeout_seconds])
		return false
	
	return true

func await_timer(timeout_seconds: float) -> void:
	"""Await a timer for specified duration."""
	var elapsed: float = 0.0
	while elapsed < timeout_seconds:
		await get_tree().process_frame
		elapsed += get_process_delta_time()

# ============================================================
# ASSERTION METHODS
# ============================================================

func assert_resource_exists(resource_path: String, context: String = "") -> void:
	"""Assert that a resource exists and can be loaded."""
	var resource: Resource = load(resource_path)
	if resource == null:
		fail_test("FAIL: Resource does not exist: %s\nContext: %s. Why: Resource must exist. Hint: Check file path and resource type." % [resource_path, context])
		return

func assert_script_loads(script_path: String, context: String = "") -> void:
	"""Assert that a script loads without parse errors."""
	var script: GDScript = load(script_path) as GDScript
	if script == null:
		fail_test("FAIL: Script failed to load: %s\nContext: %s. Why: Script must load without parse errors. Hint: Check for syntax errors in %s." % [script_path, context, script_path])
		return
	
	if not script.can_instantiate():
		fail_test("FAIL: Script cannot be instantiated: %s\nContext: %s. Why: Script must be instantiable. Hint: Check _init() method." % [script_path, context])
		return

func assert_singleton_state(singleton_name: String, property: String, expected_value, context: String = "") -> void:
	"""Assert that a singleton has expected state."""
	if not Engine.has_singleton(singleton_name):
		fail_test("FAIL: Singleton '%s' does not exist\nContext: %s. Why: Singleton must be registered. Hint: Check autoload configuration." % [singleton_name, context])
		return
	
	var singleton: Node = Engine.get_singleton(singleton_name)
	if singleton == null:
		fail_test("FAIL: Singleton '%s' is null\nContext: %s. Why: Singleton must be initialized. Hint: Check autoload initialization." % [singleton_name, context])
		return
	
	if not singleton.has(property):
		fail_test("FAIL: Singleton '%s' does not have property '%s'\nContext: %s. Why: Property must exist. Hint: Check singleton script." % [singleton_name, property, context])
		return
	
	var actual_value = singleton.get(property)
	if actual_value != expected_value:
		fail_test("FAIL: Singleton '%s'.%s expected %s, got %s\nContext: %s. Why: State should match expected. Hint: Check property value." % [singleton_name, property, str(expected_value), str(actual_value), context])
		return

func assert_file_written(file_path: String, context: String = "") -> void:
	"""Assert that a file was written (exists on disk)."""
	if not FileAccess.file_exists(file_path):
		fail_test("FAIL: File was not written: %s\nContext: %s. Why: File should exist after write operation. Hint: Check file write permissions and path." % [file_path, context])
		return

func assert_node_exists(node_path: String, context: String = "") -> void:
	"""Assert that a node exists in the scene tree."""
	var node: Node = ui_instance.get_node_or_null(node_path) if ui_instance else null
	if node == null:
		fail_test("FAIL: Node does not exist: %s\nContext: %s. Why: Node must exist in scene. Hint: Check node path and scene structure." % [node_path, context])
		return

func assert_property_set(object: Object, property: String, expected_value, context: String = "") -> void:
	"""Assert that an object's property is set to expected value."""
	if not object.has(property):
		fail_test("FAIL: Object does not have property '%s'\nContext: %s. Why: Property must exist. Hint: Check object type and property name." % [property, context])
		return
	
	var actual_value = object.get(property)
	if actual_value != expected_value:
		fail_test("FAIL: Property '%s' expected %s, got %s\nContext: %s. Why: Property should match expected value. Hint: Check property assignment." % [property, str(expected_value), str(actual_value), context])
		return

# ============================================================
# UI INTERACTION HELPERS
# ============================================================

func find_control_by_name(name: String, parent: Node = null) -> Control:
	"""Find control by exact name (recursive search)."""
	if parent == null:
		parent = ui_instance
	return _find_control_recursive(parent, name, false)

func find_control_by_pattern(pattern: String, parent: Node = null) -> Control:
	"""Find control by name pattern (recursive search)."""
	if parent == null:
		parent = ui_instance
	return _find_control_recursive(parent, pattern, true)

func _find_control_recursive(parent: Node, search: String, use_pattern: bool) -> Control:
	"""Recursively search for control by name or pattern."""
	if not parent:
		return null
	
	if parent is Control:
		var control: Control = parent as Control
		if use_pattern:
			if search.to_lower() in control.name.to_lower():
				return control
		else:
			if control.name == search:
				return control
	
	for child in parent.get_children():
		var found := _find_control_recursive(child, search, use_pattern)
		if found:
			return found
	
	return null

func simulate_button_click(button: Button) -> void:
	"""Safely simulate button click."""
	if button and is_instance_valid(button):
		button.pressed.emit()

func simulate_text_input(line_edit: LineEdit, text: String) -> void:
	"""Safely simulate text input."""
	if line_edit and is_instance_valid(line_edit):
		line_edit.text = text
		line_edit.text_changed.emit(text)

func simulate_slider_drag(slider: HSlider, value: float) -> void:
	"""Safely simulate slider drag."""
	if slider and is_instance_valid(slider):
		slider.value = value
		slider.value_changed.emit(value)

func simulate_spinbox_change(spinbox: SpinBox, value: float) -> void:
	"""Safely simulate spinbox change."""
	if spinbox and is_instance_valid(spinbox):
		spinbox.value = value
		spinbox.value_changed.emit(value)

func simulate_option_selection(option_button: OptionButton, index: int) -> void:
	"""Safely simulate option selection."""
	if option_button and is_instance_valid(option_button):
		if index >= 0 and index < option_button.get_item_count():
			option_button.selected = index
			option_button.item_selected.emit(index)

func simulate_checkbox_toggle(checkbox: CheckBox, pressed: bool) -> void:
	"""Safely simulate checkbox toggle."""
	if checkbox and is_instance_valid(checkbox):
		checkbox.button_pressed = pressed
		checkbox.toggled.emit(pressed)

# ============================================================
# SCENE LOADING HELPERS
# ============================================================

func load_ui_scene(scene_path: String) -> Node:
	"""Load and instantiate a UI scene. Preloads scripts and checks for errors."""
	# Preload scene
	var scene: PackedScene = load(scene_path)
	if scene == null:
		fail_test("FAIL: Failed to load scene: %s\nContext: Scene loading. Why: Scene must load. Hint: Check scene path and file existence." % scene_path)
		return null
	
	# Instantiate scene
	ui_instance = scene.instantiate()
	if ui_instance == null:
		fail_test("FAIL: Failed to instantiate scene: %s\nContext: Scene instantiation. Why: Scene must instantiate. Hint: Check scene structure and node references." % scene_path)
		return null
	
	# Add to test scene
	test_scene.add_child(ui_instance)
	
	# Wait for _ready() to complete
	await_process_frames(3)
	
	# Check for errors during load
	check_for_errors("scene load: %s" % scene_path)
	
	return ui_instance
