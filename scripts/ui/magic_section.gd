# ╔═══════════════════════════════════════════════════════════
# ║ magic_section.gd
# ║ Desc: Magic section with magic level, ley lines, mana wells, and wild magic controls
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
@tool
extends PanelContainer

signal param_changed(param: String, value: Variant)

@onready var magic_level_slider: HSlider = $MarginContainer/VBoxContainer/content/MagicLevelContainer/MagicLevelSlider
@onready var magic_level_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/MagicLevelContainer/MagicLevelSpinBox
@onready var ley_line_density_slider: HSlider = $MarginContainer/VBoxContainer/content/LeyLineDensityContainer/LeyLineDensitySlider
@onready var ley_line_density_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/LeyLineDensityContainer/LeyLineDensitySpinBox
@onready var mana_well_count_slider: HSlider = $MarginContainer/VBoxContainer/content/ManaWellCountContainer/ManaWellCountSlider
@onready var mana_well_count_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/ManaWellCountContainer/ManaWellCountSpinBox
@onready var wild_magic_zones_slider: HSlider = $MarginContainer/VBoxContainer/content/WildMagicZonesContainer/WildMagicZonesSlider
@onready var wild_magic_zones_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/WildMagicZonesContainer/WildMagicZonesSpinBox

func _ready() -> void:
	"""Initialize magic section controls and connections."""
	# Connect magic level controls
	magic_level_slider.value_changed.connect(_on_magic_level_changed)
	magic_level_spinbox.value_changed.connect(_on_magic_level_spinbox_changed)
	
	# Connect ley line density controls
	ley_line_density_slider.value_changed.connect(_on_ley_line_density_changed)
	ley_line_density_spinbox.value_changed.connect(_on_ley_line_density_spinbox_changed)
	
	# Connect mana well count controls
	mana_well_count_slider.value_changed.connect(_on_mana_well_count_changed)
	mana_well_count_spinbox.value_changed.connect(_on_mana_well_count_spinbox_changed)
	
	# Connect wild magic zones controls
	wild_magic_zones_slider.value_changed.connect(_on_wild_magic_zones_changed)
	wild_magic_zones_spinbox.value_changed.connect(_on_wild_magic_zones_spinbox_changed)
	
	# Sync initial values
	_sync_magic_level()
	_sync_ley_line_density()
	_sync_mana_well_count()
	_sync_wild_magic_zones()

func _on_magic_level_changed(value: float) -> void:
	"""Handle magic level slider change."""
	magic_level_spinbox.value = value
	emit_signal("param_changed", "magic_level", value)

func _on_magic_level_spinbox_changed(value: float) -> void:
	"""Handle magic level spinbox change."""
	magic_level_slider.value = value
	emit_signal("param_changed", "magic_level", value)

func _on_ley_line_density_changed(value: float) -> void:
	"""Handle ley line density slider change."""
	ley_line_density_spinbox.value = value
	emit_signal("param_changed", "ley_line_density", value)

func _on_ley_line_density_spinbox_changed(value: float) -> void:
	"""Handle ley line density spinbox change."""
	ley_line_density_slider.value = value
	emit_signal("param_changed", "ley_line_density", value)

func _on_mana_well_count_changed(value: float) -> void:
	"""Handle mana well count slider change."""
	mana_well_count_spinbox.value = value
	emit_signal("param_changed", "mana_well_count", value)

func _on_mana_well_count_spinbox_changed(value: float) -> void:
	"""Handle mana well count spinbox change."""
	mana_well_count_slider.value = value
	emit_signal("param_changed", "mana_well_count", value)

func _on_wild_magic_zones_changed(value: float) -> void:
	"""Handle wild magic zones slider change."""
	wild_magic_zones_spinbox.value = value
	emit_signal("param_changed", "wild_magic_zones", value)

func _on_wild_magic_zones_spinbox_changed(value: float) -> void:
	"""Handle wild magic zones spinbox change."""
	wild_magic_zones_slider.value = value
	emit_signal("param_changed", "wild_magic_zones", value)

func _sync_magic_level() -> void:
	"""Sync magic level slider and spinbox."""
	magic_level_spinbox.value = magic_level_slider.value

func _sync_ley_line_density() -> void:
	"""Sync ley line density slider and spinbox."""
	ley_line_density_spinbox.value = ley_line_density_slider.value

func _sync_mana_well_count() -> void:
	"""Sync mana well count slider and spinbox."""
	mana_well_count_spinbox.value = mana_well_count_slider.value

func _sync_wild_magic_zones() -> void:
	"""Sync wild magic zones slider and spinbox."""
	wild_magic_zones_spinbox.value = wild_magic_zones_slider.value

func get_params() -> Dictionary:
	"""Get all magic parameters as dictionary."""
	return {
		"magic_level": magic_level_slider.value,
		"ley_line_density": ley_line_density_slider.value,
		"mana_well_count": mana_well_count_slider.value,
		"wild_magic_zones": wild_magic_zones_slider.value
	}

func set_params(params: Dictionary) -> void:
	"""Set magic parameters from dictionary."""
	if params.has("magic_level"):
		var value: float = params["magic_level"]
		magic_level_slider.value = value
		magic_level_spinbox.value = value
	
	if params.has("ley_line_density"):
		var value: float = params["ley_line_density"]
		ley_line_density_slider.value = value
		ley_line_density_spinbox.value = value
	
	if params.has("mana_well_count"):
		var value: float = params["mana_well_count"]
		mana_well_count_slider.value = value
		mana_well_count_spinbox.value = value
	
	if params.has("wild_magic_zones"):
		var value: float = params["wild_magic_zones"]
		wild_magic_zones_slider.value = value
		wild_magic_zones_spinbox.value = value
