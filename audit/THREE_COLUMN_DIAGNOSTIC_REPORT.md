# THREE-COLUMN LAYOUT DIAGNOSTIC REPORT
## RaceTab.tscn - Column Visibility Issue

---

## 1. NODE HIERARCHY (from root Control)

```
RaceTab (Control)
└── VBoxContainer (VBoxContainer) [CONTAINER]
    ├── TitleLabel (Label)
    └── UnifiedScroll (ScrollContainer) [CONTAINER]
        └── ColumnsContainer (HBoxContainer) [CONTAINER]
            ├── Column1Content (VBoxContainer) [CONTAINER]
            ├── Column2Content (VBoxContainer) [CONTAINER]
            └── Column3Content (VBoxContainer) [CONTAINER]
```

---

## 2. CONTAINER PROPERTIES (from .tscn file)

### RaceTab (Control - root)
- **Layout Mode**: 3 (Anchors)
- **Anchors Preset**: 15 (Full Rect)
- **Anchor Right**: 1.0
- **Anchor Bottom**: 1.0
- **Grow Horizontal**: 2 (Expand)
- **Grow Vertical**: 2 (Expand)

### VBoxContainer (parent of UnifiedScroll)
- **Layout Mode**: 2 (Container)
- **Size Flags Horizontal**: 3 (SIZE_EXPAND_FILL = 1 | SIZE_EXPAND = 2)
  - Fill: ✅ YES
  - Expand: ✅ YES
- **Size Flags Vertical**: 3 (SIZE_EXPAND_FILL = 1 | SIZE_EXPAND = 2)
  - Fill: ✅ YES
  - Expand: ✅ YES
- **Custom Minimum Size**: (not set, defaults to Vector2(0, 0))
- **Anchors**: N/A (Container mode)
- **Visible**: ✅ YES (default)
- **Separation**: 32

### UnifiedScroll (ScrollContainer)
- **Layout Mode**: 2 (Container)
- **Size Flags Horizontal**: 3 (SIZE_EXPAND_FILL)
  - Fill: ✅ YES
  - Expand: ✅ YES
- **Size Flags Vertical**: 3 (SIZE_EXPAND_FILL)
  - Fill: ✅ YES
  - Expand: ✅ YES
- **Custom Minimum Size**: Vector2(0, 0) ⚠️ **ZERO SIZE**
- **Anchors**: N/A (Container mode)
- **Visible**: ✅ YES (default)
- **Horizontal Scroll Mode**: 0 (Disabled)
- **Vertical Scroll Mode**: 2 (Enabled)

### ColumnsContainer (HBoxContainer) - **THE PROBLEM LIKELY HERE**
- **Layout Mode**: 2 (Container) ⚠️ **WRONG FOR SCROLLCONTAINER CHILD**
- **Size Flags Horizontal**: 3 (SIZE_EXPAND_FILL)
  - Fill: ✅ YES
  - Expand: ✅ YES
- **Size Flags Vertical**: 3 (SIZE_EXPAND_FILL)
  - Fill: ✅ YES
  - Expand: ✅ YES
- **Custom Minimum Size**: (not set, defaults to Vector2(0, 0))
- **Anchors**: N/A (Container mode)
- **Visible**: ✅ YES (default)
- **Separation**: 32

### Column1Content, Column2Content, Column3Content (VBoxContainer)
- **Layout Mode**: 2 (Container)
- **Size Flags Horizontal**: 3 (SIZE_EXPAND_FILL)
  - Fill: ✅ YES
  - Expand: ✅ YES
- **Size Flags Vertical**: 3 (SIZE_EXPAND_FILL)
  - Fill: ✅ YES
  - Expand: ✅ YES
- **Custom Minimum Size**: (not set)
- **Anchors**: N/A (Container mode)
- **Visible**: ✅ YES (default)
- **Separation**: 12

---

## 3. LAYOUT PRESETS

- **RaceTab**: Full Rect (anchors_preset = 15)
- **VBoxContainer**: Container mode (no preset)
- **UnifiedScroll**: Container mode (no preset)
- **ColumnsContainer**: Container mode (no preset)
- **Column1Content, Column2Content, Column3Content**: Container mode (no preset)

---

## 4. .tscn CONTENT FOR COLUMNS

```tscn
[node name="ColumnsContainer" type="HBoxContainer" parent="VBoxContainer/UnifiedScroll"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 32

[node name="Column1Content" type="VBoxContainer" parent="VBoxContainer/UnifiedScroll/ColumnsContainer"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 12

[node name="Column2Content" type="VBoxContainer" parent="VBoxContainer/UnifiedScroll/ColumnsContainer"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 12

[node name="Column3Content" type="VBoxContainer" parent="VBoxContainer/UnifiedScroll/ColumnsContainer"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 12
```

---

## 5. SCRIPT ANALYSIS

### Code that modifies sizes:
- **Line 40-42 in RaceTab.gd**: Sets `unified_scroll_node.custom_minimum_size.y = 0` (only if > 0)
- **Line 141-142 in RaceTab.gd**: Sets `content.size_flags_horizontal = Control.SIZE_EXPAND_FILL` (runtime)
- **No code found that sets**: `size = Vector2.ZERO`, `visible = false`, `modulate = Color(1,1,1,0)`, `size_flags_horizontal = 0`

### Search Results:
- ✅ No problematic assignments found in scripts
- Only `modulate` usage found in AbilityScoreTab and AbilityRow (unrelated)

---

## 🔴 **ROOT CAUSE IDENTIFIED**

### **THE PROBLEM: ScrollContainer + Container Mode Child**

In **Godot 4.3**, `ScrollContainer` requires its **direct child** to use **Anchor mode (layout_mode = 1)** with anchors set to fill the container, NOT Container mode (layout_mode = 2).

**Current Setup (BROKEN):**
- `ColumnsContainer` (HBoxContainer) has `layout_mode = 2` (Container mode)
- This causes the ScrollContainer to not properly calculate the child's size
- Result: Zero width columns

**Required Fix:**
- `ColumnsContainer` must use `layout_mode = 1` (Anchor mode)
- Set anchors to `preset = 15` (Full Rect) or manually: `anchor_right = 1.0, anchor_bottom = 1.0`
- Keep `size_flags_horizontal = 3` and `size_flags_vertical = 3` for the columns inside

---

## ✅ **QUICK FIX TEST**

In the Godot editor:
1. Select `ColumnsContainer` (HBoxContainer inside UnifiedScroll)
2. In Inspector → Layout → Change `Layout Mode` from "Container" to "Anchors"
3. Set `Anchors Preset` to "Full Rect" (preset 15)
4. Verify `Grow Horizontal` and `Grow Vertical` are both set to "Expand"
5. Run the project - columns should now appear

---

## 📋 **RECOMMENDED FIX**

Modify `RaceTab.tscn`:

```tscn
[node name="ColumnsContainer" type="HBoxContainer" parent="VBoxContainer/UnifiedScroll"]
unique_name_in_owner = true
layout_mode = 1                    # ← CHANGE FROM 2 TO 1
anchors_preset = 15                 # ← ADD THIS (Full Rect)
anchor_right = 1.0                 # ← ADD THIS
anchor_bottom = 1.0                # ← ADD THIS
grow_horizontal = 2                # ← ADD THIS (Expand)
grow_vertical = 2                  # ← ADD THIS (Expand)
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 32
```

The three column VBoxContainers can remain in Container mode (layout_mode = 2) as they are children of an HBoxContainer, not a ScrollContainer.

---

## 🧪 **RUNTIME DIAGNOSTIC SCRIPT**

Add this to RaceTab.gd `_ready()` function to print actual runtime sizes:

```gdscript
func _print_diagnostic() -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    
    print("=== RUNTIME DIAGNOSTIC ===")
    if unified_scroll:
        print("UnifiedScroll size: ", unified_scroll.size)
        print("UnifiedScroll min_size: ", unified_scroll.custom_minimum_size)
        print("UnifiedScroll visible: ", unified_scroll.visible)
    
    if columns_container:
        print("ColumnsContainer size: ", columns_container.size)
        print("ColumnsContainer min_size: ", columns_container.custom_minimum_size)
        print("ColumnsContainer layout_mode: ", columns_container.layout_mode)
        print("ColumnsContainer visible: ", columns_container.visible)
    
    for i in range(3):
        var col := [column1_content, column2_content, column3_content][i]
        if col:
            print("Column%d size: %s, min_size: %s, visible: %s" % [i+1, col.size, col.custom_minimum_size, col.visible])
```

