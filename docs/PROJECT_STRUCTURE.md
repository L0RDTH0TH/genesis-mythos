# ╔═══════════════════════════════════════════════════════════
# ║ PROJECT_STRUCTURE.md
# ║ Desc: Complete project folder structure and organization
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

# Project Structure

This document describes the complete folder structure of the Genesis Mythos project and explains the purpose of each directory.

## Root Directory

```
Final-Approach/
├── .cursor/              # Cursor IDE configuration
├── .gitignore           # Git ignore rules
├── assets/              # Game assets (models, textures, shaders, etc.)
├── core/                # Core system scripts and singletons
├── data/                # JSON data files and configuration
├── docs/                # Project documentation
├── godot/               # Godot-specific files
├── materials/           # Material resources
├── project.godot        # Godot project configuration
├── README.md            # Project readme
├── resources/           # Resource script definitions
├── scenes/              # Scene files (.tscn)
├── scripts/             # GDScript files
├── shaders/             # Shader files
├── singletons/          # Autoload singleton scripts
├── tests/               # Test files
├── themes/              # UI theme resources
├── tools/               # Development tools and utilities
└── ui/                  # UI component scenes and scripts
```

## Directory Descriptions

### `.cursor/`
Cursor IDE configuration and rules.
- `rules/project-rules.mdc` - Permanent project rules (locked)

### `assets/`
All game assets including models, textures, shaders, and UI elements.

```
assets/
├── environment/         # Environment assets (skyboxes, etc.)
│   └── skyboxes/      # HDR skybox files
├── environments/       # Environment resource files
├── fonts/             # Custom font files
├── icons/             # UI icon files
├── materials/         # Material resource files
├── meshes/            # Mesh resource files
├── models/            # 3D model files (GLB, TSCN)
├── shaders/           # Custom shader files
├── textures/          # Texture files
├── themes/            # Additional theme resources
└── ui/                # UI-specific assets
```

**Purpose**: Central location for all game assets. Organized by type for easy management.

### `core/`
Core system scripts and singletons that form the foundation of the game.

```
core/
├── procedural/        # Procedural generation systems
├── scenes/           # Core scene definitions
├── sim/              # Simulation systems (entity, economy, etc.)
├── singletons/       # Core singleton scripts
├── streaming/        # World streaming system
└── utils/           # Core utility scripts
```

**Purpose**: Core game systems that are independent of specific features. These are the foundational systems that other parts of the game depend on.

**Key Files**:
- `singletons/eryndor.gd` - Main game singleton
- `streaming/world_streamer.gd` - World streaming system
- `sim/entity_sim.gd` - Entity simulation
- `sim/faction_economy.gd` - Faction economy system

### `data/`
JSON data files and configuration files.

```
data/
├── config/           # Configuration files
│   ├── logging_config.json
│   ├── terrain_generation.json
│   └── world_builder_ui.json
├── map_icons.json    # 2D map icon definitions
├── biomes.json       # Biome definitions with temperature/rainfall ranges
├── civilizations.json # Civilization types for city assignment
└── resources.json    # Resource type definitions
```

**Purpose**: All data-driven content. JSON files define game content that can be modified without code changes.

**Key Files**:
- `map_icons.json` - Icon definitions for 2D map maker (forest, mountain, city, etc.)
- `biomes.json` - Biome definitions with climate ranges and colors
- `civilizations.json` - Civilization types (Human Kingdom, Elven Enclave, etc.)
- `resources.json` - Resource types (Iron, Gold, Mana Crystal, etc.)

### `docs/`
Project documentation.

```
docs/
├── api/              # API reference documentation
├── architecture/     # Architecture documentation
├── archive/          # Archived documentation
├── dev/              # Development guides
├── schemas/          # Data schema documentation
├── technical/        # Technical documentation
└── testing/          # Testing documentation
```

**Purpose**: Complete project documentation including API references, architecture diagrams, coding standards, and guides.

### `godot/`
Godot-specific files and editor configuration.

**Purpose**: Godot editor state and configuration. Typically auto-generated.

### `materials/`
Material resource files.

**Purpose**: Reusable material definitions for 3D objects.

### `resources/`
Resource script class definitions.

**Purpose**: Custom Resource classes that extend Godot's Resource system. These define data structures that can be saved as `.tres` files.

**Note**: Previously contained CharacterData, WorldData, and PointBuyCostTable resources, which have been removed.

### `scenes/`
All scene files (.tscn).

```
scenes/
├── ui/               # UI component scenes
└── MainMenu.tscn     # Main menu scene
```

**Purpose**: Godot scene files that define node hierarchies and configurations.

**Key Scenes**:
- `MainMenu.tscn` - Main menu scene (entry point)

### `scripts/`
All GDScript files organized by feature/system.

```
scripts/
├── data/             # Data loading/processing scripts
├── preview/          # Preview system scripts
├── singletons/       # Autoload singleton scripts
├── utils/            # Utility scripts
├── Logger.gd         # Logging system
├── Main.gd           # Main entry point
└── MainMenu.gd       # Main menu script
```

**Purpose**: All game logic and scripts. Organized by feature for easy navigation.

**Key Files**:
- `Logger.gd` - Centralized logging system
- `Main.gd` - Main entry point
- `MainMenu.gd` - Main menu controller

### `shaders/`
Shader files organized by type.

```
shaders/
├── compute/          # Compute shaders
│   ├── noise/       # Noise generation shaders
│   └── shapes/      # Shape generation shaders
├── blue_glow.gdshader
└── ...
```

**Purpose**: Custom shaders for visual effects and procedural generation.

### `singletons/`
Autoload singleton script definitions.

**Purpose**: Scripts that are automatically loaded when the game starts. These are configured in `project.godot` under `[autoload]`.

**Current Autoloads** (from `project.godot`):
- `Eryndor` - Core game singleton
- `WorldStreamer` - World streaming system
- `EntitySim` - Entity simulation
- `FactionEconomy` - Faction economy system

### `tests/`
Test files and test runners.

```
tests/
├── interaction_only/ # Interaction-based tests
│   ├── fixtures/     # Test fixtures
│   └── helpers/     # Test helper utilities
└── ui/               # UI-specific tests
```

**Purpose**: Automated tests for game systems and features.

### `themes/`
UI theme resource files.

```
themes/
└── bg3_theme.tres   # Main UI theme (CRITICAL)
```

**Purpose**: UI styling and theming. The single `bg3_theme.tres` is applied globally to all UI elements.

**Important**: This is the ONLY theme file used in the project. All UI styling must come from this theme.

### `tools/`
Development tools and utilities.

```
tools/
└── tripo3d_prompts/  # 3D model generation prompts
```

**Purpose**: Development tools, scripts, and utilities that assist in content creation or project management.

### `ui/`
UI component scenes and scripts.

```
ui/
├── components/       # Reusable UI components
├── main_menu/        # Main menu UI
└── theme/            # UI theme resources
```

**Purpose**: UI-specific scenes and scripts. Reusable UI components and menu systems.

## File Naming Conventions

### Scripts
- Format: `ClassName.gd`
- Example: `PlayerController.gd`, `HealthBar.gd`

### Scenes
- Format: `SceneName.tscn`
- Example: `MainMenu.tscn`, `PlayerCharacter.tscn`

### Resources
- Format: `ResourceName.tres`
- Example: `ItemData.tres`, `WeaponStats.tres`

### JSON Data
- Format: `data_name.json`
- Example: `races.json`, `classes.json`

## Important Notes

### Never Modify Without Updating Rules
The folder structure is defined in `.cursor/rules/project-rules.mdc`. If you need to add or remove folders, you must update the project rules first.

### Data-Driven Design
All game content should come from JSON files in `data/` or Resource files in `resources/`. Never hard-code content in scripts.

### Single Theme
All UI must use the single theme file: `themes/bg3_theme.tres`. Never create additional theme files.

### Autoload Singletons
Singletons are configured in `project.godot` under `[autoload]`. To add a new singleton:
1. Create the script in `singletons/` or `core/singletons/`
2. Add it to `project.godot` under `[autoload]`
3. Update this documentation

## Recent Changes

### Removed Systems
The following systems have been removed and their folders/files deleted:
- Character Creation System (`scenes/character/`, `scripts/character/`)
- World Generation System (`scenes/sections/`, `scripts/world_creation/`)
- Related data files (`data/races.json`, `data/classes.json`, etc.)
- Related resources (`resources/CharacterData.gd`, `resources/WorldData.gd`)

The project is now in a clean state for new feature development.

---

**This structure is maintained as part of the permanent project rules. See `.cursor/rules/project-rules.mdc` for the complete rules.**
