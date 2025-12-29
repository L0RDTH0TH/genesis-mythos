# Curated Azgaar Parameters Approach - Audit Report

**Date:** 2025-01-20  
**Author:** Auto (Cursor AI)  
**Purpose:** Investigate current implementation of curated Azgaar world generation parameters and propose optimizations for the full JS-based GUI era

---

## Executive Summary

The current implementation uses a multi-layer parameter flow: JSON definitions → Godot controller → Alpine.js WebView → postMessage → Azgaar iframe. While functional, this approach introduces complexity and fragility due to cross-origin iframe communication. With full JS-based GUI migration complete, opportunities exist to simplify by leveraging direct JavaScript access to Azgaar when served from the same origin.

---

## Current Implementation Summary

### Architecture Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. DATA DEFINITION LAYER                                        │
│    res://data/config/azgaar_step_parameters.json                │
│    - 8 steps with curated parameters                            │
│    - Each param: azgaar_key, ui_type, min/max, default, etc.   │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. GODOT CONTROLLER LAYER                                        │
│    scripts/ui/WorldBuilderWebController.gd                      │
│    - Loads step definitions from JSON                           │
│    - Clamps parameters (hardware-aware for pointsInput)         │
│    - Sends to WebView via execute_js()                          │
│    - Handles IPC messages (update_param, generate, etc.)         │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. ALPINE.JS WEBVIEW LAYER                                       │
│    assets/ui_web/templates/world_builder.html                  │
│    assets/ui_web/js/world_builder.js                            │
│    - Alpine.js component manages UI state                       │
│    - Renders parameters from step definitions                   │
│    - Collects user input in params{} object                     │
│    - Debounced updates sent to Godot via IPC                    │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. IFRAME COMMUNICATION LAYER                                   │
│    <iframe src="http://127.0.0.1:8080/index.html">              │
│    - Injected message listener (via script tag or eval)         │
│    - Listens for 'azgaar_params' and 'azgaar_generate' messages  │
│    - Applies params to azgaar.options via Object.assign()        │
│    - Calls azgaar.generate()                                    │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. AZGAAR GENERATION LAYER                                      │
│    tools/azgaar/main.js, modules/ui/options.js                  │
│    - azgaar.options object holds all parameters                │
│    - azgaar.generate() triggers map generation                 │
│    - Legacy options.json loading (unused in current flow)       │
└─────────────────────────────────────────────────────────────────┘
```

### Key Files and Responsibilities

#### Data Layer
- **`data/config/azgaar_step_parameters.json`**: Defines 8 wizard steps with curated parameters. Each parameter includes:
  - `azgaar_key`: Direct mapping to Azgaar option (e.g., `"pointsInput"`, `"options.winds[0]"`)
  - `curated`: Boolean flag (defaults to `true`) to filter which params appear in UI
  - `clamped_min`/`clamped_max`: Hardware-aware limits (e.g., `pointsInput` clamped to 1-10)
  - `ui_type`: Control type (HSlider, SpinBox, OptionButton, CheckBox)

#### Godot Controller
- **`scripts/ui/WorldBuilderWebController.gd`**: 
  - Loads step definitions from JSON
  - Clamps parameters server-side (especially `pointsInput` with hardware awareness)
  - Sends step definitions to WebView via `execute_js()` with Alpine.js reactivity handling
  - Handles IPC: `update_param`, `generate`, `load_archetype`, `set_seed`
  - Tracks current_params dictionary (synced with WebView)

#### WebView (Alpine.js)
- **`assets/ui_web/js/world_builder.js`**:
  - Alpine.js component `worldBuilder` manages state
  - `params{}` object stores all parameter values
  - `updateParam(key, value)` debounces updates and sends to Godot
  - `generate()` function:
    1. Sends params to Godot via IPC
    2. Injects message listener into Azgaar iframe (if not already injected)
    3. Sends `postMessage` with `azgaar_params` type
    4. Sends `postMessage` with `azgaar_generate` type
  - `_setupAzgaarListener()`: Injects listener script into iframe (retries on failure)

#### Azgaar Integration
- **`tools/azgaar/index.html`**: Standard Azgaar HTML (no customizations)
- **`tools/azgaar/main.js`**: Contains legacy `loadGodotCustomOptions()` that fetches `options.json` (unused in current flow)
- **Injected Listener**: Listens for `postMessage` events, applies params to `azgaar.options`, calls `azgaar.generate()`

---

## Identified Issues and Inefficiencies

### 1. **Cross-Origin Complexity**
- **Issue**: Azgaar is loaded in an iframe from `http://127.0.0.1:8080`, requiring `postMessage` for communication
- **Impact**: 
  - Listener injection is fragile (CORS checks, timing issues, retry logic)
  - Cannot directly access `azgaar` object from parent window
  - Requires string-based message passing instead of direct object manipulation

### 2. **Redundant Parameter Clamping**
- **Issue**: Parameters are clamped in both Godot (`_clamp_parameter_value()`) and JavaScript (`updateParam()`)
- **Impact**: 
  - Duplicate logic maintenance
  - Potential inconsistencies if clamping rules diverge
  - Unnecessary round-trip to Godot for validation

### 3. **Fragile Listener Injection**
- **Issue**: `_setupAzgaarListener()` uses multiple fallback strategies (script tag → eval → retries)
- **Impact**:
  - Complex retry logic (10 attempts with delays)
  - Timing-dependent (waits for iframe load, then 2-3 second delay for Azgaar init)
  - Potential race conditions if generate() called before listener ready

### 4. **Unused Legacy Code**
- **Issue**: `tools/azgaar/main.js` contains `loadGodotCustomOptions()` that fetches `options.json` (never created/used)
- **Impact**: Dead code, potential confusion for future developers

### 5. **Parameter Flow Overhead**
- **Issue**: Parameters flow through multiple layers: JSON → Godot → JS → postMessage → iframe → Azgaar
- **Impact**:
  - Each layer adds serialization/deserialization overhead
  - IPC messages for every parameter update (debounced, but still overhead)
  - Godot acts as unnecessary intermediary for parameter updates

### 6. **Limited Error Handling**
- **Issue**: If listener injection fails or postMessage is blocked, errors are logged but user experience degrades silently
- **Impact**: Users may not realize generation failed due to communication issues

---

## Proposed Alternative Approaches

### Option 1: Direct Azgaar Loading (Same-Origin WebView)

**Concept**: Load Azgaar directly in the main WebView instead of an iframe, enabling direct JavaScript access to `azgaar` object.

**Implementation**:
1. Modify `world_builder.html` to load Azgaar scripts directly (or embed Azgaar in a div instead of iframe)
2. Remove iframe and postMessage communication
3. Directly manipulate `azgaar.options` from `world_builder.js`
4. Call `azgaar.generate()` directly

**Pros**:
- ✅ Eliminates postMessage complexity
- ✅ Direct object access (no serialization)
- ✅ No listener injection needed
- ✅ Simpler error handling
- ✅ Better performance (no cross-origin overhead)
- ✅ Easier debugging (direct console access)

**Cons**:
- ❌ Requires Azgaar to be served from same origin (already done via localhost:8080)
- ❌ May need to modify Azgaar's UI to hide/show controls (or use headless mode)
- ❌ Potential conflicts if Azgaar's own UI interferes with our wizard
- ❌ More complex initial setup (need to ensure Azgaar scripts load before our code)

**Feasibility**: High - Azgaar is already served from `http://127.0.0.1:8080`, so same-origin is achievable. Would need to either:
- Load Azgaar in a hidden div and only show the canvas
- Use Azgaar's headless mode (if available)
- Override Azgaar's UI CSS to hide controls

---

### Option 2: Simplified postMessage with Better Abstraction

**Concept**: Keep iframe approach but simplify the communication layer with a cleaner abstraction.

**Implementation**:
1. Create a dedicated `AzgaarBridge.js` module that handles all iframe communication
2. Implement a queue system for messages (retry failed messages)
3. Add connection health monitoring
4. Simplify parameter application (batch updates instead of individual messages)

**Pros**:
- ✅ Maintains isolation (Azgaar UI doesn't interfere)
- ✅ Better error handling and retry logic
- ✅ Cleaner separation of concerns
- ✅ Easier to test (mockable bridge)

**Cons**:
- ❌ Still requires postMessage (cross-origin overhead)
- ❌ Listener injection complexity remains
- ❌ More code to maintain

**Feasibility**: Medium - Improves current approach but doesn't eliminate fundamental issues.

---

### Option 3: Hybrid Approach (Direct Access with Fallback)

**Concept**: Try to access Azgaar directly, fall back to postMessage if same-origin fails.

**Implementation**:
1. Check if `window.azgaar` is accessible (same-origin check)
2. If accessible, use direct manipulation
3. If not, fall back to iframe + postMessage
4. Abstract parameter application behind a unified API

**Pros**:
- ✅ Best of both worlds (performance when possible, compatibility when needed)
- ✅ Graceful degradation
- ✅ Future-proof (works if origin changes)

**Cons**:
- ❌ Most complex implementation
- ❌ Requires maintaining both code paths
- ❌ Testing complexity (need to test both paths)

**Feasibility**: Medium-High - Good long-term solution but requires careful abstraction.

---

## Recommendation

**Recommended Approach: Option 1 (Direct Azgaar Loading)**

**Rationale**:
1. **Simplification**: Eliminates the most complex part of the current system (postMessage + listener injection)
2. **Performance**: Direct object access is faster and more reliable
3. **Maintainability**: Fewer moving parts, easier to debug
4. **Current Context**: Azgaar is already served from localhost:8080, so same-origin is achievable

**Implementation Steps**:

1. **Phase 1: Investigation**
   - Test loading Azgaar directly in WebView (without iframe)
   - Verify `azgaar` object is accessible from `world_builder.js`
   - Check if Azgaar's UI can be hidden/disabled (CSS or headless mode)

2. **Phase 2: Refactoring**
   - Remove iframe from `world_builder.html`
   - Load Azgaar scripts directly (or embed Azgaar HTML in a div)
   - Remove `_setupAzgaarListener()` and postMessage code
   - Replace with direct `azgaar.options` manipulation in `generate()`

3. **Phase 3: Parameter Flow Simplification**
   - Remove Godot as intermediary for parameter updates (keep only for step definitions and archetype presets)
   - Move parameter clamping to JavaScript (single source of truth)
   - Use Alpine.js reactivity for real-time parameter updates

4. **Phase 4: Cleanup**
   - Remove unused `loadGodotCustomOptions()` from Azgaar main.js (or document it)
   - Remove listener injection retry logic
   - Simplify error handling (direct access = simpler errors)

**Migration Path**:
- Keep current iframe approach as fallback during transition
- Feature flag to switch between iframe and direct access
- Gradual migration: test direct access, then switch over

---

## Next Steps

1. **Immediate**: Test direct Azgaar loading in WebView to verify feasibility
2. **Short-term**: Implement Option 1 if feasible, or Option 2 if not
3. **Medium-term**: Simplify parameter flow (remove Godot intermediary for updates)
4. **Long-term**: Consider full Azgaar integration (embed as library instead of separate app)

---

## Appendix: Current Parameter Flow Details

### Parameter Update Flow (Current)
```
User changes slider → Alpine.js updateParam() → 
  → Debounce (100ms) → IPC to Godot → 
  → WorldBuilderWebController._handle_update_param() → 
  → Clamp value → Store in current_params → 
  → (No immediate sync back to WebView - only on generate)
```

### Generation Flow (Current)
```
User clicks Generate → Alpine.js generate() → 
  → IPC to Godot (for progress tracking) → 
  → Inject listener into iframe (if needed) → 
  → postMessage('azgaar_params', {params, seed}) → 
  → iframe listener applies to azgaar.options → 
  → postMessage('azgaar_generate') → 
  → iframe listener calls azgaar.generate()
```

### Proposed Direct Access Flow
```
User changes slider → Alpine.js updateParam() → 
  → Directly update azgaar.options[key] = value → 
  → (No IPC, no postMessage, no Godot)

User clicks Generate → Alpine.js generate() → 
  → IPC to Godot (for progress tracking only) → 
  → Directly call azgaar.generate() → 
  → (No postMessage, no listener injection)
```

---

**Report Generated:** 2025-01-20  
**Status:** Investigation Complete - Awaiting Implementation Decision
