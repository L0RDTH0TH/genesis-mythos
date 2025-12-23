# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderAzgaar.gd
# ║ Desc: Controls Azgaar WebView embedding and communication in WorldBuilderUI
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Control

@onready var web_view: GDCef = $AzgaarWebView
@onready var azgaar_integrator: Node = get_node("/root/AzgaarIntegrator")

func _ready() -> void:
	"""Initialize Azgaar WebView on ready."""
	if azgaar_integrator:
		azgaar_integrator.copy_azgaar_to_user()
		if web_view:
			var url := azgaar_integrator.get_azgaar_url()
			web_view.load_url(url)
			MythosLogger.info("WorldBuilderAzgaar", "Azgaar WebView loaded", {"url": url})
		else:
			MythosLogger.error("WorldBuilderAzgaar", "AzgaarWebView node not found")
	else:
		MythosLogger.error("WorldBuilderAzgaar", "AzgaarIntegrator singleton not found")

func reload_azgaar() -> void:
	"""Reload the Azgaar WebView."""
	if web_view:
		web_view.reload()
		MythosLogger.debug("WorldBuilderAzgaar", "Azgaar WebView reloaded")

