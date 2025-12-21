# Performance System Threading Metrics Disconnect Audit

**Date:** 2025-01-26  
**Audit Type:** Performance Monitoring System Architecture  
**Status:** Critical Issues Identified  
**Priority:** High - Affects performance logging and waterfall view accuracy

---

## Executive Summary

The performance monitoring system has a **critical architectural disconnect** between thread metric collection and metric consumption. Background threads are executing correctly and recording metrics, but these metrics are not being aggregated into breakdowns that feed the waterfall view and PerformanceLogger CSV exports.

**Key Findings:**
- ✅ Threads are running correctly (`WorldGenerator._threaded_generate()` executes in background)
- ✅ Individual phase metrics are being recorded (`_record_metric()` called for each phase)
- ❌ Metrics are never aggregated into breakdowns (`push_thread_breakdown()` never called)
- ❌ PerformanceLogger hardcodes `thread_ms = 0.0` (placeholder, never populated)
- ❌ Waterfall view always falls back to `thread_compute_time_ms` because breakdown buffer is empty
- ⚠️ Refresh breakdowns may also have similar issues (MapRenderer only calls `set_refresh_time()`, not `push_refresh_breakdown()`)

**Impact:**
- All CSV logs show `ThreadMs = 0.000` regardless of actual thread activity
- Waterfall view thread metrics are unreliable (uses fallback values when available)
- Performance analysis cannot distinguish thread compute time from main thread time

---

## 1. System Architecture Analysis

### 1.1 Dual Metric Buffer Systems

The codebase implements **two separate metric collection systems** that operate independently:

#### System A: Ring Buffer (Graph Display)
- **Purpose:** Real-time graph updates for individual phase metrics
- **Entry Point:** `WorldGenerator._record_metric()` → `PerformanceMonitorSingleton.push_metric_from_thread()`
- **Storage:** `PerformanceMonitor._metric_ring_buffer` (Array[Dictionary])
- **Consumption:** `PerformanceMonitor._process()` drains buffer and feeds `bottom_thread_graph`
- **Status:** ✅ **WORKING** - Metrics flow correctly to graph display

#### System B: Breakdown Buffer (Waterfall View + CSV Logging)
- **Purpose:** Frame-tagged aggregated breakdowns for waterfall view synchronization
- **Entry Point:** `PerformanceMonitorSingleton.push_thread_breakdown()` (should be called)
- **Storage:** `PerformanceMonitorSingleton._thread_breakdown_buffer` (Array[Dictionary])
- **Consumption:** `PerformanceMonitor._match_thread_to_frame()` → `consume_thread_for_frame()`
- **Status:** ❌ **NOT WORKING** - Buffer is never populated (function never called)

### 1.2 Data Flow Diagram

```
[Background Thread]
WorldGenerator._threaded_generate()
  ├─ Phase 1: configure_noise → _record_metric("configure_noise", time_ms)
  ├─ Phase 2: generate_heightmap → _record_metric("generate_heightmap", time_ms)
  ├─ Phase 3: post_processing → _record_metric("post_processing", time_ms)
  └─ Total → _record_metric("total_generation", time_ms)

_record_metric(phase, time_ms)
  ├─ ✅ push_metric_from_thread() → Ring Buffer → Graph Display (WORKING)
  └─ ❌ push_thread_breakdown() → Breakdown Buffer → Waterfall/CSV (MISSING)

[Main Thread]
PerformanceMonitor._process()
  ├─ ✅ Drain ring buffer → bottom_thread_graph.add_value() (WORKING)
  └─ ❌ consume_thread_for_frame() → Always returns {} (EMPTY BUFFER)

PerformanceLogger.log_current_frame()
  └─ ❌ thread_ms = 0.0 (HARDCODED PLACEHOLDER)
```

---

## 2. Detailed Findings

### 2.1 WorldGenerator Metric Recording

**File:** `res://core/world_generation/WorldGenerator.gd`

```190:205:core/world_generation/WorldGenerator.gd
func _record_metric(phase: String, time_ms: float) -> void:
	"""Record thread metric via DiagnosticDispatcher (thread-safe)."""
	# Push metric to DiagnosticDispatcher ring buffer (thread-safe)
	PerformanceMonitorSingleton.push_metric_from_thread({
		"phase": phase,
		"time_ms": time_ms,
		"timestamp": Time.get_ticks_msec()
	})
	
	# Also keep local queue for backward compatibility with get_thread_metrics()
	metrics_mutex.lock()
	thread_metrics_queue.append({"phase": phase, "time_ms": time_ms})
	# Keep queue size reasonable (last 100 entries)
	if thread_metrics_queue.size() > 100:
		thread_metrics_queue.pop_front()
	metrics_mutex.unlock()
```

**Issue:** Only pushes to ring buffer. Never aggregates metrics or calls `push_thread_breakdown()`.

**Missing Code:** After generation completes, should aggregate all phase metrics into a breakdown dictionary and push it:

```gdscript
# MISSING: Should be called after _threaded_generate() completes
func _aggregate_and_push_breakdown(phases: Array[Dictionary], total_time: float) -> void:
	var breakdown: Dictionary = {
		"total_ms": total_time,
		"configure_noise_ms": phases[0].time_ms,
		"generate_heightmap_ms": phases[1].time_ms,
		"post_processing_ms": phases[2].time_ms
	}
	var frame_id: int = Engine.get_process_frames()  # Use current frame when aggregation happens
	PerformanceMonitorSingleton.push_thread_breakdown(breakdown, frame_id)
```

### 2.2 PerformanceMonitor Thread Matching

**File:** `res://scripts/ui/overlays/PerformanceMonitor.gd`

```765:772:scripts/ui/overlays/PerformanceMonitor.gd
func _match_thread_to_frame(frame_id: int) -> float:
	"""Match thread breakdown to frame_id from PerformanceMonitorSingleton buffer."""
	var metric: Dictionary = PerformanceMonitorSingleton.consume_thread_for_frame(frame_id)
	if metric.is_empty():
		return thread_compute_time_ms  # Fallback to current thread_compute_time_ms
	
	var breakdown: Dictionary = metric.get("breakdown", {})
	return breakdown.get("total_ms", thread_compute_time_ms)
```

**Issue:** Always returns empty dictionary because `_thread_breakdown_buffer` is never populated. Falls back to `thread_compute_time_ms`, which is only updated via `_update_thread_metrics()` → `get_thread_metrics()`, but that relies on finding WorldGenerator in scene tree and may not be frame-synchronized.

**Fallback Chain:**
1. Try `consume_thread_for_frame(frame_id)` → Returns `{}` (buffer empty)
2. Fall back to `thread_compute_time_ms` (updated by `_update_thread_metrics()`)
3. `_update_thread_metrics()` finds WorldGenerator and calls `get_thread_metrics()`
4. `get_thread_metrics()` returns averaged phase times, but not frame-tagged

### 2.3 PerformanceLogger Hardcoded Thread Time

**File:** `res://core/singletons/PerformanceLogger.gd`

```231:232:core/singletons/PerformanceLogger.gd
	# Thread time (placeholder - can be extended with custom tracking)
	var thread_ms: float = 0.0
```

**Issue:** Explicitly hardcoded to `0.0` with placeholder comment. Never populated from any metric source.

**CSV Impact:** Every row shows `ThreadMs = 0.000` regardless of actual thread activity.

### 2.4 PerformanceMonitorSingleton Breakdown Buffer

**File:** `res://core/singletons/PerformanceMonitorSingleton.gd`

```78:90:core/singletons/PerformanceMonitorSingleton.gd
func push_thread_breakdown(breakdown: Dictionary, frame_id: int = -1) -> void:
	"""Push thread breakdown with frame_id for waterfall view sync."""
	if frame_id == -1:
		frame_id = Engine.get_process_frames()
	_buffer_mutex.lock()
	_thread_breakdown_buffer.append({
		"frame_id": frame_id,
		"breakdown": breakdown,
		"timestamp_usec": Time.get_ticks_usec()
	})
	if _thread_breakdown_buffer.size() > UIConstants.WATERFALL_BUFFER_MAX:
		_thread_breakdown_buffer.pop_front()
	_buffer_mutex.unlock()
```

**Status:** Function exists and is properly implemented. **Never called by WorldGenerator.**

**Buffer Size:** `UIConstants.WATERFALL_BUFFER_MAX = 10` (last 10 breakdowns retained)

### 2.5 Thread Metrics Queue (Backward Compatibility)

**File:** `res://core/world_generation/WorldGenerator.gd`

```208:214:core/world_generation/WorldGenerator.gd
func get_thread_metrics() -> Array[Dictionary]:
	"""Get and clear thread metrics queue (thread-safe, called from main thread)."""
	metrics_mutex.lock()
	var metrics: Array[Dictionary] = thread_metrics_queue.duplicate()
	thread_metrics_queue.clear()
	metrics_mutex.unlock()
	return metrics
```

**Status:** Used by `PerformanceMonitor._update_thread_metrics()` for status label updates, but:
- Metrics are cleared when retrieved (can only be read once)
- Not frame-tagged (can't match to specific frames)
- Only provides average/aggregate, not per-phase breakdown

---

## 3. Comparison with Refresh Metrics

### 3.1 Refresh Breakdown Implementation (Reference)

**File:** `res://core/world_generation/MapRenderer.gd`

```302:304:core/world_generation/MapRenderer.gd
	# Send timing to Performance Monitor overlay
	if PerformanceMonitorSingleton.monitor_instance:
		PerformanceMonitorSingleton.set_refresh_time(refresh_time_ms)
```

**Finding:** MapRenderer only calls `set_refresh_time()`, **not** `push_refresh_breakdown()`. This suggests refresh breakdowns may also be incomplete, but refresh metrics work because `set_refresh_time()` directly updates `PerformanceMonitor.refresh_time_ms`, which is used as a fallback.

**Difference:** Refresh has a direct update path (`set_refresh_time()` → `refresh_time_ms` variable). Thread metrics have no equivalent direct update path to `thread_compute_time_ms` during active generation.

### 3.2 Waterfall View Refresh Matching

**File:** `res://scripts/ui/overlays/PerformanceMonitor.gd`

```756:763:scripts/ui/overlays/PerformanceMonitor.gd
func _match_refresh_to_frame(frame_id: int) -> float:
	"""Match refresh breakdown to frame_id from PerformanceMonitorSingleton buffer."""
	var metric: Dictionary = PerformanceMonitorSingleton.consume_refresh_for_frame(frame_id)
	if metric.is_empty():
		return refresh_time_ms  # Fallback to current refresh_time_ms
	
	var breakdown: Dictionary = metric.get("breakdown", {})
	return breakdown.get("total_ms", refresh_time_ms)
```

**Observation:** Refresh matching has same pattern as thread matching, but refresh has a reliable fallback (`refresh_time_ms` is updated every refresh). Thread fallback (`thread_compute_time_ms`) is less reliable because it depends on `_update_thread_metrics()` finding WorldGenerator and metrics not being cleared.

---

## 4. Logging Bugs

### 4.1 PerformanceLogger Never Reads Thread Metrics

**File:** `res://core/singletons/PerformanceLogger.gd`

`log_current_frame()` has no mechanism to:
- Read from `PerformanceMonitorSingleton.get_thread_breakdown_buffer()`
- Read from `PerformanceMonitor.thread_compute_time_ms`
- Query WorldGenerator directly for metrics
- Accept thread_ms as custom_data parameter (could be extended)

**Current Behavior:** Always logs `0.000` for ThreadMs column.

### 4.2 Thread Metrics Queue Clearing

**Issue:** `get_thread_metrics()` clears the queue on read. If multiple consumers try to read:
- First consumer gets all metrics
- Subsequent consumers get empty array
- Metrics lost after first read

**Impact:** If both `PerformanceMonitor._update_thread_metrics()` and a hypothetical PerformanceLogger query both read metrics, second reader gets nothing.

---

## 5. Recommended Fixes (Priority: Critical to Low)

### 5.1 🔴 CRITICAL: Aggregate and Push Thread Breakdowns

**Priority:** Critical  
**Files:** `res://core/world_generation/WorldGenerator.gd`

**Change:** Modify `_threaded_generate()` to aggregate metrics and push breakdown after completion.

**Implementation:**
1. Track all phase metrics in local array during generation
2. After all phases complete, aggregate into breakdown dictionary
3. Call `push_thread_breakdown()` with aggregated breakdown and frame_id

**Code Location:** After line 170 (after `_record_metric("total_generation", total_time)`)

**Pseudocode:**
```gdscript
# After _record_metric("total_generation", total_time)
var breakdown: Dictionary = {
	"total_ms": total_time,
	"configure_noise_ms": config_time,
	"generate_heightmap_ms": heightmap_time,
	"post_processing_ms": postproc_time
}
# Note: frame_id will be set when breakdown is consumed on main thread
# We use -1 to let push_thread_breakdown() use current frame
PerformanceMonitorSingleton.push_thread_breakdown(breakdown, -1)
```

**Consideration:** Threads can't call `Engine.get_process_frames()` (main thread only), so use `-1` to let `push_thread_breakdown()` set frame_id on main thread. However, this loses frame accuracy. **Better approach:** Use `call_deferred()` to push breakdown on main thread with correct frame_id.

**Better Implementation:**
```gdscript
# In _threaded_generate(), after all phases:
call_deferred("_push_thread_breakdown_main_thread", {
	"total_ms": total_time,
	"configure_noise_ms": config_time,
	"generate_heightmap_ms": heightmap_time,
	"post_processing_ms": postproc_time
})

# New method (called on main thread via call_deferred):
func _push_thread_breakdown_main_thread(breakdown: Dictionary) -> void:
	var frame_id: int = Engine.get_process_frames()
	PerformanceMonitorSingleton.push_thread_breakdown(breakdown, frame_id)
```

### 5.2 🔴 CRITICAL: Update PerformanceLogger to Read Thread Metrics

**Priority:** Critical  
**Files:** `res://core/singletons/PerformanceLogger.gd`

**Change:** Replace hardcoded `thread_ms = 0.0` with actual metric retrieval.

**Options:**

**Option A: Read from breakdown buffer (frame-matched)**
```gdscript
# Get current frame_id
var frame_id: int = Engine.get_process_frames()
var thread_metric: Dictionary = PerformanceMonitorSingleton.consume_thread_for_frame(frame_id)
var thread_ms: float = 0.0
if not thread_metric.is_empty():
	var breakdown: Dictionary = thread_metric.get("breakdown", {})
	thread_ms = breakdown.get("total_ms", 0.0)
```

**Option B: Read from PerformanceMonitor (fallback)**
```gdscript
# Try to get from PerformanceMonitor instance
var thread_ms: float = 0.0
if PerformanceMonitorSingleton.monitor_instance:
	thread_ms = PerformanceMonitorSingleton.monitor_instance.thread_compute_time_ms
```

**Option C: Hybrid (preferred)**
```gdscript
# Try breakdown buffer first (frame-accurate), fallback to PerformanceMonitor
var frame_id: int = Engine.get_process_frames()
var thread_metric: Dictionary = PerformanceMonitorSingleton.consume_thread_for_frame(frame_id)
var thread_ms: float = 0.0

if not thread_metric.is_empty():
	var breakdown: Dictionary = thread_metric.get("breakdown", {})
	thread_ms = breakdown.get("total_ms", 0.0)
elif PerformanceMonitorSingleton.monitor_instance:
	thread_ms = PerformanceMonitorSingleton.monitor_instance.thread_compute_time_ms
```

**Recommendation:** Option C (hybrid) provides best accuracy with graceful fallback.

### 5.3 🟡 HIGH: Fix Thread Metrics Queue Clearing

**Priority:** High  
**Files:** `res://core/world_generation/WorldGenerator.gd`

**Issue:** `get_thread_metrics()` clears queue, making metrics single-use.

**Change:** Don't clear queue on read, or provide non-destructive read method.

**Options:**

**Option A: Non-destructive read**
```gdscript
func peek_thread_metrics() -> Array[Dictionary]:
	"""Peek at thread metrics without clearing (non-destructive)."""
	metrics_mutex.lock()
	var metrics: Array[Dictionary] = thread_metrics_queue.duplicate()
	metrics_mutex.unlock()
	return metrics

func get_thread_metrics() -> Array[Dictionary]:
	"""Get and clear thread metrics queue (thread-safe, called from main thread)."""
	# Existing implementation (keep for backward compatibility)
```

**Option B: Keep metrics longer (time-based expiry)**
```gdscript
# Add timestamp to metrics, expire after N seconds instead of clearing on read
# More complex, but allows multiple consumers
```

**Recommendation:** Option A (add `peek_thread_metrics()`) - simple, backward compatible.

### 5.4 🟡 HIGH: Periodic Breakdown Pushes During Generation

**Priority:** High  
**Files:** `res://core/world_generation/WorldGenerator.gd`

**Current Behavior:** Breakdown only pushed after generation completes. Waterfall view only sees metrics after generation finishes.

**Change:** Push breakdowns periodically during generation (e.g., after each phase completes).

**Implementation:**
- After each phase completes, push incremental breakdown
- Or push accumulated breakdown every N milliseconds during generation
- Allows waterfall view to show thread activity in real-time

**Consideration:** May increase overhead. Buffer size limit (10 entries) prevents unbounded growth.

### 5.5 🟢 MEDIUM: Add Refresh Breakdown Support

**Priority:** Medium  
**Files:** `res://core/world_generation/MapRenderer.gd`

**Finding:** MapRenderer doesn't push refresh breakdowns, only sets refresh time.

**Change:** Add breakdown push alongside `set_refresh_time()` call.

**Implementation:**
```gdscript
# In MapRenderer._do_actual_refresh(), after timing calculation:
var breakdown: Dictionary = {
	"total_ms": refresh_time_ms,
	# Add sub-breakdowns if available:
	# "culling_ms": culling_time_ms,
	# "mesh_gen_ms": mesh_gen_time_ms,
	# "texture_update_ms": texture_update_time_ms
}
PerformanceMonitorSingleton.push_refresh_breakdown(breakdown)
```

**Benefit:** Waterfall view could show refresh sub-breakdowns (culling, mesh gen, texture updates).

### 5.6 🟢 LOW: PerformanceLogger Custom Data Extension

**Priority:** Low  
**Files:** `res://core/singletons/PerformanceLogger.gd`

**Enhancement:** Allow `thread_ms` to be passed as `custom_data` parameter.

**Implementation:**
```gdscript
# In log_current_frame(), check custom_data for thread_ms:
var thread_ms: float = custom_data.get("thread_ms", 0.0)
if thread_ms == 0.0:
	# Fall back to breakdown buffer or PerformanceMonitor (Option C from 5.2)
```

**Benefit:** External code can manually provide thread metrics if needed.

---

## 6. Migration Plan

### 6.1 Phase 1: Critical Fixes (Immediate)

1. **Add breakdown aggregation in WorldGenerator**
   - Modify `_threaded_generate()` to aggregate metrics
   - Add `_push_thread_breakdown_main_thread()` helper method
   - Test: Generate map, verify breakdown buffer populated

2. **Fix PerformanceLogger thread_ms**
   - Replace hardcoded `0.0` with hybrid retrieval (Option C)
   - Test: Enable logging, generate map, verify CSV shows non-zero ThreadMs

**Estimated Time:** 2-3 hours  
**Risk:** Low (additive changes, doesn't break existing functionality)

### 6.2 Phase 2: Enhancements (Short-term)

3. **Add peek_thread_metrics() for non-destructive reads**
   - Implement `peek_thread_metrics()` method
   - Update `PerformanceMonitor._update_thread_metrics()` to use peek
   - Test: Verify metrics persist after status label update

4. **Periodic breakdown pushes during generation**
   - Add breakdown push after each phase completes
   - Test: Verify waterfall view shows thread activity in real-time

**Estimated Time:** 2-3 hours  
**Risk:** Low-Medium (changes metric collection timing)

### 6.3 Phase 3: Optional Improvements (Medium-term)

5. **Add refresh breakdown support**
   - Instrument MapRenderer to push breakdowns
   - Test: Verify waterfall view shows refresh sub-breakdowns

6. **PerformanceLogger custom_data extension**
   - Allow thread_ms in custom_data with fallback
   - Document usage

**Estimated Time:** 1-2 hours  
**Risk:** Very Low

### 6.4 Testing Checklist

After each phase:

- [ ] Generate map with threading enabled
- [ ] Verify `PerformanceMonitorSingleton.get_thread_breakdown_buffer()` contains entries
- [ ] Verify waterfall view shows thread metrics (non-zero thread_ms bars)
- [ ] Verify PerformanceLogger CSV contains non-zero ThreadMs values
- [ ] Verify graph display still works (ring buffer unaffected)
- [ ] Verify status label shows "World Gen Active" during generation
- [ ] Test with multiple map generations (verify buffer doesn't overflow)
- [ ] Test with threading disabled (verify no errors, metrics remain 0)

---

## 7. Testing Plan

### 7.1 Unit Test Scenarios

1. **Breakdown Aggregation Test**
   - Mock `_threaded_generate()` phases
   - Verify breakdown dictionary structure correct
   - Verify `push_thread_breakdown()` called with correct frame_id

2. **Buffer Consumption Test**
   - Push multiple breakdowns with different frame_ids
   - Verify `consume_thread_for_frame()` returns correct breakdown
   - Verify buffer size limit enforced

3. **PerformanceLogger Integration Test**
   - Mock breakdown buffer with known values
   - Verify `log_current_frame()` logs correct thread_ms
   - Test fallback when buffer empty

### 7.2 Integration Test Scenarios

1. **Full Generation Workflow**
   - Start world generation
   - Monitor breakdown buffer during generation
   - Verify breakdown pushed after completion
   - Verify PerformanceLogger CSV contains metrics
   - Verify waterfall view displays metrics

2. **Concurrent Reads**
   - Generate map
   - Simultaneously query via `get_thread_metrics()` and breakdown buffer
   - Verify both receive data (after Phase 1 fix)

3. **Edge Cases**
   - Very fast generation (< 1ms total)
   - Very slow generation (> 10 seconds)
   - Generation cancellation/interruption
   - Multiple sequential generations

### 7.3 Performance Impact Assessment

- **Overhead:** Breakdown aggregation adds minimal overhead (dictionary creation)
- **Memory:** Breakdown buffer limited to 10 entries (constant memory)
- **Thread Safety:** All buffer operations use mutex (safe)

**Expected Impact:** Negligible (< 0.1ms per generation cycle)

---

## 8. Code Quality Requirements

All fixes must follow project rules:

- ✅ Typed GDScript (`: float`, `: Dictionary`, etc.)
- ✅ Docstrings on all public functions
- ✅ No magic numbers (use constants from UIConstants or define new ones)
- ✅ Thread-safe operations (mutex where needed)
- ✅ Error handling for edge cases
- ✅ Script headers with exact format

---

## 9. Related Documentation

- `docs/ui/WATERFALL_VIEW_V4_SPECIFICATION.md` - Waterfall view specification
- `audit/WATERFALL_VIEW_V3_EVALUATION.md` - Previous waterfall view evaluation
- `audit/PERFORMANCE_MONITOR_ANALYSIS_PROMPT.md` - Performance monitor analysis

---

## 10. Conclusion

The threading metrics disconnect is a **critical architectural issue** that prevents accurate performance analysis. The fix requires minimal code changes but addresses a fundamental gap in the metric collection pipeline.

**Root Cause:** Two metric systems (ring buffer vs. breakdown buffer) were implemented, but only one (ring buffer) was connected to the data source. The breakdown buffer infrastructure exists but is never populated.

**Solution:** Connect WorldGenerator metric recording to the breakdown buffer system via aggregation and `push_thread_breakdown()` calls, and update PerformanceLogger to consume from the breakdown buffer.

**Priority:** Address Phase 1 fixes immediately to restore accurate performance logging and waterfall view metrics.

---

**Audit Completed By:** AI Assistant (Auto)  
**Next Steps:** Implement Phase 1 fixes, then proceed with testing and validation.

