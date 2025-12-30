# World Builder Generate/Apply Button Failure - Audit Report
**Date:** 2025-12-29  
**Issue:** Generate/Apply button fails to regenerate after first use  
**Root Cause:** Missing generation completion detection and UI state reset

---

## Executive Summary

The Generate/Apply button in the World Builder UI becomes non-functional after the first use because:
1. Generation is triggered but completion is never detected
2. The `isGenerating` flag remains `true` indefinitely
3. No completion message handler exists to reset the UI state
4. Progress updates stop at 40% and never complete

---

## Analysis from Log File

### Key Log Entries

```
[2025-12-29 13:23:28] [WorldBuilderWebController] [DEBUG]: _handle_generate() called
[2025-12-29 13:23:29] [WorldBuilderWebController] [INFO]: Generation requested
[2025-12-29 13:23:29] [WorldBuilderWebController] [DEBUG]: Sending progress update [{"progress":10.0,"status":"Syncing parameters to Azgaar...","is_generating":true}]
[2025-12-29 13:23:30] [WorldBuilderWebController] [DEBUG]: Sending progress update [{"progress":40.0,"status":"Generating map...","is_generating":true}]
[2025-12-29 13:23:30] [WorldBuilderWebController] [INFO]: Generation triggered via iframe (eval)
```

**Problem:** After line 530 (generation triggered), there are NO further log entries indicating completion, progress updates, or state reset.

---

## Code Analysis

### 1. Generation Trigger (`WorldBuilderWebController.gd`)

```529:614:scripts/ui/WorldBuilderWebController.gd
func _handle_generate(data: Dictionary) -> void:
	"""Handle generate message from WebView."""
	MythosLogger.debug("WorldBuilderWebController", "_handle_generate() called", {"data_keys": data.keys()})
	
	# ... parameter processing ...
	
	send_progress_update(10.0, "Syncing parameters to Azgaar...", true)
	_sync_params_to_azgaar_iframe(current_params)
	send_progress_update(40.0, "Generating map...", true)
	
	# Trigger generation via iframe
	var generate_script: String = """
		(function() {
			try {
				var iframe = document.getElementById('%s');
				if (iframe && iframe.contentWindow && iframe.contentWindow.azgaar && 
				    typeof iframe.contentWindow.azgaar.generate === 'function') {
					iframe.contentWindow.azgaar.generate();
					return 'generated';
				}
				return 'error: azgaar not available';
			} catch (e) {
				console.error('[WorldBuilder] Error triggering generation:', e);
				return 'error: ' + e.message;
			}
		})();
	""" % IFRAME_ID
	
	if web_view.has_method("execute_js"):
		var result = web_view.execute_js(generate_script)
		if result == "generated":
			MythosLogger.info("WorldBuilderWebController", "Generation triggered via iframe")
		else:
			MythosLogger.error("WorldBuilderWebController", "Failed to trigger generation via iframe", {"result": result})
			send_progress_update(0.0, "Error: Failed to trigger generation", false)
	elif web_view.has_method("eval"):
		web_view.eval(generate_script)
		MythosLogger.info("WorldBuilderWebController", "Generation triggered via iframe (eval)")
```

**Issues:**
- Generation is triggered but there's no completion handler
- No final progress update with `is_generating = false`
- No timeout fallback if generation hangs

### 2. Removed Completion Handlers

```804:806:scripts/ui/WorldBuilderWebController.gd
# Removed _on_azgaar_generation_complete() and _on_azgaar_generation_failed() - 
# These were for node-based signals. For iframe, generation completion would need
# to be detected via polling or iframe postMessage (future enhancement)
```

**Problem:** Completion handlers were removed but never replaced with iframe-based alternatives.

### 3. JavaScript State Management (`world_builder.js`)

```859:896:assets/ui_web/js/world_builder.js
generate() {
    this.isGenerating = true;
    this.progressValue = 0;
    this.statusText = 'Preparing generation...';
    
    try {
        GodotBridge.postMessage('generate', { 
            params: this.params
        });
        this.statusText = 'Generation in progress...';
    } catch (e) {
        this.isGenerating = false;
        // ... error handling ...
    }
}
```

**Problem:** `isGenerating` is set to `true` but never reset to `false` after successful generation.

### 4. Progress Update Handler

```22:29:assets/ui_web/js/world_builder.js
} else if (data.update_type === 'progress_update') {
    // Update progress bar
    if (window.worldBuilderInstance) {
        window.worldBuilderInstance.progressValue = data.progress || 0;
        window.worldBuilderInstance.statusText = data.status || '';
        window.worldBuilderInstance.isGenerating = data.is_generating || false;
        console.log('[Genesis World Builder] Progress update', { progress: data.progress, status: data.status });
    }
}
```

**Status:** Handler correctly sets `isGenerating` from `data.is_generating`, but Godot never sends a completion update with `is_generating = false`.

---

## Root Cause Summary

1. **Missing Completion Detection:** No mechanism to detect when Azgaar generation completes
2. **No Completion Message:** Azgaar iframe doesn't send `generation_complete` postMessage
3. **UI State Never Reset:** `isGenerating` remains `true`, blocking subsequent generations
4. **No Timeout Fallback:** If generation hangs, state never recovers

---

## Solution Strategy

### Option 1: PostMessage-Based Completion (Recommended)
- Add postMessage listener in `world_builder.html` to listen for completion from Azgaar iframe
- Hook into Azgaar's `generate()` to send `generation_complete` postMessage
- Handle completion in `WorldBuilderWebController` to send final progress update

### Option 2: Polling-Based Completion (Fallback)
- Poll Azgaar iframe periodically to check generation state
- Reset UI state after timeout or detection

### Option 3: Timeout Fallback (Safety Net)
- Add timeout timer after triggering generation
- Automatically reset state after reasonable duration (e.g., 30 seconds)

**Recommendation:** Implement Option 1 (postMessage) with Option 3 (timeout) as safety fallback.

---

## Implementation Plan

### Step 1: Add Completion Detection in Azgaar Iframe
- Hook into Azgaar's `generate()` function to detect completion
- Send `postMessage` to parent window when generation completes

### Step 2: Add PostMessage Listener in World Builder HTML
- Listen for `generation_complete` messages from Azgaar iframe
- Forward to Godot via IPC message

### Step 3: Handle Completion in WorldBuilderWebController
- Add handler for `generation_complete` IPC message
- Send final progress update with `is_generating = false` and `progress = 100`

### Step 4: Add Timeout Fallback
- Start timeout timer when generation starts
- Reset state if completion not detected within timeout period

---

## Files to Modify

1. `scripts/ui/WorldBuilderWebController.gd` - Add completion handler and timeout
2. `assets/ui_web/templates/world_builder.html` - Add postMessage listener
3. `tools/azgaar/main.js` (optional) - Add completion postMessage hook

---

## Testing Checklist

- [ ] First generation completes and resets UI state
- [ ] Generate/Apply button works on subsequent clicks
- [ ] Progress bar reaches 100% and disappears
- [ ] `isGenerating` flag resets to `false`
- [ ] Timeout fallback works if generation hangs
- [ ] Multiple rapid clicks don't cause state issues

---

## Conclusion

The issue is a **missing completion detection mechanism** after migrating from node-based signals to iframe-based communication. The fix requires adding postMessage listeners and completion handlers to properly reset the UI state after generation completes.
