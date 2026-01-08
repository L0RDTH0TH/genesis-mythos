# Azgaar Integration & Procedural World Generation Audit
**Genesis Mythos - Full First Person 3D Virtual Tabletop RPG**  
**Date:** 2026-01-01  
**Scope:** Comprehensive audit of Azgaar integration and procedural world generation pipeline

---

## 1. Project Overview

### 1.1 Godot Version Confirmation
- **Confirmed Version:** `4.6.beta2` (from `project.godot:69`)
- **Project Name:** "Eryndor 4.0 Final"
- **Main Scene:** `res://scenes/MainMenuWeb.tscn`
- **Engine Features:** `PackedStringArray("4.6", "Forward Plus")`

### 1.2 Folder Structure vs. Rules Comparison

#### ✅ **Compliant Structure:**
- `assets/ui_web/` - WebView HTML/CSS/JS templates (per rules)
- `assets/ui_web/js/azgaar/` - Azgaar fork JavaScript modules
- `assets/ui_web/templates/` - HTML templates (world_builder.html, world_builder_v2.html)
- `scripts/managers/` - AzgaarIntegrator.gd, AzgaarServer.gd, AzgaarDataConverter.gd
- `core/world_generation/` - Terrain3DManager.gd, WorldGenerator.gd (deprecated)
- `data/config/` - Azgaar configuration JSON files

#### ⚠️ **Deviations:**
- `tools/azgaar/` - **Monolithic bundle** (1302 files, 615 no-ext, 338 SVG, 232 JS)
  - Contains original Azgaar FMG with full UI, dependencies, assets
  - Not used directly (served via AzgaarServer HTTP on port 8080)
  - Duplicate: `tools/azgaar-fork/` exists but appears unused
  
- `scripts/ui/WorldBuilderAzgaar.gd` - **Legacy script** (found via grep but not actively used)
  - Contains `DEBUG_DISABLE_AZGAAR = true` diagnostic flag
  - Replaced by `WorldBuilderWebController.gd` (fork-based)

#### 📋 **Missing/Incomplete:**
- `scenes/tools/` directory does not exist (per rules, should contain GM tools scenes)
- No dedicated Azgaar integration test scenes in `demo/` or `tests/`

---

## 2. Azgaar-Related Files Inventory

### 2.1 Files Containing "azgaar" or "Azgaar" in Path/Name

#### **Manager Scripts:**
1. **`scripts/managers/AzgaarIntegrator.gd`** (137 lines)
   - Purpose: Copies bundled Azgaar files from `res://tools/azgaar/` to `user://azgaar/`
   - Key Methods: `copy_azgaar_to_user()`, `write_options()`, `get_azgaar_url()`, `get_azgaar_http_url()`
   - Autoload: `AzgaarIntegrator` (from project.godot:35)

2. **`scripts/managers/AzgaarServer.gd`** (318 lines)
   - Purpose: Embedded HTTP server serving Azgaar files from `user://azgaar/`
   - Key Features: TCP server (port 8080), CORS headers, MIME type handling
   - Autoload: `AzgaarServer` (from project.godot:36)
   - Status: Enabled (`DEBUG_DISABLE_AZGAAR = false`)

3. **`scripts/managers/AzgaarDataConverter.gd`** (219 lines)
   - Purpose: Converts Azgaar fork JSON to Godot Images (heightmap, biome map)
   - Key Methods: `convert_to_heightmap()`, `convert_to_biome_map()`, `extract_biomes()`, `extract_rivers()`
   - Uses: Spatial hashing for efficient rasterization (32×32 buckets)
   - Class: `AzgaarDataConverter` (RefCounted)

4. **`scripts/ui/WorldBuilderAzgaar.gd`** (Found via grep, exact location TBD)
   - Status: **Legacy/Deprecated** - contains `DEBUG_DISABLE_AZGAAR = true`
   - Purpose: Old WebView controller for iframe-based Azgaar embedding
   - Replacement: `WorldBuilderWebController.gd` (fork-based)

#### **JavaScript Files in `assets/ui_web/js/azgaar/`:**
1. **`azgaar-genesis.esm.js`** (149KB) - **Primary fork module (ESM)**
   - Location: `assets/ui_web/js/azgaar/azgaar-genesis.esm.js`
   - Purpose: Modular Azgaar fork with headless generation API
   - Exports: `initGenerator`, `loadOptions`, `generateMap`, `getMapData`, `renderPreview`, `renderPreviewSVG`
   - Used by: `world_builder_v2.html` (fork template)

2. **`azgaar-genesis.esm-20251230.js`** (132KB) - Backup/previous version
3. **`azgaar-genesis.umd.js`** (116KB) - UMD bundle variant
4. **`azgaar-genesis.min.js`** (53KB) - Minified version

#### **HTML Templates:**
1. **`assets/ui_web/templates/world_builder_v2.html`** (803 lines) - **Active (Fork Mode)**
   - Purpose: Fork-based world builder with Alpine.js wizard
   - Key Features:
     - Direct ESM import: `import { initGenerator, generateMap, getMapData, renderPreviewSVG } from '../js/azgaar/azgaar-genesis.esm.js'`
     - Canvas initialization: `<canvas id="azgaar-canvas">`
     - SVG preview container: `<div id="map-preview" class="svg-preview">`
     - IPC bridge: Uses `window.GodotBridge.postMessage()` for communication
     - Alpine.js integration: `x-data="worldBuilder"` reactive component
   - Import Structure:
     ```javascript
     import Delaunator from 'https://cdn.jsdelivr.net/npm/delaunator@5.0.1/+esm';
     import { initGenerator, loadOptions, generateMap, getMapData, renderPreview, renderPreviewSVG } from '../js/azgaar/azgaar-genesis.esm.js';
     ```
   - Canvas Setup: Lines 233-258 (resize, validation, initialization)
   - Data Validation: Lines 620-689 (`validateMapData()` function with deep integrity checks)
   - Data Repair: Lines 695-793 (`repairMapData()` function for cells.v reconstruction)

2. **`assets/ui_web/templates/world_builder.html`** (210 lines) - **Legacy (Iframe Mode)**
   - Purpose: Iframe-based embedding of full Azgaar UI
   - Key Features:
     - Iframe source: `http://127.0.0.1:8080/index.html` (AzgaarServer)
     - PostMessage listeners for generation events
     - Legacy Alpine.js wizard (no fork integration)
   - Status: **Deprecated** - kept for reference but not actively used

#### **Configuration Files:**
1. **`data/config/azgaar_step_parameters.json`**
   - Purpose: Step-by-step parameter definitions for world builder wizard
   - Loaded by: `WorldBuilderWebController.gd` (line 42)
   - Structure: `{ "steps": [{ "title": "...", "parameters": [...] }] }`

2. **`data/config/archetype_azgaar_presets.json`**
   - Purpose: Preset parameter combinations for fantasy archetypes
   - Loaded by: `WorldBuilderWebController.gd` (line 156)
   - Used for: High Fantasy, Low Fantasy, Dark Fantasy, etc.

3. **`data/config/azgaar_config.json`** (exact contents TBD)
4. **`data/config/azgaar_parameter_mapping.json`** (exact contents TBD)

#### **Bundled Azgaar Assets:**
- **`tools/azgaar/`** (1302 files total)
  - Original Azgaar Fantasy Map Generator bundle
  - Served via HTTP by `AzgaarServer.gd` on `http://127.0.0.1:8080/`
  - Copied to `user://azgaar/` by `AzgaarIntegrator.gd` on startup
  - Structure: `index.html`, `main.js`, `modules/`, `libs/`, `styles/`, `images/`, etc.

### 2.2 Key Script Imports and Canvas Setup (world_builder_v2.html)

**Critical Setup Code (Lines 166-313):**
```javascript
// Import Delaunator (peer dependency) from CDN
import Delaunator from 'https://cdn.jsdelivr.net/npm/delaunator@5.0.1/+esm';

// Import Azgaar Genesis library (updated bundle with SVG rendering)
import { 
    initGenerator, 
    loadOptions, 
    generateMap, 
    getMapData, 
    renderPreview,
    renderPreviewSVG 
} from '../js/azgaar/azgaar-genesis.esm.js';

// Initialize generator with canvas for preview rendering
const canvas = document.getElementById('azgaar-canvas');
initGenerator({ canvas: canvas });

// Store generator functions globally for Alpine.js access
window.AzgaarGenesis = {
    Delaunator,
    loadOptions,
    generateMap,
    getMapData,
    renderPreview,
    renderPreviewSVG,
    initialized: true
};
```

**Canvas Initialization (Lines 233-258):**
- Resizes canvas to container dimensions
- Validates `canvas.getContext` availability
- Sets up resize event listener
- Logs canvas state for debugging

**IPC Communication (Lines 308-325):**
```javascript
// Notify Godot that fork is ready via IPC
if (window.GodotBridge && window.GodotBridge.postMessage) {
    window.GodotBridge.postMessage('fork_ready', {});
}

// Listen for IPC messages from Godot
if (window.GodotBridge && window.GodotBridge.onMessage) {
    window.GodotBridge.onMessage((message) => {
        if (message.type === 'generate_map') {
            handleGenerateMap(message.options || {});
        }
    });
}
```

---

## 3. WebView GUI Status

### 3.1 Scenes Using WebView Nodes

#### **Active WebView Scenes:**
1. **`scenes/ui/WorldBuilderUI.tscn`**
   - Controller: `WorldBuilderWebController.gd`
   - Template: `world_builder_v2.html` (fork mode, default)
   - Purpose: Full world builder wizard with step-by-step parameters

2. **`scenes/MainMenuWeb.tscn`**
   - Template: TBD (likely main menu HTML)
   - Purpose: Main menu with WebView-based UI

3. **`scenes/ui/ProgressDialogWeb.tscn`**
   - Template: TBD
   - Purpose: Progress dialog overlay via WebView

#### **Legacy Control-Based UI:**
- **`scenes/ui/WorldBuilderUI.tscn`** (if exists) - May contain old Control node hierarchy
- **`themes/bg3_theme.tres`** - Legacy Godot theme (deprecated per rules, may still be referenced)

### 3.2 Migration Status

#### ✅ **Fully Migrated to WebView + HTML/Alpine:**
- World Builder UI (`WorldBuilderWebController.gd` + `world_builder_v2.html`)
  - Uses Alpine.js for reactivity
  - Fork-based headless generation (no iframe)
  - SVG preview rendering (primary method)
  - Canvas fallback (deprecated, disabled)

#### ⚠️ **Partially Migrated:**
- Main Menu (`MainMenuWeb.tscn`) - WebView exists but template structure unknown
- Progress Dialog (`ProgressDialogWeb.tscn`) - WebView exists but template structure unknown

#### ❌ **Still Using Godot Control (if any):**
- Potential legacy components in `scenes/ui/components/` (SkyrimSlider.tscn found)
- Debug overlays may use native Godot UI

### 3.3 Legacy Theme Status

- **`themes/bg3_theme.tres`** - Exists but deprecated per rules
- **`themes/bg3_theme_backup.tres`** - Backup copy exists
- Theme colors are injected via JavaScript into CSS variables (see `WorldBuilderWebController.gd:267-331`)
  - Extracted colors: `bg_dark`, `font_gold`, `font_hover_gold`, `bg_panel`, etc.
  - Injected as CSS custom properties for responsive layout

---

## 4. Procedural Generation Pipeline

### 4.1 Key Scripts

#### **Core Generation Scripts:**
1. **`core/world_generation/WorldGenerator.gd`** (48 lines) - **DEPRECATED STUB**
   - Status: All methods return stubs/warnings
   - Comment: "old generator removed for Azgaar integration"
   - Signals: `generation_complete`, `progress_update` (not used)

2. **`core/world_generation/Terrain3DManager.gd`** (212 lines) - **ACTIVE**
   - Purpose: Manages Terrain3D terrain generation from heightmaps
   - Key Methods:
     - `generate_from_heightmap(heightmap_image: Image, min_height, max_height, terrain_position)`
     - `generate_from_noise(seed, frequency, min_height, max_height)`
     - `create_terrain()`, `configure_terrain()`
   - Import Format: `terrain.data.import_images([heightmap, null, null], offset, 1.0, height_range)`
   - Requires: `Image.FORMAT_RF` (single-channel float, 0.0-1.0 normalized)

3. **`scripts/managers/AzgaarDataConverter.gd`** (219 lines) - **ACTIVE**
   - Purpose: Converts Azgaar fork JSON to Godot Images
   - Key Methods:
     - `convert_to_heightmap(json_data: Dictionary) -> Image`
     - `convert_to_biome_map(json_data: Dictionary) -> Image`
     - `extract_biomes(json_data: Dictionary) -> Dictionary`
     - `extract_rivers(json_data: Dictionary) -> Array`
   - Rasterization: Spatial hashing (32×32 buckets) for Voronoi-to-grid conversion
   - Normalization: Water <20 → 0.0, Land 20-100 → 0.0-1.0

### 4.2 Azgaar Data Flow into Terrain3D

#### **Current Pipeline:**
```
1. Fork Generation (JavaScript)
   ├─ world_builder_v2.html: handleGenerateMap()
   ├─ azgaar-genesis.esm.js: generateMap(Delaunator)
   └─ azgaar-genesis.esm.js: getMapData() → JSON Dictionary

2. IPC Transfer (Godot ↔ JS)
   ├─ JavaScript: window.GodotBridge.postMessage('map_generated', { data: json })
   └─ GDScript: WorldBuilderWebController._handle_map_generated(data)

3. JSON Parsing (GDScript)
   ├─ WorldBuilderWebController._handle_map_generated()
   ├─ Extracts: map_data Dictionary from IPC message
   └─ Validates: Top-level keys (pack, grid, options, seed)

4. Heightmap Conversion (GDScript)
   ├─ AzgaarDataConverter.convert_to_heightmap(json_data)
   ├─ Extracts: grid.cells.h (heights), grid.points (positions)
   ├─ Rasterizes: Voronoi cells → regular grid (spatial hashing)
   └─ Outputs: Image.FORMAT_RF (normalized 0.0-1.0)

5. Terrain3D Import (GDScript)
   ├─ Terrain3DManager.generate_from_heightmap(heightmap_img, min_h, max_h)
   ├─ terrain.data.import_images([heightmap, null, null], offset, 1.0, range)
   └─ terrain.update_maps(), terrain.update_collision()

6. Preview Rendering (JavaScript - parallel to conversion)
   ├─ world_builder_v2.html: renderPreviewSVG(svgOptions)
   ├─ SVG generated from pack.cells.v (vertex arrays)
   └─ Displayed in <div id="map-preview"> via Alpine.js (x-html binding)
```

#### **Data Structure Mapping:**

**Fork JSON Structure (from getMapData()):**
```javascript
{
  "options": {
    "mapWidth": 1024,
    "mapHeight": 768,
    "seed": "12345",
    ...
  },
  "grid": {
    "cells": {
      "h": [20, 45, 80, ...],  // Heights (0-100, water <20)
      "i": [0, 1, 2, ...]       // Cell indices
    },
    "points": [[x, y], [x, y], ...]  // Cell center positions
  },
  "pack": {
    "cells": {
      "v": [[...], [...], ...],      // Vertex arrays per cell (CRITICAL for SVG)
      "i": [0, 1, 2, ...],           // Cell indices
      "biome": [0, 1, 2, ...],       // Biome indices
      "state": [0, 1, 2, ...],       // State indices
      "c": [0, 1, 2, ...]            // Coast flags
    },
    "vertices": {
      "c": {...},                    // Vertex coordinates
      "p": [...]                     // Vertex positions
    },
    "biomes": ["Ocean", "Tundra", ...],
    "states": [...],
    "burgs": [...],
    "rivers": [...]
  },
  "seed": "12345"
}
```

**GDScript Dictionary Access:**
```gdscript
var options: Dictionary = json_data.get("options", {})
var grid: Dictionary = json_data.get("grid", {})
var pack: Dictionary = json_data.get("pack", {})

var heights: Array = grid.get("cells", {}).get("h", [])
var points: Array = grid.get("points", [])

var cells_v: Array = pack.get("cells", {}).get("v", [])
var cell_biomes: Array = pack.get("cells", {}).get("biome", [])
```

### 4.3 Custom JSON Parsing and Transformation

#### **Heightmap Rasterization (AzgaarDataConverter.gd:21-89):**
- **Input:** Voronoi cell data (irregular polygons with center points)
- **Output:** Regular grid Image (FORMAT_RF, normalized 0.0-1.0)
- **Algorithm:**
  1. Build spatial hash: 32×32 buckets mapping grid regions to cell IDs
  2. For each pixel (px, py):
     - Find bucket coordinates (bx, by)
     - Collect candidate cells from 3×3 bucket neighborhood
     - Find nearest cell by Euclidean distance
     - Normalize height: water (<20) → 0.0, land (20-100) → 0.0-1.0
  3. Set pixel color: `Color(norm, 0.0, 0.0, 1.0)` (red channel = height)

#### **Biome Map Rasterization (AzgaarDataConverter.gd:137-218):**
- Similar algorithm to heightmap but uses biome indices instead of heights
- Output: `Image.FORMAT_R8` with biome indices normalized to 0-1 range
- Used for: Terrain texture/material selection (future feature)

#### **Data Validation (world_builder_v2.html:620-689):**
- **Purpose:** Validate map data structure before SVG rendering
- **Checks:**
  - `pack.cells` existence and structure
  - `cells.v` array length matches `cells.i.length`
  - `cells.v` entries are not `undefined` (critical for SVG rendering)
  - `cells.biome`, `cells.state` length consistency
  - `pack.vertices` structure for isolines

#### **Data Repair (world_builder_v2.html:695-793):**
- **Purpose:** Attempt to fix common data structure issues
- **Repairs:**
  - Extend/trim `cells.v` to match expected length
  - Fill `undefined` entries in `cells.v` with empty arrays
  - Extend `cells.c`, `cells.biome`, `cells.state` if length mismatches
- **Note:** Repair is a workaround - root cause should be fixed in Voronoi constructor

---

## 5. Known Integration Pain Points

### 5.1 Outdated Azgaar Bundle Structure

#### **Issue: Monolithic Bundle (`tools/azgaar/`)**
- **Problem:** Original Azgaar FMG is a monolithic application (1302 files)
  - Contains full UI, dependencies (jQuery, Three.js, TinyMCE, etc.)
  - Served via HTTP server (AzgaarServer.gd) on port 8080
  - Not designed for headless/modular integration
  
- **Impact:**
  - Unnecessary dependencies loaded (UI components, editors, etc.)
  - Large bundle size (600+ JS files, 300+ SVG files)
  - Iframe embedding required for full UI (performance overhead)
  - Hard to extract just generation logic

#### **Issue: Duplicate Fork (`tools/azgaar-fork/`)**
- **Problem:** Fork bundle exists but appears unused
  - Similar structure to `tools/azgaar/` (same files, different location)
  - Not referenced in codebase (grep found no references)
  - May be outdated or test version

#### **Solution Path:**
- Use modular ESM fork (`assets/ui_web/js/azgaar/azgaar-genesis.esm.js`) instead of bundle
- **Status:** ✅ Partially implemented (fork template uses ESM, but bundle still served)

### 5.2 Hard-Coded Paths and Assumptions

#### **Hard-Coded Paths:**
1. **AzgaarIntegrator.gd:9-10:**
   ```gdscript
   const AZGAAR_BUNDLE_PATH: String = "res://tools/azgaar/"
   const AZGAAR_USER_PATH: String = "user://azgaar/"
   ```
   - Fixed paths assume bundle location

2. **AzgaarServer.gd:11:**
   ```gdscript
   const AZGAAR_DIR: String = "user://azgaar"
   ```
   - Server directory hard-coded

3. **world_builder.html:47:**
   ```html
   <iframe id="azgaar-iframe" src="http://127.0.0.1:8080/index.html" ...>
   ```
   - Hard-coded HTTP URL (legacy template)

4. **WorldBuilderWebController.gd:80:**
   ```gdscript
   var html_url: String = "res://assets/ui_web/templates/world_builder_v2.html"
   ```
   - Template path hard-coded (acceptable)

#### **Assumptions About Old API:**
1. **world_builder.html (Legacy):**
   - Assumes `iframe.contentWindow.azgaar.generate()` exists
   - Assumes `azgaar.options` object structure
   - Assumes postMessage events from iframe (`generation_complete`, `generation_failed`)

2. **AzgaarDataConverter.gd:**
   - Assumes fork JSON uses `options.mapWidth` (not `settings.mapWidth`)
   - Assumes `grid.cells.h` array exists and matches `points` length
   - Assumes height scale 0-100 (water <20, land 20-100)

### 5.3 Missing or Incomplete Rendering Layers

#### **Issue: "Dot Painting" Rendering**
- **Symptom:** Maps render as raw Voronoi points without full layers (biomes, rivers, borders, states)
- **Root Cause:** `pack.cells.v` (vertex arrays) missing or incomplete
  - Voronoi constructor may not populate `cells.v` correctly during edge traversal
  - Validation/repair functions attempt to fix but may not address root cause
  
- **Evidence from Audits:**
  - `audit/azgaar_dot_painting_investigation_audit_2025-01-01.md` documents issue
  - Multiple repair attempts in `world_builder_v2.html:695-793`
  - Validation warnings in `world_builder_v2.html:620-689`

- **Workaround:** Data repair function fills undefined entries with empty arrays
- **Impact:** SVG rendering may fail or produce incomplete maps

#### **Issue: Canvas Rendering Unreliable in WebView**
- **Problem:** Canvas preview (`canvas.toDataURL()`) disabled in fork template
  - `ENABLE_CANVAS_FALLBACK = false` (line 512)
  - Comment: "Canvas is unreliable in Godot WebView - deprioritize it"
  
- **Impact:** SVG is now the only preview method (good, but less flexible)

#### **Issue: Layer Enablement Before SVG Export**
- **Problem:** `_enable_all_layers_before_svg()` (WorldBuilderWebController.gd:1945-1991)
  - Attempts to enable biomes, states, labels, borders, religions, cultures
  - Uses `turnOn()` function (assumes Azgaar global functions exist)
  - Fork may not have these functions (headless mode)
  
- **Impact:** SVG may render with layers disabled (incomplete visualization)

### 5.4 Performance and Memory Issues

#### **Console Message Overflow:**
- **Problem:** WebView console messages can overflow with large arrays
  - `WorldBuilderWebController.gd:1218-1279` filters verbose messages
  - Array dumps (100+ items) are suppressed unless important prefix
  - Safety override in `world_builder_v2.html:172-217` truncates large arrays

#### **Generation Timeout:**
- **Problem:** Generation may hang if IPC messages fail
  - `WorldBuilderWebController.gd:1063-1087` implements 60-second timeout
  - Fallback resets UI state if completion not detected
  
#### **Memory Usage:**
- **Potential Issue:** Large JSON dictionaries passed via IPC
  - `map_generated` IPC message includes full `data` Dictionary (may be 10+ MB)
  - Saved to `user://debug/azgaar_sample_map.json` for analysis
  - No streaming/chunking for large maps

#### **Spatial Hashing Performance:**
- **Algorithm:** 32×32 buckets for Voronoi rasterization
  - 3×3 bucket search per pixel = 9 bucket checks
  - Nearest-neighbor search within candidates = O(n) per pixel
  - For 1024×768 map = ~786K pixel iterations
  - **Optimization Opportunity:** Use k-d tree or quadtree for faster lookups

---

## 6. Recommended Integration Plan for New Azgaar Fork

### 6.1 Files to Delete/Replace

#### **Delete (Obsolete):**
1. **`tools/azgaar/`** (entire directory) - Monolithic bundle no longer needed
2. **`tools/azgaar-fork/`** (entire directory) - Unused duplicate
3. **`scripts/ui/WorldBuilderAzgaar.gd`** - Legacy iframe-based controller
4. **`assets/ui_web/templates/world_builder.html`** - Legacy iframe template (keep as reference if needed)

#### **Replace:**
1. **`assets/ui_web/js/azgaar/azgaar-genesis.esm.js`** - Replace with new fork version
   - New version should fix Voronoi constructor (`cells.v` population)
   - Ensure `getMapData()` returns complete structure
   - Verify SVG rendering (`renderPreviewSVG`) works with full layers

2. **`assets/ui_web/js/azgaar/azgaar-genesis.esm-20251230.js`** - Remove backup (or archive)

### 6.2 New Files to Add

#### **Required:**
1. **`assets/ui_web/js/azgaar/azgaar-genesis.esm.js`** (new version)
   - Modular ESM export with fixed Voronoi constructor
   - Complete `pack.cells.v` population
   - Full layer rendering (biomes, states, borders, rivers, labels)
   - Version identifier: `azgaar-genesis@v2.0.0` (or similar)

2. **`assets/ui_web/js/alpine-integration.js`** (if not exists)
   - Shared Alpine.js component for Azgaar integration
   - Reusable IPC message handlers
   - Common validation/repair functions

3. **`assets/ui_web/js/azgaar/alpine-integration.js`** (optional)
   - Alpine.js wrapper for Azgaar fork functions
   - Reactive state management for generation progress
   - Preview SVG/Canvas toggle component

#### **Optional:**
1. **`data/config/azgaar_fork_config.json`**
   - Fork-specific configuration (version, API endpoints, feature flags)
   - Default layer visibility settings
   - Render quality presets

2. **`docs/azgaar_fork_api.md`**
   - Complete API documentation for fork functions
   - Data structure specifications
   - Integration examples

### 6.3 Required GDScript Changes

#### **WorldBuilderWebController.gd:**
1. **Remove iframe-based generation code:**
   - Delete `_generate_via_iframe()` (line 751-796)
   - Delete `_sync_params_to_azgaar_iframe()` (line 855-953)
   - Delete `_generate_initial_default_map()` (line 956-1035)
   - Delete `azgaar_readiness_timer` polling logic (lines 23-24, 414-472)

2. **Update fork API calls:**
   - Ensure `_convert_params_to_fork_options()` maps all parameters correctly
   - Verify `handleGenerateMap()` function signature matches new fork
   - Update IPC message handling for new fork events

3. **Simplify layer enablement:**
   - Remove `_enable_all_layers_before_svg()` (assume fork handles layers)
   - Or: Add fork API call to enable layers via `loadOptions({ layers: { biomes: true, ... } })`

#### **AzgaarDataConverter.gd:**
1. **No changes required** - Conversion logic is fork-agnostic
   - Assumes standard JSON structure (should remain compatible)

2. **Optional enhancements:**
   - Add `extract_states()` method for political boundaries
   - Add `extract_provinces()` method for administrative regions
   - Add `convert_to_river_map()` for river visualization

#### **AzgaarIntegrator.gd:**
1. **Remove bundle copying:**
   - Delete `copy_azgaar_to_user()` and `_copy_directory_recursive()`
   - Remove `user://azgaar/` directory creation
   - Keep `write_options()` if still needed for legacy compatibility

2. **Update autoload:**
   - Consider removing `AzgaarIntegrator` autoload (no longer needed)
   - Or: Repurpose for fork configuration management

#### **AzgaarServer.gd:**
1. **Remove HTTP server:**
   - Delete entire server implementation (no longer needed for fork)
   - Remove autoload from `project.godot`
   - Or: Keep as optional fallback for legacy templates

2. **Alternative: Repurpose for asset serving**
   - Serve static assets (images, fonts) if needed
   - Not required for fork (all assets embedded in ESM)

### 6.4 Message Handling Updates

#### **IPC Message Types (Current):**
- `fork_ready` - Fork initialized and ready
- `map_generated` - Map generation complete with JSON data
- `map_generation_failed` - Generation error
- `svg_preview_ready` - SVG preview rendered
- `svg_failed` - SVG rendering failed
- `render_failed` - Generic rendering failure (validation, SVG, canvas)

#### **Required Changes:**
1. **Verify `getMapData()` structure:**
   ```javascript
   // Ensure fork returns:
   {
     options: { mapWidth, mapHeight, seed, ... },
     grid: { cells: { h, i }, points },
     pack: {
       cells: { v, i, biome, state, c },
       vertices: { c, p },
       biomes, states, burgs, rivers, ...
     },
     seed: "..."
   }
   ```

2. **Update validation:**
   - Ensure `validateMapData()` checks all required fields
   - Verify `cells.v` is fully populated (no undefined entries)
   - Check layer data completeness (biomes, states, etc.)

3. **Update repair (if still needed):**
   - Repair logic should be temporary until fork is fixed
   - Consider removing repair if new fork is stable

### 6.5 Suggested Commit Sequence

#### **Phase 1: Preparation (Non-Breaking)**
1. **Commit:** `refactor/genesis: Extract Azgaar fork API interface`
   - Create abstract interface for fork functions
   - Document expected API contract
   - Add type definitions (JSDoc or TypeScript)

2. **Commit:** `docs/genesis: Add Azgaar fork integration guide`
   - Document fork API usage
   - Integration examples
   - Troubleshooting guide

#### **Phase 2: Fork Update (Breaking)**
3. **Commit:** `feat/genesis: Update Azgaar fork to v2.0.0`
   - Replace `azgaar-genesis.esm.js` with new version
   - Update imports in `world_builder_v2.html`
   - Test generation and SVG rendering

4. **Commit:** `fix/genesis: Remove data repair workaround for fixed fork`
   - Remove or simplify `repairMapData()` if fork is fixed
   - Keep validation for safety

#### **Phase 3: Cleanup (Breaking)**
5. **Commit:** `refactor/genesis: Remove legacy Azgaar bundle and iframe code`
   - Delete `tools/azgaar/` and `tools/azgaar-fork/`
   - Remove `AzgaarServer.gd` (or repurpose)
   - Remove `AzgaarIntegrator.gd` bundle copying
   - Remove iframe-based generation code from `WorldBuilderWebController.gd`

6. **Commit:** `refactor/genesis: Simplify Azgaar integration (fork-only)`
   - Remove dual-mode support (fork vs. iframe)
   - Update documentation
   - Clean up unused IPC message handlers

#### **Phase 4: Enhancement (Optional)**
7. **Commit:** `feat/genesis: Add Alpine.js Azgaar integration wrapper`
   - Create reusable Alpine component
   - Standardize IPC message handling
   - Add reactive state management

8. **Commit:** `perf/genesis: Optimize Voronoi rasterization with k-d tree`
   - Replace spatial hashing with k-d tree
   - Benchmark performance improvement
   - Update `AzgaarDataConverter.gd`

---

## Summary

### Current Status: **Hybrid Integration (Fork + Bundle)**
- **Primary:** Fork-based headless generation via ESM module ✅
- **Secondary:** Monolithic bundle served via HTTP (unused but still present) ⚠️
- **Migration:** ~80% complete (fork template active, bundle still exists)

### Critical Issues:
1. **"Dot Painting" Rendering** - `cells.v` incomplete (fork Voronoi constructor bug)
2. **Outdated Bundle** - Monolithic bundle still present but not needed
3. **Legacy Code** - Iframe-based generation code still present (dead code)

### Recommendations Priority:
1. **HIGH:** Update fork to fix Voronoi constructor (`cells.v` population)
2. **HIGH:** Remove legacy bundle and iframe code
3. **MEDIUM:** Optimize rasterization performance (k-d tree)
4. **LOW:** Add Alpine.js wrapper for reusability

### Integration Health: **Good (with workarounds)**
- Fork integration is functional but relies on data repair workarounds
- SVG rendering works but may be incomplete due to missing layers
- Terrain3D conversion pipeline is solid and fork-agnostic
- Performance is acceptable but has optimization opportunities

---

**Audit Complete**  
**Generated:** 2026-01-01  
**Auditor:** AI Assistant (Auto)  
**Next Steps:** Review recommendations and prioritize fork update
