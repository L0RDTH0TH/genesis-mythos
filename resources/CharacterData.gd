# ╔═══════════════════════════════════════════════════════════
# ║ CharacterData.gd
# ║ Desc: Resource for storing complete character data
# ║ Author: Grok + Cursor
# ╚═══════════════════════════════════════════════════════════
"""
CharacterData Resource

Resource class for storing complete character data. This is the final
data structure that represents a fully created character and can be
saved to disk for later loading.

All properties are exported, allowing them to be serialized and saved
as .tres resource files.

Usage:
    var character = CharacterData.new()
    character.name = "Aragorn"
    character.race = "human"
    # ... set other properties
    ResourceSaver.save(character, "user://characters/aragorn.tres")
"""
extends Resource

# Character's display name (user-entered)
@export var name: String = ""

# Race ID (must match an ID in GameData.races)
@export var race: String = ""

# Subrace ID (must match an ID in the race's subraces array, or empty string)
@export var subrace: String = ""

# Class ID (must match an ID in GameData.classes)
@export var character_class: String = ""

# Background ID (must match an ID in GameData.backgrounds)
@export var background: String = ""

# Dictionary of ability scores
# Keys: "strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma"
# Values: Integer scores (base scores, racial bonuses are calculated separately)
@export var ability_scores: Dictionary = {}

# Dictionary of appearance customization data
# Structure depends on appearance system implementation
# May contain: head_preset, hair_style, skin_color, hair_color, etc.
@export var appearance: Dictionary = {}

# Voice ID (must match an ID in GameData.voices)
@export var voice: String = ""

