# Audit Report v2: Azgaar Parameter Integration Readiness

**Date:** 2025-12-22  
**Purpose:** Updated audit focusing on remaining open areas for Azgaar parameter integration, now that UI responsiveness/resize testing and performance benchmarking have been CONFIRMED fine and do NOT need further investigation.  
**Focus Areas:** Communication bridge feasibility, heightmap export compatibility, downstream system integration, and accessibility/error handling gaps.

**Auditor:** AI Assistant (Auto)  
**Project:** Genesis Mythos - Full First Person 3D Virtual Tabletop RPG  
**Godot Version:** 4.5.1

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Resolved Status from v1](#resolved-status-from-v1)
3. [Azgaar-Godot Communication Bridge](#azgaar-godot-communication-bridge)
4. [Heightmap Export Compatibility](#heightmap-export-compatibility)
5. [Downstream System Integration](#downstream-system-integration)
6. [Accessibility & Error Handling](#accessibility--error-handling)
7. [Updated Recommendations](#updated-recommendations)
8. [Next Steps](#next-steps)

---

## Executive Summary

This v2 audit confirms that **UI responsiveness and performance are no longer blockers** for Azgaar parameter integration. The focus shifts to four critical integration areas:

1. **Communication Bridge:** GDCef JavaScript execution capabilities need verification and implementation
2. **Heightmap Export:** Azgaar data structure access and Terrain3D normalization require careful mapping
3. **Downstream Integration:** EntitySim, FactionEconomy, and WorldStreamer need assessment for Azgaar data consumption
4. **Accessibility & Error Handling:** Azgaar-specific failure modes need dedicated error paths

**Overall Status:** Ready for parameter integration with identified technical requirements.

---

## Resolved Status from v1

### ✅ CONFIRMED: UI Responsiveness & Performance

**Status:** RESOLVED - No further investigation needed

**Confirmed Items:**
- ✅ UI responsiveness tested and verified at multiple resolutions
- ✅ Performance benchmarking confirms 60 FPS target achievable
- ✅ Resize handling works correctly
- ✅ No clipping or distortion issues identified

**Impact:** These areas are no longer blockers for Azgaar parameter integration.

---

## Azgaar-Godot Communication Bridge

### 3.1 Current Implementation Status

**Location:** `scripts/ui/WorldBuilderAzgaar.gd`, `scripts/managers/AzgaarIntegrator.gd`

**Current Capabilities:**
- ✅ GDCef WebView embedded and loading Azgaar (`file://` URL)
- ✅ Azgaar bundle copied to `user://azgaar/` for writability
- ✅ `AzgaarIntegrator.write_options()` exists (writes `options.json`)
- ❌ **NO JavaScript execution** - No evidence of `execute_js()`, `eval()`, or similar methods
- ❌ **NO bidirectional communication** - Cannot read Azgaar data from Godot
- ❌ **NO parameter injection** - `options.json` written but not applied to running Azgaar instance

**Code Analysis:**
```gdscript
// WorldBuilderAzgaar.gd - Current methods:
- load_url() / navigate_to_url() / set_url() ✅
- reload() ✅
- NO execute_js() / NO JavaScript evaluation ❌
```

### 3.2 GDCef JavaScript Execution Research

**Research Findings:**
- GDCef (Godot Chromium Embedded Framework) is a GDExtension wrapper around CEF
- Standard CEF supports JavaScript execution via `ExecuteJavaScript()` or `EvaluateJavaScript()`
- GDCef likely exposes this via GDScript, but **exact API not confirmed in codebase**

**Required GDCef Methods (Hypothetical):**
```gdscript
# Expected methods (need verification):
web_view.execute_js(code: String) -> Variant
web_view.evaluate_js(code: String) -> Variant
web_view.call_js_function(function_name: String, args: Array) -> Variant
```

**Security Considerations:**
- ✅ `user://azgaar/` is safe (user data directory, sandboxed)
- ✅ File writes limited to `options.json` (no arbitrary file access)
- ⚠️ JavaScript execution in WebView could theoretically access local files if not properly sandboxed
- ✅ Azgaar runs from `file://` URL (local, no network access)

**Recommendation:**
- **VERIFY** GDCef JavaScript execution API via:
  1. Check GDCef documentation/examples
  2. Inspect GDCef GDExtension source if available
  3. Test `execute_js()` or similar method existence at runtime
  4. Implement fallback if API unavailable (poll `options.json` + reload)

### 3.3 Azgaar JavaScript Globals & Data Access

**Identified Global Variables (from `main.js`):**

| Variable | Type | Description | Access Pattern |
|----------|------|-------------|----------------|
| `options` | Object | Parameter object | `options.temperatureEquator`, `options.winds`, etc. |
| `pack.cells.h` | TypedArray | Height data (0-100) | `pack.cells.h[cellId]` |
| `pack.cells.p` | Array[Array] | Cell positions `[x, y]` | `pack.cells.p[cellId]` |
| `pack.cells.i` | TypedArray | Cell indices | `pack.cells.i` |
| `pack.burgs` | Array | Settlement data | `pack.burgs[i].x`, `pack.burgs[i].y`, `pack.burgs[i].population` |
| `pack.states` | Array | State/country data | `pack.states[i].name`, `pack.states[i].culture` |
| `pack.cultures` | Array | Culture data | `pack.cultures[i].name` |
| `pack.religions` | Array | Religion data | `pack.religions[i].name` |
| `graphWidth` | Number | Canvas width (pixels) | `graphWidth` |
| `graphHeight` | Number | Canvas height (pixels) | `graphHeight` |
| `seed` | String | Map seed | `seed` |
| `generate()` | Function | Trigger generation | `generate({seed: "123"})` |

**JavaScript Execution Examples (Required):**

```javascript
// Set parameter:
options.temperatureEquator = 28;
byId("temperatureEquatorInput").value = 28;
byId("temperatureEquatorOutput").value = 28;

// Trigger generation:
generate({seed: "123456"});

// Get heightmap data:
(function() {
  if (!pack.cells || !pack.cells.h) return null;
  var width = graphWidth;
  var height = graphHeight;
  var data = [];
  for (var i = 0; i < pack.cells.i.length; i++) {
    var cellId = pack.cells.i[i];
    var [x, y] = pack.cells.p[cellId];
    var h = pack.cells.h[cellId];
    data.push({x: x, y: y, height: h});
  }
  return {width: width, height: height, cells: data};
})();

// Get burgs data:
pack.burgs.map(b => ({
  name: b.name,
  x: b.x,
  y: b.y,
  population: b.population,
  state: b.state,
  culture: b.culture
}));
```

### 3.4 Communication Bridge Implementation Plan

**Phase 1: Verification**
1. Test GDCef JavaScript execution at runtime
2. Document exact API (method names, return types, error handling)
3. Create test script to verify bidirectional communication

**Phase 2: Implementation**
1. Add `execute_azgaar_js(code: String) -> Variant` to `WorldBuilderAzgaar.gd`
2. Add `set_azgaar_parameter(param_name: String, value: Variant) -> bool`
3. Add `get_azgaar_parameter(param_name: String) -> Variant`
4. Add `trigger_azgaar_generation(seed: String = "") -> void`
5. Add error handling for JS execution failures

**Phase 3: Fallback Strategy**
- If JavaScript execution unavailable:
  1. Write `options.json` via `AzgaarIntegrator.write_options()`
  2. Reload WebView to apply options
  3. Poll for generation completion (check `pack.cells.h` existence)
  4. Extract data via file-based export (if Azgaar supports it)

**Risk Assessment:**
- **HIGH:** If GDCef doesn't support JavaScript execution, fallback is required
- **MEDIUM:** JavaScript execution may be async (need await/promise handling)
- **LOW:** Security risk (local file:// URL, sandboxed)

---

## Heightmap Export Compatibility

### 4.1 Azgaar Heightmap Data Structure

**Source:** `tools/azgaar/main.js:1180`

**Data Format:**
- `pack.cells.h` - TypedArray (Uint8Array or similar) with height values **0-100**
- `pack.cells.p` - Array of `[x, y]` positions for each cell
- `pack.cells.i` - TypedArray of cell indices
- `graphWidth` / `graphHeight` - Canvas dimensions in pixels

**Key Characteristics:**
- Heights are **0-100 range** (not normalized 0-1)
- Cells are **Voronoi-based** (irregular polygons, not grid)
- Ocean cells have `h < 20` (sea level threshold)
- Land cells have `h >= 20`

**Export Challenge:**
- Azgaar uses **irregular Voronoi cells**, not a regular grid
- Terrain3D expects **regular grid heightmap** (Image with pixel-per-cell)
- Need to **rasterize** Voronoi cells to grid

### 4.2 Terrain3D Import Requirements

**Source:** `core/world_generation/Terrain3DManager.gd:170-215`

**Required Format:**
- `Image.FORMAT_RF` (single-channel float, 0.0-1.0 range)
- Regular grid (width × height pixels)
- Height values normalized to 0.0-1.0
- `terrain.data.import_images([heightmap, null, null], offset, 1.0, height_range)`

**Parameters:**
- `offset: Vector3` - World position offset (typically `Vector3(-width/2, min_height, -height/2)`)
- `height_range: float` - Height range in world units (e.g., `max_height - min_height`)

**Current Implementation:**
```gdscript
func generate_from_heightmap(heightmap_image: Image, min_height: float = -50.0, max_height: float = 300.0, terrain_position: Vector3 = Vector3.ZERO) -> void:
    # Converts Image.FORMAT_RF to Terrain3D
    # Expects normalized 0.0-1.0 values
```

### 4.3 Normalization & Conversion Strategy

**Step 1: Extract Azgaar Data**
```javascript
// JavaScript to extract heightmap:
(function() {
  if (!pack.cells || !pack.cells.h) return null;
  var width = graphWidth;
  var height = graphHeight;
  var cells = [];
  for (var i = 0; i < pack.cells.i.length; i++) {
    var cellId = pack.cells.i[i];
    var [x, y] = pack.cells.p[cellId];
    var h = pack.cells.h[cellId];
    cells.push({x: x, y: y, height: h, cellId: cellId});
  }
  return {width: width, height: height, cells: cells};
})();
```

**Step 2: Rasterize to Grid**
```gdscript
# GDScript conversion:
func _rasterize_azgaar_heightmap(azgaar_data: Dictionary) -> Image:
    var width: int = azgaar_data["width"]
    var height: int = azgaar_data["height"]
    var cells: Array = azgaar_data["cells"]
    
    # Create grid image
    var image: Image = Image.create(width, height, false, Image.FORMAT_RF)
    image.fill(Color(0.0, 0.0, 0.0, 1.0))  # Initialize to sea level (0.0)
    
    # Rasterize Voronoi cells to grid
    # Option 1: Sample nearest cell for each pixel
    for y in range(height):
        for x in range(width):
            var nearest_cell = _find_nearest_cell(x, y, cells)
            if nearest_cell:
                # Normalize: Azgaar 0-100 → Terrain3D 0.0-1.0
                var normalized_height: float = nearest_cell["height"] / 100.0
                image.set_pixel(x, y, Color(normalized_height, 0.0, 0.0, 1.0))
    
    return image
```

**Step 3: Handle Ocean/Land Threshold**
- Azgaar: `h < 20` = ocean
- Terrain3D: Can use negative heights or 0.0 for ocean
- **Decision:** Map Azgaar `h < 20` to Terrain3D `0.0` (sea level)
- Map Azgaar `h >= 20` to Terrain3D `0.2-1.0` (land, normalized)

**Normalization Formula:**
```gdscript
# Azgaar height (0-100) → Terrain3D normalized (0.0-1.0)
func _normalize_azgaar_height(azgaar_h: int) -> float:
    if azgaar_h < 20:  # Ocean
        return 0.0
    else:  # Land
        # Map 20-100 to 0.2-1.0
        return 0.2 + ((azgaar_h - 20) / 80.0) * 0.8
```

### 4.4 Compatibility Assessment

**✅ COMPATIBLE:**
- Terrain3D accepts `Image.FORMAT_RF` (single-channel float)
- Normalization straightforward (0-100 → 0.0-1.0)
- Offset and height_range parameters allow flexible positioning

**⚠️ CHALLENGES:**
1. **Voronoi → Grid Rasterization:** Need efficient algorithm (nearest-neighbor or interpolation)
2. **Cell Density:** Azgaar cells may be sparse (not every pixel has a cell)
3. **Performance:** Large maps (100K cells) may require optimization
4. **Artifacts:** Erosion and lake formation may create discontinuities

**Recommendations:**
- Use **nearest-neighbor sampling** for simplicity (fast, acceptable quality)
- Consider **bilinear interpolation** for smoother results (slower)
- Cache rasterized heightmap to avoid re-computation
- Add progress indicator for large maps

---

## Downstream System Integration

### 5.1 Current System Status

**EntitySim (`core/sim/entity_sim.gd`):**
- ✅ Singleton exists
- ❌ **STUB IMPLEMENTATION** - Only `_ready()` with logging
- ❌ No entity data structures
- ❌ No Azgaar data consumption

**FactionEconomy (`core/sim/faction_economy.gd`):**
- ✅ Singleton exists
- ❌ **STUB IMPLEMENTATION** - Only `_ready()` with logging
- ❌ No faction data structures
- ❌ No Azgaar data consumption

**WorldStreamer (`core/streaming/world_streamer.gd`):**
- ✅ Singleton exists
- ❌ **STUB IMPLEMENTATION** - Only `_ready()` with logging
- ❌ No streaming logic
- ❌ No Azgaar data consumption

### 5.2 Azgaar Data Available for Integration

**From Azgaar `pack` Object:**

| Data Type | Azgaar Source | Potential Use | Integration Complexity |
|-----------|---------------|---------------|------------------------|
| **States** | `pack.states[i]` | Faction definitions | **LOW** - Direct mapping possible |
| **Burgs** | `pack.burgs[i]` | Settlement locations | **LOW** - Position + population data |
| **Cultures** | `pack.cultures[i]` | Cultural regions | **MEDIUM** - Need cell-to-culture mapping |
| **Religions** | `pack.religions[i]` | Religious regions | **MEDIUM** - Need cell-to-religion mapping |
| **Provinces** | `pack.provinces[i]` | Administrative regions | **LOW** - Direct mapping possible |
| **Routes** | `pack.routes[i]` | Trade/transport paths | **MEDIUM** - Path data structure |
| **Biomes** | `pack.cells.biome[i]` | Biome per cell | **LOW** - Already have biomes.json |
| **Population** | `pack.cells.pop[i]` | Rural population | **MEDIUM** - Need aggregation |

**Example Azgaar State Object:**
```javascript
pack.states[i] = {
  i: 1,                    // State ID
  name: "Kingdom of Eldoria",
  capital: 5,              // Burg ID of capital
  culture: 2,              // Culture ID
  type: "Kingdom",         // State form
  expansionism: 0.5,       // Expansion tendency
  area: 12345,            // Area in cells
  // ... more fields
}
```

**Example Azgaar Burg Object:**
```javascript
pack.burgs[i] = {
  i: 5,                    // Burg ID
  name: "Eldoria City",
  x: 450.5,                // X position
  y: 320.2,                // Y position
  cell: 123,               // Cell ID
  state: 1,                // State ID
  population: 50000,       // Population
  type: "city",            // city/town/village
  port: true,              // Has port
  // ... more fields
}
```

### 5.3 Integration Feasibility Assessment

#### EntitySim Integration

**Current State:** Stub only

**Azgaar Data Needed:**
- Burgs → NPC spawn locations
- Population → NPC density
- Cultures → NPC cultural identity

**Integration Plan:**
1. Extract burgs data from Azgaar after generation
2. Convert Azgaar coordinates to Godot world coordinates
3. Create entity spawn points at burg locations
4. Use population data for spawn density
5. Use culture data for entity appearance/behavior

**Complexity:** **MEDIUM** - Requires coordinate transformation and entity system design

**Recommendation:**
- **Phase 1:** Extract and store Azgaar data in Godot-friendly format (JSON/Dictionary)
- **Phase 2:** Create entity spawn system that reads Azgaar burg data
- **Phase 3:** Integrate with existing EntitySim when implemented

#### FactionEconomy Integration

**Current State:** Stub only

**Azgaar Data Needed:**
- States → Factions
- Burgs → Economic centers
- Routes → Trade routes
- Provinces → Administrative regions

**Integration Plan:**
1. Map `pack.states` to faction definitions
2. Use burg population for economic strength
3. Use routes for trade network
4. Use provinces for resource distribution

**Complexity:** **LOW** - Direct mapping possible, but FactionEconomy needs implementation

**Recommendation:**
- **Phase 1:** Design faction data structure based on Azgaar states
- **Phase 2:** Implement FactionEconomy to consume Azgaar state/burg data
- **Phase 3:** Add trade route system using Azgaar routes

#### WorldStreamer Integration

**Current State:** Stub only

**Azgaar Data Needed:**
- Cell positions → Streaming regions
- Biome data → Region properties
- Height data → LOD levels

**Integration Plan:**
1. Divide Azgaar map into streaming regions (chunks)
2. Use biome data for region properties
3. Use height data for LOD selection
4. Stream regions based on player position

**Complexity:** **MEDIUM** - Requires streaming system design

**Recommendation:**
- **Phase 1:** Design streaming region system
- **Phase 2:** Implement WorldStreamer to consume Azgaar cell data
- **Phase 3:** Add LOD system based on distance/height

### 5.4 Data Export Format Recommendation

**Create Azgaar Data Exporter:**

```gdscript
# In WorldBuilderAzgaar.gd or new AzgaarDataExporter.gd
func export_azgaar_world_data() -> Dictionary:
    """Export all Azgaar data to Godot-friendly format."""
    var js_code = """
    (function() {
        if (!pack) return null;
        return {
            seed: seed,
            width: graphWidth,
            height: graphHeight,
            states: pack.states.map(s => ({
                id: s.i,
                name: s.name,
                capital: s.capital,
                culture: s.culture,
                type: s.type,
                area: s.area
            })),
            burgs: pack.burgs.map(b => ({
                id: b.i,
                name: b.name,
                x: b.x,
                y: b.y,
                cell: b.cell,
                state: b.state,
                population: b.population,
                type: b.type,
                port: b.port || false
            })),
            cultures: pack.cultures.map(c => ({
                id: c.i,
                name: c.name
            })),
            religions: pack.religions.map(r => ({
                id: r.i,
                name: r.name
            }))
        };
    })();
    """
    var result = execute_azgaar_js(js_code)
    return result as Dictionary
```

**Storage:**
- Save to `user://world_data/azgaar_world_{seed}.json`
- Load by EntitySim/FactionEconomy/WorldStreamer on demand
- Cache in memory for performance

---

## Accessibility & Error Handling

### 6.1 Current Accessibility Status

**WorldBuilderUI Analysis:**

**Keyboard Navigation:**
- ✅ Tab navigation exists (`_setup_navigation()` in WorldBuilderUI.gd)
- ✅ Button focus management
- ⚠️ **WebView (Azgaar) focus handling UNKNOWN** - GDCef may not support keyboard focus
- ⚠️ **No explicit focus indicators** - Theme may provide, but not verified

**Screen Reader Support:**
- ❌ No ARIA labels or screen reader hints
- ❌ No alt text for map previews
- ❌ No descriptive labels for parameter controls

**Color Contrast:**
- ✅ Theme uses `bg3_theme.tres` (should have good contrast)
- ⚠️ **Not verified** - No color-blind mode testing

**Font Scaling:**
- ✅ UIConstants used for font sizes
- ✅ Theme overrides support scaling
- ⚠️ **Not tested** - No explicit font scaling UI

### 6.2 Azgaar-Specific Accessibility Concerns

**WebView Accessibility:**
- GDCef embeds Chromium, which has built-in accessibility
- **BUT:** WebView may not expose accessibility to Godot's accessibility system
- **RISK:** Screen readers may not see Azgaar content

**Keyboard Navigation in WebView:**
- Azgaar UI uses standard HTML controls (should be keyboard-navigable)
- **BUT:** Focus may not transfer between Godot UI and WebView
- **RISK:** Tab navigation may skip WebView entirely

**Recommendations:**
1. Test keyboard navigation with WebView visible
2. Add explicit focus management for WebView
3. Provide alternative UI for Azgaar parameters (Godot-native controls)
4. Add screen reader announcements for generation status

### 6.3 Error Handling Gaps

**Current Error Handling:**

**WorldBuilderUI:**
- ✅ MythosLogger used extensively
- ✅ Null checks for node references
- ✅ Error messages for invalid inputs
- ⚠️ **No Azgaar-specific error handling**

**Azgaar-Specific Error Scenarios:**

| Error Type | Current Handling | Required Handling |
|------------|------------------|-------------------|
| **GDCef not loaded** | ✅ Logged, graceful degradation | ✅ Adequate |
| **Azgaar generation timeout** | ❌ None | ⚠️ Need timeout + progress dialog |
| **Invalid parameters** | ❌ None | ⚠️ Need validation before injection |
| **JavaScript execution failure** | ❌ None | ⚠️ Need try/catch + fallback |
| **Heightmap export failure** | ❌ None | ⚠️ Need error dialog + retry option |
| **options.json write failure** | ❌ None | ⚠️ Need error handling in AzgaarIntegrator |
| **Azgaar WebView crash** | ❌ None | ⚠️ Need crash detection + recovery |

**Required Error Handling:**

```gdscript
# In WorldBuilderAzgaar.gd
func execute_azgaar_js(code: String) -> Variant:
    """Execute JavaScript with error handling."""
    if not web_view:
        MythosLogger.error("WorldBuilderAzgaar", "WebView not initialized")
        return null
    
    if not web_view.has_method("execute_js"):
        MythosLogger.error("WorldBuilderAzgaar", "GDCef does not support JavaScript execution")
        return null
    
    try:
        var result = web_view.execute_js(code)
        return result
    except error:
        MythosLogger.error("WorldBuilderAzgaar", "JavaScript execution failed", {"error": str(error), "code": code})
        return null

func trigger_azgaar_generation(seed: String = "") -> bool:
    """Trigger Azgaar generation with timeout handling."""
    var js_code = 'generate(' + (('{seed: "' + seed + '"}') if seed else '{}') + ')'
    
    # Set timeout
    var timeout_timer = Timer.new()
    timeout_timer.wait_time = 60.0  # 60 second timeout
    timeout_timer.one_shot = true
    add_child(timeout_timer)
    timeout_timer.timeout.connect(_on_generation_timeout)
    timeout_timer.start()
    
    var result = execute_azgaar_js(js_code)
    timeout_timer.queue_free()
    
    if result == null:
        _show_error_dialog("Azgaar generation failed", "JavaScript execution returned null. Check console for details.")
        return false
    
    return true

func _on_generation_timeout() -> void:
    """Handle generation timeout."""
    MythosLogger.error("WorldBuilderAzgaar", "Azgaar generation timed out after 60 seconds")
    _show_error_dialog("Generation Timeout", "Azgaar map generation took too long. Try reducing cell density or map size.")
```

### 6.4 Error Recovery Strategies

**Generation Failure:**
1. Show error dialog with retry option
2. Log error details to MythosLogger
3. Allow user to adjust parameters and retry
4. Fallback to MapMakerModule if Azgaar fails

**Heightmap Export Failure:**
1. Show error dialog
2. Allow manual export (if Azgaar supports file download)
3. Fallback to screenshot-based extraction (lower quality)

**Parameter Validation:**
1. Validate ranges before injection
2. Show warnings for performance-intensive settings
3. Auto-clamp based on hardware profile
4. Prevent generation if critical parameters invalid

---

## Updated Recommendations

### 7.1 Phase 1: Communication Bridge (Week 1)

**Priority: CRITICAL**

**Task 1.1: Verify GDCef JavaScript Execution**
- Test `web_view.execute_js()` or equivalent at runtime
- Document exact API (method name, parameters, return type)
- Create test script to verify bidirectional communication
- **Deliverable:** GDCef API documentation + test results

**Task 1.2: Implement JavaScript Bridge**
- Add `execute_azgaar_js()` to `WorldBuilderAzgaar.gd`
- Add `set_azgaar_parameter()` and `get_azgaar_parameter()`
- Add `trigger_azgaar_generation()` with timeout handling
- **Files:** `scripts/ui/WorldBuilderAzgaar.gd`

**Task 1.3: Implement Fallback Strategy**
- If JS execution unavailable, use `options.json` + reload
- Add polling for generation completion
- **Files:** `scripts/ui/WorldBuilderAzgaar.gd`, `scripts/managers/AzgaarIntegrator.gd`

### 7.2 Phase 2: Heightmap Export (Week 2)

**Priority: HIGH**

**Task 2.1: Create Heightmap Extraction**
- Implement JavaScript to extract `pack.cells.h` data
- Add `export_azgaar_heightmap() -> Image` method
- **Files:** `scripts/ui/WorldBuilderAzgaar.gd`

**Task 2.2: Implement Rasterization**
- Create `_rasterize_azgaar_heightmap()` function
- Use nearest-neighbor sampling (fast) or bilinear (smooth)
- Handle ocean/land threshold (h < 20 → 0.0)
- Normalize 0-100 → 0.0-1.0
- **Files:** `scripts/ui/WorldBuilderAzgaar.gd` or new `AzgaarHeightmapConverter.gd`

**Task 2.3: Integrate with Terrain3D**
- Modify `_on_bake_to_3d_pressed()` to check for Azgaar map
- Use `export_azgaar_heightmap()` if available
- Pass to `Terrain3DManager.generate_from_heightmap()`
- **Files:** `ui/world_builder/WorldBuilderUI.gd`

### 7.3 Phase 3: Downstream Integration (Week 3-4)

**Priority: MEDIUM (Future)**

**Task 3.1: Create Azgaar Data Exporter**
- Implement `export_azgaar_world_data() -> Dictionary`
- Extract states, burgs, cultures, religions, routes
- Save to `user://world_data/azgaar_world_{seed}.json`
- **Files:** New `scripts/managers/AzgaarDataExporter.gd`

**Task 3.2: Design EntitySim Integration**
- Design entity spawn system using Azgaar burg data
- Create coordinate transformation (Azgaar → Godot world)
- **Files:** `core/sim/entity_sim.gd` (when implemented)

**Task 3.3: Design FactionEconomy Integration**
- Design faction system using Azgaar states
- Map states → factions, burgs → economic centers
- **Files:** `core/sim/faction_economy.gd` (when implemented)

**Task 3.4: Design WorldStreamer Integration**
- Design streaming regions using Azgaar cell data
- Use biome/height for LOD selection
- **Files:** `core/streaming/world_streamer.gd` (when implemented)

### 7.4 Phase 4: Accessibility & Error Handling (Week 2-3)

**Priority: MEDIUM**

**Task 4.1: Add Error Handling**
- Implement timeout handling for generation
- Add error dialogs for failures
- Add parameter validation
- **Files:** `scripts/ui/WorldBuilderAzgaar.gd`, `ui/world_builder/WorldBuilderUI.gd`

**Task 4.2: Improve Accessibility**
- Test keyboard navigation with WebView
- Add focus indicators
- Add screen reader support
- **Files:** `ui/world_builder/WorldBuilderUI.gd`, `ui/world_builder/WorldBuilderUI.tscn`

**Task 4.3: Add Error Recovery**
- Implement retry mechanisms
- Add fallback to MapMakerModule
- Add parameter auto-clamping
- **Files:** `ui/world_builder/WorldBuilderUI.gd`

---

## Next Steps

### Immediate Actions (This Week)

1. **Verify GDCef JavaScript Execution:**
   - [ ] Test `execute_js()` or equivalent method at runtime
   - [ ] Document API if available
   - [ ] Create test script

2. **Implement Communication Bridge:**
   - [ ] Add JavaScript execution methods to `WorldBuilderAzgaar.gd`
   - [ ] Implement parameter get/set functions
   - [ ] Add generation trigger with timeout

3. **Create Heightmap Export:**
   - [ ] Implement JavaScript extraction
   - [ ] Create rasterization function
   - [ ] Test with Terrain3D import

### Short-Term (Next 2 Weeks)

4. **Error Handling:**
   - [ ] Add timeout handling
   - [ ] Add error dialogs
   - [ ] Add parameter validation

5. **Accessibility:**
   - [ ] Test keyboard navigation
   - [ ] Add focus indicators
   - [ ] Add screen reader support

### Medium-Term (Next Month)

6. **Downstream Integration:**
   - [ ] Create Azgaar data exporter
   - [ ] Design EntitySim integration
   - [ ] Design FactionEconomy integration
   - [ ] Design WorldStreamer integration

---

## Appendix A: GDCef JavaScript Execution Research

### A.1 Expected API (Hypothetical)

Based on standard CEF patterns, GDCef likely provides:

```gdscript
# Method 1: Execute JavaScript and return result
var result = web_view.execute_js("return pack.cells.h.length;")

# Method 2: Evaluate JavaScript expression
var result = web_view.evaluate_js("pack.cells.h")

# Method 3: Call JavaScript function
var result = web_view.call_js_function("generate", [{"seed": "123"}])
```

### A.2 Verification Steps

1. **Runtime Inspection:**
   ```gdscript
   # In WorldBuilderAzgaar._initialize_webview()
   var methods = web_view.get_method_list()
   for method in methods:
       if "js" in method.name.to_lower() or "execute" in method.name.to_lower():
           print("Found JS method: ", method.name)
   ```

2. **Documentation Check:**
   - Check GDCef GitHub repository
   - Check GDCef examples
   - Check CEF documentation (GDCef wraps CEF)

3. **Test Execution:**
   ```gdscript
   # Test simple JavaScript execution
   var test_code = "return 42;"
   var result = web_view.execute_js(test_code)  # Should return 42
   ```

### A.3 Fallback Implementation

If JavaScript execution unavailable:

```gdscript
func set_azgaar_parameter_fallback(param_name: String, value: Variant) -> bool:
    """Set parameter via options.json + reload."""
    var options = {}
    options[param_name] = value
    options["regenerateOnLoad"] = false  # Don't auto-regenerate
    
    if AzgaarIntegrator.write_options(options):
        web_view.reload()
        return true
    return false
```

---

## Appendix B: Heightmap Rasterization Algorithms

### B.1 Nearest-Neighbor (Fast)

```gdscript
func _rasterize_nearest_neighbor(cells: Array, width: int, height: int) -> Image:
    """Fast rasterization using nearest cell."""
    var image = Image.create(width, height, false, Image.FORMAT_RF)
    var quadtree = _build_quadtree(cells)  # Build spatial index
    
    for y in range(height):
        for x in range(width):
            var nearest = quadtree.find_nearest(Vector2(x, y))
            var h = _normalize_azgaar_height(nearest["height"])
            image.set_pixel(x, y, Color(h, 0.0, 0.0, 1.0))
    
    return image
```

**Performance:** O(n × m) where n = pixels, m = cells (with quadtree: O(n × log m))

### B.2 Bilinear Interpolation (Smooth)

```gdscript
func _rasterize_bilinear(cells: Array, width: int, height: int) -> Image:
    """Smooth rasterization using bilinear interpolation."""
    var image = Image.create(width, height, false, Image.FORMAT_RF)
    var quadtree = _build_quadtree(cells)
    
    for y in range(height):
        for x in range(width):
            var pos = Vector2(x, y)
            var neighbors = quadtree.find_neighbors(pos, 4)  # 4 nearest cells
            var h = _interpolate_bilinear(pos, neighbors)
            image.set_pixel(x, y, Color(h, 0.0, 0.0, 1.0))
    
    return image
```

**Performance:** O(n × log m) - Slower but smoother

**Recommendation:** Start with nearest-neighbor, add bilinear as option later.

---

## Appendix C: Azgaar Data Structure Reference

### C.1 Complete Pack Object Structure

```javascript
pack = {
  cells: {
    i: TypedArray,           // Cell indices
    p: Array[[x, y]],        // Cell positions
    h: TypedArray,           // Heights (0-100)
    area: TypedArray,        // Cell areas
    biome: TypedArray,        // Biome IDs
    culture: TypedArray,      // Culture IDs
    state: TypedArray,        // State IDs
    province: TypedArray,     // Province IDs
    religion: TypedArray,     // Religion IDs
    pop: Float32Array,        // Population
    s: Int16Array,            // Suitability
    // ... more fields
  },
  states: Array[{
    i: int,
    name: string,
    capital: int,
    culture: int,
    type: string,
    area: int,
    // ... more fields
  }],
  burgs: Array[{
    i: int,
    name: string,
    x: float,
    y: float,
    cell: int,
    state: int,
    population: int,
    type: string,
    port: bool,
    // ... more fields
  }],
  cultures: Array[{
    i: int,
    name: string,
    // ... more fields
  }],
  religions: Array[{
    i: int,
    name: string,
    // ... more fields
  }],
  provinces: Array[{
    i: int,
    name: string,
    state: int,
    center: int,
    // ... more fields
  }],
  routes: Array[{
    i: int,
    type: string,
    // ... more fields
  }]
}
```

### C.2 Global Variables

```javascript
// Map dimensions
graphWidth: number          // Canvas width (pixels)
graphHeight: number         // Canvas height (pixels)

// Generation
seed: string                // Map seed
options: object             // Parameter object

// Functions
generate(options): void     // Trigger generation
```

---

## Appendix D: Error Handling Checklist

### D.1 Pre-Generation Validation

- [ ] Validate parameter ranges
- [ ] Check hardware limits (pointsInput clamping)
- [ ] Verify WebView is loaded
- [ ] Check options.json write permissions
- [ ] Validate seed format

### D.2 During Generation

- [ ] Monitor generation progress (if possible)
- [ ] Set timeout (60 seconds default)
- [ ] Handle JavaScript errors
- [ ] Handle WebView crashes
- [ ] Show progress dialog

### D.3 Post-Generation

- [ ] Verify `pack.cells.h` exists
- [ ] Check heightmap data validity
- [ ] Handle export failures
- [ ] Validate exported Image format
- [ ] Test Terrain3D import

### D.4 User-Facing Errors

- [ ] Generation timeout → Show dialog with retry
- [ ] Invalid parameters → Show validation errors
- [ ] Export failure → Show error + fallback option
- [ ] WebView crash → Show error + reload option
- [ ] Low memory → Show warning + suggest lower settings

---

**End of Audit Report v2**

