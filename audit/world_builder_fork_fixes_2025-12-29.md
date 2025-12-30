# World Builder Fork Mode Fixes - Implementation Summary
**Date:** 2025-12-29  
**Implementation:** Auto (Cursor AI)

## Overview
Implemented fixes to make headless Genesis-Azgaar fork the default mode, eliminate generation timeouts, and display full-color 2D map preview in the central UI panel.

## Changes Made

### 1. WorldBuilderWebController.gd
**File:** `scripts/ui/WorldBuilderWebController.gd`

**Key Changes:**
- **Removed DEBUG_TEST_FORK flag** - Fork mode is now always enabled
- **Always load fork template** - Changed from conditional to always using `world_builder_v2.html`
- **Updated _handle_generate()** - Now checks for fork availability first, falls back to iframe if needed
- **Added _generate_via_fork()** - New method to generate using fork API with proper option conversion
- **Added _generate_via_iframe()** - Extracted iframe generation to separate method for fallback
- **Added _convert_params_to_fork_options()** - Converts UI params to fork API format
- **Updated _handle_map_generated()** - Now handles preview data URL from fork, sends to WebView
- **Added _send_preview_to_webview()** - Sends preview image (data URL) to Alpine.js component
- **Updated _convert_and_preview_heightmap()** - Now converts PNG to base64 data URL and sends to WebView
- **Added _handle_fork_ready()** - Handler for fork ready IPC message
- **Improved error handling** - Better error messages and timeout handling

### 2. world_builder_v2.html
**File:** `assets/ui_web/templates/world_builder_v2.html`

**Key Changes:**
- **Canvas now visible** - Changed from `display: none` to conditionally shown after rendering
- **Canvas initialization** - Properly sized to match container, with resize handler
- **Preview rendering** - Calls `renderPreview()` after generation and exports to data URL
- **Status display** - Shows/hides based on preview state
- **Preview data URL** - Included in `map_generated` IPC message to Godot

### 3. world_builder.js
**File:** `assets/ui_web/js/world_builder.js`

**Key Changes:**
- **Added previewImageUrl state** - Alpine.js reactive property for preview image
- **Preview handling** - Handles `preview_ready` IPC update type
- **Canvas clearing** - Hides canvas and shows status when starting new generation
- **Preview display** - Updates previewImageUrl when preview is ready

## Flow Diagram

### Fork Mode (Default)
1. User clicks "Generate Map" → Alpine.js sends `generate` IPC
2. Godot `_handle_generate()` checks fork availability
3. If fork available → `_generate_via_fork()` executes JS
4. JS calls `handleGenerateMap()` or direct fork API
5. Fork generates map → `renderPreview()` draws to canvas
6. Canvas exported to data URL → sent via `map_generated` IPC
7. Godot receives data → `_handle_map_generated()` processes
8. Preview data URL sent to WebView → Alpine.js updates `previewImageUrl`
9. Canvas/image displayed in center panel

### Iframe Mode (Fallback)
1. Fork not available → `_generate_via_iframe()` called
2. Parameters synced to iframe via JS injection
3. `azgaar.generate()` called in iframe
4. Waits for `generation_complete` IPC (with timeout)
5. If successful, extracts data and converts to preview

## Benefits

1. **Fork mode is default** - More reliable, no CORS issues, faster
2. **Full-color preview** - Uses Azgaar's native rendering with biomes, rivers, etc.
3. **No timeouts** - Uses IPC callbacks instead of timer-based timeouts
4. **Better error handling** - Clear error messages and fallback mechanisms
5. **Unified data flow** - Both modes trigger same handlers with JSON data

## Testing Checklist

- [ ] Fork mode activates on generation
- [ ] Preview displays in center panel after generation
- [ ] Preview shows full-color map with biomes/rivers
- [ ] No 60-second timeouts occur
- [ ] Iframe fallback works if fork unavailable
- [ ] Preview clears when starting new generation
- [ ] Canvas resizes properly on window resize

## Files Modified

1. `scripts/ui/WorldBuilderWebController.gd` - Main controller logic
2. `assets/ui_web/templates/world_builder_v2.html` - Fork template with preview
3. `assets/ui_web/js/world_builder.js` - Alpine.js component with preview state

## Next Steps

- Test in-game to verify all functionality
- Add overlay toggles (biomes, political, etc.) if needed
- Optimize preview rendering performance for large maps
- Add loading indicators during generation
