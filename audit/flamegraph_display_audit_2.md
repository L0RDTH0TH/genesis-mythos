# Flame Graph Display Audit 2 – No Visual Output

**Date:** 2025-01-20  
**Investigator:** Auto (Cursor AI)  
**Issue:** Flame graph completely invisible in FLAME mode (no graph, no status messages, blank/dark panel)

---

## Current Symptom

When switching to FLAME mode via F3:
- Bottom panel shows **nothing at all** (blank/dark)
- No flame graph bars
- No status messages ("Collecting samples...", "Aggregating data...")
- No text overlay
- Waterfall graph was previously visible in DETAILED mode, but entire bottom panel is now blank in FLAME mode

This suggests the **entire bottom graph bar container is hidden** rather than just the flame graph control being empty.

---

## Files Reviewed

### 1. `res://scripts/ui/overlays/PerformanceMonitor.gd`

**Key Findings:**

**Line 26:** FlameGraphControl reference
```gdscript
@onready var flame_graph_control: Control = $BottomGraphBar/MarginContainer/BottomGraphsContainer/FlameGraphControl
```

**Lines 362-382:** FLAME mode setup
```gdscript
Mode.FLAME:
    # ... other setup ...
    if bottom_graph_bar:
        bottom_graph_bar.visible = true
    _update_bottom_graph_bar()
    # Show flame graph, hide waterfall
    if waterfall_control:
        waterfall_control.visible = false
    if flame_graph_control:
        flame_graph_control.visible = true
    # Start flame profiling
    if FlameGraphProfiler:
        FlameGraphProfiler.start_profiling()
```

**Lines 554-579:** `_update_bottom_graph_bar()` function
```gdscript
func _update_bottom_graph_bar() -> void:
    """Update bottom graph bar positioning and visibility."""
    if not bottom_graph_bar:
        return
    
    # ... positioning code ...
    
    # Set visibility based on mode
    bottom_graph_bar.visible = (current_mode == Mode.DETAILED)  # ⚠️ BUG HERE!
    
    MythosLogger.debug("PerformanceMonitor", "Bottom graph bar updated (visible: %s, height: %d)" % [bottom_graph_bar.visible, UIConstants.BOTTOM_GRAPH_BAR_HEIGHT])
```

**CRITICAL BUG IDENTIFIED:** Line 577 sets `bottom_graph_bar.visible = (current_mode == Mode.DETAILED)`, which means:
- ✅ DETAILED mode: Bottom bar is visible
- ❌ FLAME mode: Bottom bar is **hidden** (even though `set_mode()` sets it to `true` on line 371, `_update_bottom_graph_bar()` immediately hides it again!)

**Execution Order Issue:**
1. `set_mode(Mode.FLAME)` is called
2. Line 371: `bottom_graph_bar.visible = true` (correct)
3. Line 372: `_update_bottom_graph_bar()` is called
4. Line 577: `bottom_graph_bar.visible = (current_mode == Mode.DETAILED)` → **FALSE** (hides it!)
5. Lines 374-377: FlameGraphControl visibility is set, but parent is hidden, so it doesn't matter

### 2. `res://scenes/ui/overlays/PerformanceMonitor.tscn`

**Key Findings:**

**Lines 73-88:** BottomGraphBar PanelContainer
```gdscript
[node name="BottomGraphBar" type="PanelContainer" parent="."]
# ... anchors and positioning ...
visible = false  # Hidden by default
```

**Lines 144-155:** FlameGraphControl
```gdscript
[node name="FlameGraphControl" type="Control" parent="BottomGraphBar/MarginContainer/BottomGraphsContainer"]
# ... anchors and size flags ...
visible = false  # Hidden by default
```

**Structure:** Both controls are siblings under `BottomGraphsContainer`, which is correct. The issue is the parent `BottomGraphBar` is being hidden.

### 3. `res://scripts/ui/overlays/FlameGraphControl.gd`

**Key Findings:**

**Lines 270-305:** `_draw()` function with status messages
```gdscript
func _draw() -> void:
    """Draw the flame graph with nested rectangles and status feedback."""
    MythosLogger.debug("FlameGraphControl", "_draw() called - size: %s, call_tree empty: %s, total_time_ms: %.2f" % [
        size, call_tree.is_empty(), _total_time_ms
    ])
    
    # Always draw background
    var bg_color: Color = Color(0.1, 0.08, 0.06, 0.9)
    draw_rect(Rect2(Vector2.ZERO, size), bg_color)
    
    # If no data yet, show helpful status
    if call_tree.is_empty():
        _draw_status_message("Collecting samples...\nPress F3 to cycle modes")
        return
    
    if _total_time_ms <= 0.1:
        _draw_status_message("Aggregating data...\nSamples collected but processing")
        return
    
    # ... rest of drawing code ...
```

**Lines 473-485:** `_draw_status_message()` helper
```gdscript
func _draw_status_message(message: String) -> void:
    """Draw centered multi-line status text."""
    var lines: PackedStringArray = message.split("\n")
    var font: Font = ThemeDB.fallback_font
    # ... drawing code ...
```

**Analysis:** The `_draw()` function is properly implemented with status messages. However, if the control is not visible or has zero size, `_draw()` may not be called or may draw nothing visible.

**Lines 80-82:** Signal connection in `_ready()`
```gdscript
# Connect to profiler aggregation signal for immediate updates
if FlameGraphProfiler and FlameGraphProfiler.has_signal("aggregation_complete"):
    FlameGraphProfiler.aggregation_complete.connect(_on_aggregation_complete)
```

**Analysis:** Signal connection looks correct, but if the control is hidden, updates won't be visible.

### 4. `res://core/singletons/FlameGraphProfiler.gd`

**Key Findings:**

**Lines 30-31:** Signal definition
```gdscript
## Signal emitted when aggregation completes
signal aggregation_complete(samples_processed: int)
```

**Lines 244-261:** `_periodic_aggregate()` with signal emission
```gdscript
func _periodic_aggregate() -> void:
    """Periodically aggregate samples into call tree for visualization."""
    if not is_profiling_enabled:
        return
    
    # ... aggregation logic ...
    
    if samples_to_aggregate.size() > 0:
        _aggregate_samples_to_tree(samples_to_aggregate)
        # ...
        var processed_count: int = samples_to_aggregate.size()
        aggregation_complete.emit(processed_count)
```

**Analysis:** Signal emission is correct. The profiler should be working and emitting signals.

---

## Test Observations

**From Code Analysis (Unable to interactively test due to automation constraints):**

1. **Visibility Chain:**
   - `BottomGraphBar` (parent) → `visible = false` in FLAME mode (due to bug)
   - `FlameGraphControl` (child) → `visible = true` in FLAME mode (correct, but parent hidden)
   - Result: Control is hidden because parent is hidden

2. **Expected Behavior:**
   - When F3 cycles to FLAME mode:
     - `set_mode(Mode.FLAME)` sets `bottom_graph_bar.visible = true` (line 371)
     - Then calls `_update_bottom_graph_bar()` (line 372)
     - `_update_bottom_graph_bar()` **immediately hides it again** (line 577)

3. **Waterfall vs Flame:**
   - In DETAILED mode: `bottom_graph_bar.visible = true` (correct)
   - In FLAME mode: `bottom_graph_bar.visible = false` (incorrect - should be true)

---

## Most Likely Causes (Prioritized)

### 1. **PRIMARY BUG: `_update_bottom_graph_bar()` Visibility Logic** ⚠️ **CONFIRMED**

**Evidence:**
- Line 577 in `PerformanceMonitor.gd`: `bottom_graph_bar.visible = (current_mode == Mode.DETAILED)`
- This only shows the bottom bar in DETAILED mode, not FLAME mode
- Even though `set_mode(Mode.FLAME)` sets `bottom_graph_bar.visible = true` on line 371, `_update_bottom_graph_bar()` is called immediately after and hides it again

**Impact:** 100% - This is definitely the root cause. The entire bottom panel is hidden in FLAME mode.

**Fix Required:**
```gdscript
# Line 577 should be:
bottom_graph_bar.visible = (current_mode == Mode.DETAILED or current_mode == Mode.FLAME)
```

### 2. **Secondary: Execution Order Issue**

**Evidence:**
- `set_mode()` sets visibility, then calls `_update_bottom_graph_bar()` which overrides it
- The visibility check in `_update_bottom_graph_bar()` doesn't account for FLAME mode

**Impact:** Medium - This is a design issue where the helper function conflicts with the main function's intent.

**Fix Required:**
- Either remove the visibility line from `_update_bottom_graph_bar()` and handle it in `set_mode()` only
- Or update the condition to include FLAME mode

### 3. **Tertiary: Size/Anchoring Issues (Unlikely but Possible)**

**Evidence:**
- FlameGraphControl has proper anchors (`PRESET_FULL_RECT`) and size flags
- Custom minimum size is set in scene: `custom_minimum_size = Vector2(0, 480)`

**Impact:** Low - If the control were visible, it should have proper size. But since parent is hidden, this is moot.

---

## Recommendations

### Immediate Fix (Critical)

**File:** `res://scripts/ui/overlays/PerformanceMonitor.gd`

**Location:** Line 577 in `_update_bottom_graph_bar()`

**Change:**
```gdscript
# BEFORE:
bottom_graph_bar.visible = (current_mode == Mode.DETAILED)

# AFTER:
bottom_graph_bar.visible = (current_mode == Mode.DETAILED or current_mode == Mode.FLAME)
```

**Alternative (Cleaner):**
Remove the visibility line from `_update_bottom_graph_bar()` entirely and handle visibility only in `set_mode()`:

```gdscript
func _update_bottom_graph_bar() -> void:
    """Update bottom graph bar positioning and visibility."""
    if not bottom_graph_bar:
        return
    
    # ... positioning code ...
    
    # REMOVE THIS LINE - visibility is handled in set_mode()
    # bottom_graph_bar.visible = (current_mode == Mode.DETAILED)
    
    MythosLogger.debug("PerformanceMonitor", "Bottom graph bar updated (visible: %s, height: %d)" % [bottom_graph_bar.visible, UIConstants.BOTTOM_GRAPH_BAR_HEIGHT])
```

### Additional Verification Steps

1. **After Fix:**
   - Run project and cycle to FLAME mode
   - Verify `bottom_graph_bar.visible == true` in FLAME mode
   - Verify `flame_graph_control.visible == true` in FLAME mode
   - Check console for `_draw()` calls from FlameGraphControl
   - Verify status messages appear ("Collecting samples...")
   - Wait 1-2 seconds and verify flame graph bars appear after aggregation

2. **Debug Logging:**
   - Add logging in `_update_bottom_graph_bar()` to confirm visibility state
   - Add logging in `set_mode()` to track visibility changes
   - Verify signal connections are working (check for `aggregation_complete` emissions)

3. **Edge Cases:**
   - Test mode cycling: OFF → SIMPLE → DETAILED → FLAME → OFF
   - Verify waterfall is hidden in FLAME mode
   - Verify flame graph is hidden in DETAILED mode
   - Test window resize while in FLAME mode

### Code Quality Improvements

1. **Consolidate Visibility Logic:**
   - Consider moving all visibility logic to `set_mode()` and removing it from `_update_bottom_graph_bar()`
   - This prevents future conflicts between positioning and visibility

2. **Add Mode Constants:**
   - Consider using a helper function:
   ```gdscript
   func _should_show_bottom_bar() -> bool:
       return current_mode == Mode.DETAILED or current_mode == Mode.FLAME
   ```

3. **Documentation:**
   - Add comment explaining that `_update_bottom_graph_bar()` handles positioning only, not visibility

---

## Next Steps

1. **Apply Fix:** Modify `_update_bottom_graph_bar()` to include FLAME mode in visibility check (or remove visibility logic entirely)

2. **Test:**
   - Run project
   - Cycle to FLAME mode with F3
   - Verify bottom panel appears
   - Verify status messages appear initially
   - Wait for aggregation and verify flame graph bars appear

3. **Verify Other Modes:**
   - Test DETAILED mode still shows waterfall
   - Test SIMPLE mode hides bottom bar
   - Test OFF mode hides everything

4. **Commit:**
   - After successful test, commit with message: `fix/genesis: Show bottom graph bar in FLAME mode - fix visibility logic in _update_bottom_graph_bar()`

---

## Summary

**Root Cause:** `_update_bottom_graph_bar()` only sets `bottom_graph_bar.visible = true` for DETAILED mode, causing the entire bottom panel (including FlameGraphControl) to be hidden in FLAME mode.

**Fix:** Update line 577 to include FLAME mode: `bottom_graph_bar.visible = (current_mode == Mode.DETAILED or current_mode == Mode.FLAME)`

**Confidence:** 100% - This is a clear logic error in the visibility condition.

