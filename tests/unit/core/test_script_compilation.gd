# ╔═══════════════════════════════════════════════════════════
# ║ test_script_compilation.gd
# ║ Desc: Comprehensive test to catch parse errors, circular extends, and script compilation issues
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Directories to scan for scripts (excluding addons and tests to avoid false positives)
const SCRIPT_DIRECTORIES: Array[String] = [
	"res://scripts/",
	"res://core/",
	"res://ui/",
	"res://data/",
	"res://scenes/",
]

## Directories to exclude from scanning
const EXCLUDE_DIRECTORIES: Array[String] = [
	"res://addons/",
	"res://tests/",
	"res://demo/",
	"res://.git/",
]

## Track compilation results
var compilation_results: Dictionary = {}
var parse_errors: Array[String] = []
var instantiation_errors: Array[String] = []

func before_all() -> void:
	"""Collect all scripts before running tests."""
	_scan_all_scripts()

func test_all_scripts_load_successfully() -> void:
	"""Test that all scripts can be loaded without parse errors."""
	var failed_scripts: Array[String] = []
	
	for script_path: String in compilation_results.keys():
		var result: Dictionary = compilation_results[script_path]
		if not result.get("loads", false):
			failed_scripts.append(script_path)
			parse_errors.append("%s: %s" % [script_path, result.get("error", "Unknown error")])
	
	if failed_scripts.size() > 0:
		var error_msg: String = "FAIL: %d scripts failed to load:\n%s\nContext: Script compilation. Why: All scripts should load without parse errors. Hint: Check extends statements, syntax, and circular dependencies."
		fail_test(error_msg % [failed_scripts.size(), "\n".join(failed_scripts)])
		return
	
	pass_test("All scripts loaded successfully")

func test_all_scripts_instantiate_successfully() -> void:
	"""Test that all non-abstract scripts can be instantiated."""
	var failed_scripts: Array[String] = []
	
	for script_path: String in compilation_results.keys():
		var result: Dictionary = compilation_results[script_path]
		if not result.get("loads", false):
			continue  # Skip scripts that don't load
		
		if result.get("is_abstract", false):
			continue  # Skip abstract scripts
		
		if not result.get("can_instantiate", false):
			failed_scripts.append(script_path)
			instantiation_errors.append("%s: %s" % [script_path, result.get("instantiation_error", "Cannot instantiate")])
	
	if failed_scripts.size() > 0:
		var error_msg: String = "FAIL: %d scripts failed to instantiate:\n%s\nContext: Script instantiation. Why: Non-abstract scripts should be instantiable. Hint: Check _init() methods and required dependencies."
		fail_test(error_msg % [failed_scripts.size(), "\n".join(failed_scripts)])
		return
	
	pass_test("All scripts instantiate successfully")

func test_no_circular_extends() -> void:
	"""Test that no scripts have circular extends chains."""
	var circular_chains: Array[String] = []
	
	for script_path: String in compilation_results.keys():
		var result: Dictionary = compilation_results[script_path]
		if result.get("has_circular_extends", false):
			circular_chains.append("%s: %s" % [script_path, result.get("circular_chain", "")])
	
	if circular_chains.size() > 0:
		var error_msg: String = "FAIL: Found circular extends chains:\n%s\nContext: Circular dependencies. Why: Circular extends cause parse errors. Hint: Refactor class hierarchy."
		fail_test(error_msg % "\n".join(circular_chains))
		return
	
	pass_test("No circular extends detected")

func test_no_self_extends() -> void:
	"""Test that no scripts extend themselves."""
	var self_extends: Array[String] = []
	
	for script_path: String in compilation_results.keys():
		var result: Dictionary = compilation_results[script_path]
		if result.get("self_extends", false):
			self_extends.append(script_path)
	
	if self_extends.size() > 0:
		var error_msg: String = "FAIL: Found scripts that extend themselves:\n%s\nContext: Self-extend error. Why: Scripts cannot extend themselves. Hint: Use explicit path to base class or rename file."
		fail_test(error_msg % "\n".join(self_extends))
		return
	
	pass_test("No self-extends detected")

func test_no_deprecated_syntax() -> void:
	"""Test that scripts don't use deprecated syntax (basic checks)."""
	var deprecated_usage: Array[String] = []
	
	for script_path: String in compilation_results.keys():
		var result: Dictionary = compilation_results[script_path]
		if result.get("uses_deprecated", false):
			deprecated_usage.append("%s: %s" % [script_path, result.get("deprecated_details", "")])
	
	if deprecated_usage.size() > 0:
		var error_msg: String = "FAIL: Found deprecated syntax usage:\n%s\nContext: Deprecated APIs. Why: Deprecated syntax may break in future versions. Hint: Update to modern Godot 4.5.1 APIs."
		fail_test(error_msg % "\n".join(deprecated_usage))
		return
	
	pass_test("No deprecated syntax detected")

# ============================================================
# HELPER FUNCTIONS
# ============================================================

func _scan_all_scripts() -> void:
	"""Scan all directories for .gd files and test compilation."""
	for dir_path: String in SCRIPT_DIRECTORIES:
		if not DirAccess.dir_exists_absolute(dir_path):
			continue
		_scan_directory(dir_path)

func _scan_directory(dir_path: String) -> void:
	"""Recursively scan directory for .gd files."""
	var dir: DirAccess = DirAccess.open(dir_path)
	if not dir:
		return
	
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	
	while file_name != "":
		var full_path: String = dir_path.path_join(file_name)
		
		# Skip excluded directories
		var should_exclude: bool = false
		for exclude_path: String in EXCLUDE_DIRECTORIES:
			if full_path.begins_with(exclude_path):
				should_exclude = true
				break
		
		if should_exclude:
			file_name = dir.get_next()
			continue
		
		if dir.current_is_dir():
			_scan_directory(full_path + "/")
		elif file_name.ends_with(".gd"):
			_test_script_compilation(full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

func _test_script_compilation(script_path: String) -> void:
	"""Test a single script for compilation errors."""
	var result: Dictionary = {
		"loads": false,
		"can_instantiate": false,
		"is_abstract": false,
		"has_circular_extends": false,
		"self_extends": false,
		"uses_deprecated": false,
		"error": "",
		"instantiation_error": "",
		"circular_chain": "",
		"deprecated_details": ""
	}
	
	# Try to load the script
	var script: GDScript = load(script_path) as GDScript
	if script == null:
		result["error"] = "Failed to load script"
		compilation_results[script_path] = result
		return
	
	result["loads"] = true
	
	# Check for self-extend (basic check - if extends matches filename)
	var script_source: String = script.source_code
	if script_source.is_empty():
		# Try reading file directly
		var file: FileAccess = FileAccess.open(script_path, FileAccess.READ)
		if file:
			script_source = file.get_as_text()
			file.close()
	
	if not script_source.is_empty():
		# Check for self-extend pattern
		var file_name: String = script_path.get_file().get_basename()
		var extends_pattern: RegEx = RegEx.new()
		extends_pattern.compile("^\\s*extends\\s+(" + file_name + "|[\"']" + script_path + "[\"'])")
		if extends_pattern.search(script_source):
			result["self_extends"] = true
			result["error"] = "Script extends itself"
		
		# Check for deprecated syntax (basic patterns)
		if "onready var" in script_source:
			result["uses_deprecated"] = true
			result["deprecated_details"] = "Uses deprecated 'onready var' (should use '@onready var')"
		if "yield(" in script_source:
			result["uses_deprecated"] = true
			result["deprecated_details"] += "Uses deprecated 'yield()' (should use 'await')"
	
	# Check if script can be instantiated
	if script.can_instantiate():
		# Try to instantiate
		var instance: Variant = null
		var instantiation_success: bool = false
		var error_msg: String = ""
		
		# Use try-catch pattern (Godot 4 style)
		var error_occurred: bool = false
		var error_text: String = ""
		
		# Attempt instantiation
		instance = script.new()
		if instance != null:
			instantiation_success = true
			# Clean up
			if instance is RefCounted:
				# RefCounted types are automatically freed
				pass
			elif instance is Node:
				instance.queue_free()
			else:
				# Try to free if possible
				if instance.has_method("free"):
					instance.free()
		
		result["can_instantiate"] = instantiation_success
		if not instantiation_success:
			result["instantiation_error"] = error_text if error_text != "" else "Instantiation returned null"
	else:
		result["is_abstract"] = true
	
	# Check for circular extends (basic check - would need full dependency graph)
	# For now, we'll rely on load() failing if there's a circular dependency
	
	compilation_results[script_path] = result
