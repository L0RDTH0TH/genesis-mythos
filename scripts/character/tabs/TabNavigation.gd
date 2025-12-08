# ╔═══════════════════════════════════════════════════════════
# ║ TabNavigation.gd
# ║ Desc: Left sidebar tab controller for BG3 character creation
# ║ Author: Grok + Cursor
# ╚═══════════════════════════════════════════════════════════
"""
TabNavigation

Left sidebar navigation controller for character creation tabs.
Manages tab selection, button states, and sequential navigation flow.

Features:
- Sequential tab unlocking (can only advance one tab at a time)
- Visual state indication (selected vs normal buttons)
- Tab validation before switching
- Signal emission for tab changes

Tab Order:
1. Race
2. Class
3. Background
4. AbilityScore
5. Appearance
6. NameConfirm

Signals:
- tab_changed(tab_name: String): Emitted when user switches to a different tab
"""
extends Control

# Emitted when user switches to a different tab
# Parameters:
#   tab_name (String): Name of the tab being switched to
signal tab_changed(tab_name: String)

# ============================================================
# UI NODE REFERENCES
# ============================================================

# Button references for each tab (connected in _connect_buttons())
@onready var race_button: Button = $TabContainer/RaceButton
@onready var class_button: Button = $TabContainer/ClassButton
@onready var background_button: Button = $TabContainer/BackgroundButton
@onready var ability_button: Button = $TabContainer/AbilityButton
@onready var appearance_button: Button = $TabContainer/AppearanceButton
@onready var confirm_button: Button = $TabContainer/ConfirmButton

# ============================================================
# STATE VARIABLES
# ============================================================

# Currently selected tab name (must match one of TAB_ORDER values)
var current_tab: String = "Race"

# Ordered list of all tabs in character creation flow
# Used to determine tab progression and enable/disable logic
const TAB_ORDER := [
	"Race", "Class", "Background", 
	"AbilityScore", "Appearance", "NameConfirm"
]

var selected_stylebox: StyleBoxFlat
var normal_stylebox: StyleBoxFlat

func _ready() -> void:
	Logger.debug("TabNavigation: _ready() called", "character_creation")
	# Create styleboxes once
	selected_stylebox = StyleBoxFlat.new()
	selected_stylebox.bg_color = Color(0.25, 0.2, 0.15, 1)
	selected_stylebox.border_width_left = 4
	selected_stylebox.border_color = Color(0.95, 0.85, 0.6, 1)
	
	normal_stylebox = StyleBoxFlat.new()
	normal_stylebox.bg_color = Color(0.12, 0.1, 0.08, 1)
	normal_stylebox.border_width_left = 3
	normal_stylebox.border_color = Color(0.85, 0.7, 0.4, 0.3)
	
	_select_tab("Race")
	_connect_buttons()
	Logger.debug("TabNavigation: Initialization complete", "character_creation")

func _connect_buttons() -> void:
	race_button.pressed.connect(_on_tab_pressed.bind("Race"))
	class_button.pressed.connect(_on_tab_pressed.bind("Class"))
	background_button.pressed.connect(_on_tab_pressed.bind("Background"))
	ability_button.pressed.connect(_on_tab_pressed.bind("AbilityScore"))
	appearance_button.pressed.connect(_on_tab_pressed.bind("Appearance"))
	confirm_button.pressed.connect(_on_tab_pressed.bind("NameConfirm"))

func _on_tab_pressed(tab_name: String) -> void:
	Logger.log_user_action("tab_navigation", tab_name, "character_creation")
	if _can_select_tab(tab_name):
		Logger.log_state_transition(current_tab, tab_name, "character_creation")
		_select_tab(tab_name)
		tab_changed.emit(tab_name)
		Logger.debug("TabNavigation: Switched to tab: %s" % tab_name, "character_creation")
	else:
		Logger.debug("TabNavigation: Cannot switch to tab %s (current: %s)" % [tab_name, current_tab], "character_creation")

func _can_select_tab(tab_name: String) -> bool:
	var current_idx := TAB_ORDER.find(current_tab)
	var target_idx := TAB_ORDER.find(tab_name)
	return target_idx <= current_idx + 1

func _select_tab(tab_name: String) -> void:
	current_tab = tab_name
	_update_button_states()

func _update_button_states() -> void:
	var current_idx := TAB_ORDER.find(current_tab)
	
	race_button.disabled = false
	class_button.disabled = current_idx < 1
	background_button.disabled = current_idx < 2
	ability_button.disabled = current_idx < 3
	appearance_button.disabled = current_idx < 4
	confirm_button.disabled = current_idx < 5
	
	# Visual selected state
	var buttons := [race_button, class_button, background_button, ability_button, appearance_button, confirm_button]
	var tab_names := ["Race", "Class", "Background", "AbilityScore", "Appearance", "NameConfirm"]
	
	for i in range(buttons.size()):
		var btn: Button = buttons[i]
		var tab_name: String = tab_names[i]
		if tab_name == current_tab and not btn.disabled:
			btn.add_theme_stylebox_override("normal", selected_stylebox)
		else:
			btn.add_theme_stylebox_override("normal", normal_stylebox)

func enable_next_tab() -> void:
	"""
	Enable and advance to the next tab in sequence.
	
	This function is called when a tab emits its tab_completed signal,
	indicating that the user has completed the current tab and can proceed.
	
	Behavior:
	1. Finds the next tab in TAB_ORDER
	2. Enables that tab's button
	3. Automatically switches to the next tab
	4. Emits tab_changed signal
	
	Note: This is the primary way tabs advance in the character creation flow.
	Individual tabs call this via their tab_completed signal connection.
	"""
	Logger.debug("TabNavigation: enable_next_tab() called from tab_completed signal", "character_creation")
	Logger.debug("TabNavigation: Current tab is: %s" % current_tab, "character_creation")
	
	var next_idx := TAB_ORDER.find(current_tab) + 1
	if next_idx >= TAB_ORDER.size():
		Logger.debug("TabNavigation: Already at last tab, cannot advance", "character_creation")
		return
	
	var next_tab: String = TAB_ORDER[next_idx]
	Logger.debug("TabNavigation: Next tab will be: %s (index %d)" % [next_tab, next_idx], "character_creation")
	
	# Validate prerequisites before advancing
	if next_tab == "Class" and PlayerData.race_id.is_empty():
		Logger.warning("TabNavigation: Cannot advance to Class tab - no race selected", "character_creation")
		return
	
	# Verify tab_changed signal has connections
	if tab_changed.get_connections().is_empty():
		Logger.error("TabNavigation: tab_changed signal has no connections! Tab transition will fail.", "character_creation")
	else:
		Logger.debug("TabNavigation: tab_changed signal has %d connections" % tab_changed.get_connections().size(), "character_creation")
		for conn in tab_changed.get_connections():
			Logger.debug("TabNavigation: tab_changed connected to: %s" % str(conn), "character_creation")
	
	Logger.log_state_transition(current_tab, next_tab, "character_creation", {"auto_advance": true})
	_select_tab(next_tab)
	Logger.debug("TabNavigation: About to emit tab_changed signal for: %s" % next_tab, "character_creation")
	tab_changed.emit(next_tab)
	Logger.debug("TabNavigation: tab_changed signal emitted for: %s" % next_tab, "character_creation")
	Logger.info("TabNavigation: Auto-advanced to next tab: %s" % next_tab, "character_creation")

