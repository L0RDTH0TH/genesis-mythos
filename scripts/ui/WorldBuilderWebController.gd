# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderWebController.gd
# ║ Desc: Handles WebView for World Builder UI wizard with Alpine.js
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name WorldBuilderWebController
extends Control

## Reference to the WebView node (for UI)
@onready var web_view: WebView = $WebView

## Reference to WorldBuilderAzgaar controller (for direct JS injection)
var azgaar_controller: Node = null

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
	
	# Load the World Builder HTML file (custom template with 8-step sidebar)
	var html_url: String = "res://assets/ui_web/templates/world_builder.html"
	web_view.load_url(html_url)
	MythosLogger.info("WorldBuilderWebController", "Loaded World Builder HTML", {"url": html_url})
	
	# Connect IPC message signal for bidirectional communication
	if web_view.has_signal("ipc_message"):
		web_view.ipc_message.connect(_on_ipc_message)
		MythosLogger.info("WorldBuilderWebController", "Connected to WebView IPC message signal")
	else:
		MythosLogger.warn("WorldBuilderWebController", "WebView does not have ipc_message signal")
	
	# Connect to WebView error signals if available
	if web_view.has_signal("console_message"):
		web_view.console_message.connect(_on_console_message)
		MythosLogger.info("WorldBuilderWebController", "Connected to WebView console_message signal")
	
	# Log WebView initialization
	MythosLogger.info("WorldBuilderWebController", "WebView initialized", {
		"has_ipc": web_view.has_signal("ipc_message"),
		"has_console": web_view.has_signal("console_message")
	})
	
	# Find WorldBuilderAzgaar controller for direct JS injection
	_find_azgaar_controller()
	
	# Wait for page to load, then inject theme/constants
	# Alpine.js readiness will be signaled via IPC message 'alpine_ready'
	await get_tree().create_timer(0.5).timeout
	_inject_theme_and_constants()
	
	# WebView automatically sizes via anchors/size flags - no manual resize needed


func _find_azgaar_controller() -> void:
	"""Find the WorldBuilderAzgaar controller in the scene tree."""
	# Try to find it as a sibling or in parent
	var parent_node = get_parent()
	if parent_node:
		# Look for WorldBuilderAzgaar as sibling
		for child in parent_node.get_children():
			if child.has_method("trigger_generation_with_options"):
				azgaar_controller = child
				MythosLogger.info("WorldBuilderWebController", "Found WorldBuilderAzgaar controller", {"path": child.get_path()})
				return
		
		# Look in parent's parent
		var grandparent = parent_node.get_parent()
		if grandparent:
			for child in grandparent.get_children():
				if child.has_method("trigger_generation_with_options"):
					azgaar_controller = child
					MythosLogger.info("WorldBuilderWebController", "Found WorldBuilderAzgaar controller in grandparent", {"path": child.get_path()})
					return
	
	# Try to find by node path (common structure)
	var azgaar_node = get_node_or_null("../WorldBuilderAzgaar")
	if azgaar_node and azgaar_node.has_method("trigger_generation_with_options"):
		azgaar_controller = azgaar_node
		MythosLogger.info("WorldBuilderWebController", "Found WorldBuilderAzgaar controller via path")
		return
	
	# Try to find by autoload/singleton if it exists
	azgaar_node = get_node_or_null("/root/WorldBuilderAzgaar")
	if azgaar_node and azgaar_node.has_method("trigger_generation_with_options"):
		azgaar_controller = azgaar_node
		MythosLogger.info("WorldBuilderWebController", "Found WorldBuilderAzgaar controller via autoload")
		return
	
	MythosLogger.warn("WorldBuilderWebController", "WorldBuilderAzgaar controller not found - direct injection will not work")


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
	MythosLogger.info("WorldBuilderWebController", "Loaded step definitions", {
		"count": data.steps.size(),
		"step_0_params": data.steps[0].get("parameters", []).size() if data.steps.size() > 0 else 0,
		"step_1_params": data.steps[1].get("parameters", []).size() if data.steps.size() > 1 else 0
	})




func _send_step_definitions() -> void:
	"""Send step definitions to WebView via IPC with reactive assignment."""
	if not web_view or step_definitions.is_empty():
		MythosLogger.warn("WorldBuilderWebController", "Cannot send step definitions - web_view or data missing")
		return
	
	# Send step definitions as JSON string with reactive assignment
	var json_string: String = JSON.stringify(step_definitions)
	MythosLogger.debug("WorldBuilderWebController", "Sending step definitions JSON", {
		"json_length": json_string.length(),
		"steps_count": step_definitions.get("steps", []).size()
	})
	
	# Use reactive assignment and force Alpine.js to detect changes
	# Fallback: store in _pendingStepsData if worldBuilderInstance not found
	var script: String = """
		(function() {
			try {
				var stepData = %s;
				
				if (!window.worldBuilderInstance) {
					// Store in pending data for later initialization
					console.log('[WorldBuilder] worldBuilderInstance not found, storing in _pendingStepsData');
					window._pendingStepsData = stepData;
					return 'pending';
				}
				
				console.log('[WorldBuilder] Received step definitions:', stepData.steps.length, 'steps');
				
				// Reactive assignment - ensure Alpine.js detects the change
				if (stepData && stepData.steps && Array.isArray(stepData.steps)) {
					// Use Alpine's reactivity system - assign via component instance
					// Clear existing steps first to trigger reactivity
					window.worldBuilderInstance.steps = [];
					
					// Use $nextTick to ensure Alpine processes the change
					if (window.worldBuilderInstance.$nextTick) {
						window.worldBuilderInstance.$nextTick(() => {
							window.worldBuilderInstance.steps = stepData.steps;
							console.log('[WorldBuilder] Steps updated via $nextTick:', window.worldBuilderInstance.steps.length);
							window.worldBuilderInstance._initializeParams();
						});
					} else {
						// Fallback: direct assignment (Alpine should detect array replacement)
						window.worldBuilderInstance.steps = stepData.steps;
						window.worldBuilderInstance._initializeParams();
						console.log('[WorldBuilder] Steps updated (direct assignment):', window.worldBuilderInstance.steps.length);
					}
					
					return true;
				} else {
					console.error('[WorldBuilder] Invalid step data structure');
					return false;
				}
			} catch (e) {
				console.error('[WorldBuilder] Error setting steps:', e);
				return false;
			}
		})();
	""" % json_string
	
	if web_view.has_method("execute_js"):
		var result = web_view.execute_js(script)
		if result == "pending":
			MythosLogger.info("WorldBuilderWebController", "Step definitions stored in _pendingStepsData (Alpine.js not ready yet)")
		else:
			MythosLogger.info("WorldBuilderWebController", "Sent step definitions to WebView", {"result": result})
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
		"alpine_ready":
			_handle_alpine_ready(message_data)
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


func _handle_alpine_ready(data: Dictionary) -> void:
	"""Handle alpine_ready IPC message from WebView."""
	MythosLogger.info("WorldBuilderWebController", "Alpine.js ready signal received from WebView")
	# Small delay to ensure Alpine.js component is fully initialized before sending data
	await get_tree().create_timer(0.1).timeout
	# Now that Alpine.js is ready, send step definitions and archetypes
	_send_step_definitions()
	_send_archetypes()


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
	MythosLogger.debug("WorldBuilderWebController", "_handle_generate() called", {"data_keys": data.keys()})
	
	var params: Dictionary = data.get("params", {})
	var seed_from_message = data.get("seed", current_seed)
	
	MythosLogger.debug("WorldBuilderWebController", "Received params from WebView", {
		"params_count": params.size(), 
		"params": params,
		"seed": seed_from_message
	})
	
	current_params.merge(params)
	
	# Use seed from message if provided, otherwise use current_seed
	if seed_from_message != current_seed:
		current_seed = int(seed_from_message)
	
	# Ensure seed is set in params
	current_params["optionsSeed"] = current_seed
	
	# Clamp all parameters before generation (only curated parameters)
	var clamped_params: Dictionary = {}
	for key in current_params.keys():
		var value = current_params[key]
		clamped_params[key] = _clamp_parameter_value(key, value)
	
	current_params = clamped_params
	
	MythosLogger.info("WorldBuilderWebController", "Generation requested", {
		"params_count": current_params.size(), 
		"seed": current_seed,
		"sample_params": _get_sample_params(current_params, 5)
	})
	
	# Use direct JS injection via WorldBuilderAzgaar controller
	if azgaar_controller and azgaar_controller.has_method("trigger_generation_with_options"):
		send_progress_update(10.0, "Syncing parameters to Azgaar...", true)
		
		# Prepare options dictionary for Azgaar
		var azgaar_options: Dictionary = current_params.duplicate()
		# Ensure seed is set correctly
		azgaar_options["optionsSeed"] = current_seed
		
		# Trigger generation via direct JS injection
		azgaar_controller.trigger_generation_with_options(azgaar_options, true)
		
		send_progress_update(40.0, "Generating map...", true)
		
		# Connect to generation signals if available
		if azgaar_controller.has_signal("generation_complete"):
			if not azgaar_controller.generation_complete.is_connected(_on_azgaar_generation_complete):
				azgaar_controller.generation_complete.connect(_on_azgaar_generation_complete)
		if azgaar_controller.has_signal("generation_failed"):
			if not azgaar_controller.generation_failed.is_connected(_on_azgaar_generation_failed):
				azgaar_controller.generation_failed.connect(_on_azgaar_generation_failed)
		
		MythosLogger.info("WorldBuilderWebController", "Generation triggered via direct JS injection")
	else:
		MythosLogger.error("WorldBuilderWebController", "Cannot generate - Azgaar controller not available")
		send_progress_update(0.0, "Error: Azgaar controller not found", false)


func _on_azgaar_generation_complete() -> void:
	"""Handle generation complete signal from Azgaar controller."""
	send_progress_update(100.0, "Generation complete!", false)
	MythosLogger.info("WorldBuilderWebController", "Azgaar generation completed")


func _on_azgaar_generation_failed(reason: String) -> void:
	"""Handle generation failed signal from Azgaar controller."""
	send_progress_update(0.0, "Generation failed: %s" % reason, false)
	MythosLogger.error("WorldBuilderWebController", "Azgaar generation failed", {"reason": reason})


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


func set_terrain_manager(manager: Node) -> void:
	"""Set terrain manager reference (stub for interface compatibility)."""
	# Store reference if needed for future terrain operations
	# Currently, WorldBuilderWebController doesn't directly interact with terrain
	MythosLogger.debug("WorldBuilderWebController", "Terrain manager set", {"manager": manager})


func _get_sample_params(params: Dictionary, count: int) -> Dictionary:
	"""Get a sample of parameters for logging (to avoid huge log entries)."""
	var sample: Dictionary = {}
	var keys: Array = params.keys()
	var sample_size: int = min(count, keys.size())
	for i in range(sample_size):
		var key = keys[i]
		sample[key] = params[key]
	return sample


func _on_console_message(level: int, message: String, source: String, line: int) -> void:
	"""Handle console messages from WebView (for debugging)."""
	# Filter for relevant messages
	if message.contains("[Genesis World Builder]") or message.contains("[Genesis Azgaar]") or message.contains("CORS") or message.contains("timeout"):
		match level:
			0:  # LOG_LEVEL_DEBUG
				MythosLogger.debug("WorldBuilderWebController", "WebView console", {"level": "debug", "message": message, "source": source, "line": line})
			1:  # LOG_LEVEL_INFO
				MythosLogger.info("WorldBuilderWebController", "WebView console", {"level": "info", "message": message, "source": source, "line": line})
			2:  # LOG_LEVEL_WARN
				MythosLogger.warn("WorldBuilderWebController", "WebView console", {"level": "warn", "message": message, "source": source, "line": line})
			3:  # LOG_LEVEL_ERROR
				MythosLogger.error("WorldBuilderWebController", "WebView console", {"level": "error", "message": message, "source": source, "line": line})
			_:
				MythosLogger.debug("WorldBuilderWebController", "WebView console", {"level": level, "message": message, "source": source, "line": line})

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
	
	MythosLogger.debug("WorldBuilderWebController", "Sending progress update", update_data)
	
	var update_script: String = """
		if (window.GodotBridge && window.GodotBridge._handleUpdate) {
			window.GodotBridge._handleUpdate(%s);
		}
	""" % JSON.stringify(update_data)
	
	if web_view.has_method("execute_js"):
		web_view.execute_js(update_script)
	elif web_view.has_method("eval"):
		web_view.eval(update_script)
