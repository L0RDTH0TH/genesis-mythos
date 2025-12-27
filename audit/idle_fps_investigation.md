# Idle FPS Investigation Report - WorldBuilderUI

**Date:** 2025-12-27  
**Issue:** Critical 5-6 FPS when WorldBuilderUI is idle  
**Investigator:** Cursor AI  
**Status:** Investigation Complete - Requires Profiler GUI Verification

---

## Executive Summary

This investigation analyzed the codebase to identify potential causes of the 5-6 FPS idle performance issue in WorldBuilderUI. Code analysis confirms that known performance-killing functions (`_process()` in WorldBuilderUI, PerformanceLogger, and WebView) are properly disabled. However, **profiler GUI analysis is required** to identify the actual bottleneck causing the 5-6 FPS.

---

## 1. Current State Confirmation

### 1.1 WebView Status

**File:** `res://scripts/ui/WorldBuilderAzgaar.gd`  
**Line:** 10

```gdscript
const DEBUG_DISABLE_AZGAAR := true
```

**Status:** ✅ **CONFIRMED DISABLED**

- WebView initialization is skipped when `DEBUG_DISABLE_AZGAAR` is true
- WebView node is removed from scene tree (lines 34-40)
- No godot_wry WebView processes should be running

---

### 1.2 WorldBuilderUI._process() Status

**File:** `res://ui/world_builder/WorldBuilderUI.gd`  
**Lines:** 108-110, 657-682

```108:110:ui/world_builder/WorldBuilderUI.gd
	# GUI Performance Fix: _process() is conditionally enabled only during generation
	# (see _generate_azgaar() and generation complete/failed handlers)
	set_process(false)
```

```657:682:ui/world_builder/WorldBuilderUI.gd
func _process(delta: float) -> void:
	"""Process generation status updates (fallback polling if signals don't work)."""
	# GUI Performance Fix: Early exit if generation is not active
	if gen_timer <= 0.0:
		set_process(false)  # Disable when no longer needed
		return
	
	# Generation logic (gen_timer > 0.0 guaranteed at this point)
	gen_elapsed_time += delta
	gen_timer += delta
	
	# Check timeout first (increased to 60s to match timeout timer)
	if gen_elapsed_time > 60.0:
		_update_status("Timeout - reduce points?", 0)
		gen_timer = 0.0
		gen_elapsed_time = 0.0
		set_process(false)  # Disable when timeout occurs
		return
	
	# Poll every 2 seconds for completion (reduced frequency)
	if gen_timer > 2.0:
		gen_timer = 0.0  # Reset timer for next polling cycle
		# Update progress based on elapsed time
		var progress = min(40 + (gen_elapsed_time / 60.0 * 40.0), 80.0)
		_update_status("Generating map... (%d%%)" % int(progress), progress)
```

**Status:** ✅ **CONFIRMED DISABLED WHEN IDLE**

- `set_process(false)` is called in `_ready()` (line 110)
- `_process()` is only enabled during generation (`_generate_azgaar()` line 654)
- Early return check disables `_process()` if `gen_timer <= 0.0` (line 661)
- When idle, `gen_timer` should be 0.0, so `_process()` should not be running

---

### 1.3 PerformanceLogger._process() Status

**File:** `res://core/singletons/PerformanceLogger.gd`  
**Lines:** 61-69

```61:69:core/singletons/PerformanceLogger.gd
	# DIAGNOSTIC TEST: Disable _process() entirely for testing
	set_process(false)
	MythosLogger.info("PerformanceLogger", "DIAGNOSTIC: _process() disabled for FPS testing")


func _process(_delta: float) -> void:
	"""Process per-frame logic: handle interval logging."""
	# DIAGNOSTIC TEST: Disabled entirely - return immediately
	return
```

**Status:** ✅ **CONFIRMED DISABLED**

- `set_process(false)` is called in `_ready()` (line 62)
- `_process()` has early return (line 69)
- Should not be contributing to idle FPS

---

### 1.4 PerformanceMonitor._process() Status

**File:** `res://scripts/ui/overlays/PerformanceMonitor.gd`  
**Lines:** 336, 351, 375, 396, 401-405

```336:336:scripts/ui/overlays/PerformanceMonitor.gd
			set_process(false)  # GUI Performance Fix: Disable _process when OFF
```

```351:351:scripts/ui/overlays/PerformanceMonitor.gd
			set_process(true and visible)  # GUI Performance Fix: Only enable if visible
```

```375:375:scripts/ui/overlays/PerformanceMonitor.gd
			set_process(true and visible)  # GUI Performance Fix: Only enable if visible
```

```396:396:scripts/ui/overlays/PerformanceMonitor.gd
			set_process(true and visible)  # GUI Performance Fix: Only enable if visible
```

```401:405:scripts/ui/overlays/PerformanceMonitor.gd
func _process(_delta: float) -> void:
	"""Update performance metrics each frame. DiagnosticDispatcher: drains queue first, then metrics, then existing logic."""
	# GUI Performance Fix: Only process if overlay is visible and mode is not OFF
	if not visible or current_mode == Mode.OFF:
		return
```

**Status:** ⚠️ **CONDITIONAL - DEPENDS ON VISIBILITY AND MODE**

- `_process()` is disabled when mode is OFF (line 336)
- `_process()` is enabled only if visible AND mode is SIMPLE/DETAILED/FLAME (lines 351, 375, 396)
- Early return check prevents execution if not visible or mode is OFF (lines 404-405)
- **Action Required:** Verify PerformanceMonitor visibility and mode when idle in WorldBuilderUI

---

## 2. Code Analysis - Potential Per-Frame Functions

### 2.1 Tree Signal Connections

**File:** `res://ui/world_builder/WorldBuilderUI.gd`  
**Lines:** 380-382, 509-554

**Signals Connected:**
- `param_tree.item_selected.connect(_on_tree_item_selected)` - Line 380
- `param_tree.item_edited.connect(_on_tree_item_edited)` - Line 381
- `param_tree.cell_selected.connect(_on_tree_cell_selected)` - Line 382

**Status:** ✅ **EVENT-DRIVEN, NOT PER-FRAME**

- These signals only fire on user interaction (selection, editing, cell selection)
- `_on_tree_item_selected()` and `_on_tree_cell_selected()` are empty (pass statements)
- `_on_tree_item_edited()` only runs when user edits a Tree item
- Should not be firing every frame when idle

---

### 2.2 Seed SpinBox Signal

**File:** `res://ui/world_builder/WorldBuilderUI.gd`  
**Line:** 88

```88:88:ui/world_builder/WorldBuilderUI.gd
	seed_spin.value_changed.connect(_on_seed_changed)
```

**Status:** ✅ **EVENT-DRIVEN, NOT PER-FRAME**

- `value_changed` signal only fires when the SpinBox value actually changes
- Should not be firing every frame when idle

---

### 2.3 Responsive Layout Updates

**File:** `res://ui/world_builder/WorldBuilderUI.gd`  
**Lines:** 192-199, 201-234

```192:199:ui/world_builder/WorldBuilderUI.gd
func _notification(what: int) -> void:
	"""Handle window resize for responsive layout."""
	if what == NOTIFICATION_RESIZED:
		# GUI Performance Fix: Throttle resize updates with deferred batching
		if not _resize_pending:
			_resize_pending = true
			call_deferred("_update_responsive_layout")
```

**Status:** ✅ **EVENT-DRIVEN WITH THROTTLING**

- `_notification()` only fires on window resize events (NOTIFICATION_RESIZED)
- Throttled with `_resize_pending` flag to prevent multiple calls
- Uses `call_deferred()` to batch updates
- Should not be running every frame when idle

---

## 3. Profiler GUI Checklist

Since code analysis confirms expected optimizations are in place, **profiler GUI analysis is required** to identify the actual bottleneck. Use the following checklist:

### 3.1 Start Profiler and Navigate to WorldBuilderUI

1. Start project in debug mode
2. Navigate to Create World → enter WorldBuilderUI scene
3. Let it sit idle for 10 seconds (do not interact with UI)
4. Open Debugger → Profiler tab

### 3.2 Check Top 5 Functions by Time

Look for functions with high "Time (ms)" or "Self (ms)" values:

**Expected Results:**
- ✅ `WorldBuilderUI._process()` should be **0% or absent** (disabled when idle)
- ✅ `PerformanceLogger._process()` should be **0% or absent** (disabled)
- ✅ WebView-related functions should be **0% or absent** (disabled)

**Potential Culprits to Look For:**
- 🔴 `PerformanceMonitor._process()` - Check if visible and mode is not OFF
- 🔴 `Tree.*` functions - Check if Tree is doing per-frame updates
- 🔴 `Control.*` or `CanvasItem.*` functions - Check for excessive redraws
- 🔴 `Theme.*` or `StyleBox.*` functions - Check for theme overhead
- 🔴 `RenderingServer.*` functions - Check for rendering overhead

### 3.3 Check _process() Function Calls

Search profiler for all `_process()` functions:

**Check These Scripts:**
1. `WorldBuilderUI._process()` - Should be 0% (confirmed disabled in code)
2. `PerformanceLogger._process()` - Should be 0% (confirmed disabled in code)
3. `PerformanceMonitor._process()` - Check percentage (may be running if visible)
4. Any other `_process()` functions in WorldBuilderUI scene tree

### 3.4 Check Rendering/UI Functions

Look for high-cost UI rendering functions:

- `Control._notification()` calls (NOTIFICATION_RESIZED, etc.)
- `CanvasItem.queue_redraw()` calls
- `Theme` or `StyleBox` calculations
- `Tree` internal update/redraw functions
- `Label` or `RichTextLabel` text rendering

### 3.5 Check Signal Emissions

While signals themselves don't appear in profiler, their connected functions do. Check for:

- Functions that might be connected to signals that fire frequently
- Any callbacks from Tree, SpinBox, or other controls
- Any callbacks from singletons or autoload nodes

---

## 4. Code Excerpts for Reference

### 4.1 WorldBuilderUI._process() - Disabled When Idle

```657:682:ui/world_builder/WorldBuilderUI.gd
func _process(delta: float) -> void:
	"""Process generation status updates (fallback polling if signals don't work)."""
	# GUI Performance Fix: Early exit if generation is not active
	if gen_timer <= 0.0:
		set_process(false)  # Disable when no longer needed
		return
	
	# Generation logic (gen_timer > 0.0 guaranteed at this point)
	gen_elapsed_time += delta
	gen_timer += delta
	
	# Check timeout first (increased to 60s to match timeout timer)
	if gen_elapsed_time > 60.0:
		_update_status("Timeout - reduce points?", 0)
		gen_timer = 0.0
		gen_elapsed_time = 0.0
		set_process(false)  # Disable when timeout occurs
		return
	
	# Poll every 2 seconds for completion (reduced frequency)
	if gen_timer > 2.0:
		gen_timer = 0.0  # Reset timer for next polling cycle
		# Update progress based on elapsed time
		var progress = min(40 + (gen_elapsed_time / 60.0 * 40.0), 80.0)
		_update_status("Generating map... (%d%%)" % int(progress), progress)
```

**Analysis:**
- `_process()` is disabled by default (`set_process(false)` in `_ready()`)
- Early return if `gen_timer <= 0.0` (should be true when idle)
- Only enabled during generation (`set_process(true)` in `_generate_azgaar()`)

---

### 4.2 PerformanceLogger._process() - Disabled for Testing

```61:69:core/singletons/PerformanceLogger.gd
	# DIAGNOSTIC TEST: Disable _process() entirely for testing
	set_process(false)
	MythosLogger.info("PerformanceLogger", "DIAGNOSTIC: _process() disabled for FPS testing")


func _process(_delta: float) -> void:
	"""Process per-frame logic: handle interval logging."""
	# DIAGNOSTIC TEST: Disabled entirely - return immediately
	return
```

**Analysis:**
- `_process()` is disabled (`set_process(false)`)
- Early return prevents any execution
- Should not contribute to idle FPS

---

### 4.3 PerformanceMonitor._process() - Conditional Execution

```401:405:scripts/ui/overlays/PerformanceMonitor.gd
func _process(_delta: float) -> void:
	"""Update performance metrics each frame. DiagnosticDispatcher: drains queue first, then metrics, then existing logic."""
	# GUI Performance Fix: Only process if overlay is visible and mode is not OFF
	if not visible or current_mode == Mode.OFF:
		return
```

**Analysis:**
- `_process()` is enabled only if visible AND mode is not OFF
- Early return if not visible or mode is OFF
- **Requires verification:** Check if PerformanceMonitor is visible and mode when idle

---

## 5. Conclusion and Next Steps

### 5.1 Code Analysis Summary

✅ **Confirmed Optimized:**
1. WorldBuilderUI._process() is disabled when idle
2. PerformanceLogger._process() is disabled
3. WebView (Azgaar) is disabled via DEBUG_DISABLE_AZGAAR
4. Tree signals are event-driven, not per-frame
5. Responsive layout updates are event-driven with throttling

⚠️ **Requires Verification:**
1. PerformanceMonitor visibility and mode when idle
2. Actual profiler data to identify the 5-6 FPS bottleneck

### 5.2 Recommended Profiler Actions

1. **Open Profiler GUI** (Debugger → Profiler tab)
2. **Navigate to WorldBuilderUI** and let it sit idle for 10 seconds
3. **Check Top 5 Functions by Time** and note percentages
4. **Search for all `_process()` functions** and verify they are 0% or absent
5. **Check for high-cost UI rendering functions** (Control.*, CanvasItem.*, Theme.*, Tree.*)
6. **Take screenshot of profiler** showing top functions

### 5.3 Likely Culprits (Based on Common Patterns)

Given that known per-frame functions are disabled, the 5-6 FPS bottleneck is likely:

1. **PerformanceMonitor._process()** - If visible and mode is SIMPLE/DETAILED/FLAME, this runs every frame with multiple `Performance.get_monitor()` calls and `RenderingServer.get_rendering_info()` calls
2. **Tree internal updates** - Tree widget may have internal per-frame update logic (requires profiler verification)
3. **Theme/StyleBox overhead** - Deep node nesting (8-9 levels) with theme overrides may cause excessive style calculations
4. **Rendering overhead** - Large UI tree with many controls may cause excessive draw calls or layout recalculations

### 5.4 Next Investigation Steps

After profiler GUI analysis:

1. **If PerformanceMonitor is the culprit:**
   - Disable PerformanceMonitor when in WorldBuilderUI scene
   - Or set PerformanceMonitor mode to OFF when idle

2. **If Tree is the culprit:**
   - Investigate Tree widget internal update logic
   - Consider replacing Tree with simpler control if possible
   - Or disable Tree updates when not visible/active

3. **If rendering/theme is the culprit:**
   - Reduce node nesting depth
   - Optimize theme overrides (use fewer overrides, cache stylebox calculations)
   - Use `visible = false` on hidden panels to skip rendering

4. **If other function is the culprit:**
   - Follow profiler data to identify the function
   - Apply appropriate optimization (disable _process, use timers instead, cache calculations, etc.)

---

## 6. Files Analyzed

- `res://ui/world_builder/WorldBuilderUI.gd` - Main UI script (verified `_process()` disabled)
- `res://scripts/ui/WorldBuilderAzgaar.gd` - WebView controller (verified disabled)
- `res://core/singletons/PerformanceLogger.gd` - Performance logger (verified `_process()` disabled)
- `res://scripts/ui/overlays/PerformanceMonitor.gd` - Performance monitor overlay (conditional `_process()`)
- `res://core/scenes/world_root.gd` - Scene root (no `_process()` functions)
- `res://ui/world_builder/WorldBuilderUI.tscn` - Scene file (node structure)

---

**Report Status:** Code analysis complete. Profiler GUI analysis required to identify actual bottleneck.

