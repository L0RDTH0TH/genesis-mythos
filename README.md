# ╔═══════════════════════════════════════════════════════════
# ║ Genesis Mythos
# ║ Godot 4.5.1 Project
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

Genesis Mythos is a Godot 4.5.1 project built with a focus on clean architecture, data-driven design, and extensibility.

## Project Information

- **Godot Version**: 4.3 stable (4.3.0 or any 4.3.x patch)
- **Language**: GDScript only
- **Author**: Lordthoth
- **Repository**: https://github.com/L0RDTH0TH/genesis-mythos.git

## Permanent Project Rules

These rules are **LOCKED** and must be followed 100% with zero exceptions:

### 1. Godot Version
- **4.5.1 stable only**
- GDScript only (no C#, no VisualScript)
- Typed code everywhere

### 2. Folder Structure
- EXACTLY as specified in the project (never add/remove folders without updating rules)
- See `docs/PROJECT_STRUCTURE.md` for current structure

### 3. Naming Conventions
- **Variables/functions**: `snake_case`
- **Classes/nodes/resources**: `PascalCase`
- **Constants**: `ALL_CAPS`
- One class = one file = file name matches class name

### 4. Script Header Format
Every script MUST start with:
```gdscript
# ╔═══════════════════════════════════════════════════════════
# ║ MyClassName.gd
# ║ Desc: One-line description
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
```

### 5. UI & Styling
- Single `.tres` theme for the whole project (`themes/bg3_theme.tres`)
- No magic numbers
- No hard-coded colors
- All styling from theme

### 6. Data-Driven Design
- Everything (items, abilities, races, UI text) comes from JSON or Resources
- Zero hard-coded content
- Easy to extend and modify without code changes

### 7. MCP Rules
- **`launch_editor` is PERMANENTLY FORBIDDEN. Never use it.**
- `run_project` is allowed and encouraged after big changes
- All other Godot MCP actions are preferred over raw text when they speed things up

### 8. Git & Version Control
- Direct pushes to main are allowed
- Every logical feature finished → auto-commit + push to GitHub
- Commit messages: `feat:`, `fix:`, `refactor:`, `style:`, `docs:`, etc.

## Installation & Setup

### Prerequisites

- **Godot 4.3.x** (stable version required)
- No additional dependencies required

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/L0RDTH0TH/genesis-mythos.git
   cd Final-Approach
   ```

2. **Open in Godot**
   - Launch Godot 4.5.1
   - Click "Import" and select the `project.godot` file
   - Click "Import & Edit"

3. **Run the Project**
   - Press F5 or click the "Play" button
   - The main menu should appear

### Project Configuration

The project is configured in `project.godot`:

- **Main Scene**: `res://scenes/MainMenu.tscn`
- **Window Size**: 1920x1080 (configurable)
- **Theme**: `res://themes/bg3_theme.tres` (applied globally)
- **Autoload Singletons**:
  - `Eryndor`: Core game singleton (`res://core/singletons/eryndor.gd`)
  - `Logger`: Logging system (`res://core/singletons/Logger.gd`)
  - `WorldStreamer`: World streaming system (`res://core/streaming/world_streamer.gd`)
  - `EntitySim`: Entity simulation (`res://core/sim/entity_sim.gd`)
  - `FactionEconomy`: Faction economy system (`res://core/sim/faction_economy.gd`)

## Documentation

### Essential Documentation

- **[System Implementations](docs/SYSTEM_IMPLEMENTATIONS.md)** - **START HERE**: Complete documentation of all current system implementations
- **[Architecture Overview](docs/architecture/overview.md)** - High-level system architecture and data flow
- **[World Builder Wizard Guide](docs/WORLD_BUILDER_WIZARD_GUIDE.md)** - Complete guide to the wizard-style world builder
- **[World Builder API Reference](docs/WORLD_BUILDER_API_REFERENCE.md)** - API documentation for world builder classes

### Reference Documentation

- **[Coding Standards](docs/CODING_STANDARDS.md)** - Detailed coding conventions and style guide
- **[Project Structure](docs/PROJECT_STRUCTURE.md)** - Current folder structure and organization
- **[API Reference](docs/api/API_REFERENCE.md)** - Complete API reference for all public classes
- **[Data Schemas](docs/schemas/DATA_SCHEMAS.md)** - JSON schema documentation
- **[Changelog](docs/CHANGELOG.md)** - Project change history
- **[TODO](docs/TODO.md)** - Current tasks and future plans

### Documentation Index

See [docs/README.md](docs/README.md) for complete documentation directory structure and all available documentation.

## Current System Implementations

### ✅ Fully Implemented Systems

1. **Core Singletons** - All 5 autoload singletons (Eryndor, Logger, WorldStreamer, EntitySim, FactionEconomy)
2. **World Generation** - Complete procedural generation system with:
   - MapGenerator: Noise-based heightmap generation with erosion and rivers
   - MapRenderer: Shader-based rendering with multiple view modes
   - MapEditor: Brush-based editing with multiple tools
   - MarkerManager: Icon placement system
3. **World Builder UI** - Complete 8-step wizard interface for world creation
4. **Terrain3D Integration** - Full Terrain3D plugin integration for 3D terrain
5. **Procedural World Map Addon** - Integrated 2D map display system
6. **Data Management** - All JSON data files and loading systems

### Key Features

- **2D Map Editor**: Full-featured map editor with brush tools, presets, and real-time preview
- **3D Terrain Generation**: Procedural terrain generation with Terrain3D integration
- **Biome System**: Data-driven biome generation based on height, temperature, and moisture
- **Wizard Interface**: Step-by-step world creation workflow
- **Fantasy Archetypes**: Preset configurations for different fantasy world types

For complete details, see [System Implementations Documentation](docs/SYSTEM_IMPLEMENTATIONS.md).

## Core Principles

- **100% Data-Driven**: All game data comes from JSON files or Resources
- **Type-Safe**: Typed GDScript throughout for better error detection
- **Performance**: 60 FPS target on mid-range hardware
- **Extensible**: Easy to add new features without code changes
- **Clean Architecture**: Modular design with clear separation of concerns

## Contributing

See `docs/CODING_STANDARDS.md` for complete coding guidelines.

### Quick Reference

1. Follow all naming conventions (snake_case, PascalCase, ALL_CAPS)
2. Use typed GDScript everywhere
3. Include script header in every file
4. No magic numbers or hard-coded values
5. All UI uses single theme
6. Data-driven approach for all content

## License

[Specify your license here]

---

**Genesis Mythos - Project by Lordthoth**

*For complete project rules and conventions, see `.cursor/rules/project-rules.mdc`*
