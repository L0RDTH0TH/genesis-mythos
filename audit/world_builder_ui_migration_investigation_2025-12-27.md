# World Builder UI Migration Investigation Report
**Date:** 2025-12-27  
**Purpose:** Document current state, identify mismatches with pre-migration design, and propose polish/fix considerations  
**Status:** Investigation Complete - No Implementation Yet

---

## Executive Summary

The World Builder UI has migrated from a native Godot UI (left/center/right panel layout with native controls) to a **dual-WebView architecture**:
1. **WorldBuilderWeb.tscn** - Loads a custom HTML/JS UI (`web_ui/world_builder/index.html`) via `WorldBuilderWebController.gd`
2. **Separate Azgaar WebView** - Handled by `WorldBuilderAzgaar.gd` (currently **disabled** via `DEBUG_DISABLE_AZGAAR` flag)

**Key Findings:**
- ✅ **Architecture Shift:** Native Godot controls replaced with Alpine.js-based HTML UI
- ⚠️ **Parameter Exposure:** Only ~20 curated parameters across 8 steps (much smaller than planned 40-60)
- ⚠️ **Missing Features:** Steps 3 (Biomes), 6 (Resources & Magic), and 7 (Export) have 0 parameters
- ⚠️ **Azgaar Integration:** Currently disabled (diagnostic flag), breaks generation flow
- ✅ **Responsive Design:** CSS uses theme colors and UIConstants-derived values
- ⚠️ **Theme Consistency:** JS UI matches theme colors but feels "webby" (could be more immersive)

---

## 1. Current Implementation State

### 1.1 Scene Hierarchy

**File:** `res://ui/world_builder/WorldBuilderWeb.tscn`

```
WorldBuilderWebRoot (Control)
├── layout_mode = 3 (PRESET_FULL_RECT)
├── anchors_preset = 15 (FULL_RECT)
├── theme = res://themes/bg3_theme.tres
└── WebView (godot_wry WebView)
    ├── layout_mode = 1 (FULL_RECT)
    ├── anchors_preset = 15 (FULL_RECT)
    └── Loads: res://web_ui/world_builder/index.html
```

**Node Count:** 2 nodes (root Control + WebView)  
**Attached Script:** `WorldBuilderWebController.gd`

**Comparison to Pre-Migration Design:**
- ❌ **Pre-Migration:** Native HSplitContainer with Left/Center/Right panels
- ✅ **Current:** Single WebView displaying HTML UI (left/center/right layout handled by CSS flexbox)

---

### 1.2 Key Scripts & Their Roles

#### 1.2.1 `WorldBuilderWebController.gd`

**Location:** `res://scripts/ui/WorldBuilderWebController.gd`  
**Purpose:** Main controller for the HTML-based World Builder UI

**Key Responsibilities:**
- Loads `res://web_ui/world_builder/index.html` into WebView
- Loads step definitions from `res://data/config/azgaar_step_parameters.json`
- Sends step definitions and archetype names to WebView via JS injection
- Handles IPC messages from WebView (step changes, parameter updates, generation requests)
- Clamps parameter values based on `clamped_min`/`clamped_max` in JSON
- Forwards generation requests to `WorldBuilderAzgaar` (if found in scene tree)

**Parameter Flow:**
```
JSON (azgaar_step_parameters.json)
  ↓
WorldBuilderWebController._load_step_definitions()
  ↓
_send_step_definitions() → JS injection → Alpine.js worldBuilder instance
  ↓
User edits params in HTML UI
  ↓
updateParam() → GodotBridge.postMessage('update_param')
  ↓
WorldBuilderWebController._handle_update_param() → _clamp_parameter_value()
  ↓
current_params Dictionary (stored in GDScript)
  ↓
Generate button → _handle_generate() → WorldBuilderAzgaar.trigger_generation_with_options()
```

**Communication Methods:**
- `web_view.execute_js(code)` or `web_view.eval(code)` - Send JS code to WebView
- `web_view.ipc_message` signal - Receive messages from WebView (JSON strings)
- `web_view.load_url(url)` - Load HTML file

---

#### 1.2.2 `WorldBuilderAzgaar.gd`

**Location:** `res://scripts/ui/WorldBuilderAzgaar.gd`  
**Purpose:** Controls Azgaar WebView embedding and parameter syncing

**Key Responsibilities:**
- Initializes separate Azgaar WebView (embedded Azgaar Fantasy Map Generator)
- Loads Azgaar from `user://azgaar/` via HTTP server (`AzgaarServer`) or `file://` URL
- Injects bridge script for bidirectional communication
- Syncs parameters to Azgaar via JS injection (`azgaar.options.paramName = value`)
- Triggers generation (`azgaar.generate()`)
- Exports heightmap data

**⚠️ Critical Issue:** Currently **DISABLED** via `DEBUG_DISABLE_AZGAAR := true` (line 10)
- WebView node is removed from scene tree on initialization
- Generation requests will fail silently (logged as "DIAGNOSTIC: Generation skipped")
- This breaks the entire generation flow

**Expected Integration:** Should be instantiated in a separate scene/node (not in `WorldBuilderWeb.tscn`). The HTML UI shows a placeholder "Map Preview" in the center panel, indicating Azgaar WebView should be embedded separately.

---

#### 1.2.3 `AzgaarIntegrator.gd`

**Location:** `res://scripts/managers/AzgaarIntegrator.gd`  
**Purpose:** Manages Azgaar bundle copying and URL generation

**Key Responsibilities:**
- Copies Azgaar bundle from `res://tools/azgaar/` to `user://azgaar/` on startup
- Provides `get_azgaar_url()` (file://) and `get_azgaar_http_url()` (http:// via `AzgaarServer`)
- Handles file writability (Azgaar may write `options.json` to user directory)

**Status:** Functional, but `AzgaarServer` is also disabled when `DEBUG_DISABLE_AZGAAR` is true.

---

#### 1.2.4 `AzgaarServer.gd`

**Location:** `res://scripts/managers/AzgaarServer.gd`  
**Purpose:** Embedded HTTP server to serve Azgaar files

**Key Responsibilities:**
- Serves files from `user://azgaar/` on `http://127.0.0.1:8080` (or next available port)
- Handles MIME types (HTML, JS, CSS, images, fonts)
- Prevents directory traversal attacks
- Defaults to `index.html` for root requests

**Status:** Disabled when `DEBUG_DISABLE_AZGAAR := true` (line 15).

---

### 1.3 HTML/JS UI Implementation

#### 1.3.1 Structure (`web_ui/world_builder/index.html`)

**Layout:** Matches pre-migration design structurally (left/center/right panels)

```
Top Bar (title)
├── Main HSplit (flexbox row)
│   ├── Left Panel (numbered tabs, ~280px)
│   ├── Center Panel (Azgaar placeholder, flex: 1)
│   └── Right Panel (parameters, ~280px)
└── Bottom Bar (navigation buttons, progress)
```

**Technologies:**
- **Alpine.js** - Reactive data binding (`x-data="worldBuilder"`)
- **GodotBridge** (`web_ui/shared/bridge.js`) - IPC communication with Godot
- **CSS** (`world_builder.css`) - Theme-matched styling

**CSS Theme Integration:**
- ✅ Uses CSS variables derived from `bg3_theme.tres` colors:
  - `--bg-dark: #101010`
  - `--font-color-gold: #FFD700`
  - `--bg-panel: #1A1F26`
- ✅ Uses UIConstants-derived sizes:
  - `--button-height-small: 50px` (matches `UIConstants.BUTTON_HEIGHT_SMALL`)
  - `--spacing-medium: 20px` (matches `UIConstants.SPACING_MEDIUM`)
- ⚠️ **Hard-coded panel widths:** `--left-tabs-width: 280px`, `--right-panel-width: 280px` (not using `UIConstants.LEFT_PANEL_WIDTH` / `RIGHT_PANEL_WIDTH`)

---

#### 1.3.2 Parameter Rendering (`world_builder.js`)

**Alpine.js Component:** `worldBuilder`

**Data Flow:**
1. `init()` requests step definitions from Godot via `GodotBridge.requestData('step_definitions')`
2. `_initializeParams()` sets default values from JSON (only curated parameters)
3. `currentStepParams` computed property filters to curated params for current step
4. `updateParam(key, value)` clamps value (client-side) and sends to Godot
5. `generate()` sends all params to Godot for generation

**UI Controls Rendered:**
- `OptionButton` → `<select>` dropdown
- `HSlider` → `<input type="range">` + value display
- `SpinBox` → `<input type="number">`
- `CheckBox` → `<input type="checkbox">`

**Responsiveness:**
- ✅ Uses flexbox for layout
- ✅ Scrollable parameter list in right panel
- ⚠️ Fixed panel widths (280px) may not adapt well to small screens

---

### 1.4 Parameter Definitions (`azgaar_step_parameters.json`)

**Location:** `res://data/config/azgaar_step_parameters.json`  
**Total Parameters:** 20 curated parameters across 8 steps

**Distribution by Step:**

| Step | Title | Parameter Count | Parameters |
|------|-------|----------------|------------|
| 0 | Map Generation & Editing | 6 | templateInput, pointsInput, optionsSeed, mapWidthInput, mapHeightInput, mapSizeInput |
| 1 | Terrain | 4 | heightExponentInput, allowErosion, resolveDepressionsStepsInput, lakeElevationLimitInput |
| 2 | Climate | 4 | precInput, temperatureEquator, temperatureNorthPole, temperatureSouthPole |
| 3 | Biomes | 0 | *(empty - auto-generated from climate)* |
| 4 | Structures & Civilizations | 6 | statesNumber, culturesInput, culturesSet, religionsNumber, manorsInput, provincesRatio |
| 5 | Environment | 3 | populationRateInput, urbanizationInput, urbanDensityInput |
| 6 | Resources & Magic | 0 | *(empty - future expansion)* |
| 7 | Export | 0 | *(empty - export handled by Bake button)* |

**Parameter Metadata:**
Each parameter includes:
- `name` - Display name
- `azgaar_key` - Key to set in Azgaar (`azgaar.options.key` or direct input)
- `ui_type` - Control type (OptionButton, HSlider, SpinBox, CheckBox)
- `default` - Default value
- `min` / `max` - Range for numeric controls
- `step` - Step increment (for sliders/spinboxes)
- `clamped_min` / `clamped_max` - Clamped range (if different from min/max)
- `description` - Tooltip text
- `curated` - Boolean flag (always `true` in current JSON)

**Comparison to Full Azgaar Parameters:**
- **Full Parameter Count:** ~100+ parameters (see `tools/azgaar/AZGAAR_PARAMETERS.md`)
- **Curated Count:** 20 parameters (~20% of total)
- **Missing Categories:**
  - Wind directions (`winds` array - 6 values)
  - State/culture size variety (`sizeVariety`, `growthRate`)
  - Map positioning (`latitudeInput`, `longitudeInput`)
  - Distance/area units (`distanceUnitInput`, `distanceScaleInput`)
  - Emblem shapes (`emblemShape`)
  - Advanced terrain tweaks (erosion iteration counts, depression resolution variants)

---

### 1.5 WebView Integration & Communication

#### 1.5.1 Godot → WebView Communication

**Methods Used:**
1. **JS Injection via `execute_js()` / `eval()`:**
   ```gdscript
   var script: String = """
       if (window.worldBuilderInstance) {
           window.worldBuilderInstance.steps = %s;
           window.worldBuilderInstance._initializeParams();
       }
   """ % JSON.stringify(step_definitions)
   web_view.execute_js(script)
   ```

2. **IPC Messages via `post_message()`:**
   - Not currently used in WorldBuilderWebController
   - Used in WorldBuilderAzgaar for bridge communication

**Data Sent:**
- Step definitions (JSON array of step objects)
- Archetype names (array of strings)
- Parameter updates (when archetype loaded or values synced)
- Progress updates (progress bar value, status text)

---

#### 1.5.2 WebView → Godot Communication

**Method:** IPC message signal (`web_view.ipc_message`)

**Message Format:** JSON string
```json
{
  "type": "message_type",
  "data": { ... },
  "timestamp": 1234567890
}
```

**Message Types Handled:**
- `set_step` - User changed step (updates `current_step`)
- `load_archetype` - User selected archetype preset
- `set_seed` - User changed seed value
- `update_param` - User changed parameter value
- `generate` - User clicked Generate button
- `request_data` - WebView requests step definitions or archetypes

**Bridge Implementation:** `web_ui/shared/bridge.js` (GodotBridge global object)

---

### 1.6 Responsive Design & Anchors

**Scene File (`WorldBuilderWeb.tscn`):**
- ✅ Root Control: `anchors_preset = 15` (FULL_RECT)
- ✅ WebView: `anchors_preset = 15` (FULL_RECT)
- ✅ Theme applied: `res://themes/bg3_theme.tres`

**HTML/CSS:**
- ✅ Uses flexbox for responsive layout
- ✅ CSS variables for theme colors and sizes
- ⚠️ Fixed panel widths (280px) - not fully responsive
- ✅ Scrollable parameter list handles overflow
- ✅ Bottom bar adapts to content width

**Compliance with UIConstants:**
- ✅ CSS uses UIConstants-derived values (button heights, spacing)
- ⚠️ Panel widths hard-coded in CSS (should use `UIConstants.LEFT_PANEL_WIDTH` / `RIGHT_PANEL_WIDTH`)
- ✅ No magic numbers in GDScript (all sizes via constants or theme)

---

## 2. Mismatches with Pre-Migration Design

### 2.1 Architecture Mismatch

**Pre-Migration Intent:**
- Native Godot controls (sliders, checkboxes, dropdowns) in right panel
- All UI elements styled via `bg3_theme.tres`
- Full Godot-native responsiveness (anchors, size flags)

**Current Implementation:**
- ❌ **HTML/JS UI** replaces native controls
- ✅ Theme colors matched in CSS
- ⚠️ Responsiveness handled by CSS flexbox (works but feels "webby")

**Rationale (Inferred):**
- **Simpler iteration:** Easier to add parameters by editing JSON + HTML template
- **Consistent UI across steps:** Alpine.js reactive binding handles dynamic parameter lists
- **Future extensibility:** Can add complex UI (tabs, accordions) without deep Godot scene tree changes

**Trade-offs:**
- ✅ Easier to maintain parameter definitions (JSON-only changes)
- ❌ Less immersive (feels like a web app, not a game UI)
- ❌ Theme consistency relies on manual CSS variable sync
- ⚠️ Performance: WebView overhead (likely minimal but measurable)

---

### 2.2 Parameter Exposure Mismatch

**Pre-Migration Intent:**
- Curated subset of ~40-60 parameters (from full ~100+ Azgaar parameters)
- Each step should expose relevant parameters (even if 0 for auto-generated steps)
- Parameters should align with step theme (e.g., "Terrain" should include erosion settings)

**Current Implementation:**
- ⚠️ **Only 20 parameters** exposed (~33-50% of planned range)
- ❌ **Steps 3, 6, 7 have 0 parameters** (empty panels - feels incomplete)
- ⚠️ **Missing key parameters** (see table below)

**Missing Parameters by Category:**

| Category | Missing Parameters | Priority | Notes |
|----------|-------------------|----------|-------|
| **Terrain** | `winds` (array[6]) | HIGH | Affects precipitation patterns |
| **Terrain** | Erosion iteration tweaks | MEDIUM | Fine-tune erosion behavior |
| **Climate** | *(all covered)* | - | Temperature/precipitation complete |
| **Biomes** | *(auto-generated)* | LOW | Intentionally empty (derived from climate) |
| **Structures** | `sizeVariety` | MEDIUM | State/culture expansionism |
| **Structures** | `growthRate` | MEDIUM | Neutral lands amount |
| **Structures** | `stateLabelsMode` | LOW | Display preference only |
| **Environment** | `distanceUnitInput` | LOW | Map scale units |
| **Environment** | `distanceScaleInput` | LOW | Scale multiplier |
| **Export** | Heightmap export options | MEDIUM | Resolution, format (future: Bake to 3D) |

**Recommendation:** Expand to ~40-50 parameters total:
- Add `winds` to Terrain step (6 sliders for wind directions)
- Add `sizeVariety`, `growthRate` to Structures step
- Add heightmap export options to Export step (even if placeholder for now)
- Keep Biomes empty (documented as auto-generated)

---

### 2.3 User Experience Mismatch

**Pre-Migration Intent:**
- Fantasy-themed, diegetic UI (parchment textures, ornate frames)
- Seamless integration with game aesthetic
- Intuitive navigation (wizard flow, clear step progression)

**Current Implementation:**
- ✅ Fantasy colors (gold accents, dark panels)
- ⚠️ **Feels "webby"** (clean HTML forms, no textures)
- ✅ Wizard flow maintained (8 steps, navigation buttons)
- ⚠️ **Empty steps** (Biomes, Resources, Export) show blank panels (confusing UX)

**Specific Issues:**
1. **Empty Steps:** Steps 3, 6, 7 show "Step Title" but no parameters - users may think UI is broken
2. **Placeholder Center Panel:** Shows "Map Preview (Azgaar WebView handled separately)" - not clear where Azgaar actually renders
3. **No Visual Feedback on Empty Steps:** Could add info text like "Biomes are automatically generated from climate and terrain settings."

---

### 2.4 Azgaar Integration Mismatch

**Pre-Migration Intent:**
- Azgaar embedded in center panel (full interactive map)
- User can switch layers inside Azgaar (heightmap, biomes, temperature, etc.)
- Generation triggers update Azgaar map in real-time

**Current Implementation:**
- ❌ **Azgaar WebView disabled** (`DEBUG_DISABLE_AZGAAR := true`)
- ❌ **Separate architecture:** HTML UI in one WebView, Azgaar should be in another (not implemented)
- ⚠️ **Generation flow broken:** Generate button triggers `WorldBuilderAzgaar.trigger_generation_with_options()`, but Azgaar WebView doesn't exist

**Architecture Question:**
- **Option A:** Embed Azgaar WebView in center panel of HTML UI (iframe?)
- **Option B:** Separate node/scene for Azgaar WebView, positioned behind HTML UI with transparent center
- **Option C:** Remove Azgaar embedding, use HTML UI only for parameters, bake to 3D after generation

**Recommendation:** Implement Option B or C (document decision in polish plan).

---

### 2.5 Theme Consistency Mismatch

**Pre-Migration Intent:**
- All styling via `bg3_theme.tres`
- UI feels like game UI, not web app
- Parchment textures, ornate borders where appropriate

**Current Implementation:**
- ✅ CSS uses theme color values (manually synced)
- ❌ **No texture support** (CSS backgrounds are solid colors)
- ❌ **No font consistency** (HTML uses `'Times New Roman', serif` - not theme font)
- ⚠️ **Theme changes require CSS updates** (not automatic sync)

**Recommendation:**
- Export theme colors to CSS on load (via JS injection)
- Use theme font in CSS (if available)
- Consider adding subtle background textures (CSS `background-image` or pseudo-elements)

---

### 2.6 Future Extensibility Mismatch

**Pre-Migration Intent:**
- Easy to add parameters by editing JSON
- UI adapts automatically (native Godot controls are data-driven)

**Current Implementation:**
- ✅ **Easy JSON editing** (matches intent)
- ✅ **UI adapts via Alpine.js** (reactive templates)
- ⚠️ **CSS needs updates** for new UI types (e.g., if adding `TextEdit` control type)
- ⚠️ **JS needs updates** for new message types (if adding new IPC commands)

**Assessment:** Extensibility is good but not perfect (requires 3-file edits: JSON + CSS + JS for new control types).

---

## 3. Breakage Points & Issues

### 3.1 Critical Breakage

#### 3.1.1 Azgaar WebView Disabled

**Location:** `WorldBuilderAzgaar.gd:10`, `AzgaarServer.gd:15`

**Issue:** `DEBUG_DISABLE_AZGAAR := true` disables entire Azgaar integration

**Impact:**
- ❌ Generation requests fail silently (logged but no action)
- ❌ Heightmap export returns `null`
- ❌ No map preview visible
- ❌ "Bake to 3D" button likely broken (depends on heightmap export)

**Fix:** Set `DEBUG_DISABLE_AZGAAR := false` and ensure Azgaar WebView is instantiated in scene tree.

---

#### 3.1.2 Missing Azgaar WebView in Scene

**Issue:** `WorldBuilderWeb.tscn` contains only the HTML UI WebView, not the Azgaar WebView

**Impact:**
- Even if `DEBUG_DISABLE_AZGAAR` is false, Azgaar WebView must be instantiated elsewhere (not found)

**Investigation Needed:**
- Check if `WorldBuilderAzgaar` expects to be in a parent scene (e.g., `world_root.tscn`)
- Verify scene tree structure when World Builder is opened

---

### 3.2 Parameter Validation Issues

#### 3.2.1 Clamping Inconsistency

**Issue:** Clamping happens in both JS (client-side) and GDScript (server-side)

**Location:**
- `world_builder.js:196-206` - Client-side clamping
- `WorldBuilderWebController.gd:275-300` - Server-side clamping

**Impact:**
- ⚠️ Minor performance overhead (double clamping)
- ✅ Safety (ensures values are always clamped even if JS is bypassed)

**Assessment:** Not a breakage, but could be optimized (clamp only server-side).

---

#### 3.2.2 Missing Parameter Validation

**Issue:** Some parameters lack `clamped_min`/`clamped_max`, falling back to `min`/`max`

**Impact:**
- ⚠️ Performance: `pointsInput` slider value 13 maps to ~100K cells (may crash on low-end hardware)
- ✅ `UIConstants.get_clamped_points()` exists but not used for `pointsInput` clamping

**Recommendation:** Use `UIConstants.get_clamped_points()` in `_clamp_parameter_value()` for `pointsInput`.

---

### 3.3 UI/UX Issues

#### 3.3.1 Empty Step Panels

**Steps Affected:** 3 (Biomes), 6 (Resources & Magic), 7 (Export)

**User Experience:**
- Shows step title but no parameters
- Users may think UI is broken or step is incomplete
- No explanation text

**Recommendation:** Add info text for empty steps (e.g., "Biomes are automatically generated from climate and terrain settings. No manual configuration needed.").

---

#### 3.3.2 Azgaar Preview Placeholder

**Issue:** Center panel shows placeholder text instead of actual Azgaar map

**Impact:**
- Users cannot see map while adjusting parameters
- No visual feedback on generation

**Fix:** Embed Azgaar WebView in center panel (see architecture options above).

---

#### 3.3.3 Fixed Panel Widths

**Issue:** Left and right panels are 280px fixed width (not responsive)

**Impact:**
- ⚠️ May clip on small screens (< 1200px width)
- ⚠️ Wastes space on ultrawide monitors

**Recommendation:** Use `UIConstants.LEFT_PANEL_WIDTH` / `RIGHT_PANEL_WIDTH` and make CSS responsive (min/max widths, flex-based sizing).

---

## 4. Polish Considerations & Recommendations

### 4.1 Parameter Expansion Plan

**Goal:** Expand from 20 to ~40-50 curated parameters

**Priority Order:**

#### Phase 1: High-Impact Missing Parameters (10-15 new params)
1. **Terrain Step:**
   - Add `winds` array (6 sliders for wind directions per latitude tier)
   - Add erosion iteration count tweaks (2-3 params)
2. **Structures Step:**
   - Add `sizeVariety` (state/culture expansionism)
   - Add `growthRate` (neutral lands amount)
3. **Export Step:**
   - Add heightmap export resolution dropdown (placeholder for Bake to 3D)

#### Phase 2: Medium-Impact Parameters (5-10 new params)
4. **Environment Step:**
   - Add `distanceUnitInput` (map scale units)
   - Add `distanceScaleInput` (scale multiplier)
5. **Map Generation Step:**
   - Add `latitudeInput` (North-South map shift)
   - Add `longitudeInput` (West-East map shift)

#### Phase 3: Low-Impact / Display-Only (5-10 new params)
6. **Structures Step:**
   - Add `stateLabelsMode` (auto/short/full - display only)
7. **Export Step:**
   - Add emblem shape selector (visual only)

**Implementation:**
- Add parameters to `azgaar_step_parameters.json`
- HTML UI will automatically render them (Alpine.js reactive templates)
- Test parameter syncing to Azgaar (ensure JS injection works)

---

### 4.2 Architecture Decision: Azgaar Embedding

**Options:**

#### Option A: Embed Azgaar in HTML UI (iframe)

**Pros:**
- Single WebView (simpler architecture)
- Azgaar rendered in center panel of HTML UI
- Can style Azgaar container via CSS

**Cons:**
- iframe may have security restrictions
- Azgaar's own UI may conflict with outer HTML UI styling
- Harder to communicate between Godot ↔ Azgaar (must route through HTML UI)

**Implementation:**
```html
<!-- In index.html center-panel -->
<iframe id="azgaar-frame" src="http://127.0.0.1:8080/index.html" style="width: 100%; height: 100%; border: none;"></iframe>
```

---

#### Option B: Separate Azgaar WebView Node (Recommended)

**Pros:**
- Direct Godot ↔ Azgaar communication (no HTML UI routing)
- Azgaar UI remains untouched (no styling conflicts)
- Can position Azgaar behind HTML UI with transparent center panel

**Cons:**
- Two WebViews (higher memory usage)
- More complex scene tree

**Implementation:**
- Create separate scene: `WorldBuilderAzgaarView.tscn` with WebView node
- Instantiate in `world_root.tscn` or parent scene
- Position behind `WorldBuilderWeb` with transparent center panel in HTML CSS

---

#### Option C: Remove Azgaar Embedding (Parameter-Only UI)

**Pros:**
- Simplest architecture (no Azgaar WebView)
- Faster initialization
- Users configure parameters, then "Bake to 3D" generates Terrain3D directly

**Cons:**
- No live map preview (users can't see changes before bake)
- Less immersive (loses interactive map exploration)

**Recommendation:** **Option B** (separate WebView) for best UX while maintaining direct Godot ↔ Azgaar communication.

---

### 4.3 Theme Consistency Improvements

#### 4.3.1 Automatic Theme Color Sync

**Current:** CSS variables manually synced with theme colors

**Improvement:** Inject theme colors from Godot on HTML load

**Implementation:**
```gdscript
# In WorldBuilderWebController._ready()
var theme_colors: Dictionary = {
    "bg_dark": "#101010",  # Get from theme
    "font_gold": "#FFD700",  # Get from theme
    # ... etc
}
var script: String = """
    :root {
        --bg-dark: %s;
        --font-color-gold: %s;
        /* ... */
    }
""" % [theme_colors.bg_dark, theme_colors.font_gold]
web_view.execute_js("document.documentElement.style.setProperty('--bg-dark', '%s')" % theme_colors.bg_dark)
```

---

#### 4.3.2 Font Consistency

**Current:** HTML uses `'Times New Roman', serif` (hard-coded)

**Improvement:** Use theme font family (if available) or match Godot default font

**Implementation:**
- Extract font family from `bg3_theme.tres` (e.g., `theme.default_font.font_name`)
- Inject into CSS: `document.body.style.fontFamily = '...'`

---

#### 4.3.3 Texture/Background Enhancements

**Current:** Solid color backgrounds

**Improvement:** Add subtle parchment texture or gradient overlays

**Implementation:**
- Add CSS `background-image` for parchment texture (if available in `res://assets/ui/`)
- Or use CSS gradients for depth (e.g., `linear-gradient(180deg, rgba(26,31,38,0.9) 0%, rgba(16,16,16,1) 100%)`)

---

### 4.4 Empty Step Handling

**Recommendation:** Add info panels for steps with 0 parameters

**Implementation:**
```html
<!-- In index.html, inside param-scroll -->
<div x-show="currentStepParams.length === 0" class="empty-step-info">
    <p class="info-text">This step has no configurable parameters.</p>
    <p class="info-subtext" x-text="steps[currentStep]?.description || 'Settings are automatically generated.'"></p>
</div>
```

**CSS:**
```css
.empty-step-info {
    padding: var(--spacing-large);
    text-align: center;
    color: var(--font-color-gold);
    opacity: 0.7;
}
```

---

### 4.5 Responsive Layout Improvements

**Current:** Fixed 280px panel widths

**Improvement:** Use UIConstants and responsive min/max widths

**Implementation:**
1. Inject UIConstants values from Godot:
   ```gdscript
   var panel_widths: Dictionary = {
       "left": UIConstants.LEFT_PANEL_WIDTH,
       "right": UIConstants.RIGHT_PANEL_WIDTH,
       "left_min": UIConstants.LEFT_PANEL_WIDTH_MIN,
       "right_min": UIConstants.RIGHT_PANEL_WIDTH_MIN,
   }
   ```
2. Update CSS to use injected values and add min/max:
   ```css
   .left-tabs-panel {
       width: var(--left-panel-width);
       min-width: var(--left-panel-width-min);
       max-width: var(--left-panel-width-max);
   }
   ```

---

### 4.6 Performance Optimizations

#### 4.6.1 Parameter Update Debouncing

**Current:** Every slider change sends IPC message immediately

**Improvement:** Debounce parameter updates (send after user stops dragging for 100ms)

**Implementation:**
```javascript
// In world_builder.js
let updateTimeout = null;
updateParam(key, value) {
    this.params[key] = value;
    clearTimeout(updateTimeout);
    updateTimeout = setTimeout(() => {
        GodotBridge.postMessage('update_param', { azgaar_key: key, value: this.params[key] });
    }, 100);
}
```

---

#### 4.6.2 Lazy Step Definition Loading

**Current:** All step definitions loaded at once

**Improvement:** Load step definitions per step (reduce initial payload)

**Assessment:** Likely not needed (JSON is small, ~5KB). Current approach is fine.

---

### 4.7 Compliance Checklist

**UIConstants Usage:**
- ✅ GDScript uses UIConstants (button heights, spacing)
- ⚠️ CSS hard-codes some values (panel widths) - **needs update**
- ✅ No magic numbers in GDScript

**Theme Usage:**
- ✅ Theme applied to root Control
- ✅ CSS matches theme colors (manual sync)
- ⚠️ Font not synced - **needs update**
- ⚠️ No texture support - **future enhancement**

**Responsive Design:**
- ✅ Root uses full rect anchors
- ✅ HTML uses flexbox
- ⚠️ Fixed panel widths - **needs responsive min/max**

**Accessibility:**
- ✅ Keyboard navigation (tab through controls)
- ✅ Focus indicators (CSS `:focus` styles)
- ⚠️ Screen reader support (HTML needs ARIA labels) - **future enhancement**

---

## 5. Implementation Priority

### Phase 1: Critical Fixes (Do First)
1. **Enable Azgaar WebView** (`DEBUG_DISABLE_AZGAAR := false`)
2. **Fix Azgaar WebView instantiation** (ensure it's in scene tree)
3. **Test generation flow** (verify parameters sync to Azgaar and generation triggers)
4. **Add empty step info text** (improve UX for steps 3, 6, 7)

### Phase 2: Parameter Expansion (High Priority)
5. **Add winds array to Terrain step** (6 sliders)
6. **Add sizeVariety/growthRate to Structures step**
7. **Add heightmap export options to Export step**
8. **Test parameter clamping** (ensure `pointsInput` uses `UIConstants.get_clamped_points()`)

### Phase 3: Architecture & Theme (Medium Priority)
9. **Implement Azgaar embedding** (Option B: separate WebView node)
10. **Sync theme colors automatically** (inject from Godot)
11. **Sync theme font** (inject from Godot)
12. **Make panel widths responsive** (use UIConstants, add min/max)

### Phase 4: Polish & Enhancements (Low Priority)
13. **Add texture backgrounds** (parchment-style CSS)
14. **Debounce parameter updates** (performance optimization)
15. **Add more parameters** (Phase 2/3 from expansion plan)
16. **Accessibility improvements** (ARIA labels, screen reader support)

---

## 6. Testing Recommendations

### 6.1 Functional Testing
- [ ] Enable Azgaar WebView and verify map loads
- [ ] Test parameter syncing (change value in HTML UI, verify Azgaar receives it)
- [ ] Test generation trigger (click Generate, verify Azgaar generates map)
- [ ] Test heightmap export (verify `export_heightmap()` returns valid Image)
- [ ] Test Bake to 3D flow (if implemented)

### 6.2 Parameter Validation Testing
- [ ] Test clamping (set value beyond max, verify it's clamped)
- [ ] Test `pointsInput` hardware clamping (low-end vs high-end hardware)
- [ ] Test empty steps (verify info text displays)
- [ ] Test archetype loading (verify preset values apply correctly)

### 6.3 Responsive Testing
- [ ] Test at 1080p, 1440p, 4K, ultrawide resolutions
- [ ] Test window resize (verify layout adapts)
- [ ] Test small window (< 1200px width) - verify no clipping

### 6.4 Performance Testing
- [ ] Measure WebView initialization time
- [ ] Measure parameter update latency (slider drag → Azgaar sync)
- [ ] Test with all 40-50 parameters (after expansion) - verify no slowdown

---

## 7. Conclusions

**Current State Summary:**
- ✅ Architecture is functional but incomplete (Azgaar disabled)
- ✅ Parameter system is extensible (JSON-driven, reactive UI)
- ⚠️ Parameter exposure is limited (20 vs planned 40-60)
- ⚠️ UX issues (empty steps, placeholder preview, "webby" feel)
- ⚠️ Theme consistency relies on manual sync

**Key Decisions Needed:**
1. **Azgaar Embedding:** Choose Option A (iframe), B (separate WebView), or C (no embedding)
2. **Parameter Expansion:** Prioritize which parameters to add first
3. **Theme Sync:** Implement automatic color/font injection or keep manual sync

**Recommended Next Steps:**
1. Fix critical breakage (enable Azgaar, test generation)
2. Expand parameters (Phase 1: winds, sizeVariety, growthRate)
3. Implement Azgaar embedding (Option B recommended)
4. Improve theme consistency (automatic sync)

**Overall Assessment:** The migration to HTML/JS UI is **structurally sound** but **incomplete**. The extensible architecture is good, but critical features (Azgaar integration) are disabled, and UX polish is needed (empty steps, theme sync). With the fixes and expansions outlined above, the World Builder UI will meet the pre-migration design goals while maintaining the benefits of the new architecture (easier parameter management, reactive UI).

---

**End of Report**

