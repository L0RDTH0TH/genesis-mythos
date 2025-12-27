# ╔═══════════════════════════════════════════════════════════
# ║ diagnostic_scene_tree_analyzer.gd
# ║ Desc: Diagnostic tool to analyze scene tree structure
# ║ Author: Diagnostic Script
# ╚═══════════════════════════════════════════════════════════

extends Node

## Analyze a scene tree node and collect statistics
static func analyze_node(node: Node, depth: int = 0, stats: Dictionary = {}) -> Dictionary:
	"""Recursively analyze node tree and collect statistics."""
	if stats.is_empty():
		stats = {
			"total_nodes": 0,
			"control_nodes": 0,
			"max_depth": 0,
			"nodes_with_scripts": 0,
			"script_paths": [],
			"node_counts_by_type": {},
			"deepest_path": "",
			"deepest_depth": 0
		}
	
	stats.total_nodes += 1
	
	# Track node type
	var node_type: String = node.get_class()
	if not stats.node_counts_by_type.has(node_type):
		stats.node_counts_by_type[node_type] = 0
	stats.node_counts_by_type[node_type] += 1
	
	# Track Control nodes specifically
	if node is Control:
		stats.control_nodes += 1
	
	# Track scripts
	if node.get_script():
		stats.nodes_with_scripts += 1
		var script_path: String = node.get_script().resource_path
		if script_path != "":
			stats.script_paths.append({
				"path": node.get_path(),
				"script": script_path
			})
	
	# Track depth
	if depth > stats.max_depth:
		stats.max_depth = depth
		stats.deepest_path = str(node.get_path())
		stats.deepest_depth = depth
	
	# Recursively analyze children
	for child in node.get_children():
		analyze_node(child, depth + 1, stats)
	
	return stats


static func print_analysis(node: Node) -> void:
	"""Analyze and print scene tree statistics."""
	var stats: Dictionary = analyze_node(node)
	
	print("\n=== SCENE TREE ANALYSIS ===")
	print("Total Nodes: %d" % stats.total_nodes)
	print("Control Nodes: %d" % stats.control_nodes)
	print("Max Nesting Depth: %d" % stats.max_depth)
	print("Nodes with Scripts: %d" % stats.nodes_with_scripts)
	print("\nDeepest Path: %s (depth: %d)" % [stats.deepest_path, stats.deepest_depth])
	
	print("\nNode Counts by Type:")
	var sorted_types = stats.node_counts_by_type.keys()
	sorted_types.sort()
	for node_type in sorted_types:
		var count: int = stats.node_counts_by_type[node_type]
		print("  %s: %d" % [node_type, count])
	
	if stats.script_paths.size() > 0:
		print("\nScripts Attached:")
		for script_info in stats.script_paths:
			print("  %s -> %s" % [script_info.path, script_info.script])
	
	print("\n=== END ANALYSIS ===\n")
	
	# Flag potential issues
	var warnings: Array[String] = []
	if stats.total_nodes > 50:
		warnings.append("High node count (%d > 50)" % stats.total_nodes)
	if stats.max_depth > 10:
		warnings.append("Deep nesting (depth %d > 10)" % stats.max_depth)
	if stats.control_nodes > 30:
		warnings.append("Many Control nodes (%d > 30)" % stats.control_nodes)
	
	if warnings.size() > 0:
		print("⚠️  WARNINGS:")
		for warning in warnings:
			print("  - %s" % warning)
