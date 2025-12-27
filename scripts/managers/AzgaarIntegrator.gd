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
	# Check if destination exists and is up-to-date
	var source_index_path: String = AZGAAR_BUNDLE_PATH.path_join("index.html")
	var dest_index_path: String = AZGAAR_USER_PATH.path_join("index.html")
	
	if FileAccess.file_exists(dest_index_path):
		# Compare modification times
		var source_time: int = FileAccess.get_modified_time(source_index_path)
		var dest_time: int = FileAccess.get_modified_time(dest_index_path)
		
		if dest_time >= source_time:
			# Destination is up-to-date, skip copy
			MythosLogger.debug("AzgaarIntegrator", "Azgaar files are up-to-date, skipping copy")
			return
	
	# Files need to be copied (missing or outdated)
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
	MythosLogger.info("AzgaarIntegrator", "Azgaar bundled files copied to user://azgaar/ for writability")

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

func write_options(options: Dictionary) -> bool:
	"""Write Azgaar options to user://azgaar/options.json."""
	var file_path: String = AZGAAR_USER_PATH.path_join(OPTIONS_FILE)
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		MythosLogger.error("AzgaarIntegrator", "Failed to open options.json for writing", {"error": FileAccess.get_open_error(), "path": file_path})
		return false
	
	var json_string := JSON.stringify(options, "  ", false)
	file.store_string(json_string)
	file.close()
	MythosLogger.info("AzgaarIntegrator", "Wrote options.json", {"path": file_path})
	return true

func get_azgaar_url() -> String:
	"""Get the file:// URL path to Azgaar index.html in user:// directory."""
	var user_path := OS.get_user_data_dir()
	var azgaar_path := user_path.path_join("azgaar").path_join("index.html")
	# Convert to file:// URL format
	return "file://" + azgaar_path

func get_azgaar_http_url() -> String:
	"""Get the http:// URL to Azgaar index.html via embedded server."""
	var azgaar_server: Node = get_node_or_null("/root/AzgaarServer")
	if azgaar_server and azgaar_server.has_method("is_running") and azgaar_server.has_method("get_port"):
		if azgaar_server.is_running():
			var server_port: int = azgaar_server.get_port()
			return "http://127.0.0.1:%d/index.html" % server_port
	
	# Fallback to file:// if server not available
	return ""

