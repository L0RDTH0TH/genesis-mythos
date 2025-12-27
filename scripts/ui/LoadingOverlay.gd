# ╔═══════════════════════════════════════════════════════════
# ║ LoadingOverlay.gd
# ║ Desc: Full-screen loading overlay with progress feedback
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name LoadingOverlayUI
extends Control

## Status label showing current loading message
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel

## Progress bar showing loading progress (0.0 to 100.0)
@onready var progress_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBar


func _ready() -> void:
	"""Initialize the loading overlay."""
	# Full-screen overlay
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 1000  # Ensure overlay is on top of everything
	
	# Improve visibility: Set gold color for status label (readable against dark backgrounds)
	if status_label:
		status_label.modulate = Color(1.0, 0.843, 0.0, 1.0)  # Gold color
	
	# Initially hidden
	visible = false


func show_loading(text: String = "Loading...", progress: float = 0.0) -> void:
	"""Show loading overlay with text and progress."""
	visible = true
	status_label.text = text
	progress_bar.value = progress
	progress_bar.visible = true
	MythosLogger.debug("UI/LoadingOverlay", "Loading overlay shown", {"text": text, "progress": progress})


func update_progress(text: String, progress: float) -> void:
	"""Update loading progress."""
	status_label.text = text
	progress_bar.value = progress
	MythosLogger.debug("UI/LoadingOverlay", "Progress updated", {"text": text, "progress": progress})


func hide_loading() -> void:
	"""Hide loading overlay."""
	visible = false
	MythosLogger.debug("UI/LoadingOverlay", "Loading overlay hidden")
