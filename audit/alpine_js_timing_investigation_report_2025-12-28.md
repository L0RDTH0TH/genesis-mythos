# Alpine.js Timing Issue Investigation Report
**Date:** 2025-12-28  
**Purpose:** Investigate Alpine.js initialization timing failures in World Builder UI  
**Status:** Investigation Complete - No Code Changes Made

---

## Executive Summary

The World Builder UI uses Alpine.js for reactive data binding, but the current polling mechanism (`_wait_for_alpine_ready()`) is timing out after 20 attempts (2 seconds total). The investigation reveals a **race condition** between Alpine.js initialization and the GDScript polling mechanism, compounded by WebView load timing and script execution order.

**Key Finding:** The polling checks for `window.worldBuilderInstance.steps !== undefined`, but `worldBuilderInstance` may not be set until Alpine.js fully initializes the `worldBuilder` data component, which can occur after the polling window expires.

---

## 1. Current Polling Mechanism

### 1.1 Implementation Details

**Location:** `res://scripts/ui/WorldBuilderWebController.gd:140-171`

```140:171:scripts/ui/WorldBuilderWebController.gd
func _wait_for_alpine_ready() -> void:
	"""Poll until Alpine.js worldBuilder instance is ready."""
	if not web_view:
		return
	
	var max_attempts: int = 20  # 2 seconds total (20 * 0.1s)
	var attempt: int = 0
	
	while attempt < max_attempts:
		var check_script: String = """
			(function() {
				if (window.worldBuilderInstance && window.worldBuilderInstance.steps !== undefined) {
					return true;
				}
				return false;
			})();
		"""
		
		var result = null
		if web_view.has_method("execute_js"):
			result = web_view.execute_js(check_script)
		elif web_view.has_method("eval"):
			web_view.eval(check_script)
		
		if result == true:
			MythosLogger.info("WorldBuilderWebController", "Alpine.js ready", {"attempts": attempt + 1})
			return
		
		attempt += 1
		await get_tree().create_timer(0.1).timeout
	
	MythosLogger.warn("WorldBuilderWebController", "Alpine.js not ready after %d attempts, proceeding anyway" % max_attempts)
```

**Polling Parameters:**
- **Max Attempts:** 20
- **Delay Between Attempts:** 0.1 seconds
- **Total Timeout:** 2.0 seconds (20 × 0.1s)
- **Check Condition:** `window.worldBuilderInstance && window.worldBuilderInstance.steps !== undefined`

### 1.2 Initialization Sequence

**Location:** `res://scripts/ui/WorldBuilderWebController.gd:42-73`

```42:73:scripts/ui/WorldBuilderWebController.gd
func _ready() -> void:
	"""Initialize the WebView and load the World Builder HTML."""
	MythosLogger.info("WorldBuilderWebController", "_ready() called")
	
	if not web_view:
		MythosLogger.error("WorldBuilderWebController", "WebView node not found!")
		return
	
	# Load step definitions from JSON
	_load_step_definitions()
	
	# Load the World Builder HTML file
	var html_url: String = "res://web_ui/world_builder/index.html"
	web_view.load_url(html_url)
	MythosLogger.info("WorldBuilderWebController", "Loaded World Builder HTML", {"url": html_url})
	
	# Connect IPC message signal for bidirectional communication
	if web_view.has_signal("ipc_message"):
		web_view.ipc_message.connect(_on_ipc_message)
		MythosLogger.info("WorldBuilderWebController", "Connected to WebView IPC message signal")
	else:
		MythosLogger.warn("WorldBuilderWebController", "WebView does not have ipc_message signal")
	
	# Try to find WorldBuilderAzgaar in scene tree (for generation)
	_find_azgaar_controller()
	
	# Wait for page to load, then inject data with polling to ensure Alpine.js is ready
	await get_tree().create_timer(1.5).timeout
	_inject_theme_and_constants()
	await _wait_for_alpine_ready()
	_send_step_definitions()
	_send_archetypes()
```

**Timeline:**
1. `_ready()` called → WebView loads HTML
2. **Fixed 1.5 second delay** (`await get_tree().create_timer(1.5).timeout`)
3. `_inject_theme_and_constants()` executes JS
4. `_wait_for_alpine_ready()` starts polling (20 attempts, 0.1s each = 2.0s total)
5. If successful, `_send_step_definitions()` and `_send_archetypes()` execute

**Total Time from `_ready()` to Step Definitions Sent:** ~3.5 seconds minimum (1.5s delay + 2.0s polling)

---

## 2. Alpine.js Initialization Analysis

### 2.1 HTML Script Loading Order

**Location:** `res://web_ui/world_builder/index.html:151-153`

```151:153:web_ui/world_builder/index.html
    <script src="../shared/bridge.js"></script>
    <script src="../shared/alpine.min.js" defer></script>
    <script src="world_builder.js"></script>
```

**Script Execution Order:**
1. **`bridge.js`** - Executes immediately (synchronous, ~5ms)
2. **`alpine.min.js`** - Executes with `defer` attribute (after DOM parsing, ~30-85ms)
3. **`world_builder.js`** - Executes immediately (synchronous, ~5-10ms)

**Critical Issue:** `world_builder.js` executes **before** Alpine.js is ready because:
- `alpine.min.js` has `defer` attribute → executes after DOM parsing
- `world_builder.js` has no `defer` → executes immediately
- `Alpine.data('worldBuilder', ...)` in `world_builder.js` may fail if Alpine not initialized

### 2.2 Alpine.js Data Component Initialization

**Location:** `res://web_ui/world_builder/world_builder.js:44-91`

```44:91:web_ui/world_builder/world_builder.js
// Alpine.js data component
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

**Key Points:**
- `Alpine.data('worldBuilder', ...)` registers the component **when Alpine.js is ready**
- `init()` is called by Alpine.js **after** the component is bound to the DOM element
- `window.worldBuilderInstance = this` is set **inside** `init()`, which only runs after Alpine.js initializes
- The polling checks for `window.worldBuilderInstance`, which may not exist until `init()` runs

### 2.3 Alpine.js Initialization Timing

**From Audit Report** (`lag_investigation_create_world_button_2025-12-27.md`):

> **Alpine.js 3.15.3 (48KB minified):**
> 
> **Initialization Process:**
> 1. **Script Load:** `defer` attribute delays execution until DOM is parsed
> 2. **Alpine.start():** Auto-called via `queueMicrotask(() => { Vt.start() })`
> 3. **DOM Scan:** Alpine scans entire DOM for `x-data`, `x-for`, `x-if`, etc.
> 4. **Reactivity Setup:** Creates reactive proxies for all data objects
> 5. **MutationObserver:** Sets up observer for DOM changes
> 
> **Performance Impact:**
> - **DOM Scan:** For WorldBuilder HTML with ~100+ Alpine directives:
>   - Initial scan: **20-50ms** (synchronous, blocks main thread)
>   - Reactive proxy creation: **10-30ms**
>   - MutationObserver setup: **<5ms**
>   - **Total: 30-85ms** (synchronous, blocks main thread)

**Critical Issue:** Alpine.js initialization happens **synchronously** in the WebView's JavaScript thread, which may block godot_wry's IPC communication if WebView is not fully initialized.

---

## 3. Potential Causes of Timeout

### 3.1 Race Condition: Script Execution Order

**Issue:** `world_builder.js` executes before Alpine.js is ready.

**Evidence:**
- `alpine.min.js` has `defer` → executes after DOM parsing
- `world_builder.js` has no `defer` → executes immediately
- `Alpine.data('worldBuilder', ...)` may fail silently if Alpine not initialized

**Impact:** If `Alpine.data()` fails, `window.worldBuilderInstance` is never set, causing polling to timeout.

**Likelihood:** **HIGH** - This is the most likely cause based on script loading order.

### 3.2 WebView Load Delays

**Issue:** WebView may not be fully initialized when `load_url()` is called.

**Evidence:**
- Fixed 1.5 second delay before polling starts
- WebView initialization in godot_wry may take longer on slower systems
- HTML parsing and script execution may be delayed

**Impact:** If WebView is still loading, JavaScript execution (`execute_js()`) may fail or return null, causing polling to fail.

**Likelihood:** **MEDIUM** - Fixed delay should cover most cases, but edge cases exist.

### 3.3 Alpine.js Defer Timing

**Issue:** `defer` attribute delays Alpine.js execution until DOM is parsed, but timing is unpredictable.

**Evidence:**
- `defer` scripts execute after DOM parsing but before `DOMContentLoaded`
- WebView may have different timing than standard browsers
- godot_wry's WebView engine (Wry) may have different defer behavior

**Impact:** Alpine.js may initialize later than expected, causing `window.worldBuilderInstance` to be set after polling expires.

**Likelihood:** **MEDIUM** - Defer timing is generally predictable, but WebView engines can vary.

### 3.4 JavaScript Execution Context Not Ready

**Issue:** `execute_js()` may fail if WebView's JavaScript context is not ready.

**Evidence:**
- `execute_js()` returns `null` if execution fails
- Polling checks `result == true`, which fails if `result` is `null`
- No error handling for failed JavaScript execution

**Impact:** If `execute_js()` fails silently, polling will always timeout even if Alpine.js is ready.

**Likelihood:** **LOW** - `execute_js()` should work after WebView loads, but edge cases exist.

### 3.5 Alpine.js Component Binding Delay

**Issue:** Even if Alpine.js is loaded, the `worldBuilder` component may not be bound to the DOM element yet.

**Evidence:**
- `init()` is called by Alpine.js **after** component binding
- `window.worldBuilderInstance = this` is set inside `init()`
- Polling checks for `worldBuilderInstance`, which may not exist until `init()` runs

**Impact:** Alpine.js may be ready, but `worldBuilderInstance` is not set until `init()` runs, causing polling to timeout.

**Likelihood:** **HIGH** - This is a critical timing issue: Alpine.js ready ≠ `worldBuilderInstance` ready.

---

## 4. Code Analysis: Step Definitions Injection

### 4.1 Step Definitions Injection After Polling

**Location:** `res://scripts/ui/WorldBuilderWebController.gd:174-234`

```174:234:scripts/ui/WorldBuilderWebController.gd
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
	var script: String = """
		(function() {
			try {
				if (!window.worldBuilderInstance) {
					console.error('[WorldBuilder] worldBuilderInstance not found!');
					return false;
				}
				
				var stepData = %s;
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
		MythosLogger.info("WorldBuilderWebController", "Sent step definitions to WebView", {"result": result})
	elif web_view.has_method("eval"):
		web_view.eval(script)
		MythosLogger.info("WorldBuilderWebController", "Sent step definitions to WebView via eval")
```

**Key Observations:**
- `_send_step_definitions()` is called **after** `_wait_for_alpine_ready()` completes
- It checks for `window.worldBuilderInstance` and logs an error if not found
- If polling times out, `worldBuilderInstance` may not exist, causing injection to fail

**Fallback Mechanism:**
- `world_builder.js` has a fallback that requests step definitions via `GodotBridge.requestData()` if direct injection fails
- This fallback only works if `worldBuilderInstance` exists (set in `init()`)

---

## 5. Recommendations

### 5.1 Increase Polling Attempts and Delay

**Current:** 20 attempts × 0.1s = 2.0 seconds  
**Recommended:** 50 attempts × 0.1s = 5.0 seconds

**Rationale:**
- Alpine.js initialization can take 30-85ms, but WebView load delays can add 1-3 seconds
- Component binding and `init()` execution may occur after Alpine.js is "ready"
- More attempts provide buffer for slower systems

**Trade-off:** Longer initialization time, but more reliable.

### 5.2 Use IPC Signal Instead of Polling

**Current:** Polling with `execute_js()` checks  
**Recommended:** Use `ipc_message` signal from WebView when Alpine.js is ready

**Implementation:**
1. Add `window.GodotBridge.notifyAlpineReady()` in `world_builder.js` `init()`
2. Send IPC message to Godot when Alpine.js is ready
3. Remove polling, wait for IPC signal instead

**Benefits:**
- Event-driven instead of polling (more efficient)
- Guaranteed timing (signals when actually ready)
- No timeout issues

**Trade-off:** Requires IPC signal handling, but eliminates race conditions.

### 5.3 Fix Script Loading Order

**Current:** `alpine.min.js` (defer) + `world_builder.js` (immediate)  
**Recommended:** Both scripts with `defer`, or `world_builder.js` after Alpine.js

**Implementation:**
```html
<script src="../shared/bridge.js"></script>
<script src="../shared/alpine.min.js" defer></script>
<script src="world_builder.js" defer></script>
```

**Or:**
```html
<script src="../shared/bridge.js"></script>
<script src="../shared/alpine.min.js"></script>
<script src="world_builder.js"></script>
```

**Benefits:**
- Ensures Alpine.js is ready before `world_builder.js` executes
- Prevents `Alpine.data()` from failing

**Trade-off:** May delay UI initialization slightly, but more reliable.

### 5.4 Add Pending Data Storage

**Current:** Polling checks for `worldBuilderInstance`  
**Recommended:** Store step definitions in `window._pendingStepsData` before Alpine.js is ready

**Implementation:**
- In `_send_step_definitions()`, check if `worldBuilderInstance` exists
- If not, store data in `window._pendingStepsData`
- `world_builder.js` `init()` already checks for `_pendingStepsData` and loads it

**Benefits:**
- Works even if polling times out
- Data is available when Alpine.js initializes

**Trade-off:** Requires data storage mechanism, but provides fallback.

### 5.5 Combine Recommendations

**Best Approach:** Combine recommendations 2, 3, and 4:
1. Fix script loading order (recommendation 3)
2. Use IPC signal for readiness (recommendation 2)
3. Add pending data storage as fallback (recommendation 4)
4. Increase polling attempts as temporary safety net (recommendation 1)

**Priority:**
1. **HIGH:** Fix script loading order (immediate fix)
2. **HIGH:** Use IPC signal (eliminates polling)
3. **MEDIUM:** Add pending data storage (fallback)
4. **LOW:** Increase polling attempts (temporary workaround)

---

## 6. Relevant Code Snippets

### 6.1 Polling Function

```140:171:scripts/ui/WorldBuilderWebController.gd
func _wait_for_alpine_ready() -> void:
	"""Poll until Alpine.js worldBuilder instance is ready."""
	if not web_view:
		return
	
	var max_attempts: int = 20  # 2 seconds total (20 * 0.1s)
	var attempt: int = 0
	
	while attempt < max_attempts:
		var check_script: String = """
			(function() {
				if (window.worldBuilderInstance && window.worldBuilderInstance.steps !== undefined) {
					return true;
				}
				return false;
			})();
		"""
		
		var result = null
		if web_view.has_method("execute_js"):
			result = web_view.execute_js(check_script)
		elif web_view.has_method("eval"):
			web_view.eval(check_script)
		
		if result == true:
			MythosLogger.info("WorldBuilderWebController", "Alpine.js ready", {"attempts": attempt + 1})
			return
		
		attempt += 1
		await get_tree().create_timer(0.1).timeout
	
	MythosLogger.warn("WorldBuilderWebController", "Alpine.js not ready after %d attempts, proceeding anyway" % max_attempts)
```

### 6.2 Alpine.js Component Initialization

```58:91:web_ui/world_builder/world_builder.js
    init() {
        // Store instance for global access
        window.worldBuilderInstance = this;
        console.log('[WorldBuilder] Alpine.js init() called, steps:', this.steps.length);
        
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

### 6.3 HTML Script Loading

```151:153:web_ui/world_builder/index.html
    <script src="../shared/bridge.js"></script>
    <script src="../shared/alpine.min.js" defer></script>
    <script src="world_builder.js"></script>
```

---

## 7. Summary

### 7.1 Root Cause

The timeout occurs due to a **race condition** between:
1. Alpine.js initialization (deferred script)
2. `world_builder.js` execution (immediate script)
3. GDScript polling mechanism (checks for `worldBuilderInstance`)

**Primary Issue:** `world_builder.js` executes before Alpine.js is ready, causing `Alpine.data()` to potentially fail silently. Even if it succeeds, `window.worldBuilderInstance` is only set in `init()`, which runs after Alpine.js binds the component to the DOM.

### 7.2 Contributing Factors

1. **Script Loading Order:** `alpine.min.js` (defer) + `world_builder.js` (immediate) creates race condition
2. **Component Binding Delay:** `init()` runs after Alpine.js binds component, delaying `worldBuilderInstance` assignment
3. **WebView Load Timing:** Fixed 1.5s delay may not be sufficient on slower systems
4. **Polling Timeout:** 2.0 seconds may be insufficient for Alpine.js + component binding

### 7.3 Recommended Fix Priority

1. **IMMEDIATE:** Fix script loading order (add `defer` to `world_builder.js` or ensure Alpine.js loads first)
2. **HIGH:** Replace polling with IPC signal (event-driven, eliminates race condition)
3. **MEDIUM:** Add pending data storage (fallback mechanism)
4. **LOW:** Increase polling attempts (temporary workaround if IPC signal not feasible)

---

## 8. Next Steps

1. **Test Current Behavior:** Run project and capture debug output to confirm timeout frequency
2. **Implement Fix:** Choose recommendation (preferably IPC signal + script order fix)
3. **Test Fix:** Verify Alpine.js initialization succeeds within expected timeframe
4. **Monitor Logs:** Check for "Alpine.js not ready" warnings after fix

---

**Report Generated:** 2025-12-28  
**Investigation Status:** Complete  
**Code Changes:** None (investigation only)

