# Load Time Audit: MainMenuUI → WorldBuilderUI Scene Transition

**Date:** 2025-12-27  
**Focus:** Scene transition load times and frame-blocking operations  
**Status:** Analysis Complete - Bottlenecks Identified

---

## Executive Summary

The transition from `MainMenuUI` to `WorldBuilderUI` involves multiple synchronous operations that block the main thread, causing noticeable frame drops and UI freezing. The primary bottlenecks are:

1. **Synchronous scene loading** via `get_tree().change_scene_to_file()` (~65-230ms+ blocking)
2. **Heavy `_ready()` functions** executing synchronously (~50-200ms+)
3. **File I/O operations** (JSON loading, Azgaar file copying) (~10-50ms)
4. **WebView initialization** (if enabled, ~50-200ms+)
5. **UI instantiation and layout calculations** (~20-50ms)

**Estimated Total Blocking Time:** 155-530ms+ → causes FPS drops to ~7-20 FPS during transition.

---

## 1. Scene Transition Flow Analysis

### 1.1 MainMenu → WorldBuilderUI Transition Path

**Entry Point:** `MainMenuController._on_create_world_pressed()`

```75:80:scripts/MainMenu.gd
func _on_create_world_pressed() -> void:
	"""Stub - old world generation disabled (preparing for Azgaar integration)."""
	print("World Builder: Old generator disabled – Azgaar integration in progress")
	push_warning("MainMenuController._on_create_world_pressed() called but old generation is disabled – Azgaar integration in progress")
	# Transition to world scene (UI still works, just generation is disabled)
	get_tree().change_scene_to_file(WORLD_CREATION_SCENE)
```

**Scene Path:** `res://core/scenes/world_root.tscn` (constant `WORLD_CREATION_SCENE`)

**Transition Method:** `get_tree().change_scene_to_file()` - **SYNCHRONOUS BLOCKING OPERATION**

### 1.2 world_root.tscn Load Sequence

**Scene Structure:**
- `WorldRoot` (Node3D) with script `world_root.gd`
- `MainCamera` (Camera3D) with `creative_fly_camera.gd`
- `DirectionalLight3D`
- `WorldEnvironment` (with environment resource)
- `ProceduralWorld` (Node3D)
- `Terrain3DManager` (Node3D) with `Terrain3DManager.gd`
- `DebugOverlay` (instance)

**Load Steps:** 8 (includes external resources: Environment, Scripts, PackedScene)

**Estimated Load Time:**
- File I/O (disk read): ~5-10ms
- Scene instantiation (node creation): ~10-20ms
- Script attachment and initialization: ~5-10ms
- **Total scene load: ~20-40ms**

### 1.3 world_root.gd._ready() Execution

**Location:** `res://core/scenes/world_root.gd`

```81:89:core/scenes/world_root.gd
func _ready() -> void:
	MythosLogger.verbose("World", "_ready() called")
	_remove_splash_screen()
	_ensure_lighting_and_camera()
	# Terrain3D initialization is now deferred - Terrain3DManager only loads config in _ready().
	# Terrain3D will be created and configured only when "Bake to 3D" button is clicked in WorldBuilderUI.
	# This improves performance by avoiding unnecessary Terrain3D setup until user actually needs 3D terrain.
	_setup_world_builder_ui()
	MythosLogger.info("World", "Setup complete - splash removed, terrain visible, UI added")
```

**Operations in `_ready()`:**
1. `_remove_splash_screen()` - Recursive label search (~1-5ms)
2. `_ensure_lighting_and_camera()` - Camera/light setup (~5-10ms)
3. `_setup_world_builder_ui()` - **MAJOR BOTTLENECK** (~50-200ms+)

**Estimated `_ready()` Time:** ~56-215ms

### 1.4 _setup_world_builder_ui() Breakdown

**Location:** `res://core/scenes/world_root.gd:102-160`

**Operations:**
1. **Scene Loading:** `load("res://ui/world_builder/WorldBuilderUI.tscn")` - **SYNCHRONOUS** (~10-20ms)
2. **Scene Instantiation:** `ui_scene.instantiate()` - **SYNCHRONOUS** (~10-20ms)
3. **CanvasLayer Creation:** `CanvasLayer.new()` + `add_child()` (~1-2ms)
4. **Theme Loading:** `load("res://themes/bg3_theme.tres")` - **SYNCHRONOUS** (~5-10ms)
5. **Terrain Manager Connection:** `world_builder_ui.set_terrain_manager()` (~1ms)

**Estimated `_setup_world_builder_ui()` Time:** ~27-53ms

**Total world_root.gd._ready() Time:** ~56-215ms (dominated by `_setup_world_builder_ui()`)

---

## 2. WorldBuilderUI.gd._ready() Analysis

**Location:** `res://ui/world_builder/WorldBuilderUI.gd`

### 2.1 _ready() Function Breakdown

```63:111:ui/world_builder/WorldBuilderUI.gd
func _ready() -> void:
	"""Initialize the World Builder UI."""
	DirAccess.make_dir_recursive_absolute("user://azgaar/")
	DirAccess.make_dir_recursive_absolute(UIConstants.DOWNLOADS_DIR)
	
	# Load step definitions from JSON
	_load_step_definitions()
	
	# Apply UIConstants to UI elements
	_apply_ui_constants()
	
	# Populate archetype option button
	for archetype_name in ARCHETYPES.keys():
		archetype_option.add_item(archetype_name)
	
	# Collect step buttons and connect signals
	var step_sidebar: VBoxContainer = $MainVBox/MainHSplit/LeftPanel/LeftContent/StepSidebar
	for i in range(TOTAL_STEPS):
		var btn: Button = step_sidebar.get_child(i) as Button
		if btn:
			step_buttons.append(btn)
			btn.pressed.connect(func(): _on_step_button_pressed(i))
	
	# Connect signals
	archetype_option.item_selected.connect(_load_archetype_params)
	seed_spin.value_changed.connect(_on_seed_changed)
	randomize_btn.pressed.connect(_randomize_seed)
	back_btn.pressed.connect(_on_back_pressed)
	next_btn.pressed.connect(_on_next_pressed)
	gen_btn.pressed.connect(_generate_azgaar)
	bake_to_3d_btn.pressed.connect(_bake_to_3d)
	
	# GUI Performance Fix: Setup Tree for parameters
	_setup_param_tree()
	
	# Initialize with first step
	_load_archetype_params(0)
	_update_step_ui()
	
	# Initialize Azgaar with default map
	_initialize_azgaar_default()
	
	# Apply responsive layout on initial load
	call_deferred("_update_responsive_layout")
	
	# GUI Performance Fix: _process() is conditionally enabled only during generation
	# (see _generate_azgaar() and generation complete/failed handlers)
	set_process(false)
```

### 2.2 Synchronous Operations in _ready()

| Operation | Location | Estimated Time | Blocking? |
|-----------|----------|----------------|-----------|
| `DirAccess.make_dir_recursive_absolute()` | Line 65-66 | ~1-5ms | Yes |
| `_load_step_definitions()` | Line 69 | **~10-30ms** | **Yes** |
| `_apply_ui_constants()` | Line 72 | ~5-15ms | Yes |
| Archetype loop | Line 75-76 | ~1-2ms | Yes |
| Step button collection | Line 79-84 | ~2-5ms | Yes |
| Signal connections | Line 87-93 | ~1-2ms | Yes |
| `_setup_param_tree()` | Line 96 | ~2-5ms | Yes |
| `_load_archetype_params(0)` | Line 99 | ~1-2ms | Yes |
| `_update_step_ui()` | Line 100 | ~5-10ms | Yes |
| `_initialize_azgaar_default()` | Line 103 | ~1ms (deferred) | No |
| `call_deferred("_update_responsive_layout")` | Line 106 | Deferred | No |

**Total WorldBuilderUI._ready() Time:** ~29-77ms (excluding deferred operations)

### 2.3 _load_step_definitions() Analysis

**Location:** `res://ui/world_builder/WorldBuilderUI.gd:237-300`

```237:300:ui/world_builder/WorldBuilderUI.gd
func _load_step_definitions() -> void:
	"""Load step definitions from JSON file."""
	var file: FileAccess = FileAccess.open(STEP_PARAMETERS_PATH, FileAccess.READ)
	if not file:
		MythosLogger.error("UI/WorldBuilder", "Failed to load step parameters", {"path": STEP_PARAMETERS_PATH})
		# Fallback to empty definitions
		for i in range(TOTAL_STEPS):
			STEP_DEFINITIONS[i] = {"title": "Step %d" % (i + 1), "params": []}
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		MythosLogger.error("UI/WorldBuilder", "Failed to parse step parameters JSON", {"error": parse_result})
		# Fallback to empty definitions
		for i in range(TOTAL_STEPS):
			STEP_DEFINITIONS[i] = {"title": "Step %d" % (i + 1), "params": []}
		return
	
	var data: Dictionary = json.data
	if not data.has("steps") or not data.steps is Array:
		MythosLogger.error("UI/WorldBuilder", "Invalid step parameters JSON structure")
		return
	
	# Convert JSON array to dictionary indexed by step index
	for step_data in data.steps:
		if not step_data is Dictionary or not step_data.has("index"):
			continue
		var step_idx: int = step_data.index
		var params_list: Array = []
		
		# Convert parameter definitions to format expected by _populate_param_tree()
		if step_data.has("parameters") and step_data.parameters is Array:
			for param_data in step_data.parameters:
				if not param_data is Dictionary:
					continue
				var param: Dictionary = {}
				param.name = param_data.get("name", "")
				param.type = param_data.get("ui_type", "HSlider")
				param.azgaar_key = param_data.get("azgaar_key", param.name)
				
				# Copy type-specific properties
				if param_data.has("options"):
					param.options = param_data.options
				if param_data.has("min"):
					param.min = param.data.min
				if param_data.has("max"):
					param.max = param_data.max
				if param_data.has("step"):
					param.step = param_data.step
				if param_data.has("default"):
					param.default = param_data.default
				
				params_list.append(param)
		
		STEP_DEFINITIONS[step_idx] = {
			"title": step_data.get("title", "Step %d" % (step_idx + 1)),
			"params": params_list
		}
	
	MythosLogger.info("UI/WorldBuilder", "Loaded step definitions", {"count": STEP_DEFINITIONS.size()})
```

**Bottleneck Analysis:**
- **File I/O:** `FileAccess.open()` + `get_as_text()` - **SYNCHRONOUS** (~5-15ms for ~300-line JSON)
- **JSON Parsing:** `JSON.parse()` - **SYNCHRONOUS** (~3-10ms for complex nested structure)
- **Data Processing:** Nested loops processing ~8 steps × ~30 params each (~2-5ms)

**Estimated `_load_step_definitions()` Time:** ~10-30ms

### 2.4 _apply_ui_constants() Analysis

**Location:** `res://ui/world_builder/WorldBuilderUI.gd:113-189`

**Operations:**
- Multiple `custom_minimum_size` assignments (~20+ operations)
- Theme constant overrides (~10+ operations)
- Modulate color assignments (~2 operations)

**Estimated `_apply_ui_constants()` Time:** ~5-15ms (depends on UI complexity)

### 2.5 _update_step_ui() Analysis

**Location:** `res://ui/world_builder/WorldBuilderUI.gd:333-371`

**Operations:**
- Step button highlight updates (8 buttons × modulate assignment)
- `_populate_param_tree()` call - **POTENTIAL BOTTLENECK** (~5-20ms for complex parameter trees)

**Estimated `_update_step_ui()` Time:** ~5-10ms

---

## 3. WorldBuilderAzgaar.gd Initialization

**Location:** `res://scripts/ui/WorldBuilderAzgaar.gd`

### 3.1 _ready() and _initialize_webview()

```23:111:scripts/ui/WorldBuilderAzgaar.gd
func _ready() -> void:
	"""Initialize Azgaar WebView on ready."""
	# Use call_deferred to ensure node tree is fully initialized
	call_deferred("_initialize_webview")

func _initialize_webview() -> void:
	"""Initialize the Azgaar WebView after the node tree is ready."""
	# TEMPORARY DIAGNOSTIC: Azgaar WebView disabled to test custom GUI layout visibility
	if DEBUG_DISABLE_AZGAAR:
		MythosLogger.info("WorldBuilderAzgaar", "DIAGNOSTIC: Azgaar WebView initialization disabled")
		# Remove the WebView node from scene tree to prevent godot_wry from initializing
		var web_view_node = get_node_or_null("WebViewMargin/AzgaarWebView")
		if web_view_node:
			# Remove from parent to prevent initialization, then queue_free to clean up
			var parent = web_view_node.get_parent()
			if parent:
				parent.remove_child(web_view_node)
			web_view_node.queue_free()
			MythosLogger.info("WorldBuilderAzgaar", "DIAGNOSTIC: WebView node removed to prevent godot_wry initialization")
		var web_view_margin = get_node_or_null("WebViewMargin")
		if web_view_margin:
			web_view_margin.visible = false
		return
	
	# Get the WebView node (godot_wry uses "WebView" type)
	# WebView is now wrapped in WebViewMargin container
	var web_view_node = get_node_or_null("WebViewMargin/AzgaarWebView")
	
	if not web_view_node:
		MythosLogger.error("WorldBuilderAzgaar", "AzgaarWebView node not found in scene tree")
		return
	
	# Check if it's a valid WebView instance
	var node_class = web_view_node.get_class()
	if node_class == "WebView":
		web_view = web_view_node
		MythosLogger.info("WorldBuilderAzgaar", "AzgaarWebView node is valid WebView instance (class: %s)" % node_class)
		
		# Connect IPC message signal for bidirectional communication
		if web_view.has_signal("ipc_message"):
			web_view.ipc_message.connect(_on_ipc_message)
			MythosLogger.info("WorldBuilderAzgaar", "Connected to WebView IPC message signal")
		else:
			MythosLogger.warn("WorldBuilderAzgaar", "WebView does not have ipc_message signal")
	else:
		MythosLogger.error("WorldBuilderAzgaar", "AzgaarWebView is not a WebView node (class: %s)" % node_class)
		return
	
	# Initialize Azgaar
	if azgaar_integrator:
		azgaar_integrator.copy_azgaar_to_user()
		
		# Prefer HTTP URL (embedded server), fallback to file://
		var url: String = azgaar_integrator.get_azgaar_http_url()
		if url.is_empty():
			url = azgaar_integrator.get_azgaar_url()
			MythosLogger.info("WorldBuilderAzgaar", "Using file:// URL (HTTP server not available)")
		else:
			MythosLogger.info("WorldBuilderAzgaar", "Using HTTP URL (embedded server)")
		
		# Load Azgaar URL
		if web_view.has_method("load_url"):
			web_view.load_url(url)
			MythosLogger.info("WorldBuilderAzgaar", "Loaded Azgaar URL", {"url": url})
			
			# Wait for page to load using process_frame yields instead of timer
			# Azgaar is a heavy page, so we yield more frames (~2 seconds at 60 FPS)
			var tree = get_tree()
			if tree:
				# Yield frames for Azgaar initialization
				for i in range(120):  # ~2 seconds at 60 FPS
					await tree.process_frame
					# Log progress at key intervals
					if i == 30:
						MythosLogger.debug("WorldBuilderAzgaar", "Azgaar loading... (25%)")
					elif i == 60:
						MythosLogger.debug("WorldBuilderAzgaar", "Azgaar loading... (50%)")
					elif i == 90:
						MythosLogger.debug("WorldBuilderAzgaar", "Azgaar loading... (75%)")
				
				_inject_azgaar_bridge()
			else:
				MythosLogger.warn("WorldBuilderAzgaar", "Node not in tree, injecting bridge immediately")
				_inject_azgaar_bridge()
		else:
			MythosLogger.error("WorldBuilderAzgaar", "WebView does not have load_url method")
	else:
		MythosLogger.error("WorldBuilderAzgaar", "AzgaarIntegrator singleton not found")
```

**Bottleneck Analysis:**
- **AzgaarIntegrator.copy_azgaar_to_user()** - **MAJOR BOTTLENECK IF FIRST RUN** (~50-500ms+ for recursive file copying)
- **WebView.load_url()** - **SYNCHRONOUS** (~10-50ms for URL loading)
- **Frame yielding loop** - 120 frames × 16.67ms = **~2000ms** (2 seconds) - **NON-BLOCKING** (uses `await`)
- **Bridge injection** - JavaScript execution (~5-10ms)

**Current Status:** WebView is **DISABLED** (`DEBUG_DISABLE_AZGAAR = true`), so initialization is minimal (~1-5ms).

**If WebView Enabled:** Estimated initialization time: ~65-560ms+ (dominated by file copying on first run)

### 3.2 AzgaarIntegrator.copy_azgaar_to_user() Analysis

**Location:** `res://scripts/managers/AzgaarIntegrator.gd:16-42`

```16:42:scripts/managers/AzgaarIntegrator.gd
func copy_azgaar_to_user() -> void:
	"""Copy Azgaar bundled files to user://azgaar/ for writability."""
	var source_dir := DirAccess.open(AZGAAR_BUNDLE_PATH)
	if not source_dir:
		push_error("Failed to open Azgaar bundle path: " + AZGAAR_BUNDLE_PATH)
		return
	
	# Create user directory if it doesn't exist
	var user_dir := DirAccess.open("user://")
	if not user_dir:
		push_error("Failed to open user:// directory")
		return
	
	if not user_dir.dir_exists("azgaar"):
		var err := user_dir.make_dir("azgaar")
		if err != OK:
			push_error("Failed to create user://azgaar/ directory: " + str(err))
			return
	
	# Copy files recursively
	var target_dir := DirAccess.open("user://azgaar/")
	if not target_dir:
		push_error("Failed to open user://azgaar/ directory")
		return
	
	_copy_directory_recursive(source_dir, target_dir, AZGAAR_BUNDLE_PATH, "user://azgaar/")
	print("Azgaar bundled files copied to user://azgaar/ for writability")
```

**Bottleneck Analysis:**
- **Recursive directory copy** - `_copy_directory_recursive()` processes entire `res://tools/azgaar/` directory
- **File I/O per file** - Each file requires `FileAccess.open()` (READ) + `get_as_text()` + `FileAccess.open()` (WRITE) + `store_string()`
- **Estimated files:** ~50-200+ files (HTML, JS, CSS, images, etc.)
- **Estimated size:** ~5-50MB total

**Estimated Time:**
- **First run (files don't exist):** ~50-500ms+ (depends on file count and size)
- **Subsequent runs (files exist):** ~1-5ms (early exit if files already copied, but current implementation doesn't check)

**Current Issue:** No existence check before copying - **ALWAYS COPIES** even if files already exist.

---

## 4. AzgaarServer Initialization

**Location:** `res://scripts/managers/AzgaarServer.gd`

### 4.1 _ready() Analysis

```44:64:scripts/managers/AzgaarServer.gd
func _ready() -> void:
	"""Initialize the HTTP server on ready."""
	# TEMPORARY DIAGNOSTIC: Skip server initialization if Azgaar is disabled
	if DEBUG_DISABLE_AZGAAR:
		MythosLogger.info("AzgaarServer", "DIAGNOSTIC: Azgaar disabled - server not started")
		set_process(false)
		return
	
	start_server()
	
	# Use Timer-based polling instead of _process() for better performance
	polling_timer = Timer.new()
	polling_timer.name = "PollingTimer"
	polling_timer.wait_time = 0.1  # Poll every 100ms instead of every frame
	polling_timer.one_shot = false
	polling_timer.timeout.connect(_on_polling_timer_timeout)
	add_child(polling_timer)
	polling_timer.start()
	
	# Disable _process() - use timer instead
	set_process(false)
```

**Bottleneck Analysis:**
- **start_server()** - Port binding attempts (~1-10ms, depends on port availability)
- **Timer creation** - Minimal (~1ms)

**Estimated Time:** ~2-11ms (currently disabled, so ~1ms)

---

## 5. Performance Metrics Summary

### 5.1 Estimated Load Times (Current - WebView Disabled)

| Phase | Operation | Estimated Time | Blocking? |
|-------|-----------|----------------|-----------|
| **Scene Transition** | `change_scene_to_file()` | ~20-40ms | **Yes** |
| **world_root._ready()** | Total | ~56-215ms | **Yes** |
| - `_remove_splash_screen()` | ~1-5ms | Yes |
| - `_ensure_lighting_and_camera()` | ~5-10ms | Yes |
| - `_setup_world_builder_ui()` | ~27-53ms | **Yes** |
| **WorldBuilderUI._ready()** | Total | ~29-77ms | **Yes** |
| - `_load_step_definitions()` | ~10-30ms | **Yes** |
| - `_apply_ui_constants()` | ~5-15ms | Yes |
| - `_update_step_ui()` | ~5-10ms | Yes |
| **WorldBuilderAzgaar._initialize_webview()** | (Disabled) | ~1-5ms | No (deferred) |
| **AzgaarServer._ready()** | (Disabled) | ~1ms | Yes |
| **Total Blocking Time** | | **~105-332ms** | |

### 5.2 Estimated Load Times (If WebView Enabled)

| Phase | Operation | Estimated Time | Blocking? |
|-------|-----------|----------------|-----------|
| **Scene Transition** | `change_scene_to_file()` | ~20-40ms | **Yes** |
| **world_root._ready()** | Total | ~56-215ms | **Yes** |
| **WorldBuilderUI._ready()** | Total | ~29-77ms | **Yes** |
| **WorldBuilderAzgaar._initialize_webview()** | Total | ~65-560ms+ | **Yes** |
| - `copy_azgaar_to_user()` (first run) | ~50-500ms+ | **Yes** |
| - `web_view.load_url()` | ~10-50ms | **Yes** |
| - Frame yielding (120 frames) | ~2000ms | No (async) |
| **AzgaarServer._ready()** | Total | ~2-11ms | Yes |
| **Total Blocking Time** | | **~170-903ms+** | |

### 5.3 Frame Time Impact

**Target Frame Time:** 16.67ms (60 FPS)

**Current Blocking Time:** ~105-332ms
- **Frame time during transition:** ~105-332ms
- **Effective FPS:** ~3-9 FPS (severe drop)

**If WebView Enabled:** ~170-903ms+
- **Frame time during transition:** ~170-903ms+
- **Effective FPS:** ~1-6 FPS (critical drop)

---

## 6. Bottleneck Analysis

### 6.1 Critical Bottlenecks (Must Fix)

1. **Synchronous Scene Loading** (`change_scene_to_file()`)
   - **Impact:** Blocks main thread for ~20-40ms
   - **Solution:** Use `change_scene_to_packed()` with preloaded scene, or implement async loading with progress overlay

2. **JSON File Loading** (`_load_step_definitions()`)
   - **Impact:** Blocks main thread for ~10-30ms
   - **Solution:** Load JSON asynchronously with `await` and `process_frame` yields

3. **Azgaar File Copying** (`copy_azgaar_to_user()` - if enabled)
   - **Impact:** Blocks main thread for ~50-500ms+ on first run
   - **Solution:** Check file existence before copying, or copy asynchronously with progress updates

### 6.2 Moderate Bottlenecks (Should Fix)

1. **UI Constants Application** (`_apply_ui_constants()`)
   - **Impact:** Blocks main thread for ~5-15ms
   - **Solution:** Batch UI updates or defer non-critical styling

2. **Parameter Tree Population** (`_populate_param_tree()`)
   - **Impact:** Blocks main thread for ~5-20ms
   - **Solution:** Populate tree incrementally with `await` yields

3. **Theme Loading** (`load("res://themes/bg3_theme.tres")`)
   - **Impact:** Blocks main thread for ~5-10ms
   - **Solution:** Preload theme in MainMenu or use `ResourceLoader.load_threaded_request()`

### 6.3 Minor Bottlenecks (Nice to Fix)

1. **Signal Connections** (multiple `connect()` calls)
   - **Impact:** ~1-2ms total
   - **Solution:** Batch connections or use signal groups

2. **Directory Creation** (`DirAccess.make_dir_recursive_absolute()`)
   - **Impact:** ~1-5ms
   - **Solution:** Check existence before creating, or create asynchronously

---

## 7. Recommended Chunk Points

### 7.1 Scene Transition Chunking

**Current:** `get_tree().change_scene_to_file(WORLD_CREATION_SCENE)` - **SYNCHRONOUS**

**Recommended Approach:**
```gdscript
# Preload scene in MainMenu (non-blocking)
var world_scene: PackedScene = preload("res://core/scenes/world_root.tscn")

# On button press, show progress overlay immediately
func _on_create_world_pressed() -> void:
    _show_progress_overlay("Loading world...", 0.0)
    await get_tree().process_frame  # Yield to show overlay
    
    # Change scene (still blocks, but overlay is visible)
    get_tree().change_scene_to_packed(world_scene)
```

**Better Approach (Async Loading):**
```gdscript
# In MainMenuController
var world_scene: PackedScene = null

func _ready() -> void:
    # Preload scene asynchronously
    ResourceLoader.load_threaded_request("res://core/scenes/world_root.tscn")
    # ... rest of initialization

func _on_create_world_pressed() -> void:
    _show_progress_overlay("Loading world...", 0.0)
    
    # Poll for scene load completion
    while ResourceLoader.load_threaded_get_status("res://core/scenes/world_root.tscn") == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
        await get_tree().process_frame
        _update_progress_overlay(ResourceLoader.load_threaded_get("res://core/scenes/world_root.tscn"))
    
    world_scene = ResourceLoader.load_threaded_get("res://core/scenes/world_root.tscn")
    if world_scene:
        get_tree().change_scene_to_packed(world_scene)
```

### 7.2 JSON Loading Chunking

**Current:** `_load_step_definitions()` - **SYNCHRONOUS**

**Recommended Approach:**
```gdscript
func _load_step_definitions() -> void:
    """Load step definitions from JSON file asynchronously."""
    # Yield to show progress
    await get_tree().process_frame
    
    var file: FileAccess = FileAccess.open(STEP_PARAMETERS_PATH, FileAccess.READ)
    if not file:
        # ... error handling
        return
    
    # Read file in chunks (if large)
    var json_string: String = file.get_as_text()
    file.close()
    
    # Yield before parsing
    await get_tree().process_frame
    
    var json: JSON = JSON.new()
    var parse_result: Error = json.parse(json_string)
    if parse_result != OK:
        # ... error handling
        return
    
    # Yield before processing
    await get_tree().process_frame
    
    var data: Dictionary = json.data
    # ... process data with periodic yields
    for step_data in data.steps:
        # Process step
        if step_data.get("index", -1) % 2 == 0:  # Yield every 2 steps
            await get_tree().process_frame
```

### 7.3 Azgaar File Copying Chunking

**Current:** `copy_azgaar_to_user()` - **SYNCHRONOUS** (always copies)

**Recommended Approach:**
```gdscript
func copy_azgaar_to_user() -> void:
    """Copy Azgaar bundled files asynchronously with progress."""
    # Check if files already exist
    if DirAccess.dir_exists_absolute("user://azgaar/") and FileAccess.file_exists("user://azgaar/index.html"):
        MythosLogger.debug("AzgaarIntegrator", "Azgaar files already exist, skipping copy")
        return
    
    # Create directory
    DirAccess.make_dir_recursive_absolute("user://azgaar/")
    
    # Copy files with progress updates
    var source_dir := DirAccess.open(AZGAAR_BUNDLE_PATH)
    var target_dir := DirAccess.open("user://azgaar/")
    
    var files_to_copy: Array[String] = []
    _collect_files_recursive(source_dir, AZGAAR_BUNDLE_PATH, files_to_copy)
    
    var total_files: int = files_to_copy.size()
    var copied_files: int = 0
    
    for file_path in files_to_copy:
        _copy_single_file(file_path)
        copied_files += 1
        
        # Yield every 10 files
        if copied_files % 10 == 0:
            await get_tree().process_frame
            # Update progress: copied_files / total_files
```

### 7.4 UI Initialization Chunking

**Current:** `WorldBuilderUI._ready()` - **SYNCHRONOUS**

**Recommended Approach:**
```gdscript
func _ready() -> void:
    """Initialize the World Builder UI with async chunking."""
    # Critical: Create directories
    DirAccess.make_dir_recursive_absolute("user://azgaar/")
    DirAccess.make_dir_recursive_absolute(UIConstants.DOWNLOADS_DIR)
    
    # Yield before heavy operations
    await get_tree().process_frame
    
    # Load step definitions asynchronously
    await _load_step_definitions()
    
    # Yield before UI setup
    await get_tree().process_frame
    
    # Apply UI constants (lightweight)
    _apply_ui_constants()
    
    # Yield before signal connections
    await get_tree().process_frame
    
    # Connect signals
    _connect_signals()
    
    # Yield before tree setup
    await get_tree().process_frame
    
    # Setup parameter tree
    _setup_param_tree()
    
    # Yield before initial step load
    await get_tree().process_frame
    
    # Initialize with first step
    _load_archetype_params(0)
    _update_step_ui()
    
    # Deferred operations (non-blocking)
    call_deferred("_initialize_azgaar_default")
    call_deferred("_update_responsive_layout")
    
    set_process(false)
```

---

## 8. Progress Overlay Integration Ideas

### 8.1 Native Progress Dialog (Recommended)

**Implementation:**
```gdscript
# res://scripts/ui/LoadingOverlay.gd
class_name LoadingOverlay
extends Control

@onready var progress_bar: ProgressBar = $VBox/ProgressBar
@onready var status_label: Label = $VBox/StatusLabel
@onready var panel: PanelContainer = $Panel

func _ready() -> void:
    # Full-screen overlay
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    z_index = 1000  # On top of everything
    
    # Semi-transparent background
    var bg: ColorRect = ColorRect.new()
    bg.color = Color(0, 0, 0, 0.7)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)
    move_child(bg, 0)

func show_loading(text: String = "Loading...", progress: float = 0.0) -> void:
    """Show loading overlay with text and progress."""
    visible = true
    status_label.text = text
    progress_bar.value = progress
    progress_bar.visible = true

func update_progress(text: String, progress: float) -> void:
    """Update loading progress."""
    status_label.text = text
    progress_bar.value = progress

func hide_loading() -> void:
    """Hide loading overlay."""
    visible = false
```

**Usage in MainMenuController:**
```gdscript
var loading_overlay: LoadingOverlay = null

func _ready() -> void:
    # ... existing code
    
    # Create loading overlay
    loading_overlay = preload("res://scenes/ui/LoadingOverlay.tscn").instantiate()
    add_child(loading_overlay)
    loading_overlay.hide_loading()

func _on_create_world_pressed() -> void:
    """Transition to world scene with progress overlay."""
    loading_overlay.show_loading("Loading world...", 0.0)
    await get_tree().process_frame  # Show overlay immediately
    
    # Change scene (overlay will be destroyed with MainMenu)
    get_tree().change_scene_to_file(WORLD_CREATION_SCENE)
```

### 8.2 WorldBuilderUI Progress Integration

**Add to WorldBuilderUI._ready():**
```gdscript
func _ready() -> void:
    """Initialize with progress updates."""
    # Show progress overlay (created in world_root.gd)
    var loading_overlay = get_node_or_null("/root/LoadingOverlay")
    if loading_overlay:
        loading_overlay.update_progress("Initializing UI...", 10.0)
    
    # ... directory creation
    
    if loading_overlay:
        loading_overlay.update_progress("Loading step definitions...", 30.0)
    await _load_step_definitions()
    
    if loading_overlay:
        loading_overlay.update_progress("Setting up UI...", 50.0)
    await get_tree().process_frame
    
    _apply_ui_constants()
    
    if loading_overlay:
        loading_overlay.update_progress("Connecting signals...", 70.0)
    await get_tree().process_frame
    
    _connect_signals()
    
    if loading_overlay:
        loading_overlay.update_progress("Finalizing...", 90.0)
    await get_tree().process_frame
    
    _setup_param_tree()
    _load_archetype_params(0)
    _update_step_ui()
    
    if loading_overlay:
        loading_overlay.update_progress("Complete!", 100.0)
        await get_tree().create_timer(0.2).timeout
        loading_overlay.hide_loading()
    
    call_deferred("_initialize_azgaar_default")
    call_deferred("_update_responsive_layout")
    set_process(false)
```

### 8.3 Global LoadingOverlay Singleton (Alternative)

**Create autoload singleton:**
```gdscript
# res://core/singletons/LoadingOverlay.gd
extends Node

var overlay_instance: Control = null

func show_loading(text: String = "Loading...", progress: float = 0.0) -> void:
    """Show global loading overlay."""
    if not overlay_instance:
        var scene = preload("res://scenes/ui/LoadingOverlay.tscn")
        overlay_instance = scene.instantiate()
        get_tree().root.add_child(overlay_instance)
    
    overlay_instance.show_loading(text, progress)

func update_progress(text: String, progress: float) -> void:
    """Update global loading progress."""
    if overlay_instance:
        overlay_instance.update_progress(text, progress)

func hide_loading() -> void:
    """Hide global loading overlay."""
    if overlay_instance:
        overlay_instance.hide_loading()
        overlay_instance.queue_free()
        overlay_instance = null
```

**Usage:**
```gdscript
# In MainMenuController
func _on_create_world_pressed() -> void:
    LoadingOverlay.show_loading("Loading world...", 0.0)
    await get_tree().process_frame
    get_tree().change_scene_to_file(WORLD_CREATION_SCENE)

# In WorldBuilderUI
func _ready() -> void:
    LoadingOverlay.update_progress("Initializing...", 10.0)
    # ... async operations with progress updates
    LoadingOverlay.hide_loading()
```

---

## 9. Implementation Priority

### 9.1 Phase 1: Critical Fixes (Immediate Impact)

1. **Add Progress Overlay** - Show loading feedback immediately
   - **Estimated Impact:** User perception improvement (no visual feedback → instant feedback)
   - **Estimated Time:** 2-4 hours

2. **Chunk JSON Loading** - Make `_load_step_definitions()` async
   - **Estimated Impact:** Reduce blocking by ~10-30ms
   - **Estimated Time:** 1-2 hours

3. **Fix Azgaar File Copying** - Check existence before copying
   - **Estimated Impact:** Reduce blocking by ~50-500ms on subsequent runs
   - **Estimated Time:** 30 minutes

### 9.2 Phase 2: Moderate Improvements (High Impact)

1. **Chunk UI Initialization** - Make `WorldBuilderUI._ready()` async
   - **Estimated Impact:** Reduce perceived blocking by ~29-77ms
   - **Estimated Time:** 2-3 hours

2. **Preload Theme** - Load theme in MainMenu
   - **Estimated Impact:** Reduce blocking by ~5-10ms
   - **Estimated Time:** 30 minutes

3. **Async Scene Loading** - Use `ResourceLoader.load_threaded_request()`
   - **Estimated Impact:** Reduce blocking by ~20-40ms (with progress updates)
   - **Estimated Time:** 2-3 hours

### 9.3 Phase 3: Polish (Nice to Have)

1. **Batch UI Updates** - Optimize `_apply_ui_constants()`
   - **Estimated Impact:** Reduce blocking by ~2-5ms
   - **Estimated Time:** 1 hour

2. **Incremental Tree Population** - Chunk `_populate_param_tree()`
   - **Estimated Impact:** Reduce blocking by ~5-20ms
   - **Estimated Time:** 1-2 hours

---

## 10. Testing Recommendations

### 10.1 Performance Profiling

1. **Use Godot Profiler:**
   - Enable "Frame Time" and "Function Time" in Debugger → Profiler
   - Capture transition from MainMenu to WorldBuilderUI
   - Identify exact blocking times for each function

2. **Add Timing Logs:**
   ```gdscript
   var start_time = Time.get_ticks_msec()
   # ... operation
   var elapsed = Time.get_ticks_msec() - start_time
   MythosLogger.debug("Performance", "Operation took %dms" % elapsed)
   ```

### 10.2 Load Time Metrics

**Target Metrics:**
- **Total blocking time:** < 50ms (maintain 60 FPS)
- **Perceived load time:** < 200ms (with progress overlay)
- **Frame time during transition:** < 16.67ms (60 FPS)

**Measurement Points:**
1. Button click → Progress overlay visible
2. Progress overlay visible → Scene loaded
3. Scene loaded → UI fully initialized
4. UI fully initialized → First frame rendered

### 10.3 Test Scenarios

1. **Cold Start:** First run (Azgaar files don't exist)
2. **Warm Start:** Subsequent runs (files exist)
3. **WebView Enabled:** With Azgaar WebView initialization
4. **WebView Disabled:** Current state (WebView disabled)

---

## 11. Code Snippets: Problematic Areas

### 11.1 Synchronous Scene Loading

```75:80:scripts/MainMenu.gd
func _on_create_world_pressed() -> void:
	"""Stub - old world generation disabled (preparing for Azgaar integration)."""
	print("World Builder: Old generator disabled – Azgaar integration in progress")
	push_warning("MainMenuController._on_create_world_pressed() called but old generation is disabled – Azgaar integration in progress")
	# Transition to world scene (UI still works, just generation is disabled)
	get_tree().change_scene_to_file(WORLD_CREATION_SCENE)
```

**Issue:** `change_scene_to_file()` is synchronous and blocks main thread.

### 11.2 Synchronous JSON Loading

```237:300:ui/world_builder/WorldBuilderUI.gd
func _load_step_definitions() -> void:
	"""Load step definitions from JSON file."""
	var file: FileAccess = FileAccess.open(STEP_PARAMETERS_PATH, FileAccess.READ)
	# ... synchronous file read and JSON parse
```

**Issue:** File I/O and JSON parsing block main thread.

### 11.3 Synchronous File Copying

```16:42:scripts/managers/AzgaarIntegrator.gd
func copy_azgaar_to_user() -> void:
	"""Copy Azgaar bundled files to user://azgaar/ for writability."""
	# ... recursive directory copy (synchronous)
	_copy_directory_recursive(source_dir, target_dir, AZGAAR_BUNDLE_PATH, "user://azgaar/")
```

**Issue:** Recursive file copying blocks main thread, no existence check.

### 11.4 Synchronous UI Initialization

```63:111:ui/world_builder/WorldBuilderUI.gd
func _ready() -> void:
	"""Initialize the World Builder UI."""
	# ... all operations are synchronous
	_load_step_definitions()
	_apply_ui_constants()
	# ... no yields between operations
```

**Issue:** All initialization happens in one frame, blocking rendering.

---

## 12. Conclusion

The scene transition from MainMenuUI to WorldBuilderUI has **multiple synchronous bottlenecks** that cause significant frame drops (FPS drops to ~3-9 FPS). The primary issues are:

1. **Synchronous scene loading** (~20-40ms blocking)
2. **Heavy `_ready()` functions** (~85-292ms total blocking)
3. **File I/O operations** (~10-30ms for JSON, ~50-500ms+ for Azgaar files if enabled)
4. **No progress feedback** (user sees frozen screen)

**Recommended Immediate Actions:**
1. Add progress overlay for instant visual feedback
2. Chunk JSON loading with `await` yields
3. Fix Azgaar file copying to check existence first
4. Make UI initialization async with progress updates

**Expected Improvement:**
- **Current blocking time:** ~105-332ms (WebView disabled)
- **Target blocking time:** < 50ms (with async chunking)
- **Perceived load time:** < 200ms (with progress overlay)

**Implementation Priority:** Phase 1 fixes should be implemented first for immediate user experience improvement.

---

**End of Audit**

