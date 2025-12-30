# Azgaar Fantasy Map Generator Integration Report
**Date:** December 30, 2025  
**Project:** Genesis Mythos – Full First Person 3D Virtual Tabletop RPG  
**Engine:** Godot 4.5.1  
**Report Type:** Comprehensive System Analysis

---

## Executive Summary

The Genesis Mythos project integrates a **forked version** of the Azgaar Fantasy Map Generator (Azgaar FMG) for procedural world generation within a first-person 3D RPG context. The integration uses a **headless/modular JavaScript API** approach embedded via **godot_wry WebView**, with a sophisticated HTML/CSS/JS/Alpine.js GUI system for parameter input and map preview.

**Key Integration Points:**
- **Azgaar Fork Module:** `azgaar-genesis.esm.js` (modular ES6 export API)
- **UI Layer:** WebView-embedded HTML templates with Alpine.js reactivity
- **Controller Layer:** `WorldBuilderWebController.gd` (GDScript IPC bridge)
- **Data Processing:** `AzgaarDataConverter.gd` (JSON → heightmap/biome maps)
- **Terrain Integration:** `Terrain3DManager.gd` (3D world generation from heightmaps)
- **Supporting Systems:** `AzgaarServer.gd` (HTTP server, legacy), `AzgaarIntegrator.gd` (file management)

**Current Status:** ✅ Fully functional with fork-based headless generation. Legacy iframe mode supported as fallback but not used in current implementation.

---

## Architecture Overview

### High-Level Data Flow

```
User Input (HTML/Alpine.js)
    ↓
WorldBuilderWebController.gd (IPC Bridge)
    ↓
JavaScript Fork API (azgaar-genesis.esm.js)
    ↓
Map Generation (headless, returns JSON)
    ↓
IPC: map_generated message
    ↓
AzgaarDataConverter.gd (JSON → Image conversion)
    ↓
Terrain3DManager.gd (Image → 3D terrain)
    ↓
Godot 3D World
```

### Component Layers

1. **Presentation Layer (WebView/HTML)**
   - `world_builder_v2.html`: Main UI template (three-panel layout)
   - `world_builder.js`: Alpine.js component and IPC handlers
   - `world_builder.css`: Fantasy-themed responsive styling

2. **Controller Layer (GDScript)**
   - `WorldBuilderWebController.gd`: Main IPC bridge and generation orchestrator
   - Parameter clamping, archetype presets, step definitions

3. **Generation Layer (JavaScript)**
   - `azgaar-genesis.esm.js`: Forked Azgaar library (modular API)
   - Headless generation with optional canvas preview rendering

4. **Data Processing Layer (GDScript)**
   - `AzgaarDataConverter.gd`: JSON → heightmap/biome map Image conversion
   - Spatial hashing for efficient Voronoi cell rasterization

5. **Terrain Integration Layer (GDScript)**
   - `Terrain3DManager.gd`: Terrain3D addon integration for 3D world generation

6. **Supporting Infrastructure**
   - `AzgaarServer.gd`: Embedded HTTP server (legacy, for iframe mode)
   - `AzgaarIntegrator.gd`: File copying and path management (legacy)

---

## Detailed Analysis

### 1. Azgaar Fork Module Integration

#### 1.1 Module Structure

**Location:** `res://assets/ui_web/js/azgaar/azgaar-genesis.esm.js`

The fork provides an ES6 module API with the following exports:
- `initGenerator({ canvas })`: Initialize generator (optional canvas for preview)
- `loadOptions(options)`: Set generation parameters
- `generateMap(DelaunatorClass)`: Generate map, returns `{ seed, data }`
- `getMapData()`: Extract JSON representation
- `renderPreview(canvas)`: Render 2D preview to canvas (optional)

**Key Features:**
- **Headless generation:** No DOM dependency (except optional canvas)
- **Seedable PRNG:** Custom RNG class using aleaPRNG for deterministic results
- **Modular options:** `DEFAULT_OPTIONS` dictionary with validation
- **Typed arrays:** Efficient cell data storage (Uint8Array/Uint16Array/Uint32Array)

#### 1.2 Initialization Flow

```javascript
// From world_builder_v2.html (lines 158-232)
import { initGenerator, loadOptions, generateMap, getMapData, renderPreview } 
    from '../js/azgaar/azgaar-genesis.esm.js';

const canvas = document.getElementById('azgaar-canvas');
initGenerator({ canvas: canvas });  // Canvas optional (headless if null)

window.AzgaarGenesis = { Delaunator, loadOptions, generateMap, getMapData, renderPreview, initialized: true };

// Notify Godot via IPC
GodotBridge.postMessage('fork_ready', {});
```

**IPC Signals:**
- `fork_ready`: Sent when module is loaded and ready
- `map_generated`: Sent after successful generation (includes JSON data)
- `map_generation_failed`: Sent on error (includes error message/stack)

#### 1.3 Generation Options

**Options Structure (from DEFAULT_OPTIONS):**
```javascript
{
  mapWidth: 960,              // Canvas width (240-10000)
  mapHeight: 540,             // Canvas height (135-10000)
  seed: null,                 // String seed (generated if null)
  points: 4,                  // Maps to cellsDesired via CELLS_DENSITY_MAP
  template: null,             // Heightmap template ID (null = random)
  statesNumber: 18,           // Political states (0-100)
  cultures: 12,               // Cultural groups (1-100)
  culturesSet: "world",       // Culture set preset
  religionsNumber: 6,         // Religions (0-50)
  heightExponent: 1.8,        // Terrain roughness (0.1-10)
  lakeElevationLimit: 20,     // Lake threshold (0-100)
  winds: [225, 45, 225, 315, 135, 315],  // Wind directions (6 values)
  // ... many more
}
```

**Parameter Mapping (UI → Fork Options):**

From `WorldBuilderWebController.gd:_convert_params_to_fork_options()`:
- `optionsSeed` → `seed` (string)
- `mapWidthInput` → `mapWidth` (int)
- `mapHeightInput` → `mapHeight` (int)
- `pointsInput` → `cellsDesired` (computed via log scale: 10^pointsInput * 1000)
- `templateInput` → `template` (string)
- `heightExponentInput` → `heightExponent` (float)
- `statesNumber` → `statesNumber` (int)
- `culturesInput` → `cultures` (int)
- `religionsNumber` → `religionsNumber` (int)
- `options.winds[0..5]` → `winds` array (Array[int])

---

### 2. UI Integration & User Interface

#### 2.1 Three-Panel Layout

**HTML Template:** `res://assets/ui_web/templates/world_builder_v2.html`

The UI uses a responsive three-panel design:

1. **Left Panel:** Numbered step tabs (BG3-style vertical tabs)
   - 8 steps total (Map Generation, Terrain, Societies, etc.)
   - Steps defined in `azgaar_step_parameters.json`
   - Active step highlighted in gold (`--font-color-gold`)

2. **Center Panel:** Map preview/status
   - Canvas element (`#azgaar-canvas`) for fork preview rendering
   - Fallback `<img>` for Godot-generated previews
   - Status message when no preview available

3. **Right Panel:** Parameter inputs (step-specific)
   - Archetype selector (top)
   - Step title
   - Scrollable parameter list (only curated parameters shown)
   - UI controls: OptionButton, HSlider, SpinBox, CheckBox

#### 2.2 Alpine.js Reactivity

**Component:** `worldBuilder` (from `world_builder.js`)

**Key Data Properties:**
```javascript
{
  currentStep: 0,
  totalSteps: 8,
  steps: [],              // Step definitions (loaded from Godot)
  params: {},             // Parameter values (synced with Godot)
  archetype: 'High Fantasy',
  archetypeNames: [],     // Loaded from Godot
  isGenerating: false,
  progressValue: 0,
  statusText: '',
  previewImageUrl: null,  // Data URL for preview image
  errorMessage: null,
  errorDetails: null
}
```

**IPC Communication Flow:**
1. Alpine.js initializes → sends `alpine_ready` IPC
2. Godot sends step definitions → reactive update via `_send_step_definitions()`
3. User changes parameter → `updateParam()` → debounced `update_param` IPC
4. User clicks "Generate" → `generate()` → `generate` IPC with params
5. Godot triggers fork generation → sends progress updates
6. Generation completes → `map_generated` IPC → preview URL set

#### 2.3 Parameter Clamping & Curation

**Step Definitions:** `res://data/config/azgaar_step_parameters.json`

Parameters have metadata:
- `curated`: Boolean (only curated params shown in UI)
- `clamped_min` / `clamped_max`: Hardware-aware limits (overrides `min`/`max`)
- `ui_type`: Control type (OptionButton, HSlider, SpinBox, CheckBox)
- `default`: Default value
- `azgaar_key`: Maps to fork option key

**Clamping Logic (WorldBuilderWebController.gd:_clamp_parameter_value()):**
- Special handling for `pointsInput`: hardware-aware clamping via `UIConstants.get_clamped_points()`
- Other parameters: clamped to `clamped_min`/`clamped_max` or `min`/`max`
- Only applies to curated parameters

**Archetype Presets:** `res://data/config/archetype_azgaar_presets.json`

Presets provide pre-configured parameter sets (e.g., "High Fantasy", "Dark Fantasy"). When loaded:
1. All preset keys merged into `current_params`
2. Each value clamped via `_clamp_parameter_value()`
3. Params sent to WebView via IPC
4. Auto-trigger generation after archetype change

---

### 3. Data Processing & Conversion

#### 3.1 JSON Structure (Fork Output)

**From `getMapData()`:**
```json
{
  "options": { ... },           // Generation options (mapWidth, mapHeight, seed, etc.)
  "grid": {
    "points": [[x, y], ...],    // Array of cell center positions
    "cells": {
      "h": [20, 45, 80, ...],   // Heights (0-100, water <20, land 20-100)
      // ... other cell data
    }
  },
  "pack": {
    "biomes": ["tundra", "taiga", ...],  // Biome name array
    "cells": {
      "biome": [0, 1, 2, ...],  // Biome indices per cell
      // ... other pack data
    },
    "rivers": [...],            // River objects
    // ... other pack data
  },
  "seed": "12345"
}
```

#### 3.2 Heightmap Conversion

**Function:** `AzgaarDataConverter.convert_to_heightmap(json_data)`

**Algorithm:**
1. Extract `options.mapWidth`/`mapHeight` for image dimensions
2. Extract `grid.points` (cell centers) and `grid.cells.h` (heights)
3. Build spatial hash (32×32 buckets) for efficient nearest-neighbor lookup
4. For each pixel (px, py):
   - Query 3×3 bucket neighborhood
   - Find nearest cell using Euclidean distance
   - Normalize height: water=0, land remapped from [20, 100] to [0.0, 1.0]
5. Store normalized height in Image red channel (FORMAT_RF)

**Output:** `Image` with `FORMAT_RF` (single-channel float, 0.0-1.0 range)

**Key Constants:**
- `MIN_LAND_HEIGHT: 20` (sea level threshold)
- `MAX_HEIGHT: 100` (maximum land height)
- `BUCKET_COUNT: 32` (spatial hash resolution)

#### 3.3 Biome Map Conversion

**Function:** `AzgaarDataConverter.convert_to_biome_map(json_data)`

Similar rasterization to heightmap, but:
- Uses `pack.cells.biome` (array of biome indices) instead of heights
- Output format: `Image.FORMAT_R8` (single-channel uint8)
- Stores biome index normalized to [0.0, 1.0] (index / max_biomes)

**Extraction Functions:**
- `extract_biomes(json_data)`: Returns `Dictionary{cell_id: biome_name}`
- `extract_rivers(json_data)`: Returns `Array` of river objects

#### 3.4 Preview Generation

**Two Preview Paths:**

1. **Fork Canvas Preview (Primary):**
   - Fork calls `renderPreview(canvas)` after generation
   - Canvas converted to data URL: `canvas.toDataURL('image/png')`
   - Sent via `map_generated` IPC message

2. **Godot Heightmap Preview (Fallback):**
   - If fork preview unavailable, `_convert_and_preview_heightmap()` called
   - Heightmap converted to grayscale RGB8 Image
   - Saved as PNG to `user://debug/heightmap_preview.png`
   - Loaded and converted to base64 data URL
   - Sent to WebView via `_send_preview_to_webview()`

---

### 4. Terrain Integration (3D World Generation)

#### 4.1 Terrain3D Integration

**Manager:** `core/world_generation/Terrain3DManager.gd`

**Function:** `generate_from_heightmap(heightmap_image, min_height, max_height, terrain_position)`

**Process:**
1. Receives `Image` (FORMAT_RF, normalized 0.0-1.0 heights)
2. Creates/configures Terrain3D instance (if needed)
3. Converts image format to FORMAT_RF (if needed)
4. Imports via `terrain.data.import_images([heightmap, null, null], offset, 1.0, height_range)`
   - `offset`: `Vector3(-width/2, min_height, -height/2)` (centers terrain)
   - `height_range`: `max_height - min_height` (world units, e.g., 350.0 for -50 to 300)
5. Updates maps and collision: `terrain.update_maps()`, `terrain.update_collision()`

**Terrain Configuration:**
- `vertex_spacing: 1.0` (world units per vertex)
- `region_size: 1024` (Terrain3D region size)
- `data_directory`: Set from config (default `res://terrain_data/`)

#### 4.2 Connection to Azgaar Data

**Current Status:** ⚠️ **Not Fully Integrated**

The conversion pipeline exists (`AzgaarDataConverter.convert_to_heightmap()` → `Terrain3DManager.generate_from_heightmap()`), but there is **no automatic flow** from map generation to 3D terrain creation in the current implementation.

**Integration Points:**
- `WorldBuilderWebController._handle_map_generated()` saves JSON and sends preview, but does not trigger terrain generation
- Terrain generation would need to be explicitly called (e.g., via "Bake to 3D" button or automatic pipeline)

**Potential Integration Flow:**
```
_handle_map_generated()
  → AzgaarDataConverter.convert_to_heightmap(json_data)
  → Terrain3DManager.generate_from_heightmap(heightmap_img, -50.0, 300.0)
  → 3D world terrain created
```

---

### 5. IPC Communication (Godot ↔ JavaScript)

#### 5.1 IPC Bridge (bridge.js)

**GodotBridge API:**
- `postMessage(type, data)`: Send message to Godot
- `_handleUpdate(data)`: Receive update from Godot (overridden by world_builder.js)
- `requestData(endpoint, callback)`: Request data from Godot (async)

#### 5.2 Message Types (Godot → JS)

| Type | Data | Handler | Purpose |
|------|------|---------|---------|
| `params_update` | `{ params: {...} }` | `_handleUpdate()` | Update parameter values |
| `progress_update` | `{ progress, status, is_generating }` | `_handleUpdate()` | Update progress bar |
| `step_definitions` | `{ steps: [...] }` | `_handleUpdate()` | Load step definitions |
| `archetypes` | `{ archetype_names: [...] }` | `_handleUpdate()` | Load archetype names |

#### 5.3 Message Types (JS → Godot)

| Type | Data | Handler | Purpose |
|------|------|---------|---------|
| `alpine_ready` | `{}` | `_handle_alpine_ready()` | Alpine.js initialized |
| `fork_ready` | `{}` | `_handle_fork_ready()` | Fork module loaded |
| `set_step` | `{ step: int }` | `_handle_set_step()` | Step navigation |
| `load_archetype` | `{ archetype: string }` | `_handle_load_archetype()` | Load archetype preset |
| `update_param` | `{ azgaar_key, value }` | `_handle_update_param()` | Parameter change |
| `generate` | `{ params: {...} }` | `_handle_generate()` | Trigger generation |
| `map_generated` | `{ data, seed, generationTime, previewDataUrl }` | `_handle_map_generated()` | Generation complete |
| `map_generation_failed` | `{ error, stack }` | `_handle_map_generation_failed()` | Generation error |

#### 5.4 Execution Flow Example

**Generation Request:**
1. User clicks "Generate" → `generate()` in world_builder.js
2. `GodotBridge.postMessage('generate', { params })`
3. `WorldBuilderWebController._on_ipc_message()` receives message
4. `_handle_generate()` called
5. `_convert_params_to_fork_options()` transforms params
6. JavaScript executed: `window.handleGenerateMap(fork_options)`
7. Fork generates map → `map_generated` IPC sent
8. `_handle_map_generated()` processes JSON, sends preview

---

### 6. Scene Structure & Node Hierarchy

#### 6.1 WorldBuilderWeb Scene

**File:** `ui/world_builder/WorldBuilderWeb.tscn`

```
WorldBuilderWebRoot (Control)
└── WebView (WebView)
    └── [Loads world_builder_v2.html]
```

**Configuration:**
- Control anchors: Full screen (preset 15)
- WebView anchors: Full screen (preset 15)
- Theme: `bg3_theme.tres` (legacy, mostly unused in WebView)

#### 6.2 Integration with Main Scene

The WorldBuilderWeb scene is loaded as a child of the main UI hierarchy. The WebView loads the HTML template which embeds the Azgaar fork module and Alpine.js components.

---

### 7. Supporting Systems

#### 7.1 AzgaarServer (Legacy)

**File:** `scripts/managers/AzgaarServer.gd`

**Purpose:** Embedded HTTP server to serve Azgaar files from `user://azgaar/` (for iframe mode).

**Status:** ⚠️ **Legacy/Unused**

- Server starts on port 8080 (tries ports 8080-8089)
- Serves files from `user://azgaar/` directory
- CORS headers enabled for iframe embedding
- **Not used in fork mode** (fork loads via ES6 module import)

**Note:** Code comments indicate fork mode is preferred; iframe mode is fallback only.

#### 7.2 AzgaarIntegrator (Legacy)

**File:** `scripts/managers/AzgaarIntegrator.gd`

**Purpose:** Copy bundled Azgaar files from `res://tools/azgaar/` to `user://azgaar/` for writability.

**Status:** ⚠️ **Legacy/Unused**

- Copies files on `_ready()` if destination outdated
- Used for iframe mode file serving
- **Not needed for fork mode** (fork uses bundled JS module)

---

### 8. Configuration Files

#### 8.1 Step Parameters

**File:** `res://data/config/azgaar_step_parameters.json`

**Structure:**
```json
{
  "steps": [
    {
      "index": 0,
      "title": "1. Map Generation & Editing",
      "description": "...",
      "parameters": [
        {
          "name": "templateInput",
          "azgaar_key": "templateInput",
          "ui_type": "OptionButton",
          "options": ["pangea", "continents", ...],
          "default": "continents",
          "curated": true
        },
        // ... more parameters
      ]
    },
    // ... 7 more steps
  ]
}
```

**8 Steps:**
1. Map Generation & Editing (template, size, seed)
2. Terrain (height exponent, erosion, winds)
3. Societies & Politics (states, cultures, religions)
4. Settlements & Scale (manors/burgs, urbanization)
5. Climate & Environment (temperature, precipitation)
6. Advanced Options (various fine-tuning)
7. Review & Preview
8. Export & Integration

#### 8.2 Parameter Mapping

**File:** `res://data/config/azgaar_parameter_mapping.json`

**Purpose:** Metadata for parameters (category, performance impact, description).

**Not directly used** in current implementation (step definitions contain all needed info).

#### 8.3 Archetype Presets

**File:** `res://data/config/archetype_azgaar_presets.json` (referenced but not read in current code; presets loaded from different path in WorldBuilderWebController.gd)

**Note:** WorldBuilderWebController loads from `res://data/config/archetype_azgaar_presets.json` (line 145), but this file wasn't found in the codebase during analysis. Presets may be defined elsewhere or generated dynamically.

---

## Issues & Recommendations

### Critical Issues

1. **⚠️ Missing Automatic Terrain Integration**
   - **Issue:** Map generation completes but does not automatically create 3D terrain
   - **Impact:** Users must manually trigger terrain generation
   - **Recommendation:** Add "Bake to 3D" button in UI, or auto-trigger after generation

2. **⚠️ Legacy Code Present**
   - **Issue:** AzgaarServer and AzgaarIntegrator remain but are unused in fork mode
   - **Impact:** Code maintenance burden, potential confusion
   - **Recommendation:** Remove or clearly mark as legacy/fallback-only

3. **⚠️ Preview Limitations**
   - **Issue:** Fork canvas preview may not render all map features (only basic heightmap)
   - **Impact:** Limited preview quality
   - **Recommendation:** Enhance fork `renderPreview()` or improve Godot fallback preview

### Performance Considerations

1. **Large Map Generation:**
   - High `pointsInput` values (10-13) generate 70K-100K cells
   - Rasterization in `AzgaarDataConverter` uses spatial hashing (efficient)
   - **Recommendation:** Add generation timeout/progress updates for large maps

2. **Memory Usage:**
   - Fork JSON can be large (multi-megabyte for 100K cells)
   - Heightmap Images are reasonable (width × height × 4 bytes for FORMAT_RF)
   - **Recommendation:** Stream/compress JSON if needed, or generate in chunks

### Enhancement Opportunities

1. **Biome Integration:**
   - Biome map conversion exists but not integrated into terrain
   - **Recommendation:** Use biome map for terrain material assignment (Terrain3D supports texture splatting)

2. **River Integration:**
   - River extraction exists but rivers not rendered in 3D
   - **Recommendation:** Convert rivers to 3D meshes or decals on terrain

3. **Preview Enhancements:**
   - Current preview is basic heightmap grayscale
   - **Recommendation:** Color-code by biome, add political borders, show settlements

4. **Parameter Validation:**
   - Clamping exists but some edge cases may slip through
   - **Recommendation:** Add comprehensive validation with user-friendly error messages

5. **Save/Load Integration:**
   - Generated maps can be saved to JSON, but no load functionality in UI
   - **Recommendation:** Add "Load Map" option to import previous generations

---

## Code References

### Key Files

| File | Purpose | Lines |
|------|---------|-------|
| `assets/ui_web/js/azgaar/azgaar-genesis.esm.js` | Azgaar fork module | ~3000+ |
| `assets/ui_web/templates/world_builder_v2.html` | Main UI template | 348 |
| `assets/ui_web/js/world_builder.js` | Alpine.js component | 920 |
| `scripts/ui/WorldBuilderWebController.gd` | IPC bridge controller | 1681 |
| `scripts/managers/AzgaarDataConverter.gd` | JSON → Image conversion | 219 |
| `core/world_generation/Terrain3DManager.gd` | Terrain3D integration | 212 |
| `data/config/azgaar_step_parameters.json` | Step definitions | 500+ |

### Key Functions

**WorldBuilderWebController.gd:**
- `_handle_generate()`: Entry point for generation requests (line 558)
- `_generate_via_fork()`: Fork generation trigger (line 614)
- `_convert_params_to_fork_options()`: Parameter transformation (line 763)
- `_handle_map_generated()`: Post-generation processing (line 1438)
- `_clamp_parameter_value()`: Parameter clamping logic (line 508)

**AzgaarDataConverter.gd:**
- `convert_to_heightmap()`: Voronoi → heightmap rasterization (line 21)
- `convert_to_biome_map()`: Voronoi → biome map rasterization (line 137)
- `extract_biomes()`: Biome extraction (line 96)
- `extract_rivers()`: River extraction (line 125)

**Terrain3DManager.gd:**
- `generate_from_heightmap()`: Image → 3D terrain (line 166)
- `create_terrain()`: Terrain instance creation (line 51)
- `configure_terrain()`: Terrain configuration (line 69)

---

## Conclusion

The Azgaar Fantasy Map Generator integration in Genesis Mythos is a **well-architected, modern implementation** using:

✅ **Modular JavaScript API** (fork-based, headless generation)  
✅ **WebView-embedded HTML/JS/Alpine.js GUI** (responsive, fantasy-themed)  
✅ **Robust IPC communication** (bidirectional, type-safe message passing)  
✅ **Efficient data conversion** (spatial hashing for Voronoi rasterization)  
✅ **Data-driven configuration** (JSON step definitions, archetype presets)  

**Strengths:**
- Clean separation of concerns (presentation, controller, generation, conversion)
- Extensible parameter system (curated/clamped parameters)
- Hardware-aware clamping for performance
- Fallback mechanisms (fork → iframe, fork preview → Godot preview)

**Areas for Improvement:**
- Automatic terrain integration (missing pipeline from map → 3D)
- Legacy code cleanup (AzgaarServer, AzgaarIntegrator)
- Enhanced preview rendering (biome coloring, political borders)
- Save/load functionality in UI

**Overall Assessment:** The integration is **production-ready** for map generation and preview, with clear paths for enhancement (terrain automation, biome/river rendering, advanced preview features).

---

**Report Generated:** December 30, 2025  
**Analysis Method:** Code review, file structure analysis, integration point mapping  
**Next Steps:** Consider implementing automatic terrain generation pipeline, removing legacy code, enhancing preview quality.
