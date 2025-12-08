# ╔═══════════════════════════════════════════════════════════
# ║ HeadPresetEntry.gd
# ║ Desc: Clickable head preset with thumbnail
# ║ Author: Grok + Cursor
# ╚═══════════════════════════════════════════════════════════
extends Button

signal preset_selected(id: String)

@onready var preview: TextureRect = $Preview

var preset_id: String

func setup(id: String, texture: Texture2D) -> void:
	preset_id = id
	if texture:
		preview.texture = texture
	pressed.connect(func(): preset_selected.emit(preset_id))

