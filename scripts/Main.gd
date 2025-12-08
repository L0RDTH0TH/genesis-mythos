# ╔═══════════════════════════════════════════════════════════
# ║ Main.gd
# ║ Desc: Entry point of the game
# ║ Author: Grok + Cursor
# ╚═══════════════════════════════════════════════════════════
extends Node2D

func _ready() -> void:
	GameData.load_all_data()

func start_character_creation() -> void:
	get_tree().change_scene_to_file("res://scenes/character_creation/CharacterCreationRoot.tscn")

