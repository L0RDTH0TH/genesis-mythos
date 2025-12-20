# Prompt: Performance Monitor Overlay - Detailed Graph Implementation Analysis

## Objective
Analyze and document the current implementation of the Graphs feature in the Detailed option of the Performance Monitor Overlay. This is a **strictly analytical task** focused on extracting and describing existing code structure, components, data sources, rendering logic, dependencies, and configurations. **Do not suggest improvements, upgrades, or changes**—only document what currently exists.

---

## Key Analysis Areas

### 1. File Structure & Main Components

**Investigate the following files and document their roles:**

- **Main Implementation File:**
  - `res://scripts/ui/overlays/PerformanceMonitor.gd`
    - Identify the class structure, inheritance, and main responsibilities
    - Document the three modes (OFF, SIMPLE, DETAILED) and how DETAILED mode activates graphs
    - List all graph-related node references (top-right graphs and bottom graphs)
    - Document graph configuration logic (max_value, line_color settings for each graph)

- **Graph Rendering Component:**
  - `res://scripts/ui/overlays/GraphControl.gd`
    - Analyze the class structure and inheritance (extends Control)
    - Document the rendering approach (custom `_draw()` method)
    - Identify graph types (line graphs, filled areas, dots, labels)
    - Document smoothing options and circular buffer implementation

- **Scene File:**
  - `res://scenes/ui/overlays/PerformanceMonitor.tscn`
    - Document the node hierarchy for graphs
    - List all GraphControl instances (FPSGraph, ProcessGraph, RefreshGraph, BottomFPSGraph, BottomProcessGraph, BottomRefreshGraph, BottomThreadGraph)
    - Document layout containers (GraphsContainer, BottomGraphsContainer) and their configuration

- **Singleton Wrapper:**
  - `res://core/singletons/PerformanceMonitorSingleton.gd`
    - Document how the singleton instantiates and manages the PerformanceMonitor instance
    - Identify any graph-related methods exposed via the singleton

---

### 2. Data Collection Mechanisms

**Document how performance metrics are gathered:**

- **Engine-Level Metrics:**
  - `Engine.get_frames_per_second()` - Used for FPS graph
  - `Performance.get_monitor(Performance.TIME_PROCESS)` - Process time in seconds (converted to ms)
  - `Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)` - Physics time in seconds (converted to ms)
  - `Performance.get_monitor(Performance.MEMORY_STATIC)` - Static memory usage
  - `Performance.get_monitor(Performance.OBJECT_COUNT)` - Total object count
  - `Performance.get_monitor(Performance.OBJECT_NODE_COUNT)` - Node count

- **RenderingServer Metrics:**
  - `RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)`
  - `RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)`
  - `RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)`
  - `RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED)`
  - `RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED)`
  
  **Note:** Document that RenderingServer metrics require at least 2-3 frames before being available (see `_frame_count >= 3` check in `_process()`).

- **Custom Timing Metrics:**
  - `refresh_time_ms` - Custom timing for `MapRenderer.refresh()` (set via `set_refresh_time()`)
  - `thread_compute_time_ms` - Thread compute time from WorldGenerator (computed in `_update_thread_metrics()`)

- **Update Frequency:**
  - Document that metrics are collected every frame in `_process()` when DETAILED mode is active
  - Document the `set_process_priority(-1000)` for high-priority diagnostic processing
  - Identify the frame-based conditional logic (`if _frame_count >= 3`) for RenderingServer data

---

### 3. Graph Rendering Implementation

**Analyze the GraphControl rendering system:**

- **Rendering Framework:**
  - Confirms that **Godot's built-in `Control._draw()` method** is used for custom canvas drawing
  - No external libraries (no Matplotlib, Chart.js, or third-party graph libraries)
  - Pure GDScript implementation using Godot's drawing API

- **Graph Types:**
  - **Line Graphs:** Primary graph type drawn via `draw_polyline()`
  - **Filled Areas:** Semi-transparent polygon drawn under the line using `draw_colored_polygon()` (25% opacity)
  - **Grid Lines:** Horizontal grid lines (4 lines) drawn via `draw_line()` for reference
  - **Background:** Semi-transparent background rectangle drawn via `draw_rect()`
  - **Current Value Indicator:** Circular dot at the current point (4px radius) drawn via `draw_circle()`

- **Rendering Details:**
  - Document the `_draw()` method's execution flow:
    1. Background rectangle
    2. Grid lines (4 horizontal lines)
    3. Build points array from circular buffer
    4. Draw filled polygon under curve
    5. Draw polyline (main graph line)
    6. Draw current value dot
    7. Update min/max/stats labels
  
  - Document coordinate calculations:
    - X-axis: Time-based progression (linear distribution across graph width)
    - Y-axis: Value-based scaling (normalized between min_val and max_val, inverted for screen coordinates)

- **Update Mechanism:**
  - Graphs update via `queue_redraw()` called in `add_value()`
  - Each frame when DETAILED mode is active, new values are added to graphs, triggering redraw

- **Styling & Colors:**
  - Document export variables for customization:
    - `max_value` (0.0 = auto-scale)
    - `line_color` (default: Color(0.2, 1.0, 0.2) - green)
    - `bg_color` (default: Color(0.0, 0.0, 0.0, 0.4) - semi-transparent black)
    - `grid_color` (default: Color(1.0, 1.0, 1.0, 0.15) - semi-transparent white)
    - `smoothing_enabled` (default: false)
    - `smoothing_samples` (default: 3)
  
  - Document per-graph color configurations in `PerformanceMonitor._ready()`:
    - FPS Graph: Green (Color(0.2, 1.0, 0.2))
    - Process Graph: Yellow/Orange (Color(1.0, 0.8, 0.2))
    - Refresh Graph: Red (Color(1.0, 0.3, 0.3))
    - Thread Graph: Blue (Color(0.3, 0.7, 1.0))

---

### 4. State Management & Data Storage

**Document how graph data is stored and managed:**

- **History Storage:**
  - **Data Structure:** `PackedFloat32Array` named `history`
  - **Size:** Fixed size determined by `UIConstants.PERF_HISTORY_SIZE` (currently 120 samples)
  - **Purpose:** Stores ~2 seconds of data at 60 FPS

- **Circular Buffer Implementation:**
  - Document the circular buffer logic:
    - `history_index` tracks the current write position
    - `history_full` boolean flag indicates when buffer is full
    - When buffer is full, oldest values are overwritten (circular behavior)
    - Index calculation: `(history_index + i) % count` for reading, `(history_index + 1) % UIConstants.PERF_HISTORY_SIZE` for writing

- **Value Addition Process:**
  - `add_value(value: float)` method:
    1. Optional smoothing calculation (if enabled)
    2. Append to array if not full, or overwrite at current index if full
    3. Increment `history_index` with modulo wrap
    4. Call `queue_redraw()` to trigger rendering

- **Statistical Calculations:**
  - Document helper methods:
    - `get_min()` - Calculates minimum from current history
    - `get_max()` - Calculates maximum from current history
    - `get_average()` - Calculates average from current history
    - `_get_auto_max()` - Auto-scales max with 10% padding if `max_value` is 0.0
    - `_get_auto_min()` - Auto-scales min with 10% padding

- **Thread-Safe Metric Collection:**
  - Document the DiagnosticDispatcher infrastructure:
    - `_metric_ring_buffer: Array[Dictionary]` for thread-pushed metrics
    - `_buffer_mutex: Mutex` for thread-safe access
    - `push_metric_from_thread(metric: Dictionary)` for external threads to push metrics
    - Metrics are drained in `_process()` and fed to `bottom_thread_graph`

---

### 5. UI Integration & Layout

**Document how graphs are integrated into the overlay UI:**

- **Top-Right Panel Graphs:**
  - **Container:** `GraphsContainer` (HBoxContainer) inside `PerfPanel/Content`
  - **Graphs:**
    - `FPSGraph` - FPS over time (max: 60.0)
    - `ProcessGraph` - Process time in ms (max: 16.67ms = 60 FPS budget)
    - `RefreshGraph` - MapRenderer refresh time (max: 16.67ms)
  - **Sizing:**
    - Width: 20% of viewport width (`UIConstants.PERF_GRAPH_WIDTH_RATIO = 0.2`)
    - Height: 100px (`UIConstants.PERF_GRAPH_HEIGHT`)
    - Set dynamically in `_on_viewport_resized()`

- **Bottom Graph Bar:**
  - **Container:** `BottomGraphBar` (PanelContainer) positioned at bottom of viewport
  - **Visibility:** Only visible in DETAILED mode
  - **Layout:** `BottomGraphsContainer` (HBoxContainer) with 40px separation
  - **Graphs:**
    - `BottomFPSGraph` - Large FPS graph (max: 120.0)
    - `BottomProcessGraph` - Large process time graph (max: 33.33ms)
    - `BottomRefreshGraph` - Large refresh time graph (max: 33.33ms)
    - `BottomThreadGraph` - Thread compute time graph (max: 33.33ms)
  - **Sizing:**
    - Bar height: 480px (`UIConstants.BOTTOM_GRAPH_BAR_HEIGHT`)
    - Individual graph height: 140px (`UIConstants.GRAPH_INNER_HEIGHT`)
    - Bottom margin: 20px (`UIConstants.BOTTOM_GRAPH_BAR_MARGIN`)

- **Positioning Logic:**
  - Document `_apply_panel_positioning()` for top-right panel
  - Document `_update_bottom_graph_bar()` for bottom graph bar
  - Document `_on_viewport_resized()` handler that updates graph sizes on window resize

- **Labels & Annotations:**
  - Each graph includes:
    - `min_label` - Minimum value label (bottom-left, 10px font)
    - `max_label` - Maximum value label (top-left, 10px font)
    - `stats_label` - Min/Avg/Max statistics (bottom-center, 9px font, format: "Min: X.X | Avg: X.X | Max: X.X")

---

### 6. Update Cycle & Performance

**Document the update and rendering flow:**

- **Frame-by-Frame Updates:**
  - `_process(_delta: float)` is called every frame when DETAILED mode is active
  - Execution order:
    1. Drain diagnostic queue (thread-safe log/UI updates)
    2. Drain metric ring buffer (thread-safe metric collection)
    3. Feed drained metrics to `bottom_thread_graph`
    4. Collect FPS and process time metrics
    5. If DETAILED mode and `_frame_count >= 3`:
       - Update detailed metric labels
       - Add values to top-right graphs (`fps_graph.add_value()`, `process_graph.add_value()`, `refresh_graph.add_value()`)
       - Add values to bottom graphs (`bottom_fps_graph.add_value()`, `bottom_process_graph.add_value()`, `bottom_refresh_graph.add_value()`, `bottom_thread_graph.add_value()`)

- **Rendering Trigger:**
  - Each `add_value()` call triggers `queue_redraw()`
  - `_draw()` is called by Godot's rendering system
  - Multiple graphs = multiple `_draw()` calls per frame

- **Performance Considerations:**
  - Process priority: `-1000` (high priority for diagnostics)
  - Circular buffer limits memory growth (fixed 120 samples)
  - Conditional rendering: Only active graphs redraw (visibility controlled by mode)

---

### 7. Dependencies & Configuration

**Document external dependencies and configuration:**

- **UIConstants.gd:**
  - Location: `res://scripts/ui/UIConstants.gd`
  - Constants used:
    - `PERF_HISTORY_SIZE: int = 120` - History buffer size
    - `PERF_GRAPH_WIDTH_RATIO: float = 0.2` - Graph width (20% of viewport)
    - `PERF_GRAPH_HEIGHT: int = 100` - Top graph height
    - `BOTTOM_GRAPH_BAR_HEIGHT: int = 480` - Bottom bar total height
    - `BOTTOM_GRAPH_BAR_MARGIN: int = 20` - Bottom margin
    - `GRAPH_INNER_HEIGHT: int = 140` - Individual bottom graph height
    - `PERF_LABEL_FONT_SIZE: int = 18` - Font size for metric labels
    - `PERF_REFRESH_THRESHOLD: float = 10.0` - Threshold for color-coding refresh time
    - `OVERLAY_MIN_WIDTH: int = 450` - Minimum overlay width
    - `SPACING_SMALL: int = 10` - Spacing constant
    - `SPACING_MEDIUM: int = 20` - Spacing constant

- **Theme Integration:**
  - Theme file: `res://themes/bg3_theme.tres`
  - Used for panel styling (`perf_overlay` StyleBox)
  - Applied to `PerfPanel` and `BottomGraphBar`

- **MythosLogger:**
  - Used extensively for debug logging throughout the performance monitor
  - Rate-limited via `can_log()` method (max 15 logs/second)

- **ConfigFile:**
  - Saves/loads monitor mode and category to `user://settings.cfg`
  - Keys: `debug/perf_monitor_mode` and `debug/perf_monitor_category`

---

### 8. External Integrations

**Document connections to other systems:**

- **PerformanceMonitorSingleton:**
  - Autoload singleton that instantiates PerformanceMonitor scene
  - Provides global access via `PerformanceMonitorSingleton` autoload
  - Exposes methods: `set_refresh_time()`, `queue_diagnostic()`, `push_metric_from_thread()`, `can_log()`

- **MapRenderer Integration:**
  - Calls `PerformanceMonitorSingleton.set_refresh_time(time_ms)` to update refresh graph
  - Timing measured around `MapRenderer.refresh()` calls

- **WorldGenerator Integration:**
  - `_update_thread_metrics()` searches scene tree for WorldGenerator
  - Calls `is_generating()` and `get_thread_metrics()` if available
  - Thread metrics are summed/averaged and fed to `bottom_thread_graph`

- **Logger Integration:**
  - Logger calls `PerformanceMonitorSingleton.can_log()` for rate limiting
  - Logger calls `PerformanceMonitorSingleton.queue_diagnostic()` for thread-safe log updates

- **Input System:**
  - F3 key toggles between modes (OFF → SIMPLE → DETAILED → OFF)
  - Category filter key (perf_toggle_category action) cycles metric categories
  - Export key (perf_export_data action) exports current snapshot to CSV

---

### 9. Export Functionality

**Document the snapshot export feature:**

- **Export Method:** `export_snapshot()`
- **Output Format:** CSV file
- **Output Location:** `user://perf_exports/snapshot_{timestamp}.csv`
- **Data Exported:**
  - timestamp (Unix time)
  - fps
  - process_ms
  - physics_ms
  - memory_bytes
  - objects
  - nodes
  - draw_calls (if frame_count >= 3)
  - primitives (if frame_count >= 3)
  - objects_drawn (if frame_count >= 3)
  - vram_bytes (if frame_count >= 3)
  - texture_mem_bytes (if frame_count >= 3)

---

### 10. Code Examples & Pseudocode

**Provide code snippets illustrating key operations:**

#### Graph Value Addition Flow:
```gdscript
# In PerformanceMonitor._process() when DETAILED mode:
var fps: float = Engine.get_frames_per_second()
fps_graph.add_value(fps)  # Adds to top-right FPS graph
bottom_fps_graph.add_value(fps)  # Adds to bottom FPS graph

var process_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
process_graph.add_value(process_ms)
bottom_process_graph.add_value(process_ms)

refresh_graph.add_value(refresh_time_ms)
bottom_refresh_graph.add_value(refresh_time_ms)

if bottom_thread_graph:
    bottom_thread_graph.add_value(thread_compute_time_ms)
```

#### Graph Rendering Flow (from GraphControl._draw()):
```gdscript
func _draw() -> void:
    # 1. Draw background
    draw_rect(Rect2(Vector2.ZERO, size), bg_color)
    
    # 2. Determine scaling
    var max_val: float = max_value if max_value > 0.0 else _get_auto_max()
    var min_val: float = _get_auto_min()
    
    # 3. Draw grid lines
    for i in range(1, GRID_LINES):
        var y: float = (float(i) / GRID_LINES) * size.y
        draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)
    
    # 4. Build points from circular buffer
    var points: PackedVector2Array = PackedVector2Array()
    # ... (circular buffer indexing logic)
    
    # 5. Draw filled area
    draw_colored_polygon(filled_points, fill_color)
    
    # 6. Draw line graph
    draw_polyline(points, line_color, 2.0)
    
    # 7. Draw current value dot
    draw_circle(dot_pos, 4.0, line_color)
    
    # 8. Update labels
    # ... (min/max/stats label updates)
```

#### Circular Buffer Implementation:
```gdscript
func add_value(value: float) -> void:
    # Apply smoothing if enabled
    var final_value: float = value
    if smoothing_enabled:
        # ... smoothing calculation
    
    # Circular buffer: add or overwrite
    if history.size() < UIConstants.PERF_HISTORY_SIZE:
        history.append(final_value)
    else:
        if not history_full:
            history_full = true
        history[history_index] = final_value
        history_index = (history_index + 1) % UIConstants.PERF_HISTORY_SIZE
    
    queue_redraw()
```

---

## Output Format

Provide your analysis as a structured markdown document with the following sections:

1. **Executive Summary** - Brief overview of the graph implementation
2. **File Structure & Components** - Complete file listing with roles
3. **Data Collection** - Detailed breakdown of all metric sources
4. **Rendering System** - Complete documentation of GraphControl rendering
5. **State Management** - Data storage, circular buffers, statistics
6. **UI Integration** - Layout, positioning, sizing, labels
7. **Update Cycle** - Frame-by-frame flow and performance characteristics
8. **Dependencies** - All external files, constants, themes, systems
9. **External Integrations** - Connections to other game systems
10. **Code Examples** - Key code snippets illustrating implementation details

**Important:** Focus exclusively on documenting what exists. Do not include recommendations, improvements, or upgrade suggestions. This is a pure analysis and documentation task.
