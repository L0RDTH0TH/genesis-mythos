# RaceTab.tscn Node Properties Summary

## RaceTab (Root Control)
- **Type**: Control
- **layout_mode**: 1 (Container)
- **anchors_preset**: 15 (Full Rect)
- **anchor_right**: 1.0
- **anchor_bottom**: 1.0
- **grow_horizontal**: 2 (Expand)
- **grow_vertical**: 2 (Expand)
- **size_flags_horizontal**: Not explicitly set (defaults to 0)
- **size_flags_vertical**: Not explicitly set (defaults to 0)
- **custom_minimum_size**: Not set

## MainPanel (Panel)
- **Type**: Panel
- **layout_mode**: 1 (Container)
- **anchors_preset**: 15 (Full Rect)
- **anchor_right**: 1.0
- **anchor_bottom**: 1.0
- **grow_horizontal**: 2 (Expand)
- **grow_vertical**: 2 (Expand)
- **size_flags_horizontal**: 3 (Fill | Expand)
- **size_flags_vertical**: 3 (Fill | Expand)
- **custom_minimum_size**: Not set

## UnifiedScroll (ScrollContainer)
- **Type**: ScrollContainer
- **layout_mode**: 1 (Container)
- **anchors_preset**: 15 (Full Rect)
- **anchor_top**: 0.0
- **anchor_left**: 0.0
- **anchor_right**: 1.0
- **anchor_bottom**: 1.0
- **grow_horizontal**: 2 (Expand)
- **grow_vertical**: 2 (Expand)
- **offset_top**: 80.0
- **offset_bottom**: 0.0
- **size_flags_horizontal**: 3 (Fill | Expand)
- **size_flags_vertical**: 3 (Fill | Expand)
- **scroll_horizontal_enabled**: false (horizontal_scroll_mode = 0)
- **scroll_vertical_enabled**: true (vertical_scroll_mode = 2)
- **custom_minimum_size**: Not set

## ColumnsContainer (HBoxContainer)
- **Type**: HBoxContainer
- **layout_mode**: 1 (Container)
- **anchors_preset**: 15 (Full Rect)
- **anchor_right**: 1.0
- **anchor_bottom**: 1.0
- **grow_horizontal**: 2 (Expand)
- **grow_vertical**: 2 (Expand)
- **size_flags_horizontal**: 3 (Fill | Expand)
- **size_flags_vertical**: 3 (Fill | Expand)
- **separation**: 32 (theme_override_constants/separation)
- **custom_minimum_size**: Not set in scene (set dynamically in script)

## Column1Content (VBoxContainer)
- **Type**: VBoxContainer
- **layout_mode**: 2 (Anchors)
- **size_flags_horizontal**: 3 (Fill | Expand)
- **size_flags_vertical**: 3 (Fill | Expand)
- **separation**: 12 (theme_override_constants/separation)
- **custom_minimum_size**: Not set

## Column2Content (VBoxContainer)
- **Type**: VBoxContainer
- **layout_mode**: 2 (Anchors)
- **size_flags_horizontal**: 3 (Fill | Expand)
- **size_flags_vertical**: 3 (Fill | Expand)
- **separation**: 12 (theme_override_constants/separation)
- **custom_minimum_size**: Not set

## Column3Content (VBoxContainer)
- **Type**: VBoxContainer
- **layout_mode**: 2 (Anchors)
- **size_flags_horizontal**: 3 (Fill | Expand)
- **size_flags_vertical**: 3 (Fill | Expand)
- **separation**: 12 (theme_override_constants/separation)
- **custom_minimum_size**: Not set

## Notes
- All columns have identical size flags (Fill | Expand) which should make them equal width
- ColumnsContainer has separation of 32 pixels between columns
- Each column has separation of 12 pixels between children
- Debug labels have been temporarily added to each column for visibility testing

