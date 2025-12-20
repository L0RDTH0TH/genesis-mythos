# Audit Report: Mesh Generation – Thin Lines Rendering Issue (BG3 World Builder Prototype)

**Project:** BG3 Character Creation Clone (DEBUG) – Procedural World Builder  
**Audit Date:** 2025-01-09  
**Focus:** Mesh Generation System – "Thin Lines" Wireframe Rendering Anomaly  
**Reference Specifications:** `WORLD_BUILDER_GENERATION_GUIDE.md`  
**Godot Version:** 4.3 stable  

---

## Executive Summary

- **Primary Symptom:** Current render displays wireframe-like thin white lines forming abstract mountain shapes, lacking volumetric fill and texture gradients that should be present per specification.
- **Root Cause Hypothesis A:** Shader material application failure—either incorrect shader selection (holographic wireframe shader active instead of solid gradient), or material override not applying correctly due to missing resource paths or failed texture generation.
- **Root Cause Hypothesis B:** Mesh primitive/render mode mismatch—triangle mesh generation in `world.gd` appears correct (`Mesh.PRIMITIVE_TRIANGLES`), but shader culling modes (`cull_front` in `topo_preview.gdshader`) combined with potentially incorrect winding order or missing normals could cause all front faces to be culled, leaving only edge/wireframe artifacts visible.

---

## Section 1: Observed Symptoms (Hop 1 Analysis)

### 1.1 Visual Anomalies in Current Render

- **Wireframe-Like Appearance:** Uniform white lines without surface fill, suggesting unshaded wireframe rendering mode or face culling that hides all solid surfaces.
- **Low Detail:** Jagged, abstract mountain shapes indicate either insufficient vertex density or shader/texture failure preventing smooth gradient application.
- **Lack of Color Gradients:** Missing blue-to-white height gradients and contour lines that should be present per `WORLD_BUILDER_GENERATION_GUIDE.md` §6 specification (expected: `ALBEDO = vec3(0.0, 0.2 + height * 0.8, 1.0)`).
- **No Volumetric Appearance:** Terrain appears flat and two-dimensional rather than having the textured, volumetric appearance shown in Past Render references.

### 1.2 Comparison to Expected Behavior (Past Render / Guide)

- **Past Render Expected State:** 
  - Filled blue gradients with smooth contour lines
  - Proper fragment shading indicating successful shader material application
  - Volumetric terrain with defined elevation features
  - Topographic map aesthetic with color transitions (water → land → snow)

- **Current Render Observed State:**
  - Uniform white lines only
  - No fill between lines
  - No gradient or color information visible
  - Abstract, low-resolution appearance

### 1.3 Pipeline Stage Symptom Mapping

**Mesh Generation Stage (`scripts/world.gd:129-189`):**
- ✅ Uses `Mesh.PRIMITIVE_TRIANGLES` correctly (line 131)
- ✅ Generates proper triangle indices (lines 170-178)
- ✅ Calls `st.generate_normals()` (line 186)
- ⚠️ **Potential Issue:** Vertex/UV generation might produce degenerate triangles if `vert_grid_size` calculations result in zero-size quads or if heightmap conversion introduces NaN/invalid values

**Material Application Stage (`scripts/preview/world_preview.gd:76-100`):**
- ⚠️ **Critical Anomaly:** Material resource path hardcoded: `"res://assets/materials/topo_preview_shader.tres"` (line 82) – if this resource doesn't exist, material creation falls back to shader loading (line 87-91), but there's no error handling if both fail
- ⚠️ **Potential Failure Point:** `_generate_heightmap_texture()` (line 96) may return `null` if mesh has no surfaces or invalid UV data, causing shader parameter `"heightmap"` to be unset
- ⚠️ **Culling Mode Risk:** Shader uses `cull_front` (see Section 2.3.1) which could hide all visible faces if mesh winding order is incorrect

**Viewport Rendering Stage:**
- ⚠️ **Shader Selection:** Two competing preview systems exist:
  - `WorldPreviewController.gd` uses `topo_hologram_final.gdshader` (wireframe shader) on `PlaneMesh`
  - `world_preview.gd` uses `topo_preview.gdshader` (solid shader) on generated `ArrayMesh`
- ⚠️ **Unclear Which Is Active:** `WorldCreator.gd:123-126` conditionally attaches `world_preview.gd` script, but `WorldPreview.tscn` scene file references `WorldPreviewController.gd` directly

---

## Section 2: Hypothesized Root Causes (Hop 2 Analysis)

### 2.1 Shader Material Application Failure Chain

**Sub-point A: Missing Material Resource**
- **Description:** `world_preview.gd:82` attempts to load `"res://assets/materials/topo_preview_shader.tres"`. If this resource file doesn't exist in the project, `load()` returns `null`, triggering fallback shader loading (line 87-91). However, if the shader file path `"res://assets/shaders/topo_preview.gdshader"` is also missing or invalid, `material` remains `null`, but `material_override` assignment (line 100) still executes with `null`, effectively clearing any existing material.
- **Link to Guide:** `WORLD_BUILDER_GENERATION_GUIDE.md` §6 specifies using a `ShaderMaterial` on `MeshInstance3D`, but doesn't specify whether it should be a `.tres` resource or programmatically created. The current implementation assumes a resource file exists.
- **Godot 4.3 Implications:** In Godot 4.3, assigning `null` to `material_override` removes the material entirely, causing the mesh to render with default (white) unlit appearance or fall back to wireframe if no material is present.
- **Diagnostic Recommendation:** Verify existence of both `res://assets/materials/topo_preview_shader.tres` and `res://assets/shaders/topo_preview.gdshader`. Add debug prints in `_apply_topo_shader()` to log material creation success/failure. Check `terrain_mesh_instance.material_override` value in debugger after `update_mesh()` call.

**Sub-point B: Heightmap Texture Generation Failure**
- **Description:** `_generate_heightmap_texture()` (lines 102-170) can return `null` if: mesh has no surfaces, `surface_get_arrays(0)` fails, vertices array is empty, or UV coordinates are missing/invalid. If `heightmap_texture` is `null`, the shader parameter `"heightmap"` remains unset, causing the shader's `texture(heightmap, UV)` calls to fail or return black/zero values, resulting in no visible output (black screen) or fallback wireframe rendering.
- **Link to Guide:** Guide §5 specifies mesh generation via `SurfaceTool` but doesn't explicitly require UV coordinates. However, `world.gd:155` does set UVs, so they should exist. The issue may be in the texture generation mapping logic (lines 153-162) which uses index-based fallback if UVs are missing.
- **Godot 4.3 Implications:** Unset shader uniforms in spatial shaders default to zero/black. If `sampler2D heightmap` is unset or invalid, `texture()` returns `vec4(0.0)`, causing fragment shader to output black or default colors (white if `ALBEDO` is unset).
- **Diagnostic Recommendation:** Add validation in `_generate_heightmap_texture()` to ensure mesh has valid surfaces and UVs before processing. Log texture creation success. Verify shader parameter is set: `material.get_shader_parameter("heightmap")` should return non-null `ImageTexture`.

### 2.2 Shader Culling Mode Conflict

**Sub-point A: `cull_front` Hiding All Faces**
- **Description:** `topo_preview.gdshader:3` specifies `render_mode unshaded, depth_draw_never, cull_front`. The `cull_front` mode culls (hides) all front-facing triangles based on winding order. If the mesh generated by `world.gd` has incorrect vertex winding (e.g., clockwise instead of counter-clockwise when viewed from camera), all front faces are culled, leaving only back faces or edges visible, which could appear as thin lines.
- **Link to Guide:** Guide §6 example shader shows `render_mode unshaded` only, without `cull_front`. The actual implementation adds `cull_front`, which is not specified in the guide and could cause rendering issues if mesh winding is inconsistent.
- **Godot 4.3 Implications:** In Godot 4.3, `Mesh.PRIMITIVE_TRIANGLES` with `SurfaceTool.generate_normals()` should produce correct winding order, but if vertices are added in wrong order or normals point inward, `cull_front` will hide visible faces. The wireframe appearance could be back faces showing through or edge lines from degenerate triangles.
- **Diagnostic Recommendation:** Temporarily change shader to `cull_back` or `cull_disabled` to test if faces become visible. Verify mesh winding order: check `arrays[Mesh.ARRAY_NORMAL]` values point outward from terrain center. Inspect generated mesh in Godot mesh inspector to confirm triangle orientation.

**Sub-point B: `depth_draw_never` Causing Z-Fighting Artifacts**
- **Description:** `depth_draw_never` disables depth buffer writes, which can cause rendering artifacts if multiple surfaces overlap or if back faces are visible through front faces due to culling. This could create the appearance of thin lines if only edges are visible.
- **Link to Guide:** Guide §6 does not specify `depth_draw_never`. This render mode is typically used for transparent overlays, not solid terrain.
- **Godot 4.3 Implications:** Without depth writes, the mesh may not occlude properly, and edge artifacts may become visible. Combined with `cull_front`, this could produce wireframe-like appearance.
- **Diagnostic Recommendation:** Test with `depth_draw_opaque` or remove `depth_draw_never` to see if fill appears. Verify mesh has proper depth variation (check vertex Y values span expected height range).

### 2.3 Mesh Generation Data Flow Breakdown

**Sub-point A: Heightmap Array Conversion Anomaly**
- **Description:** `world.gd:116-117` converts noise image pixel (0-1 range) to noise value (-1 to 1 range) via `(pixel.r * 2.0) - 1.0`. If `heightmap_image` is invalid or uninitialized (e.g., `noise.get_image()` failed), `get_pixel()` may return invalid colors (NaN, infinity) or default black, causing height calculations to produce zero or invalid heights, resulting in flat mesh or degenerate triangles.
- **Link to Guide:** Guide §5 shows simplified mesh generation loop, but doesn't specify the exact conversion from noise to height. The current implementation uses `noise.get_image()` which should work, but error handling is missing.
- **Godot 4.3 Implications:** `FastNoiseLite.get_image()` returns normalized 0-1 range per channel. Invalid results would produce flat terrain (all heights = 0) or NaN vertices that fail to render correctly, potentially appearing as wireframe artifacts.
- **Diagnostic Recommendation:** Add validation: check `heightmap_image.get_size()` matches expected dimensions. Log sample height values (min/max) after conversion. Verify no NaN/infinity values in `heightmap` array before mesh generation.

**Sub-point B: Triangle Index Generation Edge Cases**
- **Description:** `world.gd:164-178` generates triangles using index arithmetic. If `vert_grid_size` is too small (e.g., `(vert_grid_size.x - 1) * (vert_grid_size.y - 1)` < 1) or if loop bounds are incorrect, no triangles are generated, resulting in vertex-only mesh that renders as points or lines.
- **Link to Guide:** Guide §5 shows simplified loop structure without explicit bounds checking. Current implementation has abort checks (`if should_abort: return`) but no validation of grid size minimums.
- **Godot 4.3 Implications:** Mesh with vertices but no indices renders as point cloud. Mesh with indices but degenerate triangles (all vertices colinear) may render as lines. If `preview_resolution` is set too low (e.g., `SizePreset.TINY = 64`), resulting mesh may have insufficient detail.
- **Diagnostic Recommendation:** Verify `vert_grid_size.x` and `vert_grid_size.y` are both >= 2 before triangle generation. Log triangle count: should be `(vert_grid_size.x - 1) * (vert_grid_size.y - 1) * 2`. Check mesh inspector shows surface with triangle count > 0.

### 2.4 Competing Preview System Conflict

**Sub-point A: Two Preview Controllers Active Simultaneously**
- **Description:** Two separate preview systems exist: `WorldPreviewController.gd` (uses `PlaneMesh` with holographic wireframe shader) and `world_preview.gd` (uses generated `ArrayMesh` with solid gradient shader). `WorldCreator.gd:123-126` conditionally attaches `world_preview.gd` script if `world_preview` node exists, but `WorldPreview.tscn` scene file directly references `WorldPreviewController.gd` as its script (line 58). If both are active or if the wrong one is used, wireframe shader may be applied to solid mesh or vice versa.
- **Link to Guide:** Guide §6 specifies a single preview system with `MeshInstance3D` for world mesh. The existence of two systems suggests refactoring in progress or conflicting implementations.
- **Godot 4.3 Implications:** Scene scripts attached directly to nodes take precedence over dynamically attached scripts. If `WorldPreview.tscn` has `WorldPreviewController.gd` attached, `WorldCreator.gd`'s script attachment may be ignored or cause conflicts.
- **Diagnostic Recommendation:** Check which script is actually active on the preview node at runtime: `world_preview.get_script()` should return expected script. Verify scene file `WorldPreview.tscn` script path matches intended controller. Ensure only one preview system is used.

**Sub-point B: Shader Selection Mismatch**
- **Description:** `WorldPreviewController.gd` uses `topo_hologram_final.gdshader` which is intentionally designed to produce wireframe/holographic appearance (line 24-28: "Dense holographic wireframe"). If this shader is accidentally applied to the terrain mesh, it would produce exactly the "thin lines" appearance described. The shader's `ALBEDO = vec3(0.0)` (line 45) means no solid fill, only emission-based wireframe lines.
- **Link to Guide:** Guide §6 specifies simple blue gradient shader (`ALBEDO = vec3(0.0, 0.2 + height * 0.8, 1.0)`), not holographic wireframe. The holographic shader contradicts the specification.
- **Godot 4.3 Implications:** Shader with `ALBEDO = vec3(0.0)` and `EMISSION` only produces glowing lines without fill, matching the observed symptom exactly. If `topo_hologram_final.gdshader` is the active shader, this explains the wireframe appearance.
- **Diagnostic Recommendation:** Verify active shader on mesh: `terrain_mesh_instance.material_override.shader.resource_path` should be `"res://assets/shaders/topo_preview.gdshader"`, not `"res://assets/shaders/topo_hologram_final.gdshader"`. Check scene file material assignments.

### 2.5 Viewport/Environment Rendering Settings

**Sub-point A: Viewport Rendering Mode Override**
- **Description:** SubViewport rendering settings might be configured to show wireframe mode or debug view. If viewport debug draw is enabled (e.g., `Viewport.DEBUG_DRAW_WIREFRAME`), all meshes render as wireframe regardless of material.
- **Link to Guide:** Guide §6 doesn't specify viewport debug settings. Default should be solid rendering.
- **Godot 4.3 Implications:** `SubViewport.debug_draw` property controls rendering mode. If set to `Viewport.DEBUG_DRAW_WIREFRAME`, all geometry renders as lines.
- **Diagnostic Recommendation:** Check `SubViewport.debug_draw` value in scene file or at runtime. Should be `Viewport.DEBUG_DRAW_DISABLED` (0) for normal rendering.

**Sub-point B: Missing or Incorrect Lighting**
- **Description:** If shader uses `render_mode unshaded`, lighting doesn't matter, but if material is missing and mesh falls back to default material, lack of lighting could cause visibility issues. However, unshaded shaders should still show colors, so this is less likely the root cause unless material assignment failed entirely.
- **Link to Guide:** Guide §6 specifies `render_mode unshaded`, so lighting should not be required.
- **Godot 4.3 Implications:** Unshaded materials ignore lights, so missing `DirectionalLight3D` shouldn't cause wireframe appearance. If material is null and default material is used, it may appear white/unlit but should still show faces, not just lines.
- **Diagnostic Recommendation:** Verify `DirectionalLight3D` exists in scene (should be present per guide). Check if removing lights changes appearance (should not, if shader is unshaded).

### 2.6 Threading/Mesh Update Synchronization Issue

**Sub-point A: Mesh Assignment Before Generation Complete**
- **Description:** `world.gd` generates mesh in background thread (`_generate_threaded()`), then updates `generated_mesh` on main thread via mutex (lines 192-194). If `world_preview.update_mesh()` is called before `generated_mesh` is set or if mutex lock fails, mesh may be null or stale, causing rendering of empty/previous mesh that appears as lines.
- **Link to Guide:** Guide §7 mentions threading for performance but doesn't specify synchronization details. Current implementation uses mutex correctly, but error handling is minimal.
- **Godot 4.3 Implications:** Assigning `null` mesh to `MeshInstance3D` makes it invisible. Assigning incomplete mesh (e.g., vertices but no indices) may render as points/lines only.
- **Diagnostic Recommendation:** Add validation in `update_mesh()`: check `new_mesh != null` and `new_mesh.get_surface_count() > 0` before assignment. Log mesh assignment timing relative to generation completion signal.

**Sub-point B: Preview Update Not Triggered**
- **Description:** `WorldCreator.gd:250-256` calls `update_mesh()` on `world.generation_complete` signal, but if signal connection is broken or if preview node reference is invalid, mesh update never occurs, leaving previous (possibly wireframe) mesh visible.
- **Link to Guide:** Guide §7 specifies real-time updates on param change, but doesn't detail signal connection implementation.
- **Godot 4.3 Implications:** If `world_preview` node is null or `update_mesh()` method doesn't exist, mesh never updates, causing stale rendering.
- **Diagnostic Recommendation:** Verify signal connection: `world.generation_complete` should be connected to preview update handler. Add debug prints in `_on_generation_complete()` to confirm signal emission. Check `world_preview` node exists and has correct script attached.

---

## Section 3: Interdependencies and Ripple Effects

- **Material Failure → Shader Parameter Unset → Heightmap Texture Missing:** If `_generate_heightmap_texture()` fails, shader receives no heightmap, causing flat or black rendering that may appear as wireframe if combined with culling issues.

- **Cull Mode + Winding Order → All Faces Hidden:** If `cull_front` is active and mesh has incorrect winding, all front faces are hidden, leaving only back faces or edges visible as thin lines.

- **Preview System Conflict → Wrong Shader Applied:** If `WorldPreviewController.gd` (wireframe shader) is active instead of `world_preview.gd` (solid shader), terrain always renders as wireframe regardless of mesh generation quality.

- **Mesh Generation Failure → Degenerate Triangles → Line Rendering:** If heightmap conversion produces invalid values or triangle generation fails, mesh may have zero-area triangles that render as lines or points instead of solid faces.

- **Threading Race Condition → Stale Mesh → Previous Wireframe Visible:** If mesh update occurs before new mesh is ready, previous (possibly wireframe) mesh remains visible, giving false impression that generation failed.

- **Auto-Propagation Ripple:** If mesh generation fails due to invalid params, `auto_propagate()` (line 203) may still execute, potentially corrupting parameter state for subsequent generation attempts, causing cascading failures.

- **Climate/Biome Section Dependencies:** If terrain generation fails, biome assignment (`_assign_biomes()`, line 197) receives invalid heightmap data, causing incorrect biome colors or missing overlay, which could compound visual confusion if user expects biome-colored terrain.

---

## Section 4: Metrics for Validation

| Aspect | Current State (from symptoms) | Desired State (from Past Render/Guide) | Audit Check |
|--------|------------------------------|--------------------------------------|-------------|
| **Vertex Count** | Unknown (low detail suggests < 1000) | Should be `vert_grid_size.x * vert_grid_size.y` (e.g., 256×256×4 = 262,144 for SMALL preset with VERTS_PER_UNIT=4) | Verify: `mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()` >= expected count |
| **Triangle Count** | Unknown (wireframe suggests 0 or degenerate) | Should be `(vert_grid_size.x - 1) * (vert_grid_size.y - 1) * 2` (e.g., 511×511×2 = 522,242) | Verify: `mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() / 3` >= expected count |
| **Material Applied** | Likely null or wrong shader | Should be `ShaderMaterial` with `topo_preview.gdshader` | Check: `terrain_mesh_instance.material_override != null` and `material_override.shader.resource_path == "res://assets/shaders/topo_preview.gdshader"` |
| **Heightmap Texture** | Likely null or invalid | Should be `ImageTexture` with size matching mesh UVs (e.g., 512×512 or 1024×1024) | Verify: `material.get_shader_parameter("heightmap") != null` and texture has valid image data |
| **Shader Render Mode** | Unknown (possibly wireframe mode) | Should be `unshaded` (solid fill, not wireframe) | Check shader source: `render_mode unshaded` (no `cull_front` or `depth_draw_never` ideally, or verify cull matches mesh winding) |
| **Mesh Surface Count** | Unknown (likely 0 or 1) | Should be 1 (single terrain surface) | Verify: `mesh.get_surface_count() == 1` |
| **Normal Array Present** | Unknown | Should exist (generated via `st.generate_normals()`) | Check: `arrays[Mesh.ARRAY_NORMAL].size() > 0` and normals point outward |
| **UV Array Present** | Unknown (texture gen may fail if missing) | Should exist (set via `st.set_uv()` in world.gd:155) | Verify: `arrays[Mesh.ARRAY_TEX_UV].size() == vertices.size()` |
| **Height Range** | Flat or zero (suggested by low detail) | Should span elevation range (e.g., -100 to +100 based on `elevation_scale` param) | Check: `min(vertices.y)` and `max(vertices.y)` span expected range |
| **Active Preview Script** | Possibly `WorldPreviewController.gd` (wireframe) | Should be `world_preview.gd` (solid) | Verify: `world_preview.get_script().resource_path == "res://scripts/preview/world_preview.gd"` |
| **Viewport Debug Draw** | Possibly `DEBUG_DRAW_WIREFRAME` | Should be `DEBUG_DRAW_DISABLED` | Check: `SubViewport.debug_draw == Viewport.DEBUG_DRAW_DISABLED` |

---

## Appendices

### Appendix A: Key Code Snippets from Guide and Implementation

**Guide Specification (WORLD_BUILDER_GENERATION_GUIDE.md §5):**
```gdscript
# Generate heightmap mesh (ArrayMesh)
var st = SurfaceTool.new()
st.begin(Mesh.PRIMITIVE_TRIANGLES)
for x in size.x:
    for y in size.y:
        var height = noise.get_noise_2d(x, y) * params["elevation"]
        # Add vertices/tris (marching squares or grid)
        # Tag biomes based on height/humidity noise
generated_mesh = st.commit()
```
**Annotation:** Guide shows simplified loop. Actual implementation (`world.gd:129-189`) correctly implements vertex generation, UV assignment, and triangle indexing, but guide doesn't specify UV requirements or normal generation.

**Guide Specification (WORLD_BUILDER_GENERATION_GUIDE.md §6):**
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
**Annotation:** Guide specifies simple blue gradient. Actual shader (`topo_preview.gdshader`) adds `depth_draw_never, cull_front` and complex color transitions (water/land/snow), which deviates from guide and may cause rendering issues.

**Implementation Risk Point (world.gd:131):**
```gdscript
st.begin(Mesh.PRIMITIVE_TRIANGLES)  # Correct primitive type
```
**Annotation:** This is correct. Issue is not in primitive type selection.

**Implementation Risk Point (world_preview.gd:82-100):**
```gdscript
var shader_material_path: String = "res://assets/materials/topo_preview_shader.tres"
var material: ShaderMaterial = load(shader_material_path)

if not material:
    # Create material from shader if resource doesn't exist
    var shader_path: String = "res://assets/shaders/topo_preview.gdshader"
    var shader: Shader = load(shader_path)
    if shader:
        material = ShaderMaterial.new()
        material.shader = shader

if material:
    # ... texture generation ...
    terrain_mesh_instance.material_override = material
```
**Annotation:** Critical risk: If both resource and shader load fail, `material` remains `null`, but code continues. If `material` is null, `if material:` block is skipped, and `material_override` is never set (or remains previous value, possibly wireframe shader). No error handling or fallback.

**Implementation Risk Point (topo_preview.gdshader:3):**
```glsl
render_mode unshaded, depth_draw_never, cull_front;
```
**Annotation:** `cull_front` is not in guide specification and may cause all front faces to be hidden if mesh winding is incorrect. `depth_draw_never` is unusual for solid terrain and may cause rendering artifacts.

**Implementation Risk Point (WorldPreviewController.gd vs world_preview.gd):**
- `WorldPreviewController.gd` uses `topo_hologram_final.gdshader` (wireframe shader) – this matches the "thin lines" symptom exactly.
- `world_preview.gd` uses `topo_preview.gdshader` (solid shader) – this matches guide specification.
- Conflict: Both systems exist, unclear which is active.

### Appendix B: Visual Diff Notes

**Screenshot Variance Analysis (Text Description):**

**Current Render (Wireframe/Thin Lines):**
- Appearance: Uniform white lines forming abstract, jagged mountain-like shapes
- Fill: No surface fill visible between lines
- Detail: Low-resolution, angular edges
- Color: Monochromatic white/gray, no gradients
- Depth: Appears flat, two-dimensional wireframe

**Past Render (Desired/Expected):**
- Appearance: Solid volumetric terrain with smooth elevation transitions
- Fill: Blue-to-white gradient fills entire surface area
- Detail: High-resolution smooth curves and defined topographic features
- Color: Blue gradients (water → land → snow), with cyan contour lines overlaid
- Depth: Three-dimensional appearance with clear elevation differences

**Hypothesis Mapping:**
- If shader is `topo_hologram_final.gdshader` → Current render matches expected output of that shader (wireframe-only).
- If material is null → Current render matches default unlit white appearance or fallback wireframe.
- If `cull_front` hides all faces → Current render matches back-face edges or degenerate triangle lines.
- If heightmap texture is missing → Current render matches shader output with zero height (flat black/white).

---

## Diagnostic Query Recommendations (Non-Actionable)

1. **Material Validation:** In debugger, inspect `terrain_mesh_instance.material_override` after `update_mesh()` call. Is it `null`? If not, what is `material_override.shader.resource_path`? Is it the expected `topo_preview.gdshader` or the wireframe `topo_hologram_final.gdshader`?

2. **Mesh Surface Inspection:** After generation, check `world.generated_mesh.get_surface_count()`. Is it 1 (expected) or 0 (failure)? If 1, inspect `surface_get_arrays(0)[Mesh.ARRAY_INDEX].size()`. Is triangle count > 0?

3. **Heightmap Texture Status:** After `_generate_heightmap_texture()` call, check return value. Is it `null`? If not, what is texture size? Does `material.get_shader_parameter("heightmap")` return the texture after assignment?

4. **Preview Script Verification:** At runtime, check `world_preview.get_script().resource_path`. Is it `world_preview.gd` (expected) or `WorldPreviewController.gd` (wireframe system)?

5. **Shader Render Mode Check:** Inspect active shader source code. Does it have `cull_front`? If so, test changing to `cull_back` or `cull_disabled`. Does appearance change?

6. **Vertex/Triangle Counts:** Log vertex count and triangle count after mesh generation. Do they match expected values based on `size_preset` and `VERTS_PER_UNIT`?

7. **Height Range Validation:** Extract min/max Y values from generated mesh vertices. Do they span expected elevation range, or are they all zero/flat?

8. **Viewport Debug Mode:** Check `SubViewport.debug_draw` property. Is it `DEBUG_DRAW_DISABLED` (0) or `DEBUG_DRAW_WIREFRAME` (1)?

---

**Audit complete; await directives for remediation phase.**

**[AUDIT COMPLETE – READY FOR NEXT PHASE]**
