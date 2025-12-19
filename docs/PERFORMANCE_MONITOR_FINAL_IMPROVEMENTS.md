# Performance Monitor Overlay – Final Remaining Improvements

**Date:** 2025-01-28  
**Status:** POLISHED SPEC REVIEW  
**Version:** v2 Final Review

---

## Executive Summary

The polished specification is **excellent and production-ready**. However, there are **7 minor improvements** that would enhance robustness, performance, and integration consistency. All are optional but recommended.

**Overall Assessment:** ✅ **READY FOR IMPLEMENTATION** (with optional polish)

---

## 1. 🔴 Critical: Node Path Mismatch

### Issue
The script references `$PerfPanel/MarginContainer/Content` but the scene structure spec shows:
```
PanelContainer (PerfPanel)
  └── MarginContainer
      └── VBoxContainer (Content)
```

However, `PanelContainer` in Godot **automatically wraps its child in a MarginContainer** internally. The actual accessible path should be:
```
$PerfPanel/Content
```

### Fix
**Option A (Recommended):** Remove explicit MarginContainer from scene structure:
```gdscript
# In PerformanceMonitor.gd, change:
@onready var fps_label: Label = $PerfPanel/Content/FPSLabel
@onready var metrics_container: VBoxContainer = $PerfPanel/Content/MetricsContainer
@onready var graphs_container: HBoxContainer = $PerfPanel/Content/GraphsContainer
@onready var fps_graph: GraphControl = $PerfPanel/Content/GraphsContainer/FPSGraph
@onready var process_graph: GraphControl = $PerfPanel/Content/GraphsContainer/ProcessGraph
```

**Option B:** Keep MarginContainer but adjust paths:
```gdscript
@onready var fps_label: Label = $PerfPanel/MarginContainer/Content/FPSLabel
# ... etc
```

**Recommendation:** Use Option A (PanelContainer handles margins internally via theme/stylebox).

---

## 2. 🟡 Performance: GraphControl History Optimization

### Issue
`GraphControl.add_value()` uses `remove_at(0)` which is **O(n)** for each removal. With 120 history entries, this can cause micro-stutters.

### Current Code
```gdscript
func add_value(value: float) -> void:
	history.append(value)
	if history.size() > UIConstants.PERF_HISTORY_SIZE:
		history.remove_at(0)  # O(n) operation
	queue_redraw()
```

### Optimization: Circular Buffer Approach
```gdscript
# In GraphControl.gd, replace history management:
var history: PackedFloat32Array = PackedFloat32Array()
var history_index: int = 0
var history_full: bool = false

func add_value(value: float) -> void:
	if history.size() < UIConstants.PERF_HISTORY_SIZE:
		history.append(value)
	else:
		# Circular buffer: overwrite oldest entry
		if not history_full:
			history_full = true
		history[history_index] = value
		history_index = (history_index + 1) % UIConstants.PERF_HISTORY_SIZE
	queue_redraw()

func _draw() -> void:
	if history.is_empty():
		return
	
	# ... background and grid code ...
	
	# Build points from circular buffer
	var points: PackedVector2Array = PackedVector2Array()
	var count: int = history.size() if not history_full else UIConstants.PERF_HISTORY_SIZE
	
	for i in range(count):
		var idx: int = (history_index + i) % count if history_full else i
		var x: float = (float(i) / max(count - 1, 1)) * size.x
		var y: float = size.y * (1.0 - (history[idx] / max_val))
		points.append(Vector2(x, y))
	
	# ... rest of draw code ...
```

**Trade-off:** Slightly more complex code, but **O(1) insertions** instead of O(n).

**Recommendation:** Implement if you notice frame drops when monitor is visible. For 120 entries, the current approach is probably fine, but this is more scalable.

---

## 3. 🟡 Error Handling: Settings Persistence

### Issue
Settings save/load has no error handling. If file is locked or disk is full, it fails silently.

### Current Code
```gdscript
func _save_mode() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("debug", "perf_monitor_mode", current_mode)
	cfg.save("user://settings.cfg")  # No error checking
```

### Enhanced Version
```gdscript
func _save_mode() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("debug", "perf_monitor_mode", current_mode)
	var err: Error = cfg.save("user://settings.cfg")
	if err != OK:
		MythosLogger.warn("PerformanceMonitor", "Failed to save monitor mode: %d" % err)

func _load_saved_mode() -> void:
	var cfg := ConfigFile.new()
	var err: Error = cfg.load("user://settings.cfg")
	if err == OK:
		var saved: int = cfg.get_value("debug", "perf_monitor_mode", Mode.OFF)
		if saved >= 0 and saved < Mode.size():
			set_mode(saved)
		else:
			MythosLogger.warn("PerformanceMonitor", "Invalid saved mode: %d, using OFF" % saved)
			set_mode(Mode.OFF)
	else:
		set_mode(Mode.OFF)  # Default on first run or error
```

**Recommendation:** Add this for production robustness.

---

## 4. 🟡 Code Cleanup: Redundant Input Processing

### Issue
`set_process_input(true)` in `_ready()` is redundant. `_input()` is called automatically for all nodes in the scene tree.

### Current Code
```gdscript
func _ready() -> void:
	# ... setup code ...
	# Input
	set_process_input(true)  # ← Not needed
```

### Fix
Remove the line:
```gdscript
func _ready() -> void:
	# ... setup code ...
	# Input handling via _input() is automatic
```

**Recommendation:** Remove for cleaner code.

---

## 5. 🟡 Integration: Use MythosLogger

### Issue
The spec doesn't use `MythosLogger` (project's logging system) for debug messages.

### Current Code
No logging in the spec.

### Enhancement
Add logging for mode changes and errors:
```gdscript
func set_mode(new_mode: Mode) -> void:
	current_mode = new_mode
	
	var mode_names: Array[String] = ["OFF", "SIMPLE", "DETAILED"]
	MythosLogger.debug("PerformanceMonitor", "Mode changed to: %s" % mode_names[current_mode])
	
	match current_mode:
		# ... rest of function ...
```

**Recommendation:** Add for consistency with project logging standards.

---

## 6. 🟡 Scene Integration: Match Existing Pattern

### Issue
The integration example in Section 8 uses `preload()` and `instantiate()`, but `world_root.tscn` instances `DebugOverlay` directly in the scene file.

### Current Spec (Section 8)
```gdscript
func _ready() -> void:
	var perf_scene: PackedScene = preload("res://scenes/ui/overlays/PerformanceMonitor.tscn")
	var perf_inst: Node = perf_scene.instantiate()
	add_child(perf_inst)
```

### Alternative (Match DebugOverlay Pattern)
**In `world_root.tscn`:**
```gdscript
[ext_resource type="PackedScene" uid="uid://perf_monitor" path="res://scenes/ui/overlays/PerformanceMonitor.tscn" id="9_perf_monitor"]

[node name="PerformanceMonitor" parent="." instance=ExtResource("9_perf_monitor")]
```

**Recommendation:** Use scene file instantiation for consistency, unless you need runtime control.

---

## 7. 🟢 Nice-to-Have: Graph Min/Max Display

### Enhancement
Add min/max value labels to graphs for better readability:

```gdscript
# In GraphControl.gd, add:
@onready var min_label: Label
@onready var max_label: Label

func _ready() -> void:
	min_label = Label.new()
	min_label.name = "MinLabel"
	min_label.add_theme_font_size_override("font_size", 10)
	min_label.position = Vector2(2, size.y - 12)
	add_child(min_label)
	
	max_label = Label.new()
	max_label.name = "MaxLabel"
	max_label.add_theme_font_size_override("font_size", 10)
	max_label.position = Vector2(2, 2)
	add_child(max_label)

func _draw() -> void:
	# ... existing draw code ...
	
	# Update labels
	if not history.is_empty():
		var max_val: float = max_value if max_value > 0.0 else _get_auto_max()
		var min_val: float = _get_auto_min()
		max_label.text = "%.1f" % max_val
		min_label.text = "%.1f" % min_val
```

**Recommendation:** Optional polish for better UX.

---

## 8. 🟢 Nice-to-Have: Theme Stylebox Creation Guide

### Issue
Section 7 mentions adding a stylebox to the theme but doesn't provide step-by-step instructions.

### Enhancement: Detailed Theme Update Steps

**Option A: Via Editor (Recommended)**
1. Open `res://themes/bg3_theme.tres` in Godot editor
2. In the Inspector, expand `Panel/styles`
3. Click "+" next to `styles` to add a new stylebox
4. Name it `perf_overlay`
5. Configure:
   - `bg_color = Color(0.05, 0.05, 0.1, 0.85)`
   - `border_width_left/top/right/bottom = 2`
   - `border_color = Color(1, 0.843, 0, 0.6)`
   - `corner_radius_* = 6`

**Option B: Via Script (If theme is data-driven)**
```gdscript
# In PerformanceMonitor._ready(), after loading theme:
var stylebox := StyleBoxFlat.new()
stylebox.bg_color = Color(0.05, 0.05, 0.1, 0.85)
stylebox.border_width_left = 2
stylebox.border_width_top = 2
stylebox.border_width_right = 2
stylebox.border_width_bottom = 2
stylebox.border_color = Color(1, 0.843, 0, 0.6)
stylebox.corner_radius_top_left = 6
stylebox.corner_radius_top_right = 6
stylebox.corner_radius_bottom_right = 6
stylebox.corner_radius_bottom_left = 6

perf_panel.add_theme_stylebox_override("panel", stylebox)
```

**Recommendation:** Add Option B to script for immediate effect, document Option A for future theme updates.

---

## 9. 🟢 Nice-to-Have: Export Variables for Customization

### Enhancement
Make graph colors and thresholds configurable:

```gdscript
# In PerformanceMonitor.gd, add:
@export var fps_good_threshold: float = 55.0
@export var fps_warning_threshold: float = 30.0
@export var fps_good_color: Color = Color(0.2, 1.0, 0.2)
@export var fps_warning_color: Color = Color(1.0, 0.8, 0.2)
@export var fps_bad_color: Color = Color(1.0, 0.2, 0.2)

# In _process(), use:
if fps >= fps_good_threshold:
	fps_label.modulate = fps_good_color
elif fps >= fps_warning_threshold:
	fps_label.modulate = fps_warning_color
else:
	fps_label.modulate = fps_bad_color
```

**Recommendation:** Optional for advanced users who want to customize.

---

## 10. 🟢 Nice-to-Have: Graph Smoothing Option

### Enhancement
Add optional smoothing for graphs (moving average):

```gdscript
# In GraphControl.gd:
@export var smoothing_enabled: bool = false
@export var smoothing_samples: int = 3

func add_value(value: float) -> void:
	if smoothing_enabled and history.size() > 0:
		# Simple moving average
		var avg: float = value
		var count: int = min(smoothing_samples, history.size())
		for i in range(1, count + 1):
			avg += history[history.size() - i]
		avg /= (count + 1)
		value = avg
	
	# ... rest of add_value() ...
```

**Recommendation:** Optional for users who prefer smoother graphs.

---

## Priority Summary

### Must-Fix (Before Implementation)
1. ✅ **Node Path Mismatch** (#1) – Will cause runtime errors

### Should-Fix (Recommended)
2. 🟡 **Settings Error Handling** (#3) – Production robustness
3. 🟡 **Remove Redundant Input Call** (#4) – Code cleanup
4. 🟡 **Add MythosLogger** (#5) – Project consistency

### Nice-to-Have (Optional)
5. 🟢 **Graph History Optimization** (#2) – Performance (only if needed)
6. 🟢 **Scene Integration Pattern** (#6) – Consistency
7. 🟢 **Graph Min/Max Labels** (#7) – UX polish
8. 🟢 **Theme Stylebox Guide** (#8) – Documentation
9. 🟢 **Export Variables** (#9) – Customization
10. 🟢 **Graph Smoothing** (#10) – Advanced feature

---

## Final Recommendation

**The specification is production-ready** with one critical fix (#1: Node Path). The remaining improvements are optional polish that can be added incrementally.

**Minimum Required Changes:**
1. Fix node paths in `PerformanceMonitor.gd` (remove `MarginContainer` from paths or adjust scene structure)

**Recommended Additions:**
2. Add error handling to settings save/load
3. Remove `set_process_input(true)`
4. Add MythosLogger calls

**Everything else is optional enhancement.**

---

## Conclusion

The polished specification is **excellent** and demonstrates thorough consideration of project rules, performance, and UX. With the node path fix, it's ready for immediate implementation. The remaining improvements are incremental enhancements that can be added post-implementation based on testing and user feedback.

**Status:** ✅ **APPROVED FOR IMPLEMENTATION** (fix #1 first, then optional enhancements)
