# Azgaar Fantasy Map Generator - Complete Parameter List

This document contains the exhaustive list of all map generation parameters extracted from the bundled Azgaar Fantasy Map Generator version. Parameters are organized by category for easy reference.

**Last Updated:** 2025-01-20  
**Source:** Azgaar Fantasy Map Generator (bundled version in `tools/azgaar/`)

---

## Table of Contents

1. [General / Map Size](#general--map-size)
2. [Template & Heightmap](#template--heightmap)
3. [Climate & Temperature](#climate--temperature)
4. [Precipitation & Winds](#precipitation--winds)
5. [Biomes](#biomes)
6. [States & Provinces](#states--provinces)
7. [Cultures](#cultures)
8. [Religions](#religions)
9. [Burgs (Towns/Cities)](#burgs-townscities)
10. [Rivers & Lakes](#rivers--lakes)
11. [Routes](#routes)
12. [Markers & Emblems](#markers--emblems)
13. [Military](#military)
14. [Population](#population)
15. [Units & Measurement](#units--measurement)
16. [UI / Display Only](#ui--display-only)
17. [Heightmap Customization](#heightmap-customization)

---

## General / Map Size

| Key | Default Value | Type | Description | Notes |
|-----|---------------|------|-------------|-------|
| `mapWidthInput` | 960 | number | Canvas width in pixels | Min: 240, cannot be changed after generation |
| `mapHeightInput` | 540 | number | Canvas height in pixels | Min: 135, cannot be changed after generation |
| `optionsSeed` | (random) | number | Map seed number | Min: 1, Max: 999999999, produces same map if canvas size and options are identical |
| `mapName` | (generated) | string | Map name | Used for downloaded file names |
| `yearInput` | (random 100-2000) | number | Current year | Used for era display |
| `eraInput` | (generated) | string | Era name | E.g., "First Era", "Age of Heroes" |
| `mapSizeInput` | (varies by template) | number | Map size relative to world | 1-100%, affects latitude/longitude coverage |
| `latitudeInput` | (varies by template) | number | North-South map shift | 0-100, 50 = Equator |
| `longitudeInput` | 50 | number | West-East map shift | 0-100, 50 = Prime Meridian |

---

## Template & Heightmap

| Key | Default Value | Type | Description | Notes |
|-----|---------------|------|-------------|-------|
| `templateInput` | (random) | string | Heightmap template | See template list below |
| `pointsInput` | 4 | number | Points density selector | Range 1-13, maps to actual cell count (1K-100K) |
| `pointsOutputFormatted` | "10K" | string | Formatted cell count | Display only, derived from pointsInput |
| `resolveDepressionsStepsInput` | 250 | number | Max iterations for depression filling | 0-500, affects lake formation |
| `lakeElevationLimitInput` | 20 | number | Depression depth threshold for lakes | 0-80, higher = fewer lakes |
| `heightExponentInput` | 2 | number | Height exponent for altitude sharpness | 1.5-2.2, affects temperature/biome calculations |
| `allowErosion` | true | boolean | Allow water erosion | Regenerates rivers and allows water flow changes |

### Available Templates

Templates define the base heightmap pattern. Common values include:
- `pangea` - Single supercontinent
- `continents` - Multiple large continents
- `archipelago` - Many small islands
- `highIsland` - Large islands
- `lowIsland` - Small, low islands
- `mediterranean` - Mediterranean-style sea
- `peninsula` - Peninsula formation
- `isthmus` - Narrow land bridge
- `atoll` - Atoll formation
- `volcano` - Volcanic islands
- `shattered` - Fragmented landmasses
- `world` - Full world map
- `africa-centric`, `arabia`, `atlantics`, `britain`, `caribbean`, `east-asia`, `eurasia`, `europe`, `europe-accented`, `europe-and-central-asia`, `europe-central`, `europe-north`, `greenland`, `hellenica`, `iceland`, `indian-ocean`, `mediterranean-sea`, `middle-east`, `north-america`, `us-centric`, `us-mainland`, `world-from-pacific` - Regional templates

---

## Climate & Temperature

| Key | Default Value | Type | Description | Notes |
|-----|---------------|------|-------------|-------|
| `temperatureEquator` | 27 | number | Temperature at equator (°C) | -50 to 50, stored in `options.temperatureEquator` |
| `temperatureNorthPole` | -30 | number | Temperature at North Pole (°C) | -50 to 50, stored in `options.temperatureNorthPole` |
| `temperatureSouthPole` | -15 | number | Temperature at South Pole (°C) | -50 to 50, stored in `options.temperatureSouthPole` |
| `temperatureScale` | "°C" | string | Temperature scale | Options: °C, °F, K, °R, °De, °N, °Ré, °Rø |

---

## Precipitation & Winds

| Key | Default Value | Type | Description | Notes |
|-----|---------------|------|-------------|-------|
| `precInput` | 100 | number | Precipitation percentage | 0-500%, affects rivers and biomes |
| `winds` | [225, 45, 225, 315, 135, 315] | array[6] | Wind directions per latitude tier | 0-360 degrees, stored in `options.winds` |

**Wind Tiers:** The array contains 6 values for different latitude bands (from 90°N to 90°S in 30° increments):
- Index 0: 90°N-60°N
- Index 1: 60°N-30°N
- Index 2: 30°N-0° (Equator)
- Index 3: 0°-30°S
- Index 4: 30°S-60°S
- Index 5: 60°S-90°S

---

## Biomes

Biomes are automatically generated based on temperature, precipitation, and elevation. No direct biome count parameter exists, but biome distribution is influenced by:
- Temperature settings (equator/poles)
- Precipitation amount
- Height exponent
- Template selection

---

## States & Provinces

| Key | Default Value | Type | Description | Notes |
|-----|---------------|------|-------------|-------|
| `statesNumber` | 18 | number | Number of states/countries | 0-100, affects capitals and political borders |
| `provincesRatio` | 20 | number | Burgs percentage to form province | 0-100%, higher = more provinces |
| `sizeVariety` | 4 | number | State/culture size variety | 0-10, defines expansionism value |
| `growthRate` | 1.0-2.0 | number | State/culture growth rate | 0.1-2.0, affects neutral lands |
| `stateLabelsMode` | "auto" | string | State label display mode | Options: "auto", "short", "full", stored in `options.stateLabelsMode` |

---

## Cultures

| Key | Default Value | Type | Description | Notes |
|-----|---------------|------|-------------|-------|
| `culturesInput` | 12 | number | Number of cultures | Min: 1, Max varies by culture set |
| `culturesSet` | "world" | string | Culture set for names | Options: "world", "european", "oriental", "english", "antique", "highFantasy", "darkFantasy", "random" |

**Culture Set Maximums:**
- `world`: 32
- `european`: 15
- `oriental`: 13
- `english`: 10
- `antique`: 10
- `highFantasy`: 17
- `darkFantasy`: 18
- `random`: 100

---

## Religions

| Key | Default Value | Type | Description | Notes |
|-----|---------------|------|-------------|-------|
| `religionsNumber` | 6 | number | Number of organized religions | 0-50, cultures have folk religions regardless |

---

## Burgs (Towns/Cities)

| Key | Default Value | Type | Description | Notes |
|-----|---------------|------|-------------|-------|
| `manorsInput` | 1000 | number | Number of towns to place | 0-1000, "auto" if 1000 |
| `villageMaxPopulation` | 2000 | number | Maximum population for villages | Stored in `options.villageMaxPopulation` |
| `showBurgPreview` | true | boolean | Show burg preview | Stored in `options.showBurgPreview` |

---

## Rivers & Lakes

Rivers are automatically generated based on:
- Precipitation amount
- Heightmap elevation
- Temperature (frozen areas have no rivers)
- Template selection

Lakes are formed by:
- Deep depressions (`lakeElevationLimitInput`)
- Depression filling iterations (`resolveDepressionsStepsInput`)
- Water erosion settings (`allowErosion`)

No direct river/lake count parameters exist.

---

## Routes

Routes are automatically generated between burgs. No direct route count parameter exists, but routes are influenced by:
- Number of burgs
- State borders
- Terrain (mountains block routes)
- Coastlines (sea routes)

---

## Markers & Emblems

| Key | Default Value | Type | Description | Notes |
|-----|---------------|------|-------------|-------|
| `emblemShape` | "culture" | string | Default emblem shape | See emblem shapes below |
| `pinNotes` | false | boolean | Pin notes to map | Stored in `options.pinNotes` |

**Emblem Shapes:**
- Diversiform: `culture`, `random`, `state`
- Basic: `heater`, `spanish`, `french`
- Regional: `horsehead`, `horsehead2`, `polish`, `hessen`, `swiss`
- Historical: `boeotian`, `roman`, `kite`, `oldFrench`, `renaissance`, `baroque`
- Specific: `targe`, `targe2`, `pavise`, `wedged`
- Banner: `flag`, `pennon`, `guidon`, `banner`, `dovetail`, `gonfalon`, `pennant`
- Simple: `round`, `oval`, `vesicaPiscis`, `square`, `diamond`
- Fantasy: `fantasy1`, `fantasy2`, `fantasy3`, `fantasy4`, `fantasy5`
- Middle Earth: `noldor`, `gondor`, `easterling`, `erebor`, `ironHills`, `urukHai`, `moriaOrc`

Markers are generated automatically with configurable multipliers (no direct count parameter).

---

## Military

| Key | Default Value | Type | Description | Notes |
|-----|---------------|------|-------------|-------|
| `military` | (object) | object | Military unit definitions | Stored in `options.military`, contains unit types and stats |

Military forces are calculated based on:
- State population
- State size
- Military options configuration

---

## Population

| Key | Default Value | Type | Description | Notes |
|-----|---------------|------|-------------|-------|
| `populationRateInput` | 1000 | number | People per population point | 10-10000, step: 10 |
| `urbanizationInput` | 1 | number | Urbanization rate | 0.01-5, burgs population relative to all population |
| `urbanDensityInput` | 10 | number | Urban density | 1-200, average population per building |

---

## Units & Measurement

| Key | Default Value | Type | Description | Notes |
|-----|---------------|------|-------------|-------|
| `distanceUnitInput` | "mi" | string | Distance unit | Options: "mi", "km", "lg", "vr", "nmi", "nlg", "custom_name" |
| `distanceScaleInput` | 3 | number | Distance units per pixel | 0.01-20, step: 0.1 |
| `areaUnit` | "square" | string | Area unit name | Type "square" to add ² to distance unit |
| `heightUnit` | "ft" | string | Height/altitude unit | Options: "ft", "m", "f", "custom_name" |

---

## UI / Display Only

These parameters affect UI behavior but not map generation:

| Key | Default Value | Type | Description | Notes |
|-----|---------------|------|-------------|-------|
| `uiSize` | (auto) | number | Interface size multiplier | 0.6-3, step: 0.1 |
| `tooltipSize` | 14 | number | Tooltip font size | 1-32 |
| `themeColorInput` | "#997787" | string | Theme color for dialogs | HSL color |
| `themeHueInput` | (derived) | number | Theme hue | 0-359 |
| `transparencyInput` | 5 | number | Dialog transparency | 0-100 |
| `autosaveIntervalInput` | 15 | number | Autosave interval (minutes) | 0-60, 0 = disabled |
| `onloadBehavior` | "random" | string | Behavior on page load | Options: "random", "lastSaved" |
| `azgaarAssistant` | "show" | string | Show/hide assistant | Options: "show", "hide" |
| `speakerVoice` | (auto) | number | Speech synthesis voice index | Browser-dependent |
| `zoomExtentMin` | 1 | number | Minimum zoom level | 0.2-20 |
| `zoomExtentMax` | 20 | number | Maximum zoom level | 1-50 |
| `shapeRendering` | "optimizeSpeed" | string | Rendering mode | Options: "geometricPrecision", "optimizeSpeed" |
| `translateExtent` | false | boolean | Allow dragging beyond canvas | Toggle via icon |

---

## Heightmap Customization

These parameters are used during heightmap editing mode:

| Key | Default Value | Type | Description | Notes |
|-----|---------------|------|-------------|-------|
| `renderOcean` | false | boolean | Render ocean cells | Display only |
| `allowErosion` | true | boolean | Allow water erosion | See Template section |
| `resolveDepressionsStepsInput` | 250 | number | Depression filling iterations | See Template section |
| `lakeElevationLimitInput` | 20 | number | Lake formation threshold | See Template section |

---

## Curated Subset for Fantasy World Archetypes

Based on the full parameter list, here are **25-30 key parameters** that have the most impact on fantasy world generation and should be prioritized for exposure in a curated Godot UI:

### High Priority (Core Generation)

1. **`templateInput`** - Heightmap template (string) - **CRITICAL** - Defines landmass structure
2. **`pointsInput`** - Cell density (number, 1-13) - **CRITICAL** - Affects detail and performance
3. **`statesNumber`** - Number of states (number, 0-100) - **HIGH** - Political density
4. **`culturesInput`** - Number of cultures (number) - **HIGH** - Cultural variety
5. **`culturesSet`** - Culture set (string) - **HIGH** - Name style and theme
6. **`religionsNumber`** - Number of religions (number, 0-50) - **MEDIUM** - Religious diversity
7. **`manorsInput`** - Towns number (number, 0-1000) - **HIGH** - Settlement density
8. **`precInput`** - Precipitation (number, 0-500%) - **HIGH** - Affects rivers, biomes, habitability
9. **`temperatureEquator`** - Equator temperature (°C, -50 to 50) - **HIGH** - Climate baseline
10. **`temperatureNorthPole`** - North Pole temperature (°C, -50 to 50) - **MEDIUM** - Climate gradient
11. **`temperatureSouthPole`** - South Pole temperature (°C, -50 to 50) - **MEDIUM** - Climate gradient
12. **`winds`** - Wind directions (array[6], 0-360°) - **MEDIUM** - Precipitation patterns

### Medium Priority (Fine-Tuning)

13. **`provincesRatio`** - Provinces ratio (number, 0-100%) - **MEDIUM** - Administrative granularity
14. **`sizeVariety`** - Size variety (number, 0-10) - **MEDIUM** - State/culture expansionism
15. **`growthRate`** - Growth rate (number, 0.1-2.0) - **MEDIUM** - Neutral lands amount
16. **`mapSizeInput`** - Map size (number, 1-100%) - **MEDIUM** - World coverage
17. **`latitudeInput`** - Latitude shift (number, 0-100) - **MEDIUM** - Climate zone positioning
18. **`longitudeInput`** - Longitude shift (number, 0-100) - **LOW** - Map positioning
19. **`heightExponentInput`** - Height exponent (number, 1.5-2.2) - **MEDIUM** - Terrain sharpness
20. **`lakeElevationLimitInput`** - Lake threshold (number, 0-80) - **LOW** - Lake frequency
21. **`populationRateInput`** - Population rate (number, 10-10000) - **LOW** - Population scaling
22. **`urbanizationInput`** - Urbanization (number, 0.01-5) - **LOW** - Urban/rural balance
23. **`distanceScaleInput`** - Distance scale (number, 0.01-20) - **LOW** - Map scale
24. **`emblemShape`** - Emblem shape (string) - **LOW** - Visual style only

### Archetype-Specific Recommendations

#### High Fantasy (e.g., Tolkien, D&D)
- **Higher values:** `statesNumber` (20-30), `culturesInput` (15-20), `religionsNumber` (8-12), `precInput` (120-150%), `manorsInput` (800-1000)
- **Temperature:** `temperatureEquator` (25-30°C), moderate poles
- **Template:** `continents`, `pangea`, or `mediterranean`
- **Culture Set:** `highFantasy` or `world`

#### Dark Fantasy (e.g., Dark Souls, Warhammer)
- **Lower values:** `statesNumber` (8-15), `culturesInput` (8-12), `religionsNumber` (4-8), `precInput` (60-90%), `manorsInput` (400-600)
- **Temperature:** `temperatureEquator` (20-25°C), colder poles
- **Template:** `shattered`, `volcano`, or `peninsula`
- **Culture Set:** `darkFantasy` or `antique`
- **Size Variety:** Higher (6-8) for more expansionist states

#### Low Fantasy / Historical (e.g., Game of Thrones, Medieval)
- **Moderate values:** `statesNumber` (12-20), `culturesInput` (10-15), `religionsNumber` (5-8), `precInput` (80-120%), `manorsInput` (600-800)
- **Temperature:** `temperatureEquator` (22-27°C), realistic poles
- **Template:** `europe`, `mediterranean`, or `continents`
- **Culture Set:** `european`, `oriental`, or `antique`

#### Archipelago / Island Worlds
- **Template:** `archipelago`, `highIsland`, `lowIsland`, or `atoll`
- **Higher:** `precInput` (100-150%) for lush islands
- **Lower:** `statesNumber` (5-12) for isolated kingdoms
- **Culture Set:** `world` or `oriental`

---

## Implementation Notes

1. **Options Object Structure:** Most parameters are stored in the global `options` object (see `main.js:189-198`), while others are read directly from DOM inputs.

2. **Parameter Locking:** Many parameters can be "locked" to prevent randomization. Locked parameters are stored in localStorage with a `lock_` prefix.

3. **Randomization:** The `randomizeOptions()` function (see `modules/ui/options.js:586-619`) sets default ranges for parameters when not locked.

4. **World Configurator:** Temperature, precipitation, and wind parameters are managed through the "Configure World" dialog (`modules/ui/world-configurator.js`).

5. **Template Selection:** Templates are defined in `heightmapTemplates` object (not shown in extracted files but referenced throughout).

6. **Generation Flow:** Parameters are applied in this order:
   - Canvas size → Grid generation → Heightmap → Temperature → Precipitation → Biomes → Cultures → States → Burgs → Routes → Religions → Military → Markers

---

## References

- Main options object: `tools/azgaar/main.js:189-198`
- Options UI: `tools/azgaar/modules/ui/options.js`
- World configurator: `tools/azgaar/modules/ui/world-configurator.js`
- HTML inputs: `tools/azgaar/index.html` (lines 1510-2001 for options, 2438-2644 for world configurator)

---

**End of Document**

