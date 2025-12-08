# Race Selection to Appearance Tab 3D Preview - Flow Analysis

## Current Flow

### 1. Race Selection in RaceTab
- **Location**: `scripts/character_creation/tabs/RaceTab.gd`
- **Trigger**: User clicks a race entry
- **Action**: 
  - `RaceEntry._select_race()` emits `race_selected` signal (line 139)
  - `RaceTab._on_race_selected()` receives it (line 179)
  - Updates `selected_race` and `selected_subrace` (lines 208-209)
  - Emits `race_selected.emit(race_id, subrace_id)` (line 214)

### 2. CharacterCreationRoot Receives Race Selection
- **Location**: `scripts/character_creation/CharacterCreationRoot.gd`
- **Signal Connection**: Line 196-198 connects `RaceTab.race_selected` → `_on_race_selected()`
- **Action in `_on_race_selected()`** (lines 224-246):
  - Updates `preview_race` and `preview_subrace` (lines 226-227)
  - Updates `PlayerData.race_id` and `PlayerData.subrace_id` (lines 241-242)
  - Emits `PlayerData.racial_bonuses_updated.emit()` (line 244)
  - Updates preview panel (line 246)

### 3. AppearanceTab Receives Race Change
- **Location**: `scripts/character_creation/tabs/AppearanceTab.gd`
- **Signal Connection**: Line 38-39 connects `PlayerData.racial_bonuses_updated` → `_on_race_changed()`
- **Action in `_on_race_changed()`** (lines 182-195):
  - Reads `PlayerData.race_id` and `PlayerData.subrace_id` (lines 187-188)
  - Updates `current_race_id` and `current_subrace_id` (lines 191-192)
  - Calls `_update_preview_race_gender()` (line 193)
  - Rebuilds sliders (line 194)

### 4. Update Preview 3D Model
- **Location**: `scripts/character_creation/tabs/AppearanceTab.gd`
- **Function**: `_update_preview_race_gender()` (lines 252-268)
- **Action**:
  - Checks if `preview` exists and has `set_race` method (line 254)
  - Converts `current_race_id` to lowercase (line 258)
  - Gets gender from PlayerData (lines 261-263)
  - Calls `preview.set_race(preview_race)` (line 265)
  - Calls `preview.set_gender(preview_gender)` (line 266)

### 5. CharacterPreview3D Loads Model
- **Location**: `scripts/character_preview/CharacterPreview3D.gd`
- **Function**: `set_race()` (lines 306-351)
- **Action**:
  - Normalizes race_id to lowercase (line 308)
  - Skips if already showing this race (line 309-310)
  - Cleans up old model (lines 315-316)
  - Builds model path: `res://assets/models/character_bases/{race}-body-{gender}-modified.glb` (line 323)
  - Loads and instantiates new model (lines 326-335)
  - Updates skeleton references (line 341)
  - Plays idle animation if available (lines 344-346)

## Potential Issues Identified

### Issue 1: Timing - AppearanceTab Not Loaded Yet
**Problem**: When a race is selected in RaceTab, AppearanceTab might not be loaded yet (it's only loaded when user navigates to it).

**Current Mitigation**: 
- `CharacterCreationRoot._on_player_data_race_changed()` (lines 258-281) tries to update AppearanceTab if it's already loaded
- `AppearanceTab._ready()` (lines 47-50) initializes `current_race_id` from `PlayerData.race_id` when it loads

**Status**: ✅ Should work - AppearanceTab checks PlayerData on load

### Issue 2: Preview Node Type Mismatch
**Problem**: In `AppearanceTab.gd` line 16, `preview` is typed as `SubViewport`, but it's actually a `CharacterPreview3D` instance.

**Impact**: Type system doesn't know `preview` has `set_race()` method, but runtime check `preview.has_method("set_race")` should catch it.

**Status**: ⚠️ Works but type annotation is incorrect

### Issue 3: Race ID Format Conversion
**Problem**: Race IDs in JSON might be PascalCase (e.g., "Human", "Elf"), but model files use lowercase (e.g., "human-body-male-modified.glb").

**Current Handling**: 
- `AppearanceTab._update_preview_race_gender()` converts to lowercase (line 258)
- `CharacterPreview3D.set_race()` also converts to lowercase (line 308)

**Status**: ✅ Should work correctly

### Issue 4: Initial Load Race Check
**Problem**: In `AppearanceTab._ready()`, the preview update is only called if `preview` exists and has `preview_ready` signal (lines 53-57).

**Potential Issue**: If preview is null or signal doesn't exist, `_update_preview_race_gender()` won't be called initially.

**Status**: ⚠️ Needs verification - preview should exist as it's a @onready var

## Recommended Fixes

### Fix 1: Ensure Preview Update on Initial Load
Add explicit check and update in `AppearanceTab._ready()`:

```gdscript
# After setting current_race_id from PlayerData (line 50)
if current_race_id != "":
    # Wait for preview to be ready
    await get_tree().process_frame
    _update_preview_race_gender()
```

### Fix 2: Fix Type Annotation
Change line 16 in `AppearanceTab.gd`:
```gdscript
@onready var preview: CharacterPreview3D = $MainSplit/PreviewPanel/SubViewportContainer/CharacterPreview3D
```

### Fix 3: Add Logging
Add more debug logging to trace the flow:
- Log when `_on_race_changed()` is called
- Log when `_update_preview_race_gender()` is called
- Log the race_id being passed to `set_race()`
- Log when model is successfully loaded

## Testing Checklist

- [ ] Select a race in RaceTab - verify PlayerData.race_id is updated
- [ ] Navigate to AppearanceTab - verify preview shows selected race model
- [ ] Select different race in RaceTab - verify preview updates (if AppearanceTab is already loaded)
- [ ] Check console logs for race selection events
- [ ] Verify model files exist for selected race
- [ ] Test with races that have subraces
- [ ] Test with races that don't have subraces










