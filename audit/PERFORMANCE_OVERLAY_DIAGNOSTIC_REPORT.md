# CURRENT PERFORMANCE OVERLAY IMPLEMENTATION DIAGNOSTIC

**Date:** 2025-01-27  
**Task:** Diagnostic analysis of PerformanceOverlay clipping/unreadability issues  
**Status:** DIAGNOSTIC ONLY - NO CHANGES MADE

---

## 1. LOCATION & INSTANTIATION

### 1.1 Scene File Location
- **Scene Path:** `res://scenes/ui/PerformanceOverlay.tscn`
- **Script:** `res://scripts/managers/MonitorManager.gd`
- **Addon Script:** `res://addons/monitor_overlay/monitor_overlay.gd`

### 1.2 Autoload Configuration
- **Registered as autoload singleton** in `project.godot` line 28:
  ```
  PerformanceOverlay="*res://scenes/ui/PerformanceOverlay.tscn"
  ```
- This means the scene is instantiated automatically when the game starts and exists globally.

### 1.3 Node Hierarchy (from PerformanceOverlay.tscn)
```
PerformanceOverlay (CanvasLayer, layer=128)
└── MarginContainer
    └── Panel
        └── MonitorOverlay (VBoxContainer - addon script)
```

---

## 2. CURRENT POSITIONING & SIZING CONFIGURATION

### 2.1 Hardcoded Values in .tscn File
**File:** `res://scenes/ui/PerformanceOverlay.tscn` (lines 11-24)

```gdscript
[node name="MarginContainer" type="MarginContainer" parent="."]
layout_mode = 1
anchors_preset = 12  # PRESET_TOP_RIGHT
anchor_left = 1.0
anchor_top = 0.0
anchor_right = 1.0
anchor_bottom = 0.0
offset_left = -500.0      # ⚠️ HARDCODED
offset_top = 50.0         # ⚠️ HARDCODED
offset_right = -50.0      # ⚠️ HARDCODED
offset_bottom = 0.0       # ⚠️ HARDCODED
grow_horizontal = 0
grow_vertical = 2
theme = ExtResource("2_0")
```

### 2.2 Runtime Override Attempt in MonitorManager.gd
**File:** `res://scripts/managers/MonitorManager.gd` (lines 61-106)

The `_apply_theme_and_sizing()` function attempts to override these offsets:

```gdscript
func _apply_theme_and_sizing() -> void:
    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    
    # Calculate dynamic width (25% of viewport, clamped)
    var overlay_width: float = clamp(
        viewport_size.x * 0.25,
        UIConstants.OVERLAY_MIN_WIDTH,  # 450
        800.0
    )
    
    # Set MarginContainer offsets using UIConstants (anchored to top-right)
    margin_container.offset_left = -overlay_width
    margin_container.offset_top = UIConstants.OVERLAY_MARGIN_LARGE  # 50
    margin_container.offset_right = -UIConstants.OVERLAY_MARGIN_LARGE  # -50
    margin_container.offset_bottom = 0.0
    
    # Set minimum width based on viewport size
    overlay.custom_minimum_size.x = overlay_width
```

### 2.3 UIConstants Values
**File:** `res://scripts/ui/UIConstants.gd` (lines 52-53)
```gdscript
const OVERLAY_MIN_WIDTH: int = 450  # Minimum width for performance monitor overlay
const OVERLAY_MARGIN_LARGE: int = 50  # Larger margin to prevent clipping
```

---

## 3. IDENTIFIED ISSUES

### 3.1 CRITICAL: Offset Calculation Logic Error

**Problem:** The offset calculation in `MonitorManager._apply_theme_and_sizing()` does not correctly account for how `PRESET_TOP_RIGHT` anchors work.

**How PRESET_TOP_RIGHT Offsets Work:**
- When `anchor_left = 1.0` and `anchor_right = 1.0` (top-right preset):
  - `offset_left`: Negative value extends **leftward** from the right edge (defines the width)
  - `offset_right`: Negative value creates margin from right edge (inset)
  - `offset_top`: Positive value creates margin from top edge
  - `offset_bottom`: Positive value sets bottom edge **from top** (defines height)

**Current Code Issue:**
```gdscript
margin_container.offset_left = -overlay_width  # ✓ Correct
margin_container.offset_bottom = 0.0           # ✗ INCORRECT - leaves height undefined!
```

**Expected Behavior (from DebugMenuScaler.gd reference):**
```gdscript
offset_left = -scaled_size.x           # Width from right edge
offset_top = safe_margin               # Top margin
offset_right = -safe_margin            # Right margin inset
offset_bottom = safe_margin + scaled_size.y  # Height = top margin + content height
```

### 3.2 CRITICAL: No Height Calculation

**Problem:** The code sets `offset_bottom = 0.0`, which means the `MarginContainer` has **zero height** when anchored to top-right. This causes the content to be clipped vertically.

**Root Cause:** The script never calculates the actual height of the `MonitorOverlay` content. The `MonitorOverlay` VBoxContainer's height depends on:
- Number of active monitors (6 enabled: fps, total_draw_calls, video_memory, texture_memory, objects_drawn, primitives_drawn)
- Each monitor has a `graph_height = 50` pixels (from .tscn line 46)
- Font size and text labels
- Background panels

**Missing Logic:** Should calculate content height using `get_combined_minimum_size()` or measure actual size after layout.

### 3.3 CONFLICT: Hardcoded vs Runtime Offsets

**Problem:** The `.tscn` file has hardcoded offsets (`offset_left = -500.0`, etc.) that are then overridden in script. However, if the script runs before the scene is fully laid out, or if there's a timing issue, the hardcoded values may persist.

**Recommendation:** Either:
- Remove hardcoded offsets from `.tscn` (set to 0) and let script handle everything, OR
- Remove runtime offset overrides and fix the hardcoded values

### 3.4 CONFLICT: Width Setting vs Content Size

**Problem:** The script sets `overlay.custom_minimum_size.x = overlay_width`, but:
1. The `MonitorOverlay` addon script (`monitor_overlay.gd` line 160-161) sets `custom_minimum_size.x = 300` in `_ready()` if it's 0
2. The actual content width may differ from the calculated `overlay_width`
3. Setting minimum size doesn't guarantee the overlay will actually be that width if content is smaller

**Order of Operations Issue:**
- `MonitorOverlay._ready()` runs → sets `custom_minimum_size.x = 300` (if 0)
- `MonitorManager._ready()` runs → calls `_apply_theme_and_sizing()` → sets `overlay.custom_minimum_size.x = overlay_width`
- But the MarginContainer's offset_left is set independently, creating a mismatch

### 3.5 FONT SIZE SETTING METHOD

**Potential Issue:** The script uses `overlay.set("font_size", font_size)` to set the addon's export property. This should work, but there's no verification that it actually propagates to the child `DebugGraph` nodes that do the actual text drawing.

**In monitor_overlay.gd:**
- Line 149: `@export var font_size := 14`
- Line 259: Font size is passed to DebugGraph: `graph.font_size = font_size`

**In monitor_overlay_debug_graph.gd:**
- Line 34: `var font_size: int = 14` (instance variable)
- Line 40: Used in `draw_string()`: `draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)`

**Issue:** The font_size is multiplied by 1.5 in MonitorManager (line 95), but if the property setter doesn't trigger `need_to_rebuild_ui = true`, the UI won't rebuild with the new font size.

### 3.6 TIMING: When Sizing Runs

**Problem:** `_apply_theme_and_sizing()` is called:
1. In `_ready()` (line 35)
2. In `_on_viewport_resized()` (line 58)
3. In `toggle_overlay()` when visible becomes true (line 142)

**Potential Race Condition:**
- At `_ready()`, the `MonitorOverlay` may not have built its UI yet (it uses `need_to_rebuild_ui` flag and rebuilds in `_process()`)
- The content size calculation happens before the overlay's children (DebugGraph nodes) exist
- The MarginContainer offsets are set before knowing the actual content size

---

## 4. TOGGLE MECHANISM

### 4.1 Input Action
**Action Name:** `toggle_perf_overlay`  
**Key Binding:** F3 (physical_keycode 4194306)  
**Configuration:** `project.godot` lines 94-98

### 4.2 Toggle Handler
**File:** `res://scripts/managers/MonitorManager.gd` (lines 44-47, 138-143)

```gdscript
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_perf_overlay"):
        toggle_overlay()

func toggle_overlay() -> void:
    visible = !visible
    if visible:
        _apply_theme_and_sizing()
        _apply_theme_to_labels()
```

**Status:** ✓ Working correctly - toggles CanvasLayer.visible property

---

## 5. ENGINE DEBUG OVERLAY STATUS

**File:** `project.godot` lines 100-107

```
[debug]
settings/show_fps=false
settings/show_memory=false
settings/show_collision_shapes=false
settings/show_navigation=false
settings/show_paths=false
settings/show_visibility_rects=false
```

**Status:** ✓ All engine debug overlays are disabled - no conflict

---

## 6. CANVAS LAYER CONFIGURATION

**Configuration:**
- **Layer:** 128 (very high, appears above all game content)
- **Type:** CanvasLayer (correct for overlay UI)
- **Visibility:** Starts as `visible = false`, toggled via F3

**Status:** ✓ Configuration is correct

---

## 7. SUMMARY OF ROOT CAUSES

### Primary Issues:
1. **Zero Height:** `offset_bottom = 0.0` when using PRESET_TOP_RIGHT means zero height, causing vertical clipping
2. **No Content Size Calculation:** Script never measures actual MonitorOverlay content height
3. **Width Mismatch:** Calculated width may not match actual content requirements
4. **Timing:** Sizing runs before MonitorOverlay builds its child nodes (DebugGraph instances)

### Secondary Issues:
1. **Hardcoded Offsets:** .tscn has hardcoded offsets that conflict with runtime overrides
2. **Font Size Propagation:** May not properly rebuild UI after font size change
3. **Offset Logic:** Doesn't follow the same pattern as DebugMenuScaler.gd (which works correctly)

---

## 8. REFERENCE: WORKING IMPLEMENTATION

**File:** `res://scripts/core/DebugMenuScaler.gd` (lines 65-107)

This script successfully handles a top-right anchored overlay. Key differences:

1. **Waits for layout:** Uses `await get_tree().process_frame` (twice) to ensure content size is calculated
2. **Measures content:** Uses `get_combined_minimum_size()` to get actual content dimensions
3. **Calculates height properly:** Sets `offset_bottom = safe_margin + scaled_size.y`
4. **Validates bounds:** Final clamp check ensures content fits on screen

**Recommended Pattern:**
```gdscript
# Wait for layout
await get_tree().process_frame
await get_tree().process_frame

# Get actual content size
var content_size: Vector2 = overlay.get_combined_minimum_size()

# Calculate proper offsets for PRESET_TOP_RIGHT
margin_container.offset_left = -content_size.x
margin_container.offset_top = UIConstants.OVERLAY_MARGIN_LARGE
margin_container.offset_right = -UIConstants.OVERLAY_MARGIN_LARGE
margin_container.offset_bottom = UIConstants.OVERLAY_MARGIN_LARGE + content_size.y
```

---

## 9. RECOMMENDATIONS FOR FIX (NOT IMPLEMENTED)

1. **Remove hardcoded offsets from .tscn** - Set all offsets to 0
2. **Calculate content height** - Use `get_combined_minimum_size()` or measure after layout
3. **Fix offset_bottom** - Set to `margin + content_height` instead of `0.0`
4. **Add layout wait** - Use `await get_tree().process_frame` before sizing
5. **Follow DebugMenuScaler pattern** - Use the same proven approach
6. **Remove custom_minimum_size.x override** - Let content determine natural width, or set it properly with height
7. **Verify font size propagation** - Ensure setting font_size triggers UI rebuild

---

**END OF DIAGNOSTIC REPORT**
