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
var archetypes: Dictionary = {}
var selected_style: String = "High Fantasy"

var size_map: Dictionary = {"Tiny": 512, "Small": 1024, "Medium": 2048, "Large": 4096, "Extra Large": 8192}
var landmass_types: Array[String] = ["Continents", "Island Chain", "Single Island", "Archipelago", "Pangea", "Coastal"]

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
	
	# Load archetypes from JSON
	var file: FileAccess = FileAccess.open("res://data/fantasy_archetypes.json", FileAccess.READ)
	if file:
		archetypes = JSON.parse_string(file.get_as_text())
		file.close()
	else:
		print("Error loading fantasy_archetypes.json")
	
	# Populate Size dropdown
	if size_dropdown != null:
		for size in size_map.keys():
			size_dropdown.add_item(size)
		size_dropdown.selected = 1  # Default Small
		size_dropdown.item_selected.connect(_on_size_selected)
	
	# Populate Fantasy Style dropdown
	if style_dropdown != null:
		for style in archetypes.keys():
			style_dropdown.add_item(style)
		style_dropdown.selected = 0
		style_dropdown.item_selected.connect(_on_style_selected)
		if archetypes.size() > 0:
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
	var arch: Dictionary = archetypes.get(selected_style, {})
	if arch.is_empty():
		return
	
	# Set recommended size
	var rec_size: String = arch.get("recommended_size", "Small")
	if size_dropdown != null:
		var size_index: int = 0
		for i in range(size_dropdown.get_item_count()):
			if size_dropdown.get_item_text(i) == rec_size:
				size_index = i
				break
		size_dropdown.selected = size_index
		_on_size_selected(size_index)
	
	# Set default landmass
	var rec_land: String = arch.get("default_landmass", "Continents")
	if landmass_dropdown != null:
		var land_index: int = landmass_types.find(rec_land)
		if land_index >= 0:
			landmass_dropdown.selected = land_index
	
	# Set tooltip
	if style_dropdown != null:
		style_dropdown.tooltip_text = arch.get("description", "")

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
	var arch: Dictionary = archetypes.get(selected_style, {})
	if arch.is_empty():
		return
	
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = seed_value
	
	# Map noise type string to enum
	var noise_type_str: String = arch.get("noise_type", "TYPE_SIMPLEX")
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
	noise.frequency = arch.get("frequency", 0.004)
	noise.fractal_octaves = arch.get("octaves", 6)
	noise.fractal_gain = arch.get("gain", 0.5)
	noise.fractal_lacunarity = arch.get("lacunarity", 2.0)
	var height_scale: float = arch.get("height_scale", 0.8)
	
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
	var colors: Dictionary = arch["biome_colors"]
	
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
