# RightControls Granular Modularization Audit
**Date:** 2025-12-27  
**Goal:** Achieve true on-demand parameter loading with tiny subcategory scenes

---

## 1. Current RightControls Analysis

### Current Node Structure
**Scene Nodes (Static):** 14 nodes
- `WorldBuilderRightControls` (PanelContainer)
- `RightScroll` (ScrollContainer)
- `RightVBox` (VBoxContainer)
- `ArchetypeLabel` (Label)
- `ArchetypeOption` (OptionButton)
- `SeedLabel` (Label)
- `SeedHBox` (HBoxContainer)
- `SeedSpin` (SpinBox)
- `RandomizeBtn` (Button)
- `SectionSep` (HSeparator)
- `StepTitle` (Label)
- `ParamTree` (Tree) - **this is the problem node**

**Dynamic Nodes (ParamTree):**
- Each parameter creates 1 TreeItem with 3 columns
- TreeItem internally manages multiple child nodes:
  - Column 0: Label (parameter name)
  - Column 1: Control node (range/check/custom widget)
  - Column 2: Value display Label
  - Internal Tree node structures: ~3-5 nodes per TreeItem
- **Estimated node count per parameter:** 4-6 internal nodes

**Total Active Nodes Calculation:**
- Static scene: 14 nodes
- Step 0 (6 params): 6 × 5 = ~30 TreeItem nodes → **~44 total**
- Step 1 (4 params): 4 × 5 = ~20 TreeItem nodes → **~34 total**
- Step 4 (6 params): 6 × 5 = ~30 TreeItem nodes → **~44 total**
- Step 5 (3 params): 3 × 5 = ~15 TreeItem nodes → **~29 total**

**Actual Runtime (profiler observation):** ~104 active nodes in entire World Builder UI, with RightControls contributing ~30-40 nodes depending on step.

### TreeItem Creation in `_populate_param_tree()`

**Key Code Path (lines 192-341 in WorldBuilderRightControls.gd):**

```192:341:ui/world_builder/modules/WorldBuilderRightControls.gd
func _populate_param_tree() -> void:
	"""Populate Tree with parameters for current step."""
	if not param_tree:
		return
	
	# Check if we can use cached tree data
	var use_cache: bool = cached_trees.has(current_step) and not tree_dirty
	var cached_data: Dictionary = {}
	var params_list: Array = []
	var cached_values: Dictionary = {}
	
	if use_cache:
		cached_data = cached_trees[current_step]
		params_list = cached_data.get("params", [])
		cached_values = cached_data.get("values", {})
		MythosLogger.debug("UI/WorldBuilder", "Using cached tree data for step", {"step": current_step})
	else:
		# Load fresh data from STEP_DEFINITIONS
		var step_def: Dictionary = STEP_DEFINITIONS.get(current_step, {})
		params_list = step_def.get("params", [])
		
		# Build cached_values from current_params for this step's parameters
		for param in params_list:
			var azgaar_key: String = param.get("azgaar_key", param.get("name", ""))
			var cached_value: Variant = current_params.get(azgaar_key)
			if cached_value == null:
				cached_value = param.get("default", 0)
				current_params[azgaar_key] = cached_value
			cached_values[azgaar_key] = cached_value
		
		# Cache the data for future use
		cached_trees[current_step] = {
			"params": params_list.duplicate(true),  # Deep copy
			"values": cached_values.duplicate()
		}
		MythosLogger.debug("UI/WorldBuilder", "Cached tree data for step", {"step": current_step})
	
	if params_list.is_empty():
		MythosLogger.debug("UI/WorldBuilder", "No parameters for step", {"step": current_step})
		param_tree.clear()
		param_tree_items.clear()
		return
	
	# Clear existing items
	param_tree.clear()
	param_tree_items.clear()
	
	# Create root (hidden)
	var root: TreeItem = param_tree.create_item()
	
	# Create items for each parameter
	for param in params_list:
		var azgaar_key: String = param.get("azgaar_key", param.get("name", ""))
		var param_name: String = param.get("name", "")
		var param_type: String = param.get("type", param.get("ui_type", "HSlider"))
		
		# Create TreeItem
		var item: TreeItem = param_tree.create_item(root)
		
		# Column 0: Parameter name (with tooltip if available)
		item.set_text(0, param_name.capitalize() + ":")
		if param.has("description"):
			item.set_tooltip_text(0, param.description)
		
		# Column 1: Control (slider, option, checkbox, etc.)
		# Column 2: Value display
		var current_value: Variant
		if use_cache:
			# Use cached value
			current_value = cached_values.get(azgaar_key, param.get("default", 0))
			# Update current_params to match cached value
			current_params[azgaar_key] = current_value
		else:
			# Use current_params or default
			current_value = current_params.get(azgaar_key)
			if current_value == null:
				current_value = param.get("default", 0)
				current_params[azgaar_key] = current_value
		
		match param_type:
			"HSlider":
				# Use RANGE cell mode for sliders
				item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
				var min_val: float = param.get("min", 0.0)
				var max_val: float = param.get("max", 100.0)
				var step_val: float = param.get("step", 1.0)
				item.set_range_config(1, min_val, max_val, step_val, false)
				item.set_range(1, float(current_value))
				item.set_text(2, str(current_value))
				item.set_editable(1, true)
				item.set_editable(2, false)
			
			"OptionButton":
				# Use RANGE cell mode as dropdown (values are indices)
				if param.has("options"):
					var options: Array = param.options
					item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
					item.set_range_config(1, 0, options.size() - 1, 1, false)
					var selected_idx: int = options.find(current_value)
					if selected_idx < 0:
						selected_idx = 0
					item.set_range(1, selected_idx)
					item.set_text(2, str(options[selected_idx]))
					item.set_editable(1, true)
					item.set_editable(2, false)
				else:
					item.set_text(1, "No options")
					item.set_text(2, str(current_value))
			
			"CheckBox":
				# Use CHECK cell mode
				item.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
				item.set_checked(1, bool(current_value))
				item.set_text(2, "Yes" if bool(current_value) else "No")
				item.set_editable(1, true)
				item.set_editable(2, false)
			
			"SpinBox":
				# Use RANGE cell mode for spinbox
				item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
				var min_val: float = param.get("min", 0.0)
				var max_val: float = param.get("max", 100.0)
				var step_val: float = param.get("step", 1.0)
				item.set_range_config(1, min_val, max_val, step_val, false)
				item.set_range(1, float(current_value))
				item.set_text(2, str(int(current_value)))
				item.set_editable(1, true)
				item.set_editable(2, false)
			
			_:
				# Default: text display
				item.set_text(1, str(current_value))
				item.set_text(2, "")
				item.set_editable(1, false)
				item.set_editable(2, false)
		
		# Store metadata in TreeItem (azgaar_key and param data)
		item.set_metadata(0, {"azgaar_key": azgaar_key, "param": param})
		
		# Store mapping for quick lookup
		param_tree_items[azgaar_key] = item
	
	# Reset tree_dirty flag after successful rebuild
	tree_dirty = false
	
	MythosLogger.debug("UI/WorldBuilder", "Populated ParamTree", {
		"step": current_step,
		"param_count": params_list.size(),
		"cached": use_cache
	})
```

**Problem:** Even with caching, `param_tree.clear()` only removes TreeItems, but the Tree widget itself remains active and consumes resources. All TreeItems are instantiated and kept in memory even when switching steps, and the Tree's internal rendering system keeps all controls active.

### Why Current Caching Doesn't Help

1. **Tree Widget Overhead:** The `Tree` node is a complex container that maintains internal state, rendering buffers, and event handlers even when empty.

2. **TreeItem Persistence:** While `clear()` removes TreeItems, the underlying Tree node structure remains active. Each TreeItem creates multiple internal Control nodes that persist in the scene tree until explicitly freed.

3. **All Steps Still Loaded:** The `STEP_DEFINITIONS` dictionary loads all 8 steps' parameters on initialization (lines 94-152), even though only one step's UI is shown.

4. **No True Unloading:** When switching steps, old TreeItems are cleared but the Tree widget itself never gets disabled or removed from the scene tree. The widget continues to process input, layout calculations, and rendering updates.

---

## 2. Parameter Breakdown by Step (from azgaar_step_parameters.json)

### Step 0: Map Generation & Editing (6 parameters)

**Subcategory 1: Template & Base Generation (2 params)**
- `templateInput` (OptionButton) - Map template type
- `pointsInput` (HSlider) - Cell density

**Subcategory 2: Canvas Dimensions (3 params)**
- `mapWidthInput` (SpinBox) - Canvas width in pixels
- `mapHeightInput` (SpinBox) - Canvas height in pixels
- `mapSizeInput` (HSlider) - Map size relative to world (1-100%)

**Subcategory 3: Seed Configuration (1 param)**
- `optionsSeed` (SpinBox) - Map seed number

**Total:** 6 parameters across 3 subcategories

---

### Step 1: Terrain (4 parameters)

**Subcategory 1: Heightmap Generation (2 params)**
- `heightExponentInput` (HSlider) - Height exponent for altitude sharpness
- `allowErosion` (CheckBox) - Allow water erosion

**Subcategory 2: Water & Depressions (2 params)**
- `resolveDepressionsStepsInput` (SpinBox) - Max iterations for depression filling
- `lakeElevationLimitInput` (SpinBox) - Depression depth threshold for lakes

**Total:** 4 parameters across 2 subcategories

---

### Step 2: Climate (4 parameters)

**Subcategory 1: Precipitation (1 param)**
- `precInput` (HSlider) - Precipitation percentage (0-500%)

**Subcategory 2: Temperature Zones (3 params)**
- `temperatureEquator` (HSlider) - Temperature at equator (°C)
- `temperatureNorthPole` (HSlider) - Temperature at North Pole (°C)
- `temperatureSouthPole` (HSlider) - Temperature at South Pole (°C)

**Total:** 4 parameters across 2 subcategories

---

### Step 3: Biomes (0 parameters)
- Automatically generated from climate and terrain
- **No subcategories needed** - display informational message only

---

### Step 4: Structures & Civilizations (6 parameters)

**Subcategory 1: Political Entities (2 params)**
- `statesNumber` (SpinBox) - Number of states/countries
- `provincesRatio` (SpinBox) - Burgs percentage to form province

**Subcategory 2: Cultural Settings (2 params)**
- `culturesInput` (SpinBox) - Number of cultures
- `culturesSet` (OptionButton) - Culture set for names

**Subcategory 3: Religious & Settlement Scale (2 params)**
- `religionsNumber` (SpinBox) - Number of organized religions
- `manorsInput` (SpinBox) - Number of towns to place (0-1000, 1000=auto)

**Total:** 6 parameters across 3 subcategories

---

### Step 5: Environment (3 parameters)

**Subcategory 1: Population Settings (3 params)**
- `populationRateInput` (SpinBox) - People per population point
- `urbanizationInput` (HSlider) - Urbanization rate
- `urbanDensityInput` (SpinBox) - Urban density (average population per building)

**Total:** 3 parameters in 1 subcategory

---

### Step 6: Resources & Magic (0 parameters)
- Future expansion placeholder
- **No subcategories needed** - display informational message only

---

### Step 7: Export (0 parameters)
- Export and bake settings (handled by bottom bar)
- **No subcategories needed** - display informational message only

---

**Summary Statistics:**
- **Total parameters:** 23 across 5 steps (steps 0, 1, 2, 4, 5)
- **Total subcategories:** 11 across 5 steps
- **Average params per subcategory:** ~2.1
- **Largest subcategory:** 3 params (Canvas Dimensions, Temperature Zones, Population Settings)
- **Smallest subcategory:** 1 param (Seed Configuration, Precipitation)

---

## 3. Proposed Subcategory Scenes

### Directory Structure
```
res://ui/world_builder/submodules/
├── step0_map/
│   ├── MapTemplateBaseGen.tscn (2 params)
│   ├── MapCanvasDimensions.tscn (3 params)
│   └── MapSeedConfig.tscn (1 param)
├── step1_terrain/
│   ├── TerrainHeightmap.tscn (2 params)
│   └── TerrainWaterDepressions.tscn (2 params)
├── step2_climate/
│   ├── ClimatePrecipitation.tscn (1 param)
│   └── ClimateTemperature.tscn (3 params)
├── step3_biomes/
│   └── BiomesInfo.tscn (info message only, 0 params)
├── step4_structures/
│   ├── StructuresPolitical.tscn (2 params)
│   ├── StructuresCultural.tscn (2 params)
│   └── StructuresReligiousSettlements.tscn (2 params)
├── step5_environment/
│   └── EnvironmentPopulation.tscn (3 params)
├── step6_resources/
│   └── ResourcesInfo.tscn (info message only, 0 params)
└── step7_export/
    └── ExportInfo.tscn (info message only, 0 params)
```

### Generic Subcategory Scene Structure (Parameter Controls)

**Base Template:** Each parameter subcategory scene follows this structure:

```
SubcategoryContainer (VBoxContainer) [~5-12 nodes]
├── SubcategoryLabel (Label) - Optional, for grouping
├── ParamRow1 (HBoxContainer)
│   ├── ParamLabel1 (Label)
│   ├── ParamControl1 (HSlider/SpinBox/OptionButton/CheckBox)
│   └── ParamValue1 (Label) - Shows current value
├── ParamRow2 (HBoxContainer)
│   ├── ParamLabel2 (Label)
│   ├── ParamControl2 (HSlider/SpinBox/OptionButton/CheckBox)
│   └── ParamValue2 (Label)
└── ... (up to 6 params per subcategory)
```

**Node Count per Subcategory:**
- 1-param subcategory: ~6 nodes (VBoxContainer + Label + HBoxContainer + Label + Control + Value Label)
- 2-param subcategory: ~10 nodes
- 3-param subcategory: ~14 nodes

### Specific Subcategory Scenes

#### Step 0 Subcategories

**Scene: `MapTemplateBaseGen.tscn`** (2 params, ~10 nodes)
- Controls: `templateInput` (OptionButton), `pointsInput` (HSlider)
- Signals: `parameter_changed(key: String, value: Variant)`
- Methods: `get_current_values() -> Dictionary`, `set_values(dict: Dictionary)`

**Scene: `MapCanvasDimensions.tscn`** (3 params, ~14 nodes)
- Controls: `mapWidthInput` (SpinBox), `mapHeightInput` (SpinBox), `mapSizeInput` (HSlider)
- Signals: `parameter_changed(key: String, value: Variant)`
- Methods: `get_current_values() -> Dictionary`, `set_values(dict: Dictionary)`

**Scene: `MapSeedConfig.tscn`** (1 param, ~6 nodes)
- Controls: `optionsSeed` (SpinBox)
- Signals: `parameter_changed(key: String, value: Variant)`
- Methods: `get_current_values() -> Dictionary`, `set_values(dict: Dictionary)`

#### Step 1 Subcategories

**Scene: `TerrainHeightmap.tscn`** (2 params, ~10 nodes)
- Controls: `heightExponentInput` (HSlider), `allowErosion` (CheckBox)
- Signals: `parameter_changed(key: String, value: Variant)`
- Methods: `get_current_values() -> Dictionary`, `set_values(dict: Dictionary)`

**Scene: `TerrainWaterDepressions.tscn`** (2 params, ~10 nodes)
- Controls: `resolveDepressionsStepsInput` (SpinBox), `lakeElevationLimitInput` (SpinBox)
- Signals: `parameter_changed(key: String, value: Variant)`
- Methods: `get_current_values() -> Dictionary`, `set_values(dict: Dictionary)`

#### Step 2 Subcategories

**Scene: `ClimatePrecipitation.tscn`** (1 param, ~6 nodes)
- Controls: `precInput` (HSlider)
- Signals: `parameter_changed(key: String, value: Variant)`
- Methods: `get_current_values() -> Dictionary`, `set_values(dict: Dictionary)`

**Scene: `ClimateTemperature.tscn`** (3 params, ~14 nodes)
- Controls: `temperatureEquator` (HSlider), `temperatureNorthPole` (HSlider), `temperatureSouthPole` (HSlider)
- Signals: `parameter_changed(key: String, value: Variant)`
- Methods: `get_current_values() -> Dictionary`, `set_values(dict: Dictionary)`

#### Step 4 Subcategories

**Scene: `StructuresPolitical.tscn`** (2 params, ~10 nodes)
- Controls: `statesNumber` (SpinBox), `provincesRatio` (SpinBox)
- Signals: `parameter_changed(key: String, value: Variant)`
- Methods: `get_current_values() -> Dictionary`, `set_values(dict: Dictionary)`

**Scene: `StructuresCultural.tscn`** (2 params, ~10 nodes)
- Controls: `culturesInput` (SpinBox), `culturesSet` (OptionButton)
- Signals: `parameter_changed(key: String, value: Variant)`
- Methods: `get_current_values() -> Dictionary`, `set_values(dict: Dictionary)`

**Scene: `StructuresReligiousSettlements.tscn`** (2 params, ~10 nodes)
- Controls: `religionsNumber` (SpinBox), `manorsInput` (SpinBox)
- Signals: `parameter_changed(key: String, value: Variant)`
- Methods: `get_current_values() -> Dictionary`, `set_values(dict: Dictionary)`

#### Step 5 Subcategories

**Scene: `EnvironmentPopulation.tscn`** (3 params, ~14 nodes)
- Controls: `populationRateInput` (SpinBox), `urbanizationInput` (HSlider), `urbanDensityInput` (SpinBox)
- Signals: `parameter_changed(key: String, value: Variant)`
- Methods: `get_current_values() -> Dictionary`, `set_values(dict: Dictionary)`

#### Info-Only Scenes (Steps 3, 6, 7)

**Scene: `BiomesInfo.tscn`** (~3 nodes)
- Structure: VBoxContainer + Label (info text)
- No parameters, display-only

**Scene: `ResourcesInfo.tscn`** (~3 nodes)
- Structure: VBoxContainer + Label (info text)
- No parameters, display-only

**Scene: `ExportInfo.tscn`** (~3 nodes)
- Structure: VBoxContainer + Label (info text)
- No parameters, display-only

---

**Total Scene Count:** 16 subcategory scenes
- 11 parameter control scenes
- 3 info-only scenes
- 2 reusable templates (if we create base ParameterRow.tscn)

---

## 4. New Permanent Global Module

### Scene: `GlobalInputs.tscn` (7 nodes)

**Structure:**
```
GlobalInputs (VBoxContainer)
├── ArchetypeLabel (Label) - "Archetype Preset:"
├── ArchetypeOption (OptionButton) - Preset selection
├── SeedLabel (Label) - "Seed:"
├── SeedHBox (HBoxContainer)
│   ├── SeedSpin (SpinBox) - Seed value
│   └── RandomizeBtn (Button) - "🎲" randomize
└── SectionSep (HSeparator) - Visual separator
```

**Node Count:** 7 nodes (VBoxContainer + 2 Labels + OptionButton + HBoxContainer + SpinBox + Button + Separator)

**Script: `GlobalInputs.gd`**
- Signals:
  - `archetype_changed(archetype_name: String)`
  - `seed_changed(seed_value: int)`
- Methods:
  - `set_archetype(name: String)`
  - `get_archetype() -> String`
  - `set_seed(value: int)`
  - `get_seed() -> int`
  - `populate_archetypes(list: Array)` - Populate OptionButton with archetype names

**Location:** `res://ui/world_builder/submodules/GlobalInputs.tscn`

**Always Loaded:** Yes, this module remains in the scene tree permanently and is never unloaded.

---

## 5. Lazy Loading & Unloading Strategy

### New RightControls Structure

**Scene Updates:**
```
WorldBuilderRightControls (PanelContainer)
├── RightScroll (ScrollContainer)
│   └── RightVBox (VBoxContainer)
│       ├── GlobalInputs (Instance of GlobalInputs.tscn) - ALWAYS LOADED
│       ├── SectionSep1 (HSeparator)
│       ├── StepTitle (Label)
│       └── DynamicParams (VBoxContainer) - REPLACEABLE CONTENT
│           └── [Subcategory scenes loaded here dynamically]
```

### Lazy Loading Implementation (`WorldBuilderRightControls.gd`)

**Key Changes:**

1. **Remove ParamTree entirely** - Delete from scene and script references
2. **Add DynamicParams VBoxContainer** - Container for subcategory scenes
3. **Implement subcategory caching** - Dictionary of PackedScene → instantiated node
4. **Step change handler** - Clear and load only current step's subcategories

**New Data Structures:**
```gdscript
# Subcategory scene paths by step index
var STEP_SUBCATEGORIES: Dictionary = {
	0: [
		"res://ui/world_builder/submodules/step0_map/MapTemplateBaseGen.tscn",
		"res://ui/world_builder/submodules/step0_map/MapCanvasDimensions.tscn",
		"res://ui/world_builder/submodules/step0_map/MapSeedConfig.tscn"
	],
	1: [
		"res://ui/world_builder/submodules/step1_terrain/TerrainHeightmap.tscn",
		"res://ui/world_builder/submodules/step1_terrain/TerrainWaterDepressions.tscn"
	],
	# ... etc for all steps
}

# Cache of instantiated subcategories (for reuse)
var subcategory_cache: Dictionary = {}  # scene_path -> Array of instantiated nodes

# Currently loaded subcategories for active step
var active_subcategories: Array = []  # Array of Node references
```

**New Method: `clear_and_load_subcategories(step_index: int)`**

```gdscript
func clear_and_load_subcategories(step_index: int) -> void:
	"""Clear current subcategories and load only those for the active step."""
	var dynamic_params: VBoxContainer = $RightScroll/RightVBox/DynamicParams
	
	# Unload all currently active subcategories
	for subcat_node in active_subcategories:
		if is_instance_valid(subcat_node):
			# Option 1: queue_free() for true unloading (recommended)
			subcat_node.queue_free()
			
			# Option 2: Disable but keep (if caching enabled)
			# subcat_node.visible = false
			# subcat_node.process_mode = Node.PROCESS_MODE_DISABLED
	
	active_subcategories.clear()
	
	# Clear children from DynamicParams
	for child in dynamic_params.get_children():
		child.queue_free()
	
	# Load subcategories for current step
	var subcategory_paths: Array = STEP_SUBCATEGORIES.get(step_index, [])
	
	if subcategory_paths.is_empty():
		# Step with no parameters - show info message
		var info_label: Label = Label.new()
		info_label.text = "This step has no configurable parameters."
		info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dynamic_params.add_child(info_label)
		active_subcategories.append(info_label)
		return
	
	# Instance and add subcategory scenes
	for scene_path in subcategory_paths:
		var subcat_scene: PackedScene = load(scene_path) as PackedScene
		if not subcat_scene:
			MythosLogger.error("UI/WorldBuilder", "Failed to load subcategory scene", {"path": scene_path})
			continue
		
		var subcat_node: Node = subcat_scene.instantiate()
		dynamic_params.add_child(subcat_node)
		active_subcategories.append(subcat_node)
		
		# Connect subcategory signals to parameter_changed
		if subcat_node.has_signal("parameter_changed"):
			subcat_node.parameter_changed.connect(_on_subcategory_parameter_changed)
		
		# Initialize subcategory with current parameter values
		if subcat_node.has_method("set_values"):
			var param_values: Dictionary = {}
			var param_keys: Array = _get_subcategory_param_keys(scene_path)
			for key in param_keys:
				if current_params.has(key):
					param_values[key] = current_params[key]
			subcat_node.set_values(param_values)
	
	MythosLogger.debug("UI/WorldBuilder", "Loaded subcategories for step", {
		"step": step_index,
		"count": active_subcategories.size()
	})
```

**New Method: `_on_subcategory_parameter_changed(key: String, value: Variant)`**

```gdscript
func _on_subcategory_parameter_changed(key: String, value: Variant) -> void:
	"""Handle parameter change from a subcategory module."""
	current_params[key] = value
	emit_signal("parameter_changed", key, value)
	MythosLogger.debug("UI/WorldBuilder", "Parameter changed from subcategory", {"key": key, "value": value})
```

**Updated Method: `update_step(step_index: int)`**

```gdscript
func update_step(step_index: int) -> void:
	"""Update the UI for the specified step."""
	current_step = step_index
	
	var step_def: Dictionary = STEP_DEFINITIONS.get(current_step, {})
	step_title.text = step_def.get("title", "Step %d" % (current_step + 1))
	
	# Replace ParamTree population with subcategory loading
	clear_and_load_subcategories(step_index)
```

### Unloading Strategy

**Preferred: `queue_free()`** (True Unloading)
- Completely removes nodes from scene tree
- Frees memory immediately
- Maximum performance gain
- Slight delay on step switch (instantiation overhead)

**Alternative: `visible=false + process_mode=DISABLED`** (Caching)
- Keeps nodes in memory for faster switching
- Still processes input/rendering events (mitigated by DISABLED)
- Use for frequently accessed steps (e.g., step 0, 1)
- Cache limit: Keep only 2-3 most recent steps active

**Recommendation:** Use `queue_free()` for all subcategories initially. If step switching feels sluggish, implement selective caching for steps 0 and 1 only.

### UIConstants Integration

All subcategory scenes must use UIConstants for spacing:
- `VBoxContainer.separation = UIConstants.SPACING_MEDIUM`
- `HBoxContainer.separation = UIConstants.SPACING_SMALL`
- `Label` width constraints via `custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_STANDARD, 0)`
- Button heights: `custom_minimum_size = Vector2(0, UIConstants.BUTTON_HEIGHT_SMALL)`

### ScrollContainer Clipping

Add to `RightScroll`:
- `clip_children = true` - Prevents visual overflow

Add to `DynamicParams`:
- `clip_children = true` - Additional safety (though ScrollContainer should handle this)

---

## 6. Expected Performance Impact

### Current State
- **RightControls active nodes:** ~30-40 nodes (varies by step)
- **Total World Builder UI active nodes:** ~104 nodes (profiler observation)
- **Idle FPS:** ~5-30 FPS (unacceptable)
- **Problem:** Tree widget + all TreeItems active even when switching steps

### New State (Target)
- **RightControls active nodes during normal use:** ~10-15 nodes
  - GlobalInputs: 7 nodes (always loaded)
  - StepTitle: 1 node
  - Separator: 1 node
  - DynamicParams container: 1 node
  - Active subcategories: 1-3 scenes × 6-14 nodes each = 6-42 nodes (average ~12)
  - **Total: ~18-25 nodes** (on average)
- **Total World Builder UI active nodes goal:** 35-50 nodes (down from 104)
  - TopBar: ~10 nodes
  - LeftNav: ~12 nodes
  - CenterWebView: ~5 nodes
  - RightControls: ~20 nodes (new estimate)
  - BottomBar: ~8 nodes
  - **Total: ~55 nodes** (still within goal range, with buffer)

### Performance Improvements

1. **Node Count Reduction:** ~50% reduction in active nodes (104 → ~55)
2. **Tree Widget Removed:** Eliminates complex Tree widget overhead
3. **On-Demand Loading:** Only current step's parameters are instantiated
4. **Memory Efficiency:** Unused subcategories are completely freed
5. **Input Processing:** Only active controls process input events

### Expected FPS Impact

- **Idle FPS:** Target 60+ FPS (up from 5-30 FPS)
- **Step Switching:** Instant (< 16ms per switch) with `queue_free()`, even faster with caching
- **Parameter Editing:** No change (parameter controls remain responsive)

### Measurement Plan

After implementation, verify:
1. **Node count:** `print(get_tree().get_node_count())` at idle
2. **FPS:** Use Godot's built-in FPS counter or Performance Monitor
3. **Step switch speed:** Measure time between step change signal and subcategory load complete
4. **Memory usage:** Monitor with Performance Monitor's memory graphs

---

## 7. Implementation Plan (Step-by-Step)

### Phase 1: Setup & Infrastructure (Day 1)

**Step 1.1:** Create submodules directory structure
- Create `res://ui/world_builder/submodules/`
- Create step subdirectories: `step0_map/`, `step1_terrain/`, `step2_climate/`, `step3_biomes/`, `step4_structures/`, `step5_environment/`, `step6_resources/`, `step7_export/`

**Step 1.2:** Create GlobalInputs module
- Create `GlobalInputs.tscn` at `res://ui/world_builder/submodules/GlobalInputs.tscn`
- Create `GlobalInputs.gd` script with signals and methods
- Test archetype and seed functionality independently

**Step 1.3:** Update `azgaar_step_parameters.json`
- Add `"subcategories"` array to each step definition:
```json
{
  "index": 0,
  "title": "1. Map Generation & Editing",
  "subcategories": [
    {
      "name": "Template & Base Generation",
      "scene": "res://ui/world_builder/submodules/step0_map/MapTemplateBaseGen.tscn",
      "parameters": ["templateInput", "pointsInput"]
    },
    {
      "name": "Canvas Dimensions",
      "scene": "res://ui/world_builder/submodules/step0_map/MapCanvasDimensions.tscn",
      "parameters": ["mapWidthInput", "mapHeightInput", "mapSizeInput"]
    },
    {
      "name": "Seed Configuration",
      "scene": "res://ui/world_builder/submodules/step0_map/MapSeedConfig.tscn",
      "parameters": ["optionsSeed"]
    }
  ],
  "parameters": [...]
}
```

### Phase 2: Create First Proof-of-Concept Subcategory (Day 1-2)

**Step 2.1:** Create `MapTemplateBaseGen.tscn`
- 2-param subcategory scene (templateInput OptionButton, pointsInput HSlider)
- Basic layout: VBoxContainer + 2 parameter rows
- Each row: HBoxContainer + Label + Control + Value Label

**Step 2.2:** Create `MapTemplateBaseGen.gd` script
- Signal: `parameter_changed(key: String, value: Variant)`
- Methods: `get_current_values() -> Dictionary`, `set_values(dict: Dictionary)`
- Connect control signals to emit `parameter_changed`

**Step 2.3:** Test in isolation
- Instance scene manually and verify signal emission
- Test `set_values()` with sample data

### Phase 3: Create All Subcategory Scenes (Day 2-3)

**Step 3.1:** Create remaining Step 0 subcategories
- `MapCanvasDimensions.tscn` (3 params)
- `MapSeedConfig.tscn` (1 param)

**Step 3.2:** Create Step 1 subcategories
- `TerrainHeightmap.tscn` (2 params)
- `TerrainWaterDepressions.tscn` (2 params)

**Step 3.3:** Create Step 2 subcategories
- `ClimatePrecipitation.tscn` (1 param)
- `ClimateTemperature.tscn` (3 params)

**Step 3.4:** Create Step 4 subcategories
- `StructuresPolitical.tscn` (2 params)
- `StructuresCultural.tscn` (2 params)
- `StructuresReligiousSettlements.tscn` (2 params)

**Step 3.5:** Create Step 5 subcategories
- `EnvironmentPopulation.tscn` (3 params)

**Step 3.6:** Create info-only scenes
- `BiomesInfo.tscn` (Step 3)
- `ResourcesInfo.tscn` (Step 6)
- `ExportInfo.tscn` (Step 7)

**Step 3.7:** Add tooltips from JSON
- Extract `description` field from parameter definitions
- Set `tooltip_text` on control widgets

### Phase 4: Refactor RightControls Script (Day 3-4)

**Step 4.1:** Update scene structure
- Remove `ParamTree` node from `WorldBuilderRightControls.tscn`
- Add `DynamicParams` VBoxContainer
- Instance `GlobalInputs.tscn` as permanent child

**Step 4.2:** Refactor `WorldBuilderRightControls.gd`
- Remove all `param_tree` references
- Remove `param_tree_items` Dictionary
- Remove `cached_trees` Dictionary (no longer needed)
- Add `STEP_SUBCATEGORIES` Dictionary (populated from JSON or hardcoded)
- Add `active_subcategories` Array
- Implement `clear_and_load_subcategories(step_index: int)`
- Implement `_on_subcategory_parameter_changed(key: String, value: Variant)`
- Update `update_step(step_index: int)` to call `clear_and_load_subcategories()`
- Update `_load_archetype_params()` to propagate values to active subcategories

**Step 4.3:** Update `_ready()`
- Instance and add `GlobalInputs` module
- Connect GlobalInputs signals (`archetype_changed`, `seed_changed`)
- Remove `_setup_param_tree()` call
- Remove `_populate_param_tree()` call

**Step 4.4:** Update parameter value propagation
- When archetype changes, call `set_values()` on all active subcategories
- When step changes, initialize new subcategories with current `current_params` values

### Phase 5: Update WorldBuilderRoot Integration (Day 4)

**Step 5.1:** Verify signal forwarding
- Ensure `WorldBuilderRoot.gd` forwards `step_changed` to RightControls (already done, line 129-130)
- Test step switching triggers `update_step()` correctly

**Step 5.2:** Test parameter change propagation
- Ensure `parameter_changed` signals from subcategories bubble up correctly
- Verify CenterWebView receives parameter updates

### Phase 6: Testing & Verification (Day 4-5)

**Step 6.1:** Functional Testing
- Test all 8 steps: verify correct subcategories load
- Test parameter editing: verify values update and signals emit
- Test archetype switching: verify values propagate to active subcategories
- Test seed changes: verify GlobalInputs works correctly

**Step 6.2:** Performance Testing
- Measure node count: `print(get_tree().get_node_count())` at idle
- Measure FPS: Use Performance Monitor or built-in FPS counter
- Test step switching speed: Time from signal to UI update
- Compare before/after: Document node count and FPS improvements

**Step 6.3:** Edge Cases
- Test switching rapidly between steps
- Test with invalid/missing subcategory scenes
- Test with empty step (no parameters)
- Test parameter persistence across step switches

**Step 6.4:** UI Polish
- Verify UIConstants applied correctly (spacing, sizes)
- Verify tooltips display on hover
- Verify responsive layout on window resize
- Verify scroll behavior in RightScroll

### Phase 7: Optimization & Caching (Optional, Day 5)

**Step 7.1:** Implement selective caching
- If step switching is slow, add caching for frequently accessed steps (0, 1)
- Use `visible=false + process_mode=DISABLED` instead of `queue_free()`
- Limit cache to 2-3 most recent steps

**Step 7.2:** Fine-tune unloading strategy
- Benchmark `queue_free()` vs. `visible=false` performance
- Choose optimal strategy based on results

---

## 8. Risks & Mitigations

### Risk 1: Too Many Small Scenes → File Clutter
**Likelihood:** Medium  
**Impact:** Low (organizational issue, not performance)

**Mitigation:**
- Use clear, consistent naming: `{StepName}{SubcategoryName}.tscn`
- Organize in subdirectories by step
- Document scene purposes in JSON metadata
- Consider creating a reusable `ParameterRow.tscn` base scene if many subcategories share structure

### Risk 2: Signal Spam During Step Switch
**Likelihood:** Low  
**Impact:** Medium (could cause UI lag or parameter sync issues)

**Mitigation:**
- Batch parameter changes with `call_deferred()` if multiple subcategories emit simultaneously
- Add debounce/throttle to parameter change handler if needed
- Use signal blocking during initialization: `subcat_node.set_block_signals(true)` during `set_values()`, then unblock

### Risk 3: Memory Churn from Frequent Instantiate/Free
**Likelihood:** Low  
**Impact:** Low (Godot's object pool should handle this efficiently)

**Mitigation:**
- Monitor memory usage with Performance Monitor
- If churn is noticeable, implement selective caching (keep 2-3 most recent steps active)
- Use `queue_free()` instead of `free()` to avoid immediate deallocation mid-frame

### Risk 4: Parameter Value Loss During Step Switch
**Likelihood:** Medium  
**Impact:** High (user frustration if values reset)

**Mitigation:**
- Store all parameter values in `current_params` Dictionary (already implemented)
- When loading new subcategories, call `set_values()` with stored values from `current_params`
- Test thoroughly: switch steps, edit parameters, switch back, verify values persist

### Risk 5: Missing Subcategory Scenes Cause Crashes
**Likelihood:** Low  
**Impact:** High (game crashes if scene missing)

**Mitigation:**
- Validate scene paths exist before loading: `ResourceLoader.exists(scene_path)`
- Log errors and skip missing scenes gracefully
- Fallback to info message: "Some parameters could not be loaded"
- Add error handling in `clear_and_load_subcategories()` with try/catch equivalent

### Risk 6: Tooltip Text Not Displaying
**Likelihood:** Medium  
**Impact:** Low (UX degradation, not breaking)

**Mitigation:**
- Ensure tooltip_text set on control widgets (not just labels)
- Test tooltip display in all subcategory scenes
- Add tooltip support helper function if needed

### Risk 7: UIConstants Not Applied Correctly
**Likelihood:** Medium  
**Impact:** Medium (UI looks inconsistent)

**Mitigation:**
- Create a helper function `apply_ui_constants(node: Node)` to standardize application
- Add UIConstants application to each subcategory scene's `_ready()`
- Audit all subcategory scenes after creation

### Risk 8: Step Switching Feels Sluggish
**Likelihood:** Medium  
**Impact:** Medium (UX degradation)

**Mitigation:**
- Benchmark step switch time (target: < 16ms)
- If slow, implement selective caching for frequently accessed steps
- Consider preloading next/previous step subcategories in background (advanced optimization)

---

## 9. Next Actions After Audit

### Immediate Next Steps

1. **Review and Approve Audit** - User reviews this document and approves the approach
2. **Create Implementation Branch** - Git branch: `feat/genesis:right-controls-granular-modularization`
3. **Begin Phase 1** - Create directory structure and GlobalInputs module

### Refactor Prompt Template

When ready to implement, use this prompt structure:

```
[GENESIS MYTHOS – FULL FIRST PERSON 3D VIRTUAL TABLETOP RPG – GODOT 4.5.1]

Implement Phase X of the RightControls Granular Modularization refactor.

Reference: audit/RightControls_Granular_Modularization_Audit.md

Task: [Specific phase task from Section 7]

Requirements:
- Follow exact folder structure: ui/world_builder/submodules/
- Use UIConstants for all sizing/spacing
- Add exact script header to all .gd files
- Use typed GDScript everywhere
- Test after implementation

Do not run project until Phase 6 testing phase.
```

### Performance Verification Checklist

After Phase 6, verify:
- [ ] Node count reduced: `get_tree().get_node_count()` shows ~35-50 at idle (down from 104)
- [ ] FPS improved: Idle FPS > 60 (up from 5-30)
- [ ] Step switching works: All 8 steps load correct subcategories
- [ ] Parameter editing works: Values update and signals emit correctly
- [ ] Archetype switching works: Values propagate to active subcategories
- [ ] Parameter persistence works: Values persist across step switches
- [ ] Tooltips display: Hover shows parameter descriptions
- [ ] UI responsive: Layout scales correctly on window resize
- [ ] No errors in logs: Clean console output during normal use

### Success Criteria

**Minimum Success:**
- Node count reduced by 40%+ (104 → ~60)
- FPS improved to 30+ at idle (up from 5-30)
- All 8 steps functional with correct subcategories

**Target Success:**
- Node count reduced by 50%+ (104 → ~50)
- FPS improved to 60+ at idle
- Step switching instant (< 16ms)
- All parameters editable and persistent

**Stretch Goal:**
- Node count reduced by 60%+ (104 → ~40)
- FPS consistently 60+ even with all modules active
- Zero performance degradation during step switching

---

## Appendix A: Subcategory Scene Template Code

### Generic ParameterRow.gd (Optional Reusable Component)

```gdscript
# ╔═══════════════════════════════════════════════════════════
# ║ ParameterRow.gd
# ║ Desc: Reusable parameter row component for subcategory scenes
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends HBoxContainer

signal parameter_changed(key: String, value: Variant)

@onready var param_label: Label = $ParamLabel
@onready var param_control: Control = $ParamControl
@onready var param_value: Label = $ParamValue

var azgaar_key: String = ""
var param_type: String = "HSlider"

func setup(param_name: String, key: String, param_type: String, default_value: Variant, tooltip_text: String = "") -> void:
	"""Initialize parameter row with control type and default value."""
	azgaar_key = key
	param_type = param_type
	param_label.text = param_name.capitalize() + ":"
	if tooltip_text:
		param_control.tooltip_text = tooltip_text
	
	# Create control based on type
	match param_type:
		"HSlider":
			_create_slider(default_value)
		"SpinBox":
			_create_spinbox(default_value)
		"OptionButton":
			_create_option_button(default_value)
		"CheckBox":
			_create_checkbox(default_value)

func _create_slider(default_value: Variant) -> void:
	# Implementation for HSlider
	pass

# ... other control creation methods
```

**Note:** This template is optional. If subcategories are simple enough, inline implementation is acceptable.

---

## Appendix B: JSON Schema Extension

### Updated azgaar_step_parameters.json Structure

```json
{
  "steps": [
    {
      "index": 0,
      "title": "1. Map Generation & Editing",
      "description": "Core map generation parameters",
      "subcategories": [
        {
          "name": "Template & Base Generation",
          "scene": "res://ui/world_builder/submodules/step0_map/MapTemplateBaseGen.tscn",
          "parameters": ["templateInput", "pointsInput"]
        },
        {
          "name": "Canvas Dimensions",
          "scene": "res://ui/world_builder/submodules/step0_map/MapCanvasDimensions.tscn",
          "parameters": ["mapWidthInput", "mapHeightInput", "mapSizeInput"]
        },
        {
          "name": "Seed Configuration",
          "scene": "res://ui/world_builder/submodules/step0_map/MapSeedConfig.tscn",
          "parameters": ["optionsSeed"]
        }
      ],
      "parameters": [
        {
          "name": "templateInput",
          "azgaar_key": "templateInput",
          "ui_type": "OptionButton",
          "subcategory": "Template & Base Generation",
          "options": [...],
          "default": "continents"
        }
        // ... rest of parameters
      ]
    }
  ]
}
```

**Key Addition:** `subcategories` array at step level, and optional `subcategory` field on each parameter to link it to its subcategory.

---

**END OF AUDIT**

