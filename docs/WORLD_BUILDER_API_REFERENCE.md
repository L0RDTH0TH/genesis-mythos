# ╔═══════════════════════════════════════════════════════════
# ║ World Builder API Reference
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

## WorldBuilderUI Class

### Class: WorldBuilderUI
**File:** `ui/world_builder/WorldBuilderUI.gd`  
**Extends:** `Control`

### Properties

```gdscript
var terrain_manager: Terrain3DManager = null
var current_step: int = 0
var step_data: Dictionary = {}
var map_icons_data: Dictionary = {}
var biomes_data: Dictionary = {}
var civilizations_data: Dictionary = {}
var placed_icons: Array[IconNode] = []
var icon_groups: Array[Array] = []
var control_references: Dictionary = {}
```

### Constants

```gdscript
const STEPS: Array[String] = [
    "Seed & Size",
    "2D Map Maker",
    "Terrain",
    "Climate",
    "Biomes",
    "Structures & Civilizations",
    "Environment",
    "Resources & Magic",
    "Export"
]

const MAP_ICONS_PATH: String = "res://data/map_icons.json"
const BIOMES_PATH: String = "res://data/biomes.json"
const CIVILIZATIONS_PATH: String = "res://data/civilizations.json"
```

### Public Methods

#### `set_terrain_manager(manager: Terrain3DManager) -> void`
Connects the terrain manager for live updates.

**Parameters:**
- `manager`: Terrain3DManager instance

**Example:**
```gdscript
world_builder_ui.set_terrain_manager(terrain_manager)
```

### Step Creation Methods

#### `_create_step_seed_size(parent: VBoxContainer) -> void`
Creates Step 1: Seed & Size UI.

#### `_create_step_map_maker(parent: VBoxContainer) -> void`
Creates Step 2: 2D Map Maker UI with canvas and icon toolbar.

#### `_create_step_terrain(parent: VBoxContainer) -> void`
Creates Step 3: Terrain UI with all noise parameters.

#### `_create_step_climate(parent: VBoxContainer) -> void`
Creates Step 4: Climate UI with temperature, rainfall, wind controls.

#### `_create_step_biomes(parent: VBoxContainer) -> void`
Creates Step 5: Biomes UI with biome list and generation modes.

#### `_create_step_structures(parent: VBoxContainer) -> void`
Creates Step 6: Structures & Civilizations UI.

#### `_create_step_environment(parent: VBoxContainer) -> void`
Creates Step 7: Environment UI with fog, sky, lighting controls.

#### `_create_step_resources(parent: VBoxContainer) -> void`
Creates Step 8: Resources & Magic UI.

#### `_create_step_export(parent: VBoxContainer) -> void`
Creates Step 9: Export UI with summary and export buttons.

### Event Handlers

#### `_on_terrain_param_changed(param_name: String, value: Variant) -> void`
Handles terrain parameter changes with live updates.

**Parameters:**
- `param_name`: Parameter name (height_scale, noise_frequency, etc.)
- `value`: New parameter value

#### `_on_climate_param_changed(param_name: String, value: Variant) -> void`
Handles climate parameter changes.

#### `_on_environment_param_changed(param_name: String, value: Variant) -> void`
Handles environment parameter changes.

#### `_on_canvas_clicked(event: InputEvent) -> void`
Handles clicks on 2D map canvas to place icons.

#### `_on_next_pressed() -> void`
Handles Next button - advances to next step or triggers 3D conversion.

#### `_on_back_pressed() -> void`
Handles Back button - returns to previous step.

### Data Processing Methods

#### `_cluster_icons(icons: Array[IconNode], distance_threshold: float) -> Array[Array]`
Clusters icons by proximity using DBSCAN-like algorithm.

**Parameters:**
- `icons`: Array of IconNode instances
- `distance_threshold`: Maximum distance for clustering (default: 50.0)

**Returns:** Array of icon groups (each group is an Array of IconNode)

#### `_generate_biomes_from_climate() -> void`
Generates biomes based on climate parameters from Step 4.

#### `_generate_3d_world() -> void`
Generates 3D world based on all step data and icon selections.

#### `_update_terrain_live() -> void`
Updates terrain in real-time with current parameters.

#### `_update_climate_live() -> void`
Updates climate effects in real-time.

#### `_update_environment_live() -> void`
Updates environment effects in real-time.

---

## IconNode Class

### Class: IconNode
**File:** `ui/world_builder/IconNode.gd`  
**Extends:** `Node2D`

### Properties

```gdscript
var icon_id: String = ""
var icon_type: String = ""
var map_position: Vector2 = Vector2.ZERO
var icon_color: Color = Color.WHITE
var sprite: Node = null
```

### Methods

#### `set_icon_data(id: String, color: Color, type: String = "") -> void`
Sets icon data from JSON configuration.

**Parameters:**
- `id`: Icon ID from map_icons.json
- `color`: Icon color
- `type`: Icon type (optional)

#### `get_distance_to(other: IconNode) -> float`
Calculates distance to another icon node.

**Parameters:**
- `other`: Another IconNode instance

**Returns:** Distance as float

---

## Terrain3DManager Integration

### Method: `generate_from_noise(seed: int, frequency: float, min_height: float, max_height: float) -> void`
Generates terrain from noise parameters.

**Parameters:**
- `seed`: Random seed value
- `frequency`: Noise frequency (0.001-0.1)
- `min_height`: Minimum terrain height
- `max_height`: Maximum terrain height

**Example:**
```gdscript
terrain_manager.generate_from_noise(12345, 0.0005, 0.0, 150.0)
```

### Method: `apply_biome_map(biome_type: String, blending: float, color: Color) -> void`
Applies biome colors to terrain.

**Parameters:**
- `biome_type`: Biome ID string
- `blending`: Blending factor (0.0-1.0)
- `color`: Biome color

### Method: `update_environment(time_of_day: float, fog_density: float, wind_strength: float, weather: String, sky_color: Color, ambient_light: Color) -> void`
Updates environment parameters.

**Parameters:**
- `time_of_day`: Hours (0.0-24.0)
- `fog_density`: Fog density (0.0-1.0)
- `wind_strength`: Wind strength (0.0-10.0)
- `weather`: Weather type string
- `sky_color`: Sky color
- `ambient_light`: Ambient light color

---

## Data File Formats

### map_icons.json Structure

```json
{
  "icons": [
    {
      "id": "string",
      "prompt": "string",
      "types": ["string", ...],
      "color": [r, g, b, a]
    }
  ]
}
```

### biomes.json Structure

```json
{
  "biomes": [
    {
      "id": "string",
      "name": "string",
      "temperature_range": [min, max],
      "rainfall_range": [min, max],
      "color": [r, g, b, a]
    }
  ]
}
```

### civilizations.json Structure

```json
{
  "civilizations": [
    {
      "id": "string",
      "name": "string",
      "description": "string"
    }
  ]
}
```

### resources.json Structure

```json
{
  "resources": [
    {
      "id": "string",
      "name": "string",
      "color": [r, g, b, a]
    }
  ]
}
```

---

## Step Data Structure

The `step_data` dictionary stores all parameters from each step:

```gdscript
step_data = {
    "Seed & Size": {
        "seed": 12345,
        "width": 1000,
        "height": 1000
    },
    "2D Map Maker": {
        "selected_icon": "forest"
    },
    "Terrain": {
        "seed": 12345,
        "height_scale": 20.0,
        "noise_frequency": 0.0005,
        "octaves": 4.0,
        "persistence": 0.5,
        "lacunarity": 2.0,
        "noise_type": 2
    },
    "Climate": {
        "temperature_intensity": 0.5,
        "rainfall_intensity": 0.5,
        "wind_strength": 1.0,
        "wind_direction_x": 1.0,
        "wind_direction_y": 0.0,
        "time_of_day": 12.0
    },
    "Biomes": {
        "show_biome_overlay": false,
        "generation_mode": 1,
        "selected_biome": "temperate_forest"
    },
    "Structures & Civilizations": {
        "cities": [
            {
                "icon": IconNode,
                "position": Vector2,
                "name": "Northport",
                "civilization": "human_kingdom"
            }
        ]
    },
    "Environment": {
        "fog_density": 0.1,
        "fog_color": Color,
        "sky_type": 0,
        "ambient_intensity": 0.3,
        "ambient_color": Color,
        "water_level": 0.0,
        "ocean_shader": true
    },
    "Resources & Magic": {
        "show_resource_overlay": false,
        "magic_density": 0.5,
        "ley_lines": []
    },
    "Export": {
        "world_name": "MyWorld"
    }
}
```

---

**Last Updated:** 2025-01-XX  
**Version:** 1.0.0
