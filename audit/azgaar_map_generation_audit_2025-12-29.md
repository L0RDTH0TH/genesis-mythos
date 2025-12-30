# Azgaar Map Generation Deep Audit Report
**Date:** 2025-12-29  
**Issue:** Azgaar map generation never starts despite WorldBuilderWebController receiving Alpine ready + generate requests  
**Status:** ROOT CAUSE IDENTIFIED - Missing Azgaar WebView and Controller in Scene Tree

---

## Executive Summary

The Azgaar map generation system is completely non-functional because **the Azgaar WebView node and WorldBuilderAzgaar controller are missing from the scene tree**. The `WorldBuilderWeb.tscn` scene only contains a single WebView for the UI HTML wrapper (`world_builder.html`), but no separate WebView for embedding the Azgaar map generator.

**Root Cause:** `WorldBuilderAzgaar.gd` script exists but is never instantiated. There is no `WorldBuilderAzgaar.tscn` scene file, and the Azgaar WebView node is not present in `WorldBuilderWeb.tscn`.

---

## Current Symptoms

From latest diagnostic run (2025-12-29 12:37:56):

1. ✅ **WorldBuilderWeb.tscn instantiates correctly**
2. ✅ **world_builder.html loads in main WebView**
3. ✅ **Alpine.js signals "alpine_ready"**
4. ✅ **Step definitions sent successfully**
5. ✅ **On "generate" click: full params + seed received in _handle_generate()**
6. ❌ **Immediate error: "Cannot generate - Azgaar controller not available"**
7. ❌ **Multiple warnings: "WorldBuilderAzgaar controller not found - direct injection will not work"**
8. ❌ **No azgaar_ready ever emitted**
9. ❌ **No execute_js calls succeed on Azgaar functions**
10. ❌ **Center panel shows placeholder text: "Map preview rendered in separate WebView"**

---

## Scene Tree Structure Analysis

### Actual Scene Tree (from diagnostics)

```
/root/WorldRoot (Node3D)
├── MainCamera (Camera3D)
├── DirectionalLight3D
├── WorldEnvironment
├── ProceduralWorld (Node3D)
├── Terrain3DManager (Node3D)
├── DebugOverlay (CanvasLayer)
└── UICanvasLayer (CanvasLayer)
    └── WorldBuilderWebRoot (Control) ← WorldBuilderWebController.gd attached
        └── WebView ← ONLY ONE WebView (for UI HTML)
```

### Expected Scene Tree (what should exist)

```
/root/WorldRoot (Node3D)
├── ...
└── UICanvasLayer (CanvasLayer)
    ├── WorldBuilderWebRoot (Control) ← WorldBuilderWebController.gd
    │   └── WebView ← UI HTML wrapper
    └── WorldBuilderAzgaar (Control) ← WorldBuilderAzgaar.gd attached
        └── WebViewMargin (MarginContainer)
            └── AzgaarWebView (WebView) ← Azgaar map generator
```

---

## Diagnostic Findings

### 1. WebView Node Count

**Found:** Only **1 WebView node** in entire scene tree
- Path: `/root/WorldRoot/UICanvasLayer/WorldBuilderWebRoot/WebView`
- Purpose: Loads `res://assets/ui_web/templates/world_builder.html`
- Class: `WebView` (godot_wry)

**Missing:** Second WebView for Azgaar
- Expected path: `/root/WorldRoot/UICanvasLayer/WorldBuilderAzgaar/WebViewMargin/AzgaarWebView`
- Expected URL: `http://127.0.0.1:8080/index.html` (from AzgaarServer)

### 2. WorldBuilderAzgaar Controller Search

**All tested paths return null:**
- `../WorldBuilderAzgaar` ❌
- `../AzgaarWebView` ❌
- `../WebViewMargin/AzgaarWebView` ❌
- `../../WorldBuilderAzgaar` ❌
- `/root/WorldBuilderAzgaar` ❌
- `/root/UICanvasLayer/WorldBuilderAzgaar` ❌
- `/root/UICanvasLayer/WorldBuilderWebRoot/WorldBuilderAzgaar` ❌

**Method search:** Found **0 nodes** with `trigger_generation_with_options` method

### 3. WorldBuilderAzgaar.gd Script Analysis

**File exists:** `res://scripts/ui/WorldBuilderAzgaar.gd`

**Expected behavior:**
- Attached to a Control node named `WorldBuilderAzgaar`
- Node should have child: `WebViewMargin/AzgaarWebView` (WebView type)
- In `_ready()`, loads Azgaar URL via `web_view.load_url(url)`
- Emits `azgaar_ready` signal when Azgaar JS is ready
- Provides `trigger_generation_with_options()` method for direct JS injection

**Actual state:** Script exists but **never instantiated** - no scene file or node in tree

### 4. WorldBuilderWeb.tscn Analysis

**File:** `res://ui/world_builder/WorldBuilderWeb.tscn`

**Current structure:**
```gdscript
[gd_scene load_steps=4 format=3 uid="uid://world_builder_web_phase2"]

[node name="WorldBuilderWebRoot" type="Control"]
script = ExtResource("1_worldbuilderweb")  # WorldBuilderWebController.gd

[node name="WebView" type="WebView" parent="."]
# Only one WebView - for UI HTML
```

**Missing:**
- No `WorldBuilderAzgaar` node
- No second WebView for Azgaar
- No `WorldBuilderAzgaar.gd` script attachment

### 5. HTML Template Analysis

**File:** `res://assets/ui_web/templates/world_builder.html`

**Center panel (lines 44-49):**
```html
<div class="center-panel" style="background: #1a1a1a; display: flex; align-items: center; justify-content: center;">
    <p style="color: #888; font-style: italic;">Map preview rendered in separate WebView</p>
</div>
```

**Status:** Placeholder text confirms expectation of separate WebView, but it doesn't exist.

---

## Code Flow Analysis

### Current Flow (Broken)

1. `world_root.gd._setup_world_builder_ui_async()` loads `WorldBuilderWeb.tscn`
2. `WorldBuilderWebController._ready()` initializes:
   - Loads `world_builder.html` into single WebView
   - Calls `_find_azgaar_controller()` → **returns null** (no node exists)
   - Logs error: "Azgaar controller NOT FOUND"
3. Alpine.js signals ready → `_handle_alpine_ready()`
   - Retries `_find_azgaar_controller()` → **still null**
   - Calls `_check_and_trigger_initial_generation()` → **skips** (no controller)
4. User clicks "Generate" → `_handle_generate()`
   - Checks `azgaar_controller` → **null**
   - Logs error: "Cannot generate - Azgaar controller not available"
   - **Generation never starts**

### Expected Flow (Should Work)

1. `world_root.gd._setup_world_builder_ui_async()` loads `WorldBuilderWeb.tscn`
2. **ALSO instantiates `WorldBuilderAzgaar` node** (separate scene or child)
3. `WorldBuilderWebController._ready()`:
   - Loads UI HTML
   - `_find_azgaar_controller()` → **finds WorldBuilderAzgaar node**
   - Connects to `azgaar_ready` signal
4. `WorldBuilderAzgaar._ready()`:
   - Loads `http://127.0.0.1:8080/index.html` into AzgaarWebView
   - Waits for Azgaar JS to initialize
   - Emits `azgaar_ready` signal
5. `WorldBuilderWebController._on_azgaar_ready()`:
   - Triggers initial default map generation
6. User clicks "Generate" → `_handle_generate()`
   - Calls `azgaar_controller.trigger_generation_with_options()`
   - **Generation starts successfully**

---

## Root Cause Hypothesis

**PRIMARY ISSUE:** The Azgaar WebView and controller were never added to the scene tree during the migration from the old `WorldBuilderUI.tscn` to the new `WorldBuilderWeb.tscn` architecture.

**Evidence:**
1. `WorldBuilderAzgaar.gd` script exists and is fully implemented
2. No `WorldBuilderAzgaar.tscn` scene file exists
3. `WorldBuilderWeb.tscn` only contains UI WebView
4. `WorldBuilderWebController.gd` expects to find Azgaar controller but never does
5. HTML template has placeholder for "separate WebView" that doesn't exist

**Likely History:**
- Original `WorldBuilderUI.tscn` may have had both WebViews
- During migration to WebView + Alpine.js, only the UI wrapper was migrated
- Azgaar integration was forgotten or assumed to be handled differently
- `WorldBuilderAzgaar.gd` was written but never integrated into scene

---

## Files Inspected

### Scene Files
- ✅ `res://ui/world_builder/WorldBuilderWeb.tscn` - **Read** (only UI WebView)
- ❌ `res://scenes/ui/WorldBuilderUI.tscn` - **Exists but not used** (old implementation)
- ❌ `res://**/*Azgaar*.tscn` - **No scene file found**

### Script Files
- ✅ `res://scripts/ui/WorldBuilderWebController.gd` - **Read** (expects Azgaar controller)
- ✅ `res://scripts/ui/WorldBuilderAzgaar.gd` - **Read** (fully implemented, never instantiated)

### HTML/JS Files
- ✅ `res://assets/ui_web/templates/world_builder.html` - **Read** (placeholder for Azgaar)

---

## Diagnostic Logging Added

Added extensive diagnostic functions to `WorldBuilderWebController.gd`:

1. **`_print_scene_tree_diagnostics()`** - Logs entire scene tree structure
2. **`_print_azgaar_search_diagnostics()`** - Tests all possible Azgaar node paths
3. **`_find_all_webview_nodes()`** - Recursively finds all WebView nodes
4. **`_find_nodes_with_method()`** - Searches entire tree for nodes with specific method

**Enhanced logging in:**
- `_ready()` - Scene tree diagnostics on initialization
- `_find_azgaar_controller()` - Detailed search results
- `_handle_generate()` - Azgaar controller state before generation

---

## Recommendations (Diagnosis Only - No Fixes Yet)

### Required Changes

1. **Add WorldBuilderAzgaar node to scene tree:**
   - Option A: Add as sibling to `WorldBuilderWebRoot` in `WorldBuilderWeb.tscn`
   - Option B: Create separate `WorldBuilderAzgaar.tscn` and instantiate in `world_root.gd`
   - Option C: Add as child of `WorldBuilderWebRoot` (layered WebView)

2. **Create Azgaar WebView node:**
   - Add `WebViewMargin` (MarginContainer) child
   - Add `AzgaarWebView` (WebView) child of MarginContainer
   - Attach `WorldBuilderAzgaar.gd` script to parent Control node

3. **Position and size Azgaar WebView:**
   - Should overlay center panel area of UI
   - Use anchors to match center panel dimensions
   - Ensure proper z-ordering (Azgaar behind UI controls but visible)

4. **Verify Azgaar URL loading:**
   - Ensure `AzgaarServer` is running (✅ confirmed in logs: port 8080)
   - Verify `WorldBuilderAzgaar._ready()` loads `http://127.0.0.1:8080/index.html`
   - Confirm `azgaar_ready` signal is emitted

5. **Test signal connections:**
   - Verify `WorldBuilderWebController` connects to `azgaar_ready`
   - Test initial auto-generation on ready
   - Test manual generation via Generate button

---

## Next Steps

1. **User decision:** Choose integration approach (Option A, B, or C above)
2. **Implementation:** Add Azgaar WebView node to scene tree
3. **Testing:** Verify Azgaar loads, signals emit, generation works
4. **Cleanup:** Remove diagnostic logging (or keep for future debugging)

---

## Additional Notes

- **AzgaarServer is running:** Logs confirm HTTP server started on port 8080
- **AzgaarIntegrator singleton exists:** Referenced in `WorldBuilderAzgaar.gd`
- **No timing issues:** Problem is structural (missing node), not timing
- **godot_wry WebView works:** UI WebView loads successfully, so Azgaar WebView should work too

---

**END OF AUDIT REPORT**
