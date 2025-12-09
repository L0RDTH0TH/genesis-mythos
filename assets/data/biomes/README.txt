Biome Definition Resources Directory
====================================

This directory contains BiomeDefinition.tres resources that define all biomes
used in the world generation system.

Directory Structure
------------------

assets/data/biomes/
├── README.txt                    # This file
├── forest.tres                    # Forest biome definition
├── desert.tres                   # Desert biome definition
├── mountain.tres                 # Mountain biome definition
└── ...                           # Additional biome definitions

BiomeDefinition Resource Schema
-------------------------------

Each BiomeDefinition.tres resource must contain the following properties:

Required Properties:
--------------------

biome_id: String
    Unique identifier for the biome (e.g., "forest", "desert")
    Must be lowercase with underscores, no special characters

biome_name: String
    Display name for the biome (e.g., "Forest", "Desert")

noise_parameters: Dictionary
    Noise generation parameters for heightmap generation:
    {
        "frequency": float,        # Base noise frequency (0.001-0.1)
        "octaves": int,            # Number of octaves (1-8)
        "lacunarity": float,       # Frequency multiplier per octave (1.5-4.0)
        "gain": float,             # Amplitude multiplier per octave (0.3-0.9)
        "noise_type": String       # "Perlin", "Simplex", "Cellular", or "Value"
    }

height_range: Vector2
    Min/max height for this biome (0.0-1.0)
    Example: Vector2(0.3, 0.8) means biome prefers 30%-80% height

temperature_range: Vector2
    Preferred temperature range in Celsius
    Example: Vector2(5.0, 25.0) means biome prefers 5°C to 25°C

humidity_range: Vector2
    Preferred humidity range (0.0-1.0)
    Example: Vector2(0.4, 0.9) means biome prefers 40%-90% humidity

Optional Properties:
--------------------

blend_distance: float
    Distance for biome blending in world units (default: 16.0)
    Larger values = smoother transitions
    Smaller values = sharper boundaries

foliage_density: float
    Base foliage density (0.0-1.0, default: 0.5)
    0.0 = no foliage, 1.0 = dense foliage

poi_types: Array[String]
    Allowed Point of Interest types for this biome (default: [])
    Examples: ["village", "ruin", "shrine", "city"]

resource_types: Array[String]
    Available resource types in this biome (default: [])
    Examples: ["wood", "ore", "herbs", "stone"]

texture_path: String
    Path to biome diffuse texture (optional)
    Example: "res://assets/textures/biomes/forest.png"

normal_map_path: String
    Path to biome normal map texture (optional)
    Example: "res://assets/textures/biomes/forest_normal.png"

Example BiomeDefinition
------------------------

# Forest biome example
biome_id = "forest"
biome_name = "Forest"
noise_parameters = {
    "frequency": 0.02,
    "octaves": 6,
    "lacunarity": 2.1,
    "gain": 0.6,
    "noise_type": "Simplex"
}
height_range = Vector2(0.3, 0.8)
temperature_range = Vector2(5.0, 25.0)
humidity_range = Vector2(0.5, 1.0)
blend_distance = 32.0
foliage_density = 0.8
poi_types = ["village", "ruin", "shrine"]
resource_types = ["wood", "herbs"]
texture_path = "res://assets/textures/biomes/forest.png"
normal_map_path = "res://assets/textures/biomes/forest_normal.png"

Creating a New Biome
--------------------

1. In Godot Editor:
   - Right-click this directory → New Resource
   - Select "BiomeDefinition"
   - Configure all required properties
   - Save as: {biome_id}.tres

2. Add to RegionSeed.json:
   - Open res://assets/data/RegionSeed.json
   - Add biome_id to appropriate region's biome_ids array
   - Or create new region entry

3. Create textures (optional):
   - Create diffuse texture: res://assets/textures/biomes/{biome_id}.png
   - Create normal map: res://assets/textures/biomes/{biome_id}_normal.png
   - Update BiomeDefinition texture_path properties

4. Test:
   - Run world generation
   - Verify biome appears correctly
   - Check biome blending at boundaries

For detailed instructions, see:
- docs/dev/contributing.md (Adding or Modifying Biomes section)
- docs/world_generation.md (Complete world generation documentation)

JSON Schema Reference
----------------------

While BiomeDefinition resources are .tres files (Godot resources), they can
be conceptually represented as JSON for reference:

{
  "biome_id": "string",
  "biome_name": "string",
  "noise_parameters": {
    "frequency": 0.02,
    "octaves": 6,
    "lacunarity": 2.1,
    "gain": 0.6,
    "noise_type": "Simplex"
  },
  "height_range": [0.3, 0.8],
  "temperature_range": [5.0, 25.0],
  "humidity_range": [0.5, 1.0],
  "blend_distance": 32.0,
  "foliage_density": 0.8,
  "poi_types": ["village", "ruin", "shrine"],
  "resource_types": ["wood", "herbs"],
  "texture_path": "res://assets/textures/biomes/forest.png",
  "normal_map_path": "res://assets/textures/biomes/forest_normal.png"
}

Notes
-----

- Biome IDs must be unique across all biome definitions
- Biome IDs are used in RegionSeed.json to assign biomes to regions
- The system auto-discovers all .tres files in this directory on generation start
- Biome blending uses blend_distance to create smooth transitions
- Noise parameters significantly affect terrain appearance - test different values

Last Updated: 2025-01-09
