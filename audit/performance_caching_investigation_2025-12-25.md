# Performance Caching Investigation Report
**Date:** 2025-12-25  
**Purpose:** Identify caching opportunities to optimize game performance  
**Scope:** Procedural generation, terrain streaming, entity simulation, UI rendering, resource loading

---

## Executive Summary

After reviewing the codebase architecture, several high-impact caching opportunities have been identified. The project currently loads JSON files, resources, and performs computations repeatedly without caching. Implementing strategic caching will significantly improve performance, especially for:

1. **JSON Data Files** - Loaded on-demand without caching
2. **Azgaar Integration** - Repeated file copying and JS execution
3. **Terrain Generation** - Heightmap processing and noise calculations
4. **UI Systems** - Step definitions and parameter trees rebuilt frequently
5. **Resource Loading** - Models, textures, and materials loaded repeatedly

---

## Bottlenecks Identified

### 1. JSON File Loading (High Impact)
**Evidence:**
- `WorldBuilderUI.gd` loads `azgaar_step_parameters.json` on every `_ready()` call (line 231-294)
- `AbilityScoreTab.gd` loads `abilities.json` on every tab initialization (line 55-74)
- Multiple character creation tabs load JSON files independently
- No centralized JSON cache exists

**Impact:** 
- Repeated file I/O operations
- Redundant JSON parsing
- Memory waste from duplicate data structures

**Files Affected:**
- `ui/world_builder/WorldBuilderUI.gd` - `_load_step_definitions()`
- `scripts/character_creation/tabs/AbilityScoreTab.gd` - `_load_abilities_data()`
- `scripts/character_creation/tabs/ClassTab.gd` - Similar pattern
- `scripts/character_creation/tabs/RaceTab.gd` - Similar pattern
- All data loading in `data/` directory

---

### 2. Azgaar File Copying (High Impact)
**Evidence:**
- `AzgaarIntegrator.gd` copies entire Azgaar bundle (`res://tools/azgaar/`) to `user://azgaar/` on every `_ready()` call (line 16-89)
- Recursive directory copy operation is expensive
- No check if files already exist or are up-to-date

**Impact:**
- Significant startup delay
- Unnecessary disk I/O on every launch
- Potential for file corruption if copy is interrupted

**Files Affected:**
- `scripts/managers/AzgaarIntegrator.gd` - `copy_azgaar_to_user()`

---

### 3. Terrain Heightmap Processing (Medium-High Impact)
**Evidence:**
- `Terrain3DManager.gd` generates noise-based heightmaps without caching (line 108-163)
- `generate_from_noise()` creates new `FastNoiseLite` instance every call
- Heightmap image generation loops through 2048x2048 pixels (4M+ iterations)
- No caching of generated heightmaps by seed/parameters

**Impact:**
- Expensive noise calculations repeated for same seeds
- Large image generation operations
- Memory allocation for temporary images

**Files Affected:**
- `core/world_generation/Terrain3DManager.gd` - `generate_from_noise()`, `generate_from_heightmap()`

---

### 4. UI Parameter Tree Rebuilding (Medium Impact)
**Evidence:**
- `WorldBuilderUI.gd` rebuilds entire parameter tree on every step change (line 396-500)
- `_populate_param_tree()` clears and recreates all TreeItems
- No reuse of existing tree structure

**Impact:**
- UI lag when switching steps
- Redundant object creation/destruction
- Memory churn

**Files Affected:**
- `ui/world_builder/WorldBuilderUI.gd` - `_populate_param_tree()`

---

### 5. Resource Loading (Medium Impact)
**Evidence:**
- Character models loaded via `load()` without preloading or caching
- `CharacterPreview3D.gd` loads GLB/TSCN files on demand
- No ResourceLoader cache utilization

**Impact:**
- Disk I/O on every model load
- Potential stuttering when switching characters
- No benefit from Godot's built-in resource caching

**Files Affected:**
- `scripts/character_creation/CharacterPreview3D.gd` - Model loading
- Any `load()` or `preload()` calls without ResourceLoader cache

---

### 6. Azgaar JavaScript Execution (Medium Impact)
**Evidence:**
- `WorldBuilderAzgaar.gd` executes JavaScript repeatedly for parameter syncing (line 205-237)
- Each parameter change triggers separate JS execution
- No batching of parameter updates

**Impact:**
- WebView IPC overhead
- Repeated JS parsing/execution
- Slower parameter updates

**Files Affected:**
- `scripts/ui/WorldBuilderAzgaar.gd` - `_sync_parameters_to_azgaar()`

---

### 7. World Map Data Operations (Low-Medium Impact)
**Evidence:**
- `WorldMapData.gd` performs elevation lookups without spatial caching
- `get_elevation_at()` reads pixels directly from image every call (line 186-200)
- No caching of frequently accessed elevation data

**Impact:**
- Repeated image pixel reads
- No spatial locality optimization

**Files Affected:**
- `core/world_generation/WorldMapData.gd` - `get_elevation_at()`

---

## Potential Cacheable Items

### 1. JSON Data Cache (Priority: HIGH)
**Location:** Create new `core/singletons/DataCache.gd`

**Mechanism:**
- Singleton autoload that caches parsed JSON data
- Dictionary mapping file paths to parsed data
- Lazy loading with first-access caching
- Optional: Preload critical JSON files on startup

**Implementation:**
```gdscript
# Pseudo-code structure
var json_cache: Dictionary = {}

func get_json_data(path: String) -> Variant:
    if json_cache.has(path):
        return json_cache[path]
    
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        return null
    
    var json = JSON.new()
    json.parse(file.get_as_text())
    file.close()
    
    json_cache[path] = json.data
    return json.data
```

**Files to Modify:**
- Create: `core/singletons/DataCache.gd`
- Modify: `ui/world_builder/WorldBuilderUI.gd` - Use DataCache instead of direct file access
- Modify: `scripts/character_creation/tabs/*.gd` - Use DataCache
- Add to `project.godot` autoload

**Estimated Impact:** 
- 50-80% reduction in JSON parse time
- Eliminates redundant file I/O
- Memory overhead: ~5-10MB for all JSON files

**Trade-offs:**
- Memory usage increases (but JSON files are small)
- Cache invalidation needed if JSON files change during development

---

### 2. Azgaar File Copy Cache (Priority: HIGH)
**Location:** `scripts/managers/AzgaarIntegrator.gd`

**Mechanism:**
- Check if `user://azgaar/` exists and has valid files
- Compare file modification times or use hash-based validation
- Skip copy if files are up-to-date
- Optional: Background copy on first launch

**Implementation:**
```gdscript
func copy_azgaar_to_user() -> void:
    var user_dir = "user://azgaar/"
    if DirAccess.dir_exists_absolute(user_dir):
        # Check if key files exist and are recent
        if FileAccess.file_exists(user_dir.path_join("index.html")):
            var source_time = FileAccess.get_modified_time(AZGAAR_BUNDLE_PATH.path_join("index.html"))
            var dest_time = FileAccess.get_modified_time(user_dir.path_join("index.html"))
            if dest_time >= source_time:
                return  # Files are up-to-date
    
    # Perform copy only if needed
    _copy_directory_recursive(...)
```

**Files to Modify:**
- `scripts/managers/AzgaarIntegrator.gd` - `copy_azgaar_to_user()`

**Estimated Impact:**
- Eliminates 1-5 second startup delay
- Reduces disk I/O by 99% on subsequent launches

**Trade-offs:**
- Slightly more complex file validation logic
- Need to handle version mismatches if Azgaar bundle updates

---

### 3. Terrain Heightmap Cache (Priority: MEDIUM-HIGH)
**Location:** `core/world_generation/Terrain3DManager.gd`

**Mechanism:**
- Cache generated heightmap Images by seed + parameters hash
- Store in Dictionary: `{seed: int, params_hash: int} -> Image`
- Limit cache size (LRU eviction)
- Optional: Disk-based cache for large heightmaps

**Implementation:**
```gdscript
var heightmap_cache: Dictionary = {}
const MAX_CACHE_SIZE: int = 10

func generate_from_noise(seed_value: int, frequency: float, ...) -> void:
    var cache_key = hash_seed_and_params(seed_value, frequency, ...)
    if heightmap_cache.has(cache_key):
        var cached_image = heightmap_cache[cache_key]
        terrain.data.import_images([cached_image, null, null], ...)
        return
    
    # Generate new heightmap
    var height_image = _generate_heightmap(...)
    
    # Cache it
    if heightmap_cache.size() >= MAX_CACHE_SIZE:
        # LRU eviction: remove oldest
        var oldest_key = heightmap_cache.keys()[0]
        heightmap_cache.erase(oldest_key)
    heightmap_cache[cache_key] = height_image.duplicate()
```

**Files to Modify:**
- `core/world_generation/Terrain3DManager.gd` - `generate_from_noise()`

**Estimated Impact:**
- 80-95% reduction in noise calculation time for repeated seeds
- Faster terrain regeneration during testing

**Trade-offs:**
- Memory usage: ~50-200MB for cached heightmaps (2048x2048 RF format = 16MB each)
- Cache invalidation needed if generation algorithm changes

---

### 4. UI Parameter Tree Cache (Priority: MEDIUM)
**Location:** `ui/world_builder/WorldBuilderUI.gd`

**Mechanism:**
- Cache TreeItem structures per step
- Reuse tree structure instead of clearing/recreating
- Only update values when parameters change

**Implementation:**
```gdscript
var cached_trees: Dictionary = {}  # step_index -> TreeItem root

func _populate_param_tree() -> void:
    if cached_trees.has(current_step):
        # Restore cached tree
        var cached_root = cached_trees[current_step]
        param_tree.root = cached_root
        # Update values from current_params
        _update_tree_values()
        return
    
    # Create new tree and cache it
    var root = _create_tree_for_step(current_step)
    cached_trees[current_step] = root
```

**Files to Modify:**
- `ui/world_builder/WorldBuilderUI.gd` - `_populate_param_tree()`

**Estimated Impact:**
- 60-80% reduction in UI rebuild time
- Smoother step navigation

**Trade-offs:**
- Slightly more complex tree management
- Need to handle parameter value updates without full rebuild

---

### 5. Resource Preloading Cache (Priority: MEDIUM)
**Location:** Create new `core/singletons/ResourceCache.gd`

**Mechanism:**
- Preload common resources (models, textures) on startup
- Use ResourceLoader with `CACHE_MODE_REUSE` flag
- Dictionary cache mapping paths to resources
- Background loading for non-critical resources

**Implementation:**
```gdscript
var resource_cache: Dictionary = {}

func preload_resource(path: String) -> void:
    if resource_cache.has(path):
        return
    var resource = load(path)
    if resource:
        resource_cache[path] = resource

func get_resource(path: String) -> Resource:
    if resource_cache.has(path):
        return resource_cache[path]
    var resource = load(path)
    if resource:
        resource_cache[path] = resource
    return resource
```

**Files to Modify:**
- Create: `core/singletons/ResourceCache.gd`
- Modify: `scripts/character_creation/CharacterPreview3D.gd` - Use ResourceCache
- Add to `project.godot` autoload

**Estimated Impact:**
- 70-90% reduction in model load time after first load
- Eliminates stuttering when switching characters

**Trade-offs:**
- Memory usage increases (models can be large)
- Need to manage cache size for memory-constrained systems

---

### 6. Azgaar Parameter Batching (Priority: LOW-MEDIUM)
**Location:** `scripts/ui/WorldBuilderAzgaar.gd`

**Mechanism:**
- Batch multiple parameter updates into single JS execution
- Use debouncing to collect parameter changes
- Execute JS once per frame or after delay

**Implementation:**
```gdscript
var pending_params: Dictionary = {}
var sync_timer: Timer = null

func _sync_parameters_to_azgaar(params: Dictionary) -> void:
    pending_params.merge(params)
    
    if not sync_timer:
        sync_timer = Timer.new()
        sync_timer.wait_time = 0.1  # 100ms debounce
        sync_timer.one_shot = true
        sync_timer.timeout.connect(_flush_pending_params)
        add_child(sync_timer)
    
    sync_timer.start()

func _flush_pending_params() -> void:
    # Build single JS code block for all params
    var js_code = "if (typeof azgaar !== 'undefined') { "
    for key in pending_params:
        js_code += "azgaar.options.%s = %s; " % [key, format_value(pending_params[key])]
    js_code += " }"
    _execute_azgaar_js(js_code)
    pending_params.clear()
```

**Files to Modify:**
- `scripts/ui/WorldBuilderAzgaar.gd` - `_sync_parameters_to_azgaar()`

**Estimated Impact:**
- 50-70% reduction in JS execution overhead
- Faster parameter updates

**Trade-offs:**
- Slight delay before parameters are applied (100ms debounce)
- More complex state management

---

### 7. Elevation Lookup Cache (Priority: LOW)
**Location:** `core/world_generation/WorldMapData.gd`

**Mechanism:**
- Spatial hash cache for frequently accessed elevation values
- Cache grid: divide world into chunks, cache elevation per chunk
- LRU eviction for memory management

**Implementation:**
```gdscript
var elevation_cache: Dictionary = {}
const CACHE_CHUNK_SIZE: int = 64  # pixels

func get_elevation_at(position: Vector2) -> float:
    var chunk_x = int(position.x / CACHE_CHUNK_SIZE)
    var chunk_y = int(position.y / CACHE_CHUNK_SIZE)
    var cache_key = "%d,%d" % [chunk_x, chunk_y]
    
    if elevation_cache.has(cache_key):
        return elevation_cache[cache_key]
    
    # Calculate and cache
    var elevation = _calculate_elevation(position)
    elevation_cache[cache_key] = elevation
    return elevation
```

**Files to Modify:**
- `core/world_generation/WorldMapData.gd` - `get_elevation_at()`

**Estimated Impact:**
- 40-60% reduction in elevation lookup time for repeated queries
- Better performance for pathfinding/AI systems

**Trade-offs:**
- Memory overhead for cache (minimal for spatial hash)
- Cache invalidation needed if heightmap changes

---

## Next Steps

### Phase 1: Quick Wins (Week 1)
1. **Implement DataCache singleton** for JSON files
   - Highest impact, lowest risk
   - Affects multiple systems
   - Easy to test and validate

2. **Fix Azgaar file copying** with existence check
   - Eliminates startup delay
   - Simple file validation logic
   - Immediate user-visible improvement

### Phase 2: Terrain Optimization (Week 2)
3. **Implement heightmap cache** in Terrain3DManager
   - High impact for world generation testing
   - Requires careful memory management
   - Test with various seed values

### Phase 3: UI Optimization (Week 3)
4. **Implement parameter tree cache** in WorldBuilderUI
   - Improves UI responsiveness
   - Medium complexity
   - User-visible improvement

5. **Implement resource preloading** for character models
   - Reduces character creation stuttering
   - Requires memory budget planning

### Phase 4: Advanced Optimizations (Week 4+)
6. **Azgaar parameter batching**
   - Lower priority, but improves parameter sync
   - Requires careful timing

7. **Elevation lookup cache** (if needed)
   - Only if elevation queries become bottleneck
   - Monitor usage first

---

## Implementation Guidelines

### Cache Invalidation Strategy
- **JSON Cache:** Invalidate on file modification time change (development only)
- **Heightmap Cache:** Invalidate on seed/parameter change
- **Resource Cache:** Persistent until explicit clear (game restart)
- **UI Tree Cache:** Invalidate on step definition JSON change

### Memory Management
- Set maximum cache sizes for all caches
- Implement LRU eviction for bounded caches
- Monitor memory usage with `Performance.get_monitor()`
- Add cache clearing methods for low-memory scenarios

### Testing Requirements
- Verify cache hits reduce load times
- Test cache invalidation on file changes
- Monitor memory usage during extended play
- Performance benchmarks before/after caching

### Code Quality
- Follow project coding standards (typed GDScript, headers)
- Add docstrings for all cache methods
- Use MythosLogger for cache operations
- Add unit tests for cache logic (GUT framework)

---

## Estimated Overall Impact

**Performance Improvements:**
- Startup time: **30-50% reduction** (Azgaar copy + JSON loading)
- World generation: **40-60% faster** for repeated seeds (heightmap cache)
- UI responsiveness: **50-70% improvement** (tree cache + parameter batching)
- Character creation: **60-80% faster** model loading (resource cache)

**Memory Overhead:**
- JSON cache: ~5-10MB
- Heightmap cache: ~50-200MB (configurable)
- Resource cache: ~100-500MB (configurable, depends on models)
- **Total: ~155-710MB** (acceptable for mid-range hardware)

**Trade-offs:**
- Slightly increased memory usage (acceptable for performance gain)
- More complex code (mitigated by singleton pattern)
- Cache invalidation logic needed (standard practice)

---

## Conclusion

Implementing these caching strategies will significantly improve game performance with minimal code complexity. The highest-impact items (JSON cache, Azgaar copy optimization) should be prioritized first, as they provide immediate benefits with low risk. Terrain and UI caching will further improve the user experience during world generation and character creation.

All caching implementations should follow the project's data-driven architecture (JSON/Resources) and maintain extensibility for future features like save/load and multiplayer.

