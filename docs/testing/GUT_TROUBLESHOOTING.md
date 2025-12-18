# GUT Troubleshooting Guide

**Issue:** GUT classes not loading, "GutUtils" not declared errors

---

## Problem

When opening Godot, you see errors like:
```
Parse Error: Identifier "GutUtils" not declared in the current scope.
Missing class_names: ["GutErrorTracker", "GutHookScript", "GutInputFactory", "GutInputSender", "GutMain", "GutStringUtils", "GutTest", "GutTrackedError", "GutUtils"]
```

## Root Cause

GUT's classes haven't been imported/registered yet. This happens when:
1. GUT was just installed
2. Godot hasn't fully scanned/imported the addon
3. GUT's `project.godot` file conflicts with main project

## Solutions

### Solution 1: Let Godot Import (Recommended)

1. **Close Godot Editor completely**

2. **Reopen Godot Editor**
   - Godot will automatically scan and import GUT
   - Wait for import to complete (check bottom-right progress bar)

3. **Verify Import:**
   - Project Settings → Plugins → "Gut" should be enabled
   - Tools menu should have "GUT" submenu

### Solution 2: Manual Import (If Solution 1 Fails)

1. **Close Godot Editor**

2. **Run Import Command:**
   ```bash
   # Find your Godot executable path first
   # Then run:
   /path/to/godot --headless --import --path /home/darth/Final-Approach
   ```

3. **Reopen Godot Editor**

### Solution 3: Fix project.godot Conflict

The error message shows:
```
Detected another project.godot at res://addons/gut. The folder will be ignored.
```

**Fix:**
1. Rename or remove `addons/gut/project.godot`:
   ```bash
   mv addons/gut/project.godot addons/gut/project.godot.bak
   ```

2. Reopen Godot Editor

**Note:** This file was already moved in the setup process.

### Solution 4: Version Compatibility

GUT 9.5.1 requires Godot 4.5+, but project uses 4.3.

**If errors persist, downgrade to GUT 9.4.0:**

```bash
cd /home/darth/Final-Approach
rm -rf addons/gut
curl -L -o /tmp/gut.zip https://github.com/bitwes/Gut/archive/refs/tags/v9.4.0.zip
unzip -q /tmp/gut.zip -d /tmp
mv /tmp/Gut-9.4.0/addons/gut addons/
rm -rf /tmp/Gut-9.4.0 /tmp/gut.zip
```

Then reopen Godot Editor.

---

## Verification

After applying solutions, verify GUT works:

1. **Check Plugin:**
   - Project Settings → Plugins → "Gut" is enabled

2. **Check Menu:**
   - Tools menu has "GUT" submenu

3. **Run Test:**
   - Tools → GUT → Show Gut Panel
   - Select `res://tests/unit`
   - Click "Run All"
   - Should see test results (no parse errors)

---

## Expected Behavior After Fix

- No "GutUtils not declared" errors
- GUT panel opens without errors
- Tests can be run from GUT panel
- Command-line tests work: `godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`

---

## Still Having Issues?

1. **Check GUT Version:**
   - `addons/gut/plugin.cfg` should show version 9.4.0 or 9.5.1

2. **Check Godot Version:**
   - Project uses Godot 4.3
   - GUT 9.4.0 is compatible with 4.3

3. **Check Plugin Enabled:**
   - `project.godot` should have `res://addons/gut/plugin.cfg` in `[editor_plugins]` enabled array

4. **Full Reinstall:**
   ```bash
   cd /home/darth/Final-Approach
   rm -rf addons/gut
   # Then reinstall GUT 9.4.0 (see Solution 4)
   ```

---

**Last Updated:** 2025-12-13  
**Maintained By:** Lordthoth




