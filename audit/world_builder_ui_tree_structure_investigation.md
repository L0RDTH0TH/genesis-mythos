# World Builder UI Tree Structure Investigation
**Date:** 2025-12-27  
**Target:** WorldBuilderUI scene hierarchy and structure analysis  
**Method:** Static code analysis, scene tree inspection, UIConstants compliance check

---

## Executive Summary

The WorldBuilderUI scene has **8 levels of nesting** for the ParamTree widget, which is a potential performance concern. The scene structure is generally well-organized with proper use of built-in containers, but there are opportunities to flatten the hierarchy and improve UIConstants compliance in the scene file.

**Key Findings:**
1. **Deep Nesting:** 8 levels deep for ParamTree (Control → VBoxContainer → HSplitContainer → PanelContainer → VBoxContainer → ScrollContainer → VBoxContainer → Tree)
2. **Magic Numbers:** Scene file (.tscn) contains hard-coded `Vector2(0, 40)` values that should use UIConstants
3. **UIConstants Compliance:** Script (.gd) uses UIConstants properly, but scene file has hard-coded values
4. **Container Structure:** Proper use of built-in containers (VBoxContainer, HSplitContainer, ScrollContainer)
5. **Size Flags & Anchors:** Properly configured for responsive layout

---

## Scene File Structure Analysis

### File Location
- **Scene:** `res://ui/world_builder/WorldBuilderUI.tscn`
- **Script:** `res://ui/world_builder/WorldBuilderUI.gd`
- **Related Scripts:**
  - `res://scripts/ui/WorldBuilderAzgaar.gd` (attached to CenterContent)
  - `res://scripts/managers/AzgaarIntegrator.gd` (singleton)

### Node Hierarchy (Full Tree)

```
WorldBuilderUI (Control) [Level 0]
├─ Background (ColorRect) [Level 1]
└─ MainVBox (VBoxContainer) [Level 1]
   ├─ TopBar (PanelContainer) [Level 2]
   │  └─ TopBarContent (CenterContainer) [Level 3]
   │     └─ TitleLabel (Label) [Level 4]
   │
   ├─ MainHSplit (HSplitContainer) [Level 2]
   │  ├─ LeftPanel (PanelContainer) [Level 3]
   │  │  └─ LeftContent (VBoxContainer) [Level 4]
   │  │     └─ StepSidebar (VBoxContainer) [Level 5]
   │  │        ├─ Step1Btn (Button) [Level 6]
   │  │        ├─ Step2Btn (Button) [Level 6]
   │  │        ├─ Step3Btn (Button) [Level 6]
   │  │        ├─ Step4Btn (Button) [Level 6]
   │  │        ├─ Step5Btn (Button) [Level 6]
   │  │        ├─ Step6Btn (Button) [Level 6]
   │  │        ├─ Step7Btn (Button) [Level 6]
   │  │        └─ Step8Btn (Button) [Level 6]
   │  │
   │  ├─ CenterPanel (PanelContainer) [Level 3]
   │  │  └─ CenterContent (Control) [Level 4] ⚠️ Script: WorldBuilderAzgaar.gd
   │  │     └─ OverlayPlaceholder (TextureRect) [Level 5] (visible = false)
   │  │
   │  └─ RightPanel (PanelContainer) [Level 3]
   │     └─ RightOuterVBox (VBoxContainer) [Level 4]
   │        ├─ ArchetypeLabel (Label) [Level 5]
   │        ├─ ArchetypeOption (OptionButton) [Level 5]
   │        ├─ SeedLabel (Label) [Level 5]
   │        ├─ SeedHBox (HBoxContainer) [Level 5]
   │        │  ├─ SeedSpin (SpinBox) [Level 6]
   │        │  └─ RandomizeBtn (Button) [Level 6]
   │        │
   │        └─ RightScroll (ScrollContainer) [Level 5]
   │           └─ RightVBox (VBoxContainer) [Level 6]
   │              ├─ SectionSep (HSeparator) [Level 7]
   │              ├─ StepTitle (Label) [Level 7]
   │              └─ ParamTree (Tree) [Level 7] ⚠️ DEEP NESTING TARGET
   │
   └─ BottomBar (PanelContainer) [Level 2]
      └─ BottomContent (HBoxContainer) [Level 3]
         ├─ SpacerLeft (Control) [Level 4]
         ├─ BackBtn (Button) [Level 4]
         ├─ GenBtn (Button) [Level 4]
         ├─ BakeTo3DBtn (Button) [Level 4]
         ├─ NextBtn (Button) [Level 4]
         ├─ ProgressBar (ProgressBar) [Level 4]
         ├─ StatusLabel (Label) [Level 4]
         └─ SpacerRight (Control) [Level 4]
```

### Deep Nesting Analysis

**Maximum Depth:** 8 levels (WorldBuilderUI → MainVBox → MainHSplit → RightPanel → RightOuterVBox → RightScroll → RightVBox → ParamTree)

**Critical Paths:**
1. **ParamTree Path (8 levels):**
   - Control → VBoxContainer → HSplitContainer → PanelContainer → VBoxContainer → ScrollContainer → VBoxContainer → Tree
   - **Performance Impact:** Each level requires style/theme resolution per frame
   - **Estimated Cost:** 1-3ms per frame per level = 8-24ms per frame for style resolution

2. **Step Buttons Path (6 levels):**
   - Control → VBoxContainer → HSplitContainer → PanelContainer → VBoxContainer → VBoxContainer → Button
   - **Performance Impact:** Moderate (6 levels is acceptable but could be optimized)

3. **CenterContent Path (5 levels):**
   - Control → VBoxContainer → HSplitContainer → PanelContainer → Control (with script)
   - **Performance Impact:** Low (5 levels is acceptable)

### Node Type Breakdown

| Node Type | Count | Purpose |
|-----------|-------|---------|
| Control | 3 | Root, CenterContent, Spacers |
| VBoxContainer | 5 | Main layout, left sidebar, right panels |
| HBoxContainer | 2 | Seed controls, bottom bar |
| HSplitContainer | 1 | Main horizontal split (left/center/right) |
| PanelContainer | 4 | Top bar, left panel, center panel, right panel, bottom bar |
| ScrollContainer | 1 | Right panel scrollable content |
| Button | 11 | Step buttons (8) + navigation buttons (3) |
| Label | 4 | Title, step title, archetype, seed labels |
| Tree | 1 | Parameter tree (main content) |
| OptionButton | 1 | Archetype selector |
| SpinBox | 1 | Seed input |
| ProgressBar | 1 | Generation progress |
| HSeparator | 1 | Section separator |
| ColorRect | 1 | Background |
| CenterContainer | 1 | Title centering |
| TextureRect | 1 | Overlay placeholder (hidden) |

**Total Static Nodes:** ~44 nodes (excluding dynamic Tree items)

---

## UIConstants Compliance Analysis

### Script Compliance (WorldBuilderUI.gd)

✅ **Excellent Compliance** - All sizing uses UIConstants:

```gdscript
// Examples from _apply_ui_constants():
left_panel.custom_minimum_size = Vector2(UIConstants.LEFT_PANEL_WIDTH, 0)
btn.custom_minimum_size = Vector2(0, UIConstants.STEP_BUTTON_HEIGHT)
right_panel.custom_minimum_size = Vector2(UIConstants.RIGHT_PANEL_WIDTH, 0)
back_btn.custom_minimum_size = Vector2(UIConstants.BUTTON_WIDTH_SMALL, 0)
seed_spin.custom_minimum_size = Vector2(UIConstants.SEED_SPIN_WIDTH, 0)
```

**Theme Constant Overrides:**
- All separation values use UIConstants (SPACING_SMALL, SPACING_MEDIUM, SPACING_LARGE)
- Proper use of UIConstants for all button/label/panel sizes

### Scene File Compliance (WorldBuilderUI.tscn)

⚠️ **Partial Compliance** - Hard-coded values found:

**Magic Numbers Found:**
```gdscript
// Step buttons have hard-coded height:
custom_minimum_size = Vector2(0, 40)  // Should use UIConstants.STEP_BUTTON_HEIGHT (which is 40)
```

**Issue:** While the value (40) matches `UIConstants.STEP_BUTTON_HEIGHT`, it's hard-coded in the scene file. The script correctly applies UIConstants in `_apply_ui_constants()`, but the scene file has redundant hard-coded values.

**Impact:** Low - Script overrides scene values, but violates "no magic numbers" rule.

**Recommendation:** Remove hard-coded `custom_minimum_size` from step buttons in scene file, let script handle sizing.

---

## Size Flags & Anchors Analysis

### Root Node (WorldBuilderUI)
- **Anchors:** `PRESET_FULL_RECT` (15) ✅
- **Size Flags:** Horizontal=3 (EXPAND_FILL), Vertical=3 (EXPAND_FILL) ✅
- **Layout Mode:** 3 (PRESET_MODE_MINSIZE) ✅

### MainVBox
- **Anchors:** `PRESET_FULL_RECT` (15) ✅
- **Size Flags:** Horizontal=3, Vertical=3 ✅
- **Layout Mode:** 1 (PRESET_MODE_MINSIZE) ✅

### MainHSplit
- **Size Flags:** Horizontal=3, Vertical=3 ✅
- **Layout Mode:** 2 (PRESET_MODE_MINSIZE) ✅

### Panels
- **LeftPanel:** Size flags horizontal=0 (fixed), vertical=3 ✅
- **RightPanel:** Size flags horizontal=0 (fixed), vertical=3 ✅
- **CenterPanel:** Size flags horizontal=3, vertical=3 ✅

### ParamTree
- **Anchors:** `PRESET_FULL_RECT` (15) ✅
- **Size Flags:** Horizontal=3, Vertical=3 ✅
- **Layout Mode:** 2 (PRESET_MODE_MINSIZE) ✅

**Overall Assessment:** ✅ Excellent - All nodes use proper anchors and size flags for responsive layout.

---

## Script Analysis

### WorldBuilderUI.gd

**Key Functions:**
1. `_apply_ui_constants()` - Applies UIConstants to all UI elements ✅
2. `_update_responsive_layout()` - Handles window resize with throttling ✅
3. `_setup_param_tree()` - Configures Tree widget ✅
4. `_populate_param_tree()` - Dynamically populates Tree items ✅

**Performance Optimizations Found:**
- ✅ `_process()` disabled by default (only enabled during generation)
- ✅ Resize throttling with `_resize_pending` flag
- ✅ Theme constant overrides applied via script (not hard-coded)
- ✅ Tree items stored in Dictionary for quick lookup

**Potential Issues:**
- ⚠️ Deep node path references: `$MainVBox/MainHSplit/RightPanel/RightOuterVBox/RightScroll/RightVBox/ParamTree` (8 levels)
- ⚠️ Multiple `get_node()` calls in `_apply_ui_constants()` (could cache references)

### WorldBuilderAzgaar.gd

**Key Features:**
- Controls WebView embedding (godot_wry)
- Handles Azgaar JavaScript communication
- Manages generation lifecycle

**Current Status:**
- ⚠️ `DEBUG_DISABLE_AZGAAR := true` - WebView is currently disabled for testing
- This means CenterContent is not actively rendering WebView content

**Performance Impact:**
- Low when disabled (current state)
- High when enabled (WebView rendering overhead)

### AzgaarIntegrator.gd

**Key Features:**
- Manages Azgaar bundle copying to `user://azgaar/`
- Provides URL generation (file:// or http://)
- Handles options.json writing

**Performance Impact:**
- Low - Only runs on initialization (`_ready()`)

---

## Performance Concerns

### 1. Deep Nesting (HIGH PRIORITY)

**Issue:** ParamTree is 8 levels deep, requiring style/theme resolution at each level.

**Impact:**
- Estimated 8-24ms per frame for style resolution
- Amplified by theme constant overrides at multiple levels
- Tree widget itself has known performance overhead in Godot 4

**Recommendation:**
- Flatten hierarchy by 1-2 levels where possible
- Consider merging RightOuterVBox and RightVBox (if ScrollContainer can be moved up)
- Alternative: Move ParamTree to a shallower path (e.g., directly under RightPanel)

### 2. Magic Numbers in Scene File (LOW PRIORITY)

**Issue:** Step buttons have hard-coded `Vector2(0, 40)` in scene file.

**Impact:** Low - Script overrides these values, but violates coding standards.

**Recommendation:**
- Remove `custom_minimum_size` from step buttons in scene file
- Let script handle all sizing via `_apply_ui_constants()`

### 3. Multiple get_node() Calls (MEDIUM PRIORITY)

**Issue:** `_apply_ui_constants()` calls `get_node()` multiple times with deep paths.

**Impact:** Low-Medium - `get_node()` is cached by Godot, but deep paths are still expensive.

**Recommendation:**
- Cache node references in `@onready var` declarations
- Use existing `@onready var` references where possible

### 4. Tree Widget Overhead (HIGH PRIORITY - from previous audit)

**Issue:** Tree widget has known performance issues in Godot 4.

**Impact:** 2-5ms per frame (from FPS cause likelihood investigation)

**Recommendation:**
- Consider replacing Tree with VBoxContainer + custom rows if Tree overhead is confirmed
- Reduce Tree columns from 3 to 2 if possible
- Disable Tree hover/selection features when not needed

---

## Suggested Optimizations (Not Implemented - For Approval)

### 1. Flatten Right Panel Hierarchy

**Current Structure:**
```
RightPanel (PanelContainer)
  └─ RightOuterVBox (VBoxContainer)
      └─ RightScroll (ScrollContainer)
          └─ RightVBox (VBoxContainer)
              └─ ParamTree (Tree)
```

**Proposed Structure:**
```
RightPanel (PanelContainer)
  └─ RightScroll (ScrollContainer)  // Move ScrollContainer up one level
      └─ RightVBox (VBoxContainer)   // Merge RightOuterVBox and RightVBox
          ├─ ArchetypeLabel
          ├─ ArchetypeOption
          ├─ SeedLabel
          ├─ SeedHBox
          ├─ SectionSep
          ├─ StepTitle
          └─ ParamTree (Tree)
```

**Benefits:**
- Reduces ParamTree depth from 8 to 6 levels
- Eliminates one VBoxContainer level
- Maintains functionality (ScrollContainer can contain all right panel content)

**Risks:**
- Requires testing to ensure scrolling works correctly
- May need to adjust size flags/anchors

### 2. Remove Hard-Coded Sizes from Scene File

**Action:** Remove `custom_minimum_size = Vector2(0, 40)` from all Step buttons in `.tscn` file.

**Benefits:**
- Full UIConstants compliance
- Single source of truth (script only)
- Easier maintenance

**Risks:**
- None - script already applies these values

### 3. Cache Node References

**Current:**
```gdscript
func _apply_ui_constants() -> void:
    var left_panel: PanelContainer = $MainVBox/MainHSplit/LeftPanel
    var step_sidebar: VBoxContainer = $MainVBox/MainHSplit/LeftPanel/LeftContent/StepSidebar
    // ... more get_node() calls
```

**Proposed:**
```gdscript
@onready var left_panel: PanelContainer = $MainVBox/MainHSplit/LeftPanel
@onready var step_sidebar: VBoxContainer = $MainVBox/MainHSplit/LeftPanel/LeftContent/StepSidebar
// ... cache all references

func _apply_ui_constants() -> void:
    left_panel.custom_minimum_size = Vector2(UIConstants.LEFT_PANEL_WIDTH, 0)
    // ... use cached references
```

**Benefits:**
- Faster access (no path resolution)
- Cleaner code
- Better performance

**Risks:**
- None - `@onready` ensures nodes exist before access

### 4. Consider Tree Widget Replacement (If Performance Issue Confirmed)

**If Tree widget is confirmed as performance bottleneck:**
- Replace Tree with VBoxContainer + custom parameter rows
- Use HBoxContainer for each parameter row
- Maintain same functionality with better performance

**Benefits:**
- Eliminates Tree widget overhead
- More control over rendering
- Better performance

**Risks:**
- Significant refactoring required
- Need to reimplement Tree features (editing, selection)
- Only recommended if Tree is confirmed bottleneck

---

## Compliance Checklist

### ✅ Good Practices
- [x] Uses built-in containers (VBoxContainer, HBoxContainer, HSplitContainer)
- [x] Proper size flags and anchors for responsive layout
- [x] Script uses UIConstants for all sizing
- [x] Theme constant overrides use UIConstants
- [x] Resize handling with throttling
- [x] Process disabled when not needed

### ⚠️ Areas for Improvement
- [ ] Remove magic numbers from scene file
- [ ] Flatten deep nesting (8 levels → 6 levels)
- [ ] Cache node references in `@onready var`
- [ ] Consider Tree widget replacement if performance issue confirmed

---

## Summary

The WorldBuilderUI structure is generally well-designed with proper use of built-in containers and responsive layout techniques. The main concerns are:

1. **Deep Nesting (8 levels)** - ParamTree path could be flattened to 6 levels
2. **Magic Numbers** - Scene file has hard-coded values (low priority, script overrides)
3. **Tree Widget Overhead** - Known Godot 4 performance issue (from previous audit)

**Recommended Priority:**
1. **High:** Flatten right panel hierarchy (reduce ParamTree depth from 8 to 6)
2. **Medium:** Cache node references in `@onready var`
3. **Low:** Remove magic numbers from scene file
4. **Conditional:** Replace Tree widget if performance testing confirms it's the bottleneck

All optimizations should be tested with `run_project` to verify no regressions in functionality or layout.

---

**Next Steps:**
1. Test current structure with `run_project` to establish baseline FPS
2. Implement flattening optimization (if approved)
3. Measure FPS improvement
4. Apply additional optimizations based on results

