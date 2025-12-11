# ╔═══════════════════════════════════════════════════════════
# ║ World Builder Wizard System Documentation
# ║ Author: Lordthoth
# ║ Last Updated: 2025-01-XX
# ╚═══════════════════════════════════════════════════════════

## Overview

The World Builder is a step-by-step wizard-style interface for creating procedural 3D worlds in Godot 4.3. The system is fully data-driven, using JSON configuration files for all definitions (icons, biomes, civilizations, resources).

## Architecture

### UI Structure

The wizard interface consists of:

1. **Background Layer** - Opaque black ColorRect (`BackgroundRect`) covering full screen to block background rendering
2. **Overlay Layer** - Vignette shader overlay (`Overlay`) with transparent center window for BG3-inspired aesthetic
3. **Left Navigation Panel** - Vertical list of 9 steps with gold highlighting for current step
4. **Center Preview Area** - Displays either 2D map (Steps 1-2) or 3D terrain preview (Steps 3+)
5. **Right Content Panel** - Displays the active step's controls
6. **Navigation Buttons** - Next/Back buttons at the bottom

### Rendering Architecture

**Full-Screen Layout:**
- Root `WorldBuilderUI` Control uses full rect anchors (0,0,1,1) for complete screen coverage
- `BackgroundRect` provides opaque background (Color(0.1, 0.1, 0.1, 1)) to prevent 3D bleed-through
- All UI panels use proper anchor-based layout for responsive sizing

**2D/3D View Separation:**
- **Steps 1-2 (Seed & Size, 2D Map Maker):**
  - `Map2DTexture` (TextureRect) visible - displays 2D map from dedicated SubViewport
  - `Terrain3DView` (SubViewportContainer) hidden - 3D rendering disabled
  - 2D map rendered via `map_2d_viewport` SubViewport with parchment background and grid
  
- **Steps 3+ (Terrain and beyond):**
  - `Map2DTexture` hidden
  - `Terrain3DView` visible - 3D terrain preview active
  - `PreviewViewport` contains isolated 3D world with its own `WorldEnvironment`
  - Camera and lighting configured for perspective view

**3D Isolation:**
- 3D SubViewport has its own `WorldEnvironment` node to isolate environment effects
- Prevents main scene's WorldEnvironment from affecting UI background
- 3D rendering only occurs when `Terrain3DView` is visible (step >= 2)
- Render target update mode set to `UPDATE_DISABLED` when hidden to prevent unnecessary rendering

### Step Flow

```
Step 1: Seed & Size
  ↓
Step 2: 2D Map Maker
  ↓ (triggers 3D conversion)
Step 3: Terrain
  ↓
Step 4: Climate
  ↓
Step 5: Biomes
  ↓
Step 6: Structures & Civilizations
  ↓
Step 7: Environment
  ↓
Step 8: Resources & Magic
  ↓
Step 9: Export
```

## Step Details

### Step 1: Seed & Size

**Purpose:** Set the foundational parameters for world generation.

**Controls:**
- **Seed** (SpinBox): Random seed value (0-999999)
- **Width** (SpinBox): World width in units (100-10000)
- **Height** (SpinBox): World height in units (100-10000)

**Data Flow:**
- Seed automatically syncs to Step 3 (Terrain) as read-only field
- Size parameters used for terrain generation bounds

**File:** `ui/world_builder/WorldBuilderUI.gd` - `_create_step_seed_size()`

---

### Step 2: 2D Map Maker

**Purpose:** Create a 2D top-down map with terrain feature icons.

**Features:**
- **Icon Toolbar:** Buttons for each icon type (forest, mountain, city, water, desert, swamp)
- **Map Canvas:** Clickable panel for placing icons
- **Icon Placement:** Click on canvas to place selected icon type
- **3D Conversion:** When advancing to Step 3, triggers clustering and type selection

**Icon Types:**
- Defined in `res://data/map_icons.json`
- Each icon has: `id`, `prompt`, `types` array, `color`

**3D Conversion Process:**
1. Icons are clustered by proximity (DBSCAN-like, 50-unit threshold)
2. For each cluster, a pop-up dialog appears
3. User selects specific type (e.g., jungle/pine/redwood for forest)
4. Selected types are stored for 3D world generation

**Files:**
- `ui/world_builder/WorldBuilderUI.gd` - `_create_step_map_maker()`
- `ui/world_builder/IconNode.gd` - Icon data structure
- `data/map_icons.json` - Icon definitions

---

### Step 3: Terrain

**Purpose:** Configure procedural terrain generation parameters.

**Controls:**
- **Seed** (SpinBox, read-only): Auto-filled from Step 1
- **Height Scale** (Slider): 0.0-100.0, default 20.0
- **Noise Frequency** (Slider): 0.001-0.1, default 0.0005
- **Octaves** (Slider): 1.0-8.0, default 4.0
- **Persistence** (Slider): 0.0-1.0, default 0.5
- **Lacunarity** (Slider): 1.0-4.0, default 2.0
- **Noise Type** (OptionButton): Simplex, Simplex Smooth, Perlin, Value, Value Cubic, Cellular
- **Regenerate Terrain** (Button): Instantly updates live Terrain3D mesh

**Live Updates:**
- All sliders trigger real-time terrain regeneration
- Terrain mesh updates in background viewport
- Uses `Terrain3DManager.generate_from_noise()`

**Files:**
- `ui/world_builder/WorldBuilderUI.gd` - `_create_step_terrain()`, `_on_terrain_param_changed()`
- `core/world_generation/Terrain3DManager.gd` - `generate_from_noise()`

---

### Step 4: Climate

**Purpose:** Configure climate parameters that affect biome generation.

**Controls:**
- **Temperature Intensity** (Slider): 0.0-1.0, maps to -50°C to 50°C
- **Rainfall Intensity** (Slider): 0.0-1.0, maps to 0-300mm
- **Wind Strength** (Slider): 0.0-10.0, default 1.0
- **Wind Direction** (SpinBox X/Y): -1.0 to 1.0 vector components
- **Time of Day** (Slider): 0.0-24.0 hours, affects sky in real-time

**Live Updates:**
- Time of Day slider updates sky lighting immediately
- Parameters feed into Step 5 (Biomes) for auto-generation

**Files:**
- `ui/world_builder/WorldBuilderUI.gd` - `_create_step_climate()`, `_on_climate_param_changed()`

---

### Step 5: Biomes

**Purpose:** Define and generate biome distribution across the world.

**Features:**
- **Biome Overlay Toggle:** Show/hide biome colors on 2D map
- **Biome List:** Select from 10 predefined biomes
- **Generation Modes:**
  - Manual Painting (future)
  - Auto-Generate from Climate (uses Step 4 parameters)
  - Auto-Generate from Height (uses terrain elevation)

**Biome Definitions:**
- Loaded from `res://data/biomes.json`
- Each biome has: `id`, `name`, `temperature_range`, `rainfall_range`, `color`

**Auto-Generation Logic:**
- Maps climate intensity values to temperature/rainfall ranges
- Finds matching biome based on ranges
- Applies biome color to terrain via `Terrain3DManager.apply_biome_map()`

**Files:**
- `ui/world_builder/WorldBuilderUI.gd` - `_create_step_biomes()`, `_generate_biomes_from_climate()`
- `data/biomes.json` - Biome definitions

---

### Step 6: Structures & Civilizations

**Purpose:** Assign civilizations to city icons from Step 2.

**Features:**
- **Process Cities Button:** Scans 2D map for city icons
- **Civilization Selection:** Pop-up dialog for each city with:
  - City name input (with random name generator)
  - Civilization selection (Human Kingdom, Elven Enclave, Dwarven Hold, etc.)
- **City List:** Displays all processed cities with their assignments

**Civilization Definitions:**
- Loaded from `res://data/civilizations.json`
- Each civilization has: `id`, `name`, `description`

**Random Name Generator:**
- Combines prefixes (North, South, New, Old, etc.) with suffixes (port, haven, burg, etc.)

**Files:**
- `ui/world_builder/WorldBuilderUI.gd` - `_create_step_structures()`, `_on_process_cities_pressed()`
- `data/civilizations.json` - Civilization definitions

---

### Step 7: Environment

**Purpose:** Configure atmospheric and lighting effects.

**Controls:**
- **Fog Density** (Slider): 0.0-1.0, default 0.1
- **Fog Color** (ColorPicker): Default light blue-gray
- **Sky Type** (OptionButton): Procedural, HDRI, Custom Gradient
- **Ambient Light Intensity** (Slider): 0.0-2.0, default 0.3
- **Ambient Light Color** (ColorPicker): Default gray
- **Water Level** (Slider): -50.0 to 50.0, default 0.0
- **Enable Ocean Shader** (CheckBox): Toggle ocean rendering

**Live Updates:**
- All parameters update environment in real-time
- Integrates with climate time of day for sky lighting

**Files:**
- `ui/world_builder/WorldBuilderUI.gd` - `_create_step_environment()`, `_on_environment_param_changed()`

---

### Step 8: Resources & Magic

**Purpose:** Define resource distribution and magical elements.

**Features:**
- **Resource Overlay Toggle:** Show/hide resource markers on map
- **Magic Density** (Slider): 0.0-1.0 heat-map intensity
- **Ley Line Placement:** Drag tool for placing magical ley lines (future)

**Resource Definitions:**
- Loaded from `res://data/resources.json`
- Resources: Iron Ore, Gold, Mana Crystal, Ancient Ruin

**Files:**
- `ui/world_builder/WorldBuilderUI.gd` - `_create_step_resources()`
- `data/resources.json` - Resource definitions

---

### Step 9: Export

**Purpose:** Finalize and export the generated world.

**Features:**
- **World Name** (LineEdit): Name for saved world
- **Summary Panel:** Displays all world parameters
- **Export Buttons:**
  - **Save World Config:** Saves to `user://worlds/{name}.json`
  - **Export Heightmap:** 16-bit PNG export (placeholder)
  - **Export Biome Map:** PNG export (placeholder)
  - **Generate Full 3D Scene:** Creates scene in `res://worlds/` (placeholder)

**Export Format:**
```json
{
  "world_name": "MyWorld",
  "step_data": {
    "Seed & Size": { ... },
    "2D Map Maker": { ... },
    "Terrain": { ... },
    ...
  },
  "timestamp": "2025-01-XX..."
}
```

**Files:**
- `ui/world_builder/WorldBuilderUI.gd` - `_create_step_export()`, export handlers

---

## Data Files

### map_icons.json
```json
{
  "icons": [
    {
      "id": "forest",
      "prompt": "simple pixel art icon of a green forest tree cluster",
      "types": ["jungle", "pine", "redwood"],
      "color": [0.2, 0.6, 0.2, 1.0]
    }
  ]
}
```

### biomes.json
```json
{
  "biomes": [
    {
      "id": "tundra",
      "name": "Tundra",
      "temperature_range": [-50, -10],
      "rainfall_range": [0, 30],
      "color": [0.8, 0.85, 0.9, 1.0]
    }
  ]
}
```

### civilizations.json
```json
{
  "civilizations": [
    {
      "id": "human_kingdom",
      "name": "Human Kingdom",
      "description": "A prosperous human settlement..."
    }
  ]
}
```

### resources.json
```json
{
  "resources": [
    {
      "id": "iron",
      "name": "Iron Ore",
      "color": [0.6, 0.5, 0.4, 1.0]
    }
  ]
}
```

## Integration with Terrain3DManager

The World Builder UI connects to `Terrain3DManager` for live terrain updates:

```gdscript
func set_terrain_manager(manager) -> void:
    terrain_manager = manager
```

**Available Methods:**
- `generate_from_noise(seed, frequency, min_height, max_height)` - Generate terrain
- `apply_biome_map(biome_type, blending, color)` - Apply biome colors
- `update_environment(time_of_day, fog_density, wind_strength, weather, sky_color, ambient_light)` - Update atmosphere
- `place_structure(structure_type, position, scale)` - Place structures (future)
- `get_height_at(position)` - Get terrain height at point (future)

## Code Structure

### Main UI Class
- **File:** `ui/world_builder/WorldBuilderUI.gd`
- **Extends:** `Control`
- **Key Methods:**
  - `_create_step_*()` - Create each step's UI
  - `_on_*_param_changed()` - Handle parameter updates
  - `_update_*_live()` - Real-time update handlers
  - `_update_step_display()` - Show/hide step panels

### Icon Node Class
- **File:** `ui/world_builder/IconNode.gd`
- **Extends:** `Node2D`
- **Purpose:** Data structure for map icons
- **Properties:** `icon_id`, `icon_type`, `map_position`, `icon_color`

### Scene File
- **File:** `ui/world_builder/WorldBuilderUI.tscn`
- **Structure:**
  - WorldBuilderUI (Control, full rect)
    - BackgroundRect (ColorRect, full rect, opaque black)
    - Overlay (ColorRect, full rect, vignette shader)
    - BackgroundPanel (Panel, full rect)
      - TitleLabel (top center)
      - MainContainer (HSplitContainer, full rect with margins)
        - LeftNav (Panel, fixed width 250px)
        - RightSplit (HSplitContainer)
          - CenterPanel (Panel, expanding)
            - Map2DTexture (TextureRect, full rect, visible for steps 1-2)
            - Terrain3DView (SubViewportContainer, full rect, hidden by default)
              - PreviewViewport (SubViewport)
                - PreviewWorld (Node3D)
                  - WorldEnvironment (isolated environment)
                  - PreviewCamera (Camera3D)
                  - PreviewLight (DirectionalLight3D)
                  - Map2DLayer (Node2D, hidden in 3D mode)
          - RightContent (PanelContainer, fixed width 400px)
      - ButtonContainer (HBoxContainer, bottom center)
        - BackButton
        - NextButton

## Theme Integration

All UI elements use the single `bg3_theme.tres` theme:
- Gold color for current step: `Color(1, 0.843137, 0, 1)`
- Consistent styling across all controls
- No hard-coded colors or magic numbers

## Future Enhancements

1. **Manual Biome Painting:** Click-to-paint biomes on 2D map
2. **Ley Line Drag Tool:** Interactive placement of magical lines
3. **Heightmap Export:** Full implementation of 16-bit PNG export
4. **Biome Map Export:** Visual representation of biome distribution
5. **Scene Generation:** Complete 3D scene file creation
6. **Structure Placement:** 3D model placement based on icons
7. **Preview Window:** Live 3D preview of world generation

## Testing

The wizard system should be tested for:
- Step navigation (Next/Back)
- Data persistence between steps
- Live terrain updates
- Icon clustering accuracy
- Civilization assignment workflow
- Export functionality

## Troubleshooting

**Terrain not updating:**
- Check `terrain_manager` is assigned via `set_terrain_manager()`
- Verify `Terrain3DManager.generate_from_noise()` exists
- Check console for error messages

**Icons not placing:**
- Ensure icon is selected from toolbar before clicking canvas
- Check `map_icons.json` is loaded correctly
- Verify canvas click handler is connected

**Seed not syncing:**
- Check Step 1 seed value is set
- Verify `_update_terrain_seed_from_step1()` is called when entering Step 3

---

## Recent Updates (2025-01-XX)

### UI Rendering Fixes

**Full-Screen Layout:**
- Fixed UI proportioning - WorldBuilderUI now uses full screen (not 80% size)
- Added opaque `BackgroundRect` to prevent 3D terrain/sky from rendering behind UI
- All panels use proper anchor-based layout for responsive full-screen display

**2D/3D View Control:**
- 2D map displays immediately on launch (Steps 1-2)
- 3D terrain only renders when Step 3 (Terrain) is selected
- Proper visibility toggling prevents premature 3D rendering
- 3D SubViewport isolated with its own WorldEnvironment to prevent global effects

**Scene Structure:**
- Restructured scene tree for proper layering: Background → Overlay → UI Panels
- CenterPanel contains both 2D and 3D views, with visibility controlled by step
- 3D rendering confined to center panel, never extends to background

**Files Modified:**
- `ui/world_builder/WorldBuilderUI.tscn` - Scene restructure with BackgroundRect and proper anchors
- `ui/world_builder/WorldBuilderUI.gd` - Step visibility control and 2D viewport setup
- `core/scenes/world_root.gd` - Fixed UI sizing to full screen

---

**Last Updated:** 2025-01-XX  
**Version:** 1.1.0  
**Author:** Lordthoth
