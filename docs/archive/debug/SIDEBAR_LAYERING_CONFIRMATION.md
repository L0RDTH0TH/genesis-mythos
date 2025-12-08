# SidebarBorder Layering Issue Confirmation

## Scene File Analysis: `res://scenes/character_creation/CharacterCreationRoot.tscn`

### LeftSidebar Node Children (in scene tree order):

**Parent:** `MainLayout/LeftSidebar` (Control)
- `layout_mode = 2`
- `size_flags_horizontal = 0`
- `custom_minimum_size = Vector2(300, 0)`

**Children (in order they appear in scene tree):**

1. **TabNavigation** (Control) - Line 54
   - Type: Instance of `res://scenes/character_creation/tabs/TabNavigation.tscn`
   - `layout_mode = 1`
   - `anchors_preset = 15` (FULL_RECT)
   - `anchor_right = 1.0`
   - `anchor_bottom = 1.0`
   - `grow_horizontal = 2`
   - `grow_vertical = 2`
   - **z_index:** NOT SET → **defaults to 0**
   - **z_as_relative:** NOT SET → **defaults to true**
   - **z_index_mode:** NOT SET → **defaults to Z_INDEX_MODE_AUTO**

2. **SidebarBorder** (Panel) - Line 62
   - Type: Panel
   - `layout_mode = 1`
   - `anchors_preset = 15` (FULL_RECT)
   - `anchor_right = 1.0`
   - `anchor_bottom = 1.0`
   - `grow_horizontal = 2`
   - `grow_vertical = 2`
   - `theme_override_styles/panel = SubResource("StyleBoxFlat_1")`
   - `mouse_filter = 2` (MOUSE_FILTER_IGNORE)
   - **z_index:** NOT SET → **defaults to 0**
   - **z_as_relative:** NOT SET → **defaults to true**
   - **z_index_mode:** NOT SET → **defaults to Z_INDEX_MODE_AUTO**

---

## Z-Index Confirmation

### TabNavigation:
- **z_index:** NOT SET → **defaults to 0** ✅
- **z_as_relative:** NOT SET → **defaults to true** ✅
- **z_index_mode:** NOT SET → **defaults to Z_INDEX_MODE_AUTO** ✅

### SidebarBorder:
- **z_index:** NOT SET → **defaults to 0** ✅
- **z_as_relative:** NOT SET → **defaults to true** ✅
- **z_index_mode:** NOT SET → **defaults to Z_INDEX_MODE_AUTO** ✅

**Result:** Both nodes have **z_index = 0** (default), so rendering order is determined by **scene tree position**. Since SidebarBorder comes AFTER TabNavigation in the tree, it renders ON TOP.

---

## SidebarBorder StyleBox Definition

**Full SubResource Definition (StyleBoxFlat_1):**

```7:11:scenes/character_creation/CharacterCreationRoot.tscn
[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_1"]
resource_name = "bg3_sidebar_border"
bg_color = Color(0.062745, 0.062745, 0.062745, 1)
border_width_right = 2
border_color = Color(1, 0.843137, 0, 1)
```

**Properties:**
- **Type:** StyleBoxFlat
- **Resource Name:** "bg3_sidebar_border"
- **bg_color:** `Color(0.062745, 0.062745, 0.062745, 1)` ✅ **alpha = 1.0** (fully opaque)
- **border_width_right:** `2` (2px border on right side only)
- **border_color:** `Color(1, 0.843137, 0, 1)` ✅ **alpha = 1.0** (fully opaque, gold color)

**Analysis:** The StyleBox has a **fully opaque dark background** (`bg_color.a = 1.0`) that covers the entire Panel area. This will visually cover anything behind it.

---

## Modulate/Self_Modulate Check

**SidebarBorder:**
- **modulate:** NOT SET → **defaults to `Color(1, 1, 1, 1)`** ✅ (fully opaque)
- **self_modulate:** NOT SET → **defaults to `Color(1, 1, 1, 1)`** ✅ (fully opaque)

**TabNavigation:**
- **modulate:** NOT SET → **defaults to `Color(1, 1, 1, 1)`** ✅ (fully opaque)
- **self_modulate:** NOT SET → **defaults to `Color(1, 1, 1, 1)`** ✅ (fully opaque)

**Result:** Both nodes are fully opaque. No transparency issues.

---

## Rendering Order Analysis

### Scene Tree Order (determines rendering):
1. **TabNavigation** (added first) → Renders FIRST (behind)
2. **SidebarBorder** (added second) → Renders SECOND (on top)

### Visual Result:
- **SidebarBorder** has `anchors_preset = 15` (FULL_RECT), covering entire LeftSidebar
- **SidebarBorder** has fully opaque dark background (`bg_color.a = 1.0`)
- **SidebarBorder** renders AFTER TabNavigation in tree order
- **Therefore:** SidebarBorder visually covers TabNavigation/TabContainer

### Why Mouse Still Works:
- **SidebarBorder** has `mouse_filter = 2` (MOUSE_FILTER_IGNORE)
- This means it doesn't receive mouse input, so clicks pass through to TabNavigation
- But it still **renders visually on top**, making TabNavigation invisible

---

## Expected Visual Result

When Character Creation loads, the LeftSidebar area should show:
- ✅ **A dark background** (SidebarBorder's StyleBox)
- ✅ **A gold border on the right side** (2px border from SidebarBorder)
- ❌ **NO visible tab buttons** (TabNavigation/TabContainer is behind SidebarBorder)
- ❌ **NO "1 RACE", "2 CLASS", etc. buttons visible**

The tabs are there and functional (mouse clicks work because `mouse_filter = 2`), but they're **visually hidden** behind the opaque SidebarBorder Panel.

---

## Solution

To fix this, either:

1. **Move SidebarBorder BEFORE TabNavigation in scene tree** (recommended)
2. **Set `z_index = -1` on SidebarBorder** to force it behind TabNavigation
3. **Make SidebarBorder background transparent** (set `bg_color.a = 0` in StyleBox)
4. **Remove SidebarBorder** if it's not essential

