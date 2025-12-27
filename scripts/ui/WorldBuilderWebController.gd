# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderWebController.gd
# ║ Desc: Handles WebView for World Builder UI wizard with Alpine.js
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name WorldBuilderWebController
extends Control

## Reference to the WebView node
@onready var web_view: WebView = $WebView

## Reference to WorldBuilderUI for accessing generation logic (optional, can be set by parent)
var world_builder_ui: WorldBuilderUI = null

## Reference to WorldBuilderAzgaar for generation (can be found in scene tree)
var world_builder_azgaar: Node = null

## Current step index (synced with WebView)
var current_step: int = 0

## Current parameters dictionary (synced with WebView)
var current_params: Dictionary = {}

## Current seed value
var current_seed: int = 12345

## Current archetype name
var current_archetype: String = "High Fantasy"

## Step definitions loaded from JSON
var step_definitions: Dictionary = {}
const STEP_PARAMETERS_PATH: String = "res://data/config/azgaar_step_parameters.json"

## Archetype presets (same as WorldBuilderUI)
const ARCHETYPES: Dictionary = {
	"High Fantasy": {"points": 800000, "heightExponent": 1.2, "allowErosion": true, "plateCount": 8, "burgs": 500, "precip": 0.6},
	"Low Fantasy": {"points": 600000, "heightExponent": 0.8, "allowErosion": true, "plateCount": 5, "burgs": 200, "precip": 0.5},
	"Dark Fantasy": {"points": 400000, "heightExponent": 1.5, "allowErosion": false, "plateCount": 12, "burgs": 100, "precip": 0.8},
	"Realistic": {"points": 1000000, "heightExponent": 1.0, "allowErosion": true, "plateCount": 7, "burgs": 800},
	"Custom": {}
}


func _ready() -> void:
	"""Initialize the WebView and load the World Builder HTML."""
	MythosLogger.info("WorldBuilderWebController", "_ready() called")
	
	if not web_view:
		MythosLogger.error("WorldBuilderWebController", "WebView node not found!")
		return
	
	# Load step definitions from JSON (synchronous, but small file)
	_load_step_definitions()
	
	# Connect IPC message signal immediately (non-blocking)
	if web_view.has_signal("ipc_message"):
		web_view.ipc_message.connect(_on_ipc_message)
		MythosLogger.info("WorldBuilderWebController", "Connected to WebView IPC message signal")
	else:
		MythosLogger.warn("WorldBuilderWebController", "WebView does not have ipc_message signal")
	
	# Try to find WorldBuilderAzgaar in scene tree (for generation)
	_find_azgaar_controller()
	
	# Defer WebView load to allow UI to render first (reduces perceived lag)
	call_deferred("_deferred_load_web_ui")
	
	# Ensure WebView matches initial viewport size
	_update_webview_size()

func _deferred_load_web_ui() -> void:
	"""Deferred WebView load to allow overlay to render first."""
	var tree = get_tree()
	if not tree:
		MythosLogger.warn("WorldBuilderWebController", "Node not in tree, cannot load WebView")
		return
	
	# Show progress for load sequence
	ProgressDialogWeb.show_progress("Loading World Builder", "Initializing WebView...")
	await tree.process_frame
	
	# Load the World Builder HTML file
	var html_url: String = "res://web_ui/world_builder/index.html"
	web_view.load_url(html_url)
	MythosLogger.info("WorldBuilderWebController", "Loaded World Builder HTML (deferred)", {"url": html_url})
	ProgressDialogWeb.update_progress(0.2, "Loading HTML...")
	await tree.process_frame
	
	# Wait for page to load (yield multiple frames for WebView initialization)
	# Use process_frame yields instead of timer for better precision
	for i in range(30):  # ~0.5 seconds at 60 FPS
		await tree.process_frame
		if i == 10:
			ProgressDialogWeb.update_progress(0.4, "Initializing Alpine.js...")
		elif i == 20:
			ProgressDialogWeb.update_progress(0.6, "Preparing UI...")
	
	# Send initial data
	ProgressDialogWeb.update_progress(0.8, "Loading step definitions...")
	await tree.process_frame
	_send_step_definitions()
	await tree.process_frame
	
	ProgressDialogWeb.update_progress(0.9, "Loading archetypes...")
	await tree.process_frame
	_send_archetypes()
	await tree.process_frame
	
	ProgressDialogWeb.update_progress(1.0, "Ready")
	await tree.process_frame
	ProgressDialogWeb.hide_progress()


func _find_azgaar_controller() -> void:
	"""Try to find WorldBuilderAzgaar controller in scene tree."""
	# Look for nodes with WorldBuilderAzgaar script
	var root: Node = get_tree().root
	var azgaar_nodes: Array[Node] = []
	_find_nodes_with_script(root, azgaar_nodes)
	
	if azgaar_nodes.size() > 0:
		world_builder_azgaar = azgaar_nodes[0]
		MythosLogger.info("WorldBuilderWebController", "Found WorldBuilderAzgaar controller", {"path": world_builder_azgaar.get_path()})
	else:
		MythosLogger.warn("WorldBuilderWebController", "WorldBuilderAzgaar controller not found in scene tree")


func _find_nodes_with_script(node: Node, results: Array) -> void:
	"""Recursively find nodes with WorldBuilderAzgaar script."""
	if node.get_script():
		var script_path: String = node.get_script().resource_path
		if "WorldBuilderAzgaar" in script_path:
			results.append(node)
	
	for child in node.get_children():
		_find_nodes_with_script(child, results)


func _notification(what: int) -> void:
	"""Handle window resize events for responsive UI."""
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_update_webview_size()


func _update_webview_size() -> void:
	"""Force WebView to match viewport size."""
	if web_view:
		var viewport_size: Vector2 = get_viewport().get_visible_rect().size
		web_view.size = viewport_size
		MythosLogger.debug("WorldBuilderWebController", "WebView resized to viewport", {"size": viewport_size})


func _load_step_definitions() -> void:
	"""Load step definitions from JSON file."""
	var file: FileAccess = FileAccess.open(STEP_PARAMETERS_PATH, FileAccess.READ)
	if not file:
		MythosLogger.error("WorldBuilderWebController", "Failed to load step parameters", {"path": STEP_PARAMETERS_PATH})
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		MythosLogger.error("WorldBuilderWebController", "Failed to parse step parameters JSON", {"error": parse_result})
		return
	
	var data: Dictionary = json.data
	if not data.has("steps") or not data.steps is Array:
		MythosLogger.error("WorldBuilderWebController", "Invalid step parameters JSON structure")
		return
	
	# Store step definitions
	step_definitions = data
	MythosLogger.info("WorldBuilderWebController", "Loaded step definitions", {"count": data.steps.size()})


func _send_step_definitions() -> void:
	"""Send step definitions to WebView via IPC."""
	if not web_view or step_definitions.is_empty():
		return
	
	# Send step definitions as JSON string
	var json_string: String = JSON.stringify(step_definitions)
	var script: String = """
		// Store in pending data if Alpine not ready, otherwise use instance
		if (window.worldBuilderInstance) {
			window.worldBuilderInstance.steps = %s.steps || [];
			// Chunked initialization: only init params for current step (step 0)
			if (window.worldBuilderInstance._initializeParamsForStep) {
				window.worldBuilderInstance._initializeParamsForStep(0);
			}
		} else {
			// Alpine not ready yet, store for lazy init
			window._pendingStepsData = %s;
		}
	""" % [json_string, json_string]
	
	if web_view.has_method("execute_js"):
		web_view.execute_js(script)
		MythosLogger.info("WorldBuilderWebController", "Sent step definitions to WebView")
	elif web_view.has_method("eval"):
		web_view.eval(script)
		MythosLogger.info("WorldBuilderWebController", "Sent step definitions to WebView via eval")


func _send_archetypes() -> void:
	"""Send archetype names to WebView."""
	if not web_view:
		return
	
	var archetype_names: Array[String] = []
	for archetype_name in ARCHETYPES.keys():
		archetype_names.append(archetype_name)
	
	var script: String = """
		if (window.worldBuilderInstance) {
			window.worldBuilderInstance.archetypeNames = %s;
		}
	""" % JSON.stringify(archetype_names)
	
	if web_view.has_method("execute_js"):
		web_view.execute_js(script)
	elif web_view.has_method("eval"):
		web_view.eval(script)


func _on_ipc_message(message: String) -> void:
	"""Handle IPC messages from WebView."""
	MythosLogger.debug("WorldBuilderWebController", "Received IPC message from WebView", {"message": message})
	
	var json = JSON.new()
	var parse_result = json.parse(message)
	if parse_result != OK:
		MythosLogger.error("WorldBuilderWebController", "Failed to parse IPC message JSON", {"error": json.get_error_message()})
		return
	
	var data = json.data
	if not data is Dictionary:
		MythosLogger.warn("WorldBuilderWebController", "IPC message data is not a Dictionary")
		return
	
	# Bridge.js sends messages as {type: "message_type", data: {...}, timestamp: ...}
	var message_type: String = data.get("type", "")
	var message_data: Dictionary = data.get("data", {})
	
	# Fallback: if no type field, assume flat structure
	if message_type.is_empty() and data.size() > 0:
		var keys: Array = data.keys()
		message_type = keys[0]
		message_data = data
	
	match message_type:
		"set_step":
			_handle_set_step(message_data)
		"load_archetype":
			_handle_load_archetype(message_data)
		"set_seed":
			_handle_set_seed(message_data)
		"update_param":
			_handle_update_param(message_data)
		"generate":
			_handle_generate(message_data)
		"request_data":
			_handle_request_data(message_data)
		_:
			MythosLogger.warn("WorldBuilderWebController", "Unknown IPC message type", {"type": message_type, "data": data})


func _handle_set_step(data: Dictionary) -> void:
	"""Handle set_step message from WebView."""
	var step: int = data.get("step", 0)
	if step >= 0 and step < 8:
		current_step = step
		MythosLogger.info("WorldBuilderWebController", "Step changed", {"step": step})


func _handle_load_archetype(data: Dictionary) -> void:
	"""Handle load_archetype message from WebView."""
	var archetype_name: String = data.get("archetype", "High Fantasy")
	current_archetype = archetype_name
	
	var preset: Dictionary = ARCHETYPES.get(archetype_name, {}).duplicate()
	if not preset.is_empty():
		# Apply hardware clamping for points parameter
		if preset.has("points"):
			preset["points"] = UIConstants.get_clamped_points(preset["points"])
		
		# Merge preset params into current_params
		for key in preset.keys():
			current_params[key] = preset[key]
		
		# Send params update to WebView
		_send_params_update()
		MythosLogger.info("WorldBuilderWebController", "Loaded archetype preset", {"archetype": archetype_name, "params": preset})


func _handle_set_seed(data: Dictionary) -> void:
	"""Handle set_seed message from WebView."""
	current_seed = int(data.get("seed", 12345))
	MythosLogger.debug("WorldBuilderWebController", "Seed changed", {"seed": current_seed})


func _handle_update_param(data: Dictionary) -> void:
	"""Handle update_param message from WebView."""
	var azgaar_key: String = data.get("azgaar_key", "")
	var value = data.get("value")
	
	if not azgaar_key.is_empty():
		current_params[azgaar_key] = value
		MythosLogger.debug("WorldBuilderWebController", "Parameter updated", {"key": azgaar_key, "value": value})


func _handle_generate(data: Dictionary) -> void:
	"""Handle generate message from WebView."""
	var params: Dictionary = data.get("params", {})
	current_params.merge(params)
	
	# Ensure seed is set
	current_params["optionsSeed"] = current_seed
	
	MythosLogger.info("WorldBuilderWebController", "Generation requested", {"params": current_params})
	
	# Trigger generation via WorldBuilderAzgaar (prefer direct reference, fallback to WorldBuilderUI)
	var azgaar_controller: Node = null
	if world_builder_azgaar:
		azgaar_controller = world_builder_azgaar
	elif world_builder_ui and world_builder_ui.world_builder_azgaar:
		azgaar_controller = world_builder_ui.world_builder_azgaar
	
	if azgaar_controller and azgaar_controller.has_method("trigger_generation_with_options"):
		# Connect signals for progress updates
		if not azgaar_controller.generation_complete.is_connected(_on_generation_complete):
			azgaar_controller.generation_complete.connect(_on_generation_complete)
		if not azgaar_controller.generation_failed.is_connected(_on_generation_failed):
			azgaar_controller.generation_failed.connect(_on_generation_failed)
		
		send_progress_update(10.0, "Syncing parameters...", true)
		azgaar_controller.trigger_generation_with_options(current_params, true)
		send_progress_update(40.0, "Generating map...", true)
	else:
		MythosLogger.error("WorldBuilderWebController", "Azgaar controller not available for generation")
		send_progress_update(0.0, "Error: Azgaar controller not found", false)


func _on_generation_complete() -> void:
	"""Handle generation complete signal."""
	send_progress_update(100.0, "Generation complete!", false)
	MythosLogger.info("WorldBuilderWebController", "Generation complete")


func _on_generation_failed(reason: String) -> void:
	"""Handle generation failed signal."""
	send_progress_update(0.0, "Generation failed: %s" % reason, false)
	MythosLogger.error("WorldBuilderWebController", "Generation failed", {"reason": reason})


func _handle_request_data(data: Dictionary) -> void:
	"""Handle request_data message from WebView."""
	var request_id: String = data.get("request_id", "")
	var endpoint: String = data.get("endpoint", "")
	
	if request_id.is_empty():
		MythosLogger.warn("WorldBuilderWebController", "Request data without request_id")
		return
	
	match endpoint:
		"step_definitions":
			_send_step_definitions_response(request_id)
		"archetypes":
			_send_archetypes_response(request_id)
		_:
			MythosLogger.warn("WorldBuilderWebController", "Unknown data request endpoint", {"endpoint": endpoint})


func _send_step_definitions_response(request_id: String) -> void:
	"""Send step definitions as response to request."""
	if not web_view or step_definitions.is_empty():
		return
	
	# Use GodotBridge response format
	var response_script: String = """
		if (window.GodotBridge && window.GodotBridge._pendingRequests && window.GodotBridge._pendingRequests['%s']) {
			window.GodotBridge._pendingRequests['%s'](%s);
			delete window.GodotBridge._pendingRequests['%s'];
		}
	""" % [request_id, request_id, JSON.stringify(step_definitions), request_id]
	
	if web_view.has_method("execute_js"):
		web_view.execute_js(response_script)
	elif web_view.has_method("eval"):
		web_view.eval(response_script)


func _send_archetypes_response(request_id: String) -> void:
	"""Send archetypes as response to request."""
	if not web_view:
		return
	
	var archetype_names: Array[String] = []
	for archetype_name in ARCHETYPES.keys():
		archetype_names.append(archetype_name)
	
	var response_data: Dictionary = {
		"archetype_names": archetype_names,
		"archetypes": ARCHETYPES
	}
	
	var response_script: String = """
		if (window.GodotBridge && window.GodotBridge._pendingRequests && window.GodotBridge._pendingRequests['%s']) {
			window.GodotBridge._pendingRequests['%s'](%s);
			delete window.GodotBridge._pendingRequests['%s'];
		}
	""" % [request_id, request_id, JSON.stringify(response_data), request_id]
	
	if web_view.has_method("execute_js"):
		web_view.execute_js(response_script)
	elif web_view.has_method("eval"):
		web_view.eval(response_script)


func _send_params_update() -> void:
	"""Send parameters update to WebView."""
	if not web_view:
		return
	
	var update_script: String = """
		if (window.worldBuilderInstance) {
			Object.assign(window.worldBuilderInstance.params, %s);
		}
	""" % JSON.stringify(current_params)
	
	if web_view.has_method("execute_js"):
		web_view.execute_js(update_script)
	elif web_view.has_method("eval"):
		web_view.eval(update_script)


func send_progress_update(progress: float, status: String, is_generating: bool) -> void:
	"""Send progress update to WebView."""
	if not web_view:
		return
	
	var update_data: Dictionary = {
		"update_type": "progress_update",
		"progress": progress,
		"status": status,
		"is_generating": is_generating
	}
	
	var update_script: String = """
		if (window.GodotBridge && window.GodotBridge._handleUpdate) {
			window.GodotBridge._handleUpdate(%s);
		}
	""" % JSON.stringify(update_data)
	
	if web_view.has_method("execute_js"):
		web_view.execute_js(update_script)
	elif web_view.has_method("eval"):
		web_view.eval(update_script)

