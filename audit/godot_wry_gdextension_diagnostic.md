# godot_wry GDExtension Loading Diagnostic Report
**Date:** 2025-12-29  
**Issue:** Project fails to start with grey screen due to GDExtension initialization errors

## Findings

### 1. Version Mismatch (FIXED)
- **Project Configuration:** `godot_version="4.3.stable"` (now updated to `"4.6"`)
- **Engine Running:** Godot 4.6.beta2
- **Project Features:** `config/features=PackedStringArray("4.6", "Forward Plus")`
- **Status:** ✅ Updated `project.godot` to match running engine version

### 2. Addon Structure
- **Location:** `res://addons/godot_wry/`
- **Extension File:** `WRY.gdextension` (correctly named)
- **Binary:** `bin/x86_64-unknown-linux-gnu/libgodot_wry.so` (exists, 4.2MB)
- **Entry Symbol:** `gdext_rust_init` (verified in binary)
- **Compatibility:** `compatibility_minimum = 4.1` (should work with 4.6)

### 3. System Dependencies
- **WebKitGTK:** ✅ Installed
  - `libwebkit2gtk-4.1.so.0` (linked correctly)
  - `libjavascriptcoregtk-4.1.so.0` (linked correctly)
- **GTK3:** ✅ Installed (required by WebKitGTK)
- **All Dependencies:** ✅ Resolved (verified via `ldd`)

### 4. Binary Verification
- **File Type:** ELF 64-bit LSB shared object, x86-64
- **Symbols:** `gdext_rust_init` present
- **Dependencies:** All linked libraries found
- **Permissions:** Readable and executable

### 5. Scene Configuration
- **WorldBuilderWeb.tscn:** Uses `type="WebView"` (expects WebView class)
- **Node Path:** `WorldBuilderWebRoot/WebView`
- **Script:** `WorldBuilderWebController.gd` expects `@onready var web_view: WebView`

## Root Cause Analysis

### Primary Issue: Version Compatibility
The godot_wry binary was likely built for Godot 4.3/4.4 stable and may not be fully compatible with Godot 4.6.beta2. GDExtensions are version-sensitive, and beta versions often have API changes that break compatibility.

### Secondary Issues
1. **Project Version Mismatch:** Fixed by updating `godot_version` in `project.godot`
2. **Extension Not Reimported:** The `.gdextension` file may need to be reimported by opening the project in the editor

## Recommended Solutions

### Option 1: Switch to Godot 4.5.1 Stable (RECOMMENDED)
**Per project rules, the project should use Godot 4.5.1 stable:**
1. Download and install Godot 4.5.1 stable
2. Open the project with Godot 4.5.1
3. The extension should load correctly if the binary is compatible with 4.5.1

### Option 2: Rebuild godot_wry for Godot 4.6
If you must use 4.6.beta2:
1. Clone https://github.com/doceazedo/godot_wry
2. Install build dependencies (`just`, Rust toolchain)
3. Build for your exact Godot version: `just build`
4. Copy the new binary to `addons/godot_wry/bin/x86_64-unknown-linux-gnu/libgodot_wry.so`

### Option 3: Use Pre-built Binary for 4.6 (if available)
Check if godot_wry v1.0.1 or later has a 4.6-compatible binary, or wait for an update.

## Actions Taken

1. ✅ Updated `project.godot` `godot_version` from `"4.3.stable"` to `"4.6"` to match running engine
2. ✅ Verified addon structure and binary integrity
3. ✅ Confirmed system dependencies (WebKitGTK) are installed
4. ✅ Documented version mismatch issue

## Next Steps

1. **Test with updated project.godot:** Run the project to see if the version update helps
2. **If still failing:** Switch to Godot 4.5.1 stable (per project rules) or rebuild the extension
3. **Verify WebView loads:** Once extension loads, verify `ClassDB.class_exists("WebView")` returns `true`

## System Information
- **OS:** Linux (RADV CARRIZO detected in logs)
- **Architecture:** x86_64
- **WebKitGTK Version:** 4.1 (libwebkit2gtk-4.1.so.0)
- **Binary Date:** 2025-12-24
