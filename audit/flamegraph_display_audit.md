# Flame Graph Display Audit

## Overview

The flame graph visualization in `FlameGraphControl` successfully collects profiling data and exports JSON files (e.g., `flame_graph_20251221_062956.json` with 89 samples), but no actual stacked flame graph visualization appears on screen. Only waterfall-style bars or partial timelines are shown in screenshots, indicating the hierarchical flame graph rendering is not functioning correctly.

## Files Reviewed

1. **`scripts/ui/overlays/FlameGraphControl.gd`** (452 lines)
   - Custom Control node responsible for rendering the flame graph visualization
   - Contains `_draw()` method and recursive `_draw_func_node()` logic

2. **`core/singletons/FlameGraphProfiler.gd`** (584 lines)
   - Singleton that collects stack trace samples and aggregates them into a hierarchical call tree
   - Provides `get_call_tree()` method for data retrieval

3. **`scripts/ui/overlays/PerformanceMonitor.gd`** (922 lines)
   - Overlay controller that manages visibility and mode switching
   - Handles FLAME mode activation and `FlameGraphControl` visibility

4. **`scenes/ui/overlays/PerformanceMonitor.tscn`**
   - Scene file defining the node hierarchy
   - `FlameGraphControl` is a child of `BottomGraphBar/MarginContainer/BottomGraphsContainer`

5. **`scripts/ui/UIConstants.gd`**
   - Defines `WATERFALL_LANE_HEIGHT = 60` used for flame graph rendering

6. **`data/config/flame_graph_config.json`**
   - Configuration with `sampling_interval_ms: 100.0` and `enabled: false`

## Potential Causes

### 1. Early Return in `_draw()` Prevents Rendering (HIGH PRIORITY)

**Location:** `FlameGraphControl.gd:256-260`

```254:260:scripts/ui/overlays/FlameGraphControl.gd
func _draw() -> void:
	"""Draw the flame graph with nested rectangles."""
	if call_tree.is_empty() or _total_time_ms <= 0.0:
		# Draw background only
		var bg_color: Color = Color(0.1, 0.08, 0.06, 0.9)  # Parchment-like
		draw_rect(Rect2(Vector2.ZERO, size), bg_color)
		return
```

**Issue:** The `_draw()` function returns early if `call_tree.is_empty()` or `_total_time_ms <= 0.0`, drawing only a background. This can occur if:
- Aggregation hasn't completed yet (1-second interval vs 0.5-second update interval)
- No samples have been collected
- The call tree structure doesn't match expectations

**Impact:** If aggregation is delayed or samples haven't accumulated, the control will draw only the background, explaining why no flame graph bars appear.

### 2. Root Node Drawing Logic May Skip Root (MEDIUM PRIORITY)

**Location:** `FlameGraphControl.gd:272`

```269:272:scripts/ui/overlays/FlameGraphControl.gd
	# Draw root node and all children recursively
	# Root node uses full width, children are proportional to parent
	var root_y: float = UIConstants.SPACING_MEDIUM
	_draw_func_node(call_tree, 0.0, root_y, size.x, 0, _total_time_ms)
```

**Issue:** The root node (`function: "<root>"`) is passed to `_draw_func_node()`, but the drawing logic in `_draw_func_node()` (line 315-317) may skip nodes with `node_time <= 0.0`. If the root node's `total_time_ms` is 0 or very small, it won't be drawn, and children might not be drawn either if they depend on the root.

**Impact:** Even if children exist, the root node might not render, causing the entire graph to fail.

### 3. Data Structure Mismatch in `update_from_profiler()` (MEDIUM PRIORITY)

**Location:** `FlameGraphControl.gd:91-106`

```91:106:scripts/ui/overlays/FlameGraphControl.gd
func update_from_profiler() -> void:
	"""Pull data from FlameGraphProfiler and update visualization."""
	if not FlameGraphProfiler:
		return
	
	# Get call tree from profiler
	call_tree = FlameGraphProfiler.get_call_tree()
	
	# Extract total time from root node for scaling
	if call_tree.has("total_time_ms"):
		_total_time_ms = call_tree.get("total_time_ms", 0.0)
	else:
		_total_time_ms = 0.0
	
	# Trigger redraw
	queue_redraw()
```

**Issue:** The code checks `call_tree.has("total_time_ms")`, but if `call_tree` is empty (returned from `get_call_tree()` when no aggregation has occurred), this will set `_total_time_ms = 0.0`, triggering the early return in `_draw()`.

**Impact:** If aggregation hasn't run yet or samples are empty, `_total_time_ms` will be 0, preventing any drawing.

### 4. Update Timing Race Condition (MEDIUM PRIORITY)

**Location:** `FlameGraphControl.gd:81-88` and `FlameGraphProfiler.gd:226-238`

```81:88:scripts/ui/overlays/FlameGraphControl.gd
func _process(_delta: float) -> void:
	"""Update call tree data periodically to avoid overhead."""
	_update_frame_counter += 1
	
	# Throttle updates: Only update every UPDATE_INTERVAL_FRAMES
	if _update_frame_counter >= UPDATE_INTERVAL_FRAMES:
		_update_frame_counter = 0
		update_from_profiler()
```

**Issue:** 
- `FlameGraphControl` updates every 30 frames (~0.5s at 60 FPS)
- `FlameGraphProfiler` aggregates every 1 second (`AGGREGATION_INTERVAL_SECONDS`)
- There's a race condition where the control may try to draw before aggregation completes

**Impact:** The control may attempt to render before the call tree is populated, resulting in empty/background-only renders.

### 5. Control Size/Visibility Issues (LOW PRIORITY)

**Location:** `PerformanceMonitor.tscn:144-155`

```144:155:scenes/ui/overlays/PerformanceMonitor.tscn
[node name="FlameGraphControl" type="Control" parent="BottomGraphBar/MarginContainer/BottomGraphsContainer"]
layout_mode = 2
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
size_flags_horizontal = 3
size_flags_vertical = 3
custom_minimum_size = Vector2(0, 480)
visible = false
script = ExtResource("5_flame_graph_control")
```

**Issue:** The control starts with `visible = false` and relies on `PerformanceMonitor.set_mode(Mode.FLAME)` to set visibility. If the control's size is 0 or invalid when first shown, `_draw()` might not be called or might draw with invalid dimensions.

**Impact:** If size is 0 or anchors aren't properly set, drawing may fail silently.

### 6. Children Dictionary Structure Assumption (LOW PRIORITY)

**Location:** `FlameGraphControl.gd:347-372`

```347:372:scripts/ui/overlays/FlameGraphControl.gd
	# Draw children recursively
	var children: Dictionary = node.get("children", {})
	if children.is_empty():
		return
	
	var child_y: float = y + lane_height
	var child_x: float = x
	
	# Draw each child with proportional width
	for child_key in children.keys():
		var child: Dictionary = children[child_key]
		var child_time: float = child.get("total_time_ms", 0.0)
		
		# Calculate child width relative to parent node width
		# Child width = (child_time / parent_total_time) * parent_width
		# But we use node_time as parent_total_time for children
		var child_width: float = 0.0
		if node_time > 0.0:
			child_width = (child_time / node_time) * node_width
		else:
			child_width = node_width / children.size()  # Equal distribution if no time data
		
		# Only draw if child has time and is wide enough
		if child_time > 0.0 and child_width >= MIN_BAR_WIDTH:
			_draw_func_node(child, child_x, child_y, child_width, depth + 1, node_time)
		
		child_x += child_width
```

**Issue:** The code assumes `children` is a Dictionary with string keys mapping to child node dictionaries. If the structure differs (e.g., Array instead of Dictionary), the iteration will fail silently.

**Impact:** If the profiler returns a different structure, children won't be drawn.

### 7. Missing Debug Logging (LOW PRIORITY)

**Location:** Throughout `FlameGraphControl.gd`

**Issue:** There's no debug logging to indicate:
- When `_draw()` is called
- What `call_tree` contains
- What `_total_time_ms` value is
- Whether nodes are being skipped due to size/time constraints

**Impact:** Difficult to diagnose why rendering fails without visibility into the control's state.

## Recommendations

### Priority 1: Fix Early Return Logic

1. **Add fallback rendering for empty/zero-time cases:**
   - Instead of returning early, draw a message like "Collecting samples..." or "No data yet"
   - This provides visual feedback that the control is active but waiting for data

2. **Add debug logging in `_draw()`:**
   ```gdscript
   func _draw() -> void:
       MythosLogger.debug("FlameGraphControl", "_draw() called - call_tree empty: %s, total_time_ms: %.2f" % [call_tree.is_empty(), _total_time_ms])
       # ... rest of function
   ```

3. **Validate data before early return:**
   - Check if aggregation has occurred at least once
   - Log when early return happens to understand timing issues

### Priority 2: Fix Update Timing

1. **Synchronize update intervals:**
   - Reduce `UPDATE_INTERVAL_FRAMES` to match or be slightly longer than aggregation interval
   - Or trigger `update_from_profiler()` immediately after aggregation completes (via signal)

2. **Add signal connection:**
   - Have `FlameGraphProfiler` emit a signal when aggregation completes
   - Connect `FlameGraphControl` to this signal to update immediately

### Priority 3: Improve Root Node Handling

1. **Ensure root node always draws:**
   - Modify `_draw_func_node()` to always draw the root node even if `total_time_ms` is 0
   - Or skip root node drawing and draw children directly from root's children dictionary

2. **Add validation:**
   - Verify call tree structure matches expectations before drawing
   - Log structure issues for debugging

### Priority 4: Add Comprehensive Debug Logging

1. **Log in `update_from_profiler()`:**
   ```gdscript
   func update_from_profiler() -> void:
       var tree: Dictionary = FlameGraphProfiler.get_call_tree()
       MythosLogger.debug("FlameGraphControl", "update_from_profiler() - tree keys: %s, total_time_ms: %.2f" % [tree.keys(), tree.get("total_time_ms", 0.0)])
       # ... rest of function
   ```

2. **Log in `_draw_func_node()`:**
   - Log when nodes are skipped and why (too small, zero time, etc.)
   - Log node count and depth for each recursive call

### Priority 5: Validate Control State

1. **Check size in `_draw()`:**
   ```gdscript
   if size.x <= 0 or size.y <= 0:
       MythosLogger.warn("FlameGraphControl", "Invalid size in _draw(): %s" % size)
       return
   ```

2. **Verify visibility and tree membership:**
   - Log when control becomes visible/invisible
   - Verify control is in scene tree before drawing

## Next Steps

1. **Add debug logging** to `FlameGraphControl._draw()` and `update_from_profiler()` to capture:
   - Call tree structure and size
   - `_total_time_ms` value
   - When early returns occur
   - Node drawing attempts and skips

2. **Test with minimal repro:**
   - Enable flame profiling
   - Wait 2+ seconds for aggregation
   - Check logs for call tree data
   - Verify `_draw()` is being called

3. **External tool validation:**
   - Load exported JSON (`flame_graph_20251221_062956.json`) into speedscope or flamegraph.pl
   - Verify the data structure is correct and can be visualized externally
   - If external tools work, the issue is in rendering logic; if not, the issue is in data collection

4. **Timing fix:**
   - Reduce `UPDATE_INTERVAL_FRAMES` to 60 (1 second) to match aggregation interval
   - Or add signal-based updates from profiler to control

5. **Root node fix:**
   - Modify `_draw()` to draw children directly if root node has no time
   - Or ensure root node always has a minimum time value for scaling

## Code Snippets for Quick Fixes

### Fix 1: Add Debug Logging to `_draw()`

```gdscript
func _draw() -> void:
	"""Draw the flame graph with nested rectangles."""
	MythosLogger.debug("FlameGraphControl", "_draw() - call_tree empty: %s, total_time_ms: %.2f, size: %s" % [call_tree.is_empty(), _total_time_ms, size])
	
	if call_tree.is_empty() or _total_time_ms <= 0.0:
		# Draw background only
		var bg_color: Color = Color(0.1, 0.08, 0.06, 0.9)  # Parchment-like
		draw_rect(Rect2(Vector2.ZERO, size), bg_color)
		# Draw status message
		var status_text: String = "Collecting samples..." if call_tree.is_empty() else "No time data"
		draw_string(ThemeDB.fallback_font, Vector2(10, 20), status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
		return
	# ... rest of function
```

### Fix 2: Synchronize Update Timing

```gdscript
# In FlameGraphControl.gd, change UPDATE_INTERVAL_FRAMES:
const UPDATE_INTERVAL_FRAMES: int = 60  # Match 1-second aggregation interval
```

### Fix 3: Add Signal-Based Updates

```gdscript
# In FlameGraphProfiler.gd, add signal:
signal aggregation_complete

# In _periodic_aggregate(), emit signal:
func _periodic_aggregate() -> void:
	# ... existing code ...
	if samples_to_aggregate.size() > 0:
		_aggregate_samples_to_tree(samples_to_aggregate)
		aggregation_complete.emit()  # Add this line

# In FlameGraphControl._ready(), connect signal:
func _ready() -> void:
	# ... existing code ...
	if FlameGraphProfiler:
		FlameGraphProfiler.aggregation_complete.connect(update_from_profiler)
```

---

**Report Generated:** 2025-12-21  
**Auditor:** AI Assistant (Cursor)  
**Status:** Analysis Complete - Awaiting Implementation

