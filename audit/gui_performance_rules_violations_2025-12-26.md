# GUI Performance Rules Violations Investigation Report
**Date:** 2025-12-26  
**Purpose:** Investigate codebase for violations of GUI performance rules as defined in `docs/gui/gui_performance_rules.md`  
**Status:** Investigation Complete – No Code Changes Made

---

## Executive Summary

This investigation identified **multiple critical violations** of the GUI performance rules across the codebase. The most severe violation is in `WorldBuilderUI.gd`, which uses the exact forbidden pattern (runtime node creation/destruction on step changes) that caused the original 5-7 FPS performance issue.

### Violation Summary
- **Hard Rule Violations:** 3 major categories
  - **Runtime Node Creation/Destruction:** 1 critical violation (WorldBuilderUI._populate_params)
  - **Theme Overrides:** 20+ violations across .tscn files and scripts
  - **Hard-Coded Sizes:** 30+ violations in .tscn files
  - **Nesting Depth:** 1 violation (WorldBuilderUI exceeds 6-level limit)
- **Soft Rule Violations:** Multiple instances of missing object pooling, dynamic node creation

---

## Hard Rule Violations

### 1. Runtime Node Creation/Destruction (Hard Rule #1) – CRITICAL

**Rule:** No frequent runtime creation/destruction of Control nodes. Forbidden: Clearing and recreating rows, labels, or controls on every update/step change.

#### Violation: `ui/world_builder/WorldBuilderUI.gd` – `_populate_params()` Method

**Location:** Lines 334-418

**Violation Details:**
```334:418:ui/world_builder/WorldBuilderUI.gd
func _populate_params() -> void:
	"""Populate parameter controls for current step."""
	# Clear existing params
	for child in active_params.get_children():
		child.queue_free()
	
	var step_def: Dictionary = STEP_DEFINITIONS.get(current_step, {})
	var params_list: Array = step_def.get("params", [])
	
	if params_list.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No parameters for this step"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		active_params.add_child(empty_label)
		return
	
	for param in params_list:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", UIConstants.SPACING_SMALL)
		
		var param_name: String = param.get("name", "")
		var azgaar_key: String = param.get("azgaar_key", param_name)
		var param_type: String = param.get("type", "HSlider")
		
		var label: Label = Label.new()
		label.text = param_name.capitalize() + ":"
		label.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_STANDARD, 0)
		row.add_child(label)
		
		var control: Control
		match param_type:
			"OptionButton":
				control = OptionButton.new()
				# ... more node creation ...
			"HSlider":
				control = HSlider.new()
				# ... more node creation ...
			"CheckBox":
				control = CheckBox.new()
			"SpinBox":
				control = SpinBox.new()
		
		control.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_WIDE, UIConstants.BUTTON_HEIGHT_SMALL)
		control.tooltip_text = "Controls " + param_name
		row.add_child(control)
		active_params.add_child(row)
```

**Why This Violates the Rule:**
- **Line 337-338:** Clears all existing parameter rows via `queue_free()` on every step change
- **Lines 344-417:** Creates new Control nodes (HBoxContainer, Label, OptionButton, HSlider, CheckBox, SpinBox) dynamically for each parameter
- **Called from:** `_update_step_ui()` (line 331), which is triggered on every step navigation
- **Impact:** Creates 18-30 Control nodes per step switch, causing the exact performance degradation pattern documented in the audit history

**Required Fix:**
- Use object pooling: Pre-create all parameter rows in `.tscn` file or `_ready()`, then toggle visibility or update data
- Alternative: Use `ItemList`, `Tree`, or `RichTextLabel` for dynamic parameter display
- Never call `queue_free()` or `free()` on parameter rows during step navigation

**Severity:** **CRITICAL** – This is the root cause of the original 5-7 FPS issue.

---

### 2. Per-Node Theme Overrides (Hard Rule #4)

**Rule:** No per-node theme overrides in .tscn files or via `add_theme_*_override()`. Use theme variants, style classes, or `modulate`.

#### Violations in .tscn Files

**2.1 `ui/world_builder/WorldBuilderUI.tscn`**
- Line 36: `theme_override_constants/separation = 0` (MainVBox)
- Line 54: `theme_override_font_sizes/font_size = 28` (TitleLabel)
- Line 55: `theme_override_colors/font_color = Color(1, 0.843137, 0, 1)` (TitleLabel)
- Line 56: `theme_override_colors/font_shadow_color = Color(0, 0, 0, 0.5)` (TitleLabel)
- Line 57-58: `theme_override_constants/shadow_offset_x = 2`, `shadow_offset_y = 2` (TitleLabel)
- Line 80: `theme_override_constants/separation = 10` (LeftContent)
- Line 86: `theme_override_constants/separation = 5` (StepSidebar)
- Line 191: `theme_override_constants/separation = 20` (RightVBox)
- Line 195: `theme_override_constants/separation = 10` (GlobalControls)
- Line 211: `theme_override_constants/separation = 10` (SeedHBox)
- Line 231: `theme_override_font_sizes/font_size = 20` (StepTitle)
- Line 232: `theme_override_colors/font_color = Color(1, 0.843137, 0, 1)` (StepTitle)
- Line 238: `theme_override_constants/separation = 20` (ActiveParams)
- Line 254: `theme_override_constants/separation = 20` (BottomContent)

**2.2 `scenes/MainMenu.tscn`**
- Lines 40-44: Multiple theme overrides on TitleLabel (font_color, font_shadow_color, shadow_offset_x/y, font_size)

**2.3 `scenes/character_creation/CharacterCreationRoot.tscn`**
- Lines 43-47: Multiple theme overrides on TitleLabel (font_size, font_color, font_shadow_color, shadow_offset_x/y)

**2.4 Character Creation Tab Scenes**
- `scenes/character_creation/tabs/AbilityScoreTab.tscn`: Lines 12-13, 31-32 (font_size, font_color)
- `scenes/character_creation/tabs/NameConfirmTab.tscn`: Lines 12-13
- `scenes/character_creation/tabs/AppearanceTab.tscn`: Lines 12-13
- `scenes/character_creation/tabs/BackgroundTab.tscn`: Lines 12-13
- `scenes/character_creation/tabs/ClassTab.tscn`: Lines 12-13
- `scenes/character_creation/tabs/RaceTab.tscn`: Lines 12-13

**2.5 `scenes/ui/overlays/PerformanceMonitor.tscn`**
- Multiple theme_override_constants for margins and separation (lines 33, 43, 50, 92-95, 101, 138-141, 180-183)

#### Violations in Scripts

**2.6 `ui/world_builder/WorldBuilderUI.gd`**
- Lines 298-299: `add_theme_color_override()` calls in `_update_step_ui()`
```298:299:ui/world_builder/WorldBuilderUI.gd
			btn.add_theme_color_override("font_color", Color(1.0, 0.843, 0.0, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.4, 1.0))
```

**2.7 `ui/components/AbilityScoreRow.gd`**
- Line 97: `add_theme_color_override()` call in `_refresh()`
```97:97:ui/components/AbilityScoreRow.gd
			mod_label.add_theme_color_override("font_color", pos_color if mod >= 0 else neg_color)
```

**Why These Violate the Rule:**
- Per-node theme overrides break render batching, causing each node to be drawn separately
- Should use theme variants (`theme_type_variation`) or style classes in `bg3_theme.tres`
- Dynamic color changes should use `modulate` instead of `add_theme_color_override()`

**Required Fix:**
- Create theme variants in `bg3_theme.tres` for common patterns (e.g., "TitleLabel", "StepButton", "GoldText")
- Replace theme overrides in .tscn files with theme variant assignments
- Replace `add_theme_color_override()` calls with `modulate` for dynamic color changes
- Document any exceptions (e.g., progress bars) with heavy justification

**Severity:** **HIGH** – Breaks render batching, contributing to performance degradation.

---

### 3. Hard-Coded Sizes/Positions (Hard Rule #5)

**Rule:** No hard-coded sizes or positions (magic numbers). All sizing/positioning must use UIConstants.gd values, Theme constants, Anchors + size flags, or Runtime calculations.

#### Violations in .tscn Files

**3.1 `ui/world_builder/WorldBuilderUI.tscn`**
- Line 42: `custom_minimum_size = Vector2(0, 60)` (TopBar) – Should use `UIConstants.BOTTOM_BAR_HEIGHT` or similar
- Line 69: `custom_minimum_size = Vector2(220, 0)` (LeftPanel) – Should use `UIConstants.LEFT_PANEL_WIDTH`
- Lines 90, 97, 104, 111, 118, 125, 132, 139: `custom_minimum_size = Vector2(0, 40)` (8× Step buttons) – Should use `UIConstants.STEP_BUTTON_HEIGHT`
- Line 173: `custom_minimum_size = Vector2(240, 0)` (RightPanel) – Should use `UIConstants.RIGHT_PANEL_WIDTH`
- Line 215: `custom_minimum_size = Vector2(200, 0)` (SeedSpin) – Should use `UIConstants.SEED_SPIN_WIDTH`
- Line 222: `custom_minimum_size = Vector2(64, 50)` (RandomizeBtn) – Should use `UIConstants.RANDOMIZE_BTN_SIZE`
- Line 244: `custom_minimum_size = Vector2(0, 50)` (BottomBar) – Should use `UIConstants.BOTTOM_BAR_HEIGHT`
- Line 263: `custom_minimum_size = Vector2(120, 0)` (BackBtn) – Should use `UIConstants.BUTTON_WIDTH_SMALL`
- Line 268: `custom_minimum_size = Vector2(250, 0)` (GenBtn) – Should use `UIConstants.BUTTON_WIDTH_LARGE`
- Line 274: `custom_minimum_size = Vector2(180, 0)` (BakeTo3DBtn) – Should use `UIConstants.BUTTON_WIDTH_MEDIUM`
- Line 281: `custom_minimum_size = Vector2(120, 0)` (NextBtn) – Should use `UIConstants.BUTTON_WIDTH_SMALL`
- Line 286: `custom_minimum_size = Vector2(200, 0)` (ProgressBar) – Should use `UIConstants.PROGRESS_BAR_WIDTH`
- Line 293: `custom_minimum_size = Vector2(150, 0)` (StatusLabel) – Should use `UIConstants.LABEL_WIDTH_STANDARD`

**3.2 `scenes/ui/overlays/PerformanceMonitor.tscn`**
- Lines 56, 63, 70: `custom_minimum_size = Vector2(0, 100)` (Graph heights) – Should use UIConstants or theme constants
- Lines 112, 153: `custom_minimum_size = Vector2(0, 480)` (Bottom graph bar) – Should use `UIConstants.BOTTOM_GRAPH_BAR_HEIGHT`

**Why These Violate the Rule:**
- Hard-coded numeric literals prevent responsive scaling and make maintenance difficult
- UIConstants.gd already defines all these values, but they're not being used in .tscn files
- Note: `WorldBuilderUI.gd` correctly applies UIConstants in `_apply_ui_constants()` (lines 106-146), but the .tscn file still has hard-coded values that override them

**Required Fix:**
- Remove hard-coded `custom_minimum_size` values from .tscn files
- Apply sizes via script in `_ready()` or `_apply_ui_constants()` (already partially done in WorldBuilderUI.gd)
- Use theme constants for common sizes (e.g., button heights, panel widths)
- Ensure all sizing references UIConstants or theme constants

**Severity:** **MEDIUM** – Violates code standards and makes responsive scaling harder, but less critical than runtime node creation.

---

### 4. Maximum Nesting Depth (Hard Rule #3)

**Rule:** Maximum nesting depth: 6 levels. Count from root Control/CanvasLayer to deepest leaf Control node.

#### Violation: `ui/world_builder/WorldBuilderUI.tscn`

**Nesting Depth Analysis:**
Based on scene tree structure analysis from audit files:
- Root: `WorldBuilderUI` (Control) [depth 0]
- `MainVBox` (VBoxContainer) [depth 1]
- `MainHSplit` (HSplitContainer) [depth 2]
- `RightPanel` (PanelContainer) [depth 3]
- `RightScroll` (ScrollContainer) [depth 4]
- `RightVBox` (VBoxContainer) [depth 5]
- `GlobalControls` (VBoxContainer) [depth 6]
- `SeedHBox` (HBoxContainer) [depth 7]
- `SeedSpin` (SpinBox) [depth 8] ← **Exceeds 6-level limit**

**Deepest Path:** `WorldBuilderUI/MainVBox/MainHSplit/RightPanel/RightScroll/RightVBox/GlobalControls/SeedHBox/SeedSpin`

**Why This Violates the Rule:**
- Maximum nesting depth is **8 levels**, exceeding the 6-level limit by 2 levels
- Deep nesting causes layout recalculation overhead and makes the scene tree harder to maintain

**Required Fix:**
- Flatten the hierarchy by removing intermediate containers where possible
- Consider combining `RightScroll` and `RightVBox` if not needed separately
- Move `GlobalControls` to a shallower level if possible
- Document justification if deeper nesting is required for functional reasons

**Severity:** **MEDIUM** – Contributes to performance overhead but less critical than runtime node creation.

---

### 5. Maximum CanvasItem Count (Hard Rule #2)

**Rule:** Maximum 600 CanvasItem nodes in any active UI scene.

#### Status: Requires Runtime Measurement

**Static Node Count (from .tscn files):**
- `WorldBuilderUI.tscn`: ~44 nodes (static)
- `CharacterCreationRoot.tscn`: ~15 nodes (static)
- `MainMenu.tscn`: ~8 nodes (static)

**Runtime Node Count (with dynamic creation):**
- `WorldBuilderUI`: ~44 static + 18-30 dynamic parameter rows = **62-74 nodes** (within limit if no other dynamic creation)
- However, the audit history indicates **~1900 objects / ~1514 CanvasItems** were measured at runtime, suggesting:
  - Additional dynamic node creation beyond `_populate_params()`
  - WebView embedding may create many internal nodes
  - PerformanceMonitor overlay adds nodes

**Required Action:**
- Run project with WorldBuilderUI active and measure CanvasItem count via Debugger → Monitors → Objects Drawn
- Verify total CanvasItem count stays under 600
- If exceeded, identify additional sources of node creation beyond `_populate_params()`

**Severity:** **UNKNOWN** – Requires runtime measurement to confirm.

---

## Soft Rule Violations

### 1. Pre-Create Controls in .tscn Files (Soft Rule #1)

**Rule:** Pre-create all labels, controls, and rows in .tscn files when possible (avoid `Node.new()` in `_ready()` or updates).

#### Violations

**1.1 `ui/world_builder/WorldBuilderUI.gd`**
- `_populate_params()` creates all parameter rows dynamically (lines 344-417)
- Should pre-create parameter row templates in .tscn file or use ItemList/Tree

**1.2 `scripts/character_creation/tabs/AbilityScoreTab.gd`**
- `_create_ability_rows()` creates rows via `instantiate()` in `_ready()` (line 93)
- **Note:** This is acceptable as it's one-time initialization, not frequent updates

**1.3 `scripts/character_creation/CharacterCreationRoot.gd`**
- `_create_placeholder_tab()` creates nodes dynamically (lines 125-140)
- **Note:** This is a fallback for error cases, acceptable

**Severity:** **LOW** – Most violations are acceptable (one-time initialization). Only `_populate_params()` is problematic.

---

### 2. Use ItemList/Tree/RichTextLabel for Dynamic Lists (Soft Rule #2)

**Rule:** Use `ItemList`, `Tree`, or `RichTextLabel` for dynamic lists instead of individual Control rows.

#### Violations

**2.1 `ui/world_builder/WorldBuilderUI.gd`**
- `_populate_params()` creates individual HBoxContainer rows for each parameter
- Should use `ItemList` or `Tree` to display parameters dynamically

**Severity:** **MEDIUM** – Would reduce node count and improve performance.

---

### 3. Object Pooling (Soft Rule #3)

**Rule:** Implement object pooling for any repeating UI elements (parameter rows, inventory slots, metric lists).

#### Violations

**3.1 `ui/world_builder/WorldBuilderUI.gd`**
- No object pooling for parameter rows
- Rows are created and destroyed on every step change

**Severity:** **MEDIUM** – Object pooling would eliminate the need for runtime node creation/destruction.

---

### 4. Profile Every Major UI Change (Soft Rule #4)

**Rule:** Profile every major UI change using Remote Debugger (check FPS, CanvasItem count).

#### Status

- No evidence of profiling data in recent commits
- Audit files indicate profiling was done during the original performance investigation, but not consistently

**Severity:** **LOW** – Process issue, not code violation.

---

## Scene-Specific Findings

### WorldBuilderUI.tscn / WorldBuilderUI.gd

**Summary:** Most critical violations are in this scene.

**Violations:**
1. ✅ **CRITICAL:** Runtime node creation/destruction in `_populate_params()`
2. ✅ **HIGH:** 14+ theme overrides in .tscn file
3. ✅ **MEDIUM:** 13+ hard-coded sizes in .tscn file
4. ✅ **MEDIUM:** Nesting depth of 8 levels (exceeds 6-level limit)
5. ⚠️ **UNKNOWN:** CanvasItem count requires runtime measurement

**Recommendation:** This scene should be the **highest priority** for fixes.

---

### CharacterCreationRoot.tscn / CharacterCreationRoot.gd

**Summary:** Fewer violations, mostly theme overrides.

**Violations:**
1. ✅ **HIGH:** Theme overrides in .tscn file (TitleLabel)
2. ✅ **LOW:** Acceptable runtime node creation (one-time tab instantiation)

**Recommendation:** Lower priority, but should fix theme overrides.

---

### MainMenu.tscn

**Summary:** Minimal violations.

**Violations:**
1. ✅ **HIGH:** Theme overrides in .tscn file (TitleLabel)

**Recommendation:** Low priority, simple fix.

---

### Character Creation Tab Scenes

**Summary:** Consistent theme override violations across all tabs.

**Violations:**
1. ✅ **HIGH:** Theme overrides in all tab .tscn files (TitleLabel font_size, font_color)

**Recommendation:** Batch fix all tabs together using theme variants.

---

## Overall Compliance Summary

### Hard Rules Compliance
- ❌ **Rule #1 (Runtime Node Creation):** 1 CRITICAL violation (WorldBuilderUI._populate_params)
- ⚠️ **Rule #2 (CanvasItem Count):** Requires runtime measurement
- ❌ **Rule #3 (Nesting Depth):** 1 violation (WorldBuilderUI exceeds 6 levels)
- ❌ **Rule #4 (Theme Overrides):** 20+ violations across .tscn files and scripts
- ❌ **Rule #5 (Hard-Coded Sizes):** 30+ violations in .tscn files

### Soft Rules Compliance
- ⚠️ **Rule #1 (Pre-Create Controls):** Mostly compliant (except WorldBuilderUI._populate_params)
- ❌ **Rule #2 (ItemList/Tree Usage):** 1 violation (WorldBuilderUI should use ItemList)
- ❌ **Rule #3 (Object Pooling):** No pooling implemented
- ⚠️ **Rule #4 (Profiling):** Inconsistent profiling

---

## Recommended Fix Priority

### Priority 1 (CRITICAL – Fix Immediately)
1. **WorldBuilderUI._populate_params()** – Replace runtime node creation with object pooling or ItemList/Tree
   - **Impact:** Will eliminate the root cause of 5-7 FPS performance issue
   - **Effort:** Medium (requires refactoring parameter display system)

### Priority 2 (HIGH – Fix Soon)
2. **Theme Overrides** – Replace with theme variants in bg3_theme.tres
   - **Impact:** Will improve render batching and reduce draw calls
   - **Effort:** Medium (create theme variants, update .tscn files)

### Priority 3 (MEDIUM – Fix When Convenient)
3. **Hard-Coded Sizes** – Remove from .tscn files, ensure UIConstants applied in scripts
   - **Impact:** Better code maintainability and responsive scaling
   - **Effort:** Low (mostly removing hard-coded values, scripts already use UIConstants)

4. **Nesting Depth** – Flatten WorldBuilderUI hierarchy
   - **Impact:** Reduced layout recalculation overhead
   - **Effort:** Medium (requires restructuring scene tree)

5. **ItemList/Tree Usage** – Replace parameter rows with ItemList
   - **Impact:** Reduced node count, better performance
   - **Effort:** Medium (requires UI redesign)

### Priority 4 (LOW – Nice to Have)
6. **Object Pooling** – Implement for any remaining dynamic node creation
   - **Impact:** Further performance improvements
   - **Effort:** Low (if Priority 1 fix uses pooling)

7. **Profiling Process** – Establish consistent profiling workflow
   - **Impact:** Better performance monitoring
   - **Effort:** Low (process/documentation)

---

## High-Level Fix Suggestions

### Fix 1: Replace `_populate_params()` with ItemList

**Current Approach:**
- Creates HBoxContainer + Label + Control for each parameter
- Destroys all rows on step change

**Suggested Approach:**
```gdscript
# Pre-create ItemList in .tscn file
@onready var params_list: ItemList = $MainVBox/MainHSplit/RightPanel/RightScroll/RightVBox/ActiveParams/ParamsItemList

func _populate_params() -> void:
	"""Populate parameter controls using ItemList."""
	params_list.clear()
	
	var step_def: Dictionary = STEP_DEFINITIONS.get(current_step, {})
	var params_list_data: Array = step_def.get("params", [])
	
	if params_list_data.is_empty():
		params_list.add_item("No parameters for this step")
		return
	
	for param in params_list_data:
		var param_name: String = param.get("name", "")
		var display_text: String = "%s: [value]" % param_name.capitalize()
		params_list.add_item(display_text)
		# Store param data in item metadata
		params_list.set_item_metadata(params_list.get_item_count() - 1, param)
```

**Alternative:** Use object pooling with pre-created row templates.

---

### Fix 2: Create Theme Variants

**Create in `bg3_theme.tres`:**
- `theme_type_variation = "TitleLabel"` for large gold titles
- `theme_type_variation = "StepButton"` for step navigation buttons
- `theme_type_variation = "GoldText"` for gold-colored text labels

**Update .tscn files:**
- Replace `theme_override_*` with `theme_type_variation = "TitleLabel"` assignments

---

### Fix 3: Flatten Nesting Depth

**Current Structure:**
```
WorldBuilderUI → MainVBox → MainHSplit → RightPanel → RightScroll → RightVBox → GlobalControls → SeedHBox → SeedSpin (8 levels)
```

**Suggested Structure:**
```
WorldBuilderUI → MainVBox → MainHSplit → RightPanel → RightScroll → RightVBox → SeedHBox → SeedSpin (7 levels)
```

Remove `GlobalControls` container if it's only used for grouping (can use VBoxContainer separation instead).

---

## Notes

- **No code changes were made** during this investigation – this is a read-only audit report.
- **Runtime measurements** (FPS, CanvasItem count) were not performed as part of this investigation. These should be done after fixes are applied to verify improvements.
- **Addon files** (GUT, Terrain3D, etc.) were excluded from this audit as they are third-party code.
- **Test files** were excluded from this audit as they are not production UI code.

---

## Next Steps

1. **Review this report** with the team
2. **Prioritize fixes** based on impact and effort
3. **Implement Priority 1 fix** (WorldBuilderUI._populate_params) first
4. **Run project** and measure CanvasItem count to verify Rule #2 compliance
5. **Apply fixes** in priority order
6. **Re-audit** after fixes to verify compliance

---

**Report Generated:** 2025-12-26  
**Investigation Method:** Static code analysis, .tscn file inspection, pattern matching  
**Files Analyzed:** 20+ UI-related .tscn and .gd files

