# Azgaar Fork Migration Plan
## From Original Azgaar to Genesis-Azgaar Modular Fork

**Date:** 2025-12-29  
**Status:** Planning Phase  
**Target:** Complete migration from `res://tools/azgaar/` (original) to `res://assets/ui_web/js/azgaar/` (fork bundles)

---

## Executive Summary

### Current State
- **Source:** Original Azgaar FMG bundled in `res://tools/azgaar/` (flat structure: `index.html`, `main.js`, etc.)
- **Integration:** Full web app loaded in iframe via `http://127.0.0.1:8080/index.html` (AzgaarServer)
- **Communication:** postMessage-based with injected listeners (fragile, CORS issues)
- **Data Export:** Manual scraping via `execute_js()` to extract heightmaps/data

### Target State
- **Source:** Custom fork bundles from `https://github.com/L0RDTH0TH/Genesis-Azgaar`
- **Integration:** Modular library (ESM/UMD) loaded directly in WebView HTML
- **Communication:** Programmatic API (`initGenerator`, `loadOptions`, `generateMap`, `getMapData`, `renderPreview`)
- **Data Export:** Structured JSON via `getMapData()` → IPC postMessage to Godot

### Benefits
- ✅ **Reliable IPC:** No CORS issues, no iframe complexity
- ✅ **Structured Data:** Clean JSON export optimized for Godot
- ✅ **Headless Mode:** Can generate without canvas rendering
- ✅ **Better Performance:** Smaller bundle, no full UI overhead
- ✅ **Maintainable:** Modular codebase, easier to extend

---

## 1. Fork Repository Analysis

### 1.1 Repository Structure
- **Location:** `/home/darth/Azgaar-Genesis/azgaar-genesis-fork`
- **Remote:** `https://github.com/L0RDTH0TH/Genesis-Azgaar.git`
- **Branch:** `main`
- **Status:** Phase 3 Complete (Production Ready)

### 1.2 Build Output
```
dist/
├── azgaar-genesis.esm.js      (110.54 kB, gzip: 26.14 kB)
├── azgaar-genesis.esm.js.map  (257.54 kB)
├── azgaar-genesis.umd.js      (117.88 kB, gzip: 26.71 kB)
├── azgaar-genesis.umd.js.map  (258.24 kB)
└── azgaar-genesis.min.js      (53.84 kB, gzip: 19.62 kB)
```

### 1.3 Dependencies
- **Peer Dependencies:** `d3@^7.0.0`, `delaunator@^5.0.0` (not bundled, must be provided)
- **Build Tool:** Vite 5.0.0
- **Module Format:** ESM (recommended) or UMD (fallback)

### 1.4 Public API
```javascript
import { 
  initGenerator,    // Initialize with optional canvas
  loadOptions,       // Load curated params from Godot
  generateMap,       // Generate map data (requires Delaunator)
  getMapData,        // Get structured JSON for Godot
  renderPreview      // Render to canvas (optional)
} from 'azgaar-genesis';
```

---

## 2. Current Integration Analysis

### 2.1 File Structure
```
res://
├── tools/azgaar/              # Original Azgaar bundle (TO BE REPLACED)
│   ├── index.html
│   ├── main.js
│   └── ...
├── assets/ui_web/
│   ├── templates/
│   │   └── world_builder.html # Current UI with iframe
│   └── js/
│       └── world_builder.js   # Alpine.js controller
└── scripts/
    ├── managers/
    │   ├── AzgaarIntegrator.gd  # Copies bundle to user://
    │   └── AzgaarServer.gd       # HTTP server for iframe
    └── ui/
        ├── WorldBuilderWebController.gd  # WebView controller
        └── WorldBuilderAzgaar.gd        # Legacy Azgaar integration
```

### 2.2 Current Communication Flow
```
Alpine.js UI (world_builder.html)
    ↓
world_builder.js: generate()
    ↓
postMessage to iframe (azgaar-iframe)
    ↓
Injected Listener in Azgaar iframe
    ↓
Object.assign(azgaar.options, params)
    ↓
azgaar.generate()
    ↓
Manual scraping via execute_js() to get data
```

### 2.3 Issues with Current Approach
- ❌ **CORS Problems:** Cross-origin iframe communication unreliable
- ❌ **Timing Issues:** Listener injection may fail silently
- ❌ **Fragile:** Depends on Azgaar's internal structure
- ❌ **No Structured Export:** Manual scraping of heightmaps/data
- ❌ **Full UI Overhead:** Loads entire Azgaar web app

---

## 3. Migration Plan

### Phase 1: Setup & Bundle Preparation ✅

#### 3.1.1 Copy Fork Bundles
**Action:** Copy built bundles from fork to project
```bash
# Source: /home/darth/Azgaar-Genesis/azgaar-genesis-fork/dist/
# Target: res://assets/ui_web/js/azgaar/
```

**Files to Copy:**
- `azgaar-genesis.esm.js` (primary, for ES modules)
- `azgaar-genesis.umd.js` (fallback for non-ESM contexts)
- `azgaar-genesis.min.js` (production minified)

**New Directory Structure:**
```
res://assets/ui_web/
├── js/
│   ├── azgaar/
│   │   ├── azgaar-genesis.esm.js
│   │   ├── azgaar-genesis.umd.js
│   │   └── azgaar-genesis.min.js
│   └── world_builder.js (existing)
└── templates/
    └── world_builder.html (to be modified)
```

#### 3.1.2 Add Delaunator Dependency
**Option A:** CDN (Recommended for WebView)
```html
<script type="module">
  import Delaunator from 'https://cdn.jsdelivr.net/npm/delaunator@5.0.1/+esm';
</script>
```

**Option B:** Local Bundle
- Download `delaunator.min.js` to `res://assets/ui_web/js/azgaar/`
- Use `<script src="res://assets/ui_web/js/azgaar/delaunator.min.js">`

**Recommendation:** Use CDN for now (simpler), switch to local if needed.

#### 3.1.3 Optional: D3 Dependency
**Note:** Fork uses D3 for some utilities, but may work without it for basic generation.
- **Test first without D3** (headless JSON generation)
- **Add D3 later** if rendering features require it

---

### Phase 2: HTML Template Migration

#### 3.2.1 Create New World Builder Template
**File:** `res://assets/ui_web/templates/world_builder_v2.html` (prototype first)

**Key Changes:**
1. **Remove iframe:** Replace `<iframe id="azgaar-iframe">` with `<canvas id="azgaar-canvas">` (optional)
2. **Import Library:** Add ES module import for fork
3. **Initialize Generator:** Call `initGenerator()` on Alpine.js ready
4. **Handle IPC:** Listen for `generate_map` messages from Godot
5. **Send JSON:** Post `map_generated` message back to Godot

**Template Structure:**
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>World Builder - Genesis Mythos</title>
    <link rel="stylesheet" href="../css/world_builder.css">
    <script defer src="../js/alpine.min.js"></script>
</head>
<body>
    <div class="world-builder-container" x-data="worldBuilder">
        <!-- Existing UI: Left tabs, right params -->
        
        <!-- Center Panel: Canvas (optional preview) or hidden for headless -->
        <div class="center-panel">
            <canvas id="azgaar-canvas" style="width:100%; height:100%; display:none;"></canvas>
            <div id="azgaar-status" style="padding: 1rem; text-align: center; color: #aaa;">
                Ready to generate map...
            </div>
        </div>
    </div>

    <script type="module">
        // Import Delaunator (peer dependency)
        import Delaunator from 'https://cdn.jsdelivr.net/npm/delaunator@5.0.1/+esm';
        
        // Import Azgaar Genesis library
        import { 
            initGenerator, 
            loadOptions, 
            generateMap, 
            getMapData, 
            renderPreview 
        } from '../js/azgaar/azgaar-genesis.esm.js';

        // Initialize generator (headless mode - no canvas)
        const canvas = document.getElementById('azgaar-canvas');
        initGenerator({ canvas: null }); // null = headless mode
        
        // Store generator functions globally for Alpine.js access
        window.AzgaarGenesis = {
            Delaunator,
            loadOptions,
            generateMap,
            getMapData,
            renderPreview
        };
        
        // Listen for IPC messages from Godot
        if (window.GodotBridge && window.GodotBridge.onMessage) {
            window.GodotBridge.onMessage((message) => {
                if (message.type === 'generate_map') {
                    handleGenerateMap(message.options);
                }
            });
        }
        
        async function handleGenerateMap(options) {
            try {
                const statusDiv = document.getElementById('azgaar-status');
                statusDiv.textContent = 'Generating map...';
                
                // Load options from Godot
                loadOptions(options);
                
                // Generate map
                const data = generateMap(Delaunator);
                
                // Get structured JSON
                const json = getMapData();
                
                // Send back to Godot via IPC
                if (window.GodotBridge && window.GodotBridge.postMessage) {
                    window.GodotBridge.postMessage('map_generated', {
                        data: json,
                        seed: data.seed
                    });
                }
                
                statusDiv.textContent = `Map generated (seed: ${data.seed})`;
            } catch (error) {
                console.error('Map generation error:', error);
                if (window.GodotBridge && window.GodotBridge.postMessage) {
                    window.GodotBridge.postMessage('map_generation_failed', {
                        error: error.message
                    });
                }
            }
        }
    </script>
    
    <script src="../js/world_builder.js"></script>
</body>
</html>
```

---

### Phase 3: GDScript Integration Updates

#### 3.3.1 Update WorldBuilderWebController.gd

**Changes Required:**

1. **Remove iframe-related code:**
   - Remove `IFRAME_ID` constant
   - Remove `azgaar_ready_via_iframe` flag
   - Remove `azgaar_readiness_timer` and polling logic
   - Remove `_setupAzgaarListener()` and related methods

2. **Add new generation handler:**
```gdscript
func _handle_generate_map(params: Dictionary) -> void:
	"""Handle map generation request from Alpine.js UI."""
	MythosLogger.info("WorldBuilderWebController", "Generating map with fork API", {"params": params})
	
	# Convert GDScript params to JavaScript options format
	var js_options: Dictionary = _convert_params_to_azgaar_options(params)
	
	# Send generate command to WebView
	var message: Dictionary = {
		"type": "generate_map",
		"options": js_options
	}
	
	# Use execute_js to call handleGenerateMap directly, or postMessage
	if web_view and web_view.has_method("execute_js"):
		var js_code: String = "handleGenerateMap(%s);" % JSON.stringify(message.options)
		web_view.execute_js(js_code)
	else:
		# Fallback: use IPC postMessage
		if web_view and web_view.has_method("post_message"):
			web_view.post_message(JSON.stringify(message))

func _convert_params_to_azgaar_options(params: Dictionary) -> Dictionary:
	"""Convert Genesis Mythos parameter format to Azgaar Genesis options format."""
	var options: Dictionary = {}
	
	# Map parameter keys (example - full mapping needed)
	if params.has("templateInput"):
		options["template"] = params["templateInput"]
	if params.has("pointsInput"):
		options["cellsDesired"] = int(params["pointsInput"])
	if params.has("mapWidthInput"):
		options["mapWidth"] = int(params["mapWidthInput"])
	if params.has("mapHeightInput"):
		options["mapHeight"] = int(params["mapHeightInput"])
	if params.has("optionsSeed"):
		options["seed"] = str(params["optionsSeed"])
	# ... map all parameters
	
	return options
```

3. **Add IPC handler for map_generated:**
```gdscript
func _on_ipc_message(message: String) -> void:
	"""Handle IPC messages from WebView."""
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(message)
	if parse_result != OK:
		MythosLogger.warn("WorldBuilderWebController", "Failed to parse IPC message", {"error": parse_result})
		return
	
	var data: Dictionary = json.data
	var msg_type: String = data.get("type", "")
	
	match msg_type:
		"map_generated":
			_handle_map_generated(data)
		"map_generation_failed":
			_handle_map_generation_failed(data)
		# ... other message types

func _handle_map_generated(data: Dictionary) -> void:
	"""Handle successful map generation from fork."""
	MythosLogger.info("WorldBuilderWebController", "Map generated successfully", {
		"seed": data.get("seed", ""),
		"data_size": str(data.get("data", {})).length()
	})
	
	var map_data: Dictionary = data.get("data", {})
	
	# Emit signal or call downstream system
	if has_signal("map_generated"):
		emit_signal("map_generated", map_data)
	
	# Forward to Terrain3DManager or other systems
	_forward_map_data_to_terrain(map_data)

func _handle_map_generation_failed(data: Dictionary) -> void:
	"""Handle map generation failure."""
	var error_msg: String = data.get("error", "Unknown error")
	MythosLogger.error("WorldBuilderWebController", "Map generation failed", {"error": error_msg})
	
	# Show error in UI
	if web_view and web_view.has_method("execute_js"):
		var js_code: String = """
			if (window.worldBuilderInstance) {
				window.worldBuilderInstance.errorMessage = 'Map generation failed';
				window.worldBuilderInstance.errorDetails = '%s';
			}
		""" % error_msg.replace("'", "\\'")
		web_view.execute_js(js_code)
```

#### 3.3.2 Update world_builder.js

**Changes Required:**

1. **Remove iframe-related code:**
   - Remove `_setupAzgaarListener()`
   - Remove `_waitForAzgaarReady()`
   - Remove `_injectAzgaarListener()`
   - Remove postMessage to iframe logic

2. **Update generate() function:**
```javascript
async generate() {
    try {
        this.isGenerating = true;
        this.progressValue = 0;
        this.statusText = 'Preparing generation...';
        
        // Collect all parameters
        const allParams = this._collectAllParams();
        
        // Send to Godot, which will forward to Azgaar Genesis
        if (window.GodotBridge && window.GodotBridge.postMessage) {
            window.GodotBridge.postMessage('generate_map', {
                params: allParams
            });
        } else {
            // Fallback: call directly if GodotBridge not available
            if (window.AzgaarGenesis) {
                await this._generateDirectly(allParams);
            }
        }
    } catch (error) {
        console.error('[Genesis World Builder] Generation error:', error);
        this.errorMessage = 'Generation failed';
        this.errorDetails = error.message;
    } finally {
        this.isGenerating = false;
    }
}

async _generateDirectly(params) {
    const { Delaunator, loadOptions, generateMap, getMapData } = window.AzgaarGenesis;
    
    this.statusText = 'Loading options...';
    loadOptions(this._convertParamsToOptions(params));
    
    this.statusText = 'Generating map...';
    const data = generateMap(Delaunator);
    
    this.statusText = 'Extracting data...';
    const json = getMapData();
    
    // Send to Godot
    if (window.GodotBridge && window.GodotBridge.postMessage) {
        window.GodotBridge.postMessage('map_generated', {
            data: json,
            seed: data.seed
        });
    }
    
    this.statusText = `Map generated (seed: ${data.seed})`;
}

_convertParamsToOptions(params) {
    // Convert Alpine.js params to Azgaar Genesis options format
    return {
        seed: String(params.optionsSeed || Date.now()),
        mapWidth: parseInt(params.mapWidthInput || 960),
        mapHeight: parseInt(params.mapHeightInput || 540),
        cellsDesired: parseInt(params.pointsInput || 10000),
        template: params.templateInput || 'continents',
        // ... map all parameters
    };
}
```

---

### Phase 4: Deprecate Old Systems

#### 3.4.1 AzgaarIntegrator.gd
**Action:** Update to handle fork bundles instead of original bundle
- Change `AZGAAR_BUNDLE_PATH` to point to new location (or remove if not needed)
- Remove `copy_azgaar_to_user()` if bundles are loaded directly from `res://`
- Keep `get_azgaar_http_url()` only if still needed for other purposes

#### 3.4.2 AzgaarServer.gd
**Action:** Mark as deprecated or remove
- Fork bundles are loaded directly from `res://` via WebView
- No HTTP server needed for local files
- **Keep temporarily** if other systems depend on it

#### 3.4.3 WorldBuilderAzgaar.gd
**Action:** Mark as deprecated/legacy
- This was the old direct integration path
- Keep for reference but add `@deprecated` comment
- Remove after migration is complete and tested

---

## 4. Implementation Steps

### Step 1: Create Prototype (SAFE - Non-Breaking)
1. ✅ Copy fork bundles to `res://assets/ui_web/js/azgaar/`
2. ✅ Create `world_builder_v2.html` as prototype
3. ✅ Create test WebView scene: `res://ui/world_builder/WorldBuilderWebV2.tscn`
4. ✅ Test headless JSON generation in isolation
5. ✅ Verify IPC communication (Godot ↔ WebView)

### Step 2: Parameter Mapping
1. ✅ Audit all parameters in `azgaar_step_parameters.json`
2. ✅ Create mapping function: `_convert_params_to_azgaar_options()`
3. ✅ Test parameter conversion with sample data
4. ✅ Verify all 8 steps map correctly

### Step 3: Integration
1. ✅ Update `WorldBuilderWebController.gd` with new handlers
2. ✅ Update `world_builder.js` to use new API
3. ✅ Replace iframe with canvas (or keep hidden for headless)
4. ✅ Test full generation flow: UI → Godot → Fork → JSON → Godot

### Step 4: Testing & Validation
1. ✅ Test all archetype presets
2. ✅ Test all 8 wizard steps
3. ✅ Verify JSON structure matches expected format
4. ✅ Test error handling (invalid params, generation failures)
5. ✅ Performance test (generation time, memory usage)

### Step 5: Cleanup
1. ✅ Remove old iframe code from `world_builder.html`
2. ✅ Archive `res://tools/azgaar/` (or delete after backup)
3. ✅ Update documentation
4. ✅ Commit with message: `feat/genesis: complete Azgaar fork migration`

---

## 5. Potential Issues & Solutions

### Issue 1: Rendering Limitations
**Problem:** Fork currently has basic canvas rendering (ocean, lakes, landmass) - may not match original Azgaar's full UI.

**Solution:**
- Start with **headless mode** (no canvas rendering)
- Use fork for **data generation only**
- Keep existing 2D map renderer (`MapMakerModule`) for visualization
- Extend fork's rendering later if needed

### Issue 2: D3 Dependency
**Problem:** Fork may require D3 for some features, but we want to avoid heavy dependencies.

**Solution:**
- Test headless generation **without D3 first**
- If D3 required, use CDN: `https://cdn.jsdelivr.net/npm/d3@7/+esm`
- Or bundle minimal D3 subset if needed

### Issue 3: Parameter Mapping Complexity
**Problem:** Original Azgaar has many parameters, fork may have different names/format.

**Solution:**
- Create comprehensive mapping table
- Test each parameter individually
- Log unmapped parameters for investigation
- Extend fork API if needed

### Issue 4: IPC Reliability
**Problem:** godot_wry IPC may have limitations or quirks.

**Solution:**
- Test IPC thoroughly in prototype
- Use both `execute_js()` and `postMessage()` as fallbacks
- Add retry logic for critical operations
- Log all IPC messages for debugging

### Issue 5: Performance
**Problem:** Fork may have different performance characteristics.

**Solution:**
- Benchmark generation time (fork vs original)
- Profile memory usage
- Test with large maps (high `cellsDesired`)
- Optimize if needed (fork is modular, easier to optimize)

---

## 6. Code Samples

### 6.1 Complete HTML Template (Minimal)
See Phase 2 section above for full template.

### 6.2 GDScript Parameter Converter
```gdscript
func _convert_params_to_azgaar_options(params: Dictionary) -> Dictionary:
	"""Convert Genesis Mythos parameters to Azgaar Genesis options."""
	var options: Dictionary = {}
	
	# Step 0: Map Generation
	if params.has("templateInput"):
		options["template"] = params["templateInput"]
	if params.has("pointsInput"):
		options["cellsDesired"] = int(params["pointsInput"])
	if params.has("mapWidthInput"):
		options["mapWidth"] = int(params["mapWidthInput"])
	if params.has("mapHeightInput"):
		options["mapHeight"] = int(params["mapHeightInput"])
	if params.has("optionsSeed"):
		options["seed"] = str(params["optionsSeed"])
	
	# Step 1: Heightmap & Relief
	if params.has("heightExponentInput"):
		options["heightExponent"] = float(params["heightExponentInput"])
	if params.has("allowErosionInput"):
		options["allowErosion"] = bool(params["allowErosionInput"])
	if params.has("plateCountInput"):
		options["plateCount"] = int(params["plateCountInput"])
	
	# Step 2: Climate
	if params.has("precipInput"):
		options["precip"] = float(params["precipInput"])
	if params.has("temperatureEquatorInput"):
		options["temperatureEquator"] = float(params["temperatureEquatorInput"])
	if params.has("temperatureNorthPoleInput"):
		options["temperatureNorthPole"] = float(params["temperatureNorthPoleInput"])
	
	# Step 3: States & Cultures
	if params.has("statesNumberInput"):
		options["statesNumber"] = int(params["statesNumberInput"])
	if params.has("culturesSetInput"):
		options["cultures"] = int(params["culturesSetInput"])
	
	# Step 4: Religions
	if params.has("religionsNumberInput"):
		options["religionsNumber"] = int(params["religionsNumberInput"])
	
	# ... map remaining parameters
	
	return options
```

### 6.3 JavaScript Generation Handler
```javascript
async function handleGenerateMap(options) {
    const statusDiv = document.getElementById('azgaar-status');
    const { Delaunator, loadOptions, generateMap, getMapData } = window.AzgaarGenesis;
    
    try {
        statusDiv.textContent = 'Loading options...';
        loadOptions(options);
        
        statusDiv.textContent = 'Generating map...';
        const startTime = performance.now();
        const data = generateMap(Delaunator);
        const generateTime = performance.now() - startTime;
        
        statusDiv.textContent = 'Extracting JSON data...';
        const json = getMapData();
        
        // Send to Godot
        if (window.GodotBridge && window.GodotBridge.postMessage) {
            window.GodotBridge.postMessage('map_generated', {
                data: json,
                seed: data.seed,
                generationTime: generateTime
            });
        }
        
        statusDiv.textContent = `Map generated in ${generateTime.toFixed(0)}ms (seed: ${data.seed})`;
        console.log('Map generated:', {
            seed: data.seed,
            cells: json.grid?.cells?.i?.length || 0,
            jsonSize: JSON.stringify(json).length
        });
    } catch (error) {
        console.error('Map generation error:', error);
        statusDiv.textContent = `Error: ${error.message}`;
        
        if (window.GodotBridge && window.GodotBridge.postMessage) {
            window.GodotBridge.postMessage('map_generation_failed', {
                error: error.message,
                stack: error.stack
            });
        }
    }
}
```

---

## 7. Testing Checklist

### 7.1 Basic Functionality
- [ ] Fork bundles load correctly in WebView
- [ ] `initGenerator()` succeeds (headless mode)
- [ ] `loadOptions()` accepts parameters
- [ ] `generateMap()` completes without errors
- [ ] `getMapData()` returns valid JSON

### 7.2 Parameter Mapping
- [ ] All Step 0 parameters map correctly
- [ ] All Step 1 parameters map correctly
- [ ] All Step 2-7 parameters map correctly
- [ ] Archetype presets work correctly

### 7.3 IPC Communication
- [ ] Godot → WebView: `generate_map` message received
- [ ] WebView → Godot: `map_generated` message sent
- [ ] Error messages propagate correctly
- [ ] Large JSON payloads transfer successfully

### 7.4 Data Validation
- [ ] Generated JSON has expected structure
- [ ] Seed values are consistent
- [ ] Grid/pack data is valid
- [ ] No circular references in JSON

### 7.5 Integration
- [ ] Terrain3DManager receives map data
- [ ] Heightmap export works (if implemented)
- [ ] World generation pipeline completes
- [ ] No regressions in existing features

---

## 8. Rollback Plan

If migration fails or causes issues:

1. **Keep old code:** Don't delete `res://tools/azgaar/` immediately
2. **Feature flag:** Add `USE_AZGAAR_FORK` constant to toggle
3. **Quick revert:** Switch HTML template back to `world_builder.html` (old version)
4. **Gradual migration:** Run both systems in parallel, switch via config

---

## 9. Next Steps

### Immediate Actions
1. ✅ **Create prototype HTML** (`world_builder_v2.html`)
2. ✅ **Copy fork bundles** to `res://assets/ui_web/js/azgaar/`
3. ✅ **Test in isolation** before integrating

### After Prototype Works
1. ✅ **Update GDScript** integration
2. ✅ **Update JavaScript** controller
3. ✅ **Test full flow** end-to-end
4. ✅ **Performance test** and optimize

### Final Steps
1. ✅ **Replace production** template
2. ✅ **Archive old** Azgaar bundle
3. ✅ **Update documentation**
4. ✅ **Commit and push**

---

## 10. Questions & Decisions Needed

### Q1: Canvas Rendering
**Question:** Do we need canvas preview in the UI, or is headless JSON generation sufficient?

**Recommendation:** Start with **headless mode** (no canvas). We have `MapMakerModule` for 2D visualization. Add canvas later if users request it.

### Q2: D3 Dependency
**Question:** Does the fork require D3, or can we generate maps without it?

**Action:** Test fork **without D3 first**. If generation fails, add D3 via CDN.

### Q3: Parameter Completeness
**Question:** Does the fork support all parameters we currently use?

**Action:** Audit fork's `src/core/options.js` to see supported parameters. Map missing ones or extend fork if needed.

### Q4: Migration Timeline
**Question:** Should we migrate incrementally or all at once?

**Recommendation:** **Incremental** - create prototype first, test thoroughly, then replace production.

---

## Conclusion

This migration plan provides a clear path from the original Azgaar integration to the custom modular fork. The fork offers significant advantages:

- ✅ **Reliability:** No CORS/iframe issues
- ✅ **Structured Data:** Clean JSON export
- ✅ **Maintainability:** Modular codebase
- ✅ **Performance:** Smaller bundle, headless mode

**Next Action:** Begin with Step 1 (Prototype) to validate the approach before full integration.
