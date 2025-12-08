# ╔═══════════════════════════════════════════════════════════
# ║ AsyncHelpers.gd
# ║ Desc: Bulletproof async waiting utilities for interaction tests
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name AsyncHelpers
extends RefCounted

# Wait for a node to exist in the scene tree (perfect for dynamically loaded sections)
static func wait_for_node(parent: Node, node_name: String, timeout_sec: float = 5.0) -> Node:
	"""Wait for a node to appear in the scene tree with timeout.
	
	Args:
		parent: Parent node to search under
		node_name: Name of node to find
		timeout_sec: Maximum time to wait in seconds
		
	Returns:
		Node if found, null if timeout
	"""
	var timer := 0.0
	while timer < timeout_sec:
		var node := parent.find_child(node_name, true, false)
		if node and node.is_inside_tree():
			return node
		await parent.get_tree().process_frame
		timer += parent.get_tree().get_physics_frame_delta_time() if Engine.is_in_physics_frame() else parent.get_tree().get_frame_delta_time()
	
	push_error("wait_for_node timeout: %s not found under %s" % [node_name, parent])
	return null

# Wait for a signal with timeout – never miss generation_complete again
static func wait_for_signal(emitter: Object, signal_name: String, timeout_sec: float = 30.0, scene_node: Node = null) -> Array:
	"""Wait for a signal to be emitted with timeout.
	
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
		push_error("wait_for_signal: Cannot get SceneTree from emitter")
		return []
	
	var timer := Timer.new()
	timer.wait_time = timeout_sec
	timer.one_shot = true
	tree.root.add_child(timer)
	timer.start()
	
	# Connect signal
	var signal_received := false
	var callback := func(args...):
		result = args
		signal_received = true
		if timer.is_inside_tree():
			timer.queue_free()
	
	var connected := false
	if emitter.has_signal(signal_name):
		connected = emitter.connect(signal_name, callback)
	else:
		push_error("wait_for_signal: Signal %s does not exist on emitter" % signal_name)
		timer.queue_free()
		return []
	
	# Wait for signal or timeout
	while timer.is_running() and not signal_received:
		await tree.process_frame
	
	# Cleanup
	if connected and emitter.is_connected(signal_name, callback):
		emitter.disconnect(signal_name, callback)
	if timer.is_inside_tree():
		timer.queue_free()
	
	if result.is_empty():
		push_error("wait_for_signal timeout: %s never emitted" % signal_name)
	
	return result
