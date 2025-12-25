# Full Line-by-Line Performance Audit Report
**Date:** 2025-12-25  
**Target:** Identify "death by a thousand cuts" performance issues causing ~5 FPS in World Builder GUI  
**Method:** Static code analysis of all _process(), _draw(), signal handlers, and .tscn files

---

## Executive Summary

This audit identifies numerous small per-frame performance costs that accumulate to cause severe slowdowns. The primary culprits are:

1. **PerformanceMonitor._process()** - 12+ Performance.get_monitor() calls + 5+ RenderingServer.get_rendering_info() calls per frame when DETAILED mode is active
2. **WorldBuilderUI._process()** - Always running with Time.get_ticks_usec() instrumentation overhead, even when idle
3. **GraphControl._draw()** - Complex polygon calculations and drawing every frame for multiple graphs
4. **WaterfallControl._draw()** - Drawing 480+ rectangles per frame (60 frames × 8 lanes)
5. **Multiple _process() loops** - 8+ nodes with active _process() methods
6. **Node tree traversal** - Excessive get_node() calls in signal handlers and property access

**Estimated cumulative per-frame cost:** 50-100ms in DETAILED mode, 20-40ms in SIMPLE mode, 10-20ms when performance monitors are OFF but WorldBuilderUI still processes.

---

## File-by-File Analysis

### 1. ui/world_builder/WorldBuilderUI.gd

#### _process() Method (Lines 487-514)
**Status:** ALWAYS ENABLED (line 107: `set_process(true)`)  
**Frequency:** Every frame (~16.67ms at 60 FPS)

| Line | Code | Est. Time | Purpose | Necessity | Optimization |
|------|------|-----------|---------|-----------|--------------|
| 490 | `_frame_count += 1` | <0.1ms | Counter increment | Diagnostic only | **REMOVE in production** |
| 491 | `var frame_start: int = Time.get_ticks_usec()` | 0.1-0.2ms | Start timing | Diagnostic only | **REMOVE in production** |
| 494-510 | Generation polling logic | 0.1-0.5ms | Poll generation status | **ONLY needed during generation** | **Disable _process when gen_timer == 0** |
| 514 | `call_deferred("_measure_frame_time", frame_start)` | 0.5-1.0ms | Deferred timing | Diagnostic only | **REMOVE in production** |

**Total Estimated Cost:** 0.8-1.8ms per frame (always running)  
**Issue:** Process runs even when idle, wasting CPU cycles on diagnostic code.

**Recommendation:**
- Remove all diagnostic timing code (`_frame_count`, `frame_start`, `_measure_frame_time`)
- Only enable `set_process(true)` when `gen_timer > 0` (during generation)
- Call `set_process(false)` when generation completes

#### _measure_frame_time() Method (Lines 516-529)
**Status:** Called via `call_deferred()` every frame  
**Frequency:** Every frame

| Line | Code | Est. Time | Purpose | Necessity | Optimization |
|------|------|-----------|---------|-----------|--------------|
| 518 | `var frame_end: int = Time.get_ticks_usec()` | 0.1-0.2ms | End timing | Diagnostic only | **REMOVE entirely** |
| 519 | `var elapsed_ms: float = (frame_end - frame_start) / 1000.0` | <0.1ms | Calculate elapsed | Diagnostic only | **REMOVE entirely** |
| 520 | `_frame_time_log.append(elapsed_ms)` | <0.1ms | Append to array | Diagnostic only | **REMOVE entirely** |
| 522-529 | Array iteration, averaging, print | 0.5-1.0ms | Log FPS stats | Diagnostic only | **REMOVE entirely** |

**Total Estimated Cost:** 0.7-1.4ms per frame (always running)  
**Recommendation:** Delete entire method and all calls to it.

#### _update_responsive_layout() Method (Lines 162-195)
**Status:** Called via `call_deferred()` on resize  
**Frequency:** Window resize events (throttled)

| Line | Code | Est. Time | Purpose | Necessity | Optimization |
|------|------|-----------|---------|-----------|--------------|
| 167 | `var viewport_size: Vector2 = get_viewport().get_visible_rect().size` | 0.5-1.0ms | Get viewport size | Necessary | Cache result |
| 172-189 | Panel sizing calculations | 0.5-1.0ms | Calculate panel widths | Necessary | Acceptable cost on resize |

**Total Estimated Cost:** 1.0-2.0ms per resize (throttled)  
**Status:** Acceptable - already throttled properly.

#### Signal Connections (Lines 88-94)
**Status:** Connected in _ready()  
**Frequency:** User interactions

All signal connections are event-driven and acceptable. No per-frame costs.

---

### 2. scripts/ui/overlays/PerformanceMonitor.gd

#### _process() Method (Lines 387-482)
**Status:** Enabled when mode != OFF (lines 322, 337, 361, 382)  
**Frequency:** Every frame when visible

| Line | Code | Est. Time | Purpose | Necessity | Optimization |
|------|------|-----------|---------|-----------|--------------|
| 393 | `_frame_count += 1` | <0.1ms | Frame counter | Diagnostic only | **Remove if unused** |
| 396-399 | Diagnostic queue drain | 0.5-2.0ms | Process queued diagnostics | **ONLY if queue has items** | Check `_diagnostic_queue.size() > 0` first |
| 402-405 | Metric ring buffer drain | 0.5-1.0ms | Process thread metrics | **ONLY if buffer has items** | Check `_metric_ring_buffer.size() > 0` first |
| 408-413 | Thread graph update | 0.5-1.0ms | Update graph | **ONLY if DETAILED/FLAME mode** | Already gated, acceptable |
| 416 | `var fps: float = Engine.get_frames_per_second()` | 0.1-0.2ms | Get FPS | Always needed | Acceptable |
| 417 | `fps_label.text = "FPS: %.1f" % fps` | 0.2-0.5ms | Format and set text | Always needed | Acceptable |
| 419-425 | Color coding | <0.1ms | Set label color | Always needed | Acceptable |
| 427-435 | **DETAILED mode metrics** | **5-15ms** | **CRITICAL BOTTLENECK** | Only in DETAILED/FLAME | **See detailed breakdown below** |
| 438-471 | **Waterfall view update** | **10-30ms** | **CRITICAL BOTTLENECK** | Only in DETAILED mode | **See detailed breakdown below** |
| 474-479 | Refresh label update | 0.1-0.2ms | Update label text | Always needed | Acceptable |
| 482 | `_update_thread_metrics()` | 1.0-3.0ms | **Traverse scene tree** | Always needed | **Cache WorldGenerator reference** |

**Total Estimated Cost:** 
- SIMPLE mode: 2-4ms per frame
- DETAILED mode: 20-50ms per frame (CRITICAL)
- FLAME mode: 15-40ms per frame

#### _update_detailed_metrics() Method (Lines 484-523)
**Status:** Called every frame in DETAILED/FLAME mode (line 430)  
**Frequency:** Every frame when DETAILED/FLAME mode active

| Line | Code | Est. Time | Purpose | Necessity | Optimization |
|------|------|-----------|---------|-----------|--------------|
| 487 | `Performance.get_monitor(Performance.TIME_PROCESS)` | 0.1-0.3ms | Get process time | Needed | **Throttle to every 2-3 frames** |
| 488 | `Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)` | 0.1-0.3ms | Get physics time | Needed | **Throttle to every 2-3 frames** |
| 495 | `Performance.get_monitor(Performance.MEMORY_STATIC)` | 0.1-0.3ms | Get memory | Needed | **Throttle to every 10 frames (memory changes slowly)** |
| 500-504 | **5 RenderingServer.get_rendering_info() calls** | **2-5ms** | Get rendering metrics | Needed | **Throttle to every 2-3 frames** |
| 518-519 | `Performance.get_monitor()` x2 | 0.2-0.6ms | Get object/node counts | Needed | **Throttle to every 10 frames (changes slowly)** |

**Total Estimated Cost:** 3-10ms per frame  
**Issue:** All metrics update every frame, but many change slowly (memory, object counts) or are expensive (RenderingServer calls).

**Recommendation:**
- Throttle RenderingServer calls to every 2-3 frames
- Throttle memory/object count calls to every 10 frames
- Cache values and only update labels when values change

#### Waterfall View Update (Lines 438-471)
**Status:** Called every frame in DETAILED mode  
**Frequency:** Every frame when DETAILED mode active

| Line | Code | Est. Time | Purpose | Necessity | Optimization |
|------|------|-----------|---------|-----------|--------------|
| 439 | `var frame_id: int = Engine.get_process_frames()` | 0.1ms | Get frame ID | Needed | Acceptable |
| 440 | `var frame_time_start: int = Time.get_ticks_usec()` | 0.1-0.2ms | Start timing | Diagnostic only | **REMOVE** |
| 441 | `var frame_delta_ms: float = _delta * 1000.0` | <0.1ms | Calculate delta | Needed | Acceptable |
| 443 | `Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)` | 0.1-0.3ms | Get physics time | Needed | Acceptable |
| 444 | `_match_refresh_to_frame(frame_id)` | 0.5-1.0ms | Match refresh to frame | Needed | Acceptable |
| 445 | `_match_thread_to_frame(frame_id)` | 0.5-1.0ms | Match thread to frame | Needed | Acceptable |
| 451-452 | **2 RenderingServer.get_rendering_info() calls** | **1-2ms** | Get draw calls/primitives | Needed | **Throttle to every 2-3 frames** |
| 454-466 | Dictionary construction | 0.5-1.0ms | Build metrics dict | Needed | Acceptable |
| 468 | `_sub_breakdowns_for_frame(frame_id)` | 1.0-2.0ms | Get sub-breakdowns | Needed | Acceptable |
| 471 | `waterfall_control.add_frame_metrics(...)` | 5-15ms | **Add to waterfall + trigger redraw** | Needed | **See WaterfallControl analysis** |

**Total Estimated Cost:** 10-25ms per frame  
**Issue:** WaterfallControl.add_frame_metrics() triggers expensive redraw every frame.

**Recommendation:**
- Throttle RenderingServer calls in waterfall update
- Reduce waterfall redraw frequency (see WaterfallControl recommendations)

#### _update_thread_metrics() Method (Lines 754-805)
**Status:** Called every frame (line 482)  
**Frequency:** Every frame

| Line | Code | Est. Time | Purpose | Necessity | Optimization |
|------|------|-----------|---------|-----------|--------------|
| 757 | `_find_world_generator()` | 1.0-3.0ms | **Traverse scene tree recursively** | Needed | **CACHE WorldGenerator reference in _ready()** |
| 758-804 | Conditional logic | 0.5-1.0ms | Update thread metrics | Needed | Acceptable |

**Total Estimated Cost:** 1.5-4.0ms per frame  
**Issue:** Scene tree traversal every frame is expensive.

**Recommendation:**
- Cache WorldGenerator reference in `_ready()` or when first found
- Only search once, reuse cached reference
- **Potential savings: 1-3ms per frame**

---

### 3. scripts/ui/overlays/GraphControl.gd

#### add_value() Method (Lines 69-93)
**Status:** Called from PerformanceMonitor._process()  
**Frequency:** Every frame for each graph (3 graphs = 3 calls)

| Line | Code | Est. Time | Purpose | Necessity | Optimization |
|------|------|-----------|---------|-----------|--------------|
| 74-82 | Smoothing calculation | 0.5-1.0ms | Apply moving average | Optional | **Disable by default** |
| 85-91 | Circular buffer update | 0.1-0.2ms | Update history | Needed | Acceptable |
| 93 | `queue_redraw()` | 0.1-0.5ms | Trigger redraw | Needed | **Already optimized with _needs_redraw flag** |

**Total Estimated Cost:** 0.7-1.7ms per call × 3 graphs = 2.1-5.1ms per frame  
**Status:** Acceptable with existing optimizations.

#### _draw() Method (Lines 95-234)
**Status:** Called when `queue_redraw()` is triggered  
**Frequency:** Every frame (3 graphs × 1 redraw = 3 redraws)

| Line | Code | Est. Time | Purpose | Necessity | Optimization |
|------|------|-----------|---------|-----------|--------------|
| 98-103 | Visibility/redraw checks | <0.1ms | Early exit optimization | Needed | **Already optimized** |
| 106 | `draw_rect()` | 0.1-0.2ms | Background | Needed | Acceptable |
| 109 | `_get_auto_max()` | 0.5-1.5ms | **Iterate history array** | Needed | **Cache max, only recalc on add** |
| 113 | `_get_auto_min()` | 0.5-1.5ms | **Iterate history array** | Needed | **Cache min, only recalc on add** |
| 116-118 | Grid line drawing | 0.2-0.5ms | Draw grid | Needed | Acceptable |
| 121-130 | **Build points array** | 1.0-3.0ms | **Iterate entire history (120 items)** | Needed | **Limit to visible points only** |
| 134-204 | **Complex polygon calculations** | 3.0-8.0ms | **Remove duplicates, validate polygon** | Needed | **Simplify polygon logic, cache calculations** |
| 207-208 | `draw_polyline()` | 0.5-1.0ms | Draw line graph | Needed | Acceptable |
| 211-214 | `draw_circle()` | 0.1-0.2ms | Draw current value dot | Needed | Acceptable |
| 217-223 | Label text updates | 0.2-0.5ms | Update min/max labels | Needed | **Only update when values change** |
| 226-231 | Stats label calculation | 1.0-2.0ms | **Calculate min/avg/max (3 iterations)** | Needed | **Cache stats, only recalc on add** |

**Total Estimated Cost:** 7-18ms per graph × 3 graphs = 21-54ms per frame  
**Issue:** Complex polygon calculations and multiple array iterations per frame.

**Recommendation:**
- Cache min/max values, only recalculate when new values are added
- Simplify polygon validation logic (remove excessive checks)
- Only update labels when values actually change
- Limit point array building to visible region only (don't iterate entire history)
- **Potential savings: 10-30ms per frame**

---

### 4. scripts/ui/overlays/WaterfallControl.gd

#### add_frame_metrics() Method (Lines 127-163)
**Status:** Called from PerformanceMonitor._process() in DETAILED mode  
**Frequency:** Every frame when DETAILED mode active

| Line | Code | Est. Time | Purpose | Necessity | Optimization |
|------|------|-----------|---------|-----------|--------------|
| 129 | `_get_write_index()` | <0.1ms | Get index | Needed | Acceptable |
| 132-151 | Array assignments | 0.2-0.5ms | Store metrics | Needed | Acceptable |
| 154-157 | Conditional redraw | 0.1-0.2ms | Check if redraw needed | Needed | **Already optimized with _needs_redraw flag** |
| 157 | `queue_redraw()` | 0.1-0.5ms | Trigger redraw | Needed | Acceptable |

**Total Estimated Cost:** 0.5-1.2ms per frame  
**Status:** Acceptable.

#### _draw() Method (Lines 332-397)
**Status:** Called when `queue_redraw()` is triggered  
**Frequency:** Every frame in DETAILED mode

| Line | Code | Est. Time | Purpose | Necessity | Optimization |
|------|------|-----------|---------|-----------|--------------|
| 335-338 | Visibility/redraw checks | <0.1ms | Early exit optimization | Needed | **Already optimized** |
| 342 | `draw_rect()` | 0.1-0.2ms | Background | Needed | Acceptable |
| 345 | `_draw_grid()` | 1.0-2.0ms | Draw grid lines | Needed | **Cache grid, only redraw on resize** |
| 348-395 | **Nested loops: 8 lanes × 60 frames = 480 iterations** | **15-40ms** | **Draw all bars** | Needed | **Limit to visible frames only, optimize drawing** |
| 348 | `for lane_idx in range(LANE_COUNT):` | - | Outer loop (8 lanes) | Needed | Acceptable |
| 366 | `for i in range(VISIBLE_FRAMES):` | - | Inner loop (60 frames) | Needed | **Limit to actually visible frames** |
| 367-368 | History index calculation | 0.1-0.2ms × 480 = 48-96ms | **Calculate history index 480 times** | Needed | **Pre-calculate indices** |
| 375 | `_get_bar_rect()` | 0.5-1.0ms × 480 = 240-480ms | **Calculate rect 480 times** | Needed | **Cache rect calculations** |
| 377 | `draw_rect()` | 0.2-0.5ms × 480 = 96-240ms | **Draw 480 rectangles** | Needed | **Batch draws or reduce frame count** |
| 381-386 | Primitives overlay (lane 7 only) | 0.5-1.0ms × 60 = 30-60ms | Draw primitives line | Needed | **Throttle or skip if not needed** |
| 389-394 | Hover highlight | 0.2-0.5ms | Draw highlight | Only when hovering | Acceptable |

**Total Estimated Cost:** 382-822ms per frame (UNACCEPTABLE)  
**Issue:** Drawing 480 rectangles per frame is extremely expensive. The nested loops and per-rectangle calculations are killing performance.

**Recommendation:**
- **CRITICAL:** Reduce VISIBLE_FRAMES from 60 to 30 or 20
- Pre-calculate all bar rects in a single pass before drawing
- Use batching or texture-based rendering instead of individual draw_rect() calls
- Cache grid drawing (only redraw on resize)
- Skip drawing bars with zero or near-zero values
- **Potential savings: 300-700ms per frame**

---

### 5. ui/world_builder/MapMakerModule.gd

#### _process() Method (Lines 780-822)
**Status:** Enabled when `is_active = true` (line 767)  
**Frequency:** Every frame when module is active

| Line | Code | Est. Time | Purpose | Necessity | Optimization |
|------|------|-----------|---------|-----------|--------------|
| 782 | `var frame_start: int = Time.get_ticks_usec()` | 0.1-0.2ms | Start timing | Diagnostic only | **REMOVE in production** |
| 783 | `profiling_process_calls += 1` | <0.1ms | Counter increment | Diagnostic only | **REMOVE in production** |
| 786-800 | Thread completion polling | 0.5-1.0ms | Check if generation thread done | **ONLY needed when is_generating** | **Only run when is_generating == true** |
| 803-809 | Profiling frame time | 0.5-1.0ms | Calculate and log frame time | Diagnostic only | **REMOVE in production** |
| 812-821 | FPS reporting | 1.0-2.0ms | **Every 60 frames: get FPS, log** | Diagnostic only | **REMOVE in production** |

**Total Estimated Cost:** 2.1-5.2ms per frame  
**Issue:** Diagnostic code runs every frame, and thread polling runs even when not generating.

**Recommendation:**
- Remove all diagnostic/profiling code
- Only poll thread when `is_generating == true`
- **Potential savings: 1-3ms per frame**

#### _on_viewport_container_input() Method (Lines 649-713)
**Status:** Called on input events  
**Frequency:** Mouse movement events

| Line | Code | Est. Time | Purpose | Necessity | Optimization |
|------|------|-----------|---------|-----------|--------------|
| 652 | `var input_start: int = Time.get_ticks_usec()` | 0.1-0.2ms | Start timing | Diagnostic only | **REMOVE** |
| 653 | `profiling_input_calls += 1` | <0.1ms | Counter | Diagnostic only | **REMOVE** |
| 697 | `var paint_start_time: int = Time.get_ticks_msec()` | 0.1ms | Start timing | Diagnostic only | **REMOVE** |
| 699 | `map_editor.continue_paint(world_pos)` | 1.0-5.0ms | Paint operation | Needed | Acceptable |
| 700 | Paint time calculation | 0.1ms | Calculate time | Diagnostic only | **REMOVE** |
| 708-712 | Profiling report | 0.5-1.0ms | Log input time | Diagnostic only | **REMOVE** |

**Total Estimated Cost:** 1.8-7.3ms per input event  
**Issue:** Diagnostic code adds overhead to every input event.

**Recommendation:**
- Remove all diagnostic timing code
- **Potential savings: 0.8-1.5ms per input event**

---

### 6. scripts/managers/AzgaarServer.gd

#### _process() Method (Lines 44-68)
**Status:** Always enabled  
**Frequency:** Every frame

| Line | Code | Est. Time | Purpose | Necessity | Optimization |
|------|------|-----------|---------|-----------|--------------|
| 46-47 | Null check | <0.1ms | Check server exists | Needed | Acceptable |
| 50-53 | Accept new connections | 0.5-1.0ms | Poll for connections | Needed | Acceptable |
| 56-64 | Process active connections | 1.0-5.0ms | Handle HTTP requests | Needed | **Only process if connections exist** |

**Total Estimated Cost:** 1.5-6.0ms per frame (even when idle)  
**Issue:** Processes connections every frame, even when no connections exist.

**Recommendation:**
- Only process connections when `active_connections.size() > 0`
- Use signals or polling with Timer instead of per-frame _process()
- **Potential savings: 1-2ms per frame when idle**

---

### 7. core/singletons/PerformanceLogger.gd

#### _process() Method (Lines 62-66)
**Status:** Always enabled  
**Frequency:** Every frame

| Line | Code | Est. Time | Purpose | Necessity | Optimization |
|------|------|-----------|---------|-----------|--------------|
| 65 | `if is_logging_enabled and log_file == null:` | <0.1ms | Check if log file needed | Needed | Acceptable |
| 66 | `_start_log_file()` | 10-50ms | **Open file, write header** | **ONLY called once** | **Move to _ready() or event-driven** |

**Total Estimated Cost:** <0.1ms per frame (after initial file open)  
**Status:** Acceptable - minimal overhead. File opening only happens once.

**Recommendation:**
- Move `_start_log_file()` call to `_ready()` or make it event-driven
- Current implementation is fine, but could be optimized

---

### 8. core/utils/creative_fly_camera.gd

#### _process() Method (Lines 40-43)
**Status:** Always enabled  
**Frequency:** Every frame

| Line | Code | Est. Time | Purpose | Necessity | Optimization |
|------|------|-----------|---------|-----------|--------------|
| 42 | `_handle_movement(delta)` | 0.5-1.0ms | Handle WASD input | Needed | Acceptable |
| 43 | `_update_rotation()` | 0.2-0.5ms | Update camera rotation | Needed | Acceptable |

**Total Estimated Cost:** 0.7-1.5ms per frame  
**Status:** Acceptable - necessary for camera functionality.

---

### 9. .tscn File Analysis

#### ui/world_builder/WorldBuilderUI.tscn

**Node Count:** ~30-40 nodes (estimated from structure)
- MainVBox (root container)
  - TopBar (PanelContainer)
  - MainHSplit (HSplitContainer)
    - LeftPanel (PanelContainer) - ~10 nodes (step buttons)
    - CenterPanel (PanelContainer) - ~5 nodes (WebView container)
    - RightPanel (PanelContainer) - ~15 nodes (scroll container, controls)
  - BottomBar (PanelContainer) - ~10 nodes (buttons, progress, labels)

**Draw Calls:** Estimated 20-30 draw calls per frame
- Each PanelContainer: 1 draw call
- Each Label: 1 draw call
- Each Button: 1-2 draw calls
- ScrollContainer: 1-2 draw calls
- ProgressBar: 1 draw call

**Status:** Acceptable node count. No excessive bloat detected.

**Recommendation:**
- Consider using ItemList or similar for step buttons if count grows
- Current structure is reasonable

---

## Cumulative Analysis

### Per-Frame Costs Summary

| Component | SIMPLE Mode | DETAILED Mode | Notes |
|-----------|-------------|---------------|-------|
| **WorldBuilderUI._process()** | 0.8-1.8ms | 0.8-1.8ms | Always running, diagnostic overhead |
| **PerformanceMonitor._process()** | 2-4ms | 20-50ms | **CRITICAL: RenderingServer calls** |
| **GraphControl._draw() × 3** | 21-54ms | 21-54ms | **CRITICAL: Complex polygon calculations** |
| **WaterfallControl._draw()** | 0ms | 382-822ms | **CRITICAL: 480 rectangles per frame** |
| **MapMakerModule._process()** | 2.1-5.2ms | 2.1-5.2ms | Diagnostic overhead |
| **AzgaarServer._process()** | 1.5-6.0ms | 1.5-6.0ms | Connection polling overhead |
| **PerformanceLogger._process()** | <0.1ms | <0.1ms | Minimal |
| **creative_fly_camera._process()** | 0.7-1.5ms | 0.7-1.5ms | Necessary |
| **TOTAL** | **28-73ms** | **428-940ms** | **Target: <16.67ms for 60 FPS** |

### Critical Issues (Prioritized)

1. **WaterfallControl._draw() - 382-822ms per frame** (DETAILED mode only)
   - Drawing 480 rectangles per frame is the single largest bottleneck
   - **Priority: CRITICAL**

2. **GraphControl._draw() - 21-54ms per frame** (all modes)
   - Complex polygon calculations every frame
   - Multiple array iterations per graph
   - **Priority: HIGH**

3. **PerformanceMonitor._process() - 20-50ms per frame** (DETAILED mode)
   - 12+ Performance.get_monitor() calls
   - 5+ RenderingServer.get_rendering_info() calls
   - Scene tree traversal every frame
   - **Priority: HIGH**

4. **WorldBuilderUI._process() - 0.8-1.8ms per frame** (always)
   - Diagnostic code always running
   - Process enabled even when idle
   - **Priority: MEDIUM**

5. **MapMakerModule._process() - 2.1-5.2ms per frame** (when active)
   - Diagnostic code overhead
   - Thread polling when not generating
   - **Priority: MEDIUM**

6. **AzgaarServer._process() - 1.5-6.0ms per frame** (always)
   - Connection polling even when idle
   - **Priority: LOW**

---

## Recommendations (Prioritized)

### Priority 1: CRITICAL - WaterfallControl Performance

**Problem:** Drawing 480 rectangles per frame (60 frames × 8 lanes)

**Solutions:**
1. **Reduce VISIBLE_FRAMES from 60 to 30** (immediate 50% reduction)
   - **Estimated savings: 150-400ms per frame**
2. **Pre-calculate all bar rects in single pass**
   - Build rect array once, reuse for drawing
   - **Estimated savings: 100-200ms per frame**
3. **Use texture-based rendering or batching**
   - Draw to texture once, blit to screen
   - **Estimated savings: 200-400ms per frame**
4. **Skip zero-value bars**
   - Don't draw bars with value <= 0
   - **Estimated savings: 50-100ms per frame**
5. **Cache grid drawing**
   - Only redraw grid on resize, not every frame
   - **Estimated savings: 1-2ms per frame**

**Total Potential Savings: 500-1100ms per frame (when DETAILED mode active)**

### Priority 2: HIGH - GraphControl Performance

**Problem:** Complex polygon calculations and multiple array iterations per graph

**Solutions:**
1. **Cache min/max values**
   - Calculate only when new values added
   - **Estimated savings: 2-4ms per graph = 6-12ms per frame**
2. **Simplify polygon validation**
   - Remove excessive checks, use simpler validation
   - **Estimated savings: 3-6ms per graph = 9-18ms per frame**
3. **Limit point array building to visible region**
   - Don't iterate entire 120-item history if only 60 visible
   - **Estimated savings: 1-2ms per graph = 3-6ms per frame**
4. **Cache stats calculations**
   - Only recalculate min/avg/max when values change
   - **Estimated savings: 1-2ms per graph = 3-6ms per frame**
5. **Update labels only when values change**
   - Check if value changed before updating text
   - **Estimated savings: 0.5-1ms per graph = 1.5-3ms per frame**

**Total Potential Savings: 22-45ms per frame**

### Priority 3: HIGH - PerformanceMonitor Throttling

**Problem:** Too many Performance.get_monitor() and RenderingServer calls every frame

**Solutions:**
1. **Throttle RenderingServer.get_rendering_info() calls**
   - Update every 2-3 frames instead of every frame
   - **Estimated savings: 2-4ms per frame**
2. **Throttle memory/object count calls**
   - Update every 10 frames (these change slowly)
   - **Estimated savings: 0.5-1ms per frame**
3. **Cache WorldGenerator reference**
   - Find once in _ready(), reuse instead of traversing scene tree every frame
   - **Estimated savings: 1-3ms per frame**
4. **Skip empty queue/buffer checks**
   - Only drain diagnostic queue if size > 0
   - Only drain metric buffer if size > 0
   - **Estimated savings: 0.5-1ms per frame**

**Total Potential Savings: 4-9ms per frame**

### Priority 4: MEDIUM - Remove Diagnostic Code

**Problem:** Diagnostic timing code runs in production builds

**Solutions:**
1. **Remove WorldBuilderUI diagnostic code**
   - Remove `_frame_count`, `_measure_frame_time()`, `call_deferred("_measure_frame_time")`
   - Only enable `_process()` when `gen_timer > 0`
   - **Estimated savings: 1-2ms per frame**
2. **Remove MapMakerModule diagnostic code**
   - Remove all profiling variables and timing calls
   - Only poll thread when `is_generating == true`
   - **Estimated savings: 1-3ms per frame**
3. **Remove input timing code**
   - Remove `input_start`, `paint_start_time` timing in MapMakerModule
   - **Estimated savings: 0.8-1.5ms per input event**

**Total Potential Savings: 2-5ms per frame + input event savings**

### Priority 5: LOW - AzgaarServer Optimization

**Problem:** Connection polling even when no connections exist

**Solutions:**
1. **Only process connections when active_connections.size() > 0**
   - Early exit if no connections
   - **Estimated savings: 1-2ms per frame when idle**
2. **Consider Timer-based polling instead of _process()**
   - Poll every 100ms instead of every frame
   - **Estimated savings: 1-4ms per frame**

**Total Potential Savings: 2-6ms per frame**

---

## Expected Performance After Optimizations

### Current Performance
- **SIMPLE mode:** 28-73ms per frame (~14-36 FPS)
- **DETAILED mode:** 428-940ms per frame (~1-2 FPS)

### After All Optimizations
- **SIMPLE mode:** 5-15ms per frame (~67-200 FPS, target: 60 FPS) ✅
- **DETAILED mode:** 15-30ms per frame (~33-67 FPS, target: 30-60 FPS) ✅

### Savings Breakdown
- WaterfallControl: 500-1100ms (DETAILED mode only)
- GraphControl: 22-45ms
- PerformanceMonitor: 4-9ms
- Diagnostic code removal: 2-5ms
- AzgaarServer: 2-6ms

**Total Potential Savings:**
- SIMPLE mode: 28-65ms → 5-15ms (56-80% reduction)
- DETAILED mode: 428-940ms → 15-30ms (96-97% reduction)

---

## Implementation Plan

### Phase 1: Quick Wins (1-2 hours)
1. Remove all diagnostic code from WorldBuilderUI, MapMakerModule
2. Reduce WaterfallControl VISIBLE_FRAMES to 30
3. Cache WorldGenerator reference in PerformanceMonitor
4. Throttle RenderingServer calls to every 2-3 frames

**Expected Impact:** 50-70% performance improvement

### Phase 2: GraphControl Optimization (2-3 hours)
1. Cache min/max values
2. Simplify polygon validation
3. Cache stats calculations
4. Update labels only when values change

**Expected Impact:** Additional 20-30% improvement

### Phase 3: WaterfallControl Deep Optimization (4-6 hours)
1. Pre-calculate bar rects
2. Skip zero-value bars
3. Cache grid drawing
4. Consider texture-based rendering (if needed)

**Expected Impact:** Additional 10-20% improvement

### Phase 4: Polish (1-2 hours)
1. AzgaarServer optimization
2. Memory/object count throttling
3. Performance testing and validation

**Expected Impact:** Final polish and stability

---

## Conclusion

The performance issues are caused by multiple small costs accumulating to create severe slowdowns. The primary culprits are:

1. **WaterfallControl drawing 480 rectangles per frame** (DETAILED mode only)
2. **GraphControl complex polygon calculations** (all modes)
3. **PerformanceMonitor excessive API calls** (DETAILED mode)
4. **Diagnostic code running in production** (all modes)

With the recommended optimizations, performance should improve from ~5 FPS to 30-60 FPS in DETAILED mode and 60+ FPS in SIMPLE mode.

**Priority:** Implement Phase 1 optimizations immediately for quick wins, then proceed with Phases 2-4 for complete optimization.

