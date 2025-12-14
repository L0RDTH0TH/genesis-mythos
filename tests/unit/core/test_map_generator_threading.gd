# ╔═══════════════════════════════════════════════════════════
# ║ test_map_generator_threading.gd
# ║ Desc: Unit tests for MapGenerator threading, race conditions, and thread safety
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

## Test fixture: MapGenerator instances
var gen1: MapGenerator
var gen2: MapGenerator

## Test fixture: WorldMapData for testing
var test_data: WorldMapData

func before_each() -> void:
	"""Setup test fixtures before each test."""
	test_data = UnitTestHelpers.create_test_world_map_data(12345, 1024, 1024)  # Large enough to trigger threading
	gen1 = MapGenerator.new()
	gen2 = MapGenerator.new()

func after_each() -> void:
	"""Cleanup after each test."""
	if gen1:
		# Wait for any threads to finish
		if gen1.has("generation_thread") and gen1.generation_thread != null:
			if gen1.generation_thread.is_alive():
				gen1.generation_thread.wait_to_finish()
		gen1 = null
	if gen2:
		if gen2.has("generation_thread") and gen2.generation_thread != null:
			if gen2.generation_thread.is_alive():
				gen2.generation_thread.wait_to_finish()
		gen2 = null
	if test_data:
		test_data = null

func test_threaded_generation_creates_heightmap() -> void:
	"""Test that threaded generation creates heightmap correctly."""
	var data := UnitTestHelpers.create_test_world_map_data(12345, 1024, 1024)
	
	# Use threaded generation (large map triggers threading)
	gen1.generate_map(data, true)
	
	# Wait for thread to complete
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Wait for thread explicitly if accessible
	if gen1.has("generation_thread") and gen1.generation_thread != null:
		if gen1.generation_thread.is_alive():
			gen1.generation_thread.wait_to_finish()
	
	# Wait additional frames for completion
	await get_tree().process_frame
	await get_tree().process_frame
	
	assert_not_null(data.heightmap_image, "FAIL: Expected heightmap_image after threaded generation. Context: seed=12345, size=1024x1024, threaded=true. Why: Threaded generation should create heightmap. Hint: Check MapGenerator._thread_generate() completes and heightmap_image is set.")

func test_concurrent_generation_requests_handled_safely() -> void:
	"""Test that concurrent generation requests are handled safely (no race conditions)."""
	var data1 := UnitTestHelpers.create_test_world_map_data(12345, 1024, 1024)
	var data2 := UnitTestHelpers.create_test_world_map_data(54321, 1024, 1024)
	
	# Start two generations concurrently
	gen1.generate_map(data1, true)
	gen2.generate_map(data2, true)
	
	# Wait for both threads
	await get_tree().process_frame
	await get_tree().process_frame
	
	if gen1.has("generation_thread") and gen1.generation_thread != null:
		if gen1.generation_thread.is_alive():
			gen1.generation_thread.wait_to_finish()
	if gen2.has("generation_thread") and gen2.generation_thread != null:
		if gen2.generation_thread.is_alive():
			gen2.generation_thread.wait_to_finish()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Both should complete without crashing
	assert_not_null(data1.heightmap_image, "FAIL: Expected data1.heightmap_image after concurrent generation. Context: Two generators running simultaneously. Why: Concurrent generation should not interfere. Hint: Check MapGenerator thread isolation.")
	assert_not_null(data2.heightmap_image, "FAIL: Expected data2.heightmap_image after concurrent generation. Context: Two generators running simultaneously. Why: Concurrent generation should not interfere. Hint: Check MapGenerator thread isolation.")

func test_thread_cleanup_on_new_generation() -> void:
	"""Test that starting new generation properly cleans up previous thread."""
	var data1 := UnitTestHelpers.create_test_world_map_data(12345, 1024, 1024)
	var data2 := UnitTestHelpers.create_test_world_map_data(54321, 1024, 1024)
	
	# Start first generation
	gen1.generate_map(data1, true)
	await get_tree().process_frame
	
	# Start second generation before first completes (should wait for first)
	gen1.generate_map(data2, true)
	await get_tree().process_frame
	
	# Wait for thread to complete
	if gen1.has("generation_thread") and gen1.generation_thread != null:
		if gen1.generation_thread.is_alive():
			gen1.generation_thread.wait_to_finish()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Second generation should complete (first may be interrupted or completed)
	# Key: No crash or memory leak
	assert_not_null(data2.heightmap_image, "FAIL: Expected data2.heightmap_image after thread cleanup. Context: New generation started before previous completed. Why: Thread cleanup should prevent race conditions. Hint: Check MapGenerator._generate_in_thread() waits for existing thread via wait_to_finish().")

func test_threaded_generation_determinism() -> void:
	"""Test that threaded generation produces deterministic results (same as sync)."""
	var data_threaded := UnitTestHelpers.create_test_world_map_data(12345, 1024, 1024)
	var data_sync := UnitTestHelpers.create_test_world_map_data(12345, 1024, 1024)
	
	# Generate with threading
	gen1.generate_map(data_threaded, true)
	
	# Wait for thread
	if gen1.has("generation_thread") and gen1.generation_thread != null:
		if gen1.generation_thread.is_alive():
			gen1.generation_thread.wait_to_finish()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Generate synchronously
	gen2.generate_map(data_sync, false)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Results should be identical (determinism)
	assert_not_null(data_threaded.heightmap_image, "FAIL: Expected threaded heightmap to exist. Context: seed=12345, threaded=true. Why: Threaded generation should work. Hint: Check MapGenerator._thread_generate().")
	assert_not_null(data_sync.heightmap_image, "FAIL: Expected sync heightmap to exist. Context: seed=12345, threaded=false. Why: Sync generation should work. Hint: Check MapGenerator._generate_sync().")
	
	# Compare heightmaps (should be identical for same seed)
	var is_identical: bool = UnitTestHelpers.compare_heightmaps(
		data_threaded.heightmap_image,
		data_sync.heightmap_image,
		0.0001,
		"seed=12345, threaded vs sync"
	)
	assert_true(is_identical, "FAIL: Expected identical heightmaps for threaded vs sync generation (determinism). Got different. Context: seed=12345, size=1024x1024. Why: Threading should not affect determinism. Hint: Check RNG seed initialization in MapGenerator._configure_noise() is consistent for threaded path.")

func test_thread_safety_with_null_data() -> void:
	"""Test that threaded generation handles null data gracefully."""
	# Should not crash when null data passed to threaded generation
	gen1.generate_map(null, true)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Wait for thread if it was created
	if gen1.has("generation_thread") and gen1.generation_thread != null:
		if gen1.generation_thread.is_alive():
			gen1.generation_thread.wait_to_finish()
	
	await get_tree().process_frame
	
	# Test passes if no crash
	pass_test("Threaded generation with null data handled without crash")

func test_thread_cleanup_on_generator_destruction() -> void:
	"""Test that threads are properly cleaned up when generator is destroyed."""
	var data := UnitTestHelpers.create_test_world_map_data(12345, 1024, 1024)
	
	# Start generation
	gen1.generate_map(data, true)
	await get_tree().process_frame
	
	# Destroy generator (simulating cleanup)
	# In real scenario, this might happen if scene is unloaded during generation
	if gen1.has("generation_thread") and gen1.generation_thread != null:
		var thread_alive_before: bool = gen1.generation_thread.is_alive()
		
		# Wait for thread to finish or cleanup
		if thread_alive_before:
			gen1.generation_thread.wait_to_finish()
		
		# Cleanup
		gen1.generation_thread = null
	
	gen1 = null
	
	# Test passes if no crash or memory leak
	pass_test("Thread cleanup on generator destruction handled without crash")
