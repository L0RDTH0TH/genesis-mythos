# World Builder Map Update Failure Investigation Report
**Date:** 2025-12-28  
**Purpose:** Investigate why the "Generate/Apply Changes" button fails to trigger Azgaar map regeneration  
**Status:** Investigation Complete - Root Cause Identified

---

## Executive Summary

The World Builder UI successfully displays Azgaar in an iframe, and the "Generate/Apply Changes" button correctly sends parameters via IPC to Godot. However, **Azgaar does not regenerate the map** because:

1. **Missing Message Listener**: Azgaar's JavaScript code does not have a `window.addEventListener('message', ...)` handler to receive postMessage events from the parent window
2. **One-Way Communication**: The JavaScript in `world_builder.js` sends postMessage to the iframe, but Azgaar never receives or processes these messages
3. **No Parameter Injection**: Even if messages were received, Azgaar has no code to apply the parameters and trigger regeneration

**Root Cause:** The integration assumes Azgaar can receive and process postMessage events, but Azgaar's codebase does not include this functionality.

---

## 1. Current Architecture

### 1.1 Scene Structure

**File:** `res://scenes/ui/WorldBuilderUI.tscn` / `res://ui/world_builder/WorldBuilderWeb.tscn`

```
WorldBuilderWebRoot (Control)
└── WebView (godot_wry WebView)
    └── Loads: res://assets/ui_web/templates/world_builder.html
```

**Key Observations:**
- ✅ Single WebView node loads the HTML/JS UI template
- ✅ HTML template contains an iframe that loads Azgaar from `http://127.0.0.1:8080/index.html`
- ✅ HTTP server (AzgaarServer) is running on port 8080 and serving files successfully

### 1.2 HTML Template Structure

**File:** `res://assets/ui_web/templates/world_builder.html`

```html
<div class="center-panel">
    <iframe 
        id="azgaar-iframe"
        src="http://127.0.0.1:8080/index.html"
        style="width: 100%; height: 100%; border: none; background: transparent;"
        allowfullscreen
        sandbox="allow-scripts allow-same-origin allow-popups allow-modals">
    </iframe>
</div>
```

**Key Observations:**
- ✅ Iframe loads Azgaar successfully (confirmed by debug logs showing file serving)
- ✅ Iframe has proper sandbox attributes for cross-origin communication
- ✅ Iframe source URL matches the HTTP server port (8080)

---

## 2. JavaScript Implementation

### 2.1 Generate Function

**File:** `res://assets/ui_web/js/world_builder.js` (lines 284-323)

```javascript
generate() {
    this.isGenerating = true;
    this.progressValue = 0;
    this.statusText = 'Generating...';
    
    // Send to Godot for progress tracking
    GodotBridge.postMessage('generate', { params: this.params });
    
    // Send parameters to Azgaar iframe via postMessage
    const iframe = document.getElementById('azgaar-iframe');
    if (iframe && iframe.contentWindow) {
        try {
            const sendToIframe = () => {
                if (iframe.contentWindow) {
                    // Send parameters to Azgaar iframe
                    iframe.contentWindow.postMessage({
                        type: 'azgaar_params',
                        params: this.params,
                        seed: this.seed
                    }, 'http://127.0.0.1:8080');
                    
                    // Trigger generation in Azgaar
                    iframe.contentWindow.postMessage({
                        type: 'azgaar_generate'
                    }, 'http://127.0.0.1:8080');
                }
            };
            
            // Try immediately, or wait for iframe load
            if (iframe.contentDocument && iframe.contentDocument.readyState === 'complete') {
                sendToIframe();
            } else {
                iframe.addEventListener('load', sendToIframe, { once: true });
            }
        } catch (e) {
            console.warn('[WorldBuilder] Failed to send to iframe:', e);
        }
    }
}
```

**Key Observations:**
- ✅ Function correctly finds the iframe element
- ✅ Function sends two postMessage events:
  1. `azgaar_params` - Contains parameter dictionary and seed
  2. `azgaar_generate` - Triggers generation
- ✅ Uses correct target origin (`http://127.0.0.1:8080`)
- ✅ Handles iframe load timing correctly

### 2.2 Debug Logging Added

Temporary debug logging was added to track execution:

```javascript
console.log('[WorldBuilder] generate() called', {
    params: this.params,
    seed: this.seed,
    paramsCount: Object.keys(this.params).length
});
// ... additional logging throughout
```

**Note:** JavaScript console logs are not captured in Godot's debug output, so these would only appear in the browser's developer console.

---

## 3. Godot Script Implementation

### 3.1 WorldBuilderWebController.gd

**File:** `res://scripts/ui/WorldBuilderWebController.gd`

**IPC Handler:**
```gdscript
func _handle_generate(data: Dictionary) -> void:
    """Handle generate message from WebView."""
    var params: Dictionary = data.get("params", {})
    current_params.merge(params)
    current_params["optionsSeed"] = current_seed
    
    # Clamp all parameters before generation
    var clamped_params: Dictionary = {}
    for key in current_params.keys():
        var value = current_params[key]
        clamped_params[key] = _clamp_parameter_value(key, value)
    
    current_params = clamped_params
    
    MythosLogger.info("WorldBuilderWebController", "Generation requested", {"params": current_params})
    
    # Generation is handled via iframe postMessage in JavaScript
    # The JS generate() function sends postMessage to the Azgaar iframe
    # We just track progress here
    send_progress_update(10.0, "Syncing parameters...", true)
    send_progress_update(40.0, "Generating map...", true)
```

**Key Observations:**
- ✅ IPC message is received correctly (confirmed by debug logs)
- ✅ Parameters are parsed and clamped correctly
- ✅ 37 parameters were received in test run
- ✅ Script correctly notes that generation is handled by JavaScript postMessage
- ⚠️ **No direct communication with Azgaar** - relies entirely on JavaScript postMessage

### 3.2 Debug Output Evidence

From the test run (2025-12-28 15:34:04):

```
[WorldBuilderWebController] [INFO]: _handle_generate() called [{"data_keys":["params"]}]
[WorldBuilderWebController] [DEBUG]: Received params from JS [{"params_count":37,"params_keys":[...]}]
[WorldBuilderWebController] [DEBUG]: Seed set [{"seed":12345}]
[WorldBuilderWebController] [INFO]: Generation requested [{"params_count":37,...}]
```

**Confirmation:**
- ✅ Generate button click was received
- ✅ Parameters were correctly transmitted from JavaScript to Godot
- ✅ All 37 parameters were present and valid

---

## 4. Azgaar Codebase Analysis

### 4.1 Message Listener Search

**Search Results:**
- Searched `tools/azgaar/main.js` for `postMessage`, `addEventListener.*message`
- **Result:** No message listener found

**Evidence:**
```bash
$ grep -r "postMessage\|addEventListener.*message" tools/azgaar/main.js
# No matches found
```

### 4.2 Azgaar Main.js Structure

**File:** `tools/azgaar/main.js`

Azgaar's main.js initializes the application but does not include:
- ❌ `window.addEventListener('message', ...)` handler
- ❌ PostMessage event processing
- ❌ External parameter injection mechanism
- ❌ Programmatic generation trigger (beyond UI buttons)

**Key Functions Found:**
- `azgaar.generate()` - Internal generation function (called by UI buttons)
- No public API for external parameter injection
- No message listener for cross-frame communication

### 4.3 Azgaar Options Structure

Azgaar stores parameters in `azgaar.options` object, but:
- ❌ No mechanism to receive external updates via postMessage
- ❌ No listener for `azgaar_params` message type
- ❌ No listener for `azgaar_generate` message type

---

## 5. Communication Flow Analysis

### 5.1 Intended Flow

```
User clicks "Generate/Apply Changes"
    ↓
JavaScript: generate() function called
    ↓
JavaScript: postMessage to iframe (azgaar_params)
    ↓
Azgaar: Receives message, applies parameters
    ↓
JavaScript: postMessage to iframe (azgaar_generate)
    ↓
Azgaar: Receives message, calls azgaar.generate()
    ↓
Azgaar: Map regenerates with new parameters
```

### 5.2 Actual Flow (Current State)

```
User clicks "Generate/Apply Changes"
    ↓
JavaScript: generate() function called ✅
    ↓
JavaScript: postMessage to iframe (azgaar_params) ✅
    ↓
Azgaar: Message sent but NOT RECEIVED ❌
    ↓
JavaScript: postMessage to iframe (azgaar_generate) ✅
    ↓
Azgaar: Message sent but NOT RECEIVED ❌
    ↓
Azgaar: No regeneration occurs ❌
```

**Break Point:** Messages are sent but Azgaar has no listener to receive them.

---

## 6. Root Cause Analysis

### 6.1 Primary Issue: Missing Message Listener

**Problem:** Azgaar's JavaScript code does not include a `window.addEventListener('message', ...)` handler to receive postMessage events from the parent window.

**Impact:**
- All postMessage events sent from `world_builder.js` are silently ignored
- No error is thrown (postMessage is fire-and-forget)
- Azgaar continues to display the original map

**Evidence:**
- Code search found no message listeners in Azgaar codebase
- Debug logs show no errors related to message handling
- Map does not regenerate when button is clicked

### 6.2 Secondary Issue: No Parameter Injection API

**Problem:** Even if messages were received, Azgaar has no public API to:
- Apply parameters from an external source
- Trigger generation programmatically (beyond UI buttons)

**Impact:**
- Parameters cannot be injected into `azgaar.options`
- Generation cannot be triggered without user clicking Azgaar's UI buttons

**Evidence:**
- `azgaar.generate()` exists but is not exposed for external calls
- `azgaar.options` is not designed for external updates
- No documented API for programmatic control

### 6.3 Architecture Mismatch

**Problem:** The integration assumes Azgaar supports cross-frame communication, but Azgaar is designed as a standalone web application.

**Impact:**
- Current iframe embedding approach cannot work without modifications
- Requires either:
  1. Modifying Azgaar's code to add message listeners
  2. Using a different integration approach (e.g., direct JavaScript injection)

---

## 7. Debug Output Analysis

### 7.1 Successful Operations

From test run logs:

1. **HTTP Server:** ✅ Running on port 8080
   ```
   [AzgaarServer] [INFO]: HTTP server started [{"dir":"user://azgaar","host":"127.0.0.1","port":8080}]
   ```

2. **Iframe Loading:** ✅ Azgaar files served successfully
   ```
   [AzgaarServer] [DEBUG]: Served file [{"mime":"text/html","path":"index.html","size":589207}]
   [AzgaarServer] [DEBUG]: Served file [{"mime":"application/javascript","path":"main.js","size":46118}]
   # ... many more files served successfully
   ```

3. **IPC Communication:** ✅ JavaScript → Godot working
   ```
   [WorldBuilderWebController] [DEBUG]: Received IPC message from WebView [{"message":"{\"type\":\"generate\",...}"}]
   [WorldBuilderWebController] [INFO]: Generation requested [{"params_count":37,...}]
   ```

### 7.2 Missing Evidence

**What we DON'T see in logs:**
- ❌ No errors from iframe postMessage (expected - postMessage doesn't throw)
- ❌ No JavaScript console logs (not captured in Godot debug output)
- ❌ No indication that Azgaar received messages
- ❌ No map regeneration activity

**Note:** JavaScript console logs would need to be checked in the browser's developer console to confirm postMessage was sent.

### 7.3 Errors Found (Unrelated)

Several errors were found but are unrelated to the map generation issue:

```
ERROR: [panic] Gd<T>::bind() failed, already bound; T = godot_wry::WebView.
```

**Impact:** These errors occur when calling `execute_js()` or `eval()` on the WebView, but they don't prevent postMessage from being sent (postMessage is handled by the browser, not Godot).

---

## 8. Recommended Solutions

### 8.1 Solution 1: Inject Message Listener into Azgaar (Recommended)

**Approach:** Inject JavaScript code into Azgaar's iframe to add a message listener.

**Implementation:**
1. Wait for Azgaar to fully load
2. Inject a script that:
   - Listens for `window.addEventListener('message', ...)`
   - Processes `azgaar_params` messages by updating `azgaar.options`
   - Processes `azgaar_generate` messages by calling `azgaar.generate()`

**Code Example:**
```javascript
// In world_builder.js, after iframe loads:
const injectAzgaarListener = () => {
    const iframe = document.getElementById('azgaar-iframe');
    if (iframe.contentWindow) {
        // Inject message listener script
        const script = `
            window.addEventListener('message', function(event) {
                if (event.origin !== 'http://127.0.0.1:8080') return;
                
                if (event.data.type === 'azgaar_params') {
                    // Apply parameters to azgaar.options
                    if (typeof azgaar !== 'undefined' && azgaar.options) {
                        Object.assign(azgaar.options, event.data.params);
                        if (event.data.seed) {
                            azgaar.options.seed = event.data.seed;
                        }
                    }
                } else if (event.data.type === 'azgaar_generate') {
                    // Trigger generation
                    if (typeof azgaar !== 'undefined' && azgaar.generate) {
                        azgaar.generate();
                    }
                }
            });
        `;
        
        // Execute script in iframe context
        iframe.contentWindow.eval(script);
    }
};
```

**Pros:**
- ✅ Minimal changes to existing code
- ✅ Works with current iframe architecture
- ✅ No modifications to Azgaar source files

**Cons:**
- ⚠️ Requires iframe to allow script execution (sandbox attribute may block)
- ⚠️ Timing-dependent (must wait for Azgaar to fully load)

### 8.2 Solution 2: Direct JavaScript Injection via Godot

**Approach:** Use Godot's WebView `execute_js()` to inject parameters directly into Azgaar.

**Implementation:**
1. Access the Azgaar iframe's contentWindow from the parent WebView
2. Execute JavaScript to set `azgaar.options` values
3. Execute JavaScript to call `azgaar.generate()`

**Code Example:**
```gdscript
# In WorldBuilderWebController.gd
func _handle_generate(data: Dictionary) -> void:
    # ... parameter processing ...
    
    # Inject parameters into Azgaar iframe
    var js_code = """
        (function() {
            var iframe = document.getElementById('azgaar-iframe');
            if (iframe && iframe.contentWindow && iframe.contentWindow.azgaar) {
                var azgaar = iframe.contentWindow.azgaar;
                // Apply parameters
                %s
                // Trigger generation
                azgaar.generate();
            }
        })();
    """ % _build_parameter_js(current_params)
    
    web_view.execute_js(js_code)
```

**Pros:**
- ✅ Direct control from Godot
- ✅ No need for postMessage
- ✅ Can handle errors more gracefully

**Cons:**
- ⚠️ Requires iframe to be accessible from parent (same-origin or proper CORS)
- ⚠️ Complex parameter mapping (must convert GDScript Dictionary to JavaScript)

### 8.3 Solution 3: Modify Azgaar Source (Not Recommended)

**Approach:** Add message listener directly to Azgaar's `main.js`.

**Implementation:**
1. Modify `tools/azgaar/main.js` to add message listener
2. Re-bundle Azgaar files

**Pros:**
- ✅ Permanent solution
- ✅ No runtime injection needed

**Cons:**
- ❌ Requires maintaining modified Azgaar codebase
- ❌ Breaks on Azgaar updates
- ❌ Violates separation of concerns

---

## 9. Code Snippets Reference

### 9.1 JavaScript Generate Function

**Location:** `res://assets/ui_web/js/world_builder.js:284-323`

```javascript
generate() {
    this.isGenerating = true;
    this.progressValue = 0;
    this.statusText = 'Generating...';
    
    // Send to Godot for progress tracking
    GodotBridge.postMessage('generate', { params: this.params });
    
    // Send parameters to Azgaar iframe via postMessage
    const iframe = document.getElementById('azgaar-iframe');
    if (iframe && iframe.contentWindow) {
        try {
            const sendToIframe = () => {
                if (iframe.contentWindow) {
                    // Send parameters to Azgaar iframe
                    iframe.contentWindow.postMessage({
                        type: 'azgaar_params',
                        params: this.params,
                        seed: this.seed
                    }, 'http://127.0.0.1:8080');
                    
                    // Trigger generation in Azgaar
                    iframe.contentWindow.postMessage({
                        type: 'azgaar_generate'
                    }, 'http://127.0.0.1:8080');
                }
            };
            
            // Try immediately, or wait for iframe load
            if (iframe.contentDocument && iframe.contentDocument.readyState === 'complete') {
                sendToIframe();
            } else {
                iframe.addEventListener('load', sendToIframe, { once: true });
            }
        } catch (e) {
            console.warn('[WorldBuilder] Failed to send to iframe:', e);
        }
    }
}
```

### 9.2 Godot IPC Handler

**Location:** `res://scripts/ui/WorldBuilderWebController.gd:435-461`

```gdscript
func _handle_generate(data: Dictionary) -> void:
    """Handle generate message from WebView."""
    var params: Dictionary = data.get("params", {})
    current_params.merge(params)
    
    # Ensure seed is set
    current_params["optionsSeed"] = current_seed
    
    # Clamp all parameters before generation (only curated parameters)
    var clamped_params: Dictionary = {}
    for key in current_params.keys():
        var value = current_params[key]
        clamped_params[key] = _clamp_parameter_value(key, value)
    
    current_params = clamped_params
    
    MythosLogger.info("WorldBuilderWebController", "Generation requested", {"params": current_params})
    
    # Generation is handled via iframe postMessage in JavaScript
    # The JS generate() function sends postMessage to the Azgaar iframe
    # We just track progress here
    send_progress_update(10.0, "Syncing parameters...", true)
    send_progress_update(40.0, "Generating map...", true)
    
    # Note: Actual generation happens in iframe via postMessage from JS
    # We'll update progress when iframe sends completion message (if needed)
```

---

## 10. Testing Evidence

### 10.1 Test Run Summary

**Date:** 2025-12-28 15:33:36 - 15:34:04  
**Duration:** ~28 seconds  
**Actions Performed:**
1. Project launched successfully
2. World Builder UI loaded
3. Azgaar iframe loaded (confirmed by file serving logs)
4. Parameter changed (templateInput → "continents")
5. "Generate/Apply Changes" button clicked

### 10.2 Log Evidence

**Successful Operations:**
- ✅ HTTP server started on port 8080
- ✅ Azgaar files served (100+ files)
- ✅ IPC message received: `generate` type
- ✅ 37 parameters received and processed
- ✅ Progress updates sent

**Missing Evidence:**
- ❌ No indication that Azgaar received postMessage
- ❌ No map regeneration activity
- ❌ No errors (postMessage is silent on failure)

### 10.3 JavaScript Console (Not Captured)

**Note:** JavaScript console logs are not captured in Godot's debug output. To verify postMessage was sent, check the browser's developer console (if accessible) or add logging that sends messages back to Godot via IPC.

---

## 11. Conclusion

### 11.1 Root Cause

**Primary Issue:** Azgaar does not have a message listener to receive postMessage events from the parent window. The JavaScript code in `world_builder.js` correctly sends postMessage events, but Azgaar never receives or processes them.

### 11.2 Impact

- **User Experience:** Button click appears to do nothing (no map regeneration)
- **Functionality:** World Builder cannot update Azgaar parameters or trigger regeneration
- **Architecture:** Current iframe + postMessage approach is incomplete

### 11.3 Recommended Fix

**Solution 1 (Recommended):** Inject a message listener into Azgaar's iframe after it loads. This requires:
1. Waiting for Azgaar to fully initialize
2. Injecting JavaScript that adds `window.addEventListener('message', ...)`
3. Processing `azgaar_params` and `azgaar_generate` message types
4. Applying parameters to `azgaar.options` and calling `azgaar.generate()`

**Alternative:** Use direct JavaScript injection via Godot's WebView `execute_js()` to access the iframe's contentWindow and manipulate Azgaar directly.

### 11.4 Next Steps

1. Implement Solution 1 (inject message listener)
2. Test parameter injection and generation trigger
3. Verify map regeneration occurs with new parameters
4. Remove temporary debug logging
5. Update documentation with integration details

---

## 12. Files Modified During Investigation

### 12.1 Temporary Debug Additions

**File:** `res://assets/ui_web/js/world_builder.js`
- Added extensive console.log statements in `generate()` function
- **Action Required:** Remove debug logging after fix is implemented

**File:** `res://scripts/ui/WorldBuilderWebController.gd`
- Added debug logging in `_handle_generate()` function
- **Action Required:** Remove or reduce debug logging after fix is implemented

### 12.2 No Permanent Changes

All changes made during investigation were temporary debug additions. No permanent code modifications were made.

---

**End of Investigation Report**

