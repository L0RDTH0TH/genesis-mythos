# ╔═══════════════════════════════════════════════════════════
# ║ PreviewManager.gd
# ║ Desc: Single source of truth for all visual fantasy effects
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node
class_name PreviewManager

var terrain_mesh_instance: MeshInstance3D
var particles: GPUParticles3D
var environment: WorldEnvironment
var camera: Camera3D

static var current: PreviewManager

func _ready() -> void:
	current = self
	add_to_group("preview_manager")
	
	# Find nodes in the scene hierarchy
	# PreviewManager is a child of WorldPreviewRoot, so siblings are "../"
	terrain_mesh_instance = get_node_or_null("../terrain_mesh")
	particles = get_node_or_null("../MagicParticles")
	camera = get_node_or_null("../Camera3D")
	
	# WorldEnvironment is a sibling of WorldPreviewRoot (same parent: WorldPreviewViewport)
	# So we need to go up to parent, then find sibling
	var parent_root: Node3D = get_parent()
	if parent_root:
		var viewport: SubViewport = parent_root.get_parent() as SubViewport
		if viewport:
			environment = viewport.get_node_or_null("WorldEnvironment")
	
	# Debug: Print found nodes
	if not terrain_mesh_instance:
		push_warning("PreviewManager: terrain_mesh_instance not found")
	if not particles:
		push_warning("PreviewManager: MagicParticles not found")
	if not environment:
		push_warning("PreviewManager: WorldEnvironment not found")
	if not camera:
		push_warning("PreviewManager: Camera3D not found")

func apply_fantasy_style_instant(data: Dictionary) -> void:
	"""Apply visual fantasy style effects instantly.
	
	Args:
		data: Dictionary containing style parameters (skybox, particles, bloom, fog, tint, etc.)
	"""
	if not terrain_mesh_instance or not environment or not environment.environment:
		push_warning("PreviewManager: Missing required nodes for style application")
		return
	
	# Skybox
	var sky_mat: PanoramaSkyMaterial = PanoramaSkyMaterial.new()
	if data.has("skybox") and FileAccess.file_exists(data["skybox"]):
		var skybox_texture: Texture2D = load(data["skybox"])
		if skybox_texture:
			sky_mat.panorama = skybox_texture
		else:
			push_warning("PreviewManager: Failed to load skybox: " + str(data["skybox"]))
	
	environment.environment.background_mode = Environment.BG_SKY
	if not environment.environment.sky:
		environment.environment.sky = Sky.new()
	environment.environment.sky.sky_material = sky_mat
	
	# Particles
	if particles:
		if data.has("particle_density"):
			particles.amount = data["particle_density"]
		
		if data.has("particle_color"):
			var process_mat: ParticleProcessMaterial = particles.process_material
			if not process_mat:
				process_mat = ParticleProcessMaterial.new()
				particles.process_material = process_mat
			
			process_mat.color = data["particle_color"]
			if data.has("particle_density") and data["particle_density"] > 0:
				process_mat.emission_ring_radius = 300.0
				process_mat.emission_ring_height = 200.0
				particles.emitting = true
			else:
				particles.emitting = false
		else:
			particles.emitting = false
	else:
		push_warning("PreviewManager: MagicParticles node not found")
	
	# Bloom + Fog
	if data.has("bloom_intensity"):
		environment.environment.glow_enabled = true
		environment.environment.glow_intensity = data["bloom_intensity"]
	
	if data.has("fog_density"):
		environment.environment.fog_enabled = true
		environment.environment.fog_density = data["fog_density"]
	
	# Tint via shader
	if data.has("tint"):
		var mat: Material = terrain_mesh_instance.material_override
		if mat and mat is ShaderMaterial:
			var shader_mat: ShaderMaterial = mat as ShaderMaterial
			shader_mat.set_shader_parameter("tint_color", data["tint"])
	
	# Floating islands (simple Y offset + second noise layer)
	if data.get("floating_islands", false):
		# This will be handled in terrain generation
		pass
