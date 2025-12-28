# GUI Update Integration Investigation Audit
**Date:** 2025-12-27  
**Target:** World Builder UI Migration to Modular Render Approach  
**Scope:** Complete investigation of current implementation and migration plan for performance-optimized modular UI trees

---

## Executive Summary

### Current State
The World Builder UI (`WorldBuilderUI.tscn` and `WorldBuilderUI.gd`) is a monolithic full-screen Control with **43 nodes** organized in a deep hierarchy. The structure uses an `HSplitContainer` dividing the screen into left navigation (step buttons), center WebView (Azgaar map display via godot_wry), and right controls (dynamic parameters). Performance issues are documented with ~5 FPS in debug mode, primarily from rendering overhead in large node trees, though the audit reveals additional bottlenecks in performance monitoring overlays.

### Desired State
Migrate to a **modular UI architecture** with small, self-contained `.tscn` scenes (5-20 nodes each) that are dynamically instanced and managed. This approach reduces draw calls, tree traversal overhead, and enables visibility culling for inactive sections. The target layout maintains the same 8-step wizard workflow but with improved performance through modularization.

### Migration Feasibility
**Estimated Effort:** 15-25 hours  
**Reusability:** ~70% of existing code (logic, data structures, signals) can be preserved  
**Main Effort:** Breaking monolithic scene into modular components, refactoring node paths, and establishing communication patterns between modules

**Key Findings:**
- ✅ **WebView Integration:** Uses `godot_wry` (not GDCef) with full JavaScript execution support via `execute_js()`/`eval()` and bidirectional IPC via `ipc_message` signal
- ✅ **Parameter Sync:** Currently uses direct JS injection (not file-based `options.json` reloading as initially assumed)
- ⚠️ **Performance:** Current structure has 43 nodes in a single scene; modularization should reduce per-frame overhead
- ✅ **Data-Driven:** Parameters loaded from JSON (`azgaar_step_parameters.json`), making refactoring easier
- ✅ **Theme System:** Centralized theme (`bg3_theme.tres`) and constants (`UIConstants.gd`) support modular approach

---

## Codebase Investigation

### Relevant Files and Scripts

#### Core UI Files
1. **`ui/world_builder/WorldBuilderUI.tscn`** (275 lines, 43 nodes)
   - Main scene file with full node hierarchy
   - Root: `Control` with `PRESET_FULL_RECT` anchors
   - Structure: `MainVBox` → `HSplitContainer` → 3 panels (Left, Center, Right) + `BottomBar`

2. **`ui/world_builder/WorldBuilderUI.gd`** (795 lines)
   - Main controller script
   - Handles step navigation, parameter management, generation triggers
   - Uses `@onready var` with deep node paths (e.g., `$MainVBox/MainHSplit/RightPanel/RightScroll/RightVBox/ArchetypeOption`)

3. **`scripts/ui/WorldBuilderAzgaar.gd`** (401 lines)
   - WebView controller for Azgaar integration
   - Handles WebView initialization, JS execution, parameter syncing
   - Currently has `DEBUG_DISABLE_AZGAAR = true` (diagnostic flag)

#### Integration Scripts
4. **`scripts/managers/AzgaarIntegrator.gd`** (137 lines)
   - Manages Azgaar asset copying from `res://tools/azgaar/` to `user://azgaar/`
   - Provides URL generation (HTTP server or file:// fallback)
   - Handles `options.json` file writing (currently unused - JS injection preferred)

5. **`scripts/managers/AzgaarServer.gd`** (295 lines)
   - Embedded HTTP server for serving Azgaar files
   - Listens on port 8080+ (tries multiple ports)
   - Currently disabled when `DEBUG_DISABLE_AZGAAR = true`

#### Supporting Files
6. **`scripts/ui/UIConstants.gd`** (111 lines)
   - Semantic UI sizing constants
   - Used throughout for responsive layouts
   - Supports modular approach

7. **`themes/bg3_theme.tres`** (475 lines)
   - Centralized theme resource
   - Dark fantasy aesthetic with gold/orange accents
   - Applied to all UI elements

8. **`data/config/azgaar_step_parameters.json`**
   - Step definitions and parameter configurations
   - Data-driven approach supports modular refactoring

### Current Node Hierarchy Analysis

#### Full Tree Structure
```
WorldBuilderUI (Control, anchors_full_rect)
├── Background (ColorRect, full rect, mouse_filter=IGNORE)
└── MainVBox (VBoxContainer, full rect)
    ├── TopBar (PanelContainer)
    │   └── TopBarContent (CenterContainer)
    │       └── TitleLabel (Label, "World Builder – Forging the World")
    ├── MainHSplit (HSplitContainer)
    │   ├── LeftPanel (PanelContainer, ~15-20% width)
    │   │   └── LeftContent (VBoxContainer)
    │   │       └── StepSidebar (VBoxContainer)
    │   │           ├── Step1Btn (Button, "1. Map Generation & Editing")
    │   │           ├── Step2Btn (Button, "2. Terrain")
    │   │           ├── Step3Btn (Button, "3. Climate")
    │   │           ├── Step4Btn (Button, "4. Biomes")
    │   │           ├── Step5Btn (Button, "5. Structures & Civilizations")
    │   │           ├── Step6Btn (Button, "6. Environment")
    │   │           ├── Step7Btn (Button, "7. Resources & Magic")
    │   │           └── Step8Btn (Button, "8. Export")
    │   ├── CenterPanel (PanelContainer, ~60-65% width)
    │   │   └── CenterContent (Control, WorldBuilderAzgaar script)
    │   │       └── OverlayPlaceholder (TextureRect, visible=false)
    │   │           └── [WebViewMargin/AzgaarWebView - removed when DEBUG_DISABLE_AZGAAR]
    │   └── RightPanel (PanelContainer, ~20-25% width)
    │       └── RightScroll (ScrollContainer)
    │           └── RightVBox (VBoxContainer)
    │               ├── ArchetypeLabel (Label)
    │               ├── ArchetypeOption (OptionButton)
    │               ├── SeedLabel (Label)
    │               ├── SeedHBox (HBoxContainer)
    │               │   ├── SeedSpin (SpinBox)
    │               │   └── RandomizeBtn (Button, "🎲")
    │               ├── SectionSep (HSeparator)
    │               ├── StepTitle (Label)
    │               └── ParamTree (Tree, 3 columns, hide_root=true)
    └── BottomBar (PanelContainer)
        └── BottomContent (HBoxContainer)
            ├── SpacerLeft (Control, expand)
            ├── BackBtn (Button, "← Back")
            ├── GenBtn (Button, "✨ Generate / Apply Changes")
            ├── BakeTo3DBtn (Button, "🎨 Bake to 3D", disabled, hidden)
            ├── NextBtn (Button, "Next →")
            ├── ProgressBar (ProgressBar, hidden)
            ├── StatusLabel (Label, "Ready")
            └── SpacerRight (Control, expand)
```

#### Node Count Breakdown
- **Total Nodes:** 43
- **Left Panel:** 11 nodes (1 PanelContainer + 1 VBoxContainer + 1 VBoxContainer + 8 Buttons)
- **Center Panel:** 3 nodes (1 PanelContainer + 1 Control + 1 TextureRect)
- **Right Panel:** 10 nodes (1 PanelContainer + 1 ScrollContainer + 1 VBoxContainer + 7 controls)
- **Bottom Bar:** 8 nodes (1 PanelContainer + 1 HBoxContainer + 6 controls)
- **Top Bar:** 3 nodes (1 PanelContainer + 1 CenterContainer + 1 Label)
- **Root/Background:** 2 nodes

### Bottleneck Identification

#### 1. Node Tree Traversal
**Issue:** Deep node paths in `@onready var` declarations require traversal on every access
```gdscript
@onready var archetype_option: OptionButton = $MainVBox/MainHSplit/RightPanel/RightScroll/RightVBox/ArchetypeOption
```
**Impact:** Each `@onready var` assignment traverses the tree once at `_ready()`, but subsequent property access is cached. However, the deep hierarchy still impacts initial load and makes refactoring difficult.

**Current Count:** 18 `@onready var` declarations with paths 4-7 levels deep

#### 2. Dynamic Parameter Tree
**Issue:** `ParamTree` is rebuilt on every step change via `_populate_param_tree()`
- Clears and recreates all TreeItems
- Iterates through parameter definitions
- Creates controls (sliders, option buttons, checkboxes) as TreeItem cells
- **Current optimization:** Caching system (`cached_trees`) reduces rebuilds, but still requires tree manipulation

**Impact:** Tree manipulation is expensive, especially with many parameters (some steps have 10+ parameters)

#### 3. WebView Rendering
**Issue:** WebView (godot_wry) renders in the center panel, adding rendering overhead
- WebView is a native component that renders independently
- Currently disabled for diagnostics (`DEBUG_DISABLE_AZGAAR = true`)
- When active, adds significant rendering cost

**Impact:** WebView rendering is separate from Godot's rendering pipeline, but still impacts overall FPS

#### 4. Layout Recalculation
**Issue:** `_update_responsive_layout()` recalculates panel widths on resize
- Called via `call_deferred()` with throttling (`_resize_pending` flag)
- Recalculates panel widths as percentages of viewport
- Updates `custom_minimum_size` on multiple panels

**Impact:** Acceptable with current throttling, but could be optimized further

### godot_wry Integration Details

#### Current Implementation
- **Addon:** `res://addons/godot_wry/` (GDExtension-based WebView)
- **Node Type:** `WebView` (not a built-in Godot node)
- **Initialization:** WebView node must exist in scene tree, then accessed via `get_node()`

#### Key Methods Available
```gdscript
web_view.load_url(url: String)                    # Load URL
web_view.execute_js(code: String) -> Variant      # Execute JS, returns result
web_view.eval(code: String) -> void                # Execute JS, no return
web_view.post_message(message: String)             # Send IPC message
web_view.reload()                                   # Reload current page
```

#### Key Signals
```gdscript
web_view.ipc_message(message: String)              # Receive IPC messages from web
```

#### Current Parameter Sync Method
**NOT file-based reloading** - Uses direct JavaScript injection:
```gdscript
func _sync_parameters_to_azgaar(params: Dictionary) -> void:
    for azgaar_key in params:
        var value = params[azgaar_key]
        var js_code = "if (typeof azgaar !== 'undefined' && azgaar.options) { azgaar.options.%s = %s; }" % [azgaar_key, js_value]
        _execute_azgaar_js(js_code)
```

**Advantages:**
- ✅ No file I/O overhead
- ✅ Immediate parameter updates
- ✅ No reload delays

**Limitations:**
- ⚠️ Requires Azgaar to be fully loaded (checks for `typeof azgaar !== 'undefined'`)
- ⚠️ JS execution may fail silently if Azgaar not ready
- ⚠️ No direct return values from parameter setting (fire-and-forget)

#### Generation Flow
1. User clicks "Generate / Apply Changes"
2. `_generate_azgaar()` called
3. `trigger_generation_with_options()` on `WorldBuilderAzgaar`
4. `_sync_parameters_to_azgaar()` injects all parameters via JS
5. `_execute_azgaar_js("azgaar.generate()")` triggers generation
6. Bridge script (injected on page load) monitors completion
7. IPC message sent when generation complete
8. `_on_ipc_message()` receives completion signal
9. `generation_complete` signal emitted

**No file-based reloading** - All communication is via JavaScript execution and IPC messages.

---

## Gap Analysis

### Differences: Current vs. Desired Layout

#### Current Layout
- **Left Panel:** Vertical list of 8 step buttons (always visible)
- **Center Panel:** WebView for Azgaar (interactive, full Azgaar UI)
- **Right Panel:** ScrollContainer with:
  - Archetype preset (always visible)
  - Seed controls (always visible)
  - Step title (dynamic)
  - Parameter Tree (dynamic, changes per step)
- **Bottom Bar:** Navigation buttons, progress, status (always visible)

#### Desired Layout (from requirements)
- **Left Panel:** Vertical navigation with step buttons (same)
- **Center Panel:** WebView (same, but note: "no local overlays—all edits via Azgaar's native UI")
- **Right Panel:** Dynamic controls with:
  - Globals (seed/template) in first step OR always visible (current: always visible ✅)
  - Step-specific parameters (current: dynamic ✅)
- **Bottom Bar:** Generate/Apply, Bake to 3D, Back/Next, Status (same)

**Conclusion:** Current layout **already matches desired layout** in structure. The migration focus should be on **modularization**, not layout changes.

### Missing Features

1. **Tooltips**
   - Current: No tooltips on parameters
   - Desired: Tooltips for parameter descriptions (from JSON `description` field)
   - **Impact:** Low priority, can be added during modularization

2. **3D Preview Toggle**
   - Current: `BakeTo3DBtn` exists but only visible on step 7 (Export)
   - Desired: Toggle to switch between 2D WebView and 3D Terrain3D preview
   - **Impact:** Medium priority, requires SubViewport setup

3. **Performance Notes**
   - Current: No performance warnings for high point counts
   - Desired: Warnings when `pointsInput` exceeds hardware capabilities
   - **Impact:** Low priority, `UIConstants.get_clamped_points()` already handles clamping

4. **Progress Indicators**
   - Current: ProgressBar and StatusLabel exist but basic
   - Desired: More detailed progress (e.g., "Generating heightmap... 45%")
   - **Impact:** Low priority, can be enhanced incrementally

### Integration Risks

#### 1. Azgaar Reload Times
**Risk:** WebView reload can take 2-5 seconds for full Azgaar initialization  
**Current Mitigation:** Uses HTTP server (faster than file://) and JS injection (no reload needed)  
**Modular Impact:** None - WebView remains in center panel module

#### 2. File I/O Reliability
**Risk:** `options.json` writing could fail on some systems  
**Current Status:** Not used - JS injection preferred  
**Modular Impact:** None - file-based approach not needed

#### 3. Cross-Platform WebView Support
**Risk:** godot_wry may have platform-specific limitations  
**Current Status:** Works on Windows/Linux/Mac (GDExtension)  
**Modular Impact:** Low - WebView module can be swapped if needed

#### 4. JavaScript Execution Reliability
**Risk:** JS execution may fail if Azgaar not fully loaded  
**Current Mitigation:** Checks for `typeof azgaar !== 'undefined'` before execution  
**Modular Impact:** None - JS execution logic remains in `WorldBuilderAzgaar` module

#### 5. Signal Communication Between Modules
**Risk:** Modular scenes need reliable signal communication  
**Current Status:** Uses direct signal connections  
**Modular Solution:** Use autoload singleton (EventBus) or parent-child signal forwarding

---

## Modularization Plan

### Target Architecture

Break the monolithic `WorldBuilderUI.tscn` into **7 modular scenes**:

1. **`WorldBuilderRoot.tscn`** (5-8 nodes)
   - Root Control with background
   - MainVBox container
   - Instances and manages child modules

2. **`WorldBuilderTopBar.tscn`** (3-4 nodes)
   - TopBar PanelContainer
   - TitleLabel
   - Self-contained, minimal

3. **`WorldBuilderLeftNav.tscn`** (10-12 nodes)
   - LeftPanel PanelContainer
   - StepSidebar with 8 step buttons
   - Emits signals for step changes

4. **`WorldBuilderCenterWebView.tscn`** (3-5 nodes)
   - CenterPanel PanelContainer
   - WebView container (WorldBuilderAzgaar script)
   - Handles WebView initialization and communication

5. **`WorldBuilderRightControls.tscn`** (12-15 nodes)
   - RightPanel PanelContainer
   - ScrollContainer with RightVBox
   - Archetype, Seed, StepTitle, ParamTree
   - Emits signals for parameter changes

6. **`WorldBuilderBottomBar.tscn`** (8-10 nodes)
   - BottomBar PanelContainer
   - Navigation buttons, progress, status
   - Emits signals for button presses

7. **`WorldBuilderParamRow.tscn`** (3-5 nodes) [Optional - for future Tree replacement]
   - Reusable parameter row (Label + Control + Value)
   - Can replace Tree with VBoxContainer of rows

### Proposed Scene Structure

```
res://scenes/ui/world_builder/
├── WorldBuilderRoot.tscn          # Main container
├── WorldBuilderTopBar.tscn      # Title bar
├── WorldBuilderLeftNav.tscn       # Step navigation
├── WorldBuilderCenterWebView.tscn  # Azgaar WebView
├── WorldBuilderRightControls.tscn  # Parameter controls
├── WorldBuilderBottomBar.tscn     # Navigation bar
└── components/
    ├── StepButton.tscn            # Reusable step button (optional)
    └── ParamRow.tscn              # Reusable parameter row (optional)
```

### Module Communication Pattern

#### Option 1: Autoload EventBus (Recommended)
```gdscript
# autoload/EventBus.gd
extends Node

signal step_changed(step_index: int)
signal parameter_changed(azgaar_key: String, value: Variant)
signal generate_requested(options: Dictionary)
signal generation_complete()
signal generation_failed(reason: String)
```

**Advantages:**
- ✅ Decouples modules completely
- ✅ Easy to add new modules
- ✅ No parent-child dependencies

**Disadvantages:**
- ⚠️ Requires autoload setup
- ⚠️ Global namespace pollution (mitigated by namespaced signals)

#### Option 2: Parent-Child Signal Forwarding
```gdscript
# WorldBuilderRoot.gd
func _ready():
    left_nav.step_changed.connect(_on_step_changed)
    right_controls.parameter_changed.connect(_on_parameter_changed)
    bottom_bar.generate_pressed.connect(_on_generate_pressed)
    
    # Forward to other modules
    func _on_step_changed(step: int):
        right_controls.update_step(step)
        # ... other updates
```

**Advantages:**
- ✅ No autoload needed
- ✅ Clear ownership (parent manages children)

**Disadvantages:**
- ⚠️ Parent must know all child signals
- ⚠️ Tighter coupling

#### Option 3: Hybrid (Recommended for Migration)
- Use **EventBus** for cross-module communication (step changes, generation events)
- Use **direct parent references** for UI updates (e.g., parent updates child visibility)

### Step-by-Step Refactor Plan

#### Phase 1: Extract Bottom Bar (2-3 hours)
1. Create `WorldBuilderBottomBar.tscn` with BottomBar structure
2. Create `WorldBuilderBottomBar.gd` script
3. Move button logic to script
4. Replace in `WorldBuilderUI.tscn` with instance
5. Connect signals via parent or EventBus
6. Test navigation and generation

**Node Count:** 8-10 nodes (isolated)

#### Phase 2: Extract Top Bar (1 hour)
1. Create `WorldBuilderTopBar.tscn` with TopBar structure
2. Create `WorldBuilderTopBar.gd` script (minimal, just title)
3. Replace in `WorldBuilderUI.tscn` with instance
4. Test display

**Node Count:** 3-4 nodes (isolated)

#### Phase 3: Extract Left Navigation (2-3 hours)
1. Create `WorldBuilderLeftNav.tscn` with LeftPanel structure
2. Create `WorldBuilderLeftNav.gd` script
3. Move step button logic to script
4. Emit `step_changed` signal
5. Replace in `WorldBuilderUI.tscn` with instance
6. Connect signals
7. Test step navigation

**Node Count:** 10-12 nodes (isolated)

#### Phase 4: Extract Right Controls (4-5 hours)
1. Create `WorldBuilderRightControls.tscn` with RightPanel structure
2. Create `WorldBuilderRightControls.gd` script
3. Move parameter management logic
4. Handle step updates via signal
5. Emit `parameter_changed` signals
6. Replace in `WorldBuilderUI.tscn` with instance
7. Connect signals
8. Test parameter editing and step changes

**Node Count:** 12-15 nodes (isolated, but ParamTree adds complexity)

#### Phase 5: Extract Center WebView (3-4 hours)
1. Create `WorldBuilderCenterWebView.tscn` with CenterPanel structure
2. Move `WorldBuilderAzgaar.gd` script reference
3. Ensure WebView node exists in scene
4. Handle WebView initialization in module
5. Emit generation signals
6. Replace in `WorldBuilderUI.tscn` with instance
7. Connect signals
8. Test WebView loading and generation

**Node Count:** 3-5 nodes (isolated, but WebView is external component)

#### Phase 6: Create Root Container (2-3 hours)
1. Create `WorldBuilderRoot.tscn` with MainVBox structure
2. Create `WorldBuilderRoot.gd` script
3. Instance all child modules in `_ready()`
4. Connect signals between modules
5. Handle overall state management
6. Replace `WorldBuilderUI.tscn` usage with `WorldBuilderRoot.tscn`

**Node Count:** 5-8 nodes (container only, children are instances)

#### Phase 7: Optimize and Polish (2-3 hours)
1. Add visibility culling (hide inactive modules)
2. Optimize signal connections
3. Profile performance before/after
4. Test all workflows
5. Update documentation

### Code Snippets: Module Instancing

#### Root Container Instancing
```gdscript
# WorldBuilderRoot.gd
extends Control

@onready var top_bar: Control = $MainVBox/TopBarInstance
@onready var left_nav: Control = $MainVBox/MainHSplit/LeftNavInstance
@onready var center_webview: Control = $MainVBox/MainHSplit/CenterWebViewInstance
@onready var right_controls: Control = $MainVBox/MainHSplit/RightControlsInstance
@onready var bottom_bar: Control = $MainVBox/BottomBarInstance

func _ready():
    # Instance modules (or load from PackedScene if needed)
    # Modules are already in scene tree as instances
    
    # Connect signals
    if left_nav.has_signal("step_changed"):
        left_nav.step_changed.connect(_on_step_changed)
    
    if right_controls.has_signal("parameter_changed"):
        right_controls.parameter_changed.connect(_on_parameter_changed)
    
    if bottom_bar.has_signal("generate_pressed"):
        bottom_bar.generate_pressed.connect(_on_generate_pressed)
    
    if center_webview.has_signal("generation_complete"):
        center_webview.generation_complete.connect(_on_generation_complete)

func _on_step_changed(step_index: int):
    right_controls.update_step(step_index)
    # Update other modules as needed
```

#### Dynamic Instancing (Alternative)
```gdscript
# WorldBuilderRoot.gd
const TOP_BAR_SCENE = preload("res://scenes/ui/world_builder/WorldBuilderTopBar.tscn")
const LEFT_NAV_SCENE = preload("res://scenes/ui/world_builder/WorldBuilderLeftNav.tscn")
# ... etc

func _ready():
    var main_vbox = $MainVBox
    
    # Instance and add modules
    var top_bar = TOP_BAR_SCENE.instantiate()
    main_vbox.add_child(top_bar)
    main_vbox.move_child(top_bar, 0)  # Move to top
    
    var main_hsplit = $MainVBox/MainHSplit
    
    var left_nav = LEFT_NAV_SCENE.instantiate()
    main_hsplit.add_child(left_nav)
    main_hsplit.move_child(left_nav, 0)
    
    # ... etc for other modules
```

### Signal Connection Examples

#### Left Navigation Module
```gdscript
# WorldBuilderLeftNav.gd
extends PanelContainer

signal step_changed(step_index: int)

@onready var step_sidebar: VBoxContainer = $LeftContent/StepSidebar
var step_buttons: Array[Button] = []

func _ready():
    for i in range(8):
        var btn = step_sidebar.get_child(i) as Button
        if btn:
            step_buttons.append(btn)
            btn.pressed.connect(func(): _on_step_button_pressed(i))

func _on_step_button_pressed(step_idx: int):
    emit_signal("step_changed", step_idx)
    _update_button_highlights(step_idx)

func _update_button_highlights(active_step: int):
    for i in range(step_buttons.size()):
        if i == active_step:
            step_buttons[i].modulate = Color(1.0, 0.7, 0.3, 1.0)  # Orange
        else:
            step_buttons[i].modulate = Color(0.6, 0.6, 0.6, 1.0)  # Dimmed
```

#### Right Controls Module
```gdscript
# WorldBuilderRightControls.gd
extends PanelContainer

signal parameter_changed(azgaar_key: String, value: Variant)

var current_step: int = 0
var current_params: Dictionary = {}
@onready var param_tree: Tree = $RightScroll/RightVBox/ParamTree

func update_step(step_index: int):
    current_step = step_index
    _populate_param_tree()

func _on_tree_item_edited():
    var edited_item = param_tree.get_selected()
    if not edited_item:
        return
    
    var metadata = edited_item.get_metadata(0)
    if not metadata or not metadata.has("azgaar_key"):
        return
    
    var azgaar_key = metadata.azgaar_key
    var new_value = _get_edited_value(edited_item, metadata.param)
    
    current_params[azgaar_key] = new_value
    emit_signal("parameter_changed", azgaar_key, new_value)
```

---

## Implementation Steps

### Detailed Migration Roadmap

#### Step 1: Backup and Preparation (30 minutes)
1. **Create backup branch:**
   ```bash
   git checkout -b backup/world-builder-ui-monolithic
   git push origin backup/world-builder-ui-monolithic
   ```

2. **Create feature branch:**
   ```bash
   git checkout -b feat/world-builder-modular-ui
   ```

3. **Create directory structure:**
   ```bash
   mkdir -p scenes/ui/world_builder/components
   ```

4. **Document current FPS baseline:**
   - Run project in debug mode
   - Note FPS in World Builder UI (idle, with WebView, during generation)
   - Record in migration notes

#### Step 2: Create EventBus Autoload (1 hour)
1. Create `autoload/EventBus.gd`:
```gdscript
# ╔═══════════════════════════════════════════════════════════
# ║ EventBus.gd
# ║ Desc: Central event bus for World Builder UI module communication
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

# World Builder UI signals
signal world_builder_step_changed(step_index: int)
signal world_builder_parameter_changed(azgaar_key: String, value: Variant)
signal world_builder_generate_requested(options: Dictionary)
signal world_builder_generation_complete()
signal world_builder_generation_failed(reason: String)
signal world_builder_archetype_changed(archetype_name: String)
signal world_builder_seed_changed(seed_value: int)
```

2. Add to `project.godot` autoloads:
```
[autoload]
EventBus="*res://autoload/EventBus.gd"
```

3. Test signal emission/reception in existing code

#### Step 3: Extract Bottom Bar Module (2-3 hours)
**Files to create:**
- `scenes/ui/world_builder/WorldBuilderBottomBar.tscn`
- `scripts/ui/world_builder/WorldBuilderBottomBar.gd`

**Steps:**
1. Open `WorldBuilderUI.tscn` in editor
2. Select `BottomBar` node and all children
3. Right-click → "Change Scene" → Save as `WorldBuilderBottomBar.tscn`
4. Create script `WorldBuilderBottomBar.gd`:
```gdscript
# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderBottomBar.gd
# ║ Desc: Bottom navigation bar for World Builder UI
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends PanelContainer

signal back_pressed
signal next_pressed
signal generate_pressed
signal bake_to_3d_pressed

@onready var back_btn: Button = $BottomContent/BackBtn
@onready var next_btn: Button = $BottomContent/NextBtn
@onready var gen_btn: Button = $BottomContent/GenBtn
@onready var bake_to_3d_btn: Button = $BottomContent/BakeTo3DBtn
@onready var progress_bar: ProgressBar = $BottomContent/ProgressBar
@onready var status_label: Label = $BottomContent/StatusLabel

func _ready():
    back_btn.pressed.connect(func(): emit_signal("back_pressed"))
    next_btn.pressed.connect(func(): emit_signal("next_pressed"))
    gen_btn.pressed.connect(func(): emit_signal("generate_pressed"))
    bake_to_3d_btn.pressed.connect(func(): emit_signal("bake_to_3d_pressed"))
    
    # Apply UIConstants
    var bottom_content = $BottomContent
    bottom_content.add_theme_constant_override("separation", UIConstants.SPACING_LARGE)
    back_btn.custom_minimum_size = Vector2(UIConstants.BUTTON_WIDTH_SMALL, 0)
    next_btn.custom_minimum_size = Vector2(UIConstants.BUTTON_WIDTH_SMALL, 0)
    gen_btn.custom_minimum_size = Vector2(UIConstants.BUTTON_WIDTH_LARGE, 0)
    bake_to_3d_btn.custom_minimum_size = Vector2(UIConstants.BUTTON_WIDTH_MEDIUM, 0)
    progress_bar.custom_minimum_size = Vector2(UIConstants.PROGRESS_BAR_WIDTH, 0)
    status_label.custom_minimum_size = Vector2(UIConstants.LABEL_WIDTH_STANDARD, 0)

func update_status(text: String, progress: float = -1.0):
    status_label.text = text
    if progress >= 0:
        progress_bar.value = progress
        progress_bar.visible = true
    else:
        progress_bar.visible = false

func update_navigation(current_step: int, total_steps: int):
    back_btn.disabled = (current_step == 0)
    next_btn.disabled = (current_step == total_steps - 1)
    
    # Show/hide buttons based on step
    if current_step == 6:  # Export step
        gen_btn.visible = true
        next_btn.visible = false
        bake_to_3d_btn.visible = false
    elif current_step == 7:  # Bake step
        gen_btn.visible = false
        next_btn.visible = false
        bake_to_3d_btn.visible = true
        bake_to_3d_btn.disabled = false
    else:
        gen_btn.visible = false
        next_btn.visible = true
        bake_to_3d_btn.visible = false
```

5. In `WorldBuilderUI.tscn`, replace `BottomBar` subtree with instance of `WorldBuilderBottomBar.tscn`
6. Update `WorldBuilderUI.gd` to use module signals
7. Test navigation and generation

#### Step 4: Extract Remaining Modules (10-15 hours)
Repeat Step 3 process for:
- TopBar (1 hour)
- LeftNav (2-3 hours)
- RightControls (4-5 hours)
- CenterWebView (3-4 hours)

**Key considerations:**
- **RightControls:** Most complex - handles ParamTree, parameter caching, step updates
- **CenterWebView:** Requires WebView node in scene - ensure godot_wry addon is available
- **LeftNav:** Simple but needs step highlighting logic

#### Step 5: Create Root Container (2-3 hours)
1. Create `WorldBuilderRoot.tscn` with minimal structure:
```
WorldBuilderRoot (Control, anchors_full_rect)
├── Background (ColorRect)
└── MainVBox (VBoxContainer)
    ├── MainHSplit (HSplitContainer)
    └── [Child module instances added via script or scene]
```

2. Create `WorldBuilderRoot.gd` to manage modules:
```gdscript
# ╔═══════════════════════════════════════════════════════════
# ║ WorldBuilderRoot.gd
# ║ Desc: Root container for modular World Builder UI
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Control

const TOP_BAR_SCENE = preload("res://scenes/ui/world_builder/WorldBuilderTopBar.tscn")
const LEFT_NAV_SCENE = preload("res://scenes/ui/world_builder/WorldBuilderLeftNav.tscn")
const CENTER_WEBVIEW_SCENE = preload("res://scenes/ui/world_builder/WorldBuilderCenterWebView.tscn")
const RIGHT_CONTROLS_SCENE = preload("res://scenes/ui/world_builder/WorldBuilderRightControls.tscn")
const BOTTOM_BAR_SCENE = preload("res://scenes/ui/world_builder/WorldBuilderBottomBar.tscn")

var top_bar: Control
var left_nav: Control
var center_webview: Control
var right_controls: Control
var bottom_bar: Control

var current_step: int = 0
var current_params: Dictionary = {}
var terrain_manager: Node = null

func _ready():
    _setup_ui()
    _connect_signals()
    _initialize_defaults()

func _setup_ui():
    var main_vbox = $MainVBox
    var main_hsplit = $MainVBox/MainHSplit
    
    # Instance modules
    top_bar = TOP_BAR_SCENE.instantiate()
    main_vbox.add_child(top_bar)
    main_vbox.move_child(top_bar, 0)
    
    left_nav = LEFT_NAV_SCENE.instantiate()
    main_hsplit.add_child(left_nav)
    main_hsplit.move_child(left_nav, 0)
    
    center_webview = CENTER_WEBVIEW_SCENE.instantiate()
    main_hsplit.add_child(center_webview)
    
    right_controls = RIGHT_CONTROLS_SCENE.instantiate()
    main_hsplit.add_child(right_controls)
    
    bottom_bar = BOTTOM_BAR_SCENE.instantiate()
    main_vbox.add_child(bottom_bar)

func _connect_signals():
    # Left nav → Root → Right controls
    if left_nav.has_signal("step_changed"):
        left_nav.step_changed.connect(_on_step_changed)
    
    # Right controls → Root → Center webview
    if right_controls.has_signal("parameter_changed"):
        right_controls.parameter_changed.connect(_on_parameter_changed)
    
    # Bottom bar → Root → Center webview
    if bottom_bar.has_signal("generate_pressed"):
        bottom_bar.generate_pressed.connect(_on_generate_pressed)
    if bottom_bar.has_signal("back_pressed"):
        bottom_bar.back_pressed.connect(_on_back_pressed)
    if bottom_bar.has_signal("next_pressed"):
        bottom_bar.next_pressed.connect(_on_next_pressed)
    
    # Center webview → Root → Bottom bar
    if center_webview.has_signal("generation_complete"):
        center_webview.generation_complete.connect(_on_generation_complete)
    if center_webview.has_signal("generation_failed"):
        center_webview.generation_failed.connect(_on_generation_failed)

func _on_step_changed(step_index: int):
    current_step = step_index
    right_controls.update_step(step_index)
    bottom_bar.update_navigation(step_index, 8)

func _on_parameter_changed(azgaar_key: String, value: Variant):
    current_params[azgaar_key] = value

func _on_generate_pressed():
    if center_webview.has_method("trigger_generation_with_options"):
        center_webview.trigger_generation_with_options(current_params, true)
        bottom_bar.update_status("Generating map...", 40)

func _on_generation_complete():
    bottom_bar.update_status("Generation complete!", 100)
    current_step = 7
    _on_step_changed(7)

func _on_generation_failed(reason: String):
    bottom_bar.update_status("Generation failed: %s" % reason, 0)

func _on_back_pressed():
    if current_step > 0:
        _on_step_changed(current_step - 1)

func _on_next_pressed():
    if current_step < 7:
        _on_step_changed(current_step + 1)

func _initialize_defaults():
    _on_step_changed(0)

func set_terrain_manager(manager: Node):
    terrain_manager = manager
    if center_webview.has_method("set_terrain_manager"):
        center_webview.set_terrain_manager(manager)
```

3. Update `world_root.gd` to use `WorldBuilderRoot.tscn` instead of `WorldBuilderUI.tscn`

#### Step 6: Testing and Validation (3-4 hours)
1. **Functional Testing:**
   - Test all 8 steps navigation
   - Test parameter editing
   - Test generation flow
   - Test bake to 3D
   - Test archetype presets
   - Test seed randomization

2. **Performance Testing:**
   - Measure FPS before/after
   - Profile with Godot Profiler
   - Check draw calls
   - Verify no memory leaks

3. **Edge Cases:**
   - Test with WebView disabled
   - Test with invalid parameters
   - Test rapid step switching
   - Test window resize

#### Step 7: Optimization (2-3 hours)
1. **Visibility Culling:**
   - Hide inactive modules when possible
   - Use `visible = false` and `process_mode = DISABLED`

2. **Signal Optimization:**
   - Remove redundant signal connections
   - Use one-shot signals where appropriate

3. **Performance Profiling:**
   - Use Godot Profiler to identify remaining bottlenecks
   - Optimize hot paths

---

## Potential Challenges and Mitigations

### Challenge 1: WebView Initialization Timing
**Issue:** WebView may not be ready when module is instantiated  
**Mitigation:**
- Use `call_deferred()` for WebView initialization
- Check `web_view != null` before JS execution
- Add retry logic with timeout

### Challenge 2: Parameter Tree Complexity
**Issue:** ParamTree is complex and tightly coupled to step definitions  
**Mitigation:**
- Keep Tree in RightControls module (isolated)
- Consider future replacement with VBoxContainer of ParamRow scenes
- Maintain caching system for performance

### Challenge 3: Signal Spaghetti
**Issue:** Too many signals between modules can become hard to manage  
**Mitigation:**
- Use EventBus for cross-module communication (centralized)
- Document signal flow in comments
- Use signal namespacing (e.g., `world_builder_*`)

### Challenge 4: Node Path Breaking
**Issue:** Deep `@onready var` paths break when nodes move  
**Mitigation:**
- Use `%` unique node names for critical nodes
- Use `get_node_or_null()` with fallbacks
- Prefer signal communication over direct node access

### Challenge 5: Performance Regression
**Issue:** Modularization might not improve performance if not done carefully  
**Mitigation:**
- Profile before/after each phase
- Use `visible = false` and `process_mode = DISABLED` for inactive modules
- Limit module count (target: 5-7 modules, not 20+)

### Challenge 6: godot_wry Compatibility
**Issue:** WebView node must exist in scene tree at initialization  
**Mitigation:**
- Keep WebView node in `WorldBuilderCenterWebView.tscn` scene
- Don't try to create WebView dynamically
- Test on all target platforms

---

## Recommendations and Next Steps

### Immediate Actions (Week 1)
1. **Create EventBus autoload** - Foundation for module communication
2. **Extract BottomBar module** - Lowest risk, validates approach
3. **Profile baseline performance** - Document current FPS/metrics

### Short-Term (Weeks 2-3)
1. **Extract remaining modules** - TopBar, LeftNav, RightControls, CenterWebView
2. **Create Root container** - Orchestrate modules
3. **Functional testing** - Ensure all workflows work

### Medium-Term (Week 4)
1. **Performance optimization** - Visibility culling, signal optimization
2. **Edge case testing** - Handle error scenarios
3. **Documentation** - Update API docs, migration notes

### Long-Term (Future)
1. **Replace ParamTree with ParamRow scenes** - Further modularization
2. **Add 3D preview toggle** - SubViewport for Terrain3D
3. **Add tooltips** - Parameter descriptions
4. **Performance monitoring** - Built-in FPS overlay for World Builder

### Tools and Best Practices

#### Scene Inheritance
Use Godot's scene inheritance for reusable components:
- `StepButton.tscn` (base) → `StepButton1.tscn`, `StepButton2.tscn`, etc.
- Reduces duplication

#### Data-Driven Parameters
Keep parameter definitions in JSON:
- Easy to modify without code changes
- Supports modding
- Enables dynamic UI generation

#### Profiling Strategy
1. **Before migration:** Profile monolithic UI
2. **After each phase:** Profile and compare
3. **Final:** Profile complete modular UI
4. **Use Godot Profiler:** Focus on `_process()`, `_draw()`, draw calls

#### Testing Strategy
1. **Unit tests:** Test each module in isolation
2. **Integration tests:** Test module interactions
3. **Performance tests:** Measure FPS, draw calls, memory
4. **User acceptance:** Test full workflow end-to-end

---

## Appendices

### Appendix A: Current Node Tree Dump
```
WorldBuilderUI (Control)
├── Background (ColorRect)
└── MainVBox (VBoxContainer)
    ├── TopBar (PanelContainer)
    │   └── TopBarContent (CenterContainer)
    │       └── TitleLabel (Label)
    ├── MainHSplit (HSplitContainer)
    │   ├── LeftPanel (PanelContainer)
    │   │   └── LeftContent (VBoxContainer)
    │   │       └── StepSidebar (VBoxContainer)
    │   │           ├── Step1Btn (Button)
    │   │           ├── Step2Btn (Button)
    │   │           ├── Step3Btn (Button)
    │   │           ├── Step4Btn (Button)
    │   │           ├── Step5Btn (Button)
    │   │           ├── Step6Btn (Button)
    │   │           ├── Step7Btn (Button)
    │   │           └── Step8Btn (Button)
    │   ├── CenterPanel (PanelContainer)
    │   │   └── CenterContent (Control) [WorldBuilderAzgaar script]
    │   │       └── OverlayPlaceholder (TextureRect)
    │   └── RightPanel (PanelContainer)
    │       └── RightScroll (ScrollContainer)
    │           └── RightVBox (VBoxContainer)
    │               ├── ArchetypeLabel (Label)
    │               ├── ArchetypeOption (OptionButton)
    │               ├── SeedLabel (Label)
    │               ├── SeedHBox (HBoxContainer)
    │               │   ├── SeedSpin (SpinBox)
    │               │   └── RandomizeBtn (Button)
    │               ├── SectionSep (HSeparator)
    │               ├── StepTitle (Label)
    │               └── ParamTree (Tree)
    └── BottomBar (PanelContainer)
        └── BottomContent (HBoxContainer)
            ├── SpacerLeft (Control)
            ├── BackBtn (Button)
            ├── GenBtn (Button)
            ├── BakeTo3DBtn (Button)
            ├── NextBtn (Button)
            ├── ProgressBar (ProgressBar)
            ├── StatusLabel (Label)
            └── SpacerRight (Control)

Total: 43 nodes
```

### Appendix B: Proposed Modular Tree Structure
```
WorldBuilderRoot (Control)
├── Background (ColorRect)
└── MainVBox (VBoxContainer)
    ├── TopBarInstance (WorldBuilderTopBar) [3-4 nodes]
    ├── MainHSplit (HSplitContainer)
    │   ├── LeftNavInstance (WorldBuilderLeftNav) [10-12 nodes]
    │   ├── CenterWebViewInstance (WorldBuilderCenterWebView) [3-5 nodes]
    │   └── RightControlsInstance (WorldBuilderRightControls) [12-15 nodes]
    └── BottomBarInstance (WorldBuilderBottomBar) [8-10 nodes]

Total: 5-8 nodes in root + 36-46 nodes in modules = 41-54 nodes total
(Similar count, but better organized and cullable)
```

### Appendix C: Signal Flow Diagram
```
┌─────────────────┐
│  LeftNav        │
│  (Step Buttons) │
└────────┬────────┘
         │ step_changed(step_index)
         ▼
┌─────────────────┐
│  WorldBuilder   │
│  Root           │
└────────┬────────┘
         │ update_step(step_index)
         ▼
┌─────────────────┐      ┌─────────────────┐
│  RightControls  │      │  BottomBar      │
│  (Parameters)   │      │  (Navigation)   │
└────────┬────────┘      └────────┬────────┘
         │                         │
         │ parameter_changed()     │ generate_pressed()
         │                         │
         ▼                         ▼
┌─────────────────┐      ┌─────────────────┐
│  CenterWebView  │      │  CenterWebView   │
│  (Azgaar)       │      │  (Azgaar)       │
└────────┬────────┘      └────────┬────────┘
         │                         │
         │ generation_complete()   │ generation_failed()
         │                         │
         ▼                         ▼
┌─────────────────┐      ┌─────────────────┐
│  BottomBar      │      │  BottomBar       │
│  (Status)       │      │  (Status)        │
└─────────────────┘      └─────────────────┘
```

### Appendix D: Performance Baseline (from audit)
**Current Performance (Monolithic):**
- **Idle FPS:** ~5 FPS (with performance monitors)
- **Idle FPS (monitors off):** ~30-40 FPS
- **During generation:** ~2-3 FPS
- **Draw calls:** ~20-30 per frame
- **Node count:** 43 nodes in single scene

**Target Performance (Modular):**
- **Idle FPS:** 60+ FPS (with visibility culling)
- **During generation:** 30+ FPS
- **Draw calls:** 15-25 per frame (fewer with culling)
- **Node count:** Similar, but organized in modules

**Expected Improvements:**
- ✅ Faster initial load (smaller scenes load faster)
- ✅ Better visibility culling (hide inactive modules)
- ✅ Reduced tree traversal (shallow hierarchies)
- ✅ Easier debugging (isolated modules)

---

## Conclusion

The migration from monolithic `WorldBuilderUI.tscn` to a modular architecture is **highly feasible** with **~70% code reusability**. The main effort lies in breaking the 43-node scene into 5-7 modular scenes and establishing communication patterns via signals or EventBus.

**Key Success Factors:**
1. ✅ **WebView integration is solid** - godot_wry provides full JS execution and IPC
2. ✅ **Data-driven parameters** - JSON configs make refactoring easier
3. ✅ **Existing optimizations** - Caching, throttling already in place
4. ✅ **Clear module boundaries** - Natural separation (Left, Center, Right, Bottom)

**Risks to Mitigate:**
1. ⚠️ **Signal complexity** - Use EventBus to centralize communication
2. ⚠️ **WebView timing** - Ensure proper initialization order
3. ⚠️ **Performance regression** - Profile at each phase

**Recommended Approach:**
- **Phase 1:** Extract BottomBar (validate approach)
- **Phase 2:** Extract remaining modules incrementally
- **Phase 3:** Create Root container and integrate
- **Phase 4:** Optimize and polish

**Estimated Timeline:** 15-25 hours over 3-4 weeks

**Next Step:** Create EventBus autoload and extract BottomBar module as proof of concept.

---

**Report Generated:** 2025-12-27  
**Author:** Cursor AI (Auto)  
**Status:** Ready for Implementation
