# ╔═══════════════════════════════════════════════════════════
# ║ DataCache.gd
# ║ Desc: Centralized cache for parsed JSON data files to eliminate redundant file I/O and parsing
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

var _json_cache: Dictionary = {}

## Returns parsed JSON data for the given path. Caches result on first load.
func get_json_data(path: String) -> Variant:
	if _json_cache.has(path):
		return _json_cache[path]
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("DataCache: Failed to open JSON file at %s" % path)
		return null
	
	var text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(text)
	if parse_result != OK:
		push_error("DataCache: Failed to parse JSON at %s - %s" % [path, json.get_error_message()])
		return null
	
	_json_cache[path] = json.data
	return json.data


## Clears the entire cache (useful for development when JSON files change)
func clear_cache() -> void:
	_json_cache.clear()


## Clears a specific entry (optional utility)
func invalidate_path(path: String) -> void:
	_json_cache.erase(path)

