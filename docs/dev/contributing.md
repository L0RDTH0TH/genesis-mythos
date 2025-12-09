# Contributing Guidelines

**Last Updated:** 2025-01-09  
**Project:** Genesis (Godot 4.3)  
**Author:** Lordthoth

---

## Table of Contents

1. [Code Style](#code-style)
2. [Folder Structure](#folder-structure)
3. [Adding or Modifying Biomes](#adding-or-modifying-biomes)
4. [Testing](#testing)
5. [Pull Request Process](#pull-request-process)

---

## Code Style

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
   - Never hard-code races, classes, biomes, etc.
   - Load everything from JSON or Resources

---

## Folder Structure

**NEVER** add folders outside the defined structure. If you need a new folder, update the project rules first.

See the main README.md for the complete folder structure.

---

## Adding or Modifying Biomes

### Overview

The world generation system uses a data-driven biome system. All biomes are defined via `BiomeDefinition.tres` resources, and region placement is controlled via `RegionSeed.json`.

### Step-by-Step Workflow

#### 1. Create BiomeDefinition Resource

1. **Open Godot Editor:**
   - Navigate to `res://assets/data/biomes/`

2. **Create New Resource:**
   - Right-click in FileSystem → New Resource
   - Select `BiomeDefinition` from the resource list
   - If `BiomeDefinition` doesn't appear, ensure the resource script exists at `res://resources/BiomeDefinition.gd`

3. **Configure Biome Properties:**
   
   **Required Properties:**
   - `biome_id: String` - Unique identifier (e.g., "volcanic_wasteland")
   - `biome_name: String` - Display name (e.g., "Volcanic Wasteland")
   - `noise_parameters: Dictionary` - Noise generation settings:
     ```gdscript
     {
         "frequency": 0.015,      # Base noise frequency
         "octaves": 5,            # Number of octaves
         "lacunarity": 2.3,       # Frequency multiplier per octave
         "gain": 0.7,             # Amplitude multiplier per octave
         "noise_type": "Cellular" # "Perlin", "Simplex", "Cellular", or "Value"
     }
     ```
   - `height_range: Vector2` - Min/max height (0.0-1.0)
   - `temperature_range: Vector2` - Min/max temperature (°C)
   - `humidity_range: Vector2` - Min/max humidity (0.0-1.0)

   **Optional Properties:**
   - `blend_distance: float` - Biome blending distance (default: 16.0)
   - `foliage_density: float` - Base foliage density (0.0-1.0, default: 0.5)
   - `poi_types: Array[String]` - Allowed POI types (default: [])
   - `resource_types: Array[String]` - Available resources (default: [])
   - `texture_path: String` - Path to biome texture (optional)
   - `normal_map_path: String` - Path to normal map (optional)

4. **Save Resource:**
   - Save as `res://assets/data/biomes/{biome_id}.tres`
   - Example: `res://assets/data/biomes/volcanic_wasteland.tres`

#### 2. Add Biome to RegionSeed.json

1. **Open RegionSeed.json:**
   - Path: `res://assets/data/RegionSeed.json`

2. **Find or Create Region:**
   - If biome fits existing region: Add `biome_id` to that region's `biome_ids` array
   - If new region needed: Create new region entry

3. **Region Entry Structure:**
   ```json
   {
     "id": "volcanic_region",
     "name": "Volcanic Region",
     "biome_ids": ["volcanic_wasteland", "lava_fields"],
     "weight": 0.1,
     "min_size": 4,
     "max_size": 10,
     "placement_rules": {
       "prefer_height_range": [0.6, 1.0],
       "prefer_temperature_range": [40.0, 60.0],
       "prefer_humidity_range": [0.0, 0.2],
       "avoid_adjacent": ["tundra_region", "swamp_region"]
     }
   }
   ```

4. **Save File:**
   - Ensure JSON is valid (use a JSON validator if unsure)

#### 3. Create Biome Textures (Optional)

1. **Create Diffuse Texture:**
   - Path: `res://assets/textures/biomes/{biome_id}.png`
   - Recommended size: 512×512 or 1024×1024
   - Format: PNG with transparency support

2. **Create Normal Map (Optional):**
   - Path: `res://assets/textures/biomes/{biome_id}_normal.png`
   - Same size as diffuse texture

3. **Update BiomeDefinition:**
   - Set `texture_path` in BiomeDefinition resource
   - Set `normal_map_path` if normal map exists

#### 4. Test Generation

1. **Run World Generation:**
   - Launch project
   - Navigate to World Creation
   - Generate a world

2. **Verify Biome:**
   - Check that biome appears in appropriate regions
   - Verify biome blending at boundaries looks natural
   - Check that foliage/POIs appear correctly
   - Verify textures load and display properly

3. **Adjust Parameters:**
   - If biome placement is wrong: Adjust `placement_rules` in RegionSeed.json
   - If blending is too sharp: Increase `blend_distance` in BiomeDefinition
   - If noise looks wrong: Adjust `noise_parameters` in BiomeDefinition

### Modifying Existing Biomes

1. **Open BiomeDefinition Resource:**
   - Navigate to `res://assets/data/biomes/{biome_id}.tres`
   - Open in Godot inspector

2. **Modify Properties:**
   - Adjust any properties as needed
   - Save resource

3. **Test Changes:**
   - Regenerate world
   - Verify changes appear correctly

### Best Practices

1. **Biome IDs:**
   - Use lowercase with underscores: `volcanic_wasteland`
   - Keep IDs unique and descriptive
   - Avoid special characters

2. **Noise Parameters:**
   - Start with similar biomes as reference
   - Test different noise types for variety
   - Lower frequency = larger features
   - More octaves = more detail

3. **Climate Ranges:**
   - Ensure ranges are realistic
   - Overlapping ranges allow biome mixing
   - Non-overlapping ranges create distinct zones

4. **Blending:**
   - Larger `blend_distance` = smoother transitions
   - Smaller `blend_distance` = sharper boundaries
   - Test blending with adjacent biomes

5. **Region Placement:**
   - Use `weight` to control region frequency
   - Use `placement_rules` to guide placement
   - Use `avoid_adjacent` to prevent unwanted combinations

---

## Testing

### Writing Tests

1. **Test Location:**
   - Place tests in `res://tests/`
   - Follow existing test structure

2. **Test Naming:**
   - Use descriptive names: `test_biome_generation_volcanic_wasteland.gd`
   - Group related tests in test suites

3. **Test Biome Generation:**
   ```gdscript
   func test_volcanic_wasteland_generation():
       var biome_def = load("res://assets/data/biomes/volcanic_wasteland.tres")
       assert_not_null(biome_def)
       assert_eq(biome_def.biome_id, "volcanic_wasteland")
       assert_true(biome_def.temperature_range.x > 30.0)
   ```

### Running Tests

See [docs/testing/RUNNING_TESTS.md](../testing/RUNNING_TESTS.md) for detailed instructions.

---

## Pull Request Process

1. **Create Feature Branch:**
   ```bash
   git checkout -b feature/add-volcanic-biome
   ```

2. **Follow Code Style:**
   - Ensure all code follows style guidelines
   - Run linter if available

3. **Add Documentation:**
   - Document new biomes in relevant docs
   - Update BiomeDefinition examples if needed

4. **Test Thoroughly:**
   - Test biome generation
   - Test biome blending
   - Test region placement
   - Verify textures load

5. **Update JSON Schemas:**
   - If modifying RegionSeed.json structure, update schema docs
   - See [docs/schemas/DATA_SCHEMAS.md](../schemas/DATA_SCHEMAS.md)

6. **Submit PR:**
   - Clear description of changes
   - Reference related issues if any
   - Include screenshots if visual changes

---

## Additional Resources

- [World Generation Documentation](../world_generation.md) - Complete world generation system docs
- [Data Schemas](../schemas/DATA_SCHEMAS.md) - JSON schema documentation
- [API Reference](../api/API_REFERENCE.md) - Complete API documentation

---

**End of Documentation**
