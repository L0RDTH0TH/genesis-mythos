# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderAzgaar.gd
# ║ Desc: Controls Azgaar WebView embedding and communication using godot_wry
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Control

# TEMPORARY DIAGNOSTIC: Azgaar WebView disabled to test custom GUI layout visibility
const DEBUG_DISABLE_AZGAAR := true

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
	# TEMPORARY DIAGNOSTIC: Azgaar WebView disabled to test custom GUI layout visibility
	if DEBUG_DISABLE_AZGAAR:
		MythosLogger.info("WorldBuilderAzgaar", "DIAGNOSTIC: Azgaar WebView initialization disabled")
		# Remove the WebView node from scene tree to prevent godot_wry from initializing
		var web_view_node = get_node_or_null("WebViewMargin/AzgaarWebView")
		if web_view_node:
			# Remove from parent to prevent initialization, then queue_free to clean up
			var parent = web_view_node.get_parent()
			if parent:
				parent.remove_child(web_view_node)
			web_view_node.queue_free()
			MythosLogger.info("WorldBuilderAzgaar", "DIAGNOSTIC: WebView node removed to prevent godot_wry initialization")
		var web_view_margin = get_node_or_null("WebViewMargin")
		if web_view_margin:
			web_view_margin.visible = false
		return
	
	# Get the WebView node (godot_wry uses "WebView" type)
	# WebView is now wrapped in WebViewMargin container
	var web_view_node = get_node_or_null("WebViewMargin/AzgaarWebView")
	
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
		
		# Prefer HTTP URL (embedded server), fallback to file://
		var url: String = azgaar_integrator.get_azgaar_http_url()
		if url.is_empty():
			url = azgaar_integrator.get_azgaar_url()
			MythosLogger.info("WorldBuilderAzgaar", "Using file:// URL (HTTP server not available)")
		else:
			MythosLogger.info("WorldBuilderAzgaar", "Using HTTP URL (embedded server)")
		
		# Load Azgaar URL
		if web_view.has_method("load_url"):
			web_view.load_url(url)
			MythosLogger.info("WorldBuilderAzgaar", "Loaded Azgaar URL", {"url": url})
			
			# Wait for page to load using process_frame yields instead of timer
			# Azgaar is a heavy page, so we yield more frames (~2 seconds at 60 FPS)
			var tree = get_tree()
			if tree:
				# Yield frames for Azgaar initialization
				for i in range(120):  # ~2 seconds at 60 FPS
					await tree.process_frame
					# Log progress at key intervals
					if i == 30:
						MythosLogger.debug("WorldBuilderAzgaar", "Azgaar loading... (25%)")
					elif i == 60:
						MythosLogger.debug("WorldBuilderAzgaar", "Azgaar loading... (50%)")
					elif i == 90:
						MythosLogger.debug("WorldBuilderAzgaar", "Azgaar loading... (75%)")
				
				_inject_azgaar_bridge()
			else:
				MythosLogger.warn("WorldBuilderAzgaar", "Node not in tree, injecting bridge immediately")
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
		# eval() returns void, so don't try to capture return value
		web_view.eval(code)
		MythosLogger.debug("WorldBuilderAzgaar", "Executed JS via eval", {"code": code})
		return null
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
		# Fallback: reload URL (prefer HTTP, fallback to file://)
		var url: String = azgaar_integrator.get_azgaar_http_url()
		if url.is_empty():
			url = azgaar_integrator.get_azgaar_url()
		web_view.load_url(url)
		MythosLogger.debug("WorldBuilderAzgaar", "Azgaar WebView reloaded via load_url", {"url": url})
	else:
		MythosLogger.warn("WorldBuilderAzgaar", "Cannot reload - WebView or URL not available")

func trigger_generation_with_options(options: Dictionary, auto_generate: bool = true) -> void:
	"""Trigger Azgaar generation by injecting parameters via JS."""
	# TEMPORARY DIAGNOSTIC: Skip generation if Azgaar is disabled
	if DEBUG_DISABLE_AZGAAR:
		MythosLogger.info("WorldBuilderAzgaar", "DIAGNOSTIC: Generation skipped (Azgaar disabled)")
		return
	
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
	# Parameters are already in Azgaar key format from JSON config
	# Direct mapping: param keys are Azgaar option keys
	
	# Inject each parameter
	for azgaar_key in params:
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
		
		# Execute JS to set parameter
		# Handle nested options (e.g., options.temperatureEquator)
		var js_code: String
		if azgaar_key.begins_with("options"):
			# Already has "options" prefix
			js_code = "if (typeof azgaar !== 'undefined' && azgaar.options) { azgaar.%s = %s; }" % [azgaar_key, js_value]
		else:
			# Standard option path
			js_code = "if (typeof azgaar !== 'undefined' && azgaar.options) { azgaar.options.%s = %s; }" % [azgaar_key, js_value]
		
		_execute_azgaar_js(js_code)
	
	MythosLogger.debug("WorldBuilderAzgaar", "Synced parameters to Azgaar", {"param_count": params.size()})

func _on_generation_timeout() -> void:
	"""Handle generation timeout."""
	if not is_generation_complete:
		emit_signal("generation_failed", "Generation timed out after 60 seconds")
		MythosLogger.warn("WorldBuilderAzgaar", "Generation timed out", {"timeout_seconds": 60.0})

func export_heightmap() -> Image:
	"""Export heightmap from Azgaar and return as Godot Image."""
	# TEMPORARY DIAGNOSTIC: Skip export if Azgaar is disabled
	if DEBUG_DISABLE_AZGAAR:
		MythosLogger.info("WorldBuilderAzgaar", "DIAGNOSTIC: Heightmap export skipped (Azgaar disabled)")
		return null
	
	if not web_view:
		MythosLogger.error("WorldBuilderAzgaar", "WebView is null, cannot export heightmap")
		return null
	
	# Get map dimensions from Azgaar
	var width_js: String = """
		(function() {
			if (typeof graphWidth !== 'undefined') return graphWidth;
			if (typeof pack !== 'undefined' && pack.cells) return pack.cells.x.length || 1000;
			return 1000;
		})();
	"""
	var height_js: String = """
		(function() {
			if (typeof graphHeight !== 'undefined') return graphHeight;
			if (typeof pack !== 'undefined' && pack.cells) return pack.cells.y.length || 500;
			return 500;
		})();
	"""
	
	var width_result = _execute_azgaar_js(width_js)
	var height_result = _execute_azgaar_js(height_js)
	
	var width: int = int(width_result) if width_result != null else 1000
	var height: int = int(height_result) if height_result != null else 500
	
	MythosLogger.debug("WorldBuilderAzgaar", "Map dimensions", {"width": width, "height": height})
	
	# Extract heightmap data from Azgaar's internal structures
	var heightmap_js: String = """
		(function() {
			if (!pack || !pack.cells || !pack.cells.h || !pack.cells.i) {
				console.error('Azgaar data not available');
				return null;
			}
			var width = %d;
			var height = %d;
			var heightmap = new Array(width * height);
			
			// Initialize with zeros
			for (var i = 0; i < heightmap.length; i++) {
				heightmap[i] = 0.0;
			}
			
			// Fill from pack.cells.h (height values) and pack.cells.i (cell indices)
			for (var i = 0; i < pack.cells.h.length; i++) {
				var cellIndex = pack.cells.i[i];
				var x = cellIndex %% width;
				var y = Math.floor(cellIndex / width);
				if (x >= 0 && x < width && y >= 0 && y < height) {
					// Normalize height from 0-100 to 0-1
					var normalizedHeight = pack.cells.h[i] / 100.0;
					heightmap[y * width + x] = normalizedHeight;
				}
			}
			
			return heightmap;
		})();
	""" % [width, height]
	
	var heightmap_data = _execute_azgaar_js(heightmap_js)
	
	if heightmap_data == null:
		MythosLogger.error("WorldBuilderAzgaar", "Failed to extract heightmap data from Azgaar")
		return null
	
	# Convert to Godot Image
	var image: Image = Image.create(width, height, false, Image.FORMAT_RF)
	
	if heightmap_data is Array:
		# Data is array of floats
		for y in range(height):
			for x in range(width):
				var idx: int = y * width + x
				if idx < heightmap_data.size():
					var height_value: float = float(heightmap_data[idx])
					# Clamp to 0-1 range
					height_value = clamp(height_value, 0.0, 1.0)
					image.set_pixel(x, y, Color(height_value, 0.0, 0.0, 1.0))
	else:
		MythosLogger.error("WorldBuilderAzgaar", "Heightmap data is not an array", {"type": typeof(heightmap_data)})
		return null
	
	MythosLogger.info("WorldBuilderAzgaar", "Heightmap exported", {"size": image.get_size()})
	return image

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
