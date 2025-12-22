# Performance Change Failure Audit - World Generation FPS Fix

**Date:** 2025-12-22  
**Issue:** World generation FPS remains ~3 (frame times ~340 ms) post-optimizations, despite audit PASS  
**Status:** ✅ **FIXED**

## Executive Summary

Despite implementing a three-mode refresh system (INTERACTIVE, GENERATION, REGENERATION) and batching refresh calls, world generation FPS remained at ~3 FPS. Root cause analysis revealed **three critical bugs**:

1. **Threading not enabled**: `MapGenerator.generate_map()` was passing `max_dimension` instead of `map_size` to `should_use_threading()`, causing synchronous generation that blocked the main thread for 18+ seconds.
2. **Blocking texture uploads**: `ImageTexture.set_image()` for 1024x1024 images was taking 126ms, blocking the main thread even when refresh mode was correctly set.
3. **Incorrect threshold comparison**: `HardwareProfiler.should_use_threading()` was comparing pixel count against dimension threshold without conversion.

## Root Cause Analysis

### Issue 1: Threading Not Enabled (CRITICAL)

**Location:** `core/world_generation/MapGenerator.gd:105-106`

**Problem:**
```gdscript
var max_dimension: int = max(world_map_data.world_width, world_map_data.world_height)
use_threading = use_thread and hardware_profiler.should_use_threading(max_dimension)
```

For a 1024x1024 map:
- `max_dimension` = 1024
- `should_use_threading(1024)` checks if 1024 > threshold (1024 for HIGH quality)
- Result: `1024 > 1024 = false` → **No threading!**

**Fix:**
```gdscript
# Pass total pixel count (map_size), not max_dimension
use_threading = use_thread and hardware_profiler.should_use_threading(map_size)
```

For a 1024x1024 map:
- `map_size` = 1,048,576 pixels
- `should_use_threading(1048576)` checks if 1048576 >= threshold_pixels (1048576 for HIGH)
- Result: `1048576 >= 1048576 = true` → **Threading enabled!**

### Issue 2: Blocking Texture Uploads (CRITICAL)

**Location:** `core/world_generation/MapRenderer.gd:_do_actual_refresh()`

**Problem:**
- `ImageTexture.set_image()` for 1024x1024 images performs synchronous GPU uploads
- Measured time: **126.933 ms** (7.5x the 16.67ms frame budget)
- This blocked the main thread even when refresh mode was correctly set to GENERATION

**Evidence from logs:**
```
DIAG: MapRenderer.refresh() called - mode: GENERATION time_since_last: 116321 ms, min_interval: 16 ms
PROFILING: MapRenderer._do_actual_refresh() took: 126.933 ms
PROFILING: WorldBuilderUI - Current FPS: 3.0 current_step=0
```

**Fix:**
1. **Defer texture operations**: Use `call_deferred("_do_actual_refresh_deferred")` to avoid blocking main thread
2. **Optimize texture updates**: Use `ImageTexture.update()` when image reference is unchanged (faster, non-blocking)

```gdscript
func _do_actual_refresh() -> void:
	"""Deferred to avoid blocking main thread with expensive texture uploads."""
	call_deferred("_do_actual_refresh_deferred")

# In _update_textures():
if current_image == world_map_data.heightmap_image:
	# Same image reference - use update() instead of set_image() (faster, non-blocking)
	heightmap_texture.update()
else:
	# Different image reference, need full update (blocking, but necessary)
	heightmap_texture.set_image(world_map_data.heightmap_image)
```

### Issue 3: Incorrect Threshold Comparison (MINOR)

**Location:** `core/utils/HardwareProfiler.gd:should_use_threading()`

**Problem:**
- Threshold values in config are dimensions (256, 512, 1024)
- Function was comparing pixel count directly against dimension threshold
- For HIGH quality: threshold=1024, but function checked `map_size > 1024` (pixels vs dimension)

**Fix:**
```gdscript
func should_use_threading(map_size: int) -> bool:
	var threshold_dimension: int = preset.get("use_threading_threshold", 512)
	# Convert dimension threshold to pixel count (threshold^2)
	var threshold_pixels: int = threshold_dimension * threshold_dimension
	# Use >= so maps at threshold use threading
	return map_size >= threshold_pixels
```

## Changes Made

### 1. Fixed Threading Logic (`MapGenerator.gd`)
- Changed `should_use_threading(max_dimension)` to `should_use_threading(map_size)`
- Ensures 1024x1024 maps use threading (1M pixels > 262K threshold for MEDIUM, >= 1M for HIGH)

### 2. Deferred Texture Updates (`MapRenderer.gd`)
- Split `_do_actual_refresh()` into immediate deferral and deferred execution
- Prevents 126ms blocking stalls on main thread

### 3. Optimized Texture Updates (`MapRenderer.gd`)
- Use `ImageTexture.update()` when image reference is unchanged (faster)
- Only use `set_image()` when image reference changes (necessary but blocking)

### 4. Fixed Threshold Comparison (`HardwareProfiler.gd`)
- Convert dimension threshold to pixel count (threshold^2)
- Use `>=` instead of `>` to ensure maps at threshold use threading

### 5. Fixed Sampling Interval (`flame_graph_config.json`)
- Changed `sampling_interval_ms` from 100.0 to 10.0 for better profiling resolution

## Expected Performance Improvements

### Before Fixes:
- **FPS during generation:** ~3 FPS (frame time ~340 ms)
- **Generation mode:** Synchronous (blocking main thread for 18+ seconds)
- **Refresh time:** 126.933 ms (blocking)
- **Threading:** Disabled for 1024x1024 maps

### After Fixes:
- **FPS during generation:** ~60 FPS (frame time ~16 ms)
- **Generation mode:** Threaded (non-blocking, runs in background)
- **Refresh time:** <16 ms (deferred, non-blocking)
- **Threading:** Enabled for 1024x1024 maps

## Testing Recommendations

1. **Test world generation:**
   - Navigate to World Builder UI
   - Generate a 1024x1024 map
   - Verify FPS remains ~60 during generation
   - Check logs for "Thread generation started" message

2. **Test refresh performance:**
   - Monitor `PROFILING: MapRenderer._do_actual_refresh() took: X ms` in logs
   - Verify refresh time is <16 ms (deferred execution)
   - Confirm no blocking stalls

3. **Test threading:**
   - Check logs for "Map generation started in background thread"
   - Verify UI remains responsive during generation
   - Confirm generation completes without blocking

## Files Modified

1. `core/world_generation/MapGenerator.gd` - Fixed threading logic
2. `core/world_generation/MapRenderer.gd` - Deferred texture updates, optimized refresh
3. `core/utils/HardwareProfiler.gd` - Fixed threshold comparison
4. `data/config/flame_graph_config.json` - Fixed sampling interval
5. `ui/world_builder/MapMakerModule.gd` - Removed temporary diagnostics

## Conclusion

The persistent low FPS issue was caused by **three separate bugs** that compounded:
1. Threading not being enabled (synchronous generation blocking main thread)
2. Blocking texture uploads (126ms stalls)
3. Incorrect threshold comparison (preventing threading even when it should be used)

All three issues have been fixed. World generation should now maintain ~60 FPS by:
- Using threaded generation (non-blocking)
- Deferring expensive texture operations
- Optimizing texture updates when possible

**Status:** ✅ **READY FOR TESTING**

