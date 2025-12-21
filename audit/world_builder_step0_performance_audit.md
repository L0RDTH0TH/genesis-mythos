# World Builder Step 0 Performance Audit - Critical Blocking Issues

**Date:** 2025-01-20  
**Issue:** World Builder running at ~1 FPS with ~1000ms frame times, stuck on Step 0  
**Status:** CRITICAL - Main thread blocking identified

---

## Executive Summary

The World Builder is experiencing severe performance degradation (~1 FPS) due to **synchronous map generation blocking the main thread**. The primary culprit is `MapMakerModule.regenerate_map()` calling `MapGenerator.generate_map()` with `use_thread = false`, forcing synchronous execution that can take 100-1000ms+ for typical map sizes.

---

## Critical Findings

### 1. **PRIMARY ISSUE: Synchronous Map Generation Blocking Main Thread**

**Location:** `ui/world_builder/MapMakerModule.gd:616`

```616:616:ui/world_builder/MapMakerModule.gd
	map_generator.generate_map(world_map_data, false, use_low_res_preview)  # Synchronous, preview mode if requested
```

**Problem:**
- Second parameter `false` forces `use_thread = false`
- This calls `MapGenerator._generate_sync()` which blocks the main thread
- For a 1024x1024 map, `_generate_heightmap()` alone can take 200-500ms
- With post-processing (even disabled in preview mode), total blocking time can exceed 1000ms
- This causes the ~1 FPS performance observed

**Impact:** 
- Every map generation/regeneration blocks the main thread for 100-1000ms+
- UI becomes completely unresponsive during generation
- Frame times spike to 1000ms+ as observed

**Root Cause Chain:**
1. `WorldBuilderUI._on_generate_map_pressed()` → 
2. `MapMakerModule.regenerate_map()` → 
3. `MapGenerator.generate_map(world_map_data, false, ...)` → 
4. `MapGenerator._generate_sync()` → 
5. `MapGenerator._generate_heightmap()` (blocks main thread)

---

### 2. **Heightmap Generation Loop Without Yielding**

**Location:** `core/world_generation/MapGenerator.gd:322-359`

```322:359:core/world_generation/MapGenerator.gd
	for y in range(size.y):
		for x in range(size.x):
			# Normalize coordinates to world space
			var world_x: float = (float(x) / float(size.x) - 0.5) * world_map_data.world_width
			var world_y: float = (float(y) / float(size.y) - 0.5) * world_map_data.world_height
			
			# Get height noise value (-1 to 1) - this is the primary seed-dependent value
			var height_value: float = height_noise.get_noise_2d(world_x, world_y)
			
			# Apply continent mask (radial gradient + noise)
			var distance_from_center: float = Vector2(world_x, world_y).length() / (max(world_map_data.world_width, world_map_data.world_height) * 0.5)
			var continent_mask: float = continent_noise.get_noise_2d(world_x, world_y)
			continent_mask = (continent_mask + 1.0) * 0.5  # Normalize to 0-1
			
			# Combine: islands near edges, continents in center
			var mask_factor: float = 1.0 - smoothstep(0.3, 1.0, distance_from_center)
			mask_factor = lerp(mask_factor, continent_mask, 0.5)
			
			# Normalize height to 0-1 range - preserve full height_noise variation
			height_value = (height_value + 1.0) * 0.5
			# Apply mask while preserving seed-dependent height_noise variation
			# Use additive approach to ensure height_noise remains significant
			height_value = height_value * (0.7 + mask_factor * 0.3)
			height_value = clamp(height_value, 0.0, 1.0)
			
			# Apply sea level cutoff - preserve seed-dependent variation even underwater
			if height_value < world_map_data.sea_level:
				# Use a seed-dependent offset to preserve variation underwater
				# Sample height_noise at slightly different coordinates to get variation
				var underwater_noise: float = height_noise.get_noise_2d(world_x * 1.5, world_y * 1.5)
				var underwater_base: float = world_map_data.sea_level * 0.5
				var underwater_variation: float = (underwater_noise + 1.0) * 0.5 * 0.15
				height_value = underwater_base + underwater_variation
				height_value = clamp(height_value, 0.0, world_map_data.sea_level)
			
			# Store as grayscale (RF format uses red channel)
			var color: Color = Color(height_value, height_value, height_value, 1.0)
			img.set_pixel(x, size.y - 1 - y, color)  # Flip Y for proper orientation
```

**Problem:**
- Nested loops process every pixel synchronously
- For 1024x1024 = 1,048,576 pixels, this is a massive blocking operation
- No yielding between rows or chunks
- Each pixel requires multiple noise calculations (height_noise, continent_noise, potentially underwater_noise)

**Impact:**
- 1024x1024 map: ~200-500ms blocking time
- 2048x2048 map: ~800-2000ms blocking time
- Completely freezes UI during generation

---

### 3. **Biome Preview Generation Also Blocks**

**Location:** `core/world_generation/MapGenerator.gd:736-779`

```736:779:core/world_generation/MapGenerator.gd
func generate_biome_preview(world_map_data: WorldMapData) -> Image:
	"""Generate biome color preview image based on height, temperature, moisture."""
	if world_map_data.heightmap_image == null:
		return null
	
	var height_img: Image = world_map_data.heightmap_image
	var size: Vector2i = height_img.get_size()
	var biome_img: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	
	# Generate biome colors (Images are thread-safe in Godot 4.3, no lock needed)
	for y in range(size.y):
		for x in range(size.x):
			# Get world position
			var world_x: float = (float(x) / float(size.x) - 0.5) * world_map_data.world_width
			var world_y: float = (float(y) / float(size.y) - 0.5) * world_map_data.world_height
			
			# Get height
			var height: float = height_img.get_pixel(x, size.y - 1 - y).r
			
			# Get temperature and moisture (normalized to 0-1)
			var temperature: float = (temperature_noise.get_noise_2d(world_x, world_y) + 1.0) * 0.5
			var moisture: float = (moisture_noise.get_noise_2d(world_x, world_y) + 1.0) * 0.5
			
			# Apply global biases
			var temp_bias: float = world_map_data.temperature_bias
			var moist_bias: float = world_map_data.moisture_bias
			temperature = clampf(temperature + temp_bias * 0.5, 0.0, 1.0)
			moisture = clampf(moisture + moist_bias * 0.5, 0.0, 1.0)
			
			# Apply regional climate adjustments if available (from MapEditor painting)
			var pixel_key: String = "%d,%d" % [x, size.y - 1 - y]
			if world_map_data.regional_climate_adjustments.has(pixel_key):
				var adjustment: Dictionary = world_map_data.regional_climate_adjustments[pixel_key]
				var temp_adj: float = adjustment.get("temp", 0.0)
				var moist_adj: float = adjustment.get("moist", 0.0)
				temperature = clampf(temperature + temp_adj * 0.5, 0.0, 1.0)
				moisture = clampf(moisture + moist_adj * 0.5, 0.0, 1.0)
			
			# Determine biome color based on height, temperature, moisture
			var biome_color: Color = _get_biome_color(height, temperature, moisture, world_map_data.sea_level)
			biome_img.set_pixel(x, size.y - 1 - y, biome_color)
	
	world_map_data.biome_preview_image = biome_img
	return biome_img
```

**Problem:**
- Another nested loop processing every pixel synchronously
- Called immediately after heightmap generation in `MapMakerModule.regenerate_map()`
- Adds another 100-300ms blocking time

**Impact:**
- Total blocking time: heightmap (200-500ms) + biome preview (100-300ms) = 300-800ms for 1024x1024

---

### 4. **PerformanceLogger.log_current_frame() Called Every Frame**

**Location:** `ui/world_builder/WorldBuilderUI.gd:181-201`

```181:201:ui/world_builder/WorldBuilderUI.gd
func _process(delta: float) -> void:
	"""PROFILING: Per-frame processing - timing instrumentation and performance logging."""
	var frame_start: int = Time.get_ticks_usec()
	profiling_process_calls += 1
	
	# Performance logging integration (if PerformanceLogger is available)
	if PerformanceLogger != null:
		# Collect custom data for logging
		var custom_data: Dictionary = {
			"scene": "WorldBuilder",
			"notes": "Step %d" % current_step
		}
		
		# Add MapMakerModule stats if available (example: could add draw_calls, primitives from MapRenderer)
		if map_maker_module != null and map_maker_module.map_renderer != null:
			# Future: could extract actual draw_calls/primitives from MapRenderer
			# For now, just pass scene context
			pass
		
		# Call performance logger (it handles interval throttling internally)
		PerformanceLogger.log_current_frame(custom_data)
```

**Problem:**
- `_process()` is enabled when PerformanceLogger is active
- Calls `PerformanceLogger.log_current_frame()` every frame
- While `log_current_frame()` has interval throttling (default 0.1s), it still does work every frame
- File I/O operations in `log_current_frame()` can add overhead

**Impact:**
- Minor overhead, but adds to frame time
- Should be disabled when not actively profiling

**Note:** This is NOT the primary cause of 1 FPS, but contributes to overhead.

---

## Secondary Findings

### 5. **No Automatic Map Generation on Initialization**

**Status:** ✅ GOOD - No automatic generation found

Checked:
- `WorldBuilderUI._ready()` - No map generation
- `MapMakerModule._ready()` - No map generation  
- `MapMakerModule.initialize_from_step_data()` - Only creates data structure, no generation

**Conclusion:** The blocking is triggered by user action (Generate Map button), not automatic initialization.

---

### 6. **Project Settings Check**

**Checked:** `project.godot`

- No `application/run/low_processor_mode` setting found
- No `application/run/low_processor_mode_sleep_usec` setting found
- `physics/common/physics_ticks_per_second` not explicitly set (uses default 60)

**Impact:** Not contributing to the issue, but could be optimized later.

---

### 7. **No OS.delay_msec/usec Found**

**Status:** ✅ GOOD - No blocking delays found

Searched entire codebase - no `OS.delay_msec()` or `OS.delay_usec()` calls found.

---

### 8. **No Blocking While Loops Found**

**Status:** ✅ GOOD - No blocking while loops found

All while loops found are:
- Bounded (e.g., `while river_sources.size() < river_count and attempts < MAX_ATTEMPTS`)
- In threaded code (e.g., `_thread_generate()`)
- Not in `_process()` or `_physics_process()`

---

## Recommended Fixes (Priority Order)

### **FIX 1: Enable Threading for Map Generation (CRITICAL)**

**File:** `ui/world_builder/MapMakerModule.gd`

**Change Line 616:**
```gdscript
# BEFORE:
map_generator.generate_map(world_map_data, false, use_low_res_preview)  # Synchronous, preview mode if requested

# AFTER:
map_generator.generate_map(world_map_data, true, use_low_res_preview)  # Use threading to prevent blocking
```

**Additional Changes Required:**
1. Update `MapMakerModule.regenerate_map()` to handle threaded generation:
   - Poll thread status or use signals to detect completion
   - Show progress indicator during generation
   - Update renderer when thread completes

2. Update `MapGenerator._generate_in_thread()` to emit completion signal:
   - Since `MapGenerator` extends `RefCounted` (not `Node`), use a callback or polling
   - Or refactor to use `Node`-based approach with `call_deferred`

**Impact:** Eliminates main thread blocking for map generation. Should restore 60 FPS during generation.

---

### **FIX 2: Add Yielding to Heightmap Generation (If Threading Not Possible)**

**File:** `core/world_generation/MapGenerator.gd`

**Modify `_generate_heightmap()` to yield every N rows:**

```gdscript
func _generate_heightmap(world_map_data: WorldMapData) -> void:
	"""Generate base heightmap using multi-octave noise."""
	# ... existing code ...
	
	var img: Image = world_map_data.heightmap_image
	var size: Vector2i = img.get_size()
	
	# Process in chunks to allow yielding
	const CHUNK_SIZE: int = 64  # Process 64 rows at a time
	var processed_rows: int = 0
	
	for y in range(size.y):
		for x in range(size.x):
			# ... existing pixel processing code ...
			img.set_pixel(x, size.y - 1 - y, color)
		
		processed_rows += 1
		# Yield every CHUNK_SIZE rows to prevent blocking
		if processed_rows >= CHUNK_SIZE:
			processed_rows = 0
			await get_tree().process_frame  # Yield to allow frame rendering
```

**Note:** This requires `_generate_heightmap()` to be called from a `Node` context (not `RefCounted`). May require refactoring.

**Impact:** Reduces blocking time, but still adds overhead. Threading (FIX 1) is preferred.

---

### **FIX 3: Defer Biome Preview Generation**

**File:** `ui/world_builder/MapMakerModule.gd`

**Change Line 635:**
```gdscript
# BEFORE:
# Generate biome preview
map_generator.generate_biome_preview(world_map_data)

# AFTER:
# Generate biome preview asynchronously (defer to next frame)
call_deferred("_generate_biome_preview_deferred")

# Add new method:
func _generate_biome_preview_deferred() -> void:
	if map_generator != null and world_map_data != null:
		map_generator.generate_biome_preview(world_map_data)
		if map_renderer != null:
			map_renderer.refresh()
```

**Impact:** Prevents biome preview from blocking initial map display. User sees heightmap immediately, biome colors appear next frame.

---

### **FIX 4: Disable PerformanceLogger._process() When Not Needed**

**File:** `ui/world_builder/WorldBuilderUI.gd`

**Already implemented** - `_process()` is disabled when PerformanceLogger is inactive (line 168-169).

**Recommendation:** Ensure PerformanceLogger is disabled by default in production builds.

---

## Implementation Priority

1. **IMMEDIATE (Fix 1):** Enable threading for map generation - This will restore 60 FPS
2. **HIGH (Fix 3):** Defer biome preview generation - Improves perceived responsiveness
3. **MEDIUM (Fix 2):** Add yielding if threading proves problematic - Fallback option
4. **LOW (Fix 4):** Verify PerformanceLogger defaults - Already mostly handled

---

## Testing Plan

After implementing fixes:

1. **Test Step 0 Performance:**
   - Open World Builder
   - Navigate to Step 0 (Map Generation)
   - Click "Generate Map" button
   - Verify FPS stays at 60 FPS during generation
   - Verify frame times stay < 16ms

2. **Test Map Sizes:**
   - Small (512x512) - Should be instant
   - Medium (1024x1024) - Should complete in < 100ms without blocking
   - Large (2048x2048) - Should complete in < 500ms without blocking

3. **Test UI Responsiveness:**
   - Generate map while moving mouse
   - Generate map while resizing window
   - Verify UI remains responsive throughout

---

## Code References

- `ui/world_builder/MapMakerModule.gd:616` - Synchronous generation call
- `core/world_generation/MapGenerator.gd:150-188` - `_generate_sync()` blocking function
- `core/world_generation/MapGenerator.gd:322-359` - Heightmap generation loop
- `core/world_generation/MapGenerator.gd:736-779` - Biome preview generation loop
- `ui/world_builder/WorldBuilderUI.gd:181-201` - `_process()` with PerformanceLogger

---

## Conclusion

The primary cause of 1 FPS performance is **synchronous map generation blocking the main thread**. The fix is straightforward: enable threading for map generation. This will move the expensive computation to a background thread, allowing the main thread to maintain 60 FPS while generation occurs.

**Estimated Fix Time:** 2-4 hours (including testing and thread completion handling)

**Expected Result:** 60 FPS maintained during map generation, UI remains fully responsive.

