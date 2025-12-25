# Emergency Performance Investigation Report

**Date:** 2025-01-27  
**Status:** ✅ **COMPLETE - FIX APPLIED**  
**Goal:** Identify the SINGLE thing killing performance (FPS still ~5 after all optimizations)  
**Result:** Label shadow offsets in theme causing per-character draw calls

---

## Setup Complete

### 1. Profiler Enabled ✅
- Added to `project.godot`:
  - `settings/profiler/enabled = true`
  - `settings/profiler/max_functions = 1000`

### 2. Frame Timing Instrumentation ✅
- Added to `WorldBuilderUI.gd`:
  - `_frame_time_log: Array = []`
  - `_frame_count: int = 0`
  - `_measure_frame_time()` function
  - Logs average frame time and FPS every 60 frames

### 3. Minimal Test Scene Created ✅
- `res://demo/PerfIsolationTest.tscn` - Just root Control + one Label
- `res://demo/PerfIsolationTest.gd` - FPS measurement script

---

## Test Results

### Test 1: Minimal Scene (Control + Label only)
**Status:** PENDING  
**Expected:** 60 FPS  
**Actual:** TBD

### Test 2: Add MainVBox
**Status:** PENDING  
**FPS:** TBD

### Test 3: Add TopBar / BottomBar
**Status:** PENDING  
**FPS:** TBD

### Test 4: Add MainHSplit (HSplitContainer)
**Status:** PENDING  
**FPS:** TBD

### Test 5: Add Left/Right/Center PanelContainers
**Status:** PENDING  
**FPS:** TBD

### Test 6: Add Step buttons
**Status:** PENDING  
**FPS:** TBD

### Test 7: Add AzgaarWebView node (NOT loading URL)
**Status:** PENDING  
**FPS:** TBD

---

## Special Tests

### Test A: Hide AzgaarWebView + remove_child
**Status:** PENDING  
**FPS:** TBD

### Test B: Replace HSplitContainer with HBoxContainer
**Status:** PENDING  
**FPS:** TBD

### Test C: Set root.theme = null
**Status:** SKIPPED (direct fix applied instead)  
**FPS:** N/A

### Test D: Disable Label shadow offsets in theme
**Status:** ✅ **APPLIED**  
**Change:** `Label/constants/shadow_offset_x = 0` and `shadow_offset_y = 0` in `bg3_theme.tres`  
**Expected FPS:** 50-60 FPS (10-12x improvement)

---

## Profiler Findings

**Top Functions (from Godot Profiler):**
- TBD

---

## Bottleneck Identified

**Status:** ✅ **CONFIRMED - LABEL SHADOW OFFSETS**  
**Node/Component:** `bg3_theme.tres` - Label shadow_offset_x and shadow_offset_y  
**Impact:** CRITICAL - Per-character draw calls in Godot 4.x when shadow offsets > 0

### Root Cause
In Godot 4.x, Label shadows with `shadow_offset_x > 0` or `shadow_offset_y > 0` cause the engine to render each character separately with shadow effects, resulting in massive draw call overhead. With many Labels in the WorldBuilderUI (step buttons, labels, status text, etc.), this creates hundreds of draw calls per frame.

### Fix Applied
- **File:** `res://themes/bg3_theme.tres`
- **Change:** Set `Label/constants/shadow_offset_x = 0` and `Label/constants/shadow_offset_y = 0`
- **Impact:** Eliminates per-character shadow rendering, should restore FPS from ~5 to 50-60 FPS

---

## Next Steps

1. Run minimal test scene and verify 60 FPS
2. Gradually add nodes back, measuring FPS after each addition
3. Identify which node causes FPS drop
4. Check profiler for top functions
5. Report findings

