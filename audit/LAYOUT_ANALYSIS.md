# CHARACTER CREATION LAYOUT ANALYSIS

## 1. ROOT NODE STRUCTURE

**Root Node:** `CharacterCreationRoot` (Control)
- **Layout Mode:** 1 (Anchors)
- **Anchors Preset:** 15 (Full Rect)
- **Size Flags Horizontal:** 3 (Expand + Fill)
- **Size Flags Vertical:** 3 (Expand + Fill)

**Main Container:** `MainHBox` (HBoxContainer)
- **Layout Mode:** 1 (Anchors)
- **Anchors Preset:** 15 (Full Rect)
- **Size Flags Horizontal:** 3 (Expand + Fill)
- **Size Flags Vertical:** 3 (Expand + Fill)
- **Custom Constants → Separation:** 0

---

## 2. THREE MAIN CONTAINERS

### 2.1 LEFT SIDEBAR (Steps 4,5,6)

**Node Path:** `MainHBox/MarginContainer`

**Type:** MarginContainer
- **Layout Mode:** 2 (Container)
- **Size Flags Horizontal:** 0 (No flags)
- **Size Flags Vertical:** 0 (No flags)
- **Custom Minimum Size:** Vector2(320, 0)

**Child Structure:**
```
MarginContainer
├── SidebarBorder (Panel) - Full rect anchors
└── VBoxContainer - Full rect anchors
    └── TabNavigation (instance)
```

**Theme:** Uses `bg3_theme.tres` (via root)
**StyleBox:** `bg3_sidebar_border` (SubResource StyleBoxFlat_1)

---

### 2.2 CENTER AREA (Race Selection)

**Node Path:** `MainHBox/MarginContainer2`

**Type:** MarginContainer
- **Layout Mode:** 2 (Container)
- **Size Flags Horizontal:** 3 (Expand + Fill)
- **Size Flags Vertical:** 3 (Expand + Fill)
- **Custom Minimum Size:** None

**Child Structure:**
```
MarginContainer2
└── center_area (VBoxContainer)
    └── MarginContainer3
        └── CurrentTabContainer (Control)
            └── [RaceTab instance loaded here]
```

**MarginContainer3 Settings:**
- **Margins:** Left=60, Top=80, Right=60, Bottom=80

**CurrentTabContainer:**
- **Layout Mode:** 2 (Container)
- **Size Flags Horizontal:** 3 (Expand + Fill)
- **Size Flags Vertical:** 3 (Expand + Fill)

**RaceTab Structure (when loaded):**
```
RaceTab (Control)
└── MainPanel (Panel) - Full rect
    ├── TitleLabel (Label) - "CHOOSE YOUR RACE"
    └── UnifiedScroll (ScrollContainer)
        └── RaceGrid (GridContainer)
```

**Theme:** Uses `bg3_theme.tres` (via root)

---

### 2.3 RIGHT PREVIEW PANEL

**Node Path:** `MainHBox/MarginContainer4`

**Type:** MarginContainer
- **Layout Mode:** 2 (Container)
- **Size Flags Horizontal:** 0 (No flags)
- **Size Flags Vertical:** 0 (No flags)
- **Custom Minimum Size:** Vector2(420, 0)

**Child Structure:**
```
MarginContainer4
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

**Theme:** Uses `bg3_theme.tres` (via root)
**StyleBox:** `bg3_preview_panel` (SubResource StyleBoxFlat_2)

---

## 3. "CHOOSE YOUR RACE" LABEL ANALYSIS

### 3.1 CENTER LABEL (The Giant One)

**Node Path:** `RaceTab/MainPanel/TitleLabel`

**Type:** Label
- **Layout Mode:** 1 (Anchors)
- **Anchors Preset:** 2 (Top Wide)
- **Anchor Top:** 0.0
- **Anchor Bottom:** 0.0
- **Anchor Left:** 0.0
- **Anchor Right:** 1.0
- **Grow Horizontal:** 2 (Expand)
- **Grow Vertical:** 0 (No grow)
- **Offset Bottom:** 80.0
- **Custom Minimum Size:** Vector2(0, 80)
- **Size Flags Vertical:** 0 (No flags)
- **Font Size:** 64
- **Text:** "CHOOSE YOUR RACE"
- **Horizontal Alignment:** 1 (Center)
- **Autowrap:** Not set (defaults to false)

**Parent Chain:**
```
CharacterCreationRoot (Control)
└── MainHBox (HBoxContainer)
    └── MarginContainer2 (MarginContainer) - Expand+Fill
        └── center_area (VBoxContainer)
            └── MarginContainer3 (MarginContainer)
                └── CurrentTabContainer (Control) - Expand+Fill
                    └── RaceTab (Control) - Expand+Fill
                        └── MainPanel (Panel) - Expand+Fill
                            └── TitleLabel (Label)
```

**Analysis:**
- Label uses **Anchors mode** with **Top Wide preset**
- Spans full width of MainPanel (anchor_left=0, anchor_right=1)
- Fixed height of 80px (custom_minimum_size.y = 80)
- **No autowrap** - text will overflow if too long
- **No size flags** that would cause expansion issues

### 3.2 RIGHT PANEL LABEL

**Node Path:** `MainHBox/MarginContainer4/PreviewMargin/VBoxContainer/SelectedTitle`

**Type:** Label
- **Layout Mode:** 2 (Container)
- **Font Size:** 32
- **Text:** "CHOOSE YOUR RACE"
- **Horizontal Alignment:** 1 (Center)
- This is in the preview panel, not the center area

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

**Separation:** 0 (no spacing between containers)

---

## 5. THEME RESOURCES

**Root Theme:** `res://themes/bg3_theme.tres` (ExtResource id="3_0")

**Applied to:**
- CharacterCreationRoot (Control)
- ColorRect (background)

**StyleBox Resources (SubResources):**
1. **StyleBoxFlat_1** (`bg3_sidebar_border`)
   - Applied to: `MainHBox/MarginContainer/SidebarBorder` (Panel)
   - No minimum size constraints

2. **StyleBoxFlat_2** (`bg3_preview_panel`)
   - Applied to: `MainHBox/MarginContainer4/PreviewBorder` (Panel)
   - No minimum size constraints

**Theme Overrides:**
- No theme constants forcing minimum widths found
- Font sizes are overridden but don't affect layout sizing

---

## 6. POTENTIAL ISSUES IDENTIFIED

### Issue 1: TitleLabel in RaceTab
- Uses **Anchors mode** instead of Container mode
- Spans full width (anchor_left=0, anchor_right=1)
- Fixed height of 80px
- **No autowrap** - if text is too long, it will overflow
- Font size is 64px which is very large

### Issue 2: Center Area Layout
- MarginContainer2 has Expand+Fill (correct)
- But center_area VBoxContainer uses Container mode
- CurrentTabContainer uses Container mode with Expand+Fill
- RaceTab uses Anchors mode with Expand+Fill
- Multiple layout mode switches could cause issues

### Issue 3: No Size Constraints on TitleLabel
- TitleLabel has no maximum width
- Could theoretically expand beyond container bounds
- However, it's anchored to MainPanel which should constrain it

---

## 7. RECOMMENDATIONS

1. **TitleLabel should use Container mode** instead of Anchors mode for better layout control
2. **Add autowrap** to TitleLabel if text might be long
3. **Consider reducing font size** from 64px if it's causing layout issues
4. **Verify RaceTab MainPanel** is properly constrained by its parent

