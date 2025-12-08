# Race/Subrace to Class Selection Transition Analysis

## Executive Summary

This document provides comprehensive answers to questions about cleaning the transition from race/subrace selection to class selection in the BG3 character creation clone. All code follows project rules: data-driven JSON, single `bg3_theme.tres`, typed GDScript, snake_case variables, PascalCase classes.

---

## 1. Current Implementation Details

### 1.1 Scene Hierarchy and Node Structure

**RaceTab Scene Structure:**
```
RaceTab (Control)
└── MainPanel (Panel)
    ├── TitleMargin (MarginContainer)
    │   └── TitleLabel (Label) - %TitleLabel
    ├── UnifiedScroll (ScrollContainer) - %UnifiedScroll
    │   └── RaceGrid (GridContainer) - %RaceGrid (3 columns)
    ├── BackButton (Button) - %BackButton
    └── ConfirmRaceButton (Button) - %ConfirmRaceButton
```

**ClassTab Scene Structure:**
```
ClassTab (Control)
└── MainSplit (HSplitContainer)
    ├── LeftColumn
    │   └── ScrollContainer
    │       └── ClassList (VBoxContainer)
    └── RightPanel
        └── MarginContainer
            └── Info
                ├── SelectedClassName (Label)
                ├── ClassDescription (RichTextLabel)
                ├── ProficienciesList (RichTextLabel)
                └── FeaturesList (RichTextLabel)
```

### 1.2 Data Loading

**Races/Subraces:**
- Source: `res://data/races.json` (Array of race dictionaries)
- Loader: `GameData.gd` singleton in `_ready()` → `load_all_data()` → `_load_json_array()`
- Structure: Each race has `id`, `name`, `subraces` array, `ability_bonuses`, `features`, etc.
- Access: `GameData.races` (typed as `Array[Dictionary]`)

**Classes:**
- Source: `res://data/classes.json` (Array of class dictionaries)
- Loader: Same `GameData.gd` mechanism
- Structure: Each class has `id`, `name`, `proficiencies`, `features`, `subclasses`, etc.
- Access: `GameData.classes` (typed as `Array[Dictionary]`)

### 1.3 Transition Trigger

**Current Flow:**
1. User selects race → `RaceTab._on_race_selected()` emits `race_selected(race_id, subrace_id)` signal (preview only)
2. User clicks "Confirm Race →" → `RaceTab._confirm_race()` checks if subraces exist
3. If subraces exist → switches to `MODE_SUBRACE`, repopulates grid with subraces
4. User selects subrace → `RaceTab._on_race_selected()` (preview)
5. User clicks "Confirm Subrace →" → `RaceTab._confirm_subrace()` calls `_store_race_data()` then emits `tab_completed`
6. `CharacterCreationRoot._on_race_tab_completed()` receives `tab_completed` signal
7. Calls `tab_navigation.enable_next_tab()` which:
   - Updates `current_tab` from "Race" to "Class"
   - Emits `tab_changed("Class")` signal
8. `CharacterCreationRoot._on_tab_changed("Class")` loads `ClassTab.tscn` and connects signals

### 1.4 Data Passing Mechanisms

**Primary Storage:**
- `PlayerData.gd` (autoload singleton) stores confirmed selections:
  - `PlayerData.race_id` (String)
  - `PlayerData.subrace_id` (String)
  - `PlayerData.race_data` (Dictionary - merged race+subrace)

**Signal Chain:**
- `RaceTab.tab_completed` → `CharacterCreationRoot._on_race_tab_completed()` → `TabNavigation.enable_next_tab()` → `tab_changed` signal → `CharacterCreationRoot._load_tab("Class")`

**Data Persistence:**
- Race data is stored in `PlayerData` BEFORE `tab_completed` is emitted (in `_store_race_data()`)
- ClassTab reads from `GameData.classes` directly, does NOT currently read `PlayerData.race_id` for filtering

---

## 2. Desired Flow and UX

### 2.1 Current "Cleaning" Issues Identified

Based on code analysis, these areas need improvement:

**A. No Visual Transition Animation**
- Tab switches are instant (`remove_child()` → `add_child()` in `_load_tab()`)
- No fade/translate animation between RaceTab and ClassTab

**B. No Race-Dependent Class Filtering**
- `ClassTab._populate_list()` loads ALL classes without checking race compatibility
- No validation that selected race allows specific classes (if such rules exist in JSON)

**C. Tab State Not Preserved on Back Navigation**
- If user goes back from ClassTab to RaceTab, they see fresh state (no selected race highlighted)
- RaceTab doesn't restore previous selection when re-entered

**D. No Loading/Transition Feedback**
- No visual indicator during tab transition
- No error handling UI if ClassTab fails to load

**E. Potential Data Race**
- `ClassTab._ready()` calls `_populate_list()` immediately
- If `GameData.classes` isn't fully loaded, population may fail silently
- RaceTab has double `await get_tree().process_frame` for safety, ClassTab doesn't

### 2.2 Recommended Intermediate Steps

**Option A: No Summary Popup (Recommended)**
- Direct transition with smooth animation
- Race/subrace info remains visible in preview panel (right side)
- Cleaner, faster UX

**Option B: Summary Popup**
- Small modal confirming "Race: Dwarf (Hill Dwarf)" before proceeding
- Adds extra click but provides confirmation
- May break BG3 fidelity (BG3 doesn't do this)

**Recommendation: Option A** - matches BG3 flow exactly.

### 2.3 Class Compatibility Handling

**Current State:**
- `classes.json` does NOT contain `race_compatibility` or `forbidden_races` fields
- All classes are available to all races (5e D&D standard)

**If Compatibility Rules Are Added:**
1. Add to `classes.json`: `"race_restrictions": ["dwarf", "elf"]` or `"race_forbidden": ["halfling"]`
2. Filter in `ClassTab._populate_list()`:
   ```gdscript
   var player_race: String = PlayerData.race_id
   if cls.has("race_restrictions") and player_race not in cls.get("race_restrictions", []):
       continue  # Skip incompatible class
   ```
3. Visual feedback: gray out or hide incompatible entries
4. Optionally show tooltip: "This class is not available for your selected race"

**Recommendation:** Since current JSON lacks compatibility fields, implement flexible filtering that gracefully handles missing fields (future-proof).

### 2.4 Theme Migration Needs

**Current Hard-Coded Styles (Found in RaceTab/ClassTab):**
- `RaceTab.gd` line 50: `theme_override_font_sizes/font_size = 64` (in .tscn)
- `TabNavigation.gd` lines 30-38: Creates `StyleBoxFlat` instances programmatically instead of using theme

**Actions Required:**
1. Move `TitleLabel` font size to `bg3_theme.tres` as a theme constant or custom stylebox
2. Move `TabNavigation` styleboxes to theme (custom stylebox names like `selected_tab_button`, `normal_tab_button`)
3. Replace hard-coded colors with theme references

---

## 3. Data and Dependencies

### 3.1 JSON Structure Reference

**races.json:**
```json
{
  "id": "dwarf",
  "name": "Dwarf",
  "description": "...",
  "speed": "7.5m / 25ft",
  "size": "Medium",
  "features": ["Darkvision up to 12m", ...],
  "ability_bonuses": { "constitution": 2 },
  "subraces": [
    {
      "id": "hill_dwarf",
      "name": "Hill Dwarf",
      "description": "...",
      "features": [...],
      "ability_bonuses": { "wisdom": 1 }
    }
  ]
}
```

**classes.json:**
```json
{
  "id": "barbarian",
  "name": "Barbarian",
  "hit_die": "1d12",
  "description": "...",
  "proficiencies": ["Light Armor", ...],
  "features": ["Rage", "Unarmored Defense"],
  "subclasses": [...]
}
```

**Missing Fields for Class Compatibility (if needed):**
- `race_restrictions: Array[String]` - only these races can use
- `race_forbidden: Array[String]` - these races cannot use
- `subrace_specific: Dictionary` - subrace-specific class bonuses

### 3.2 Singleton Scripts

**GameData.gd (Autoload):**
- Loads all JSON files on `_ready()`
- Provides `GameData.races`, `GameData.classes`, `GameData.backgrounds`, etc.
- Typed arrays: `Array[Dictionary]`
- Must be loaded before any tab accesses data

**PlayerData.gd (Autoload):**
- Stores confirmed character creation selections
- Persists across tab transitions
- Has `reset()` method for new character
- Structure:
  - `race_id: String`
  - `subrace_id: String`
  - `race_data: Dictionary` (merged race+subrace)
  - `class_id: String`
  - `class_data: Dictionary`

### 3.3 External Dependencies

**Ability Scores:**
- `AbilityScoreTab.gd` will read `PlayerData.race_data` to apply racial bonuses
- Uses `race_data.get("ability_bonuses", {})` which is merged in `RaceTab._store_race_data()`

**Preview Panel:**
- `CharacterCreationRoot` maintains preview state separately (`preview_race`, `confirmed_race`)
- Preview updates immediately on race selection
- Confirmed state stored in `PlayerData` after confirm button

**No Current Dependency Issues:**
- ClassTab doesn't read race data yet (should for filtering)
- AbilityScoreTab will depend on both race AND class (for multiclass rules - future)

---

## 4. Testing and Edge Cases

### 4.1 Identified Edge Cases

**A. Rapid Tab Switching**
- User clicks "Confirm Subrace" then immediately clicks "Class" tab button
- Potential race condition: `tab_completed` signal may fire after manual tab change
- **Fix:** Add guard in `TabNavigation._on_tab_pressed()` to prevent skipping ahead

**B. Back Navigation from ClassTab to RaceTab**
- RaceTab reinitializes with empty selection
- User's previous race/subrace choice not highlighted
- **Fix:** In `RaceTab._ready()`, check `PlayerData.race_id` and restore selection state

**C. Missing Subrace on Race with Subraces**
- User confirms race with subraces but somehow bypasses subrace selection
- Current code prevents this (forces subrace mode), but defensive coding needed

**D. Empty Classes Array**
- If `GameData.classes` is empty, `ClassTab._populate_list()` returns early
- No error message shown to user
- **Fix:** Show error label similar to RaceTab's `ErrorLabel`

**E. Tab Load Failure**
- If `ClassTab.tscn` fails to load, `current_tab_instance` becomes null
- Next tab change may crash
- **Fix:** Add null checks in `_load_tab()` and fallback to previous tab

**F. Race Data Not Stored Before Tab Switch**
- If `_store_race_data()` fails silently, `PlayerData.race_id` remains empty
- ClassTab can't filter by race
- **Fix:** Add error handling and validation in `_store_race_data()`

### 4.2 Testing Scenarios

**Recommended Test Flow (via MCP `run_project`):**

1. **Normal Flow:**
   - Select race → confirm → select subrace → confirm → verify ClassTab loads
   - Verify race data in `PlayerData.race_id` is set
   - Verify all classes are visible (no filtering yet)

2. **Race Without Subraces:**
   - Select race with no subraces → confirm → verify immediate transition to ClassTab
   - Verify `PlayerData.subrace_id` is empty string

3. **Back Navigation:**
   - Complete race selection → go to ClassTab → click "Race" tab → verify RaceTab shows selected race highlighted

4. **Rapid Clicking:**
   - Rapidly click "Confirm Subrace" multiple times → verify only one tab transition occurs
   - Verify no duplicate signals or race conditions

5. **Data Persistence:**
   - Select race/subrace → go to ClassTab → check `PlayerData.race_data` contains merged data
   - Verify ability bonuses are correctly merged

6. **Error Handling:**
   - Corrupt `classes.json` → verify graceful error message
   - Empty `GameData.classes` → verify error label appears

---

## 5. Recommended Implementation Plan

### Phase 1: Fix Immediate Issues

1. **Add Transition Animation**
   - Implement fade-out/fade-in between tabs in `CharacterCreationRoot._load_tab()`
   - Use `Tween` or `AnimationPlayer` for smooth transitions
   - Duration: 0.2-0.3 seconds

2. **Add Race Data Validation**
   - In `ClassTab._ready()`, verify `PlayerData.race_id` is not empty before populating
   - Show error if race not selected (defensive)

3. **Fix Back Navigation**
   - In `RaceTab._ready()`, restore selection from `PlayerData.race_id` if exists
   - Set `current_mode` and `selected_race`/`selected_subrace` from stored data

### Phase 2: Enhance UX

4. **Add Loading State**
   - Show loading spinner during tab transition (if transition takes > 100ms)

5. **Improve Error Handling**
   - Add error label to `ClassTab.tscn` (similar to RaceTab)
   - Display errors when class loading fails

6. **Theme Migration**
   - Move hard-coded styles to `bg3_theme.tres`
   - Update `TabNavigation.gd` to use theme styleboxes

### Phase 3: Future-Proofing (Optional)

7. **Add Class Compatibility Filtering**
   - Implement flexible filtering system in `ClassTab._populate_list()`
   - Supports optional `race_restrictions`/`race_forbidden` in `classes.json`
   - Gracefully handles missing fields (all classes available if no restrictions)

8. **Add Transition Summary (Optional)**
   - If user requests, add small summary popup before class selection
   - Otherwise skip (matches BG3)

---

## 6. Code Examples

### Example: Smooth Tab Transition

```gdscript
# In CharacterCreationRoot._load_tab()
func _load_tab(tab_name: String) -> void:
    # Fade out current tab
    if current_tab_instance:
        var tween := create_tween()
        tween.tween_property(current_tab_instance, "modulate:a", 0.0, 0.15)
        await tween.finished
        content_area.remove_child(current_tab_instance)
        current_tab_instance.queue_free()
    
    # Load and add new tab (invisible)
    var path: String = TAB_SCENES[tab_name]
    var scene := load(path) as PackedScene
    if scene:
        current_tab_instance = scene.instantiate()
        current_tab_instance.modulate.a = 0.0  # Start invisible
        content_area.add_child(current_tab_instance)
        
        # Fade in new tab
        var tween2 := create_tween()
        tween2.tween_property(current_tab_instance, "modulate:a", 1.0, 0.15)
```

### Example: Restore Selection on Back Navigation

```gdscript
# In RaceTab._ready()
func _ready() -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    
    # Restore previous selection if returning from another tab
    if PlayerData.race_id != "":
        selected_race = PlayerData.race_id
        selected_subrace = PlayerData.subrace_id
        if PlayerData.subrace_id != "":
            # Find parent race
            for race in GameData.races:
                if race.get("id", "") == PlayerData.race_id:
                    pending_race = race
                    current_mode = MODE_SUBRACE
                    break
    
    _update_ui_for_mode()
    _populate_list()
    
    # Restore visual selection after population
    if selected_race != "":
        _restore_visual_selection()
```

### Example: Class Compatibility Filtering

```gdscript
# In ClassTab._populate_list()
func _populate_list() -> void:
    var player_race: String = PlayerData.race_id
    
    for cls in GameData.classes:
        # Check race restrictions (if field exists)
        if cls.has("race_restrictions"):
            var allowed: Array = cls.get("race_restrictions", [])
            if player_race not in allowed:
                continue  # Skip incompatible class
        
        # Check race forbidden list (if field exists)
        if cls.has("race_forbidden"):
            var forbidden: Array = cls.get("race_forbidden", [])
            if player_race in forbidden:
                continue  # Skip forbidden class
        
        # Create and add entry (existing code)
        var entry := class_entry_scene.instantiate()
        entry.setup(cls)
        entry.class_selected.connect(_on_class_selected)
        class_list.add_child(entry)
```

---

## 7. Summary

### Key Findings

1. **Transition is functional but lacks polish** - instant tab switching, no animations
2. **No race-class compatibility filtering** - all classes available (matches 5e, but system should support filtering)
3. **Back navigation loses state** - RaceTab doesn't restore previous selection
4. **Minimal error handling** - failures are silent or logged only

### Priority Actions

1. ✅ **HIGH:** Add smooth transition animation
2. ✅ **HIGH:** Fix back navigation state restoration
3. ✅ **MEDIUM:** Add race data validation in ClassTab
4. ✅ **MEDIUM:** Move hard-coded styles to theme
5. ✅ **LOW:** Implement class compatibility filtering (future-proof)

### Ready for Implementation

All questions answered. Ready to generate implementation code using MCP actions (`write_file`, `read_file`, `run_project`) following project rules.

