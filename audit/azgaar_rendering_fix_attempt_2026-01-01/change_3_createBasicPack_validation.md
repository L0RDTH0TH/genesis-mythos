# Change 3: Add Error Throw for >10% Empty cells.v in createBasicPack

**Date:** 2026-01-01  
**File:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js`  
**Location:** `createBasicPack` function, after counting empty cells

## What Was Changed

Added validation that throws an error if more than 10% of cells have empty `cells.v` arrays, and throws immediately if `cells.v` is missing entirely.

### Before

```javascript
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
      cellsV.push([]);  // Fallback empty array
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
```

### After

```javascript
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
      cellsV.push([]);  // Fallback empty array
    }
  }
  // Error if >10% empty cells.v - indicates serious Voronoi construction issue
  const emptyPercent = (emptyCount / cellCount) * 100;
  if (emptyPercent > 10) {
    const errorMsg = `[createBasicPack] Too many empty cells.v: ${emptyCount}/${cellCount} (${emptyPercent.toFixed(1)}%) - Voronoi constructor failed to populate cells.v correctly`;
    if (typeof console !== "undefined" && console.error) {
      console.error(errorMsg);
    }
    throw new Error(errorMsg);
  }
  if (emptyCount > 0 && typeof console !== "undefined" && console.warn) {
    console.warn(`[createBasicPack] ${emptyCount}/${cellCount} cells have missing/empty vertex arrays (${validCount} valid) - isolines may fail for empty cells`);
  } else if (typeof console !== "undefined" && console.log) {
    console.log(`[createBasicPack] All ${validCount} cells have valid vertex arrays`);
  }
} else {
  // cells.v is missing or not an array - this is a critical error
  const errorMsg = `[createBasicPack] cells.v missing or invalid (type: ${typeof gridCells.v}, length: ${gridCells.v?.length || 0} vs expected ${cellCount}) - Voronoi constructor failed completely`;
  if (typeof console !== "undefined" && console.error) {
    console.error(errorMsg);
  }
  throw new Error(errorMsg);
}
```

## Why (Reference to Investigation)

The investigation audit recommended adding validation to fail fast when `cells.v` is missing or has too many empty entries. This prevents silent failures that result in "dot painting" rendering. The 10% threshold is a reasonable balance - a small number of empty cells might be acceptable (edge cases, boundary cells), but >10% indicates a systematic failure in Voronoi construction.

By throwing an error immediately, we:
1. Prevent downstream functions from trying to work with invalid data
2. Make debugging easier by surfacing the error at the source
3. Force the constructor fix (Change 1) to be validated

## Expected Impact

- **Positive:** Fails fast with clear error message when Voronoi construction fails
- **Positive:** Prevents silent "dot painting" rendering by catching errors early
- **Positive:** Provides actionable error message pointing to constructor failure
- **Risk:** If the constructor fix (Change 1) doesn't work, map generation will now fail with an error instead of producing invalid output
