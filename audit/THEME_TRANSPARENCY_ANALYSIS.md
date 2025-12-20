# THEME TRANSPARENCY & VISIBILITY ANALYSIS

## Analysis of `themes/bg3_theme.tres`

This report checks for:
1. StyleBox or constant overrides with alpha = 0 or transparent colors
2. Items containing "race", "column", or "header"
3. Theme default_font_size = 0
4. Custom styles that hide children

---

## 1. DEFAULT FONT SIZE

**Line 389:**
```
default_font_size = 18
```

**✅ NO ISSUE:** Font size is **18**, not 0. Theme font size is properly configured.

---

## 2. RACE-RELATED STYLES

### 2.1 Race Entry Button Styles

**Lines 408-410:**
```
Button/styles/bg3_race_entry_normal = SubResource("StyleBoxFlat_13")
Button/styles/bg3_race_entry_hover = SubResource("StyleBoxFlat_14")
Button/styles/bg3_race_entry_selected = SubResource("StyleBoxFlat_15")
```

**StyleBoxFlat_13** (bg3_race_entry_normal) - Lines 119-124:
- `bg_color = Color(0.117647, 0.137255, 0.156863, 1)` ✅ **alpha = 1.0** (fully opaque)
- `border_color = Color(0.235294, 0.235294, 0.235294, 1)` ✅ **alpha = 1.0**

**StyleBoxFlat_14** (bg3_race_entry_hover) - Lines 127-132:
- `bg_color = Color(0.176471, 0.211765, 0.258824, 1)` ✅ **alpha = 1.0**
- `border_color = Color(1, 0.843137, 0, 1)` ✅ **alpha = 1.0**

**StyleBoxFlat_15** (bg3_race_entry_selected) - Lines 135-144:
- `bg_color = Color(0.239216, 0.27451, 0.4, 1)` ✅ **alpha = 1.0**
- `border_color = Color(1, 0.843137, 0, 1)` ✅ **alpha = 1.0**

### 2.2 Race Button PanelContainer Styles

**Lines 429-432:**
```
PanelContainer/styles/race_button_normal = SubResource("StyleBoxFlat_34")
PanelContainer/styles/race_button_hover = SubResource("StyleBoxFlat_35")
PanelContainer/styles/race_button_pressed = SubResource("StyleBoxFlat_36")
PanelContainer/styles/race_button_selected = SubResource("StyleBoxFlat_37")
```

**StyleBoxFlat_34** (race_button_normal) - Lines 323-334:
- `bg_color = Color(0.15, 0.09, 0.05, 1)` ✅ **alpha = 1.0**
- `border_color = Color(0.8, 0.6, 0.2, 1)` ✅ **alpha = 1.0**
- `shadow_color = Color(0, 0, 0, 0.6)` - Shadow alpha = 0.6 (normal for shadows)

**StyleBoxFlat_35** (race_button_hover) - Lines 337-348:
- `bg_color = Color(0.2, 0.12, 0.07, 1)` ✅ **alpha = 1.0**
- `border_color = Color(1, 0.843137, 0, 1)` ✅ **alpha = 1.0**
- `shadow_color = Color(1, 0.843137, 0, 0.4)` - Shadow alpha = 0.4 (normal for glow effect)

**StyleBoxFlat_36** (race_button_pressed) - Lines 351-362:
- `bg_color = Color(0.18, 0.11, 0.06, 1)` ✅ **alpha = 1.0**
- `border_color = Color(1, 0.843137, 0, 1)` ✅ **alpha = 1.0**
- `shadow_color = Color(0, 0, 0, 0.6)` - Shadow alpha = 0.6 (normal for shadows)

**StyleBoxFlat_37** (race_button_selected) - Lines 365-376:
- `bg_color = Color(0.15, 0.09, 0.05, 1)` ✅ **alpha = 1.0**
- `border_color = Color(1, 0.843137, 0, 1)` ✅ **alpha = 1.0**
- `shadow_color = Color(1, 0.843137, 0, 0.6)` - Shadow alpha = 0.6 (normal for glow effect)

**✅ NO TRANSPARENCY ISSUES:** All race-related StyleBoxes have fully opaque backgrounds (alpha = 1.0).

---

## 3. COLUMN-RELATED STYLES

**Search Result:** No styles in the theme file contain "column" in their name.

**✅ NO COLUMN-SPECIFIC STYLES:** No theme overrides for columns found.

---

## 4. HEADER-RELATED STYLES

**Search Result:** No styles in the theme file contain "header" in their name.

**✅ NO HEADER-SPECIFIC STYLES:** No theme overrides for headers found.

---

## 5. LABEL FONT COLORS

**Line 398:**
```
Label/colors/font_color = Color(1, 0.843137, 0, 1)
```

**✅ NO TRANSPARENCY ISSUE:** Label font color has **alpha = 1.0** (fully opaque).

**Label Shadow Color:**
```
Label/colors/font_shadow_color = Color(0, 0, 0, 0.5)
```

**✅ NORMAL:** Shadow color with alpha = 0.5 is expected for shadow effects.

---

## 6. BUTTON FONT COLORS

**Lines 390-393:**
```
Button/colors/font_color = Color(1, 0.843137, 0, 1)
Button/colors/font_hover_color = Color(1, 0.95, 0.75, 1)
Button/colors/font_pressed_color = Color(0.85, 0.7, 0.4, 1)
Button/colors/font_disabled_color = Color(0.5, 0.5, 0.5, 1)
```

**✅ ALL OPAQUE:**
- `font_color` alpha = 1.0
- `font_hover_color` alpha = 1.0
- `font_pressed_color` alpha = 1.0
- `font_disabled_color` alpha = 1.0

---

## 7. ColorRect COLORS

**Line 435:**
```
ColorRect/colors/bg_dark = Color(0.0588235, 0.0588235, 0.0588235, 1)
```

**✅ NO TRANSPARENCY ISSUE:** ColorRect bg_dark has **alpha = 1.0** (fully opaque).

---

## 8. COMPLETE ALPHA CHANNEL AUDIT

### 8.1 Background Colors (bg_color)

All StyleBoxFlat resources checked:
- **StyleBoxFlat_1 through StyleBoxFlat_39:** All have `bg_color` alpha = 1.0 ✅

**No zero-alpha backgrounds found.**

### 8.2 Border Colors

Most border colors have alpha = 1.0. Some have alpha < 1.0 for visual effects:
- StyleBoxFlat_4: `border_color = Color(0.85, 0.7, 0.4, 0.5)` - alpha = 0.5 (intentional transparency for disabled state)
- StyleBoxFlat_5: `border_color = Color(0.85, 0.7, 0.4, 0.5)` - alpha = 0.5
- StyleBoxFlat_6: `border_color = Color(0.85, 0.7, 0.4, 0.5)` - alpha = 0.5
- StyleBoxFlat_8: `border_color = Color(0.85, 0.7, 0.4, 0.3)` - alpha = 0.3
- StyleBoxFlat_9: `border_color = Color(0.85, 0.7, 0.4, 0.6)` - alpha = 0.6
- StyleBoxFlat_10: `border_color = Color(0.85, 0.7, 0.4, 0.8)` - alpha = 0.8
- StyleBoxFlat_11: `border_color = Color(0.5, 0.5, 0.5, 0.2)` - alpha = 0.2

**✅ NO ISSUE:** Border transparency is intentional for visual styling. Backgrounds remain fully opaque.

### 8.3 Shadow Colors

Some StyleBoxes have shadow effects:
- StyleBoxFlat_34: `shadow_color = Color(0, 0, 0, 0.6)` - alpha = 0.6
- StyleBoxFlat_35: `shadow_color = Color(1, 0.843137, 0, 0.4)` - alpha = 0.4
- StyleBoxFlat_36: `shadow_color = Color(0, 0, 0, 0.6)` - alpha = 0.6
- StyleBoxFlat_37: `shadow_color = Color(1, 0.843137, 0, 0.6)` - alpha = 0.6

**✅ NO ISSUE:** Shadow transparency is normal and expected for shadow effects.

---

## 9. STYLES THAT HIDE CHILDREN

**Search Result:** No StyleBox properties found that would hide children:
- No `content_margin_*` set to hide content
- No `expand_margin_*` set to hide content
- No special flags that would hide child nodes

**✅ NO ISSUE:** No styles found that would hide child elements.

---

## 10. THEME CONSTANTS OVERRIDE CHECK

### Constants Related to Visibility:

**Label constants:**
```
Label/constants/shadow_offset_x = 2
Label/constants/shadow_offset_y = 2
```

**✅ NO ISSUE:** These are shadow offsets, not visibility settings.

**No other constants found that would affect visibility or transparency.**

---

## 11. SEARCH FOR ZERO-ALPHA COLORS

**Pattern Search:** Looking for `Color(..., 0)` or `Color(..., 0.0)` patterns

**Result:** No colors found with alpha channel = 0 or 0.0.

**✅ NO TRANSPARENT COLORS FOUND:** All colors have alpha > 0.

---

## 12. SUMMARY

### ✅ ALL CHECKS PASSED:

1. **default_font_size:** 18 (not 0) ✅
2. **Race-related styles:** All have alpha = 1.0 ✅
3. **Column-related styles:** None found (not an issue) ✅
4. **Header-related styles:** None found (not an issue) ✅
5. **Label font_color:** alpha = 1.0 ✅
6. **Button font_colors:** All have alpha = 1.0 ✅
7. **ColorRect colors:** alpha = 1.0 ✅
8. **All StyleBox bg_color:** alpha = 1.0 ✅
9. **No zero-alpha colors:** Found ✅
10. **No styles that hide children:** Found ✅

### ⚠️ INTENTIONAL TRANSPARENCY (NOT AN ISSUE):

- **Border colors:** Some have alpha < 1.0 for visual effects (0.2-0.8 range)
- **Shadow colors:** Some have alpha < 1.0 for shadow effects (0.4-0.6 range)

**These are intentional design choices and do not affect element visibility.**

---

## 13. CONCLUSION

**✅ THEME FILE IS CLEAN:** No transparency or visibility issues found in the theme file.

All race-related, column-related, and header-related styles (where they exist) are fully opaque and visible. The theme does not contain any hidden styles or zero-alpha colors that would cause elements to be invisible.

**If race columns are not displaying, the issue is NOT in the theme file.**

---

**Report Generated:** Complete transparency and visibility analysis of bg3_theme.tres

