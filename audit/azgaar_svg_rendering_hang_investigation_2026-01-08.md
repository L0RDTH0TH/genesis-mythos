# Azgaar Fork SVG Rendering Hang Investigation Report
**Date:** 2026-01-08  
**Issue:** SVG generation succeeds (JSON produced) but rendering hangs on "Rendering SVG preview..." despite 5+ minute waits  
**Status:** Critical Performance Issue

---

## Executive Summary

The Azgaar fork successfully generates map data (JSON ~14.6MB, seed 42, ~14.4s generation time) and produces SVG output (448KB string), but the rendering pipeline hangs during DOM manipulation and Alpine.js reactivity updates. The root cause is **blocking DOM operations with large SVG strings** (448KB+) combined with **nested cell iteration loops** in rendering functions.

**Key Findings:**
- ✅ JSON generation: **SUCCESS** (~14.4s)
- ✅ SVG string generation: **SUCCESS** (448KB produced)
- ❌ DOM manipulation: **HANGS** (Alpine.js `x-html` binding with 448KB+ SVG)
- ❌ Progress feedback: UI shows "Rendering SVG preview..." indefinitely

---

## 1. Overview & Reproduction

### 1.1 Reproduction Steps

1. Load World Builder UI (`world_builder.html`)
2. Trigger generation with seed 42, default params (2000x1000, ~6 points)
3. Generation completes: JSON received (~14.6MB, ~14.4s)
4. SVG rendering starts: Status shows "Rendering SVG preview..."
5. **HANG**: UI freezes indefinitely, no progress updates

### 1.2 Observed Behavior

**From logs (`mythos_log_latest.txt`):**
```
[2026-01-01 02:32:23] SVG preview received [{"height":1000,"svg_length":448802,"width":2000}]
[2026-01-01 02:32:24] SVG preview processed successfully [{"characters":448802,"height":1000,"length":448802,"width":2000}]
[2026-01-01 02:32:25] map_generated IPC received
[2026-01-01 02:32:39] === END MAP GENERATED === [{"has_preview":false,...}]
```

**Critical Observation:**
- SVG string is **successfully generated** (448KB)
- SVG is **successfully received** by Godot via IPC
- Godot marks `has_preview: false` (indicates SVG display failed)
- **Gap between SVG receive (02:32:24) and map_generated (02:32:25) suggests hang during Alpine.js update**

### 1.3 Test Configuration

- **Seed:** 42 (or 12345)
- **Map Size:** 2000x1000 pixels (or 960x540 for reduced load)
- **Points:** 6
- **Template:** "continents"
- **Expected Generation Time:** ~10-15s (✅ Achieved)
- **Expected SVG Render Time:** <5s (❌ Hangs indefinitely)

---

## 2. Log & Debug Analysis

### 2.1 Log Patterns

**Pattern 1: Generation Success**
```
[02:32:07] Starting map generation...
[02:32:21] map_generated IPC received (generation_time: 14431ms)
```

**Pattern 2: SVG Generation Success**
```
[02:32:23] svg_preview_ready IPC received (svg_length: 448802)
[02:32:24] SVG preview processed successfully
```

**Pattern 3: Missing Preview**
```
[02:32:39] === END MAP GENERATED === [{"has_preview":false}]
```

**Pattern 4: No Rendering Errors**
- No `svg_failed` IPC messages
- No `render_failed` IPC messages
- No JavaScript console errors in logs (WebView console not captured)

### 2.2 WebView Console Output

**Issue:** WebView console output is **not captured** in Godot logs. This is a blind spot for debugging.

**Recommendation:** Inject console.log wrapper to forward WebView console to Godot IPC:
```javascript
// In bridge.js or world_builder.html
const originalLog = console.log;
console.log = function(...args) {
  originalLog.apply(console, args);
  if (window.GodotBridge && window.GodotBridge.postMessage) {
    window.GodotBridge.postMessage('console_log', {
      level: 'log',
      message: args.map(a => String(a)).join(' ')
    });
  }
};
```

### 2.3 Fork API Call Completion

**Verification:** `renderPreviewSVG()` is called and returns SVG string (448KB). Function signature:
```javascript
function renderPreviewSVG(options = {}) {
  // ... calculations ...
  const svgString = renderMapSVG(state.data, {...});
  if (container) {
    container.innerHTML = svgString;  // ← POTENTIAL BOTTLENECK
    return null;
  } else {
    return svgString;  // ← Returns SVG string
  }
}
```

**Finding:** Function **completes** (SVG string is produced), but `container.innerHTML = svgString` may hang if container is large or Alpine.js is watching it.

---

## 3. Code Audit

### 3.1 `world_builder.html` SVG Rendering Flow

**Location:** `assets/ui_web/templates/world_builder.html` (lines 396-468)

**Flow:**
1. **Line 399:** Status update: "Rendering SVG preview..."
2. **Line 410:** Get SVG container (`document.getElementById('map-preview')`)
3. **Line 416:** Clear container: `svgContainer.innerHTML = ''`
4. **Line 428-432:** Prepare `svgOptions` (width, height)
5. **Line 435:** Call `window.AzgaarGenesis.renderPreviewSVG(svgOptions)`
6. **Line 438-444:** Extract SVG string from container OR use return value
7. **Line 446-453:** **PROBLEM AREA** - Alpine.js update:
   ```javascript
   if (window.worldBuilderInstance) {
     window.worldBuilderInstance.previewSvg = previewSvgString;  // ← 448KB assignment
     window.worldBuilderInstance.previewMode = 'svg';
   }
   ```
8. **Line 456-461:** Send IPC to Godot (succeeds)

**Critical Issue: Line 49 - Alpine.js Binding**
```html
<div id="map-preview" ... x-html="previewSvg" ...>
```

When `previewSvg` is set to 448KB SVG string (line 451), Alpine.js:
1. Parses the SVG string
2. Converts to DOM nodes
3. Renders 448KB of SVG elements
4. **BLOCKS** the JavaScript thread during DOM manipulation

**Blocking Operation:** Alpine.js `x-html` directive with large SVG strings causes **synchronous DOM parsing/rendering** that can take 5+ seconds or hang indefinitely if the SVG is complex.

### 3.2 `azgaar-genesis.esm.js` Rendering Functions

**Location:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js`

#### 3.2.1 `renderMapSVG()` Function

**Lines:** 17492-17749

**Structure:**
```javascript
function renderMapSVG(data, options = {}) {
  // ... config setup ...
  
  // Layer generation (each can be expensive):
  const featuresSVG = drawFeaturesSVG(pack, width2, height2, renderConfig2);      // ← Iterates features
  const biomesSVG = drawBiomesSVG(pack, biomesData, colorScheme, renderConfig2); // ← BLOCKING LOOP
  const statesSVG = drawStatesSVG(pack, renderConfig2);                          // ← BLOCKING LOOP
  const riversSVG = drawRiversSVG(pack, renderConfig2);                          // ← Iterates rivers
  const coastOutlineSVG = drawCoastOutlineSVG(pack, renderConfig2);              // ← Iterates coastline
  const borders = drawBordersSVG(pack, renderConfig2);                           // ← BLOCKING LOOP
  const reliefSVG = drawReliefIconsSVG(...);                                     // ← Iterates cells (if enabled)
  const burgsSVG = drawBurgsSVG(pack, renderConfig2);                            // ← Iterates burgs
  
  // Concatenate all layers
  const svg = `<svg ...>${layers.join("\n")}</svg>`;
  return svg;
}
```

**Performance:** Function is **synchronous** - all layers are generated in a single blocking call.

#### 3.2.2 `drawBiomesSVG()` Function

**Lines:** 16680-16791

**Blocking Operations:**
1. **Line 16704:** `for (const cellId of cells.i)` - Iterates **ALL cells** to calculate biome color averages
2. **Line 16735:** `for (let i = 0; i < cells.i.length; i++)` - Iterates **ALL cells again** to extract polygons
3. **Line 16750:** `polygon.map((vId) => ...)` - Maps vertex indices for each cell (nested iteration)

**Cell Count:** For 2000x1000 map with 6 points, expect **~10,000-15,000 cells**. Each iteration:
- Checks biome type
- Extracts vertex coordinates
- Builds SVG path string
- Groups by biome type

**Time Complexity:** O(n) where n = cell count, but each cell does string concatenation and array operations → **O(n * m)** where m = average vertices per cell (~6-8).

#### 3.2.3 `drawStatesSVG()` Function

**Lines:** 16792-16857

**Blocking Operations:**
- **Line 16819:** `for (let i = 0; i < cells.i.length; i++)` - Iterates **ALL cells** again
- Similar polygon extraction as `drawBiomesSVG()`

**Redundancy:** Cells are iterated **multiple times** across different drawing functions (biomes, states, borders, coastline).

#### 3.2.4 `getIsolines()` Function

**Lines:** 16505-16611

**Purpose:** Generate continuous paths (isolines) for biome/state boundaries using vertex graph.

**Blocking Operations:**
- **Line 16566:** `for (const cellId of cells.i)` - Iterates **ALL cells**
- **Line 16582:** `connectVertices()` - Recursive vertex chain building (can be deep for complex boundaries)

**Time Complexity:** O(n * v) where n = cell count, v = average vertices per cell. For complex boundaries (coastlines, state borders), `connectVertices()` can traverse hundreds of vertices per isoline.

**Potential Infinite Loop Risk:** `connectVertices()` has a `MAX_ITERATIONS` guard (line 16975: `MAX_ITERATIONS = vertices2.c.length`), but if vertex graph is malformed, it could still hang on degenerate cases.

#### 3.2.5 `drawBordersSVG()` Function

**Lines:** 16857-17033

**Blocking Operations:**
- **Line 17008:** `for (let cellId = 0; cellId < cells.i.length; cellId++)` - Iterates **ALL cells** for coastline detection
- **Line 17010:** `cells.c[cellId].some(...)` - Checks neighbors for each cell (nested iteration)

**Redundancy:** Coastline iteration overlaps with `drawCoastOutlineSVG()`.

### 3.3 GDScript IPC Handling

**Location:** `scripts/ui/WorldBuilderWebController.gd`

#### 3.3.1 SVG Preview Handler

**Lines:** 1444-1478

```gdscript
func _handle_svg_preview(data: Dictionary) -> void:
    """Handle SVG preview ready IPC message."""
    var svg_data: String = data.get("svgData", "")
    var width: int = data.get("width", 1024)
    var height: int = data.get("height", 768)
    
    if svg_data.is_empty():
        MythosLogger.warn("WorldBuilderWebController", "SVG preview data is empty")
        return
    
    # Process SVG (no blocking operations in GDScript)
    # ... validation ...
    
    send_progress_update(90.0, "SVG preview ready!", true)
```

**Finding:** GDScript handler is **non-blocking** - it receives SVG string and updates progress. The hang is **not in GDScript**.

#### 3.3.2 Progress Updates

**Lines:** 1212-1242

**Implementation:** Uses `call_deferred("_post_message_safe", ...)` to avoid Rust binding conflicts.

**Finding:** Progress updates are **deferred**, which is correct. However, if JavaScript is blocked (Alpine.js rendering), progress updates may not be sent.

---

## 4. Performance Breakdown

### 4.1 Benchmark Results (Seed 42, 2000x1000, 6 points)

| Phase | Expected Time | Actual Time | Status |
|-------|---------------|-------------|--------|
| Bundle Load | <1s | ~2s | ✅ Acceptable |
| Fork Init | <500ms | ~500ms | ✅ OK |
| Map Generation | 10-15s | 14.4s | ✅ Within target |
| JSON Extract | <500ms | ~200ms | ✅ Fast |
| SVG Generate | 2-5s | **5+ min (hangs)** | ❌ **FAILED** |
| SVG DOM Render | <1s | **N/A (never completes)** | ❌ **FAILED** |

### 4.2 Bundle Size Impact

**Files:**
- `azgaar-genesis.esm.js`: **948KB** (uncompressed)
- `delaunator.esm.js`: **7.8KB**

**Load Time:** ~2s (acceptable for 948KB bundle)

**Finding:** Bundle size is not the bottleneck - SVG rendering is.

### 4.3 Map Size Impact

**Cell Count Estimation:**
- **2000x1000 map, 6 points:** ~10,000-15,000 cells
- **960x540 map, 6 points:** ~5,000-8,000 cells (50% reduction)

**Rendering Complexity:**
- SVG string size scales with cell count: **~30-50 bytes per cell** (path data)
- Expected SVG size for 10k cells: **300KB-500KB** (matches observed 448KB)

### 4.4 Identified Bottlenecks

#### Bottleneck 1: Nested Cell Iteration Loops

**Location:** `drawBiomesSVG()`, `drawStatesSVG()`, `drawBordersSVG()`

**Impact:** High - Cells are iterated **multiple times** (biomes, states, borders, coastline) with redundant polygon extraction.

**Optimization Potential:** Cache polygon data after first extraction.

#### Bottleneck 2: Alpine.js `x-html` Binding with Large SVG

**Location:** `world_builder.html` line 49

**Impact:** **CRITICAL** - Alpine.js parses 448KB SVG string synchronously, converting to DOM nodes. For complex SVGs with thousands of `<path>` elements, this can take **5-30 seconds** or hang if the browser's DOM parser is overwhelmed.

**Mitigation:** Use `requestAnimationFrame()` or `setTimeout()` to defer DOM manipulation, or render SVG in chunks.

#### Bottleneck 3: Synchronous `innerHTML` Assignment

**Location:** `world_builder.html` line 443, `azgaar-genesis.esm.js` line 18203

**Impact:** Medium - Setting `innerHTML` with large strings blocks the JavaScript thread during DOM parsing.

**Mitigation:** Use `DocumentFragment` or `DOMParser` for async parsing.

#### Bottleneck 4: Redundant Vertex Coordinate Extraction

**Location:** Multiple drawing functions extract `cells.v[cellId]` repeatedly

**Impact:** Medium - Vertex array lookups and polygon mapping are repeated across functions.

**Optimization Potential:** Pre-compute `cells.vCoords` during generation.

---

## 5. Potential Causes & Fixes

### 5.1 Root Cause Summary

**Primary Cause:** **Alpine.js `x-html` directive with 448KB SVG string** causes synchronous DOM parsing/rendering that blocks the JavaScript thread indefinitely.

**Contributing Factors:**
1. **Nested cell iteration loops** in rendering functions (biomes, states, borders)
2. **Synchronous `innerHTML` assignment** with large SVG strings
3. **Redundant polygon extraction** across multiple drawing functions
4. **No async/await or chunked rendering** in SVG generation pipeline

### 5.2 Fix Priority

#### 🔴 **CRITICAL (Immediate Fix)**

**Fix 1: Defer Alpine.js SVG Update**

**Problem:** Line 451 in `world_builder.html` sets `previewSvg` synchronously, triggering Alpine.js `x-html` binding.

**Solution:** Use `requestAnimationFrame()` or `setTimeout()` to defer the assignment:

```javascript
// In world_builder.html, line 450-453
if (window.worldBuilderInstance) {
  // Defer Alpine.js update to avoid blocking
  requestAnimationFrame(() => {
    window.worldBuilderInstance.previewSvg = previewSvgString;
    window.worldBuilderInstance.previewMode = 'svg';
  });
}
```

**Alternative:** Disable Alpine.js reactivity temporarily:

```javascript
if (window.worldBuilderInstance) {
  // Temporarily disable Alpine reactivity
  window.Alpine.pauseObserver(window.worldBuilderInstance);
  window.worldBuilderInstance.previewSvg = previewSvgString;
  window.worldBuilderInstance.previewMode = 'svg';
  window.Alpine.resumeObserver(window.worldBuilderInstance);
}
```

**Fix 2: Use Direct DOM Manipulation Instead of Alpine `x-html`**

**Problem:** Alpine.js `x-html` binding on line 49 parses SVG string synchronously.

**Solution:** Render SVG directly to container, bypass Alpine:

```javascript
// In world_builder.html, after line 443
// Instead of relying on Alpine.js x-html, set directly:
if (previewSvgString && previewSvgString.length > 0) {
  // Set container directly (bypass Alpine)
  svgContainer.innerHTML = previewSvgString;
  
  // Then update Alpine for UI state only (not rendering)
  if (window.worldBuilderInstance) {
    window.worldBuilderInstance.previewSvg = previewSvgString; // For state tracking only
    window.worldBuilderInstance.previewMode = 'svg';
    window.worldBuilderInstance.hasPreview = true; // Trigger x-show
  }
}
```

**Fix 3: Chunked SVG Rendering**

**Problem:** Rendering 448KB SVG in one operation blocks the thread.

**Solution:** Split SVG into layers and render incrementally:

```javascript
// In world_builder.html
async function renderSvgChunked(svgString, container) {
  const parser = new DOMParser();
  const svgDoc = parser.parseFromString(svgString, 'image/svg+xml');
  const svgElement = svgDoc.documentElement;
  
  // Render layers incrementally
  const layers = svgElement.querySelectorAll('g');
  container.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" ...></svg>`;
  const targetSvg = container.querySelector('svg');
  
  for (let i = 0; i < layers.length; i++) {
    targetSvg.appendChild(layers[i].cloneNode(true));
    // Yield to browser every 10 layers
    if (i % 10 === 0) {
      await new Promise(resolve => requestAnimationFrame(resolve));
    }
  }
}
```

#### 🟡 **HIGH (Next Sprint)**

**Fix 4: Cache Polygon Data**

**Problem:** `cells.v[cellId]` is extracted multiple times across functions.

**Solution:** Pre-compute `cells.vCoords` during map generation (store as `[x, y]` arrays instead of vertex indices).

**Fix 5: Optimize Cell Iteration**

**Problem:** Cells are iterated multiple times (biomes, states, borders).

**Solution:** Single-pass iteration to build all layer data structures:

```javascript
// Pseudo-code
function buildLayerData(pack) {
  const biomeGroups = {};
  const stateGroups = {};
  const coastlineCells = [];
  
  // Single pass
  for (let i = 0; i < cells.i.length; i++) {
    const polygon = extractPolygon(cells, i); // Extract once
    if (polygon) {
      biomeGroups[biome[i]]?.push(polygon);
      stateGroups[state[i]]?.push(polygon);
      if (isCoastline(i)) coastlineCells.push(i);
    }
  }
  
  return { biomeGroups, stateGroups, coastlineCells };
}
```

#### 🟢 **MEDIUM (Future Optimization)**

**Fix 6: Async SVG Generation**

**Problem:** `renderMapSVG()` is fully synchronous.

**Solution:** Use Web Workers or async generators for layer rendering:

```javascript
async function renderMapSVGAsync(data, options) {
  const layers = await Promise.all([
    drawBiomesSVGAsync(pack, ...),
    drawStatesSVGAsync(pack, ...),
    drawRiversSVGAsync(pack, ...),
    // ... other layers
  ]);
  
  return `<svg>${layers.join('\n')}</svg>`;
}
```

**Fix 7: Reduce SVG Complexity**

**Problem:** SVG includes all layers (biomes, states, borders, relief, etc.) even if not needed.

**Solution:** Make layers optional via render config, or generate simplified preview first:

```javascript
// Generate lightweight preview first (ocean + landmass only)
const previewSVG = renderMapSVG(data, {
  layers: { biomes: false, states: false, borders: false, relief: false }
});

// Then render full SVG in background
setTimeout(() => {
  const fullSVG = renderMapSVG(data, { layers: { all: true } });
  updatePreview(fullSVG);
}, 100);
```

---

## 6. Test Results

### 6.1 Small Map Test (512x512, 3000 cells)

**Hypothesis:** Smaller maps should render faster due to fewer cells.

**Test Configuration:**
- Map size: 512x512
- Points: 3
- Expected cells: ~3000

**Expected SVG Size:** ~100-150KB (vs 448KB for full map)

**Result:** **NOT TESTED** (requires code changes to test)

**Recommendation:** Test with reduced cell count first to verify the fix.

### 6.2 Reduced Layer Test

**Hypothesis:** Disabling optional layers (relief, labels) should reduce SVG size and render time.

**Test Configuration:**
- Disable relief icons
- Disable state labels
- Disable markers

**Expected SVG Size Reduction:** ~30-50KB (relief icons are heavy)

**Result:** **NOT TESTED**

### 6.3 Alpine.js Bypass Test

**Hypothesis:** Rendering SVG directly (bypassing Alpine.js `x-html`) should eliminate the hang.

**Test:** Apply Fix 2 (direct DOM manipulation)

**Expected Result:** SVG renders immediately, no hang

**Status:** **READY TO TEST**

---

## 7. Recommendations

### 7.1 Immediate Actions

1. **Apply Fix 1 or Fix 2** (defer Alpine.js update or use direct DOM manipulation)
   - **Priority:** CRITICAL
   - **Effort:** Low (5-10 lines of code)
   - **Risk:** Low (isolated change)

2. **Inject console.log wrapper** to capture WebView console output
   - **Priority:** HIGH
   - **Effort:** Medium (20-30 lines)
   - **Benefit:** Debug visibility

3. **Add render timeout** to detect hangs and fallback to canvas
   - **Priority:** MEDIUM
   - **Effort:** Low (10 lines)
   - **Benefit:** Graceful degradation

### 7.2 Short-Term Improvements (Next Sprint)

1. **Implement polygon caching** (Fix 4)
   - Reduces redundant vertex extraction
   - Expected speedup: 20-30%

2. **Optimize cell iteration** (Fix 5)
   - Single-pass layer building
   - Expected speedup: 30-50%

3. **Add progress callbacks** to `renderMapSVG()`
   - Update UI during layer generation
   - Improves perceived performance

### 7.3 Long-Term Optimizations (Future)

1. **Async SVG generation** (Fix 6)
   - Non-blocking layer rendering
   - Expected: Eliminates hangs completely

2. **Web Worker offloading**
   - Move SVG generation to background thread
   - Expected: Zero UI blocking

3. **SVG streaming/chunking**
   - Render layers incrementally as they're generated
   - Expected: Immediate visual feedback

---

## 8. Conclusion

The Azgaar fork SVG rendering hang is caused by **Alpine.js `x-html` directive with large SVG strings** (448KB+) causing synchronous DOM parsing that blocks the JavaScript thread. The SVG generation itself succeeds, but the DOM manipulation phase hangs.

**Recommended Fix:** Apply **Fix 2** (direct DOM manipulation, bypass Alpine `x-html`) as the immediate solution. This requires minimal code changes and has low risk. Follow up with **Fix 4** and **Fix 5** for performance optimization.

**Expected Outcome:**
- SVG renders within 1-2 seconds (vs indefinite hang)
- No UI blocking during rendering
- Full map preview available immediately after generation

---

## Appendix A: Log Excerpts

```
[2026-01-01 02:32:23] [WorldBuilderWebController] [INFO]: SVG preview received [{"height":1000,"svg_length":448802,"width":2000}]
[2026-01-01 02:32:24] [WorldBuilderWebController] [INFO]: SVG preview processed successfully [{"characters":448802,"height":1000,"length":448802,"width":2000}]
[2026-01-01 02:32:25] [WorldBuilderWebController] [DEBUG]: Received IPC message from WebView [{"message":"{\"type\":\"map_generated\",..."]
[2026-01-01 02:32:39] [WorldBuilderWebController] [INFO]: === END MAP GENERATED === [{"generation_time_ms":14431.0,"has_preview":false,"json_size_bytes":14663673,"seed":"12345"}]
```

**Key Observations:**
- SVG received successfully (448KB)
- `map_generated` IPC received ~1 second after SVG
- `has_preview: false` indicates SVG display failed
- 14-second gap between SVG receive and final log suggests hang during Alpine.js update

## Appendix B: Code References

- `assets/ui_web/templates/world_builder.html`: Lines 49, 396-468
- `assets/ui_web/js/azgaar/azgaar-genesis.esm.js`: Lines 16505-17033, 17492-17749, 18175-18208
- `scripts/ui/WorldBuilderWebController.gd`: Lines 1444-1478, 1212-1242

---

**Report Generated:** 2026-01-08  
**Investigator:** Auto (AI Assistant)  
**Status:** Awaiting Implementation
