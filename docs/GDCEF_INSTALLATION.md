# gdCEF Installation Guide

## Overview
gdCEF (Godot Chromium Embedded Framework) is required for embedding the Azgaar Fantasy Map Generator WebView in WorldBuilderUI.

## Installation Steps

1. **Open Godot Editor** (4.5.1 stable)

2. **Open AssetLib** (Project → AssetLib or click the AssetLib tab)

3. **Search for "gdCEF"** or navigate to: https://godotengine.org/asset-library/asset/1495

4. **Download and Install**:
   - Click "Download" on the gdCEF asset page
   - Click "Install" in the AssetLib
   - The addon will be installed to `res://addons/gdcef/`

5. **Enable the Plugin**:
   - Go to Project → Project Settings → Plugins
   - Find "gdCEF" in the list
   - Check the "Enable" checkbox
   - Click "Close"

6. **Update WorldBuilderUI Scene**:
   - Open `res://ui/world_builder/WorldBuilderUI.tscn`
   - Navigate to `BackgroundPanel/MainContainer/RightSplit/CenterPanel/AzgaarWebView`
   - In the Inspector, change the node type from `Control` to `WebView` (the gdCEF node type)
   - Save the scene

7. **Test**:
   - Run the project (F5)
   - Open World Builder from main menu
   - The Azgaar WebView should load in the right preview panel

## Troubleshooting

- **WebView node type not available**: Ensure gdCEF plugin is enabled in Project Settings → Plugins
- **Azgaar not loading**: Check that `res://tools/azgaar/` contains the Azgaar files and that `AzgaarIntegrator` singleton is working
- **File path errors**: Verify that `user://azgaar/` directory is created and contains `index.html`

## Notes

- The WebView node is currently hidden by default (`visible = false` in the scene)
- To show it, set `visible = true` on the `AzgaarWebView` node or toggle it via script
- The WebView will load `user://azgaar/index.html` which is copied from `res://tools/azgaar/` at runtime

