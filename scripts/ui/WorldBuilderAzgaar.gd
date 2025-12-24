# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderAzgaar.gd
# ║ Desc: Controls Azgaar WebView embedding and communication using godot_wry
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Control

var web_view: Node = null  # godot_wry WebView node
@onready var azgaar_integrator: Node = get_node("/root/AzgaarIntegrator")

var generation_timeout_timer: Timer = null
var current_generation_options: Dictionary = {}
var is_generation_complete: bool = false

signal generation_started
signal generation_complete
signal generation_failed(reason: String)

func _ready() -> void:
	"""Initialize Azgaar WebView on ready."""
	# Use call_deferred to ensure node tree is fully initialized
	call_deferred("_initialize_webview")

func _initialize_webview() -> void:
	"""Initialize the Azgaar WebView after the node tree is ready."""
	# Get the WebView node (godot_wry uses "WebView" type)
	var web_view_node = get_node_or_null("AzgaarWebView")
	
	if not web_view_node:
		MythosLogger.error("WorldBuilderAzgaar", "AzgaarWebView node not found in scene tree")
		return
	
	# Check if it's a valid WebView instance
	var node_class = web_view_node.get_class()
	if node_class == "WebView":
		web_view = web_view_node
		MythosLogger.info("WorldBuilderAzgaar", "AzgaarWebView node is valid WebView instance (class: %s)" % node_class)
		
		# Connect IPC message signal for bidirectional communication
		if web_view.has_signal("ipc_message"):
			web_view.ipc_message.connect(_on_ipc_message)
			MythosLogger.info("WorldBuilderAzgaar", "Connected to WebView IPC message signal")
		else:
			MythosLogger.warn("WorldBuilderAzgaar", "WebView does not have ipc_message signal")
	else:
		MythosLogger.error("WorldBuilderAzgaar", "AzgaarWebView is not a WebView node (class: %s)" % node_class)
		return
	
	# Initialize Azgaar
	if azgaar_integrator:
		azgaar_integrator.copy_azgaar_to_user()
		var url: String = azgaar_integrator.get_azgaar_url()
		
		# Load Azgaar URL
		if web_view.has_method("load_url"):
			web_view.load_url(url)
			MythosLogger.info("WorldBuilderAzgaar", "Loaded Azgaar URL", {"url": url})
			
			# Wait for page to load, then inject bridge script
			await get_tree().create_timer(2.0).timeout
			_inject_azgaar_bridge()
		else:
			MythosLogger.error("WorldBuilderAzgaar", "WebView does not have load_url method")
	else:
		MythosLogger.error("WorldBuilderAzgaar", "AzgaarIntegrator singleton not found")

func _on_ipc_message(message: String) -> void:
	"""Handle IPC messages from Azgaar WebView."""
	MythosLogger.debug("WorldBuilderAzgaar", "Received IPC message from Azgaar", {"message": message})
	
	# Parse JSON message if possible
	var json = JSON.new()
	var parse_result = json.parse(message)
	if parse_result == OK:
		var data = json.data
		if data is Dictionary:
			# Handle different message types
			if data.has("type"):
				match data.type:
					"generation_complete":
						is_generation_complete = true
						if generation_timeout_timer:
							generation_timeout_timer.stop()
						emit_signal("generation_complete")
						MythosLogger.info("WorldBuilderAzgaar", "Azgaar generation completed")
					"generation_failed":
						emit_signal("generation_failed", data.get("reason", "Unknown error"))
					"export_complete":
						MythosLogger.info("WorldBuilderAzgaar", "Azgaar export completed", {"data": data})

func _execute_azgaar_js(code: String) -> Variant:
	"""Execute JavaScript code in Azgaar WebView."""
	if not web_view:
		MythosLogger.error("WorldBuilderAzgaar", "WebView is null, cannot execute JS")
		return null
	
	# godot_wry uses execute_js or eval method
	if web_view.has_method("execute_js"):
		var result = web_view.execute_js(code)
		MythosLogger.debug("WorldBuilderAzgaar", "Executed JS", {"code": code, "result": result})
		return result
	elif web_view.has_method("eval"):
		var result = web_view.eval(code)
		MythosLogger.debug("WorldBuilderAzgaar", "Executed JS via eval", {"code": code, "result": result})
		return result
	else:
		MythosLogger.warn("WorldBuilderAzgaar", "WebView does not have execute_js or eval method")
		# Fallback: use post_message to send JS code
		if web_view.has_method("post_message"):
			var message = JSON.stringify({"type": "execute_js", "code": code})
			web_view.post_message(message)
			MythosLogger.debug("WorldBuilderAzgaar", "Sent JS via post_message", {"code": code})
		return null

func reload_azgaar() -> void:
	"""Reload the Azgaar WebView."""
	if web_view and web_view.has_method("reload"):
		web_view.reload()
		MythosLogger.debug("WorldBuilderAzgaar", "Azgaar WebView reloaded")
	elif web_view and azgaar_integrator:
		# Fallback: reload URL
		var url: String = azgaar_integrator.get_azgaar_url()
		web_view.load_url(url)
		MythosLogger.debug("WorldBuilderAzgaar", "Azgaar WebView reloaded via load_url")
	else:
		MythosLogger.warn("WorldBuilderAzgaar", "Cannot reload - WebView or URL not available")

func trigger_generation_with_options(options: Dictionary, auto_generate: bool = true) -> void:
	"""Trigger Azgaar generation by injecting parameters via JS."""
	current_generation_options = options
	is_generation_complete = false
	emit_signal("generation_started")
	
	# Inject parameters via JavaScript instead of writing options.json
	_sync_parameters_to_azgaar(options)
	
	# Trigger generation
	if auto_generate:
		_execute_azgaar_js("if (typeof azgaar !== 'undefined' && azgaar.generate) { azgaar.generate(); }")
	
	# Start timeout timer (60 seconds default)
	if generation_timeout_timer == null:
		generation_timeout_timer = Timer.new()
		generation_timeout_timer.one_shot = true
		add_child(generation_timeout_timer)
		generation_timeout_timer.timeout.connect(_on_generation_timeout)
	
	generation_timeout_timer.wait_time = 60.0
	generation_timeout_timer.start()
	MythosLogger.info("WorldBuilderAzgaar", "Generation triggered with options", {"auto_generate": auto_generate})

func _sync_parameters_to_azgaar(params: Dictionary) -> void:
	"""Sync parameters to Azgaar via JavaScript injection."""
	# Map Godot parameter names to Azgaar parameter names
	# Based on AZGAAR_PARAMETERS.md and azgaar_parameter_mapping.json
	
	var param_mapping: Dictionary = {
		"template": "templateInput",
		"points": "pointsInput",
		"heightExponent": "heightExponent",
		"allowErosion": "allowErosion",
		"plateCount": "plateCount",
		"precip": "precip",
		"temperatureEquator": "temperatureEquator",
		"temperatureNorthPole": "temperatureNorthPole",
		"statesNumber": "statesNumber",
		"culturesSet": "culturesSet",
		"religionsNumber": "religionsNumber",
		"seed": "optionsSeed"
	}
	
	# Inject each parameter
	for godot_key in params:
		var azgaar_key = param_mapping.get(godot_key, godot_key)
		var value = params[godot_key]
		
		# Format value based on type
		var js_value: String
		if value is String:
			js_value = '"%s"' % value
		elif value is bool:
			js_value = "true" if value else "false"
		else:
			js_value = str(value)
		
		# Execute JS to set parameter
		var js_code = "if (typeof azgaar !== 'undefined') { azgaar.options.%s = %s; }" % [azgaar_key, js_value]
		_execute_azgaar_js(js_code)
	
	MythosLogger.debug("WorldBuilderAzgaar", "Synced parameters to Azgaar", {"param_count": params.size()})

func _on_generation_timeout() -> void:
	"""Handle generation timeout."""
	if not is_generation_complete:
		emit_signal("generation_failed", "Generation timed out after 60 seconds")
		MythosLogger.warn("WorldBuilderAzgaar", "Generation timed out", {"timeout_seconds": 60.0})

func export_heightmap() -> Image:
	"""Export heightmap from Azgaar and return as Godot Image."""
	if not web_view:
		MythosLogger.error("WorldBuilderAzgaar", "WebView is null, cannot export heightmap")
		return null
	
	# Execute JS to trigger heightmap export
	# Azgaar may save to a file or return data via callback
	_execute_azgaar_js("if (typeof azgaar !== 'undefined' && azgaar.exportMap) { azgaar.exportMap('heightmap'); }")
	
	# Wait for export to complete (via IPC message or file system check)
	# For now, return null - this will be implemented when we have the export callback
	MythosLogger.info("WorldBuilderAzgaar", "Heightmap export triggered")
	return null

func _inject_azgaar_bridge() -> void:
	"""Inject bridge script into Azgaar for bidirectional communication."""
	var bridge_script = """
	(function() {
		// Bridge script to communicate with Godot via godot_wry IPC
		if (typeof window.godot === 'undefined') {
			window.godot = {};
		}
		
		// Function to send messages to Godot
		window.godot.postMessage = function(message) {
			if (window.godot && window.godot.ipc) {
				window.godot.ipc.postMessage(JSON.stringify(message));
			}
		};
		
		// Hook into Azgaar's generation completion
		// Monitor for generation completion by watching for map updates
		var originalGenerate = null;
		if (typeof azgaar !== 'undefined' && azgaar.generate) {
			originalGenerate = azgaar.generate;
			azgaar.generate = function() {
				var result = originalGenerate.apply(this, arguments);
				// Wait for generation to complete (Azgaar is async)
				setTimeout(function() {
					if (window.godot && window.godot.postMessage) {
						window.godot.postMessage({
							type: 'generation_complete',
							timestamp: Date.now()
						});
					}
				}, 1000); // Give Azgaar time to finish rendering
				return result;
			};
		}
		
		// Also listen for map regeneration events
		if (typeof addEventListener !== 'undefined') {
			window.addEventListener('mapGenerated', function() {
				if (window.godot && window.godot.postMessage) {
					window.godot.postMessage({
						type: 'generation_complete',
						timestamp: Date.now()
					});
				}
			});
		}
		
		console.log('Godot-Azgaar bridge injected');
	})();
	"""
	
	_execute_azgaar_js(bridge_script)
	MythosLogger.info("WorldBuilderAzgaar", "Injected Azgaar bridge script")

func post_message_to_azgaar(message: Dictionary) -> void:
	"""Send a message to Azgaar via IPC."""
	if web_view and web_view.has_method("post_message"):
		var json_string = JSON.stringify(message)
		web_view.post_message(json_string)
		MythosLogger.debug("WorldBuilderAzgaar", "Posted message to Azgaar", {"message": message})
	else:
		MythosLogger.warn("WorldBuilderAzgaar", "Cannot post message - WebView or method not available")
