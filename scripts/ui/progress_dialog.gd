# ╔═══════════════════════════════════════════════════════════
# ║ ProgressDialog.gd
# ║ Desc: Progress dialog for world generation and other long operations
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Window

## UI references
@onready var status_label: Label = $StatusLabel
@onready var progress_bar: ProgressBar = $ProgressBar


func _ready() -> void:
	"""Initialize progress dialog."""
	MythosLogger.verbose("UI/ProgressDialog", "_ready() called")
	_apply_ui_constants()
	MythosLogger.info("UI/ProgressDialog", "Progress dialog initialized")


func _apply_ui_constants() -> void:
	"""Apply UIConstants to make dialog responsive."""
	# Set dialog size based on UIConstants
	var dialog_width: int = UIConstants.DIALOG_WIDTH_MEDIUM
	var dialog_height: int = UIConstants.DIALOG_HEIGHT_STANDARD / 2  # Progress dialogs are typically shorter
	size = Vector2i(dialog_width, dialog_height)
	
	# Apply padding/margins using UIConstants
	if status_label != null:
		status_label.add_theme_constant_override("line_spacing", UIConstants.SPACING_SMALL)
	
	# Ensure dialog is centered when shown
	popup_centered()


func set_status(text: String) -> void:
	"""Update status label text."""
	if status_label != null:
		status_label.text = text
	MythosLogger.debug("UI/ProgressDialog", "Status updated: %s" % text)


func set_progress(value: float) -> void:
	"""Update progress bar value (0.0 to 1.0)."""
	if progress_bar != null:
		progress_bar.value = clamp(value, 0.0, 1.0)
	MythosLogger.debug("UI/ProgressDialog", "Progress updated: %.2f" % value)


func _notification(what: int) -> void:
	"""Handle window resize events for responsive UI."""
	if what == NOTIFICATION_WM_SIZE_CHANGED or what == NOTIFICATION_RESIZED:
		# Ensure dialog stays centered
		if visible:
			popup_centered()
