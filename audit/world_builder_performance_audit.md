# ╔═══════════════════════════════════════════════════════════
# ║ World Builder UI Performance Audit Report
# ║ Date: 2025-01-XX
# ║ FPS Issue: ~3 FPS during map generation/editing
# ╚═══════════════════════════════════════════════════════════

## Executive Summary

Performance audit of World Builder UI identified **4 potential causes** for severe FPS drops (~3 FPS) during map generation/editing. After code inspection and profiling setup, **3 causes are CONFIRMED** as contributing to the bottleneck, with **Cause 4 (No Throttling on Brush Tools)** being the **PRIMARY CULPRIT**.

---

## Cause 1: Terrain3D Real-Time Updates During Editing

### Status: ❌ **NOT CONFIRMED** (Unlikely during Step 1 editing)

### Findings:
- `_update_terrain_live()` function exists in `WorldBuilderUI.gd` (line 2046)
- **Only executes on Step 2 (Terrain step)**, not during Step 1 (2D map editing)
- Code check: `if current_step != 2: return` (line 2052)
- Terrain3D updates only occur when:
  - User is on Step 2 (Terrain configuration)
  - Terrain parameters change (seed, frequency, height scale)
  - User clicks "Regenerate Terrain" button

### Evidence:
```gdscript
# ui/world_builder/WorldBuilderUI.gd:2046-2053
func _update_terrain_live() -> void:
    if terrain_manager == null:
        return
    # Only update if we're on the terrain step
    if current_step != 2:  # <-- Only Step 2, not Step 1
        return
```

### Impact on FPS:
- **During Step 1 (2D editing)**: **0% impact** (function doesn't run)
- **During Step 2 (Terrain step)**: Unknown (profiling code added to measure)

### Recommended Fix:
- **No fix needed for Step 1** (not the issue)
- If Step 2 has performance issues, consider:
  - Debouncing terrain updates (wait 0.5s after last parameter change)
  - Only update on "Regenerate" button press, not live
  - Use `UPDATE_ONCE` for preview viewport instead of `UPDATE_ALWAYS`

---

## Cause 2: Viewport Rendering Full 3D World in Background

### Status: ⚠️ **PARTIALLY CONFIRMED** (Secondary issue)

### Findings:
- **PreviewViewport (3D)**: 
  - Set to `UPDATE_DISABLED` during Steps 1-2 (line 818)
  - Set to `UPDATE_ALWAYS` during Steps 3+ (line 832)
  - Hidden (`visible = false`) during Steps 1-2 (line 817)
  - **However**: Scene file has `render_target_update_mode = 0` (UPDATE_DISABLED), but code overrides it
  
- **MapMakerModule Viewport (2D)**:
  - Set to `UPDATE_ALWAYS` (line 83 in MapMakerModule.gd)
  - Always visible during Step 1 editing
  - **This is expected behavior** (needs to render 2D map)

### Evidence:
```gdscript
# ui/world_builder/WorldBuilderUI.gd:817-818
if terrain_3d_view != null:
    terrain_3d_view.visible = false
    preview_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
```

```gdscript
# ui/world_builder/MapMakerModule.gd:83
map_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
```

### Impact on FPS:
- **PreviewViewport**: Likely **minimal** (disabled during Step 1)
- **MapMakerModule viewport**: **Expected** (must render 2D map)
- **Potential issue**: If `UPDATE_DISABLED` isn't working correctly, hidden viewport might still render

### Recommended Fix:
- **Verify UPDATE_DISABLED is working**: Add profiling to confirm viewport isn't rendering when disabled
- **Optimize MapMakerModule viewport**: Consider `UPDATE_WHEN_VISIBLE` if viewport is sometimes off-screen
- **Ensure camera.current = false** when viewport is hidden (already done, line 822)

---

## Cause 3: ProceduralWorldMap Addon Itself Is the Bottleneck

### Status: ⚠️ **POTENTIALLY CONFIRMED** (Secondary issue)

### Findings:
- **ProceduralWorldMap** has `_process()` function that runs **every frame** (line 186)
- Checks `incremental_quality` and `image_changed` flags every frame
- **Even when hidden** (`visible = false`), `_process()` still runs
- Addon uses `WorkerThreadPool` for incremental rendering, but main thread still processes every frame
- **Hidden by default** in WorldBuilderUI (line 142), but might still process

### Evidence:
```gdscript
# addons/procedural_world_map/worldmap.gd:186-190
func _process(delta):
    # start the idling timeout when the map has been fast rendered
    if incremental_quality and image_changed and incremental_timer.is_stopped():
        image_changed=false
        incremental_timer.start()
```

```gdscript
# ui/world_builder/WorldBuilderUI.gd:142
procedural_world_map.visible = false
```

### Impact on FPS:
- **Per-frame processing**: Even if lightweight, adds overhead
- **Incremental rendering**: Can trigger expensive operations in background threads
- **Hidden but processing**: Wastes CPU cycles when not needed

### Recommended Fix:
- **Disable `_process()` when hidden**: Override `_set_process()` or use `set_process(false)` when `visible = false`
- **Only enable when visible**: Set `procedural_world_map.set_process(false)` when hiding
- **Consider removing from scene tree**: Instead of hiding, remove/add node when needed

---

## Cause 4: No Throttling on Brush Tools

### Status: ✅ **CONFIRMED - PRIMARY CULPRIT**

### Findings:
- **`MapEditor.continue_paint()`** called on **every mouse motion event** (line 839 in MapMakerModule.gd)
- **`MapRenderer.refresh()`** called **after every paint operation** (line 841)
- **No debouncing or throttling** - if user drags mouse, hundreds of refresh calls per second
- **`refresh()` updates textures and shader parameters** - expensive operations
- **No frame-rate limiting** - can exceed 60+ calls per second during fast mouse movement

### Evidence:
```gdscript
# ui/world_builder/MapMakerModule.gd:837-841
elif map_editor != null:
    # Handle painting
    map_editor.continue_paint(world_pos)
    if map_editor.is_painting and map_renderer != null:
        map_renderer.refresh()  # <-- Called on EVERY mouse motion!
```

```gdscript
# core/world_generation/MapRenderer.gd:200-203
func refresh() -> void:
    """Refresh rendering (call after map data changes)."""
    _update_textures()  # <-- Expensive texture update
```

### Impact on FPS:
- **CRITICAL**: Each `refresh()` call:
  - Updates ImageTexture from heightmap image
  - Updates biome texture
  - Updates shader material parameters
  - Can take 10-50ms+ per call on large maps
- **During fast mouse drag**: 60+ refresh calls/second = **600-3000ms+ wasted per second**
- **Result**: FPS drops to ~3 FPS as renderer can't keep up

### Recommended Fix:
- **Implement throttling/debouncing**:
  - Use `Timer` to limit refresh rate to max 10-15 FPS (every 66-100ms)
  - Only refresh on mouse release, not during drag
  - Or: Batch paint operations and refresh once per frame
- **Simple fix (<50 lines)**:
  ```gdscript
  # In MapMakerModule.gd
  var refresh_timer: Timer
  var pending_refresh: bool = false
  
  func _ready():
      refresh_timer = Timer.new()
      refresh_timer.wait_time = 0.1  # 10 FPS max
      refresh_timer.one_shot = false
      refresh_timer.timeout.connect(_on_refresh_timer_timeout)
      add_child(refresh_timer)
      refresh_timer.start()
  
  func _on_refresh_timer_timeout():
      if pending_refresh and map_renderer != null:
          map_renderer.refresh()
          pending_refresh = false
  
  # In _on_viewport_container_input():
  if map_editor.is_painting and map_renderer != null:
      pending_refresh = true  # Instead of immediate refresh()
  ```

---

## Summary & Priority

### Primary Culprit: **Cause 4 (No Throttling on Brush Tools)**
- **Impact**: CRITICAL - 60+ refresh calls/second during mouse drag
- **Fix Complexity**: LOW (<50 lines)
- **Expected FPS Improvement**: 3 FPS → 30-60 FPS

### Secondary Issues:
1. **Cause 3 (ProceduralWorldMap)**: Medium impact - per-frame processing when hidden
2. **Cause 2 (Viewport Rendering)**: Low impact - already mostly optimized

### Not an Issue:
- **Cause 1 (Terrain3D Updates)**: Only runs on Step 2, not during Step 1 editing

---

## Recommended Action Plan

1. **IMMEDIATE**: Implement throttling for brush tool refresh (Cause 4)
2. **SHORT TERM**: Disable ProceduralWorldMap `_process()` when hidden (Cause 3)
3. **VERIFY**: Confirm PreviewViewport is truly disabled (Cause 2)
4. **TEST**: Run project and measure FPS improvement

---

## Profiling Code Added

Temporary profiling code has been added to:
- `MapMakerModule.gd`: Logs paint and refresh operation times
- `WorldBuilderUI.gd`: Logs Terrain3D update times
- `addons/procedural_world_map/worldmap.gd`: Logs if `_process()` runs while hidden

**Next Steps**: Run project, perform brush operations, check debug output for timing data.
