# Map Preview Texture Resize Investigation Report

## Problem Summary

When World Size changes (e.g., Tiny → Large):
- ✅ Container/background expands correctly (grey grid lines show new bounds)
- ❌ Map texture stays at old small size in top-left corner
- ❌ Texture does NOT stretch to fill the new container bounds

## Investigation Findings

### 1. TextureRect Configuration Analysis

**Scene File (`WorldBuilderUI.tscn` line 110-118):**
```
Map2DTexture (TextureRect)
- layout_mode = 1 (Anchors mode)
- anchors_preset = 15 (PRESET_FULL_RECT)
- expand_mode = 1 (EXPAND_FIT_WIDTH)
- stretch_mode = 5 (STRETCH_KEEP_ASPECT_CENTERED)
```

**Code (`WorldBuilderUI.gd` line 1655):**
```gdscript
map_2d_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
```

**⚠️ CONFLICT DETECTED:**
- Scene file sets `expand_mode = 1` (EXPAND_FIT_WIDTH)
- Code sets `expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL` (value = 3)
- This creates a runtime override that may conflict with scene initialization

### 2. Expand Mode Constants (Godot 4.x)

According to Godot documentation:
- `EXPAND_KEEP_SIZE` (0): Minimum size = texture's original size
- `EXPAND_FIT_WIDTH` (1): Minimum width = current height × texture aspect ratio
- `EXPAND_FIT_WIDTH_PROPORTIONAL` (3): **⚠️ EXPERIMENTAL** - May cause unstable behavior in containers

**Key Finding:** `EXPAND_FIT_WIDTH_PROPORTIONAL` is marked as experimental and may cause unstable behavior in certain container controls.

### 3. Expand Mode Behavior Analysis

**EXPAND_FIT_WIDTH_PROPORTIONAL (3):**
- According to docs: "The minimum width is adjusted to match the height, maintaining the texture's aspect ratio"
- This mode calculates a minimum size based on the texture's aspect ratio
- **Problem:** When texture size changes dramatically (512 → 4096), the calculated minimum size may not update correctly
- **Problem:** This mode is designed for horizontal layouts (HBoxContainer), not full-rect anchored nodes

**EXPAND_FIT_WIDTH (1):**
- Calculates minimum width based on current height and texture aspect ratio
- More stable than EXPAND_FIT_WIDTH_PROPORTIONAL
- Still may have issues with aspect ratio calculations

**EXPAND_KEEP_SIZE (0):**
- Sets minimum size to texture's native size
- **This would prevent expansion** - TextureRect would be stuck at texture size

### 4. Layout Mode Mismatch

**TextureRect:**
- `layout_mode = 1` (Anchors mode)
- Uses anchors to fill parent

**Parent Container (CenterPanel):**
- `layout_mode = 2` (Container mode)
- Uses container layout system

**Potential Issue:** Mixing Anchors mode child with Container mode parent can cause layout calculation timing issues.

### 5. Custom Minimum Size Reset

**Current Code (line 1651):**
```gdscript
map_2d_texture.custom_minimum_size = Vector2.ZERO
```

**Problem:** Setting `custom_minimum_size = Vector2.ZERO` may conflict with `EXPAND_FIT_WIDTH_PROPORTIONAL`, which calculates its own minimum size based on the texture's aspect ratio. The expand mode may be recalculating a minimum size that prevents expansion.

### 6. Layout Timing Issues

**Current Sequence:**
1. Set texture = null
2. Set texture = new texture
3. Set custom_minimum_size = Vector2.ZERO
4. Set expand_mode and stretch_mode
5. Call `parent.update_minimum_size()`
6. Call `queue_redraw()`

**Potential Issue:** Layout recalculation happens synchronously, but Godot's layout system may need a frame to process. The `call_deferred()` for `_update_map_grid()` suggests layout timing is already a known issue.

### 7. Parent Container Update

**Current Code (line 1660-1661):**
```gdscript
var parent: Control = map_2d_texture.get_parent()
if parent != null:
    parent.update_minimum_size()
```

**Analysis:**
- `update_minimum_size()` only updates the minimum size calculation
- Does NOT force a full layout recalculation
- May need `parent.queue_sort()` or `parent.queue_redraw()` instead

### 8. Diagnostic Logging Added

**New Diagnostic Function:** `_diagnostic_check_texture_rect_after_layout()`

This function logs:
- TextureRect size before/after texture assignment
- Custom minimum size values
- Parent container size
- Texture size and aspect ratios
- Whether TextureRect is stuck at texture size
- Whether TextureRect is filling parent

**Location:** Lines 1673-1720 in `WorldBuilderUI.gd`

**Usage:** Run the project and check debug output when changing world size. Look for:
- `=== MAP PREVIEW DIAGNOSTIC START ===`
- `⚠️ ISSUE DETECTED` warnings

## Root Cause Hypotheses (Ranked by Likelihood)

### Hypothesis 1: EXPAND_FIT_WIDTH_PROPORTIONAL Conflict (HIGHEST PROBABILITY)

**Theory:** `EXPAND_FIT_WIDTH_PROPORTIONAL` calculates a minimum size based on the texture's aspect ratio. When the texture size changes dramatically, this calculation may:
1. Use cached aspect ratio from old texture
2. Calculate minimum size that prevents expansion
3. Conflict with `custom_minimum_size = Vector2.ZERO`

**Evidence:**
- Godot docs warn this mode is experimental and may cause unstable behavior
- Mode is designed for horizontal layouts, not full-rect anchored nodes
- Scene file uses different expand mode (1) than code (3)

### Hypothesis 2: Layout Timing Issue (HIGH PROBABILITY)

**Theory:** Layout recalculation happens before Godot's layout system processes the new texture size. The TextureRect may be sizing itself based on the old texture before the new one is fully processed.

**Evidence:**
- `call_deferred()` is already used for `_update_map_grid()`
- No `await get_tree().process_frame` or deferred layout calls
- Parent container update happens synchronously

### Hypothesis 3: Custom Minimum Size Conflict (MEDIUM PROBABILITY)

**Theory:** Setting `custom_minimum_size = Vector2.ZERO` conflicts with `EXPAND_FIT_WIDTH_PROPORTIONAL`'s internal minimum size calculation. The expand mode may be overriding the zero value with its calculated minimum.

**Evidence:**
- Expand modes calculate their own minimum sizes
- Setting custom_minimum_size may be ignored or overridden
- No verification that custom_minimum_size actually stays at zero

### Hypothesis 4: Parent Container Not Forcing Layout (MEDIUM PROBABILITY)

**Theory:** `parent.update_minimum_size()` is insufficient. The Panel container may need `queue_sort()` or a full layout recalculation to properly resize its anchored child.

**Evidence:**
- `update_minimum_size()` only updates minimum size, not full layout
- Panel uses Container mode, which may need explicit sort
- No call to `parent.queue_sort()` or similar

### Hypothesis 5: Anchors Mode vs Container Mode Mismatch (LOW PROBABILITY)

**Theory:** Mixing Anchors mode (TextureRect) with Container mode (Panel) parent causes layout calculation issues when texture size changes.

**Evidence:**
- Different layout systems may have timing conflicts
- Anchors mode should work with Container mode parent, but edge cases exist

## Recommended Investigation Steps

1. **Run Diagnostic Logging:**
   - Change world size from Tiny → Large
   - Check debug output for diagnostic messages
   - Look for `⚠️ ISSUE DETECTED` warnings
   - Verify actual sizes vs expected sizes

2. **Test Different Expand Modes:**
   - Try `EXPAND_KEEP_SIZE` (0) - should prevent expansion (baseline)
   - Try `EXPAND_FIT_WIDTH` (1) - more stable than PROPORTIONAL
   - Compare behavior with current `EXPAND_FIT_WIDTH_PROPORTIONAL` (3)

3. **Test Layout Timing:**
   - Add `await get_tree().process_frame` after texture assignment
   - Use `call_deferred()` for layout updates
   - Test if deferred layout fixes the issue

4. **Test Parent Container Updates:**
   - Try `parent.queue_sort()` instead of `update_minimum_size()`
   - Try `parent.queue_redraw()`
   - Test if parent container is actually resizing

5. **Verify Custom Minimum Size:**
   - Log `custom_minimum_size` after setting to Vector2.ZERO
   - Check if expand mode is overriding it
   - Test removing the `custom_minimum_size = Vector2.ZERO` line

## Next Steps

1. Run the project with diagnostic logging enabled
2. Change world size and capture debug output
3. Analyze the diagnostic output to identify which hypothesis is correct
4. Apply targeted fix based on diagnostic findings

## Files Modified for Investigation

- `ui/world_builder/WorldBuilderUI.gd`:
  - Added comprehensive diagnostic logging (lines 1642-1720)
  - Added `_diagnostic_check_texture_rect_after_layout()` function
  - No functional changes, only investigation code
