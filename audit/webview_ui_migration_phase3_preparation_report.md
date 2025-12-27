# WebView UI Migration Phase 3 Preparation Report

**Date:** 2025-12-27  
**Phase:** Phase 3 Preparation (PerformanceMonitor Overlay Migration Feasibility)  
**Status:** Investigation Complete - Ready for Decision

---

## Executive Summary

This report investigates the feasibility of migrating the **PerformanceMonitor overlay** to a WebView-based implementation using **Chart.js** for graph rendering. The PerformanceMonitor is a complex real-time performance debugging tool with multiple graph types (FPS, frame time, draw calls, waterfall view, flame graph) that updates every frame.

**Key Findings:**
- **PerformanceMonitor** is highly optimized with custom drawing and ring buffers
- Updates **every frame** with low-level RenderingServer API calls
- Multiple graph types: line charts, waterfall view, flame graph
- Current implementation uses native `_draw()` with excellent performance
- **Chart.js** (~70-80KB gzipped) could handle line/bar charts well
- **Flame graph** would need d3-flame-graph (~40-60KB) or custom canvas
- **Real-time IPC push every frame** may be a significant bottleneck
- Current web_ui bundle is ~45KB (Phase 1+2), adding Chart.js would be ~120KB total

**Recommendation:** **Defer PerformanceMonitor migration** - keep native implementation. Real-time frame-by-frame data push via IPC is likely to introduce latency and overhead that defeats the purpose of a performance monitor. If migration is desired, consider a **hybrid approach** with throttled updates (e.g., every 10 frames) and accept reduced accuracy.

---

## 1. Current PerformanceMonitor Implementation

### 1.1 Scene Structure

**Path:** `res://scenes/ui/overlays/PerformanceMonitor.tscn`

**Root Node:** `Control` (named "PerformanceMonitor")

**Key Child Nodes:**
- `GraphControl` nodes (multiple) - Line charts for FPS, frame time, draw calls, physics time
- `WaterfallControl` - Stacked floating bar chart for frame breakdown
- `FlameGraphControl` - Flame graph visualization for function call profiling
- `HBoxContainer` / `VBoxContainer` - Layout containers
- `Label` nodes - Metric displays (FPS, frame time, etc.)

**Attached Script:** `res://scripts/ui/overlays/PerformanceMonitor.gd`

### 1.2 Script Details

**Class:** `PerformanceMonitor` (extends `Control`)

**Key Features:**
- **Update Frequency:** Every frame (via `_process(delta)`)
- **Process Mode:** `PROCESS_MODE_ALWAYS` (always active when visible)
- **Custom Drawing:** Uses `_draw()` methods extensively for graph rendering
- **Ring Buffers:** Uses fixed-size arrays (PERF_HISTORY_SIZE = 120) for metric history
- **Data Sources:** 
  - `RenderingServer.get_frame_time()` - Frame time in milliseconds
  - `RenderingServer.get_frame_delta_time()` - Delta time
  - `RenderingServer.get_rendering_info()` - Draw calls, object count, etc.
  - Direct performance counters from Godot engine

**Update Pattern:**
```gdscript
func _process(delta: float) -> void:
    # Collect metrics every frame
    var frame_time = RenderingServer.get_frame_time()
    var draw_calls = RenderingServer.get_rendering_info(RenderingServer.INFO_TOTAL_DRAW_CALLS_IN_FRAME)
    # ... update ring buffers ...
    # Trigger redraw
    queue_redraw()
```

### 1.3 Graph Control Implementation

**Path:** `res://scripts/ui/overlays/GraphControl.gd`

**Class:** `GraphControl` (extends `Control`)

**Custom Drawing:**
- Uses `_draw()` to render line graphs directly on Canvas
- Draws grid lines, axes, labels, and data series
- Optimized with minimal allocations (reuses Vector2 arrays)
- Supports multiple metrics (FPS, frame time, draw calls, physics time)

**Data Structure:**
- Ring buffer: `Array[float]` of size PERF_HISTORY_SIZE (120 frames ≈ 2 seconds at 60 FPS)
- Each graph maintains its own ring buffer
- Values normalized to 0-1 range for rendering

### 1.4 Waterfall Control Implementation

**Path:** `res://scripts/ui/overlays/WaterfallControl.gd`

**Class:** `WaterfallControl` (extends `Control`)

**Custom Drawing:**
- Stacked floating bar chart showing frame breakdown
- Each frame is a vertical bar with colored segments (CPU, GPU, physics, etc.)
- Uses `_draw()` with custom rectangle drawing
- Horizontal scrolling to show frame history

**Complexity:** Medium-High (custom layout logic for stacked bars)

### 1.5 Flame Graph Control Implementation

**Path:** `res://scripts/ui/overlays/FlameGraphControl.gd`

**Class:** `FlameGraphControl` (extends `Control`)

**Custom Drawing:**
- Hierarchical flame graph for function call profiling
- Recursive rectangle drawing based on call stack depth
- Complex layout algorithm (width proportional to time, height for stack depth)
- Interactive hover tooltips (requires mouse position tracking)

**Complexity:** High (recursive layout + interactive hover)

---

## 2. Graph Types and Data Flow

### 2.1 Graph Types

1. **FPS Graph** (Line Chart)
   - Data: Frames per second (inverse of frame time)
   - Update: Every frame
   - Y-axis: 0-120 FPS (typically)

2. **Frame Time Graph** (Line Chart)
   - Data: Milliseconds per frame
   - Update: Every frame
   - Y-axis: 0-33.33ms (target 30 FPS) or 0-16.67ms (target 60 FPS)

3. **Draw Calls Graph** (Line Chart)
   - Data: Number of draw calls per frame
   - Update: Every frame
   - Y-axis: 0-MAX_DRAW_CALLS (configurable, default 2000)

4. **Physics Time Graph** (Line Chart)
   - Data: Physics step time in milliseconds
   - Update: Every frame
   - Y-axis: 0-16.67ms (target 60 FPS)

5. **Waterfall View** (Stacked Floating Bar Chart)
   - Data: Frame breakdown (CPU, GPU, physics, rendering)
   - Update: Every frame
   - Each frame is a vertical bar with colored segments

6. **Flame Graph** (Hierarchical Rectangle Chart)
   - Data: Function call stack with timing
   - Update: On-demand (when profiling enabled)
   - Requires profiler integration (not always active)

### 2.2 Data Collection

**RenderingServer API Calls:**
```gdscript
# Frame timing
var frame_time = RenderingServer.get_frame_time()
var delta_time = RenderingServer.get_frame_delta_time()

# Rendering metrics
var draw_calls = RenderingServer.get_rendering_info(RenderingServer.INFO_TOTAL_DRAW_CALLS_IN_FRAME)
var object_count = RenderingServer.get_rendering_info(RenderingServer.INFO_OBJECTS_IN_FRAME)
var primitives = RenderingServer.get_rendering_info(RenderingServer.INFO_PRIMITIVES_IN_FRAME)
```

**Data Structure:**
- Ring buffers: `Array[float]` with fixed size (PERF_HISTORY_SIZE = 120)
- Timestamps: Not stored (frames are sequential, index = frame offset)
- Normalization: Values normalized to 0-1 range for rendering

**Update Frequency:**
- **Every frame** when PerformanceMonitor is visible
- No throttling (real-time monitoring requires frame-accurate data)

---

## 3. Existing WebView Performance Baseline

### 3.1 Phase 1/2 Performance Observations

**From Phase 1 (MainMenuWeb):**
- Simple static UI with 2 buttons
- No performance impact observed (static content)
- WebView initialization: ~100-200ms on first load

**From Phase 2 (WorldBuilderWeb):**
- Alpine.js reactive wizard with parameter tree
- No significant performance impact observed
- IPC communication: <1ms per message (occasional user interactions)

**Current web_ui Bundle Size:**
- `web_ui/shared/alpine.min.js`: ~45KB
- `web_ui/shared/bridge.js`: ~2KB
- `web_ui/main_menu/`: ~10KB (HTML/CSS/JS)
- `web_ui/world_builder/`: ~15KB (HTML/CSS/JS)
- **Total:** ~72KB uncompressed, ~45KB gzipped (estimated)

### 3.2 WebView Memory/CPU Overhead

**Observed Overhead:**
- WebView process: ~50-100MB RAM (godot_wry/WRY engine)
- CPU: Negligible for static/interactive content
- IPC latency: <1ms for occasional messages

**Potential Issues for Real-Time Updates:**
- **IPC message serialization/deserialization:** JSON parsing overhead
- **JavaScript event loop:** Updates may queue if JS is busy
- **Canvas rendering:** Chart.js canvas operations may introduce jitter
- **Memory allocations:** Frequent data push could trigger GC pauses

### 3.3 Throttling/Sync Issues

**Current Implementation:** No throttling (updates every frame)

**WebView Migration Concerns:**
- **60 FPS = 16.67ms per frame**
- **IPC overhead:** ~1-2ms per message (estimated)
- **JSON serialization:** ~0.5-1ms for small arrays
- **Total overhead:** ~2-3ms per frame (18-20% of frame budget at 60 FPS)
- **Canvas rendering:** Chart.js update may add 1-5ms depending on complexity

**Risk:** Real-time frame-by-frame updates via IPC could introduce stuttering and make the performance monitor itself impact performance.

---

## 4. Chart.js Integration Readiness

### 4.1 Chart.js Status

**Current Status:** ❌ **Not Yet Added**

**Recommended URL:** `https://cdn.jsdelivr.net/npm/chart.js@4.4.4/dist/chart.umd.min.js`

**Version:** 4.4.4 (latest stable as of 2025-12-27)

### 4.2 Bundle Size Estimates

**Chart.js:**
- Full bundle (UMD): ~280KB minified, ~90KB gzipped
- Tree-shaken (with bundler): ~200KB minified, ~70KB gzipped (estimated)
- Core chart types (line, bar): ~150KB minified, ~60KB gzipped (estimated)

**d3-flame-graph (for flame graph):**
- Modular D3 dependency: ~40KB minified, ~15KB gzipped
- d3-flame-graph plugin: ~20KB minified, ~8KB gzipped
- **Total:** ~60KB minified, ~23KB gzipped

**Total Projected Bundle:**
- Current web_ui: ~45KB gzipped
- Chart.js (tree-shaken): ~70KB gzipped
- d3-flame-graph: ~23KB gzipped
- **Total:** ~138KB gzipped (within 200KB target, but close)

### 4.3 Canvas Rendering Compatibility

**Chart.js Rendering:**
- Uses HTML5 Canvas API
- Compatible with WebView (godot_wry supports canvas)
- Hardware-accelerated rendering (browser/WebView dependent)
- Update performance: ~1-5ms for line chart redraw (depends on data points)

**WebView Canvas Support:**
- ✅ Full HTML5 Canvas API support
- ✅ Hardware acceleration (when available)
- ✅ Performance: Comparable to native browser canvas

---

## 5. Specific Graph Migration Feasibility

### 5.1 Line/FPS Graphs → Chart.js Line Chart

**Feasibility:** ✅ **Easy**

**Chart.js Implementation:**
```javascript
// Chart.js line chart
new Chart(ctx, {
    type: 'line',
    data: {
        labels: Array(120).fill(''), // Frame indices
        datasets: [{
            label: 'FPS',
            data: fpsArray, // Ring buffer data
            borderColor: 'rgb(255, 215, 0)',
            tension: 0.1
        }]
    },
    options: {
        animation: false, // Disable animation for real-time updates
        responsive: true,
        scales: {
            y: { min: 0, max: 120 }
        }
    }
});
```

**Update Pattern:**
- Push new data point every frame via IPC
- Chart.js `update()` method: ~1-3ms per update
- **Total overhead:** ~2-4ms per frame (acceptable if throttled)

**Recommendation:** ✅ **Migrate** - Chart.js line charts are well-suited for real-time FPS/frame time graphs.

### 5.2 Waterfall View → Chart.js Stacked Floating Bar

**Feasibility:** ⚠️ **Moderate** (requires custom Chart.js configuration)

**Chart.js Implementation:**
- Chart.js doesn't have native "waterfall" chart type
- Would need custom bar chart with stacked segments
- Floating bars require base value calculation (complexity: medium)

**Alternative:** Custom canvas drawing in WebView (similar to current `_draw()` approach)

**Recommendation:** ⚠️ **Consider custom canvas** - Waterfall view may be easier to implement with native canvas API than forcing Chart.js.

### 5.3 Flame Graph → d3-flame-graph or Custom Canvas

**Feasibility:** ⚠️ **Complex** (requires d3-flame-graph or custom implementation)

**Option 1: d3-flame-graph**
- Mature library with good performance
- Bundle size: ~23KB gzipped
- Requires D3 dependency (~15KB gzipped)
- **Total:** ~38KB gzipped

**Option 2: Custom Canvas**
- Implement flame graph rendering in vanilla JavaScript
- Bundle size: ~5-10KB (custom code)
- Complexity: High (recursive layout algorithm)
- Maintenance: Higher (custom code vs. library)

**Recommendation:** ⚠️ **Use d3-flame-graph if migrating** - Custom implementation is too complex for Phase 3.

### 5.4 Real-Time Update Requirements

**Current:** Every frame (no throttling)

**WebView Migration Options:**

1. **Every Frame (Native Behavior)**
   - **Overhead:** ~2-4ms per frame (IPC + Chart.js update)
   - **Impact:** 12-24% of 16.67ms frame budget
   - **Risk:** High (performance monitor impacts performance)

2. **Throttled (Every N Frames)**
   - **Option A:** Every 5 frames (~12 updates/second)
   - **Option B:** Every 10 frames (~6 updates/second)
   - **Overhead:** Reduced proportionally
   - **Trade-off:** Reduced accuracy (acceptable for debugging)

3. **Adaptive Throttling**
   - Throttle based on frame rate (more updates at 60 FPS, fewer at 30 FPS)
   - Complexity: Medium

**Recommendation:** ⚠️ **Throttle to every 5-10 frames** - Real-time every-frame updates are too expensive via IPC.

---

## 6. Bundle Size Impact

### 6.1 Current Bundle Size

**Phase 1 + 2:**
- Alpine.js: ~45KB gzipped
- Bridge.js: ~2KB gzipped
- MainMenu: ~10KB gzipped
- WorldBuilder: ~15KB gzipped
- **Total:** ~72KB gzipped

### 6.2 Projected with Chart.js

**With Chart.js (tree-shaken, core charts only):**
- Chart.js: ~70KB gzipped
- **Total:** ~142KB gzipped

**With Chart.js + d3-flame-graph:**
- Chart.js: ~70KB gzipped
- d3-flame-graph: ~38KB gzipped
- **Total:** ~180KB gzipped

**With Chart.js + Custom Canvas (waterfall + flame):**
- Chart.js: ~70KB gzipped
- Custom canvas code: ~10KB gzipped
- **Total:** ~152KB gzipped

### 6.3 Comparison to 200KB Target

- **Chart.js only:** ✅ Within target (142KB < 200KB)
- **Chart.js + d3-flame-graph:** ✅ Within target (180KB < 200KB)
- **Chart.js + Custom canvas:** ✅ Within target (152KB < 200KB)

**Conclusion:** ✅ **Bundle size is acceptable** - All options are within 200KB target.

---

## 7. Performance Risks

### 7.1 Real-Time Data Push Every Frame

**Risk Level:** 🔴 **High**

**Concerns:**
- **IPC overhead:** ~1-2ms per message (JSON serialization/deserialization)
- **JavaScript event loop:** Updates may queue if JS is busy rendering
- **Canvas rendering:** Chart.js update: ~1-5ms depending on graph complexity
- **Total per-frame overhead:** ~2-7ms (12-42% of 16.67ms frame budget)

**Impact:** Performance monitor itself becomes a performance bottleneck, defeating its purpose.

**Mitigation:** Throttle updates (every 5-10 frames), accept reduced accuracy.

### 7.2 Canvas Rendering in WebView vs Native Custom Drawing

**Risk Level:** 🟡 **Medium**

**Native `_draw()` Advantages:**
- Direct GPU rendering (no JavaScript overhead)
- Minimal allocations (reuses buffers)
- Optimized for real-time updates
- Zero IPC overhead

**WebView Canvas Disadvantages:**
- JavaScript execution overhead
- Canvas API abstraction layer
- IPC serialization overhead
- Potential GC pauses

**Impact:** Canvas rendering in WebView is slower than native `_draw()`, but acceptable if throttled.

### 7.3 Memory Impact of Additional JS Libraries

**Risk Level:** 🟢 **Low**

**Memory Estimates:**
- Chart.js: ~5-10MB RAM (initialized charts)
- d3-flame-graph: ~2-5MB RAM
- WebView process: ~50-100MB RAM (existing)

**Impact:** Negligible compared to overall WebView footprint.

---

## 8. Recommended Approach

### 8.1 Option A: Full Migration with Chart.js + d3-flame-graph

**Pros:**
- ✅ Unified UI architecture (all overlays in WebView)
- ✅ Rich charting capabilities (Chart.js is mature and well-maintained)
- ✅ Consistent styling (easier to theme)
- ✅ Easier to extend (add new graphs via JavaScript)

**Cons:**
- ❌ Real-time frame-by-frame updates are expensive (IPC overhead)
- ❌ Reduced accuracy (must throttle to every 5-10 frames)
- ❌ Additional bundle size (~180KB total)
- ❌ Performance monitor impacts performance (ironic)

**Recommendation:** ❌ **Not Recommended** - IPC overhead makes real-time monitoring impractical.

### 8.2 Option B: Hybrid - Keep Flame Graph Native, Migrate Others

**Pros:**
- ✅ Flame graph (complex, infrequently updated) stays native (fast)
- ✅ Line charts (simple, frequently updated) migrate to Chart.js (easier to style)
- ✅ Reduced bundle size (~142KB vs 180KB)

**Cons:**
- ⚠️ Mixed architecture (native + WebView)
- ⚠️ Still has IPC overhead for line charts
- ⚠️ Throttling still required

**Recommendation:** ⚠️ **Consider if migration is required** - Better than full migration, but still has overhead.

### 8.3 Option C: Defer Flame Graph Entirely (Custom Canvas for Waterfall)

**Pros:**
- ✅ Line charts with Chart.js (easy, good styling)
- ✅ Custom canvas for waterfall (no library dependency)
- ✅ Smaller bundle size (~152KB)
- ✅ Skip flame graph complexity

**Cons:**
- ❌ Still has IPC overhead for line charts
- ❌ Custom canvas code requires maintenance
- ❌ Flame graph stays native (mixed architecture)

**Recommendation:** ⚠️ **Consider if migration is required** - Balanced approach, but IPC overhead remains.

### 8.4 Option D: Keep Entire PerformanceMonitor Native (Recommended)

**Pros:**
- ✅ **Zero IPC overhead** (native `_draw()` is optimal)
- ✅ **True real-time monitoring** (every frame, no throttling)
- ✅ **No bundle size increase** (no Chart.js/d3)
- ✅ **Performance monitor doesn't impact performance** (critical for debugging tool)

**Cons:**
- ⚠️ Mixed architecture (some UI in WebView, PerformanceMonitor native)
- ⚠️ Styling consistency (native Control nodes vs WebView theme)
- ⚠️ Future maintenance (native GDScript vs JavaScript)

**Recommendation:** ✅ **Recommended** - PerformanceMonitor should be as lightweight as possible. Real-time frame-by-frame updates via IPC are fundamentally incompatible with the tool's purpose.

---

## 9. Folder Readiness

### 9.1 Current Structure

**Status:** ❌ **Not Created**

**Planned Structure (if migration proceeds):**
```
res://web_ui/
├── shared/
│   ├── bridge.js
│   ├── alpine.min.js
│   └── chart.min.js (if added)
├── main_menu/
├── world_builder/
├── character_creation/
└── overlays/           # New folder
    └── performance/
        ├── index.html
        ├── performance.css
        └── performance.js
```

**Recommendation:** Create `web_ui/overlays/performance/` only if migration is approved.

---

## 10. Next Steps

### 10.1 Immediate Actions

1. **Decision Point:** Choose approach (recommendation: **Option D - Keep Native**)
2. **If migrating:**
   - Fetch Chart.js minified: `https://cdn.jsdelivr.net/npm/chart.js@4.4.4/dist/chart.umd.min.js`
   - Save to: `res://web_ui/shared/chart.min.js`
   - Create `web_ui/overlays/performance/` folder structure
   - Implement throttled update mechanism (every 5-10 frames)

### 10.2 If Keeping Native

- ✅ **No action required** - PerformanceMonitor remains as-is
- Focus Phase 3 on other UI elements (dialogs, HUD overlays, etc.)
- Consider migrating simpler overlays (tooltips, status bars) instead

### 10.3 Alternative Phase 3 Targets

If PerformanceMonitor migration is deferred, consider:

1. **Status Bar / HUD Overlays** (simple text/metrics, no real-time graphs)
2. **Dialog Windows** (modal dialogs, confirmations, settings)
3. **Tooltips** (hover tooltips, context-sensitive help)
4. **Inventory UI** (if applicable, item lists, grids)
5. **Character Sheet** (static/occasionally updated data)

**Recommendation:** Migrate **simpler overlays** that don't require real-time frame-by-frame updates.

---

## 11. Conclusion

The **PerformanceMonitor overlay** is a complex real-time debugging tool that updates every frame with low-level RenderingServer API calls. While **Chart.js** and **d3-flame-graph** could technically render the graphs in a WebView, the **fundamental limitation is IPC overhead** - pushing data every frame via IPC adds 2-7ms of overhead (12-42% of frame budget), making the performance monitor itself a performance bottleneck.

**Final Recommendation:** ✅ **Defer PerformanceMonitor migration** - keep native implementation for optimal real-time performance. Focus Phase 3 on simpler UI elements that don't require frame-by-frame updates.

---

**Report Generated:** 2025-12-27  
**Next Review:** After Phase 2 completion and testing

