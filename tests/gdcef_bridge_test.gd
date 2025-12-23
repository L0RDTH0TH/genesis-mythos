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
	
	# Inspect available methods
	var method_list := web_view.get_method_list()
	var js_methods: Array[String] = []
	for method in method_list:
		var name: String = method.name
		if "js" in name.to_lower() or "execute" in name.to_lower() or "eval" in name.to_lower() or "call" in name.to_lower():
			js_methods.append(name)
	
	if js_methods.is_empty():
		print("No obvious JavaScript execution methods found.")
	else:
		print("Potential JS methods found: %s" % str(js_methods))
	
	# Simple runtime test if common methods exist
	if web_view.has_method("execute_js"):
		print("Testing execute_js('return 42;')...")
		var result = web_view.execute_js("return 42;")
		print("Result: %s" % result)
	elif web_view.has_method("evaluate_js"):
		print("Testing evaluate_js('42')...")
		var result = web_view.evaluate_js("42")
		print("Result: %s" % result)
	else:
		print("No standard execute_js/evaluate_js method available.")
	
	print("=== GDCef Bridge Test End ===")
	
	scene.queue_free()

