# ╔═══════════════════════════════════════════════════════════
# ║ Genesis Mythos
# ║ D&D 5e Character Creation & World Generation System for Godot 4.3
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

Genesis Mythos is a comprehensive D&D 5e character creation and world generation system built in Godot 4.3. Featuring pixel-perfect UI design, data-driven architecture, and full character customization with procedural world generation.

## Table of Contents

- [Project Overview](#project-overview)
- [Installation & Setup](#installation--setup)
- [Folder Structure](#folder-structure)
- [Key Features](#key-features)
- [Usage Guide](#usage-guide)
- [Data-Driven Elements](#data-driven-elements)
- [Architecture](#architecture)
- [API Documentation](#api-documentation)
- [Contributing Guidelines](#contributing-guidelines)
- [License](#license)

## Project Overview

This project is a complete recreation of Baldur's Gate 3's character creation system, built in Godot 4.3 using GDScript. The system is fully data-driven, meaning all game data (races, classes, abilities, etc.) is loaded from JSON files, making it easy to extend and modify without code changes.

### Core Principles

- **100% Data-Driven**: All game data comes from JSON files or Resources
- **Pixel-Perfect UI**: Professional D&D 5e character creation interface
- **Performance**: 60 FPS target on mid-range hardware
- **Extensible**: Easy to add new races, classes, backgrounds, etc.
- **Type-Safe**: Typed GDScript throughout for better error detection

## Installation & Setup

### Prerequisites

- **Godot 4.3.x** (stable version required - currently 4.3.0 or any 4.3.x patch)
- No additional dependencies required

### Setup Steps

1. **Clone or download the project**
   ```bash
   git clone <repository-url>
   cd Final-Approach
   ```

2. **Open in Godot**
   - Launch Godot 4.3.x
   - Click "Import" and select the `project.godot` file
   - Click "Import & Edit"

3. **Verify Data Files**
   - Ensure all JSON files are present in `res://data/`
   - Check that `res://themes/bg3_theme.tres` exists

4. **Run the Project**
   - Press F5 or click the "Play" button
   - The main menu should appear

### Project Configuration

The project is configured in `project.godot`:

- **Main Scene**: `res://scenes/MainMenu.tscn`
- **Window Size**: 1920x1080 (configurable)
- **Theme**: `res://themes/bg3_theme.tres` (applied globally)
- **Autoload Singletons**:
  - `GameData`: Loads all JSON data
  - `Logger`: Centralized logging system
  - `PlayerData`: Stores character creation state

## Folder Structure

```
res://
├── assets/                    # Game assets
│   ├── data/                  # Asset-specific data (biome textures, etc.)
│   ├── environment/           # Skyboxes and environment assets
│   ├── fonts/                 # Custom fonts
│   ├── icons/                 # UI icons
│   ├── materials/             # Material resources
│   ├── meshes/                # Mesh resources
│   ├── models/                # 3D character models (GLB/TSCN)
│   │   └── character_bases/   # Race-specific character models
│   ├── presets/               # World generation presets
│   ├── shaders/               # Custom shaders
│   ├── textures/              # Texture resources
│   ├── themes/                # Additional theme resources
│   └── worlds/                # World resources
├── core/                      # Core system scripts
│   └── CryptographicValidator.gd
├── data/                      # All JSON data files (CRITICAL)
│   ├── abilities.json         # Ability score definitions
│   ├── appearance_presets.json # Character appearance presets
│   ├── backgrounds.json       # Character backgrounds
│   ├── classes.json           # Character classes and subclasses
│   ├── point_buy.json         # Point-buy system costs
│   ├── races.json             # Races and subraces
│   ├── skills.json            # Skill definitions
│   ├── voices.json            # Voice options
│   ├── appearance/            # Appearance-related data
│   │   └── sliders/           # Slider presets
│   ├── character/             # Character-specific data
│   │   └── sex_variants.json  # Gender variants
│   └── config/                # Configuration files
│       └── logging_config.json # Logger configuration
├── docs/                      # Documentation files
├── resources/                 # Resource scripts (CharacterData, WorldData, etc.)
├── scenes/                    # All scene files (.tscn)
│   ├── character/             # Character creation scenes
│   │   ├── CharacterCreationRoot.tscn
│   │   ├── CharacterPreview3D.tscn
│   │   ├── tabs/              # Tab scenes (Race, Class, etc.)
│   │   └── appearance/        # Appearance customization scenes
│   ├── sections/              # World creation sections
│   ├── ui/                    # UI components
│   └── MainMenu.tscn          # Main menu scene
├── scripts/                   # All GDScript files
│   ├── character/             # Character creation scripts
│   │   ├── CharacterCreationRoot.gd
│   │   ├── CharacterPreview3D.gd
│   │   └── tabs/              # Tab controllers
│   │       ├── RaceTab.gd
│   │       ├── ClassTab.gd
│   │       ├── BackgroundTab.gd
│   │       ├── AbilityScoreTab.gd
│   │       ├── AppearanceTab.gd
│   │       ├── NameConfirmTab.gd
│   │       ├── StatsTab.gd
│   │       ├── TabNavigation.gd
│   │       └── components/    # Reusable UI components
│   ├── singletons/            # Autoload singletons
│   │   ├── GameData.gd        # Data loader
│   │   └── PlayerData.gd      # Character state
│   ├── world_creation/        # World generation scripts
│   ├── ui/                    # UI helper scripts
│   ├── preview/               # Preview system scripts
│   ├── utils/                 # Utility scripts
│   ├── Logger.gd              # Logging system
│   └── Main.gd                # Main entry point
├── themes/                    # Theme resources
│   └── bg3_theme.tres        # Main UI theme (CRITICAL)
├── tests/                     # Test suites
└── project.godot              # Project configuration
```

## Key Features

### Character Creation System

1. **Race Selection**
   - Visual race grid with previews
   - Subrace selection
   - Real-time preview panel updates
   - Ability score bonus preview

2. **Class Selection**
   - Class grid with descriptions
   - Subclass selection
   - Hit die and proficiency display

3. **Background Selection**
   - Background cards with features
   - Skill proficiency display
   - Feature descriptions

4. **Ability Score Assignment**
   - Point-buy system
   - Real-time point calculation
   - Racial bonus integration
   - Final score preview

5. **Appearance Customization**
   - 3D character preview
   - Head, body, hair customization
   - Color pickers for skin, hair, etc.
   - Gender selection

6. **Name & Confirmation**
   - Character naming
   - Voice selection
   - Final review and confirmation

### World Creation System

- **[NEW] Data-Driven Biomes** - Biome-blended world generation using BiomeDefinition resources
- Three-phase generation pipeline: Seed → Regions → Chunks
- Region-seeded placement system using RegionSeed.json
- Smooth biome blending at region boundaries
- Procedural terrain generation with biome-specific noise parameters
- Climate and civilization settings
- Resource distribution per biome
- Magic system configuration

### Technical Features

- **Data-Driven Architecture**: All content loaded from JSON and Resources
- **[NEW] Data-Driven Biomes**: BiomeDefinition.tres resources for extensible biome system
- **Centralized Logging**: Configurable logging system with file output
- **Performance Optimized**: LOD system, efficient rendering, threaded generation
- **Type-Safe Code**: Full GDScript typing
- **Modular Design**: Reusable components and systems

## Usage Guide

### Running the Project

1. **Start from Main Menu**
   - Launch the project (F5)
   - Main menu appears automatically

2. **Create a Character**
   - Click "New Character" or similar button
   - Follow the tab navigation:
     1. Select Race → Confirm
     2. Select Class → Confirm
     3. Select Background → Confirm
     4. Assign Ability Scores → Confirm
     5. Customize Appearance → Confirm
     6. Enter Name & Confirm → Save

3. **Navigate Tabs**
   - Use the tab navigation bar at the top
   - Previous/Next buttons for sequential navigation
   - Direct tab clicking (if enabled)

### Keyboard Controls

- **W/S**: Camera zoom in/out (in character preview)
- **A/D**: Camera orbit left/right (in character preview)

### Data Modification

To add new races, classes, or backgrounds:

1. **Add a New Race**
   - Open `res://data/races.json`
   - Add a new race object following the existing schema
   - Save the file
   - The game will automatically load it on next run

2. **Add a New Class**
   - Open `res://data/classes.json`
   - Add a new class object following the existing schema
   - Save the file

3. **Modify Point-Buy Costs**
   - Open `res://data/point_buy.json`
   - Adjust the `costs` dictionary
   - Modify `starting_points`, `min_base_score`, or `max_base_score` as needed

## Data-Driven Elements

For complete JSON schema documentation, see [docs/schemas/DATA_SCHEMAS.md](docs/schemas/DATA_SCHEMAS.md).

For complete API documentation, see [docs/api/API_REFERENCE.md](docs/api/API_REFERENCE.md).

### JSON Schema Documentation

#### `races.json`

Array of race objects. Each race has:

```json
{
  "id": "string",                    // Unique race identifier (e.g., "dwarf")
  "name": "string",                  // Display name (e.g., "Dwarf")
  "description": "string",           // Race description text
  "speed": "string",                 // Movement speed (e.g., "7.5m / 25ft")
  "size": "string",                 // Size category (e.g., "Medium")
  "features": ["string"],           // Array of feature descriptions
  "ability_bonuses": {              // Ability score bonuses
    "strength": 0,
    "dexterity": 0,
    "constitution": 0,
    "intelligence": 0,
    "wisdom": 0,
    "charisma": 0
  },
  "subraces": [                     // Optional array of subraces
    {
      "id": "string",               // Subrace identifier
      "name": "string",              // Subrace display name
      "description": "string",      // Subrace description
      "features": ["string"],       // Additional features
      "ability_bonuses": {}         // Additional ability bonuses
    }
  ]
}
```

#### `classes.json`

Array of class objects. Each class has:

```json
{
  "id": "string",                    // Unique class identifier
  "name": "string",                  // Display name
  "hit_die": "string",               // Hit die (e.g., "1d12")
  "description": "string",           // Class description
  "proficiencies": ["string"],       // Array of proficiency names
  "features": ["string"],           // Class features
  "subclasses": [                   // Optional subclasses
    {
      "id": "string",               // Subclass identifier
      "name": "string",             // Subclass display name
      "description": "string"       // Subclass description
    }
  ]
}
```

#### `backgrounds.json`

Array of background objects. Each background has:

```json
{
  "id": "string",                    // Unique background identifier
  "name": "string",                  // Display name
  "description": "string",           // Background description
  "skill_proficiencies": ["string"], // Skills granted
  "feature": "string",               // Background feature name
  "feature_description": "string",  // Feature description
  "languages": 0,                    // Number of languages granted
  "tools": ["string"],               // Tool proficiencies
  "inspiration": "string"           // Inspiration trigger description
}
```

#### `abilities.json`

Dictionary mapping ability keys to display info:

```json
{
  "strength": {
    "short": "STR",
    "full": "Strength"
  },
  "dexterity": {
    "short": "DEX",
    "full": "Dexterity"
  }
  // ... (constitution, intelligence, wisdom, charisma)
}
```

#### `point_buy.json`

Point-buy system configuration:

```json
{
  "starting_points": 27,            // Initial point-buy points
  "min_base_score": 6,              // Minimum base ability score
  "max_base_score": 25,             // Maximum base ability score
  "costs": {                        // Cost to reach each score
    "6": -4,                        // Negative = refund when decreasing
    "7": -2,
    "8": 0,                         // Baseline (no cost)
    "9": 1,
    // ... up to "25": 75
  }
}
```

#### `skills.json`

Dictionary of skill definitions:

```json
{
  "skill_id": {
    "name": "string",                // Display name
    "ability": "string",             // Associated ability (e.g., "dexterity")
    "description": "string"          // Skill description
  }
}
```

#### `appearance_presets.json`

Dictionary of appearance presets for quick application.

#### `voices.json`

Array of voice options:

```json
[
  {
    "id": "string",                  // Voice identifier
    "name": "string",                // Display name
    "description": "string"          // Voice description
  }
]
```

### Resource Files

#### `CharacterData.gd`

Resource class for storing complete character data. Properties include:
- Race/class/background IDs
- Ability scores
- Appearance data
- Name and voice
- Skill proficiencies

#### `WorldData.gd`

Resource class for world generation parameters.

#### `PointBuyCostTable.gd`

Resource for point-buy cost calculations.

## Architecture

### Singleton System

#### `GameData` (Autoload)

Central data loader singleton that loads all JSON files on startup.

**Key Methods:**
- `load_all_data()`: Loads all JSON files into memory
- `_load_json_array(path)`: Loads a JSON array file
- `_load_json_dict(path)`: Loads a JSON dictionary file

**Data Properties:**
- `races: Array[Dictionary]`
- `classes: Array[Dictionary]`
- `backgrounds: Array[Dictionary]`
- `abilities: Dictionary`
- `appearance_presets: Dictionary`
- `voices: Array[Dictionary]`
- `point_buy_data: Dictionary`
- `skills: Dictionary`

#### `PlayerData` (Autoload)

Stores the current character creation state.

**Key Properties:**
- `race_id`, `subrace_id`, `race_data`
- `class_id`, `subclass_id`, `class_data`
- `background_id`, `background_data`
- `ability_scores: Dictionary`
- `points_remaining: int`
- `appearance_data: Dictionary`
- `character_name: String`
- `voice_id: String`

**Key Methods:**
- `reset()`: Reset all data to defaults
- `get_racial_bonus(ability_key)`: Get racial bonus for ability
- `get_final_ability_score(ability_key)`: Get base + racial bonus
- `get_ability_modifier(ability_key)`: Calculate ability modifier

**Signals:**
- `stats_changed`: Emitted when ability scores change
- `points_changed`: Emitted when point-buy points change
- `racial_bonuses_updated`: Emitted when race selection changes

#### `Logger` (Autoload)

Centralized logging system with configurable levels and outputs.

**Log Levels:**
- `DEBUG`: Detailed debugging information
- `INFO`: General information
- `WARNING`: Warning messages
- `ERROR`: Error messages

**Key Methods:**
- `debug(message, module)`: Log debug message
- `info(message, module)`: Log info message
- `warning(message, module)`: Log warning
- `error(message, module)`: Log error
- `start_timer(timer_id, module)`: Start performance timer
- `end_timer(timer_id, log_result)`: End performance timer

**Configuration:**
- Loaded from `res://data/config/logging_config.json`
- Supports console, file, and UI outputs
- Module-specific log levels

### Character Creation Flow

1. **CharacterCreationRoot** loads and manages tabs
2. **TabNavigation** handles tab switching and validation
3. Each tab (RaceTab, ClassTab, etc.) handles its own logic
4. **PlayerData** stores state and emits signals
5. **Preview panels** update based on PlayerData signals
6. **CharacterPreview3D** renders 3D character model

### UI System

- **Single Theme**: `bg3_theme.tres` applied globally
- **No Magic Numbers**: All styling from theme
- **Data-Driven Text**: All UI text from JSON or Resources
- **Reusable Components**: Components in `scripts/character/tabs/components/`

## API Documentation

For complete API reference documentation, see [docs/api/API_REFERENCE.md](docs/api/API_REFERENCE.md).

### Core Classes

#### `CharacterCreationRoot`

Main controller for character creation flow.

**Signals:**
- `race_confirmed(race_id: String, subrace_id: String)`

**Key Methods:**
- `_load_tab(tab_name: String)`: Load and display a tab
- `_on_tab_changed(tab_name: String)`: Handle tab navigation
- `_update_preview_panel(race_id: String, subrace_id: String)`: Update preview

**Tab Scenes:**
- `"Race"` → `res://scenes/character/tabs/RaceTab.tscn`
- `"Class"` → `res://scenes/character/tabs/ClassTab.tscn`
- `"Background"` → `res://scenes/character/tabs/BackgroundTab.tscn`
- `"AbilityScore"` → `res://scenes/character/tabs/AbilityScoreTab.tscn`
- `"Appearance"` → `res://scenes/character/tabs/AppearanceTab.tscn`
- `"NameConfirm"` → `res://scenes/character/tabs/NameConfirmTab.tscn`

#### `TabNavigation`

Handles tab navigation and validation.

**Signals:**
- `tab_changed(tab_name: String)`

**Key Methods:**
- `_select_tab(tab_name: String)`: Switch to a tab
- `enable_next_tab()`: Enable the next tab button
- `disable_next_tab()`: Disable the next tab button

### Component Classes

#### `RaceEntry`

UI component for displaying a race option.

**Signals:**
- `race_selected(race_id: String, subrace_id: String)`

#### `ClassEntry`

UI component for displaying a class option.

**Signals:**
- `class_selected(class_id: String, subclass_id: String)`

#### `BackgroundEntry`

UI component for displaying a background option.

**Signals:**
- `background_selected(background_id: String)`

#### `AbilityScoreEntry`

UI component for ability score adjustment.

**Signals:**
- `score_changed(ability_key: String, new_score: int)`

### World Generation Classes

#### `WorldGenerator`

Main world generation controller.

#### `TerrainGenerator`

Generates terrain heightmaps and meshes.

#### `BiomeTextureManager`

Manages biome texture assignment.

#### `FoliageGenerator`

Generates foliage placement.

#### `POIGenerator`

Generates points of interest.

#### `RiverGenerator`

Generates river systems.

#### `ErosionGenerator`

Applies erosion effects to terrain.

#### `LODManager`

Manages level-of-detail for performance.

## Contributing Guidelines

### Code Style

**MANDATORY** - All code must follow these rules:

1. **Naming Conventions:**
   - Variables/functions: `snake_case`
   - Classes/nodes/resources: `PascalCase`
   - Constants: `ALL_CAPS`

2. **File Structure:**
   - One class per file
   - File name must match class name: `MyClass.gd`

3. **Script Header:**
   Every script MUST start with:
   ```gdscript
   # ╔═══════════════════════════════════════════════════════════
   # ║ MyClassName.gd
   # ║ Desc: One-line description
   # ║ Author: Lordthoth
   # ╚═══════════════════════════════════════════════════════════
   ```

4. **Typed GDScript:**
   - Use type hints everywhere: `var count: int = 0`
   - Use `@onready var` (not old `onready var`)
   - Return types on all functions: `func do_thing() -> void:`

5. **Documentation:**
   - Every public function needs a docstring: `"""Description"""`
   - Inline comments for complex logic
   - Explain parameters and return values

6. **No Magic Numbers:**
   - Use constants or theme overrides
   - No hard-coded colors, sizes, etc.

7. **Data-Driven:**
   - Never hard-code races, classes, etc.
   - Load everything from JSON or Resources

### Folder Structure

**NEVER** add folders outside the defined structure. If you need a new folder, update the project rules first.

### Testing

- Write tests for new features in `tests/`
- Use GUT (Godot Unit Test) framework
- Test data loading, calculations, and UI interactions

### Pull Request Process

1. Create a feature branch
2. Follow all code style rules
3. Add documentation for new features
4. Update JSON schemas if adding new data
5. Test thoroughly
6. Submit PR with clear description

## License

[Specify your license here]

---

**Genesis Mythos - Project by Grok + Cursor + Lordthoth**

*For complete project rules and conventions, see `.cursor/rules/project-rules.mdc`*
