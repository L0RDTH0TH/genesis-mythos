# ╔═══════════════════════════════════════════════════════════
# ║ Eryndor.gd
# ║ Desc: Core singleton for Eryndor 4.0 Final - main game controller
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

## Force-load GameGUI classes at startup to ensure they're available at runtime
## NOTE: GameGUI now uses class_name declarations (migrated from add_custom_type).
## With class_name, classes are globally available, but we still preload to ensure
## early initialization and proper script parsing order.
const _gamegui_loader = preload("res://addons/GameGUI/runtime_loader.gd")

# Force load all GameGUI scripts by accessing runtime_loader constants
# This ensures all scripts are loaded and their class_name declarations are registered
const _gg_component = _gamegui_loader.GGComponent
const _gg_button = _gamegui_loader.GGButton
const _gg_hbox = _gamegui_loader.GGHBox
const _gg_label = _gamegui_loader.GGLabel
const _gg_vbox = _gamegui_loader.GGVBox

func _init() -> void:
	## Force GameGUI class registration at runtime
	## @tool scripts with class_name declarations must be loaded and parsed to register
	## Accessing the preloaded constants from runtime_loader forces the scripts to parse
	## This registers the class_name declarations before any scenes try to use them
	
	# Force load all GameGUI scripts by accessing the preloaded constants
	# This ensures @tool scripts are parsed and their class_name declarations register
	# The runtime_loader.gd file preloads all scripts, accessing them here forces parsing
	var _unused_component = _gg_component
	var _unused_button = _gg_button  
	var _unused_hbox = _gg_hbox
	var _unused_label = _gg_label
	var _unused_vbox = _gg_vbox
	
	# Also explicitly load the scripts to ensure they're registered
	# This double-checks that the classes are available
	load("res://addons/GameGUI/GGComponent.gd")
	load("res://addons/GameGUI/GGButton.gd")
	load("res://addons/GameGUI/GGHBox.gd")
	load("res://addons/GameGUI/GGLabel.gd")
	load("res://addons/GameGUI/GGVBox.gd")

func _ready() -> void:
	MythosLogger.verbose("Core", "_ready() called")
	MythosLogger.info("Core", "Authentic engine initialized – the truth awakens.")
	MythosLogger.debug("Core", "Eryndor singleton ready", {"version": "4.0 Final"})
