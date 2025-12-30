# World Builder UI Audit Report – Auto-Generation and Archetype Behavior

**Date:** 2025-12-29  
**Focus:** Auto-map generation on load and archetype change trigger behavior

---

## 1. Current Implementation Summary

### Overview of Relevant Code/Files

**Godot Side (GDScript):**
- `res://scripts/ui/WorldBuilderWebController.gd` - Main controller (1,616 lines)
  - Handles IPC communication with WebView
  - Manages map generation via fork (preferred) or iframe (fallback)
  - Contains archetype presets in `ARCHETYPES` constant (lines 45-51)
  - Handles `alpine_ready`, `load_archetype`, `generate` IPC messages

**Web Side (HTML/JS/Alpine.js):**
- `res://assets/ui_web/templates/world_builder_v2.html` - Fork-based UI template (334 lines)
  - Alpine.js component: `x-data="worldBuilder"`
  - Azgaar Genesis fork integration via ES modules
  - Canvas for 2D preview rendering
- `res://assets/ui_web/js/world_builder.js` - Alpine.js state management (920 lines)
  - `worldBuilder` Alpine component with reactive state
  - `loadArchetype()` function (line 822) - sends IPC but doesn't trigger generation
  - `generate()` function (line 868) - manual generation trigger

**Data Files:**
- `res://data/fantasy_archetypes.json` - Fantasy archetype definitions (447 lines)
  - Contains detailed archetype configs (High Fantasy, Grimdark, etc.)
  - Includes noise, terrain, climate, biome settings
- `res://data/config/archetype_azgaar_presets.json` - Azgaar parameter mappings (64 lines)
  - Maps archetypes to Azgaar-specific parameters (templateInput, pointsInput, etc.)
- `res://data/config/azgaar_step_parameters.json` - Step definitions with defaults
  - Defines 8 wizard steps with curated parameters and default values

### Key Data Flows

**Initialization Flow:**
1. `WorldBuilderWebController._ready()` loads HTML template
2. HTML loads Alpine.js and Azgaar Genesis fork
3. Alpine.js `init()` sends `alpine_ready` IPC to Godot
4. Godot `_handle_alpine_ready()` sends step definitions and archetype names
5. **MISSING:** No automatic map generation triggered

**Archetype Change Flow:**
1. User selects archetype from dropdown (`@change="loadArchetype($event.target.value)"`)
2. `loadArchetype()` sends `load_archetype` IPC to Godot
3. Godot `_handle_load_archetype()` loads preset from `ARCHETYPES` constant
4. Godot maps preset to Azgaar parameters and sends `params_update` to WebView
5. **MISSING:** No automatic regeneration triggered after params update

**Manual Generation Flow:**
1. User clicks "Generate Map" button
2. `generate()` sends `generate` IPC with current params
3. Godot `_handle_generate()` checks fork availability
4. If fork available: `_generate_via_fork()` executes JS in WebView
5. If fork unavailable: `_generate_via_iframe()` uses iframe injection
6. Map generated, preview rendered, `map_generated` IPC sent back

---

## 2. Issue 1: Auto-Map Generation on Load

### Observed Behavior

**Current State:**
- When World Builder loads, the central preview area shows placeholder text:
  - "Azgaar Genesis Fork - Ready"
  - "Using modular API - Generate a map to see preview"
- No map is automatically generated
- User must manually click "Generate Map" button
- Default parameters exist in `azgaar_step_parameters.json` but are not applied automatically

**Code Evidence:**
- `_handle_alpine_ready()` (lines 361-368) only sends step definitions and archetypes
- `_generate_initial_default_map()` (lines 907-986) exists but is **only called for iframe mode** (line 444)
- Fork mode has no equivalent auto-generation trigger
- Default archetype is "High Fantasy" (line 35, 73) but its preset is never applied on load

### Root Causes

1. **No Auto-Trigger After Alpine Ready:**
   - `_handle_alpine_ready()` completes initialization but doesn't trigger generation
   - Fork mode initialization happens in HTML/JS, but no signal is sent to trigger auto-gen

2. **Fork Mode Missing Auto-Generation:**
   - `_generate_initial_default_map()` is iframe-specific
   - Fork mode (`world_builder_v2.html`) has no equivalent auto-generation logic
   - Fork readiness is signaled via `fork_ready` IPC, but `_handle_fork_ready()` (lines 1483-1486) only logs

3. **Default Parameters Not Applied:**
   - Step definitions contain defaults, but they're not merged into `current_params` on load
   - Archetype preset ("High Fantasy") is never loaded automatically

4. **Missing Initialization Sequence:**
   - No clear sequence: `alpine_ready` → load defaults → apply archetype → generate map

### Missing Elements

1. **Auto-Generation Trigger:**
   - Function to trigger generation after Alpine.js and fork are ready
   - Should use default parameters from step definitions or "High Fantasy" archetype preset

2. **Default Parameter Application:**
   - Logic to merge step definition defaults into `current_params` on initialization
   - Logic to apply default archetype preset ("High Fantasy") on load

3. **Fork Auto-Generation:**
   - Equivalent of `_generate_initial_default_map()` for fork mode
   - Should be triggered after `fork_ready` IPC or after Alpine ready + fork check

---

## 3. Issue 2: Archetype Change Trigger

### Observed Behavior

**Current State:**
- When user changes archetype dropdown, `loadArchetype()` is called
- Parameters are updated in Godot and sent to WebView
- **Map preview does NOT regenerate automatically**
- User must manually click "Generate Map" after changing archetype

**Code Evidence:**
- `loadArchetype()` in `world_builder.js` (lines 822-825):
  ```javascript
  loadArchetype(archetypeName) {
      this.archetype = archetypeName;
      GodotBridge.postMessage('load_archetype', { archetype: archetypeName });
  }
  ```
  - Only sends IPC, doesn't trigger generation

- `_handle_load_archetype()` in `WorldBuilderWebController.gd` (lines 457-493):
  - Loads preset from `ARCHETYPES` constant
  - Maps preset to Azgaar parameters
  - Updates `current_params` and sends `params_update` to WebView
  - **Does NOT call `_handle_generate()` or trigger regeneration**

### How Archetypes Are Loaded/Used

**Archetype Definition Sources:**
1. **GDScript Constant** (`ARCHETYPES` in `WorldBuilderWebController.gd`, lines 45-51):
   - Hardcoded presets: High Fantasy, Low Fantasy, Dark Fantasy, Realistic, Custom
   - Contains: points, heightExponent, allowErosion, plateCount, burgs, precip

2. **JSON Files:**
   - `fantasy_archetypes.json` - Detailed fantasy configs (noise, terrain, climate, biomes)
   - `archetype_azgaar_presets.json` - Azgaar parameter mappings
   - **Note:** These JSON files are not currently loaded/used by `_handle_load_archetype()`

**Parameter Mapping:**
- `_handle_load_archetype()` maps `ARCHETYPES` presets to Azgaar keys:
  - `points` → `pointsInput` (with log conversion)
  - `heightExponent` → `heightExponentInput`
  - `allowErosion` → `allowErosion`
  - `burgs` → `manorsInput`
  - `precip` → `precInput` (percentage conversion)

**Missing Integration:**
- `archetype_azgaar_presets.json` contains more complete mappings but is not used
- `fantasy_archetypes.json` has rich biome/climate data but is not integrated

### Missing Repopulation/Regeneration Logic

1. **No Auto-Regeneration After Archetype Change:**
   - `_handle_load_archetype()` should call `_handle_generate()` after updating params
   - Or `loadArchetype()` in JS should call `generate()` after IPC completes

2. **Incomplete Parameter Repopulation:**
   - Only a subset of archetype parameters are mapped (points, heightExponent, etc.)
   - Missing: templateInput, statesNumber, culturesInput, religionsNumber, temperature settings
   - `archetype_azgaar_presets.json` has these but isn't loaded

3. **No Visual Feedback:**
   - No loading state or progress indicator when archetype changes
   - User doesn't know if params updated successfully until they check manually

---

## 4. Recommendations

### High-Level Fixes

#### Fix 1: Auto-Generate Map on Load

**Location:** `WorldBuilderWebController.gd`

**Approach:**
1. After `_handle_alpine_ready()`, wait for fork readiness
2. Load default parameters from step definitions or "High Fantasy" archetype
3. Trigger automatic generation with defaults

**Pseudocode:**
```gdscript
func _handle_alpine_ready(data: Dictionary) -> void:
    # ... existing code ...
    _send_step_definitions()
    _send_archetypes()
    
    # NEW: Wait for fork, then auto-generate
    await get_tree().create_timer(0.5).timeout  # Wait for fork init
    _trigger_auto_generation_on_load()

func _trigger_auto_generation_on_load() -> void:
    # Load default archetype ("High Fantasy")
    current_archetype = "High Fantasy"
    var preset = ARCHETYPES.get("High Fantasy", {}).duplicate()
    
    # Apply preset to current_params
    # ... (existing mapping logic from _handle_load_archetype)
    
    # Also merge step definition defaults
    _merge_step_defaults_into_params()
    
    # Trigger generation
    _handle_generate({"params": current_params})
```

**Alternative:** Trigger from `_handle_fork_ready()` if fork signals readiness separately.

#### Fix 2: Auto-Regenerate on Archetype Change

**Location:** `WorldBuilderWebController.gd` and `world_builder.js`

**Approach A (Godot-side):**
- In `_handle_load_archetype()`, after sending params update, call `_handle_generate()`

**Pseudocode:**
```gdscript
func _handle_load_archetype(data: Dictionary) -> void:
    # ... existing preset loading and mapping ...
    
    # Send params update to WebView
    _send_params_update()
    
    # NEW: Auto-trigger generation
    await get_tree().create_timer(0.1).timeout  # Small delay for UI update
    _handle_generate({"params": current_params})
```

**Approach B (JS-side):**
- In `loadArchetype()`, after sending IPC, wait for params update, then call `generate()`

**Pseudocode:**
```javascript
loadArchetype(archetypeName) {
    this.archetype = archetypeName;
    GodotBridge.postMessage('load_archetype', { archetype: archetypeName });
    
    // NEW: Auto-regenerate after params update
    // Could use a callback or listen for params_update IPC
    setTimeout(() => {
        this.generate();
    }, 200);  // Wait for Godot to process and send params_update
}
```

**Recommendation:** Use Approach A (Godot-side) for consistency and to avoid timing issues.

#### Fix 3: Load Complete Archetype Presets

**Location:** `WorldBuilderWebController.gd`

**Approach:**
- Load `archetype_azgaar_presets.json` on initialization
- Use it in `_handle_load_archetype()` instead of hardcoded `ARCHETYPES` constant
- Map all parameters (templateInput, statesNumber, culturesInput, etc.)

**Pseudocode:**
```gdscript
var archetype_presets: Dictionary = {}

func _ready() -> void:
    # ... existing code ...
    _load_archetype_presets()

func _load_archetype_presets() -> void:
    var file = FileAccess.open("res://data/config/archetype_azgaar_presets.json", FileAccess.READ)
    if file:
        var json = JSON.new()
        json.parse(file.get_as_text())
        archetype_presets = json.data
        file.close()

func _handle_load_archetype(data: Dictionary) -> void:
    var archetype_name = data.get("archetype", "High Fantasy")
    var preset = archetype_presets.get(archetype_name, {})
    
    # Apply all preset parameters
    for key in preset.keys():
        current_params[key] = _clamp_parameter_value(key, preset[key])
    
    _send_params_update()
    await get_tree().create_timer(0.1).timeout
    _handle_generate({"params": current_params})
```

### Potential Code Snippets (Pseudocode Only)

**Auto-Generation on Load:**
```gdscript
# In _handle_alpine_ready() or _handle_fork_ready()
func _trigger_initial_generation() -> void:
    # 1. Load default archetype preset
    current_archetype = "High Fantasy"
    var preset = _get_archetype_preset("High Fantasy")
    
    # 2. Merge with step definition defaults
    _merge_step_defaults()
    
    # 3. Ensure seed is set
    if not current_params.has("optionsSeed"):
        current_params["optionsSeed"] = randi() % 999999999 + 1
    
    # 4. Trigger generation
    _handle_generate({"params": current_params})
```

**Archetype Change Auto-Regeneration:**
```gdscript
# In _handle_load_archetype(), after _send_params_update()
# Add:
await get_tree().create_timer(0.1).timeout
_handle_generate({"params": current_params})
```

### Impact on Performance/UX

**Performance:**
- **Auto-generation on load:** Adds ~2-5 seconds to initial load time (map generation)
  - **Mitigation:** Show loading spinner, generate in background
  - **Benefit:** Immediate visual feedback, no empty state

- **Auto-regeneration on archetype change:** Adds ~2-5 seconds per archetype change
  - **Mitigation:** Debounce rapid changes, show progress bar
  - **Benefit:** Instant preview of archetype style, better UX

**UX Improvements:**
- ✅ Eliminates empty placeholder state
- ✅ Immediate visual feedback when entering World Builder
- ✅ Instant preview when exploring different archetypes
- ✅ Reduces manual clicks (better workflow)
- ⚠️ May generate unwanted maps if user wants to adjust params first
  - **Solution:** Add "Auto-generate on load" toggle in settings (future enhancement)

---

## 5. Raw Data

### Key File Excerpts

**WorldBuilderWebController.gd - Archetype Handling:**
```gdscript
# Lines 457-493
func _handle_load_archetype(data: Dictionary) -> void:
    var archetype_name: String = data.get("archetype", "High Fantasy")
    current_archetype = archetype_name
    
    var preset: Dictionary = ARCHETYPES.get(archetype_name, {}).duplicate()
    if not preset.is_empty():
        # Map preset keys to azgaar_keys
        var preset_mapped: Dictionary = {}
        # ... mapping logic ...
        
        # Clamp and apply preset params
        for key in preset_mapped.keys():
            var clamped_value = _clamp_parameter_value(key, preset_mapped[key])
            current_params[key] = clamped_value
        
        # Send params update to WebView
        _send_params_update()
        # MISSING: No generation trigger here
```

**world_builder.js - Archetype Change:**
```javascript
// Lines 822-825
loadArchetype(archetypeName) {
    this.archetype = archetypeName;
    GodotBridge.postMessage('load_archetype', { archetype: archetypeName });
    // MISSING: No generate() call
}
```

**WorldBuilderWebController.gd - Alpine Ready:**
```gdscript
// Lines 361-368
func _handle_alpine_ready(data: Dictionary) -> void:
    MythosLogger.info("WorldBuilderWebController", "Alpine.js ready signal received from WebView")
    await get_tree().create_timer(0.1).timeout
    _send_step_definitions()
    _send_archetypes()
    # MISSING: No auto-generation trigger
```

**WorldBuilderWebController.gd - Fork Ready:**
```gdscript
// Lines 1483-1486
func _handle_fork_ready(data: Dictionary) -> void:
    MythosLogger.info("WorldBuilderWebController", "Fork is ready for generation")
    # MISSING: No auto-generation trigger
```

**world_builder_v2.html - Status Display:**
```html
<!-- Lines 53-56 -->
<div id="azgaar-status" style="padding: 2rem; text-align: center; color: #aaa; font-size: 1.2em;">
    <p>Azgaar Genesis Fork - Ready</p>
    <p style="font-size: 0.8em; margin-top: 1rem; color: #666;">Using modular API - Generate a map to see preview</p>
</div>
```

### Test Logs

**Not tested in this audit** - Focus was on code analysis. Recommended test scenarios:

1. **Load World Builder:**
   - Navigate to World Builder scene
   - Observe: Does map auto-generate? (Expected: No, currently)
   - Check console for `alpine_ready` and `fork_ready` IPC messages

2. **Change Archetype:**
   - Select "Dark Fantasy" from dropdown
   - Observe: Do parameters update? (Expected: Yes)
   - Observe: Does map regenerate? (Expected: No, currently)
   - Check console for `load_archetype` IPC and params_update

3. **Manual Generation:**
   - Click "Generate Map" button
   - Observe: Does generation complete? (Expected: Yes)
   - Check console for `generate` IPC and `map_generated` response

---

## Summary

**Issue 1 (Auto-Generation on Load):** Missing trigger after Alpine.js and fork initialization. Solution: Add `_trigger_initial_generation()` called from `_handle_alpine_ready()` or `_handle_fork_ready()`.

**Issue 2 (Archetype Change Trigger):** Missing auto-regeneration after archetype preset is applied. Solution: Add `_handle_generate()` call at end of `_handle_load_archetype()`.

**Additional Recommendations:**
- Load `archetype_azgaar_presets.json` for complete parameter mappings
- Add loading states and progress indicators for better UX
- Consider adding "Auto-generate on load" toggle for users who prefer manual control
