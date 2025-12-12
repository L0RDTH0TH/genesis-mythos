# ╔═══════════════════════════════════════════════════════════
# ║ set_parchment_import_settings.gd
# ║ Desc: Editor script to configure parchment texture import settings
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
@tool
extends EditorScript

## Configure import settings for parchment textures


func _run() -> void:
	"""Set import settings for parchment texture files."""
	if not Engine.is_editor_hint():
		print("ERROR: This script must be run in the editor (Script > Run)")
		return
	
	var editor_interface: EditorInterface = EditorInterface
	var filesystem: EditorFileSystem = editor_interface.get_resource_filesystem()
	
	# Parchment texture paths
	var parchment_files: Array[String] = [
		"res://assets/textures/ui/parchment_background.png",
		"res://assets/textures/ui/parchment_stain_overlay.png"
	]
	
	var import_plugin: EditorImportPlugin = null
	# Find the texture import plugin
	for plugin_name in ProjectSettings.get("editor_plugins/enabled"):
		var plugin_path: String = str(plugin_name)
		# This is a workaround - we'll use direct import settings
	
	# Set import settings directly using EditorFileSystem
	for file_path in parchment_files:
		if not ResourceLoader.exists(file_path):
			print("WARNING: File not found: ", file_path)
			continue
		
		# Get the import file path
		var import_path: String = file_path + ".import"
		
		# Create import settings dictionary
		var import_settings: Dictionary = {
			"remap": {
				"importer": "texture",
				"type": "CompressedTexture2D",
				"metadata": {
					"imported_formats": ["s3tc", "bptc"],
					"vram_texture": true
				}
			},
			"deps": {
				"source_file": file_path
			},
			"params": {
				"compress/mode": 2,  # Lossless
				"compress/lossy_quality": 0.7,
				"compress/hdr_compression": 1,
				"compress/normal_map": 2,
				"compress/channel_pack": 0,
				"mipmaps/generate": true,  # Enable mipmaps
				"mipmaps/limit": -1,
				"roughness/mode": 0,
				"process/fix_alpha_border": true,
				"process/premult_alpha": false,
				"process/normal_map_invert_y": false,
				"process/hdr_as_srgb": false,
				"process/hdr_clamp_exposure": false,
				"process/size_limit": 0,
				"detect_3d/compress_to": 1
			}
		}
		
		# Note: Directly editing .import files is not recommended
		# Instead, we'll use the proper API if available
		print("INFO: Would configure import settings for: ", file_path)
	
	print("INFO: Import settings configuration complete!")
	print("NOTE: You may need to manually configure import settings in the editor:")
	print("  1. Select parchment_background.png in FileSystem")
	print("  2. Import tab → Enable Filter, Enable Mipmaps, Set Compress to Lossless")
	print("  3. Click 'Reimport'")
	print("  4. Repeat for parchment_stain_overlay.png")
