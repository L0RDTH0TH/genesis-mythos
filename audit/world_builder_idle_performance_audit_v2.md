# World Builder UI Idle Performance Audit Report v2

**Date:** 2025-12-19  
**Focus:** ~3 FPS idle bottleneck in World Builder UI (Step 1, mouse completely still)  
**Previous Fixes Attempted:** Throttling brush refresh, disabling _process on hidden/idle modules, viewport UPDATE_WHEN_VISIBLE  
**Result:** ZERO impact on FPS

---

## Executive Summary

This audit adds comprehensive profiling instrumentation to identify the root cause of the ~3 FPS idle bottleneck. Despite previous optimizations (refresh throttling, disabled _process on hidden modules, viewport update mode changes), FPS remains at ~3 when the World Builder UI is idle at Step 1 with no mouse movement.

**New Potential Causes Identified:**
1. **SubViewport continuous rendering loop** - SubViewport may be forcing full redraws every frame even when idle
2. **Shader material texture updates** - MapRenderer shader material may be triggering expensive texture uploads per frame
3. **MapEditor input event processing** - Input event handlers may be running even when no input occurs
4. **ProceduralWorldMap incremental rendering** - Even when hidden, incremental quality rendering may still be active
5. **Viewport container input polling** - SubViewportContainer may be polling for input events every frame

---

## Profiling Instrumentation Added

### 1. MapMakerModule._process() Profiling
**File:** `ui/world_builder/MapMakerModule.gd`  
**Lines:** 915-930

```gdscript
func _process(delta: float) -> void:
	"""Process per-frame updates - PROFILING ENABLED."""
	if not is_active:
		return
	
	var frame_start: int = Time.get_ticks_usec()
	
	# Existing per-frame logic would go here (currently none)
	
	var frame_time: int = Time.get_ticks_usec() - frame_start
	if frame_time > 1000:  # >1ms
		print("PROFILING: MapMakerModule._process took: ", frame_time / 1000.0, " ms")
	
	# Periodic FPS reporting (every 1 second)
	if Engine.get_process_frames() % 60 == 0:
		var current_fps: float = Engine.get_frames_per_second()
		print("PROFILING: MapMakerModule - Current FPS: ", current_fps, " | is_active: ", is_active, " | visible: ", visible)
```

**Status:** ✅ ADDED  
**Findings:** 
- `_process()` only runs when `is_active == true` (controlled by `activate()`/`deactivate()`)
- If `_process()` is running, it will report frame times >1ms and FPS every 60 frames
- **Critical:** Need to verify if `activate()` is being called when entering Step 1

**Evidence:**
- `activate()` is called in `WorldBuilderUI.gd` line 807
- `deactivate()` is called in `WorldBuilderUI.gd` line 834
- Default state: `set_process(false)` in `_ready()` (line 70)

---

### 2. MapMakerModule._on_viewport_container_input() Profiling
**File:** `ui/world_builder/MapMakerModule.gd`  
**Lines:** 813-865

```gdscript
func _on_viewport_container_input(event: InputEvent) -> void:
	"""Handle input events from viewport container - PROFILING ENABLED."""
	if map_viewport_container == null or not map_viewport_container.is_visible_in_tree():
		return
	
	var input_start: int = Time.get_ticks_usec()
	
	# ... existing input handling code ...
	
	var input_time: int = Time.get_ticks_usec() - input_start
	if input_time > 1000:  # >1ms
		print("PROFILING: MapMakerModule._on_viewport_container_input took: ", input_time / 1000.0, " ms")
```

**Status:** ✅ ADDED  
**Findings:**
- This function should only be called when actual input events occur
- If it's being called during idle, that indicates input event spam or polling
- Will report if input handling takes >1ms

**Evidence:**
- Connected to `map_viewport_container.gui_input` signal (line 104)
- Should only fire on actual mouse/keyboard events

---

### 3. ProceduralWorldMap._process() Enhanced Profiling
**File:** `addons/procedural_world_map/worldmap.gd`  
**Lines:** 186-210

```gdscript
func _process(delta):
	# PROFILING: Enhanced timing
	var frame_start: int = Time.get_ticks_usec()
	
	# PROFILING: Log if processing while hidden
	if not visible:
		# Only log once per second to avoid spam
		if Engine.get_process_frames() % 60 == 0:
			print("PROFILING: ProceduralWorldMap._process() running while hidden! visible=", visible, " incremental_quality=", incremental_quality)
	
	# ... existing logic ...
	
	var frame_time: int = Time.get_ticks_usec() - frame_start
	if frame_time > 1000:  # >1ms
		print("PROFILING: ProceduralWorldMap._process took: ", frame_time / 1000.0, " ms | visible=", visible, " incremental_quality=", incremental_quality)
	
	# Periodic FPS reporting (every 1 second)
	if Engine.get_process_frames() % 60 == 0:
		var current_fps: float = Engine.get_frames_per_second()
		print("PROFILING: ProceduralWorldMap - Current FPS: ", current_fps, " | visible: ", visible, " | incremental_quality: ", incremental_quality)
```

**Status:** ✅ ENHANCED  
**Findings:**
- Previous profiling only logged "running while hidden" for incremental_quality
- Now logs frame times and FPS even when visible
- **Critical:** Will detect if ProceduralWorldMap is running when it should be disabled

**Evidence:**
- `WorldBuilderUI.gd` line 144: `procedural_world_map.set_process(false)` when hidden
- But `_process()` may still run if `set_process(false)` wasn't effective

---

### 4. MapRenderer.refresh() Profiling
**File:** `core/world_generation/MapRenderer.gd`  
**Lines:** 200-234

```gdscript
func refresh() -> void:
	"""Refresh rendering (call after map data changes) - PROFILING ENABLED."""
	var refresh_start: int = Time.get_ticks_usec()
	
	# ... existing refresh logic ...
	
	var refresh_time: int = Time.get_ticks_usec() - refresh_start
	if refresh_time > 1000:  # >1ms
		print("PROFILING: MapRenderer.refresh() took: ", refresh_time / 1000.0, " ms")
```

**Status:** ✅ ADDED  
**Findings:**
- `refresh()` is called from multiple places:
  - `MapMakerModule.generate_map()` (line 461)
  - `MapMakerModule._on_refresh_timer_timeout()` (line 908) - throttled
  - `MapMakerModule._on_viewport_container_input()` (line 843) - on mouse release
- If `refresh()` is being called every frame during idle, that's the bottleneck
- Will report if refresh takes >1ms

**Evidence:**
- Refresh throttling is in place (100ms throttle, line 63)
- But if something else is calling `refresh()` directly, throttling won't help

---

## Potential Root Causes (Based on Code Analysis)

### Cause 1: SubViewport Continuous Rendering
**Status:** ⚠️ SUSPECTED  
**Impact:** HIGH  
**Evidence:**
- `map_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE` (line 97)
- But SubViewport may still be rendering every frame if it thinks it's "visible"
- SubViewport rendering is expensive, especially with shader materials

**Recommended Fix:**
- Set `render_target_update_mode = SubViewport.UPDATE_ONCE` after initial render
- Only switch to `UPDATE_ALWAYS` when actively editing
- Add profiling to measure viewport render time

---

### Cause 2: Shader Material Texture Updates Every Frame
**Status:** ⚠️ SUSPECTED  
**Impact:** HIGH  
**Evidence:**
- `MapRenderer` uses `ShaderMaterial` with multiple textures (heightmap, biome, rivers)
- Shader material parameter updates may trigger texture uploads
- Even if textures don't change, parameter validation may be expensive

**Recommended Fix:**
- Add profiling to `_update_textures()` to measure texture upload time
- Cache texture state and only update when actually changed
- Consider using `ImageTexture.update()` instead of `set_image()` if image data hasn't changed

---

### Cause 3: Input Event Polling/Spam
**Status:** ⚠️ SUSPECTED  
**Impact:** MEDIUM  
**Evidence:**
- `SubViewportContainer.gui_input` signal may be firing even when mouse is still
- Input event processing includes coordinate conversion (`_screen_to_world_position`)
- Multiple input handlers may be processing the same events

**Recommended Fix:**
- Add early return in `_on_viewport_container_input()` if no actual input occurred
- Verify that input events aren't being generated by the UI system itself
- Consider debouncing input events

---

### Cause 4: ProceduralWorldMap Still Running
**Status:** ⚠️ SUSPECTED  
**Impact:** MEDIUM  
**Evidence:**
- `WorldBuilderUI.gd` line 144: `procedural_world_map.set_process(false)`
- But if `set_process(false)` is called before `_ready()`, it may not take effect
- Incremental quality rendering may continue in background threads

**Recommended Fix:**
- Verify `set_process(false)` is called after `_ready()` completes
- Check if incremental rendering threads are still active
- Add explicit check: `if procedural_world_map.is_processing(): print("ERROR: PWM still processing!")`

---

### Cause 5: Viewport Container Resize Events
**Status:** ⚠️ SUSPECTED  
**Impact:** LOW-MEDIUM  
**Evidence:**
- `_on_viewport_container_resized()` calls `_update_viewport_size()`
- Resize events may be firing continuously if layout is unstable
- Viewport size updates trigger texture reallocation

**Recommended Fix:**
- Add profiling to `_update_viewport_size()`
- Only update viewport size if it actually changed
- Debounce resize events

---

## Testing Instructions

1. **Launch World Builder UI:**
   - Start the project
   - Navigate to World Builder (Step 1: Map Generation & Editing)
   - Wait for initial map generation to complete

2. **Enter Idle State:**
   - Do NOT move the mouse
   - Do NOT interact with any UI elements
   - Wait 60 seconds

3. **Capture Debug Output:**
   - Look for lines starting with `PROFILING:`
   - Note frame times, FPS reports, and "running while hidden" messages
   - Count how many times each profiling message appears

4. **Expected Profiling Output:**
   ```
   PROFILING: MapMakerModule - Current FPS: 3.0 | is_active: true | visible: true
   PROFILING: ProceduralWorldMap._process() running while hidden! visible=false incremental_quality=true
   PROFILING: MapRenderer.refresh() took: 250.0 ms
   ```

---

## Analysis Framework

### If MapMakerModule._process() is running:
- **Check frame time:** If >16ms, that's the bottleneck
- **Check is_active:** If true when it shouldn't be, fix activation logic
- **Check FPS:** If FPS is low but frame time is <1ms, bottleneck is elsewhere

### If ProceduralWorldMap._process() is running while hidden:
- **CRITICAL BUG:** `set_process(false)` didn't work
- **Fix:** Call `set_process(false)` in `_ready()` after a frame delay
- **Alternative:** Remove ProceduralWorldMap from scene tree when not needed

### If MapRenderer.refresh() is called frequently:
- **Check call stack:** Use `print_stack()` to see who's calling it
- **Check throttle timer:** Verify `refresh_timer` is actually throttling
- **Fix:** Add guard to prevent refresh if nothing changed

### If no profiling output appears:
- **Profiling code not running:** Check if `_process()` is enabled
- **Frame times <1ms:** Bottleneck is in rendering, not script
- **Use Godot Profiler:** Enable "Script Functions" profiling in Godot editor

---

## Recommended Action Plan

### Phase 1: Verify Profiling Data (IMMEDIATE)
1. Run project with profiling code
2. Navigate to Step 1, enter idle state
3. Capture all `PROFILING:` output
4. Identify which functions are running and their frame times

### Phase 2: Fix Confirmed Bottlenecks (HIGH PRIORITY)
1. **If SubViewport is rendering every frame:**
   - Set `UPDATE_ONCE` after initial render
   - Only update when map data changes
   - Add viewport render time profiling

2. **If Shader material is updating every frame:**
   - Cache texture state
   - Only call `set_shader_parameter()` when values actually change
   - Consider using `RenderingServer` for direct texture updates

3. **If ProceduralWorldMap is still running:**
   - Fix `set_process(false)` timing
   - Remove from scene tree when not needed
   - Disable incremental rendering threads

### Phase 3: Optimize Rendering Pipeline (MEDIUM PRIORITY)
1. Reduce viewport render target size if possible
2. Use lower resolution textures for preview
3. Disable shader effects that aren't needed for 2D map view
4. Consider using `CanvasLayer` instead of `SubViewport` for 2D map

### Phase 4: Advanced Optimizations (LOW PRIORITY)
1. Implement frame skipping for non-interactive periods
2. Use `call_deferred()` for non-critical updates
3. Batch texture updates
4. Consider multi-threaded rendering

---

## Next Steps

1. **Run the project with profiling code active**
2. **Navigate to Step 1 and leave idle for 60 seconds**
3. **Capture all `PROFILING:` output from debug console**
4. **Share profiling output for analysis**
5. **Implement fixes based on profiling data**

---

## Commit Message

```
Perf: Add temporary profiling for idle FPS audit v2

- Added frame timing to MapMakerModule._process()
- Added input event timing to _on_viewport_container_input()
- Enhanced ProceduralWorldMap._process() profiling
- Added MapRenderer.refresh() timing
- All profiling prints to console with "PROFILING:" prefix
- FPS reporting every 60 frames
- Frame time warnings for operations >1ms
```

---

**END OF AUDIT REPORT v2**
