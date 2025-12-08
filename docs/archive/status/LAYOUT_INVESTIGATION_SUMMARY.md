# LAYOUT INVESTIGATION SUMMARY

## EXECUTIVE SUMMARY

Complete analysis of the Character Creation scene layout structure, node properties, and potential issues.

---

## 1. ROOT NODE ANALYSIS

**Scene:** `res://scenes/character_creation/CharacterCreationRoot.tscn`

**Root Node:** `CharacterCreationRoot` (Control)
- **Type:** Control
- **Layout Mode:** 1 (Anchors)
- **Anchors Preset:** 15 (Full Rect)
- **Size Flags:** Horizontal=3 (Expand+Fill), Vertical=3 (Expand+Fill)

**Main Container:** `MainHBox` (HBoxContainer)
- **Type:** HBoxContainer
- **Layout Mode:** 1 (Anchors)
- **Anchors Preset:** 15 (Full Rect)
- **Size Flags:** Horizontal=3 (Expand+Fill), Vertical=3 (Expand+Fill)
- **Custom Constants → Separation:** **0** (no spacing between children)

---

## 2. THREE MAIN CONTAINERS - DETAILED PROPERTIES

### 2.1 LEFT SIDEBAR (Steps 4,5,6)

**Node Path:** `MainHBox/MarginContainer`

**Properties:**
- **Type:** MarginContainer
- **Layout Mode:** 2 (Container)
- **Size Flags Horizontal:** **0** (No flags - fixed width)
- **Size Flags Vertical:** **0** (No flags)
- **Custom Minimum Size:** **Vector2(320, 0)** ✅ Fixed at 320px width

**Child Hierarchy:**
```
MarginContainer (320px min width)
├── SidebarBorder (Panel) - Full rect anchors
└── VBoxContainer - Full rect anchors
    └── TabNavigation (instance)
```

**Theme:** `res://themes/bg3_theme.tres`
**StyleBox:** `bg3_sidebar_border` (no min size constraints)

---

### 2.2 CENTER AREA (Race Selection)

**Node Path:** `MainHBox/MarginContainer2`

**Properties:**
- **Type:** MarginContainer
- **Layout Mode:** 2 (Container)
- **Size Flags Horizontal:** **3** (Expand + Fill) ✅ Should expand
- **Size Flags Vertical:** **3** (Expand + Fill)
- **Custom Minimum Size:** **None** ✅ No constraints

**Child Hierarchy:**
```
MarginContainer2 (Expand+Fill)
└── center_area (VBoxContainer)
    └── MarginContainer3 (margins: 60,80,60,80)
        └── CurrentTabContainer (Control) - Expand+Fill
            └── [RaceTab instance loaded dynamically]
```

**RaceTab Structure (when loaded):**
```
RaceTab (Control) - Expand+Fill
└── MainPanel (Panel) - Expand+Fill
    ├── TitleLabel (Label) - "CHOOSE YOUR RACE" ⚠️
    └── UnifiedScroll (ScrollContainer)
        └── RaceGrid (GridContainer) - 4 columns
```

**Theme:** `res://themes/bg3_theme.tres`

---

### 2.3 RIGHT PREVIEW PANEL

**Node Path:** `MainHBox/MarginContainer4`

**Properties:**
- **Type:** MarginContainer
- **Layout Mode:** 2 (Container)
- **Size Flags Horizontal:** **0** (No flags - fixed width)
- **Size Flags Vertical:** **0** (No flags)
- **Custom Minimum Size:** **Vector2(420, 0)** ✅ Fixed at 420px width

**Child Hierarchy:**
```
MarginContainer4 (420px min width)
├── PreviewBorder (Panel) - Full rect anchors
└── PreviewMargin (MarginContainer) - Full rect anchors
    └── VBoxContainer - Full rect anchors
        ├── SelectedTitle (Label) - "CHOOSE YOUR RACE"
        ├── Subtitle (Label)
        ├── Description (RichTextLabel)
        ├── SpeedSize (Label)
        ├── AbilityScores (RichTextLabel)
        ├── FeaturesTitle (Label)
        └── FeaturesList (ItemList)
```

**Theme:** `res://themes/bg3_theme.tres`
**StyleBox:** `bg3_preview_panel` (no min size constraints)

---

## 3. "CHOOSE YOUR RACE" LABEL ANALYSIS

### 3.1 CENTER LABEL (The Giant One)

**Node Path:** `RaceTab/MainPanel/TitleLabel`

**Full Parent Chain:**
```
CharacterCreationRoot (Control)
└── MainHBox (HBoxContainer) - Separation: 0
    └── MarginContainer2 (MarginContainer) - Expand+Fill
        └── center_area (VBoxContainer)
            └── MarginContainer3 (MarginContainer) - margins: 60,80,60,80
                └── CurrentTabContainer (Control) - Expand+Fill
                    └── RaceTab (Control) - Expand+Fill
                        └── MainPanel (Panel) - Expand+Fill
                            └── TitleLabel (Label) ⚠️
```

**Label Properties:**
- **Type:** Label
- **Layout Mode:** **1 (Anchors)** ⚠️ Should be Container mode
- **Anchors Preset:** **2 (Top Wide)**
- **Anchor Top:** 0.0
- **Anchor Bottom:** 0.0
- **Anchor Left:** **0.0** (spans full width)
- **Anchor Right:** **1.0** (spans full width)
- **Grow Horizontal:** 2 (Expand)
- **Grow Vertical:** 0 (No grow)
- **Offset Bottom:** 80.0
- **Custom Minimum Size:** Vector2(0, 80) - Fixed height 80px
- **Size Flags Vertical:** 0 (No flags)
- **Font Size:** **64px** ⚠️ Very large
- **Text:** "CHOOSE YOUR RACE"
- **Horizontal Alignment:** 1 (Center)
- **Autowrap:** **Not set (defaults to false)** ⚠️ No text wrapping
- **Full Rect:** No (uses Top Wide preset)
- **Expand:** Yes (grow_horizontal = 2)

**Analysis:**
- Label uses **Anchors mode** which can cause layout issues in container-based layouts
- Spans **full width** of MainPanel (anchor_left=0, anchor_right=1)
- **No autowrap** - text will overflow if container is too narrow
- **Large font size (64px)** may require more space than available
- Fixed height of 80px is fine

---

## 4. HBoxContainer CHILD SIZE FLAGS

**MainHBox Children (in order):**

1. **MarginContainer** (Left Sidebar)
   - Size Flags Horizontal: **0** (No flags)
   - Custom Minimum Size: **320, 0**

2. **MarginContainer2** (Center Area)
   - Size Flags Horizontal: **3** (Expand + Fill)
   - Custom Minimum Size: **None**

3. **MarginContainer4** (Right Panel)
   - Size Flags Horizontal: **0** (No flags)
   - Custom Minimum Size: **420, 0**

**Separation:** **0** (no spacing between containers)

**Expected Behavior:**
- Left: Fixed 320px
- Center: Expands to fill remaining space
- Right: Fixed 420px
- Total fixed width: 320 + 420 = 740px
- Center should get: window_width - 740px

---

## 5. THEME RESOURCES

**Root Theme:** `res://themes/bg3_theme.tres`

**Applied to:**
- CharacterCreationRoot (Control)
- ColorRect (background)

**StyleBox Resources:**
1. **bg3_sidebar_border** (StyleBoxFlat_38)
   - Applied to: Left sidebar Panel
   - **No minimum size constraints** ✅

2. **bg3_preview_panel** (StyleBoxFlat_39)
   - Applied to: Right panel Panel
   - **No minimum size constraints** ✅

**Theme Constants:**
- No theme constants forcing minimum widths found ✅
- Font sizes are overridden but don't affect layout sizing ✅

---

## 6. VERBOSE OUTPUT ANALYSIS

**No warnings found about:**
- "Control size is smaller than minimum size"
- "Node cannot satisfy size requests"
- Any layout constraint violations

**Debug Output:**
- RaceGrid size when TitleLabel visible: (398, 1962)
- RaceGrid size when TitleLabel hidden: (260, 1962)
- **Difference: 138px** - suggests TitleLabel is affecting layout

---

## 7. TEST: DISABLING TITLE LABEL

**Test Performed:** Set `visible = false` on TitleLabel

**Results:**
- RaceGrid width changed from **398px to 260px**
- **138px difference** suggests TitleLabel is consuming space
- However, TitleLabel should only be 80px tall, not affecting width
- **Conclusion:** TitleLabel's anchor-based layout may be interfering with container sizing

---

## 8. IDENTIFIED ISSUES

### Issue #1: TitleLabel Uses Anchors Mode ⚠️
- **Problem:** TitleLabel uses Layout Mode 1 (Anchors) instead of Container mode
- **Impact:** Can cause layout conflicts in container-based parent
- **Fix:** Change to Layout Mode 2 (Container)

### Issue #2: TitleLabel Spans Full Width ⚠️
- **Problem:** anchor_left=0, anchor_right=1 spans entire MainPanel width
- **Impact:** May force MainPanel to expand beyond available space
- **Fix:** Use Container mode with proper size flags

### Issue #3: No Autowrap on TitleLabel ⚠️
- **Problem:** autowrap_mode not set (defaults to false)
- **Impact:** Text may overflow if container is too narrow
- **Fix:** Enable autowrap or reduce font size

### Issue #4: Large Font Size ⚠️
- **Problem:** Font size is 64px
- **Impact:** Requires significant horizontal space
- **Fix:** Consider reducing to 48px or 56px

---

## 9. RECOMMENDATIONS

1. **Change TitleLabel to Container Mode**
   - Set `layout_mode = 2` (Container)
   - Remove anchors preset
   - Use size flags instead

2. **Add Autowrap to TitleLabel**
   - Set `autowrap_mode = 3` (Automatic)

3. **Consider Reducing Font Size**
   - Reduce from 64px to 48px or 56px

4. **Verify Center Area Expansion**
   - Ensure MarginContainer2 properly expands
   - Check that center_area VBoxContainer doesn't constrain width

---

## 10. CONCLUSION

The layout structure is **mostly correct**:
- ✅ Left sidebar: Fixed 320px width
- ✅ Center area: Expand+Fill (should work)
- ✅ Right panel: Fixed 420px width
- ✅ No theme constraints causing issues
- ✅ No size constraint warnings

**Primary Suspect:** The TitleLabel in RaceTab uses **Anchors mode** and spans full width, which may be interfering with the container-based layout system. Changing it to Container mode should resolve the issue.

