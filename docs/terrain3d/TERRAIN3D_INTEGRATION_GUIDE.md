# Terrain3D Integration Guide

**Last Updated:** 2025-12-09  
**Status:** ✅ **Complete Integration Guide**  
**Terrain3D Version:** 1.0.0 (Godot 4.3 compatible)

---

## 1. Installation Verification

### ✅ Current Status
- **Terrain3D Addon:** Installed at `res://addons/terrain_3d/`
- **Plugin Enabled:** `res://addons/terrain_3d/plugin.cfg` in `project.godot`
- **GDExtension:** Linux x86_64 binaries present
- **Version:** 1.0.0-stable (Godot 4.3 compatible)

### Setup Steps Completed
1. ✅ Addon extracted to `addons/terrain_3d/`
2. ✅ Plugin enabled in `project.godot` → `[editor_plugins]`
3. ✅ Data directory ready (can use `res://data/terrain3d/` or user-defined)

### Configuration Notes
- **Data Directory:** Terrain3D stores region data in a directory (not single file)
- **Recommended Path:** `res://data/terrain3d/` or `user://terrain3d/` for runtime
- **Region Size:** Default 1024m, configurable per terrain
- **Mesh Size:** Default 64m per region cell

---

## 2. Basic Scene Setup

### Adding Terrain3D Node

**Manual Setup:**
1. Add `Terrain3D` node to scene (extends `Node3D`)
2. Set `data_directory` property (e.g., `"res://data/terrain3d"`)
3. Configure `region_size` (default: 1024)
4. Set `mesh_size` (default: 64)
5. Set `vertex_spacing` (default: 1.0, controls mesh density)

**Programmatic Setup:**
```gdscript
var terrain: Terrain3D = Terrain3D.new()
terrain.name = "Terrain3D"
terrain.data_directory = "res://data/terrain3d"
terrain.region_size = 1024  # 1024m per region
terrain.mesh_size = 64      # 64m mesh cells
terrain.vertex_spacing = 1.0  # Higher = lower poly
add_child(terrain)
```

### Initial Parameters

**Key Properties:**
- `region_size: int` - Size of each terrain region in meters (64-65536, default: 1024)
- `mesh_size: int` - Size of mesh cells within regions (default: 64)
- `vertex_spacing: float` - Distance between vertices (1.0 = default density, higher = lower poly)
- `data_directory: String` - Path to store terrain data
- `material: Terrain3DMaterial` - Material/shader configuration
- `assets: Terrain3DAssets` - Texture and mesh asset definitions

---

## 3. Key Runtime-Modifiable Parameters

### Heightmap Editing

**Programmatic Height Modification:**
```gdscript
# Access terrain data
var terrain_data: Terrain3DData = terrain.data

# Get region at location (Vector2i coordinates)
var region_location: Vector2i = Vector2i(0, 0)
var region: Terrain3DRegion = terrain_data.get_region(region_location)

# Get height map
var height_map: Image = region.get_height_map()

# Modify height at position (x, y) - Color.R = height value
var height_value: float = 50.0  # meters
height_map.set_pixel(x, y, Color(height_value, 0.0, 0.0, 1.0))

# Apply changes
region.set_height_map(height_map)
region.update_height()
terrain.update_maps()  # Refresh terrain display
```

**Bulk Height Import:**
```gdscript
# Import heightmap from Image (FORMAT_RF for 32-bit float)
var height_image: Image = Image.create_empty(2048, 2048, false, Image.FORMAT_RF)
# ... populate height_image with noise or data ...
terrain.data.import_images([height_image, null, null], Vector3(-1024, 0, -1024), 0.0, 150.0)
```

### Texture Painting/Blending

**Control Map Modification:**
```gdscript
# Get control map (determines texture blending)
var control_map: Image = region.get_control_map()

# Modify texture weights at position (x, y)
# Color channels: R=texture0, G=texture1, B=texture2, A=texture3
var texture_weights: Color = Color(0.8, 0.2, 0.0, 0.0)  # 80% texture0, 20% texture1
control_map.set_pixel(x, y, texture_weights)

# Apply changes
region.set_control_map(control_map)
region.update_control()
terrain.update_maps()
```

### Collision Updates

**Dynamic Collision:**
```gdscript
# Enable dynamic collision (updates as terrain changes)
terrain.collision.mode = Terrain3DCollision.DYNAMIC_EDITOR  # Editor only
# OR
terrain.collision.mode = Terrain3DCollision.DYNAMIC_RUNTIME  # Runtime updates
```

### Procedural Generation Hooks

**Noise-Based Generation:**
```gdscript
# Generate heightmap from FastNoiseLite
var noise: FastNoiseLite = FastNoiseLite.new()
noise.frequency = 0.0005
noise.seed = 12345

var height_image: Image = Image.create_empty(2048, 2048, false, Image.FORMAT_RF)
for x in height_image.get_width():
    for y in height_image.get_height():
        var noise_value: float = noise.get_noise_2d(x, y)
        height_image.set_pixel(x, y, Color(noise_value, 0.0, 0.0, 1.0))

# Import with scale (min_height, max_height)
terrain.data.import_images([height_image, null, null], Vector3(-1024, 0, -1024), 0.0, 150.0)
```

---

## 4. Real-Time UI Integration

### Dynamic Parameter Updates

**Height Scale Slider:**
```gdscript
func _on_height_scale_changed(value: float) -> void:
    # Modify existing heights by scale factor
    var terrain_data: Terrain3DData = terrain.data
    var region: Terrain3DRegion = terrain_data.get_region(Vector2i(0, 0))
    var height_map: Image = region.get_height_map()
    
    # Scale all heights
    for x in height_map.get_width():
        for y in height_map.get_height():
            var current_height: Color = height_map.get_pixel(x, y)
            var new_height: float = current_height.r * value
            height_map.set_pixel(x, y, Color(new_height, 0.0, 0.0, 1.0))
    
    region.set_height_map(height_map)
    region.update_height()
    terrain.update_maps()
```

**Texture Weight Slider:**
```gdscript
func _on_texture_weight_changed(texture_id: int, weight: float) -> void:
    var terrain_data: Terrain3DData = terrain.data
    var region: Terrain3DRegion = terrain_data.get_region(Vector2i(0, 0))
    var control_map: Image = region.get_control_map()
    
    # Update texture weight for entire region (example: simple uniform)
    var weights: Color = Color.ZERO
    weights[texture_id] = weight
    # Normalize other weights...
    
    # Apply to region (simplified - would need proper blending logic)
    region.set_control_map(control_map)
    region.update_control()
    terrain.update_maps()
```

**Material Parameter Updates:**
```gdscript
func _on_displacement_scale_changed(value: float) -> void:
    terrain.material.set_shader_param("displacement_scale", value)
    # Material changes apply immediately, no update_maps() needed
```

### Signal Connections

**Terrain Update Signals:**
```gdscript
# Connect to terrain signals if available
# Note: Terrain3D may not emit custom signals, use update_maps() after changes
```

**UI Signal Pattern:**
```gdscript
# In UI controller
@onready var height_scale_slider: HSlider = $HeightScaleSlider
@onready var terrain: Terrain3D = get_node("../Terrain3D")

func _ready() -> void:
    height_scale_slider.value_changed.connect(_on_height_scale_changed)

func _on_height_scale_changed(value: float) -> void:
    # Update terrain (see example above)
    pass
```

### Performance Tips

- **Batch Updates:** Make multiple changes, then call `update_maps()` once
- **Region-Based:** Only update regions that changed
- **LOD System:** Terrain3D uses clipmap LOD automatically
- **Async Updates:** Consider using `call_deferred()` for heavy operations

---

## 5. API Essentials

### Core Classes

#### Terrain3D
**Main terrain node class**

**Key Methods:**
- `update_maps()` - Refresh terrain display after modifications
- `snap()` - Snap objects to terrain surface
- `get_height(position: Vector3) -> float` - Get height at world position
- `get_normal(position: Vector3) -> Vector3` - Get surface normal

**Key Properties:**
- `data: Terrain3DData` - Terrain data container
- `material: Terrain3DMaterial` - Material/shader
- `assets: Terrain3DAssets` - Texture/mesh assets
- `region_size: int` - Size of regions in meters
- `mesh_size: int` - Size of mesh cells

#### Terrain3DData
**Terrain data container**

**Key Methods:**
- `get_region(location: Vector2i) -> Terrain3DRegion` - Get region at coordinates
- `import_images(images: Array, origin: Vector3, min_height: float, max_height: float)` - Import heightmap
- `save()` - Save terrain data
- `load()` - Load terrain data

#### Terrain3DRegion
**Individual terrain region**

**Key Methods:**
- `get_height_map() -> Image` - Get height map image
- `set_height_map(image: Image)` - Set height map
- `update_height()` - Apply height changes
- `get_control_map() -> Image` - Get texture control map
- `set_control_map(image: Image)` - Set texture control map
- `update_control()` - Apply texture changes

#### Terrain3DMaterial
**Terrain material/shader**

**Key Methods:**
- `set_shader_param(name: String, value: Variant)` - Set shader parameter
- `get_shader_param(name: String) -> Variant` - Get shader parameter

**Key Properties:**
- `auto_shader: bool` - Use auto-generated shader
- `world_background: int` - Background type (NONE, SKY, COLOR)

#### Terrain3DAssets
**Texture and mesh asset container**

**Key Methods:**
- `set_texture(id: int, asset: Terrain3DTextureAsset)` - Set texture asset
- `get_texture(id: int) -> Terrain3DTextureAsset` - Get texture asset
- `set_mesh_asset(id: int, asset: Terrain3DMeshAsset)` - Set mesh asset

---

## 6. MVP UI Outline

### Simple Panel-Based UI

**Structure:**
```
WorldBuilderUI (Panel)
├── VBoxContainer
│   ├── Label "Terrain Generation"
│   ├── HBoxContainer
│   │   ├── Label "Height Scale:"
│   │   └── HSlider (0.1 - 2.0)
│   ├── HBoxContainer
│   │   ├── Label "Noise Frequency:"
│   │   └── HSlider (0.0001 - 0.01)
│   ├── HBoxContainer
│   │   ├── Label "Texture 0 Weight:"
│   │   └── HSlider (0.0 - 1.0)
│   └── Button "Regenerate Terrain"
```

**Implementation:**
- Use single `.tres` theme (`res://themes/bg3_theme.tres`)
- Connect sliders to terrain update functions
- Use `update_maps()` after parameter changes
- Store parameters in JSON for persistence

---

## 7. Data-Driven Aspects

### JSON Configuration

**Example: `data/config/terrain_generation.json`**
```json
{
  "noise": {
    "seed": 12345,
    "frequency": 0.0005,
    "type": "Perlin",
    "octaves": 4,
    "lacunarity": 2.0,
    "gain": 0.5
  },
  "height": {
    "min": 0.0,
    "max": 150.0,
    "scale": 1.0
  },
  "textures": [
    {
      "id": 0,
      "name": "Grass",
      "weight": 0.8,
      "uv_scale": 0.1
    },
    {
      "id": 1,
      "name": "Dirt",
      "weight": 0.2,
      "uv_scale": 0.03
    }
  ],
  "terrain": {
    "region_size": 1024,
    "mesh_size": 64,
    "vertex_spacing": 1.0
  }
}
```

**Loading and Applying:**
```gdscript
func load_terrain_config(path: String) -> Dictionary:
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("Failed to load terrain config: " + path)
        return {}
    
    var json_string: String = file.get_as_text()
    file.close()
    
    var json: JSON = JSON.new()
    var parse_result: Error = json.parse(json_string)
    if parse_result != OK:
        push_error("Failed to parse terrain config JSON")
        return {}
    
    return json.data as Dictionary

func apply_terrain_config(config: Dictionary, terrain: Terrain3D) -> void:
    # Apply noise settings
    var noise: FastNoiseLite = FastNoiseLite.new()
    noise.seed = config.get("noise", {}).get("seed", 0)
    noise.frequency = config.get("noise", {}).get("frequency", 0.0005)
    
    # Generate and import heightmap
    # ... (see noise generation example above)
    
    # Apply texture weights
    var texture_configs: Array = config.get("textures", [])
    for texture_config in texture_configs:
        var texture_id: int = texture_config.get("id", 0)
        var weight: float = texture_config.get("weight", 0.0)
        # Apply texture weight...
```

---

## 8. Performance Tips for VTT-Scale Maps

### Large World Handling

1. **Clipmap LOD:** Terrain3D uses automatic clipmap LOD - no manual configuration needed
2. **Region-Based Streaming:** Only load/update visible regions
3. **Vertex Spacing:** Increase `vertex_spacing` for lower-poly distant terrain
4. **Texture Resolution:** Use appropriate texture sizes (512-2048)
5. **Batch Updates:** Group multiple changes before calling `update_maps()`

### Recommended Settings for VTT

- **Region Size:** 1024m (good balance)
- **Mesh Size:** 64m (default)
- **Vertex Spacing:** 1.0-2.0 (1.0 = detailed, 2.0 = performance)
- **Texture Count:** 4-8 textures (not all 32)
- **LOD Levels:** Default (10 levels automatic)

---

## Next Steps

1. Create `Terrain3DManager` class for terrain lifecycle
2. Create `WorldBuilderUI` scene with sliders
3. Create `TerrainGenerationConfig` resource for JSON loading
4. Integrate with existing `WorldRoot` scene
5. Test with `run_project` via MCP
