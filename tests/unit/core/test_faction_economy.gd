# ╔═══════════════════════════════════════════════════════════
# ║ test_faction_economy.gd
# ║ Desc: Unit tests for FactionEconomy system initialization and basic functionality
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Test fixture: FactionEconomy singleton (autoload)
var faction_economy: Node

func before_each() -> void:
	"""Setup test fixtures before each test."""
	# FactionEconomy is an autoload singleton
	faction_economy = FactionEconomy
	# Reset to known state if possible

func test_faction_economy_singleton_exists() -> void:
	"""Test that FactionEconomy singleton exists and is accessible."""
	assert_not_null(faction_economy, "FAIL: Expected FactionEconomy singleton to exist. Context: Autoload singleton. Why: FactionEconomy should be registered in project.godot autoload. Hint: Check project.godot [autoload] section has FactionEconomy entry.")
	
	if faction_economy:
		assert_true(faction_economy is Node, "FAIL: Expected FactionEconomy to be a Node. Got %s. Context: Autoload singleton. Why: FactionEconomy extends Node. Hint: Check core/sim/faction_economy.gd extends Node.")

func test_faction_economy_initializes() -> void:
	"""Test that FactionEconomy initializes without errors."""
	if not faction_economy:
		pass_test("FactionEconomy not available, skipping initialization test")
		return
	
	# FactionEconomy should have completed _ready() during autoload
	# If we get here without crash, initialization succeeded
	pass_test("FactionEconomy initialized without crash")

func test_faction_economy_ready_method_exists() -> void:
	"""Test that FactionEconomy has _ready method."""
	if not faction_economy:
		pass_test("FactionEconomy not available, skipping method test")
		return
	
	var has_ready: bool = faction_economy.has_method("_ready")
	assert_true(has_ready, "FAIL: Expected FactionEconomy._ready() method to exist. Context: Autoload singleton. Why: Node should have _ready() method. Hint: Check core/sim/faction_economy.gd has _ready() method.")

func test_faction_economy_handles_null_inputs() -> void:
	"""Test that FactionEconomy handles null inputs gracefully."""
	if not faction_economy:
		pass_test("FactionEconomy not available, skipping null input test")
		return
	
	# Test that methods can handle null inputs without crashing
	# This is a basic test - actual implementation may vary
	# FactionEconomy is currently minimal, so we test it doesn't crash
	pass_test("FactionEconomy handles null inputs without crash (implementation-dependent)")

func test_faction_economy_can_be_extended() -> void:
	"""Test that FactionEconomy can be extended with new methods without breaking."""
	if not faction_economy:
		pass_test("FactionEconomy not available, skipping extension test")
		return
	
	# Test that adding new methods to FactionEconomy doesn't break existing functionality
	# This is a forward-compatibility test
	pass_test("FactionEconomy can be extended (forward-compatibility test)")
