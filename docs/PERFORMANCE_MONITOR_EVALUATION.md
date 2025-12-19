# Performance Monitor Overlay - Specification Evaluation & Improvements

**Date:** 2025-01-27  
**Status:** EVALUATION & RECOMMENDATIONS  
**Author:** Auto (Cursor AI)

---

## Executive Summary

The provided Performance Monitor overlay specification is **well-designed and aligns with project rules**, but several improvements and considerations are recommended to ensure robustness, maintainability, and optimal integration with the existing codebase.

**Overall Assessment:** ✅ **APPROVED with recommended enhancements**

---

## 1. Specification Strengths

### ✅ Compliance with Project Rules
- **GUI Spec v5:** Uses built-in containers, UIConstants, theme integration
- **Code Style:** Proper header format, typed GDScript, snake_case/PascalCase conventions
- **Responsiveness:** Anchor-based positioning, size flags, viewport resize handling
- **Performance:** Lightweight updates, fixed-size history buffers

### ✅ Design Philosophy
- **Immersion:** Semi-transparent fantasy-themed panel aligns with BG3 aesthetics
- **Extensibility:** Easy to add metrics via Performance singleton
- **Three-tier detail levels:** Off/Simple/Detailed provides flexibility

---

## 2. Critical Issues & Fixes Required

### 🔴 Issue 1: Graph Drawing Implementation Missing

**Problem:** The specification provides pseudocode for `_draw()` but doesn't specify how to implement it properly.

**Current Spec:**
```gdscript
# Example for fps_graph._draw():
# func _draw() -> void:
#     if fps_history.is_empty(): return
#     ...
```

**Solution:** Create a reusable `GraphControl.gd` script that extends `Control` and handles drawing logic.

**Recommended Implementation:**
```gdscript
# ╔═══════════════════════════════════════════════════════════
# ║ GraphControl.gd
# ║ Desc: Reusable control for drawing line graphs with history data
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name GraphControl
extends Control

## History data to plot (Array[float])
var history: Array[float] = []

## Maximum value for Y-axis scaling (0 = auto-scale)
var max_value: float = 0.0

## Line color
var line_color: Color = Color.GREEN

## Background color (semi-transparent)
var bg_color: Color = Color(0, 0, 0, 0.3)

## Grid line color
var grid_color: Color = Color(1, 1, 1, 0.1)

## Number of horizontal grid lines
const GRID_LINES: int = 5

func _draw() -> void:
	if history.is_empty():
		return
	
	# Draw background
	draw_rect(Rect2(Vector2.ZERO, size), bg_color)
	
	# Calculate scaling
	var max_val: float = max_value if max_value > 0.0 else _calculate_max()
	if max_val <= 0.0:
		return
	
	# Draw grid lines
	_draw_grid(max_val)
	
	# Draw line graph
	var points: PackedVector2Array = []
	for i in range(history.size()):
		var x: float = (float(i) / max(history.size() - 1, 1)) * size.x
		var y: float = size.y - (history[i] / max_val) * size.y
		points.append(Vector2(x, y))
	
	if points.size() > 1:
		draw_polyline(points, line_color, 2.0)
	
	# Draw current value indicator
	if points.size() > 0:
		var last_point: Vector2 = points[points.size() - 1]
		draw_circle(last_point, 3.0, line_color)

func _draw_grid(max_val: float) -> void:
	for i in range(GRID_LINES + 1):
		var y: float = (float(i) / GRID_LINES) * size.y
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)

func _calculate_max() -> float:
	if history.is_empty():
		return 0.0
	var max_val: float = history[0]
	for val in history:
		if val > max_val:
			max_val = val
	return max_val * 1.1  # Add 10% padding
```

**Usage in PerformanceMonitor.gd:**
```gdscript
# In _ready(), after creating graphs:
fps_graph.set_script(preload("res://scripts/ui/overlays/GraphControl.gd"))
fps_graph.max_value = 60.0  # Target FPS
fps_graph.line_color = Color(0.2, 1.0, 0.2)  # Green
fps_graph.history = fps_history

process_graph.set_script(preload("res://scripts/ui/overlays/GraphControl.gd"))
process_graph.max_value = 16.67  # 60 FPS = 16.67ms
process_graph.line_color = Color(1.0, 0.8, 0.2)  # Yellow/amber
process_graph.history = process_history
```

**Alternative (Better):** Use `class_name GraphControl` and instantiate directly:
```gdscript
fps_graph = GraphControl.new()
fps_graph.name = "FPSGraph"
graphs_container.add_child(fps_graph)
```

---

### 🔴 Issue 2: Script Syntax Error in `_ready()`

**Problem:** Line 47 in spec has invalid syntax:
```gdscript
label.theme_override_font_sizes/font_size = UIConstants.LABEL_FONT_SIZE_OVERRIDE
```

**Fix:**
```gdscript
label.theme_override_font_sizes["font_size"] = UIConstants.LABEL_FONT_SIZE_OVERRIDE
```

---

### 🔴 Issue 3: History Update Timing

**Problem:** `update_histories()` is called in `_process()`, but graphs are redrawn immediately. This can cause one-frame delay.

**Fix:** Update histories BEFORE redraw:
```gdscript
func _process(_delta: float) -> void:
	update_metrics()
	if current_mode == Mode.DETAILED:
		update_histories()  # Update first
		fps_graph.queue_redraw()  # Then redraw
		process_graph.queue_redraw()
```

**Better:** Connect history updates to graph controls directly:
```gdscript
# In GraphControl.gd, add:
func update_history(new_value: float) -> void:
	history.push_back(new_value)
	if history.size() > HISTORY_SIZE:
		history.pop_front()
	queue_redraw()  # Auto-redraw on update
```

---

### 🔴 Issue 4: Input Action Not Defined

**Problem:** Spec references `toggle_perf_monitor` action but doesn't specify it exists.

**Fix:** Add to `project.godot`:
```ini
[input]

toggle_perf_monitor={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194306,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
```

**Note:** `physical_keycode":4194306` is KEY_F3. Verify this matches your key mapping.

---

## 3. Recommended Enhancements

### 🟡 Enhancement 1: UIConstants Extensions

**Current Spec Constants:**
```gdscript
const OVERLAY_PADDING: int = 10
const GRAPH_WIDTH: float = 0.2
const GRAPH_HEIGHT: int = 100
const LABEL_FONT_SIZE_OVERRIDE: int = 14
```

**Issues:**
- `GRAPH_WIDTH` is a float (0.2 = 20%) but should be documented as relative
- `OVERLAY_PADDING` conflicts with existing `SPACING_SMALL` (also 10)

**Recommended:**
```gdscript
# Add to UIConstants.gd:
# Performance Monitor Constants
const PERF_OVERLAY_PADDING: int = 10  # Explicit naming
const PERF_GRAPH_WIDTH_RATIO: float = 0.2  # 20% of viewport width
const PERF_GRAPH_HEIGHT: int = 100  # Fixed height (scalable via theme)
const PERF_LABEL_FONT_SIZE: int = 14  # Smaller font for perf text
const PERF_HISTORY_SIZE: int = 60  # 60 frames (~1 second at 60 FPS)
```

**Rationale:** Prefix prevents conflicts, explicit naming clarifies purpose.

---

### 🟡 Enhancement 2: Memory Formatting

**Current Spec:**
```gdscript
var static_memory: float = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
memory_label.text = "Static Memory: %.2f MB" % static_memory
```

**Enhancement:** Add dynamic unit formatting (KB/MB/GB):
```gdscript
func format_memory(bytes: float) -> String:
	if bytes < 1024.0:
		return "%.1f B" % bytes
	elif bytes < 1048576.0:
		return "%.2f KB" % (bytes / 1024.0)
	elif bytes < 1073741824.0:
		return "%.2f MB" % (bytes / 1048576.0)
	else:
		return "%.2f GB" % (bytes / 1073741824.0)
```

---

### 🟡 Enhancement 3: Color-Coded FPS Display

**Enhancement:** Color-code FPS label based on performance:
```gdscript
func update_metrics() -> void:
	var fps: float = Engine.get_frames_per_second()
	fps_label.text = "FPS: %.1f" % fps
	
	# Color-code based on performance
	if fps >= 55.0:
		fps_label.modulate = Color.GREEN
	elif fps >= 30.0:
		fps_label.modulate = Color.YELLOW
	else:
		fps_label.modulate = Color.RED
```

**Note:** Use theme colors instead of hard-coded:
```gdscript
var good_color: Color = theme.get_color("positive", "Label")
var warning_color: Color = theme.get_color("font_color", "Label")
var bad_color: Color = theme.get_color("negative", "Label")
```

---

### 🟡 Enhancement 4: Additional Metrics (Future-Proof)

**Recommended additions for detailed mode:**
- **Draw Calls:** `Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)`
- **Video Memory:** `Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)`
- **Texture Memory:** `Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)`
- **Physics Objects:** `Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)`

**Implementation:** Make metrics configurable via export variables:
```gdscript
@export var show_draw_calls: bool = true
@export var show_video_memory: bool = true
@export var show_physics_objects: bool = false  # Off by default
```

---

### 🟡 Enhancement 5: Smooth Graph Interpolation

**Enhancement:** Add smooth line interpolation for better visualization:
```gdscript
# In GraphControl._draw(), replace draw_polyline with:
if points.size() > 1:
	# Draw smooth curve using quadratic bezier
	for i in range(points.size() - 1):
		var p0: Vector2 = points[i]
		var p1: Vector2 = points[i + 1]
		var mid: Vector2 = (p0 + p1) / 2.0
		draw_line(p0, mid, line_color, 2.0)
		draw_line(mid, p1, line_color, 2.0)
```

**Alternative:** Use `draw_polyline()` with antialiasing (if available in Godot 4.5.1).

---

### 🟡 Enhancement 6: Persistence & Settings

**Enhancement:** Save monitor state to user settings:
```gdscript
# In set_mode():
func set_mode(new_mode: Mode) -> void:
	current_mode = new_mode
	# Save to user settings
	var config: ConfigFile = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("performance_monitor", "mode", current_mode)
	config.save("user://settings.cfg")
	# ... rest of function
```

**Load in `_ready()`:**
```gdscript
var config: ConfigFile = ConfigFile.new()
if config.load("user://settings.cfg") == OK:
	var saved_mode = config.get_value("performance_monitor", "mode", Mode.OFF)
	set_mode(saved_mode)
else:
	set_mode(Mode.OFF)
```

---

## 4. Integration Considerations

### 🟡 Integration Point: world_root.tscn

**Current State:** `world_root.tscn` already has `DebugOverlay.tscn` instance (line 38).

**Recommendation:** Add PerformanceMonitor as sibling:
```gdscript
# In world_root.tscn:
[node name="PerformanceMonitor" parent="." instance=ExtResource("9_perf_monitor")]
```

**Or via code in `world_root.gd`:**
```gdscript
func _ready() -> void:
	# ... existing code ...
	_setup_performance_monitor()

func _setup_performance_monitor() -> void:
	var perf_monitor_scene: PackedScene = preload("res://scenes/ui/overlays/PerformanceMonitor.tscn")
	var perf_monitor: Node = perf_monitor_scene.instantiate()
	add_child(perf_monitor)
	MythosLogger.debug("World", "PerformanceMonitor added")
```

---

### 🟡 Layer Management

**Current Spec:** `CanvasLayer.layer = 128`

**Consideration:** `DebugOverlay.tscn` uses `layer = 10`. PerformanceMonitor should be:
- **Above game content:** `layer >= 1`
- **Below debug menu (if exists):** `layer < 128` (or coordinate with DebugOverlay)

**Recommendation:** Use `layer = 20` (above game, below potential debug menu at 128).

---

### 🟡 Theme Integration

**Current Spec:** Uses `bg3_theme.tres` with stylebox override.

**Enhancement:** Create dedicated stylebox in theme for overlay:
```gdscript
# In bg3_theme.tres, add:
Panel/styles/perf_overlay = SubResource("StyleBoxFlat_perf")
```

**StyleBoxFlat_perf properties:**
- `bg_color = Color(0.1, 0.1, 0.1, 0.8)` (semi-transparent dark)
- `border_color = Color(1, 0.843, 0, 0.6)` (golden, subtle)
- `border_width_* = 2`
- `corner_radius_* = 4`

**Usage:**
```gdscript
perf_panel.add_theme_stylebox_override("panel", theme.get_stylebox("perf_overlay", "Panel"))
```

---

## 5. Performance Optimizations

### 🟡 Optimization 1: Conditional Updates

**Enhancement:** Only update when visible:
```gdscript
func _process(_delta: float) -> void:
	if not perf_panel.visible:
		return  # Skip if hidden
	update_metrics()
	# ... rest
```

**Note:** Already handled by `set_process(false)` in OFF mode, but good defensive coding.

---

### 🟡 Optimization 2: Frame-Rate Limited Updates

**Enhancement:** Update graphs at lower frequency (e.g., every 2-3 frames):
```gdscript
var frame_counter: int = 0

func _process(_delta: float) -> void:
	frame_counter += 1
	if frame_counter % 2 == 0:  # Update every 2 frames
		update_metrics()
		if current_mode == Mode.DETAILED:
			update_histories()
			fps_graph.queue_redraw()
			process_graph.queue_redraw()
```

**Trade-off:** Slightly less smooth graphs, but lower CPU usage.

---

### 🟡 Optimization 3: History Circular Buffer

**Enhancement:** Use `PackedFloat32Array` for better memory efficiency:
```gdscript
var fps_history: PackedFloat32Array = []
var process_history: PackedFloat32Array = []

func update_histories() -> void:
	fps_history.append(Engine.get_frames_per_second())
	process_history.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000)
	
	if fps_history.size() > HISTORY_SIZE:
		fps_history.remove_at(0)
		process_history.remove_at(0)
```

**Note:** `PackedFloat32Array` is more memory-efficient than `Array[float]`.

---

## 6. Testing Recommendations

### ✅ Test Checklist

1. **Responsiveness:**
   - [ ] Test at 1080p, 1440p, 4K, ultrawide (21:9)
   - [ ] Resize window dynamically
   - [ ] Verify no clipping at edges

2. **Performance:**
   - [ ] Measure FPS impact (should be < 1% overhead)
   - [ ] Test with full world + UI active
   - [ ] Verify 60 FPS stable with monitor visible

3. **Functionality:**
   - [ ] Toggle modes (Off → Simple → Detailed → Off)
   - [ ] Verify graphs update smoothly
   - [ ] Check metric accuracy (compare with Godot's built-in profiler)

4. **Integration:**
   - [ ] Verify no conflicts with DebugOverlay
   - [ ] Test in MainMenu and WorldRoot scenes
   - [ ] Verify theme styling matches project aesthetic

---

## 7. File Structure Recommendations

### ✅ Recommended Structure

```
res://
├── scenes/
│   └── ui/
│       └── overlays/  # NEW (allowed per rules)
│           └── PerformanceMonitor.tscn
├── scripts/
│   └── ui/
│       └── overlays/  # NEW
│           ├── PerformanceMonitor.gd
│           └── GraphControl.gd  # NEW (reusable graph component)
└── scripts/
    └── ui/
        └── UIConstants.gd  # UPDATE (add perf constants)
```

**Rationale:** Matches existing `scenes/ui/` and `scripts/ui/` structure, `overlays/` subfolder is logical extension.

---

## 8. Final Recommendations Summary

### ✅ Must-Fix (Before Implementation)
1. ✅ Create `GraphControl.gd` with proper `_draw()` implementation
2. ✅ Fix script syntax error (`theme_override_font_sizes`)
3. ✅ Add `toggle_perf_monitor` input action to `project.godot`
4. ✅ Update UIConstants with prefixed constants

### 🟡 Should-Add (Recommended)
1. 🟡 Memory formatting function (KB/MB/GB)
2. 🟡 Color-coded FPS display
3. 🟡 Theme stylebox for overlay panel
4. 🟡 Settings persistence
5. 🟡 Additional metrics (draw calls, video memory)

### 🟢 Nice-to-Have (Future)
1. 🟢 Smooth graph interpolation
2. 🟢 Frame-rate limited updates
3. 🟢 Circular buffer optimization
4. 🟢 Export variables for metric customization

---

## 9. Conclusion

The specification is **solid and ready for implementation** with the critical fixes applied. The recommended enhancements will improve robustness, maintainability, and user experience without compromising performance or project rule compliance.

**Next Steps:**
1. Apply critical fixes (Issues 1-4)
2. Implement base functionality
3. Test thoroughly
4. Add recommended enhancements incrementally
5. Document final implementation

---

**Status:** ✅ **APPROVED FOR IMPLEMENTATION** (with fixes and enhancements)
