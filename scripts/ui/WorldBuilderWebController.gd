# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderWebController.gd
# ║ Desc: Handles WebView for World Builder UI wizard with Alpine.js
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name WorldBuilderWebController
extends Control

## Reference to the WebView node
@onready var web_view: WebView = $WebView

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
	
	# Load step definitions from JSON
	_load_step_definitions()
	
	# Load the World Builder HTML file
	var html_url: String = "res://web_ui/world_builder/index.html"
	web_view.load_url(html_url)
	MythosLogger.info("WorldBuilderWebController", "Loaded World Builder HTML", {"url": html_url})
	
	# Connect IPC message signal for bidirectional communication
	if web_view.has_signal("ipc_message"):
		web_view.ipc_message.connect(_on_ipc_message)
		MythosLogger.info("WorldBuilderWebController", "Connected to WebView IPC message signal")
	else:
		MythosLogger.warn("WorldBuilderWebController", "WebView does not have ipc_message signal")
	
	# Try to find WorldBuilderAzgaar in scene tree (for generation)
	_find_azgaar_controller()
	
	# Wait for page to load, then send initial data
	await get_tree().create_timer(1.5).timeout
	_inject_theme_and_constants()
	_send_step_definitions()
	_send_archetypes()
	
	# WebView automatically sizes via anchors/size flags - no manual resize needed


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
		# WebView automatically resizes via anchors/size flags - no manual resize needed
		MythosLogger.debug("WorldBuilderWebController", "Window resized - WebView handles via anchors")


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
		if (window.worldBuilderInstance) {
			var stepData = %s;
			window.worldBuilderInstance.steps = stepData.steps || [];
			window.worldBuilderInstance._initializeParams();
		}
	""" % json_string
	
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


func _inject_theme_and_constants() -> void:
	"""Inject theme colors and UIConstants values into CSS for responsive layout."""
	if not web_view:
		return
	
	# Get theme colors from bg3_theme.tres (extract common colors)
	# Note: Theme resource parsing is limited, so we'll use known values
	var theme_colors: Dictionary = {
		"bg_dark": "#101010",  # Color(0.0588235, 0.0588235, 0.0588235, 1)
		"font_gold": "#FFD700",  # Color(1, 0.843137, 0, 1)
		"font_hover_gold": "#FFF5BF",  # Color(1, 0.95, 0.75, 1)
		"font_pressed_gold": "#D9B366",  # Color(0.85, 0.7, 0.4, 1)
		"bg_panel": "#1A1F26",  # Panel background
		"bg_panel_light": "#2A323D",  # Hover state
		"font_default": "#E0E0E0",  # Default text
		"border_gold": "#FFD700"
	}
	
	# Get UIConstants values for responsive panel widths
	var panel_constants: Dictionary = {
		"left_panel_width": UIConstants.LEFT_PANEL_WIDTH,
		"left_panel_width_min": UIConstants.LEFT_PANEL_WIDTH_MIN,
		"left_panel_width_max": UIConstants.LEFT_PANEL_WIDTH_MAX,
		"right_panel_width": UIConstants.RIGHT_PANEL_WIDTH,
		"right_panel_width_min": UIConstants.RIGHT_PANEL_WIDTH_MIN,
		"right_panel_width_max": UIConstants.RIGHT_PANEL_WIDTH_MAX,
		"spacing_small": UIConstants.SPACING_SMALL,
		"spacing_medium": UIConstants.SPACING_MEDIUM,
		"spacing_large": UIConstants.SPACING_LARGE,
		"button_height_small": UIConstants.BUTTON_HEIGHT_SMALL,
		"button_height_medium": UIConstants.BUTTON_HEIGHT_MEDIUM,
		"button_height_large": UIConstants.BUTTON_HEIGHT_LARGE
	}
	
	# Inject CSS variables via JavaScript
	var script: String = """
		(function() {
			var root = document.documentElement;
			
			// Inject theme colors
			var themeColors = %s;
			for (var key in themeColors) {
				var cssKey = '--' + key.replace(/_/g, '-');
				root.style.setProperty(cssKey, themeColors[key]);
			}
			
			// Inject UIConstants for responsive sizing
			var constants = %s;
			root.style.setProperty('--left-tabs-width', constants.left_panel_width + 'px');
			root.style.setProperty('--left-tabs-width-min', constants.left_panel_width_min + 'px');
			root.style.setProperty('--left-tabs-width-max', constants.left_panel_width_max + 'px');
			root.style.setProperty('--right-panel-width', constants.right_panel_width + 'px');
			root.style.setProperty('--right-panel-width-min', constants.right_panel_width_min + 'px');
			root.style.setProperty('--right-panel-width-max', constants.right_panel_width_max + 'px');
			
			console.log('Theme colors and UIConstants injected');
		})();
	""" % [JSON.stringify(theme_colors), JSON.stringify(panel_constants)]
	
	if web_view.has_method("execute_js"):
		web_view.execute_js(script)
		MythosLogger.info("WorldBuilderWebController", "Injected theme colors and UIConstants")
	elif web_view.has_method("eval"):
		web_view.eval(script)
		MythosLogger.info("WorldBuilderWebController", "Injected theme colors and UIConstants via eval")


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
		# Send updated step parameters to WebView
		_send_step_params_for_current_step()


func _handle_load_archetype(data: Dictionary) -> void:
	"""Handle load_archetype message from WebView."""
	var archetype_name: String = data.get("archetype", "High Fantasy")
	current_archetype = archetype_name
	
	var preset: Dictionary = ARCHETYPES.get(archetype_name, {}).duplicate()
	if not preset.is_empty():
		# Map preset keys to azgaar_keys (handle different naming conventions)
		# Note: ARCHETYPES uses different keys than azgaar - this mapping is approximate
		var preset_mapped: Dictionary = {}
		# Convert points (actual count) to pointsInput slider value (1-13) - approximate conversion
		if preset.has("points"):
			# Approximate: pointsInput 1-13 maps to ~1K-100K cells
			# We'll use a simple mapping - this may need adjustment
			var points_count: int = preset["points"]
			var clamped_points: int = UIConstants.get_clamped_points(points_count)
			# Convert to slider value (1-13 scale, approximate)
			# Use natural log divided by log(10) to get log base 10
			preset_mapped["pointsInput"] = int(log(clamped_points / 1000.0) / log(10.0))
			preset_mapped["pointsInput"] = clamp(preset_mapped["pointsInput"], 1, 10)  # Use clamped max
		if preset.has("heightExponent"):
			preset_mapped["heightExponentInput"] = preset["heightExponent"]
		if preset.has("allowErosion"):
			preset_mapped["allowErosion"] = preset["allowErosion"]
		if preset.has("burgs"):
			preset_mapped["manorsInput"] = preset["burgs"]
		if preset.has("precip"):
			preset_mapped["precInput"] = int(preset["precip"] * 100)  # Convert to percentage
		
		# Clamp and apply preset params
		for key in preset_mapped.keys():
			var clamped_value = _clamp_parameter_value(key, preset_mapped[key])
			current_params[key] = clamped_value
		
		# Send params update to WebView
		_send_params_update()
		MythosLogger.info("WorldBuilderWebController", "Loaded archetype preset", {"archetype": archetype_name, "params": preset_mapped})


func _handle_set_seed(data: Dictionary) -> void:
	"""Handle set_seed message from WebView."""
	current_seed = int(data.get("seed", 12345))
	MythosLogger.debug("WorldBuilderWebController", "Seed changed", {"seed": current_seed})


func _clamp_parameter_value(azgaar_key: String, value: Variant) -> Variant:
	"""Clamp parameter value based on step definitions (curated/clamped_min/clamped_max)."""
	# Special handling for pointsInput: use hardware-aware clamping
	if azgaar_key == "pointsInput" and value is int:
		# Convert slider value (1-13) to approximate cell count, then clamp by hardware
		# Approximate: pointsInput maps to ~1K-100K cells (log scale)
		var approximate_cells: int = int(pow(10.0, float(value)) * 1000.0)
		var clamped_cells: int = UIConstants.get_clamped_points(approximate_cells)
		# Convert back to slider value (inverse log)
		var clamped_slider: int = int(log(clamped_cells / 1000.0) / log(10.0))
		return clamp(clamped_slider, 1, 10)  # Ensure within slider range
	
	# Find parameter definition in step definitions
	for step_dict in step_definitions.get("steps", []):
		var parameters: Array = step_dict.get("parameters", [])
		for param_dict in parameters:
			if param_dict.get("azgaar_key") == azgaar_key:
				# Only clamp curated parameters
				if param_dict.get("curated", true) != true:
					return value
				
				# Clamp numeric values
				if value is int or value is float:
					var min_val = param_dict.get("clamped_min")
					if min_val == null:
						min_val = param_dict.get("min")
					var max_val = param_dict.get("clamped_max")
					if max_val == null:
						max_val = param_dict.get("max")
					
					if min_val != null and max_val != null:
						# Clamp numeric value to defined range
						return clamp(value, min_val, max_val)
				return value
	
	return value


func _handle_update_param(data: Dictionary) -> void:
	"""Handle update_param message from WebView."""
	var azgaar_key: String = data.get("azgaar_key", "")
	var value = data.get("value")
	
	if not azgaar_key.is_empty():
		# Clamp value based on parameter definition
		var clamped_value = _clamp_parameter_value(azgaar_key, value)
		current_params[azgaar_key] = clamped_value
		MythosLogger.debug("WorldBuilderWebController", "Parameter updated", {"key": azgaar_key, "value": clamped_value, "original": value})


func _handle_generate(data: Dictionary) -> void:
	"""Handle generate message from WebView."""
	var params: Dictionary = data.get("params", {})
	current_params.merge(params)
	
	# Ensure seed is set
	current_params["optionsSeed"] = current_seed
	
	# Clamp all parameters before generation (only curated parameters)
	var clamped_params: Dictionary = {}
	for key in current_params.keys():
		var value = current_params[key]
		clamped_params[key] = _clamp_parameter_value(key, value)
	
	current_params = clamped_params
	
	MythosLogger.info("WorldBuilderWebController", "Generation requested", {"params": current_params})
	
	# Trigger generation via WorldBuilderAzgaar
	var azgaar_controller: Node = null
	if world_builder_azgaar:
		azgaar_controller = world_builder_azgaar
	
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


func _send_step_params_for_current_step() -> void:
	"""Send parameters for the current step to WebView."""
	if not web_view or step_definitions.is_empty():
		return
	
	# Get current step definition
	var steps: Array = step_definitions.get("steps", [])
	if current_step >= 0 and current_step < steps.size():
		var step_dict: Dictionary = steps[current_step]
		var step_params: Array = step_dict.get("parameters", [])
		
		# Filter to only curated parameters and build param update dict
		var curated_params: Dictionary = {}
		for param_dict in step_params:
			if param_dict.get("curated", true) == true:
				var azgaar_key: String = param_dict.get("azgaar_key", "")
				if not azgaar_key.is_empty():
					# Use current value if exists, otherwise use default
					if current_params.has(azgaar_key):
						curated_params[azgaar_key] = current_params[azgaar_key]
					elif param_dict.has("default"):
						curated_params[azgaar_key] = param_dict["default"]
		
		# Send update to WebView
		if not curated_params.is_empty():
			_send_params_update()
			MythosLogger.debug("WorldBuilderWebController", "Sent step params for step", {"step": current_step, "params": curated_params})


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
