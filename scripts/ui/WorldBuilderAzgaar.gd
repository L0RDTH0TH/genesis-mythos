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
	# Try to get the web view node - it might be a placeholder if GDExtension isn't loaded
	var web_view_node = get_node_or_null("AzgaarWebView")
	if web_view_node:
		# Check if it's a valid GDCef instance (not a placeholder)
		if web_view_node.get_class() == "GDCef" or web_view_node.has_method("load_url"):
			web_view = web_view_node
		else:
			MythosLogger.warn("WorldBuilderAzgaar", "AzgaarWebView is a placeholder - GDCef extension may not be loaded")
			MythosLogger.warn("WorldBuilderAzgaar", "Node class: %s" % web_view_node.get_class())
	
	if azgaar_integrator:
		azgaar_integrator.copy_azgaar_to_user()
		if web_view and web_view.has_method("load_url"):
			var url: String = azgaar_integrator.get_azgaar_url()
			web_view.load_url(url)
			MythosLogger.info("WorldBuilderAzgaar", "Azgaar WebView loaded", {"url": url})
		else:
			MythosLogger.error("WorldBuilderAzgaar", "AzgaarWebView node not found or GDCef extension not loaded")
			MythosLogger.error("WorldBuilderAzgaar", "Please ensure gdCEF extension is properly installed and Godot is restarted")
	else:
		MythosLogger.error("WorldBuilderAzgaar", "AzgaarIntegrator singleton not found")

func reload_azgaar() -> void:
	"""Reload the Azgaar WebView."""
	if web_view and web_view.has_method("reload"):
		web_view.reload()
		MythosLogger.debug("WorldBuilderAzgaar", "Azgaar WebView reloaded")

