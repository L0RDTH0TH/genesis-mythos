# Procedural Map Datasource Enhancement Investigation

## Executive Summary

This document investigates the current parameter structure in the codebase and proposes enhancements to the `ProceduralWorldDatasource` pattern to support richer, more configurable fantasy archetype definitions.

**Status:** Investigation Complete - Enhancement Suggestions Ready  
**Date:** 2025-12-13  
**Author:** AI Assistant

---

## 1. Current Parameter Inventory

### 1.1 Currently Used in `fantasy_archetypes.json`

**Noise Generation Parameters:**
- `noise_type` (String): "TYPE_SIMPLEX", "TYPE_PERLIN", "TYPE_CELLULAR", "TYPE_VALUE", "TYPE_SIMPLEX_SMOOTH"
- `frequency` (float): 0.003 - 0.015 (base noise frequency)
- `octaves` (int): 3 - 8 (fractal detail levels)
- `gain` (float): 0.3 - 0.6 (amplitude multiplier per octave, also called "persistence" in some contexts)
- `lacunarity` (float): 1.8 - 2.2 (frequency multiplier per octave)
- `height_scale` (float): 0.2 - 0.9 (overall heightmap scaling)

**Biome Parameters:**
- `biome_colors` (Dictionary): Currently supports 7 basic biomes:
  - `water`, `beach`, `grass`, `forest`, `hill`, `mountain`, `snow`

**Metadata:**
- `description` (String): Flavor text
- `recommended_size` (String): "Tiny", "Small", "Medium", "Large", "Extra Large"
- `default_landmass` (String): "Continents", "Single Island", "Island Chain", "Archipelago", "Pangea", "Coastal"

### 1.2 Found in Codebase but NOT in Archetype JSON

**From `WorldMapData.gd`:**
- `sea_level` (float): 0.0 - 1.0, normalized height threshold
- `erosion_enabled` (bool): Enable/disable erosion
- `erosion_strength` (float): 0.0 - 1.0, erosion intensity
- `erosion_iterations` (int): Number of erosion passes
- `rivers_enabled` (bool): Enable/disable river generation
- `river_count` (int): Number of rivers to generate
- `river_start_elevation` (float): Height threshold where rivers start
- `biome_temperature_noise_frequency` (float): Temperature noise frequency
- `biome_moisture_noise_frequency` (float): Moisture noise frequency

**From `biomes.json`:**
- Additional biome types: `tundra`, `taiga`, `temperate_forest`, `grassland`, `desert`, `savanna`, `tropical_rainforest`, `swamp`, `mountain`, `ocean`
- Biome properties: `temperature_range`, `rainfall_range`, `color` (RGBA array)

**From `MapGenerator.gd`:**
- Temperature/moisture-based biome generation logic
- Multi-noise system (height + temperature + moisture)

**From User Examples:**
- `biome_thresholds` (Dictionary): Custom height thresholds per biome
- `additional_params` (Dictionary): Flavor metadata (magic_density, creature_diversity, weather_variety)
- Extended `biome_colors`: Fantasy-specific biomes (enchanted_forest, ancient_ruins, crystal_lake, wasteland, plagued_land, ruined_city)

---

## 2. Parameter Gap Analysis

### 2.1 Missing Core Parameters

| Parameter | Current Status | Impact | Priority |
|-----------|---------------|--------|----------|
| `biome_thresholds` | ❌ Not in JSON | Hard-coded in datasource | **HIGH** |
| `sea_level` | ❌ Not in JSON | Always uses default 0.4 | **MEDIUM** |
| `erosion_*` | ❌ Not in JSON | Erosion always disabled | **MEDIUM** |
| `rivers_*` | ❌ Not in JSON | Rivers always disabled | **LOW** |
| `temperature/moisture` | ❌ Not in JSON | Height-only biome generation | **HIGH** |
| Extended biomes | ❌ Limited to 7 | Cannot express fantasy-specific biomes | **HIGH** |

### 2.2 Missing Enhancement Parameters

| Parameter | Current Status | Impact | Priority |
|-----------|---------------|--------|----------|
| `additional_params` | ❌ Not in JSON | No flavor metadata storage | **LOW** |
| `biome_temperature_noise_frequency` | ❌ Not in JSON | Temperature noise always default | **MEDIUM** |
| `biome_moisture_noise_frequency` | ❌ Not in JSON | Moisture noise always default | **MEDIUM** |

---

## 3. Suggested Enhanced Archetype Pattern

### 3.1 Enhanced JSON Structure

```json
{
  "High Fantasy": {
    "description": "A vibrant world of magic, with lush forests, towering mountains, and mystical landscapes teeming with wonder and adventure.",
    "recommended_size": "Large",
    "default_landmass": "Continents",
    
    "noise": {
      "noise_type": "TYPE_SIMPLEX",
      "frequency": 0.004,
      "octaves": 6,
      "gain": 0.5,
      "lacunarity": 2.0,
      "height_scale": 0.8
    },
    
    "terrain": {
      "sea_level": 0.35,
      "erosion": {
        "enabled": true,
        "strength": 0.3,
        "iterations": 5
      },
      "rivers": {
        "enabled": true,
        "count": 15,
        "start_elevation": 0.7
      }
    },
    
    "climate": {
      "temperature_noise_frequency": 0.002,
      "moisture_noise_frequency": 0.002,
      "temperature_bias": 0.0,
      "moisture_bias": 0.1
    },
    
    "biomes": {
      "colors": {
        "water": "#2a6d9e",
        "beach": "#d4b56a",
        "grass": "#3d8c40",
        "forest": "#2d5a3d",
        "hill": "#8b7355",
        "mountain": "#c0c0c0",
        "snow": "#ffffff",
        "enchanted_forest": "#4b0082",
        "ancient_ruins": "#808080",
        "crystal_lake": "#00ffff"
      },
      "thresholds": {
        "water": 0.35,
        "beach": 0.38,
        "grass": 0.5,
        "forest": 0.65,
        "hill": 0.8,
        "mountain": 0.95,
        "snow": 1.0,
        "enchanted_forest": 0.55,
        "ancient_ruins": 0.7,
        "crystal_lake": 0.3
      },
      "generation_mode": "height_and_climate",
      "fantasy_biomes": {
        "enchanted_forest": {
          "height_range": [0.5, 0.65],
          "temperature_range": [0.3, 0.7],
          "moisture_range": [0.6, 1.0],
          "spawn_chance": 0.15
        },
        "ancient_ruins": {
          "height_range": [0.6, 0.8],
          "temperature_range": [0.0, 1.0],
          "moisture_range": [0.0, 0.5],
          "spawn_chance": 0.05
        },
        "crystal_lake": {
          "height_range": [0.25, 0.35],
          "temperature_range": [0.0, 1.0],
          "moisture_range": [0.8, 1.0],
          "spawn_chance": 0.1
        }
      }
    },
    
    "additional_params": {
      "magic_density": "high",
      "creature_diversity": "abundant",
      "weather_variety": ["sunny", "rainy", "mystical fog"]
    }
  }
}
```

### 3.2 Key Enhancements Explained

**1. Organized Structure:**
- `noise`: All noise generation parameters grouped
- `terrain`: Terrain modification parameters (erosion, rivers, sea level)
- `climate`: Temperature/moisture generation parameters
- `biomes`: All biome-related configuration
- `additional_params`: Flavor metadata (not used in generation, but useful for UI/descriptions)

**2. Biome Thresholds:**
- Moves hard-coded thresholds from datasource to JSON
- Allows per-archetype customization
- Supports extended biome types

**3. Climate-Based Generation:**
- `generation_mode`: "height_only" (current) or "height_and_climate" (enhanced)
- Temperature/moisture noise configuration
- Bias parameters for global climate shifts

**4. Fantasy Biomes:**
- `fantasy_biomes`: Dictionary of special biomes with spawn conditions
- Each fantasy biome has:
  - `height_range`: [min, max] normalized height
  - `temperature_range`: [min, max] normalized temperature
  - `moisture_range`: [min, max] normalized moisture
  - `spawn_chance`: Probability of spawning when conditions met

**5. Terrain Features:**
- Erosion configuration per archetype
- River generation configuration
- Sea level customization

---

## 4. Datasource Enhancement Suggestions

### 4.1 Current Implementation Limitations

**In `ProceduralWorldDatasource.gd`:**

1. **Hard-coded Biome Thresholds:**
   ```gdscript
   # Current (lines 175-188)
   if h < 0.35:
       col = Color(biome_colors.get("water", "#2a6d9e"))
   elif h < 0.38:
       col = Color(biome_colors.get("beach", "#d4b56a"))
   # ... etc
   ```
   **Problem:** Thresholds are fixed, cannot be customized per archetype.

2. **Height-Only Biome Generation:**
   ```gdscript
   # Current (line 171)
   var h: float = height_img.get_pixel(x, y).r
   # Only uses height, ignores temperature/moisture
   ```
   **Problem:** Cannot generate climate-based biomes (desert, tundra, rainforest, etc.)

3. **No Erosion/Rivers:**
   - Erosion and river generation exist in `MapGenerator.gd` but are not accessible from datasource
   - No way to configure these per archetype

4. **Limited Biome Support:**
   - Only 7 basic biomes supported
   - Cannot express fantasy-specific biomes (enchanted forests, crystal lakes, etc.)

### 4.2 Suggested Datasource Enhancements

#### Enhancement 1: Configurable Biome Thresholds

**Add to `configure_from_archetype()`:**
```gdscript
## Biome thresholds from archetype
var biome_thresholds: Dictionary = {}

func configure_from_archetype(arch: Dictionary, landmass: String, seed_value: int) -> void:
    # ... existing code ...
    
    # Load biome thresholds (with defaults)
    biome_thresholds = arch.get("biomes", {}).get("thresholds", {
        "water": 0.35,
        "beach": 0.38,
        "grass": 0.5,
        "forest": 0.65,
        "hill": 0.8,
        "mountain": 0.95,
        "snow": 1.0
    })
```

**Update `_generate_biome_image()`:**
```gdscript
func _generate_biome_image(height_img: Image, size: Vector2i) -> Image:
    """Generate biome image using configurable thresholds."""
    var biome_img: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
    
    for y: int in size.y:
        for x: int in size.x:
            var h: float = height_img.get_pixel(x, y).r
            var col: Color = _get_biome_color_from_height(h)
            biome_img.set_pixel(x, y, col)
    
    return biome_img

func _get_biome_color_from_height(height: float) -> Color:
    """Get biome color based on height using configurable thresholds."""
    # Sort thresholds by value
    var sorted_biomes: Array = []
    for biome_name: String in biome_thresholds.keys():
        sorted_biomes.append({
            "name": biome_name,
            "threshold": biome_thresholds[biome_name]
        })
    sorted_biomes.sort_custom(func(a, b): return a["threshold"] < b["threshold"])
    
    # Find matching biome
    for biome_data: Dictionary in sorted_biomes:
        if height < biome_data["threshold"]:
            return Color(biome_colors.get(biome_data["name"], "#000000"))
    
    # Default to last biome (usually snow)
    var last_biome: String = sorted_biomes[-1]["name"]
    return Color(biome_colors.get(last_biome, "#ffffff"))
```

#### Enhancement 2: Temperature/Moisture-Based Biome Generation

**Add noise generators:**
```gdscript
## Temperature and moisture noise generators
var temperature_noise: FastNoiseLite = null
var moisture_noise: FastNoiseLite = null

func _init() -> void:
    super._init()
    noise = FastNoiseLite.new()
    temperature_noise = FastNoiseLite.new()
    moisture_noise = FastNoiseLite.new()

func configure_from_archetype(arch: Dictionary, landmass: String, seed_value: int) -> void:
    # ... existing noise configuration ...
    
    # Configure climate noise
    var climate: Dictionary = arch.get("climate", {})
    var temp_freq: float = climate.get("temperature_noise_frequency", 0.002)
    var moist_freq: float = climate.get("moisture_noise_frequency", 0.002)
    
    temperature_noise.seed = seed_value + 2000
    temperature_noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
    temperature_noise.frequency = temp_freq
    
    moisture_noise.seed = seed_value + 3000
    moisture_noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX
    moisture_noise.frequency = moist_freq
```

**Update biome generation:**
```gdscript
func _generate_biome_image(height_img: Image, size: Vector2i) -> Image:
    """Generate biome image using height + climate."""
    var biome_img: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
    var generation_mode: String = archetype.get("biomes", {}).get("generation_mode", "height_only")
    
    for y: int in size.y:
        for x: int in size.x:
            var h: float = height_img.get_pixel(x, y).r
            var col: Color
            
            if generation_mode == "height_and_climate":
                # Get temperature and moisture
                var world_x: float = float(x) + offset.x
                var world_y: float = float(y) + offset.y
                var temp: float = (temperature_noise.get_noise_2d(world_x, world_y) + 1.0) * 0.5
                var moist: float = (moisture_noise.get_noise_2d(world_x, world_y) + 1.0) * 0.5
                
                col = _get_biome_color_from_climate(h, temp, moist)
            else:
                col = _get_biome_color_from_height(h)
            
            biome_img.set_pixel(x, y, col)
    
    return biome_img

func _get_biome_color_from_climate(height: float, temperature: float, moisture: float) -> Color:
    """Get biome color based on height, temperature, and moisture."""
    # Underwater
    var sea_level: float = archetype.get("terrain", {}).get("sea_level", 0.4)
    if height < sea_level:
        return Color(biome_colors.get("water", "#2a6d9e"))
    
    # Beach
    if height < sea_level + 0.03:
        return Color(biome_colors.get("beach", "#d4b56a"))
    
    # Climate-based biomes (using temperature/moisture)
    # This would use the biome definitions from biomes.json or archetype-specific rules
    # ... implementation would match temperature/moisture to biome types ...
    
    # Fallback to height-based for now
    return _get_biome_color_from_height(height)
```

#### Enhancement 3: Fantasy Biome Support

**Add fantasy biome generation:**
```gdscript
func _generate_biome_image(height_img: Image, size: Vector2i) -> Image:
    """Generate biome image with fantasy biome support."""
    var biome_img: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
    var fantasy_biomes: Dictionary = archetype.get("biomes", {}).get("fantasy_biomes", {})
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = seed
    
    for y: int in size.y:
        for x: int in size.x:
            var h: float = height_img.get_pixel(x, y).r
            var col: Color
            
            # Check for fantasy biomes first
            var world_x: float = float(x) + offset.x
            var world_y: float = float(y) + offset.y
            var temp: float = (temperature_noise.get_noise_2d(world_x, world_y) + 1.0) * 0.5
            var moist: float = (moisture_noise.get_noise_2d(world_x, world_y) + 1.0) * 0.5
            
            var fantasy_match: String = _check_fantasy_biome(h, temp, moist, fantasy_biomes, rng)
            if fantasy_match != "":
                col = Color(biome_colors.get(fantasy_match, "#000000"))
            else:
                col = _get_biome_color_from_climate(h, temp, moist)
            
            biome_img.set_pixel(x, y, col)
    
    return biome_img

func _check_fantasy_biome(height: float, temp: float, moist: float, fantasy_biomes: Dictionary, rng: RandomNumberGenerator) -> String:
    """Check if conditions match a fantasy biome."""
    for biome_name: String in fantasy_biomes.keys():
        var biome_def: Dictionary = fantasy_biomes[biome_name]
        var h_range: Array = biome_def.get("height_range", [0.0, 1.0])
        var t_range: Array = biome_def.get("temperature_range", [0.0, 1.0])
        var m_range: Array = biome_def.get("moisture_range", [0.0, 1.0])
        var spawn_chance: float = biome_def.get("spawn_chance", 0.0)
        
        if (height >= h_range[0] and height <= h_range[1] and
            temp >= t_range[0] and temp <= t_range[1] and
            moist >= m_range[0] and moist <= m_range[1] and
            rng.randf() < spawn_chance):
            return biome_name
    
    return ""
```

#### Enhancement 4: Erosion and Rivers (Optional)

**Note:** Erosion and rivers are computationally expensive and may not be suitable for real-time generation in the datasource. However, they could be:
1. Applied as post-processing after initial generation
2. Configured in archetype but applied separately
3. Enabled only for final high-resolution generation

**Suggested approach:**
- Keep erosion/rivers in `MapGenerator.gd` for full map generation
- Add configuration to archetype JSON for when full generation runs
- Datasource focuses on fast preview generation (height + biomes only)

---

## 5. Implementation Priority

### Phase 1: Core Enhancements (High Priority)
1. ✅ **Configurable Biome Thresholds** - Enables per-archetype customization
2. ✅ **Extended Biome Colors** - Support for fantasy-specific biomes
3. ✅ **Biome Thresholds JSON** - Move hard-coded values to data

### Phase 2: Climate System (Medium Priority)
4. ⚠️ **Temperature/Moisture Noise** - Add climate generation
5. ⚠️ **Climate-Based Biome Selection** - Use temperature/moisture for biome determination
6. ⚠️ **Climate Bias Parameters** - Global climate shifts per archetype

### Phase 3: Fantasy Features (Medium Priority)
7. ⚠️ **Fantasy Biome System** - Conditional fantasy biome spawning
8. ⚠️ **Fantasy Biome Configuration** - JSON structure for fantasy biomes

### Phase 4: Terrain Features (Low Priority)
9. ⚪ **Sea Level Configuration** - Per-archetype sea level
10. ⚪ **Erosion Configuration** - Per-archetype erosion settings (for full generation)
11. ⚪ **River Configuration** - Per-archetype river settings (for full generation)

### Phase 5: Metadata (Low Priority)
12. ⚪ **Additional Params** - Flavor metadata storage (UI/descriptions only)

---

## 6. Backward Compatibility

### 6.1 Migration Strategy

**Current archetypes will continue to work:**
- If `biome_thresholds` missing → use defaults (current hard-coded values)
- If `generation_mode` missing → default to "height_only" (current behavior)
- If `climate` section missing → skip temperature/moisture generation
- If `fantasy_biomes` missing → skip fantasy biome checks

**Example migration:**
```json
// Old format (still works)
{
  "High Fantasy": {
    "noise_type": "TYPE_SIMPLEX",
    "frequency": 0.004,
    "biome_colors": { ... }
  }
}

// New format (enhanced)
{
  "High Fantasy": {
    "noise": {
      "noise_type": "TYPE_SIMPLEX",
      "frequency": 0.004
    },
    "biomes": {
      "colors": { ... },
      "thresholds": { ... }
    }
  }
}
```

---

## 7. Recommended Next Steps

1. **Update JSON Structure** - Migrate `fantasy_archetypes.json` to enhanced format
2. **Enhance Datasource** - Implement configurable thresholds and climate system
3. **Add Fantasy Biomes** - Implement conditional fantasy biome spawning
4. **Test Backward Compatibility** - Ensure existing archetypes still work
5. **Update Documentation** - Document new parameters and structure

---

## 8. Example: Complete Enhanced Archetype

See `docs/ENHANCED_ARCHETYPE_EXAMPLE.json` (to be created) for a complete example of the enhanced structure with all features enabled.

---

## Conclusion

The current datasource pattern is functional but limited. The suggested enhancements would:
- ✅ Enable per-archetype customization (thresholds, sea level, etc.)
- ✅ Support climate-based biome generation
- ✅ Allow fantasy-specific biome types
- ✅ Maintain backward compatibility
- ✅ Provide a clear migration path

**Recommendation:** Implement Phase 1 (Core Enhancements) first, then evaluate performance impact before adding climate system (Phase 2).
