# Performance Overlay Migration: Autoload Scene → Singleton Manager

**Date:** 2025-01-27  
**Status:** COMPLETED

---

## Changes Made

### 1. Created New Singleton Manager
- **File:** `res://scripts/managers/PerformanceOverlayManager.gd`
- **Autoload Name:** `PerfOverlay`
- **Purpose:** Lightweight singleton that controls a manually-placed PerformanceOverlay scene instance

### 2. Updated Scene File
- **File:** `res://scenes/ui/PerformanceOverlay.tscn`
- **Changes:**
  - Removed script reference (no longer uses MonitorManager.gd)
  - Set `visible = false` in scene file (prevents flash on load)
  - Kept structure: CanvasLayer → MarginContainer → Panel → MonitorOverlay

### 3. Removed Autoload Scene
- **File:** `project.godot`
- **Removed:** `PerformanceOverlay="*res://scenes/ui/PerformanceOverlay.tscn"`
- **Added:** `PerfOverlay="*res://scripts/managers/PerformanceOverlayManager.gd"`

### 4. Old Manager Script
- **File:** `res://scripts/managers/MonitorManager.gd`
- **Status:** No longer used, can be archived/deleted

---

## Manual Setup Required

### Step 1: Add PerformanceOverlay Scene to Main Scene

The PerformanceOverlay scene must be manually added to your main game scene (e.g., `MainMenu.tscn` or a persistent UI root):

1. Open your main scene in the editor
2. Add a child node (or use existing CanvasLayer)
3. Right-click → "Change Scene Type" → Select `res://scenes/ui/PerformanceOverlay.tscn`
   - OR: Instance it as a child: Right-click → "Instance Child Scene" → Select `res://scenes/ui/PerformanceOverlay.tscn`
4. Ensure the CanvasLayer has `layer = 128` (or high enough to appear above game content)

### Step 2: Connect Manager to Scene Instance

1. Open Project Settings → AutoLoad
2. Find `PerfOverlay` in the list
3. In the inspector, you'll see `overlay_root` export variable
4. Drag the PerformanceOverlay CanvasLayer node from your scene tree onto the `overlay_root` field

---

## Benefits

1. **No Duplication:** Only one instance exists (manually placed)
2. **Full Control:** Manager script has complete control over visibility and positioning
3. **No Timing Issues:** Scene starts hidden, manager controls when to show
4. **Reliable Positioning:** Uses proven DebugMenuScaler pattern (two-frame wait, bounds validation)
5. **Rule Compliant:** Follows project rules (typed GDScript, proper headers, UIConstants usage)

---

## Testing Checklist

- [ ] PerformanceOverlay scene added to main scene
- [ ] PerfOverlay manager connected to scene instance in inspector
- [ ] Overlay hidden on launch (no flash)
- [ ] F3 key toggles overlay visibility
- [ ] Overlay positioned correctly at top-left
- [ ] No clipping on different resolutions
- [ ] Theme applied correctly (gold colors, readable font)
- [ ] Only one overlay instance exists (check scene tree at runtime)

---

## Rollback Instructions

If issues occur, revert these changes:

1. Restore autoload in `project.godot`:
   ```
   PerformanceOverlay="*res://scenes/ui/PerformanceOverlay.tscn"
   ```

2. Restore script in `PerformanceOverlay.tscn`:
   ```
   [ext_resource type="Script" path="res://scripts/managers/MonitorManager.gd" id="1_0"]
   ...
   script = ExtResource("1_0")
   ```

3. Remove `PerfOverlay` autoload entry

4. Remove manually-placed scene instance

---

**END OF MIGRATION NOTES**
