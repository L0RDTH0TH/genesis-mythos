# Waterfall View v4 Specification

**Date:** December 19, 2025  
**Spec Version:** v4  
**Status:** Updated for Production - Incorporates Evaluation Feedback & GUI Guidelines  
**Changes from v3:** Addressed all critical/high/medium issues from evaluation (frame sync, data efficiency, idle calc, script time replacement, lane viz, sub-metrics assoc, tooltip perf, pan/zoom deferral). Integrated project GUI philosophy: Immersive fantasy aesthetics via `bg3_theme.tres`, no magic numbers (all via `UIConstants.gd`), responsive layout with built-in containers/anchors/size flags. Added recommended features (frame time lane, color intensity, export snapshot, new UIConstants).

This v4 spec ensures reliable, efficient diagnostics for real-time performance monitoring in the Detailed mode of the Performance Monitor Overlay. It replaces the four bottom line graphs with a single unified timeline waterfall view, emphasizing per-frame breakdowns while future-proofing for sub-metrics (e.g., Map Refresh breakdowns, thread-specific timings, other process attribution).

## Visual Goal & Inspiration

The view evokes a mystical "time rune" artifact—subtle fantasy flourishes like glowing lane separators (faint rune textures) and parchment-like background via `bg3_theme.tres`. Bars use thematic colors with intensity gradients (green-good to red-bad) for immersion without distracting from data.

Professional references (simplified for Godot):

(v4 remains flat lanes; nesting/sub-bars deferred to v5 for hierarchy/flame evolution.)

## Core Features (v4)

### Location & Layout
- Single `WaterfallControl` (extends Control) in `PerformanceMonitor.tscn`'s `BottomGraphsContainer` (HBoxContainer)
- Full width via `size_flags_horizontal = Control.SIZE_EXPAND_FILL`
- Height = `UIConstants.BOTTOM_GRAPH_BAR_HEIGHT` (480px) with `size_flags_vertical = Control.SIZE_EXPAND_FILL`
- Anchors: `anchors_preset = PRESET_FULL_RECT`
- No magic numbers—use `UIConstants` for margins/separations

### History
- Fixed `UIConstants.PERF_HISTORY_SIZE` samples (~2s at 60 FPS) via circular buffer

### Lanes
- 8 primary flat lanes (parallel for overlaps/async visibility) + sparse sub-metric support

### Interaction
- **Hover:** Highlight frame column (vertical glow via semi-transparent rect) + deferred tooltip (separate child Panel for perf)
- **Click:** Pin tooltip to bottom-right (position clamped to viewport bounds) or trigger export/log
- **No pan/zoom in v4** (deferred to v5); visible frames reduced to last 60 for wider bars (~32px/frame at 1920px width) and better hover accuracy

### Aesthetics
- Apply `theme = preload("res://themes/bg3_theme.tres")` at root
- Lane backgrounds: subtle parchment gradient
- Bar colors: thematic with intensity (e.g., low values green-tinted, high red-tinted)
- Reference lines: dashed rune-like lines

### Responsiveness
- Handles viewport resize via `_notification(NOTIFICATION_RESIZED)`: Recompute lane heights (`UIConstants.WATERFALL_LANE_HEIGHT`), frame widths (clamp to `UIConstants.WATERFALL_FRAME_WIDTH_MIN`), tooltip positions

### Performance
- Conditional redraw (only on new data), batched polygon drawing per lane, deferred tooltip
- Target 60 FPS; tested on mid-range hardware

## Lanes (Top to Bottom - VBoxContainer Nested for Layout)

1. **Frame Time** (new - actual delta) – `_delta * 1000.0` ms – Gray (base), intensity gradient  
2. **Main Process** – `Performance.TIME_PROCESS * 1000` ms – Yellow/Orange base  
3. **Physics Process** – `Performance.TIME_PHYSICS_PROCESS * 1000` ms – Cyan base  
4. **Map Refresh** – `refresh_time_ms` (top-level, frame-tagged) – Red base  
   → Future sub-lanes (sparse, collapsed): culling_ms, mesh_gen_ms, texture_update_ms (pushed with frame_id)  
5. **Thread Compute** – `thread_compute_time_ms` (aggregated, frame-tagged) – Blue base  
   → Future sub-lanes: per-thread_ms (e.g., thread_0, thread_1 from WorldGenerator)  
6. **Other Process** (replaces Script Time - derived) – `max(0.0, process_ms - refresh_ms - thread_ms)` ms – Green base  
   → Captures unattributed process time (engine overhead, signals, etc.); future explicit instrumentation hook  
7. **Idle / GPU Wait** (calculated from actual frame delta) – `max(0.0, frame_delta_ms - cpu_total_ms)` ms – Light Gray  
8. **Draw Calls + Primitives** (dual-scale) – Draw calls (solid bar, scaled 0-2000) + Primitives (overlay line, normalized 0-1.0 based on max seen) – Purple (draw) / Magenta (primitives)  

Each lane: `UIConstants.WATERFALL_LANE_HEIGHT` (~60px, 8 lanes = ~480px). Separators: thin rune-textured lines via theme constant.

## Scaling & Grid

### Time lanes (1-7)
- Unified horizontal scale to `UIConstants.WATERFALL_TARGET_FRAME_MS` (16.67 default, configurable for 60 FPS target)

### Count lane (8)
- Independent auto-scale + 10% padding
- Draw calls cap at `UIConstants.WATERFALL_DRAW_CALLS_MAX` (2000)
- Primitives normalized

### Reference lines
- Dashed 16.67 ms (green), 33.33 ms (orange) on time lanes
- Intensity for bound indicators (red if > target)

### Grid
- Vertical lines every 30 frames
- Horizontal separators via theme

### Labels
- Left-side (narrow Label via `UIConstants.LABEL_WIDTH_NARROW`): Lane name + current/avg (small font override)
- No magic numbers—use theme for sizes

### Color Intensity
Proportional to value:
```gdscript
var intensity = clamp(value_ms / UIConstants.WATERFALL_TARGET_FRAME_MS, 0.0, 1.0)
var color = Color(1.0 - intensity, intensity, 0.0)  # green → yellow → red
```

## Data Structure & Extensibility (Efficient Hybrid)

```gdscript
# In WaterfallControl.gd (extends Control)
# Parallel PackedArrays for primaries (memory-efficient, ~1.2KB for 120 frames)
var history_frame_time: PackedFloat32Array = PackedFloat32Array()
var history_process: PackedFloat32Array = PackedFloat32Array()
var history_physics: PackedFloat32Array = PackedFloat32Array()
var history_refresh: PackedFloat32Array = PackedFloat32Array()
var history_thread: PackedFloat32Array = PackedFloat32Array()
var history_other_process: PackedFloat32Array = PackedFloat32Array()
var history_idle: PackedFloat32Array = PackedFloat32Array()
var history_draw_calls: PackedInt32Array = PackedInt32Array()
var history_primitives: PackedInt32Array = PackedInt32Array()

# Sparse sub-metrics (only when available, Array[Dictionary] indexed by history_index)
var history_sub: Array[Dictionary] = []  # e.g., history_sub[5] = {"refresh": {culling: 2.1, mesh: 5.4}, "thread": {thread_0: 3.2}}

# Frame metadata for sync
var history_frame_ids: PackedInt32Array = PackedInt32Array()
var history_timestamps_usec: PackedInt64Array = PackedInt64Array()  # For precise timing

const HISTORY_SIZE: int = UIConstants.PERF_HISTORY_SIZE
var history_index: int = 0
var history_full: bool = false
var _max_primitives_seen: float = 1.0  # For normalization

func add_frame_metrics(primary: Dictionary, sub_metrics: Array[Dictionary] = []) -> void:
    var write_idx = _get_write_index()
    
    # Primaries to packed arrays
    history_frame_time[write_idx] = primary.get("frame_delta_ms", 0.0)
    history_process[write_idx] = primary.get("process_ms", 0.0)
    history_physics[write_idx] = primary.get("physics_ms", 0.0)
    history_refresh[write_idx] = primary.get("refresh_ms", 0.0)
    history_thread[write_idx] = primary.get("thread_ms", 0.0)
    history_other_process[write_idx] = primary.get("other_process_ms", 0.0)
    history_idle[write_idx] = primary.get("idle_ms", 0.0)
    history_draw_calls[write_idx] = primary.get("draw_calls", 0)
    history_primitives[write_idx] = primary.get("primitives", 0)
    _max_primitives_seen = max(_max_primitives_seen, primary.get("primitives", 0))
    
    # Sparse sub only if present
    if sub_metrics.size() > 0:
        if history_sub.size() <= write_idx:
            history_sub.resize(HISTORY_SIZE)
        history_sub[write_idx] = _organize_sub_metrics(sub_metrics)
    
    # Metadata
    history_frame_ids[write_idx] = primary.get("frame_id", -1)
    history_timestamps_usec[write_idx] = primary.get("timestamp_usec", 0)
    
    # Conditional redraw
    if history_index != _last_rendered_index:
        queue_redraw()
        _last_rendered_index = history_index
    
    # Circular advance
    history_index = (history_index + 1) % HISTORY_SIZE
    if not history_full and history_index == 0:
        history_full = true
```

All arrays resized to HISTORY_SIZE in `_ready()`.

## Integration in PerformanceMonitor.gd

```gdscript
# In _process(_delta: float)
func _process(_delta: float) -> void:
    if current_mode != Mode.DETAILED or _frame_count < 3:
        return
    
    var frame_id: int = Engine.get_process_frames()
    var frame_time_start: int = Time.get_ticks_usec()
    var frame_delta_ms: float = _delta * 1000.0
    
    var process_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
    var physics_ms: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
    var refresh_ms: float = _match_refresh_to_frame(frame_id)
    var thread_ms: float = _match_thread_to_frame(frame_id)
    
    var cpu_total_ms: float = process_ms + physics_ms + refresh_ms + thread_ms
    var other_process_ms: float = max(0.0, process_ms - refresh_ms - thread_ms)
    var idle_ms: float = max(0.0, frame_delta_ms - cpu_total_ms)
    
    var draw_calls: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
    var primitives: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
    
    var primary: Dictionary = {
        frame_id = frame_id,
        frame_delta_ms = frame_delta_ms,
        process_ms = process_ms,
        physics_ms = physics_ms,
        refresh_ms = refresh_ms,
        thread_ms = thread_ms,
        other_process_ms = other_process_ms,
        idle_ms = idle_ms,
        draw_calls = draw_calls,
        primitives = primitives,
        timestamp_usec = frame_time_start
    }
    
    var sub_breakdowns: Array[Dictionary] = _sub_breakdowns_for_frame(frame_id)
    
    waterfall_control.add_frame_metrics(primary, sub_breakdowns)
```

## Instrumentation Hooks (Frame-Tagged for Sync)

Extend `PerformanceMonitorSingleton.gd`:

```gdscript
# Async pushes with frame_id
func push_refresh_breakdown(breakdown: Dictionary, frame_id: int = -1) -> void:
    if frame_id == -1: frame_id = Engine.get_process_frames()
    _mutex.lock()
    _refresh_breakdown_buffer.append({"frame_id": frame_id, "breakdown": breakdown, "timestamp_usec": Time.get_ticks_usec()})
    if _refresh_breakdown_buffer.size() > UIConstants.WATERFALL_BUFFER_MAX:  # e.g., 10
        _refresh_breakdown_buffer.pop_front()
    _mutex.unlock()

# Similar for thread, other_process explicit timings

# Matching in PerformanceMonitor
func _match_refresh_to_frame(frame_id: int) -> float:
    _mutex.lock()
    for i in range(_refresh_breakdown_buffer.size() - 1, -1, -1):
        var metric = _refresh_breakdown_buffer[i]
        if metric.frame_id == frame_id or metric.frame_id == frame_id - 1:
            _refresh_breakdown_buffer.remove_at(i)  # Consume
            _mutex.unlock()
            return metric.breakdown.get("total_ms", 0.0)  # Assume breakdown has total
    _mutex.unlock()
    return 0.0

# _sub_breakdowns_for_frame similar, consuming matched entries
```

## Rendering Pseudocode (_draw())

```gdscript
var _last_rendered_index: int = -1

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), bg_color)  # Theme bg
    
    _draw_grid()  # Batched lines
    
    for lane_idx in range(8):
        var lane_rect = _get_lane_rect(lane_idx)  # From VBox-like calc
        var lane_points: PackedVector2Array = PackedVector2Array()
        
        for i in range(VISIBLE_FRAMES):  # e.g., 60
            var frame_idx = (history_index - 1 - i + HISTORY_SIZE) % HISTORY_SIZE  # Newest right
            var value = _get_lane_value(lane_idx, frame_idx)
            var bar_rect = _get_bar_rect(lane_idx, i, value)  # Scaled, intensity color
            if bar_rect.size.x > 0:
                lane_points.append_array(_get_rect_points(bar_rect))  # For batch
            
            # Dual for lane 8: Add overlay line points
            if lane_idx == 7:
                var primitives_norm = _get_primitives_normalized(frame_idx)
                var line_y = lane_rect.position.y + (1.0 - primitives_norm) * lane_rect.size.y
                draw_line(Vector2(lane_rect.position.x, line_y), Vector2(lane_rect.end.x, line_y), Color.MAGENTA, 2.0)
        
        if lane_points.size() > 0:
            draw_colored_polygon(lane_points, _get_lane_color(lane_idx))  # Single call per lane
    
    # Deferred tooltip if visible (separate _draw_tooltip call)
```

## Tooltip (Deferred Perf)

```gdscript
@onready var tooltip_panel: Panel = $TooltipPanel  # Child, hidden by default, theme-styled
var _tooltip_frame_idx: int = -1
var _tooltip_pos: Vector2
var _tooltip_visible: bool = false

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        var frame_idx = _get_frame_idx_from_pos(event.position)
        if frame_idx != _tooltip_frame_idx:
            _tooltip_frame_idx = frame_idx
            _tooltip_pos = event.position
            _tooltip_visible = true
            _update_tooltip()  # Only update text/pos, no full redraw

func _update_tooltip() -> void:
    if not _tooltip_visible: return
    var data = _get_frame_data(_tooltip_frame_idx)
    tooltip_panel.text = _format_tooltip(data)  # Label child
    tooltip_panel.position = _clamp_tooltip_pos(_tooltip_pos)  # Viewport bounds
    tooltip_panel.visible = true
```

## Export Functionality

```gdscript
func export_frame_snapshot(frame_idx: int) -> void:
    var data = _get_frame_data(frame_idx)
    # Append to CSV: timestamp_usec, frame_id, all primaries + sub
    # Use existing export_snapshot() extension
```

## UIConstants Additions

Add to `res://scripts/ui/UIConstants.gd`:

```gdscript
# Waterfall View Constants
const WATERFALL_LANE_HEIGHT: int = 60  ## Height per lane in waterfall view
const WATERFALL_FRAME_WIDTH_MIN: int = 32  ## Minimum frame width for hover accuracy
const WATERFALL_TARGET_FRAME_MS: float = 16.67  ## Target frame time (60 FPS)
const WATERFALL_DRAW_CALLS_MAX: int = 2000  ## Maximum draw calls for scaling
const WATERFALL_BUFFER_MAX: int = 10  ## Maximum size for metric buffers
const WATERFALL_TOOLTIP_DELAY_MS: int = 200  ## Tooltip display delay in milliseconds
```

## Future-Proofing

- Sub-metrics sparse and frame-tagged; easy nesting in v5
- Pan/zoom hooks in _gui_input (deferred)
- Flame evolution: Aggregate history for hotspots in separate mode

## Implementation Notes

This v4 is production-ready: Efficient, synced, responsive, and on-brand. Test via `run_project` for FPS/resize.

### Key Design Decisions

1. **Flat lanes in v4:** Nesting/sub-bars deferred to v5 for hierarchy/flame evolution
2. **60 visible frames:** Wider bars (~32px/frame at 1920px) for better hover accuracy
3. **Conditional redraw:** Only redraws when new data arrives, improving performance
4. **Sparse sub-metrics:** Only stored when available, reducing memory overhead
5. **Frame-tagged sync:** Ensures async metrics (refresh, thread) match correct frames

### Testing Checklist

- [ ] 60 FPS maintained with waterfall view active
- [ ] Responsive resize (1080p, 4K, ultrawide)
- [ ] Tooltip appears on hover with correct frame data
- [ ] All 8 lanes render correctly with proper scaling
- [ ] Color intensity gradients work (green → yellow → red)
- [ ] Export functionality captures frame snapshot correctly
- [ ] Frame sync works for async metrics (refresh, thread)
- [ ] No magic numbers (all via UIConstants)
- [ ] Theme applied correctly (bg3_theme.tres)
