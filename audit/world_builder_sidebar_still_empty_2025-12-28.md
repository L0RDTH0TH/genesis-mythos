# World Builder UI – 8-Step Left Sidebar Still Empty After Fix – Investigation Report – 2025-12-28

**Date:** 2025-12-28  
**Status:** Investigation Complete  
**Purpose:** Deep investigation into why the 8-step left sidebar remains empty despite correct HTML template being loaded

---

## Overview & Context

The World Builder UI was recently fixed to load the custom template `res://assets/ui_web/templates/world_builder.html` instead of the previous template. The run log confirms:
- ✅ Correct HTML file is loaded (`res://assets/ui_web/templates/world_builder.html`)
- ✅ Step definitions are loaded (8 steps detected in JSON)
- ✅ No obvious errors in the log

**Yet the left column (`.left-tabs-panel`) remains empty when the World Builder is opened.**

This report documents a comprehensive investigation into the root cause(s) of this rendering failure.

---

## Files Examined

### 1. HTML Template: `assets/ui_web/templates/world_builder.html`

**Key Structure:**
```10:31:assets/ui_web/templates/world_builder.html
    <div class="world-builder-container" x-data="worldBuilder">
        <!-- Top Bar -->
        <div class="top-bar">
            <h1 class="title-label">World Builder – Forging the World</h1>
        </div>

        <!-- Main Content Area -->
        <div class="main-hsplit">
            <!-- Left Panel: Numbered Tab Bar (BG3-style) -->
            <div class="left-tabs-panel">
                <div class="left-tabs-container">
                    <template x-for="(step, index) in steps" :key="index">
                        <button 
                            class="left-tab-button" 
                            :class="{ 'active': currentStep === index }"
                            @click="setStep(index)">
                            <span class="tab-number" x-text="index + 1"></span>
                            <span class="tab-label" x-text="step.title || `Step ${index + 1}`"></span>
                        </button>
                    </template>
                </div>
            </div>
```

**Script Loading:**
```151:153:assets/ui_web/templates/world_builder.html
    <script src="../js/bridge.js"></script>
    <script src="../js/alpine.min.js" defer></script>
    <script src="../js/world_builder.js" defer></script>
```

**Critical Finding:** Alpine.js and `world_builder.js` are both loaded with `defer` attribute, meaning:
- HTML parses first
- Alpine.js loads and initializes
- Alpine.js tries to find `worldBuilder` component (referenced in `x-data="worldBuilder"` on line 10)
- `world_builder.js` loads and registers the component in `alpine:init` event
- **Potential race condition:** Alpine might try to initialize the component before it's registered

### 2. JavaScript Component: `assets/ui_web/js/world_builder.js`

**Component Registration:**
```44:100:assets/ui_web/js/world_builder.js
// Register the worldBuilder component only after Alpine is fully initialized
document.addEventListener('alpine:init', () => {
    Alpine.data('worldBuilder', () => ({
        currentStep: 0,
        totalSteps: 8,
        steps: [],
        params: {},
        archetype: 'High Fantasy',
        archetypeNames: ['High Fantasy', 'Low Fantasy', 'Dark Fantasy', 'Realistic', 'Custom'],
        seed: Math.floor(Math.random() * 1e9),
        isGenerating: false,
        progressValue: 0,
        statusText: '',
        updateDebounceTimer: null,
        
        init() {
            // Store instance for global access
            window.worldBuilderInstance = this;
            console.log('[WorldBuilder] Alpine.js init() called, steps:', this.steps.length);
            
            // Notify Godot that Alpine.js is ready via IPC
            if (window.GodotBridge && window.GodotBridge.postMessage) {
                window.GodotBridge.postMessage('alpine_ready', {});
                console.log('[WorldBuilder] Sent alpine_ready IPC message to Godot');
            } else {
                console.warn('[WorldBuilder] GodotBridge.postMessage not available - cannot notify Godot');
            }
            
            // Check if steps data was stored before Alpine initialized
            if (window._pendingStepsData && window._pendingStepsData.steps) {
                console.log('[WorldBuilder] Loading pending steps data:', window._pendingStepsData.steps.length);
                this.steps = window._pendingStepsData.steps;
                this._initializeParams();
                delete window._pendingStepsData;
            } else {
                // Request step definitions from Godot (fallback if direct injection fails)
                console.log('[WorldBuilder] Requesting step definitions from Godot');
                if (window.GodotBridge && window.GodotBridge.requestData) {
                    GodotBridge.requestData('step_definitions', (data) => {
                        if (data && data.steps) {
                            console.log('[WorldBuilder] Received steps via requestData:', data.steps.length);
                            this.steps = data.steps;
                            this._initializeParams();
                        }
                    });
                } else {
                    console.warn('[WorldBuilder] GodotBridge.requestData not available');
                }
            }
            
            // Request archetypes (already have names, but can request full data if needed)
            // Archetype names are already set in archetypeNames array
            
            // Send initial step
            this.setStep(0);
            console.log('[WorldBuilder] Initialized, current step:', this.currentStep, 'total steps:', this.steps.length);
        },
```

**Critical Finding:** 
- `steps` array is initialized as **empty** (`steps: []` on line 49)
- Steps are populated only if:
  1. `window._pendingStepsData` exists (lines 73-77)
  2. OR via `GodotBridge.requestData()` callback (lines 82-88)
  3. OR via direct assignment from Godot controller (see controller analysis)

### 3. Controller Script: `scripts/ui/WorldBuilderWebController.gd`

**Step Definitions Loading:**
```108:135:scripts/ui/WorldBuilderWebController.gd
func _load_step_definitions() -> void:
	"""Load step definitions from JSON file."""
	var file: FileAccess = FileAccess.open(STEP_PARAMETERS_PATH, FileAccess.READ)
	if not file:
		MythosLogger.error("WorldBuilderWebController", "Failed to load step parameters", {"path": STEP_PARAMETERS_PATH})
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		MythosLogger.error("WorldBuilderWebController", "Failed to parse step parameters JSON", {"error": parse_result})
		return
	
	var data: Dictionary = json.data
	if not data.has("steps") or not data.steps is Array:
		MythosLogger.error("WorldBuilderWebController", "Invalid step parameters JSON structure")
		return
	
	# Store step definitions
	step_definitions = data
	MythosLogger.info("WorldBuilderWebController", "Loaded step definitions", {
		"count": data.steps.size(),
		"step_0_params": data.steps[0].get("parameters", []).size() if data.steps.size() > 0 else 0,
		"step_1_params": data.steps[1].get("parameters", []).size() if data.steps.size() > 1 else 0
	})
```

**Step Definitions Transmission:**
```140:207:scripts/ui/WorldBuilderWebController.gd
func _send_step_definitions() -> void:
	"""Send step definitions to WebView via IPC with reactive assignment."""
	if not web_view or step_definitions.is_empty():
		MythosLogger.warn("WorldBuilderWebController", "Cannot send step definitions - web_view or data missing")
		return
	
	# Send step definitions as JSON string with reactive assignment
	var json_string: String = JSON.stringify(step_definitions)
	MythosLogger.debug("WorldBuilderWebController", "Sending step definitions JSON", {
		"json_length": json_string.length(),
		"steps_count": step_definitions.get("steps", []).size()
	})
	
	# Use reactive assignment and force Alpine.js to detect changes
	# Fallback: store in _pendingStepsData if worldBuilderInstance not found
	var script: String = """
		(function() {
			try {
				var stepData = %s;
				
				if (!window.worldBuilderInstance) {
					// Store in pending data for later initialization
					console.log('[WorldBuilder] worldBuilderInstance not found, storing in _pendingStepsData');
					window._pendingStepsData = stepData;
					return 'pending';
				}
				
				console.log('[WorldBuilder] Received step definitions:', stepData.steps.length, 'steps');
				
				// Reactive assignment - use Object.assign or direct assignment with nextTick
				if (stepData && stepData.steps && Array.isArray(stepData.steps)) {
					// Clear existing steps and assign new ones (triggers reactivity)
					window.worldBuilderInstance.steps = [];
					window.worldBuilderInstance.steps = stepData.steps;
					
					// Force Alpine to update by triggering a reactive change
					if (window.worldBuilderInstance.$nextTick) {
						window.worldBuilderInstance.$nextTick(() => {
							console.log('[WorldBuilder] Steps updated via $nextTick:', window.worldBuilderInstance.steps.length);
							window.worldBuilderInstance._initializeParams();
						});
					} else {
						// Fallback: direct call
						window.worldBuilderInstance._initializeParams();
						console.log('[WorldBuilder] Steps updated (no $nextTick):', window.worldBuilderInstance.steps.length);
					}
					
					return true;
				} else {
					console.error('[WorldBuilder] Invalid step data structure');
					return false;
				}
			} catch (e) {
				console.error('[WorldBuilder] Error setting steps:', e);
				return false;
			}
		})();
	""" % json_string
	
	if web_view.has_method("execute_js"):
		var result = web_view.execute_js(script)
		if result == "pending":
			MythosLogger.info("WorldBuilderWebController", "Step definitions stored in _pendingStepsData (Alpine.js not ready yet)")
		else:
			MythosLogger.info("WorldBuilderWebController", "Sent step definitions to WebView", {"result": result})
	elif web_view.has_method("eval"):
		web_view.eval(script)
		MythosLogger.info("WorldBuilderWebController", "Sent step definitions to WebView via eval")
```

**Alpine Ready Handler:**
```342:347:scripts/ui/WorldBuilderWebController.gd
func _handle_alpine_ready(data: Dictionary) -> void:
	"""Handle alpine_ready IPC message from WebView."""
	MythosLogger.info("WorldBuilderWebController", "Alpine.js ready signal received from WebView")
	# Now that Alpine.js is ready, send step definitions and archetypes
	_send_step_definitions()
	_send_archetypes()
```

**Critical Finding:**
- Controller waits for `alpine_ready` IPC message (line 324-325)
- Then calls `_send_step_definitions()` (line 346)
- The script tries to set `window.worldBuilderInstance.steps` directly (line 172-173)
- If `worldBuilderInstance` doesn't exist, it stores in `_pendingStepsData` (line 163)
- The JavaScript `init()` method checks for `_pendingStepsData` (line 73), but this might not work if timing is off

### 4. CSS Styling: `assets/ui_web/css/world_builder.css`

**Left Sidebar Styles:**
```79:97:assets/ui_web/css/world_builder.css
/* Left Tabs Panel (BG3-style numbered tabs) */
.left-tabs-panel {
    width: var(--left-tabs-width, 280px);
    min-width: var(--left-tabs-width-min, 180px);
    max-width: var(--left-tabs-width-max, 300px);
    background-color: var(--bg-panel);
    border-right: 2px solid var(--border-gold);
    display: flex;
    flex-direction: column;
    overflow: hidden;
}

.left-tabs-container {
    display: flex;
    flex-direction: column;
    padding: var(--spacing-medium);
    gap: var(--spacing-small);
    overflow-y: auto;
}
```

**Critical Finding:** CSS looks correct. The sidebar should be visible if the DOM elements exist. No `display: none`, `width: 0`, or `opacity: 0` that would hide it.

### 5. Bridge.js: `assets/ui_web/js/bridge.js`

**IPC Mechanism:**
```5:28:assets/ui_web/js/bridge.js
window.GodotBridge = {
    // Send message to Godot
    postMessage: function(type, data) {
        // Support both object format {type, data} and separate parameters
        if (typeof type === 'object' && type !== null) {
            // Single object parameter format
            data = type;
            type = data.type || 'message';
        }
        
        // Build message object
        var message = {
            type: type,
            data: data || {},
            timestamp: Date.now()
        };
        
        // godot_wry provides window.ipc.postMessage directly (see character_creator example)
        if (window.ipc && typeof window.ipc.postMessage === 'function') {
            window.ipc.postMessage(JSON.stringify(message));
        } else {
            console.warn('Godot IPC not available - message not sent:', message);
        }
    },
```

**Critical Finding:** IPC mechanism looks correct. Uses `window.ipc.postMessage` which is provided by godot_wry.

---

## HTML Structure Analysis

### ✅ Correct Elements Present

1. **Root Alpine Component:** `<div class="world-builder-container" x-data="worldBuilder">` (line 10)
2. **Left Sidebar Container:** `<div class="left-tabs-panel">` (line 19)
3. **Tabs Container:** `<div class="left-tabs-container">` (line 20)
4. **Alpine Loop:** `<template x-for="(step, index) in steps" :key="index">` (line 21)
5. **Button Structure:** Correct button with number and label (lines 22-28)

### ⚠️ Potential Issues

1. **Alpine.js Template Syntax:** The `x-for` directive uses `<template>` tag, which is correct for Alpine.js v3
2. **Component Reference:** `x-data="worldBuilder"` references the component name, which should be registered via `Alpine.data('worldBuilder', ...)`

---

## Alpine.js / JavaScript State Analysis

### Component Registration Flow

1. **HTML loads** → Alpine.js script tag with `defer` attribute
2. **Alpine.js initializes** → Looks for `x-data` directives
3. **Finds `x-data="worldBuilder"`** → Tries to find registered component
4. **Component not found yet** → `world_builder.js` hasn't loaded (also has `defer`)
5. **`world_builder.js` loads** → Registers component in `alpine:init` event
6. **Component registered** → Alpine should re-initialize the element

**Potential Issue:** If Alpine.js tries to initialize the component before it's registered, it might fail silently or create an empty component instance.

### Steps Array Population Flow

1. **Component `init()` called** → `steps: []` (empty)
2. **Checks `window._pendingStepsData`** → If exists, loads it (lines 73-77)
3. **Otherwise requests from Godot** → `GodotBridge.requestData('step_definitions', ...)` (lines 82-88)
4. **Godot sends step definitions** → Via `_send_step_definitions()` after `alpine_ready` message
5. **Controller sets `window.worldBuilderInstance.steps`** → Direct assignment (line 172-173)

**Potential Issue:** If `worldBuilderInstance` doesn't exist when Godot sends data, it stores in `_pendingStepsData`. But if the component `init()` already ran and didn't find `_pendingStepsData`, it won't check again.

---

## Data Flow from Godot to Web (Step Definitions Transmission)

### Sequence of Events

1. **Controller `_ready()` called** → Loads HTML, waits 0.5s, injects theme
2. **HTML loads** → Alpine.js and `world_builder.js` load with `defer`
3. **Alpine.js initializes** → Component registration happens in `alpine:init` event
4. **Component `init()` called** → Sends `alpine_ready` IPC message to Godot
5. **Controller receives `alpine_ready`** → Calls `_send_step_definitions()`
6. **Controller executes JS** → Tries to set `window.worldBuilderInstance.steps`

### Potential Race Conditions

1. **Timing Issue #1:** Alpine.js might initialize before `world_builder.js` registers the component
   - **Symptom:** `x-data="worldBuilder"` fails to find component
   - **Result:** Empty component instance or Alpine error

2. **Timing Issue #2:** Controller sends step definitions before `worldBuilderInstance` exists
   - **Symptom:** Data stored in `_pendingStepsData`, but component `init()` already ran
   - **Result:** Steps array remains empty

3. **Timing Issue #3:** Component `init()` runs before `_pendingStepsData` is set
   - **Symptom:** `init()` checks for `_pendingStepsData`, finds nothing, requests from Godot
   - **Result:** Steps might be populated via `requestData` callback, but timing is uncertain

---

## CSS & Visibility Analysis

### Left Sidebar CSS Rules

```79:97:assets/ui_web/css/world_builder.css
.left-tabs-panel {
    width: var(--left-tabs-width, 280px);
    min-width: var(--left-tabs-width-min, 180px);
    max-width: var(--left-tabs-width-max, 300px);
    background-color: var(--bg-panel);
    border-right: 2px solid var(--border-gold);
    display: flex;
    flex-direction: column;
    overflow: hidden;
}

.left-tabs-container {
    display: flex;
    flex-direction: column;
    padding: var(--spacing-medium);
    gap: var(--spacing-small);
    overflow-y: auto;
}
```

**Analysis:**
- ✅ No `display: none` or `visibility: hidden`
- ✅ Width is set (280px default)
- ✅ Background color is set
- ✅ Border is visible
- ⚠️ **If `steps` array is empty, `x-for` loop renders nothing** → Container exists but is empty

### Button Styles

```99:140:assets/ui_web/css/world_builder.css
.left-tab-button {
    display: flex;
    align-items: center;
    gap: var(--spacing-small);
    height: 50px;
    min-height: 50px;
    background-color: var(--bg-panel);
    border: 2px solid var(--border-gold);
    border-radius: 4px;
    color: var(--font-default);
    font-size: 16px;
    font-family: 'Times New Roman', serif;
    cursor: pointer;
    transition: all 0.2s;
    text-align: left;
    padding: 0 var(--spacing-medium);
    position: relative;
}
```

**Analysis:** Button styles look correct. If buttons were rendered, they would be visible.

---

## Runtime Debug Results

**Note:** Direct runtime debugging via MCP is limited. The following analysis is based on code inspection and logical deduction.

### Expected Console Logs (if working correctly)

1. `[WorldBuilder] Alpine.js init() called, steps: 0` (component initialized with empty steps)
2. `[WorldBuilder] Sent alpine_ready IPC message to Godot` (IPC message sent)
3. `[WorldBuilder] Received step definitions: 8 steps` (steps received from Godot)
4. `[WorldBuilder] Steps updated via $nextTick: 8` (steps array populated)

### Potential Failure Points

1. **Component not registered:** Alpine.js can't find `worldBuilder` component
   - **Console:** Alpine.js error about missing component
   - **Result:** `x-data="worldBuilder"` fails, component not initialized

2. **Steps array remains empty:** Data not reaching Alpine component
   - **Console:** `[WorldBuilder] Alpine.js init() called, steps: 0` (but never updates)
   - **Result:** `x-for` loop has nothing to iterate, sidebar empty

3. **Timing issue:** `worldBuilderInstance` not set when Godot sends data
   - **Console:** `[WorldBuilder] worldBuilderInstance not found, storing in _pendingStepsData`
   - **Result:** Data stored but component already initialized, steps remain empty

---

## Identified Root Cause(s)

### Primary Root Cause: **Alpine.js Component Registration Timing Race Condition**

**Problem:** The HTML template uses `x-data="worldBuilder"` immediately, but the component is registered in `alpine:init` event after both scripts load with `defer`. This creates a race condition where:

1. HTML parses → Alpine.js script tag with `defer` is encountered
2. Alpine.js loads and initializes → Scans DOM for `x-data` directives
3. Finds `x-data="worldBuilder"` → Tries to find registered component
4. Component not found → `world_builder.js` hasn't loaded yet (also has `defer`)
5. Alpine.js might fail silently or create an empty component instance
6. `world_builder.js` loads → Registers component in `alpine:init` event
7. **But Alpine might not re-initialize the element** → Component remains in broken state

**Evidence:**
- HTML line 10: `x-data="worldBuilder"` used immediately
- HTML line 152: Alpine.js loaded with `defer`
- HTML line 153: `world_builder.js` loaded with `defer`
- JS line 45: Component registered in `alpine:init` event

### Secondary Root Cause: **Steps Array Not Populated Due to Timing**

**Problem:** Even if the component initializes correctly, the `steps` array might remain empty due to timing issues:

1. Component `init()` runs → `steps: []` (empty)
2. Checks `window._pendingStepsData` → Not set yet (Godot hasn't sent data)
3. Falls back to `GodotBridge.requestData()` → Async callback
4. Godot receives `alpine_ready` → Sends step definitions
5. **But if `worldBuilderInstance` doesn't exist yet** → Data stored in `_pendingStepsData`
6. Component already initialized → Never checks `_pendingStepsData` again
7. `requestData` callback might not fire → Steps remain empty

**Evidence:**
- JS line 49: `steps: []` initialized as empty
- JS line 73: Checks `_pendingStepsData` only in `init()`
- Controller line 163: Stores in `_pendingStepsData` if instance not found
- Controller line 172: Tries to set `worldBuilderInstance.steps` directly

### Tertiary Root Cause: **Alpine.js Reactivity Not Triggered**

**Problem:** Even if steps are set, Alpine.js might not detect the change and re-render:

1. Steps array is set → `window.worldBuilderInstance.steps = stepData.steps`
2. Alpine.js reactivity might not detect the change → No re-render
3. `$nextTick` is used (line 176), but if `$nextTick` doesn't exist, fallback might not work

**Evidence:**
- Controller line 172-173: Direct assignment `window.worldBuilderInstance.steps = stepData.steps`
- Controller line 176: Uses `$nextTick` if available
- Controller line 183: Fallback direct call if `$nextTick` not available

---

## Supporting Evidence

### Code Snippets

**HTML Template - Component Reference:**
```10:10:assets/ui_web/templates/world_builder.html
    <div class="world-builder-container" x-data="worldBuilder">
```

**HTML Template - Script Loading:**
```151:153:assets/ui_web/templates/world_builder.html
    <script src="../js/bridge.js"></script>
    <script src="../js/alpine.min.js" defer></script>
    <script src="../js/world_builder.js" defer></script>
```

**JavaScript - Component Registration:**
```44:49:assets/ui_web/js/world_builder.js
// Register the worldBuilder component only after Alpine is fully initialized
document.addEventListener('alpine:init', () => {
    Alpine.data('worldBuilder', () => ({
        currentStep: 0,
        totalSteps: 8,
        steps: [],
```

**JavaScript - Steps Population Logic:**
```72:92:assets/ui_web/js/world_builder.js
            // Check if steps data was stored before Alpine initialized
            if (window._pendingStepsData && window._pendingStepsData.steps) {
                console.log('[WorldBuilder] Loading pending steps data:', window._pendingStepsData.steps.length);
                this.steps = window._pendingStepsData.steps;
                this._initializeParams();
                delete window._pendingStepsData;
            } else {
                // Request step definitions from Godot (fallback if direct injection fails)
                console.log('[WorldBuilder] Requesting step definitions from Godot');
                if (window.GodotBridge && window.GodotBridge.requestData) {
                    GodotBridge.requestData('step_definitions', (data) => {
                        if (data && data.steps) {
                            console.log('[WorldBuilder] Received steps via requestData:', data.steps.length);
                            this.steps = data.steps;
                            this._initializeParams();
                        }
                    });
                } else {
                    console.warn('[WorldBuilder] GodotBridge.requestData not available');
                }
            }
```

**Controller - Step Definitions Transmission:**
```155:197:scripts/ui/WorldBuilderWebController.gd
	var script: String = """
		(function() {
			try {
				var stepData = %s;
				
				if (!window.worldBuilderInstance) {
					// Store in pending data for later initialization
					console.log('[WorldBuilder] worldBuilderInstance not found, storing in _pendingStepsData');
					window._pendingStepsData = stepData;
					return 'pending';
				}
				
				console.log('[WorldBuilder] Received step definitions:', stepData.steps.length, 'steps');
				
				// Reactive assignment - use Object.assign or direct assignment with nextTick
				if (stepData && stepData.steps && Array.isArray(stepData.steps)) {
					// Clear existing steps and assign new ones (triggers reactivity)
					window.worldBuilderInstance.steps = [];
					window.worldBuilderInstance.steps = stepData.steps;
					
					// Force Alpine to update by triggering a reactive change
					if (window.worldBuilderInstance.$nextTick) {
						window.worldBuilderInstance.$nextTick(() => {
							console.log('[WorldBuilder] Steps updated via $nextTick:', window.worldBuilderInstance.steps.length);
							window.worldBuilderInstance._initializeParams();
						});
					} else {
						// Fallback: direct call
						window.worldBuilderInstance._initializeParams();
						console.log('[WorldBuilder] Steps updated (no $nextTick):', window.worldBuilderInstance.steps.length);
					}
					
					return true;
				} else {
					console.error('[WorldBuilder] Invalid step data structure');
					return false;
				}
			} catch (e) {
				console.error('[WorldBuilder] Error setting steps:', e);
				return false;
			}
		})();
	""" % json_string
```

---

## Recommendations

### Immediate Fixes (Priority 1)

1. **Fix Alpine.js Component Registration Timing**
   - **Option A:** Remove `defer` from `world_builder.js` script tag, load it before Alpine.js
   - **Option B:** Register component synchronously before Alpine.js initializes
   - **Option C:** Use `Alpine.data()` registration before Alpine.js scans the DOM

2. **Ensure Steps Array is Populated**
   - **Option A:** Initialize `steps` with placeholder data, then update when real data arrives
   - **Option B:** Use Alpine.js `x-init` to check for `_pendingStepsData` after component initialization
   - **Option C:** Use a watcher or reactive property to detect when steps are set

3. **Force Alpine.js Reactivity**
   - **Option A:** Use `Alpine.reactive()` or `Alpine.store()` for steps array
   - **Option B:** Use `Alpine.$data()` to access component data and trigger reactivity
   - **Option C:** Manually trigger Alpine.js update after setting steps

### Testing Steps (Priority 2)

1. **Add Console Logging**
   - Add `console.log` statements at key points to track execution flow
   - Log when component is registered, when `init()` runs, when steps are set

2. **Runtime DOM Inspection**
   - Use `webview.execute_js()` to query DOM: `document.querySelector('.left-tabs-panel')`
   - Check if buttons exist: `document.querySelectorAll('.left-tab-button').length`
   - Check Alpine state: `window.worldBuilderInstance?.steps?.length`

3. **Verify IPC Communication**
   - Confirm `alpine_ready` message is received by Godot
   - Confirm step definitions are sent from Godot
   - Confirm data reaches JavaScript

### Long-term Improvements (Priority 3)

1. **Refactor to Use Alpine.js Store**
   - Move steps array to `Alpine.store()` for global reactive state
   - Eliminates timing issues with component initialization

2. **Use Alpine.js Plugins**
   - Create a plugin that handles Godot IPC communication
   - Ensures data is available before components initialize

3. **Implement Loading States**
   - Show loading indicator while steps are being fetched
   - Prevents confusion when sidebar is empty

---

## Conclusion

The root cause of the empty sidebar is a **combination of timing issues**:

1. **Primary:** Alpine.js component registration race condition (component referenced before registration)
2. **Secondary:** Steps array not populated due to timing (data sent before instance exists or after init runs)
3. **Tertiary:** Alpine.js reactivity not triggered (direct assignment might not trigger re-render)

The fix requires addressing the component registration timing first, then ensuring steps are populated correctly, and finally ensuring Alpine.js reactivity is triggered.

**Next Steps:**
1. Fix component registration timing (remove `defer` or register synchronously)
2. Add fallback logic to check for `_pendingStepsData` after component initialization
3. Use Alpine.js reactive methods to ensure re-rendering when steps are set
4. Test with console logging to verify the fix works

---

**Report Generated:** 2025-12-28  
**Investigator:** AI Assistant (Cursor)  
**Status:** Investigation Complete - Awaiting Implementation

