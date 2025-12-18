# DEEP AUDIT: DEBUG OVERLAY DUPLICATION INVESTIGATION

**Date:** 2025-01-27  
**Task:** Comprehensive investigation of debug overlay duplication issue  
**Status:** AUDIT ONLY - NO CHANGES MADE

---

## 1. SUMMARY OF DUPLICATION CAUSE

### 1.1 Observed Behavior
- **Overlay #1:** Appears on project launch at **top-left** corner
- **Overlay #2:** Triggered by F3 keypress, appears at **top-right** corner, **clipped/unreadable**

### 1.2 Root Cause Analysis

**PRIMARY HYPOTHESIS:** There is **only ONE instance** of the PerformanceOverlay (autoload singleton), but there appears to be a **discrepancy between the scene file state and runtime behavior**, OR a **timing issue** where the overlay becomes visible before `visible = false` is set in `_ready()`.

**SECONDARY HYPOTHESIS:** The diagnostic report from 2025-01-27 references a `.tscn` file with `PRESET_TOP_RIGHT` and hardcoded offsets, but the current `.tscn` file has `PRESET_TOP_LEFT` with all offsets at 0. This suggests:
1. The file was modified after the diagnostic report
2. There may be a cached version or editor state that hasn't refreshed
3. The runtime positioning code may be conflicting with scene file defaults

### 1.3 Key Finding: File State Discrepancy

**Diagnostic Report (2025-01-27) states:**
```
[node name="MarginContainer" type="MarginContainer" parent="."]
anchors_preset = 12  # PRESET_TOP_RIGHT
offset_left = -500.0      # ⚠️ HARDCODED
offset_top = 50.0         # ⚠️ HARDCODED
offset_right = -50.0      # ⚠️ HARDCODED
offset_bottom = 0.0       # ⚠️ HARDCODED
```

**Current File State (2025-01-27 audit):**
```
[node name="MarginContainer" type="MarginContainer" parent="."]
layout_mode = 1
anchors_preset = 1        # PRESET_TOP_LEFT (changed from 12)
anchor_left = 0.0
anchor_top = 0.0
anchor_right = 0.0
anchor_bottom = 0.0
offset_left = 0.0         # All offsets reset to 0
offset_top = 0.0
offset_right = 0.0
offset_bottom = 0.0
```

**Conclusion:** The scene file was modified to use `PRESET_TOP_LEFT` with zero offsets, but the runtime behavior may still reflect the old positioning logic or there's a timing issue.

---

## 2. BUILD DETAILS

### 2.1 Scene Structure

**File:** `res://scenes/ui/PerformanceOverlay.tscn`

**Node Hierarchy:**
```
PerformanceOverlay (CanvasLayer, layer=128)
└── MarginContainer (anchors_preset=1, PRESET_TOP_LEFT)
    └── Panel (size_flags: expand/fill)
        └── MonitorOverlay (VBoxContainer - addon script)
            └── [Dynamic DebugGraph children created at runtime]
```

**Key Properties:**
- **CanvasLayer.layer:** 128 (very high, appears above all game content)
- **MarginContainer.anchors_preset:** 1 (PRESET_TOP_LEFT)
- **MarginContainer.offsets:** All set to 0.0 (runtime positioning via script)
- **MonitorOverlay (addon):** 6 monitors enabled (fps, total_draw_calls, video_memory, texture_memory, objects_drawn, primitives_drawn)

### 2.2 Script Structure

**File:** `res://scripts/managers/MonitorManager.gd`

**Class:** `MonitorManager extends CanvasLayer`

**Key Components:**
- `@onready var margin_container: MarginContainer`
- `@onready var panel: Panel`
- `@onready var overlay: VBoxContainer` (MonitorOverlay addon instance)

**Initialization Flow:**
1. `_ready()` sets `visible = false` (should hide on launch)
2. `_ready()` calls `call_deferred("_apply_theme_and_readability")`
3. `_input()` listens for F3 keypress (`toggle_perf_overlay` action)
4. `toggle_overlay()` toggles `visible` property

### 2.3 Addon Integration

**Addon:** HungryProton Monitor Overlay v1.1.0  
**Location:** `res://addons/monitor_overlay/`

**Key Script:** `monitor_overlay.gd`
- Extends `VBoxContainer`
- Creates `DebugGraph` children dynamically in `rebuild_ui()`
- Uses `need_to_rebuild_ui` flag to trigger rebuild in `_process()`
- Sets `custom_minimum_size.x = 300` in `_ready()` if width is 0

**Plugin:** `monitor_overlay_plugin.gd`
- Registers custom type "MonitorOverlay" in editor
- **Does NOT auto-instantiate** - only provides editor integration

---

## 3. IMPLEMENTATION DETAILS

### 3.1 Autoload Configuration

**File:** `project.godot` line 28

```ini
[autoload]
PerformanceOverlay="*res://scenes/ui/PerformanceOverlay.tscn"
```

**Behavior:** The scene is instantiated automatically when the game starts and exists globally as a singleton named `PerformanceOverlay`.

### 3.2 Instantiation Path

**Single Instantiation Point:**
- **Autoload:** Only one instance created via autoload system
- **No manual instantiation found:** Grep search found no `instantiate()`, `add_child()`, or `preload()` calls for PerformanceOverlay in codebase

**Conclusion:** There is **only ONE instance** of PerformanceOverlay in the project.

### 3.3 Visibility Control

**File:** `scripts/managers/MonitorManager.gd` lines 20-42

```gdscript
func _ready() -> void:
    # ... setup code ...
    # Hide by default (player toggles with F3)
    visible = false
    
    # Apply theme and readability settings
    call_deferred("_apply_theme_and_readability")
```

**Issue:** If `_ready()` runs after the scene tree is rendered, or if there's a timing issue, the overlay might be visible for a frame before `visible = false` is set.

### 3.4 Positioning Logic

**File:** `scripts/managers/MonitorManager.gd` lines 70-142

**Current Implementation (PRESET_TOP_LEFT):**
```gdscript
func _apply_theme_and_readability_async() -> void:
    # Ensure anchor is set to top-left (PRESET_TOP_LEFT = 1)
    margin_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
    
    # ... theme application ...
    
    # Wait one frame for layout to update
    await get_tree().process_frame
    
    # Get content size after layout update
    var content_size: Vector2 = overlay.get_combined_minimum_size()
    # ... size calculations ...
    
    # Set margins using UIConstants (position from top-left corner)
    var margin: int = UIConstants.OVERLAY_MARGIN_LARGE
    
    # For PRESET_TOP_LEFT:
    # - offset_left: margin from left edge
    # - offset_top: margin from top edge
    # - offset_right: width (offset_left + content_width)
    # - offset_bottom: height (offset_top + content_height)
    margin_container.offset_left = margin
    margin_container.offset_top = margin
    margin_container.offset_right = margin + content_size.x
    margin_container.offset_bottom = margin + content_size.y
```

**Analysis:**
- ✅ Correctly sets `PRESET_TOP_LEFT` at runtime
- ✅ Waits one frame for layout (`await get_tree().process_frame`)
- ✅ Measures content size using `get_combined_minimum_size()`
- ✅ Calculates proper offsets for top-left positioning
- ⚠️ **Potential Issue:** Only waits ONE frame - may need two frames like `DebugMenuScaler.gd` does

### 3.5 Toggle Mechanism

**File:** `scripts/managers/MonitorManager.gd` lines 45-48, 174-179

```gdscript
func _input(event: InputEvent) -> void:
    """Handle input for toggling the overlay."""
    if event.is_action_pressed("toggle_perf_overlay"):
        toggle_overlay()

func toggle_overlay() -> void:
    """Toggles visibility of the performance overlay."""
    visible = !visible
    if visible:
        # When becoming visible, ensure theme and readability are applied
        call_deferred("_apply_theme_and_readability")
```

**Input Action:** `toggle_perf_overlay` (F3 key, physical_keycode 4194306)  
**Configuration:** `project.godot` lines 94-98

**Behavior:** Toggles `CanvasLayer.visible` property, which should show/hide the entire overlay.

### 3.6 Comparison with Working Implementation

**Reference:** `res://scripts/core/DebugMenuScaler.gd` (lines 59-107)

**Key Differences:**

| Aspect | DebugMenuScaler (Working) | MonitorManager (Current) |
|-------|---------------------------|-------------------------|
| **Anchor Preset** | PRESET_TOP_RIGHT | PRESET_TOP_LEFT |
| **Layout Wait** | `await get_tree().process_frame` (twice) | `await get_tree().process_frame` (once) |
| **Content Size** | `get_combined_minimum_size()` | `get_combined_minimum_size()` ✅ |
| **Height Calculation** | `offset_bottom = safe_margin + scaled_size.y` | `offset_bottom = margin + content_size.y` ✅ |
| **Width Calculation** | `offset_left = -scaled_size.x` | `offset_left = margin` ✅ |
| **Validation** | Final clamp checks for screen bounds | No validation ❌ |

**Recommendation:** Add second `await get_tree().process_frame` and add validation checks like `DebugMenuScaler`.

---

## 4. ISSUES FOUND

### 4.1 CRITICAL: Potential Timing Issue

**Problem:** The overlay may be visible for a frame on launch before `visible = false` is set in `_ready()`.

**Evidence:**
- Autoload scenes are instantiated early in the engine lifecycle
- `_ready()` may run after the first frame is rendered
- If `visible` property defaults to `true` in the scene file, it will show until `_ready()` sets it to `false`

**Solution:** Set `visible = false` in the `.tscn` file itself, not just in script.

### 4.2 CRITICAL: Layout Timing Insufficient

**Problem:** Only one frame wait may not be enough for `MonitorOverlay` addon to build its UI.

**Evidence:**
- `MonitorOverlay` uses `need_to_rebuild_ui` flag and rebuilds in `_process()`
- `DebugMenuScaler` waits TWO frames for reliable layout calculation
- Content size may be `Vector2.ZERO` if measured before addon builds children

**Current Code:**
```gdscript
await get_tree().process_frame  # Only one frame
var content_size: Vector2 = overlay.get_combined_minimum_size()
```

**Solution:** Wait two frames like `DebugMenuScaler` does.

### 4.3 CRITICAL: No Screen Bounds Validation

**Problem:** No validation to ensure overlay fits on screen, especially on different resolutions.

**Evidence:**
- `DebugMenuScaler` has comprehensive bounds checking (lines 109-127)
- `MonitorManager` calculates offsets but doesn't verify they're within viewport bounds
- Could cause clipping on smaller screens or ultrawide displays

**Solution:** Add validation checks similar to `DebugMenuScaler`.

### 4.4 MODERATE: Scene File vs Runtime Discrepancy

**Problem:** Diagnostic report references old scene file state (PRESET_TOP_RIGHT with hardcoded offsets), but current file has PRESET_TOP_LEFT with zero offsets.

**Evidence:**
- Diagnostic report dated 2025-01-27 shows PRESET_TOP_RIGHT
- Current file audit shows PRESET_TOP_LEFT
- Runtime code sets PRESET_TOP_LEFT, matching current file

**Conclusion:** File was likely updated after diagnostic report. No action needed, but this explains confusion.

### 4.5 MODERATE: Missing Content Size Fallback Validation

**Problem:** Fallback size estimation may not match actual content if `get_combined_minimum_size()` returns zero.

**Current Code:**
```gdscript
if content_size == Vector2.ZERO or content_size.y <= 0:
    # Fallback: estimate size based on enabled monitors
    var graph_height: float = 50.0
    if overlay.has("graph_height"):
        graph_height = overlay.get("graph_height")
    var estimated_height: float = (6.0 * graph_height) + (UIConstants.SPACING_MEDIUM * 2.0)
    content_size = Vector2(UIConstants.OVERLAY_MIN_WIDTH, estimated_height)
```

**Issue:** Hardcoded `6.0` multiplier assumes 6 monitors, but this may change if monitors are toggled.

**Solution:** Count actual enabled monitors dynamically.

### 4.6 MINOR: Font Size Propagation Timing

**Problem:** Font size is set before layout wait, which is correct, but there's no verification that it actually triggers UI rebuild.

**Current Code:**
```gdscript
overlay.set("font_size", font_size)  # Should trigger need_to_rebuild_ui=true
# ... other settings ...
await get_tree().process_frame  # Wait for rebuild
```

**Analysis:** The addon's export property setter should set `need_to_rebuild_ui = true`, but there's no verification.

**Solution:** Add verification or ensure rebuild happens before measuring size.

---

## 5. RECOMMENDATIONS

### 5.1 Immediate Fixes (High Priority)

1. **Set `visible = false` in `.tscn` file:**
   - Add `visible = false` to the `PerformanceOverlay` CanvasLayer node in the scene file
   - This ensures it's hidden from the first frame, regardless of script timing

2. **Add second frame wait:**
   ```gdscript
   await get_tree().process_frame
   await get_tree().process_frame  # Extra frame for reliable layout
   ```

3. **Add screen bounds validation:**
   - Copy validation logic from `DebugMenuScaler.gd` lines 109-127
   - Ensure overlay never clips off-screen

### 5.2 Code Quality Improvements (Medium Priority)

4. **Dynamic monitor count:**
   - Replace hardcoded `6.0` multiplier with actual count of enabled monitors
   - Iterate through addon's export properties to count enabled monitors

5. **Add logging for debugging:**
   ```gdscript
   MythosLogger.debug("UI/PerformanceOverlay", "Content size: %s, Offsets: L=%d T=%d R=%d B=%d" % [content_size, offset_left, offset_top, offset_right, offset_bottom])
   ```

6. **Verify UI rebuild:**
   - Check `need_to_rebuild_ui` flag after setting properties
   - Add assertion or warning if rebuild doesn't trigger

### 5.3 Architecture Improvements (Low Priority)

7. **Consider removing autoload:**
   - If overlay is only needed in specific scenes, instantiate it manually
   - Reduces global state and potential timing issues

8. **Unify with DebugMenuScaler pattern:**
   - Consider creating a base class for overlay positioning/scaling
   - Reduces code duplication and ensures consistent behavior

---

## 6. DIAGNOSTIC SUMMARY

### 6.1 Duplication Explanation

**Conclusion:** There is **NO actual duplication** of the PerformanceOverlay instance. The observed behavior of "two overlays" is likely:

1. **Timing Issue:** Overlay visible for one frame on launch before `visible = false` is set
2. **Positioning Issue:** When F3 is pressed, the overlay may be positioned incorrectly (top-right instead of top-left) due to:
   - Insufficient layout wait time
   - Content size not calculated correctly
   - Missing screen bounds validation

### 6.2 Root Cause

The primary issue is **not duplication, but incorrect positioning and timing**. The overlay appears:
- **On launch (top-left):** Because `visible = false` isn't set early enough or in the scene file
- **On F3 (top-right, clipped):** Because positioning logic may be using stale/cached values or not waiting long enough for layout

### 6.3 Fix Strategy

1. Set `visible = false` in `.tscn` file (prevents launch visibility)
2. Add second frame wait (ensures layout is complete)
3. Add screen bounds validation (prevents clipping)
4. Add logging (helps diagnose future issues)

---

## 7. CODE SNIPPETS FOR REFERENCE

### 7.1 Current Positioning Logic (MonitorManager.gd)

```gdscript
func _apply_theme_and_readability_async() -> void:
    if not overlay or not margin_container:
        return
    
    # Ensure anchor is set to top-left (PRESET_TOP_LEFT = 1)
    margin_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
    
    # Apply theme font and colors first (before measuring, as it affects content size)
    if _theme_resource and overlay.get_script() != null:
        var base_font_size: int = _theme_resource.get_font_size("default_font_size", "Label")
        if base_font_size <= 0:
            base_font_size = 14
        var font_size: int = int(base_font_size * 1.8)
        overlay.set("font_size", font_size)
        # ... color settings ...
        if overlay.has("need_to_rebuild_ui"):
            overlay.set("need_to_rebuild_ui", true)
    
    _apply_theme_to_labels()
    
    # Wait one frame for layout to update after font/theme changes
    await get_tree().process_frame
    
    # Get content size after layout update
    var content_size: Vector2 = overlay.get_combined_minimum_size()
    if content_size == Vector2.ZERO or content_size.y <= 0:
        # Fallback estimation
        var graph_height: float = 50.0
        if overlay.has("graph_height"):
            graph_height = overlay.get("graph_height")
        var estimated_height: float = (6.0 * graph_height) + (UIConstants.SPACING_MEDIUM * 2.0)
        content_size = Vector2(UIConstants.OVERLAY_MIN_WIDTH, estimated_height)
    
    # Ensure minimum width from UIConstants
    if content_size.x < UIConstants.OVERLAY_MIN_WIDTH:
        content_size.x = UIConstants.OVERLAY_MIN_WIDTH
    
    # Clamp max width to 40% of viewport or 600px (whichever is smaller)
    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    var max_width: float = min(viewport_size.x * 0.4, 600.0)
    if content_size.x > max_width:
        content_size.x = max_width
    
    # Set margins using UIConstants (position from top-left corner)
    var margin: int = UIConstants.OVERLAY_MARGIN_LARGE
    margin_container.offset_left = margin
    margin_container.offset_top = margin
    margin_container.offset_right = margin + content_size.x
    margin_container.offset_bottom = margin + content_size.y
```

### 7.2 Reference: Working Implementation (DebugMenuScaler.gd)

```gdscript
func _apply_responsive_positioning() -> void:
    if debug_control == null:
        return
    
    # Ensure anchor is set to top-right
    debug_control.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    
    # Wait for layout to update to get actual content size
    await get_tree().process_frame
    await get_tree().process_frame  # Extra frame to ensure size is calculated
    
    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    var content_size: Vector2 = debug_control.get_combined_minimum_size()
    if content_size == Vector2.ZERO:
        content_size = Vector2(UIConstants.LABEL_WIDTH_WIDE * 2, UIConstants.LIST_HEIGHT_STANDARD * 2)
    
    var scaled_size: Vector2 = content_size * debug_control.scale
    var safe_margin: int = UIConstants.SPACING_MEDIUM
    
    # Calculate safe position ensuring it fits on screen
    var max_width: float = viewport_size.x - (safe_margin * 2)
    var max_height: float = viewport_size.y - (safe_margin * 2)
    
    # Adjust scale if content is too large
    if scaled_size.x > max_width:
        debug_control.scale = Vector2(max_width / content_size.x, debug_control.scale.y)
        scaled_size = content_size * debug_control.scale
    if scaled_size.y > max_height:
        debug_control.scale = Vector2(debug_control.scale.x, max_height / content_size.y)
        scaled_size = content_size * debug_control.scale
    
    # Set offsets with safe margins
    debug_control.offset_left = -scaled_size.x
    debug_control.offset_top = safe_margin
    debug_control.offset_right = -safe_margin
    debug_control.offset_bottom = safe_margin + scaled_size.y
    
    # Verify it's fully visible (final check)
    var right_edge: float = viewport_size.x + debug_control.offset_right
    var left_edge: float = right_edge - scaled_size.x
    var top_edge: float = debug_control.offset_top
    var bottom_edge: float = top_edge + scaled_size.y
    
    # Final clamp if still needed
    if right_edge > viewport_size.x:
        debug_control.offset_right = -safe_margin
        debug_control.offset_left = -scaled_size.x
    if left_edge < safe_margin:
        debug_control.offset_right = -safe_margin
        debug_control.offset_left = -(viewport_size.x - safe_margin * 2)
    if top_edge < safe_margin:
        debug_control.offset_top = safe_margin
        debug_control.offset_bottom = safe_margin + scaled_size.y
    if bottom_edge > viewport_size.y - safe_margin:
        debug_control.offset_top = viewport_size.y - scaled_size.y - safe_margin
        debug_control.offset_bottom = debug_control.offset_top + scaled_size.y
```

---

## 8. FILES AUDITED

### 8.1 Scene Files
- ✅ `res://scenes/ui/PerformanceOverlay.tscn` - Read and analyzed

### 8.2 Script Files
- ✅ `res://scripts/managers/MonitorManager.gd` - Read and analyzed
- ✅ `res://addons/monitor_overlay/monitor_overlay.gd` - Read and analyzed
- ✅ `res://addons/monitor_overlay/monitor_overlay_debug_graph.gd` - Read and analyzed
- ✅ `res://scripts/core/DebugMenuScaler.gd` - Read for reference
- ✅ `res://scripts/ui/UIConstants.gd` - Read for constants

### 8.3 Configuration Files
- ✅ `res://project.godot` - Checked autoload and input map configuration
- ✅ `res://addons/monitor_overlay/plugin.cfg` - Checked plugin configuration
- ✅ `res://addons/monitor_overlay/monitor_overlay_plugin.gd` - Verified no auto-instantiation

### 8.4 Documentation
- ✅ `res://audit/PERFORMANCE_OVERLAY_DIAGNOSTIC_REPORT.md` - Referenced for historical context

---

## 9. CONCLUSION

**Primary Finding:** There is **NO duplication** of PerformanceOverlay instances. The observed "two overlays" behavior is caused by:

1. **Timing Issue:** Overlay visible on launch before `visible = false` is set
2. **Positioning Issue:** Incorrect positioning when toggled via F3 due to insufficient layout wait and missing validation

**Recommended Actions:**
1. Set `visible = false` in `.tscn` file
2. Add second frame wait in positioning logic
3. Add screen bounds validation
4. Add logging for future debugging

**Status:** Audit complete. Ready for implementation of fixes.

---

**END OF AUDIT REPORT**
