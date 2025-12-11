# CURRENT CODEBASE STATE – 2D-to-3D PARCHMENT MAP MAKER INTEGRATION

**Investigation Date:** 2025-01-06  
**Project:** Genesis Mythos (Godot 4.3)  
**Feature:** 2D Parchment Map Editor → Live 3D Terrain3D Generation

---

## EXECUTIVE SUMMARY

The codebase already contains **substantial infrastructure** for 2D map editing and 3D terrain generation. The integration path is **well-defined** but requires adding **parchment visual styling**, **enhanced brush tools**, and a **direct 2D→3D conversion pipeline**. Most core systems exist and can be extended rather than built from scratch.

---

## 1. WHAT ALREADY EXISTS (Reusable Components)

### ✅ **Terrain3D Plugin**
- **Status:** ✅ **FULLY INSTALLED AND ENABLED**
- **Location:** `res://addons/terrain_3d/`
- **Plugin Config:** Enabled in `project.godot` line 37
- **Capabilities:**
  - Heightmap import/export (EXR, PNG, R16)
  - Region-based terrain (up to 65km)
  - Biome texture blending (32 textures)
  - LOD system for performance
  - Sculpting tools (editor plugin)
- **Integration:** `Terrain3DManager.gd` already wraps Terrain3D with `generate_from_noise()` method

### ✅ **2D Map Editor System**
- **Status:** ✅ **FULLY IMPLEMENTED**
- **Core Files:**
  - `core/world_generation/MapEditor.gd` - Brush-based editing (raise/lower/smooth/river/mountain/crater/island)
  - `core/world_generation/MapRenderer.gd` - Shader-based rendering with hillshading/biomes
  - `core/world_generation/MapGenerator.gd` - Procedural generation using FastNoiseLite
  - `core/world_generation/WorldMapData.gd` - Resource class storing heightmap + parameters
  - `core/world_generation/MarkerManager.gd` - Icon/marker placement system
- **UI Integration:**
  - `ui/world_builder/MapMakerModule.gd` - Complete module with viewport, camera, toolbar, params panel
  - Integrated into `WorldBuilderUI.gd` as Step 2 ("2D Map Maker")
- **Features Already Working:**
  - ✅ Heightmap generation from noise
  - ✅ Brush painting (raise/lower/smooth/sharpen)
  - ✅ Preset tools (mountain/crater/island/river)
  - ✅ Undo/redo system (20-level history)
  - ✅ View modes (heightmap/biomes/political)
  - ✅ Camera pan/zoom
  - ✅ Parameter sliders (noise frequency, octaves, persistence, lacunarity, sea level)
  - ✅ Biome preview generation
  - ✅ Marker/icon placement system

### ✅ **Terrain3D Manager**
- **Status:** ✅ **IMPLEMENTED**
- **Location:** `core/world_generation/Terrain3DManager.gd`
- **Methods:**
  - `generate_from_noise(seed, frequency, min_height, max_height)` - Creates terrain from noise
  - `create_terrain()` - Instantiates Terrain3D node
  - `configure_terrain()` - Sets up regions, spacing, data directory
- **Integration:** Connected to `WorldBuilderUI` via `set_terrain_manager()`

### ✅ **World Map Data Structure**
- **Status:** ✅ **COMPLETE RESOURCE CLASS**
- **Location:** `core/world_generation/WorldMapData.gd`
- **Stores:**
  - Heightmap Image (FORMAT_RF or grayscale)
  - Noise parameters (type, frequency, octaves, persistence, lacunarity)
  - Erosion settings
  - Sea level
  - Rivers parameters
  - Biome parameters
  - Markers array
  - Undo history
- **Methods:**
  - `create_heightmap(size_x, size_y, format)`
  - `save_heightmap_to_history()` / `undo_heightmap()`
  - `get_elevation_at(position)` / `is_underwater(position)`
  - `add_marker()` / `remove_marker()` / `clear_markers()`

### ✅ **UI Theme System**
- **Status:** ✅ **THEME EXISTS**
- **Location:** `ui/theme/global_theme.tres`
- **Alternative:** `themes/bg3_theme.tres` (BG3-style theme)
- **Usage:** Applied to `WorldBuilderUI` in `world_root.gd` line 125-130
- **Note:** Parchment styling can be added as StyleBoxFlat or shader overlay

### ✅ **Main Scene Structure**
- **Status:** ✅ **ESTABLISHED**
- **Entry Point:** `scenes/MainMenu.tscn` (set as main scene in project.godot)
- **World Scene:** `core/scenes/world_root.tscn` (Node3D root with Terrain3DManager, Camera3D, DirectionalLight3D)
- **UI Overlay:** `WorldBuilderUI.tscn` loaded as CanvasLayer child in `world_root.gd`
- **Camera:** `creative_fly_camera.gd` (fly camera, not FPS CharacterBody3D)

### ✅ **Save/Load Infrastructure**
- **Status:** ✅ **PARTIALLY IMPLEMENTED**
- **Save Paths:**
  - `user://worlds/{name}.json` - World config (WorldBuilderUI line 2340)
  - `user://exports/{name}_heightmap.png` - Heightmap export (line 2368)
  - `user://exports/{name}_biomes.png` - Biome map export (line 2379)
- **Methods:** Uses `FileAccess` and `DirAccess.make_dir_recursive_absolute()`
- **Note:** ResourceSaver mentioned in docs but not actively used for map data

### ✅ **Shader System**
- **Status:** ✅ **EXISTS**
- **Map Renderer Shader:** `shaders/map_renderer.gdshader` - Hillshading, biome coloring, river overlays
- **Other Shaders:** `assets/shaders/topo_hologram_final.gdshader`, `hex_splat_compute.gdshader`
- **Note:** Parchment shader does NOT exist yet (mentioned in docs/2d map maker.txt but not implemented)

---

## 2. WHAT IS MISSING (Required for Full Feature)

### ❌ **Parchment Visual Styling**
- **Status:** ❌ **NOT IMPLEMENTED**
- **Missing Components:**
  - Parchment shader (`parchment.gdshader`) - CanvasItem shader for stained paper effect
  - Parchment texture assets (`res://assets/textures/parchment_*.png`)
  - Parchment overlay system (ColorRect with ShaderMaterial behind map canvas)
- **Reference:** Described in `docs/2d map maker.txt` lines 89-110
- **Required:** Create shader with curl edges, stain noise, yellowed paper effect

### ❌ **Direct 2D→3D Conversion Pipeline**
- **Status:** ❌ **NOT IMPLEMENTED**
- **Missing:** Button/action to convert 2D heightmap → Terrain3D import
- **Current State:** 
  - MapMakerModule generates heightmap in `WorldMapData`
  - Terrain3DManager can generate from noise OR import heightmap
  - **Gap:** No direct "Generate 3D Terrain" button that takes `WorldMapData.heightmap_image` → Terrain3D
- **Required:** 
  - Add `generate_terrain_from_heightmap(heightmap_image: Image)` method to Terrain3DManager
  - Add "Generate 3D Terrain" button in MapMakerModule toolbar
  - Connect button → export heightmap to EXR → import into Terrain3D → show in preview viewport

### ❌ **Enhanced Brush Tools for Parchment Drawing**
- **Status:** ⚠️ **PARTIAL**
- **Existing:** Basic brushes (raise/lower/smooth) work on heightmap
- **Missing:**
  - Ink brush mode (draws dark lines on parchment, converts to heightmap)
  - Eraser tool (removes drawn features)
  - Pressure sensitivity simulation (brush strength based on stroke speed)
  - Stylized drawing filters (wobbly lines, texture overlays)
- **Reference:** `docs/2d map maker.txt` mentions "hand-drawn aesthetics"

### ❌ **Fog of War System**
- **Status:** ❌ **NOT IMPLEMENTED**
- **Reference:** Mentioned in `docs/2d map maker.txt` line 130
- **Required:** Decal or CanvasModulate shader masking unexplored areas
- **Note:** This is for the 3D VTT view, not the 2D editor

### ❌ **Draggable Minis/Tokens**
- **Status:** ❌ **NOT IMPLEMENTED**
- **Reference:** Mentioned in `docs/2d map maker.txt` line 129
- **Required:** RigidBody3D models with raycast placement
- **Note:** This is for the 3D VTT view, not the 2D editor

### ❌ **FPS Character Controller**
- **Status:** ⚠️ **PARTIAL**
- **Current:** `creative_fly_camera.gd` (fly camera, not FPS)
- **Missing:** CharacterBody3D-based FPS controller with ground collision
- **Reference:** `docs/2d map maker.txt` lines 119-128
- **Note:** Optional for VTT exploration, not required for map editor

---

## 3. RECOMMENDED INTEGRATION PATH

### **Scene Hierarchy & File Locations**

#### **Option A: Extend Existing MapMakerModule (RECOMMENDED)**
- **Location:** `ui/world_builder/MapMakerModule.gd` (already exists)
- **Scene:** Integrated into `WorldBuilderUI.tscn` Step 2
- **Advantages:**
  - ✅ Already integrated into wizard flow
  - ✅ Viewport and camera already set up
  - ✅ Toolbar and params panel exist
  - ✅ Connected to WorldMapData
- **Modifications Needed:**
  1. Add parchment overlay (ColorRect + ShaderMaterial) behind map viewport
  2. Add "Generate 3D Terrain" button to toolbar
  3. Connect button → Terrain3DManager.generate_from_heightmap()
  4. Show Terrain3D preview in existing `Terrain3DView` SubViewportContainer

#### **Option B: Standalone ParchmentMapEditor Scene (ALTERNATIVE)**
- **Location:** `scenes/editor/ParchmentMapEditor.tscn` (NEW)
- **Script:** `scripts/editor/ParchmentMapEditor.gd` (NEW)
- **Advantages:**
  - ✅ Clean separation from WorldBuilderUI
  - ✅ Can be used standalone or embedded
- **Disadvantages:**
  - ❌ Duplicates existing MapMakerModule functionality
  - ❌ Requires new integration point

**RECOMMENDATION:** Use **Option A** (extend MapMakerModule) to avoid duplication.

---

## 4. EXACT CLASS NAMES & FILE STRUCTURE

### **New Files to Create:**

```
res://
├── assets/
│   └── textures/
│       ├── parchment_background.png          # NEW - Stained paper texture
│       ├── parchment_stain_01.png            # NEW - Optional stain overlays
│       └── parchment_stain_02.png            # NEW - Optional stain overlays
├── shaders/
│   └── parchment.gdshader                   # NEW - CanvasItem shader for parchment effect
└── core/
    └── world_generation/
        └── (no new files - extend existing)
```

### **Files to Modify:**

```
res://
├── ui/
│   └── world_builder/
│       ├── MapMakerModule.gd                 # MODIFY - Add parchment overlay + Generate 3D button
│       └── WorldBuilderUI.gd                  # MODIFY - Connect Generate button to Terrain3DManager
└── core/
    └── world_generation/
        └── Terrain3DManager.gd               # MODIFY - Add generate_from_heightmap() method
```

### **Class Names (Following PascalCase Convention):**

- ✅ **MapEditor** (already exists) - Brush tools
- ✅ **MapRenderer** (already exists) - Shader rendering
- ✅ **MapGenerator** (already exists) - Procedural generation
- ✅ **MapMakerModule** (already exists) - Main UI module
- ✅ **Terrain3DManager** (already exists) - Terrain management
- ✅ **WorldMapData** (already exists) - Data resource
- 🆕 **ParchmentShader** (optional) - If we create a separate shader class wrapper

**Note:** No new major classes needed. Extend existing ones.

---

## 5. INTEGRATION WORKFLOW

### **Step 1: Add Parchment Visual Styling**
1. Download/import parchment textures → `res://assets/textures/`
2. Create `shaders/parchment.gdshader` (CanvasItem shader)
3. In `MapMakerModule._setup_ui()`:
   - Add ColorRect behind map_viewport_container
   - Apply ShaderMaterial with parchment shader
   - Load parchment texture as uniform

### **Step 2: Add Generate 3D Terrain Button**
1. In `MapMakerModule._create_toolbar()`:
   - Add "Generate 3D Terrain" button after "Regenerate"
2. Connect button → `_on_generate_3d_terrain_pressed()`
3. In handler:
   - Export `world_map_data.heightmap_image` to EXR format
   - Call `Terrain3DManager.generate_from_heightmap(exr_path)`
   - Show Terrain3D preview in `Terrain3DView` SubViewportContainer

### **Step 3: Extend Terrain3DManager**
1. Add method: `generate_from_heightmap(heightmap_image: Image, min_height: float, max_height: float)`
2. Convert Image to EXR format (or use Terrain3D's import_images directly)
3. Call `terrain.data.import_images([heightmap_image, null, null], position, min_height, max_height)`
4. Call `terrain.update_maps()`

### **Step 4: Connect Preview Viewport**
1. In `WorldBuilderUI`:
   - Ensure `Terrain3DView` SubViewportContainer is visible when Step 3 (Terrain) is active
   - Add Terrain3D node to `PreviewWorld` Node3D
   - Connect camera controls for preview rotation

---

## 6. TECHNICAL CONSIDERATIONS

### **Heightmap Format Compatibility**
- **Current:** `WorldMapData.heightmap_image` uses `Image.FORMAT_RF` (float format)
- **Terrain3D:** Accepts EXR, PNG, R16 formats
- **Solution:** Use `Image.save_exr()` or convert to R16 format before import
- **Note:** Terrain3D's `import_images()` accepts Image directly, so conversion may not be needed

### **Coordinate System Mapping**
- **2D Map:** World coordinates centered at (0,0), image coordinates (0,0) to (width, height)
- **3D Terrain:** Terrain3D uses world-space positions
- **Solution:** MapMakerModule already handles conversion in `_screen_to_world_position()`
- **Terrain Position:** Set Terrain3D position to `Vector3(-world_width/2, 0, -world_height/2)` to center

### **Performance Considerations**
- **2D Editor:** 1024x1024 or 2048x2048 heightmap is reasonable
- **3D Terrain:** Terrain3D LOD handles large terrains automatically
- **Preview:** Use lower resolution (512x512) for preview, full resolution for final generation
- **Threading:** MapGenerator already supports threaded generation (not currently used in MapMakerModule)

### **Save/Load Integration**
- **Current:** WorldBuilderUI saves to `user://worlds/{name}.json`
- **Enhancement:** Also save heightmap EXR alongside JSON
- **Load:** Add "Load Map" button that restores heightmap_image from EXR

---

## 7. DEPENDENCIES & PREREQUISITES

### **Required Assets:**
- ✅ Terrain3D plugin (INSTALLED)
- ❌ Parchment textures (NEED TO DOWNLOAD/IMPORT)
  - Reference: `docs/2d map maker.txt` mentions itch.io sources
  - Suggested: `res://assets/textures/parchment_background.png`

### **Required Shaders:**
- ✅ Map renderer shader (EXISTS: `shaders/map_renderer.gdshader`)
- ❌ Parchment shader (NEED TO CREATE: `shaders/parchment.gdshader`)

### **Optional Enhancements:**
- Fog of War (for 3D VTT view)
- Draggable minis/tokens (for 3D VTT view)
- FPS CharacterBody3D controller (for exploration)

---

## 8. INTEGRATION CHECKLIST

### **Phase 1: Visual Styling (Parchment Effect)**
- [ ] Download/import parchment texture assets
- [ ] Create `shaders/parchment.gdshader`
- [ ] Add parchment overlay ColorRect to MapMakerModule
- [ ] Test parchment shader with map canvas

### **Phase 2: 2D→3D Conversion**
- [ ] Add `generate_from_heightmap()` method to Terrain3DManager
- [ ] Add "Generate 3D Terrain" button to MapMakerModule toolbar
- [ ] Connect button → export heightmap → import to Terrain3D
- [ ] Show Terrain3D preview in Terrain3DView SubViewportContainer

### **Phase 3: Enhanced Drawing Tools (Optional)**
- [ ] Add ink brush mode (draws on parchment, converts to heightmap)
- [ ] Add eraser tool
- [ ] Add pressure sensitivity simulation
- [ ] Add stylized drawing filters

### **Phase 4: VTT Features (Future)**
- [ ] Fog of War system
- [ ] Draggable minis/tokens
- [ ] FPS CharacterBody3D controller
- [ ] Grid snapping system

---

## 9. CONCLUSION

**Integration Feasibility:** ✅ **HIGHLY FEASIBLE**

The codebase already contains **~80% of required infrastructure**:
- ✅ Terrain3D plugin installed
- ✅ 2D map editor fully functional
- ✅ Terrain3DManager exists
- ✅ WorldMapData resource complete
- ✅ UI integration in place

**Remaining Work:**
1. **Parchment visual styling** (~2-3 hours)
2. **2D→3D conversion pipeline** (~1-2 hours)
3. **Enhanced brush tools** (optional, ~3-4 hours)
4. **VTT features** (future, ~8-10 hours)

**Recommended Approach:**
1. Start with **Phase 1** (parchment styling) for visual polish
2. Implement **Phase 2** (2D→3D conversion) for core functionality
3. Add **Phase 3** (enhanced tools) if time permits
4. Defer **Phase 4** (VTT features) to future iteration

**File Locations:**
- Extend existing `ui/world_builder/MapMakerModule.gd`
- Extend existing `core/world_generation/Terrain3DManager.gd`
- Create new `shaders/parchment.gdshader`
- Import assets to `res://assets/textures/`

**No new major classes needed** - extend existing infrastructure.

---

**END OF REPORT**
