# RACE DATA DISPLAY NODES - COMPLETE INVENTORY

## Summary

This report lists every scene, script, and Control node responsible for displaying race data in the character creation system.

---

## 1. SCENES THAT DISPLAY RACE DATA

### 1.1 Primary Race Selection Tab
**Scene:** `scenes/character_creation/tabs/RaceTab.tscn`  
**Script:** `scripts/character_creation/tabs/RaceTab.gd`

This is the main tab where users select their race from a three-column layout.

---

## 2. CONTROL NODES DISPLAYING RACE COLUMNS

### 2.1 Three-Column Layout Container

**Node Path:** `RaceTab/MainPanel/UnifiedScroll/ColumnsContainer`  
**Type:** `HBoxContainer`  
**Unique Name:** `ColumnsContainer`  
**Purpose:** Contains the three VBoxContainer columns that hold race entries

**Column 1:**
- **Node Path:** `RaceTab/MainPanel/UnifiedScroll/ColumnsContainer/Column1Content`
- **Type:** `VBoxContainer`
- **Unique Name:** `Column1Content`
- **Script Reference:** `@onready var column_1: VBoxContainer = %Column1Content`

**Column 2:**
- **Node Path:** `RaceTab/MainPanel/UnifiedScroll/ColumnsContainer/Column2Content`
- **Type:** `VBoxContainer`
- **Unique Name:** `Column2Content`
- **Script Reference:** `@onready var column_2: VBoxContainer = %Column2Content`

**Column 3:**
- **Node Path:** `RaceTab/MainPanel/UnifiedScroll/ColumnsContainer/Column3Content`
- **Type:** `VBoxContainer`
- **Unique Name:** `Column3Content`
- **Script Reference:** `@onready var column_3: VBoxContainer = %Column3Content`

### 2.2 Scroll Container
**Node Path:** `RaceTab/MainPanel/UnifiedScroll`  
**Type:** `ScrollContainer`  
**Unique Name:** `UnifiedScroll`  
**Purpose:** Provides scrolling for the three-column layout

---

## 3. INDIVIDUAL RACE ENTRY COMPONENT

### 3.1 Race Entry Scene
**Scene:** `scenes/character_creation/tabs/components/RaceEntry.tscn`  
**Script:** `scripts/character_creation/tabs/components/RaceEntry.gd`  
**Type:** `PanelContainer` (root node)

**Control Nodes Inside RaceEntry:**

1. **Icon Display:**
   - **Node Path:** `RaceEntry/MarginContainer/VBoxContainer/Icon`
   - **Type:** `TextureRect`
   - **Unique Name:** `Icon`
   - **Script Reference:** `@onready var icon: TextureRect = %Icon`
   - **Purpose:** Displays race icon/placeholder

2. **Race Name Label:**
   - **Node Path:** `RaceEntry/MarginContainer/VBoxContainer/RaceNameLabel`
   - **Type:** `Label`
   - **Unique Name:** `RaceNameLabel`
   - **Script Reference:** `@onready var race_name_label: Label = %RaceNameLabel`
   - **Purpose:** Displays race or subrace name

3. **Ability Preview Label:**
   - **Node Path:** `RaceEntry/MarginContainer/VBoxContainer/AbilityPreviewLabel`
   - **Type:** `RichTextLabel`
   - **Unique Name:** `AbilityPreviewLabel`
   - **Script Reference:** `@onready var ability_preview_label: RichTextLabel = %AbilityPreviewLabel`
   - **Purpose:** Displays ability score bonuses (STR, DEX, CON, INT, WIS, CHA)

---

## 4. SCRIPTS THAT POPULATE RACE COLUMNS

### 4.1 RaceTab.gd - Main Population Script

**File:** `scripts/character_creation/tabs/RaceTab.gd`  
**Function:** `_populate_list()` (lines 38-166)

**What it does:**
1. Clears existing entries from all three columns (lines 53-58)
2. Collects all race items (races + subraces) from `GameData.races` (lines 62-67)
3. Distributes entries across three columns using round-robin algorithm (lines 92-123)
4. Instantiates `RaceEntry.tscn` for each race/subrace (line 97)
5. Adds each entry to the appropriate column VBoxContainer (line 107)
6. Calls `setup()` method on each entry to populate race data (lines 112-117)
7. Adds VSpacer to each column to push content to top (lines 143-148)

**Key Variables:**
- `column_1`, `column_2`, `column_3`: References to the three VBoxContainer columns
- `race_entry_scene`: PackedScene reference to `RaceEntry.tscn`
- `all_entries`: Array storing all instantiated RaceEntry nodes

### 4.2 RaceEntry.gd - Individual Entry Population

**File:** `scripts/character_creation/tabs/components/RaceEntry.gd`  
**Function:** `setup()` (lines 45-50) and `_update_display()` (lines 52-66)

**What it does:**
1. Receives race data dictionary (and optional subrace dictionary)
2. Updates the race name label (line 60)
3. Builds ability preview text via `_build_ability_preview()` (line 63)
4. Sets up icon placeholder (line 66)

**Function:** `_build_ability_preview()` (lines 68-95)
- Merges race and subrace ability bonuses
- Formats bonuses as BBCode for RichTextLabel
- Displays in format: `+2 STR +1 DEX CON INT WIS CHA`

---

## 5. PREVIEW PANELS (Race Information Display)

### 5.1 CharacterCreationRoot Preview Panel

**Scene:** `scenes/character_creation/CharacterCreationRoot.tscn`  
**Script:** `scripts/character_creation/CharacterCreationRoot.gd`

**Control Nodes Displaying Race Data:**

1. **Race Title:**
   - **Node Path:** `CharacterCreationRoot/MainLayout/RightPreview/PreviewMargin/PreviewContent/SelectedTitle`
   - **Type:** `Label`
   - **Unique Name:** `SelectedTitle`
   - **Script Reference:** `@onready var preview_title: Label = %SelectedTitle`

2. **Subtitle:**
   - **Node Path:** `CharacterCreationRoot/MainLayout/RightPreview/PreviewMargin/PreviewContent/Subtitle`
   - **Type:** `Label`
   - **Unique Name:** `Subtitle`

3. **Description:**
   - **Node Path:** `CharacterCreationRoot/MainLayout/RightPreview/PreviewMargin/PreviewContent/Description`
   - **Type:** `RichTextLabel`
   - **Unique Name:** `Description`
   - **Script Reference:** `@onready var preview_description: RichTextLabel = %Description`

4. **Speed/Size:**
   - **Node Path:** `CharacterCreationRoot/MainLayout/RightPreview/PreviewMargin/PreviewContent/SpeedSize`
   - **Type:** `Label`
   - **Unique Name:** `SpeedSize`
   - **Script Reference:** `@onready var preview_speed_size: Label = %SpeedSize`

5. **Ability Scores:**
   - **Node Path:** `CharacterCreationRoot/MainLayout/RightPreview/PreviewMargin/PreviewContent/AbilityScores`
   - **Type:** `RichTextLabel`
   - **Unique Name:** `AbilityScores`
   - **Script Reference:** `@onready var preview_ability_scores: RichTextLabel = %AbilityScores`

6. **Features List:**
   - **Node Path:** `CharacterCreationRoot/MainLayout/RightPreview/PreviewMargin/PreviewContent/FeaturesList`
   - **Type:** `ItemList`
   - **Unique Name:** `FeaturesList`
   - **Script Reference:** `@onready var preview_features_list: ItemList = %FeaturesList`
   - **Purpose:** Displays race features as bullet points

**Population Function:** `_update_preview_panel()` (lines 185-260 in CharacterCreationRoot.gd)

### 5.2 RacePreview Component (Legacy/Unused?)

**Scene:** `scenes/character_creation/tabs/components/RacePreview.tscn`  
**Script:** `scripts/character_creation/tabs/components/RacePreview.gd`

**Note:** This component exists but may not be actively used, as `CharacterCreationRoot` handles preview display directly.

**Control Nodes:**
- `RacePreviewPanel/MarginContainer/VBoxContainer/RaceFeaturesList` (ItemList)
- Various labels for race name, speed, size, description, ability scores

---

## 6. DATA SOURCE

**File:** `data/races.json`  
**Loaded by:** `singletons/GameData.gd` (as `GameData.races`)

All race data (names, descriptions, abilities, features, subraces) comes from this JSON file.

---

## 7. COMPLETE NODE PATH SUMMARY

### Race Selection Columns:
```
RaceTab
└── MainPanel
    └── UnifiedScroll (ScrollContainer)
        └── ColumnsContainer (HBoxContainer)
            ├── Column1Content (VBoxContainer) ← Populated with RaceEntry instances
            ├── Column2Content (VBoxContainer) ← Populated with RaceEntry instances
            └── Column3Content (VBoxContainer) ← Populated with RaceEntry instances
```

### Individual Race Entry:
```
RaceEntry (PanelContainer)
└── MarginContainer
    └── VBoxContainer
        ├── Icon (TextureRect)
        ├── RaceNameLabel (Label)
        └── AbilityPreviewLabel (RichTextLabel)
```

### Preview Panel:
```
CharacterCreationRoot
└── MainLayout
    └── RightPreview (PanelContainer)
        └── PreviewMargin
            └── PreviewContent (VBoxContainer)
                ├── SelectedTitle (Label)
                ├── Subtitle (Label)
                ├── Description (RichTextLabel)
                ├── SpeedSize (Label)
                ├── AbilityScores (RichTextLabel)
                ├── FeaturesTitle (Label)
                └── FeaturesList (ItemList)
```

---

## 8. SCRIPT RESPONSIBILITIES

| Script | Primary Function | Lines |
|--------|-----------------|-------|
| `RaceTab.gd` | Populates three columns with RaceEntry instances | 38-166 |
| `RaceEntry.gd` | Displays individual race data (name, icon, abilities) | 45-95 |
| `CharacterCreationRoot.gd` | Updates preview panel with selected race details | 185-260 |

---

**Report Generated:** Complete inventory of all race data display nodes

