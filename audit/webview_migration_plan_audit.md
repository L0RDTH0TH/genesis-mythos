# WebView Migration Plan – Genesis Mythos UI System
## Investigation & Planning Report

**Date:** 2025-12-26  
**Status:** INVESTIGATION PHASE (No Changes Made)  
**Goal:** Migrate all Godot native UI to JavaScript-based UIs embedded via godot_wry WebViews

---

## Executive Summary

This document outlines a comprehensive investigation and migration plan for replacing Godot's native Control-based UI system with JavaScript/HTML/CSS UIs rendered in godot_wry WebViews. The migration is inspired by the smooth performance observed with Azgaar's WebView integration and aims to address current UI performance bottlenecks while maintaining full functionality.

**Key Findings:**
- **Current UI Inventory:** 25+ UI scenes, 30+ UI scripts, complex dependency chains
- **Performance Issues:** ~1900 objects, 8-9 level nesting, dynamic node creation/destruction
- **Existing WebView Integration:** Successful Azgaar integration provides proven communication patterns
- **Migration Complexity:** High – requires careful phased approach with fallback strategies

---

## 1. Current UI Inventory

### 1.1 UI Scenes (.tscn files)

| Scene Path | Purpose | Complexity | Dependencies |
|------------|---------|------------|--------------|
| `scenes/MainMenu.tscn` | Main menu with navigation buttons | Low | MainMenuController.gd |
| `ui/world_builder/WorldBuilderUI.tscn` | 8-step wizard for world generation | **Very High** | WorldBuilderUI.gd, WorldBuilderAzgaar.gd, AzgaarIntegrator |
| `scenes/character_creation/CharacterCreationRoot.tscn` | Character creation wizard root | High | CharacterCreationRoot.gd, 6 tab scenes |
| `scenes/character_creation/tabs/RaceTab.tscn` | Race selection tab | Medium | RaceTab.gd, JSON data |
| `scenes/character_creation/tabs/ClassTab.tscn` | Class selection tab | Medium | ClassTab.gd, JSON data |
| `scenes/character_creation/tabs/BackgroundTab.tscn` | Background selection tab | Medium | BackgroundTab.gd, JSON data |
| `scenes/character_creation/tabs/AbilityScoreTab.tscn` | Ability score point-buy tab | High | AbilityScoreTab.gd, AbilityScoreRow.gd |
| `scenes/character_creation/tabs/AppearanceTab.tscn` | Appearance customization tab | Medium | AppearanceTab.gd, 3D preview |
| `scenes/character_creation/tabs/NameConfirmTab.tscn` | Final confirmation tab | Low | NameConfirmTab.gd |
| `scenes/ui/overlays/PerformanceMonitor.tscn` | Performance overlay (FPS, graphs) | **Very High** | PerformanceMonitor.gd, GraphControl.gd, WaterfallControl.gd |
| `scenes/ui/DebugOverlay.tscn` | Debug information overlay | Low | (minimal) |
| `scenes/ui/progress_dialog.tscn` | Progress dialog for long operations | Low | progress_dialog.gd |
| `ui/components/ParameterRow.tscn` | Reusable parameter control row | Low | ParameterRow.gd |
| `ui/components/AbilityScoreRow.tscn` | Ability score row with +/- buttons | Medium | AbilityScoreRow.gd, PlayerData singleton |

**Total:** 13+ UI scenes identified

### 1.2 UI Scripts (.gd files)

| Script Path | Purpose | Lines | Key Dependencies |
|-------------|---------|-------|------------------|
| `scripts/ui/UIConstants.gd` | Semantic UI sizing constants | 111 | (class_name, no dependencies) |
| `ui/world_builder/WorldBuilderUI.gd` | World builder wizard controller | 745 | WorldBuilderAzgaar, AzgaarIntegrator, UIConstants, JSON config |
| `scripts/ui/WorldBuilderAzgaar.gd` | WebView integration for Azgaar | 384 | godot_wry WebView, AzgaarIntegrator, IPC communication |
| `scripts/managers/AzgaarIntegrator.gd` | Azgaar asset bundling/copying | 123 | FileAccess, DirAccess |
| `scripts/managers/AzgaarServer.gd` | Embedded HTTP server for Azgaar | 295 | TCPServer, StreamPeerTCP |
| `ui/main_menu/main_menu_controller.gd` | Main menu navigation | 124 | Scene transitions |
| `scripts/character_creation/CharacterCreationRoot.gd` | Character creation root controller | 312 | 6 tab scenes, 3D preview, signals |
| `scripts/character_creation/tabs/BaseTab.gd` | Base class for character tabs | ~50 | (base class) |
| `scripts/character_creation/tabs/RaceTab.gd` | Race selection logic | ~100 | JSON data, signals |
| `scripts/character_creation/tabs/ClassTab.gd` | Class selection logic | ~100 | JSON data, signals |
| `scripts/character_creation/tabs/BackgroundTab.gd` | Background selection logic | ~100 | JSON data, signals |
| `scripts/character_creation/tabs/AbilityScoreTab.gd` | Ability score point-buy logic | ~150 | AbilityScoreRow, PlayerData |
| `scripts/character_creation/tabs/AppearanceTab.gd` | Appearance customization logic | ~100 | 3D preview updates |
| `scripts/character_creation/tabs/NameConfirmTab.gd` | Final confirmation logic | ~80 | Character data summary |
| `scripts/ui/progress_dialog.gd` | Progress dialog controller | 57 | UIConstants |
| `scripts/ui/overlays/PerformanceMonitor.gd` | Performance overlay controller | 975 | GraphControl, WaterfallControl, RenderingServer API |
| `scripts/ui/overlays/GraphControl.gd` | Graph rendering control | ~200 | Custom drawing |
| `scripts/ui/overlays/WaterfallControl.gd` | Waterfall view control | ~300 | Custom drawing |
| `scripts/ui/overlays/FlameGraphControl.gd` | Flame graph control | ~200 | Custom drawing |
| `ui/components/ParameterRow.gd` | Parameter control row | ~100 | UIConstants |
| `ui/components/AbilityScoreRow.gd` | Ability score row | 147 | PlayerData, UIConstants |

**Total:** 20+ UI scripts identified

### 1.3 UI-Related Managers & Singletons

| Component | Purpose | Dependencies |
|-----------|---------|--------------|
| `AzgaarIntegrator` (singleton) | Manages Azgaar bundle copying to `user://azgaar/` | FileAccess, DirAccess |
| `AzgaarServer` (singleton) | Embedded HTTP server serving Azgaar files | TCPServer, StreamPeerTCP |
| `UIConstants` (class_name) | Semantic UI sizing constants | (standalone) |
| `bg3_theme.tres` | Central theme resource | (theme resource) |

### 1.4 Data Dependencies

| Data Source | Used By | Format |
|-------------|---------|--------|
| `res://data/races.json` | CharacterCreation (RaceTab) | JSON |
| `res://data/classes.json` | CharacterCreation (ClassTab) | JSON |
| `res://data/backgrounds.json` | CharacterCreation (BackgroundTab) | JSON |
| `res://data/abilities.json` | CharacterCreation (AbilityScoreTab) | JSON |
| `res://data/config/azgaar_step_parameters.json` | WorldBuilderUI | JSON |
| `res://data/fantasy_archetypes.json` | WorldBuilderUI | JSON |

---

## 2. Current UI System Analysis

### 2.1 Performance Hotspots

**Identified Issues (from audit reports):**

1. **WorldBuilderUI.tscn:**
   - **Node Count:** ~1900 objects, ~1514 CanvasItem primitives
   - **Nesting Depth:** 8-9 levels
   - **Dynamic Creation:** 18-30 Control nodes created/destroyed per step switch
   - **Theme Overrides:** Per-node theme overrides breaking render batching
   - **Current FPS:** ~5-7 FPS (target: 60 FPS)

2. **PerformanceMonitor.tscn:**
   - **Complexity:** Multiple graphs, waterfall view, flame graph
   - **Update Frequency:** Every frame (`_process()` enabled)
   - **Custom Drawing:** GraphControl, WaterfallControl use `_draw()` extensively

3. **CharacterCreationRoot.tscn:**
   - **Tab Switching:** Loads/unloads entire tab scenes
   - **3D Preview:** SubViewport with 3D rendering (may conflict with WebView)

### 2.2 UI-Backend Communication Patterns

**Current Patterns:**

1. **Signals:** UI scripts emit signals (e.g., `race_selected`, `generation_complete`)
2. **Direct Method Calls:** UI scripts call backend methods (e.g., `WorldStreamer`, `EntitySim`)
3. **Singleton Access:** UI scripts access singletons (e.g., `PlayerData`, `AzgaarIntegrator`)
4. **JSON Data Loading:** UI scripts load JSON files directly via `FileAccess`
5. **3D Preview Updates:** CharacterCreation updates 3D preview via `SubViewport`

**Key Dependencies:**
- `WorldStreamer` (core singleton) – world generation/streaming
- `EntitySim` (core singleton) – entity simulation
- `PlayerData` (singleton) – character data storage
- `MythosLogger` (singleton) – logging
- `AzgaarIntegrator` (singleton) – Azgaar asset management
- `AzgaarServer` (singleton) – HTTP server for Azgaar

### 2.3 Existing godot_wry Integration

**Current Implementation (WorldBuilderAzgaar.gd):**

**WebView Node:**
- Type: `WebView` (from godot_wry addon)
- Location: `WorldBuilderUI.tscn` → `CenterContent/WebViewMargin/AzgaarWebView`
- Initialization: `_initialize_webview()` called on `_ready()`

**Communication Methods:**

1. **Godot → JavaScript:**
   - `web_view.execute_js(code: String) -> Variant` – Execute JS code, returns result
   - `web_view.eval(code: String) -> Variant` – Alternative execution method
   - `web_view.post_message(message: String)` – Send message to JS (fallback)

2. **JavaScript → Godot:**
   - `web_view.ipc_message` signal – Receives messages from JS
   - Message format: JSON string (parsed in `_on_ipc_message()`)

**Bridge Script Pattern:**
```javascript
// Injected into Azgaar WebView
window.godot.postMessage = function(message) {
    if (window.godot && window.godot.ipc) {
        window.godot.ipc.postMessage(JSON.stringify(message));
    }
};
```

**URL Loading:**
- HTTP server: `http://127.0.0.1:8080/index.html` (via `AzgaarServer`)
- Fallback: `file://` URL (via `AzgaarIntegrator.get_azgaar_url()`)

**Known Limitations:**
- WebView presentation throttling (~5 Hz) when idle (addon limitation)
- Requires embedded HTTP server or file:// URLs
- JavaScript execution is synchronous (blocks until completion)

---

## 3. Proposed Migration Plan

### 3.1 High-Level Strategy

**Phased Approach:**

1. **Phase 1: Foundation** (Low Risk)
   - Create `res://web_ui/` folder structure
   - Set up build pipeline for JS/HTML/CSS bundles
   - Create communication bridge library (JS ↔ GDScript)
   - Migrate simple UIs (MainMenu, ProgressDialog)

2. **Phase 2: Wizards** (Medium Risk)
   - Migrate WorldBuilderUI (8-step wizard)
   - Migrate CharacterCreationRoot (6-step wizard)
   - Test with full data loading and 3D preview integration

3. **Phase 3: Overlays & HUD** (High Risk)
   - Migrate PerformanceMonitor (complex graphs)
   - Migrate DebugOverlay
   - Test with in-game 3D world active

4. **Phase 4: Polish & Optimization** (Ongoing)
   - Performance tuning
   - Responsive layout testing
   - Fallback strategies for edge cases

### 3.2 Folder Structure

**Proposed Structure:**

```
res://web_ui/
├── main_menu/
│   ├── index.html
│   ├── main.js
│   └── styles.css
├── world_builder/
│   ├── index.html
│   ├── main.js
│   ├── styles.css
│   └── components/
│       ├── step-navigation.js
│       ├── parameter-controls.js
│       └── preview-container.js
├── character_creation/
│   ├── index.html
│   ├── main.js
│   ├── styles.css
│   └── tabs/
│       ├── race-tab.js
│       ├── class-tab.js
│       └── ...
├── overlays/
│   ├── performance/
│   │   ├── index.html
│   │   ├── main.js
│   │   └── styles.css
│   └── debug/
│       ├── index.html
│       └── main.js
├── shared/
│   ├── bridge.js          # Communication bridge library
│   ├── theme.css          # Shared theme styles
│   └── utils.js           # Shared utilities
└── build/                 # Built bundles (if using build tool)
    └── ...
```

**Alternative (Single Bundle Approach):**
```
res://web_ui/
├── bundle/
│   ├── index.html         # Router page
│   ├── main.js            # Main app with routing
│   ├── styles.css         # Global styles
│   └── pages/
│       ├── main-menu.js
│       ├── world-builder.js
│       └── character-creation.js
└── shared/
    └── bridge.js
```

**Recommendation:** Start with **separate bundles** (easier to test/debug), migrate to **single bundle** later if needed.

### 3.3 Communication Architecture

**Bridge Library (`web_ui/shared/bridge.js`):**

```javascript
// Godot Bridge API
window.GodotBridge = {
    // Send message to Godot
    postMessage: function(type, data) {
        if (window.godot && window.godot.ipc) {
            window.godot.ipc.postMessage(JSON.stringify({
                type: type,
                data: data,
                timestamp: Date.now()
            }));
        }
    },
    
    // Request data from Godot (async)
    requestData: function(endpoint, callback) {
        var requestId = Math.random().toString(36);
        window.GodotBridge._pendingRequests[requestId] = callback;
        window.GodotBridge.postMessage('request_data', {
            request_id: requestId,
            endpoint: endpoint
        });
    },
    
    // Call Godot function (async)
    callFunction: function(functionName, args, callback) {
        var requestId = Math.random().toString(36);
        window.GodotBridge._pendingRequests[requestId] = callback;
        window.GodotBridge.postMessage('call_function', {
            request_id: requestId,
            function_name: functionName,
            arguments: args
        });
    },
    
    _pendingRequests: {}
};

// Handle messages from Godot
window.addEventListener('message', function(event) {
    if (event.data && typeof event.data === 'string') {
        try {
            var message = JSON.parse(event.data);
            if (message.type === 'response' && message.request_id) {
                var callback = window.GodotBridge._pendingRequests[message.request_id];
                if (callback) {
                    callback(message.data);
                    delete window.GodotBridge._pendingRequests[message.request_id];
                }
            } else if (message.type === 'update') {
                // Handle push updates from Godot
                window.GodotBridge._handleUpdate(message.data);
            }
        } catch (e) {
            console.error('Failed to parse message from Godot:', e);
        }
    }
});
```

**GDScript Bridge Handler:**

```gdscript
# scripts/ui/WebViewBridge.gd
class_name WebViewBridge
extends Node

signal ui_event_received(event_type: String, data: Dictionary)

var web_view: Node = null
var pending_requests: Dictionary = {}

func _ready() -> void:
    """Initialize bridge."""
    pass

func connect_webview(webview: Node) -> void:
    """Connect to a WebView node."""
    web_view = webview
    if web_view.has_signal("ipc_message"):
        web_view.ipc_message.connect(_on_ipc_message)

func _on_ipc_message(message: String) -> void:
    """Handle IPC messages from WebView."""
    var json = JSON.new()
    if json.parse(message) != OK:
        return
    
    var data = json.data
    if not data is Dictionary:
        return
    
    var event_type: String = data.get("type", "")
    var event_data: Dictionary = data.get("data", {})
    
    match event_type:
        "request_data":
            _handle_data_request(event_data)
        "call_function":
            _handle_function_call(event_data)
        _:
            emit_signal("ui_event_received", event_type, event_data)

func _handle_data_request(request: Dictionary) -> void:
    """Handle data request from JS."""
    var request_id: String = request.get("request_id", "")
    var endpoint: String = request.get("endpoint", "")
    
    # Load data (e.g., from JSON file)
    var data = _load_data(endpoint)
    
    # Send response
    _send_response(request_id, data)

func _handle_function_call(request: Dictionary) -> void:
    """Handle function call from JS."""
    var request_id: String = request.get("request_id", "")
    var function_name: String = request.get("function_name", "")
    var args: Array = request.get("arguments", [])
    
    # Call GDScript function (e.g., on singleton)
    var result = _call_godot_function(function_name, args)
    
    # Send response
    _send_response(request_id, result)

func _send_response(request_id: String, data: Variant) -> void:
    """Send response to JS."""
    if not web_view:
        return
    
    var message = JSON.stringify({
        "type": "response",
        "request_id": request_id,
        "data": data
    })
    
    if web_view.has_method("post_message"):
        web_view.post_message(message)

func send_update(update_type: String, data: Dictionary) -> void:
    """Push update to JS (Godot-initiated)."""
    if not web_view:
        return
    
    var message = JSON.stringify({
        "type": "update",
        "update_type": update_type,
        "data": data
    })
    
    if web_view.has_method("post_message"):
        web_view.post_message(message)
```

### 3.4 JavaScript Framework Recommendations

**Options:**

1. **Vanilla JavaScript** (Recommended for Phase 1)
   - **Pros:** No dependencies, small bundle size, full control
   - **Cons:** More boilerplate, manual state management
   - **Use Case:** Simple UIs (MainMenu, ProgressDialog)

2. **Alpine.js** (Recommended for Phase 2)
   - **Pros:** Lightweight (~15KB), declarative, reactive
   - **Cons:** Limited for complex state
   - **Use Case:** Wizards (WorldBuilderUI, CharacterCreation)

3. **Svelte** (Consider for Phase 3)
   - **Pros:** Compile-time optimization, reactive, component-based
   - **Cons:** Requires build step, larger bundle
   - **Use Case:** Complex UIs (PerformanceMonitor with graphs)

4. **React/Vue** (Not Recommended)
   - **Pros:** Mature, feature-rich
   - **Cons:** Large bundle size, overkill for embedded UIs

**Recommendation:** Start with **Vanilla JS** for Phase 1, evaluate **Alpine.js** for Phase 2, consider **Svelte** for Phase 3 if needed.

### 3.5 Responsive Layout Strategy

**CSS-Based Responsiveness:**

```css
/* web_ui/shared/theme.css */
:root {
    --button-height-small: 50px;
    --button-height-medium: 80px;
    --button-height-large: 120px;
    --spacing-small: 10px;
    --spacing-medium: 20px;
    --spacing-large: 40px;
    --panel-width-nav: 250px;
    --panel-width-content: 300px;
}

/* Responsive breakpoints */
@media (max-width: 1920px) {
    :root {
        --button-height-medium: 70px;
    }
}

@media (max-width: 1280px) {
    :root {
        --button-height-medium: 60px;
    }
}

/* Use CSS Grid/Flexbox for layouts */
.main-container {
    display: grid;
    grid-template-columns: var(--panel-width-nav) 1fr var(--panel-width-content);
    gap: var(--spacing-medium);
    height: 100vh;
}
```

**Viewport Size Updates:**

```javascript
// Update on resize
window.addEventListener('resize', function() {
    window.GodotBridge.postMessage('viewport_resize', {
        width: window.innerWidth,
        height: window.innerHeight
    });
});
```

**GDScript Handler:**

```gdscript
func _on_viewport_resize(data: Dictionary) -> void:
    """Handle viewport resize from JS."""
    var width: int = data.get("width", 1920)
    var height: int = data.get("height", 1080)
    # Update WebView size if needed
    if web_view:
        web_view.size = Vector2i(width, height)
```

### 3.6 3D Preview Integration

**Challenge:** CharacterCreation uses `SubViewport` for 3D preview. WebView cannot directly render 3D.

**Solutions:**

1. **Render to Texture (Recommended):**
   - Render 3D preview to `ViewportTexture`
   - Send texture data to WebView as base64 image
   - Update periodically (e.g., every 0.1s or on appearance change)

```gdscript
# In CharacterCreationRoot.gd
func _update_preview_texture() -> void:
    """Render 3D preview to texture and send to WebView."""
    var viewport: SubViewport = preview_viewport
    await RenderingServer.frame_post_draw
    
    var image: Image = viewport.get_texture().get_image()
    var png_bytes: PackedByteArray = image.save_png_to_buffer()
    var base64: String = Marshalls.raw_to_base64(png_bytes)
    
    # Send to WebView
    web_view_bridge.send_update("preview_texture", {
        "image_data": "data:image/png;base64," + base64
    })
```

```javascript
// In character-creation.js
window.GodotBridge._handleUpdate = function(data) {
    if (data.update_type === 'preview_texture') {
        var img = document.getElementById('preview-image');
        img.src = data.image_data;
    }
};
```

2. **Separate Window (Alternative):**
   - Keep 3D preview in native Godot window
   - WebView UI communicates via bridge
   - Less seamless but simpler

**Recommendation:** Use **Render to Texture** approach for seamless integration.

### 3.7 Performance Considerations

**WebView Overhead:**

- **Memory:** Each WebView instance consumes ~50-100MB RAM
- **CPU:** JavaScript execution adds ~1-5ms per frame (depending on complexity)
- **Rendering:** WebView rendering is separate from Godot's renderer (may cause sync issues)

**Optimization Strategies:**

1. **Lazy Loading:** Only load WebView when UI is opened
2. **Single WebView Instance:** Reuse one WebView for all UIs (router pattern)
3. **Throttle Updates:** Limit update frequency (e.g., 30 FPS for non-critical UIs)
4. **Minimize JS Execution:** Cache data, batch updates
5. **WebView Pooling:** Reuse WebView instances (if multiple needed)

**Target Metrics:**
- **Memory:** <200MB per active WebView
- **CPU:** <5ms per frame for UI updates
- **FPS:** Maintain 60 FPS with WebView active

### 3.8 Fallback Strategies

**Hybrid Approach (Recommended):**

1. **Keep Native for Critical UIs:**
   - PerformanceMonitor (complex graphs may not translate well)
   - DebugOverlay (low overhead, native is fine)

2. **WebView for Wizards/Menus:**
   - MainMenu
   - WorldBuilderUI
   - CharacterCreationRoot

3. **Gradual Migration:**
   - Start with simple UIs
   - Migrate complex UIs only if performance improves
   - Keep native fallback for each UI

**Error Handling:**

```gdscript
# In WebViewBridge.gd
func _on_webview_error(error: String) -> void:
    """Handle WebView errors."""
    MythosLogger.error("WebViewBridge", "WebView error: %s" % error)
    # Fallback to native UI
    _fallback_to_native_ui()
```

---

## 4. Migration Phases

### Phase 1: Foundation (Week 1-2)

**Goals:**
- Set up `res://web_ui/` folder structure
- Create bridge library (`bridge.js`, `WebViewBridge.gd`)
- Migrate MainMenu (simple, low risk)
- Test communication patterns

**Deliverables:**
- `res://web_ui/main_menu/` bundle
- `scripts/ui/WebViewBridge.gd`
- `scripts/ui/MainMenuWebView.gd` (wrapper)
- Documentation

**Success Criteria:**
- MainMenu loads in WebView
- Buttons trigger scene transitions
- No performance regression

### Phase 2: Wizards (Week 3-5)

**Goals:**
- Migrate WorldBuilderUI (8-step wizard)
- Migrate CharacterCreationRoot (6-step wizard)
- Integrate with existing data sources (JSON)
- Test 3D preview integration

**Deliverables:**
- `res://web_ui/world_builder/` bundle
- `res://web_ui/character_creation/` bundle
- Updated `WorldBuilderWebView.gd`
- Updated `CharacterCreationWebView.gd`

**Success Criteria:**
- Wizards function identically to native versions
- Data loading works (JSON files)
- 3D preview updates in WebView
- Performance equal or better than native

### Phase 3: Overlays (Week 6-7)

**Goals:**
- Evaluate PerformanceMonitor migration (may keep native)
- Migrate DebugOverlay (if beneficial)
- Test with full 3D world active

**Deliverables:**
- `res://web_ui/overlays/` bundles (if migrated)
- Performance comparison report

**Success Criteria:**
- Overlays work with 3D world active
- No FPS drops
- Maintain 60 FPS target

### Phase 4: Polish (Week 8+)

**Goals:**
- Performance optimization
- Responsive layout testing (multiple resolutions)
- Error handling improvements
- Documentation

**Deliverables:**
- Performance report
- Responsive layout test results
- Migration documentation

---

## 5. Risks & Mitigation

### 5.1 Compatibility Risks

**Risk:** godot_wry addon compatibility issues
- **Mitigation:** Test on all target platforms (Windows, Linux, macOS)
- **Fallback:** Keep native UI as backup

**Risk:** WebView rendering conflicts with 3D
- **Mitigation:** Use Render to Texture for 3D previews
- **Fallback:** Separate window for 3D preview

### 5.2 Performance Risks

**Risk:** WebView overhead causes FPS drops
- **Mitigation:** Lazy loading, single WebView instance, throttling
- **Fallback:** Hybrid approach (native for critical UIs)

**Risk:** JavaScript execution blocks main thread
- **Mitigation:** Async patterns, batch updates
- **Fallback:** Native UI for time-critical operations

### 5.3 Data Integration Risks

**Risk:** JSON data loading from WebView
- **Mitigation:** Bridge library handles data requests
- **Fallback:** Pre-load data in GDScript, send to JS

**Risk:** Save/load system compatibility
- **Mitigation:** Bridge handles save/load requests
- **Fallback:** Native save/load dialogs

### 5.4 Multiplayer Risks

**Risk:** WebView UI doesn't work in multiplayer
- **Mitigation:** Test with multiplayer networking
- **Fallback:** Native UI for multiplayer sessions

---

## 6. Questions & Clarifications Needed

1. **3D Preview Strategy:**
   - Prefer Render to Texture or separate window?
   - Update frequency for preview texture?

2. **PerformanceMonitor Migration:**
   - Should complex graphs (waterfall, flame) remain native?
   - Or migrate with canvas-based rendering in JS?

3. **Build Pipeline:**
   - Use build tool (Vite, Webpack) or plain JS/CSS?
   - Bundle size targets?

4. **Theme Migration:**
   - Convert `bg3_theme.tres` to CSS?
   - Or maintain separate theme systems?

5. **Testing Strategy:**
   - Automated tests for WebView UIs?
   - Manual testing checklist?

---

## 7. Next Steps

1. **Review & Approval:**
   - Review this plan with team
   - Get approval for Phase 1

2. **Phase 1 Implementation:**
   - Create folder structure
   - Implement bridge library
   - Migrate MainMenu

3. **Testing:**
   - Test communication patterns
   - Measure performance impact
   - Document findings

4. **Iterate:**
   - Adjust plan based on Phase 1 results
   - Proceed to Phase 2 if successful

---

## Appendix A: File Inventory Summary

**UI Scenes:** 13+ scenes  
**UI Scripts:** 20+ scripts  
**Managers:** 4 singletons/managers  
**Data Files:** 6+ JSON files  
**Theme:** 1 theme resource (`bg3_theme.tres`)

**Total Estimated Migration Scope:** ~40 files to migrate or adapt

---

## Appendix B: godot_wry Capabilities Reference

**Methods:**
- `load_url(url: String)` – Load URL
- `execute_js(code: String) -> Variant` – Execute JS, return result
- `eval(code: String) -> Variant` – Alternative execution
- `post_message(message: String)` – Send message to JS
- `reload()` – Reload current URL

**Signals:**
- `ipc_message(message: String)` – Receive messages from JS

**Properties:**
- `url: String` – Current URL
- `size: Vector2i` – WebView size
- `visible: bool` – Visibility

---

**END OF REPORT**

