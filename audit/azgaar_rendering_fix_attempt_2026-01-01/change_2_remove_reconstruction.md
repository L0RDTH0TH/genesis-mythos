# Change 2: Remove Flawed Reconstruction Logic

**Date:** 2026-01-01  
**File:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js`  
**Location:** `createVoronoiDiagram` function, lines 658-708 (removed)

## What Was Changed

Removed the flawed reconstruction logic that attempted to rebuild missing/empty `cells.v` arrays after Voronoi construction. This logic was inefficient (linear search through all edges) and potentially incorrect.

### Before

```javascript
// Validation: Ensure cells.v exists and check for missing/empty vertex arrays
// Voronoi constructor should populate cells.v, but validate for debugging
if (!cells.v || !Array.isArray(cells.v)) {
  if (typeof console !== "undefined" && console.error) {
    console.error("[createVoronoiDiagram] cells.v missing or invalid after Voronoi construction");
  }
  cells.v = [];
}
// RECONSTRUCTION: Actively rebuild missing/empty cells.v arrays using Voronoi methods
let emptyVerticesCount = 0;
let reconstructedCount = 0;
for (let i = 0; i < points.length; i++) {
  if (!cells.v[i] || !Array.isArray(cells.v[i]) || cells.v[i].length === 0) {
    emptyVerticesCount++;
    // Attempt reconstruction: find edges around point i and map to triangles
    let reconstructed = false;
    for (let e = 0; e < delaunay.triangles.length; e++) {
      const p = delaunay.triangles[voronoi.nextHalfedge(e)];
      if (p === i && p < points.length) {
        try {
          const edges = voronoi.edgesAroundPoint(e);
          if (edges && edges.length > 0) {
            cells.v[i] = edges.map((e2) => voronoi.triangleOfEdge(e2));
            reconstructed = true;
            reconstructedCount++;
            if (typeof console !== "undefined" && console.log && reconstructedCount <= 5) {
              console.log(`[createVoronoiDiagram] Reconstructed ${edges.length} vertices for cell ${i}`);
            }
            break;  // Found and reconstructed, move to next cell
          }
        } catch (err) {
          if (typeof console !== "undefined" && console.warn && i < 5) {
            console.warn(`[createVoronoiDiagram] Reconstruction failed for cell ${i}:`, err.message);
          }
        }
      }
    }
    if (!reconstructed) {
      // Failed to reconstruct - initialize as empty array
      if (!cells.v[i]) {
        cells.v[i] = [];
      }
      if (typeof console !== "undefined" && console.warn && emptyVerticesCount <= 10) {
        console.warn(`[createVoronoiDiagram] Could not reconstruct cells.v[${i}] - isolines will fail for this cell`);
      }
    }
  }
}
if (emptyVerticesCount > 0 && typeof console !== "undefined" && console.warn) {
  console.warn(`[createVoronoiDiagram] ${emptyVerticesCount}/${points.length} cells had missing/empty vertex arrays - reconstructed ${reconstructedCount}, ${emptyVerticesCount - reconstructedCount} remain empty`);
}
```

### After

```javascript
// Validation: Ensure cells.v exists (Voronoi constructor should populate it via post-loop)
if (!cells.v || !Array.isArray(cells.v)) {
  if (typeof console !== "undefined" && console.error) {
    console.error("[createVoronoiDiagram] cells.v missing or invalid after Voronoi construction");
  }
  cells.v = [];
}
```

## Why (Reference to Investigation)

The investigation audit identified that this reconstruction logic was inefficient and potentially incorrect. It uses a linear search through all edges for each missing cell, which is O(n*m) complexity. More importantly, if the Voronoi constructor itself is not populating `cells.v` correctly, then this post-processing reconstruction cannot reliably fix the issue because it relies on the same edge traversal logic.

Instead of trying to fix the problem after construction, the fix should be in the Voronoi constructor itself (Change 1). Once the constructor is fixed, this reconstruction logic becomes unnecessary and potentially harmful (it may mask constructor bugs).

## Expected Impact

- **Positive:** Removes inefficient O(n*m) post-processing loop that was masking the root cause
- **Positive:** Forces errors to surface earlier, making debugging easier
- **Positive:** Simplifies code flow - constructor is now responsible for correctness
- **Risk:** If the constructor fix (Change 1) doesn't work, errors will now be caught in `createBasicPack` validation (Change 4) instead of being silently handled here
