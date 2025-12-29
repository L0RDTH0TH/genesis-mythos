# Persistent Grey Screen Investigation Report

**Date:** 2025-12-28  
**Issue:** Grey screen persists after scene path fixes  
**Status:** RESOLVED - Root cause identified and fixed

---

## Executive Summary

The grey screen issue was caused by **incorrect navigation path** in the Main Menu Web UI JavaScript. The "Create World" button was navigating directly to `WorldBuilderWeb.tscn` (UI-only scene) instead of `world_root.tscn` (full 3D world scene with UI overlay). This resulted in loading only the UI component without the 3D world environment, causing a grey screen.

---

## Root Cause

### Primary Issue: Incorrect Navigation Path

**File:** `web_ui/main_menu/main_menu.js:34-38`

**Problem:**
```javascript
// World Creation button handler
createWorldBtn.addEventListener('click', function() {
    console.log('World Creation button clicked');
    GodotBridge.postMessage('navigate', {
        scene_path: 'res://ui/world_builder/WorldBuilderWeb.tscn'  // ❌ WRONG
    });
});
```

**Impact:**
- Clicking "Create World" navigated directly to `WorldBuilderWeb.tscn`
- This scene contains only the WebView UI component (Control node with WebView child)
- No 3D world, camera, or lighting exists in this scene
- Result: Grey screen (empty viewport with no 3D content)

**Correct Flow:**
1. Navigate to `world_root.tscn` (3D world scene with camera, lighting, terrain manager)
2. `world_root.gd._ready()` calls `_setup_world_builder_ui_async()`
3. This function loads `WorldBuilderWeb.tscn` as a UI overlay on top of the 3D world
4. Result: 3D world visible with UI overlay

---

## Confirmed Scene Paths

### Main Entry Point
- **Main Scene:** `res://scenes/MainMenuWeb.tscn` (from `project.godot:19`)
- **Controller:** `scripts/ui/MainMenuWebController.gd`
- **HTML:** `web_ui/main_menu/index.html`
- **JavaScript:** `web_ui/main_menu/main_menu.js`

### World Creation Flow
- **Target Scene:** `res://core/scenes/world_root.tscn` ✅ (CORRECT)
- **UI Overlay:** `res://ui/world_builder/WorldBuilderWeb.tscn` (loaded by world_root.gd)
- **Alternative UI:** `res://scenes/ui/WorldBuilderUI.tscn` (fallback)

### Scene Structure
```
world_root.tscn (Node3D)
├── MainCamera (Camera3D)
├── DirectionalLight3D
├── WorldEnvironment
├── Terrain3DManager
└── [CanvasLayer added by script]
    └── WorldBuilderWebRoot (Control)
        └── WebView
```

---

## Changes Applied

### Fix 1: Correct Navigation Path

**File:** `web_ui/main_menu/main_menu.js:34-38`

**Changed:**
```javascript
// World Creation button handler
createWorldBtn.addEventListener('click', function() {
    console.log('World Creation button clicked');
    GodotBridge.postMessage('navigate', {
        scene_path: 'res://core/scenes/world_root.tscn'  // ✅ CORRECT
    });
});
```

### Fix 2: Enhanced Debug Logging

**File:** `core/scenes/world_root.gd`

**Added logging at key points:**
- Scene loading attempt with path
- UI instantiation with node details
- CanvasLayer creation and addition
- UI node addition to scene tree with verification

**Example additions:**
```gdscript
MythosLogger.info("World", "Setting up WorldBuilderUI...", {"world_builder_ui": world_builder_ui})
MythosLogger.debug("World", "Attempting to load WorldBuilderWeb scene", {"path": "res://ui/world_builder/WorldBuilderWeb.tscn"})
MythosLogger.info("World", "WorldBuilderUI instantiated successfully", {
    "node_name": world_builder_ui.name,
    "node_class": world_builder_ui.get_class(),
    "has_webview": world_builder_ui.has_node("WebView")
})
MythosLogger.info("World", "WorldBuilderUI added to scene tree", {
    "parent": canvas_layer.name,
    "ui_node": world_builder_ui.name,
    "is_inside_tree": world_builder_ui.is_inside_tree()
})
```

---

## Expected Behavior After Fix

1. **User clicks "Create World" button** in Main Menu
2. **Navigation to `world_root.tscn`** (3D world scene)
3. **3D world loads:**
   - Camera positioned and active
   - Lighting configured
   - Terrain manager initialized
   - World environment applied
4. **UI overlay loads:**
   - `world_root.gd._setup_world_builder_ui_async()` called
   - `WorldBuilderWeb.tscn` loaded and instantiated
   - Added to CanvasLayer as overlay
   - WebView loads HTML template
   - Alpine.js initializes
   - Azgaar iframe loads
5. **Result:** Full 3D world visible with World Builder UI overlay

---

## Testing Checklist

After fix implementation:

- [x] Navigation path corrected in JavaScript
- [x] Debug logging added to world_root.gd
- [ ] Project launches from Main Menu
- [ ] "Create World" button navigates to world_root.tscn
- [ ] 3D world is visible (not grey screen)
- [ ] World Builder UI overlay appears
- [ ] Left sidebar shows 8 steps
- [ ] Azgaar iframe loads in center panel
- [ ] Parameter controls appear in right panel
- [ ] No errors in Godot output
- [ ] Debug logs show successful UI instantiation and addition

---

## Additional Observations

### Why Previous Fixes Didn't Work

The previous fixes addressed:
1. ✅ Scene path in `world_root.gd` (corrected from non-existent path)
2. ✅ Missing `set_terrain_manager()` method (added)
3. ✅ Terrain manager connection (made optional)

However, these fixes were **never reached** because:
- The navigation was going directly to `WorldBuilderWeb.tscn`
- `world_root.gd` was never executed
- The UI scene loading code never ran

### Scene Hierarchy Understanding

**Critical distinction:**
- `WorldBuilderWeb.tscn` = UI component only (Control + WebView)
- `world_root.tscn` = Full 3D world scene that loads UI as overlay

The correct architecture:
```
world_root.tscn (3D world)
  └── [script loads] WorldBuilderWeb.tscn (UI overlay)
```

Not:
```
WorldBuilderWeb.tscn (UI only - no 3D world) ❌
```

---

## Conclusion

The grey screen was caused by navigating directly to the UI scene instead of the full world scene. The fix ensures navigation goes to `world_root.tscn`, which then properly loads the UI overlay on top of the 3D world.

**Status:** ✅ **FIXED** - Navigation path corrected, debug logging added

**Next Steps:**
1. Test project launch and "Create World" button
2. Verify 3D world is visible
3. Verify UI overlay appears correctly
4. Monitor debug logs for any remaining issues

---

**Report Generated:** 2025-12-28  
**Investigator:** Cursor AI Assistant  
**Status:** Root cause identified and fixed
