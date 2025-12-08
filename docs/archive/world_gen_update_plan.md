# World Generation System Update Plan

**Generated via Multi-Hop Analysis**  
**Date:** 2025-01-06  
**Project:** Genesis (Godot 4.3)  
**Author:** Lordthoth  
**Base Documentation:** `world_generation.md`, `CurrentVisualPipelineDocumentation.gd`

---

## Table of Contents

1. [Goals & Scope](#goals--scope)
2. [Phased Roadmap](#phased-roadmap)
3. [Risks & Mitigations](#risks--mitigations)
4. [New Data Structures](#new-data-structures)
5. [UI Updates](#ui-updates)
6. [Visual Pipeline Changes](#visual-pipeline-changes)
7. [Testing Protocol](#testing-protocol)

---

## Goals & Scope

### Primary Goals

1. **Enhance Terrain Realism** - Add industry-standard features (domain warping, erosion, river systems) for more natural-looking terrain
2. **Increase Immersion** - Add foliage placement, point-of-interest (POI) generation, and enhanced biome visualization
3. **Improve Performance** - Implement LOD system and heightmap caching for large worlds
4. **Expand Fantasy Styles** - Leverage the 12 fantasy archetypes for richer world generation
5. **Maintain Architecture** - Preserve existing threaded generation, preview/full-res modes, and data-driven design

### Industry Standards Alignment

**Quick Wins (Phase 1):**
- Domain warping for organic terrain distortion
- Enhanced noise layering (multiple octaves with different frequencies)
- Improved biome transitions (smooth blending between biomes)

**Immersion Boosts (Phase 2-3):**
- Hydrological erosion simulation
- River system generation (pathfinding-based)
- Foliage density maps per biome
- POI placement (cities, ruins, landmarks)

**Advanced Features (Phase 4-5):**
- LOD system for chunk-based generation
- Heightmap caching for faster preview updates
- Texture splatting for biome visualization
- Advanced shader features (normal mapping, parallax)

### Scope Boundaries

**In Scope:**
- Terrain generation enhancements (noise, erosion, rivers)
- Biome system improvements (transitions, metadata)
- Foliage and POI placement
- Visual pipeline evolution (shaders, materials)
- Performance optimizations (LOD, caching)
- UI parameter additions

**Out of Scope (Future):**
- Real-time editing/painting mode (post-generation)
- Multi-threaded biome assignment (already identified as enhancement)
- Civilization AI simulation
- Weather system simulation
- Dynamic world events

---

## Phased Roadmap

### Phase 1: Noise Enhancements & Domain Warping
**Estimated Duration:** 1-2 weeks  
**Effort Level:** Easy to Medium  
**Priority:** Quick Win

#### Features

1. **Domain Warping Implementation**
   - Add domain warping to FastNoiseLite setup
   - Warp strength parameter (0.0 to 100.0)
   - Affects terrain organic flow and river-like patterns

2. **Enhanced Noise Layering**
   - Multiple noise layers with different frequencies
   - Layer blending modes (add, multiply, subtract)
   - Per-layer octave control

3. **Improved Biome Transitions**
   - Smooth biome blending at boundaries
   - Transition zones based on distance to biome center
   - Edge detection for sharp boundaries (mountains, coastlines)

#### Integration Hooks

**File:** `scripts/world.gd`
- **Function:** `_generate_threaded()` (lines ~70-99)
- **Modification:** Add domain warping after noise setup:
  ```gdscript
  if params.get("domain_warp_strength", 0.0) > 0.0:
      noise.domain_warp_enabled = true
      noise.domain_warp_amplitude = params["domain_warp_strength"]
      noise.domain_warp_frequency = params.get("domain_warp_freq", 0.01)
  ```
- **Function:** `_assign_biomes()` (lines ~330-379)
- **Modification:** Add transition zone calculation:
  ```gdscript
  var transition_zone: float = _calculate_biome_transition(x, y, biome_data)
  biome_data["transition_strength"] = transition_zone
  ```

**File:** `scripts/ui/terrain_section.gd`
- **Function:** `_ready()` (lines ~22-58)
- **Modification:** Add domain warping slider/spinbox controls
- **New Controls:**
  - `domain_warp_slider: HSlider` (0-100)
  - `domain_warp_spinbox: SpinBox` (0-100)
  - `domain_warp_freq_slider: HSlider` (0.001-0.1)

**File:** `assets/shaders/topo_preview.gdshader`
- **Modification:** Add domain warp visualization (optional, for preview)

#### Godot Feasibility

✅ **Highly Feasible**
- FastNoiseLite has built-in domain warping support (`domain_warp_enabled`, `domain_warp_amplitude`)
- Biome transitions can use distance fields or noise-based blending
- No external dependencies required

#### MCP Actions

1. **Modify Script:**
   - `scripts/world.gd` - Add domain warping logic to `_generate_threaded()`
   - `scripts/world.gd` - Add `_calculate_biome_transition()` helper function
   - `scripts/ui/terrain_section.gd` - Add domain warping UI controls

2. **Modify Scene:**
   - `scenes/sections/terrain_section.tscn` - Add domain warping slider/spinbox nodes

3. **Update Resource:**
   - `assets/worlds/default_world.tres` - Add default `domain_warp_strength: 0.0` to params

4. **Test:**
   - `run_project` after modifications
   - Verify domain warping affects terrain shape
   - Test biome transitions visually

---

### Phase 2: Erosion & River Systems
**Estimated Duration:** 2-3 weeks  
**Effort Level:** Medium to Hard  
**Priority:** Immersion Boost

#### Features

1. **Hydrological Erosion Simulation**
   - Thermal erosion (slope-based material movement)
   - Hydraulic erosion (water flow simulation)
   - Erosion strength parameter (0.0 to 1.0)
   - Iteration count for erosion passes (1-10)

2. **River System Generation**
   - Pathfinding from high to low elevation
   - River width based on flow accumulation
   - River depth carving (subtract from heightmap)
   - River network connectivity (tributaries)

3. **Erosion-Based Terrain Features**
   - Valleys and canyons from erosion
   - Alluvial plains at river deltas
   - Erosion-resistant rock formations

#### Integration Hooks

**File:** `scripts/world.gd`
- **Function:** `_generate_threaded()` (after heightmap generation, line ~143)
- **Modification:** Add erosion pass:
  ```gdscript
  # After heightmap generation, before mesh creation
  if params.get("enable_erosion", false):
      var erosion_strength: float = params.get("erosion_strength", 0.5)
      var erosion_iterations: int = params.get("erosion_iterations", 5)
      heightmap = _apply_erosion(heightmap, vert_grid_size, erosion_strength, erosion_iterations)
  ```
- **New Function:** `_apply_erosion(heightmap: Array[float], size: Vector2i, strength: float, iterations: int) -> Array[float]`
- **New Function:** `_generate_rivers(heightmap: Array[float], size: Vector2i) -> Array[Vector2i]` (returns river paths)

**File:** `scripts/ui/terrain_section.gd`
- **Modification:** Add erosion controls:
  - `enable_erosion_checkbox: CheckBox`
  - `erosion_strength_slider: HSlider` (0-100)
  - `erosion_iterations_spinbox: SpinBox` (1-10)

**File:** `scripts/world.gd`
- **Function:** `_assign_biomes()` (lines ~360-379)
- **Modification:** Mark river cells in biome metadata:
  ```gdscript
  if _is_river_cell(x, y, river_paths):
      biome_data["is_river"] = true
      biome_data["river_width"] = _get_river_width(x, y, river_paths)
  ```

#### Godot Feasibility

⚠️ **Moderately Feasible**
- Erosion algorithms are CPU-intensive but can run in thread
- Pathfinding can use A* (Godot has built-in AStar2D)
- River carving requires heightmap modification (straightforward)
- Performance concern: Erosion iterations may slow generation for large worlds

#### MCP Actions

1. **Create New Script:**
   - `scripts/world_creation/ErosionGenerator.gd` - Erosion algorithms
   - `scripts/world_creation/RiverGenerator.gd` - River pathfinding and carving

2. **Modify Script:**
   - `scripts/world.gd` - Integrate erosion and river generation
   - `scripts/ui/terrain_section.gd` - Add erosion UI controls

3. **Modify Scene:**
   - `scenes/sections/terrain_section.tscn` - Add erosion controls

4. **Test:**
   - `run_project` with erosion enabled
   - Verify terrain smoothing and valley formation
   - Test river generation with different seeds

---

### Phase 3: Foliage & Point-of-Interest Placement
**Estimated Duration:** 2-3 weeks  
**Effort Level:** Medium  
**Priority:** Immersion Boost

#### Features

1. **Foliage Density Maps**
   - Per-biome foliage density (forest: high, desert: low)
   - Noise-based variation within biomes
   - Foliage type assignment (trees, grass, shrubs, etc.)

2. **Point-of-Interest (POI) Generation**
   - Cities/towns (based on biome suitability, distance rules)
   - Ruins and landmarks (random placement with clustering)
   - Resource nodes (ore, wood, magical sites)
   - POI metadata (name, type, population, etc.)

3. **POI Visualization**
   - Icon markers in preview (optional)
   - POI list in UI panel
   - Export POI data to JSON

#### Integration Hooks

**File:** `scripts/world.gd`
- **New Variable:** `foliage_density: Array[float]` - Per-cell foliage density (0.0 to 1.0)
- **New Variable:** `poi_metadata: Array[Dictionary]` - POI data
- **Function:** `_generate_threaded()` (after biome assignment, line ~293)
- **Modification:** Add foliage and POI generation:
  ```gdscript
  # After biome assignment
  _generate_foliage_density()
  _generate_pois()
  ```
- **New Function:** `_generate_foliage_density() -> void`
- **New Function:** `_generate_pois() -> void`
- **New Function:** `_place_city(x: int, y: int, biome_data: Dictionary) -> Dictionary`
- **New Function:** `_place_ruin(x: int, y: int) -> Dictionary`
- **New Function:** `_place_resource_node(x: int, y: int, biome_data: Dictionary) -> Dictionary`

**File:** `scripts/ui/civilization_section.gd` (if exists) or new `poi_section.gd`
- **Modification:** Add POI controls:
  - `poi_density_slider: HSlider` (0-100)
  - `enable_cities_checkbox: CheckBox`
  - `enable_ruins_checkbox: CheckBox`
  - `enable_resources_checkbox: CheckBox`

**File:** `scripts/preview/world_preview.gd`
- **Function:** `_update_node_points()` (lines ~410-471)
- **Modification:** Add POI markers (different color, e.g., green for cities, red for ruins)

#### Godot Feasibility

✅ **Highly Feasible**
- Foliage density is simple noise-based calculation
- POI placement can use Poisson disk sampling (Godot has built-in)
- MultiMeshInstance3D can render POI markers efficiently
- No external dependencies

#### MCP Actions

1. **Create New Script:**
   - `scripts/world_creation/FoliageGenerator.gd` - Foliage density calculation
   - `scripts/world_creation/POIGenerator.gd` - POI placement logic

2. **Modify Script:**
   - `scripts/world.gd` - Add foliage and POI generation
   - `scripts/preview/world_preview.gd` - Add POI marker rendering

3. **Modify Scene:**
   - `scenes/sections/civilization_section.tscn` - Add POI controls (or create new section)

4. **Test:**
   - `run_project` with POI generation enabled
   - Verify POI placement respects biome rules
   - Test foliage density visualization

---

### Phase 4: LOD & Performance Optimizations
**Estimated Duration:** 2-3 weeks  
**Effort Level:** Hard  
**Priority:** Advanced Feature

#### Features

1. **Level-of-Detail (LOD) System**
   - Chunk-based generation for large worlds (EPIC/2048)
   - LOD levels (0 = full detail, 1-3 = reduced detail)
   - Distance-based LOD switching
   - Chunk loading/unloading

2. **Heightmap Caching**
   - Cache heightmap images for faster preview updates
   - Cache key: `"{seed}_{size}_{noise_params_hash}"`
   - Cache invalidation on parameter change

3. **Progressive Generation**
   - Generate chunks incrementally
   - Show progress per chunk
   - Allow cancellation mid-generation

#### Integration Hooks

**File:** `scripts/world.gd`
- **New Variable:** `heightmap_cache: Dictionary` - Cached heightmap images
- **New Variable:** `chunk_size: int = 256` - Chunk size in world units
- **Function:** `generate()` (line ~41)
- **Modification:** Check cache before generation:
  ```gdscript
  var cache_key = _get_cache_key()
  if heightmap_cache.has(cache_key) and not force_full_res:
      var cached_heightmap = heightmap_cache[cache_key]
      # Use cached heightmap
  ```
- **New Function:** `_get_cache_key() -> String`
- **New Function:** `_generate_chunk(chunk_x: int, chunk_y: int, lod_level: int) -> Mesh`
- **Modification:** `_generate_threaded()` - Split into chunk-based generation

**File:** `scripts/WorldCreator.gd`
- **Function:** `_on_generation_progress()` (line ~367)
- **Modification:** Show chunk progress:
  ```gdscript
  progress_dialog.set_progress(progress)  # If progress_dialog supports it
  ```

#### Godot Feasibility

⚠️ **Moderately Feasible**
- Chunk-based generation requires significant refactoring
- LOD system needs mesh simplification (Godot has `SurfaceTool` but no built-in simplification)
- Heightmap caching is straightforward (Dictionary + Image storage)
- Performance testing required for large worlds

#### MCP Actions

1. **Create New Script:**
   - `scripts/world_creation/ChunkGenerator.gd` - Chunk-based generation
   - `scripts/world_creation/LODManager.gd` - LOD level management

2. **Modify Script:**
   - `scripts/world.gd` - Refactor to chunk-based generation
   - `scripts/WorldCreator.gd` - Add chunk progress display

3. **Test:**
   - `run_project` with EPIC size (2048×2048)
   - Verify chunk loading performance
   - Test heightmap cache hit rate

---

### Phase 5: Visual Pipeline Evolution & Polish
**Estimated Duration:** 2-3 weeks  
**Effort Level:** Medium  
**Priority:** Polish & Integration

#### Features

1. **Texture Splatting for Biomes**
   - Per-biome texture assignment
   - Smooth blending at biome boundaries
   - Texture atlas for multiple biomes

2. **Enhanced Shader Features**
   - Normal mapping for terrain detail
   - Parallax mapping for depth illusion
   - Biome-based color tinting

3. **Advanced Preview Modes**
   - Topographic map mode (contour lines)
   - Biome heatmap mode
   - Foliage density visualization
   - POI overlay toggle

4. **Export Enhancements**
   - Export POI data to JSON
   - Export heightmap as PNG
   - Export biome map as image

#### Integration Hooks

**File:** `assets/shaders/topo_preview.gdshader`
- **Modification:** Add texture splatting:
  ```glsl
  uniform sampler2D biome_texture_0;  // Forest
  uniform sampler2D biome_texture_1;  // Desert
  uniform sampler2D biome_texture_2;  // Mountain
  uniform sampler2D splat_map;  // Biome blend weights
  
  void fragment() {
      vec3 forest_col = texture(biome_texture_0, UV).rgb;
      vec3 desert_col = texture(biome_texture_1, UV).rgb;
      vec3 mountain_col = texture(biome_texture_2, UV).rgb;
      vec3 splat = texture(splat_map, UV).rgb;
      vec3 final_col = forest_col * splat.r + desert_col * splat.g + mountain_col * splat.b;
      // ... rest of shader
  }
  ```

**File:** `scripts/preview/world_preview.gd`
- **New Function:** `set_preview_mode(mode: String)` - Switch between preview modes
- **Modification:** `_apply_topo_shader()` - Load biome textures and splat map

**File:** `scripts/utils/export_utils.gd`
- **New Function:** `export_heightmap_png(world_data, output_path: String) -> Error`
- **New Function:** `export_biome_map(world_data, output_path: String) -> Error`
- **New Function:** `export_poi_json(world_data, output_path: String) -> Error`

#### Godot Feasibility

✅ **Highly Feasible**
- Texture splatting is standard shader technique
- Normal/parallax mapping well-supported in Godot
- Preview mode switching is UI logic
- Export functions are straightforward file I/O

#### MCP Actions

1. **Modify Shader:**
   - `assets/shaders/topo_preview.gdshader` - Add texture splatting and advanced features

2. **Create Resources:**
   - `assets/textures/biomes/` - Biome texture atlas
   - `assets/textures/splat_maps/` - Splat map generation

3. **Modify Script:**
   - `scripts/preview/world_preview.gd` - Add preview mode switching
   - `scripts/utils/export_utils.gd` - Add new export functions

4. **Test:**
   - `run_project` with texture splatting enabled
   - Test all preview modes
   - Verify export functions

---

## Risks & Mitigations

### Risk 1: Performance Degradation
**Description:** Adding erosion, rivers, and POI generation may slow down world generation, especially for large worlds (LARGE/EPIC).

**Mitigation:**
- Implement heightmap caching (Phase 4) to avoid regenerating unchanged terrain
- Run erosion/rivers in threaded generation (already threaded)
- Add performance profiling to identify bottlenecks
- Consider reducing erosion iterations for preview mode
- **Testing:** Profile generation time before/after each phase

### Risk 2: Backward Compatibility
**Description:** New parameters and data structures may break existing saved worlds.

**Mitigation:**
- Use default values for new parameters (existing worlds load with defaults)
- Version world save format (add `version: int` to WorldData)
- Migration function to upgrade old saves to new format
- **Testing:** Load old saved worlds after each phase, verify they work

### Risk 3: Threading Issues
**Description:** Complex algorithms (erosion, POI placement) may have race conditions or deadlocks.

**Mitigation:**
- Keep all generation logic in `_generate_threaded()` (single thread)
- Use mutex for shared data access (already implemented)
- Avoid main thread access during generation
- **Testing:** Stress test with rapid parameter changes during generation

### Risk 4: Visual Pipeline Complexity
**Description:** Adding texture splatting and advanced shaders may break existing visual style.

**Mitigation:**
- Make advanced features optional (toggle in UI)
- Preserve existing shader as fallback
- Test with all fantasy style presets
- **Testing:** Verify all style presets still work after shader changes

### Risk 5: Data Structure Bloat
**Description:** Adding foliage density, POI metadata, etc. may increase memory usage significantly.

**Mitigation:**
- Use efficient data structures (PackedFloat32Array for heightmaps)
- Consider sparse storage for POIs (only store non-zero entries)
- Add memory usage monitoring
- **Testing:** Monitor memory usage with EPIC size worlds

---

## New Data Structures

### Extended WorldData Resource

**File:** `scripts/world.gd`

**New Variables:**
```gdscript
# Phase 1: Domain Warping
# (No new variables, uses existing params Dictionary)

# Phase 2: Erosion & Rivers
var erosion_params: Dictionary = {
    "enable_erosion": false,
    "erosion_strength": 0.5,
    "erosion_iterations": 5,
    "thermal_erosion": true,
    "hydraulic_erosion": true
}
var river_paths: Array[Vector2i] = []  # River cell coordinates
var river_metadata: Array[Dictionary] = []  # [{x, y, width, depth, flow}]

# Phase 3: Foliage & POIs
var foliage_density: Array[float] = []  # Per-cell density (0.0 to 1.0)
var foliage_type: Array[int] = []  # Per-cell foliage type index
var poi_metadata: Array[Dictionary] = []  # [{type, x, y, name, population, ...}]

# Phase 4: LOD & Caching
var heightmap_cache: Dictionary = {}  # Cache key -> Image
var chunk_data: Dictionary = {}  # Chunk coordinates -> Mesh
var lod_levels: Dictionary = {}  # Chunk coordinates -> LOD level

# Phase 5: Visual Pipeline
var biome_textures: Dictionary = {}  # Biome name -> Texture2D
var splat_map: Image = null  # Biome blend weights
```

**New Enums:**
```gdscript
enum FoliageType {
    NONE = 0,
    GRASS = 1,
    SHRUB = 2,
    TREE = 3,
    DENSE_FOREST = 4
}

enum POIType {
    CITY = 0,
    TOWN = 1,
    VILLAGE = 2,
    RUIN = 3,
    LANDMARK = 4,
    RESOURCE_NODE = 5
}

enum PreviewMode {
    NETWORK = 0,  # Current line-based network
    TOPO = 1,  # Topographic with contour lines
    BIOME_HEATMAP = 2,  # Biome color overlay
    FOLIAGE_DENSITY = 3,  # Foliage visualization
    POI_OVERLAY = 4  # POI markers
}
```

### Biome Metadata Extensions

**Current Structure:**
```gdscript
{
    "biome": String,
    "temperature": String,
    "monsters": Array[String],
    "magic_level": String,
    "humidity": float,
    "temp_value": float,
    "x": int,
    "y": int
}
```

**Extended Structure (Phase 1-3):**
```gdscript
{
    "biome": String,
    "temperature": String,
    "monsters": Array[String],
    "magic_level": String,
    "humidity": float,
    "temp_value": float,
    "x": int,
    "y": int,
    "transition_strength": float,  # Phase 1: Biome transition blending
    "is_river": bool,  # Phase 2: River cell flag
    "river_width": float,  # Phase 2: River width at this cell
    "foliage_density": float,  # Phase 3: Foliage density (0.0 to 1.0)
    "foliage_type": int  # Phase 3: FoliageType enum
}
```

### POI Metadata Structure

**Phase 3:**
```gdscript
{
    "type": int,  # POIType enum
    "x": int,  # World grid X
    "y": int,  # World grid Y
    "name": String,  # Generated or user-defined name
    "population": int,  # For cities/towns (0 for ruins/landmarks)
    "biome": String,  # Associated biome
    "resources": Array[String],  # Available resources
    "magic_level": String,  # Local magic level
    "connections": Array[int]  # Indices of connected POIs (roads/trade routes)
}
```

---

## UI Updates

### Terrain Section (`terrain_section.gd`)

**Phase 1 Additions:**
- Domain Warping Container:
  - `DomainWarpSlider: HSlider` (0-100, default: 0)
  - `DomainWarpSpinBox: SpinBox` (0-100)
  - `DomainWarpFreqSlider: HSlider` (0.001-0.1, default: 0.01)
  - Tooltip: "Domain warping creates organic, flowing terrain patterns by distorting noise coordinates."

**Phase 2 Additions:**
- Erosion Container:
  - `EnableErosionCheckBox: CheckBox` (default: false)
  - `ErosionStrengthSlider: HSlider` (0-100, default: 50)
  - `ErosionIterationsSpinBox: SpinBox` (1-10, default: 5)
  - Tooltip: "Erosion simulates natural weathering, creating valleys and smoothing terrain."

- Rivers Container:
  - `EnableRiversCheckBox: CheckBox` (default: false) - Already exists, needs implementation
  - `RiverDensitySlider: HSlider` (0-100, default: 30)
  - `RiverMinLengthSpinBox: SpinBox` (10-1000, default: 100)
  - Tooltip: "Generate river systems that flow from high to low elevation."

**Phase 3 Additions:**
- Foliage Container:
  - `FoliageDensitySlider: HSlider` (0-100, default: 50)
  - `FoliageVariationSlider: HSlider` (0-100, default: 30)
  - Tooltip: "Control overall foliage density and variation across biomes."

### New POI Section (`poi_section.gd` or extend `civilization_section.gd`)

**Phase 3:**
- POI Generation Container:
  - `EnableCitiesCheckBox: CheckBox` (default: true)
  - `EnableTownsCheckBox: CheckBox` (default: true)
  - `EnableRuinsCheckBox: CheckBox` (default: true)
  - `EnableResourcesCheckBox: CheckBox` (default: true)
  - `POIDensitySlider: HSlider` (0-100, default: 30)
  - `MinPOIDistanceSpinBox: SpinBox` (10-500, default: 50)
  - Tooltip: "Generate cities, towns, ruins, and resource nodes across the world."

- POI List Container:
  - `POIList: ItemList` - Display generated POIs
  - `POIFilterOption: OptionButton` - Filter by type (All, Cities, Ruins, etc.)
  - `ExportPOIButton: Button` - Export POI data to JSON

### Preview Controls (`WorldCreator.gd`)

**Phase 5:**
- Preview Mode Selector:
  - `PreviewModeOption: OptionButton` - Switch between preview modes:
    - "Network" (current)
    - "Topographic"
    - "Biome Heatmap"
    - "Foliage Density"
    - "POI Overlay"
  - Tooltip: "Change preview visualization mode."

- Layer Toggles:
  - `ShowRiversCheckBox: CheckBox` - Toggle river visualization
  - `ShowPOIsCheckBox: CheckBox` - Toggle POI markers
  - `ShowFoliageCheckBox: CheckBox` - Toggle foliage visualization

---

## Visual Pipeline Changes

### Shader Evolution (`topo_preview.gdshader`)

**Phase 1: Domain Warping Visualization (Optional)**
- Add uniform `domain_warp_visualization: bool` to show warp vectors
- Visualize warp direction with color coding (for debugging)

**Phase 2: River Visualization**
- Add uniform `river_data: sampler2D` - River path texture
- Fragment shader: Detect river cells and apply blue/cyan color
- Add river width visualization (thicker lines for wider rivers)

**Phase 3: Foliage Visualization**
- Add uniform `foliage_density_map: sampler2D` - Foliage density texture
- Fragment shader: Apply green tint based on foliage density
- Optional: Add foliage "dots" using noise-based point rendering

**Phase 5: Texture Splatting**
- Replace single color with biome texture atlas
- Add `splat_map: sampler2D` for biome blending
- Add normal mapping for terrain detail
- Add parallax mapping for depth illusion

**Phase 5: Preview Mode Switching**
- Add uniform `preview_mode: int` - PreviewMode enum
- Fragment shader: Switch color calculation based on mode
- Topographic mode: Contour lines every 0.1 height units
- Biome heatmap: Color based on biome type
- Foliage density: Green gradient based on density
- POI overlay: Render POI markers (handled in MultiMesh, not shader)

### Material Updates

**File:** `assets/materials/topo_preview_shader.tres`

**Phase 2:**
- Add `river_data` texture parameter (generated from river_paths)
- Add `show_rivers: bool` parameter

**Phase 3:**
- Add `foliage_density_map` texture parameter
- Add `show_foliage: bool` parameter

**Phase 5:**
- Add `biome_texture_0` through `biome_texture_N` parameters
- Add `splat_map` texture parameter
- Add `normal_map` texture parameter (optional)
- Add `preview_mode` parameter (int)

### Preview Manager Updates

**File:** `scripts/preview/PreviewManager.gd`

**Phase 5:**
- **New Function:** `set_preview_mode(mode: PreviewMode) -> void`
- **Modification:** `apply_fantasy_style_instant()` - Load biome textures based on style

---

## Testing Protocol

### Phase 1 Testing

1. **Domain Warping Test:**
   - Set `domain_warp_strength` to 50.0
   - Generate world with seed 12345
   - Verify terrain shows organic, flowing patterns
   - Compare with `domain_warp_strength = 0.0` (should be more grid-like)

2. **Biome Transition Test:**
   - Generate world with multiple biomes
   - Verify smooth blending at biome boundaries
   - Check `transition_strength` values in biome_metadata

3. **Regression Test:**
   - Load existing saved world
   - Verify it generates correctly (backward compatibility)
   - Test all fantasy style presets still work

**Commands:**
```bash
# Run project
mcp_user-godot_run_project --projectPath /home/darth/Documents/Mythos-gen/Final-Approach

# Check debug output
mcp_user-godot_get_debug_output
```

### Phase 2 Testing

1. **Erosion Test:**
   - Enable erosion with `erosion_strength = 0.7`, `iterations = 5`
   - Generate world, compare before/after erosion
   - Verify terrain smoothing and valley formation
   - Test performance: Time generation with/without erosion

2. **River Generation Test:**
   - Enable rivers with `river_density = 50`
   - Generate world, verify rivers flow from high to low elevation
   - Check river_metadata for correct width/depth values
   - Test with different seeds (rivers should vary)

3. **Integration Test:**
   - Enable both erosion and rivers
   - Verify rivers follow eroded valleys
   - Test with all size presets (TINY to EPIC)

### Phase 3 Testing

1. **Foliage Density Test:**
   - Generate world with `foliage_density = 70`
   - Verify forests have high density, deserts have low density
   - Check foliage_density array values (should be 0.0 to 1.0)

2. **POI Placement Test:**
   - Enable all POI types with `poi_density = 40`
   - Generate world, verify POIs respect biome rules (cities in plains, ruins in mountains)
   - Check POI distance rules (min_distance respected)
   - Verify POI metadata is complete

3. **Performance Test:**
   - Generate EPIC size world (2048×2048) with all features enabled
   - Monitor generation time and memory usage
   - Verify no crashes or memory leaks

### Phase 4 Testing

1. **LOD System Test:**
   - Generate EPIC size world
   - Verify chunks generate correctly
   - Test LOD switching (distance-based)
   - Check chunk loading/unloading

2. **Heightmap Cache Test:**
   - Generate world with seed 12345
   - Change non-terrain parameter (e.g., fantasy style)
   - Regenerate, verify heightmap is cached (faster generation)
   - Change seed, verify cache is invalidated

3. **Progressive Generation Test:**
   - Generate large world, monitor chunk progress
   - Cancel generation mid-way, verify clean cancellation
   - Resume generation, verify it continues correctly

### Phase 5 Testing

1. **Texture Splatting Test:**
   - Generate world with texture splatting enabled
   - Verify biome textures blend correctly at boundaries
   - Test all preview modes (Network, Topo, Biome Heatmap, etc.)

2. **Export Test:**
   - Generate world with POIs and rivers
   - Export heightmap PNG, verify image is correct
   - Export biome map, verify colors match biomes
   - Export POI JSON, verify all POI data is present

3. **Visual Regression Test:**
   - Compare visual output before/after Phase 5
   - Test all fantasy style presets
   - Verify existing visual style is preserved (when using Network mode)

### General Testing Checklist

After each phase:
- [ ] Run project (`run_project`)
- [ ] Verify no errors in debug output
- [ ] Test parameter changes trigger regeneration
- [ ] Test save/load with new parameters
- [ ] Test export functions (if applicable)
- [ ] Test all fantasy style presets
- [ ] Test with different size presets (TINY to EPIC)
- [ ] Test with different seeds (verify determinism)
- [ ] Performance profiling (generation time, memory usage)
- [ ] Visual inspection of generated terrain

---

## Industry Standards Reference

### Procedural Terrain Generation Best Practices

**Noise Techniques:**
- ✅ Multiple octaves (fractal noise) - **Current:** Implemented
- ✅ Domain warping - **Phase 1:** Add
- ✅ Noise layering (multiple frequencies) - **Phase 1:** Enhance
- ✅ Voronoi/Cellular noise - **Current:** Implemented (Cellular type)

**Terrain Features:**
- ✅ Erosion simulation - **Phase 2:** Add
- ✅ River systems - **Phase 2:** Add
- ✅ Biome transitions - **Phase 1:** Improve
- ✅ Height-based features (mountains, valleys) - **Current:** Basic implementation

**World Content:**
- ✅ Foliage placement - **Phase 3:** Add
- ✅ POI generation - **Phase 3:** Add
- ✅ Resource distribution - **Phase 3:** Add
- ✅ Civilization placement - **Future:** Out of scope

**Performance:**
- ✅ LOD system - **Phase 4:** Add
- ✅ Heightmap caching - **Phase 4:** Add
- ✅ Chunk-based generation - **Phase 4:** Add
- ✅ Progressive loading - **Phase 4:** Add

**Visualization:**
- ✅ Texture splatting - **Phase 5:** Add
- ✅ Normal mapping - **Phase 5:** Add
- ✅ Multiple preview modes - **Phase 5:** Add
- ✅ Export formats - **Phase 5:** Enhance

---

## Summary

This update plan evolves the World Generation system from a basic procedural terrain generator into a comprehensive, industry-standard fantasy world creation tool. The phased approach ensures:

1. **Quick Wins First** - Domain warping and noise enhancements provide immediate visual improvements
2. **Immersion Boosts** - Erosion, rivers, foliage, and POIs make worlds feel alive
3. **Performance Foundation** - LOD and caching enable large worlds without slowdowns
4. **Visual Polish** - Texture splatting and advanced shaders create beautiful, immersive previews

Each phase builds on the previous, maintaining backward compatibility and preserving the existing architecture (threaded generation, preview/full-res modes, data-driven design).

**Total Estimated Duration:** 10-14 weeks (2-3 weeks per phase)

**Success Criteria:**
- All phases completed with full testing
- No breaking changes to existing functionality
- Performance maintained or improved
- Visual quality significantly enhanced
- All fantasy style presets work correctly

---

**End of Update Plan**
