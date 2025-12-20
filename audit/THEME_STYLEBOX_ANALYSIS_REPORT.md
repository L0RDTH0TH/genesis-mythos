# Theme & StyleBox Analysis Report

## 1. Project-Wide Theme File

**File Name:** `bg3_theme.tres`  
**Path:** `res://themes/bg3_theme.tres`  
**Set in:** `project.godot` line 32: `theme/custom="res://themes/bg3_theme.tres"`

---

## 2. TabContainer/Tabs StyleBox Analysis

### Tab-Related StyleBoxes in Theme

The theme defines **Button tab styles** (lines 403-407):

```
Button/styles/tab_normal = SubResource("StyleBoxFlat_8")
Button/styles/tab_hover = SubResource("StyleBoxFlat_9")
Button/styles/tab_pressed = SubResource("StyleBoxFlat_10")
Button/styles/tab_disabled = SubResource("StyleBoxFlat_11")
Button/styles/tab_selected = SubResource("StyleBoxFlat_12")
```

### Alpha Channel Analysis

**StyleBoxFlat_8 (tab_normal)** - Lines 78-84:
- `bg_color = Color(0.12, 0.1, 0.08, 1)` ✅ **alpha = 1.0** (fully opaque)
- `border_color = Color(0.85, 0.7, 0.4, 0.3)` - border alpha = 0.3 (semi-transparent border, but background is opaque)

**StyleBoxFlat_9 (tab_hover)** - Lines 86-92:
- `bg_color = Color(0.18, 0.15, 0.12, 1)` ✅ **alpha = 1.0** (fully opaque)
- `border_color = Color(0.85, 0.7, 0.4, 0.6)` - border alpha = 0.6

**StyleBoxFlat_10 (tab_pressed)** - Lines 94-100:
- `bg_color = Color(0.22, 0.18, 0.14, 1)` ✅ **alpha = 1.0** (fully opaque)
- `border_color = Color(0.85, 0.7, 0.4, 0.8)` - border alpha = 0.8

**StyleBoxFlat_11 (tab_disabled)** - Lines 102-108:
- `bg_color = Color(0.08, 0.06, 0.05, 1)` ✅ **alpha = 1.0** (fully opaque)
- `border_color = Color(0.5, 0.5, 0.5, 0.2)` - border alpha = 0.2

**StyleBoxFlat_12 (tab_selected)** - Lines 110-116:
- `bg_color = Color(0.25, 0.2, 0.15, 1)` ✅ **alpha = 1.0** (fully opaque)
- `border_color = Color(0.95, 0.85, 0.6, 1)` - border alpha = 1.0

### Font Color Analysis

**Button font colors** (lines 390-393):
- `font_color = Color(1, 0.843137, 0, 1)` ✅ **alpha = 1.0** (fully opaque)
- `font_hover_color = Color(1, 0.95, 0.75, 1)` ✅ **alpha = 1.0** (fully opaque)
- `font_pressed_color = Color(0.85, 0.7, 0.4, 1)` ✅ **alpha = 1.0** (fully opaque)
- `font_disabled_color = Color(0.5, 0.5, 0.5, 1)` ✅ **alpha = 1.0** (fully opaque)

### Panel Styles (for TabContainer if it were a Panel)

**Panel/styles/panel** (StyleBoxFlat_7) - Line 76:
- `bg_color = Color(0.062745, 0.062745, 0.062745, 1)` ✅ **alpha = 1.0** (fully opaque)

### Summary of Tab-Related StyleBoxes

✅ **NO TRANSPARENCY ISSUES FOUND:**
- All tab StyleBox `bg_color` values have **alpha = 1.0** (fully opaque)
- All Button font colors have **alpha = 1.0** (fully opaque)
- Border colors have varying alpha (0.2-0.8), but borders don't affect background visibility
- No transparent backgrounds found

---

## 3. TabContainer Theme Override Check

### TabContainer Node (VBoxContainer)

**Scene:** `res://scenes/character_creation/tabs/TabNavigation.tscn`  
**Node Path:** `TabNavigation/TabContainer`  
**Type:** `VBoxContainer` (NOT Godot's TabContainer class)

**Theme Overrides Found:**
```56:67:scenes/character_creation/tabs/TabNavigation.tscn
[node name="TabContainer" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 80.0
offset_top = 120.0
offset_right = -80.0
offset_bottom = -120.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 12
```

**Theme Override:** Only `theme_override_constants/separation = 12` (spacing between children)

**Theme Assignment:**
- ❌ **NO `theme = null`** found
- ❌ **NO custom theme override** that would affect visibility
- ✅ Uses project-wide theme from `bg3_theme.tres`

### TabNavigation Root Node

**Scene:** `res://scenes/character_creation/tabs/TabNavigation.tscn`  
**Node:** `TabNavigation` (Control)

**Theme Overrides:** None found in scene file

### CharacterCreationRoot Scene

**Scene:** `res://scenes/character_creation/CharacterCreationRoot.tscn`  
**Line 36:** `theme = ExtResource("3_0")` - References `bg3_theme.tres`

**Theme Override on TabNavigation Instance:**
- No theme override found on the TabNavigation instance in CharacterCreationRoot.tscn

---

## 4. Important Finding

### ⚠️ Tab Styles Don't Apply to VBoxContainer

The theme defines `Button/styles/tab_*` styles, but:

1. **TabContainer is a VBoxContainer**, not a TabContainer class
2. **VBoxContainer doesn't use tab styles** - it's just a layout container
3. **Button children** inside TabContainer use their own theme overrides (see TabNavigation.tscn lines 72-147)

### Button Theme Overrides in TabNavigation

Each Button in TabNavigation.tscn has **explicit theme overrides**:

```69:80:scenes/character_creation/tabs/TabNavigation.tscn
[node name="RaceButton" type="Button" parent="TabContainer"]
layout_mode = 2
custom_minimum_size = Vector2(0, 90)
theme_override_styles/normal = SubResource("StyleBoxFlat_1")
theme_override_styles/hover = SubResource("StyleBoxFlat_2")
theme_override_styles/pressed = SubResource("StyleBoxFlat_3")
theme_override_styles/disabled = SubResource("StyleBoxFlat_4")
theme_override_styles/focus = SubResource("StyleBoxEmpty_1")
theme_override_font_sizes/font_size = 32
text = "1  RACE"
```

**These StyleBoxes are defined locally in TabNavigation.tscn**, not from the theme file.

**Local StyleBoxes in TabNavigation.tscn:**
- StyleBoxFlat_1 (normal): `bg_color = Color(0.12, 0.1, 0.08, 1)` ✅ alpha = 1.0
- StyleBoxFlat_2 (hover): `bg_color = Color(0.18, 0.15, 0.12, 1)` ✅ alpha = 1.0
- StyleBoxFlat_3 (pressed): `bg_color = Color(0.22, 0.18, 0.14, 1)` ✅ alpha = 1.0
- StyleBoxFlat_4 (disabled): `bg_color = Color(0.08, 0.06, 0.05, 1)` ✅ alpha = 1.0
- StyleBoxFlat_5 (selected - created in script): `bg_color = Color(0.25, 0.2, 0.15, 1)` ✅ alpha = 1.0

---

## 5. Final Summary

### ✅ Theme File Analysis Results:

1. **Theme File:** `res://themes/bg3_theme.tres` ✅
2. **Tab StyleBoxes:** All have `bg_color.a = 1.0` ✅ (no transparency)
3. **Font Colors:** All have `alpha = 1.0` ✅ (no transparency)
4. **TabContainer Theme:** Uses project theme, only overrides `separation` constant ✅
5. **No `theme = null`:** TabContainer inherits theme properly ✅

### ⚠️ Key Insight:

The **TabContainer (VBoxContainer) doesn't use theme tab styles** - it's just a layout container. The **Button children** use **local StyleBox overrides** defined in `TabNavigation.tscn`, and all of those have **alpha = 1.0** (fully opaque).

**Conclusion:** **NO THEME/STYLEBOX ISSUES** that would cause visibility problems. All StyleBoxes and colors are fully opaque.

