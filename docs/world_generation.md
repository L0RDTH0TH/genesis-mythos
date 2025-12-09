# World Generation System Documentation

**Last Updated:** 2025-01-09  
**Project:** Genesis (Godot 4.3)  
**Author:** Lordthoth

---

## Table of Contents

1. [Overview](#overview)
2. [High-Level Architecture](#high-level-architecture)
3. [Core Components](#core-components)
4. [Generation Pipeline](#generation-pipeline)
5. [Data-Driven System](#data-driven-system)
6. [Adding New Biomes](#adding-new-biomes)
7. [Integration Points](#integration-points)

---

## Overview

The World Generation system is a fully data-driven, biome-blended terrain generation system built in Godot 4.3. It replaces the old chunk-based noise system with a sophisticated three-phase generation pipeline that uses region seeding and biome blending to create organic, realistic worlds.

**Key Features:**
- **Data-Driven Architecture**: All biomes defined via `BiomeDefinition.tres` resources
- **Region-Seeded Generation**: Uses `RegionSeed.json` for consistent region placement
- **Three-Phase Pipeline**: Seed → Regions → Chunks for scalable generation
- **Biome Blending**: Smooth transitions between biome types
- **Threaded Generation**: Background processing for smooth UI
- **Preview vs. Full Resolution**: Fast preview mode for real-time editing

**Architecture Pattern:**
- **Data-Driven:** All biomes and parameters stored in Resources and JSON
- **Signal-Based:** Event-driven updates via signals
- **Threaded:** Background generation with mutex-protected updates
- **Modular:** Clear separation between seeding, region generation, and chunk generation

---

## High-Level Architecture

The new world generation system follows a three-phase pipeline:

```
Phase 1: Seed Generation
    ↓
Phase 2: Region Generation (using RegionSeed.json)
    ↓
Phase 3: Chunk Generation (using BiomeDefinition resources)
    ↓
Final World Mesh
```

### Phase 1: Seed Generation

The seed phase establishes the fundamental world parameters:
- World seed value
- World size and resolution
- Base terrain parameters (elevation scale, noise settings)
- Climate parameters (temperature, humidity ranges)

**Output:** Base world configuration ready for region placement.

### Phase 2: Region Generation

Regions are large-scale areas with distinct characteristics. The system:
- Loads region definitions from `RegionSeed.json`
- Places regions based on seed-based RNG
- Assigns biome types to regions
- Creates region boundaries with blending zones

**Output:** Region map with biome assignments and boundaries.

### Phase 3: Chunk Generation

Chunks are the final renderable units. The system:
- Loads `BiomeDefinition.tres` resources for each biome type
- Generates heightmaps per chunk using biome-specific noise parameters
- Blends biomes at region boundaries
- Applies biome-specific features (foliage, POIs, resources)

**Output:** Final mesh chunks ready for rendering.

---

## Core Components

### 1. `WorldGenerationManager.gd`

**Path:** `res://scripts/world_creation/WorldGenerationManager.gd`  
**Type:** `class_name WorldGenerationManager extends Node`  
**Purpose:** Central manager for the entire world generation pipeline

**Key Variables:**
- `world_seed: int` - Master world generation seed
- `world_size: Vector2i` - World dimensions in chunks
- `region_seed_data: Dictionary` - Loaded region seed data
- `biome_definitions: Dictionary` - Loaded BiomeDefinition resources (biome_id → BiomeDefinition)
- `region_map: Array[Array]` - Region assignments per world cell
- `chunk_cache: Dictionary` - Cached chunk meshes (chunk_key → Mesh)
- `generation_thread: Thread` - Background generation thread
- `generation_mutex: Mutex` - Thread synchronization

**Key Functions:**
- `generate_world(seed: int, size: Vector2i, force_full_res: bool = false)` - Start world generation
- `_generate_threaded()` - Background generation logic
- `_phase_seed_generation()` - Phase 1: Generate base world seed
- `_phase_region_generation()` - Phase 2: Generate regions from RegionSeed.json
- `_phase_chunk_generation()` - Phase 3: Generate chunks with biome blending
- `_load_region_seed_data() -> bool` - Load RegionSeed.json
- `_load_biome_definitions() -> bool` - Load all BiomeDefinition.tres resources
- `_get_biome_at_position(pos: Vector2i) -> String` - Get biome ID at world position
- `_blend_biomes(pos: Vector2i, biome_a: String, biome_b: String) -> Dictionary` - Blend two biomes

**Signals:**
- `generation_progress(progress: float)` - 0.0 to 1.0
- `generation_complete()` - Emitted when world is ready
- `chunk_generated(chunk_x: int, chunk_y: int, mesh: Mesh)` - Progressive chunk generation
- `region_generated(region_id: String, bounds: Rect2i)` - Region placement complete

**Dependencies:**
- `BiomeDefinition` resource class
- `RegionSeed.json` data file
- Biome definition resources in `res://assets/data/biomes/`

---

### 2. `BiomeDefinition.tres` (Resource)

**Path:** `res://assets/data/biomes/{biome_id}.tres`  
**Type:** `class_name BiomeDefinition extends Resource`  
**Purpose:** Data-driven biome configuration

**Key Properties:**
- `biome_id: String` - Unique biome identifier (e.g., "forest", "desert")
- `biome_name: String` - Display name
- `noise_parameters: Dictionary` - Noise generation parameters:
  - `frequency: float` - Base noise frequency
  - `octaves: int` - Number of noise octaves
  - `lacunarity: float` - Frequency multiplier per octave
  - `gain: float` - Amplitude multiplier per octave
  - `noise_type: String` - "Perlin", "Simplex", "Cellular", "Value"
- `height_range: Vector2` - Min/max height for this biome (0.0-1.0)
- `temperature_range: Vector2` - Preferred temperature range (°C)
- `humidity_range: Vector2` - Preferred humidity range (0.0-1.0)
- `blend_distance: float` - Distance for biome blending (in world units)
- `foliage_density: float` - Base foliage density (0.0-1.0)
- `poi_types: Array[String]` - Allowed POI types for this biome
- `resource_types: Array[String]` - Available resource types
- `texture_path: String` - Path to biome texture
- `normal_map_path: String` - Path to normal map (optional)

**Example BiomeDefinition Structure:**
```gdscript
# Forest biome definition
biome_id = "forest"
biome_name = "Forest"
noise_parameters = {
    "frequency": 0.02,
    "octaves": 6,
    "lacunarity": 2.1,
    "gain": 0.6,
    "noise_type": "Simplex"
}
height_range = Vector2(0.3, 0.8)
temperature_range = Vector2(5.0, 25.0)
humidity_range = Vector2(0.5, 1.0)
blend_distance = 32.0
foliage_density = 0.8
poi_types = ["village", "ruin", "shrine"]
resource_types = ["wood", "herbs"]
texture_path = "res://assets/textures/biomes/forest.png"
```

---

### 3. `RegionSeed.json`

**Path:** `res://assets/data/RegionSeed.json`  
**Purpose:** Defines region types and their placement rules

**Structure:**
```json
{
  "regions": [
    {
      "id": "temperate_forest_region",
      "name": "Temperate Forest Region",
      "biome_ids": ["forest", "grassland", "plains"],
      "weight": 0.3,
      "min_size": 8,
      "max_size": 16,
      "placement_rules": {
        "prefer_height_range": [0.3, 0.7],
        "prefer_temperature_range": [5.0, 25.0],
        "prefer_humidity_range": [0.4, 0.9],
        "avoid_adjacent": ["desert_region", "tundra_region"]
      }
    },
    {
      "id": "desert_region",
      "name": "Desert Region",
      "biome_ids": ["desert", "badlands"],
      "weight": 0.15,
      "min_size": 4,
      "max_size": 12,
      "placement_rules": {
        "prefer_height_range": [0.1, 0.5],
        "prefer_temperature_range": [30.0, 50.0],
        "prefer_humidity_range": [0.0, 0.3],
        "avoid_adjacent": ["tundra_region", "swamp_region"]
      }
    }
  ],
  "blending": {
    "default_blend_distance": 16.0,
    "blend_curve": "smoothstep"
  }
}
```

**Region Properties:**
- `id: String` - Unique region identifier
- `name: String` - Display name
- `biome_ids: Array[String]` - List of biome IDs that can appear in this region
- `weight: float` - Placement probability weight (0.0-1.0)
- `min_size: int` - Minimum region size in chunks
- `max_size: int` - Maximum region size in chunks
- `placement_rules: Dictionary` - Rules for region placement:
  - `prefer_height_range: Array[float]` - Preferred height range
  - `prefer_temperature_range: Array[float]` - Preferred temperature range
  - `prefer_humidity_range: Array[float]` - Preferred humidity range
  - `avoid_adjacent: Array[String]` - Region IDs to avoid placing adjacent

---

## Generation Pipeline

### Complete Generation Flow

1. **Initialization:**
   ```gdscript
   WorldGenerationManager.generate_world(seed, size, force_full_res)
   ```
   - Creates generation thread
   - Loads RegionSeed.json
   - Loads all BiomeDefinition.tres resources
   - Starts `_generate_threaded()`

2. **Phase 1: Seed Generation (0% → 10%)**
   ```gdscript
   _phase_seed_generation()
   ```
   - Establishes base world parameters
   - Generates global climate maps (temperature, humidity)
   - Creates base heightmap using global noise
   - Emits progress: 10%

3. **Phase 2: Region Generation (10% → 40%)**
   ```gdscript
   _phase_region_generation()
   ```
   - Iterates through RegionSeed.json regions
   - For each region:
     - Calculates placement probability based on weight and rules
     - Places region using seed-based RNG
     - Assigns biome IDs from region's biome_ids list
     - Creates region boundaries
   - Generates region map (world_size × world_size array)
   - Emits progress: 40%

4. **Phase 3: Chunk Generation (40% → 100%)**
   ```gdscript
   _phase_chunk_generation()
   ```
   - For each chunk in world:
     - Determines primary biome from region map
     - Checks for adjacent regions (for blending)
     - Loads BiomeDefinition for primary biome
     - Generates heightmap using biome-specific noise parameters
     - If blending needed:
       - Loads BiomeDefinition for secondary biome
       - Blends heightmaps using blend_distance
       - Blends biome properties (foliage, textures)
     - Generates chunk mesh from heightmap
     - Applies biome-specific features (foliage, POIs)
     - Emits `chunk_generated` signal
   - Emits progress: 100%

5. **Completion:**
   ```gdscript
   call_deferred("_on_generation_complete")
   ```
   - Validates all chunks
   - Emits `generation_complete` signal

---

### Biome Blending Algorithm

When two regions meet, their biomes are blended smoothly:

```gdscript
func _blend_biomes(pos: Vector2i, biome_a: String, biome_b: String) -> Dictionary:
    """Blend two biomes at a position.
    
    Args:
        pos: World position
        biome_a: Primary biome ID
        biome_b: Secondary biome ID
    
    Returns:
        Dictionary with blended properties
    """
    var def_a: BiomeDefinition = biome_definitions[biome_a]
    var def_b: BiomeDefinition = biome_definitions[biome_b]
    
    # Calculate distance to region boundary
    var dist_to_boundary: float = _get_distance_to_boundary(pos)
    var blend_distance: float = min(def_a.blend_distance, def_b.blend_distance)
    
    # Calculate blend factor (0.0 = full biome_a, 1.0 = full biome_b)
    var blend_factor: float = clamp(dist_to_boundary / blend_distance, 0.0, 1.0)
    blend_factor = smoothstep(0.0, 1.0, blend_factor)  # Smooth transition
    
    # Blend noise parameters
    var blended_freq: float = lerp(def_a.noise_parameters.frequency, 
                                   def_b.noise_parameters.frequency, 
                                   blend_factor)
    
    # Blend height ranges
    var blended_height_min: float = lerp(def_a.height_range.x, 
                                          def_b.height_range.x, 
                                          blend_factor)
    var blended_height_max: float = lerp(def_a.height_range.y, 
                                         def_b.height_range.y, 
                                         blend_factor)
    
    # Blend foliage density
    var blended_foliage: float = lerp(def_a.foliage_density, 
                                      def_b.foliage_density, 
                                      blend_factor)
    
    return {
        "frequency": blended_freq,
        "height_range": Vector2(blended_height_min, blended_height_max),
        "foliage_density": blended_foliage,
        "blend_factor": blend_factor
    }
```

---

## Data-Driven System

### Biome Definition Workflow

1. **Create BiomeDefinition Resource:**
   - In Godot editor: Right-click `res://assets/data/biomes/` → New Resource → BiomeDefinition
   - Set all properties (biome_id, noise_parameters, ranges, etc.)
   - Save as `{biome_id}.tres` (e.g., `forest.tres`)

2. **Add to RegionSeed.json:**
   - Open `res://assets/data/RegionSeed.json`
   - Add biome_id to appropriate region's `biome_ids` array
   - Or create new region entry

3. **System Auto-Discovery:**
   - `WorldGenerationManager._load_biome_definitions()` scans `res://assets/data/biomes/`
   - Loads all `.tres` files that extend BiomeDefinition
   - Stores in `biome_definitions` dictionary

### Region Configuration Workflow

1. **Edit RegionSeed.json:**
   - Open `res://assets/data/RegionSeed.json`
   - Add/modify region entries
   - Adjust weights and placement rules
   - Save file

2. **System Auto-Load:**
   - `WorldGenerationManager._load_region_seed_data()` loads on generation start
   - Validates JSON structure
   - Stores in `region_seed_data` dictionary

---

## Adding New Biomes

### Step-by-Step Guide

1. **Create BiomeDefinition Resource:**
   ```
   a. In Godot: Right-click res://assets/data/biomes/
   b. New Resource → BiomeDefinition
   c. Set biome_id (e.g., "volcanic_wasteland")
   d. Set biome_name (e.g., "Volcanic Wasteland")
   e. Configure noise_parameters:
      - frequency: 0.015
      - octaves: 5
      - lacunarity: 2.3
      - gain: 0.7
      - noise_type: "Cellular"
   f. Set height_range: Vector2(0.6, 1.0)  # High elevation
   g. Set temperature_range: Vector2(40.0, 60.0)  # Very hot
   h. Set humidity_range: Vector2(0.0, 0.2)  # Very dry
   i. Set blend_distance: 24.0
   j. Set foliage_density: 0.1  # Sparse
   k. Set poi_types: ["volcano", "lava_cave"]
   l. Set resource_types: ["obsidian", "sulfur"]
   m. Set texture_path: "res://assets/textures/biomes/volcanic.png"
   n. Save as: res://assets/data/biomes/volcanic_wasteland.tres
   ```

2. **Add Biome to Region:**
   ```
   a. Open res://assets/data/RegionSeed.json
   b. Find or create appropriate region
   c. Add "volcanic_wasteland" to biome_ids array
   d. Save file
   ```

3. **Create Biome Texture (Optional):**
   ```
   a. Create texture: res://assets/textures/biomes/volcanic.png
   b. Create normal map: res://assets/textures/biomes/volcanic_normal.png (optional)
   c. Update BiomeDefinition texture_path if needed
   ```

4. **Test Generation:**
   ```
   a. Run world generation
   b. Verify biome appears in appropriate regions
   c. Check biome blending at boundaries
   d. Verify foliage/POI placement
   ```

---

## Integration Points

### WorldCreator Integration

**WorldCreator.gd** calls `WorldGenerationManager`:

```gdscript
@onready var world_gen_manager: WorldGenerationManager = $WorldGenerationManager

func _on_generate_world_pressed():
    world_gen_manager.generate_world(world.seed, world.size_preset, true)
    await world_gen_manager.generation_complete
    # Store in GameData for character creation
```

### Preview System Integration

**WorldPreview.gd** receives chunk signals:

```gdscript
func _ready():
    WorldGenerationManager.chunk_generated.connect(_on_chunk_generated)

func _on_chunk_generated(chunk_x: int, chunk_y: int, mesh: Mesh):
    # Create/update MeshInstance3D for chunk
    # Apply biome textures from BiomeDefinition
```

### Export Integration

**ExportUtils.gd** can export complete world:

```gdscript
static func export_world(world_gen_manager: WorldGenerationManager, output_path: String):
    # Export all chunks
    # Export region map
    # Export biome metadata
    # Export textures
```

---

## Summary

The new World Generation system provides:

- **Data-Driven Biomes**: All biomes defined via BiomeDefinition resources
- **Region-Based Placement**: Consistent region placement via RegionSeed.json
- **Smooth Biome Blending**: Natural transitions between biome types
- **Three-Phase Pipeline**: Scalable Seed → Regions → Chunks architecture
- **Easy Extension**: Add new biomes by creating resources and updating JSON
- **Threaded Generation**: Smooth UI during world creation
- **Progressive Updates**: Chunk-by-chunk generation with real-time preview

The system is designed for extensibility: add new biomes, regions, and features without modifying core generation code.

---

**End of Documentation**
