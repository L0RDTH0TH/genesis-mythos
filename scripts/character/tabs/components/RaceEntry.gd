# ╔═══════════════════════════════════════════════════════════
# ║ RaceEntry.gd
# ║ Desc: BG3-style race button with icon, name, and ability preview
# ║ Author: Grok + Cursor
# ╚═══════════════════════════════════════════════════════════
class_name RaceEntry
extends PanelContainer

@onready var panel: PanelContainer = self
@onready var icon: TextureRect = %Icon
@onready var race_name_label: Label = %RaceNameLabel
@onready var ability_preview_label: RichTextLabel = %AbilityPreviewLabel

var race_data: Dictionary
var subrace_data: Dictionary = {}
var is_selected: bool = false

signal race_selected(race_id: String, subrace_id: String)

const ABILITY_MAP := {
	"STR": "strength",
	"DEX": "dexterity",
	"CON": "constitution",
	"INT": "intelligence",
	"WIS": "wisdom",
	"CHA": "charisma"
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not gui_input.is_connected(_on_gui_input):
		gui_input.connect(_on_gui_input)
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	
	# Set initial style
	_update_style()
	
	# Update display if data is already set
	if not race_data.is_empty():
		_update_display()

func setup(race: Dictionary, subrace: Dictionary = {}) -> void:
	race_data = race
	subrace_data = subrace
	
	# Update display
	_update_display()

func _update_display() -> void:
	if not is_inside_tree():
		call_deferred("_update_display")
		return
	
	var display_name: String = subrace_data.get("name", race_data.get("name", "")) if !subrace_data.is_empty() else race_data.get("name", "")
	
	if race_name_label:
		race_name_label.text = display_name
	
	# Build ability preview text
	_build_ability_preview()
	
	# Set icon placeholder (ColorRect for now)
	_setup_icon()

func _build_ability_preview() -> void:
	if not ability_preview_label:
		return
	
	var bonuses: Dictionary = race_data.get("ability_bonuses", {}).duplicate()
	if subrace_data.has("ability_bonuses"):
		for key in subrace_data.ability_bonuses:
			bonuses[key] = bonuses.get(key, 0) + subrace_data.ability_bonuses[key]
	
	# Handle "all" bonus
	if bonuses.has("all"):
		var all_bonus: int = bonuses["all"]
		bonuses.erase("all")
		for abil_key in GameData.abilities.keys():
			bonuses[abil_key] = bonuses.get(abil_key, 0) + all_bonus
	
	var mods := ""
	for stat in ["STR", "DEX", "CON", "INT", "WIS", "CHA"]:
		var abil_key: String = ABILITY_MAP[stat]
		var val: int = bonuses.get(abil_key, 0)
		if val > 0:
			mods += "[color=lime]+%d %s [/color]" % [val, stat]
		elif val < 0:
			mods += "[color=red]%d %s [/color]" % [val, stat]
		else:
			mods += "%s " % stat
	
	ability_preview_label.text = "[center]%s[/center]" % mods

func _setup_icon() -> void:
	if not icon:
		return
	
	# Create a placeholder ColorRect as child of icon
	# Remove existing placeholder if any
	for child in icon.get_children():
		if child.name == "Placeholder":
			child.queue_free()
	
	# Create colored placeholder based on race name hash
	var color_seed: int = race_data.get("name", "Unknown").hash()
	var hue: float = abs(color_seed % 360) / 360.0
	var color := Color.from_hsv(hue, 0.6, 0.8)
	
	var placeholder := ColorRect.new()
	placeholder.name = "Placeholder"
	placeholder.color = color
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.add_child(placeholder)
	
	# Set placeholder to fill the icon
	placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_race()

func _on_mouse_entered() -> void:
	if not is_selected:
		_update_style("hover")

func _on_mouse_exited() -> void:
	_update_style()

func _select_race() -> void:
	is_selected = true
	_update_style("selected")
	
	var race_id: String = race_data.get("id", "")
	var subrace_id: String = subrace_data.get("id", "")
	race_selected.emit(race_id, subrace_id)

func set_selected(value: bool) -> void:
	is_selected = value
	_update_style()

func _update_style(state: String = "normal") -> void:
	if is_selected:
		state = "selected"
	
	var theme_resource := load("res://themes/bg3_theme.tres") as Theme
	if not theme_resource:
		return
	
	var style_name: String = "race_button_" + state
	var stylebox := theme_resource.get_stylebox(style_name, "PanelContainer")
	if stylebox:
		add_theme_stylebox_override("panel", stylebox)
