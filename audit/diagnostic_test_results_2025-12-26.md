# Singleton Diagnostic Test Results
**Date:** 2025-12-26  
**Purpose:** Confirm which singletons cause low FPS (3-7 FPS) in World Builder UI  
**Method:** Disable per-frame/timed logic one-by-one and measure FPS deltas

---

## Current Configuration Status

### PerformanceLogger
- **Config:** `res://data/config/logging_config.json`
- **is_logging_enabled:** `true` (line 41: `"enabled": true`)
- **Has `_process()`:** YES (runs every frame)
- **Status:** DISABLED FOR TESTING

### FlameGraphProfiler
- **Config:** `res://data/config/flame_graph_config.json`
- **is_profiling_enabled:** `false` (line 2: `"enabled": false`)
- **Has Timers:** NO (disabled by config)
- **Status:** FORCE-DISABLED FOR TESTING (regardless of config)

### PerformanceMonitor
- **Status:** Instantiated globally via PerformanceMonitorSingleton
- **Has `_process()`:** YES (with early return guard)
- **Status:** INSTANTIATION DISABLED FOR TESTING

### AzgaarServer
- **Has Timer:** YES (100ms polling interval)
- **Status:** TIMER DISABLED FOR TESTING

---

## Test Modifications Applied

### 1. PerformanceLogger.gd
**File:** `res://core/singletons/PerformanceLogger.gd`

**Changes:**
- Added `set_process(false)` in `_ready()` to disable `_process()` entirely
- Added `return` at top of `_process()` as backup (should never execute)

**Code:**
```gdscript
# In _ready():
set_process(false)
MythosLogger.info("PerformanceLogger", "DIAGNOSTIC: _process() disabled for FPS testing")

# In _process():
return  # DIAGNOSTIC TEST: Disabled entirely - return immediately
```

---

### 2. PerformanceMonitorSingleton.gd
**File:** `res://core/singletons/PerformanceMonitorSingleton.gd`

**Changes:**
- Added early `return` in `_ready()` to prevent instantiation of PerformanceMonitor scene
- This completely disables the PerformanceMonitor overlay and its `_process()` method

**Code:**
```gdscript
# In _ready():
# DIAGNOSTIC TEST: Prevent instantiation entirely
MythosLogger.info("PerformanceMonitorSingleton", "DIAGNOSTIC: PerformanceMonitor instantiation disabled for FPS testing")
return
```

---

### 3. AzgaarServer.gd
**File:** `res://scripts/managers/AzgaarServer.gd`

**Changes:**
- Commented out `polling_timer.start()` to disable HTTP server polling
- Timer still created but never fires

**Code:**
```gdscript
# DIAGNOSTIC TEST: Disable timer polling
# polling_timer.start()
MythosLogger.info("AzgaarServer", "DIAGNOSTIC: Polling timer disabled for FPS testing")
```

**Note:** This will break Azgaar WebView integration (server won't respond to requests), but allows us to measure FPS impact.

---

### 4. FlameGraphProfiler.gd
**File:** `res://core/singletons/FlameGraphProfiler.gd`

**Changes:**
- Force-set `is_profiling_enabled = false` in `_ready()` regardless of config
- Prevents any Timers from being created

**Code:**
```gdscript
# DIAGNOSTIC TEST: Force disable profiling regardless of config
is_profiling_enabled = false
MythosLogger.info("FlameGraphProfiler", "DIAGNOSTIC: Flame graph profiling force-disabled for FPS testing")
```

---

## Test Procedure

### Baseline Test (ALL DISABLED)
**Status:** READY TO TEST

**Steps:**
1. Run project: `run_project`
2. Navigate to World Builder UI (from Main Menu)
3. Stay on first tab (Step 0: World Size)
4. **Idle for 30 seconds** - no inputs, no mouse movement
5. Observe FPS from profiler or on-screen display
6. Record average FPS and Process Time

**Expected Result:**
- If FPS jumps to 60 FPS: One or more of these singletons was the culprit
- If FPS remains low (3-7 FPS): Issue is elsewhere (UI rendering, WebView, etc.)

---

## Individual Test Results

### Test A: PerformanceLogger Disabled
**Status:** PENDING  
**FPS Before:** [TO BE MEASURED]  
**FPS After:** [TO BE MEASURED]  
**Delta:** [TO BE CALCULATED]  
**Impact:** [TO BE DETERMINED]

---

### Test B: PerformanceMonitor Disabled
**Status:** PENDING  
**FPS Before:** [TO BE MEASURED]  
**FPS After:** [TO BE MEASURED]  
**Delta:** [TO BE CALCULATED]  
**Impact:** [TO BE DETERMINED]  
**Note:** Check if RenderingServer calls were active (high impact if yes)

---

### Test C: AzgaarServer Timer Disabled
**Status:** PENDING  
**FPS Before:** [TO BE MEASURED]  
**FPS After:** [TO BE MEASURED]  
**Delta:** [TO BE CALCULATED]  
**Impact:** [TO BE DETERMINED]  
**Note:** WebView will not work (server not polling), but FPS impact can be measured

---

### Test D: FlameGraphProfiler Disabled
**Status:** PENDING  
**FPS Before:** [TO BE MEASURED]  
**FPS After:** [TO BE MEASURED]  
**Delta:** [TO BE CALCULATED]  
**Impact:** [TO BE DETERMINED]  
**Note:** Already disabled by config, but force-disabled for testing

---

## Combined Test (ALL DISABLED)

**Current Status:** ALL FOUR DISABLED SIMULTANEOUSLY

**Test Steps:**
1. Run project with all modifications active
2. Navigate to World Builder UI
3. Idle on first tab for 30 seconds
4. Record FPS and Process Time

**Expected:**
- If FPS jumps significantly: One or more singletons were the primary cause
- If FPS remains low: Issue is in UI rendering, WebView, or other systems

---

## Reversion Instructions

All changes are reversible via backups:

```bash
cd /home/darth/Final-Approach
cp core/singletons/PerformanceLogger.gd.backup core/singletons/PerformanceLogger.gd
cp core/singletons/PerformanceMonitorSingleton.gd.backup core/singletons/PerformanceMonitorSingleton.gd
cp scripts/ui/overlays/PerformanceMonitor.gd.backup scripts/ui/overlays/PerformanceMonitor.gd
cp scripts/managers/AzgaarServer.gd.backup scripts/managers/AzgaarServer.gd
cp core/singletons/FlameGraphProfiler.gd.backup core/singletons/FlameGraphProfiler.gd
```

**Backup files created:**
- `core/singletons/PerformanceLogger.gd.backup`
- `core/singletons/PerformanceMonitorSingleton.gd.backup`
- `scripts/ui/overlays/PerformanceMonitor.gd.backup`
- `scripts/managers/AzgaarServer.gd.backup`
- `core/singletons/FlameGraphProfiler.gd.backup`

---

## Next Steps

1. **Run baseline test** with all four disabled
2. **Record FPS** from profiler or on-screen display
3. **If FPS improves:** Re-enable one-by-one to identify culprit
4. **If FPS remains low:** Issue is elsewhere (UI, WebView, rendering)
5. **Revert all changes** after testing complete

---

**Test Status:** READY - All modifications applied, ready for baseline test  
**Backup Status:** COMPLETE - All files backed up  
**Revert Status:** READY - Reversion commands documented above
