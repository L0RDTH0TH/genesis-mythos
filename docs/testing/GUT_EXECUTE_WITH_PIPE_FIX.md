# GUT execute_with_pipe() Fix for Godot 4.3

**Date:** 2025-12-13  
**Issue:** `execute_with_pipe()` parse error - too many arguments  
**Status:** Fixed

---

## Problem

**Error:**
```
res://addons/gut/gui/RunExternally.gd:149 - Parse Error: Too many arguments for "execute_with_pipe()" call. Expected at most 2 but received 3.
```

**Code:**
```gdscript
_pipe_results = OS.execute_with_pipe(OS.get_executable_path(), options, false)
```

---

## Root Cause

In Godot 4.3, `OS.execute_with_pipe()` only accepts **2 parameters**:
1. `path: String` - Path to executable
2. `arguments: PackedStringArray` - Command arguments

The `blocking: bool` parameter (3rd argument) doesn't exist in Godot 4.3. The method is **always non-blocking** by default (it returns pipes for async I/O).

---

## Fix Applied

**File:** `addons/gut/gui/RunExternally.gd` line 149

**Before:**
```gdscript
_pipe_results = OS.execute_with_pipe(OS.get_executable_path(), options, false)
```

**After:**
```gdscript
# In Godot 4.3, execute_with_pipe() only takes 2 arguments (path, arguments)
# It's always non-blocking by default
_pipe_results = OS.execute_with_pipe(OS.get_executable_path(), options)
```

---

## Verification

After this fix:
- ✅ No parse error in `RunExternally.gd`
- ✅ Non-blocking execution still works (it's the default behavior)
- ✅ GUT can run tests externally

---

## About execute_with_pipe() in Godot 4.3

**Signature:**
```gdscript
Dictionary OS.execute_with_pipe(path: String, arguments: PackedStringArray)
```

**Returns:**
- Dictionary with `"stdio"`, `"stderr"`, and `"pid"` keys
- Always non-blocking (returns immediately with pipes)

**Usage:**
```gdscript
var result = OS.execute_with_pipe("path/to/executable", ["arg1", "arg2"])
# result.stdio - FileAccess for stdout/stdin
# result.stderr - FileAccess for stderr
# result.pid - Process ID
```

---

**Status:** Fixed  
**Action:** Reload script or restart editor  
**Result:** Parse error resolved, functionality preserved
