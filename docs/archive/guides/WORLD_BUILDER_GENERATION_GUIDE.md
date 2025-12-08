### Detailed Godot Prototyping Guide: D&D 5e World Builder Tool

This guide walks you through prototyping the specified D&D 5e world builder in Godot 4.x (assuming 4.3+ as of Dec 2025, with features like improved FastNoiseLite and editor plugins). The goal is a functional MVP: a single-window editor tool for procedural world generation, with UI sections, real-time 3D preview, basic D&D hooks, and exports. We'll prioritize core features for quick iteration, using Godot's built-in tools (no external addons unless noted).

Focus on GDScript for simplicity, but you can swap to C# if preferred. Prototype in Godot's editor—run as a tool script where possible for live testing.

#### 1. Project Setup
- **Download Godot:** Get Godot 4.3+ from godotengine.org. Use the standard edition (Mono if you want C#).
- **Create New Project:** Name it "WorldBuilderPrototype". Set rendering to Forward+ (for 3D performance) in Project Settings > Rendering > Renderer.
- **Enable Tool Mode:** Many scripts will use `@tool` annotation to run in the editor.
- **Key Settings:**
  - Project Settings > Display > Window: Set "Stretch Mode" to "canvas_items" and "Aspect" to "keep" for responsive UI.
  - Input > Devices: Enable "Use Accumulated Input" for smooth sliders.
  - Editor Settings > Interface: Dark theme to match "dark fantasy" aesthetic.
- **Dependencies:** No installs needed—use built-in FastNoiseLite for procedural gen, Control nodes for UI.
- **Aesthetic Setup:** Create a custom Theme (Project > Tools > Create New Theme). Use dark grays/blues for backgrounds, glowing cyan accents for sliders (via StyleBoxFlat with glow shaders). Add subtle particle effects via GPUParticles2D in UI (e.g., faint runes floating on sections).

#### 2. Folder Structure
Organize for modularity. This matches the spec's folder-package persistence.

```
WorldBuilderPrototype/
├── addons/                # For optional plugins (e.g., Terrain3D if you expand later)
├── assets/                # Textures, shaders, presets
│   ├── materials/         # Shaders for topo map (blue height, lines/nodes)
│   ├── presets/           # JSON files for genre packs (e.g., high_fantasy.json)
│   └── ui/                # Parchment textures, rune icons
├── scripts/               # Core logic
│   ├── generation/        # Procedural scripts (terrain_gen.gd, biome_gen.gd)
│   ├── ui/                # Section scripts (terrain_section.gd)
│   ├── utils/             # Helpers (noise_utils.gd, export_utils.gd)
│   └── world.gd           # Main world data class (seed, params, metadata)
├── scenes/                # TSCN files
│   ├── main.tscn          # Root scene: UI + Preview
│   ├── sections/          # Instanced sections (terrain_section.tscn)
│   └── preview/           # 3D viewport subscene
├── exports/               # Runtime output folder (PDFs, scenes)
└── project.godot          # Project file
```

For persistence: Save world as a folder (e.g., "MyWorld/") with `data.gworld` (binary via ResourceSaver), `data.json` (human-readable via JSON.parse), assets/, and previews/.

#### 3. Main Scene Setup (UI + Preview)
- **Create main.tscn:** Root = Control (full rect anchor for single-window).
  - Add VBoxContainer (root child) for vertical layout: Top toolbar + Scrolling sections + Bottom status.
  - Add SubViewport (side panel) for 3D preview (dock right, 40% width).
- **Toolbar:** HBoxContainer with buttons: New Project (size slider popup), Load/Save, Generate, Export, Presets dropdown.
- **Scrolling Page:** ScrollContainer > VBoxContainer. Instance section scenes here (logical order: Terrain → Climate → etc.).
- **Preview Panel:** SubViewport > ViewportTexture displayed in TextureRect. Inside: Camera3D (ortho) + MeshInstance3D for world mesh.
- **Script main.gd (@tool):**
  ```gdscript
  @tool
  extends Control
  
  var world: WorldData = WorldData.new()  # Custom class for params/seed
  var sections: Array = []  # Array of section nodes
  
  func _ready():
      setup_sections()
      connect_dependencies()
      update_preview()
  
  func setup_sections():
      # Instance and add terrain_section.tscn, etc., to VBox
      # Each section emits "param_changed" signal
  
  func on_generate():
      world.generate()  # Procedural gen
      update_preview()
  ```

Match aesthetic: Apply custom Theme to all Controls. Add CanvasLayer with GPUParticles2D for subtle runes (texture: rune.png, emission: low, color: glowing blue).

#### 4. Implementing Sections
Each section is a collapsible PanelContainer (VBox inside for params).
- **Common Pattern:** For each (e.g., terrain_section.tscn):
  - HBox for header: Button (collapse toggle) + Label ("Terrain & Geography").
  - VBox for params: HSlider + SpinBox for values, CheckBox for toggles.
  - Advanced Foldout: ItemList or Accordion for noise funcs (e.g., FastNoiseLite editor).
- **Parameter Types (per spec):**
  - Sliders/Numeric: HSlider (range 0-100) linked to SpinBox.
  - Dropdowns: OptionButton for biomes (e.g., "Forest", "Desert").
  - Advanced: Popup with GraphEdit for noise (use FastNoiseLite.get_noise_2d(x,y)).
  - Randomness: Per-category HSlider ("Terrain Chaos: 0-100%").
- **Script Example (terrain_section.gd):**
  ```gdscript
  extends PanelContainer
  
  signal param_changed(param, value)
  
  @export var elevation_slider: HSlider
  @export var noise_type: OptionButton  # Perlin, Simplex, etc.
  
  func _on_slider_value_changed(value):
      emit_signal("param_changed", "elevation", value)
  ```
- **D&D Hooks:** In biomes section, add metadata tags as Dictionary (e.g., {"temperature": "cold", "monsters": ["goblin", "wolf"]}). Store in world.biome_metadata.

Sections emit signals on change → main.gd propagates (one-way: terrain change → climate auto-adjust).

#### 5. Procedural Generation Logic
Use FastNoiseLite for noise-based gen (built-in, Perlin/Simplex/Cellular).
- **WorldData Class (world.gd):**
  ```gdscript
  class_name WorldData
  extends Resource
  
  @export var seed: int = 0
  @export var size: Vector2i = Vector2i(1024, 1024)  # User slider
  @export var params: Dictionary = {}  # e.g., {"terrain_elevation": 50}
  @export var randomness: Dictionary = {}  # Per-category 0-1.0
  var generated_mesh: Mesh
  var biome_metadata: Array = []  # [{biome: "forest", tags: {...}}]
  
  func generate():
      var noise = FastNoiseLite.new()
      noise.seed = seed
      noise.noise_type = FastNoiseLite.TYPE_PERLIN  # From params
      noise.frequency = params.get("frequency", 0.01) * (1 + randomness.get("terrain", 0))
      
      # Generate heightmap mesh (ArrayMesh)
      var st = SurfaceTool.new()
      st.begin(Mesh.PRIMITIVE_TRIANGLES)
      for x in size.x:
          for y in size.y:
              var height = noise.get_noise_2d(x, y) * params["elevation"]
              # Add vertices/tris (marching squares or grid)
              # Tag biomes based on height/humidity noise
      generated_mesh = st.commit()
      
      # Dependencies: Climate from terrain (e.g., high elev = cold)
      auto_propagate()
  
  func auto_propagate():
      # One-way: Update climate params based on terrain averages
  ```
- **Best Practices:** Generate in chunks for performance (LOD). Start deterministic (same seed = same output), add randomness via offset/noise layers. For civilizations: Use noise for population density, Poisson disk for placements.
- **Manual Overrides:** Post-gen, add EditorPlugin for painting (tool mode: brush to edit heightmap).

#### 6. Preview Setup
- **3D Viewport:** In preview.tscn: Camera3D (projection = ORTHOGRAPHIC, size = 1000 for ortho zoom).
  - Script: Rotatable via mouse (InputEventMouseMotion: rotate_yaw/pitch).
  - Background: Environment with black sky (dark space).
- **Topo Map Render:** Custom ShaderMaterial on MeshInstance3D.
  ```gdscript
  # Shader (topo.shader)
  shader_type spatial;
  render_mode unshaded;
  
  uniform sampler2D heightmap;  # From noise
  varying vec3 vertex_pos;
  
  void vertex() {
      vertex_pos = VERTEX;
  }
  
  void fragment() {
      float height = texture(heightmap, UV).r;
      ALBEDO = vec3(0.0, 0.2 + height * 0.8, 1.0);  // Blue gradient
      // Add lines/nodes: Use step functions for contours, points for nodes
  }
  ```
- **Real-time Updates:** On param change, regenerate mesh (async with Thread for heavy ops, progress bar via ProgressBar popup).
- **Features:** Layer toggles (e.g., hide water via shader uniform). Time-lapse: Animate noise offset over time.

#### 7. Dependencies and Real-time Updates
- In main.gd: Connect all section "param_changed" to a central handler.
  ```gdscript
  func on_param_changed(section, param, value):
      world.params[param] = value
      world.auto_propagate()  # One-way ripple (e.g., climate from terrain)
      update_preview()  # Regen mesh if needed
  ```
- Performance: Use low-res mesh for previews (downsample noise). Batch updates with Timer (debounce changes).

#### 8. Persistence and Editing
- **Save/Load:** Use ResourceSaver.save(world, "MyWorld/data.gworld", ResourceSaver.FLAG_COMPRESS).
  - JSON backup: var json = JSON.stringify(world.params); FileAccess.save("data.json", json).
  - Folder: DirAccess.copy_recursive for assets/previews.
- **Post-Gen Editing:** Switch to "edit mode" (unlock chunks). Use InputEvent to paint on mesh (raycast from camera).
- **Undo/Redo:** Use UndoRedo class: On change, undo_redo.create_action("Param Change"); add_do/undo methods.

#### 9. Export Options
- **Godot/Unity Scenes:** Save generated_mesh as .tres, package with .tscn (ResourceSaver). For Unity: Export mesh as OBJ (custom GDScript exporter using FileAccess).
- **PDF Atlas:** No native support—use a simple GDScript to generate text/markdown, then recommend external tool (e.g., pandoc) for PDF. Or, integrate via OS.execute("wkhtmltopdf ...") if prototyped on desktop.
  - Content: Maps (screenshot Viewport), lore (generated text), tables (CSV from metadata).

#### 10. Additional Features
- **Presets:** Load JSON to set params (e.g., "high_fantasy.json": high magic randomness).
- **Community Sharing:** Simple FileDialog for import/export JSON presets.
- **Guided Tours:** PopupDialog sequence on first run (explain sections).
- **Accessibility:** Tooltips via set_tooltip(), keyboard nav with focus_next.

#### Prototyping Milestones (1-Week Plan)
- **Day 1-2:** Setup project, main scene, basic sections with sliders.
- **Day 3:** Procedural gen + basic mesh.
- **Day 4:** Preview with ortho camera + shader.
- **Day 5:** Dependencies, real-time updates, performance opts.
- **Day 6:** Persistence, exports, D&D tags.
- **Day 7:** Polish (aesthetic, undo, presets), test with sample world.

Resources: Follow YouTube tutorials like "How to Procedurally Generate Terrain" (web:20) for noise/mesh, Godot docs for UI (web:11). Iterate by running in editor—aim for playable MVP before expanding to full tool. If stuck, check Godot forums or extend with addons like Terrain3D (web:26).
