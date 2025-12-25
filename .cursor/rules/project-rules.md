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
├── materials/           # Material resources – ALLOWED
└── project.godot
```

**Note:** Additional folders (`addons/`, `demo/`, `tests/`, `tools/`, `shaders/`, `materials/`) are explicitly permitted and do not require rule changes. Terrain3D, GUT, ProceduralWorldMap, and godot_wry are explicitly supported addons (core systems for procedural world generation and web content embedding).

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

Preferred Godot MCP server: Coding-Solo/godot-mcp (free, open-source, MIT-licensed)

You may ONLY use these Godot MCP actions:
- run_project, stop_project, get_debug_output
- create_scene, add_node, set_property, attach_script, save_scene, get_scene_tree, etc.
- read_file, write_file, list_files

You may aggressively use Godot MCP to create/modify/save scenes and scripts.

After major changes you MAY call run_project to test (unless explicitly told "do not run").

All other MCP servers (obsidian, github-mcp-server, memory, blender) are available.

When finishing a logical feature → auto commit + push via github-mcp-server with clear message (feat/genesis:, fix:, refactor:, etc.).

You MUST obey 100% the folder structure, naming conventions, typed GDScript, and theme rules above.
Never create files outside allowed paths.
Always use the current theme path res://themes/bg3_theme.tres
Always add the exact script header shown in rule 3.
```

## 6. MCP Usage Policy

- **`launch_editor` is PERMANENTLY DISABLED.**
- **Preferred MCP server:** Coding-Solo/godot-mcp (free, open-source, MIT-licensed) - supports all core needs without cost.
- `run_project` encouraged after significant changes.
- All other Godot MCP actions preferred when they accelerate development.
- See `.cursor/rules/mcp-usage.md` for detailed MCP usage guidelines.

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
- Existing systems (WorldStreamer, EntitySim, FactionEconomy, Terrain3D integration, procedural world map generator, godot_wry WebView integration) take precedence.

## 10. Current Implementation Status

### ✅ Implemented
- Procedural world generation (MapGenerator, MapRenderer, MapEditor) with Terrain3D integration
- Terrain3D integration and streaming
- 8-step World Builder UI wizard with Azgaar Fantasy Map Generator integration
- Azgaar WebView integration using godot_wry (replaced GDCef) for embedded world generation
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

## 11. GUI Specification: Philosophy & Structural Guidelines

**IMPORTANT UPDATE (2025-12-17):** GameGUI addon fully removed. Godot's built-in containers, size flags, anchors, theme overrides, and `UIConstants.gd` now handle all dynamic/responsive scaling needs. This eliminates runtime/export errors permanently while maintaining immersive, proportional layouts.

### 11.1 GUI Philosophy (Core Principles – Never Compromise)
Our GUI design blends classic tabletop RPG tactility (e.g., character sheets, dice rolls) with immersive fantasy aesthetics, inspired by Baldur's Gate 3's worn parchment, ornate frames, and intuitive flow. The goal is a seamless, responsive interface that feels like an extension of the game's lore—ancient tomes and mystical artifacts—rather than a modern app overlay. For character creation and world generation menus (which are non-3D contexts), prioritize:

- **Immersion & Diegesis:** UI elements should feel "in-world" where possible (e.g., menus as floating scrolls or engraved stone tablets). Even flat 2D menus incorporate subtle fantasy flourishes like glowing runes or parchment textures. Avoid sleek/minimalist modern UIs; embrace ornate, thematic density without overwhelming the user.

- **Clarity & Intuitiveness:** Follow AAA RPG principles (e.g., BG3's UI): Clear hierarchy, consistent icons/symbols, and no unnecessary handholding. Users should navigate instinctively—e.g., tooltips for stats, visual feedback on hovers. Prioritize readability on varied hardware (mid-range PCs, potential future consoles).

- **Responsiveness & Accessibility:** All UI must adapt to any resolution/aspect ratio without clipping or distortion. No fixed pixels; everything relative or theme-driven. Support color-blind modes, scalable fonts, and keyboard/mouse/controller navigation from day one. UI must scale content (text, buttons, panels) proportionally while adapting layout.

- **Data-Driven & Extensible:** Align with project goals—100% JSON/Resources for content (e.g., races.json for character creation). UI layouts pull from configs for easy modding. Maintain 60 FPS even with complex menus.

- **Consistency with Project Rules:** Zero hard-coded values (use constants/theme overrides). All styling via res://themes/bg3_theme.tres (or migrated equivalent). GDScript only, typed, with proper headers/docstrings.

- **BG3-Inspired Touchpoints:** Menus evoke BG3's character creator (modular panels, 3D previews) and world maps (interactive overlays). But adapt for our virtual tabletop twist: e.g., world gen as a "ritual" wizard with procedural previews.

- **Dynamic Responsiveness Emphasis:** Leverage Godot's built-in containers, size flags, anchors, theme overrides, and `UIConstants.gd` for true dynamic scaling (e.g., text/buttons that proportionally grow/shrink while maintaining layout integrity across resolutions).

### 11.2 Structural Guidelines (Mandatory Practices)

#### 11.2.1 Node Hierarchy & Layout Fundamentals
- **Root Node:** Always a `Control` or `CanvasLayer` for menus. Use `anchors_preset = 15` (PRESET_FULL_RECT) for full-screen coverage, ensuring it expands to viewport size.

- **Layout Containers as Default:** Build with nested containers for responsiveness:
  - Use `VBoxContainer` / `HBoxContainer` for vertical/horizontal stacking (e.g., stat rows, button rows, sidebar layouts).
  - Use `CenterContainer` for centering main content (e.g., title labels or 3D preview windows).
  - Use `MarginContainer` for consistent padding (pull margins from `UIConstants` or theme constants, not hard-coded pixels).
  - Use `HSplitContainer` / `VSplitContainer` for resizable panels (e.g., left-side options, right-side preview in world gen and character creation).
  - Avoid raw `Control` nodes without containers—they lead to manual positioning issues and poor responsiveness.

- **Size Flags:** Explicitly set on relevant children:
  - `size_flags_horizontal = Control.SIZE_EXPAND_FILL` (3) to allow horizontal growth.
  - `size_flags_vertical   = Control.SIZE_EXPAND_FILL` (3) to allow vertical growth.
  - Use `SIZE_FILL` / `SIZE_EXPAND` selectively for elements that should maintain intrinsic size (e.g., icons).

- **Anchors & Offsets:**
  - Prefer anchor presets (e.g., full rect, top, bottom) over manual anchors.
  - Keep offsets minimal and semantic (e.g., use `UIConstants` for margins instead of arbitrary numbers).

- **Advanced Proportional Scaling:**
  - Use theme overrides (font sizes, constants) + runtime calculations in `_notification(NOTIFICATION_RESIZED)` or `_notification(NOTIFICATION_THEME_CHANGED)` when needed.
  - Example: Recompute panel widths based on `get_viewport().get_visible_rect().size` and clamp to min/max values from `UIConstants`.

- **Hybrid Approach:**
  - Use built-in containers with explicit size flags and anchors for 95% of layouts.
  - Add small, focused custom scripts (optionally with `@tool`) only for rare, advanced dynamic behavior (e.g., special proportional layouts, auto-clamping behavior). Keep these scripts local to UI folders (`scripts/ui/`).

- **Stretch Mode:** Project settings: Set `display/window/stretch/mode = "viewport"` and `aspect = "expand"` for responsive scaling. Test on multiple resolutions (e.g., 1080p, 4K, ultrawide).

#### 11.2.2 Sizing & Positioning Rules
- **No Magic Numbers:** Ban hard-coded pixels for sizes/positions (e.g., no `custom_minimum_size = Vector2(150, 0)` sprinkled across scenes). Replace with:
  - `UIConstants.gd` (primary source for semantic sizes like button heights).
    - Location: `res://scripts/ui/UIConstants.gd`
    - Implementation: `class_name UIConstants` (not autoload).
  - Theme constants (add to `bg3_theme.tres`, e.g., `constant/button_height_small = 50` for built-in styling).
  - Runtime calculations: e.g., `size = get_viewport().get_visible_rect().size * Vector2(0.8, 0.6)` for 80% width / 60% height.

- **Relative Positioning:**
  - Use anchors + margins instead of absolute offsets wherever possible.
  - Example: for a top-right debug overlay, anchor to `PRESET_TOP_RIGHT` and set `margin_right = -UIConstants.SPACING_MEDIUM` instead of hard-coding a position.

- **Responsive Testing:**
  - Every menu scene must handle window resize via `_notification(NOTIFICATION_RESIZED)` or equivalent.
  - Clamp positions to screen bounds to prevent off-screen issues (e.g., `position.x = clamp(position.x, 0.0, viewport_size.x - rect_size.x)`).

- **Standard Sizes:** Define tiers in UIConstants.gd:

| Category | Name | Value | Usage Example |
|----------|------|-------|---------------|
| Button Height | BUTTON_HEIGHT_SMALL | 50 | Small action buttons |
| | BUTTON_HEIGHT_MEDIUM | 80 | Standard menu buttons |
| | BUTTON_HEIGHT_LARGE | 120 | Prominent calls-to-action (e.g., Generate World) |
| Label Width | LABEL_WIDTH_NARROW | 80 | Value displays (numbers, short tags) |
| | LABEL_WIDTH_STANDARD | 150 | Most descriptive labels |
| | LABEL_WIDTH_WIDE | 200 | Long text fields (e.g., seed input) |
| Spacing / Margin | SPACING_SMALL | 10 | Tight grouping |
| | SPACING_MEDIUM | 20 | Standard separation |
| | SPACING_LARGE | 40 | Section breaks |
| Icon Size | ICON_SIZE_SMALL | 32 | Inline icons |
| | ICON_SIZE_MEDIUM | 64 | Buttons, previews |
| | ICON_SIZE_LARGE | 128 | Hero icons, logos |

#### 11.2.3 Theme & Styling Integration
- **Central Theme Enforcement:**
  - Every `Control`-based UI scene uses `res://themes/bg3_theme.tres` as its theme.
  - Apply theme either at root (`theme = preload("res://themes/bg3_theme.tres")`) or via project settings.
  - Use overrides sparingly, only for hierarchy (e.g., larger fonts for titles), and document with comments.

- **Fantasy Aesthetics:**
  - Fonts: Ornate/serif for titles (e.g., gold-tinted `Color(1, 0.843, 0, 1)`).
  - Colors: Earthy tones, gradients for depth (e.g., parchment beige with shadow edges).
  - Icons/Textures: From `res://assets/icons/` or `res://assets/ui/`—e.g., scroll borders for panels.

- **Overrides vs. Hard-Codes:**
  - Prefer theme or `UIConstants` overrides (e.g., `theme_override_constants/separation = UIConstants.SPACING_MEDIUM`) over direct literals.

#### 11.2.4 Specific Guidelines for Character Creation Menus
- **Structure:** Wizard-style flow (multi-step, like world builder UI).

  - **Root:**
    - Full-screen `Control` or `VBoxContainer` as root, with `anchors_preset = PRESET_FULL_RECT` and size flags set to expand/fill.

  - **Top (Title Area):**
    - `CenterContainer` containing a `Label` for the title.
    - Use theme overrides for font size and color (e.g., large gold title).

  - **Middle (Main Content Area):**
    - `HSplitContainer` or `HBoxContainer` for left/right layout:
      - **Left Panel:** `VBoxContainer` for options (race, class, stats), each row using reusable scenes like `AbilityScoreRow.tscn`.
      - **Right Panel:** `Panel` containing a `SubViewport` (3D preview) or `TextureRect` (baked render). The panel should use size flags and anchors to take ~40% of width, centered or right-aligned.

  - **Bottom (Navigation):**
    - `HBoxContainer` for Back/Next/Confirm buttons.
    - Buttons use `custom_minimum_size.y = UIConstants.BUTTON_HEIGHT_MEDIUM` and size flags to center horizontally.

- **Interactivity:**
  - Use raycasts for 3D model interaction (e.g., click/drag to rotate character).
  - Use signals to update preview dynamically as stats or selections change.

- **Data-Driven:**
  - Pull options from JSON (e.g., `fantasy_archetypes.json`, future `races.json`, `classes.json`).
  - Use `ItemList`, `OptionButton`, or `Tree` for lists depending on density.

#### 11.2.5 Specific Guidelines for World Generation Menus
- **Structure:** 8-step wizard (built on existing `WorldBuilderUI.tscn` at `res://ui/world_builder/WorldBuilderUI.tscn`).

  - **Root:**
    - Full-screen `Control` with background texture (e.g., mystical map overlay) using a `TextureRect` or `ColorRect` + theme colors.

  - **Main Layout:**
    - `HSplitContainer` for left (controls) and right (previews):
      - **Left Panel (Step Controls):**
        - `VBoxContainer` with labels, sliders, dropdowns, and toggles.
        - Use `UIConstants` for label widths and spacing.
      - **Right Panel (Preview):**
        - **WebView Integration (godot_wry):** Uses `WebView` node (from godot_wry addon) to embed Azgaar Fantasy Map Generator.
          - Node type: `WebView` (declared as `type="WebView"` in `.tscn`)
          - Key methods: `load_url(url: String)`, `execute_js(code: String) -> Variant`, `eval(code: String) -> Variant`, `post_message(message: String)`
          - Key signals: `ipc_message(message: String)` for bidirectional communication
          - Sized via anchors and size flags (no fixed viewport sizes)
        - **Alternative previews:** `TabContainer` or stacked `Control` nodes allowing switching between WebView (Azgaar) and 3D Terrain3D preview.
        - For 3D: `SubViewportContainer` + `SubViewport` sized via anchors and size flags.

  - **Progress/Step Indicator:**
    - `HBoxContainer` at top or bottom with step icons/labels.

  - **Bottom Controls:**
    - `HBoxContainer` for Back/Next/Generate buttons, using `UIConstants` for button heights and spacing.

- **WebView Integration (godot_wry):**
  - **Addon:** `res://addons/godot_wry/` - WebView embedding addon (replaced GDCef)
  - **Usage:** Azgaar Fantasy Map Generator embedded via `WebView` node
  - **Communication:** JavaScript execution via `execute_js()`/`eval()`, bidirectional IPC via `ipc_message` signal
  - **Script:** `res://scripts/ui/WorldBuilderAzgaar.gd` handles WebView initialization, JS execution, and parameter syncing
  - **Manager:** `res://scripts/managers/AzgaarIntegrator.gd` manages Azgaar asset copying and URL generation
  - **Assets:** `res://tools/azgaar/` contains full Azgaar bundle (HTML, JS, CSS, images, heightmaps)

- **3D Integration:**
  - After 2D map baking, allow toggling to a 3D view of the same world.
  - Use a simple camera (orbit/fly-cam) and minimal lights to avoid performance issues.

- **Progress Dialog:**
  - Use `Window` or `Panel` with `VBoxContainer` for:
    - Title/Status `Label`
    - `ProgressBar`
  - Size via content (e.g., padding from `UIConstants`), not fixed pixels.

#### 11.2.6 Performance & Testing
- **Optimization:**
  - Limit draw calls by:
    - Reusing themes and styleboxes.
    - Using `NinePatchRect` for scalable backgrounds instead of large textures.
  - Ensure UI updates are lightweight (avoid expensive operations in `_process`).

- **Testing:**
  - Test with full UI active (complex scenes, multiple panels).
  - Validate 60 FPS on target hardware configurations.
  - Resize tests: 1080p, 1440p, 4K, ultrawide, windowed mode.

- **Audit Compliance:**
  - All new/changed UI must pass a mini-audit: no magic numbers, theme-applied, responsive on resize.

#### 11.2.7 Accessibility Guidelines
- Support scalable UI via project setting `display/window/stretch/scale_mode = "fractional"`.
- Provide high-contrast theme variant (future: toggle in options).
- Ensure all interactive elements are focusable and have visible focus indicators.
- Use color + icon/shape for critical info (avoid color-only cues).

#### 11.2.8 Error Handling
Error states (e.g., failed world generation, invalid character data) should use a centered modal `Panel` with:
- A bold title `Label` (e.g., "World Generation Failed")
- A descriptive `Label` explaining the issue
- "Retry" and "Back" buttons in an `HBoxContainer`
- A distinct error-tinted style (e.g., reddish border) while remaining on-brand via theme.

### 11.3 Project Settings (Add to project.godot)
```
[display]
window/stretch/mode = "viewport"
window/stretch/aspect = "expand"
window/stretch/scale = 1.0
window/stretch/scale_mode = "fractional" # Enables UI scaling
```

### 11.4 Implementation Workflow (For Grok/Cursor Prompts)
- Start prompts with: `[GENESIS MYTHOS GUI SPEC v5 – BUILT-IN RESPONSIVE UI ONLY]`.
- For new menus: Specify scene path (e.g., `res://scenes/character_creation/CharacterCreator.tscn`), node tree, and scripts.
- For modifications: Audit before/after for compliance (e.g., replace magic numbers with `UIConstants` usage).
- Testing: Use `run_project` to verify no clipping on resize and stable FPS.
- All UI scripts must follow core project rules: exact header block, typed GDScript, one class per file, docstrings on public functions.

### 11.5 Migration Plan (Phased & Safe – GameGUI Removed)
1. **Phase 0: Setup & Cleanup**
   - Remove or archive the `res://addons/gamegui/` folder outside the project (no longer used).
   - Create `UIConstants.gd` at `res://scripts/ui/UIConstants.gd` with the canonical constants table from Section 11.2.2.
   - Update `project.godot` with display settings from Section 11.3.
   - Commit: `"feat/genesis: Remove GameGUI addon, add UIConstants.gd, and update project settings"`.

2. **Phase 1: Quick Wins (Low Risk)**
   - Refactor `MainMenu.tscn` (`res://scenes/MainMenu.tscn`):
     - Ensure root is full-screen `Control` or `VBoxContainer` with full rect anchors.
     - Use `VBoxContainer` / `HBoxContainer` for layout; remove any magic numbers.
     - Replace hard-coded button sizes with `UIConstants.BUTTON_HEIGHT_MEDIUM`.
   - Test responsiveness (window resize, different resolutions).
   - Commit: `"feat/genesis: Make MainMenu responsive with built-in containers and UIConstants"`.

3. **Phase 2: World Generation Menus**
   - Update `WorldBuilderUI.tscn` / `WorldBuilderUI.gd` at `res://ui/world_builder/`:
     - Replace any remaining magic numbers with `UIConstants` or theme constants.
     - Ensure all major panels use proper anchors and size flags.
     - Make previews rely on anchors/flags (no fixed viewport sizes).
   - Test responsiveness and performance while generating worlds.
   - Commit: `"feat/genesis: Refactor WorldBuilderUI to built-in responsive layout"`.

4. **Phase 2.5: Bulk Migrate Scenes**
   - Use Find in Files to locate:
     - `custom_minimum_size = Vector2(`
     - `offset_left`, `offset_top`, `offset_right`, `offset_bottom`
   - Replace with `UIConstants`-driven sizes or anchor/margin-based layouts.
   - Ensure each modified scene passes resize tests.

5. **Phase 3: Character Creation (Future)**
   - Build new character creation scenes using only built-in containers and `UIConstants`:
     - `res://scenes/character_creation/CharacterCreator.tscn`
     - `res://scripts/character_creation/CharacterCreator.gd`
   - Follow guidelines from Section 11.2.4.

6. **Phase 4: Global Polish**
   - Make progress dialogs and overlays fully responsive:
     - Use `Panel`/`Window` + containers and `UIConstants`.
   - Perform a final audit: no remaining magic numbers, all UI responsive.
   - Commit: `"feat/genesis: Global UI polish with built-in responsive layout"`.

**Rule:** Migrate one scene at a time. Use `run_project` after each to verify no clipping/FPS drop.

### 11.6 UI Change Checklist (Mandatory for All UI Work)
- [ ] Built-in containers (VBoxContainer/HBoxContainer/etc.) with explicit size flags/anchors for scaling
- [ ] No hard-coded pixels (>10 not in `UIConstants`)
- [ ] Theme applied (`bg3_theme.tres`)
- [ ] Tested: 1080p, 4K, ultrawide, window resize
- [ ] Size flags and anchors explicitly set for key nodes
- [ ] Keyboard/controller focus logical and navigable

---

**THESE RULES ARE CURRENT AND AUTHORITATIVE AS OF 2025-12-20. MAJOR CHANGES REQUIRE EXPLICIT APPROVAL AND AUDIT.**

**UPDATE 2025-12-20:** Godot version updated to 4.5.1 stable (migration complete). Repository URL added. ProceduralWorldMap upgraded to explicitly supported addon status (core system that generates 2D maps seeding Terrain3D procedural generation).

**UPDATE 2025-12-24:** godot_wry addon integrated for WebView embedding. GDCef fully removed and replaced with godot_wry for Azgaar World Builder UI integration. WebView node type (`type="WebView"`) now used for embedded web content with JavaScript execution and bidirectional IPC communication via `ipc_message` signal. See `res://scripts/ui/WorldBuilderAzgaar.gd` for implementation details.
