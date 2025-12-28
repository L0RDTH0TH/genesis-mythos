# Azgaar Map Web Viewer Current State Audit
**Date:** 2025-01-20  
**Purpose:** Document current state of Azgaar map web viewer integration in World Builder UI  
**Status:** Investigation Complete - Audit Only (No Modifications)

---

## Executive Summary

The Azgaar map web viewer integration is **currently in a disconnected state**:
- The `WorldBuilderAzgaar.gd` script expects a WebView node structure (`WebViewMargin/AzgaarWebView`) that **does not exist** in the current scene files
- The HTML template (`world_builder.html`) contains only a **placeholder div** for the Azgaar preview, with no actual WebView embedding
- The `DEBUG_DISABLE_AZGAAR` flag is set to `false` (enabled), but the script cannot find the expected node structure
- The current architecture uses a **single WebView** that loads the HTML/JS UI template, with the Azgaar map intended to be embedded within that HTML (but not yet implemented)

---

## 1. Current Scene Setup

### 1.1 Primary Scene Files

**File:** `res://scenes/ui/WorldBuilderUI.tscn`  
**File:** `res://ui/world_builder/WorldBuilderWeb.tscn`  
*(Both files are identical)*

**Scene Structure:**
```
WorldBuilderWebRoot (Control)
├── layout_mode = 3 (PRESET_FULL_RECT)
├── anchors_preset = 15 (FULL_RECT)
├── anchor_right = 1.0
├── anchor_bottom = 1.0
├── grow_horizontal = 2
├── grow_vertical = 2
├── theme = res://themes/bg3_theme.tres
├── script = res://scripts/ui/WorldBuilderWebController.gd
└── WebView (godot_wry WebView)
    ├── layout_mode = 1 (FULL_RECT)
    ├── anchors_preset = 15 (FULL_RECT)
    ├── anchor_right = 1.0
    ├── anchor_bottom = 1.0
    ├── grow_horizontal = 2
    └── grow_vertical = 2
```

**Node Count:** 2 nodes (root Control + WebView)  
**Attached Script:** `WorldBuilderWebController.gd`

**Key Observations:**
- ✅ Single WebView node that loads the HTML/JS UI template
- ❌ **No separate Azgaar WebView node exists in the scene**
- ❌ **No `WebViewMargin` container node exists**
- ❌ **No `AzgaarWebView` node exists**

---

## 2. WebView Node Details

### 2.1 WorldBuilderWebController WebView

**Node Path:** `WorldBuilderWebRoot/WebView`  
**Node Type:** `WebView` (godot_wry)  
**Node Name:** `WebView`

**Properties:**
- **Layout:** Full rect (anchors_preset = 15, layout_mode = 1)
- **Sizing:** Anchors set to fill entire parent (anchor_right = 1.0, anchor_bottom = 1.0)
- **Grow Flags:** Both horizontal and vertical set to 2 (expand)
- **Visibility:** Not explicitly set (defaults to visible)
- **Enabled:** Not explicitly set (defaults to enabled)

**Loaded URL:**
- `res://assets/ui_web/templates/world_builder.html`

**Script Reference:**
- Accessed via `@onready var web_view: WebView = $WebView` in `WorldBuilderWebController.gd`

### 2.2 Expected Azgaar WebView (Not Present)

**Expected Node Path:** `WebViewMargin/AzgaarWebView`  
**Expected Node Type:** `WebView` (godot_wry)  
**Expected Container:** `WebViewMargin` (likely a MarginContainer or Control)

**Status:** ❌ **This node structure does not exist in any scene file**

**Script Expectations (from `WorldBuilderAzgaar.gd`):**
```gdscript
var web_view_node = get_node_or_null("WebViewMargin/AzgaarWebView")
```

**Impact:** The `WorldBuilderAzgaar.gd` script will fail to find this node and log an error:
```
"AzgaarWebView node not found in scene tree"
```

---

## 3. Script Logic

### 3.1 WorldBuilderWebController.gd

**Location:** `res://scripts/ui/WorldBuilderWebController.gd`  
**Purpose:** Manages the main WebView that loads the HTML/JS UI template

**Key Functions:**
- `_ready()`: Loads `world_builder.html`, connects IPC signals, finds `WorldBuilderAzgaar` in scene tree
- `_find_azgaar_controller()`: Searches scene tree for nodes with `WorldBuilderAzgaar` script (will not find any in current setup)
- `_on_ipc_message()`: Handles IPC messages from the HTML/JS UI
- `_handle_generate()`: Forwards generation requests to `WorldBuilderAzgaar` (if found)

**IPC Communication:**
- Listens for: `alpine_ready`, `set_step`, `load_archetype`, `set_seed`, `update_param`, `generate`, `request_data`
- Sends: Step definitions, archetypes, parameter updates, progress updates

**Azgaar Integration:**
- Attempts to find `WorldBuilderAzgaar` node in scene tree via script search
- If found, connects to `trigger_generation_with_options()` method
- Currently will **not find** the Azgaar controller (no node with that script exists in scene)

### 3.2 WorldBuilderAzgaar.gd

**Location:** `res://scripts/ui/WorldBuilderAzgaar.gd`  
**Purpose:** Controls Azgaar WebView embedding and communication (when node structure exists)

**Key Constants:**
```gdscript
const DEBUG_DISABLE_AZGAAR := false  # Currently ENABLED
```

**Key Functions:**
- `_initialize_webview()`: Looks for `WebViewMargin/AzgaarWebView` node
  - If `DEBUG_DISABLE_AZGAAR == true`: Removes WebView node, hides WebViewMargin
  - If `DEBUG_DISABLE_AZGAAR == false`: Attempts to load Azgaar URL
- `trigger_generation_with_options()`: Syncs parameters to Azgaar via JavaScript injection
- `_sync_parameters_to_azgaar()`: Executes JS to set Azgaar options
- `export_heightmap()`: Extracts heightmap data from Azgaar via JS

**Node Path Expectations:**
```gdscript
var web_view_node = get_node_or_null("WebViewMargin/AzgaarWebView")
var web_view_margin = get_node_or_null("WebViewMargin")
```

**Current Behavior:**
- Script expects node at path `WebViewMargin/AzgaarWebView`
- **This path does not exist** in current scene files
- Script will log error: `"AzgaarWebView node not found in scene tree"`
- Script will return early from `_initialize_webview()` without loading Azgaar

**Visibility Control:**
- If `DEBUG_DISABLE_AZGAAR == true`, sets `web_view_margin.visible = false`
- Currently `DEBUG_DISABLE_AZGAAR == false`, but node doesn't exist anyway

**URL Loading:**
- Prefers HTTP URL via `AzgaarIntegrator.get_azgaar_http_url()` (embedded server)
- Falls back to `file://` URL via `AzgaarIntegrator.get_azgaar_url()`
- Loads via `web_view.load_url(url)`

**IPC Communication:**
- Connects to `web_view.ipc_message` signal
- Handles: `generation_complete`, `generation_failed`, `export_complete`
- Injects bridge script for bidirectional communication

---

## 4. HTML/JS Integration

### 4.1 World Builder HTML Template

**File:** `res://assets/ui_web/templates/world_builder.html`

**Structure:**
```html
<div class="world-builder-container" x-data="worldBuilder">
    <!-- Top Bar -->
    <div class="top-bar">...</div>
    
    <!-- Main Content Area -->
    <div class="main-hsplit">
        <!-- Left Panel: Numbered Tab Bar -->
        <div class="left-tabs-panel">...</div>
        
        <!-- Center Panel: Azgaar Preview (placeholder) -->
        <div class="center-panel">
            <div id="azgaar-container" class="azgaar-placeholder">
                <p>Azgaar Map Preview</p>
                <p class="placeholder-note">(Map preview will appear here)</p>
            </div>
        </div>
        
        <!-- Right Panel: Parameters -->
        <div class="right-panel">...</div>
    </div>
</div>
```

**Key Observations:**
- ✅ Center panel exists with `id="azgaar-container"`
- ❌ **No actual WebView embedding** - only a placeholder div
- ❌ **No iframe or embedded WebView** for Azgaar
- ❌ **No JavaScript code** to load/embed Azgaar map

### 4.2 CSS Styling

**File:** `res://assets/ui_web/css/world_builder.css`

**Center Panel Styles:**
```css
.center-panel {
    flex: 1;
    min-width: 0;
    background-color: var(--bg-dark);
    display: flex;
    align-items: center;
    justify-content: center;
    border-left: 1px solid rgba(255, 215, 0, 0.3);
    border-right: 1px solid rgba(255, 215, 0, 0.3);
}

.azgaar-placeholder {
    text-align: center;
    color: var(--font-color-gold);
    opacity: 0.5;
}
```

**Key Observations:**
- Center panel uses flexbox layout (flex: 1, takes remaining space)
- Placeholder is centered with reduced opacity
- **No styles for embedded WebView or iframe**

### 4.3 JavaScript Integration

**File:** `res://assets/ui_web/js/world_builder.js`

**Current State:**
- Alpine.js component `worldBuilder` manages UI state
- **No code to embed or communicate with Azgaar WebView**
- **No iframe creation or WebView embedding logic**

---

## 5. Visibility & Sizing Observations

### 5.1 WorldBuilderWebController WebView

**Visibility:** ✅ Visible (default, not explicitly set to false)  
**Enabled:** ✅ Enabled (default, not explicitly set to false)  
**Sizing:** Full rect via anchors (fills entire parent Control)

**Layout Behavior:**
- Anchors set to fill parent (anchor_right = 1.0, anchor_bottom = 1.0)
- Grow flags set to expand (grow_horizontal = 2, grow_vertical = 2)
- Automatically resizes with window (handled by anchors)

### 5.2 Expected Azgaar WebView (Not Present)

**Visibility:** N/A (node doesn't exist)  
**Sizing:** N/A (node doesn't exist)

**Expected Behavior (if node existed):**
- Would be wrapped in `WebViewMargin` container
- Would be sized by parent container
- Visibility controlled by `WorldBuilderAzgaar.gd` script (currently would be visible if `DEBUG_DISABLE_AZGAAR == false`)

### 5.3 HTML Center Panel

**CSS Sizing:**
- `flex: 1` - Takes remaining space after left/right panels
- `min-width: 0` - Allows flex shrinking
- Centered placeholder content

**Current Display:**
- Shows placeholder text: "Azgaar Map Preview" and "(Map preview will appear here)"
- Styled with gold color and 50% opacity

---

## 6. Potential Issues Noted

### 6.1 Missing Node Structure

**Issue:** `WorldBuilderAzgaar.gd` expects `WebViewMargin/AzgaarWebView` node structure that doesn't exist

**Impact:**
- Script fails to initialize Azgaar WebView
- Error logged: `"AzgaarWebView node not found in scene tree"`
- Generation requests from HTML UI will fail (no Azgaar controller found)

**Evidence:**
```gdscript
# scripts/ui/WorldBuilderAzgaar.gd:49
var web_view_node = get_node_or_null("WebViewMargin/AzgaarWebView")
if not web_view_node:
    MythosLogger.error("WorldBuilderAzgaar", "AzgaarWebView node not found in scene tree")
    return
```

### 6.2 Disconnected Architecture

**Issue:** Two separate systems that don't connect:
1. `WorldBuilderWebController` manages HTML/JS UI WebView
2. `WorldBuilderAzgaar` expects separate Azgaar WebView node (doesn't exist)

**Impact:**
- HTML UI can send generation requests, but no Azgaar WebView exists to handle them
- `WorldBuilderWebController._find_azgaar_controller()` will not find `WorldBuilderAzgaar` node
- Generation flow is broken

**Evidence:**
```gdscript
# scripts/ui/WorldBuilderWebController.gd:87
MythosLogger.warn("WorldBuilderWebController", "WorldBuilderAzgaar controller not found in scene tree")
```

### 6.3 Placeholder Only in HTML

**Issue:** HTML template contains only a placeholder div, no actual Azgaar embedding

**Impact:**
- Center panel shows placeholder text instead of map
- No visual feedback of map generation
- No way to preview map before export

**Evidence:**
```html
<!-- assets/ui_web/templates/world_builder.html:35-38 -->
<div id="azgaar-container" class="azgaar-placeholder">
    <p>Azgaar Map Preview</p>
    <p class="placeholder-note">(Map preview will appear here)</p>
</div>
```

### 6.4 DEBUG_DISABLE_AZGAAR Flag State

**Issue:** `DEBUG_DISABLE_AZGAAR = false` (enabled), but node structure doesn't exist anyway

**Impact:**
- Flag suggests Azgaar should be enabled, but it cannot function
- May cause confusion about intended state
- Script will attempt initialization but fail silently (after error log)

**Evidence:**
```gdscript
# scripts/ui/WorldBuilderAzgaar.gd:10
const DEBUG_DISABLE_AZGAAR := false  # Currently ENABLED
```

### 6.5 No Scene File Contains Azgaar WebView

**Issue:** Searched all `.tscn` files - none contain `WebViewMargin` or `AzgaarWebView` nodes

**Impact:**
- No scene file provides the expected node structure
- `WorldBuilderAzgaar.gd` script cannot function in current setup
- Would need to be added to scene or created programmatically

**Evidence:**
- `grep` search for `WorldBuilderAzgaar|AzgaarWebView|WebViewMargin` in `*.tscn` files returned **0 matches**

---

## 7. Summary of Current State

### 7.1 What Exists

✅ **WorldBuilderWebController WebView:**
- Single WebView node in `WorldBuilderWeb.tscn` / `WorldBuilderUI.tscn`
- Loads HTML/JS UI template (`world_builder.html`)
- Full rect sizing, visible and enabled
- IPC communication working

✅ **HTML Template:**
- Complete 8-step wizard UI with Alpine.js
- Center panel placeholder for Azgaar preview
- Responsive CSS layout

✅ **WorldBuilderAzgaar Script:**
- Complete script with all functionality
- `DEBUG_DISABLE_AZGAAR = false` (enabled)
- Ready to initialize WebView (if node existed)

### 7.2 What's Missing

❌ **Azgaar WebView Node:**
- No `WebViewMargin` container node
- No `AzgaarWebView` node
- No scene file contains these nodes

❌ **HTML Embedding:**
- No iframe or embedded WebView in HTML
- No JavaScript to load/embed Azgaar
- Only placeholder div exists

❌ **Scene Integration:**
- `WorldBuilderAzgaar.gd` script not attached to any node in current scenes
- No node structure for Azgaar WebView exists

### 7.3 Current Behavior

1. **WorldBuilderWebController** loads HTML/JS UI successfully
2. **HTML UI** displays with placeholder in center panel
3. **WorldBuilderAzgaar** script initialization fails (node not found)
4. **Generation requests** from HTML UI cannot be fulfilled (no Azgaar controller found)
5. **User sees** placeholder text instead of map preview

---

## 8. Architecture Notes

### 8.1 Intended Design (Inferred)

Based on code comments and structure, the intended design appears to be:

1. **Separate Azgaar WebView:** A second WebView node (separate from the HTML UI WebView) that loads the Azgaar map generator
2. **Layered Architecture:** HTML UI WebView on top, Azgaar WebView behind it (or embedded within HTML)
3. **Communication Bridge:** IPC messages between Godot scripts and both WebViews

### 8.2 Current Implementation Gap

The current implementation has:
- ✅ HTML UI WebView (working)
- ❌ Azgaar WebView (missing)
- ❌ Integration between them (missing)

The gap suggests either:
- Migration in progress (HTML UI migrated, Azgaar integration pending)
- Alternative approach planned (embed Azgaar within HTML instead of separate WebView)
- Implementation incomplete

---

**End of Audit Report**

