# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderAzgaar.gd
# ║ Desc: Controls Azgaar WebView embedding and communication in WorldBuilderUI
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Control

## Reference to the WebView node (from gdCEF addon)
@onready var web_view: Control = $AzgaarWebView

## Reference to AzgaarIntegrator singleton
var azgaar_integrator: Node

func _ready() -> void:
	"""Initialize Azgaar WebView and load the embedded application."""
	# Get AzgaarIntegrator singleton
	azgaar_integrator = get_node_or_null("/root/AzgaarIntegrator")
	if not azgaar_integrator:
		push_error("WorldBuilderAzgaar: AzgaarIntegrator singleton not found")
		return
	
	# Ensure Azgaar files are copied to user:// directory
	azgaar_integrator.copy_azgaar_to_user()
	
	# Load Azgaar in WebView
	if web_view:
		# Check if WebView has load_url method (gdCEF must be installed)
		if web_view.has_method("load_url"):
			var azgaar_path: String = azgaar_integrator.get_azgaar_url()
			# Convert user:// path to absolute file path, then to file:// URL
			var absolute_path: String = ProjectSettings.globalize_path(azgaar_path)
			var file_url: String = "file://" + absolute_path
			web_view.load_url(file_url)
			print("WorldBuilderAzgaar: Loading Azgaar from ", file_url)
		else:
			push_warning("WorldBuilderAzgaar: WebView node does not have load_url() method. Please install gdCEF addon and change node type from 'Control' to 'WebView'.")
	else:
		push_error("WorldBuilderAzgaar: WebView node not found")

func reload_azgaar() -> void:
	"""Reload the Azgaar WebView."""
	if web_view and web_view.has_method("reload"):
		web_view.reload()
		print("WorldBuilderAzgaar: Reloaded Azgaar WebView")
	else:
		push_warning("WorldBuilderAzgaar: Cannot reload - WebView not available or gdCEF not installed")

