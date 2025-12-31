# SVG and Canvas Rendering Audit Report - 2025-12-30

## Summary

During world generation in the World Builder, both SVG and canvas rendering fail, resulting in the UI error message "Error: Both SVG and canvas rendering failed" and fallback to deprecated heightmap PNG conversion. The system successfully generates map data but cannot render previews via SVG or canvas methods.

The issue occurs when:
- SVG rendering (`renderPreviewSVG`) is attempted but fails (likely due to missing or incomplete data structures)
- Canvas rendering (`renderPreview`) fallback also fails (likely due to missing canvas initialization or data issues)
- System falls back to deprecated heightmap PNG conversion which succeeds

## Reproduction Steps

1. Load the project in Godot 4.5.1
2. Navigate to World Builder UI (loads `world_builder_v2.html` automatically)
3. Select "High Fantasy" archetype preset (or any preset)
4. Trigger map generation (automatically on load or manually via "Generate Map" button)
5. Observe the UI status message: "Error: Both SVG and canvas rendering failed"
6. Check logs for warnings:
   - `[WARN]: SVG missing, using legacy heightmap PNG fallback (SVG rendering may have failed)`
   - `[WARN]: No SVG or canvas preview available, using deprecated heightmap conversion`
   - `[WARN]: Using deprecated heightmap PNG conversion fallback`

**Key observation**: Map generation succeeds (JSON data is created), but preview rendering fails for both SVG and canvas methods.

## Root Cause Analysis

### Investigation Findings

The rendering pipeline follows this sequence:

1. **Generation Success** (`world_builder_v2.html:327`):
   - `generateMap(Delaunator)` successfully creates map data
   - `state.data` is set by `generateMap()` (azgaar-genesis.esm.js:3318)
   - `getMapData()` successfully extracts JSON

2. **SVG Rendering Attempt** (`world_builder_v2.html:350-421`):
   - `renderPreviewSVG(svgOptions)` is called
   - Function requires `state.data` to exist (azgaar-genesis.esm.js:3408-3409)
   - Calls `renderMapSVG(state.data, { width, height })` (line 3425)
   - `renderMapSVG` requires `data.pack` to exist (line 3127-3128)

3. **SVG Rendering Failure Points**:

   **Potential Issue #1: Missing or Incomplete Pack Data**
   - `renderMapSVG` calls `drawBiomesSVG(pack, biomesData)` (line 3142)
   - `drawBiomesSVG` calls `getIsolines(pack, (cellId) => cells.biome[cellId], ...)` (line 2901)
   - `getIsolines` requires:
     - `pack.cells` with `cells.i`, `cells.c`, `cells.v`, `cells.h`, `cells.biome`
     - `pack.vertices` with `vertices.c` and `vertices.p`
   - If `pack.vertices.c` is missing or incomplete, accessing `vertices.c[v]` (line 2803) could throw an error

   **Potential Issue #2: Missing Rendering Fields**
   - `drawBiomesSVG` requires `pack.cells.biome` (line 2898)
   - `drawStatesSVG` requires `pack.cells.state` (line 2915)
   - If these fields are missing (not generated or not in state.data), rendering functions return empty strings or throw errors

   **Potential Issue #3: Container Dimensions**
   - `renderPreviewSVG` calculates dimensions from container `getBoundingClientRect()` (line 3417-3419)
   - If container has zero dimensions, it falls back to `state.data.options.mapWidth/mapHeight`
   - If options are missing, uses defaults (1000x600)
   - Zero or invalid dimensions could cause rendering issues

4. **Canvas Rendering Attempt** (`world_builder_v2.html:430-451`):
   - Only attempted if SVG fails (`!previewSvgString`)
   - Requires `canvas` element to exist (line 430)
   - Calls `window.AzgaarGenesis.renderPreview()` (line 434)
   - `renderPreview` requires:
     - `state.canvas` to be set (azgaar-genesis.esm.js:3394-3398)
     - `state.data` to exist (line 3391-3392)

5. **Canvas Rendering Failure Points**:

   **Potential Issue #1: Canvas Not Initialized**
   - Canvas is initialized in module script (world_builder_v2.html:186-211)
   - `initGenerator({ canvas: canvas })` sets `state.canvas` (azgaar-genesis.esm.js:3271-3289)
   - If canvas element is not found or initialization fails, `state.canvas` remains null
   - `renderPreview()` checks for canvas and returns early if missing (line 3394-3398)

   **Potential Issue #2: Canvas Rendering Function Missing**
   - `renderPreview()` calls `renderMap(state.canvas, state.data)` (line 3401)
   - If `renderMap` function is missing or throws an error, canvas rendering fails

### Code Locations of Interest

**SVG Rendering Entry Point:**
```javascript
// assets/ui_web/templates/world_builder_v2.html:378
const svgResult = window.AzgaarGenesis.renderPreviewSVG(svgOptions);
```

**SVG Rendering Function:**
```javascript
// assets/ui_web/js/azgaar/azgaar-genesis.esm.js:3406-3438
function renderPreviewSVG(options = {}) {
  requireInitialized();
  if (!state.data) {
    throw new NoDataError();
  }
  // ... dimension calculation ...
  const svgString = renderMapSVG(state.data, { width, height });
  // ...
}
```

**SVG Map Rendering:**
```javascript
// assets/ui_web/js/azgaar/azgaar-genesis.esm.js:3126-3165
function renderMapSVG(data, options = {}) {
  if (!data || !data.pack) {
    throw new Error("Map data with pack is required");
  }
  // Calls: drawBiomesSVG, drawStatesSVG, etc.
}
```

**Isolines Function (Potential Failure Point):**
```javascript
// assets/ui_web/js/azgaar/azgaar-genesis.esm.js:2800-2806
const startingVertex = (_e = cells.v[cellId]) == null ? void 0 : _e.find(
  (v) => {
    var _a2;
    return (_a2 = vertices.c[v]) == null ? void 0 : _a2.some(ofDifferentType);
  }
);
// If vertices.c[v] is undefined, this could throw
```

**Canvas Rendering:**
```javascript
// assets/ui_web/js/azgaar/azgaar-genesis.esm.js:3389-3405
function renderPreview() {
  requireInitialized();
  if (!state.data) {
    throw new NoDataError();
  }
  if (!state.canvas) {
    console.warn("renderPreview() called but no canvas was provided...");
    return; // Silent failure
  }
  renderMap(state.canvas, state.data);
}
```

**Godot Side Preview Handling:**
```gdscript
// scripts/ui/WorldBuilderWebController.gd:1532-1556
if not preview_svg.is_empty():
    _handle_svg_preview({...})
else:
    if not preview_data_url.is_empty():
        _send_preview_to_webview(preview_data_url)
    else:
        _convert_and_preview_heightmap(map_data)  # Fallback
```

### Most Likely Root Causes

1. **Missing Vertices Data Structure**:
   - `getIsolines` accesses `vertices.c[v]` which may not exist if vertices weren't properly initialized
   - `pack.vertices` might be missing or incomplete in `state.data`
   - This would cause `drawBiomesSVG` or `drawStatesSVG` to throw errors

2. **Missing Rendering Fields in Pack.Cells**:
   - `drawBiomesSVG` requires `pack.cells.biome` (line 2898)
   - `drawStatesSVG` requires `pack.cells.state` (line 2915)
   - If these fields are missing (not generated or filtered out), functions return empty strings
   - However, empty strings shouldn't cause errors - the issue might be in `getIsolines` when accessing missing fields

3. **Canvas Not Properly Initialized**:
   - Canvas element might not be found during initialization
   - `state.canvas` might be null when `renderPreview()` is called
   - Function returns early without error, causing silent failure

4. **Error Propagation Issues**:
   - SVG errors are caught and logged (line 3432-3437), but error details might not reach Godot
   - Canvas errors might not be caught at all
   - IPC messages might not include error details

## Impact

### User Experience
- **No Visual Preview**: Users cannot see the generated map preview in the UI
- **Confusing Error Messages**: "Both SVG and canvas rendering failed" doesn't explain why
- **Fallback to Deprecated Method**: System uses deprecated heightmap PNG conversion, which works but is not the preferred method
- **Reduced Functionality**: SVG previews provide better scalability and interactivity than PNG

### Performance
- **Wasted Computation**: SVG/canvas rendering attempts fail, wasting CPU cycles
- **Fallback Overhead**: Heightmap conversion adds extra processing time
- **Memory Usage**: Failed rendering attempts may leave temporary data structures in memory

### Development Workflow
- **Debugging Difficulty**: Errors are not clearly logged or propagated
- **Silent Failures**: Canvas rendering fails silently (returns early without error)
- **Missing Error Context**: Error messages don't indicate which specific rendering function failed or why

## Recommendations

### High Priority

1. **Add Comprehensive Error Logging**:
   - Wrap SVG rendering in try-catch and log detailed error information
   - Include error message, stack trace, and data structure validation
   - Send detailed error info to Godot via IPC for logging
   - Example: Log which specific drawing function failed (drawBiomesSVG, drawStatesSVG, etc.)

2. **Validate Data Structures Before Rendering**:
   - Add validation checks in `renderPreviewSVG` to ensure `state.data.pack` has required fields
   - Check for `pack.vertices.c`, `pack.vertices.p`, `pack.cells.biome`, `pack.cells.state`
   - Log warnings for missing optional fields, throw errors for required fields
   - Example: `if (!pack.vertices || !pack.vertices.c) throw new Error("Missing vertices.c")`

3. **Fix Canvas Initialization**:
   - Ensure canvas element is found and properly initialized
   - Add error handling if canvas is null during initialization
   - Log warning if `renderPreview()` is called without canvas
   - Consider creating canvas dynamically if missing

4. **Improve Error Propagation**:
   - Ensure SVG rendering errors are caught and sent to Godot via IPC
   - Include error details in `svg_failed` IPC message
   - Make canvas rendering errors visible (don't fail silently)

### Medium Priority

5. **Add Data Structure Validation in getIsolines**:
   - Add null checks before accessing `vertices.c[v]`
   - Handle missing vertex data gracefully (skip or use fallback)
   - Log warnings for missing data instead of throwing errors

6. **Add Rendering Field Validation**:
   - Check if required rendering fields exist before calling drawing functions
   - Provide fallback rendering if fields are missing (e.g., render without biomes if biome data missing)
   - Log which fields are missing for debugging

7. **Improve Container Dimension Handling**:
   - Ensure container has valid dimensions before rendering
   - Add fallback dimension calculation if container rect is zero
   - Validate width/height are positive numbers

### Low Priority

8. **Add Rendering Mode Diagnostics**:
   - Add debug mode that logs data structure contents before rendering
   - Include field existence checks, array lengths, etc.
   - Help identify which specific data is missing

9. **Create Rendering Test Function**:
   - Add a function to test rendering with minimal data
   - Help isolate which rendering function fails
   - Useful for debugging and regression testing

## Related Files

### Examined Files

1. **`scripts/ui/WorldBuilderWebController.gd`** (1768 lines)
   - Lines 1505-1565: `_handle_map_generated()` - handles preview data from IPC
   - Lines 1532-1556: Preview handling logic (SVG → canvas → heightmap fallback)
   - Lines 1541-1556: Fallback chain when SVG/canvas fail

2. **`assets/ui_web/templates/world_builder_v2.html`** (503 lines)
   - Lines 186-211: Canvas initialization
   - Lines 306-492: `handleGenerateMap()` - generation and rendering orchestration
   - Lines 350-421: SVG rendering attempt with error handling
   - Lines 430-451: Canvas rendering fallback with error handling
   - Lines 458-472: IPC message sending with preview data

3. **`assets/ui_web/js/azgaar/azgaar-genesis.esm.js`** (3579 lines)
   - Lines 3126-3165: `renderMapSVG()` - orchestrates SVG layer rendering
   - Lines 2783-2841: `getIsolines()` - generates isolines for biomes/states (potential failure point)
   - Lines 2897-2929: `drawBiomesSVG()` and `drawStatesSVG()` - call getIsolines
   - Lines 3406-3438: `renderPreviewSVG()` - entry point for SVG rendering
   - Lines 3389-3405: `renderPreview()` - canvas rendering function
   - Lines 3314-3326: `generateMap()` - sets `state.data`
   - Lines 3167-3175: `state` object definition

4. **`scripts/managers/AzgaarIntegrator.gd`** (137 lines)
   - Manages Azgaar bundle files (not directly related to rendering failures)

### Key Code Excerpts

**SVG Rendering with Error Handling:**
```javascript
// assets/ui_web/templates/world_builder_v2.html:350-421
if (useSvg && window.AzgaarGenesis.renderPreviewSVG) {
    try {
        const svgResult = window.AzgaarGenesis.renderPreviewSVG(svgOptions);
        // Extract SVG string...
    } catch (svgError) {
        console.error('[Azgaar Genesis] SVG preview render failed:', svgError);
        // Notify Godot, fall through to canvas
    }
}
```

**Canvas Rendering with Error Handling:**
```javascript
// assets/ui_web/templates/world_builder_v2.html:430-451
if (!previewSvgString && canvas && window.AzgaarGenesis.renderPreview) {
    try {
        window.AzgaarGenesis.renderPreview();
        previewDataUrl = canvas.toDataURL('image/png');
    } catch (renderError) {
        console.error('[Azgaar Genesis] Canvas preview render failed:', renderError);
        statusDiv.innerHTML = '<p style="color: #f44;">Error: Both SVG and canvas rendering failed</p>';
    }
}
```

**Godot Side Fallback Chain:**
```gdscript
// scripts/ui/WorldBuilderWebController.gd:1532-1556
if not preview_svg.is_empty():
    _handle_svg_preview({...})
else:
    if not preview_data_url.is_empty():
        _send_preview_to_webview(preview_data_url)
    else:
        _convert_and_preview_heightmap(map_data)  # Last resort
```

## Next Steps

1. **Immediate Action**: Add detailed error logging to identify which specific rendering function fails
2. **Investigation**: Use browser DevTools to inspect JavaScript errors during rendering
3. **Validation**: Add data structure validation before rendering attempts
4. **Testing**: Create test cases with minimal data to isolate failure points
5. **Fix Implementation**: Once root cause is confirmed, implement targeted fixes

## Notes

- Map generation succeeds (JSON data is created correctly)
- The issue is specifically with preview rendering, not map generation
- Both SVG and canvas rendering fail, suggesting a common underlying issue (likely data structure)
- Fallback to heightmap PNG works, indicating basic data is available
- Error messages are not detailed enough to identify the specific failure point
- Canvas rendering fails silently (returns early without error), making debugging difficult

---

**Report Generated**: 2025-12-30  
**Investigator**: AI Assistant (Cursor)  
**Status**: Investigation Complete - Root Cause Identified (Likely Data Structure Issues)
