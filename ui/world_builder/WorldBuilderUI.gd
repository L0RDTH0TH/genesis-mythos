# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderUI.gd
# ║ Desc: Minimal wrapper for Alpine.js-based World Builder UI in WebView
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name WorldBuilderUI
extends Control

## Reference to terrain manager (optional, for future 3D baking)
var terrain_manager: Node = null

# Wizard flow
var current_step: int = 0
const TOTAL_STEPS: int = 8

# UI References
@onready var web_view_container: MarginContainer = $MainVBox/WebViewContainer
@onready var world_builder_webview: Control = $MainVBox/WebViewContainer/WorldBuilderWebView
@onready var web_view: Node = $MainVBox/WebViewContainer/WorldBuilderWebView/WebView
@onready var progress_modal: Panel = $ProgressModal
@onready var progress_label: Label = $ProgressModal/ModalContent/ProgressLabel
@onready var progress_bar: ProgressBar = $ProgressModal/ModalContent/ProgressBar

# Step definitions loaded from JSON
var STEP_DEFINITIONS: Dictionary = {}
const STEP_PARAMETERS_PATH: String = "res://data/config/azgaar_step_parameters.json"

# Current parameters (synced with WebView)
var current_params: Dictionary = {}

# WorldBuilderAzgaar script reference (for Azgaar map generation)
var azgaar_controller: Node = null


func _ready() -> void:
	"""Initialize the World Builder UI."""
	DirAccess.make_dir_recursive_absolute("user://azgaar/")
	
	# Load step definitions from JSON
	_load_step_definitions()
	
	# Get WorldBuilderAzgaar script reference
	azgaar_controller = world_builder_webview
	if not azgaar_controller:
		MythosLogger.error("UI/WorldBuilder", "WorldBuilderAzgaar script not found")
		return
	
	# Connect to Azgaar generation signals
	if azgaar_controller.has_signal("generation_complete"):
		if not azgaar_controller.generation_complete.is_connected(_on_azgaar_generation_complete):
			azgaar_controller.generation_complete.connect(_on_azgaar_generation_complete)
	if azgaar_controller.has_signal("generation_failed"):
		if not azgaar_controller.generation_failed.is_connected(_on_azgaar_generation_failed):
			azgaar_controller.generation_failed.connect(_on_azgaar_generation_failed)
	
	# Initialize WebView
	call_deferred("_initialize_webview")


func _initialize_webview() -> void:
	"""Initialize the WebView and load Alpine.js UI."""
	if not web_view:
		MythosLogger.error("UI/WorldBuilder", "WebView node not found")
		return
	
	# Connect IPC message signal
	if web_view.has_signal("ipc_message"):
		web_view.ipc_message.connect(_on_ipc_message)
		MythosLogger.info("UI/WorldBuilder", "Connected to WebView IPC message signal")
	else:
		MythosLogger.warn("UI/WorldBuilder", "WebView does not have ipc_message signal")
	
	# Load Alpine.js UI HTML file
	var html_path: String = "res://web_ui/world_builder/index.html"
	if web_view.has_method("load_url"):
		web_view.load_url(html_path)
		MythosLogger.info("UI/WorldBuilder", "Loading Alpine.js UI", {"path": html_path})
		
		# Wait for page to load, then inject IPC bridge and send step definitions
		await get_tree().create_timer(1.0).timeout
		_inject_ipc_bridge()
		_send_step_definitions()
	else:
		MythosLogger.error("UI/WorldBuilder", "WebView does not have load_url method")


func _inject_ipc_bridge() -> void:
	"""Inject IPC bridge script into WebView for bidirectional communication."""
	if not web_view:
		return
	
	var bridge_script: String = """
	(function() {
		// Set up IPC handler for godot_wry
		if (typeof window.godotBridgeOnMessage === 'function') {
			// Bridge already set up
			return;
		}
		
		// Expose onMessage function for godot_wry to call
		window.godotBridgeOnMessage = function(message) {
			if (window.GodotBridge && window.GodotBridge.onMessage) {
				window.GodotBridge.onMessage(message);
			}
		};
		
		// Set up postMessage to use godot_wry IPC
		if (window.GodotBridge) {
			var originalPostMessage = window.GodotBridge.postMessage;
			window.GodotBridge.postMessage = function(type, data) {
				var message = {
					type: type,
					data: data || {},
					timestamp: Date.now()
				};
				// Call original postMessage which will use window.godot.postMessage or IPC
				originalPostMessage.call(this, type, data);
			};
		}
		
		console.log('[WorldBuilderUI] IPC bridge injected');
	})();
	"""
	
	if web_view.has_method("execute_js"):
		web_view.execute_js(bridge_script)
		MythosLogger.info("UI/WorldBuilder", "Injected IPC bridge script")
	elif web_view.has_method("eval"):
		web_view.eval(bridge_script)
		MythosLogger.info("UI/WorldBuilder", "Injected IPC bridge script via eval")
	else:
		MythosLogger.warn("UI/WorldBuilder", "Cannot inject bridge - WebView does not have execute_js or eval method")


func _load_step_definitions() -> void:
	"""Load step definitions from JSON file."""
	var data: Variant = DataCache.get_json_data(STEP_PARAMETERS_PATH)
	if data == null:
		MythosLogger.error("UI/WorldBuilder", "Failed to load step parameters", {"path": STEP_PARAMETERS_PATH})
		# Fallback to empty definitions
		for i in range(TOTAL_STEPS):
			STEP_DEFINITIONS[i] = {"title": "Step %d" % (i + 1), "parameters": []}
		return
	
	if not data is Dictionary:
		MythosLogger.error("UI/WorldBuilder", "Step parameters JSON is not a Dictionary")
		# Fallback to empty definitions
		for i in range(TOTAL_STEPS):
			STEP_DEFINITIONS[i] = {"title": "Step %d" % (i + 1), "parameters": []}
		return
	
	if not data.has("steps") or not data.steps is Array:
		MythosLogger.error("UI/WorldBuilder", "Invalid step parameters JSON structure")
		return
	
	# Convert JSON array to dictionary indexed by step index
	for step_data in data.steps:
		if not step_data is Dictionary or not step_data.has("index"):
			continue
		var step_idx: int = step_data.index
		var params_list: Array = []
		
		# Convert parameter definitions to format expected by Alpine.js UI
		if step_data.has("parameters") and step_data.parameters is Array:
			for param_data in step_data.parameters:
				if not param_data is Dictionary:
					continue
				var param: Dictionary = {}
				param.name = param_data.get("name", "")
				param.type = param_data.get("ui_type", "HSlider")
				param.azgaar_key = param_data.get("azgaar_key", param.name)
				
				# Copy type-specific properties
				if param_data.has("options"):
					param.options = param_data.options
				if param_data.has("min"):
					param.min = param_data.min
				if param_data.has("max"):
					param.max = param_data.max
				if param_data.has("step"):
					param.step = param_data.step
				if param_data.has("default"):
					param.default = param_data.default
				
				params_list.append(param)
		
		STEP_DEFINITIONS[step_idx] = {
			"title": step_data.get("title", "Step %d" % (step_idx + 1)),
			"parameters": params_list
		}
	
	MythosLogger.info("UI/WorldBuilder", "Loaded step definitions", {"count": STEP_DEFINITIONS.size()})


func _send_step_definitions() -> void:
	"""Send step definitions to WebView."""
	if not web_view:
		return
	
	# Convert STEP_DEFINITIONS to array format for JSON
	var steps_array: Array = []
	for i in range(TOTAL_STEPS):
		if STEP_DEFINITIONS.has(i):
			steps_array.append(STEP_DEFINITIONS[i])
		else:
			steps_array.append({"title": "Step %d" % (i + 1), "parameters": []})
	
	var message: Dictionary = {
		"type": "step_definitions",
		"data": {
			"steps": steps_array
		}
	}
	
	_post_message_to_webview(message)


func _on_ipc_message(message: String) -> void:
	"""Handle IPC messages from WebView."""
	MythosLogger.debug("UI/WorldBuilder", "Received IPC message from WebView", {"message": message})
	
	# Parse JSON message
	var json = JSON.new()
	var parse_result = json.parse(message)
	if parse_result != OK:
		MythosLogger.warn("UI/WorldBuilder", "Failed to parse IPC message", {"message": message})
		return
	
	var data = json.data
	if not data is Dictionary or not data.has("type"):
		return
	
	match data.type:
		"request_step_definitions":
			_send_step_definitions()
		
		"step_changed":
			current_step = data.data.get("step", 0)
			MythosLogger.debug("UI/WorldBuilder", "Step changed", {"step": current_step})
		
		"parameter_changed":
			var key: String = data.data.get("key", "")
			var value = data.data.get("value")
			if not key.is_empty():
				current_params[key] = value
				MythosLogger.debug("UI/WorldBuilder", "Parameter changed", {"key": key, "value": value})
		
		"generate":
			var params: Dictionary = data.data.get("parameters", {})
			_generate_azgaar(params)
		
		_:
			MythosLogger.debug("UI/WorldBuilder", "Unhandled message type", {"type": data.type})


func _post_message_to_webview(message: Dictionary) -> void:
	"""Send message to WebView via IPC."""
	if not web_view:
		return
	
	# Use post_message method (godot_wry standard)
	if web_view.has_method("post_message"):
		var json_string = JSON.stringify(message)
		web_view.post_message(json_string)
		MythosLogger.debug("UI/WorldBuilder", "Posted message to WebView", {"type": message.get("type", "unknown")})
	# Fallback: use execute_js to call JavaScript function directly
	elif web_view.has_method("execute_js"):
		var js_code: String = "if (window.godotBridgeOnMessage) { window.godotBridgeOnMessage(%s); }" % JSON.stringify(message)
		web_view.execute_js(js_code)
		MythosLogger.debug("UI/WorldBuilder", "Sent message to WebView via execute_js", {"type": message.get("type", "unknown")})


func _generate_azgaar(params: Dictionary) -> void:
	"""Generate world with Azgaar using parameters from WebView."""
	_update_progress("Syncing parameters...", 10)
	
	# Update current_params
	current_params = params.duplicate()
	
	if not azgaar_controller or not azgaar_controller.has_method("trigger_generation_with_options"):
		_update_progress("Error: Azgaar controller not found", 0)
		MythosLogger.error("UI/WorldBuilder", "Cannot find WorldBuilderAzgaar controller")
		return
	
	# Connect to generation signals if not already connected
	if azgaar_controller.has_signal("generation_complete"):
		if not azgaar_controller.generation_complete.is_connected(_on_azgaar_generation_complete):
			azgaar_controller.generation_complete.connect(_on_azgaar_generation_complete)
	if azgaar_controller.has_signal("generation_failed"):
		if not azgaar_controller.generation_failed.is_connected(_on_azgaar_generation_failed):
			azgaar_controller.generation_failed.connect(_on_azgaar_generation_failed)
	
	# Trigger generation with parameters
	_update_progress("Injecting parameters...", 20)
	azgaar_controller.trigger_generation_with_options(current_params, true)
	
	_update_progress("Generating map...", 40)
	progress_modal.visible = true


func _on_azgaar_generation_complete() -> void:
	"""Handle Azgaar generation completion signal."""
	_update_progress("Generation complete!", 100)
	
	# Wait a moment for final rendering
	await get_tree().create_timer(1.0).timeout
	
	# Hide progress modal
	progress_modal.visible = false
	
	# Notify WebView
	_post_message_to_webview({
		"type": "generation_complete",
		"data": {}
	})
	
	MythosLogger.info("UI/WorldBuilder", "Azgaar generation completed")


func _on_azgaar_generation_failed(reason: String) -> void:
	"""Handle Azgaar generation failure signal."""
	_update_progress("Generation failed: %s" % reason, 0)
	
	# Notify WebView
	_post_message_to_webview({
		"type": "generation_failed",
		"data": {
			"reason": reason
		}
	})
	
	MythosLogger.error("UI/WorldBuilder", "Azgaar generation failed", {"reason": reason})


func _update_progress(text: String, progress: float) -> void:
	"""Update progress modal."""
	progress_label.text = text
	progress_bar.value = progress
	progress_modal.visible = (progress < 100)


func set_terrain_manager(manager: Node) -> void:
	"""Set the terrain manager reference (called by world_root.gd)."""
	terrain_manager = manager
	var manager_name: String = String(manager.name) if manager != null else "null"
	MythosLogger.debug("UI/WorldBuilder", "Terrain manager set", {"manager": manager_name})
