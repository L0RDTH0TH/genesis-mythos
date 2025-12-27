# ╔═══════════════════════════════════════════════════════════
# ║ RunGenerateButtonTest.gd
# ║ Desc: Quick test runner for Generate Map button test
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

func test_generate_map_button() -> void:
	"""Run the Generate Map button test."""
	var test_suite = load("res://tests/integration/test_world_builder_ui_full_interactions.gd")
	var test_instance = test_suite.new()
	
	# Run the specific test
	test_instance.before_each()
	test_instance.test_step_1_generate_button_full_lifecycle()
	test_instance.after_each()
	
	pass_test("Generate Map button test completed")














