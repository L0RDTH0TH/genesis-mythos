# Data Schema Documentation

This document describes the JSON schema for all data files used in the project.

## Table of Contents

- [biomes.json](#biomesjson)
- [map_icons.json](#map_iconsjson)
- [civilizations.json](#civilizationsjson)
- [resources.json](#resourcesjson)
- [Configuration Files](#configuration-files)

---

## biomes.json

**Type:** Dictionary containing array of Biome Objects  
**Path:** `res://data/biomes.json`

### Biome Object Schema

```json
{
  "biomes": [
    {
      "id": "string",                    // Required: Unique identifier (e.g., "tundra", "desert")
      "name": "string",                  // Required: Display name (e.g., "Tundra", "Desert")
      "temperature_range": [min, max],   // Required: Temperature range [int, int]
      "rainfall_range": [min, max],      // Required: Rainfall range [int, int]
      "color": [r, g, b, a]             // Required: RGBA color array [float, float, float, float]
    }
  ]
}
```

### Example

```json
{
  "biomes": [
    {
      "id": "tundra",
      "name": "Tundra",
      "temperature_range": [-50, -10],
      "rainfall_range": [0, 30],
      "color": [0.8, 0.85, 0.9, 1.0]
    },
    {
      "id": "desert",
      "name": "Desert",
      "temperature_range": [20, 50],
      "rainfall_range": [0, 25],
      "color": [0.9, 0.8, 0.6, 1.0]
    }
  ]
}
```

**Notes:**
- Temperature and rainfall ranges define climate conditions for biome assignment
- Color is used for biome visualization on maps
- All values are required

---

## map_icons.json

**Type:** Dictionary containing array of Icon Objects  
**Path:** `res://data/map_icons.json`

### Icon Object Schema

```json
{
  "icons": [
    {
      "id": "string",                    // Required: Unique identifier (e.g., "forest", "mountain")
      "prompt": "string",                // Required: Description for icon generation
      "types": ["string"],               // Required: Array of icon type variants
      "color": [r, g, b, a]             // Required: RGBA color array [float, float, float, float]
    }
  ]
}
```

### Example

```json
{
  "icons": [
    {
      "id": "forest",
      "prompt": "simple pixel art icon of a green forest tree cluster",
      "types": ["jungle", "pine", "redwood"],
      "color": [0.2, 0.6, 0.2, 1.0]
    },
    {
      "id": "mountain",
      "prompt": "simple pixel art icon of a rocky mountain peak",
      "types": ["snowy", "volcanic", "rocky"],
      "color": [0.5, 0.5, 0.5, 1.0]
    }
  ]
}
```

**Notes:**
- Icons are used for 2D map marker placement
- Types array provides variants for the same icon category
- Color is used for icon visualization

---

## civilizations.json

**Type:** Dictionary containing array of Civilization Objects  
**Path:** `res://data/civilizations.json`

### Civilization Object Schema

```json
{
  "civilizations": [
    {
      "id": "string",                    // Required: Unique identifier (e.g., "human_kingdom")
      "name": "string",                  // Required: Display name (e.g., "Human Kingdom")
      "description": "string"           // Required: Civilization description
    }
  ]
}
```

### Example

```json
{
  "civilizations": [
    {
      "id": "human_kingdom",
      "name": "Human Kingdom",
      "description": "A prosperous human settlement with stone walls and towers"
    },
    {
      "id": "elven_enclave",
      "name": "Elven Enclave",
      "description": "An ancient elven city built among the trees"
    }
  ]
}
```

**Notes:**
- Civilizations are used for city assignment in world generation
- All fields are required

---

## resources.json

**Type:** Dictionary containing array of Resource Objects  
**Path:** `res://data/resources.json`

### Resource Object Schema

```json
{
  "resources": [
    {
      "id": "string",                    // Required: Unique identifier (e.g., "iron", "gold")
      "name": "string",                  // Required: Display name (e.g., "Iron Ore", "Gold")
      "color": [r, g, b, a]             // Required: RGBA color array [float, float, float, float]
    }
  ]
}
```

### Example

```json
{
  "resources": [
    {
      "id": "iron",
      "name": "Iron Ore",
      "color": [0.6, 0.5, 0.4, 1.0]
    },
    {
      "id": "gold",
      "name": "Gold",
      "color": [1.0, 0.84, 0.0, 1.0]
    }
  ]
}
```

**Notes:**
- Resources are used for resource placement in world generation
- Color is used for resource visualization on maps
- All fields are required

---

## Configuration Files

Configuration files are located in `res://data/config/`:

### logging_config.json

Logging system configuration.

### terrain_generation.json

Terrain generation parameters and settings.

### world_builder_ui.json

World Builder UI configuration and step definitions.

---

## Data Loading

Data files are loaded on-demand by the World Builder system:

1. Files are loaded when needed by specific modules
2. JSON parsing uses Godot's built-in `JSON.parse_string()` or `FileAccess`
3. Data is cached in module-specific variables or resources
4. Error handling logs issues and provides fallback values

**Error Handling:**
- Missing files: Logs error, returns empty array/dictionary
- Parse errors: Logs error with line number, returns empty array/dictionary
- Invalid structure: Logs error, skips invalid entries

**Access Pattern:**
```gdscript
# Load biomes
var file = FileAccess.open("res://data/biomes.json", FileAccess.READ)
if file:
    var json = JSON.new()
    json.parse(file.get_as_text())
    var biomes = json.data.get("biomes", [])
    file.close()

# Access specific biome
var desert = biomes.filter(func(b): return b.id == "desert")[0]

# Load map icons
var icons_file = FileAccess.open("res://data/map_icons.json", FileAccess.READ)
if icons_file:
    var icons_json = JSON.new()
    icons_json.parse(icons_file.get_as_text())
    var icons = icons_json.data.get("icons", [])
    icons_file.close()
```

