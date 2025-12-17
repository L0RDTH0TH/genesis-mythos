# ╔═══════════════════════════════════════════════════════════
# ║ MapEditor.gd
# ║ Desc: Handles 2D parchment map editing and procedural world generation with correct scaling.
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends CanvasLayer

@onready var canvas: TextureRect = $Canvas
@onready var size_dropdown: OptionButton = $Step1Panel/SizeDropdown
@onready var seed_input: LineEdit = $Step1Panel/SeedInput
@onready var random_seed_button: Button = $Step1Panel/RandomSeedButton
@onready var style_dropdown: OptionButton = $Step1Panel/StyleDropdown
@onready var landmass_dropdown: OptionButton = $Step1Panel/LandmassDropdown
@onready var generate_button: Button = $Step1Panel/GenerateButton

var height_img: Image
var biome_img: Image
var canvas_texture: ImageTexture = ImageTexture.new()  # Persistent reference – this is the key

var map_width: int = 1024
var map_height: int = 1024
var seed_value: int = 12345
var archetypes: Dictionary = {}  # Maps display name to file path
var available_archetypes: Array[String] = []  # List of archetype display names
var current_archetype: Dictionary = {}  # Currently loaded archetype data
var selected_style: String = "High Fantasy"

var size_map: Dictionary = {"Tiny": 512, "Small": 1024, "Medium": 2048, "Large": 4096, "Extra Large": 8192}
var landmass_types: Array[String] = ["Continents", "Island Chain", "Single Island", "Archipelago", "Pangea", "Coastal"]

const ARCHETYPES_DIR: String = "res://data/archetypes/"

# Brush variables for manual editing (from original implementation)
var brush_size: int = 20
var strength: float = 0.1
var mode: String = "raise"
var brush_color: Color = Color.GREEN

func _ready() -> void:
	# Perfect centering and scaling setup
	if canvas != null:
		canvas.anchor_left = 0.5
		canvas.anchor_top = 0.5
		canvas.anchor_right = 0.5
		canvas.anchor_bottom = 0.5
		canvas.pivot_offset = canvas.size / 2
		canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
		canvas.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	
	# Load available archetypes from directory
	_load_archetype_list()
	
	# Populate Size dropdown
	if size_dropdown != null:
		for size in size_map.keys():
			size_dropdown.add_item(size)
		size_dropdown.selected = 1  # Default Small
		size_dropdown.item_selected.connect(_on_size_selected)
	
	# Populate Fantasy Style dropdown
	if style_dropdown != null:
		for style_name: String in available_archetypes:
			style_dropdown.add_item(style_name)
		style_dropdown.selected = 0
		style_dropdown.item_selected.connect(_on_style_selected)
		if available_archetypes.size() > 0:
			_on_style_selected(0)  # Initialize with first style
	
	# Populate Landmass dropdown
	if landmass_dropdown != null:
		for landmass in landmass_types:
			landmass_dropdown.add_item(landmass)
		landmass_dropdown.item_selected.connect(_on_landmass_selected)
	
	# Connect signals
	if random_seed_button != null:
		random_seed_button.pressed.connect(_on_random_seed)
	if generate_button != null:
		generate_button.pressed.connect(_on_generate_map)
	if seed_input != null:
		seed_input.text_submitted.connect(_on_seed_changed)
		seed_input.text = str(seed_value)
	
	# Initial images setup
	_resize_images()

func _resize_images() -> void:
	if size_dropdown == null:
		return
	
	map_width = size_map[size_dropdown.get_item_text(size_dropdown.selected)]
	map_height = map_width
	
	height_img = Image.create(map_width, map_height, false, Image.FORMAT_RF)
	biome_img = Image.create(map_width, map_height, false, Image.FORMAT_RGB8)
	
	# DO NOT fill biome_img here — we want the procedural colors to show!
	height_img.fill(Color.BLACK)  # Sea level = black
	# biome_img is left completely empty on purpose
	
	update_canvas()  # Will show clean parchment until Generate is pressed

func update_canvas() -> void:
	var combined: Image = Image.create(map_width, map_height, false, Image.FORMAT_RGBA8)
	
	# Blit biome colors first
	combined.blit_rect(biome_img, Rect2(0, 0, map_width, map_height), Vector2(0, 0))
	
	# Overlay height as alpha channel
	for y: int in map_height:
		for x: int in map_width:
			var h: float = height_img.get_pixel(x, y).r
			var col: Color = combined.get_pixel(x, y)
			combined.set_pixel(x, y, Color(col.r, col.g, col.b, h))
	
	# BULLETPROOF FIX: Recreate ImageTexture entirely to avoid all caching issues
	canvas_texture = ImageTexture.create_from_image(combined)
	
	# Assign to TextureRect with proper refresh
	if canvas != null:
		# Step 1: Break old reference to force TextureRect to re-read size
		canvas.texture = null
		
		# Step 2: Assign new texture
		canvas.texture = canvas_texture
		
		# Step 3: Force layout recalculation by resetting minimum size
		canvas.custom_minimum_size = Vector2.ZERO
		
		# Step 4: Set stretch mode explicitly (defensive)
		canvas.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		canvas.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		
		# Step 5: Force redraw and parent container update
		canvas.queue_redraw()
		var parent: Control = canvas.get_parent()
		if parent != null:
			parent.update_minimum_size()

func _on_size_selected(_index: int) -> void:
	_resize_images()  # This now fully refreshes everything

func _on_style_selected(index: int) -> void:
	if style_dropdown == null:
		return
	selected_style = style_dropdown.get_item_text(index)
	current_archetype = _load_archetype_by_name(selected_style)
	if current_archetype.is_empty():
		return
	
	# Set recommended size
	var rec_size: String = current_archetype.get("recommended_size", "Small")
	if size_dropdown != null:
		var size_index: int = 0
		for i in range(size_dropdown.get_item_count()):
			if size_dropdown.get_item_text(i) == rec_size:
				size_index = i
				break
		size_dropdown.selected = size_index
		_on_size_selected(size_index)
	
	# Set default landmass
	var rec_land: String = current_archetype.get("default_landmass", "Continents")
	if landmass_dropdown != null:
		var land_index: int = landmass_types.find(rec_land)
		if land_index >= 0:
			landmass_dropdown.selected = land_index
	
	# Set tooltip
	if style_dropdown != null:
		style_dropdown.tooltip_text = current_archetype.get("description", "")

func _load_archetype_list() -> void:
	"""Load list of available archetype files from directory."""
	var dir: DirAccess = DirAccess.open(ARCHETYPES_DIR)
	if dir == null:
		push_error("MapEditor: Failed to open archetypes directory: " + ARCHETYPES_DIR)
		return
	
	available_archetypes.clear()
	archetypes.clear()
	
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".json"):
			var file_path: String = ARCHETYPES_DIR + file_name
			var arch_data: Dictionary = _load_archetype_file(file_path)
			if not arch_data.is_empty():
				var display_name: String = arch_data.get("name", file_name.get_basename().replace("_", " "))
				available_archetypes.append(display_name)
				archetypes[display_name] = file_path
		
		file_name = dir.get_next()
	
	available_archetypes.sort()
	print("MapEditor: Loaded ", available_archetypes.size(), " archetype definitions")


func _load_archetype_file(file_path: String) -> Dictionary:
	"""Load a single archetype file and return its data."""
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("MapEditor: Failed to load archetype from " + file_path)
		return {}
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var arch_data: Dictionary = JSON.parse_string(json_string)
	if arch_data.is_empty():
		push_error("MapEditor: Failed to parse archetype JSON from " + file_path)
		return {}
	
	return arch_data


func _load_archetype_by_name(archetype_name: String) -> Dictionary:
	"""Load a specific archetype by its display name."""
	var file_path: String = archetypes.get(archetype_name, "")
	if file_path.is_empty():
		push_error("MapEditor: Archetype not found: " + archetype_name)
		return {}
	
	return _load_archetype_file(file_path)


func _on_landmass_selected(_index: int) -> void:
	pass  # Placeholder

func _on_random_seed() -> void:
	seed_value = randi() % 999999 + 1
	if seed_input != null:
		seed_input.text = str(seed_value)

func _on_seed_changed(text: String) -> void:
	if text.is_valid_int():
		seed_value = text.to_int()
	else:
		if seed_input != null:
			seed_input.text = str(seed_value)

func _on_generate_map() -> void:
	# Reload archetype to ensure we have latest data
	current_archetype = _load_archetype_by_name(selected_style)
	if current_archetype.is_empty():
		return
	
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = seed_value
	
	# Map noise type string to enum - support both old flat format and new grouped format
	var noise_type_str: String
	if current_archetype.has("noise"):
		noise_type_str = current_archetype["noise"].get("noise_type", "TYPE_SIMPLEX")
	else:
		noise_type_str = current_archetype.get("noise_type", "TYPE_SIMPLEX")
	var noise_type: FastNoiseLite.NoiseType = FastNoiseLite.NoiseType.TYPE_SIMPLEX
	match noise_type_str:
		"TYPE_SIMPLEX":
			noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
		"TYPE_SIMPLEX_SMOOTH":
			noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX_SMOOTH
		"TYPE_PERLIN":
			noise_type = FastNoiseLite.NoiseType.TYPE_PERLIN
		"TYPE_VALUE":
			noise_type = FastNoiseLite.NoiseType.TYPE_VALUE
		"TYPE_CELLULAR":
			noise_type = FastNoiseLite.NoiseType.TYPE_CELLULAR
	
	noise.noise_type = noise_type
	# Support both old flat format and new grouped format
	var height_scale: float = 0.8
	if current_archetype.has("noise"):
		noise.frequency = current_archetype["noise"].get("frequency", 0.004)
		noise.fractal_octaves = current_archetype["noise"].get("octaves", 6)
		noise.fractal_gain = current_archetype["noise"].get("gain", 0.5)
		noise.fractal_lacunarity = current_archetype["noise"].get("lacunarity", 2.0)
		height_scale = current_archetype["noise"].get("height_scale", 0.8)
	else:
		noise.frequency = current_archetype.get("frequency", 0.004)
		noise.fractal_octaves = current_archetype.get("octaves", 6)
		noise.fractal_gain = current_archetype.get("gain", 0.5)
		noise.fractal_lacunarity = current_archetype.get("lacunarity", 2.0)
		height_scale = current_archetype.get("height_scale", 0.8)
	
	# Generate heightmap
	for y: int in map_height:
		for x: int in map_width:
			var val: float = (noise.get_noise_2d(x, y) + 1.0) / 2.0 * height_scale
			val = clampf(val, 0.0, 1.0)
			height_img.set_pixel(x, y, Color(val, val, val))
	
	# Apply landmass-specific mask
	var landmass: String = "Continents"
	if landmass_dropdown != null:
		landmass = landmass_dropdown.get_item_text(landmass_dropdown.selected)
	
	match landmass:
		"Single Island":
			_apply_radial_mask(0.5, 0.5, 0.35)
		"Island Chain":
			_apply_multi_radial_mask(4, 0.25)
		"Archipelago":
			_apply_multi_radial_mask(12, 0.15)
		"Pangea":
			_apply_radial_mask(0.5, 0.5, 0.9, true)
		"Coastal":
			_apply_coastal_mask()
		_:  # Continents: no mask
			pass
	
	# NOW paint the biomes using the selected archetype
	# Support both old flat format and new grouped format
	var colors: Dictionary
	if current_archetype.has("biomes") and current_archetype["biomes"].has("colors"):
		colors = current_archetype["biomes"]["colors"]
	elif current_archetype.has("biome_colors"):
		colors = current_archetype["biome_colors"]
	else:
		push_error("MapEditor: No biome colors found in archetype")
		return
	
	for y: int in map_height:
		for x: int in map_width:
			var h: float = height_img.get_pixel(x, y).r
			
			var col: Color = Color(colors["water"])
			if h > 0.38:   col = Color(colors["beach"])
			if h > 0.42:   col = Color(colors["grass"])
			if h > 0.55:   col = Color(colors["forest"])
			if h > 0.70:   col = Color(colors["hill"])
			if h > 0.85:   col = Color(colors["mountain"])
			if h > 0.95:   col = Color(colors["snow"])
			
			biome_img.set_pixel(x, y, col)
	
	update_canvas()  # ← This now shows the real land!

func _apply_radial_mask(cx: float, cy: float, radius: float, invert: bool = false) -> void:
	var center: Vector2 = Vector2(map_width * cx, map_height * cy)
	for y: int in map_height:
		for x: int in map_width:
			var dist: float = Vector2(x, y).distance_to(center) / (map_width * radius)
			var falloff: float = clampf(1.0 - dist, 0.0, 1.0)
			if invert:
				falloff = 1.0 - falloff
			var val: float = height_img.get_pixel(x, y).r * falloff
			height_img.set_pixel(x, y, Color(val, val, val))

func _apply_multi_radial_mask(num: int, radius: float) -> void:
	for i: int in num:
		var cx: float = randf_range(0.1, 0.9)
		var cy: float = randf_range(0.1, 0.9)
		_apply_radial_mask(cx, cy, radius)

func _apply_coastal_mask() -> void:
	_apply_radial_mask(0.5, 0.5, 0.7, true)  # Lower edges for coastal effect
