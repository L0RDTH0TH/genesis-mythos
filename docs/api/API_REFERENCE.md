# API Reference Documentation

Complete API reference for all public classes, methods, signals, and properties in the project.

## Table of Contents

- [Singletons](#singletons)
  - [GameData](#gamedata)
  - [PlayerData](#playerdata)
  - [Logger](#logger)
- [Character Creation](#character-creation)
  - [CharacterCreationRoot](#charactercreationroot)
  - [TabNavigation](#tabnavigation)
  - [RaceTab](#racetab)
  - [ClassTab](#classtab)
  - [BackgroundTab](#backgroundtab)
  - [AbilityScoreTab](#abilityscoretab)
  - [AppearanceTab](#appearancetab)
  - [NameConfirmTab](#nameconfirmtab)
- [Resources](#resources)
  - [CharacterData](#characterdata)
  - [WorldData](#worlddata)
  - [PointBuyCostTable](#pointbuycosttable)
- [World Generation](#world-generation)
  - [WorldGenerator](#worldgenerator)
  - [TerrainGenerator](#terraingenerator)
  - [BiomeTextureManager](#biometexturemanager)

---

## Singletons

### GameData

**Path:** `res://scripts/singletons/GameData.gd`  
**Type:** Autoload Singleton (Node)

Central data loader that loads all JSON files on startup.

#### Properties

```gdscript
var races: Array[Dictionary]          # All races from races.json
var classes: Array[Dictionary]         # All classes from classes.json
var backgrounds: Array[Dictionary]     # All backgrounds from backgrounds.json
var abilities: Dictionary              # Ability definitions from abilities.json
var appearance_presets: Dictionary      # Appearance presets from appearance_presets.json
var voices: Array[Dictionary]          # Voice options from voices.json
var point_buy_data: Dictionary         # Point-buy config from point_buy.json
var skills: Dictionary                 # Skill definitions from skills.json
var current_world_data: Dictionary     # World generation data
```

#### Methods

##### `load_all_data() -> void`

Loads all JSON data files into memory. Called automatically during `_ready()`.

##### `_load_json_array(path: String) -> Array[Dictionary]`

Loads a JSON file containing an array of dictionaries.

**Parameters:**
- `path` (String): File path relative to project root

**Returns:**
- `Array[Dictionary]`: Array of dictionaries, or empty array on error

##### `_load_json_dict(path: String) -> Dictionary`

Loads a JSON file containing a dictionary object.

**Parameters:**
- `path` (String): File path relative to project root

**Returns:**
- `Dictionary`: Dictionary object, or empty dictionary on error

---

### PlayerData

**Path:** `res://scripts/singletons/PlayerData.gd`  
**Type:** Autoload Singleton (Node)

Stores character creation state and provides methods for score calculations.

#### Properties

```gdscript
# Race selection
var race_id: String                    # Selected race ID
var subrace_id: String                 # Selected subrace ID
var race_data: Dictionary               # Complete race data dictionary

# Class selection
var class_id: String                   # Selected class ID
var subclass_id: String                 # Selected subclass ID
var class_data: Dictionary              # Complete class data dictionary

# Background selection
var background_id: String              # Selected background ID
var background_data: Dictionary         # Complete background data dictionary

# Ability scores (base values, before racial bonuses)
var ability_scores: Dictionary          # Keys: "strength", "dexterity", etc.

# Point-buy system
var points_remaining: int                # Remaining point-buy points

# Skill proficiencies
var selected_skill_proficiencies: Array[String]  # User-selected skills

# Appearance
var appearance_data: Dictionary        # Appearance customization data
var gender: String                      # "male" or "female"

# Character identity
var character_name: String              # Character's name
var voice_id: String                    # Selected voice ID
```

#### Signals

```gdscript
signal stats_changed                    # Emitted when ability scores change
signal points_changed                   # Emitted when point-buy points change
signal racial_bonuses_updated          # Emitted when race/subrace changes
```

#### Methods

##### `reset() -> void`

Resets all player data to default values. Emits `stats_changed` and `points_changed`.

##### `get_starting_points() -> int`

Gets starting point-buy points from GameData.

**Returns:**
- `int`: Starting points (typically 27)

##### `get_min_score() -> int`

Gets minimum ability score from GameData.

**Returns:**
- `int`: Minimum score (typically 6)

##### `get_max_score() -> int`

Gets maximum ability score from GameData.

**Returns:**
- `int`: Maximum score (typically 25)

##### `increase_ability_score(ability_key: String) -> bool`

Increases an ability score if within valid range.

**Parameters:**
- `ability_key` (String): Ability key ("strength", "dexterity", etc.)

**Returns:**
- `bool`: `true` if score was increased, `false` if at maximum

**Emits:** `stats_changed`, `points_changed`

##### `decrease_ability_score(ability_key: String) -> bool`

Decreases an ability score if within valid range.

**Parameters:**
- `ability_key` (String): Ability key

**Returns:**
- `bool`: `true` if score was decreased, `false` if at minimum

**Emits:** `stats_changed`, `points_changed`

##### `get_racial_bonus(ability_key: String) -> int`

Gets total racial bonus for an ability (race + subrace).

**Parameters:**
- `ability_key` (String): Ability key

**Returns:**
- `int`: Total racial bonus (can be negative, zero, or positive)

##### `get_final_ability_score(ability_key: String) -> int`

Gets final ability score (base + racial bonus).

**Parameters:**
- `ability_key` (String): Ability key

**Returns:**
- `int`: Final ability score

##### `get_ability_modifier(ability_key: String) -> int`

Calculates ability modifier using D&D 5e formula: `floor((score - 10) / 2.0)`.

**Parameters:**
- `ability_key` (String): Ability key

**Returns:**
- `int`: Ability modifier

---

### Logger

**Path:** `res://scripts/Logger.gd`  
**Type:** Autoload Singleton (Node)

Centralized logging system with configurable levels and outputs.

#### Enums

```gdscript
enum LOG_LEVEL {
    DEBUG,      # Detailed debugging information
    INFO,       # General information
    WARNING,    # Warning messages
    ERROR       # Error messages
}
```

#### Signals

```gdscript
signal log_event(level: LOG_LEVEL, message: String, module: String)
```

#### Methods

##### `debug(message: String, module: String = "") -> void`

Logs a DEBUG level message.

##### `info(message: String, module: String = "") -> void`

Logs an INFO level message.

##### `warning(message: String, module: String = "") -> void`

Logs a WARNING level message.

##### `error(message: String, module: String = "") -> void`

Logs an ERROR level message.

##### `start_timer(timer_id: String, module: String = "") -> void`

Starts a performance timer.

**Parameters:**
- `timer_id` (String): Unique timer identifier
- `module` (String): Optional module name

##### `end_timer(timer_id: String, log_result: bool = true) -> float`

Ends a performance timer and optionally logs the result.

**Parameters:**
- `timer_id` (String): Timer identifier
- `log_result` (bool): Whether to log the result

**Returns:**
- `float`: Elapsed time in milliseconds, or -1.0 if timer not found

---

## Character Creation

### CharacterCreationRoot

**Path:** `res://scripts/character/CharacterCreationRoot.gd`  
**Type:** Control

Main controller for character creation flow. Manages tab loading and preview updates.

#### Signals

```gdscript
signal race_confirmed(race_id: String, subrace_id: String)
```

#### Properties

```gdscript
var current_tab_instance: Node         # Currently loaded tab instance
var selected_race: String             # Selected race ID
var selected_subrace: String          # Selected subrace ID
var selected_class: String            # Selected class ID
var selected_background: String       # Selected background ID
var final_ability_scores: Dictionary  # Final ability scores
var appearance_data: Dictionary       # Appearance data
var character_name: String            # Character name
var selected_voice: String            # Selected voice ID
```

#### Methods

##### `_load_tab(tab_name: String) -> void`

Loads and displays a character creation tab.

**Parameters:**
- `tab_name` (String): Tab name ("Race", "Class", "Background", etc.)

**Behavior:**
- Fades out current tab
- Loads new tab scene
- Fades in new tab
- Connects tab signals

##### `_on_tab_changed(tab_name: String) -> void`

Handles tab navigation changes.

**Parameters:**
- `tab_name` (String): Name of tab being switched to

##### `_update_preview_panel(race_id: String, subrace_id: String) -> void`

Updates the right preview panel with race details.

**Parameters:**
- `race_id` (String): Race ID
- `subrace_id` (String): Subrace ID (empty if none)

---

### TabNavigation

**Path:** `res://scripts/character/tabs/TabNavigation.gd`  
**Type:** Control

Left sidebar navigation controller for character creation tabs.

#### Signals

```gdscript
signal tab_changed(tab_name: String)
```

#### Constants

```gdscript
const TAB_ORDER := [
    "Race", "Class", "Background", 
    "AbilityScore", "Appearance", "NameConfirm"
]
```

#### Methods

##### `_select_tab(tab_name: String) -> void`

Selects a tab and updates button states.

**Parameters:**
- `tab_name` (String): Tab name from TAB_ORDER

##### `enable_next_tab() -> void`

Enables and advances to the next tab in sequence. Called when a tab emits `tab_completed`.

##### `_can_select_tab(tab_name: String) -> bool`

Checks if a tab can be selected (sequential unlocking).

**Parameters:**
- `tab_name` (String): Tab name

**Returns:**
- `bool`: `true` if tab can be selected

---

### RaceTab

**Path:** `res://scripts/character/tabs/RaceTab.gd`  
**Type:** Control

Two-stage race → subrace selection tab.

#### Signals

```gdscript
signal race_selected(race_id: String, subrace_id: String)
signal tab_completed()
```

#### Methods

##### `_populate_list() -> void`

Populates the race grid based on current mode (race or subrace).

##### `_on_race_entry_selected(race_id: String) -> void`

Handles race entry selection.

**Parameters:**
- `race_id` (String): Selected race ID

##### `_on_subrace_entry_selected(subrace_id: String) -> void`

Handles subrace entry selection.

**Parameters:**
- `subrace_id` (String): Selected subrace ID

##### `_on_confirm_race() -> void`

Confirms race selection and emits `tab_completed`.

---

### ClassTab

**Path:** `res://scripts/character/tabs/ClassTab.gd`  
**Type:** Control

Class and subclass selection tab.

#### Signals

```gdscript
signal class_selected(class_id: String, subclass_id: String)
signal tab_completed()
```

---

### BackgroundTab

**Path:** `res://scripts/character/tabs/BackgroundTab.gd`  
**Type:** Control

Background selection tab.

#### Signals

```gdscript
signal background_selected(background_id: String)
signal tab_completed()
```

---

### AbilityScoreTab

**Path:** `res://scripts/character/tabs/AbilityScoreTab.gd`  
**Type:** Control

Point-buy ability score assignment tab.

#### Signals

```gdscript
signal tab_completed()
```

---

### AppearanceTab

**Path:** `res://scripts/character/tabs/AppearanceTab.gd`  
**Type:** Control

Character appearance customization tab with 3D preview.

#### Signals

```gdscript
signal appearance_completed(data: Dictionary)
signal tab_completed()
```

---

### NameConfirmTab

**Path:** `res://scripts/character/tabs/NameConfirmTab.gd`  
**Type:** Control

Final character name entry and confirmation tab.

#### Signals

```gdscript
signal character_confirmed(character: CharacterData)
```

---

## Resources

### CharacterData

**Path:** `res://resources/CharacterData.gd`  
**Type:** Resource

Resource class for storing complete character data.

#### Properties

```gdscript
@export var name: String               # Character name
@export var race: String               # Race ID
@export var subrace: String           # Subrace ID
@export var character_class: String   # Class ID
@export var background: String        # Background ID
@export var ability_scores: Dictionary # Ability scores
@export var appearance: Dictionary    # Appearance data
@export var voice: String             # Voice ID
```

---

### WorldData

**Path:** `res://resources/WorldData.gd`  
**Type:** Resource

Resource class for world generation parameters.

---

### PointBuyCostTable

**Path:** `res://resources/PointBuyCostTable.gd`  
**Type:** Resource

Resource for point-buy cost calculations.

---

## World Generation

### WorldGenerator

**Path:** `res://scripts/world_creation/WorldGenerator.gd`  
**Type:** Node

Main world generation controller.

---

### TerrainGenerator

**Path:** `res://scripts/world_creation/TerrainGenerator.gd`  
**Type:** Node

Generates terrain heightmaps and meshes.

---

### BiomeTextureManager

**Path:** `res://scripts/world_creation/BiomeTextureManager.gd`  
**Type:** Node

Manages biome texture assignment.

---

## Usage Examples

### Accessing Game Data

```gdscript
# Get all races
for race in GameData.races:
    print(race.name)

# Find specific race
var dwarf = GameData.races.filter(func(r): return r.id == "dwarf")[0]

# Get point-buy config
var starting_points = GameData.point_buy_data.get("starting_points", 27)
```

### Using PlayerData

```gdscript
# Set race
PlayerData.race_id = "elf"
PlayerData.subrace_id = "high_elf"

# Get final ability score (base + racial bonus)
var final_str = PlayerData.get_final_ability_score("strength")

# Get ability modifier
var str_mod = PlayerData.get_ability_modifier("strength")
```

### Logging

```gdscript
# Simple logging
Logger.info("Character created", "character_creation")
Logger.error("Failed to load data", "gamedata")

# Performance timing
Logger.start_timer("load_races", "gamedata")
# ... do work ...
var elapsed = Logger.end_timer("load_races")
```

### Character Creation Flow

```gdscript
# In CharacterCreationRoot
func _on_race_selected(race_id: String, subrace_id: String):
    PlayerData.race_id = race_id
    PlayerData.subrace_id = subrace_id
    PlayerData.racial_bonuses_updated.emit()
```

---

*For detailed implementation, see source code comments in each file.*

