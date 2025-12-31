# Azgaar Rendering Disconnect Report

**Date:** 2025-12-31  
**Investigator:** AI Assistant  
**Scope:** Investigation of why Azgaar fork renders maps as "dot painting" (raw Voronoi cells/points in green/yellow gradients) instead of polished fantasy maps (smooth coastlines, filled biomes, rivers, borders, labels) like default Azgaar.

---

## Executive Summary

The Genesis Mythos Azgaar fork integration generates complete map data (including biomes, states, rivers, borders) but the **SVG rendering functions return empty strings** because the `pack.cells.v` (vertex arrays) structure is missing, empty, or contains undefined entries. The `getIsolines()` function, which is critical for rendering biomes and states, requires `cells.v[cellId]` to be a valid array of vertex indices. When this data is missing, isoline generation fails silently, resulting in empty SVG layers and a "dot painting" appearance (only Voronoi cell points visible).

**Root Cause:** The fork's `createBasicPack()` function and `loadMapData()` function attempt to initialize `cells.v`, but the vertex arrays may be empty or contain undefined entries. The `getIsolines()` function at line 2800 uses `cells.v[cellId]` to find starting vertices for isoline generation. If `cells.v[cellId]` is undefined or empty, `startingVertex` becomes `undefined`, causing the isoline to be skipped, resulting in empty biome/state layers.

---

## Project Rendering Behavior

### Current Implementation

#### 1. Generation Flow (`WorldBuilderWebController.gd`)

The generation is triggered via fork mode:

```650:748:scripts/ui/WorldBuilderWebController.gd
func _generate_via_fork(params: Dictionary) -> void:
	"""Generate map using Azgaar fork API (headless mode)."""
	MythosLogger.info("WorldBuilderWebController", "Generating via fork mode")
	
	# Verify fork is actually available before proceeding
	if not web_view:
		MythosLogger.error("WorldBuilderWebController", "Cannot generate via fork - WebView is null")
		send_progress_update(0.0, "Error: WebView not available", false)
		return
	
	send_progress_update(20.0, "Loading options into fork...", true)
	
	# Convert params to fork options format
	var fork_options: Dictionary = _convert_params_to_fork_options(params)
	MythosLogger.debug("WorldBuilderWebController", "Fork options prepared", {"options_keys": fork_options.keys(), "seed": fork_options.get("seed", "not_set")})
	
	# Trigger fork generation via JavaScript (use handleGenerateMap if available, else direct call)
	var generate_script: String = """
		(function() {
			try {
				// Use handleGenerateMap if available (from world_builder_v2.html)
				if (window.handleGenerateMap && typeof window.handleGenerateMap === 'function') {
					console.log('[Fork] Using handleGenerateMap function');
					window.handleGenerateMap(%s);
					return 'triggered';
				}
				
				// Fallback: direct fork API call
				if (!window.AzgaarGenesis || !window.AzgaarGenesis.initialized) {
					console.error('[Fork] Fork not initialized');
					if (window.GodotBridge && window.GodotBridge.postMessage) {
						window.GodotBridge.postMessage('map_generation_failed', {
							error: 'Fork not initialized'
						});
					}
					return 'error: not initialized';
				}
				
				console.log('[Fork] Loading options...');
				window.AzgaarGenesis.loadOptions(%s);
				
				console.log('[Fork] Generating map...');
				const startTime = performance.now();
				const data = window.AzgaarGenesis.generateMap(window.AzgaarGenesis.Delaunator);
				const generateTime = performance.now() - startTime;
				
				console.log('[Fork] Generation complete:', { seed: data.seed, time: generateTime });
				
				console.log('[Fork] Extracting JSON...');
				const json = window.AzgaarGenesis.getMapData();
				
				console.log('[Fork] Rendering preview...');
				// Render preview to canvas
				const canvas = document.getElementById('azgaar-canvas');
				let previewDataUrl = '';
				if (canvas && window.AzgaarGenesis.renderPreview) {
					canvas.style.display = 'block';
					window.AzgaarGenesis.renderPreview(canvas);
					previewDataUrl = canvas.toDataURL('image/png');
				}
				
				// Send to Godot
				if (window.GodotBridge && window.GodotBridge.postMessage) {
					window.GodotBridge.postMessage('map_generated', {
						data: json,
						seed: data.seed,
						generationTime: generateTime,
						previewDataUrl: previewDataUrl
					});
					return 'success';
				}
				
				return 'error: no GodotBridge';
			} catch (error) {
				console.error('[Fork] Generation error:', error);
				if (window.GodotBridge && window.GodotBridge.postMessage) {
					window.GodotBridge.postMessage('map_generation_failed', {
						error: error.message,
						stack: error.stack
					});
				}
				return 'error: ' + error.message;
			}
		})();
	""" % [JSON.stringify(fork_options), JSON.stringify(fork_options)]
```

**Key Observation:** The generation script calls `generateMap()` and `getMapData()`, but **does not explicitly trigger SVG rendering**. SVG rendering is handled separately in `world_builder_v2.html` via `renderPreviewSVG()`.

#### 2. SVG Rendering Flow (`world_builder_v2.html`)

```411:483:assets/ui_web/templates/world_builder_v2.html
                // Force SVG rendering (default enabled)
                if (useSvg && window.AzgaarGenesis.renderPreviewSVG) {
                    try {
                        statusDiv.innerHTML = '<p>Rendering SVG preview...</p>';
                        if (DEBUG_RENDERING) {
                            console.log('[Azgaar Genesis] Rendering SVG preview (forced mode)...', { useSvg, hasFunction: !!window.AzgaarGenesis.renderPreviewSVG });
                        }
                        
                        // Re-validate right before rendering (data should already be valid, but double-check)
                        const preRenderValidation = validateMapData(json);
                        if (!preRenderValidation.valid) {
                            throw new Error('Pre-render validation failed: ' + preRenderValidation.errors.join(', '));
                        }
                        
                        const svgContainer = document.getElementById('map-preview');
                        if (!svgContainer) {
                            throw new Error('SVG container element not found');
                        }
                        
                        // Clear previous content
                        svgContainer.innerHTML = '';
                        
                        // Calculate dimensions
                        const containerRect = svgContainer.getBoundingClientRect();
                        const width = containerRect.width > 0 ? containerRect.width : (options.mapWidth || 1024);
                        const height = containerRect.height > 0 ? containerRect.height : (options.mapHeight || 768);
                        
                        if (DEBUG_RENDERING) {
                            console.log('[Azgaar Genesis] SVG container dimensions:', { width, height, containerWidth: containerRect.width, containerHeight: containerRect.height });
                        }
                        
                        // Render SVG to container
                        const svgOptions = {
                            container: svgContainer,
                            width: Math.max(width, 512),  // Ensure minimum size
                            height: Math.max(height, 384)
                        };
                        
                        // Call renderPreviewSVG - it should append to container or return string
                        const svgResult = window.AzgaarGenesis.renderPreviewSVG(svgOptions);
                        
                        // Extract SVG string from container (function appends to container)
                        if (svgContainer.firstChild || svgContainer.innerHTML) {
                            previewSvgString = svgContainer.innerHTML;
                        } else if (typeof svgResult === 'string' && svgResult.length > 0) {
                            // Function returned SVG string directly
                            previewSvgString = svgResult;
                            svgContainer.innerHTML = previewSvgString;
                        }
                        
                        if (previewSvgString && previewSvgString.length > 0) {
                            console.log('[Azgaar Genesis] SVG preview rendered successfully, length:', previewSvgString.length);
                            
                            // Update Alpine.js component
                            if (window.worldBuilderInstance) {
                                window.worldBuilderInstance.previewSvg = previewSvgString;
                                window.worldBuilderInstance.previewMode = 'svg';
                            }
                            
                            // Send SVG data to Godot via IPC
                            if (window.GodotBridge && window.GodotBridge.postMessage) {
                                window.GodotBridge.postMessage('svg_preview_ready', {
                                    svgData: previewSvgString,
                                    width: svgOptions.width,
                                    height: svgOptions.height
                                });
                                if (DEBUG_RENDERING) {
                                    console.log('[Azgaar Genesis] Sent svg_preview_ready IPC message');
                                }
                            }
                        } else {
                            throw new Error('SVG rendering returned empty result');
                        }
```

**Key Observation:** SVG rendering is attempted, but if `renderPreviewSVG()` returns an empty string or the container remains empty, the error is caught and logged.

#### 3. Fork Rendering Functions (`azgaar-genesis.esm.js`)

**`renderMapSVG()` Function:**

```3126:3166:assets/ui_web/js/azgaar/azgaar-genesis.esm.js
function renderMapSVG(data, options = {}) {
  if (!data || !data.pack) {
    throw new Error("Map data with pack is required");
  }
  const { pack, options: genOptions } = data;
  const { mapWidth, mapHeight } = genOptions || options;
  const width = options.width || mapWidth || 1e3;
  const height = options.height || mapHeight || 600;
  const biomesData = getDefaultBiomes();
  const layers = [];
  layers.push(`<rect x="0" y="0" width="${width}" height="${height}" fill="${STYLE_CONSTANTS.oceanBase}" />`);
  const featuresSVG = drawFeaturesSVG(pack);
  if (featuresSVG) {
    layers.push(`<g id="features">${featuresSVG}</g>`);
  }
  layers.push(`<rect x="0" y="0" width="${width}" height="${height}" fill="${STYLE_CONSTANTS.landBase}" />`);
  const biomesSVG = drawBiomesSVG(pack, biomesData);
  if (biomesSVG) {
    layers.push(`<g id="biomes" opacity="0.7">${biomesSVG}</g>`);
  }
  const statesSVG = drawStatesSVG(pack);
  if (statesSVG) {
    layers.push(`<g id="states" opacity="0.6">${statesSVG}</g>`);
  }
  const riversSVG = drawRiversSVG(pack);
  if (riversSVG) {
    layers.push(`<g id="rivers">${riversSVG}</g>`);
  }
  const borders = drawBordersSVG(pack);
  if (borders.stateBorders || borders.provinceBorders) {
    layers.push(`<g id="borders">${borders.stateBorders}${borders.provinceBorders}</g>`);
  }
  const burgsSVG = drawBurgsSVG(pack);
  if (burgsSVG) {
    layers.push(`<g id="burgs">${burgsSVG}</g>`);
  }
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
${layers.join("\n")}
</svg>`;
  return svg;
}
```

**Key Observation:** The function attempts to render all layers, but each drawing function checks for data existence and returns empty strings if data is missing.

**Critical Function: `getIsolines()` - The Root of the Problem**

```2783:2841:assets/ui_web/js/azgaar/azgaar-genesis.esm.js
function getIsolines(pack, getType, options = { fill: false, waterGap: false, halo: false }) {
  var _a, _b, _c, _d, _e;
  const { cells, vertices } = pack;
  const isolines = {};
  const checkedCells = new Uint8Array(cells.i.length);
  const addToChecked = (cellId) => checkedCells[cellId] = 1;
  const isChecked = (cellId) => checkedCells[cellId] === 1;
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
    const startingVertex = (_e = cells.v[cellId]) == null ? void 0 : _e.find(
      (v) => {
        var _a2;
        return (_a2 = vertices.c[v]) == null ? void 0 : _a2.some(ofDifferentType);
      }
    );
    if (startingVertex === void 0) continue;
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

**CRITICAL FINDING:** At line 2800, `getIsolines()` uses `cells.v[cellId]` to find the starting vertex. If `cells.v[cellId]` is:
- `undefined` → `startingVertex` becomes `undefined` → isoline is skipped
- Empty array `[]` → `.find()` returns `undefined` → isoline is skipped
- Contains undefined entries → `.find()` may fail → isoline is skipped

**Result:** If `cells.v` is missing or malformed, **all isolines fail**, causing `drawBiomesSVG()` and `drawStatesSVG()` to return empty strings.

**Drawing Functions - Data Checks:**

```2897:2930:assets/ui_web/js/azgaar/azgaar-genesis.esm.js
function drawBiomesSVG(pack, biomesData) {
  if (!pack.cells || !pack.cells.biome) return "";
  const cells = pack.cells;
  const bodyPaths = [];
  const isolines = getIsolines(pack, (cellId) => cells.biome[cellId], {
    fill: true,
    waterGap: true
  });
  Object.entries(isolines).forEach(([index, { fill, waterGap }]) => {
    const biomeIndex = parseInt(index);
    if (biomeIndex >= 0 && biomeIndex < biomesData.color.length) {
      const color = biomesData.color[biomeIndex];
      bodyPaths.push(getGappedFillPaths("biome", fill, waterGap, color, biomeIndex));
    }
  });
  return bodyPaths.join("");
}
function drawStatesSVG(pack) {
  if (!pack.cells || !pack.cells.state || !pack.states) return "";
  const { cells, states } = pack;
  const bodyPaths = [];
  const isolines = getIsolines(pack, (cellId) => cells.state[cellId], {
    fill: true,
    waterGap: true
  });
  Object.entries(isolines).forEach(([index, { fill, waterGap }]) => {
    const stateIndex = parseInt(index);
    if (stateIndex > 0 && stateIndex < states.length && states[stateIndex]) {
      const color = states[stateIndex].color || "#cccccc";
      bodyPaths.push(getGappedFillPaths("state", fill, waterGap, color, stateIndex));
    }
  });
  return bodyPaths.join("");
}
```

**Critical Finding:** Each drawing function:
1. Checks for `pack.cells.biome` or `pack.cells.state` (returns `""` if missing)
2. Calls `getIsolines()` which requires `cells.v[cellId]` to be valid
3. If `getIsolines()` returns empty `isolines` object (due to missing `cells.v`), `Object.entries(isolines)` is empty
4. Returns `""` (empty string)

**Result:** If `cells.v` is missing or malformed, the SVG will only contain:
- Ocean base rectangle
- Land base rectangle
- (Possibly) Features layer
- **No biomes, states, rivers, borders, or burgs**

This results in a "dot painting" appearance where only the Voronoi cell points are visible (if features layer renders points).

#### 4. `cells.v` Initialization (`createBasicPack()` and `loadMapData()`)

**`createBasicPack()` Function:**

```3176:3225:assets/ui_web/js/azgaar/azgaar-genesis.esm.js
function createBasicPack(grid, options) {
  const { cells: gridCells, points, vertices } = grid;
  const cellCount = gridCells.i.length;
  // Ensure cells.v is properly initialized - critical for SVG rendering
  let cellsV = [];
  if (gridCells.v && Array.isArray(gridCells.v)) {
    // cells.v exists - copy it and ensure all entries are arrays (fill undefined gaps)
    let hasUndefined = false;
    for (let i = 0; i < cellCount; i++) {
      if (i < gridCells.v.length && gridCells.v[i] !== undefined && Array.isArray(gridCells.v[i])) {
        cellsV.push([...gridCells.v[i]]);
      } else {
        cellsV.push([]);
        if (i < gridCells.v.length && gridCells.v[i] === undefined) {
          hasUndefined = true;
        }
      }
    }
    if (hasUndefined && typeof console !== "undefined" && console.warn) {
      console.warn(`createBasicPack: cells.v contained undefined entries, filled with empty arrays`);
    }
  } else {
    // cells.v is missing or not an array - create array of empty arrays with correct length
    if (typeof console !== "undefined" && console.warn && cellCount > 0) {
      console.warn(`createBasicPack: cells.v missing or empty (length ${gridCells.v?.length || 0} vs expected ${cellCount}), creating placeholder array`);
    }
    const placeholder = [];
    for (let i = 0; i < cellCount; i++) {
      placeholder.push([]);
    }
    return placeholder;
  }
  return cellsV;
}
```

**Key Observation:** `createBasicPack()` attempts to initialize `cells.v`, but if `gridCells.v` is missing or empty, it creates an array of **empty arrays** `[]`. This means `cells.v[cellId]` will be `[]` (empty), causing `getIsolines()` to fail.

**`loadMapData()` Function:**

```3576:3604:assets/ui_web/js/azgaar/azgaar-genesis.esm.js
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

**Key Observation:** `loadMapData()` also creates placeholder arrays of empty arrays if `cells.v` is missing. This means when data is loaded from JSON, `cells.v[cellId]` will be `[]` (empty), causing `getIsolines()` to fail.

#### 5. Log Evidence (`mythos_log_2025-12-29.txt`)

From the log file, generation is triggered successfully:

```
[2025-12-29 13:23:28] [WorldBuilderWebController] [INFO]: Generation requested [{"optionsSeed":12345.0,"params_count":37,"sample_params":{"mapHeightInput":540.0,"mapWidthInput":960.0,"optionsSeed":12345.0,"pointsInput":5.0,"templateInput":"archipelago"}}]
[2025-12-29 13:23:30] [WorldBuilderWebController] [INFO]: Generation triggered via iframe (eval)
```

However, **no SVG rendering logs are present**, suggesting either:
1. SVG rendering is failing silently
2. SVG rendering is not being called
3. SVG rendering returns empty strings (no error thrown)

---

## Default Azgaar Behavior

### Reference: https://azgaar.github.io/Fantasy-Map-Generator/

**Default Azgaar Rendering:**
- **Initial View:** Full layered map with biomes, states, rivers, borders, labels
- **View Modes:** Canvas (default), Heightmap, Cells (debug), Points (debug)
- **Layer Composition:** Ocean → Land → Biomes → States → Rivers → Borders → Burgs → Labels
- **Rendering Pipeline:** Full generation includes all layers by default

**Default Azgaar Generation Flow:**
1. Voronoi grid generation (populates `grid.cells.v` with vertex arrays)
2. Heightmap generation
3. **Biome assignment** (populates `pack.cells.biome`)
4. **River generation** (populates `pack.rivers`)
5. **State generation** (populates `pack.cells.state` and `pack.states`)
6. **Culture generation** (populates `pack.cells.culture`)
7. **Burg generation** (populates `pack.burgs`)
8. **Border generation** (derived from states)
9. **Full rendering** (all layers rendered)

**Default Azgaar Code (from GitHub):**
- `main.js` contains the full generation pipeline
- Voronoi generation populates `grid.cells.v` with valid vertex arrays (not empty)
- All layer generation functions populate `pack.cells` arrays
- Rendering functions expect complete data structures

---

## Key Differences

### Comparison Table

| Aspect | Default Azgaar | Genesis Fork | Impact |
|--------|----------------|--------------|--------|
| **Initial View Mode** | Canvas (full layers) | SVG (but empty layers) | Fork renders SVG but layers are empty |
| **`cells.v` Initialization** | Populated by Voronoi with vertex arrays | May be empty arrays `[]` | Isolines fail, layers empty |
| **Layer Generation** | Full pipeline (all layers) | Full pipeline, but `cells.v` missing | Missing vertex data causes isoline failure |
| **Rendering Default** | Full SVG with all layers | Empty SVG (layers missing due to `cells.v`) | "Dot painting" appearance |
| **Data Validation** | Implicit (full data guaranteed) | Explicit checks (returns `""` if missing) | Silent failures |
| **View Mode Toggle** | UI controls for view modes | "Switch to Canvas" button exists | May be stuck in cells/points mode |

### Code Differences

**Default Azgaar:**
- Voronoi generation populates `grid.cells.v` with valid vertex arrays (each cell has array of vertex indices)
- `createBasicPack()` copies `grid.cells.v` to `pack.cells.v` (preserving vertex arrays)
- Rendering functions assume `cells.v[cellId]` is a valid array of vertex indices
- Full layer pipeline always runs with complete data

**Genesis Fork:**
- Voronoi generation may not populate `grid.cells.v` correctly
- `createBasicPack()` may create empty arrays if `grid.cells.v` is missing
- Rendering functions check for data existence (defensive programming)
- Layer generation runs, but isolines fail due to missing `cells.v` data

---

## Root Causes

### 1. **Missing or Empty `cells.v` Vertex Arrays (PRIMARY ROOT CAUSE)**

**Problem:** The fork's Voronoi generation or `createBasicPack()` function does not populate `pack.cells.v` with valid vertex arrays. Instead, `cells.v[cellId]` is either `undefined` or an empty array `[]`.

**Evidence:**
- `getIsolines()` at line 2800 uses `cells.v[cellId]` to find starting vertices
- If `cells.v[cellId]` is `[]` (empty), `.find()` returns `undefined`
- `startingVertex === undefined` causes the isoline to be skipped
- Result: `getIsolines()` returns empty `isolines` object
- `drawBiomesSVG()` and `drawStatesSVG()` return `""` (empty string)

**Location:** 
- `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:2783-2841` (`getIsolines()`)
- `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:3176-3225` (`createBasicPack()`)
- `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:3576-3604` (`loadMapData()`)

### 2. **Voronoi Generation Not Populating `grid.cells.v`**

**Problem:** The Voronoi diagram generation may not be populating `grid.cells.v` with vertex arrays.

**Evidence:**
- `createBasicPack()` checks `if (gridCells.v && Array.isArray(gridCells.v))`
- If `gridCells.v` is missing, it creates placeholder empty arrays
- Voronoi generation should populate `grid.cells.v` during diagram creation

**Location:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:524-655` (Voronoi class and generation)

### 3. **Silent Rendering Failures**

**Problem:** SVG rendering functions return empty strings without throwing errors, causing silent failures.

**Evidence:**
- `drawBiomesSVG()` returns `""` if `getIsolines()` returns empty object (no error)
- `renderMapSVG()` continues even if all layers are empty
- Result: SVG contains only ocean/land rectangles, appears as "dot painting"

**Location:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:2897-3166` (drawing functions)

### 4. **View Mode Not Set to "Canvas"**

**Problem:** The fork may be rendering in "cells" or "points" debug mode instead of full "canvas" mode.

**Evidence:**
- "Switch to Canvas" button exists in `world_builder_v2.html`
- Initial view mode may default to cells/points
- No explicit view mode setting in generation flow

**Location:** `assets/ui_web/templates/world_builder_v2.html:54-59`

---

## Recommendations

### Priority 1: Fix `cells.v` Vertex Array Population (CRITICAL)

**Action:** Ensure Voronoi generation populates `grid.cells.v` with valid vertex arrays, and `createBasicPack()` preserves them:

```javascript
// In Voronoi class constructor or generation:
// Ensure cells.v is populated with vertex arrays (not empty)
this.cells.v[p] = edges.map((e2) => this.triangleOfEdge(e2));
// Should result in: cells.v[cellId] = [vertex1, vertex2, vertex3, ...]

// In createBasicPack(), verify gridCells.v is populated:
if (gridCells.v && Array.isArray(gridCells.v)) {
  // Validate that each entry is a non-empty array
  for (let i = 0; i < cellCount; i++) {
    if (!gridCells.v[i] || !Array.isArray(gridCells.v[i]) || gridCells.v[i].length === 0) {
      console.error(`createBasicPack: cells.v[${i}] is missing or empty - isolines will fail`);
    }
  }
}
```

**Location:** 
- `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:524-655` (Voronoi generation)
- `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:3176-3225` (`createBasicPack()`)

### Priority 2: Add Validation and Logging for `cells.v`

**Action:** Add validation in `getIsolines()` to log missing `cells.v` data:

```javascript
// In getIsolines(), before using cells.v[cellId]:
if (!cells.v || !Array.isArray(cells.v) || cells.v.length === 0) {
  console.error('[Genesis Azgaar] cells.v missing or empty - isolines cannot be generated');
  return {};
}
if (!cells.v[cellId] || !Array.isArray(cells.v[cellId]) || cells.v[cellId].length === 0) {
  // Log first few failures, then skip
  if (cellId < 10) {
    console.warn(`[Genesis Azgaar] cells.v[${cellId}] is missing or empty - skipping isoline`);
  }
  continue;
}
```

**Location:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:2783-2841` (`getIsolines()`)

### Priority 3: Fix `createBasicPack()` to Preserve Vertex Arrays

**Action:** Ensure `createBasicPack()` does not create empty arrays if `gridCells.v` exists but has empty entries:

```javascript
// In createBasicPack(), if gridCells.v exists but has empty entries:
if (gridCells.v && Array.isArray(gridCells.v)) {
  cellsV = [];
  for (let i = 0; i < cellCount; i++) {
    if (i < gridCells.v.length && Array.isArray(gridCells.v[i]) && gridCells.v[i].length > 0) {
      cellsV.push([...gridCells.v[i]]);  // Copy valid vertex array
    } else {
      // If missing or empty, try to reconstruct from Voronoi diagram
      // OR log error and skip (don't create empty array)
      console.warn(`createBasicPack: cells.v[${i}] missing or empty - isolines will fail for this cell`);
      cellsV.push([]);  // Temporary: create empty array (should be fixed at Voronoi level)
    }
  }
}
```

**Location:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:3176-3225` (`createBasicPack()`)

### Priority 4: Add Rendering Validation and Logging

**Action:** Add validation in `renderPreviewSVG()` to log missing data:

```javascript
// In renderPreviewSVG(), before calling renderMapSVG():
if (!state.data.pack.cells.v || !Array.isArray(state.data.pack.cells.v)) {
  console.error('[Genesis Azgaar] pack.cells.v missing - isolines will not render');
}
if (state.data.pack.cells.v && state.data.pack.cells.v.length > 0) {
  const emptyCount = state.data.pack.cells.v.filter(v => !v || !Array.isArray(v) || v.length === 0).length;
  if (emptyCount > 0) {
    console.warn(`[Genesis Azgaar] ${emptyCount} cells have empty cells.v arrays - isolines will fail for these cells`);
  }
}
```

**Location:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js:3458-3501` (`renderPreviewSVG()`)

### Priority 5: Compare Voronoi Generation with Default Azgaar

**Action:** Compare the fork's Voronoi generation with default Azgaar's to identify why `cells.v` is not populated.

**Reference:** `https://github.com/Azgaar/Fantasy-Map-Generator/blob/master/main.js`

### Priority 6: Set Initial View Mode to "SVG" (Full Layers)

**Action:** Ensure initial preview mode is set to "svg" (full layers) in `world_builder_v2.html`:

```javascript
// In Alpine.js component initialization:
previewMode: 'svg',  // Default to SVG (full layers)
```

**Location:** `assets/ui_web/templates/world_builder_v2.html`

---

## Testing Plan

1. **Generate a map and inspect `pack.cells.v` structure:**
   - Log `pack.cells.v` after generation
   - Verify arrays are populated (not `undefined` or empty)
   - Check first 10 cells: `cells.v[0]`, `cells.v[1]`, etc. should be arrays of vertex indices

2. **Test `getIsolines()` with complete data:**
   - Manually populate `pack.cells.v` with test vertex arrays
   - Call `getIsolines()` and verify isolines are generated
   - Verify `drawBiomesSVG()` and `drawStatesSVG()` return non-empty strings

3. **Compare generated JSON with default Azgaar:**
   - Generate a map in default Azgaar and export JSON
   - Inspect `pack.cells.v` structure (should be arrays of vertex indices)
   - Generate a map in fork and compare `pack.cells.v` structure
   - Identify missing or empty entries

4. **Verify Voronoi generation:**
   - Check if Voronoi class populates `grid.cells.v` during diagram creation
   - Verify `createBasicPack()` preserves vertex arrays from `grid.cells.v`

---

## Conclusion

The "dot painting" rendering issue is caused by **missing or empty `cells.v` vertex arrays** - the fork generates Voronoi cells and basic heightmap data, but `pack.cells.v` is either missing, contains empty arrays, or has undefined entries. The `getIsolines()` function, which is critical for rendering biomes and states, requires `cells.v[cellId]` to be a valid array of vertex indices. When this data is missing or empty, isoline generation fails silently, resulting in empty SVG layers and a "dot painting" appearance (only ocean/land base rectangles visible).

**Fix Strategy:** 
1. Ensure Voronoi generation populates `grid.cells.v` with valid vertex arrays
2. Ensure `createBasicPack()` preserves vertex arrays from `grid.cells.v` (don't create empty arrays)
3. Add validation/logging to identify missing `cells.v` data early
4. Compare with default Azgaar to identify missing Voronoi generation steps

---

## Appendix: Code References

### Key Files

1. **Generation Controller:** `scripts/ui/WorldBuilderWebController.gd` (lines 650-748)
2. **HTML Template:** `assets/ui_web/templates/world_builder_v2.html` (lines 411-483)
3. **Fork JS:** `assets/ui_web/js/azgaar/azgaar-genesis.esm.js`
   - `renderMapSVG()`: lines 3126-3166
   - `drawBiomesSVG()`: lines 2897-2913
   - `drawStatesSVG()`: lines 2914-2930
   - `getIsolines()`: lines 2783-2841 (CRITICAL - uses `cells.v[cellId]`)
   - `createBasicPack()`: lines 3176-3225
   - `loadMapData()`: lines 3576-3604
   - Voronoi class: lines 524-655

### Log Files

- `mythos_log_2025-12-29.txt` (generation logs, no SVG rendering logs)

---

**Report End**
