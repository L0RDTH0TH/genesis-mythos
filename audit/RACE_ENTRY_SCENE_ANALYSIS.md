# RACE ENTRY SCENE - COMPLETE NODE ANALYSIS

## Scene File
**Path:** `scenes/character_creation/tabs/components/RaceEntry.tscn`

This document analyzes every node in the race entry prefab scene, checking for:
- Clip Contents settings
- Layout presets that force size = Vector2(0,0)
- Visibility flags
- Size properties

---

## 1. NODE HIERARCHY

```
RaceEntry (PanelContainer - ROOT)
└── MarginContainer
    └── VBoxContainer
        ├── Icon (TextureRect)
        ├── RaceNameLabel (Label)
        └── AbilityPreviewLabel (RichTextLabel)
```

---

## 2. DETAILED NODE ANALYSIS

### 2.1 Root Node: RaceEntry

**Type:** `PanelContainer`  
**Path:** `.` (root)  
**Lines:** 6-13

```6:13:scenes/character_creation/tabs/components/RaceEntry.tscn
[node name="RaceEntry" type="PanelContainer"]
layout_mode = 2
custom_minimum_size = Vector2(0, 90)
size_flags_horizontal = 3
size_flags_vertical = 0
clip_contents = true
mouse_filter = 0
script = ExtResource("1_0")
```

**Properties:**
- ✅ **clip_contents:** `true` ⚠️ **CLIPPING ENABLED**
- **layout_mode:** `2` (PRESET_MODE_MINSIZE)
- **custom_minimum_size:** `Vector2(0, 90)` ✅ **Height = 90 (NOT 0)**
- **size_flags_horizontal:** `3` (SIZE_EXPAND_FILL)
- **size_flags_vertical:** `0` (SIZE_SHRINK_CENTER)
- **mouse_filter:** `0` (MOUSE_FILTER_STOP)
- **visible:** NOT SET (defaults to `true`)
- **modulate:** NOT SET (defaults to `Color(1,1,1,1)`)

**⚠️ ISSUE FOUND:** `clip_contents = true` on root PanelContainer will clip child content that extends beyond the panel bounds.

---

### 2.2 MarginContainer

**Type:** `MarginContainer`  
**Path:** `MarginContainer`  
**Parent:** RaceEntry  
**Lines:** 15-22

```15:22:scenes/character_creation/tabs/components/RaceEntry.tscn
[node name="MarginContainer" type="MarginContainer" parent="."]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 0
theme_override_constants/margin_left = 8
theme_override_constants/margin_top = 4
theme_override_constants/margin_right = 8
theme_override_constants/margin_bottom = 4
```

**Properties:**
- ✅ **clip_contents:** NOT SET (defaults to `false`) ✅ **NO CLIPPING**
- **layout_mode:** `2` (PRESET_MODE_MINSIZE)
- **size_flags_horizontal:** `3` (SIZE_EXPAND_FILL)
- **size_flags_vertical:** `0` (SIZE_SHRINK_CENTER)
- **Margins:** left=8, top=4, right=8, bottom=4
- **visible:** NOT SET (defaults to `true`)
- **modulate:** NOT SET (defaults to `Color(1,1,1,1)`)
- **Size:** NOT SET (uses layout_mode to calculate from children)

**✅ NO ISSUES:** MarginContainer does not clip contents and has proper layout flags.

---

### 2.3 VBoxContainer

**Type:** `VBoxContainer`  
**Path:** `MarginContainer/VBoxContainer`  
**Parent:** MarginContainer  
**Lines:** 24-28

```24:28:scenes/character_creation/tabs/components/RaceEntry.tscn
[node name="VBoxContainer" type="VBoxContainer" parent="MarginContainer"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 0
theme_override_constants/separation = 2
```

**Properties:**
- ✅ **clip_contents:** NOT SET (defaults to `false`) ✅ **NO CLIPPING**
- **layout_mode:** `2` (PRESET_MODE_MINSIZE)
- **size_flags_horizontal:** `3` (SIZE_EXPAND_FILL)
- **size_flags_vertical:** `0` (SIZE_SHRINK_CENTER)
- **separation:** `2`
- **visible:** NOT SET (defaults to `true`)
- **modulate:** NOT SET (defaults to `Color(1,1,1,1)`)
- **Size:** NOT SET (uses layout_mode to calculate from children)

**✅ NO ISSUES:** VBoxContainer does not clip contents and has proper layout flags.

---

### 2.4 Icon (TextureRect)

**Type:** `TextureRect`  
**Path:** `MarginContainer/VBoxContainer/Icon`  
**Parent:** VBoxContainer  
**Lines:** 30-37

```30:37:scenes/character_creation/tabs/components/RaceEntry.tscn
[node name="Icon" type="TextureRect" parent="MarginContainer/VBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 0
custom_minimum_size = Vector2(40, 40)
expand_mode = 1
stretch_mode = 5
```

**Properties:**
- ✅ **clip_contents:** NOT SET (defaults to `false`) ✅ **NO CLIPPING**
- **layout_mode:** `2` (PRESET_MODE_MINSIZE)
- **size_flags_horizontal:** `3` (SIZE_EXPAND_FILL)
- **size_flags_vertical:** `0` (SIZE_SHRINK_CENTER)
- **custom_minimum_size:** `Vector2(40, 40)` ✅ **Size = 40x40 (NOT 0x0)**
- **expand_mode:** `1` (EXPAND_FIT_WIDTH)
- **stretch_mode:** `5` (STRETCH_KEEP_ASPECT_CENTERED)
- **visible:** NOT SET (defaults to `true`)
- **modulate:** NOT SET (defaults to `Color(1,1,1,1)`)

**⚠️ CLIPPING PARENT:** Icon is inside containers that eventually lead to root `RaceEntry` which has `clip_contents = true`. If Icon exceeds 40x40, it will be clipped.

**✅ NO SIZE ISSUES:** Icon has valid minimum size of 40x40.

---

### 2.5 RaceNameLabel (Label)

**Type:** `Label`  
**Path:** `MarginContainer/VBoxContainer/RaceNameLabel`  
**Parent:** VBoxContainer  
**Lines:** 39-49

```39:49:scenes/character_creation/tabs/components/RaceEntry.tscn
[node name="RaceNameLabel" type="Label" parent="MarginContainer/VBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
size_flags_vertical = 0
custom_minimum_size = Vector2(0, 24)
theme_override_font_sizes/font_size = 16
theme_override_colors/font_color = Color(1, 0.843137, 0, 1)
text = "Race Name"
horizontal_alignment = 1
vertical_alignment = 1
autowrap_mode = 3
```

**Properties:**
- ✅ **clip_contents:** NOT SET (defaults to `false`) ✅ **NO CLIPPING ON LABEL**
- **layout_mode:** `2` (PRESET_MODE_MINSIZE)
- **size_flags_horizontal:** NOT SET (defaults to `0` = SIZE_SHRINK_CENTER) ⚠️ **MISSING**
- **size_flags_vertical:** `0` (SIZE_SHRINK_CENTER)
- **custom_minimum_size:** `Vector2(0, 24)` ⚠️ **Width = 0, Height = 24**
- **font_size:** `16`
- **font_color:** `Color(1, 0.843137, 0, 1)` ✅ **alpha = 1.0 (opaque)**
- **horizontal_alignment:** `1` (CENTER)
- **vertical_alignment:** `1` (CENTER)
- **autowrap_mode:** `3` (AUTOWRAP_WORD_SMART)
- **visible:** NOT SET (defaults to `true`)
- **modulate:** NOT SET (defaults to `Color(1,1,1,1)`)

**⚠️ CLIPPING PARENT:** Label is inside containers that eventually lead to root `RaceEntry` which has `clip_contents = true`. If text exceeds bounds, it will be clipped.

**⚠️ MISSING SIZE FLAG:** `size_flags_horizontal` is not set (defaults to 0). Should probably be `3` (SIZE_EXPAND_FILL) to fill width.

**⚠️ ZERO WIDTH:** `custom_minimum_size = Vector2(0, 24)` - width is 0, but this is okay for labels as they expand based on text content when inside VBoxContainer.

---

### 2.6 AbilityPreviewLabel (RichTextLabel)

**Type:** `RichTextLabel`  
**Path:** `MarginContainer/VBoxContainer/AbilityPreviewLabel`  
**Parent:** VBoxContainer  
**Lines:** 51-62

```51:62:scenes/character_creation/tabs/components/RaceEntry.tscn
[node name="AbilityPreviewLabel" type="RichTextLabel" parent="MarginContainer/VBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
size_flags_vertical = 0
custom_minimum_size = Vector2(0, 18)
bbcode_enabled = true
fit_content = false
scroll_active = false
theme_override_font_sizes/normal_font_size = 12
theme_override_colors/default_color = Color(0.83, 0.83, 0.83, 1)
text = ""
autowrap_mode = 3
```

**Properties:**
- ✅ **clip_contents:** NOT SET (defaults to `false`) ✅ **NO CLIPPING ON RICHTEXTLABEL**
- **layout_mode:** `2` (PRESET_MODE_MINSIZE)
- **size_flags_horizontal:** NOT SET (defaults to `0` = SIZE_SHRINK_CENTER) ⚠️ **MISSING**
- **size_flags_vertical:** `0` (SIZE_SHRINK_CENTER)
- **custom_minimum_size:** `Vector2(0, 18)` ⚠️ **Width = 0, Height = 18**
- **bbcode_enabled:** `true`
- **fit_content:** `false` ⚠️ **Content fitting is disabled**
- **scroll_active:** `false` ✅ **No scrolling**
- **font_size:** `12`
- **default_color:** `Color(0.83, 0.83, 0.83, 1)` ✅ **alpha = 1.0 (opaque)**
- **autowrap_mode:** `3` (AUTOWRAP_WORD_SMART)
- **visible:** NOT SET (defaults to `true`)
- **modulate:** NOT SET (defaults to `Color(1,1,1,1)`)

**⚠️ CLIPPING PARENT:** RichTextLabel is inside containers that eventually lead to root `RaceEntry` which has `clip_contents = true`. If text exceeds bounds, it will be clipped.

**⚠️ MISSING SIZE FLAG:** `size_flags_horizontal` is not set (defaults to 0). Should probably be `3` (SIZE_EXPAND_FILL) to fill width.

**⚠️ ZERO WIDTH:** `custom_minimum_size = Vector2(0, 18)` - width is 0, but this is okay as RichTextLabel will expand based on content when inside VBoxContainer.

**⚠️ fit_content = false:** With `fit_content = false`, RichTextLabel may not resize properly to fit text content.

---

## 3. CLIP CONTENTS ANALYSIS

### 3.1 Root PanelContainer Clipping

**RaceEntry (PanelContainer):**
- ✅ `clip_contents = true` ⚠️ **ENABLED**

**Impact:**
- Any child content (Labels, TextureRects) that extends beyond the PanelContainer's bounds will be **clipped/hidden**
- The PanelContainer has `custom_minimum_size = Vector2(0, 90)`, so height is fixed at 90 pixels
- If Icon (40px) + margins (4+4=8px) + RaceNameLabel (24px) + spacing (2px) + AbilityPreviewLabel (18px) + spacing (2px) = **94px minimum**, content will be clipped
- Width clipping is less likely as `size_flags_horizontal = 3` allows expansion

### 3.2 Container Clipping Check

**All intermediate containers:**
- MarginContainer: `clip_contents = false` ✅
- VBoxContainer: `clip_contents = false` ✅

**✅ NO ADDITIONAL CLIPPING:** Only the root PanelContainer clips contents.

---

## 4. SIZE ANALYSIS

### 4.1 Root Container Size

**RaceEntry (PanelContainer):**
- **custom_minimum_size:** `Vector2(0, 90)`
- **Height:** `90` pixels ✅ **NOT 0**
- **Width:** `0` (will expand based on parent/children) ✅ **OKAY**

### 4.2 Child Node Sizes

**Icon (TextureRect):**
- **custom_minimum_size:** `Vector2(40, 40)` ✅ **40x40 (NOT 0x0)**

**RaceNameLabel (Label):**
- **custom_minimum_size:** `Vector2(0, 24)` ⚠️ **Width = 0, Height = 24**
- Width of 0 is acceptable for labels in VBoxContainer (expands to fit text)

**AbilityPreviewLabel (RichTextLabel):**
- **custom_minimum_size:** `Vector2(0, 18)` ⚠️ **Width = 0, Height = 18**
- Width of 0 is acceptable for RichTextLabel in VBoxContainer (expands to fit content)

### 4.3 Size Calculation

**Total Minimum Height Needed:**
- MarginContainer top margin: 4px
- Icon: 40px
- VBoxContainer separation: 2px
- RaceNameLabel: 24px
- VBoxContainer separation: 2px
- AbilityPreviewLabel: 18px
- MarginContainer bottom margin: 4px
- **Total: 94px**

**PanelContainer Height:** 90px

**⚠️ HEIGHT CLIPPING:** Content requires 94px minimum, but PanelContainer only has 90px height. **4px will be clipped!**

---

## 5. VISIBILITY FLAGS

### 5.1 All Nodes Visibility

All nodes in the scene:
- ✅ **visible:** NOT SET (defaults to `true`)
- ✅ **modulate:** NOT SET (defaults to `Color(1,1,1,1)` = fully opaque)
- ✅ **self_modulate:** NOT SET (defaults to `Color(1,1,1,1)` = fully opaque)

**✅ NO VISIBILITY ISSUES:** All nodes are visible and fully opaque.

---

## 6. SUMMARY OF ISSUES

### ✅ What's Working:
1. All containers except root have `clip_contents = false` ✅
2. All nodes have proper visibility (visible = true, opaque) ✅
3. No nodes have explicit size = Vector2(0,0) ✅
4. Icon has valid minimum size (40x40) ✅

### ⚠️ Issues Found:

1. **ROOT CLIPPING ENABLED:**
   - `RaceEntry` PanelContainer has `clip_contents = true`
   - This will clip child content that exceeds bounds

2. **HEIGHT CLIPPING:**
   - Total content height needed: **94px**
   - PanelContainer height: **90px**
   - **4px of content will be clipped at bottom**

3. **MISSING SIZE FLAGS:**
   - `RaceNameLabel`: Missing `size_flags_horizontal` (defaults to 0)
   - `AbilityPreviewLabel`: Missing `size_flags_horizontal` (defaults to 0)
   - Should be set to `3` (SIZE_EXPAND_FILL) to fill width

4. **RichTextLabel fit_content:**
   - `AbilityPreviewLabel` has `fit_content = false`
   - May cause text overflow/clipping issues

---

## 7. RECOMMENDATIONS

### Fix 1: Increase PanelContainer Height

Change line 8:
```
custom_minimum_size = Vector2(0, 90)
```

To:
```
custom_minimum_size = Vector2(0, 96)
```

Or better, remove fixed height and let it calculate:
```
# Remove custom_minimum_size or increase to 96+
```

### Fix 2: Add Size Flags to Labels

Add to `RaceNameLabel` (after line 42):
```
size_flags_horizontal = 3
```

Add to `AbilityPreviewLabel` (after line 54):
```
size_flags_horizontal = 3
```

### Fix 3: Consider Disabling Clip Contents

Change line 11:
```
clip_contents = true
```

To:
```
clip_contents = false
```

Or keep clipping but ensure content fits within bounds.

---

## 8. CONCLUSION

**✅ NO Layout Presets Forcing size = Vector2(0,0):** All nodes use proper layout modes.

**⚠️ CLIP CONTENTS ENABLED:** Root PanelContainer clips child content.

**⚠️ HEIGHT CLIPPING:** Content needs 94px but container only has 90px (4px will be clipped).

**⚠️ MISSING SIZE FLAGS:** Labels missing horizontal size flags may not expand properly.

---

**Report Generated:** Complete node analysis of RaceEntry.tscn scene

