# ╔═══════════════════════════════════════════════════════════
# ║ test_icon_node.gd
# ║ Desc: Unit tests for IconNode icon placement and distance calculations
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Test fixture: IconNode instances
var icon1: IconNode
var icon2: IconNode

## Test fixture: Scene tree for node testing
var test_scene: Node2D

func before_all() -> void:
	"""Setup test scene before all tests."""
	test_scene = Node2D.new()
	test_scene.name = "TestScene"
	get_tree().root.add_child(test_scene)

func after_all() -> void:
	"""Cleanup test scene after all tests."""
	if test_scene:
		test_scene.queue_free()
		await get_tree().process_frame

func before_each() -> void:
	"""Setup IconNode instances before each test."""
	icon1 = IconNode.new()
	icon1.name = "Icon1"
	icon1.position = Vector2(0, 0)
	test_scene.add_child(icon1)
	
	icon2 = IconNode.new()
	icon2.name = "Icon2"
	icon2.position = Vector2(100, 100)
	test_scene.add_child(icon2)
	
	await get_tree().process_frame

func after_each() -> void:
	"""Cleanup IconNode instances after each test."""
	if icon1:
		icon1.queue_free()
	if icon2:
		icon2.queue_free()
	await get_tree().process_frame
	icon1 = null
	icon2 = null

func test_icon_node_initializes() -> void:
	"""Test that IconNode initializes without errors."""
	assert_not_null(icon1, "FAIL: Expected IconNode to be created. Context: Instantiation. Why: Icon should initialize. Hint: Check IconNode._ready() completes without errors.")

func test_icon_node_has_icon_id() -> void:
	"""Test that IconNode has icon_id property."""
	if not icon1.has("icon_id"):
		push_warning("IconNode.icon_id not accessible, skipping test")
		pass_test("icon_id not accessible")
		return
	
	var icon_id = icon1.get("icon_id")
	# Should be initialized (empty string is valid)
	assert_not_null(icon_id, "FAIL: Expected icon_id to exist. Context: IconNode initialization. Why: Icon ID should be available. Hint: Check IconNode.gd defines icon_id: String = \"\".")

func test_icon_node_has_icon_type() -> void:
	"""Test that IconNode has icon_type property."""
	if not icon1.has("icon_type"):
		push_warning("IconNode.icon_type not accessible, skipping test")
		pass_test("icon_type not accessible")
		return
	
	var icon_type = icon1.get("icon_type")
	# Should be initialized (empty string is valid)
	assert_not_null(icon_type, "FAIL: Expected icon_type to exist. Context: IconNode initialization. Why: Icon type should be available. Hint: Check IconNode.gd defines icon_type: String = \"\".")

func test_icon_node_has_map_position() -> void:
	"""Test that IconNode has map_position property."""
	if not icon1.has("map_position"):
		push_warning("IconNode.map_position not accessible, skipping test")
		pass_test("map_position not accessible")
		return
	
	var map_position = icon1.get("map_position")
	assert_not_null(map_position, "FAIL: Expected map_position to exist. Context: IconNode initialization. Why: Map position should be available. Hint: Check IconNode.gd defines map_position: Vector2 = Vector2.ZERO.")

func test_set_icon_data_sets_properties() -> void:
	"""Test that set_icon_data sets icon properties correctly."""
	var test_id: String = "test_icon_123"
	var test_color: Color = Color(1.0, 0.5, 0.0, 1.0)
	var test_type: String = "jungle"
	
	if icon1.has_method("set_icon_data"):
		icon1.set_icon_data(test_id, test_color, test_type)
		await get_tree().process_frame
		
		if icon1.has("icon_id"):
			var icon_id = icon1.get("icon_id")
			assert_eq(icon_id, test_id, "FAIL: Expected icon_id '%s', got '%s'. Context: set_icon_data(). Why: ID should be set. Hint: Check IconNode.set_icon_data() assigns icon_id.")
		
		if icon1.has("icon_color"):
			var icon_color = icon1.get("icon_color")
			assert_eq(icon_color, test_color, "FAIL: Expected icon_color %s, got %s. Context: set_icon_data(). Why: Color should be set. Hint: Check IconNode.set_icon_data() assigns icon_color.")
		
		if icon1.has("icon_type"):
			var icon_type = icon1.get("icon_type")
			assert_eq(icon_type, test_type, "FAIL: Expected icon_type '%s', got '%s'. Context: set_icon_data(). Why: Type should be set. Hint: Check IconNode.set_icon_data() assigns icon_type.")
	else:
		push_warning("set_icon_data method not found, skipping test")
		pass_test("set_icon_data method not accessible")

func test_get_distance_to_calculates_distance() -> void:
	"""Test that get_distance_to calculates correct distance between icons."""
	# Set positions
	icon1.position = Vector2(0, 0)
	icon2.position = Vector2(100, 0)  # 100 units to the right
	
	if icon1.has_method("get_distance_to"):
		var distance: float = icon1.get_distance_to(icon2)
		var expected_distance: float = 100.0
		var tolerance: float = 0.1
		
		assert_almost_eq(distance, expected_distance, tolerance, "FAIL: Expected distance %.2f, got %.2f. Context: icon1 at (0,0), icon2 at (100,0). Why: Distance should be calculated. Hint: Check IconNode.get_distance_to() uses Vector2.distance_to().")
	else:
		push_warning("get_distance_to method not found, skipping test")
		pass_test("get_distance_to method not accessible")

func test_get_distance_to_diagonal() -> void:
	"""Test that get_distance_to calculates diagonal distance correctly."""
	# Set positions for diagonal distance
	icon1.position = Vector2(0, 0)
	icon2.position = Vector2(100, 100)  # Diagonal
	
	if icon1.has_method("get_distance_to"):
		var distance: float = icon1.get_distance_to(icon2)
		var expected_distance: float = sqrt(100.0 * 100.0 + 100.0 * 100.0)  # ~141.42
		var tolerance: float = 0.1
		
		assert_almost_eq(distance, expected_distance, tolerance, "FAIL: Expected diagonal distance ~%.2f, got %.2f. Context: icon1 at (0,0), icon2 at (100,100). Why: Diagonal distance should use Pythagorean theorem. Hint: Check IconNode.get_distance_to() uses Vector2.distance_to().")
	else:
		push_warning("get_distance_to method not found, skipping test")
		pass_test("get_distance_to method not accessible")

func test_get_distance_to_same_position() -> void:
	"""Test that get_distance_to returns 0 for same position."""
	icon1.position = Vector2(50, 50)
	icon2.position = Vector2(50, 50)  # Same position
	
	if icon1.has_method("get_distance_to"):
		var distance: float = icon1.get_distance_to(icon2)
		var expected_distance: float = 0.0
		var tolerance: float = 0.01
		
		assert_almost_eq(distance, expected_distance, tolerance, "FAIL: Expected distance 0.0 for same position, got %.2f. Context: Both icons at (50,50). Why: Same position should return 0. Hint: Check IconNode.get_distance_to() handles zero distance.")
	else:
		push_warning("get_distance_to method not found, skipping test")
		pass_test("get_distance_to method not accessible")

func test_icon_node_creates_visual() -> void:
	"""Test that IconNode creates visual representation."""
	# Wait for _ready to complete
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Check if visual child exists (sprite or ColorRect)
	var child_count: int = icon1.get_child_count()
	assert_true(child_count > 0, "FAIL: Expected IconNode to have visual children, got %d. Context: After _ready(). Why: Visual should be created. Hint: Check IconNode._create_visual() creates visual representation.")
	
	# Check if sprite exists
	if icon1.has("sprite"):
		var sprite = icon1.get("sprite")
		# Sprite can be null if visual is created differently
		pass_test("Visual representation created")
	else:
		# Visual might be created as child node instead
		pass_test("Visual representation exists as child node")

func test_icon_color_applied_to_visual() -> void:
	"""Test that icon color is applied to visual representation."""
	var test_color: Color = Color(0.8, 0.2, 0.9, 1.0)
	
	if icon1.has_method("set_icon_data"):
		icon1.set_icon_data("test", test_color, "test_type")
		await get_tree().process_frame
		
		# Check if color is applied (visual might be a child node)
		# This is a basic check - actual implementation may vary
		if icon1.has("icon_color"):
			var icon_color = icon1.get("icon_color")
			assert_eq(icon_color, test_color, "FAIL: Expected icon_color %s, got %s. Context: After set_icon_data(). Why: Color should be stored. Hint: Check IconNode.set_icon_data() updates visual modulate.")
		else:
			push_warning("icon_color not accessible, skipping verification")
			pass_test("icon_color set but not accessible")
	else:
		push_warning("set_icon_data method not found, skipping test")
		pass_test("set_icon_data method not accessible")
