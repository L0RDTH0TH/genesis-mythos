# Architecture Overview

**Last Updated:** 2025-01-09  
**Project:** Genesis (Godot 4.3)  
**Author:** Lordthoth

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Core Systems](#core-systems)
3. [World Builder](#world-builder)
4. [Data Flow](#data-flow)

---

## System Architecture

Genesis Mythos follows a modular, data-driven architecture with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    Core Singletons                       │
│         (Eryndor, Logger, WorldStreamer, etc.)          │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   World      │  │   Terrain3D  │  │     UI       │
│   Builder    │  │   System     │  │   System     │
└──────────────┘  └──────────────┘  └──────────────┘
```

---

## Core Systems

### Core Singletons

The project uses several autoload singletons for core functionality:

**Eryndor** (`res://core/singletons/eryndor.gd`)
- Main game controller and entry point
- Initializes core systems on startup

**Logger** (`res://core/singletons/Logger.gd`)
- Centralized logging system
- Provides structured logging with categories and levels

**WorldStreamer** (`res://core/streaming/world_streamer.gd`)
- World streaming and loading system
- Manages dynamic world content loading

**EntitySim** (`res://core/sim/entity_sim.gd`)
- Entity simulation system
- Handles entity behavior and state

**FactionEconomy** (`res://core/sim/faction_economy.gd`)
- Faction economy simulation
- Manages economic interactions between factions

### World Builder System

Step-by-step wizard interface for creating procedural 3D worlds.

**Key Components:**
- `WorldBuilderUI.gd` - Main wizard controller with 9 steps
- `MapMakerModule.gd` - 2D map editor with parchment styling
- `Terrain3DManager.gd` - Terrain3D integration and management
- `IconNode.gd` - Icon placement system for 2D map

### World Generation System

Data-driven, biome-blended world generation with three-phase pipeline.

**Key Components:**
- `WorldGenerationManager.gd` - Central generation manager
- `BiomeDefinition` resources - Data-driven biome definitions
- `RegionSeed.json` - Region placement configuration
- Three-phase pipeline: Seed → Regions → Chunks

---

## World Generation

### Architecture Flow

```
┌─────────────────────────────────────────────────────────────┐
│              WorldGenerationManager                         │
│                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐ │
│  │   Phase 1:   │───▶│   Phase 2:   │───▶│   Phase 3:   │ │
│  │    Seed      │    │   Regions    │    │   Chunks    │ │
│  └──────────────┘    └──────────────┘    └──────────────┘ │
│         │                   │                   │           │
│         ▼                   ▼                   ▼           │
│  Base World Config   RegionSeed.json   BiomeDefinition     │
│  Global Climate      Region Placement  Biome Blending      │
│  Base Heightmap      Biome Assignment  Chunk Meshes       │
└─────────────────────────────────────────────────────────────┘
```

### Class Responsibilities

#### WorldGenerationManager

**Primary Responsibilities:**
- Orchestrate three-phase generation pipeline
- Load and manage BiomeDefinition resources
- Load and process RegionSeed.json
- Manage generation thread and synchronization
- Emit progress and completion signals

**Key Methods:**
- `generate_world()` - Entry point for world generation
- `_phase_seed_generation()` - Phase 1: Base world setup
- `_phase_region_generation()` - Phase 2: Region placement
- `_phase_chunk_generation()` - Phase 3: Chunk mesh generation
- `_blend_biomes()` - Biome blending at boundaries

#### BiomeDefinition Resource

**Primary Responsibilities:**
- Store biome-specific generation parameters
- Define noise parameters for heightmap generation
- Define climate ranges (temperature, humidity, height)
- Define biome features (foliage, POIs, resources)
- Store texture and visual asset paths

**Key Properties:**
- `noise_parameters` - Noise generation settings
- `height_range`, `temperature_range`, `humidity_range` - Climate ranges
- `blend_distance` - Biome blending distance
- `foliage_density`, `poi_types`, `resource_types` - Biome features

#### RegionSeed.json

**Primary Responsibilities:**
- Define region types and their characteristics
- Define region placement rules and weights
- Define biome composition for each region
- Define blending behavior between regions

**Key Structure:**
- `regions[]` - Array of region definitions
- `blending` - Global blending configuration

### Generation Pipeline

**Phase 1: Seed Generation (0% → 10%)**
- Establish base world parameters
- Generate global climate maps
- Create base heightmap

**Phase 2: Region Generation (10% → 40%)**
- Load RegionSeed.json
- Place regions based on weights and rules
- Assign biome IDs to regions
- Create region boundaries

**Phase 3: Chunk Generation (40% → 100%)**
- For each chunk:
  - Determine primary biome from region map
  - Load BiomeDefinition for biome
  - Generate heightmap using biome-specific noise
  - Blend with adjacent biomes if needed
  - Generate chunk mesh
  - Apply biome features (foliage, POIs)
- Emit chunk_generated signals for progressive updates

### Data Flow

```
User Input (WorldCreator)
    ↓
WorldGenerationManager.generate_world()
    ↓
Load RegionSeed.json
    ↓
Load BiomeDefinition resources
    ↓
Phase 1: Seed Generation
    ↓
Phase 2: Region Generation
    ↓
Phase 3: Chunk Generation
    ├─→ For each chunk:
    │   ├─→ Get biome from region map
    │   ├─→ Load BiomeDefinition
    │   ├─→ Generate heightmap
    │   ├─→ Blend biomes if needed
    │   ├─→ Generate mesh
    │   └─→ Emit chunk_generated signal
    ↓
Generation Complete
    ↓
WorldPreview updates
    ↓
User sees final world
```

---

## World Builder

### Architecture Flow

```
┌─────────────────────────────────────────────────────────────┐
│              WorldBuilderUI                                   │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │  Step 1 │  │  Step 2 │  │  Step 3  │  │  Step 4  │ │
│  │  Seed   │  │  2D Map │  │ Terrain  │  │ Climate  │ │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘ │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │  Step 5  │  │  Step 6  │  │  Step 7  │              │
│  │ Biomes   │  │Resources  │  │Cities    │              │
│  └──────────┘  └──────────┘  └──────────┘              │
│                                                             │
│  ┌──────────┐  ┌──────────┐                              │
│  │  Step 8  │  │  Step 9  │                              │
│  │Preview   │  │  Export  │                              │
│  └──────────┘  └──────────┘                              │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐ │
│  │              Terrain3DManager                         │ │
│  │         (Terrain Generation & Management)            │ │
│  └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Class Responsibilities

#### WorldBuilderUI

**Primary Responsibilities:**
- Manage wizard step navigation
- Load and display step content
- Coordinate between 2D map and 3D terrain preview
- Handle world export and saving

#### MapMakerModule

**Primary Responsibilities:**
- Provide 2D map editing interface
- Handle brush tools and icon placement
- Generate heightmaps from user input
- Convert 2D map to 3D terrain data

#### Terrain3DManager

**Primary Responsibilities:**
- Manage Terrain3D plugin integration
- Generate terrain from heightmaps or noise
- Handle terrain import/export
- Coordinate terrain updates

---

## Data Flow

### World Generation Data Flow

```
JSON/Resources → WorldGenerationManager → World Mesh
     │                    │
     │                    ├─→ RegionSeed.json
     │                    ├─→ BiomeDefinition.tres
     │                    └─→ Biome textures
     │
     └─→ GameData.current_world_data
```

### World Builder Data Flow

```
JSON Files → WorldBuilderUI → Terrain3DManager → 3D Terrain
     │            │                  │
     │            │                  └─→ Terrain3D Node
     │            │
     │            └─→ MapMakerModule → 2D Map Canvas
     │
     └─→ biomes.json, civilizations.json, resources.json, map_icons.json
```

---

## Integration Points

### 2D Map → 3D Terrain

When 2D map editing completes:
1. `MapMakerModule` generates heightmap from user input
2. Heightmap exported to EXR format
3. `Terrain3DManager` imports heightmap into Terrain3D
4. 3D terrain preview updates in real-time

### World Builder → Export

When world generation completes:
1. `WorldBuilderUI` collects all step data
2. World data saved to JSON (`user://worlds/{name}.json`)
3. Heightmap exported to PNG/EXR (`user://exports/{name}_heightmap.png`)
4. Biome map exported (`user://exports/{name}_biomes.png`)

---

**End of Documentation**
