# Change 7: Add SVG Saving

**Date:** 2026-01-01  
**File:** `scripts/ui/WorldBuilderWebController.gd`  
**Location:** `_handle_svg_preview` function, after receiving SVG data

## What Was Changed

Added code to save the SVG preview to a file for debugging/analysis purposes.

### Before

```gdscript
	if svg_data.is_empty():
		MythosLogger.warn("WorldBuilderWebController", "SVG preview data is empty")
		return
	
	MythosLogger.info("WorldBuilderWebController", "SVG preview received", {
		"svg_length": svg_data.length(),
		"width": width,
		"height": height
	})
```

### After

```gdscript
	if svg_data.is_empty():
		MythosLogger.warn("WorldBuilderWebController", "SVG preview data is empty")
		return
	
	MythosLogger.info("WorldBuilderWebController", "SVG preview received", {
		"svg_length": svg_data.length(),
		"width": width,
		"height": height
	})
	
	# Save SVG to file for debugging/analysis
	var debug_dir := DirAccess.open("user://")
	if debug_dir and not debug_dir.dir_exists("debug"):
		debug_dir.make_dir("debug")
	
	var svg_path: String = "user://debug/azgaar_sample_svg.svg"
	var svg_file := FileAccess.open(svg_path, FileAccess.WRITE)
	if svg_file:
		svg_file.store_string(svg_data)
		svg_file.close()
		MythosLogger.info("SVG Saved", svg_path)
	else:
		MythosLogger.error("WorldBuilderWebController", "Failed to save SVG file", {
			"path": svg_path,
			"error": FileAccess.get_open_error()
		})
```

## Why (Reference to Investigation)

The investigation audit recommended saving SVG files to disk for layer-by-layer verification. This allows:
1. Manual inspection of SVG structure to verify which layers (biomes, states, rivers, borders) are present
2. Comparison of before/after SVG files to measure rendering improvement
3. Debugging of rendering issues by examining the actual SVG output

The SVG is saved to `user://debug/azgaar_sample_svg.svg`, same directory as the JSON file, making it easy to correlate JSON data with rendered output.

## Expected Impact

- **Positive:** Enables manual inspection of SVG output for debugging
- **Positive:** Allows before/after comparison to measure fix effectiveness
- **Positive:** Non-invasive - only saves data, doesn't change rendering behavior
- **Risk:** Very low - defensive programming with error handling, minimal performance impact
