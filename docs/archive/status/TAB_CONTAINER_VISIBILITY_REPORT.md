# TabContainer Visibility & Properties Report

## Node Path
**Full Path:** `CharacterCreationRoot/MainLayout/LeftSidebar/TabNavigation/TabContainer`  
**Node Type:** `VBoxContainer` (NOT Godot's TabContainer class - it's a custom VBoxContainer with Button children)  
**Scene File:** `res://scenes/character_creation/tabs/TabNavigation.tscn` (lines 56-67)

---

## 1. TabContainer Node Properties

### Current Values (from TabNavigation.tscn):

**visible:** NOT SET (defaults to `true`)  
**process_mode:** NOT SET (defaults to `PROCESS_MODE_INHERIT`)  
**modulate:** NOT SET (defaults to `Color(1, 1, 1, 1)` - fully opaque)  
**self_modulate:** NOT SET (defaults to `Color(1, 1, 1, 1)` - fully opaque)  
**size/rect_size:** NOT SET (calculated from anchors and offsets)  
**offset_left:** `80.0`  
**offset_top:** `120.0`  
**offset_right:** `-80.0`  
**offset_bottom:** `-120.0`  
**anchors_preset:** `15` (FULL_RECT - anchors to all corners)  
**layout_mode:** `1` (CONTAINER - uses anchors)

### Theme Overrides:
- `theme_override_constants/separation = 12` (spacing between VBoxContainer children)

**No opacity-related theme overrides found.**

---

## 2. Parent Node Hierarchy & Visibility

### Full Parent Chain:
1. **CharacterCreationRoot** (Control) - Root node
   - `visible`: NOT SET (defaults to `true`)
   - `process_mode`: NOT SET (defaults to `PROCESS_MODE_INHERIT`)
   - `modulate`: NOT SET (defaults to `Color(1, 1, 1, 1)`)
   - `self_modulate`: NOT SET (defaults to `Color(1, 1, 1, 1)`)

2. **MainLayout** (HBoxContainer)
   - `visible`: NOT SET (defaults to `true`)
   - `process_mode`: NOT SET (defaults to `PROCESS_MODE_INHERIT`)
   - `modulate`: NOT SET (defaults to `Color(1, 1, 1, 1)`)
   - `self_modulate`: NOT SET (defaults to `Color(1, 1, 1, 1)`)

3. **LeftSidebar** (Control)
   - `visible`: NOT SET (defaults to `true`)
   - `process_mode`: NOT SET (defaults to `PROCESS_MODE_INHERIT`)
   - `modulate`: NOT SET (defaults to `Color(1, 1, 1, 1)`)
   - `self_modulate`: NOT SET (defaults to `Color(1, 1, 1, 1)`)
   - `custom_minimum_size`: `Vector2(300, 0)` - **300px wide minimum**

4. **TabNavigation** (Control) - Instance from `TabNavigation.tscn`
   - `visible`: NOT SET (defaults to `true`)
   - `process_mode`: NOT SET (defaults to `PROCESS_MODE_INHERIT`)
   - `modulate`: NOT SET (defaults to `Color(1, 1, 1, 1)`)
   - `self_modulate`: NOT SET (defaults to `Color(1, 1, 1, 1)`)
   - `anchors_preset`: `15` (FULL_RECT)
   - `layout_mode`: `1` (CONTAINER)

5. **TabContainer** (VBoxContainer) - THE NODE IN QUESTION
   - Properties listed above

---

## 3. Potential Visibility Issues

### ⚠️ CRITICAL FINDING: SidebarBorder Panel

**Node:** `MainLayout/LeftSidebar/SidebarBorder` (Panel)  
**Position in Scene Tree:** Added AFTER TabNavigation (line 62-70 of CharacterCreationRoot.tscn)

**Properties:**
- `anchors_preset`: `15` (FULL_RECT - covers entire LeftSidebar)
- `mouse_filter`: `2` (MOUSE_FILTER_IGNORE - doesn't block mouse input)
- `theme_override_styles/panel`: StyleBoxFlat with dark background

**Potential Issue:** This Panel is rendered AFTER TabNavigation in the scene tree, which means it may be visually covering the TabNavigation/TabContainer. However, since `mouse_filter = 2`, it shouldn't block mouse clicks.

**Z-Index:** No explicit z-index settings found. In Godot, nodes are rendered in tree order (children rendered after siblings added later).

---

## 4. Code-Based Visibility Changes

**No code found that sets:**
- `visible = false` on TabContainer or any parent
- `hide()` calls on TabContainer or parents
- `modulate` or `self_modulate` with alpha < 1.0
- `opacity` property changes

**Scripts checked:**
- `CharacterCreationRoot.gd` - No visibility changes
- `TabNavigation.gd` - No visibility changes
- All tab scripts - No visibility changes to TabContainer

---

## 5. Theme-Based Opacity Issues

**Checked:** `res://themes/bg3_theme.tres`  
**Result:** No opacity-related theme overrides found. All StyleBox colors have alpha = 1.0 (fully opaque).

---

## 6. Summary

### ✅ All Properties Are Default (Visible)
- `visible`: `true` (default)
- `process_mode`: `PROCESS_MODE_INHERIT` (default)
- `modulate`: `Color(1, 1, 1, 1)` (default - fully opaque)
- `self_modulate`: `Color(1, 1, 1, 1)` (default - fully opaque)
- No parent nodes have `visible = false`
- No theme overrides affecting opacity

### ⚠️ Potential Issue: SidebarBorder Panel
The `SidebarBorder` Panel node may be visually covering the TabContainer, but it shouldn't block interaction due to `mouse_filter = 2`.

### 🔍 Recommended Next Steps
1. Check if TabContainer is actually being rendered (use Godot's Remote Inspector)
2. Verify z-index/rendering order - consider moving SidebarBorder BEFORE TabNavigation in scene tree
3. Check if TabContainer's calculated size is 0x0 (anchors might be collapsing it)
4. Verify TabContainer's buttons are actually visible (they might be there but styled to be invisible)

