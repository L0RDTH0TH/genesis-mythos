# Tab Completed Signal Migration Fix

## Problem Identified

The RaceTab's `tab_completed` signal was connected to a legacy handler `_on_race_tab_completed()` that bypassed the animated transition flow. This caused instant tab switching without the fade animations.

## Solution Implemented

**File:** `scripts/character_creation/CharacterCreationRoot.gd`

**Changes:**
1. **Removed legacy handler:** Completely removed `_on_race_tab_completed()` function
2. **Direct connection:** Changed RaceTab's `tab_completed` signal to connect directly to `TabNavigation.enable_next_tab()`
3. **Added duplicate check:** Prevents multiple signal connections with `is_connected()` check

**Before:**
```gdscript
if current_tab_instance.has_signal("tab_completed"):
    current_tab_instance.tab_completed.connect(_on_race_tab_completed)

func _on_race_tab_completed() -> void:
    tab_navigation.enable_next_tab()  # Indirect call
```

**After:**
```gdscript
if current_tab_instance.has_signal("tab_completed"):
    if not current_tab_instance.tab_completed.is_connected(tab_navigation.enable_next_tab):
        current_tab_instance.tab_completed.connect(tab_navigation.enable_next_tab)
        Logger.debug("Connected RaceTab.tab_completed to TabNavigation.enable_next_tab", "character_creation")
```

## Signal Flow (Fixed)

1. **RaceTab emits:** `tab_completed.emit()`
2. **Direct connection:** → `TabNavigation.enable_next_tab()`
3. **TabNavigation emits:** `tab_changed.emit("Class")`
4. **CharacterCreationRoot receives:** `_on_tab_changed("Class")`
5. **Animated transition:** `await _load_tab("Class")` with fade animations

## Debug Logging Added

**File:** `scripts/character_creation/tabs/TabNavigation.gd`

Added debug logs in `enable_next_tab()`:
- Line: "enable_next_tab() called from tab_completed signal"
- Line: "About to emit tab_changed signal for: [tab_name]"
- Line: "TabNavigation: Auto-advanced to next tab: [tab_name]"

## Expected Log Sequence (After Fix)

When race is confirmed:
1. `[INFO] RaceTab: Subrace confirmed - advancing to next tab`
2. `[DEBUG] enable_next_tab() called from tab_completed signal`
3. `[DEBUG] About to emit tab_changed signal for: Class`
4. `[DEBUG] TabNavigation: Auto-advanced to next tab: Class`
5. `[DEBUG] Tab changed to: Class`
6. `[DEBUG] Loading tab scene: Class`
7. `[DEBUG] Starting fade-out for old tab: RaceTab`
8. `[DEBUG] Fade-out complete for old tab`
9. `[DEBUG] New tab created with alpha 0.0: ClassTab`
10. `[DEBUG] Fade-in complete for new tab`
11. `[DEBUG] Tab transition complete: Class`

## Files Modified

1. `scripts/character_creation/CharacterCreationRoot.gd`
   - Removed `_on_race_tab_completed()` function
   - Changed signal connection to direct path
   - Added duplicate connection check

2. `scripts/character_creation/tabs/TabNavigation.gd`
   - Added debug logging in `enable_next_tab()`

## Testing Checklist

- [ ] Confirm race selection
- [ ] Verify "enable_next_tab() called from tab_completed signal" log appears
- [ ] Verify "Tab changed to: Class" log appears
- [ ] Verify "Loading tab scene: Class" log appears
- [ ] Verify fade animation logs appear
- [ ] Verify visual fade animation works (~0.3 seconds)
- [ ] Test with race that has subraces
- [ ] Test with race without subraces

