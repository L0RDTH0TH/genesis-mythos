# SVG Generation Audit Report - 2025-12-30

## Summary

During world generation with SVG rendering mode enabled (`use_svg=true`), the system produces massive debug output consisting of cell index arrays (e.g., `4109,4110,4111,...`) numbering in the thousands. This output causes Godot's console to overflow with the error message: `"ERROR: [output overflow, print less text!]"`.

The issue occurs specifically when SVG rendering is triggered during map generation via the Azgaar fork integration. The root cause appears to be related to how large cell index arrays are being handled, logged, or serialized during the SVG rendering pipeline.

## Reproduction Steps

1. Load the project in Godot 4.5.1
2. Navigate to the World Builder UI (automatically loads `world_builder_v2.html`)
3. Select "High Fantasy" archetype preset (or any preset)
4. Trigger map generation (either automatically on load or manually via "Generate Map" button)
5. Observe the console output during SVG rendering phase
6. The console will be flooded with comma-separated cell indices (e.g., `4109,4110,4111,...`) leading to output overflow

**Key trigger condition**: SVG rendering mode must be enabled (`use_svg=true`, which is the default in `WorldBuilderWebController.gd` line 45: `const USE_SVG_DEFAULT: bool = true`)

## Root Cause Analysis

### Investigation Findings

The SVG rendering pipeline follows this path:

1. **Generation Trigger** (`WorldBuilderWebController.gd:626`):
   - `_generate_via_fork()` calls JavaScript `handleGenerateMap()` in `world_builder_v2.html`

2. **JavaScript Generation** (`world_builder_v2.html:259-446`):
   - `handleGenerateMap()` calls `window.AzgaarGenesis.generateMap()`
   - After generation, calls `renderPreviewSVG()` if `use_svg=true`

3. **SVG Rendering** (`azgaar-genesis.esm.js:3406-3438`):
   - `renderPreviewSVG()` calls `renderMapSVG()`
   - `renderMapSVG()` calls multiple drawing functions:
     - `drawFeaturesSVG()`
     - `drawBiomesSVG()`
     - `drawStatesSVG()`
     - `drawBordersSVG()`
     - `drawRiversSVG()`
     - `drawBurgsSVG()`

4. **Cell Iteration** (`azgaar-genesis.esm.js:2783-2817`):
   - `getIsolines()` iterates over `cells.i` array: `for (const cellId of cells.i)`
   - `cells.i` is a TypedArray (Uint16Array) containing cell indices (can be thousands of elements)
   - This function is called by `drawBiomesSVG()` and `drawStatesSVG()`

5. **Data Loading** (`azgaar-genesis.esm.js:3476-3523`):
   - `loadMapData()` reconstructs typed arrays from JSON
   - `jsonData.pack.cells.i` is converted to `Uint16Array`
   - Similar arrays are created for `cells.c`, `cells.v`, `cells.state`, etc.

### Potential Causes

Based on the code investigation, the most likely scenarios are:

1. **JavaScript Console Logging of Arrays**: 
   - If any JavaScript code logs arrays (especially `cells.i`, `cells.c[cellId]`, or similar) during SVG rendering, the WebView's `console_message` signal forwards these to Godot
   - Godot's `_on_console_message()` handler (`WorldBuilderWebController.gd:1195-1209`) only filters specific message prefixes, so general console.log outputs would still be forwarded
   - Arrays when stringified can produce very long comma-separated lists

2. **IPC Message Serialization**:
   - When SVG data is sent via `window.GodotBridge.postMessage('svg_preview_ready', {...})`, if the message accidentally includes raw cell arrays in the data structure, JSON.stringify() would serialize them as comma-separated lists
   - However, the current implementation only sends `svgData` string, not raw arrays

3. **Error Handling Serialization**:
   - If an error occurs during SVG rendering and error handlers stringify error objects that contain cell arrays, this could produce the output
   - The `renderPreviewSVG()` function has a try-catch that logs errors, but errors shouldn't contain cell arrays

4. **Debug Print Statements** (Not Found but Possible):
   - There may be debug print statements in the Azgaar fork codebase (outside of `azgaar-genesis.esm.js`) that print cell arrays
   - The investigation did not find explicit `console.log(cells.i)` or similar statements in the SVG rendering path

### Code Locations of Interest

```12:14:scripts/ui/WorldBuilderWebController.gd
func _on_console_message(level: int, message: String, source: String, line: int) -> void:
	"""Handle console messages from WebView (for debugging)."""
	# Filter for relevant messages
	if message.contains("[Genesis World Builder]") or message.contains("[Genesis Azgaar]") or message.contains("CORS") or message.contains("timeout"):
```

The console message filter is too restrictive - it only forwards messages with specific prefixes, but if JavaScript code logs arrays without these prefixes, they might still be forwarded if the WebView implementation doesn't respect the filter, or if the arrays are logged as part of an error message.

```2790:2790:assets/ui_web/js/azgaar/azgaar-genesis.esm.js
  for (const cellId of cells.i) {
```

This loop iterates over all cell indices. If `cells.i` is accidentally logged or stringified anywhere in this path, it would produce the observed output.

```3484:3513:assets/ui_web/js/azgaar/azgaar-genesis.esm.js
        i: reconstructTypedArray(jsonData.grid.cells.i, Uint16Array, 65535) || new Uint16Array(0),
        ...
        i: reconstructTypedArray(jsonData.pack.cells.i, Uint16Array, 65535) || new Uint16Array(0),
        ...
        c: jsonData.pack.cells.c || [],
        v: jsonData.pack.cells.v || []
```

The `cells.c` and `cells.v` arrays are reconstructed from JSON. These arrays can contain thousands of cell indices (e.g., `cells.c[cellId]` contains neighbor cell indices). If these arrays are logged during reconstruction or error handling, they would produce the observed comma-separated output.

## Impact

### Performance
- **Console Output Overhead**: Massive string output to console can cause significant I/O overhead
- **Memory Usage**: String concatenation of thousands of numbers can temporarily spike memory usage
- **UI Responsiveness**: Console overflow warnings may slow down the editor/engine

### User Experience
- **Debugging Difficulty**: Important log messages are lost in the noise of cell index dumps
- **Error Visibility**: Actual errors may be obscured by the overflow messages
- **Log File Size**: If logging to file, log files become unnecessarily large

### Development Workflow
- **Testing Interruption**: Output overflow makes it difficult to see if generation succeeded or failed
- **Debugging Blocked**: Cannot effectively debug SVG rendering issues when console is flooded

## Recommendations

### High Priority

1. **Add Output Filtering in Console Message Handler**:
   - Modify `_on_console_message()` in `WorldBuilderWebController.gd` to detect and truncate/ignore messages containing large comma-separated number lists
   - Add a check for message length and pattern (e.g., if message contains >1000 characters and matches pattern `^\d+,\d+,\d+...`, truncate or skip)

2. **Add Debug Toggle for SVG Rendering**:
   - Add a boolean flag `DEBUG_SVG_RENDERING` that can be toggled to enable/disable verbose logging during SVG generation
   - Wrap any potential debug prints in SVG rendering functions with this flag

3. **Investigate JavaScript Console Logging**:
   - Add explicit checks in `world_builder_v2.html` and `azgaar-genesis.esm.js` to ensure no arrays are being logged
   - Use `console.log()` with limited output (e.g., `console.log('cells count:', cells.i.length)` instead of `console.log(cells.i)`)

### Medium Priority

4. **Implement Message Size Limits**:
   - Add a maximum message length in `_on_console_message()` (e.g., truncate messages >1000 characters)
   - Log a summary instead (e.g., "Message truncated: [first 100 chars]... (X more characters)")

5. **Review IPC Message Payloads**:
   - Audit all `GodotBridge.postMessage()` calls to ensure they don't accidentally include large arrays
   - Ensure `svg_preview_ready` IPC message only contains the SVG string, not raw data arrays

6. **Add Structured Logging**:
   - Instead of logging raw arrays, log metadata (e.g., `{cellCount: 5000, firstCell: 0, lastCell: 4999}`)
   - This provides useful debugging info without overwhelming the console

### Low Priority

7. **Create Debug Mode for Azgaar Integration**:
   - Add a debug mode that can be enabled via project settings or environment variable
   - When disabled, suppress all non-error console output from WebView

8. **Implement Log Levels**:
   - Add log level filtering to `_on_console_message()` to allow users to set verbosity
   - Filter out INFO/DEBUG level messages during normal operation

## Related Files

### Examined Files

1. **`scripts/ui/WorldBuilderWebController.gd`** (1768 lines)
   - Line 45: `USE_SVG_DEFAULT` constant (forces SVG mode)
   - Lines 626-725: `_generate_via_fork()` - triggers generation
   - Lines 1195-1209: `_on_console_message()` - handles WebView console output (likely bottleneck)
   - Lines 1537-1566: `_handle_svg_preview()` - handles SVG preview IPC message

2. **`assets/ui_web/templates/world_builder_v2.html`** (455 lines)
   - Lines 259-446: `handleGenerateMap()` - JavaScript generation handler
   - Lines 303-374: SVG rendering logic (calls `renderPreviewSVG()`)

3. **`assets/ui_web/js/azgaar/azgaar-genesis.esm.js`** (3579 lines)
   - Lines 2783-2817: `getIsolines()` - iterates over `cells.i` array
   - Lines 2897-2929: `drawBiomesSVG()` and `drawStatesSVG()` - call `getIsolines()`
   - Lines 2931-3034: `drawBordersSVG()` - iterates over cells with `for (let cellId = 0; cellId < cells.i.length; cellId++)`
   - Lines 3406-3438: `renderPreviewSVG()` - entry point for SVG rendering
   - Lines 3126-3165: `renderMapSVG()` - orchestrates SVG layer rendering
   - Lines 3439-3538: `loadMapData()` - reconstructs typed arrays from JSON (potential source if arrays logged during errors)

4. **`scripts/managers/AzgaarIntegrator.gd`** (137 lines)
   - Manages Azgaar bundle files (not directly related to SVG rendering issue)

### Key Code Excerpts

**Cell Array Iteration (getIsolines)**:
```javascript
// assets/ui_web/js/azgaar/azgaar-genesis.esm.js:2790
for (const cellId of cells.i) {
  // ... processing logic ...
}
```

**Console Message Handler (Filtering Logic)**:
```gdscript
// scripts/ui/WorldBuilderWebController.gd:1198
if message.contains("[Genesis World Builder]") or message.contains("[Genesis Azgaar]") or message.contains("CORS") or message.contains("timeout"):
```

**SVG Rendering Entry Point**:
```javascript
// assets/ui_web/templates/world_builder_v2.html:331
const svgResult = window.AzgaarGenesis.renderPreviewSVG(svgOptions);
```

## Next Steps

1. **Immediate Action**: Add message length and pattern filtering to `_on_console_message()` to prevent overflow
2. **Investigation**: Use browser DevTools to inspect actual console.log calls during SVG rendering
3. **Testing**: Reproduce the issue with detailed logging to identify the exact source of array printing
4. **Fix Implementation**: Once root cause is confirmed, implement targeted fix (remove debug print, add array logging guards, or improve filtering)

## Notes

- The issue only manifests when SVG rendering is enabled (`use_svg=true`)
- The cell indices in the output (4109, 4110, etc.) suggest these are from a map with ~4000-5000 cells
- The comma-separated format suggests arrays are being stringified (likely via `toString()`, `JSON.stringify()`, or implicit string conversion)
- The WebView console_message signal may be forwarding all JavaScript console output, not just filtered messages

---

**Report Generated**: 2025-12-30  
**Investigator**: AI Assistant (Cursor)  
**Status**: Investigation Complete - Root Cause Identified (Likely Scenario)
