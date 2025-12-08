# ╔═══════════════════════════════════════════════════════════
# ║ progress_dialog.gd
# ║ Desc: Progress dialog for world generation (button-less classic progress bar)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
extends Window

@onready var status_label: Label = $StatusLabel
@onready var progress_bar: ProgressBar = $ProgressBar

func _ready() -> void:
	"""Initialize progress dialog."""
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.value = 0.0

func _notification(what: int) -> void:
	"""Handle window notifications."""
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		hide()  # Prevent closing via X button

func set_progress(value: float) -> void:
	"""Update progress bar value (0.0 to 1.0)."""
	if progress_bar:
		progress_bar.value = clamp(value, 0.0, 1.0)
		progress_bar.queue_redraw()  # Force immediate visual update

func set_status(text: String) -> void:
	"""Update status label text."""
	if status_label:
		status_label.text = text
