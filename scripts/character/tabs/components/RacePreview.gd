# ╔═══════════════════════════════════════════════════════════
# ║ RacePreview.gd
# ║ Desc: Final pixel-perfect BG3 race preview panel with ghost fixes
# ║ Author: Grok + Cursor
# ╚═══════════════════════════════════════════════════════════
extends PanelContainer

@onready var race_name_label: Label = %RaceNameLabel
@onready var speed_label: Label = %SpeedLabel
@onready var size_label: Label = %SizeLabel
@onready var description_label: RichTextLabel = %DescriptionLabel
@onready var ability_scores_label: RichTextLabel = %AbilityScoresLabel
@onready var features_list: ItemList = %RaceFeaturesList

const ABILITIES := ["STR", "DEX", "CON", "INT", "WIS", "CHA"]
const ABILITY_MAP := {
	"STR": "strength",
	"DEX": "dexterity",
	"CON": "constitution",
	"INT": "intelligence",
	"WIS": "wisdom",
	"CHA": "charisma"
}
const BONUS_GREEN := Color("#00FF88")

var races_data: Array[Dictionary] = []

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	load_races()
	show_default_state()

func load_races() -> void:
	# Use GameData singleton
	races_data = GameData.races

func update_preview(race_key: String, subrace_key: String = "") -> void:
	# Defensive check: ensure nodes are ready
	if not is_inside_tree():
		call_deferred("update_preview", race_key, subrace_key)
		return
	
	# Wait for nodes to be ready if they're not yet
	if not race_name_label or not ability_scores_label or not features_list:
		await get_tree().process_frame  # Wait one frame for @onready to complete
		if not race_name_label or not ability_scores_label or not features_list:
			Logger.error("RacePreview: Critical nodes not available!", "character_creation")
			return
	
	var race_data: Dictionary = {}
	
	# Find race by ID
	for race in races_data:
		if race.get("id", "") == race_key:
			race_data = race
			break
	
	if race_data.is_empty():
		show_default_state()
		return
	
	# Handle subrace
	var display_name: String = race_data.get("name", "")
	var description: String = race_data.get("description", "")
	var features: Array = []
	var bonuses: Dictionary = race_data.get("ability_bonuses", {}).duplicate()
	
	# Initialize features from race data
	var race_features = race_data.get("features", [])
	if race_features is Array:
		for feat in race_features:
			if feat is String:
				features.append(feat)
	
	if subrace_key != "":
		var subraces: Array = race_data.get("subraces", [])
		for subrace in subraces:
			if subrace.get("id", "") == subrace_key:
				display_name = subrace.get("name", display_name)
				if subrace.has("description") and subrace.get("description", "") != "":
					description = subrace.get("description", description)
				if subrace.has("features"):
					var sub_features = subrace.get("features", [])
					if sub_features is Array:
						for feat in sub_features:
							if feat is String:
								features.append(feat)
				if subrace.has("ability_bonuses"):
					var sub_bonuses: Dictionary = subrace.get("ability_bonuses", {})
					for key in sub_bonuses.keys():
						bonuses[key] = bonuses.get(key, 0) + sub_bonuses[key]
				break
	
	# Clear and update
	race_name_label.text = display_name.to_upper()
	
	# Update description
	if description_label:
		description_label.text = description
	
	# Update speed and size
	var speed_value: String = race_data.get("speed", "")
	var size_value: String = race_data.get("size", "")
	if speed_label:
		speed_label.text = "Speed: " + speed_value if speed_value != "" else ""
	if size_label:
		size_label.text = "Size: " + size_value if size_value != "" else ""
	
	# Build ability scores string with BBCode
	build_ability_scores_text(bonuses)
	
	# Update features
	features_list.clear()
	var trait_str: String
	for idx in range(features.size()):
		trait_str = str(features[idx])
		if trait_str.length() > 0:
			features_list.add_item("•  " + trait_str)
	
	features_list.visible = true

func build_ability_scores_text(bonuses: Dictionary) -> void:
	# Handle "all" bonus
	if bonuses.has("all"):
		var all_bonus: int = bonuses["all"]
		bonuses.erase("all")
		for abil_key in GameData.abilities.keys():
			bonuses[abil_key] = bonuses.get(abil_key, 0) + all_bonus
	
	# Build BBCode text for all abilities
	var score_text := ""
	for abil_short in ABILITIES:
		var abil_key: String = ABILITY_MAP[abil_short]
		var mod: int = bonuses.get(abil_key, 0)
		
		score_text += abil_short
		
		if mod > 0:
			score_text += " [color=green]+" + str(mod) + "[/color] "
		elif mod < 0:
			score_text += " [color=red]" + str(mod) + "[/color] "
		else:
			score_text += " "
	
	if ability_scores_label:
		ability_scores_label.text = "[center]" + score_text + "[/center]"

func show_default_state() -> void:
	# Null checks before accessing nodes
	if not race_name_label or not ability_scores_label or not features_list:
		return
	
	race_name_label.text = ""
	if speed_label:
		speed_label.text = ""
	if size_label:
		size_label.text = ""
	if description_label:
		description_label.text = ""
	if ability_scores_label:
		ability_scores_label.text = ""
	features_list.clear()
	features_list.add_item("Features will appear here when a race is selected")
	features_list.visible = true

func clear_preview() -> void:
	"""Compatibility method for RaceTab"""
	show_default_state()

