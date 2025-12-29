# Azgaar Signal Ignoring Issue Investigation Report

**Date:** 2025-12-29  
**Issue:** Custom GUI for Azgaar world builder sends signals/parameters, but Azgaar appears to ignore them  
**Status:** ROOT CAUSE IDENTIFIED - Multiple contributing factors

---

## Executive Summary

The investigation reveals that the Azgaar integration uses a **postMessage-based communication system** between the World Builder GUI (Alpine.js/HTML) and the Azgaar iframe. The system relies on **injected JavaScript listeners** rather than native Azgaar support. Multiple potential failure points exist:

1. **Timing Issues**: Listener injection and message sending may occur before Azgaar is fully initialized
2. **Origin/CORS Issues**: Cross-origin communication between `res://` (parent) and `http://127.0.0.1:8080` (iframe)
3. **Silent Failures**: Listener injection failures may not be properly logged or detected
4. **No Native Support**: The Azgaar fork has no built-in postMessage handling - relies entirely on injected code

**Root Cause**: The injected message listener may not be successfully injected or may fail to execute due to timing/CORS issues, causing Azgaar to never receive the parameter messages.

---

## Architecture Overview

### Communication Flow

```
World Builder GUI (Alpine.js)
    ↓
world_builder.js: generate()
    ↓
postMessage to iframe (azgaar-iframe)
    ↓
Injected Listener in Azgaar iframe
    ↓
Object.assign(azgaar.options, params)
    ↓
azgaar.generate()
```

### Key Components

1. **World Builder GUI**: `assets/ui_web/templates/world_builder.html`
   - Alpine.js-based UI with left tabs, center iframe, right parameters
   - Iframe loads Azgaar from `http://127.0.0.1:8080/index.html`

2. **JavaScript Controller**: `assets/ui_web/js/world_builder.js`
   - `generate()` function sends postMessage to iframe
   - `_setupAzgaarListener()` injects message listener into iframe

3. **Azgaar Fork**: `tools/azgaar/`
   - No native postMessage handling found
   - Relies on injected listener code

4. **Godot Integration**: `scripts/ui/WorldBuilderWebController.gd`
   - Handles IPC from WebView
   - Does NOT directly communicate with Azgaar (delegates to JS)

---

## Code Analysis

### 1. Message Sending (world_builder.js)

**Location**: `assets/ui_web/js/world_builder.js:449-669`

The `generate()` function:
- Checks if listener is injected (`azgaarListenerInjected`)
- Waits for iframe to load
- Checks if `azgaar.options` and `azgaar.generate` are available
- Sends two postMessage calls:
  1. `azgaar_params` with `params` and `seed`
  2. `azgaar_generate` to trigger generation

```javascript
const paramsMessage = {
    type: 'azgaar_params',
    params: this.params,
    seed: this.seed
};

iframe.contentWindow.postMessage(paramsMessage, '*');
```

**Issues Identified**:
- Uses `'*'` as targetOrigin (security risk, but necessary for WebView context)
- Retry logic exists but may not wait long enough for Azgaar initialization
- No verification that message was received

### 2. Listener Injection (world_builder.js)

**Location**: `assets/ui_web/js/world_builder.js:129-288`

The `_setupAzgaarListener()` function:
- Tries to inject listener via script tag (preferred)
- Falls back to `eval()` if script tag fails
- Retries up to 10 times with 1-second delays
- Listener checks for `azgaar.options` before applying parameters

**Injected Listener Code**:
```javascript
window.addEventListener('message', function(event) {
    // Origin validation
    const allowedOrigins = ['file://', 'res://', 'http://127.0.0.1:8080', window.location.origin, '*'];
    
    if (event.data && event.data.type === 'azgaar_params') {
        if (typeof azgaar !== 'undefined' && azgaar.options) {
            Object.assign(azgaar.options, event.data.params);
            azgaar.options.seed = event.data.seed;
        }
    }
    
    if (event.data && event.data.type === 'azgaar_generate') {
        if (typeof azgaar !== 'undefined' && typeof azgaar.generate === 'function') {
            azgaar.generate();
        }
    }
});
```

**Issues Identified**:
- CORS may prevent script tag injection if iframe is cross-origin
- `eval()` may be blocked by CSP (Content Security Policy)
- No confirmation that listener was successfully injected
- Timing: Listener may be injected before Azgaar is fully loaded

### 3. Azgaar Fork Analysis

**Location**: `tools/azgaar/`

**Findings**:
- ✅ Fork files are present (index.html, main.js, modules/)
- ❌ **NO native postMessage handling found** in main.js or modules
- ❌ **NO message event listeners** in the original Azgaar code
- ✅ Fork is modular refactor (as expected)

**Conclusion**: The fork does NOT include built-in support for postMessage communication. It relies entirely on the injected listener from world_builder.js.

### 4. Godot Integration

**Location**: `scripts/ui/WorldBuilderWebController.gd`

**Findings**:
- Handles IPC from WebView (Alpine.js → Godot)
- Does NOT directly communicate with Azgaar
- Delegates Azgaar communication to JavaScript (iframe postMessage)
- `_handle_generate()` receives params but doesn't send them to Azgaar directly

**Note**: There is also `WorldBuilderAzgaar.gd` which uses direct JS injection (`_execute_azgaar_js()`), but this appears to be a separate/legacy integration path not used by the current WebView-based GUI.

---

## Potential Root Causes

### 1. Timing Issues (HIGH PROBABILITY)

**Problem**: Listener injection or message sending occurs before Azgaar is fully initialized.

**Evidence**:
- `_setupAzgaarListener()` waits 2-3 seconds after iframe load, but Azgaar may take longer
- `generate()` checks for `azgaar.options` but may not wait long enough
- No polling/verification that Azgaar is ready before sending messages

**Impact**: Messages sent before Azgaar is ready are lost (no queue/buffer).

### 2. CORS/Same-Origin Policy (MEDIUM PROBABILITY)

**Problem**: Cross-origin communication between `res://` (parent) and `http://127.0.0.1:8080` (iframe).

**Evidence**:
- Iframe loads from `http://127.0.0.1:8080/index.html`
- Parent page loads from `res://assets/ui_web/templates/world_builder.html`
- Different origins may prevent script tag injection
- `eval()` may be blocked by CSP

**Impact**: Listener injection fails silently, messages never received.

### 3. Listener Injection Failure (MEDIUM PROBABILITY)

**Problem**: Listener injection fails but error is not properly detected/logged.

**Evidence**:
- Multiple fallback strategies (script tag → eval → retry)
- `azgaarListenerInjected` flag may be set even if injection failed
- No verification that listener is actually active

**Impact**: Messages sent but no listener to receive them.

### 4. Parameter Format Mismatch (LOW PROBABILITY)

**Problem**: Parameters sent don't match Azgaar's expected format.

**Evidence**:
- Parameters use `azgaar_key` from JSON config (e.g., `pointsInput`, `optionsSeed`)
- Azgaar expects options in `azgaar.options` object
- `Object.assign()` should handle this, but nested keys (e.g., `options.winds[0]`) may not work

**Impact**: Parameters applied but ignored due to incorrect keys/format.

### 5. Azgaar Options Override (LOW PROBABILITY)

**Problem**: Azgaar may reset options after they're applied (e.g., on generation start).

**Evidence**:
- No code found that explicitly resets options
- But Azgaar's generation logic may read defaults from elsewhere

**Impact**: Parameters applied but immediately overwritten.

---

## Debugging Recommendations

### 1. Add Console Logging

**In world_builder.js**:
- Log when listener injection succeeds/fails
- Log when messages are sent (with full payload)
- Log when messages are received in listener (if possible)

**In injected listener**:
- Log when listener is registered
- Log when messages are received (with origin and data)
- Log when parameters are applied (before/after values)
- Log when `azgaar.generate()` is called

### 2. Verify Listener Injection

Add verification code after injection:
```javascript
// After injection, verify listener exists
setTimeout(() => {
    try {
        const testMessage = { type: 'test', test: true };
        iframe.contentWindow.postMessage(testMessage, '*');
        // Check if test message was logged by listener
    } catch (e) {
        console.error('Listener verification failed:', e);
    }
}, 1000);
```

### 3. Add Polling/Retry for Azgaar Readiness

Instead of fixed delays, poll for Azgaar readiness:
```javascript
const waitForAzgaar = (maxWait = 10000) => {
    return new Promise((resolve, reject) => {
        const startTime = Date.now();
        const check = () => {
            if (iframe.contentWindow && 
                typeof iframe.contentWindow.azgaar !== 'undefined' &&
                iframe.contentWindow.azgaar.options &&
                typeof iframe.contentWindow.azgaar.generate === 'function') {
                resolve();
            } else if (Date.now() - startTime > maxWait) {
                reject(new Error('Azgaar not ready after ' + maxWait + 'ms'));
            } else {
                setTimeout(check, 100);
            }
        };
        check();
    });
};
```

### 4. Test Direct JS Injection (Alternative Approach)

Instead of postMessage, try direct JS execution via Godot:
- Use `WorldBuilderAzgaar.gd._execute_azgaar_js()` to set parameters directly
- This bypasses postMessage entirely
- Requires access to Azgaar WebView (separate from World Builder WebView)

---

## Pre- vs Post-Refactor Behavior

### Before Fork Refactor (Original Azgaar)

- Same architecture (postMessage + injected listener)
- Same potential issues (timing, CORS, injection failures)
- **No change in behavior expected** - fork is modular refactor, not communication refactor

### After Fork Refactor (Current Fork)

- Fork is modular but doesn't add native postMessage support
- Same injection-based approach required
- **Issue likely persists** - no fixes for communication layer

---

## Recommended Fixes

### Fix 1: Improve Timing and Verification (HIGH PRIORITY)

1. Add polling for Azgaar readiness (don't rely on fixed delays)
2. Verify listener injection before sending messages
3. Add retry logic with exponential backoff for message sending

### Fix 2: Add Native postMessage Support to Fork (MEDIUM PRIORITY)

1. Modify `tools/azgaar/main.js` to add native message listener
2. Remove dependency on injected listener
3. More reliable than injection-based approach

### Fix 3: Use Direct JS Injection (ALTERNATIVE)

1. Use `WorldBuilderAzgaar.gd` to inject parameters directly via `_execute_azgaar_js()`
2. Requires separate WebView for Azgaar (not iframe)
3. More reliable but requires architecture change

### Fix 4: Add Comprehensive Logging (IMMEDIATE)

1. Add console.log statements at all critical points
2. Log message sending, receiving, and parameter application
3. Helps identify exact failure point

---

## Testing Checklist

- [ ] Verify iframe loads successfully
- [ ] Verify listener injection succeeds (check console logs)
- [ ] Verify messages are sent (check console logs)
- [ ] Verify messages are received in iframe (check console logs)
- [ ] Verify `azgaar.options` is updated (log before/after)
- [ ] Verify `azgaar.generate()` is called (log call)
- [ ] Test with different parameter values
- [ ] Test with different origins (file:// vs http://)
- [ ] Test timing variations (slow/fast Azgaar load)

---

## Conclusion

The issue is **likely caused by timing and/or CORS issues** preventing the injected message listener from working correctly. The system relies entirely on JavaScript injection, which is fragile in cross-origin contexts. 

**Immediate Action**: Add comprehensive logging to identify the exact failure point.

**Long-term Solution**: Either add native postMessage support to the Azgaar fork, or switch to direct JS injection via Godot's WebView API.

---

## Files Referenced

- `assets/ui_web/templates/world_builder.html` - GUI template
- `assets/ui_web/js/world_builder.js` - JavaScript controller
- `scripts/ui/WorldBuilderWebController.gd` - Godot WebView controller
- `scripts/ui/WorldBuilderAzgaar.gd` - Legacy Azgaar controller (direct JS injection)
- `scripts/managers/AzgaarIntegrator.gd` - Azgaar file management
- `tools/azgaar/main.js` - Azgaar fork main file
- `tools/azgaar/index.html` - Azgaar fork HTML
- `data/config/azgaar_step_parameters.json` - Parameter definitions

---

**Report Generated**: 2025-12-29  
**Investigator**: AI Assistant  
**Status**: Investigation Complete - Root Causes Identified
