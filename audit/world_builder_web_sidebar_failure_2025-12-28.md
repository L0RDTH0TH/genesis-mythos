# World Builder UI (Web/Embedded Azgaar) – Left Sidebar (8 Steps) Display Failure Audit – 2025-12-28

**Date:** 2025-12-28  
**Purpose:** Investigate why the left sidebar containing the 8-step wizard is not displaying in the embedded World Builder UI  
**Status:** Investigation Complete - Root Cause Identified

---

## Overview & Architectural Context

According to the task description, the World Builder UI was migrated to be "100% implemented inside the embedded Azgaar Fantasy Map Generator web application loaded via godot_wry WebView." However, investigation reveals a **critical architectural mismatch** between the expected implementation and the actual state of the codebase.

**Current Architecture:**
- There are **TWO separate WebView implementations**:
  1. **`WorldBuilderWeb.tscn`** → Loads custom HTML UI at `web_ui/world_builder/index.html` (HAS 8-step wizard sidebar)
  2. **`WorldBuilderAzgaar.gd`** → Loads standard Azgaar bundle at `tools/azgaar/index.html` (NO 8-step wizard sidebar)

**Expected vs. Actual:**
- **Expected:** 8-step wizard sidebar exists in Azgaar bundle (`res://tools/azgaar/`)
- **Actual:** Standard Azgaar bundle does NOT contain any 8-step wizard sidebar
- **Finding:** 8-step wizard sidebar exists in a separate custom HTML file (`web_ui/world_builder/index.html`)

---

## Examined Files

### 1. Azgaar Bundle Files (Standard Application)

**Location:** `res://tools/azgaar/` (or `tools/azgaar/` on disk)

#### 1.1 HTML Structure (`index.html`)
- **Total Size:** 8,185+ lines
- **Structure:** Standard Azgaar Fantasy Map Generator HTML
- **Key Elements Found:**
  - SVG map container (`<svg id="map">`)
  - Dialog/panel elements (e.g., `id="options"`, `id="styleElements"`)
  - No left sidebar with 8-step wizard
  - No elements with IDs/classes containing "step", "wizard", "sidebar", "left-panel", or "left-tabs"

**Search Results:**
- Searched for: `sidebar`, `step`, `wizard`, `progress`, `left.*panel`, `navigation`
- Found: Only generic references (e.g., `step` in slider inputs, `left` in padding styles)
- **Conclusion:** Standard Azgaar does not contain an 8-step wizard sidebar

#### 1.2 CSS Styling (`index.css`)
- **Total Size:** 2,424+ lines
- **Key Findings:**
  - Contains standard Azgaar UI styling (dialogs, options panels, buttons)
  - No CSS rules targeting a left sidebar with 8 steps
  - No `.left-tabs-panel`, `.left-tab-button`, `.step-*` classes
  - Contains `#options` panel styling (floating dialog, not sidebar)
  - Media queries for responsive design (e.g., `@media screen and (max-width: 600px)`) but no sidebar-specific breakpoints

**Search Results:**
- Searched for: `sidebar`, `.left`, `display.*none`, `visibility.*hidden`, `width.*0`, `translateX`, `opacity.*0`
- Found: Generic hiding rules (e.g., `.hidden { display: none !important; }`), but no sidebar-specific rules
- **Conclusion:** No CSS exists to style or hide an 8-step wizard sidebar

#### 1.3 JavaScript Logic (`main.js`)
- **Total Size:** 1,295+ lines
- **Key Findings:**
  - Contains Azgaar initialization, map generation, UI toggling
  - No code that initializes or manages an 8-step wizard
  - No references to "step", "wizard", "sidebar" in UI initialization
  - Standard Azgaar uses dialog-based UI (e.g., `toggleOptions()`, `openDialog()`)

**Search Results:**
- Searched for: `getElementById.*sidebar`, `querySelector.*sidebar`, `.style.display`, `.style.visibility`, `.style.width`
- Found: Generic style manipulation (e.g., `assistantContainer.style.display = "block"`), but no sidebar-specific code
- **Conclusion:** No JavaScript exists to initialize or toggle an 8-step wizard sidebar

### 2. Custom World Builder UI Files

**Location:** `res://web_ui/world_builder/` (or `web_ui/world_builder/` on disk)

#### 2.1 HTML Structure (`index.html`)
- **Contains:** 8-step wizard sidebar implementation
- **Structure (lines 18-31):**
```html
<!-- Left Panel: Numbered Tab Bar (BG3-style) -->
<div class="left-tabs-panel">
    <div class="left-tabs-container">
        <template x-for="(step, index) in steps" :key="index">
            <button 
                class="left-tab-button" 
                :class="{ 'active': currentStep === index }"
                @click="setStep(index)">
                <span class="tab-number" x-text="index + 1"></span>
                <span class="tab-label" x-text="step.title || `Step ${index + 1}`"></span>
            </button>
        </template>
    </div>
</div>
```

#### 2.2 CSS Styling (`world_builder.css`)
- **Contains:** Styling for `.left-tabs-panel`, `.left-tab-button`, `.tab-number`, `.tab-label`
- **Key Rules (lines 79-170):**
```css
.left-tabs-panel {
    width: var(--left-tabs-width, 280px);
    min-width: var(--left-tabs-width-min, 180px);
    max-width: var(--left-tabs-width-max, 300px);
    background-color: var(--bg-panel);
    border-right: 2px solid var(--border-gold);
    display: flex;
    flex-direction: column;
    overflow: hidden;
}
```

#### 2.3 JavaScript Logic (`world_builder.js`)
- **Contains:** Alpine.js component `worldBuilder` with step management
- **Methods:** `setStep(index)`, `currentStep`, `steps` array

**Conclusion:** The 8-step wizard sidebar exists in the custom HTML UI, NOT in the Azgaar bundle.

---

## HTML Structure Analysis

### Standard Azgaar (`tools/azgaar/index.html`)

**Key Structural Elements:**
- `<svg id="map">` - Main map container (full-screen)
- Dialog elements (e.g., `<div id="options" class="dialog">`) - Floating panels, not sidebars
- No left sidebar structure
- No step-based navigation UI

**Layout:** Azgaar uses a **dialog-based UI** where options/panels appear as floating windows over the map, not as persistent sidebars.

### Custom World Builder (`web_ui/world_builder/index.html`)

**Key Structural Elements:**
- `<div class="left-tabs-panel">` - Left sidebar container
  - `<div class="left-tabs-container">` - Step buttons container
    - `<template x-for="(step, index) in steps">` - Alpine.js loop for 8 steps
      - `<button class="left-tab-button">` - Individual step button
        - `<span class="tab-number">` - Step number (1-8)
        - `<span class="tab-label">` - Step title

**Layout:** Custom UI uses a **three-panel layout** (left sidebar, center preview, right parameters), with the left sidebar containing the 8-step wizard navigation.

---

## CSS Analysis

### Standard Azgaar (`tools/azgaar/index.css`)

**No Sidebar CSS Rules Found:**
- No `.left-tabs-panel`, `.left-tab-button`, `.tab-number`, `.tab-label` classes
- No rules that would hide/show a sidebar (e.g., `display: none` on a sidebar element)
- No media queries that would collapse a sidebar on certain widths

**Relevant CSS Rules:**
- `#options` - Floating dialog panel (not a sidebar)
- `.dialog` - Generic dialog styling
- Media queries exist but target dialogs/panels, not sidebars

### Custom World Builder (`web_ui/world_builder/world_builder.css`)

**Sidebar CSS Rules Found:**
- `.left-tabs-panel` - Full sidebar styling (width, background, border, flex layout)
- `.left-tab-button` - Button styling (height, padding, hover states, active state)
- `.tab-number` - Circular number badge styling
- `.tab-label` - Step title text styling

**Key CSS Variables:**
```css
--left-tabs-width: 280px;
--left-tabs-width-min: 180px;
--left-tabs-width-max: 300px;
```

---

## JavaScript Logic Analysis

### Standard Azgaar (`tools/azgaar/main.js`)

**No Step Wizard Logic Found:**
- No initialization code for an 8-step wizard
- No step navigation functions (e.g., `setStep()`, `nextStep()`, `previousStep()`)
- No step state management (e.g., `currentStep`, `steps` array)

**Relevant Functions:**
- `checkLoadParameters()` - Checks URL parameters on load
- `generateMapOnLoad()` - Auto-generates map if URL params present
- Dialog toggling functions (e.g., `toggleOptions()`, `openDialog()`)

**Conclusion:** Standard Azgaar uses parameter-based generation (URL params or options object), not a step-based wizard flow.

### Custom World Builder (`web_ui/world_builder/world_builder.js`)

**Step Wizard Logic Found:**
- Alpine.js component: `worldBuilder` with `steps` array, `currentStep` index
- `setStep(index)` - Changes active step
- `currentStepParams` - Computed property filtering params by step
- Step definitions loaded from JSON via IPC from Godot

---

## Runtime Observations

**Unable to run project** (as per instructions to investigate only), but based on code analysis:

### Expected Behavior (if 8-step wizard was in Azgaar):
1. WebView loads `tools/azgaar/index.html`
2. Azgaar initializes its standard UI (map + floating dialogs)
3. Left sidebar with 8 steps should appear
4. **Reality:** Standard Azgaar has no such sidebar

### Actual Behavior (based on code):
1. **If `WorldBuilderWeb.tscn` is loaded:**
   - WebView loads `web_ui/world_builder/index.html`
   - **Left sidebar with 8 steps SHOULD appear** (HTML/CSS/JS all present)
   - Center panel shows placeholder (Azgaar handled separately)
   - Right panel shows step parameters

2. **If `WorldBuilderAzgaar.gd` is loaded:**
   - WebView loads Azgaar bundle (`tools/azgaar/index.html` or `user://azgaar/index.html`)
   - **No left sidebar appears** (none exists in standard Azgaar)
   - Standard Azgaar UI appears (map + floating options dialog)

---

## Identified Root Cause(s)

### Primary Root Cause: Architectural Mismatch

**The 8-step wizard sidebar does not exist in the Azgaar bundle because:**

1. **Standard Azgaar Fantasy Map Generator does not include an 8-step wizard:**
   - Azgaar uses a dialog-based UI (floating panels), not a sidebar-based wizard
   - Azgaar generation is parameter-driven (options object), not step-based
   - The Azgaar bundle (`tools/azgaar/`) is the standard, unmodified application

2. **The 8-step wizard exists in a separate custom HTML file:**
   - Location: `web_ui/world_builder/index.html`
   - This is a custom implementation built specifically for Genesis Mythos
   - It is NOT part of the Azgaar bundle

3. **Dual WebView Architecture:**
   - Two separate WebViews serve different purposes:
     - `WorldBuilderWeb.tscn` → Custom 8-step wizard UI
     - `WorldBuilderAzgaar.gd` → Embedded Azgaar map generator
   - The sidebar should appear in `WorldBuilderWeb.tscn`, NOT in `WorldBuilderAzgaar.gd`

### Secondary Considerations

**If the sidebar is expected in the Azgaar WebView specifically:**

1. **No Custom Modifications to Azgaar Bundle:**
   - The `tools/azgaar/` bundle appears to be the standard Azgaar release
   - No custom HTML/CSS/JS has been added to inject the 8-step wizard
   - No build process exists to merge the custom UI into Azgaar

2. **Integration Path Not Implemented:**
   - If the intent was to embed the 8-step wizard inside Azgaar's HTML, this has not been done
   - No script injection or DOM manipulation code exists to add the sidebar to Azgaar's UI
   - No iframe or hybrid approach has been implemented

---

## Supporting Evidence (Code Excerpts)

### Evidence 1: Azgaar Bundle Does Not Contain Sidebar HTML

**File:** `tools/azgaar/index.html`

**Search Results:**
- No `<div class="left-tabs-panel">` found
- No `<div class="left-tabs-container">` found
- No `<button class="left-tab-button">` found
- No Alpine.js `x-for` templates for steps

**Conclusion:** Standard Azgaar HTML structure does not include a left sidebar with 8 steps.

### Evidence 2: Custom World Builder Contains Sidebar HTML

**File:** `web_ui/world_builder/index.html` (lines 18-31)

```html
<!-- Left Panel: Numbered Tab Bar (BG3-style) -->
<div class="left-tabs-panel">
    <div class="left-tabs-container">
        <template x-for="(step, index) in steps" :key="index">
            <button 
                class="left-tab-button" 
                :class="{ 'active': currentStep === index }"
                @click="setStep(index)">
                <span class="tab-number" x-text="index + 1"></span>
                <span class="tab-label" x-text="step.title || `Step ${index + 1}`"></span>
            </button>
        </template>
    </div>
</div>
```

**Conclusion:** The 8-step wizard sidebar exists in the custom World Builder HTML, not in Azgaar.

### Evidence 3: CSS Styling Only Exists in Custom UI

**File:** `web_ui/world_builder/world_builder.css` (lines 79-170)

```css
.left-tabs-panel {
    width: var(--left-tabs-width, 280px);
    background-color: var(--bg-panel);
    border-right: 2px solid var(--border-gold);
    display: flex;
    flex-direction: column;
    overflow: hidden;
}

.left-tab-button {
    display: flex;
    align-items: center;
    gap: var(--spacing-small);
    height: 50px;
    background-color: var(--bg-panel);
    border: 2px solid var(--border-gold);
    /* ... */
}
```

**File:** `tools/azgaar/index.css`

**Search Results:**
- No `.left-tabs-panel` rule found
- No `.left-tab-button` rule found
- No `.tab-number` or `.tab-label` rules found

**Conclusion:** CSS for the sidebar only exists in the custom World Builder stylesheet.

### Evidence 4: JavaScript Logic Only Exists in Custom UI

**File:** `web_ui/world_builder/world_builder.js`

**Alpine.js Component (excerpt):**
```javascript
Alpine.data('worldBuilder', () => ({
    steps: [],
    currentStep: 0,
    setStep(index) {
        this.currentStep = index;
        // ...
    },
    // ...
}));
```

**File:** `tools/azgaar/main.js`

**Search Results:**
- No `worldBuilder` Alpine.js component found
- No `setStep()` function found
- No `currentStep` or `steps` array found

**Conclusion:** JavaScript for step management only exists in the custom World Builder script.

---

## Recommendations

### Option 1: Use the Existing Custom UI (Recommended)

**Current State:**
- The 8-step wizard sidebar already exists in `web_ui/world_builder/index.html`
- This UI is loaded by `WorldBuilderWeb.tscn` via `WorldBuilderWebController.gd`

**Action Required:**
1. Verify that `WorldBuilderWeb.tscn` is being used (not `WorldBuilderAzgaar.gd` alone)
2. Ensure the WebView loads `web_ui/world_builder/index.html` correctly
3. If the sidebar is still not visible, check:
   - CSS file loading (`world_builder.css` path)
   - Alpine.js initialization (`alpine.min.js` loaded before component initialization)
   - Step definitions being sent from Godot via IPC

### Option 2: Integrate Sidebar into Azgaar Bundle (Not Recommended)

**If the intent is to have the sidebar inside the Azgaar WebView:**

1. **Modify Azgaar HTML:**
   - Inject the sidebar HTML structure into `tools/azgaar/index.html`
   - Requires maintaining a fork of Azgaar or build process to merge changes

2. **Modify Azgaar CSS:**
   - Add sidebar styles to `tools/azgaar/index.css`
   - Ensure no conflicts with existing Azgaar UI

3. **Modify Azgaar JavaScript:**
   - Add step wizard logic to `tools/azgaar/main.js` or a new module
   - Integrate with Azgaar's existing parameter system

**Challenges:**
- Maintenance burden (custom Azgaar fork)
- Upgrade complexity (Azgaar updates would need to be merged)
- Potential UI conflicts (Azgaar's dialog system vs. sidebar)

### Option 3: Hybrid Approach (Current Architecture)

**Keep both WebViews separate:**

1. **`WorldBuilderWeb.tscn`** → Custom 8-step wizard UI (with sidebar)
2. **`WorldBuilderAzgaar.gd`** → Embedded Azgaar map generator (no sidebar)

**Action Required:**
1. Ensure both WebViews are instantiated in the scene tree
2. Position Azgaar WebView behind the custom UI (with transparent center panel)
3. Communicate between WebViews via Godot (IPC or signals)

**Status:** This appears to be the current intended architecture (see `world_builder_ui_migration_investigation_2025-12-27.md`).

---

## Conclusion

**Root Cause Summary:**

The left sidebar with the 8-step wizard is **not displaying in the embedded Azgaar World Builder UI** because **it does not exist in the Azgaar bundle**. The standard Azgaar Fantasy Map Generator uses a dialog-based UI, not a sidebar-based wizard. The 8-step wizard sidebar exists in a separate custom HTML file (`web_ui/world_builder/index.html`), which is loaded by a different WebView (`WorldBuilderWeb.tscn`).

**Key Findings:**

1. ✅ **8-step wizard sidebar exists** → In `web_ui/world_builder/index.html` (custom UI)
2. ❌ **8-step wizard sidebar does NOT exist** → In `tools/azgaar/index.html` (standard Azgaar)
3. ⚠️ **Architectural mismatch** → Expectation is that sidebar is in Azgaar, but it's in a separate file

**Next Steps:**

1. **Verify which WebView is being used** in the scene tree
2. **If `WorldBuilderWeb.tscn` is used**, investigate why the sidebar isn't rendering (CSS loading, Alpine.js initialization, step definitions)
3. **If `WorldBuilderAzgaar.gd` is used alone**, switch to using `WorldBuilderWeb.tscn` or implement Option 2/3 above
4. **Clarify architecture intent** → Confirm whether the sidebar should be in Azgaar or in a separate WebView

---

**End of Audit Report**

