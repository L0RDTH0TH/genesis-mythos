# Azgaar Rendering Investigation Report v2

**Date:** 2025-12-31  
**Investigator:** AI Assistant  
**Scope:** Deep investigation of Azgaar fork rendering issues focusing on post-Voronoi data flow, boundary cell handling, point distribution, isoline generation, and SVG layer failures beyond Voronoi construction.

---

## Executive Summary

Previous investigations identified issues with missing `cells.v` vertex arrays in the Voronoi constructor. This report focuses on **post-Voronoi data flow** and **rendering pipeline** issues that may contribute to or compound the "dot painting" rendering problem. Key findings include:

1. **Data Flow Corruption:** `createBasicPack()` creates empty arrays as fallbacks when `grid.cells.v` contains empty entries, propagating the problem downstream.
2. **Boundary Cell Handling:** The Voronoi constructor filters neighbor cells to exclude boundary points (`c < this.pointsN`), which may cause edge cases where valid vertex arrays are filtered incorrectly.
3. **Isoline Generation Logic:** `getIsolines()` has multiple failure points beyond just empty `cells.v` arrays, including dependency on `cells.c` (neighbor arrays) and `vertices.c` (vertex-to-cell mappings).
4. **SVG Layer Dependencies:** Biomes and States layers depend on `getIsolines()`, while Rivers, Borders, and Features use different rendering paths that may still fail if underlying data is incomplete.
5. **JSON Serialization/Deserialization:** `loadMapData()` creates placeholder empty arrays when `cells.v` is missing from JSON, but cannot reconstruct valid vertex arrays from boundary information alone.

**Critical Insight:** Even if the Voronoi constructor populates `cells.v` correctly, downstream functions (`createBasicPack`, `loadMapData`) may create empty arrays as fallbacks, and `getIsolines()` requires multiple interdependent data structures (`cells.v`, `cells.c`, `vertices.c`) to be valid simultaneously.

---

## Root Cause Analysis

### 1. Post-Voronoi Data Flow: `createBasicPack()` Analysis

The `createBasicPack()` function (lines 3313-3377) copies `grid.cells.v` to `pack.cells.v`:

```3313:3377:assets/ui_web/js/azgaar/azgaar-genesis.esm.js
function createBasicPack(grid, options) {
  const { cells: gridCells, points, vertices } = grid;
  const cellCount = gridCells.i.length;
  // Ensure cells.v is properly initialized - critical for SVG rendering
  // Note: Reconstruction should happen in createVoronoiDiagram (which has voronoi instance access)
  // Here we copy and validate, logging issues for debugging
  let cellsV = [];
  let emptyCount = 0;
  let validCount = 0;
  if (gridCells.v && Array.isArray(gridCells.v)) {
    // cells.v exists - copy it and preserve valid vertex arrays
    for (let i = 0; i < cellCount; i++) {
      if (i < gridCells.v.length && Array.isArray(gridCells.v[i]) && gridCells.v[i].length > 0) {
        cellsV.push([...gridCells.v[i]]);  // Copy valid vertex array
        validCount++;
      } else {
        // Missing or empty vertex array - should have been reconstructed in createVoronoiDiagram
        // Log warning for first few cells, then use empty as fallback
        if (i < 10 && typeof console !== "undefined" && console.warn) {
          console.warn(`[createBasicPack] cells.v[${i}] is missing or empty (length: ${gridCells.v[i]?.length || 0}) - isolines will fail for this cell (should have been reconstructed in createVoronoiDiagram)`);
        }
        emptyCount++;
        cellsV.push([]);  // Fallback empty array (cannot reconstruct without Voronoi instance - should have been done earlier)
      }
    }
    if (emptyCount > 0 && typeof console !== "undefined" && console.warn) {
      console.warn(`[createBasicPack] ${emptyCount}/${cellCount} cells have missing/empty vertex arrays (${validCount} valid) - isolines may fail for empty cells`);
    } else if (typeof console !== "undefined" && console.log) {
      console.log(`[createBasicPack] All ${validCount} cells have valid vertex arrays`);
    }
  } else {
    // cells.v is missing or not an array - create array of empty arrays with correct length
    if (typeof console !== "undefined" && console.error && cellCount > 0) {
      console.error(`[createBasicPack] cells.v missing or invalid (type: ${typeof gridCells.v}, length: ${gridCells.v?.length || 0} vs expected ${cellCount}) - creating placeholder array (all isolines will fail)`);
    }
    for (let i = 0; i < cellCount; i++) {
      cellsV.push([]);
    }
    emptyCount = cellCount;
  }
  const packCells = {
    i: createTypedArray({ maxValue: cellCount, length: cellCount }).map((_, i) => i),
    p: points.slice(),
    g: createTypedArray({ maxValue: cellCount, length: cellCount }).map((_, i) => i),
    h: new Uint8Array(gridCells.h.length),
    c: gridCells.c ? gridCells.c.slice() : [],
    v: cellsV,
    b: gridCells.b ? new Uint8Array(gridCells.b.length) : new Uint8Array(cellCount),
    t: gridCells.t ? new Int8Array(gridCells.t.length) : new Int8Array(cellCount),
    f: gridCells.f ? new Uint16Array(gridCells.f.length) : new Uint16Array(cellCount),
    area: new Float32Array(cellCount)
  };
  // ... rest of function
  return pack;
}
```

**Critical Issues:**

1. **Empty Array Fallbacks:** When `gridCells.v[i]` is missing or empty, the function pushes an empty array `[]` into `cellsV`. This ensures `pack.cells.v[i]` exists but is empty, causing `getIsolines()` to skip the cell.

2. **No Reconstruction Attempt:** The comment states "cannot reconstruct without Voronoi instance", but the Voronoi instance is still accessible via `grid` if it's stored, or reconstruction should have happened earlier. This creates a "point of no return" where empty arrays are permanently set.

3. **Length Mismatch Handling:** If `gridCells.v.length < cellCount`, the function creates empty arrays for missing indices. However, if `gridCells.v.length > cellCount`, indices beyond `cellCount` are ignored, potentially losing valid data.

4. **Array Copying:** The function uses `gridCells.c ? gridCells.c.slice() : []` for `cells.c` (neighbor arrays), which is a shallow copy. If `gridCells.c` contains sparse arrays or undefined entries, these are preserved.

### 2. Boundary Cell Handling and Ocean/Land Distinction

The Voronoi constructor processes points up to `pointsN`, excluding boundary points:

```524:537:assets/ui_web/js/azgaar/azgaar-genesis.esm.js
  constructor(delaunay, points, pointsN) {
    this.delaunay = delaunay;
    this.points = points;
    this.pointsN = pointsN;
    this.cells = { v: [], c: [], b: [] };
    this.vertices = { p: [], v: [], c: [] };
    for (let e = 0; e < this.delaunay.triangles.length; e++) {
      const p = this.delaunay.triangles[this.nextHalfedge(e)];
      if (p < this.pointsN && !this.cells.c[p]) {
        const edges = this.edgesAroundPoint(e);
        this.cells.v[p] = edges.map((e2) => this.triangleOfEdge(e2));
        this.cells.c[p] = edges.map((e2) => this.delaunay.triangles[e2]).filter((c) => c < this.pointsN);
        this.cells.b[p] = edges.length > this.cells.c[p].length ? 1 : 0;
      }
      // ... vertices processing
    }
  }
```

**Critical Analysis:**

1. **Boundary Point Exclusion:** `pointsN = points.length` (line 655), meaning boundary points (added via `points.concat(boundary)`) are excluded from Voronoi cell processing. This is correct, but:

2. **Neighbor Filtering:** Line 535 filters neighbor cells: `.filter((c) => c < this.pointsN)`. This removes boundary points from neighbor arrays, which is correct, BUT:

3. **Boundary Cell Flag:** `cells.b[p]` is set to `1` if `edges.length > this.cells.c[p].length`, indicating the cell has neighbors beyond the boundary. However, if a cell is entirely surrounded by boundary points (or has no valid neighbors due to filtering), `cells.c[p]` may be empty, causing issues downstream.

4. **Edge Case:** If a cell `p` has all neighbors as boundary points, `cells.c[p]` will be an empty array `[]` after filtering. This may cause `getIsolines()` to fail when checking for `onborderCell` (line 2855), as it uses `cells.c[cellId].find(ofDifferentType)` which returns `undefined` for empty arrays.

### 3. Point Distribution and Seed Impact

Point generation via `placePoints()` and `getJitteredGrid()`:

```634:640:assets/ui_web/js/azgaar/azgaar-genesis.esm.js
function placePoints(width, height, cellsDesired, rng) {
  const spacing = rn(Math.sqrt(width * height / cellsDesired), 2);
  const boundary = getBoundaryPoints(width, height, spacing);
  const points = getJitteredGrid(width, height, spacing, rng);
  const cellsX = Math.floor((width + 0.5 * spacing - 1e-10) / spacing);
  const cellsY = Math.floor((height + 0.5 * spacing - 1e-10) / spacing);
  return { spacing, cellsDesired, boundary, points, cellsX, cellsY };
}
```

```620:632:assets/ui_web/js/azgaar/azgaar-genesis.esm.js
function getJitteredGrid(width, height, spacing, rng) {
  const radius = spacing / 2;
  const jittering = radius * 0.9;
  const jitter = () => rng.randFloat(-jittering, jittering);
  let points = [];
  for (let y = radius; y < height; y += spacing) {
    for (let x = radius; x < width; x += spacing) {
      const xj = Math.min(rn(x + jitter(), 2), width);
      const yj = Math.min(rn(y + jitter(), 2), height);
      points.push([xj, yj]);
    }
  }
  return points;
}
```

**Potential Issues:**

1. **Jittering Clamping:** Points are clamped to `[0, width]` and `[0, height]` via `Math.min()`. This may cause points on edges to cluster, potentially creating degenerate Delaunay triangles or incomplete halfedge structures.

2. **Spacing Calculation:** `spacing = sqrt(width * height / cellsDesired)`. For low `cellsDesired` (e.g., points=4 → 10K cells), spacing may be large, causing sparse point distributions that Delaunator may handle inconsistently.

3. **Boundary Point Spacing:** Boundary points use `bSpacing = spacing * 2`, which is twice the regular spacing. This creates a sparser boundary grid that may cause edge cases in Delaunay triangulation.

4. **Seed Dependency:** The RNG seed affects jittering, which may cause certain seeds to produce point distributions that result in incomplete Voronoi diagrams (e.g., collinear points, degenerate triangles).

### 4. Deep Dive: `getIsolines()` Failure Modes

The `getIsolines()` function (lines 2839-2924) has multiple failure points:

```2839:2898:assets/ui_web/js/azgaar/azgaar-genesis.esm.js
function getIsolines(pack, getType, options = { fill: false, waterGap: false, halo: false }) {
  var _a, _b, _c, _d, _e;
  const { cells, vertices } = pack;
  const isolines = {};
  const checkedCells = new Uint8Array(cells.i.length);
  const addToChecked = (cellId) => checkedCells[cellId] = 1;
  const isChecked = (cellId) => checkedCells[cellId] === 1;
  // Validation: Check if cells.v is missing or invalid
  if (!cells.v || !Array.isArray(cells.v)) {
    if (typeof console !== "undefined" && console.warn) {
      console.warn("[getIsolines] cells.v missing or invalid - isolines cannot be generated");
    }
    return {};
  }
  let skippedCount = 0;
  for (const cellId of cells.i) {
    if (isChecked(cellId) || !getType(cellId)) continue;
    addToChecked(cellId);
    const type = getType(cellId);
    const ofSameType = (cellId2) => getType(cellId2) === type;
    const ofDifferentType = (cellId2) => getType(cellId2) !== type;
    const onborderCell = (_a = cells.c[cellId]) == null ? void 0 : _a.find(ofDifferentType);
    if (onborderCell === void 0) continue;
    const feature = (_c = pack.features) == null ? void 0 : _c[(_b = cells.f) == null ? void 0 : _b[onborderCell]];
    if ((feature == null ? void 0 : feature.type) === "lake" && ((_d = feature.shoreline) == null ? void 0 : _d.every(ofSameType))) continue;
    // Validation: Check if cells.v[cellId] is valid before using it
    if (!cells.v[cellId] || !Array.isArray(cells.v[cellId]) || cells.v[cellId].length === 0) {
      if (skippedCount < 10 && typeof console !== "undefined" && console.warn) {
        console.warn(`[getIsolines] Skipping isoline for cell ${cellId} - missing/empty cells.v[${cellId}]`);
      }
      skippedCount++;
      continue;  // Skip invalid cell
    }
    let startingVertex = (_e = cells.v[cellId]) == null ? void 0 : _e.find(
      (v) => {
        var _a2;
        return (_a2 = vertices.c[v]) == null ? void 0 : _a2.some(ofDifferentType);
      }
    );
    // Fallback: if no starting vertex found via condition, try first vertex in cells.v[cellId]
    if (startingVertex === void 0) {
      if (cells.v[cellId] && Array.isArray(cells.v[cellId]) && cells.v[cellId].length > 0) {
        // Attempt fallback: use first vertex as starting point
        startingVertex = cells.v[cellId][0];
        if (typeof console !== "undefined" && console.warn && skippedCount < 5) {
          console.warn(`[getIsolines] No starting vertex found via condition for cell ${cellId} - using first vertex ${startingVertex} as fallback`);
        }
      } else {
        // No vertices available - cannot create isoline
        if (skippedCount < 10 && typeof console !== "undefined" && console.warn) {
          console.warn(`[getIsolines] No starting vertex found for cell ${cellId} (cells.v[${cellId}] is empty) - skipping isoline`);
        }
        skippedCount++;
        continue;
      }
    }
    const vertexChain = connectVertices({
      vertices,
      startingVertex,
      ofSameType,
      addToChecked,
      closeRing: true
    });
    if (vertexChain.length < 3) continue;
    addIsoline(type, vertices, vertexChain);
  }
  return isolines;
```

**Failure Modes:**

1. **Empty `cells.v` Arrays:** Line 2860 checks if `cells.v[cellId]` is empty and skips the cell. This is the primary failure mode we've identified.

2. **Missing `cells.c` Neighbor Arrays:** Line 2855 uses `cells.c[cellId]` to find a border cell. If `cells.c[cellId]` is `undefined` or empty (e.g., cell has no neighbors after boundary filtering), `onborderCell` is `undefined` and the cell is skipped.

3. **Missing `vertices.c` Mappings:** Line 2870 uses `vertices.c[v]` to check if a vertex touches cells of different types. If `vertices.c[v]` is missing or empty, the starting vertex search fails, and the fallback uses the first vertex (line 2877), which may not be correct.

4. **`connectVertices()` Failures:** The `connectVertices()` function (lines 2925-2947) may fail if:
   - `vertices.v[current]` is missing (line 2938)
   - The vertex chain doesn't close (line 2945)
   - `MAX_ITERATIONS` is exceeded (line 2943)

5. **Insufficient Vertex Chain Length:** Line 2897 requires `vertexChain.length >= 3`. If `connectVertices()` returns a chain with fewer than 3 vertices, the isoline is skipped.

### 5. SVG Layer Analysis: Which Layers Fail and Why

The `renderMapSVG()` function (lines 3209-3303) attempts to render multiple layers:

**Layer Dependencies on `getIsolines()`:**

1. **Biomes Layer** (line 3236): Calls `drawBiomesSVG()` → `getIsolines(pack, (cellId) => cells.biome[cellId])`
   - **Requires:** `pack.cells.biome`, `pack.cells.v`, `pack.cells.c`, `pack.vertices.c`
   - **Failure:** Returns empty string if isolines are empty

2. **States Layer** (line 3248): Calls `drawStatesSVG()` → `getIsolines(pack, (cellId) => cells.state[cellId])`
   - **Requires:** `pack.cells.state`, `pack.cells.v`, `pack.cells.c`, `pack.vertices.c`
   - **Failure:** Returns empty string if isolines are empty

**Layer Dependencies (No `getIsolines()`):**

3. **Features Layer** (line 3222): Calls `drawFeaturesSVG()` (lines 3191-3208)
   - **Requires:** `pack.features`, `pack.vertices.p`
   - **Failure:** Returns empty string if no features or missing vertices
   - **Note:** This layer should work if features are generated, but may be sparse

4. **Rivers Layer** (line 3260): Calls `drawRiversSVG()` (lines 3118-3132)
   - **Requires:** `pack.rivers`, `pack.cells.p` (point coordinates)
   - **Failure:** Returns empty string if no rivers or missing point coordinates
   - **Note:** Rivers use point coordinates, not vertex arrays, so should work independently

5. **Borders Layer** (line 3272): Calls `drawBordersSVG()` (lines 3014-3117)
   - **Requires:** `pack.cells.state`, `pack.cells.c`, `pack.vertices.p`, `pack.cells.v` (for edge calculations)
   - **Failure:** May return empty borders if `cells.c` is missing or `vertices.p` is invalid
   - **Note:** Uses `cells.v` indirectly via vertex-to-cell mappings

6. **Burgs Layer** (line 3285): Calls `drawBurgsSVG()`
   - **Requires:** `pack.burgs`, `pack.cells.p`
   - **Failure:** Returns empty string if no burgs
   - **Note:** Should work independently

**Layer Rendering Order (Critical for "Dot Painting" Appearance):**

1. Ocean base (always renders)
2. Features (may be sparse)
3. Land base (always renders) ← **This covers features, causing "dot painting" if biomes/states are empty**
4. Biomes (FAILS if isolines empty) ← **Primary failure point**
5. States (FAILS if isolines empty) ← **Primary failure point**
6. Rivers (should work)
7. Borders (may fail if `cells.c` missing)
8. Burgs (should work)

**Result:** If Biomes and States layers are empty (due to failed isolines), only the Land base rectangle is visible, giving the appearance of a solid color map with only point features (rivers, burgs) visible, hence "dot painting".

### 6. JSON Serialization/Deserialization: `loadMapData()` Analysis

The `loadMapData()` function (lines 3668-3795) loads map data from JSON:

```3742:3770:assets/ui_web/js/azgaar/azgaar-genesis.esm.js
        v: (() => {
          // Ensure cells.v is properly initialized - critical for SVG rendering
          const cellCount = jsonData.pack.cells.i ? jsonData.pack.cells.i.length : 0;
          if (jsonData.pack.cells.v && Array.isArray(jsonData.pack.cells.v) && jsonData.pack.cells.v.length === cellCount) {
            // Valid cells.v exists - validate and fill undefined entries
            let hasUndefined = false;
            const validated = jsonData.pack.cells.v.map((v, idx) => {
              if (v === undefined || v === null) {
                hasUndefined = true;
                return [];
              }
              return Array.isArray(v) ? v : [];
            });
            if (hasUndefined && typeof console !== "undefined" && console.warn) {
              console.warn(`loadMapData: cells.v contained undefined/null entries, filled with empty arrays`);
            }
            return validated;
          } else {
            // cells.v is missing, empty, or wrong length - create array of empty arrays
            if (typeof console !== "undefined" && console.warn && cellCount > 0) {
              console.warn(`loadMapData: cells.v missing or empty (length ${jsonData.pack.cells.v?.length || 0} vs expected ${cellCount}), creating placeholder array`);
            }
            const placeholder = [];
            for (let i = 0; i < cellCount; i++) {
              placeholder.push([]);
            }
            return placeholder;
          }
        })()
```

**Critical Issues:**

1. **Empty Array Fallbacks:** When `cells.v` is missing or has wrong length, the function creates an array of empty arrays, permanently losing the ability to render isolines.

2. **Undefined/Null Handling:** The function converts `undefined`/`null` entries to empty arrays, which is correct, but cannot reconstruct valid vertex arrays from JSON alone (requires Voronoi instance).

3. **No Reconstruction:** Unlike `createBasicPack()`, `loadMapData()` cannot access the Voronoi instance, so it cannot reconstruct `cells.v` even if boundary/point data is available.

4. **JSON Export (`getMapData()`):** The `getMapData()` function (lines 3509-3587) exports `cells.v` to JSON:

```3548:3565:assets/ui_web/js/azgaar/azgaar-genesis.esm.js
        v: (() => {
          // Ensure cells.v is properly initialized - critical for SVG rendering
          const cellCount = pack.cells.i ? pack.cells.i.length : 0;
          if (pack.cells.v && Array.isArray(pack.cells.v) && pack.cells.v.length === cellCount) {
            // Valid cells.v exists - map it properly
            return pack.cells.v.map((v) => Array.isArray(v) ? [...v] : v);
          } else {
            // cells.v is missing, empty, or wrong length - create array of empty arrays
            if (typeof console !== "undefined" && console.warn && cellCount > 0) {
              console.warn(`getMapData: cells.v missing or empty (length ${pack.cells.v?.length || 0} vs expected ${cellCount}), creating placeholder array`);
            }
            const placeholder = [];
            for (let i = 0; i < cellCount; i++) {
              placeholder.push([]);
            }
            return placeholder;
          }
        })(),
```

   - **Issue:** If `pack.cells.v` contains empty arrays, they are exported to JSON, and `loadMapData()` will load them as empty arrays, creating a permanent loss of data.

---

## Evidence from Logs and Code

### Code Evidence

1. **Empty Array Propagation:** Both `createBasicPack()` and `loadMapData()` create empty arrays as fallbacks when `cells.v` is missing or empty. This ensures the data structure exists but is invalid, causing downstream failures.

2. **Multiple Validation Points:** The codebase has validation at multiple points:
   - `createVoronoiDiagram()` (reconstruction attempt)
   - `createBasicPack()` (validation and logging)
   - `loadMapData()` (validation and placeholder creation)
   - `getIsolines()` (validation and skipping)
   - `renderPreviewSVG()` (validation before rendering)

   The presence of validation at all these points suggests that `cells.v` is indeed missing or empty at various stages of the pipeline.

3. **Dependency Chain:** `getIsolines()` requires:
   - `cells.v[cellId]` (vertex arrays)
   - `cells.c[cellId]` (neighbor arrays)
   - `vertices.c[v]` (vertex-to-cell mappings)
   - `getType(cellId)` (biome/state assignments)

   If ANY of these are missing or invalid, isoline generation fails, causing Biomes and States layers to be empty.

4. **Layer-Specific Failures:** Based on code analysis:
   - **Biomes/States:** Fail if `getIsolines()` returns empty (primary failure)
   - **Rivers/Burgs:** Should work independently (use point coordinates)
   - **Borders:** May fail if `cells.c` or `vertices.p` is missing
   - **Features:** Should work if features are generated

### Parameter Comparison Evidence

From `audit/azgaar_param_comparison.md`:
- Fork uses lower point density (points=4-5 → 10K-20K cells) vs. original (points=6-7 → 30K-40K cells)
- Lower density may cause sparse point distributions that result in incomplete Voronoi diagrams or edge cases with boundary points

---

## Recommendations (Prioritized)

### Priority 1: Fix `createBasicPack()` to Preserve Valid Data

**Action:** Instead of creating empty arrays as fallbacks, `createBasicPack()` should preserve the original `gridCells.v` structure, even if some entries are empty, and add validation logging:

```javascript
// In createBasicPack(), replace empty array fallback with preservation:
if (gridCells.v && Array.isArray(gridCells.v)) {
  cellsV = [];
  for (let i = 0; i < cellCount; i++) {
    if (i < gridCells.v.length) {
      // Preserve original entry (even if empty) - reconstruction should happen earlier
      cellsV.push(gridCells.v[i] && Array.isArray(gridCells.v[i]) ? [...gridCells.v[i]] : []);
    } else {
      // Missing index - create empty array
      cellsV.push([]);
      if (i < 10 && typeof console !== "undefined" && console.warn) {
        console.warn(`[createBasicPack] cells.v[${i}] is missing (index out of bounds) - isolines will fail`);
      }
    }
  }
} else {
  // cells.v is missing entirely - this is a critical error
  throw new Error(`[createBasicPack] CRITICAL: grid.cells.v is missing or invalid - cannot create pack without vertex arrays`);
}
```

**Location:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:3313-3377`

**Rationale:** Empty arrays should not be created as fallbacks. If `cells.v` is missing, this is a critical error that should be caught early, not masked by empty arrays.

### Priority 2: Add Validation for `cells.c` Neighbor Arrays

**Action:** Add validation in `getIsolines()` to handle missing or empty `cells.c` arrays:

```javascript
// In getIsolines(), before using cells.c[cellId]:
if (!cells.c || !Array.isArray(cells.c)) {
  if (typeof console !== "undefined" && console.warn) {
    console.warn("[getIsolines] cells.c missing or invalid - isolines cannot find border cells");
  }
  return {};
}

// When checking for border cell:
const cellNeighbors = cells.c[cellId];
if (!cellNeighbors || !Array.isArray(cellNeighbors) || cellNeighbors.length === 0) {
  // Cell has no neighbors (may be boundary cell or isolated cell)
  // Skip this cell for isoline generation
  if (skippedCount < 10 && typeof console !== "undefined" && console.warn) {
    console.warn(`[getIsolines] Cell ${cellId} has no neighbors (cells.c[${cellId}] is empty) - skipping isoline`);
  }
  skippedCount++;
  continue;
}
const onborderCell = cellNeighbors.find(ofDifferentType);
```

**Location:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:2855` (before `cells.c[cellId].find()`)

### Priority 3: Add Validation for `vertices.c` Mappings

**Action:** Add validation in `getIsolines()` to handle missing `vertices.c` mappings:

```javascript
// In getIsolines(), when finding starting vertex:
let startingVertex = cells.v[cellId].find((v) => {
  if (!vertices.c || !Array.isArray(vertices.c) || !vertices.c[v]) {
    return false; // Vertex has no cell mappings
  }
  return vertices.c[v].some(ofDifferentType);
});
```

**Location:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:2867-2872`

### Priority 4: Improve Boundary Point Handling

**Action:** Add validation to ensure boundary cells have valid neighbor arrays after filtering:

```javascript
// In Voronoi constructor, after filtering neighbors:
this.cells.c[p] = edges.map((e2) => this.delaunay.triangles[e2]).filter((c) => c < this.pointsN);
if (this.cells.c[p].length === 0 && edges.length > 0) {
  // All neighbors are boundary points - this is expected for edge cells
  // Log for debugging but don't treat as error
  if (typeof console !== "undefined" && console.log && p < 5) {
    console.log(`[Voronoi] Cell ${p} has no non-boundary neighbors (all ${edges.length} neighbors are boundary points)`);
  }
}
```

**Location:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:535`

### Priority 5: Add Comprehensive Logging for Data Flow

**Action:** Add detailed logging at each stage of the data flow:

```javascript
// In createBasicPack(), log statistics:
const stats = {
  totalCells: cellCount,
  validCells: validCount,
  emptyCells: emptyCount,
  missingCells: cellCount - (gridCells.v?.length || 0),
  sampleValid: cellsV.slice(0, 3).map(v => v.length),
  sampleEmpty: cellsV.filter(v => !v || v.length === 0).slice(0, 3).map((_, i) => cellsV.findIndex((v, idx) => (!v || v.length === 0) && idx >= i))
};
console.log(`[createBasicPack] cells.v statistics:`, stats);
```

**Location:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:3338` (after validation loop)

### Priority 6: Test with Known Good Parameters

**Action:** Test generation with parameters known to work in original Azgaar:
- points=6 (30K cells) instead of 4-5
- mapWidth=2000, mapHeight=1000 instead of 960x540
- Various seeds to identify seed-dependent issues

**Reference:** `audit/azgaar_param_comparison.md`

### Priority 7: Compare `loadMapData()` with Original Azgaar

**Action:** If possible, compare how original Azgaar handles `cells.v` in JSON export/import to identify differences.

---

## Testing Plan

### Test 1: Data Flow Validation

1. Add logging to `createBasicPack()` to track:
   - Number of valid vs. empty `cells.v` arrays
   - Sample of valid arrays (first 3)
   - Sample of empty array indices (first 10)
   - Length mismatches between `gridCells.v.length` and `cellCount`

2. Generate a map and inspect logs to see how many cells have empty `cells.v` after `createBasicPack()`.

### Test 2: Boundary Cell Analysis

1. Add logging to Voronoi constructor to track:
   - Cells with no non-boundary neighbors (`cells.c[p].length === 0`)
   - Cells with boundary flag set (`cells.b[p] === 1`)
   - Correlation between empty `cells.v` and boundary cells

2. Generate maps with different point counts and analyze if boundary cells are more likely to have empty `cells.v`.

### Test 3: Isoline Generation Validation

1. Add detailed logging to `getIsolines()`:
   - Count of cells skipped due to empty `cells.v`
   - Count of cells skipped due to empty `cells.c`
   - Count of cells skipped due to no starting vertex found
   - Count of cells skipped due to insufficient vertex chain length
   - Count of successful isolines generated

2. Generate a map and inspect logs to identify which failure mode is most common.

### Test 4: SVG Layer Rendering

1. Generate a map and inspect `renderMapSVG()` logs:
   - Which layers are empty vs. non-empty
   - Character counts for each layer
   - Correlation between empty layers and `cells.v` statistics

2. Verify that Rivers and Burgs layers render even when Biomes/States are empty.

### Test 5: JSON Export/Import Round-Trip

1. Generate a map with known parameters
2. Export to JSON via `getMapData()`
3. Inspect JSON to verify `cells.v` structure
4. Load JSON via `loadMapData()`
5. Attempt to render and verify if rendering succeeds or fails
6. Compare `cells.v` structure before/after JSON round-trip

### Test 6: Point Distribution Analysis

1. Test with different point counts (4, 5, 6, 7) and seeds
2. Analyze if certain point counts or seeds consistently produce empty `cells.v` arrays
3. Compare point spacing and jittering for problematic seeds

---

## Conclusion

Beyond the Voronoi constructor issues identified in previous reports, this investigation reveals **critical problems in the post-Voronoi data flow**:

1. **Empty Array Propagation:** `createBasicPack()` and `loadMapData()` create empty arrays as fallbacks, permanently losing the ability to render isolines.

2. **Multiple Dependency Failures:** `getIsolines()` requires `cells.v`, `cells.c`, and `vertices.c` to be valid simultaneously. If any are missing or empty, isoline generation fails.

3. **Boundary Cell Edge Cases:** Cells with no non-boundary neighbors may have empty `cells.c` arrays, causing `getIsolines()` to skip them.

4. **Layer-Specific Failures:** Biomes and States layers fail if isolines are empty, while Rivers and Burgs work independently, explaining the "dot painting" appearance (solid land base with only point features visible).

**Recommended Fix Strategy:**

1. **Fix Voronoi constructor** (from previous report) to populate `cells.v` correctly for ALL points.
2. **Remove empty array fallbacks** in `createBasicPack()` and `loadMapData()` - throw errors instead.
3. **Add comprehensive validation** for `cells.c` and `vertices.c` in `getIsolines()`.
4. **Add detailed logging** throughout the pipeline to identify exactly where data is lost.
5. **Test with known good parameters** (points=6, 2000x1000) to verify fixes.

The issue is likely a combination of Voronoi constructor failures AND downstream empty array propagation, creating a cascade of failures that results in empty isolines and "dot painting" rendering.

---

## Appendix: Code References

### Key Files

1. **Pack Creation:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:3313-3377` (`createBasicPack()`)
2. **JSON Loading:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:3668-3795` (`loadMapData()`)
3. **JSON Export:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:3509-3587` (`getMapData()`)
4. **Isoline Generation:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:2839-2924` (`getIsolines()`)
5. **SVG Rendering:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:3209-3303` (`renderMapSVG()`)
6. **SVG Layers:** 
   - `drawBiomesSVG()`: lines 2980-2996
   - `drawStatesSVG()`: lines 2997-3013
   - `drawRiversSVG()`: lines 3118-3132
   - `drawBordersSVG()`: lines 3014-3117
   - `drawFeaturesSVG()`: lines 3191-3208
7. **Point Generation:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:634-640` (`placePoints()`)
8. **Voronoi Constructor:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:524-545`

### Related Documentation

- `audit/azgaar_rendering_disconnect.md` - Initial investigation report
- `audit/azgaar_rendering_investigation_2025-12-31.md` - Voronoi constructor analysis
- `audit/azgaar_param_comparison.md` - Parameter comparison with original Azgaar

---

**Report End**
