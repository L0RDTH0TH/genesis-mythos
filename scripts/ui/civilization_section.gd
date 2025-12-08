# ╔═══════════════════════════════════════════════════════════
# ║ civilization_section.gd
# ║ Desc: Civilization section with population, cities, settlements, foliage, and POI controls
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
@tool
extends PanelContainer

signal param_changed(param: String, value: Variant)

@onready var population_density_slider: HSlider = $MarginContainer/VBoxContainer/content/PopulationDensityContainer/PopulationDensitySlider
@onready var population_density_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/PopulationDensityContainer/PopulationDensitySpinBox
@onready var city_count_slider: HSlider = $MarginContainer/VBoxContainer/content/CityCountContainer/CityCountSlider
@onready var city_count_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/CityCountContainer/CityCountSpinBox
@onready var village_density_slider: HSlider = $MarginContainer/VBoxContainer/content/VillageDensityContainer/VillageDensitySlider
@onready var village_density_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/VillageDensityContainer/VillageDensitySpinBox
@onready var civilization_type_option: OptionButton = $MarginContainer/VBoxContainer/content/CivilizationTypeContainer/CivilizationTypeOptionButton
@onready var enable_foliage_checkbox: CheckBox = $MarginContainer/VBoxContainer/content/FoliageContainer/EnableFoliageCheckBox
@onready var foliage_density_slider: HSlider = $MarginContainer/VBoxContainer/content/FoliageContainer/FoliageDensityContainer/FoliageDensitySlider
@onready var foliage_density_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/FoliageContainer/FoliageDensityContainer/FoliageDensitySpinBox
@onready var foliage_variation_slider: HSlider = $MarginContainer/VBoxContainer/content/FoliageContainer/FoliageVariationContainer/FoliageVariationSlider
@onready var enable_cities_checkbox: CheckBox = $MarginContainer/VBoxContainer/content/POIContainer/EnableCitiesCheckBox
@onready var enable_towns_checkbox: CheckBox = $MarginContainer/VBoxContainer/content/POIContainer/EnableTownsCheckBox
@onready var enable_ruins_checkbox: CheckBox = $MarginContainer/VBoxContainer/content/POIContainer/EnableRuinsCheckBox
@onready var enable_resources_checkbox: CheckBox = $MarginContainer/VBoxContainer/content/POIContainer/EnableResourcesCheckBox
@onready var poi_density_slider: HSlider = $MarginContainer/VBoxContainer/content/POIContainer/POIDensityContainer/POIDensitySlider
@onready var min_poi_distance_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/POIContainer/MinPOIDistanceContainer/MinPOIDistanceSpinBox

const CIVILIZATION_TYPES := ["Medieval", "Ancient", "Renaissance", "Steampunk", "Magical"]

func _ready() -> void:
	"""Initialize civilization section controls and connections."""
	# Populate civilization type option button
	civilization_type_option.clear()
	for civ_type in CIVILIZATION_TYPES:
		civilization_type_option.add_item(civ_type)
	civilization_type_option.selected = 0
	civilization_type_option.item_selected.connect(_on_civilization_type_changed)
	
	# Connect population density controls
	population_density_slider.value_changed.connect(_on_population_density_changed)
	population_density_spinbox.value_changed.connect(_on_population_density_spinbox_changed)
	
	# Connect city count controls
	city_count_slider.value_changed.connect(_on_city_count_changed)
	city_count_spinbox.value_changed.connect(_on_city_count_spinbox_changed)
	
	# Connect village density controls
	village_density_slider.value_changed.connect(_on_village_density_changed)
	village_density_spinbox.value_changed.connect(_on_village_density_spinbox_changed)
	
	# Connect foliage controls (Phase 3)
	enable_foliage_checkbox.toggled.connect(_on_foliage_enabled_toggled)
	foliage_density_slider.value_changed.connect(_on_foliage_density_changed)
	foliage_density_spinbox.value_changed.connect(_on_foliage_density_spinbox_changed)
	foliage_variation_slider.value_changed.connect(_on_foliage_variation_changed)
	
	# Connect POI controls (Phase 3)
	enable_cities_checkbox.toggled.connect(_on_cities_enabled_toggled)
	enable_towns_checkbox.toggled.connect(_on_towns_enabled_toggled)
	enable_ruins_checkbox.toggled.connect(_on_ruins_enabled_toggled)
	enable_resources_checkbox.toggled.connect(_on_resources_enabled_toggled)
	poi_density_slider.value_changed.connect(_on_poi_density_changed)
	min_poi_distance_spinbox.value_changed.connect(_on_min_poi_distance_changed)
	
	# Sync initial values
	_sync_population_density()
	_sync_city_count()
	_sync_village_density()
	_sync_foliage_density()

func _on_population_density_changed(value: float) -> void:
	"""Handle population density slider change."""
	population_density_spinbox.value = value
	emit_signal("param_changed", "population_density", value)

func _on_population_density_spinbox_changed(value: float) -> void:
	"""Handle population density spinbox change."""
	population_density_slider.value = value
	emit_signal("param_changed", "population_density", value)

func _on_city_count_changed(value: float) -> void:
	"""Handle city count slider change."""
	city_count_spinbox.value = value
	emit_signal("param_changed", "city_count", value)

func _on_city_count_spinbox_changed(value: float) -> void:
	"""Handle city count spinbox change."""
	city_count_slider.value = value
	emit_signal("param_changed", "city_count", value)

func _on_village_density_changed(value: float) -> void:
	"""Handle village density slider change."""
	village_density_spinbox.value = value
	emit_signal("param_changed", "village_density", value)

func _on_village_density_spinbox_changed(value: float) -> void:
	"""Handle village density spinbox change."""
	village_density_slider.value = value
	emit_signal("param_changed", "village_density", value)

func _on_civilization_type_changed(index: int) -> void:
	"""Handle civilization type selection change."""
	emit_signal("param_changed", "civilization_type", CIVILIZATION_TYPES[index])

func _on_foliage_enabled_toggled(pressed: bool) -> void:
	"""Handle foliage checkbox toggle."""
	emit_signal("param_changed", "enable_foliage", pressed)

func _on_foliage_density_changed(value: float) -> void:
	"""Handle foliage density slider change."""
	foliage_density_spinbox.value = value
	# Convert 0-100 to 0.0-1.0
	var normalized_value: float = value / 100.0
	emit_signal("param_changed", "foliage_density", normalized_value)

func _on_foliage_density_spinbox_changed(value: float) -> void:
	"""Handle foliage density spinbox change."""
	foliage_density_slider.value = value
	# Convert 0-100 to 0.0-1.0
	var normalized_value: float = value / 100.0
	emit_signal("param_changed", "foliage_density", normalized_value)

func _on_foliage_variation_changed(value: float) -> void:
	"""Handle foliage variation slider change."""
	# Convert 0-100 to 0.0-1.0
	var normalized_value: float = value / 100.0
	emit_signal("param_changed", "foliage_variation", normalized_value)

func _on_cities_enabled_toggled(pressed: bool) -> void:
	"""Handle cities checkbox toggle."""
	emit_signal("param_changed", "enable_cities", pressed)

func _on_towns_enabled_toggled(pressed: bool) -> void:
	"""Handle towns checkbox toggle."""
	emit_signal("param_changed", "enable_towns", pressed)

func _on_ruins_enabled_toggled(pressed: bool) -> void:
	"""Handle ruins checkbox toggle."""
	emit_signal("param_changed", "enable_ruins", pressed)

func _on_resources_enabled_toggled(pressed: bool) -> void:
	"""Handle resources checkbox toggle."""
	emit_signal("param_changed", "enable_resources", pressed)

func _on_poi_density_changed(value: float) -> void:
	"""Handle POI density slider change."""
	# Convert 0-100 to 0.0-1.0
	var normalized_value: float = value / 100.0
	emit_signal("param_changed", "poi_density", normalized_value)

func _on_min_poi_distance_changed(value: float) -> void:
	"""Handle min POI distance spinbox change."""
	emit_signal("param_changed", "min_poi_distance", int(value))

func _sync_population_density() -> void:
	"""Sync population density slider and spinbox."""
	population_density_spinbox.value = population_density_slider.value

func _sync_city_count() -> void:
	"""Sync city count slider and spinbox."""
	city_count_spinbox.value = city_count_slider.value

func _sync_village_density() -> void:
	"""Sync village density slider and spinbox."""
	village_density_spinbox.value = village_density_slider.value

func _sync_foliage_density() -> void:
	"""Sync foliage density slider and spinbox."""
	if foliage_density_slider and foliage_density_spinbox:
		foliage_density_spinbox.value = foliage_density_slider.value

func get_params() -> Dictionary:
	"""Get all civilization parameters as dictionary."""
	var params: Dictionary = {
		"population_density": population_density_slider.value,
		"city_count": city_count_slider.value,
		"village_density": village_density_slider.value,
		"civilization_type": CIVILIZATION_TYPES[civilization_type_option.selected],
		"enable_foliage": enable_foliage_checkbox.button_pressed if enable_foliage_checkbox else true,
		"foliage_density": (foliage_density_slider.value / 100.0) if foliage_density_slider else 0.6,
		"foliage_variation": (foliage_variation_slider.value / 100.0) if foliage_variation_slider else 0.4,
		"enable_cities": enable_cities_checkbox.button_pressed if enable_cities_checkbox else true,
		"enable_towns": enable_towns_checkbox.button_pressed if enable_towns_checkbox else true,
		"enable_ruins": enable_ruins_checkbox.button_pressed if enable_ruins_checkbox else true,
		"enable_resources": enable_resources_checkbox.button_pressed if enable_resources_checkbox else true,
		"poi_density": (poi_density_slider.value / 100.0) if poi_density_slider else 0.3,
		"min_poi_distance": int(min_poi_distance_spinbox.value) if min_poi_distance_spinbox else 80
	}
	return params

func set_params(params: Dictionary) -> void:
	"""Set civilization parameters from dictionary."""
	if params.has("population_density"):
		var value: float = params["population_density"]
		population_density_slider.value = value
		population_density_spinbox.value = value
	
	if params.has("city_count"):
		var value: float = params["city_count"]
		city_count_slider.value = value
		city_count_spinbox.value = value
	
	if params.has("village_density"):
		var value: float = params["village_density"]
		village_density_slider.value = value
		village_density_spinbox.value = value
	
	if params.has("civilization_type"):
		var civ_type: String = params["civilization_type"]
		var index: int = CIVILIZATION_TYPES.find(civ_type)
		if index >= 0:
			civilization_type_option.selected = index
	
	# Phase 3: Foliage parameters
	if params.has("enable_foliage"):
		if enable_foliage_checkbox:
			enable_foliage_checkbox.button_pressed = params["enable_foliage"]
	
	if params.has("foliage_density"):
		var value: float = params["foliage_density"]
		# Convert 0.0-1.0 to 0-100 for UI
		var ui_value: float = value * 100.0
		if foliage_density_slider:
			foliage_density_slider.value = ui_value
		if foliage_density_spinbox:
			foliage_density_spinbox.value = ui_value
	
	if params.has("foliage_variation"):
		var value: float = params["foliage_variation"]
		# Convert 0.0-1.0 to 0-100 for UI
		var ui_value: float = value * 100.0
		if foliage_variation_slider:
			foliage_variation_slider.value = ui_value
	
	# Phase 3: POI parameters
	if params.has("enable_cities"):
		if enable_cities_checkbox:
			enable_cities_checkbox.button_pressed = params["enable_cities"]
	
	if params.has("enable_towns"):
		if enable_towns_checkbox:
			enable_towns_checkbox.button_pressed = params["enable_towns"]
	
	if params.has("enable_ruins"):
		if enable_ruins_checkbox:
			enable_ruins_checkbox.button_pressed = params["enable_ruins"]
	
	if params.has("enable_resources"):
		if enable_resources_checkbox:
			enable_resources_checkbox.button_pressed = params["enable_resources"]
	
	if params.has("poi_density"):
		var value: float = params["poi_density"]
		# Convert 0.0-1.0 to 0-100 for UI
		var ui_value: float = value * 100.0
		if poi_density_slider:
			poi_density_slider.value = ui_value
	
	if params.has("min_poi_distance"):
		var value: int = params["min_poi_distance"]
		if min_poi_distance_spinbox:
			min_poi_distance_spinbox.value = float(value)
