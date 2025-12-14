# ╔═══════════════════════════════════════════════════════════
# ║ FullTestRunner.gd
# ║ Desc: Automated test runner for ALL tests (unit + integration)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node2D

var GutRunner = load('res://addons/gut/gui/GutRunner.tscn')
var GutConfig = load('res://addons/gut/gut_config.gd')

var _runner: Node = null
var _config = null

func _ready() -> void:
	"""Setup and run all tests automatically."""
	call_deferred('_setup_and_run')

func _setup_and_run() -> void:
	"""Setup config and runner, then run tests."""
	_setup_config()
	_setup_runner()
	call_deferred('_run_tests')

func _setup_config() -> void:
	"""Configure GUT to run all tests (unit + integration)."""
	_config = GutConfig.new()
	_config.options.dirs = ['res://tests/unit', 'res://tests/integration']
	_config.options.include_subdirs = true
	_config.options.prefix = 'test_'
	_config.options.suffix = '.gd'
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
	"""Start running the test suite."""
	_runner.run_tests(false)
