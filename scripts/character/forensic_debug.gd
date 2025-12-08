# ╔══════════════════════════════════════════════════════════════════════════════
# ║ forensic_debug.gd
# ║ Desc: Complete forensic debug for invisible columns issue
# ║ Author: Debug Session
# ╚══════════════════════════════════════════════════════════════════════════════

func forensic_debug_race_grid() -> void:
	print("\n" + "="*80)
	print("FORENSIC DEBUG - RACE GRID COLUMNS VISIBILITY")
	print("="*80)
	
	var root: Node = get_tree().root
	if not root:
		print("\n[ERROR] No root node found!")
		return
	
	# Find RaceTab in the scene tree
	var race_tab: Node = null
	var current_tab: Node = root.find_child("RaceTab", true, false)
	if current_tab:
		race_tab = current_tab
	else:
		# Try finding through CharacterCreationRoot
		var creation_root: Node = root.find_child("CharacterCreationRoot", true, false)
		if creation_root:
			var tab_container: Node = creation_root.find_child("CurrentTabContainer", true, false)
			if tab_container:
				for child in tab_container.get_children():
					if child.name == "RaceTab":
						race_tab = child
						break
	
	if not race_tab:
		print("\n[ERROR] RaceTab not found in scene tree!")
		print("\nSearching entire tree...")
		_print_scene_tree(root, 0)
		return
	
	print("\n[SUCCESS] Found RaceTab node")
	
	# Get RaceGrid
	var race_grid: GridContainer = race_tab.get_node_or_null("MainPanel/UnifiedScroll/RaceGrid")
	if not race_grid:
		print("\n[ERROR] RaceGrid node not found at expected path!")
		print("RaceTab children:")
		_print_node_children(race_tab, 0)
		return
	
	print("\n" + "="*80)
	print("QUESTION 1: EXACT NODE THAT SHOULD DISPLAY RACE COLUMNS")
	print("="*80)
	print("Full node path: RaceTab/MainPanel/UnifiedScroll/RaceGrid")
	print("Exact node type: %s" % race_grid.get_class())
	print("Name in scene tree: %s" % race_grid.name)
	
	print("\n" + "="*80)
	print("QUESTION 2: RUNTIME GEOMETRY")
	print("="*80)
	print("global_position: %s" % race_grid.global_position)
	print("position: %s" % race_grid.position)
	print("size: %s" % race_grid.size)
	print("rect_min_size (custom_minimum_size): %s" % race_grid.custom_minimum_size)
	if race_grid.size == Vector2(0, 0) or race_grid.size.x < 4 or race_grid.size.y < 4:
		print("[WARNING] Size is zero or ridiculously small!")
	
	print("\n" + "="*80)
	print("QUESTION 3: PARENT CHAIN GEOMETRY")
	print("="*80)
	var parent: Node = race_grid.get_parent()
	var level: int = 1
	while parent:
		if parent is Control:
			var ctrl: Control = parent as Control
			print("Level %d - %s (%s): size = %s" % [level, parent.name, parent.get_class(), ctrl.size])
			if ctrl.size == Vector2(0, 0) or (ctrl.size.x < 4 and ctrl.size.y < 4):
				print("  [WARNING] Parent has zero or tiny size!")
		parent = parent.get_parent()
		level += 1
		if level > 20:  # Safety break
			break
	
	print("\n" + "="*80)
	print("QUESTION 4: LAYOUT & SIZING FLAGS (LIVE VALUES)")
	print("="*80)
	print("RaceGrid:")
	print("  size_flags_horizontal: %d" % race_grid.size_flags_horizontal)
	print("  size_flags_vertical: %d" % race_grid.size_flags_vertical)
	print("  anchors_preset: %d" % race_grid.anchors_preset)
	print("  layout_mode: %d" % race_grid.layout_mode)
	
	var parent_ctrl: Control = race_grid.get_parent()
	if parent_ctrl is Control:
		print("\nDirect Parent (%s):" % parent_ctrl.name)
		print("  size_flags_horizontal: %d" % parent_ctrl.size_flags_horizontal)
		print("  size_flags_vertical: %d" % parent_ctrl.size_flags_vertical)
		print("  anchors_preset: %d" % parent_ctrl.anchors_preset)
		
		var grandparent: Control = parent_ctrl.get_parent()
		if grandparent is Control:
			print("\nGrand-parent (%s):" % grandparent.name)
			print("  size_flags_horizontal: %d" % grandparent.size_flags_horizontal)
			print("  size_flags_vertical: %d" % grandparent.size_flags_vertical)
			print("  anchors_preset: %d" % grandparent.anchors_preset)
	
	print("\n" + "="*80)
	print("QUESTION 5: GRIDCONTAINER-SPECIFIC LIVE VALUES")
	print("="*80)
	print("columns property: %d" % race_grid.columns)
	print("separation_horizontal: %d" % race_grid.get_theme_constant("h_separation", 0))
	print("separation_vertical: %d" % race_grid.get_theme_constant("v_separation", 0))
	print("custom_minimum_size (live): %s" % race_grid.custom_minimum_size)
	var child_count: int = race_grid.get_child_count()
	print("Number of child nodes: %d" % child_count)
	
	print("\n" + "="*80)
	print("QUESTION 6: CHILD NODES INSIDE COLUMN CONTAINER")
	print("="*80)
	var children: Array = race_grid.get_children()
	print("Number of direct children: %d" % children.size())
	
	if children.size() > 0:
		var first_child: Node = children[0]
		if first_child is Control:
			var ctrl: Control = first_child as Control
			print("\nFirst child (%s):" % first_child.name)
			print("  size: %s" % ctrl.size)
			print("  visible: %s" % ctrl.visible)
			print("  modulate: %s" % ctrl.modulate)
			print("  self_modulate: %s" % ctrl.self_modulate)
			print("  type: %s" % first_child.get_class())
			
			# Check for StyleBox transparency
			if first_child is PanelContainer:
				var pc: PanelContainer = first_child as PanelContainer
				var style: StyleBox = pc.get_theme_stylebox("panel", "PanelContainer")
				if style:
					if style is StyleBoxFlat:
						var sb: StyleBoxFlat = style as StyleBoxFlat
						print("  StyleBox bg_color: %s (alpha: %f)" % [sb.bg_color, sb.bg_color.a])
	
	print("\n" + "="*80)
	print("QUESTION 7: VISIBILITY CHAIN")
	print("="*80)
	var node: Node = race_grid
	var vis_level: int = 0
	while node:
		if node is CanvasItem:
			var ci: CanvasItem = node as CanvasItem
			var vis_str: String = "true" if ci.visible else "false"
			print("Level %d - %s: visible = %s" % [vis_level, node.name, vis_str])
			if not ci.visible:
				print("  [WARNING] Node is invisible!")
		node = node.get_parent()
		vis_level += 1
		if vis_level > 20:
			break
	
	print("\n" + "="*80)
	print("QUESTION 8: THEME OVERRIDES AT RUNTIME")
	print("="*80)
	print("RaceGrid theme overrides:")
	_print_theme_overrides(race_grid)
	
	if children.size() > 0 and children[0] is Control:
		print("\nFirst child theme overrides:")
		_print_theme_overrides(children[0] as Control)
	
	print("\n" + "="*80)
	print("QUESTION 9: CLIPPING & MASKING")
	print("="*80)
	var check_node: Control = race_grid
	var clip_level: int = 0
	while check_node:
		if check_node is Control:
			print("Level %d - %s:" % [clip_level, check_node.name])
			print("  clip_contents: %s" % check_node.clip_contents)
		check_node = check_node.get_parent() as Control
		clip_level += 1
		if clip_level > 10:
			break
	
	print("\n" + "="*80)
	print("QUESTION 10: QUICK TEST - MANUAL SIZE SET")
	print("="*80)
	var original_size: Vector2 = race_grid.size
	print("Original size: %s" % original_size)
	race_grid.size = Vector2(800, 600)
	print("Set size to: Vector2(800, 600)")
	print("After setting, actual size: %s" % race_grid.size)
	await get_tree().process_frame
	await get_tree().process_frame
	print("After 2 frames, size: %s" % race_grid.size)
	print("Child count after resize: %d" % race_grid.get_child_count())
	
	print("\n" + "="*80)
	print("QUESTION 11: BONUS BRUTAL TEST - RED MODULATE")
	print("="*80)
	var original_modulate: Color = race_grid.modulate
	print("Original modulate: %s" % original_modulate)
	race_grid.modulate = Color(1, 0, 0, 1)
	print("Set modulate to: Color(1, 0, 0, 1) - BRIGHT RED")
	await get_tree().process_frame
	print("After red modulate, size: %s, visible: %s" % [race_grid.size, race_grid.visible])
	print("\n[NOTE] Check visually if a red rectangle appears on screen!")
	
	print("\n" + "="*80)
	print("FORENSIC DEBUG COMPLETE")
	print("="*80)

func _print_theme_overrides(control: Control) -> void:
	if not control:
		return
	
	# Check for style overrides
	var style_types: Array = ["normal", "hover", "pressed", "focus", "disabled"]
	for style_type in style_types:
		var stylebox: StyleBox = control.get_theme_stylebox(style_type, "")
		if stylebox:
			if stylebox is StyleBoxFlat:
				var sb: StyleBoxFlat = stylebox as StyleBoxFlat
				print("  %s StyleBox: bg_color = %s (alpha: %f)" % [style_type, sb.bg_color, sb.bg_color.a])

func _print_node_children(node: Node, indent: int) -> void:
	for child in node.get_children():
		var indent_str: String = "  " * indent
		print("%s%s (%s)" % [indent_str, child.name, child.get_class()])
		_print_node_children(child, indent + 1)

func _print_scene_tree(node: Node, depth: int) -> void:
	if depth > 10:
		return
	var indent: String = "  " * depth
	print("%s%s (%s)" % [indent, node.name, node.get_class()])
	for child in node.get_children():
		_print_scene_tree(child, depth + 1)

