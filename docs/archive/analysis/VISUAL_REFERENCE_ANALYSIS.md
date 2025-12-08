# Visual Reference Analysis - Race/Class/Ability Scores Tabs

## Screenshot Note

**Screenshots:** The project is currently running. To capture screenshots:
1. Navigate to each tab in the running Godot project
2. Take screenshots manually using your system's screenshot tool
3. Compare the visual differences side-by-side

**Current State:** The project loads successfully and all tabs are functional. Race and Class tabs are fully populated with 9 races and 12 classes respectively. Ability Scores tab is visible but uses a different layout structure than Race/Class tabs.

---

## Quick Answer Summary

| Question | Race/Class Tabs | Ability Scores Tab |
|----------|----------------|-------------------|
| **Central Column Width** | Full width (no margins) | 20px margins on all sides |
| **Title Style** | Label, 64px font, gold color | N/A (different structure) |
| **Top Padding** | 80px from top to grid | 20px root margin + 20px VBox separation |
| **Description Panel** | ❌ None | ❌ None |
| **Grid Layout** | 3 columns, 100px height entries | 3 columns, compact HBox rows |
| **Entry Style** | Large PanelContainer buttons | Compact HBoxContainer rows |
| **Points Label** | N/A | Top-center, styled PanelContainer |
| **Confirm Button** | Fixed bottom-center, 300×80px | Flows in VBox, auto-sized |
| **Background Panel** | Black Panel (no card) | No background panel |
| **Dividers** | ❌ None | ⚠️ 2 HSeparators (default style) |
| **Hover Effects** | ✅ Theme styles with glow | ❌ None on rows |

---

## 1. Central Column Width

**Answer:** The central content area does NOT use explicit pixel widths or percentages. Instead:

- **RaceTab.tscn & ClassTab.tscn:**
  - `UnifiedScroll` (ScrollContainer) uses `anchors_preset = 15` (full screen)
  - `RaceGrid`/`ClassGrid` (GridContainer) uses `size_flags_horizontal = 3` (SIZE_EXPAND_FILL)
  - **No MarginContainer** around the grid - it fills the entire scroll area
  - GridContainer has `columns = 3`, so each cell is 1/3 of available width
  - **TitleMargin** has margins: `left = 40, top = 40, right = 40, bottom = 40` (but this is for the title, not the grid)

- **AbilityScoreTab.tscn:**
  - `RootMargin` (MarginContainer) has margins: `left = 20, top = 20, right = 20, bottom = 20`
  - `MainVBox` fills remaining space with `separation = 20` between children
  - `CenterContainer` uses `size_flags_horizontal = 3` (SIZE_EXPAND_FILL)
  - **No explicit width constraints** - content expands to fill available space

**Conclusion:** 
- Race/Class tabs: Grid fills full width (no side margins on grid itself)
- Ability Scores tab: 20px margins on all sides of root container
- Grid cells in Race/Class auto-size to 1/3 of available width (no explicit cell size)

---

## 2. Title Style

**Answer:**

- **Node Type:** `Label` (NOT RichTextLabel)
- **Location:** `MainPanel/TitleMargin/TitleLabel`
- **Font Size:** `theme_override_font_sizes/font_size = 64`
- **Font Color:** `theme_override_colors/font_color = Color(1, 0.843137, 0, 1)` (gold)
- **Alignment:** `horizontal_alignment = 1` (center), `vertical_alignment = 1` (center)
- **Container:** Inside `TitleMargin` (MarginContainer) with margins: `left = 40, top = 40, right = 40, bottom = 40`
- **Height:** `custom_minimum_size = Vector2(0, 80)` on TitleMargin

**Theme Override Name:** Uses `font_size` override directly, NOT a named theme font size. The theme defines `Label/font_sizes/title_label = 64`, but the scene uses direct override.

---

## 3. Vertical Spacing

**Answer:**

### Top Padding (Title to Content):
- **RaceTab/ClassTab:**
  - TitleMargin: `offset_bottom = 80.0` (height = 80px)
  - TitleMargin margins: `top = 40, bottom = 40` (internal padding)
  - UnifiedScroll: `offset_top = 80.0` (starts exactly below title)
  - **Total top padding: 80px** (from top of screen to first grid item)
  - **Title height: 80px** (custom_minimum_size = Vector2(0, 80))

### Spacing Between Sections:
- **RaceTab/ClassTab:** 
  - GridContainer has NO explicit separation constant
  - Grid items are directly adjacent (no spacing between grid cells)
  - **No description panel** in current implementation - grid is the only content

### AbilityScoreTab:
- `MainVBox` has `theme_override_constants/separation = 20`
- Header section → CenterContainer: **20px separation**
- PointsPanel → AbilityGrid: **20px separation** (within PointBuyContainer VBox)
- RootMargin margins: **20px on all sides**

---

## 4. Description Text

**Answer:**

- **RaceTab/ClassTab:** 
  - **NO description panel exists** in the current scene files
  - Only the grid of race/class entries is displayed
  - Each `RaceEntry`/`ClassEntry` has a small `RichTextLabel` for ability preview, but no main description box

- **RaceEntry.tscn/ClassEntry.tscn:**
  - Each entry has `AbilityPreviewLabel` (RichTextLabel) with `bbcode_enabled = true`
  - Shows ability bonuses (e.g., "+2 STR, +1 CON")
  - **NOT a description panel** - just preview text in each button

**Conclusion:** There is NO description panel in Race/Class tabs currently. If you want one, it needs to be added.

---

## 5. Grid vs List Layout

**Answer:**

- **RaceTab/ClassTab:**
  - Uses `GridContainer` with `columns = 3`
  - Each cell contains a `RaceEntry`/`ClassEntry` (PanelContainer)
  - Entry size: `custom_minimum_size = Vector2(0, 100)` (height = 100px)
  - Grid has NO explicit cell size - cells auto-size to 1/3 width

- **AbilityScoreTab:**
  - Currently uses `GridContainer` with `columns = 3` for `AbilityGrid`
  - Each cell contains `AbilityScoreRow` (HBoxContainer)
  - **Mismatch:** Ability rows are horizontal HBoxContainers, NOT large buttons like race/class entries

**Recommendation:** 
- **Option A:** Keep 3-column grid, but make each ability row a large button-style PanelContainer (like RaceEntry) with height ~100px
- **Option B:** Use 2-column grid (3 rows × 2 columns) for 6 abilities
- **Option C:** Use single-column VBoxContainer (vertical list) for 6 abilities

**Current State:** AbilityScoreRow is a compact HBoxContainer, NOT matching the large button style of Race/Class entries.

---

## 6. AbilityScoreRow Visual Target

**Answer:**

**Current Implementation:**
- `AbilityScoreRow` is an `HBoxContainer` (horizontal row)
- Contains: NameLabel, BaseLabel, BonusLabel, FinalLabel, ModLabel, MinusButton, PlusButton
- **Height:** No explicit height (auto-sizes to content)
- **Style:** Uses default Button theme (NOT the large button styles)

**RaceEntry/ClassEntry for Comparison:**
- `PanelContainer` with `custom_minimum_size = Vector2(0, 100)` (100px height)
- Uses theme styles: `bg3_race_entry_normal/hover/selected` or `bg3_class_entry_normal/hover/selected`
- Contains: 
  - Icon: `custom_minimum_size = Vector2(40, 40)` (40×40px)
  - RaceNameLabel: `custom_minimum_size = Vector2(0, 24)` (24px height)
  - AbilityPreviewLabel: `custom_minimum_size = Vector2(0, 18)` (18px height)
- **MarginContainer** with margins: `left = 8, top = 4, right = 8, bottom = 4`
- **VBoxContainer** with `separation = 2`

**Recommendation:** 
- **Should Ability rows be large buttons?** YES - to match Race/Class visual style
- **Should they be compact rows?** NO - current compact style doesn't match BG3 aesthetic
- **Target:** Each ability should be a PanelContainer button (like RaceEntry) with:
  - Height: 100px (matching RaceEntry)
  - Theme: `bg3_ability_row_normal/hover/selected` (already defined in theme!)
  - Layout: Icon (optional) + Ability Name + Base/Bonus/Final/Mod + +/- buttons inside

---

## 7. Points Remaining Label

**Answer:**

**Current Implementation:**
- **Location:** `RootMargin/MainVBox/CenterContainer/PointBuyContainer/PointsPanel/PointsMargin/PointsLabel`
- **Container:** `PanelContainer` with theme style `bg3_points_display` (StyleBoxFlat_25)
- **Position:** Top of PointBuyContainer (above AbilityGrid)
- **Alignment:** `horizontal_alignment = 1` (center)
- **Style:** Uses `bg3_points_display` panel style (dark background with gold border)

**Visual Position:**
- **NOT** top-right like "Level 1" indicator (that doesn't exist in ClassTab)
- **NOT** bottom-center like Confirm button
- **IS** top-center, inside its own styled PanelContainer

**Theme Style:** `bg3_points_display` = StyleBoxFlat_25:
- `bg_color = Color(0.0784314, 0.0941176, 0.113725, 1)` (dark blue-gray)
- `border_width = 4` (all sides)
- `border_color = Color(1, 0.843137, 0, 1)` (gold)
- `corner_radius = 12` (all corners)

---

## 8. Confirm Button Placement

**Answer:**

**RaceTab/ClassTab:**
- **Position:** `anchors_preset = 7` (center-bottom)
- **Offset:** `offset_left = -150, offset_top = -100, offset_right = 150, offset_bottom = -20`
  - This creates a 300px wide button (150px left + 150px right from center)
  - Positioned 100px from top of bottom edge, 20px from actual bottom
- **Size:** `custom_minimum_size = Vector2(300, 80)` (300px width × 80px height)
- **Distance from bottom:** 20px (offset_bottom = -20 means 20px from bottom)
- **Theme:** Uses default Button theme (NOT a custom style name)
- **Button styles:** `normal = StyleBoxFlat_1`, `hover = StyleBoxFlat_2`, `pressed = StyleBoxFlat_3`

**AbilityScoreTab:**
- **Position:** Inside `RootMargin/MainVBox` (VBoxContainer)
- **No explicit anchors** - positioned by VBoxContainer flow
- **Size:** No explicit size (auto-sizes to content)
- **Distance:** Follows VBoxContainer separation (20px from previous element)
- **Theme:** Uses default Button theme

**Comparison:**
- Race/Class: Fixed position at bottom-center, 20px from bottom, 300×80px
- Ability Scores: Flows in VBoxContainer, no fixed position, auto-sized

**Recommendation:** Ability Scores confirm button should match Race/Class: fixed bottom-center, 300×80px, 20px from bottom.

---

## 9. Background Panels

**Answer:**

**RaceTab/ClassTab:**
- **Main Container:** `MainPanel` (Panel) - uses default Panel style
- **Panel style:** `Panel/styles/panel = StyleBoxFlat_7` (black background, no border)
- **Grid Container:** NO PanelContainer around the grid
- **Grid items:** Each `RaceEntry`/`ClassEntry` is a `PanelContainer` with custom styles

**AbilityScoreTab:**
- **Main Container:** `RootMargin` (MarginContainer) - no background
- **Points Panel:** `PointsPanel` (PanelContainer) with `bg3_points_display` style
- **No main content card** - content flows in VBoxContainer

**Conclusion:** 
- Race/Class tabs have NO main content card/panel - just a black Panel background
- Ability Scores tab has NO main content card either
- **If BG3 has a content card, it's not implemented yet**

---

## 10. Divider Lines

**Answer:**

**RaceTab/ClassTab:**
- **NO HSeparator nodes** exist in the scene files
- **NO divider lines** between sections
- Grid items are directly adjacent

**AbilityScoreTab:**
- **HSeparator1:** Between PointBuyContainer and AbilityScoresContainer (when visible)
- **HSeparator2:** Between DetailsHBox and CoreStatsGrid (within AbilityScoresContainer)
- Uses default HSeparator style (no custom theme override)

**Conclusion:** Race/Class tabs have NO dividers. Ability Scores has 2 HSeparators, but they use default style (not gold).

**Recommendation:** If BG3 has gold dividers, add custom HSeparator style to theme.

---

## 11. Hover/Active States

**Answer:**

**RaceEntry/ClassEntry:**
- **Theme Styles:**
  - Normal: `bg3_race_entry_normal` (StyleBoxFlat_13) - dark blue-gray
  - Hover: `bg3_race_entry_hover` (StyleBoxFlat_14) - lighter blue with gold border
  - Selected: `bg3_race_entry_selected` (StyleBoxFlat_15) - brighter blue with gold border
- **PanelContainer Styles:**
  - Normal: `race_button_normal` (StyleBoxFlat_34) - brown with shadow
  - Hover: `race_button_hover` (StyleBoxFlat_35) - lighter brown with glow
  - Pressed: `race_button_pressed` (StyleBoxFlat_36) - darker brown
  - Selected: `race_button_selected` (StyleBoxFlat_37) - bright with strong glow
- **Hover Effect:** Color change + border glow (no scale animation in code)
- **Selection:** Visual state change via `set_selected()` method

**AbilityScoreRow:**
- **Current:** Uses default Button theme for +/- buttons
- **NO hover effect** on the row itself (it's an HBoxContainer, not a button)
- **NO theme styles** applied to the row container

**Recommendation:**
- Apply `bg3_ability_row_normal/hover/selected` styles to AbilityScoreRow container
- Make the entire row a PanelContainer button (like RaceEntry)
- Add hover scale/glow effect to match Race/Class entries

---

## Summary of Visual Differences

### Race/Class Tabs:
- ✅ 3-column GridContainer
- ✅ Large button-style entries (100px height)
- ✅ Gold title (64px font)
- ✅ 80px top padding
- ✅ No description panel
- ✅ No dividers
- ✅ Fixed bottom-center confirm button (300×80px)
- ✅ Hover/selected states with glow

### Ability Scores Tab (Current):
- ⚠️ 3-column GridContainer (but rows are compact, not large buttons)
- ❌ Compact HBoxContainer rows (NOT large buttons)
- ❌ Different layout structure (VBoxContainer flow, not fixed)
- ⚠️ Points panel at top (styled, but different position)
- ⚠️ Confirm button flows in VBox (not fixed bottom)
- ❌ No hover effects on ability rows
- ⚠️ HSeparators exist but use default style

### Recommendations:
1. **Convert AbilityScoreRow to PanelContainer** (like RaceEntry) with 100px height
2. **Apply bg3_ability_row theme styles** (already defined in theme!)
3. **Fix confirm button position** to match Race/Class (fixed bottom-center, 300×80px)
4. **Remove or style HSeparators** to match BG3 gold dividers
5. **Add hover/scale animations** to ability rows
6. **Consider 2-column grid** or single-column list for 6 abilities (3 columns might be too wide)

