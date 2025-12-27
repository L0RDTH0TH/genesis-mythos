# WebView UI Migration Phase 2 Preparation Report

**Date:** 2025-12-27  
**Phase:** Phase 2 Preparation (Alpine.js Integration & Wizard Migration)  
**Status:** Investigation Complete - Ready for Implementation

---

## Executive Summary

This report investigates the current state of **WorldBuilderUI** and **CharacterCreationRoot** implementations to prepare for Phase 2 of the WebView UI migration. Phase 2 will migrate complex wizard-style UIs to WebView-based interfaces using Alpine.js for reactivity.

**Key Findings:**
- **WorldBuilderUI** is partially WebView-based (uses godot_wry for Azgaar integration) but still has native Control nodes for wizard steps
- **CharacterCreationRoot** uses native Control nodes with SubViewport for 3D preview
- Both systems use JSON data files and signal-based communication
- Alpine.js 3.15.3 minified has been fetched and saved to `res://web_ui/shared/alpine.min.js`
- Bridge.js is compatible with Alpine.js (no conflicts - Alpine uses `x-` attributes, bridge uses `window.GodotBridge`)

**Recommended Starting Point:** **WorldBuilderUI** (already partially WebView-based, simpler migration path)

---

## 1. Current WorldBuilderUI Implementation

### 1.1 Scene Structure

**Path:** `res://ui/world_builder/WorldBuilderUI.tscn`

**Root Node:** `Control` (anchors_preset = PRESET_FULL_RECT, theme = bg3_theme.tres)

**Node Hierarchy:**
```
WorldBuilderUI (Control)
├── Background (ColorRect, dark brown)
├── MainVBox (VBoxContainer)
│   ├── TopBar (PanelContainer)
│   │   └── TopBarContent (CenterContainer)
│   │       └── TitleLabel ("World Builder – Forging the World")
│   ├── MainHSplit (HSplitContainer)
│   │   ├── LeftPanel (PanelContainer, ~220px width)
│   │   │   └── LeftContent (VBoxContainer)
│   │   │       └── StepSidebar (VBoxContainer)
│   │   │           ├── Step1Btn (Button) - "1. Map Generation & Editing"
│   │   │           ├── Step2Btn (Button) - "2. Terrain"
│   │   │           ├── Step3Btn (Button) - "3. Climate"
│   │   │           ├── Step4Btn (Button) - "4. Biomes"
│   │   │           ├── Step5Btn (Button) - "5. Structures & Civilizations"
│   │   │           ├── Step6Btn (Button) - "6. Environment"
│   │   │           ├── Step7Btn (Button) - "7. Resources & Magic"
│   │   │           └── Step8Btn (Button) - "8. Export"
│   │   ├── CenterPanel (PanelContainer, expand_fill)
│   │   │   └── CenterContent (Control) - WorldBuilderAzgaar script attached
│   │   │       └── OverlayPlaceholder (TextureRect, hidden)
│   │   └── RightPanel (PanelContainer, ~240px width)
│   │       └── RightOuterVBox (VBoxContainer)
│   │           ├── ArchetypeOption (OptionButton)
│   │           ├── SeedHBox (HBoxContainer)
│   │           │   ├── SeedSpin (SpinBox)
│   │           │   └── RandomizeBtn (Button)
│   │           └── RightScroll (ScrollContainer)
│   │               └── RightVBox (VBoxContainer)
│   │                   ├── StepTitle (Label)
│   │                   └── ParamTree (Tree, 3 columns, hide_root=true)
│   └── BottomBar (PanelContainer)
│       └── BottomContent (HBoxContainer)
│           ├── SpacerLeft (Control, expand_fill)
│           ├── BackBtn (Button)
│           ├── GenBtn (Button) - "✨ Generate / Apply Changes"
│           ├── BakeTo3DBtn (Button, disabled, hidden)
│           ├── NextBtn (Button)
│           ├── ProgressBar (ProgressBar, hidden)
│           └── StatusLabel (Label)
```

### 1.2 Script Logic

**Path:** `res://ui/world_builder/WorldBuilderUI.gd`

**Key Variables:**
- `current_step: int = 0` (0-7, 8 total steps)
- `TOTAL_STEPS: int = 8`
- `STEP_DEFINITIONS: Dictionary` (loaded from JSON)
- `current_params: Dictionary` (Azgaar parameters)
- `param_tree_items: Dictionary` (maps azgaar_key -> TreeItem)

**Key Functions:**
- `_ready()` - Initializes UI, loads step definitions, connects signals
- `_load_step_definitions()` - Loads from `res://data/config/azgaar_step_parameters.json`
- `_load_archetype_params(index: int)` - Loads archetype preset (High Fantasy, Low Fantasy, etc.)
- `_on_step_button_pressed(step: int)` - Handles step navigation
- `_on_back_pressed()` / `_on_next_pressed()` - Wizard navigation
- `_generate_azgaar()` - Triggers Azgaar map generation
- `_update_step_ui()` - Updates UI for current step
- `_setup_param_tree()` - Populates Tree with parameters for current step

**Signal Connections:**
- Step buttons → `_on_step_button_pressed(step)`
- ArchetypeOption → `_load_archetype_params(index)`
- SeedSpin → `_on_seed_changed(value)`
- RandomizeBtn → `_randomize_seed()`
- BackBtn → `_on_back_pressed()`
- NextBtn → `_on_next_pressed()`
- GenBtn → `_generate_azgaar()`

### 1.3 Azgaar Integration

**Path:** `res://scripts/ui/WorldBuilderAzgaar.gd`

**Current Implementation:**
- Uses godot_wry `WebView` node (embedded in CenterPanel)
- Loads Azgaar Fantasy Map Generator via HTTP server (`AzgaarServer` singleton)
- URL: `http://127.0.0.1:8080/azgaar/index.html`
- Communication: JavaScript execution via `execute_js()` / `eval()`, IPC via `ipc_message` signal
- Bridge pattern: Injects bridge script to create `window.godot.postMessage()` function

**Key Methods:**
- `_initialize_azgaar()` - Sets up WebView and loads Azgaar URL
- `_inject_bridge()` - Injects JavaScript bridge for IPC
- `_on_ipc_message(message: String)` - Handles messages from Azgaar WebView
- `_sync_params_to_azgaar()` - Sends parameter updates to Azgaar via JavaScript

**Dependencies:**
- `AzgaarServer` singleton (autoload) - HTTP server for serving Azgaar assets
- `AzgaarIntegrator` singleton (autoload) - Manages Azgaar asset copying and URL generation

### 1.4 Step Wizard Details

**Step Definitions Source:** `res://data/config/azgaar_step_parameters.json`

**Step Structure:**
Each step has:
- `step_name: String` - Display name
- `step_description: String` - Description text
- `parameters: Array[Dictionary]` - List of Azgaar parameters
  - Each parameter has: `azgaar_key`, `display_name`, `type` (int/float/bool), `default_value`, `min`, `max`, `tooltip`

**Archetype Presets:**
- "High Fantasy" - 800k points, heightExponent 1.2, 8 plates, 500 burgs
- "Low Fantasy" - 600k points, heightExponent 0.8, 5 plates, 200 burgs
- "Dark Fantasy" - 400k points, heightExponent 1.5, 12 plates, 100 burgs
- "Realistic" - 1M points, heightExponent 1.0, 7 plates, 800 burgs
- "Custom" - Empty (user-defined)

**Wizard Flow:**
1. User selects archetype → loads preset parameters
2. User navigates steps (1-8) → updates `current_step`, shows relevant parameters in Tree
3. User modifies parameters in Tree → updates `current_params` Dictionary
4. User clicks "Generate" → calls `_generate_azgaar()` → sends params to Azgaar via JavaScript
5. Azgaar generates map → displays in CenterPanel WebView
6. User can "Bake to 3D" (future feature, button disabled)

---

## 2. Current CharacterCreation Implementation

### 2.1 Scene Structure

**Path:** `res://scenes/character_creation/CharacterCreationRoot.tscn`

**Root Node:** `Control` (anchors_preset = PRESET_FULL_RECT)

**Node Hierarchy:**
```
CharacterCreationRoot (Control)
└── MainContainer (VBoxContainer)
    ├── TitleArea (MarginContainer)
    │   └── TitleLabel (Label) - "Character Creation"
    ├── ContentArea (HSplitContainer)
    │   ├── LeftPanel (Panel, 60% width)
    │   │   └── LeftContent (VBoxContainer)
    │   │       └── OptionsContainer (VBoxContainer) - Dynamic tab content
    │   └── RightPanel (Panel, 40% width)
    │       └── PreviewContainer (SubViewportContainer, stretch=true)
    │           └── PreviewViewport (SubViewport, 512x512)
    │               └── PreviewWorld (Node3D)
    │                   ├── CharacterPreview3D (Node3D) - CharacterPreview3D.gd script
    │                   ├── PreviewCamera (Camera3D)
    │                   └── PreviewLight (DirectionalLight3D)
    └── NavigationArea (HBoxContainer)
        ├── SpacerLeft (Control, expand_fill)
        ├── BackButton (Button, %BackButton)
        ├── SpacerMiddle (Control, expand_fill)
        └── NextButton (Button, %NextButton)
```

### 2.2 Script Logic

**Path:** `res://scripts/character_creation/CharacterCreationRoot.gd`

**Key Variables:**
- `STEPS: Array[String]` - ["Race", "Class", "Background", "Ability Scores", "Appearance", "Name & Confirm"]
- `TAB_SCENES: Array[String]` - Paths to tab scene files
- `current_step: int = 0` (0-5, 6 total steps)
- `step_data: Dictionary` - Stores selections from each step
- `current_tab_instance: Control` - Currently loaded tab scene instance

**Key Functions:**
- `_ready()` - Initializes UI, applies UIConstants, sets up navigation
- `_load_step(step_index: int)` - Loads tab scene for step, instantiates as child of OptionsContainer
- `_on_back_pressed()` / `_on_next_pressed()` - Wizard navigation
- `_save_step_data()` - Saves current step data to `step_data` Dictionary
- `_update_preview_appearance(appearance_data: Dictionary)` - Updates 3D preview
- `_connect_tab_signals(tab_instance: Control, step_index: int)` - Connects tab signals

**Signal Handlers:**
- `_on_race_selected(race_id: String, race_data: Dictionary)`
- `_on_class_selected(class_id: String, class_data: Dictionary)`
- `_on_background_selected(background_id: String, background_data: Dictionary)`
- `_on_ability_scores_changed(scores: Dictionary)`
- `_on_appearance_changed(appearance_data: Dictionary)`
- `_on_character_confirmed(character_data: Dictionary)`

### 2.3 Tab Scenes & Scripts

**Tab Scene Paths:**
1. `res://scenes/character_creation/tabs/RaceTab.tscn` → `RaceTab.gd`
2. `res://scenes/character_creation/tabs/ClassTab.tscn` → `ClassTab.gd`
3. `res://scenes/character_creation/tabs/BackgroundTab.tscn` → `BackgroundTab.gd`
4. `res://scenes/character_creation/tabs/AbilityScoreTab.tscn` → `AbilityScoreTab.gd`
5. `res://scenes/character_creation/tabs/AppearanceTab.tscn` → `AppearanceTab.gd`
6. `res://scenes/character_creation/tabs/NameConfirmTab.tscn` → `NameConfirmTab.gd`

**Tab Script Pattern:**
- Each tab extends `Control`
- Loads data from JSON files (via `GameData` singleton)
- Emits signals when selections change (e.g., `race_selected`, `class_selected`)
- Uses native Godot UI nodes (ItemList, OptionButton, GridContainer, etc.)

**Example: RaceTab.gd**
- Loads `res://data/races.json` via `GameData.races`
- Populates `ItemList` with race names
- On selection, emits `race_selected(race_id, race_data)` signal
- Displays race description and traits in Labels

### 2.4 JSON Data Files

**Data Sources:**
- `res://data/races.json` - Race definitions (id, name, description, traits, ability_bonuses, subraces)
- `res://data/classes.json` - Class definitions (id, name, description, proficiencies, features, subclasses)
- `res://data/backgrounds.json` - Background definitions
- `res://data/abilities.json` - Ability score definitions
- `res://data/appearance_presets.json` - Appearance customization options

**Loader:** `GameData` singleton (autoload) - Loads all JSON files in `_ready()`, provides typed arrays (`Array[Dictionary]`)

### 2.5 3D Preview Render-to-Texture Logic

**Current Implementation:**
- Uses `SubViewport` (`PreviewViewport`) with `SubViewportContainer` (`PreviewContainer`)
- `SubViewportContainer.stretch = true` (automatic sizing)
- `CharacterPreview3D` script manages 3D model (currently placeholder cylinder/sphere)
- Camera positioned at `Vector3(0, 1.6, 2.5)` looking at `Vector3(0, 1.6, 0)`

**Render-to-Texture Approach (for WebView migration):**
```gdscript
# In CharacterCreationRoot.gd (future implementation)
func _update_preview_texture() -> void:
    """Render 3D preview to texture and send to WebView."""
    var viewport: SubViewport = preview_viewport
    await RenderingServer.frame_post_draw
    
    var image: Image = viewport.get_texture().get_image()
    var png_bytes: PackedByteArray = image.save_png_to_buffer()
    var base64: String = Marshalls.raw_to_base64(png_bytes)
    
    # Send to WebView via bridge
    web_view_bridge.send_update("preview_texture", {
        "image_data": "data:image/png;base64," + base64
    })
```

**Update Frequency:**
- On appearance change (via `_on_appearance_changed` signal)
- Periodically (every 0.1s) or on-demand via IPC message from WebView

---

## 3. Alpine.js Integration Readiness

### 3.1 Alpine.js File Status

**Path:** `res://web_ui/shared/alpine.min.js`

**Status:** ✅ **Fetched and Saved**

- **Source:** `https://unpkg.com/alpinejs@3.15.3/dist/cdn.min.js`
- **Version:** 3.15.3 (latest stable)
- **Size:** ~46KB minified
- **Inclusion:** `<script src="../shared/alpine.min.js" defer></script>` in HTML files

### 3.2 Bridge.js Compatibility

**Path:** `res://web_ui/shared/bridge.js`

**Compatibility:** ✅ **Fully Compatible**

**Analysis:**
- Alpine.js uses `x-` attributes (e.g., `x-data`, `x-show`, `x-for`) - no namespace conflicts
- Bridge.js uses `window.GodotBridge` namespace - no conflicts
- Alpine.js initializes via `Alpine.start()` (auto-called on load)
- Bridge.js initializes immediately (no initialization conflicts)

**Integration Pattern:**
```html
<!DOCTYPE html>
<html>
<head>
    <link rel="stylesheet" href="world_builder.css">
</head>
<body>
    <div x-data="{ currentStep: 0, steps: [...] }">
        <!-- Alpine.js reactive UI -->
    </div>
    <script src="../shared/bridge.js"></script>
    <script src="../shared/alpine.min.js" defer></script>
    <script src="world_builder.js"></script>
</body>
</html>
```

**Note:** Load order: bridge.js first (for IPC), then Alpine.js (for reactivity), then app-specific JS.

### 3.3 Alpine.js Usage in Wizards

**Recommended Patterns:**

1. **Wizard State Management:**
```javascript
// In world_builder.js
Alpine.data('worldBuilder', () => ({
    currentStep: 0,
    totalSteps: 8,
    archetype: 'High Fantasy',
    seed: 12345,
    params: {},
    
    nextStep() {
        if (this.currentStep < this.totalSteps - 1) {
            this.currentStep++;
        }
    },
    
    previousStep() {
        if (this.currentStep > 0) {
            this.currentStep--;
        }
    }
}));
```

2. **Reactive Parameter Tree:**
```html
<div x-data="worldBuilder">
    <template x-for="(param, index) in currentStepParams" :key="index">
        <div class="param-row">
            <label x-text="param.display_name"></label>
            <input type="number" x-model="params[param.azgaar_key]" 
                   :min="param.min" :max="param.max">
        </div>
    </template>
</div>
```

3. **Step Navigation:**
```html
<div x-data="worldBuilder">
    <button @click="previousStep()" :disabled="currentStep === 0">Back</button>
    <button @click="nextStep()" :disabled="currentStep === totalSteps - 1">Next</button>
</div>
```

---

## 4. Recommended Phase 2 Starting Point

### 4.1 WorldBuilderUI (Recommended)

**Rationale:**
1. **Already Partially WebView-Based:** CenterPanel uses godot_wry WebView for Azgaar integration
2. **Simpler Migration:** Only need to migrate LeftPanel (step sidebar) and RightPanel (parameter tree) to WebView
3. **Existing Bridge Pattern:** `WorldBuilderAzgaar.gd` already implements IPC bridge pattern
4. **Clear Separation:** Wizard UI (WebView) vs. Map Preview (existing WebView) - clean architecture

**Migration Scope:**
- **Migrate to WebView:**
  - LeftPanel (step sidebar buttons)
  - RightPanel (archetype selector, seed controls, parameter tree)
  - BottomBar (navigation buttons, progress bar)
- **Keep Native:**
  - CenterPanel WebView (already WebView-based, no change needed)
  - Background ColorRect (can stay native or move to WebView CSS)

**Implementation Steps:**
1. Create `res://web_ui/world_builder/index.html` with Alpine.js wizard UI
2. Create `res://web_ui/world_builder/world_builder.js` with Alpine.js data and methods
3. Create `res://web_ui/world_builder/world_builder.css` with theme-matching styles
4. Create `res://scripts/ui/WorldBuilderWebController.gd` to manage WebView
5. Update `WorldBuilderUI.tscn` to use WebView instead of native Controls
6. Implement IPC communication for:
   - Step navigation (`current_step` sync)
   - Parameter updates (`current_params` sync)
   - Archetype/seed changes
   - Generate button → trigger `_generate_azgaar()`

### 4.2 CharacterCreationRoot (Future Phase)

**Rationale:**
1. **More Complex:** 6 tabs with different UI patterns (RaceTab uses GridContainer, ClassTab uses split layout)
2. **3D Preview Challenge:** Requires render-to-texture approach (more complex than WorldBuilderUI)
3. **More Data Dependencies:** Multiple JSON files, GameData singleton dependencies
4. **Better to Migrate After WorldBuilderUI:** Learn from WorldBuilderUI migration patterns

**Migration Scope (Future):**
- **Migrate to WebView:**
  - LeftPanel (all 6 tab UIs)
  - NavigationArea (back/next buttons)
- **Keep Native (or Render-to-Texture):**
  - RightPanel 3D preview (SubViewport → base64 image → WebView `<img>`)

---

## 5. Potential Gotchas

### 5.1 WorldBuilderUI Gotchas

1. **Parameter Tree Complexity:**
   - Current implementation uses Godot `Tree` node with 3 columns (parameter name, value input, tooltip)
   - WebView equivalent: HTML table or Alpine.js `x-for` with custom input components
   - **Solution:** Use Alpine.js reactive array with `x-for` directive, bind inputs to `x-model`

2. **Step Definitions JSON Loading:**
   - Currently loaded in GDScript via `_load_step_definitions()`
   - WebView needs to request JSON via IPC bridge
   - **Solution:** Implement `GodotBridge.requestData("step_definitions")` → GDScript responds with JSON

3. **Azgaar Parameter Syncing:**
   - Current: GDScript updates `current_params` → sends to Azgaar via JavaScript
   - WebView: WebView updates params → sends to GDScript via IPC → GDScript sends to Azgaar
   - **Solution:** Bidirectional sync: WebView → GDScript → Azgaar (for generation), Azgaar → GDScript → WebView (for updates)

4. **Progress Bar Updates:**
   - Current: GDScript updates `progress_bar.value` during generation
   - WebView: GDScript sends progress updates via IPC → WebView updates Alpine.js reactive property
   - **Solution:** Implement `GodotBridge._handleUpdate()` in WebView JS to update progress

5. **Archetype Preset Loading:**
   - Current: ArchetypeOption selection → `_load_archetype_params(index)` → updates Tree
   - WebView: Select dropdown → send IPC message → GDScript responds with preset params → update Alpine.js data
   - **Solution:** IPC message type `"load_archetype"` with `{archetype_name: string}` → GDScript responds with `{params: Dictionary}`

### 5.2 CharacterCreationRoot Gotchas

1. **3D Preview Render-to-Texture:**
   - SubViewport → Image → base64 → WebView `<img>` requires periodic updates
   - Performance: Rendering every frame is expensive
   - **Solution:** Update only on appearance change or every 0.1s (throttled)

2. **Tab Scene Instantiation:**
   - Current: Loads `.tscn` files and instantiates as children
   - WebView: No scene instantiation - all HTML/JS in single WebView
   - **Solution:** Use Alpine.js `x-show` / `x-if` to show/hide tab content based on `current_step`

3. **JSON Data Loading:**
   - Current: `GameData` singleton loads all JSON files in `_ready()`
   - WebView: Needs to request data via IPC bridge
   - **Solution:** Implement `GodotBridge.requestData("races")`, `requestData("classes")`, etc. → GDScript responds with JSON

4. **Signal-Based Communication:**
   - Current: Tabs emit signals (e.g., `race_selected`) → CharacterCreationRoot handles
   - WebView: No signals - use IPC messages
   - **Solution:** Replace signals with IPC messages: `GodotBridge.postMessage("race_selected", {race_id, race_data})`

5. **Ability Score Calculation:**
   - Current: RaceTab selection → updates racial bonuses → AbilityScoreTab receives via signal
   - WebView: Need to maintain state in Alpine.js, sync with GDScript
   - **Solution:** Alpine.js reactive `abilityScores` object, sync on step change via IPC

---

## 6. Folder Readiness

### 6.1 Current Status

**Existing Folders:**
- ✅ `res://web_ui/` - Created in Phase 1
- ✅ `res://web_ui/main_menu/` - Phase 1 implementation
- ✅ `res://web_ui/shared/` - Phase 1 implementation (bridge.js, alpine.min.js)

**Missing Folders (for Phase 2):**
- ❌ `res://web_ui/world_builder/` - **Does not exist** (will be created in Phase 2)
- ❌ `res://web_ui/character_creation/` - **Does not exist** (future phase)

### 6.2 Required Folder Structure (Phase 2)

```
res://web_ui/
├── main_menu/          # Phase 1 (complete)
│   ├── index.html
│   ├── main_menu.css
│   └── main_menu.js
├── shared/             # Phase 1 (complete)
│   ├── bridge.js
│   └── alpine.min.js   # Phase 2 (just added)
└── world_builder/       # Phase 2 (to be created)
    ├── index.html
    ├── world_builder.css
    └── world_builder.js
```

---

## 7. Implementation Checklist (Phase 2 - WorldBuilderUI)

### 7.1 Preparation (Complete)
- [x] Fetch Alpine.js 3.15.3 minified
- [x] Verify bridge.js compatibility
- [x] Investigate WorldBuilderUI structure
- [x] Investigate CharacterCreationRoot structure
- [x] Generate preparation report

### 7.2 WorldBuilderUI Migration (To Do)
- [ ] Create `res://web_ui/world_builder/` folder
- [ ] Create `index.html` with Alpine.js wizard UI structure
- [ ] Create `world_builder.css` with theme-matching styles
- [ ] Create `world_builder.js` with Alpine.js data and IPC handlers
- [ ] Create `WorldBuilderWebController.gd` script
- [ ] Update `WorldBuilderUI.tscn` to use WebView
- [ ] Implement IPC handlers for:
  - [ ] Step navigation
  - [ ] Archetype selection
  - [ ] Seed changes
  - [ ] Parameter updates
  - [ ] Generate button
  - [ ] Progress updates
- [ ] Test wizard flow (step navigation, parameter editing, generation)
- [ ] Test Azgaar integration (parameter syncing, map generation)
- [ ] Commit: `"feat/genesis: Migrate WorldBuilderUI to WebView with Alpine.js (Phase 2 complete)"`

---

## 8. Next Steps

1. **Immediate:** Review this report and approve Phase 2 implementation plan
2. **Phase 2 Implementation:** Migrate WorldBuilderUI to WebView with Alpine.js
3. **Phase 3 (Future):** Migrate CharacterCreationRoot to WebView with Alpine.js
4. **Phase 4 (Future):** Migrate remaining native UIs (Settings, Inventory, etc.)

---

**Report Generated:** 2025-12-27  
**Investigation Method:** MCP tools (read_file, codebase_search, grep)  
**Files Analyzed:** 15+ files (scenes, scripts, JSON configs)  
**Status:** Ready for Phase 2 Implementation

