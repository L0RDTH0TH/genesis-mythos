# ╔═══════════════════════════════════════════════════════════
# ║ UIComplianceTest.gd
# ║ Desc: General UI compliance tests - hard-coded values, theme usage, responsiveness
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## UIConstants reference for validation
const UIConstants = preload("res://scripts/ui/UIConstants.gd")

## Theme path that should be used everywhere
const EXPECTED_THEME_PATH: String = "res://themes/bg3_theme.tres"

## Directories to scan for UI scenes
const UI_DIRECTORIES: Array[String] = [
	"res://scenes/ui/",
	"res://scenes/tools/",
	"res://scenes/character_creation/",
	"res://ui/",
	"res://scenes/"
]

## Allowed hard-coded values (small numbers that are acceptable)
const ALLOWED_SMALL_VALUES: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

## Files to exclude from scanning
const EXCLUDE_PATTERNS: Array[String] = [
	"test_",
	".uid",
	"addons/",
	"tests/"
]

## Collected violations
var violations: Array[Dictionary] = []

func before_all() -> void:
	"""Setup before all tests."""
	violations.clear()

func test_no_hard_coded_custom_minimum_size() -> void:
	"""Test that no UI scenes have hard-coded custom_minimum_size > 10."""
	var found_violations: Array[Dictionary] = []
	
	for dir_path in UI_DIRECTORIES:
		if not DirAccess.dir_exists_absolute(dir_path):
			continue
		
		var files: Array[String] = _get_scene_files_in_directory(dir_path)
		for file_path in files:
			var file_violations: Array[Dictionary] = _check_file_for_hard_coded_sizes(file_path)
			found_violations.append_array(file_violations)
	
	if found_violations.size() > 0:
		var violation_msg: String = "Found %d hard-coded custom_minimum_size violations:\n" % found_violations.size()
		for v in found_violations:
			violation_msg += "  - %s: %s\n" % [v.file, v.details]
		assert_true(false, violation_msg)
	else:
		pass_test("No hard-coded custom_minimum_size values found")

func test_no_hard_coded_offsets() -> void:
	"""Test that no UI scenes have hard-coded offset_* values > 10."""
	var found_violations: Array[Dictionary] = []
	
	for dir_path in UI_DIRECTORIES:
		if not DirAccess.dir_exists_absolute(dir_path):
			continue
		
		var files: Array[String] = _get_scene_files_in_directory(dir_path)
		for file_path in files:
			var file_violations: Array[Dictionary] = _check_file_for_hard_coded_offsets(file_path)
			found_violations.append_array(file_violations)
	
	if found_violations.size() > 0:
		var violation_msg: String = "Found %d hard-coded offset violations:\n" % found_violations.size()
		for v in found_violations:
			violation_msg += "  - %s: %s\n" % [v.file, v.details]
		assert_true(false, violation_msg)
	else:
		pass_test("No hard-coded offset values found")

func test_theme_applied_to_scenes() -> void:
	"""Test that major UI scenes have theme applied."""
	var scenes_to_check: Array[String] = [
		"res://scenes/MainMenu.tscn",
		"res://ui/world_builder/WorldBuilderUI.tscn",
		"res://scenes/character_creation/CharacterCreationRoot.tscn"
	]
	
	var missing_themes: Array[String] = []
	
	for scene_path in scenes_to_check:
		if not ResourceLoader.exists(scene_path):
			continue
		
		var scene_text: String = _read_file_content(scene_path)
		if scene_text.is_empty():
			continue
		
		# Check if theme is referenced in the scene
		var has_theme: bool = scene_text.contains(EXPECTED_THEME_PATH) or scene_text.contains("bg3_theme.tres")
		
		if not has_theme:
			missing_themes.append(scene_path)
	
	if missing_themes.size() > 0:
		assert_true(false, "The following scenes are missing theme application:\n  - %s" % "\n  - ".join(missing_themes))
	else:
		pass_test("All major UI scenes have theme applied")

func test_ui_constants_exists() -> void:
	"""Test that UIConstants.gd exists and has required constants."""
	if not ResourceLoader.exists("res://scripts/ui/UIConstants.gd"):
		assert_true(false, "UIConstants.gd not found at res://scripts/ui/UIConstants.gd")
		return
	
	# Try to load and check constants
	var constants_script: GDScript = load("res://scripts/ui/UIConstants.gd") as GDScript
	if not constants_script:
		assert_true(false, "Failed to load UIConstants.gd as GDScript")
		return
	
	# Check for key constants
	var required_constants: Array[String] = [
		"BUTTON_HEIGHT_SMALL",
		"BUTTON_HEIGHT_MEDIUM",
		"BUTTON_HEIGHT_LARGE",
		"SPACING_SMALL",
		"SPACING_MEDIUM",
		"SPACING_LARGE"
	]
	
	var missing_constants: Array[String] = []
	for const_name in required_constants:
		if not constants_script.get_script_constant_map().has(const_name):
			missing_constants.append(const_name)
	
	if missing_constants.size() > 0:
		assert_true(false, "UIConstants.gd missing required constants: %s" % ", ".join(missing_constants))
	else:
		pass_test("UIConstants.gd exists with all required constants")

func test_responsive_anchors() -> void:
	"""Test that major UI scenes use proper anchors (anchors_preset = 15 for full rect)."""
	var scenes_to_check: Array[String] = [
		"res://scenes/MainMenu.tscn",
		"res://ui/world_builder/WorldBuilderUI.tscn",
		"res://scenes/character_creation/CharacterCreationRoot.tscn"
	]
	
	var missing_anchors: Array[String] = []
	
	for scene_path in scenes_to_check:
		if not ResourceLoader.exists(scene_path):
			continue
		
		var scene_text: String = _read_file_content(scene_path)
		if scene_text.is_empty():
			continue
		
		# Check if root node has anchors_preset = 15 (PRESET_FULL_RECT)
		# Look for root Control node with anchors_preset = 15
		var has_full_rect: bool = scene_text.contains("anchors_preset = 15") or \
		                          scene_text.contains("anchor_right = 1.0") and scene_text.contains("anchor_bottom = 1.0")
		
		if not has_full_rect:
			missing_anchors.append(scene_path)
	
	if missing_anchors.size() > 0:
		assert_true(false, "The following scenes may not have full-rect anchors on root:\n  - %s" % "\n  - ".join(missing_anchors))
	else:
		pass_test("All major UI scenes have proper anchors")

## Helper functions

func _get_scene_files_in_directory(dir_path: String) -> Array[String]:
	"""Get all .tscn files in a directory recursively."""
	var files: Array[String] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	
	if not dir:
		return files
	
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	
	while file_name != "":
		var full_path: String = dir_path.path_join(file_name)
		
		# Skip excluded patterns
		var should_exclude: bool = false
		for pattern in EXCLUDE_PATTERNS:
			if full_path.contains(pattern):
				should_exclude = true
				break
		
		if not should_exclude:
			if dir.current_is_dir():
				# Recursively search subdirectories
				var sub_files: Array[String] = _get_scene_files_in_directory(full_path)
				files.append_array(sub_files)
			elif file_name.ends_with(".tscn"):
				files.append(full_path)
		
		file_name = dir.get_next()
	
	return files

func _check_file_for_hard_coded_sizes(file_path: String) -> Array[Dictionary]:
	"""Check a .tscn file for hard-coded custom_minimum_size values > 10."""
	var violations: Array[Dictionary] = []
	var content: String = _read_file_content(file_path)
	
	if content.is_empty():
		return violations
	
	# Look for custom_minimum_size = Vector2(x, y) patterns
	var regex: RegEx = RegEx.new()
	regex.compile("custom_minimum_size\\s*=\\s*Vector2\\(\\s*(\\d+)\\s*,\\s*(\\d+)\\s*\\)")
	
	var results: Array[RegExMatch] = regex.search_all(content)
	for result in results:
		var x: int = result.get_string(1).to_int()
		var y: int = result.get_string(2).to_int()
		
		if x > 10 and not ALLOWED_SMALL_VALUES.has(x):
			violations.append({
				"file": file_path,
				"details": "custom_minimum_size.x = %d (should use UIConstants)" % x
			})
		if y > 10 and not ALLOWED_SMALL_VALUES.has(y):
			violations.append({
				"file": file_path,
				"details": "custom_minimum_size.y = %d (should use UIConstants)" % y
			})
	
	return violations

func _check_file_for_hard_coded_offsets(file_path: String) -> Array[Dictionary]:
	"""Check a .tscn file for hard-coded offset_* values > 10."""
	var violations: Array[Dictionary] = []
	var content: String = _read_file_content(file_path)
	
	if content.is_empty():
		return violations
	
	# Look for offset_left, offset_top, offset_right, offset_bottom patterns
	var offset_patterns: Array[String] = ["offset_left", "offset_top", "offset_right", "offset_bottom"]
	
	for pattern in offset_patterns:
		var regex: RegEx = RegEx.new()
		regex.compile("%s\\s*=\\s*([\\d\\.]+)" % pattern)
		
		var results: Array[RegExMatch] = regex.search_all(content)
		for result in results:
			var value: float = result.get_string(1).to_float()
			var int_value: int = int(value)
			
			# Allow 0.0 and small values, but flag larger values
			if abs(value) > 10.0 and not ALLOWED_SMALL_VALUES.has(int_value):
				violations.append({
					"file": file_path,
					"details": "%s = %.1f (should use UIConstants or anchors/margins)" % [pattern, value]
				})
	
	return violations

func _read_file_content(file_path: String) -> String:
	"""Read file content as string."""
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return ""
	
	var content: String = file.get_as_text()
	file.close()
	return content
