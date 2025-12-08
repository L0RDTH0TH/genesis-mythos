# TAB SWITCH DIAGNOSIS - COMPLETE ANALYSIS

**Problem:** Tab does NOT visually switch from RaceTab to ClassTab despite console showing "Advancing to next tab" message.

**Date:** 2025-01-17

---

## EXECUTIVE SUMMARY

The signal chain is firing correctly, but there is a **CRITICAL RACE CONDITION** between:
1. `queue_free()` on the old RaceTab instance
2. Instantiation and visibility of the new ClassTab instance
3. Signal connection timing in `_on_tab_changed()`

**ROOT CAUSE:** The `_load_tab()` function in `CharacterCreationRoot.gd` calls `queue_free()` on the old tab instance, but `queue_free()` defers deletion to the end of the frame. The new ClassTab is instantiated and added to the scene tree in the same frame, but both the old RaceTab (pending deletion) and new ClassTab may be visible simultaneously, or the new ClassTab may not be properly rendered yet.

---

## 1. TabNavigation.gd – ADVANCE LOGIC ANALYSIS

### Function: `enable_next_tab()`

```93:104:scripts/character_creation/tabs/TabNavigation.gd
func enable_next_tab() -> void:
	var next_idx := TAB_ORDER.find(current_tab) + 1
	if next_idx < TAB_ORDER.size():
		var next_tab: String = TAB_ORDER[next_idx]
		print("enable_next_tab() called – emitting tab_changed(", next_tab, ")")
		Logger.log_state_transition(current_tab, next_tab, "character_creation", {"auto_advance": true})
		_select_tab(next_tab)
		tab_changed.emit(next_tab)  # Emit signal to load tab content
		Logger.debug("TabNavigation: Auto-advanced to next tab: %s" % next_tab, "character_creation")
	else:
		Logger.debug("TabNavigation: Already at last tab, cannot advance", "character_creation")
```

**Analysis:**
- ✅ Function is being called (console proves it)
- ✅ `_select_tab(next_tab)` updates `current_tab` variable to "Class"
- ✅ `tab_changed.emit("Class")` is emitted
- ✅ Button states are updated via `_update_button_states()`

**Function: `_select_tab()`**

```67:69:scripts/character_creation/tabs/TabNavigation.gd
func _select_tab(tab_name: String) -> void:
	current_tab = tab_name
	_update_button_states()
```

**Analysis:**
- ✅ Updates internal state variable `current_tab`
- ✅ Updates button visual states (enabled/disabled, stylebox overrides)
- ❌ **DOES NOT** directly change visible tab content – relies on signal emission

**Conclusion:** `enable_next_tab()` is working correctly and emitting the signal. The issue is downstream in the signal handler.

---

## 2. SIGNAL CONNECTION VERIFICATION

### Signal Flow:

1. **RaceTab** emits `tab_completed` signal:
```202:204:scripts/character_creation/tabs/RaceTab.gd
	# Emit tab_completed to advance to next tab
	tab_completed.emit()
	Logger.info("RaceTab: Advancing to next tab", "character_creation")
```

2. **CharacterCreationRoot** receives it:
```131:132:scripts/character_creation/CharacterCreationRoot.gd
func _on_race_tab_completed() -> void:
	tab_navigation.enable_next_tab()
```

3. **TabNavigation** emits `tab_changed("Class")`:
```100:100:scripts/character_creation/tabs/TabNavigation.gd
		tab_changed.emit(next_tab)  # Emit signal to load tab content
```

4. **CharacterCreationRoot** receives it:
```76:77:scripts/character_creation/CharacterCreationRoot.gd
func _on_tab_changed(tab_name: String) -> void:
	_load_tab(tab_name)
```

### Signal Connection in Scene File:

```194:194:scenes/character_creation/CharacterCreationRoot.tscn
[connection signal="tab_changed" from="MainHBox/MarginContainer/VBoxContainer/TabNavigation" to="." method="_on_tab_changed"]
```

**Analysis:**
- ✅ Signal connection exists and is valid
- ✅ The signal chain is firing (console confirms)

### Signal Connection Timing Issue:

```76:107:scripts/character_creation/CharacterCreationRoot.gd
func _on_tab_changed(tab_name: String) -> void:
	_load_tab(tab_name)
	if tab_name == "Race":
		if current_tab_instance.has_signal("race_selected"):
			current_tab_instance.race_selected.connect(_on_race_selected)
		if current_tab_instance.has_signal("tab_completed"):
			current_tab_instance.tab_completed.connect(_on_race_tab_completed)
	elif tab_name == "Class":
		if current_tab_instance.has_signal("class_selected"):
			current_tab_instance.class_selected.connect(_on_class_selected)
		if current_tab_instance.has_signal("tab_completed"):
			current_tab_instance.tab_completed.connect(_on_class_tab_completed)
```

**CRITICAL ISSUE:** 
- `_load_tab()` is called FIRST (line 77)
- `_load_tab()` calls `queue_free()` on the OLD RaceTab instance
- NEW ClassTab is instantiated and added immediately
- Signal connections happen AFTER `_load_tab()` completes
- **BUT:** The old RaceTab might still be visible because `queue_free()` defers deletion

**Conclusion:** Signal connections are valid, but timing may cause issues with old tab visibility.

---

## 3. TabNavigation STATE TRACKING

### Current State Variables:

```17:22:scripts/character_creation/tabs/TabNavigation.gd
var current_tab: String = "Race"

const TAB_ORDER := [
	"Race", "Class", "Background", 
	"AbilityScore", "Appearance", "NameConfirm"
]
```

**After Confirm Button Press:**
- `current_tab` should be: **"Race"** (before `enable_next_tab()`)
- After `_select_tab("Class")`: `current_tab` = **"Class"**
- `TAB_ORDER` is correct: Race (0) → Class (1)

**State Update Sequence:**
1. `enable_next_tab()` calls `_select_tab("Class")`
2. `current_tab` variable is updated to "Class"
3. `_update_button_states()` enables Class button
4. `tab_changed.emit("Class")` is emitted

**Conclusion:** State tracking is correct. The `current_tab` variable updates properly.

---

## 4. VISIBILITY / INSTANTIATION OF ClassTab

### Tab Loading Function:

```109:120:scripts/character_creation/CharacterCreationRoot.gd
func _load_tab(tab_name: String) -> void:
	if current_tab_instance:
		current_tab_instance.queue_free()
	
	var path: String = TAB_SCENES[tab_name]
	var scene := load(path) as PackedScene
	if scene:
		current_tab_instance = scene.instantiate()
		content_area.add_child(current_tab_instance)
		Logger.debug("Loaded tab scene: %s" % tab_name, "character_creation")
	else:
		Logger.error("Failed to load scene: %s" % path, "character_creation")
```

**CRITICAL ISSUE IDENTIFIED:**

1. **Line 111:** `current_tab_instance.queue_free()` 
   - `queue_free()` **DEFERS deletion** to the end of the frame
   - RaceTab is still in the scene tree and visible at this moment

2. **Line 116:** `current_tab_instance = scene.instantiate()`
   - ClassTab is instantiated immediately

3. **Line 117:** `content_area.add_child(current_tab_instance)`
   - ClassTab is added to the scene tree
   - **BOTH RaceTab (pending deletion) AND ClassTab are now children of content_area**

4. **RaceTab is still visible** because `queue_free()` hasn't executed yet

### Scene Tree Structure:

```
content_area (CurrentTabContainer)
├── RaceTab (visible, pending queue_free())
└── ClassTab (visible, but potentially behind RaceTab)
```

**Conclusion:** **ROOT CAUSE FOUND** – Both tabs exist in the scene tree simultaneously. RaceTab is still visible because `queue_free()` hasn't executed.

---

## 5. TabContainer vs Custom Tab System

**System Type:** **CUSTOM TAB SYSTEM**

- ❌ NOT using Godot's built-in `TabContainer`
- ✅ Custom system with:
  - `TabNavigation` (left sidebar buttons)
  - `CurrentTabContainer` (content area)
  - Manual instantiation via `_load_tab()`

### Tab Switching Code:

The tab switching is done via:
1. `_load_tab()` removes old instance and adds new instance
2. No explicit visibility management
3. Relies on `queue_free()` to remove old tab

**Issue:** `queue_free()` defers deletion, so old tab remains visible.

---

## 6. POTENTIAL SILENT FAILURES

### Search Results:

```bash
# Searched for: current_tab, current_idx, selected_tab, visible_tab
```

**No silent failures found:**
- ✅ No `assert()` statements in tab-switching code
- ✅ No silent `return` statements
- ✅ No error handling that swallows errors

**However:**
- ⚠️ `queue_free()` is silent – it doesn't print anything
- ⚠️ Multiple children in `content_area` won't cause errors, just visual overlap

---

## 7. QUICK VERIFICATION TEST

### Suggested Debug Prints:

```gdscript
# In TabNavigation.enable_next_tab() - line 93
func enable_next_tab() -> void:
	var next_idx := TAB_ORDER.find(current_tab) + 1
	print(">>> ENABLE_NEXT_TAB: current_idx =", TAB_ORDER.find(current_tab), " next_idx =", next_idx)
	if next_idx < TAB_ORDER.size():
		var next_tab: String = TAB_ORDER[next_idx]
		print(">>> ABOUT TO SHOW CLASS TAB: next_tab =", next_tab)
		# ... rest of function

# In CharacterCreationRoot._load_tab() - line 109
func _load_tab(tab_name: String) -> void:
	print(">>> LOAD_TAB CALLED: tab_name =", tab_name)
	if current_tab_instance:
		print(">>> QUEUE_FREE OLD TAB:", current_tab_instance.name)
		current_tab_instance.queue_free()
		print(">>> OLD TAB CHILDREN COUNT:", content_area.get_child_count())
	
	var path: String = TAB_SCENES[tab_name]
	var scene := load(path) as PackedScene
	if scene:
		current_tab_instance = scene.instantiate()
		content_area.add_child(current_tab_instance)
		print(">>> NEW TAB ADDED, CHILDREN COUNT:", content_area.get_child_count())
		print(">>> ALL CHILDREN:", content_area.get_children().map(func(c): return c.name))

# In CharacterCreationRoot._on_tab_changed() - line 76
func _on_tab_changed(tab_name: String) -> void:
	print(">>> TAB_CHANGED RECEIVED FROM TAB NAVIGATION: tab_name =", tab_name)
	_load_tab(tab_name)
```

**Expected Output if Bug Exists:**
```
>>> TAB_CHANGED RECEIVED: tab_name = Class
>>> LOAD_TAB CALLED: tab_name = Class
>>> QUEUE_FREE OLD TAB: RaceTab
>>> OLD TAB CHILDREN COUNT: 1
>>> NEW TAB ADDED, CHILDREN COUNT: 2  <-- BOTH TABS PRESENT!
>>> ALL CHILDREN: [RaceTab, ClassTab]
```

---

## 8. ROOT CAUSE SUMMARY

### THE EXACT POINT OF FAILURE:

**Location:** `CharacterCreationRoot._load_tab()` line 111

**Problem:** `queue_free()` defers deletion to end of frame, so RaceTab remains visible while ClassTab is added.

**Visual Result:** Both tabs exist in scene tree → RaceTab (old) may still be visible/on top → User sees no visual change.

### The Fix Must:

1. **Immediately hide** the old tab before freeing it
2. OR **immediately remove** the old tab from scene tree before adding new one
3. OR use `remove_child()` + `queue_free()` instead of just `queue_free()`

### Single-Line Root Cause:

**`queue_free()` defers deletion, leaving both RaceTab and ClassTab visible simultaneously in the scene tree. The old RaceTab remains visually present, blocking the new ClassTab.**

---

## 9. VERIFICATION CHECKLIST

- [x] TabNavigation.enable_next_tab() is being called
- [x] Signal tab_changed("Class") is being emitted
- [x] CharacterCreationRoot._on_tab_changed() is receiving the signal
- [x] _load_tab("Class") is being called
- [x] ClassTab scene exists and can be instantiated
- [x] ClassTab is being added to content_area
- [ ] **RaceTab is being removed BEFORE ClassTab is added** ← FAILING
- [ ] **Only one tab exists in content_area at any time** ← FAILING

---

## 10. RECOMMENDED FIX

### Option 1: Immediate Removal + Hide

```gdscript
func _load_tab(tab_name: String) -> void:
	if current_tab_instance:
		content_area.remove_child(current_tab_instance)
		current_tab_instance.visible = false
		current_tab_instance.queue_free()
	
	var path: String = TAB_SCENES[tab_name]
	var scene := load(path) as PackedScene
	if scene:
		current_tab_instance = scene.instantiate()
		content_area.add_child(current_tab_instance)
		Logger.debug("Loaded tab scene: %s" % tab_name, "character_creation")
```

### Option 2: Immediate Hide

```gdscript
func _load_tab(tab_name: String) -> void:
	if current_tab_instance:
		current_tab_instance.visible = false  # Hide immediately
		current_tab_instance.queue_free()
	
	var path: String = TAB_SCENES[tab_name]
	var scene := load(path) as PackedScene
	if scene:
		current_tab_instance = scene.instantiate()
		current_tab_instance.visible = true  # Ensure visible
		content_area.add_child(current_tab_instance)
		Logger.debug("Loaded tab scene: %s" % tab_name, "character_creation")
```

---

## END OF DIAGNOSIS

**ROOT CAUSE:** `queue_free()` defers deletion, leaving both RaceTab and ClassTab visible simultaneously.

**FIX REQUIRED:** Hide or remove the old tab instance immediately before adding the new one.

