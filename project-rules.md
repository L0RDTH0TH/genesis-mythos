# ╔═══════════════════════════════════════════════════════════
# ║ COMPLETE & FINAL PROJECT RULES – ITERATION 5
# ║ GENESIS MYTHOS – FULL FIRST PERSON 3D VIRTUAL TABLETOP RPG IN GODOT 4.5.1
# ║ Valid for Grok AND Cursor – major changes require explicit approval
# ╚═══════════════════════════════════════════════════════════

## 1. Master Goals (never compromise)

- Full first-person 3D immersive virtual tabletop role-playing game with original "Genesis Mythos" lore and systems.
- Core experience: seamless blend of true first-person exploration (FPS-style movement, interaction, combat) and classic tabletop elements (dice rolling, character sheets, GM tools, grid maps, tokens, fog of war).
- Supports single-player, hosted multiplayer sessions, and future modding.
- Godot 4.5.1 stable only.
- 100% data-driven (JSON + Resources). Zero hard-coded content where possible.
- Maintain 60 FPS on mid-range hardware with full world and UI active.
- Built for extensibility: save/load, multiplayer, character creation, procedural world.

## 2. Folder Structure (CURRENT STATE – may evolve with approval)

```
res://
├── assets/
│   ├── fonts/
│   ├── icons/
│   ├── models/          # GLB characters, props, environment, miniatures
│   ├── textures/        # PBR, UI, dice, etc.
│   ├── sounds/          # SFX, music, ambient, voice (NEW – encouraged)
│   └── ui/
├── core/                # Core engine systems (EXISTING)
│   ├── singletons/
│   ├── streaming/
│   ├── sim/
│   ├── procedural/
│   └── utils/
├── data/                # All JSON configuration and content data
│   ├── biomes.json
│   ├── civilizations.json
│   ├── resources.json
│   ├── map_icons.json
│   ├── fantasy_archetypes.json
│   └── config/          # Subfolder for tool/world configs
│       ├── logging_config.json
│       ├── terrain_generation.json
│       └── world_builder_ui.json
├── scenes/
│   ├── core/            # Main game scenes (World, Main, etc.)
│   ├── ui/              # HUD, menus, sheets, overlays
│   ├── character_creation/  # Future – character creator scenes
│   ├── tabletop/        # Dice roller, token scenes, map overlays
│   └── tools/           # GM tools, map editor, world builder
├── scripts/
│   ├── core/            # Core logic scripts
│   ├── ui/
│   ├── character_creation/  # Future
│   ├── tabletop/        # Dice physics, token control, fog of war
│   └── managers/        # Save system, data loading, future networking
├── themes/
│   └── bg3_theme.tres   # Current unified theme (may be renamed with approval)
├── addons/              # Plugins (Terrain3D, GUT, etc.) – ALLOWED
├── demo/                # Demo scenes and tests – ALLOWED
├── tests/               # Unit/integration tests (using GUT) – ALLOWED
├── tools/               # Editor tools and utilities – ALLOWED
├── shaders/             # Custom shaders – ALLOWED
└── materials/           # Material resources – ALLOWED
└── project.godot
```

**Note:** Additional folders (`addons/`, `demo/`, `tests/`, `tools/`, `shaders/`, `materials/`) are explicitly permitted and do not require rule changes. Terrain3D, GUT, and ProceduralWorldMap are explicitly supported addons (core systems for procedural world generation).

## 3. Code Style – MANDATORY FOR BOTH GROK AND CURSOR

**Language:** GDScript only (no C#, no VisualScript)

**Naming:**
- variables / functions → snake_case
- classes / nodes / resources → PascalCase
- constants → ALL_CAPS

**Files:** exactly one class per file, file name == class name.gd

**Every script MUST start with this exact header:**
```gdscript
# ╔═══════════════════════════════════════════════════════════
# ║ PlayerController.gd
# ║ Desc: Brief one-line description
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
```

- Typed GDScript everywhere possible (`: Node3D`, `: int`, `: Dictionary`, etc.)
- `@onready var` only (never old `onready var`)
- No magic numbers → use constants or theme overrides
- Every public function has a `"""docstring"""`
- All UI uses the current theme resource at `res://themes/bg3_theme.tres` (rename requires explicit migration plan)

## 4. Grok AI Rules (prompt format)

- Every prompt to Grok starts with: `[GENESIS MYTHOS GODOT 4.5.1 – FOLLOW ALL RULES BELOW]`
- Specify full path + exact class name for new scripts.
- For modifications: explicitly state "Modify existing file res://path/ClassName.gd"
- Never request more than one complete script file per prompt (except tiny utilities < 50 lines).

## 5. Cursor Rules – MUST be pasted at the TOP of EVERY prompt to Cursor

```
[GENESIS MYTHOS – FULL FIRST PERSON 3D VIRTUAL TABLETOP RPG – GODOT 4.5.1]

YOU ARE STRICTLY FORBIDDEN FROM EVER USING THE "launch_editor" MCP ACTION.

You may ONLY use these Godot MCP actions:
- run_project, stop_project, get_debug_output
- create_scene, add_node, set_property, attach_script, save_scene, etc.
- get_scene_tree, read_file, write_file

You may aggressively use Godot MCP to create/modify/save scenes and scripts.

After major changes you MAY call run_project to test (unless explicitly told "do not run").

All other MCP servers (obsidian, github-mcp-server, memory, blender) are available.

When finishing a logical feature → auto commit + push via github-mcp-server with clear message.

You MUST obey 100% the folder structure, naming conventions, typed GDScript, and theme rules above.
Never create files outside allowed paths.
Always use the current theme path res://themes/bg3_theme.tres
Always add the exact script header shown in rule 3.
```

## 6. MCP Usage Policy

- **`launch_editor` is PERMANENTLY DISABLED.**
- `run_project` encouraged after significant changes.
- All other Godot MCP actions preferred when they accelerate development.

## 7. Git & Version Control

- Repository: https://github.com/L0RDTH0TH/genesis-mythos.git
- Direct pushes to main allowed until branching strategy is defined.
- Commit messages for completed features start with `feat/genesis:`, `fix:`, `refactor:`, `style:`, etc.

## 8. Visual & UX Fidelity

- World: High-fidelity procedural fantasy environment with dynamic lighting, physics interaction, using Terrain3D for terrain.
- First-person controller: Smooth, responsive, Skyrim-like feel with interaction raycasts.
- Tabletop elements: 3D physics-based dice, draggable tokens, measurable grids, fog of war.
- UI: Fantasy-themed, diegetic where possible, clean overlays. All styled via central theme.
- Reference blend: TaleSpire + Tabletop Simulator + Skyrim + Foundry VTT.

## 9. Migration & Compatibility

- Existing code using `bg3_theme.tres` remains valid and must not be broken without explicit migration plan.
- Theme rename to `genesis_theme.tres` (or similar) requires full audit and approval.
- New folders/subsystems may be added only with rule update approval.
- Existing systems (WorldStreamer, EntitySim, FactionEconomy, Terrain3D integration, procedural world map generator) take precedence.

## 10. Current Implementation Status

### ✅ Implemented
- Procedural world generation (MapGenerator, MapRenderer, MapEditor) with Terrain3D integration
- Terrain3D integration and streaming
- 8-step World Builder UI wizard
- Core singletons (Eryndor, Logger, WorldStreamer, EntitySim, FactionEconomy)
- CreativeFlyCamera for 3D exploration
- Basic save/load foundations
- GUT setup for unit/integration testing

### 🔄 In Progress
- First-person character controller integration
- UI polish and theme consistency

### 📋 Planned / Future
- Full character creation system + data files (`classes.json`, `races.json`, etc.)
- Tabletop overlay system (dice, tokens, fog of war)
- Multiplayer networking (`NetworkManager.gd` singleton)
- Expanded sound integration

---

**THESE RULES ARE CURRENT AND AUTHORITATIVE AS OF 2025-12-20. MAJOR CHANGES REQUIRE EXPLICIT APPROVAL AND AUDIT.**

**UPDATE 2025-12-20:** Godot version updated to 4.5.1 stable (migration complete). Repository URL added. ProceduralWorldMap upgraded to explicitly supported addon status (core system that generates 2D maps seeding Terrain3D procedural generation).

