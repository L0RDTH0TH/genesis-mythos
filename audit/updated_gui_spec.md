# ╔═══════════════════════════════════════════════════════════
# ║ GUI SPECIFICATION: PHILOSOPHY & STRUCTURAL GUIDELINES
# ║ GENESIS MYTHOS – FULL FIRST PERSON 3D VIRTUAL TABLETOP RPG IN GODOT 4.5.1
# ║ Valid for Grok AND Cursor – major changes require explicit approval
# ║ Date: 2025-12-16 | Status: Finalized (Incorporates All Iterations)
# ╚═══════════════════════════════════════════════════════════

## 1. GUI Philosophy (Core Principles – Never Compromise)
Our GUI design blends classic tabletop RPG tactility (e.g., character sheets, dice rolls) with immersive fantasy aesthetics, inspired by Baldur's Gate 3's worn parchment, ornate frames, and intuitive flow. The goal is a seamless, responsive interface that feels like an extension of the game's lore—ancient tomes and mystical artifacts—rather than a modern app overlay. For character creation and world generation menus (which are non-3D contexts), prioritize:

- **Immersion & Diegesis:** UI elements should feel "in-world" where possible (e.g., menus as floating scrolls or engraved stone tablets). Even flat 2D menus incorporate subtle fantasy flourishes like glowing runes or parchment textures. Avoid sleek/minimalist modern UIs; embrace ornate, thematic density without overwhelming the user.

- **Clarity & Intuitiveness:** Follow AAA RPG principles (e.g., BG3's UI): Clear hierarchy, consistent icons/symbols, and no unnecessary handholding. Users should navigate instinctively—e.g., tooltips for stats, visual feedback on hovers. Prioritize readability on varied hardware (mid-range PCs, potential future consoles).

- **Responsiveness & Accessibility:** All UI must adapt to any resolution/aspect ratio without clipping or distortion. No fixed pixels; everything relative or theme-driven. Support color-blind modes, scalable fonts, and keyboard/mouse/controller navigation from day one. UI must scale content (text, buttons, panels) proportionally while adapting layout.

- **Data-Driven & Extensible:** Align with project goals—100% JSON/Resources for content (e.g., races.json for character creation). UI layouts pull from configs for easy modding. Maintain 60 FPS even with complex menus.

- **Consistency with Project Rules:** Zero hard-coded values (use constants/theme overrides). All styling via res://themes/bg3_theme.tres (or migrated equivalent). GDScript only, typed, with proper headers/docstrings.

- **BG3-Inspired Touchpoints:** Menus evoke BG3's character creator (modular panels, 3D previews) and world maps (interactive overlays). But adapt for our virtual tabletop twist: e.g., world gen as a "ritual" wizard with procedural previews.

- **Dynamic Responsiveness Emphasis:** Leverage advanced tools like GameGUI for true dynamic scaling (e.g., text/buttons that proportionally grow/shrink while maintaining layout integrity across resolutions).

## 2. Structural Guidelines (Mandatory Practices)
### 2.1 Node Hierarchy & Layout Fundamentals
- **Root Node:** Always a Control or CanvasLayer for menus. Use `anchors_preset = 15` (PRESET_FULL_RECT) for full-screen coverage, ensuring it expands to viewport size.

- **Layout Containers as Default:** Build with nested containers for responsiveness:
  - Prefer GameGUI nodes for complex/dynamic sections: `GGHBox`/`GGVBox` for vertical/horizontal stacking (e.g., stat rows in character creation), `GGComponent`-derived nodes like `GGMarginLayout` for dynamic sizing (modes: Expand, Fit, etc.).
  - `CenterContainer` for centering main content (e.g., title labels or 3D preview windows).
  - `MarginContainer` for consistent padding (pull margins from theme constants, not hard-codes).
  - `HSplitContainer`/`VSplitContainer` for resizable panels (e.g., left-side options, right-side preview in world gen).
  - Avoid raw Control nodes without containers—they lead to manual positioning issues.
  - Hybrid Approach: Use GameGUI nodes where scaling is needed; fall back to built-in Containers for simple cases.

- **Size Flags:** Explicitly set on all children: `size_flags_horizontal = 3` (FILL_EXPAND) and `size_flags_vertical = 3` for most elements to ensure they grow/shrink dynamically.

- **Stretch Mode:** Project settings: Set `display/window/stretch/mode = "viewport"` and `aspect = "expand"` for responsive scaling. Test on multiple resolutions (e.g., 1080p, 4K, ultrawide).

### 2.2 Sizing & Positioning Rules
- **No Magic Numbers:** Ban hard-coded pixels (e.g., no `custom_minimum_size = Vector2(150, 0)`). Replace with:
  - UIConstants.gd (primary source for semantic sizes like button heights) - located at `res://scripts/ui/UIConstants.gd`, uses `class_name UIConstants` (not autoload).
  - Theme constants (add to bg3_theme.tres: e.g., `constant/button_height_small = 50` for built-in styling).
  - Runtime calculations: e.g., `size = get_viewport().get_visible_rect().size * Vector2(0.8, 0.6)` for 80% width/60% height.
  - GameGUI parameters for dynamic overrides (e.g., min_size, max_size from constants).

- **Relative Positioning:** Use anchors/margins over offsets. E.g., for a top-right debug overlay: Anchor to `top_right` preset with `margin_right = -UIConstants.MARGIN_SMALL`.

- **Responsive Testing:** Every menu scene must handle window resize via `_notification(WINDOW_SIZE_CHANGED)`. Clamp positions to screen bounds to prevent off-screen issues (e.g., `position.x = clamp(position.x, 0, viewport_size.x)`).

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

### 2.3 Theme & Styling Integration
- **Central Theme Enforcement:** Every Control node loads `res://themes/bg3_theme.tres` in `_ready()` or via scene properties. Use overrides sparingly, only for hierarchy (e.g., larger fonts for titles), and document with comments. Apply to GameGUI nodes (they inherit Theme properties).

- **Fantasy Aesthetics:**
  - Fonts: Ornate/serif for titles (e.g., gold-tinted Color(1, 0.843, 0, 1)).
  - Colors: Earthy tones, gradients for depth (e.g., parchment beige with shadow edges).
  - Icons/Textures: From res://assets/icons/ or ui/—e.g., scroll borders for panels.

- **Overrides vs. Hard-Codes:** Prefer `theme_override_constants/separation = UIConstants.SPACING_MEDIUM` over direct values.

### 2.4 Specific Guidelines for Character Creation Menus
- **Structure:** Wizard-style flow (multi-step, like world builder UI).
  - Root: Full-screen GGVBox (or VBoxContainer for simplicity).
  - Top: Title (CenterContainer with large font).
  - Middle: HSplitContainer – Left: Options (GGVBox with rows for race/class/stats, using AbilityScoreRow.tscn prefab).
  - Right: 3D Preview Window (SubViewport in a GGComponent-derived node like GGMarginLayout/Panel; size 40% of screen, centered, with orbit camera for model rotation).
  - Bottom: Navigation buttons (GGHBox, centered, medium size).

- **Interactivity:** Raycasts for 3D model interaction (e.g., click to rotate). Stats update preview dynamically via signals.

- **Data-Driven:** Pull from JSON (e.g., fantasy_archetypes.json). Use ItemList or OptionButton for selections.

### 2.5 Specific Guidelines for World Generation Menus
- **Structure:** 8-step wizard (build on existing WorldBuilderUI.tscn at res://ui/world_builder/WorldBuilderUI.tscn).
  - Root: Full-screen Control with background texture (e.g., mystical map overlay).
  - Left/Right Split: HSplitContainer – Left: Step controls (GGVBox with sliders/labels from terrain_generation.json).
  - Right: Preview Panel (initially 2D map from ProceduralWorldMap, then baked 3D view in SubViewport after generation).
  - Progress Bar: Top GGHBox with step indicators (e.g., icons for biomes/civs).
  - Bottom: Generate/Back buttons (large, centered).

- **3D Integration:** Post-2D map baking, embed a minimal 3D scene in the preview (e.g., fly-cam for quick inspection). Use signals to update on param changes.

- **Progress Dialog:** Responsive popup (no fixed 400x120 size—use content_size instead, via GGComponent-derived nodes like GGMarginLayout).

### 2.6 Performance & Testing
- **Optimization:** Limit draw calls; use GGNinePatchRect for scalable backgrounds. Test FPS with full UI active.

- **Best Practices Integration:** Follow Godot docs—scenes for reusable components (e.g., ButtonPrefab.tscn), scripts for logic (e.g., MenuController.gd).

- **Audit Compliance:** All new/changed UI must pass a mini-audit: No hard-codes, theme-applied, responsive on resize.

### 2.7 Accessibility Guidelines
- Support scalable UI via project setting `display/window/stretch/scale_mode = "fractional"`.
- Provide high-contrast theme variant (future: toggle in options).
- Ensure all interactive elements are focusable and have visible focus indicators.
- Use color + icon/shape for critical info (avoid color-only cues).

### 2.8 Error Handling
Error states (e.g., failed world generation, invalid character data) should use a centered modal Panel with a bold title, descriptive Label, and "Retry/Back" buttons. Use a distinct error color from the theme (e.g., reddish tint) but remain on-brand.

## 3. GameGUI Integration (Primary Tool for Complex Menus)
- **Rationale:** GameGUI (https://godotengine.org/asset-library/asset/2168) provides advanced nodes for dynamic layout and scaling, addressing audit issues like clipping and inconsistent sizing.
- **Setup:** Folder: `res://addons/gamegui/`. Enable in Project Settings > Plugins.
- **Usage:** Primary for complex menus; compatible with themes and existing Controls.
- **Node Names:** Use exact names from GameGUI plugin:
  - `GGHBox` (not GGHBoxContainer)
  - `GGVBox` (not GGVBoxContainer)
  - `GGLabel`
  - `GGButton`
  - `GGNinePatchRect`
  - `GGMarginLayout` (for padding)
  - `GGComponent` (base class for dynamic sizing)

## 4. Project Settings (Add to project.godot)
```
[display]
window/stretch/mode = "viewport"
window/stretch/aspect = "expand"
window/stretch/scale = 1.0
window/stretch/scale_mode = "fractional" # Enables UI scaling

[plugins]
gamegui="res://addons/gamegui/plugin.cfg"
```

## 5. Implementation Workflow (For Grok/Cursor Prompts)
- Start prompts with: `[GENESIS MYTHOS GUI SPEC v2 – GAMEGUI MIGRATION]`.
- For new menus: Specify scene path (e.g., res://scenes/character_creation/CharacterCreator.tscn), node tree, and script attachments.
- Modifications: Audit before/after for compliance (e.g., replace hard-codes with constants).
- Testing: Use run_project to verify no clipping on resize.
- All UI scripts must follow core project rules: exact header block, typed GDScript, one class per file, docstrings on public functions.

## 6. Migration Plan (Phased & Safe)
1. **Phase 0: Setup**
   - Install/enable GameGUI (verify res://addons/gamegui/ exists and plugin is enabled).
   - Create `UIConstants.gd` at `res://scripts/ui/UIConstants.gd` with canonical table.
   - Update project.godot with display settings from Section 4.
   - Commit: "feat/genesis: Add GameGUI addon, UIConstants.gd, and update project settings"

2. **Phase 1: Quick Wins (Low Risk)**
   - Refactor MainMenu.tscn: Replace VBox/HBox with GGVBox/GGHBox, use GGLabel.
   - Replace hard-coded button sizes with UIConstants.
   - Test responsiveness.

3. **Phase 2: World Generation Menus**
   - Update WorldBuilderUI.tscn/.gd at res://ui/world_builder/ (highest magic number count).
   - Migrate splits/previews to GameGUI nodes.
   - Make preview viewports dynamic via GameGUI sizing.

4. **Phase 3: Character Creation (Future)**
   - Build new using GameGUI from start (HSplit: options left, 3D preview right).

5. **Phase 4: Global Polish**
   - Progress dialogs: Use GGComponent-derived nodes for content-based sizing.
   - Debug overlay: GameGUI positioning with safe margins.
   - Audit: No remaining hard-codes.

**Rule:** Migrate one scene at a time. Use `run_project` after each to verify no clipping/FPS drop.

## 7. UI Change Checklist (Mandatory for All UI Work)
- [ ] GameGUI enabled & nodes used where scaling needed
- [ ] No hard-coded pixels (>10 not in UIConstants)
- [ ] Theme applied
- [ ] Tested: 1080p, 4K, ultrawide, window resize
- [ ] Size flags / GameGUI modes explicit
- [ ] Keyboard/controller focus logical

**THIS GUI SPECIFICATION IS FINALIZED AS OF 2025-12-16 AND SHOULD BE INTEGRATED INTO PROJECT-RULES.MD.**
