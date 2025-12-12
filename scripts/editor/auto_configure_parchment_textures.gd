# ╔═══════════════════════════════════════════════════════════
# ║ auto_configure_parchment_textures.gd
# ║ Desc: Automatically configure parchment texture import settings on project load
# ║ Author: Lordthoth
# ║ Usage: Place in res://addons/auto_config_parchment/plugin.gd as an EditorPlugin
# ╚═══════════════════════════════════════════════════════════
@tool
extends EditorPlugin

## Auto-configure parchment texture import settings when files are imported


func _enter_tree() -> void:
	"""Called when plugin is enabled."""
	# Connect to filesystem signals
	var filesystem: EditorFileSystem = EditorInterface.get_resource_filesystem()
	if filesystem:
		filesystem.filesystem_changed.connect(_on_filesystem_changed)
	
	print("AutoConfigureParchment: Plugin enabled - monitoring texture imports")


func _exit_tree() -> void:
	"""Called when plugin is disabled."""
	var filesystem: EditorFileSystem = EditorInterface.get_resource_filesystem()
	if filesystem:
		filesystem.filesystem_changed.disconnect(_on_filesystem_changed)


func _on_filesystem_changed() -> void:
	"""Called when filesystem changes - check if parchment textures were imported."""
	var parchment_files: Array[String] = [
		"res://assets/textures/ui/parchment_background.png",
		"res://assets/textures/ui/parchment_stain_overlay.png"
	]
	
	for file_path in parchment_files:
		if ResourceLoader.exists(file_path):
			_configure_texture_import(file_path)


func _configure_texture_import(file_path: String) -> void:
	"""Configure import settings for a texture file."""
	# This is a simplified version - actual implementation would use
	# EditorFileSystem API to modify import settings
	print("AutoConfigureParchment: Would configure: ", file_path)
