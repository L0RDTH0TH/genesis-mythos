# Azgaar Integration State Audit – As of 2025-01-20

**Audit Purpose:** Comprehensive documentation of current Azgaar integration implementation, compliance with project rules, and identification of gaps relative to Final Implementation Plan for Azgaar Parameter Integration.

**Audit Method:** Performed via Godot MCP actions (list_files, read_file, codebase_search, grep) and file system inspection.

---

## Executive Summary

The Azgaar integration is **partially implemented** with solid foundations in place, but critical gaps remain in parameter injection, heightmap export, and downstream system integration. The UI infrastructure for parameter controls is well-structured and compliant with project rules (data-driven JSON, UIConstants usage, responsive containers), but the bridge layer (GDCef JavaScript execution) and data export pipeline are incomplete.

**Key Findings:**
- ✅ **Phase 1 Complete:** Parameter mapping JSON and archetype presets exist and are loaded
- ✅ **Phase 1 Partial:** UI controls built from mapping with category grouping (TabContainer)
- ⚠️ **Phase 1 Gap:** Hardware clamping implemented for `pointsInput` only; other high-impact parameters not clamped
- ❌ **Phase 2 Gap:** GDCef JavaScript execution bridge not verified/implemented (options.json fallback only)
- ❌ **Phase 3 Missing:** Heightmap extraction/rasterization from Azgaar WebView not implemented
- ❌ **Phase 4 Missing:** Downstream integrations (EntitySim, FactionEconomy, WorldStreamer) are stubs only

---

## Existing Files & Configurations

### Configuration Files

#### `res://data/config/azgaar_parameter_mapping.json`
**Status:** ✅ Exists and loaded  
**Structure:**
- Root key: `"parameters"` (Dictionary)
- Each parameter contains:
  - `ui_type`: "HSlider" | "SpinBox" | "CheckBox" | "OptionButton"
  - `category`: "Terrain & Heightmap" | "Climate & Environment" | "Societies & Politics" | "Settlements & Scale"
  - `performance_impact`: "low" | "medium" | "high"
  - `description`: String (optional)
  - Type-specific fields: `min`, `max`, `step`, `default`, `options`

**Current Parameters (13 total):**
1. `templateInput` (OptionButton, Terrain & Heightmap)
2. `pointsInput` (HSlider, 1-13, Terrain & Heightmap, **high impact**)
3. `statesNumber` (SpinBox, 0-100, Societies & Politics)
4. `culturesInput` (SpinBox, 1-32, Societies & Politics)
5. `culturesSet` (OptionButton, Societies & Politics)
6. `religionsNumber` (SpinBox, 0-50, Societies & Politics)
7. `manorsInput` (SpinBox, 0-1000, Settlements & Scale, **medium impact**)
8. `precInput` (HSlider, 0-500, Climate & Environment)
9. `temperatureEquator` (HSlider, -50-50, Climate & Environment)
10. `temperatureNorthPole` (HSlider, -50-50, Climate & Environment)
11. `temperatureSouthPole` (HSlider, -50-50, Climate & Environment)
12. `heightExponentInput` (HSlider, 1.5-2.2, Terrain & Heightmap)
13. `allowErosion` (CheckBox, Terrain & Heightmap, **medium impact**)

**Gaps:**
- Missing many parameters from `AZGAAR_PARAMETERS.md` (e.g., `mapWidthInput`, `mapHeightInput`, `optionsSeed`, `yearInput`, `winds`, biome-specific params)
- Only 4 categories; could expand for better organization

#### `res://data/config/archetype_azgaar_presets.json`
**Status:** ✅ Exists and loaded  
**Structure:**
- Root: Dictionary with archetype names as keys
- Each archetype: Dictionary of `param_name: value` pairs

**Current Presets (4 total):**
1. `"High Fantasy"` - High states (25), cultures (18), manors (900), high precipitation (130)
2. `"Dark Fantasy"` - Lower states (10), cultures (10), manors (500), shattered template
3. `"Low Fantasy / Historical"` - Europe template, balanced settings
4. `"Archipelago"` - Islands template, no erosion

**Gaps:**
- Only 4 presets; could expand to match `data/archetypes/` (13 archetype JSON files exist)
- No linkage to `fantasy_archetypes.json` or individual archetype files

### Script Files

#### `res://scripts/managers/AzgaarIntegrator.gd`
**Status:** ✅ Active singleton (autoload: `AzgaarIntegrator`)  
**Purpose:** Bundles Azgaar files, copies to `user://azgaar/`, writes `options.json`  
**Methods:**
- `copy_azgaar_to_user()` - Recursive copy from `res://tools/azgaar/` to `user://azgaar/`
- `write_options(options: Dictionary) -> bool` - Writes `options.json` to `user://azgaar/`
- `get_azgaar_url() -> String` - Returns `file://` URL to `user://azgaar/index.html`

**Implementation Quality:**
- ✅ Typed GDScript, proper header, docstrings
- ✅ Error handling with MythosLogger
- ✅ Uses `user://` for writability (Azgaar needs to write state/indexedDB)

**Gaps:**
- No validation of options before writing
- No schema checking against Azgaar parameter requirements
- No caching/optimization for repeated writes

#### `res://scripts/ui/WorldBuilderAzgaar.gd`
**Status:** ✅ Active (extends Control, attached to `AzgaarContainer` node)  
**Purpose:** Wrapper for GDCef WebView embedding and communication  
**Key Variables:**
- `web_view: Node` - GDCef node reference
- `azgaar_integrator: Node` - Reference to AzgaarIntegrator singleton
- `poll_timer: Timer` - Polls for generation completion (2s interval)
- `generation_timeout_timer: Timer` - 60s timeout
- `current_generation_options: Dictionary` - Last-used options

**Signals:**
- `generation_started` - Emitted when generation begins
- `generation_complete` - Emitted when generation finishes (not yet implemented)
- `generation_failed(reason: String)` - Emitted on failure/timeout

**Methods:**
- `_initialize_webview()` - Initializes GDCef, attempts CEF init, creates browser
- `_create_azgaar_browser(url: String)` - Creates browser instance via `create_browser()`
- `_try_direct_url_loading()` / `_try_fallback_url_loading()` - Fallback URL loading methods
- `reload_azgaar()` - Reloads WebView (used after writing options.json)
- `trigger_generation_with_options(options: Dictionary, auto_generate: bool)` - Writes options, reloads, starts polling

**Gaps:**
- ❌ **No JavaScript execution bridge** - Cannot execute JS in Azgaar context
- ❌ **No completion detection** - `_on_poll_timeout()` is a stub (TODO comment)
- ❌ **No heightmap extraction** - No method to get `pack.cells.h` from Azgaar
- ⚠️ **GDCef API assumptions** - Code assumes `create_browser(url, texture_rect, options)` signature but not verified
- ⚠️ **No error recovery** - If CEF init fails, no graceful degradation

#### `res://ui/world_builder/WorldBuilderUI.gd`
**Status:** ✅ Active (main UI controller)  
**Purpose:** Single-screen Azgaar-first world builder UI  
**Key Variables:**
- `azgaar_mapping: Dictionary` - Loaded from `azgaar_parameter_mapping.json`
- `archetype_presets: Dictionary` - Loaded from `archetype_azgaar_presets.json`
- `step_data: Dictionary` - Stores `{"Azgaar": {param_name: value}}`
- `azgaar_parameter_controls: Dictionary` - `{param_name: Control}` mapping
- `hardware_profiler: HardwareProfiler` - For adaptive quality clamping

**UI References (via @onready):**
- `archetype_option_button: OptionButton` - Archetype dropdown
- `azgaar_tab_container: TabContainer` - Category-grouped parameter tabs
- `generate_azgaar_button: Button` - "Generate with Azgaar" button
- `azgaar_status_label: Label` - Status text
- `world_builder_azgaar: Node` - WorldBuilderAzgaar node
- `bake_button: Button` - "Bake to 3D" button (stub implementation)

**Key Methods:**
- `_load_azgaar_configs()` - Loads JSON configs
- `_setup_azgaar_ui()` - Populates archetype dropdown, builds parameter UI, connects signals
- `_build_azgaar_parameter_ui()` - Creates TabContainer tabs by category, builds controls per parameter
- `_create_control_for_param()` / `_create_slider()` / `_create_spinbox()` / `_create_checkbox()` / `_create_option_button()` - Control factory methods
- `_apply_archetype_preset(preset_name: String)` - Applies preset values to controls, with clamping
- `_clamp_parameter(param_name: String, value: Variant) -> Variant` - Hardware-based clamping (only `pointsInput` currently)
- `_on_param_value_changed()` - Updates `step_data` when control values change
- `_on_generate_azgaar_pressed()` - Collects options, calls `world_builder_azgaar.trigger_generation_with_options()`
- `_on_bake_to_3d_pressed()` - **STUB** - Shows "not yet implemented" dialog

**Gaps:**
- ❌ **Hardware clamping incomplete** - Only `pointsInput` clamped; `manorsInput` (medium impact) and `allowErosion` (medium impact) not clamped
- ⚠️ **Magic numbers present** - Slider/spinbox `custom_minimum_size` uses `Vector2(200, 0)` and `Vector2(100, 0)` instead of UIConstants
- ❌ **No seed input** - `optionsSeed` not exposed in UI (hardcoded to 12345 in generation)
- ❌ **Bake to 3D not implemented** - Heightmap extraction missing

### Scene Files

#### `res://ui/world_builder/WorldBuilderUI.tscn`
**Status:** ✅ Exists  
**Node Hierarchy:**
```
WorldBuilderUI (Control, theme=bg3_theme.tres)
├── MainSplit (HSplitContainer)
│   ├── LeftPanel (Control)
│   │   └── LeftVBox (VBoxContainer)
│   │       ├── TitleLabel (Label)
│   │       ├── ArchetypeOptionButton (OptionButton)
│   │       ├── AzgaarParamsTabContainer (TabContainer) - Dynamically populated
│   │       ├── GenerateButton (Button, custom_minimum_size.y=120)
│   │       └── StatusLabel (Label)
│   └── RightPanel (Control)
│       └── AzgaarContainer (Control, script=WorldBuilderAzgaar.gd)
│           └── AzgaarWebView (GDCef) - WebView node
├── BottomButtons (HBoxContainer)
│   ├── BakeButton (Button)
│   └── BackButton (Button)
```

**Theme Application:**
- ✅ Root Control uses `theme = preload("res://themes/bg3_theme.tres")`
- ✅ Theme overrides used for spacing (e.g., `theme_override_constants/shadow_offset_x`)

**Responsiveness:**
- ✅ HSplitContainer for left/right layout
- ✅ VBoxContainer/HBoxContainer for stacking
- ⚠️ **Magic numbers:** `custom_minimum_size = Vector2(0, 120)` on GenerateButton (should use `UIConstants.BUTTON_HEIGHT_LARGE`)
- ⚠️ **Anchors:** Some nodes use `offset_*` instead of anchors (acceptable for nested containers but not ideal)

### Supporting Files

#### `res://tools/azgaar/`
**Status:** ✅ Bundled Azgaar FMG (689+ files)  
**Key Files:**
- `index.html` - Main entry point
- `main.js` - Core generation logic
- `modules/heightmap-generator.js` - Heightmap generation (Voronoi-based)
- `modules/biomes.js`, `modules/burgs-and-states.js`, etc. - Feature modules
- `heightmaps/*.png` - Precreated heightmap templates

#### `res://tools/azgaar/AZGAAR_PARAMETERS.md`
**Status:** ✅ Documentation (375 lines)  
**Content:** Exhaustive parameter list with types, ranges, descriptions  
**Usage:** Reference for expanding `azgaar_parameter_mapping.json`

#### `res://core/utils/HardwareProfiler.gd`
**Status:** ✅ Exists and used  
**Purpose:** Detects hardware capabilities, determines quality presets  
**Quality Levels:** LOW, MEDIUM, HIGH (enum)  
**Used By:** `WorldBuilderUI._clamp_parameter()` for `pointsInput` clamping

**Clamping Logic (Current):**
```gdscript
match quality_level:
    HardwareProfiler.QualityLevel.LOW: max_points = 3
    HardwareProfiler.QualityLevel.MEDIUM: max_points = 6
    HardwareProfiler.QualityLevel.HIGH: max_points = 13
```

**Gaps:**
- Only used for `pointsInput`; could expand to clamp other high-impact parameters (e.g., `manorsInput`, map size)

---

## UI Implementation

### Node Tree Structure

**Root:** `Control` with `anchors_preset = PRESET_FULL_RECT` (full-screen)  
**Layout:** HSplitContainer for left (controls) / right (preview)  
**Theme:** `bg3_theme.tres` applied at root

### Responsiveness Checks

**✅ Compliant:**
- Uses `HSplitContainer` / `VBoxContainer` / `HBoxContainer` for layout
- Size flags set: `size_flags_horizontal = SIZE_EXPAND_FILL` on sliders/spinboxes
- Anchors: Root uses `PRESET_FULL_RECT`
- Theme: Applied via `theme = preload("res://themes/bg3_theme.tres")`
- UIConstants: Used for label widths (`LABEL_WIDTH_STANDARD`, `LABEL_WIDTH_NARROW`), spacing (`SPACING_MEDIUM`, `SPACING_SMALL`)

**⚠️ Partially Compliant:**
- **Magic numbers found:**
  - Line 291: `slider.custom_minimum_size = Vector2(200, 0)` (should use UIConstants)
  - Line 311: `spinbox.custom_minimum_size = Vector2(100, 0)` (should use UIConstants)
  - Scene file: `GenerateButton.custom_minimum_size = Vector2(0, 120)` (should use `UIConstants.BUTTON_HEIGHT_LARGE`)
- **Offset usage:** Some nodes in `.tscn` use `offset_*` properties (acceptable but not ideal for responsiveness)

### Dynamic UI Generation

**Category Grouping:**
- Parameters grouped into TabContainer tabs by `category` field
- Category order: `["Terrain & Heightmap", "Climate & Environment", "Societies & Politics", "Settlements & Scale"]`
- Each tab: ScrollContainer → VBoxContainer → parameter rows (HBoxContainer)

**Control Creation:**
- Factory pattern: `_create_control_for_param()` dispatches to type-specific creators
- Control metadata: `set_meta("param_name", param_name)` for identification
- Signal connections: Value change signals connected to `_on_param_value_changed()`
- Value labels: Sliders show current value in adjacent Label

**Data Flow:**
1. Configs loaded → `azgaar_mapping`, `archetype_presets`
2. UI built → Controls created, stored in `azgaar_parameter_controls`
3. User changes → `_on_param_value_changed()` → `step_data["Azgaar"][param_name] = value`
4. Generate pressed → Options collected from controls → `trigger_generation_with_options()`

---

## Bridge & Communication

### GDCef Integration

**Status:** ⚠️ **Partially Implemented / Assumed**  
**Location:** `cef_artifacts/` directory exists (GDCef extension files)

**Current Implementation:**
- `WorldBuilderUI.tscn` declares `AzgaarWebView` as `type="GDCef"` node
- `WorldBuilderAzgaar._initialize_webview()` attempts to:
  1. Get `AzgaarWebView` node
  2. Check if class is "GDCef"
  3. Check if CEF is alive (`is_alive()` method)
  4. Initialize CEF if needed (`initialize({})`)
  5. Create browser (`create_browser(url, null, {})`)

**Assumptions (Not Verified):**
- GDCef API: `create_browser(url: String, texture_rect: TextureRect, options: Dictionary)`
- CEF initialization: `initialize(settings: Dictionary) -> void`
- Browser lifecycle: Browser created as child node or accessible via getter

**Gaps:**
- ❌ **No JavaScript execution** - No `execute_javascript()` or equivalent method called
- ❌ **No event listeners** - No signals for page load, generation complete
- ⚠️ **Fallback only** - Relies on `options.json` file write + reload, not JS injection
- ❌ **No completion detection** - `_on_poll_timeout()` is stub; relies on 60s timeout

### Communication Method: options.json Fallback

**Current Flow:**
1. `WorldBuilderUI._on_generate_azgaar_pressed()` collects options from controls
2. Calls `AzgaarIntegrator.write_options(options)` → writes `user://azgaar/options.json`
3. Calls `world_builder_azgaar.trigger_generation_with_options(options, true)`
4. `WorldBuilderAzgaar` calls `reload_azgaar()` → reloads WebView
5. Azgaar `main.js` reads `options.json` on load (if file exists)

**Limitations:**
- ⚠️ **Requires page reload** - Not real-time parameter injection
- ⚠️ **Azgaar must support `options.json`** - Not verified in bundled Azgaar code
- ❌ **No bidirectional communication** - Cannot query Azgaar state (generation progress, completion)

### Test Infrastructure

**File:** `res://tests/gdcef_bridge_test.gd` (EditorScript)  
**Purpose:** Inspects GDCef node capabilities, lists methods/properties  
**Status:** Exists but not run during audit  
**Recommendation:** Run this test to verify GDCef API availability

---

## Parameter Handling

### Parameter Mapping

**Source:** `azgaar_parameter_mapping.json`  
**Structure:** Data-driven, extensible  
**Categories:** 4 categories defined, supports expansion

### Archetype Presets

**Source:** `archetype_azgaar_presets.json`  
**Count:** 4 presets  
**Application:** Dropdown selection → `_apply_archetype_preset()` → values set on controls  
**Hardware Adaptation:** Preset values clamped via `_clamp_parameter()` before setting

### Hardware Clamping

**Implementation:** `_clamp_parameter(param_name: String, value: Variant) -> Variant`  
**Current Scope:** **Only `pointsInput`**  
**Logic:**
- Checks `performance_impact == "high"` in mapping
- Gets `hardware_profiler.detected_quality` (LOW/MEDIUM/HIGH)
- Clamps `pointsInput` to 3/6/13 based on quality
- Shows ConfirmationDialog if clamped

**Gaps:**
- ❌ **Other high-impact params not clamped:** `manorsInput` (medium impact, could be high for large values), `allowErosion` (medium impact, could affect performance)
- ❌ **No adaptive defaults:** Presets don't consider hardware when loading
- ⚠️ **Clamping only on preset apply:** Manual control changes not clamped until generation (should clamp immediately)

### Parameter Validation

**Status:** ❌ **Not Implemented**  
**Gaps:**
- No range validation beyond UI control min/max
- No cross-parameter validation (e.g., `culturesInput <= statesNumber`)
- No schema validation against Azgaar requirements

---

## Generation & Export Pipeline

### Generation Trigger

**Flow:**
1. User clicks "Generate with Azgaar"
2. `_on_generate_azgaar_pressed()` collects options from controls
3. Adds `optionsSeed` (hardcoded 12345 if not in step_data)
4. Calls `world_builder_azgaar.trigger_generation_with_options(options, true)`
5. Button disabled, status label updated
6. `WorldBuilderAzgaar` writes options.json, reloads WebView
7. Polling timer started (2s interval, 60s timeout)

**Status:** ⚠️ **Partial** - Trigger works, but completion detection is stub

### Heightmap Export

**Status:** ❌ **Not Implemented**  
**Current:** `_on_bake_to_3d_pressed()` shows "not yet implemented" dialog

**Required Implementation:**
1. Extract heightmap data from Azgaar WebView (JS execution)
2. Get `pack.cells.h` (height array, 0-100 range)
3. Get `pack.cells.p` (positions, Voronoi cell centers)
4. Rasterize Voronoi cells to regular grid (Image)
5. Normalize heights to 0.0-1.0 range
6. Convert to `Image.FORMAT_RF`
7. Pass to `Terrain3DManager.generate_from_heightmap()`

**Challenges:**
- Azgaar uses **Voronoi cells** (irregular polygons), Terrain3D expects **regular grid**
- Need rasterization algorithm (nearest-neighbor or bilinear interpolation)
- JavaScript execution required to access `pack` object

**References:**
- `audit/azgaar_parameter_integration_audit_v2.md` lines 197-257 (rasterization strategy)
- `core/world_generation/Terrain3DManager.gd:166-211` (heightmap import method)

---

## Downstream Integrations

### EntitySim Integration

**Status:** ❌ **Stub Only**  
**File:** `core/sim/entity_sim.gd`  
**Current:** Only `_ready()` with logging, no data structures or logic

**Azgaar Data Available:**
- `pack.burgs[i]` - Settlement locations (x, y, cell, population, type)
- `pack.cells.pop[i]` - Rural population per cell
- `pack.cultures[i]` - Cultural regions

**Integration Needs:**
- Extract burg data after Azgaar generation
- Convert Azgaar coordinates to Godot world coordinates
- Create entity spawn points at burg locations
- Use population data for spawn density
- Use culture data for entity appearance/behavior

**Complexity:** MEDIUM - Requires coordinate transformation and entity system design

### FactionEconomy Integration

**Status:** ❌ **Stub Only**  
**File:** `core/sim/faction_economy.gd`  
**Current:** Only `_ready()` with logging, no data structures or logic

**Azgaar Data Available:**
- `pack.states[i]` - Faction definitions (name, capital, culture, type, expansionism, area)
- `pack.burgs[i]` - Economic centers (population, state affiliation)
- `pack.routes[i]` - Trade routes (path coordinates)

**Integration Needs:**
- Map `pack.states` to faction definitions
- Use burg population for economic strength
- Use routes for trade network
- Use provinces for resource distribution

**Complexity:** LOW - Direct mapping possible, but FactionEconomy needs implementation

### WorldStreamer Integration

**Status:** ❌ **Stub Only**  
**File:** `core/streaming/world_streamer.gd`  
**Current:** Only `_ready()` with logging, no streaming logic

**Azgaar Data Available:**
- `pack.cells.p` - Cell positions for streaming regions
- `pack.cells.biome[i]` - Biome per cell (region properties)
- `pack.cells.h[i]` - Height data (LOD selection)

**Integration Needs:**
- Divide Azgaar map into streaming regions (chunks)
- Use biome data for region properties
- Use height data for LOD selection
- Stream regions based on player position

**Complexity:** MEDIUM - Requires streaming system design

---

## Compliance Issues

### Code Style Compliance

**✅ Compliant:**
- Typed GDScript (`: Dictionary`, `: String`, `: Variant`)
- Snake_case variables, PascalCase classes
- Exact script headers (5-line block with ╔═══ format)
- Docstrings on public functions (`"""docstring"""`)
- One class per file

**⚠️ Minor Issues:**
- Line 291, 311: Magic numbers in `custom_minimum_size` (should use UIConstants)
- Scene file: `GenerateButton.custom_minimum_size = Vector2(0, 120)` (should use `UIConstants.BUTTON_HEIGHT_LARGE`)

### GUI Specification Compliance

**✅ Compliant:**
- Built-in containers (VBoxContainer, HBoxContainer, TabContainer, ScrollContainer)
- Size flags used (`SIZE_EXPAND_FILL`)
- Anchors used (root: `PRESET_FULL_RECT`)
- Theme applied (`bg3_theme.tres`)
- UIConstants used for label widths, spacing

**⚠️ Partially Compliant:**
- Magic numbers in slider/spinbox sizes (lines 291, 311)
- Scene file magic number for button height

**Recommendations:**
1. Replace `Vector2(200, 0)` with `Vector2(UIConstants.LABEL_WIDTH_WIDE, 0)` or add `SLIDER_WIDTH_STANDARD` constant
2. Replace `Vector2(100, 0)` with `Vector2(UIConstants.LABEL_WIDTH_STANDARD, 0)` or add `SPINBOX_WIDTH_STANDARD` constant
3. Replace `Vector2(0, 120)` with `Vector2(0, UIConstants.BUTTON_HEIGHT_LARGE)` in scene file

### Data-Driven Compliance

**✅ Compliant:**
- All parameters defined in JSON (`azgaar_parameter_mapping.json`)
- All presets defined in JSON (`archetype_azgaar_presets.json`)
- No hard-coded parameter values in scripts (except defaults/fallbacks)

### Performance Compliance

**✅ Compliant:**
- Hardware profiler used for adaptive quality
- Clamping logic exists (though limited scope)

**⚠️ Gaps:**
- Only `pointsInput` clamped; other high-impact parameters not clamped
- No FPS considerations during generation (polling timer runs regardless of frame time)

---

## Gaps & Recommendations

### Phase 1 Gaps (Parameter Mapping & UI)

**✅ Complete:**
- Parameter mapping JSON exists
- Archetype presets JSON exists
- UI controls built from mapping
- Category grouping (TabContainer)

**⚠️ Partial:**
- Hardware clamping only for `pointsInput`
- Missing many parameters from `AZGAAR_PARAMETERS.md`

**❌ Missing:**
- Seed input control (currently hardcoded)
- Cross-parameter validation
- Adaptive preset loading based on hardware

**Recommendations:**
1. Expand `azgaar_parameter_mapping.json` to include all parameters from `AZGAAR_PARAMETERS.md`
2. Add hardware clamping for `manorsInput` and other high-impact parameters
3. Add seed input control (SpinBox, 1-999999999)
4. Implement cross-parameter validation (e.g., `culturesInput <= statesNumber`)
5. Link archetype presets to `data/archetypes/*.json` files if needed

### Phase 2 Gaps (Bridge & Communication)

**❌ Critical Missing:**
- JavaScript execution bridge (GDCef `execute_javascript()` or equivalent)
- Generation completion detection (currently stub with 60s timeout)
- Bidirectional communication (Godot ↔ Azgaar)

**Recommendations:**
1. **Verify GDCef API:** Run `tests/gdcef_bridge_test.gd` to list available methods
2. **Implement JS execution:** Add `execute_azgaar_js(code: String) -> Variant` method to `WorldBuilderAzgaar`
3. **Implement completion detection:** Poll Azgaar state via JS (e.g., check if `pack` object exists and is populated)
4. **Add event listeners:** If GDCef supports signals, listen for page load/generation events
5. **Fallback strategy:** If JS execution unavailable, improve timeout/polling heuristic

### Phase 3 Gaps (Heightmap Export)

**❌ Critical Missing:**
- Heightmap extraction from Azgaar WebView
- Voronoi-to-grid rasterization
- Integration with Terrain3DManager

**Recommendations:**
1. **Implement heightmap extraction:**
   ```gdscript
   func export_azgaar_heightmap() -> Image:
       # Execute JS to get pack.cells data
       # Rasterize Voronoi cells to regular grid
       # Normalize to 0.0-1.0
       # Convert to Image.FORMAT_RF
       # Return Image
   ```
2. **Implement rasterization:** Nearest-neighbor (fast) or bilinear interpolation (smooth)
3. **Integrate with Bake button:** Modify `_on_bake_to_3d_pressed()` to call `export_azgaar_heightmap()` and pass to Terrain3DManager
4. **Add progress indicator:** Show progress during rasterization for large maps

### Phase 4 Gaps (Downstream Integration)

**❌ Missing:**
- EntitySim implementation (stub only)
- FactionEconomy implementation (stub only)
- WorldStreamer implementation (stub only)
- Azgaar data exporter (no bridge to extract `pack` object)

**Recommendations:**
1. **Create Azgaar data exporter:**
   ```gdscript
   func export_azgaar_world_data() -> Dictionary:
       # Execute JS to extract pack.states, pack.burgs, pack.routes, etc.
       # Convert to Godot-friendly format (Dictionary/Array)
       # Return structured data
   ```
2. **Design entity spawn system:** Use burg data for spawn points
3. **Design faction system:** Map states to factions
4. **Design streaming system:** Use cell data for region streaming
5. **Phase implementation:** Downstream systems depend on Azgaar data export being complete

### Additional Recommendations

1. **Testing:**
   - Add unit tests for parameter clamping logic
   - Add integration tests for options.json write/read
   - Test UI responsiveness on multiple resolutions

2. **Documentation:**
   - Document GDCef API assumptions/requirements
   - Document Azgaar data structure (`pack` object schema)
   - Document coordinate transformation (Azgaar → Godot world space)

3. **Error Handling:**
   - Add validation for options before writing
   - Add graceful degradation if GDCef unavailable
   - Add user-friendly error messages for generation failures

4. **Performance:**
   - Optimize options.json write (cache, only write on changes)
   - Consider async heightmap extraction for large maps
   - Add FPS-aware polling (pause if frame time too high)

---

## Audit Conclusion

The Azgaar integration has a **solid foundation** with well-structured, data-driven UI and proper separation of concerns. The parameter mapping and archetype preset systems are extensible and compliant with project rules. However, **critical gaps** remain in the bridge layer (JavaScript execution), heightmap export, and downstream system integration.

**Priority Actions:**
1. **HIGH:** Verify and implement GDCef JavaScript execution bridge
2. **HIGH:** Implement heightmap extraction and rasterization
3. **MEDIUM:** Expand hardware clamping to all high-impact parameters
4. **MEDIUM:** Add seed input control and cross-parameter validation
5. **LOW:** Implement downstream integrations (depends on data export)

**Estimated Effort:**
- Phase 1 completion: 4-8 hours
- Phase 2 (bridge): 8-16 hours (depends on GDCef API verification)
- Phase 3 (export): 16-24 hours (rasterization is complex)
- Phase 4 (downstream): 40+ hours (requires system design)

---

**Audit performed via Godot MCP actions on 2025-01-20.**  
**Next steps:** Verify GDCef API, implement JavaScript execution bridge, then proceed with heightmap export.

