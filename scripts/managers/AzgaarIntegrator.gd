# ╔═══════════════════════════════════════════════════════════
# ║ AzgaarIntegrator.gd
# ║ Desc: Manages bundling, copying, and config for embedded Azgaar FMG
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

const AZGAAR_BUNDLE_PATH: String = "res://tools/azgaar/"
const AZGAAR_USER_PATH: String = "user://azgaar/"
const OPTIONS_FILE: String = "options.json"

func _ready() -> void:
	copy_azgaar_to_user()

func copy_azgaar_to_user() -> void:
	"""Copy Azgaar bundled files to user://azgaar/ for writability."""
	var source_dir := DirAccess.open(AZGAAR_BUNDLE_PATH)
	if not source_dir:
		push_error("Failed to open Azgaar bundle path: " + AZGAAR_BUNDLE_PATH)
		return
	
	# Create user directory if it doesn't exist
	var user_dir := DirAccess.open("user://")
	if not user_dir:
		push_error("Failed to open user:// directory")
		return
	
	if not user_dir.dir_exists("azgaar"):
		var err := user_dir.make_dir("azgaar")
		if err != OK:
			push_error("Failed to create user://azgaar/ directory: " + str(err))
			return
	
	# Copy files recursively
	var target_dir := DirAccess.open("user://azgaar/")
	if not target_dir:
		push_error("Failed to open user://azgaar/ directory")
		return
	
	_copy_directory_recursive(source_dir, target_dir, AZGAAR_BUNDLE_PATH, "user://azgaar/")
	print("Azgaar bundled files copied to user://azgaar/ for writability")

func _copy_directory_recursive(source_dir: DirAccess, target_dir: DirAccess, source_path: String, target_path: String) -> void:
	"""Recursively copy directory contents."""
	source_dir.list_dir_begin()
	var file_name := source_dir.get_next()
	
	while file_name != "":
		if source_dir.current_is_dir():
			if file_name != "." and file_name != "..":
				var new_source_path := source_path.path_join(file_name)
				var new_target_path := target_path.path_join(file_name)
				
				# Create subdirectory in target
				if not target_dir.dir_exists(file_name):
					var err := target_dir.make_dir(file_name)
					if err != OK:
						push_warning("Failed to create directory: " + new_target_path)
						file_name = source_dir.get_next()
						continue
				
				# Recursively copy subdirectory
				var new_source_dir := DirAccess.open(new_source_path)
				var new_target_dir := DirAccess.open(new_target_path)
				if new_source_dir and new_target_dir:
					_copy_directory_recursive(new_source_dir, new_target_dir, new_source_path, new_target_path)
		else:
			# Copy file
			var source_file_path := source_path.path_join(file_name)
			var target_file_path := target_path.path_join(file_name)
			
			var source_file := FileAccess.open(source_file_path, FileAccess.READ)
			if source_file:
				var content := source_file.get_as_text()
				source_file.close()
				
				var target_file := FileAccess.open(target_file_path, FileAccess.WRITE)
				if target_file:
					target_file.store_string(content)
					target_file.close()
				else:
					push_warning("Failed to write file: " + target_file_path)
			else:
				push_warning("Failed to read file: " + source_file_path)
		
		file_name = source_dir.get_next()
	
	source_dir.list_dir_end()

func write_options(config: Dictionary) -> bool:
	"""Write options.json to user://azgaar/options.json."""
	var full_path := AZGAAR_USER_PATH.path_join(OPTIONS_FILE)
	var file := FileAccess.open(full_path, FileAccess.WRITE)
	if file:
		var json_string := JSON.stringify(config, "  ", false)
		file.store_string(json_string)
		file.close()
		print("options.json written to ", full_path)
		return true
	push_error("Failed to write options.json to " + full_path)
	return false

func get_azgaar_url() -> String:
	"""Get the URL path to Azgaar index.html in user:// directory."""
	return AZGAAR_USER_PATH.path_join("index.html")

