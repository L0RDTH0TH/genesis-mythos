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
	print("\n=== TOTAL METHODS COUNT: %d ===" % method_list.size())
	
	# Filter out standard Node methods to find GDCef-specific ones
	var standard_node_methods: Array[String] = [
		"_process", "_physics_process", "_enter_tree", "_exit_tree", "_ready",
		"_get_configuration_warnings", "_input", "_shortcut_input", "_unhandled_input",
		"_unhandled_key_input", "print_orphan_nodes", "get_orphan_node_ids",
		"add_sibling", "set_name", "get_name", "add_child", "remove_child", "reparent",
		"get_child_count", "get_children", "get_child", "has_node", "get_node",
		"get_node_or_null", "get_parent", "find_child", "find_children", "find_parent",
		"has_node_and_resource", "get_node_and_resource", "is_inside_tree",
		"is_part_of_edited_scene", "is_ancestor_of", "is_greater_than", "get_path",
		"get_path_to", "add_to_group", "remove_from_group", "is_in_group", "move_child",
		"get_groups", "set_editor_description", "get_editor_description", "set_script", "get_script"
	]
	
	var gdcef_methods: Array[String] = []
	for method in method_list:
		var name: String = method.name
		if not name in standard_node_methods and not name.begins_with("_"):
			gdcef_methods.append(name)
	
	print("\n=== GDCef-SPECIFIC METHODS (%d found) ===" % gdcef_methods.size())
	if gdcef_methods.is_empty():
		print("No GDCef-specific methods found (all are standard Node methods).")
	else:
		print("GDCef methods: %s" % str(gdcef_methods))
	
	# Search for JavaScript-related methods with broader patterns
	var js_methods: Array[String] = []
	var script_methods: Array[String] = []
	var browser_methods: Array[String] = []
	var interesting_methods: Array[String] = []
	
	for method in method_list:
		var name: String = method.name
		var name_lower: String = name.to_lower()
		
		# JavaScript execution patterns
		if "js" in name_lower or "javascript" in name_lower:
			js_methods.append(name)
		# Script execution patterns (excluding standard set_script/get_script)
		if ("script" in name_lower or "run" in name_lower or "execute" in name_lower or "eval" in name_lower) and not name in ["set_script", "get_script"]:
			script_methods.append(name)
		# Browser/WebView specific patterns
		if "browser" in name_lower or "webview" in name_lower or "page" in name_lower or "frame" in name_lower:
			browser_methods.append(name)
		# Other interesting patterns
		if "load" in name_lower or "navigate" in name_lower or "url" in name_lower or "html" in name_lower or "dom" in name_lower:
			interesting_methods.append(name)
	
	print("\n=== JAVASCRIPT-RELATED METHODS ===")
	if js_methods.is_empty():
		print("No methods containing 'js' or 'javascript' found.")
	else:
		print("JS methods: %s" % str(js_methods))
	
	print("\n=== SCRIPT EXECUTION METHODS (non-standard) ===")
	if script_methods.is_empty():
		print("No non-standard script execution methods found.")
	else:
		print("Script methods: %s" % str(script_methods))
	
	print("\n=== BROWSER/WEBVIEW METHODS ===")
	if browser_methods.is_empty():
		print("No browser/webview-specific methods found.")
	else:
		print("Browser methods: %s" % str(browser_methods))
	
	print("\n=== OTHER INTERESTING METHODS (load/navigate/url/html/dom) ===")
	if interesting_methods.is_empty():
		print("No other interesting methods found.")
	else:
		print("Interesting methods: %s" % str(interesting_methods))
	
	# Check ALL properties
	print("\n=== ALL PROPERTIES ===")
	var property_list := web_view.get_property_list()
	print("Total properties: %d" % property_list.size())
	var interesting_properties: Array[String] = []
	var all_property_names: Array[String] = []
	
	for prop in property_list:
		var name: String = prop.name
		all_property_names.append(name)
		var name_lower: String = name.to_lower()
		if "browser" in name_lower or "webview" in name_lower or "page" in name_lower or "frame" in name_lower or "js" in name_lower or "javascript" in name_lower or "url" in name_lower:
			interesting_properties.append(name)
	
	print("All property names (first 30): %s" % str(all_property_names.slice(0, 30)))
	
	if interesting_properties.is_empty():
		print("\nNo interesting properties found.")
	else:
		print("\nInteresting properties: %s" % str(interesting_properties))
		# Try to get values of interesting properties
		print("\n=== INTERESTING PROPERTY VALUES ===")
		for prop_name in interesting_properties:
			if web_view.has_method("get_" + prop_name):
				var value = web_view.call("get_" + prop_name)
				print("  %s = %s (type: %s)" % [prop_name, str(value), typeof(value)])
			elif web_view.has(prop_name):
				var value = web_view.get(prop_name)
				print("  %s = %s (type: %s)" % [prop_name, str(value), typeof(value)])
	
	# Try to inspect create_browser method signature
	print("\n=== INSPECTING create_browser METHOD ===")
	if web_view.has_method("create_browser"):
		var method_info = null
		for method in method_list:
			if method.name == "create_browser":
				method_info = method
				break
		
		if method_info:
			print("create_browser found:")
			print("  Method info keys: %s" % str(method_info.keys()))
			
			if method_info.has("args"):
				var args = method_info.args
				print("  Arguments: %d" % args.size())
				for i in range(args.size()):
					var arg = args[i]
					if arg is Dictionary:
						print("    arg[%d]: name=%s, type=%s" % [i, arg.get("name", "unknown"), arg.get("type", -1)])
					else:
						print("    arg[%d]: %s" % [i, str(arg)])
			else:
				print("  Arguments: (not found in method info)")
			
			if method_info.has("return"):
				var return_info = method_info.return
				if return_info is Dictionary:
					print("  Return type: %s" % return_info.get("type", -1))
				else:
					print("  Return: %s" % str(return_info))
			elif method_info.has("return_val"):
				var return_info = method_info.return_val
				if return_info is Dictionary:
					print("  Return type: %s" % return_info.get("type", -1))
				else:
					print("  Return: %s" % str(return_info))
			else:
				print("  Return type: (not specified)")
			
			# Try to call it and inspect the returned object
			print("\n  Attempting to call create_browser()...")
			print("  Type 24 = Variant.Type.OBJECT (likely)")
			print("  Type 4 = Variant.Type.INT (likely)")
			print("  Type 27 = Variant.Type.STRING (likely)")
			print("  Note: Browser is created as a child node (typically 'browser_0')")
			print("  WARNING: CEF must be initialized before creating browsers")
			
			# Check if initialize() needs to be called first
			if web_view.has_method("initialize"):
				print("  Found initialize() method - checking if CEF is initialized...")
				if web_view.has_method("is_alive"):
					var is_alive = web_view.call("is_alive")
					print("  is_alive() = %s" % str(is_alive))
					if not is_alive:
						print("  CEF not initialized. Attempting initialize()...")
						# Note: initialize() might require arguments, but let's try
						web_view.call("initialize")
						print("  initialize() called")
			
			# Check current children before creating browser
			var children_before: Array[String] = []
			var existing_browser_nodes: Array[Node] = []
			for child in web_view.get_children():
				children_before.append(child.name)
				if "browser" in child.name.to_lower():
					existing_browser_nodes.append(child)
			print("\n  Current children before create_browser: %s" % str(children_before))
			
			# If browser nodes already exist, inspect them instead of creating new ones
			if not existing_browser_nodes.is_empty():
				var existing_names: Array[String] = []
				for n in existing_browser_nodes:
					existing_names.append(n.name)
				print("  ✓ Found existing browser node(s): %s" % str(existing_names))
				print("  Will inspect existing browser nodes instead of creating new ones...")
				# Skip to browser inspection (will happen after this if/else)
			else:
				# Try calling with reasonable defaults
				# Based on gdCEF API, might be: url, texture_rect, options_dict
				# NOTE: In EditorScript context, CEF may not be fully initialized
				# We'll try but expect it might fail
				if web_view.has_method("create_browser"):
					print("  Attempting create_browser('about:blank', null, {})...")
					print("  (This may fail in EditorScript context - CEF needs proper scene tree)")
					
					# Try calling - might need a TextureRect, but let's try with null first
					var call_result = null
					var call_error = false
					# Wrap in error handling since it might fail
					call_result = web_view.call("create_browser", "about:blank", null, {})
					print("  create_browser() returned: %s (type: %s)" % [str(call_result), typeof(call_result)])
					
					# If call failed, note that browser creation requires proper CEF initialization
					# which may not work in EditorScript context
					if call_result == null:
						print("  NOTE: create_browser() returned null - CEF may not be initialized in EditorScript")
						print("  To properly test browser creation, run this in a real scene with CEF initialized")
						if existing_browser_nodes.is_empty():
							print("  Skipping browser child node inspection...")
							scene.queue_free()
							print("=== GDCef Bridge Test End (Early - CEF not initialized) ===")
							return
						else:
							print("  But we have existing browser nodes, so continuing with inspection...")
					
					# Check children after creating browser (if we tried to create)
					if call_result != null:
						var children_after = web_view.get_children()
						var children_after_names: Array[String] = []
						for child in children_after:
							children_after_names.append(child.name)
						print("  Children after create_browser: %s" % str(children_after_names))
						
						# Look for browser child nodes
						for child in children_after:
							if "browser" in child.name.to_lower() and not child in existing_browser_nodes:
								existing_browser_nodes.append(child)
			
			# Inspect browser nodes (either existing or newly created)
			if existing_browser_nodes.is_empty():
					print("  No browser child nodes found. Checking all children...")
					for child in web_view.get_children():
						print("    Child: %s (%s)" % [child.name, child.get_class()])
				else:
					print("  ✓ Found %d browser child node(s) to inspect" % existing_browser_nodes.size())
					
					# Inspect the first browser node
					var browser_node = existing_browser_nodes[0]
					print("\n  === INSPECTING BROWSER CHILD NODE: %s ===" % browser_node.name)
					print("  Class: %s" % browser_node.get_class())
					
					# Get methods on the browser node
					var browser_node_methods = browser_node.get_method_list()
					print("  Browser node methods count: %d" % browser_node_methods.size())
					
					# Search for JS-related methods on browser node
					var browser_js_methods: Array[String] = []
					var browser_interesting_methods: Array[String] = []
					for method in browser_node_methods:
						var method_name: String = method.get("name", "") if method is Dictionary else str(method)
						var method_name_lower: String = method_name.to_lower()
						if "js" in method_name_lower or "javascript" in method_name_lower:
							browser_js_methods.append(method_name)
						if "script" in method_name_lower or "execute" in method_name_lower or "eval" in method_name_lower or "run" in method_name_lower:
							browser_interesting_methods.append(method_name)
					
					if browser_js_methods.is_empty():
						print("  No JS-related methods found on browser node.")
						if browser_interesting_methods.is_empty():
							print("  No script/execute/eval methods found either.")
							var first_browser_methods: Array[String] = []
							for i in range(min(30, browser_node_methods.size())):
								var browser_method_info = browser_node_methods[i]
								if browser_method_info is Dictionary:
									first_browser_methods.append(browser_method_info.get("name", "unknown"))
								else:
									first_browser_methods.append(str(browser_method_info))
							print("  First 30 methods: %s" % str(first_browser_methods))
						else:
							print("  Script/execute/eval methods: %s" % str(browser_interesting_methods))
					else:
						print("  ✓✓✓ JS-RELATED METHODS ON BROWSER NODE: %s" % str(browser_js_methods))
					
					# Check properties on browser node
					var browser_props = browser_node.get_property_list()
					var browser_js_props: Array[String] = []
					for prop in browser_props:
						var prop_name: String = prop.name
						if "js" in prop_name.to_lower() or "javascript" in prop_name.to_lower():
							browser_js_props.append(prop_name)
					
					if not browser_js_props.is_empty():
						print("  JS-related properties: %s" % str(browser_js_props))
	
	# Look for getter methods that might return browser objects
	print("\n=== BROWSER GETTER METHODS ===")
	var browser_getters: Array[String] = []
	for method in method_list:
		var name: String = method.name
		var name_lower: String = name.to_lower()
		if (name.begins_with("get_") and ("browser" in name_lower or "webview" in name_lower or "page" in name_lower or "frame" in name_lower)) or name == "get_browser" or name == "get_webview":
			browser_getters.append(name)
	
	if browser_getters.is_empty():
		print("No browser getter methods found.")
	else:
		print("Browser getters: %s" % str(browser_getters))
		# Try to call them
		for getter_name in browser_getters:
			print("  Attempting %s()..." % getter_name)
			# Note: Can't actually call in EditorScript, but we can see the signature
	
	# Test common method name variations
	print("\n=== TESTING COMMON METHOD NAMES ===")
	var test_methods: Array[String] = [
		"execute_js", "evaluate_js", "run_js", "eval_js",
		"execute_javascript", "evaluate_javascript",
		"execute_script", "evaluate_script", "run_script",
		"call_js", "call_javascript", "call_script"
	]
	
	var found_methods: Array[String] = []
	for method_name in test_methods:
		if web_view.has_method(method_name):
			found_methods.append(method_name)
	
	if found_methods.is_empty():
		print("No common JS execution method names found.")
	else:
		print("Found methods: %s" % str(found_methods))
	
	# Check signals
	print("\n=== SIGNALS ===")
	var signal_list := web_view.get_signal_list()
	var browser_signals: Array[String] = []
	for signal_info in signal_list:
		var name: String = signal_info.name
		var name_lower: String = name.to_lower()
		if "browser" in name_lower or "webview" in name_lower or "page" in name_lower or "frame" in name_lower or "load" in name_lower or "ready" in name_lower:
			browser_signals.append(name)
	
	if browser_signals.is_empty():
		print("No browser-related signals found.")
		print("Total signals: %d" % signal_list.size())
	else:
		print("Browser-related signals: %s" % str(browser_signals))
	
	print("=== GDCef Bridge Test End ===")
	
	scene.queue_free()

