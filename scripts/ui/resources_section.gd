# ╔═══════════════════════════════════════════════════════════
# ║ resources_section.gd
# ║ Desc: Resources section with mineral, ore, gemstone, and wood controls
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
@tool
extends PanelContainer

signal param_changed(param: String, value: Variant)

@onready var mineral_richness_slider: HSlider = $MarginContainer/VBoxContainer/content/MineralRichnessContainer/MineralRichnessSlider
@onready var mineral_richness_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/MineralRichnessContainer/MineralRichnessSpinBox
@onready var ore_deposits_slider: HSlider = $MarginContainer/VBoxContainer/content/OreDepositsContainer/OreDepositsSlider
@onready var ore_deposits_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/OreDepositsContainer/OreDepositsSpinBox
@onready var gemstone_rarity_slider: HSlider = $MarginContainer/VBoxContainer/content/GemstoneRarityContainer/GemstoneRaritySlider
@onready var gemstone_rarity_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/GemstoneRarityContainer/GemstoneRaritySpinBox
@onready var wood_availability_slider: HSlider = $MarginContainer/VBoxContainer/content/WoodAvailabilityContainer/WoodAvailabilitySlider
@onready var wood_availability_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/WoodAvailabilityContainer/WoodAvailabilitySpinBox

func _ready() -> void:
	"""Initialize resources section controls and connections."""
	# Connect mineral richness controls
	mineral_richness_slider.value_changed.connect(_on_mineral_richness_changed)
	mineral_richness_spinbox.value_changed.connect(_on_mineral_richness_spinbox_changed)
	
	# Connect ore deposits controls
	ore_deposits_slider.value_changed.connect(_on_ore_deposits_changed)
	ore_deposits_spinbox.value_changed.connect(_on_ore_deposits_spinbox_changed)
	
	# Connect gemstone rarity controls
	gemstone_rarity_slider.value_changed.connect(_on_gemstone_rarity_changed)
	gemstone_rarity_spinbox.value_changed.connect(_on_gemstone_rarity_spinbox_changed)
	
	# Connect wood availability controls
	wood_availability_slider.value_changed.connect(_on_wood_availability_changed)
	wood_availability_spinbox.value_changed.connect(_on_wood_availability_spinbox_changed)
	
	# Sync initial values
	_sync_mineral_richness()
	_sync_ore_deposits()
	_sync_gemstone_rarity()
	_sync_wood_availability()

func _on_mineral_richness_changed(value: float) -> void:
	"""Handle mineral richness slider change."""
	mineral_richness_spinbox.value = value
	emit_signal("param_changed", "mineral_richness", value)

func _on_mineral_richness_spinbox_changed(value: float) -> void:
	"""Handle mineral richness spinbox change."""
	mineral_richness_slider.value = value
	emit_signal("param_changed", "mineral_richness", value)

func _on_ore_deposits_changed(value: float) -> void:
	"""Handle ore deposits slider change."""
	ore_deposits_spinbox.value = value
	emit_signal("param_changed", "ore_deposits", value)

func _on_ore_deposits_spinbox_changed(value: float) -> void:
	"""Handle ore deposits spinbox change."""
	ore_deposits_slider.value = value
	emit_signal("param_changed", "ore_deposits", value)

func _on_gemstone_rarity_changed(value: float) -> void:
	"""Handle gemstone rarity slider change."""
	gemstone_rarity_spinbox.value = value
	emit_signal("param_changed", "gemstone_rarity", value)

func _on_gemstone_rarity_spinbox_changed(value: float) -> void:
	"""Handle gemstone rarity spinbox change."""
	gemstone_rarity_slider.value = value
	emit_signal("param_changed", "gemstone_rarity", value)

func _on_wood_availability_changed(value: float) -> void:
	"""Handle wood availability slider change."""
	wood_availability_spinbox.value = value
	emit_signal("param_changed", "wood_availability", value)

func _on_wood_availability_spinbox_changed(value: float) -> void:
	"""Handle wood availability spinbox change."""
	wood_availability_slider.value = value
	emit_signal("param_changed", "wood_availability", value)

func _sync_mineral_richness() -> void:
	"""Sync mineral richness slider and spinbox."""
	mineral_richness_spinbox.value = mineral_richness_slider.value

func _sync_ore_deposits() -> void:
	"""Sync ore deposits slider and spinbox."""
	ore_deposits_spinbox.value = ore_deposits_slider.value

func _sync_gemstone_rarity() -> void:
	"""Sync gemstone rarity slider and spinbox."""
	gemstone_rarity_spinbox.value = gemstone_rarity_slider.value

func _sync_wood_availability() -> void:
	"""Sync wood availability slider and spinbox."""
	wood_availability_spinbox.value = wood_availability_slider.value

func get_params() -> Dictionary:
	"""Get all resources parameters as dictionary."""
	return {
		"mineral_richness": mineral_richness_slider.value,
		"ore_deposits": ore_deposits_slider.value,
		"gemstone_rarity": gemstone_rarity_slider.value,
		"wood_availability": wood_availability_slider.value
	}

func set_params(params: Dictionary) -> void:
	"""Set resources parameters from dictionary."""
	if params.has("mineral_richness"):
		var value: float = params["mineral_richness"]
		mineral_richness_slider.value = value
		mineral_richness_spinbox.value = value
	
	if params.has("ore_deposits"):
		var value: float = params["ore_deposits"]
		ore_deposits_slider.value = value
		ore_deposits_spinbox.value = value
	
	if params.has("gemstone_rarity"):
		var value: float = params["gemstone_rarity"]
		gemstone_rarity_slider.value = value
		gemstone_rarity_spinbox.value = value
	
	if params.has("wood_availability"):
		var value: float = params["wood_availability"]
		wood_availability_slider.value = value
		wood_availability_spinbox.value = value
