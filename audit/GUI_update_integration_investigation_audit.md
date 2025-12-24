# GUI Update Integration Investigation Audit

**Generated:** 2025-01-20  
**Purpose:** Comprehensive analysis and migration plan for transitioning World Builder UI from current local procedural implementation to Azgaar Fantasy Map Generator-driven workflow with fully responsive GUI per Section 11 specifications.

---

## 1. Current Implementation Analysis

### 1.1 Relevant Files and Scripts

#### Core UI Files
- **Scene:** `res://ui/world_builder/WorldBuilderUI.tscn` (354 lines)
- **Script:** `res://ui/world_builder/WorldBuilderUI.gd` (344 lines)
- **Supporting Script:** `res://scripts/ui/WorldBuilderAzgaar.gd` (280 lines)
- **Manager:** `res://scripts/managers/AzgaarIntegrator.gd` (111 lines)
- **Helper Module:** `res://ui/world_builder/MapMakerModule.gd` (872 lines - partially deprecated for Azgaar migration)

#### Configuration Files
- `res://data/config/world_builder_ui.json` (248 lines) - Legacy tab-based config (Terrain, Biomes, Structures, Environment, Export)
- `res://data/config/azgaar_parameter_mapping.json` - Azgaar parameter mappings
- `res://data/config/archetype_azgaar_presets.json` - Preset archetype configurations
- `res://themes/bg3_theme.tres` - Current unified theme (374+ lines)

#### Constants and Utilities
- `res://scripts/ui/UIConstants.gd` (101 lines) - ✅ **EXISTS** with proper semantic constants

#### Addons and Dependencies
- **GDCef:** `res://cef_artifacts/` directory exists with `gdcef.gdextension`, libraries (`.so`, `.dll`, `.dylib`), and required artifacts
- **Terrain3D:** `res://addons/terrain_3d/` (128 files) - ✅ Installed
- **ProceduralWorldMap:** `res://addons/procedural_world_map/` (18 files) - ✅ Installed but being phased out for Azgaar

#### Azgaar Assets
- `res://tools/azgaar/` - Full Azgaar Fantasy Map Generator bundle (701 files including HTML, JS, CSS, images, heightmaps)
- **Entry Point:** `tools/azgaar/index.html`

### 1.2 Current WorldBuilderUI.tscn Node Tree Structure

```
WorldBuilderUI (Control, anchors_full_rect, theme=bg3_theme.tres)
├── Background (ColorRect, full rect, dark brown)
├── TopToolbar (HBoxContainer, anchored top, height=80px)
│   ├── ToolbarContent (HBoxContainer)
│   │   ├── ViewMenuLabel + ViewMenu (OptionButton)
│   │   ├── ToolsLabel + RaiseBtn, LowerBtn, SmoothBtn, RegenerateBtn
│   │   └── Generate3DBtn (Button, 180px width)
├── MainHSplit (HSplitContainer, anchored full rect with top/bottom offsets)
│   │   split_offset = 220 (left panel width)
│   ├── LeftPanel (VBoxContainer, custom_minimum_size=220px width)
│   │   ├── LeftPanelBg (ColorRect, parchment beige)
│   │   └── LeftContent (VBoxContainer)
│   │       ├── TitleLabel ("World Generation Wizard")
│   │       └── StepTabs (TabContainer) ← **ISSUE: Uses TabContainer instead of vertical sidebar buttons**
│   │           ├── Step1Terrain (VBoxContainer, empty)
│   │           ├── Step2Climate (VBoxContainer, empty)
│   │           ├── Step3Biomes (VBoxContainer, empty)
│   │           ├── Step4Structures (VBoxContainer, empty)
│   │           ├── Step5Environment (VBoxContainer, empty)
│   │           ├── Step6Resources (VBoxContainer, empty)
│   │           ├── Step7Export (VBoxContainer, empty)
│   │           └── Step8Bake (VBoxContainer, empty)
│   ├── CenterPanel (PanelContainer, expand_fill)
│   │   ├── CenterPanelBg (ColorRect, light beige)
│   │   └── CenterContent (VBoxContainer)
│   │       ├── AzgaarWebView (GDCef node) ← **PARTIAL: GDCef node exists but integration incomplete**
│   │       └── OverlayPlaceholder (TextureRect, hidden, for future use)
│   └── RightPanel (ScrollContainer, custom_minimum_size=240px width)
│       ├── RightPanelBg (ColorRect, parchment beige)
│       └── RightVBox (VBoxContainer)
│           ├── GlobalControls (VBoxContainer)
│           │   ├── ArchetypeOption (OptionButton)
│           │   └── SeedHBox (HBoxContainer)
│           │       ├── SeedSpin (SpinBox, 200px width)
│           │       └── RandomizeBtn (Button, 64x50px)
│           ├── SectionSep (HSeparator)
│           ├── StepTitle (Label, dynamic)
│           └── ActiveParams (VBoxContainer) ← **DYNAMIC: Populated per step**
└── BottomHBox (HBoxContainer, anchored bottom, height=50px)
    ├── BottomBg (ColorRect, parchment beige)
    └── BottomContent (HBoxContainer, centered)
        ├── SpacerLeft (Control, expand)
        ├── BackBtn (Button, 120px width)
        ├── NextBtn (Button, 120px width)
        ├── GenBtn (Button, 250px width, "✨ Generate with Azgaar")
        ├── ProgressBar (ProgressBar, 200px width, hidden by default)
        ├── StatusLabel (Label, 150px width)
        └── SpacerRight (Control, expand)
```

**Current Step Definitions (from WorldBuilderUI.gd):**
```gdscript
0: "Step 1: Terrain & Heightmap" - params: template, points, heightExponent, allowErosion, plateCount
1: "Step 2: Climate & Environment" - params: precip, temperatureEquator, temperatureNorthPole
2: "Step 3: Biomes & Ecosystems" - params: [] (empty)
3: "Step 4: Structures & Civilizations" - params: statesNumber, culturesSet, religionsNumber
4: "Step 5: Environment & Atmosphere" - params: [] (empty)
5: "Step 6: Resources & Magic" - params: [] (empty)
6: "Step 7: Export & Preview" - params: [] (empty)
7: "Step 8: Bake to 3D" - params: [] (empty)
```

**Desired Step Definitions (from user requirements):**
```
1. Map Generation & Editing
2. Terrain
3. Climate
4. Biomes
5. Structures & Civilizations
6. Environment
7. Resources & Magic
8. Export
```

### 1.3 Current Script Logic Analysis

#### WorldBuilderUI.gd Key Functions

**Initialization:**
- `_ready()`: Sets up UI, populates archetypes, connects signals, initializes Azgaar default
- `_initialize_azgaar_default()`: Calls `azgaar_webview.load_url(UIConstants.AZGAAR_BASE_URL)` - **ISSUE: Uses online URL instead of local bundled Azgaar**

**Step Management:**
- `_update_step_ui()`: Updates TabContainer current tab, title, navigation buttons, parameter controls
- `_populate_params()`: Dynamically creates controls (HSlider, OptionButton, CheckBox, SpinBox) from STEP_DEFINITIONS
- `_on_step_changed()`: Handler for TabContainer tab change

**Generation Flow:**
- `_generate_azgaar()`: Writes `current_params` to `user://azgaar/options.json`, reloads WebView
- `_process()`: Polls for generation completion by checking page title (heuristic: checks if title contains "[" and "x")
- `_bake_to_3d()`: Calls `terrain_manager.create_terrain()` and `configure_terrain()` - **STUB: TODO comments indicate incomplete**

**Parameter Management:**
- `_load_archetype_params()`: Loads preset params from ARCHETYPES dictionary (High Fantasy, Low Fantasy, Dark Fantasy, Realistic, Custom)
- `current_params: Dictionary` stores all active parameters

#### WorldBuilderAzgaar.gd Key Functions

**WebView Initialization:**
- `_initialize_webview()`: Attempts to get GDCef node, checks class name, initializes CEF if needed, creates browser
- `_create_azgaar_browser()`: Calls `create_browser(url, null, {})` on GDCef node
- **ISSUES:**
  - Fallback methods (`_try_direct_url_loading`, `_try_fallback_url_loading`) indicate uncertainty about GDCef API
  - No JavaScript execution methods called (no `execute_javascript()` or equivalent)
  - No event listeners for page load or generation completion

**Generation Triggering:**
- `trigger_generation_with_options()`: Writes options via `AzgaarIntegrator.write_options()`, reloads WebView, starts polling/timeout timers
- `_on_poll_timeout()`: **STUB** - TODO comment indicates completion detection not implemented
- `_on_generation_timeout()`: Emits `generation_failed` signal after 60 seconds

#### AzgaarIntegrator.gd Functions

- `copy_azgaar_to_user()`: Recursively copies `res://tools/azgaar/` to `user://azgaar/` for writability
- `write_options()`: Writes JSON options to `user://azgaar/options.json`
- `get_azgaar_url()`: Returns `file://` URL to `user://azgaar/index.html` - **CORRECT: Uses local bundled version**

### 1.4 Integration Points with Addons

#### Terrain3D Integration
- **Status:** ✅ Addon installed at `res://addons/terrain_3d/`
- **Current Usage:** `_bake_to_3d()` calls `terrain_manager.create_terrain()` and `configure_terrain()`
- **Gap:** No heightmap export/import logic from Azgaar → Terrain3D implemented
- **Required:** Parse Azgaar heightmap export (PNG/EXR) and feed to Terrain3D heightmap system

#### ProceduralWorldMap Integration
- **Status:** ⚠️ Addon installed but being phased out
- **Current Usage:** `MapMakerModule.gd` references old procedural generation (disabled with stubs)
- **Migration Note:** Old procedural code should be removed entirely once Azgaar integration is complete

#### GDCef Integration
- **Status:** ⚠️ **Partially Implemented**
- **Evidence:**
  - `cef_artifacts/` directory exists with all required files
  - `gdcef.gdextension` configured for Linux/Windows/macOS
  - `WorldBuilderUI.tscn` declares `AzgaarWebView` as `type="GDCef"`
  - `WorldBuilderAzgaar.gd` attempts initialization but has multiple fallback paths
- **Gaps:**
  - ❌ No JavaScript execution (no `execute_javascript()` calls)
  - ❌ No bidirectional communication (cannot query Azgaar state)
  - ❌ No event listeners (page load, generation complete signals)
  - ⚠️ Completion detection relies on heuristic (page title parsing) instead of proper events

### 1.5 Identified Issues

#### Magic Numbers and Non-Responsive Elements

**From `WorldBuilderUI.tscn` grep results:**
- `offset_bottom = 80.0` (TopToolbar) - **Should use UIConstants or calculate from toolbar height**
- `custom_minimum_size = Vector2(150, 0)` (ViewMenu) - **Should use UIConstants.LABEL_WIDTH_WIDE or semantic constant**
- `custom_minimum_size = Vector2(180, 0)` (Generate3DBtn) - **Should use UIConstants or theme-driven sizing**
- `offset_top = 80.0` and `offset_bottom = -50.0` (MainHSplit) - **Should use anchors or calculated offsets**
- `custom_minimum_size = Vector2(220, 0)` (LeftPanel) - **Should use UIConstants.LEFT_PANEL_WIDTH** (exists: 220, but should reference constant)
- `custom_minimum_size = Vector2(240, 0)` (RightPanel) - **Should use UIConstants.RIGHT_PANEL_WIDTH** (exists: 240, but should reference constant)
- `custom_minimum_size = Vector2(200, 0)` (SeedSpin) - **Should use UIConstants.LABEL_WIDTH_WIDE**
- `custom_minimum_size = Vector2(64, 50)` (RandomizeBtn) - **Should use UIConstants.BUTTON_HEIGHT_SMALL for height**
- `offset_top = -50.0` and `custom_minimum_size = Vector2(0, 50)` (BottomHBox) - **Should use UIConstants.BOTTOM_BAR_HEIGHT** (exists: 50)
- Multiple button widths (120px, 250px, 200px, 150px) - **Should use UIConstants semantic sizes**

**Total Magic Numbers Found:** 18 instances in `.tscn` file alone

#### Layout Structure Issues

1. **Left Panel Uses TabContainer Instead of Vertical Sidebar:**
   - Current: `StepTabs (TabContainer)` with 8 tab pages
   - Desired: Vertical list of buttons/tabs styled as sidebar
   - **Impact:** Requires complete restructuring of left panel

2. **Center Panel Not Fully Responsive:**
   - `AzgaarWebView` uses `size_flags_horizontal = 3` and `size_flags_vertical = 3` ✅ (correct)
   - But parent `MainHSplit` uses fixed `split_offset = 220` ⚠️ (should be dynamic or use UIConstants)

3. **Top Toolbar Fixed Height:**
   - `offset_bottom = 80.0` hardcoded
   - Should calculate from toolbar's actual height or use UIConstants

4. **Bottom Bar Fixed Height:**
   - `custom_minimum_size = Vector2(0, 50)` and `offset_top = -50.0`
   - UIConstants.BOTTOM_BAR_HEIGHT exists (50) but not used

#### Performance Bottlenecks

1. **Low FPS (3-7 FPS in debug mode):**
   - Likely causes:
     - GDCef rendering overhead (embedded browser is expensive)
     - No viewport culling or optimization for hidden elements
     - Potential memory leaks in WebView (if not properly managed)

2. **Generation Polling:**
   - `_process()` polls every 0.5 seconds checking page title
   - **Better approach:** Use GDCef events/signals if available, or reduce polling frequency

3. **Azgaar File Copying:**
   - `copy_azgaar_to_user()` runs on every `_ready()` if files don't exist
   - **Optimization:** Check if files already exist before copying

#### Compliance Check with GUI Philosophy & Structural Guidelines (Section 11)

**✅ Compliant:**
- Uses theme (`bg3_theme.tres`) ✅
- Uses containers (HSplitContainer, VBoxContainer, HBoxContainer) ✅
- Some size flags set (expand/fill on center panel) ✅
- UIConstants.gd exists with proper constants ✅

**❌ Violations:**
- **18 magic numbers** in `.tscn` file (hard-coded pixels) ❌
- Fixed `split_offset` instead of using UIConstants ❌
- TabContainer for steps instead of vertical sidebar buttons ❌
- No resize handling (`_notification(NOTIFICATION_RESIZED)`) ❌
- Fixed offsets (`offset_top = 80.0`, `offset_bottom = -50.0`) instead of anchors ❌
- Some controls don't use UIConstants (e.g., button widths) ❌

---

## 2. Desired Implementation Overview

### 2.1 Key Changes from Current to Desired

#### Layout Transformation

**Current Structure:**
```
[TopToolbar: 80px fixed]
[HSplitContainer: Left(220px) | Center(expand) | Right(240px)]
[BottomHBox: 50px fixed]
```

**Desired Structure:**
```
[HSplitContainer: Left(~15-20%) | Center(~60-65%) | Right(~20-25%)]
  ├── Left: Vertical sidebar with step buttons (fixed ~15-20% width)
  ├── Center: Azgaar WebView (expand_fill)
  └── Right: Dynamic step controls (ScrollContainer, ~20-25% width)
[BottomHBox: Overlaid on center panel bottom, full width, dark bar]
  ├── Generate/Apply Changes Button (centered, large, orange)
  ├── Bake to 3D Button (centered, appears after map finalized)
  ├── Back Button (left-aligned)
  ├── Next Button (right-aligned, orange highlighted)
  └── Status Label (center or near buttons)
```

**Key Differences:**
1. **No Top Toolbar** - All tools integrated into Azgaar's native UI
2. **Percentage-based widths** instead of fixed pixels (15-20% / 60-65% / 20-25%)
3. **Bottom bar overlaid** on center panel instead of separate row
4. **Vertical sidebar buttons** instead of TabContainer
5. **All editing in Azgaar** - no local painting tools (Raise/Lower/Smooth removed)

#### Step Definitions Update

**Current Steps (8):**
1. Terrain & Heightmap
2. Climate & Environment
3. Biomes & Ecosystems
4. Structures & Civilizations
5. Environment & Atmosphere
6. Resources & Magic
7. Export & Preview
8. Bake to 3D

**Desired Steps (8, aligned with Azgaar workflow):**
1. **Map Generation & Editing** - Global params (seed, template, map size, landmass type), Azgaar map generation
2. **Terrain** - Heightmap parameters, erosion, elevation
3. **Climate** - Temperature, precipitation, wind patterns
4. **Biomes** - Biome distribution, vegetation, ecosystem settings
5. **Structures & Civilizations** - States, cultures, religions, cities, routes
6. **Environment** - Atmosphere, fog, lighting (for 3D preview)
7. **Resources & Magic** - Resource distribution, magical zones
8. **Export** - Export options, bake to 3D trigger

**Mapping Note:** Steps align better with Azgaar's native parameter categories.

### 2.2 Benefits of Azgaar-Driven Approach

1. **Enhanced Procedural Capabilities:**
   - Azgaar handles complex noise generation, biome distribution, civilization placement
   - Sophisticated algorithms for rivers, routes, state borders, culture spread
   - Pre-built fantasy templates and heightmap presets

2. **Interactive Editing:**
   - Users can edit directly in Azgaar (paint terrain, place markers, adjust states)
   - Real-time preview of all layers (heightmap, biomes, temperature, population, political, religions, rivers)
   - No need to reimplement painting tools in Godot

3. **Alignment with Fantasy World-Building:**
   - Azgaar is purpose-built for fantasy maps (cultures, religions, states, routes, names)
   - Supports fantasy archetypes (high fantasy, dark fantasy, etc.)
   - Extensive customization options for fantasy settings

4. **Data Export:**
   - Azgaar can export heightmaps (PNG), biomes (JSON), political maps, etc.
   - Well-documented export formats suitable for Terrain3D import

### 2.3 Potential Challenges

#### CEF Integration Complexity

**Challenge:** GDCef API uncertainty
- Current code has multiple fallback paths indicating uncertainty
- Need to verify actual GDCef API: `create_browser()`, `execute_javascript()`, event signals
- **Mitigation:** Check GDCef documentation, test with minimal example, add error handling

**Challenge:** JavaScript Injection for Parameter Syncing
- Need to inject parameters into Azgaar via JS (e.g., `azgaar.setOption('points', 600000)`)
- Azgaar must expose API for external control (check `main.js` for global functions)
- **Mitigation:** Use Azgaar's URL parameters or modify bundled Azgaar to accept `options.json` on load

**Challenge:** Export/Import Data Flow
- Export heightmap from Azgaar (via JS: `azgaar.exportMap('png')` or download button)
- Parse exported PNG/EXR for Terrain3D heightmap format
- **Mitigation:** Use Azgaar's export functions, parse with Godot's Image API

#### Performance Overhead

**Challenge:** Embedded Browser Resource Usage
- GDCef/CEF is heavy (memory, CPU for rendering)
- **Mitigation:**
  - Lazy load: Only initialize GDCef when World Builder UI is opened
  - Use viewport culling: Hide WebView when not visible
  - Optimize Azgaar settings: Reduce cell density for preview, increase for final export

#### Compatibility

**Challenge:** Godot 4.5.1 Compatibility
- Current `project.godot` shows `godot_version="4.3.stable"` - **NEEDS UPDATE** to 4.5.1
- GDCef extension compatibility with 4.5.1 must be verified
- **Mitigation:** Test GDCef with 4.5.1, update project version, check for breaking changes

---

## 3. Migration Plan

### 3.1 Phased Approach

#### Phase 1: Setup and Foundation (Priority: HIGH)

**Objective:** Ensure GDCef is working, update project version, create responsive layout foundation

**Tasks:**
1. **Verify GDCef Installation:**
   - Test `create_browser()` with simple HTML page
   - Verify `execute_javascript()` method exists and works
   - Check for event signals (page loaded, URL changed)
   - **Files:** Create `res://tests/gdcef_verification_test.gd` (EditorScript)

2. **Update Project Version:**
   - Change `project.godot` line 57: `godot_version="4.5.1.stable"`
   - Test project loads correctly
   - **Files:** `res://project.godot`

3. **Replace Magic Numbers with UIConstants:**
   - Update `WorldBuilderUI.tscn`: Replace all `custom_minimum_size` and `offset_*` with UIConstants references
   - Use `UIConstants.LEFT_PANEL_WIDTH` (220), `UIConstants.RIGHT_PANEL_WIDTH` (240), `UIConstants.BOTTOM_BAR_HEIGHT` (50)
   - Replace button widths with `UIConstants.BUTTON_HEIGHT_MEDIUM` or semantic constants
   - **Files:** `res://ui/world_builder/WorldBuilderUI.tscn`

4. **Add Resize Handling:**
   - Add `_notification(NOTIFICATION_RESIZED)` to `WorldBuilderUI.gd`
   - Recalculate panel widths as percentages (15-20% / 60-65% / 20-25%)
   - Clamp to min/max from UIConstants
   - **Files:** `res://ui/world_builder/WorldBuilderUI.gd`

**Estimated Effort:** 4-6 hours  
**Testing:** Run project, verify UI scales on window resize, check FPS

#### Phase 2: Restructure Left Panel to Vertical Sidebar (Priority: HIGH)

**Objective:** Replace TabContainer with vertical button list

**Tasks:**
1. **Remove TabContainer:**
   - Delete `StepTabs` node and all child tab pages
   - **Files:** `res://ui/world_builder/WorldBuilderUI.tscn`

2. **Create Vertical Sidebar:**
   - Add `VBoxContainer` named `StepSidebar` to `LeftContent`
   - Create 8 `Button` nodes (one per step) with text matching desired step names
   - Style buttons: Dim when inactive, orange highlight on current step
   - Use `theme_override_colors/font_color` and `theme_override_styles/normal` for styling
   - **Files:** `res://ui/world_builder/WorldBuilderUI.tscn`

3. **Update Script Logic:**
   - Remove `step_tabs: TabContainer` reference
   - Add `@onready var step_buttons: Array[Button] = []` to store button references
   - Update `_update_step_ui()`: Set button pressed state, update highlights
   - Connect button `pressed` signals to `_on_step_button_pressed(step_idx: int)`
   - **Files:** `res://ui/world_builder/WorldBuilderUI.gd`

4. **Update Step Definitions:**
   - Update `STEP_DEFINITIONS` dictionary with new step titles matching desired structure
   - Align parameter lists with Azgaar's actual parameter categories
   - **Files:** `res://ui/world_builder/WorldBuilderUI.gd`

**Estimated Effort:** 3-4 hours  
**Testing:** Click step buttons, verify highlights update, verify step content changes

#### Phase 3: Integrate Azgaar JavaScript Communication (Priority: HIGH)

**Objective:** Enable bidirectional communication between Godot and Azgaar

**Tasks:**
1. **Research Azgaar API:**
   - Inspect `tools/azgaar/main.js` for global functions (e.g., `azgaar.generate()`, `azgaar.setOption()`, `azgaar.exportMap()`)
   - Document available functions in `tools/azgaar/AZGAAR_PARAMETERS.md` (already exists - review it)
   - **Files:** `res://tools/azgaar/main.js`, `res://tools/azgaar/AZGAAR_PARAMETERS.md`

2. **Implement JavaScript Execution:**
   - Add `_execute_azgaar_js(code: String) -> Variant` method to `WorldBuilderAzgaar.gd`
   - Use GDCef's `execute_javascript()` or equivalent method
   - Add error handling for JS execution failures
   - **Files:** `res://scripts/ui/WorldBuilderAzgaar.gd`

3. **Sync Parameters to Azgaar:**
   - Update `_generate_azgaar()`: Instead of writing `options.json`, inject parameters via JS
   - Example: `_execute_azgaar_js("azgaar.setOption('points', %d)" % current_params.points)`
   - Map `current_params` keys to Azgaar parameter names (use `azgaar_parameter_mapping.json`)
   - **Files:** `res://ui/world_builder/WorldBuilderUI.gd`, `res://scripts/ui/WorldBuilderAzgaar.gd`

4. **Implement Completion Detection:**
   - Replace `_process()` polling with event-based detection
   - Option A: Use GDCef page load event → check if generation complete
   - Option B: Inject JS callback: `azgaar.onGenerationComplete(() => { window.godotGenerationComplete() })`
   - Option C: Poll Azgaar state via JS: `_execute_azgaar_js("azgaar.getState()")`
   - **Files:** `res://scripts/ui/WorldBuilderAzgaar.gd`

5. **Remove Top Toolbar:**
   - Delete `TopToolbar` node and all children
   - Update `MainHSplit` anchors: Remove `offset_top = 80.0`, set to full rect
   - **Files:** `res://ui/world_builder/WorldBuilderUI.tscn`

**Estimated Effort:** 6-8 hours  
**Testing:** Generate map, verify parameters sync to Azgaar, verify completion detection works

#### Phase 4: Update Right Panel for Dynamic Step Controls (Priority: MEDIUM)

**Objective:** Populate right panel with Azgaar-relevant parameters per step

**Tasks:**
1. **Create Step Parameter Configurations:**
   - Create `res://data/config/azgaar_step_parameters.json` mapping step indices to Azgaar parameter groups
   - Example structure:
     ```json
     {
       "0": {
         "title": "Map Generation & Editing",
         "parameters": ["templateInput", "pointsInput", "worldSize", "landmassType"],
         "category": "global"
       },
       "1": {
         "title": "Terrain",
         "parameters": ["heightExponent", "erosion", "seaLevel"],
         "category": "terrain"
       }
     }
     ```
   - **Files:** `res://data/config/azgaar_step_parameters.json` (new)

2. **Load Parameters from Config:**
   - Update `_populate_params()`: Load from `azgaar_step_parameters.json` instead of hard-coded `STEP_DEFINITIONS`
   - Map Azgaar parameter names to UI controls using `azgaar_parameter_mapping.json`
   - **Files:** `res://ui/world_builder/WorldBuilderUI.gd`

3. **Update Parameter Controls:**
   - Ensure controls update `current_params` dictionary
   - On change, call `_execute_azgaar_js()` to sync to Azgaar in real-time (optional, or batch on "Apply" button)
   - **Files:** `res://ui/world_builder/WorldBuilderUI.gd`

**Estimated Effort:** 4-5 hours  
**Testing:** Switch steps, verify correct parameters appear, verify changes sync to Azgaar

#### Phase 5: Implement Export and 3D Bake (Priority: MEDIUM)

**Objective:** Export heightmap from Azgaar and bake to Terrain3D

**Tasks:**
1. **Implement Heightmap Export:**
   - Add `_export_heightmap() -> Image` method to `WorldBuilderAzgaar.gd`
   - Execute JS: `_execute_azgaar_js("azgaar.exportMap('heightmap')")` or equivalent
   - Receive exported data via callback or file read (Azgaar may save to `user://azgaar/downloads/`)
   - Parse PNG/EXR to Godot `Image` using `Image.load_from_file()` or `Image.load_exr_from_buffer()`
   - **Files:** `res://scripts/ui/WorldBuilderAzgaar.gd`

2. **Implement Terrain3D Bake:**
   - Update `_bake_to_3d()`: Call `_export_heightmap()`, then feed to Terrain3D
   - Use Terrain3D's heightmap import API (check `addons/terrain_3d/` documentation)
   - Example: `terrain_manager.generate_from_heightmap(heightmap_image, min_height, max_height, center_pos)`
   - **Files:** `res://ui/world_builder/WorldBuilderUI.gd`

3. **Add Bake Button to Bottom Bar:**
   - Update bottom bar layout: Add "Bake to 3D" button (only visible/enabled on step 8)
   - Style: Large, orange/gold, centered
   - Connect to `_bake_to_3d()`
   - **Files:** `res://ui/world_builder/WorldBuilderUI.tscn`, `res://ui/world_builder/WorldBuilderUI.gd`

4. **Update Bottom Bar Overlay:**
   - Change `BottomHBox` from separate row to overlay on center panel
   - Set anchors to bottom of center panel, use `z_index` to render above WebView
   - Add dark background (`ColorRect` with dark color, semi-transparent)
   - **Files:** `res://ui/world_builder/WorldBuilderUI.tscn`

**Estimated Effort:** 5-6 hours  
**Testing:** Export heightmap, verify image loads correctly, verify Terrain3D bake creates terrain

#### Phase 6: Remove Old Procedural Code and Cleanup (Priority: LOW)

**Objective:** Remove deprecated MapMakerModule and old procedural generation code

**Tasks:**
1. **Archive MapMakerModule:**
   - Move `res://ui/world_builder/MapMakerModule.gd` to `res://ui/world_builder/_deprecated/` (or delete if no longer needed)
   - Remove any references to `MapMakerModule` in `WorldBuilderUI.gd`
   - **Files:** `res://ui/world_builder/MapMakerModule.gd`, `res://ui/world_builder/WorldBuilderUI.gd`

2. **Remove Old Config Files:**
   - Archive `res://data/config/world_builder_ui.json` (legacy tab-based config)
   - Ensure `azgaar_step_parameters.json` replaces it
   - **Files:** `res://data/config/world_builder_ui.json`

3. **Update Documentation:**
   - Update README or docs to reflect Azgaar-driven workflow
   - Document new step flow and parameter mapping
   - **Files:** `res://README.md` or `res://docs/`

**Estimated Effort:** 2-3 hours  
**Testing:** Verify no broken references, project loads without errors

### 3.2 Step-by-Step File Modifications

#### Files to Modify

1. **`res://project.godot`**
   - Line 57: `godot_version="4.5.1.stable"` (update from 4.3)

2. **`res://ui/world_builder/WorldBuilderUI.tscn`**
   - Remove `TopToolbar` node
   - Replace `StepTabs` (TabContainer) with `StepSidebar` (VBoxContainer with Button children)
   - Update all `custom_minimum_size` and `offset_*` to use calculated values or remove (use anchors)
   - Update `MainHSplit`: Remove `offset_top` and `offset_bottom`, use percentage-based `split_offset` or anchors
   - Update `BottomHBox`: Change to overlay (anchors to center panel bottom), add dark background
   - Add "Bake to 3D" button to bottom bar

3. **`res://ui/world_builder/WorldBuilderUI.gd`**
   - Update `STEP_DEFINITIONS` with new step titles and Azgaar-aligned parameters
   - Remove `step_tabs` reference, add `step_buttons: Array[Button]`
   - Replace `_on_step_changed(tab_idx)` with `_on_step_button_pressed(step_idx)`
   - Update `_populate_params()`: Load from `azgaar_step_parameters.json`
   - Update `_generate_azgaar()`: Use JS injection instead of `options.json` file write
   - Update `_bake_to_3d()`: Call `WorldBuilderAzgaar._export_heightmap()`, feed to Terrain3D
   - Add `_notification(NOTIFICATION_RESIZED)`: Recalculate panel widths as percentages
   - Remove references to `MapMakerModule`

4. **`res://scripts/ui/WorldBuilderAzgaar.gd`**
   - Add `_execute_azgaar_js(code: String) -> Variant`: Execute JavaScript in Azgaar WebView
   - Update `_initialize_webview()`: Use local Azgaar URL (`azgaar_integrator.get_azgaar_url()`) ✅ (already correct)
   - Update `trigger_generation_with_options()`: Use JS injection instead of file write + reload
   - Implement `_export_heightmap() -> Image`: Export heightmap from Azgaar, parse to Image
   - Replace `_process()` polling with event-based completion detection
   - Add event handlers for GDCef page load, generation complete (if available)

5. **`res://scripts/managers/AzgaarIntegrator.gd`**
   - No changes required (already handles file copying and URL generation correctly)

#### Files to Create

1. **`res://data/config/azgaar_step_parameters.json`** (new)
   - JSON mapping step indices to parameter groups and Azgaar parameter names

2. **`res://tests/gdcef_verification_test.gd`** (new, optional)
   - EditorScript to test GDCef API availability and functionality

#### Files to Archive/Delete

1. **`res://ui/world_builder/MapMakerModule.gd`** → Move to `_deprecated/` or delete
2. **`res://data/config/world_builder_ui.json`** → Archive (legacy, replaced by `azgaar_step_parameters.json`)

### 3.3 UI Responsiveness Fixes

#### Replace Magic Numbers

**Current Issues:**
- 18 magic numbers in `.tscn` file
- Fixed pixel sizes instead of semantic constants

**Solution:**
1. **Update UIConstants.gd (if needed):**
   - Verify `LEFT_PANEL_WIDTH = 220`, `RIGHT_PANEL_WIDTH = 240`, `BOTTOM_BAR_HEIGHT = 50` exist ✅ (already exist)
   - Add percentage-based constants if needed: `LEFT_PANEL_WIDTH_PERCENT = 0.18` (18%)

2. **Update WorldBuilderUI.tscn:**
   - Replace `custom_minimum_size = Vector2(220, 0)` with calculated value or use percentage-based split
   - Replace `custom_minimum_size = Vector2(240, 0)` with calculated value or use percentage-based split
   - Replace button widths with `UIConstants.BUTTON_HEIGHT_MEDIUM` or theme-driven sizes
   - Remove `offset_top` and `offset_bottom`, use anchors instead

3. **Add Resize Handler:**
   ```gdscript
   func _notification(what: int) -> void:
       if what == NOTIFICATION_RESIZED:
           _update_responsive_layout()
   
   func _update_responsive_layout() -> void:
       var viewport_size: Vector2 = get_viewport().get_visible_rect().size
       # Calculate panel widths as percentages
       var left_width: float = viewport_size.x * 0.18  # 18% for left panel
       var right_width: float = viewport_size.x * 0.22  # 22% for right panel
       # Clamp to min/max from UIConstants
       left_width = clamp(left_width, UIConstants.LEFT_PANEL_WIDTH * 0.5, UIConstants.LEFT_PANEL_WIDTH * 1.5)
       right_width = clamp(right_width, UIConstants.RIGHT_PANEL_WIDTH * 0.5, UIConstants.RIGHT_PANEL_WIDTH * 1.5)
       # Update HSplitContainer split_offset (if using fixed split, or use anchors)
   ```

#### Add Size Flags and Anchors

**Current State:**
- Center panel: ✅ `size_flags_horizontal = 3`, `size_flags_vertical = 3` (correct)
- Left/Right panels: ⚠️ `size_flags_horizontal = 3` but fixed `custom_minimum_size` overrides

**Solution:**
- Remove `custom_minimum_size` from left/right panels, use percentage-based `split_offset` on HSplitContainer
- Or use anchors: Set left panel to `PRESET_LEFT_WIDE` with calculated margin, right to `PRESET_RIGHT_WIDE`

### 3.4 Addon Handling

#### GDCef Status

**Current:** ✅ GDCef artifacts present in `res://cef_artifacts/`
- `gdcef.gdextension` configured
- Libraries for Linux/Windows/macOS present
- **Action Required:** Verify GDCef works with Godot 4.5.1, test `execute_javascript()` API

**Recommendation:** 
- Test GDCef with minimal HTML page first
- If API differs from assumptions, update `WorldBuilderAzgaar.gd` accordingly
- If GDCef doesn't work with 4.5.1, may need to update extension or find alternative (e.g., Godot WebView addon)

#### Terrain3D Integration

**Current:** ✅ Addon installed
- **Action Required:** Research Terrain3D heightmap import API
- Check `addons/terrain_3d/` documentation or examples for `generate_from_heightmap()` or equivalent method

### 3.5 Data Flow: Parameter Syncing and Export

#### Parameter Syncing: Godot → Azgaar

**Current Flow (File-based):**
```
WorldBuilderUI._generate_azgaar()
  → AzgaarIntegrator.write_options(options)  # Writes user://azgaar/options.json
  → WorldBuilderAzgaar.reload_azgaar()       # Reloads WebView
  → Azgaar reads options.json on page load
```

**Desired Flow (JS Injection):**
```
WorldBuilderUI._generate_azgaar()
  → Map current_params to Azgaar parameter names (using azgaar_parameter_mapping.json)
  → For each parameter:
      WorldBuilderAzgaar._execute_azgaar_js("azgaar.setOption('%s', %s)" % [param_name, value])
  → WorldBuilderAzgaar._execute_azgaar_js("azgaar.generate()")  # Trigger generation
```

**Challenges:**
- Azgaar must expose `setOption()` and `generate()` functions (verify in `main.js`)
- If not available, may need to modify bundled Azgaar to add these functions
- Alternative: Use URL parameters: `index.html?points=600000&template=default#generate`

#### Export: Azgaar → Godot → Terrain3D

**Flow:**
```
User clicks "Bake to 3D"
  → WorldBuilderUI._bake_to_3d()
  → WorldBuilderAzgaar._export_heightmap()
    → _execute_azgaar_js("azgaar.exportMap('heightmap')")
    → Receive exported data (via callback or file read)
    → Parse PNG/EXR to Image
  → terrain_manager.generate_from_heightmap(heightmap_image, ...)
    → Terrain3D creates 3D terrain mesh
```

**Export Format:**
- Azgaar can export heightmap as PNG (grayscale) or EXR
- Godot's `Image.load_from_file()` or `Image.load_exr_from_buffer()` can parse
- May need to normalize height values (0-1 range) for Terrain3D

### 3.6 Testing Steps

#### Phase 1 Testing
- [ ] Verify project loads with Godot 4.5.1
- [ ] Verify GDCef initializes (check logs for "CEF initialized successfully")
- [ ] Test window resize: UI scales proportionally, no clipping
- [ ] Verify FPS remains acceptable (target: 30+ FPS with WebView)

#### Phase 2 Testing
- [ ] Click step buttons: Highlights update correctly
- [ ] Verify step content changes (right panel updates)
- [ ] Test navigation: Back/Next buttons work correctly

#### Phase 3 Testing
- [ ] Generate map: Parameters sync to Azgaar (verify in browser DevTools)
- [ ] Verify completion detection works (no 60s timeout)
- [ ] Test parameter changes: Updates reflect in Azgaar map

#### Phase 4 Testing
- [ ] Switch steps: Correct parameters appear per step
- [ ] Modify parameters: Changes sync to Azgaar (or batch on Apply)
- [ ] Verify all 8 steps have appropriate parameter controls

#### Phase 5 Testing
- [ ] Export heightmap: Image loads correctly in Godot
- [ ] Bake to 3D: Terrain3D creates terrain mesh
- [ ] Verify terrain matches Azgaar map visually

#### Phase 6 Testing
- [ ] Project loads without errors (no broken references)
- [ ] No deprecated code remains in active use
- [ ] Documentation updated

---

## 4. Potential Risks and Mitigations

### 4.1 Performance Risks

**Risk:** Embedded browser (GDCef) causes low FPS (< 30 FPS)
- **Impact:** Poor user experience, UI feels sluggish
- **Mitigation:**
  - Lazy load: Only initialize GDCef when World Builder UI is opened
  - Viewport culling: Hide WebView when not visible (e.g., when another menu is open)
  - Optimize Azgaar: Reduce cell density for preview, increase only for final export
  - Profile with PerformanceMonitor: Identify bottlenecks, optimize hot paths

**Risk:** Memory leaks in WebView
- **Impact:** Memory usage grows over time, potential crashes
- **Mitigation:**
  - Properly cleanup: Call `web_view.queue_free()` when World Builder UI is closed
  - Monitor memory: Use `PerformanceMonitor` to track memory usage
  - Test extended sessions: Run World Builder for 30+ minutes, check for leaks

### 4.2 Compatibility Risks

**Risk:** GDCef not compatible with Godot 4.5.1
- **Impact:** WebView doesn't initialize, Azgaar cannot be embedded
- **Mitigation:**
  - Test early: Verify GDCef works in Phase 1
  - Fallback plan: If GDCef fails, consider alternative (Godot WebView addon, or external browser with communication bridge)
  - Check GDCef repository: Look for 4.5.1 compatibility updates

**Risk:** Azgaar JavaScript API differs from assumptions
- **Impact:** Parameter syncing fails, generation doesn't trigger
- **Mitigation:**
  - Research first: Inspect `tools/azgaar/main.js` for actual API functions
  - Document findings: Update `AZGAAR_PARAMETERS.md` with verified API
  - Fallback: Use file-based approach (write `options.json`, reload) if JS injection fails

### 4.3 Data Export/Import Risks

**Risk:** Azgaar export format incompatible with Terrain3D
- **Impact:** Heightmap cannot be imported, 3D bake fails
- **Mitigation:**
  - Research Terrain3D API: Check documentation for supported formats (PNG, EXR, raw)
  - Test early: Export sample heightmap, attempt import in Phase 5
  - Conversion: If format mismatch, convert using Godot's Image API (e.g., PNG → EXR, normalize values)

**Risk:** Heightmap resolution too high/low for Terrain3D
- **Impact:** Terrain quality poor or performance issues
- **Mitigation:**
  - Clamp resolution: Limit Azgaar export to reasonable size (e.g., 2048x2048 max)
  - Downscale if needed: Use `Image.resize()` if Terrain3D has max resolution limits
  - Document limits: Add UI hints about recommended resolutions

### 4.4 Fallback Strategies

**If Azgaar Integration Fails:**
- **Option A:** Retain local procedural generation as toggle (keep `MapMakerModule.gd` as backup)
- **Option B:** Use Azgaar in external browser, communicate via file system (write `options.json`, read exports)
- **Option C:** Implement minimal procedural fallback (basic noise generation) for quick world creation

**If GDCef Fails:**
- **Option A:** Use Godot WebView addon (if available for 4.5.1)
- **Option B:** Launch external browser, use file-based communication
- **Option C:** Implement native Godot UI for Azgaar parameters (recreate Azgaar's UI in Godot) - **NOT RECOMMENDED** (too much work)

---

## 5. Resource Requirements

### 5.1 New Files/Scenes/Scripts Needed

1. **`res://data/config/azgaar_step_parameters.json`** (new)
   - Estimated size: ~5-10 KB
   - Contains step-to-parameter mappings

2. **`res://tests/gdcef_verification_test.gd`** (optional, new)
   - Estimated size: ~2-3 KB
   - EditorScript for testing GDCef API

3. **No new scenes required** (modify existing `WorldBuilderUI.tscn`)

### 5.2 Updates to Existing Files

1. **`res://project.godot`** - 1 line change (version update)
2. **`res://ui/world_builder/WorldBuilderUI.tscn`** - Major restructuring (~100+ line changes)
3. **`res://ui/world_builder/WorldBuilderUI.gd`** - Major refactoring (~200+ line changes)
4. **`res://scripts/ui/WorldBuilderAzgaar.gd`** - Add JS execution, export methods (~100+ line changes)
5. **`res://scripts/ui/UIConstants.gd`** - Possibly add percentage constants (minor, ~10 lines)

### 5.3 Estimated Effort

**Phase 1: Setup and Foundation** - 4-6 hours
**Phase 2: Restructure Left Panel** - 3-4 hours
**Phase 3: Azgaar JS Communication** - 6-8 hours (most complex, depends on GDCef API research)
**Phase 4: Dynamic Step Controls** - 4-5 hours
**Phase 5: Export and 3D Bake** - 5-6 hours
**Phase 6: Cleanup** - 2-3 hours

**Total Estimated Effort:** 24-32 hours (3-4 full working days)

**Dependencies:**
- GDCef API documentation/research: +2-4 hours (if not readily available)
- Terrain3D API research: +1-2 hours
- Testing and bug fixes: +4-6 hours (20% buffer)

**Grand Total:** 31-44 hours (~1-1.5 weeks for a single developer)

---

## 6. Compliance Checklist

### 6.1 Responsive UI per Section 11.2

- [ ] **Built-in containers with size flags/anchors:** ✅ Current (HSplitContainer, VBoxContainer, HBoxContainer used)
- [ ] **No magic numbers:** ❌ **18 magic numbers found** - Must replace with UIConstants
- [ ] **Theme applied:** ✅ Current (`bg3_theme.tres` applied)
- [ ] **Tested on multiple resolutions:** ❌ **Not tested** - Must test 1080p, 4K, ultrawide, window resize
- [ ] **Size flags explicitly set:** ⚠️ **Partial** - Center panel correct, left/right need fixes
- [ ] **Resize handling:** ❌ **Missing** - Must add `_notification(NOTIFICATION_RESIZED)`

### 6.2 Theme Consistency

- [x] **Theme resource exists:** ✅ `res://themes/bg3_theme.tres`
- [x] **Theme applied to root:** ✅ `WorldBuilderUI` has `theme = ExtResource("2_theme")`
- [ ] **Overrides documented:** ⚠️ **Some overrides** (font sizes, colors) - Should document with comments
- [ ] **Fantasy aesthetics:** ✅ Current (parchment colors, gold accents)

### 6.3 Code Quality

- [x] **Typed GDScript:** ✅ Current (most variables typed)
- [x] **Script headers:** ✅ Current (exact header format used)
- [x] **Docstrings:** ✅ Current (public functions documented)
- [ ] **One class per file:** ✅ Current
- [ ] **No hard-coded values in scripts:** ⚠️ **Some hard-coded** (e.g., timeout 60.0, polling 0.5s) - Consider constants

### 6.4 Performance Target

- [ ] **60 FPS target maintained:** ❌ **Current: 3-7 FPS** - Must investigate and optimize
  - Likely causes: GDCef overhead, no viewport culling, unoptimized rendering
  - Target: 30+ FPS with WebView active (60 FPS may be unrealistic with embedded browser)

### 6.5 Migration-Specific Compliance

- [ ] **UIConstants usage:** ❌ **Not used in .tscn file** - Must replace all magic numbers
- [ ] **Percentage-based layouts:** ❌ **Fixed pixels** - Must convert to percentages or calculated values
- [ ] **Dynamic parameter loading:** ⚠️ **Partially** - Uses hard-coded `STEP_DEFINITIONS`, should use JSON config
- [ ] **Azgaar integration complete:** ❌ **Partial** - JS communication missing, export missing

---

## 7. Recommendations and Next Steps

### 7.1 Immediate Actions (Before Migration)

1. **Verify GDCef Compatibility:**
   - Test GDCef with Godot 4.5.1 in a minimal test project
   - Verify `execute_javascript()` method exists and works
   - Document actual GDCef API (methods, signals, properties)

2. **Research Azgaar API:**
   - Inspect `tools/azgaar/main.js` for global functions
   - Document available functions (e.g., `azgaar.setOption()`, `azgaar.generate()`, `azgaar.exportMap()`)
   - Test in browser DevTools: Can we call these functions from console?

3. **Research Terrain3D Heightmap Import:**
   - Check Terrain3D documentation for heightmap import methods
   - Look for examples in `addons/terrain_3d/` or tests
   - Verify supported formats (PNG, EXR, raw)

### 7.2 Migration Priority Order

1. **Phase 1 (Setup)** - **CRITICAL** - Must do first (verify GDCef, update version, fix magic numbers)
2. **Phase 3 (JS Communication)** - **CRITICAL** - Core functionality (Azgaar integration won't work without this)
3. **Phase 2 (Sidebar)** - **HIGH** - UI restructuring (improves UX, aligns with desired design)
4. **Phase 5 (Export/Bake)** - **HIGH** - Core feature (3D bake is essential for workflow)
5. **Phase 4 (Dynamic Controls)** - **MEDIUM** - Nice to have (improves maintainability)
6. **Phase 6 (Cleanup)** - **LOW** - Can be done last (doesn't affect functionality)

### 7.3 Risk Mitigation Strategy

1. **Start with Minimal Viable Product:**
   - Phase 1 + Phase 3 (basic JS communication)
   - Test with simple parameter (e.g., seed) before full parameter mapping
   - Verify completion detection works before moving to next phases

2. **Incremental Testing:**
   - Test after each phase (don't wait until end)
   - Use `run_project` MCP action to verify UI scales, FPS acceptable
   - Fix issues immediately (don't accumulate technical debt)

3. **Fallback Planning:**
   - Keep old procedural code as backup until Azgaar integration is proven stable
   - Archive, don't delete, deprecated files until migration is complete

---

## Appendix A: Current vs Desired Step Mapping

| Current Step | Desired Step | Key Differences |
|--------------|--------------|-----------------|
| 0: Terrain & Heightmap | 1: Map Generation & Editing | Broader scope (includes global params like seed, template, map size) |
| 1: Climate & Environment | 2: Terrain | Focused on heightmap/elevation (moved from step 0) |
| 2: Biomes & Ecosystems | 3: Climate | Separated from environment (more focused) |
| 3: Structures & Civilizations | 4: Biomes | No change (same scope) |
| 4: Environment & Atmosphere | 5: Structures & Civilizations | No change (same scope) |
| 5: Resources & Magic | 6: Environment | Renamed from "Environment & Atmosphere" (more focused on 3D atmosphere) |
| 6: Export & Preview | 7: Resources & Magic | No change (same scope) |
| 7: Bake to 3D | 8: Export | Export includes bake option (merged) |

**Note:** Step numbering changes from 0-indexed to 1-indexed for user-facing labels (internal code remains 0-indexed).

---

## Appendix B: GDCef API Assumptions (To Be Verified)

Based on code analysis, the following GDCef API is assumed (must be verified):

- `GDCef.initialize(settings: Dictionary) -> void` - Initialize CEF
- `GDCef.is_alive() -> bool` - Check if CEF is initialized
- `GDCef.create_browser(url: String, texture_rect: TextureRect, options: Dictionary) -> Browser` - Create browser instance
- `Browser.load_url(url: String) -> void` - Load URL
- `Browser.execute_javascript(code: String) -> Variant` - Execute JS, return result (ASSUMED - **NEEDS VERIFICATION**)
- `Browser.reload() -> void` - Reload page
- Signals: `page_loaded`, `url_changed`, `title_changed` (ASSUMED - **NEEDS VERIFICATION**)

**Action Required:** Verify these methods exist and document actual API.

---

## Appendix C: Azgaar Parameter Mapping Reference

Key Azgaar parameters (from `azgaar_parameter_mapping.json`):

- `templateInput` - Heightmap template (OptionButton)
- `pointsInput` - Cell density (HSlider, 1-13, maps to 1K-100K cells)
- `statesNumber` - Number of states (SpinBox, 0-100)
- `culturesInput` - Number of cultures (SpinBox, 1-32)
- `culturesSet` - Culture set (OptionButton: world, european, oriental, highFantasy, darkFantasy)
- `religionsNumber` - Number of religions (SpinBox, 0-50)

**Full mapping:** See `res://data/config/azgaar_parameter_mapping.json`

---

**End of Audit Report**

