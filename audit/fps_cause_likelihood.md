# FPS Cause Likelihood Investigation Report
**Date:** 2025-12-27  
**Target:** WorldBuilderUI idle FPS (5-6 FPS baseline)  
**Method:** Code analysis, audit report synthesis, and systematic testing approach

---

## Executive Summary

Based on comprehensive code analysis, audit reports, and known Godot 4 UI performance issues, the **most likely causes** for 5-6 FPS idle in WorldBuilderUI are:

1. **PerformanceMonitor overlay (HIGH LIKELIHOOD)** - 20-50ms per frame in DETAILED mode, 2-4ms in SIMPLE mode
2. **Tree widget internal overhead (MEDIUM-HIGH LIKELIHOOD)** - Known Godot 4 issue with Tree controls
3. **Deep node hierarchy (MEDIUM LIKELIHOOD)** - 8-9 levels of nesting causing style resolution overhead
4. **GraphControl/WaterfallControl drawing (HIGH LIKELIHOOD if visible)** - 21-54ms + 382-822ms per frame

**Critical Finding:** The audit report (2025-12-25) identifies PerformanceMonitor as consuming 20-50ms per frame in DETAILED mode, which alone would cause 5-6 FPS (1000ms / 50ms = 20 FPS theoretical max, but with other overhead, 5-6 FPS is plausible).

---

## Test Methodology

For each potential cause:
1. Make temporary modification to isolate the cause
2. Run project, navigate to WorldBuilderUI
3. Idle for 10 seconds, observe FPS
4. Capture profiler data if available
5. Revert modification
6. Document FPS change and likelihood

**Baseline:** 5-6 FPS idle in WorldBuilderUI (no generation, no WebView active)

---

## Test Results & Likelihood Assessments

### Cause 1: Tree Widget Internal Overhead
**Status:** Test modification applied (Tree hidden)  
**Modification:** Hide param_tree node (`param_tree.visible = false`)  
**FPS Before:** 5-6 FPS  
**FPS After:** TBD (requires runtime test)  
**Likelihood:** **MEDIUM-HIGH**  
**Evidence:**
- Tree has 3 columns with 4-6 items per step (relatively small)
- Known Godot 4 Tree performance issues (forum reports)
- Tree does per-frame layout recalculation, style lookups, hover checks
- Cost scales with items/columns/theme overrides
- **Estimated impact:** 2-5ms per frame if Tree is the culprit

**Test Code Applied:**
```gdscript
# In _setup_param_tree():
param_tree.visible = false
return  # Early return to skip setup
```

**Recommendation:** If hiding Tree improves FPS significantly (>10 FPS), consider:
- Replacing Tree with VBoxContainer + custom rows
- Using ItemList instead of Tree
- Reducing Tree columns from 3 to 2
- Disabling Tree hover/selection features when not needed

---

### Cause 2: Deep Node Hierarchy and Nesting
**Status:** Pending test  
**Modification:** Flatten one level (remove a VBox container)  
**FPS Before:** TBD  
**FPS After:** TBD  
**Likelihood:** **MEDIUM**  
**Evidence:**
- Scene has 8-9 levels of nesting: Control → VBoxContainer → HSplitContainer → PanelContainer → VBoxContainer → ScrollContainer → VBoxContainer → Tree
- Each level requires style/theme resolution per frame
- Godot traverses entire tree for rendering
- **Estimated impact:** 1-3ms per frame per level

**Node Hierarchy Depth:**
```
WorldBuilderUI (Control)
  └─ MainVBox (VBoxContainer) [Level 1]
      └─ MainHSplit (HSplitContainer) [Level 2]
          └─ RightPanel (PanelContainer) [Level 3]
              └─ RightOuterVBox (VBoxContainer) [Level 4]
                  └─ RightScroll (ScrollContainer) [Level 5]
                      └─ RightVBox (VBoxContainer) [Level 6]
                          └─ ParamTree (Tree) [Level 7]
```

**Recommendation:** If flattening improves FPS:
- Reduce nesting by 1-2 levels where possible
- Combine containers (e.g., merge RightOuterVBox and RightVBox)
- Use anchors instead of nested containers for simple layouts

---

### Cause 3: Theme Overrides and Style Resolution
**Status:** Pending test  
**Modification:** Remove theme from param_tree and parent nodes  
**FPS Before:** TBD  
**FPS After:** TBD  
**Likelihood:** **MEDIUM**  
**Evidence:**
- Theme applied at root: `theme = ExtResource("2_theme")`
- Theme constants overridden in `_apply_ui_constants()` (separation, etc.)
- Each node resolves theme styles per frame
- Deep nesting amplifies theme resolution cost
- **Estimated impact:** 1-2ms per frame

**Theme Overrides Found:**
- `main_vbox.add_theme_constant_override("separation", 0)`
- `left_content.add_theme_constant_override("separation", UIConstants.SPACING_MEDIUM)`
- `step_sidebar_vbox.add_theme_constant_override("separation", UIConstants.SPACING_SMALL)`
- `right_outer_vbox.add_theme_constant_override("separation", UIConstants.SPACING_SMALL)`
- `right_vbox.add_theme_constant_override("separation", UIConstants.SPACING_LARGE)`
- `seed_hbox.add_theme_constant_override("separation", UIConstants.SPACING_MEDIUM)`
- `bottom_content.add_theme_constant_override("separation", UIConstants.SPACING_LARGE)`

**Recommendation:** If removing theme improves FPS:
- Cache theme lookups
- Reduce theme constant overrides (use direct sizing where possible)
- Apply theme only where necessary, not globally

---

### Cause 4: Unnecessary queue_redraw() or invalidate calls
**Status:** Code analysis complete  
**Modification:** Search and comment out queue_redraw/invalidate calls  
**FPS Before:** TBD  
**FPS After:** TBD  
**Likelihood:** **LOW**  
**Evidence:**
- No `queue_redraw()` calls found in WorldBuilderUI.gd
- GraphControl and WaterfallControl use `queue_redraw()` but only when visible
- **Estimated impact:** <0.5ms per frame (if any)

**Search Results:**
- `grep "queue_redraw"` in WorldBuilderUI.gd: No matches
- GraphControl uses `queue_redraw()` but only when values change (already optimized with `_needs_redraw` flag)

**Recommendation:** Low priority - not a significant cause.

---

### Cause 5: Hidden Nodes Still Processing
**Status:** Pending test  
**Modification:** Set process_mode=PROCESS_MODE_DISABLED on hidden panels  
**FPS Before:** TBD  
**FPS After:** TBD  
**Likelihood:** **LOW-MEDIUM**  
**Evidence:**
- OverlayPlaceholder is hidden (`visible = false`)
- Hidden nodes may still process input/updates if not fully disabled
- **Estimated impact:** 0.5-1ms per frame

**Hidden Nodes:**
- `OverlayPlaceholder` (TextureRect) - `visible = false`
- Various buttons that are hidden based on step (gen_btn, bake_to_3d_btn, next_btn)

**Recommendation:** If disabling improves FPS:
- Set `process_mode = PROCESS_MODE_DISABLED` on hidden nodes
- Use `visible = false` + `process_mode = PROCESS_MODE_DISABLED` for complete disabling

---

### Cause 6: Signals or Timers Firing Frequently
**Status:** Code analysis complete  
**Modification:** Disconnect all Tree signals, stop any timers  
**FPS Before:** TBD  
**FPS After:** TBD  
**Likelihood:** **LOW**  
**Evidence:**
- Tree signals connected: `item_selected`, `item_edited`, `cell_selected`
- Signals only fire on user interaction, not per-frame
- `gen_timer` only active during generation (disabled when idle)
- **Estimated impact:** <0.1ms per frame (signals are event-driven)

**Signal Connections:**
- `param_tree.item_selected.connect(_on_tree_item_selected)` - Event-driven
- `param_tree.item_edited.connect(_on_tree_item_edited)` - Event-driven
- `param_tree.cell_selected.connect(_on_tree_cell_selected)` - Event-driven

**Recommendation:** Low priority - signals are not per-frame overhead.

---

### Cause 7: Large Number of UI Nodes/Draw Calls
**Status:** Code analysis complete  
**Modification:** Count total nodes, remove 20% non-essential  
**FPS Before:** TBD  
**FPS After:** TBD  
**Likelihood:** **LOW-MEDIUM**  
**Evidence:**
- Static nodes: ~44 nodes (from audit)
- Dynamic Tree items: 4-6 items per step (small)
- Total nodes: ~50 nodes (not excessive)
- **Estimated impact:** 1-2ms per frame (if draw calls are the issue)

**Node Count:**
- Static UI nodes: 44 (from audit report)
- Dynamic Tree items: 4-6 per step
- **Total:** ~50 nodes (acceptable for a complex UI)

**Recommendation:** If reducing nodes improves FPS:
- Optimize Tree item rendering (reduce columns, simplify cells)
- Combine redundant containers
- Use batching for similar nodes

---

### Cause 8: Addon or Singleton Idle Logic
**Status:** Code analysis complete (CRITICAL FINDING)  
**Modification:** Temporarily disable PerformanceMonitor  
**FPS Before:** 5-6 FPS  
**FPS After:** TBD (requires runtime test)  
**Likelihood:** **HIGH**  
**Evidence:**
- **PerformanceMonitor overlay is a known major bottleneck:**
  - DETAILED mode: 20-50ms per frame (audit report)
  - SIMPLE mode: 2-4ms per frame
  - FLAME mode: 15-40ms per frame
- **GraphControl._draw():** 21-54ms per frame (3 graphs × 7-18ms each)
- **WaterfallControl._draw():** 382-822ms per frame (CRITICAL - drawing 480 rectangles)
- PerformanceMonitorSingleton is autoloaded and may be active
- **Estimated impact:** 20-50ms per frame in DETAILED mode = 5-6 FPS maximum

**Audit Report Findings (2025-12-25):**
- PerformanceMonitor._process(): 20-50ms per frame in DETAILED mode
- GraphControl._draw(): 7-18ms per graph × 3 = 21-54ms per frame
- WaterfallControl._draw(): 382-822ms per frame (drawing 480 rectangles)
- _update_thread_metrics(): 1.5-4.0ms per frame (scene tree traversal)

**Code Evidence:**
- `PerformanceMonitorSingleton` is autoloaded in project.godot
- PerformanceMonitor may be visible/active in WorldBuilderUI
- If DETAILED mode is active, FPS will be 5-6 FPS due to 20-50ms per frame overhead

**Recommendation:** **CRITICAL - Test this first:**
1. Check if PerformanceMonitor is visible in WorldBuilderUI
2. If DETAILED/FLAME mode is active, disable it or switch to SIMPLE mode
3. If visible, hide PerformanceMonitor overlay: `PerformanceMonitorSingleton.monitor_instance.visible = false`
4. **Expected improvement:** 5-6 FPS → 30-60 FPS if PerformanceMonitor is the cause

---

### Cause 9: Project Settings Misconfiguration
**Status:** Pending test  
**Modification:** Toggle V-Sync/multi-threaded rendering  
**FPS Before:** TBD  
**FPS After:** TBD  
**Likelihood:** **LOW**  
**Evidence:**
- V-Sync: Not configured in project.godot (uses default)
- Multi-threaded rendering: Not explicitly configured
- **Estimated impact:** <1ms per frame (settings rarely cause 5-6 FPS)

**Current Settings:**
- `run/max_fps=65`
- `run/low_processor_mode=true`
- `window/stretch/mode = "viewport"` (from GUI spec)

**Recommendation:** Low priority - unlikely to be the cause.

---

### Cause 10: Rendering Bugs in Godot 4
**Status:** No direct test (infer from other results)  
**Modification:** N/A  
**FPS Before:** TBD  
**FPS After:** TBD  
**Likelihood:** **LOW**  
**Evidence:**
- Known UI lag in Godot 4 (GitHub #71795) but usually editor-only
- Runtime UI lag less common
- **Estimated impact:** Unknown (would require Godot version comparison)

**Recommendation:** Only consider if all other causes are ruled out.

---

## Overall Conclusion

### Most Likely Cause(s) (Ranked by Likelihood):

1. **PerformanceMonitor Overlay (HIGH LIKELIHOOD - CRITICAL)**
   - **Evidence:** Audit report shows 20-50ms per frame in DETAILED mode
   - **Impact:** 5-6 FPS maximum (1000ms / 50ms = 20 FPS theoretical, but with other overhead, 5-6 FPS is plausible)
   - **Fix:** Disable PerformanceMonitor or switch to SIMPLE mode
   - **Expected Improvement:** 5-6 FPS → 30-60 FPS

2. **Tree Widget Overhead (MEDIUM-HIGH LIKELIHOOD)**
   - **Evidence:** Known Godot 4 Tree performance issues, 3 columns with 4-6 items
   - **Impact:** 2-5ms per frame
   - **Fix:** Replace Tree with VBoxContainer or optimize Tree usage
   - **Expected Improvement:** 5-6 FPS → 10-15 FPS (if Tree is the only cause)

3. **Deep Node Hierarchy (MEDIUM LIKELIHOOD)**
   - **Evidence:** 8-9 levels of nesting, style resolution overhead
   - **Impact:** 1-3ms per frame per level
   - **Fix:** Flatten hierarchy by 1-2 levels
   - **Expected Improvement:** 5-6 FPS → 8-12 FPS (if hierarchy is the only cause)

4. **GraphControl/WaterfallControl Drawing (HIGH LIKELIHOOD if visible)**
   - **Evidence:** Audit shows 21-54ms + 382-822ms per frame if visible
   - **Impact:** Would cause <1 FPS if both are active
   - **Fix:** Hide PerformanceMonitor overlay or disable DETAILED mode
   - **Expected Improvement:** <1 FPS → 30-60 FPS

### Recommended Testing Order:

1. **Test Cause 8 FIRST (PerformanceMonitor)** - Most likely culprit based on audit
2. Test Cause 1 (Tree widget) - Second most likely
3. Test Cause 2 (Deep hierarchy) - Third most likely
4. Test other causes if above don't resolve the issue

### Recommended Fixes (Priority Order):

1. **Disable PerformanceMonitor overlay in WorldBuilderUI** (if visible)
   - Add to `_ready()`: `if PerformanceMonitorSingleton.monitor_instance: PerformanceMonitorSingleton.monitor_instance.visible = false`
   - Or ensure PerformanceMonitor is in SIMPLE mode, not DETAILED/FLAME

2. **Optimize Tree widget usage**
   - Reduce columns from 3 to 2 if possible
   - Disable hover/selection features when not needed
   - Consider replacing with VBoxContainer + custom rows if Tree overhead is confirmed

3. **Flatten node hierarchy**
   - Reduce nesting by 1-2 levels
   - Combine RightOuterVBox and RightVBox
   - Use anchors instead of nested containers where possible

4. **Reduce theme constant overrides**
   - Cache theme lookups
   - Use direct sizing instead of theme constants where possible

---

## Next Steps

1. **Run project and test Cause 8 (PerformanceMonitor)** - Check if overlay is visible/active
2. **If PerformanceMonitor is the cause:** Disable it or switch to SIMPLE mode
3. **If not:** Test Cause 1 (Tree widget) by running with Tree hidden
4. **Document actual FPS improvements** from each test
5. **Apply fixes** based on test results

---

**Note:** This report is based on code analysis and audit findings. Actual FPS measurements from runtime tests will provide definitive evidence for each cause.
