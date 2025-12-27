# ╔═══════════════════════════════════════════════════════════
# ║ DataCache.gd
# ║ Desc: Centralized cache for parsed JSON data files to eliminate redundant file I/O and parsing
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

## Maximum number of cached entries (LRU eviction)
const MAX_CACHE_SIZE: int = 50

## Cache structure: path -> { "data": Variant, "mod_time": int }
var _json_cache: Dictionary = {}

## LRU order: Array of paths, most recently used at end
var _lru_order: Array[String] = []

## Cache statistics
var hits: int = 0
var misses: int = 0


func _ready() -> void:
	"""Preload common JSON files at startup."""
	preload_common_files()


## Returns parsed JSON data for the given path. Caches result on first load.
## Automatically invalidates cache if file modification time has changed.
func get_json_data(path: String) -> Variant:
	# Check if cached
	if _json_cache.has(path):
		var cache_entry: Dictionary = _json_cache[path]
		var cached_mod_time: int = cache_entry.get("mod_time", 0)
		
		# Check if file has been modified
		if FileAccess.file_exists(path):
			var current_mod_time: int = FileAccess.get_modified_time(path)
			if current_mod_time == cached_mod_time:
				# Cache hit - update LRU order
				_update_lru(path)
				hits += 1
				return cache_entry.get("data")
			else:
				# File modified - invalidate cache entry
				_json_cache.erase(path)
				_lru_order.erase(path)
		
		# File doesn't exist anymore - remove from cache
		_json_cache.erase(path)
		_lru_order.erase(path)
	
	# Cache miss - load and parse file
	misses += 1
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("DataCache: Failed to open JSON file at %s" % path)
		return null
	
	var text := file.get_as_text()
	var mod_time: int = FileAccess.get_modified_time(path)
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(text)
	if parse_result != OK:
		push_error("DataCache: Failed to parse JSON at %s - %s" % [path, json.get_error_message()])
		return null
	
	# Check cache size and evict if needed
	if _json_cache.size() >= MAX_CACHE_SIZE:
		_evict_lru()
	
	# Store in cache with modification time
	_json_cache[path] = {
		"data": json.data,
		"mod_time": mod_time
	}
	_update_lru(path)
	
	return json.data


## Updates LRU order (moves path to end = most recently used)
func _update_lru(path: String) -> void:
	_lru_order.erase(path)
	_lru_order.append(path)


## Evicts least recently used entry (first in array)
func _evict_lru() -> void:
	if _lru_order.is_empty():
		return
	
	var oldest_path: String = _lru_order[0]
	_json_cache.erase(oldest_path)
	_lru_order.erase(0)
	MythosLogger.debug("DataCache", "Evicted LRU entry", {"path": oldest_path})


## Clears the entire cache (useful for development when JSON files change)
func clear_cache() -> void:
	_json_cache.clear()
	_lru_order.clear()
	hits = 0
	misses = 0
	MythosLogger.debug("DataCache", "Cache cleared")


## Clears a specific entry (optional utility)
func invalidate_path(path: String) -> void:
	_json_cache.erase(path)
	_lru_order.erase(path)
	MythosLogger.debug("DataCache", "Invalidated path", {"path": path})


## Preloads common JSON files at startup for faster access
func preload_common_files() -> void:
	"""Preload critical JSON files that are frequently accessed."""
	var common_files: Array[String] = [
		"res://data/biomes.json",
		"res://data/civilizations.json",
		"res://data/resources.json",
		"res://data/fantasy_archetypes.json",
		"res://data/abilities.json",
		"res://data/classes.json",
		"res://data/races.json",
		"res://data/backgrounds.json",
		"res://data/map_icons.json"
	]
	
	for file_path in common_files:
		if ResourceLoader.exists(file_path):
			var data = get_json_data(file_path)
			if data != null:
				MythosLogger.debug("DataCache", "Preloaded JSON file", {"path": file_path})
			else:
				MythosLogger.warn("DataCache", "Failed to preload JSON file", {"path": file_path})
		else:
			MythosLogger.debug("DataCache", "Skipping non-existent file", {"path": file_path})


## Returns cache statistics as a formatted string
func get_stats() -> String:
	var total: int = hits + misses
	var hit_rate: float = (float(hits) / float(total) * 100.0) if total > 0 else 0.0
	return "DataCache Stats: Hits=%d, Misses=%d, HitRate=%.1f%%, CacheSize=%d/%d" % [
		hits, misses, hit_rate, _json_cache.size(), MAX_CACHE_SIZE
	]
