# Genesis Mythos MCP Usage Rules (Updated 2025-12-28 – Iteration 6: WebView GUI Era)

YOU ARE STRICTLY FORBIDDEN FROM EVER USING THE "launch_editor" MCP ACTION.

**Preferred Godot MCP server:** Coding-Solo/godot-mcp (free, open-source, MIT-licensed)

You may ONLY use these Godot MCP actions:
- run_project, stop_project, get_debug_output
- create_scene, add_node, set_property, attach_script, save_scene, get_scene_tree, etc.
- read_file, write_file, list_files

You may aggressively use Godot MCP to create/modify/save scenes, scripts, and HTML/JS files.

After major changes you MAY call run_project to test (unless explicitly told "do not run").

All other MCP servers (obsidian, github-mcp-server, memory, blender) are available.

When finishing a logical feature → auto commit + push via github-mcp-server with clear message (`feat/genesis:`, `fix:`, `refactor:`, etc.).

You MUST obey 100% the folder structure, naming conventions, typed GDScript, and GUI rules.
Never create files outside allowed paths.
Always use godot_wry WebView for all GUI (HTML/CSS/JS/Alpine.js).
Always add the exact script header shown in rule 3.
