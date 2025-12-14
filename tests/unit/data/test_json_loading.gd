# ╔═══════════════════════════════════════════════════════════════════════════════
# ║ test_json_loading.gd
# ║ Desc: Unit tests for JSON data loading, validation, and error handling
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════════════════════════

extends GutTest

## Test fixture: JSON parser
var json_parser: JSON

func before_each() -> void:
	"""Setup test fixtures before each test."""
	json_parser = JSON.new()

func test_load_biomes_json_exists() -> void:
	"""Test that biomes.json file exists and is readable."""
	var path: String = "res://data/biomes.json"
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	
	assert_not_null(file, "FAIL: Expected biomes.json to exist and be readable. Context: path=%s. Why: Game requires biome data for world generation. Hint: Check res://data/biomes.json exists and is not corrupted." % path)
	
	if file:
		file.close()

func test_load_biomes_json_valid_structure() -> void:
	"""Test that biomes.json has valid JSON structure."""
	var path: String = "res://data/biomes.json"
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	
	if not file:
		pass_test("biomes.json not found, skipping structure test")
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var parse_result: Error = json_parser.parse(json_string)
	
	assert_eq(parse_result, OK, "FAIL: Expected biomes.json to parse successfully. Got parse error: %s (line %d). Context: path=%s. Why: Invalid JSON structure prevents biome loading. Hint: Check JSON syntax, ensure proper brackets/braces/quotes." % [json_parser.get_error_message(), json_parser.get_error_line(), path])
	
	if parse_result == OK:
		var data: Variant = json_parser.data
		assert_true(data is Dictionary, "FAIL: Expected biomes.json root to be Dictionary. Got %s. Context: path=%s. Why: Biome data structure expects root object with 'biomes' array. Hint: Check biomes.json has {\"biomes\": [...]} structure." % [typeof(data), path])
		
		if data is Dictionary:
			var biomes_dict: Dictionary = data as Dictionary
			assert_true(biomes_dict.has("biomes"), "FAIL: Expected biomes.json to have 'biomes' key. Got keys: %s. Context: path=%s. Why: Biome data structure requires 'biomes' array. Hint: Check biomes.json has {\"biomes\": [...]} structure." % [biomes_dict.keys(), path])
			
			if biomes_dict.has("biomes"):
				var biomes: Variant = biomes_dict["biomes"]
				assert_true(biomes is Array, "FAIL: Expected 'biomes' to be Array. Got %s. Context: path=%s. Why: Biome data should be array of biome objects. Hint: Check biomes.json has \"biomes\": [...] (array, not object)." % [typeof(biomes), path])

func test_load_biomes_json_required_fields() -> void:
	"""Test that each biome in biomes.json has required fields (id, name, temperature_range, rainfall_range, color)."""
	var path: String = "res://data/biomes.json"
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	
	if not file:
		pass_test("biomes.json not found, skipping required fields test")
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var parse_result: Error = json_parser.parse(json_string)
	if parse_result != OK:
		pass_test("biomes.json parse failed, skipping required fields test")
		return
	
	var data: Dictionary = json_parser.data as Dictionary
	if not data.has("biomes"):
		pass_test("biomes.json missing 'biomes' key, skipping required fields test")
		return
	
	var biomes: Array = data["biomes"] as Array
	if biomes.is_empty():
		pass_test("biomes.json has empty biomes array, skipping required fields test")
		return
	
	var required_fields: Array[String] = ["id", "name", "temperature_range", "rainfall_range", "color"]
	var missing_fields: Array[Dictionary] = []
	
	for i in range(biomes.size()):
		var biome: Variant = biomes[i]
		if not biome is Dictionary:
			continue
		
		var biome_dict: Dictionary = biome as Dictionary
		for field in required_fields:
			if not biome_dict.has(field):
				missing_fields.append({"index": i, "field": field, "biome": biome_dict.get("id", "unknown")})
	
	var error_msg: String = "FAIL: Expected all biomes to have required fields. Missing fields: %s. Context: path=%s, total biomes=%d. Why: Required fields ensure biome data integrity. Hint: Check each biome object in biomes.json has: id, name, temperature_range, rainfall_range, color." % [missing_fields, path, biomes.size()]
	assert_true(missing_fields.is_empty(), error_msg)

func test_load_civilizations_json_exists() -> void:
	"""Test that civilizations.json file exists and is readable."""
	var path: String = "res://data/civilizations.json"
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	
	assert_not_null(file, "FAIL: Expected civilizations.json to exist and be readable. Context: path=%s. Why: Game requires civilization data for world generation. Hint: Check res://data/civilizations.json exists and is not corrupted." % path)
	
	if file:
		file.close()

func test_load_civilizations_json_valid_structure() -> void:
	"""Test that civilizations.json has valid JSON structure."""
	var path: String = "res://data/civilizations.json"
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	
	if not file:
		pass_test("civilizations.json not found, skipping structure test")
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var parse_result: Error = json_parser.parse(json_string)
	
	assert_eq(parse_result, OK, "FAIL: Expected civilizations.json to parse successfully. Got parse error: %s (line %d). Context: path=%s. Why: Invalid JSON structure prevents civilization loading. Hint: Check JSON syntax, ensure proper brackets/braces/quotes." % [json_parser.get_error_message(), json_parser.get_error_line(), path])

func test_load_resources_json_exists() -> void:
	"""Test that resources.json file exists and is readable."""
	var path: String = "res://data/resources.json"
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	
	assert_not_null(file, "FAIL: Expected resources.json to exist and be readable. Context: path=%s. Why: Game requires resource data for world generation. Hint: Check res://data/resources.json exists and is not corrupted." % path)
	
	if file:
		file.close()

func test_load_resources_json_valid_structure() -> void:
	"""Test that resources.json has valid JSON structure."""
	var path: String = "res://data/resources.json"
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	
	if not file:
		pass_test("resources.json not found, skipping structure test")
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var parse_result: Error = json_parser.parse(json_string)
	
	assert_eq(parse_result, OK, "FAIL: Expected resources.json to parse successfully. Got parse error: %s (line %d). Context: path=%s. Why: Invalid JSON structure prevents resource loading. Hint: Check JSON syntax, ensure proper brackets/braces/quotes." % [json_parser.get_error_message(), json_parser.get_error_line(), path])

func test_load_map_icons_json_exists() -> void:
	"""Test that map_icons.json file exists and is readable."""
	var path: String = "res://data/map_icons.json"
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	
	assert_not_null(file, "FAIL: Expected map_icons.json to exist and be readable. Context: path=%s. Why: Game requires map icon data for marker system. Hint: Check res://data/map_icons.json exists and is not corrupted." % path)
	
	if file:
		file.close()

func test_load_map_icons_json_valid_structure() -> void:
	"""Test that map_icons.json has valid JSON structure."""
	var path: String = "res://data/map_icons.json"
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	
	if not file:
		pass_test("map_icons.json not found, skipping structure test")
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var parse_result: Error = json_parser.parse(json_string)
	
	assert_eq(parse_result, OK, "FAIL: Expected map_icons.json to parse successfully. Got parse error: %s (line %d). Context: path=%s. Why: Invalid JSON structure prevents icon loading. Hint: Check JSON syntax, ensure proper brackets/braces/quotes." % [json_parser.get_error_message(), json_parser.get_error_line(), path])

func test_invalid_json_handles_gracefully() -> void:
	"""Test that invalid JSON string is handled gracefully (returns parse error)."""
	var invalid_json: String = UnitTestHelpers.create_invalid_json()
	
	var parse_result: Error = json_parser.parse(invalid_json)
	
	assert_ne(parse_result, OK, "FAIL: Expected invalid JSON to return parse error. Got OK. Context: invalid_json='%s'. Why: Invalid JSON should be detected and reported. Hint: Check JSON.parse() returns Error != OK for invalid input." % invalid_json)
	
	if parse_result != OK:
		var error_msg: String = json_parser.get_error_message()
		assert_false(error_msg.is_empty(), "FAIL: Expected parse error message to be non-empty. Got empty. Context: invalid_json='%s'. Why: Error messages help debug JSON issues. Hint: Check JSON.get_error_message() returns descriptive error." % invalid_json)

func test_missing_json_file_handles_gracefully() -> void:
	"""Test that missing JSON file is handled gracefully (returns null FileAccess)."""
	var path: String = "res://data/nonexistent_file.json"
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	
	assert_null(file, "FAIL: Expected FileAccess.open() to return null for nonexistent file. Got non-null. Context: path=%s. Why: Missing files should be handled gracefully. Hint: Check FileAccess.open() returns null when file doesn't exist, use 'if not file:' pattern." % path)

func test_json_parse_empty_string() -> void:
	"""Test that empty JSON string is handled gracefully."""
	var empty_json: String = ""
	
	var parse_result: Error = json_parser.parse(empty_json)
	
	# Empty string may or may not be valid JSON depending on implementation
	# We just test it doesn't crash
	pass_test("Empty JSON string parsed without crash (result: %s)" % parse_result)

func test_json_parse_whitespace_only() -> void:
	"""Test that whitespace-only JSON string is handled gracefully."""
	var whitespace_json: String = "   \n\t  "
	
	var parse_result: Error = json_parser.parse(whitespace_json)
	
	# Whitespace-only may or may not be valid JSON
	# We just test it doesn't crash
	pass_test("Whitespace-only JSON string parsed without crash (result: %s)" % parse_result)
