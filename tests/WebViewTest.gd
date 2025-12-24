# ╔═══════════════════════════════════════════════════════════
# ║ WebViewTest.gd
# ║ Desc: Minimal test scene to verify godot_wry WebView works
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Control

@onready var web_view: Node = $WebView

func _ready() -> void:
	"""Initialize WebView and test JS execution."""
	if not web_view:
		push_error("WebView node not found")
		return
	
	# Load test HTML
	if web_view.has_method("load_url"):
		web_view.load_url("res://tests/webview_test.html")
		MythosLogger.info("WebViewTest", "Loaded test HTML")
	
	# Wait for page to load, then test JS execution
	await get_tree().create_timer(1.0).timeout
	_test_js_execution()

func _test_js_execution() -> void:
	"""Test JavaScript execution in WebView."""
	if not web_view:
		return
	
	# Test JS execution - godot_wry uses execute_js or eval
	if web_view.has_method("execute_js"):
		var result = web_view.execute_js("testFunc()")
		MythosLogger.info("WebViewTest", "JS execution result: %s" % result)
	elif web_view.has_method("eval"):
		var result = web_view.eval("testFunc()")
		MythosLogger.info("WebViewTest", "JS execution result: %s" % result)
	else:
		MythosLogger.warn("WebViewTest", "No JS execution method found")
		# List available methods
		var methods = web_view.get_method_list()
		for method in methods:
			if "js" in method.name.to_lower() or "eval" in method.name.to_lower():
				MythosLogger.debug("WebViewTest", "Found method: %s" % method.name)

