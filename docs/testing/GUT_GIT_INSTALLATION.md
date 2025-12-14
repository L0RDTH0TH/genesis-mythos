# GUT Git Installation - Complete ✅

**Date:** 2025-12-13  
**Method:** Git Clone from GitHub  
**Status:** Successfully Installed

---

## Installation Summary

### Removed Old Installation
- ✅ Completely removed zip-based GUT installation
- ✅ Cleaned up all modified files and compatibility fixes

### New Git Installation
- ✅ Cloned from: `https://github.com/bitwes/Gut.git`
- ✅ Branch: `main`
- ✅ Version: **9.5.1** (from plugin.cfg)
- ✅ Location: `res://addons/gut/`
- ✅ Git repository active (can pull updates with `git pull`)

---

## Installation Details

**Repository:** https://github.com/bitwes/Gut  
**Latest Commit:** `3748cbf` - "Remove duplicate 'buy me a coffee' link"  
**Version:** 9.5.1 (Godot 4.x compatible)

**Essential Files Verified:**
- ✅ `plugin.cfg` - Plugin configuration (v9.5.1)
- ✅ `gut.gd` - Main GUT script
- ✅ `gut_plugin.gd` - Plugin entry point
- ✅ `cli/gut_cmdln.gd` - CLI script for headless testing
- ✅ All supporting files and directories

---

## Benefits of Git Installation

1. **Easy Updates:** Pull latest changes with `git pull` in `addons/gut/`
2. **Version Control:** Track GUT changes in your project's git history
3. **Latest Features:** Always on the latest main branch
4. **No Manual Downloads:** No need to download and extract zip files

---

## Next Steps

1. **Restart Godot Editor** (if open)
2. **Enable Plugin:**
   - Project Settings → Plugins
   - Find "Gut" and enable it
3. **Verify Installation:**
   - Tools menu should have "GUT" submenu
   - No parse errors in GUT files
4. **Run Tests:**
   - Tools → GUT → Run selected → `res://tests/unit`

---

## Updating GUT

To update GUT to the latest version:

```bash
cd /home/darth/Final-Approach/addons/gut
git pull origin main
```

Or to update to a specific version/tag:

```bash
cd /home/darth/Final-Approach/addons/gut
git fetch --tags
git checkout v9.5.1  # or any other tag
```

---

## Git Repository Info

**Remote:** `https://github.com/bitwes/Gut.git`  
**Branch:** `main`  
**Status:** Up to date with origin/main

**Available Versions:**
- Main branch (latest, requires Godot 4.5+)
- v9.5.1 (Godot 4.5+)
- v9.4.0 (Godot 4.3+) ← **Recommended for Godot 4.3**
- v9.3.0 (Godot 4.2+)

**Note:** If you encounter compatibility issues with the main branch, you can switch to v9.4.0 which is specifically for Godot 4.3:

```bash
cd /home/darth/Final-Approach/addons/gut
git fetch --tags
git checkout v9.4.0
```

---

## Compatibility Notes

The main branch (9.5.1) is designed for Godot 4.5+. Since you're using Godot 4.3, you may want to use v9.4.0 instead if you encounter any issues.

**To switch to v9.4.0 (recommended for Godot 4.3):**
```bash
cd /home/darth/Final-Approach/addons/gut
git fetch --tags
git checkout v9.4.0
```

---

**Status:** ✅ Git Installation Complete  
**Ready:** Enable plugin and start testing  
**Maintained By:** Lordthoth
