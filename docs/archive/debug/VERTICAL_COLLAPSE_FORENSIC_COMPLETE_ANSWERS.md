# VERTICAL COLLAPSE FORENSIC - COMPLETE ANSWERS TO ALL 8 QUESTIONS

## RUNTIME DATA CAPTURED VIA MCP TOOLS

All answers below are from live runtime inspection while the game was running.

---

### 1. FULL NODE HIERARCHY FROM RaceTab ROOT DOWN TO RaceGrid

**Scene:** `res://scenes/character_creation/tabs/RaceTab.tscn`

**Hierarchy:**
```
RaceTab (Control)
└→ MainPanel (Panel)
    ├→ TitleMargin (MarginContainer)
    │   └→ TitleLabel (Label)
    └→ UnifiedScroll (ScrollContainer) ← THIS IS THE SCROLLCONTAINER
        └→ RaceGrid (GridContainer)
```

---

### 2. EXACT LAYOUT SETUP OF RaceTab (THE ROOT CONTROL OF THIS TAB)

**RaceTab (Control) properties:**
- `anchors_preset: 15` (Full Rect)
- `size_flags_horizontal: 3` (SIZE_EXPAND_FILL) ✅
- `size_flags_vertical: 3` (SIZE_EXPAND_FILL) ✅
- `layout_mode: 1` (Anchors mode)

**Parent of RaceTab:**
- **Parent node:** `CurrentTabContainer` (Control)
- **Parent size_flags_horizontal:** `3` (SIZE_EXPAND_FILL) ✅
- **Parent size_flags_vertical:** `3` (SIZE_EXPAND_FILL) ✅
- **Parent runtime size:** `(1235, 0)` 🔴 **HEIGHT = 0!**

**Analysis:** RaceTab itself is correctly configured, but its parent `CurrentTabContainer` has **height = 0**, which causes the collapse.

---

### 3. UnifiedScroll (ScrollContainer) PROPERTIES

**Live runtime values:**
- `size_flags_horizontal: 3` (SIZE_EXPAND_FILL) ✅
- `size_flags_vertical: 3` (SIZE_EXPAND_FILL) ✅
- `anchors_preset: 15` (Full Rect)
- `custom_minimum_size: (0, 0)`
- `layout_mode: 1` (Anchors mode)
- `horizontal_scroll_mode: 0` (Disabled)
- `vertical_scroll_mode: 2` (Auto)
- `follow_focus: false`
- **Runtime size:** `(1235, 0)` 🔴 **HEIGHT = 0!**

**Anchor values (layout_mode = 1 - Anchors mode):**
- `anchor_left: 0.000000`
- `anchor_top: 0.000000`
- `anchor_right: 1.000000`
- `anchor_bottom: 1.000000`
- `offset_left: 0.000000`
- `offset_top: 80.000000` ⚠️ **KEY FINDING**
- `offset_right: 0.000000`
- `offset_bottom: 0.000000`

**🚨 CRITICAL ANALYSIS:**
UnifiedScroll uses **anchors mode** with:
- `offset_top = 80` (starts 80px from top)
- `offset_bottom = 0` (ends at parent bottom)

**This means:** `height = parent_height - 80`

**Since parent (MainPanel) has height = 0:**
- `UnifiedScroll height = 0 - 80 = 0` 🔴

---

### 4. THE NODE THAT IS THE SCROLLABLE CHILD OF UnifiedScroll

**Child node:**
- **Name:** `RaceGrid`
- **Type:** `GridContainer`
- **size_flags_vertical:** `3` (SIZE_EXPAND_FILL) ✅
- **custom_minimum_size.y:** `0.000000`

**Analysis:** RaceGrid is properly configured with SIZE_EXPAND_FILL, but it can't expand because its parent UnifiedScroll has height 0.

---

### 5. PARENT OF RaceTab ITSELF

**Parent node:**
- **Name:** `CurrentTabContainer`
- **Type:** `Control`
- **size_flags_vertical:** `3` (SIZE_EXPAND_FILL) ✅
- **Runtime size:** `(1235, 0)` 🔴 **HEIGHT = 0!**

**Analysis:** CurrentTabContainer has correct size flags but **height = 0**. This is the immediate cause of the collapse.

---

### 6. VERTICAL SIZE FLAGS CHAIN - LIST FROM RaceTab ROOT UPWARD

**Complete chain from RaceTab upward:**

| Level | Node | Type | Horizontal | Vertical | Status |
|-------|------|------|------------|----------|--------|
| 0 | RaceTab | Control | 3 | 3 | ✅ |
| 1 | CurrentTabContainer | Control | 3 | 3 | ✅ |
| 2 | MarginContainer3 | MarginContainer | 1 | **1** | ⚠️ **Not SIZE_EXPAND_FILL!** |
| 3 | center_area | VBoxContainer | 1 | **1** | ⚠️ **Not SIZE_EXPAND_FILL!** |
| 4 | MarginContainer2 | MarginContainer | 3 | 3 | ✅ |
| 5 | MainHBox | HBoxContainer | 3 | 3 | ✅ |
| 6 | CharacterCreationRoot | Control | 1 | **1** | ⚠️ **Not SIZE_EXPAND_FILL!** |

**🚨 CRITICAL FINDINGS:**

1. **MarginContainer3** has `vertical = 1` (not 3 = SIZE_EXPAND_FILL)
2. **center_area** (VBoxContainer) has `vertical = 1` (not 3)
3. **CharacterCreationRoot** has `vertical = 1` (not 3)

**However**, these nodes with `vertical = 1` are not necessarily the cause - they might be using different sizing strategies. The real issue is that **CurrentTabContainer has height = 0**.

---

### 7. QUICK LIVE TEST PERFORMED

**a) UnifiedScroll size_flags_vertical:**
- Original: `3` (SIZE_EXPAND_FILL) ✅
- Original size: `(1235, 0)` 🔴

**b) After setting size_flags_vertical = 3 (SIZE_EXPAND_FILL):**
- UnifiedScroll size: `(1235, 0)` 🔴
- **Height > 0?** **NO**

**c) Direct child of UnifiedScroll (RaceGrid):**
- RaceGrid size_flags_vertical: `3` ✅

**d) RaceTab root:**
- Original size_flags_vertical: `3` ✅
- (Already was SIZE_EXPAND_FILL, no change needed)

**Analysis:** Setting UnifiedScroll size_flags_vertical to 3 didn't help because the **parent chain has height = 0**. The size flags are correct, but the parent containers don't have height.

---

### 8. ANCHORS VS SIZE FLAGS CONFLICT CHECK

**Nodes using Anchors Mode (layout_mode = 1):**

**RaceTab:**
- `layout_mode: 1` (Anchors)
- `anchors_preset: 15` (Full Rect)
- All anchors: `0.0, 0.0, 1.0, 1.0`
- All offsets: `0, 0, 0, 0`

**MainPanel:**
- `layout_mode: 1` (Anchors)
- `anchors_preset: 15` (Full Rect)
- All anchors: `0.0, 0.0, 1.0, 1.0`
- All offsets: `0, 0, 0, 0`

**UnifiedScroll:**
- `layout_mode: 1` (Anchors) ⚠️
- `anchors_preset: 15` (Full Rect)
- All anchors: `0.0, 0.0, 1.0, 1.0`
- `offset_top: 80.0` ⚠️ **CRITICAL**
- `offset_bottom: 0.0`

**🚨 ROOT CAUSE IDENTIFIED:**

UnifiedScroll uses **anchors mode** with:
- `offset_top = 80` (accounts for TitleMargin height)
- `offset_bottom = 0`

**The formula is:** `height = parent_height - offset_top - offset_bottom`

Since `offset_bottom = 0`:
- `height = parent_height - 80`

**If parent (MainPanel) has height = 0:**
- `UnifiedScroll height = 0 - 80 = 0` 🔴

**The issue:** MainPanel (and its parent chain) has height = 0, so UnifiedScroll calculates its height as 0, making it invisible.

---

## 🔴 SMOKING GUN - ROOT CAUSE IDENTIFIED

### THE PROBLEM:

**CurrentTabContainer has height = 0**

**Why this happens:**
1. CurrentTabContainer is a Control node with size_flags_vertical = 3 ✅
2. But it's inside MarginContainer3 → center_area → MarginContainer2
3. The parent chain may not be properly expanding vertically
4. When CurrentTabContainer has height = 0:
   - RaceTab (anchored to fill parent) gets height = 0
   - MainPanel (anchored to fill RaceTab) gets height = 0
   - UnifiedScroll calculates: `height = 0 - 80 = 0` 🔴

### THE FIX NEEDED:

The issue is that **CurrentTabContainer** needs to properly expand to fill its parent's vertical space. Even though it has size_flags_vertical = 3, the parent containers may not be providing vertical space.

**Key observation:** MarginContainer3 and center_area both have `vertical = 1` instead of `3`, which may be preventing vertical expansion.

---

## SUMMARY

**All 8 questions answered with exact runtime values.**

**Root cause:** 
- UnifiedScroll uses anchors with `offset_top = 80`
- Parent chain (CurrentTabContainer → RaceTab → MainPanel) has height = 0
- UnifiedScroll calculates: `height = 0 - 80 = 0`

**Fix direction:** Ensure CurrentTabContainer and its parent containers properly expand vertically to provide height > 0 to RaceTab/MainPanel, which will then allow UnifiedScroll to calculate a valid height.

