# ╔═══════════════════════════════════════════════════════════
# ║ terrain_section.gd
# ║ Desc: Terrain section with elevation, chaos, noise type, and rivers controls
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
@tool
extends PanelContainer

signal param_changed(param: String, value: Variant)

@onready var elevation_scale_slider: HSlider = $MarginContainer/VBoxContainer/content/ElevationScaleContainer/ElevationScaleSlider
@onready var elevation_scale_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/ElevationScaleContainer/ElevationScaleSpinBox
@onready var terrain_chaos_slider: HSlider = $MarginContainer/VBoxContainer/content/TerrainChaosContainer/TerrainChaosSlider
@onready var terrain_chaos_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/TerrainChaosContainer/TerrainChaosSpinBox
@onready var domain_warp_strength_slider: HSlider = $MarginContainer/VBoxContainer/content/DomainWarpStrengthContainer/DomainWarpStrengthSlider
@onready var domain_warp_strength_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/DomainWarpStrengthContainer/DomainWarpStrengthSpinBox
@onready var domain_warp_freq_slider: HSlider = $MarginContainer/VBoxContainer/content/DomainWarpFreqContainer/DomainWarpFreqSlider
@onready var enable_erosion_checkbox: CheckBox = $MarginContainer/VBoxContainer/content/ErosionContainer/EnableErosionCheckBox
@onready var erosion_strength_slider: HSlider = $MarginContainer/VBoxContainer/content/ErosionContainer/ErosionStrengthContainer/ErosionStrengthSlider
@onready var erosion_strength_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/ErosionContainer/ErosionStrengthContainer/ErosionStrengthSpinBox
@onready var erosion_iterations_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/ErosionContainer/ErosionIterationsContainer/ErosionIterationsSpinBox
@onready var noise_type_option: OptionButton = $MarginContainer/VBoxContainer/content/NoiseTypeContainer/NoiseTypeOptionButton
@onready var enable_rivers_checkbox: CheckBox = $MarginContainer/VBoxContainer/content/EnableRiversCheckBox
@onready var size_preset_option: OptionButton = $MarginContainer/VBoxContainer/content/SizePresetContainer/SizePresetOptionButton
# Phase 4: LOD controls
@onready var enable_lod_checkbox: CheckBox = $MarginContainer/VBoxContainer/content/LODContainer/EnableLODCheckBox
@onready var lod_levels_spinbox: SpinBox = $MarginContainer/VBoxContainer/content/LODContainer/LODLevelsContainer/LODLevelsSpinBox
@onready var chunk_size_option: OptionButton = $MarginContainer/VBoxContainer/content/LODContainer/ChunkSizeContainer/ChunkSizeOptionButton

const NOISE_TYPES := ["Perlin", "Simplex", "Cellular", "Value"]
const SIZE_PRESET_NAMES := ["Tiny (64×64)", "Small (256×256)", "Medium (512×512)", "Large (1024×1024)", "Epic (2048×2048)"]
const CHUNK_SIZE_OPTIONS := ["32", "64", "128"]

func _ready() -> void:
	"""Initialize terrain section controls and connections."""
	# Populate noise type option button
	noise_type_option.clear()
	for noise_type in NOISE_TYPES:
		noise_type_option.add_item(noise_type)
	noise_type_option.selected = 0
	
	# Populate size preset option button
	if size_preset_option:
		size_preset_option.clear()
		for preset_name in SIZE_PRESET_NAMES:
			size_preset_option.add_item(preset_name)
		size_preset_option.selected = 2  # Default to MEDIUM (512)
		size_preset_option.item_selected.connect(_on_size_preset_changed)
	
	# Connect elevation scale controls
	elevation_scale_slider.value_changed.connect(_on_elevation_scale_changed)
	elevation_scale_spinbox.value_changed.connect(_on_elevation_scale_spinbox_changed)
	
	# Connect terrain chaos controls
	terrain_chaos_slider.value_changed.connect(_on_terrain_chaos_changed)
	terrain_chaos_spinbox.value_changed.connect(_on_terrain_chaos_spinbox_changed)
	
	# Connect domain warping controls
	domain_warp_strength_slider.value_changed.connect(_on_domain_warp_strength_changed)
	domain_warp_strength_spinbox.value_changed.connect(_on_domain_warp_strength_spinbox_changed)
	domain_warp_freq_slider.value_changed.connect(_on_domain_warp_freq_changed)
	
	# Connect erosion controls
	enable_erosion_checkbox.toggled.connect(_on_erosion_enabled_toggled)
	erosion_strength_slider.value_changed.connect(_on_erosion_strength_changed)
	erosion_strength_spinbox.value_changed.connect(_on_erosion_strength_spinbox_changed)
	erosion_iterations_spinbox.value_changed.connect(_on_erosion_iterations_changed)
	
	# Connect noise type
	noise_type_option.item_selected.connect(_on_noise_type_changed)
	
	# Connect rivers checkbox
	enable_rivers_checkbox.toggled.connect(_on_rivers_toggled)
	
	# Phase 4: Connect LOD controls
	if enable_lod_checkbox:
		enable_lod_checkbox.toggled.connect(_on_lod_enabled_toggled)
	if lod_levels_spinbox:
		lod_levels_spinbox.value_changed.connect(_on_lod_levels_changed)
	if chunk_size_option:
		chunk_size_option.item_selected.connect(_on_chunk_size_changed)
		# Populate chunk size options
		chunk_size_option.clear()
		for option in CHUNK_SIZE_OPTIONS:
			chunk_size_option.add_item(option)
		chunk_size_option.selected = 1  # Default to 64
	
	# Setup tooltips and accessibility
	_setup_tooltips()
	_setup_keyboard_navigation()
	
	# Sync initial values
	_sync_elevation_scale()
	_sync_terrain_chaos()

func _setup_tooltips() -> void:
	"""Set tooltips for all controls."""
	if elevation_scale_slider:
		elevation_scale_slider.tooltip_text = "Controls the overall height scale of the terrain. Higher values create more dramatic elevation changes."
	if elevation_scale_spinbox:
		elevation_scale_spinbox.tooltip_text = "Numeric input for elevation scale. Use slider or type directly."
	if terrain_chaos_slider:
		terrain_chaos_slider.tooltip_text = "Controls terrain randomness and variation. Higher values create more chaotic, unpredictable terrain."
	if terrain_chaos_spinbox:
		terrain_chaos_spinbox.tooltip_text = "Numeric input for terrain chaos. Use slider or type directly."
	if noise_type_option:
		noise_type_option.tooltip_text = "Select the noise algorithm type. Perlin: smooth, Simplex: smoother, Cellular: cell-like patterns, Value: blocky."
	if domain_warp_strength_slider:
		domain_warp_strength_slider.tooltip_text = "Domain warping strength (0-100). Creates organic, flowing terrain patterns by distorting noise coordinates. Higher values create more dramatic warping."
	if domain_warp_strength_spinbox:
		domain_warp_strength_spinbox.tooltip_text = "Numeric input for domain warp strength. Use slider or type directly."
	if domain_warp_freq_slider:
		domain_warp_freq_slider.tooltip_text = "Domain warping frequency (0.001-0.1). Controls the scale of the warping effect. Lower values create larger-scale distortions."
	if enable_erosion_checkbox:
		enable_erosion_checkbox.tooltip_text = "Enable erosion simulation. Erosion simulates natural weathering, creating valleys and smoothing terrain."
	if erosion_strength_slider:
		erosion_strength_slider.tooltip_text = "Erosion strength (0-100). Controls how much material is moved by erosion. Higher values create more dramatic terrain smoothing."
	if erosion_strength_spinbox:
		erosion_strength_spinbox.tooltip_text = "Numeric input for erosion strength. Use slider or type directly."
	if erosion_iterations_spinbox:
		erosion_iterations_spinbox.tooltip_text = "Number of erosion passes (1-10). More iterations create smoother, more eroded terrain but take longer to generate."
	if domain_warp_strength_slider:
		domain_warp_strength_slider.focus_mode = Control.FOCUS_ALL
	if domain_warp_strength_spinbox:
		domain_warp_strength_spinbox.focus_mode = Control.FOCUS_ALL
	if domain_warp_freq_slider:
		domain_warp_freq_slider.focus_mode = Control.FOCUS_ALL
	if enable_rivers_checkbox:
		enable_rivers_checkbox.tooltip_text = "Enable river generation in the terrain. Rivers will follow natural height gradients."
	if size_preset_option:
		size_preset_option.tooltip_text = "Select world size preset. Larger sizes take longer to generate but provide more detail."
	if enable_lod_checkbox:
		enable_lod_checkbox.tooltip_text = "Enable Level-of-Detail (LOD) system. Divides world into chunks for better performance on large worlds."
	if lod_levels_spinbox:
		lod_levels_spinbox.tooltip_text = "Number of LOD levels (2-4). Higher values provide more detail levels but use more memory."
	if chunk_size_option:
		chunk_size_option.tooltip_text = "Chunk size in vertices (32, 64, or 128). Smaller chunks provide finer LOD control but more overhead."

func _setup_keyboard_navigation() -> void:
	"""Setup keyboard navigation with focus_next and focus_prev."""
	# Set focus mode for all interactive controls
	if elevation_scale_slider:
		elevation_scale_slider.focus_mode = Control.FOCUS_ALL
	if elevation_scale_spinbox:
		elevation_scale_spinbox.focus_mode = Control.FOCUS_ALL
	if terrain_chaos_slider:
		terrain_chaos_slider.focus_mode = Control.FOCUS_ALL
	if terrain_chaos_spinbox:
		terrain_chaos_spinbox.focus_mode = Control.FOCUS_ALL
	if noise_type_option:
		noise_type_option.focus_mode = Control.FOCUS_ALL
	if enable_rivers_checkbox:
		enable_rivers_checkbox.focus_mode = Control.FOCUS_ALL
	if size_preset_option:
		size_preset_option.focus_mode = Control.FOCUS_ALL
	
	# Focus navigation is handled automatically by container layouts in Godot
	# Manual focus chain setup removed - VBoxContainer handles focus navigation automatically

func _on_elevation_scale_changed(value: float) -> void:
	"""Handle elevation scale slider change."""
	elevation_scale_spinbox.value = value
	emit_signal("param_changed", "elevation_scale", value)

func _on_elevation_scale_spinbox_changed(value: float) -> void:
	"""Handle elevation scale spinbox change."""
	elevation_scale_slider.value = value
	emit_signal("param_changed", "elevation_scale", value)

func _on_terrain_chaos_changed(value: float) -> void:
	"""Handle terrain chaos slider change."""
	terrain_chaos_spinbox.value = value
	emit_signal("param_changed", "terrain_chaos", value)

func _on_terrain_chaos_spinbox_changed(value: float) -> void:
	"""Handle terrain chaos spinbox change."""
	terrain_chaos_slider.value = value
	emit_signal("param_changed", "terrain_chaos", value)

func _on_domain_warp_strength_changed(value: float) -> void:
	"""Handle domain warp strength slider change."""
	if domain_warp_strength_spinbox:
		domain_warp_strength_spinbox.value = value
	emit_signal("param_changed", "domain_warp_strength", value)

func _on_domain_warp_strength_spinbox_changed(value: float) -> void:
	"""Handle domain warp strength spinbox change."""
	if domain_warp_strength_slider:
		domain_warp_strength_slider.value = value
	emit_signal("param_changed", "domain_warp_strength", value)

func _on_domain_warp_freq_changed(value: float) -> void:
	"""Handle domain warp frequency slider change."""
	emit_signal("param_changed", "domain_warp_frequency", value)

func _on_erosion_enabled_toggled(pressed: bool) -> void:
	"""Handle erosion enable checkbox toggle."""
	emit_signal("param_changed", "enable_erosion", pressed)

func _on_erosion_strength_changed(value: float) -> void:
	"""Handle erosion strength slider change."""
	if erosion_strength_spinbox:
		erosion_strength_spinbox.value = value
	# Convert 0-100 to 0.0-1.0 for param
	var normalized_value: float = value / 100.0
	emit_signal("param_changed", "erosion_strength", normalized_value)

func _on_erosion_strength_spinbox_changed(value: float) -> void:
	"""Handle erosion strength spinbox change."""
	if erosion_strength_slider:
		erosion_strength_slider.value = value
	# Convert 0-100 to 0.0-1.0 for param
	var normalized_value: float = value / 100.0
	emit_signal("param_changed", "erosion_strength", normalized_value)

func _on_erosion_iterations_changed(value: float) -> void:
	"""Handle erosion iterations spinbox change."""
	emit_signal("param_changed", "erosion_iterations", int(value))

func _on_noise_type_changed(index: int) -> void:
	"""Handle noise type selection change."""
	emit_signal("param_changed", "noise_type", NOISE_TYPES[index])

func _on_rivers_toggled(pressed: bool) -> void:
	"""Handle rivers checkbox toggle."""
	emit_signal("param_changed", "enable_rivers", pressed)

func _on_size_preset_changed(index: int) -> void:
	"""Handle size preset selection change."""
	emit_signal("param_changed", "size_preset", index)

func _on_lod_enabled_toggled(pressed: bool) -> void:
	"""Handle LOD enable checkbox toggle."""
	emit_signal("param_changed", "enable_lod", pressed)

func _on_lod_levels_changed(value: float) -> void:
	"""Handle LOD levels spinbox change."""
	emit_signal("param_changed", "lod_levels", int(value))

func _on_chunk_size_changed(index: int) -> void:
	"""Handle chunk size option selection change."""
	var chunk_size: int = int(CHUNK_SIZE_OPTIONS[index])
	emit_signal("param_changed", "chunk_size", chunk_size)

func _sync_elevation_scale() -> void:
	"""Sync elevation scale slider and spinbox."""
	elevation_scale_spinbox.value = elevation_scale_slider.value

func _sync_terrain_chaos() -> void:
	"""Sync terrain chaos slider and spinbox."""
	terrain_chaos_spinbox.value = terrain_chaos_slider.value

func _sync_domain_warp_strength() -> void:
	"""Sync domain warp strength slider and spinbox."""
	if domain_warp_strength_slider and domain_warp_strength_spinbox:
		domain_warp_strength_spinbox.value = domain_warp_strength_slider.value

func get_params() -> Dictionary:
	"""Get all terrain parameters as dictionary."""
	var params: Dictionary = {
		"elevation_scale": elevation_scale_slider.value,
		"terrain_chaos": terrain_chaos_slider.value,
		"noise_type": NOISE_TYPES[noise_type_option.selected],
		"enable_rivers": enable_rivers_checkbox.button_pressed,
		"domain_warp_strength": domain_warp_strength_slider.value if domain_warp_strength_slider else 0.0,
		"domain_warp_frequency": domain_warp_freq_slider.value if domain_warp_freq_slider else 0.005,
		"enable_erosion": enable_erosion_checkbox.button_pressed if enable_erosion_checkbox else false,
		"erosion_strength": (erosion_strength_slider.value / 100.0) if erosion_strength_slider else 0.5,
		"erosion_iterations": int(erosion_iterations_spinbox.value) if erosion_iterations_spinbox else 5,
		"enable_lod": enable_lod_checkbox.button_pressed if enable_lod_checkbox else true,
		"lod_levels": int(lod_levels_spinbox.value) if lod_levels_spinbox else 3,
		"chunk_size": int(CHUNK_SIZE_OPTIONS[chunk_size_option.selected]) if chunk_size_option else 64,
		"lod_distances": [500.0, 2000.0]  # Default LOD distance thresholds
	}
	if size_preset_option:
		params["size_preset"] = size_preset_option.selected
	return params

func set_params(params: Dictionary) -> void:
	"""Set terrain parameters from dictionary."""
	if params.has("elevation_scale"):
		var value: float = params["elevation_scale"]
		elevation_scale_slider.value = value
		elevation_scale_spinbox.value = value
	
	if params.has("terrain_chaos"):
		var value: float = params["terrain_chaos"]
		terrain_chaos_slider.value = value
		terrain_chaos_spinbox.value = value
	
	if params.has("noise_type"):
		var noise_type: String = params["noise_type"]
		var index: int = NOISE_TYPES.find(noise_type)
		if index >= 0:
			noise_type_option.selected = index
	
	if params.has("enable_rivers"):
		enable_rivers_checkbox.button_pressed = params["enable_rivers"]
	
	if params.has("domain_warp_strength"):
		var value: float = params["domain_warp_strength"]
		if domain_warp_strength_slider:
			domain_warp_strength_slider.value = value
		if domain_warp_strength_spinbox:
			domain_warp_strength_spinbox.value = value
	
	if params.has("domain_warp_frequency"):
		var value: float = params["domain_warp_frequency"]
		if domain_warp_freq_slider:
			domain_warp_freq_slider.value = value
	
	if params.has("enable_erosion"):
		if enable_erosion_checkbox:
			enable_erosion_checkbox.button_pressed = params["enable_erosion"]
	
	if params.has("erosion_strength"):
		var value: float = params["erosion_strength"]
		# Convert 0.0-1.0 to 0-100 for UI
		var ui_value: float = value * 100.0
		if erosion_strength_slider:
			erosion_strength_slider.value = ui_value
		if erosion_strength_spinbox:
			erosion_strength_spinbox.value = ui_value
	
	if params.has("erosion_iterations"):
		var value: int = params["erosion_iterations"]
		if erosion_iterations_spinbox:
			erosion_iterations_spinbox.value = float(value)
	
	if params.has("size_preset") and size_preset_option:
		var preset_index: int = params["size_preset"]
		if preset_index >= 0 and preset_index < SIZE_PRESET_NAMES.size():
			size_preset_option.selected = preset_index
	
	# Phase 4: Set LOD params
	if params.has("enable_lod") and enable_lod_checkbox:
		enable_lod_checkbox.button_pressed = params["enable_lod"]
	
	if params.has("lod_levels") and lod_levels_spinbox:
		var levels: int = params["lod_levels"]
		lod_levels_spinbox.value = clamp(float(levels), 2.0, 4.0)
	
	if params.has("chunk_size") and chunk_size_option:
		var chunk_size: int = params["chunk_size"]
		var index: int = CHUNK_SIZE_OPTIONS.find(str(chunk_size))
		if index >= 0:
			chunk_size_option.selected = index
	
	if params.has("lod_distances"):
		# lod_distances is stored in params but not displayed in UI (uses defaults)
		pass

