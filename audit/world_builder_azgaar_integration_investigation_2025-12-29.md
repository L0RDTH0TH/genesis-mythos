# World Builder UI and Azgaar Integration Investigation Report
**Date:** 2025-12-29  
**Investigator:** Auto (Cursor AI)  
**Purpose:** Investigate why the in-game 2D preview is not displaying, why generation falls back to iframe-based method with timeouts, and why headless Genesis-Azgaar fork mode is not reliably activating.

---

## [START INVESTIGATION OUTPUT]

### 1. Key File Contents

#### 1.1 WorldBuilderWebController.gd (Main Controller)
**Location:** `scripts/ui/WorldBuilderWebController.gd`  
**Key Findings:**
- **Line 42:** `DEBUG_TEST_FORK: bool = true` - Fork testing is enabled but only runs in debug mode
- **Line 17:** `azgaar_ready_via_iframe: bool = false` - Flag tracks iframe readiness, defaults to false
- **Line 22:** `MAX_READINESS_POLLS: int = 20` - Polls for 10 seconds (20 * 0.5s) before timeout
- **Line 26:** `GENERATION_TIMEOUT_SECONDS: float = 60.0` - 60-second timeout for generation completion
- **Line 71-75:** Template selection logic:
  ```gdscript
  if DEBUG_TEST_FORK:
      html_url = "res://assets/ui_web/templates/world_builder_v2.html"  # Fork template
  else:
      html_url = "res://assets/ui_web/templates/world_builder.html"  # Iframe template
  ```
- **Line 380-394:** `_handle_azgaar_loaded()` - Starts polling when iframe loads
- **Line 397-438:** `_poll_azgaar_readiness()` - Polls iframe for `azgaar.generate` function availability
- **Line 603:** `if not azgaar_ready_via_iframe:` - Generation proceeds even if not ready (warning only)
- **Line 1267-1332:** `_handle_map_generated()` - Handles fork-generated JSON data, saves to `user://debug/azgaar_sample_map.json`
- **Line 1388-1444:** `_convert_and_preview_heightmap()` - Converts JSON to heightmap Image and saves PNG to `user://debug/heightmap_preview.png`, but **does NOT display it in UI**

**Critical Issue:** The heightmap preview is generated and saved to disk, but there's no code to display it in the WebView UI or update any preview element.

#### 1.2 world_builder.html (Iframe Template - Currently Active)
**Location:** `assets/ui_web/templates/world_builder.html`  
**Key Findings:**
- **Line 47:** `<iframe id="azgaar-iframe" src="http://127.0.0.1:8080/index.html">` - Embeds Azgaar via iframe
- **Line 152-206:** JavaScript listens for iframe load and forwards `generation_complete` messages to Godot
- **No preview display logic** - The iframe shows Azgaar's own UI, but there's no 2D preview image element

#### 1.3 world_builder_v2.html (Fork Template - Not Active by Default)
**Location:** `assets/ui_web/templates/world_builder_v2.html`  
**Key Findings:**
- **Line 48:** `<canvas id="azgaar-canvas" style="display: none;">` - Canvas exists but is hidden
- **Line 49-52:** Status div shows "Azgaar Genesis Fork - Ready" but no preview
- **Line 154-192:** Fork integration script:
  ```javascript
  import { initGenerator, loadOptions, generateMap, getMapData, renderPreview } 
      from '../js/azgaar/azgaar-genesis.esm.js';
  initGenerator({ canvas: null }); // null = headless mode
  ```
- **Line 208-279:** `handleGenerateMap()` - Generates map and sends JSON to Godot via IPC
- **No preview rendering** - `renderPreview()` is imported but never called, canvas is hidden

**Critical Issue:** The fork template is designed for headless mode (canvas: null) and never renders a preview, even though `renderPreview()` is available.

#### 1.4 AzgaarDataConverter.gd
**Location:** `scripts/managers/AzgaarDataConverter.gd`  
**Key Findings:**
- **Line 21-89:** `convert_to_heightmap()` - Converts Azgaar JSON to Godot Image (FORMAT_RF)
- **Line 137-218:** `convert_to_biome_map()` - Converts biome data to Image
- **Both methods work correctly** - They create valid Image resources from JSON data

#### 1.5 world_builder.js (Alpine.js Controller)
**Location:** `assets/ui_web/js/world_builder.js`  
**Key Findings:**
- **Line 859-896:** `generate()` - Sends params to Godot via IPC, no preview handling
- **No preview update logic** - The Alpine.js component has no methods to display a 2D preview image
- **Line 149-151:** Comment states "Azgaar is now handled via direct JS injection from GDScript" - but this is outdated

#### 1.6 Bridge.js (IPC Communication)
**Location:** `assets/ui_web/js/bridge.js`  
**Key Findings:**
- **Line 23:** Uses `window.ipc.postMessage()` for godot_wry IPC
- **Line 52-59:** `_handleUpdate()` - Handles updates from Godot, but no preview image handling

### 2. File Presence Confirmation

#### 2.1 Azgaar Fork Files
- ✅ **Present:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js` (3023 lines, minified)
- ✅ **Present:** `assets/ui_web/js/azgaar/azgaar-genesis.umd.js`
- ✅ **Present:** `assets/ui_web/js/azgaar/azgaar-genesis.min.js`
- ✅ **Present:** `tools/azgaar/` (1302 files - full Azgaar bundle)

#### 2.2 Debug Files (Expected Locations)
- **Expected:** `user://debug/azgaar_sample_map.json` (created by `_save_test_json_to_file()`)
- **Expected:** `user://debug/heightmap_preview.png` (created by `_convert_and_preview_heightmap()`)
- **Note:** These are in `user://` directory (not `res://`), so they exist at runtime but may not be visible in editor

#### 2.3 Configuration Files
- ✅ **Present:** `data/config/azgaar_step_parameters.json` (503 lines, defines all wizard steps)
- ❌ **Missing:** `data/config/world_builder_ui.json` (referenced in investigation prompt but doesn't exist)

#### 2.4 Scene Files
- ✅ **Present:** `ui/world_builder/WorldBuilderWeb.tscn` - Simple scene with WebView node
- ✅ **Present:** `scenes/ui/WorldBuilderUI.tscn` - Legacy Control-based UI (deprecated)

### 3. Run Project Results

#### 3.1 Project Startup
- ✅ Godot project starts successfully
- ✅ AzgaarServer initializes and serves files on port 8080
- ✅ WebView loads HTML template

#### 3.2 Log Analysis (from mythos_log_2025-12-29.txt)
**Key Log Entries:**
- **Line 514:** `azgaar_loaded` IPC message received - iframe loaded successfully
- **Line 515:** Azgaar readiness polling started
- **Line 517:** **Polling timeout after 20 attempts** - `azgaar_ready_via_iframe` never becomes true
- **Line 522:** `azgaar_ready_via_iframe: false` - Confirmed not ready when generation triggered
- **Line 525:** Warning: "Azgaar not ready yet via iframe, attempting generation anyway"
- **Line 530:** Generation triggered via iframe (eval) - but iframe was never ready
- **Line 531:** Project stopped (user exit) - No completion message received

**Critical Finding:** The iframe readiness check fails because:
1. The polling script checks for `iframe.contentWindow.azgaar.generate` function
2. CORS or timing issues prevent access to iframe contentWindow
3. The check returns "not_ready" for all 20 attempts
4. Generation proceeds anyway but likely fails silently

### 4. Analysis: Root Causes

#### 4.1 Why 2D Preview is Not Displaying

**Root Cause:** There is **no code to display the preview image** in the UI.

**Evidence:**
1. `_convert_and_preview_heightmap()` saves PNG to disk but doesn't update any UI element
2. `world_builder.html` has no `<img>` element for preview
3. `world_builder_v2.html` has a canvas but it's hidden and `renderPreview()` is never called
4. Alpine.js `worldBuilder` component has no preview image state or display logic
5. No IPC message type for "preview_ready" or "preview_update"

**Missing Implementation:**
- No method to load PNG from `user://debug/heightmap_preview.png` into WebView
- No `<img>` or `<canvas>` element in HTML to display preview
- No Alpine.js reactive property for preview image URL
- No IPC handler to receive preview image data from Godot

#### 4.2 Why Generation Falls Back to Iframe Method with Timeouts

**Root Cause:** The fork template (`world_builder_v2.html`) is **not loaded by default**, and the iframe template has **CORS/timing issues** preventing readiness detection.

**Evidence:**
1. **Line 71-75 of WorldBuilderWebController.gd:** Fork template only loads if `DEBUG_TEST_FORK == true`
2. **Default behavior:** Uses `world_builder.html` (iframe template) when `DEBUG_TEST_FORK == false`
3. **Iframe readiness polling fails:** 20 attempts over 10 seconds, all return "not_ready"
4. **Generation proceeds anyway:** Code continues even when `azgaar_ready_via_iframe == false`
5. **60-second timeout:** `GENERATION_TIMEOUT_SECONDS` triggers if completion not detected

**Why Iframe Readiness Fails:**
- CORS restrictions prevent accessing `iframe.contentWindow.azgaar` from parent page
- Azgaar may not be fully initialized when polling starts
- The check script may be executing before Azgaar's global `azgaar` object exists
- No error handling to distinguish CORS errors from "not ready yet"

#### 4.3 Why Headless Fork Mode is Not Reliably Activating

**Root Cause:** Fork mode is **gated behind a debug flag** and **only runs in test scenarios**, not during normal user generation.

**Evidence:**
1. **Line 42:** `DEBUG_TEST_FORK: bool = true` - Only enables fork template loading
2. **Line 107-109:** Fork test only runs if `DEBUG_TEST_FORK == true` and waits 3 seconds
3. **Line 1179-1264:** `_test_fork_headless_generation()` - Only called in debug mode
4. **Line 1267:** `_handle_map_generated()` - Handles fork results, but only receives data from test function
5. **Normal generation flow:** Uses `_handle_generate()` which calls `_sync_params_to_azgaar_iframe()` - **always uses iframe method**

**Why Fork Mode Doesn't Activate:**
- Fork template (`world_builder_v2.html`) is not the default
- Normal generation path (`_handle_generate()`) always uses iframe injection
- No code path to use fork API (`generateMap()`, `getMapData()`) during user-triggered generation
- Fork mode is treated as a "test" feature, not production code

**Missing Integration:**
- No check to detect if fork is available before falling back to iframe
- No automatic fallback from iframe to fork if iframe fails
- No user-facing option to choose fork vs iframe mode
- Fork generation results are handled separately from normal generation flow

### 5. Additional Observations

#### 5.1 IPC Message Flow Issues
- **Fork mode:** Sends `map_generated` IPC message with JSON data
- **Iframe mode:** Expects `generation_complete` IPC message (no data)
- **Mismatch:** Two different message types for the same operation
- **Handler:** `_handle_map_generated()` exists but is only called for fork test, not normal generation

#### 5.2 Preview Generation vs Display
- **Generation works:** `AzgaarDataConverter.convert_to_heightmap()` successfully creates Image
- **Saving works:** PNG is saved to `user://debug/heightmap_preview.png`
- **Display missing:** No code to load PNG into WebView or update UI

#### 5.3 Template Selection Logic
- **Current:** Binary choice between iframe template and fork template based on debug flag
- **Better approach:** Should detect fork availability and use it, fallback to iframe if unavailable
- **Missing:** Runtime detection of fork library availability

#### 5.4 Error Handling
- **Iframe readiness:** Fails silently, generation proceeds anyway
- **Generation timeout:** 60-second timer resets UI but doesn't show meaningful error
- **Fork errors:** Handled in `_handle_map_generation_failed()` but only for test scenarios

### 6. Recommendations for Fixes

#### 6.1 Fix 2D Preview Display
1. **Add preview element to HTML:**
   - Add `<img id="map-preview">` or `<canvas id="preview-canvas">` to center panel
   - Style it to fill the center panel area

2. **Add preview state to Alpine.js:**
   - Add `previewImageUrl: null` to `worldBuilder` data
   - Add `x-show` or `x-bind:src` to display preview when available

3. **Add IPC handler for preview:**
   - Create `preview_ready` IPC message type
   - Send base64-encoded PNG or file path from Godot to WebView
   - Update Alpine.js state when preview received

4. **Update conversion function:**
   - After saving PNG, send preview to WebView via IPC
   - Or load PNG into WebView's ImageTexture and display

#### 6.2 Fix Iframe Readiness Detection
1. **Improve polling logic:**
   - Add CORS error detection and handling
   - Increase polling interval or max attempts
   - Add exponential backoff

2. **Add fallback mechanism:**
   - If iframe not ready after polling, try fork mode
   - Or show user-friendly error message

3. **Fix CORS issues:**
   - Ensure AzgaarServer sends proper CORS headers (already done in AzgaarServer.gd)
   - Use postMessage API instead of direct iframe access

#### 6.3 Enable Fork Mode for Normal Use
1. **Remove debug flag dependency:**
   - Make fork mode the default, iframe as fallback
   - Or add runtime detection of fork availability

2. **Integrate fork into normal generation:**
   - Update `_handle_generate()` to use fork API if available
   - Unify message handling for both modes

3. **Add preview rendering:**
   - Call `renderPreview()` after generation in fork mode
   - Show canvas in UI when preview is ready

4. **Unify data flow:**
   - Both modes should call `_handle_map_generated()` with JSON data
   - Both modes should trigger preview display

---

## [END INVESTIGATION OUTPUT]

### Summary

**Primary Issues Identified:**
1. ✅ **2D Preview Not Displaying:** No UI element or code to display the generated preview image
2. ✅ **Iframe Timeouts:** CORS/timing issues prevent readiness detection, but generation proceeds anyway
3. ✅ **Fork Mode Not Activating:** Fork is gated behind debug flag and only used in test scenarios, not normal generation

**Next Steps:**
- Implement preview display in HTML/Alpine.js
- Fix iframe readiness detection or add fork fallback
- Enable fork mode for production use and integrate into normal generation flow

---

**Investigation Complete**  
*No files were modified during this investigation.*
