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
