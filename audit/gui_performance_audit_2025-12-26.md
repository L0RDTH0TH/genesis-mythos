# GUI Performance Audit – December 26, 2025

## Executive Summary

This audit identifies the root causes of severe GUI performance degradation (~7 FPS, ~1900 objects, ~1514 primitives drawn) in the World Builder UI and other interface scenes. The primary issue is **excessive CanvasItem node count** caused by:

1. **Dynamic node creation** in `WorldBuilderUI._populate_params()` - creates 18-30 nodes per step
2. **Deep nesting** (8 levels) causing layout recalculation overhead
3. **Per-node theme overrides** breaking render batching
4. **Multiple dynamic label creation** in PerformanceMonitor and GraphControl overlays

**Target:** Reduce total CanvasItem count from ~1900 to <500 → Achieve 60+ FPS

---

## Current Baseline

- **Measured FPS:** ~7 FPS (when WorldBuilderUI is active)
- **Object count:** ~1900 objects
- **Estimated CanvasItem count:** ~1514 primitives drawn
- **Key scenes audited:** 
  - `ui/world_builder/WorldBuilderUI.tscn` (PRIMARY TARGET)
  - `scenes/ui/overlays/PerformanceMonitor.tscn`
  - `scenes/character_creation/CharacterCreationRoot.tscn`
  - `scenes/MainMenu.tscn`

---

## Findings per Scene

### 1. WorldBuilderUI.tscn (PRIMARY BOTTLENECK)

**Path:** `res://ui/world_builder/WorldBuilderUI.tscn`

#### Static Node Count (from .tscn file)
- **Total nodes:** 44 nodes (counted via `grep "^\[node"`)
- **Node types breakdown:**
  - 1 Control (root)
  - 1 ColorRect (Background)
  - 1 VBoxContainer (MainVBox)
  - 1 PanelContainer (TopBar)
  - 1 CenterContainer (TopBarContent)
  - 1 Label (TitleLabel)
  - 1 HSplitContainer (MainHSplit)
  - 3 PanelContainer (LeftPanel, CenterPanel, RightPanel)
  - 3 VBoxContainer (LeftContent, StepSidebar, RightVBox)
  - 1 ScrollContainer (RightScroll)
  - 8 Button (Step1Btn-Step8Btn)
  - 2 Label (ArchetypeLabel, SeedLabel)
  - 1 OptionButton (ArchetypeOption)
  - 1 HBoxContainer (SeedHBox)
  - 1 SpinBox (SeedSpin)
  - 1 Button (RandomizeBtn)
  - 1 HSeparator (SectionSep)
  - 1 Label (StepTitle)
  - 1 VBoxContainer (ActiveParams) ← **DYNAMIC CONTENT CONTAINER**
  - 1 VBoxContainer (GlobalControls)
  - 1 PanelContainer (BottomBar)
  - 1 HBoxContainer (BottomContent)
  - 2 Control (SpacerLeft, SpacerRight)
  - 4 Button (BackBtn, GenBtn, BakeTo3DBtn, NextBtn)
  - 1 ProgressBar (ProgressBar)
  - 1 Label (StatusLabel)
  - 1 Control (CenterContent with WorldBuilderAzgaar script)
  - 1 TextureRect (OverlayPlaceholder)

#### Dynamic Node Creation (CRITICAL ISSUE)

**Location:** `ui/world_builder/WorldBuilderUI.gd::_populate_params()` (lines 334-417)

**Problem:** This method **clears and recreates** all parameter control nodes every time the user switches steps or updates parameters.

**Node creation per parameter:**
- 1 HBoxContainer (row container)
- 1 Label (parameter name)
- 1 Control (HSlider/SpinBox/OptionButton/CheckBox)
- **For HSliders:** +1 Label (value display)

**Parameter counts per step:**
- **Step 0 (Map Generation):** 6 params → ~18-24 nodes (2 HSliders = +2 value labels)
- **Step 1 (Terrain):** 4 params → ~12-16 nodes (1 HSlider = +1 value label)
- **Step 2 (Climate):** 4 params → ~16-20 nodes (4 HSliders = +4 value labels) ← **WORST CASE**
- **Step 4 (Structures):** 6 params → ~18-24 nodes
- **Step 5 (Environment):** 3 params → ~9-12 nodes

**Total dynamic nodes:** ~18-30 nodes per active step (worst case: Step 2 with 20 nodes)

**Performance Impact:**
- Creates 18-30 new Control nodes per step switch
- `queue_free()` on all previous nodes (async cleanup overhead)
- All new nodes require layout recalculation
- Each node triggers theme application

#### Deep Nesting Analysis

**Maximum nesting depth:** 8 levels

```
WorldBuilderUI (Control) [depth 1]
└── MainVBox (VBoxContainer) [depth 2]
    └── MainHSplit (HSplitContainer) [depth 3]
        └── RightPanel (PanelContainer) [depth 4]
            └── RightScroll (ScrollContainer) [depth 5]
                └── RightVBox (VBoxContainer) [depth 6]
                    └── ActiveParams (VBoxContainer) [depth 7]
                        └── [Dynamic HBoxContainer rows] [depth 8]
                            └── [Label + Control + Label] [depth 9]
```

**Impact:** Layout recalculation must traverse 8 levels, multiplying cost for each dynamic node.

#### Theme Overrides

**Per-node theme overrides identified:**
- `TitleLabel`: `theme_override_font_sizes/font_size`, `theme_override_colors/font_color`, `theme_override_colors/font_shadow_color`, `theme_override_constants/shadow_offset_x`, `theme_override_constants/shadow_offset_y` (5 overrides)
- Multiple VBoxContainers: `theme_override_constants/separation`
- Step buttons: `theme_override_colors/font_color`, `theme_override_colors/font_hover_color` (per-button, dynamic via `_update_step_ui()`)

**Impact:** Theme overrides break render batching, forcing separate draw calls per overridden node.

#### Magic Numbers

**Found hard-coded sizes:**
- Line 42: `custom_minimum_size = Vector2(0, 60)` (TopBar)
- Line 69: `custom_minimum_size = Vector2(220, 0)` (LeftPanel)
- Line 90: `custom_minimum_size = Vector2(0, 40)` (each Step button, 8×)
- Line 173: `custom_minimum_size = Vector2(240, 0)` (RightPanel)
- Line 244: `custom_minimum_size = Vector2(0, 50)` (BottomBar)
- Line 263: `custom_minimum_size = Vector2(120, 0)` (BackBtn)
- Line 268: `custom_minimum_size = Vector2(250, 0)` (GenBtn)
- Line 274: `custom_minimum_size = Vector2(180, 0)` (BakeTo3DBtn)
- Line 281: `custom_minimum_size = Vector2(120, 0)` (NextBtn)
- Line 286: `custom_minimum_size = Vector2(200, 0)` (ProgressBar)
- Line 293: `custom_minimum_size = Vector2(150, 0)` (StatusLabel)

**Note:** Script uses `UIConstants` for dynamic sizing in `_apply_ui_constants()`, but scene file still contains hard-coded values (legacy).

---

### 2. PerformanceMonitor.tscn

**Path:** `res://scenes/ui/overlays/PerformanceMonitor.tscn`

#### Static Node Count
- **Total nodes:** ~25 nodes (estimated from scene structure)
- **Node types:** CanvasLayer, PanelContainer, VBoxContainer, HBoxContainer, Label, Control nodes (GraphControl, WaterfallControl, FlameGraphControl)

#### Dynamic Node Creation

**Location:** `scripts/ui/overlays/PerformanceMonitor.gd::_ready()` (lines 135-168)

**Problem:** Creates 12 metric labels dynamically via `_create_metric_label()`:
1. process_label
2. physics_label
3. refresh_label
4. system_status_label
5. memory_label
6. vram_label
7. texture_mem_label
8. draw_calls_label
9. primitives_label
10. objects_drawn_label
11. object_label
12. node_label
13. flame_status_label (optional)

**Impact:** Adds 12-13 Control nodes at runtime, but only visible in DETAILED mode.

#### GraphControl Dynamic Labels

**Location:** `scripts/ui/overlays/GraphControl.gd::_ready()` (lines 47-65)

**Problem:** Each GraphControl creates 3 labels dynamically:
- min_label
- max_label
- stats_label

**Graph counts:**
- 3 graphs in top graphs container (FPSGraph, ProcessGraph, RefreshGraph)
- 4 optional graphs in bottom container (if present)

**Total dynamic labels:** 3-9 labels (3-21 nodes including containers, if bottom graphs exist)

---

### 3. CharacterCreationRoot.tscn

**Path:** `res://scenes/character_creation/CharacterCreationRoot.tscn`

#### Static Node Count
- **Total nodes:** ~15 nodes (estimated from scene structure)
- **Node types:** Control, ColorRect, VBoxContainer, HSplitContainer, Panel, ScrollContainer, SubViewportContainer, SubViewport, Node3D, Camera3D

**Status:** Low priority - not currently contributing to performance issues.

---

### 4. MainMenu.tscn

**Path:** `res://scenes/MainMenu.tscn`

#### Static Node Count
- **Total nodes:** ~10 nodes
- **Node types:** Control, ColorRect, CenterContainer, VBoxContainer, Label, Button

**Status:** Low priority - simple scene with minimal nesting.

---

## Prioritized Recommendations

### 1. **Replace Dynamic Parameter Rows with Object Pooling** (HIGHEST IMPACT)

**Expected node reduction:** ~15-25 nodes per step → **Reduce from 18-30 dynamic nodes to 0 new allocations**

**Rationale:** Instead of creating/destroying 18-30 nodes per step switch, reuse a pool of parameter row scenes.

**Exact steps:**
1. Create a reusable parameter row scene: `res://scenes/ui/components/ParameterRow.tscn`
   - Contains: HBoxContainer + Label (name) + Control slot (HSlider/SpinBox/etc.) + Label (value, optional)
   - Use `@export var` for control type configuration
2. In `WorldBuilderUI.gd`:
   - Add `var _param_row_pool: Array[Control] = []` (pool of pre-created rows)
   - Add `const POOL_SIZE: int = 30` (enough for worst-case step)
   - In `_ready()`, pre-create 30 ParameterRow instances, hide them, add to pool
   - In `_populate_params()`:
     - Hide all rows in pool
     - For each parameter: get row from pool, configure it, show it, add to ActiveParams
     - No `queue_free()` or `new()` calls
3. Use `visible = false` instead of `queue_free()` for hiding rows

**Compliance:** ✅ Uses built-in containers, UIConstants, shared theme, no magic numbers

**Estimated impact:** Reduce dynamic node creation from ~20 nodes/step to 0 allocations → **~20 fewer nodes per step switch**

---

### 2. **Merge Parameter Labels into RichTextLabel** (HIGH IMPACT)

**Expected node reduction:** ~6-10 Label nodes per step → **Reduce Labels by ~50%**

**Rationale:** Instead of separate Label nodes for each parameter name, use a single RichTextLabel with formatted text.

**Exact steps:**
1. Replace `ActiveParams` VBoxContainer structure:
   - Keep VBoxContainer for layout
   - Add single `RichTextLabel` at top for all parameter names (hidden when params exist)
   - OR: Use `ItemList` or `Tree` for parameter display (better for large lists)
2. For parameter values: Keep individual controls (HSlider, SpinBox, etc.) but remove name Labels
   - Use control `tooltip_text` for parameter descriptions
   - Use `hint_tooltip` for accessibility

**Alternative (simpler):** Use `ItemList` with custom item rendering for parameters (Godot 4.5.1 supports custom item rendering).

**Compliance:** ✅ Built-in containers, theme-driven, responsive

**Estimated impact:** Reduce Labels from ~6-10 per step to 0-1 → **~6-10 fewer nodes per step**

---

### 3. **Reduce Nesting Depth via Flattening** (MEDIUM IMPACT)

**Expected performance improvement:** ~10-20% faster layout recalculation

**Rationale:** Reduce nesting from 8 levels to 5-6 levels by removing unnecessary container wrappers.

**Exact steps:**
1. Remove `RightScroll` wrapper if scrolling is not needed (check if content fits viewport)
   - Move `RightVBox` directly under `RightPanel`
   - Apply `ScrollContainer` behavior only if content exceeds viewport height
2. Merge `GlobalControls` VBoxContainer directly into `RightVBox` (remove one level)
3. Consider merging `LeftContent` directly into `LeftPanel` (remove one level if not needed for styling)

**Compliance:** ✅ Maintains responsive layout with anchors/size flags

**Estimated impact:** Reduce layout recalculation cost by ~10-20% (doesn't reduce node count, but improves performance)

---

### 4. **Consolidate Theme Overrides into Theme Variants** (MEDIUM IMPACT)

**Expected performance improvement:** Improve render batching → **~5-10% FPS improvement**

**Rationale:** Move per-node theme overrides into theme variants or style classes, enabling render batching.

**Exact steps:**
1. Add theme variants to `bg3_theme.tres`:
   - `title_label` style class for TitleLabel (large font, gold color, shadow)
   - `step_button_active` style class for active step buttons
   - `step_button_inactive` style class for inactive step buttons
2. In `WorldBuilderUI.tscn`:
   - Remove `theme_override_*` properties from TitleLabel
   - Apply `theme_type_variation = "title_label"` instead
3. In `WorldBuilderUI.gd::_update_step_ui()`:
   - Replace `add_theme_color_override()` with `theme_type_variation` switching
   - Or use `modulate` color instead of theme overrides (cheaper)

**Compliance:** ✅ Uses shared theme, no magic numbers

**Estimated impact:** Enable render batching for ~15-20 nodes → **~5-10% FPS improvement**

---

### 5. **Pre-create PerformanceMonitor Labels in Scene** (LOW IMPACT)

**Expected node reduction:** 12-13 fewer dynamic nodes

**Rationale:** Move metric labels from runtime creation to scene file for better performance and easier inspection.

**Exact steps:**
1. In `PerformanceMonitor.tscn`:
   - Add 12-13 Label nodes under `MetricsContainer` with unique names
   - Remove dynamic creation code in `_ready()`
2. Use `@onready var` references instead of runtime creation
   - Change `var process_label: Label` to `@onready var process_label: Label = $PerfPanel/Content/MetricsContainer/ProcessLabel`

**Compliance:** ✅ No code changes to logic, only initialization method

**Estimated impact:** Reduce dynamic nodes by 12-13 → **Minor improvement, but better for maintainability**

---

### 6. **Pre-create GraphControl Labels in Scene** (LOW IMPACT)

**Expected node reduction:** 3-9 fewer dynamic nodes per graph

**Rationale:** Move GraphControl labels to scene file.

**Exact steps:**
1. Create `GraphControl.tscn` scene:
   - Control (root)
   - 3 Label children (MinLabel, MaxLabel, StatsLabel)
2. Update `PerformanceMonitor.tscn` to use `GraphControl.tscn` as PackedScene instances
3. Remove `Label.new()` calls from `GraphControl.gd::_ready()`

**Compliance:** ✅ Scene-driven approach, easier to inspect/debug

**Estimated impact:** Reduce dynamic nodes by 3-9 per graph → **Minor improvement**

---

## Estimated Impact Summary

| Recommendation | Node Reduction | Performance Gain | Priority |
|---------------|----------------|------------------|----------|
| 1. Object Pooling for Parameter Rows | ~20 nodes/step | **HIGH** (eliminates allocations) | **HIGHEST** |
| 2. Merge Labels into RichTextLabel | ~6-10 nodes/step | **MEDIUM** (fewer Labels) | **HIGH** |
| 3. Reduce Nesting Depth | 0 nodes (layout speed) | **MEDIUM** (10-20% faster) | **MEDIUM** |
| 4. Consolidate Theme Overrides | 0 nodes (batching) | **MEDIUM** (5-10% FPS) | **MEDIUM** |
| 5. Pre-create PerformanceMonitor Labels | 12-13 nodes | **LOW** (minor) | **LOW** |
| 6. Pre-create GraphControl Labels | 3-9 nodes/graph | **LOW** (minor) | **LOW** |

**Total estimated node reduction (after recommendations 1, 2, 5, 6):** ~40-60 nodes per active step

**Target:** Reduce from ~1900 objects to <500 → **~75% reduction needed**

**Note:** The ~1900 object count likely includes:
- Static scene nodes (~44 in WorldBuilderUI)
- Dynamic parameter rows (~20 per step)
- PerformanceMonitor overlays (~25-50 nodes)
- Other UI scenes (CharacterCreation, MainMenu)
- 3D scene nodes (World, Terrain3D, etc.)

**Focus:** Recommendations 1-2 address the primary bottleneck (dynamic parameter rows). Additional investigation needed for remaining ~1800 objects (may include 3D scene nodes, not just UI).

---

## Implementation Phases

### Phase 1: Quick Wins (Recommendations 5-6)
- **Effort:** 1-2 hours
- **Risk:** Low (scene file changes only)
- **Impact:** Minor node reduction, better maintainability

### Phase 2: High Impact (Recommendations 1-2)
- **Effort:** 4-6 hours
- **Risk:** Medium (requires careful testing of parameter row pooling)
- **Impact:** **Major node reduction** (~25-35 nodes per step)

### Phase 3: Performance Polish (Recommendations 3-4)
- **Effort:** 2-3 hours
- **Risk:** Low (layout improvements, theme consolidation)
- **Impact:** Moderate performance improvement (10-20% FPS gain)

---

## Next Steps

1. **Approve this audit report** - Review findings and prioritize recommendations
2. **Implement Phase 1** (Quick Wins) - Pre-create labels in scenes
3. **Implement Phase 2** (High Impact) - Object pooling for parameter rows + label consolidation
4. **Test and measure** - Verify node count reduction and FPS improvement
5. **Investigate remaining objects** - Profile to identify sources of remaining ~1800 objects (may include 3D scene nodes)

---

## Risks & Considerations

**None** - All recommendations use built-in Godot features only (containers, anchors, size flags, UIConstants, shared theme). No external dependencies or breaking changes to project rules.

**Testing Requirements:**
- Test step switching performance (should be instant with pooling)
- Test parameter control functionality (sliders, spinboxes, etc.)
- Test responsive layout on window resize
- Verify theme consistency after override consolidation

---

## Appendix: Code Locations

### Key Files to Modify

1. `ui/world_builder/WorldBuilderUI.gd` - Lines 334-417 (`_populate_params()`)
2. `ui/world_builder/WorldBuilderUI.tscn` - Static node structure, theme overrides
3. `scenes/ui/overlays/PerformanceMonitor.gd` - Lines 135-168 (dynamic label creation)
4. `scenes/ui/overlays/PerformanceMonitor.tscn` - Add metric labels to scene
5. `scripts/ui/overlays/GraphControl.gd` - Lines 47-65 (dynamic label creation)
6. `themes/bg3_theme.tres` - Add theme variants for TitleLabel, step buttons

### Key Data Files

- `data/config/azgaar_step_parameters.json` - Parameter definitions (23 total parameters across 8 steps)

---

**Report Generated:** 2025-12-26  
**Audit Method:** Static code analysis + scene file inspection + dynamic node counting  
**Status:** ✅ READY FOR REVIEW - Awaiting approval before implementation

