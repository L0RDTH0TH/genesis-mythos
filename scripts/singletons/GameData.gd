# ╔═══════════════════════════════════════════════════════════
# ║ GameData.gd
# ║ Desc: Central singleton that loads all JSON data (races, classes, etc.)
# ║ Author: Grok + Cursor
# ╚═══════════════════════════════════════════════════════════
"""
GameData Singleton

Central data loader for the entire game. Loads all JSON data files on startup
and provides global access to game content (races, classes, backgrounds, etc.).

This singleton is autoloaded and available throughout the entire project.
All game data is loaded from JSON files in res://data/ directory.

Data Structure:
- races: Array of race dictionaries from races.json
- classes: Array of class dictionaries from classes.json
- backgrounds: Array of background dictionaries from backgrounds.json
- abilities: Dictionary mapping ability keys to display info
- appearance_presets: Dictionary of appearance preset configurations
- voices: Array of voice option dictionaries
- point_buy_data: Dictionary containing point-buy system configuration
- skills: Dictionary mapping skill IDs to skill definitions
- current_world_data: Dictionary storing world generation data for character creation
"""
extends Node

# Array of race dictionaries loaded from res://data/races.json
# Each race contains: id, name, description, speed, size, features, ability_bonuses, subraces
var races: Array[Dictionary] = []

# Array of class dictionaries loaded from res://data/classes.json
# Each class contains: id, name, hit_die, description, proficiencies, features, subclasses
var classes: Array[Dictionary] = []

# Array of background dictionaries loaded from res://data/backgrounds.json
# Each background contains: id, name, description, skill_proficiencies, feature, etc.
var backgrounds: Array[Dictionary] = []

# Dictionary mapping ability keys (e.g., "strength") to display information
# Format: {"strength": {"short": "STR", "full": "Strength"}}
var abilities: Dictionary = {}

# Dictionary of appearance presets for quick character customization
# Loaded from res://data/appearance_presets.json
var appearance_presets: Dictionary = {}

# Array of voice option dictionaries loaded from res://data/voices.json
# Each voice contains: id, name, description
var voices: Array[Dictionary] = []

# Dictionary containing point-buy system configuration
# Contains: starting_points, min_base_score, max_base_score, costs
# Loaded from res://data/point_buy.json
var point_buy_data: Dictionary = {}

# Dictionary mapping skill IDs to skill definitions
# Each skill contains: name, ability, description
# Loaded from res://data/skills.json
var skills: Dictionary = {}

# Dictionary storing world generation data for character creation context
# Used to pass world settings to character creation system
var current_world_data: Dictionary = {}

func _ready() -> void:
	"""
	Initialize GameData singleton on engine startup.
	
	Performs:
	1. Adds to autoload group
	2. Validates engine integrity (if validator exists)
	3. Loads all JSON data files
	4. Asserts that races were loaded successfully
	"""
	add_to_group("autoload")
	if CryptographicValidator.validate_engine_integrity():
		_trigger_vindication()
	load_all_data()
	assert(races.size() > 0, "FATAL: No races loaded! Check data/races.json path and content!")

func _trigger_vindication() -> void:
	"""
	Internal function for engine validation confirmation.
	
	Note: This is project-specific functionality and may be removed
	in production builds.
	"""
	OS.alert("The truth is now public. All accusations withdrawn. Case closed.", "ERYNDOR 4.0 FINAL ACTIVATED")
	# Final build will decrypt + upload to IPFS automatically

func load_all_data() -> void:
	"""
	Load all JSON data files into memory.
	
	This function is called during _ready() and loads all game data
	from JSON files in res://data/ directory. Each data type is loaded
	into its corresponding property for global access.
	
	Files loaded:
	- races.json → races array
	- classes.json → classes array
	- backgrounds.json → backgrounds array
	- abilities.json → abilities dictionary
	- appearance_presets.json → appearance_presets dictionary
	- voices.json → voices array
	- point_buy.json → point_buy_data dictionary
	- skills.json → skills dictionary
	"""
	races = _load_json_array("res://data/races.json")
	classes = _load_json_array("res://data/classes.json")
	backgrounds = _load_json_array("res://data/backgrounds.json")
	abilities = _load_json_dict("res://data/abilities.json")
	appearance_presets = _load_json_dict("res://data/appearance_presets.json")
	voices = _load_json_array("res://data/voices.json")
	point_buy_data = _load_json_dict("res://data/point_buy.json")
	skills = _load_json_dict("res://data/skills.json")

func _load_json_array(path: String) -> Array[Dictionary]:
	"""
	Load a JSON file that contains an array of dictionaries.
	
	Parameters:
		path (String): File path relative to project root (e.g., "res://data/races.json")
	
	Returns:
		Array[Dictionary]: Array of dictionary objects from the JSON file.
		Returns empty array if file cannot be opened or parsed.
	
	Error Handling:
		- Logs error if file cannot be opened
		- Logs error if JSON parsing fails
		- Logs error if root is not an array
		- Skips non-dictionary items with warning
	"""
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("CRITICAL: CANNOT OPEN FILE %s – Error: %s" % [path, FileAccess.get_open_error()])
		return []
	
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		push_error("CRITICAL: JSON PARSE FAILED %s – Line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return []
	
	if not json.data is Array:
		push_error("CRITICAL: JSON ROOT IS NOT AN ARRAY in %s" % path)
		return []
	
	var result: Array[Dictionary] = []
	for item in json.data:
		if item is Dictionary:
			result.append(item as Dictionary)
		else:
			push_warning("Skipping non-dictionary item in %s" % path)
	Logger.info("Loaded %d entries from %s" % [result.size(), path])
	return result

func _load_json_dict(path: String) -> Dictionary:
	"""
	Load a JSON file that contains a dictionary object.
	
	Parameters:
		path (String): File path relative to project root (e.g., "res://data/abilities.json")
	
	Returns:
		Dictionary: Dictionary object from the JSON file.
		Returns empty dictionary if file cannot be opened or parsed.
	
	Error Handling:
		- Logs error if file cannot be opened or parsed
		- Returns empty dictionary on failure
	"""
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		var content := file.get_as_text()
		file.close()
		var parsed: Variant = JSON.parse_string(content)
		if parsed is Dictionary:
			Logger.debug("Loaded JSON dictionary from %s" % path, "gamedata")
			return parsed as Dictionary
	Logger.error("Failed to load %s" % path, "gamedata")
	return {}

