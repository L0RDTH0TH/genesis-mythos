# ╔═══════════════════════════════════════════════════════════
# ║ COMPLETE & FINAL PROJECT RULES – ITERATION 7
# ║ GENESIS MYTHOS – FULL FIRST PERSON 3D VIRTUAL TABLETOP RPG IN GODOT 4.6-BETA2
# ║ Valid for Grok AND Cursor – major changes require explicit approval
# ╚═══════════════════════════════════════════════════════════

## 1. Master Goals (never compromise)

- Full first-person 3D immersive virtual tabletop role-playing game with original "Genesis Mythos" lore and systems.
- Core experience: seamless blend of true first-person exploration (FPS-style movement, interaction, combat) and classic tabletop elements (dice rolling, character sheets, GM tools, grid maps, tokens, fog of war).
- Supports single-player, hosted multiplayer sessions, and future modding.
- Godot 4.6-beta2 only.
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
│   ├── ui/              # Legacy Godot UI textures (may be deprecated)
│   └── ui_web/          # NEW: Local HTML, CSS, JS, Alpine.js templates for embedded GUIs
│       ├── templates/   # HTML files for menus (e.g., world_builder.html, character_creator.html)
│       ├── css/         # Shared styles (fantasy-themed, responsive)
│       ├── js/          # Shared scripts + Alpine.js
│       └── images/      # UI-specific images/icons
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
│   ├── ui/              # Godot scenes hosting WebView nodes for menus/overlays
│   ├── character_creation/  # WebView-based character creator
│   ├── tabletop/        # Dice roller, token scenes, map overlays
│   └── tools/           # GM tools, map editor, world builder (WebView hosts)
├── scripts/
│   ├── core/            # Core logic scripts
│   ├── ui/              # Scripts managing WebView nodes, IPC, JS bridging
│   ├── character_creation/
│   ├── tabletop/
│   └── managers/        # Save system, data loading, future networking, AzgaarIntegrator
├── themes/              # Legacy Godot themes (bg3_theme.tres – may be deprecated)
├── addons/              # Plugins (Terrain3D, GUT, godot_wry, ProceduralWorldMap) – ALLOWED
├── demo/                # Demo scenes and tests – ALLOWED
├── tests/               # Unit/integration tests (using GUT) – ALLOWED
├── tools/               # Editor tools and utilities (including azgaar/ bundle) – ALLOWED
├── shaders/             # Custom shaders – ALLOWED
├── materials/           # Material resources – ALLOWED
└── project.godot
```

**Note:** Additional folders (`addons/`, `demo/`, `tests/`, `tools/`, `shaders/`, `materials/`, `assets/ui_web/`) are explicitly permitted. godot_wry is a core supported addon for all GUI embedding.

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
- No magic numbers → use constants
- Every public function has a `"""docstring"""`
- Legacy theme (`res://themes/bg3_theme.tres`) may remain for minimal Godot UI elements but is deprecated for new work.

## 4. Grok AI Rules (prompt format)

- Every prompt to Grok starts with: `[GENESIS MYTHOS GODOT 4.6-BETA2 – FOLLOW ALL RULES BELOW]`
- Specify full path + exact class name for new scripts.
- For modifications: explicitly state "Modify existing file res://path/ClassName.gd"
- Never request more than one complete script file per prompt (except tiny utilities < 50 lines).
- For HTML/JS: Request full file content with path (e.g., res://assets/ui_web/templates/world_builder.html).

## 5. Cursor Rules – MUST be pasted at the TOP of EVERY prompt to Cursor

```
[GENESIS MYTHOS – FULL FIRST PERSON 3D VIRTUAL TABLETOP RPG – GODOT 4.6-BETA2]

YOU ARE STRICTLY FORBIDDEN FROM EVER USING THE "launch_editor" MCP ACTION.

Preferred Godot MCP server: Coding-Solo/godot-mcp (free, open-source, MIT-licensed)

You may ONLY use these Godot MCP actions:
- run_project, stop_project, get_debug_output
- create_scene, add_node, set_property, attach_script, save_scene, get_scene_tree, etc.
- read_file, write_file, list_files

You may aggressively use Godot MCP to create/modify/save scenes, scripts, and HTML/JS files.

After major changes you MAY call run_project to test (unless explicitly told "do not run").

All other MCP servers (obsidian, github-mcp-server, memory, blender) are available.

When finishing a logical feature → auto commit + push via github-mcp-server with clear message (feat/genesis:, fix:, refactor:, etc.).

You MUST obey 100% the folder structure, naming conventions, typed GDScript, and GUI rules below.
Never create files outside allowed paths.
Always use godot_wry WebView for GUI.
```

## 5.5 Interactive Testing & Wait Time Protocol

To ensure accurate testing during interactive sessions (e.g., via run_project), ALWAYS calculate and apply wait times based on the following three parts: an Estimation Table for baselines, Adjustment Rules for refinements, and a Workflow Protocol for execution. This protocol applies whenever run_project is used for user-involved testing, such as triggering UI interactions, scene navigation, or event responses.

### Estimation Table
Use this table for baseline wait times. Categories are based on common Genesis Mythos testing patterns. All times are in seconds.

| Interaction Type          | Base Wait | Extended Wait | Use Extended When                  | Completion Signals                                                                 |
|---------------------------|-----------|---------------|------------------------------------|------------------------------------------------------------------------------------|
| Simple UI Click/Hover     | 5         | 10            | Multi-step or first attempt        | "Button clicked" log, state change event, or "UI interaction complete"            |
| Multi-Step UI Flow        | 15        | 30            | >3 steps or form dependencies      | "Form submitted" log, final step confirmation, or "Wizard complete"               |
| Scene Navigation/Exploration | 20     | 45            | Procedural loads or large terrain  | "Scene ready" log, FPS stabilized >30 for 5s, or "Navigation complete"            |
| Event Trigger & Response  | 10        | 25            | Physics/animation heavy            | "Interaction complete" log, no active physics updates, or animation end signal    |
| Procedural Generation     | 30        | 60            | Large world or Azgaar integration  | "Generation complete" log, "Terrain loaded" signal, or no pending procedural tasks|
| Multiplayer/Networking Sim| 20        | 40            | Session join/host or sync checks   | "Network connected" log, "Sync complete" signal, or stable connection status      |
| Full Feature Test         | 45        | 90            | End-to-end flows (e.g., load → create → overlay) | Sum of sub-interaction signals, "Feature test complete" log                       |

- **First Run Flag**: For the first run after major changes (e.g., new feature addition), always use Extended Wait and add a 20s cold-start buffer.

### Adjustment Rules
1. **Scale by Complexity**: For interactions with >3 steps or dependencies (e.g., IPC with WebView), multiply base/extended by 1.5x.
2. **User Factors**: If prior feedback indicates slow user (from chat history or adjustments), add 10-20s buffer. For fast users, reduce by 20%.
3. **Hardware Guidelines**: If debug output shows sustained FPS <30, consider adding 50% buffer. If load times >5s, add 15s. These are guidelines—apply judgment to avoid over-adjustment during natural fluctuations (e.g., terrain streaming).
4. **Dynamic Polling**: During waits, use get_debug_output every 10s to check for completion signals. Use exact log strings where possible (e.g., "World generation complete"). Fallback: If no signal, check for absence of error logs and stable FPS (>30) for 5s.
5. **Signal Timeout**: If expected signal not found within 2x base wait, treat as potential failure, notify user (e.g., "No completion signal detected—possible issue?"), and extend by 50%.
6. **Max Cap**: Never exceed 120s without explicit user confirmation. If needed, pause and ask: "Need more time? Reply to continue."
7. **Learning Loop**: After each test, log adjustments in commit messages using this format: `[WAIT-ADJUSTMENT] Interaction: [type], Estimated: [X]s, Actual Needed: [Y]s, Adjustment: [+/-Z]s`. Reference prior adjustments in future estimates for similar interactions. Also, store in memory for immediate session reference.
8. **Sequential Interactions**: For N sequential interactions, sum individual waits + 10s buffer per transition. Example: UI click (5s) → Scene nav (20s) → Event trigger (10s) = 35s + 20s buffer = 55s.
9. **Parallel Interactions**: If user indicates testing multiple unrelated features simultaneously, sum individual waits without transition buffers.
10. **Debug Output Fallback**: If get_debug_output is empty or malformed, rely on time-based estimates only and add 25% safety buffer.
11. **User Intervention**: If the user sends any message during the wait, immediately stop the timer, call get_debug_output to check current state, and proceed or adjust based on output before resuming.

### Workflow Protocol
Follow these steps strictly for every run_project call involving user interactions:
1. **Before run_project**: Explicitly state the expected interaction type(s), estimated wait time (after adjustments), and key completion signals in your response (e.g., "Waiting 30s for procedural generation; looking for 'Generation complete' log").
2. **After run_project**: Start the timer and begin polling get_debug_output every 10s.
3. **During Wait**:
   - At 50% of estimated time: Send a brief status message (e.g., "Waiting for [interaction]... halfway through estimated time").
   - Check for completion signals in each poll.
   - If incomplete at 100% of estimated time: Extend by 50%, notify user (e.g., "Extending wait by 15s as interaction not complete").
4. **On Completion**: Confirm with a message (e.g., "Interaction complete; proceeding"), log the [WAIT-ADJUSTMENT] for the learning loop.
5. **Post-Session Feedback (Optional)**: If there's uncertainty (e.g., extension triggered), ask: "Was the wait time sufficient? This helps calibrate future tests." Avoid if session was smooth to prevent annoyance.

## 6. MCP Usage Policy

- **`launch_editor` is PERMANENTLY DISABLED.**
- **Preferred MCP server:** Coding-Solo/godot-mcp
- `run_project` encouraged after significant changes.
- All other Godot MCP actions preferred.

## 7. Git & Version Control

- Repository: https://github.com/L0RDTH0TH/genesis-mythos.git
- Direct pushes to main allowed until branching strategy is defined.
- Commit messages: `feat/genesis:`, `fix:`, `refactor:`, etc.

## 8. Visual & UX Fidelity

- World: High-fidelity procedural fantasy environment with dynamic lighting, physics interaction, using Terrain3D.
- First-person controller: Smooth, responsive, Skyrim-like feel.
- Tabletop elements: 3D physics-based dice, draggable tokens, measurable grids, fog of war.
- UI: Fantasy-themed HTML/CSS/JS via embedded WebView (Alpine.js for reactivity). Diegetic where possible, clean overlays.
- Reference blend: TaleSpire + Tabletop Simulator + Skyrim + Foundry VTT.

## 9. Migration & Compatibility

- All new and refactored GUI must use godot_wry WebView + local HTML/JS/Alpine.
- Existing Godot Control-based UI may remain temporarily but should be migrated scene-by-scene.
- New folders/subsystems only with rule update approval.

## 10. Current Implementation Status

### ✅ Implemented
- Procedural world generation with Terrain3D
- Azgaar integration via godot_wry WebView
- Core singletons
- CreativeFlyCamera
- Basic save/load
- GUT testing

### 🔄 In Progress
- First-person character controller
- Full migration of all menus/overlays to WebView + HTML/JS/Alpine.js GUI system
- UI polish and consistency

### 📋 Planned / Future
- Full character creation (WebView-based)
- Tabletop overlay system
- Multiplayer networking
- Expanded sound integration

---

## 11. GUI Specification: Philosophy & Structural Guidelines (WEBVIEW + HTML/JS/ALPINE ERA)

**UPDATE (2025-12-28):** All GUI (menus, overlays, HUD elements, character creation, world builder, etc.) is now handled exclusively via embedded WebView nodes (godot_wry addon) loading local HTML/CSS/JS files. Alpine.js is the standard for client-side interactivity and reactivity. Godot's built-in Control nodes are deprecated for all new GUI work and should be phased out.

### 11.1 GUI Philosophy (Core Principles – Never Compromise)
- Immersion & Diegesis: UI feels "in-world" (parchment scrolls, ancient tomes, mystical runes) using fantasy-styled HTML/CSS (ornate fonts, parchment backgrounds, glowing effects via CSS).
- Clarity & Intuitiveness: AAA RPG flow (BG3-inspired hierarchy, tooltips, hover feedback). Alpine.js handles dynamic updates seamlessly.
- Responsiveness & Accessibility: CSS media queries, flexbox/grid for perfect adaptation to any resolution/aspect ratio. Support color-blind modes via CSS variables, scalable fonts, keyboard navigation.
- Data-Driven & Extensible: JSON data passed via IPC/post_message to JS. Easy modding by overriding HTML/JS templates.
- Performance: Local files ensure fast loading; Alpine.js is lightweight. Maintain 60 FPS even with complex menus.
- Consistency: Shared CSS/JS across all templates for unified fantasy look.

### 11.2 Structural Guidelines (Mandatory Practices)

#### 11.2.1 Godot Side (WebView Hosting)
- UI scenes contain a root `Node` with one or more `WebView` nodes (type="WebView").
- WebView sized via anchors/full-rect or layered (reminder: WebView renders on top – design overlays accordingly).
- Scripts bridge Godot ↔ JS:
  - Load local HTML: `webview.load_url("res://assets/ui_web/templates/example.html")`
  - IPC: Connect to `ipc_message` signal; use `webview.post_message(JSON.stringify(data))`
  - JS execution: `webview.execute_js(code)` or `eval(code)`
- Data flow: Godot loads JSON → post_message to JS → Alpine.js reacts and updates DOM.

#### 11.2.2 Web Side (HTML/CSS/JS/Alpine.js)
- All templates in `res://assets/ui_web/templates/`.
- Base structure:
  ```html
  <!DOCTYPE html>
  <html lang="en" x-data="appState()">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <script defer src="res://assets/ui_web/js/alpine.min.js"></script>
      <link rel="stylesheet" href="res://assets/ui_web/css/fantasy-base.css">
      <!-- Custom CSS per template -->
    </head>
    <body class="parchment-bg fantasy-font">
      <!-- Alpine.js reactive components -->
    </body>
  </html>
  ```
- Responsiveness: CSS flex/grid, media queries, rem/vw/vh units. No fixed pixels.
- Interactivity: Alpine.js (`x-data`, `x-bind`, `x-on`, `@click`, etc.) for state, forms, wizards.
- Fantasy Styling: Shared `fantasy-base.css` with variables (gold accents, serif fonts, parchment textures, shadow/glow effects).
- Bidirectional Communication: Listen for Godot messages via `window.ipc` or custom events; call back with injected bridge functions.

#### 11.2.3 Specific Guidelines
- **World Generation Menus**: Extend existing Azgaar WebView; overlay controls via additional layered WebView or integrated HTML wrapper using Alpine for step wizard.
- **Character Creation Menus**: Full HTML wizard with Alpine.js steps, dynamic previews (post_message to Godot for 3D model updates).
- **Overlays/HUD**: Transparent layered WebView nodes loading minimal HTML for diegetic elements (e.g., character sheet as floating scroll).
- **Progress/Error Modals**: Alpine.js components toggled via IPC.

#### 11.2.4 Performance & Testing
- Local `res://` loading ensures speed.
- Test across resolutions; verify no FPS drop with WebView active.
- Audit: Responsive CSS, no hard-coded pixels, fantasy theme consistent.

#### 11.2.5 Accessibility
- CSS variables for contrast modes.
- ARIA attributes, keyboard support via Alpine/focus management.

### 11.3 Implementation Workflow
- Prompts: `[GENESIS MYTHOS WEB GUI – GODOT_WRY + ALPINE.JS]`
- Create separate files for HTML/CSS/JS when needed.
- Use `run_project` to test IPC and responsiveness.

**THESE RULES ARE CURRENT AND AUTHORITATIVE AS OF 2025-12-28. MAJOR CHANGES REQUIRE EXPLICIT APPROVAL AND AUDIT.**

**UPDATE 2025-12-28:** Full migration to godot_wry WebView + HTML/CSS/JS/Alpine.js for all GUI complete. Built-in Godot Control-based UI deprecated. New `assets/ui_web/` structure added.

**UPDATE 2026-01-09:** Added section 5.5 for interactive testing wait time protocol to improve testing consistency.
