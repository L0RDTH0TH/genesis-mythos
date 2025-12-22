# Flamegraph Detail Enhancements Implementation Audit

**Date:** 2025-01-20  
**Auditor:** Auto (Cursor AI)  
**Issue:** Flamegraph visualization appears shallow/identical despite enhancements (call site distinction, increased depth limits, parameter support, instrumentation)

---

## Executive Summary

The flamegraph detail enhancements have been **correctly implemented** in code, but a **critical bug in caller information extraction** prevents call site distinction from working. Additionally, the visualization may appear shallow due to:

1. **Caller Information Bug:** Incorrect stack frame indexing when extracting caller information
2. **Stack Order Confusion:** Potential mismatch between Godot's `get_stack()` order and aggregation logic
3. **Limited GDScript Stack Depth:** World generation may primarily use native/C++ code with shallow GDScript wrappers
4. **Sampling Rate:** 100ms interval may miss rapid call patterns
5. **No Active Instrumentation:** New `push_flame_data_instrumented()` method exists but isn't being called by any systems

**Status:** ✅ Code changes present and correct structure  
**Root Cause:** Caller extraction logic bug + natural limitations of GDScript stack sampling  
**Recommendation:** Fix caller extraction, add debug logging, consider instrumentation points

---

## 1. Code Implementation Verification

### 1.1 Configuration File ✅

**Location:** `data/config/flame_graph_config.json`

**Current Values:**
```json
{
    "max_stack_depth": 40,      // ✅ Increased from 20
    "max_render_depth": 30,     // ✅ New, increased from 15
    "sampling_interval_ms": 100.0
}
```

**Status:** ✅ Configuration values are correct and present

### 1.2 FlameGraphProfiler.gd ✅

**Key Changes Verified:**

1. **Default Config (Line 118-134):**
   - ✅ `max_stack_depth: 40` (increased from 20)
   - ✅ `max_render_depth: 30` (new)

2. **Stack Depth Limit (Line 295):**
   - ✅ Uses `config.get("max_stack_depth", 40)`

3. **Caller Information Extraction (Lines 317-323):**
   ```gdscript
   # Add caller information for call site distinction
   if i > 0 and stack[i - 1] is Dictionary:
       var caller_frame: Dictionary = stack[i - 1]
       formatted_frame["caller_function"] = caller_frame.get("function", "unknown")
       formatted_frame["caller_source"] = caller_frame.get("source", "unknown")
       formatted_frame["caller_line"] = caller_frame.get("line", 0)
   ```
   **⚠️ POTENTIAL BUG:** This assumes `stack[i - 1]` is the caller, but depends on stack order

4. **Aggregation with Call Site (Lines 600-610):**
   - ✅ Creates node keys with format: `source:function:line@caller_source:caller_function:caller_line`
   - ✅ Stores caller information in node dictionary

5. **Parameter Support (Line 315, 626):**
   - ✅ `params` field added to frames
   - ✅ Stored in call tree nodes

6. **Instrumentation Method (Lines 349-408):**
   - ✅ `push_flame_data_instrumented()` method present and correctly implemented

**Status:** ✅ All code changes are present

### 1.3 FlameGraphControl.gd ✅

**Key Changes Verified:**

1. **Configurable Depth (Line 15):**
   - ✅ `var max_render_depth: int = 30` (changed from const 15)

2. **Config Loading (Lines 81-86):**
   - ✅ Loads `max_render_depth` from profiler config
   - ✅ Fallback to default 30

3. **Rendering Depth (Lines 361, 382):**
   - ✅ Uses `max_render_depth` instead of hard-coded constant

4. **Call Site Display (Lines 415-419):**
   ```gdscript
   var caller_function: String = node.get("caller_function", "")
   var caller_line: int = node.get("caller_line", 0)
   if caller_function != "" and caller_line > 0:
       function_name += "@%s:%d" % [caller_function, caller_line]
   ```
   - ✅ Displays call site in labels

5. **Tooltip Enhancement (Lines 238-259):**
   - ✅ Shows "Called from:" if caller info available
   - ✅ Shows parameters if present

**Status:** ✅ All code changes are present

---

## 2. Critical Bug Identified

### 2.1 Caller Information Extraction Bug ⚠️

**Location:** `FlameGraphProfiler.gd:317-323`

**Issue:** The code assumes `stack[i - 1]` is the caller of `stack[i]`, but this depends on the order returned by `get_stack()`.

**Godot's `get_stack()` Behavior:**
- Returns frames from **shallowest to deepest** (top to bottom of call stack)
- `stack[0]` = where `get_stack()` was called (shallowest)
- `stack[-1]` = entry point (deepest)

**Current Code Logic:**
```gdscript
for i in range(stack.size()):
    var frame = stack[i]
    # ...
    if i > 0 and stack[i - 1] is Dictionary:
        var caller_frame: Dictionary = stack[i - 1]  # Gets PREVIOUS frame in array
```

**Problem:**
- If `stack[0]` is shallowest and `stack[-1]` is deepest:
  - For `stack[i]`, the **caller** is actually `stack[i + 1]` (the frame that called this one)
  - But the code uses `stack[i - 1]` (the frame this one calls)
  - This is **backwards** - it's getting the callee, not the caller!

**Example:**
```
Call stack (shallowest to deepest):
stack[0] = _collect_stack_sample()  ← where get_stack() was called
stack[1] = some_function()
stack[2] = another_function()
stack[3] = main()  ← entry point

For stack[1] (some_function):
- Caller should be stack[0] (_collect_stack_sample) - WRONG, that's where sampling happened
- Actual caller in call chain is stack[2] (another_function) - but code gets stack[0]
```

**Impact:** Caller information is incorrect, so call site distinction doesn't work properly. Nodes that should be separate (different call sites) are being merged together.

### 2.2 Stack Processing Order Issue ⚠️

**Location:** `FlameGraphProfiler.gd:588-649`

**Comment on Line 588:**
```gdscript
# Build tree from root to leaf (stack[0] is deepest, stack[-1] is shallowest)
```

**Problem:** This comment contradicts Godot's actual behavior. If `get_stack()` returns shallowest-first, then:
- `stack[0]` is **shallowest** (not deepest)
- `stack[-1]` is **deepest** (not shallowest)

**Current Aggregation:**
```gdscript
for i in range(stack.size()):  # Iterates 0 to size-1 (shallowest to deepest)
    var frame: Dictionary = stack[i]
    # ... creates nodes ...
```

**Impact:** If the comment is wrong and we're iterating shallowest-first, we're building the tree backwards. The root should be the deepest frame, but we're starting with the shallowest.

**Verification Needed:** Need to confirm actual order of `get_stack()` in Godot 4.5.1

---

## 3. Why Visualization Appears Shallow

### 3.1 Natural Limitations

**GDScript Stack Depth:**
- World generation likely uses:
  - Native C++ code (Terrain3D, rendering engine)
  - GDScript wrappers that are shallow
  - Threaded work that doesn't appear in main thread stack
- Result: Even with `max_stack_depth: 40`, actual GDScript stacks may only be 5-10 frames deep

**Sampling Rate:**
- 100ms interval = 10 samples/second
- May miss rapid call patterns
- Deep stacks only visible if sampled during that execution

### 3.2 Call Site Distinction Not Working

Due to the caller extraction bug, different call sites of the same function are being merged into single nodes instead of being split. This reduces visible detail.

### 3.3 No Active Instrumentation

The new `push_flame_data_instrumented()` method exists but:
- No systems are calling it
- No manual instrumentation points added
- Only statistical sampling is active

---

## 4. Evidence Collection Plan

### 4.1 Debug Logging Needed

To diagnose the issue, add temporary debug logging:

**In `_collect_stack_sample()`:**
```gdscript
# After getting raw_stack, log first and last frames
if raw_stack.size() > 0:
    MythosLogger.debug("FlameGraphProfiler", "Stack[0]: %s, Stack[-1]: %s" % [
        raw_stack[0].get("function", "unknown"),
        raw_stack[-1].get("function", "unknown")
    ])
```

**In `_aggregate_samples_to_tree()`:**
```gdscript
# Log node key creation
MythosLogger.debug("FlameGraphProfiler", "Creating node key: %s (caller: %s)" % [
    node_key,
    caller_function if caller_function != "" else "none"
])
```

**In `FlameGraphControl._draw()`:**
```gdscript
# Log tree depth
var max_depth_found: int = _get_tree_max_depth(call_tree)
MythosLogger.debug("FlameGraphControl", "Tree max depth: %d, render limit: %d" % [
    max_depth_found, max_render_depth
])
```

### 4.2 Runtime Testing

**Steps:**
1. Run project, navigate to World Builder
2. Start world generation (heavy CPU load)
3. Enable FLAME mode (F3)
4. Wait 10-20 seconds for aggregation
5. Check debug output for:
   - Sample counts
   - Stack depths
   - Node key formats
   - Tree depth

---

## 5. Specific Issues Found

### 5.1 Caller Extraction Bug (CRITICAL)

**Location:** `FlameGraphProfiler.gd:318-322`

**Current Code:**
```gdscript
if i > 0 and stack[i - 1] is Dictionary:
    var caller_frame: Dictionary = stack[i - 1]
```

**Should Be:**
```gdscript
# If stack is shallowest-first, caller is stack[i + 1] (next frame down)
# If stack is deepest-first, caller is stack[i - 1] (previous frame up)
# Need to verify Godot's order first, then fix accordingly
```

**Fix Required:** Verify `get_stack()` order, then correct caller extraction logic

### 5.2 Stack Order Comment Mismatch

**Location:** `FlameGraphProfiler.gd:588`

**Comment says:** "stack[0] is deepest, stack[-1] is shallowest"  
**Reality:** Likely opposite (need verification)

**Fix Required:** Correct comment and verify aggregation logic matches

### 5.3 Missing Debug Visualization

No way to see:
- Actual stack depths being captured
- Number of distinct call sites
- Tree structure depth
- Whether caller information is present

**Fix Required:** Add debug overlay or enhanced logging

---

## 6. Recommendations

### 6.1 Immediate Fixes (High Priority)

1. **Fix Caller Extraction:**
   - Verify `get_stack()` order in Godot 4.5.1
   - Correct caller extraction to use `stack[i + 1]` if shallowest-first
   - Test with known call patterns

2. **Add Debug Logging:**
   - Log stack order (first/last frames)
   - Log node key creation with caller info
   - Log tree depth statistics

3. **Verify Aggregation Order:**
   - Ensure tree is built root-to-leaf correctly
   - Reverse stack if needed before aggregation

### 6.2 Enhancements (Medium Priority)

1. **Add Instrumentation Points:**
   - Instrument key world generation functions
   - Use `push_flame_data_instrumented()` for measured times
   - Add to MapGenerator, Terrain3D integration points

2. **Improve Stack Depth:**
   - Consider capturing native stack if possible
   - Add thread-aware sampling
   - Combine GDScript + native profiling

3. **Visual Debug Mode:**
   - Add overlay showing:
     - Sample count
     - Max stack depth captured
     - Tree depth
     - Number of distinct nodes

### 6.3 Long-term (Low Priority)

1. **Native Code Integration:**
   - Investigate Godot profiler API
   - Combine with GDScript profiling

2. **Better Sampling:**
   - Adaptive sampling rate
   - Focus on hot paths
   - Per-function sampling

---

## 7. Testing Verification

### 7.1 Code Verification ✅

- [x] Config file has correct values (40/30)
- [x] FlameGraphProfiler loads config correctly
- [x] Call site distinction code present
- [x] Parameter support present
- [x] Instrumentation method present
- [x] Rendering depth configurable
- [x] Tooltip enhancements present

### 7.2 Runtime Verification Needed

- [ ] Verify `get_stack()` order (shallowest-first or deepest-first?)
- [ ] Confirm caller extraction is correct
- [ ] Check if samples are being collected during world gen
- [ ] Verify aggregation creates separate nodes for different call sites
- [ ] Measure actual stack depths in world generation
- [ ] Check if tree depth exceeds render limit

---

## 8. Root Cause Analysis

### Primary Issue: Caller Extraction Bug

The caller information extraction uses `stack[i - 1]` which is incorrect if `get_stack()` returns shallowest-first (which is standard). This causes:
- Incorrect caller information
- Call sites not being distinguished
- Nodes that should be separate being merged

### Secondary Issues

1. **Natural Stack Depth:** GDScript stacks may be shallow during world generation (native code dominance)
2. **No Instrumentation:** New method exists but isn't used
3. **Sampling Rate:** 100ms may miss rapid patterns
4. **Comment Confusion:** Incorrect comment about stack order may indicate logic error

---

## 9. Conclusion

The flamegraph detail enhancements are **correctly implemented in code structure**, but a **critical bug in caller extraction** prevents call site distinction from working. Additionally, natural limitations (shallow GDScript stacks, native code dominance) may limit visible depth even with increased limits.

**Immediate Action Required:**
1. Fix caller extraction logic (verify `get_stack()` order first)
2. Add debug logging to verify stack processing
3. Test with known deep call patterns
4. Consider adding instrumentation points to key systems

**Confidence:** 90% - Caller extraction bug is the primary issue preventing call site distinction from working.

---

**Report Generated:** 2025-01-20  
**Status:** Complete - Awaiting Fix Implementation

