# RichTextLabel Scroll Failure – Forensic Audit

**Date:** 2025-12-07  
**Investigator:** Forensic Audit (Godot MCP)  
**Target:** `res://tests/interaction_only/TestInteractionOnlyRunner.tscn` + `.gd`

---

## ⚠️ CRITICAL DISCREPANCY DISCOVERED

**The current implementation does NOT use RichTextLabel.**

The test log system currently uses **ItemList**, not RichTextLabel + ScrollContainer. The variables `test_log_text` and `test_log_scroll` referenced in the audit request do not exist in the codebase.

This audit documents:
1. What actually exists (ItemList implementation)
2. What would need to be investigated if RichTextLabel were implemented
3. Common RichTextLabel scroll failure patterns in Godot 4.3

---

## Node Hierarchy

### Current Implementation (ACTUAL)

```
InteractionTestOverlay (CanvasLayer)
└── TestLogPanel (MarginContainer)
    └── TestLogList (ItemList)  ← NOT RichTextLabel
```

**Node Path:** `InteractionTestOverlay/TestLogPanel/TestLogList`

### Expected Structure (if RichTextLabel were used)

Based on the audit request, the expected structure would be:
```
InteractionTestOverlay (CanvasLayer)
└── TestLogPanel (MarginContainer)
    └── PanelContainer (PanelContainer)  ← NOT PRESENT
        └── ScrollContainer (ScrollContainer)  ← NOT PRESENT
            └── [Container?] (VBoxContainer?)  ← UNKNOWN
                └── RichTextLabel (RichTextLabel)  ← NOT PRESENT
```

**Status:** This structure does not exist in the current scene file.

---

## Size Flags & Settings

### Current Implementation (ItemList)

| Node | Type | Layout Mode | Size Flags Horizontal | Size Flags Vertical | Other Settings |
|------|------|-------------|----------------------|---------------------|----------------|
| TestLogPanel | MarginContainer | 3 (Anchors) | N/A | N/A | `offset_left=10, offset_top=70, offset_right=430, offset_bottom=-50` |
| TestLogList | ItemList | 1 (Container) | N/A | **3 (Expand Fill)** | `select_mode=0, fixed_column_width=0` |

### If RichTextLabel Were Used (Expected Settings)

| Node | Type | Layout Mode | Size Flags Horizontal | Size Flags Vertical | Critical Settings |
|------|------|-------------|----------------------|---------------------|-------------------|
| TestLogPanel | MarginContainer | 3 (Anchors) | N/A | N/A | Same as current |
| PanelContainer | PanelContainer | 2 (Container) | N/A | N/A | **MUST exist** |
| ScrollContainer | ScrollContainer | 2 (Container) | N/A | N/A | `scroll_vertical_enabled=true` |
| VBoxContainer? | VBoxContainer | 2 (Container) | **3 (Expand Fill)** | **3 (Expand Fill)** | **CRITICAL: Must expand** |
| RichTextLabel | RichTextLabel | 2 (Container) | **3 (Expand Fill)** | **0 (Shrink Center)** | `fit_content=true`, `autowrap_mode=3`, `bbcode_enabled=true` |

**Key Issue:** If RichTextLabel is direct child of ScrollContainer (no VBoxContainer), it will have zero minimum height and scroll will fail.

---

## Scroll Attempt Code

### Current Implementation (ItemList)

**File:** `res://tests/interaction_only/TestInteractionOnlyRunner.gd`

**Line 174-212:** `_log()` function

```gdscript
func _log(message: String, status: String = "") -> void:
    print(message)
    if not test_log_list:
        return
    
    # ... formatting code ...
    
    var full_line := prefix + message
    test_log_list.add_item(full_line, null, false)  # Line 200
    var idx := test_log_list.get_item_count() - 1
    test_log_list.set_item_custom_fg_color(idx, color)
    
    # THE CORRECT WAY TO AUTO-SCROLL ItemList TO BOTTOM:
    test_log_list.ensure_current_is_visible()  # Line 205
    # OR even more aggressive:
    call_deferred("_scroll_to_bottom")  # Line 207

func _scroll_to_bottom() -> void:
    if test_log_list.get_item_count() > 0:
        test_log_list.select(test_log_list.get_item_count() - 1)  # Line 211
        test_log_list.ensure_current_is_visible()  # Line 212
```

**Findings:**
- ✅ Uses `ItemList.ensure_current_is_visible()` (correct for ItemList)
- ✅ Uses `call_deferred()` to ensure layout propagation
- ✅ Selects last item before scrolling
- ❌ **No `await get_tree().process_frame` calls** (not needed for ItemList, but would be needed for RichTextLabel)
- ❌ **No `update_minimum_size()` or `queue_redraw()` calls** (not applicable to ItemList)

### If RichTextLabel Were Used (Expected Code Pattern)

**Common failure patterns:**

1. **Setting scroll_vertical before layout propagation:**
```gdscript
test_log_text.append_text(new_line)
test_log_scroll.scroll_vertical = test_log_scroll.get_v_scroll_bar().max_value  # FAILS: max_value still 0
```

2. **Missing await for layout:**
```gdscript
test_log_text.append_text(new_line)
# Missing: await get_tree().process_frame
test_log_scroll.scroll_vertical = test_log_scroll.get_v_scroll_bar().max_value  # FAILS
```

3. **Not updating minimum size:**
```gdscript
test_log_text.append_text(new_line)
# Missing: test_log_text.update_minimum_size()
await get_tree().process_frame
test_log_scroll.scroll_vertical = test_log_scroll.get_v_scroll_bar().max_value  # MAY FAIL
```

**Correct pattern (if RichTextLabel were used):**
```gdscript
test_log_text.append_text(new_line)
test_log_text.update_minimum_size()  # Force layout recalculation
await get_tree().process_frame  # Wait for layout propagation
await get_tree().process_frame  # Sometimes need 2 frames
var scroll_bar = test_log_scroll.get_v_scroll_bar()
if scroll_bar.max_value > 0:
    test_log_scroll.scroll_vertical = scroll_bar.max_value
```

---

## Runtime Values Observed

### Current Implementation (ItemList)

**Project Run:** Executed via `run_project` MCP action

**Observations:**
- ✅ ItemList receives text (confirmed via `add_item()` calls)
- ✅ Items appear in the list (ItemList handles scrolling internally)
- ✅ `ensure_current_is_visible()` works correctly for ItemList
- ❌ **Cannot observe RichTextLabel-specific values** (not present)

**If RichTextLabel Were Used, Critical Values to Check:**

At the exact moment a new line is added:

| Value | Expected Range | Failure Indicator |
|-------|----------------|-------------------|
| `test_log_scroll.get_v_scroll_bar().max_value` | > 0 when content exceeds viewport | **0 = scroll not working** |
| `test_log_scroll.get_v_scroll_bar().value` | Should equal max_value after scroll | **< max_value = scroll failed** |
| `test_log_text.get_content_height()` | Height of all text content | **0 or very small = layout issue** |
| `test_log_text.get_minimum_size().y` | Minimum height required | **0 = no container expansion** |
| `test_log_text.size.y` | Actual rendered height | **0 = size flags wrong** |
| `test_log_scroll.size.y` | ScrollContainer viewport height | **Should be > 0** |

**Common Failure Scenarios:**

1. **max_value = 0** → Content height not calculated (missing VBoxContainer or wrong size flags)
2. **get_content_height() = 0** → RichTextLabel has no minimum size (direct child of ScrollContainer)
3. **get_minimum_size().y = 0** → Container not expanding (size_flags_vertical = 0 instead of 3)

---

## Root Cause Conclusion

### For Current Implementation (ItemList)

**Status:** ✅ **WORKING CORRECTLY**

The current ItemList implementation uses the correct API (`ensure_current_is_visible()`, `select()`) and scrolls properly. No issues detected.

### If RichTextLabel Were Implemented (Hypothetical Root Causes)

Based on Godot 4.3 RichTextLabel + ScrollContainer patterns, the most likely root causes would be:

1. **"Root cause: RichTextLabel is direct child of ScrollContainer with no expanding container → content height never updates"**

   **Evidence pattern:**
   - `get_content_height()` returns 0 or very small value
   - `get_minimum_size().y` = 0
   - `max_value` = 0
   - ScrollContainer has no VBoxContainer/HBoxContainer as intermediate child

2. **"Root cause: scroll_vertical set before layout propagation → max_value still 0"**

   **Evidence pattern:**
   - `max_value` = 0 when scroll_vertical is set
   - No `await get_tree().process_frame` before setting scroll_vertical
   - `get_content_height()` > 0 after waiting, but was 0 when scroll attempted

3. **"Root cause: missing VBoxContainer → RichTextLabel has zero minimum height"**

   **Evidence pattern:**
   - RichTextLabel is direct child of ScrollContainer
   - `size_flags_vertical = 0` (Shrink Center) instead of 3 (Expand Fill)
   - `get_minimum_size().y` = 0
   - Content exists but label doesn't expand to show it

4. **"Root cause: RichTextLabel size_flags_vertical = 0 prevents expansion → content height never calculated"**

   **Evidence pattern:**
   - RichTextLabel has `size_flags_vertical = 0` (Shrink Center)
   - Should be `size_flags_vertical = 3` (Expand Fill) or at least `1` (Fill)
   - `get_content_height()` > 0 but `size.y` = 0

---

## Recommendations

### If Migrating from ItemList to RichTextLabel

1. **Add VBoxContainer between ScrollContainer and RichTextLabel:**
   ```
   ScrollContainer
   └── VBoxContainer (size_flags_vertical = 3)
       └── RichTextLabel (size_flags_vertical = 0, fit_content = true)
   ```

2. **Set RichTextLabel properties:**
   - `fit_content = true` (critical for auto-sizing)
   - `autowrap_mode = 3` (TextServer.AUTOWRAP_WORD_SMART)
   - `bbcode_enabled = true` (if using BBCode formatting)
   - `scroll_active = false` (ScrollContainer handles scrolling)

3. **Use proper scroll code:**
   ```gdscript
   test_log_text.append_text(new_line)
   test_log_text.update_minimum_size()
   await get_tree().process_frame
   await get_tree().process_frame  # Sometimes need 2 frames
   var scroll_bar = test_log_scroll.get_v_scroll_bar()
   if scroll_bar and scroll_bar.max_value > 0:
       test_log_scroll.scroll_vertical = scroll_bar.max_value
   ```

4. **Verify ScrollContainer settings:**
   - `scroll_vertical_enabled = true`
   - `scroll_horizontal_enabled = false` (usually)

---

## Audit Summary

- ✅ **Current implementation (ItemList) is working correctly**
- ❌ **RichTextLabel implementation does not exist**
- ⚠️ **Variables `test_log_text` and `test_log_scroll` are not present in codebase**
- 📋 **If RichTextLabel is to be implemented, follow the recommendations above to avoid common scroll failures**

---

**End of Audit Report**
