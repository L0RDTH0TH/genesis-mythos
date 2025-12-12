# ╔═══════════════════════════════════════════════════════════
# ║ Genesis Mythos
# ║ Godot 4.3 Project
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

Genesis Mythos is a Godot 4.3 project built with a focus on clean architecture, data-driven design, and extensibility.

## Project Information

- **Godot Version**: 4.3 stable (4.3.0 or any 4.3.x patch)
- **Language**: GDScript only
- **Author**: Lordthoth
- **Repository**: https://github.com/L0RDTH0TH/genesis-mythos.git

## Permanent Project Rules

These rules are **LOCKED** and must be followed 100% with zero exceptions:

### 1. Godot Version
- **4.3 stable only** (currently 4.3.0 or any 4.3.x patch)
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
   - Launch Godot 4.3.x
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

- **[Coding Standards](docs/CODING_STANDARDS.md)** - Detailed coding conventions and style guide
- **[Project Structure](docs/PROJECT_STRUCTURE.md)** - Current folder structure and organization
- **[Changelog](docs/CHANGELOG.md)** - Project change history
- **[TODO](docs/TODO.md)** - Current tasks and future plans

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
