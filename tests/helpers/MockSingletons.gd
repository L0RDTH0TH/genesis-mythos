# ╔═══════════════════════════════════════════════════════════
# ║ MockSingletons.gd
# ║ Desc: Mock implementations of singletons for test isolation
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends RefCounted
class_name MockSingletons

## Mock Logger that captures log messages
class MockLogger:
	extends Node
	
	var log_messages: Array[Dictionary] = []
	
	func error(system: String, message: String, data: Variant = null) -> void:
		log_messages.append({"level": "ERROR", "system": system, "message": message, "data": data})
	
	func warn(system: String, message: String, data: Variant = null) -> void:
		log_messages.append({"level": "WARN", "system": system, "message": message, "data": data})
	
	func info(system: String, message: String, data: Variant = null) -> void:
		log_messages.append({"level": "INFO", "system": system, "message": message, "data": data})
	
	func debug(system: String, message: String, data: Variant = null) -> void:
		log_messages.append({"level": "DEBUG", "system": system, "message": message, "data": data})
	
	func verbose(system: String, message: String, data: Variant = null) -> void:
		log_messages.append({"level": "VERBOSE", "system": system, "message": message, "data": data})
	
	func clear() -> void:
		log_messages.clear()
	
	func has_error() -> bool:
		for msg in log_messages:
			if msg.get("level") == "ERROR":
				return true
		return false

## Mock WorldStreamer that simulates chunk loading
class MockWorldStreamer:
	extends Node
	
	var loaded_chunks: Dictionary = {}
	var load_failures: Array[Vector2i] = []
	
	func load_chunk(chunk_coord: Vector2i) -> bool:
		"""Mock chunk loading. Returns true if successful."""
		if load_failures.has(chunk_coord):
			return false
		loaded_chunks[chunk_coord] = true
		return true
	
	func unload_chunk(chunk_coord: Vector2i) -> void:
		loaded_chunks.erase(chunk_coord)
	
	func is_chunk_loaded(chunk_coord: Vector2i) -> bool:
		return loaded_chunks.has(chunk_coord)
	
	func simulate_load_failure(chunk_coord: Vector2i) -> void:
		"""Simulate a chunk load failure for testing."""
		load_failures.append(chunk_coord)
	
	func clear() -> void:
		loaded_chunks.clear()
		load_failures.clear()

## Mock EntitySim that tracks entity operations
class MockEntitySim:
	extends Node
	
	var spawned_entities: Array[Dictionary] = []
	var despawned_entities: Array[int] = []
	
	func spawn_entity(entity_type: String, position: Vector3) -> int:
		"""Mock entity spawning. Returns entity ID."""
		var entity_id: int = spawned_entities.size()
		spawned_entities.append({"id": entity_id, "type": entity_type, "position": position})
		return entity_id
	
	func despawn_entity(entity_id: int) -> void:
		despawned_entities.append(entity_id)
		# Remove from spawned list
		for i in range(spawned_entities.size()):
			if spawned_entities[i].get("id") == entity_id:
				spawned_entities.remove_at(i)
				break
	
	func get_entity_count() -> int:
		return spawned_entities.size()
	
	func clear() -> void:
		spawned_entities.clear()
		despawned_entities.clear()

## Mock FactionEconomy that tracks economic operations
class MockFactionEconomy:
	extends Node
	
	var faction_resources: Dictionary = {}
	var transactions: Array[Dictionary] = []
	
	func add_faction(faction_id: String, initial_resources: Dictionary = {}) -> void:
		faction_resources[faction_id] = initial_resources.duplicate()
	
	func transfer_resources(from_faction: String, to_faction: String, resources: Dictionary) -> bool:
		"""Mock resource transfer. Returns true if successful."""
		if not faction_resources.has(from_faction) or not faction_resources.has(to_faction):
			return false
		
		transactions.append({
			"from": from_faction,
			"to": to_faction,
			"resources": resources
		})
		return true
	
	func get_faction_resources(faction_id: String) -> Dictionary:
		return faction_resources.get(faction_id, {}).duplicate()
	
	func clear() -> void:
		faction_resources.clear()
		transactions.clear()
