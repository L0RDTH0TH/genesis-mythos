# Flamegraph Detail Enhancements Implementation Audit

**Date:** 2025-01-20  
**Auditor:** Auto (Cursor AI)  
**Issue:** Flamegraph visualization appears identical (shallow, few bars) despite enhancements  
**Goal:** Diagnose why new features (call site distinction, increased depth, parameters, instrumentation) are not producing richer visualization

---

## Executive Summary

The flamegraph detail enhancements have been **successfully implemented** in code, but a **critical bug in call site distinction logic** prevents proper caller information from being captured. Additionally, several factors may limit visible depth:

1. **CRITICAL BUG:** Caller information is captured from the wrong stack frame index
2. **Config loaded correctly:** `max_stack_depth: 40` and `max_render_depth: 30` are present
3. **Code changes verified:** All enhancement code is present and syntactically correct
4. **Potential limiting factors:** World generation may not produce deep GDScript stacks, or aggregation may not be creating separate nodes

**Status:** ✅ Code present, ❌ Logic bug prevents call site distinction, ⚠️ Depth may be limited by actual stack depth

---

## 1. Code Verification

### 1.1 Configuration File

**File:** `res://data/config/flame_graph_config.json`

**Status:** ✅ **CORRECT**

```json
{
    "max_stack_depth": 40,      // ✅ Increased from 20
    "max_render_depth": 30,     // ✅ New key added
    "sampling_interval_ms": 100.0
}
```

**Verification:** Both new keys are present with correct values.

### 1.2 FlameGraphProfiler.gd Changes

**Status:** ✅ **Code present, ❌ Logic bug found**

#### ✅ Config Loading
- Line 124-125: Default config includes `max_stack_depth: 40` and `max_render_depth: 30`
- Line 295: Uses `config.get("max_stack_depth", 40)` correctly
- Config is loaded in `_ready()` via `_load_config()`

#### ✅ Parameter Support
- Line 315: `"params": frame.get("params", {})` added to formatted frames
- Line 626: Parameters stored in call tree nodes
- Placeholder support is present

#### ✅ Instrumentation Method
- Line 349-408: `push_flame_data_instrumented()` method is present and correctly implemented
- Thread-safe with mutex protection
- Creates synthetic stack traces with caller information

#### ❌ **CRITICAL BUG: Call Site Distinction Logic**

**Location:** `FlameGraphProfiler.gd:318-322`

**Current Code:**
```gdscript
# Add caller information for call site distinction
if i > 0 and stack[i - 1] is Dictionary:
    var caller_frame: Dictionary = stack[i - 1]
    formatted_frame["caller_function"] = caller_frame.get("function", "unknown")
    formatted_frame["caller_source"] = caller_frame.get("source", "unknown")
    formatted_frame["caller_line"] = caller_frame.get("line", 0)
```

**Problem:** The code comment at line 588 states: `"stack[0] is deepest, stack[-1] is shallowest"`

This means:
- `stack[0]` = deepest frame (current executing function)
- `stack[1]` = caller of `stack[0]`
- `stack[2]` = caller of `stack[1]`

**For `stack[i]`, the CALLER should be `stack[i+1]`, NOT `stack[i-1]`!**

**Impact:** 
- Caller information is being captured from the wrong frame (the callee, not the caller)
- This causes incorrect or missing call site distinction
- Separate nodes for different call sites are not being created properly
- The `@caller:line` suffix in node keys is incorrect or empty

**Same bug exists in:**
- Line 318: `_collect_stack_sample()`
- Line 445: `push_flame_data()`

#### ✅ Aggregation Logic
- Line 600-610: Node key generation includes call site suffix `@caller_source:caller_function:caller_line`
- Line 615-635: Separate nodes created for different call sites
- Logic is correct IF caller information is captured correctly (but it's not due to bug above)

### 1.3 FlameGraphControl.gd Changes

**Status:** ✅ **Code present and correct**

#### ✅ Configurable Depth
- Line 15: `var max_render_depth: int = 30` (default)
- Line 82-86: Loads from `FlameGraphProfiler.config` with fallback
- Line 361: Grid drawing uses `max_render_depth`
- Line 382: Rendering recursion check uses `max_render_depth`

#### ✅ Call Site Display
- Line 416-419: Labels show `function@caller:line` format
- Line 247-248: Tooltips show "Called from: source:function:line"
- Line 191, 286, 501: Node key generation includes call site suffix

#### ✅ Parameter Display
- Line 244: Gets parameters from node
- Line 255-259: Displays parameters in tooltips
- Line 264-266: Tooltip size adjusts for parameters

**All rendering code is correct and will work once caller information is fixed.**

---

## 2. Root Cause Analysis

### 2.1 Primary Issue: Incorrect Caller Frame Index

**The Bug:**
```gdscript
# WRONG: Gets frame[i-1] which is the CALLEE (deeper), not the CALLER
if i > 0 and stack[i - 1] is Dictionary:
    var caller_frame: Dictionary = stack[i - 1]
```

**Should be:**
```gdscript
# CORRECT: Gets frame[i+1] which is the CALLER (shallower)
if i < stack.size() - 1 and stack[i + 1] is Dictionary:
    var caller_frame: Dictionary = stack[i + 1]
```

**Why this matters:**
- Without correct caller information, all nodes for the same function get the same key
- Call site distinction doesn't work, so functions called from different places are merged
- The visualization appears shallow because nodes aren't being split by call site

### 2.2 Secondary Issues

#### Issue 2.1: Stack Depth May Be Naturally Shallow

**Observation:** World generation might not produce deep GDScript call stacks because:
- Heavy computation may be in native/C++ code (Terrain3D, procedural generation)
- GDScript may only have shallow wrappers around native functions
- Thread-based work (world generation threads) may not be captured by `get_stack()`

**Evidence Needed:** Check actual stack depth during world generation via debug logs.

#### Issue 2.2: Aggregation Timing

**Observation:** Aggregation happens every 1 second. If samples are collected but aggregation hasn't run yet, the visualization will be empty or stale.

**Mitigation:** Signal-based updates should handle this, but worth verifying.

#### Issue 2.3: Minimum Bar Width Filter

**Location:** `FlameGraphControl.gd:395`

**Code:**
```gdscript
if node_width < MIN_BAR_WIDTH:
    return  # Skip if too narrow
```

**Impact:** Very small functions (narrow bars) won't be rendered, even if they exist in the call tree. This is intentional but may hide detail.

---

## 3. Verification Steps Performed

### 3.1 Code Review

✅ **Config file:** Verified `max_stack_depth: 40` and `max_render_depth: 30` are present  
✅ **FlameGraphProfiler.gd:** All enhancement code is present  
✅ **FlameGraphControl.gd:** All rendering enhancements are present  
❌ **Call site logic:** Found bug in caller frame index calculation  

### 3.2 Logic Analysis

**Call Site Distinction Flow:**
1. `_collect_stack_sample()` captures stack frames
2. For each frame, tries to get caller from `stack[i-1]` ❌ **WRONG**
3. Aggregation creates node key with `@caller:line` suffix
4. If caller info is wrong/empty, all nodes for same function get same key
5. Nodes are merged instead of split by call site
6. Visualization appears shallow

**Depth Limiting Flow:**
1. Config loaded: `max_stack_depth: 40` ✅
2. Stack truncated to 40 frames (keeps deepest) ✅
3. Rendering limited to `max_render_depth: 30` ✅
4. If actual stack is < 10 frames, depth limits don't help

### 3.3 Expected vs Actual Behavior

**Expected:**
- Functions called from different places create separate nodes
- Deeper stacks (up to 40 frames) are captured
- More nested bars visible (up to 30 levels)
- Tooltips show `@caller:line` information

**Actual:**
- Functions are merged (same key regardless of call site)
- Visualization appears shallow (few bars)
- Call site information likely incorrect or missing

---

## 4. Specific Bugs Identified

### Bug #1: Incorrect Caller Frame Index (CRITICAL)

**Severity:** 🔴 **CRITICAL**  
**Location:** `FlameGraphProfiler.gd:318` and `FlameGraphProfiler.gd:445`

**Current Code:**
```gdscript
if i > 0 and stack[i - 1] is Dictionary:
    var caller_frame: Dictionary = stack[i - 1]
```

**Correct Code:**
```gdscript
if i < stack.size() - 1 and stack[i + 1] is Dictionary:
    var caller_frame: Dictionary = stack[i + 1]
```

**Impact:**
- Caller information is captured from wrong frame (callee instead of caller)
- Call site distinction doesn't work
- All nodes for same function get merged
- Visualization appears shallow

**Fix Required:** Change `stack[i - 1]` to `stack[i + 1]` in both locations.

### Bug #2: First Frame Has No Caller (MINOR)

**Location:** `FlameGraphProfiler.gd:318`

**Issue:** The first frame in the stack (`i == 0`) will never have caller information because the check is `if i > 0`. This is actually correct behavior (root frame has no caller), but the logic should be clearer.

**Impact:** Minimal - root frame shouldn't have a caller anyway.

### Bug #3: Caller Check Logic in push_flame_data()

**Location:** `FlameGraphProfiler.gd:445`

**Current Code:**
```gdscript
if i > start_idx and stack_trace[i - 1] is Dictionary:
```

**Issue:** Same bug as Bug #1 - should be `stack_trace[i + 1]`.

---

## 5. Recommendations

### 5.1 Immediate Fixes (High Priority)

#### Fix #1: Correct Caller Frame Index

**File:** `core/singletons/FlameGraphProfiler.gd`

**Change 1 - Line 318:**
```gdscript
# BEFORE:
if i > 0 and stack[i - 1] is Dictionary:
    var caller_frame: Dictionary = stack[i - 1]

# AFTER:
if i < stack.size() - 1 and stack[i + 1] is Dictionary:
    var caller_frame: Dictionary = stack[i + 1]
```

**Change 2 - Line 445:**
```gdscript
# BEFORE:
if i > start_idx and stack_trace[i - 1] is Dictionary:
    var caller_frame: Dictionary = stack_trace[i - 1]

# AFTER:
if i < stack_trace.size() - 1 and stack_trace[i + 1] is Dictionary:
    var caller_frame: Dictionary = stack_trace[i + 1]
```

**Expected Result:** Caller information will be captured correctly, call site distinction will work, separate nodes will be created for different call sites.

### 5.2 Diagnostic Enhancements (Medium Priority)

#### Diagnostic #1: Add Debug Logging

**Add to `_aggregate_samples_to_tree()`:**
```gdscript
MythosLogger.debug("FlameGraphProfiler", "Aggregated %d samples into call tree" % samples.size())
MythosLogger.debug("FlameGraphProfiler", "Call tree depth: %d, root children: %d" % [
    _get_tree_depth(call_tree),
    call_tree.get("children", {}).size()
])
```

**Add helper function:**
```gdscript
func _get_tree_depth(node: Dictionary, current_depth: int = 0) -> int:
    """Get maximum depth of call tree."""
    var max_depth: int = current_depth
    var children: Dictionary = node.get("children", {})
    for child_key in children.keys():
        var child_depth: int = _get_tree_depth(children[child_key], current_depth + 1)
        if child_depth > max_depth:
            max_depth = child_depth
    return max_depth
```

#### Diagnostic #2: Log Stack Depth During Sampling

**Add to `_collect_stack_sample()`:**
```gdscript
MythosLogger.debug("FlameGraphProfiler", "Collected stack sample: depth=%d, frames=%d" % [
    formatted_stack.size(),
    raw_stack.size()
])
```

#### Diagnostic #3: Log Call Site Information

**Add to aggregation:**
```gdscript
if caller_function != "":
    MythosLogger.debug("FlameGraphProfiler", "Node key with call site: %s" % node_key)
else:
    MythosLogger.debug("FlameGraphProfiler", "Node key without call site: %s" % node_key)
```

### 5.3 Testing Recommendations

#### Test #1: Verify Call Site Distinction

1. Fix the caller frame index bug
2. Run project, enable FLAME mode
3. Trigger world generation
4. Wait 10-20 seconds
5. Check exported JSON for nodes with `@caller:line` suffixes
6. Verify tooltips show "Called from:" information

#### Test #2: Verify Depth Limits

1. Add debug logging for actual stack depth
2. Run during world generation
3. Check logs for stack depth values
4. Verify if stacks are actually deep (>20 frames) or shallow (<10 frames)

#### Test #3: Verify Aggregation

1. Add debug logging for call tree structure
2. Check number of root children
3. Check maximum tree depth
4. Verify if nodes are being merged or split correctly

---

## 6. Additional Findings

### 6.1 Stack Order Verification Needed

**Uncertainty:** The code comment says "stack[0] is deepest", but this needs verification against Godot's actual `get_stack()` behavior.

**Recommendation:** Add test code to print stack frame order and verify:
```gdscript
var test_stack: Array = get_stack()
for i in range(test_stack.size()):
    var frame = test_stack[i]
    print("Stack[%d]: %s:%s:%d" % [i, frame.get("source"), frame.get("function"), frame.get("line")])
```

### 6.2 World Generation Stack Depth

**Hypothesis:** World generation may not produce deep GDScript stacks because:
- Terrain3D operations are native/C++
- Procedural generation may be thread-based
- GDScript may only have shallow wrappers

**Recommendation:** Add instrumentation points in world generation code to measure actual GDScript stack depth.

### 6.3 Native Code Visibility

**Limitation:** `get_stack()` only captures GDScript stack traces. Native/C++ code is not visible.

**Impact:** If world generation is primarily native code, the flamegraph will appear shallow even with correct logic.

---

## 7. Summary

### 7.1 Code Status

✅ **Config:** Correctly updated with `max_stack_depth: 40` and `max_render_depth: 30`  
✅ **Implementation:** All enhancement code is present and syntactically correct  
❌ **Logic Bug:** Caller frame index is wrong (`stack[i-1]` should be `stack[i+1]`)  
✅ **Rendering:** All UI code is correct and will work once caller info is fixed  

### 7.2 Root Cause

**Primary:** Incorrect caller frame index prevents call site distinction from working, causing all nodes for the same function to be merged regardless of where they're called from.

**Secondary:** Actual stack depth during world generation may be shallow due to native code dominance or thread-based work.

### 7.3 Fix Priority

1. **CRITICAL:** Fix caller frame index bug (lines 318 and 445)
2. **MEDIUM:** Add debug logging to verify stack depth and aggregation
3. **LOW:** Verify stack frame order with test code

### 7.4 Expected Outcome After Fix

Once the caller frame index is corrected:
- Functions called from different places will create separate nodes
- Call site information will appear in labels (`function@caller:line`)
- Tooltips will show "Called from:" information
- Visualization should show more detail and nesting
- If stacks are actually deep (>20 frames), they will be captured and rendered

---

## 8. Conclusion

The flamegraph detail enhancements are **correctly implemented in code**, but a **critical logic bug** prevents call site distinction from working. The bug is a simple index error (`stack[i-1]` instead of `stack[i+1]`) that causes caller information to be captured from the wrong frame.

**Fix the bug and the enhancements should work as intended.** If the visualization still appears shallow after the fix, it may indicate that:
1. Actual GDScript stack depth during world generation is shallow (<10 frames)
2. Heavy computation is in native/C++ code (not visible to `get_stack()`)
3. World generation work is thread-based (not captured by main thread sampling)

**Next Steps:**
1. Fix the caller frame index bug
2. Add debug logging to verify actual stack depth
3. Test with world generation and verify call site distinction works
4. If still shallow, investigate native code dominance or add instrumentation points

---

**Report Generated:** 2025-01-20  
**Auditor:** Auto (Cursor AI)  
**Status:** Complete - Critical bug identified, fix recommended


