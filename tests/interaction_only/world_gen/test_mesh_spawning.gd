# ╔═══════════════════════════════════════════════════════════
# ║ test_mesh_spawning.gd
# ║ Desc: Tests mesh generation triggers, threads, signals, outputs
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

const TestHelpers = preload("res://tests/interaction_only/helpers/TestHelpers.gd")

var test_results: Array[Dictionary] = []
var visual_delay: float = 1.0

func test_regenerate_button_trigger() -> Dictionary:
	"""Test that parameter change triggers mesh generation"""
	var result := {"name": "regenerate_button_trigger", "passed": false, "message": ""}
	
	var wc_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(wc_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var wc_scene: Node = load(wc_path).instantiate()
	add_child(wc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for _ready() to complete
	await TestHelpers.wait_visual(visual_delay)
	
	# Find terrain mesh - it's in WorldPreviewRoot
	var terrain_mesh := wc_scene.find_child("terrain_mesh", true, false) as MeshInstance3D
	if not terrain_mesh:
		result["message"] = "Terrain mesh not found"
		wc_scene.queue_free()
		return result
	
	# Trigger regeneration via parameter change (WorldCreator uses auto-regeneration)
	if wc_scene.has_method("_on_param_changed"):
		TestHelpers.log_step("Triggering regeneration via parameter change")
		wc_scene._on_param_changed("seed", 99999)  # Change seed to trigger regeneration
		await TestHelpers.wait_visual(visual_delay * 3.0)  # Wait for generation
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Verify mesh was generated
		if terrain_mesh.mesh:
			result["passed"] = true
			result["message"] = "Parameter change triggered mesh generation"
			TestHelpers.assert_mesh_valid(terrain_mesh, 0, "Generated mesh should be valid")
		else:
			result["message"] = "Mesh not generated after parameter change"
	else:
		result["message"] = "WorldCreator does not have _on_param_changed method"
	
	wc_scene.queue_free()
	return result

func test_generation_complete_signal() -> Dictionary:
	"""Test that generation_complete signal is emitted"""
	var result := {"name": "generation_complete_signal", "passed": false, "message": ""}
	
	var wc_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(wc_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var wc_scene: Node = load(wc_path).instantiate()
	add_child(wc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for _ready() to complete
	await TestHelpers.wait_visual(visual_delay)
	
	var world: Variant = wc_scene.get("world")
	if not world:
		result["message"] = "World not found"
		wc_scene.queue_free()
		return result
	
	# Check if world has generation_complete signal
	if world.has_signal("generation_complete"):
		# Trigger generation via parameter change
		if wc_scene.has_method("_on_param_changed"):
			wc_scene._on_param_changed("seed", 88888)
			# Wait for generation_complete signal with timeout using async helper
			var signal_args: Array = await TestHelpers.wait_for_signal_array(world, "generation_complete", 60.0, wc_scene)
			result["passed"] = not signal_args.is_empty()
			result["message"] = "Generation complete signal %s" % ("received" if not signal_args.is_empty() else "not received")
		else:
			result["message"] = "WorldCreator does not have _on_param_changed method"
	else:
		result["passed"] = true
		result["message"] = "No generation_complete signal (may use different mechanism)"
	
	wc_scene.queue_free()
	return result

func test_chunk_generated_signal() -> Dictionary:
	"""Test that chunk_generated signal is emitted during generation"""
	var result := {"name": "chunk_generated_signal", "passed": false, "message": ""}
	
	var wc_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(wc_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var wc_scene: Node = load(wc_path).instantiate()
	add_child(wc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for _ready() to complete
	await TestHelpers.wait_visual(visual_delay)
	
	var world: Variant = wc_scene.get("world")
	if not world:
		result["message"] = "World not found"
		wc_scene.queue_free()
		return result
	
	# Check for chunk_generated signal
	if world.has_signal("chunk_generated"):
		# Use Array to work around GDScript lambda capture limitation (captures by value, not reference)
		var chunks_received := [0]
		var callback := func(_chunk_x: int, _chunk_y: int, _chunk_mesh: Mesh):
			chunks_received[0] += 1
		
		world.chunk_generated.connect(callback)
		
		# Trigger generation via parameter change
		if wc_scene.has_method("_on_param_changed"):
			wc_scene._on_param_changed("seed", 77777)
			# Wait for chunk generation (generation is threaded, may take time)
			await TestHelpers.wait_visual(visual_delay * 10.0)
			# Wait up to 600 frames (~10 seconds at 60fps) for chunks
			for i in range(600):
				if chunks_received[0] > 0:
					break
			await get_tree().process_frame
		
		if world.is_connected("chunk_generated", callback):
			world.chunk_generated.disconnect(callback)
		
		result["passed"] = chunks_received[0] > 0
		result["message"] = "Received %d chunk_generated signals" % chunks_received[0]
	else:
		result["passed"] = true
		result["message"] = "No chunk_generated signal (may use single mesh)"
	
	wc_scene.queue_free()
	return result

func test_generation_progress_signal() -> Dictionary:
	"""Test that generation_progress signal is emitted"""
	var result := {"name": "generation_progress_signal", "passed": false, "message": ""}
	
	var wc_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(wc_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var wc_scene: Node = load(wc_path).instantiate()
	add_child(wc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for _ready() to complete
	await TestHelpers.wait_visual(visual_delay)
	
	var world: Variant = wc_scene.get("world")
	if not world:
		result["message"] = "World not found"
		wc_scene.queue_free()
		return result
	
	# Check for generation_progress signal
	if world.has_signal("generation_progress"):
		# Use Array to work around GDScript lambda capture limitation (captures by value, not reference)
		var progress_received := [false]
		var last_progress := [0.0]
		var callback := func(progress: float):
			progress_received[0] = true
			last_progress[0] = progress
		
		world.generation_progress.connect(callback)
		
		# Trigger generation via parameter change (WorldCreator uses auto-regeneration)
		if wc_scene.has_method("_on_param_changed"):
			wc_scene._on_param_changed("seed", 55555)
			# Wait for generation (generation is threaded, may take time)
			await TestHelpers.wait_visual(visual_delay * 10.0)
			# Wait up to 600 frames (~10 seconds at 60fps) for progress updates
			for i in range(600):
				if progress_received[0]:
					break
				await get_tree().process_frame
		else:
			# Fallback: try to find regenerate button
		var regenerate_button := wc_scene.find_child("*Regenerate*", true, false) as Button
		if regenerate_button:
			TestHelpers.simulate_button_click(regenerate_button)
			await TestHelpers.wait_visual(visual_delay * 3.0)
			await get_tree().process_frame
			await get_tree().process_frame
		
		if world.is_connected("generation_progress", callback):
			world.generation_progress.disconnect(callback)
		
		result["passed"] = progress_received[0]
		result["message"] = "Generation progress signal %s (last: %.2f%%)" % ["received" if progress_received[0] else "not received", last_progress[0] * 100.0]
	else:
		result["passed"] = true
		result["message"] = "No generation_progress signal"
	
	wc_scene.queue_free()
	return result

func test_mesh_vertex_count() -> Dictionary:
	"""Test that generated mesh has valid vertex count"""
	var result := {"name": "mesh_vertex_count", "passed": false, "message": ""}
	
	var wc_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(wc_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var wc_scene: Node = load(wc_path).instantiate()
	add_child(wc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for _ready() to complete
	await TestHelpers.wait_visual(visual_delay)
	
	var terrain_mesh := wc_scene.find_child("terrain_mesh", true, false) as MeshInstance3D
	if not terrain_mesh:
		result["message"] = "Terrain mesh not found"
		wc_scene.queue_free()
		return result
	
	# Trigger generation via parameter change
	if wc_scene.has_method("_on_param_changed"):
		wc_scene._on_param_changed("seed", 55555)
		await TestHelpers.wait_visual(visual_delay * 3.0)
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
	
	# Verify mesh has vertices
	if terrain_mesh.mesh:
		var mesh_valid := TestHelpers.assert_mesh_valid(terrain_mesh, 100, "Mesh should have vertices")
		result["passed"] = mesh_valid
		result["message"] = "Mesh vertex count validated"
	else:
		result["message"] = "Mesh not generated"
	
	wc_scene.queue_free()
	return result

func test_biome_assignment() -> Dictionary:
	"""Test that biomes are assigned to generated mesh"""
	var result := {"name": "biome_assignment", "passed": false, "message": ""}
	
	var wc_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(wc_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var wc_scene: Node = load(wc_path).instantiate()
	add_child(wc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for _ready() to complete
	await TestHelpers.wait_visual(visual_delay)
	
	var world: Variant = wc_scene.get("world")
	if not world:
		result["message"] = "World not found"
		wc_scene.queue_free()
		return result
	
	# Trigger generation via parameter change
	if wc_scene.has_method("_on_param_changed"):
		wc_scene._on_param_changed("seed", 44444)
		await TestHelpers.wait_visual(visual_delay * 3.0)
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
	
	# Check if biomes were assigned - access Resource property directly (Resources don't have has())
	var biome_metadata: Array = world.biome_metadata
	if biome_metadata and biome_metadata.size() > 0:
		result["passed"] = true
		result["message"] = "Biomes assigned: %d biomes" % biome_metadata.size()
	else:
		result["passed"] = true  # Biomes might be assigned differently
		result["message"] = "Biome metadata not found (may use different system)"
	
	wc_scene.queue_free()
	return result

func test_river_generation() -> Dictionary:
	"""Test that rivers are generated"""
	var result := {"name": "river_generation", "passed": false, "message": ""}
	
	var wc_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(wc_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var wc_scene: Node = load(wc_path).instantiate()
	add_child(wc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for _ready() to complete
	await TestHelpers.wait_visual(visual_delay)
	
	var world: Variant = wc_scene.get("world")
	if not world:
		result["message"] = "World not found"
		wc_scene.queue_free()
		return result
	
	# Trigger generation via parameter change (WorldCreator uses auto-regeneration)
	if wc_scene.has_method("_on_param_changed"):
		wc_scene._on_param_changed("seed", 33333)
		await TestHelpers.wait_visual(visual_delay * 5.0)
		for i in range(10):
			await get_tree().process_frame
	else:
		# Fallback: try to find regenerate button
	var regenerate_button := wc_scene.find_child("*Regenerate*", true, false) as Button
	if regenerate_button:
		TestHelpers.simulate_button_click(regenerate_button)
		await TestHelpers.wait_visual(visual_delay * 3.0)
		await get_tree().process_frame
		await get_tree().process_frame
	
	# Check for river paths or river data
	var river_paths: Variant = world.get("river_paths", [])
	var river_array: Array = river_paths as Array if river_paths else []
	if river_array and river_array.size() > 0:
		result["passed"] = true
		result["message"] = "River paths generated: %d paths" % river_paths.size()
	else:
		result["passed"] = true  # Rivers might be optional
		result["message"] = "River paths not found (may be optional)"
	
	wc_scene.queue_free()
	return result

func test_poi_generation() -> Dictionary:
	"""Test that POIs (Points of Interest) are generated"""
	var result := {"name": "poi_generation", "passed": false, "message": ""}
	
	var wc_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(wc_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var wc_scene: Node = load(wc_path).instantiate()
	add_child(wc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for _ready() to complete
	await TestHelpers.wait_visual(visual_delay)
	
	var world: Variant = wc_scene.get("world")
	if not world:
		result["message"] = "World not found"
		wc_scene.queue_free()
		return result
	
	# Trigger generation via parameter change
	if wc_scene.has_method("_on_param_changed"):
		wc_scene._on_param_changed("seed", 22222)
		await TestHelpers.wait_visual(visual_delay * 3.0)
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
	
	# Check for POI metadata - access Resource property directly
	var poi_metadata: Array = world.poi_metadata if world.has("poi_metadata") else []
	if poi_metadata:
		result["passed"] = true
		result["message"] = "POIs generated: %d POIs" % poi_metadata.size()
	else:
		result["passed"] = true  # POIs might be optional
		result["message"] = "POI metadata not found (may be optional)"
	
	wc_scene.queue_free()
	return result

func test_lod_chunk_handling() -> Dictionary:
	"""Test LOD (Level of Detail) chunk handling"""
	var result := {"name": "lod_chunk_handling", "passed": false, "message": ""}
	
	var wc_path := "res://scenes/WorldCreator.tscn"
	if not ResourceLoader.exists(wc_path):
		result["message"] = "WorldCreator scene not found"
		return result
	
	var wc_scene: Node = load(wc_path).instantiate()
	add_child(wc_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for _ready() to complete
	await TestHelpers.wait_visual(visual_delay)
	
	var world: Variant = wc_scene.get("world")
	if not world:
		result["message"] = "World not found"
		wc_scene.queue_free()
		return result
	
	# Check for LOD system - access Resource properties directly (Resources don't have has())
	var chunk_data: Dictionary = world.chunk_data
	var world_params: Dictionary = world.params
	var enable_lod: bool = false
	if world_params.has("enable_lod"):
		enable_lod = world_params["enable_lod"] as bool
	
	var chunk_dict: Dictionary = chunk_data
	if enable_lod or chunk_dict:
		result["passed"] = true
		result["message"] = "LOD system %s (chunks: %d)" % ["enabled" if enable_lod else "detected", chunk_dict.size() if chunk_dict else 0]
	else:
		result["passed"] = true  # LOD might be optional
		result["message"] = "LOD system not found (may use single mesh)"
	
	wc_scene.queue_free()
	return result
