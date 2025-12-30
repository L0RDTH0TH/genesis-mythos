# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderWebController.gd
# ║ Desc: Handles WebView for World Builder UI wizard with Alpine.js
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name WorldBuilderWebController
extends Control

## Reference to the WebView node (for UI)
@onready var web_view: WebView = $WebView

## Iframe ID for Azgaar embedding (for iframe-based JS injection)
const IFRAME_ID: String = "azgaar-iframe"

## Flag to track if Azgaar is ready via iframe
var azgaar_ready_via_iframe: bool = false

## Timer for polling Azgaar readiness
var azgaar_readiness_timer: Timer = null
var azgaar_readiness_poll_count: int = 0
const MAX_READINESS_POLLS: int = 20  # 20 * 0.5s = 10 seconds max

## Timer for generation completion timeout (fallback)
var generation_timeout_timer: Timer = null
const GENERATION_TIMEOUT_SECONDS: float = 60.0  # 60 seconds timeout

## Current step index (synced with WebView)
var current_step: int = 0

## Current parameters dictionary (synced with WebView)
var current_params: Dictionary = {}

## Current archetype name
var current_archetype: String = "High Fantasy"

## Step definitions loaded from JSON
var step_definitions: Dictionary = {}
const STEP_PARAMETERS_PATH: String = "res://data/config/azgaar_step_parameters.json"

## Debug: Test Azgaar fork headless generation
const DEBUG_TEST_FORK: bool = true  # Set to true to run test on _ready()
var test_json_data: Dictionary = {}  # Store test JSON output

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
	
	# DIAGNOSTIC: Log scene tree structure
	_print_scene_tree_diagnostics()
	
	if not web_view:
		MythosLogger.error("WorldBuilderWebController", "WebView node not found!")
		return
	
	# Load step definitions from JSON
	_load_step_definitions()
	
	# Load the World Builder HTML file (use fork template if testing)
	var html_url: String
	if DEBUG_TEST_FORK:
		html_url = "res://assets/ui_web/templates/world_builder_v2.html"
		MythosLogger.info("WorldBuilderWebController", "DEBUG: Loading fork template for testing")
	else:
		html_url = "res://assets/ui_web/templates/world_builder.html"
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
	
	# Note: Azgaar is now embedded as iframe in world_builder.html
	# Readiness will be signaled via IPC message 'azgaar_loaded' and 'azgaar_ready'
	MythosLogger.info("WorldBuilderWebController", "Azgaar will be accessed via iframe embedding")
	
	# Wait for page to load, then inject theme/constants
	# Alpine.js readiness will be signaled via IPC message 'alpine_ready'
	await get_tree().create_timer(0.5).timeout
	_inject_theme_and_constants()
	
	# Debug: Test fork headless generation if enabled
	if DEBUG_TEST_FORK:
		await get_tree().create_timer(3.0).timeout  # Wait for fork to initialize
		_test_fork_headless_generation()
	
	# WebView automatically sizes via anchors/size flags - no manual resize needed


# Removed _find_azgaar_controller() - Azgaar is now accessed via iframe in HTML


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
		"azgaar_loaded":
			_handle_azgaar_loaded(message_data)
		"azgaar_ready":
			_handle_azgaar_ready_ipc(message_data)
		"set_step":
			_handle_set_step(message_data)
		"load_archetype":
			_handle_load_archetype(message_data)
		"update_param":
			_handle_update_param(message_data)
		"generate":
			_handle_generate(message_data)
		"generation_complete":
			_handle_generation_complete(message_data)
		"generation_failed":
			_handle_generation_failed(message_data)
		"request_data":
			_handle_request_data(message_data)
		"map_generated":
			_handle_map_generated(message_data)
		"map_generation_failed":
			_handle_map_generation_failed(message_data)
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


func _handle_azgaar_loaded(data: Dictionary) -> void:
	"""Handle azgaar_loaded IPC message - iframe has loaded, start polling for readiness."""
	MythosLogger.info("WorldBuilderWebController", "Azgaar iframe loaded, starting readiness polling")
	
	# Start polling for Azgaar readiness
	azgaar_readiness_poll_count = 0
	if azgaar_readiness_timer == null:
		azgaar_readiness_timer = Timer.new()
		azgaar_readiness_timer.one_shot = false
		azgaar_readiness_timer.wait_time = 0.5
		azgaar_readiness_timer.timeout.connect(_poll_azgaar_readiness)
		add_child(azgaar_readiness_timer)
	
	azgaar_readiness_timer.start()
	MythosLogger.debug("WorldBuilderWebController", "Started Azgaar readiness polling timer")


func _poll_azgaar_readiness() -> void:
	"""Poll iframe to check if Azgaar JS is ready."""
	if azgaar_readiness_poll_count >= MAX_READINESS_POLLS:
		azgaar_readiness_timer.stop()
		MythosLogger.warn("WorldBuilderWebController", "Azgaar readiness polling timeout after %d attempts" % MAX_READINESS_POLLS)
		return
	
	azgaar_readiness_poll_count += 1
	
	# Check if Azgaar is ready via iframe
	var check_script: String = """
		(function() {
			try {
				var iframe = document.getElementById('%s');
				if (iframe && iframe.contentWindow && iframe.contentWindow.azgaar && 
				    iframe.contentWindow.azgaar.options && typeof iframe.contentWindow.azgaar.generate === 'function') {
					if (window.GodotBridge && window.GodotBridge.postMessage) {
						window.GodotBridge.postMessage({
							type: 'azgaar_ready',
							data: {}
						});
					}
					return 'ready';
				}
				return 'not_ready';
			} catch (e) {
				console.error('[WorldBuilder] Error checking Azgaar readiness:', e);
				return 'error: ' + e.message;
			}
		})();
	""" % IFRAME_ID
	
	if web_view.has_method("execute_js"):
		var result = web_view.execute_js(check_script)
		if result == "ready":
			azgaar_readiness_timer.stop()
			MythosLogger.info("WorldBuilderWebController", "Azgaar is ready via iframe (poll attempt %d)" % azgaar_readiness_poll_count)
		elif result != null and result.begins_with("error"):
			MythosLogger.warn("WorldBuilderWebController", "Error checking Azgaar readiness: %s" % result)
	elif web_view.has_method("eval"):
		web_view.eval(check_script)


func _handle_azgaar_ready_ipc(data: Dictionary) -> void:
	"""Handle azgaar_ready IPC message - Azgaar JS is ready for generation."""
	MythosLogger.info("WorldBuilderWebController", "Azgaar ready via iframe, triggering initial generation")
	azgaar_ready_via_iframe = true
	
	# Stop polling if still running
	if azgaar_readiness_timer and azgaar_readiness_timer.is_stopped() == false:
		azgaar_readiness_timer.stop()
	
	# Wait a moment for Azgaar to be fully ready
	await get_tree().create_timer(0.5).timeout
	
	# Trigger initial default map generation
	_generate_initial_default_map()


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
	
	# DIAGNOSTIC: Log iframe readiness state before generation
	MythosLogger.info("WorldBuilderWebController", "DIAGNOSTIC: _handle_generate() iframe readiness", {
		"azgaar_ready_via_iframe": azgaar_ready_via_iframe,
		"iframe_id": IFRAME_ID
	})
	
	var params: Dictionary = data.get("params", {})
	
	MythosLogger.debug("WorldBuilderWebController", "Received params from WebView", {
		"params_count": params.size(), 
		"params": params,
		"optionsSeed": params.get("optionsSeed", "not_set")
	})
	
	current_params.merge(params)
	
	# Ensure optionsSeed is set in params (from Step 1)
	if not current_params.has("optionsSeed"):
		# Fallback: use default from step definitions or random
		var default_seed: int = 12345
		for step_dict in step_definitions.get("steps", []):
			var parameters: Array = step_dict.get("parameters", [])
			for param_dict in parameters:
				if param_dict.get("azgaar_key") == "optionsSeed" and param_dict.has("default"):
					default_seed = int(param_dict["default"])
					break
		current_params["optionsSeed"] = default_seed
		MythosLogger.warn("WorldBuilderWebController", "optionsSeed not in params, using default", {"seed": default_seed})
	
	# Clamp all parameters before generation (only curated parameters)
	var clamped_params: Dictionary = {}
	for key in current_params.keys():
		var value = current_params[key]
		clamped_params[key] = _clamp_parameter_value(key, value)
	
	current_params = clamped_params
	
	MythosLogger.info("WorldBuilderWebController", "Generation requested", {
		"params_count": current_params.size(), 
		"optionsSeed": current_params.get("optionsSeed", "not_set"),
		"sample_params": _get_sample_params(current_params, 5)
	})
	
	# Use iframe-based JS injection to access Azgaar
	if not azgaar_ready_via_iframe:
		MythosLogger.warn("WorldBuilderWebController", "Azgaar not ready yet via iframe, attempting generation anyway")
	
	send_progress_update(10.0, "Syncing parameters to Azgaar...", true)
	
	# Inject parameters into Azgaar via iframe.contentWindow
	_sync_params_to_azgaar_iframe(current_params)
	
	send_progress_update(40.0, "Generating map...", true)
	
	# Trigger generation via iframe
	var generate_script: String = """
		(function() {
			try {
				var iframe = document.getElementById('%s');
				if (iframe && iframe.contentWindow && iframe.contentWindow.azgaar && 
				    typeof iframe.contentWindow.azgaar.generate === 'function') {
					iframe.contentWindow.azgaar.generate();
					return 'generated';
				}
				return 'error: azgaar not available';
			} catch (e) {
				console.error('[WorldBuilder] Error triggering generation:', e);
				return 'error: ' + e.message;
			}
		})();
	""" % IFRAME_ID
	
	if web_view.has_method("execute_js"):
		var result = web_view.execute_js(generate_script)
		if result == "generated":
			MythosLogger.info("WorldBuilderWebController", "Generation triggered via iframe")
			_start_generation_timeout()
		else:
			MythosLogger.error("WorldBuilderWebController", "Failed to trigger generation via iframe", {"result": result})
			send_progress_update(0.0, "Error: Failed to trigger generation", false)
	elif web_view.has_method("eval"):
		web_view.eval(generate_script)
		MythosLogger.info("WorldBuilderWebController", "Generation triggered via iframe (eval)")
		_start_generation_timeout()


# Removed _on_azgaar_ready() - replaced by _handle_azgaar_ready_ipc() for iframe-based access
# Removed _check_and_trigger_initial_generation() - replaced by polling in _handle_azgaar_loaded()


func _sync_params_to_azgaar_iframe(params: Dictionary) -> void:
	"""Sync parameters to Azgaar via iframe.contentWindow JavaScript injection."""
	# Special handling: Collect wind array parameters (options.winds[0..5])
	var winds_array: Array[int] = []
	var wind_keys_processed: Array[String] = []
	
	for azgaar_key in params.keys():
		# Check if this is a wind array parameter (e.g., "options.winds[0]")
		if azgaar_key.begins_with("options.winds[") and azgaar_key.ends_with("]"):
			var index_str: String = azgaar_key.substr(azgaar_key.find("[") + 1, azgaar_key.find("]") - azgaar_key.find("[") - 1)
			var wind_index: int = int(index_str)
			var wind_value: int = int(params[azgaar_key])
			
			# Ensure array is large enough
			while winds_array.size() <= wind_index:
				winds_array.append(0)
			winds_array[wind_index] = wind_value
			wind_keys_processed.append(azgaar_key)
	
	# If we collected wind values, set the winds array in Azgaar
	if winds_array.size() > 0:
		var winds_strs: Array[String] = []
		for wind_val in winds_array:
			winds_strs.append(str(wind_val))
		var winds_js: String = "[%s]" % ",".join(winds_strs)
		var js_code: String = """
			(function() {
				try {
					var iframe = document.getElementById('%s');
					if (iframe && iframe.contentWindow && iframe.contentWindow.azgaar && iframe.contentWindow.azgaar.options) {
						iframe.contentWindow.azgaar.options.winds = %s;
					}
				} catch (e) {
					console.error('[WorldBuilder] Error setting winds:', e);
				}
			})();
		""" % [IFRAME_ID, winds_js]
		
		if web_view.has_method("execute_js"):
			web_view.execute_js(js_code)
		elif web_view.has_method("eval"):
			web_view.eval(js_code)
		MythosLogger.debug("WorldBuilderWebController", "Synced winds array to Azgaar via iframe", {"winds": winds_array})
	
	# Inject each parameter (skip wind array indices as they're handled above)
	for azgaar_key in params:
		if azgaar_key in wind_keys_processed:
			continue  # Skip, already handled
		
		var value = params[azgaar_key]
		
		# Format value based on type
		var js_value: String
		if value is String:
			js_value = '"%s"' % value.replace('"', '\\"')
		elif value is bool:
			js_value = "true" if value else "false"
		elif value is int or value is float:
			js_value = str(value)
		else:
			js_value = str(value)
		
		# Execute JS to set parameter via iframe
		var js_code: String
		if azgaar_key.begins_with("options"):
			# Already has "options" prefix
			js_code = """
				(function() {
					try {
						var iframe = document.getElementById('%s');
						if (iframe && iframe.contentWindow && iframe.contentWindow.azgaar && iframe.contentWindow.azgaar.options) {
							iframe.contentWindow.azgaar.%s = %s;
						}
					} catch (e) {
						console.error('[WorldBuilder] Error setting param:', e);
					}
				})();
			""" % [IFRAME_ID, azgaar_key, js_value]
		else:
			# Standard option path
			js_code = """
				(function() {
					try {
						var iframe = document.getElementById('%s');
						if (iframe && iframe.contentWindow && iframe.contentWindow.azgaar && iframe.contentWindow.azgaar.options) {
							iframe.contentWindow.azgaar.options.%s = %s;
						}
					} catch (e) {
						console.error('[WorldBuilder] Error setting param:', e);
					}
				})();
			""" % [IFRAME_ID, azgaar_key, js_value]
		
		if web_view.has_method("execute_js"):
			web_view.execute_js(js_code)
		elif web_view.has_method("eval"):
			web_view.eval(js_code)
	
	MythosLogger.debug("WorldBuilderWebController", "Synced parameters to Azgaar via iframe", {"param_count": params.size(), "winds_processed": winds_array.size()})


func _generate_initial_default_map() -> void:
	"""Generate initial default map when World Builder loads via iframe."""
	if not azgaar_ready_via_iframe:
		MythosLogger.warn("WorldBuilderWebController", "Azgaar not ready yet via iframe, attempting generation anyway")
	
	# Build default parameters from step definitions
	var default_params: Dictionary = {}
	
	# Load defaults from step definitions
	if not step_definitions.is_empty():
		var steps: Array = step_definitions.get("steps", [])
		for step_dict in steps:
			var parameters: Array = step_dict.get("parameters", [])
			for param_dict in parameters:
				# Only include curated parameters with defaults
				if param_dict.get("curated", true) == true and param_dict.has("default"):
					var azgaar_key: String = param_dict.get("azgaar_key", "")
					if not azgaar_key.is_empty():
						default_params[azgaar_key] = param_dict["default"]
	
	# Ensure we have at least basic defaults if JSON didn't provide them
	if default_params.is_empty():
		MythosLogger.warn("WorldBuilderWebController", "No defaults from JSON, using hardcoded defaults")
		default_params = {
			"templateInput": "continents",
			"pointsInput": 5,
			"mapWidthInput": 960,
			"mapHeightInput": 540
		}
	
	# Use random seed for initial generation if optionsSeed not already set
	if not default_params.has("optionsSeed"):
		var initial_seed: int = randi() % 999999999 + 1
		default_params["optionsSeed"] = initial_seed
	
	# Clamp parameters
	var clamped_params: Dictionary = {}
	for key in default_params.keys():
		var value = default_params[key]
		clamped_params[key] = _clamp_parameter_value(key, value)
	
	MythosLogger.info("WorldBuilderWebController", "Triggering initial default map generation", {
		"params_count": clamped_params.size(),
		"optionsSeed": clamped_params.get("optionsSeed", "not_set"),
		"sample_params": _get_sample_params(clamped_params, 5)
	})
	
	# Sync parameters to Azgaar via iframe
	_sync_params_to_azgaar_iframe(clamped_params)
	
	# Trigger generation via iframe
	var generate_script: String = """
		(function() {
			try {
				var iframe = document.getElementById('%s');
				if (iframe && iframe.contentWindow && iframe.contentWindow.azgaar && 
				    typeof iframe.contentWindow.azgaar.generate === 'function') {
					iframe.contentWindow.azgaar.generate();
					return 'generated';
				}
				return 'error: azgaar not available';
			} catch (e) {
				console.error('[WorldBuilder] Error triggering initial generation:', e);
				return 'error: ' + e.message;
			}
		})();
	""" % IFRAME_ID
	
	if web_view.has_method("execute_js"):
		var result = web_view.execute_js(generate_script)
		if result == "generated":
			MythosLogger.info("WorldBuilderWebController", "Initial generation triggered via iframe")
		else:
			MythosLogger.warn("WorldBuilderWebController", "Failed to trigger initial generation via iframe", {"result": result})
	elif web_view.has_method("eval"):
		web_view.eval(generate_script)
		MythosLogger.info("WorldBuilderWebController", "Initial generation triggered via iframe (eval)")
	
	# Also update current_params so UI reflects the defaults
	current_params = clamped_params.duplicate()


func _handle_generation_complete(data: Dictionary) -> void:
	"""Handle generation_complete IPC message from WebView."""
	MythosLogger.info("WorldBuilderWebController", "Generation completed", {"timestamp": data.get("timestamp", "unknown")})
	
	# Stop timeout timer if running
	if generation_timeout_timer and not generation_timeout_timer.is_stopped():
		generation_timeout_timer.stop()
	
	# Send final progress update to reset UI state
	send_progress_update(100.0, "Generation complete!", false)


func _handle_generation_failed(data: Dictionary) -> void:
	"""Handle generation_failed IPC message from WebView."""
	var error_msg: String = data.get("error", "Unknown error")
	MythosLogger.error("WorldBuilderWebController", "Generation failed", {"error": error_msg, "timestamp": data.get("timestamp", "unknown")})
	
	# Stop timeout timer if running
	if generation_timeout_timer and not generation_timeout_timer.is_stopped():
		generation_timeout_timer.stop()
	
	# Send error progress update to reset UI state
	send_progress_update(0.0, "Error: Generation failed - %s" % error_msg, false)


func _start_generation_timeout() -> void:
	"""Start timeout timer as fallback if generation completion not detected."""
	# Stop existing timer if any
	if generation_timeout_timer:
		if not generation_timeout_timer.is_stopped():
			generation_timeout_timer.stop()
		generation_timeout_timer.queue_free()
	
	# Create new timeout timer
	generation_timeout_timer = Timer.new()
	generation_timeout_timer.one_shot = true
	generation_timeout_timer.wait_time = GENERATION_TIMEOUT_SECONDS
	generation_timeout_timer.timeout.connect(_on_generation_timeout)
	add_child(generation_timeout_timer)
	generation_timeout_timer.start()
	
	MythosLogger.debug("WorldBuilderWebController", "Started generation timeout timer", {"timeout_seconds": GENERATION_TIMEOUT_SECONDS})


func _on_generation_timeout() -> void:
	"""Timeout fallback - reset UI state if completion not detected."""
	MythosLogger.warn("WorldBuilderWebController", "Generation timeout - resetting UI state as fallback")
	
	# Reset UI state
	send_progress_update(0.0, "Generation timeout - please try again", false)


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

func _print_scene_tree_diagnostics() -> void:
	"""Print detailed scene tree structure for diagnostics."""
	MythosLogger.info("WorldBuilderWebController", "=== SCENE TREE DIAGNOSTICS ===")
	MythosLogger.info("WorldBuilderWebController", "Current node", {
		"name": name,
		"path": get_path(),
		"class": get_class(),
		"parent": get_parent().name if get_parent() else "NONE"
	})
	
	# Log all children
	var children = get_children()
	MythosLogger.info("WorldBuilderWebController", "Direct children", {"count": children.size()})
	for i in range(children.size()):
		var child = children[i]
		MythosLogger.info("WorldBuilderWebController", "  Child[%d]" % i, {
			"name": child.name,
			"path": child.get_path(),
			"class": child.get_class(),
			"has_trigger_method": child.has_method("trigger_generation_with_options")
		})
	
	# Log parent and siblings
	var parent = get_parent()
	if parent:
		MythosLogger.info("WorldBuilderWebController", "Parent node", {
			"name": parent.name,
			"path": parent.get_path(),
			"class": parent.get_class()
		})
		var siblings = parent.get_children()
		MythosLogger.info("WorldBuilderWebController", "Siblings", {"count": siblings.size()})
		for i in range(siblings.size()):
			var sibling = siblings[i]
			MythosLogger.info("WorldBuilderWebController", "  Sibling[%d]" % i, {
				"name": sibling.name,
				"path": sibling.get_path(),
				"class": sibling.get_class(),
				"has_trigger_method": sibling.has_method("trigger_generation_with_options")
			})
		
		# Log grandparent if exists
		var grandparent = parent.get_parent()
		if grandparent:
			MythosLogger.info("WorldBuilderWebController", "Grandparent node", {
				"name": grandparent.name,
				"path": grandparent.get_path(),
				"class": grandparent.get_class()
			})
			var cousins = grandparent.get_children()
			MythosLogger.info("WorldBuilderWebController", "Cousins (grandparent children)", {"count": cousins.size()})
			for i in range(cousins.size()):
				var cousin = cousins[i]
				MythosLogger.info("WorldBuilderWebController", "  Cousin[%d]" % i, {
					"name": cousin.name,
					"path": cousin.get_path(),
					"class": cousin.get_class(),
					"has_trigger_method": cousin.has_method("trigger_generation_with_options")
				})
	
	# Check for WebView nodes
	var webview_nodes = _find_all_webview_nodes(self)
	MythosLogger.info("WorldBuilderWebController", "WebView nodes found", {"count": webview_nodes.size()})
	for i in range(webview_nodes.size()):
		var wv = webview_nodes[i]
		MythosLogger.info("WorldBuilderWebController", "  WebView[%d]" % i, {
			"name": wv.name,
			"path": wv.get_path(),
			"parent": wv.get_parent().name if wv.get_parent() else "NONE"
		})
	
	MythosLogger.info("WorldBuilderWebController", "=== END SCENE TREE DIAGNOSTICS ===")


func _find_all_webview_nodes(node: Node) -> Array:
	"""Recursively find all WebView nodes in the scene tree."""
	var webviews: Array = []
	if node.get_class() == "WebView":
		webviews.append(node)
	for child in node.get_children():
		webviews.append_array(_find_all_webview_nodes(child))
	return webviews


func _print_azgaar_search_diagnostics() -> void:
	"""Print detailed diagnostics about Azgaar iframe access (replaces node search)."""
	MythosLogger.info("WorldBuilderWebController", "=== AZGAAR IFRAME DIAGNOSTICS ===")
	MythosLogger.info("WorldBuilderWebController", "Iframe ID", {"iframe_id": IFRAME_ID})
	MythosLogger.info("WorldBuilderWebController", "Azgaar ready via iframe", {"ready": azgaar_ready_via_iframe})
	
	# Check iframe existence via JS
	var check_script: String = """
		(function() {
			var iframe = document.getElementById('%s');
			if (iframe) {
				return {
					exists: true,
					src: iframe.src,
					loaded: iframe.contentDocument ? 'yes' : 'no'
				};
			}
			return {exists: false};
		})();
	""" % IFRAME_ID
	
	if web_view.has_method("execute_js"):
		var result = web_view.execute_js(check_script)
		MythosLogger.info("WorldBuilderWebController", "Iframe check result", {"result": result})
	elif web_view.has_method("eval"):
		web_view.eval(check_script)
		MythosLogger.info("WorldBuilderWebController", "Iframe check executed via eval")
	
	MythosLogger.info("WorldBuilderWebController", "=== END AZGAAR IFRAME DIAGNOSTICS ===")


func _find_nodes_with_method(node: Node, method_name: String) -> Array:
	"""Recursively find all nodes with a specific method."""
	var results: Array = []
	if node.has_method(method_name):
		results.append(node)
	for child in node.get_children():
		results.append_array(_find_nodes_with_method(child, method_name))
	return results


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


func _test_fork_headless_generation() -> void:
	"""Debug test: Run headless Azgaar fork generation with fixed parameters."""
	MythosLogger.info("WorldBuilderWebController", "=== DEBUG TEST: Fork Headless Generation ===")
	
	if not web_view:
		MythosLogger.error("WorldBuilderWebController", "Cannot run test - WebView is null")
		return
	
	# Fork template already loaded in _ready() if DEBUG_TEST_FORK is true
	MythosLogger.info("WorldBuilderWebController", "Fork template should be loaded, waiting for initialization...")
	
	# Wait a bit more for fork to fully initialize
	await get_tree().create_timer(2.0).timeout
	
	# Test parameters (small map for speed)
	var test_options: Dictionary = {
		"seed": "12345",
		"mapWidth": 512,
		"mapHeight": 512,
		"cellsDesired": 3000,
		"template": "continents",
		"heightExponent": 1.0,
		"allowErosion": true,
		"plateCount": 5,
		"statesNumber": 10,
		"cultures": 8,
		"religionsNumber": 5
	}
	
	MythosLogger.info("WorldBuilderWebController", "Triggering test generation", {"options": test_options})
	
	# Execute test generation via JavaScript
	var test_script: String = """
		(async function() {
			try {
				console.log('[Test] Checking AzgaarGenesis availability...');
				if (!window.AzgaarGenesis || !window.AzgaarGenesis.initialized) {
					console.error('[Test] AzgaarGenesis not initialized');
					return 'error: not initialized';
				}
				
				console.log('[Test] Loading options...');
				window.AzgaarGenesis.loadOptions(%s);
				
				console.log('[Test] Generating map...');
				const startTime = performance.now();
				const data = window.AzgaarGenesis.generateMap(window.AzgaarGenesis.Delaunator);
				const generateTime = performance.now() - startTime;
				
				console.log('[Test] Generation complete:', { seed: data.seed, time: generateTime });
				
				console.log('[Test] Extracting JSON...');
				const json = window.AzgaarGenesis.getMapData();
				
				console.log('[Test] JSON extracted, keys:', Object.keys(json));
				
				// Send to Godot
				if (window.GodotBridge && window.GodotBridge.postMessage) {
					window.GodotBridge.postMessage('map_generated', {
						data: json,
						seed: data.seed,
						generationTime: generateTime
					});
					return 'success';
				} else {
					return 'error: no GodotBridge';
				}
			} catch (error) {
				console.error('[Test] Generation error:', error);
				if (window.GodotBridge && window.GodotBridge.postMessage) {
					window.GodotBridge.postMessage('map_generation_failed', {
						error: error.message,
						stack: error.stack
					});
				}
				return 'error: ' + error.message;
			}
		})();
	""" % JSON.stringify(test_options)
	
	if web_view.has_method("execute_js"):
		var result = web_view.execute_js(test_script)
		MythosLogger.info("WorldBuilderWebController", "Test generation triggered", {"result": result})
	elif web_view.has_method("eval"):
		web_view.eval(test_script)
		MythosLogger.info("WorldBuilderWebController", "Test generation triggered via eval")


func _handle_map_generated(data: Dictionary) -> void:
	"""Handle successful map generation from fork."""
	MythosLogger.info("WorldBuilderWebController", "=== MAP GENERATED (Fork Test) ===")
	
	var map_data: Dictionary = data.get("data", {})
	var seed_value: String = data.get("seed", "")
	var gen_time: float = data.get("generationTime", 0.0)
	
	# Store for analysis
	test_json_data = map_data
	
	# Print top-level keys
	var top_keys: Array = map_data.keys()
	MythosLogger.info("WorldBuilderWebController", "JSON Top-Level Keys", {"keys": top_keys, "count": top_keys.size()})
	
	# Print structure summary
	if map_data.has("settings"):
		var settings: Dictionary = map_data.get("settings", {})
		MythosLogger.info("WorldBuilderWebController", "Settings", {"keys": settings.keys()})
	
	if map_data.has("grid"):
		var grid: Dictionary = map_data.get("grid", {})
		var grid_keys: Array = grid.keys()
		MythosLogger.info("WorldBuilderWebController", "Grid", {"keys": grid_keys})
		
		if grid.has("cells"):
			var cells: Dictionary = grid.get("cells", {})
			var cell_keys: Array = cells.keys()
			MythosLogger.info("WorldBuilderWebController", "Grid.Cells", {"keys": cell_keys})
			if cells.has("h"):
				var heights: Array = cells.get("h", [])
				MythosLogger.info("WorldBuilderWebController", "Grid.Cells.Heights", {"count": heights.size(), "sample": heights.slice(0, 5) if heights.size() > 5 else heights})
		
		if grid.has("points"):
			var points: Array = grid.get("points", [])
			MythosLogger.info("WorldBuilderWebController", "Grid.Points", {"count": points.size(), "sample": points.slice(0, 2) if points.size() > 2 else points})
	
	if map_data.has("pack"):
		var pack: Dictionary = map_data.get("pack", {})
		var pack_keys: Array = pack.keys()
		MythosLogger.info("WorldBuilderWebController", "Pack", {"keys": pack_keys})
		
		if pack.has("cells"):
			var pack_cells: Dictionary = pack.get("cells", {})
			var pack_cell_keys: Array = pack_cells.keys()
			MythosLogger.info("WorldBuilderWebController", "Pack.Cells", {"keys": pack_cell_keys})
		
		if pack.has("biomes"):
			var biomes: Array = pack.get("biomes", [])
			MythosLogger.info("WorldBuilderWebController", "Pack.Biomes", {"count": biomes.size(), "sample": biomes.slice(0, 5) if biomes.size() > 5 else biomes})
		
		if pack.has("rivers"):
			var rivers: Array = pack.get("rivers", [])
			MythosLogger.info("WorldBuilderWebController", "Pack.Rivers", {"count": rivers.size()})
	
	# Save to file
	_save_test_json_to_file(map_data, seed_value)
	
	# Phase 3: Convert to heightmap and generate 2D preview
	_convert_and_preview_heightmap(map_data)
	
	MythosLogger.info("WorldBuilderWebController", "=== END MAP GENERATED ===", {
		"seed": seed_value,
		"generation_time_ms": gen_time,
		"json_size_bytes": JSON.stringify(map_data).length()
	})


func _handle_map_generation_failed(data: Dictionary) -> void:
	"""Handle map generation failure from fork."""
	var error_msg: String = data.get("error", "Unknown error")
	var stack: String = data.get("stack", "")
	
	MythosLogger.error("WorldBuilderWebController", "Map generation failed", {
		"error": error_msg,
		"stack": stack
	})
	
	push_error("Azgaar Fork Test Failed: " + error_msg)


func _save_test_json_to_file(json_data: Dictionary, seed: String) -> void:
	"""Save test JSON to user://debug/azgaar_sample_map.json"""
	# Create debug directory if needed
	var debug_dir := DirAccess.open("user://")
	if not debug_dir:
		MythosLogger.error("WorldBuilderWebController", "Cannot open user:// directory")
		return
	
	if not debug_dir.dir_exists("debug"):
		var err := debug_dir.make_dir("debug")
		if err != OK:
			MythosLogger.error("WorldBuilderWebController", "Failed to create debug directory", {"error": err})
			return
	
	# Save JSON file
	var file_path: String = "user://debug/azgaar_sample_map.json"
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		MythosLogger.error("WorldBuilderWebController", "Failed to open file for writing", {
			"path": file_path,
			"error": FileAccess.get_open_error()
		})
		return
	
	var json_string := JSON.stringify(json_data, "  ", false)
	file.store_string(json_string)
	file.close()
	
	MythosLogger.info("WorldBuilderWebController", "Saved test JSON to file", {
		"path": file_path,
		"size_bytes": json_string.length(),
		"seed": seed
	})
	
	print("=== AZGAAR TEST JSON SAVED ===")
	print("File: " + file_path)
	print("Size: " + str(json_string.length()) + " bytes")
	print("Seed: " + seed)


func _convert_and_preview_heightmap(json_data: Dictionary) -> void:
	"""Convert Azgaar JSON to heightmap Image and save preview PNG (Phase 3)."""
	MythosLogger.info("WorldBuilderWebController", "Converting JSON to heightmap for 2D preview")
	
	var converter: AzgaarDataConverter = AzgaarDataConverter.new()
	var heightmap_img: Image = converter.convert_to_heightmap(json_data)
	
	if heightmap_img.is_empty():
		MythosLogger.error("WorldBuilderWebController", "Failed to convert JSON to heightmap")
		return
	
	var img_size: Vector2i = heightmap_img.get_size()
	MythosLogger.info("WorldBuilderWebController", "Heightmap converted", {
		"width": img_size.x,
		"height": img_size.y,
		"format": heightmap_img.get_format()
	})
	
	# Create debug directory if needed
	var debug_dir := DirAccess.open("user://")
	if not debug_dir:
		MythosLogger.error("WorldBuilderWebController", "Cannot open user:// directory")
		return
	
	if not debug_dir.dir_exists("debug"):
		var err := debug_dir.make_dir("debug")
		if err != OK:
			MythosLogger.error("WorldBuilderWebController", "Failed to create debug directory", {"error": err})
			return
	
	# Convert heightmap to RGB8 format for PNG export (heightmap is FORMAT_RF)
	var preview_img: Image = Image.create(img_size.x, img_size.y, false, Image.FORMAT_RGB8)
	for y in range(img_size.y):
		for x in range(img_size.x):
			var height_color: Color = heightmap_img.get_pixel(x, y)
			var height_value: float = height_color.r  # FORMAT_RF stores height in red channel
			# Convert normalized height (0-1) to grayscale RGB
			preview_img.set_pixel(x, y, Color(height_value, height_value, height_value, 1.0))
	
	# Save PNG preview
	var png_path: String = "user://debug/heightmap_preview.png"
	var save_err: Error = preview_img.save_png(png_path)
	if save_err != OK:
		MythosLogger.error("WorldBuilderWebController", "Failed to save heightmap PNG", {
			"path": png_path,
			"error": save_err
		})
		return
	
	MythosLogger.info("WorldBuilderWebController", "Heightmap PNG preview saved", {
		"path": png_path,
		"size": img_size
	})
	print("=== HEIGHTMAP PREVIEW SAVED ===")
	print("File: " + png_path)
	print("Size: " + str(img_size.x) + "x" + str(img_size.y))
	
	# Optional: Integrate with MapMakerModule for live 2D preview
	# Note: MapRenderer is currently deprecated, so we'll skip this for now
	# Future: Create WorldMapData and pass to MapMakerModule if needed
