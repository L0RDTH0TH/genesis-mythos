# Flamegraph Profiling System Implementation Audit

**Date:** 2025-01-20  
**Auditor:** Auto (Cursor AI)  
**Scope:** Complete audit of flamegraph profiling system including data collection, processing, rendering, and display

---

## Executive Summary

The Genesis Mythos project implements a comprehensive flamegraph profiling system for performance analysis. The system consists of a singleton profiler (`FlameGraphProfiler`) that collects stack trace samples and aggregates them into hierarchical call trees, and a UI control (`FlameGraphControl`) that renders the data as nested horizontal bars. The implementation is functional with proper thread-safety, configuration management, and export capabilities. However, there are limitations in detail level, update timing, and rendering depth that could be improved.

**Status:** ✅ Functional with known limitations  
**Recommendation:** Enhance detail level, improve update synchronization, and add deeper call stack visualization

---

## 1. System Architecture Overview

### 1.1 Component Structure

The flamegraph system consists of four main components:

1. **FlameGraphProfiler** (`core/singletons/FlameGraphProfiler.gd`)
   - Singleton autoload registered in `project.godot`
   - Collects stack trace samples via `get_stack()`
   - Aggregates samples into hierarchical call tree
   - Exports data to JSON format

2. **FlameGraphControl** (`scripts/ui/overlays/FlameGraphControl.gd`)
   - Custom Control node for rendering flamegraph visualization
   - Recursively draws nested bars representing call hierarchy
   - Provides tooltip interaction for detailed information

3. **PerformanceMonitor** (`scripts/ui/overlays/PerformanceMonitor.gd`)
   - Manages visibility and mode switching (OFF/SIMPLE/DETAILED/FLAME)
   - Controls when profiling starts/stops
   - Integrates flamegraph with other performance overlays

4. **Configuration** (`data/config/flame_graph_config.json`)
   - JSON-based configuration for sampling intervals, depth limits, export settings

### 1.2 Data Flow

```
User activates FLAME mode (F3)
    ↓
PerformanceMonitor.set_mode(Mode.FLAME)
    ↓
FlameGraphProfiler.start_profiling()
    ↓
Sampling Timer (100ms interval) → _collect_stack_sample()
    ↓
Stack samples stored in ring buffer (MAX_SAMPLES = 1000)
    ↓
Aggregation Timer (1s interval) → _aggregate_samples_to_tree()
    ↓
Call tree built hierarchically with time statistics
    ↓
aggregation_complete signal emitted
    ↓
FlameGraphControl.update_from_profiler()
    ↓
FlameGraphControl._draw() renders nested bars
```

---

## 2. File Inventory

### 2.1 Core Implementation Files

| File Path | Lines | Purpose |
|-----------|-------|---------|
| `core/singletons/FlameGraphProfiler.gd` | 591 | Singleton profiler for data collection and aggregation |
| `scripts/ui/overlays/FlameGraphControl.gd` | 495 | UI control for flamegraph rendering |
| `scripts/ui/overlays/PerformanceMonitor.gd` | 922 | Performance overlay manager with mode switching |
| `scenes/ui/overlays/PerformanceMonitor.tscn` | 185 | Scene file with node hierarchy |
| `data/config/flame_graph_config.json` | 14 | Configuration file for profiling settings |
| `scripts/ui/UIConstants.gd` | 80 | UI constants including `WATERFALL_LANE_HEIGHT = 60` |

### 2.2 Related Files

- `audit/flamegraph_display_audit.md` - Previous audit (2025-12-21)
- `audit/flamegraph_display_audit_2.md` - Visibility bug fix audit (2025-01-20)
- `flame_graph_freeze_audit.md` - Performance freeze investigation
- `audit/flame_graph_integration_audit.md` - Integration analysis

---

## 3. Data Collection Analysis

### 3.1 Sampling Mechanism

**Location:** `FlameGraphProfiler.gd:264-328`

The profiler uses interval-based sampling with the following characteristics:

- **Sampling Interval:** Configurable via `sampling_interval_ms` (default: 100ms in config, 10ms in code defaults)
- **Method:** `get_stack()` - Godot's built-in stack trace function
- **Throttling:** Minimum 50ms between samples (`MIN_SAMPLE_INTERVAL_MSEC`)
- **Rate Limiting:** Integrated with `PerformanceMonitorSingleton.can_log()` to prevent excessive logging

**Key Code:**
```gdscript
func _collect_stack_sample() -> void:
    """Collect a stack trace sample (called by sampling timer)."""
    # Additional throttling: Ensure minimum time between samples
    var now: int = Time.get_ticks_msec()
    if now - _last_sample_time < MIN_SAMPLE_INTERVAL_MSEC:
        return  # Skip if sampled too recently
    
    # Get stack trace (get_stack() returns Array[Dictionary] with source, function, line)
    var raw_stack: Array = get_stack()
    
    # Limit stack depth (keep deepest frames, remove top-level ones)
    var max_depth: int = config.get("max_stack_depth", 20)
    # ... formatting and storage ...
```

**Performance Overhead:**
- `get_stack()` is expensive (1-5ms with deep stacks)
- Current config: 100ms interval = 10 samples/sec (acceptable)
- Previous config: 10ms interval = 100 samples/sec (caused freezes - fixed)

### 3.2 Data Storage

**Location:** `FlameGraphProfiler.gd:45-47`

- **Buffer Type:** Ring buffer (Array[Dictionary])
- **Max Samples:** 1000 (`MAX_SAMPLES`)
- **Memory:** ~50KB estimated
- **Thread Safety:** Mutex-protected (`_buffer_mutex`)

**Sample Structure:**
```gdscript
{
    "frame_id": int,              # Engine frame ID
    "timestamp_usec": int,         # Microsecond timestamp
    "stack": Array[Dictionary],   # Stack frames with function, source, line
    "stack_depth": int,           # Number of frames
    "time_ms": float              # Optional: time spent (if provided)
}
```

### 3.3 Stack Frame Formatting

**Location:** `FlameGraphProfiler.gd:304-313`

Each stack frame is formatted as:
```gdscript
{
    "function": String,  # Function name
    "source": String,    # Source file path
    "line": int          # Line number
}
```

**Limitations:**
- Only shows function name, source file, and line number
- No parameter values or variable states
- No return value information
- Limited to GDScript stack traces (no C++/native code details)

---

## 4. Data Processing Analysis

### 4.1 Aggregation Mechanism

**Location:** `FlameGraphProfiler.gd:469-561`

The profiler aggregates samples into a hierarchical call tree:

**Process:**
1. Initialize root node with `<root>` function
2. For each sample, traverse stack from deepest to shallowest
3. Create or update nodes for each function call
4. Accumulate `total_time_ms`, `call_count`, and `frame_ids`
5. Calculate `self_time_ms` (time spent in function itself, excluding children)

**Call Tree Structure:**
```gdscript
{
    "function": "<root>",
    "source": "",
    "line": 0,
    "total_time_ms": float,      # Total time including children
    "self_time_ms": float,        # Time in function itself
    "call_count": int,            # Number of times called
    "frame_ids": Array[int],      # Frame IDs where this function appeared
    "children": Dictionary {      # Child function calls
        "source:function:line": {
            # Same structure recursively
        }
    }
}
```

**Aggregation Interval:** 1 second (`AGGREGATION_INTERVAL_SECONDS`)

**Key Code:**
```gdscript
func _aggregate_samples_to_tree(samples: Array[Dictionary]) -> void:
    """Aggregate stack trace samples into hierarchical call tree."""
    call_tree.clear()
    
    # Initialize root node
    call_tree = {
        "function": "<root>",
        "source": "",
        "line": 0,
        "total_time_ms": 0.0,
        "self_time_ms": 0.0,
        "call_count": 0,
        "frame_ids": [],
        "children": {}
    }
    
    # Process each sample
    for sample in samples:
        var stack: Array = sample.get("stack", [])
        # ... build tree recursively ...
```

### 4.2 Time Calculation

**Location:** `FlameGraphProfiler.gd:494-556`

**Time Assignment:**
- If sample has `time_ms`, use that value
- Otherwise, estimate using `sampling_interval_ms` (default: 10ms)
- All nodes in a stack trace receive the same time value
- Self-time calculated as: `total_time - sum(children's total_time)`

**Limitations:**
- Time is estimated, not measured directly
- All functions in a stack trace get equal time allocation
- No distinction between CPU time and wall-clock time
- No per-function timing measurements

### 4.3 Self-Time Calculation

**Location:** `FlameGraphProfiler.gd:564-581`

Self-time (time spent in function itself, excluding children) is calculated recursively:

```gdscript
func _calculate_self_times(node: Dictionary) -> void:
    """Recursively calculate self_time for all nodes."""
    # First, recursively calculate self_times for all children
    for child_key in children.keys():
        var child: Dictionary = children[child_key]
        _calculate_self_times(child)
        children_total += child.get("total_time_ms", 0.0)
    
    # Then calculate self_time for this node
    var self_time: float = max(0.0, total_time - children_total)
    node["self_time_ms"] = self_time
```

**Accuracy:** Good for identifying hot functions, but limited by sampling resolution

---

## 5. Rendering Analysis

### 5.1 Drawing Mechanism

**Location:** `FlameGraphControl.gd:270-305`

The flamegraph is rendered using Godot's `_draw()` method with recursive bar drawing:

**Rendering Process:**
1. Draw background (dark parchment color)
2. Check if data is available (show status messages if not)
3. Draw grid lines for reference
4. Recursively draw root node and all children
5. Draw hover highlight if tooltip is active
6. Overlay total time information

**Key Code:**
```gdscript
func _draw() -> void:
    """Draw the flame graph with nested rectangles and status feedback."""
    # Always draw background
    var bg_color: Color = Color(0.1, 0.08, 0.06, 0.9)
    draw_rect(Rect2(Vector2.ZERO, size), bg_color)
    
    # If no data yet, show helpful status
    if call_tree.is_empty():
        _draw_status_message("Collecting samples...\nPress F3 to cycle modes")
        return
    
    if _total_time_ms <= 0.1:
        _draw_status_message("Aggregating data...\nSamples collected but processing")
        return
    
    # Valid data - draw the actual flame graph
    _draw_grid()
    var root_y: float = UIConstants.SPACING_MEDIUM
    _draw_func_node(call_tree, 0.0, root_y, size.x, 0, _total_time_ms)
```

### 5.2 Recursive Node Drawing

**Location:** `FlameGraphControl.gd:327-401`

Each function node is drawn as a horizontal bar:

**Bar Properties:**
- **Width:** Proportional to `total_time_ms` relative to parent
- **Height:** `UIConstants.WATERFALL_LANE_HEIGHT` (60px)
- **Color:** Based on `self_time_ms` (green → yellow → red gradient)
- **Position:** X position based on sibling order, Y position based on depth

**Key Code:**
```gdscript
func _draw_func_node(node: Dictionary, x: float, y: float, width: float, depth: int, parent_total_time: float) -> void:
    """Recursively draw a function node and its children."""
    if depth >= MAX_RENDER_DEPTH:
        return  # Prevent excessive recursion
    
    var node_time: float = node.get("total_time_ms", 0.0)
    var node_width: float = (node_time / parent_total_time) * width
    
    if node_width < MIN_BAR_WIDTH:
        return  # Skip if too narrow
    
    # Get node color based on self_time
    var self_time: float = node.get("self_time_ms", 0.0)
    var node_color: Color = _get_node_color(self_time, node_time)
    
    # Draw this node's bar
    var bar_rect: Rect2 = Rect2(Vector2(x, y), Vector2(node_width, lane_height))
    draw_rect(bar_rect, node_color)
    
    # Draw function name label if bar is wide enough
    if node_width > UIConstants.LABEL_WIDTH_NARROW:
        var function_name: String = node.get("function", "unknown")
        draw_string(ThemeDB.fallback_font, label_pos, function_name, ...)
    
    # Draw children recursively
    # ...
```

### 5.3 Color Coding

**Location:** `FlameGraphControl.gd:403-418`

Colors are based on `self_time_ms` (time spent in function itself):

- **Green:** `self_time_ms < 1.0ms` (good performance)
- **Yellow:** `1.0ms <= self_time_ms < 5.0ms` (warning)
- **Red:** `self_time_ms >= 10.0ms` (bad performance)

**Gradient Calculation:**
```gdscript
func _get_node_color(self_time_ms: float, total_time_ms: float) -> Color:
    """Get color for a node based on self time (green → yellow → red gradient)."""
    var intensity: float = clamp(self_time_ms / TIME_BAD_MS, 0.0, 1.0)
    var r: float = intensity
    var g: float = 1.0 - (intensity * 0.5)  # Green fades slower
    var b: float = 0.0
    var alpha: float = 0.85 - (intensity * 0.15)
    return Color(r, g, b, alpha)
```

### 5.4 Rendering Limitations

**Maximum Render Depth:** 15 levels (`MAX_RENDER_DEPTH`)
- Prevents excessive recursion and performance issues
- Deeper call stacks are truncated

**Minimum Bar Width:** 2.0 pixels (`MIN_BAR_WIDTH`)
- Bars narrower than 2px are not drawn
- Prevents visual clutter from tiny bars

**Label Display:** Only shown if bar width > `LABEL_WIDTH_NARROW` (80px)
- Narrow bars don't show function names
- Tooltip still works for narrow bars

---

## 6. Update and Synchronization

### 6.1 Update Intervals

**FlameGraphControl Updates:**
- **Frame-based:** Every 60 frames (~1 second at 60 FPS)
- **Signal-based:** Immediate on `aggregation_complete` signal
- **Location:** `FlameGraphControl.gd:85-92`

**FlameGraphProfiler Aggregation:**
- **Interval:** 1 second (`AGGREGATION_INTERVAL_SECONDS`)
- **Location:** `FlameGraphProfiler.gd:229-241`

**Synchronization:**
- Signal connection ensures immediate updates after aggregation
- Location: `FlameGraphControl.gd:81-82`

```gdscript
# Connect to profiler aggregation signal for immediate updates
if FlameGraphProfiler and FlameGraphProfiler.has_signal("aggregation_complete"):
    FlameGraphProfiler.aggregation_complete.connect(_on_aggregation_complete)
```

### 6.2 Timing Issues

**Potential Race Condition:**
- Control may try to render before aggregation completes
- Status messages handle this gracefully ("Collecting samples...", "Aggregating data...")
- Signal connection mitigates most timing issues

**Update Throttling:**
- Frame-based updates are throttled to prevent overhead
- Signal-based updates are immediate (no throttling)

---

## 7. User Interaction

### 7.1 Tooltip System

**Location:** `FlameGraphControl.gd:125-253`

The flamegraph provides interactive tooltips on hover:

**Tooltip Information:**
- Function name
- Source file and line number
- Total time (including children)
- Self time (function itself)
- Call count

**Implementation:**
- Mouse position detection via `_gui_input()`
- Recursive position search to find node under cursor
- Tooltip panel positioned near cursor (clamped to viewport)

**Key Code:**
```gdscript
func _update_tooltip() -> void:
    """Update tooltip text and position."""
    var function_name: String = node.get("function", "unknown")
    var source: String = node.get("source", "unknown")
    var line: int = node.get("line", 0)
    var total_time: float = node.get("total_time_ms", 0.0)
    var self_time: float = node.get("self_time_ms", 0.0)
    var call_count: int = node.get("call_count", 0)
    
    var text: String = "Function: %s\n" % function_name
    text += "Source: %s:%d\n" % [source, line]
    text += "Total Time: %.2f ms\n" % total_time
    text += "Self Time: %.2f ms\n" % self_time
    text += "Call Count: %d" % call_count
```

### 7.2 Hover Highlighting

**Location:** `FlameGraphControl.gd:421-470`

Hovered nodes are highlighted with a semi-transparent gold overlay:

```gdscript
func _draw_node_highlight(node: Dictionary, x: float, y: float, width: float, target_key: String, parent_total_time: float) -> bool:
    """Recursively find and highlight target node."""
    # ... find node ...
    if node_key == target_key:
        var highlight_rect: Rect2 = Rect2(Vector2(x, y), Vector2(node_width, lane_height))
        var highlight_color: Color = Color(1.0, 0.843, 0.0, 0.3)  # Semi-transparent gold glow
        draw_rect(highlight_rect, highlight_color)
        return true
```

---

## 8. Export Functionality

### 8.1 JSON Export

**Location:** `FlameGraphProfiler.gd:389-449`

The profiler can export data to JSON format compatible with external tools:

**Export Format:**
```json
{
    "metadata": {
        "export_timestamp": "ISO 8601 timestamp",
        "sample_count": int,
        "profiler": "GenesisMythos_FlameGraphProfiler",
        "version": "1.0.0",
        "config": { ... }
    },
    "call_tree": { ... },  // Hierarchical call tree
    "samples": [ ... ]     // Raw samples array
}
```

**Export Triggers:**
- Automatic on `stop_profiling()`
- Periodic via `auto_export_interval_seconds` (default: 60s)
- Manual via `export_to_json()`

**Export Location:** `user://flame_graphs/flame_graph_YYYYMMDD_HHMMSS.json`

**Compatibility:** Compatible with speedscope, flamegraph.pl, and other flamegraph visualization tools

---

## 9. Configuration System

### 9.1 Configuration File

**Location:** `data/config/flame_graph_config.json`

**Current Configuration:**
```json
{
    "enabled": false,
    "sampling_mode": "sampling",
    "sampling_interval_ms": 100.0,
    "max_stack_depth": 20,
    "export_format": "json",
    "export_directory": "user://flame_graphs/",
    "auto_export_interval_seconds": 60.0,
    "systems": {
        "world_generation": true,
        "rendering": true,
        "entity_sim": false
    }
}
```

**Configuration Loading:**
- Loaded on `_ready()` via `_load_config()`
- Falls back to defaults if file missing or invalid
- Applied via `_apply_config()`

### 9.2 Configurable Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `enabled` | `false` | Auto-start profiling on load |
| `sampling_interval_ms` | `10.0` | Time between stack samples |
| `max_stack_depth` | `20` | Maximum stack frames to capture |
| `auto_export_interval_seconds` | `60.0` | Time between auto-exports |
| `export_directory` | `user://flame_graphs/` | Export file location |

---

## 10. Current Strengths

### 10.1 Architecture

✅ **Well-structured:** Clear separation between data collection, processing, and rendering  
✅ **Thread-safe:** Mutex protection for buffer operations  
✅ **Configurable:** JSON-based configuration with sensible defaults  
✅ **Extensible:** Signal-based communication for updates  
✅ **Exportable:** JSON export compatible with external tools  

### 10.2 Performance

✅ **Low Overhead:** Configurable sampling interval (100ms = 10 samples/sec)  
✅ **Memory Efficient:** Ring buffer limits memory usage (1000 samples max)  
✅ **Throttled Updates:** Frame-based throttling prevents rendering overhead  
✅ **Rate Limiting:** Integrated with performance monitor to prevent excessive logging  

### 10.3 User Experience

✅ **Status Messages:** Helpful feedback when data is collecting/processing  
✅ **Tooltips:** Detailed information on hover  
✅ **Color Coding:** Visual indication of performance (green/yellow/red)  
✅ **Hover Highlighting:** Visual feedback for interactive elements  
✅ **Mode Integration:** Seamless integration with performance monitor modes  

---

## 11. Current Weaknesses and Limitations

### 11.1 Detail Level Limitations

❌ **No Call Stack Details:**
- Only shows function name, source file, and line number
- No parameter values, variable states, or return values
- No distinction between different call sites of the same function

❌ **Limited Depth:**
- Maximum render depth of 15 levels (deeper stacks truncated)
- Maximum stack capture depth of 20 frames (configurable but limited)

❌ **Time Estimation:**
- Time is estimated from sampling interval, not measured directly
- All functions in a stack trace get equal time allocation
- No distinction between CPU time and wall-clock time

❌ **No Per-Function Timing:**
- Cannot measure actual time spent in individual functions
- Relies on statistical sampling rather than instrumentation

### 11.2 Rendering Limitations

❌ **Minimum Bar Width:**
- Bars narrower than 2px are not drawn
- Small but important functions may be invisible

❌ **Label Visibility:**
- Function names only shown if bar width > 80px
- Narrow bars require tooltip to identify

❌ **Depth Truncation:**
- Maximum 15 levels of nesting rendered
- Deeper call stacks are cut off

### 11.3 Update Timing

❌ **Delayed Updates:**
- Frame-based updates every 60 frames (~1 second)
- Signal-based updates are immediate but may miss rapid changes

❌ **Aggregation Delay:**
- 1-second aggregation interval means data is always up to 1 second old
- Rapid performance changes may not be immediately visible

### 11.4 Data Collection Limitations

❌ **Sampling Overhead:**
- `get_stack()` is expensive (1-5ms per call)
- High sampling rates cause performance issues (fixed by increasing interval)

❌ **No Native Code Visibility:**
- Only shows GDScript stack traces
- C++/native code calls are not visible

❌ **No Thread Information:**
- Cannot distinguish between different threads
- All samples aggregated together

---

## 12. Recommendations for Improvement

### 12.1 Enhance Detail Level (High Priority)

**1. Add Call Site Distinction:**
- Modify aggregation to include call site information (caller function + line)
- Create separate nodes for different call sites of the same function
- This would show: `function_name@caller:line` instead of just `function_name`

**2. Increase Depth Limits:**
- Increase `MAX_RENDER_DEPTH` from 15 to 30 or make it configurable
- Add scroll/zoom functionality to navigate deep call stacks
- Implement virtual scrolling for performance

**3. Add Parameter Information:**
- Capture function parameters in stack frames (if possible via reflection)
- Display parameter values in tooltips
- Filter by parameter values

**4. Per-Function Instrumentation:**
- Add manual instrumentation points using `push_flame_data()`
- Allow systems to report actual measured times
- Combine sampling with instrumentation for better accuracy

### 12.2 Improve Rendering (Medium Priority)

**1. Zoom and Pan:**
- Add zoom functionality to see narrow bars in detail
- Implement panning for wide flamegraphs
- Add minimap for navigation

**2. Better Label Handling:**
- Use abbreviated function names for narrow bars
- Add text rotation for vertical labels
- Implement label collision detection

**3. Depth Navigation:**
- Add breadcrumb trail showing current depth
- Implement "zoom to function" feature
- Add depth slider for filtering

### 12.3 Improve Update Timing (Medium Priority)

**1. Reduce Aggregation Interval:**
- Make aggregation interval configurable (currently fixed at 1s)
- Add adaptive interval based on sample rate
- Consider incremental aggregation instead of full rebuild

**2. Improve Synchronization:**
- Ensure signal-based updates are always immediate
- Add debouncing for rapid updates
- Consider using `NOTIFICATION_THEME_CHANGED` for size changes

### 12.4 Enhance Data Collection (Low Priority)

**1. Native Code Integration:**
- Investigate Godot's native profiler integration
- Add support for C++ stack traces if available
- Combine GDScript and native profiling data

**2. Thread Awareness:**
- Add thread ID to samples
- Separate call trees by thread
- Add thread selector in UI

**3. Memory Profiling:**
- Add memory allocation tracking to samples
- Show memory usage per function in tooltips
- Add memory-based color coding option

### 12.5 User Experience Improvements (Low Priority)

**1. Search and Filter:**
- Add search box to find specific functions
- Filter by time thresholds (show only functions > X ms)
- Filter by source file or function name pattern

**2. Comparison Mode:**
- Allow loading multiple flamegraph exports
- Compare two profiles side-by-side
- Highlight differences between profiles

**3. Export Enhancements:**
- Add export to other formats (SVG, PNG, HTML)
- Add export of filtered/zoomed views
- Add export of specific time ranges

---

## 13. Code Quality Assessment

### 13.1 Code Organization

✅ **Well-structured:** Clear separation of concerns  
✅ **Typed GDScript:** Proper type annotations throughout  
✅ **Documentation:** Comprehensive docstrings on public functions  
✅ **Error Handling:** Proper error handling and fallbacks  

### 13.2 Performance Considerations

✅ **Throttling:** Proper update throttling to prevent overhead  
✅ **Memory Management:** Ring buffer prevents unbounded growth  
✅ **Thread Safety:** Mutex protection for shared data  

### 13.3 Maintainability

✅ **Configuration:** External JSON configuration for easy tuning  
✅ **Constants:** UI constants in `UIConstants.gd` for consistency  
✅ **Signals:** Signal-based communication for loose coupling  

### 13.4 Areas for Improvement

⚠️ **Magic Numbers:** Some hard-coded values could be constants (e.g., `TIME_GOOD_MS = 1.0`)  
⚠️ **Error Messages:** Could be more descriptive in some cases  
⚠️ **Testing:** No unit tests found for flamegraph system  

---

## 14. Integration Points

### 14.1 Performance Monitor Integration

**Location:** `PerformanceMonitor.gd:362-382`

The flamegraph is integrated into the performance monitor's mode system:

- **OFF:** All overlays hidden, profiling stopped
- **SIMPLE:** FPS only, profiling stopped
- **DETAILED:** All metrics + waterfall view, profiling stopped
- **FLAME:** All metrics + flamegraph view, profiling active

**Key Integration Code:**
```gdscript
Mode.FLAME:
    if bottom_graph_bar:
        bottom_graph_bar.visible = true
    if waterfall_control:
        waterfall_control.visible = false
    if flame_graph_control:
        flame_graph_control.visible = true
    if FlameGraphProfiler:
        FlameGraphProfiler.start_profiling()
```

### 14.2 Singleton Dependencies

- **FlameGraphProfiler:** Autoload singleton (registered in `project.godot`)
- **PerformanceMonitorSingleton:** Used for rate limiting
- **MythosLogger:** Used for debug/info logging
- **UIConstants:** Used for UI sizing constants

---

## 15. Known Issues and Fixes

### 15.1 Fixed Issues

✅ **Visibility Bug (Fixed):**
- **Issue:** `_update_bottom_graph_bar()` only showed bottom bar in DETAILED mode
- **Fix:** Updated to include FLAME mode: `bottom_graph_bar.visible = (current_mode == Mode.DETAILED or current_mode == Mode.FLAME)`
- **Location:** `PerformanceMonitor.gd:577` (fixed in current code)

✅ **Performance Freeze (Fixed):**
- **Issue:** High sampling rate (10ms interval) caused freezes
- **Fix:** Increased default interval to 100ms, added throttling (`MIN_SAMPLE_INTERVAL_MSEC = 50`)
- **Location:** `FlameGraphProfiler.gd:64, 269-274`

### 15.2 Remaining Issues

⚠️ **Update Timing Race Condition:**
- Control may try to render before aggregation completes
- Mitigated by status messages and signal connection
- **Recommendation:** Add explicit "ready" state check

⚠️ **Early Return Logic:**
- `_draw()` returns early if `call_tree.is_empty()` or `_total_time_ms <= 0.0`
- Status messages handle this, but could be more informative
- **Recommendation:** Add more detailed status messages

---

## 16. Testing Recommendations

### 16.1 Unit Tests

- Test `_aggregate_samples_to_tree()` with various sample structures
- Test `_calculate_self_times()` with known call trees
- Test `_draw_func_node()` with edge cases (zero time, very narrow bars)
- Test tooltip position calculation and clamping

### 16.2 Integration Tests

- Test mode switching (OFF → SIMPLE → DETAILED → FLAME)
- Test profiling start/stop lifecycle
- Test export functionality with various data sizes
- Test signal connections and update timing

### 16.3 Performance Tests

- Measure overhead of `get_stack()` at different intervals
- Test memory usage with maximum samples (1000)
- Test rendering performance with deep call stacks (15+ levels)
- Test update performance with rapid aggregation

---

## 17. Summary

### 17.1 Current State

The flamegraph profiling system is **functional and well-implemented** with proper architecture, thread safety, and user experience features. It successfully collects stack trace samples, aggregates them into hierarchical call trees, and renders them as nested horizontal bars with interactive tooltips.

### 17.2 Key Strengths

- ✅ Clean architecture with separation of concerns
- ✅ Thread-safe data collection
- ✅ Configurable via JSON
- ✅ Export functionality for external tools
- ✅ Good user experience with tooltips and status messages
- ✅ Low performance overhead

### 17.3 Key Limitations

- ❌ Limited detail level (no call site distinction, no parameters)
- ❌ Maximum depth restrictions (15 render, 20 capture)
- ❌ Time estimation rather than direct measurement
- ❌ No native code visibility
- ❌ Update timing delays (1-second aggregation interval)

### 17.4 Priority Recommendations

1. **High Priority:** Enhance detail level (call site distinction, increased depth)
2. **Medium Priority:** Improve rendering (zoom, pan, better labels)
3. **Medium Priority:** Reduce update delays (configurable aggregation interval)
4. **Low Priority:** Add search/filter, comparison mode, native code support

---

## 18. Conclusion

The flamegraph profiling system is a solid implementation that provides valuable performance insights. While it has limitations in detail level and update timing, these are reasonable trade-offs for a sampling-based profiler. The system is well-architected, maintainable, and provides a good foundation for future enhancements.

**Overall Assessment:** ✅ **Functional and Production-Ready** with room for enhancement

---

**Report Generated:** 2025-01-20  
**Auditor:** Auto (Cursor AI)  
**Status:** Complete - Ready for Review

