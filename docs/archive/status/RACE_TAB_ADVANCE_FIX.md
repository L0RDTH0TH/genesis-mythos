# RaceTab Tab Advancement Fix

## Problem Analysis

After analyzing the game log, the following was identified:

1. **Confirm button fires correctly**: Events logged show `confirm_race` actions occurring
2. **Race data stores correctly**: `Race data stored in PlayerData` appears in logs
3. **Advancement intent logged**: "advancing to next tab" messages appear
4. **Tab transition fails silently**: No logs for "Loading tab scene: Class" or fade transitions

## Root Cause

The signal chain from RaceTab → TabNavigation → CharacterCreationRoot was not reliably connected or logging was insufficient to diagnose connection failures.

## Fixes Applied

### 1. RaceTab.gd Enhancements

**Changes:**
- Added button disable on press to prevent spam clicks
- Added explicit logging before/after `tab_completed.emit()`
- Added connection verification logging to check if signal has receivers
- Enhanced both `_confirm_race()` and `_confirm_subrace()` methods

**Key additions:**
```gdscript
# Disable button immediately
race_confirm_button.disabled = true

# Log connection status before emit
Logger.debug("RaceTab: tab_completed signal has %d connections" % tab_completed.get_connections().size())

# Explicit error if no connections
if tab_completed.get_connections().is_empty():
    Logger.error("RaceTab: tab_completed signal has no connections! Tab advancement will fail.")
```

### 2. CharacterCreationRoot.gd Signal Connection

**Changes:**
- Enhanced signal connection logging for `tab_completed`
- Added duplicate connection check with verbose logging
- Improved `_on_tab_changed()` logging for traceability

**Key additions:**
```gdscript
# Verify connection before connecting
if not current_tab_instance.tab_completed.is_connected(tab_navigation.enable_next_tab):
    current_tab_instance.tab_completed.connect(tab_navigation.enable_next_tab)
    Logger.debug("CharacterCreationRoot: Connected RaceTab.tab_completed to TabNavigation.enable_next_tab")
    Logger.debug("Signal connection verified - %d total connections" % current_tab_instance.tab_completed.get_connections().size())
```

### 3. TabNavigation.gd Enhanced Logging

**Changes:**
- Added comprehensive logging in `enable_next_tab()`
- Added signal connection verification for `tab_changed`
- Added validation logging for tab order and prerequisites

**Key additions:**
```gdscript
# Verify tab_changed has connections
if tab_changed.get_connections().is_empty():
    Logger.error("TabNavigation: tab_changed signal has no connections! Tab transition will fail.")
else:
    Logger.debug("TabNavigation: tab_changed signal has %d connections" % tab_changed.get_connections().size())
```

## Expected Behavior Post-Fix

### Normal Flow (Race with no subraces)
1. User selects race → preview updates
2. User clicks "Confirm Race →" button
3. Button disables immediately (prevents spam)
4. Race data stored in PlayerData
5. `tab_completed.emit()` called with connection count logged
6. TabNavigation.enable_next_tab() receives signal
7. TabNavigation validates and emits `tab_changed("Class")`
8. CharacterCreationRoot receives `tab_changed` and calls `_load_tab("Class")`
9. Fade-out old tab → Load new tab → Fade-in new tab
10. ClassTab appears in center area

### Normal Flow (Race with subraces)
1. User selects race → switches to subrace mode
2. User selects subrace → preview updates
3. User clicks "Confirm Subrace →" button
4. Same flow as above from step 3

## Testing Checklist

- [ ] Select/Confirm Race (no subrace) → Advance log + ClassTab loads/fades in
- [ ] Select Race w/ Subrace → Confirm → Subrace UI → Advance + ClassTab
- [ ] Button disables on confirm → No spam clicks possible
- [ ] Logs show "tab_completed emitted" + "Loading tab scene: Class"
- [ ] Full trace visible in console from RaceTab → TabNavigation → CharacterCreationRoot
- [ ] Visual: Center fades to next tab smoothly

## Files Modified

1. `scripts/character_creation/tabs/RaceTab.gd`
   - Enhanced `_on_confirm_button_pressed()` with button disable
   - Enhanced `_confirm_race()` with logging
   - Enhanced `_confirm_subrace()` with logging

2. `scripts/character_creation/CharacterCreationRoot.gd`
   - Enhanced signal connection logging in `_ready()`
   - Enhanced `_on_tab_changed()` logging
   - Improved RaceTab signal connection verification

3. `scripts/character_creation/tabs/TabNavigation.gd`
   - Enhanced `enable_next_tab()` with comprehensive logging
   - Added signal connection verification

## Next Steps

1. Run project with `run_project`
2. Test race selection and confirmation
3. Monitor console logs for full signal chain trace
4. Verify visual transition occurs
5. If issues persist, logs will now show exact failure point

