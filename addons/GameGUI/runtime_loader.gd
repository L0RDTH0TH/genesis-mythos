# ╔═══════════════════════════════════════════════════════════════════════════════
# ║ runtime_loader.gd
# ║ Desc: Forces GameGUI classes to be loaded and registered at runtime
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════════════════════════

## Preloads all GameGUI classes to ensure they're available at runtime
## This is necessary because the plugin's add_custom_type() only works in the editor
## By preloading these scripts, we force Godot to parse them and register their class_name declarations

const GGButton = preload("res://addons/GameGUI/GGButton.gd")
const GGComponent = preload("res://addons/GameGUI/GGComponent.gd")
const GGFiller = preload("res://addons/GameGUI/GGFiller.gd")
const GGHBox = preload("res://addons/GameGUI/GGHBox.gd")
const GGInitialWindowSize = preload("res://addons/GameGUI/GGInitialWindowSize.gd")
const GGLabel = preload("res://addons/GameGUI/GGLabel.gd")
const GGLayoutConfig = preload("res://addons/GameGUI/GGLayoutConfig.gd")
const GGLimitedSizeComponent = preload("res://addons/GameGUI/GGLimitedSizeComponent.gd")
const GGMarginLayout = preload("res://addons/GameGUI/GGMarginLayout.gd")
const GGNinePatchRect = preload("res://addons/GameGUI/GGNinePatchRect.gd")
const GGParameterSetter = preload("res://addons/GameGUI/GGParameterSetter.gd")
const GGOverlay = preload("res://addons/GameGUI/GGOverlay.gd")
const GGRichTextLabel = preload("res://addons/GameGUI/GGRichTextLabel.gd")
const GGTextureRect = preload("res://addons/GameGUI/GGTextureRect.gd")
const GGVBox = preload("res://addons/GameGUI/GGVBox.gd")

