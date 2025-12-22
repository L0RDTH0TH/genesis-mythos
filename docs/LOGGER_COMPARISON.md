# Godot Native Logger vs Custom Logger Comparison

## Overview

This document compares Godot's native logging capabilities with the custom Logger singleton (`core/singletons/Logger.gd`) implemented in Genesis Mythos.

---

## Godot Native Logger

### Available Functions

```gdscript
# Standard output functions
print(...)              # Basic console output
print_rich(...)         # Rich text formatting (BBCode support)
prints(...)             # Print with separator between arguments
printerr(...)           # Print to stderr

# Error/Warning handling
push_error(message)     # Log an error (visible in editor Output panel)
push_warning(message)   # Log a warning (visible in editor Output panel)

# OS-level functions
OS.print_verbose(...)   # Only if verbose mode enabled
OS.print_debug(...)     # Only in debug builds
```

### Characteristics

**✅ Strengths:**
- Built into engine - zero overhead
- Immediate availability - no initialization needed
- Standard GDScript functions - everyone knows them
- Editor integration - errors/warnings appear in Output panel with clickable links
- `push_error()` and `push_warning()` integrate with Godot's error tracking
- Works immediately at any point in code execution

**❌ Limitations:**
- **No file logging** - Output only goes to console/editor
- **No log levels** - Only basic print vs error vs warning distinction
- **No filtering** - Cannot filter by module/system/category
- **No configuration** - Cannot adjust verbosity without code changes
- **No structured data** - Cannot easily attach metadata/context
- **No timestamps** - Must manually add if needed
- **No persistence** - Logs lost when editor/game closes
- **No UI integration** - Cannot build in-game log viewers
- **No thread safety** - Basic operations, but no coordination mechanism

---

## Custom Logger (`core/singletons/Logger.gd`)

### Available Functions

```gdscript
# Convenience methods (system-first API)
Logger.error(system, message, data)
Logger.warn(system, message, data)
Logger.info(system, message, data)
Logger.debug(system, message, data)
Logger.verbose(system, message, data)

# Core method
Logger.log_entry(system, level, message, data)

# Runtime configuration (dev_mode only)
Logger.set_system_level(system, "DEBUG")
Logger.get_system_level(system)
Logger.reload_config()
```

### Characteristics

**✅ Strengths:**

1. **Per-System Log Levels**
   - Configure different verbosity per system (Combat, UI, AI, etc.)
   - Example: `"Networking": "WARN"` while `"Combat": "DEBUG"`
   - Runtime adjustment in dev mode

2. **JSON Configuration** (`res://config/logging_config.json`)
   - Change logging behavior without code changes
   - Adjust levels per environment (dev vs production)
   - Reload config at runtime

3. **File Logging**
   - Automatic log files in `user://logs/`
   - Daily rotation (one file per day)
   - Persistent logs across sessions
   - Dev mode also writes to absolute path for easy access

4. **Structured Data Support**
   - Attach dictionaries/arrays as metadata
   - JSON serialization for complex data
   - Perfect for debugging state transitions, user actions, etc.

5. **Rich Formatting**
   - Consistent timestamp format: `[YYYY-MM-DD HH:MM:SS]`
   - System labels: `[System]`
   - Level labels: `[ERROR]`, `[WARN]`, `[INFO]`, `[DEBUG]`, `[VERBOSE]`
   - Example: `[2025-01-15 14:32:10] [Combat] [INFO]: Player attacked Goblin`

6. **Signal Integration**
   - `log_entry_created` signal for UI integration
   - Can build in-game log viewers
   - Real-time log streaming to UI elements

7. **Thread Safety**
   - Mutex protection for multi-threaded scenarios
   - Safe for future async operations

8. **Development Features**
   - Dev mode for runtime level changes
   - Dual logging (user:// and absolute path)
   - Session headers/footers in log files

**❌ Limitations:**

1. **Requires Initialization**
   - Must be autoload singleton
   - Not available before `_ready()` in some edge cases
   - Adds ~400 lines of code

2. **Performance Overhead**
   - String formatting and file I/O
   - Level checking on every call
   - Mutex locking (minimal, but exists)

3. **Still Uses Native Functions**
   - Internally calls `push_error()`, `push_warning()`, `print()`
   - Not a replacement, but a wrapper/enhancement

---

## Detailed Feature Comparison

| Feature | Godot Native | Custom Logger |
|---------|-------------|---------------|
| **Console Output** | ✅ Yes | ✅ Yes (wraps native) |
| **Editor Integration** | ✅ Yes | ✅ Partial (uses push_error/warning) |
| **File Logging** | ❌ No | ✅ Yes |
| **Log Levels** | ❌ Basic (error/warn/print) | ✅ 5 levels (ERROR/WARN/INFO/DEBUG/VERBOSE) |
| **Per-System Filtering** | ❌ No | ✅ Yes |
| **JSON Configuration** | ❌ No | ✅ Yes |
| **Structured Data** | ❌ No | ✅ Yes (Dictionary/Array support) |
| **Timestamps** | ❌ Manual | ✅ Automatic, configurable |
| **Thread Safety** | ⚠️ Basic | ✅ Mutex-protected |
| **UI Signals** | ❌ No | ✅ Yes (`log_entry_created`) |
| **Runtime Configuration** | ❌ No | ✅ Yes (dev_mode) |
| **Performance** | ✅ Zero overhead | ⚠️ Minimal overhead |
| **Setup Complexity** | ✅ None | ⚠️ Autoload + config |
| **Persistence** | ❌ No | ✅ Yes |

---

## Usage Examples

### Godot Native Logger

```gdscript
# Simple debug output
print("Player health: ", player.health)

# Error reporting
if not file_exists(path):
    push_error("File not found: " + path)

# Warning
if invalid_config:
    push_warning("Using default configuration")

# Verbose mode (only in debug builds)
OS.print_debug("Detailed debug info: ", some_data)
```

**Output:**
```
Player health: 100
ERROR: File not found: res://data/config.json
WARNING: Using default configuration
```

### Custom Logger

```gdscript
# System-based logging with levels
Logger.info("Combat", "Player health: %d" % player.health)

# Error with system context
if not file_exists(path):
    Logger.error("DataLoader", "File not found", {"path": path})

# Warning with metadata
if invalid_config:
    Logger.warn("Config", "Using defaults", {"missing_keys": missing_keys})

# Debug with structured data
Logger.debug("Combat", "Attack calculation", {
    "attacker": player.name,
    "target": enemy.name,
    "damage": calculated_damage,
    "rolls": dice_results
})
```

**Output (Console):**
```
[2025-01-15 14:32:10] [Combat] [INFO]: Player health: 100
[2025-01-15 14:32:11] [DataLoader] [ERROR]: File not found [{"path":"res://data/config.json"}]
[2025-01-15 14:32:12] [Config] [WARN]: Using defaults [{"missing_keys":["api_key","port"]}]
[2025-01-15 14:32:13] [Combat] [DEBUG]: Attack calculation [{"attacker":"Hero","target":"Goblin","damage":15,"rolls":[4,5,6]}]
```

**Output (Log File):**
Same formatted output, persisted to `user://logs/mythos_log_2025-01-15.txt`

---

## When to Use Each

### Use Godot Native Logger When:
- ✅ Quick debugging during development (`print()`)
- ✅ Critical errors that must always appear (`push_error()`)
- ✅ Simple one-off warnings (`push_warning()`)
- ✅ You need immediate output before Logger initializes
- ✅ Testing in isolation (small scripts)

### Use Custom Logger When:
- ✅ Production logging that needs persistence
- ✅ Different verbosity per system/module
- ✅ Need structured data/metadata in logs
- ✅ Want to build in-game log viewers
- ✅ Need log analysis or debugging from saved files
- ✅ Configuration-driven logging (dev vs production)
- ✅ Multi-threaded operations requiring thread-safe logging

---

## Configuration Example

### `res://config/logging_config.json`

```json
{
    "global_default_level": "INFO",
    "systems": {
        "Combat": "DEBUG",
        "UI": "INFO",
        "AI": "WARN",
        "Inventory": "INFO",
        "Networking": "WARN",
        "Logger": "VERBOSE"
    },
    "dev_mode": true,
    "log_to_console": true,
    "log_to_file": true,
    "log_dir": "user://logs/",
    "log_file_prefix": "mythos_log_",
    "timestamp_format": "%Y-%m-%d %H:%M:%S"
}
```

**Effect:**
- Global default: INFO level
- Combat system: Very verbose (DEBUG)
- AI system: Only warnings and errors
- Networking: Only warnings and errors
- Logger system: Maximum verbosity (VERBOSE) for debugging the logger itself

---

## Best Practices

### Hybrid Approach (Recommended)

Use **both** strategically:

1. **Quick Debugging:** Use native `print()` for rapid iteration
2. **Structured Logging:** Use Custom Logger for production code
3. **Critical Errors:** Both `push_error()` (for editor) and `Logger.error()` (for file)

```gdscript
func load_config() -> bool:
    # Quick debug
    print("Loading config...")
    
    # Structured logging
    Logger.info("ConfigLoader", "Starting config load", {"path": config_path})
    
    if not file_exists(config_path):
        # Editor integration + file logging
        push_error("Config file missing: " + config_path)
        Logger.error("ConfigLoader", "Config file missing", {"path": config_path})
        return false
    
    # Success logging with metadata
    Logger.info("ConfigLoader", "Config loaded successfully", {
        "entries": config.size(),
        "version": config.get("version", "unknown")
    })
    
    return true
```

### Migration Strategy

When converting code to use Custom Logger:

1. Replace `print()` → `Logger.info(system, message)`
2. Replace `push_error()` → `Logger.error(system, message)`
3. Replace `push_warning()` → `Logger.warn(system, message)`
4. Add system names for better filtering
5. Add structured data where useful

---

## Performance Considerations

### Custom Logger Overhead

- **Level Check:** ~0.001ms per call (dictionary lookup)
- **String Formatting:** ~0.01-0.1ms depending on data complexity
- **File I/O:** ~1-5ms (async in future versions)
- **Mutex Lock:** Negligible for single-threaded

**Total:** ~1-5ms per log entry (mostly file I/O)

### Recommendations

- Use appropriate log levels (DEBUG/VERBOSE in development only)
- Disable file logging in performance-critical builds if needed
- Use structured data sparingly for high-frequency logs
- Consider async file writing for future optimization

---

## Conclusion

**Godot Native Logger:**
- Perfect for quick debugging and editor integration
- Zero overhead, always available
- Limited features but simple

**Custom Logger:**
- Essential for production logging and debugging
- Rich features, configurable, persistent
- Minimal overhead, excellent for structured development

**Recommendation:** Use both! Native for quick iteration, Custom Logger for all production code and structured debugging.

---

*Last Updated: 2025-01-15*
*Logger Implementation: `core/singletons/Logger.gd`*
*Config Location: `res://config/logging_config.json`*










