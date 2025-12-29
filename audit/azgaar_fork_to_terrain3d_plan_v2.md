# Azgaar Fork → Terrain3D Integration Plan v2
## Complete Integration Roadmap for Genesis-Azgaar Fork

**Date:** 2025-12-29  
**Status:** Post-Migration Planning  
**Target:** Seamless integration from fork generation → 2D preview → 3D terrain

---

## Executive Summary

This document provides a revised, fork-aligned plan for integrating the **Genesis-Azgaar fork** (modular ES module with headless generation and structured JSON export) with Genesis Mythos' existing systems (`MapMakerModule`, `Terrain3DManager`, `WorldMapData`). 

**Key Difference from Original Plan:** The fork eliminates all iframe/CORS/timeout issues by providing a direct programmatic API. This shifts focus from workarounds to clean data conversion and system integration.

---

## 1. Goals

### Primary Objectives
1. ✅ **Use Azgaar fork to generate procedural world data** (heightmaps, biomes, rivers, settlements)
2. ✅ **Provide interactive 2D preview** for parameter tweaking and approval
3. ✅ **Seed Terrain3D** with accurate heightmap + additional data (biomes, rivers, settlements)
4. ✅ **Achieve reliable, timeout-free generation** (<10s for medium maps)

### Success Criteria
- Fork generates maps without timeouts or IPC failures
- 2D preview renders within 1 second of generation
- Terrain3D imports heightmap correctly with proper scaling
- Full JSON data stored in `WorldMapData` for future reference
- End-to-end flow: UI → Generate → Preview → Approve → 3D

---

## 2. Key Advantages of Fork Migration

### Problems Eliminated
| Old System (Original Azgaar) | Fork Solution |
|------------------------------|---------------|
| ❌ iframe readiness polling (timeouts) | ✅ Direct ES module import → instant initialization |
| ❌ CORS issues (cross-origin iframe) | ✅ Same-origin WebView → no CORS |
| ❌ postMessage injection (fragile) | ✅ Programmatic API calls → reliable |
| ❌ Manual JS eval scraping | ✅ Structured `getMapData()` JSON → clean access |
| ❌ Full UI overhead (slow) | ✅ Headless mode → faster generation |
| ❌ No structured export | ✅ Optimized JSON for Godot consumption |

### Fork API Benefits
```javascript
// Simple, reliable API
import { initGenerator, loadOptions, generateMap, getMapData } from 'azgaar-genesis';

initGenerator({ canvas: null });  // Headless mode
loadOptions({ seed: '42', mapWidth: 960, mapHeight: 540, ... });
const data = generateMap(Delaunator);
const json = getMapData();  // Structured, Godot-ready JSON
```

---

## 3. Current Status

### ✅ Completed
- Fork bundles copied to `res://assets/ui_web/js/azgaar/`
- Prototype HTML template created (`world_builder_v2.html`)
- Headless generation prototyped
- Migration plan documented

### ⏳ In Progress
- JavaScript/GDScript bridge stabilization
- IPC communication testing
- Parameter mapping validation

### 📋 Pending
- JSON → Image conversion (`AzgaarDataConverter.gd`)
- 2D preview integration with `MapMakerModule`
- Terrain3D pipeline connection
- End-to-end testing

---

## 4. Revised Implementation Phases

### Phase 1: Finalize Fork Integration (In Progress → Complete Soon)

#### 1.1 Stabilize IPC Bridge
**Goal:** Ensure reliable communication between Godot WebView and fork JavaScript.

**Tasks:**
- ✅ Test `initGenerator()` initialization
- ⏳ Validate `loadOptions()` parameter passing
- ⏳ Test `generateMap()` execution
- ⏳ Verify `getMapData()` JSON retrieval
- ⏳ Handle fork-specific errors:
  - `InitializationError` (not initialized)
  - `InvalidOptionError` (bad parameter values)
  - `GenerationError` (generation failure)
  - `NoDataError` (no data generated yet)

**GDScript Handler Example:**
```gdscript
# In WorldBuilderWebController.gd
func _handle_map_generated(data: Dictionary) -> void:
	"""Handle successful map generation from fork."""
	var map_data: Dictionary = data.get("data", {})
	var seed_value: String = data.get("seed", "")
	
	MythosLogger.info("WorldBuilderWebController", "Map generated", {
		"seed": seed_value,
		"has_grid": map_data.has("grid"),
		"has_pack": map_data.has("pack")
	})
	
	# Forward to converter
	_convert_and_preview(map_data)

func _handle_map_generation_failed(data: Dictionary) -> void:
	"""Handle generation failure."""
	var error_msg: String = data.get("error", "Unknown error")
	MythosLogger.error("WorldBuilderWebController", "Generation failed", {"error": error_msg})
	
	# Show error in UI
	_show_error("Map generation failed", error_msg)
```

**JavaScript Integration:**
```javascript
// In world_builder_v2.html
async function handleGenerateMap(options) {
    try {
        const { Delaunator, loadOptions, generateMap, getMapData } = window.AzgaarGenesis;
        
        loadOptions(options);
        const data = generateMap(Delaunator);
        const json = getMapData();
        
        // Send to Godot
        if (window.GodotBridge && window.GodotBridge.postMessage) {
            window.GodotBridge.postMessage('map_generated', {
                data: json,
                seed: data.seed
            });
        }
    } catch (error) {
        if (window.GodotBridge && window.GodotBridge.postMessage) {
            window.GodotBridge.postMessage('map_generation_failed', {
                error: error.message,
                stack: error.stack
            });
        }
    }
}
```

#### 1.2 Parameter Mapping
**Goal:** Convert Genesis Mythos UI parameters to fork's options format.

**Mapping Function:**
```gdscript
# In WorldBuilderWebController.gd
func _convert_params_to_azgaar_options(params: Dictionary) -> Dictionary:
	"""Convert Genesis Mythos parameters to Azgaar Genesis options format."""
	var options: Dictionary = {}
	
	# Step 0: Map Generation
	if params.has("templateInput"):
		options["template"] = params["templateInput"]  # "continents", "archipelago", etc.
	if params.has("pointsInput"):
		options["cellsDesired"] = int(params["pointsInput"])
	if params.has("mapWidthInput"):
		options["mapWidth"] = int(params["mapWidthInput"])
	if params.has("mapHeightInput"):
		options["mapHeight"] = int(params["mapHeightInput"])
	if params.has("optionsSeed"):
		options["seed"] = str(params["optionsSeed"])
	
	# Step 1: Heightmap & Relief
	if params.has("heightExponentInput"):
		options["heightExponent"] = float(params["heightExponentInput"])
	if params.has("allowErosionInput"):
		options["allowErosion"] = bool(params["allowErosionInput"])
	if params.has("plateCountInput"):
		options["plateCount"] = int(params["plateCountInput"])
	
	# Step 2: Climate
	if params.has("precipInput"):
		options["precip"] = float(params["precipInput"])
	if params.has("temperatureEquatorInput"):
		options["temperatureEquator"] = float(params["temperatureEquatorInput"])
	if params.has("temperatureNorthPoleInput"):
		options["temperatureNorthPole"] = float(params["temperatureNorthPoleInput"])
	
	# Step 3: States & Cultures
	if params.has("statesNumberInput"):
		options["statesNumber"] = int(params["statesNumberInput"])
	if params.has("culturesSetInput"):
		options["cultures"] = int(params["culturesSetInput"])
	
	# Step 4: Religions
	if params.has("religionsNumberInput"):
		options["religionsNumber"] = int(params["religionsNumberInput"])
	
	# ... map remaining parameters from azgaar_step_parameters.json
	
	return options
```

#### 1.3 Benchmarking
**Target:** <10s generation for medium maps (960x540, ~10k cells)

**Metrics to Track:**
- Fork initialization time
- Parameter loading time
- Map generation time
- JSON extraction time
- Total end-to-end time

**Performance Logger Integration:**
```gdscript
# Use existing PerformanceLogger
PerformanceLogger.log_event("azgaar_generation", {
    "seed": seed_value,
    "map_width": map_width,
    "map_height": map_height,
    "cells_desired": cells_desired,
    "generation_time_ms": generation_time
})
```

---

### Phase 2: Build AzgaarDataConverter.gd

#### 2.1 Create Converter Script
**Location:** `res://scripts/managers/AzgaarDataConverter.gd`

**Purpose:** Convert fork's structured JSON output to Godot-native formats (Image, WorldMapData, etc.)

**Core Structure:**
```gdscript
# ╔═══════════════════════════════════════════════════════════
# ║ AzgaarDataConverter.gd
# ║ Desc: Converts Azgaar Genesis fork JSON output to Godot formats
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends RefCounted
class_name AzgaarDataConverter

## Convert fork JSON to heightmap Image
static func convert_to_heightmap(json_data: Dictionary, map_width: int, map_height: int) -> Image:
	"""
	Convert Azgaar fork JSON grid data to Godot Image (FORMAT_RF).
	
	Fork JSON structure:
	{
		"grid": {
			"cells": {
				"i": [0, 1, 2, ...],      # Cell indices
				"x": [100, 150, 200, ...], # X coordinates
				"y": [50, 100, 150, ...],  # Y coordinates
				"h": [20, 45, 80, ...]     # Heights (0-100 scale, water <20, land 20-100)
			}
		},
		"seed": "42"
	}
	"""
	MythosLogger.verbose("AzgaarConverter", "Converting JSON to heightmap", {
		"width": map_width,
		"height": map_height
	})
	
	# Create float image (Terrain3D requires FORMAT_RF)
	var img := Image.create(map_width, map_height, false, Image.FORMAT_RF)
	img.fill(Color.BLACK)  # Initialize to sea level
	
	# Get grid data
	var grid: Dictionary = json_data.get("grid", {})
	var cells: Dictionary = grid.get("cells", {})
	var cell_indices: Array = cells.get("i", [])
	var cell_x: Array = cells.get("x", [])
	var cell_y: Array = cells.get("y", [])
	var cell_h: Array = cells.get("h", [])
	
	if cell_indices.is_empty():
		MythosLogger.warn("AzgaarConverter", "No cell data in JSON")
		return img
	
	# Map cells to image pixels
	# Fork uses Voronoi cells, so we need to rasterize
	# Strategy: For each pixel, find nearest cell and use its height
	var sea_level: float = 20.0  # Fork uses <20 for water
	var land_min: float = 20.0
	var land_max: float = 100.0
	
	for y in range(map_height):
		for x in range(map_width):
			# Find nearest cell (simple distance-based)
			var nearest_idx: int = 0
			var min_dist: float = INF
			
			for i in range(cell_indices.size()):
				var cell_x_pos: float = float(cell_x[i])
				var cell_y_pos: float = float(cell_y[i])
				var dist: float = Vector2(x, y).distance_to(Vector2(cell_x_pos, cell_y_pos))
				
				if dist < min_dist:
					min_dist = dist
					nearest_idx = i
			
			# Get height from nearest cell
			var height_raw: float = float(cell_h[nearest_idx])
			
			# Normalize: water (0-20) → 0.0-0.2, land (20-100) → 0.2-1.0
			var normalized: float
			if height_raw < sea_level:
				# Water: map 0-20 to 0.0-0.2
				normalized = (height_raw / sea_level) * 0.2
			else:
				# Land: map 20-100 to 0.2-1.0
				normalized = 0.2 + ((height_raw - land_min) / (land_max - land_min)) * 0.8
			
			# Clamp to 0-1
			normalized = clamp(normalized, 0.0, 1.0)
			
			# Set pixel (FORMAT_RF uses red channel for single float)
			img.set_pixel(x, y, Color(normalized, 0.0, 0.0, 1.0))
	
	MythosLogger.info("AzgaarConverter", "Heightmap converted", {
		"size": Vector2i(map_width, map_height),
		"cells_processed": cell_indices.size()
	})
	
	return img

## Extract biome data from fork JSON
static func extract_biomes(json_data: Dictionary) -> Dictionary:
	"""
	Extract biome information from fork JSON.
	
	Returns: Dictionary mapping cell indices to biome types
	{
		"cell_0": "plains",
		"cell_1": "forest",
		...
	}
	"""
	var biomes: Dictionary = {}
	var pack: Dictionary = json_data.get("pack", {})
	var cells: Dictionary = pack.get("cells", {})
	
	# Fork stores biome data in pack.cells.biome array
	if cells.has("biome"):
		var biome_array: Array = cells.get("biome", [])
		for i in range(biome_array.size()):
			biomes["cell_%d" % i] = biome_array[i]
	
	return biomes

## Extract rivers from fork JSON
static func extract_rivers(json_data: Dictionary) -> Array[Dictionary]:
	"""
	Extract river/water features from fork JSON.
	
	Returns: Array of river dictionaries with coordinates
	[
		{"type": "river", "points": [Vector2, Vector2, ...]},
		{"type": "lake", "center": Vector2, "radius": float},
		...
	]
	"""
	var rivers: Array[Dictionary] = []
	var pack: Dictionary = json_data.get("pack", {})
	var features: Array = pack.get("features", [])
	
	for feature in features:
		if feature is Dictionary:
			var feature_type: String = feature.get("type", "")
			if feature_type == "river" or feature_type == "lake":
				rivers.append(feature)
	
	return rivers

## Extract settlements (burgs) from fork JSON
static func extract_settlements(json_data: Dictionary) -> Array[Dictionary]:
	"""
	Extract settlement/burg data from fork JSON.
	
	Returns: Array of settlement dictionaries
	[
		{"name": "City Name", "position": Vector2, "population": int, "type": "city"},
		...
	]
	"""
	var settlements: Array[Dictionary] = []
	var pack: Dictionary = json_data.get("pack", {})
	var burgs: Array = pack.get("burgs", [])
	
	for burg in burgs:
		if burg is Dictionary:
			var settlement: Dictionary = {
				"name": burg.get("name", ""),
				"position": Vector2(burg.get("x", 0.0), burg.get("y", 0.0)),
				"population": burg.get("population", 0),
				"type": burg.get("type", "town")
			}
			settlements.append(settlement)
	
	return settlements

## Convert full JSON to WorldMapData
static func convert_to_world_map_data(json_data: Dictionary, params: Dictionary) -> WorldMapData:
	"""
	Convert fork JSON to WorldMapData resource.
	
	This stores the full fork data in WorldMapData for later reference.
	"""
	var world_data := WorldMapData.new()
	
	# Set basic properties from params
	if params.has("optionsSeed"):
		world_data.set_seed(int(params["optionsSeed"]))
	if params.has("mapWidthInput"):
		world_data.world_width = int(params["mapWidthInput"])
	if params.has("mapHeightInput"):
		world_data.world_height = int(params["mapHeightInput"])
	
	# Convert heightmap
	var heightmap: Image = convert_to_heightmap(
		json_data,
		world_data.world_width,
		world_data.world_height
	)
	world_data.heightmap_image = heightmap
	
	# Store raw JSON for future reference (as metadata)
	# Note: WorldMapData doesn't have a raw_json field, but we can extend it
	# or store in a separate file
	
	MythosLogger.info("AzgaarConverter", "Converted to WorldMapData", {
		"seed": world_data.seed,
		"size": Vector2i(world_data.world_width, world_data.world_height)
	})
	
	return world_data
```

#### 2.2 Optimization: Threaded Conversion
**For Large Maps:** Convert JSON → Image in background thread to avoid UI freeze.

```gdscript
# In WorldBuilderWebController.gd
func _convert_async(json_data: Dictionary, map_width: int, map_height: int) -> void:
	"""Convert JSON to Image in background thread."""
	var thread := Thread.new()
	var result: Image
	
	thread.start(func():
		result = AzgaarDataConverter.convert_to_heightmap(json_data, map_width, map_height)
	)
	
	# Wait for completion (with timeout)
	var timeout: float = 30.0  # 30 seconds max
	var elapsed: float = 0.0
	while not thread.is_alive() and elapsed < timeout:
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
	
	if thread.is_alive():
		thread.wait_to_finish()
	
	if result:
		_on_heightmap_converted(result)
	else:
		_show_error("Conversion failed", "Failed to convert JSON to heightmap")
```

#### 2.3 Testing
**Test Cases:**
- Small map (512x512) → verify conversion accuracy
- Medium map (960x540) → verify performance
- Large map (1920x1080) → verify memory usage
- Edge cases: archipelago (many water cells), high elevation, erosion

---

### Phase 3: 2D Preview Integration

#### 3.1 Primary Approach: MapMakerModule
**Goal:** Use existing `MapMakerModule` to render fork-generated data.

**Integration Flow:**
```gdscript
# In WorldBuilderWebController.gd
func _convert_and_preview(json_data: Dictionary) -> void:
	"""Convert JSON and show 2D preview."""
	# Convert to WorldMapData
	var world_data: WorldMapData = AzgaarDataConverter.convert_to_world_map_data(
		json_data,
		current_params
	)
	
	# Get MapMakerModule reference
	var map_maker: MapMakerModule = get_node_or_null("/root/WorldRoot/.../MapMakerModule")
	if map_maker:
		# Update MapMakerModule with new data
		map_maker.set_world_map_data(world_data)
		map_maker.regenerate_map({})  # Trigger render
		
		MythosLogger.info("WorldBuilderWebController", "2D preview updated")
	else:
		MythosLogger.warn("WorldBuilderWebController", "MapMakerModule not found")
```

**MapMakerModule Integration:**
```gdscript
# In MapMakerModule.gd (add method)
func set_world_map_data(data: WorldMapData) -> void:
	"""Set WorldMapData from external source (e.g., Azgaar fork)."""
	world_map_data = data
	# Trigger renderer update
	if map_renderer:
		map_renderer.set_world_map_data(data)
		map_renderer.update_texture()
```

#### 3.2 Alternative: Fork Canvas Preview
**If needed:** Use fork's `renderPreview()` for live canvas preview in WebView.

```javascript
// In world_builder_v2.html
const canvas = document.getElementById('azgaar-canvas');
canvas.style.display = 'block';  // Show canvas

// Initialize with canvas
initGenerator({ canvas: canvas });

// After generation
renderPreview();  // Renders to canvas
```

**Recommendation:** Use `MapMakerModule` (primary) - it's already integrated and styled. Use canvas preview only if real-time parameter tweaking is needed.

#### 3.3 UI Flow
```
User adjusts params in WorldBuilderWeb
    ↓
Click "Generate Map"
    ↓
Fork generates → JSON received
    ↓
Convert JSON → WorldMapData
    ↓
MapMakerModule renders 2D preview
    ↓
User reviews preview
    ↓
Approve → Proceed to 3D
    OR
Reject → Regenerate with new params
```

---

### Phase 4: Terrain3D Seeding Pipeline

#### 4.1 Heightmap Import
**Goal:** Pass converted heightmap to `Terrain3DManager`.

**Integration:**
```gdscript
# In WorldBuilderWebController.gd
func _on_user_approved_preview() -> void:
	"""User approved 2D preview, proceed to 3D generation."""
	if not current_world_data:
		MythosLogger.error("WorldBuilderWebController", "No world data to export")
		return
	
	var heightmap: Image = current_world_data.heightmap_image
	if not heightmap:
		MythosLogger.error("WorldBuilderWebController", "No heightmap image")
		return
	
	# Get Terrain3DManager
	var terrain_manager: Terrain3DManager = get_node_or_null("/root/WorldRoot/Terrain3DManager")
	if not terrain_manager:
		MythosLogger.error("WorldBuilderWebController", "Terrain3DManager not found")
		return
	
	# Generate 3D terrain
	MythosLogger.info("WorldBuilderWebController", "Generating 3D terrain from heightmap")
	terrain_manager.generate_from_heightmap(
		heightmap,
		min_height=0.0,
		max_height=1000.0,  # Adjust based on fork's height range
		terrain_position=Vector3.ZERO
	)
	
	MythosLogger.info("WorldBuilderWebController", "3D terrain generation complete")
```

#### 4.2 Biome Mapping
**Goal:** Use extracted biome data to assign Terrain3D textures.

**Approach:**
```gdscript
# Extract biomes from JSON
var biomes: Dictionary = AzgaarDataConverter.extract_biomes(json_data)

# Map biomes to Terrain3D texture slots
# This requires Terrain3D's texture system - implementation depends on Terrain3D API
# Example (pseudo-code):
for cell_idx in biomes.keys():
	var biome_type: String = biomes[cell_idx]
	var texture_slot: int = _get_texture_slot_for_biome(biome_type)
	# Apply texture to Terrain3D region
```

#### 4.3 Rivers/Lakes
**Goal:** Add water nodes for rivers and lakes.

**Approach:**
```gdscript
# Extract rivers/lakes
var water_features: Array[Dictionary] = AzgaarDataConverter.extract_rivers(json_data)

# Create water nodes (CSGBox3D or custom WaterPlane)
for feature in water_features:
	if feature.get("type") == "river":
		_create_river_node(feature)
	elif feature.get("type") == "lake":
		_create_lake_node(feature)
```

#### 4.4 Settlements/Provinces
**Goal:** Seed entities via Sim/Entity system.

**Approach:**
```gdscript
# Extract settlements
var settlements: Array[Dictionary] = AzgaarDataConverter.extract_settlements(json_data)

# Create entities (via EntitySim system)
for settlement in settlements:
	var entity_data: Dictionary = {
		"type": "settlement",
		"name": settlement.get("name", ""),
		"position": settlement.get("position", Vector2.ZERO),
		"population": settlement.get("population", 0)
	}
	# Create entity via EntitySim (implementation depends on system)
	# EntitySim.create_entity(entity_data)
```

#### 4.5 Data Storage
**Goal:** Store full JSON in `WorldMapData` for future reference.

**Extension to WorldMapData:**
```gdscript
# Add to WorldMapData.gd
@export var azgaar_json_data: Dictionary = {}  # Store raw fork JSON

# When converting
world_data.azgaar_json_data = json_data  # Store for later
```

---

### Phase 5: Testing & Polish

#### 5.1 Incremental Testing
**Test Progression:**
1. Small map (512x512) → verify basic flow
2. Medium map (960x540) → verify performance
3. Large map (1920x1080) → verify memory/performance
4. Edge cases:
   - Archipelago (many water cells)
   - High elevation (heightExponent > 1.5)
   - Erosion enabled/disabled
   - Various templates (continents, islands, etc.)

#### 5.2 Performance Monitoring
**Use Existing PerformanceLogger:**
```gdscript
PerformanceLogger.log_event("azgaar_to_terrain3d", {
    "generation_time_ms": generation_time,
    "conversion_time_ms": conversion_time,
    "terrain_import_time_ms": terrain_import_time,
    "total_time_ms": total_time,
    "map_size": Vector2i(map_width, map_height)
})
```

#### 5.3 Error Handling
**Comprehensive Error Coverage:**
- Fork initialization failures
- Parameter validation errors
- Generation failures
- JSON parsing errors
- Image conversion failures
- Terrain3D import failures

**User Feedback:**
- Clear error messages in UI
- Retry mechanisms
- Fallback to previous state

#### 5.4 Fallback Strategies
**If Conversion Slow:**
- Cache converted heightmap Images
- Use lower resolution for preview
- Async conversion with progress indicator

**If Terrain3D Import Fails:**
- Validate heightmap format before import
- Provide diagnostic information
- Suggest resolution adjustments

---

## 5. Risks & Mitigations (Updated)

| Risk | Old Plan Issue | New Mitigation |
|------|----------------|----------------|
| **Generation timeouts** | Polling/eval delays | Headless direct call → near-instant |
| **Data extraction inaccuracy** | JS scraping | Structured `getMapData()` JSON |
| **Heightmap scaling issues** | Manual normalization | Converter handles 0-100 → float remapping |
| **Large map performance** | WebView overhead | Headless + threaded conversion |
| **Coordinate mismatches** | Voronoi → raster alignment | Use grid.x/y for precise pixel placement |
| **CORS/iframe issues** | Cross-origin communication | Fork uses same-origin → no CORS |
| **Parameter mapping errors** | Incomplete mapping | Comprehensive mapping function with validation |

---

## 6. Code Examples

### 6.1 Complete Generation Flow
```gdscript
# In WorldBuilderWebController.gd
func _on_generate_button_pressed() -> void:
	"""User clicked Generate button."""
	# Collect parameters
	var params: Dictionary = _collect_all_params()
	
	# Convert to fork options
	var options: Dictionary = _convert_params_to_azgaar_options(params)
	
	# Send to WebView (fork)
	if web_view and web_view.has_method("execute_js"):
		var js_code: String = """
			handleGenerateMap(%s);
		""" % JSON.stringify(options)
		web_view.execute_js(js_code)
	else:
		MythosLogger.error("WorldBuilderWebController", "Cannot execute JS")

func _handle_map_generated(data: Dictionary) -> void:
	"""Fork generated map, convert and preview."""
	var json_data: Dictionary = data.get("data", {})
	
	# Convert to WorldMapData
	current_world_data = AzgaarDataConverter.convert_to_world_map_data(
		json_data,
		current_params
	)
	
	# Show 2D preview
	_show_2d_preview(current_world_data)
	
	# Store for 3D generation
	_pending_3d_data = current_world_data

func _on_user_approved_preview() -> void:
	"""User approved preview, generate 3D."""
	if _pending_3d_data:
		_generate_3d_terrain(_pending_3d_data)
```

### 6.2 Heightmap Conversion (Optimized)
```gdscript
# Optimized version using spatial hash for faster lookup
static func convert_to_heightmap_optimized(json_data: Dictionary, map_width: int, map_height: int) -> Image:
	"""Optimized conversion using spatial hash."""
	var img := Image.create(map_width, map_height, false, Image.FORMAT_RF)
	img.fill(Color.BLACK)
	
	var grid: Dictionary = json_data.get("grid", {})
	var cells: Dictionary = grid.get("cells", {})
	var cell_indices: Array = cells.get("i", [])
	var cell_x: Array = cells.get("x", [])
	var cell_y: Array = cells.get("y", [])
	var cell_h: Array = cells.get("h", [])
	
	# Build spatial hash (grid-based lookup)
	var cell_size: int = 50  # Approximate cell size
	var hash: Dictionary = {}
	
	for i in range(cell_indices.size()):
		var x: int = int(cell_x[i] / cell_size)
		var y: int = int(cell_y[i] / cell_size)
		var key: String = "%d,%d" % [x, y]
		
		if not hash.has(key):
			hash[key] = []
		hash[key].append(i)
	
	# Rasterize using spatial hash
	for y in range(map_height):
		for x in range(map_width):
			var hash_x: int = x / cell_size
			var hash_y: int = y / cell_size
			var key: String = "%d,%d" % [hash_x, hash_y]
			
			var nearest_idx: int = 0
			var min_dist: float = INF
			
			# Check current cell and neighbors
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					var check_key: String = "%d,%d" % [hash_x + dx, hash_y + dy]
					if hash.has(check_key):
						for idx in hash[check_key]:
							var dist: float = Vector2(x, y).distance_to(
								Vector2(cell_x[idx], cell_y[idx])
							)
							if dist < min_dist:
								min_dist = dist
								nearest_idx = idx
			
			# Normalize height
			var height_raw: float = float(cell_h[nearest_idx])
			var normalized: float = _normalize_height(height_raw)
			img.set_pixel(x, y, Color(normalized, 0.0, 0.0, 1.0))
	
	return img
```

---

## 7. Timeline & Milestones

### Week 1: Fork Integration
- ✅ Bundles copied
- ✅ Prototype HTML
- ⏳ IPC bridge stabilization
- ⏳ Parameter mapping validation

### Week 2: Data Conversion
- 📋 Create `AzgaarDataConverter.gd`
- 📋 Implement heightmap conversion
- 📋 Test with sample JSON
- 📋 Optimize for large maps

### Week 3: Preview Integration
- 📋 Integrate with `MapMakerModule`
- 📋 Test 2D preview flow
- 📋 UI polish

### Week 4: Terrain3D Pipeline
- 📋 Connect to `Terrain3DManager`
- 📋 Test heightmap import
- 📋 Add biome/river/settlement support
- 📋 End-to-end testing

### Week 5: Polish & Testing
- 📋 Performance optimization
- 📋 Error handling
- 📋 Documentation
- 📋 Final validation

---

## 8. Next Actions

### Immediate (This Week)
1. ✅ Complete fork IPC bridge testing
2. ✅ Validate parameter mapping
3. 📋 Create `AzgaarDataConverter.gd` skeleton
4. 📋 Test heightmap conversion with sample JSON

### Short-term (Next 2 Weeks)
1. 📋 Complete data converter implementation
2. 📋 Integrate with `MapMakerModule`
3. 📋 Test 2D preview flow
4. 📋 Begin Terrain3D integration

### Medium-term (Next Month)
1. 📋 Complete Terrain3D pipeline
2. 📋 Add biome/river/settlement support
3. 📋 Performance optimization
4. 📋 Comprehensive testing

---

## 9. Questions & Decisions

### Q1: Canvas Preview vs MapMakerModule
**Decision:** Use `MapMakerModule` as primary (already integrated). Canvas preview only if real-time tweaking needed.

### Q2: Heightmap Resolution
**Decision:** Start with fork's native resolution, allow user to scale up/down for Terrain3D.

### Q3: Biome Mapping
**Decision:** Implement basic biome → texture mapping first, extend later.

### Q4: Data Storage
**Decision:** Store full JSON in `WorldMapData.azgaar_json_data` for future reference.

---

## 10. Conclusion

This revised plan provides a clear, fork-aligned roadmap for integrating Azgaar generation with Terrain3D. The fork's programmatic API eliminates previous pain points, allowing focus on clean data conversion and system integration.

**Key Success Factors:**
- ✅ Fork migration eliminates iframe/CORS issues
- ✅ Structured JSON enables reliable data access
- ✅ Existing systems (`MapMakerModule`, `Terrain3DManager`) provide solid foundation
- ✅ Incremental approach allows testing at each phase

**Next Step:** Complete Phase 1 (fork integration), then proceed to Phase 2 (data conversion).

---

**Document Version:** 2.0  
**Last Updated:** 2025-12-29  
**Status:** Active Planning
