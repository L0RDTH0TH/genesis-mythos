# Architecture Overview

**Last Updated:** 2025-01-09  
**Project:** Genesis (Godot 4.3)  
**Author:** Lordthoth

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Core Systems](#core-systems)
3. [World Generation](#world-generation)
4. [Character Creation](#character-creation)
5. [Data Flow](#data-flow)

---

## System Architecture

Genesis Mythos follows a modular, data-driven architecture with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    GameData Singleton                    │
│              (JSON Data Loader & Storage)                │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Character  │  │     World     │  │     UI       │
│   Creation   │  │  Generation   │  │   System     │
└──────────────┘  └──────────────┘  └──────────────┘
```

---

## Core Systems

### GameData Singleton

Central data management singleton that loads all JSON data files on startup.

**Responsibilities:**
- Load all JSON data files (races, classes, backgrounds, etc.)
- Provide data access to all systems
- Store current world and character data

### Character Creation System

Complete D&D 5e character creation flow with tab-based navigation.

**Key Components:**
- `CharacterCreationRoot.gd` - Main controller
- `TabNavigation.gd` - Tab switching and validation
- Individual tab controllers (RaceTab, ClassTab, etc.)
- `PlayerData` singleton - Character state storage
- `CharacterPreview3D` - 3D character preview

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

## Character Creation

### Architecture Flow

```
┌─────────────────────────────────────────────────────────────┐
│              CharacterCreationRoot                          │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │   Race   │  │  Class   │  │Background│  │  Ability  │ │
│  │   Tab    │  │   Tab    │  │   Tab    │  │   Tab     │ │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘ │
│                                                             │
│  ┌──────────┐  ┌──────────┐                              │
│  │Appearance│  │   Name   │                              │
│  │   Tab    │  │   Tab    │                              │
│  └──────────┘  └──────────┘                              │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐ │
│  │              PlayerData Singleton                     │ │
│  │         (Character State Storage)                    │ │
│  └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Class Responsibilities

#### CharacterCreationRoot

**Primary Responsibilities:**
- Manage tab navigation
- Load and display tab scenes
- Coordinate between tabs and preview
- Handle character confirmation

#### TabNavigation

**Primary Responsibilities:**
- Manage tab button states
- Validate tab completion
- Enable/disable navigation
- Emit tab change signals

#### PlayerData Singleton

**Primary Responsibilities:**
- Store current character creation state
- Provide calculated values (ability modifiers, etc.)
- Emit signals on state changes
- Reset character data

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

### Character Creation Data Flow

```
JSON Files → GameData → PlayerData → CharacterCreationRoot → UI
     │          │          │              │
     │          │          │              └─→ Tab Controllers
     │          │          │
     │          │          └─→ Character Preview
     │          │
     │          └─→ CharacterData Resource (on save)
     │
     └─→ races.json, classes.json, backgrounds.json, etc.
```

---

## Integration Points

### World → Character Creation

When world generation completes:
1. `WorldGenerationManager` emits `generation_complete`
2. `WorldCreator` stores world in `GameData.current_world_data`
3. Scene transitions to character creation
4. Character creation can access world via `GameData.current_world_data`

### Character Creation → Game

When character creation completes:
1. `CharacterCreationRoot` creates `CharacterData` resource
2. Stores in `GameData.current_character_data`
3. Scene transitions to main game
4. Game can access character and world data

---

**End of Documentation**
