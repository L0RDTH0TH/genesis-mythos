# GUI Performance Rules – Genesis Mythos

**Document:** `docs/gui/gui_performance_rules.md`  
**Date:** 2025-12-26  
**Status:** ACTIVE – Mandatory for all UI development and refactors  

**Goal:** Ensure all UI scenes maintain 60+ FPS on mid-range hardware, even with full world and complex menus active. Total CanvasItem count must stay < 600 in worst-case scenes (e.g., WorldBuilderUI fully open).

These rules are **mandatory**. Violations in new code or refactors require justification and explicit approval.

## Lessons from December 2025 Audit

The WorldBuilderUI scene dropped to ~5-7 FPS due to:
- Runtime creation/destruction of 18–30 Control nodes every step switch
- ~1900 total objects / ~1514 CanvasItem primitives drawn
- Deep nesting (up to 9 levels)
- Per-node theme overrides breaking batching
- Hard-coded sizes (magic numbers)

These rules directly prevent recurrence.

## Hard Rules (MUST NOT – No Exceptions Without Approval)

1. **No frequent runtime creation/destruction of Control nodes**  
   Forbidden: Clearing and recreating rows, labels, or controls on every update/step change (e.g., like old `_populate_params()`).  
   Required: Use object pooling, visibility toggling (`visible = false`), or data-driven single-node updates (RichTextLabel, ItemList, Tree).

2. **Maximum 600 CanvasItem nodes in any active UI scene**  
   Measure via Debugger → Monitors → Objects Drawn + Primitives Drawn.  
   Worst-case scene (WorldBuilderUI, CharacterCreation, etc.) must stay under 600.

3. **Maximum nesting depth: 6 levels**  
   Count from root Control/CanvasLayer to deepest leaf Control node.  
   Deeper nesting requires approval and justification.

4. **No per-node theme overrides in .tscn files or via `add_theme_*_override()`**  
   Use theme variants (`theme_type_variation`), style classes in `bg3_theme.tres`, or `modulate`.  
   Exception: Rare dynamic cases (e.g., progress bars) – document heavily.

5. **No hard-coded sizes or positions (magic numbers)**  
   All sizing/positioning must use:
   - `UIConstants.gd` values
   - Theme constants
   - Anchors + size flags
   - Runtime calculations based on viewport size

## Soft Rules (Strongly Recommended)

1. Pre-create all labels, controls, and rows in .tscn files when possible (avoid `Node.new()` in `_ready()` or updates).
2. Use `ItemList`, `Tree`, or `RichTextLabel` for dynamic lists instead of individual Control rows.
3. Implement object pooling for any repeating UI elements (parameter rows, inventory slots, metric lists).
4. Profile every major UI change using Remote Debugger (check FPS, CanvasItem count).

## Enforcement & Review

- **PR/Checklist Requirement:** Every UI-related PR must include:
  - Before/after CanvasItem count and FPS for affected scenes
  - Confirmation no forbidden patterns introduced
- **Future Automation (Planned):**
  - CI linting for theme_override_* in .tscn files
  - Scene node count checks
  - Nesting depth analysis

## Reference Metrics (Post-Fix Baseline – To Maintain)

- WorldBuilderUI (fully active): ~420 CanvasItems, 60+ FPS
- PerformanceMonitor overlay: < 50 additional nodes

**All UI work must preserve or improve these baselines.**
