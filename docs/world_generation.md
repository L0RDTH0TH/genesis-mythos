# World Generation System Documentation

**Generated via Multi-Hop Analysis**  
**Last Updated:** 2025-01-06  
**Project:** Genesis (Godot 4.3)  
**Author:** Lordthoth

---

## Table of Contents

1. [Overview](#overview)
2. [Core Components](#core-components)
3. [Data Flows](#data-flows)
4. [Procedural Logic](#procedural-logic)
5. [Integration Points](#integration-points)
6. [Potential Update Hooks](#potential-update-hooks)

---

## Overview

The World Generation system is a fully procedural, data-driven terrain generation system built in Godot 4.3. It generates 3D mesh terrain using FastNoiseLite for heightmap generation, assigns biomes based on height/temperature/humidity, and provides real-time preview with fantasy style presets.

**Key Features:**
- Threaded procedural generation (background processing)
- Preview resolution vs. full resolution modes
- Biome assignment with metadata (monsters, magic levels, temperature categories)
- Fantasy style presets with visual effects (skybox, particles, bloom, fog)
- Parameter auto-propagation (terrain → climate dependencies)
- Save/Load system with folder-based persistence
- Export capabilities (Godot scene, OBJ, PDF atlas)

**Architecture Pattern:**
- **Data-Driven:** All parameters stored in `WorldData` Resource
- **Signal-Based:** Event-driven updates via signals
- **Threaded:** Background generation with mutex-protected mesh updates
- **Modular:** Section-based UI with parameter isolation

---

## Core Components

### Entry Points

#### 1. `WorldCreator.gd` (Main Controller)
**Path:** `res://scripts/WorldCreator.gd`  
**Type:** `extends MarginContainer`  
**Purpose:** Primary UI controller for world creation interface

**Key Variables:**
- `world: WorldData` - Current world data resource
- `sections: Array[String]` - Scene paths for parameter sections
- `current_tab: int` - Active tab index (0-5)
- `regeneration_timer: Timer` - Debounce timer (0.3s) for regeneration
- `is_regenerating: bool` - Generation state flag
- `world_preview: Node3D` - 3D preview root node

**Key Functions:**
- `_ready()` - Initialize world from default, setup UI, connect signals
- `_on_tab_selected(tab_idx: int)` - Switch parameter sections
- `_on_param_changed(param: String, value: Variant)` - Handle parameter updates
- `queue_regeneration()` - Debounced regeneration trigger
- `_on_generation_complete()` - Update preview mesh after generation
- `_on_generate_world_pressed()` - Final generation + transition to character creation

**Dependencies:**
- `WorldData` (world.gd)
- `WorldPreview` (world_preview.gd)
- Section scenes (6 tabs: seed_size, terrain, climate, biome, civilization, resources)
- `GameData` singleton (for world data storage)
- `ExportUtils` (for export functionality)

---

#### 2. `world.gd` (WorldData Resource)
**Path:** `res://scripts/world.gd`  
**Type:** `class_name WorldData extends Resource`  
**Purpose:** Core world data and generation logic

**Key Enums:**
```gdscript
enum SizePreset {
    TINY = 64,
    SMALL = 256,
    MEDIUM = 512,
    LARGE = 1024,
    EPIC = 2048
}
```

**Key Variables:**
- `seed: int` - World generation seed
- `size_preset: SizePreset` - Full resolution size
- `preview_resolution: SizePreset` - Preview resolution (default: SMALL/256)
- `params: Dictionary` - Terrain/climate parameters
- `randomness: Dictionary` - Per-category randomness (0-1.0)
- `generated_mesh: Mesh` - Final generated mesh
- `biome_metadata: Array[Dictionary]` - Biome data per cell
- `river_paths: Array` - Phase 2: River paths (list of path arrays, each path is Array[Vector2i])
- `heightmap_cache: Dictionary` - Phase 4: Cached heightmap images (cache key -> Image)
- `chunk_data: Dictionary` - Phase 4: Chunk meshes (chunk key -> Mesh)
- `lod_levels: Dictionary` - Phase 4: Chunk LOD levels (chunk key -> LOD level)
- `foliage_density: Array` - Phase 3: Per-cell foliage density (0.0-1.0, Array of floats)
- `poi_metadata: Array` - Phase 3: POI data (Array of Dictionaries: {type, position, biome, name, ...})
- `splatmap_texture: ImageTexture` - Phase 5: Biome splatmap (RGBA = 4 biome channels)
- `river_map_texture: ImageTexture` - Phase 5: River overlay map
- `foliage_density_texture: ImageTexture` - Phase 5: Foliage density map
- `generation_thread: Thread` - Background generation thread
- `generation_mutex: Mutex` - Thread synchronization
- `is_generating: bool` - Generation state
- `should_abort: bool` - Abort flag

**Key Constants:**
- `VERTS_PER_UNIT: int = 8` - Vertices per world unit (denser grid)
- `HORIZONTAL_SCALE: float = 4.0` - World units between vertices
- `DEFAULT_ELEVATION_SCALE: float = 30.0` - Default height scale

**Key Functions:**
- `generate(force_full_res: bool = false)` - Start threaded generation
- `_generate_threaded()` - Background generation logic (switches to chunked mode if LOD enabled)
- `_generate_chunked(vert_grid_size: Vector2i, _world_size: Vector2i)` - Phase 4: Chunk-based generation
- `_generate_chunk(...)` - Phase 4: Generate single chunk mesh
- `_get_cache_key() -> String` - Phase 4: Generate cache key from seed + params (includes shape_preset)
- `_apply_shape_mask(heightmap: Array[float], vert_grid_size: Vector2i, shape_preset: String) -> Array[float]` - Apply shape preset mask to heightmap
- `_generate_full_heightmap(vert_grid_size: Vector2i) -> Array[float]` - Phase 4: Extract heightmap generation
- `_assign_biomes(heightmap: Array[float], size: Vector2i)` - Biome assignment
- `_determine_biome(height: float, humidity: float, temp: float) -> Dictionary` - Biome logic
- `_generate_splatmap(size: Vector2i)` - Phase 5: Generate biome splatmap texture (RGBA channels)
- `_generate_river_map(size: Vector2i)` - Phase 5: Generate river overlay texture
- `_generate_foliage_density_texture(size: Vector2i)` - Phase 5: Generate foliage density texture
- `auto_propagate()` - One-way parameter propagation (terrain → climate)
- `load_style_preset(style_name: String)` - Apply fantasy style preset
- `abort_generation()` - Cancel ongoing generation

**Signals:**
- `generation_progress(progress: float)` - 0.0 to 1.0
- `generation_complete()` - Emitted when mesh is ready
- `chunk_generated(chunk_x: int, chunk_y: int, mesh: Mesh)` - Phase 4: Progressive chunk generation
- `style_applied(style_name: String, color_tint: Color, invert_normals: bool)` - Style update

---

#### 3. `world_preview.gd` (3D Preview Controller)
**Path:** `res://scripts/preview/world_preview.gd`  
**Type:** `extends Node3D`  
**Purpose:** 3D preview with camera controls and mesh rendering

**Key Variables:**
- `camera: Camera3D` - Preview camera
- `terrain_mesh_instance: MeshInstance3D` - Terrain mesh renderer
- `biome_overlay: MeshInstance3D` - Biome color overlay
- `node_points_instance: MultiMeshInstance3D` - Cyan node points
- `node_points_orange_instance: MultiMeshInstance3D` - Orange highlight nodes
- `river_points_instance: MultiMeshInstance3D` - Phase 2: Blue river visualization points
- `chunk_nodes: Dictionary` - Phase 4: Chunk mesh instances (chunk key -> MeshInstance3D)
- `chunks_container: Node3D` - Phase 4: Container for chunk meshes
- `world_data: WorldData` - Reference to world data
- `camera_distance: float = 500.0` - Camera distance
- `camera_yaw: float = 0.3` - Camera rotation
- `camera_pitch: float = -0.35` - Camera pitch angle

**Key Functions:**
- `update_mesh(new_mesh: Mesh)` - Update terrain mesh and apply shader
- `_apply_world_shader(mesh: Mesh)` - Phase 5: Apply world preview shader with texture splatting (falls back to topo shader)
- `_apply_topo_shader_fallback(mesh: Mesh)` - Fallback to old topo preview shader
- `_apply_biome_textures(material: ShaderMaterial)` - Phase 5: Load and apply biome textures to shader
- `_generate_heightmap_texture(mesh: Mesh) -> ImageTexture` - Generate heightmap from mesh
- `auto_fit_camera()` - Auto-fit camera to mesh bounds
- `set_world_data(data: WorldData)` - Set world data reference
- `toggle_biome_overlay(enabled: bool)` - Toggle biome color overlay
- `_setup_node_points()` - Create MultiMesh instances for node visualization
- `_update_node_points(mesh: Mesh)` - Update node positions from mesh vertices
- `_update_river_visualization(mesh: Mesh)` - Phase 2: Update blue river point visualization
- `_update_foliage_visualization(mesh: Mesh)` - Phase 3: Update green foliage point visualization
- `_update_poi_visualization(mesh: Mesh)` - Phase 3: Update POI marker visualization
- `_setup_chunks_container()` - Phase 4: Create container for chunk meshes
- `_on_chunk_generated(chunk_x: int, chunk_y: int, mesh: Mesh)` - Phase 4: Handle incremental chunk updates
- `_apply_topo_shader_to_chunk(chunk_node: MeshInstance3D, mesh: Mesh)` - Phase 4: Apply shader to chunk meshes

**Input Handling:**
- Mouse drag (left button) - Orbit camera
- Mouse wheel - Zoom in/out
- Auto-fit on mesh update

---

### Parameter Sections

#### 4. `seed_size_section.gd`
**Path:** `res://scripts/ui/seed_size_section.gd`  
**Type:** `extends PanelContainer`  
**Purpose:** Seed, world size, and map shape parameter controls

**Key Controls:**
- `seed_spinbox: SpinBox` - Seed input
- `fresh_seed_button: Button` - Random seed generator
- `size_option: OptionButton` - Size preset selector
- `shape_option: OptionButton` - Map shape preset selector

**Signals:**
- `param_changed(param: String, value: Variant)` - Emitted on change

**Parameter Mapping:**
- UI index → WorldData.SizePreset: `[1, 1, 2, 3, 3]` (maps to SMALL, SMALL, MEDIUM, LARGE, LARGE)
- Shape preset: Loaded from `res://assets/presets/shape_presets.json` (Square, Continent, Island Chain, Coastline, Trench)

**Parameters Emitted:**
- `"seed"` → `world.seed` (int)
- `"size_preset"` → `world.size_preset` (SizePreset enum)
- `"shape_preset"` → `world.params["shape_preset"]` (String, key from JSON)

---

#### 5. `terrain_section.gd`
**Path:** `res://scripts/ui/terrain_section.gd`  
**Type:** `extends PanelContainer`  
**Purpose:** Terrain generation parameters

**Key Controls:**
- `elevation_scale_slider/spinbox` - Elevation scale (0-100)
- `terrain_chaos_slider/spinbox` - Terrain randomness (0-100, converted to 0-1.0)
- `domain_warp_strength_slider/spinbox` - Domain warping strength (0-100)
- `domain_warp_freq_slider` - Domain warping frequency (0.001-0.1)
- `enable_erosion_checkbox` - Enable erosion simulation (Phase 2)
- `erosion_strength_slider/spinbox` - Erosion strength (0-100, converted to 0.0-1.0)
- `erosion_iterations_spinbox` - Erosion iterations (1-10)
- `noise_type_option` - Noise algorithm (Perlin, Simplex, Cellular, Value)
- `enable_rivers_checkbox` - River generation toggle (Phase 2)
- `size_preset_option` - Size preset (duplicate of seed_size for convenience)

**Parameters Emitted:**
- `"elevation_scale"` → `world.params["elevation_scale"]` and `world.params["elevation"]`
- `"terrain_chaos"` → `world.randomness["terrain"]` (converted 0-100 to 0-1.0)
- `"domain_warp_strength"` → `world.params["domain_warp_strength"]` (0-100)
- `"domain_warp_frequency"` → `world.params["domain_warp_frequency"]` (0.001-0.1)
- `"enable_erosion"` → `world.params["enable_erosion"]` (Phase 2)
- `"erosion_strength"` → `world.params["erosion_strength"]` (0.0-1.0, Phase 2)
- `"erosion_iterations"` → `world.params["erosion_iterations"]` (1-10, Phase 2)
- `"noise_type"` → `world.params["noise_type"]`
- `"enable_rivers"` → `world.params["enable_rivers"]` (Phase 2)

---

#### 5b. `civilization_section.gd`
**Path:** `res://scripts/ui/civilization_section.gd`  
**Type:** `extends PanelContainer`  
**Purpose:** Civilization, population, settlements, foliage, and POI parameters (Phase 3)

**Key Controls:**
- `population_density_slider/spinbox` - Population density (0-100)
- `city_count_slider/spinbox` - City count (0-50)
- `village_density_slider/spinbox` - Village density (0-100)
- `civilization_type_option` - Civilization type (Medieval, Ancient, Renaissance, Steampunk, Magical)
- `enable_foliage_checkbox` - Enable foliage generation (Phase 3)
- `foliage_density_slider/spinbox` - Foliage density (0-100, converted to 0.0-1.0, Phase 3)
- `foliage_variation_slider` - Foliage variation (0-100, converted to 0.0-1.0, Phase 3)
- `enable_cities_checkbox` - Enable city POI placement (Phase 3)
- `enable_towns_checkbox` - Enable town POI placement (Phase 3)
- `enable_ruins_checkbox` - Enable ruin POI placement (Phase 3)
- `enable_resources_checkbox` - Enable resource node POI placement (Phase 3)
- `poi_density_slider` - POI density (0-100, converted to 0.0-1.0, Phase 3)
- `min_poi_distance_spinbox` - Minimum distance between POIs (10-500, default 80, Phase 3)

**Parameters Emitted:**
- `"population_density"` → `world.params["population_density"]`
- `"city_count"` → `world.params["city_count"]`
- `"village_density"` → `world.params["village_density"]`
- `"civilization_type"` → `world.params["civilization_type"]`
- `"enable_foliage"` → `world.params["enable_foliage"]` (Phase 3)
- `"foliage_density"` → `world.params["foliage_density"]` (0.0-1.0, Phase 3)
- `"foliage_variation"` → `world.params["foliage_variation"]` (0.0-1.0, Phase 3)
- `"enable_cities"` → `world.params["enable_cities"]` (Phase 3)
- `"enable_towns"` → `world.params["enable_towns"]` (Phase 3)
- `"enable_ruins"` → `world.params["enable_ruins"]` (Phase 3)
- `"enable_resources"` → `world.params["enable_resources"]` (Phase 3)
- `"poi_density"` → `world.params["poi_density"]` (0.0-1.0, Phase 3)
- `"min_poi_distance"` → `world.params["min_poi_distance"]` (int, Phase 3)

---

### Supporting Systems

#### 6. `BiomeTextureManager.gd` (Phase 5)
**Path:** `res://scripts/world_creation/BiomeTextureManager.gd`  
**Type:** `class_name BiomeTextureManager extends RefCounted`  
**Purpose:** Static utility class for loading and managing biome textures

**Key Static Variables:**
- `texture_cache: Dictionary` - Cached biome textures (biome name -> Texture2D)
- `normal_cache: Dictionary` - Cached normal maps (biome name -> Texture2D)
- `biome_config: Dictionary` - Loaded biome texture configuration from JSON

**Key Static Functions:**
- `load_config() -> bool` - Load biome texture configuration from `res://assets/data/biome_textures.json`
- `get_texture(biome_name: String) -> Texture2D` - Get texture for a biome (with caching)
- `get_normal_map(biome_name: String) -> Texture2D` - Get normal map for a biome (optional)
- `get_biome_color(biome_name: String) -> Color` - Get default color for a biome
- `get_splat_channel(biome_name: String) -> int` - Get splat channel index (0-3) for a biome
- `get_all_biome_names() -> Array[String]` - Get list of all biome names from config

**Configuration File:**
- **Path:** `res://assets/data/biome_textures.json`
- **Structure:** Maps biome names to texture paths, normal maps, colors, and splat channels
- **Usage:** Loaded automatically on first access, cached for performance

---

#### 7. `PreviewManager.gd`
**Path:** `res://scripts/preview/PreviewManager.gd`  
**Type:** `class_name PreviewManager extends Node`  
**Purpose:** Visual fantasy style effects manager

**Key Variables:**
- `terrain_mesh_instance: MeshInstance3D` - Terrain mesh reference
- `particles: GPUParticles3D` - Magic particle system
- `environment: WorldEnvironment` - Environment settings
- `camera: Camera3D` - Camera reference

**Key Functions:**
- `apply_fantasy_style_instant(data: Dictionary)` - Apply style effects:
  - Skybox (PanoramaSkyMaterial)
  - Particles (GPUParticles3D with color/density)
  - Bloom (Environment glow_intensity)
  - Fog (Environment fog_density)
  - Tint (ShaderMaterial tint_color parameter)

**Group:** `"preview_manager"` - Found via `get_nodes_in_group()`

---

#### 8. `ExportUtils.gd`
**Path:** `res://scripts/utils/export_utils.gd`  
**Type:** `class_name ExportUtils extends RefCounted`  
**Purpose:** World export utilities

**Static Functions:**
- `export_godot_scene(world_data, output_path: String) -> Error` - Export as .tscn + .tres mesh
- `export_obj(world_data, output_path: String) -> Error` - Export as OBJ file
- `export_pdf_atlas(world_data, output_path: String, viewport_screenshot_path: String) -> Error` - Export as PDF (requires wkhtmltopdf)
- `generate_markdown_atlas(world_data, viewport_screenshot_path: String) -> String` - Generate markdown content
- `export_complete_atlas(world_data, output_folder: String) -> Error` - Phase 5: Export complete atlas to folder (includes textures, meshes, metadata)

---

#### 8. `GameData.gd` (Singleton)
**Path:** `res://scripts/singletons/GameData.gd`  
**Type:** `extends Node` (autoload)  
**Purpose:** Central data storage

**Key Variables:**
- `current_world_data: Dictionary` - Stores world data for character creation:
  ```gdscript
  {
      "world": WorldData,
      "seed": int,
      "size_preset": int
  }
  ```

**Usage:** WorldCreator stores world data here before transitioning to character creation.

---

### Data Resources

#### 9. `default_world.tres`
**Path:** `res://assets/worlds/default_world.tres`  
**Type:** `WorldData` Resource  
**Purpose:** Default world template

**Default Values:**
- `seed = 0`
- `size_preset = 2` (MEDIUM/512)
- `preview_resolution = 1` (SMALL/256)
- `generate_in_background = true`
- `params = {
    "domain_warp_strength": 0.0,
    "domain_warp_frequency": 0.005,
    "domain_warp_amplitude": 30.0,
    "enable_erosion": false,
    "erosion_strength": 0.5,
    "erosion_iterations": 5,
    "shape_preset": "Square"
}` (Phase 1: Domain warping, Phase 2: Erosion parameters, Shape presets with defaults)
- `randomness = {}` (empty, populated in `load_world_defaults()`)
- `biome_metadata = []`

---

#### 11. Shape Presets

**Path:** `res://assets/presets/shape_presets.json`  
**Purpose:** Map shape presets that apply procedural masks to heightmaps

**Available Presets:**
- `"Square"` - No mask (rectangular boundaries, default behavior)
- `"Continent"` - Single central radial falloff with soft edges (radius_factor: 0.8, falloff_sharpness: 2.0)
- `"Island Chain"` - Multiple random centers with smaller radial masks (3-6 centers, radius_factor: 0.2-0.4, falloff_sharpness: 3.0)
- `"Coastline"` - Linear gradient from one edge simulating a shore (direction: "x", start_pos: 0.0, falloff_width: 0.3)
- `"Trench"` - Inverted radial mask for valleys/depressions (2 centers, radius_factor: 0.5, falloff_sharpness: 1.5)

**Mask Application:**
- Masks are applied in `_apply_shape_mask()` after base heightmap generation
- Masks multiply heightmap values (0.0-1.0) to fade to sea level at edges
- Very low mask values (< 0.1) clamp height to sea level (0.0)
- Mask centers use seed-based RNG for consistent placement across regenerations
- Island Chain shape increases humidity randomness in `auto_propagate()`

**Integration:**
- Stored in `world.params["shape_preset"]` (String)
- Included in cache key for proper heightmap caching
- UI control: `seed_size_section.gd` → `shape_option` OptionButton

---

#### 11. Fantasy Style Presets

**Hardcoded Styles (in `world.gd`):**
- `"High Fantasy"` - Elevated terrain, floating islands, blue particles, high bloom
- `"Mythic Fantasy"` - Higher elevation, golden particles, very high bloom
- `"Grimdark"` - Lower elevation, high chaos, dark red particles, low bloom, high fog
- `"Weird Fantasy"` - Extreme elevation range, high chaos, purple particles, very high bloom

**JSON-Based Styles (fallback):**
- `res://assets/presets/fantasy_styles.json` - Additional styles (Low Fantasy, Dark Fantasy, Sword and Sorcery, etc.)

**Style Data Structure:**
```gdscript
{
    "elevation": [min: float, max: float],
    "frequency": [min: float, max: float],
    "octaves": int,
    "lacunarity": float,
    "gain": float,
    "chaos": float,
    "floating_islands": bool,
    "particle_color": Color,
    "particle_density": int,
    "skybox": String (path),
    "bloom_intensity": float,
    "fog_density": float,
    "tint": Color
}
```

---

## Data Flows

### Initialization Flow

1. **Scene Load:**
   - `WorldCreator.tscn` loads → `WorldCreator._ready()` executes

2. **World Initialization:**
   ```gdscript
   if not world:
       world = DEFAULT_WORLD.duplicate()  # Load default_world.tres
   ```

3. **Default Parameters:**
   ```gdscript
   load_world_defaults()  # Sets world.params and world.randomness
   ```

4. **UI Setup:**
   - `setup_tabs()` - Connect tab buttons
   - `setup_sections()` - Store section scene paths
   - `setup_preview_controls()` - Connect world signals
   - `setup_fantasy_style_selector()` - Populate style dropdown

5. **Initial Section Load:**
   ```gdscript
   _on_tab_selected(0)  # Load seed_size_section
   ```

6. **Initial Generation:**
   ```gdscript
   update_preview()  # Calls world.generate(false) - preview resolution
   ```

---

### Parameter Change Flow

1. **User Input:**
   - User changes slider/spinbox/option in section UI

2. **Section Signal:**
   ```gdscript
   section.param_changed.emit("elevation_scale", 45.0)
   ```

3. **WorldCreator Handler:**
   ```gdscript
   _on_param_changed(param: String, value: Variant)
   ```
   - Updates `world.params` or `world.randomness`
   - Special handling for `seed`, `size_preset`, `elevation_scale`, `terrain_chaos`
   - Generic handler for all other params (including `shape_preset`, `domain_warp_strength`, `domain_warp_frequency`, `enable_erosion`, `erosion_strength`, `erosion_iterations`, `enable_rivers`, `enable_foliage`, `foliage_density`, `foliage_variation`, `enable_cities`, `enable_towns`, `enable_ruins`, `enable_resources`, `poi_density`, `min_poi_distance`)

4. **Auto-Propagation:**
   ```gdscript
   world.auto_propagate()  # One-way: terrain → climate
   ```

5. **Debounced Regeneration:**
   ```gdscript
   queue_regeneration()  # Starts 0.3s timer
   ```

6. **Timer Timeout:**
   ```gdscript
   _on_regeneration_timer_timeout()
   world.generate(false)  # Preview resolution
   ```

---

### Generation Pipeline

1. **Generation Start:**
   ```gdscript
   world.generate(force_full_res: bool)
   ```
   - Creates `Thread` and `Mutex`
   - Starts `_generate_threaded()` in background

2. **Threaded Generation (`_generate_threaded()`):**
   
   **Progress Tracking:** 8 major phases (0% → 100%)

   **a. Resolution Selection:**
   ```gdscript
   var target_preset = size_preset if force_full_res else preview_resolution
   var grid_size = target_preset as int  # 64, 256, 512, 1024, or 2048
   var world_size = Vector2i(grid_size, grid_size)
   var vert_grid_size = Vector2i(world_size.x * VERTS_PER_UNIT, world_size.y * VERTS_PER_UNIT)
   ```

   **b. Noise Setup:**
   ```gdscript
   var noise = FastNoiseLite.new()
   noise.seed = seed
   noise.noise_type = params.get("noise_type", "Perlin")
   noise.frequency = base_frequency * (1.0 + terrain_chaos)
   # Optional fractal settings
   if params.get("use_fractal", false):
       noise.fractal_type = FastNoiseLite.FRACTAL_FBM
       noise.fractal_octaves = params.get("fractal_octaves", 4)
   
   # Domain warping (Phase 1)
   var domain_warp_strength = params.get("domain_warp_strength", 0.0)
   if domain_warp_strength > 0.0:
       noise.domain_warp_enabled = true
       noise.domain_warp_amplitude = params.get("domain_warp_amplitude", 30.0)
       noise.domain_warp_frequency = params.get("domain_warp_frequency", 0.005)
       noise.domain_warp_amplitude *= (domain_warp_strength / 100.0)  # Scale by strength
   else:
       noise.domain_warp_enabled = false
   ```

   **c. Heightmap Generation:**
   ```gdscript
   var heightmap_image = noise.get_image(vert_grid_size.x, vert_grid_size.y)
   # Convert to heightmap array
   for y in range(vert_grid_size.y):
       for x in range(vert_grid_size.x):
           var pixel = heightmap_image.get_pixel(x, y)
           var noise_value = (pixel.r * 2.0) - 1.0  # 0-1 → -1 to 1
           var height = noise_value * elevation_scale * chaos_multiplier
           heightmap[y * vert_grid_size.x + x] = height
   ```
   
   **c2. Shape Preset Mask Application:**
   ```gdscript
   var shape_preset = params.get("shape_preset", "Square")
   if shape_preset != "Square":
       heightmap = _apply_shape_mask(heightmap, vert_grid_size, shape_preset)
   ```
   - Loads mask configuration from `res://assets/presets/shape_presets.json`
   - Applies procedural masks to create organic, non-rectangular boundaries
   - Mask types: `radial`, `multi_radial`, `linear`, `inverted_radial`, `none`
   - Masks fade heights to sea level (0.0) at edges or in specific patterns
   - Applied after base heightmap generation, before erosion/rivers
   
   **d. Erosion Application (Phase 2):**
   ```gdscript
   if params.get("enable_erosion", false):
       var erosion_strength = params.get("erosion_strength", 0.5)
       var erosion_iterations = params.get("erosion_iterations", 5)
       var ErosionGen = load("res://scripts/world_creation/ErosionGenerator.gd")
       heightmap = ErosionGen.apply_erosion(heightmap, vert_grid_size, erosion_strength, erosion_iterations)
   ```
   - Thermal erosion: Slope-based material movement
   - Hydraulic erosion: Water particle simulation with erosion/deposition
   
   **e. River Generation (Phase 2):**
   ```gdscript
   if params.get("enable_rivers", false):
       var RiverGen = load("res://scripts/world_creation/RiverGenerator.gd")
       river_paths = RiverGen.generate_rivers(heightmap, vert_grid_size, true)  # Carve into heightmap
   ```
   - Uses AStar2D pathfinding from high to low elevation
   - Generates tributaries branching from main rivers
   - Carves river channels into heightmap
   - Calculates flow accumulation for river width

   **d. Mesh Generation (Line-Based Network):**
   ```gdscript
   var st = SurfaceTool.new()
   st.begin(Mesh.PRIMITIVE_LINES)
   
   # Generate vertices
   for y in range(vert_grid_size.y):
       for x in range(vert_grid_size.x):
           var pos_x = x * horizontal_scale - half_width
           var pos_z = y * horizontal_scale - half_height
           var vertex_pos = Vector3(pos_x, heightmap[idx], pos_z)
           st.set_uv(Vector2(uv_x, uv_y))
           st.add_vertex(vertex_pos)
   
   # Generate lines: horizontal, vertical, and diagonal
   # Horizontal lines
   for y in range(vert_grid_size.y):
       for x in range(vert_grid_size.x - 1):
           st.add_index(i)
           st.add_index(i + 1)
   
   # Vertical lines
   for y in range(vert_grid_size.y - 1):
       for x in range(vert_grid_size.x):
           st.add_index(i)
           st.add_index(i + vert_grid_size.x)
   
   # Diagonal lines (both diagonals per quad)
   for y in range(vert_grid_size.y - 1):
       for x in range(vert_grid_size.x - 1):
           st.add_index(i)  # top-left
           st.add_index(i + vert_grid_size.x + 1)  # bottom-right
           st.add_index(i + 1)  # top-right
           st.add_index(i + vert_grid_size.x)  # bottom-left
   
   var new_mesh = st.commit()
   ```

   **f. Biome Assignment:**
   ```gdscript
   _assign_biomes(heightmap, vert_grid_size)
   ```
   - Phase 2: Marks river cells with `is_river: true` and `river_width: float` in biome metadata

   **g. Foliage Generation (Phase 3):**
   ```gdscript
   var FoliageGen = load("res://scripts/world_creation/FoliageGenerator.gd")
   if FoliageGen:
       FoliageGen.generate_foliage_density(self)
   ```
   - Generates per-cell foliage density based on biome type and noise variation
   - Stores result in `world_data.foliage_density` (Array of floats, 0.0-1.0)

   **h. POI Generation (Phase 3):**
   ```gdscript
   var POIGen = load("res://scripts/world_creation/POIGenerator.gd")
   if POIGen:
       POIGen.generate_pois(self)
   ```
   - Places cities, towns, ruins, and resource nodes
   - Respects biome suitability and minimum distance rules
   - Stores result in `world_data.poi_metadata` (Array of POI dictionaries)

   **i. Mesh Update (Thread-Safe):**
   ```gdscript
   generation_mutex.lock()
   generated_mesh = new_mesh
   generation_mutex.unlock()
   ```

   **j. Phase 5: Generate Texture Maps (97.5% → 98.75%):**
   ```gdscript
   _generate_splatmap(vert_grid_size)  # Biome splatmap (RGBA channels)
   _generate_river_map(vert_grid_size)  # River overlay map
   _generate_foliage_density_texture(vert_grid_size)  # Foliage density map
   ```

   **k. Completion Signal:**
   ```gdscript
   call_deferred("_on_generation_complete")  # Main thread
   ```

3. **Main Thread Completion:**
   ```gdscript
   _on_generation_complete()
   ```
   - Validates mesh
   - Emits `generation_complete` signal

4. **Preview Update:**
   ```gdscript
   WorldCreator._on_generation_complete()
   world_preview.update_mesh(world.generated_mesh)
   ```

---

### Biome Assignment Flow

1. **Heightmap Normalization:**
   ```gdscript
   var min_height = min(heightmap)
   var max_height = max(heightmap)
   var height_range = max_height - min_height
   var normalized_height = (heightmap[idx] - min_height) / height_range
   ```

2. **Climate Noise:**
   ```gdscript
   var humidity_noise = FastNoiseLite.new()
   humidity_noise.seed = seed + 1000
   humidity_noise.frequency = 0.02
   
   var temp_noise = FastNoiseLite.new()
   temp_noise.seed = seed + 2000
   temp_noise.frequency = 0.015
   ```

3. **Local Climate:**
   ```gdscript
   var local_humidity = (humidity_noise.get_noise_2d(x, y) + 1.0) * 0.5
   local_humidity = (local_humidity * 0.5 + global_humidity * 0.5)
   
   var local_temp = temp_noise.get_noise_2d(x, y) * 20.0 + global_temperature
   local_temp -= normalized_height * 30.0  # Higher = colder
   ```

4. **Biome Determination:**
   ```gdscript
   _determine_biome(normalized_height, local_humidity, local_temp)
   ```
   - Returns: `{biome, temperature, monsters, magic_level, humidity, temp_value}`

5. **Biome Metadata Storage:**
   ```gdscript
   biome_metadata.append({
       "biome": "forest",
       "temperature": "temperate",
       "monsters": ["goblin", "wolf", "dire_bear"],
       "magic_level": "high",
       "humidity": 0.7,
       "temp_value": 15.0,
       "x": x,
       "y": y
   })
   ```

---

### Style Preset Flow

1. **User Selection:**
   ```gdscript
   fantasy_style_selector.item_selected(index)
   ```

2. **Style Load:**
   ```gdscript
   world.load_style_preset(style_name)
   ```

3. **Parameter Application:**
   ```gdscript
   params["elevation_scale"] = randf_range(style["elevation"][0], style["elevation"][1])
   params["frequency"] = randf_range(style["frequency"][0], style["frequency"][1])
   params["use_fractal"] = true
   params["fractal_octaves"] = style["octaves"]
   randomness["terrain"] = style["chaos"]
   ```

4. **Visual Effects:**
   ```gdscript
   call_deferred("_apply_visual_style", style_data)
   # Finds PreviewManager via group
   preview_manager.apply_fantasy_style_instant(style_data)
   ```

5. **Material Update:**
   ```gdscript
   emit_signal("style_applied", style_name, style_tint, style_invert)
   # WorldCreator receives signal
   shader_material.set_shader_parameter("tint_color", color_tint)
   ```

6. **Regeneration:**
   ```gdscript
   auto_propagate()
   generate()  # Regenerate with new parameters
   ```

---

## Procedural Logic

### Noise Generation

**Algorithm:** FastNoiseLite (Godot built-in)

**Noise Types:**
- `TYPE_PERLIN` - Smooth, organic patterns
- `TYPE_SIMPLEX` - Smoother than Perlin, less artifacts
- `TYPE_CELLULAR` - Cell-like, Voronoi-like patterns
- `TYPE_VALUE` - Blocky, grid-like patterns

**Fractal Settings (when enabled):**
- `FRACTAL_FBM` - Fractional Brownian Motion
- `fractal_octaves` - Detail layers (default: 4, style presets: 8-12)
- `fractal_lacunarity` - Frequency multiplier per octave (default: 2.0, style presets: 2.3-4.0)
- `fractal_gain` - Amplitude multiplier per octave (default: 0.5, style presets: 0.55-0.85)

**Domain Warping (Phase 1):**
- `domain_warp_enabled` - Enable/disable domain warping (auto-enabled when strength > 0)
- `domain_warp_strength` - Warping strength (0-100, UI control, default: 0.0)
- `domain_warp_frequency` - Warping frequency (0.001-0.1, UI control, default: 0.005)
- `domain_warp_amplitude` - Base warping amplitude (default: 30.0, scaled by strength percentage)
- **Effect:** Creates organic, flowing terrain patterns by distorting noise coordinates before sampling

**Erosion Simulation (Phase 2):**
- `enable_erosion` - Enable/disable erosion (default: false)
- `erosion_strength` - Erosion strength (0.0-1.0, from UI 0-100, default: 0.5)
- `erosion_iterations` - Number of erosion passes (1-10, default: 5)
- **Thermal Erosion:** Material moves downhill when slope exceeds talus angle (~28 degrees)
- **Hydraulic Erosion:** Water particles erode and deposit sediment based on velocity and capacity
- **Effect:** Creates valleys, canyons, and smoother terrain through natural weathering simulation

**River Systems (Phase 2):**
- `enable_rivers` - Enable/disable river generation (default: false)
- **Pathfinding:** Uses AStar2D to find paths from high to low elevation
- **Flow Accumulation:** Tracks how many rivers pass through each cell to determine width
- **Tributaries:** Generates branching rivers from main paths
- **Carving:** Subtracts depth from heightmap to create river channels
- **Effect:** Creates realistic river networks that follow terrain gradients

**Foliage Density (Phase 3):**
- `enable_foliage` - Enable/disable foliage generation (default: true)
- `foliage_density` - Base foliage density (0.0-1.0, from UI 0-100, default: 0.6)
- `foliage_variation` - Noise variation amount (0.0-1.0, from UI 0-100, default: 0.4)
- **Biome-Based:** Different biomes have different base densities (forest: high, desert: low)
- **Noise Variation:** Adds organic variation within biomes using FastNoiseLite
- **Effect:** Creates realistic vegetation distribution that matches biome types

**Point-of-Interest Placement (Phase 3):**
- `enable_cities/towns/ruins/resources` - Enable/disable specific POI types (default: all true)
- `poi_density` - Overall POI density (0.0-1.0, from UI 0-100, default: 0.3)
- `min_poi_distance` - Minimum distance between POIs (10-500, default: 80)
- **Placement Algorithm:** Poisson disk sampling with biome suitability filtering
- **POI Types:** Cities (large), Towns (medium), Ruins (ancient), Resources (biome-specific)
- **Effect:** Populates world with named settlements, landmarks, and resource nodes

**Frequency Calculation:**
```gdscript
var base_frequency = params.get("frequency", 0.01)
var terrain_chaos = randomness.get("terrain", 0.0)
noise.frequency = base_frequency * (1.0 + terrain_chaos)
```

**Height Calculation:**
```gdscript
var noise_value = (pixel.r * 2.0) - 1.0  # Convert 0-1 to -1 to 1
var elevation_scale = params.get("elevation_scale", 30.0)
var chaos_multiplier = 1.0 + terrain_chaos
var height = noise_value * elevation_scale * chaos_multiplier
height = clamp(height, -elevation_scale * 1.5, elevation_scale * 1.5)
```

---

### Biome Assignment Logic

**Input Parameters:**
- `height: float` - Normalized height (0.0 to 1.0)
- `humidity: float` - Local humidity (0.0 to 1.0)
- `temp: float` - Local temperature (°C, typically -50 to 50)

**Biome Decision Tree:**

```
if temp < -10:
    biome = "tundra"
    temp_category = "arctic"
    monsters = ["frost_giant", "winter_wolf", "yeti"]
    magic_level = "low"
elif temp < 5:
    temp_category = "cold"
    if humidity > 0.6:
        biome = "taiga"
        monsters = ["bear", "wolf", "elk"]
    else:
        biome = "cold_desert"
        monsters = ["camel", "scorpion"]
    magic_level = "low"
elif temp > 30:
    temp_category = "hot"
    if humidity > 0.4:
        biome = "jungle"
        monsters = ["panther", "snake", "ape"]
        magic_level = "high"
    else:
        biome = "desert"
        monsters = ["scorpion", "camel", "vulture"]
        magic_level = "low"
else:
    temp_category = "temperate"
    if height > 0.7:
        biome = "mountain"
        monsters = ["eagle", "goat", "dragon"]
        magic_level = "high"
    elif height < 0.2:
        if humidity > 0.7:
            biome = "swamp"
            monsters = ["lizardfolk", "crocodile", "will_o_wisp"]
            magic_level = "medium"
        else:
            biome = "coast"
            monsters = ["crab", "seagull"]
            magic_level = "low"
    elif humidity > 0.6:
        biome = "forest"
        monsters = ["goblin", "wolf", "dire_bear"]
        magic_level = "high"
    elif humidity > 0.3:
        biome = "grassland"
        monsters = ["deer", "rabbit", "horse"]
        magic_level = "medium"
    else:
        biome = "plains"
        monsters = ["rabbit", "coyote"]
        magic_level = "low"
```

**Biome Metadata Structure:**
```gdscript
{
    "biome": String,           # "forest", "desert", "mountain", etc.
    "temperature": String,      # "arctic", "cold", "temperate", "hot"
    "monsters": Array[String],  # List of monster types
    "magic_level": String,      # "low", "medium", "high"
    "humidity": float,          # 0.0 to 1.0
    "temp_value": float,        # Actual temperature in °C
    "x": int,                   # Grid X coordinate
    "y": int,                   # Grid Y coordinate
    "is_river": bool,           # Phase 2: True if cell is on a river path
    "river_width": float        # Phase 2: River width at this cell (0.0 if not river)
}
```

---

### Auto-Propagation Logic

**Shape Preset Effects:**
- `"Island Chain"` shape increases humidity randomness by +0.2 (clamped to 1.0)
- Applied in `auto_propagate()` after terrain-based climate adjustments

**One-Way Dependencies:** Terrain → Climate (no reverse)

**Propagation Rules:**

1. **Elevation → Temperature:**
   ```gdscript
   if avg_elevation > 50.0:
       var temp_adjustment = (avg_elevation - 50.0) * 0.4
       params["temperature"] = max(current_temp - temp_adjustment, -50.0)
   ```

2. **Terrain Chaos → Climate Randomness:**
   ```gdscript
   if terrain_chaos > 0.7:
       randomness["climate"] = min(randomness.get("climate", 0.3) + 0.2, 1.0)
   ```

3. **Humidity → Precipitation:**
   ```gdscript
   if humidity > 70.0:
       params["precipitation"] = min(current_precip + (humidity - 70.0) * 0.5, 100.0)
   elif humidity < 30.0:
       params["precipitation"] = max(current_precip - (30.0 - humidity) * 0.5, 0.0)
   ```

4. **Temperature → Biome Weights:**
   ```gdscript
   if temperature < -10.0:
       params["biome_cold_weight"] = 1.0
       params["biome_temperate_weight"] = 0.3
       params["biome_hot_weight"] = 0.0
   elif temperature > 30.0:
       params["biome_cold_weight"] = 0.0
       params["biome_temperate_weight"] = 0.3
       params["biome_hot_weight"] = 1.0
   else:
       params["biome_cold_weight"] = 0.5
       params["biome_temperate_weight"] = 1.0
       params["biome_hot_weight"] = 0.5
   ```

5. **Shape Preset → Climate Randomness:**
   ```gdscript
   var shape_preset = params.get("shape_preset", "Square")
   if shape_preset == "Island Chain":
       randomness["humidity"] = min(randomness.get("humidity", 0.0) + 0.2, 1.0)
   ```
   - Island Chain shape increases humidity randomness by +0.2 (clamped to 1.0)
   - Simulates increased climate variation in island environments

---

### Mesh Generation Details

**Primitive Type:** `Mesh.PRIMITIVE_LINES` (network visualization)

**Vertex Grid:**
- Base grid: `world_size × world_size` (e.g., 512×512)
- Vertex grid: `world_size × VERTS_PER_UNIT` (e.g., 512×8 = 4096×4096 vertices)
- Horizontal spacing: `HORIZONTAL_SCALE` (4.0 world units)

**Line Connections:**
- **Horizontal lines:** `(vert_grid_size.x - 1) × vert_grid_size.y`
- **Vertical lines:** `(vert_grid_size.y - 1) × vert_grid_size.x`
- **Diagonal lines:** `(vert_grid_size.x - 1) × (vert_grid_size.y - 1) × 2` (both diagonals per quad)
- **Total lines:** `horizontal + vertical + diagonal`

**UV Coordinates:**
```gdscript
var uv_x = float(x) / float(vert_grid_size.x - 1) if vert_grid_size.x > 1 else 0.0
var uv_y = float(y) / float(vert_grid_size.y - 1) if vert_grid_size.y > 1 else 0.0
```

**Centering:**
```gdscript
var half_width = (vert_grid_size.x - 1) * horizontal_scale * 0.5
var half_height = (vert_grid_size.y - 1) * horizontal_scale * 0.5
var pos_x = x * horizontal_scale - half_width
var pos_z = y * horizontal_scale - half_height
```

---

## Integration Points

### Mesh Generation Integration

**Reference:** See `MESH_GENERATION_AUDIT_REPORT.md` for detailed mesh generation documentation.

**Integration Points:**
1. **Mesh Output:** `world.generated_mesh` (ArrayMesh with PRIMITIVE_LINES)
2. **Preview Update:** `world_preview.update_mesh(mesh)` receives mesh
3. **Shader Application:** `world_preview._apply_world_shader(mesh)` applies world preview shader (Phase 5) or falls back to topo shader
4. **Heightmap Texture:** `world_preview._generate_heightmap_texture(mesh)` creates texture from vertex data

**Shader Integration (Phase 5):**
- **Primary Shader Path:** `res://assets/shaders/world_preview.gdshader` (Phase 5: Texture splatting)
- **Fallback Shader Path:** `res://assets/shaders/topo_preview.gdshader` (Legacy topo preview)
- **Material Path:** `res://assets/materials/topo_preview_shader.tres` (Legacy)
- **Phase 5 Shader Parameters:**
  - `heightmap: Texture2D` - Generated from mesh vertices
  - `splatmap: Texture2D` - Biome splatmap (RGBA = 4 biome channels)
  - `river_map: Texture2D` - River overlay map
  - `foliage_density_map: Texture2D` - Foliage density map
  - `biome_texture_0` through `biome_texture_N: Texture2D` - Biome textures loaded via BiomeTextureManager
  - `preview_mode: int` - Preview mode enum (topographic, biome heatmap, foliage density, etc.)
  - `tint_color: Vector3` - Style preset color tint
  - `use_texture_splatting: bool` - Enable texture splatting
  - `use_normal_mapping: bool` - Enable normal mapping for terrain detail
- **Legacy Shader Parameters:**
  - `heightmap: Texture2D` - Generated from mesh vertices
  - `tint_color: Color` - Style preset color tint
  - `invert_normals: bool` - Dark fantasy style flag
  - `time: float` - Animation time (for wavy effects)

---

### Preview System Integration

**Scene Hierarchy:**
```
WorldCreator.tscn
└── VBoxContainer
    └── HBoxContainer
        └── CenterPreview
            └── WorldPreviewViewport (SubViewport)
                └── WorldPreviewRoot (Node3D)
                    ├── terrain_mesh (MeshInstance3D)
                    ├── biome_overlay (MeshInstance3D)
                    ├── Camera3D
                    ├── node_points_cyan (MultiMeshInstance3D)
                    ├── node_points_orange (MultiMeshInstance3D)
                    └── PreviewManager (Node)
```

**PreviewManager Integration:**
- Found via `get_nodes_in_group("preview_manager")`
- Applies visual effects: skybox, particles, bloom, fog, tint
- Called from `world._apply_visual_style()` via `call_deferred()`

**Camera Controls:**
- Orbit: Mouse drag (left button)
- Zoom: Mouse wheel
- Auto-fit: Called on mesh update (`auto_fit_camera()`)

---

### Style System Integration

**Style Application Flow:**
1. `WorldCreator._on_fantasy_style_selected(index)` → `world.load_style_preset(style_name)`
2. `world.load_style_preset()` → Updates `params` and `randomness`
3. `world._apply_visual_style()` → Finds `PreviewManager` → `apply_fantasy_style_instant(data)`
4. `world.emit_signal("style_applied", ...)` → `WorldCreator._on_style_applied()` → Updates shader material
5. `world.generate()` → Regenerates terrain with new parameters

**Visual Effects:**
- **Skybox:** `PanoramaSkyMaterial` with HDR texture
- **Particles:** `GPUParticles3D` with ring emission, color, density
- **Bloom:** `Environment.glow_intensity`
- **Fog:** `Environment.fog_density`
- **Tint:** `ShaderMaterial.tint_color` parameter

---

### Save/Load Integration

**Save Flow:**
1. User clicks "Save" → `WorldCreator._on_save_world()`
2. FileDialog opens → `user://worlds/` directory
3. User selects path → `_save_world_to_path(path)`
4. Creates world folder: `user://worlds/{world_name}/`
5. Saves binary resource: `{world_folder}/data.gworld`
6. Saves JSON backup: `{world_folder}/data.json`
7. Creates `assets/` and `previews/` subfolders

**Load Flow:**
1. User clicks "Load" → `WorldCreator._on_load_world()`
2. FileDialog opens → `user://worlds/` directory
3. User selects `.gworld` file → `_load_world_from_path(path)`
4. `world = load(path)` → Loads WorldData resource
5. `_load_section(current_tab)` → Updates UI with loaded params
6. `queue_regeneration()` → Regenerates preview

**Export Integration:**
- **Godot Scene:** `ExportUtils.export_godot_scene()` → Creates `.tscn` + `_mesh.tres`
- **OBJ:** `ExportUtils.export_obj()` → Creates `.obj` file
- **PDF Atlas:** `ExportUtils.export_pdf_atlas()` → Creates `.pdf` with markdown content (requires wkhtmltopdf)

---

### Character Creation Integration

**World Data Transfer:**
1. User clicks "Generate World" → `WorldCreator._on_generate_world_pressed()`
2. `world.generate(true)` → Full resolution generation
3. `await world.generation_complete` → Wait for completion
4. Store in `GameData`:
   ```gdscript
   GameData.current_world_data = {
       "world": world,
       "seed": world.seed,
       "size_preset": world.size_preset
   }
   ```
5. `get_tree().change_scene_to_file(CHARACTER_CREATION_SCENE)` → Transition

**Character Creation Access:**
- `GameData.current_world_data["world"]` → Full WorldData resource
- `GameData.current_world_data["seed"]` → World seed
- `GameData.current_world_data["size_preset"]` → World size

---

## Potential Update Hooks

### Extension Points

1. **Biome System:**
   - **Location:** `world._determine_biome()`
   - **Hook:** Add custom biome types or modify decision tree
   - **Data Source:** Could load from JSON (`data/biomes.json`)

2. **Noise Algorithms:**
   - **Location:** `world._generate_threaded()` - Noise setup
   - **Hook:** Add custom noise types or additional warping techniques
   - **Current:** FastNoiseLite (Perlin, Simplex, Cellular, Value) with domain warping support (Phase 1)

3. **Erosion & River Systems:**
   - **Location:** `world._generate_threaded()` - After heightmap generation
   - **Hook:** Modify erosion algorithms or river pathfinding logic
   - **Current:** ErosionGenerator (thermal + hydraulic), RiverGenerator (AStar2D pathfinding) - Phase 2

4. **Foliage & POI Systems:**
   - **Location:** `world._generate_threaded()` - After biome assignment
   - **Hook:** Modify foliage density calculation or POI placement algorithms
   - **Current:** FoliageGenerator (biome-based density), POIGenerator (Poisson disk sampling) - Phase 3

3. **Mesh Primitive Types:**
   - **Location:** `world._generate_threaded()` - SurfaceTool setup
   - **Hook:** Switch from `PRIMITIVE_LINES` to `PRIMITIVE_TRIANGLES` for solid terrain
   - **Current:** Line-based network visualization

6. **Parameter Sections:**
   - **Location:** `WorldCreator.SECTION_SCENES` array
   - **Hook:** Add new section scenes (e.g., `magic_section.tscn`)
   - **Integration:** Add to `setup_sections()` and tab buttons

5. **Style Presets:**
   - **Location:** `world.load_style_preset()` - `STYLE_DATA` constant or JSON
   - **Hook:** Add new fantasy styles via JSON (`assets/presets/fantasy_styles.json`)
   - **Integration:** Add to `WorldCreator.setup_fantasy_style_selector()`

8. **Auto-Propagation Rules:**
   - **Location:** `world.auto_propagate()`
   - **Hook:** Add new propagation rules (e.g., humidity → vegetation density)
   - **Current:** One-way (terrain → climate)

7. **Export Formats:**
   - **Location:** `ExportUtils` static functions
   - **Hook:** Add new export formats (e.g., GLTF, STL, heightmap PNG)
   - **Current:** Godot scene, OBJ, PDF

10. **Biome Metadata:**
   - **Location:** `world._assign_biomes()` and `world._determine_biome()`
   - **Hook:** Add new metadata fields (e.g., `resource_nodes`)
   - **Current:** `{biome, temperature, monsters, magic_level, humidity, temp_value, x, y, is_river, river_width}` (Phase 2: Added river metadata)
   - **Phase 3:** Foliage density stored separately in `foliage_density` array, POIs stored in `poi_metadata` array

9. **Node Point System:**
   - **Location:** `world_preview._setup_node_points()` and `_update_node_points()`
   - **Hook:** Add more node types (e.g., red for danger zones, green for resources)
   - **Current:** Cyan (default) and Orange (10% highlights)

12. **Preview Shader:**
    - **Location:** `world_preview._apply_world_shader()` and `assets/shaders/world_preview.gdshader` (Phase 5)
    - **Fallback:** `world_preview._apply_topo_shader_fallback()` and `assets/shaders/topo_preview.gdshader` (Legacy)
    - **Hook:** Modify shader for different visualization styles (e.g., heatmap, contour lines, texture splatting)
    - **Current:** Phase 5 shader with texture splatting, biome textures, normal mapping, and preview mode switching
    - **Legacy:** Topo preview with cyan/orange highlights (fallback if textures unavailable)

---

### Future Enhancements

1. **Rivers System:**
   - **Status:** ✅ **Implemented (Phase 2)**
   - **Location:** `_generate_threaded()` after heightmap generation
   - **Algorithm:** AStar2D pathfinding from high to low elevation, carves river channels
   - **Features:** Tributaries, flow accumulation, river width calculation

2. **Civilization Placement:**
   - **Hook:** `civilization_section.tscn` exists but not fully integrated
   - **Location:** Add civilization node placement in `_generate_threaded()` or separate pass
   - **Algorithm:** Place cities/towns based on biome suitability, distance rules

3. **Resource Nodes:**
   - **Hook:** `resources_section.tscn` exists but not fully integrated
   - **Location:** Add resource node placement based on biome metadata
   - **Algorithm:** Assign resources per biome (e.g., forests → wood, mountains → ore)

4. **Multi-Threaded Biome Assignment:**
   - **Current:** Biome assignment runs on main thread after mesh generation
   - **Enhancement:** Move biome assignment to generation thread for better performance

5. **Progressive Generation:**
   - **Status:** ✅ **Implemented (Phase 4)**
   - **Location:** `world._generate_chunked()` and `world._generate_chunk()`
   - **Features:** Chunk-based generation for large worlds (MEDIUM/512+), incremental preview updates via `chunk_generated` signal

6. **Heightmap Caching:**
   - **Status:** ✅ **Implemented (Phase 4)**
   - **Location:** `world._get_cache_key()` and `world.heightmap_cache`
   - **Features:** Cache heightmap images per seed+terrain params hash, invalidate on terrain param changes, faster preview updates

7. **Biome Overlay Visualization:**
   - **Current:** `toggle_biome_overlay()` exists but basic implementation
   - **Enhancement:** Full biome color mapping with proper vertex-to-biome lookup

8. **Undo/Redo System:**
   - **Current:** No undo/redo for parameter changes
   - **Enhancement:** Add command pattern for parameter history

---

## Summary

The World Generation system is a comprehensive, data-driven procedural terrain generator with:

- **Threaded generation** for smooth UI during large world creation
- **Preview vs. full resolution** modes for responsive editing
- **Biome assignment** with rich metadata (monsters, magic levels, temperature)
- **Domain warping** (Phase 1) for organic, flowing terrain patterns
- **Erosion simulation** (Phase 2) with thermal and hydraulic erosion algorithms
- **River systems** (Phase 2) with AStar2D pathfinding and tributary generation
- **Foliage density** (Phase 3) with biome-based distribution and noise variation
- **POI placement** (Phase 3) with cities, towns, ruins, and resource nodes
- **LOD system** (Phase 4) with chunk-based generation and distance-based switching
- **Heightmap caching** (Phase 4) for faster preview updates
- **Progressive generation** (Phase 4) with incremental chunk updates
- **Visual pipeline** (Phase 5) with texture splatting, biome textures, and preview modes
- **Splatmap generation** (Phase 5) for biome blending (RGBA = 4 channels)
- **Texture maps** (Phase 5) for rivers, foliage density, and biome visualization
- **Fantasy style presets** with visual effects integration
- **Parameter auto-propagation** for realistic climate dependencies
- **Save/Load system** with folder-based persistence
- **Export capabilities** for multiple formats (including complete atlas export)
- **Integration** with character creation via GameData singleton

The system is designed for extensibility, with clear hooks for adding new biomes, styles, export formats, and generation features. Phase 1 (domain warping), Phase 2 (erosion & rivers), Phase 3 (foliage & POIs), Phase 4 (LOD & optimizations), and Phase 5 (visual pipeline & texture splatting) are fully implemented and integrated.

---

## Phase 4: LOD & Performance Optimizations

**Status:** ✅ **Implemented**  
**Date:** 2025-01-06

### Features

1. **Level-of-Detail (LOD) System:**
   - Chunk-based generation for large worlds (MEDIUM/512+)
   - Multiple LOD levels per chunk (LOD0: full res, LOD1: half, LOD2: quarter)
   - Distance-based LOD switching (configurable thresholds)
   - Seamless chunk rendering with proper positioning

2. **Heightmap Caching:**
   - Cache full heightmap per seed + terrain params hash
   - Dictionary-based storage in `WorldData.heightmap_cache`
   - Automatic cache invalidation on terrain-related param changes
   - Faster preview updates when only non-terrain params change

3. **Progressive Generation:**
   - Generate chunks one-by-one in thread
   - Emit `chunk_generated` signal per chunk for incremental preview updates
   - Progress tracking per chunk (0.0 to 1.0)
   - Support for abort/resume via `should_abort` flag

### New Components

**LODManager.gd:**
- **Path:** `res://scripts/world_creation/LODManager.gd`
- **Type:** `class_name LODManager extends RefCounted`
- **Purpose:** Static utility functions for LOD mesh creation and chunk management
- **Usage:** Must be preloaded in scripts that use it:
  ```gdscript
  const LODManager = preload("res://scripts/world_creation/LODManager.gd")
  ```
- **Key Functions:**
  - `create_lod_mesh(heightmap: Array[float], size: Vector2i, lod_level: int, horizontal_scale: float) -> Mesh` - Create mesh with specified LOD level
  - `downsample_heightmap(heightmap: Array[float], size: Vector2i, lod_level: int) -> Array[float]` - Downsample heightmap for lower LOD levels
  - `get_lod_for_distance(distance: float, lod_distances: Array[float]) -> int` - Get LOD level based on camera distance
  - `create_chunk_key(chunk_x: int, chunk_y: int) -> String` - Generate unique chunk identifier

### New Parameters

Added to `WorldData.params`:
- `"chunk_size": int = 64` - Vertices per chunk side (32, 64, or 128)
- `"enable_lod": bool = true` - Enable/disable LOD system
- `"lod_levels": int = 3` - Number of LOD levels (2-4)
- `"lod_distances": Array[float] = [500.0, 2000.0]` - Distance thresholds for LOD switching

### UI Updates

**terrain_section.tscn/gd:**
- Added "LOD" container with:
  - `EnableLODCheckBox` - Toggle LOD system
  - `LODLevelsSpinBox` - Number of LOD levels (2-4)
  - `ChunkSizeOptionButton` - Chunk size selection (32, 64, 128)

### Integration Points

**world.gd:**
- **Preload:** `const LODManager = preload("res://scripts/world_creation/LODManager.gd")` - Required for LOD functions
- `_generate_chunked(vert_grid_size: Vector2i, _world_size: Vector2i)` - Main chunk-based generation function
- `_generate_chunk(heightmap: Array[float], heightmap_size: Vector2i, chunk_x: int, chunk_y: int, chunk_size: int, lod_level: int) -> Mesh` - Generate single chunk mesh
- `_get_cache_key() -> String` - Generate cache key from seed + terrain params hash
- `_generate_full_heightmap(vert_grid_size: Vector2i) -> Array[float]` - Extract heightmap generation logic (includes noise, erosion, rivers)
- `_image_to_heightmap_array(image: Image) -> Array[float]` - Convert cached Image to heightmap array
- `_heightmap_array_to_image(heightmap: Array[float], size: Vector2i) -> Image` - Convert heightmap array to Image for caching
- `_combine_chunks_into_mesh(_chunks_x: int, _chunks_y: int, _chunk_size: int)` - Combine chunks for backward compatibility (simplified)

**world_preview.gd:**
- **Preload:** `const LODManager = preload("res://scripts/world_creation/LODManager.gd")` - Required for LOD functions
- `_setup_chunks_container()` - Create container Node3D for chunk meshes
- `_on_chunk_generated(chunk_x: int, chunk_y: int, mesh: Mesh)` - Handle incremental chunk updates (creates/updates MeshInstance3D per chunk)
- `_update_lod()` - Update LOD levels based on camera distance (called in `_process()` and on camera movement)
- `_apply_topo_shader_to_chunk(chunk_node: MeshInstance3D, mesh: Mesh)` - Apply topo shader material to chunk meshes

**WorldCreator.gd:**
- `_on_chunk_generated(chunk_x: int, chunk_y: int, mesh: Mesh)` - Handle chunk generation signal (forwards to world_preview)
- `_on_generation_progress(progress: float)` - Update progress bar for chunk-based generation
- `_show_progress_dialog()` - Show progress dialog with progress bar during generation

### Backward Compatibility

- If `enable_lod` is false, falls back to single mesh generation (original behavior)
- Old worlds without LOD params use defaults (LOD enabled, chunk_size=64, lod_levels=3)
- Cache is optional - generation works without cache (just slower)

### Performance Notes

- LOD system activates automatically for worlds >= MEDIUM (512×512) when `enable_lod` is true
- Heightmap cache significantly speeds up preview updates when only non-terrain params change
- Chunk-based generation allows progressive preview updates for better UX
- Distance-based LOD switching reduces rendering load for distant chunks
- Cache key includes: seed, size, noise_type, frequency, elevation_scale, fractal params, domain warp params, erosion params, shape_preset, and terrain randomness
- Cache invalidation: Automatically invalidated when any terrain-related param changes (detected via cache key mismatch)

### Implementation Details

**Chunk Generation Flow:**
1. `generate()` → `_generate_threaded()` checks if LOD enabled and world size >= 512
2. If yes, calls `_generate_chunked()` which:
   - Calculates number of chunks based on `chunk_size` param
   - Checks heightmap cache using `_get_cache_key()`
   - If cached, loads heightmap; otherwise generates via `_generate_full_heightmap()`
   - Generates chunks progressively, emitting `chunk_generated` signal per chunk
   - Stores chunks in `chunk_data` Dictionary
3. `world_preview._on_chunk_generated()` receives signal and creates/updates MeshInstance3D
4. `_update_lod()` runs in `_process()` to adjust chunk visibility based on camera distance

**Cache Key Generation:**
- Format: `"seed_{seed}_size_{size}_param1_value1_param2_value2_..."`
- Includes all terrain-affecting parameters for accurate cache matching
- Terrain randomness included to ensure cache matches exact generation parameters

---

## Phase 5: Visual Pipeline & Texture Splatting

**Status:** ✅ **Implemented**  
**Date:** 2025-01-06

### Features

1. **Biome Texture System:**
   - `BiomeTextureManager` static utility class for texture loading and caching
   - Configuration from `res://assets/data/biome_textures.json`
   - Support for diffuse textures, normal maps, and biome colors
   - Splat channel mapping (RGBA = 4 biome channels)

2. **Splatmap Generation:**
   - RGBA image where each channel represents a biome group
   - Channel 0 (R): forest, mountain, jungle
   - Channel 1 (G): desert, grassland, plains
   - Channel 2 (B): tundra, taiga, cold_desert
   - Channel 3 (A): swamp, coast
   - Stored in `world_data.splatmap_texture` (ImageTexture)

3. **Texture Map Generation:**
   - **River Map:** R8 texture marking river cells (white = river, black = no river)
   - **Foliage Density Map:** R8 texture with foliage density values (0.0-1.0)
   - Both stored as ImageTexture in `world_data`

4. **World Preview Shader:**
   - New shader: `res://assets/shaders/world_preview.gdshader`
   - Texture splatting with biome textures
   - Normal mapping support for terrain detail
   - Preview mode switching (topographic, biome heatmap, foliage density, etc.)
   - Falls back to legacy `topo_preview.gdshader` if textures unavailable

5. **Preview Mode Selector:**
   - UI control for switching preview visualization modes
   - Modes: Topographic, Biome Heatmap, Foliage Density, etc.
   - Stored in `world_data.params["preview_mode"]` (int enum)

### New Components

**BiomeTextureManager.gd:**
- **Path:** `res://scripts/world_creation/BiomeTextureManager.gd`
- **Type:** `class_name BiomeTextureManager extends RefCounted`
- **Purpose:** Static utility for biome texture management
- **Key Functions:**
  - `load_config() -> bool` - Load biome texture config from JSON
  - `get_texture(biome_name: String) -> Texture2D` - Get biome texture (cached)
  - `get_normal_map(biome_name: String) -> Texture2D` - Get normal map (optional)
  - `get_splat_channel(biome_name: String) -> int` - Get splat channel (0-3)
  - `get_biome_color(biome_name: String) -> Color` - Get default biome color

### New WorldData Variables

Added to `WorldData`:
- `splatmap_texture: ImageTexture` - Biome splatmap (RGBA = 4 channels)
- `river_map_texture: ImageTexture` - River overlay map
- `foliage_density_texture: ImageTexture` - Foliage density map

### New Parameters

Added to `WorldData.params`:
- `"preview_mode": int = 0` - Preview visualization mode (enum)
- `"use_normal_mapping": bool = true` - Enable normal mapping in shader
- `"tint_color": Vector3 = Vector3(1.0, 1.0, 1.0)` - Color tint for shader

### Integration Points

**world.gd:**
- `_generate_splatmap(size: Vector2i)` - Generate biome splatmap texture
- `_generate_river_map(size: Vector2i)` - Generate river overlay texture
- `_generate_foliage_density_texture(size: Vector2i)` - Generate foliage density texture
- Called after biome assignment in both `_generate_threaded()` and `_generate_chunked()`

**world_preview.gd:**
- `_apply_world_shader(mesh: Mesh)` - Apply world preview shader with texture splatting
- `_apply_biome_textures(material: ShaderMaterial)` - Load and apply biome textures
- Falls back to `_apply_topo_shader_fallback()` if textures unavailable

**WorldCreator.gd:**
- `setup_preview_mode_selector()` - Setup preview mode dropdown
- `_on_preview_mode_selected(index: int)` - Handle preview mode changes

### Configuration File

**biome_textures.json:**
- **Path:** `res://assets/data/biome_textures.json`
- **Structure:**
  ```json
  {
    "biome_textures": {
      "forest": {
        "texture_path": "res://assets/textures/biomes/forest.png",
        "normal_path": "res://assets/textures/biomes/forest_normal.png",
        "color": [0.2, 0.6, 0.2],
        "splat_channel": 0
      },
      ...
    }
  }
  ```

### Shader Details

**world_preview.gdshader:**
- Fragment shader with texture splatting
- Samples biome textures based on splatmap channels
- Blends textures using splatmap weights
- Supports normal mapping for terrain detail
- Preview mode switching via `preview_mode` uniform
- River and foliage visualization via texture maps

### Performance Notes

- Biome textures are cached in `BiomeTextureManager` static dictionaries
- Splatmap, river map, and foliage density textures generated once per world
- Shader falls back to legacy topo shader if textures unavailable (no performance impact)
- Preview mode switching is instant (no regeneration required)

---

**End of Documentation**
