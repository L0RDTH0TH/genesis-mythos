# ╔═══════════════════════════════════════════════════════════
# ║ MainMenuWebController.gd
# ║ Desc: Controller for MainMenu WebView UI (godot_wry-based)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name MainMenuWebController
extends Control

@onready var web_view: Node = $WebView

func _ready() -> void:
	"""Initialize WebView and connect IPC signal."""
	if not web_view:
		push_error("MainMenuWebController: WebView node not found!")
		return
	
	# Check if it's a valid WebView instance
	var node_class = web_view.get_class()
	if node_class != "WebView":
		push_error("MainMenuWebController: Node is not a WebView (class: %s)" % node_class)
		return
	
	# Connect IPC message signal for bidirectional communication
	if web_view.has_signal("ipc_message"):
		web_view.ipc_message.connect(_on_ipc_message)
		MythosLogger.info("MainMenuWebController", "Connected to WebView IPC message signal")
	else:
		push_warning("MainMenuWebController: WebView does not have ipc_message signal")
	
	# Load the MainMenu HTML file
	# Use res:// URL directly (godot_wry supports res:// URLs)
	var html_url: String = "res://web_ui/main_menu/index.html"
	web_view.load_url(html_url)
	MythosLogger.info("MainMenuWebController", "Loaded MainMenu HTML", {"url": html_url})
	
	# Wait for page to load, then inject bridge initialization
	await get_tree().create_timer(1.0).timeout
	_inject_ipc_bridge()

func _on_ipc_message(message: String) -> void:
	"""Handle IPC messages from MainMenu WebView."""
	MythosLogger.debug("MainMenuWebController", "Received IPC message", {"message": message})
	
	# Parse JSON message
	var json = JSON.new()
	var parse_result = json.parse(message)
	if parse_result != OK:
		MythosLogger.warn("MainMenuWebController", "Failed to parse IPC message", {"error": parse_result})
		return
	
	var data = json.data
	if not data is Dictionary:
		MythosLogger.warn("MainMenuWebController", "IPC message data is not a Dictionary")
		return
	
	# Handle different message types
	var message_type: String = data.get("type", "")
	var message_data: Dictionary = data.get("data", {})
	
	match message_type:
		"navigate":
			_handle_navigate(message_data)
		"viewport_resize":
			_handle_viewport_resize(message_data)
		_:
			MythosLogger.debug("MainMenuWebController", "Unknown message type", {"type": message_type})

func _handle_navigate(data: Dictionary) -> void:
	"""Handle navigation request from WebView."""
	var scene_path: String = data.get("scene_path", "")
	if scene_path.is_empty():
		MythosLogger.warn("MainMenuWebController", "Navigate request missing scene_path")
		return
	
	MythosLogger.info("MainMenuWebController", "Navigating to scene", {"scene_path": scene_path})
	get_tree().change_scene_to_file(scene_path)

func _handle_viewport_resize(data: Dictionary) -> void:
	"""Handle viewport resize notification from WebView."""
	var width: int = data.get("width", 0)
	var height: int = data.get("height", 0)
	
	MythosLogger.debug("MainMenuWebController", "Viewport resize", {"width": width, "height": height})
	
	# Ensure WebView matches viewport size
	if web_view and web_view.has_method("set_size"):
		web_view.set_size(Vector2i(width, height))

func _inject_ipc_bridge() -> void:
	"""Verify IPC bridge is available (godot_wry provides window.ipc automatically)."""
	# Note: godot_wry provides window.ipc automatically - no injection needed
	# This just logs status for debugging
	var bridge_check_script = """
	(function() {
		if (window.ipc && typeof window.ipc.postMessage === 'function') {
			console.log('Godot IPC available via window.ipc.postMessage');
		} else {
			console.warn('Godot IPC not available - window.ipc should be provided by godot_wry');
		}
	})();
	"""
	
	if web_view.has_method("execute_js"):
		web_view.execute_js(bridge_check_script)
		MythosLogger.info("MainMenuWebController", "Checked IPC bridge availability")
	elif web_view.has_method("eval"):
		web_view.eval(bridge_check_script)
		MythosLogger.info("MainMenuWebController", "Checked IPC bridge availability via eval")

func _notification(what: int) -> void:
	"""Handle window resize events."""
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		# Ensure WebView fills viewport
		var viewport_size: Vector2 = get_viewport().get_visible_rect().size
		if web_view and web_view.has_method("set_size"):
			web_view.set_size(Vector2i(int(viewport_size.x), int(viewport_size.y)))

