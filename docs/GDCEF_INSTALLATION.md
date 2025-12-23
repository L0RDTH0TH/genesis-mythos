# ╔═══════════════════════════════════════════════════════════
# ║ gdCEF Installation Guide
# ║ Desc: Instructions for installing gdCEF addon for Azgaar WebView
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

## Overview

gdCEF (Godot Chromium Embedded Framework) is required for embedding Azgaar's Fantasy Map Generator in the WorldBuilderUI.

## Installation Steps

1. **Download the Latest Release:**
   - Visit: https://github.com/Lecrapouille/gdcef/releases
   - Download the latest prebuilt release compatible with Godot 4.5.1
   - Look for releases tagged with "godot4" (e.g., v0.17.0-godot4 or newer)

2. **Extract and Place Files:**
   - Uncompress the downloaded archive
   - Place the entire `cef_artifacts` folder at the root of the project:
     ```
     res://cef_artifacts/
     ```
   - **Important:** Do NOT rename the folder or remove any files inside it
   - The folder structure should be:
     ```
     res://cef_artifacts/
     ├── addons/
     ├── bin/
     └── ... (other files)
     ```

3. **Enable the Addon (if needed):**
   - The addon should auto-load in most cases
   - If not, go to Project Settings → Plugins
   - Enable "gdCEF" if it appears in the list

4. **Verify Installation:**
   - After installation, the `GDCef` node type should be available in the node creation menu
   - You can verify by trying to add a GDCef node in any scene

## Usage

The gdCEF WebView is integrated into `WorldBuilderUI.tscn` as `AzgaarWebView` node, controlled by `WorldBuilderAzgaar.gd` script.

## Troubleshooting

- **Node not found:** Ensure `cef_artifacts` folder is at project root and contains all files
- **WebView not loading:** Check that Azgaar files are copied to `user://azgaar/` via `AzgaarIntegrator`
- **Build errors:** Ensure you downloaded the correct version for your platform (Linux/Windows/Mac)

## References

- gdCEF GitHub: https://github.com/Lecrapouille/gdcef
- Latest Releases: https://github.com/Lecrapouille/gdcef/releases

