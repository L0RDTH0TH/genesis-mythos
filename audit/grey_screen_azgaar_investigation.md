# Grey Screen Azgaar Integration Investigation Report

**Date:** 2025-12-28  
**Issue:** Project launches to grey screen after implementing Azgaar message listener injection  
**Commit:** `19a9d86` - "fix: Implement Azgaar message listener injection for map regeneration"

---

## Executive Summary

The grey screen issue is **NOT directly caused by the Azgaar message listener changes**. Instead, it is caused by a **scene path mismatch** in `world_root.gd` that prevents the World Builder UI from loading. The Azgaar listener injection code appears correct, but cannot function because the UI never initializes.

---

## Observed Symptoms

1. **Grey screen on project launch** - No UI visible, only grey background
2. **No error messages visible** - Silent failure during scene loading
3. **Parameter tweaks not affecting Azgaar** - Cannot be tested because UI doesn't load
4. **Disconnect between custom GUI and Azgaar** - Cannot be verified due to UI failure

---

## Root Cause Analysis

### Primary Issue: Scene Path Mismatch

**Location:** `core/scenes/world_root.gd:116`

```116:120:core/scenes/world_root.gd
	# Load WorldBuilderRoot scene (modular UI)
	var ui_scene: PackedScene = load("res://ui/world_builder/modules/WorldBuilderRoot.tscn")
	if ui_scene == null:
		MythosLogger.error("World", "Failed to load WorldBuilderRoot scene")
		LoadingOverlay.hide_loading()
		return
```

**Problem:** The code attempts to load `res://ui/world_builder/modules/WorldBuilderRoot.tscn`, but this file **does not exist**.

**Actual scene files found:**
- `res://ui/world_builder/WorldBuilderWeb.tscn` (exists)
- `res://scenes/ui/WorldBuilderUI.tscn` (exists)

**Impact:** When `load()` returns `null`, the function returns early, hiding the loading overlay and leaving only the grey 3D world visible. No UI is instantiated.

### Secondary Issue: Method Verification Failure

**Location:** `core/scenes/world_root.gd:136`

```136:139:core/scenes/world_root.gd
	# Verify it's the correct type
	if not world_builder_ui.has_method("set_terrain_manager"):
		MythosLogger.error("World", "Instantiated node is not WorldBuilderUI")
		LoadingOverlay.hide_loading()
```

**Problem:** Even if the scene loaded, it would fail this check because `WorldBuilderWebController` (the script attached to `WorldBuilderWeb.tscn`) does not have a `set_terrain_manager()` method.

**Current script:** `scripts/ui/WorldBuilderWebController.gd` - No `set_terrain_manager()` method exists.

---

## File Analysis

### 1. World Builder JavaScript (`assets/ui_web/js/world_builder.js`)

**Status:** ✅ **Code appears correct**

The Azgaar message listener injection logic in `world_builder.js` is well-implemented:

- **Lines 129-269:** `_setupAzgaarListener()` method with proper retry logic
- **Lines 145-204:** Listener script injection with origin validation
- **Lines 207-230:** Multiple injection strategies (script tag, eval fallback)
- **Lines 237-268:** Retry mechanism with exponential backoff

**Key Features:**
- Checks for `window._azgaarMessageListenerInjected` to prevent duplicate injection
- Validates message origins (file://, res://, http://127.0.0.1:8080)
- Handles both `azgaar_params` and `azgaar_generate` message types
- Waits for Azgaar to initialize before injection

**Potential Issues:**
- None identified in the JavaScript code itself
- Code cannot execute if HTML never loads (due to scene path issue)

### 2. World Builder HTML Template (`assets/ui_web/templates/world_builder.html`)

**Status:** ✅ **Structure appears correct**

- **Line 35-41:** Azgaar iframe properly configured
  ```html
  <iframe 
      id="azgaar-iframe"
      src="http://127.0.0.1:8080/index.html"
      style="width: 100%; height: 100%; border: none; background: transparent;"
      allowfullscreen
      sandbox="allow-scripts allow-same-origin allow-popups allow-modals">
  </iframe>
  ```

- **Line 154-156:** Scripts loaded in correct order (bridge.js, world_builder.js, alpine.min.js)

**Potential Issues:**
- None identified - HTML structure is sound

### 3. World Builder Controller (`scripts/ui/WorldBuilderWebController.gd`)

**Status:** ⚠️ **Missing method expected by world_root.gd**

**Issues Found:**

1. **Missing `set_terrain_manager()` method:**
   - `world_root.gd:136` expects this method to exist
   - Current script does not implement it
   - This would cause instantiation to fail even if scene path was correct

2. **IPC message handling appears correct:**
   - Lines 276-317: Proper message parsing and routing
   - Lines 320-327: Alpine.js ready handler
   - Lines 435-461: Generate handler (delegates to iframe postMessage)

**What works:**
- WebView loading and IPC connection setup
- Step definitions loading and sending
- Parameter updates and clamping
- Progress updates

### 4. Azgaar HTML (`tools/azgaar/index.html`)

**Status:** ✅ **Listener injection code present**

**Lines 8184-8256:** Message listener script is embedded in Azgaar HTML:

- Waits for `azgaar` object to initialize
- Sets up `window.addEventListener('message', ...)`
- Handles `azgaar_params` and `azgaar_generate` messages
- Validates message origins

**Note:** This listener is **in addition to** the one injected from `world_builder.js`. Both should work, but the injected one from JavaScript is more flexible.

---

## Debug Output Analysis

**Note:** Unable to capture live debug output due to Godot not being in PATH. However, based on code analysis, expected errors would be:

1. **Scene load failure:**
   ```
   [ERROR] World: Failed to load WorldBuilderRoot scene
   ```

2. **Method verification failure (if scene loaded):**
   ```
   [ERROR] World: Instantiated node is not WorldBuilderUI
   ```

3. **Missing IPC connection warnings (if UI loaded but WebView fails):**
   ```
   [WARN] WorldBuilderWebController: WebView does not have ipc_message signal
   ```

---

## Breaking Changes from Commit `19a9d86`

**Files Modified:**
1. `assets/ui_web/js/world_builder.js` - Added Azgaar listener injection (265 lines added)
2. `tools/azgaar/index.html` - Added embedded message listener (74 lines added)
3. `scripts/ui/WorldBuilderWebController.gd` - Minor change (2 lines)

**Analysis:**
- The JavaScript changes are **additive only** - no existing functionality was removed
- The Azgaar HTML changes are **additive only** - embedded listener is a fallback
- The GDScript change is minimal (2 lines)

**Conclusion:** The commit itself did not introduce breaking changes. The grey screen is caused by **pre-existing scene path mismatch** that was not caught because the UI was never tested after the Azgaar integration changes.

---

## Recommended Solutions

### Solution 1: Fix Scene Path (CRITICAL - Required for UI to load)

**File:** `core/scenes/world_root.gd:116`

**Change:**
```gdscript
# OLD (broken):
var ui_scene: PackedScene = load("res://ui/world_builder/modules/WorldBuilderRoot.tscn")

# NEW (correct):
var ui_scene: PackedScene = load("res://ui/world_builder/WorldBuilderWeb.tscn")
# OR
var ui_scene: PackedScene = load("res://scenes/ui/WorldBuilderUI.tscn")
```

**Decision needed:** Determine which scene file is the correct one to use:
- `WorldBuilderWeb.tscn` - Uses `WorldBuilderWebController` (WebView-based, current implementation)
- `WorldBuilderUI.tscn` - May be legacy or different implementation

### Solution 2: Remove or Implement `set_terrain_manager()` Method

**Option A: Remove the check** (if terrain manager connection is not needed)

**File:** `core/scenes/world_root.gd:136-139`

```gdscript
# Remove or comment out:
# if not world_builder_ui.has_method("set_terrain_manager"):
#     MythosLogger.error("World", "Instantiated node is not WorldBuilderUI")
#     LoadingOverlay.hide_loading()
#     return
```

**Option B: Implement the method** (if terrain manager connection is needed)

**File:** `scripts/ui/WorldBuilderWebController.gd`

Add method:
```gdscript
func set_terrain_manager(manager: Node) -> void:
    """Set terrain manager reference (stub for interface compatibility)."""
    # Store reference if needed for future terrain operations
    # Currently, WorldBuilderWebController doesn't directly interact with terrain
    MythosLogger.debug("WorldBuilderWebController", "Terrain manager set", {"manager": manager})
```

**Option C: Update world_root.gd to not require this method**

**File:** `core/scenes/world_root.gd:170-175`

```gdscript
# Make terrain manager connection optional:
if terrain_manager and world_builder_ui.has_method("set_terrain_manager"):
    world_builder_ui.set_terrain_manager(terrain_manager)
    MythosLogger.debug("World", "Terrain manager connected to WorldBuilderUI")
elif terrain_manager:
    MythosLogger.debug("World", "WorldBuilderUI does not support terrain manager connection")
```

### Solution 3: Verify IPC Communication (After UI loads)

Once the scene path is fixed and UI loads:

1. **Check WebView IPC signal connection:**
   - Verify `web_view.has_signal("ipc_message")` returns `true`
   - Verify `web_view.ipc_message.connect(_on_ipc_message)` succeeds

2. **Test Alpine.js initialization:**
   - Verify `alpine_ready` message is received from WebView
   - Verify step definitions are sent and received

3. **Test Azgaar iframe communication:**
   - Verify iframe loads (`http://127.0.0.1:8080/index.html`)
   - Verify listener injection succeeds (check console logs)
   - Test parameter updates via `postMessage`
   - Test generation trigger via `postMessage`

### Solution 4: Add Error Handling and Logging

**File:** `core/scenes/world_root.gd:116-120`

Improve error reporting:
```gdscript
var ui_scene: PackedScene = load("res://ui/world_builder/WorldBuilderWeb.tscn")
if ui_scene == null:
    MythosLogger.error("World", "Failed to load WorldBuilderWeb scene", {
        "path": "res://ui/world_builder/WorldBuilderWeb.tscn",
        "alternative": "res://scenes/ui/WorldBuilderUI.tscn"
    })
    # Try alternative path
    ui_scene = load("res://scenes/ui/WorldBuilderUI.tscn")
    if ui_scene == null:
        MythosLogger.error("World", "Failed to load alternative WorldBuilderUI scene")
        LoadingOverlay.hide_loading()
        return
```

### Solution 5: Verify Azgaar Server is Running

**Requirement:** Azgaar must be served at `http://127.0.0.1:8080/index.html`

**Check:**
- Is a local HTTP server running on port 8080?
- Does `tools/azgaar/index.html` exist and is it being served correctly?
- Are there CORS issues preventing iframe loading?

**Alternative:** Consider using `res://tools/azgaar/index.html` if godot_wry supports loading local files in iframes.

---

## Testing Checklist

After implementing fixes:

- [ ] Project launches without grey screen
- [ ] World Builder UI is visible
- [ ] Left sidebar shows 8 steps
- [ ] Azgaar iframe loads in center panel
- [ ] Parameter controls appear in right panel
- [ ] Console shows "Alpine.js ready" message
- [ ] Console shows "Azgaar message listener injected" message
- [ ] Parameter changes update Azgaar options
- [ ] Generate button triggers Azgaar map generation
- [ ] Progress bar updates during generation
- [ ] No JavaScript errors in browser console (if accessible)
- [ ] No GDScript errors in Godot output

---

## Additional Observations

### Potential Cross-Origin Issues

The iframe loads from `http://127.0.0.1:8080` while the parent WebView loads from `res://`. This may cause cross-origin restrictions:

- **postMessage** should work across origins if targetOrigin is `'*'` (currently used in `world_builder.js:525-526`)
- **iframe.contentWindow.eval()** may fail due to CORS - this is why script tag injection is preferred
- **iframe.contentDocument** access may be blocked - fallback to `eval()` handles this

### Timing Issues

The listener injection has multiple retry mechanisms:
- Initial delay: 2-3 seconds after iframe load
- Retry count: Up to 5 retries with 2-second intervals
- Total wait time: Up to 12 seconds

This should be sufficient, but if Azgaar takes longer to initialize, injection may fail silently.

### Duplicate Listeners

Both `tools/azgaar/index.html` (embedded) and `world_builder.js` (injected) set up message listeners. This is redundant but harmless - both will fire, which may cause duplicate parameter applications. Consider removing the embedded listener if the injected one works reliably.

---

## Conclusion

The grey screen issue is **not caused by the Azgaar message listener implementation**. The root cause is a **scene path mismatch** in `world_root.gd` that prevents the World Builder UI from loading. The Azgaar listener code appears sound and should work once the UI loads correctly.

**Priority fixes:**
1. **CRITICAL:** Fix scene path in `world_root.gd:116`
2. **HIGH:** Resolve `set_terrain_manager()` method requirement
3. **MEDIUM:** Add better error handling and logging
4. **LOW:** Verify Azgaar server is running and accessible

Once these fixes are applied, the Azgaar message listener injection should function as intended, allowing parameter updates and map regeneration to work correctly.

---

**Report Generated:** 2025-12-28  
**Investigator:** Cursor AI Assistant  
**Status:** Ready for implementation
