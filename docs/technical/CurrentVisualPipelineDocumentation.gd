# ╔═══════════════════════════════════════════════════════════
# ║ CurrentVisualPipelineDocumentation.gd
# ║ Desc: Complete technical documentation of current visual rendering pipeline
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
# ═══════════════════════════════════════════════════════════
# TECHNICAL DOCUMENTATION: Current Visual Pipeline
# ═══════════════════════════════════════════════════════════
#
# This class serves as the single source of truth for documenting
# HOW the current visual style is achieved in-engine.
#
# Last Updated: 2025-12-07 (Added shape preset mask documentation, preview mode system, biome overlay, river/foliage/POI visualization, LOD/chunk system, biome texture manager, progress popup)
# 
# Current Visual Style:
# - Glowing blue network of wavy lines connecting mesh vertices
# - Cyan-blue line colors with deep blue base
# - Orange highlights on node points (~10% of vertices)
# - Strong emission glow (bloom) for network effect
# - Node points at vertices using MultiMeshInstance3D
# - Black background with subtle fog
# - Perspective camera with depth of field (bokeh blur)
# - Character preview with 3D models, morph targets, and orbit camera
# - Multiple preview modes (Network, Topographic, Biome Color, Foliage Density, Full Render)
# - Biome overlay system with semi-transparent colors
# - River, foliage, and POI visualization systems
# - LOD and chunk-based rendering for large terrains
# - Biome texture manager for texture splatting
# - Progress popup during world mesh generation
#
# ═══════════════════════════════════════════════════════════

class_name CurrentVisualPipelineDocumentation
extends RefCounted

## ═══════════════════════════════════════════════════════════
## SECTION 1: BASE WORLD MESH GENERATION
## ═══════════════════════════════════════════════════════════
#
# The terrain mesh is generated procedurally via SurfaceTool using
# FastNoiseLite noise functions.
#
# Location: scripts/world.gd
# Function: _generate_threaded() (lines ~54-241)
#
# Generation Pipeline:
#
# 1. FastNoiseLite Setup:
#    - Noise seed from world.seed (default: 0)
#    - Noise type from params["noise_type"] (default: "Perlin")
#    - Frequency from params["frequency"] (default: 0.01)
#    - Optional fractal settings (octaves, lacunarity, gain)
#
# 2. Heightmap Generation:
#    - Noise sampled into Image via noise.get_image(width, height)
#    - Image converted to height array (normalized -1 to 1, then scaled)
#    - Height calculation: noise_value * elevation_scale * chaos_multiplier
#    - Elevation scale clamped: 10.0 - 50.0 (default: 30.0)
#    - Height clamped to range: [-elevation_scale * 1.5, elevation_scale * 1.5]
#
# 2a. Shape Preset Mask Application (if shape_preset != "Square"):
#    - Location: scripts/world.gd, _apply_shape_mask()
#    - Applied after base heightmap generation, before erosion/rivers
#    - Loads mask configuration from res://assets/presets/shape_presets.json
#    - Mask types create organic, non-rectangular boundaries:
#      * "radial": Single central falloff (Continent shape)
#      * "multi_radial": Multiple random centers (Island Chain shape)
#      * "linear": Edge-to-edge gradient (Coastline shape)
#      * "inverted_radial": Depressions/valleys (Trench shape)
#    - Visual effect: Heights fade to sea level (0.0) at mask edges
#    - Low mask values (< 0.1) clamp height to sea level, creating visible boundaries
#    - Mask centers use seed-based RNG (seed + 5000/6000) for consistent placement
#    - Result: Mesh vertices at edges have Y=0.0, creating organic map boundaries
#    - Visible in preview: Network lines fade out at edges, node points disappear
#    - Affects biome assignment: Low heights at edges become "coast" or "swamp" biomes
#
# 3. Vertex Grid Generation:
#    - Grid resolution: vert_grid_size = world_size * VERTS_PER_UNIT
#    - VERTS_PER_UNIT constant: 8 (8 vertices per world unit, increased for finer grid)
#    - Horizontal spacing: HORIZONTAL_SCALE = 4.0 world units between vertices
#    - Vertex positions: X/Z from grid * horizontal_scale, Y from heightmap (after mask application)
#    - UV coordinates: Normalized 0-1 range based on grid position
#    - Note: Shape preset masks modify heightmap Y values, creating visible boundary effects
#      in the final mesh (edges fade to sea level, creating organic map shapes)
#
# 4. Line Network Mesh Creation:
#    - SurfaceTool.begin(Mesh.PRIMITIVE_LINES)
#    - Vertices added with UV coordinates via st.set_uv() and st.add_vertex()
#    - Lines generated for dense triangular network:
#      * Horizontal lines: Connect vertices along X axis (for each row)
#      * Vertical lines: Connect vertices along Y axis (for each column)
#      * Diagonal lines: Both diagonals per quad (top-left to bottom-right, top-right to bottom-left)
#      * Creates triangular mesh pattern for denser, more connected network
#    - VERTS_PER_UNIT: 8 (increased from 4 for finer grid density)
#    - No normals generated (not needed for line rendering)
#    - Final mesh: ArrayMesh from st.commit()
#    - Vertex positions stored for node point generation
#
# Key Constants:
#   - VERTS_PER_UNIT: int = 8 (increased for finer grid)
#   - HORIZONTAL_SCALE: float = 4.0
#   - DEFAULT_ELEVATION_SCALE: float = 30.0
#
# Resource Path: scripts/world.gd

## ═══════════════════════════════════════════════════════════
## SECTION 2: MATERIAL AND SHADER APPLICATION
## ═══════════════════════════════════════════════════════════
#
# The terrain mesh uses a ShaderMaterial with custom spatial shaders.
# The system supports multiple shaders with fallback logic.
#
# Application Location: scripts/preview/world_preview.gd
# Functions: _apply_world_shader(), _apply_topo_shader_fallback()
#
# Material Loading Pipeline:
#
# 1. Primary Shader (world_preview.gdshader):
#    - Path: "res://assets/shaders/world_preview.gdshader"
#    - Used when splatmap_texture is available in world_data
#    - Supports multiple preview modes (Network, Topographic, Biome Color, Foliage Density, Full Render)
#    - Includes texture splatting, normal mapping, parallax mapping
#    - Falls back to topo_preview.gdshader if splatmap missing
#
# 2. Fallback Shader (topo_preview.gdshader):
#    - Path: "res://assets/shaders/topo_preview.gdshader"
#    - Used when world_preview shader cannot be applied
#    - Network-style rendering with wavy lines
#    - Creates new ShaderMaterial and assigns shader
#
# 3. Heightmap Texture Generation:
#    - Function: _generate_heightmap_texture() (lines ~145-213)
#    - Extracts vertex heights from mesh
#    - Normalizes heights to 0-1 range
#    - Creates Image (512x512 default, or based on UV range)
#    - Maps vertex heights to image pixels based on UV coordinates
#    - Creates ImageTexture and assigns to shader parameter "heightmap"
#
# 4. Material Assignment:
#    - Applied via terrain_mesh_instance.material_override = material
#    - MeshInstance3D node: "terrain_mesh" (in WorldPreviewRoot)
#
# Resource Paths:
#   - Primary Shader: res://assets/shaders/world_preview.gdshader
#   - Fallback Shader: res://assets/shaders/topo_preview.gdshader
#   - Optional Material: res://assets/materials/topo_preview_shader.tres

## ═══════════════════════════════════════════════════════════
## SECTION 3: SHADER IMPLEMENTATIONS
## ═══════════════════════════════════════════════════════════
#
# The project uses three main shaders for world preview rendering:
#
# ────────────────────────────────────────────────────────────
# 3.1: topo_preview.gdshader (Network Style)
# ────────────────────────────────────────────────────────────
#
# Render Mode: unshaded, cull_disabled, depth_draw_never
#
# Uniforms:
#   - sampler2D heightmap: Height data texture
#   - float scale_y = 20.0: Vertical displacement scale
#   - float emission_intensity = 1.2: Base emission multiplier
#   - float noise_scale = 0.15: Noise frequency for waviness
#   - float noise_strength = 0.08: Wavy displacement strength
#   - float line_thickness = 0.5: Simulated line thickness
#   - float time_scale = 0.5: Animation speed for TIME-based effects
#   - vec3 tint_color = vec3(0.4, 0.8, 1.0): Color tint multiplier
#   - bool invert_normals = false: Nightmare mode toggle
#
# Color Constants:
#   - DEEP_BLUE: vec3(0.0, 0.1, 0.4) - Base network line color
#   - CYAN_EDGE: vec3(0.0, 0.8, 1.0) - Bright cyan edge glow
#   - ORANGE_HIGHLIGHT: vec3(1.0, 0.5, 0.0) - Orange accent color
#
# Vertex Shader:
#   - Applies height displacement: VERTEX.y += heightmap.r * scale_y
#   - Adds organic wavy variation using multi-octave FBM noise
#   - Noise uses TIME for animated movement
#   - Displacement: XZ += noise_offset * noise_strength
#   - Creates flowing, natural network appearance
#
# Fragment Shader:
#   - Base color: DEEP_BLUE for network lines
#   - Simulates line thickness using screen-space derivatives
#   - Adds cyan edge glow based on height variation
#   - Noise-based color variation for wavy appearance
#   - Height-based intensity (cyan for higher areas)
#   - Orange highlights: ~15% chance via noise-based selection
#   - Emission: emission_intensity * (1.0 + thickness_factor * 0.5)
#   - Final emission can reach 180% intensity with thickness falloff
#   - Applies tint_color multiplier
#   - Optional normal inversion for Dark Fantasy style
#
# Resource Path: res://assets/shaders/topo_preview.gdshader
#
# ────────────────────────────────────────────────────────────
# 3.2: world_preview.gdshader (Multi-Mode Shader)
# ────────────────────────────────────────────────────────────
#
# Render Mode: cull_disabled, depth_draw_opaque
#
# Preview Modes (preview_mode uniform):
#   0 = Network (wireframe style with wavy lines)
#   1 = Topographic (contour lines)
#   2 = Biome Color (texture splatting)
#   3 = Foliage Density (green gradient)
#   4 = Full Render (texture splatting + lighting)
#
# Uniforms:
#   - int preview_mode = 0: Current rendering mode
#   - sampler2D heightmap: Height data
#   - sampler2D splatmap: Biome splatting weights (RGBA = 4 channels)
#   - sampler2D normal_map: Optional normal map
#   - sampler2D biome_texture_0-7: Up to 8 biome textures
#   - sampler2D biome_normal_0-3: Normal maps for biomes
#   - sampler2D foliage_density_map: Foliage density data
#   - sampler2D river_map: River path data
#   - float scale_y = 20.0: Height displacement scale
#   - float emission_intensity = 1.2: Emission multiplier
#   - float parallax_scale = 0.02: Parallax mapping strength
#   - float normal_strength = 1.0: Normal map influence
#   - vec3 tint_color = vec3(1.0, 1.0, 1.0): Color tint
#   - bool use_texture_splatting = true: Enable texture blending
#   - bool use_normal_mapping = true: Enable normal maps
#   - bool use_parallax = false: Enable parallax mapping
#
# Network Mode (preview_mode = 0):
#   - Same wavy network style as topo_preview.gdshader
#   - Deep blue base with cyan edges
#   - Orange highlights via noise
#   - Enhanced emission with thickness falloff
#
# Topographic Mode (preview_mode = 1):
#   - Height-based color gradient (blue → brown → gray)
#   - Contour lines at regular intervals (contour_spacing)
#   - Contour width controlled by contour_width uniform
#   - Calculated via: mod(h, contour_spacing) and smoothstep()
#
# Biome Color Mode (preview_mode = 2):
#   - Texture splatting using splatmap weights
#   - Blends up to 4 biome textures (RGBA channels)
#   - Optional normal map blending
#   - River overlay using river_map texture
#   - River color: vec3(0.2, 0.5, 1.0)
#
# Foliage Density Mode (preview_mode = 3):
#   - Green gradient based on foliage_density_map
#   - Dark gray (0.2, 0.2, 0.2) to bright green (0.1, 0.6, 0.2)
#
# Full Render Mode (preview_mode = 4):
#   - Same texture splatting as Biome Color mode
#   - Adds height-based emission for "magic areas" (h > 0.7)
#   - Magic emission: smoothstep(0.7, 1.0, h) * 0.3
#   - Full lighting support (not unshaded)
#
# Vertex Shader:
#   - Height displacement: VERTEX.y += h * scale_y
#   - Network mode: Adds wavy variation (same as topo_preview)
#   - Other modes: No wavy displacement
#
# Fragment Shader:
#   - Mode-specific color calculations
#   - Normal calculation from heightmap or blended normals
#   - Parallax offset mapping (if enabled)
#   - Final tint color application
#   - Emission set based on mode
#
# Resource Path: res://assets/shaders/world_preview.gdshader
#
# ────────────────────────────────────────────────────────────
# 3.3: topo_hologram_final.gdshader (Holographic Style)
# ────────────────────────────────────────────────────────────
#
# Render Mode: unshaded, depth_draw_never, cull_back, blend_add
#
# Uniforms:
#   - sampler2D heightmap: Height data
#   - float global_time: Animation time (0.0-1000.0)
#   - float glow_intensity = 4.5: Emission multiplier (0.0-10.0)
#
# Visual Features:
#   - Thick, bright cyan contour lines (vec3(0.0, 1.8, 2.5))
#   - Dense holographic wireframe grid
#   - Pulsing rivers in valleys (animated with sin())
#   - City lights / settlement clusters (procedural noise)
#   - Additive blending for intense glow effect
#
# Vertex Shader:
#   - Height displacement: VERTEX.y += v_height * 35.0
#   - Stores height in varying for fragment shader
#
# Fragment Shader:
#   - Contour lines: abs(fract(h * 22.0 + 0.5) - 0.5) * 2.0
#   - Wireframe: abs(fract(UV * 120.0) - 0.5) / fwidth()
#   - Rivers: smoothstep() mask with pulsing sin() animation
#   - City lights: Procedural noise with high power (pow(noise, 9.0))
#   - Final glow: contours + wires + rivers + lights
#   - EMISSION: final_glow * glow_intensity
#   - ALPHA: dot(final_glow, vec3(0.33)) * 0.8
#
# Resource Path: res://assets/shaders/topo_hologram_final.gdshader
#
# ────────────────────────────────────────────────────────────
# 3.4: blue_glow.gdshader (Simple Glow Effect)
# ────────────────────────────────────────────────────────────
#
# Location: res://shaders/blue_glow.gdshader
# Simple blue glow shader for UI elements or special effects
# (Less commonly used in main pipeline)

## ═══════════════════════════════════════════════════════════
## SECTION 4: NODE POINTS SYSTEM (MultiMeshInstance3D)
## ═══════════════════════════════════════════════════════════
#
# Node points are rendered using MultiMeshInstance3D for efficient
# instanced rendering of thousands of billboard sprites.
#
# Location: scripts/preview/world_preview.gd
# Functions: _setup_node_points(), _update_node_points()
#
# Setup Pipeline:
#
# 1. Mesh Loading:
#    - Path: "res://assets/meshes/node_point.tres"
#    - Type: QuadMesh (billboard sprite)
#    - Base size: 0.5x0.5 world units
#    - Fallback: Creates QuadMesh if resource not found
#
# 2. Cyan Nodes Instance:
#    - MultiMeshInstance3D node: "node_points_cyan"
#    - Material: StandardMaterial3D (unshaded)
#    - Albedo: Color(0.0, 0.8, 1.0) - Cyan
#    - Emission: Color(0.0, 0.8, 1.0) * 1.2 - Enhanced glow
#    - Billboard mode: BILLBOARD_ENABLED (always face camera)
#    - Transform format: TRANSFORM_3D (full 3D transforms)
#
# 3. Orange Nodes Instance:
#    - MultiMeshInstance3D node: "node_points_orange"
#    - Material: StandardMaterial3D (unshaded)
#    - Albedo: Color(1.0, 0.6, 0.0) - Orange
#    - Emission: Color(1.0, 0.6, 0.0) * 1.2 - Enhanced glow
#    - Billboard mode: BILLBOARD_ENABLED
#    - Transform format: TRANSFORM_3D
#
# Update Pipeline (_update_node_points):
#
# 1. Vertex Extraction:
#    - Reads vertices from mesh surface arrays
#    - Separates into cyan (90%) and orange (10%) groups
#    - Uses RandomNumberGenerator with seed from first vertex
#    - ORANGE_PROBABILITY: 0.1 (10% chance per vertex)
#
# 2. Transform Generation:
#    - Position: Vertex position (transform.origin)
#    - Size variation: 0.8 to 1.2 scale based on position hash
#    - Hash calculation: hash(Vector2(vertex_pos.x, vertex_pos.z))
#    - Scale: Vector3(size_variation, size_variation, 1.0)
#    - Creates organic size variation for visual interest
#
# 3. MultiMesh Update:
#    - Sets instance_count to vertex array size
#    - Calls set_instance_transform() for each vertex
#    - Separate MultiMesh instances for cyan and orange
#    - Efficient GPU instancing for thousands of points
#
# Additional Node Point Types:
#
# - River Points: Green MultiMeshInstance3D for river visualization
#   - Color: Color(0.2, 0.8, 0.3) - Green
#   - Size: 1.0x1.0 world units
#   - Created in _update_river_visualization()
#
# - Foliage Points: Green MultiMeshInstance3D for foliage density
#   - Color: Color(0.2, 0.8, 0.3) - Green
#   - Size: 0.8x0.8 world units (smaller than rivers)
#   - Created in _update_foliage_visualization()
#
# - POI Points: Colored markers for Points of Interest
#   - Colors vary by type:
#     * City: Color(1.0, 0.8, 0.0) - Gold
#     * Town: Color(0.8, 0.8, 0.8) - Silver/Gray
#     * Ruin: Color(0.8, 0.2, 0.2) - Red
#     * Resource: Color(0.2, 0.8, 1.0) - Cyan
#   - Created in _update_poi_visualization()
#
# Resource Paths:
#   - Node mesh: res://assets/meshes/node_point.tres
#   - Setup code: scripts/preview/world_preview.gd

## ═══════════════════════════════════════════════════════════
## SECTION 5: CHARACTER PREVIEW PIPELINE
## ═══════════════════════════════════════════════════════════
#
# The character preview system renders 3D character models
# in a SubViewport with real-time morphing and camera controls.
#
# Location: scripts/character/CharacterPreview3D.gd
# Scene: scenes/character/CharacterPreview3D.tscn
#
# Viewport Setup:
#   - Type: SubViewport
#   - Size: Vector2(800, 1000) pixels
#   - transparent_bg: true (allows UI integration)
#   - Script: CharacterPreview3D.gd
#
# Scene Structure:
#   - WorldEnvironment: Environment settings
#   - DirectionalLight3D: Scene lighting
#   - PreviewCamera: Camera3D with CharacterPreviewCamera script
#   - CharacterRoot: Node3D container for character model
#     - CharacterSkeleton: Skeleton3D (Rigify rig)
#       - BodyMesh: MeshInstance3D (body geometry)
#       - HairMesh: MeshInstance3D (hair geometry)
#       - HornsMesh: MeshInstance3D (race-specific features)
#
# Model Loading:
#
# 1. Path Resolution:
#    - Primary: "res://assets/models/character_bases/{race}-body-{gender}.glb"
#    - Fallback: "res://assets/models/character_bases/{race}-body-{gender}.tscn"
#    - Tries GLB first, falls back to TSCN if not found
#
# 2. Model Instantiation:
#    - Loads PackedScene from resolved path
#    - Instantiates scene as child of CharacterRoot
#    - Clears old model children before loading new
#    - Updates skeleton and mesh references
#
# 3. Skeleton Discovery:
#    - Recursively searches for Skeleton3D node
#    - Handles Rigify naming conventions
#    - Stores reference in skeleton variable
#    - Logs bone count for debugging
#
# 4. Mesh Discovery:
#    - Recursively searches for MeshInstance3D nodes
#    - Skips Rigify widget/deform helpers (WGT/DEF in name)
#    - Stores body mesh reference
#
# 5. Placeholder Fallback:
#    - Creates CapsuleMesh if model not found
#    - Size: radius 0.3, height 1.6
#    - Material: StandardMaterial3D with skin tone Color(0.8, 0.7, 0.6)
#    - Used for testing when models unavailable
#
# Morph Target System:
#
# The apply_slider() function applies real-time morphing via:
#   - Bone scaling (Skeleton3D.set_bone_pose_scale())
#   - Mesh scaling (MeshInstance3D.scale)
#   - Character root scaling (Node3D.scale)
#
# Supported Sliders:
#   - height: Character root scale (0.9-1.1)
#   - weight: Body mesh X scale (0.9-1.2)
#   - muscle: Body mesh XZ scale (1.0-1.15)
#   - head_size: Head bone scale (0.9-1.1)
#   - horn_length: Horns mesh scale (race-specific: tiefling)
#   - head_width/height/depth: Head bone scale per axis
#   - neck_length: Neck bone Y scale
#   - shoulder_width: Shoulder bone X scale
#   - chest_width: Body mesh X scale
#   - waist_width: Body mesh X scale
#   - hip_width: Body mesh X scale
#   - arm_length: Arm bone Y scale
#   - leg_length: Leg bone Y scale
#   - foot_size: Foot bone XZ scale
#   - Facial features: nose_size, eye_size, mouth_size, ear_size
#   - Facial structure: jaw_width, cheekbone_height, brow_height, etc.
#   - Race-specific: snout_length (dragonborn), ear_length (drow)
#
# Camera System:
#
# Location: scripts/ui/character_preview_camera.gd
# Class: CharacterPreviewCamera extends Camera3D
#
# Settings:
#   - target: Node3D (CharacterRoot)
#   - zoom_speed: 10.0
#   - orbit_speed: 120.0 degrees/second
#   - min_distance: 1.5
#   - max_distance: 5.0
#   - zoom_smoothing: 12.0
#   - orbit_smoothing: 10.0
#
# Initial Transform:
#   - Position: (0, 1.4, 2.2)
#   - Rotation: Pitch -10°, Yaw 0° (looking down slightly)
#   - Target: CharacterRoot at eye level (y=1.4)
#
# Controls:
#   - Mouse wheel: Zoom in/out (adjusts distance)
#   - Right mouse drag: Orbit around character (yaw rotation)
#   - W/S keys: Zoom in/out
#   - A/D keys: Orbit left/right
#   - Smooth interpolation for all movements
#
# Update Function:
#   - Calculates offset: Vector3(cos(yaw) * distance, 1.6, sin(yaw) * distance)
#   - Positions camera at target + offset
#   - Looks at target + Vector3(0, 1.4, 0) (eye level)
#   - Smoothly interpolates distance and yaw
#
# Animation Support:
#   - Searches for AnimationPlayer in character model
#   - Plays "idle" animation if available
#   - Animation must be in loaded GLB/TSCN file
#
# Resource Paths:
#   - Character preview script: scripts/character/CharacterPreview3D.gd
#   - Camera script: scripts/ui/character_preview_camera.gd
#   - Scene: scenes/character/CharacterPreview3D.tscn
#   - Models: res://assets/models/character_bases/

## ═══════════════════════════════════════════════════════════
## SECTION 6: WORLD PREVIEW CAMERA SYSTEM
## ═══════════════════════════════════════════════════════════
#
# The world preview uses a perspective camera with depth of field
# for cinematic bokeh blur effects.
#
# Location: scripts/preview/world_preview.gd
# Scene: scenes/WorldCreator.tscn
# Node: Camera3D (parent: WorldPreviewRoot)
#
# Initial Transform:
#   - Position: (0, 100, -200) in world space
#   - Rotation: Pitch 45°, Yaw 0° (angled downward)
#   - Looks at: Vector3.ZERO (terrain center)
#
# Projection Settings:
#   - projection: 0 (PROJECTION_PERSPECTIVE)
#   - fov: 60.0 degrees
#   - near: 0.1
#   - far: 10000.0
#
# Depth of Field (Bokeh Blur):
#   - dof_blur_far_enabled: true
#   - dof_blur_far_distance: 150.0 (focus distance)
#   - dof_blur_far_transition: 75.0 (blur falloff)
#   - dof_blur_far_amount: 1.0 (maximum blur strength)
#   - dof_blur_near_enabled: true
#   - dof_blur_near_distance: 50.0
#   - dof_blur_near_transition: 25.0
#   - dof_blur_near_amount: 0.3 (weaker near blur)
#   - Creates strong bokeh blur on foreground and background
#   - Keeps mid-ground network sharply focused
#
# Camera Controls:
#
# Variables:
#   - camera_distance: 500.0 (initial, range: 100.0-5000.0)
#   - camera_yaw: 0.3 (initial rotation)
#   - camera_pitch: -0.35 (initial downward angle)
#   - is_dragging: bool (mouse drag state)
#
# Constants:
#   - MIN_DISTANCE: 100.0
#   - MAX_DISTANCE: 5000.0
#   - MIN_PITCH: -PI/2 + 0.1
#   - MAX_PITCH: PI/2 - 0.1
#   - ZOOM_SENSITIVITY: 50.0
#   - ROTATION_SENSITIVITY: 0.005
#
# Input Handling (_input):
#   - Left mouse drag: Rotate camera (yaw/pitch)
#   - Mouse wheel up: Zoom in (decrease distance)
#   - Mouse wheel down: Zoom out (increase distance)
#   - Smooth clamping of distance and pitch
#
# Position Update (_update_camera_position):
#   - Calculates spherical offset:
#     offset = Vector3(
#       sin(yaw) * cos(pitch),
#       sin(pitch),
#       cos(yaw) * cos(pitch)
#     ) * distance
#   - Sets camera.position = offset
#   - camera.look_at(Vector3.ZERO, Vector3.UP)
#
# Auto-Fit Function (auto_fit_camera):
#   - Calculates mesh horizontal size (max X/Z dimensions)
#   - Sets camera.size = horizontal_size * 1.3 (30% padding)
#   - Adjusts camera position based on mesh bounds
#   - Default pitch: -0.6 radians (slight downward angle)
#   - Looks at terrain center: Vector3(0, avg_height, 0)
#
# LOD Integration:
#   - Calls _update_lod() on camera movement
#   - Updates chunk LOD levels based on distance
#   - Phase 4 feature for performance optimization
#
# Resource Path: scripts/preview/world_preview.gd

## ═══════════════════════════════════════════════════════════
## SECTION 7: LIGHTING SETUP
## ═══════════════════════════════════════════════════════════
#
# Current Lighting Configuration:
#
# 1. Shader Render Mode:
#    - Most shaders use: render_mode unshaded
#    - Lighting is DISABLED - shader ignores all lights
#    - Colors come entirely from ALBEDO and EMISSION
#    - Exception: world_preview.gdshader mode 4 (Full Render) uses lighting
#
# 2. World Preview Scene Lighting:
#    - DirectionalLight3D node exists in scene
#    - Location: WorldPreviewRoot/DirectionalLight3D
#    - Transform: Rotated for angled lighting
#    - Light color: Color(0.2, 0.6, 1, 1) (blue tint)
#    - Light energy: 0.5
#    - Shadow enabled: false
#    - NOTE: Has NO effect on unshaded shaders
#    - Used only for Full Render mode (preview_mode = 4)
#
# 3. Character Preview Scene Lighting:
#    - DirectionalLight3D node in CharacterPreview3D scene
#    - Standard lighting for 3D character models
#    - Affects character materials (StandardMaterial3D)
#    - No special configuration (uses defaults)
#
# 4. Ambient Light:
#    - Environment ambient_light_source: 2 (SKY color)
#    - Ambient light color: Color(0.1, 0.1, 0.15, 1) (dark blue-gray)
#    - NOTE: Also has NO effect on unshaded shaders
#    - Only affects lit materials
#
# Resource Path: scenes/WorldCreator.tscn, scenes/character/CharacterPreview3D.tscn

## ═══════════════════════════════════════════════════════════
## SECTION 8: POST-PROCESSING AND ENVIRONMENT
## ═══════════════════════════════════════════════════════════
#
# Environment Configuration:
#
# Location: scenes/WorldCreator.tscn
# Node: WorldEnvironment (SubResource: Environment_1)
#
# Background Settings:
#   - background_mode: 1 (COLOR - solid color background)
#   - background_color: Color(0, 0, 0, 1) (pure black)
#   - ambient_light_source: 2 (SKY - but unused due to unshaded shader)
#   - ambient_light_color: Color(0.1, 0.1, 0.15, 1) (unused)
#
# Glow (Bloom) Post-Processing:
#   - glow_enabled: true
#   - glow_levels/1-6: true (multi-level bloom)
#   - glow_intensity: 2.0 (amplifies emission)
#   - glow_strength: 1.5 (bloom strength)
#   - glow_bloom: 0.6 (bloom threshold)
#   - glow_hdr_threshold: 0.8 (HDR cutoff)
#   - Blend mode: Additive (creates halos)
#   - Creates intense glow around network lines and node points
#   - Particularly visible on cyan edges and orange highlights
#
# Fog Settings:
#   - fog_enabled: true
#   - fog_density: 0.02 (doubled from 0.01 for stronger effect)
#   - fog_color: Color(0, 0, 0, 1) (black fog)
#   - fog_height: 0.0
#   - fog_height_density: 0.0
#   - fog_sun_scatter: 0.0 (no light scattering)
#   - fog_aerial_perspective: 0.0
#   - Creates atmospheric mist fading distant parts
#   - Enhances depth perception
#
# Auto-Exposure:
#   - auto_exposure_enabled: true (if configured)
#   - Provides dynamic range adjustment
#   - Helps with bright emission values
#
# SSAO (Screen-Space Ambient Occlusion):
#   - ssao_enabled: true (in some scenes)
#   - ssao_ao_channel_affect: 0.0
#   - ssao_radius: 1.0
#   - ssao_intensity: 0.5
#   - Adds subtle depth cues (if enabled)
#
# Character Preview Environment:
#   - Uses default WorldEnvironment
#   - No special post-processing
#   - Standard 3D rendering
#
# Resource Path: scenes/WorldCreator.tscn

## ═══════════════════════════════════════════════════════════
## SECTION 9: VIEWPORT SETUP
## ═══════════════════════════════════════════════════════════
#
# World Preview Viewport:
#
# Location: scenes/WorldCreator.tscn
# Node: WorldPreviewViewport (parent: CenterPreview)
# Type: SubViewport
#
# Viewport Settings:
#   - size: Vector2(512, 512) pixels
#   - transparent_bg: false (opaque black background)
#   - render_target_update_mode: 2 (UPDATE_ALWAYS - continuous rendering)
#   - debug_draw: 0 (DEBUG_DRAW_DISABLED - no debug wireframe)
#   - disable_3d: false (3D rendering enabled)
#   - msaa: 0 (no anti-aliasing, or configured value)
#
# Container:
#   - Wrapped in SubViewportContainer for UI integration
#   - Container name: CenterPreview
#   - stretch: true (fills container)
#   - Layout anchors: Full rect (0-1.0)
#   - size_flags_horizontal: 3 (expand and fill)
#
# Character Preview Viewport:
#
# Location: scenes/character/CharacterPreview3D.tscn
# Node: root (type: SubViewport)
#
# Viewport Settings:
#   - size: Vector2(800, 1000) pixels
#   - transparent_bg: true (allows UI integration)
#   - render_target_update_mode: 2 (UPDATE_ALWAYS)
#   - debug_draw: 0 (DEBUG_DRAW_DISABLED)
#   - disable_3d: false (3D rendering enabled)
#
# Resource Paths:
#   - World preview: scenes/WorldCreator.tscn
#   - Character preview: scenes/character/CharacterPreview3D.tscn

## ═══════════════════════════════════════════════════════════
## SECTION 10: RENDERING STACK ORDER
## ═══════════════════════════════════════════════════════════
#
# Complete Rendering Pipeline (Bottom-to-Top):
#
# World Preview Rendering Stack:
#
# 1. Background Layer:
#    - WorldEnvironment.background_color = Color(0, 0, 0, 1) (black)
#    - Fog applied (density 0.02, black color)
#
# 2. Terrain Mesh Rendering:
#    - MeshInstance3D.terrain_mesh with ArrayMesh from world.gd
#    - ShaderMaterial with shader applied (world_preview or topo_preview)
#    - Vertex shader: Displaces vertices based on heightmap + wavy noise
#    - Fragment shader: Computes network colors + emission
#    - ALBEDO: Base network colors (deep blue → cyan)
#    - EMISSION: Enhanced glow (120-180% intensity)
#    - Render mode: unshaded (no lighting)
#    - Shape Preset Visual Effect: Organic boundaries visible as:
#      * Network lines fade out at mask edges (Y=0.0 vertices create flat boundaries)
#      * Node points disappear at edges (no vertices = no points to render)
#      * Creates non-rectangular map shapes (continent, islands, coastline, etc.)
#      * Low-lying areas at edges appear as "sea" in network view (dark/empty regions)
#
# 3. Node Points Layer:
#    - MultiMeshInstance3D.node_points_cyan (90% of vertices)
#    - MultiMeshInstance3D.node_points_orange (10% of vertices)
#    - Billboard quads with emission glow
#    - Size variation: 0.8-1.2 scale
#    - Colors: Cyan (0.0, 0.8, 1.0) and Orange (1.0, 0.6, 0.0)
#    - Shape Preset Effect: Node points only render where vertices exist
#      * Mask edges (Y=0.0 clamped vertices) create visible boundaries
#      * Island Chain: Multiple isolated clusters of points
#      * Coastline: Points fade out along one edge
#      * Continent: Points concentrated in center, sparse at edges
#
# 4. Additional Visualization Layers (if enabled):
#    - River points: Green MultiMeshInstance3D
#    - Foliage points: Green MultiMeshInstance3D
#    - POI markers: Colored MultiMeshInstance3D (varies by type)
#
# 5. Post-Processing:
#    - Bloom (glow): Intensity 2.0, strength 1.5, levels 1-6
#    - Depth of field: Bokeh blur on foreground/background
#    - Fog: Atmospheric mist
#
# Character Preview Rendering Stack:
#
# 1. Background:
#    - WorldEnvironment (default or transparent)
#
# 2. Character Model:
#    - CharacterRoot with instantiated GLB/TSCN model
#    - Skeleton3D with bone poses (morph targets)
#    - MeshInstance3D nodes (body, hair, horns, etc.)
#    - StandardMaterial3D or imported materials
#    - Standard lighting calculations
#
# 3. Camera:
#    - Perspective projection
#    - Orbit controls
#    - Smooth interpolation
#
# Final Output:
#   - World: Glowing blue network with cyan edges, orange highlights,
#            black background, bokeh blur, atmospheric fog
#   - Character: 3D model with real-time morphing, orbit camera,
#                standard 3D lighting

## ═══════════════════════════════════════════════════════════
## SECTION 11: RESOURCE PATHS SUMMARY
## ═══════════════════════════════════════════════════════════
#
# Critical Resource Paths:
#
# Mesh Generation:
#   - scripts/world.gd (WorldData class, _generate_threaded())
#
# World Preview Controller:
#   - scripts/preview/world_preview.gd (world_preview Node3D)
#   - scenes/WorldCreator.tscn (WorldPreviewViewport/WorldPreviewRoot)
#
# Shaders:
#   - res://assets/shaders/world_preview.gdshader (primary, multi-mode)
#   - res://assets/shaders/topo_preview.gdshader (fallback, network style)
#   - res://assets/shaders/topo_hologram_final.gdshader (holographic style)
#   - res://shaders/blue_glow.gdshader (simple glow)
#
# Materials:
#   - res://assets/materials/topo_preview_shader.tres (optional)
#   - res://materials/blue_glow.tres (optional)
#
# Meshes:
#   - res://assets/meshes/node_point.tres (node point billboard)
#
# Character Preview:
#   - scripts/character/CharacterPreview3D.gd
#   - scripts/ui/character_preview_camera.gd
#   - scenes/character/CharacterPreview3D.tscn
#   - res://assets/models/character_bases/ (GLB/TSCN models)
#
# Preview Mode System:
#   - scripts/preview/world_preview.gd (set_preview_mode)
#   - scripts/WorldCreator.gd (preview_mode_selector UI)
#
# Biome Overlay:
#   - scripts/preview/world_preview.gd (toggle_biome_overlay, _update_biome_overlay)
#   - scenes/WorldCreator.tscn (biome_overlay node)
#
# Visualization Systems:
#   - scripts/preview/world_preview.gd (_update_river_visualization, _update_foliage_visualization, _update_poi_visualization)
#
# LOD and Chunk System:
#   - scripts/preview/world_preview.gd (chunk management, LOD updates)
#   - scripts/world_creation/LODManager.gd (LOD utilities)
#   - scripts/world.gd (chunk generation)
#
# Biome Texture Manager:
#   - scripts/world_creation/BiomeTextureManager.gd (texture loading)
#   - scripts/preview/world_preview.gd (_apply_biome_textures)
#
# Progress Dialog:
#   - scripts/ui/progress_dialog.gd
#   - scenes/ui/progress_dialog.tscn
#   - scripts/WorldCreator.gd, scripts/main_controller.gd (usage)
#
# Scene Structure:
#   - scenes/WorldCreator.tscn (main world creator scene)
#     - WorldPreviewViewport (SubViewport)
#       - WorldPreviewRoot (Node3D with script: world_preview.gd)
#         - terrain_mesh (MeshInstance3D)
#         - node_points_cyan (MultiMeshInstance3D)
#         - node_points_orange (MultiMeshInstance3D)
#         - Camera3D (perspective with DOF)
#         - DirectionalLight3D (unused for unshaded)
#       - WorldEnvironment (black background, bloom, fog)
#
# Themes (UI only):
#   - res://assets/themes/dark_fantasy_theme.tres
#   - res://themes/bg3_theme.tres (if exists)

## ═══════════════════════════════════════════════════════════
## SECTION 12: PERFORMANCE CONSIDERATIONS
## ═══════════════════════════════════════════════════════════
#
# Optimization Strategies:
#
# 1. MultiMeshInstance3D:
#    - Efficient GPU instancing for thousands of node points
#    - Single draw call per MultiMesh instance
#    - Separate instances for cyan/orange (2 draw calls total)
#    - Billboard mode reduces overdraw
#
# 2. LOD System (Phase 4):
#    - Chunk-based LOD for large terrains
#    - Distance-based detail reduction
#    - Managed by LODManager class
#    - Updates on camera movement
#
# 3. Shader Optimization:
#    - Unshaded render mode (no lighting calculations)
#    - Simple fragment shader operations
#    - Efficient noise functions (hash-based)
#    - Screen-space derivatives for line thickness
#
# 4. Viewport Settings:
#    - Fixed size viewports (512x512, 800x1000)
#    - No MSAA (or minimal) for performance
#    - Continuous rendering (UPDATE_ALWAYS)
#
# 5. Mesh Generation:
#    - Threaded generation (_generate_threaded)
#    - Efficient SurfaceTool usage
#    - PRIMITIVE_LINES (minimal vertex data)
#    - No normals (not needed for lines)
#
# Performance Targets:
#   - 60 FPS on mid-range hardware
#   - Smooth camera movement
#   - Real-time morph target updates
#   - Responsive UI interaction

## ═══════════════════════════════════════════════════════════
## SECTION 13: PREVIEW MODE SYSTEM
## ═══════════════════════════════════════════════════════════
#
# The world preview supports multiple rendering modes that can be switched
# at runtime via the set_preview_mode() function.
#
# Location: scripts/preview/world_preview.gd
# Function: set_preview_mode(mode: int)
# UI Integration: scripts/WorldCreator.gd (preview_mode_selector)
#
# Preview Modes:
#
# Mode 0: Network (Default)
#    - Wireframe style with wavy animated lines
#    - Deep blue base with cyan edges
#    - Orange highlights via noise
#    - Enhanced emission glow
#    - Uses same visual style as topo_preview.gdshader
#
# Mode 1: Topographic
#    - Height-based color gradient (blue → brown → gray)
#    - Contour lines at regular intervals
#    - Contour spacing controlled by contour_spacing uniform
#    - Contour width controlled by contour_width uniform
#
# Mode 2: Biome Color
#    - Texture splatting using splatmap weights
#    - Blends up to 4 biome textures (RGBA channels)
#    - Optional normal map blending
#    - River overlay using river_map texture
#    - Requires splatmap_texture in world_data
#
# Mode 3: Foliage Density
#    - Green gradient visualization
#    - Dark gray (0.2, 0.2, 0.2) to bright green (0.1, 0.6, 0.2)
#    - Based on foliage_density_map texture
#    - Shows vegetation distribution
#
# Mode 4: Full Render
#    - Complete texture splatting with lighting
#    - Same as Biome Color mode but with full lighting support
#    - Height-based emission for "magic areas" (h > 0.7)
#    - Magic emission: smoothstep(0.7, 1.0, h) * 0.3
#    - Uses scene lighting (not unshaded)
#
# Implementation:
#
# 1. Mode Setting:
#    - Function: set_preview_mode(mode: int)
#    - Updates shader parameter "preview_mode" on ShaderMaterial
#    - Updates world_data.params["preview_mode"] for persistence
#    - Location: world_preview.gd:224-242
#
# 2. UI Integration:
#    - OptionButton: preview_mode_selector in WorldCreator.gd
#    - Options: "Network", "Topographic", "Biome Color", "Foliage Density", "Full Render"
#    - Signal: item_selected → _on_preview_mode_selected(index)
#    - Default: Mode 0 (Network)
#    - Location: WorldCreator.gd:175-213
#
# 3. Shader Application:
#    - Mode set during _apply_world_shader()
#    - Read from world_data.params.get("preview_mode", 0)
#    - Applied to ShaderMaterial via set_shader_parameter()
#    - Location: world_preview.gd:149-150
#
# 4. Fallback Behavior:
#    - If world_preview shader unavailable, falls back to topo_preview shader
#    - Fallback shader only supports Network mode (mode 0)
#    - Other modes require world_preview.gdshader with splatmap
#
# Resource Paths:
#   - Preview mode function: scripts/preview/world_preview.gd
#   - UI selector: scripts/WorldCreator.gd
#   - Shader: res://assets/shaders/world_preview.gdshader

## ═══════════════════════════════════════════════════════════
## SECTION 14: BIOME OVERLAY SYSTEM
## ═══════════════════════════════════════════════════════════
#
# A semi-transparent overlay mesh that displays biome colors on top of
# the terrain mesh for visual reference.
#
# Location: scripts/preview/world_preview.gd
# Functions: toggle_biome_overlay(), _update_biome_overlay()
# Node: biome_overlay (MeshInstance3D in WorldPreviewRoot)
#
# Overlay Implementation:
#
# 1. Mesh Creation:
#    - Creates duplicate of base terrain mesh
#    - Uses SurfaceTool to copy mesh geometry
#    - Applies vertex colors based on biome type
#    - Generates normals for proper rendering
#    - Location: world_preview.gd:387-444
#
# 2. Biome Color Mapping:
#    - Maps biome types to semi-transparent colors:
#      * forest: Color(0.2, 0.6, 0.2, 0.5) - Green
#      * desert: Color(0.9, 0.8, 0.5, 0.5) - Sand
#      * jungle: Color(0.1, 0.5, 0.1, 0.5) - Dark green
#      * tundra: Color(0.8, 0.9, 0.9, 0.5) - Light blue-gray
#      * taiga: Color(0.4, 0.6, 0.5, 0.5) - Gray-green
#      * mountain: Color(0.6, 0.6, 0.6, 0.5) - Gray
#      * swamp: Color(0.3, 0.4, 0.2, 0.5) - Dark green-brown
#      * grassland: Color(0.6, 0.7, 0.4, 0.5) - Light green
#      * plains: Color(0.7, 0.7, 0.5, 0.5) - Tan
#      * coast: Color(0.4, 0.6, 0.8, 0.5) - Blue
#      * cold_desert: Color(0.7, 0.7, 0.6, 0.5) - Light tan
#    - Default: Color(0.5, 0.5, 0.5, 0.3) - Gray (if biome unknown)
#
# 3. Material Properties:
#    - StandardMaterial3D with transparency
#    - albedo_color: Color(1, 1, 1, 0.5) - White with 50% opacity
#    - transparency: TRANSPARENCY_ALPHA
#    - shading_mode: SHADING_MODE_UNSHADED (no lighting)
#    - Renders on top of terrain mesh
#
# 4. Toggle Function:
#    - Function: toggle_biome_overlay(enabled: bool)
#    - Sets biome_overlay_enabled flag
#    - Shows/hides biome_overlay node
#    - Updates overlay mesh if enabled and mesh exists
#    - Location: world_preview.gd:380-385
#
# 5. Update Trigger:
#    - Called automatically in update_mesh() if overlay enabled
#    - Can be called manually via toggle_biome_overlay(true)
#    - Requires world_data to be set via set_world_data()
#    - Location: world_preview.gd:103-105
#
# Usage:
#    - Toggle via UI button or function call
#    - Overlay provides visual reference for biome distribution
#    - Semi-transparent so underlying terrain remains visible
#    - Useful for debugging biome assignment
#
# Resource Paths:
#   - Overlay functions: scripts/preview/world_preview.gd
#   - Node: scenes/WorldCreator.tscn (WorldPreviewRoot/biome_overlay)

## ═══════════════════════════════════════════════════════════
## SECTION 15: RIVER, FOLIAGE, AND POI VISUALIZATION SYSTEMS
## ═══════════════════════════════════════════════════════════
#
# Additional MultiMeshInstance3D systems for visualizing rivers, foliage density,
# and Points of Interest (POI) on the terrain.
#
# Location: scripts/preview/world_preview.gd
# Functions: _update_river_visualization(), _update_foliage_visualization(), _update_poi_visualization()
#
# ────────────────────────────────────────────────────────────
# 15.1: River Visualization
# ────────────────────────────────────────────────────────────
#
# Visualizes river paths using blue MultiMeshInstance3D points.
#
# Implementation:
#    - MultiMeshInstance3D: river_points_instance
#    - Material: StandardMaterial3D (unshaded)
#    - Color: Color(0.2, 0.5, 1.0) - Blue
#    - Emission: Color(0.2, 0.5, 1.0) * 1.5 - Enhanced glow
#    - Billboard mode: BILLBOARD_ENABLED
#    - Point size: 2.0x2.0 world units (larger than regular nodes)
#    - Scale: 1.2x (slightly larger than regular nodes)
#
# Data Source:
#    - Reads river_paths array from world_data
#    - Maps grid positions to mesh vertex positions
#    - Creates points at each river cell
#    - Location: world_preview.gd:572-648
#
# Update Trigger:
#    - Called automatically in _update_node_points()
#    - Also called in update_mesh() if world_data has river_paths
#    - Removes visualization if no rivers exist
#
# ────────────────────────────────────────────────────────────
# 15.2: Foliage Visualization
# ────────────────────────────────────────────────────────────
#
# Visualizes foliage density using green MultiMeshInstance3D points.
#
# Implementation:
#    - MultiMeshInstance3D: foliage_points_instance
#    - Material: StandardMaterial3D (unshaded)
#    - Color: Color(0.2, 0.8, 0.3) - Green
#    - Emission: Color(0.2, 0.8, 0.3) * 1.2 - Enhanced glow
#    - Billboard mode: BILLBOARD_ENABLED
#    - Point size: 1.5x1.5 world units (smaller than rivers)
#    - Scale: 0.8x (smaller than regular nodes)
#
# Data Source:
#    - Reads foliage_density array from world_data
#    - Only shows points where density > 0.2 (20% threshold)
#    - Probability-based display (higher density = more likely to show)
#    - Uses seed-based RNG for consistent placement
#    - Location: world_preview.gd:656-740
#
# Enable/Disable:
#    - Controlled by world_data.params.get("enable_foliage", true)
#    - Removes visualization if disabled or no data
#
# Update Trigger:
#    - Called automatically in _update_node_points()
#    - Removes visualization if no foliage data or disabled
#
# ────────────────────────────────────────────────────────────
# 15.3: POI (Points of Interest) Visualization
# ────────────────────────────────────────────────────────────
#
# Visualizes Points of Interest using colored MultiMeshInstance3D markers.
#
# Implementation:
#    - MultiMeshInstance3D: poi_points_instance
#    - Material: StandardMaterial3D (unshaded)
#    - Billboard mode: BILLBOARD_ENABLED
#    - Point size: 3.0x3.0 world units (largest of all point types)
#    - Scale: 2.0x (larger than foliage and rivers)
#
# POI Type Colors:
#    - city: Color(1.0, 0.8, 0.0) - Gold
#    - town: Color(0.8, 0.8, 0.8) - Silver/Gray
#    - ruin: Color(0.8, 0.2, 0.2) - Red
#    - resource: Color(0.2, 0.8, 1.0) - Cyan
#    - Default: Color.WHITE (if type unknown)
#
# Data Source:
#    - Reads poi_metadata array from world_data
#    - Each POI has: position (Vector3), type (String)
#    - Creates one point per POI
#    - Material color set based on first POI type (simplified)
#    - Location: world_preview.gd:748-816
#
# Update Trigger:
#    - Called automatically in _update_node_points()
#    - Removes visualization if no POIs exist
#
# Common Properties:
#    - All use MultiMeshInstance3D for efficient GPU instancing
#    - All use billboard mode (always face camera)
#    - All use unshaded materials with emission
#    - All update automatically when mesh updates
#    - All remove themselves if no data available
#
# Resource Paths:
#   - Visualization functions: scripts/preview/world_preview.gd
#   - Data source: world_data (WorldData class)

## ═══════════════════════════════════════════════════════════
## SECTION 16: LOD AND CHUNK SYSTEM
## ═══════════════════════════════════════════════════════════
#
# Level-of-Detail (LOD) and chunk-based rendering system for large terrains.
#
# Location: scripts/preview/world_preview.gd
# Manager: scripts/world_creation/LODManager.gd
# Functions: _setup_chunks_container(), _on_chunk_generated(), _update_lod()
#
# Chunk System:
#
# 1. Chunk Container:
#    - Node3D container: chunks_container
#    - Created via _setup_chunks_container()
#    - Name: "ChunksContainer"
#    - Parent: WorldPreviewRoot
#    - Stores all chunk mesh instances
#    - Location: world_preview.gd:826-834
#
# 2. Chunk Storage:
#    - Dictionary: chunk_nodes (chunk_key → MeshInstance3D)
#    - Chunk key format: "chunk_{x}_{y}" (via LODManager.create_chunk_key())
#    - Each chunk has its own MeshInstance3D node
#    - Location: world_preview.gd:24-25
#
# 3. Chunk Generation Signal:
#    - Signal: world_data.chunk_generated(chunk_x, chunk_y, mesh)
#    - Connected in set_world_data()
#    - Handler: _on_chunk_generated()
#    - Creates or updates chunk mesh instance
#    - Applies shader material to chunk
#    - Location: world_preview.gd:374-378, 836-865
#
# 4. Chunk Shader Application:
#    - Function: _apply_shader_to_chunk()
#    - Duplicates main terrain material
#    - Generates heightmap texture for chunk
#    - Falls back to basic material if main material unavailable
#    - Location: world_preview.gd:867-893
#
# LOD System:
#
# 1. LOD Manager:
#    - Class: LODManager (preloaded static class)
#    - Path: res://scripts/world_creation/LODManager.gd
#    - Functions: create_chunk_key(), get_lod_for_distance(), downsample_heightmap(), create_lod_mesh()
#    - Location: world_preview.gd:9
#
# 2. LOD Update:
#    - Function: _update_lod()
#    - Called on camera movement (_input event)
#    - Called in _process() if LOD enabled
#    - Calculates distance from camera to each chunk
#    - Gets LOD level via LODManager.get_lod_for_distance()
#    - Currently shows/hides chunks based on max_distance
#    - Full LOD switching requires regenerating chunks (not yet implemented)
#    - Location: world_preview.gd:68, 895-935, 937-940
#
# 3. LOD Configuration:
#    - Enable/disable: world_data.params.get("enable_lod", true)
#    - LOD distances: world_data.params.get("lod_distances", [500.0, 2000.0])
#    - Default distances: 500.0 (medium), 2000.0 (far)
#    - Max distance: Last value in lod_distances array
#    - Chunks beyond max_distance are hidden
#
# 4. Performance Optimization:
#    - Chunks beyond max_distance are set to visible = false
#    - Reduces rendering load for distant terrain
#    - Full LOD mesh switching requires chunk regeneration (Phase 4 feature)
#    - Currently only visibility culling implemented
#
# Integration:
#    - Chunk generation happens in world.gd (_generate_threaded)
#    - Chunks emitted via chunk_generated signal
#    - Preview receives chunks and creates mesh instances
#    - LOD updates based on camera position
#    - Works alongside main terrain mesh (not replacement)
#
# Resource Paths:
#   - Chunk functions: scripts/preview/world_preview.gd
#   - LOD Manager: scripts/world_creation/LODManager.gd
#   - Chunk generation: scripts/world.gd

## ═══════════════════════════════════════════════════════════
## SECTION 17: BIOME TEXTURE MANAGER INTEGRATION
## ═══════════════════════════════════════════════════════════
#
# System for loading and applying biome textures to the world preview shader.
#
# Manager: scripts/world_creation/BiomeTextureManager.gd
# Integration: scripts/preview/world_preview.gd (_apply_biome_textures())
#
# Texture Loading:
#
# 1. Manager Class:
#    - Class: BiomeTextureManager (preloaded static class)
#    - Path: res://scripts/world_creation/BiomeTextureManager.gd
#    - Loads biome texture configuration from JSON
#    - Provides texture lookup functions
#    - Location: world_preview.gd:11
#
# 2. Texture Application:
#    - Function: _apply_biome_textures(material: ShaderMaterial)
#    - Gets all biome names via BiomeTextureManager.get_all_biome_names()
#    - Loads first 8 biome textures (biome_texture_0 through biome_texture_7)
#    - Sets shader parameters: "biome_texture_{i}" for each texture
#    - Loads normal maps for first 4 biomes (biome_normal_0 through biome_normal_3)
#    - Sets shader parameters: "biome_normal_{i}" for each normal map
#    - Location: world_preview.gd:200-222
#
# 3. Texture Limits:
#    - Up to 8 biome textures supported (shader uniform limit)
#    - Up to 4 normal maps supported (shader uniform limit)
#    - Textures loaded in order from BiomeTextureManager
#    - Missing textures are skipped (no error)
#
# 4. Integration Point:
#    - Called during _apply_world_shader()
#    - Only applies if world_preview shader is used (not fallback)
#    - Requires world_data to be set
#    - Location: world_preview.gd:137-138
#
# Configuration:
#    - Biome textures configured in JSON file
#    - Path loaded by BiomeTextureManager
#    - Supports texture paths and normal map paths
#    - Caches loaded textures for performance
#
# Usage:
#    - Automatic: Textures applied when world_preview shader is used
#    - Manual: Can be called directly if material is available
#    - Required for: Biome Color mode (2) and Full Render mode (4)
#    - Optional for: Network mode (0) and Topographic mode (1)
#
# Resource Paths:
#   - Texture application: scripts/preview/world_preview.gd
#   - Texture manager: scripts/world_creation/BiomeTextureManager.gd
#   - Configuration: JSON file (path managed by BiomeTextureManager)

## ═══════════════════════════════════════════════════════════
## SECTION 18: WORLD MESH GENERATION PROGRESS POPUP
## ═══════════════════════════════════════════════════════════
#
# A progress dialog popup appears during world mesh generation to provide
# user feedback during long-running generation tasks.
#
# Location: scripts/ui/progress_dialog.gd
# Scene: scenes/ui/progress_dialog.tscn
# Usage: scripts/WorldCreator.gd, scripts/main_controller.gd
#
# Popup Implementation:
#
# 1. Dialog Type:
#    - Extends Window (Godot's window base class)
#    - Title: "Forging the World…"
#    - Size: 400x120 pixels (centered on screen)
#    - Mode: Window.MODE_POPUP (popup window)
#    - Theme: Uses bg3_theme.tres for consistent styling
#    - Transparent: false
#    - Borderless: false
#    - Initially hidden (visible = false)
#
# 2. UI Components:
#    - StatusLabel: Displays current generation phase text
#      * Position: Vector2(20, 20), Size: Vector2(360, 30)
#      * Text: "Generating heightmap..." (progress < 0.3)
#      * Text: "Building mesh geometry..." (progress < 0.6)
#      * Text: "Calculating normals..." (progress < 0.9)
#      * Text: "Finalizing world..." (progress >= 0.9)
#      * Horizontal alignment: Center
#    - ProgressBar: Visual progress indicator (0.0 to 1.0)
#      * Position: Vector2(20, 60), Size: Vector2(360, 20)
#      * min_value: 0.0
#      * max_value: 1.0
#      * show_percentage: false (no percentage text)
#    - No buttons: Classic progress bar dialog without Cancel or OK buttons
#
# 3. Window Behavior:
#    - Close request handling: _notification(what) intercepts NOTIFICATION_CLOSE_REQUEST
#    - Close request calls hide() to prevent closing via X button
#    - No cancellation support: Dialog cannot be cancelled by user
#    - Dialog automatically closes when generation completes
#
# 4. Lifecycle:
#
# Show Phase (_show_progress_dialog):
#    - Called when world.generate() is invoked
#    - Instantiates progress_dialog from PROGRESS_DIALOG_SCENE
#    - Adds dialog as child to scene tree
#    - Calls popup_centered(Vector2i(400, 120)) to display
#    - Location: WorldCreator.gd:396-400, main_controller.gd:208-216
#
# Update Phase (_on_generation_progress):
#    - Receives progress value (0.0 to 1.0) from world.generation_progress signal
#    - Updates progress_bar.value via set_progress()
#    - Updates status_label.text via set_status() with phase-specific messages
#    - Location: WorldCreator.gd:416-422, main_controller.gd:226-239
#
# Hide Phase (_on_generation_complete):
#    - Called when world.generation_complete signal is emitted
#    - Calls progress_dialog.queue_free() to remove dialog
#    - Sets progress_dialog = null
#    - Location: WorldCreator.gd:369-372, main_controller.gd:243-246
#
# 5. Integration Points:
#
# WorldCreator.gd:
#    - const PROGRESS_DIALOG_SCENE = preload("res://scenes/ui/progress_dialog.tscn")
#    - var progress_dialog: Window = null
#    - Shows popup before calling world.generate()
#    - Updates popup during chunk generation (_on_chunk_generated)
#    - No cancellation signal connections (removed)
#
# main_controller.gd:
#    - Same PROGRESS_DIALOG_SCENE constant
#    - var progress_dialog: Window
#    - Shows popup in _on_regeneration_timeout()
#    - Provides detailed status messages based on progress value
#    - No cancellation signal connections (removed)
#
# world.gd:
#    - Emits generation_progress signal with float value (0.0-1.0)
#    - Emits generation_complete signal when finished
#    - Note: abort_generation() still exists but is not accessible via UI
#
# 6. Visual Styling:
#    - Uses bg3_theme.tres for consistent UI appearance
#    - Window appears centered on screen
#    - Popup mode (non-blocking but modal)
#    - Progress bar fills from left to right
#    - Status text updates dynamically during generation
#    - Classic progress bar design without buttons
#
# Resource Paths:
#   - Dialog Script: scripts/ui/progress_dialog.gd
#   - Dialog Scene: scenes/ui/progress_dialog.tscn
#   - Usage: scripts/WorldCreator.gd, scripts/main_controller.gd
#   - Theme: res://themes/bg3_theme.tres

## ═══════════════════════════════════════════════════════════
## SUMMARY OF CURRENT LOOK
## ═══════════════════════════════════════════════════════════

const SUMMARY_OF_CURRENT_LOOK: String = """
The current visual style produces an organic, wavy glowing blue network with dense triangular connections, rendered against a black background with strong bokeh depth blur and mist. The terrain mesh is generated as a line-based network (PRIMITIVE_LINES) with horizontal, vertical, and diagonal connections forming a dense triangular mesh pattern (VERTS_PER_UNIT: 8 for finer grid). Lines exhibit organic waviness through TIME-animated multi-octave FBM noise displacement in the vertex shader, creating flowing, natural movement. Lines are rendered with a deep blue base color (0.0, 0.1, 0.4) transitioning to bright cyan edges (0.0, 0.8, 1.0) based on height variation, with simulated thickness using screen-space derivatives for a tube-like appearance. Orange highlights (1.0, 0.5, 0.0) appear randomly on ~15% of line fragments via noise-based selection. Node points are positioned at all mesh vertices using MultiMeshInstance3D with per-instance colors: ~90% cyan (0.0, 0.8, 1.0) and ~10% orange (1.0, 0.6, 0.0) for highlights, with size variation (0.8-1.2 scale) for organic feel. The shader applies 120% base emission intensity (1.2), enhanced up to 180% with thickness falloff, creating an intense glow effect amplified by post-processing bloom (intensity 2.0, strength 1.5, levels 1-6, additive blend mode). Enhanced black fog (density 0.02, doubled from previous) creates atmospheric mist fading distant parts. The camera uses a perspective projection (60° FOV) with enhanced depth of field (far_amount 1.0, focus_distance 150.0, near blur enabled) creating strong bokeh blur effects on foreground and background while keeping the mid-ground network sharply focused. The camera is positioned closer (distance multiplier 1.2, initial 500.0) at a dynamic angled view (pitch -0.35, yaw 0.3) for detailed network inspection. All rendering is unlit (unshaded shader mode), meaning colors come entirely from the shader's ALBEDO and EMISSION calculations rather than scene lighting.

The character preview system renders 3D character models with real-time morphing via bone scaling and mesh scaling. Models are loaded from GLB/TSCN files with Rigify skeleton support. The camera uses orbit controls with smooth interpolation, positioned at eye level (1.4 units) with zoom range 1.5-5.0 units. Morph targets include height, weight, muscle, facial features, and race-specific attributes, all applied in real-time for immediate visual feedback.
"""
