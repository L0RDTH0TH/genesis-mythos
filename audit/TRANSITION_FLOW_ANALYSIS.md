# Race→Class Transition Flow - Detailed Analysis

## Answers to All 15 Questions

---

### 1. Exact Code Executed When User Presses "Confirm" on Subrace/Race

**Function Call Chain:**

1. **User clicks Confirm button** → Signal connection in `RaceTab.tscn` line 139:
   ```
   [connection signal="pressed" from="MainPanel/ConfirmRaceButton" to="." method="_on_confirm_button_pressed"]
   ```

2. **RaceTab._on_confirm_button_pressed()** (line 241-246):
   ```gdscript
   func _on_confirm_button_pressed() -> void:
       if current_mode == MODE_RACE:
           _confirm_race()
       elif current_mode == MODE_SUBRACE:
           _confirm_subrace()
   ```

3. **For Subrace:** `_confirm_subrace()` (lines 286-298):
   - Checks if `selected_subrace.is_empty()` → returns if empty
   - Checks if `pending_race.is_empty()` → returns if empty
   - Calls `_store_race_data(pending_race, selected_subrace)` (line 296)
   - **Emits signal:** `tab_completed.emit()` (line 297)
   - Logs: "Subrace confirmed - advancing to next tab"

4. **For Race (no subrace):** `_confirm_race()` (lines 248-284):
   - Checks if `selected_race.is_empty()` → returns if empty
   - Finds race data in `GameData.races`
   - Checks if race has subraces:
     - **If HAS subraces:** Switches to subrace mode, repopulates, does NOT emit `tab_completed`
     - **If NO subraces:** Calls `_store_race_data(race_data, "")` → emits `tab_completed.emit()` (line 283)

**Conditions checked:**
- `selected_race.is_empty()` or `selected_subrace.is_empty()` (depending on mode)
- Race data exists in `GameData.races`
- For subrace: `pending_race.is_empty()`
- Race has subraces (determines if it advances or switches mode)

---

### 2. Signal Connection Chain to Tab Switching

**RaceTab does NOT directly call `_load_tab()`**. Flow goes through TabNavigation:

**Signal Chain:**

1. **RaceTab emits `tab_completed`** (line 283 or 297)
2. **CharacterCreationRoot._on_race_tab_completed()** receives it (line 174-183):
   - Connected in `_on_tab_changed()` when RaceTab loads (lines 94-95)
   - Calls: `tab_navigation.enable_next_tab()` (line 181)

3. **TabNavigation.enable_next_tab()** (lines 93-110):
   - Calculates next tab index
   - Validates race selection (if advancing to Class)
   - Calls `_select_tab(next_tab)` (line 108)
   - **Emits signal:** `tab_changed.emit(next_tab)` (line 109)

4. **CharacterCreationRoot._on_tab_changed()** receives it (line 76-121):
   - Connected in `_ready()` line 62-63:
     ```gdscript
     if not tab_navigation.tab_changed.is_connected(_on_tab_changed):
         tab_navigation.tab_changed.connect(_on_tab_changed)
     ```
   - Validates race selection (line 80-85)
   - **Calls:** `await _load_tab(tab_name)` (line 88)
   - Connects tab signals after load completes

**Answer:** Goes through TabNavigation via `tab_changed` signal, NOT direct call.

---

### 3. Async Status of _load_tab() and Await

**YES, `_load_tab()` is async** (uses `await` internally) and **IS awaited** in caller:

**Code:**

```gdscript
# CharacterCreationRoot._on_tab_changed() line 88:
await _load_tab(tab_name)
```

**However, there's an issue:** `_on_tab_changed()` is NOT marked as `async`, so the `await` will work but the function continues synchronously after starting the async operation.

**`_load_tab()` signature** (line 123):
```gdscript
func _load_tab(tab_name: String) -> void:
```

**Inside `_load_tab()`:**
- Uses `await tween.finished` (line 132)
- Uses `await fade_in_tween.finished` (line 161)

**Current state:** `_load_tab()` IS async (uses await), and IS awaited in `_on_tab_changed()`, but `_on_tab_changed()` itself should be async to properly wait.

---

### 4. Conditions Checked Before Fade-Out Tween

**Condition checked:** `if current_tab_instance:` (line 127)

**Code:**
```gdscript
# Line 127-137
if current_tab_instance:
    var old_tab: Node = current_tab_instance
    var tween := create_tween()
    tween.set_parallel(false)
    tween.tween_property(old_tab, "modulate:a", 0.0, 0.15)
    await tween.finished
    
    if is_instance_valid(content_area) and is_instance_valid(old_tab) and old_tab.is_inside_tree():
        content_area.remove_child(old_tab)
    if is_instance_valid(old_tab):
        old_tab.queue_free()
```

**Debug logs:**
- Line 124: `Logger.debug("Loading tab scene: %s" % tab_name, "character_creation")`
- Line 163: `Logger.debug("Tab transition complete: %s" % tab_name, "character_creation")`

**Missing:** No specific log inside the fade-out block to confirm it enters. Should add:
```gdscript
Logger.debug("Starting fade-out for old tab", "character_creation")
```

**Answer:** Checks `if current_tab_instance:` before fade-out. No debug print inside the block currently.

---

### 5. Fade-Out Tween Details

**Tween creation** (lines 129-131):
```gdscript
var tween := create_tween()
tween.set_parallel(false)
tween.tween_property(old_tab, "modulate:a", 0.0, 0.15)
```

**Properties:**
- **Property tweened:** `"modulate:a"` (alpha channel of modulate property)
- **Target node:** `old_tab` (which is `current_tab_instance` cast to Node)
- **Start value:** Current alpha (1.0, assumed)
- **End value:** `0.0`
- **Duration:** `0.15` seconds
- **Parallel mode:** `false` (sequential)

**Node type:** `old_tab` is of type `Node` (line 128), but `current_tab_instance` is declared as `var current_tab_instance: Node = null` (line 30). The actual instance is a Control (RaceTab/ClassTab extends Control).

**Answer:** Tweening `modulate:a` on `old_tab` (the current_tab_instance), from 1.0→0.0 over 0.15s, parallel=false.

---

### 6. Await After Fade-Out and Removal

**YES, there is `await tween.finished`** (line 132), and removal happens after:

**Code:**
```gdscript
await tween.finished  # Line 132

if is_instance_valid(content_area) and is_instance_valid(old_tab) and old_tab.is_inside_tree():
    content_area.remove_child(old_tab)  # Line 135
if is_instance_valid(old_tab):
    old_tab.queue_free()  # Line 137
```

**Validation checks:**
- Checks `is_instance_valid(content_area)`
- Checks `is_instance_valid(old_tab)`
- Checks `old_tab.is_inside_tree()`

**Missing debug print:** No log after removal to confirm it happened. Should add:
```gdscript
Logger.debug("Old tab removed and queued for deletion", "character_creation")
```

**Answer:** YES, awaits tween.finished, then removes old tab with validation checks. No debug print after removal.

---

### 7. New Tab Addition and Initial Alpha

**YES, alpha is set to 0.0 BEFORE adding to scene tree:**

**Code (lines 146-155):**
```gdscript
current_tab_instance = scene.instantiate()
if not current_tab_instance:
    Logger.error("Failed to instantiate scene: %s" % path, "character_creation")
    return

# Set initial alpha to 0 for fade-in
current_tab_instance.modulate.a = 0.0  # Line 152

# Add to scene tree
content_area.add_child(current_tab_instance)  # Line 155
```

**Parent:** `content_area` which is:
```gdscript
@onready var content_area: Control = $MainHBox/MarginContainer2/center_area/MarginContainer3/CurrentTabContainer
```

**Answer:** YES, `modulate.a = 0.0` set on line 152, then added to `content_area` (CurrentTabContainer) on line 155.

---

### 8. Fade-In Tween Details

**Fade-in tween** (lines 158-161):
```gdscript
var fade_in_tween := create_tween()
fade_in_tween.set_parallel(false)
fade_in_tween.tween_property(current_tab_instance, "modulate:a", 1.0, 0.15)
await fade_in_tween.finished
```

**Properties:**
- **Property:** `"modulate:a"`
- **Target node:** `current_tab_instance` (the newly added tab)
- **Start value:** 0.0 (set on line 152)
- **End value:** 1.0
- **Duration:** 0.15 seconds
- **Parallel:** false

**Skip condition:** Fade-in ALWAYS runs for new tabs. Only fade-out is conditional (if `current_tab_instance` exists).

**Initial load:** For the very first tab load (RaceTab in `_ready()`), there's no `current_tab_instance`, so:
- Fade-out block is skipped (line 127 check fails)
- New tab is instantiated with alpha 0.0
- Fade-in runs normally

**Answer:** Tweening `modulate:a` on `current_tab_instance` from 0.0→1.0 over 0.15s. No skip condition - always runs for new tabs.

---

### 9. Debug Output and Errors

**Need to check runtime:** Use `get_debug_output` after `run_project` to see actual errors.

**Potential issues:**
- If `modulate` property doesn't exist on the node type
- If Tween creation fails
- If node is removed before tween completes

**Check:** Run project and capture debug output.

---

### 10. Node Type and Modulate Property

**Node type declaration:**
```gdscript
var current_tab_instance: Node = null  # Line 30
```

**Actual node types:**
- RaceTab extends `Control` (line 6 of RaceTab.gd)
- ClassTab extends `Control` (line 6 of ClassTab.gd)

**Modulate property:** `Control` nodes (and all CanvasItem nodes) have a `modulate` property in Godot 4.3, so it should be accessible.

**Scene hierarchy:**
- RaceTab (Control) → MainPanel (Panel) → children...
- ClassTab (Control) → MainSplit (HSplitContainer) → children...

**Potential issue:** If a parent node has `modulate.a = 0.0` or theme override, child modulate might not be visible. Need to check scene tree.

**Answer:** Node type is `Control`, which has `modulate` property. Should work, but parent nodes could affect visibility.

---

### 11. Race Without Subrace Path

**For race without subrace** (Human example):

**Path:** `_confirm_race()` → checks `subraces.size() > 0` (line 268) → FALSE → goes to else block (line 280-284):

```gdscript
else:
    # No subraces - store and advance immediately
    _store_race_data(race_data, "")
    tab_completed.emit()  # Line 283
    Logger.info("RaceTab: Race confirmed (no subraces) - advancing to next tab", "character_creation")
```

**Same flow:** Still emits `tab_completed` → same signal chain → same `_load_tab()` with fade animation.

**Answer:** YES, same path. Race without subrace still triggers `tab_completed` → same transition with fade.

---

### 12. TabNavigation Bypass Check

**TabNavigation.enable_next_tab()** (lines 93-110):

```gdscript
func enable_next_tab() -> void:
    var next_idx := TAB_ORDER.find(current_tab) + 1
    if next_idx >= TAB_ORDER.size():
        Logger.debug("TabNavigation: Already at last tab, cannot advance", "character_creation")
        return
    
    var next_tab: String = TAB_ORDER[next_idx]
    
    # Validate prerequisites before advancing
    if next_tab == "Class" and PlayerData.race_id.is_empty():
        Logger.warning("TabNavigation: Cannot advance to Class tab - no race selected", "character_creation")
        return
    
    Logger.log_state_transition(current_tab, next_tab, "character_creation", {"auto_advance": true})
    _select_tab(next_tab)
    tab_changed.emit(next_tab)  # Line 109
    Logger.debug("TabNavigation: Auto-advanced to next tab: %s" % next_tab, "character_creation")
```

**Does NOT bypass:** Only calls `_select_tab()` (updates button states) and emits `tab_changed` signal, which triggers `CharacterCreationRoot._on_tab_changed()` → `_load_tab()`.

**Answer:** NO bypass. TabNavigation only emits signal, actual loading happens in CharacterCreationRoot via signal handler.

---

### 13. Transition Timeout/Hang or Instant

**Need runtime test:** Check if:
- Transition hangs (await issue)
- Transition is instant (fade skipped)
- Transition works smoothly (~0.3 seconds)

**Potential hang causes:**
- `_on_tab_changed()` not async but uses await
- Tween never finishes
- Signal connection issue

**Potential instant causes:**
- Modulate property not working
- Tween creation failing silently
- Old tab removal happens too fast

**Answer:** Need to test. Current code should work but needs verification.

---

### 14. Tween Management and Accumulation

**Current code:** Creates new Tween each time:
- Line 129: `var tween := create_tween()` (fade-out)
- Line 158: `var fade_in_tween := create_tween()` (fade-in)

**Tween cleanup:** Godot automatically cleans up Tweens when the node that created them is removed/freed, BUT:

**Potential issue:** If tab switch happens rapidly (before fade completes), multiple Tweens could run concurrently:
- Old tab fade-out tween still running
- New tab fade-in tween starts
- Old tween might be orphaned if old_tab is freed

**Solution needed:**
- Kill old tween before creating new one
- Check if tween is valid before awaiting
- Use `tween.kill()` if tab switches rapidly

**Answer:** No explicit Tween management. Could accumulate on rapid switches. Should add tween.kill() checks.

---

### 15. Scene Hierarchy and Modulate Accessibility

**Path to tab instances:**
```
CharacterCreationRoot (Control)
└── MainHBox (HBoxContainer)
    └── MarginContainer2
        └── center_area
            └── MarginContainer3
                └── CurrentTabContainer (content_area)  ← tabs added here
                    └── RaceTab (Control) or ClassTab (Control)
```

**Modulate inheritance:** In Godot, child modulate is multiplied by parent modulate. If any parent has `modulate.a = 0`, child will be invisible.

**Check needed:**
- Verify no parent nodes have `modulate.a = 0` or theme override
- Check if `content_area` (CurrentTabContainer) has any modulate restrictions

**Answer:** Need to inspect scene tree to confirm no parent nodes block modulate. Path is `CharacterCreationRoot → MainHBox → MarginContainer2 → center_area → MarginContainer3 → CurrentTabContainer → TabInstance`.

---

## Recommendations for Fixes

1. **Add debug prints** inside fade-out block to confirm it runs
2. **Make `_on_tab_changed()` async** to properly await `_load_tab()`
3. **Add tween cleanup** before creating new tweens (kill existing)
4. **Verify scene hierarchy** - check parent modulate values
5. **Add error handling** for tween creation failures
6. **Test with get_debug_output** to see runtime errors

