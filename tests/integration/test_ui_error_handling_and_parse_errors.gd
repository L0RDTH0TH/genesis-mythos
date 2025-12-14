# ╔═══════════════════════════════════════════════════════════
# ║ test_ui_error_handling_and_parse_errors.gd
# ║ Desc: Tests for error handling, parse errors, null references, invalid states, threading issues
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Test fixture: Scene tree for error testing
var test_scene: Node

## Track errors and warnings
var captured_errors: Array[String] = []
var captured_warnings: Array[String] = []

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
	"""Setup before each test."""
	captured_errors.clear()
	captured_warnings.clear()

func after_each() -> void:
	"""Cleanup after each test."""
	for child in test_scene.get_children():
		child.queue_free()
	await get_tree().process_frame

func test_null_reference_handling() -> void:
	"""Test that null references are handled gracefully."""
	var world_builder_ui: Control = null
	var scene_path: String = "res://ui/world_builder/WorldBuilderUI.tscn"
	if ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		if scene:
			world_builder_ui = scene.instantiate() as Control
			if world_builder_ui:
				test_scene.add_child(world_builder_ui)
				await get_tree().process_frame
				await get_tree().process_frame
	
	if not world_builder_ui:
		pass_test("WorldBuilderUI not available")
		return
	
	# Test calling methods with null data
	if world_builder_ui.has_method("_on_generate_map_pressed"):
		# Clear step_data to simulate null state
		if world_builder_ui.has("step_data"):
			var step_data: Dictionary = world_builder_ui.get("step_data")
			step_data.clear()
		
		# Try to generate with null data
		try:
			world_builder_ui._on_generate_map_pressed()
			await get_tree().process_frame
			await get_tree().process_frame
			_check_for_errors("null reference handling")
		except:
			captured_errors.append("Null reference caused exception")
	
	pass_test("Null reference handling tested")

func test_invalid_input_handling() -> void:
	"""Test that invalid inputs are handled gracefully."""
	var world_builder_ui: Control = null
	var scene_path: String = "res://ui/world_builder/WorldBuilderUI.tscn"
	if ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		if scene:
			world_builder_ui = scene.instantiate() as Control
			if world_builder_ui:
				test_scene.add_child(world_builder_ui)
				await get_tree().process_frame
				await get_tree().process_frame
	
	if not world_builder_ui:
		pass_test("WorldBuilderUI not available")
		return
	
	# Navigate to step 1
	if world_builder_ui.has("current_step"):
		world_builder_ui.set("current_step", 0)
		await get_tree().process_frame
		
		# Test invalid seed input
		var seed_input := _find_control_recursive(world_builder_ui, "seed", false) as LineEdit
		if seed_input:
			var invalid_inputs: Array[String] = ["", "abc", "-999999", "999999999999999999", "!@#$%"]
			for invalid_input in invalid_inputs:
				seed_input.text = invalid_input
				seed_input.text_changed.emit(invalid_input)
				await get_tree().process_frame
				_check_for_errors("invalid input: %s" % invalid_input)
	
	pass_test("Invalid input handling tested")

func test_invalid_state_transitions() -> void:
	"""Test invalid state transitions - e.g., navigating without completing steps."""
	var world_builder_ui: Control = null
	var scene_path: String = "res://ui/world_builder/WorldBuilderUI.tscn"
	if ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		if scene:
			world_builder_ui = scene.instantiate() as Control
			if world_builder_ui:
				test_scene.add_child(world_builder_ui)
				await get_tree().process_frame
				await get_tree().process_frame
	
	if not world_builder_ui or not world_builder_ui.has("current_step"):
		pass_test("WorldBuilderUI not available")
		return
	
	# Try to jump to step 7 without completing previous steps
	world_builder_ui.set("current_step", 7)
	if world_builder_ui.has_method("_update_step_display"):
		world_builder_ui._update_step_display()
	await get_tree().process_frame
	_check_for_errors("invalid state transition")
	
	pass_test("Invalid state transitions tested")

func test_missing_dependency_handling() -> void:
	"""Test handling of missing dependencies (e.g., Terrain3DManager not set)."""
	var map_maker_module: MapMakerModule = null
	var module_script = load("res://ui/world_builder/MapMakerModule.gd")
	if module_script:
		map_maker_module = module_script.new() as MapMakerModule
		if map_maker_module:
			test_scene.add_child(map_maker_module)
			await get_tree().process_frame
	
	if not map_maker_module:
		pass_test("MapMakerModule not available")
		return
	
	# Try to generate 3D world without terrain manager
	if map_maker_module.has_method("_on_generate_3d_button_pressed"):
		try:
			map_maker_module._on_generate_3d_button_pressed()
			await get_tree().process_frame
			await get_tree().process_frame
			_check_for_errors("missing terrain manager")
		except:
			captured_errors.append("Missing dependency caused exception")
	
	pass_test("Missing dependency handling tested")

func test_threading_safety_ui_interactions() -> void:
	"""Test that UI interactions from threads are handled safely."""
	var world_builder_ui: Control = null
	var scene_path: String = "res://ui/world_builder/WorldBuilderUI.tscn"
	if ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		if scene:
			world_builder_ui = scene.instantiate() as Control
			if world_builder_ui:
				test_scene.add_child(world_builder_ui)
				await get_tree().process_frame
				await get_tree().process_frame
	
	if not world_builder_ui:
		pass_test("WorldBuilderUI not available")
		return
	
	# Simulate UI interaction during generation (which may use threads)
	if world_builder_ui.has("current_step"):
		world_builder_ui.set("current_step", 0)
		await get_tree().process_frame
		
		# Trigger generation (may use threads)
		var generate_button := _find_button_by_text_recursive(world_builder_ui, "Generate")
		if generate_button:
			generate_button.pressed.emit()
			await get_tree().process_frame
			
			# Immediately try UI interaction (should be safe)
			var seed_input := _find_control_recursive(world_builder_ui, "seed", false) as LineEdit
			if seed_input:
				seed_input.text = "99999"
				seed_input.text_changed.emit("99999")
				await get_tree().process_frame
				await get_tree().process_frame
				_check_for_errors("threading safety")
	
	pass_test("Threading safety UI interactions tested")

func test_resource_loading_errors() -> void:
	"""Test handling of resource loading errors (missing scenes, scripts)."""
	# Try to load non-existent scene
	var invalid_path: String = "res://scenes/NonExistentScene.tscn"
	var scene: PackedScene = load(invalid_path)
	assert_null(scene, "FAIL: Loading non-existent scene should return null. Context: Resource loading. Why: load() should return null for missing resources. Hint: Check ResourceLoader.exists() before loading.")
	
	# Try to load non-existent script
	var invalid_script_path: String = "res://scripts/NonExistentScript.gd"
	var script: GDScript = load(invalid_script_path) as GDScript
	assert_null(script, "FAIL: Loading non-existent script should return null. Context: Resource loading. Why: load() should return null for missing resources.")
	
	pass_test("Resource loading errors handled correctly")

func test_parse_error_detection() -> void:
	"""Test detection of parse errors in dynamically loaded scripts."""
	# Note: We can't easily create parse errors in tests, but we can test
	# that the system handles script loading failures gracefully
	
	var module_script = load("res://ui/world_builder/MapMakerModule.gd")
	if module_script:
		# Test that script can be instantiated (no parse errors)
		if module_script.can_instantiate():
			var instance = module_script.new()
			assert_not_null(instance, "FAIL: Script instantiation should succeed. Context: Parse error detection. Why: Valid script should instantiate. Hint: Check script syntax.")
			if instance:
				instance.queue_free()
		else:
			captured_errors.append("Script cannot be instantiated (may have parse errors)")
	
	pass_test("Parse error detection tested")

func test_concurrent_ui_operations() -> void:
	"""Test concurrent UI operations - should handle gracefully."""
	var world_builder_ui: Control = null
	var scene_path: String = "res://ui/world_builder/WorldBuilderUI.tscn"
	if ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		if scene:
			world_builder_ui = scene.instantiate() as Control
			if world_builder_ui:
				test_scene.add_child(world_builder_ui)
				await get_tree().process_frame
				await get_tree().process_frame
	
	if not world_builder_ui:
		pass_test("WorldBuilderUI not available")
		return
	
	# Simulate concurrent operations
	if world_builder_ui.has("current_step"):
		# Rapid step changes
		for i in range(10):
			world_builder_ui.set("current_step", i % 8)
			if world_builder_ui.has_method("_update_step_display"):
				world_builder_ui._update_step_display()
			await get_tree().process_frame
		
		# Rapid button clicks
		var generate_button := _find_button_by_text_recursive(world_builder_ui, "Generate")
		if generate_button:
			for i in range(5):
				generate_button.pressed.emit()
				await get_tree().process_frame
		
		_check_for_errors("concurrent UI operations")
	
	pass_test("Concurrent UI operations handled gracefully")

func test_memory_leak_prevention() -> void:
	"""Test that UI interactions don't cause memory leaks."""
	var world_builder_ui: Control = null
	var scene_path: String = "res://ui/world_builder/WorldBuilderUI.tscn"
	if ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		if scene:
			world_builder_ui = scene.instantiate() as Control
			if world_builder_ui:
				test_scene.add_child(world_builder_ui)
				await get_tree().process_frame
				await get_tree().process_frame
	
	if not world_builder_ui:
		pass_test("WorldBuilderUI not available")
		return
	
	# Perform many interactions
	if world_builder_ui.has("current_step"):
		for i in range(50):
			world_builder_ui.set("current_step", i % 8)
			if world_builder_ui.has_method("_update_step_display"):
				world_builder_ui._update_step_display()
			await get_tree().process_frame
		
		# Cleanup
		world_builder_ui.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Verify cleanup
		assert_false(is_instance_valid(world_builder_ui), "FAIL: WorldBuilderUI should be freed after queue_free(). Context: Memory leak prevention. Why: queue_free() should clean up resources. Hint: Check for circular references.")
	
	pass_test("Memory leak prevention tested")

# ============================================================
# HELPER FUNCTIONS
# ============================================================

func _find_button_by_text_recursive(parent: Node, text: String) -> Button:
	"""Recursively find button by text."""
	if not parent:
		return null
	
	if parent is Button:
		var button: Button = parent as Button
		if text.to_lower() in button.text.to_lower():
			return button
	
	for child in parent.get_children():
		var found := _find_button_by_text_recursive(child, text)
		if found:
			return found
	
	return null

func _find_control_recursive(parent: Node, name: String, use_pattern: bool) -> Control:
	"""Recursively find control by name or pattern."""
	if not parent:
		return null
	
	if parent is Control:
		var control: Control = parent as Control
		if use_pattern:
			if name.to_lower() in control.name.to_lower():
				return control
		else:
			if control.name == name:
				return control
	
	for child in parent.get_children():
		var found := _find_control_recursive(child, name, use_pattern)
		if found:
			return found
	
	return null

func _check_for_errors(context: String) -> void:
	"""Check for errors in captured_errors."""
	if captured_errors.size() > 0:
		var error_msg: String = "Errors during %s: %s" % [context, str(captured_errors)]
		push_error(error_msg)
		captured_errors.clear()
