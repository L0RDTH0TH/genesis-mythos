# ╔═══════════════════════════════════════════════════════════
# ║ world_preview.gd
# ║ Desc: 3D world preview with mouse orbit and zoom controls
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
extends Node3D

# Phase 4: LOD Manager (preloaded for static functions)
const LODManager = preload("res://scripts/world_creation/LODManager.gd")
# Phase 5: Biome Texture Manager
const BiomeTextureManager = preload("res://scripts/world_creation/BiomeTextureManager.gd")
# Phase 4: WorldGenerator for threaded preview
const WorldGenerator = preload("res://scripts/world_creation/WorldGenerator.gd")

@onready var camera: Camera3D = $Camera3D
@onready var terrain_mesh_instance: MeshInstance3D = $terrain_mesh
@onready var biome_overlay: MeshInstance3D = $biome_overlay

var node_points_instance: MultiMeshInstance3D = null
var node_points_orange_instance: MultiMeshInstance3D = null
var river_points_instance: MultiMeshInstance3D = null  # Phase 2: River visualization
var foliage_points_instance: MultiMeshInstance3D = null  # Phase 3: Foliage visualization
var poi_points_instance: MultiMeshInstance3D = null  # Phase 3: POI markers

# Phase 4: LOD & Chunks
var chunk_nodes: Dictionary = {}  # Chunk key -> MeshInstance3D
var chunks_container: Node3D = null  # Container for chunk meshes

# Phase 4: Threaded preview generation
var preview_thread: Thread = null
var preview_timer: Timer = null
var is_generating_preview: bool = false
var pending_world_data = null  # WorldData to generate preview for

var biome_overlay_enabled: bool = false
var world_data = null  # WorldData - type annotation removed for @tool compatibility

var camera_distance: float = 500.0  # Closer initial distance
var camera_yaw: float = 0.3  # Slight rotation for dynamic view
var camera_pitch: float = -0.35  # More angled downward for closer view
var is_dragging: bool = false
var last_mouse_pos: Vector2

const MIN_DISTANCE: float = 100.0
const MAX_DISTANCE: float = 5000.0
const MIN_PITCH: float = -PI / 2 + 0.1
const MAX_PITCH: float = PI / 2 - 0.1
const ZOOM_SENSITIVITY: float = 50.0
const ROTATION_SENSITIVITY: float = 0.005

func _ready() -> void:
	"""Initialize camera position and create node points instance."""
	_update_camera_position()
	_setup_node_points()
	_setup_preview_timer()

func _input(event: InputEvent) -> void:
	"""Handle input events for camera control."""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			if event.pressed:
				last_mouse_pos = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = clamp(camera_distance - ZOOM_SENSITIVITY, MIN_DISTANCE, MAX_DISTANCE)
			_update_camera_position()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = clamp(camera_distance + ZOOM_SENSITIVITY, MIN_DISTANCE, MAX_DISTANCE)
			_update_camera_position()
	
	elif event is InputEventMouseMotion and is_dragging:
		var delta: Vector2 = event.position - last_mouse_pos
		camera_yaw -= delta.x * ROTATION_SENSITIVITY
		camera_pitch = clamp(camera_pitch - delta.y * ROTATION_SENSITIVITY, MIN_PITCH, MAX_PITCH)
		last_mouse_pos = event.position
		_update_camera_position()
		_update_lod()  # Phase 4: Update LOD on camera movement

func _update_camera_position() -> void:
	"""Update camera position based on yaw, pitch, and distance."""
	var offset: Vector3 = Vector3(
		sin(camera_yaw) * cos(camera_pitch),
		sin(camera_pitch),
		cos(camera_yaw) * cos(camera_pitch)
	) * camera_distance
	
	camera.position = offset
	camera.look_at(Vector3.ZERO, Vector3.UP)

func update_mesh(new_mesh: Mesh) -> void:
	"""Update the terrain mesh instance with a new mesh."""
	if not terrain_mesh_instance:
		print("world_preview: ERROR - terrain_mesh_instance is null")
		return
	
	if not new_mesh:
		print("world_preview: ERROR - new_mesh is null")
		return
	
	if new_mesh.get_surface_count() == 0:
		print("world_preview: ERROR - mesh has no surfaces")
		return
	
	terrain_mesh_instance.mesh = new_mesh
	
	# Phase 5: Apply shader material (new world_preview shader or fallback)
	_apply_world_shader(new_mesh)
	
	# Auto-fit camera to mesh bounds
	auto_fit_camera()
	
	# Update biome overlay if enabled
	if biome_overlay_enabled and new_mesh:
		_update_biome_overlay(new_mesh)
	
	# Phase 2: Update river visualization
	if world_data and world_data.has_method("get") and world_data.get("river_paths"):
		_update_river_visualization(new_mesh)

func _apply_world_shader(mesh: Mesh) -> void:
	"""Apply world preview shader material with texture splatting (Phase 5).
	
	Falls back to old topo shader if biome textures are missing.
	"""
	if not terrain_mesh_instance or not mesh:
		print("world_preview: Cannot apply shader - missing mesh_instance or mesh")
		return
	
	# Phase 5: Try to use new world_preview shader
	var new_shader_path: String = "res://assets/shaders/world_preview.gdshader"
	var new_shader: Shader = load(new_shader_path)
	
	if new_shader and world_data and world_data.has("splatmap_texture") and world_data.splatmap_texture:
		# Use new shader with texture splatting
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = new_shader
		
		# Generate heightmap texture
		var heightmap_texture: ImageTexture = _generate_heightmap_texture(mesh)
		if heightmap_texture:
			material.set_shader_parameter("heightmap", heightmap_texture)
		
		# Set splatmap
		material.set_shader_parameter("splatmap", world_data.splatmap_texture)
		
		# Load biome textures
		_apply_biome_textures(material)
		
		# Set river map if available
		if world_data.has("river_map_texture") and world_data.river_map_texture:
			material.set_shader_parameter("river_map", world_data.river_map_texture)
		
		# Set foliage density map if available
		if world_data.has("foliage_density_texture") and world_data.foliage_density_texture:
			material.set_shader_parameter("foliage_density_map", world_data.foliage_density_texture)
		
		# Set preview mode
		var preview_mode: int = world_data.params.get("preview_mode", 0)
		material.set_shader_parameter("preview_mode", preview_mode)
		
		# Set material properties
		material.set_shader_parameter("tint_color", world_data.params.get("tint_color", Vector3(1.0, 1.0, 1.0)))
		material.set_shader_parameter("use_texture_splatting", true)
		material.set_shader_parameter("use_normal_mapping", world_data.params.get("use_normal_mapping", true))
		
		terrain_mesh_instance.material_override = material
		print("world_preview: Applied new world_preview shader with texture splatting")
		return
	
	# Fallback: Use old topo shader
	_apply_topo_shader_fallback(mesh)

func _apply_topo_shader_fallback(mesh: Mesh) -> void:
	"""Fallback to old topo shader (backward compatibility)."""
	if not terrain_mesh_instance or not mesh:
		return
	
	# Load old shader
	var shader_path: String = "res://assets/shaders/topo_preview.gdshader"
	var shader: Shader = load(shader_path)
	if not shader:
		print("world_preview: WARNING - Old shader not found, using fallback material")
		var fallback_material: StandardMaterial3D = StandardMaterial3D.new()
		fallback_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fallback_material.albedo_color = Color(0.2, 0.5, 1.0, 1.0)
		terrain_mesh_instance.material_override = fallback_material
		return
	
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	
	# Generate heightmap texture
	var heightmap_texture: ImageTexture = _generate_heightmap_texture(mesh)
	if heightmap_texture:
		material.set_shader_parameter("heightmap", heightmap_texture)
	
	# Preserve existing parameters
	var existing_material: Material = terrain_mesh_instance.material_override
	if existing_material and existing_material is ShaderMaterial:
		var existing_shader_mat: ShaderMaterial = existing_material as ShaderMaterial
		if existing_shader_mat.get_shader_parameter("tint_color"):
			material.set_shader_parameter("tint_color", existing_shader_mat.get_shader_parameter("tint_color"))
		if existing_shader_mat.get_shader_parameter("invert_normals") != null:
			material.set_shader_parameter("invert_normals", existing_shader_mat.get_shader_parameter("invert_normals"))
	
	terrain_mesh_instance.material_override = material
	print("world_preview: Applied fallback topo shader")

func _apply_biome_textures(material: ShaderMaterial) -> void:
	"""Load and apply biome textures to shader material.
	
	Args:
		material: ShaderMaterial to apply textures to
	"""
	if not world_data:
		return
	
	# Load biome textures (up to 8 for splatting)
	var biome_names: Array[String] = BiomeTextureManager.get_all_biome_names()
	
	# Load first 8 biome textures
	for i in range(min(8, biome_names.size())):
		var biome_name: String = biome_names[i]
		var texture: Texture2D = BiomeTextureManager.get_texture(biome_name)
		if texture:
			material.set_shader_parameter("biome_texture_%d" % i, texture)
			
			# Load normal map if available
			var normal: Texture2D = BiomeTextureManager.get_normal_map(biome_name)
			if normal and i < 4:  # Only first 4 normal maps
				material.set_shader_parameter("biome_normal_%d" % i, normal)

func set_preview_mode(mode: int) -> void:
	"""Set preview mode (0=Network, 1=Topographic, 2=Biome, 3=Foliage, 4=Full Render).
	
	Args:
		mode: Preview mode index
	"""
	if not terrain_mesh_instance:
		return
	
	var material: Material = terrain_mesh_instance.material_override
	if material and material is ShaderMaterial:
		var shader_mat: ShaderMaterial = material as ShaderMaterial
		shader_mat.set_shader_parameter("preview_mode", mode)
		
		# Update world_data params
		if world_data:
			world_data.params["preview_mode"] = mode
		
		print("world_preview: Preview mode set to: ", mode)

func _generate_heightmap_texture(mesh: Mesh) -> ImageTexture:
	"""Generate heightmap texture from mesh vertex data."""
	if mesh.get_surface_count() == 0:
		return null
	
	var arrays: Array = mesh.surface_get_arrays(0)
	if arrays.size() <= Mesh.ARRAY_VERTEX:
		return null
	
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays.size() > Mesh.ARRAY_TEX_UV else PackedVector2Array()
	
	if vertices.size() == 0:
		return null
	
	# Find min/max height
	var min_height: float = vertices[0].y
	var max_height: float = vertices[0].y
	for vertex in vertices:
		if vertex.y < min_height:
			min_height = vertex.y
		if vertex.y > max_height:
			max_height = vertex.y
	
	var height_range: float = max_height - min_height
	if height_range == 0:
		height_range = 1.0
	
	# Create heightmap image (use UV coordinates if available, otherwise estimate size)
	var image_size: int = 512  # Default size
	if uvs.size() > 0:
		# Estimate size from UV coordinates
		var max_uv: float = 0.0
		for uv in uvs:
			max_uv = max(max_uv, max(uv.x, uv.y))
		if max_uv > 0:
			image_size = int(max_uv * 256) + 1
		image_size = clamp(image_size, 64, 1024)
	
	var heightmap_image: Image = Image.create(image_size, image_size, false, Image.FORMAT_RF)
	
	# Fill heightmap based on vertex positions
	# Simple approach: map vertex positions to image coordinates
	for i in range(vertices.size()):
		var vertex: Vector3 = vertices[i]
		var normalized_height: float = (vertex.y - min_height) / height_range
		
		# Map to image coordinates
		var img_x: int = 0
		var img_y: int = 0
		
		if uvs.size() > i:
			img_x = int(uvs[i].x * (image_size - 1))
			img_y = int(uvs[i].y * (image_size - 1))
		else:
			# Fallback: use vertex index to estimate position
			img_x = (i % image_size)
			img_y = (i / image_size) % image_size
		
		img_x = clamp(img_x, 0, image_size - 1)
		img_y = clamp(img_y, 0, image_size - 1)
		
		heightmap_image.set_pixel(img_x, img_y, Color(normalized_height, normalized_height, normalized_height, 1.0))
	
	# Create texture from image
	var texture: ImageTexture = ImageTexture.new()
	texture.set_image(heightmap_image)
	
	return texture

func auto_fit_camera() -> void:
	"""Auto-fit camera distance to mesh bounds for wide, flat terrain viewing."""
	if not terrain_mesh_instance or not terrain_mesh_instance.mesh:
		return
	
	var mesh: Mesh = terrain_mesh_instance.mesh
	if mesh.get_surface_count() == 0:
		return
	
	# Get mesh AABB directly from mesh (faster than calculating from vertices)
	var mesh_aabb: AABB = mesh.get_aabb()
	if mesh_aabb.size.x <= 0 or mesh_aabb.size.z <= 0:
		return
	
	# Calculate size - use horizontal dimensions (X/Z) for wide terrain
	var horizontal_size: float = max(mesh_aabb.size.x, mesh_aabb.size.z)
	var vertical_size: float = mesh_aabb.size.y
	
	# For perspective camera (default for network visualization)
	if camera and camera.projection == Camera3D.PROJECTION_PERSPECTIVE:
		# Calculate distance for perspective view with closer framing for detailed network view
		var fov_rad: float = deg_to_rad(camera.fov) if camera else deg_to_rad(60.0)
		var distance: float = (horizontal_size * 0.5) / tan(fov_rad * 0.5)
		camera_distance = distance * 1.2  # Closer zoom for detailed network view (reduced from 1.8)
		
		# Set camera position for dynamic angled view (looking down and forward)
		camera_yaw = 0.3  # Slight rotation for more dynamic perspective
		camera_pitch = -0.35  # Angled downward view for closer inspection
		_update_camera_position()
		
		# Set depth of field focus distance (mid-ground focus)
		var avg_height: float = mesh_aabb.position.y + (vertical_size * 0.5)
		# Note: DOF properties are set in scene file (WorldCreator.tscn)
		# DOF is configured with dof_blur_far_distance, dof_blur_far_transition, etc.
		
		# Make sure camera looks at terrain center
		camera.look_at(Vector3(0, avg_height, 0), Vector3.UP)
	else:
		# For orthographic camera (fallback)
		if camera:
			camera.size = horizontal_size * 1.3  # 30% padding to see edges
		var avg_height: float = mesh_aabb.position.y + (vertical_size * 0.5)
		var viewing_height: float = avg_height + horizontal_size * 0.3
		camera_distance = viewing_height
		camera_yaw = 0.0
		camera_pitch = -0.6
		_update_camera_position()
		if camera:
			camera.look_at(Vector3(0, avg_height, 0), Vector3.UP)
	
	print("world_preview: Camera auto-fitted - Horizontal size: ", horizontal_size, " | Distance: ", camera_distance, " | FOV: ", camera.fov if camera else "N/A")

func set_world_data(data) -> void:
	"""Set world data for biome overlay.
	
	Args:
		data: WorldData instance
	"""
	world_data = data
	
	# Phase 4: Connect to chunk_generated signal for incremental updates
	if world_data and world_data.has_signal("chunk_generated"):
		if world_data.chunk_generated.is_connected(_on_chunk_generated):
			world_data.chunk_generated.disconnect(_on_chunk_generated)
		world_data.chunk_generated.connect(_on_chunk_generated)
	
	# Phase 4: Queue threaded preview update
	queue_preview_update()

func _setup_preview_timer() -> void:
	"""Setup debounce timer for preview updates."""
	preview_timer = Timer.new()
	preview_timer.wait_time = 0.5
	preview_timer.one_shot = true
	preview_timer.timeout.connect(_on_preview_timer_timeout)
	add_child(preview_timer)

func queue_preview_update() -> void:
	"""Queue a preview update with debounce."""
	if not preview_timer:
		return
	if preview_timer.is_stopped():
		preview_timer.start()
	else:
		preview_timer.start()  # Restart timer

func _on_preview_timer_timeout() -> void:
	"""Trigger threaded preview generation after debounce."""
	if world_data and not is_generating_preview:
		update_preview_threaded()

func update_preview_threaded() -> void:
	"""Update preview using threaded generation (Phase 4).
	
	Generates a low-resolution preview in a separate thread to avoid UI freezes.
	"""
	if is_generating_preview:
		return
	
	if preview_thread and preview_thread.is_alive():
		# Thread already running, skip
		return
	
	is_generating_preview = true
	pending_world_data = world_data.duplicate() if world_data else null
	
	# Start fade-out animation
	if terrain_mesh_instance:
		var tween: Tween = create_tween()
		tween.tween_property(terrain_mesh_instance, "modulate:a", 0.3, 0.2)
	
	# Start threaded generation
	preview_thread = Thread.new()
	var error: Error = preview_thread.start(_generate_preview_threaded)
	if error != OK:
		push_error("world_preview: Failed to start preview thread: %d" % error)
		is_generating_preview = false
		pending_world_data = null

func _generate_preview_threaded() -> void:
	"""Generate preview in thread (Phase 4).
	
	Creates a scaled-down version of the world for fast preview.
	"""
	if not pending_world_data:
		call_deferred("_on_preview_generation_complete", null)
		return
	
	# Scale down for performance (1/10th resolution)
	var preview_data = pending_world_data.duplicate()
	
	# Scale down size preset (use smaller size for preview)
	var size_preset: int = preview_data.get("size_preset", 2)
	var preview_size_preset: int = max(0, size_preset - 2)  # Scale down by 2 levels
	
	# Create preview world data with scaled parameters
	var preview_params: Dictionary = preview_data.get("params", {}).duplicate()
	preview_params["preview_mode"] = true
	preview_params["chunk_size"] = 32  # Smaller chunks for preview
	
	# Generate preview size (scaled down)
	var preview_size: Vector2i = Vector2i(256, 256)  # Fixed low-res for preview
	match preview_size_preset:
		0: preview_size = Vector2i(64, 64)
		1: preview_size = Vector2i(128, 128)
		2: preview_size = Vector2i(256, 256)
		3: preview_size = Vector2i(256, 256)
		4: preview_size = Vector2i(256, 256)
	
	# Get generation parameters
	var seed_value: int = preview_data.get("seed", 12345)
	var frequency: float = preview_params.get("frequency", 0.01)
	var elevation_scale: float = preview_params.get("elevation_scale", 30.0)
	var domain_warp_strength: float = preview_params.get("domain_warp_strength", 0.0)
	var domain_warp_freq: float = preview_params.get("domain_warp_frequency", 0.005)
	var terrain_chaos: float = preview_params.get("terrain_chaos", 50.0)
	
	# Generate heightmap using CPU (thread-safe)
	var heightmap: Image = _generate_heightmap_cpu(preview_size, seed_value, frequency, elevation_scale, domain_warp_strength, domain_warp_freq, terrain_chaos)
	
	# Convert heightmap to mesh (simplified for preview)
	var preview_mesh: Mesh = _heightmap_to_mesh(heightmap)
	
	# Return mesh via call_deferred
	call_deferred("_on_preview_generation_complete", preview_mesh)

func _generate_heightmap_cpu_fallback(size: Vector2i, seed_value: int) -> Image:
	"""Fallback CPU heightmap generation if GPU fails."""
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.01
	noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5
	
	var img: Image = Image.create(size.x, size.y, false, Image.FORMAT_RF)
	for x in size.x:
		for y in size.y:
			var n: float = noise.get_noise_2d(x, y)
			n = (n + 1.0) * 0.5  # Normalize to 0-1
			img.set_pixel(x, y, Color(n, n, n, 1.0))
	
	return img

func _heightmap_to_mesh(heightmap: Image) -> Mesh:
	"""Convert heightmap image to mesh for preview."""
	if not heightmap:
		return null
	
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var size: Vector2i = heightmap.get_size()
	var scale: float = 10.0  # World scale
	var height_scale: float = 30.0
	
	# Center the mesh at origin
	var offset_x: float = -(size.x * scale) * 0.5
	var offset_z: float = -(size.y * scale) * 0.5
	
	# Generate vertices from heightmap
	for y in range(size.y - 1):
		for x in range(size.x - 1):
			# Get heights
			var h00: float = heightmap.get_pixel(x, y).r * height_scale
			var h10: float = heightmap.get_pixel(x + 1, y).r * height_scale
			var h01: float = heightmap.get_pixel(x, y + 1).r * height_scale
			var h11: float = heightmap.get_pixel(x + 1, y + 1).r * height_scale
			
			# Convert to world coordinates (centered)
			var v00: Vector3 = Vector3(offset_x + x * scale, h00, offset_z + y * scale)
			var v10: Vector3 = Vector3(offset_x + (x + 1) * scale, h10, offset_z + y * scale)
			var v01: Vector3 = Vector3(offset_x + x * scale, h01, offset_z + (y + 1) * scale)
			var v11: Vector3 = Vector3(offset_x + (x + 1) * scale, h11, offset_z + (y + 1) * scale)
			
			# Create two triangles per quad
			# Triangle 1: v00, v10, v01
			st.add_vertex(v00)
			st.add_vertex(v10)
			st.add_vertex(v01)
			
			# Triangle 2: v10, v11, v01
			st.add_vertex(v10)
			st.add_vertex(v11)
			st.add_vertex(v01)
	
	st.generate_normals()
	st.generate_tangents()
	return st.commit()

func _on_preview_generation_complete(preview_mesh: Mesh) -> void:
	"""Handle completion of threaded preview generation (Phase 4)."""
	is_generating_preview = false
	
	if preview_thread:
		preview_thread.wait_to_finish()
		preview_thread = null
	
	if preview_mesh and terrain_mesh_instance:
		# Update mesh
		update_mesh(preview_mesh)
		
		# Fade-in animation
		var tween: Tween = create_tween()
		tween.tween_property(terrain_mesh_instance, "modulate:a", 1.0, 0.5)
	
	pending_world_data = null

func toggle_biome_overlay(enabled: bool) -> void:
	"""Toggle biome overlay visibility."""
	biome_overlay_enabled = enabled
	biome_overlay.visible = enabled
	if enabled and terrain_mesh_instance.mesh:
		_update_biome_overlay(terrain_mesh_instance.mesh)

func _update_biome_overlay(base_mesh: Mesh) -> void:
	"""Update biome overlay mesh with color tint based on biomes."""
	if not world_data or not base_mesh:
		return
	
	# Create a duplicate mesh with biome colors
	var st: SurfaceTool = SurfaceTool.new()
	st.create_from(base_mesh, 0)
	
	# Apply biome colors to vertices
	var arrays: Array = base_mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = []
	colors.resize(vertices.size())
	
	# Map biome types to colors
	var _biome_colors: Dictionary = {
		"forest": Color(0.2, 0.6, 0.2, 0.5),
		"desert": Color(0.9, 0.8, 0.5, 0.5),
		"jungle": Color(0.1, 0.5, 0.1, 0.5),
		"tundra": Color(0.8, 0.9, 0.9, 0.5),
		"taiga": Color(0.4, 0.6, 0.5, 0.5),
		"mountain": Color(0.6, 0.6, 0.6, 0.5),
		"swamp": Color(0.3, 0.4, 0.2, 0.5),
		"grassland": Color(0.6, 0.7, 0.4, 0.5),
		"plains": Color(0.7, 0.7, 0.5, 0.5),
		"coast": Color(0.4, 0.6, 0.8, 0.5),
		"cold_desert": Color(0.7, 0.7, 0.6, 0.5)
	}
	
	# Assign colors based on biome metadata
	for i in range(vertices.size()):
		# Simple mapping - in a real implementation, you'd map vertex to biome cell
		colors[i] = Color(0.5, 0.5, 0.5, 0.3)  # Default gray
	
	# Apply colors and create overlay mesh
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var surface_arrays: Array = base_mesh.surface_get_arrays(0)
	if surface_arrays.size() > Mesh.ARRAY_VERTEX:
		var base_vertices: PackedVector3Array = surface_arrays[Mesh.ARRAY_VERTEX]
		var base_indices: PackedInt32Array = surface_arrays[Mesh.ARRAY_INDEX]
		
		for i in range(base_vertices.size()):
			st.set_color(colors[i] if i < colors.size() else Color(0.5, 0.5, 0.5, 0.3))
			st.add_vertex(base_vertices[i])
		
		for idx in base_indices:
			st.add_index(idx)
	
	st.generate_normals()
	biome_overlay.mesh = st.commit()
	
	# Set material with transparency
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 1, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	biome_overlay.material_override = material

func _setup_node_points() -> void:
	"""Create MultiMeshInstance3D nodes for cyan and orange node points."""
	if node_points_instance:
		return
	
	# Load node point mesh
	var node_mesh_path: String = "res://assets/meshes/node_point.tres"
	var node_mesh: QuadMesh = load(node_mesh_path)
	if not node_mesh:
		print("world_preview: WARNING - Node point mesh not found: ", node_mesh_path)
		# Create fallback quad mesh
		node_mesh = QuadMesh.new()
		node_mesh.size = Vector2(0.5, 0.5)
	
	# Create cyan nodes MultiMeshInstance3D
	node_points_instance = MultiMeshInstance3D.new()
	node_points_instance.name = "node_points_cyan"
	add_child(node_points_instance)
	
	var multimesh_cyan: MultiMesh = MultiMesh.new()
	multimesh_cyan.mesh = node_mesh
	multimesh_cyan.instance_count = 0
	multimesh_cyan.transform_format = MultiMesh.TRANSFORM_3D
	
	var material_cyan: StandardMaterial3D = StandardMaterial3D.new()
	material_cyan.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_cyan.albedo_color = Color(0.0, 0.8, 1.0, 1.0)  # Cyan
	material_cyan.emission_enabled = true
	material_cyan.emission = Color(0.0, 0.8, 1.0, 1.0) * 1.2
	material_cyan.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	
	node_points_instance.multimesh = multimesh_cyan
	node_points_instance.material_override = material_cyan
	
	# Create orange nodes MultiMeshInstance3D
	node_points_orange_instance = MultiMeshInstance3D.new()
	node_points_orange_instance.name = "node_points_orange"
	add_child(node_points_orange_instance)
	
	var multimesh_orange: MultiMesh = MultiMesh.new()
	multimesh_orange.mesh = node_mesh
	multimesh_orange.instance_count = 0
	multimesh_orange.transform_format = MultiMesh.TRANSFORM_3D
	
	var material_orange: StandardMaterial3D = StandardMaterial3D.new()
	material_orange.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_orange.albedo_color = Color(1.0, 0.6, 0.0, 1.0)  # Orange
	material_orange.emission_enabled = true
	material_orange.emission = Color(1.0, 0.6, 0.0, 1.0) * 1.2
	material_orange.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	
	node_points_orange_instance.multimesh = multimesh_orange
	node_points_orange_instance.material_override = material_orange
	
	print("world_preview: Node points instances created (cyan and orange)")

func _update_node_points(mesh: Mesh) -> void:
	"""Update node points positions based on mesh vertices."""
	if not node_points_instance or not node_points_instance.multimesh:
		return
	
	if mesh.get_surface_count() == 0:
		return
	
	var arrays: Array = mesh.surface_get_arrays(0)
	if arrays.size() <= Mesh.ARRAY_VERTEX:
		return
	
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if vertices.size() == 0:
		return
	
	# Separate vertices into cyan and orange groups
	var cyan_vertices: Array[Vector3] = []
	var orange_vertices: Array[Vector3] = []
	
	# Create random number generator for consistent randomness
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(vertices[0]) if vertices.size() > 0 else 0
	
	const ORANGE_PROBABILITY: float = 0.1  # 10% orange highlights
	
	# Separate vertices by color
	for vertex_pos in vertices:
		if rng.randf() < ORANGE_PROBABILITY:
			orange_vertices.append(vertex_pos)
		else:
			cyan_vertices.append(vertex_pos)
	
	# Update cyan nodes MultiMesh
	var multimesh_cyan: MultiMesh = node_points_instance.multimesh
	multimesh_cyan.instance_count = cyan_vertices.size()
	
	for i in range(cyan_vertices.size()):
		var vertex_pos: Vector3 = cyan_vertices[i]
		var pos_hash: int = hash(Vector2(vertex_pos.x, vertex_pos.z))
		var noise_value: float = float(pos_hash % 1000) / 1000.0
		var size_variation: float = 0.8 + (noise_value * 0.4)  # 0.8 to 1.2 scale
		var transform: Transform3D = Transform3D.IDENTITY
		transform.origin = vertex_pos
		transform = transform.scaled(Vector3(size_variation, size_variation, 1.0))
		multimesh_cyan.set_instance_transform(i, transform)
	
	# Update orange nodes MultiMesh
	var multimesh_orange: MultiMesh = node_points_orange_instance.multimesh
	multimesh_orange.instance_count = orange_vertices.size()
	
	for i in range(orange_vertices.size()):
		var vertex_pos: Vector3 = orange_vertices[i]
		var pos_hash: int = hash(Vector2(vertex_pos.x, vertex_pos.z))
		var noise_value: float = float(pos_hash % 1000) / 1000.0
		var size_variation: float = 0.8 + (noise_value * 0.4)  # 0.8 to 1.2 scale
		var transform: Transform3D = Transform3D.IDENTITY
		transform.origin = vertex_pos
		transform = transform.scaled(Vector3(size_variation, size_variation, 1.0))
		multimesh_orange.set_instance_transform(i, transform)
	
	print("world_preview: Updated ", cyan_vertices.size(), " cyan nodes and ", orange_vertices.size(), " orange nodes")
	
	# Phase 2: Update river visualization
	_update_river_visualization(mesh)
	
	# Phase 3: Update foliage and POI visualization
	_update_foliage_visualization(mesh)
	_update_poi_visualization(mesh)

func _update_river_visualization(mesh: Mesh) -> void:
	"""Update river visualization with blue points for river cells."""
	if not world_data or not mesh:
		return
	
	# Get river paths from world_data
	var river_paths: Array = []
	if world_data.has("river_paths"):
		river_paths = world_data.river_paths
	
	if river_paths.is_empty():
		# Remove river visualization if no rivers
		if river_points_instance:
			river_points_instance.queue_free()
			river_points_instance = null
		return
	
	# Create river points instance if it doesn't exist
	if not river_points_instance:
		river_points_instance = MultiMeshInstance3D.new()
		add_child(river_points_instance)
		
		var multimesh: MultiMesh = MultiMesh.new()
		multimesh.mesh = _create_river_point_mesh()
		multimesh.instance_count = 0
		river_points_instance.multimesh = multimesh
		
		# Create blue material for rivers
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(0.2, 0.5, 1.0, 1.0)  # Blue
		material.emission_enabled = true
		material.emission = Color(0.2, 0.5, 1.0, 1.0) * 1.5
		material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		river_points_instance.material_override = material
	
	# Get mesh vertices to map river paths to 3D positions
	var arrays: Array = mesh.surface_get_arrays(0)
	if arrays.size() <= Mesh.ARRAY_VERTEX:
		return
	
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if vertices.is_empty():
		return
	
	# Calculate vertex grid size (assume square grid)
	var grid_size: int = int(sqrt(vertices.size()))
	if grid_size * grid_size != vertices.size():
		# Not a perfect square, estimate
		grid_size = int(sqrt(vertices.size()))
	
	# Collect river point positions
	var river_positions: Array[Vector3] = []
	
	for river_path in river_paths:
		for point in river_path:
			if point.x < 0 or point.x >= grid_size or point.y < 0 or point.y >= grid_size:
				continue
			
			# Map grid position to vertex index (row-major: y * grid_size + x)
			var vertex_idx: int = point.y * grid_size + point.x
			if vertex_idx >= 0 and vertex_idx < vertices.size():
				river_positions.append(vertices[vertex_idx])
	
	# Update MultiMesh
	var multimesh: MultiMesh = river_points_instance.multimesh
	multimesh.instance_count = river_positions.size()
	
	for i in range(river_positions.size()):
		var pos: Vector3 = river_positions[i]
		var transform: Transform3D = Transform3D.IDENTITY
		transform.origin = pos
		transform = transform.scaled(Vector3(1.2, 1.2, 1.0))  # Slightly larger than regular nodes
		multimesh.set_instance_transform(i, transform)
	
	if river_positions.size() > 0:
		print("world_preview: Updated ", river_positions.size(), " river points")

func _create_river_point_mesh() -> QuadMesh:
	"""Create a simple quad mesh for river point visualization."""
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)  # Slightly larger than regular nodes
	return quad

func _update_foliage_visualization(mesh: Mesh) -> void:
	"""Update foliage visualization with green points based on foliage density."""
	if not world_data or not mesh:
		return
	
	# Get foliage density from world_data
	var foliage_density: Array = []
	if world_data.has("foliage_density"):
		foliage_density = world_data.foliage_density
	
	if foliage_density.is_empty():
		# Remove foliage visualization if no data
		if foliage_points_instance:
			foliage_points_instance.queue_free()
			foliage_points_instance = null
		return
	
	# Check if foliage is enabled
	var enable_foliage: bool = world_data.params.get("enable_foliage", true)
	if not enable_foliage:
		if foliage_points_instance:
			foliage_points_instance.queue_free()
			foliage_points_instance = null
		return
	
	# Get mesh vertices
	var arrays: Array = mesh.surface_get_arrays(0)
	if arrays.size() <= Mesh.ARRAY_VERTEX:
		return
	
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if vertices.is_empty():
		return
	
	# Calculate vertex grid size
	var grid_size: int = int(sqrt(vertices.size()))
	if grid_size * grid_size != vertices.size():
		grid_size = int(sqrt(vertices.size()))
	
	# Collect foliage positions (only show points where density > threshold)
	var foliage_positions: Array[Vector3] = []
	var density_threshold: float = 0.2  # Only show foliage above 20% density
	
	for i in range(min(foliage_density.size(), vertices.size())):
		var density: float = foliage_density[i]
		if density > density_threshold:
			# Probability based on density (higher density = more likely to show)
			var rng: RandomNumberGenerator = RandomNumberGenerator.new()
			rng.seed = hash(Vector2(i % grid_size, i / grid_size)) + world_data.seed
			if rng.randf() < density:
				foliage_positions.append(vertices[i])
	
	# Create foliage points instance if it doesn't exist
	if not foliage_points_instance and foliage_positions.size() > 0:
		foliage_points_instance = MultiMeshInstance3D.new()
		add_child(foliage_points_instance)
		
		var multimesh: MultiMesh = MultiMesh.new()
		multimesh.mesh = _create_foliage_point_mesh()
		multimesh.instance_count = 0
		foliage_points_instance.multimesh = multimesh
		
		# Create green material for foliage
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(0.2, 0.8, 0.3, 1.0)  # Green
		material.emission_enabled = true
		material.emission = Color(0.2, 0.8, 0.3, 1.0) * 1.2
		material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		foliage_points_instance.material_override = material
	
	# Update MultiMesh
	if foliage_points_instance:
		var multimesh: MultiMesh = foliage_points_instance.multimesh
		multimesh.instance_count = foliage_positions.size()
		
		for i in range(foliage_positions.size()):
			var pos: Vector3 = foliage_positions[i]
			var transform: Transform3D = Transform3D.IDENTITY
			transform.origin = pos
			transform = transform.scaled(Vector3(0.8, 0.8, 1.0))  # Smaller than rivers
			multimesh.set_instance_transform(i, transform)
		
		if foliage_positions.size() > 0:
			print("world_preview: Updated ", foliage_positions.size(), " foliage points")

func _create_foliage_point_mesh() -> QuadMesh:
	"""Create a simple quad mesh for foliage point visualization."""
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(1.5, 1.5)  # Smaller than rivers
	return quad

func _update_poi_visualization(mesh: Mesh) -> void:
	"""Update POI visualization with colored markers per type."""
	if not world_data or not mesh:
		return
	
	# Get POI metadata from world_data
	var poi_metadata: Array = []
	if world_data.has("poi_metadata"):
		poi_metadata = world_data.poi_metadata
	
	if poi_metadata.is_empty():
		# Remove POI visualization if no POIs
		if poi_points_instance:
			poi_points_instance.queue_free()
			poi_points_instance = null
		return
	
	# Create POI points instance if it doesn't exist
	if not poi_points_instance:
		poi_points_instance = MultiMeshInstance3D.new()
		add_child(poi_points_instance)
		
		var multimesh: MultiMesh = MultiMesh.new()
		multimesh.mesh = _create_poi_point_mesh()
		multimesh.instance_count = 0
		poi_points_instance.multimesh = multimesh
		
		# Material will be set per-instance via color array (or use default)
		var poi_material: StandardMaterial3D = StandardMaterial3D.new()
		poi_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		poi_material.albedo_color = Color.WHITE  # Default, will vary by type
		poi_material.emission_enabled = true
		poi_material.emission = Color.WHITE * 1.5
		poi_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		poi_points_instance.material_override = poi_material
	
	# Update MultiMesh with POI positions
	var multimesh: MultiMesh = poi_points_instance.multimesh
	multimesh.instance_count = poi_metadata.size()
	
	# Create materials per POI type (simplified: use one instance per type)
	var poi_colors: Dictionary = {
		"city": Color(1.0, 0.8, 0.0, 1.0),      # Gold
		"town": Color(0.8, 0.8, 0.8, 1.0),      # Silver/Gray
		"ruin": Color(0.8, 0.2, 0.2, 1.0),     # Red
		"resource": Color(0.2, 0.8, 1.0, 1.0)  # Cyan
	}
	
	for i in range(poi_metadata.size()):
		var poi: Dictionary = poi_metadata[i]
		var position: Vector3 = poi.get("position", Vector3.ZERO)
		var poi_type: String = poi.get("type", "town")
		
		var transform: Transform3D = Transform3D.IDENTITY
		transform.origin = position
		transform = transform.scaled(Vector3(2.0, 2.0, 1.0))  # Larger than foliage
		multimesh.set_instance_transform(i, transform)
	
	# Update material color based on first POI type (simplified visualization)
	if poi_metadata.size() > 0:
		var first_poi: Dictionary = poi_metadata[0]
		var first_type: String = first_poi.get("type", "town")
		var color: Color = poi_colors.get(first_type, Color.WHITE)
		var poi_mat: StandardMaterial3D = poi_points_instance.material_override as StandardMaterial3D
		if poi_mat:
			poi_mat.albedo_color = color
			poi_mat.emission = color * 1.5
		
		print("world_preview: Updated ", poi_metadata.size(), " POI markers")

func _create_poi_point_mesh() -> QuadMesh:
	"""Create a simple quad mesh for POI point visualization."""
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(3.0, 3.0)  # Larger than foliage and rivers
	return quad

# Phase 4: LOD & Chunk Management

func _setup_chunks_container() -> void:
	"""Create container node for chunk meshes."""
	if chunks_container:
		return
	
	chunks_container = Node3D.new()
	chunks_container.name = "ChunksContainer"
	add_child(chunks_container)
	print("world_preview: Chunks container created")

func _on_chunk_generated(chunk_x: int, chunk_y: int, mesh: Mesh) -> void:
	"""Handle chunk generation signal for incremental preview updates.
	
	Args:
		chunk_x: Chunk X coordinate
		chunk_y: Chunk Y coordinate
		mesh: Generated chunk mesh
	"""
	if not chunks_container:
		_setup_chunks_container()
	
	var chunk_key: String = LODManager.create_chunk_key(chunk_x, chunk_y)
	
	# Create or update chunk mesh instance
	var chunk_node: MeshInstance3D = null
	if chunk_nodes.has(chunk_key):
		chunk_node = chunk_nodes[chunk_key]
	else:
		chunk_node = MeshInstance3D.new()
		chunk_node.name = "Chunk_%d_%d" % [chunk_x, chunk_y]
		chunks_container.add_child(chunk_node)
		chunk_nodes[chunk_key] = chunk_node
		
		# Phase 5: Apply shader to chunk (use same shader as main terrain)
		_apply_shader_to_chunk(chunk_node, mesh)
	
	chunk_node.mesh = mesh
	
	# Update LOD if needed
	_update_lod()

func _apply_shader_to_chunk(chunk_node: MeshInstance3D, mesh: Mesh) -> void:
	"""Apply shader material to chunk mesh (Phase 5: uses same shader as main terrain).
	
	Args:
		chunk_node: Chunk mesh instance
		mesh: Chunk mesh
	"""
	# Copy material from main terrain if available
	if terrain_mesh_instance and terrain_mesh_instance.material_override:
		var main_material: Material = terrain_mesh_instance.material_override
		if main_material is ShaderMaterial:
			# Duplicate material for chunk
			var chunk_material: ShaderMaterial = main_material.duplicate() as ShaderMaterial
			
			# Generate heightmap for chunk
			var heightmap_texture: ImageTexture = _generate_heightmap_texture(mesh)
			if heightmap_texture:
				chunk_material.set_shader_parameter("heightmap", heightmap_texture)
			
			chunk_node.material_override = chunk_material
			return
	
	# Fallback: Create basic material
	var fallback_material: StandardMaterial3D = StandardMaterial3D.new()
	fallback_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fallback_material.albedo_color = Color(0.2, 0.5, 1.0, 1.0)
	chunk_node.material_override = fallback_material

func _update_lod() -> void:
	"""Update LOD levels for all chunks based on camera distance."""
	if not world_data or not camera:
		return
	
	var enable_lod: bool = world_data.params.get("enable_lod", true)
	if not enable_lod:
		return
	
	var lod_distances_raw = world_data.params.get("lod_distances", [500.0, 2000.0])
	var lod_distances: Array[float] = []
	if lod_distances_raw is Array:
		for dist in lod_distances_raw:
			if dist is float:
				lod_distances.append(dist)
		if lod_distances.is_empty():
			lod_distances = [500.0, 2000.0]  # Fallback to defaults
	else:
		lod_distances = [500.0, 2000.0]  # Fallback to defaults
	var camera_pos: Vector3 = camera.global_position
	
	# Update LOD for each chunk
	for chunk_key in chunk_nodes.keys():
		var chunk_node: MeshInstance3D = chunk_nodes[chunk_key]
		if not chunk_node or not chunk_node.mesh:
			continue
		
		# Calculate distance from camera to chunk center
		var chunk_center: Vector3 = chunk_node.global_position
		var distance: float = camera_pos.distance_to(chunk_center)
		
		# Get appropriate LOD level (stored but not used yet - full LOD switching requires regenerating chunks)
		var _lod_level: int = LODManager.get_lod_for_distance(distance, lod_distances)
		
		# For now, just show/hide chunks based on distance (full LOD switching requires regenerating chunks)
		# In a full implementation, we would switch to pre-generated LOD meshes
		var max_distance: float = lod_distances.back() if lod_distances.size() > 0 else 2000.0
		if distance > max_distance:
			chunk_node.visible = false  # Hide very far chunks
		else:
			chunk_node.visible = true

func _process(_delta: float) -> void:
	"""Update LOD based on camera movement."""
	if world_data and world_data.params.get("enable_lod", true):
		_update_lod()

