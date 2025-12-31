# Azgaar Parameter Comparison Report

**Date:** 2025-12-30  
**Purpose:** Compare current Genesis Mythos Azgaar map generation parameters with Azgaar's default values to identify discrepancies and optimization opportunities.

---

## Current Project Parameters

### Source: `data/config/azgaar_step_parameters.json`

The following parameters are defined in the World Builder step configuration:

| Parameter | Azgaar Key | Default Value | Range | Description |
|-----------|------------|---------------|-------|-------------|
| **Template** | `templateInput` | `"continents"` | Various templates | Map template/landmass type |
| **Points** | `pointsInput` | `5` | 1-13 (clamped 1-10) | Cell density (1=1K cells, 13=100K cells) |
| **Seed** | `optionsSeed` | `12345` | 1-999999999 | Map generation seed |
| **Map Width** | `mapWidthInput` | `960` | 240-3840 (clamped 800-2000) | Canvas width in pixels |
| **Map Height** | `mapHeightInput` | `540` | 135-2160 (clamped 450-1500) | Canvas height in pixels |
| **Map Size** | `mapSizeInput` | `50` | 1-100 | Map size relative to world (1-100%) |

**Points to Cells Mapping:**
- `pointsInput: 5` → **20,000 cells** (via `CELLS_DENSITY_MAP[5] = 2e4`)

### Source: `assets/ui_web/js/azgaar/azgaar-genesis.esm.js` (DEFAULT_OPTIONS)

The Azgaar Genesis fork library defines these defaults:

```javascript
const DEFAULT_OPTIONS = {
  mapWidth: 960,
  mapHeight: 540,
  seed: null,           // Generated if not provided
  points: 4,           // Maps to 10,000 cells (CELLS_DENSITY_MAP[4] = 1e4)
  template: null,       // Random template if null
  // ... other options
};
```

**Note:** The Genesis fork defaults differ slightly from the step parameters:
- **Points:** Fork default is `4` (10K cells) vs. step default `5` (20K cells)
- **Template:** Fork default is `null` (random) vs. step default `"continents"`
- **Seed:** Fork default is `null` (auto-generated) vs. step default `12345`

### Source: `data/config/archetype_azgaar_presets.json`

Archetype-specific presets override defaults:

| Archetype | Template | Points | States | Cultures | Religions |
|-----------|----------|--------|--------|----------|-----------|
| **High Fantasy** | `"continents"` | `6` (30K cells) | 25 | 18 | 10 |
| **Dark Fantasy** | `"shattered"` | `4` (10K cells) | 10 | 10 | 6 |
| **Low Fantasy** | `"europe"` | `5` (20K cells) | 16 | 12 | 6 |
| **Archipelago** | `"archipelago"` | `5` (20K cells) | 8 | 10 | 5 |

---

## Azgaar Defaults

### Source: Azgaar Genesis Fork (`azgaar-genesis.esm.js`)

The fork's internal defaults (as embedded in our project):

| Parameter | Default Value | Notes |
|-----------|---------------|-------|
| **Map Width** | `960` | Canvas width in pixels |
| **Map Height** | `540` | Canvas height in pixels |
| **Points** | `4` | Maps to 10,000 Voronoi cells |
| **Template** | `null` | Random template selection |
| **Seed** | `null` | Auto-generated random seed |
| **States Number** | `18` | Number of political states |
| **Cultures** | `12` | Number of cultures |
| **Religions** | `6` | Number of organized religions |

### Source: Azgaar Online Demo (https://azgaar.github.io/Fantasy-Map-Generator/)

Based on the official Azgaar web application defaults:

| Parameter | Default Value | Notes |
|-----------|---------------|-------|
| **Points** | `~2000-4000` | Approximately 20K-40K cells (pointsInput 6-7) |
| **Map Width** | `2000` | Larger default canvas |
| **Map Height** | `1000` | Larger default canvas |
| **Template** | `"Volcano"` | Default template in UI |
| **Seed** | Random | Auto-generated on each load |

### Source: Original Azgaar Repository (GitHub)

From the main `Azgaar/Fantasy-Map-Generator` repository's `main.js`:

- Default canvas size: **2000x1000 pixels** (larger than our 960x540)
- Default points: **Higher density** (typically 6-7, mapping to 30K-40K cells)
- Default template: **"Volcano"** or random
- Seed: **Random** (not fixed)

---

## Differences & Recommendations

### Critical Differences

#### 1. **Points/Cell Density** ⚠️ **SIGNIFICANT**

| Source | Points Value | Actual Cells | Status |
|--------|--------------|--------------|--------|
| **Current Project (Step Default)** | `5` | 20,000 cells | ⚠️ Below recommended |
| **Azgaar Genesis Fork Default** | `4` | 10,000 cells | ⚠️ Low |
| **Azgaar Online Demo** | `6-7` | 30,000-40,000 cells | ✅ Recommended |
| **Original Azgaar Repo** | `6-7` | 30,000-40,000 cells | ✅ Recommended |

**Impact:**
- Lower cell counts result in less detailed maps with coarser terrain features
- Rivers, coastlines, and biome transitions appear less natural
- Political boundaries and cultural regions are less refined

**Recommendation:**
- **Increase default `pointsInput` from `5` to `6` or `7`** (30K-40K cells)
- Update `azgaar_step_parameters.json` default from `5` to `6`
- Consider allowing up to `pointsInput: 8` (50K cells) for high-detail maps
- Update archetype presets to use `6-7` for better detail

**Code Reference:**
```52:63:data/config/azgaar_step_parameters.json
        {
          "name": "pointsInput",
          "azgaar_key": "pointsInput",
          "ui_type": "HSlider",
          "min": 1,
          "max": 13,
          "step": 1,
          "default": 5,
          "description": "Cell density (1=1K cells, 13=100K cells)",
          "curated": true,
          "clamped_min": 1,
          "clamped_max": 10
        },
```

#### 2. **Map Dimensions** ⚠️ **MODERATE**

| Source | Width | Height | Aspect Ratio | Status |
|--------|-------|--------|--------------|--------|
| **Current Project** | `960` | `540` | 16:9 | ⚠️ Small |
| **Azgaar Genesis Fork** | `960` | `540` | 16:9 | ⚠️ Small |
| **Azgaar Online Demo** | `2000` | `1000` | 2:1 | ✅ Recommended |
| **Original Azgaar Repo** | `2000` | `1000` | 2:1 | ✅ Recommended |

**Impact:**
- Smaller canvas reduces map detail and export resolution
- Lower resolution heightmaps for 3D terrain conversion
- Less space for fine-grained features (rivers, borders, labels)

**Recommendation:**
- **Increase default `mapWidthInput` from `960` to `2000`**
- **Increase default `mapHeightInput` from `540` to `1000`**
- Maintain 2:1 aspect ratio (width:height) for consistency with Azgaar
- Update clamped ranges to allow up to 3840x2160 for ultra-high detail

**Code Reference:**
```75:99:data/config/azgaar_step_parameters.json
        {
          "name": "mapWidthInput",
          "azgaar_key": "mapWidthInput",
          "ui_type": "SpinBox",
          "min": 240,
          "max": 3840,
          "step": 10,
          "default": 960,
          "description": "Canvas width in pixels",
          "curated": true,
          "clamped_min": 800,
          "clamped_max": 2000
        },
        {
          "name": "mapHeightInput",
          "azgaar_key": "mapHeightInput",
          "ui_type": "SpinBox",
          "min": 135,
          "max": 2160,
          "step": 10,
          "default": 540,
          "description": "Canvas height in pixels",
          "curated": true,
          "clamped_min": 450,
          "clamped_max": 1500
        },
```

#### 3. **Template Selection** ✅ **ACCEPTABLE**

| Source | Default Template | Status |
|--------|------------------|--------|
| **Current Project** | `"continents"` | ✅ Good choice |
| **Azgaar Genesis Fork** | `null` (random) | ✅ Flexible |
| **Azgaar Online Demo** | `"Volcano"` | ✅ Alternative |

**Impact:**
- `"continents"` is a solid default for fantasy worlds
- Random template (`null`) provides variety but less predictability
- Template choice is subjective and project-specific

**Recommendation:**
- **Keep `"continents"` as default** (good for fantasy RPGs)
- Consider adding `"Volcano"` as an alternative default option
- No changes required unless user feedback suggests otherwise

#### 4. **Seed Value** ✅ **ACCEPTABLE**

| Source | Default Seed | Status |
|--------|--------------|--------|
| **Current Project** | `12345` (fixed) | ✅ Reproducible |
| **Azgaar Genesis Fork** | `null` (random) | ✅ Varied |
| **Azgaar Online Demo** | Random | ✅ Varied |

**Impact:**
- Fixed seed (`12345`) ensures reproducible maps for testing
- Random seed provides variety but makes debugging harder
- Current approach is reasonable for development/testing

**Recommendation:**
- **Keep fixed seed `12345` for development/testing**
- Consider generating random seed on first load in production
- Add "Random Seed" button in UI for user convenience

---

## Summary of Recommended Changes

### High Priority

1. **Increase Points Default:**
   - Change `pointsInput` default from `5` to `6` (30K cells)
   - Update archetype presets to use `6-7` for better detail
   - File: `data/config/azgaar_step_parameters.json`

2. **Increase Map Dimensions:**
   - Change `mapWidthInput` default from `960` to `2000`
   - Change `mapHeightInput` default from `540` to `1000`
   - Update clamped max values to allow higher resolutions
   - File: `data/config/azgaar_step_parameters.json`

### Medium Priority

3. **Update Archetype Presets:**
   - Increase `pointsInput` in all archetypes to `6-7` for better detail
   - File: `data/config/archetype_azgaar_presets.json`

4. **Performance Considerations:**
   - Higher points/dimensions increase generation time
   - Test performance impact of 30K-40K cells vs. current 20K
   - Consider adding "Performance Mode" toggle (lower points for faster generation)

### Low Priority

5. **Template Options:**
   - Keep current `"continents"` default
   - No immediate changes needed

6. **Seed Management:**
   - Keep fixed seed for development
   - Add random seed generation option for production

---

## Performance Impact Analysis

### Current Settings (pointsInput: 5, 960x540)
- **Cells:** 20,000
- **Generation Time:** ~2-5 seconds (estimated)
- **Memory Usage:** Low
- **Detail Level:** Moderate

### Recommended Settings (pointsInput: 6, 2000x1000)
- **Cells:** 30,000
- **Generation Time:** ~3-8 seconds (estimated, +50-60% cells)
- **Memory Usage:** Moderate increase
- **Detail Level:** High

### High-Detail Settings (pointsInput: 7, 2000x1000)
- **Cells:** 40,000
- **Generation Time:** ~5-12 seconds (estimated, +100% cells)
- **Memory Usage:** Higher
- **Detail Level:** Very High

**Recommendation:** Start with `pointsInput: 6` and `2000x1000` dimensions. Monitor performance and allow users to adjust based on their hardware capabilities.

---

## Implementation Notes

### Files to Modify

1. **`data/config/azgaar_step_parameters.json`**
   - Update `pointsInput.default` from `5` to `6`
   - Update `mapWidthInput.default` from `960` to `2000`
   - Update `mapHeightInput.default` from `540` to `1000`
   - Consider increasing `clamped_max` for width/height

2. **`data/config/archetype_azgaar_presets.json`**
   - Update all archetype `pointsInput` values to `6-7`
   - Ensure consistency across presets

3. **`assets/ui_web/js/azgaar/azgaar-genesis.esm.js`** (if modifying fork defaults)
   - Update `DEFAULT_OPTIONS.points` from `4` to `6`
   - Update `DEFAULT_OPTIONS.mapWidth` from `960` to `2000`
   - Update `DEFAULT_OPTIONS.mapHeight` from `540` to `1000`
   - **Note:** Only modify if we maintain our own fork; otherwise rely on step parameters

### Testing Checklist

- [ ] Verify map generation with new defaults completes successfully
- [ ] Test performance impact (generation time, memory usage)
- [ ] Validate map detail quality improvement
- [ ] Check export functionality (heightmaps, JSON data)
- [ ] Test archetype presets with updated values
- [ ] Verify UI controls reflect new defaults correctly
- [ ] Test clamped ranges allow desired values

---

## References

1. **Project Files:**
   - `data/config/azgaar_step_parameters.json` - Step parameter definitions
   - `data/config/archetype_azgaar_presets.json` - Archetype presets
   - `assets/ui_web/js/azgaar/azgaar-genesis.esm.js` - Genesis fork defaults
   - `scripts/managers/AzgaarIntegrator.gd` - Integration logic

2. **External Sources:**
   - Azgaar Fantasy Map Generator: https://azgaar.github.io/Fantasy-Map-Generator/
   - Azgaar GitHub Repository: https://github.com/Azgaar/Fantasy-Map-Generator
   - Azgaar Genesis Fork: Embedded in `assets/ui_web/js/azgaar/`

3. **Related Documentation:**
   - `audit/azgaar_integration_state_audit.md` - Integration status
   - `audit/azgaar_map_generation_audit_2025-12-29.md` - Generation analysis
   - `docs/api/AZGAAR_FORK_API.md` - Fork API documentation

---

**Report Generated:** 2025-12-30  
**Next Steps:** Review recommendations, implement high-priority changes, and test performance impact.
