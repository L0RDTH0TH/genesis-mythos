# Change 4: Increase Jitter Factor to 0.6

**Date:** 2026-01-01  
**File:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js`  
**Location:** `getJitteredGrid` function, line 622

## What Was Changed

Increased the jitter factor from 0.9 to 0.6, reducing the randomness in point placement.

### Before

```javascript
function getJitteredGrid(width, height, spacing, rng) {
  const radius = spacing / 2;
  const jittering = radius * 0.9;
  const jitter = () => rng.randFloat(-jittering, jittering);
  // ...
}
```

### After

```javascript
function getJitteredGrid(width, height, spacing, rng) {
  const radius = spacing / 2;
  const jittering = radius * 0.6;
  const jitter = () => rng.randFloat(-jittering, jittering);
  // ...
}
```

## Why (Reference to Investigation)

The investigation audit suggested that point distribution might be contributing to Voronoi construction issues. Reducing jitter (from 0.9 to 0.6) makes the grid more regular, which should result in:
1. More predictable Voronoi cell shapes
2. Better edge traversal in the constructor (more consistent halfedge structure)
3. Reduced chance of degenerate cases that might cause constructor edge cases

This is a conservative change that should improve stability without significantly affecting map appearance (0.6 still provides substantial jitter for natural-looking terrain).

## Expected Impact

- **Positive:** More regular point distribution should reduce edge cases in Voronoi construction
- **Positive:** Smaller jitter range reduces chance of points being too close together or too far apart
- **Neutral:** Slightly more regular/less organic-looking terrain (but still random enough for variety)
- **Risk:** Very low - this is a minor parameter adjustment
