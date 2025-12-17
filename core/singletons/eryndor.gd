# ╔═══════════════════════════════════════════════════════════
# ║ Eryndor.gd
# ║ Desc: Core singleton for Eryndor 4.0 Final - main game controller
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

## Force-load GameGUI classes at startup to ensure they're available at runtime
## The plugin's add_custom_type() only works in editor, so we must force load at runtime
## @tool scripts are not loaded at runtime by default, so we explicitly load them here
const _gamegui_loader = preload("res://addons/GameGUI/runtime_loader.gd")

# Force load scripts by preloading them - this should parse class_name declarations
# However, @tool scripts may still not register, so we also try in _init()
const _gg_component_script = preload("res://addons/GameGUI/GGComponent.gd")
const _gg_button_script = preload("res://addons/GameGUI/GGButton.gd")
const _gg_vbox_script = preload("res://addons/GameGUI/GGVBox.gd")

func _init() -> void:
	## Force GameGUI class registration at runtime
	## @tool scripts with class_name declarations need special handling
	## We load the scripts and attempt to register them via ClassDB
	
	# Load scripts to ensure they're parsed
	# The class_name declarations should register automatically when parsed
	# but @tool scripts may need explicit handling
	
	# Try using ClassDB to check and force registration
	# First ensure scripts are loaded
	var component_script = _gg_component_script
	var button_script = _gg_button_script
	var vbox_script = _gg_vbox_script
	
	# Force script parsing by accessing resource paths
	# This should trigger class_name registration
	ResourceLoader.exists("res://addons/GameGUI/GGComponent.gd")
	ResourceLoader.exists("res://addons/GameGUI/GGButton.gd")
	ResourceLoader.exists("res://addons/GameGUI/GGVBox.gd")
	
	# Try to instantiate via ClassDB if class exists
	# This forces the class to be fully registered
	if ClassDB.class_exists("GGComponent"):
		var _dummy = ClassDB.instantiate("GGComponent")
		if _dummy:
			_dummy.queue_free()
	if ClassDB.class_exists("GGButton"):
		var _dummy = ClassDB.instantiate("GGButton")
		if _dummy:
			_dummy.queue_free()
	if ClassDB.class_exists("GGVBox"):
		var _dummy = ClassDB.instantiate("GGVBox")
		if _dummy:
			_dummy.queue_free()

func _ready() -> void:
	MythosLogger.verbose("Core", "_ready() called")
	MythosLogger.info("Core", "Authentic engine initialized – the truth awakens.")
	MythosLogger.debug("Core", "Eryndor singleton ready", {"version": "4.0 Final"})
