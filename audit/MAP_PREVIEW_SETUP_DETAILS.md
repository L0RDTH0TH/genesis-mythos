# Map Preview Setup - Complete Implementation Details

This document provides comprehensive details about the map preview implementation to guide fixing the resize behavior where the preview should display different on-screen physical sizes based on world size selection.

---

## 1. Node Hierarchy for the Preview Area

### Scene Tree Structure

From `WorldBuilderUI.tscn`:

```
WorldBuilderUI (Control) - Full screen, anchors full rect
└── BackgroundPanel (Panel)
    └── MainContainer (HSplitContainer) - Horizontal split layout
        ├── LeftNav (Panel) - Left navigation panel (250px min width)
        └── RightSplit (HSplitContainer) - Right side split (60% split)
            ├── CenterPanel (Panel) ⭐ MAIN PREVIEW CONTAINER
            │   ├── Map2DTexture (TextureRect) ⭐ MAP PREVIEW TEXTURE
            │   │   - layout_mode = 1 (Anchors mode)
            │   │   - anchors_preset = 15 (PRESET_FULL_RECT) - fills parent
            │   │   - expand_mode = 1 (EXPAND_FIT_WIDTH) - scene default
            │   │   - stretch_mode = 5 (STRETCH_KEEP_ASPECT_CENTERED)
            │   │   - grow_horizontal = 2, grow_vertical = 2 (fill/expand flags)
            │   │
            │   └── [Initially displays ImageTexture from map_2d_viewport]
            │
            └── RightContent (PanelContainer) - Right sidebar (400px min width)

└── [Scene root also contains]
    └── map_2d_viewport (SubViewport) - Created at runtime in _ready()
        └── MapRoot (Node2D)
            ├── ParchmentBackground (Polygon2D) - Colored rectangle
            ├── ParchmentTexture (Sprite2D) - Optional texture overlay
            ├── GridContainer (Node2D) ⭐ GRID LINES CONTAINER
            │   ├── Line2D (horizontal lines, spaced every 100 units)
            │   └── Line2D (vertical lines, spaced every 100 units)
            └── CompassRose (Sprite2D) - Compass decoration
```

### Key Container Details

**CenterPanel (Panel):**
- `layout_mode = 2` (Container mode)
- `size_flags_horizontal = 3` (Fill + Expand)
- Has custom style: `StyleBoxFlat_center` with beige background (Color(0.25, 0.2, 0.15, 1))
- Borders: 2px width, golden color (Color(0.85, 0.7, 0.4, 1))

**Map2DTexture (TextureRect):**
- Anchored to fill entire CenterPanel (PRESET_FULL_RECT)
- Uses Anchors mode (not Container mode) despite parent using Container mode
- **CRITICAL:** Currently always fills parent container regardless of texture size
- Runtime override: Code sets `expand_mode = EXPAND_FIT_WIDTH_PROPORTIONAL` (value 3), conflicting with scene default (value 1)

**Grid Lines:**
- Implemented as `Line2D` nodes in `map_2d_viewport`'s Node2D hierarchy
- Created dynamically based on world size (lines every 100 units)
- Updated via `_update_map_grid()` when size changes (called deferred)
- Color: `Color(0.6, 0.5, 0.4, 0.3)` - light ink color, 30% opacity
- These are part of the 2D viewport, NOT the UI TextureRect

---

## 2. Current Code for Size Change and Preview Update

### Size Selection Handler

**File:** `ui/world_builder/WorldBuilderUI.gd`

**Function:** `_on_size_selected(index: int)` (line 1472)

```gdscript
func _on_size_selected(index: int) -> void:
	"""Handle size selection - update width/height and show placeholder immediately."""
	var size_dropdown: OptionButton = control_references.get("Seed & Size/size") as OptionButton
	if size_dropdown == null:
		return
	
	var size_name: String = size_dropdown.get_item_text(index)
	var size_map: Dictionary = {
		"Tiny": 512,
		"Small": 1024,
		"Medium": 2048,
		"Large": 4096,
		"Extra Large": 8192
	}
	var map_size: int = size_map.get(size_name, 1024)
	
	step_data["Seed & Size"]["size"] = size_name
	step_data["Seed & Size"]["width"] = map_size
	step_data["Seed & Size"]["height"] = map_size
	
	# Immediately show placeholder to fill new container bounds
	_update_map_preview_placeholder(map_size, map_size)
	
	call_deferred("_update_map_grid")  # Update grid lines in viewport
```

### Placeholder Update Function

**Function:** `_update_map_preview_placeholder(width: int, height: int)` (line 1649)

```gdscript
func _update_map_preview_placeholder(width: int, height: int) -> void:
	"""Update map preview with placeholder parchment image - fills container immediately on size change."""
	if map_2d_texture == null:
		return
	
	# Create placeholder image
	var placeholder_img: Image = create_placeholder_image(width, height)
	
	# Use bulletproof update method to ensure proper scaling
	map_preview_texture = ImageTexture.create_from_image(placeholder_img)
	
	# Step 1: Break old reference to force TextureRect to re-read size
	map_2d_texture.texture = null
	
	# Step 2: Assign new texture
	map_2d_texture.texture = map_preview_texture
	
	# Step 3: Force layout recalculation by resetting minimum size
	map_2d_texture.custom_minimum_size = Vector2.ZERO
	
	# Step 4: Set stretch mode explicitly (defensive)
	map_2d_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map_2d_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL  # ⚠️ EXPERIMENTAL MODE
	
	# Step 5: Force redraw and parent container update
	map_2d_texture.queue_redraw()
	var parent: Control = map_2d_texture.get_parent()
	if parent != null:
		parent.update_minimum_size()
	
	map_2d_texture.visible = true
```

### Actual Map Preview Update (After Generation)

**Function:** `_update_2d_map_preview(height_img: Image, biome_img: Image, width: int, height: int)` (line 1688)

Similar process to placeholder, but combines height and biome images before creating texture.

### Grid Update Function

**Function:** `_update_map_grid()` (line 450)

```gdscript
func _update_map_grid() -> void:
	"""Update map grid when world size changes."""
	if map_2d_viewport == null:
		return
	
	var map_root: Node2D = map_2d_viewport.get_node_or_null("MapRoot")
	if map_root == null:
		return
	
	# Remove old grid
	var old_grid: Node2D = map_root.get_node_or_null("GridContainer")
	if old_grid != null:
		old_grid.queue_free()
	
	# Create new grid with updated size
	_create_map_grid_in_parent(map_root)
```

**Grid Creation:** `_create_map_grid_in_parent(parent: Node2D)` (line 376)

- Creates horizontal and vertical `Line2D` nodes
- Grid spacing: 100 units
- Lines span from `-world_width/2` to `+world_width/2` (centered at origin)
- Grid color: `Color(0.6, 0.5, 0.4, 0.3)`

### Initialization

**Function:** `_ready()` and `_setup_2d_map_viewport()` (line 298)

- Creates `SubViewport` (map_2d_viewport) at runtime
- Initial size: 1920x1080 (fixed, not based on world size)
- Viewport is used for rendering 2D map layer with grid
- TextureRect initially displays viewport texture (later replaced with ImageTexture)

---

## 3. Current Problem Analysis

### What Currently Happens

1. **Container resizes correctly:** CenterPanel expands/contracts based on splitter position ✅
2. **Grid updates correctly:** Grid lines in viewport are recreated with new world dimensions ✅
3. **TextureRect behavior:** Always fills CenterPanel completely, regardless of texture size ❌
   - Tiny (512x512) map: Scaled up to fill entire container
   - Extra Large (8192x8192) map: Scaled down to fit container
   - Result: All sizes appear the same on-screen physical size

### Root Cause

The TextureRect is configured to **always fill its parent container**:

1. **Anchors:** `PRESET_FULL_RECT` (15) makes it fill parent
2. **Stretch mode:** `STRETCH_KEEP_ASPECT_CENTERED` scales texture to fit while maintaining aspect
3. **Expand mode:** `EXPAND_FIT_WIDTH_PROPORTIONAL` calculates minimum size but parent fills the container anyway
4. **Size flags:** `grow_horizontal = 2, grow_vertical = 2` means it expands to fill available space

This configuration **forces the preview to always fill the container**, which is why all world sizes appear the same physical size on screen.

---

## 4. Desired Visual Behavior (Inferred from Context)

Based on the investigation document and code analysis, the desired behavior appears to be:

### Expected Behavior for Different Sizes

**Option A: Native Pixel Size Display (Most Likely)**
- **Tiny (512x512):** Display as 512x512 pixels on screen (small square, centered, empty space around)
- **Small (1024x1024):** Display as 1024x1024 pixels on screen
- **Medium (2048x2048):** Display as 2048x2048 pixels (might exceed container, require scrolling)
- **Large (4096x4096):** Display as 4096x4096 pixels (definitely exceeds container, require scrolling/zooming)
- **Extra Large (8192x8192):** Display as 8192x8192 pixels (requires zoom/pan controls)

**Option B: Scaled but Proportionally Different Sizes**
- All sizes scaled to fit container, but with visible size differences
- Tiny takes 25% of container, Small 50%, Medium 75%, Large 100%, Extra Large with scrollbars
- Grid lines and borders scale proportionally with map

**Option C: Fixed Scale Factor**
- Use a fixed pixel-per-unit scale (e.g., 1 pixel = 1 world unit)
- Tiny = 512px, Small = 1024px, etc.
- When map exceeds container, add ScrollContainer

### Grid and Borders Behavior

- Grid lines should represent the **actual world bounds**
- For native pixel display: Grid should match map texture size exactly
- For scaled display: Grid should scale with map proportionally
- Borders (CenterPanel's StyleBoxFlat) could either:
  - Always fill container (current behavior)
  - Scale with map size (new behavior needed)

---

## 5. Custom Draw and Grid Implementation

### Grid Lines (Faint Grey Lines)

**Implementation:** `Line2D` nodes in 2D viewport hierarchy

**Location:** `_create_map_grid_in_parent()` (line 376)

```gdscript
func _create_map_grid_in_parent(parent: Node2D) -> void:
	"""Create grid lines for the 2D map in the specified parent."""
	var grid_container: Node2D = Node2D.new()
	grid_container.name = "GridContainer"
	parent.add_child(grid_container)
	
	var world_width: float = float(step_data.get("Seed & Size", {}).get("width", 1000))
	var world_height: float = float(step_data.get("Seed & Size", {}).get("height", 1000))
	
	var grid_spacing: float = 100.0
	var grid_color: Color = Color(0.6, 0.5, 0.4, 0.3)  # Light ink color
	
	# Horizontal lines
	for y in range(0, int(world_height) + 1, int(grid_spacing)):
		var line: Line2D = Line2D.new()
		line.add_point(Vector2(-world_width / 2, y - world_height / 2))
		line.add_point(Vector2(world_width / 2, y - world_height / 2))
		line.width = 1.0
		line.default_color = grid_color
		grid_container.add_child(line)
	
	# Vertical lines (similar for x-axis)
```

**Notes:**
- Grid is in **world space** (viewport coordinate system), NOT screen space
- Grid updates when world size changes (old grid deleted, new one created)
- Grid spacing is fixed at 100 units (not percentage-based)
- Grid is part of `map_2d_viewport`, but this viewport is currently not used for the preview texture (preview uses direct ImageTexture, not viewport texture)

**Issue:** The grid is in a viewport that's separate from the ImageTexture preview. If we want the grid to match the map preview, we have two options:
1. Render the viewport (which includes grid) to a texture and use that
2. Draw grid directly on the ImageTexture
3. Use a separate UI overlay that draws grid lines in screen space

---

## 6. Project Context

### Godot Version
- **Version:** 4.3.x (per project rules)
- **Format:** Godot 4.x scene format (`.tscn`)

### Current Architecture

**Preview Rendering Method:**
- Currently uses direct `ImageTexture` created from `Image` objects
- NOT using the `map_2d_viewport` texture for preview (viewport exists but texture is replaced)
- Placeholder uses `create_placeholder_image()` → `ImageTexture.create_from_image()`
- Generated map uses combined height/biome images → `ImageTexture.create_from_image()`

**Viewport Usage:**
- `map_2d_viewport` exists and contains grid/parchment background
- Initially, TextureRect displayed viewport texture
- Now replaced with direct ImageTexture (bypasses viewport rendering)
- Viewport grid is updated but not visible in current preview

### Known Issues from Investigation

1. **Expand Mode Conflict:** Scene file sets `expand_mode = 1`, code sets `expand_mode = 3` (experimental)
2. **Layout Timing:** Layout updates happen synchronously, may need deferred processing
3. **Container Mode Mismatch:** Parent uses Container mode, child uses Anchors mode
4. **Minimum Size Reset:** Setting `custom_minimum_size = Vector2.ZERO` may conflict with expand mode calculations

---

## 7. Recommended Solution Approaches

### Approach 1: Use STRETCH_KEEP (Native Pixel Size) ⭐ RECOMMENDED

**Goal:** Display texture at native pixel size, centered in container

**Changes Needed:**
1. Set `stretch_mode = TextureRect.STRETCH_KEEP` (no scaling)
2. Set `expand_mode = TextureRect.EXPAND_KEEP_SIZE` (use texture's native size)
3. Change anchors from FULL_RECT to CENTER preset
4. Optionally wrap in `ScrollContainer` for sizes that exceed container

**Pros:**
- Simple, native Godot behavior
- Different sizes actually look different on screen
- Easy to understand and maintain

**Cons:**
- Very large maps (8192px) may exceed screen, need scrolling
- Tiny maps (512px) will have lots of empty space

### Approach 2: Dynamic Scale Factor

**Goal:** Scale maps proportionally but maintain size differences

**Changes Needed:**
1. Calculate scale factor based on container size and map size
2. Set TextureRect size to `texture_size * scale_factor`
3. Use STRETCH_KEEP with calculated size
4. Center in container

**Pros:**
- All maps visible without scrolling
- Size differences still visible
- More controlled UX

**Cons:**
- Requires calculating scale factor
- May need min/max scale limits

### Approach 3: Use Viewport Texture (Render Grid + Map Together)

**Goal:** Display viewport texture which includes grid, scale appropriately

**Changes Needed:**
1. Update viewport size to match world size
2. Render map image as Sprite2D in viewport (instead of ImageTexture on TextureRect)
3. Use viewport texture in TextureRect
4. Adjust viewport camera/scale to control on-screen size

**Pros:**
- Grid and map are in same coordinate system
- Can use viewport camera for zoom/pan later
- More flexible rendering pipeline

**Cons:**
- More complex architecture
- Requires changing rendering pipeline
- Viewport rendering may have performance implications

---

## 8. Next Steps

To proceed with implementation, please clarify:

1. **Desired on-screen size behavior:**
   - [ ] Native pixel size (512px = 512px on screen)
   - [ ] Scaled proportionally (all sizes visible, but different scales)
   - [ ] Fixed scale factor (e.g., 0.25x for all sizes)

2. **Handling oversized maps:**
   - [ ] Add ScrollContainer for maps larger than container
   - [ ] Scale down to fit with max size limit
   - [ ] Add zoom/pan controls

3. **Grid display:**
   - [ ] Grid should match map texture size exactly
   - [ ] Grid should scale with map preview
   - [ ] Grid independent of map (always fills container)

4. **Border display:**
   - [ ] Borders (CenterPanel style) should scale with map
   - [ ] Borders always fill container (current behavior)

Once these decisions are made, I can provide a precise code patch to implement the fix.
