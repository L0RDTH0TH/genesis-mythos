# Character Creation UI Instantiation Report

## 1. Search Results for Character Creation Related Strings

### Files containing "character_creation", "CharCreation", "TabContainer", "create_tabs", "setup_ui":

**Main Entry Points:**
- `scripts/MainMenu.gd` - Entry point that loads Character Creation scene
- `scripts/Main.gd` - Alternative entry point
- `scripts/character_creation/CharacterCreationRoot.gd` - Main controller

**Tab Scripts:**
- `scripts/character_creation/tabs/TabNavigation.gd` - Tab navigation controller
- `scripts/character_creation/tabs/RaceTab.gd` - Race selection tab
- `scripts/character_creation/tabs/ClassTab.gd` - Class selection tab
- `scripts/character_creation/tabs/BackgroundTab.gd` - Background selection tab
- `scripts/character_creation/tabs/AbilityScoreTab.gd` - Ability scores tab
- `scripts/character_creation/tabs/AppearanceTab.gd` - Appearance customization tab
- `scripts/character_creation/tabs/NameConfirmTab.gd` - Final confirmation tab

**Component Scripts:**
- `scripts/character_creation/tabs/components/RaceEntry.gd`
- `scripts/character_creation/tabs/components/ClassEntry.gd`
- `scripts/character_creation/tabs/components/BackgroundEntry.gd`
- `scripts/character_creation/tabs/components/AbilityRow.gd`
- `scripts/character_creation/tabs/components/HeadPresetEntry.gd`
- `scripts/character_creation/tabs/components/VoiceEntry.gd`
- `scripts/character_creation/tabs/components/ColorPickerButton.gd`
- `scripts/character_creation/tabs/components/RacePreview.gd`

---

## 2. Functions with `.add_child()` Related to Tabs/Character Creation

### Main Character Creation Root - Tab Loading

**File:** `scripts/character_creation/CharacterCreationRoot.gd`
**Function:** `_load_tab(tab_name: String)`

```114:125:scripts/character_creation/CharacterCreationRoot.gd
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

**Purpose:** Dynamically loads and instantiates tab scenes (RaceTab, ClassTab, etc.) into `content_area` (CurrentTabContainer).

---

### Race Tab - Race Entry Creation

**File:** `scripts/character_creation/tabs/RaceTab.gd`
**Function:** `_populate_race_list()`

```95:110:scripts/character_creation/tabs/RaceTab.gd
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
```

**Purpose:** Creates RaceEntry instances and adds them to column containers in a 3-column layout.

---

### Class Tab - Class Entry Creation

**File:** `scripts/character_creation/tabs/ClassTab.gd`
**Function:** `_populate_class_list()`

```28:38:scripts/character_creation/tabs/ClassTab.gd
	var count: int = 0
	for cls in GameData.classes:
		var entry := class_entry_scene.instantiate()
		if not entry:
			Logger.error("ClassTab: Failed to instantiate class_entry_scene!", "character_creation")
			continue
		entry.setup(cls)
		entry.class_selected.connect(_on_class_selected)
		class_list.add_child(entry)
		count += 1
```

**Purpose:** Creates ClassEntry instances for each class and adds them to the class list.

---

### Background Tab - Background Entry Creation

**File:** `scripts/character_creation/tabs/BackgroundTab.gd`
**Function:** `_populate_background_list()`

```30:40:scripts/character_creation/tabs/BackgroundTab.gd
	var count: int = 0
	for bg in GameData.backgrounds:
		var entry := entry_scene.instantiate()
		if not entry:
			Logger.error("BackgroundTab: Failed to instantiate background_entry_scene!", "character_creation")
			continue
		entry.setup(bg)
		entry.background_selected.connect(_on_selected)
		list.add_child(entry)
		count += 1
```

**Purpose:** Creates BackgroundEntry instances for each background and adds them to the list.

---

### Appearance Tab - Head Preset Creation

**File:** `scripts/character_creation/tabs/AppearanceTab.gd`
**Function:** `_populate_head_presets()`

```63:77:scripts/character_creation/tabs/AppearanceTab.gd
	var count: int = 0
	for head_id in heads:
		var entry := head_entry_scene.instantiate()
		if not entry:
			Logger.error("AppearanceTab: Failed to instantiate head_entry_scene!", "character_creation")
			continue
		# Placeholder texture - will be replaced with actual head textures later
		var placeholder := ImageTexture.create_from_image(Image.create(128, 128, false, Image.FORMAT_RGB8))
		entry.setup(head_id, placeholder)
		entry.preset_selected.connect(_on_head_selected)
		head_grid.add_child(entry)
		count += 1
	
	Logger.debug("AppearanceTab: Added %d head presets" % count, "character_creation")
```

**Purpose:** Creates HeadPresetEntry instances for head customization.

---

### Other `.add_child()` Calls (Non-Tab Related)

**AbilityScoreTab.gd:**
- `ability_container.add_child(row)` - Adds ability score rows

**NameConfirmTab.gd:**
- `abilities_grid.add_child(label)` - Adds ability labels
- `abilities_grid.add_child(value_label)` - Adds ability values
- `voice_grid.add_child(entry)` - Adds voice entries

**Component Scripts:**
- `RaceEntry.gd`: `icon.add_child(placeholder)` - Adds placeholder icon
- `ColorPickerButton.gd`: `container.add_child(picker)`, `popup.add_child(container)` - Color picker UI
- `BackgroundEntry.gd`: `skills_container.add_child(label)` - Skill labels
- `ClassEntry.gd`: `subclass_container.add_child(label)` - Subclass labels

---

## 3. How Character Creation Scene is Instantiated

### Method: `change_scene_to_file()` (NOT `add_child()`)

**The entire Character Creation scene is loaded using `change_scene_to_file()`, NOT dynamically created with `add_child()`.**

### Entry Points:

**1. MainMenu.gd:**
```11:12:scripts/MainMenu.gd
func start_character_creation() -> void:
	get_tree().change_scene_to_file("res://scenes/character_creation/CharacterCreationRoot.tscn")
```

**2. Main.gd:**
```9:10:scripts/Main.gd
func start_character_creation() -> void:
	get_tree().change_scene_to_file("res://scenes/character_creation/CharacterCreationRoot.tscn")
```

### Scene Structure:

The `CharacterCreationRoot.tscn` scene file contains:
- **Static nodes** defined in the .tscn file (MainLayout, LeftSidebar, TabNavigation, etc.)
- **TabNavigation** is an **instance** of `TabNavigation.tscn` (not dynamically created)
- **TabContainer** (VBoxContainer) is **static** in `TabNavigation.tscn` (not dynamically created)

### Dynamic Tab Content Loading:

While the main scene structure is static, **tab content** is dynamically loaded:

```114:125:scripts/character_creation/CharacterCreationRoot.gd
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

**Tab scenes loaded:**
- `RaceTab.tscn`
- `ClassTab.tscn`
- `BackgroundTab.tscn`
- `AbilityScoreTab.tscn`
- `AppearanceTab.tscn`
- `NameConfirmTab.tscn`

---

## Summary

1. **Main Scene:** Loaded via `change_scene_to_file()` - **NOT dynamically created**
2. **Tab Navigation:** Static in scene file - **NOT dynamically created**
3. **Tab Container (VBoxContainer):** Static in `TabNavigation.tscn` - **NOT dynamically created**
4. **Tab Content:** Dynamically loaded via `load()` + `instantiate()` + `add_child()` in `_load_tab()`
5. **Tab Entries:** Dynamically created within each tab (RaceEntry, ClassEntry, etc.) using `instantiate()` + `add_child()`

**Key Finding:** The TabContainer and TabNavigation are **static scene nodes**, not dynamically created. Only the **content within tabs** is dynamically instantiated.

