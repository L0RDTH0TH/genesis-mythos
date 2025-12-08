# RACE POPULATION CODE BLOCKS - EXACT ANALYSIS

## Overview

This document shows the exact code blocks responsible for:
1. Loading races from JSON
2. Instantiating race entry prefabs
3. Setting text/values for column display
4. Visibility and size flag configurations

---

## 1. LOAD RACES FROM JSON

### 1.1 GameData Singleton - Loads JSON Data

**File:** `scripts/singletons/GameData.gd`  
**Function:** `load_all_data()` and `_load_json_array()`

```19:24:scripts/singletons/GameData.gd
func load_all_data() -> void:
	races = _load_json_array("res://data/races.json")
	classes = _load_json_array("res://data/classes.json")
	backgrounds = _load_json_array("res://data/backgrounds.json")
	abilities = _load_json_dict("res://data/abilities.json")
	appearance_presets = _load_json_dict("res://data/appearance_presets.json")
	voices = _load_json_array("res://data/voices.json")
```

**JSON Loading Function:**
```26:52:scripts/singletons/GameData.gd
func _load_json_array(path: String) -> Array[Dictionary]:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("CRITICAL: CANNOT OPEN FILE %s – Error: %s" % [path, FileAccess.get_open_error()])
		return []
	
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		push_error("CRITICAL: JSON PARSE FAILED %s – Line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return []
	
	if not json.data is Array:
		push_error("CRITICAL: JSON ROOT IS NOT AN ARRAY in %s" % path)
		return []
	
	var result: Array[Dictionary] = []
	for item in json.data:
		if item is Dictionary:
			result.append(item as Dictionary)
		else:
			push_warning("Skipping non-dictionary item in %s" % path)
	Logger.info("Loaded %d entries from %s" % [result.size(), path])
	return result
```

### 1.2 RaceTab - Accesses Loaded Data

**File:** `scripts/character_creation/tabs/RaceTab.gd`  
**Function:** `_ready()` - Checks if data is loaded

```32:34:scripts/character_creation/tabs/RaceTab.gd
	if not GameData.races or GameData.races.is_empty():
		Logger.error("RaceTab: GameData.races is empty! Aborting population.", "character_creation")
		return
```

### 1.3 RaceTab - Collects Race Items from GameData

**File:** `scripts/character_creation/tabs/RaceTab.gd`  
**Function:** `_populate_list()` - Loop that processes loaded race data

```61:67:scripts/character_creation/tabs/RaceTab.gd
	# Collect all race entries (races + subraces)
	var all_race_items: Array = []
	for race in GameData.races:
		all_race_items.append({"type": "race", "data": race})
		if race.has("subraces") and race.get("subraces", []).size() > 0:
			for subrace in race.get("subraces", []):
				all_race_items.append({"type": "subrace", "race_data": race, "subrace_data": subrace})
```

**⚠️ NOTE:** This loop accesses `GameData.races` directly (loaded from JSON in GameData singleton).

---

## 2. INSTANTIATE ROW PREFAB / ADD_CHILD

### 2.1 Preload Scene Reference

**File:** `scripts/character_creation/tabs/RaceTab.gd`  
**Line 18:** Preloads the race entry prefab

```18:18:scripts/character_creation/tabs/RaceTab.gd
var race_entry_scene: PackedScene = preload("res://scenes/character_creation/tabs/components/RaceEntry.tscn")
```

### 2.2 Main Instantiation Loop

**File:** `scripts/character_creation/tabs/RaceTab.gd`  
**Function:** `_populate_list()` - Lines 96-123

```92:123:scripts/character_creation/tabs/RaceTab.gd
	# Distribute entries across three columns (round-robin)
	var column_index: int = 0
	var columns: Array = [column_1, column_2, column_3]
	
	for item in all_race_items:
		var entry := race_entry_scene.instantiate()
		if not entry:
			Logger.error("RaceTab: Failed to instantiate race_entry_scene!", "character_creation")
			continue
		
		var target_column: VBoxContainer = columns[column_index]
		if not target_column:
			Logger.error("RaceTab: Target column is null at index %d!" % column_index, "character_creation")
			continue
		
		target_column.add_child(entry)
		all_entries.append(entry)
		
		Logger.debug("RaceTab: Added entry to column %d, total entries: %d" % [column_index, all_entries.size()], "character_creation")
		
		if item.get("type") == "race":
			if entry.has_method("setup"):
				entry.setup(item.get("data"))
		else:
			if entry.has_method("setup"):
				entry.setup(item.get("race_data"), item.get("subrace_data"))
		
		if entry.has_signal("race_selected"):
			entry.race_selected.connect(_on_race_selected)
		
		# Round-robin to next column
		column_index = (column_index + 1) % 3
```

**Key Operations:**
- **Line 97:** `var entry := race_entry_scene.instantiate()` - Instantiates the prefab
- **Line 107:** `target_column.add_child(entry)` - Adds to column VBoxContainer
- **Line 108:** `all_entries.append(entry)` - Stores reference

---

## 3. SET_TEXT() / ADD_ITEM() CALLS FOR COLUMN VALUES

### 3.1 RaceEntry.setup() - Entry Point for Data Population

**File:** `scripts/character_creation/tabs/components/RaceEntry.gd`

```45:50:scripts/character_creation/tabs/components/RaceEntry.gd
func setup(race: Dictionary, subrace: Dictionary = {}) -> void:
	race_data = race
	subrace_data = subrace
	
	# Update display
	_update_display()
```

### 3.2 RaceEntry._update_display() - Sets Race Name Text

**File:** `scripts/character_creation/tabs/components/RaceEntry.gd`

```52:66:scripts/character_creation/tabs/components/RaceEntry.gd
func _update_display() -> void:
	if not is_inside_tree():
		call_deferred("_update_display")
		return
	
	var display_name: String = subrace_data.get("name", race_data.get("name", "")) if !subrace_data.is_empty() else race_data.get("name", "")
	
	if race_name_label:
		race_name_label.text = display_name
	
	# Build ability preview text
	_build_ability_preview()
	
	# Set icon placeholder (ColorRect for now)
	_setup_icon()
```

**Key Text Setting:**
- **Line 60:** `race_name_label.text = display_name` - Sets race/subrace name

### 3.3 RaceEntry._build_ability_preview() - Sets Ability Scores Text

**File:** `scripts/character_creation/tabs/components/RaceEntry.gd`

```68:95:scripts/character_creation/tabs/components/RaceEntry.gd
func _build_ability_preview() -> void:
	if not ability_preview_label:
		return
	
	var bonuses: Dictionary = race_data.get("ability_bonuses", {}).duplicate()
	if subrace_data.has("ability_bonuses"):
		for key in subrace_data.ability_bonuses:
			bonuses[key] = bonuses.get(key, 0) + subrace_data.ability_bonuses[key]
	
	# Handle "all" bonus
	if bonuses.has("all"):
		var all_bonus: int = bonuses["all"]
		bonuses.erase("all")
		for abil_key in GameData.abilities.keys():
			bonuses[abil_key] = bonuses.get(abil_key, 0) + all_bonus
	
	var mods := ""
	for stat in ["STR", "DEX", "CON", "INT", "WIS", "CHA"]:
		var abil_key: String = ABILITY_MAP[stat]
		var val: int = bonuses.get(abil_key, 0)
		if val > 0:
			mods += "[color=lime]+%d %s [/color]" % [val, stat]
		elif val < 0:
			mods += "[color=red]%d %s [/color]" % [val, stat]
		else:
			mods += "%s " % stat
	
	ability_preview_label.text = "[center]%s[/center]" % mods
```

**Key Text Setting:**
- **Line 95:** `ability_preview_label.text = "[center]%s[/center]" % mods` - Sets ability scores with BBCode formatting

---

## 4. VISIBILITY AND SIZE FLAGS ANALYSIS

### 4.1 ✅ Size Flags SET on Columns Container

**File:** `scripts/character_creation/tabs/RaceTab.gd`  
**Lines 73-79:**

```73:79:scripts/character_creation/tabs/RaceTab.gd
	# Ensure columns container is properly configured
	if columns_container:
		# Ensure ColumnsContainer fills the ScrollContainer width
		columns_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		columns_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		# Ensure it's visible
		columns_container.visible = true
```

**✅ Size flags are SET** - Lines 76-77  
**✅ Visible is SET to true** - Line 79

### 4.2 ✅ Size Flags SET on Column VBoxContainers

**File:** `scripts/character_creation/tabs/RaceTab.gd`  
**Lines 81-87:**

```81:87:scripts/character_creation/tabs/RaceTab.gd
	# Ensure all three columns have equal expansion
	for content in [column_1, column_2, column_3]:
		if not content:
			continue
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content.visible = true
```

**✅ Size flags are SET** - Lines 85-86  
**✅ Visible is SET to true** - Line 87

### 4.3 ⚠️ Size Flags SET AGAIN (Redundant)

**File:** `scripts/character_creation/tabs/RaceTab.gd`  
**Lines 128-135:**

```128:135:scripts/character_creation/tabs/RaceTab.gd
	# Update column content to allow full expansion
	for content in [column_1, column_2, column_3]:
		if not content:
			continue
		
		# Ensure size flags are set
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.size_flags_vertical = Control.SIZE_EXPAND_FILL
```

**⚠️ Redundant** - Size flags are set twice (lines 85-86 and 134-135)

### 4.4 ⚠️ MISSING Size Flags on Instantiated RaceEntry Nodes

**File:** `scripts/character_creation/tabs/RaceTab.gd`  
**Lines 96-107:**

```96:107:scripts/character_creation/tabs/RaceTab.gd
	for item in all_race_items:
		var entry := race_entry_scene.instantiate()
		if not entry:
			Logger.error("RaceTab: Failed to instantiate race_entry_scene!", "character_creation")
			continue
		
		var target_column: VBoxContainer = columns[column_index]
		if not target_column:
			Logger.error("RaceTab: Target column is null at index %d!" % column_index, "character_creation")
			continue
		
		target_column.add_child(entry)
```

**⚠️ PROBLEM:** After `add_child(entry)` on line 107, there is **NO code that sets size flags on the instantiated entry node**.

**RaceEntry.tscn** has these size flags in the scene file:
- `size_flags_horizontal = 3` (EXPAND_FILL)
- `size_flags_vertical = 0` (SHRINK_CENTER)

But they are set in the scene file, not in code after instantiation. If the scene file values are correct, this may not be an issue, but it's worth noting.

### 4.5 ✅ No `visible = false` Found

**Search Result:** No explicit `visible = false` is set anywhere in the race population code.

### 4.6 ✅ No `modulate.a = 0` Found

**Search Result:** No `modulate.a = 0` (transparency) is set anywhere in the race population code.

### 4.7 ⚠️ Debug Labels Added (May Cause Issues)

**File:** `scripts/character_creation/tabs/RaceTab.gd`  
**Lines 44-50:**

```44:50:scripts/character_creation/tabs/RaceTab.gd
	# Temporary debug – make columns visible even when empty
	for col in [column_1, column_2, column_3]:
		col.add_theme_constant_override("separation", 16)
		var debug_label := Label.new()
		debug_label.text = "COLUMN READY"
		debug_label.add_theme_color_override("font_color", Color.GREEN_YELLOW)
		col.add_child(debug_label)
```

**⚠️ WARNING:** Debug labels are added but **NEVER REMOVED** before entries are added. These debug labels will appear in the final UI unless removed.

**Also:** Debug labels are added AFTER the "Clear existing entries" loop (lines 53-58), but they are added BEFORE the actual race entries. This means:
1. Debug labels are added to empty columns
2. Then cleared in lines 53-58? No, wait - debug labels are added AFTER the clear, so they won't be cleared.
3. Then race entries are added, but debug labels remain.

**🔴 CRITICAL:** Debug labels should be removed or this code block should be removed/commented out.

---

## 5. SUMMARY OF ISSUES

### ✅ What's Working:
1. Size flags are set on `columns_container` (HBoxContainer)
2. Size flags are set on all three column VBoxContainers
3. Visible is explicitly set to `true` on containers
4. No `visible = false` or `modulate.a = 0` causing hidden elements

### ⚠️ Potential Issues:
1. **Debug labels are added and never removed** (lines 44-50)
2. **Redundant size flag setting** (set twice on same nodes)
3. **No explicit size flag verification on instantiated entries** (relies on scene file defaults)

### 🔴 Critical Issues:
1. **Debug labels will appear in production UI** unless code at lines 44-50 is removed/commented out

---

## 6. COMPLETE CODE FLOW

```
1. GameData._ready() 
   └──> load_all_data()
        └──> _load_json_array("res://data/races.json")
             └──> Returns Array[Dictionary] to GameData.races

2. RaceTab._ready()
   └──> Check GameData.races not empty (line 32)
   └──> _populate_list()

3. RaceTab._populate_list()
   └──> Loop through GameData.races (lines 63-67)
        └──> Collect races + subraces into all_race_items
   └──> Set size flags on columns_container (lines 76-77)
   └──> Set size flags on columns (lines 85-86)
   └──> Loop through all_race_items (lines 96-123)
        └──> Instantiate RaceEntry.tscn (line 97)
        └──> Add to column VBoxContainer (line 107)
        └──> Call entry.setup() with race data (lines 114 or 117)
             └──> RaceEntry.setup()
                  └──> RaceEntry._update_display()
                       └──> Set race_name_label.text (line 60)
                       └──> RaceEntry._build_ability_preview()
                            └──> Set ability_preview_label.text (line 95)
```

---

**Report Generated:** Complete analysis of race population code blocks with visibility and size flag highlights

