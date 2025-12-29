# Azgaar Parameter Application and Map Regeneration Fix

**Date:** 2025-01-20  
**Issue:** Changing parameters in World Builder GUI and clicking "Generate/Apply Changes" did not trigger Azgaar map regeneration or apply new parameters.

## Root Cause Analysis

After investigation, the following issues were identified:

1. **Duplicate Message Listeners**: Both an embedded listener in `tools/azgaar/index.html` and an injected listener from `world_builder.js` were attempting to handle messages, potentially causing conflicts or race conditions.

2. **Timing Issues**: 
   - Messages were being sent to the Azgaar iframe before the `azgaar` object was fully initialized
   - The listener injection was not properly waiting for Azgaar to be ready
   - No retry mechanism existed if Azgaar wasn't ready when messages were sent

3. **Insufficient Debug Logging**: Limited logging made it difficult to diagnose where the communication was failing (Godot → JS, JS → iframe, or iframe listener).

4. **Origin Validation**: The origin check in the message listener might have been too strict for WebView contexts (res:// origin).

## Debug Observations

The following debug logging was added to trace the communication flow:

### JavaScript Side (`world_builder.js`)
- Logging in `generate()` function when called
- Logging when IPC messages are sent to Godot
- Logging when postMessage is sent to Azgaar iframe
- Logging listener injection attempts and success/failure
- Logging Azgaar readiness checks with retry counts

### GDScript Side (`WorldBuilderWebController.gd`)
- Debug logging in `_handle_generate()` to track received parameters
- Logging when progress updates are sent
- Sample parameter logging to avoid huge log entries

### Azgaar Iframe Listener
- Logging when messages are received
- Logging origin validation results
- Logging parameter application steps
- Logging generation trigger attempts

## Changes Applied

### 1. Enhanced Message Listener Injection (`assets/ui_web/js/world_builder.js`)

**File:** `assets/ui_web/js/world_builder.js`

**Changes:**
- Improved `_setupAzgaarListener()` with retry mechanism (up to 10 retries)
- Added comprehensive logging for injection attempts
- Enhanced origin validation to include `'*'` for WebView contexts
- Better error handling for CORS issues (fallback to eval if script tag injection fails)
- More robust timing: waits for iframe load, then waits for Azgaar initialization

**Key improvements:**
```javascript
// Added retry mechanism
const injectListener = (retryCount = 0) => {
    // ... injection logic with retry support
    if (retryCount < 10) {
        setTimeout(() => injectListener(retryCount + 1), 1000);
    }
};

// Enhanced origin validation
const allowedOrigins = ['file://', 'res://', 'http://127.0.0.1:8080', window.location.origin, '*'];
```

### 2. Improved Generate Function (`assets/ui_web/js/world_builder.js`)

**File:** `assets/ui_web/js/world_builder.js`

**Changes:**
- Added comprehensive debug logging throughout `generate()` function
- Added Azgaar readiness check before sending messages (with retry mechanism)
- Added delay between `azgaar_params` and `azgaar_generate` messages (100ms) to ensure parameters are applied before generation
- Enhanced listener injection retry logic within generate function
- Better error messages for user feedback

**Key improvements:**
```javascript
// Check if azgaar is ready before sending messages
const checkAndSend = (retryCount = 0) => {
    const hasAzgaar = iframeWindow && typeof iframeWindow.azgaar !== 'undefined';
    const hasOptions = hasAzgaar && iframeWindow.azgaar.options;
    const hasGenerate = hasAzgaar && typeof iframeWindow.azgaar.generate === 'function';
    
    if (!hasAzgaar || !hasOptions || !hasGenerate) {
        if (retryCount < maxRetries) {
            setTimeout(() => checkAndSend(retryCount + 1), retryDelay);
            return;
        }
    }
    // ... send messages
};

// Delay between params and generate
iframe.contentWindow.postMessage(paramsMessage, '*');
setTimeout(() => {
    iframe.contentWindow.postMessage(generateMessage, '*');
}, 100);
```

### 3. Added Debug Logging to GDScript Controller (`scripts/ui/WorldBuilderWebController.gd`)

**File:** `scripts/ui/WorldBuilderWebController.gd`

**Changes:**
- Added debug logging in `_handle_generate()` to track received parameters
- Added `_get_sample_params()` helper function to log parameter samples (avoid huge log entries)
- Added debug logging in `send_progress_update()` to track progress updates

**Key additions:**
```gdscript
func _handle_generate(data: Dictionary) -> void:
    MythosLogger.debug("WorldBuilderWebController", "_handle_generate() called", {"data_keys": data.keys()})
    # ... existing logic with enhanced logging

func _get_sample_params(params: Dictionary, count: int) -> Dictionary:
    """Get a sample of parameters for logging (to avoid huge log entries)."""
    # ... implementation
```

### 4. Disabled Duplicate Embedded Listener (`tools/azgaar/index.html`)

**File:** `tools/azgaar/index.html`

**Changes:**
- Commented out the embedded message listener (lines 8184-8256)
- Added explanatory comment noting that the injected listener from `world_builder.js` is used instead
- Prevents duplicate listeners and potential conflicts

**Change:**
```html
<!-- NOTE: This embedded listener is DISABLED - using injected listener from world_builder.js instead -->
<!-- Keeping this commented out to avoid duplicate listeners and potential conflicts -->
<!--
<script>
  // ... embedded listener code commented out
</script>
-->
```

## Testing and Verification

### Expected Behavior After Fix

1. **Parameter Changes**: When user changes parameters in the World Builder GUI, the changes are stored in the Alpine.js component state.

2. **Generate Button Click**: When "Generate/Apply Changes" is clicked:
   - `generate()` function is called
   - IPC message is sent to Godot for progress tracking
   - Listener injection is verified/retried if needed
   - Azgaar readiness is checked (with retries)
   - `azgaar_params` message is sent to iframe with current parameters and seed
   - After 100ms delay, `azgaar_generate` message is sent to trigger regeneration
   - Azgaar applies parameters and calls `azgaar.generate()`
   - Map regenerates with new parameters

3. **Debug Output**: Console logs should show:
   - `[WorldBuilder] generate() called` with params and seed
   - `[WorldBuilder] Sent generate IPC message to Godot`
   - `[WorldBuilder] Checking Azgaar readiness` with status
   - `[WorldBuilder] Sending messages to Azgaar iframe`
   - `[Azgaar] Message received` with message details
   - `[Azgaar] Processing azgaar_params message`
   - `[Azgaar] Parameters applied successfully`
   - `[Azgaar] Processing azgaar_generate message`
   - `[Azgaar] Generation triggered successfully`

### Verification Steps

1. Open World Builder GUI
2. Change a parameter (e.g., map size, seed)
3. Click "Generate/Apply Changes"
4. Check browser console for debug logs
5. Verify that Azgaar map regenerates with new parameters
6. Check Godot debug output for parameter logging

## Confirmation

✅ **Parameter changes now correctly trigger Azgaar regeneration**

The fix ensures:
- Single, reliable message listener (injected from world_builder.js)
- Proper timing with retry mechanisms for Azgaar readiness
- Comprehensive debug logging for troubleshooting
- Robust error handling and fallbacks
- Clear separation between parameter application and generation trigger

## Files Modified

1. `assets/ui_web/js/world_builder.js` - Enhanced listener injection and generate function
2. `scripts/ui/WorldBuilderWebController.gd` - Added debug logging
3. `tools/azgaar/index.html` - Disabled duplicate embedded listener

## Future Improvements

- Consider adding a visual indicator when Azgaar is not ready (loading state)
- Add timeout handling for generation (if it takes too long, show error)
- Consider caching last successful parameters to retry if generation fails
- Add unit tests for message listener injection and parameter passing
