# ╔═══════════════════════════════════════════════════════════
# ║ GDCefBridgeTest.gd
# ║ Desc: Editor tool to inspect GDCef WebView capabilities and test JS execution
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

@tool
extends EditorScript

func _run() -> void:
	print("=== GDCef Bridge Test Start ===")
	
	var scene_path := "res://ui/world_builder/WorldBuilderUI.tscn"
	if not FileAccess.file_exists(scene_path):
		print("ERROR: WorldBuilderUI.tscn not found at %s" % scene_path)
		return
	
	var scene: Node = load(scene_path).instantiate()
	# Find the AzgaarWebView node (GDCef WebView)
	var web_view: Node = scene.find_child("AzgaarWebView", true, false)
	if not web_view:
		print("ERROR: AzgaarWebView node not found in scene")
		scene.queue_free()
		return
	
	print("Found WebView node: %s (%s)" % [web_view.name, web_view.get_class()])
	
	# Inspect ALL available methods
	var method_list := web_view.get_method_list()
	print("\n=== ALL METHODS (first 50) ===")
	var all_method_names: Array[String] = []
	for i in range(min(50, method_list.size())):
		all_method_names.append(method_list[i].name)
	print(str(all_method_names))
	
	# Search for JavaScript-related methods with broader patterns
	var js_methods: Array[String] = []
	var script_methods: Array[String] = []
	var browser_methods: Array[String] = []
	
	for method in method_list:
		var name: String = method.name
		var name_lower: String = name.to_lower()
		
		# JavaScript execution patterns
		if "js" in name_lower or "javascript" in name_lower:
			js_methods.append(name)
		# Script execution patterns
		if "script" in name_lower or "run" in name_lower or "execute" in name_lower or "eval" in name_lower:
			script_methods.append(name)
		# Browser/WebView specific patterns
		if "browser" in name_lower or "webview" in name_lower or "page" in name_lower:
			browser_methods.append(name)
	
	print("\n=== JAVASCRIPT-RELATED METHODS ===")
	if js_methods.is_empty():
		print("No methods containing 'js' or 'javascript' found.")
	else:
		print("JS methods: %s" % str(js_methods))
	
	print("\n=== SCRIPT EXECUTION METHODS ===")
	if script_methods.is_empty():
		print("No methods containing 'script', 'run', 'execute', or 'eval' found.")
	else:
		print("Script methods: %s" % str(script_methods))
	
	print("\n=== BROWSER/WEBVIEW METHODS ===")
	if browser_methods.is_empty():
		print("No browser/webview-specific methods found.")
	else:
		print("Browser methods: %s" % str(browser_methods))
	
	# Test common method name variations
	print("\n=== TESTING COMMON METHOD NAMES ===")
	var test_methods: Array[String] = [
		"execute_js", "evaluate_js", "run_js", "eval_js",
		"execute_javascript", "evaluate_javascript",
		"execute_script", "evaluate_script", "run_script",
		"call_js", "call_javascript", "call_script"
	]
	
	for method_name in test_methods:
		if web_view.has_method(method_name):
			print("✓ Found method: %s" % method_name)
			# Try to call it with a simple test
			print("  Attempting to call %s('return 42;')..." % method_name)
			# Note: We can't actually call it in EditorScript without proper setup
			# This is just to confirm the method exists
	
	print("=== GDCef Bridge Test End ===")
	
	scene.queue_free()

