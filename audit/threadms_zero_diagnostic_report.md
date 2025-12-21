# ThreadMs=0.000 Diagnostic Report

**Date:** 2025-01-26  
**Issue:** ThreadMs values remain 0.000 in CSV logs despite Phase 1 fixes  
**Status:** Critical - Multiple root causes identified  
**Priority:** High - Performance analysis blocked

---

## Executive Summary

After Phase 1 implementation, ThreadMs values are still 0.000 across 57 frames including during generation spikes. **Four critical issues** identified:

1. **🔴 CONSUMPTION CONFLICT**: Both PerformanceMonitor and PerformanceLogger consume (remove) breakdowns - first consumer wins, second gets empty
2. **🔴 TIMING MISMATCH**: Breakdowns pushed AFTER generation completes, but logging happens DURING generation
3. **🟡 FALLBACK FAILURE**: `thread_compute_time_ms` only updated in DETAILED mode with active WorldGenerator
4. **🟡 GENERATION STATUS UNKNOWN**: Cannot verify if threading actually executed or breakdown was pushed

---

## 1. 🔴 CRITICAL: Consumption Conflict (Primary Issue)

### Issue Description

Both `PerformanceMonitor._match_thread_to_frame()` and `PerformanceLogger.log_current_frame()` call `consume_thread_for_frame()`, which **removes** the breakdown from the buffer.

### Code Evidence

**PerformanceMonitor consumption (line 767):**
```765:772:scripts/ui/overlays/PerformanceMonitor.gd
func _match_thread_to_frame(frame_id: int) -> float:
	"""Match thread breakdown to frame_id from PerformanceMonitorSingleton buffer."""
	var metric: Dictionary = PerformanceMonitorSingleton.consume_thread_for_frame(frame_id)
	if metric.is_empty():
		return thread_compute_time_ms  # Fallback to current thread_compute_time_ms
	
	var breakdown: Dictionary = metric.get("breakdown", {})
	return breakdown.get("total_ms", thread_compute_time_ms)
```

**PerformanceLogger consumption (line 232):**
```229:239:core/singletons/PerformanceLogger.gd
	# Thread time: Try breakdown buffer first (frame-accurate), fallback to PerformanceMonitor
	var thread_ms: float = 0.0
	var frame_id: int = Engine.get_process_frames()
	var thread_metric: Dictionary = PerformanceMonitorSingleton.consume_thread_for_frame(frame_id)
	
	if not thread_metric.is_empty():
		var breakdown: Dictionary = thread_metric.get("breakdown", {})
		thread_ms = breakdown.get("total_ms", 0.0)
	elif PerformanceMonitorSingleton.monitor_instance:
		# Fallback to PerformanceMonitor's aggregated thread compute time
		thread_ms = PerformanceMonitorSingleton.monitor_instance.thread_compute_time_ms
```

**Consume function removes entry:**
```140:151:core/singletons/PerformanceMonitorSingleton.gd
func consume_thread_for_frame(frame_id: int) -> Dictionary:
	"""Consume and return thread breakdown for a specific frame."""
	_buffer_mutex.lock()
	for i in range(_thread_breakdown_buffer.size() - 1, -1, -1):
		var metric: Dictionary = _thread_breakdown_buffer[i]
		if metric.get("frame_id", -1) == frame_id or metric.get("frame_id", -1) == frame_id - 1:
			var result: Dictionary = metric.duplicate()
			_thread_breakdown_buffer.remove_at(i)  # ⚠️ REMOVES FROM BUFFER
			_buffer_mutex.unlock()
			return result
	_buffer_mutex.unlock()
	return {}
```

### Execution Order Analysis

**Typical Frame Execution:**
1. `PerformanceMonitor._process()` runs (if DETAILED mode enabled)
   - Calls `_match_thread_to_frame(frame_id)` → consumes breakdown
   - Breakdown removed from buffer
2. `WorldBuilderUI._process()` runs
   - Calls `PerformanceLogger.log_current_frame()`
   - Calls `consume_thread_for_frame(frame_id)` → buffer already empty → returns `{}`
   - Falls back to `thread_compute_time_ms` (which may be 0.0)

**Result:** PerformanceMonitor consumes breakdown first, PerformanceLogger gets empty dict, fallback may not work.

### Impact

- **100% failure rate** when both systems active (PerformanceMonitor in DETAILED mode + PerformanceLogger logging)
- Breakdown consumed before PerformanceLogger can read it
- Only one consumer can ever see the breakdown

---

## 2. 🔴 CRITICAL: Timing Mismatch

### Issue Description

Breakdowns are pushed **AFTER** generation completes, but logging happens **DURING** generation (every ~0.1 seconds based on interval throttling).

### Code Flow

**Generation Timeline:**
```
Frame N-100: Generation starts (threaded)
Frame N-50:  log_current_frame() called → No breakdown yet → thread_ms = 0.0
Frame N-10:  log_current_frame() called → No breakdown yet → thread_ms = 0.0
Frame N:     Generation completes
             call_deferred("_push_thread_breakdown_main_thread", breakdown)
Frame N+1:   _push_thread_breakdown_main_thread() executes (main thread)
             frame_id = Engine.get_process_frames()  # Gets frame N+1
             push_thread_breakdown(breakdown, frame_id=N+1)
Frame N+1:   log_current_frame() called → Checks frame_id N+1 → Finds breakdown (if not consumed)
Frame N+2:   log_current_frame() called → Checks frame_id N+2 → No breakdown (already consumed or wrong frame)
```

**Breakdown Push:**
```237:243:core/world_generation/WorldGenerator.gd
func _push_thread_breakdown_main_thread(breakdown: Dictionary) -> void:
	"""Push thread breakdown to PerformanceMonitorSingleton on main thread (callable from thread via call_deferred)."""
	var frame_id: int = Engine.get_process_frames()
	PerformanceMonitorSingleton.push_thread_breakdown(breakdown, frame_id)
	MythosLogger.debug("WorldGenerator", "Pushed thread breakdown to buffer", {
		"frame_id": frame_id,
		"total_ms": breakdown.get("total_ms", 0.0)
```

**Frame Matching Logic:**
```140:151:core/singletons/PerformanceMonitorSingleton.gd
func consume_thread_for_frame(frame_id: int) -> Dictionary:
	"""Consume and return thread breakdown for a specific frame."""
	_buffer_mutex.lock()
	for i in range(_thread_breakdown_buffer.size() - 1, -1, -1):
		var metric: Dictionary = _thread_breakdown_buffer[i]
		if metric.get("frame_id", -1) == frame_id or metric.get("frame_id", -1) == frame_id - 1:
			var result: Dictionary = metric.duplicate()
			_thread_breakdown_buffer.remove_at(i)
			_buffer_mutex.unlock()
			return result
```

### Problem

- Breakdown represents **total generation time** (all phases combined), but is only available **after** generation completes
- Logging during generation sees `thread_ms = 0.0` because breakdown doesn't exist yet
- Even after breakdown is pushed, it might be consumed immediately by PerformanceMonitor before PerformanceLogger sees it

### Impact

- Logs during generation will always show `ThreadMs = 0.000`
- Only logs **after** generation completes might capture thread time (if not consumed first)
- Frame_id matching (`frame_id` or `frame_id - 1`) helps but doesn't solve consumption conflict

---

## 3. 🟡 HIGH: Fallback Failure

### Issue Description

The fallback to `thread_compute_time_ms` may not work because:
1. `thread_compute_time_ms` is only updated when PerformanceMonitor is in DETAILED mode
2. Requires finding WorldGenerator in scene tree
3. Uses `get_thread_metrics()` which clears the queue (one-time read)

### Code Evidence

**Fallback logic:**
```237:239:core/singletons/PerformanceLogger.gd
	elif PerformanceMonitorSingleton.monitor_instance:
		# Fallback to PerformanceMonitor's aggregated thread compute time
		thread_ms = PerformanceMonitorSingleton.monitor_instance.thread_compute_time_ms
```

**thread_compute_time_ms update (only in DETAILED mode):**
```700:723:scripts/ui/overlays/PerformanceMonitor.gd
func _update_thread_metrics() -> void:
	"""Update thread metrics from WorldGenerator if available."""
	# Try to find WorldGenerator in scene tree (using method check to avoid type issues)
	var world_gen = _find_world_generator()
	if world_gen and world_gen.has_method("is_generating"):
		# Check if generating
		if world_gen.is_generating():
			system_status = "World Gen Active"
			# Get thread metrics
			var metrics: Array[Dictionary] = world_gen.get_thread_metrics()
			if metrics.size() > 0:
				# Sum up recent compute time (last metric's time)
				thread_compute_time_ms = 0.0
				for metric: Dictionary in metrics:
					thread_compute_time_ms += metric.get("time_ms", 0.0)
				# Average over metrics count
				if metrics.size() > 0:
					thread_compute_time_ms /= metrics.size()
		else:
			system_status = "Idle"
			thread_compute_time_ms = 0.0
	else:
		system_status = "Idle"
		thread_compute_time_ms = 0.0
```

**Called only in DETAILED mode:**
```427:428:scripts/ui/overlays/PerformanceMonitor.gd
		# Update system status and thread metrics
		_update_thread_metrics()
```

### Scenarios Where Fallback Fails

1. **PerformanceMonitor in OFF or SIMPLE mode:**
   - `_update_thread_metrics()` never called
   - `thread_compute_time_ms` remains 0.0
   - PerformanceLogger fallback returns 0.0

2. **WorldGenerator not in scene tree:**
   - `_find_world_generator()` returns null
   - `thread_compute_time_ms` set to 0.0
   - PerformanceLogger fallback returns 0.0

3. **Generation completed:**
   - `is_generating()` returns false
   - `thread_compute_time_ms` set to 0.0
   - PerformanceLogger fallback returns 0.0

4. **Metrics already consumed:**
   - `get_thread_metrics()` clears queue
   - If called multiple times, subsequent calls return empty array
   - `thread_compute_time_ms` calculated as 0.0

### Impact

- Fallback unreliable when PerformanceMonitor not in DETAILED mode
- Fallback may return 0.0 even when thread activity exists
- Creates dependency on PerformanceMonitor mode for PerformanceLogger accuracy

---

## 4. 🟡 MEDIUM: Generation Status Unknown

### Issue Description

Cannot verify if:
1. Threading actually executed (vs synchronous generation)
2. Breakdown was pushed successfully
3. `_push_thread_breakdown_main_thread()` was called

### Verification Points Needed

**Check if generation was threaded:**
- Review logs for "Thread generation complete" message
- Check if `MapGenerator.use_threading` was true
- Verify `generation_thread` was created and executed

**Check if breakdown was pushed:**
- Review logs for "Pushed thread breakdown to buffer" debug message
- Verify frame_id logged matches expected frame
- Check breakdown buffer contents (if accessible)

**Check breakdown buffer state:**
- Buffer might be empty (already consumed)
- Buffer might contain breakdowns with wrong frame_ids
- Buffer might be full (limited to 10 entries per `UIConstants.WATERFALL_BUFFER_MAX`)

### Current Logging

**WorldGenerator logs breakdown push:**
```237:243:core/world_generation/WorldGenerator.gd
func _push_thread_breakdown_main_thread(breakdown: Dictionary) -> void:
	"""Push thread breakdown to PerformanceMonitorSingleton on main thread (callable from thread via call_deferred)."""
	var frame_id: int = Engine.get_process_frames()
	PerformanceMonitorSingleton.push_thread_breakdown(breakdown, frame_id)
	MythosLogger.debug("WorldGenerator", "Pushed thread breakdown to buffer", {
		"frame_id": frame_id,
		"total_ms": breakdown.get("total_ms", 0.0)
```

**Note:** Uses `MythosLogger.debug()` - may not appear if debug level disabled.

### Impact

- Cannot determine root cause without verification
- May be implementation issue or execution issue
- Requires logging review to confirm

---

## 5. Root Cause Analysis Summary

### Primary Root Cause: Consumption Conflict

**Problem:** `consume_thread_for_frame()` removes breakdowns from buffer. Both PerformanceMonitor and PerformanceLogger call it, causing race condition where first consumer wins.

**Evidence:**
- Both systems call `consume_thread_for_frame()`
- Function removes entry after reading
- No mechanism for multiple consumers

**Impact:** **100% failure** when both systems active simultaneously.

### Secondary Root Cause: Timing Mismatch

**Problem:** Breakdowns pushed AFTER generation completes, but logging happens DURING generation.

**Evidence:**
- Breakdown pushed via `call_deferred()` after generation completes
- `log_current_frame()` called every ~0.1 seconds during generation
- No breakdown exists during generation

**Impact:** Logs during generation always show 0.0 (expected), but logs after completion may miss breakdown if consumed first.

### Tertiary Root Cause: Fallback Limitations

**Problem:** Fallback to `thread_compute_time_ms` only works when PerformanceMonitor in DETAILED mode and WorldGenerator active.

**Evidence:**
- `thread_compute_time_ms` only updated in `_update_thread_metrics()`
- `_update_thread_metrics()` only called in DETAILED mode
- Requires WorldGenerator in scene tree and `is_generating() == true`

**Impact:** Fallback unreliable when PerformanceMonitor in OFF/SIMPLE mode.

---

## 6. Recommended Fixes (Priority: Critical to Low)

### 6.1 🔴 CRITICAL: Fix Consumption Conflict

**Option A: Non-Destructive Read (Preferred)**
- Add `peek_thread_for_frame()` that reads without removing
- PerformanceLogger uses peek (non-destructive)
- PerformanceMonitor uses consume (removes for waterfall view)
- Both can access same breakdown

**Option B: Separate Buffers**
- Create separate buffer for PerformanceLogger
- WorldGenerator pushes to both buffers
- No consumption conflict

**Option C: Read-Then-Consume Pattern**
- PerformanceLogger reads breakdown, stores value, then consumes
- PerformanceMonitor checks if already consumed (by checking stored value)
- More complex, requires shared state

**Recommendation:** Option A (non-destructive peek) - simplest, cleanest, no breaking changes.

### 6.2 🔴 CRITICAL: Fix Timing Mismatch

**Option A: Push Breakdown Immediately (Not After Generation)**
- Push breakdown when generation STARTS (with estimated time)
- Update breakdown as phases complete
- Logging can capture thread activity during generation

**Option B: Store Breakdown in Non-Consumed Buffer**
- Push breakdown to separate "log buffer" that's never consumed
- PerformanceLogger reads from log buffer (doesn't remove)
- PerformanceMonitor reads from breakdown buffer (consumes for waterfall)

**Option C: Deferred Logging**
- Queue frame logs during generation
- After generation completes, retroactively update logs with thread time
- Complex, requires log queue management

**Recommendation:** Option B (separate log buffer) - clean separation, allows both systems to work independently.

### 6.3 🟡 HIGH: Improve Fallback Reliability

**Option A: Always Update thread_compute_time_ms**
- Update `thread_compute_time_ms` regardless of PerformanceMonitor mode
- Call `_update_thread_metrics()` from separate update cycle (not just DETAILED mode)
- PerformanceLogger fallback more reliable

**Option B: Direct WorldGenerator Query**
- PerformanceLogger queries WorldGenerator directly for metrics
- Doesn't rely on PerformanceMonitor state
- Bypasses fallback entirely

**Option C: Push Thread Time to Separate Variable**
- WorldGenerator pushes total thread time to PerformanceMonitorSingleton
- Separate from breakdown buffer
- PerformanceLogger reads directly (no consumption)

**Recommendation:** Option C (separate thread time variable) - simplest, most reliable, no dependencies.

### 6.4 🟢 MEDIUM: Add Diagnostic Logging

**Enhancements:**
- Log when breakdown is pushed (currently debug level)
- Log when breakdown is consumed (by which system)
- Log buffer state (size, frame_ids)
- Log fallback usage (when breakdown not found, using fallback value)

**Implementation:**
- Change `MythosLogger.debug()` to `MythosLogger.info()` for breakdown push
- Add logging in `consume_thread_for_frame()` for diagnostics
- Add logging in PerformanceLogger fallback path

---

## 7. Implementation Priority

### Phase 1: Quick Fix (Immediate)

1. **Add `peek_thread_for_frame()` method** (non-destructive read)
2. **Change PerformanceLogger to use peek** (don't consume)
3. **Test:** Verify both systems can read breakdown

**Estimated Time:** 1-2 hours  
**Risk:** Low (additive change, no breaking modifications)

### Phase 2: Proper Fix (Short-term)

4. **Add separate thread time variable** to PerformanceMonitorSingleton
5. **WorldGenerator updates thread time** directly (in addition to breakdown)
6. **PerformanceLogger reads thread time** (bypasses breakdown buffer entirely)
7. **Test:** Verify logging works regardless of PerformanceMonitor mode

**Estimated Time:** 2-3 hours  
**Risk:** Low-Medium (adds new data path, but doesn't break existing)

### Phase 3: Enhanced Diagnostics (Medium-term)

8. **Add diagnostic logging** for breakdown push/consume
9. **Add buffer state inspection** (debug view)
10. **Add fallback usage logging** (know when fallback triggered)

**Estimated Time:** 1-2 hours  
**Risk:** Very Low (logging only)

---

## 8. Testing Plan

After fixes:

1. **Enable PerformanceLogger** (default now enabled)
2. **Generate map** (small/medium/large)
3. **Check logs for:**
   - "Pushed thread breakdown to buffer" message
   - Breakdown frame_id matches expected
   - ThreadMs > 0.000 in CSV during/after generation
4. **Test with PerformanceMonitor in different modes:**
   - OFF mode: ThreadMs should still work (via separate thread time)
   - SIMPLE mode: ThreadMs should still work
   - DETAILED mode: ThreadMs should work (no consumption conflict)
5. **Verify both systems can read thread metrics:**
   - PerformanceMonitor waterfall view shows thread bars
   - PerformanceLogger CSV shows ThreadMs values

---

## 9. Conclusion

**Primary Issue:** Consumption conflict prevents PerformanceLogger from reading breakdowns after PerformanceMonitor consumes them.

**Secondary Issue:** Timing mismatch means breakdowns only available after generation, but logging happens during generation.

**Tertiary Issue:** Fallback unreliable when PerformanceMonitor not in DETAILED mode.

**Recommended Approach:** 
1. Add non-destructive peek method (Phase 1 - quick fix)
2. Add separate thread time variable (Phase 2 - proper fix)
3. Add diagnostic logging (Phase 3 - visibility)

This will ensure ThreadMs values are correctly logged regardless of PerformanceMonitor mode or execution order.

---

**Audit Completed By:** AI Assistant (Auto)  
**Next Steps:** Implement Phase 1 fix, then proceed with Phase 2 for long-term solution.

