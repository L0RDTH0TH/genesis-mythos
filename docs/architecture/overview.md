# Architecture Overview

**Last Updated:** 2025-12-13  
**Project:** Genesis Mythos (Godot 4.3)  
**Author:** Lordthoth

> **Note:** For detailed system implementation documentation, see [SYSTEM_IMPLEMENTATIONS.md](../SYSTEM_IMPLEMENTATIONS.md)

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Core Systems](#core-systems)
3. [World Generation Systems](#world-generation-systems)
4. [World Builder System](#world-builder-system)
5. [Data Flow](#data-flow)

---

## System Architecture

Genesis Mythos follows a modular, data-driven architecture with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    Core Singletons                       │
│   (Eryndor, Logger, WorldStreamer, EntitySim,           │
│    FactionEconomy)                                       │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   World      │  │   Terrain3D  │  │   Procedural │
│   Builder    │  │   System     │  │   World Map  │
│   (UI)       │  │              │  │   Addon      │
└──────────────┘  └──────────────┘  └──────────────┘
        │                 │                 │
        └─────────────────┼─────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Map        │  │   Map        │  │   Map        │
│   Generator  │  │   Renderer   │  │   Editor     │
└──────────────┘  └──────────────┘  └──────────────┘
```

---

## Core Systems

### Core Singletons

The project uses five autoload singletons configured in `project.godot`:

**Eryndor** (`res://core/singletons/eryndor.gd`)
- Main game controller and entry point
- Initializes core systems on startup
- **Status:** ✅ Implemented

**Logger** (`res://core/singletons/Logger.gd`)
- Centralized logging system with structured categories
- Provides Verbose, Debug, Info, Warn, Error levels
- Category-based filtering (e.g., "World/Generation", "UI/WorldBuilder")
- **Status:** ✅ Fully Implemented

**WorldStreamer** (`res://core/streaming/world_streamer.gd`)
- World streaming and loading system
- Manages dynamic world content loading
- **Status:** ✅ Implemented

**EntitySim** (`res://core/sim/entity_sim.gd`)
- Entity simulation system
- Handles entity behavior and state
- **Status:** ✅ Implemented

**FactionEconomy** (`res://core/sim/faction_economy.gd`)
- Faction economy simulation
- Manages economic interactions between factions
- **Status:** ✅ Implemented

---

## World Generation Systems

### MapGenerator (`core/world_generation/MapGenerator.gd`)

**Status:** ✅ Fully Implemented

Procedural map generation using FastNoiseLite with support for:
- Heightmap generation with multiple noise types (Perlin, Simplex, Cellular, Value, SimplexSmooth)
- Erosion simulation (5 iterations by default)
- River generation (simplified overlay system)
- Biome generation based on height, temperature, and moisture
- Threaded generation support for large maps
- Multiple noise generators:
  - `height_noise`: Primary heightmap generation
  - `continent_noise`: Continent mask generation
  - `temperature_noise`: Temperature map generation
  - `moisture_noise`: Moisture/humidity map generation

**Key Methods:**
- `generate_map(world_map_data: WorldMapData, use_thread: bool = true)` - Main generation entry point
- `_generate_sync(world_map_data: WorldMapData)` - Synchronous generation
- `_generate_heightmap(world_map_data: WorldMapData)` - Heightmap generation
- `_apply_erosion(world_map_data: WorldMapData)` - Erosion simulation
- `_generate_rivers(world_map_data: WorldMapData)` - River generation

### MapRenderer (`core/world_generation/MapRenderer.gd`)

**Status:** ✅ Fully Implemented

Shader-based map rendering with:
- Custom shader (`res://shaders/map_renderer.gdshader`)
- Multiple view modes: HEIGHTMAP, BIOMES, POLITICAL
- Hillshading with configurable light direction
- Biome texture rendering
- Rivers overlay rendering
- Real-time texture updates

**Key Methods:**
- `setup_render_target(target: Node)` - Setup rendering target
- `set_world_map_data(data: WorldMapData)` - Set world map data
- `set_view_mode(mode: ViewMode)` - Change view mode
- `refresh()` - Refresh rendering

### MapEditor (`core/world_generation/MapEditor.gd`)

**Status:** ✅ Fully Implemented

Brush-based map editing with:
- Multiple tools: RAISE, LOWER, SMOOTH, SHARPEN, RIVER, MOUNTAIN, CRATER, ISLAND
- Configurable brush parameters (radius, strength, falloff)
- Real-time painting with mouse input
- Undo/redo system integration

### WorldMapData (`core/world_generation/WorldMapData.gd`)

**Status:** ✅ Fully Implemented

Resource class storing:
- Heightmap Image (FORMAT_RF or grayscale)
- Noise parameters (type, frequency, octaves, persistence, lacunarity)
- Erosion settings
- Sea level
- Rivers parameters
- Biome parameters
- Markers array
- Undo history (20 levels)

### MarkerManager (`core/world_generation/MarkerManager.gd`)

**Status:** ✅ Fully Implemented

Icon/marker placement system for 2D map with clustering support.

---

## World Builder System

### WorldBuilderUI (`ui/world_builder/WorldBuilderUI.gd`)

**Status:** ✅ Fully Implemented

Step-by-step wizard interface with 8 steps:
1. **Map Generation & Editing** - Initial map setup and 2D editing
2. **Terrain** - Terrain3D configuration
3. **Climate** - Temperature, rainfall, wind controls
4. **Biomes** - Biome assignment and generation
5. **Structures & Civilizations** - City and structure placement
6. **Environment** - Fog, sky, lighting controls
7. **Resources & Magic** - Resource distribution
8. **Export** - World export and saving

**Features:**
- Integration with MapMakerModule for Step 1
- Live terrain preview updates
- Data persistence across steps
- Icon placement and clustering system
- Fantasy archetype support

### MapMakerModule (`ui/world_builder/MapMakerModule.gd`)

**Status:** ✅ Fully Implemented

Main module for 2D Map Maker that integrates:
- MapGenerator for procedural generation
- MapRenderer for visualization
- MapEditor for brush editing
- MarkerManager for icon placement

**Features:**
- Viewport-based rendering with Camera2D
- Toolbar with editing tools
- Parameters panel for generation settings
- View mode switching (heightmap/biomes/political)
- Real-time preview updates
- Integration with Terrain3DManager for 3D preview

### Terrain3DManager (`core/world_generation/Terrain3DManager.gd`)

**Status:** ✅ Fully Implemented

Terrain3D plugin integration with:
- Terrain3D node creation and management
- Heightmap import/export (EXR, PNG, R16)
- Procedural generation from noise
- Region-based terrain (up to 65km)
- Biome texture blending (32 textures)
- LOD system for performance
- Integration with WorldBuilderUI for live updates

**Terrain3D Plugin:**
- Location: `res://addons/terrain_3d/`
- Status: ✅ Fully Installed and Enabled
- Provides terrain sculpting tools, texture painting, region management

### IconNode (`ui/world_builder/IconNode.gd`)

**Status:** ✅ Fully Implemented

Icon placement system for 2D map with visual representation and click detection.

---

## World Generation Flow

### Current Implementation Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    MapGenerator                              │
│                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐ │
│  │   Heightmap  │───▶│   Erosion    │───▶│   Rivers     │ │
│  │  Generation  │    │  Simulation  │    │  Generation  │ │
│  └──────────────┘    └──────────────┘    └──────────────┘ │
│         │                   │                   │           │
│         ▼                   ▼                   ▼           │
│  FastNoiseLite      Erosion Iterations   River Overlay    │
│  (Multiple Types)    (5 default)         (Simplified)      │
│                                                             │
│  ┌──────────────┐                                          │
│  │   Biomes     │                                          │
│  │  Generation  │                                          │
│  └──────────────┘                                          │
│         │                                                   │
│         ▼                                                   │
│  Temperature + Moisture + Height                            │
└─────────────────────────────────────────────────────────────┘
```

### Generation Process

1. **Heightmap Generation**
   - Uses FastNoiseLite with configurable noise type
   - Supports Perlin, Simplex, Cellular, Value, SimplexSmooth
   - Configurable frequency, octaves, persistence, lacunarity
   - Generates base heightmap from noise

2. **Erosion Simulation**
   - Applies erosion algorithm (5 iterations by default)
   - Configurable erosion strength
   - Creates more natural terrain features

3. **River Generation**
   - Simplified river overlay system
   - Paints rivers as low paths on heightmap
   - Configurable river count and start elevation

4. **Biome Generation**
   - Based on height, temperature, and moisture maps
   - Uses separate noise generators for temperature and moisture
   - Assigns biome IDs based on climate ranges from `biomes.json`

5. **Data Storage**
   - All generated data stored in `WorldMapData` resource
   - Supports undo/redo (20 levels)
   - Can be exported to PNG/EXR formats

---

## World Builder Architecture

### Wizard Flow

```
┌─────────────────────────────────────────────────────────────┐
│              WorldBuilderUI                                   │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │  Step 1  │  │  Step 2  │  │  Step 3  │  │  Step 4  │ │
│  │   Map    │  │ Terrain  │  │ Climate  │  │ Biomes   │ │
│  │  Maker   │  │          │  │          │  │          │ │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘ │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │  Step 5  │  │  Step 6  │  │  Step 7  │              │
│  │Structures│  │Environment│  │Resources │              │
│  └──────────┘  └──────────┘  └──────────┘              │
│                                                             │
│  ┌──────────┐                                              │
│  │  Step 8  │                                              │
│  │  Export  │                                              │
│  └──────────┘                                              │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐ │
│  │              MapMakerModule                          │ │
│  │  (Step 1: Integrates Generator, Renderer, Editor)   │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐ │
│  │              Terrain3DManager                         │ │
│  │         (Terrain Generation & Management)            │ │
│  └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### World Generation Data Flow

```
JSON Files (data/*.json)
    ↓
WorldBuilderUI (loads data)
    ↓
MapMakerModule
    ├─→ MapGenerator.generate_map()
    │   └─→ WorldMapData (stores heightmap + parameters)
    ├─→ MapRenderer.setup_render_target()
    │   └─→ Shader-based visualization
    ├─→ MapEditor (brush tools)
    │   └─→ Modifies WorldMapData
    └─→ MarkerManager (icon placement)
        └─→ IconNode instances
    ↓
Terrain3DManager
    ├─→ generate_from_noise() or import_heightmap()
    └─→ Terrain3D Node (3D terrain)
```

### Data Sources

**JSON Configuration Files:**
- `res://data/biomes.json` - Biome definitions with temperature/rainfall ranges
- `res://data/civilizations.json` - Civilization types for city assignment
- `res://data/map_icons.json` - 2D map icon definitions
- `res://data/fantasy_archetypes.json` - Fantasy archetype presets
- `res://data/resources.json` - Resource type definitions
- `res://data/config/terrain_generation.json` - Terrain generation defaults
- `res://data/config/world_builder_ui.json` - UI configuration
- `res://data/config/logging_config.json` - Logging configuration

**Resource Classes:**
- `WorldMapData` - Stores heightmap and generation parameters
- `TerrainGenerationConfig` - Terrain generation configuration

---

## Integration Points

### 2D Map → 3D Terrain

When 2D map editing completes:
1. `MapMakerModule` generates heightmap via `MapGenerator`
2. Heightmap stored in `WorldMapData` resource
3. `Terrain3DManager` imports heightmap into Terrain3D
4. 3D terrain preview updates in real-time via live update system

### World Builder → Export

When world generation completes:
1. `WorldBuilderUI` collects all step data
2. World data saved to JSON (`user://worlds/{name}.json`)
3. Heightmap exported to PNG/EXR (`user://exports/{name}_heightmap.png`)
4. Biome map exported (`user://exports/{name}_biomes.png`)

### Procedural World Map Addon Integration

The `ProceduralWorldMap` addon (`res://addons/procedural_world_map/`) provides:
- `ProceduralWorldMap` node for 2D map display
- Custom datasource: `ProceduralWorldDatasource.gd` in `data/` directory
- Fantasy archetype-based generation support
- Integration with WorldBuilderUI for map display

---

## Additional Resources

- **Detailed System Documentation:** [SYSTEM_IMPLEMENTATIONS.md](../SYSTEM_IMPLEMENTATIONS.md)
- **World Builder Guide:** [WORLD_BUILDER_WIZARD_GUIDE.md](../WORLD_BUILDER_WIZARD_GUIDE.md)
- **World Builder API:** [WORLD_BUILDER_API_REFERENCE.md](../WORLD_BUILDER_API_REFERENCE.md)
- **Data Schemas:** [schemas/DATA_SCHEMAS.md](../schemas/DATA_SCHEMAS.md)

---

**End of Documentation**
