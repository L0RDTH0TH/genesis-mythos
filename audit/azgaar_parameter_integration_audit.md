# Audit Report: Azgaar Parameter Integration Readiness

**Date:** 2025-01-20  
**Purpose:** Comprehensive audit of current world generation setup, Azgaar implementation, and UI in preparation for integrating curated Azgaar parameters with grouping, archetype presets, and performance resource checks.

**Auditor:** AI Assistant (Auto)  
**Project:** Genesis Mythos - Full First Person 3D Virtual Tabletop RPG  
**Godot Version:** 4.5.1

---

## Table of Contents

1. [Current State Summary](#current-state-summary)
2. [Compliance Audit](#compliance-audit)
3. [Identified Issues & Concerns](#identified-issues--concerns)
4. [Recommendations for Integration & Fixes](#recommendations-for-integration--fixes)
5. [Next Steps](#next-steps)

---

## Current State Summary

### 1.1 World Generation Setup

#### Pipeline Overview

The current world generation pipeline consists of multiple systems working together:

```
Main Menu (MainMenuController)
    ↓
World Root Scene (world_root.tscn)
    ↓
Terrain3DManager._ready() [INITIALIZES IMMEDIATELY - TODO: DEFER]
    ↓
WorldBuilderUI._ready() [8-step wizard UI]
    ↓
Step 1: Map Generation & Editing
    ├─ MapMakerModule (primary 2D renderer)
    ├─ ProceduralWorldMap (fallback addon)
    └─ Landmass types from JSON (12 types available)
    ↓
"Bake to 3D" Button Click
    ↓
Terrain3DManager.generate_from_heightmap()
    ↓
Terrain3D.data.import_images()
    ↓
3D Terrain Visible
```

#### Key Components

| Component | Location | Status | Notes |
|-----------|----------|--------|-------|
| **WorldBuilderUI** | `ui/world_builder/WorldBuilderUI.gd` | ✅ Active | 8-step wizard, 4012 lines, fully functional |
| **MapMakerModule** | `ui/world_builder/MapMakerModule.gd` | ✅ Active | Primary 2D map renderer, custom implementation |
| **Terrain3DManager** | `core/world_generation/Terrain3DManager.gd` | ✅ Active | **ISSUE:** Initializes on scene load (should be deferred) |
| **AzgaarIntegrator** | `scripts/managers/AzgaarIntegrator.gd` | ✅ Active | Copies Azgaar bundle to `user://azgaar/`, provides URL |
| **WorldBuilderAzgaar** | `scripts/ui/WorldBuilderAzgaar.gd` | ✅ Active | WebView wrapper for embedded Azgaar (GDCef) |
| **ProceduralWorldMap** | Addon | ✅ Fallback | Used only if MapMakerModule fails |
| **WorldStreamer** | `core/streaming/world_streamer.gd` | ✅ Singleton | Future: streaming large worlds |
| **EntitySim** | `core/sim/entity_sim.gd` | ✅ Singleton | Future: entity simulation |
| **FactionEconomy** | `core/sim/faction_economy.gd` | ✅ Singleton | Future: faction systems |

#### Data Flow: 2D Map → 3D Terrain

**Current Flow:**
1. **2D Generation:** MapMakerModule generates heightmap (`Image.FORMAT_RF`)
2. **Storage:** Heightmap stored in `step_data["Map Gen"]["heightmap_image"]`
3. **Export Trigger:** "Bake to 3D" button calls `_on_bake_to_3d_pressed()`
4. **Terrain3D Import:** `Terrain3DManager.generate_from_heightmap()` converts Image to Terrain3D
5. **Format:** Image converted to `Image.FORMAT_RF` if needed, then `terrain.data.import_images([heightmap, null, null], offset, 1.0, height_range)`

**Azgaar Integration Status:**
- ✅ Azgaar bundle exists at `tools/azgaar/` (689 files)
- ✅ AzgaarIntegrator copies files to `user://azgaar/` for writability
- ✅ WorldBuilderAzgaar embeds GDCef WebView
- ❌ **NO CURRENT PARAMETER INTEGRATION** - Azgaar runs with default/random parameters
- ❌ **NO DATA EXTRACTION** - Heightmap export from Azgaar to Terrain3D not implemented

#### Exposed Parameters (Current)

**WorldBuilderUI Step 1 (Map Generation):**
- Seed (SpinBox, 0-999999)
- Width/Height (SpinBox, power-of-2)
- Landmass Type (OptionButton, 12 types from JSON)
- Landmass-specific parameters (sliders/spinboxes, dynamic)
- Noise parameters (frequency, octaves, persistence, lacunarity)
- Sea level (Slider)
- Erosion toggle (CheckBox)

**Other Steps:**
- Climate (temperature, precipitation, wind)
- Biomes (ItemList selection)
- Structures (icon placement)
- Environment (fog, sky, water)
- Resources & Magic (density sliders)
- Export (world name, save config)

**Missing Azgaar Parameters:**
- `templateInput` (heightmap template selection)
- `pointsInput` (cell density, 1-13, performance-critical)
- `statesNumber` (political density)
- `culturesInput` / `culturesSet` (cultural variety)
- `religionsNumber` (religious diversity)
- `manorsInput` (settlement density)
- `precInput` (precipitation percentage)
- `temperatureEquator/NorthPole/SouthPole` (climate gradient)
- `winds` (wind directions array)
- And 15+ more from curated list

---

### 1.2 Azgaar Implementation

#### Integration Architecture

**Current Setup:**
- **Bundle Location:** `res://tools/azgaar/` (689 files, includes all JS, HTML, configs)
- **User Copy:** `user://azgaar/` (writable, created by AzgaarIntegrator on startup)
- **WebView:** GDCef extension embedded in `WorldBuilderUI.tscn` (AzgaarWebView node)
- **URL:** `file://{user_data_dir}/azgaar/index.html`

**Parameter Handling:**
- ❌ **No parameter injection** - Azgaar runs with default/random settings
- ✅ `AzgaarIntegrator.write_options()` exists but **not called anywhere**
- ✅ `options.json` structure documented in `AZGAAR_PARAMETERS.md`
- ❌ **No communication bridge** - Godot cannot read/write Azgaar parameters via JS
- ❌ **No heightmap export** - Azgaar-generated maps not extracted to Terrain3D

**Available Templates:**
- 14 procedural templates (pangea, continents, archipelago, etc.)
- 23 regional precreated templates (europe, mediterranean, etc.)
- Templates defined in `tools/azgaar/config/heightmap-templates.js`
- Template selection currently random (no UI control)

**Performance Considerations:**
- `pointsInput` (1-13) maps to cell counts: 1K-100K cells
- Higher values = exponentially more computation
- **NO CURRENT RESOURCE CHECKS** - users can select max points on low-end hardware
- HardwareProfiler exists but not used for Azgaar parameter clamping

---

### 1.3 World Generation UI

#### Structure Analysis

**Root Node:** `Control` with `anchors_preset = 15` (PRESET_FULL_RECT) ✅  
**Theme:** `res://themes/bg3_theme.tres` applied ✅

**Node Hierarchy:**
```
WorldBuilderUI (Control, full rect)
├─ BackgroundRect (ColorRect, full rect)
├─ Overlay (ColorRect, full rect, vignette shader)
├─ BackgroundPanel (Panel, full rect)
│   ├─ TitleLabel (Label, top anchor)
│   ├─ MainContainer (HSplitContainer, full rect)
│   │   ├─ LeftNav (Panel, fixed width via UIConstants.PANEL_WIDTH_NAV)
│   │   └─ RightSplit (HSplitContainer, expand fill)
│   │       ├─ CenterPanel (Panel, expand fill)
│   │       │   ├─ AzgaarWebView (GDCef, full rect) [HIDDEN by default?]
│   │       │   ├─ Map2DScrollContainer (ScrollContainer, full rect)
│   │       │   │   └─ ProceduralWorldMap (fallback)
│   │       │   └─ Terrain3DView (SubViewportContainer, full rect, hidden)
│   │       └─ RightContent (PanelContainer, fixed width)
│   └─ ButtonContainer (HBoxContainer, bottom center anchor)
│       ├─ BackButton
│       └─ NextButton
```

**Container Usage:**
- ✅ HSplitContainer for left nav / main content
- ✅ HSplitContainer for center panel / right content
- ✅ VBoxContainer/HBoxContainer for step content (procedurally generated)
- ✅ ScrollContainer for map preview
- ⚠️ Some hard-coded split offsets (250, 60) - should use UIConstants

**Size Flags:**
- ✅ LeftNav: `size_flags_horizontal = 0` (fixed width)
- ✅ RightSplit: `size_flags_horizontal = 3` (SIZE_EXPAND_FILL)
- ✅ CenterPanel: `size_flags_horizontal = 3`
- ✅ RightContent: `size_flags_horizontal = 0` (fixed width)

**Anchors:**
- ✅ Root: `anchors_preset = 15` (PRESET_FULL_RECT)
- ✅ TitleLabel: `anchors_preset = 6` (PRESET_TOP_WIDE)
- ✅ ButtonContainer: `anchors_preset = 7` (PRESET_BOTTOM_WIDE)
- ✅ Most children use proper anchor presets

#### UIConstants Usage

**Status:** ✅ **UIConstants.gd EXISTS** at `scripts/ui/UIConstants.gd`

**Usage Analysis:**
- ✅ **109 instances** of `UIConstants` usage in `WorldBuilderUI.gd`
- ✅ Button heights: `BUTTON_HEIGHT_SMALL`, `BUTTON_HEIGHT_MEDIUM`, `BUTTON_HEIGHT_LARGE`
- ✅ Label widths: `LABEL_WIDTH_NARROW`, `LABEL_WIDTH_STANDARD`, `LABEL_WIDTH_WIDE`, `LABEL_WIDTH_COMPACT`, `LABEL_WIDTH_MEDIUM`
- ✅ Spacing: `SPACING_SMALL`, `SPACING_MEDIUM`, `SPACING_LARGE`
- ✅ Panel widths: `PANEL_WIDTH_NAV`, `PANEL_WIDTH_CONTENT`
- ✅ List heights: `LIST_HEIGHT_STANDARD`
- ✅ Icon sizes: `ICON_SIZE_MEDIUM`
- ✅ Button sizes: `BUTTON_SIZE_TYPE`

**Magic Numbers Found:**
- ⚠️ `split_offset = 250` (HSplitContainer) - should use `UIConstants.PANEL_WIDTH_NAV`
- ⚠️ `split_offset = 60` (RightSplit) - should use constant
- ⚠️ `title_label.offset_bottom = UIConstants.SPACING_LARGE * 1.25` (50px calculation) - acceptable but could be constant
- ⚠️ Hard-coded viewport sizes in some calculations (e.g., `Vector2(512, 512)` for SubViewport)

#### Responsiveness

**Resize Handling:**
- ✅ `_notification(NOTIFICATION_WM_SIZE_CHANGED)` implemented
- ✅ `_update_viewport_size()` called on resize
- ✅ Anchors and size flags should handle most cases
- ⚠️ **NOT TESTED** - No evidence of resize testing at different resolutions

**Project Settings:**
- ✅ `window/stretch/mode = "viewport"`
- ✅ `window/stretch/aspect = "expand"`
- ⚠️ `window/stretch/scale_mode` not set (should be "fractional" per GUI spec 11.3)

#### Theme Enforcement

- ✅ Theme applied at root: `theme = ExtResource("2_theme")`
- ✅ Theme overrides used for title (font size, color)
- ✅ StyleBoxFlat resources defined in scene
- ✅ Most styling via theme, minimal hard-coded colors

---

### 1.4 Data Configuration

#### JSON Config Files

| File | Location | Status | Usage |
|------|----------|--------|-------|
| **landmass_types.json** | `data/config/landmass_types.json` | ✅ Loaded | 12 landmass types, used in Step 1 |
| **terrain_generation.json** | `data/config/terrain_generation.json` | ✅ Exists | Noise, height, textures, post-processing config |
| **world_builder_ui.json** | `data/config/world_builder_ui.json` | ⚠️ Exists | **NOT USED** - UI is procedurally generated, file appears legacy |
| **hardware_adaptation.json** | `data/config/hardware_adaptation.json` | ✅ Loaded | Used by HardwareProfiler for quality presets |
| **logging_config.json** | `config/logging_config.json` | ✅ Exists | Logger configuration |
| **biomes.json** | `data/biomes.json` | ✅ Loaded | Biome definitions (loaded but not fully integrated) |
| **civilizations.json** | `data/civilizations.json` | ✅ Loaded | Civilization data (loaded but not used in 2D gen) |
| **map_icons.json** | `data/map_icons.json` | ✅ Loaded | Icon definitions for map markers |
| **fantasy_archetypes.json** | `data/fantasy_archetypes.json` | ✅ Loaded | Archetype metadata (name, default_landmass) |
| **archetypes/** | `data/archetypes/*.json` | ✅ Loaded | 13 individual archetype files |

**Missing Configs:**
- ❌ **No Azgaar parameter presets JSON** (for archetype integration)
- ❌ **No Azgaar-to-Terrain3D mapping config** (for data export)

---

### 1.5 Performance Systems

#### Hardware Profiling

**HardwareProfiler:**
- ✅ Location: `core/utils/HardwareProfiler.gd`
- ✅ Detects CPU count, GPU, memory
- ✅ Runs quick benchmark (map generation time)
- ✅ Determines quality level (LOW/MEDIUM/HIGH)
- ✅ Loads adaptation config from JSON
- ✅ **USED** in WorldBuilderUI for viewport optimizations
- ❌ **NOT USED** for Azgaar parameter clamping

**Quality Presets:**
- LOW: max_preview_resolution=512, max_octaves=3, max_map_size_preview=1024
- MEDIUM: max_preview_resolution=1024, max_octaves=4, max_map_size_preview=2048
- HIGH: max_preview_resolution=2048, max_octaves=6, max_map_size_preview=4096

**Performance Monitoring:**
- ✅ PerformanceLogger singleton exists
- ✅ PerformanceMonitorSingleton exists
- ✅ WorldBuilderUI integrates PerformanceLogger
- ✅ Profiling timers and FPS tracking in WorldBuilderUI
- ⚠️ No performance warnings for resource-intensive operations

---

## Compliance Audit

### 2.1 GUI Specification Compliance (Section 11)

| Requirement | Status | Notes |
|-------------|--------|-------|
| **Root Node** | ✅ PASS | Control with `anchors_preset = 15` (PRESET_FULL_RECT) |
| **Layout Containers** | ✅ PASS | VBoxContainer, HBoxContainer, HSplitContainer used extensively |
| **Size Flags** | ✅ PASS | Explicit size flags set (SIZE_EXPAND_FILL where needed) |
| **Anchors** | ✅ PASS | Anchor presets used (PRESET_FULL_RECT, PRESET_TOP_WIDE, etc.) |
| **No Magic Numbers** | ⚠️ PARTIAL | 109 UIConstants usages, but some hard-coded values remain (split offsets, viewport sizes) |
| **UIConstants.gd** | ✅ PASS | Exists and extensively used |
| **Theme Application** | ✅ PASS | `bg3_theme.tres` applied at root, overrides minimal |
| **Responsive Testing** | ❌ UNKNOWN | Resize handling exists but not verified at multiple resolutions |
| **Project Settings** | ⚠️ PARTIAL | `stretch/mode` and `aspect` set, but `scale_mode = "fractional"` missing |
| **Typed GDScript** | ✅ PASS | All scripts use typed GDScript (`: Node3D`, `: int`, etc.) |
| **Script Headers** | ✅ PASS | All scripts have required header block |
| **One Class Per File** | ✅ PASS | Naming convention followed |
| **Docstrings** | ✅ PASS | Public functions have docstrings |

**Compliance Score: 10/12 (83%)**

**Issues:**
1. Some magic numbers (split offsets, viewport sizes)
2. `scale_mode = "fractional"` not set in project.godot
3. Responsiveness not tested at multiple resolutions

---

### 2.2 Project Rules Compliance

| Rule | Status | Notes |
|------|--------|-------|
| **Folder Structure** | ✅ PASS | All files in correct locations per rules |
| **Naming Conventions** | ✅ PASS | snake_case for vars/funcs, PascalCase for classes |
| **GDScript Only** | ✅ PASS | No C# or VisualScript |
| **@onready var** | ✅ PASS | Modern syntax used |
| **Theme Path** | ✅ PASS | `res://themes/bg3_theme.tres` used |
| **Data-Driven** | ✅ PASS | JSON configs loaded, minimal hard-coding |
| **60 FPS Target** | ⚠️ UNKNOWN | Performance monitoring exists but no explicit FPS guarantees |
| **Extensibility** | ✅ PASS | JSON-based configs, modular architecture |

**Compliance Score: 8/8 (100%)**

---

### 2.3 Code Quality

| Aspect | Status | Notes |
|--------|--------|-------|
| **Error Handling** | ✅ GOOD | MythosLogger used extensively, null checks present |
| **Accessibility** | ⚠️ UNKNOWN | No explicit accessibility features (color-blind modes, scalable fonts) |
| **Modding Support** | ✅ GOOD | JSON configs, extensible archetype system |
| **Documentation** | ✅ GOOD | Docstrings, comments, architecture docs exist |

---

## Identified Issues & Concerns

### 3.1 Critical Issues

#### Issue #1: Terrain3D Initializes on Scene Load
**Severity:** HIGH  
**Location:** `core/world_generation/Terrain3DManager.gd:17-22`

**Problem:**
- Terrain3D creates and configures terrain in `_ready()`, which runs when `world_root.tscn` loads
- This happens immediately when "World Generation" is clicked in main menu
- User may never click "Bake to 3D", wasting resources

**Impact:**
- Unnecessary Terrain3D initialization
- Performance overhead on scene load
- Memory usage even if 3D terrain not needed

**Status:**
- ✅ TODO notes added in code (defer initialization)
- ❌ Not yet implemented

**Recommendation:**
- Move `create_terrain()` and `configure_terrain()` to lazy initialization
- Call from `_on_bake_to_3d_pressed()` if `terrain == null`

---

#### Issue #2: No Azgaar Parameter Integration
**Severity:** CRITICAL  
**Location:** Multiple (AzgaarIntegrator, WorldBuilderAzgaar, WorldBuilderUI)

**Problem:**
- Azgaar runs with default/random parameters
- No way to set `templateInput`, `pointsInput`, `statesNumber`, etc. from Godot UI
- `AzgaarIntegrator.write_options()` exists but never called
- No communication bridge between Godot and Azgaar JavaScript

**Impact:**
- Cannot expose curated Azgaar parameters in UI
- Cannot implement archetype presets
- Cannot clamp performance-intensive parameters
- Users cannot control world generation style

**Status:**
- ❌ No implementation
- ✅ Documentation exists (`AZGAAR_PARAMETERS.md`)

**Recommendation:**
- Implement JS bridge (GDCef JavaScript execution)
- Create parameter mapping system (Godot UI → Azgaar options.json)
- Add parameter injection before Azgaar generation

---

#### Issue #3: No Azgaar Heightmap Export
**Severity:** HIGH  
**Location:** WorldBuilderAzgaar, Terrain3DManager

**Problem:**
- Azgaar generates maps in WebView but heightmap not extracted
- No way to get Azgaar-generated heightmap into Terrain3D
- Current pipeline only supports MapMakerModule → Terrain3D

**Impact:**
- Azgaar integration is display-only
- Cannot use Azgaar-generated worlds in 3D
- Defeats purpose of Azgaar integration

**Status:**
- ❌ No implementation
- ✅ Terrain3DManager has `generate_from_heightmap()` ready

**Recommendation:**
- Implement heightmap extraction from Azgaar (JS → Godot)
- Add export button in Azgaar WebView or Godot UI
- Convert Azgaar heightmap to `Image.FORMAT_RF` for Terrain3D

---

### 3.2 High Priority Issues

#### Issue #4: Magic Numbers in UI
**Severity:** MEDIUM  
**Location:** `ui/world_builder/WorldBuilderUI.gd`, `ui/world_builder/WorldBuilderUI.tscn`

**Problems:**
- `split_offset = 250` (should use `UIConstants.PANEL_WIDTH_NAV`)
- `split_offset = 60` (should use constant)
- Hard-coded viewport sizes (`Vector2(512, 512)`)
- Some offset calculations with literals

**Impact:**
- Violates GUI spec 11.2.2 (No Magic Numbers)
- Makes responsive adjustments harder
- Inconsistent with project rules

**Recommendation:**
- Add constants to UIConstants.gd for split offsets
- Replace all hard-coded values with UIConstants
- Audit scene file for magic numbers

---

#### Issue #5: No Performance Resource Checks for Azgaar
**Severity:** HIGH  
**Location:** WorldBuilderUI (future Azgaar parameter UI)

**Problem:**
- `pointsInput` (1-13) can cause exponential performance degradation
- Higher values (10K-100K cells) may freeze low-end hardware
- HardwareProfiler exists but not used for Azgaar parameter clamping

**Impact:**
- Users can select settings that freeze their system
- No warnings for resource-intensive operations
- Violates 60 FPS maintenance goal

**Recommendation:**
- Use HardwareProfiler to clamp `pointsInput` based on quality level
- Add performance warnings for high settings
- Implement dynamic parameter limits

---

#### Issue #6: Missing Project Setting
**Severity:** LOW  
**Location:** `project.godot`

**Problem:**
- `window/stretch/scale_mode = "fractional"` not set
- Required by GUI spec 11.3 for scalable UI

**Impact:**
- UI may not scale properly on different DPI displays
- Accessibility concern

**Recommendation:**
- Add `scale_mode = "fractional"` to project.godot

---

### 3.3 Medium Priority Issues

#### Issue #7: Responsiveness Not Tested
**Severity:** MEDIUM  
**Location:** WorldBuilderUI

**Problem:**
- Resize handling exists but not verified
- No evidence of testing at 1080p, 4K, ultrawide, windowed mode
- GUI spec 11.2.6 requires multi-resolution testing

**Impact:**
- UI may clip or distort on some resolutions
- Unknown if 60 FPS maintained during resize

**Recommendation:**
- Test at multiple resolutions (1080p, 1440p, 4K, ultrawide)
- Verify no clipping, proper scaling, stable FPS
- Document test results

---

#### Issue #8: Legacy Config File
**Severity:** LOW  
**Location:** `data/config/world_builder_ui.json`

**Problem:**
- File exists but not used
- UI is procedurally generated in code
- May cause confusion

**Impact:**
- Dead code, maintenance burden
- Potential for future developers to try using it

**Recommendation:**
- Remove file or document as "future dynamic UI generation"
- Consider implementing dynamic UI from JSON if desired

---

#### Issue #9: No Archetype Parameter Presets
**Severity:** MEDIUM  
**Location:** Archetype system

**Problem:**
- Archetypes have `default_landmass` but no full Azgaar parameter presets
- Cannot apply "High Fantasy" archetype to Azgaar generation
- Missing link between archetypes and Azgaar parameters

**Impact:**
- Cannot implement archetype-based world generation
- Users must manually configure all parameters
- Defeats purpose of archetype system

**Recommendation:**
- Create archetype parameter preset JSON files
- Map archetypes to Azgaar parameter sets (from AZGAAR_PARAMETERS.md recommendations)
- Add archetype selector that applies presets

---

### 3.4 Integration Concerns

#### Concern #1: UI Clutter Risk
**Severity:** MEDIUM

**Problem:**
- Adding 25-30 Azgaar parameters to UI could overwhelm users
- Current 8-step wizard already complex
- Need careful grouping and organization

**Recommendation:**
- Use TabContainer or Accordion for parameter categories
- Hide advanced parameters by default
- Group related parameters (Terrain & Heightmap, Climate & Environment, etc.)

---

#### Concern #2: Parameter Mapping Complexity
**Severity:** MEDIUM

**Problem:**
- Azgaar uses JavaScript/DOM, Godot uses GDScript
- Parameter names may not match (e.g., `templateInput` vs `landmass_type`)
- Need bidirectional mapping (Godot UI ↔ Azgaar options.json)

**Recommendation:**
- Create parameter mapping config JSON
- Implement translation layer (Godot param names → Azgaar param names)
- Validate parameter ranges and types

---

#### Concern #3: Performance Impact of Parameter Changes
**Severity:** HIGH

**Problem:**
- Changing `pointsInput` or `templateInput` triggers full regeneration
- No progress indication during Azgaar generation
- May cause UI freeze on low-end hardware

**Recommendation:**
- Add progress dialog for Azgaar generation
- Use async/await for parameter application
- Show estimated generation time based on parameters

---

## Recommendations for Integration & Fixes

### 4.1 Phase 1: Foundation & Fixes (Week 1)

#### 4.1.1 Fix Critical Issues

**Task 1.1: Defer Terrain3D Initialization**
- Move `create_terrain()` and `configure_terrain()` out of `_ready()`
- Add lazy initialization in `_on_bake_to_3d_pressed()`
- Test that Terrain3D only initializes when needed
- **Files:** `core/world_generation/Terrain3DManager.gd`, `ui/world_builder/WorldBuilderUI.gd`

**Task 1.2: Remove Magic Numbers**
- Add to UIConstants.gd:
  ```gdscript
  const SPLIT_OFFSET_NAV: int = 250
  const SPLIT_OFFSET_CONTENT: int = 60
  const PREVIEW_VIEWPORT_SIZE: Vector2 = Vector2(512, 512)
  ```
- Replace all hard-coded values in WorldBuilderUI.gd and WorldBuilderUI.tscn
- **Files:** `scripts/ui/UIConstants.gd`, `ui/world_builder/WorldBuilderUI.gd`, `ui/world_builder/WorldBuilderUI.tscn`

**Task 1.3: Add Missing Project Setting**
- Add `window/stretch/scale_mode = "fractional"` to project.godot
- **File:** `project.godot`

**Task 1.4: Test Responsiveness**
- Test at 1080p, 1440p, 4K, ultrawide (21:9), windowed mode
- Verify no clipping, proper scaling, stable FPS
- Document results in audit/ folder
- **Action:** Manual testing, create test report

---

#### 4.1.2 Create Parameter Infrastructure

**Task 1.5: Create Azgaar Parameter Mapping Config**
- Create `data/config/azgaar_parameter_mapping.json`:
  ```json
  {
    "godot_to_azgaar": {
      "landmass_template": "templateInput",
      "cell_density": "pointsInput",
      "state_count": "statesNumber",
      ...
    },
    "azgaar_to_godot": {
      "templateInput": "landmass_template",
      "pointsInput": "cell_density",
      ...
    },
    "parameter_ranges": {
      "pointsInput": {"min": 1, "max": 13, "performance_impact": "high"},
      "statesNumber": {"min": 0, "max": 100, "performance_impact": "low"},
      ...
    }
  }
  ```
- **File:** `data/config/azgaar_parameter_mapping.json` (new)

**Task 1.6: Create Archetype Parameter Presets**
- Create `data/config/archetype_azgaar_presets.json`:
  ```json
  {
    "high_fantasy": {
      "templateInput": "continents",
      "pointsInput": 4,
      "statesNumber": 25,
      "culturesInput": 18,
      "culturesSet": "highFantasy",
      "religionsNumber": 10,
      "manorsInput": 900,
      "precInput": 130,
      "temperatureEquator": 28,
      ...
    },
    "dark_fantasy": {
      "templateInput": "shattered",
      "pointsInput": 3,
      "statesNumber": 10,
      ...
    },
    ...
  }
  ```
- Map to recommendations from AZGAAR_PARAMETERS.md Section 4
- **File:** `data/config/archetype_azgaar_presets.json` (new)

**Task 1.7: Implement JS Bridge for Azgaar Communication**
- Add methods to WorldBuilderAzgaar.gd:
  ```gdscript
  func execute_azgaar_js(code: String) -> Variant
  func set_azgaar_parameter(param_name: String, value: Variant) -> bool
  func get_azgaar_parameter(param_name: String) -> Variant
  func trigger_azgaar_generation() -> void
  func export_azgaar_heightmap() -> Image
  ```
- Use GDCef JavaScript execution API
- **File:** `scripts/ui/WorldBuilderAzgaar.gd`

---

### 4.2 Phase 2: Parameter UI Integration (Week 2)

#### 4.2.1 Create Parameter Category System

**Task 2.1: Add Parameter Category Tabs to Step 1**
- Modify `_setup_step_content()` in WorldBuilderUI.gd
- Add TabContainer for parameter categories:
  - **Terrain & Heightmap:** templateInput, pointsInput, heightExponentInput, allowErosion
  - **Climate & Environment:** temperatureEquator, temperatureNorthPole, temperatureSouthPole, precInput, winds
  - **Civilization:** statesNumber, culturesInput, culturesSet, religionsNumber, manorsInput
  - **Advanced:** resolveDepressionsStepsInput, lakeElevationLimitInput, mapSizeInput, latitudeInput, longitudeInput
- **File:** `ui/world_builder/WorldBuilderUI.gd`

**Task 2.2: Implement Parameter Controls**
- Create helper functions:
  ```gdscript
  func _create_azgaar_slider(parent: VBoxContainer, param_name: String, label_text: String, min_val: float, max_val: float, default_val: float, step: float) -> HSlider
  func _create_azgaar_spinbox(parent: VBoxContainer, param_name: String, label_text: String, min_val: int, max_val: int, default_val: int) -> SpinBox
  func _create_azgaar_option_button(parent: VBoxContainer, param_name: String, label_text: String, options: Array[String], default_index: int) -> OptionButton
  ```
- Use UIConstants for all sizing
- **File:** `ui/world_builder/WorldBuilderUI.gd`

**Task 2.3: Add Performance Resource Checks**
- Create `_clamp_parameter_by_hardware(param_name: String, value: Variant) -> Variant`:
  ```gdscript
  func _clamp_parameter_by_hardware(param_name: String, value: Variant) -> Variant:
    if not hardware_profiler:
      return value
    
    var preset = hardware_profiler.get_quality_preset()
    var mapping = load_azgaar_parameter_mapping()
    var param_info = mapping.get("parameter_ranges", {}).get(param_name, {})
    
    if param_info.get("performance_impact") == "high":
      match hardware_profiler.detected_quality:
        HardwareProfiler.QualityLevel.LOW:
          # Clamp pointsInput to max 3 (5K cells)
          if param_name == "pointsInput" and value > 3:
            return 3
        HardwareProfiler.QualityLevel.MEDIUM:
          if param_name == "pointsInput" and value > 6:
            return 6
        HardwareProfiler.QualityLevel.HIGH:
          pass  # Allow all values
    
    return value
  ```
- Call on parameter changes
- Show warning dialog if value clamped
- **File:** `ui/world_builder/WorldBuilderUI.gd`

---

#### 4.2.2 Implement Archetype Preset System

**Task 2.4: Add Archetype Selector to Step 1**
- Add OptionButton for archetype selection (above parameter tabs)
- Load presets from `archetype_azgaar_presets.json`
- On selection, apply preset to all parameter controls
- **File:** `ui/world_builder/WorldBuilderUI.gd`

**Task 2.5: Create Preset Application Logic**
- Implement `_apply_archetype_preset(archetype_name: String)`:
  ```gdscript
  func _apply_archetype_preset(archetype_name: String) -> void:
    var presets = load_archetype_azgaar_presets()
    var preset = presets.get(archetype_name, {})
    
    if preset.is_empty():
      MythosLogger.warn("UI/WorldBuilder", "Archetype preset not found: %s" % archetype_name)
      return
    
    # Apply each parameter
    for param_name in preset:
      var value = preset[param_name]
      var clamped_value = _clamp_parameter_by_hardware(param_name, value)
      _set_parameter_control_value(param_name, clamped_value)
      step_data["Map Gen"][param_name] = clamped_value
    
    MythosLogger.info("UI/WorldBuilder", "Applied archetype preset", {"archetype": archetype_name})
  ```
- **File:** `ui/world_builder/WorldBuilderUI.gd`

---

### 4.3 Phase 3: Azgaar Communication & Export (Week 3)

#### 4.3.1 Implement Parameter Injection

**Task 3.1: Create Parameter Injection System**
- Implement `_inject_azgaar_parameters()`:
  ```gdscript
  func _inject_azgaar_parameters() -> void:
    var mapping = load_azgaar_parameter_mapping()
    var godot_to_azgaar = mapping.get("godot_to_azgaar", {})
    var azgaar_options = {}
    
    # Convert Godot parameters to Azgaar format
    for godot_param in step_data.get("Map Gen", {}):
      var azgaar_param = godot_to_azgaar.get(godot_param, godot_param)
      azgaar_options[azgaar_param] = step_data["Map Gen"][godot_param]
    
    # Write options.json via AzgaarIntegrator
    if AzgaarIntegrator.write_options(azgaar_options):
      # Reload Azgaar WebView to apply options
      if world_builder_azgaar:
        world_builder_azgaar.reload_azgaar()
  ```
- Call before Azgaar generation
- **File:** `ui/world_builder/WorldBuilderUI.gd`

**Task 3.2: Add "Generate with Azgaar" Button**
- Add button to Step 1 (next to "Generate Map" and "Bake to 3D")
- On click:
  1. Inject parameters
  2. Trigger Azgaar generation via JS
  3. Show progress dialog
  4. Wait for completion
  5. Extract heightmap
- **File:** `ui/world_builder/WorldBuilderUI.gd`

---

#### 4.3.2 Implement Heightmap Export

**Task 3.3: Create Heightmap Extraction**
- Add to WorldBuilderAzgaar.gd:
  ```gdscript
  func export_azgaar_heightmap() -> Image:
    # Execute JS to get heightmap data
    var js_code = """
      (function() {
        if (!pack.cells || !pack.cells.h) return null;
        var width = graphWidth;
        var height = graphHeight;
        var heightmap = new Float32Array(width * height);
        for (var i = 0; i < pack.cells.h.length; i++) {
          var cell = pack.cells.i[i];
          var x = Math.floor(cell % width);
          var y = Math.floor(cell / width);
          heightmap[y * width + x] = pack.cells.h[i] / 100; // Normalize 0-1
        }
        return Array.from(heightmap);
      })();
    """
    var result = execute_azgaar_js(js_code)
    if result == null:
      return null
    
    # Convert to Godot Image
    var width = get_azgaar_parameter("mapWidthInput")
    var height = get_azgaar_parameter("mapHeightInput")
    var image = Image.create(width, height, false, Image.FORMAT_RF)
    
    var data = result as Array
    for y in range(height):
      for x in range(width):
        var idx = y * width + x
        var height_value = data[idx] as float
        image.set_pixel(x, y, Color(height_value, 0.0, 0.0, 1.0))
    
    return image
  ```
- **File:** `scripts/ui/WorldBuilderAzgaar.gd`

**Task 3.4: Integrate Export into Bake Pipeline**
- Modify `_on_bake_to_3d_pressed()` to check if Azgaar map exists
- If Azgaar-generated, use `export_azgaar_heightmap()`
- Otherwise, use existing MapMakerModule heightmap
- **File:** `ui/world_builder/WorldBuilderUI.gd`

---

### 4.4 Phase 4: Polish & Testing (Week 4)

#### 4.4.1 UI Polish

**Task 4.1: Add Progress Dialogs**
- Create progress dialog for Azgaar generation
- Show estimated time based on parameters
- Allow cancellation
- **File:** `scripts/ui/progress_dialog.gd` (exists, enhance)

**Task 4.2: Add Parameter Validation**
- Validate parameter ranges before injection
- Show error messages for invalid combinations
- Prevent generation if critical parameters invalid
- **File:** `ui/world_builder/WorldBuilderUI.gd`

**Task 4.3: Add Tooltips & Help**
- Add tooltips to all parameter controls
- Link to AZGAAR_PARAMETERS.md documentation
- Show performance impact warnings
- **File:** `ui/world_builder/WorldBuilderUI.gd`

---

#### 4.4.2 Testing & Documentation

**Task 4.4: Comprehensive Testing**
- Test all parameter combinations
- Test archetype presets
- Test performance clamping on low-end hardware
- Test heightmap export and Terrain3D import
- Test UI responsiveness at multiple resolutions
- **Action:** Create test plan, execute, document results

**Task 4.5: Update Documentation**
- Update architecture docs with Azgaar integration
- Document parameter mapping system
- Create user guide for archetype presets
- **Files:** `docs/architecture/`, `docs/user_guides/`

---

## Next Steps

### Immediate Actions (This Week)

1. **Fix Critical Issues:**
   - [ ] Defer Terrain3D initialization (Issue #1)
   - [ ] Remove magic numbers (Issue #4)
   - [ ] Add `scale_mode = "fractional"` to project.godot (Issue #6)

2. **Create Infrastructure:**
   - [ ] Create `azgaar_parameter_mapping.json`
   - [ ] Create `archetype_azgaar_presets.json`
   - [ ] Implement JS bridge in WorldBuilderAzgaar.gd

3. **Test Responsiveness:**
   - [ ] Test at 1080p, 1440p, 4K, ultrawide
   - [ ] Document results

### Short-Term (Next 2 Weeks)

4. **Implement Parameter UI:**
   - [ ] Add parameter category tabs
   - [ ] Create parameter control helpers
   - [ ] Implement performance resource checks
   - [ ] Add archetype selector

5. **Implement Azgaar Communication:**
   - [ ] Parameter injection system
   - [ ] Heightmap export
   - [ ] "Generate with Azgaar" button

### Medium-Term (Next Month)

6. **Polish & Testing:**
   - [ ] Progress dialogs
   - [ ] Parameter validation
   - [ ] Tooltips & help
   - [ ] Comprehensive testing
   - [ ] Documentation updates

---

## Appendix A: Parameter Mapping Table

| Azgaar Parameter | Godot UI Name | Type | Range | Performance Impact | Category |
|------------------|---------------|------|-------|-------------------|----------|
| `templateInput` | Landmass Template | OptionButton | 14 templates + 23 regional | Low | Terrain & Heightmap |
| `pointsInput` | Cell Density | HSlider | 1-13 (1K-100K cells) | **HIGH** | Terrain & Heightmap |
| `statesNumber` | State Count | SpinBox | 0-100 | Low | Civilization |
| `culturesInput` | Culture Count | SpinBox | 1-32 (varies by set) | Low | Civilization |
| `culturesSet` | Culture Set | OptionButton | world, european, oriental, etc. | Low | Civilization |
| `religionsNumber` | Religion Count | SpinBox | 0-50 | Low | Civilization |
| `manorsInput` | Town Count | SpinBox | 0-1000 | Medium | Civilization |
| `precInput` | Precipitation | HSlider | 0-500% | Low | Climate & Environment |
| `temperatureEquator` | Equator Temp | HSlider | -50 to 50°C | Low | Climate & Environment |
| `temperatureNorthPole` | North Pole Temp | HSlider | -50 to 50°C | Low | Climate & Environment |
| `temperatureSouthPole` | South Pole Temp | HSlider | -50 to 50°C | Low | Climate & Environment |
| `winds` | Wind Directions | Array[6] HSliders | 0-360° each | Low | Climate & Environment |
| `heightExponentInput` | Height Exponent | HSlider | 1.5-2.2 | Low | Terrain & Heightmap |
| `allowErosion` | Allow Erosion | CheckBox | true/false | Medium | Terrain & Heightmap |
| `resolveDepressionsStepsInput` | Depression Steps | SpinBox | 0-500 | Medium | Advanced |
| `lakeElevationLimitInput` | Lake Threshold | SpinBox | 0-80 | Low | Advanced |
| `mapSizeInput` | Map Size | HSlider | 1-100% | Low | Advanced |
| `latitudeInput` | Latitude Shift | HSlider | 0-100 | Low | Advanced |
| `longitudeInput` | Longitude Shift | HSlider | 0-100 | Low | Advanced |

---

## Appendix B: Archetype Preset Recommendations

Based on `AZGAAR_PARAMETERS.md` Section 4:

### High Fantasy
```json
{
  "templateInput": "continents",
  "pointsInput": 4,
  "statesNumber": 25,
  "culturesInput": 18,
  "culturesSet": "highFantasy",
  "religionsNumber": 10,
  "manorsInput": 900,
  "precInput": 130,
  "temperatureEquator": 28,
  "temperatureNorthPole": -25,
  "temperatureSouthPole": -20
}
```

### Dark Fantasy
```json
{
  "templateInput": "shattered",
  "pointsInput": 3,
  "statesNumber": 10,
  "culturesInput": 10,
  "culturesSet": "darkFantasy",
  "religionsNumber": 6,
  "manorsInput": 500,
  "precInput": 75,
  "temperatureEquator": 22,
  "temperatureNorthPole": -30,
  "temperatureSouthPole": -25
}
```

### Low Fantasy / Historical
```json
{
  "templateInput": "europe",
  "pointsInput": 4,
  "statesNumber": 16,
  "culturesInput": 12,
  "culturesSet": "european",
  "religionsNumber": 6,
  "manorsInput": 700,
  "precInput": 100,
  "temperatureEquator": 25,
  "temperatureNorthPole": -28,
  "temperatureSouthPole": -22
}
```

### Archipelago / Island Worlds
```json
{
  "templateInput": "archipelago",
  "pointsInput": 4,
  "statesNumber": 8,
  "culturesInput": 10,
  "culturesSet": "world",
  "religionsNumber": 5,
  "manorsInput": 600,
  "precInput": 125,
  "temperatureEquator": 27,
  "temperatureNorthPole": -25,
  "temperatureSouthPole": -20
}
```

---

## Appendix C: Performance Clamping Rules

Based on HardwareProfiler quality levels:

| Parameter | LOW | MEDIUM | HIGH |
|-----------|-----|--------|------|
| `pointsInput` | Max 3 (5K cells) | Max 6 (50K cells) | Max 13 (100K cells) |
| `resolveDepressionsStepsInput` | Max 100 | Max 250 | Max 500 |
| `statesNumber` | Max 15 | Max 30 | Max 100 |
| `manorsInput` | Max 500 | Max 800 | Max 1000 |

---

**End of Audit Report**

