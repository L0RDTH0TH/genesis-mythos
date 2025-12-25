# Azgaar Success GUI Failure Audit

**Generated:** 2025-12-24  
**Purpose:** Investigate disconnect between successful Azgaar WebView loading (HTTP server working, map displays correctly) and missing Godot UI wrapper elements (step sidebar, right panel parameters, bottom bar overlay). Identifies why users see only raw Azgaar interface without surrounding Godot UI controls.

---

## 1. Executive Summary

**Current State:**
- ✅ **Azgaar Loading:** HTTP server operational (port 8080), Azgaar map loads successfully with full labels and functionality
- ✅ **WebView Integration:** godot_wry WebView node correctly initialized, JavaScript execution working, bridge script injected
- ❌ **UI Wrapper Missing:** Only raw Azgaar interface visible - Godot UI elements (step sidebar, right parameter panel, bottom navigation bar) not rendering or hidden

**Root Cause:** Structural layout issue where WebView fills entire center panel area, potentially covering or preventing rendering of:
1. Bottom navigation bar (`BottomHBox`) positioned inside `CenterPanel` but likely behind WebView or improperly z-ordered
2. Layout hierarchy places bottom bar as child of `CenterPanel` rather than root-level overlay, causing visibility/rendering conflicts
3. Magic numbers and hard-coded offsets in `.tscn` file prevent proper responsive layout
4. Missing margin/padding on `CenterContent` to accommodate bottom bar overlay

**Key Findings:**
- Scene structure mostly correct (StepSidebar uses buttons, not TabContainer ✅)
- WebView properly sized but takes full space of `CenterContent` VBoxContainer
- BottomHBox anchored to bottom of `CenterPanel` but WebView may render on top
- Right panel and left sidebar exist in scene tree but may be hidden or sized incorrectly
- Initialization scripts run successfully, UI constants applied, but visual result doesn't match structure

**Priority Fixes:**
1. **CRITICAL:** Move `BottomHBox` to root level or properly overlay it above WebView (z-index/margin solution)
2. **HIGH:** Verify left/right panels are visible and properly sized (check if HSplitContainer split is working)
3. **MEDIUM:** Replace magic numbers with UIConstants throughout `.tscn` file
4. **LOW:** Add proper resize handling for responsive layout updates

---

## 2. Current Implementation Analysis

### 2.1 Scene Tree Structure (from WorldBuilderUI.tscn)

```
WorldBuilderUI (Control, anchors_full_rect, theme=bg3_theme.tres) ✅
├── Background (ColorRect, full rect, dark brown) ✅
├── MainHSplit (HSplitContainer, full rect, split_offset=220) ⚠️ Hard-coded split
│   ├── LeftPanel (VBoxContainer, custom_minimum_size=220px) ✅
│   │   ├── LeftPanelBg (ColorRect, parchment beige) ✅
│   │   └── LeftContent (VBoxContainer) ✅
│   │       ├── TitleLabel ("World Builder – Forging the World") ✅
│   │       └── StepSidebar (VBoxContainer) ✅ **CORRECT: Uses buttons, not TabContainer**
│   │           ├── Step1Btn through Step8Btn (8 buttons) ✅
│   │
│   ├── CenterPanel (PanelContainer, expand_fill) ⚠️ **ISSUE: BottomHBox is child here**
│   │   ├── CenterPanelBg (ColorRect, light beige) ✅
│   │   ├── CenterContent (VBoxContainer, full rect) ⚠️ **ISSUE: WebView fills this**
│   │   │   ├── AzgaarWebView (WebView, size_flags=expand_fill) ⚠️ **Takes full space**
│   │   │   └── OverlayPlaceholder (TextureRect, hidden) ✅
│   │   └── BottomHBox (HBoxContainer, anchored bottom, offset_top=-50) ❌ **WRONG PARENT**
│   │       ├── BottomBg (ColorRect) ✅
│   │       └── BottomContent (HBoxContainer, centered)
│   │           ├── BackBtn, GenBtn, NextBtn, ProgressBar, StatusLabel ✅
│   │
│   └── RightPanel (ScrollContainer, custom_minimum_size=240px) ✅
│       ├── RightPanelBg (ColorRect, parchment beige) ✅
│       └── RightVBox (VBoxContainer)
│           ├── GlobalControls (VBoxContainer) ✅
│           │   ├── ArchetypeOption, SeedSpin, RandomizeBtn ✅
│           ├── StepTitle (Label, dynamic) ✅
│           └── ActiveParams (VBoxContainer, dynamic) ✅
```

### 2.2 Script Logic Analysis

#### WorldBuilderUI.gd Key Functions

**Initialization (`_ready()`):**
- ✅ Loads step definitions from JSON
- ✅ Applies UIConstants to UI elements
- ✅ Collects step buttons and connects signals
- ✅ Initializes Azgaar default map
- ✅ Sets up resize notification handler

**UI Constants Application (`_apply_ui_constants()`):**
- ✅ Sets left panel width from `UIConstants.LEFT_PANEL_WIDTH` (220)
- ✅ Sets step button heights from `UIConstants.STEP_BUTTON_HEIGHT` (40)
- ✅ Sets right panel width from `UIConstants.RIGHT_PANEL_WIDTH` (240)
- ✅ Sets bottom bar height from `UIConstants.BOTTOM_BAR_HEIGHT` (50)
- ✅ Sets button widths from UIConstants
- ✅ Sets initial split offset to `UIConstants.LEFT_PANEL_WIDTH`

**Responsive Layout (`_update_responsive_layout()`):**
- ✅ Calculates panel widths as percentages (17.5% left, 22.5% right)
- ✅ Clamps to min/max values from UIConstants
- ✅ Updates split offset dynamically
- ⚠️ **ISSUE:** Only called on `NOTIFICATION_RESIZED`, may not fire on initial load

**Step UI Updates (`_update_step_ui()`):**
- ✅ Updates step button highlights (orange for active, dimmed for inactive)
- ✅ Updates step title from JSON definitions
- ✅ Manages navigation button visibility based on step
- ✅ Populates parameters dynamically

**Parameter Population (`_populate_params()`):**
- ✅ Clears existing params
- ✅ Creates controls dynamically (OptionButton, HSlider, CheckBox, SpinBox)
- ✅ Uses UIConstants for sizing
- ✅ Connects signals to update `current_params` dictionary

#### WorldBuilderAzgaar.gd Key Functions

**WebView Initialization (`_initialize_webview()`):**
- ✅ Gets WebView node from scene tree
- ✅ Connects `ipc_message` signal
- ✅ Gets HTTP URL from AzgaarIntegrator (prefers HTTP over file://)
- ✅ Loads Azgaar URL successfully
- ✅ Injects bridge script after 2-second delay

**JavaScript Execution (`_execute_azgaar_js()`):**
- ✅ Uses `execute_js()` or `eval()` methods (godot_wry)
- ✅ Handles errors gracefully
- ✅ Logs execution for debugging

**Parameter Syncing (`_sync_parameters_to_azgaar()`):**
- ✅ Maps parameters to Azgaar option keys
- ✅ Formats values by type (string, bool, int/float)
- ✅ Executes JavaScript to set Azgaar options

### 2.3 Runtime Observations (from Debug Output)

**Successful Operations:**
```
[AzgaarServer] [INFO]: HTTP server started [{"port":8080}]
[WorldBuilderUI] [DEBUG]: Layout updated for resize [{"left_width":300,"right_width":350}]
[WorldBuilderUI] [INFO]: Loaded step definitions [{"count":8}]
[WorldBuilderAzgaar] [INFO]: Using HTTP URL (embedded server)
[WorldBuilderAzgaar] [INFO]: Loaded Azgaar URL [{"url":"http://127.0.0.1:8080/index.html"}]
[AzgaarServer] [DEBUG]: Served file [{"path":"index.html","size":589207}]
[WorldBuilderAzgaar] [INFO]: Injected Azgaar bridge script
```

**Key Observations:**
- Azgaar server starts successfully
- Layout resize handler runs (left_width: 300, right_width: 350 calculated)
- Step definitions loaded (8 steps)
- WebView loads HTTP URL correctly
- Bridge script injection successful
- No errors related to UI node visibility or layout

**Missing Observations:**
- No logs indicating UI elements are hidden or not rendering
- No errors about node paths or missing references
- Layout calculations suggest panels should be visible

---

## 3. Identified Issues

### 3.1 Critical Issues

#### Issue #1: BottomHBox Positioning and Z-Order
**Location:** `WorldBuilderUI.tscn` lines 171-252

**Problem:**
- `BottomHBox` is a child of `CenterPanel`, not root level
- WebView (`AzgaarWebView`) is in `CenterContent` VBoxContainer with `size_flags_horizontal = 3` and `size_flags_vertical = 3` (SIZE_EXPAND_FILL)
- WebView fills entire `CenterContent` area, potentially covering `BottomHBox`
- No explicit z-index or rendering order to ensure bottom bar appears above WebView
- `BottomHBox` uses `offset_top = -50.0` which positions it from bottom of parent, but WebView may render on top

**Impact:** Bottom navigation bar (Back/Next/Generate buttons, progress bar, status label) not visible or hidden behind WebView.

**Evidence:**
- Scene structure shows `BottomHBox` inside `CenterPanel/CenterContent` hierarchy
- WebView has expand_fill flags, takes all available space in VBoxContainer
- No margin/padding on `CenterContent` to reserve space for bottom bar

**Expected Behavior:**
- Bottom bar should overlay above WebView or be positioned outside WebView area
- Proper z-ordering ensures bottom bar renders on top
- WebView should have bottom margin/padding to avoid covering bottom bar

#### Issue #2: CenterContent Layout Without Bottom Bar Reservation
**Location:** `WorldBuilderUI.tscn` lines 149-169

**Problem:**
- `CenterContent` is a VBoxContainer with full rect anchors
- `AzgaarWebView` child has `size_flags_vertical = 3` (SIZE_EXPAND_FILL), taking all vertical space
- No bottom margin or padding to reserve space for `BottomHBox` (50px height)
- `BottomHBox` is sibling to `CenterContent`, not child, so VBoxContainer doesn't account for it

**Impact:** WebView expands to fill entire center panel, covering bottom bar area.

**Evidence:**
- `CenterContent` VBoxContainer has no theme_override_constants/separation or custom_minimum_size to limit WebView
- `AzgaarWebView` expand_fill flags cause it to take all space
- `BottomHBox` offset_top = -50 suggests it should overlay, but no guarantee of z-order

### 3.2 High Priority Issues

#### Issue #3: HSplitContainer Split Offset Hard-Coded
**Location:** `WorldBuilderUI.tscn` line 33, `WorldBuilderUI.gd` line 131

**Problem:**
- `.tscn` file has `split_offset = 220` hard-coded
- Script applies `UIConstants.LEFT_PANEL_WIDTH` (220) in `_apply_ui_constants()`, but initial scene load uses hard-coded value
- `_update_responsive_layout()` calculates dynamic widths but may not run on initial load

**Impact:** Left panel may not size correctly on initial load, potentially hiding step buttons.

**Evidence:**
- Hard-coded `split_offset = 220` in `.tscn`
- Script sets split_offset in `_apply_ui_constants()` but scene may load with hard-coded value first

#### Issue #4: Magic Numbers in .tscn File
**Location:** Multiple locations in `WorldBuilderUI.tscn`

**Problem:**
- `offset_top = -50.0` (line 180) - should use `-UIConstants.BOTTOM_BAR_HEIGHT`
- `custom_minimum_size = Vector2(0, 50)` (line 181) - should use `UIConstants.BOTTOM_BAR_HEIGHT`
- `custom_minimum_size = Vector2(220, 0)` (line 39) - should use `UIConstants.LEFT_PANEL_WIDTH`
- `custom_minimum_size = Vector2(240, 0)` (line 255) - should use `UIConstants.RIGHT_PANEL_WIDTH`
- Button sizes hard-coded (120, 250, 180, 200, 150) instead of UIConstants

**Impact:** Layout not responsive, breaks GUI spec compliance (Section 11.2.2: No Magic Numbers).

**Evidence:**
- Multiple `custom_minimum_size` and `offset_top` values with literal numbers
- Script applies UIConstants in `_apply_ui_constants()` but `.tscn` hard-coded values may override

### 3.3 Medium Priority Issues

#### Issue #5: Responsive Layout Not Triggered on Initial Load
**Location:** `WorldBuilderUI.gd` lines 134-170

**Problem:**
- `_update_responsive_layout()` only called on `NOTIFICATION_RESIZED`
- Initial load may not trigger resize notification if viewport size matches scene defaults
- Panel widths calculated in script but `.tscn` hard-coded values may be used first

**Impact:** UI may not size correctly on initial load, especially on different resolutions.

**Evidence:**
- `_notification(what: int)` only handles `NOTIFICATION_RESIZED`
- No explicit call to `_update_responsive_layout()` in `_ready()` after applying constants

#### Issue #6: CenterContent VBoxContainer Layout Issue
**Location:** `WorldBuilderUI.tscn` lines 149-169

**Problem:**
- `CenterContent` is VBoxContainer but `BottomHBox` is not its child
- VBoxContainer doesn't account for `BottomHBox` when sizing `AzgaarWebView`
- Should either:
  - Make `BottomHBox` child of `CenterContent` (last in VBoxContainer)
  - OR use margin/padding on `CenterContent` to reserve bottom space
  - OR move `BottomHBox` to root level with proper anchoring

**Impact:** WebView takes full space, no room reserved for bottom bar.

### 3.4 Low Priority Issues

#### Issue #7: Step Button Sizing Uses UIConstants in Script But Hard-Coded in .tscn
**Location:** `WorldBuilderUI.tscn` lines 80, 87, 94, etc., `WorldBuilderUI.gd` line 104

**Problem:**
- `.tscn` has `custom_minimum_size = Vector2(0, 40)` for step buttons
- Script applies `UIConstants.STEP_BUTTON_HEIGHT` (40) in `_apply_ui_constants()`
- Redundant but harmless - script override should work, but `.tscn` should use UIConstants for clarity

**Impact:** Minor - script override works but violates "no magic numbers" rule.

#### Issue #8: Missing Top Toolbar (Per Previous Audit)
**Location:** Previous audit (`GUI_update_integration_investigation_audit_v2.md`) mentioned TopToolbar removal

**Problem:**
- Previous audit noted TopToolbar should be removed per Phase 3 migration
- Current `.tscn` doesn't show TopToolbar, suggesting it was removed
- Verify it's completely removed and not causing layout issues

**Impact:** None if already removed, but worth verifying.

---

## 4. Root Cause Analysis

### 4.1 Why Azgaar Loads But Godot UI Doesn't Render

**Primary Root Cause: Layout Hierarchy and Z-Order Conflict**

The scene structure places `BottomHBox` as a child of `CenterPanel`, but `AzgaarWebView` is in `CenterContent` (also child of `CenterPanel`). The WebView uses `size_flags_vertical = 3` (SIZE_EXPAND_FILL), causing it to expand and fill the entire `CenterContent` VBoxContainer area. Since `BottomHBox` is positioned using `offset_top = -50.0` (relative to bottom of parent), it should overlay, but:

1. **VBoxContainer Layout:** `CenterContent` is a VBoxContainer, but `BottomHBox` is not its child, so the VBoxContainer doesn't reserve space for it. The WebView fills all available space.

2. **Z-Order:** Godot's rendering order for Control nodes is typically based on scene tree order (children render in order), but WebView may render as a separate layer, potentially covering other UI elements.

3. **Anchoring Conflict:** `BottomHBox` uses `anchors_preset = 12` (PRESET_TOP_LEFT with bottom anchor) and `offset_top = -50.0`, which positions it from the bottom of `CenterPanel`. However, if WebView fills the entire `CenterPanel` area, the bottom bar may be behind it.

**Secondary Root Cause: Initial Layout State**

The `.tscn` file has hard-coded values (split_offset=220, custom_minimum_size values), and while the script applies UIConstants in `_apply_ui_constants()`, the initial scene load may use the hard-coded values. The responsive layout handler (`_update_responsive_layout()`) only runs on `NOTIFICATION_RESIZED`, which may not fire on initial load if the viewport size matches defaults.

**Tertiary Root Cause: Missing Margin/Padding**

The `CenterContent` VBoxContainer has no bottom margin or padding to reserve space for the bottom bar. Even if `BottomHBox` is properly positioned, the WebView expands to fill all space, covering the bottom bar area.

### 4.2 Why Left/Right Panels May Not Be Visible

**Potential Causes:**
1. **HSplitContainer Split:** The split offset is hard-coded (220), and while the script applies UIConstants, if the initial load uses hard-coded values and the viewport is small, panels may be sized incorrectly.

2. **Panel Sizing:** Left panel uses `custom_minimum_size = Vector2(220, 0)` and right panel uses `custom_minimum_size = Vector2(240, 0)`. If the viewport width is less than 220 + 240 + center panel minimum, panels may be compressed or hidden.

3. **Visibility:** No explicit `visible = false` found in scene tree, so panels should be visible unless sized to zero width.

**Most Likely:** Panels are visible but WebView is taking full window space due to layout issue, making it appear as if only Azgaar is shown.

---

## 5. Potential Solutions

### 5.1 Solution #1: Move BottomHBox to Root Level (RECOMMENDED)

**Approach:**
- Move `BottomHBox` from `MainHSplit/CenterPanel/BottomHBox` to `WorldBuilderUI/BottomHBox` (root level)
- Use proper anchoring (`anchors_preset = 7` PRESET_BOTTOM_WIDE) to overlay above entire UI
- Ensure z-index/rendering order (add to scene tree after WebView or use CanvasLayer)

**Pros:**
- Clean separation of concerns
- Bottom bar overlays entire UI, always visible
- No layout conflicts with WebView sizing

**Cons:**
- Requires scene restructuring
- Need to ensure proper z-ordering

**Implementation Steps:**
1. In `.tscn`, move `BottomHBox` node to be child of root `WorldBuilderUI`
2. Update anchors to `anchors_preset = 7` (PRESET_BOTTOM_WIDE)
3. Update script paths if needed (currently `$MainHSplit/CenterPanel/BottomHBox/...`)
4. Test z-ordering (may need CanvasLayer for guaranteed overlay)

### 5.2 Solution #2: Add Margin to CenterContent VBoxContainer

**Approach:**
- Keep `BottomHBox` as child of `CenterPanel` but move it to be last child of `CenterContent` VBoxContainer
- VBoxContainer will automatically reserve space for bottom bar
- WebView will size to remaining space above bottom bar

**Pros:**
- Minimal structural changes
- VBoxContainer handles layout automatically
- WebView properly constrained

**Cons:**
- Bottom bar is part of center panel, not full-width overlay
- May look less integrated if panels have different widths

**Implementation Steps:**
1. In `.tscn`, move `BottomHBox` to be last child of `CenterContent` VBoxContainer
2. Remove `offset_top = -50.0` (VBoxContainer handles positioning)
3. Remove `anchors_preset = 12` (VBoxContainer handles layout)
4. Update script paths if needed

### 5.3 Solution #3: Use MarginContainer to Reserve Bottom Space

**Approach:**
- Wrap `AzgaarWebView` in MarginContainer with bottom margin = `UIConstants.BOTTOM_BAR_HEIGHT`
- Keep `BottomHBox` as sibling, positioned at bottom
- WebView respects margin, bottom bar overlays in reserved space

**Pros:**
- Explicit space reservation
- Clear layout intent
- Minimal restructuring

**Cons:**
- Adds extra container node
- MarginContainer may affect WebView sizing

**Implementation Steps:**
1. Add MarginContainer as child of `CenterContent`
2. Set `theme_override_constants/margin_bottom = UIConstants.BOTTOM_BAR_HEIGHT`
3. Move `AzgaarWebView` to be child of MarginContainer
4. Keep `BottomHBox` as child of `CenterPanel` with proper anchoring

### 5.4 Solution #4: Replace Magic Numbers with UIConstants (Required)

**Approach:**
- Replace all hard-coded values in `.tscn` with UIConstants references (via theme overrides or script-only, as `.tscn` doesn't support constants directly)
- Ensure `_apply_ui_constants()` runs early and overrides all hard-coded values
- Add explicit call to `_update_responsive_layout()` in `_ready()` after constants applied

**Implementation Steps:**
1. Audit `.tscn` for all magic numbers (split_offset, custom_minimum_size, offset_top)
2. Update `_apply_ui_constants()` to set all values explicitly
3. Add `_update_responsive_layout()` call at end of `_ready()`
4. Verify responsive behavior on different resolutions

### 5.5 Solution Priority Matrix

| Solution | Priority | Effort | Impact | Risk |
|----------|----------|--------|--------|------|
| #1: Move BottomHBox to root | CRITICAL | Medium | High | Low |
| #4: Replace magic numbers | HIGH | Low | Medium | Low |
| #2: Add margin to CenterContent | MEDIUM | Low | High | Medium |
| #3: Use MarginContainer | MEDIUM | Medium | Medium | Low |

**Recommended Approach:** Combine Solutions #1 and #4:
1. Move `BottomHBox` to root level (Solution #1)
2. Replace magic numbers via script (Solution #4)
3. Test and iterate
4. Consider Solution #2 as alternative if #1 causes issues

---

## 6. Updated Migration Plan

### Phase 1: Critical Fixes (Immediate)

**Goal:** Make bottom bar visible and ensure left/right panels render correctly.

**Tasks:**
1. **Move BottomHBox to root level:**
   - Edit `WorldBuilderUI.tscn`: Move `BottomHBox` node from `MainHSplit/CenterPanel/BottomHBox` to `WorldBuilderUI/BottomHBox`
   - Update anchors: `anchors_preset = 7` (PRESET_BOTTOM_WIDE)
   - Remove `offset_top = -50.0` (not needed with proper anchoring)
   - Update script paths: Change `$MainHSplit/CenterPanel/BottomHBox/...` to `$BottomHBox/...`

2. **Ensure responsive layout on initial load:**
   - Edit `WorldBuilderUI.gd`: Add `call_deferred("_update_responsive_layout")` at end of `_ready()`
   - Verify panel widths calculated correctly on startup

3. **Test visibility:**
   - Run project, verify bottom bar visible above WebView
   - Verify left sidebar (step buttons) visible
   - Verify right panel (parameters) visible

**Commit:** `"fix/genesis: Move BottomHBox to root level, fix bottom bar visibility"`

### Phase 2: Magic Number Elimination (High Priority)

**Goal:** Replace all magic numbers with UIConstants for GUI spec compliance.

**Tasks:**
1. **Update _apply_ui_constants() to override all hard-coded values:**
   - Ensure split_offset set from UIConstants
   - Ensure all button sizes set from UIConstants
   - Ensure all panel sizes set from UIConstants
   - Ensure bottom bar offset uses UIConstants

2. **Add explicit responsive layout call:**
   - Call `_update_responsive_layout()` in `_ready()` after constants applied
   - Verify works on different resolutions (1080p, 4K, ultrawide)

3. **Document remaining hard-coded values:**
   - Note which values must remain in `.tscn` (Godot limitation)
   - Ensure script overrides all of them

**Commit:** `"refactor/genesis: Replace magic numbers with UIConstants in WorldBuilderUI"`

### Phase 3: Layout Polish (Medium Priority)

**Goal:** Ensure proper spacing, margins, and responsive behavior.

**Tasks:**
1. **Add proper margins to CenterContent:**
   - Consider adding bottom margin if keeping bottom bar as overlay
   - Or ensure VBoxContainer spacing is correct if using Solution #2

2. **Verify HSplitContainer split behavior:**
   - Test split dragging works
   - Test min/max panel widths enforced
   - Test responsive calculations on window resize

3. **Test on multiple resolutions:**
   - 1080p (1920x1080)
   - 4K (3840x2160)
   - Ultrawide (2560x1080, 3440x1440)
   - Windowed mode resize

**Commit:** `"feat/genesis: Polish WorldBuilderUI layout and responsiveness"`

### Phase 4: Integration Testing (Low Priority)

**Goal:** Verify full integration works end-to-end.

**Tasks:**
1. **Test step navigation:**
   - Click step buttons, verify highlights update
   - Verify parameters populate correctly per step
   - Verify step title updates

2. **Test parameter syncing:**
   - Change parameters in right panel
   - Trigger generation, verify parameters synced to Azgaar
   - Verify generation completes and map updates

3. **Test bottom bar functionality:**
   - Test Back/Next navigation
   - Test Generate button
   - Test progress bar and status label updates

**Commit:** `"test/genesis: Integration testing for WorldBuilderUI"`

---

## 7. Risks and Mitigations

### 7.1 Risk: WebView Z-Order Still Covers UI

**Risk Level:** Medium

**Description:** Even after moving BottomHBox to root, WebView may render on separate layer, covering other UI elements.

**Mitigation:**
- Use CanvasLayer for bottom bar (guaranteed z-order above Control nodes)
- Or ensure WebView node is added to scene tree before BottomHBox (rendering order)
- Test on target hardware configurations

### 7.2 Risk: Panel Sizing Breaks on Small Screens

**Risk Level:** Low

**Description:** Left (220px) + Right (240px) + Center minimum may exceed small viewport widths.

**Mitigation:**
- `_update_responsive_layout()` already clamps to min/max values
- Test on 1024x768 and smaller resolutions
- Consider collapsing panels on very small screens (future enhancement)

### 7.3 Risk: Performance Impact of Full UI + Azgaar

**Risk Level:** Low (already tested)

**Description:** Full UI with Azgaar WebView may impact FPS.

**Mitigation:**
- Previous audits showed acceptable performance
- Monitor FPS during testing
- Consider lazy loading of parameter controls if needed

### 7.4 Risk: Script Path Changes Break Functionality

**Risk Level:** Low

**Description:** Moving BottomHBox changes node paths, scripts may reference old paths.

**Mitigation:**
- Use `@onready var` with full paths (already done in WorldBuilderUI.gd)
- Search for all references to `BottomHBox` path
- Test all button functionality after changes

---

## 8. Compliance Checklist

### 8.1 GUI Specification Section 11 Compliance

**Section 11.2.1: Node Hierarchy & Layout Fundamentals**
- ✅ Root node is Control with `anchors_preset = 15` (PRESET_FULL_RECT)
- ✅ Uses HSplitContainer for left/center/right layout
- ✅ Uses VBoxContainer/HBoxContainer for stacking
- ⚠️ **NON-COMPLIANT:** BottomHBox positioning (should be root-level or properly overlaid)
- ✅ Size flags set explicitly (`size_flags_horizontal = 3`, `size_flags_vertical = 3`)

**Section 11.2.2: Sizing & Positioning Rules**
- ❌ **NON-COMPLIANT:** Magic numbers present (split_offset=220, custom_minimum_size values, offset_top=-50)
- ✅ UIConstants.gd exists with proper constants
- ⚠️ **PARTIAL:** Script applies UIConstants but `.tscn` has hard-coded values
- ✅ Theme applied (`bg3_theme.tres`)

**Section 11.2.3: Theme & Styling Integration**
- ✅ Central theme applied (`bg3_theme.tres`)
- ✅ Theme overrides used for fonts/colors
- ✅ No hard-coded colors (uses theme)

**Section 11.2.5: World Generation Menus Structure**
- ✅ Left panel with step controls (StepSidebar with buttons) ✅ **CORRECT: Uses buttons, not TabContainer**
- ✅ Right panel with parameters (GlobalControls + ActiveParams)
- ✅ Center panel with preview (AzgaarWebView)
- ⚠️ **NON-COMPLIANT:** Bottom bar not properly overlaid (structure issue)
- ✅ Progress dialog structure exists (ProgressBar + StatusLabel)

**Section 11.2.6: Performance & Testing**
- ⚠️ **UNKNOWN:** FPS with full UI+Azgaar not measured in this audit
- ✅ Resize handling implemented (`_update_responsive_layout()`)

**Overall Compliance:** ~70% - Structure mostly correct but magic numbers and bottom bar positioning need fixes.

---

## 9. Recommendations and Next Steps

### 9.1 Immediate Actions (This Session)

1. **Move BottomHBox to root level** (Solution #1)
   - Edit `.tscn` file to restructure bottom bar
   - Update script paths if needed
   - Test visibility

2. **Add explicit responsive layout call**
   - Call `_update_responsive_layout()` in `_ready()`
   - Verify panels size correctly on startup

3. **Run project and verify**
   - Check bottom bar visible
   - Check left/right panels visible
   - Check WebView doesn't cover UI elements

### 9.2 Short-Term Actions (Next Session)

1. **Replace magic numbers** (Solution #4)
   - Update `_apply_ui_constants()` to override all values
   - Document which values must remain in `.tscn`
   - Test responsive behavior

2. **Polish layout margins/spacing**
   - Ensure proper spacing between panels
   - Verify bottom bar overlays correctly
   - Test on multiple resolutions

### 9.3 Medium-Term Actions (Future)

1. **Integration testing**
   - Test full step navigation flow
   - Test parameter syncing with Azgaar
   - Test generation and export workflows

2. **Performance validation**
   - Measure FPS with full UI + Azgaar
   - Optimize if needed (lazy loading, etc.)

3. **Accessibility improvements**
   - Verify keyboard navigation works
   - Verify focus indicators visible
   - Test with screen readers if applicable

### 9.4 Priority Order

1. **CRITICAL:** Move BottomHBox to root level (Solution #1) - Blocks user experience
2. **HIGH:** Replace magic numbers (Solution #4) - GUI spec compliance
3. **MEDIUM:** Layout polish and margins (Solution #2 or #3) - UX improvement
4. **LOW:** Integration testing and performance validation - Quality assurance

---

## 10. Conclusion

The World Builder UI structure is **mostly correct** (step sidebar uses buttons ✅, panels exist ✅, parameters populate dynamically ✅), but a **critical layout hierarchy issue** prevents the bottom navigation bar from rendering correctly. The WebView fills the entire center panel area, and the bottom bar's positioning as a child of `CenterPanel` causes it to be hidden or covered.

**Primary Fix Required:**
- Move `BottomHBox` to root level with proper anchoring to overlay above entire UI
- Ensure z-ordering guarantees bottom bar renders on top

**Secondary Fixes:**
- Replace magic numbers with UIConstants throughout
- Ensure responsive layout runs on initial load
- Add proper margins/spacing for polished layout

With these fixes, the UI should render correctly with all elements visible: step sidebar on left, Azgaar map in center, parameter controls on right, and navigation bar at bottom.

---

**Audit Complete**  
**Next Action:** Implement Solution #1 (Move BottomHBox to root level) and test visibility.

