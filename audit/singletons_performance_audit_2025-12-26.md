# Singletons Performance Audit
**Date:** 2025-12-26  
**Purpose:** Identify potential sources of high idle Process Time / low FPS in UI scenes (especially World Builder UI)  
**Scope:** All core singletons and autoloaded scripts

---

## Executive Summary

**Key Findings:**
- **1 singleton** has `_process()` that runs every frame: `PerformanceLogger.gd`
- **1 singleton** instantiates a scene with `_process()`: `PerformanceMonitorSingleton` → `PerformanceMonitor` (has early return guard)
- **1 singleton** uses Timer-based polling: `AzgaarServer.gd` (100ms interval)
- **7 singletons** are event-driven only (no per-frame overhead)

**Likely Culprits for Idle FPS Drop:**
1. **PerformanceLogger._process()** - Runs every frame even when logging is disabled
2. **PerformanceMonitor._process()** - Early return check has minimal cost, but still runs every frame
3. **AzgaarServer polling timer** - Polls every 100ms even when idle (low impact)

---

## Autoloaded Singletons (from project.godot)

All singletons listed in `[autoload]` section:
1. `Eryndor` → `res://core/singletons/eryndor.gd`
2. `MythosLogger` → `res://core/singletons/Logger.gd`
3. `WorldStreamer` → `res://core/streaming/world_streamer.gd`
4. `EntitySim` → `res://core/sim/entity_sim.gd`
5. `FactionEconomy` → `res://core/sim/faction_economy.gd`
6. `PerformanceMonitorSingleton` → `res://core/singletons/PerformanceMonitorSingleton.gd`
7. `PerformanceLogger` → `res://core/singletons/PerformanceLogger.gd`
8. `FlameGraphProfiler` → `res://core/singletons/FlameGraphProfiler.gd`
9. `AzgaarIntegrator` → `res://scripts/managers/AzgaarIntegrator.gd`
10. `AzgaarServer` → `res://scripts/managers/AzgaarServer.gd`

---

## Per-Singleton Analysis

### 1. Eryndor (`res://core/singletons/eryndor.gd`)

**Status:** ✅ **SAFE** - No per-frame overhead

**Code Excerpt:**
```gdscript
func _ready() -> void:
	MythosLogger.verbose("Core", "_ready() called")
	MythosLogger.info("Core", "Authentic engine initialized – the truth awakens.")
	MythosLogger.debug("Core", "Eryndor singleton ready", {"version": "4.0 Final"})
```

**Analysis:**
- Only has `_ready()` method
- No `_process()`, `_physics_process()`, or Timers
- All operations are event-driven (logging calls)
- **Zero idle overhead**

**Recommendation:** No changes needed.

---

### 2. Logger (`res://core/singletons/Logger.gd`)

**Status:** ✅ **SAFE** - No per-frame overhead

**Code Excerpt:**
```gdscript
func _ready() -> void:
	"""Initialize the logger on ready."""
	_load_config()
	_setup_file_logging()
	info("Logger", "Logging system initialized")

func _exit_tree() -> void:
	"""Cleanup on exit."""
	_close_log_file()
	info("Logger", "Logging system shutting down")
```

**Analysis:**
- Only has `_ready()` and `_exit_tree()` methods
- No `_process()`, `_physics_process()`, or Timers
- All logging operations are event-driven (called on-demand)
- Uses mutex for thread safety, but no polling
- **Zero idle overhead**

**Recommendation:** No changes needed.

---

### 3. WorldStreamer (`res://core/streaming/world_streamer.gd`)

**Status:** ✅ **SAFE** - No per-frame overhead

**Code Excerpt:**
```gdscript
func _ready() -> void:
	MythosLogger.verbose("World/Streaming", "_ready() called")
	MythosLogger.info("World/Streaming", "World streaming system initialized")
```

**Analysis:**
- Only has `_ready()` method
- No `_process()`, `_physics_process()`, or Timers
- **Zero idle overhead**

**Recommendation:** No changes needed.

---

### 4. EntitySim (`res://core/sim/entity_sim.gd`)

**Status:** ✅ **SAFE** - No per-frame overhead

**Code Excerpt:**
```gdscript
func _ready() -> void:
	MythosLogger.verbose("Sim/Entity", "_ready() called")
	MythosLogger.info("Sim/Entity", "Entity simulation system initialized")
```

**Analysis:**
- Only has `_ready()` method
- No `_process()`, `_physics_process()`, or Timers
- **Zero idle overhead**

**Recommendation:** No changes needed.  
**Note:** When entity simulation is implemented, it should use `set_process()` to enable/disable based on scene context (e.g., disabled in UI-only scenes).

---

### 5. FactionEconomy (`res://core/sim/faction_economy.gd`)

**Status:** ✅ **SAFE** - No per-frame overhead

**Code Excerpt:**
```gdscript
func _ready() -> void:
	MythosLogger.verbose("Sim/Economy", "_ready() called")
	MythosLogger.info("Sim/Economy", "Faction economy system initialized")
```

**Analysis:**
- Only has `_ready()` method
- No `_process()`, `_physics_process()`, or Timers
- **Zero idle overhead**

**Recommendation:** No changes needed.  
**Note:** When faction/economy simulation is implemented, it should use `set_process()` to enable/disable based on scene context (e.g., disabled in UI-only scenes).

---

### 6. PerformanceMonitorSingleton (`res://core/singletons/PerformanceMonitorSingleton.gd`)

**Status:** 🟡 **CONDITIONAL** - Instantiates PerformanceMonitor scene with `_process()`

**Code Excerpt:**
```gdscript
func _ready() -> void:
	"""Instantiate and add the Performance Monitor overlay to the scene tree."""
	MythosLogger.debug("PerformanceMonitorSingleton", "_ready() called - instantiating global overlay")
	
	# Instantiate the Performance Monitor scene
	monitor_instance = monitor_scene.instantiate() as PerformanceMonitor
	if monitor_instance == null:
		MythosLogger.error("PerformanceMonitorSingleton", "Failed to instantiate PerformanceMonitor scene")
		return
	
	# Add to scene tree
	add_child(monitor_instance, true)
```

**Analysis:**
- Singleton itself has no `_process()` or Timers
- **BUT:** Instantiates `PerformanceMonitor` scene which has `_process()` (see below)
- The `PerformanceMonitor._process()` has an early return guard:
  ```gdscript
  if not visible or current_mode == Mode.OFF:
      return
  ```
- However, the early return check itself runs every frame (minimal cost: visibility check + mode comparison)

**PerformanceMonitor._process() Details:**
- Runs every frame when overlay is visible and mode != OFF
- When hidden/OFF: Only performs early return check (~0.01-0.05ms estimated)
- When visible: Performs full update (FPS, graphs, metrics, RenderingServer calls)

**Idle Overhead (when hidden/OFF):**
- **Estimated:** ~0.01-0.05ms per frame (negligible)
- **Frequency:** Every frame (60+ times per second)
- **Severity:** 🟢 **LOW** - Early return guard minimizes overhead

**Recommendation:**
- **Option 1 (Current):** Keep early return guard (acceptable overhead)
- **Option 2 (Optimization):** Use `set_process()` to disable `_process()` when mode == OFF:
  ```gdscript
  # In PerformanceMonitor.gd, modify set_mode():
  func set_mode(new_mode: Mode) -> void:
      current_mode = new_mode
      set_process(current_mode != Mode.OFF and visible)
      # ... rest of function ...
  ```
- **Option 3 (Best):** Also check visibility in `set_process()`:
  ```gdscript
  func _notification(what: int) -> void:
      if what == NOTIFICATION_VISIBILITY_CHANGED:
          set_process(visible and current_mode != Mode.OFF)
  ```

---

### 7. PerformanceLogger (`res://core/singletons/PerformanceLogger.gd`)

**Status:** 🔴 **SUSPICIOUS** - Has `_process()` that runs every frame

**Code Excerpt:**
```gdscript
func _process(_delta: float) -> void:
	"""Process per-frame logic: handle interval logging."""
	# If logging is enabled but file not open, start new log file
	if is_logging_enabled and log_file == null:
		_start_log_file()
```

**Analysis:**
- **Has `_process()` that runs every frame**
- Performs minimal check: `if is_logging_enabled and log_file == null`
- However, this check runs **every frame** even when logging is disabled
- When logging is disabled: Still checks `is_logging_enabled` every frame
- When logging is enabled: Checks `log_file == null` every frame (until file is opened)

**Idle Overhead:**
- **Estimated:** ~0.01-0.05ms per frame (minimal, but unnecessary)
- **Frequency:** Every frame (60+ times per second)
- **Severity:** 🟡 **MEDIUM** - Unnecessary per-frame check when disabled

**Recommendation:**
- **Option 1 (Quick Fix):** Disable `_process()` when logging is disabled:
  ```gdscript
  func _ready() -> void:
      # ... existing code ...
      if is_logging_enabled:
          start_logging()
          set_process(true)  # Enable _process only when logging
      else:
          set_process(false)  # Disable _process when logging disabled
  
  func start_logging() -> void:
      if is_logging_enabled and log_file == null:
          _start_log_file()
      set_process(true)  # Enable _process when logging starts
  
  func stop_logging() -> void:
      if log_file != null:
          _close_log_file()
      set_process(false)  # Disable _process when logging stops
  ```
- **Option 2 (Better):** Use Timer instead of `_process()` for file check:
  ```gdscript
  var file_check_timer: Timer = null
  
  func _ready() -> void:
      # ... existing code ...
      if is_logging_enabled:
          start_logging()
      else:
          set_process(false)
  
  func start_logging() -> void:
      if is_logging_enabled and log_file == null:
          _start_log_file()
      # Use Timer for periodic file check (every 1 second)
      if file_check_timer == null:
          file_check_timer = Timer.new()
          file_check_timer.wait_time = 1.0
          file_check_timer.timeout.connect(_check_log_file)
          add_child(file_check_timer)
          file_check_timer.start()
      set_process(false)  # Disable _process, use Timer instead
  ```

---

### 8. FlameGraphProfiler (`res://core/singletons/FlameGraphProfiler.gd`)

**Status:** ✅ **SAFE** - Uses Timers only when profiling is enabled

**Code Excerpt:**
```gdscript
func _ready() -> void:
	"""Initialize the flame graph profiler on ready."""
	_load_config()
	_apply_config()
	
	if is_profiling_enabled:
		# Setup timers directly since config says enabled
		var sampling_mode: String = config.get("sampling_mode", "sampling")
		if sampling_mode == "sampling":
			_setup_sampling_timer()
		_setup_auto_export_timer()
```

**Analysis:**
- No `_process()` or `_physics_process()`
- Uses Timers for sampling, aggregation, and auto-export
- Timers are only created when `is_profiling_enabled == true`
- Default config: `enabled: false`
- **Zero idle overhead when disabled**

**Timer Details:**
- `sampling_timer`: Configurable interval (default 10ms) - only active when profiling
- `aggregation_timer`: 1 second interval - only active when profiling
- `auto_export_timer`: Configurable interval (default 60s) - only active when profiling

**Recommendation:** No changes needed. Profiling is opt-in and uses Timers (not per-frame).

---

### 9. AzgaarIntegrator (`res://scripts/managers/AzgaarIntegrator.gd`)

**Status:** ✅ **SAFE** - No per-frame overhead

**Code Excerpt:**
```gdscript
func _ready() -> void:
	copy_azgaar_to_user()
```

**Analysis:**
- Only has `_ready()` method (performs one-time file copy)
- No `_process()`, `_physics_process()`, or Timers
- All operations are event-driven (called on-demand)
- **Zero idle overhead**

**Recommendation:** No changes needed.

---

### 10. AzgaarServer (`res://scripts/managers/AzgaarServer.gd`)

**Status:** 🟡 **LOW IMPACT** - Uses Timer-based polling (100ms interval)

**Code Excerpt:**
```gdscript
func _ready() -> void:
	"""Initialize the HTTP server on ready."""
	start_server()
	
	# Use Timer-based polling instead of _process() for better performance
	polling_timer = Timer.new()
	polling_timer.name = "PollingTimer"
	polling_timer.wait_time = 0.1  # Poll every 100ms instead of every frame
	polling_timer.one_shot = false
	polling_timer.timeout.connect(_on_polling_timer_timeout)
	add_child(polling_timer)
	polling_timer.start()
	
	# Disable _process() - use timer instead
	set_process(false)
```

**Analysis:**
- **Uses Timer instead of `_process()`** (good design)
- Polls every 100ms (10 times per second) instead of every frame (60+ times per second)
- Timer callback `_on_polling_timer_timeout()` handles HTTP connections
- **However:** Timer runs even when no connections are active (idle polling)

**Idle Overhead:**
- **Estimated:** ~0.1-0.5ms per timer tick (10 times per second)
- **Frequency:** 10 times per second (vs 60+ for `_process()`)
- **Severity:** 🟢 **LOW** - Timer-based is much better than per-frame, but still polls when idle

**Recommendation:**
- **Option 1 (Current):** Acceptable - Timer-based polling is reasonable for HTTP server
- **Option 2 (Optimization):** Only start timer when connections are expected (e.g., when World Builder UI is open):
  ```gdscript
  func start_server() -> bool:
      # ... existing code ...
      if err == OK:
          port = try_port
          # Only start polling timer when server is actually needed
          # (could be controlled by scene context)
          _start_polling_timer()
          return true
  ```
- **Note:** HTTP server is needed for Azgaar WebView integration, so timer should run when World Builder UI is active. Consider pausing timer when World Builder UI is closed.

---

## Summary: Likely Culprits for Idle FPS Drop

### 🔴 High Priority (Fix Recommended)

1. **PerformanceLogger._process()** - Runs every frame even when disabled
   - **Impact:** ~0.01-0.05ms per frame (unnecessary overhead)
   - **Fix:** Disable `_process()` when logging is disabled, or use Timer instead

### 🟡 Medium Priority (Optimization Opportunity)

2. **PerformanceMonitor._process()** - Early return check runs every frame
   - **Impact:** ~0.01-0.05ms per frame (minimal, but could be optimized)
   - **Fix:** Use `set_process()` to disable when mode == OFF

3. **AzgaarServer polling timer** - Polls every 100ms even when idle
   - **Impact:** ~0.1-0.5ms per timer tick (10 times per second)
   - **Fix:** Pause timer when World Builder UI is closed

### 🟢 Low Priority (Acceptable)

4. All other singletons are event-driven only (zero idle overhead)

---

## Recommendations

### Immediate Actions

1. **Fix PerformanceLogger._process()** (Highest Impact):
   - Disable `_process()` when `is_logging_enabled == false`
   - Or replace `_process()` with Timer-based file check

2. **Optimize PerformanceMonitor._process()** (Medium Impact):
   - Use `set_process()` to disable when `current_mode == Mode.OFF`
   - Also disable when overlay is hidden

3. **Consider pausing AzgaarServer timer** (Low Impact):
   - Pause timer when World Builder UI is closed
   - Resume when World Builder UI is opened

### Future Considerations

- When implementing `EntitySim` and `FactionEconomy` simulation:
  - Use `set_process()` to enable/disable based on scene context
  - Disable in UI-only scenes (MainMenu, WorldBuilderUI, CharacterCreation)
  - Enable only in game world scenes

- Add scene context awareness to singletons:
  - Create a `SceneContext` singleton that tracks current scene type (UI vs Game)
  - Allow singletons to pause/resume based on context

---

## Testing Recommendations

1. **Baseline Test:**
   - Open World Builder UI
   - Idle for 30 seconds
   - Capture FPS and Process Time from profiler

2. **After Fix #1 (PerformanceLogger):**
   - Disable `_process()` when logging disabled
   - Repeat baseline test
   - Compare FPS improvement

3. **After Fix #2 (PerformanceMonitor):**
   - Use `set_process()` to disable when OFF
   - Repeat baseline test
   - Compare FPS improvement

4. **After Fix #3 (AzgaarServer):**
   - Pause timer when UI closed
   - Repeat baseline test
   - Compare FPS improvement

---

## Conclusion

The audit identified **1 high-priority issue** (PerformanceLogger._process()) and **2 medium-priority optimizations** (PerformanceMonitor and AzgaarServer). The fixes are straightforward and should improve idle FPS in UI scenes.

**Estimated FPS Improvement:** 1-3 FPS (depending on hardware and current Process Time)

**Next Steps:**
1. Implement PerformanceLogger fix (disable `_process()` when disabled)
2. Test FPS improvement in World Builder UI
3. If still low FPS, implement PerformanceMonitor and AzgaarServer optimizations
4. Re-test and document results

---

**Audit completed:** 2025-12-26  
**Files analyzed:** 10 singletons + 1 instantiated scene (PerformanceMonitor)  
**Total lines reviewed:** ~2,500+ lines of GDScript

