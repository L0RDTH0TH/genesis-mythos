# Change 5: Add Console Capture Fallback

**Date:** 2026-01-01  
**File:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js`  
**Location:** Top of file, before first function

## What Was Changed

Added console capture fallback that intercepts `console.log`, `console.warn`, and `console.error` calls and forwards them to GodotBridge if available.

### Before

```javascript
function aleaPRNG(...args) {
  // ...
}
```

### After

```javascript
// Console capture fallback for GodotBridge integration
if (typeof window !== "undefined" && window.GodotBridge && window.GodotBridge.postMessage) {
  const originalLog = console.log;
  const originalWarn = console.warn;
  const originalError = console.error;
  console.log = function(...args) {
    originalLog.apply(console, args);
    try {
      window.GodotBridge.postMessage('console_log', {msg: args.join(' ')});
    } catch (e) {
      // Ignore postMessage errors
    }
  };
  console.warn = function(...args) {
    originalWarn.apply(console, args);
    try {
      window.GodotBridge.postMessage('console_warn', {msg: args.join(' ')});
    } catch (e) {
      // Ignore postMessage errors
    }
  };
  console.error = function(...args) {
    originalError.apply(console, args);
    try {
      window.GodotBridge.postMessage('console_error', {msg: args.join(' ')});
    } catch (e) {
      // Ignore postMessage errors
    }
  };
}

function aleaPRNG(...args) {
  // ...
}
```

## Why (Reference to Investigation)

The investigation audit identified that console logs from validation code might not be visible in Godot logs due to filtering or WebView limitations. By intercepting console calls and forwarding them via `postMessage`, we ensure that critical validation warnings (like empty `cells.v` warnings) are visible in Godot's debug output.

This is a fallback mechanism - if the WebView's `console_message` signal is working properly, this provides duplicate logging, but if it's not working, this ensures logs are captured.

## Expected Impact

- **Positive:** Ensures validation warnings are visible in Godot logs even if WebView console_message signal fails
- **Positive:** Helps with debugging by capturing all console output
- **Neutral:** Minimal performance impact - only activates if GodotBridge exists, uses try-catch to prevent errors
- **Risk:** Very low - only activates in specific environment, uses defensive programming
