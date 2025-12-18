# Genesis Mythos – Addon Usage and Implementation Guidelines for Cursor

These guidelines are designed to ensure consistent, rule-compliant integration of installed Godot addons into the Genesis Mythos project. They must be referenced in every Cursor prompt where addons are involved. Cursor **MUST** adhere to the project's master rules (folder structure, code style, theme usage, etc.) when implementing or modifying addon-related code.

**Key Principles:**
- Addons are tools to accelerate development but **must not** introduce dependencies that break data-driven design, extensibility, or performance goals (e.g., maintain 60 FPS).
- **Explicitly supported addons:** Terrain3D, GUT, and ProceduralWorldMap (as per project rules - core systems for procedural world generation). Others (Debug Menu, Monitor Overlay) are permitted for development/testing but should be optional or disabled in release builds.
- **Integration Strategy:** Addons should be wrapped in custom scripts/managers where possible (e.g., under `res://scripts/core/` or `res://scripts/managers/`) to allow easy replacement or extension.
- **Testing:** All addon integrations **MUST** include GUT tests in `res://tests/`.
- **MCP Usage:** Use Godot MCP actions (e.g., `add_node`, `attach_script`, `set_property`) to integrate addons into scenes. After integration, use `run_project` to verify functionality unless instructed otherwise.
- **Disabling for Release:** Development addons (e.g., Debug Menu, Monitor Overlay) should be toggled via a config flag in `res://data/config/logging_config.json` or similar, defaulting to disabled in production.
- **Version Control:** After implementing addon features, commit via `github-mcp-server` with messages like `feat/genesis: Integrate Terrain3D for procedural terrain`.
- **No New Addons:** Do not install or suggest new addons without explicit project rule updates.

## 1. Debug Menu (v1.2.0)
   - **Author:** Calinou
   - **Description:** In-game debug menu for performance metrics and hardware info.
   - **Purpose in Project:** Debugging tool for monitoring FPS, memory, and hardware during development. Useful for optimizing the first-person exploration and tabletop elements.
   - **Usage Guidelines:**
     - **Integration:** Add as an optional overlay in debug builds. Attach to the main scene (`res://scenes/core/Main.tscn`) or HUD (`res://scenes/ui/HUD.tscn`) via MCP.
     - **Implementation Steps:**
       1. Use `add_node` to add the DebugMenu node (from addon path `res://addons/debug_menu/DebugMenu.tscn` or equivalent).
       2. Attach a wrapper script (e.g., `res://scripts/managers/DebugManager.gd`) that toggles visibility based on a debug flag.
       3. In the script, use `@onready var debug_menu: DebugMenu = $DebugMenu` and control it via `debug_menu.visible = ProjectSettings.get_setting("debug/enable_debug_menu", false)`.
       4. Add GUT tests to verify menu toggling and metric display.
     - **Best Practices:**
       - Only enable in editor or debug mode (check `OS.has_feature("editor")` or `OS.is_debug_build()`).
       - Customize display to include project-specific metrics (e.g., entity count from EntitySim, faction economy stats).
       - Avoid in release: Set to hidden by default.
     - **Potential Issues:** Ensure it doesn't interfere with UI theme – override styles to match `res://themes/bg3_theme.tres`.
     - **Example Prompt Snippet for Cursor:**  
       ```
       Use Godot MCP to add DebugMenu node to res://scenes/core/Main.tscn. Attach script res://scripts/managers/DebugManager.gd with toggle logic. Run project to test.
       ```

## 2. Gut (v9.5.1)
   - **Author:** Butch Wesley
   - **Description:** Unit testing tool for Godot.
   - **Purpose in Project:** Mandatory for testing core systems like procedural generation, entity simulation, and tabletop mechanics. Ensures stability in first-person and multiplayer modes.
   - **Usage Guidelines:**
     - **Integration:** Already set up in `res://tests/`. Use for all new features.
     - **Implementation Steps:**
       1. Create test scripts in `res://tests/` (e.g., `res://tests/TestPlayerController.gd`).
       2. Follow GUT conventions: Extend `GutTest`, use `assert_eq()`, etc.
       3. Run tests via MCP: Use `run_project` with GUT command-line args if needed, or integrate into a test runner scene.
       4. Test addon integrations: E.g., verify Terrain3D heightmap generation.
     - **Best Practices:**
       - Write tests for every public function in core scripts.
       - Use for data-driven validation: Load JSON files and assert structures.
       - Automate: After major changes, run GUT tests and commit only if all pass.
       - Cover edge cases: E.g., dice rolling physics, fog of war visibility.
     - **Potential Issues:** Keep tests isolated – mock dependencies like singletons.
     - **Example Prompt Snippet for Cursor:**  
       ```
       Create GUT test script res://tests/TestMapGenerator.gd testing procedural world generation. Include asserts for biome distribution. Run project with GUT to verify.
       ```

## 3. Monitor Overlay (v1.1.0)
   - **Author:** HungryProton
   - **Description:** In-game overlay for monitor metrics (like the editor's Monitor tab).
   - **Purpose in Project:** Real-time performance monitoring during first-person exploration and tabletop sessions. Complements Debug Menu for optimization.
   - **Usage Guidelines:**
     - **Integration:** Similar to Debug Menu – optional overlay for dev builds.
     - **Implementation Steps:**
       1. Add MonitorOverlay node via MCP to a debug scene or HUD.
       2. Wrap in a manager script (e.g., `res://scripts/managers/MonitorManager.gd`).
       3. Toggle with `visible = OS.is_debug_build()`.
       4. Customize to show relevant metrics (e.g., draw calls for 3D world, physics ticks for dice).
       5. Add GUT tests for overlay functionality.
     - **Best Practices:**
       - Position in corner to not obstruct gameplay.
       - Theme integration: Apply `res://themes/bg3_theme.tres` to text labels.
       - Use sparingly: Only enable when profiling.
     - **Potential Issues:** High overhead – disable in performance tests.
     - **Example Prompt Snippet for Cursor:**  
       ```
       Add MonitorOverlay to res://scenes/ui/HUD.tscn via MCP. Create wrapper script res://scripts/managers/MonitorManager.gd with debug toggle. Test in running project.
       ```

## 4. ProceduralWorldMap (version not specified) - **EXPLICITLY SUPPORTED CORE SYSTEM**
   - **Author:** Edwin Cox
   - **Description:** Procedural world map using FastNoiseLite.
   - **Purpose in Project:** **Core system** that generates 2D procedural maps which seed Terrain3D's procedural terrain generation. Essential for the procedural world pipeline: MapGenerator → ProceduralWorldMap → Terrain3D. Integrates with existing MapGenerator and Terrain3D for biomes and civilizations.
   - **Usage Guidelines:**
     - **Integration:** Core dependency - already integrated. Extend or wrap for the project's data-driven world builder. Required for world generation pipeline.
     - **Implementation Steps:**
       1. Use in `res://scripts/core/MapGenerator.gd` or via wrapper like `res://scripts/procedural/WorldMapProcedural.gd`.
       2. Configure via JSON (e.g., `res://data/config/terrain_generation.json` for noise params).
       3. Generate 2D maps and export data to Terrain3D for 3D terrain rendering (core pipeline: ProceduralWorldMap generates map data → seeds Terrain3D heightmaps).
       4. Add GUT tests for noise consistency, biome mapping, and integration with Terrain3D.
     - **Best Practices:**
       - Make data-driven: Load noise types, seeds from JSON.
       - Seed control: Use reproducible seeds for save/load compatibility.
       - Performance: Optimize for large worlds; stream chunks efficiently.
       - Extensibility: Allow modding via custom noise configs in `res://data/config/`.
       - **Core dependency:** Do not remove or disable - required for procedural world generation.
     - **Potential Issues:** Version unspecified – assume stable; test for Godot 4.5.1 compatibility. Ensure seamless integration with Terrain3D generation pipeline.
     - **Example Prompt Snippet for Cursor:**  
       ```
       Modify res://scripts/core/MapGenerator.gd to use ProceduralWorldMap for generating 2D map data that seeds Terrain3D terrain generation. Use data from res://data/config/terrain_generation.json. Add GUT tests verifying the ProceduralWorldMap → Terrain3D pipeline and run project.
       ```

## 5. Terrain3D (v1.0.0)
   - **Author:** Cory Petkovsek & Roope Palmroos
   - **Description:** High-performance editable terrain system for Godot 4.
   - **Purpose in Project:** Core for procedural 3D world terrain, supporting first-person exploration, grid-based tabletop maps, and dynamic editing (e.g., GM tools).
   - **Usage Guidelines:**
     - **Integration:** Already integrated; build upon for streaming and simulation.
     - **Implementation Steps:**
       1. Use in `res://scenes/core/World.tscn` or via WorldStreamer singleton.
       2. Generate terrain from procedural data (e.g., heightmaps from MapGenerator).
       3. Add physics for interaction (e.g., raycasts for placement).
       4. Support editing: Integrate with MapEditor for runtime changes.
       5. Add GUT tests for terrain loading, editing, and performance.
     - **Best Practices:**
       - Data-driven: Load biomes, textures from `res://data/biomes.json`.
       - Performance: Use LOD, culling; target 60 FPS with full entities.
       - Extensibility: Expose APIs for modding (e.g., custom biomes).
       - Tabletop Synergy: Overlay grids/fog on terrain surface.
     - **Potential Issues:** Ensure compatibility with Godot 4.5.1; monitor VRAM usage.
     - **Example Prompt Snippet for Cursor:**  
       ```
       Enhance res://scripts/core/WorldStreamer.gd with Terrain3D chunk loading based on player position. Use MCP to update scenes, add tests, and run project for verification.
       ```

**Final Notes for Cursor:** Always start prompts with the required header from project rules. Reference these guidelines explicitly (e.g., "Follow addon guidelines for Terrain3D integration"). If conflicts arise, prioritize master project rules and seek clarification. Commit after successful tests.
