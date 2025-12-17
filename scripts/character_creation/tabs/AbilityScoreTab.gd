# ╔═══════════════════════════════════════════════════════════
# ║ AbilityScoreTab.gd
# ║ Desc: Ability score allocation tab for character creation
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends VBoxContainer

## Signal emitted when ability scores change
signal ability_scores_changed(scores: Dictionary)

## Ability scores (base values, before racial bonuses)
var ability_scores: Dictionary = {
	"strength": 8,
	"dexterity": 8,
	"constitution": 8,
	"intelligence": 8,
	"wisdom": 8,
	"charisma": 8
}

## Point buy points remaining (standard D&D point buy: 27 points)
var points_remaining: int = 27

## UI references
@onready var ability_scores_container: VBoxContainer = %AbilityScoresContainer
@onready var points_remaining_label: Label = %PointsRemainingLabel

## Ability score rows
var ability_rows: Dictionary = {}

## Abilities data
var abilities_data: Array = []


func _ready() -> void:
	"""Initialize ability score allocation tab."""
	MythosLogger.verbose("UI/CharacterCreation/AbilityScoreTab", "_ready() called")
	_load_abilities_data()
	_apply_ui_constants()
	_create_ability_rows()
	_update_points_display()
	MythosLogger.info("UI/CharacterCreation/AbilityScoreTab", "Ability score tab initialized")


func _apply_ui_constants() -> void:
	"""Apply UIConstants to UI elements."""
	if ability_scores_container != null:
		ability_scores_container.add_theme_constant_override("separation", UIConstants.SPACING_SMALL)
	
	# Apply spacing to container
	add_theme_constant_override("separation", UIConstants.SPACING_MEDIUM)


func _load_abilities_data() -> void:
	"""Load abilities data from JSON file."""
	var file_path: String = "res://data/abilities.json"
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		MythosLogger.error("UI/CharacterCreation/AbilityScoreTab", "Failed to load abilities.json")
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		MythosLogger.error("UI/CharacterCreation/AbilityScoreTab", "Failed to parse abilities.json: %s" % json.get_error_message())
		return
	
	var data: Dictionary = json.data
	abilities_data = data.get("abilities", [])
	MythosLogger.debug("UI/CharacterCreation/AbilityScoreTab", "Loaded %d abilities" % abilities_data.size())


func _create_ability_rows() -> void:
	"""Create ability score rows for each ability."""
	if ability_scores_container == null:
		return
	
	# Load the AbilityScoreRow scene
	var row_scene: PackedScene = load("res://ui/components/AbilityScoreRow.tscn")
	if row_scene == null:
		MythosLogger.error("UI/CharacterCreation/AbilityScoreTab", "Failed to load AbilityScoreRow.tscn")
		return
	
	for ability_data: Dictionary in abilities_data:
		var ability_id: String = ability_data.get("id", "")
		var ability_name: String = ability_data.get("full_name", ability_data.get("name", "Unknown"))
		
		# Create row instance
		var row: Control = row_scene.instantiate()
		if row == null:
			continue
		
		# Set ability key
		if row.has_method("set_ability_key"):
			row.set_ability_key(ability_id)
		elif "ability_key" in row:
			row.ability_key = ability_id
		
		# Set initial value
		var base_value: int = ability_scores.get(ability_id, 8)
		if row.has_method("setup"):
			row.setup(base_value, 0)  # No racial bonus yet
		
		# Connect signals if available
		if row.has_signal("value_changed"):
			row.value_changed.connect(func(ability: String, new_base: int): _on_ability_changed(ability, new_base))
		
		ability_scores_container.add_child(row)
		ability_rows[ability_id] = row


func _on_ability_changed(ability: String, new_base: int) -> void:
	"""Handle ability score change."""
	# TODO: Implement point buy cost calculation
	# For now, just update the value
	ability_scores[ability] = new_base
	_update_points_display()
	ability_scores_changed.emit(ability_scores)
	MythosLogger.debug("UI/CharacterCreation/AbilityScoreTab", "Ability %s changed to %d" % [ability, new_base])


func _update_points_display() -> void:
	"""Update the points remaining display."""
	if points_remaining_label != null:
		points_remaining_label.text = "Points Remaining: %d" % points_remaining


func get_ability_scores() -> Dictionary:
	"""Get current ability scores."""
	return ability_scores.duplicate()


func set_racial_bonuses(bonuses: Dictionary) -> void:
	"""Apply racial bonuses to ability scores."""
	for ability_id: String in bonuses.keys():
		if ability_rows.has(ability_id):
			var row: Control = ability_rows[ability_id]
			var bonus: int = bonuses[ability_id]
			if row.has_method("set_racial_bonus"):
				row.set_racial_bonus(bonus)
			MythosLogger.debug("UI/CharacterCreation/AbilityScoreTab", "Applied racial bonus %+d to %s" % [bonus, ability_id])
