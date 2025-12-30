# Azgaar Genesis Fork API Reference

**Last Updated:** December 30, 2025  
**Fork Version:** 20251230 (commit 88dbf22)  
**Bundle:** `azgaar-genesis.esm.js`

## Overview

The Azgaar Genesis fork provides a modular JavaScript API for procedural fantasy map generation, designed for headless operation and integration with external applications (e.g., Godot game engine via WebView).

## Installation

### ES6 Module Import

```javascript
import { 
    initGenerator, 
    loadOptions, 
    generateMap, 
    getMapData, 
    renderPreview,
    renderPreviewSVG 
} from '../js/azgaar/azgaar-genesis.esm.js';

// Peer dependency: Delaunator (for Voronoi diagram generation)
import Delaunator from 'https://cdn.jsdelivr.net/npm/delaunator@5.0.1/+esm';
```

## Core Functions

### `initGenerator(options)`

Initialize the map generator with optional configuration.

**Parameters:**
- `options.canvas` (HTMLCanvasElement, optional): Canvas element for preview rendering. If `null` or omitted, generator runs in headless mode.

**Example:**
```javascript
const canvas = document.getElementById('map-canvas');
initGenerator({ canvas: canvas });
```

### `loadOptions(options)`

Load generation parameters (map size, seed, terrain settings, etc.).

**Parameters:**
- `options` (Object): Generation options dictionary. See [Generation Options](#generation-options) for full parameter list.

**Example:**
```javascript
loadOptions({
    mapWidth: 1024,
    mapHeight: 768,
    seed: "my-world-seed",
    points: 6,
    heightExponent: 1.8,
    statesNumber: 18,
    cultures: 12
});
```

### `generateMap(DelaunatorClass)`

Generate map data using the current options.

**Parameters:**
- `DelaunatorClass` (Class): Delaunator class from the `delaunator` package (required peer dependency).

**Returns:**
- `Object`: `{ seed: String, data: Object }` - Generated seed and internal map data.

**Example:**
```javascript
const result = generateMap(Delaunator);
console.log('Generated seed:', result.seed);
```

### `getMapData()`

Extract full map data as JSON structure.

**Returns:**
- `Object`: Complete map data including:
  - `options`: Generation parameters
  - `grid`: Voronoi cell data (points, heights, etc.)
  - `pack`: Political/social data (states, cultures, religions, biomes, rivers, etc.)
  - `seed`: Generation seed

**Example:**
```javascript
const mapData = getMapData();
console.log('Map width:', mapData.options.mapWidth);
console.log('Cell count:', mapData.grid.points.length);
```

## Rendering Functions

### `renderPreview()`

Render a basic heightmap-style preview to the canvas provided during `initGenerator()`.

**Note:** This function uses the canvas set during initialization (no parameters). Renders oceans, lakes, and landmass only (no cultures, borders, states).

**Example:**
```javascript
renderPreview();
const dataUrl = canvas.toDataURL('image/png');
```

### `renderPreviewSVG(options)`

Render a rich, scalable SVG preview of the map with full layers (cultures, borders, states, rivers, etc.).

**Parameters:**
- `options.container` (HTMLElement, optional): Container element to append SVG to. If omitted, returns SVG string.
- `options.width` (Number, optional): SVG width in pixels (default: 1024).
- `options.height` (Number, optional): SVG height in pixels (default: 768).

**Returns:**
- `String` (if no container): SVG markup string.
- `void` (if container provided): SVG is appended to container.

**Example (Return SVG String):**
```javascript
const svgString = renderPreviewSVG({
    width: 1024,
    height: 768
});
document.getElementById('map-preview').innerHTML = svgString;
```

**Example (Append to Container):**
```javascript
const container = document.getElementById('map-preview');
renderPreviewSVG({
    container: container,
    width: container.clientWidth,
    height: container.clientHeight
});
// SVG is now in container
```

## Generation Options

Common generation parameters (full list available in fork source):

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `mapWidth` | Number | Map width in pixels (240-10000) | 960 |
| `mapHeight` | Number | Map height in pixels (135-10000) | 540 |
| `seed` | String | Generation seed (null = random) | null |
| `points` | Number | Cell density (maps to cellsDesired via log scale) | 4 |
| `template` | String | Heightmap template ID (null = random) | null |
| `statesNumber` | Number | Number of political states (0-100) | 18 |
| `cultures` | Number | Number of cultural groups (1-100) | 12 |
| `religionsNumber` | Number | Number of religions (0-50) | 6 |
| `heightExponent` | Number | Terrain roughness (0.1-10) | 1.8 |
| `lakeElevationLimit` | Number | Lake threshold (0-100) | 20 |

See `azgaar_step_parameters.json` in Genesis Mythos for curated parameter definitions with UI metadata.

## Usage Example (Complete Flow)

```javascript
import Delaunator from 'https://cdn.jsdelivr.net/npm/delaunator@5.0.1/+esm';
import { 
    initGenerator, 
    loadOptions, 
    generateMap, 
    getMapData, 
    renderPreviewSVG 
} from '../js/azgaar/azgaar-genesis.esm.js';

// Initialize (headless mode)
initGenerator({ canvas: null });

// Load options
loadOptions({
    mapWidth: 1024,
    mapHeight: 768,
    seed: "my-world-12345",
    points: 6,
    statesNumber: 20,
    cultures: 15
});

// Generate map
const result = generateMap(Delaunator);
console.log('Generated seed:', result.seed);

// Get full data
const mapData = getMapData();

// Render SVG preview
const svgContainer = document.getElementById('map-preview');
const svgString = renderPreviewSVG({
    container: svgContainer,
    width: 1024,
    height: 768
});
```

## Integration with Genesis Mythos

The fork is integrated into Genesis Mythos via:

1. **HTML Template:** `assets/ui_web/templates/world_builder_v2.html`
   - Loads fork module and handles SVG/canvas rendering
   - Sends map data to Godot via IPC

2. **GDScript Controller:** `scripts/ui/WorldBuilderWebController.gd`
   - Receives IPC messages (`map_generated`, `svg_preview_ready`)
   - Processes JSON data and triggers terrain generation

3. **Alpine.js Component:** `assets/ui_web/js/world_builder.js`
   - Reactive UI for parameter input and preview display
   - Toggles between SVG and canvas preview modes

## Performance Notes

- Generation time: ~1-5 seconds for medium maps (10K cells), ~10-30 seconds for large maps (100K+ cells)
- SVG rendering: <500ms for typical maps
- Canvas rendering: <100ms for basic preview
- Memory usage: ~1-5 MB JSON for medium maps, ~10-50 MB for large maps

## Error Handling

The fork throws errors for invalid operations:
- `NoDataError`: `generateMap()` not called before `getMapData()` or rendering
- `GenerationError`: Map generation or rendering failed
- Standard JavaScript errors for invalid parameters

Always wrap API calls in try-catch blocks:

```javascript
try {
    const result = generateMap(Delaunator);
    const mapData = getMapData();
    renderPreviewSVG({ container: container });
} catch (error) {
    console.error('Generation failed:', error);
    // Handle error
}
```

## Version History

- **20251230 (commit 88dbf22):** Added SVG rendering support (`renderPreviewSVG`)
- **Initial Release:** Canvas-based preview rendering, headless generation, modular API

## References

- Fork Repository: https://github.com/L0RDTH0TH/Genesis-Azgaar
- Original Azgaar FMG: https://github.com/Azgaar/Fantasy-Map-Generator
- Genesis Mythos Integration: See `docs/azgaar_integration_report_2025-12-30.md`
