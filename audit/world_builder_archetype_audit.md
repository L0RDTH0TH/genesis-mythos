# World Builder UI Audit Report – Auto-Generation and Archetype Behavior

**Date:** 2025-12-29  
**Focus:** Auto-map generation on load and archetype change trigger behavior  
**Status:** Current implementation analysis

---

## 1. Current Implementation Summary

### Overview of Relevant Code Files

**Godot (GDScript):**
- `res://scripts/ui/WorldBuilderWebController.gd` - Main controller for World Builder UI, handles IPC, map generation, archetype loading
- `res://scripts/managers/AzgaarDataConverter.gd` - Converts Azgaar JSON to Godot Image resources
- `res://scripts/managers/AzgaarIntegrator.gd` - Manages Azgaar file copying and URLs

**Web (HTML/JS/Alpine.js):**
- `res://assets/ui_web/templates/world_builder_v2.html` - Main HTML template with Azgaar fork integration
- `res://assets/ui_web/js/world_builder.js` - Alpine.js component for UI state and IPC handlers

**Data (JSON):**
- `res://data/fantasy_archetypes.json` - Detailed fantasy archetype definitions (noise, terrain, climate, biomes)
- `res://data/config/azgaar_step_parameters.json` - Step definitions with parameter defaults
- `res://data/config/archetype_azgaar_presets.json` - Azgaar-specific parameter presets per archetype

### Key Data Flows

**Initialization Flow:**
1. `WorldBuilderWebController._ready()` loads HTML template (`world_builder_v2.html`)
2. HTML loads Alpine.js and Azgaar fork module
3. Alpine.js `init()` sends `alpine_ready` IPC to Godot
4. Godot `_handle_alpine_ready()` sends step definitions and archetype names
5. Godot waits 3 seconds for `fork_ready` IPC (or proceeds anyway)
6. Godot calls `_trigger_auto_generation_on_load()` which:
   - Sets `current_archetype = "High Fantasy"`
   - Calls `_handle_load_archetype()` with archetype data
   - `_handle_load_archetype()` loads preset, updates params, and calls `_handle_generate()`

**Archetype Change Flow:**
1. User selects archetype from dropdown (`@change="loadArchetype($event.target.value)"`)
2. `loadArchetype()` in `world_builder.js` sends `load_archetype` IPC to Godot
3. Godot `_handle_load_archetype()`:
   - Loads preset from `archetype_presets` (loaded from `archetype_azgaar_presets.json`)
   - Clamps and applies parameters to `current_params`
   - Sends `params_update` to WebView via `_send_params_update()`
   - **Calls `_handle_generate()` at line 503** (auto-triggers generation)

**Generation Flow:**
1. `_handle_generate()` checks `fork_ready` flag
2. If fork ready: `_generate_via_fork()` executes JS in WebView
3. If fork not ready: `_generate_via_iframe()` (fallback, but template has no iframe)
4. Map generated, preview rendered, `map_generated` IPC sent back
5. `_handle_map_generated()` processes JSON and sends preview to WebView

---

## 2. Issue 1: Auto-Map Generation on Load

### Observed Behavior

**Expected:**
- When World Builder loads, the central preview area should auto-populate with a 2D Azgaar-generated map using default settings for "High Fantasy" archetype
- No manual "Generate Map" click should be required

**Current State (from code analysis):**
- `_trigger_auto_generation_on_load()` exists (line 1503-1507) and is called from `_handle_alpine_ready()` (line 394)
- However, there are potential timing issues:
  - `_handle_alpine_ready()` waits 3 seconds for `fork_ready` IPC (line 391)
  - If `fork_ready` is never received, it proceeds anyway (line 392-393)
  - `_trigger_auto_generation_on_load()` calls `_handle_load_archetype()` which calls `_handle_generate()`
  - But `_handle_generate()` checks `fork_ready` flag (line 604) - if false, it falls back to iframe mode
  - Iframe mode will fail because `world_builder_v2.html` has no iframe

**Root Causes:**

1. **Race Condition with Fork Initialization:**
   - `fork_ready` flag is set in `_handle_fork_ready()` (line 1499) when `fork_ready` IPC is received
   - `fork_ready` IPC is sent from HTML/JS when Azgaar Genesis module loads (line 228 in `world_builder_v2.html`)
   - If `_trigger_auto_generation_on_load()` runs before `fork_ready` IPC is received, `fork_ready` flag will be false
   - This causes fallback to iframe mode, which fails

2. **Missing Fork Readiness Check:**
   - `_trigger_auto_generation_on_load()` doesn't verify that fork is actually ready before triggering generation
   - It relies on the 3-second timeout in `_handle_alpine_ready()`, but this may not be sufficient

3. **Default Parameters Not Fully Applied:**
   - `_trigger_auto_generation_on_load()` only loads the "High Fantasy" archetype preset
   - It doesn't merge step definition defaults for parameters not in the archetype preset
   - This could result in missing required parameters (e.g., `optionsSeed`)

### Missing Elements

1. **Explicit Fork Readiness Wait:**
   - Should wait for `fork_ready` IPC before triggering auto-generation
   - Or check `fork_ready` flag before calling `_handle_generate()`

2. **Parameter Completeness:**
   - Should merge archetype preset with step definition defaults to ensure all required parameters are present
   - Should ensure `optionsSeed` is set (currently handled in `_handle_generate()` at line 574-584, but should be done earlier)

3. **Error Handling:**
   - No error handling if fork never becomes ready
   - No user feedback if auto-generation fails

---

## 3. Issue 2: Archetype Change Trigger

### Observed Behavior

**Expected:**
- Changing the archetype (e.g., via dropdown) should:
  1. Repopulate all child parameters with archetype-specific defaults
  2. Automatically regenerate the map preview
  3. Prepare for user adjustments

**Current State (from code analysis):**
- `_handle_load_archetype()` (line 483-505) **DOES** trigger generation:
  - Line 503: `_handle_generate({"params": current_params})`
- However, there are potential issues:

1. **Parameter Mapping:**
   - `archetype_azgaar_presets.json` contains direct Azgaar parameter keys (e.g., `templateInput`, `pointsInput`)
   - These are applied directly to `current_params` (line 495)
   - This is correct and should work

2. **Timing:**
   - Small delay (0.1 seconds) before triggering generation (line 502)
   - This should be sufficient for UI update

3. **Missing Parameters:**
   - If archetype preset doesn't include all required parameters, generation may fail or use incorrect defaults
   - `_handle_generate()` has fallback logic for `optionsSeed` (line 574-584), but other parameters might be missing

### Root Causes

1. **Incomplete Preset Coverage:**
   - `archetype_azgaar_presets.json` only includes a subset of parameters (e.g., `templateInput`, `pointsInput`, `statesNumber`, etc.)
   - Missing parameters like `mapWidthInput`, `mapHeightInput`, `optionsSeed` are not in presets
   - These should be merged from step definition defaults

2. **No Visual Feedback:**
   - When archetype changes, parameters update in UI, but no immediate visual indication that generation is starting
   - User might not realize that generation is automatic

3. **Potential Race Condition:**
   - If user changes archetype multiple times quickly, multiple generations might be triggered
   - No debouncing or cancellation of previous generations

### Missing Elements

1. **Parameter Merging:**
   - Should merge archetype preset with step definition defaults
   - Should ensure all required parameters are present before generation

2. **Generation Cancellation:**
   - Should cancel any in-progress generation when archetype changes
   - Should debounce rapid archetype changes

3. **User Feedback:**
   - Should show loading state when archetype changes
   - Should indicate that generation is automatic

---

## 4. Recommendations

### High-Level Fixes

#### Fix 1: Auto-Generate Map on Load (Reliable Fork Readiness)

**Location:** `WorldBuilderWebController.gd`

**Approach:**
1. Wait for `fork_ready` IPC explicitly before triggering auto-generation
2. Merge archetype preset with step definition defaults
3. Ensure all required parameters are present

**Pseudocode:**
```gdscript
func _handle_alpine_ready(data: Dictionary) -> void:
    """Handle alpine_ready IPC message from WebView."""
    MythosLogger.info("WorldBuilderWebController", "Alpine.js ready signal received from WebView")
    await get_tree().create_timer(0.1).timeout
    _send_step_definitions()
    _send_archetypes()
    
    # Wait for fork readiness explicitly
    if not fork_ready:
        # Wait up to 5 seconds for fork_ready IPC
        var wait_time: float = 0.0
        while not fork_ready and wait_time < 5.0:
            await get_tree().create_timer(0.1).timeout
            wait_time += 0.1
        
        if not fork_ready:
            MythosLogger.warn("WorldBuilderWebController", "fork_ready IPC not received after 5 seconds, proceeding anyway")
    
    # Now trigger auto-generation
    _trigger_auto_generation_on_load()

func _trigger_auto_generation_on_load() -> void:
    """Triggers automatic map generation on initial load with default archetype."""
    current_archetype = "High Fantasy"
    var data: Dictionary = {"archetype": current_archetype}
    _handle_load_archetype(data)  # This will load preset, update params, and trigger generation
```

**Alternative:** Use a signal-based approach where `_handle_fork_ready()` triggers auto-generation if Alpine.js is already ready.

#### Fix 2: Improve Archetype Change (Parameter Merging)

**Location:** `WorldBuilderWebController.gd`

**Approach:**
1. Merge archetype preset with step definition defaults
2. Ensure all required parameters are present
3. Cancel any in-progress generation

**Pseudocode:**
```gdscript
func _handle_load_archetype(data: Dictionary) -> void:
    """Handle load_archetype message from WebView."""
    var archetype_name: String = data.get("archetype", "High Fantasy")
    current_archetype = archetype_name
    
    # Cancel any in-progress generation
    if generation_timeout_timer and not generation_timeout_timer.is_stopped():
        generation_timeout_timer.stop()
    
    var preset: Dictionary = archetype_presets.get(archetype_name, {}).duplicate()
    
    # Merge with step definition defaults
    var merged_params: Dictionary = {}
    
    # First, load defaults from step definitions
    if not step_definitions.is_empty():
        var steps: Array = step_definitions.get("steps", [])
        for step_dict in steps:
            var parameters: Array = step_dict.get("parameters", [])
            for param_dict in parameters:
                if param_dict.get("curated", true) == true and param_dict.has("default"):
                    var azgaar_key: String = param_dict.get("azgaar_key", "")
                    if not azgaar_key.is_empty():
                        merged_params[azgaar_key] = param_dict["default"]
    
    # Then, override with archetype preset values
    for key in preset.keys():
        var value = preset[key]
        var clamped_value = _clamp_parameter_value(key, value)
        merged_params[key] = clamped_value
    
    # Ensure optionsSeed is set
    if not merged_params.has("optionsSeed"):
        merged_params["optionsSeed"] = randi() % 999999999 + 1
    
    current_params = merged_params
    
    # Send params update to WebView
    _send_params_update()
    MythosLogger.info("WorldBuilderWebController", "Loaded archetype preset", {"archetype": archetype_name, "params": merged_params})
    
    # Auto-trigger generation after archetype change
    await get_tree().create_timer(0.1).timeout  # Small delay for UI update
    _handle_generate({"params": current_params})
```

#### Fix 3: Add User Feedback

**Location:** `world_builder.js` and `world_builder_v2.html`

**Approach:**
- Show loading state when archetype changes
- Display message indicating that generation is automatic

**Pseudocode:**
```javascript
loadArchetype(archetypeName) {
    this.archetype = archetypeName;
    this.isGenerating = true;  // Show loading state
    this.statusText = 'Loading archetype preset...';
    GodotBridge.postMessage('load_archetype', { archetype: archetypeName });
}
```

### Impact on Performance/UX

**Positive:**
- Immediate visual feedback when World Builder loads
- Automatic generation saves user clicks
- Archetype changes provide instant preview updates

**Potential Issues:**
- Auto-generation on load might slow down initial load time
- Multiple rapid archetype changes could trigger multiple generations (needs debouncing)
- Generation might fail if fork isn't ready (needs error handling)

---

## 5. Raw Data

### Key Code Excerpts

**WorldBuilderWebController.gd - Auto-Generation Trigger:**
```gdscript
func _handle_alpine_ready(data: Dictionary) -> void:
    """Handle alpine_ready IPC message from WebView."""
    MythosLogger.info("WorldBuilderWebController", "Alpine.js ready signal received from WebView")
    await get_tree().create_timer(0.1).timeout
    _send_step_definitions()
    _send_archetypes()
    
    # Wait for fork initialization (fork_ready IPC), then trigger auto-generation
    await get_tree().create_timer(3.0).timeout
    if not fork_ready:
        MythosLogger.warn("WorldBuilderWebController", "fork_ready IPC not received, proceeding with auto-generation anyway")
    _trigger_auto_generation_on_load()

func _trigger_auto_generation_on_load() -> void:
    """Triggers automatic map generation on initial load with default archetype."""
    current_archetype = "High Fantasy"
    var data: Dictionary = {"archetype": current_archetype}
    _handle_load_archetype(data)  # This will load preset, update params, and trigger generation
```

**WorldBuilderWebController.gd - Archetype Change Handler:**
```gdscript
func _handle_load_archetype(data: Dictionary) -> void:
    """Handle load_archetype message from WebView."""
    var archetype_name: String = data.get("archetype", "High Fantasy")
    current_archetype = archetype_name
    
    var preset: Dictionary = archetype_presets.get(archetype_name, {}).duplicate()
    if not preset.is_empty():
        # Apply all keys from JSON preset directly (JSON already uses Azgaar keys)
        for key in preset.keys():
            var value = preset[key]
            var clamped_value = _clamp_parameter_value(key, value)
            current_params[key] = clamped_value
        
        # Send params update to WebView
        _send_params_update()
        MythosLogger.info("WorldBuilderWebController", "Loaded archetype preset", {"archetype": archetype_name, "params": preset})
        
        # Auto-trigger generation after archetype change
        await get_tree().create_timer(0.1).timeout
        _handle_generate({"params": current_params})
```

**world_builder.js - Archetype Change Handler:**
```javascript
loadArchetype(archetypeName) {
    this.archetype = archetypeName;
    GodotBridge.postMessage('load_archetype', { archetype: archetypeName });
}
```

**world_builder_v2.html - Fork Ready Signal:**
```javascript
// Notify Godot that fork is ready via IPC
if (window.GodotBridge && window.GodotBridge.postMessage) {
    window.GodotBridge.postMessage('fork_ready', {});
    console.log('[Azgaar Genesis] Sent fork_ready IPC message to Godot');
}
```

### Test Logs (Not Available)

No test logs were generated during this audit. Future testing should:
1. Launch World Builder and verify auto-generation occurs
2. Change archetype and verify regeneration occurs
3. Check console logs for timing issues
4. Verify fork readiness IPC is received

---

## Summary

**Current State:**
- Auto-generation on load is **implemented** but may have timing issues with fork readiness
- Archetype change auto-regeneration is **implemented** and should work correctly
- Both features rely on proper IPC timing and fork initialization

**Primary Issues:**
1. Race condition between Alpine.js ready and fork ready
2. Missing parameter merging (archetype preset + step defaults)
3. No error handling if fork never becomes ready
4. No user feedback during auto-generation

**Recommended Actions:**
1. Implement explicit fork readiness wait in `_handle_alpine_ready()`
2. Add parameter merging in `_handle_load_archetype()`
3. Add error handling and user feedback
4. Test thoroughly to verify timing is correct
