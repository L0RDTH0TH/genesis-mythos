# Map Rendering Preview Investigation Report
**Date:** 2025-12-29  
**Investigator:** AI Assistant  
**Scope:** Investigation of 2D preview map rendering in World Builder using Azgaar fork integration

## Executive Summary

This investigation examined how the project currently handles rendering visual 2D preview maps in the World Builder system using the Azgaar fork integration. The system uses a headless Azgaar fork (azgaar-genesis.esm.js) with a modular API for map generation, then attempts to render previews to an HTML5 canvas element for display in the WebView.

**Key Finding:** The fork's `renderPreview()` function only renders a basic heightmap-style visualization (oceans, lakes, landmass) - it does NOT render full visual maps with cultures, borders, states, or other detailed features. Additionally, there is a bug in the JavaScript code where `renderPreview(canvas)` is called with a canvas parameter, but the function signature expects no parameters (it uses `state.canvas` set during initialization).

---

## Current Implementation Architecture

### 1. System Flow Overview

```
WorldBuilderWebController.gd (GDScript)
    ↓
    Loads: res://assets/ui_web/templates/world_builder_v2.html
    ↓
    HTML loads: azgaar-genesis.esm.js (fork module)
    ↓
    Generation: generateMap() → getMapData() → JSON sent to Godot
    ↓
    Preview: renderPreview() → Canvas rendering → Data URL → Godot → WebView display
```

### 2. Key Components

#### A. GDScript Controller (`scripts/ui/WorldBuilderWebController.gd`)
- **Lines 614-713:** `_generate_via_fork()` - Triggers fork generation via JavaScript execution
- **Lines 1438-1477:** `_handle_map_generated()` - Receives map JSON and preview data URL from WebView
- **Lines 1550-1614:** `_convert_and_preview_heightmap()` - Fallback: converts JSON to heightmap PNG if preview unavailable
- **Lines 1616-1680:** `_send_preview_to_webview()` - Sends preview data URL to WebView for display

#### B. HTML Template (`assets/ui_web/templates/world_builder_v2.html`)
- **Lines 48-49:** Canvas element `<canvas id="azgaar-canvas">` for preview rendering
- **Lines 177-222:** Fork initialization with `initGenerator({ canvas: canvas })`
- **Lines 249-339:** `handleGenerateMap()` function that orchestrates generation and preview
- **Lines 288-304:** Preview rendering logic (contains bug - see Issues section)

#### C. Azgaar Fork Module (`assets/ui_web/js/azgaar/azgaar-genesis.esm.js`)
- **Lines 2866-2877:** `initGenerator()` - Initializes fork with optional canvas
- **Lines 2967-2983:** `renderPreview()` - Renders preview to state.canvas
- **Lines 2708-2727:** `renderMap()` - Core rendering function
  - **Lines 2724:** `drawOceans()` - Fills canvas with ocean color
  - **Lines 2725:** `drawLakes()` - Draws lake features as circles
  - **Lines 2726:** `drawLandmass()` - Fills canvas with land color

---

## Detailed Analysis

### 3. Preview Rendering Implementation

#### A. Fork `renderPreview()` Function
**Location:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:2967-2983`

```javascript
function renderPreview() {
  requireInitialized();
  if (!state.data) {
    throw new NoDataError();
  }
  if (!state.canvas) {
    console.warn("renderPreview() called but no canvas was provided during initialization. Skipping render.");
    return;
  }
  try {
    renderMap(state.canvas, state.data);
  } catch (error) {
    throw new GenerationError(`Rendering failed: ${error.message}`);
  }
}
```

**Key Points:**
- Function takes NO parameters - uses `state.canvas` set during `initGenerator()`
- Calls `renderMap(state.canvas, state.data)` with internal state
- Requires `state.data` to be set (via `generateMap()` → stores result in `state.data`)

#### B. `renderMap()` Function Limitations
**Location:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:2708-2727`

```javascript
function renderMap(canvas, data) {
  // ... validation ...
  ctx.clearRect(0, 0, mapWidth, mapHeight);
  drawOceans(ctx, { grid, pack, options });    // Fills entire canvas with ocean color
  drawLakes(ctx, { grid, pack, options });     // Draws lakes as circles
  drawLandmass(ctx, { grid, pack, options });  // Fills entire canvas with land color
}
```

**Rendering Capabilities:**
- ✅ Oceans: Solid color fill
- ✅ Lakes: Circle-based rendering
- ✅ Landmass: Solid color fill
- ❌ **NO cultures** - Not rendered
- ❌ **NO borders/state boundaries** - Not rendered
- ❌ **NO biomes** - Not rendered
- ❌ **NO rivers** - Not rendered
- ❌ **NO burgs/cities** - Not rendered
- ❌ **NO height variation visualization** - Not rendered

**Conclusion:** The fork's `renderPreview()` only produces a basic heightmap-style visualization (ocean vs. land, with lakes). It does NOT render the full visual map with all the detailed features that users expect.

#### C. Canvas Initialization
**Location:** `assets/ui_web/templates/world_builder_v2.html:176-222`

```javascript
const canvas = document.getElementById('azgaar-canvas');
function resizeCanvas() {
  if (canvas) {
    const container = canvas.parentElement;
    if (container) {
      canvas.width = container.clientWidth;
      canvas.height = container.clientHeight;
    }
  }
}

initGenerator({ canvas: canvas });  // Canvas stored in state.canvas
```

Canvas is properly initialized and stored in fork state.

---

## Issues Identified

### Issue 1: Incorrect `renderPreview()` Call Signature
**Severity:** HIGH  
**Location:** `assets/ui_web/templates/world_builder_v2.html:293`

**Current Code:**
```javascript
window.AzgaarGenesis.renderPreview(canvas);  // ❌ WRONG - function doesn't take parameters
```

**Problem:**
- `renderPreview()` function signature expects **zero parameters**
- It uses `state.canvas` set during `initGenerator()`
- Passing `canvas` as parameter is ignored, but may cause confusion

**Expected Code:**
```javascript
window.AzgaarGenesis.renderPreview();  // ✅ CORRECT - no parameters
```

**Impact:**
- May not cause runtime error (extra parameter likely ignored)
- Could cause confusion during debugging
- Inconsistent with function signature

### Issue 2: Limited Rendering Capabilities
**Severity:** MEDIUM  
**Location:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:2708-2763`

**Problem:**
- Fork's `renderMap()` only renders basic heightmap (oceans, lakes, landmass)
- Does NOT render cultures, borders, states, biomes, rivers, burgs, etc.
- Users expecting full visual map preview will see only basic land/water visualization

**Evidence:**
- `drawOceans()`: Single solid color fill
- `drawLakes()`: Circle-based rendering only
- `drawLandmass()`: Single solid color fill (overwrites oceans)
- No functions for cultures, borders, states, biomes, rivers, burgs

**Impact:**
- Preview images are basic heightmaps, not full visual maps
- User expectations may not be met
- May need alternative rendering approach for full visual preview

### Issue 3: Canvas Size Mismatch
**Severity:** LOW  
**Location:** `assets/ui_web/templates/world_builder_v2.html:176-186` and `renderMap()` function

**Problem:**
- Canvas is resized to container dimensions (responsive to WebView size)
- `renderMap()` sets `canvas.width = mapWidth` and `canvas.height = mapHeight` from options
- Canvas may be resized by CSS (`style.width/height`) but internal size changed by renderMap
- This could cause rendering scaling issues

**Evidence:**
- `resizeCanvas()` sets canvas to container dimensions
- `renderMap()` sets canvas to `mapWidth`/`mapHeight` from options
- No coordination between these two sizing methods

**Impact:**
- Potential rendering quality/scaling issues
- May cause preview to appear distorted

### Issue 4: Preview Data URL Generation
**Severity:** LOW  
**Location:** `assets/ui_web/templates/world_builder_v2.html:294`

**Current Code:**
```javascript
previewDataUrl = canvas.toDataURL('image/png');
```

**Potential Issue:**
- If `renderPreview()` fails silently (no canvas), `previewDataUrl` will be empty string
- Empty `previewDataUrl` triggers fallback to heightmap conversion in Godot
- No explicit error handling if `toDataURL()` fails

**Impact:**
- Silent failures may go unnoticed
- Fallback mechanism works, but may mask rendering issues

---

## Data Flow Analysis

### 5. Complete Generation → Preview Flow

```
1. User clicks "Generate Map" in WebView
   ↓
2. world_builder.js: generate() → GodotBridge.postMessage('generate', { params })
   ↓
3. WorldBuilderWebController._handle_generate()
   ↓
4. _generate_via_fork() executes JavaScript:
   - window.handleGenerateMap(fork_options) OR
   - Direct fork API calls: loadOptions() → generateMap() → getMapData()
   ↓
5. handleGenerateMap() in world_builder_v2.html:
   - loadOptions(options)
   - generateMap(Delaunator) → stores result in state.data
   - getMapData() → extracts JSON
   - renderPreview() → renders to canvas (basic heightmap only)
   - canvas.toDataURL() → converts to data URL
   ↓
6. GodotBridge.postMessage('map_generated', { data, seed, previewDataUrl })
   ↓
7. WorldBuilderWebController._handle_map_generated()
   - If previewDataUrl is empty → _convert_and_preview_heightmap() (fallback)
   - If previewDataUrl exists → _send_preview_to_webview(data_url)
   ↓
8. _send_preview_to_webview() executes JavaScript:
   - window.worldBuilderInstance.previewImageUrl = data_url
   - Alpine.js reactively updates UI to show preview image
```

### 6. Fallback Mechanism

If `previewDataUrl` is empty or unavailable:
- Godot uses `AzgaarDataConverter.convert_to_heightmap()` to convert JSON to heightmap Image
- Heightmap is saved as PNG to `user://debug/heightmap_preview.png`
- PNG is loaded, converted to base64 data URL, and sent to WebView
- Same display mechanism (Alpine.js reactive update)

**Fallback Quality:**
- Also produces basic heightmap (no cultures, borders, etc.)
- Uses nearest-neighbor interpolation from Voronoi cell data
- Produces grayscale height visualization

---

## Code Locations Reference

### Key Files
1. **GDScript Controller:**
   - `scripts/ui/WorldBuilderWebController.gd` (1681 lines)
   - Primary handler for WebView communication and preview management

2. **HTML Template:**
   - `assets/ui_web/templates/world_builder_v2.html` (348 lines)
   - Contains canvas element, fork initialization, and handleGenerateMap()

3. **Azgaar Fork Module:**
   - `assets/ui_web/js/azgaar/azgaar-genesis.esm.js` (3022 lines)
   - Contains renderPreview(), renderMap(), drawOceans(), drawLakes(), drawLandmass()

4. **Alpine.js Controller:**
   - `assets/ui_web/js/world_builder.js` (919 lines)
   - Handles UI state and IPC communication

5. **Data Converter (Fallback):**
   - `scripts/managers/AzgaarDataConverter.gd` (219 lines)
   - Converts JSON to heightmap Image for fallback preview

---

## Recommendations

### Short-Term Fixes (Quick Wins)

1. **Fix renderPreview() Call Signature**
   - **File:** `assets/ui_web/templates/world_builder_v2.html:293`
   - **Change:** `window.AzgaarGenesis.renderPreview(canvas)` → `window.AzgaarGenesis.renderPreview()`
   - **Impact:** Removes incorrect parameter, aligns with function signature

2. **Add Error Handling for Preview Rendering**
   - **File:** `assets/ui_web/templates/world_builder_v2.html:288-304`
   - **Action:** Explicitly check if canvas exists and if renderPreview succeeded before calling toDataURL()
   - **Impact:** Better error visibility, prevents silent failures

3. **Document Rendering Limitations**
   - **File:** README or inline comments
   - **Action:** Document that renderPreview() only renders basic heightmap, not full visual map
   - **Impact:** Sets user/developer expectations correctly

### Medium-Term Improvements

4. **Enhance renderMap() Function**
   - **File:** Fork module (would require fork modification)
   - **Action:** Extend renderMap() to include cultures, borders, states, biomes, rivers, burgs
   - **Impact:** Full visual map preview, matches user expectations
   - **Challenge:** Requires understanding fork internals and adding rendering logic for each feature type
   - **Alternative:** Use full Azgaar (non-fork) in iframe mode for full visual preview (but requires HTTP server)

5. **Canvas Size Coordination**
   - **File:** `assets/ui_web/templates/world_builder_v2.html`
   - **Action:** Ensure canvas internal size matches map dimensions before rendering
   - **Impact:** Better rendering quality, no scaling issues

6. **Preview Quality Options**
   - **Action:** Allow users to choose preview detail level (basic heightmap vs. full visual)
   - **Impact:** Performance vs. quality trade-off

### Long-Term Considerations

7. **Alternative Preview Rendering**
   - **Option A:** Enhance fork's renderMap() with full visual rendering
   - **Option B:** Use full Azgaar in iframe mode for preview (requires HTTP server, but provides full visual map)
   - **Option C:** Implement custom rendering in Godot (using AzgaarDataConverter + custom visualization logic)
   - **Impact:** Full visual map preview with all features

8. **Performance Optimization**
   - **Action:** Cache rendered previews, use WebGL for faster rendering if possible
   - **Impact:** Faster preview generation, better user experience

---

## Testing Recommendations

1. **Test renderPreview() Call Fix**
   - Verify that removing canvas parameter doesn't break rendering
   - Confirm canvas still renders correctly using state.canvas

2. **Test Preview Data URL Generation**
   - Verify previewDataUrl is populated when renderPreview succeeds
   - Verify fallback mechanism when previewDataUrl is empty
   - Test with various map sizes

3. **Test Canvas Sizing**
   - Verify canvas renders correctly at different WebView sizes
   - Test with various map dimensions (mapWidth/mapHeight)
   - Check for scaling/distortion issues

4. **Test Error Handling**
   - Test behavior when canvas is null/missing
   - Test behavior when renderPreview throws error
   - Test behavior when toDataURL() fails

5. **Test Fallback Mechanism**
   - Verify heightmap conversion works when preview unavailable
   - Compare quality of fork preview vs. Godot fallback preview

---

## Conclusion

The current implementation successfully generates maps and provides basic heightmap-style previews, but has limitations:

1. **Preview Quality:** Only basic heightmap (ocean/land/lakes), not full visual map with cultures, borders, states, etc.
2. **Bug:** Incorrect `renderPreview(canvas)` call signature (should be `renderPreview()`)
3. **Fallback Works:** Godot-side heightmap conversion provides similar quality when fork preview unavailable

**Root Cause of Limited Preview:**
The Azgaar fork's `renderPreview()` function is intentionally minimal - it only renders basic heightmap visualization. Full visual maps with cultures, borders, states, biomes, rivers, and burgs require additional rendering logic that is not implemented in the fork.

**Next Steps:**
1. Fix the `renderPreview()` call signature bug (quick fix)
2. Document limitations (set expectations)
3. Evaluate options for full visual preview (enhance fork vs. alternative approach)

---

## Appendix: Relevant Code Snippets

### renderPreview() Function Signature
```javascript
// assets/ui_web/js/azgaar/azgaar-genesis.esm.js:2967-2983
function renderPreview() {  // ← NO parameters
  requireInitialized();
  if (!state.data) {
    throw new NoDataError();
  }
  if (!state.canvas) {
    console.warn("renderPreview() called but no canvas was provided during initialization. Skipping render.");
    return;
  }
  try {
    renderMap(state.canvas, state.data);  // ← Uses state.canvas, not parameter
  } catch (error) {
    throw new GenerationError(`Rendering failed: ${error.message}`);
  }
}
```

### Incorrect Call Site
```javascript
// assets/ui_web/templates/world_builder_v2.html:293
window.AzgaarGenesis.renderPreview(canvas);  // ← BUG: passes canvas, but function doesn't accept it
```

### renderMap() Rendering Capabilities
```javascript
// assets/ui_web/js/azgaar/azgaar-genesis.esm.js:2708-2727
function renderMap(canvas, data) {
  // ... setup ...
  drawOceans(ctx, { grid, pack, options });    // Solid ocean fill
  drawLakes(ctx, { grid, pack, options });     // Circle-based lakes
  drawLandmass(ctx, { grid, pack, options });  // Solid land fill
  // ← NO cultures, borders, states, biomes, rivers, burgs, etc.
}
```

---

**End of Investigation Report**
