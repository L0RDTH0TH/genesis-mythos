# ╔═══════════════════════════════════════════════════════════
# ║ WorldGenTestRunner.gd
# ║ Desc: Focused test runner for world generation tests only
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node2D

var GutRunner = load('res://addons/gut/gui/GutRunner.tscn')
var GutConfig = load('res://addons/gut/gut_config.gd')

var _runner: Node = null
var _config = null

func _ready() -> void:
	"""Setup and run world generation tests automatically."""
	call_deferred('_setup_and_run')

func _setup_and_run() -> void:
	"""Setup config and runner, then run tests."""
	_setup_config()
	_setup_runner()
	call_deferred('_run_tests')

func _setup_config() -> void:
	"""Configure GUT to run all world generation UI component tests."""
	_config = GutConfig.new()
	# Run all world generation UI component tests
	_config.options.tests = [
		'res://tests/unit/core/test_map_generator.gd',
		'res://tests/unit/ui/test_world_builder_ui.gd',
		'res://tests/unit/ui/test_map_maker_module.gd',
		'res://tests/unit/ui/test_icon_node.gd',
		'res://tests/integration/test_world_gen_workflow.gd'
	]
	_config.options.should_exit = true
	_config.options.should_exit_on_success = false
	_config.options.log_level = 1
	_config.options.compact_mode = false

func _setup_runner() -> void:
	"""Create and configure the GUT runner."""
	_runner = GutRunner.instantiate()
	get_tree().root.add_child.call_deferred(_runner)
	_runner.set_gut_config(_config)

func _run_tests() -> void:
	"""Start running the world generation test suite."""
	_runner.run_tests(false)
