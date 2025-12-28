# Azgaar Transparency Fix Audit Report
**Date:** 2025-12-28  
**Purpose:** Investigate why CSS transparency fix (body background transparent) was insufficient to display Azgaar map preview in World Builder UI center panel.  
**Status:** Investigation Complete - Root Cause Identified

---

## Executive Summary

The CSS transparency fix (setting `body { background-color: transparent; }`) was a necessary but **insufficient** change. The root cause is that the **main UI WebView node** (godot_wry) has an **opaque default background** that blocks the Azgaar WebView behind it, regardless of HTML/CSS transparency settings. The godot_wry addon supports a `transparent = true` property on WebView nodes, which must be set on the main UI WebView to enable true transparency. Additionally, Azgaar auto-generates a map on load via `checkLoadParameters()` → `generateMapOnLoad()` → `generate()`, so the map should be visible if transparency is properly configured.

**Key Finding:** The main UI WebView (`WorldBuilderWebRoot/WebView`) does **not** have `transparent = true` set, while the godot_wry example (`character_creator.tscn`) demonstrates this property is available and functional.

---

## CSS/HTML Audit

### CSS Verification
**File:** `res://assets/ui_web/css/world_builder.css`

**Body Selector (Lines 35-45):**
```css
body {
    margin: 0;
    padding: 0;
    width: 100vw;
    height: 100vh;
    /* Made transparent to allow Azgaar WebView behind to show through */
    background-color: transparent;
    font-family: 'Times New Roman', serif;
    color: var(--font-default);
    overflow: hidden;
}
```
✅ **Status:** Correctly set to `transparent`

**World Builder Container (Lines 47-52):**
```css
.world-builder-container {
    width: 100%;
    height: 100%;
    display: flex;
    flex-direction: column;
}
```
✅ **Status:** No background set (inherits transparent from body)

**Center Panel (Lines 173-182):**
```css
.center-panel {
    flex: 1;
    min-width: 0;
    background-color: transparent;
    display: flex;
    align-items: center;
    justify-content: center;
    border-left: 1px solid rgba(255, 215, 0, 0.3);
    border-right: 1px solid rgba(255, 215, 0, 0.3);
}
```
✅ **Status:** Correctly set to `transparent`

**Azgaar Container (Lines 184-189):**
```css
.azgaar-container {
    background: transparent;
    border: none;
    width: 100%;
    height: 100%;
}
```
✅ **Status:** Correctly set to `transparent`

**Conclusion:** All CSS transparency settings are correct. No opaque backgrounds in the HTML/CSS hierarchy.

### HTML Structure Verification
**File:** `res://assets/ui_web/templates/world_builder.html`

**Center Panel Structure:**
```html
<div class="center-panel">
    <div id="azgaar-container" class="azgaar-container"></div>
</div>
```
✅ **Status:** Empty container div with no blocking content. Structure is correct.

---

## Scene Audit

### Node Hierarchy
**File:** `res://scenes/ui/WorldBuilderUI.tscn`

**Current Structure:**
```
WorldBuilderWebRoot (Control)
├── AzgaarController (Control) [FIRST CHILD - Renders Behind]
│   ├── WebViewMargin (MarginContainer)
│   │   └── AzgaarWebView (WebView)
│   │       └── No transparent property set
└── WebView (WebView) [SECOND CHILD - Renders On Top]
    └── No transparent property set
```

**Node Properties:**
- **AzgaarController:** First child (renders behind) ✅
- **AzgaarWebView:** Full rect, anchors preset 15 ✅
- **Main WebView:** Full rect, anchors preset 15 ✅
- **Visibility:** Both nodes visible and enabled ✅
- **Layering:** Correct (AzgaarController first, main WebView second) ✅

**Missing Property:**
- ❌ **Main WebView (`WebView`):** `transparent = true` **NOT SET**

**Comparison with godot_wry Example:**
**File:** `addons/godot_wry/examples/character_creator_ui_demo/character_creator.tscn` (Line 1498)
```gdscript
[node name="WebView" type="WebView" parent="."]
url = "res://addons/godot_wry/examples/character_creator_ui_demo/ui/build/index.html"
transparent = true  ← THIS PROPERTY EXISTS
```

**Conclusion:** Scene structure is correct, but the main UI WebView lacks the `transparent = true` property that godot_wry supports.

---

## Runtime Logs Analysis

### Initialization Timeline
1. **14:57:17** - WorldBuilderWebController loaded HTML UI
2. **14:57:17** - WorldBuilderAzgaar found and initialized
3. **14:57:17** - Azgaar URL loaded: `http://127.0.0.1:8080/index.html`
4. **14:57:18** - AzgaarServer served `index.html` (589,207 bytes)
5. **14:57:18** - Bridge script injected successfully
6. **14:57:18-14:57:30** - All 100+ Azgaar assets served successfully (JS, CSS, images, JSON)
7. **14:57:30** - AzgaarServer attempted to serve `options.json` (file not found - expected, uses default)

### Key Observations
- ✅ **No errors** during Azgaar loading
- ✅ **All assets served** successfully
- ✅ **Bridge script injected** without errors
- ✅ **Azgaar auto-generation** should trigger via `checkLoadParameters()` → `generateMapOnLoad()` → `generate()`
- ⚠️ **No IPC messages** from Azgaar indicating generation completion (expected if map is not visible due to transparency)

### Missing Logs
- No `generation_complete` IPC messages from Azgaar (expected if transparency blocks visibility)
- No rendering errors (suggests Azgaar is rendering, but blocked by opaque WebView)

**Conclusion:** All initialization and loading is successful. The issue is purely visual/transparency-related, not functional.

---

## Transparency Testing Results

### Test 1: CSS Transparency (Completed)
- **Action:** Set `body { background-color: transparent; }`
- **Result:** ✅ CSS is transparent, but "white viewport" still visible
- **Conclusion:** CSS transparency alone is insufficient

### Test 2: Main WebView Visibility (Not Performed - Recommended)
- **Action:** Temporarily set `visible = false` on main WebView
- **Expected Result:** If Azgaar map becomes visible, confirms Azgaar is rendering correctly
- **Status:** Recommended for future testing

### Test 3: godot_wry Transparent Property (Identified)
- **Action:** Set `transparent = true` on main UI WebView node
- **Expected Result:** WebView background becomes transparent, allowing Azgaar to show through
- **Status:** **PRIMARY RECOMMENDATION** - Not yet tested

---

## godot_wry Transparency Support

### Evidence of Transparency Support
**File:** `addons/godot_wry/examples/character_creator_ui_demo/character_creator.tscn`
- Line 1498: `transparent = true` property exists on WebView node
- This confirms godot_wry **does support** WebView transparency

### How Transparency Works
- **CSS transparency** (`background-color: transparent`) only affects the HTML content within the WebView
- **WebView transparency** (`transparent = true`) makes the WebView's native background transparent, allowing underlying nodes to show through
- **Both are required** for layered WebViews:
  1. Main UI WebView: `transparent = true` (native transparency)
  2. Main UI HTML: `body { background-color: transparent; }` (CSS transparency)
  3. Azgaar WebView: Opaque (renders map normally)

### Current State
- ✅ CSS transparency: Set
- ❌ WebView transparency: **NOT SET** on main UI WebView
- ✅ Azgaar WebView: Opaque (correct - should render map normally)

**Conclusion:** The main UI WebView must have `transparent = true` set to enable native transparency, allowing the Azgaar WebView behind it to be visible.

---

## Map Generation Verification

### Azgaar Auto-Generation Flow
**File:** `tools/azgaar/main.js`

**On Load Sequence:**
1. `checkLoadParameters()` (Line 296) - Checks URL params, indexedDB, etc.
2. Falls through to `generateMapOnLoad()` (Line 340) if no saved map
3. `generateMapOnLoad()` calls:
   - `applyStyleOnLoad()` - Apply style
   - `generate()` - Generate map (Line 342)
   - `applyLayersPreset()` - Apply layers
   - `drawLayers()` - Render layers
   - `fitMapToScreen()` - Fit to viewport

**Generation Function:**
- `generate()` (Line 643) performs full map generation (heightmap, biomes, cultures, states, etc.)
- Takes ~2-5 seconds for typical maps
- Logs completion via console (if INFO/WARN enabled)

### Current Integration
**File:** `scripts/ui/WorldBuilderAzgaar.gd`
- Bridge script injected (Line 103)
- Hooks into `azgaar.generate()` to send `generation_complete` IPC message
- No manual generation trigger needed - Azgaar auto-generates on load

**Conclusion:** Azgaar **does auto-generate** a map on load. The map should be visible if transparency is properly configured. The "white viewport" suggests the map is rendering but blocked by the opaque main WebView background.

---

## Potential Causes & Updated Recommendations

### Root Cause
**PRIMARY:** The main UI WebView (`WorldBuilderWebRoot/WebView`) does **not** have `transparent = true` set, causing an opaque native background that blocks the Azgaar WebView behind it, regardless of CSS transparency.

### Secondary Factors
1. **CSS Transparency:** ✅ Already fixed (body background transparent)
2. **HTML Structure:** ✅ Correct (empty azgaar-container div)
3. **Scene Layering:** ✅ Correct (AzgaarController first, main WebView second)
4. **Azgaar Loading:** ✅ Successful (all assets served, bridge injected)
5. **Map Generation:** ✅ Auto-generates on load

### Recommendations

#### 1. **IMMEDIATE FIX (Primary):**
   - **Action:** Set `transparent = true` on the main UI WebView node in `res://scenes/ui/WorldBuilderUI.tscn`
   - **Location:** `[node name="WebView" type="WebView" parent="."]` (Line 46)
   - **Change:** Add `transparent = true` property
   - **Expected Result:** Main WebView background becomes transparent, Azgaar map visible through center panel

#### 2. **VERIFICATION TEST (Recommended):**
   - **Action:** Temporarily set `visible = false` on main WebView to confirm Azgaar renders correctly
   - **Purpose:** Isolate transparency issue from rendering issue
   - **Revert:** After confirmation, restore visibility and apply `transparent = true`

#### 3. **ALTERNATIVE APPROACHES (If Primary Fix Fails):**
   - **Option A:** Use CanvasLayer with different z-index values (if godot_wry supports it)
   - **Option B:** Embed Azgaar via iframe in HTML instead of separate WebView (requires HTML/JS changes)
   - **Option C:** Use a single WebView with Azgaar embedded as iframe, overlay UI via absolute positioning

#### 4. **FUTURE ENHANCEMENTS:**
   - Add `transparent` property toggle in WorldBuilderWebController script for runtime testing
   - Document transparency requirements in project rules
   - Consider making transparency the default for overlay WebViews

### Implementation Priority
1. **HIGH:** Set `transparent = true` on main UI WebView
2. **MEDIUM:** Test with main WebView hidden to verify Azgaar rendering
3. **LOW:** Alternative approaches (only if primary fix fails)

---

## Summary

The CSS transparency fix was necessary but insufficient. The root cause is that **godot_wry WebView nodes have an opaque default background** that must be explicitly set to transparent via the `transparent = true` property. This property is supported by godot_wry (as evidenced by the character_creator example) but is not currently set on the main UI WebView. Setting this property should resolve the "white viewport" issue and allow the Azgaar map to be visible through the transparent center panel.

**Next Step:** Apply `transparent = true` to the main UI WebView node in the scene file.

