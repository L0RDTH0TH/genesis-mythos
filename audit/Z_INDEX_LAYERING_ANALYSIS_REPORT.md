# Z-Index & Layering Analysis Report

## 1. Z-Index of TabContainer and All Parents

### TabContainer Node Path:
`CharacterCreationRoot/MainLayout/LeftSidebar/TabNavigation/TabContainer`

### Z-Index Values (All Default = 0):

**1. CharacterCreationRoot** (Control)
- `z_index`: NOT SET → **defaults to 0**
- `z_as_relative`: NOT SET → **defaults to true**
- `z_index_mode`: NOT SET → **defaults to Z_INDEX_MODE_AUTO**

**2. MainLayout** (HBoxContainer)
- `z_index`: NOT SET → **defaults to 0**
- `z_as_relative`: NOT SET → **defaults to true**
- `z_index_mode`: NOT SET → **defaults to Z_INDEX_MODE_AUTO**

**3. LeftSidebar** (Control)
- `z_index`: NOT SET → **defaults to 0**
- `z_as_relative`: NOT SET → **defaults to true**
- `z_index_mode`: NOT SET → **defaults to Z_INDEX_MODE_AUTO**

**4. TabNavigation** (Control) - Instance
- `z_index`: NOT SET → **defaults to 0**
- `z_as_relative`: NOT SET → **defaults to true**
- `z_index_mode`: NOT SET → **defaults to Z_INDEX_MODE_AUTO**

**5. TabContainer** (VBoxContainer)
- `z_index`: NOT SET → **defaults to 0**
- `z_as_relative`: NOT SET → **defaults to true**
- `z_index_mode`: NOT SET → **defaults to Z_INDEX_MODE_AUTO**

**Result:** All nodes use default z_index = 0, so rendering order is determined by **scene tree order** (children render in the order they appear in the tree).

---

## 2. Full-Screen Overlays Check

### ColorRect Background (NOT an overlay)

**Node:** `CharacterCreationRoot/ColorRect`
**Type:** `ColorRect`
**Position:** First child of CharacterCreationRoot (line 28-36)

**Properties:**
- `anchors_preset = 15` (FULL_RECT - covers entire screen)
- `color = Color(0.0588235, 0.0588235, 0.0588235, 1)` ✅ alpha = 1.0 (fully opaque)
- **Position in tree:** BEFORE MainLayout

**Analysis:** This is a **background**, not an overlay. It renders first (before MainLayout), so it's behind everything else. ✅ **NOT covering tabs.**

### No Other Full-Screen Overlays Found

**Checked for:**
- ❌ No additional ColorRect overlays
- ❌ No full-screen Control nodes with high z_index
- ❌ No fade/loading screens
- ❌ No black overlays
- ❌ No CanvasLayer with higher layer

**Result:** ✅ **NO full-screen overlays found that would cover the tabs.**

---

## 3. Siblings of TabContainer (Ordered by Tree Position)

### TabContainer's Parent: TabNavigation

**TabContainer's siblings within TabNavigation:**

**TabNavigation children (in order):**
1. **TabContainer** (VBoxContainer) - Line 56
   - `z_index`: NOT SET (defaults to 0)
   - **Position:** First child of TabNavigation
   - **Contains:** 6 Button children (RaceButton, ClassButton, etc.)

2. **No other siblings** - TabContainer is the only direct child of TabNavigation

---

### TabNavigation's Siblings (within LeftSidebar)

**LeftSidebar children (in order):**

1. **TabNavigation** (Control) - Line 54
   - `z_index`: NOT SET (defaults to 0)
   - **Position:** First child of LeftSidebar
   - **Contains:** TabContainer (VBoxContainer)

2. **SidebarBorder** (Panel) - Line 62
   - `z_index`: NOT SET (defaults to 0)
   - **Position:** Second child of LeftSidebar (AFTER TabNavigation)
   - **Properties:**
     - `anchors_preset = 15` (FULL_RECT - covers entire LeftSidebar)
     - `mouse_filter = 2` (MOUSE_FILTER_IGNORE - doesn't block mouse input)
     - `theme_override_styles/panel`: Dark background StyleBox
   - **⚠️ CRITICAL:** This Panel is rendered AFTER TabNavigation in the scene tree!

---

### LeftSidebar's Siblings (within MainLayout)

**MainLayout children (in order):**

1. **LeftSidebar** (Control) - Line 49
   - `z_index`: NOT SET (defaults to 0)
   - **Contains:** TabNavigation and SidebarBorder

2. **MiddleOptions** (ScrollContainer) - Line 72
   - `z_index`: NOT SET (defaults to 0)
   - **Position:** Second child of MainLayout

3. **RightPreview** (PanelContainer) - Line 96
   - `z_index`: NOT SET (defaults to 0)
   - **Position:** Third child of MainLayout

---

### MainLayout's Siblings (within CharacterCreationRoot)

**CharacterCreationRoot children (in order):**

1. **ColorRect** (ColorRect) - Line 28
   - `z_index`: NOT SET (defaults to 0)
   - **Purpose:** Background (renders first, behind everything)

2. **MainLayout** (HBoxContainer) - Line 38
   - `z_index`: NOT SET (defaults to 0)
   - **Contains:** LeftSidebar (with TabNavigation), MiddleOptions, RightPreview

---

## 4. ⚠️ CRITICAL LAYERING ISSUE FOUND

### SidebarBorder Panel is Covering TabNavigation

**Problem:**
- **TabNavigation** is added FIRST (line 54)
- **SidebarBorder** is added SECOND (line 62)
- In Godot, nodes render in **tree order** (later siblings render on top)
- Since **SidebarBorder comes after TabNavigation**, it renders **on top** of TabNavigation
- SidebarBorder has `anchors_preset = 15` (FULL_RECT), so it covers the **entire LeftSidebar area**
- This means SidebarBorder is **visually covering TabNavigation/TabContainer**

**Evidence:**
```62:70:scenes/character_creation/CharacterCreationRoot.tscn
[node name="SidebarBorder" type="Panel" parent="MainLayout/LeftSidebar"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_1")
mouse_filter = 2
```

**Why it might not block interaction:**
- `mouse_filter = 2` (MOUSE_FILTER_IGNORE) means it doesn't receive mouse input
- But it still **renders visually on top**, covering TabNavigation

---

## 5. Solution

### Option 1: Move SidebarBorder BEFORE TabNavigation (Recommended)

In `CharacterCreationRoot.tscn`, move the SidebarBorder node definition to appear BEFORE TabNavigation in the scene tree. This will make it render behind TabNavigation.

### Option 2: Set z_index Explicitly

Set `z_index = -1` on SidebarBorder to force it to render behind TabNavigation.

### Option 3: Make SidebarBorder Transparent/Invisible

If SidebarBorder is only for visual decoration, consider making it transparent or removing it entirely.

---

## 6. Summary

### Z-Index Values:
- ✅ All nodes use default z_index = 0
- ✅ No z_index conflicts found
- ⚠️ Rendering order determined by scene tree position

### Full-Screen Overlays:
- ✅ No full-screen overlays found
- ✅ ColorRect is a background (renders first, behind everything)

### Siblings:
- ⚠️ **CRITICAL:** SidebarBorder Panel is rendered AFTER TabNavigation
- ⚠️ SidebarBorder covers entire LeftSidebar area (FULL_RECT)
- ⚠️ SidebarBorder is visually covering TabNavigation/TabContainer

### Root Cause:
**The SidebarBorder Panel is visually covering the TabNavigation/TabContainer because it's added later in the scene tree and has FULL_RECT anchors covering the entire LeftSidebar area.**

