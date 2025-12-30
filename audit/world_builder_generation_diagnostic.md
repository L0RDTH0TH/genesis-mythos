# World Builder Generation Failure Diagnostic Report

**Date:** 2025-12-29  
**Issue:** Auto-generation on load fails, manual generation times out after 60 seconds

---

## 1. Symptoms

### Observed Behavior
- **Auto-generation on load:** Does not trigger successful map generation (defaults fail to produce a map)
- **Manual "Generate Map" clicks:** Result in timeout after ~60 seconds
- **Fork mode:** Not detected as available, falls back to iframe mode
- **Iframe fallback:** Times out (no iframe exists in `world_builder_v2.html`)

### Log Evidence
- Fork availability check returns "not_available"
- Falls back to iframe mode
- Iframe generation attempts fail (no iframe element)
- 60-second timeout triggers, resets UI state
- No "map_generated" IPC message received

---

## 2. Root Cause Analysis

### Issue 1: Fork Readiness Not Signaled
**Problem:** The Azgaar Genesis fork module script in `world_builder_v2.html` initializes but never sends a "fork_ready" IPC message to Godot.

**Evidence:**
- Module script sets `window.AzgaarGenesis.initialized = true` (line 214)
- Logs "[Azgaar Genesis] Library loaded and ready" (line 217)
- **Missing:** No `GodotBridge.postMessage('fork_ready', {})` call

**Impact:** Godot doesn't know when the fork is ready, so:
- Auto-generation triggers too early (0.5s after alpine_ready, before module loads)
- Fork availability check fails because module script hasn't finished loading

### Issue 2: Module Script Loading Timing
**Problem:** ES6 module scripts (`<script type="module">`) load asynchronously, so the fork may not be ready when Godot checks.

**Evidence:**
- Module imports from CDN and local files (lines 165-174)
- Initialization happens in module scope (lines 189-205)
- Godot checks fork availability immediately in `_handle_generate()` (line 596)
- No retry logic or wait for module completion

**Impact:** Fork check happens before module script finishes loading, returns "not_available"

### Issue 3: Iframe Fallback Incompatible
**Problem:** `world_builder_v2.html` is fork-only (no iframe), but code falls back to iframe mode when fork unavailable.

**Evidence:**
- `world_builder_v2.html` has no `<iframe id="azgaar-iframe">` element
- `_generate_via_iframe()` tries to access `document.getElementById('azgaar-iframe')` (line 735)
- Returns "error: azgaar not available" (line 741)
- Starts 60s timeout timer, which eventually triggers

**Impact:** When fork isn't detected, fallback fails immediately but timeout still runs

### Issue 4: Version Mismatch (Potential)
**Problem:** Project configured for Godot 4.5.1.stable but running on 4.6.beta2.

**Evidence:**
- `project.godot`: `godot_version="4.5.1.stable"`
- Runtime: Godot 4.6.beta2.official.551ce8d47
- godot_wry binary may be incompatible with 4.6.beta2

**Impact:** WebView may not function correctly, causing fork detection to fail

---

## 3. Fixes Applied

### Fix 1: Add Fork Ready IPC Signal
**File:** `assets/ui_web/templates/world_builder_v2.html`

**Change:** Added `fork_ready` IPC message after fork initialization:
```javascript
// Notify Godot that fork is ready via IPC
if (window.GodotBridge && window.GodotBridge.postMessage) {
    window.GodotBridge.postMessage('fork_ready', {});
    console.log('[Azgaar Genesis] Sent fork_ready IPC message to Godot');
}
```

**Location:** After `window.AzgaarGenesis` object creation (line ~217)

### Fix 2: Track Fork Readiness
**File:** `scripts/ui/WorldBuilderWebController.gd`

**Change:** Added `fork_ready` flag and updated handler:
```gdscript
var fork_ready: bool = false

func _handle_fork_ready(data: Dictionary) -> void:
    fork_ready = true
    MythosLogger.info("WorldBuilderWebController", "Fork is ready for generation - fork_ready IPC received")
```

### Fix 3: Wait for Fork Ready Before Auto-Generation
**File:** `scripts/ui/WorldBuilderWebController.gd`

**Change:** Modified `_handle_alpine_ready()` to wait for `fork_ready` IPC:
```gdscript
# Wait for fork initialization (fork_ready IPC), then trigger auto-generation
# If fork_ready not received within 3 seconds, proceed anyway
await get_tree().create_timer(3.0).timeout
if not fork_ready:
    MythosLogger.warn("WorldBuilderWebController", "fork_ready IPC not received, proceeding with auto-generation anyway")
_trigger_auto_generation_on_load()
```

**Previous:** Only waited 0.5s (too short for module script)

### Fix 4: Retry Fork Availability Check
**File:** `scripts/ui/WorldBuilderWebController.gd`

**Change:** Added retry logic in `_handle_generate()`:
```gdscript
var max_retries: int = 5
var retry_delay: float = 0.2

for attempt in range(max_retries):
    # Check fork availability
    # ... (check script)
    if fork_available:
        break
    if attempt < max_retries - 1:
        await get_tree().create_timer(retry_delay).timeout
```

**Impact:** Gives module script time to load before declaring fork unavailable

### Fix 5: Improved Error Handling
**File:** `scripts/ui/WorldBuilderWebController.gd`

**Changes:**
- Added WebView null check in `_generate_via_fork()`
- Added debug logging for fork options
- Improved error messages for iframe fallback (warns about no iframe)
- Added result type logging for fork generation

### Fix 6: Better Iframe Fallback Warnings
**File:** `scripts/ui/WorldBuilderWebController.gd`

**Change:** Added warning that iframe mode will fail in fork template:
```gdscript
MythosLogger.warn("WorldBuilderWebController", "Iframe mode requested, but world_builder_v2.html has no iframe - this will fail")
```

### Fix 7: Temporary Version Test
**File:** `project.godot`

**Change:** Temporarily set to `godot_version="4.6.beta2"` to test if version mismatch is causing issues.

**Note:** Per project rules, should be 4.5.1.stable, but testing with current runtime version.

---

## 4. Testing Plan

### Test 1: Fork Ready IPC
1. Run project, navigate to World Builder
2. Check logs for "fork_ready IPC received" message
3. Verify `fork_ready` flag is set to `true`

### Test 2: Auto-Generation on Load
1. Wait for World Builder to load
2. Verify map auto-generates within 5 seconds
3. Check logs for fork availability check retries
4. Verify "map_generated" IPC is received

### Test 3: Manual Generation
1. Click "Generate Map" button
2. Verify fork is detected (after retries if needed)
3. Verify generation completes without timeout
4. Check for preview image display

### Test 4: Fork Detection Retries
1. Check logs for multiple fork availability check attempts
2. Verify at least one attempt succeeds
3. Verify generation proceeds via fork mode

---

## 5. Expected Outcomes

### Success Criteria
- ✅ Fork ready IPC received within 2-3 seconds of page load
- ✅ Auto-generation triggers after fork_ready (or 3s timeout)
- ✅ Fork availability check succeeds (after retries if needed)
- ✅ Map generation completes via fork mode
- ✅ Preview displays in central panel
- ✅ No 60-second timeouts

### Failure Scenarios
- ❌ Fork ready IPC never received → Module script fails to load
- ❌ Fork availability check fails after retries → WebView/JS execution issue
- ❌ Generation script returns error → Fork API issue
- ❌ map_generated IPC never received → Fork generation fails silently

---

## 6. Additional Recommendations

### If Fork Still Fails
1. **Check Module Script Loading:**
   - Verify `azgaar-genesis.esm.js` file exists and is accessible
   - Check browser console for module import errors
   - Verify CDN access for Delaunator import

2. **Verify WebView JS Execution:**
   - Test simple `execute_js("return 'test';")` to verify WebView works
   - Check for GDExtension errors on startup
   - Verify godot_wry is loading correctly

3. **Module Script Alternative:**
   - Consider loading fork via non-module script if ES6 modules fail
   - Use dynamic import() with error handling
   - Add fallback to UMD build if ESM fails

4. **Version Compatibility:**
   - If 4.6.beta2 works, rebuild godot_wry for 4.5.1.stable
   - Or switch project to 4.5.1.stable and test
   - Check godot_wry GitHub for 4.6 compatibility status

### If Iframe Fallback Needed
- Create hybrid template with both fork and iframe
- Or create separate `world_builder_iframe.html` template
- Add template selection logic based on availability

---

## 7. Files Modified

1. `assets/ui_web/templates/world_builder_v2.html` - Added fork_ready IPC
2. `scripts/ui/WorldBuilderWebController.gd` - Added fork_ready tracking, retry logic, improved error handling
3. `project.godot` - Temporarily set to 4.6.beta2 for testing

---

## 8. Test Results (2025-12-29 23:49)

### ✅ Successes
- **fork_ready IPC received** - Fork initialization signal works correctly
- **Auto-generation triggers** - After 3s wait, auto-generation is triggered
- **Archetype loading works** - High Fantasy preset loads correctly

### ❌ Remaining Issues
- **Fork availability check fails** - After 5 retries, fork still not detected as available
- **WebView binding panics** - Multiple "Gd<T>::bind() failed, already bound" errors when calling `execute_js`
- **Root cause identified** - WebView binding panics prevent `execute_js` from working, so fork check always fails

### Error Details
```
ERROR: [panic] Gd<T>::bind() failed, already bound; T = godot_wry::WebView.
  Details: cannot borrow while accessible mutable borrow exists.
  At: _send_step_definitions_response, _send_params_update, etc.
```

**Impact:** When `_handle_generate()` tries to check fork availability via `execute_js`, the WebView is already bound from previous IPC message handling, causing a panic. The fork check fails, and it falls back to iframe mode.

### Next Steps
1. **Fix WebView binding issue** - Avoid concurrent WebView access, use signals/callbacks instead of direct execute_js in IPC handlers
2. **Alternative fork check** - Use `fork_ready` flag instead of executing JS to check availability
3. **Defer JS execution** - Queue execute_js calls or use call_deferred to avoid binding conflicts
4. **Version decision** - Determine if 4.5.1.stable or 4.6.beta2 should be used (per project rules, 4.5.1.stable is required)

---

## 9. Raw Log Excerpts (From Previous Run)

```
[WorldBuilderWebController] Fork availability check: {"result": "not_available", "available": false}
[WorldBuilderWebController] Fork not available, falling back to iframe mode
[WorldBuilderWebController] Azgaar not ready yet via iframe, attempting generation anyway
[WorldBuilderWebController] Generation triggered via iframe (eval)
[WorldBuilderWebController] Generation timeout - resetting UI state as fallback
```

**Missing:**
- No "fork_ready IPC received" message
- No fork availability check retries
- No successful fork generation
