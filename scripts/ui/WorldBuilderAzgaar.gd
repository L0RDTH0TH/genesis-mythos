# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderAzgaar.gd
# ║ Desc: Controls Azgaar WebView embedding and communication in WorldBuilderUI
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Control

@onready var web_view: GDCef = $AzgaarWebView
@onready var azgaar_integrator: Node = get_node("/root/AzgaarIntegrator")  # Assuming autoload later

func _ready() -> void:
	"""Initialize Azgaar WebView after files are copied."""
	# Initial load after files are copied
	if azgaar_integrator:
		azgaar_integrator.copy_azgaar_to_user()  # Ensure fresh copy
		var url_path := azgaar_integrator.get_azgaar_url()
		# Convert user:// path to file:// URL for GDCef
		# user:// paths need to be converted to absolute paths
		var absolute_path := ProjectSettings.globalize_path(url_path)
		var file_url := "file://" + absolute_path
		web_view.load_url(file_url)

func reload_azgaar() -> void:
	"""Reload the Azgaar WebView."""
	if web_view:
		web_view.reload()

