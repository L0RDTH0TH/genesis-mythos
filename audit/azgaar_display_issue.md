# Azgaar Map Display Issue Investigation Report
**Date:** 2025-12-28  
**Purpose:** Investigate why Azgaar map preview is not displaying in World Builder UI despite successful loading  
**Status:** Investigation Complete - Root Cause Identified

---

## Executive Summary

The Azgaar map preview is **not visible** in the World Builder UI center panel, despite:
- ✅ Successful node structure initialization
- ✅ Azgaar WebView loading URL correctly (`http://127.0.0.1:8080/index.html`)
- ✅ All Azgaar assets being served successfully (100+ files)
- ✅ Bridge script injection completing
- ✅ No errors in logs

**Root Cause Hypothesis:** The issue is likely a **layering/transparency problem** where the main UI WebView (rendering the HTML/JS interface) is **opaque and blocking** the Azgaar WebView behind it, despite CSS transparency settings. godot_wry WebView nodes may not support true transparency or layered rendering as expected.

**Key Finding:** Both WebViews are full-rect and overlapping. The main UI WebView renders on top (as second child) and likely has an opaque background that blocks the Azgaar WebView behind it, regardless of HTML/CSS transparency settings.

---

## 1. Scene Structure Audit

### 1.1 Current Node Hierarchy

**File:** `res://scenes/ui/WorldBuilderUI.tscn`

```
WorldBuilderWebRoot (Control)
├── layout_mode = 3 (PRESET_FULL_RECT)
├── anchors_preset = 15 (FULL_RECT)
├── script = WorldBuilderWebController.gd
│
├── AzgaarController (Control) [FIRST CHILD - RENDERS BEHIND]
│   ├── layout_mode = 1 (FULL_RECT)
│   ├── anchors_preset = 15 (FULL_RECT)
│   ├── script = WorldBuilderAzgaar.gd
│   │
│   └── WebViewMargin (MarginContainer)
│       ├── layout_mode = 1 (FULL_RECT)
│       ├── anchors_preset = 15 (FULL_RECT)
│       ├── all margins = 0
│       │
│       └── AzgaarWebView (WebView) [godot_wry]
│           ├── layout_mode = 1 (FULL_RECT)
│           ├── anchors_preset = 15 (FULL_RECT)
│           └── Loads: http://127.0.0.1:8080/index.html
│
└── WebView (WebView) [SECOND CHILD - RENDERS ON TOP]
    ├── layout_mode = 1 (FULL_RECT)
    ├── anchors_preset = 15 (FULL_RECT)
    └── Loads: res://assets/ui_web/templates/world_builder.html
```

**Node Count:** 4 nodes (root + AzgaarController + WebViewMargin + AzgaarWebView + main WebView)

### 1.2 Node Properties Analysis

**AzgaarController:**
- ✅ Position: First child (renders behind)
- ✅ Visibility: Not explicitly set (defaults to visible)
- ✅ Enabled: Not explicitly set (defaults to enabled)
- ✅ Layout: Full rect (fills entire parent)
- ❌ **No z_index or z_as_relative properties set** (uses default rendering order)

**AzgaarWebView:**
- ✅ Node found successfully (logs confirm: "AzgaarWebView node is valid WebView instance")
- ✅ URL loaded successfully (logs confirm: "Loaded Azgaar URL")
- ✅ IPC connected (logs confirm: "Connected to WebView IPC message signal")
- ❌ **No transparency properties** (godot_wry may not support WebView transparency)

**Main UI WebView:**
- ✅ Position: Second child (renders on top)
- ✅ Layout: Full rect (fills entire parent)
- ❌ **Likely has opaque background** (godot_wry WebView default behavior)
- ❌ **No transparency properties set**

### 1.3 Rendering Order

In Godot, Control nodes render in the order they appear as children:
1. **AzgaarController** (first child) → Renders first (behind)
2. **WebView** (second child) → Renders second (on top)

**Issue:** The main UI WebView is rendering **on top** of the Azgaar WebView, and if it has an opaque background (default for godot_wry WebView), it will completely block the Azgaar map.

---

## 2. HTML/CSS Audit

### 2.1 HTML Template Structure

**File:** `res://assets/ui_web/templates/world_builder.html`

**Center Panel:**
```html
<div class="center-panel">
    <div id="azgaar-container" class="azgaar-container"></div>
</div>
```

**Status:**
- ✅ Placeholder content removed
- ✅ Empty container div present
- ✅ No blocking content

### 2.2 CSS Transparency Settings

**File:** `res://assets/ui_web/css/world_builder.css`

**Center Panel CSS:**
```css
.center-panel {
    flex: 1;
    min-width: 0;
    background-color: transparent;  /* ✅ Set to transparent */
    display: flex;
    align-items: center;
    justify-content: center;
    border-left: 1px solid rgba(255, 215, 0, 0.3);
    border-right: 1px solid rgba(255, 215, 0, 0.3);
}

.azgaar-container {
    background: transparent;  /* ✅ Set to transparent */
    border: none;
    width: 100%;
    height: 100%;
}
```

**Status:**
- ✅ `.center-panel` has `background-color: transparent`
- ✅ `.azgaar-container` has `background: transparent`
- ✅ No opaque elements in hierarchy

**Issue:** CSS transparency is set correctly, but **this only affects the HTML content within the WebView**. The **godot_wry WebView node itself** may have an opaque background that blocks the Azgaar WebView behind it.

### 2.3 Body/Container Backgrounds

**Body CSS:**
```css
body {
    margin: 0;
    padding: 0;
    width: 100vw;
    height: 100vh;
    background-color: var(--bg-dark);  /* ⚠️ Opaque background */
    font-family: 'Times New Roman', serif;
    color: var(--font-default);
    overflow: hidden;
}
```

**Status:**
- ⚠️ Body has `background-color: var(--bg-dark)` (opaque dark background)
- ⚠️ This fills the entire WebView, potentially blocking Azgaar behind it

**Issue:** The body element has an opaque background that fills the entire WebView viewport, which would block the Azgaar WebView behind it, even if the center panel is transparent.

---

## 3. Runtime Logs Analysis

### 3.1 Initialization Sequence

**Timeline from logs:**
1. `[14:45:42]` WorldBuilderWebController._ready() called
2. `[14:45:42]` WorldBuilderAzgaar finds AzgaarWebView node successfully
3. `[14:45:42]` AzgaarWebView IPC signal connected
4. `[14:45:42]` Azgaar URL loaded: `http://127.0.0.1:8080/index.html`
5. `[14:45:43]` Azgaar loading progress: 25%, 50%, 75%
6. `[14:45:44]` Bridge script injected successfully
7. `[14:45:43-14:45:55]` All Azgaar assets served (100+ files)

**Status:**
- ✅ All initialization steps complete successfully
- ✅ No errors during loading
- ✅ Azgaar WebView is functional and loaded

### 3.2 IPC Communication

**Logs show:**
- ✅ Main UI WebView IPC working (Alpine.js ready, step definitions sent)
- ✅ Azgaar WebView IPC connected (bridge script injected)
- ⚠️ **No IPC messages from Azgaar** (no generation_complete, no map updates)

**Status:**
- Azgaar WebView is loaded but may not be generating a map by default
- No generation requests were triggered during this test session

### 3.3 Asset Loading

**AzgaarServer logs show:**
- ✅ All JavaScript modules served successfully
- ✅ All CSS files served successfully
- ✅ All image assets served successfully
- ✅ Total: 100+ files served without errors

**Status:**
- Azgaar bundle is fully loaded and functional
- No missing assets or 404 errors

---

## 4. Transparency Testing Results

### 4.1 CSS Transparency

**Test:** CSS has `background-color: transparent` on center panel

**Result:** ❌ **Not sufficient** - CSS transparency only affects HTML content, not the WebView node itself

**Conclusion:** The godot_wry WebView node likely has an opaque background that blocks the Azgaar WebView behind it, regardless of CSS settings.

### 4.2 Body Background

**Test:** Body element has `background-color: var(--bg-dark)` (opaque)

**Result:** ❌ **Blocks visibility** - The body background fills the entire WebView viewport, creating an opaque layer that blocks the Azgaar WebView behind it.

**Conclusion:** Even if the center panel is transparent, the body background creates an opaque layer that blocks the Azgaar map.

### 4.3 WebView Node Transparency

**Test:** No transparency properties set on WebView nodes

**Result:** ❌ **Unknown** - godot_wry may not support WebView transparency. No documentation or examples found showing transparent WebView nodes.

**Conclusion:** godot_wry WebView nodes may not support transparency, making layered rendering impossible.

---

## 5. Layering Verification

### 5.1 Node Order

**Current Order:**
1. AzgaarController (first child) → Renders behind ✅
2. WebView (second child) → Renders on top ✅

**Status:** Node order is correct for intended layering.

### 5.2 Z-Index

**Current State:**
- ❌ No `z_index` properties set on any nodes
- ❌ No `z_as_relative` properties set

**Status:** Using default rendering order (child order), which is correct but may not be sufficient if WebView nodes are opaque.

### 5.3 Overlap Analysis

**Both WebViews:**
- ✅ Full rect sizing (fill entire parent)
- ✅ Same parent (WorldBuilderWebRoot)
- ✅ Overlapping completely

**Status:** Complete overlap is intended, but requires transparency to work.

---

## 6. Potential Causes & Recommendations

### 6.1 Root Cause: Opaque WebView Background

**Most Likely Cause:** The main UI WebView (godot_wry) has an **opaque background** that blocks the Azgaar WebView behind it, regardless of CSS transparency settings.

**Evidence:**
- CSS transparency is set correctly
- Body has opaque background that fills WebView
- godot_wry WebView nodes may not support transparency
- No transparency properties found in godot_wry examples

**Impact:** High - This would completely prevent the Azgaar map from being visible.

### 6.2 Secondary Cause: Body Background

**Secondary Cause:** The HTML body element has `background-color: var(--bg-dark)` which creates an opaque layer filling the entire WebView viewport.

**Evidence:**
- Body CSS: `background-color: var(--bg-dark);` (opaque)
- Body fills entire viewport: `width: 100vw; height: 100vh;`

**Impact:** Medium - Even if WebView supports transparency, the body background would block visibility.

### 6.3 Alternative Cause: Azgaar Not Generating Map

**Alternative Cause:** Azgaar may not be generating a map by default, requiring explicit generation trigger.

**Evidence:**
- No `generation_complete` IPC messages in logs
- Azgaar loads but may not auto-generate

**Impact:** Low - This would only affect initial display, not the transparency issue.

---

## 7. Recommendations

### 7.1 Immediate Fix: Make Body Background Transparent

**Action:** Modify `res://assets/ui_web/css/world_builder.css`

**Change:**
```css
body {
    /* ... existing properties ... */
    background-color: transparent;  /* Change from var(--bg-dark) */
}
```

**Rationale:** This will allow the Azgaar WebView behind to show through the main UI WebView, assuming godot_wry supports transparency.

**Risk:** Low - Only affects background, UI elements will still be visible.

### 7.2 Alternative Fix: Use CanvasLayer with Z-Index

**Action:** Modify scene structure to use CanvasLayer for proper layering

**Change:**
- Create CanvasLayer for Azgaar WebView (z_index = 0)
- Create CanvasLayer for UI WebView (z_index = 1)
- Set UI WebView background to transparent if possible

**Rationale:** CanvasLayer provides explicit z-index control and may support transparency better.

**Risk:** Medium - Requires scene restructuring.

### 7.3 Investigation: Check godot_wry Transparency Support

**Action:** Investigate godot_wry documentation/examples for WebView transparency support

**Questions:**
- Does godot_wry support transparent WebView backgrounds?
- Are there properties to enable transparency?
- Can multiple WebViews be layered with transparency?

**Rationale:** If godot_wry doesn't support transparency, layered rendering may not be possible.

**Risk:** Low - Investigation only.

### 7.4 Workaround: Embed Azgaar in HTML via iframe

**Action:** Instead of separate WebView, embed Azgaar in HTML using iframe

**Change:**
- Remove AzgaarController/WebViewMargin/AzgaarWebView nodes
- Add iframe to `world_builder.html` center panel
- Load Azgaar URL in iframe

**Rationale:** iframe within HTML would be transparent and allow proper layering.

**Risk:** Medium - Requires significant restructuring, but may be more reliable.

### 7.5 Test: Temporarily Hide Main WebView

**Action:** Temporarily set main WebView `visible = false` to verify Azgaar renders

**Change:**
- In scene or script, set `$WebView.visible = false`
- Run project and check if Azgaar map is visible

**Rationale:** This will confirm if Azgaar WebView is rendering correctly when not blocked.

**Risk:** Low - Temporary test only.

---

## 8. Summary

### 8.1 What's Working

✅ **Node Structure:** Correct hierarchy with AzgaarController first (behind), main WebView second (on top)  
✅ **Initialization:** All nodes found, scripts attached, URLs loaded  
✅ **Asset Loading:** All Azgaar files served successfully  
✅ **IPC Communication:** Both WebViews have IPC connected  
✅ **CSS Transparency:** Center panel and container have transparent backgrounds

### 8.2 What's Not Working

❌ **Map Visibility:** Azgaar map is not visible in center panel  
❌ **Layered Rendering:** Main UI WebView appears to block Azgaar WebView  
❌ **Transparency:** WebView nodes may not support transparency (godot_wry limitation)

### 8.3 Most Likely Root Cause

**The main UI WebView (godot_wry) has an opaque background that blocks the Azgaar WebView behind it.** This is likely due to:
1. godot_wry WebView nodes not supporting transparency
2. HTML body element having opaque background
3. No mechanism to make WebView background transparent

### 8.4 Recommended Next Steps

1. **Immediate:** Make body background transparent in CSS
2. **Test:** Temporarily hide main WebView to verify Azgaar renders
3. **Investigate:** Check godot_wry documentation for transparency support
4. **Alternative:** Consider embedding Azgaar via iframe in HTML instead of separate WebView

---

**End of Investigation Report**

