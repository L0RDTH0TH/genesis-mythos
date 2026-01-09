# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderWebController.gd
# ║ Desc: Handles WebView for World Builder UI wizard with Alpine.js
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name WorldBuilderWebController
extends Control

## Reference to the WebView node (for UI)
@onready var web_view: WebView = $WebView

## Flag to track if fork is ready
var fork_ready: bool = false

## Flag to track if full Azgaar UI is ready
var azgaar_full_ready: bool = false

## Current mode: "fork" (modular) or "full" (original Azgaar UI)
var current_mode: String = "fork"
const MODE_FORK: String = "fork"
const MODE_FULL: String = "full"

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

## Force SVG rendering by default (deprecate PNG heightmap fallback)
const USE_SVG_DEFAULT: bool = true

## Fork mode is now the default - no debug flag needed
var test_json_data: Dictionary = {}  # Store test JSON output

## Debug flags for console message filtering
const DEBUG_WEB_CONSOLE_VERBOSE: bool = false  # Set to true only when actively debugging JS
const SUPPRESS_VERBOSE_WEB_CONSOLE: bool = true  # Default true to prevent overflow
const MAX_CONSOLE_MESSAGE_LENGTH: int = 2000  # Maximum message length before truncation

## Compiled regex for detecting large number arrays (lazy initialization)
var array_pattern_regex: RegEx = null

## Archetype presets loaded from JSON (data-driven)
var archetype_presets: Dictionary = {}


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
	
	# Load archetype presets from JSON
	_load_archetype_presets()
	
	# Load the World Builder HTML file (default: fork mode)
	# Can be switched to full Azgaar UI mode via set_mode()
	current_mode = MODE_FORK
	var html_url: String = "res://assets/ui_web/templates/world_builder.html"
	web_view.load_url(html_url)
	MythosLogger.info("WorldBuilderWebController", "Loaded World Builder HTML (fork mode)", {"url": html_url, "mode": current_mode})
	
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
	
	# Note: Azgaar fork is loaded via world_builder.html (clean integration - January 2026)
	# Fork will signal readiness via IPC message 'fork_ready' or 'map_generated'
	MythosLogger.info("WorldBuilderWebController", "Azgaar fork mode enabled - clean integration (January 2026)")
	
	# Wait for page to load, then inject theme/constants
	# Alpine.js readiness will be signaled via IPC message 'alpine_ready'
	await get_tree().create_timer(0.5).timeout
	_inject_theme_and_constants()
	
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


func _load_archetype_presets() -> void:
	"""Loads archetype presets from JSON file."""
	var file: FileAccess = FileAccess.open("res://data/config/archetype_azgaar_presets.json", FileAccess.READ)
	if file:
		var json_text: String = file.get_as_text()
		file.close()
		var json: JSON = JSON.new()
		var parse_result: Variant = json.parse(json_text)
		if parse_result == OK:
			archetype_presets = json.data
			var keys_array: Array = archetype_presets.keys()
			MythosLogger.info("WorldBuilderWebController", "Archetype presets loaded from JSON", {"archetypes": keys_array})
		else:
			MythosLogger.error("WorldBuilderWebController", "Failed to parse archetype presets JSON: %s" % json.get_error_message())
	else:
		MythosLogger.error("WorldBuilderWebController", "Failed to open archetype presets JSON file.")




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
	for archetype_name in archetype_presets.keys():
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
		"fork_ready":
			_handle_fork_ready(message_data)
		"azgaar_full_ready":
			_handle_azgaar_full_ready(message_data)
		"options_set":
			_handle_options_set(message_data)
		"svg_preview_ready":
			_handle_svg_preview(message_data)
		"svg_failed":
			_handle_svg_failed(message_data)
		"render_failed":
			_handle_render_failed(message_data)
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
	
	# Wait for fork initialization (fork_ready IPC), then trigger auto-generation
	# Fork will send fork_ready IPC after module script loads
	# If fork_ready not received within 3 seconds, proceed anyway (fork might be ready but signal missed)
	await get_tree().create_timer(3.0).timeout
	if not fork_ready:
		MythosLogger.warn("WorldBuilderWebController", "fork_ready IPC not received, proceeding with auto-generation anyway")
	_trigger_auto_generation_on_load()


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
	
	var preset: Dictionary = archetype_presets.get(archetype_name, {}).duplicate()
	if not preset.is_empty():
		# Apply all keys from JSON preset directly (JSON already uses Azgaar keys)
		# Clamp and apply each parameter
		for key in preset.keys():
			var value = preset[key]
			var clamped_value = _clamp_parameter_value(key, value)
			current_params[key] = clamped_value
		
		# Send params update to WebView
		_send_params_update()
		MythosLogger.info("WorldBuilderWebController", "Loaded archetype preset", {"archetype": archetype_name, "params": preset})
		
		# Auto-trigger generation after archetype change
		await get_tree().create_timer(0.1).timeout  # Small delay for UI update
		_handle_generate({"params": current_params})
	else:
		MythosLogger.warn("WorldBuilderWebController", "Archetype preset not found", {"archetype": archetype_name})


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
	"""Handle generate message from WebView - use fork mode first, fallback to iframe."""
	MythosLogger.info("WorldBuilderWebController", "Starting map generation...")
	MythosLogger.debug("WorldBuilderWebController", "_handle_generate() called", {"data_keys": data.keys()})
	
	var params: Dictionary = data.get("params", {})
	
	MythosLogger.debug("WorldBuilderWebController", "Received params from WebView", {
		"params_count": params.size(), 
		"params": params,
		"optionsSeed": params.get("optionsSeed", "not_set")
	})
	
	current_params.merge(params)
	
	# Ensure all default parameters from step definitions are included (if missing)
	# This ensures mapWidthInput, mapHeightInput, pointsInput, etc. are always present
	if not step_definitions.is_empty():
		var steps: Array = step_definitions.get("steps", [])
		for step_dict in steps:
			var parameters: Array = step_dict.get("parameters", [])
			for param_dict in parameters:
				# Only include curated parameters with defaults
				if param_dict.get("curated", true) == true and param_dict.has("default"):
					var azgaar_key: String = param_dict.get("azgaar_key", "")
					if not azgaar_key.is_empty() and not current_params.has(azgaar_key):
						current_params[azgaar_key] = param_dict["default"]
						MythosLogger.debug("WorldBuilderWebController", "Added missing default parameter", {"key": azgaar_key, "value": param_dict["default"]})
	
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
	
	# Force SVG rendering mode (default enabled)
	current_params["use_svg"] = USE_SVG_DEFAULT
	MythosLogger.info("WorldBuilderWebController", "SVG rendering mode enabled", {"use_svg": USE_SVG_DEFAULT})
	
	MythosLogger.info("WorldBuilderWebController", "Generation requested", {
		"params_count": current_params.size(), 
		"optionsSeed": current_params.get("optionsSeed", "not_set"),
		"use_svg": current_params.get("use_svg", false),
		"sample_params": _get_sample_params(current_params, 5)
	})
	
	send_progress_update(10.0, "Checking mode availability...", true)
	
	# Check current mode and use appropriate generation method
	if current_mode == MODE_FULL:
		# Full Azgaar UI mode - use GenesisAzgaar API
		if azgaar_full_ready:
			_trigger_full_azgaar_generation(current_params)
		else:
			MythosLogger.warn("WorldBuilderWebController", "Full Azgaar UI not ready yet, waiting...")
			send_progress_update(0.0, "Full Azgaar UI not ready, please wait...", false)
			return
	elif fork_ready:
		# Use fork mode (only mode - iframe removed in January 2026 clean integration)
		MythosLogger.info("WorldBuilderWebController", "Fork ready - generating via fork mode")
		_generate_via_fork(current_params)
	else:
		# Fork not ready - wait or show error
		MythosLogger.warn("WorldBuilderWebController", "Fork not ready (fork_ready flag is false) - cannot generate")
		send_progress_update(0.0, "Error: Azgaar fork not ready. Please wait for initialization.", false)


func _trigger_full_azgaar_generation(params: Dictionary) -> void:
	"""Generate map using full Azgaar UI mode (original Azgaar with menu system)."""
	MythosLogger.info("WorldBuilderWebController", "Generating via full Azgaar UI mode")
	
	if not web_view:
		MythosLogger.error("WorldBuilderWebController", "Cannot generate via full Azgaar - WebView is null")
		send_progress_update(0.0, "Error: WebView not available", false)
		return
	
	send_progress_update(20.0, "Setting options in full Azgaar UI...", true)
	
	# Convert params to Azgaar options format
	var azgaar_options: Dictionary = _convert_params_to_azgaar_options(params)
	MythosLogger.debug("WorldBuilderWebController", "Full Azgaar options prepared", {
		"options_keys": azgaar_options.keys(),
		"seed": azgaar_options.get("seed", "not_set")
	})
	
	# Set options and trigger generation via GenesisAzgaar API
	var set_options_script: String = """
		(function() {
			try {
				if (!window.GenesisAzgaar || !window.GenesisAzgaar.isReady()) {
					console.error('[Full Azgaar] GenesisAzgaar not ready');
					if (window.GodotBridge && window.GodotBridge.postMessage) {
						window.GodotBridge.postMessage('map_generation_failed', {
							error: 'Full Azgaar UI not ready'
						});
					}
					return 'error: not ready';
				}
				
				console.log('[Full Azgaar] Setting options...');
				window.GenesisAzgaar.setOptions(%s);
				
				console.log('[Full Azgaar] Triggering generation...');
				const startTime = performance.now();
				const result = window.GenesisAzgaar.generate();
				const generationTime = performance.now() - startTime;
				
				if (result) {
					console.log('[Full Azgaar] Generation triggered', { time: generationTime });
					return 'triggered';
				} else {
					console.error('[Full Azgaar] Generation failed');
					if (window.GodotBridge && window.GodotBridge.postMessage) {
						window.GodotBridge.postMessage('map_generation_failed', {
							error: 'Generation trigger failed'
						});
					}
					return 'error: generation failed';
				}
			} catch (error) {
				console.error('[Full Azgaar] Error:', error);
				if (window.GodotBridge && window.GodotBridge.postMessage) {
					window.GodotBridge.postMessage('map_generation_failed', {
						error: error.message,
						stack: error.stack
					});
				}
				return 'error: ' + error.message;
			}
		})();
	""" % [JSON.stringify(azgaar_options)]
	
	if web_view.has_method("execute_js"):
		var result = web_view.execute_js(set_options_script)
		send_progress_update(50.0, "Generating map (full Azgaar UI mode)...", true)
		MythosLogger.info("WorldBuilderWebController", "Full Azgaar generation triggered", {
			"result": result,
			"result_type": typeof(result)
		})
		if result != "triggered" and result != "success":
			MythosLogger.warn("WorldBuilderWebController", "Full Azgaar generation script returned unexpected result", {"result": result})
	elif web_view.has_method("eval"):
		web_view.eval(set_options_script)
		send_progress_update(50.0, "Generating map (full Azgaar UI mode)...", true)
		MythosLogger.info("WorldBuilderWebController", "Full Azgaar generation triggered (eval)")
	else:
		MythosLogger.error("WorldBuilderWebController", "Cannot execute JS - WebView method not available")
		send_progress_update(0.0, "Error: Cannot execute generation", false)


func _convert_params_to_azgaar_options(params: Dictionary) -> Dictionary:
	"""Convert UI params to full Azgaar options format (original Azgaar API)."""
	var options: Dictionary = {}
	
	# Map common parameters (same as fork, but use original Azgaar keys)
	if params.has("optionsSeed"):
		options["seed"] = str(int(params["optionsSeed"]))
	if params.has("mapWidthInput"):
		options["mapWidth"] = int(params["mapWidthInput"])
	if params.has("mapHeightInput"):
		options["mapHeight"] = int(params["mapHeightInput"])
	if params.has("templateInput"):
		options["template"] = params["templateInput"]
	if params.has("pointsInput"):
		options["points"] = int(params["pointsInput"])
	if params.has("religionsInput"):
		options["religionsNumber"] = int(params["religionsInput"])
	if params.has("culturesInput"):
		options["culturesNumber"] = int(params["culturesInput"])
	
	# Add other parameters directly (Azgaar will ignore unknown keys)
	for key in params.keys():
		if not options.has(key):
			options[key] = params[key]
	
	return options


func set_mode(mode: String) -> void:
	"""Switch between fork mode and full Azgaar UI mode."""
	if mode == MODE_FORK or mode == MODE_FULL:
		if current_mode == mode:
			MythosLogger.debug("WorldBuilderWebController", "Already in mode", {"mode": mode})
			return
		
		current_mode = mode
		var html_url: String = ""
		if mode == MODE_FULL:
			html_url = "res://assets/ui_web/azgaar_full/index.html"
			azgaar_full_ready = false  # Reset flag - will be set when ready IPC received
		else:
			html_url = "res://assets/ui_web/templates/world_builder.html"
			fork_ready = false  # Reset flag - will be set when ready IPC received
		
		if web_view:
			web_view.load_url(html_url)
			MythosLogger.info("WorldBuilderWebController", "Switched to mode", {"mode": mode, "url": html_url})
		else:
			MythosLogger.error("WorldBuilderWebController", "Cannot switch mode - WebView is null")
	else:
		MythosLogger.warn("WorldBuilderWebController", "Invalid mode", {"mode": mode, "valid_modes": [MODE_FORK, MODE_FULL]})


func _generate_via_fork(params: Dictionary) -> void:
	"""Generate map using Azgaar fork API (headless mode)."""
	MythosLogger.info("WorldBuilderWebController", "Generating via fork mode")
	
	# Verify fork is actually available before proceeding
	if not web_view:
		MythosLogger.error("WorldBuilderWebController", "Cannot generate via fork - WebView is null")
		send_progress_update(0.0, "Error: WebView not available", false)
		return
	
	send_progress_update(20.0, "Loading options into fork...", true)
	
	# Convert params to fork options format
	var fork_options: Dictionary = _convert_params_to_fork_options(params)
	MythosLogger.debug("WorldBuilderWebController", "Fork options prepared", {"options_keys": fork_options.keys(), "seed": fork_options.get("seed", "not_set")})
	
	# Trigger fork generation via JavaScript (use handleGenerateMap if available, else direct call)
	var generate_script: String = """
		(function() {
			try {
				// Use handleGenerateMap if available (from world_builder.html)
				if (window.handleGenerateMap && typeof window.handleGenerateMap === 'function') {
					console.log('[Fork] Using handleGenerateMap function');
					window.handleGenerateMap(%s);
					return 'triggered';
				}
				
				// Fallback: direct fork API call
				if (!window.AzgaarGenesis || !window.AzgaarGenesis.initialized) {
					console.error('[Fork] Fork not initialized');
					if (window.GodotBridge && window.GodotBridge.postMessage) {
						window.GodotBridge.postMessage('map_generation_failed', {
							error: 'Fork not initialized'
						});
					}
					return 'error: not initialized';
				}
				
				console.log('[Fork] Loading options...');
				window.AzgaarGenesis.loadOptions(%s);
				
				console.log('[Fork] Generating map...');
				const startTime = performance.now();
				const data = window.AzgaarGenesis.generateMap(window.AzgaarGenesis.Delaunator);
				const generateTime = performance.now() - startTime;
				
				console.log('[Fork] Generation complete:', { seed: data.seed, time: generateTime });
				
				console.log('[Fork] Extracting JSON...');
				const json = window.AzgaarGenesis.getMapData();
				
				console.log('[Fork] Rendering preview...');
				// Render preview to canvas
				const canvas = document.getElementById('azgaar-canvas');
				let previewDataUrl = '';
				if (canvas && window.AzgaarGenesis.renderPreview) {
					canvas.style.display = 'block';
					window.AzgaarGenesis.renderPreview(canvas);
					previewDataUrl = canvas.toDataURL('image/png');
				}
				
				// Send to Godot
				if (window.GodotBridge && window.GodotBridge.postMessage) {
					window.GodotBridge.postMessage('map_generated', {
						data: json,
						seed: data.seed,
						generationTime: generateTime,
						previewDataUrl: previewDataUrl
					});
					return 'success';
				}
				
				return 'error: no GodotBridge';
			} catch (error) {
				console.error('[Fork] Generation error:', error);
				if (window.GodotBridge && window.GodotBridge.postMessage) {
					window.GodotBridge.postMessage('map_generation_failed', {
						error: error.message,
						stack: error.stack
					});
				}
				return 'error: ' + error.message;
			}
		})();
	""" % [JSON.stringify(fork_options), JSON.stringify(fork_options)]
	
	if web_view.has_method("execute_js"):
		var result = web_view.execute_js(generate_script)
		send_progress_update(50.0, "Generating map (fork mode)...", true)
		MythosLogger.info("WorldBuilderWebController", "Fork generation triggered", {"result": result, "result_type": typeof(result)})
		if result != "triggered" and result != "success":
			MythosLogger.warn("WorldBuilderWebController", "Fork generation script returned unexpected result", {"result": result})
	elif web_view.has_method("eval"):
		web_view.eval(generate_script)
		send_progress_update(50.0, "Generating map (fork mode)...", true)
		MythosLogger.info("WorldBuilderWebController", "Fork generation triggered (eval)")
	else:
		MythosLogger.error("WorldBuilderWebController", "Cannot execute JS - WebView method not available")
		send_progress_update(0.0, "Error: Cannot execute generation", false)


func _convert_params_to_fork_options(params: Dictionary) -> Dictionary:
	"""Convert UI params to Azgaar fork options format."""
	var options: Dictionary = {}
	
	# Map common parameters
	if params.has("optionsSeed"):
		options["seed"] = str(int(params["optionsSeed"]))
	if params.has("mapWidthInput"):
		options["mapWidth"] = int(params["mapWidthInput"])
	if params.has("mapHeightInput"):
		options["mapHeight"] = int(params["mapHeightInput"])
	if params.has("templateInput"):
		options["template"] = params["templateInput"]
	if params.has("pointsInput"):
		# Pass points directly (1-13) - Azgaar fork maps to cells internally via CELLS_DENSITY_MAP
		var slider_val: int = int(params["pointsInput"])
		options["points"] = slider_val
	if params.has("heightExponentInput"):
		options["heightExponent"] = float(params["heightExponentInput"])
	if params.has("allowErosion"):
		options["allowErosion"] = bool(params["allowErosion"])
	if params.has("plateCount"):
		options["plateCount"] = int(params["plateCount"])
	if params.has("statesNumber"):
		options["statesNumber"] = int(params["statesNumber"])
	if params.has("culturesInput"):
		options["cultures"] = int(params["culturesInput"])
	if params.has("religionsNumber"):
		options["religionsNumber"] = int(params["religionsNumber"])
	if params.has("manorsInput"):
		options["burgs"] = int(params["manorsInput"])
	
	# Wind array - collect from params or use defaults
	var winds: Array[int] = []
	var has_winds: bool = false
	for i in range(6):
		var wind_key: String = "options.winds[%d]" % i
		if params.has(wind_key):
			winds.append(int(params[wind_key]))
			has_winds = true
		else:
			# Default wind values if not provided (Azgaar defaults)
			winds.append(0)
	
	# Always include winds array (Azgaar expects it)
	options["winds"] = winds
	if not has_winds:
		MythosLogger.debug("WorldBuilderWebController", "No wind parameters in params, using default winds (all zeros)")
	
	return options


# Removed _on_azgaar_ready() - replaced by _handle_azgaar_ready_ipc() for iframe-based access
# Removed _check_and_trigger_initial_generation() - replaced by polling in _handle_azgaar_loaded()




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
	for archetype_name in archetype_presets.keys():
		archetype_names.append(archetype_name)
	
	var response_data: Dictionary = {
		"archetype_names": archetype_names,
		"archetypes": archetype_presets
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
	"""Handle console messages from WebView (for debugging) with intelligent filtering to prevent overflow."""
	# Initialize regex pattern on first use (lazy initialization)
	if array_pattern_regex == null:
		array_pattern_regex = RegEx.create_from_string(r"^\d+(,\d+){100,}")
	
	# Truncate extremely long messages to prevent overflow
	var processed_message: String = message
	if processed_message.length() > MAX_CONSOLE_MESSAGE_LENGTH:
		var truncated_length: int = processed_message.length() - MAX_CONSOLE_MESSAGE_LENGTH
		processed_message = processed_message.substr(0, MAX_CONSOLE_MESSAGE_LENGTH) + " ... [TRUNCATED " + str(truncated_length) + " chars]"
	
	# Suppress verbose non-prefixed messages unless debug mode is enabled
	if SUPPRESS_VERBOSE_WEB_CONSOLE and not DEBUG_WEB_CONSOLE_VERBOSE:
		# Always allow messages with important prefixes or error/warning levels
		var has_important_prefix: bool = (
			processed_message.contains("[Genesis World Builder]") or 
			processed_message.contains("[Genesis Azgaar]") or 
			processed_message.contains("CORS") or 
			processed_message.contains("timeout") or
			processed_message.contains("ERROR") or
			processed_message.contains("WARN") or
			processed_message.contains("Error") or
			processed_message.contains("Warning")
		)
		
		# Check if message appears to be a large number array dump
		var is_likely_array_dump: bool = false
		if array_pattern_regex != null:
			var match_result = array_pattern_regex.search(processed_message)
			if match_result:
				is_likely_array_dump = true
		
		# Also check for very long comma-separated number patterns (heuristic)
		if not is_likely_array_dump and processed_message.length() > 500:
			# Count comma-separated numbers (simple heuristic)
			var comma_count: int = processed_message.count(",")
			var digit_count: int = 0
			for i in range(processed_message.length()):
				if processed_message[i].is_valid_int():
					digit_count += 1
			# If message is mostly digits and commas, likely an array dump
			if comma_count > 50 and (digit_count + comma_count) > (processed_message.length() * 0.8):
				is_likely_array_dump = true
		
		# Silently drop obvious array dumps unless they're errors/warnings
		if is_likely_array_dump and not has_important_prefix and level < 2:  # level 2+ = WARN, 3 = ERROR
			return  # Silently suppress
	
	# Filter for relevant messages or forward if debug mode enabled
	if DEBUG_WEB_CONSOLE_VERBOSE or processed_message.contains("[Genesis World Builder]") or processed_message.contains("[Genesis Azgaar]") or processed_message.contains("CORS") or processed_message.contains("timeout") or processed_message.contains("ERROR") or processed_message.contains("WARN") or processed_message.contains("Error") or processed_message.contains("Warning"):
		match level:
			0:  # LOG_LEVEL_DEBUG
				MythosLogger.debug("WorldBuilderWebController", "WebView console", {"level": "debug", "message": processed_message, "source": source, "line": line})
			1:  # LOG_LEVEL_INFO
				MythosLogger.info("WorldBuilderWebController", "WebView console", {"level": "info", "message": processed_message, "source": source, "line": line})
			2:  # LOG_LEVEL_WARN
				MythosLogger.warn("WorldBuilderWebController", "WebView console", {"level": "warn", "message": processed_message, "source": source, "line": line})
			3:  # LOG_LEVEL_ERROR
				MythosLogger.error("WorldBuilderWebController", "WebView console", {"level": "error", "message": processed_message, "source": source, "line": line})
			_:
				MythosLogger.debug("WorldBuilderWebController", "WebView console", {"level": level, "message": processed_message, "source": source, "line": line})

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


func _find_nodes_with_method(node: Node, method_name: String) -> Array:
	"""Recursively find all nodes with a specific method."""
	var results: Array = []
	if node.has_method(method_name):
		results.append(node)
	for child in node.get_children():
		results.append_array(_find_nodes_with_method(child, method_name))
	return results


func send_progress_update(progress: float, status: String, is_generating: bool) -> void:
	"""Send progress update to WebView via post_message to avoid Rust binding conflicts."""
	if not web_view:
		return
	
	var update_data: Dictionary = {
		"type": "update",
		"data": {
			"update_type": "progress_update",
			"progress": progress,
			"status": status,
			"is_generating": is_generating
		}
	}
	
	MythosLogger.debug("WorldBuilderWebController", "Sending progress update", update_data["data"])
	
	# Use post_message instead of execute_js/eval to avoid Rust binding conflicts
	# This is safer when multiple calls happen in quick succession
	if web_view.has_method("post_message"):
		var json_string: String = JSON.stringify(update_data)
		# Use call_deferred to serialize WebView access and prevent concurrent binding
		call_deferred("_post_message_safe", json_string)
	else:
		# Fallback to execute_js with deferred call if post_message not available
		var update_script: String = """
			if (window.GodotBridge && window.GodotBridge._handleUpdate) {
				window.GodotBridge._handleUpdate(%s);
			}
		""" % JSON.stringify(update_data["data"])
		call_deferred("_execute_js_safe", update_script)


func _post_message_safe(message: String) -> void:
	"""Safely post message to WebView (called deferred to avoid binding conflicts)."""
	if not web_view:
		return
	if web_view.has_method("post_message"):
		web_view.post_message(message)


func _execute_js_safe(script: String) -> void:
	"""Safely execute JS in WebView (called deferred to avoid binding conflicts)."""
	if not web_view:
		return
	if web_view.has_method("execute_js"):
		web_view.execute_js(script)
	elif web_view.has_method("eval"):
		web_view.eval(script)


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
	"""Handle successful map generation from fork or iframe."""
	MythosLogger.info("WorldBuilderWebController", "=== MAP GENERATED ===")
	
	# Stop timeout timer if running
	if generation_timeout_timer and not generation_timeout_timer.is_stopped():
		generation_timeout_timer.stop()
	
	var map_data: Dictionary = data.get("data", {})
	var seed_value: String = data.get("seed", "")
	var gen_time: float = data.get("generationTime", 0.0)
	var preview_data_url: String = data.get("previewDataUrl", "")
	var preview_svg_value = data.get("previewSvg", "")
	var preview_svg: String = ""
	if preview_svg_value is String:
		preview_svg = preview_svg_value
	
	# Store for analysis
	test_json_data = map_data
	
	# Print top-level keys
	var top_keys: Array = map_data.keys()
	MythosLogger.info("WorldBuilderWebController", "JSON Top-Level Keys", {"keys": top_keys, "count": top_keys.size()})
	
	# Save to file
	_save_test_json_to_file(map_data, seed_value)
	
	# Note: Layer enablement handled by fork (clean integration - January 2026)
	# Fork should provide complete data with all layers enabled by default
	
	# Handle SVG preview (primary method - clean fork integration January 2026)
	if not preview_svg.is_empty():
		_handle_svg_preview({
			"svgData": preview_svg,
			"width": data.get("width", 1024),
			"height": data.get("height", 768)
		})
		send_progress_update(90.0, "SVG preview ready!", true)
	else:
		# SVG missing - fork should always provide SVG (log error)
		MythosLogger.error("WorldBuilderWebController", "SVG missing from fork - fork may need update or rendering failed")
		# Fallback: Convert to heightmap for preview (deprecated, but useful for debugging)
		MythosLogger.warn("WorldBuilderWebController", "Using heightmap conversion fallback (SVG should be available)")
		_convert_and_preview_heightmap(map_data)
	
	send_progress_update(100.0, "Generation complete!", false)
	
	MythosLogger.info("WorldBuilderWebController", "=== END MAP GENERATED ===", {
		"seed": seed_value,
		"generation_time_ms": gen_time,
		"json_size_bytes": JSON.stringify(map_data).length(),
		"has_preview": not preview_data_url.is_empty()
	})


func _handle_map_generation_failed(data: Dictionary) -> void:
	"""Handle map generation failure from fork."""
	var error_msg: String = data.get("error", "Unknown error")
	var stack: String = data.get("stack", "")
	
	# Stop timeout timer if running
	if generation_timeout_timer and not generation_timeout_timer.is_stopped():
		generation_timeout_timer.stop()
	
	MythosLogger.error("WorldBuilderWebController", "Map generation failed", {
		"error": error_msg,
		"stack": stack
	})
	
	send_progress_update(0.0, "Error: Generation failed - %s" % error_msg, false)
	push_error("Azgaar Generation Failed: " + error_msg)


func _handle_fork_ready(data: Dictionary) -> void:
	"""Handle fork ready IPC message (modular fork mode)."""
	fork_ready = true
	current_mode = MODE_FORK
	MythosLogger.info("WorldBuilderWebController", "Fork is ready for generation - fork_ready IPC received, flag set to true")


func _handle_azgaar_full_ready(data: Dictionary) -> void:
	"""Handle azgaar_full_ready IPC message from WebView (full Azgaar UI mode)."""
	MythosLogger.info("WorldBuilderWebController", "Full Azgaar UI ready signal received from WebView")
	azgaar_full_ready = true
	current_mode = MODE_FULL


func _handle_options_set(data: Dictionary) -> void:
	"""Handle options_set IPC message from WebView (full Azgaar mode confirmation)."""
	var options: Dictionary = data.get("options", {})
	MythosLogger.info("WorldBuilderWebController", "Options set in full Azgaar UI", {"options_keys": options.keys()})


func _handle_svg_preview(data: Dictionary) -> void:
	"""Handle SVG preview ready IPC message."""
	var svg_data: String = data.get("svgData", "")
	var width: int = data.get("width", 960)  # Reduced default for testing
	var height: int = data.get("height", 540)  # Reduced default for testing
	var render_time: float = data.get("renderTime", 0.0)
	
	if svg_data.is_empty():
		MythosLogger.warn("WorldBuilderWebController", "SVG preview data is empty")
		return
	
	# Enhanced debug logging with timing information
	MythosLogger.info("WorldBuilderWebController", "SVG preview received", {
		"svg_length": svg_data.length(),
		"width": width,
		"height": height,
		"render_time_ms": render_time,
		"svg_size_kb": svg_data.length() / 1024.0
	})
	
	# Save SVG to file for debugging/audit
	_save_svg_to_file(svg_data)
	
	# Store SVG data for potential future use (e.g., export, conversion, etc.)
	# Note: SVG rendering is handled in the WebView HTML template via direct DOM manipulation (Fix 2)
	# Alpine.js x-html binding was removed to avoid blocking synchronous parsing
	
	# Optional: Could convert SVG to Image if needed for Godot display
	# For now, SVG is displayed directly in the WebView via direct innerHTML assignment
	
	# Log success message with timing details
	MythosLogger.info("WorldBuilderWebController", "SVG preview processed successfully", {
		"length": svg_data.length(),
		"characters": svg_data.length(),
		"width": width,
		"height": height,
		"render_time_ms": render_time,
		"svg_size_kb": "%.2f" % (svg_data.length() / 1024.0)
	})


func _handle_svg_failed(data: Dictionary) -> void:
	"""Handle SVG rendering failure IPC message."""
	var error_msg: String = data.get("error", "Unknown SVG rendering error")
	var stack: String = data.get("stack", "")
	
	MythosLogger.warn("WorldBuilderWebController", "SVG rendering failed in WebView", {
		"error": error_msg,
		"stack": stack
	})
	
	# SVG failed - will fall back to canvas/PNG in _handle_map_generated
	# This handler logs the failure for debugging
	send_progress_update(0.0, "Warning: SVG rendering failed, using fallback preview", true)


func _handle_render_failed(data: Dictionary) -> void:
	"""Handle render_failed IPC message with detailed error information."""
	const DEBUG_RENDERING: bool = false  # Set to true for verbose rendering logs
	const ENABLE_CANVAS_FALLBACK: bool = false  # Disabled due to WebView canvas limitations
	
	var render_type: String = data.get("type", "unknown")
	var error_msg: String = data.get("error", "Unknown rendering error")
	var stack: String = data.get("stack", "")
	var validation_errors: Array = data.get("validationErrors", [])
	
	if DEBUG_RENDERING:
		MythosLogger.debug("WorldBuilderWebController", "Render failed (detailed)", {
			"type": render_type,
			"error": error_msg,
			"stack": stack,
			"validation_errors": validation_errors
		})
	
	# Log based on render type with enhanced distinction
	match render_type:
		"validation":
			# Validation errors are the most critical - log prominently
			MythosLogger.error("WorldBuilderWebController", "DATA VALIDATION FAILED - Cannot render preview", {
				"errors": validation_errors,
				"error": error_msg,
				"count": validation_errors.size()
			})
			# Print each validation error prominently
			push_error("=== DATA VALIDATION FAILED ===")
			for i in range(validation_errors.size()):
				var err: String = str(validation_errors[i])
				push_error("  Validation Error %d: %s" % [i + 1, err])
				MythosLogger.error("WorldBuilderWebController", "Validation error detail", {"index": i + 1, "error": err})
			push_error("=== END VALIDATION ERRORS ===")
			# Don't push generic error message - already printed details above
		"svg":
			# SVG runtime errors - log with context
			MythosLogger.warn("WorldBuilderWebController", "SVG rendering failed (runtime error)", {
				"error": error_msg,
				"has_validation_errors": not validation_errors.is_empty(),
				"validation_errors": validation_errors if DEBUG_RENDERING else [],
				"stack": stack if DEBUG_RENDERING else ""
			})
			if not validation_errors.is_empty():
				push_error("SVG render failed: %s (Validation errors: %s)" % [error_msg, str(validation_errors)])
			else:
				push_error("SVG render failed: %s" % error_msg)
		"canvas":
			# Canvas errors - log but note that canvas is deprecated/unreliable
			MythosLogger.warn("WorldBuilderWebController", "Canvas rendering failed (fallback, deprecated)", {
				"error": error_msg,
				"canvas_fallback_enabled": ENABLE_CANVAS_FALLBACK,
				"validation_errors": validation_errors if DEBUG_RENDERING else [],
				"stack": stack if DEBUG_RENDERING else ""
			})
			if not validation_errors.is_empty():
				push_error("Canvas render failed (fallback): %s (Validation errors: %s)" % [error_msg, str(validation_errors)])
			else:
				push_error("Canvas render failed (fallback): %s" % error_msg)
		_:
			MythosLogger.warn("WorldBuilderWebController", "Rendering failed (unknown type)", {
				"type": render_type,
				"error": error_msg,
				"validation_errors": validation_errors
			})
			push_error("Render failed (%s): %s" % [render_type, error_msg])


func _trigger_auto_generation_on_load() -> void:
	"""Triggers automatic map generation on initial load with default archetype."""
	current_archetype = "High Fantasy"
	var data: Dictionary = {"archetype": current_archetype}
	_handle_load_archetype(data)  # This will load preset, update params, and trigger generation


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
	
	# Analyze JSON for cells.v statistics
	_analyze_json_cells_v(json_data)
	
	# Enhanced analysis: check states, cultures, burgs, religions, provinces
	_analyze_json_features(json_data)


func _analyze_json_cells_v(json_data: Dictionary) -> void:
	"""Analyze JSON map data for cells.v statistics (total cells, empty count, percentage, average vertex length)."""
	if not json_data.has("pack"):
		MythosLogger.warn("WorldBuilderWebController", "JSON analysis: missing 'pack' key in map data")
		return
	
	var pack: Dictionary = json_data.get("pack", {})
	if not pack.has("cells"):
		MythosLogger.warn("WorldBuilderWebController", "JSON analysis: missing 'cells' key in pack")
		return
	
	var cells: Dictionary = pack.get("cells", {})
	if not cells.has("v"):
		MythosLogger.warn("WorldBuilderWebController", "JSON analysis: missing 'cells.v' key")
		return
	
	var cells_v: Array = cells.get("v", [])
	var total_cells: int = cells_v.size()
	var empty_count: int = 0
	var total_vertex_length: float = 0.0
	
	for i in range(total_cells):
		var cell_v: Variant = cells_v[i]
		if cell_v == null or not cell_v is Array:
			empty_count += 1
		elif cell_v.is_empty():
			empty_count += 1
		else:
			total_vertex_length += float(cell_v.size())
	
	var percentage_empty: float = (float(empty_count) / float(total_cells) * 100.0) if total_cells > 0 else 0.0
	var valid_count: int = total_cells - empty_count
	var average_vertex_length: float = (total_vertex_length / float(valid_count)) if valid_count > 0 else 0.0
	
	MythosLogger.info("WorldBuilderWebController", "JSON cells.v analysis", {
		"total_cells": total_cells,
		"empty_count": empty_count,
		"valid_count": valid_count,
		"percentage_empty": percentage_empty,
		"average_vertex_length": average_vertex_length
	})
	
	print("=== AZGAAR JSON CELLS.V ANALYSIS ===")
	print("Total cells: %d" % total_cells)
	print("Empty cells: %d (%.2f%%)" % [empty_count, percentage_empty])
	print("Valid cells: %d" % valid_count)
	print("Average vertex length: %.2f" % average_vertex_length)


func _analyze_json_features(json_data: Dictionary) -> void:
	"""Analyze JSON map data for states, cultures, burgs, religions, and provinces counts."""
	if not json_data.has("pack"):
		MythosLogger.warn("WorldBuilderWebController", "JSON features analysis: missing 'pack' key in map data")
		return
	
	var pack: Dictionary = json_data.get("pack", {})
	
	# Analyze states
	var states_count: int = 0
	if pack.has("states") and pack.states is Array:
		states_count = pack.states.size()
		MythosLogger.info("WorldBuilderWebController", "JSON states analysis", {
			"states_count": states_count,
			"expected": current_params.get("statesNumber", 18)
		})
		if states_count < 5:
			MythosLogger.warn("WorldBuilderWebController", "WARNING: Very few states generated (%d < 5) - generation may be incomplete!" % states_count)
	else:
		MythosLogger.warn("WorldBuilderWebController", "JSON states analysis: missing 'states' array in pack")
	
	# Analyze cultures
	var cultures_count: int = 0
	if pack.has("cultures") and pack.cultures is Array:
		cultures_count = pack.cultures.size()
		MythosLogger.info("WorldBuilderWebController", "JSON cultures analysis", {
			"cultures_count": cultures_count,
			"expected": current_params.get("culturesInput", 12)
		})
		if cultures_count < 3:
			MythosLogger.warn("WorldBuilderWebController", "WARNING: Very few cultures generated (%d < 3) - generation may be incomplete!" % cultures_count)
	else:
		MythosLogger.warn("WorldBuilderWebController", "JSON cultures analysis: missing 'cultures' array in pack")
	
	# Analyze burgs
	var burgs_count: int = 0
	if pack.has("burgs") and pack.burgs is Array:
		burgs_count = pack.burgs.size()
		MythosLogger.info("WorldBuilderWebController", "JSON burgs analysis", {
			"burgs_count": burgs_count,
			"expected": current_params.get("manorsInput", 1000)
		})
		if burgs_count < 10:
			MythosLogger.warn("WorldBuilderWebController", "WARNING: Very few burgs generated (%d < 10) - generation may be incomplete!" % burgs_count)
	else:
		MythosLogger.warn("WorldBuilderWebController", "JSON burgs analysis: missing 'burgs' array in pack")
	
	# Analyze religions
	var religions_count: int = 0
	if pack.has("religions") and pack.religions is Array:
		religions_count = pack.religions.size()
		MythosLogger.info("WorldBuilderWebController", "JSON religions analysis", {
			"religions_count": religions_count,
			"expected": current_params.get("religionsNumber", 6)
		})
		if religions_count < 2:
			MythosLogger.warn("WorldBuilderWebController", "WARNING: Very few religions generated (%d < 2) - generation may be incomplete!" % religions_count)
	else:
		MythosLogger.warn("WorldBuilderWebController", "JSON religions analysis: missing 'religions' array in pack")
	
	# Analyze provinces
	var provinces_count: int = 0
	if pack.has("provinces") and pack.provinces is Array:
		provinces_count = pack.provinces.size()
		MythosLogger.info("WorldBuilderWebController", "JSON provinces analysis", {
			"provinces_count": provinces_count,
			"provinces_ratio": current_params.get("provincesRatio", 20)
		})
		if provinces_count < 5:
			MythosLogger.warn("WorldBuilderWebController", "WARNING: Very few provinces generated (%d < 5) - generation may be incomplete!" % provinces_count)
	else:
		MythosLogger.warn("WorldBuilderWebController", "JSON provinces analysis: missing 'provinces' array in pack")
	
	print("=== AZGAAR JSON FEATURES ANALYSIS ===")
	print("States: %d (expected: ~%d)" % [states_count, current_params.get("statesNumber", 18)])
	print("Cultures: %d (expected: ~%d)" % [cultures_count, current_params.get("culturesInput", 12)])
	print("Burgs: %d (expected: ~%d)" % [burgs_count, current_params.get("manorsInput", 1000)])
	print("Religions: %d (expected: ~%d)" % [religions_count, current_params.get("religionsNumber", 6)])
	print("Provinces: %d" % provinces_count)


# _enable_all_layers_before_svg() removed - clean fork (January 2026) handles layers internally
# Fork should provide complete data with all layers enabled by default


func _save_svg_to_file(svg_data: String) -> void:
	"""Save SVG string to user://debug/azgaar_sample_svg.svg"""
	# Create debug directory if needed
	var debug_dir := DirAccess.open("user://")
	if not debug_dir:
		MythosLogger.error("WorldBuilderWebController", "Cannot open user:// directory for SVG save")
		return
	
	if not debug_dir.dir_exists("debug"):
		var err := debug_dir.make_dir("debug")
		if err != OK:
			MythosLogger.error("WorldBuilderWebController", "Failed to create debug directory for SVG", {"error": err})
			return
	
	# Save SVG file
	var file_path: String = "user://debug/azgaar_sample_svg.svg"
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		MythosLogger.error("WorldBuilderWebController", "Failed to open SVG file for writing", {
			"path": file_path,
			"error": FileAccess.get_open_error()
		})
		return
	
	file.store_string(svg_data)
	file.close()
	
	MythosLogger.info("WorldBuilderWebController", "Saved SVG to file", {
		"path": file_path,
		"size_bytes": svg_data.length()
	})
	
	print("=== AZGAAR SVG SAVED ===")
	print("File: " + file_path)
	print("Size: " + str(svg_data.length()) + " bytes")


func _convert_and_preview_heightmap(json_data: Dictionary) -> void:
	"""
	Convert Azgaar JSON to heightmap Image and save preview PNG (Phase 3).
	
	DEPRECATED: This function is deprecated. SVG rendering is now the preferred method.
	This fallback should only be used if both SVG and canvas rendering fail.
	Consider removing this function in a future version once SVG rendering is fully stable.
	"""
	MythosLogger.warn("WorldBuilderWebController", "Using deprecated heightmap PNG conversion fallback")
	
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
	
	# Load PNG and convert to base64 data URL for WebView
	var png_file := FileAccess.open(png_path, FileAccess.READ)
	if png_file:
		var png_data: PackedByteArray = png_file.get_buffer(png_file.get_length())
		png_file.close()
		var base64_string: String = Marshalls.raw_to_base64(png_data)
		var data_url: String = "data:image/png;base64," + base64_string
		_send_preview_to_webview(data_url)
	else:
		MythosLogger.error("WorldBuilderWebController", "Failed to read PNG file for preview", {"path": png_path})


func _send_preview_to_webview(data_url: String) -> void:
	"""Send preview image (data URL) to WebView for display."""
	if not web_view or data_url.is_empty():
		MythosLogger.warn("WorldBuilderWebController", "Cannot send preview - web_view is null or data_url is empty")
		return
	
	MythosLogger.info("WorldBuilderWebController", "Sending preview to WebView", {"data_url_length": data_url.length()})
	
	# Escape single quotes and backslashes in data URL for JavaScript
	# First escape backslashes, then single quotes (order matters)
	# Note: In GDScript, \' is not a valid escape sequence, so we build it using concatenation
	var escaped_url: String = data_url.replace("\\", "\\\\")
	# For single quotes, we need to escape them for JavaScript: replace ' with \'
	# Build the escape sequence using backslash + quote
	var backslash: String = "\\"
	var single_quote_escaped: String = backslash + "'"
	escaped_url = escaped_url.replace("'", single_quote_escaped)
	
	var preview_script: String = """
		(function() {
			try {
				console.log('[WorldBuilder] Setting preview image URL, length:', %d);
				if (window.worldBuilderInstance) {
					// Set preview URL - Alpine.js will reactively update the UI
					window.worldBuilderInstance.previewImageUrl = '%s';
					
					// Hide status div explicitly (backup in case Alpine.js doesn't react)
					var statusDiv = document.getElementById('azgaar-status');
					if (statusDiv) {
						statusDiv.style.display = 'none';
					}
					
					// Show preview image explicitly (backup)
					var previewImg = document.getElementById('map-preview-img');
					if (previewImg) {
						previewImg.style.display = 'block';
					}
					
					console.log('[WorldBuilder] Preview image URL set successfully', {
						hasUrl: !!window.worldBuilderInstance.previewImageUrl,
						urlLength: window.worldBuilderInstance.previewImageUrl ? window.worldBuilderInstance.previewImageUrl.length : 0
					});
					return 'success';
				} else {
					console.error('[WorldBuilder] worldBuilderInstance not found - Alpine.js may not be initialized');
					return 'error: worldBuilderInstance not found';
				}
			} catch (e) {
				console.error('[WorldBuilder] Error setting preview image:', e);
				return 'error: ' + e.message;
			}
		})();
	""" % [data_url.length(), escaped_url]
	
	# Use call_deferred to avoid WebView binding panics
	if web_view.has_method("call_deferred"):
		web_view.call_deferred("execute_js", preview_script)
		MythosLogger.debug("WorldBuilderWebController", "Scheduled preview update via call_deferred")
	elif web_view.has_method("execute_js"):
		var result = web_view.execute_js(preview_script)
		MythosLogger.debug("WorldBuilderWebController", "Preview update executed", {"result": result})
	elif web_view.has_method("eval"):
		web_view.eval(preview_script)
		MythosLogger.debug("WorldBuilderWebController", "Preview update executed via eval")
	else:
		MythosLogger.error("WorldBuilderWebController", "Cannot execute JS - WebView method not available")