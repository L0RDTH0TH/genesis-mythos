# Flame Graph Integration Audit

**Date:** 2025-01-26  
**Purpose:** Investigate current performance monitoring and logging systems to prepare for flame graph support  
**Status:** Investigation Complete - Ready for Implementation Planning

---

## Executive Summary

The codebase has a **sophisticated multi-layered performance monitoring system** with logging, real-time metrics collection, waterfall visualization, and CSV export capabilities. However, **stack trace collection and hierarchical profiling data required for flame graphs are currently absent**. The system is well-architected for extension, with clear integration points in `PerformanceMonitorSingleton`, `Logger`, and `PerformanceMonitor`.

**Key Findings:**
- ✅ Comprehensive logging system (`Logger.gd`) with per-system levels, file output, and thread-safe operations
- ✅ Real-time performance monitoring (`PerformanceMonitor.gd`) with waterfall view, graphs, and detailed metrics
- ✅ Performance logging (`PerformanceLogger.gd`) with CSV export and interval-based sampling
- ✅ Thread-safe metric collection infrastructure (`PerformanceMonitorSingleton.gd`) with ring buffers
- ❌ **No stack trace collection** - current profiling is flat (function-level timing only)
- ❌ **No hierarchical call stack tracking** - required for flame graph visualization
- ❌ **No function-level instrumentation hooks** - would need to be added for stack sampling

---

## 1. Relevant Files Identified

### 1.1 Core Logging System

**Location:** `res://core/singletons/Logger.gd`
- **Purpose:** Centralized logging system with per-system log levels, file output, and thread-safe operations
- **Key Features:**
  - Log levels: ERROR, WARN, INFO, DEBUG, VERBOSE
  - Per-system log level configuration
  - File logging with daily rotation (`user://logs/`)
  - Thread-safe via mutex and `DiagnosticDispatcher` integration
  - Signal-based UI integration (`log_entry_created`)

**Configuration:** `res://data/config/logging_config.json`
- JSON-based configuration for log levels, outputs, and performance logging settings
- Structure includes `levels_enabled`, `outputs`, `modules`, `file_logging`, and `performance_logging` sections

### 1.2 Performance Monitoring System

**Location:** `res://scripts/ui/overlays/PerformanceMonitor.gd`
- **Purpose:** Toggleable performance overlay (OFF/SIMPLE/DETAILED modes) with real-time metrics
- **Key Features:**
  - FPS, process time, physics time, memory, rendering metrics
  - Real-time graphs (FPS, process, refresh)
  - Waterfall view for frame-by-frame timeline visualization
  - Category filtering (All, Time, Memory, Rendering, Objects)
  - CSV snapshot export (`export_snapshot()`)
  - DiagnosticDispatcher infrastructure for thread-safe operations

**Scene:** `res://scenes/ui/overlays/PerformanceMonitor.tscn`

### 1.3 Performance Logging (CSV Export)

**Location:** `res://core/singletons/PerformanceLogger.gd`
- **Purpose:** Lightweight CSV-based performance logging with F9 toggle
- **Key Features:**
  - Interval-based logging (configurable via `log_interval_seconds`)
  - CSV export to `user://perf_logs/`
  - Metrics: Timestamp, Frame, FrameTimeMs, FPS, DrawCalls, Primitives, PhysicsMs, ThreadMs, MemoryMB, Scene, Notes
  - Thread time integration via `PerformanceMonitorSingleton.get_thread_time_ms()`

### 1.4 Performance Monitor Singleton

**Location:** `res://core/singletons/PerformanceMonitorSingleton.gd`
- **Purpose:** Global autoload singleton managing PerformanceMonitor instance and metric buffers
- **Key Features:**
  - Instantiates and manages `PerformanceMonitor` overlay globally
  - Ring buffers for refresh/thread/other process breakdowns
  - Frame-tagged metric synchronization for waterfall view
  - Thread-safe buffer operations (mutex-protected)
  - DiagnosticDispatcher API (`queue_diagnostic()`, `push_metric_from_thread()`, `can_log()`)

### 1.5 Hardware Profiler

**Location:** `res://core/utils/HardwareProfiler.gd`
- **Purpose:** Detects system capabilities and determines quality presets
- **Key Features:**
  - CPU count detection, GPU name (platform-specific), memory estimation
  - Quick benchmark (FastNoiseLite test)
  - Quality level determination (LOW/MEDIUM/HIGH)
  - Adaptive generation parameter adjustment

**Configuration:** `res://data/config/hardware_adaptation.json`

### 1.6 Visualization Components

**Location:** `res://scripts/ui/overlays/GraphControl.gd`
- **Purpose:** Reusable line graph control with history buffer
- **Features:** Circular buffer, auto-scaling, smoothing, min/max/avg stats

**Location:** `res://scripts/ui/overlays/WaterfallControl.gd`
- **Purpose:** Timeline waterfall view for frame-by-frame performance visualization
- **Features:** 8 lanes (Frame Time, Main Process, Physics, Refresh, Thread, Other, Idle, Draw Calls), tooltip interaction, frame metadata tracking

### 1.7 UI Constants

**Location:** `res://scripts/ui/UIConstants.gd`
- **Purpose:** Semantic UI sizing constants for responsive layouts
- **Performance-Related Constants:**
  - `PERF_HISTORY_SIZE: 120` (~2 seconds at 60 FPS)
  - `WATERFALL_LANE_HEIGHT: 60`
  - `WATERFALL_BUFFER_MAX: 10`
  - `PERF_REFRESH_THRESHOLD: 10.0` (ms)

### 1.8 Additional Profiling Code

**Scattered Profiling Instrumentation:**
- `ui/world_builder/WorldBuilderUI.gd` - Per-frame timing, FPS sampling
- `ui/world_builder/MapMakerModule.gd` - Process/input timing instrumentation
- `core/world_generation/MapRenderer.gd` - Refresh timing profiling

**Note:** These use basic `Time.get_ticks_usec()` timing, not stack traces.

---

## 2. Logging System Examination

### 2.1 Logger.gd Architecture

**Class Structure:**
```gdscript
extends Node
enum LogLevel { ERROR, WARN, INFO, DEBUG, VERBOSE }
var config: Dictionary
var system_levels: Dictionary
var global_default_level: LogLevel
var log_to_console: bool
var log_to_file: bool
var log_dir: String
var log_file_prefix: String
```

**Key Functions:**
- `log_entry(system: String, level: LogLevel, message: String, data: Variant)` - Main logging method
- `error()`, `warn()`, `info()`, `debug()`, `verbose()` - Convenience methods
- `_load_config()` - Loads from `res://config/logging_config.json` (note: path discrepancy - code uses `res://config/` but file is at `res://data/config/`)
- `_setup_file_logging()` - Creates `user://logs/` directory, daily rotation
- `_format_message()` - Formats with timestamp, system, level, optional JSON data

**Thread Safety:**
- Uses `log_mutex` for thread-safe operations
- Integrates with `PerformanceMonitorSingleton.can_log()` for rate limiting
- Uses `DiagnosticDispatcher` queue for main-thread execution
- Signal emission via `call_deferred()` for thread safety

**Integration Points:**
- Signal: `log_entry_created(level, system, message, data)` - For UI integration
- Rate limiting: `PerformanceMonitorSingleton.can_log()` (MAX_LOGS_PER_SECOND = 15)

### 2.2 logging_config.json Structure

```json
{
  "levels_enabled": {
    "DEBUG": true,
    "INFO": true,
    "WARNING": true,
    "ERROR": true
  },
  "outputs": ["console", "file"],
  "modules": {
    "combat": "DEBUG",
    "dialogue": "INFO",
    "inventory": "INFO",
    "quest": "INFO",
    "character_creation": "DEBUG"
  },
  "file_logging": {
    "enabled": true,
    "daily_rotation": true,
    "max_file_size_mb": 10
  },
  "performance_logging": {
    "enabled": true,
    "log_interval_seconds": 0.1,
    "include_physics_ms": true,
    "include_draw_calls": true,
    "include_primitives": true,
    "include_nodes": true,
    "include_memory": true
  }
}
```

**Note:** Configuration path discrepancy - `Logger.gd` loads from `res://config/logging_config.json` but file exists at `res://data/config/logging_config.json`. This should be fixed.

---

## 3. Performance Monitoring Examination

### 3.1 PerformanceMonitor.gd Architecture

**Class Structure:**
```gdscript
class_name PerformanceMonitor
extends CanvasLayer
enum Mode { OFF, SIMPLE, DETAILED }
var current_mode: Mode
var refresh_time_ms: float
var thread_compute_time_ms: float
var system_status: String
```

**Data Collection:**
- **Engine Metrics:** `Engine.get_frames_per_second()`, `Performance.get_monitor()` (TIME_PROCESS, TIME_PHYSICS_PROCESS, MEMORY_STATIC, OBJECT_COUNT, etc.)
- **RenderingServer Metrics:** `RenderingServer.get_rendering_info()` (DRAW_CALLS, PRIMITIVES, OBJECTS_IN_FRAME, VRAM, TEXTURE_MEM)
- **Custom Timing:** `refresh_time_ms` (from MapRenderer), `thread_compute_time_ms` (from WorldGenerator)
- **Update Frequency:** Every frame in `_process()` when DETAILED mode active

**Visualization:**
- **Top-Right Panel:** FPS label, metric labels (filtered by category), small graphs (FPS, process, refresh)
- **Bottom Bar:** Waterfall view (replaces old bottom graphs) showing 8 lanes of frame-by-frame data
- **Graphs:** `GraphControl` instances with circular buffers (`PERF_HISTORY_SIZE = 120`)

**DiagnosticDispatcher Infrastructure:**
- `_diagnostic_queue: Array[Callable]` - Queue for thread-safe diagnostic operations
- `_metric_ring_buffer: Array[Dictionary]` - Thread-pushed metrics
- `queue_diagnostic(callable)` - Public API for queuing main-thread operations
- `push_metric_from_thread(metric)` - Public API for thread metric collection
- `can_log()` - Rate limiting (MAX_LOGS_PER_SECOND = 15)

### 3.2 PerformanceMonitorSingleton.gd Architecture

**Ring Buffers:**
- `_refresh_breakdown_buffer: Array[Dictionary]` - Refresh timing breakdowns with frame_id
- `_thread_breakdown_buffer: Array[Dictionary]` - Thread compute breakdowns with frame_id
- `_other_process_buffer: Array[Dictionary]` - Other process timing with frame_id
- All buffers are mutex-protected and frame-tagged for waterfall view synchronization

**Key Functions:**
- `push_refresh_breakdown(breakdown: Dictionary, frame_id: int)` - Push refresh metrics
- `push_thread_breakdown(breakdown: Dictionary, frame_id: int)` - Push thread metrics
- `consume_refresh_for_frame(frame_id: int)` - Consume refresh data (removes from buffer)
- `peek_thread_for_frame(frame_id: int)` - Peek thread data (non-destructive)
- `set_thread_time_ms(time_ms: float)` / `get_thread_time_ms()` - Direct thread time storage (Phase 2)

**Buffer Management:**
- Maximum size: `UIConstants.WATERFALL_BUFFER_MAX = 10`
- Circular buffer behavior (oldest entries removed when full)
- Frame ID matching for waterfall view synchronization

### 3.3 PerformanceLogger.gd Architecture

**CSV Export Format:**
```
Timestamp, Frame, FrameTimeMs, FPS, DrawCalls, Primitives, SmallObjects, LandmassNodes, PhysicsMs, ThreadMs, MemoryMB, Scene, Notes
```

**Collection Method:**
- Interval-based sampling (`log_interval_seconds` from config, default 0.1s)
- Collects metrics from `Performance` singleton, `RenderingServer`, and `PerformanceMonitorSingleton`
- Thread time via `PerformanceMonitorSingleton.get_thread_time_ms()` (with fallback to breakdown buffer)

**File Output:**
- Location: `user://perf_logs/world_builder_perf_{timestamp}.csv`
- Toggle: F9 hotkey (via `toggle_perf_logger` action)
- Signal: `logging_state_changed(is_enabled: bool)` for UI integration

### 3.4 WaterfallControl.gd Architecture

**Data Storage:**
- Parallel `PackedFloat32Array` / `PackedInt32Array` for primaries (memory-efficient)
- `Array[Dictionary]` for sparse sub-metrics (only when available)
- `PackedInt32Array` for frame IDs and timestamps
- Circular buffer with `HISTORY_SIZE = UIConstants.PERF_HISTORY_SIZE = 120`

**Lanes:**
1. Frame Time (gray)
2. Main Process (yellow/orange)
3. Physics Process (cyan)
4. Map Refresh (red)
5. Thread Compute (blue)
6. Other Process (green)
7. Idle/GPU Wait (light gray)
8. Draw Calls (purple)

**Visualization:**
- Horizontal bars per frame (last 60 frames visible)
- Color intensity based on value (green → yellow → red gradient for time lanes)
- Tooltip on hover showing frame details
- Grid lines every 30 frames, reference lines at 16.67ms (green) and 33.33ms (orange)

**Note:** Waterfall view v4 specification mentions "Flame evolution: Aggregate history for hotspots in separate mode" deferred to v5, indicating planned hierarchy support.

### 3.5 Current Profiling Limitations

**No Stack Trace Collection:**
- All timing is flat (function-level only)
- No call stack tracking
- No hierarchical function call data

**No Function-Level Instrumentation:**
- Profiling uses manual `Time.get_ticks_usec()` timing
- No automatic function entry/exit hooks
- No decorator/annotation system for profiling

**No Flame Graph Data Structure:**
- Current breakdowns are flat dictionaries (e.g., `{"total_ms": 10.5, "culling_ms": 2.1, "mesh_gen_ms": 5.2}`)
- No parent-child relationship tracking
- No call stack depth information

---

## 4. Integration Points for Flame Graphs

### 4.1 Recommended Architecture

**New Singleton: `FlameGraphProfiler.gd`**
- **Location:** `res://core/singletons/FlameGraphProfiler.gd`
- **Purpose:** Collect stack traces and hierarchical profiling data
- **Integration:** Extends existing `PerformanceMonitorSingleton` infrastructure

**Key Components:**

1. **Stack Trace Collection:**
   - Use GDScript's `get_stack()` for call stack capture
   - Sample-based profiling (periodic stack sampling, e.g., every 10ms)
   - Or instrumentation-based (function entry/exit hooks)

2. **Hierarchical Data Structure:**
   ```gdscript
   {
     "function": "MapRenderer.refresh()",
     "total_time_ms": 12.5,
     "self_time_ms": 2.1,  # Time in this function only
     "children": [
       {
         "function": "MapRenderer._do_actual_refresh()",
         "total_time_ms": 10.4,
         "self_time_ms": 5.2,
         "children": [...]
       }
     ],
     "call_count": 1,
     "frame_id": 1234
   }
   ```

3. **Data Export:**
   - JSON format compatible with flame graph tools (e.g., `perf script`, `speedscope`, `flamegraph.pl`)
   - Or custom GDScript-based flame graph renderer

### 4.2 Integration Points

**Option A: Extend PerformanceMonitorSingleton**
- Add `push_flame_data(stack_trace: Array, time_ms: float, frame_id: int)` method
- Store in new ring buffer: `_flame_data_buffer: Array[Dictionary]`
- Integrate with existing waterfall view (add new lane or separate mode)

**Option B: New FlameGraphProfiler Singleton**
- Independent singleton (like `Logger`, `PerformanceLogger`)
- Uses `PerformanceMonitorSingleton` for rate limiting and thread safety
- Exports data to `user://flame_graphs/` directory
- Can be toggled on/off via config or hotkey

**Option C: Extend Logger.gd**
- Add stack trace collection to existing logging infrastructure
- Use `get_stack()` in `log_entry()` when flame graph mode enabled
- Export stack traces with timing data

### 4.3 Data-Driven Configuration

**New Config: `res://data/config/flame_graph_config.json`**
```json
{
  "enabled": false,
  "sampling_mode": "instrumentation",  // "sampling" or "instrumentation"
  "sampling_interval_ms": 10.0,
  "max_stack_depth": 20,
  "export_format": "json",  // "json", "perf", "speedscope"
  "export_directory": "user://flame_graphs/",
  "auto_export_interval_seconds": 60.0,
  "systems": {
    "world_generation": true,
    "rendering": true,
    "entity_sim": false
  }
}
```

### 4.4 Implementation Approaches

**Approach 1: Sampling-Based (Lower Overhead)**
- Periodic stack sampling (e.g., every 10ms) using `get_stack()`
- Aggregate samples into flame graph data structure
- Lower overhead, but may miss short functions

**Approach 2: Instrumentation-Based (Higher Accuracy)**
- Function entry/exit hooks (via decorator or manual instrumentation)
- Track call stack depth and timing for each function
- Higher overhead, but complete call hierarchy

**Approach 3: Hybrid**
- Sampling for general profiling
- Instrumentation for specific hot paths (configurable per system)

### 4.5 Visualization Integration

**Option A: Extend WaterfallControl**
- Add new "Flame Graph" mode to waterfall view
- Render hierarchical bars (nested rectangles) instead of flat lanes
- Use existing tooltip system for function details

**Option B: New FlameGraphControl**
- Separate control similar to `WaterfallControl`
- Specialized rendering for flame graph visualization
- Can be toggled in PerformanceMonitor DETAILED mode

**Option C: External Tool Integration**
- Export data in standard format (JSON, perf script)
- Use external tools (speedscope, flamegraph.pl) for visualization
- Focus on data collection, not rendering

---

## 5. Gaps and Recommendations

### 5.1 Critical Gaps

1. **No Stack Trace Collection**
   - **Impact:** Cannot build flame graphs without call stack data
   - **Solution:** Implement `get_stack()`-based sampling or function instrumentation

2. **No Hierarchical Data Structure**
   - **Impact:** Current breakdowns are flat, no parent-child relationships
   - **Solution:** Design hierarchical dictionary structure for function call trees

3. **No Function-Level Instrumentation Hooks**
   - **Impact:** Manual timing only, no automatic profiling
   - **Solution:** Add decorator system or function entry/exit hooks

4. **Configuration Path Discrepancy**
   - **Impact:** `Logger.gd` loads from `res://config/logging_config.json` but file is at `res://data/config/logging_config.json`
   - **Solution:** Fix path in `Logger._load_config()` to use `res://data/config/logging_config.json`

### 5.2 Recommended Next Steps

**Phase 1: Foundation (Low Risk)**
1. Fix `Logger.gd` config path discrepancy
2. Create `res://data/config/flame_graph_config.json` with default settings
3. Create `FlameGraphProfiler.gd` singleton stub with config loading
4. Add flame graph toggle to `logging_config.json` or new config file

**Phase 2: Stack Trace Collection (Medium Risk)**
1. Implement sampling-based stack trace collection using `get_stack()`
2. Add ring buffer to `PerformanceMonitorSingleton` for flame data
3. Integrate with existing rate limiting (`can_log()`)
4. Export stack traces to JSON format

**Phase 3: Hierarchical Data Structure (Medium Risk)**
1. Design hierarchical dictionary structure for call trees
2. Implement aggregation logic (merge samples into tree)
3. Add frame_id tagging for synchronization
4. Export to flame graph-compatible format (JSON, perf script)

**Phase 4: Visualization (High Risk - Optional)**
1. Extend `WaterfallControl` with flame graph mode OR
2. Create new `FlameGraphControl` for hierarchical rendering
3. Add tooltip integration for function details
4. Test with real-world scenarios (world generation, rendering)

**Phase 5: Integration & Polish (Low Risk)**
1. Add hotkey toggle (e.g., F10 for flame graph mode)
2. Add CSV/JSON export buttons to PerformanceMonitor UI
3. Document flame graph usage in project docs
4. Performance testing (ensure <5% overhead when enabled)

### 5.3 Code Style Compliance

**All new code must follow project rules:**
- Exact script header format (see rule 3)
- Typed GDScript (`: Node`, `: Dictionary`, etc.)
- `@onready var` only (never old `onready var`)
- No magic numbers (use `UIConstants` or config)
- Data-driven (JSON configs in `res://data/config/`)
- Theme integration (`res://themes/bg3_theme.tres`)
- One class per file, file name == class name

**File Locations:**
- Singleton: `res://core/singletons/FlameGraphProfiler.gd`
- Config: `res://data/config/flame_graph_config.json`
- UI Control (if new): `res://scripts/ui/overlays/FlameGraphControl.gd`
- Scene (if new): `res://scenes/ui/overlays/FlameGraphControl.tscn`

### 5.4 Performance Considerations

**Overhead Targets:**
- Sampling mode: <2% CPU overhead when enabled
- Instrumentation mode: <5% CPU overhead when enabled
- Memory: <10MB for flame data buffers (configurable)

**Optimization Strategies:**
- Use `PackedArray` types for numeric data (like `WaterfallControl`)
- Limit stack depth (configurable, default 20)
- Rate limiting via existing `can_log()` infrastructure
- Conditional compilation (only collect when flame graph mode enabled)

### 5.5 Testing Strategy

**Unit Tests (GUT):**
- Stack trace collection accuracy
- Hierarchical data structure aggregation
- Buffer management (overflow, circular behavior)
- Export format validation

**Integration Tests:**
- Flame graph data collection during world generation
- Thread safety (flame data from background threads)
- Performance overhead measurement
- Export file format compatibility (speedscope, flamegraph.pl)

**Manual Testing:**
- Toggle flame graph mode on/off
- Export and visualize in external tools
- Compare flame graph data with waterfall view
- Verify frame synchronization

---

## 6. Summary

The codebase has a **robust performance monitoring foundation** with logging, real-time metrics, waterfall visualization, and CSV export. The architecture is well-suited for flame graph integration, with clear extension points in `PerformanceMonitorSingleton`, `Logger`, and `PerformanceMonitor`.

**Key Strengths:**
- Thread-safe infrastructure (mutex, DiagnosticDispatcher)
- Data-driven configuration (JSON-based)
- Existing visualization components (GraphControl, WaterfallControl)
- Rate limiting and buffer management patterns established

**Key Gaps:**
- No stack trace collection
- No hierarchical call stack tracking
- No function-level instrumentation hooks

**Recommended Approach:**
1. Create `FlameGraphProfiler.gd` singleton extending existing infrastructure
2. Implement sampling-based stack trace collection using `get_stack()`
3. Design hierarchical data structure for call trees
4. Export to standard formats (JSON, perf script) for external tool visualization
5. Optional: Extend `WaterfallControl` with flame graph mode for in-engine visualization

**Next Action:** Begin Phase 1 implementation (foundation and config) following project rules and code style guidelines.

---

**End of Audit**

