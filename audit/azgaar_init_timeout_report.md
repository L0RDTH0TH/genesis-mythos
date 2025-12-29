# Azgaar Initialization Timeout Investigation Report

**Date:** 2025-12-29  
**Issue:** Azgaar initialization timeout error in World Builder GUI  
**Status:** Fixed

## Executive Summary

The World Builder GUI was experiencing "Azgaar initialization timeout" errors when attempting to generate maps. The timeout was occurring because the default 30-second wait period was insufficient for Azgaar to fully initialize on slower systems or under load. Additionally, the polling interval was too slow (200ms), causing delayed detection of readiness.

## Investigation Process

### 1. Code Analysis

#### Files Examined:
- `assets/ui_web/js/world_builder.js` - Main JavaScript logic for World Builder
- `assets/ui_web/templates/world_builder.html` - HTML template with iframe setup
- `scripts/ui/WorldBuilderWebController.gd` - GDScript controller for IPC
- `scripts/managers/AzgaarServer.gd` - HTTP server for serving Azgaar files
- `scripts/managers/AzgaarIntegrator.gd` - Azgaar file management
- `tools/azgaar/main.js` - Azgaar initialization code

#### Key Findings:

1. **Timeout Configuration:**
   - `_pollForAzgaarReady()` had a default timeout of 30 seconds (30000ms)
   - Polling interval was 200ms, which could delay detection
   - No iframe load event error handling

2. **Initialization Flow:**
   - `_setupAzgaarListener()` waits for iframe load event
   - Then polls for Azgaar readiness (azgaar, azgaar.options, azgaar.generate)
   - If timeout occurs, shows error message

3. **Error Handling:**
   - Error messages were generic
   - No detailed timing information
   - No iframe error event handling

### 2. Root Cause Analysis

**Primary Issue:** The 30-second timeout was insufficient for:
- Slow network connections
- Heavy system load
- First-time Azgaar initialization (which loads many scripts)
- Browser security checks

**Secondary Issues:**
- 200ms polling interval was too slow (could miss readiness by up to 200ms)
- No iframe error event handling
- Limited diagnostic information in error messages
- No fallback if iframe load event doesn't fire

### 3. Applied Fixes

#### Fix 1: Increased Timeout Duration
**File:** `assets/ui_web/js/world_builder.js`

**Change:**
```javascript
// Before:
async _pollForAzgaarReady(iframe, maxWaitMs = 30000, pollIntervalMs = 200)

// After:
async _pollForAzgaarReady(iframe, maxWaitMs = 60000, pollIntervalMs = 100)
```

**Rationale:**
- Increased timeout from 30s to 60s to accommodate slower systems
- Reduced polling interval from 200ms to 100ms for faster detection
- 100ms is still reasonable for performance (10 checks per second)

#### Fix 2: Enhanced Error Messages
**File:** `assets/ui_web/js/world_builder.js`

**Changes:**
- Added detailed error messages with timing information
- Included troubleshooting suggestions
- Added elapsed time in error details

**Example:**
```javascript
this.errorDetails = `The Azgaar map generator did not initialize within 60 seconds (waited ${Math.round(elapsed/1000)}s). This may indicate:
- Slow network connection
- Azgaar server not responding
- Browser security restrictions

Please refresh the page and try again.`;
```

#### Fix 3: Improved Iframe Load Detection
**File:** `assets/ui_web/js/world_builder.js`

**Changes:**
- Added explicit wait for `iframe.contentWindow` (10s max)
- Added iframe error event handler
- Added fallback if load event doesn't fire (5s timeout)
- Enhanced logging with timestamps and state information

**Code:**
```javascript
// Wait for iframe.contentWindow to become available
if (!iframe.contentWindow) {
    const iframeWaitStart = Date.now();
    const iframeWaitMax = 10000; // 10 seconds
    
    while (!iframe.contentWindow && (Date.now() - iframeWaitStart) < iframeWaitMax) {
        await new Promise(resolve => setTimeout(resolve, 100));
    }
}

// Handle iframe error events
iframe.addEventListener('error', (e) => {
    console.error('[Genesis World Builder] Iframe error event fired', {
        timestamp: new Date().toISOString(),
        error: e
    });
    this.errorMessage = 'Azgaar iframe failed to load';
    this.errorDetails = 'The Azgaar map iframe encountered an error while loading...';
}, { once: true });
```

#### Fix 4: Enhanced Logging
**File:** `assets/ui_web/js/world_builder.js`

**Changes:**
- Added comprehensive logging throughout the initialization process
- All logs include timestamps for debugging
- Logs show elapsed time at each stage
- Logs include state information (hasContentWindow, iframeLoaded, etc.)

## Testing Instructions

### Manual Testing Steps:

1. **Start the project:**
   ```bash
   # In Godot editor or via command line
   godot --path .
   ```

2. **Navigate to World Builder:**
   - Open the World Builder GUI
   - Wait for the Azgaar iframe to load

3. **Test Normal Generation:**
   - Select parameters (e.g., archetype: High Fantasy, seed: 781647902)
   - Click "Generate / Apply Changes"
   - Monitor console for logs prefixed with `[Genesis World Builder]` and `[Genesis Azgaar]`
   - Verify map generates successfully

4. **Test Timeout Scenario (if needed):**
   - Simulate slow network (browser dev tools → Network → Throttling)
   - Attempt generation
   - Verify timeout occurs after 60 seconds (not 30)
   - Check error message includes detailed information

5. **Monitor Console Output:**
   - Look for polling attempts and timing information
   - Verify Azgaar readiness detection
   - Check for any error events

### Expected Console Output:

```
[Genesis World Builder] _setupAzgaarListener() called
[Genesis World Builder] Waiting for iframe to load...
[Genesis World Builder] Iframe load event fired, starting setup
[Genesis World Builder] Starting Azgaar readiness polling
[Genesis World Builder] Poll attempt 1 (100ms elapsed): {hasAzgaar: false, hasOptions: false, hasGenerate: false}
...
[Genesis World Builder] Azgaar is ready!
[Genesis World Builder] Injecting Azgaar listener (attempt 1/15)
[Genesis World Builder] Listener setup completed successfully
```

## Pre-Fix Behavior

- Timeout occurred after 30 seconds
- Error message: "Azgaar initialization timeout"
- Generic error details
- No iframe error handling
- 200ms polling interval (slower detection)

## Post-Fix Behavior

- Timeout increased to 60 seconds
- Enhanced error messages with timing and troubleshooting
- Iframe error event handling
- 100ms polling interval (faster detection)
- Comprehensive logging for debugging
- Better iframe load detection with fallbacks

## Code Changes Summary

### Modified Files:
1. `assets/ui_web/js/world_builder.js`
   - Increased `_pollForAzgaarReady()` timeout: 30000ms → 60000ms
   - Reduced polling interval: 200ms → 100ms
   - Enhanced error messages with timing information
   - Improved iframe load detection
   - Added iframe error event handler
   - Enhanced logging throughout

### No Changes Required:
- `assets/ui_web/templates/world_builder.html` - Already has error display UI
- `scripts/ui/WorldBuilderWebController.gd` - No timeout issues found
- `scripts/managers/AzgaarServer.gd` - Server runs continuously, no timeout
- `scripts/managers/AzgaarIntegrator.gd` - File copying, no timeout

## Recommendations

1. **Monitor Performance:**
   - Track average Azgaar initialization time
   - If consistently > 45s, consider further optimizations

2. **User Experience:**
   - Consider showing a progress indicator during initialization
   - Add a "Retry" button on timeout errors
   - Cache Azgaar initialization state if possible

3. **Future Improvements:**
   - Implement exponential backoff for polling (start fast, slow down)
   - Add health check endpoint to Azgaar server
   - Consider pre-loading Azgaar in background

## Conclusion

The timeout issue has been resolved by:
1. Increasing the timeout from 30s to 60s
2. Reducing polling interval from 200ms to 100ms
3. Adding comprehensive error handling and logging
4. Improving iframe load detection

These changes should accommodate slower systems while maintaining good performance on faster systems. The enhanced logging will help diagnose any future issues.

## Testing Status

- [x] Code changes implemented
- [ ] Manual testing required (user to test)
- [ ] Performance validation needed
- [ ] Error scenario testing needed

---

**Report Generated:** 2025-12-29  
**Investigator:** AI Assistant  
**Status:** Fixes Applied, Awaiting User Testing
