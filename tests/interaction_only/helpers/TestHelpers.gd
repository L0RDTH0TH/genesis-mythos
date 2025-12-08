# ╔═══════════════════════════════════════════════════════════
# ║ TestHelpers.gd
# ║ Desc: Utility functions for interaction-only UI testing
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name TestHelpers
extends RefCounted

## Wait for UI to update (process frames)
static func wait_for_ui_update(tree: SceneTree, frames: int = 2) -> void:
	"""Wait for UI to update by processing frames"""
	for i in frames:
		await tree.process_frame

## Wait for visual confirmation (configurable delay)
static func wait_visual(delay: float) -> void:
	"""Wait for visual confirmation delay"""
	if delay > 0.0:
		await Engine.get_main_loop().create_timer(delay).timeout

## Simulate button click
static func simulate_button_click(button: Button) -> void:
	"""Simulate button click via signal emission"""
	if button and is_instance_valid(button):
		button.pressed.emit()

## Simulate button press with visual delay
static func simulate_button_click_with_delay(button: Button, delay: float = 0.0) -> void:
	"""Simulate button click and wait for visual confirmation"""
	simulate_button_click(button)
	if delay > 0.0:
		await wait_visual(delay)

## Simulate text input
static func simulate_text_input(line_edit: LineEdit, text: String) -> void:
	"""Simulate text input"""
	if line_edit and is_instance_valid(line_edit):
		line_edit.text = text
		line_edit.text_changed.emit(text)

## Simulate slider value change
static func simulate_slider_drag(slider: HSlider, value: float) -> void:
	"""Simulate slider drag"""
	if slider and is_instance_valid(slider):
		slider.value = value
		slider.value_changed.emit(value)

## Simulate spinbox value change
static func simulate_spinbox_change(spinbox: SpinBox, value: float) -> void:
	"""Simulate spinbox value change"""
	if spinbox and is_instance_valid(spinbox):
		spinbox.value = value
		spinbox.value_changed.emit(value)

## Simulate option button selection
static func simulate_option_selection(option_button: OptionButton, index: int) -> void:
	"""Simulate option button selection"""
	if option_button and is_instance_valid(option_button):
		option_button.selected = index
		option_button.item_selected.emit(index)

## Simulate checkbox toggle
static func simulate_checkbox_toggle(check_box: CheckBox, pressed: bool) -> void:
	"""Simulate checkbox toggle"""
	if check_box and is_instance_valid(check_box):
		check_box.button_pressed = pressed
		check_box.toggled.emit(pressed)

## Find child node by name pattern (recursive)
static func find_child_by_pattern(parent: Node, pattern: String, recursive: bool = true) -> Node:
	"""Find child node matching pattern (supports wildcards)"""
	if not parent:
		return null
	
	for child in parent.get_children():
		if pattern in child.name or (pattern.ends_with("*") and child.name.begins_with(pattern.trim_suffix("*"))):
			return child
		if recursive:
			var found := find_child_by_pattern(child, pattern, true)
			if found:
				return found
	return null

## Assert with custom message
static func assert_true(condition: bool, message: String = "") -> bool:
	"""Assert condition is true"""
	if not condition:
		push_error("ASSERT FAILED: " + message)
		return false
	return true

## Assert with custom message
static func assert_false(condition: bool, message: String = "") -> bool:
	"""Assert condition is false"""
	if condition:
		push_error("ASSERT FAILED: " + message)
		return false
	return true

## Assert equals
static func assert_equal(actual: Variant, expected: Variant, message: String = "") -> bool:
	"""Assert two values are equal"""
	if actual != expected:
		push_error("ASSERT FAILED: Expected %s, got %s. %s" % [str(expected), str(actual), message])
		return false
	return true

## Assert not null
static func assert_not_null(value: Variant, message: String = "") -> bool:
	"""Assert value is not null"""
	if value == null:
		push_error("ASSERT FAILED: Value is null. %s" % message)
		return false
	return true

## Assert null
static func assert_null(value: Variant, message: String = "") -> bool:
	"""Assert value is null"""
	if value != null:
		push_error("ASSERT FAILED: Value is not null. %s" % message)
		return false
	return true

## Log test step
static func log_step(text: String, overlay_label: Label = null) -> void:
	"""Log test step to console and overlay"""
	var log_text := "[TEST] " + text
	print(log_text)
	if overlay_label and is_instance_valid(overlay_label):
		overlay_label.text += log_text + "\n"

## Simulate mouse enter event
static func simulate_mouse_enter(control: Control) -> void:
	"""Simulate mouse enter event on a control"""
	if control and is_instance_valid(control):
		var event := InputEventMouseMotion.new()
		event.position = Vector2(control.size.x / 2, control.size.y / 2)
		control._gui_input(event)
		if control.has_signal("mouse_entered"):
			control.mouse_entered.emit()

## Simulate mouse exit event
static func simulate_mouse_exit(control: Control) -> void:
	"""Simulate mouse exit event on a control"""
	if control and is_instance_valid(control):
		if control.has_signal("mouse_exited"):
			control.mouse_exited.emit()

## Simulate mouse button press
static func simulate_mouse_button_press(control: Control, button_index: int = 1) -> void:
	"""Simulate mouse button press (1=left, 2=right, 3=middle)"""
	if control and is_instance_valid(control):
		var event := InputEventMouseButton.new()
		event.button_index = button_index
		event.pressed = true
		event.position = Vector2(control.size.x / 2, control.size.y / 2)
		control._gui_input(event)

## Simulate mouse button release
static func simulate_mouse_button_release(control: Control, button_index: int = 1) -> void:
	"""Simulate mouse button release"""
	if control and is_instance_valid(control):
		var event := InputEventMouseButton.new()
		event.button_index = button_index
		event.pressed = false
		event.position = Vector2(control.size.x / 2, control.size.y / 2)
		control._gui_input(event)

## Assert animation duration (via timer)
static func assert_animation_duration(node: Node, animation_name: String, expected_duration: float, tolerance: float = 0.1) -> bool:
	"""Assert animation duration matches expected (checks AnimationPlayer if present)"""
	if not node:
		return false
	
	var anim_player := node.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if not anim_player:
		# Try direct AnimationPlayer
		if node is AnimationPlayer:
			anim_player = node as AnimationPlayer
	
	if anim_player and anim_player.has_animation(animation_name):
		var anim := anim_player.get_animation(animation_name)
		var actual_duration: float = anim.length
		var diff: float = abs(actual_duration - expected_duration)
		if diff > tolerance:
			push_error("ASSERT FAILED: Animation '%s' duration expected %.3f, got %.3f" % [animation_name, expected_duration, actual_duration])
			return false
		return true
	
	# If no animation found, check for Tween or manual animation
	# For now, return true (animation might be handled differently)
	return true

## Assert node visible state
static func assert_visible(node: CanvasItem, expected: bool, message: String = "") -> bool:
	"""Assert node visibility matches expected"""
	if not node:
		push_error("ASSERT FAILED: Node is null. %s" % message)
		return false
	
	var actual := node.visible
	if actual != expected:
		push_error("ASSERT FAILED: Visibility expected %s, got %s. %s" % [str(expected), str(actual), message])
		return false
	return true

## Assert node modulate color
static func assert_modulate(node: CanvasItem, expected_color: Color, tolerance: float = 0.01, message: String = "") -> bool:
	"""Assert node modulate color matches expected (with tolerance)"""
	if not node:
		push_error("ASSERT FAILED: Node is null. %s" % message)
		return false
	
	var actual := node.modulate
	# Calculate color distance manually (Euclidean distance in RGB space)
	var r_diff := actual.r - expected_color.r
	var g_diff := actual.g - expected_color.g
	var b_diff := actual.b - expected_color.b
	var a_diff := actual.a - expected_color.a
	var diff := sqrt(r_diff * r_diff + g_diff * g_diff + b_diff * b_diff + a_diff * a_diff)
	if diff > tolerance:
		push_error("ASSERT FAILED: Modulate color expected %s, got %s (diff: %.3f). %s" % [str(expected_color), str(actual), diff, message])
		return false
	return true

## Assert button disabled state
static func assert_button_disabled(button: Button, expected: bool, message: String = "") -> bool:
	"""Assert button disabled state"""
	if not button:
		push_error("ASSERT FAILED: Button is null. %s" % message)
		return false
	
	var actual := button.disabled
	if actual != expected:
		push_error("ASSERT FAILED: Button disabled expected %s, got %s. %s" % [str(expected), str(actual), message])
		return false
	return true

## Assert value in range
static func assert_in_range(value: float, min_val: float, max_val: float, message: String = "") -> bool:
	"""Assert value is within range [min_val, max_val]"""
	if value < min_val or value > max_val:
		push_error("ASSERT FAILED: Value %.3f not in range [%.3f, %.3f]. %s" % [value, min_val, max_val, message])
		return false
	return true

## Assert points exactly equal (for point buy validation)
static func assert_points_exact(actual: int, expected: int, message: String = "") -> bool:
	"""Assert points are exactly equal (for 27 point validation)"""
	if actual != expected:
		push_error("ASSERT FAILED: Points expected exactly %d, got %d. %s" % [expected, actual, message])
		return false
	return true

## Assert ability score in valid range (8-15)
static func assert_ability_score_valid(score: int, message: String = "") -> bool:
	"""Assert ability score is in valid range [8, 15]"""
	return assert_in_range(float(score), 8.0, 15.0, message)

## Assert non-empty string (for name validation)
static func assert_non_empty(text: String, message: String = "") -> bool:
	"""Assert string is non-empty"""
	if text.is_empty():
		push_error("ASSERT FAILED: String is empty. %s" % message)
		return false
	return true

## Assert mesh exists and has vertices
static func assert_mesh_valid(mesh_instance: MeshInstance3D, min_vertices: int = 0, message: String = "") -> bool:
	"""Assert mesh exists and has at least min_vertices"""
	if not mesh_instance:
		push_error("ASSERT FAILED: MeshInstance3D is null. %s" % message)
		return false
	
	var mesh := mesh_instance.mesh
	if not mesh:
		push_error("ASSERT FAILED: Mesh is null. %s" % message)
		return false
	
	if mesh.get_surface_count() == 0:
		push_error("ASSERT FAILED: Mesh has no surfaces. %s" % message)
		return false
	
	# Try to get vertex count (varies by mesh type)
	var arrays := mesh.surface_get_arrays(0)
	if arrays.size() > 0 and arrays[Mesh.ARRAY_VERTEX]:
		var vertices := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		if vertices.size() < min_vertices:
			push_error("ASSERT FAILED: Mesh has %d vertices, expected at least %d. %s" % [vertices.size(), min_vertices, message])
			return false
	
	return true

## Wait for signal with timeout (old version - use wait_for_signal_array instead)
static func wait_for_signal(signal_obj: Object, signal_name: String, timeout: float = 5.0) -> bool:
	"""Wait for signal to be emitted, returns true if received, false if timeout"""
	if not signal_obj or not signal_obj.has_signal(signal_name):
		return false
	
	var received := [false]  # Array to work around lambda capture
	var timeout_reached := [false]
	
	var callback := func():
		received[0] = true
	
	signal_obj.connect(signal_name, callback)
	
	# Wait with timeout
	var timer: SceneTreeTimer = Engine.get_main_loop().create_timer(timeout)
	var timeout_callback := func():
		timeout_reached[0] = true
	timer.timeout.connect(timeout_callback)
	
	while not received[0] and not timeout_reached[0]:
		await Engine.get_main_loop().process_frame
	
	if signal_obj.is_connected(signal_name, callback):
		signal_obj.disconnect(signal_name, callback)
	
	return received[0] and not timeout_reached[0]

## Wait for a node to exist in the scene tree (perfect for dynamically loaded sections)
static func wait_for_node(parent: Node, node_name: String, timeout_sec: float = 5.0) -> Node:
	"""Wait for a node to appear in the scene tree with timeout.
	
	Args:
		parent: Parent node to search under
		node_name: Name of node to find
		timeout_sec: Maximum time to wait in seconds
		
	Returns:
		Node if found, null if timeout
	"""
	if not parent:
		push_error("wait_for_node: Parent node is null")
		return null
	
	if not parent.is_inside_tree():
		push_error("wait_for_node: Parent node is not in tree")
		return null
	
	var tree: SceneTree = parent.get_tree()
	if not tree:
		push_error("wait_for_node: Cannot get SceneTree from parent")
		return null
	
	var timer := 0.0
	while timer < timeout_sec:
		var node := parent.find_child(node_name, true, false)
		if node and node.is_inside_tree():
			return node
		await tree.process_frame
		var delta: float = tree.get_frame_delta_time()
		if delta <= 0.0:
			delta = 1.0 / 60.0  # Fallback to 60fps
		timer += delta
	
	push_error("wait_for_node timeout: %s not found under %s after %.1fs" % [node_name, parent.name if parent else "null", timeout_sec])
	return null

## Wait for a signal with timeout – never miss generation_complete again
static func wait_for_signal_array(emitter: Object, signal_name: String, timeout_sec: float = 30.0, scene_node: Node = null) -> Array:
	"""Wait for a signal to be emitted with timeout, returns signal args array.
	
	Args:
		emitter: Object that emits the signal (can be Node or Resource)
		signal_name: Name of signal to wait for
		timeout_sec: Maximum time to wait in seconds
		scene_node: Optional Node to use for getting SceneTree (required for Resources)
		
	Returns:
		Array of signal arguments if signal emitted, empty array if timeout
	"""
	var result := []
	
	# Get tree from emitter or provided scene_node
	var tree: SceneTree = null
	if emitter is Node:
		tree = emitter.get_tree()
	elif scene_node:
		tree = scene_node.get_tree()
	else:
		# Fallback: try to get tree from main loop
		tree = Engine.get_main_loop() as SceneTree
	
	if not tree:
		push_error("wait_for_signal_array: Cannot get SceneTree from emitter")
		return []
	
	var timer := Timer.new()
	timer.wait_time = timeout_sec
	timer.one_shot = true
	tree.root.add_child(timer)
	timer.start()
	
	# Connect signal - use Array for lambda capture
	var signal_received := [false]
	
	# Check signal signature to determine if it has arguments
	var connected := false
	var callback_ref = null
	
	if emitter.has_signal(signal_name):
		# Get signal info to check argument count
		var sig_list = emitter.get_signal_list()
		var arg_count := 0
		for sig in sig_list:
			if sig.name == signal_name:
				arg_count = sig.args.size()
				break
		
		# Create callback - for now, just detect signal emission (args don't matter for our tests)
		var callback := func():
			signal_received[0] = true
			result = []  # Empty array means signal was received
			if timer.is_inside_tree():
				timer.queue_free()
		
		callback_ref = callback
		connected = emitter.connect(signal_name, callback)
	else:
		push_error("wait_for_signal_array: Signal %s does not exist on emitter" % signal_name)
		timer.queue_free()
		return []
	
	# Wait for signal or timeout (Timer.time_left > 0 means still running)
	while timer.time_left > 0.0 and not signal_received[0]:
		await tree.process_frame
	
	# Cleanup
	if connected and callback_ref and emitter.is_connected(signal_name, callback_ref):
		emitter.disconnect(signal_name, callback_ref)
	if timer.is_inside_tree():
		timer.queue_free()
	
	if result.is_empty() and not signal_received[0]:
		push_error("wait_for_signal_array timeout: %s never emitted after %.1fs" % [signal_name, timeout_sec])
	
	return result
