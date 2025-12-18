# GUT Import Fix - Quick Guide

**Issue:** GUT classes not loading after installation  
**Status:** Fixed project.godot conflict, awaiting Godot import

---

## What Was Fixed

✅ **Removed project.godot conflict:**
- Moved `addons/gut/project.godot` to `addons/gut/project.godot.bak`
- This prevents Godot from ignoring the GUT folder

---

## What You Need to Do

### Step 1: Close Godot Editor Completely

- Exit Godot completely (not just close the window)
- Ensure no Godot processes are running

### Step 2: Reopen Godot Editor

1. **Open the project in Godot 4.3**
2. **Wait for import to complete:**
   - Check bottom-right corner for import progress
   - Wait until all imports finish (may take 1-2 minutes)

3. **Verify GUT is loaded:**
   - Project Settings → Plugins → "Gut" should be enabled
   - Tools menu should have "GUT" submenu
   - No "GutUtils not declared" errors in output

### Step 3: Test GUT

1. **Open GUT Panel:**
   - Tools → GUT → Show Gut Panel

2. **Run Tests:**
   - In GUT panel, select directory: `res://tests/unit`
   - Click "Run All"
   - Should see test results without errors

---

## If Errors Persist

### Option A: Downgrade to GUT 9.4.0 (Recommended for Godot 4.3)

GUT 9.5.1 requires Godot 4.5+, but project uses 4.3. Use GUT 9.4.0 instead:

```bash
cd /home/darth/Final-Approach
rm -rf addons/gut
curl -L -o /tmp/gut.zip https://github.com/bitwes/Gut/archive/refs/tags/v9.4.0.zip
unzip -q /tmp/gut.zip -d /tmp
mv /tmp/Gut-9.4.0/addons/gut addons/
rm -rf /tmp/Gut-9.4.0 /tmp/gut.zip
```

Then reopen Godot Editor.

### Option B: Manual Import (If Godot command available)

If you have `godot` in your PATH:

```bash
cd /home/darth/Final-Approach
godot --headless --import --path .
```

Then reopen Godot Editor.

---

## Expected Result

After reopening Godot:

✅ No "GutUtils not declared" errors  
✅ GUT panel opens successfully  
✅ Tests can be run  
✅ All 28 unit tests execute

---

## Verification Checklist

- [ ] Godot Editor closed completely
- [ ] Reopened Godot Editor
- [ ] Import completed (no progress bar)
- [ ] Project Settings → Plugins → "Gut" enabled
- [ ] Tools → GUT menu visible
- [ ] GUT panel opens without errors
- [ ] Tests can be run

---

**Next:** Once GUT is working, run the Phase 1 tests and verify all 28 tests pass.

**Last Updated:** 2025-12-13







