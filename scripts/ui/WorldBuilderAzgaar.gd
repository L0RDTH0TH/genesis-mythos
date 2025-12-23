# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderAzgaar.gd
# ║ Desc: Controls Azgaar WebView embedding and communication in WorldBuilderUI
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Control

var web_view = null  # GDCef - will be set in _ready() to handle GDExtension loading
@onready var azgaar_integrator: Node = get_node("/root/AzgaarIntegrator")

func _ready() -> void:
	"""Initialize Azgaar WebView on ready."""
	# Use call_deferred to ensure node tree is fully initialized
	call_deferred("_initialize_webview")

func _initialize_webview() -> void:
	"""Initialize the Azgaar WebView after the node tree is ready."""
	# Try to get the web view node - it might be a placeholder if GDExtension isn't loaded
	var web_view_node = get_node_or_null("AzgaarWebView")
	
	if not web_view_node:
		MythosLogger.error("WorldBuilderAzgaar", "AzgaarWebView node not found in scene tree")
		# List all children for debugging
		var children = get_children()
		var child_names = []
		for child in children:
			child_names.append(child.name)
		MythosLogger.debug("WorldBuilderAzgaar", "Current node: %s, children: %s" % [name, child_names])
		return
	
	# Log node information for debugging
	var node_class = web_view_node.get_class()
	var has_load_url = web_view_node.has_method("load_url") if web_view_node else false
	
	# List all available methods for debugging
	var methods = []
	if web_view_node:
		var method_list = web_view_node.get_method_list()
		for method_info in method_list:
			if method_info.name.begins_with("load") or method_info.name.begins_with("navigate") or method_info.name.begins_with("url"):
				methods.append(method_info.name)
	
	MythosLogger.debug("WorldBuilderAzgaar", "Found AzgaarWebView node", {
		"class": node_class,
		"has_load_url": has_load_url,
		"node_type": typeof(web_view_node),
		"is_inside_tree": web_view_node.is_inside_tree() if web_view_node else false,
		"relevant_methods": methods
	})
	
	# Check if it's a valid GDCef instance
	# GDCef should have the class name "GDCef" and the load_url method
	if node_class == "GDCef":
		web_view = web_view_node
		MythosLogger.info("WorldBuilderAzgaar", "AzgaarWebView node is valid GDCef instance (class: %s)" % node_class)
	elif has_load_url:
		# Fallback: if it has the method, use it even if class name doesn't match
		web_view = web_view_node
		MythosLogger.info("WorldBuilderAzgaar", "AzgaarWebView node has load_url method (class: %s)" % node_class)
	else:
		MythosLogger.warn("WorldBuilderAzgaar", "AzgaarWebView appears to be a placeholder")
		MythosLogger.warn("WorldBuilderAzgaar", "Node class: %s, has load_url: %s" % [node_class, has_load_url])
		
		# Try to create a new GDCef node programmatically if ClassDB knows about it
		if ClassDB.class_exists("GDCef"):
			MythosLogger.info("WorldBuilderAzgaar", "GDCef class exists in ClassDB, attempting to create new node")
			# Remove the placeholder
			web_view_node.queue_free()
			# Wait a frame for the node to be removed
			await get_tree().process_frame
			# Create a new GDCef node
			var new_web_view = ClassDB.instantiate("GDCef")
			if new_web_view:
				new_web_view.name = "AzgaarWebView"
				add_child(new_web_view)
				new_web_view.set_anchors_preset(Control.PRESET_FULL_RECT)
				new_web_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				new_web_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
				new_web_view.visible = true
				web_view = new_web_view
				MythosLogger.info("WorldBuilderAzgaar", "Created new GDCef node programmatically")
			else:
				MythosLogger.error("WorldBuilderAzgaar", "Failed to instantiate GDCef via ClassDB")
				return
		else:
			MythosLogger.error("WorldBuilderAzgaar", "GDCef class not found in ClassDB")
			MythosLogger.error("WorldBuilderAzgaar", "Please ensure gdCEF extension is properly installed and Godot is restarted")
			return
	
	# Initialize Azgaar
	if azgaar_integrator:
		azgaar_integrator.copy_azgaar_to_user()
		var url: String = azgaar_integrator.get_azgaar_url()
		
		# Try different method names that gdCEF might use
		if web_view:
			if web_view.has_method("load_url"):
				web_view.load_url(url)
				MythosLogger.info("WorldBuilderAzgaar", "Azgaar WebView loaded via load_url()", {"url": url})
			elif web_view.has_method("navigate_to_url"):
				web_view.navigate_to_url(url)
				MythosLogger.info("WorldBuilderAzgaar", "Azgaar WebView loaded via navigate_to_url()", {"url": url})
			elif web_view.has_method("set_url"):
				web_view.set_url(url)
				MythosLogger.info("WorldBuilderAzgaar", "Azgaar WebView loaded via set_url()", {"url": url})
			elif web_view.has_method("url"):
				web_view.url = url
				MythosLogger.info("WorldBuilderAzgaar", "Azgaar WebView loaded via url property", {"url": url})
			else:
				# List all methods and properties for debugging
				var all_methods = []
				var method_list = web_view.get_method_list()
				for method_info in method_list:
					all_methods.append(method_info.name)
				
				var all_properties = []
				var property_list = web_view.get_property_list()
				for prop_info in property_list:
					if "url" in prop_info.name.to_lower() or "address" in prop_info.name.to_lower():
						all_properties.append(prop_info.name)
				
				MythosLogger.error("WorldBuilderAzgaar", "AzgaarWebView found but no URL loading method available")
				MythosLogger.error("WorldBuilderAzgaar", "Node class: %s" % web_view.get_class())
				var url_methods: Array[String] = []
				for m in all_methods:
					var method_name_lower: String = m.to_lower()
					if "url" in method_name_lower or "navigate" in method_name_lower or "load" in method_name_lower:
						url_methods.append(m)
				MythosLogger.error("WorldBuilderAzgaar", "URL-related methods: %s" % str(url_methods))
				MythosLogger.error("WorldBuilderAzgaar", "URL-related properties: %s" % str(all_properties))
				MythosLogger.debug("WorldBuilderAzgaar", "All methods (first 20): %s" % str(all_methods.slice(0, 20)))
		else:
			MythosLogger.error("WorldBuilderAzgaar", "web_view is null after initialization")
	else:
		MythosLogger.error("WorldBuilderAzgaar", "AzgaarIntegrator singleton not found")

func reload_azgaar() -> void:
	"""Reload the Azgaar WebView."""
	if web_view and web_view.has_method("reload"):
		web_view.reload()
		MythosLogger.debug("WorldBuilderAzgaar", "Azgaar WebView reloaded")

