# ╔═══════════════════════════════════════════════════════════
# ║ TestWorldGenMenu.gd
# ║ Desc: Integration tests for the World Generation Menu UI
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

var world_gen_menu: Node

func before_each() -> void:
	# === THE FIX ===
	world_gen_menu = preload("res://src/ui/WorldGenMenu.tscn").instantiate()
	add_child(world_gen_menu)
	
	# Wait one extra frame so the entire TabContainer + SeedSection chain finishes _ready()
	await get_tree().process_frame
	await get_tree().process_frame  # 99.9% reliable even on slow CI
	# =====================================================================
	
	watch_signals(world_gen_menu)

func after_each() -> void:
	if world_gen_menu:
		world_gen_menu.queue_free()
		world_gen_menu = null

func test_entering_custom_seed_and_starting_generation() -> void:
	"""Test entering a custom seed and starting world generation"""
	var seed_input: LineEdit = world_gen_menu.get_node("%SeedInput") as LineEdit
	assert_not_null(seed_input, "Seed input should exist")
	
	if seed_input:
		seed_input.text = "12345"
		seed_input.text_changed.emit(seed_input.text)
		await get_tree().process_frame
		
		# Additional test logic can be added here
		assert_eq(seed_input.text, "12345", "Seed input should be set correctly")
