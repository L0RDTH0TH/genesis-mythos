# ╔═══════════════════════════════════════════════════════════
# ║ GenerateButtonTestRunner.gd
# ║ Desc: Test runner specifically for Generate Map button test
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

func before_all() -> void:
	"""Setup before all tests."""
	print("=" * 80)
	print("RUNNING GENERATE MAP BUTTON TEST")
	print("=" * 80)

func test_generate_map_button_full_lifecycle() -> void:
	"""Run the Generate Map button full lifecycle test."""
	# Import the test class
	var test_file = load("res://tests/integration/test_world_builder_ui_full_interactions.gd")
	
	# Create instance and run the specific test
	var test_instance = test_file.new()
	test_instance.before_each()
	
	# Run the generate button test
	test_instance.test_step_1_generate_button_full_lifecycle()
	
	test_instance.after_each()
	
	pass_test("Generate Map button test completed")

