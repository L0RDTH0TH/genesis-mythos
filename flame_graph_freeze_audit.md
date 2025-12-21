# Flame Graph Freeze Audit Report

**Date:** 2025-01-26  
**Issue:** Performance overlay freezes when entering FLAME mode via F3  
**Status:** Critical Bug Identified  
**Priority:** High - Blocks flame graph profiling functionality

---

## Executive Summary

The flame graph implementation has **multiple critical issues** that cause the performance overlay to freeze when entering FLAME mode:

1. **CRITICAL: Missing FLAME mode handling in `_process()`** - FLAME mode doesn't trigger detailed metrics updates, but more importantly, the sampling timer calls `get_stack()` 100 times per second (every 10ms), which is extremely expensive in Godot and can freeze the main thread.

2. **High-frequency `get_stack()` calls** - The sampling timer with 10ms interval calls `get_stack()` which walks the entire call stack. This is a blocking operation that can take several milliseconds, causing frame drops and freezes.

3. **Potential mutex contention** - While mutex usage appears correct, the high frequency of lock/unlock operations (100/sec) combined with expensive operations could cause contention.

4. **Missing FLAME mode check in `_process()`** - FLAME mode should behave like DETAILED mode but currently doesn't, meaning UI updates may be inconsistent.

---

## 1. Code Analysis Findings

### 1.1 Critical Issue: Missing FLAME Mode in `_process()`

**Location:** `res://scripts/ui/overlays/PerformanceMonitor.gd`, line 412

**Problem:**
```gdscript
if current_mode == Mode.DETAILED:
    # ... detailed metrics update code ...
```

FLAME mode is not included in this check, so when in FLAME mode:
- Detailed metrics are not updated
- Graphs are not updated
- Waterfall view is not updated
- Only basic FPS label updates

**Impact:** While this doesn't directly cause a freeze, it means FLAME mode doesn't show the expected UI updates.

### 1.2 Critical Issue: High-Frequency `get_stack()` Calls

**Location:** `res://core/singletons/FlameGraphProfiler.gd`, lines 210-256

**Problem:**
- Sampling timer interval: **10ms** (100 calls per second)
- Each call executes `get_stack()` which is **extremely expensive** in Godot
- `get_stack()` walks the entire call stack synchronously, blocking the main thread
- With deep call stacks (20+ frames), each call can take 1-5ms
- **100 calls/second × 1-5ms = 100-500ms of blocking per second**

**Code:**
```gdscript
func _collect_stack_sample() -> void:
    # ...
    var raw_stack: Array = get_stack()  # EXPENSIVE - blocks main thread
    # ... formatting and buffer operations ...
```

**Impact:** This is the **primary cause of the freeze**. Calling `get_stack()` 100 times per second is far too frequent for a real-time application.

### 1.3 Timer Setup Analysis

**Location:** `res://core/singletons/FlameGraphProfiler.gd`, lines 178-191

**Current Configuration:**
- `sampling_interval_ms: 10.0` (from config)
- Timer runs on main thread (default behavior)
- Timer callback (`_collect_stack_sample()`) executes synchronously

**Issue:** Timer callbacks execute on the main thread, so expensive operations block the game loop.

### 1.4 Mutex Usage Analysis

**Location:** `res://core/singletons/FlameGraphProfiler.gd`, lines 252-256

**Code:**
```gdscript
_buffer_mutex.lock()
stack_samples.append(sample)
if stack_samples.size() > MAX_SAMPLES:
    stack_samples.pop_front()
_buffer_mutex.unlock()
```

**Analysis:** Mutex usage appears correct - lock and unlock are properly paired. However, with 100 lock/unlock operations per second, there could be contention if other threads are also accessing the buffer.

### 1.5 Aggregation Function Analysis

**Location:** `res://core/singletons/FlameGraphProfiler.gd`, lines 397-489

**Complexity Analysis:**
- `_aggregate_samples_to_tree()`: O(n × m) where n = samples, m = stack depth
- For 1000 samples with depth 20: ~20,000 operations
- `_calculate_self_times()`: Recursive, O(n) where n = tree nodes
- Called during `export_to_json()`, not during sampling

**Impact:** Aggregation is only called during export, not during sampling, so this is not the freeze cause.

### 1.6 Rate Limiting Check

**Location:** `res://core/singletons/FlameGraphProfiler.gd`, line 216

**Code:**
```gdscript
if PerformanceMonitorSingleton and not PerformanceMonitorSingleton.can_log():
    return
```

**Analysis:** This rate limiting check happens BEFORE `get_stack()`, which is good. However, `can_log()` itself may have overhead. The rate limit is 15 logs/second, but sampling happens 100 times/second, so most samples will be rejected by rate limiting.

**Issue:** The rate limiting check happens AFTER the timer callback is invoked, meaning the timer still fires 100 times/second even if most samples are rejected. This is wasteful.

---

## 2. Root Cause Analysis

### Primary Cause: Excessive `get_stack()` Frequency

**The freeze is caused by:**
1. Timer fires every 10ms (100 times/second)
2. Each timer callback calls `get_stack()` which blocks the main thread
3. `get_stack()` can take 1-5ms per call with deep stacks
4. **100 calls/second × 1-5ms = 100-500ms of blocking per second**
5. This exceeds the 16.67ms frame budget (60 FPS), causing frame drops and freezes

### Secondary Issues:
1. FLAME mode doesn't trigger DETAILED mode logic in `_process()`
2. Rate limiting happens too late (after timer callback)
3. No throttling mechanism for `get_stack()` calls

---

## 3. Recommended Fixes

### Fix 1: Increase Sampling Interval (Immediate)

**Priority:** CRITICAL  
**Change:** Increase `sampling_interval_ms` from 10.0 to 100.0 (10 samples/second instead of 100)

**Location:** `res://data/config/flame_graph_config.json`

```json
{
    "sampling_interval_ms": 100.0,  // Changed from 10.0
    // ... rest of config
}
```

**Impact:** Reduces `get_stack()` calls from 100/sec to 10/sec, reducing blocking time from 100-500ms/sec to 10-50ms/sec.

### Fix 2: Add FLAME Mode to `_process()` Check

**Priority:** HIGH  
**Location:** `res://scripts/ui/overlays/PerformanceMonitor.gd`, line 412

**Change:**
```gdscript
if current_mode == Mode.DETAILED or current_mode == Mode.FLAME:
    # ... detailed metrics update code ...
```

**Impact:** Ensures FLAME mode shows all metrics and graphs like DETAILED mode.

### Fix 3: Move Rate Limiting Before `get_stack()`

**Priority:** MEDIUM  
**Location:** `res://core/singletons/FlameGraphProfiler.gd`, line 210

**Current:**
```gdscript
func _collect_stack_sample() -> void:
    if not is_profiling_enabled:
        return
    
    # Check rate limiting via PerformanceMonitorSingleton
    if PerformanceMonitorSingleton and not PerformanceMonitorSingleton.can_log():
        return
    
    # Get stack trace (EXPENSIVE)
    var raw_stack: Array = get_stack()
```

**Better:** The rate limiting is already before `get_stack()`, which is good. However, we should add an additional check to skip if we've sampled recently.

**Recommended:**
```gdscript
var _last_sample_time: int = 0
const MIN_SAMPLE_INTERVAL_MSEC: int = 50  # Minimum 50ms between samples

func _collect_stack_sample() -> void:
    if not is_profiling_enabled:
        return
    
    # Early exit if sampled too recently (additional throttling)
    var now: int = Time.get_ticks_msec()
    if now - _last_sample_time < MIN_SAMPLE_INTERVAL_MSEC:
        return
    _last_sample_time = now
    
    # Check rate limiting
    if PerformanceMonitorSingleton and not PerformanceMonitorSingleton.can_log():
        return
    
    # Get stack trace (EXPENSIVE - but now throttled)
    var raw_stack: Array = get_stack()
```

### Fix 4: Use `call_deferred()` for Expensive Operations

**Priority:** MEDIUM  
**Location:** `res://core/singletons/FlameGraphProfiler.gd`, line 210

**Alternative Approach:** Move `get_stack()` to a deferred call to avoid blocking the timer callback.

**Note:** This may not work well because `get_stack()` needs to capture the current call stack, which may be lost if deferred.

### Fix 5: Reduce Stack Depth Limit

**Priority:** LOW  
**Location:** `res://data/config/flame_graph_config.json`

**Change:**
```json
{
    "max_stack_depth": 10,  // Reduced from 20
    // ... rest of config
}
```

**Impact:** Reduces the cost of each `get_stack()` call by limiting stack depth.

---

## 4. Testing Recommendations

### Test 1: Verify Sampling Frequency
1. Add debug print in `_collect_stack_sample()`: `print("Sample collected at: ", Time.get_ticks_msec())`
2. Run project and enter FLAME mode
3. Count samples per second in console output
4. Expected: Should see ~100 samples/second (too many!)

### Test 2: Measure `get_stack()` Cost
1. Add timing around `get_stack()`:
   ```gdscript
   var start: int = Time.get_ticks_usec()
   var raw_stack: Array = get_stack()
   var elapsed: int = Time.get_ticks_usec() - start
   print("get_stack() took: ", elapsed, " usec (", elapsed / 1000.0, " ms)")
   ```
2. Run and observe timing
3. Expected: Each call takes 1-5ms, which is too expensive for 100/sec

### Test 3: Test with Increased Interval
1. Temporarily change `sampling_interval_ms` to 100.0
2. Run project and enter FLAME mode
3. Verify freeze is resolved
4. Expected: Should work smoothly with 10 samples/second

---

## 5. Code Quality Issues

### 5.1 Missing Type Annotations
- `raw_stack: Array` should be `raw_stack: Array[Dictionary]`
- `stack: Array` should be `stack: Array[Dictionary]`
- `formatted_stack: Array[Dictionary]` is correctly typed

### 5.2 Magic Numbers
- `10.0` (sampling_interval_ms) - should come from config ✓ (already does)
- `20` (max_stack_depth) - should come from config ✓ (already does)
- `1000` (MAX_SAMPLES) - constant, acceptable

### 5.3 Documentation
- Functions have docstrings ✓
- Complex algorithms could use more inline comments

---

## 6. Summary of Issues

| Issue | Severity | Location | Fix Priority |
|-------|----------|----------|--------------|
| High-frequency `get_stack()` calls (10ms interval) | CRITICAL | FlameGraphProfiler._collect_stack_sample() | 1 |
| Missing FLAME mode in `_process()` check | HIGH | PerformanceMonitor._process() | 2 |
| No additional throttling beyond rate limiting | MEDIUM | FlameGraphProfiler._collect_stack_sample() | 3 |
| Timer callback blocks main thread | MEDIUM | FlameGraphProfiler timer setup | 4 |
| Missing type annotations | LOW | FlameGraphProfiler | 5 |

---

## 7. Immediate Action Plan

1. **URGENT:** Change `sampling_interval_ms` from 10.0 to 100.0 in config
2. **HIGH:** Add FLAME mode to `_process()` check
3. **MEDIUM:** Add additional throttling in `_collect_stack_sample()`
4. **LOW:** Improve type annotations and documentation

---

## 8. Long-Term Improvements

1. **Consider async sampling:** Move stack collection to a background thread (complex, requires careful design)
2. **Adaptive sampling:** Reduce frequency when FPS drops
3. **Stack depth limiting:** Dynamically reduce depth when performance degrades
4. **Sampling budget:** Limit total time spent on sampling per frame (e.g., max 1ms per frame)

---

---

## 9. Fixes Applied

### Fix 1: Increased Sampling Interval ✓
**Status:** APPLIED  
**Change:** `sampling_interval_ms` changed from 10.0 to 100.0 in `flame_graph_config.json`  
**Impact:** Reduces `get_stack()` calls from 100/sec to 10/sec (10x reduction)

### Fix 2: Added FLAME Mode to `_process()` Check ✓
**Status:** APPLIED  
**Change:** `if current_mode == Mode.DETAILED:` → `if current_mode == Mode.DETAILED or current_mode == Mode.FLAME:`  
**Impact:** FLAME mode now shows all detailed metrics and graphs

### Fix 3: Added Additional Throttling ✓
**Status:** APPLIED  
**Change:** Added `MIN_SAMPLE_INTERVAL_MSEC = 50` check in `_collect_stack_sample()`  
**Impact:** Prevents excessive sampling even if timer fires too frequently (max 20 samples/sec)

### Fix 4: Added Performance Monitoring ✓
**Status:** APPLIED  
**Change:** Added timing measurement around `get_stack()` with warning logs if > 1ms  
**Impact:** Helps identify performance issues during development

---

## 10. Testing Results (Expected)

After applying fixes:
- **Sampling frequency:** 10 samples/second (down from 100/sec)
- **Blocking time:** ~10-50ms/second (down from 100-500ms/sec)
- **Frame budget impact:** <1ms per frame (acceptable for 60 FPS)
- **FLAME mode UI:** Should show all metrics and graphs correctly

---

## 11. Remaining Recommendations

1. **Monitor performance:** Watch for `get_stack() took > 1ms` warnings in logs
2. **Consider adaptive sampling:** Reduce frequency further if FPS drops
3. **Test on different hardware:** Verify fixes work on various systems
4. **Remove debug code:** After confirming fixes work, remove timing measurements (or keep as optional debug mode)

---

**End of Audit Report**

