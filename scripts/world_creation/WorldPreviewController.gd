# ╔═══════════════════════════════════════════════════════════
# ║ WorldPreviewController.gd
# ║ Desc: Generates and updates the 3D world preview from seed/size
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
@tool
extends Node3D

@onready var mesh_instance: MeshInstance3D = $WorldMesh
@onready var camera: Camera3D = $PreviewCamera
var noise := FastNoiseLite.new()
var heightmap_image := Image.create(512, 512, false, Image.FORMAT_RF)
var heightmap_texture := preload("res://assets/textures/generated_heightmap.tres") as Texture2D
var orbit_tween: Tween = null

func _ready() -> void:
	"""Initialize the preview controller"""
	# Generate initial preview with default values
	if mesh_instance and heightmap_texture:
		generate_preview(randi(), Vector2i(256, 256))

func _process(_delta: float) -> void:
	"""Update shader time parameter for animations"""
	if mesh_instance and mesh_instance.material_override:
		mesh_instance.material_override.set_shader_parameter("time", Time.get_ticks_msec() * 0.001)

func generate_preview(world_seed: int, world_size: Vector2i) -> void:
	"""Generate heightmap and update the 3D preview"""
	if not mesh_instance:
		await ready
		if not mesh_instance:
			return
	
	noise.seed = world_seed
	noise.frequency = 0.002
	noise.fractal_octaves = 8
	noise.fractal_lacunarity = 2.1
	noise.fractal_gain = 0.45
	
	var img := Image.create(1024, 1024, false, Image.FORMAT_RF)
	for x in 1024:
		for y in 1024:
			var nx := (float(x)/1024 - 0.5) * 12.0
			var ny := (float(y)/1024 - 0.5) * 12.0
			var n := noise.get_noise_2d(nx*100, ny*100)
			n = (n + noise.get_noise_2d(nx*250, ny*250) * 0.3 + noise.get_noise_2d(nx*600, ny*600) * 0.1)
			n = (n + 1.0) * 0.5
			img.set_pixel(x, y, Color(n, n, n, 1))
	
	var tex := ImageTexture.create_from_image(img)
	if mesh_instance.material_override:
		mesh_instance.material_override.set_shader_parameter("heightmap", tex)
		mesh_instance.material_override.set_shader_parameter("global_time", Time.get_ticks_msec() * 0.001)
	
	# Slow majestic orbit
	if orbit_tween:
		orbit_tween.kill()
	orbit_tween = create_tween()
	orbit_tween.set_loops()
	orbit_tween.tween_property(camera, "rotation_degrees:y", 360, 120).from(0)
	var pos_tween = orbit_tween.parallel().tween_property(camera, "position:y", 25, 60).from(15)
	if pos_tween:
		pos_tween.set_trans(Tween.TRANS_SINE)
		pos_tween.set_ease(Tween.EASE_IN_OUT)
