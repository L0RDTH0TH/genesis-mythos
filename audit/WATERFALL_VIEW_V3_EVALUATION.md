# Waterfall View v3 Specification - Evaluation & Improvements

**Date:** 2025-01-06  
**Spec Version:** v3  
**Status:** Technical Review - Critical Issues & Recommendations

---

## Executive Summary

The v3 Waterfall View specification is **well-conceived and addresses real diagnostic needs**, but contains **several critical technical gaps** that would cause data synchronization issues, rendering problems, and performance overhead. This evaluation identifies superior approaches and missing considerations.

**Severity Breakdown:**
- 🔴 **CRITICAL:** Frame synchronization, data structure efficiency, interaction model
- 🟡 **HIGH:** Script time estimation, combined lane visualization, memory overhead
- 🟢 **MEDIUM:** Pan/zoom navigation, tooltip performance, sub-metric frame association

---

## 1. 🔴 CRITICAL: Frame Synchronization Problem

### Issue
The spec doesn't address how to ensure **all metrics are from the same frame**. Current implementation has inherent timing mismatches:

**Current Data Collection Timing:**
```gdscript
# In _process() - these happen at DIFFERENT times:
var process_ms = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0  # Cumulative since last call
var physics_ms = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0  # Cumulative
refresh_time_ms  # Set asynchronously from MapRenderer.refresh() - may be from previous frame!
thread_compute_time_ms  # Aggregated from ring buffer - timestamp-based matching needed
```

**Problem:** `refresh_time_ms` is set when `MapRenderer.refresh()` completes, which may be **0-N frames ago**. If refresh doesn't happen every frame, you'll show stale or missing data.

### Superior Approach

**Option A: Frame-Synchronized Collection (Recommended)**
```gdscript
# In PerformanceMonitor._process()
func _process(_delta: float) -> void:
    if current_mode != Mode.DETAILED:
        return
    
    # Collect ALL metrics for THIS frame atomically
    var frame_id: int = Engine.get_process_frames()
    var frame_time_start: int = Time.get_ticks_usec()
    
    var primary_metrics = {
        frame_id = frame_id,
        frame_delta_ms = _delta * 1000.0,
        process_ms = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
        physics_ms = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
        # Capture refresh from LAST frame's async update (with frame_id check)
        refresh_ms = _last_reported_refresh_ms if _last_refresh_frame_id == frame_id - 1 else 0.0,
        thread_ms = _get_aggregated_thread_time_for_frame(frame_id),
        draw_calls = RenderingServer.get_rendering_info(...),  # Only if _frame_count >= 3
        primitives = RenderingServer.get_rendering_info(...),
        timestamp_usec = frame_time_start
    }
    
    waterfall_control.add_frame_metrics(primary_metrics, _sub_breakdowns_for_frame(frame_id))
```

**Option B: Frame Tagging System (For Async Metrics)**
```gdscript
# In MapRenderer._do_actual_refresh()
var refresh_end_frame: int = Engine.get_process_frames()
PerformanceMonitorSingleton.push_refresh_timing({
    "frame_id": refresh_end_frame,
    "time_ms": refresh_time_ms,
    "timestamp_usec": Time.get_ticks_usec()
})

# In PerformanceMonitor - match to frame
func _match_refresh_to_frame(frame_id: int) -> float:
    for metric in _refresh_metrics_buffer:
        if metric.frame_id == frame_id or metric.frame_id == frame_id - 1:
            return metric.time_ms
    return 0.0  # No refresh this frame
```

**Recommendation:** Use **Option B** - frame tagging allows async metrics to be correctly associated with their originating frame. Maintain a small buffer of recent refresh/thread metrics keyed by frame_id.

---

## 2. 🔴 CRITICAL: Data Structure Memory Overhead

### Issue
Switching from `PackedFloat32Array` (GraphControl) to `Array[Dictionary]` introduces **significant memory overhead**:

- **GraphControl:** 120 samples × 4 bytes = 480 bytes per graph
- **WaterfallControl (proposed):** 120 samples × ~200 bytes (Dictionary overhead + keys) = ~24KB per instance

For 7 lanes with sub-metrics, this could balloon to **100KB+** just for history storage.

### Superior Approach

**Hybrid Structure: Parallel Arrays (Recommended)**
```gdscript
class_name WaterfallControl
extends Control

# Primary metrics - use PackedFloat32Array for efficiency (like GraphControl)
var history_process: PackedFloat32Array = PackedFloat32Array()
var history_physics: PackedFloat32Array = PackedFloat32Array()
var history_refresh: PackedFloat32Array = PackedFloat32Array()
var history_thread: PackedFloat32Array = PackedFloat32Array()
var history_idle: PackedFloat32Array = PackedFloat32Array()
var history_draw_calls: PackedInt32Array = PackedInt32Array()
var history_primitives: PackedInt32Array = PackedInt32Array()

# Sub-breakdowns - sparse array (only populated when available)
# Indexed by [frame_index][category] -> Dictionary
var history_sub: Array[Dictionary] = []  # Only grows when breakdowns exist

# Frame metadata (minimal)
var history_frame_ids: PackedInt32Array = PackedInt32Array()  # For matching sub-metrics

const HISTORY_SIZE: int = UIConstants.PERF_HISTORY_SIZE
var history_index: int = 0
var history_full: bool = false

func add_frame_metrics(primary: Dictionary, sub_metrics: Array[Dictionary] = []) -> void:
    # Store primaries in typed arrays (efficient)
    _append_to_buffer(history_process, primary.get("process_ms", 0.0))
    _append_to_buffer(history_physics, primary.get("physics_ms", 0.0))
    # ... etc
    
    # Store sub-metrics only if present (sparse)
    if sub_metrics.size() > 0:
        if history_sub.size() <= history_index:
            history_sub.resize(HISTORY_SIZE)
        history_sub[history_index] = _organize_sub_metrics(sub_metrics)
    
    history_frame_ids[_get_write_index()] = primary.get("frame_id", -1)
    queue_redraw()

func _append_to_buffer(buffer: PackedFloat32Array, value: float) -> void:
    # Circular buffer logic (same as GraphControl)
    if buffer.size() < HISTORY_SIZE:
        buffer.append(value)
    else:
        buffer[history_index] = value
```

**Memory Comparison:**
- **Spec (Array[Dictionary]):** ~24KB for 120 frames
- **Hybrid (PackedArrays):** ~1.2KB for 120 frames (primary metrics)
- **Savings:** ~95% reduction in memory footprint

**Recommendation:** Use parallel `PackedFloat32Array`/`PackedInt32Array` for primary metrics, sparse `Array[Dictionary]` only for sub-breakdowns. Maintain frame_id array for correlation.

---

## 3. 🔴 CRITICAL: Idle/GPU Wait Calculation Error

### Issue
Spec says: `Idle / GPU Wait = Calculated (33.33 - cpu_total_ms)`

**Problem:** This assumes a **fixed 30 FPS frame budget** (33.33ms). In reality:
- Frame time varies (delta from `_process(_delta)`)
- Target is 60 FPS (16.67ms), not 30 FPS
- GPU wait should be relative to **actual frame time**, not assumed budget

### Superior Approach

```gdscript
# In _process(_delta: float) - use actual frame delta
var frame_delta_ms: float = _delta * 1000.0
var cpu_total_ms: float = process_ms + physics_ms + refresh_ms + thread_ms
var idle_gpu_wait_ms: float = max(0.0, frame_delta_ms - cpu_total_ms)

# Or more accurately (if you can measure GPU time):
# idle_gpu_wait_ms = frame_delta_ms - (cpu_total_ms + gpu_time_ms)
```

**Alternative:** If GPU time isn't measurable, use **target frame time** but make it configurable:
```gdscript
var target_frame_time_ms: float = 16.67  # 60 FPS target (configurable)
var idle_gpu_wait_ms: float = max(0.0, target_frame_time_ms - cpu_total_ms)

# Visual indicator: If frame_delta_ms > target_frame_time_ms, show "CPU Bound" lane in red
```

**Recommendation:** Use `_delta * 1000.0` as frame time, calculate idle as `max(0.0, frame_delta_ms - cpu_total_ms)`. Add visual indicator when frame time exceeds target.

---

## 4. 🟡 HIGH: Script Time Estimation - Vague Implementation

### Issue
Spec says: *"Script Time (new – approximate) – Estimated via custom monitor or subtraction – Green"*

**Problem:** There's **no reliable way** to measure "script-only" time in Godot without custom instrumentation everywhere. `Performance.get_monitor(Performance.TIME_PROCESS)` includes:
- GDScript execution
- Engine overhead
- C++ function calls
- Signal dispatching
- etc.

**Attempted Approaches & Why They Fail:**

**Option A: Subtraction (WRONG)**
```gdscript
# This doesn't work - process_ms already includes physics, refresh, etc.
var script_time = process_ms - physics_ms  # Physics is SEPARATE, not part of process
```

**Option B: Custom Instrumentation (REQUIRED)**
```gdscript
# Would require wrapping EVERY function call:
var script_start = Time.get_ticks_usec()
my_function()
var script_end = Time.get_ticks_usec()
# Prohibitively expensive and incomplete
```

**Option C: Performance.TIME_SCRIPT (DOESN'T EXIST)**
Godot doesn't expose script-only timing via Performance API.

### Superior Approach

**Remove Script Time Lane OR Make It Optional/Derived:**

```gdscript
# Option 1: Remove "Script Time" - not reliably measurable
# Lanes: Process, Physics, Refresh, Thread, Idle, Draw Calls

# Option 2: Replace with "Other Process" (derived)
var other_process_ms = max(0.0, process_ms - refresh_ms - thread_ms)
# Shows everything in process_ms that isn't refresh or thread
# Still approximate but more useful than claiming "script time"

# Option 3: Make it user-configurable instrumentation hook
# Add PerformanceMonitorSingleton.push_script_timing(label: String, ms: float)
# Only populated if developers explicitly instrument code
```

**Recommendation:** **Replace "Script Time" with "Other Process Time"** calculated as `max(0.0, process_ms - refresh_ms - thread_ms)`. Document it as "Process time not attributed to Refresh/Thread". Add future hook for explicit instrumentation if needed.

---

## 5. 🟡 HIGH: Draw Calls + Primitives Combined Lane Problem

### Issue
Spec proposes combining draw calls (typically 100-2000) and primitives (typically 100K-10M) in **one lane**. These have **wildly different scales**:

- Draw calls: 100-2000 range
- Primitives: 100,000-10,000,000 range

Showing both as bars in the same lane would make draw calls invisible (primitive bar dominates).

### Superior Approaches

**Option A: Dual-Scale Visualization (Recommended)**
```gdscript
# Draw Calls: Solid bar, left-aligned, scale: 0-2000
# Primitives: Overlay line or secondary bar, right-aligned, normalized scale: 0-1.0

func _draw_lane_7(lane_rect: Rect2, frame_index: int) -> void:
    var draw_calls = history_draw_calls[frame_index]
    var primitives = history_primitives[frame_index]
    
    # Normalize primitives to 0-1.0 range based on max seen
    var primitives_normalized = primitives / max(1.0, _max_primitives_seen)
    
    # Draw Calls: Bar from left edge
    var draw_calls_width = (draw_calls / 2000.0) * lane_rect.size.x
    draw_rect(Rect2(lane_rect.position, Vector2(draw_calls_width, lane_rect.size.y)), Color.PURPLE)
    
    # Primitives: Overlay line (or semi-transparent bar from right)
    var primitives_y = lane_rect.position.y + (1.0 - primitives_normalized) * lane_rect.size.y
    draw_line(
        Vector2(lane_rect.position.x, primitives_y),
        Vector2(lane_rect.position.x + lane_rect.size.x, primitives_y),
        Color.MAGENTA,
        2.0
    )
```

**Option B: Separate Lanes**
Make Lane 7 "Draw Calls" and add Lane 8 "Primitives" (but this increases complexity).

**Option C: Toggle/Radio Button**
User can switch between "Draw Calls" and "Primitives" view (single lane, different metric).

**Recommendation:** Use **Option A** - dual-scale visualization with draw calls as solid bar and primitives as overlay line. Add tooltip showing both absolute values.

---

## 6. 🟡 HIGH: Sub-Metrics Frame Association

### Issue
Spec says: *"sub_metrics: Array[Dictionary] per category for breakdowns"* but doesn't specify how to **associate sub-metrics with their parent frame**.

**Problem:** When `MapRenderer.refresh()` completes and pushes breakdown `{culling: 2.1, mesh: 5.4}`, how do you know which frame it belongs to? The refresh might complete **N frames after** it started.

### Superior Approach

**Frame Tagging System (Extend Option B from Section 1):**

```gdscript
# In PerformanceMonitorSingleton
func push_refresh_breakdown(breakdown: Dictionary, frame_id: int = -1) -> void:
    if frame_id == -1:
        frame_id = Engine.get_process_frames()  # Current frame
    
    _refresh_breakdown_buffer.append({
        "frame_id": frame_id,
        "breakdown": breakdown,
        "timestamp_usec": Time.get_ticks_usec()
    })
    # Keep last 10 frames of breakdowns
    if _refresh_breakdown_buffer.size() > 10:
        _refresh_breakdown_buffer.pop_front()

# In PerformanceMonitor._process()
func _sub_breakdowns_for_frame(frame_id: int) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    
    # Match refresh breakdowns
    for breakdown in _refresh_breakdown_buffer:
        if breakdown.frame_id == frame_id or breakdown.frame_id == frame_id - 1:
            result.append({"category": "refresh", "breakdown": breakdown.breakdown})
            break  # Only one refresh per frame
    
    # Match thread breakdowns similarly
    # ...
    
    return result
```

**Recommendation:** All async metric pushes must include `frame_id` parameter. Match sub-metrics to frames using frame_id ± 1 tolerance (for async completion).

---

## 7. 🟢 MEDIUM: Interaction Model - Missing Pan/Zoom

### Issue
At 120 frames displayed across full viewport width (1920px), each frame is **~16px wide**. This is:
- **Too narrow** for accurate hover/click interactions
- **No way to zoom** into specific time ranges
- **No panning** to navigate history beyond last 120 frames

### Superior Approaches

**Option A: Zoom Slider + Pan**
```gdscript
# Add UI controls:
@onready var zoom_slider: HSlider  # 1x to 10x zoom
@onready var pan_offset: int = 0  # Frames to offset from current

# In _draw():
var visible_frames = HISTORY_SIZE / zoom_level  # e.g., 120 frames at 1x, 12 frames at 10x
var start_frame = max(0, history_index - visible_frames - pan_offset)

# Draw only visible frames
for i in range(visible_frames):
    var frame_idx = (start_frame + i) % HISTORY_SIZE
    _draw_frame_bars(frame_idx, i)
```

**Option B: Scroll Wheel Zoom + Click-Drag Pan**
```gdscript
func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            zoom_level = min(10.0, zoom_level * 1.1)
            queue_redraw()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            zoom_level = max(1.0, zoom_level / 1.1)
            queue_redraw()
        elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            _pan_start_pos = event.position
            _is_panning = true
    elif event is InputEventMouseMotion and _is_panning:
        var delta = event.position - _pan_start_pos
        pan_offset += int(delta.x / (size.x / visible_frames))
        queue_redraw()
```

**Recommendation:** **Defer to v4** but document as "Future Enhancement". For v3, increase frame width by reducing visible frames (show last 60 frames instead of 120) OR make frame width configurable via UIConstants.

---

## 8. 🟢 MEDIUM: Tooltip Performance

### Issue
Tooltip on hover requires:
1. Raycast to determine frame index
2. Lookup frame data from history
3. Format all 7+ metric values as text
4. Calculate position (avoid off-screen)

**Problem:** If hover triggers `queue_redraw()` every frame, this adds **significant overhead** (tooltip redraw + main graph redraw).

### Superior Approach

**Deferred Tooltip Rendering:**
```gdscript
var _tooltip_frame_index: int = -1
var _tooltip_position: Vector2
var _tooltip_visible: bool = false

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        var frame_idx = _get_frame_index_from_position(event.position)
        if frame_idx != _tooltip_frame_index:
            _tooltip_frame_index = frame_idx
            _tooltip_position = event.position
            _tooltip_visible = true
            # Only queue tooltip redraw (not full graph)
            _update_tooltip()

func _draw() -> void:
    # Draw main waterfall...
    
    # Draw tooltip AFTER main graph (if visible)
    if _tooltip_visible and _tooltip_frame_index >= 0:
        _draw_tooltip(_tooltip_frame_index, _tooltip_position)

func _draw_tooltip(frame_idx: int, pos: Vector2) -> void:
    # Lightweight - only draws tooltip, not full graph
    var frame_data = _get_frame_data(frame_idx)
    var tooltip_text = _format_tooltip(frame_data)
    # Draw tooltip panel + text
```

**Alternative: Separate Tooltip Node**
Create dedicated `Tooltip` Control node that's a sibling of WaterfallControl. Only update position/text on hover, doesn't trigger waterfall redraw.

**Recommendation:** Use deferred tooltip rendering - only redraw tooltip on hover change, not full waterfall. Consider separate tooltip node if performance issues arise.

---

## 9. 🟢 MEDIUM: Rendering Performance - Bar Drawing

### Issue
Drawing 120 frames × 7 lanes = **840 rectangles** per frame. If each frame triggers full redraw (via `queue_redraw()`), this could be expensive.

**Current GraphControl:** Draws ~120 points as polyline (1 draw call).  
**WaterfallControl:** Would draw 840 rectangles (potentially 840 draw calls).

### Superior Approach

**Batch Drawing (Recommended):**
```gdscript
func _draw() -> void:
    # Background
    draw_rect(Rect2(Vector2.ZERO, size), bg_color)
    
    # Grid lines (reusable)
    _draw_grid()
    
    # Batch draw bars by lane (reduces draw calls)
    for lane_idx in range(7):
        var lane_rect = _get_lane_rect(lane_idx)
        var lane_points: PackedVector2Array = PackedVector2Array()
        
        # Build polygon for all frames in this lane
        for frame_idx in range(HISTORY_SIZE):
            var bar_rect = _get_bar_rect_for_frame(lane_idx, frame_idx)
            if bar_rect.size.x > 0:
                # Add bar corners to polygon
                lane_points.append(bar_rect.position)
                lane_points.append(bar_rect.position + Vector2(bar_rect.size.x, 0))
                lane_points.append(bar_rect.position + bar_rect.size)
                lane_points.append(bar_rect.position + Vector2(0, bar_rect.size.y))
        
        # Draw entire lane as single polygon (if points exist)
        if lane_points.size() > 0:
            draw_colored_polygon(lane_points, _get_lane_color(lane_idx))
    
    # Draw separators, labels, tooltip
```

**Alternative: Conditional Redraw**
Only redraw when data changes, not every frame:
```gdscript
var _last_rendered_index: int = -1

func add_frame_metrics(...) -> void:
    # ... update buffers ...
    if history_index != _last_rendered_index:
        queue_redraw()  # Only if new frame added
        _last_rendered_index = history_index
```

**Recommendation:** Use **batched polygon drawing** per lane (single draw call per lane instead of per-bar). Test performance - if still heavy, add conditional redraw (only when new frame added).

---

## 10. Additional Recommendations

### 10.1 Frame Time Lane
Add an **optional 8th lane** showing actual frame delta time (from `_delta`). This helps identify:
- CPU-bound frames (frame time > target, but CPU lanes don't explain it)
- GPU-bound frames (frame time > target, CPU lanes are low)

### 10.2 Color Intensity by Value
Make bar color intensity proportional to value:
```gdscript
# Green = good (< 16.67ms), Yellow = warning (16.67-25ms), Red = bad (>25ms)
var intensity = clamp(value_ms / 33.33, 0.0, 1.0)
var color = Color(1.0 - intensity, intensity, 0.0)  # Green -> Yellow -> Red
```

### 10.3 Export Frame Snapshot
Extend export functionality to include waterfall frame data:
```gdscript
func export_frame_snapshot(frame_index: int) -> Dictionary:
    return {
        "frame_id": history_frame_ids[frame_index],
        "process_ms": history_process[frame_index],
        "physics_ms": history_physics[frame_index],
        # ... all metrics
        "sub_breakdowns": history_sub[frame_index] if frame_index < history_sub.size() else {}
    }
```

### 10.4 UIConstants Additions
```gdscript
# Add to UIConstants.gd
const WATERFALL_LANE_HEIGHT: int = 60  # Height per lane (7 lanes × 60 = 420px, +60 for labels)
const WATERFALL_FRAME_WIDTH_MIN: int = 8  # Minimum pixels per frame (for hover accuracy)
const WATERFALL_TOOLTIP_DELAY_MS: int = 200  # Delay before showing tooltip (avoid flicker)
const WATERFALL_ZOOM_MIN: float = 0.5  # Minimum zoom (show more frames)
const WATERFALL_ZOOM_MAX: float = 10.0  # Maximum zoom (zoom into frame)
```

---

## Summary of Critical Changes Needed

1. **Frame Synchronization:** Implement frame tagging system for async metrics (refresh, thread).
2. **Data Structure:** Use parallel `PackedFloat32Array` instead of `Array[Dictionary]` for primaries.
3. **Idle Calculation:** Use `_delta * 1000.0` instead of fixed 33.33ms.
4. **Script Time:** Replace with "Other Process Time" (derived) or remove.
5. **Draw Calls + Primitives:** Use dual-scale visualization (bar + overlay line).
6. **Sub-Metrics:** Require frame_id in all async metric pushes.

**Recommended v3.1 Spec Updates:**
- Add frame_id parameter to all `push_*_breakdown()` methods.
- Change data structure to parallel PackedArrays.
- Clarify idle calculation uses frame delta.
- Replace "Script Time" with "Other Process Time".
- Specify dual-scale for Lane 7.
- Add conditional redraw optimization.
- Document pan/zoom as v4 feature.

---

**Overall Assessment:** Specification is **solid conceptually** but requires these technical refinements for production-quality implementation. The frame synchronization issue is the most critical - without it, waterfall view will show misleading data.


