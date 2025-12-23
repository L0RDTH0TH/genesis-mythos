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
	
	MythosLogger.debug("WorldBuilderAzgaar", "Found AzgaarWebView node", {
		"class": node_class,
		"has_load_url": has_load_url,
		"node_type": typeof(web_view_node),
		"is_inside_tree": web_view_node.is_inside_tree() if web_view_node else false
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
		MythosLogger.warn("WorldBuilderAzgaar", "This usually means the scene was saved before gdCEF was installed")
		MythosLogger.warn("WorldBuilderAzgaar", "Try removing and re-adding the GDCef node in the editor")
		return
	
	# Initialize Azgaar
	if azgaar_integrator:
		azgaar_integrator.copy_azgaar_to_user()
		if web_view and web_view.has_method("load_url"):
			var url: String = azgaar_integrator.get_azgaar_url()
			web_view.load_url(url)
			MythosLogger.info("WorldBuilderAzgaar", "Azgaar WebView loaded successfully", {"url": url})
		else:
			MythosLogger.error("WorldBuilderAzgaar", "AzgaarWebView found but load_url method not available")
	else:
		MythosLogger.error("WorldBuilderAzgaar", "AzgaarIntegrator singleton not found")

func reload_azgaar() -> void:
	"""Reload the Azgaar WebView."""
	if web_view and web_view.has_method("reload"):
		web_view.reload()
		MythosLogger.debug("WorldBuilderAzgaar", "Azgaar WebView reloaded")

