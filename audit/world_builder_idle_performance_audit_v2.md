# World Builder UI Idle Performance Audit Report v2

**Date:** 2025-12-19  
**Focus:** ~3 FPS idle bottleneck in World Builder UI (Step 1, mouse completely still)  
**Previous Fixes:** Throttling brush refresh + disabling _process on hidden/idle modules + viewport UPDATE_WHEN_VISIBLE had ZERO impact

---

## Executive Summary

This audit adds comprehensive profiling instrumentation to identify why FPS remains ~3 even when the World Builder UI is completely idle (Step 1, no mouse movement, no user interaction). Previous optimizations (refresh throttling, disabling _process on hidden modules, viewport update modes) had zero impact, indicating the bottleneck is elsewhere.

**New Potential Causes Identified:**
1. **SubViewport continuous rendering** - SubViewport may be rendering every frame even when idle
2. **Shader material updates** - ShaderMaterial parameter updates may trigger per-frame GPU work
3. **Texture updates** - ImageTexture.set_image() or texture updates may be happening per-frame
4. **Input event processing** - Even idle mouse position may trigger per-frame input handling
5. **Timer callbacks** - Refresh throttling timer may be causing overhead
6. **Hidden ProceduralWorldMap still processing** - Despite set_process(false), may still have other per-frame logic

---

## Profiling Instrumentation Added

### 1. ProceduralWorldMap._process() (addons/procedural_world_map/worldmap.gd)

**Status:** ✅ INSTRUMENTED

**Changes:**
- Added microsecond-level timing around entire `_process()` function
- Enhanced visibility check logging (logs every second if running while hidden)
- Added periodic FPS reporting (every 60 frames = ~1 second)
- Reports frame time if >1ms

**Code:**
```gdscript
func _process(delta):
	# PROFILING: Time the entire _process function
	var frame_start: int = Time.get_ticks_usec()
	
	# PROFILING: Log if processing while hidden
	if not visible:
		# Only log once per second to avoid spam
		if Engine.get_process_frames() % 60 == 0:
			print("PROFILING: ProceduralWorldMap._process() running while hidden! visible=", visible, " is_processing=", is_processing())
	
	# ... existing logic ...
	
	# PROFILING: Report frame time if >1ms
	var frame_time: int = Time.get_ticks_usec() - frame_start
	if frame_time > 1000:  # >1ms
		print("PROFILING: ProceduralWorldMap._process() took: ", frame_time / 1000.0, " ms")
	
	# PROFILING: Periodic FPS report every 1 second
	if Engine.get_process_frames() % 60 == 0:
		print("PROFILING: ProceduralWorldMap - Current FPS: ", Engine.get_frames_per_second())
```

**Expected Output:**
- If `_process()` is running while hidden: `"PROFILING: ProceduralWorldMap._process() running while hidden! visible=false is_processing=true"`
- If `_process()` takes >1ms: `"PROFILING: ProceduralWorldMap._process() took: X.XX ms"`
- Every second: `"PROFILING: ProceduralWorldMap - Current FPS: X"`

---

### 2. MapMakerModule._process() (ui/world_builder/MapMakerModule.gd)

**Status:** ✅ INSTRUMENTED (NEW FUNCTION)

**Changes:**
- Added `_process()` function with timing (module previously had no _process)
- Reports frame time if >1ms
- Reports FPS and activation status every second

**Code:**
```gdscript
func _process(delta: float) -> void:
	"""PROFILING: Per-frame processing - timing instrumentation."""
	var frame_start: int = Time.get_ticks_usec()
	
	# Existing per-frame logic would go here (currently none)
	
	# PROFILING: Report frame time if >1ms
	var frame_time: int = Time.get_ticks_usec() - frame_start
	if frame_time > 1000:  # >1ms
		print("PROFILING: MapMakerModule._process() took: ", frame_time / 1000.0, " ms")
	
	# PROFILING: Periodic FPS report every 1 second
	if Engine.get_process_frames() % 60 == 0:
		print("PROFILING: MapMakerModule - Current FPS: ", Engine.get_frames_per_second(), " is_active=", is_active, " is_processing=", is_processing())
```

**Expected Output:**
- If `_process()` takes >1ms: `"PROFILING: MapMakerModule._process() took: X.XX ms"`
- Every second: `"PROFILING: MapMakerModule - Current FPS: X is_active=true is_processing=true"`

**Note:** This function should NOT be called if `is_active=false` (processing disabled via `set_process(false)`). If we see output, it means processing is enabled when it shouldn't be.

---

### 3. MapMakerModule._on_viewport_container_input() (ui/world_builder/MapMakerModule.gd)

**Status:** ✅ INSTRUMENTED

**Changes:**
- Added timing around input event handling
- Reports time if >1ms

**Code:**
```gdscript
func _on_viewport_container_input(event: InputEvent) -> void:
	"""Handle input events from viewport container."""
	# PROFILING: Time input handling
	var input_start: int = Time.get_ticks_usec()
	
	# ... existing logic ...
	
	# PROFILING: Report input handling time if >1ms
	var input_time: int = Time.get_ticks_usec() - input_start
	if input_time > 1000:  # >1ms
		print("PROFILING: MapMakerModule._on_viewport_container_input() took: ", input_time / 1000.0, " ms")
```

**Expected Output:**
- If input handling takes >1ms: `"PROFILING: MapMakerModule._on_viewport_container_input() took: X.XX ms"`

**Note:** Even idle mouse position may trigger `InputEventMouseMotion` events every frame. If this is being called every frame, it could be a major bottleneck.

---

### 4. MapRenderer.refresh() (core/world_generation/MapRenderer.gd)

**Status:** ✅ INSTRUMENTED

**Changes:**
- Added timing around entire `refresh()` operation
- Reports time if >1ms

**Code:**
```gdscript
func refresh() -> void:
	"""Refresh rendering (call after map data changes)."""
	# PROFILING: Time refresh operation
	var refresh_start: int = Time.get_ticks_usec()
	
	# ... existing logic ...
	
	# PROFILING: Report refresh time if >1ms
	var refresh_time: int = Time.get_ticks_usec() - refresh_start
	if refresh_time > 1000:  # >1ms
		print("PROFILING: MapRenderer.refresh() took: ", refresh_time / 1000.0, " ms")
```

**Expected Output:**
- If refresh takes >1ms: `"PROFILING: MapRenderer.refresh() took: X.XX ms"`

**Note:** `refresh()` should NOT be called every frame when idle. If we see frequent calls, it indicates something is triggering refreshes unnecessarily.

---

### 5. WorldBuilderUI._process() (ui/world_builder/WorldBuilderUI.gd)

**Status:** ✅ INSTRUMENTED (NEW FUNCTION)

**Changes:**
- Added `_process()` function with timing (UI previously had no _process)
- Reports frame time if >1ms
- Reports FPS and current step every second

**Code:**
```gdscript
func _process(delta: float) -> void:
	"""PROFILING: Per-frame processing - timing instrumentation."""
	var frame_start: int = Time.get_ticks_usec()
	
	# Existing per-frame logic would go here (currently none)
	
	# PROFILING: Report frame time if >1ms
	var frame_time: int = Time.get_ticks_usec() - frame_start
	if frame_time > 1000:  # >1ms
		print("PROFILING: WorldBuilderUI._process() took: ", frame_time / 1000.0, " ms")
	
	# PROFILING: Periodic FPS report every 1 second
	if Engine.get_process_frames() % 60 == 0:
		print("PROFILING: WorldBuilderUI - Current FPS: ", Engine.get_frames_per_second(), " current_step=", current_step)
```

**Expected Output:**
- If `_process()` takes >1ms: `"PROFILING: WorldBuilderUI._process() took: X.XX ms"`
- Every second: `"PROFILING: WorldBuilderUI - Current FPS: X current_step=0"`

**Note:** This function should NOT exist (UI has no per-frame logic). If we see output, it means something is enabling processing unexpectedly.

---

## Analysis of Potential Causes

### Cause 1: SubViewport Continuous Rendering

**Status:** ⚠️ SUSPECTED

**Evidence:**
- `MapMakerModule` uses `SubViewport` with `render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE`
- Even with `UPDATE_WHEN_VISIBLE`, if the viewport container is visible, it may render every frame
- SubViewport rendering involves GPU work (shader execution, texture updates)

**Impact:** HIGH - GPU-bound operations can easily drop FPS to single digits

**Recommended Fix:**
- Set `render_target_update_mode = SubViewport.UPDATE_ONCE` when idle
- Only switch to `UPDATE_WHEN_VISIBLE` or `UPDATE_ALWAYS` when actively editing
- Use a timer to detect idle state (no input for N seconds) and switch to `UPDATE_ONCE`

**How to Confirm:**
- Check if SubViewport is rendering every frame (Godot profiler → Rendering → Viewport updates)
- Look for `PROFILING: MapRenderer.refresh()` being called every frame (should NOT happen when idle)

---

### Cause 2: Shader Material Parameter Updates

**Status:** ⚠️ SUSPECTED

**Evidence:**
- `MapRenderer` uses `ShaderMaterial` with multiple texture parameters
- Even if textures don't change, shader parameter updates may trigger GPU work
- `set_shader_parameter()` calls may be happening per-frame

**Impact:** MEDIUM-HIGH - Shader parameter updates can cause GPU stalls

**Recommended Fix:**
- Only call `set_shader_parameter()` when values actually change
- Cache parameter values and compare before updating
- Use `NOTIFICATION_THEME_CHANGED` or similar to batch updates

**How to Confirm:**
- Add profiling to `MapRenderer._update_textures()` to see if it's called every frame
- Check shader parameter update frequency in Godot profiler

---

### Cause 3: Input Event Processing (Idle Mouse)

**Status:** ⚠️ SUSPECTED

**Evidence:**
- `MapMakerModule._on_viewport_container_input()` is connected to `SubViewportContainer.gui_input`
- Even when mouse is still, `InputEventMouseMotion` events may fire every frame with `relative = Vector2.ZERO`
- Input handling may be doing expensive work (coordinate conversion, world position calculation)

**Impact:** MEDIUM - Per-frame input processing adds CPU overhead

**Recommended Fix:**
- Filter out zero-movement mouse events: `if event is InputEventMouseMotion and event.relative.length_squared() < 0.001: return`
- Only process input when actually needed (mouse button pressed, mouse moved significantly)

**How to Confirm:**
- Check `PROFILING: MapMakerModule._on_viewport_container_input()` output frequency
- If called every frame even when idle, this is the culprit

---

### Cause 4: Timer Callback Overhead

**Status:** ⚠️ SUSPECTED

**Evidence:**
- `MapMakerModule` has a `refresh_timer` (Timer) that runs every 100ms (10 times per second)
- Timer callbacks may have overhead even when not doing work
- Multiple timers in the scene tree can add up

**Impact:** LOW-MEDIUM - Timer overhead is usually minimal, but can add up

**Recommended Fix:**
- Stop timer when idle: `refresh_timer.stop()` when no painting is active
- Only start timer when painting begins

**How to Confirm:**
- Check if timer is running when idle (add logging to `_on_refresh_timer_timeout()`)
- Temporarily disable timer and measure FPS impact

---

### Cause 5: Texture Updates Per Frame

**Status:** ⚠️ SUSPECTED

**Evidence:**
- `MapRenderer.refresh()` calls `ImageTexture.set_image()` which may trigger GPU uploads
- Even if image data doesn't change, texture updates can be expensive
- Sprite2D texture updates may trigger per-frame GPU work

**Impact:** HIGH - Texture uploads are expensive GPU operations

**Recommended Fix:**
- Only call `refresh()` when map data actually changes
- Cache texture data and compare before updating
- Use `ImageTexture.update()` instead of `set_image()` if image reference is the same

**How to Confirm:**
- Check `PROFILING: MapRenderer.refresh()` output frequency
- If called every frame, this is likely the bottleneck

---

### Cause 6: Hidden ProceduralWorldMap Still Processing

**Status:** ⚠️ SUSPECTED

**Evidence:**
- `ProceduralWorldMap` is set to `visible = false` and `set_process(false)`
- However, it may still have other per-frame logic (signals, timers, incremental rendering)
- `incremental_timer` may still be running even when hidden

**Impact:** MEDIUM - Hidden nodes shouldn't process, but if they do, it wastes CPU

**Recommended Fix:**
- Ensure `incremental_timer.stop()` when hidden
- Check for other per-frame logic in ProceduralWorldMap (signals, callbacks)

**How to Confirm:**
- Check `PROFILING: ProceduralWorldMap._process()` output
- If we see "running while hidden" messages, this is confirmed

---

## Testing Instructions

To capture profiling data:

1. **Launch the project** (already done with profiling code in place)
2. **Navigate to World Builder UI** (should auto-load or via main menu)
3. **Go to Step 1** (Map Generation & Editing - 2D map view)
4. **Do NOTHING** - Keep mouse completely still for ~120 seconds
5. **Capture debug output** - All `PROFILING:` messages will appear in console

**Expected Profiling Output (if idle):**
- `PROFILING: WorldBuilderUI - Current FPS: X current_step=0` (every second)
- `PROFILING: MapMakerModule - Current FPS: X is_active=true is_processing=true` (every second, if processing enabled)
- `PROFILING: ProceduralWorldMap - Current FPS: X` (every second, if processing enabled)
- `PROFILING: MapRenderer.refresh() took: X.XX ms` (should NOT appear frequently when idle)
- `PROFILING: MapMakerModule._on_viewport_container_input() took: X.XX ms` (should NOT appear when mouse is still)

**Red Flags (indicating bottleneck):**
- `MapRenderer.refresh()` called every frame → **Cause 5 confirmed**
- `_on_viewport_container_input()` called every frame → **Cause 3 confirmed**
- `ProceduralWorldMap._process()` running while hidden → **Cause 6 confirmed**
- Any `_process()` function taking >10ms per frame → **Primary bottleneck identified**

---

## Summary & Priority

### Primary Suspects (High Priority)

1. **SubViewport continuous rendering** - Most likely cause of GPU-bound 3 FPS
2. **Texture updates per frame** - If `MapRenderer.refresh()` is called every frame
3. **Input event processing** - If `_on_viewport_container_input()` fires every frame

### Secondary Suspects (Medium Priority)

4. **Shader material parameter updates** - If shader parameters are updated every frame
5. **Hidden ProceduralWorldMap processing** - If still running despite `set_process(false)`
6. **Timer callback overhead** - If multiple timers are running unnecessarily

---

## Recommended Action Plan

### Phase 1: Identify Primary Bottleneck (IMMEDIATE)

1. **Run project with profiling code** (already added)
2. **Navigate to Step 1 and remain idle for 120 seconds**
3. **Capture all `PROFILING:` output**
4. **Analyze output to identify:**
   - Which functions are called every frame?
   - Which functions take >10ms per frame?
   - Are any functions running when they shouldn't be?

### Phase 2: Implement Top Fixes (Based on Profiling Data)

**If SubViewport rendering is the issue:**
- Add idle detection (no input for 2 seconds)
- Switch to `UPDATE_ONCE` when idle
- Only use `UPDATE_WHEN_VISIBLE` or `UPDATE_ALWAYS` when actively editing

**If texture updates are the issue:**
- Add change detection before calling `refresh()`
- Cache texture data and compare before updating
- Use `ImageTexture.update()` instead of `set_image()` when possible

**If input processing is the issue:**
- Filter out zero-movement mouse events
- Only process input when mouse actually moves or buttons are pressed

**If hidden ProceduralWorldMap is the issue:**
- Ensure all timers are stopped when hidden
- Check for other per-frame logic (signals, callbacks)

### Phase 3: Verify Fixes

1. **Remove profiling code** (or make it optional via debug flag)
2. **Test idle FPS** - Should be 60 FPS or close to it
3. **Test active editing** - Should maintain smooth FPS during brush painting
4. **Test step transitions** - Should not cause FPS drops

---

## Next Steps

1. **User Action Required:** Navigate to World Builder UI → Step 1 → Remain idle for 120 seconds
2. **Capture Profiling Output:** Copy all `PROFILING:` messages from console
3. **Analyze Results:** Identify which functions are called every frame and which take >10ms
4. **Implement Fixes:** Based on profiling data, implement fixes for top 2-3 bottlenecks
5. **Re-test:** Verify FPS improvement (target: 60 FPS idle, smooth during editing)

---

## Files Modified

- `addons/procedural_world_map/worldmap.gd` - Added profiling to `_process()`
- `ui/world_builder/MapMakerModule.gd` - Added `_process()` and profiling to `_on_viewport_container_input()`
- `core/world_generation/MapRenderer.gd` - Added profiling to `refresh()`
- `ui/world_builder/WorldBuilderUI.gd` - Added `_process()` for profiling

**Commit Message:** `Perf: Add temporary profiling for idle FPS audit v2`

---

**END OF AUDIT REPORT**
