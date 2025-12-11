# ╔═══════════════════════════════════════════════════════════
# ║ CHANGELOG.md
# ║ Desc: Project change history and version log
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

# Changelog

All notable changes to the Genesis Mythos project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Updated project documentation – added/refreshed README, CODING_STANDARDS, PROJECT_STRUCTURE, and TODO
- Comprehensive documentation update to reflect current project state

## [2025-01-XX] - World Builder UI Rendering Fixes

### Fixed
- **World Builder UI Proportioning**: Fixed UI to display full screen instead of 80% size
  - Changed `world_root.gd` to use `PRESET_FULL_RECT` for WorldBuilderUI anchors
  - UI now properly covers entire screen (2560x1440 confirmed in debug output)

- **Background Rendering Prevention**: Added opaque background layer to block 3D terrain/sky bleed-through
  - Added `BackgroundRect` ColorRect with full-screen anchors and opaque black color
  - Prevents main scene's WorldEnvironment from rendering behind UI

- **2D/3D View Separation**: Properly separated 2D map and 3D terrain rendering
  - 2D map (`Map2DTexture`) displays on launch for Steps 1-2
  - 3D terrain (`Terrain3DView`) only renders when Step 3 (Terrain) is selected
  - Visibility controlled by `update_camera_for_step()` function
  - 3D SubViewport render target update disabled when hidden

- **3D Environment Isolation**: Isolated 3D SubViewport with its own WorldEnvironment
  - Added `WorldEnvironment` node inside PreviewViewport to prevent global effects
  - 3D rendering confined to center panel, never extends to background
  - Environment effects (sky, fog) only apply within SubViewport

### Changed
- Restructured `WorldBuilderUI.tscn` scene tree for proper layering
  - BackgroundRect → Overlay → BackgroundPanel → UI content
  - CenterPanel contains both Map2DTexture and Terrain3DView with visibility control
  - All panels use anchor-based layout for responsive sizing

- Updated `WorldBuilderUI.gd` to handle 2D map viewport rendering
  - Created dedicated `map_2d_viewport` SubViewport for 2D map rendering
  - Map content (parchment, grid, icons) rendered to texture via SubViewport
  - Icon placement updated to work with 2D viewport structure

### Technical Details
- **Files Modified:**
  - `ui/world_builder/WorldBuilderUI.tscn` - Scene restructure
  - `ui/world_builder/WorldBuilderUI.gd` - Step visibility and 2D viewport setup
  - `core/scenes/world_root.gd` - Full-screen UI sizing fix

- **Commit Messages:**
  - "fix/world-builder: Corrected full-screen overlay layering with central clear preview window for true BG3 forging aesthetic"
  - "fix/world-builder: Restructured 2D/3D rendering - 2D map shows on launch, 3D only renders in step 3+"
  - "fix/world-builder: Remove duplicate map_root variable declaration"
  - "fix/world-builder: Fixed UI proportioning and prevented premature 3D rendering - full screen UI with opaque background, isolated 3D SubViewport"

## [2025-01-09]

### Removed
- **BREAKING**: Removed all character creation system files
  - Deleted `scenes/character/` directory and all contents
  - Deleted `scripts/character/` directory and all contents
  - Deleted character creation data files (`data/races.json`, `data/classes.json`, `data/backgrounds.json`, etc.)
  - Deleted character model assets (`assets/models/character_bases/`)
  - Deleted `GameData.gd` and `PlayerData.gd` singletons
  - Deleted `CharacterData.gd` resource
  - Removed all character creation test files

- **BREAKING**: Removed all world generation system files
  - Deleted `scenes/sections/` directory and all contents
  - Deleted `scenes/preview/world_preview.tscn`
  - Deleted `scripts/world_creation/` directory and all contents
  - Deleted `scripts/preview/world_preview.gd`
  - Deleted `scripts/WorldCreator.gd`
  - Deleted world generation data files (`data/ui/world_config.json`)
  - Deleted world generation assets (shaders, materials, meshes, presets)
  - Deleted `WorldData.gd` resource
  - Removed all world generation test files

### Changed
- Updated `MainMenu.gd` to remove GameData references
- Updated `MainMenuController.gd` to disable deleted system buttons
- Updated `Main.gd` to remove GameData calls
- Cleaned up all references to deleted systems in remaining files

### Fixed
- Project now loads without errors after system removal
- All broken references cleaned up

## [Previous Versions]

*Note: Previous changelog entries would be listed here in reverse chronological order.*

---

**For detailed commit history, see the git log.**
