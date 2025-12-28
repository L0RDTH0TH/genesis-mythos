# ╔═══════════════════════════════════════════════════════════
# ║ ProgressDialogWebController.gd
# ║ Desc: WebView-based progress dialog controller for long operations
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name ProgressDialogWebController
extends CanvasLayer

@onready var web_view: WebView = $WebView

func _ready() -> void:
	"""Initialize progress dialog WebView."""
	layer = 100  # High layer for overlay
	visible = false  # Hidden by default
	
	if not web_view:
		MythosLogger.error("ProgressDialogWeb", "WebView node not found")
		return
	
	# Load HTML
	web_view.load_url("res://web_ui/overlays/progress_dialog/index.html")
	MythosLogger.debug("ProgressDialogWeb", "Progress dialog WebView initialized")


func show_progress(title: String = "Processing...", initial_status: String = "Please wait...") -> void:
	"""Show progress dialog with initial title and status."""
	if not web_view:
		MythosLogger.warn("ProgressDialogWeb", "WebView not available")
		return
	
	visible = true
	
	# Use execute_js to send update message to WebView via GodotBridge
	var js_code: String = """
		if (window.GodotBridge && window.GodotBridge._handleUpdate) {
			window.GodotBridge._handleUpdate({
				type: 'show_progress',
				title: '%s',
				status: '%s',
				progress: 0
			});
		}
	""" % [title.replace("'", "\\'").replace("\n", " "), initial_status.replace("'", "\\'").replace("\n", " ")]
	
	web_view.execute_js(js_code)
	MythosLogger.debug("ProgressDialogWeb", "Progress dialog shown: %s" % title)


func update_progress(progress: float, status: String = "") -> void:
	"""Update progress bar value (0.0 to 1.0) and optional status text."""
	if not web_view or not visible:
		return
	
	# Convert to percentage (0.0-1.0 -> 0-100)
	var progress_percent: int = int(clamp(progress * 100.0, 0.0, 100.0))
	
	# Use execute_js to send update message to WebView via GodotBridge
	var status_js: String = ""
	if status != "":
		status_js = ", status: '%s'" % status.replace("'", "\\'").replace("\n", " ")
	
	var js_code: String = """
		if (window.GodotBridge && window.GodotBridge._handleUpdate) {
			window.GodotBridge._handleUpdate({
				type: 'update_progress',
				progress: %d%s
			});
		}
	""" % [progress_percent, status_js]
	
	web_view.execute_js(js_code)


func hide_progress() -> void:
	"""Hide progress dialog."""
	if not web_view:
		return
	
	# Use execute_js to send hide message to WebView
	var js_code: String = """
		if (window.GodotBridge && window.GodotBridge._handleUpdate) {
			window.GodotBridge._handleUpdate({
				type: 'hide_progress'
			});
		}
	"""
	
	web_view.execute_js(js_code)
	
	# Hide after a short delay to allow transition
	await get_tree().create_timer(0.3).timeout
	visible = false
	MythosLogger.debug("ProgressDialogWeb", "Progress dialog hidden")

