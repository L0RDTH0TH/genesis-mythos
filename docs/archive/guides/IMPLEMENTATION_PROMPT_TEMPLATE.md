# Implementation Prompt Template for Race→Class Transition Cleanup

Use this template to generate Cursor prompts for implementing the cleanup. Replace `[FEATURE]` with specific feature from analysis document.

---

```
[BG3 CHARACTER CREATION CLONE – GODOT 4.3]

YOU ARE STRICTLY FORBIDDEN FROM EVER USING THE "launch_editor" MCP ACTION.

You may ONLY use these Godot MCP actions:
- run_project, stop_project, get_debug_output
- create_scene, add_node, set_property, attach_script, save_scene, etc.
- get_scene_tree, read_file, write_file

You may aggressively use the Godot MCP to create/modify/save scenes and scripts instead of only outputting raw text.

After major changes you MAY call run_project immediately to test (unless I explicitly say "do not run").

All other MCP servers (obsidian, github-mcp-server, memory, blender) are fully available.

When you finish a logical feature → auto commit + push via github-mcp-server with a clear message.

You MUST obey 100% the folder structure, naming conventions, typed GDScript, and theme rules above.
Never create files outside the allowed paths.
Never use camelCase or different styling.
Always add the exact script header shown in rule 3.

---

TASK: [FEATURE]

Current state: [DESCRIPTION]

Goal: [DESCRIPTION]

Files to modify:
- scripts/character_creation/tabs/RaceTab.gd
- scripts/character_creation/tabs/ClassTab.gd
- scripts/character_creation/CharacterCreationRoot.gd
- scripts/character_creation/tabs/TabNavigation.gd
- themes/bg3_theme.tres (if needed)

Requirements:
1. [REQUIREMENT 1]
2. [REQUIREMENT 2]
3. [REQUIREMENT 3]

Reference: See RACE_TO_CLASS_TRANSITION_ANALYSIS.md for full context.

After implementation, test the flow and commit with message: "feat/char-creation: [FEATURE DESCRIPTION]"
```

---

## Example Prompts

### Example 1: Add Transition Animation

```
[BG3 CHARACTER CREATION CLONE – GODOT 4.3]

[... standard rules header ...]

---

TASK: Add smooth fade transition animation between RaceTab and ClassTab

Current state: Tab switching is instant via remove_child/add_child, no visual feedback.

Goal: Implement 0.2-0.3 second fade-out/fade-in animation using Tween in CharacterCreationRoot._load_tab().

Files to modify:
- scripts/character_creation/CharacterCreationRoot.gd

Requirements:
1. Fade out current tab (alpha 1.0 → 0.0) over 0.15 seconds
2. Remove old tab after fade completes
3. Add new tab with alpha 0.0, fade in to 1.0 over 0.15 seconds
4. Use create_tween() and await for proper sequencing
5. Handle edge case where current_tab_instance is null (first tab load)

Reference: See RACE_TO_CLASS_TRANSITION_ANALYSIS.md section "Phase 1: Fix Immediate Issues" for details.

After implementation, test the flow and commit with message: "feat/char-creation: add smooth tab transition animation"
```

### Example 2: Fix Back Navigation State

```
[BG3 CHARACTER CREATION CLONE – GODOT 4.3]

[... standard rules header ...]

---

TASK: Restore race/subrace selection state when navigating back from ClassTab

Current state: RaceTab reinitializes with empty selection when returning from ClassTab, user's previous choice not highlighted.

Goal: In RaceTab._ready(), check PlayerData.race_id and restore selection state (current_mode, selected_race, selected_subrace, visual highlighting).

Files to modify:
- scripts/character_creation/tabs/RaceTab.gd

Requirements:
1. Check if PlayerData.race_id is not empty at start of _ready()
2. If exists, restore selected_race and selected_subrace
3. If subrace exists, set current_mode to MODE_SUBRACE and set pending_race
4. After _populate_list(), call _restore_visual_selection() to highlight entry
5. Create helper function _restore_visual_selection() that finds entry by race_id/subrace_id and calls set_selected(true)

Reference: See RACE_TO_CLASS_TRANSITION_ANALYSIS.md section "4.1 Identified Edge Cases" item B.

After implementation, test back navigation and commit with message: "feat/char-creation: restore race selection state on back navigation"
```

### Example 3: Add Class Compatibility Filtering

```
[BG3 CHARACTER CREATION CLONE – GODOT 4.3]

[... standard rules header ...]

---

TASK: Implement flexible class filtering based on race compatibility

Current state: All classes shown to all races. No compatibility checking.

Goal: Add data-driven filtering in ClassTab._populate_list() that checks optional race_restrictions/race_forbidden fields in classes.json. Gracefully handles missing fields (shows all classes if no restrictions).

Files to modify:
- scripts/character_creation/tabs/ClassTab.gd

Requirements:
1. Before creating class entry, check if cls.has("race_restrictions")
2. If restrictions exist, verify PlayerData.race_id is in allowed list, skip if not
3. Check if cls.has("race_forbidden"), skip if PlayerData.race_id in forbidden list
4. Handle missing PlayerData.race_id gracefully (show all classes with warning log)
5. Add debug logging for filtered classes (e.g., "ClassTab: Filtered out barbarian (race restriction)")

Reference: See RACE_TO_CLASS_TRANSITION_ANALYSIS.md section "2.3 Class Compatibility Handling" for JSON structure examples.

After implementation, test with classes.json (currently no restrictions - all classes should show). Commit with message: "feat/char-creation: add race-class compatibility filtering"
```

---

## Quick Reference Checklist

Before submitting prompt:
- [ ] Included full rules header (MCP restrictions, folder structure, naming conventions)
- [ ] Specified exact files to modify
- [ ] Listed clear requirements (numbered)
- [ ] Referenced analysis document section
- [ ] Specified commit message format
- [ ] Included edge cases if relevant
- [ ] Tested prompt clarity (can AI understand what to do?)

