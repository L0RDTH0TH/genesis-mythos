import Delaunator from "./delaunator.esm.js";
function aleaPRNG(...args) {
  var r, t, e, o, a, u = new Uint32Array(3), i = "";
  function c(n) {
    var a2 = function() {
      var n2 = 4022871197, r2 = function(r3) {
        r3 = r3.toString();
        for (var t2 = 0, e3 = r3.length; t2 < e3; t2++) {
          var o2 = 0.02519603282416938 * (n2 += r3.charCodeAt(t2));
          o2 -= n2 = o2 >>> 0;
          n2 = (o2 *= n2) >>> 0;
          n2 += 4294967296 * (o2 - n2);
        }
        return 23283064365386963e-26 * (n2 >>> 0);
      };
      return r2.version = "Mash 0.9", r2;
    }();
    r = a2(" ");
    t = a2(" ");
    e = a2(" ");
    o = 1;
    for (var u2 = 0; u2 < n.length; u2++) {
      (r -= a2(n[u2])) < 0 && (r += 1);
      (t -= a2(n[u2])) < 0 && (t += 1);
      (e -= a2(n[u2])) < 0 && (e += 1);
    }
    i = a2.version;
    a2 = null;
  }
  function f(n) {
    return parseInt(n, 10) === n;
  }
  var l = function() {
    var n = 2091639 * r + 23283064365386963e-26 * o;
    return r = t, t = e, e = n - (o = 0 | n);
  };
  l.fract53 = function() {
    return l() + 11102230246251565e-32 * (2097152 * l() | 0);
  };
  l.int32 = function() {
    return 4294967296 * l();
  };
  l.cycle = function(n) {
    (n = void 0 === n ? 1 : +n) < 1 && (n = 1);
    for (var r2 = 0; r2 < n; r2++) l();
  };
  l.range = function() {
    var n, r2;
    return 1 === arguments.length ? (n = 0, r2 = arguments[0]) : (n = arguments[0], r2 = arguments[1]), arguments[0] > arguments[1] && (n = arguments[1], r2 = arguments[0]), f(n) && f(r2) ? Math.floor(l() * (r2 - n + 1)) + n : l() * (r2 - n) + n;
  };
  l.restart = function() {
    c(a);
  };
  l.seed = function() {
    c(Array.prototype.slice.call(arguments));
  };
  l.version = function() {
    return "aleaPRNG 1.1.0";
  };
  l.versions = function() {
    return "aleaPRNG 1.1.0, " + i;
  };
  0 === args.length && (typeof window !== "undefined" && window.crypto && window.crypto.getRandomValues && window.crypto.getRandomValues(u), args = [u[0], u[1], u[2]]);
  a = args;
  c(args);
  return l;
}
class RNG {
  /**
   * Create a new RNG instance with optional seed
   * @param {string|number} seed - Seed for the PRNG (string or number)
   */
  constructor(seed = null) {
    this._seed = seed;
    this._prng = null;
    if (seed !== null) {
      this.setSeed(seed);
    }
  }
  /**
   * Set the seed and initialize PRNG
   * @param {string|number} seed - Seed for the PRNG
   */
  setSeed(seed) {
    this._seed = String(seed);
    this._prng = aleaPRNG(this._seed);
  }
  /**
   * Get current seed
   * @returns {string} Current seed
   */
  getSeed() {
    return this._seed;
  }
  /**
   * Generate a random number between 0 and 1 (inclusive of 0, exclusive of 1)
   * Compatible with Math.random() interface
   * @returns {number} Random number in [0, 1)
   */
  random() {
    if (!this._prng) {
      throw new Error("RNG not initialized. Call setSeed() first.");
    }
    return this._prng();
  }
  /**
   * Generate a random integer in range [min, max] (inclusive)
   * @param {number} min - Minimum value (default: 0)
   * @param {number} max - Maximum value
   * @returns {number} Random integer
   */
  randInt(min2, max2) {
    if (min2 === void 0 && max2 === void 0) {
      return Math.floor(this.random() * Number.MAX_SAFE_INTEGER);
    }
    if (max2 === void 0) {
      max2 = min2;
      min2 = 0;
    }
    return Math.floor(this.random() * (max2 - min2 + 1)) + min2;
  }
  /**
   * Generate a random float in range [min, max)
   * @param {number} min - Minimum value (default: 0)
   * @param {number} max - Maximum value
   * @returns {number} Random float
   */
  randFloat(min2, max2) {
    if (min2 === void 0 && max2 === void 0) {
      return this.random();
    }
    if (max2 === void 0) {
      max2 = min2;
      min2 = 0;
    }
    return this.random() * (max2 - min2) + min2;
  }
  /**
   * Test probability (returns true with given probability)
   * @param {number} probability - Probability in [0, 1]
   * @returns {boolean} True if random value < probability
   */
  probability(prob) {
    if (prob >= 1) return true;
    if (prob <= 0) return false;
    return this.random() < prob;
  }
  /**
   * Pick a random element from an array
   * @param {Array} array - Array to pick from
   * @returns {*} Random element
   */
  pick(array2) {
    if (!array2 || array2.length === 0) {
      throw new Error("Cannot pick from empty array");
    }
    return array2[this.randInt(0, array2.length - 1)];
  }
  /**
   * Pick a random element from a weighted object {key: weight}
   * @param {Object} weights - Object with key-value pairs (key: weight)
   * @returns {string} Random key based on weights
   */
  pickWeighted(weights) {
    const array2 = [];
    for (const key in weights) {
      for (let i = 0; i < weights[key]; i++) {
        array2.push(key);
      }
    }
    return this.pick(array2);
  }
  /**
   * Generate a random number with bias towards one end
   * @param {number} min - Minimum value
   * @param {number} max - Maximum value
   * @param {number} exponent - Bias exponent (higher = more bias towards min)
   * @returns {number} Biased random number
   */
  biased(min2, max2, exponent2) {
    return Math.round(min2 + (max2 - min2) * Math.pow(this.random(), exponent2));
  }
  /**
   * Replace Math.random globally with this RNG instance
   * @returns {Function} Original Math.random function (for restoration)
   */
  replaceMathRandom() {
    const original = Math.random;
    Math.random = () => this.random();
    return original;
  }
  /**
   * Restore original Math.random
   * @param {Function} original - Original Math.random function
   */
  restoreMathRandom(original) {
    Math.random = original;
  }
}
function rn(v, d = 0) {
  const m = Math.pow(10, d);
  return Math.round(v * m) / m;
}
function minmax(value, min2, max2) {
  return Math.min(Math.max(value, min2), max2);
}
function lim(v) {
  return minmax(v, 0, 100);
}
function normalize(val, min2, max2) {
  return minmax((val - min2) / (max2 - min2), 0, 1);
}
function dist2$1(p1, p2) {
  const dx = p2[0] - p1[0];
  const dy = p2[1] - p1[1];
  return dx * dx + dy * dy;
}
function gauss(expected = 100, deviation = 30, min2 = 0, max2 = 300, round = 0, rng = null) {
  let value;
  if (rng && typeof rng.random === "function") {
    const u1 = rng.random();
    const u2 = rng.random();
    const z0 = Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math.PI * u2);
    value = expected + deviation * z0;
  } else {
    const u1 = Math.random();
    const u2 = Math.random();
    const z0 = Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math.PI * u2);
    value = expected + deviation * z0;
  }
  return rn(minmax(value, min2, max2), round);
}
function deepCopy(obj) {
  const id2 = (x2) => x2;
  const dcTArray = (a) => a.slice();
  const dcObject = (x2) => Object.fromEntries(Object.entries(x2).map(([k, d]) => [k, dcAny(d)]));
  const isTypedArray = (x2) => x2 instanceof Int8Array || x2 instanceof Uint8Array || x2 instanceof Uint8ClampedArray || x2 instanceof Int16Array || x2 instanceof Uint16Array || x2 instanceof Int32Array || x2 instanceof Uint32Array || x2 instanceof Float32Array || x2 instanceof Float64Array;
  const dcAny = (x2) => {
    if (!(x2 instanceof Object)) return x2;
    if (isTypedArray(x2)) return dcTArray(x2);
    return cf.get(x2.constructor) ? cf.get(x2.constructor)(x2) : id2(x2);
  };
  const dcMapCore = (m) => [...m.entries()].map(([k, v]) => [k, dcAny(v)]);
  const cf = /* @__PURE__ */ new Map([
    [Int8Array, dcTArray],
    [Uint8Array, dcTArray],
    [Uint8ClampedArray, dcTArray],
    [Int16Array, dcTArray],
    [Uint16Array, dcTArray],
    [Int32Array, dcTArray],
    [Uint32Array, dcTArray],
    [Float32Array, dcTArray],
    [Float64Array, dcTArray],
    [BigInt64Array, dcTArray],
    [BigUint64Array, dcTArray],
    [Map, (m) => new Map(dcMapCore(m))],
    [WeakMap, (m) => new WeakMap(dcMapCore(m))],
    [Array, (a) => a.map(dcAny)],
    [Set, (s) => [...s.values()].map(dcAny)],
    [Date, (d) => new Date(d.getTime())],
    [Object, dcObject]
    // ... extend here to implement their custom deep copy
  ]);
  return dcAny(obj);
}
function getTypedArray(maxValue) {
  const UINT8_MAX = 255;
  const UINT16_MAX = 65535;
  const UINT32_MAX = 4294967295;
  if (!Number.isInteger(maxValue) || maxValue < 0 || maxValue > UINT32_MAX) {
    throw new Error(
      `Array maxValue must be an integer between 0 and ${UINT32_MAX}, got ${maxValue}`
    );
  }
  if (maxValue <= UINT8_MAX) return Uint8Array;
  if (maxValue <= UINT16_MAX) return Uint16Array;
  if (maxValue <= UINT32_MAX) return Uint32Array;
  return Uint32Array;
}
function createTypedArray({ maxValue, length, from }) {
  const TypedArray = getTypedArray(maxValue);
  if (!from) return new TypedArray(length);
  return TypedArray.from(from);
}
const DEFAULT_OPTIONS = {
  // Map dimensions (canvas size)
  mapWidth: 960,
  mapHeight: 540,
  // Generation parameters
  seed: null,
  // Will be generated if not provided
  points: 4,
  // Maps to 10000 cells via cellsDensityMap (1=1K, 2=2K, 3=5K, 4=10K, etc.)
  template: null,
  // Heightmap template ID (null = random)
  // Political/Administrative
  statesNumber: 18,
  provincesRatio: 20,
  manors: 1e3,
  // 1000 = "auto"
  // Cultural/Religious
  cultures: 12,
  culturesSet: "world",
  // Options: world, european, oriental, english, antique, highFantasy, darkFantasy, random
  religionsNumber: 6,
  // World configuration
  temperatureEquator: 27,
  temperatureNorthPole: -30,
  temperatureSouthPole: -15,
  prec: 100,
  // Precipitation percentage
  winds: [225, 45, 225, 315, 135, 315],
  // Wind directions
  mapSize: null,
  // Percentage (null = auto-calculated from template)
  latitude: 50,
  longitude: null,
  // null = auto-calculated from template
  // Heightmap generation
  heightExponent: 1.8,
  lakeElevationLimit: 20,
  resolveDepressionsSteps: 250,
  landPercentage: 40,
  // Percentage of map that should be land (default 40% for continent template)
  // Population/Economy
  populationRate: 1e3,
  // People per population point
  urbanization: 1,
  // Burgs population relative to all population
  urbanDensity: 10,
  // Average population per building
  growthRate: 1.5,
  // State growth rate
  sizeVariety: 4,
  // Size variety factor
  // Display/UI options (for future rendering)
  stateLabelsMode: "auto",
  // 'auto', 'always', 'never'
  showBurgPreview: true,
  villageMaxPopulation: 2e3,
  pinNotes: false,
  // Rendering options (Phase 5)
  fullRendering: false,
  // Use full Voronoi pack for polygon rendering (slower but better quality)
  // Units (for display/export)
  distanceScale: 3,
  // Scale factor for distance calculations
  distanceUnit: "km",
  // 'km' or 'mi'
  heightUnit: "m",
  // 'm' or 'ft'
  temperatureScale: "°C",
  // '°C' or '°F'
  areaUnit: "square",
  // Area unit type
  // Era/World settings
  year: null,
  // Current year (null = random 100-2000)
  era: null,
  // Era name (null = auto-generated)
  eraShort: null
  // Short era name (null = auto-generated)
};
const CELLS_DENSITY_MAP = {
  1: 1e3,
  2: 2e3,
  3: 5e3,
  4: 1e4,
  5: 2e4,
  6: 3e4,
  7: 4e4,
  8: 5e4,
  9: 6e4,
  10: 7e4,
  11: 8e4,
  12: 9e4,
  13: 1e5
};
function getCellsFromPoints(points) {
  return CELLS_DENSITY_MAP[points] || CELLS_DENSITY_MAP[4];
}
function validateOption(key, value) {
  if (value === null || value === void 0) {
    return DEFAULT_OPTIONS[key];
  }
  switch (key) {
    case "mapWidth":
      return minmax(value, 240, 1e4);
    case "mapHeight":
      return minmax(value, 135, 1e4);
    case "points":
      return minmax(Math.round(value), 1, 13);
    case "statesNumber":
      return minmax(Math.round(value), 0, 100);
    case "provincesRatio":
      return minmax(value, 0, 100);
    case "manors":
      return value === "auto" || value === 1e3 ? 1e3 : minmax(Math.round(value), 0, 1e3);
    case "cultures":
      return minmax(Math.round(value), 1, 100);
    case "religionsNumber":
      return minmax(Math.round(value), 0, 50);
    case "temperatureEquator":
      return minmax(value, -50, 50);
    case "temperatureNorthPole":
      return minmax(value, -50, 50);
    case "temperatureSouthPole":
      return minmax(value, -50, 50);
    case "prec":
      return minmax(value, 0, 500);
    case "heightExponent":
      return minmax(value, 0.1, 10);
    case "lakeElevationLimit":
      return minmax(Math.round(value), 0, 100);
    case "resolveDepressionsSteps":
      return minmax(Math.round(value), 1, 1e3);
    case "landPercentage":
      return minmax(value, 1, 90);
    case "populationRate":
      return minmax(value, 10, 1e4);
    case "urbanization":
      return minmax(value, 0.01, 5);
    case "urbanDensity":
      return minmax(Math.round(value), 1, 200);
    case "growthRate":
      return minmax(value, 0.1, 10);
    case "sizeVariety":
      return minmax(value, 0, 10);
    case "distanceScale":
      return minmax(value, 1, 5);
    case "mapSize":
      return value === null ? null : minmax(value, 1, 100);
    case "latitude":
      return minmax(value, 0, 100);
    case "longitude":
      return value === null ? null : minmax(value, 0, 100);
    case "winds":
      if (!Array.isArray(value) || value.length !== 6) {
        return DEFAULT_OPTIONS.winds;
      }
      return value.map((w) => minmax(w, 0, 360));
    case "culturesSet":
      const validSets = [
        "world",
        "european",
        "oriental",
        "english",
        "antique",
        "highFantasy",
        "darkFantasy",
        "random"
      ];
      return validSets.includes(value) ? value : DEFAULT_OPTIONS.culturesSet;
    case "stateLabelsMode":
      const validModes = ["auto", "always", "never"];
      return validModes.includes(value) ? value : DEFAULT_OPTIONS.stateLabelsMode;
    case "distanceUnit":
      return value === "km" || value === "mi" ? value : DEFAULT_OPTIONS.distanceUnit;
    case "heightUnit":
      return value === "m" || value === "ft" ? value : DEFAULT_OPTIONS.heightUnit;
    case "temperatureScale":
      return value === "°C" || value === "°F" ? value : DEFAULT_OPTIONS.temperatureScale;
    case "fullRendering":
      return value === true || value === false ? value : DEFAULT_OPTIONS.fullRendering;
    default:
      return value;
  }
}
function getDefaultOptions() {
  return deepCopy(DEFAULT_OPTIONS);
}
function mergeOptions(userOptions = {}) {
  const defaults = getDefaultOptions();
  const merged = deepCopy(defaults);
  for (const key in userOptions) {
    if (userOptions.hasOwnProperty(key)) {
      if (key in DEFAULT_OPTIONS) {
        merged[key] = validateOption(key, userOptions[key]);
      } else {
        if (typeof console !== "undefined" && console.warn) {
          console.warn(`Unknown option key: ${key}`);
        }
        merged[key] = userOptions[key];
      }
    }
  }
  if (merged.points !== void 0) {
    merged.cellsDesired = getCellsFromPoints(merged.points);
  }
  return merged;
}
function getCellsDesired(options) {
  if (options.cellsDesired) {
    return options.cellsDesired;
  }
  if (options.points) {
    return getCellsFromPoints(options.points);
  }
  return getCellsFromPoints(DEFAULT_OPTIONS.points);
}
class GeneratorError extends Error {
  constructor(message) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}
class InitializationError extends GeneratorError {
  constructor(message = "Generator not initialized. Call initGenerator() first.") {
    super(message);
  }
}
class InvalidOptionError extends GeneratorError {
  constructor(key, value, message) {
    super(message || `Invalid option value for '${key}': ${value}`);
    this.key = key;
    this.value = value;
  }
}
class GenerationError extends GeneratorError {
  constructor(message = "Map generation failed") {
    super(message);
  }
}
class NoDataError extends GeneratorError {
  constructor(message = "No map data available. Call generateMap() first.") {
    super(message);
  }
}
let Voronoi$1 = class Voronoi {
  /**
   * Creates a Voronoi diagram from the given Delaunator
   * @param {{triangles: Uint32Array, halfedges: Int32Array}} delaunay - Delaunator instance
   * @param {[number, number][]} points - List of coordinates
   * @param {number} pointsN - Number of points
   */
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
        this.cells.v[p] = edges.map((e3) => this.triangleOfEdge(e3));
        this.cells.c[p] = edges.map((e3) => this.delaunay.triangles[e3]).filter((c) => c < this.pointsN);
        this.cells.b[p] = edges.length > this.cells.c[p].length ? 1 : 0;
      }
      const t = this.triangleOfEdge(e);
      if (!this.vertices.p[t]) {
        this.vertices.p[t] = this.triangleCenter(t);
        this.vertices.v[t] = this.trianglesAdjacentToTriangle(t);
        this.vertices.c[t] = this.pointsOfTriangle(t);
      }
    }
  }
  pointsOfTriangle(t) {
    return this.edgesOfTriangle(t).map((edge) => this.delaunay.triangles[edge]);
  }
  trianglesAdjacentToTriangle(t) {
    return this.edgesOfTriangle(t).map((edge) => {
      const opposite = this.delaunay.halfedges[edge];
      return opposite === -1 ? void 0 : this.triangleOfEdge(opposite);
    }).filter((t2) => t2 !== void 0);
  }
  edgesAroundPoint(start2) {
    const result = [];
    let incoming = start2;
    do {
      result.push(incoming);
      const outgoing = this.nextHalfedge(incoming);
      incoming = this.delaunay.halfedges[outgoing];
    } while (incoming !== -1 && incoming !== start2 && result.length < 20);
    return result;
  }
  triangleCenter(t) {
    let vertices = this.pointsOfTriangle(t).map((p) => this.points[p]);
    return this.circumcenter(vertices[0], vertices[1], vertices[2]);
  }
  edgesOfTriangle(t) {
    return [3 * t, 3 * t + 1, 3 * t + 2];
  }
  triangleOfEdge(e) {
    return Math.floor(e / 3);
  }
  nextHalfedge(e) {
    return e % 3 === 2 ? e - 2 : e + 1;
  }
  prevHalfedge(e) {
    return e % 3 === 0 ? e + 2 : e - 1;
  }
  circumcenter(a, b, c) {
    const [ax, ay] = a;
    const [bx, by] = b;
    const [cx, cy] = c;
    const ad = ax * ax + ay * ay;
    const bd = bx * bx + by * by;
    const cd = cx * cx + cy * cy;
    const D = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by));
    if (Math.abs(D) < 1e-10) {
      return [Math.floor((ax + bx + cx) / 3), Math.floor((ay + by + cy) / 3)];
    }
    return [
      Math.floor(1 / D * (ad * (by - cy) + bd * (cy - ay) + cd * (ay - by))),
      Math.floor(1 / D * (ad * (cx - bx) + bd * (ax - cx) + cd * (bx - ax)))
    ];
  }
};
function getBoundaryPoints(width2, height2, spacing) {
  const offset = rn(-1 * spacing);
  const bSpacing = spacing * 2;
  const w = width2 - offset * 2;
  const h = height2 - offset * 2;
  const numberX = Math.ceil(w / bSpacing) - 1;
  const numberY = Math.ceil(h / bSpacing) - 1;
  const points = [];
  for (let i = 0.5; i < numberX; i++) {
    let x2 = Math.ceil(w * i / numberX + offset);
    points.push([x2, offset], [x2, h + offset]);
  }
  for (let i = 0.5; i < numberY; i++) {
    let y2 = Math.ceil(h * i / numberY + offset);
    points.push([offset, y2], [w + offset, y2]);
  }
  return points;
}
function getJitteredGrid(width2, height2, spacing, rng) {
  const radius = spacing / 2;
  const jittering = radius * 0.9;
  const jitter2 = () => rng.randFloat(-jittering, jittering);
  let points = [];
  for (let y2 = radius; y2 < height2; y2 += spacing) {
    for (let x2 = radius; x2 < width2; x2 += spacing) {
      const xj = Math.min(rn(x2 + jitter2(), 2), width2);
      const yj = Math.min(rn(y2 + jitter2(), 2), height2);
      points.push([xj, yj]);
    }
  }
  return points;
}
function placePoints(width2, height2, cellsDesired, rng) {
  const spacing = rn(Math.sqrt(width2 * height2 / cellsDesired), 2);
  const boundary = getBoundaryPoints(width2, height2, spacing);
  const points = getJitteredGrid(width2, height2, spacing, rng);
  const cellsX = Math.floor((width2 + 0.5 * spacing - 1e-10) / spacing);
  const cellsY = Math.floor((height2 + 0.5 * spacing - 1e-10) / spacing);
  return { spacing, cellsDesired, boundary, points, cellsX, cellsY };
}
function createVoronoiDiagram(options, rng, DelaunatorClass = null) {
  const width2 = options.mapWidth;
  const height2 = options.mapHeight;
  const cellsDesired = getCellsDesired(options);
  const { spacing, boundary, points, cellsX, cellsY } = placePoints(width2, height2, cellsDesired, rng);
  if (!DelaunatorClass) {
    throw new Error(
      "Delaunator is required as a peer dependency. Pass it as the third parameter or install: npm install delaunator"
    );
  }
  const Delaunator2 = DelaunatorClass;
  const allPoints = points.concat(boundary);
  const delaunay = Delaunator2.from(allPoints);
  const voronoi = new Voronoi$1(delaunay, allPoints, points.length);
  const cells = voronoi.cells;
  cells.i = createTypedArray({ maxValue: points.length, length: points.length }).map((_, i) => i);
  const vertices = voronoi.vertices;
  return {
    seed: options.seed || null,
    spacing,
    cellsDesired,
    boundary,
    points,
    cellsX,
    cellsY,
    cells,
    vertices
  };
}
function findGridCell(x2, y2, grid) {
  return Math.floor(Math.min(y2 / grid.spacing, grid.cellsY - 1)) * grid.cellsX + Math.floor(Math.min(x2 / grid.spacing, grid.cellsX - 1));
}
class HeightmapTemplate {
  constructor(grid, options, rng) {
    this.grid = grid;
    this.options = options;
    this.rng = rng;
    this.heights = null;
    const cellsDesired = options.cellsDesired || 1e4;
    const baseBlobPower = this.getBlobPower(cellsDesired);
    this.blobPower = 1 - (1 - baseBlobPower) * 0.5;
    this.linePower = this.getLinePower(cellsDesired);
    this.graphWidth = options.mapWidth;
    this.graphHeight = options.mapHeight;
  }
  setHeights(heights) {
    this.heights = heights;
  }
  getHeights() {
    return this.heights;
  }
  getBlobPower(cells) {
    const blobPowerMap = {
      1e3: 0.93,
      2e3: 0.95,
      5e3: 0.97,
      1e4: 0.98,
      2e4: 0.99,
      3e4: 0.991,
      4e4: 0.993,
      5e4: 0.994,
      6e4: 0.995,
      7e4: 0.9955,
      8e4: 0.996,
      9e4: 0.9964,
      1e5: 0.9973
    };
    return blobPowerMap[cells] || 0.98;
  }
  getLinePower(cells) {
    const linePowerMap = {
      1e3: 0.75,
      2e3: 0.77,
      5e3: 0.79,
      1e4: 0.81,
      2e4: 0.82,
      3e4: 0.83,
      4e4: 0.84,
      5e4: 0.86,
      6e4: 0.87,
      7e4: 0.88,
      8e4: 0.91,
      9e4: 0.92,
      1e5: 0.93
    };
    return linePowerMap[cells] || 0.81;
  }
  getNumberInRange(r) {
    if (typeof r !== "string") {
      throw new Error("Range value should be a string");
    }
    if (!isNaN(+r)) return ~~r + (this.rng.probability(r - ~~r) ? 1 : 0);
    const sign = r[0] === "-" ? -1 : 1;
    if (isNaN(+r[0])) r = r.slice(1);
    const range = r.includes("-") ? r.split("-") : null;
    if (!range) {
      throw new Error("Cannot parse the number. Check the format: " + r);
    }
    return this.rng.randInt(range[0] * sign, +range[1]);
  }
  getPointInRange(range, length) {
    if (typeof range !== "string") {
      throw new Error("Range should be a string");
    }
    const parts = range.split("-");
    const min2 = (parts[0] / 100 || 0) * length;
    const max2 = (parts[1] / 100 || min2) * length;
    return this.rng.randFloat(min2, max2);
  }
  /**
   * Add hill (blob) - creates organic blob-shaped elevation
   */
  addHill(count, height2, rangeX, rangeY) {
    count = this.getNumberInRange(count);
    while (count > 0) {
      this.addOneHill(height2, rangeX, rangeY);
      count--;
    }
  }
  addOneHill(height2, rangeX, rangeY) {
    const change = new Uint8Array(this.heights.length);
    let limit = 0;
    let start2;
    let h = lim(this.getNumberInRange(height2));
    do {
      const x2 = this.getPointInRange(rangeX || "0-100", this.graphWidth);
      const y2 = this.getPointInRange(rangeY || "0-100", this.graphHeight);
      start2 = findGridCell(x2, y2, this.grid);
      limit++;
    } while (this.heights[start2] + h > 90 && limit < 50);
    change[start2] = h;
    const queue = [start2];
    while (queue.length) {
      const q = queue.shift();
      const neighbors = this.grid.cells.c[q] || [];
      for (const c of neighbors) {
        if (change[c]) continue;
        change[c] = change[q] ** this.blobPower * (this.rng.randFloat() * 0.2 + 0.9);
        if (change[c] > 1) queue.push(c);
      }
    }
    for (let i = 0; i < this.heights.length; i++) {
      this.heights[i] = lim(this.heights[i] + change[i]);
    }
  }
  /**
   * Add pit (round depression)
   */
  addPit(count, height2, rangeX, rangeY) {
    count = this.getNumberInRange(count);
    while (count > 0) {
      this.addOnePit(height2, rangeX, rangeY);
      count--;
    }
  }
  addOnePit(height2, rangeX, rangeY) {
    const used = new Uint8Array(this.heights.length);
    let limit = 0, start2;
    let h = lim(this.getNumberInRange(height2));
    do {
      const x2 = this.getPointInRange(rangeX || "0-100", this.graphWidth);
      const y2 = this.getPointInRange(rangeY || "0-100", this.graphHeight);
      start2 = findGridCell(x2, y2, this.grid);
      limit++;
    } while (this.heights[start2] < 20 && limit < 50);
    const queue = [start2];
    while (queue.length) {
      const q = queue.shift();
      h = h ** this.blobPower * (this.rng.randFloat() * 0.2 + 0.9);
      if (h < 1) return;
      const neighbors = this.grid.cells.c[q] || [];
      neighbors.forEach((c) => {
        if (used[c]) return;
        this.heights[c] = lim(this.heights[c] - h * (this.rng.randFloat() * 0.2 + 0.9));
        used[c] = 1;
        queue.push(c);
      });
    }
  }
  /**
   * Add range (elongated ridge/mountain chain)
   */
  addRange(count, height2, rangeX, rangeY) {
    count = this.getNumberInRange(count);
    while (count > 0) {
      this.addOneRange(height2, rangeX, rangeY);
      count--;
    }
  }
  addOneRange(height2, rangeX, rangeY) {
    const used = new Uint8Array(this.heights.length);
    let h = lim(this.getNumberInRange(height2));
    const startX = this.getPointInRange(rangeX || "0-100", this.graphWidth);
    const startY = this.getPointInRange(rangeY || "0-100", this.graphHeight);
    let dist = 0, limit = 0, endX, endY;
    do {
      endX = this.rng.randFloat() * this.graphWidth * 0.8 + this.graphWidth * 0.1;
      endY = this.rng.randFloat() * this.graphHeight * 0.7 + this.graphHeight * 0.15;
      dist = Math.abs(endY - startY) + Math.abs(endX - startX);
      limit++;
    } while ((dist < this.graphWidth / 8 || dist > this.graphWidth / 3) && limit < 50);
    const startCell = findGridCell(startX, startY, this.grid);
    const endCell = findGridCell(endX, endY, this.grid);
    const range = this.getRangePath(startCell, endCell, used);
    let queue = range.slice();
    while (queue.length) {
      const frontier = queue.slice();
      queue = [];
      frontier.forEach((idx) => {
        this.heights[idx] = lim(this.heights[idx] + h * (this.rng.randFloat() * 0.3 + 0.85));
      });
      h = h ** this.linePower - 1;
      if (h < 2) break;
      frontier.forEach((f) => {
        const neighbors = this.grid.cells.c[f] || [];
        neighbors.forEach((idx) => {
          if (!used[idx]) {
            queue.push(idx);
            used[idx] = 1;
          }
        });
      });
    }
  }
  getRangePath(cur, end, used) {
    const range = [cur];
    const p = this.grid.points;
    used[cur] = 1;
    while (cur !== end) {
      let min2 = Infinity;
      const neighbors = this.grid.cells.c[cur] || [];
      neighbors.forEach((e) => {
        if (used[e]) return;
        let diff = (p[end][0] - p[e][0]) ** 2 + (p[end][1] - p[e][1]) ** 2;
        if (this.rng.randFloat() > 0.85) diff = diff / 2;
        if (diff < min2) {
          min2 = diff;
          cur = e;
        }
      });
      if (min2 === Infinity) return range;
      range.push(cur);
      used[cur] = 1;
    }
    return range;
  }
  /**
   * Add trough (elongated depression)
   */
  addTrough(count, height2, rangeX, rangeY) {
    count = this.getNumberInRange(count);
    while (count > 0) {
      this.addOneTrough(height2, rangeX, rangeY);
      count--;
    }
  }
  addOneTrough(height2, rangeX, rangeY) {
    const used = new Uint8Array(this.heights.length);
    let h = lim(this.getNumberInRange(height2));
    let startX, startY, limit = 0, startCell;
    do {
      startX = this.getPointInRange(rangeX || "0-100", this.graphWidth);
      startY = this.getPointInRange(rangeY || "0-100", this.graphHeight);
      startCell = findGridCell(startX, startY, this.grid);
      limit++;
    } while (this.heights[startCell] < 20 && limit < 50);
    let dist = 0, endX, endY;
    limit = 0;
    do {
      endX = this.rng.randFloat() * this.graphWidth * 0.8 + this.graphWidth * 0.1;
      endY = this.rng.randFloat() * this.graphHeight * 0.7 + this.graphHeight * 0.15;
      dist = Math.abs(endY - startY) + Math.abs(endX - startX);
      limit++;
    } while ((dist < this.graphWidth / 8 || dist > this.graphWidth / 2) && limit < 50);
    startCell = findGridCell(startX, startY, this.grid);
    const endCell = findGridCell(endX, endY, this.grid);
    const range = this.getRangePath(startCell, endCell, used);
    let queue = range.slice();
    while (queue.length) {
      const frontier = queue.slice();
      queue = [];
      frontier.forEach((idx) => {
        this.heights[idx] = lim(this.heights[idx] - h * (this.rng.randFloat() * 0.3 + 0.85));
      });
      h = h ** this.linePower - 1;
      if (h < 2) break;
      frontier.forEach((f) => {
        const neighbors = this.grid.cells.c[f] || [];
        neighbors.forEach((idx) => {
          if (!used[idx]) {
            queue.push(idx);
            used[idx] = 1;
          }
        });
      });
    }
  }
  /**
   * Add strait (water channel)
   */
  addStrait(width2, direction = "vertical") {
    width2 = Math.min(this.getNumberInRange(width2), Math.floor(this.graphWidth / (this.grid.cellsX || 100)) / 3);
    if (width2 < 1 && !this.rng.probability(width2)) return;
    const used = new Uint8Array(this.heights.length);
    const vert = direction === "vertical";
    const startX = vert ? Math.floor(this.rng.randFloat() * this.graphWidth * 0.4 + this.graphWidth * 0.3) : 5;
    const startY = vert ? 5 : Math.floor(this.rng.randFloat() * this.graphHeight * 0.4 + this.graphHeight * 0.3);
    const endX = vert ? Math.floor(this.graphWidth - startX - this.graphWidth * 0.1 + this.rng.randFloat() * this.graphWidth * 0.2) : this.graphWidth - 5;
    const endY = vert ? this.graphHeight - 5 : Math.floor(this.graphHeight - startY - this.graphHeight * 0.1 + this.rng.randFloat() * this.graphHeight * 0.2);
    const start2 = findGridCell(startX, startY, this.grid);
    const end = findGridCell(endX, endY, this.grid);
    let range = this.getRangePath(start2, end, used);
    const query = [];
    const step = 0.1 / width2;
    while (width2 > 0) {
      const exp = 0.9 - step * width2;
      range.forEach((r) => {
        const neighbors = this.grid.cells.c[r] || [];
        neighbors.forEach((e) => {
          if (used[e]) return;
          used[e] = 1;
          query.push(e);
          this.heights[e] **= exp;
          if (this.heights[e] > 100) this.heights[e] = 5;
        });
      });
      range = query.slice();
      width2--;
    }
  }
  /**
   * Modify heights (add or multiply)
   */
  modify(range, add, mult) {
    const min2 = range === "land" ? 20 : range === "all" ? 0 : +range.split("-")[0];
    const max2 = range === "land" || range === "all" ? 100 : +range.split("-")[1];
    const isLand2 = min2 === 20;
    for (let i = 0; i < this.heights.length; i++) {
      const h = this.heights[i];
      if (h < min2 || h > max2) continue;
      let newH = h;
      if (add) newH = isLand2 ? Math.max(newH + add, 20) : newH + add;
      if (mult !== 1 && mult !== 0) newH = isLand2 ? (newH - 20) * mult + 20 : newH * mult;
      this.heights[i] = lim(newH);
    }
  }
  /**
   * Smooth heights
   */
  smooth(fr = 2, add = 0) {
    const newHeights = new Uint8Array(this.heights.length);
    for (let i = 0; i < this.heights.length; i++) {
      const a = [this.heights[i]];
      const neighbors = this.grid.cells.c[i] || [];
      neighbors.forEach((c) => a.push(this.heights[c]));
      const mean2 = a.reduce((sum, val) => sum + val, 0) / a.length;
      if (fr === 1) {
        newHeights[i] = mean2 + add;
      } else {
        newHeights[i] = lim((this.heights[i] * (fr - 1) + mean2 + add) / fr);
      }
    }
    this.heights.set(newHeights);
  }
  /**
   * Apply mask (edge masking)
   */
  mask(power = 1) {
    const fr = Math.abs(power) || 1;
    for (let i = 0; i < this.heights.length; i++) {
      const [x2, y2] = this.grid.points[i];
      const nx = 2 * x2 / this.graphWidth - 1;
      const ny = 2 * y2 / this.graphHeight - 1;
      let distance = (1 - nx ** 2) * (1 - ny ** 2);
      if (power < 0) distance = 1 - distance;
      const masked = this.heights[i] * distance;
      this.heights[i] = lim((this.heights[i] * (fr - 1) + masked) / fr);
    }
  }
  /**
   * Invert heightmap along axes (simplified - not fully implemented for Voronoi grids)
   * Note: Original uses regular grid cellsX/cellsY; this is a placeholder
   * @param {number} count - Probability (0-1)
   * @param {string} axes - 'x', 'y', 'both', or null
   */
  invert(count = 1, axes = "both") {
    if (count > 0 && count < 1 && !this.rng.probability(count)) return;
    if (typeof console !== "undefined" && console.warn) {
      console.warn("[HeightmapTemplate] Invert operation not fully implemented for Voronoi grids - skipping");
    }
  }
  /**
   * Execute a template step (parsed from template string)
   * @param {string} tool - Operation name (Hill, Pit, Range, etc.)
   * @param {string} a2 - First argument
   * @param {string} a3 - Second argument
   * @param {string} a4 - Third argument
   * @param {string} a5 - Fourth argument
   */
  executeStep(tool, a2, a3, a4, a5) {
    if (tool === "Hill") return this.addHill(a2, a3, a4, a5);
    if (tool === "Pit") return this.addPit(a2, a3, a4, a5);
    if (tool === "Range") return this.addRange(a2, a3, a4, a5);
    if (tool === "Trough") return this.addTrough(a2, a3, a4, a5);
    if (tool === "Strait") return this.addStrait(a2, a3);
    if (tool === "Mask") return this.mask(+a2 || 1);
    if (tool === "Invert") return this.invert(+a2 || 1, a3);
    if (tool === "Add") return this.modify(a3 || "all", +a2, 1);
    if (tool === "Multiply") return this.modify(a3 || "all", 0, +a2);
    if (tool === "Smooth") return this.smooth(+a2 || 2, 0);
  }
}
const heightmapTemplates = {
  "Volcano": { id: 0, name: "Volcano", template: `Hill 1 90-100 44-56 40-60
Multiply 0.8 50-100 0 0
Range 1.5 30-55 45-55 40-60
Smooth 3 0 0 0
Hill 1.5 35-45 25-30 20-75
Hill 1 35-55 75-80 25-75
Hill 0.5 20-25 10-15 20-25
Mask 3 0 0 0`, probability: 3 },
  "High Island": { id: 1, name: "High Island", template: `Hill 1 90-100 65-75 47-53
Add 7 all 0 0
Hill 5-6 20-30 25-55 45-55
Range 1 40-50 45-55 45-55
Multiply 0.8 land 0 0
Mask 3 0 0 0
Smooth 2 0 0 0
Trough 2-3 20-30 20-30 20-30
Trough 2-3 20-30 60-80 70-80
Hill 1 10-15 60-60 50-50
Hill 1.5 13-16 15-20 20-75
Range 1.5 30-40 15-85 30-40
Range 1.5 30-40 15-85 60-70
Pit 3-5 10-30 15-85 20-80`, probability: 19 },
  "Low Island": { id: 2, name: "Low Island", template: `Hill 1 90-99 60-80 45-55
Hill 1-2 20-30 10-30 10-90
Smooth 2 0 0 0
Hill 6-7 25-35 20-70 30-70
Range 1 40-50 45-55 45-55
Trough 2-3 20-30 15-85 20-30
Trough 2-3 20-30 15-85 70-80
Hill 1.5 10-15 5-15 20-80
Hill 1 10-15 85-95 70-80
Pit 5-7 15-25 15-85 20-80
Multiply 0.4 20-100 0 0
Mask 4 0 0 0`, probability: 9 },
  "Continents": { id: 3, name: "Continents", template: `Hill 1 80-85 60-80 40-60
Hill 1 80-85 20-30 40-60
Hill 6-7 15-30 25-75 15-85
Multiply 0.6 land 0 0
Hill 8-10 5-10 15-85 20-80
Range 1-2 30-60 5-15 25-75
Range 1-2 30-60 80-95 25-75
Range 0-3 30-60 80-90 20-80
Strait 2 vertical 0 0
Strait 1 vertical 0 0
Smooth 3 0 0 0
Trough 3-4 15-20 15-85 20-80
Trough 3-4 5-10 45-55 45-55
Pit 3-4 10-20 15-85 20-80
Mask 4 0 0 0`, probability: 16 },
  "Archipelago": { id: 4, name: "Archipelago", template: `Add 11 all 0 0
Range 2-3 40-60 20-80 20-80
Hill 5 15-20 10-90 30-70
Hill 2 10-15 10-30 20-80
Hill 2 10-15 60-90 20-80
Smooth 3 0 0 0
Trough 10 20-30 5-95 5-95
Strait 2 vertical 0 0
Strait 2 horizontal 0 0`, probability: 18 },
  "Atoll": { id: 5, name: "Atoll", template: `Hill 1 75-80 50-60 45-55
Hill 1.5 30-50 25-75 30-70
Hill .5 30-50 25-35 30-70
Smooth 1 0 0 0
Multiply 0.2 25-100 0 0
Hill 0.5 10-20 50-55 48-52`, probability: 1 },
  "Mediterranean": { id: 6, name: "Mediterranean", template: `Range 4-6 30-80 0-100 0-10
Range 4-6 30-80 0-100 90-100
Hill 6-8 30-50 10-90 0-5
Hill 6-8 30-50 10-90 95-100
Multiply 0.9 land 0 0
Mask -2 0 0 0
Smooth 1 0 0 0
Hill 2-3 30-70 0-5 20-80
Hill 2-3 30-70 95-100 20-80
Trough 3-6 40-50 0-100 0-10
Trough 3-6 40-50 0-100 90-100`, probability: 5 },
  "Peninsula": { id: 7, name: "Peninsula", template: `Range 2-3 20-35 40-50 0-15
Add 5 all 0 0
Hill 1 90-100 10-90 0-5
Add 13 all 0 0
Hill 3-4 3-5 5-95 80-100
Hill 1-2 3-5 5-95 40-60
Trough 5-6 10-25 5-95 5-95
Smooth 3 0 0 0
Invert 0.4 both 0 0`, probability: 3 },
  "Pangea": { id: 8, name: "Pangea", template: `Hill 1-2 25-40 15-50 0-10
Hill 1-2 5-40 50-85 0-10
Hill 1-2 25-40 50-85 90-100
Hill 1-2 5-40 15-50 90-100
Hill 8-12 20-40 20-80 48-52
Smooth 2 0 0 0
Multiply 0.7 land 0 0
Trough 3-4 25-35 5-95 10-20
Trough 3-4 25-35 5-95 80-90
Range 5-6 30-40 10-90 35-65`, probability: 5 },
  "Isthmus": { id: 9, name: "Isthmus", template: `Hill 5-10 15-30 0-30 0-20
Hill 5-10 15-30 10-50 20-40
Hill 5-10 15-30 30-70 40-60
Hill 5-10 15-30 50-90 60-80
Hill 5-10 15-30 70-100 80-100
Smooth 2 0 0 0
Trough 4-8 15-30 0-30 0-20
Trough 4-8 15-30 10-50 20-40
Trough 4-8 15-30 30-70 40-60
Trough 4-8 15-30 50-90 60-80
Trough 4-8 15-30 70-100 80-100
Invert 0.25 x 0 0`, probability: 2 },
  "Shattered": { id: 10, name: "Shattered", template: `Hill 8 35-40 15-85 30-70
Trough 10-20 40-50 5-95 5-95
Range 5-7 30-40 10-90 20-80
Pit 12-20 30-40 15-85 20-80`, probability: 7 },
  "Taklamakan": { id: 11, name: "Taklamakan", template: `Hill 1-3 20-30 30-70 30-70
Hill 2-4 60-85 0-5 0-100
Hill 2-4 60-85 95-100 0-100
Hill 3-4 60-85 20-80 0-5
Hill 3-4 60-85 20-80 95-100
Smooth 3 0 0 0`, probability: 1 },
  "Old World": { id: 12, name: "Old World", template: `Range 3 70 15-85 20-80
Hill 2-3 50-70 15-45 20-80
Hill 2-3 50-70 65-85 20-80
Hill 4-6 20-25 15-85 20-80
Multiply 0.5 land 0 0
Smooth 2 0 0 0
Range 3-4 20-50 15-35 20-45
Range 2-4 20-50 65-85 45-80
Strait 3-7 vertical 0 0
Trough 6-8 20-50 15-85 45-65
Pit 5-6 20-30 10-90 10-90`, probability: 8 },
  "Fractious": { id: 13, name: "Fractious", template: `Hill 12-15 50-80 5-95 5-95
Mask -1.5 0 0 0
Mask 3 0 0 0
Add -20 30-100 0 0
Range 6-8 40-50 5-95 10-90`, probability: 3 }
};
function getTemplate(name) {
  if (!name) return null;
  if (heightmapTemplates[name]) {
    return heightmapTemplates[name];
  }
  const normalized = name.charAt(0).toUpperCase() + name.slice(1).toLowerCase();
  if (normalized === "High island") return heightmapTemplates["High Island"];
  if (normalized === "Low island") return heightmapTemplates["Low Island"];
  if (normalized === "Old world") return heightmapTemplates["Old World"];
  const lowerKey = name.toLowerCase();
  const keyMap = {
    "volcano": "Volcano",
    "highisland": "High Island",
    "lowisland": "Low Island",
    "continent": "Continents",
    "continents": "Continents",
    "archipelago": "Archipelago",
    "atoll": "Atoll",
    "mediterranean": "Mediterranean",
    "peninsula": "Peninsula",
    "pangea": "Pangea",
    "isthmus": "Isthmus",
    "shattered": "Shattered",
    "taklamakan": "Taklamakan",
    "oldworld": "Old World",
    "fractious": "Fractious"
  };
  const mappedKey = keyMap[lowerKey];
  if (mappedKey && heightmapTemplates[mappedKey]) {
    return heightmapTemplates[mappedKey];
  }
  return null;
}
function listTemplates() {
  return Object.keys(heightmapTemplates);
}
function generateBasicHeightmap(grid, options, rng) {
  const { points, cellsDesired } = grid;
  const heights = createTypedArray({ maxValue: 100, length: points.length });
  const template = options.template || null;
  const landPercentage = options.landPercentage || (template === "continent" ? 40 : 30);
  for (let i = 0; i < heights.length; i++) {
    heights[i] = 10;
  }
  if (template === "continent") {
    const numContinents = rng.randInt(1, 4);
    const mapArea = options.mapWidth * options.mapHeight;
    const targetLandArea = mapArea * (landPercentage / 100);
    for (let c = 0; c < numContinents; c++) {
      const margin = Math.min(options.mapWidth, options.mapHeight) * 0.1;
      const centerX = rng.randFloat(margin, options.mapWidth - margin);
      const centerY = rng.randFloat(margin, options.mapHeight - margin);
      const continentAreaFraction = 1 / numContinents;
      const targetArea = targetLandArea * continentAreaFraction * 1.2;
      const baseRadius = Math.sqrt(targetArea / Math.PI) * 2.5;
      for (let i = 0; i < points.length; i++) {
        const [x2, y2] = points[i];
        const dx = x2 - centerX;
        const dy = y2 - centerY;
        const distance = Math.sqrt(dx * dx + dy * dy);
        const maxDistance = baseRadius * 4;
        if (distance < maxDistance) {
          const normalizedDist = distance / baseRadius;
          const falloff = Math.max(0, 1 - Math.pow(normalizedDist / 4, 0.8));
          const baseHeight = 25 + falloff * 70;
          const noise = rng.randFloat(-1.5, 1.5);
          const height2 = rn(baseHeight + noise);
          heights[i] = Math.max(heights[i], lim(height2));
        }
      }
    }
  } else {
    const targetLandCells = Math.floor(points.length * (landPercentage / 100));
    const numIslands = Math.floor(targetLandCells / 50);
    for (let i = 0; i < numIslands; i++) {
      const centerIdx = rng.randInt(0, points.length - 1);
      const [centerX, centerY] = points[centerIdx];
      const radius = rng.randFloat(20, 60);
      for (let j = 0; j < points.length; j++) {
        const [x2, y2] = points[j];
        const dx = x2 - centerX;
        const dy = y2 - centerY;
        const distance = Math.sqrt(dx * dx + dy * dy);
        if (distance < radius) {
          const normalizedDist = distance / radius;
          const falloff = Math.exp(-normalizedDist * 3);
          const baseHeight = 20 + falloff * 80;
          const height2 = rn(baseHeight + rng.randFloat(-15, 15));
          heights[j] = Math.max(heights[j], lim(height2));
        }
      }
    }
  }
  return heights;
}
function smoothHeights(heights, grid, factor = 2, rng) {
  const newHeights = new Uint8Array(heights.length);
  for (let i = 0; i < heights.length; i++) {
    const neighbors = [heights[i]];
    if (grid.cells.c[i]) {
      grid.cells.c[i].forEach((c) => neighbors.push(heights[c]));
    }
    const avg = neighbors.reduce((a, b) => a + b, 0) / neighbors.length;
    newHeights[i] = lim((heights[i] * (factor - 1) + avg) / factor);
  }
  heights.set(newHeights);
}
function maskHeights(heights, grid, width2, height2, power = 1) {
  const fr = Math.abs(power) || 1;
  for (let i = 0; i < heights.length; i++) {
    const [x2, y2] = grid.points[i];
    const nx = 2 * x2 / width2 - 1;
    const ny = 2 * y2 / height2 - 1;
    let distance = (1 - nx ** 2) * (1 - ny ** 2);
    if (power < 0) distance = 1 - distance;
    const masked = heights[i] * distance;
    heights[i] = lim((heights[i] * (fr - 1) + masked) / fr);
  }
}
function generateHeightmap({ grid, options, rng, template = null }) {
  if (!grid || !grid.points) {
    throw new Error("Grid object with points is required");
  }
  if (!rng) {
    throw new Error("RNG instance is required");
  }
  const templateId = template || options.template || "Continents";
  const selectedTemplate = getTemplate(templateId);
  if (selectedTemplate && selectedTemplate.template) {
    return generateFromTemplate(grid, options, rng, selectedTemplate.template, selectedTemplate.name || templateId);
  }
  const heights = generateBasicHeightmap(grid, options, rng);
  smoothHeights(heights, grid, 2);
  maskHeights(heights, grid, options.mapWidth, options.mapHeight, 1);
  return heights;
}
function generateFromTemplate(grid, options, rng, templateString, templateId) {
  const initialHeights = createTypedArray({ maxValue: 100, length: grid.points.length });
  for (let i = 0; i < initialHeights.length; i++) {
    initialHeights[i] = 10;
  }
  const template = new HeightmapTemplate(grid, options, rng);
  template.setHeights(initialHeights);
  const steps = templateString.split("\n").map((line2) => line2.trim()).filter((line2) => line2.length > 0);
  for (const step of steps) {
    const elements = step.split(/\s+/).filter((e) => e.length > 0);
    if (elements.length < 2) {
      if (typeof console !== "undefined" && console.warn) {
        console.warn(`[generateFromTemplate] Skipping invalid step: ${step}`);
      }
      continue;
    }
    const [tool, a2 = "0", a3 = "0", a4 = "0", a5 = "0"] = elements;
    try {
      template.executeStep(tool, a2, a3, a4, a5);
    } catch (error) {
      if (typeof console !== "undefined" && console.warn) {
        console.warn(`[generateFromTemplate] Error executing step "${step}":`, error.message);
      }
    }
  }
  const heights = template.getHeights();
  const enforceLandPercentage = options.enforceLandPercentage !== false && options.enforceLandPercentage !== void 0 ? options.enforceLandPercentage : options.enforceLandPercentage === false ? false : true;
  const targetLandPercentage = options.landPercentage || 40;
  if (enforceLandPercentage) {
    const landThreshold = 20;
    const currentLandCount = heights.filter((h) => h >= landThreshold).length;
    const currentLandPercentage = currentLandCount / heights.length * 100;
    if (currentLandPercentage > targetLandPercentage) {
      const targetRatio = targetLandPercentage / currentLandPercentage;
      const reductionMultiplier = Math.pow(targetRatio, 1.5);
      for (let i = 0; i < heights.length; i++) {
        if (heights[i] >= landThreshold) {
          const newHeight = (heights[i] - 20) * reductionMultiplier + 20;
          heights[i] = Math.max(newHeight, 10);
        }
      }
      const newLandCount = heights.filter((h) => h >= landThreshold).length;
      const newLandPercentage = newLandCount / heights.length * 100;
      if (newLandPercentage > targetLandPercentage) {
        const finalReduction = targetLandPercentage / newLandPercentage;
        for (let i = 0; i < heights.length; i++) {
          if (heights[i] >= landThreshold) {
            heights[i] = Math.max((heights[i] - 20) * finalReduction + 20, 10);
          }
        }
      }
      if (typeof console !== "undefined" && console.log) {
        console.log(`[heightmap:template] Land % adjustment for ${templateId}:`, {
          initial: currentLandPercentage.toFixed(1),
          target: targetLandPercentage,
          final: (heights.filter((h) => h >= landThreshold).length / heights.length * 100).toFixed(1)
        });
      }
    }
  }
  return heights;
}
function calculateMapCoordinates(options, width2, height2) {
  const sizeFraction = (options.mapSize || 50) / 100;
  const latShift = options.latitude / 100;
  const lonShift = (options.longitude || 50) / 100;
  const latT = rn(sizeFraction * 180, 1);
  const latN = rn(90 - (180 - latT) * latShift, 1);
  const latS = rn(latN - latT, 1);
  const lonT = rn(Math.min(width2 / height2 * latT, 360), 1);
  const lonE = rn(180 - (360 - lonT) * lonShift, 1);
  const lonW = rn(lonE - lonT, 1);
  return { latT, latN, latS, lonT, lonW, lonE };
}
function getWindDirections(tier, winds) {
  const angle = winds[tier] || winds[0];
  const isWest = angle > 40 && angle < 140;
  const isEast = angle > 220 && angle < 320;
  const isNorth = angle > 100 && angle < 260;
  const isSouth = angle > 280 || angle < 80;
  return { isWest, isEast, isNorth, isSouth };
}
function getPrecipitation(humidity, currentHeight, nextHeight, modifier) {
  const normalLoss = Math.max(humidity / (10 * modifier), 1);
  const diff = Math.max(nextHeight - currentHeight, 0);
  const mod = (nextHeight / 70) ** 2;
  return minmax(normalLoss + diff * mod, 1, humidity);
}
function passWind(source, maxPrec, next, steps, grid, prec, modifier, rng) {
  const MAX_PASSABLE_ELEVATION = 85;
  const maxPrecInit = maxPrec;
  for (let first of source) {
    if (Array.isArray(first) && first[0] !== void 0) {
      maxPrec = Math.min(maxPrecInit * first[1], 255);
      first = first[0];
    }
    let humidity = maxPrec - grid.cells.h[first];
    if (humidity <= 0) continue;
    for (let s = 0, current = first; s < steps && current >= 0 && current < grid.cells.i.length; s++, current += next) {
      if (grid.cells.temp && grid.cells.temp[current] < -5) continue;
      if (grid.cells.h[current] < 20) {
        const nextCell2 = current + next;
        if (nextCell2 >= 0 && nextCell2 < grid.cells.i.length && grid.cells.h[nextCell2] >= 20) {
          prec[nextCell2] += Math.max(humidity / rng.randInt(10, 20), 1);
        } else {
          humidity = Math.min(humidity + 5 * modifier, maxPrec);
          prec[current] += 5 * modifier;
        }
        continue;
      }
      const nextCell = current + next;
      if (nextCell < 0 || nextCell >= grid.cells.i.length) continue;
      const isPassable2 = grid.cells.h[nextCell] <= MAX_PASSABLE_ELEVATION;
      const precipitation = isPassable2 ? getPrecipitation(humidity, grid.cells.h[current], grid.cells.h[nextCell], modifier) : humidity;
      prec[current] += precipitation;
      const evaporation = precipitation > 1.5 ? 1 : 0;
      humidity = isPassable2 ? minmax(humidity - precipitation + evaporation, 0, maxPrec) : 0;
    }
  }
}
function generatePrecipitation({ grid, options, rng, mapCoordinates: providedMapCoords = null }) {
  if (!grid || !grid.cells) {
    throw new Error("Grid object with cells is required");
  }
  if (!rng) {
    throw new Error("RNG instance is required");
  }
  const { cells, cellsX, cellsY } = grid;
  const prec = new Uint8Array(cells.i.length);
  const cellsNumberModifier = (options.cellsDesired / 1e4) ** 0.25;
  const precInputModifier = (options.prec || 100) / 100;
  const modifier = cellsNumberModifier * precInputModifier;
  const mapCoordinates = providedMapCoords || calculateMapCoordinates(options, options.mapWidth, options.mapHeight);
  const westerly = [];
  const easterly = [];
  let southerly = 0;
  let northerly = 0;
  const latitudeModifier = [4, 2, 2, 2, 1, 1, 2, 2, 2, 2, 3, 3, 2, 2, 1, 1, 1, 0.5];
  for (let i = 0; i < cellsY; i++) {
    const c = i * cellsX;
    const lat = mapCoordinates.latN - i / cellsY * mapCoordinates.latT;
    const latBand = (Math.abs(lat) - 1) / 5 | 0;
    const latMod = latitudeModifier[Math.min(latBand, latitudeModifier.length - 1)] || 1;
    const windTier = Math.abs(lat - 89) / 30 | 0;
    const { isWest, isEast, isNorth, isSouth } = getWindDirections(windTier, options.winds);
    if (isWest) westerly.push([c, latMod, windTier]);
    if (isEast) easterly.push([c + cellsX - 1, latMod, windTier]);
    if (isNorth) northerly++;
    if (isSouth) southerly++;
  }
  if (westerly.length) passWind(westerly, 120 * modifier, 1, cellsX, grid, prec, modifier, rng);
  if (easterly.length) passWind(easterly, 120 * modifier, -1, cellsX, grid, prec, modifier, rng);
  const vertT = southerly + northerly;
  if (northerly) {
    const bandN = (Math.abs(mapCoordinates.latN) - 1) / 5 | 0;
    const latModN = mapCoordinates.latT > 60 ? latitudeModifier.reduce((a, b) => a + b, 0) / latitudeModifier.length : latitudeModifier[Math.min(bandN, latitudeModifier.length - 1)] || 1;
    const maxPrecN = northerly / vertT * 60 * modifier * latModN;
    const northSource = [];
    for (let i = 0; i < cellsX; i++) {
      northSource.push(i);
    }
    passWind(northSource, maxPrecN, cellsX, cellsY, grid, prec, modifier, rng);
  }
  if (southerly) {
    const bandS = (Math.abs(mapCoordinates.latS) - 1) / 5 | 0;
    const latModS = mapCoordinates.latT > 60 ? latitudeModifier.reduce((a, b) => a + b, 0) / latitudeModifier.length : latitudeModifier[Math.min(bandS, latitudeModifier.length - 1)] || 1;
    const maxPrecS = southerly / vertT * 60 * modifier * latModS;
    const southSource = [];
    for (let i = cells.i.length - cellsX; i < cells.i.length; i++) {
      southSource.push(i);
    }
    passWind(southSource, maxPrecS, -cellsX, cellsY, grid, prec, modifier, rng);
  }
  return prec;
}
function alterHeights(pack) {
  const { h, c, t } = pack.cells;
  return Array.from(h).map((height2, i) => {
    if (height2 < 20 || !t || t[i] < 1) return height2;
    const neighborAvg = c[i] ? c[i].map((cell) => t[cell] || 0).reduce((a, b) => a + b, 0) / c[i].length : 0;
    return height2 + t[i] / 100 + neighborAvg / 1e4;
  });
}
function resolveDepressions(h, pack, maxIterations = 250) {
  const { cells } = pack;
  const land = cells.i.filter((i) => h[i] >= 20 && !cells.b[i]);
  land.sort((a, b) => h[a] - h[b]);
  let depressions = Infinity;
  let prevDepressions = null;
  const progress = [];
  for (let iteration = 0; depressions && iteration < maxIterations; iteration++) {
    if (progress.length > 5 && progress.reduce((a, b) => a + b, 0) > 0) {
      break;
    }
    depressions = 0;
    for (const i of land) {
      if (!cells.c[i] || cells.c[i].length === 0) continue;
      const neighbors = Array.isArray(cells.c[i]) ? cells.c[i] : Array.from(cells.c[i]);
      const minHeight = Math.min(...neighbors.map((c) => h[c]));
      if (minHeight >= 100 || h[i] > minHeight) continue;
      depressions++;
      h[i] = minHeight + 0.1;
    }
    if (prevDepressions !== null) progress.push(depressions - prevDepressions);
    prevDepressions = depressions;
  }
}
function generateRivers({
  grid,
  pack,
  options,
  rng,
  precipitation = null,
  allowErosion = true
}) {
  if (!grid || !pack) {
    throw new Error("Grid and pack objects are required");
  }
  if (!rng) {
    throw new Error("RNG instance is required");
  }
  const { cells } = pack;
  const MIN_FLUX_TO_FORM_RIVER = 30;
  const cellsNumberModifier = (options.cellsDesired / 1e4) ** 0.25;
  if (!precipitation) {
    precipitation = generatePrecipitation({ grid, options, rng });
  }
  if (!grid.cells.prec) {
    grid.cells.prec = precipitation;
  }
  cells.fl = createTypedArray({ maxValue: 65535, length: cells.i.length });
  cells.r = createTypedArray({ maxValue: 65535, length: cells.i.length });
  cells.conf = createTypedArray({ maxValue: 255, length: cells.i.length });
  const riversData = {};
  const riverParents = {};
  let riverNext = 1;
  const addCellToRiver = (cell, river) => {
    if (!riversData[river]) riversData[river] = [cell];
    else riversData[river].push(cell);
  };
  const h = alterHeights(pack);
  resolveDepressions(h, pack, options.resolveDepressionsSteps || 250);
  drainWater();
  defineRivers();
  calculateConfluenceFlux();
  if (allowErosion) {
    cells.h = Uint8Array.from(h);
    downcutRivers();
  }
  return {
    rivers: pack.rivers || [],
    flux: cells.fl,
    riverIds: cells.r,
    confluences: cells.conf
  };
  function drainWater() {
    const land = cells.i.filter((i) => h[i] >= 20).sort((a, b) => h[b] - h[a]);
    land.forEach((i) => {
      const gridCell = cells.g ? cells.g[i] : i;
      cells.fl[i] += precipitation[gridCell] / cellsNumberModifier;
      if (cells.b && cells.b[i] && cells.r[i]) {
        return addCellToRiver(-1, cells.r[i]);
      }
      if (!cells.c || !cells.c[i]) return;
      let neighbors = cells.c[i];
      if (!Array.isArray(neighbors)) {
        if (neighbors && typeof neighbors.length === "number") {
          neighbors = Array.from(neighbors);
        } else {
          return;
        }
      }
      if (neighbors.length === 0) return;
      const min2 = neighbors.sort((a, b) => h[a] - h[b])[0];
      if (h[i] <= h[min2]) return;
      if (cells.fl[i] < MIN_FLUX_TO_FORM_RIVER) {
        if (h[min2] >= 20) cells.fl[min2] += cells.fl[i];
        return;
      }
      if (!cells.r[i]) {
        cells.r[i] = riverNext;
        addCellToRiver(i, riverNext);
        riverNext++;
      }
      flowDown(min2, cells.fl[i], cells.r[i]);
    });
  }
  function flowDown(toCell, fromFlux, river) {
    const toFlux = cells.fl[toCell] - cells.conf[toCell];
    const toRiver = cells.r[toCell];
    if (toRiver) {
      if (fromFlux > toFlux) {
        cells.conf[toCell] += cells.fl[toCell];
        if (h[toCell] >= 20) riverParents[toRiver] = river;
        cells.r[toCell] = river;
      } else {
        cells.conf[toCell] += fromFlux;
        if (h[toCell] >= 20) riverParents[river] = toRiver;
      }
    } else {
      cells.r[toCell] = river;
    }
    if (h[toCell] < 20) {
      if (pack.features && cells.f) {
        const waterBody = pack.features[cells.f[toCell]];
        if (waterBody && waterBody.type === "lake") {
          if (!waterBody.river || fromFlux > waterBody.enteringFlux) {
            waterBody.river = river;
            waterBody.enteringFlux = fromFlux;
          }
          waterBody.flux = (waterBody.flux || 0) + fromFlux;
          if (!waterBody.inlets) waterBody.inlets = [river];
          else waterBody.inlets.push(river);
        }
      }
    } else {
      cells.fl[toCell] += fromFlux;
    }
    addCellToRiver(toCell, river);
  }
  function defineRivers() {
    cells.r = createTypedArray({ maxValue: 65535, length: cells.i.length });
    cells.conf = createTypedArray({ maxValue: 255, length: cells.i.length });
    pack.rivers = [];
    const defaultWidthFactor = rn(1 / (options.cellsDesired / 1e4) ** 0.25, 2);
    const mainStemWidthFactor = defaultWidthFactor * 1.2;
    for (const key in riversData) {
      const riverCells = riversData[key];
      if (riverCells.length < 3) continue;
      const riverId = +key;
      for (const cell of riverCells) {
        if (cell < 0 || cells.h[cell] < 20) continue;
        if (cells.r[cell]) cells.conf[cell] = 1;
        else cells.r[cell] = riverId;
      }
      const source = riverCells[0];
      const mouth = riverCells[riverCells.length - 2] || riverCells[riverCells.length - 1];
      const parent = riverParents[key] || 0;
      const widthFactor = !parent || parent === riverId ? mainStemWidthFactor : defaultWidthFactor;
      const discharge = cells.fl[mouth] || 0;
      const length = getApproximateLength(riverCells);
      const sourceWidth = getSourceWidth(cells.fl[source] || 0);
      const width2 = getWidth(getOffset({ flux: discharge, pointIndex: riverCells.length, widthFactor, startingWidth: sourceWidth }));
      pack.rivers.push({
        i: riverId,
        source,
        mouth,
        discharge,
        length,
        width: width2,
        widthFactor,
        sourceWidth,
        parent,
        cells: riverCells
      });
    }
  }
  function calculateConfluenceFlux() {
    for (const i of cells.i) {
      if (!cells.conf[i]) continue;
      if (!cells.c[i] || cells.c[i].length === 0) continue;
      const neighbors = Array.isArray(cells.c[i]) ? cells.c[i] : Array.from(cells.c[i]);
      const sortedInflux = neighbors.filter((c) => cells.r[c] && h[c] > h[i]).map((c) => cells.fl[c]).sort((a, b) => b - a);
      cells.conf[i] = sortedInflux.reduce((acc, flux, index) => index ? acc + flux : acc, 0);
    }
  }
  function downcutRivers() {
    const MAX_DOWNCUT = 5;
    for (const i of cells.i) {
      if (cells.h[i] < 35) continue;
      if (!cells.fl[i]) continue;
      if (!cells.c[i] || cells.c[i].length === 0) continue;
      const neighbors = Array.isArray(cells.c[i]) ? cells.c[i] : Array.from(cells.c[i]);
      const higherCells = neighbors.filter((c) => cells.h[c] > cells.h[i]);
      if (higherCells.length === 0) continue;
      const higherFlux = higherCells.reduce((acc, c) => acc + cells.fl[c], 0) / higherCells.length;
      if (!higherFlux) continue;
      const downcut = Math.floor(cells.fl[i] / higherFlux);
      if (downcut) cells.h[i] -= Math.min(downcut, MAX_DOWNCUT);
    }
  }
  function getOffset({ flux, pointIndex, widthFactor, startingWidth }) {
    if (pointIndex === 0) return startingWidth;
    const FLUX_FACTOR = 500;
    const MAX_FLUX_WIDTH = 1;
    const LENGTH_FACTOR = 200;
    const LENGTH_STEP_WIDTH = 1 / LENGTH_FACTOR;
    const LENGTH_PROGRESSION = [1, 1, 2, 3, 5, 8, 13, 21, 34].map((n) => n / LENGTH_FACTOR);
    const fluxWidth = Math.min(flux ** 0.7 / FLUX_FACTOR, MAX_FLUX_WIDTH);
    const lengthWidth = pointIndex * LENGTH_STEP_WIDTH + (LENGTH_PROGRESSION[pointIndex] || LENGTH_PROGRESSION[LENGTH_PROGRESSION.length - 1]);
    return widthFactor * (lengthWidth + fluxWidth) + startingWidth;
  }
  function getSourceWidth(flux) {
    const FLUX_FACTOR = 500;
    const MAX_FLUX_WIDTH = 1;
    return rn(Math.min(flux ** 0.9 / FLUX_FACTOR, MAX_FLUX_WIDTH), 2);
  }
  function getWidth(offset) {
    return rn((offset / 1.5) ** 1.8, 2);
  }
  function getApproximateLength(riverCells) {
    if (!cells.p || riverCells.length < 2) return 0;
    let length = 0;
    for (let i = 1; i < riverCells.length; i++) {
      const prev = riverCells[i - 1];
      const curr = riverCells[i];
      if (prev < 0 || curr < 0) continue;
      const [x1, y1] = cells.p[prev];
      const [x2, y2] = cells.p[curr];
      length += Math.hypot(x2 - x1, y2 - y1);
    }
    return rn(length, 2);
  }
}
function calculateSeaLevelTemp(latitude, options) {
  const { temperatureEquator, temperatureNorthPole, temperatureSouthPole } = options;
  const tropics = [16, -20];
  const tropicalGradient = 0.15;
  const tempNorthTropic = temperatureEquator - tropics[0] * tropicalGradient;
  const northernGradient = (tempNorthTropic - temperatureNorthPole) / (90 - tropics[0]);
  const tempSouthTropic = temperatureEquator + tropics[1] * tropicalGradient;
  const southernGradient = (tempSouthTropic - temperatureSouthPole) / (90 + tropics[1]);
  const isTropical = latitude <= 16 && latitude >= -20;
  if (isTropical) return temperatureEquator - Math.abs(latitude) * tropicalGradient;
  return latitude > 0 ? tempNorthTropic - (latitude - tropics[0]) * northernGradient : tempSouthTropic + (latitude - tropics[1]) * southernGradient;
}
function getAltitudeTemperatureDrop(height2, heightExponent) {
  if (height2 < 20) return 0;
  const heightInMeters = Math.pow(height2 - 18, heightExponent);
  return rn(heightInMeters / 1e3 * 6.5);
}
function calculateTemperatures({ grid, options, mapCoordinates: providedMapCoords = null }) {
  if (!grid || !grid.cells) {
    throw new Error("Grid object with cells is required");
  }
  const cells = grid.cells;
  const temp = new Int8Array(cells.i.length);
  let mapCoordinates = providedMapCoords;
  if (!mapCoordinates) {
    const sizeFraction = (options.mapSize || 50) / 100;
    const latShift = options.latitude / 100;
    const latT = rn(sizeFraction * 180, 1);
    const latN = rn(90 - (180 - latT) * latShift, 1);
    mapCoordinates = { latT, latN };
  }
  const { temperatureEquator, temperatureNorthPole, temperatureSouthPole } = options;
  const heightExponent = options.heightExponent || 1.8;
  const height2 = options.mapHeight || 540;
  for (let rowCellId = 0; rowCellId < cells.i.length; rowCellId += grid.cellsX) {
    const [, y2] = grid.points[rowCellId];
    const rowLatitude = mapCoordinates.latN - y2 / height2 * mapCoordinates.latT;
    const tempSeaLevel = calculateSeaLevelTemp(rowLatitude, options);
    for (let cellId = rowCellId; cellId < rowCellId + grid.cellsX && cellId < cells.i.length; cellId++) {
      const tempAltitudeDrop = getAltitudeTemperatureDrop(cells.h[cellId], heightExponent);
      temp[cellId] = minmax(tempSeaLevel - tempAltitudeDrop, -128, 127);
    }
  }
  return temp;
}
const MIN_LAND_HEIGHT$1 = 20;
function getDefaultBiomes() {
  const name = [
    "Marine",
    "Hot desert",
    "Cold desert",
    "Savanna",
    "Grassland",
    "Tropical seasonal forest",
    "Temperate deciduous forest",
    "Tropical rainforest",
    "Temperate rainforest",
    "Taiga",
    "Tundra",
    "Glacier",
    "Wetland"
  ];
  const color2 = [
    "#466eab",
    "#fbe79f",
    "#b5b887",
    "#d2d082",
    "#c8d68f",
    "#b6d95d",
    "#29bc56",
    "#7dcb35",
    "#409c43",
    "#4b6b32",
    "#96784b",
    "#d5e7eb",
    "#0b9131"
  ];
  const habitability = [0, 4, 10, 22, 30, 50, 100, 80, 90, 12, 4, 0, 12];
  const iconsDensity = [0, 3, 2, 120, 120, 120, 120, 150, 150, 100, 5, 0, 250];
  const icons = [
    {},
    { dune: 3, cactus: 6, deadTree: 1 },
    { dune: 9, deadTree: 1 },
    { acacia: 1, grass: 9 },
    { grass: 1 },
    { acacia: 8, palm: 1 },
    { deciduous: 1 },
    { acacia: 5, palm: 3, deciduous: 1, swamp: 1 },
    { deciduous: 6, swamp: 1 },
    { conifer: 1 },
    { grass: 1 },
    {},
    { swamp: 1 }
  ];
  const cost = [10, 200, 150, 60, 50, 70, 70, 80, 90, 200, 1e3, 5e3, 150];
  const biomesMatrix = [
    new Uint8Array([1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 10]),
    new Uint8Array([3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 9, 9, 9, 9, 10, 10, 10]),
    new Uint8Array([5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 9, 9, 9, 9, 9, 10, 10, 10]),
    new Uint8Array([5, 6, 6, 6, 6, 6, 6, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 10, 10, 10]),
    new Uint8Array([7, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 10, 10])
  ];
  const parsedIcons = [];
  for (let i = 0; i < icons.length; i++) {
    const parsed = [];
    for (const icon in icons[i]) {
      for (let j = 0; j < icons[i][icon]; j++) {
        parsed.push(icon);
      }
    }
    parsedIcons.push(parsed);
  }
  return {
    i: Array.from({ length: name.length }, (_, i) => i),
    name,
    color: color2,
    biomesMatrix,
    habitability,
    iconsDensity,
    icons: parsedIcons,
    cost
  };
}
function isWetland(moisture, temperature, height2) {
  if (temperature <= -2) return false;
  if (moisture > 40 && height2 < 25) return true;
  if (moisture > 24 && height2 > 24 && height2 < 60) return true;
  return false;
}
function getBiomeId(moisture, temperature, height2, hasRiver, biomesData) {
  if (height2 < 20) return 0;
  if (temperature < -5) return 11;
  if (temperature >= 25 && !hasRiver && moisture < 8) return 1;
  if (isWetland(moisture, temperature, height2)) return 12;
  const moistureBand = Math.min(moisture / 5 | 0, 4);
  const temperatureBand = Math.min(Math.max(20 - temperature, 0), 25);
  return biomesData.biomesMatrix[moistureBand][temperatureBand];
}
function calculateMoisture(cellId, pack, grid) {
  const { fl: flux, r: riverIds, h: heights, c: neighbors, g: gridReference } = pack.cells;
  const { prec } = grid.cells;
  let moisture = prec[gridReference[cellId]];
  if (riverIds[cellId]) moisture += Math.max(flux[cellId] / 10, 2);
  const moistAround = neighbors[cellId].filter((neibCellId) => heights[neibCellId] >= MIN_LAND_HEIGHT$1).map((c) => prec[gridReference[c]]).concat([moisture]);
  const mean2 = moistAround.reduce((a, b) => a + b, 0) / moistAround.length;
  return rn(4 + mean2);
}
function assignBiomes({ pack, grid, options, biomesData: providedBiomesData = null }) {
  if (!pack || !pack.cells) {
    throw new Error("Pack object with cells is required");
  }
  if (!grid || !grid.cells) {
    throw new Error("Grid object with cells is required");
  }
  const biomesData = providedBiomesData || getDefaultBiomes();
  const { fl: flux, r: riverIds, h: heights, c: neighbors, g: gridReference } = pack.cells;
  const { temp, prec } = grid.cells;
  const biome = createTypedArray({ maxValue: 12, length: pack.cells.i.length });
  for (let cellId = 0; cellId < heights.length; cellId++) {
    const height2 = heights[cellId];
    const moisture = height2 < MIN_LAND_HEIGHT$1 ? 0 : calculateMoisture(cellId, pack, grid);
    const temperature = temp[gridReference[cellId]];
    biome[cellId] = getBiomeId(moisture, temperature, height2, Boolean(riverIds[cellId]), biomesData);
  }
  pack.cells.biome = biome;
  return biome;
}
const DEEPER_LAND = 3;
const LANDLOCKED = 2;
const LAND_COAST = 1;
const UNMARKED = 0;
const WATER_COAST = -1;
const DEEP_WATER = -2;
const INT8_MAX = 127;
function isLand(cellId, pack) {
  return pack.cells.h[cellId] >= 20;
}
function isWater(cellId, pack) {
  return pack.cells.h[cellId] < 20;
}
function markupDistance({ distanceField, neighbors, start: start2, increment, limit = INT8_MAX }) {
  for (let distance = start2, marked = Infinity; marked > 0 && distance !== limit; distance += increment) {
    marked = 0;
    const prevDistance = distance - increment;
    for (let cellId = 0; cellId < neighbors.length; cellId++) {
      if (distanceField[cellId] !== prevDistance) continue;
      for (const neighborId of neighbors[cellId]) {
        if (distanceField[neighborId] !== UNMARKED) continue;
        distanceField[neighborId] = distance;
        marked++;
      }
    }
  }
}
function markupGrid({ grid }) {
  if (!grid || !grid.cells) {
    throw new Error("Grid object with cells is required");
  }
  const { h: heights, c: neighbors, b: borderCells, i } = grid.cells;
  const cellsNumber = i.length;
  const distanceField = new Int8Array(cellsNumber);
  const featureIds = new Uint16Array(cellsNumber);
  const features = [null];
  const queue = [0];
  for (let featureId = 1; queue[0] !== -1; featureId++) {
    const firstCell = queue[0];
    featureIds[firstCell] = featureId;
    const land = heights[firstCell] >= 20;
    let border = false;
    while (queue.length) {
      const cellId = queue.pop();
      if (!border && borderCells[cellId]) border = true;
      if (!neighbors[cellId]) continue;
      for (const neighborId of neighbors[cellId]) {
        if (neighborId < 0 || neighborId >= cellsNumber) continue;
        const isNeibLand = heights[neighborId] >= 20;
        if (land === isNeibLand && featureIds[neighborId] === UNMARKED) {
          featureIds[neighborId] = featureId;
          queue.push(neighborId);
        } else if (land && !isNeibLand) {
          distanceField[cellId] = LAND_COAST;
          distanceField[neighborId] = WATER_COAST;
        }
      }
    }
    const type = land ? "island" : border ? "ocean" : "lake";
    features.push({ i: featureId, land, border, type });
    queue[0] = featureIds.findIndex((f) => f === UNMARKED);
  }
  markupDistance({ distanceField, neighbors, start: DEEP_WATER, increment: -1, limit: -10 });
  grid.cells.t = distanceField;
  grid.cells.f = featureIds;
  grid.features = features;
  return features;
}
function markupPack({ pack }) {
  if (!pack || !pack.cells) {
    throw new Error("Pack object with cells is required");
  }
  const { cells } = pack;
  const { c: neighbors, b: borderCells, i } = cells;
  const packCellsNumber = i.length;
  if (!packCellsNumber) return [];
  const distanceField = new Int8Array(packCellsNumber);
  const featureIds = new Uint16Array(packCellsNumber);
  const haven = createTypedArray({ maxValue: packCellsNumber, length: packCellsNumber });
  const harbor = new Uint8Array(packCellsNumber);
  const features = [null];
  const queue = [0];
  for (let featureId = 1; queue[0] !== -1; featureId++) {
    const firstCell = queue[0];
    featureIds[firstCell] = featureId;
    const land = isLand(firstCell, pack);
    let border = Boolean(borderCells[firstCell]);
    let totalCells = 1;
    while (queue.length) {
      const cellId = queue.pop();
      if (borderCells[cellId]) border = true;
      if (!neighbors[cellId]) continue;
      for (const neighborId of neighbors[cellId]) {
        if (neighborId < 0 || neighborId >= packCellsNumber) continue;
        const isNeibLand = isLand(neighborId, pack);
        if (land && !isNeibLand) {
          distanceField[cellId] = LAND_COAST;
          distanceField[neighborId] = WATER_COAST;
          if (!haven[cellId]) defineHaven(cellId);
        } else if (land && isNeibLand) {
          if (distanceField[neighborId] === UNMARKED && distanceField[cellId] === LAND_COAST)
            distanceField[neighborId] = LANDLOCKED;
          else if (distanceField[cellId] === UNMARKED && distanceField[neighborId] === LAND_COAST)
            distanceField[cellId] = LANDLOCKED;
        }
        if (!featureIds[neighborId] && land === isNeibLand) {
          queue.push(neighborId);
          featureIds[neighborId] = featureId;
          totalCells++;
        }
      }
    }
    features.push(addFeature({ firstCell, land, border, featureId, totalCells }));
    queue[0] = featureIds.findIndex((f) => f === UNMARKED);
  }
  markupDistance({ distanceField, neighbors, start: DEEPER_LAND, increment: 1 });
  markupDistance({ distanceField, neighbors, start: DEEP_WATER, increment: -1, limit: -10 });
  pack.cells.t = distanceField;
  pack.cells.f = featureIds;
  pack.cells.haven = haven;
  pack.cells.harbor = harbor;
  pack.features = features;
  return features;
  function defineHaven(cellId) {
    const waterCells = neighbors[cellId].filter((neibCellId) => isWater(neibCellId, pack));
    if (waterCells.length === 0) return;
    const distances = waterCells.map((neibCellId) => dist2$1(cells.p[cellId], cells.p[neibCellId]));
    const closest = distances.indexOf(Math.min(...distances));
    haven[cellId] = waterCells[closest];
    harbor[cellId] = waterCells.length;
  }
  function addFeature({ firstCell, land, border, featureId, totalCells }) {
    const type = land ? "island" : border ? "ocean" : "lake";
    const feature = {
      i: featureId,
      type,
      land,
      border,
      cells: totalCells,
      firstCell
    };
    if (type === "lake") {
      feature.height = 0;
      feature.shoreline = [];
    }
    return feature;
  }
}
function specifyFeatures({ pack, grid, options }) {
  if (!pack || !pack.features) {
    throw new Error("Pack object with features is required");
  }
  const gridCellsNumber = grid.cells.i.length;
  const OCEAN_MIN_SIZE = gridCellsNumber / 25;
  const SEA_MIN_SIZE = gridCellsNumber / 1e3;
  const CONTINENT_MIN_SIZE = gridCellsNumber / 10;
  const ISLAND_MIN_SIZE = gridCellsNumber / 1e3;
  for (const feature of pack.features) {
    if (!feature || feature.type === "ocean") continue;
    feature.group = defineGroup(feature);
  }
  function defineGroup(feature) {
    if (feature.type === "island") return defineIslandGroup(feature);
    if (feature.type === "ocean") return defineOceanGroup(feature);
    if (feature.type === "lake") return defineLakeGroup(feature);
    return "unknown";
  }
  function defineOceanGroup(feature) {
    if (feature.cells > OCEAN_MIN_SIZE) return "ocean";
    if (feature.cells > SEA_MIN_SIZE) return "sea";
    return "gulf";
  }
  function defineIslandGroup(feature) {
    const prevFeature = pack.features[pack.cells.f[feature.firstCell - 1]];
    if (prevFeature && prevFeature.type === "lake") return "lake_island";
    if (feature.cells > CONTINENT_MIN_SIZE) return "continent";
    if (feature.cells > ISLAND_MIN_SIZE) return "island";
    return "isle";
  }
  function defineLakeGroup(feature) {
    if (feature.temp < -3) return "frozen";
    if (!feature.outlet && feature.evaporation > feature.flux) return "salt";
    return "freshwater";
  }
}
function ascending$1(a, b) {
  return a == null || b == null ? NaN : a < b ? -1 : a > b ? 1 : a >= b ? 0 : NaN;
}
function* numbers(values, valueof) {
  {
    for (let value of values) {
      if (value != null && (value = +value) >= value) {
        yield value;
      }
    }
  }
}
function compareDefined(compare = ascending$1) {
  if (compare === ascending$1) return ascendingDefined;
  if (typeof compare !== "function") throw new TypeError("compare is not a function");
  return (a, b) => {
    const x2 = compare(a, b);
    if (x2 || x2 === 0) return x2;
    return (compare(b, b) === 0) - (compare(a, a) === 0);
  };
}
function ascendingDefined(a, b) {
  return (a == null || !(a >= a)) - (b == null || !(b >= b)) || (a < b ? -1 : a > b ? 1 : 0);
}
const e10 = Math.sqrt(50), e5 = Math.sqrt(10), e2 = Math.sqrt(2);
function tickSpec(start2, stop, count) {
  const step = (stop - start2) / Math.max(0, count), power = Math.floor(Math.log10(step)), error = step / Math.pow(10, power), factor = error >= e10 ? 10 : error >= e5 ? 5 : error >= e2 ? 2 : 1;
  let i1, i2, inc;
  if (power < 0) {
    inc = Math.pow(10, -power) / factor;
    i1 = Math.round(start2 * inc);
    i2 = Math.round(stop * inc);
    if (i1 / inc < start2) ++i1;
    if (i2 / inc > stop) --i2;
    inc = -inc;
  } else {
    inc = Math.pow(10, power) * factor;
    i1 = Math.round(start2 / inc);
    i2 = Math.round(stop / inc);
    if (i1 * inc < start2) ++i1;
    if (i2 * inc > stop) --i2;
  }
  if (i2 < i1 && 0.5 <= count && count < 2) return tickSpec(start2, stop, count * 2);
  return [i1, i2, inc];
}
function ticks(start2, stop, count) {
  stop = +stop, start2 = +start2, count = +count;
  if (!(count > 0)) return [];
  if (start2 === stop) return [start2];
  const reverse = stop < start2, [i1, i2, inc] = reverse ? tickSpec(stop, start2, count) : tickSpec(start2, stop, count);
  if (!(i2 >= i1)) return [];
  const n = i2 - i1 + 1, ticks2 = new Array(n);
  if (reverse) {
    if (inc < 0) for (let i = 0; i < n; ++i) ticks2[i] = (i2 - i) / -inc;
    else for (let i = 0; i < n; ++i) ticks2[i] = (i2 - i) * inc;
  } else {
    if (inc < 0) for (let i = 0; i < n; ++i) ticks2[i] = (i1 + i) / -inc;
    else for (let i = 0; i < n; ++i) ticks2[i] = (i1 + i) * inc;
  }
  return ticks2;
}
function tickIncrement(start2, stop, count) {
  stop = +stop, start2 = +start2, count = +count;
  return tickSpec(start2, stop, count)[2];
}
function tickStep(start2, stop, count) {
  stop = +stop, start2 = +start2, count = +count;
  const reverse = stop < start2, inc = reverse ? tickIncrement(stop, start2, count) : tickIncrement(start2, stop, count);
  return (reverse ? -1 : 1) * (inc < 0 ? 1 / -inc : inc);
}
function max(values, valueof) {
  let max2;
  {
    for (const value of values) {
      if (value != null && (max2 < value || max2 === void 0 && value >= value)) {
        max2 = value;
      }
    }
  }
  return max2;
}
function min(values, valueof) {
  let min2;
  {
    for (const value of values) {
      if (value != null && (min2 > value || min2 === void 0 && value >= value)) {
        min2 = value;
      }
    }
  }
  return min2;
}
function quickselect(array2, k, left = 0, right = Infinity, compare) {
  k = Math.floor(k);
  left = Math.floor(Math.max(0, left));
  right = Math.floor(Math.min(array2.length - 1, right));
  if (!(left <= k && k <= right)) return array2;
  compare = compare === void 0 ? ascendingDefined : compareDefined(compare);
  while (right > left) {
    if (right - left > 600) {
      const n = right - left + 1;
      const m = k - left + 1;
      const z = Math.log(n);
      const s = 0.5 * Math.exp(2 * z / 3);
      const sd = 0.5 * Math.sqrt(z * s * (n - s) / n) * (m - n / 2 < 0 ? -1 : 1);
      const newLeft = Math.max(left, Math.floor(k - m * s / n + sd));
      const newRight = Math.min(right, Math.floor(k + (n - m) * s / n + sd));
      quickselect(array2, k, newLeft, newRight, compare);
    }
    const t = array2[k];
    let i = left;
    let j = right;
    swap(array2, left, k);
    if (compare(array2[right], t) > 0) swap(array2, left, right);
    while (i < j) {
      swap(array2, i, j), ++i, --j;
      while (compare(array2[i], t) < 0) ++i;
      while (compare(array2[j], t) > 0) --j;
    }
    if (compare(array2[left], t) === 0) swap(array2, left, j);
    else ++j, swap(array2, j, right);
    if (j <= k) left = j + 1;
    if (k <= j) right = j - 1;
  }
  return array2;
}
function swap(array2, i, j) {
  const t = array2[i];
  array2[i] = array2[j];
  array2[j] = t;
}
function quantile(values, p, valueof) {
  values = Float64Array.from(numbers(values));
  if (!(n = values.length) || isNaN(p = +p)) return;
  if (p <= 0 || n < 2) return min(values);
  if (p >= 1) return max(values);
  var n, i = (n - 1) * p, i0 = Math.floor(i), value0 = max(quickselect(values, i0).subarray(0, i0 + 1)), value1 = min(values.subarray(i0 + 1));
  return value0 + (value1 - value0) * (i - i0);
}
function mean(values, valueof) {
  let count = 0;
  let sum = 0;
  {
    for (let value of values) {
      if (value != null && (value = +value) >= value) {
        ++count, sum += value;
      }
    }
  }
  if (count) return sum / count;
}
function median(values, valueof) {
  return quantile(values, 0.5);
}
var noop$1 = { value: () => {
} };
function dispatch() {
  for (var i = 0, n = arguments.length, _ = {}, t; i < n; ++i) {
    if (!(t = arguments[i] + "") || t in _ || /[\s.]/.test(t)) throw new Error("illegal type: " + t);
    _[t] = [];
  }
  return new Dispatch(_);
}
function Dispatch(_) {
  this._ = _;
}
function parseTypenames$1(typenames, types) {
  return typenames.trim().split(/^|\s+/).map(function(t) {
    var name = "", i = t.indexOf(".");
    if (i >= 0) name = t.slice(i + 1), t = t.slice(0, i);
    if (t && !types.hasOwnProperty(t)) throw new Error("unknown type: " + t);
    return { type: t, name };
  });
}
Dispatch.prototype = dispatch.prototype = {
  constructor: Dispatch,
  on: function(typename, callback) {
    var _ = this._, T = parseTypenames$1(typename + "", _), t, i = -1, n = T.length;
    if (arguments.length < 2) {
      while (++i < n) if ((t = (typename = T[i]).type) && (t = get$1(_[t], typename.name))) return t;
      return;
    }
    if (callback != null && typeof callback !== "function") throw new Error("invalid callback: " + callback);
    while (++i < n) {
      if (t = (typename = T[i]).type) _[t] = set$1(_[t], typename.name, callback);
      else if (callback == null) for (t in _) _[t] = set$1(_[t], typename.name, null);
    }
    return this;
  },
  copy: function() {
    var copy2 = {}, _ = this._;
    for (var t in _) copy2[t] = _[t].slice();
    return new Dispatch(copy2);
  },
  call: function(type, that) {
    if ((n = arguments.length - 2) > 0) for (var args = new Array(n), i = 0, n, t; i < n; ++i) args[i] = arguments[i + 2];
    if (!this._.hasOwnProperty(type)) throw new Error("unknown type: " + type);
    for (t = this._[type], i = 0, n = t.length; i < n; ++i) t[i].value.apply(that, args);
  },
  apply: function(type, that, args) {
    if (!this._.hasOwnProperty(type)) throw new Error("unknown type: " + type);
    for (var t = this._[type], i = 0, n = t.length; i < n; ++i) t[i].value.apply(that, args);
  }
};
function get$1(type, name) {
  for (var i = 0, n = type.length, c; i < n; ++i) {
    if ((c = type[i]).name === name) {
      return c.value;
    }
  }
}
function set$1(type, name, callback) {
  for (var i = 0, n = type.length; i < n; ++i) {
    if (type[i].name === name) {
      type[i] = noop$1, type = type.slice(0, i).concat(type.slice(i + 1));
      break;
    }
  }
  if (callback != null) type.push({ name, value: callback });
  return type;
}
var xhtml = "http://www.w3.org/1999/xhtml";
const namespaces = {
  svg: "http://www.w3.org/2000/svg",
  xhtml,
  xlink: "http://www.w3.org/1999/xlink",
  xml: "http://www.w3.org/XML/1998/namespace",
  xmlns: "http://www.w3.org/2000/xmlns/"
};
function namespace(name) {
  var prefix = name += "", i = prefix.indexOf(":");
  if (i >= 0 && (prefix = name.slice(0, i)) !== "xmlns") name = name.slice(i + 1);
  return namespaces.hasOwnProperty(prefix) ? { space: namespaces[prefix], local: name } : name;
}
function creatorInherit(name) {
  return function() {
    var document2 = this.ownerDocument, uri = this.namespaceURI;
    return uri === xhtml && document2.documentElement.namespaceURI === xhtml ? document2.createElement(name) : document2.createElementNS(uri, name);
  };
}
function creatorFixed(fullname) {
  return function() {
    return this.ownerDocument.createElementNS(fullname.space, fullname.local);
  };
}
function creator(name) {
  var fullname = namespace(name);
  return (fullname.local ? creatorFixed : creatorInherit)(fullname);
}
function none() {
}
function selector(selector2) {
  return selector2 == null ? none : function() {
    return this.querySelector(selector2);
  };
}
function selection_select(select) {
  if (typeof select !== "function") select = selector(select);
  for (var groups = this._groups, m = groups.length, subgroups = new Array(m), j = 0; j < m; ++j) {
    for (var group = groups[j], n = group.length, subgroup = subgroups[j] = new Array(n), node, subnode, i = 0; i < n; ++i) {
      if ((node = group[i]) && (subnode = select.call(node, node.__data__, i, group))) {
        if ("__data__" in node) subnode.__data__ = node.__data__;
        subgroup[i] = subnode;
      }
    }
  }
  return new Selection$1(subgroups, this._parents);
}
function array$1(x2) {
  return x2 == null ? [] : Array.isArray(x2) ? x2 : Array.from(x2);
}
function empty() {
  return [];
}
function selectorAll(selector2) {
  return selector2 == null ? empty : function() {
    return this.querySelectorAll(selector2);
  };
}
function arrayAll(select) {
  return function() {
    return array$1(select.apply(this, arguments));
  };
}
function selection_selectAll(select) {
  if (typeof select === "function") select = arrayAll(select);
  else select = selectorAll(select);
  for (var groups = this._groups, m = groups.length, subgroups = [], parents = [], j = 0; j < m; ++j) {
    for (var group = groups[j], n = group.length, node, i = 0; i < n; ++i) {
      if (node = group[i]) {
        subgroups.push(select.call(node, node.__data__, i, group));
        parents.push(node);
      }
    }
  }
  return new Selection$1(subgroups, parents);
}
function matcher(selector2) {
  return function() {
    return this.matches(selector2);
  };
}
function childMatcher(selector2) {
  return function(node) {
    return node.matches(selector2);
  };
}
var find = Array.prototype.find;
function childFind(match) {
  return function() {
    return find.call(this.children, match);
  };
}
function childFirst() {
  return this.firstElementChild;
}
function selection_selectChild(match) {
  return this.select(match == null ? childFirst : childFind(typeof match === "function" ? match : childMatcher(match)));
}
var filter = Array.prototype.filter;
function children() {
  return Array.from(this.children);
}
function childrenFilter(match) {
  return function() {
    return filter.call(this.children, match);
  };
}
function selection_selectChildren(match) {
  return this.selectAll(match == null ? children : childrenFilter(typeof match === "function" ? match : childMatcher(match)));
}
function selection_filter(match) {
  if (typeof match !== "function") match = matcher(match);
  for (var groups = this._groups, m = groups.length, subgroups = new Array(m), j = 0; j < m; ++j) {
    for (var group = groups[j], n = group.length, subgroup = subgroups[j] = [], node, i = 0; i < n; ++i) {
      if ((node = group[i]) && match.call(node, node.__data__, i, group)) {
        subgroup.push(node);
      }
    }
  }
  return new Selection$1(subgroups, this._parents);
}
function sparse(update) {
  return new Array(update.length);
}
function selection_enter() {
  return new Selection$1(this._enter || this._groups.map(sparse), this._parents);
}
function EnterNode(parent, datum2) {
  this.ownerDocument = parent.ownerDocument;
  this.namespaceURI = parent.namespaceURI;
  this._next = null;
  this._parent = parent;
  this.__data__ = datum2;
}
EnterNode.prototype = {
  constructor: EnterNode,
  appendChild: function(child) {
    return this._parent.insertBefore(child, this._next);
  },
  insertBefore: function(child, next) {
    return this._parent.insertBefore(child, next);
  },
  querySelector: function(selector2) {
    return this._parent.querySelector(selector2);
  },
  querySelectorAll: function(selector2) {
    return this._parent.querySelectorAll(selector2);
  }
};
function constant$2(x2) {
  return function() {
    return x2;
  };
}
function bindIndex(parent, group, enter, update, exit, data) {
  var i = 0, node, groupLength = group.length, dataLength = data.length;
  for (; i < dataLength; ++i) {
    if (node = group[i]) {
      node.__data__ = data[i];
      update[i] = node;
    } else {
      enter[i] = new EnterNode(parent, data[i]);
    }
  }
  for (; i < groupLength; ++i) {
    if (node = group[i]) {
      exit[i] = node;
    }
  }
}
function bindKey(parent, group, enter, update, exit, data, key) {
  var i, node, nodeByKeyValue = /* @__PURE__ */ new Map(), groupLength = group.length, dataLength = data.length, keyValues = new Array(groupLength), keyValue;
  for (i = 0; i < groupLength; ++i) {
    if (node = group[i]) {
      keyValues[i] = keyValue = key.call(node, node.__data__, i, group) + "";
      if (nodeByKeyValue.has(keyValue)) {
        exit[i] = node;
      } else {
        nodeByKeyValue.set(keyValue, node);
      }
    }
  }
  for (i = 0; i < dataLength; ++i) {
    keyValue = key.call(parent, data[i], i, data) + "";
    if (node = nodeByKeyValue.get(keyValue)) {
      update[i] = node;
      node.__data__ = data[i];
      nodeByKeyValue.delete(keyValue);
    } else {
      enter[i] = new EnterNode(parent, data[i]);
    }
  }
  for (i = 0; i < groupLength; ++i) {
    if ((node = group[i]) && nodeByKeyValue.get(keyValues[i]) === node) {
      exit[i] = node;
    }
  }
}
function datum(node) {
  return node.__data__;
}
function selection_data(value, key) {
  if (!arguments.length) return Array.from(this, datum);
  var bind = key ? bindKey : bindIndex, parents = this._parents, groups = this._groups;
  if (typeof value !== "function") value = constant$2(value);
  for (var m = groups.length, update = new Array(m), enter = new Array(m), exit = new Array(m), j = 0; j < m; ++j) {
    var parent = parents[j], group = groups[j], groupLength = group.length, data = arraylike(value.call(parent, parent && parent.__data__, j, parents)), dataLength = data.length, enterGroup = enter[j] = new Array(dataLength), updateGroup = update[j] = new Array(dataLength), exitGroup = exit[j] = new Array(groupLength);
    bind(parent, group, enterGroup, updateGroup, exitGroup, data, key);
    for (var i0 = 0, i1 = 0, previous, next; i0 < dataLength; ++i0) {
      if (previous = enterGroup[i0]) {
        if (i0 >= i1) i1 = i0 + 1;
        while (!(next = updateGroup[i1]) && ++i1 < dataLength) ;
        previous._next = next || null;
      }
    }
  }
  update = new Selection$1(update, parents);
  update._enter = enter;
  update._exit = exit;
  return update;
}
function arraylike(data) {
  return typeof data === "object" && "length" in data ? data : Array.from(data);
}
function selection_exit() {
  return new Selection$1(this._exit || this._groups.map(sparse), this._parents);
}
function selection_join(onenter, onupdate, onexit) {
  var enter = this.enter(), update = this, exit = this.exit();
  if (typeof onenter === "function") {
    enter = onenter(enter);
    if (enter) enter = enter.selection();
  } else {
    enter = enter.append(onenter + "");
  }
  if (onupdate != null) {
    update = onupdate(update);
    if (update) update = update.selection();
  }
  if (onexit == null) exit.remove();
  else onexit(exit);
  return enter && update ? enter.merge(update).order() : update;
}
function selection_merge(context) {
  var selection2 = context.selection ? context.selection() : context;
  for (var groups0 = this._groups, groups1 = selection2._groups, m0 = groups0.length, m1 = groups1.length, m = Math.min(m0, m1), merges = new Array(m0), j = 0; j < m; ++j) {
    for (var group0 = groups0[j], group1 = groups1[j], n = group0.length, merge = merges[j] = new Array(n), node, i = 0; i < n; ++i) {
      if (node = group0[i] || group1[i]) {
        merge[i] = node;
      }
    }
  }
  for (; j < m0; ++j) {
    merges[j] = groups0[j];
  }
  return new Selection$1(merges, this._parents);
}
function selection_order() {
  for (var groups = this._groups, j = -1, m = groups.length; ++j < m; ) {
    for (var group = groups[j], i = group.length - 1, next = group[i], node; --i >= 0; ) {
      if (node = group[i]) {
        if (next && node.compareDocumentPosition(next) ^ 4) next.parentNode.insertBefore(node, next);
        next = node;
      }
    }
  }
  return this;
}
function selection_sort(compare) {
  if (!compare) compare = ascending;
  function compareNode(a, b) {
    return a && b ? compare(a.__data__, b.__data__) : !a - !b;
  }
  for (var groups = this._groups, m = groups.length, sortgroups = new Array(m), j = 0; j < m; ++j) {
    for (var group = groups[j], n = group.length, sortgroup = sortgroups[j] = new Array(n), node, i = 0; i < n; ++i) {
      if (node = group[i]) {
        sortgroup[i] = node;
      }
    }
    sortgroup.sort(compareNode);
  }
  return new Selection$1(sortgroups, this._parents).order();
}
function ascending(a, b) {
  return a < b ? -1 : a > b ? 1 : a >= b ? 0 : NaN;
}
function selection_call() {
  var callback = arguments[0];
  arguments[0] = this;
  callback.apply(null, arguments);
  return this;
}
function selection_nodes() {
  return Array.from(this);
}
function selection_node() {
  for (var groups = this._groups, j = 0, m = groups.length; j < m; ++j) {
    for (var group = groups[j], i = 0, n = group.length; i < n; ++i) {
      var node = group[i];
      if (node) return node;
    }
  }
  return null;
}
function selection_size() {
  let size = 0;
  for (const node of this) ++size;
  return size;
}
function selection_empty() {
  return !this.node();
}
function selection_each(callback) {
  for (var groups = this._groups, j = 0, m = groups.length; j < m; ++j) {
    for (var group = groups[j], i = 0, n = group.length, node; i < n; ++i) {
      if (node = group[i]) callback.call(node, node.__data__, i, group);
    }
  }
  return this;
}
function attrRemove$1(name) {
  return function() {
    this.removeAttribute(name);
  };
}
function attrRemoveNS$1(fullname) {
  return function() {
    this.removeAttributeNS(fullname.space, fullname.local);
  };
}
function attrConstant$1(name, value) {
  return function() {
    this.setAttribute(name, value);
  };
}
function attrConstantNS$1(fullname, value) {
  return function() {
    this.setAttributeNS(fullname.space, fullname.local, value);
  };
}
function attrFunction$1(name, value) {
  return function() {
    var v = value.apply(this, arguments);
    if (v == null) this.removeAttribute(name);
    else this.setAttribute(name, v);
  };
}
function attrFunctionNS$1(fullname, value) {
  return function() {
    var v = value.apply(this, arguments);
    if (v == null) this.removeAttributeNS(fullname.space, fullname.local);
    else this.setAttributeNS(fullname.space, fullname.local, v);
  };
}
function selection_attr(name, value) {
  var fullname = namespace(name);
  if (arguments.length < 2) {
    var node = this.node();
    return fullname.local ? node.getAttributeNS(fullname.space, fullname.local) : node.getAttribute(fullname);
  }
  return this.each((value == null ? fullname.local ? attrRemoveNS$1 : attrRemove$1 : typeof value === "function" ? fullname.local ? attrFunctionNS$1 : attrFunction$1 : fullname.local ? attrConstantNS$1 : attrConstant$1)(fullname, value));
}
function defaultView(node) {
  return node.ownerDocument && node.ownerDocument.defaultView || node.document && node || node.defaultView;
}
function styleRemove$1(name) {
  return function() {
    this.style.removeProperty(name);
  };
}
function styleConstant$1(name, value, priority) {
  return function() {
    this.style.setProperty(name, value, priority);
  };
}
function styleFunction$1(name, value, priority) {
  return function() {
    var v = value.apply(this, arguments);
    if (v == null) this.style.removeProperty(name);
    else this.style.setProperty(name, v, priority);
  };
}
function selection_style(name, value, priority) {
  return arguments.length > 1 ? this.each((value == null ? styleRemove$1 : typeof value === "function" ? styleFunction$1 : styleConstant$1)(name, value, priority == null ? "" : priority)) : styleValue(this.node(), name);
}
function styleValue(node, name) {
  return node.style.getPropertyValue(name) || defaultView(node).getComputedStyle(node, null).getPropertyValue(name);
}
function propertyRemove(name) {
  return function() {
    delete this[name];
  };
}
function propertyConstant(name, value) {
  return function() {
    this[name] = value;
  };
}
function propertyFunction(name, value) {
  return function() {
    var v = value.apply(this, arguments);
    if (v == null) delete this[name];
    else this[name] = v;
  };
}
function selection_property(name, value) {
  return arguments.length > 1 ? this.each((value == null ? propertyRemove : typeof value === "function" ? propertyFunction : propertyConstant)(name, value)) : this.node()[name];
}
function classArray(string) {
  return string.trim().split(/^|\s+/);
}
function classList(node) {
  return node.classList || new ClassList(node);
}
function ClassList(node) {
  this._node = node;
  this._names = classArray(node.getAttribute("class") || "");
}
ClassList.prototype = {
  add: function(name) {
    var i = this._names.indexOf(name);
    if (i < 0) {
      this._names.push(name);
      this._node.setAttribute("class", this._names.join(" "));
    }
  },
  remove: function(name) {
    var i = this._names.indexOf(name);
    if (i >= 0) {
      this._names.splice(i, 1);
      this._node.setAttribute("class", this._names.join(" "));
    }
  },
  contains: function(name) {
    return this._names.indexOf(name) >= 0;
  }
};
function classedAdd(node, names) {
  var list = classList(node), i = -1, n = names.length;
  while (++i < n) list.add(names[i]);
}
function classedRemove(node, names) {
  var list = classList(node), i = -1, n = names.length;
  while (++i < n) list.remove(names[i]);
}
function classedTrue(names) {
  return function() {
    classedAdd(this, names);
  };
}
function classedFalse(names) {
  return function() {
    classedRemove(this, names);
  };
}
function classedFunction(names, value) {
  return function() {
    (value.apply(this, arguments) ? classedAdd : classedRemove)(this, names);
  };
}
function selection_classed(name, value) {
  var names = classArray(name + "");
  if (arguments.length < 2) {
    var list = classList(this.node()), i = -1, n = names.length;
    while (++i < n) if (!list.contains(names[i])) return false;
    return true;
  }
  return this.each((typeof value === "function" ? classedFunction : value ? classedTrue : classedFalse)(names, value));
}
function textRemove() {
  this.textContent = "";
}
function textConstant$1(value) {
  return function() {
    this.textContent = value;
  };
}
function textFunction$1(value) {
  return function() {
    var v = value.apply(this, arguments);
    this.textContent = v == null ? "" : v;
  };
}
function selection_text(value) {
  return arguments.length ? this.each(value == null ? textRemove : (typeof value === "function" ? textFunction$1 : textConstant$1)(value)) : this.node().textContent;
}
function htmlRemove() {
  this.innerHTML = "";
}
function htmlConstant(value) {
  return function() {
    this.innerHTML = value;
  };
}
function htmlFunction(value) {
  return function() {
    var v = value.apply(this, arguments);
    this.innerHTML = v == null ? "" : v;
  };
}
function selection_html(value) {
  return arguments.length ? this.each(value == null ? htmlRemove : (typeof value === "function" ? htmlFunction : htmlConstant)(value)) : this.node().innerHTML;
}
function raise() {
  if (this.nextSibling) this.parentNode.appendChild(this);
}
function selection_raise() {
  return this.each(raise);
}
function lower() {
  if (this.previousSibling) this.parentNode.insertBefore(this, this.parentNode.firstChild);
}
function selection_lower() {
  return this.each(lower);
}
function selection_append(name) {
  var create2 = typeof name === "function" ? name : creator(name);
  return this.select(function() {
    return this.appendChild(create2.apply(this, arguments));
  });
}
function constantNull() {
  return null;
}
function selection_insert(name, before) {
  var create2 = typeof name === "function" ? name : creator(name), select = before == null ? constantNull : typeof before === "function" ? before : selector(before);
  return this.select(function() {
    return this.insertBefore(create2.apply(this, arguments), select.apply(this, arguments) || null);
  });
}
function remove() {
  var parent = this.parentNode;
  if (parent) parent.removeChild(this);
}
function selection_remove() {
  return this.each(remove);
}
function selection_cloneShallow() {
  var clone = this.cloneNode(false), parent = this.parentNode;
  return parent ? parent.insertBefore(clone, this.nextSibling) : clone;
}
function selection_cloneDeep() {
  var clone = this.cloneNode(true), parent = this.parentNode;
  return parent ? parent.insertBefore(clone, this.nextSibling) : clone;
}
function selection_clone(deep) {
  return this.select(deep ? selection_cloneDeep : selection_cloneShallow);
}
function selection_datum(value) {
  return arguments.length ? this.property("__data__", value) : this.node().__data__;
}
function contextListener(listener) {
  return function(event) {
    listener.call(this, event, this.__data__);
  };
}
function parseTypenames(typenames) {
  return typenames.trim().split(/^|\s+/).map(function(t) {
    var name = "", i = t.indexOf(".");
    if (i >= 0) name = t.slice(i + 1), t = t.slice(0, i);
    return { type: t, name };
  });
}
function onRemove(typename) {
  return function() {
    var on = this.__on;
    if (!on) return;
    for (var j = 0, i = -1, m = on.length, o; j < m; ++j) {
      if (o = on[j], (!typename.type || o.type === typename.type) && o.name === typename.name) {
        this.removeEventListener(o.type, o.listener, o.options);
      } else {
        on[++i] = o;
      }
    }
    if (++i) on.length = i;
    else delete this.__on;
  };
}
function onAdd(typename, value, options) {
  return function() {
    var on = this.__on, o, listener = contextListener(value);
    if (on) for (var j = 0, m = on.length; j < m; ++j) {
      if ((o = on[j]).type === typename.type && o.name === typename.name) {
        this.removeEventListener(o.type, o.listener, o.options);
        this.addEventListener(o.type, o.listener = listener, o.options = options);
        o.value = value;
        return;
      }
    }
    this.addEventListener(typename.type, listener, options);
    o = { type: typename.type, name: typename.name, value, listener, options };
    if (!on) this.__on = [o];
    else on.push(o);
  };
}
function selection_on(typename, value, options) {
  var typenames = parseTypenames(typename + ""), i, n = typenames.length, t;
  if (arguments.length < 2) {
    var on = this.node().__on;
    if (on) for (var j = 0, m = on.length, o; j < m; ++j) {
      for (i = 0, o = on[j]; i < n; ++i) {
        if ((t = typenames[i]).type === o.type && t.name === o.name) {
          return o.value;
        }
      }
    }
    return;
  }
  on = value ? onAdd : onRemove;
  for (i = 0; i < n; ++i) this.each(on(typenames[i], value, options));
  return this;
}
function dispatchEvent(node, type, params) {
  var window2 = defaultView(node), event = window2.CustomEvent;
  if (typeof event === "function") {
    event = new event(type, params);
  } else {
    event = window2.document.createEvent("Event");
    if (params) event.initEvent(type, params.bubbles, params.cancelable), event.detail = params.detail;
    else event.initEvent(type, false, false);
  }
  node.dispatchEvent(event);
}
function dispatchConstant(type, params) {
  return function() {
    return dispatchEvent(this, type, params);
  };
}
function dispatchFunction(type, params) {
  return function() {
    return dispatchEvent(this, type, params.apply(this, arguments));
  };
}
function selection_dispatch(type, params) {
  return this.each((typeof params === "function" ? dispatchFunction : dispatchConstant)(type, params));
}
function* selection_iterator() {
  for (var groups = this._groups, j = 0, m = groups.length; j < m; ++j) {
    for (var group = groups[j], i = 0, n = group.length, node; i < n; ++i) {
      if (node = group[i]) yield node;
    }
  }
}
var root = [null];
function Selection$1(groups, parents) {
  this._groups = groups;
  this._parents = parents;
}
function selection() {
  return new Selection$1([[document.documentElement]], root);
}
function selection_selection() {
  return this;
}
Selection$1.prototype = selection.prototype = {
  constructor: Selection$1,
  select: selection_select,
  selectAll: selection_selectAll,
  selectChild: selection_selectChild,
  selectChildren: selection_selectChildren,
  filter: selection_filter,
  data: selection_data,
  enter: selection_enter,
  exit: selection_exit,
  join: selection_join,
  merge: selection_merge,
  selection: selection_selection,
  order: selection_order,
  sort: selection_sort,
  call: selection_call,
  nodes: selection_nodes,
  node: selection_node,
  size: selection_size,
  empty: selection_empty,
  each: selection_each,
  attr: selection_attr,
  style: selection_style,
  property: selection_property,
  classed: selection_classed,
  text: selection_text,
  html: selection_html,
  raise: selection_raise,
  lower: selection_lower,
  append: selection_append,
  insert: selection_insert,
  remove: selection_remove,
  clone: selection_clone,
  datum: selection_datum,
  on: selection_on,
  dispatch: selection_dispatch,
  [Symbol.iterator]: selection_iterator
};
function define(constructor, factory, prototype) {
  constructor.prototype = factory.prototype = prototype;
  prototype.constructor = constructor;
}
function extend(parent, definition) {
  var prototype = Object.create(parent.prototype);
  for (var key in definition) prototype[key] = definition[key];
  return prototype;
}
function Color() {
}
var darker = 0.7;
var brighter = 1 / darker;
var reI = "\\s*([+-]?\\d+)\\s*", reN = "\\s*([+-]?(?:\\d*\\.)?\\d+(?:[eE][+-]?\\d+)?)\\s*", reP = "\\s*([+-]?(?:\\d*\\.)?\\d+(?:[eE][+-]?\\d+)?)%\\s*", reHex = /^#([0-9a-f]{3,8})$/, reRgbInteger = new RegExp(`^rgb\\(${reI},${reI},${reI}\\)$`), reRgbPercent = new RegExp(`^rgb\\(${reP},${reP},${reP}\\)$`), reRgbaInteger = new RegExp(`^rgba\\(${reI},${reI},${reI},${reN}\\)$`), reRgbaPercent = new RegExp(`^rgba\\(${reP},${reP},${reP},${reN}\\)$`), reHslPercent = new RegExp(`^hsl\\(${reN},${reP},${reP}\\)$`), reHslaPercent = new RegExp(`^hsla\\(${reN},${reP},${reP},${reN}\\)$`);
var named = {
  aliceblue: 15792383,
  antiquewhite: 16444375,
  aqua: 65535,
  aquamarine: 8388564,
  azure: 15794175,
  beige: 16119260,
  bisque: 16770244,
  black: 0,
  blanchedalmond: 16772045,
  blue: 255,
  blueviolet: 9055202,
  brown: 10824234,
  burlywood: 14596231,
  cadetblue: 6266528,
  chartreuse: 8388352,
  chocolate: 13789470,
  coral: 16744272,
  cornflowerblue: 6591981,
  cornsilk: 16775388,
  crimson: 14423100,
  cyan: 65535,
  darkblue: 139,
  darkcyan: 35723,
  darkgoldenrod: 12092939,
  darkgray: 11119017,
  darkgreen: 25600,
  darkgrey: 11119017,
  darkkhaki: 12433259,
  darkmagenta: 9109643,
  darkolivegreen: 5597999,
  darkorange: 16747520,
  darkorchid: 10040012,
  darkred: 9109504,
  darksalmon: 15308410,
  darkseagreen: 9419919,
  darkslateblue: 4734347,
  darkslategray: 3100495,
  darkslategrey: 3100495,
  darkturquoise: 52945,
  darkviolet: 9699539,
  deeppink: 16716947,
  deepskyblue: 49151,
  dimgray: 6908265,
  dimgrey: 6908265,
  dodgerblue: 2003199,
  firebrick: 11674146,
  floralwhite: 16775920,
  forestgreen: 2263842,
  fuchsia: 16711935,
  gainsboro: 14474460,
  ghostwhite: 16316671,
  gold: 16766720,
  goldenrod: 14329120,
  gray: 8421504,
  green: 32768,
  greenyellow: 11403055,
  grey: 8421504,
  honeydew: 15794160,
  hotpink: 16738740,
  indianred: 13458524,
  indigo: 4915330,
  ivory: 16777200,
  khaki: 15787660,
  lavender: 15132410,
  lavenderblush: 16773365,
  lawngreen: 8190976,
  lemonchiffon: 16775885,
  lightblue: 11393254,
  lightcoral: 15761536,
  lightcyan: 14745599,
  lightgoldenrodyellow: 16448210,
  lightgray: 13882323,
  lightgreen: 9498256,
  lightgrey: 13882323,
  lightpink: 16758465,
  lightsalmon: 16752762,
  lightseagreen: 2142890,
  lightskyblue: 8900346,
  lightslategray: 7833753,
  lightslategrey: 7833753,
  lightsteelblue: 11584734,
  lightyellow: 16777184,
  lime: 65280,
  limegreen: 3329330,
  linen: 16445670,
  magenta: 16711935,
  maroon: 8388608,
  mediumaquamarine: 6737322,
  mediumblue: 205,
  mediumorchid: 12211667,
  mediumpurple: 9662683,
  mediumseagreen: 3978097,
  mediumslateblue: 8087790,
  mediumspringgreen: 64154,
  mediumturquoise: 4772300,
  mediumvioletred: 13047173,
  midnightblue: 1644912,
  mintcream: 16121850,
  mistyrose: 16770273,
  moccasin: 16770229,
  navajowhite: 16768685,
  navy: 128,
  oldlace: 16643558,
  olive: 8421376,
  olivedrab: 7048739,
  orange: 16753920,
  orangered: 16729344,
  orchid: 14315734,
  palegoldenrod: 15657130,
  palegreen: 10025880,
  paleturquoise: 11529966,
  palevioletred: 14381203,
  papayawhip: 16773077,
  peachpuff: 16767673,
  peru: 13468991,
  pink: 16761035,
  plum: 14524637,
  powderblue: 11591910,
  purple: 8388736,
  rebeccapurple: 6697881,
  red: 16711680,
  rosybrown: 12357519,
  royalblue: 4286945,
  saddlebrown: 9127187,
  salmon: 16416882,
  sandybrown: 16032864,
  seagreen: 3050327,
  seashell: 16774638,
  sienna: 10506797,
  silver: 12632256,
  skyblue: 8900331,
  slateblue: 6970061,
  slategray: 7372944,
  slategrey: 7372944,
  snow: 16775930,
  springgreen: 65407,
  steelblue: 4620980,
  tan: 13808780,
  teal: 32896,
  thistle: 14204888,
  tomato: 16737095,
  turquoise: 4251856,
  violet: 15631086,
  wheat: 16113331,
  white: 16777215,
  whitesmoke: 16119285,
  yellow: 16776960,
  yellowgreen: 10145074
};
define(Color, color, {
  copy(channels) {
    return Object.assign(new this.constructor(), this, channels);
  },
  displayable() {
    return this.rgb().displayable();
  },
  hex: color_formatHex,
  // Deprecated! Use color.formatHex.
  formatHex: color_formatHex,
  formatHex8: color_formatHex8,
  formatHsl: color_formatHsl,
  formatRgb: color_formatRgb,
  toString: color_formatRgb
});
function color_formatHex() {
  return this.rgb().formatHex();
}
function color_formatHex8() {
  return this.rgb().formatHex8();
}
function color_formatHsl() {
  return hslConvert(this).formatHsl();
}
function color_formatRgb() {
  return this.rgb().formatRgb();
}
function color(format2) {
  var m, l;
  format2 = (format2 + "").trim().toLowerCase();
  return (m = reHex.exec(format2)) ? (l = m[1].length, m = parseInt(m[1], 16), l === 6 ? rgbn(m) : l === 3 ? new Rgb(m >> 8 & 15 | m >> 4 & 240, m >> 4 & 15 | m & 240, (m & 15) << 4 | m & 15, 1) : l === 8 ? rgba(m >> 24 & 255, m >> 16 & 255, m >> 8 & 255, (m & 255) / 255) : l === 4 ? rgba(m >> 12 & 15 | m >> 8 & 240, m >> 8 & 15 | m >> 4 & 240, m >> 4 & 15 | m & 240, ((m & 15) << 4 | m & 15) / 255) : null) : (m = reRgbInteger.exec(format2)) ? new Rgb(m[1], m[2], m[3], 1) : (m = reRgbPercent.exec(format2)) ? new Rgb(m[1] * 255 / 100, m[2] * 255 / 100, m[3] * 255 / 100, 1) : (m = reRgbaInteger.exec(format2)) ? rgba(m[1], m[2], m[3], m[4]) : (m = reRgbaPercent.exec(format2)) ? rgba(m[1] * 255 / 100, m[2] * 255 / 100, m[3] * 255 / 100, m[4]) : (m = reHslPercent.exec(format2)) ? hsla(m[1], m[2] / 100, m[3] / 100, 1) : (m = reHslaPercent.exec(format2)) ? hsla(m[1], m[2] / 100, m[3] / 100, m[4]) : named.hasOwnProperty(format2) ? rgbn(named[format2]) : format2 === "transparent" ? new Rgb(NaN, NaN, NaN, 0) : null;
}
function rgbn(n) {
  return new Rgb(n >> 16 & 255, n >> 8 & 255, n & 255, 1);
}
function rgba(r, g, b, a) {
  if (a <= 0) r = g = b = NaN;
  return new Rgb(r, g, b, a);
}
function rgbConvert(o) {
  if (!(o instanceof Color)) o = color(o);
  if (!o) return new Rgb();
  o = o.rgb();
  return new Rgb(o.r, o.g, o.b, o.opacity);
}
function rgb(r, g, b, opacity) {
  return arguments.length === 1 ? rgbConvert(r) : new Rgb(r, g, b, opacity == null ? 1 : opacity);
}
function Rgb(r, g, b, opacity) {
  this.r = +r;
  this.g = +g;
  this.b = +b;
  this.opacity = +opacity;
}
define(Rgb, rgb, extend(Color, {
  brighter(k) {
    k = k == null ? brighter : Math.pow(brighter, k);
    return new Rgb(this.r * k, this.g * k, this.b * k, this.opacity);
  },
  darker(k) {
    k = k == null ? darker : Math.pow(darker, k);
    return new Rgb(this.r * k, this.g * k, this.b * k, this.opacity);
  },
  rgb() {
    return this;
  },
  clamp() {
    return new Rgb(clampi(this.r), clampi(this.g), clampi(this.b), clampa(this.opacity));
  },
  displayable() {
    return -0.5 <= this.r && this.r < 255.5 && (-0.5 <= this.g && this.g < 255.5) && (-0.5 <= this.b && this.b < 255.5) && (0 <= this.opacity && this.opacity <= 1);
  },
  hex: rgb_formatHex,
  // Deprecated! Use color.formatHex.
  formatHex: rgb_formatHex,
  formatHex8: rgb_formatHex8,
  formatRgb: rgb_formatRgb,
  toString: rgb_formatRgb
}));
function rgb_formatHex() {
  return `#${hex(this.r)}${hex(this.g)}${hex(this.b)}`;
}
function rgb_formatHex8() {
  return `#${hex(this.r)}${hex(this.g)}${hex(this.b)}${hex((isNaN(this.opacity) ? 1 : this.opacity) * 255)}`;
}
function rgb_formatRgb() {
  const a = clampa(this.opacity);
  return `${a === 1 ? "rgb(" : "rgba("}${clampi(this.r)}, ${clampi(this.g)}, ${clampi(this.b)}${a === 1 ? ")" : `, ${a})`}`;
}
function clampa(opacity) {
  return isNaN(opacity) ? 1 : Math.max(0, Math.min(1, opacity));
}
function clampi(value) {
  return Math.max(0, Math.min(255, Math.round(value) || 0));
}
function hex(value) {
  value = clampi(value);
  return (value < 16 ? "0" : "") + value.toString(16);
}
function hsla(h, s, l, a) {
  if (a <= 0) h = s = l = NaN;
  else if (l <= 0 || l >= 1) h = s = NaN;
  else if (s <= 0) h = NaN;
  return new Hsl(h, s, l, a);
}
function hslConvert(o) {
  if (o instanceof Hsl) return new Hsl(o.h, o.s, o.l, o.opacity);
  if (!(o instanceof Color)) o = color(o);
  if (!o) return new Hsl();
  if (o instanceof Hsl) return o;
  o = o.rgb();
  var r = o.r / 255, g = o.g / 255, b = o.b / 255, min2 = Math.min(r, g, b), max2 = Math.max(r, g, b), h = NaN, s = max2 - min2, l = (max2 + min2) / 2;
  if (s) {
    if (r === max2) h = (g - b) / s + (g < b) * 6;
    else if (g === max2) h = (b - r) / s + 2;
    else h = (r - g) / s + 4;
    s /= l < 0.5 ? max2 + min2 : 2 - max2 - min2;
    h *= 60;
  } else {
    s = l > 0 && l < 1 ? 0 : h;
  }
  return new Hsl(h, s, l, o.opacity);
}
function hsl(h, s, l, opacity) {
  return arguments.length === 1 ? hslConvert(h) : new Hsl(h, s, l, opacity == null ? 1 : opacity);
}
function Hsl(h, s, l, opacity) {
  this.h = +h;
  this.s = +s;
  this.l = +l;
  this.opacity = +opacity;
}
define(Hsl, hsl, extend(Color, {
  brighter(k) {
    k = k == null ? brighter : Math.pow(brighter, k);
    return new Hsl(this.h, this.s, this.l * k, this.opacity);
  },
  darker(k) {
    k = k == null ? darker : Math.pow(darker, k);
    return new Hsl(this.h, this.s, this.l * k, this.opacity);
  },
  rgb() {
    var h = this.h % 360 + (this.h < 0) * 360, s = isNaN(h) || isNaN(this.s) ? 0 : this.s, l = this.l, m2 = l + (l < 0.5 ? l : 1 - l) * s, m1 = 2 * l - m2;
    return new Rgb(
      hsl2rgb(h >= 240 ? h - 240 : h + 120, m1, m2),
      hsl2rgb(h, m1, m2),
      hsl2rgb(h < 120 ? h + 240 : h - 120, m1, m2),
      this.opacity
    );
  },
  clamp() {
    return new Hsl(clamph(this.h), clampt(this.s), clampt(this.l), clampa(this.opacity));
  },
  displayable() {
    return (0 <= this.s && this.s <= 1 || isNaN(this.s)) && (0 <= this.l && this.l <= 1) && (0 <= this.opacity && this.opacity <= 1);
  },
  formatHsl() {
    const a = clampa(this.opacity);
    return `${a === 1 ? "hsl(" : "hsla("}${clamph(this.h)}, ${clampt(this.s) * 100}%, ${clampt(this.l) * 100}%${a === 1 ? ")" : `, ${a})`}`;
  }
}));
function clamph(value) {
  value = (value || 0) % 360;
  return value < 0 ? value + 360 : value;
}
function clampt(value) {
  return Math.max(0, Math.min(1, value || 0));
}
function hsl2rgb(h, m1, m2) {
  return (h < 60 ? m1 + (m2 - m1) * h / 60 : h < 180 ? m2 : h < 240 ? m1 + (m2 - m1) * (240 - h) / 60 : m1) * 255;
}
function basis(t1, v0, v1, v2, v3) {
  var t2 = t1 * t1, t3 = t2 * t1;
  return ((1 - 3 * t1 + 3 * t2 - t3) * v0 + (4 - 6 * t2 + 3 * t3) * v1 + (1 + 3 * t1 + 3 * t2 - 3 * t3) * v2 + t3 * v3) / 6;
}
function basis$1(values) {
  var n = values.length - 1;
  return function(t) {
    var i = t <= 0 ? t = 0 : t >= 1 ? (t = 1, n - 1) : Math.floor(t * n), v1 = values[i], v2 = values[i + 1], v0 = i > 0 ? values[i - 1] : 2 * v1 - v2, v3 = i < n - 1 ? values[i + 2] : 2 * v2 - v1;
    return basis((t - i / n) * n, v0, v1, v2, v3);
  };
}
const constant$1 = (x2) => () => x2;
function linear(a, d) {
  return function(t) {
    return a + t * d;
  };
}
function exponential(a, b, y2) {
  return a = Math.pow(a, y2), b = Math.pow(b, y2) - a, y2 = 1 / y2, function(t) {
    return Math.pow(a + t * b, y2);
  };
}
function gamma(y2) {
  return (y2 = +y2) === 1 ? nogamma : function(a, b) {
    return b - a ? exponential(a, b, y2) : constant$1(isNaN(a) ? b : a);
  };
}
function nogamma(a, b) {
  var d = b - a;
  return d ? linear(a, d) : constant$1(isNaN(a) ? b : a);
}
const interpolateRgb = function rgbGamma(y2) {
  var color2 = gamma(y2);
  function rgb$1(start2, end) {
    var r = color2((start2 = rgb(start2)).r, (end = rgb(end)).r), g = color2(start2.g, end.g), b = color2(start2.b, end.b), opacity = nogamma(start2.opacity, end.opacity);
    return function(t) {
      start2.r = r(t);
      start2.g = g(t);
      start2.b = b(t);
      start2.opacity = opacity(t);
      return start2 + "";
    };
  }
  rgb$1.gamma = rgbGamma;
  return rgb$1;
}(1);
function rgbSpline(spline) {
  return function(colors2) {
    var n = colors2.length, r = new Array(n), g = new Array(n), b = new Array(n), i, color2;
    for (i = 0; i < n; ++i) {
      color2 = rgb(colors2[i]);
      r[i] = color2.r || 0;
      g[i] = color2.g || 0;
      b[i] = color2.b || 0;
    }
    r = spline(r);
    g = spline(g);
    b = spline(b);
    color2.opacity = 1;
    return function(t) {
      color2.r = r(t);
      color2.g = g(t);
      color2.b = b(t);
      return color2 + "";
    };
  };
}
var rgbBasis = rgbSpline(basis$1);
function numberArray(a, b) {
  if (!b) b = [];
  var n = a ? Math.min(b.length, a.length) : 0, c = b.slice(), i;
  return function(t) {
    for (i = 0; i < n; ++i) c[i] = a[i] * (1 - t) + b[i] * t;
    return c;
  };
}
function isNumberArray(x2) {
  return ArrayBuffer.isView(x2) && !(x2 instanceof DataView);
}
function genericArray(a, b) {
  var nb = b ? b.length : 0, na = a ? Math.min(nb, a.length) : 0, x2 = new Array(na), c = new Array(nb), i;
  for (i = 0; i < na; ++i) x2[i] = interpolate$1(a[i], b[i]);
  for (; i < nb; ++i) c[i] = b[i];
  return function(t) {
    for (i = 0; i < na; ++i) c[i] = x2[i](t);
    return c;
  };
}
function date(a, b) {
  var d = /* @__PURE__ */ new Date();
  return a = +a, b = +b, function(t) {
    return d.setTime(a * (1 - t) + b * t), d;
  };
}
function interpolateNumber(a, b) {
  return a = +a, b = +b, function(t) {
    return a * (1 - t) + b * t;
  };
}
function object(a, b) {
  var i = {}, c = {}, k;
  if (a === null || typeof a !== "object") a = {};
  if (b === null || typeof b !== "object") b = {};
  for (k in b) {
    if (k in a) {
      i[k] = interpolate$1(a[k], b[k]);
    } else {
      c[k] = b[k];
    }
  }
  return function(t) {
    for (k in i) c[k] = i[k](t);
    return c;
  };
}
var reA = /[-+]?(?:\d+\.?\d*|\.?\d+)(?:[eE][-+]?\d+)?/g, reB = new RegExp(reA.source, "g");
function zero(b) {
  return function() {
    return b;
  };
}
function one(b) {
  return function(t) {
    return b(t) + "";
  };
}
function interpolateString(a, b) {
  var bi = reA.lastIndex = reB.lastIndex = 0, am, bm, bs, i = -1, s = [], q = [];
  a = a + "", b = b + "";
  while ((am = reA.exec(a)) && (bm = reB.exec(b))) {
    if ((bs = bm.index) > bi) {
      bs = b.slice(bi, bs);
      if (s[i]) s[i] += bs;
      else s[++i] = bs;
    }
    if ((am = am[0]) === (bm = bm[0])) {
      if (s[i]) s[i] += bm;
      else s[++i] = bm;
    } else {
      s[++i] = null;
      q.push({ i, x: interpolateNumber(am, bm) });
    }
    bi = reB.lastIndex;
  }
  if (bi < b.length) {
    bs = b.slice(bi);
    if (s[i]) s[i] += bs;
    else s[++i] = bs;
  }
  return s.length < 2 ? q[0] ? one(q[0].x) : zero(b) : (b = q.length, function(t) {
    for (var i2 = 0, o; i2 < b; ++i2) s[(o = q[i2]).i] = o.x(t);
    return s.join("");
  });
}
function interpolate$1(a, b) {
  var t = typeof b, c;
  return b == null || t === "boolean" ? constant$1(b) : (t === "number" ? interpolateNumber : t === "string" ? (c = color(b)) ? (b = c, interpolateRgb) : interpolateString : b instanceof color ? interpolateRgb : b instanceof Date ? date : isNumberArray(b) ? numberArray : Array.isArray(b) ? genericArray : typeof b.valueOf !== "function" && typeof b.toString !== "function" || isNaN(b) ? object : interpolateNumber)(a, b);
}
function interpolateRound(a, b) {
  return a = +a, b = +b, function(t) {
    return Math.round(a * (1 - t) + b * t);
  };
}
var degrees = 180 / Math.PI;
var identity$2 = {
  translateX: 0,
  translateY: 0,
  rotate: 0,
  skewX: 0,
  scaleX: 1,
  scaleY: 1
};
function decompose(a, b, c, d, e, f) {
  var scaleX, scaleY, skewX;
  if (scaleX = Math.sqrt(a * a + b * b)) a /= scaleX, b /= scaleX;
  if (skewX = a * c + b * d) c -= a * skewX, d -= b * skewX;
  if (scaleY = Math.sqrt(c * c + d * d)) c /= scaleY, d /= scaleY, skewX /= scaleY;
  if (a * d < b * c) a = -a, b = -b, skewX = -skewX, scaleX = -scaleX;
  return {
    translateX: e,
    translateY: f,
    rotate: Math.atan2(b, a) * degrees,
    skewX: Math.atan(skewX) * degrees,
    scaleX,
    scaleY
  };
}
var svgNode;
function parseCss(value) {
  const m = new (typeof DOMMatrix === "function" ? DOMMatrix : WebKitCSSMatrix)(value + "");
  return m.isIdentity ? identity$2 : decompose(m.a, m.b, m.c, m.d, m.e, m.f);
}
function parseSvg(value) {
  if (value == null) return identity$2;
  if (!svgNode) svgNode = document.createElementNS("http://www.w3.org/2000/svg", "g");
  svgNode.setAttribute("transform", value);
  if (!(value = svgNode.transform.baseVal.consolidate())) return identity$2;
  value = value.matrix;
  return decompose(value.a, value.b, value.c, value.d, value.e, value.f);
}
function interpolateTransform(parse, pxComma, pxParen, degParen) {
  function pop(s) {
    return s.length ? s.pop() + " " : "";
  }
  function translate(xa, ya, xb, yb, s, q) {
    if (xa !== xb || ya !== yb) {
      var i = s.push("translate(", null, pxComma, null, pxParen);
      q.push({ i: i - 4, x: interpolateNumber(xa, xb) }, { i: i - 2, x: interpolateNumber(ya, yb) });
    } else if (xb || yb) {
      s.push("translate(" + xb + pxComma + yb + pxParen);
    }
  }
  function rotate(a, b, s, q) {
    if (a !== b) {
      if (a - b > 180) b += 360;
      else if (b - a > 180) a += 360;
      q.push({ i: s.push(pop(s) + "rotate(", null, degParen) - 2, x: interpolateNumber(a, b) });
    } else if (b) {
      s.push(pop(s) + "rotate(" + b + degParen);
    }
  }
  function skewX(a, b, s, q) {
    if (a !== b) {
      q.push({ i: s.push(pop(s) + "skewX(", null, degParen) - 2, x: interpolateNumber(a, b) });
    } else if (b) {
      s.push(pop(s) + "skewX(" + b + degParen);
    }
  }
  function scale(xa, ya, xb, yb, s, q) {
    if (xa !== xb || ya !== yb) {
      var i = s.push(pop(s) + "scale(", null, ",", null, ")");
      q.push({ i: i - 4, x: interpolateNumber(xa, xb) }, { i: i - 2, x: interpolateNumber(ya, yb) });
    } else if (xb !== 1 || yb !== 1) {
      s.push(pop(s) + "scale(" + xb + "," + yb + ")");
    }
  }
  return function(a, b) {
    var s = [], q = [];
    a = parse(a), b = parse(b);
    translate(a.translateX, a.translateY, b.translateX, b.translateY, s, q);
    rotate(a.rotate, b.rotate, s, q);
    skewX(a.skewX, b.skewX, s, q);
    scale(a.scaleX, a.scaleY, b.scaleX, b.scaleY, s, q);
    a = b = null;
    return function(t) {
      var i = -1, n = q.length, o;
      while (++i < n) s[(o = q[i]).i] = o.x(t);
      return s.join("");
    };
  };
}
var interpolateTransformCss = interpolateTransform(parseCss, "px, ", "px)", "deg)");
var interpolateTransformSvg = interpolateTransform(parseSvg, ", ", ")", ")");
var frame = 0, timeout$1 = 0, interval = 0, pokeDelay = 1e3, taskHead, taskTail, clockLast = 0, clockNow = 0, clockSkew = 0, clock = typeof performance === "object" && performance.now ? performance : Date, setFrame = typeof window === "object" && window.requestAnimationFrame ? window.requestAnimationFrame.bind(window) : function(f) {
  setTimeout(f, 17);
};
function now() {
  return clockNow || (setFrame(clearNow), clockNow = clock.now() + clockSkew);
}
function clearNow() {
  clockNow = 0;
}
function Timer() {
  this._call = this._time = this._next = null;
}
Timer.prototype = timer.prototype = {
  constructor: Timer,
  restart: function(callback, delay, time) {
    if (typeof callback !== "function") throw new TypeError("callback is not a function");
    time = (time == null ? now() : +time) + (delay == null ? 0 : +delay);
    if (!this._next && taskTail !== this) {
      if (taskTail) taskTail._next = this;
      else taskHead = this;
      taskTail = this;
    }
    this._call = callback;
    this._time = time;
    sleep();
  },
  stop: function() {
    if (this._call) {
      this._call = null;
      this._time = Infinity;
      sleep();
    }
  }
};
function timer(callback, delay, time) {
  var t = new Timer();
  t.restart(callback, delay, time);
  return t;
}
function timerFlush() {
  now();
  ++frame;
  var t = taskHead, e;
  while (t) {
    if ((e = clockNow - t._time) >= 0) t._call.call(void 0, e);
    t = t._next;
  }
  --frame;
}
function wake() {
  clockNow = (clockLast = clock.now()) + clockSkew;
  frame = timeout$1 = 0;
  try {
    timerFlush();
  } finally {
    frame = 0;
    nap();
    clockNow = 0;
  }
}
function poke() {
  var now2 = clock.now(), delay = now2 - clockLast;
  if (delay > pokeDelay) clockSkew -= delay, clockLast = now2;
}
function nap() {
  var t0, t1 = taskHead, t2, time = Infinity;
  while (t1) {
    if (t1._call) {
      if (time > t1._time) time = t1._time;
      t0 = t1, t1 = t1._next;
    } else {
      t2 = t1._next, t1._next = null;
      t1 = t0 ? t0._next = t2 : taskHead = t2;
    }
  }
  taskTail = t0;
  sleep(time);
}
function sleep(time) {
  if (frame) return;
  if (timeout$1) timeout$1 = clearTimeout(timeout$1);
  var delay = time - clockNow;
  if (delay > 24) {
    if (time < Infinity) timeout$1 = setTimeout(wake, time - clock.now() - clockSkew);
    if (interval) interval = clearInterval(interval);
  } else {
    if (!interval) clockLast = clock.now(), interval = setInterval(poke, pokeDelay);
    frame = 1, setFrame(wake);
  }
}
function timeout(callback, delay, time) {
  var t = new Timer();
  delay = delay == null ? 0 : +delay;
  t.restart((elapsed) => {
    t.stop();
    callback(elapsed + delay);
  }, delay, time);
  return t;
}
var emptyOn = dispatch("start", "end", "cancel", "interrupt");
var emptyTween = [];
var CREATED = 0;
var SCHEDULED = 1;
var STARTING = 2;
var STARTED = 3;
var RUNNING = 4;
var ENDING = 5;
var ENDED = 6;
function schedule(node, name, id2, index, group, timing) {
  var schedules = node.__transition;
  if (!schedules) node.__transition = {};
  else if (id2 in schedules) return;
  create(node, id2, {
    name,
    index,
    // For context during callback.
    group,
    // For context during callback.
    on: emptyOn,
    tween: emptyTween,
    time: timing.time,
    delay: timing.delay,
    duration: timing.duration,
    ease: timing.ease,
    timer: null,
    state: CREATED
  });
}
function init(node, id2) {
  var schedule2 = get(node, id2);
  if (schedule2.state > CREATED) throw new Error("too late; already scheduled");
  return schedule2;
}
function set(node, id2) {
  var schedule2 = get(node, id2);
  if (schedule2.state > STARTED) throw new Error("too late; already running");
  return schedule2;
}
function get(node, id2) {
  var schedule2 = node.__transition;
  if (!schedule2 || !(schedule2 = schedule2[id2])) throw new Error("transition not found");
  return schedule2;
}
function create(node, id2, self) {
  var schedules = node.__transition, tween;
  schedules[id2] = self;
  self.timer = timer(schedule2, 0, self.time);
  function schedule2(elapsed) {
    self.state = SCHEDULED;
    self.timer.restart(start2, self.delay, self.time);
    if (self.delay <= elapsed) start2(elapsed - self.delay);
  }
  function start2(elapsed) {
    var i, j, n, o;
    if (self.state !== SCHEDULED) return stop();
    for (i in schedules) {
      o = schedules[i];
      if (o.name !== self.name) continue;
      if (o.state === STARTED) return timeout(start2);
      if (o.state === RUNNING) {
        o.state = ENDED;
        o.timer.stop();
        o.on.call("interrupt", node, node.__data__, o.index, o.group);
        delete schedules[i];
      } else if (+i < id2) {
        o.state = ENDED;
        o.timer.stop();
        o.on.call("cancel", node, node.__data__, o.index, o.group);
        delete schedules[i];
      }
    }
    timeout(function() {
      if (self.state === STARTED) {
        self.state = RUNNING;
        self.timer.restart(tick, self.delay, self.time);
        tick(elapsed);
      }
    });
    self.state = STARTING;
    self.on.call("start", node, node.__data__, self.index, self.group);
    if (self.state !== STARTING) return;
    self.state = STARTED;
    tween = new Array(n = self.tween.length);
    for (i = 0, j = -1; i < n; ++i) {
      if (o = self.tween[i].value.call(node, node.__data__, self.index, self.group)) {
        tween[++j] = o;
      }
    }
    tween.length = j + 1;
  }
  function tick(elapsed) {
    var t = elapsed < self.duration ? self.ease.call(null, elapsed / self.duration) : (self.timer.restart(stop), self.state = ENDING, 1), i = -1, n = tween.length;
    while (++i < n) {
      tween[i].call(node, t);
    }
    if (self.state === ENDING) {
      self.on.call("end", node, node.__data__, self.index, self.group);
      stop();
    }
  }
  function stop() {
    self.state = ENDED;
    self.timer.stop();
    delete schedules[id2];
    for (var i in schedules) return;
    delete node.__transition;
  }
}
function interrupt(node, name) {
  var schedules = node.__transition, schedule2, active, empty2 = true, i;
  if (!schedules) return;
  name = name == null ? null : name + "";
  for (i in schedules) {
    if ((schedule2 = schedules[i]).name !== name) {
      empty2 = false;
      continue;
    }
    active = schedule2.state > STARTING && schedule2.state < ENDING;
    schedule2.state = ENDED;
    schedule2.timer.stop();
    schedule2.on.call(active ? "interrupt" : "cancel", node, node.__data__, schedule2.index, schedule2.group);
    delete schedules[i];
  }
  if (empty2) delete node.__transition;
}
function selection_interrupt(name) {
  return this.each(function() {
    interrupt(this, name);
  });
}
function tweenRemove(id2, name) {
  var tween0, tween1;
  return function() {
    var schedule2 = set(this, id2), tween = schedule2.tween;
    if (tween !== tween0) {
      tween1 = tween0 = tween;
      for (var i = 0, n = tween1.length; i < n; ++i) {
        if (tween1[i].name === name) {
          tween1 = tween1.slice();
          tween1.splice(i, 1);
          break;
        }
      }
    }
    schedule2.tween = tween1;
  };
}
function tweenFunction(id2, name, value) {
  var tween0, tween1;
  if (typeof value !== "function") throw new Error();
  return function() {
    var schedule2 = set(this, id2), tween = schedule2.tween;
    if (tween !== tween0) {
      tween1 = (tween0 = tween).slice();
      for (var t = { name, value }, i = 0, n = tween1.length; i < n; ++i) {
        if (tween1[i].name === name) {
          tween1[i] = t;
          break;
        }
      }
      if (i === n) tween1.push(t);
    }
    schedule2.tween = tween1;
  };
}
function transition_tween(name, value) {
  var id2 = this._id;
  name += "";
  if (arguments.length < 2) {
    var tween = get(this.node(), id2).tween;
    for (var i = 0, n = tween.length, t; i < n; ++i) {
      if ((t = tween[i]).name === name) {
        return t.value;
      }
    }
    return null;
  }
  return this.each((value == null ? tweenRemove : tweenFunction)(id2, name, value));
}
function tweenValue(transition, name, value) {
  var id2 = transition._id;
  transition.each(function() {
    var schedule2 = set(this, id2);
    (schedule2.value || (schedule2.value = {}))[name] = value.apply(this, arguments);
  });
  return function(node) {
    return get(node, id2).value[name];
  };
}
function interpolate(a, b) {
  var c;
  return (typeof b === "number" ? interpolateNumber : b instanceof color ? interpolateRgb : (c = color(b)) ? (b = c, interpolateRgb) : interpolateString)(a, b);
}
function attrRemove(name) {
  return function() {
    this.removeAttribute(name);
  };
}
function attrRemoveNS(fullname) {
  return function() {
    this.removeAttributeNS(fullname.space, fullname.local);
  };
}
function attrConstant(name, interpolate2, value1) {
  var string00, string1 = value1 + "", interpolate0;
  return function() {
    var string0 = this.getAttribute(name);
    return string0 === string1 ? null : string0 === string00 ? interpolate0 : interpolate0 = interpolate2(string00 = string0, value1);
  };
}
function attrConstantNS(fullname, interpolate2, value1) {
  var string00, string1 = value1 + "", interpolate0;
  return function() {
    var string0 = this.getAttributeNS(fullname.space, fullname.local);
    return string0 === string1 ? null : string0 === string00 ? interpolate0 : interpolate0 = interpolate2(string00 = string0, value1);
  };
}
function attrFunction(name, interpolate2, value) {
  var string00, string10, interpolate0;
  return function() {
    var string0, value1 = value(this), string1;
    if (value1 == null) return void this.removeAttribute(name);
    string0 = this.getAttribute(name);
    string1 = value1 + "";
    return string0 === string1 ? null : string0 === string00 && string1 === string10 ? interpolate0 : (string10 = string1, interpolate0 = interpolate2(string00 = string0, value1));
  };
}
function attrFunctionNS(fullname, interpolate2, value) {
  var string00, string10, interpolate0;
  return function() {
    var string0, value1 = value(this), string1;
    if (value1 == null) return void this.removeAttributeNS(fullname.space, fullname.local);
    string0 = this.getAttributeNS(fullname.space, fullname.local);
    string1 = value1 + "";
    return string0 === string1 ? null : string0 === string00 && string1 === string10 ? interpolate0 : (string10 = string1, interpolate0 = interpolate2(string00 = string0, value1));
  };
}
function transition_attr(name, value) {
  var fullname = namespace(name), i = fullname === "transform" ? interpolateTransformSvg : interpolate;
  return this.attrTween(name, typeof value === "function" ? (fullname.local ? attrFunctionNS : attrFunction)(fullname, i, tweenValue(this, "attr." + name, value)) : value == null ? (fullname.local ? attrRemoveNS : attrRemove)(fullname) : (fullname.local ? attrConstantNS : attrConstant)(fullname, i, value));
}
function attrInterpolate(name, i) {
  return function(t) {
    this.setAttribute(name, i.call(this, t));
  };
}
function attrInterpolateNS(fullname, i) {
  return function(t) {
    this.setAttributeNS(fullname.space, fullname.local, i.call(this, t));
  };
}
function attrTweenNS(fullname, value) {
  var t0, i0;
  function tween() {
    var i = value.apply(this, arguments);
    if (i !== i0) t0 = (i0 = i) && attrInterpolateNS(fullname, i);
    return t0;
  }
  tween._value = value;
  return tween;
}
function attrTween(name, value) {
  var t0, i0;
  function tween() {
    var i = value.apply(this, arguments);
    if (i !== i0) t0 = (i0 = i) && attrInterpolate(name, i);
    return t0;
  }
  tween._value = value;
  return tween;
}
function transition_attrTween(name, value) {
  var key = "attr." + name;
  if (arguments.length < 2) return (key = this.tween(key)) && key._value;
  if (value == null) return this.tween(key, null);
  if (typeof value !== "function") throw new Error();
  var fullname = namespace(name);
  return this.tween(key, (fullname.local ? attrTweenNS : attrTween)(fullname, value));
}
function delayFunction(id2, value) {
  return function() {
    init(this, id2).delay = +value.apply(this, arguments);
  };
}
function delayConstant(id2, value) {
  return value = +value, function() {
    init(this, id2).delay = value;
  };
}
function transition_delay(value) {
  var id2 = this._id;
  return arguments.length ? this.each((typeof value === "function" ? delayFunction : delayConstant)(id2, value)) : get(this.node(), id2).delay;
}
function durationFunction(id2, value) {
  return function() {
    set(this, id2).duration = +value.apply(this, arguments);
  };
}
function durationConstant(id2, value) {
  return value = +value, function() {
    set(this, id2).duration = value;
  };
}
function transition_duration(value) {
  var id2 = this._id;
  return arguments.length ? this.each((typeof value === "function" ? durationFunction : durationConstant)(id2, value)) : get(this.node(), id2).duration;
}
function easeConstant(id2, value) {
  if (typeof value !== "function") throw new Error();
  return function() {
    set(this, id2).ease = value;
  };
}
function transition_ease(value) {
  var id2 = this._id;
  return arguments.length ? this.each(easeConstant(id2, value)) : get(this.node(), id2).ease;
}
function easeVarying(id2, value) {
  return function() {
    var v = value.apply(this, arguments);
    if (typeof v !== "function") throw new Error();
    set(this, id2).ease = v;
  };
}
function transition_easeVarying(value) {
  if (typeof value !== "function") throw new Error();
  return this.each(easeVarying(this._id, value));
}
function transition_filter(match) {
  if (typeof match !== "function") match = matcher(match);
  for (var groups = this._groups, m = groups.length, subgroups = new Array(m), j = 0; j < m; ++j) {
    for (var group = groups[j], n = group.length, subgroup = subgroups[j] = [], node, i = 0; i < n; ++i) {
      if ((node = group[i]) && match.call(node, node.__data__, i, group)) {
        subgroup.push(node);
      }
    }
  }
  return new Transition(subgroups, this._parents, this._name, this._id);
}
function transition_merge(transition) {
  if (transition._id !== this._id) throw new Error();
  for (var groups0 = this._groups, groups1 = transition._groups, m0 = groups0.length, m1 = groups1.length, m = Math.min(m0, m1), merges = new Array(m0), j = 0; j < m; ++j) {
    for (var group0 = groups0[j], group1 = groups1[j], n = group0.length, merge = merges[j] = new Array(n), node, i = 0; i < n; ++i) {
      if (node = group0[i] || group1[i]) {
        merge[i] = node;
      }
    }
  }
  for (; j < m0; ++j) {
    merges[j] = groups0[j];
  }
  return new Transition(merges, this._parents, this._name, this._id);
}
function start(name) {
  return (name + "").trim().split(/^|\s+/).every(function(t) {
    var i = t.indexOf(".");
    if (i >= 0) t = t.slice(0, i);
    return !t || t === "start";
  });
}
function onFunction(id2, name, listener) {
  var on0, on1, sit = start(name) ? init : set;
  return function() {
    var schedule2 = sit(this, id2), on = schedule2.on;
    if (on !== on0) (on1 = (on0 = on).copy()).on(name, listener);
    schedule2.on = on1;
  };
}
function transition_on(name, listener) {
  var id2 = this._id;
  return arguments.length < 2 ? get(this.node(), id2).on.on(name) : this.each(onFunction(id2, name, listener));
}
function removeFunction(id2) {
  return function() {
    var parent = this.parentNode;
    for (var i in this.__transition) if (+i !== id2) return;
    if (parent) parent.removeChild(this);
  };
}
function transition_remove() {
  return this.on("end.remove", removeFunction(this._id));
}
function transition_select(select) {
  var name = this._name, id2 = this._id;
  if (typeof select !== "function") select = selector(select);
  for (var groups = this._groups, m = groups.length, subgroups = new Array(m), j = 0; j < m; ++j) {
    for (var group = groups[j], n = group.length, subgroup = subgroups[j] = new Array(n), node, subnode, i = 0; i < n; ++i) {
      if ((node = group[i]) && (subnode = select.call(node, node.__data__, i, group))) {
        if ("__data__" in node) subnode.__data__ = node.__data__;
        subgroup[i] = subnode;
        schedule(subgroup[i], name, id2, i, subgroup, get(node, id2));
      }
    }
  }
  return new Transition(subgroups, this._parents, name, id2);
}
function transition_selectAll(select) {
  var name = this._name, id2 = this._id;
  if (typeof select !== "function") select = selectorAll(select);
  for (var groups = this._groups, m = groups.length, subgroups = [], parents = [], j = 0; j < m; ++j) {
    for (var group = groups[j], n = group.length, node, i = 0; i < n; ++i) {
      if (node = group[i]) {
        for (var children2 = select.call(node, node.__data__, i, group), child, inherit2 = get(node, id2), k = 0, l = children2.length; k < l; ++k) {
          if (child = children2[k]) {
            schedule(child, name, id2, k, children2, inherit2);
          }
        }
        subgroups.push(children2);
        parents.push(node);
      }
    }
  }
  return new Transition(subgroups, parents, name, id2);
}
var Selection = selection.prototype.constructor;
function transition_selection() {
  return new Selection(this._groups, this._parents);
}
function styleNull(name, interpolate2) {
  var string00, string10, interpolate0;
  return function() {
    var string0 = styleValue(this, name), string1 = (this.style.removeProperty(name), styleValue(this, name));
    return string0 === string1 ? null : string0 === string00 && string1 === string10 ? interpolate0 : interpolate0 = interpolate2(string00 = string0, string10 = string1);
  };
}
function styleRemove(name) {
  return function() {
    this.style.removeProperty(name);
  };
}
function styleConstant(name, interpolate2, value1) {
  var string00, string1 = value1 + "", interpolate0;
  return function() {
    var string0 = styleValue(this, name);
    return string0 === string1 ? null : string0 === string00 ? interpolate0 : interpolate0 = interpolate2(string00 = string0, value1);
  };
}
function styleFunction(name, interpolate2, value) {
  var string00, string10, interpolate0;
  return function() {
    var string0 = styleValue(this, name), value1 = value(this), string1 = value1 + "";
    if (value1 == null) string1 = value1 = (this.style.removeProperty(name), styleValue(this, name));
    return string0 === string1 ? null : string0 === string00 && string1 === string10 ? interpolate0 : (string10 = string1, interpolate0 = interpolate2(string00 = string0, value1));
  };
}
function styleMaybeRemove(id2, name) {
  var on0, on1, listener0, key = "style." + name, event = "end." + key, remove2;
  return function() {
    var schedule2 = set(this, id2), on = schedule2.on, listener = schedule2.value[key] == null ? remove2 || (remove2 = styleRemove(name)) : void 0;
    if (on !== on0 || listener0 !== listener) (on1 = (on0 = on).copy()).on(event, listener0 = listener);
    schedule2.on = on1;
  };
}
function transition_style(name, value, priority) {
  var i = (name += "") === "transform" ? interpolateTransformCss : interpolate;
  return value == null ? this.styleTween(name, styleNull(name, i)).on("end.style." + name, styleRemove(name)) : typeof value === "function" ? this.styleTween(name, styleFunction(name, i, tweenValue(this, "style." + name, value))).each(styleMaybeRemove(this._id, name)) : this.styleTween(name, styleConstant(name, i, value), priority).on("end.style." + name, null);
}
function styleInterpolate(name, i, priority) {
  return function(t) {
    this.style.setProperty(name, i.call(this, t), priority);
  };
}
function styleTween(name, value, priority) {
  var t, i0;
  function tween() {
    var i = value.apply(this, arguments);
    if (i !== i0) t = (i0 = i) && styleInterpolate(name, i, priority);
    return t;
  }
  tween._value = value;
  return tween;
}
function transition_styleTween(name, value, priority) {
  var key = "style." + (name += "");
  if (arguments.length < 2) return (key = this.tween(key)) && key._value;
  if (value == null) return this.tween(key, null);
  if (typeof value !== "function") throw new Error();
  return this.tween(key, styleTween(name, value, priority == null ? "" : priority));
}
function textConstant(value) {
  return function() {
    this.textContent = value;
  };
}
function textFunction(value) {
  return function() {
    var value1 = value(this);
    this.textContent = value1 == null ? "" : value1;
  };
}
function transition_text(value) {
  return this.tween("text", typeof value === "function" ? textFunction(tweenValue(this, "text", value)) : textConstant(value == null ? "" : value + ""));
}
function textInterpolate(i) {
  return function(t) {
    this.textContent = i.call(this, t);
  };
}
function textTween(value) {
  var t0, i0;
  function tween() {
    var i = value.apply(this, arguments);
    if (i !== i0) t0 = (i0 = i) && textInterpolate(i);
    return t0;
  }
  tween._value = value;
  return tween;
}
function transition_textTween(value) {
  var key = "text";
  if (arguments.length < 1) return (key = this.tween(key)) && key._value;
  if (value == null) return this.tween(key, null);
  if (typeof value !== "function") throw new Error();
  return this.tween(key, textTween(value));
}
function transition_transition() {
  var name = this._name, id0 = this._id, id1 = newId();
  for (var groups = this._groups, m = groups.length, j = 0; j < m; ++j) {
    for (var group = groups[j], n = group.length, node, i = 0; i < n; ++i) {
      if (node = group[i]) {
        var inherit2 = get(node, id0);
        schedule(node, name, id1, i, group, {
          time: inherit2.time + inherit2.delay + inherit2.duration,
          delay: 0,
          duration: inherit2.duration,
          ease: inherit2.ease
        });
      }
    }
  }
  return new Transition(groups, this._parents, name, id1);
}
function transition_end() {
  var on0, on1, that = this, id2 = that._id, size = that.size();
  return new Promise(function(resolve, reject) {
    var cancel = { value: reject }, end = { value: function() {
      if (--size === 0) resolve();
    } };
    that.each(function() {
      var schedule2 = set(this, id2), on = schedule2.on;
      if (on !== on0) {
        on1 = (on0 = on).copy();
        on1._.cancel.push(cancel);
        on1._.interrupt.push(cancel);
        on1._.end.push(end);
      }
      schedule2.on = on1;
    });
    if (size === 0) resolve();
  });
}
var id = 0;
function Transition(groups, parents, name, id2) {
  this._groups = groups;
  this._parents = parents;
  this._name = name;
  this._id = id2;
}
function newId() {
  return ++id;
}
var selection_prototype = selection.prototype;
Transition.prototype = {
  constructor: Transition,
  select: transition_select,
  selectAll: transition_selectAll,
  selectChild: selection_prototype.selectChild,
  selectChildren: selection_prototype.selectChildren,
  filter: transition_filter,
  merge: transition_merge,
  selection: transition_selection,
  transition: transition_transition,
  call: selection_prototype.call,
  nodes: selection_prototype.nodes,
  node: selection_prototype.node,
  size: selection_prototype.size,
  empty: selection_prototype.empty,
  each: selection_prototype.each,
  on: transition_on,
  attr: transition_attr,
  attrTween: transition_attrTween,
  style: transition_style,
  styleTween: transition_styleTween,
  text: transition_text,
  textTween: transition_textTween,
  remove: transition_remove,
  tween: transition_tween,
  delay: transition_delay,
  duration: transition_duration,
  ease: transition_ease,
  easeVarying: transition_easeVarying,
  end: transition_end,
  [Symbol.iterator]: selection_prototype[Symbol.iterator]
};
function cubicInOut(t) {
  return ((t *= 2) <= 1 ? t * t * t : (t -= 2) * t * t + 2) / 2;
}
var defaultTiming = {
  time: null,
  // Set on use.
  delay: 0,
  duration: 250,
  ease: cubicInOut
};
function inherit(node, id2) {
  var timing;
  while (!(timing = node.__transition) || !(timing = timing[id2])) {
    if (!(node = node.parentNode)) {
      throw new Error(`transition ${id2} not found`);
    }
  }
  return timing;
}
function selection_transition(name) {
  var id2, timing;
  if (name instanceof Transition) {
    id2 = name._id, name = name._name;
  } else {
    id2 = newId(), (timing = defaultTiming).time = now(), name = name == null ? null : name + "";
  }
  for (var groups = this._groups, m = groups.length, j = 0; j < m; ++j) {
    for (var group = groups[j], n = group.length, node, i = 0; i < n; ++i) {
      if (node = group[i]) {
        schedule(node, name, id2, i, group, timing || inherit(node, id2));
      }
    }
  }
  return new Transition(groups, this._parents, name, id2);
}
selection.prototype.interrupt = selection_interrupt;
selection.prototype.transition = selection_transition;
const pi = Math.PI, tau$1 = 2 * pi, epsilon$2 = 1e-6, tauEpsilon = tau$1 - epsilon$2;
function append(strings) {
  this._ += strings[0];
  for (let i = 1, n = strings.length; i < n; ++i) {
    this._ += arguments[i] + strings[i];
  }
}
function appendRound(digits) {
  let d = Math.floor(digits);
  if (!(d >= 0)) throw new Error(`invalid digits: ${digits}`);
  if (d > 15) return append;
  const k = 10 ** d;
  return function(strings) {
    this._ += strings[0];
    for (let i = 1, n = strings.length; i < n; ++i) {
      this._ += Math.round(arguments[i] * k) / k + strings[i];
    }
  };
}
let Path$1 = class Path {
  constructor(digits) {
    this._x0 = this._y0 = // start of current subpath
    this._x1 = this._y1 = null;
    this._ = "";
    this._append = digits == null ? append : appendRound(digits);
  }
  moveTo(x2, y2) {
    this._append`M${this._x0 = this._x1 = +x2},${this._y0 = this._y1 = +y2}`;
  }
  closePath() {
    if (this._x1 !== null) {
      this._x1 = this._x0, this._y1 = this._y0;
      this._append`Z`;
    }
  }
  lineTo(x2, y2) {
    this._append`L${this._x1 = +x2},${this._y1 = +y2}`;
  }
  quadraticCurveTo(x1, y1, x2, y2) {
    this._append`Q${+x1},${+y1},${this._x1 = +x2},${this._y1 = +y2}`;
  }
  bezierCurveTo(x1, y1, x2, y2, x3, y3) {
    this._append`C${+x1},${+y1},${+x2},${+y2},${this._x1 = +x3},${this._y1 = +y3}`;
  }
  arcTo(x1, y1, x2, y2, r) {
    x1 = +x1, y1 = +y1, x2 = +x2, y2 = +y2, r = +r;
    if (r < 0) throw new Error(`negative radius: ${r}`);
    let x0 = this._x1, y0 = this._y1, x21 = x2 - x1, y21 = y2 - y1, x01 = x0 - x1, y01 = y0 - y1, l01_2 = x01 * x01 + y01 * y01;
    if (this._x1 === null) {
      this._append`M${this._x1 = x1},${this._y1 = y1}`;
    } else if (!(l01_2 > epsilon$2)) ;
    else if (!(Math.abs(y01 * x21 - y21 * x01) > epsilon$2) || !r) {
      this._append`L${this._x1 = x1},${this._y1 = y1}`;
    } else {
      let x20 = x2 - x0, y20 = y2 - y0, l21_2 = x21 * x21 + y21 * y21, l20_2 = x20 * x20 + y20 * y20, l21 = Math.sqrt(l21_2), l01 = Math.sqrt(l01_2), l = r * Math.tan((pi - Math.acos((l21_2 + l01_2 - l20_2) / (2 * l21 * l01))) / 2), t01 = l / l01, t21 = l / l21;
      if (Math.abs(t01 - 1) > epsilon$2) {
        this._append`L${x1 + t01 * x01},${y1 + t01 * y01}`;
      }
      this._append`A${r},${r},0,0,${+(y01 * x20 > x01 * y20)},${this._x1 = x1 + t21 * x21},${this._y1 = y1 + t21 * y21}`;
    }
  }
  arc(x2, y2, r, a0, a1, ccw) {
    x2 = +x2, y2 = +y2, r = +r, ccw = !!ccw;
    if (r < 0) throw new Error(`negative radius: ${r}`);
    let dx = r * Math.cos(a0), dy = r * Math.sin(a0), x0 = x2 + dx, y0 = y2 + dy, cw = 1 ^ ccw, da = ccw ? a0 - a1 : a1 - a0;
    if (this._x1 === null) {
      this._append`M${x0},${y0}`;
    } else if (Math.abs(this._x1 - x0) > epsilon$2 || Math.abs(this._y1 - y0) > epsilon$2) {
      this._append`L${x0},${y0}`;
    }
    if (!r) return;
    if (da < 0) da = da % tau$1 + tau$1;
    if (da > tauEpsilon) {
      this._append`A${r},${r},0,1,${cw},${x2 - dx},${y2 - dy}A${r},${r},0,1,${cw},${this._x1 = x0},${this._y1 = y0}`;
    } else if (da > epsilon$2) {
      this._append`A${r},${r},0,${+(da >= pi)},${cw},${this._x1 = x2 + r * Math.cos(a1)},${this._y1 = y2 + r * Math.sin(a1)}`;
    }
  }
  rect(x2, y2, w, h) {
    this._append`M${this._x0 = this._x1 = +x2},${this._y0 = this._y1 = +y2}h${w = +w}v${+h}h${-w}Z`;
  }
  toString() {
    return this._;
  }
};
const epsilon$1 = 1e-6;
class Path2 {
  constructor() {
    this._x0 = this._y0 = // start of current subpath
    this._x1 = this._y1 = null;
    this._ = "";
  }
  moveTo(x2, y2) {
    this._ += `M${this._x0 = this._x1 = +x2},${this._y0 = this._y1 = +y2}`;
  }
  closePath() {
    if (this._x1 !== null) {
      this._x1 = this._x0, this._y1 = this._y0;
      this._ += "Z";
    }
  }
  lineTo(x2, y2) {
    this._ += `L${this._x1 = +x2},${this._y1 = +y2}`;
  }
  arc(x2, y2, r) {
    x2 = +x2, y2 = +y2, r = +r;
    const x0 = x2 + r;
    const y0 = y2;
    if (r < 0) throw new Error("negative radius");
    if (this._x1 === null) this._ += `M${x0},${y0}`;
    else if (Math.abs(this._x1 - x0) > epsilon$1 || Math.abs(this._y1 - y0) > epsilon$1) this._ += "L" + x0 + "," + y0;
    if (!r) return;
    this._ += `A${r},${r},0,1,1,${x2 - r},${y2}A${r},${r},0,1,1,${this._x1 = x0},${this._y1 = y0}`;
  }
  rect(x2, y2, w, h) {
    this._ += `M${this._x0 = this._x1 = +x2},${this._y0 = this._y1 = +y2}h${+w}v${+h}h${-w}Z`;
  }
  value() {
    return this._ || null;
  }
}
class Polygon {
  constructor() {
    this._ = [];
  }
  moveTo(x2, y2) {
    this._.push([x2, y2]);
  }
  closePath() {
    this._.push(this._[0].slice());
  }
  lineTo(x2, y2) {
    this._.push([x2, y2]);
  }
  value() {
    return this._.length ? this._ : null;
  }
}
class Voronoi2 {
  constructor(delaunay, [xmin, ymin, xmax, ymax] = [0, 0, 960, 500]) {
    if (!((xmax = +xmax) >= (xmin = +xmin)) || !((ymax = +ymax) >= (ymin = +ymin))) throw new Error("invalid bounds");
    this.delaunay = delaunay;
    this._circumcenters = new Float64Array(delaunay.points.length * 2);
    this.vectors = new Float64Array(delaunay.points.length * 2);
    this.xmax = xmax, this.xmin = xmin;
    this.ymax = ymax, this.ymin = ymin;
    this._init();
  }
  update() {
    this.delaunay.update();
    this._init();
    return this;
  }
  _init() {
    const { delaunay: { points, hull, triangles }, vectors } = this;
    let bx, by;
    const circumcenters = this.circumcenters = this._circumcenters.subarray(0, triangles.length / 3 * 2);
    for (let i = 0, j = 0, n = triangles.length, x2, y2; i < n; i += 3, j += 2) {
      const t1 = triangles[i] * 2;
      const t2 = triangles[i + 1] * 2;
      const t3 = triangles[i + 2] * 2;
      const x12 = points[t1];
      const y12 = points[t1 + 1];
      const x22 = points[t2];
      const y22 = points[t2 + 1];
      const x3 = points[t3];
      const y3 = points[t3 + 1];
      const dx = x22 - x12;
      const dy = y22 - y12;
      const ex = x3 - x12;
      const ey = y3 - y12;
      const ab = (dx * ey - dy * ex) * 2;
      if (Math.abs(ab) < 1e-9) {
        if (bx === void 0) {
          bx = by = 0;
          for (const i2 of hull) bx += points[i2 * 2], by += points[i2 * 2 + 1];
          bx /= hull.length, by /= hull.length;
        }
        const a = 1e9 * Math.sign((bx - x12) * ey - (by - y12) * ex);
        x2 = (x12 + x3) / 2 - a * ey;
        y2 = (y12 + y3) / 2 + a * ex;
      } else {
        const d = 1 / ab;
        const bl = dx * dx + dy * dy;
        const cl = ex * ex + ey * ey;
        x2 = x12 + (ey * bl - dy * cl) * d;
        y2 = y12 + (dx * cl - ex * bl) * d;
      }
      circumcenters[j] = x2;
      circumcenters[j + 1] = y2;
    }
    let h = hull[hull.length - 1];
    let p0, p1 = h * 4;
    let x0, x1 = points[2 * h];
    let y0, y1 = points[2 * h + 1];
    vectors.fill(0);
    for (let i = 0; i < hull.length; ++i) {
      h = hull[i];
      p0 = p1, x0 = x1, y0 = y1;
      p1 = h * 4, x1 = points[2 * h], y1 = points[2 * h + 1];
      vectors[p0 + 2] = vectors[p1] = y0 - y1;
      vectors[p0 + 3] = vectors[p1 + 1] = x1 - x0;
    }
  }
  render(context) {
    const buffer = context == null ? context = new Path2() : void 0;
    const { delaunay: { halfedges, inedges, hull }, circumcenters, vectors } = this;
    if (hull.length <= 1) return null;
    for (let i = 0, n = halfedges.length; i < n; ++i) {
      const j = halfedges[i];
      if (j < i) continue;
      const ti = Math.floor(i / 3) * 2;
      const tj = Math.floor(j / 3) * 2;
      const xi = circumcenters[ti];
      const yi = circumcenters[ti + 1];
      const xj = circumcenters[tj];
      const yj = circumcenters[tj + 1];
      this._renderSegment(xi, yi, xj, yj, context);
    }
    let h0, h1 = hull[hull.length - 1];
    for (let i = 0; i < hull.length; ++i) {
      h0 = h1, h1 = hull[i];
      const t = Math.floor(inedges[h1] / 3) * 2;
      const x2 = circumcenters[t];
      const y2 = circumcenters[t + 1];
      const v = h0 * 4;
      const p = this._project(x2, y2, vectors[v + 2], vectors[v + 3]);
      if (p) this._renderSegment(x2, y2, p[0], p[1], context);
    }
    return buffer && buffer.value();
  }
  renderBounds(context) {
    const buffer = context == null ? context = new Path2() : void 0;
    context.rect(this.xmin, this.ymin, this.xmax - this.xmin, this.ymax - this.ymin);
    return buffer && buffer.value();
  }
  renderCell(i, context) {
    const buffer = context == null ? context = new Path2() : void 0;
    const points = this._clip(i);
    if (points === null || !points.length) return;
    context.moveTo(points[0], points[1]);
    let n = points.length;
    while (points[0] === points[n - 2] && points[1] === points[n - 1] && n > 1) n -= 2;
    for (let i2 = 2; i2 < n; i2 += 2) {
      if (points[i2] !== points[i2 - 2] || points[i2 + 1] !== points[i2 - 1])
        context.lineTo(points[i2], points[i2 + 1]);
    }
    context.closePath();
    return buffer && buffer.value();
  }
  *cellPolygons() {
    const { delaunay: { points } } = this;
    for (let i = 0, n = points.length / 2; i < n; ++i) {
      const cell = this.cellPolygon(i);
      if (cell) cell.index = i, yield cell;
    }
  }
  cellPolygon(i) {
    const polygon = new Polygon();
    this.renderCell(i, polygon);
    return polygon.value();
  }
  _renderSegment(x0, y0, x1, y1, context) {
    let S;
    const c0 = this._regioncode(x0, y0);
    const c1 = this._regioncode(x1, y1);
    if (c0 === 0 && c1 === 0) {
      context.moveTo(x0, y0);
      context.lineTo(x1, y1);
    } else if (S = this._clipSegment(x0, y0, x1, y1, c0, c1)) {
      context.moveTo(S[0], S[1]);
      context.lineTo(S[2], S[3]);
    }
  }
  contains(i, x2, y2) {
    if ((x2 = +x2, x2 !== x2) || (y2 = +y2, y2 !== y2)) return false;
    return this.delaunay._step(i, x2, y2) === i;
  }
  *neighbors(i) {
    const ci = this._clip(i);
    if (ci) for (const j of this.delaunay.neighbors(i)) {
      const cj = this._clip(j);
      if (cj) loop: for (let ai = 0, li = ci.length; ai < li; ai += 2) {
        for (let aj = 0, lj = cj.length; aj < lj; aj += 2) {
          if (ci[ai] === cj[aj] && ci[ai + 1] === cj[aj + 1] && ci[(ai + 2) % li] === cj[(aj + lj - 2) % lj] && ci[(ai + 3) % li] === cj[(aj + lj - 1) % lj]) {
            yield j;
            break loop;
          }
        }
      }
    }
  }
  _cell(i) {
    const { circumcenters, delaunay: { inedges, halfedges, triangles } } = this;
    const e0 = inedges[i];
    if (e0 === -1) return null;
    const points = [];
    let e = e0;
    do {
      const t = Math.floor(e / 3);
      points.push(circumcenters[t * 2], circumcenters[t * 2 + 1]);
      e = e % 3 === 2 ? e - 2 : e + 1;
      if (triangles[e] !== i) break;
      e = halfedges[e];
    } while (e !== e0 && e !== -1);
    return points;
  }
  _clip(i) {
    if (i === 0 && this.delaunay.hull.length === 1) {
      return [this.xmax, this.ymin, this.xmax, this.ymax, this.xmin, this.ymax, this.xmin, this.ymin];
    }
    const points = this._cell(i);
    if (points === null) return null;
    const { vectors: V } = this;
    const v = i * 4;
    return this._simplify(V[v] || V[v + 1] ? this._clipInfinite(i, points, V[v], V[v + 1], V[v + 2], V[v + 3]) : this._clipFinite(i, points));
  }
  _clipFinite(i, points) {
    const n = points.length;
    let P = null;
    let x0, y0, x1 = points[n - 2], y1 = points[n - 1];
    let c0, c1 = this._regioncode(x1, y1);
    let e0, e1 = 0;
    for (let j = 0; j < n; j += 2) {
      x0 = x1, y0 = y1, x1 = points[j], y1 = points[j + 1];
      c0 = c1, c1 = this._regioncode(x1, y1);
      if (c0 === 0 && c1 === 0) {
        e0 = e1, e1 = 0;
        if (P) P.push(x1, y1);
        else P = [x1, y1];
      } else {
        let S, sx0, sy0, sx1, sy1;
        if (c0 === 0) {
          if ((S = this._clipSegment(x0, y0, x1, y1, c0, c1)) === null) continue;
          [sx0, sy0, sx1, sy1] = S;
        } else {
          if ((S = this._clipSegment(x1, y1, x0, y0, c1, c0)) === null) continue;
          [sx1, sy1, sx0, sy0] = S;
          e0 = e1, e1 = this._edgecode(sx0, sy0);
          if (e0 && e1) this._edge(i, e0, e1, P, P.length);
          if (P) P.push(sx0, sy0);
          else P = [sx0, sy0];
        }
        e0 = e1, e1 = this._edgecode(sx1, sy1);
        if (e0 && e1) this._edge(i, e0, e1, P, P.length);
        if (P) P.push(sx1, sy1);
        else P = [sx1, sy1];
      }
    }
    if (P) {
      e0 = e1, e1 = this._edgecode(P[0], P[1]);
      if (e0 && e1) this._edge(i, e0, e1, P, P.length);
    } else if (this.contains(i, (this.xmin + this.xmax) / 2, (this.ymin + this.ymax) / 2)) {
      return [this.xmax, this.ymin, this.xmax, this.ymax, this.xmin, this.ymax, this.xmin, this.ymin];
    }
    return P;
  }
  _clipSegment(x0, y0, x1, y1, c0, c1) {
    const flip = c0 < c1;
    if (flip) [x0, y0, x1, y1, c0, c1] = [x1, y1, x0, y0, c1, c0];
    while (true) {
      if (c0 === 0 && c1 === 0) return flip ? [x1, y1, x0, y0] : [x0, y0, x1, y1];
      if (c0 & c1) return null;
      let x2, y2, c = c0 || c1;
      if (c & 8) x2 = x0 + (x1 - x0) * (this.ymax - y0) / (y1 - y0), y2 = this.ymax;
      else if (c & 4) x2 = x0 + (x1 - x0) * (this.ymin - y0) / (y1 - y0), y2 = this.ymin;
      else if (c & 2) y2 = y0 + (y1 - y0) * (this.xmax - x0) / (x1 - x0), x2 = this.xmax;
      else y2 = y0 + (y1 - y0) * (this.xmin - x0) / (x1 - x0), x2 = this.xmin;
      if (c0) x0 = x2, y0 = y2, c0 = this._regioncode(x0, y0);
      else x1 = x2, y1 = y2, c1 = this._regioncode(x1, y1);
    }
  }
  _clipInfinite(i, points, vx0, vy0, vxn, vyn) {
    let P = Array.from(points), p;
    if (p = this._project(P[0], P[1], vx0, vy0)) P.unshift(p[0], p[1]);
    if (p = this._project(P[P.length - 2], P[P.length - 1], vxn, vyn)) P.push(p[0], p[1]);
    if (P = this._clipFinite(i, P)) {
      for (let j = 0, n = P.length, c0, c1 = this._edgecode(P[n - 2], P[n - 1]); j < n; j += 2) {
        c0 = c1, c1 = this._edgecode(P[j], P[j + 1]);
        if (c0 && c1) j = this._edge(i, c0, c1, P, j), n = P.length;
      }
    } else if (this.contains(i, (this.xmin + this.xmax) / 2, (this.ymin + this.ymax) / 2)) {
      P = [this.xmin, this.ymin, this.xmax, this.ymin, this.xmax, this.ymax, this.xmin, this.ymax];
    }
    return P;
  }
  _edge(i, e0, e1, P, j) {
    while (e0 !== e1) {
      let x2, y2;
      switch (e0) {
        case 5:
          e0 = 4;
          continue;
        case 4:
          e0 = 6, x2 = this.xmax, y2 = this.ymin;
          break;
        case 6:
          e0 = 2;
          continue;
        case 2:
          e0 = 10, x2 = this.xmax, y2 = this.ymax;
          break;
        case 10:
          e0 = 8;
          continue;
        case 8:
          e0 = 9, x2 = this.xmin, y2 = this.ymax;
          break;
        case 9:
          e0 = 1;
          continue;
        case 1:
          e0 = 5, x2 = this.xmin, y2 = this.ymin;
          break;
      }
      if ((P[j] !== x2 || P[j + 1] !== y2) && this.contains(i, x2, y2)) {
        P.splice(j, 0, x2, y2), j += 2;
      }
    }
    return j;
  }
  _project(x0, y0, vx, vy) {
    let t = Infinity, c, x2, y2;
    if (vy < 0) {
      if (y0 <= this.ymin) return null;
      if ((c = (this.ymin - y0) / vy) < t) y2 = this.ymin, x2 = x0 + (t = c) * vx;
    } else if (vy > 0) {
      if (y0 >= this.ymax) return null;
      if ((c = (this.ymax - y0) / vy) < t) y2 = this.ymax, x2 = x0 + (t = c) * vx;
    }
    if (vx > 0) {
      if (x0 >= this.xmax) return null;
      if ((c = (this.xmax - x0) / vx) < t) x2 = this.xmax, y2 = y0 + (t = c) * vy;
    } else if (vx < 0) {
      if (x0 <= this.xmin) return null;
      if ((c = (this.xmin - x0) / vx) < t) x2 = this.xmin, y2 = y0 + (t = c) * vy;
    }
    return [x2, y2];
  }
  _edgecode(x2, y2) {
    return (x2 === this.xmin ? 1 : x2 === this.xmax ? 2 : 0) | (y2 === this.ymin ? 4 : y2 === this.ymax ? 8 : 0);
  }
  _regioncode(x2, y2) {
    return (x2 < this.xmin ? 1 : x2 > this.xmax ? 2 : 0) | (y2 < this.ymin ? 4 : y2 > this.ymax ? 8 : 0);
  }
  _simplify(P) {
    if (P && P.length > 4) {
      for (let i = 0; i < P.length; i += 2) {
        const j = (i + 2) % P.length, k = (i + 4) % P.length;
        if (P[i] === P[j] && P[j] === P[k] || P[i + 1] === P[j + 1] && P[j + 1] === P[k + 1]) {
          P.splice(j, 2), i -= 2;
        }
      }
      if (!P.length) P = null;
    }
    return P;
  }
}
const tau = 2 * Math.PI, pow = Math.pow;
function pointX(p) {
  return p[0];
}
function pointY(p) {
  return p[1];
}
function collinear(d) {
  const { triangles, coords } = d;
  for (let i = 0; i < triangles.length; i += 3) {
    const a = 2 * triangles[i], b = 2 * triangles[i + 1], c = 2 * triangles[i + 2], cross = (coords[c] - coords[a]) * (coords[b + 1] - coords[a + 1]) - (coords[b] - coords[a]) * (coords[c + 1] - coords[a + 1]);
    if (cross > 1e-10) return false;
  }
  return true;
}
function jitter(x2, y2, r) {
  return [x2 + Math.sin(x2 + y2) * r, y2 + Math.cos(x2 - y2) * r];
}
class Delaunay {
  static from(points, fx = pointX, fy = pointY, that) {
    return new Delaunay("length" in points ? flatArray(points, fx, fy, that) : Float64Array.from(flatIterable(points, fx, fy, that)));
  }
  constructor(points) {
    this._delaunator = new Delaunator(points);
    this.inedges = new Int32Array(points.length / 2);
    this._hullIndex = new Int32Array(points.length / 2);
    this.points = this._delaunator.coords;
    this._init();
  }
  update() {
    this._delaunator.update();
    this._init();
    return this;
  }
  _init() {
    const d = this._delaunator, points = this.points;
    if (d.hull && d.hull.length > 2 && collinear(d)) {
      this.collinear = Int32Array.from({ length: points.length / 2 }, (_, i) => i).sort((i, j) => points[2 * i] - points[2 * j] || points[2 * i + 1] - points[2 * j + 1]);
      const e = this.collinear[0], f = this.collinear[this.collinear.length - 1], bounds = [points[2 * e], points[2 * e + 1], points[2 * f], points[2 * f + 1]], r = 1e-8 * Math.hypot(bounds[3] - bounds[1], bounds[2] - bounds[0]);
      for (let i = 0, n = points.length / 2; i < n; ++i) {
        const p = jitter(points[2 * i], points[2 * i + 1], r);
        points[2 * i] = p[0];
        points[2 * i + 1] = p[1];
      }
      this._delaunator = new Delaunator(points);
    } else {
      delete this.collinear;
    }
    const halfedges = this.halfedges = this._delaunator.halfedges;
    const hull = this.hull = this._delaunator.hull;
    const triangles = this.triangles = this._delaunator.triangles;
    const inedges = this.inedges.fill(-1);
    const hullIndex = this._hullIndex.fill(-1);
    for (let e = 0, n = halfedges.length; e < n; ++e) {
      const p = triangles[e % 3 === 2 ? e - 2 : e + 1];
      if (halfedges[e] === -1 || inedges[p] === -1) inedges[p] = e;
    }
    for (let i = 0, n = hull.length; i < n; ++i) {
      hullIndex[hull[i]] = i;
    }
    if (hull.length <= 2 && hull.length > 0) {
      this.triangles = new Int32Array(3).fill(-1);
      this.halfedges = new Int32Array(3).fill(-1);
      this.triangles[0] = hull[0];
      inedges[hull[0]] = 1;
      if (hull.length === 2) {
        inedges[hull[1]] = 0;
        this.triangles[1] = hull[1];
        this.triangles[2] = hull[1];
      }
    }
  }
  voronoi(bounds) {
    return new Voronoi2(this, bounds);
  }
  *neighbors(i) {
    const { inedges, hull, _hullIndex, halfedges, triangles, collinear: collinear2 } = this;
    if (collinear2) {
      const l = collinear2.indexOf(i);
      if (l > 0) yield collinear2[l - 1];
      if (l < collinear2.length - 1) yield collinear2[l + 1];
      return;
    }
    const e0 = inedges[i];
    if (e0 === -1) return;
    let e = e0, p0 = -1;
    do {
      yield p0 = triangles[e];
      e = e % 3 === 2 ? e - 2 : e + 1;
      if (triangles[e] !== i) return;
      e = halfedges[e];
      if (e === -1) {
        const p = hull[(_hullIndex[i] + 1) % hull.length];
        if (p !== p0) yield p;
        return;
      }
    } while (e !== e0);
  }
  find(x2, y2, i = 0) {
    if ((x2 = +x2, x2 !== x2) || (y2 = +y2, y2 !== y2)) return -1;
    const i0 = i;
    let c;
    while ((c = this._step(i, x2, y2)) >= 0 && c !== i && c !== i0) i = c;
    return c;
  }
  _step(i, x2, y2) {
    const { inedges, hull, _hullIndex, halfedges, triangles, points } = this;
    if (inedges[i] === -1 || !points.length) return (i + 1) % (points.length >> 1);
    let c = i;
    let dc = pow(x2 - points[i * 2], 2) + pow(y2 - points[i * 2 + 1], 2);
    const e0 = inedges[i];
    let e = e0;
    do {
      let t = triangles[e];
      const dt = pow(x2 - points[t * 2], 2) + pow(y2 - points[t * 2 + 1], 2);
      if (dt < dc) dc = dt, c = t;
      e = e % 3 === 2 ? e - 2 : e + 1;
      if (triangles[e] !== i) break;
      e = halfedges[e];
      if (e === -1) {
        e = hull[(_hullIndex[i] + 1) % hull.length];
        if (e !== t) {
          if (pow(x2 - points[e * 2], 2) + pow(y2 - points[e * 2 + 1], 2) < dc) return e;
        }
        break;
      }
    } while (e !== e0);
    return c;
  }
  render(context) {
    const buffer = context == null ? context = new Path2() : void 0;
    const { points, halfedges, triangles } = this;
    for (let i = 0, n = halfedges.length; i < n; ++i) {
      const j = halfedges[i];
      if (j < i) continue;
      const ti = triangles[i] * 2;
      const tj = triangles[j] * 2;
      context.moveTo(points[ti], points[ti + 1]);
      context.lineTo(points[tj], points[tj + 1]);
    }
    this.renderHull(context);
    return buffer && buffer.value();
  }
  renderPoints(context, r) {
    if (r === void 0 && (!context || typeof context.moveTo !== "function")) r = context, context = null;
    r = r == void 0 ? 2 : +r;
    const buffer = context == null ? context = new Path2() : void 0;
    const { points } = this;
    for (let i = 0, n = points.length; i < n; i += 2) {
      const x2 = points[i], y2 = points[i + 1];
      context.moveTo(x2 + r, y2);
      context.arc(x2, y2, r, 0, tau);
    }
    return buffer && buffer.value();
  }
  renderHull(context) {
    const buffer = context == null ? context = new Path2() : void 0;
    const { hull, points } = this;
    const h = hull[0] * 2, n = hull.length;
    context.moveTo(points[h], points[h + 1]);
    for (let i = 1; i < n; ++i) {
      const h2 = 2 * hull[i];
      context.lineTo(points[h2], points[h2 + 1]);
    }
    context.closePath();
    return buffer && buffer.value();
  }
  hullPolygon() {
    const polygon = new Polygon();
    this.renderHull(polygon);
    return polygon.value();
  }
  renderTriangle(i, context) {
    const buffer = context == null ? context = new Path2() : void 0;
    const { points, triangles } = this;
    const t0 = triangles[i *= 3] * 2;
    const t1 = triangles[i + 1] * 2;
    const t2 = triangles[i + 2] * 2;
    context.moveTo(points[t0], points[t0 + 1]);
    context.lineTo(points[t1], points[t1 + 1]);
    context.lineTo(points[t2], points[t2 + 1]);
    context.closePath();
    return buffer && buffer.value();
  }
  *trianglePolygons() {
    const { triangles } = this;
    for (let i = 0, n = triangles.length / 3; i < n; ++i) {
      yield this.trianglePolygon(i);
    }
  }
  trianglePolygon(i) {
    const polygon = new Polygon();
    this.renderTriangle(i, polygon);
    return polygon.value();
  }
}
function flatArray(points, fx, fy, that) {
  const n = points.length;
  const array2 = new Float64Array(n * 2);
  for (let i = 0; i < n; ++i) {
    const p = points[i];
    array2[i * 2] = fx.call(that, p, i, points);
    array2[i * 2 + 1] = fy.call(that, p, i, points);
  }
  return array2;
}
function* flatIterable(points, fx, fy, that) {
  let i = 0;
  for (const p of points) {
    yield fx.call(that, p, i, points);
    yield fy.call(that, p, i, points);
    ++i;
  }
}
function formatDecimal(x2) {
  return Math.abs(x2 = Math.round(x2)) >= 1e21 ? x2.toLocaleString("en").replace(/,/g, "") : x2.toString(10);
}
function formatDecimalParts(x2, p) {
  if ((i = (x2 = p ? x2.toExponential(p - 1) : x2.toExponential()).indexOf("e")) < 0) return null;
  var i, coefficient = x2.slice(0, i);
  return [
    coefficient.length > 1 ? coefficient[0] + coefficient.slice(2) : coefficient,
    +x2.slice(i + 1)
  ];
}
function exponent(x2) {
  return x2 = formatDecimalParts(Math.abs(x2)), x2 ? x2[1] : NaN;
}
function formatGroup(grouping, thousands) {
  return function(value, width2) {
    var i = value.length, t = [], j = 0, g = grouping[0], length = 0;
    while (i > 0 && g > 0) {
      if (length + g + 1 > width2) g = Math.max(1, width2 - length);
      t.push(value.substring(i -= g, i + g));
      if ((length += g + 1) > width2) break;
      g = grouping[j = (j + 1) % grouping.length];
    }
    return t.reverse().join(thousands);
  };
}
function formatNumerals(numerals) {
  return function(value) {
    return value.replace(/[0-9]/g, function(i) {
      return numerals[+i];
    });
  };
}
var re = /^(?:(.)?([<>=^]))?([+\-( ])?([$#])?(0)?(\d+)?(,)?(\.\d+)?(~)?([a-z%])?$/i;
function formatSpecifier(specifier) {
  if (!(match = re.exec(specifier))) throw new Error("invalid format: " + specifier);
  var match;
  return new FormatSpecifier({
    fill: match[1],
    align: match[2],
    sign: match[3],
    symbol: match[4],
    zero: match[5],
    width: match[6],
    comma: match[7],
    precision: match[8] && match[8].slice(1),
    trim: match[9],
    type: match[10]
  });
}
formatSpecifier.prototype = FormatSpecifier.prototype;
function FormatSpecifier(specifier) {
  this.fill = specifier.fill === void 0 ? " " : specifier.fill + "";
  this.align = specifier.align === void 0 ? ">" : specifier.align + "";
  this.sign = specifier.sign === void 0 ? "-" : specifier.sign + "";
  this.symbol = specifier.symbol === void 0 ? "" : specifier.symbol + "";
  this.zero = !!specifier.zero;
  this.width = specifier.width === void 0 ? void 0 : +specifier.width;
  this.comma = !!specifier.comma;
  this.precision = specifier.precision === void 0 ? void 0 : +specifier.precision;
  this.trim = !!specifier.trim;
  this.type = specifier.type === void 0 ? "" : specifier.type + "";
}
FormatSpecifier.prototype.toString = function() {
  return this.fill + this.align + this.sign + this.symbol + (this.zero ? "0" : "") + (this.width === void 0 ? "" : Math.max(1, this.width | 0)) + (this.comma ? "," : "") + (this.precision === void 0 ? "" : "." + Math.max(0, this.precision | 0)) + (this.trim ? "~" : "") + this.type;
};
function formatTrim(s) {
  out: for (var n = s.length, i = 1, i0 = -1, i1; i < n; ++i) {
    switch (s[i]) {
      case ".":
        i0 = i1 = i;
        break;
      case "0":
        if (i0 === 0) i0 = i;
        i1 = i;
        break;
      default:
        if (!+s[i]) break out;
        if (i0 > 0) i0 = 0;
        break;
    }
  }
  return i0 > 0 ? s.slice(0, i0) + s.slice(i1 + 1) : s;
}
var prefixExponent;
function formatPrefixAuto(x2, p) {
  var d = formatDecimalParts(x2, p);
  if (!d) return x2 + "";
  var coefficient = d[0], exponent2 = d[1], i = exponent2 - (prefixExponent = Math.max(-8, Math.min(8, Math.floor(exponent2 / 3))) * 3) + 1, n = coefficient.length;
  return i === n ? coefficient : i > n ? coefficient + new Array(i - n + 1).join("0") : i > 0 ? coefficient.slice(0, i) + "." + coefficient.slice(i) : "0." + new Array(1 - i).join("0") + formatDecimalParts(x2, Math.max(0, p + i - 1))[0];
}
function formatRounded(x2, p) {
  var d = formatDecimalParts(x2, p);
  if (!d) return x2 + "";
  var coefficient = d[0], exponent2 = d[1];
  return exponent2 < 0 ? "0." + new Array(-exponent2).join("0") + coefficient : coefficient.length > exponent2 + 1 ? coefficient.slice(0, exponent2 + 1) + "." + coefficient.slice(exponent2 + 1) : coefficient + new Array(exponent2 - coefficient.length + 2).join("0");
}
const formatTypes = {
  "%": (x2, p) => (x2 * 100).toFixed(p),
  "b": (x2) => Math.round(x2).toString(2),
  "c": (x2) => x2 + "",
  "d": formatDecimal,
  "e": (x2, p) => x2.toExponential(p),
  "f": (x2, p) => x2.toFixed(p),
  "g": (x2, p) => x2.toPrecision(p),
  "o": (x2) => Math.round(x2).toString(8),
  "p": (x2, p) => formatRounded(x2 * 100, p),
  "r": formatRounded,
  "s": formatPrefixAuto,
  "X": (x2) => Math.round(x2).toString(16).toUpperCase(),
  "x": (x2) => Math.round(x2).toString(16)
};
function identity$1(x2) {
  return x2;
}
var map = Array.prototype.map, prefixes = ["y", "z", "a", "f", "p", "n", "µ", "m", "", "k", "M", "G", "T", "P", "E", "Z", "Y"];
function formatLocale(locale2) {
  var group = locale2.grouping === void 0 || locale2.thousands === void 0 ? identity$1 : formatGroup(map.call(locale2.grouping, Number), locale2.thousands + ""), currencyPrefix = locale2.currency === void 0 ? "" : locale2.currency[0] + "", currencySuffix = locale2.currency === void 0 ? "" : locale2.currency[1] + "", decimal = locale2.decimal === void 0 ? "." : locale2.decimal + "", numerals = locale2.numerals === void 0 ? identity$1 : formatNumerals(map.call(locale2.numerals, String)), percent = locale2.percent === void 0 ? "%" : locale2.percent + "", minus = locale2.minus === void 0 ? "−" : locale2.minus + "", nan = locale2.nan === void 0 ? "NaN" : locale2.nan + "";
  function newFormat(specifier) {
    specifier = formatSpecifier(specifier);
    var fill = specifier.fill, align = specifier.align, sign = specifier.sign, symbol = specifier.symbol, zero2 = specifier.zero, width2 = specifier.width, comma = specifier.comma, precision = specifier.precision, trim = specifier.trim, type = specifier.type;
    if (type === "n") comma = true, type = "g";
    else if (!formatTypes[type]) precision === void 0 && (precision = 12), trim = true, type = "g";
    if (zero2 || fill === "0" && align === "=") zero2 = true, fill = "0", align = "=";
    var prefix = symbol === "$" ? currencyPrefix : symbol === "#" && /[boxX]/.test(type) ? "0" + type.toLowerCase() : "", suffix = symbol === "$" ? currencySuffix : /[%p]/.test(type) ? percent : "";
    var formatType = formatTypes[type], maybeSuffix = /[defgprs%]/.test(type);
    precision = precision === void 0 ? 6 : /[gprs]/.test(type) ? Math.max(1, Math.min(21, precision)) : Math.max(0, Math.min(20, precision));
    function format2(value) {
      var valuePrefix = prefix, valueSuffix = suffix, i, n, c;
      if (type === "c") {
        valueSuffix = formatType(value) + valueSuffix;
        value = "";
      } else {
        value = +value;
        var valueNegative = value < 0 || 1 / value < 0;
        value = isNaN(value) ? nan : formatType(Math.abs(value), precision);
        if (trim) value = formatTrim(value);
        if (valueNegative && +value === 0 && sign !== "+") valueNegative = false;
        valuePrefix = (valueNegative ? sign === "(" ? sign : minus : sign === "-" || sign === "(" ? "" : sign) + valuePrefix;
        valueSuffix = (type === "s" ? prefixes[8 + prefixExponent / 3] : "") + valueSuffix + (valueNegative && sign === "(" ? ")" : "");
        if (maybeSuffix) {
          i = -1, n = value.length;
          while (++i < n) {
            if (c = value.charCodeAt(i), 48 > c || c > 57) {
              valueSuffix = (c === 46 ? decimal + value.slice(i + 1) : value.slice(i)) + valueSuffix;
              value = value.slice(0, i);
              break;
            }
          }
        }
      }
      if (comma && !zero2) value = group(value, Infinity);
      var length = valuePrefix.length + value.length + valueSuffix.length, padding = length < width2 ? new Array(width2 - length + 1).join(fill) : "";
      if (comma && zero2) value = group(padding + value, padding.length ? width2 - valueSuffix.length : Infinity), padding = "";
      switch (align) {
        case "<":
          value = valuePrefix + value + valueSuffix + padding;
          break;
        case "=":
          value = valuePrefix + padding + value + valueSuffix;
          break;
        case "^":
          value = padding.slice(0, length = padding.length >> 1) + valuePrefix + value + valueSuffix + padding.slice(length);
          break;
        default:
          value = padding + valuePrefix + value + valueSuffix;
          break;
      }
      return numerals(value);
    }
    format2.toString = function() {
      return specifier + "";
    };
    return format2;
  }
  function formatPrefix2(specifier, value) {
    var f = newFormat((specifier = formatSpecifier(specifier), specifier.type = "f", specifier)), e = Math.max(-8, Math.min(8, Math.floor(exponent(value) / 3))) * 3, k = Math.pow(10, -e), prefix = prefixes[8 + e / 3];
    return function(value2) {
      return f(k * value2) + prefix;
    };
  }
  return {
    format: newFormat,
    formatPrefix: formatPrefix2
  };
}
var locale;
var format;
var formatPrefix;
defaultLocale({
  thousands: ",",
  grouping: [3],
  currency: ["$", ""]
});
function defaultLocale(definition) {
  locale = formatLocale(definition);
  format = locale.format;
  formatPrefix = locale.formatPrefix;
  return locale;
}
function precisionFixed(step) {
  return Math.max(0, -exponent(Math.abs(step)));
}
function precisionPrefix(step, value) {
  return Math.max(0, Math.max(-8, Math.min(8, Math.floor(exponent(value) / 3))) * 3 - exponent(Math.abs(step)));
}
function precisionRound(step, max2) {
  step = Math.abs(step), max2 = Math.abs(max2) - step;
  return Math.max(0, exponent(max2) - exponent(step)) + 1;
}
function area(polygon) {
  var i = -1, n = polygon.length, a, b = polygon[n - 1], area2 = 0;
  while (++i < n) {
    a = b;
    b = polygon[i];
    area2 += a[1] * b[0] - a[0] * b[1];
  }
  return area2 / 2;
}
function initInterpolator(domain, interpolator) {
  switch (arguments.length) {
    case 0:
      break;
    case 1: {
      if (typeof domain === "function") this.interpolator(domain);
      else this.range(domain);
      break;
    }
    default: {
      this.domain(domain);
      if (typeof interpolator === "function") this.interpolator(interpolator);
      else this.range(interpolator);
      break;
    }
  }
  return this;
}
function identity(x2) {
  return x2;
}
function tickFormat(start2, stop, count, specifier) {
  var step = tickStep(start2, stop, count), precision;
  specifier = formatSpecifier(specifier == null ? ",f" : specifier);
  switch (specifier.type) {
    case "s": {
      var value = Math.max(Math.abs(start2), Math.abs(stop));
      if (specifier.precision == null && !isNaN(precision = precisionPrefix(step, value))) specifier.precision = precision;
      return formatPrefix(specifier, value);
    }
    case "":
    case "e":
    case "g":
    case "p":
    case "r": {
      if (specifier.precision == null && !isNaN(precision = precisionRound(step, Math.max(Math.abs(start2), Math.abs(stop))))) specifier.precision = precision - (specifier.type === "e");
      break;
    }
    case "f":
    case "%": {
      if (specifier.precision == null && !isNaN(precision = precisionFixed(step))) specifier.precision = precision - (specifier.type === "%") * 2;
      break;
    }
  }
  return format(specifier);
}
function linearish(scale) {
  var domain = scale.domain;
  scale.ticks = function(count) {
    var d = domain();
    return ticks(d[0], d[d.length - 1], count == null ? 10 : count);
  };
  scale.tickFormat = function(count, specifier) {
    var d = domain();
    return tickFormat(d[0], d[d.length - 1], count == null ? 10 : count, specifier);
  };
  scale.nice = function(count) {
    if (count == null) count = 10;
    var d = domain();
    var i0 = 0;
    var i1 = d.length - 1;
    var start2 = d[i0];
    var stop = d[i1];
    var prestep;
    var step;
    var maxIter = 10;
    if (stop < start2) {
      step = start2, start2 = stop, stop = step;
      step = i0, i0 = i1, i1 = step;
    }
    while (maxIter-- > 0) {
      step = tickIncrement(start2, stop, count);
      if (step === prestep) {
        d[i0] = start2;
        d[i1] = stop;
        return domain(d);
      } else if (step > 0) {
        start2 = Math.floor(start2 / step) * step;
        stop = Math.ceil(stop / step) * step;
      } else if (step < 0) {
        start2 = Math.ceil(start2 * step) / step;
        stop = Math.floor(stop * step) / step;
      } else {
        break;
      }
      prestep = step;
    }
    return scale;
  };
  return scale;
}
function transformer() {
  var x0 = 0, x1 = 1, t0, t1, k10, transform, interpolator = identity, clamp = false, unknown;
  function scale(x2) {
    return x2 == null || isNaN(x2 = +x2) ? unknown : interpolator(k10 === 0 ? 0.5 : (x2 = (transform(x2) - t0) * k10, clamp ? Math.max(0, Math.min(1, x2)) : x2));
  }
  scale.domain = function(_) {
    return arguments.length ? ([x0, x1] = _, t0 = transform(x0 = +x0), t1 = transform(x1 = +x1), k10 = t0 === t1 ? 0 : 1 / (t1 - t0), scale) : [x0, x1];
  };
  scale.clamp = function(_) {
    return arguments.length ? (clamp = !!_, scale) : clamp;
  };
  scale.interpolator = function(_) {
    return arguments.length ? (interpolator = _, scale) : interpolator;
  };
  function range(interpolate2) {
    return function(_) {
      var r0, r1;
      return arguments.length ? ([r0, r1] = _, interpolator = interpolate2(r0, r1), scale) : [interpolator(0), interpolator(1)];
    };
  }
  scale.range = range(interpolate$1);
  scale.rangeRound = range(interpolateRound);
  scale.unknown = function(_) {
    return arguments.length ? (unknown = _, scale) : unknown;
  };
  return function(t) {
    transform = t, t0 = t(x0), t1 = t(x1), k10 = t0 === t1 ? 0 : 1 / (t1 - t0);
    return scale;
  };
}
function copy(source, target) {
  return target.domain(source.domain()).interpolator(source.interpolator()).clamp(source.clamp()).unknown(source.unknown());
}
function sequential() {
  var scale = linearish(transformer()(identity));
  scale.copy = function() {
    return copy(scale, sequential());
  };
  return initInterpolator.apply(scale, arguments);
}
function constant(x2) {
  return function constant2() {
    return x2;
  };
}
const epsilon = 1e-12;
function withPath(shape) {
  let digits = 3;
  shape.digits = function(_) {
    if (!arguments.length) return digits;
    if (_ == null) {
      digits = null;
    } else {
      const d = Math.floor(_);
      if (!(d >= 0)) throw new RangeError(`invalid digits: ${_}`);
      digits = d;
    }
    return shape;
  };
  return () => new Path$1(digits);
}
function array(x2) {
  return typeof x2 === "object" && "length" in x2 ? x2 : Array.from(x2);
}
function Linear(context) {
  this._context = context;
}
Linear.prototype = {
  areaStart: function() {
    this._line = 0;
  },
  areaEnd: function() {
    this._line = NaN;
  },
  lineStart: function() {
    this._point = 0;
  },
  lineEnd: function() {
    if (this._line || this._line !== 0 && this._point === 1) this._context.closePath();
    this._line = 1 - this._line;
  },
  point: function(x2, y2) {
    x2 = +x2, y2 = +y2;
    switch (this._point) {
      case 0:
        this._point = 1;
        this._line ? this._context.lineTo(x2, y2) : this._context.moveTo(x2, y2);
        break;
      case 1:
        this._point = 2;
      default:
        this._context.lineTo(x2, y2);
        break;
    }
  }
};
function curveLinear(context) {
  return new Linear(context);
}
function x(p) {
  return p[0];
}
function y(p) {
  return p[1];
}
function line(x$1, y$1) {
  var defined = constant(true), context = null, curve = curveLinear, output = null, path = withPath(line2);
  x$1 = typeof x$1 === "function" ? x$1 : x$1 === void 0 ? x : constant(x$1);
  y$1 = typeof y$1 === "function" ? y$1 : y$1 === void 0 ? y : constant(y$1);
  function line2(data) {
    var i, n = (data = array(data)).length, d, defined0 = false, buffer;
    if (context == null) output = curve(buffer = path());
    for (i = 0; i <= n; ++i) {
      if (!(i < n && defined(d = data[i], i, data)) === defined0) {
        if (defined0 = !defined0) output.lineStart();
        else output.lineEnd();
      }
      if (defined0) output.point(+x$1(d, i, data), +y$1(d, i, data));
    }
    if (buffer) return output = null, buffer + "" || null;
  }
  line2.x = function(_) {
    return arguments.length ? (x$1 = typeof _ === "function" ? _ : constant(+_), line2) : x$1;
  };
  line2.y = function(_) {
    return arguments.length ? (y$1 = typeof _ === "function" ? _ : constant(+_), line2) : y$1;
  };
  line2.defined = function(_) {
    return arguments.length ? (defined = typeof _ === "function" ? _ : constant(!!_), line2) : defined;
  };
  line2.curve = function(_) {
    return arguments.length ? (curve = _, context != null && (output = curve(context)), line2) : curve;
  };
  line2.context = function(_) {
    return arguments.length ? (_ == null ? context = output = null : output = curve(context = _), line2) : context;
  };
  return line2;
}
function noop() {
}
function point$2(that, x2, y2) {
  that._context.bezierCurveTo(
    (2 * that._x0 + that._x1) / 3,
    (2 * that._y0 + that._y1) / 3,
    (that._x0 + 2 * that._x1) / 3,
    (that._y0 + 2 * that._y1) / 3,
    (that._x0 + 4 * that._x1 + x2) / 6,
    (that._y0 + 4 * that._y1 + y2) / 6
  );
}
function BasisClosed(context) {
  this._context = context;
}
BasisClosed.prototype = {
  areaStart: noop,
  areaEnd: noop,
  lineStart: function() {
    this._x0 = this._x1 = this._x2 = this._x3 = this._x4 = this._y0 = this._y1 = this._y2 = this._y3 = this._y4 = NaN;
    this._point = 0;
  },
  lineEnd: function() {
    switch (this._point) {
      case 1: {
        this._context.moveTo(this._x2, this._y2);
        this._context.closePath();
        break;
      }
      case 2: {
        this._context.moveTo((this._x2 + 2 * this._x3) / 3, (this._y2 + 2 * this._y3) / 3);
        this._context.lineTo((this._x3 + 2 * this._x2) / 3, (this._y3 + 2 * this._y2) / 3);
        this._context.closePath();
        break;
      }
      case 3: {
        this.point(this._x2, this._y2);
        this.point(this._x3, this._y3);
        this.point(this._x4, this._y4);
        break;
      }
    }
  },
  point: function(x2, y2) {
    x2 = +x2, y2 = +y2;
    switch (this._point) {
      case 0:
        this._point = 1;
        this._x2 = x2, this._y2 = y2;
        break;
      case 1:
        this._point = 2;
        this._x3 = x2, this._y3 = y2;
        break;
      case 2:
        this._point = 3;
        this._x4 = x2, this._y4 = y2;
        this._context.moveTo((this._x0 + 4 * this._x1 + x2) / 6, (this._y0 + 4 * this._y1 + y2) / 6);
        break;
      default:
        point$2(this, x2, y2);
        break;
    }
    this._x0 = this._x1, this._x1 = x2;
    this._y0 = this._y1, this._y1 = y2;
  }
};
function curveBasisClosed(context) {
  return new BasisClosed(context);
}
function point$1(that, x2, y2) {
  that._context.bezierCurveTo(
    that._x1 + that._k * (that._x2 - that._x0),
    that._y1 + that._k * (that._y2 - that._y0),
    that._x2 + that._k * (that._x1 - x2),
    that._y2 + that._k * (that._y1 - y2),
    that._x2,
    that._y2
  );
}
function Cardinal(context, tension) {
  this._context = context;
  this._k = (1 - tension) / 6;
}
Cardinal.prototype = {
  areaStart: function() {
    this._line = 0;
  },
  areaEnd: function() {
    this._line = NaN;
  },
  lineStart: function() {
    this._x0 = this._x1 = this._x2 = this._y0 = this._y1 = this._y2 = NaN;
    this._point = 0;
  },
  lineEnd: function() {
    switch (this._point) {
      case 2:
        this._context.lineTo(this._x2, this._y2);
        break;
      case 3:
        point$1(this, this._x1, this._y1);
        break;
    }
    if (this._line || this._line !== 0 && this._point === 1) this._context.closePath();
    this._line = 1 - this._line;
  },
  point: function(x2, y2) {
    x2 = +x2, y2 = +y2;
    switch (this._point) {
      case 0:
        this._point = 1;
        this._line ? this._context.lineTo(x2, y2) : this._context.moveTo(x2, y2);
        break;
      case 1:
        this._point = 2;
        this._x1 = x2, this._y1 = y2;
        break;
      case 2:
        this._point = 3;
      default:
        point$1(this, x2, y2);
        break;
    }
    this._x0 = this._x1, this._x1 = this._x2, this._x2 = x2;
    this._y0 = this._y1, this._y1 = this._y2, this._y2 = y2;
  }
};
(function custom(tension) {
  function cardinal(context) {
    return new Cardinal(context, tension);
  }
  cardinal.tension = function(tension2) {
    return custom(+tension2);
  };
  return cardinal;
})(0);
function point(that, x2, y2) {
  var x1 = that._x1, y1 = that._y1, x22 = that._x2, y22 = that._y2;
  if (that._l01_a > epsilon) {
    var a = 2 * that._l01_2a + 3 * that._l01_a * that._l12_a + that._l12_2a, n = 3 * that._l01_a * (that._l01_a + that._l12_a);
    x1 = (x1 * a - that._x0 * that._l12_2a + that._x2 * that._l01_2a) / n;
    y1 = (y1 * a - that._y0 * that._l12_2a + that._y2 * that._l01_2a) / n;
  }
  if (that._l23_a > epsilon) {
    var b = 2 * that._l23_2a + 3 * that._l23_a * that._l12_a + that._l12_2a, m = 3 * that._l23_a * (that._l23_a + that._l12_a);
    x22 = (x22 * b + that._x1 * that._l23_2a - x2 * that._l12_2a) / m;
    y22 = (y22 * b + that._y1 * that._l23_2a - y2 * that._l12_2a) / m;
  }
  that._context.bezierCurveTo(x1, y1, x22, y22, that._x2, that._y2);
}
function CatmullRom(context, alpha) {
  this._context = context;
  this._alpha = alpha;
}
CatmullRom.prototype = {
  areaStart: function() {
    this._line = 0;
  },
  areaEnd: function() {
    this._line = NaN;
  },
  lineStart: function() {
    this._x0 = this._x1 = this._x2 = this._y0 = this._y1 = this._y2 = NaN;
    this._l01_a = this._l12_a = this._l23_a = this._l01_2a = this._l12_2a = this._l23_2a = this._point = 0;
  },
  lineEnd: function() {
    switch (this._point) {
      case 2:
        this._context.lineTo(this._x2, this._y2);
        break;
      case 3:
        this.point(this._x2, this._y2);
        break;
    }
    if (this._line || this._line !== 0 && this._point === 1) this._context.closePath();
    this._line = 1 - this._line;
  },
  point: function(x2, y2) {
    x2 = +x2, y2 = +y2;
    if (this._point) {
      var x23 = this._x2 - x2, y23 = this._y2 - y2;
      this._l23_a = Math.sqrt(this._l23_2a = Math.pow(x23 * x23 + y23 * y23, this._alpha));
    }
    switch (this._point) {
      case 0:
        this._point = 1;
        this._line ? this._context.lineTo(x2, y2) : this._context.moveTo(x2, y2);
        break;
      case 1:
        this._point = 2;
        break;
      case 2:
        this._point = 3;
      default:
        point(this, x2, y2);
        break;
    }
    this._l01_a = this._l12_a, this._l12_a = this._l23_a;
    this._l01_2a = this._l12_2a, this._l12_2a = this._l23_2a;
    this._x0 = this._x1, this._x1 = this._x2, this._x2 = x2;
    this._y0 = this._y1, this._y1 = this._y2, this._y2 = y2;
  }
};
const curveCatmullRom = function custom2(alpha) {
  function catmullRom(context) {
    return alpha ? new CatmullRom(context, alpha) : new Cardinal(context, 0);
  }
  catmullRom.alpha = function(alpha2) {
    return custom2(+alpha2);
  };
  return catmullRom;
}(0.5);
function Natural(context) {
  this._context = context;
}
Natural.prototype = {
  areaStart: function() {
    this._line = 0;
  },
  areaEnd: function() {
    this._line = NaN;
  },
  lineStart: function() {
    this._x = [];
    this._y = [];
  },
  lineEnd: function() {
    var x2 = this._x, y2 = this._y, n = x2.length;
    if (n) {
      this._line ? this._context.lineTo(x2[0], y2[0]) : this._context.moveTo(x2[0], y2[0]);
      if (n === 2) {
        this._context.lineTo(x2[1], y2[1]);
      } else {
        var px = controlPoints(x2), py = controlPoints(y2);
        for (var i0 = 0, i1 = 1; i1 < n; ++i0, ++i1) {
          this._context.bezierCurveTo(px[0][i0], py[0][i0], px[1][i0], py[1][i0], x2[i1], y2[i1]);
        }
      }
    }
    if (this._line || this._line !== 0 && n === 1) this._context.closePath();
    this._line = 1 - this._line;
    this._x = this._y = null;
  },
  point: function(x2, y2) {
    this._x.push(+x2);
    this._y.push(+y2);
  }
};
function controlPoints(x2) {
  var i, n = x2.length - 1, m, a = new Array(n), b = new Array(n), r = new Array(n);
  a[0] = 0, b[0] = 2, r[0] = x2[0] + 2 * x2[1];
  for (i = 1; i < n - 1; ++i) a[i] = 1, b[i] = 4, r[i] = 4 * x2[i] + 2 * x2[i + 1];
  a[n - 1] = 2, b[n - 1] = 7, r[n - 1] = 8 * x2[n - 1] + x2[n];
  for (i = 1; i < n; ++i) m = a[i] / b[i - 1], b[i] -= m, r[i] -= m * r[i - 1];
  a[n - 1] = r[n - 1] / b[n - 1];
  for (i = n - 2; i >= 0; --i) a[i] = (r[i] - a[i + 1]) / b[i];
  b[n - 1] = (x2[n] + a[n - 1]) / 2;
  for (i = 0; i < n - 1; ++i) b[i] = 2 * x2[i + 1] - a[i + 1];
  return [a, b];
}
function curveNatural(context) {
  return new Natural(context);
}
function Transform(k, x2, y2) {
  this.k = k;
  this.x = x2;
  this.y = y2;
}
Transform.prototype = {
  constructor: Transform,
  scale: function(k) {
    return k === 1 ? this : new Transform(this.k * k, this.x, this.y);
  },
  translate: function(x2, y2) {
    return x2 === 0 & y2 === 0 ? this : new Transform(this.k, this.x + this.k * x2, this.y + this.k * y2);
  },
  apply: function(point2) {
    return [point2[0] * this.k + this.x, point2[1] * this.k + this.y];
  },
  applyX: function(x2) {
    return x2 * this.k + this.x;
  },
  applyY: function(y2) {
    return y2 * this.k + this.y;
  },
  invert: function(location) {
    return [(location[0] - this.x) / this.k, (location[1] - this.y) / this.k];
  },
  invertX: function(x2) {
    return (x2 - this.x) / this.k;
  },
  invertY: function(y2) {
    return (y2 - this.y) / this.k;
  },
  rescaleX: function(x2) {
    return x2.copy().domain(x2.range().map(this.invertX, this).map(x2.invert, x2));
  },
  rescaleY: function(y2) {
    return y2.copy().domain(y2.range().map(this.invertY, this).map(y2.invert, y2));
  },
  toString: function() {
    return "translate(" + this.x + "," + this.y + ") scale(" + this.k + ")";
  }
};
Transform.prototype;
function rankCells({ pack, grid = null, options = null, biomesData }) {
  if (!pack || !pack.cells) {
    throw new Error("Pack object with cells is required");
  }
  if (!biomesData || !biomesData.habitability) {
    throw new Error("Biomes data with habitability scores is required");
  }
  const { cells, features } = pack;
  cells.s = new Int16Array(cells.i.length);
  cells.pop = new Float32Array(cells.i.length);
  const fluxValues = cells.fl ? Array.from(cells.fl).filter((f) => f > 0) : [];
  const flMean = fluxValues.length > 0 ? median(fluxValues) || 0 : 0;
  const flMax = cells.fl && cells.conf ? Math.max(...cells.fl) + Math.max(...cells.conf) : 0;
  const areaValues = cells.area ? Array.from(cells.area) : [];
  const areaMean = areaValues.length > 0 ? mean(areaValues) || 1 : 1;
  for (const i of cells.i) {
    if (cells.h[i] < 20) continue;
    const biomeId = cells.biome && cells.biome[i] !== void 0 ? cells.biome[i] : 0;
    let s = +biomesData.habitability[biomeId] || 0;
    if (!s) continue;
    if (flMean > 0 && cells.fl && cells.conf) {
      const flux = (cells.fl[i] || 0) + (cells.conf[i] || 0);
      if (flux > 0) {
        s += normalize(flux, flMean, flMax) * 250;
      }
    }
    s -= (cells.h[i] - 50) / 5;
    if (cells.t && cells.t[i] === 1) {
      if (cells.r && cells.r[i]) {
        s += 15;
      }
      if (cells.haven && cells.haven[i] !== void 0 && cells.f && features) {
        const havenCell = cells.haven[i];
        const featureId = cells.f[havenCell];
        const feature = features[featureId];
        if (feature && feature.type === "lake") {
          if (feature.group === "freshwater") {
            s += 30;
          } else if (feature.group === "salt") {
            s += 10;
          } else if (feature.group === "frozen") {
            s += 1;
          } else if (feature.group === "dry") {
            s -= 5;
          } else if (feature.group === "sinkhole") {
            s -= 5;
          } else if (feature.group === "lava") {
            s -= 30;
          }
        } else {
          s += 5;
          if (cells.harbor && cells.harbor[i] === 1) {
            s += 20;
          }
        }
      }
    }
    cells.s[i] = Math.round(s / 5);
    if (cells.s[i] > 0 && cells.area && cells.area[i]) {
      cells.pop[i] = cells.s[i] * cells.area[i] / areaMean;
    } else {
      cells.pop[i] = 0;
    }
  }
  if (typeof console !== "undefined" && console.log) {
    const populatedCells = Array.from(cells.s).filter((s) => s > 0).length;
    const maxSuitability = cells.s.length > 0 ? Math.max(...cells.s) : 0;
    const avgSuitability = populatedCells > 0 ? (Array.from(cells.s).reduce((a, b) => a + b, 0) / populatedCells).toFixed(2) : 0;
    const maxPopulation = cells.pop.length > 0 ? Math.max(...cells.pop) : 0;
    const avgPopulation = populatedCells > 0 ? (Array.from(cells.pop).reduce((a, b) => a + b, 0) / populatedCells).toFixed(2) : 0;
    console.log("[rankCells] Suitability and population calculated:", {
      totalCells: cells.i.length,
      populatedCells,
      populatedPercent: (populatedCells / cells.i.length * 100).toFixed(1) + "%",
      maxSuitability,
      avgSuitability,
      maxPopulation,
      avgPopulation,
      flMean: flMean.toFixed(2),
      flMax: flMax.toFixed(2),
      areaMean: areaMean.toFixed(2)
    });
  }
  return {
    s: cells.s,
    pop: cells.pop
  };
}
let SimplePriorityQueue$3 = class SimplePriorityQueue {
  constructor() {
    this.items = [];
  }
  push(item, priority) {
    this.items.push({ item, priority });
    this.items.sort((a, b) => a.priority - b.priority);
  }
  pop() {
    var _a;
    return (_a = this.items.shift()) == null ? void 0 : _a.item;
  }
  get length() {
    return this.items.length;
  }
};
function getDefaultCultures(culturesSet, count, pack, grid, rng) {
  const { cells } = pack;
  const { s, t, h, biome, haven, harbor, r, fl, g } = cells;
  const { temp } = grid.cells;
  const sMax = Math.max(...s);
  const n = (cell) => Math.ceil(s[cell] / sMax * 3);
  const td = (cell, goal) => {
    const d = Math.abs(temp[g[cell]] - goal);
    return d ? d + 1 : 1;
  };
  const bd = (cell, biomes, fee = 4) => biomes.includes(biome[cell]) ? 1 : fee;
  const sf = (cell, fee = 4) => haven[cell] && pack.features[cells.f[haven[cell]]].type !== "lake" ? 1 : fee;
  const defaultCultures = [
    { name: "Shwazen", base: 0, odd: 0.7, sort: (i) => n(i) / td(i, 10) / bd(i, [6, 8]), shield: "heater" },
    { name: "Angshire", base: 1, odd: 1, sort: (i) => n(i) / td(i, 10) / sf(i), shield: "heater" },
    { name: "Luari", base: 2, odd: 0.6, sort: (i) => n(i) / td(i, 12) / bd(i, [6, 8]), shield: "oldFrench" },
    { name: "Tallian", base: 3, odd: 0.6, sort: (i) => n(i) / td(i, 15), shield: "horsehead" },
    { name: "Astellian", base: 4, odd: 0.6, sort: (i) => n(i) / td(i, 16), shield: "spanish" },
    { name: "Slovan", base: 5, odd: 0.7, sort: (i) => n(i) / td(i, 6) * t[i], shield: "round" },
    { name: "Norse", base: 6, odd: 0.7, sort: (i) => n(i) / td(i, 5), shield: "heater" },
    { name: "Elladan", base: 7, odd: 0.7, sort: (i) => n(i) / td(i, 18) * h[i], shield: "boeotian" },
    { name: "Romian", base: 8, odd: 0.7, sort: (i) => n(i) / td(i, 15), shield: "roman" },
    { name: "Soumi", base: 9, odd: 0.3, sort: (i) => n(i) / td(i, 5) / bd(i, [9]) * t[i], shield: "pavise" },
    { name: "Koryo", base: 10, odd: 0.1, sort: (i) => n(i) / td(i, 12) / t[i], shield: "round" },
    { name: "Hantzu", base: 11, odd: 0.1, sort: (i) => n(i) / td(i, 13), shield: "banner" },
    { name: "Yamoto", base: 12, odd: 0.1, sort: (i) => n(i) / td(i, 15) / t[i], shield: "round" }
  ];
  const selected = [];
  const available = [...defaultCultures];
  for (let i = 0; selected.length < count && available.length > 0; ) {
    const rnd = rng.randInt(0, available.length - 1);
    const culture = available[rnd];
    let attempts = 0;
    while (attempts < 200 && !rng.probability(culture.odd)) {
      attempts++;
    }
    if (attempts < 200) {
      selected.push(culture);
      available.splice(rnd, 1);
    } else {
      selected.push(culture);
      available.splice(rnd, 1);
    }
  }
  return selected.slice(0, count);
}
function defineCultureType(cellId, pack, rng) {
  const { cells } = pack;
  const { h, biome, haven, harbor, r, fl, f } = cells;
  if (h[cellId] < 70 && [1, 2, 4].includes(biome[cellId])) return "Nomadic";
  if (h[cellId] > 50) return "Highland";
  const havenCell = haven && haven[cellId] !== void 0 ? haven[cellId] : null;
  const feature = havenCell !== null && pack.features && f[havenCell] !== void 0 ? pack.features[f[havenCell]] : null;
  if (feature && feature.type === "lake" && feature.cells > 5) return "Lake";
  if (harbor && harbor[cellId] && feature && feature.type !== "lake" && rng.probability(0.1) || harbor && harbor[cellId] === 1 && rng.probability(0.6) || pack.features && f[cellId] !== void 0 && pack.features[f[cellId]] && pack.features[f[cellId]].group === "isle" && rng.probability(0.4))
    return "Naval";
  if (r && r[cellId] && fl && fl[cellId] > 100) return "River";
  if (cells.t && cells.t[cellId] > 2 && [3, 7, 8, 9, 10, 12].includes(biome[cellId])) return "Hunting";
  return "Generic";
}
function defineCultureExpansionism(type, options, rng) {
  let base = 1;
  if (type === "Lake") base = 0.8;
  else if (type === "Naval") base = 1.5;
  else if (type === "River") base = 0.9;
  else if (type === "Nomadic") base = 1.5;
  else if (type === "Hunting") base = 0.7;
  else if (type === "Highland") base = 1.2;
  const sizeVariety = options.sizeVariety || 1;
  return rn((rng.random() * sizeVariety / 2 + 1) * base, 1);
}
function abbreviate(name, existingCodes) {
  const words = name.split(" ");
  let code = words.map((w) => w[0].toUpperCase()).join("");
  if (code.length > 3) code = code.substring(0, 3);
  if (existingCodes.includes(code)) {
    code = name.substring(0, 3).toUpperCase();
  }
  return code;
}
function placeCenter(sortingFn, populated, count, pack, options, rng, cultureIds, centers) {
  const spacing = (options.mapWidth + options.mapHeight) / 2 / count;
  const MAX_ATTEMPTS = 100;
  const sorted = [...populated].sort((a, b) => sortingFn(b) - sortingFn(a));
  const max2 = Math.floor(sorted.length / 2);
  let cellId = 0;
  let currentSpacing = spacing;
  for (let i = 0; i < MAX_ATTEMPTS; i++) {
    cellId = rng.biased(0, max2, 5);
    currentSpacing *= 0.9;
    if (!cultureIds[cellId]) {
      const [x2, y2] = pack.cells.p[cellId];
      let tooClose = false;
      for (const center of centers) {
        const [cx, cy] = pack.cells.p[center];
        const dist = Math.sqrt((x2 - cx) ** 2 + (y2 - cy) ** 2);
        if (dist < currentSpacing) {
          tooClose = true;
          break;
        }
      }
      if (!tooClose) break;
    }
  }
  return cellId;
}
function generateCultures({ pack, grid, options, rng, biomesData: providedBiomesData = null }) {
  if (!pack || !pack.cells) {
    throw new Error("Pack object with cells is required");
  }
  if (!rng) {
    throw new Error("RNG instance is required");
  }
  providedBiomesData || getDefaultBiomes();
  const { cells } = pack;
  const cultureIds = createTypedArray({ maxValue: 65535, length: cells.i.length });
  const culturesNumber = options.cultures || 12;
  const culturesSet = options.culturesSet || "world";
  const baseScore = cells.s || (cells.pop ? cells.pop : new Float32Array(cells.i.length));
  const populated = cells.i.filter((i) => baseScore[i] > 0);
  if (populated.length < culturesNumber * 25) {
    const adjustedCount = Math.floor(populated.length / 50);
    if (!adjustedCount) {
      pack.cultures = [{ name: "Wildlands", i: 0, base: 1, shield: "round", origins: [null] }];
      cells.culture = cultureIds;
      return pack.cultures;
    }
  }
  const count = Math.min(culturesNumber, populated.length / 25);
  const cultures = getDefaultCultures(culturesSet, count, pack, grid, rng);
  const centers = [];
  const codes = [];
  cultures.forEach((c, i) => {
    const newId2 = i + 1;
    const sortingFn = c.sort || ((i2) => baseScore[i2]);
    const center = placeCenter(sortingFn, populated, count, pack, options, rng, cultureIds, centers);
    centers.push(center);
    c.center = center;
    c.i = newId2;
    delete c.odd;
    delete c.sort;
    c.color = `hsl(${rng.randInt(0, 360)}, 70%, 50%)`;
    c.type = defineCultureType(center, pack, rng);
    c.expansionism = defineCultureExpansionism(c.type, options, rng);
    c.origins = [0];
    c.code = abbreviate(c.name, codes);
    codes.push(c.code);
    c.shield = c.shield || "heater";
    cultureIds[center] = newId2;
  });
  cultures.unshift({ name: "Wildlands", i: 0, base: 1, origins: [null], shield: "round" });
  cells.culture = cultureIds;
  pack.cultures = cultures;
  return cultures;
}
function expandCultures({ pack, options, biomesData: providedBiomesData = null }) {
  if (!pack || !pack.cells || !pack.cultures) {
    throw new Error("Pack object with cells and cultures is required");
  }
  const biomesData = providedBiomesData || getDefaultBiomes();
  const { cells, cultures } = pack;
  const queue = new SimplePriorityQueue$3();
  const cost = [];
  const neutralRate = options.neutralRate || 1;
  const maxExpansionCost = cells.i.length * 0.6 * neutralRate;
  const hasLocked = cultures.some((c) => !c.removed && c.lock);
  if (hasLocked) {
    for (const cellId of cells.i) {
      const culture = cultures[cells.culture[cellId]];
      if (culture && culture.lock) continue;
      cells.culture[cellId] = 0;
    }
  } else {
    cells.culture = createTypedArray({ maxValue: 65535, length: cells.i.length });
  }
  for (const culture of cultures) {
    if (!culture.i || culture.removed || culture.lock) continue;
    queue.push({ cellId: culture.center, cultureId: culture.i, priority: 0 }, 0);
  }
  while (queue.length) {
    const { cellId, priority, cultureId } = queue.pop();
    const { type, expansionism } = cultures[cultureId];
    if (!cells.c[cellId]) continue;
    cells.c[cellId].forEach((neibCellId) => {
      if (hasLocked) {
        const neibCultureId = cells.culture[neibCellId];
        if (neibCultureId && cultures[neibCultureId] && cultures[neibCultureId].lock) return;
      }
      const biome = cells.biome ? cells.biome[neibCellId] : 0;
      const biomeCost = getBiomeCost(cultureId, biome, type, biomesData, cells);
      const biomeChangeCost = biome === (cells.biome && cells.biome[cultures[cultureId].center] ? cells.biome[cultures[cultureId].center] : 0) ? 0 : 20;
      const heightCost = getHeightCost(neibCellId, cells.h[neibCellId], type, pack);
      const riverCost = getRiverCost(cells.r ? cells.r[neibCellId] : 0, neibCellId, type, cells);
      const typeCost = getTypeCost(cells.t ? cells.t[neibCellId] : 0, type);
      const cellCost = (biomeCost + biomeChangeCost + heightCost + riverCost + typeCost) / expansionism;
      const totalCost = priority + cellCost;
      if (totalCost > maxExpansionCost) return;
      if (!cost[neibCellId] || totalCost < cost[neibCellId]) {
        const hasPopulation = cells.pop && cells.pop[neibCellId] > 0 || cells.s && cells.s[neibCellId] > 0;
        if (hasPopulation) cells.culture[neibCellId] = cultureId;
        cost[neibCellId] = totalCost;
        queue.push({ cellId: neibCellId, cultureId, priority: totalCost }, totalCost);
      }
    });
  }
  function getBiomeCost(c, biome, type, biomesData2, cells2) {
    if (cells2.biome[cultures[c].center] === biome) return 10;
    if (type === "Hunting") return biomesData2.cost[biome] * 5;
    if (type === "Nomadic" && biome > 4 && biome < 10) return biomesData2.cost[biome] * 10;
    return biomesData2.cost[biome] * 2;
  }
  function getHeightCost(i, h, type, pack2) {
    const f = pack2.features[pack2.cells.f[i]];
    const a = pack2.cells.area ? pack2.cells.area[i] : 1;
    if (type === "Lake" && f && f.type === "lake") return 10;
    if (type === "Naval" && h < 20) return a * 2;
    if (type === "Nomadic" && h < 20) return a * 50;
    if (h < 20) return a * 6;
    if (type === "Highland" && h < 44) return 3e3;
    if (type === "Highland" && h < 62) return 200;
    if (type === "Highland") return 0;
    if (h >= 67) return 200;
    if (h >= 44) return 30;
    return 0;
  }
  function getRiverCost(riverId, cellId, type, cells2) {
    if (type === "River") return riverId ? 0 : 100;
    if (!riverId) return 0;
    const flux = cells2.fl && cells2.fl[cellId] ? cells2.fl[cellId] : 0;
    return minmax(flux / 10, 20, 100);
  }
  function getTypeCost(t, type) {
    if (t === 1) return type === "Naval" || type === "Lake" ? 0 : type === "Nomadic" ? 60 : 20;
    if (t === 2) return type === "Naval" || type === "Nomadic" ? 30 : 0;
    if (t !== -1) return type === "Naval" || type === "Lake" ? 100 : 0;
    return 0;
  }
}
let SimpleQuadtree$1 = class SimpleQuadtree {
  constructor() {
    this.points = [];
  }
  add(point2) {
    this.points.push(point2);
  }
  find(x2, y2, radius) {
    for (const [px, py] of this.points) {
      const dist = Math.sqrt((x2 - px) ** 2 + (y2 - py) ** 2);
      if (dist < radius) return [px, py];
    }
    return void 0;
  }
};
function getCloseToEdgePoint(cell1, cell2, pack) {
  const { cells, vertices } = pack;
  const [x0, y0] = cells.p[cell1];
  if (!cells.v[cell1] || !vertices) {
    return [x0, y0];
  }
  const commonVertices = cells.v[cell1].filter((vertex) => vertices.c[vertex] && vertices.c[vertex].some((cell) => cell === cell2));
  if (commonVertices.length < 2) {
    return [x0, y0];
  }
  const [x1, y1] = vertices.p[commonVertices[0]];
  const [x2, y2] = vertices.p[commonVertices[1]];
  const xEdge = (x1 + x2) / 2;
  const yEdge = (y1 + y2) / 2;
  const x3 = rn(x0 + 0.95 * (xEdge - x0), 2);
  const y3 = rn(y0 + 0.95 * (yEdge - y0), 2);
  return [x3, y3];
}
function getBurgType(cellId, port, pack) {
  const { cells, features } = pack;
  if (port) return "Naval";
  const haven = cells.haven[cellId];
  if (haven !== void 0 && features[cells.f[haven]] && features[cells.f[haven]].type === "lake") return "Lake";
  if (cells.h[cellId] > 60) return "Highland";
  if (cells.r[cellId] && cells.fl[cellId] >= 100) return "River";
  const biome = cells.biome[cellId];
  const population = cells.pop ? cells.pop[cellId] : 0;
  if (!cells.burg[cellId] || population <= 5) {
    if (population < 5 && [1, 2, 3, 4].includes(biome)) return "Nomadic";
    if (biome > 4 && biome < 10) return "Hunting";
  }
  return "Generic";
}
function placeCapitals({ pack, options, rng }) {
  const { cells } = pack;
  const statesNumber = options.statesNumber || 18;
  let burgs = [null];
  const baseScore = cells.s || (cells.pop ? cells.pop : new Float32Array(cells.i.length));
  const score = new Int16Array(Array.from(baseScore).map((s) => s * (0.5 + rng.random() * 0.5)));
  const sorted = cells.i.filter((i) => score[i] > 0 && cells.culture && cells.culture[i]).sort((a, b) => score[b] - score[a]);
  let count = statesNumber;
  if (sorted.length < count * 10) {
    count = Math.floor(sorted.length / 10);
    if (!count) {
      return burgs;
    }
  }
  let burgsTree = new SimpleQuadtree$1();
  let spacing = (options.mapWidth + options.mapHeight) / 2 / count;
  let retryCount = 0;
  const maxRetries = 10;
  while (burgs.length <= count && retryCount < maxRetries) {
    for (let i = 0; i < sorted.length && burgs.length <= count; i++) {
      const cell = sorted[i];
      const [x2, y2] = cells.p[cell];
      if (!burgsTree.find(x2, y2, spacing)) {
        burgs.push({ cell, x: x2, y: y2 });
        burgsTree.add([x2, y2]);
        if (burgs.length > count) {
          break;
        }
      }
    }
    if (burgs.length <= count && spacing > 1 && retryCount < maxRetries - 1) {
      burgsTree = new SimpleQuadtree$1();
      burgs = [null];
      spacing /= 1.2;
      retryCount++;
    } else {
      break;
    }
  }
  if (burgs.length > count + 1) {
    burgs = [null, ...burgs.slice(1, count + 1)];
  }
  if (typeof console !== "undefined" && console.log) {
    console.log("[placeCapitals] Capital placement:", {
      desiredCount: count,
      placedCount: burgs.length - 1,
      // Exclude null at index 0
      spacing: spacing.toFixed(2),
      sortedLength: sorted.length
    });
  }
  return burgs;
}
function placeTowns({ pack, options, rng, burgs, burgsTree }) {
  const { cells } = pack;
  const baseScore = cells.s || (cells.pop ? cells.pop : new Float32Array(cells.i.length));
  const score = new Int16Array(
    Array.from(baseScore).map((s) => s * gauss(1, 3, 0, 20, 3, rng))
  );
  const sorted = cells.i.filter((i) => !cells.burg[i] && score[i] > 0 && cells.culture && cells.culture[i]).sort((a, b) => score[b] - score[a]);
  const cellsDesired = options.cellsDesired || 1e4;
  const desiredNumber = options.manors === 1e3 || options.manors === "auto" ? rn(sorted.length / 5 / (cellsDesired / 1e4) ** 0.8) : options.manors || 1e3;
  const burgsNumber = Math.min(desiredNumber, sorted.length);
  let burgsAdded = 0;
  let spacing = (options.mapWidth + options.mapHeight) / 150 / (burgsNumber ** 0.7 / 66);
  while (burgsAdded < burgsNumber && spacing > 1) {
    for (let i = 0; burgsAdded < burgsNumber && i < sorted.length; i++) {
      if (cells.burg[sorted[i]]) continue;
      const cell = sorted[i];
      const [x2, y2] = cells.p[cell];
      const s = spacing * gauss(1, 0.3, 0.2, 2, 2, rng);
      if (burgsTree.find(x2, y2, s)) continue;
      const burg = burgs.length;
      const culture = cells.culture[cell];
      let name = `Town${burg}`;
      if (pack.cultures && culture !== void 0 && pack.cultures[culture]) {
        const cultureName = pack.cultures[culture].name || "";
        const suffixes = ["burg", "ton", "ville", "ford", "port", "haven", "gate", "keep", "hall", "stead"];
        const suffix = suffixes[rng.randInt(0, suffixes.length - 1)];
        if (cultureName.length > 0) {
          const prefix = cultureName.substring(0, Math.min(5, cultureName.length));
          name = prefix.charAt(0).toUpperCase() + prefix.slice(1).toLowerCase() + suffix;
        }
      }
      burgs.push({
        cell,
        x: x2,
        y: y2,
        state: 0,
        i: burg,
        culture,
        name,
        capital: 0,
        feature: cells.f[cell]
      });
      burgsTree.add([x2, y2]);
      cells.burg[cell] = burg;
      burgsAdded++;
    }
    spacing *= 0.5;
  }
}
function specifyBurgs({ pack, grid, options, rng }) {
  const { cells, features } = pack;
  const temp = grid.cells.temp;
  for (const b of pack.burgs) {
    if (!b || !b.i || b.lock) continue;
    const i = b.cell;
    const haven = cells.haven[i];
    if (haven !== void 0 && temp[cells.g[i]] > 0) {
      const f = cells.f[haven];
      const feature = features[f];
      const port = feature && feature.cells > 1 && (b.capital && cells.harbor[i] || cells.harbor[i] === 1);
      b.port = port ? f : 0;
    } else {
      b.port = 0;
    }
    const suitability = cells.s ? cells.s[i] : cells.pop ? cells.pop[i] : 0;
    b.population = rn(Math.max(suitability / 8 + b.i / 1e3 + i % 100 / 1e3, 0.1), 3);
    if (b.capital) b.population = rn(b.population * 1.3, 3);
    if (b.port) {
      b.population = b.population * 1.3;
      const [x2, y2] = getCloseToEdgePoint(i, haven, pack);
      b.x = x2;
      b.y = y2;
    }
    b.population = rn(b.population * gauss(2, 3, 0.6, 20, 3, rng), 3);
    if (!b.port && cells.r[i]) {
      const shift = Math.min((cells.fl[i] || 0) / 150, 1);
      if (i % 2) b.x = rn(b.x + shift, 2);
      else b.x = rn(b.x - shift, 2);
      if (cells.r[i] % 2) b.y = rn(b.y + shift, 2);
      else b.y = rn(b.y - shift, 2);
    }
    b.type = getBurgType(i, b.port, pack);
  }
  const ports = pack.burgs.filter((b) => b && b.i && !b.removed && b.port > 0);
  for (const f of features) {
    if (!f || !f.i || f.land || f.border) continue;
    const featurePorts = ports.filter((b) => b.port === f.i);
    if (featurePorts.length === 1) featurePorts[0].port = 0;
  }
}
function generateBurgs({ pack, grid, options, rng }) {
  if (!pack || !pack.cells) {
    throw new Error("Pack object with cells is required");
  }
  if (!rng) {
    throw new Error("RNG instance is required");
  }
  const { cells } = pack;
  const n = cells.i.length;
  cells.burg = createTypedArray({ maxValue: 65535, length: n });
  const burgs = placeCapitals({ pack, options, rng });
  const burgsTree = new SimpleQuadtree$1();
  for (let i = 1; i < burgs.length; i++) {
    if (burgs[i]) {
      burgsTree.add([burgs[i].x, burgs[i].y]);
    }
  }
  placeTowns({ pack, options, rng, burgs, burgsTree });
  const statesNumber = options.statesNumber || 18;
  const maxCapitals = Math.min(statesNumber, burgs.length - 1);
  if (typeof console !== "undefined" && console.log) {
    console.log("[generateBurgs] Before marking capitals:", {
      totalBurgs: burgs.length - 1,
      // Exclude null
      statesNumber,
      maxCapitals
    });
  }
  let capitalsMarked = 0;
  for (let i = 1; i <= maxCapitals; i++) {
    if (!burgs[i]) continue;
    const b = burgs[i];
    b.i = i;
    b.state = i;
    b.culture = cells.culture[b.cell];
    let capitalName = `Capital${i}`;
    if (pack.cultures && b.culture !== void 0 && pack.cultures[b.culture]) {
      const cultureName = pack.cultures[b.culture].name || "";
      if (cultureName.length > 0) {
        const suffixes = ["burg", "ton", "ville", "ford", "port", "haven", "gate", "keep", "hall", "stead", "holm", "wick"];
        const suffix = suffixes[rng.randInt(0, suffixes.length - 1)];
        const prefix = cultureName.substring(0, Math.min(6, cultureName.length));
        capitalName = prefix.charAt(0).toUpperCase() + prefix.slice(1).toLowerCase() + suffix;
      }
    }
    b.name = capitalName;
    b.feature = cells.f[b.cell];
    b.capital = 1;
    cells.burg[b.cell] = i;
    capitalsMarked++;
  }
  let townsMarked = 0;
  for (let i = maxCapitals + 1; i < burgs.length; i++) {
    if (!burgs[i]) continue;
    const b = burgs[i];
    b.i = i;
    b.capital = 0;
    b.state = 0;
    b.culture = cells.culture[b.cell];
    if (!b.name || b.name === `Town${i}`) {
      if (pack.cultures && b.culture !== void 0 && pack.cultures[b.culture]) {
        const cultureName = pack.cultures[b.culture].name || "";
        if (cultureName.length > 0) {
          const suffixes = ["burg", "ton", "ville", "ford", "port", "haven", "gate", "keep", "hall", "stead"];
          const suffix = suffixes[rng.randInt(0, suffixes.length - 1)];
          const prefix = cultureName.substring(0, Math.min(5, cultureName.length));
          b.name = prefix.charAt(0).toUpperCase() + prefix.slice(1).toLowerCase() + suffix;
        } else {
          b.name = `Town${i}`;
        }
      } else {
        b.name = `Town${i}`;
      }
    }
    b.feature = cells.f[b.cell];
    cells.burg[b.cell] = i;
    townsMarked++;
  }
  if (typeof console !== "undefined" && console.log) {
    const actualCapitals = burgs.filter((b, i) => i > 0 && b && b.capital === 1).length;
    console.log("[generateBurgs] After marking capitals:", {
      capitalsMarked,
      townsMarked,
      actualCapitals,
      totalBurgs: burgs.length - 1
    });
  }
  pack.burgs = burgs;
  specifyBurgs({ pack, grid, options, rng });
  return burgs;
}
let SimplePriorityQueue$2 = class SimplePriorityQueue2 {
  constructor() {
    this.items = [];
  }
  push(item, priority) {
    this.items.push({ item, priority });
    this.items.sort((a, b) => a.priority - b.priority);
  }
  pop() {
    var _a;
    return (_a = this.items.shift()) == null ? void 0 : _a.item;
  }
  get length() {
    return this.items.length;
  }
};
function getRandomColor$1(rng) {
  const colors2 = [
    "#a8d5ba",
    // Soft teal-green
    "#f4a582",
    // Soft coral
    "#b3cde3",
    // Soft blue
    "#decbe4",
    // Soft purple
    "#ccebc5",
    // Soft mint
    "#fed9a6",
    // Soft peach
    "#ffffcc",
    // Soft yellow
    "#e5d8bd",
    // Soft beige
    "#d9d9d9",
    // Soft gray
    "#bebada",
    // Soft lavender
    "#fb8072",
    // Soft rose
    "#80b1d3",
    // Soft sky blue
    "#fdb462",
    // Soft orange
    "#b3de69",
    // Soft lime
    "#fccde5",
    // Soft pink
    "#bc80bd",
    // Soft mauve
    "#ccebc5",
    // Soft green
    "#ffed6f"
    // Soft gold
  ];
  return rng.pick(colors2);
}
function createStates({ pack, options, rng }) {
  const { cells, burgs, cultures } = pack;
  const states = [{ i: 0, name: "Neutrals" }];
  const colors2 = [
    "#a8d5ba",
    // Soft teal-green
    "#f4a582",
    // Soft coral
    "#b3cde3",
    // Soft blue
    "#decbe4",
    // Soft purple
    "#ccebc5",
    // Soft mint
    "#fed9a6",
    // Soft peach
    "#ffffcc",
    // Soft yellow
    "#e5d8bd",
    // Soft beige
    "#d9d9d9",
    // Soft gray
    "#bebada",
    // Soft lavender
    "#fb8072",
    // Soft rose
    "#80b1d3",
    // Soft sky blue
    "#fdb462",
    // Soft orange
    "#b3de69",
    // Soft lime
    "#fccde5",
    // Soft pink
    "#bc80bd",
    // Soft mauve
    "#ccebc5",
    // Soft green
    "#ffed6f"
    // Soft gold
  ];
  const statesNumber = options.statesNumber || 18;
  const allCapitals = burgs.filter((b) => b && b.capital);
  const capitals = allCapitals.slice(0, statesNumber);
  if (typeof console !== "undefined" && console.log) {
    console.log("[createStates] Capital filtering:", {
      totalCapitals: allCapitals.length,
      limitedCapitals: capitals.length,
      statesNumber,
      limited: allCapitals.length > statesNumber
    });
  }
  capitals.forEach((b, i) => {
    const stateId = i + 1;
    const culture = cells.culture[b.cell];
    const cultureData = cultures[culture];
    const sizeVariety = options.sizeVariety || 1;
    const expansionism = rn(rng.random() * sizeVariety + 1, 1);
    const type = cultureData ? cultureData.type : "Generic";
    let name = `State${stateId}`;
    let fullName = name;
    if (b.name && b.name !== `Burg${b.i}` && b.name.length > 2) {
      const burgName = b.name;
      const forms2 = ["Kingdom", "Empire", "Realm", "Dominion", "Principality", "Duchy", "Republic", "Federation"];
      const form = forms2[rng.randInt(0, forms2.length - 1)];
      name = burgName;
      fullName = `${form} of ${burgName}`;
    } else if (cultureData && cultureData.name) {
      const cultureName = cultureData.name;
      const forms2 = ["Kingdom", "Empire", "Realm", "Dominion", "Principality", "Duchy"];
      const form = forms2[rng.randInt(0, forms2.length - 1)];
      name = cultureName;
      fullName = `${form} of ${cultureName}`;
    }
    states.push({
      i: stateId,
      color: colors2[(stateId - 1) % colors2.length],
      name,
      fullName,
      expansionism,
      capital: b.i,
      type,
      center: b.cell,
      culture: culture || 0,
      coa: null,
      // Placeholder for coat of arms
      form: "Monarchy"
      // Default form
    });
    b.state = stateId;
  });
  if (allCapitals.length > statesNumber) {
    allCapitals.slice(statesNumber).forEach((b) => {
      b.capital = 0;
      b.state = 0;
    });
  }
  return states;
}
function expandStates({ pack, options, biomesData: providedBiomesData = null }) {
  if (!pack || !pack.cells || !pack.states) {
    throw new Error("Pack object with cells and states is required");
  }
  const biomesData = providedBiomesData || getDefaultBiomes();
  const { cells, states, cultures, burgs } = pack;
  cells.state = cells.state || createTypedArray({ maxValue: 65535, length: cells.i.length });
  const queue = new SimplePriorityQueue$2();
  const cost = [];
  const globalGrowthRate = options.growthRate || 1;
  const statesGrowthRate = options.statesGrowthRate || 1;
  const growthRate = cells.i.length / 2 * globalGrowthRate * statesGrowthRate;
  for (const cellId of cells.i) {
    const state2 = states[cells.state[cellId]];
    if (state2 && state2.lock) continue;
    cells.state[cellId] = 0;
  }
  for (const state2 of states) {
    if (!state2.i || state2.removed) continue;
    const capitalBurg = burgs && burgs[state2.capital];
    if (!capitalBurg) continue;
    const capitalCell = capitalBurg.cell;
    if (capitalCell !== void 0) {
      cells.state[capitalCell] = state2.i;
    }
    const cultureCenter = cultures && cultures[state2.culture] ? cultures[state2.culture].center : capitalCell;
    const b = cells.biome && cells.biome[cultureCenter] !== void 0 ? cells.biome[cultureCenter] : 0;
    queue.push({ e: state2.center, p: 0, s: state2.i, b }, 0);
    cost[state2.center] = 1;
  }
  while (queue.length) {
    const next = queue.pop();
    const { e, p, s, b } = next;
    const { type, culture } = states[s];
    if (!cells.c[e]) continue;
    cells.c[e].forEach((neighborCell) => {
      const neighborState = states[cells.state[neighborCell]];
      if (neighborState && neighborState.lock) return;
      if (cells.state[neighborCell] && neighborCell === states[cells.state[neighborCell]].center) return;
      const neighborCulture = cells.culture && cells.culture[neighborCell] !== void 0 ? cells.culture[neighborCell] : 0;
      const cultureCost = culture === neighborCulture ? -9 : 100;
      const suitability = cells.s && cells.s[neighborCell] !== void 0 ? cells.s[neighborCell] : cells.pop && cells.pop[neighborCell] !== void 0 ? cells.pop[neighborCell] : 0;
      const populationCost = cells.h[neighborCell] < 20 ? 0 : suitability ? Math.max(20 - suitability, 0) : 5e3;
      const neighborBiome = cells.biome && cells.biome[neighborCell] !== void 0 ? cells.biome[neighborCell] : 0;
      const biomeCost = getBiomeCost(b, neighborBiome, type, biomesData);
      const neighborFeature = pack.features && cells.f && cells.f[neighborCell] !== void 0 ? pack.features[cells.f[neighborCell]] : null;
      const heightCost = getHeightCost(neighborFeature, cells.h[neighborCell], type);
      const neighborRiver = cells.r && cells.r[neighborCell] !== void 0 ? cells.r[neighborCell] : 0;
      const riverCost = getRiverCost(neighborRiver, neighborCell, type, cells);
      const neighborType = cells.t && cells.t[neighborCell] !== void 0 ? cells.t[neighborCell] : 0;
      const typeCost = getTypeCost(neighborType, type);
      const cellCost = Math.max(cultureCost + populationCost + biomeCost + heightCost + riverCost + typeCost, 0);
      const totalCost = p + 10 + cellCost / states[s].expansionism;
      if (totalCost > growthRate) return;
      if (!cost[neighborCell] || totalCost < cost[neighborCell]) {
        if (cells.h[neighborCell] >= 20) cells.state[neighborCell] = s;
        cost[neighborCell] = totalCost;
        queue.push({ e: neighborCell, p: totalCost, s, b }, totalCost);
      }
    });
  }
  const unclaimedLandCells = [];
  for (const cellId of cells.i) {
    if (cells.h[cellId] >= 20 && (!cells.state[cellId] || cells.state[cellId] === 0)) {
      unclaimedLandCells.push(cellId);
    }
  }
  if (unclaimedLandCells.length > 0) {
    for (const cellId of unclaimedLandCells) {
      let nearestState = 0;
      let nearestDistance = Infinity;
      for (const state2 of states) {
        if (!state2.i || state2.removed || !state2.center) continue;
        const dx = cells.p[cellId][0] - cells.p[state2.center][0];
        const dy = cells.p[cellId][1] - cells.p[state2.center][1];
        const distance = dx * dx + dy * dy;
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestState = state2.i;
        }
      }
      if (nearestState > 0) {
        cells.state[cellId] = nearestState;
      }
    }
    if (typeof console !== "undefined" && console.log) {
      console.log("[expandStates] Claimed unclaimed land cells:", {
        unclaimedCount: unclaimedLandCells.length,
        totalLandCells: cells.i.filter((i) => cells.h[i] >= 20).length
      });
    }
  }
  if (burgs && cells.burg) {
    burgs.forEach((b) => {
      if (b && b.i && !b.removed && b.cell !== void 0) {
        b.state = cells.state[b.cell];
      }
    });
  }
  function getBiomeCost(b, biome, type, biomesData2) {
    if (b === biome) return 10;
    if (type === "Hunting") return biomesData2.cost[biome] * 2;
    if (type === "Nomadic" && biome > 4 && biome < 10) return biomesData2.cost[biome] * 3;
    return biomesData2.cost[biome];
  }
  function getHeightCost(f, h, type) {
    if (type === "Lake" && f && f.type === "lake") return 10;
    if (type === "Naval" && h < 20) return 300;
    if (type === "Nomadic" && h < 20) return 1e4;
    if (h < 20) return 1e3;
    if (type === "Highland" && h < 62) return 1100;
    if (type === "Highland") return 0;
    if (h >= 67) return 2200;
    if (h >= 44) return 300;
    return 0;
  }
  function getRiverCost(r, i, type, cells2) {
    if (type === "River") return r ? 0 : 100;
    if (!r) return 0;
    const flux = cells2.fl && cells2.fl[i] ? cells2.fl[i] : 0;
    return minmax(flux / 10, 20, 100);
  }
  function getTypeCost(t, type) {
    if (t === 1) return type === "Naval" || type === "Lake" ? 0 : type === "Nomadic" ? 60 : 20;
    if (t === 2) return type === "Naval" || type === "Nomadic" ? 30 : 0;
    if (t !== -1) return type === "Naval" || type === "Lake" ? 100 : 0;
    return 0;
  }
}
function normalizeStates({ pack }) {
  if (!pack || !pack.cells || !pack.states || !pack.burgs) {
    throw new Error("Pack object with cells, states, and burgs is required");
  }
  const { cells, burgs, states } = pack;
  for (const i of cells.i) {
    if (cells.h[i] < 20 || cells.burg && cells.burg[i]) continue;
    if (states[cells.state[i]] && states[cells.state[i]].lock) continue;
    if (cells.c[i] && cells.burg && cells.c[i].some((c) => burgs[cells.burg[c]] && burgs[cells.burg[c]].capital)) continue;
    const neighbors = cells.c[i] ? cells.c[i].filter((c) => cells.h[c] >= 20) : [];
    const adversaries = neighbors.filter(
      (c) => {
        var _a;
        return !((_a = states[cells.state[c]]) == null ? void 0 : _a.lock) && cells.state[c] !== cells.state[i];
      }
    );
    if (adversaries.length < 2) continue;
    const buddies = neighbors.filter(
      (c) => {
        var _a;
        return !((_a = states[cells.state[c]]) == null ? void 0 : _a.lock) && cells.state[c] === cells.state[i];
      }
    );
    if (buddies.length > 2) continue;
    if (adversaries.length <= buddies.length) continue;
    cells.state[i] = cells.state[adversaries[0]];
  }
}
function collectStatistics({ pack }) {
  if (!pack || !pack.cells || !pack.states) {
    throw new Error("Pack object with cells and states is required");
  }
  const { cells, states, burgs } = pack;
  states.forEach((s) => {
    if (s.removed) return;
    s.cells = 0;
    s.area = 0;
    s.burgs = 0;
    s.rural = 0;
    s.urban = 0;
    s.neighbors = /* @__PURE__ */ new Set();
  });
  for (const i of cells.i) {
    if (cells.h[i] < 20) continue;
    const s = cells.state[i];
    if (!states[s]) continue;
    if (cells.c[i] && cells.state) {
      cells.c[i].filter((c) => cells.h[c] >= 20 && cells.state[c] !== s).forEach((c) => {
        if (cells.state[c] !== void 0) {
          states[s].neighbors.add(cells.state[c]);
        }
      });
    }
    states[s].cells += 1;
    if (cells.area) states[s].area += cells.area[i];
    if (cells.pop) states[s].rural += cells.pop[i];
    if (cells.burg && cells.burg[i] && burgs[cells.burg[i]]) {
      states[s].urban += burgs[cells.burg[i]].population || 0;
      states[s].burgs++;
    }
  }
  states.forEach((s) => {
    if (s.neighbors) {
      s.neighbors = Array.from(s.neighbors);
    }
  });
}
function assignColors({ pack, rng }) {
  if (!pack || !pack.states) {
    throw new Error("Pack object with states is required");
  }
  const colors2 = [
    "#a8d5ba",
    // Soft teal-green
    "#f4a582",
    // Soft coral
    "#b3cde3",
    // Soft blue
    "#decbe4",
    // Soft purple
    "#ccebc5",
    // Soft mint
    "#fed9a6",
    // Soft peach
    "#ffffcc",
    // Soft yellow
    "#e5d8bd",
    // Soft beige
    "#d9d9d9",
    // Soft gray
    "#bebada",
    // Soft lavender
    "#fb8072",
    // Soft rose
    "#80b1d3",
    // Soft sky blue
    "#fdb462",
    // Soft orange
    "#b3de69",
    // Soft lime
    "#fccde5",
    // Soft pink
    "#bc80bd",
    // Soft mauve
    "#ccebc5",
    // Soft green
    "#ffed6f"
    // Soft gold
  ];
  pack.states.forEach((s) => {
    if (!s.i || s.removed || s.lock) return;
    const neibs = s.neighbors || [];
    s.color = colors2.find((c) => neibs.every((n) => pack.states[n] && pack.states[n].color !== c));
    if (!s.color) s.color = getRandomColor$1(rng);
  });
}
function generateStates({ pack, options, rng }) {
  if (!pack || !pack.cells || !pack.burgs) {
    throw new Error("Pack object with cells and burgs is required");
  }
  if (!rng) {
    throw new Error("RNG instance is required");
  }
  const states = createStates({ pack, options, rng });
  pack.states = states;
  expandStates({ pack, options });
  normalizeStates({ pack });
  collectStatistics({ pack });
  assignColors({ pack, rng });
  return states;
}
let SimplePriorityQueue$1 = class SimplePriorityQueue3 {
  constructor() {
    this.items = [];
  }
  push(item, priority) {
    this.items.push({ item, priority });
    this.items.sort((a, b) => a.priority - b.priority);
  }
  pop() {
    var _a;
    return (_a = this.items.shift()) == null ? void 0 : _a.item;
  }
  get length() {
    return this.items.length;
  }
};
const forms = {
  Monarchy: { County: 22, Earldom: 6, Shire: 2, Landgrave: 2, Margrave: 2, Barony: 2, Captaincy: 1, Seneschalty: 1 },
  Republic: { Province: 6, Department: 2, Governorate: 2, District: 1, Canton: 1, Prefecture: 1 },
  Theocracy: { Parish: 3, Deanery: 1 },
  Union: { Province: 1, State: 1, Canton: 1, Republic: 1, County: 1, Council: 1 },
  Anarchy: { Council: 1, Commune: 1, Community: 1, Tribe: 1 },
  Wild: { Territory: 10, Land: 5, Region: 2, Tribe: 1, Clan: 1, Dependency: 1, Area: 1 }
};
function getWeightedRandom(weights, rng) {
  const array2 = [];
  for (const key in weights) {
    for (let i = 0; i < weights[key]; i++) {
      array2.push(key);
    }
  }
  return rng.pick(array2);
}
function getMixedColor$1(baseColor) {
  return baseColor;
}
function isPassable(from, to, pack) {
  const { cells } = pack;
  if (cells.f[from] !== cells.f[to]) return false;
  const passableQueue = [from];
  const used = new Uint8Array(cells.i.length);
  const state2 = cells.state[from];
  while (passableQueue.length) {
    const current = passableQueue.pop();
    if (current === to) return true;
    if (cells.c[current]) {
      cells.c[current].forEach((c) => {
        if (used[c] || cells.h[c] < 20 || cells.state[c] !== state2) return;
        passableQueue.push(c);
        used[c] = 1;
      });
    }
  }
  return false;
}
function generateProvinces({ pack, options, rng }) {
  if (!pack || !pack.cells || !pack.states || !pack.burgs) {
    throw new Error("Pack object with cells, states, and burgs is required");
  }
  if (!rng) {
    throw new Error("RNG instance is required");
  }
  const { cells, states, burgs } = pack;
  const provinces = [null];
  const provinceIds = createTypedArray({ maxValue: 65535, length: cells.i.length });
  const provincesRatio = options.provincesRatio || 20;
  const max2 = provincesRatio === 100 ? 1e3 : gauss(20, 5, 5, 100, 0, rng) * Math.pow(provincesRatio, 0.5);
  states.forEach((s) => {
    if (!s.i || s.removed) return;
    s.provinces = [];
    const stateBurgs = burgs.filter((b) => b && b.i && !b.removed && b.state === s.i && !provinceIds[b.cell]).sort((a, b) => {
      const popA = (a.population || 0) * gauss(1, 0.2, 0.5, 1.5, 3, rng);
      const popB = (b.population || 0) * gauss(1, 0.2, 0.5, 1.5, 3, rng);
      return popB - popA;
    }).sort((a, b) => (b.capital || 0) - (a.capital || 0));
    if (stateBurgs.length < 2) return;
    const provincesNumber = Math.max(Math.ceil(stateBurgs.length * provincesRatio / 100), 2);
    const form = { ...forms[s.form || "Monarchy"] };
    for (let i = 0; i < provincesNumber && i < stateBurgs.length; i++) {
      const provinceId = provinces.length;
      const burg = stateBurgs[i];
      const center = burg.cell;
      const burgId = burg.i;
      burg.culture || cells.culture ? cells.culture[center] : 0;
      const nameByBurg = rng.probability(0.5);
      const name = nameByBurg ? burg.name || `Burg${burgId}` : `Province${provinceId}`;
      const formName = getWeightedRandom(form, rng);
      form[formName] = (form[formName] || 0) + 10;
      const fullName = `${name} ${formName}`;
      const color2 = getMixedColor$1(s.color);
      provinces.push({
        i: provinceId,
        state: s.i,
        center,
        burg: burgId,
        name,
        formName,
        fullName,
        color: color2,
        coa: null
        // Placeholder for coat of arms
      });
      s.provinces.push(provinceId);
      provinceIds[center] = provinceId;
    }
  });
  const queue = new SimplePriorityQueue$1();
  const cost = [];
  provinces.forEach((p) => {
    if (!p || !p.i || p.removed) return;
    provinceIds[p.center] = p.i;
    queue.push({ e: p.center, province: p.i, state: p.state, p: 0 }, 0);
    cost[p.center] = 1;
  });
  while (queue.length) {
    const { e, p, province, state: state2 } = queue.pop();
    if (!cells.c[e]) continue;
    cells.c[e].forEach((neighborCell) => {
      if (provinceIds[neighborCell]) return;
      const land = cells.h[neighborCell] >= 20;
      if (!land && (!cells.t || !cells.t[neighborCell])) return;
      if (land && (!cells.state || cells.state[neighborCell] !== state2)) return;
      const elevation = cells.h[neighborCell] >= 70 ? 100 : cells.h[neighborCell] >= 50 ? 30 : cells.h[neighborCell] >= 20 ? 10 : 100;
      const totalCost = p + elevation;
      if (totalCost > max2) return;
      if (!cost[neighborCell] || totalCost < cost[neighborCell]) {
        if (land) provinceIds[neighborCell] = province;
        cost[neighborCell] = totalCost;
        queue.push({ e: neighborCell, province, state: state2, p: totalCost }, totalCost);
      }
    });
  }
  for (const i of cells.i) {
    if (cells.burg && cells.burg[i]) continue;
    if (provinceIds[i]) continue;
    const neighbors = cells.c[i] ? cells.c[i].filter((c) => cells.state && cells.state[c] === cells.state[i] && provinceIds[c]) : [];
    const adversaries = neighbors.filter((c) => provinceIds[c] !== provinceIds[i]);
    if (adversaries.length < 2) continue;
    const buddies = neighbors.filter((c) => provinceIds[c] === provinceIds[i]).length;
    if (buddies > 2) continue;
    const competitorCounts = {};
    adversaries.forEach((c) => {
      const prov = provinceIds[c];
      competitorCounts[prov] = (competitorCounts[prov] || 0) + 1;
    });
    const maxCount = Math.max(...Object.values(competitorCounts));
    if (buddies >= maxCount) continue;
    const winnerProv = Object.keys(competitorCounts).find((p) => competitorCounts[p] === maxCount);
    if (winnerProv) provinceIds[i] = Number(winnerProv);
  }
  const noProvince = cells.i.filter((i) => cells.state && cells.state[i] && !provinceIds[i]);
  states.forEach((s) => {
    if (!s.i || s.removed) return;
    if (!s.provinces || s.provinces.length === 0) return;
    let stateNoProvince = noProvince.filter((i) => cells.state && cells.state[i] === s.i && !provinceIds[i]);
    while (stateNoProvince.length > 0) {
      const provinceId = provinces.length;
      const burgCell = stateNoProvince.find((i) => cells.burg && cells.burg[i]);
      const center = burgCell !== void 0 ? burgCell : stateNoProvince[0];
      const burg = burgCell !== void 0 && cells.burg ? cells.burg[burgCell] : 0;
      provinceIds[center] = provinceId;
      const wildCost = [];
      const wildQueue = new SimplePriorityQueue$1();
      wildCost[center] = 1;
      wildQueue.push({ e: center, p: 0 }, 0);
      while (wildQueue.length) {
        const { e, p } = wildQueue.pop();
        if (!cells.c[e]) continue;
        cells.c[e].forEach((nextCellId) => {
          if (provinceIds[nextCellId]) return;
          const land = cells.h[nextCellId] >= 20;
          if (cells.state && cells.state[nextCellId] && cells.state[nextCellId] !== s.i) return;
          const ter = land ? cells.state && cells.state[nextCellId] === s.i ? 3 : 20 : cells.t && cells.t[nextCellId] ? 10 : 30;
          const totalCost = p + ter;
          if (totalCost > max2) return;
          if (!wildCost[nextCellId] || totalCost < wildCost[nextCellId]) {
            if (land && cells.state && cells.state[nextCellId] === s.i) provinceIds[nextCellId] = provinceId;
            wildCost[nextCellId] = totalCost;
            wildQueue.push({ e: nextCellId, p: totalCost }, totalCost);
          }
        });
      }
      cells.culture && cells.culture[center] !== void 0 ? cells.culture[center] : 0;
      const f = pack.features && cells.f && cells.f[center] !== void 0 ? pack.features[cells.f[center]] : null;
      const color2 = getMixedColor$1(s.color);
      const provCells = stateNoProvince.filter((i) => provinceIds[i] === provinceId);
      const singleIsle = f && provCells.length === f.cells && !provCells.find((i) => cells.f && cells.f[i] !== f.i);
      const isleGroup = !singleIsle && !provCells.find((i) => pack.features && cells.f && cells.f[i] !== void 0 && pack.features[cells.f[i]] && pack.features[cells.f[i]].group !== "isle");
      const colony = !singleIsle && !isleGroup && rng.probability(0.5) && s.center !== void 0 && !isPassable(s.center, center, pack);
      const name = (() => {
        if (colony && rng.probability(0.8)) return `New ${s.name}`;
        if (burgCell !== void 0 && rng.probability(0.5) && burgs && burgs[burg]) return burgs[burg].name;
        return `Province${provinceId}`;
      })();
      const formName = (() => {
        if (singleIsle) return "Island";
        if (isleGroup) return "Islands";
        if (colony) return "Colony";
        return getWeightedRandom(forms.Wild, rng);
      })();
      const fullName = `${name} ${formName}`;
      provinces.push({
        i: provinceId,
        state: s.i,
        center,
        burg: burg || 0,
        name,
        formName,
        fullName,
        color: color2,
        coa: null
      });
      s.provinces.push(provinceId);
      stateNoProvince = noProvince.filter((i) => cells.state && cells.state[i] === s.i && !provinceIds[i]);
    }
  });
  cells.province = provinceIds;
  pack.provinces = provinces;
  return provinces;
}
class SimplePriorityQueue4 {
  constructor() {
    this.items = [];
  }
  push(item, priority) {
    this.items.push({ item, priority });
    this.items.sort((a, b) => a.priority - b.priority);
  }
  pop() {
    var _a;
    return (_a = this.items.shift()) == null ? void 0 : _a.item;
  }
  get length() {
    return this.items.length;
  }
}
class SimpleQuadtree2 {
  constructor() {
    this.points = [];
  }
  add(point2) {
    this.points.push(point2);
  }
  find(x2, y2, radius) {
    for (const [px, py] of this.points) {
      const dist = Math.sqrt((x2 - px) ** 2 + (y2 - py) ** 2);
      if (dist < radius) return [px, py];
    }
    return void 0;
  }
}
function getRandomColor(rng) {
  const colors2 = ["#e74c3c", "#3498db", "#2ecc71", "#f39c12", "#9b59b6", "#1abc9c", "#e67e22", "#34495e"];
  return rng.pick(colors2);
}
function getMixedColor(baseColor, lightness = 0.25, saturation = 0.4) {
  return baseColor;
}
function generateFolkReligions(pack) {
  if (!pack.cultures) return [];
  return pack.cultures.filter((c) => c.i && !c.removed).map((culture) => ({
    type: "Folk",
    form: "Animism",
    // Default form
    culture: culture.i,
    center: culture.center
  }));
}
function generateOrganizedReligions({ pack, options, rng }) {
  const { cells, burgs } = pack;
  const religionsNumber = options.religionsNumber || 0;
  if (religionsNumber < 1) return [];
  const candidateCells = getCandidateCells();
  const religionCores = placeReligions();
  const cultsCount = Math.floor(rng.randInt(1, 4) / 10 * religionCores.length);
  const heresiesCount = Math.floor(rng.randInt(0, 3) / 10 * religionCores.length);
  const organizedCount = religionCores.length - cultsCount - heresiesCount;
  const getType = (index) => {
    if (index < organizedCount) return "Organized";
    if (index < organizedCount + cultsCount) return "Cult";
    return "Heresy";
  };
  const forms2 = {
    Organized: ["Monotheism", "Polytheism", "Dualism", "Pantheism"],
    Cult: ["Cult", "Sect", "Order"],
    Heresy: ["Heresy", "Sect", "Schism"]
  };
  return religionCores.map((cellId, index) => {
    const type = getType(index);
    const formOptions = forms2[type] || ["Religion"];
    const form = rng.pick(formOptions);
    const cultureId = cells.culture && cells.culture[cellId] !== void 0 ? cells.culture[cellId] : 0;
    return { type, form, culture: cultureId, center: cellId };
  });
  function placeReligions() {
    const religionCells = [];
    const religionsTree = new SimpleQuadtree2();
    const spacing = (options.mapWidth + options.mapHeight) / 2 / religionsNumber;
    for (const cellId of candidateCells) {
      const [x2, y2] = cells.p[cellId];
      if (!religionsTree.find(x2, y2, spacing)) {
        religionCells.push(cellId);
        religionsTree.add([x2, y2]);
        if (religionCells.length === religionsNumber) return religionCells;
      }
    }
    return religionCells;
  }
  function getCandidateCells() {
    const validBurgs = burgs ? burgs.filter((b) => b && b.i && !b.removed) : [];
    if (validBurgs.length >= religionsNumber) {
      return validBurgs.sort((a, b) => (b.population || 0) - (a.population || 0)).map((burg) => burg.cell);
    }
    const baseScore = cells.s || (cells.pop ? cells.pop : new Float32Array(cells.i.length));
    return cells.i.filter((i) => baseScore[i] > 2).sort((a, b) => baseScore[b] - baseScore[a]);
  }
}
function specifyReligions({ pack, rng, newReligions }) {
  const { cells, cultures } = pack;
  return newReligions.map(({ type, form, culture: cultureId, center }) => {
    const culture = cultures && cultures[cultureId] ? cultures[cultureId] : null;
    const stateId = cells.state && cells.state[center] !== void 0 ? cells.state[center] : 0;
    const name = `${type}${cultureId > 0 ? cultureId : ""}`;
    let expansion = "global";
    if (type === "Folk") {
      expansion = "culture";
    } else if (stateId > 0 && rng.probability(0.5)) {
      expansion = "state";
    }
    let expansionism = 0;
    if (type === "Folk") {
      expansionism = 0;
    } else if (type === "Organized") {
      expansionism = gauss(5, 3, 0, 10, 1, rng);
    } else if (type === "Cult") {
      expansionism = gauss(0.5, 0.5, 0, 5, 1, rng);
    } else if (type === "Heresy") {
      expansionism = gauss(1, 0.5, 0, 5, 1, rng);
    }
    let color2 = getRandomColor(rng);
    if (culture) {
      if (type === "Folk") {
        color2 = culture.color || color2;
      } else if (type === "Heresy") {
        color2 = getMixedColor(culture.color || color2, 0.35, 0.2);
      } else if (type === "Cult") {
        color2 = getMixedColor(culture.color || color2, 0.5, 0);
      } else {
        color2 = getMixedColor(culture.color || color2, 0.25, 0.4);
      }
    }
    return {
      name,
      type,
      form,
      culture: cultureId,
      center,
      deity: null,
      // Placeholder
      expansion,
      expansionism,
      color: color2
    };
  });
}
function expandReligions({ pack, options, religions }) {
  const { cells } = pack;
  const religionIds = createTypedArray({ maxValue: 65535, length: cells.i.length });
  religions.filter((r) => r.type === "Folk").forEach((r) => {
    for (const i of cells.i) {
      if (cells.culture && cells.culture[i] === r.culture) {
        religionIds[i] = r.i;
      }
    }
  });
  const queue = new SimplePriorityQueue4();
  const cost = [];
  const growthRate = options.growthRate || 1;
  const maxExpansionCost = cells.i.length / 20 * growthRate;
  religions.filter((r) => r.i && !r.lock && r.type !== "Folk" && !r.removed).forEach((r) => {
    religionIds[r.center] = r.i;
    const stateId = cells.state && cells.state[r.center] !== void 0 ? cells.state[r.center] : 0;
    queue.push({ e: r.center, p: 0, r: r.i, s: stateId }, 0);
    cost[r.center] = 1;
  });
  const religionsMap = new Map(religions.map((r) => [r.i, r]));
  while (queue.length) {
    const { e, p, r, s: state2 } = queue.pop();
    const { culture, expansion, expansionism } = religionsMap.get(r);
    if (!cells.c[e]) continue;
    cells.c[e].forEach((nextCell) => {
      const religion = religionsMap.get(religionIds[nextCell]);
      if (religion && religion.lock) return;
      if (expansion === "culture" && cells.culture && cells.culture[nextCell] !== culture) return;
      if (expansion === "state" && cells.state && cells.state[nextCell] !== state2) return;
      const cultureCost = cells.culture && cells.culture[nextCell] !== culture ? 10 : 0;
      const stateCost = cells.state && cells.state[nextCell] !== state2 ? 10 : 0;
      const passageCost = getPassageCost(e, nextCell, pack);
      const cellCost = cultureCost + stateCost + passageCost;
      const totalCost = p + 10 + cellCost / expansionism;
      if (totalCost > maxExpansionCost) return;
      if (!cost[nextCell] || totalCost < cost[nextCell]) {
        if (cells.culture && cells.culture[nextCell]) religionIds[nextCell] = r;
        cost[nextCell] = totalCost;
        queue.push({ e: nextCell, p: totalCost, r, s: state2 }, totalCost);
      }
    });
  }
  function getPassageCost(cellId, nextCellId, pack2) {
    const { cells: cells2 } = pack2;
    const h1 = cells2.h[cellId];
    const h2 = cells2.h[nextCellId];
    if (h1 < 20 && h2 < 20) return 5;
    if (h1 < 20 || h2 < 20) return 50;
    if (h2 >= 67) return 30;
    if (h2 >= 44) return 10;
    return 5;
  }
  return religionIds;
}
function generateReligions({ pack, options, rng }) {
  if (!pack || !pack.cells) {
    throw new Error("Pack object with cells is required");
  }
  if (!rng) {
    throw new Error("RNG instance is required");
  }
  const religionsNumber = options.religionsNumber || 0;
  if (religionsNumber === 0) {
    pack.religions = [{ name: "No religion", i: 0 }];
    pack.cells.religion = createTypedArray({ maxValue: 65535, length: pack.cells.i.length });
    return pack.religions;
  }
  const folkReligions = generateFolkReligions(pack);
  const organizedReligions = generateOrganizedReligions({ pack, options, rng });
  const namedReligions = specifyReligions({ pack, rng, newReligions: [...folkReligions, ...organizedReligions] });
  const religions = [{ name: "No religion", i: 0 }];
  namedReligions.forEach((r, i) => {
    religions.push({
      ...r,
      i: i + 1
    });
  });
  const religionIds = expandReligions({ pack, options, religions });
  pack.religions = religions;
  pack.cells.religion = religionIds;
  return religions;
}
const shieldTypes = [
  "heater",
  "round",
  "oval",
  "spanish",
  "french",
  "oldFrench",
  "swiss",
  "wedged",
  "horsehead",
  "banner",
  "square",
  "pavise",
  "roman",
  "boeotian"
];
const colors = {
  metals: ["argent", "or"],
  colours: ["gules", "azure", "sable", "vert", "purpure"]
};
const charges = [
  "lion",
  "eagle",
  "cross",
  "star",
  "crown",
  "sword",
  "shield",
  "tree",
  "sun",
  "moon"
];
function generateEmblem({ parentEmblem = null, kinship = 0.25, dominion = 0, type = "Generic", rng }) {
  if (!rng) {
    throw new Error("RNG instance is required");
  }
  const emblem = {
    shield: parentEmblem && rng.probability(kinship) ? parentEmblem.shield : rng.pick(shieldTypes),
    field: null,
    division: null,
    charge: null,
    chargeColor: null
  };
  if (parentEmblem && rng.probability(kinship)) {
    emblem.field = parentEmblem.field;
  } else {
    const allColors = [...colors.metals, ...colors.colours];
    emblem.field = rng.pick(allColors);
  }
  if (rng.probability(0.3)) {
    const divisions = ["perPale", "perFess", "perBend", "perCross"];
    emblem.division = rng.pick(divisions);
  }
  if (rng.probability(0.7)) {
    if (parentEmblem && rng.probability(kinship)) {
      emblem.charge = parentEmblem.charge;
      emblem.chargeColor = parentEmblem.chargeColor;
    } else {
      emblem.charge = rng.pick(charges);
      const allColors = [...colors.metals, ...colors.colours];
      emblem.chargeColor = rng.pick(allColors);
    }
  }
  return emblem;
}
function generateCultureEmblems({ pack, options, rng }) {
  if (!pack || !pack.cultures) {
    throw new Error("Pack object with cultures is required");
  }
  if (!rng) {
    throw new Error("RNG instance is required");
  }
  pack.cultures.forEach((culture) => {
    if (!culture.i || culture.removed) return;
    if (!culture.emblem) {
      culture.emblem = generateEmblem({
        parentEmblem: null,
        kinship: 0,
        dominion: 0,
        type: culture.type || "Generic",
        rng
      });
    }
  });
}
function generateStateEmblems({ pack, options, rng }) {
  if (!pack || !pack.states) {
    throw new Error("Pack object with states is required");
  }
  if (!rng) {
    throw new Error("RNG instance is required");
  }
  pack.states.forEach((state2) => {
    if (!state2.i || state2.removed) return;
    if (!state2.emblem) {
      const culture = pack.cultures && pack.cultures[state2.culture] ? pack.cultures[state2.culture] : null;
      const parentEmblem = culture && culture.emblem ? culture.emblem : null;
      state2.emblem = generateEmblem({
        parentEmblem,
        kinship: 0.3,
        dominion: state2.capital ? 0.1 : 0,
        type: state2.type || "Generic",
        rng
      });
    }
  });
}
function generateReligionEmblems({ pack, options, rng }) {
  if (!pack || !pack.religions) {
    throw new Error("Pack object with religions is required");
  }
  if (!rng) {
    throw new Error("RNG instance is required");
  }
  pack.religions.forEach((religion) => {
    if (!religion.i || religion.removed) return;
    if (!religion.emblem) {
      const culture = pack.cultures && pack.cultures[religion.culture] ? pack.cultures[religion.culture] : null;
      const parentEmblem = culture && culture.emblem ? culture.emblem : null;
      religion.emblem = generateEmblem({
        parentEmblem,
        kinship: religion.type === "Folk" ? 0.8 : 0.4,
        dominion: religion.type === "Heresy" ? 0.5 : 0.2,
        type: religion.type || "Generic",
        rng
      });
    }
  });
}
function generateEmblems({ pack, options, rng }) {
  if (!pack) {
    throw new Error("Pack object is required");
  }
  if (!rng) {
    throw new Error("RNG instance is required");
  }
  generateCultureEmblems({ pack, options, rng });
  generateStateEmblems({ pack, options, rng });
  generateReligionEmblems({ pack, options, rng });
}
function createPackFromGrid({ grid, options, DelaunatorClass }) {
  var _a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s;
  if (!DelaunatorClass) {
    throw new Error("Delaunator is required as a peer dependency for pack creation");
  }
  const { cells: gridCells, points, features, boundary } = grid;
  const newCells = { p: [], g: [], h: [] };
  const spacing2 = grid.spacing ** 2;
  for (const i of gridCells.i) {
    const height2 = gridCells.h[i];
    const type = gridCells.t[i];
    if (height2 < 20 && type !== -1 && type !== -2) continue;
    if (type === -2 && (i % 4 === 0 || features && features[gridCells.f[i]] && features[gridCells.f[i]].type === "lake")) continue;
    const [x2, y2] = points[i];
    addNewPoint(i, x2, y2, height2);
    if ((type === 1 || type === -1) && !gridCells.b[i]) {
      if (gridCells.c[i]) {
        gridCells.c[i].forEach((e) => {
          if (i > e) return;
          if (gridCells.t[e] === type) {
            const dist22 = (points[i][1] - points[e][1]) ** 2 + (points[i][0] - points[e][0]) ** 2;
            if (dist22 < spacing2) return;
            const x1 = (points[i][0] + points[e][0]) / 2;
            const y1 = (points[i][1] + points[e][1]) / 2;
            addNewPoint(i, x1, y1, height2);
          }
        });
      }
    }
  }
  function addNewPoint(i, x2, y2, height2) {
    newCells.p.push([x2, y2]);
    newCells.g.push(i);
    newCells.h.push(height2);
  }
  const allPoints = newCells.p.concat(boundary);
  const delaunay = DelaunatorClass.from(allPoints);
  const voronoiGraph = new Voronoi$1(delaunay, allPoints, newCells.p.length);
  const packCells = {
    i: createTypedArray({ maxValue: newCells.p.length, length: newCells.p.length }).map((_, i) => i),
    p: newCells.p,
    g: createTypedArray({ maxValue: grid.points.length, length: newCells.g.length }),
    h: createTypedArray({ maxValue: 100, length: newCells.h.length }),
    c: new Array(newCells.p.length),
    // Neighbors (from Voronoi class)
    v: new Array(newCells.p.length),
    // Vertex indices (from Voronoi class - for isoline rendering)
    vCoords: new Array(newCells.p.length),
    // Polygon coordinates (for canvas rendering)
    b: new Uint8Array(newCells.p.length),
    // Border cells
    area: new Float32Array(newCells.p.length)
  };
  for (let i = 0; i < newCells.g.length; i++) {
    packCells.g[i] = newCells.g[i];
    packCells.h[i] = newCells.h[i];
  }
  const delaunayObj = Delaunay.from(allPoints);
  const voronoiDiagram = delaunayObj.voronoi([0, 0, options.mapWidth, options.mapHeight]);
  for (let i = 0; i < newCells.p.length; i++) {
    packCells.v[i] = voronoiGraph.cells.v[i] || [];
    const cellNeighbors = voronoiGraph.cells.c[i];
    if (cellNeighbors && Array.isArray(cellNeighbors)) {
      packCells.c[i] = cellNeighbors.filter((neibIdx) => neibIdx < newCells.p.length);
    } else {
      packCells.c[i] = [];
    }
  }
  let vCoordsPopulated = 0;
  for (let i = 0; i < newCells.p.length; i++) {
    try {
      const cellPolygon = voronoiDiagram.cellPolygon(i);
      if (cellPolygon && cellPolygon.length > 0) {
        const roundedPoly = cellPolygon.map((point2) => {
          if (Array.isArray(point2) && point2.length >= 2) {
            return [Math.round(point2[0]), Math.round(point2[1])];
          }
          return null;
        }).filter((p) => p !== null);
        if (roundedPoly.length > 0) {
          packCells.vCoords[i] = roundedPoly;
          packCells.area[i] = Math.abs(area(roundedPoly));
          vCoordsPopulated++;
        } else {
          packCells.vCoords[i] = [];
          packCells.area[i] = 1;
        }
      } else {
        packCells.vCoords[i] = [];
        packCells.area[i] = 1;
      }
    } catch (error) {
      packCells.vCoords[i] = [];
      packCells.area[i] = 1;
      if (typeof console !== "undefined" && console.warn) {
        console.warn(`[regraph] Cell ${i} failed to render polygon:`, error.message);
      }
    }
  }
  for (let i = 0; i < newCells.p.length; i++) {
    const [x2, y2] = newCells.p[i];
    if (x2 <= 0 || x2 >= options.mapWidth || y2 <= 0 || y2 >= options.mapHeight) {
      packCells.b[i] = 1;
    }
  }
  const vertices = voronoiGraph.vertices;
  if (typeof console !== "undefined" && console.log) {
    console.log("[regraph] Pack cells populated (Voronoi vertices):", {
      totalCells: newCells.p.length,
      verticesCount: vertices.p.length,
      vCoordsPopulated,
      vCoordsPercent: (vCoordsPopulated / newCells.p.length * 100).toFixed(1) + "%",
      sampleVCoords: ((_a = packCells.vCoords[0]) == null ? void 0 : _a.length) || 0,
      sampleV: ((_b = packCells.v[0]) == null ? void 0 : _b.length) || 0,
      sampleVerticesV: ((_c = vertices.v[0]) == null ? void 0 : _c.length) || 0
    });
  }
  if (typeof console !== "undefined" && console.log) {
    console.log("[regraph:lifecycle] Before pack creation:", {
      packCellsHasV: "v" in packCells,
      packCellsHasVCoords: "vCoords" in packCells,
      packCellsVType: typeof packCells.v,
      packCellsVIsArray: Array.isArray(packCells.v),
      packCellsVLength: (_d = packCells.v) == null ? void 0 : _d.length,
      packCellsVCoordsType: typeof packCells.vCoords,
      packCellsVCoordsIsArray: Array.isArray(packCells.vCoords),
      packCellsVCoordsLength: (_e = packCells.vCoords) == null ? void 0 : _e.length,
      packCellsKeys: Object.keys(packCells),
      v0Exists: ((_f = packCells.v) == null ? void 0 : _f[0]) !== void 0,
      vCoords0Exists: ((_g = packCells.vCoords) == null ? void 0 : _g[0]) !== void 0,
      v0Sample: ((_h = packCells.v) == null ? void 0 : _h[0]) ? JSON.stringify(packCells.v[0].slice(0, 3)) : "undefined",
      vCoords0Sample: ((_i = packCells.vCoords) == null ? void 0 : _i[0]) ? JSON.stringify(packCells.vCoords[0].slice(0, 2)) : "undefined"
    });
  }
  const pack = {
    cells: packCells,
    vertices
  };
  if (typeof console !== "undefined" && console.log) {
    console.log("[regraph:lifecycle] After pack creation, before return:", {
      packHasCells: "cells" in pack,
      packCellsHasV: pack.cells && "v" in pack.cells,
      packCellsHasVCoords: pack.cells && "vCoords" in pack.cells,
      packCellsVType: typeof ((_j = pack.cells) == null ? void 0 : _j.v),
      packCellsVIsArray: Array.isArray((_k = pack.cells) == null ? void 0 : _k.v),
      packCellsVLength: (_m = (_l = pack.cells) == null ? void 0 : _l.v) == null ? void 0 : _m.length,
      packCellsVCoordsLength: (_o = (_n = pack.cells) == null ? void 0 : _n.vCoords) == null ? void 0 : _o.length,
      packCellsV0Sample: ((_q = (_p = pack.cells) == null ? void 0 : _p.v) == null ? void 0 : _q[0]) ? JSON.stringify(pack.cells.v[0].slice(0, 3)) : "undefined",
      packCellsVCoords0Sample: ((_s = (_r = pack.cells) == null ? void 0 : _r.vCoords) == null ? void 0 : _s[0]) ? JSON.stringify(pack.cells.vCoords[0].slice(0, 2)) : "undefined"
    });
  }
  return pack;
}
function dist2(p1, p2) {
  const dx = p1[0] - p2[0];
  const dy = p1[1] - p2[1];
  return dx * dx + dy * dy;
}
function mergeNearbyClusters(pack, options = {}) {
  if (!pack || !pack.cells || !pack.features) {
    return 0;
  }
  const { cells, features } = pack;
  const { c: neighbors, h: heights, p: points } = cells;
  const packCellsNumber = cells.i.length;
  const mergeDistance = options.mergeDistance || 6;
  const maxMergeDistance = options.maxMergeDistance || 8;
  options.minClusterSize || 5;
  const maxIterations = options.maxIterations || 10;
  const maxClusterSize = options.maxClusterSize || packCellsNumber * 0.6;
  let totalMergesPerformed = 0;
  let iteration = 0;
  while (iteration < maxIterations) {
    const landFeatures = features.filter((f) => f && f.land === true);
    if (landFeatures.length <= 1) break;
    const sortedFeatures = [...landFeatures].sort((a, b) => a.cells - b.cells);
    let iterationMerges = 0;
    const mergedThisIteration = /* @__PURE__ */ new Set();
    for (let i = 0; i < sortedFeatures.length; i++) {
      const feature1 = sortedFeatures[i];
      if (mergedThisIteration.has(feature1.i)) continue;
      if (feature1.cells >= maxClusterSize) continue;
      let bestMerge = null;
      let bestDistance = Infinity;
      let bestTarget = null;
      for (let j = i + 1; j < sortedFeatures.length; j++) {
        const feature2 = sortedFeatures[j];
        if (mergedThisIteration.has(feature2.i)) continue;
        if (feature2.cells >= maxClusterSize) continue;
        const distance = findMinDistanceBetweenFeatures(feature1, feature2, pack, cells);
        if (distance > 0 && distance <= mergeDistance) {
          const sizeDiff = feature2.cells - feature1.cells;
          const score = distance - sizeDiff * 0.01;
          if (score < bestDistance) {
            bestDistance = score;
            bestMerge = feature2;
            bestTarget = feature1;
          }
        }
      }
      if (bestMerge && bestTarget) {
        const distance = findMinDistanceBetweenFeatures(bestTarget, bestMerge, pack, cells);
        const bridged = bridgeFeatures(bestTarget, bestMerge, pack, cells, distance, maxMergeDistance);
        if (bridged) {
          iterationMerges++;
          totalMergesPerformed++;
          mergedThisIteration.add(bestTarget.i);
        }
      }
    }
    if (iterationMerges === 0) break;
    iteration++;
  }
  return totalMergesPerformed;
}
function findMinDistanceBetweenFeatures(feature1, feature2, pack, cells) {
  var _a;
  const { c: neighbors, h: heights } = cells;
  const packCellsNumber = cells.i.length;
  const feature1Cells = [];
  for (let i = 0; i < packCellsNumber; i++) {
    if (pack.cells.f[i] === feature1.i) feature1Cells.push(i);
    if (pack.cells.f[i] === feature2.i) ;
  }
  const queue = [];
  const visited = new Uint8Array(packCellsNumber);
  const distances = new Uint16Array(packCellsNumber);
  distances.fill(65535);
  for (const cellId of feature1Cells) {
    if (heights[cellId] >= 20) {
      const hasWaterNeighbor = (_a = neighbors[cellId]) == null ? void 0 : _a.some(
        (neibId) => neibId >= 0 && neibId < packCellsNumber && heights[neibId] < 20
      );
      if (hasWaterNeighbor) {
        queue.push(cellId);
        visited[cellId] = 1;
        distances[cellId] = 0;
      }
    }
  }
  let minDistance = -1;
  while (queue.length > 0) {
    const current = queue.shift();
    const currentDist = distances[current];
    if (pack.cells.f[current] === feature2.i && heights[current] >= 20) {
      minDistance = currentDist;
      break;
    }
    if (!neighbors[current]) continue;
    for (const neighborId of neighbors[current]) {
      if (neighborId < 0 || neighborId >= packCellsNumber) continue;
      if (visited[neighborId]) continue;
      const isWater2 = heights[neighborId] < 20;
      const isFeature2Land = pack.cells.f[neighborId] === feature2.i && heights[neighborId] >= 20;
      if (isWater2 || isFeature2Land) {
        visited[neighborId] = 1;
        distances[neighborId] = currentDist + 1;
        queue.push(neighborId);
      }
    }
  }
  return minDistance;
}
function bridgeFeatures(feature1, feature2, pack, cells, distance, maxDistance) {
  var _a, _b;
  if (distance > maxDistance) return false;
  const { c: neighbors, h: heights, p: points } = cells;
  const packCellsNumber = cells.i.length;
  const feature1Coast = [];
  const feature2Coast = [];
  for (let i = 0; i < packCellsNumber; i++) {
    if (pack.cells.f[i] === feature1.i && heights[i] >= 20) {
      const hasWaterNeighbor = (_a = neighbors[i]) == null ? void 0 : _a.some(
        (neibId) => neibId >= 0 && neibId < packCellsNumber && heights[neibId] < 20
      );
      if (hasWaterNeighbor) feature1Coast.push(i);
    }
    if (pack.cells.f[i] === feature2.i && heights[i] >= 20) {
      const hasWaterNeighbor = (_b = neighbors[i]) == null ? void 0 : _b.some(
        (neibId) => neibId >= 0 && neibId < packCellsNumber && heights[neibId] < 20
      );
      if (hasWaterNeighbor) feature2Coast.push(i);
    }
  }
  if (feature1Coast.length === 0 || feature2Coast.length === 0) return false;
  let minDist2 = Infinity;
  let closestPair = null;
  for (const c1 of feature1Coast) {
    for (const c2 of feature2Coast) {
      const d2 = dist2(points[c1], points[c2]);
      if (d2 < minDist2) {
        minDist2 = d2;
        closestPair = [c1, c2];
      }
    }
  }
  if (!closestPair) return false;
  const path = findPathThroughWater(closestPair[0], closestPair[1], pack, cells, maxDistance);
  if (!path || path.length === 0) return false;
  let raised = 0;
  if (path.length === 0) return false;
  const startHeight = heights[closestPair[0]];
  const endHeight = heights[closestPair[1]];
  const avgEndpointHeight = (startHeight + endHeight) / 2;
  const targetHeight = Math.max(20, Math.min(avgEndpointHeight, 30));
  for (let idx = 0; idx < path.length; idx++) {
    const cellId = path[idx];
    if (cellId < 0 || cellId >= packCellsNumber) continue;
    const currentHeight = heights[cellId];
    if (currentHeight < 20 && currentHeight >= 10) {
      const progress = idx / Math.max(path.length - 1, 1);
      const gradient = 1 - Math.abs(progress - 0.5) * 2;
      const heightValue = 20 + (targetHeight - 20) * gradient;
      heights[cellId] = Math.max(20, Math.min(heightValue, 35));
      raised++;
    }
  }
  return raised > 0;
}
function findPathThroughWater(startCell, endCell, pack, cells, maxDistance) {
  const { c: neighbors, h: heights, p: points } = cells;
  const packCellsNumber = cells.i.length;
  const queue = [[startCell, [startCell]]];
  const visited = new Uint8Array(packCellsNumber);
  visited[startCell] = 1;
  while (queue.length > 0) {
    const [current, path] = queue.shift();
    if (path.length > maxDistance + 2) continue;
    if (current === endCell) {
      return path;
    }
    if (!neighbors[current]) continue;
    for (const neighborId of neighbors[current]) {
      if (neighborId < 0 || neighborId >= packCellsNumber) continue;
      if (visited[neighborId]) continue;
      const isWater2 = heights[neighborId] < 20;
      const isTarget = neighborId === endCell;
      if (isWater2 || isTarget) {
        visited[neighborId] = 1;
        queue.push([neighborId, [...path, neighborId]]);
      }
    }
  }
  return null;
}
function getCellPolygonPath(cellIndex, pack) {
  if (!pack || !pack.cells) {
    return null;
  }
  if (pack.cells.vCoords && pack.cells.vCoords[cellIndex]) {
    const coords = pack.cells.vCoords[cellIndex];
    if (Array.isArray(coords) && coords.length > 0) {
      return coords;
    }
  }
  if (pack.cells.v && pack.cells.v[cellIndex] && pack.vertices && pack.vertices.p) {
    const vertexIndices = pack.cells.v[cellIndex];
    if (Array.isArray(vertexIndices) && vertexIndices.length > 0) {
      if (Array.isArray(vertexIndices[0]) && vertexIndices[0].length === 2) {
        return vertexIndices;
      }
      return vertexIndices.map((vId) => pack.vertices.p[vId]).filter((p) => p !== void 0);
    }
  }
  return null;
}
function pointInPolygon(point2, polygon) {
  if (!polygon || polygon.length < 3) return false;
  const [x2, y2] = point2;
  let inside = false;
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const [xi, yi] = polygon[i];
    const [xj, yj] = polygon[j];
    const intersect = yi > y2 !== yj > y2 && x2 < (xj - xi) * (y2 - yi) / (yj - yi) + xi;
    if (intersect) inside = !inside;
  }
  return inside;
}
function clipPoly(points, width2, height2, secure = 0) {
  if (points.length < 2) return points;
  if (points.some((point2) => point2 === void 0 || !Array.isArray(point2) || point2.length < 2)) {
    console.error("Invalid point in clipPoly", points);
    return points;
  }
  const bbox = [0, 0, width2, height2];
  let clipped = points;
  for (let edge = 1; edge <= 8; edge *= 2) {
    const result = [];
    if (clipped.length === 0) break;
    let prevInside = !(bitCode(clipped[clipped.length - 1], bbox) & edge);
    for (let i = 0; i < clipped.length; i++) {
      const current = clipped[i];
      const currentInside = !(bitCode(current, bbox) & edge);
      if (currentInside !== prevInside) {
        const intersection = intersectEdge(clipped[i - 1] || clipped[clipped.length - 1], current, edge, bbox);
        if (intersection) {
          result.push(intersection);
          if (secure && currentInside !== prevInside) {
            result.push(intersection);
            if (secure > 1) result.push(intersection);
          }
        }
      }
      if (currentInside) {
        result.push(current);
      }
      prevInside = currentInside;
    }
    clipped = result;
    if (clipped.length === 0) break;
  }
  return clipped.length > 0 ? clipped : points;
}
function bitCode(point2, bbox) {
  let code = 0;
  const [x2, y2] = point2;
  const [x0, y0, x1, y1] = bbox;
  if (x2 < x0) code |= 1;
  else if (x2 > x1) code |= 2;
  if (y2 < y0) code |= 4;
  else if (y2 > y1) code |= 8;
  return code;
}
function intersectEdge(p1, p2, edge, bbox) {
  const [x1, y1] = p1;
  const [x2, y2] = p2;
  const [x0, y0, x1_bound, y1_bound] = bbox;
  if (edge & 8) {
    return [x1 + (x2 - x1) * (y1_bound - y1) / (y2 - y1), y1_bound];
  } else if (edge & 4) {
    return [x1 + (x2 - x1) * (y0 - y1) / (y2 - y1), y0];
  } else if (edge & 2) {
    return [x1_bound, y1 + (y2 - y1) * (x1_bound - x1) / (x2 - x1)];
  } else if (edge & 1) {
    return [x0, y1 + (y2 - y1) * (x0 - x1) / (x2 - x1)];
  }
  return null;
}
function* poissonDiscSampler(x0, y0, x1, y1, r, k = 3) {
  if (!(x1 >= x0) || !(y1 >= y0) || !(r > 0)) throw new Error("Invalid bounds");
  const width2 = x1 - x0;
  const height2 = y1 - y0;
  const r2 = r * r;
  const r2_3 = 3 * r2;
  const cellSize = r * Math.SQRT1_2;
  const gridWidth = Math.ceil(width2 / cellSize);
  const gridHeight = Math.ceil(height2 / cellSize);
  const grid = new Array(gridWidth * gridHeight);
  const queue = [];
  function far(x2, y2) {
    const i = x2 / cellSize | 0;
    const j = y2 / cellSize | 0;
    const i0 = Math.max(i - 2, 0);
    const j0 = Math.max(j - 2, 0);
    const i1 = Math.min(i + 3, gridWidth);
    const j1 = Math.min(j + 3, gridHeight);
    for (let j2 = j0; j2 < j1; ++j2) {
      const o = j2 * gridWidth;
      for (let i2 = i0; i2 < i1; ++i2) {
        const s = grid[o + i2];
        if (s) {
          const dx = s[0] - x2;
          const dy = s[1] - y2;
          if (dx * dx + dy * dy < r2) return false;
        }
      }
    }
    return true;
  }
  function sample(x2, y2) {
    queue.push(grid[gridWidth * (y2 / cellSize | 0) + (x2 / cellSize | 0)] = [x2, y2]);
    return [x2 + x0, y2 + y0];
  }
  yield sample(width2 / 2, height2 / 2);
  pick: while (queue.length) {
    const i = Math.random() * queue.length | 0;
    const parent = queue[i];
    for (let j = 0; j < k; ++j) {
      const a = 2 * Math.PI * Math.random();
      const r4 = Math.sqrt(Math.random() * r2_3 + r2);
      const x2 = parent[0] + r4 * Math.cos(a);
      const y2 = parent[1] + r4 * Math.sin(a);
      if (0 <= x2 && x2 < width2 && 0 <= y2 && y2 < height2 && far(x2, y2)) {
        yield sample(x2, y2);
        continue pick;
      }
    }
    const r3 = queue.pop();
    if (i < queue.length) queue[i] = r3;
  }
}
function getIcon(type, set2 = "simple") {
  if (set2 === "simple") {
    const simpleMap = {
      mountSnow: "mount",
      vulcan: "mount",
      coniferSnow: "conifer",
      cactus: "dune",
      deadTree: "dune"
    };
    const simpleType = simpleMap[type] || type;
    return `#relief-${simpleType}-1`;
  }
  return `#relief-${type}-1`;
}
function getBiomeIcon(cellIndex, iconTypes, grid, pack) {
  if (!iconTypes || iconTypes.length === 0) return null;
  let type = iconTypes[Math.floor(Math.random() * iconTypes.length)];
  if (grid && pack && pack.cells && pack.cells.g) {
    const gridIndex = pack.cells.g[cellIndex];
    if (gridIndex !== void 0 && grid.cells && grid.cells.temp) {
      const temp = grid.cells.temp[gridIndex];
      if (type === "conifer" && temp < 0) type = "coniferSnow";
    }
  }
  return getIcon(type);
}
function getReliefIcon(cellIndex, height2, grid, pack, mod) {
  let type;
  let size;
  let temp = 0;
  if (grid && pack && pack.cells && pack.cells.g) {
    const gridIndex = pack.cells.g[cellIndex];
    if (gridIndex !== void 0 && grid.cells && grid.cells.temp) {
      temp = grid.cells.temp[gridIndex];
    }
  }
  if (height2 > 70 && temp < 0) {
    type = "mountSnow";
  } else if (height2 > 70) {
    type = "mount";
  } else {
    type = "hill";
  }
  size = height2 > 70 ? (height2 - 45) * mod : minmax((height2 - 40) * mod, 3, 6);
  return [getIcon(type), size];
}
function getReliefIconDefs() {
  return `
<defs>
  <g id="defs-relief">
    <symbol id="relief-mount-1" viewBox="0 0 100 100">
      <path d="m3,69 16,-12 31,-32 15,20 30,24" fill="#fff" stroke="#5c5c70" stroke-width="1" />
      <path d="m3,69 16,-12 31,-32 -14,44" fill="#999999" />
      <path d="m3,71 h92 m-83,3 h83" stroke="#5c5c70" stroke-dasharray="7, 11" stroke-width="1" />
    </symbol>
    <symbol id="relief-hill-1" viewBox="0 0 100 100">
      <path d="m20,55 q30,-28 60,0" fill="#999999" stroke="#5c5c70" />
      <path d="m38,55 q13,-24 40,0" fill="#fff" />
      <path d="m20,58 h70 m-62,3 h50" stroke="#5c5c70" stroke-dasharray="7, 11" stroke-width="1" />
    </symbol>
    <symbol id="relief-deciduous-1" viewBox="0 0 100 100">
      <path d="m49.5,52 v7 h1 v-7 h-0.5 q13,-7 0,-16 q-13,9 0,16" fill="#fff" stroke="#5c5c70" />
      <path d="M 50,51.5 C 44,49 40,43 50,36.5" fill="#999999" />
    </symbol>
    <symbol id="relief-conifer-1" viewBox="0 0 100 100">
      <path d="m49.5,55 v4 h1 v-4 l4.5,0 -4,-8 l3.5,0 -4.5,-9 -4,9 3,0 -3.5,8 7,0" fill="#fff" stroke="#5c5c70" />
      <path d="m 46,54.5 3.5,-8 H 46.6 L 50,39 v 15.5 z" fill="#999999" />
    </symbol>
    <symbol id="relief-acacia-1" viewBox="0 0 100 100">
      <path d="m34.5 44.5 c 1.8, -3 8.1, -5.7 12.6, -5.4 6, -2.2 9.3, -0.9 11.9, 1.3 1.7, 0.2 3.2,-0.3 5.2, 2.2 2.7, 1.2 3.7, 2.4 2.7, 3.7 -1.6, 0.3 -2.2, 0 -4.7, -1.6 -5.2, 0.1 -7, 0.7 -8.7, -0.9 -2.8, 1 -3.6, 0 -9.7, 0.2 -4.6, 0 -8, 1.6 -9.3, 0.4 z" fill="#fff" />
      <path d="m52 38 c-2.3 -0.1 -4.3 1.1 -4.9 1.1 -2.2 -0.2 -5 0.2 -6.4 1 -1.3 0.7 -2.8 1.6 -3.7 2.1 -1 0.6 -3.4 1.8 -2.2 2.7 1.1 0.9 3.1 -0.2 4.2 0.3 1.4 0.8 2.9 1 4.5 0.9 1.1 -0.1 2.2 -0.4 2.4 1 0.3 1.9 1.1 3.5 2.1 5.1 0.8 2.4 1 2.8 1 6.8 l2 0 c 0 -1.1 -0.1 -4 1.2 -5.7 1.1 -1.4 1.4 -3.4 3 -4.4 0.9 -1.4 2 -2.6 3.8 -2.7 1.7 -0.3 3.8 0.8 5.1 0.3 0.9 -0.1 3.2 1 3.5 -1 0.1 -2 -2.2 -2.1 -3.2 -3.3 -1.1 -1.5 -3.3 -1.9 -4.9 -1.8 -1 -0.5 -2 -2.5 -7.3 -2.5 z" fill="#5c5c70" />
      <path d="m47 42.33 c2 0.1 4.1 0.5 6.1 -0.3 1.4 -0.3 2.6 0.8 3.6 1.6 0.7 0.4 2.5 0.7 2.7 1.2 -2.2 -0.1 -3.6 0.4 -4.8 -0.4 -1 -0.7 -2.2 -0.3 -3 -0.2 -0.9 0.1 -3 -0.4 -5.5 -0.2 -2.6 0.2 -5.1 -0.1 -7.2 0.5 -3.6 0.6 -3.7 0 -3.7 0 2.2 -2 9.1 -1.7 11.9 -2.2 z" fill="#999999" />
    </symbol>
    <symbol id="relief-palm-1" viewBox="0 0 100 100">
      <path d="m 48.1,55.5 2.1,0 c 0,0 1.3,-5.5 1.2,-8.6 0,-3.2 -1.1,-5.5 -1.1,-5.5 l -0.5,-0.4 -0.2,0.1 c 0,0 0.9,2.7 0.5,6.2 -0.5,3.8 -2.1,8.2 -2.1,8.2 z" fill="#5c5c70" />
      <path d="m 54.9,48.8 c 0,0 1.9,-2.5 0.3,-5.4 -1.4,-2.6 -4.3,-3.2 -4.3,-3.2 0,0 1.6,-0.6 3.3,-0.3 1.7,0.3 4.1,2.5 4.1,2.5 0,0 -0.6,-3.6 -3.6,-4.4 -2.2,-0.6 -4.2,1.3 -4.2,1.3 0,0 0.3,-1.5 -0.2,-2.9 -0.6,-1.4 -2.6,-1.9 -2.6,-1.9 0,0 0.8,1.1 1.2,2.2 0.3,0.9 0.3,2 0.3,2 0,0 -1.3,-1.8 -3.7,-1.5 -2.5,0.2 -3.7,2.5 -3.7,2.5 0,0 2.3,-0.6 3.4,-0.6 1.1,0.1 2.6,0.8 2.6,0.8 l -0.4,0.2 c 0,0 -1.2,-0.4 -2.7,0.4 -1.9,1.1 -2.9,3.7 -2.9,3.7 0,0 1.4,-1.4 2.3,-1.9 0.5,-0.3 1.8,-0.7 1.8,-0.7 0,0 -0.7,1.3 -0.9,3.1 -0.1,2.5 1.1,4.6 1.1,4.6 0,0 0.1,-3.4 1.2,-5.6 1,-1.9 2.3,-2.6 2.3,-2.6 l 0.4,-0.2 c 0,0 1.5,0.7 2.8,2.8 1,1.7 2.3,5 2.3,5 z" fill="#fff" stroke="#5c5c70" stroke-width=".6" />
      <path d="m 47.75,34.61 c 0,0 0.97,1.22 1.22,2.31 0.2,0.89 0.35,2.81 0.35,2.81 0,0 -1.59,-1.5 -3.2,-1.61 -1.82,-0.13 -3.97,1.31 -3.97,1.31 0,0 2.11,-0.49 3.34,-0.47 1.51,0.03 3.33,1.21 3.33,1.21 0,0 -1.7,0.83 -2.57,2.8 -0.88,1.97 -0.34,6.01 -0.34,6.01 0,0 0.04,-2.95 0.94,-4.96 0.8,-1.78 2.11,-2.67 2.44,-2.85 0.66,-0.34 0.49,-1.09 0.49,-1.09 0,0 -0.1,-2.18 -0.52,-3.37 -0.42,-1.21 -1.51,-2.11 -1.51,-2.11 z" fill="#999" />
      <path d="m 42,43.7 c 0,0 1.2,-1.1 1.8,-1.5 0.7,-0.4 2,-0.8 2,-0.8 L 46.5,40.5 c 0,0 -0.8,0 -2.3,0.8 -1.3,0.8 -2.2,2.3 -2.2,2.3 z" fill="#999" />
    </symbol>
    <symbol id="relief-grass-1" viewBox="0 0 100 100">
      <path d="m 49.5,53.1 c 0,-3.4 -2.4,-4.8 -3,-5.4 1,1.8 2.4,3.7 1.8,5.4 z M 51,53.2 C 51.4,49.6 49.6,47.9 48,46.8 c 1.1,1.8 2.8,4.6 1.8,6.5 z M 51.4,51.4 c 0.6,-1.9 1.8,-3.4 3,-4.3 -0.8,0.3 -2.9,1.5 -3.4,2.8 0.2,0.4 0.3,0.8 0.4,1.5 z M 52.9,53.2 c -0.7,-1.9 0.5,-3.3 1.5,-4.4 -1.7,1 -3,2.2 -2.7,4.4 z" fill="#5c5c70" stroke="none" />
    </symbol>
    <symbol id="relief-swamp-1" viewBox="0 0 100 100">
      <path d="m 50,46 v 6 m 0,0 3,-4 m -3,4 -3,-4 m -6,4.5 h 3 m 4,0 h 4 m 4,0 3,0" fill="none" stroke="#5c5c70" stroke-linecap="round" />
    </symbol>
    <symbol id="relief-dune-1" viewBox="0 0 100 100">
      <path d="m 28.7,52.8 c 5,-3.9 10,-8.2 15.8,-8.3 4.5,0 10.8,3.8 15.2,6.5 3.5,2.2 6.8,2 6.8,2" fill="none" stroke="#5c5c70" stroke-width="1.8" />
      <path d="m 44.2,47.6 c -3.2,3.2 3.5,5.7 5.9,7.8" fill="none" stroke="#5c5c70" />
    </symbol>
  </g>
</defs>`;
}
function drawReliefIconsSVG(pack, biomesData, grid = null, options = {}) {
  var _a, _b, _c, _d;
  if (!pack.cells || !pack.cells.h || !pack.cells.biome) return "";
  const renderConfig2 = options.renderConfig || {};
  const reliefConfig = ((_a = renderConfig2.layers) == null ? void 0 : _a.relief) || {};
  const baseDensity = options.density || 0.3;
  const densityMultiplier = reliefConfig.density || 1;
  const density = baseDensity * densityMultiplier;
  const size = 2 * (options.size || 1);
  if (typeof console !== "undefined" && console.log) {
    console.log("[drawReliefIconsSVG] Config values:", {
      baseDensity,
      densityMultiplier,
      finalDensity: density,
      size,
      heightScaling: reliefConfig.heightScaling,
      pseudo3DEnabled: (_c = (_b = renderConfig2.effects) == null ? void 0 : _b.pseudo3D) == null ? void 0 : _c.enabled
    });
  }
  const mod = 0.2 * size;
  const heightScaling = reliefConfig.heightScaling !== false;
  const relief = [];
  const cells = pack.cells;
  const rn2 = (n, d = 0) => Math.round(n * Math.pow(10, d)) / Math.pow(10, d);
  for (const i of cells.i) {
    const polygon = getCellPolygonPath(i, pack);
    if (!polygon || polygon.length < 3) continue;
    const xs = polygon.map((p) => p[0]);
    const ys = polygon.map((p) => p[1]);
    (Math.max(...xs) - Math.min(...xs)) * (Math.max(...ys) - Math.min(...ys));
  }
  const highDensityBiomes = /* @__PURE__ */ new Set([5, 6, 7, 8, 9, 12]);
  for (const i of cells.i) {
    const height2 = cells.h[i];
    if (height2 < 20) continue;
    if (cells.r && cells.r[i]) continue;
    const biome = cells.biome[i];
    const polygon = getCellPolygonPath(i, pack);
    if (!polygon || polygon.length < 3) continue;
    const xs = polygon.map((p) => p[0]);
    const ys = polygon.map((p) => p[1]);
    const minX = Math.min(...xs);
    const maxX = Math.max(...xs);
    const minY = Math.min(...ys);
    const maxY = Math.max(...ys);
    if (height2 < 50) {
      if (!highDensityBiomes.has(biome)) continue;
      if (biomesData.iconsDensity[biome] === 0) continue;
      const iconsDensity = biomesData.iconsDensity[biome] / 100;
      const radius = 2 / iconsDensity / density;
      if (Math.random() > iconsDensity * 10) continue;
      const iconTypes = biomesData.icons[biome] || [];
      if (iconTypes.length === 0) continue;
      for (const [cx, cy] of poissonDiscSampler(minX, minY, maxX, maxY, radius)) {
        if (!pointInPolygon([cx, cy], polygon)) continue;
        let h = (4 + Math.random()) * size;
        const icon = getBiomeIcon(i, iconTypes, grid, pack);
        if (!icon) continue;
        if (icon === "#relief-grass-1") h *= 1.2;
        relief.push({ i: icon, x: rn2(cx - h, 2), y: rn2(cy - h, 2), s: rn2(h * 2, 2) });
      }
    } else {
      const radius = 2 / density;
      const [icon, h] = getReliefIcon(i, height2, grid, pack, mod);
      let iconSize = h * 2;
      if (heightScaling) {
        const heightFactor = (height2 - 50) / 50;
        iconSize = h * 2 * (1 + heightFactor * 0.5);
      }
      for (const [cx, cy] of poissonDiscSampler(minX, minY, maxX, maxY, radius)) {
        if (!pointInPolygon([cx, cy], polygon)) continue;
        relief.push({ i: icon, x: rn2(cx - h, 2), y: rn2(cy - h, 2), s: rn2(iconSize, 2) });
      }
    }
  }
  relief.sort((a, b) => a.y + a.s - (b.y + b.s));
  const pseudo3D = ((_d = renderConfig2.effects) == null ? void 0 : _d.pseudo3D) || {};
  const pseudo3DEnabled = pseudo3D.enabled !== false;
  const reliefHTML = relief.map((r) => {
    const iconType = r.i.includes("mountain") ? "relief-mountain" : r.i.includes("hill") ? "relief-hill" : "relief-icon";
    if (pseudo3DEnabled) {
      const iconElement = `<use href="${r.i}" x="${r.x}" y="${r.y}" width="${r.s}" height="${r.s}" class="${iconType}" filter="url(#dropShadow)"/>`;
      return iconElement;
    }
    return `<use href="${r.i}" x="${r.x}" y="${r.y}" width="${r.s}" height="${r.s}" class="${iconType}"/>`;
  });
  if (typeof console !== "undefined" && console.log && reliefHTML.length > 0) {
    console.log(`[drawReliefIconsSVG] Generated ${reliefHTML.length} relief icons${pseudo3DEnabled ? " with pseudo-3D shadows" : ""}`);
  }
  return reliefHTML.join("");
}
function getSVGDefs() {
  return `<defs>
        <g id="filters">
          <filter id="blurFilter" name="Blur 0.2" x="-1" y="-1" width="100" height="100">
            <feGaussianBlur in="SourceGraphic" stdDeviation="0.2" />
          </filter>
          <filter id="blur1" name="Blur 1" x="-1" y="-1" width="100" height="100">
            <feGaussianBlur in="SourceGraphic" stdDeviation="1" />
          </filter>
          <filter id="blur3" name="Blur 3" x="-1" y="-1" width="100" height="100">
            <feGaussianBlur in="SourceGraphic" stdDeviation="3" />
          </filter>
          <filter id="blur5" name="Blur 5" x="-1" y="-1" width="100" height="100">
            <feGaussianBlur in="SourceGraphic" stdDeviation="5" />
          </filter>
          <filter id="blur7" name="Blur 7" x="-1" y="-1" width="100" height="100">
            <feGaussianBlur in="SourceGraphic" stdDeviation="7" />
          </filter>
          <filter id="blur10" name="Blur 10" x="-1" y="-1" width="100" height="100">
            <feGaussianBlur in="SourceGraphic" stdDeviation="10" />
          </filter>
          <filter id="splotch" name="Splotch">
            <feTurbulence type="fractalNoise" baseFrequency=".01" numOctaves="4" />
            <feColorMatrix values="0 0 0 0 0, 0 0 0 0 0, 0 0 0 0 0, 0 0 0 -0.9 1.2" result="texture" />
            <feComposite in="SourceGraphic" in2="texture" operator="in" />
          </filter>
          <filter id="bluredSplotch" name="Blurred Splotch">
            <feTurbulence type="fractalNoise" baseFrequency=".01" numOctaves="4" />
            <feColorMatrix values="0 0 0 0 0, 0 0 0 0 0, 0 0 0 0 0, 0 0 0 -0.9 1.2" result="texture" />
            <feComposite in="SourceGraphic" in2="texture" operator="in" />
            <feGaussianBlur stdDeviation="4" />
          </filter>
          <filter id="dropShadow" name="Shadow 2">
            <feGaussianBlur in="SourceAlpha" stdDeviation="2" />
            <feOffset dx="1" dy="2" />
            <feMerge>
              <feMergeNode />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
          <filter id="dropShadow01" name="Shadow 0.1">
            <feGaussianBlur in="SourceAlpha" stdDeviation=".1" />
            <feOffset dx=".2" dy=".3" />
            <feMerge>
              <feMergeNode />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
          <filter id="dropShadow05" name="Shadow 0.5">
            <feGaussianBlur in="SourceAlpha" stdDeviation=".5" />
            <feOffset dx=".5" dy=".7" />
            <feMerge>
              <feMergeNode />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
          <filter id="outline" name="Outline">
            <feGaussianBlur in="SourceAlpha" stdDeviation="1" />
            <feMerge>
              <feMergeNode />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
          <filter id="pencil" name="Pencil">
            <feTurbulence baseFrequency="0.03" numOctaves="6" type="fractalNoise" />
            <feDisplacementMap scale="3" in="SourceGraphic" xChannelSelector="R" yChannelSelector="G" />
          </filter>
          <filter id="turbulence" name="Turbulence">
            <feTurbulence baseFrequency="0.1" numOctaves="3" type="fractalNoise" />
            <feDisplacementMap scale="10" in="SourceGraphic" xChannelSelector="R" yChannelSelector="G" />
          </filter>

          <filter
            id="paper"
            name="Paper"
            x="-20%"
            y="-20%"
            width="140%"
            height="140%"
            filterUnits="objectBoundingBox"
            primitiveUnits="userSpaceOnUse"
            color-interpolation-filters="sRGB"
          >
            <feGaussianBlur
              stdDeviation="1 1"
              x="0%"
              y="0%"
              width="100%"
              height="100%"
              in="SourceGraphic"
              edgeMode="none"
              result="blur"
            />
            <feTurbulence
              type="fractalNoise"
              baseFrequency="0.05 0.05"
              numOctaves="4"
              seed="1"
              stitchTiles="stitch"
              result="turbulence"
            />
            <feDiffuseLighting
              surfaceScale="2"
              diffuseConstant="1"
              lighting-color="#707070"
              in="turbulence"
              result="diffuseLighting"
            >
              <feDistantLight azimuth="45" elevation="20" />
            </feDiffuseLighting>
            <feComposite in="diffuseLighting" in2="blur" operator="lighter" result="composite" />
            <feComposite
              in="composite"
              in2="SourceGraphic"
              operator="in"
              x="0%"
              y="0%"
              width="100%"
              height="100%"
              result="composite1"
            />
          </filter>

          <filter
            id="crumpled"
            name="Crumpled"
            x="-20%"
            y="-20%"
            width="140%"
            height="140%"
            filterUnits="objectBoundingBox"
            primitiveUnits="userSpaceOnUse"
            color-interpolation-filters="sRGB"
          >
            <feGaussianBlur
              stdDeviation="2 2"
              x="0%"
              y="0%"
              width="100%"
              height="100%"
              in="SourceGraphic"
              edgeMode="none"
              result="blur"
            />
            <feTurbulence
              type="turbulence"
              baseFrequency="0.05 0.05"
              numOctaves="4"
              seed="1"
              stitchTiles="stitch"
              result="turbulence"
            />
            <feDiffuseLighting
              surfaceScale="2"
              diffuseConstant="1"
              lighting-color="#828282"
              in="turbulence"
              result="diffuseLighting"
            >
              <feDistantLight azimuth="320" elevation="10" />
            </feDiffuseLighting>
            <feComposite in="diffuseLighting" in2="blur" operator="lighter" result="composite" />
            <feComposite
              in="composite"
              in2="SourceGraphic"
              operator="in"
              x="0%"
              y="0%"
              width="100%"
              height="100%"
              result="composite1"
            />
          </filter>

          <filter id="filter-grayscale" name="Grayscale">
            <feColorMatrix
              values="0.3333 0.3333 0.3333 0 0 0.3333 0.3333 0.3333 0 0 0.3333 0.3333 0.3333 0 0 0 0 0 1 0"
            />
          </filter>
          <filter id="filter-sepia" name="Sepia">
            <feColorMatrix values="0.393 0.769 0.189 0 0 0.349 0.686 0.168 0 0 0.272 0.534 0.131 0 0 0 0 0 1 0" />
          </filter>
          <filter id="filter-dingy" name="Dingy">
            <feColorMatrix values="1 0 0 0 0 0 1 0 0 0 0 0.3 0.3 0 0 0 0 0 1 0"></feColorMatrix>
          </filter>
          <filter id="filter-tint" name="Tint">
            <feColorMatrix values="1.1 0 0 0 0  0 1.1 0 0 0  0 0 0.9 0 0  0 0 0 1 0"></feColorMatrix>
          </filter>
        </g>

        <g id="deftemp">
          <g id="featurePaths"></g>
          <g id="textPaths"></g>
          <g id="statePaths"></g>
          <g id="defs-emblems"></g>
          <mask id="land"></mask>
          <mask id="water"></mask>
          <mask id="fog" style="stroke-width: 10; stroke: black; stroke-linejoin: round; stroke-opacity: 0.1">
            <rect x="0" y="0" width="100%" height="100%" fill="white" stroke="none" />
          </mask>
        </g>

        <pattern id="oceanic" width="100" height="100" patternUnits="userSpaceOnUse">
          <image id="oceanicPattern" href="./images/pattern1.png" opacity="0.2"></image>
        </pattern>

        <mask id="vignette-mask">
          <rect x="0" y="0" width="100%" height="100%" fill="white"></rect>
          <rect id="vignette-rect" fill="black"></rect>
        </mask>
      </defs>
      <g id="viewbox"></g>
      <g id="scaleBar">
        <rect id="scaleBarBack"></rect>
      </g>
      <g id="vignette" mask="url(#vignette-mask)">
        <rect x="0" y="0" width="100%" height="100%" />
      </g>
    </svg>

    <div id="loading">
      <svg width="100%" height="100%">
        <rect x="-1%" y="-1%" width="102%" height="102%" fill="#466eab" />
        <rect x="-1%" y="-1%" width="102%" height="102%" fill="url(#oceanic)" />
      </svg>
      <svg id="loading-rose" width="100%" height="100%" viewBox="0 0 700 700">
        <use href="#defs-compass-rose" x="50%" y="50%" />
      </svg>
      <div id="loading-typography">
        <div id="titleName">Azgaar's</div>
        <div id="title">Fantasy Map Generator</div>
        <div id="versionText">‎ ‎</div>
        <p id="loading-text">LOADING<span>.</span><span>.</span><span>.</span></p>
      </div>
    </div>

    <div id="optionsContainer" style="opacity: 0">
      <div id="collapsible">
        <button
          id="optionsTrigger"
          data-tip="Click to show the Menu"
          data-shortcut="Tab"
          class="options glow"
          onclick="showOptions(event)"
        >
          ►
        </button>
        <button
          id="regenerate"
          data-tip="Click to generate a new map"
          data-shortcut="F2"
          onclick="regeneratePrompt()"
          class="options"
          style="display: none"
        >
          New Map!
        </button>
      </div>

      <div id="options" style="display: none">
        <div class="drag-trigger" data-tip="Drag to move the Menu"></div>

        <div class="tab">
          <button
            id="optionsHide"
            data-tip="Click to hide the Menu"
            data-shortcut="Tab or Esc"
            class="options"
            onclick="hideOptions(event)"
          >
            ◄
          </button>
          <button id="layersTab" data-tip="Click to change map layers" class="options active">Layers</button>
          <button id="styleTab" data-tip="Click to open style editor" class="options">Style</button>
          <button id="optionsTab" data-tip="Click to change generation and UI options" class="options">Options</button>
          <button id="toolsTab" data-tip="Click to open tools menu" class="options">Tools</button>
          <button id="aboutTab" data-tip="Click to see Generator info" class="options">About</button>
        </div>

        <div id="layersContent" class="tabcontent" style="display: block">
          <p data-tip="Select a map layers preset" style="display: inline-block">Layers preset:</p>
          <select
            data-tip="Select a map layers preset"
            id="layersPreset"
            onchange="handleLayersPresetChange(this.value)"
            style="width: 45%"
          >
            <option value="political" selected>Political map</option>
            <option value="cultural">Cultural map</option>
            <option value="religions">Religions map</option>
            <option value="provinces">Provinces map</option>
            <option value="biomes">Biomes map</option>
            <option value="heightmap">Heightmap</option>
            <option value="physical">Physical map</option>
            <option value="poi">Places of interest</option>
            <option value="military">Military map</option>
            <option value="emblems">Emblems</option>
            <option value="landmass">Pure landmass</option>
            <option hidden value="custom">Custom (not saved)</option>
          </select>
          <button
            id="savePresetButton"
            data-tip="Click to save displayed layers as a new preset"
            class="icon-plus sideButton"
            style="display: none"
            onclick="savePreset()"
          ></button>
          <button
            id="removePresetButton"
            data-tip="Click to remove current custom preset"
            class="icon-minus sideButton"
            style="display: none"
            onclick="removePreset()"
          ></button>

          <p>Displayed layers and layers order:</p>
          <ul
            data-tip="Click to toggle a layer, drag to raise or lower a layer. Ctrl + click to edit layer style"
            id="mapLayers"
          >
            <li
              id="toggleTexture"
              data-tip="Texture overlay: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="X"
              onclick="toggleTexture(event)"
            >
              Te<u>x</u>ture
            </li>
            <li
              id="toggleHeight"
              data-tip="Heightmap: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="H"
              onclick="toggleHeight(event)"
            >
              <u>H</u>eightmap
            </li>
            <li
              id="toggleBiomes"
              data-tip="Biomes: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="B"
              onclick="toggleBiomes(event)"
            >
              <u>B</u>iomes
            </li>
            <li
              id="toggleCells"
              data-tip="Cells structure: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="E"
              onclick="toggleCells(event)"
            >
              C<u>e</u>lls
            </li>
            <li
              id="toggleGrid"
              data-tip="Grid: click to toggle, drag to raise or lower. Ctrl + click to edit layer style and select type"
              data-shortcut="G"
              onclick="toggleGrid(event)"
            >
              <u>G</u>rid
            </li>
            <li
              id="toggleCoordinates"
              data-tip="Coordinate grid: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="O"
              onclick="toggleCoordinates(event)"
            >
              C<u>o</u>ordinates
            </li>
            <li
              id="toggleCompass"
              data-tip="Wind (Compass) Rose: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="W"
              onclick="toggleCompass(event)"
            >
              <u>W</u>ind Rose
            </li>
            <li
              id="toggleRivers"
              data-tip="Rivers: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="V"
              onclick="toggleRivers(event)"
            >
              Ri<u>v</u>ers
            </li>
            <li
              id="toggleRelief"
              data-tip="Relief and biome icons: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="F"
              onclick="toggleRelief(event)"
            >
              Relie<u>f</u>
            </li>
            <li
              id="toggleReligions"
              data-tip="Religions: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="R"
              onclick="toggleReligions(event)"
            >
              <u>R</u>eligions
            </li>
            <li
              id="toggleCultures"
              data-tip="Cultures: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="C"
              onclick="toggleCultures(event)"
            >
              <u>C</u>ultures
            </li>
            <li
              id="toggleStates"
              data-tip="States: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="S"
              onclick="toggleStates(event)"
            >
              <u>S</u>tates
            </li>
            <li
              id="toggleProvinces"
              data-tip="Provinces: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="P"
              onclick="toggleProvinces(event)"
            >
              <u>P</u>rovinces
            </li>
            <li
              id="toggleZones"
              data-tip="Zones: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="Z"
              onclick="toggleZones(event)"
            >
              <u>Z</u>ones
            </li>
            <li
              id="toggleBorders"
              data-tip="State borders: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="D"
              onclick="toggleBorders(event)"
            >
              Bor<u>d</u>ers
            </li>
            <li
              id="toggleRoutes"
              data-tip="Trade routes: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="U"
              onclick="toggleRoutes(event)"
            >
              Ro<u>u</u>tes
            </li>
            <li
              id="toggleTemperature"
              data-tip="Temperature map: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="T"
              onclick="toggleTemperature(event)"
            >
              <u>T</u>emperature
            </li>
            <li
              id="togglePopulation"
              data-tip="Population map: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="N"
              onclick="togglePopulation(event)"
            >
              Populatio<u>n</u>
            </li>
            <li
              id="toggleIce"
              data-tip="Icebergs and glaciers: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="J"
              onclick="toggleIce(event)"
            >
              Ice
            </li>
            <li
              id="togglePrecipitation"
              data-tip="Precipitation map: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="A"
              onclick="togglePrecipitation(event)"
            >
              Precipit<u>a</u>tion
            </li>
            <li
              id="toggleEmblems"
              data-tip="Emblems: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="Y"
              onclick="toggleEmblems(event)"
            >
              Emblems
            </li>
            <li
              id="toggleLabels"
              data-tip="Labels: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="L"
              onclick="toggleLabels(event)"
            >
              <u>L</u>abels
            </li>
            <li
              id="toggleBurgIcons"
              data-tip="Burg icons: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="I"
              onclick="toggleBurgIcons(event)"
            >
              <u>I</u>cons
            </li>
            <li
              id="toggleMilitary"
              data-tip="Military forces: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="M"
              onclick="toggleMilitary(event)"
            >
              <u>M</u>ilitary
            </li>
            <li
              id="toggleMarkers"
              data-tip="Markers: click to toggle, drag to raise or lower the layer. Ctrl + click to edit layer style"
              data-shortcut="K"
              onclick="toggleMarkers(event)"
            >
              Mar<u>k</u>ers
            </li>
            <li
              id="toggleRulers"
              data-tip="Rulers: click to toggle, drag to move, click on label to delete. Ctrl + click to edit layer style"
              data-shortcut="= (equal sign)"
              onclick="toggleRulers(event)"
            >
              Rulers
            </li>
            <li
              id="toggleScaleBar"
              data-tip="Scale Bar: click to toggle. Ctrl + click to edit style"
              data-shortcut="/ (slash sign)"
              onclick="toggleScaleBar(event)"
              class="solid"
            >
              Scale Bar
            </li>
            <li
              id="toggleVignette"
              data-tip="Vignette (border fading): click to toggle. Ctrl + click to edit style"
              data-shortcut="[ (left square bracket)"
              onclick="toggleVignette(event)"
              class="solid"
            >
              Vignette
            </li>
          </ul>
          <div class="tip">Click to toggle, drag to raise or lower the layer</div>
          <div class="tip">Ctrl + click to edit layer style</div>

          <div id="viewMode" data-tip="Set view node">
            <p>View mode:</p>
            <button data-tip="Standard view mode that allows to edit the map" id="viewStandard" class="pressed">
              Standard
            </button>
            <button
              data-tip="Map presentation in 3D scene. Works best for heightmap. Cannot be used for editing"
              id="viewMesh"
            >
              3D scene
            </button>
            <button data-tip="Project map on globe. Cannot be used for editing" id="viewGlobe">Globe</button>
          </div>
        </div>

        <div id="styleContent" class="tabcontent">
          <p
            data-tip="Select a style preset. State labels may required regeneration if font is changed"
            style="display: inline-block"
          >
            Style preset:
          </p>
          <select
            data-tip="Select a style preset"
            id="stylePreset"
            onchange="requestStylePresetChange(this.value)"
            style="width: 45%; text-transform: capitalize"
          ></select>
          <button
            id="addStyleButton"
            data-tip="Click to save current style as a new preset"
            class="icon-plus sideButton"
            style="display: inline-block"
            onclick="addStylePreset()"
          ></button>
          <button
            id="removeStyleButton"
            data-tip="Click to remove current custom style preset"
            class="icon-minus sideButton"
            style="display: none"
            onclick="requestRemoveStylePreset()"
          ></button>

          <p data-tip="Select an element to edit its style" style="display: inline-block">Select element:</p>
          <select
            data-tip="Select an element to edit its style (list is ordered alphabetically)"
            id="styleElementSelect"
            style="width: 42%"
          >
            <option value="anchors">Anchor Icons</option>
            <option value="biomes">Biomes</option>
            <option value="borders">Borders</option>
            <option value="burgIcons">Burg Icons</option>
            <option value="cells">Cells</option>
            <option value="coastline">Coastline</option>
            <option value="coordinates">Coordinates</option>
            <option value="cults">Cultures</option>
            <option value="emblems">Emblems</option>
            <option value="fogging">Fogging</option>
            <option value="gridOverlay">Grid</option>
            <option value="terrs">Heightmap</option>
            <option value="ice">Ice</option>
            <option value="labels">Labels</option>
            <option value="lakes">Lakes</option>
            <option value="landmass">Landmass</option>
            <option value="legend">Legend</option>
            <option value="markers">Markers</option>
            <option value="armies">Military</option>
            <option value="ocean">Ocean</option>
            <option value="population">Population</option>
            <option value="prec">Precipitation</option>
            <option value="provs">Provinces</option>
            <option value="terrain">Relief Icons</option>
            <option value="relig">Religions</option>
            <option value="rivers">Rivers</option>
            <option value="routes">Routes</option>
            <option value="ruler">Rulers</option>
            <option value="scaleBar">Scale Bar</option>
            <option value="regions" selected>States</option>
            <option value="temperature">Temperature</option>
            <option value="texture">Texture</option>
            <option value="vignette">Vignette</option>
            <option value="compass">Wind Rose</option>
            <option value="zones">Zones</option>
          </select>

          <table id="styleElements">
            <caption
              id="styleIsOff"
              data-tip="The selected layer is not visible. Toogle it on to see style changes effect"
            >
              Ensure the element visibility is toggled on!
            </caption>

            <tbody id="styleGroup">
              <tr data-tip="Select element group">
                <td><b>Group</b></td>
                <td>
                  <select id="styleGroupSelect"></select>
                </td>
              </tr>
            </tbody>

            <tbody id="styleHeightmap">
              <tr id="styleHeightmapRenderOceanOption" data-tip="Check to render ocean heights">
                <td colspan="2">
                  <input id="styleHeightmapRenderOcean" class="checkbox" type="checkbox" />
                  <label for="styleHeightmapRenderOcean" class="checkbox-label">Render ocean heights</label>
                </td>
              </tr>

              <tr data-tip="Terracing power. Set to 0 to toggle off">
                <td>Terracing</td>
                <td>
                  <slider-input id="styleHeightmapTerracing" min="0" max="20" step="1"></slider-input>
                </td>
              </tr>

              <tr data-tip="Layers reduction rate. Increase to improve performance">
                <td>Reduce layers</td>
                <td>
                  <slider-input id="styleHeightmapSkip" min="0" max="10" step="1"></slider-input>
                </td>
              </tr>

              <tr data-tip="Line simplification rate. Increase to slightly improve performance">
                <td>Simplify line</td>
                <td>
                  <slider-input id="styleHeightmapSimplification" min="0" max="10" step="1"></slider-input>
                </td>
              </tr>

              <tr data-tip="Select line interpolation type">
                <td>Line style</td>
                <td>
                  <select id="styleHeightmapCurve">
                    <option value="curveBasisClosed" selected>Curved</option>
                    <option value="curveLinear">Linear</option>
                    <option value="curveStep">Rectangular</option>
                  </select>
                </td>
              </tr>

              <tr data-tip="Select color scheme for the element">
                <td>Color scheme</td>
                <td>
                  <select id="styleHeightmapScheme" style="width: 86%"></select>
                  <button
                    id="openCreateHeightmapSchemeButton"
                    data-tip="Click to add a custom heightmap color scheme"
                    data-stops="#ffffff,#EEEECC,#D2B48C,#008000,#008080"
                    class="icon-plus sideButton"
                  ></button>
                </td>
              </tr>
            </tbody>

            <tbody id="styleOpacity" style="display: none">
              <tr data-tip="Set opacity. 0: transparent, 1: solid">
                <td>Opacity</td>
                <td>
                  <slider-input id="styleOpacityInput" min="0" max="1" step="0.01"></slider-input>
                </td>
              </tr>
            </tbody>

            <tbody id="styleLegend">
              <tr data-tip="Set maximum number of items in one column">
                <td>Column items</td>
                <td>
                  <slider-input id="styleLegendColItems" min="1" max="30" step="1"></slider-input>
                </td>
              </tr>

              <tr data-tip="Set background color">
                <td>Background</td>
                <td>
                  <input id="styleLegendBack" type="color" value="#ffffff" />
                  <output id="styleLegendBackOutput">#ffffff</output>
                </td>
              </tr>

              <tr data-tip="Set background opacity">
                <td>Opacity</td>
                <td>
                  <slider-input id="styleLegendOpacity" min="0" max="1" step=".01"></slider-input>
                </td>
              </tr>
            </tbody>

            <tbody id="stylePopulation">
              <tr data-tip="Set bar color for rural population">
                <td>Rural color</td>
                <td>
                  <input id="stylePopulationRuralStrokeInput" type="color" value="#0000ff" />
                  <output id="stylePopulationRuralStrokeOutput">#0000ff</output>
                </td>
              </tr>

              <tr data-tip="Set bar color for urban population">
                <td>Urban color</td>
                <td>
                  <input id="stylePopulationUrbanStrokeInput" type="color" value="#ff0000" />
                  <output id="stylePopulationUrbanStrokeOutput">#ff0000</output>
                </td>
              </tr>
            </tbody>

            <tbody id="styleTexture">
              <tr data-tip="Select texture image. Big textures can highly affect performance">
                <td>Image</td>
                <td>
                  <select id="styleTextureInput" style="width: 86%">
                    <option value="">No texture</option>
                    <option value="./images/textures/folded-paper-big.jpg">Folded paper big</option>
                    <option value="./images/textures/folded-paper-small.jpg">Folded paper small</option>
                    <option value="./images/textures/gray-paper.jpg">Gray paper</option>
                    <option value="./images/textures/soiled-paper.jpg">Soiled paper horizontal</option>
                    <option value="./images/textures/soiled-paper-vertical.jpg">Soided paper vertical</option>
                    <option value="./images/textures/plaster.jpg">Plaster</option>
                    <option value="./images/textures/ocean.jpg">Ocean</option>
                    <option value="./images/textures/antique-small.jpg">Antique small</option>
                    <option value="./images/textures/antique-big.jpg">Antique big</option>
                    <option value="./images/textures/pergamena-small.jpg">Pergamena small</option>
                    <option value="./images/textures/marble-big.jpg" selected>Marble big</option>
                    <option value="./images/textures/marble-small.jpg">Marble small</option>
                    <option value="./images/textures/marble-blue-small.jpg">Marble Blue</option>
                    <option value="./images/textures/marble-blue-big.jpg">Marble Blue big</option>
                    <option value="./images/textures/stone-small.jpg">Stone small</option>
                    <option value="./images/textures/stone-big.jpg">Stone big</option>
                    <option value="./images/textures/timbercut-small.jpg">Timber Cut small</option>
                    <option value="./images/textures/timbercut-big.jpg">Timber Cut big</option>
                    <option value="./images/textures/mars-small.jpg">Mars small</option>
                    <option value="./images/textures/mars-big.jpg">Mars big</option>
                    <option value="./images/textures/mercury-small.jpg">Mercury small</option>
                    <option value="./images/textures/mercury-big.jpg">Mercury big</option>
                    <option value="./images/textures/mauritania-small.jpg">Mauritania small</option>
                    <option value="./images/textures/iran-small.jpg">Iran small</option>
                    <option value="./images/textures/spain-small.jpg">Spain small</option>
                  </select>
                  <button
                    data-tip="Click and provide a URL to image to be set as a texture"
                    class="icon-plus sideButton"
                    onclick="textureProvideURL()"
                  ></button>
                </td>
              </tr>

              <tr data-tip="Shift the texture by axes">
                <td>Shift by axes</td>
                <td>
                  <input id="styleTextureShiftX" type="number" value="0" data-tip="Shift texture by x axis in pixels" />
                  <input id="styleTextureShiftY" type="number" value="0" data-tip="Shift texture by y axis in pixels" />
                </td>
              </tr>
            </tbody>

            <tbody id="styleVignette">
              <tr data-tip="Select precreated vignette">
                <td>Preset</td>
                <td>
                  <select id="styleVignettePreset"></select>
                </td>
              </tr>

              <tr data-tip="Vignette rectangle position (in percents)">
                <td>Position</td>
                <td style="display: flex; flex-direction: column; gap: 2px">
                  <div>
                    <span>x </span>
                    <input id="styleVignetteX" type="number" min="0" max="100" step="0.1" style="width: 5em" />
                    <span>width&nbsp; </span>
                    <input id="styleVignetteWidth" type="number" min="0" max="100" step="0.1" style="width: 5em" />
                  </div>
                  <div>
                    <span>y </span>
                    <input id="styleVignetteY" type="number" min="0" max="100" step="0.1" style="width: 5em" />
                    <span>height </span>
                    <input id="styleVignetteHeight" type="number" min="0" max="100" step="0.1" style="width: 5em" />
                  </div>
                </td>
              </tr>

              <tr data-tip="Set vignette X and Y radius (in percents)">
                <td>Radius</td>
                <td>
                  <span>x </span>
                  <input id="styleVignetteRx" type="number" min="0" max="50" style="width: 5em" />
                  <span>y </span>
                  <input id="styleVignetteRy" type="number" min="0" max="50" style="width: 5em" />
                </td>
              </tr>

              <tr data-tip="Set vignette blue propagation (in pixels)">
                <td>Blur</td>
                <td>
                  <slider-input id="styleVignetteBlur" min="0" max="400" step="1"></slider-input>
                </td>
              </tr>
            </tbody>

            <tbody id="styleOcean">
              <tr data-tip="Select ocean pattern">
                <td>Pattern</td>
                <td>
                  <select id="styleOceanPattern">
                    <option value="">No pattern</option>
                    <option value="./images/pattern1.png">Pattern 1</option>
                    <option value="./images/pattern2.png">Pattern 2</option>
                    <option value="./images/pattern3.png">Pattern 3</option>
                    <option value="./images/pattern4.png">Pattern 4</option>
                    <option value="./images/pattern5.png">Pattern 5</option>
                    <option value="./images/pattern6.png">Pattern 6</option>
                    <option value="./images/kiwiroo.png">Kiwiroo</option>
                  </select>
                </td>
              </tr>

              <tr data-tip="Set ocean pattern opacity">
                <td>Pattern opacity</td>
                <td>
                  <slider-input id="styleOceanPatternOpacity" min="0" max="1" step=".01"></slider-input>
                </td>
              </tr>

              <tr data-tip="Define the coast outline contours scheme">
                <td>Ocean layers</td>
                <td>
                  <select id="outlineLayers">
                    <option value="none">No outline</option>
                    <option value="random">Random</option>
                    <option value="-6,-3,-1" selected>Standard 3</option>
                    <option value="-6,-4,-2">Indented 3</option>
                    <option value="-9,-6,-3,-1">Standard 4</option>
                    <option value="-6,-5,-4,-3,-2,-1">Smooth 6</option>
                    <option value="-9,-8,-7,-6,-5,-4,-3,-2,-1">Smooth 9</option>
                  </select>
                </td>
              </tr>

              <tr data-tip="Set ocean color">
                <td>Color</td>
                <td>
                  <input id="styleOceanFill" type="color" value="#466eab" />
                  <output id="styleOceanFillOutput">#466eab</output>
                </td>
              </tr>
            </tbody>

            <tbody id="styleGrid">
              <tr data-tip="Select grid overlay type">
                <td>Type</td>
                <td>
                  <select id="styleGridType">
                    <option value="pointyHex">Hex grid (pointy)</option>
                    <option value="flatHex">Hex grid (flat)</option>
                    <option value="square">Square grid</option>
                    <option value="square45deg">Square 45 degrees grid</option>
                    <option value="squareTruncated">Truncated square grid</option>
                    <option value="squareTetrakis">Tetrakis square grid</option>
                    <option value="triangleHorizontal">Triangle grid (horizontal)</option>
                    <option value="triangleVertical">Triangle grid (vertical)</option>
                    <option value="trihexagonal">Trihexagonal grid</option>
                    <option value="rhombille">Rhombille grid</option>
                  </select>
                </td>
              </tr>

              <tr data-tip="Set grid cells scale multiplier">
                <td>Scale</td>
                <td>
                  <input id="styleGridScale" type="number" min=".1" max="10" step=".01" />
                  <output
                    id="styleGridSizeFriendly"
                    data-tip="Distance between grid cell centers (in map scale)"
                  ></output>
                  <a
                    href="https://github.com/Azgaar/Fantasy-Map-Generator/wiki/Scale-and-distance#grids"
                    target="_blank"
                  >
                    <span
                      data-tip="Open wiki article scale and distance to know about grid scale"
                      class="icon-info-circled pointer"
                    ></span>
                  </a>
                </td>
              </tr>

              <tr data-tip="Shift the element by axes">
                <td>Shift by axes</td>
                <td>
                  <input id="styleGridShiftX" type="number" data-tip="Shift by x axis in pixels" />
                  <input id="styleGridShiftY" type="number" data-tip="Shift by y axis in pixels" />
                </td>
              </tr>
            </tbody>

            <tbody id="styleCompass">
              <tr data-tip="Set wind (compass) rose size">
                <td>Size</td>
                <td>
                  <slider-input id="styleCompassSizeInput" min=".02" max="1" step=".01"></slider-input>
                </td>
              </tr>

              <tr data-tip="Shift wind (compass) rose by axes">
                <td>Shift by axes</td>
                <td>
                  <input id="styleCompassShiftX" type="number" value="80" data-tip="Shift by x axis in pixels" />
                  <input id="styleCompassShiftY" type="number" value="80" data-tip="Shift by y axis in pixels" />
                </td>
              </tr>
            </tbody>

            <tbody id="styleRelief">
              <tr data-tip="Select set of relief icons. All relief icons will be regenerated">
                <td>Style</td>
                <td>
                  <select id="styleReliefSet">
                    <option value="simple" selected>Simple</option>
                    <option value="gray">Gray</option>
                    <option value="colored">Colored</option>
                  </select>
                </td>
              </tr>

              <tr data-tip="Define the size of relief icons. All relief icons will be regenerated">
                <td>Size</td>
                <td>
                  <slider-input id="styleReliefSize" min=".2" max="4" step=".01"></slider-input>
                </td>
              </tr>

              <tr
                data-tip="Define the density of relief icons. All relief icons will be regenerated. Highly affects performance!"
              >
                <td>Density</td>
                <td>
                  <slider-input id="styleReliefDensity" min=".3" max=".8" step=".01"></slider-input>
                </td>
              </tr>
            </tbody>

            <tbody id="styleFill">
              <tr data-tip="Set fill color">
                <td>Fill color</td>
                <td>
                  <input id="styleFillInput" type="color" value="#5E4FA2" />
                  <output id="styleFillOutput">#5E4FA2</output>
                </td>
              </tr>
            </tbody>

            <tbody id="styleStroke">
              <tr data-tip="Set stroke color">
                <td>Stroke color</td>
                <td>
                  <input id="styleStrokeInput" type="color" value="#5E4FA2" />
                  <output id="styleStrokeOutput">#5E4FA2</output>
                </td>
              </tr>
            </tbody>

            <tbody id="styleStrokeWidth">
              <tr data-tip="Set stroke width">
                <td>Stroke width</td>
                <td>
                  <slider-input id="styleStrokeWidthInput" min="0" max="5" step=".01"></slider-input>
                </td>
              </tr>
            </tbody>

            <tbody id="styleLetterSpacing">
              <tr data-tip="Set letter spacing">
                <td>Letter spacing</td>
                <td>
                  <slider-input id="styleLetterSpacingInput" min="0" max="20" step=".01"></slider-input>
                </td>
              </tr>
            </tbody>

            <tbody id="styleStrokeDash">
              <tr data-tip="Set stroke dash array (e.g. 5 2) and linecap">
                <td>Stroke dash</td>
                <td>
                  <input id="styleStrokeDasharrayInput" type="text" value="1 2" style="width: 26%" />
                  <select id="styleStrokeLinecapInput" style="width: 32%">
                    <option value="inherit" selected>Inherit</option>
                    <option value="butt">Butt</option>
                    <option value="round">Round</option>
                    <option value="square">Square</option>
                  </select>
                </td>
              </tr>
            </tbody>

            <tbody id="styleShadow">
              <tr data-tip="Set text shadow">
                <td>Text shadow</td>
                <td>
                  <input id="styleShadowInput" type="text" value="0 0 4px white" />
                </td>
              </tr>
            </tbody>

            <tbody id="styleFont">
              <tr data-tip="Select font">
                <td>Font</td>
                <td>
                  <select id="styleSelectFont" style="width: 85%"></select>
                  <button id="styleFontAdd" data-tip="Add a font" class="icon-plus sideButton"></button>
                </td>
              </tr>
            </tbody>

            <tbody id="styleSize">
              <tr data-tip="Set font size">
                <td>Font size</td>
                <td>
                  <button id="styleFontPlus" data-tip="Increase font" class="whiteButton">+</button>
                  <button id="styleFontMinus" data-tip="Descrease font" class="whiteButton">-</button>
                  <input id="styleFontSize" type="number" min=".5" max="100" step=".1" />
                </td>
              </tr>
            </tbody>

            <tbody id="styleRadius">
              <tr data-tip="Set icon size">
                <td>Radius</td>
                <td>
                  <button id="styleRadiusPlus" data-tip="Multiply radius by 1.1" class="whiteButton">+</button>
                  <button id="styleRadiusMinus" data-tip="Multiply radius by 1.1" class="whiteButton">-</button>
                  <input id="styleRadiusInput" type="number" min=".2" max="10" step=".02" value="1" />
                </td>
              </tr>
            </tbody>

            <tbody id="styleIconSize">
              <tr data-tip="Set icon size">
                <td>Size</td>
                <td>
                  <button id="styleIconSizePlus" data-tip="Multiply size by 1.1" class="whiteButton">+</button>
                  <button id="styleIconSizeMinus" data-tip="Multiply size by 1.1" class="whiteButton">-</button>
                  <input id="styleIconSizeInput" type="number" min=".2" max="10" step=".02" value="1" />
                </td>
              </tr>
            </tbody>

            <tbody id="styleCoastline">
              <tr data-tip="Allow system to apply filter automatically based on zoom level">
                <td colspan="2">
                  <input id="styleCoastlineAuto" class="checkbox" type="checkbox" />
                  <label for="styleCoastlineAuto" class="checkbox-label">Automatically change filter on zoom</label>
                </td>
              </tr>
            </tbody>

            <tbody id="styleTemperature">
              <tr data-tip="Define transparency of temperature leyer. Set to 0 to make it fully transparent">
                <td>Fill opacity</td>
                <td>
                  <slider-input id="styleTemperatureFillOpacityInput" min="0" max="1" step=".01"></slider-input>
                </td>
              </tr>

              <tr data-tip="Set labels size">
                <td>Labels size</td>
                <td>
                  <slider-input id="styleTemperatureFontSizeInput" min="0" max="30" step="1"></slider-input>
                </td>
              </tr>

              <tr data-tip="Set labels color">
                <td>Labels color</td>
                <td>
                  <input id="styleTemperatureFillInput" type="color" />
                  <output id="styleTemperatureFillOutput">#000</output>
                </td>
              </tr>
            </tbody>

            <tbody id="styleStates" style="display: block">
              <tr data-tip="Set states fill opacity. 0: invisible, 1: solid">
                <td>Body opacity</td>
                <td>
                  <slider-input id="styleStatesBodyOpacity" min="0" max="1" step="0.01"></slider-input>
                </td>
              </tr>

              <tr data-tip="Select filter for states fill. Please note filters may cause performance issues!">
                <td>Body filter</td>
                <td><select id="styleStatesBodyFilter" /></td>
              </tr>

              <tr style="margin-top: 0.8em">
                <td style="font-style: italic">
                  Halo is only rendered if "Rendering" option is set to "Best quality"!
                </td>
              </tr>

              <tr data-tip="Set states halo effect width">
                <td>Halo width</td>
                <td>
                  <slider-input id="styleStatesHaloWidth" min="0" max="30" step="0.1"></slider-input>
                </td>
              </tr>

              <tr data-tip="Set states halo effect opacity. 0: invisible, 1: solid">
                <td>Halo opacity</td>
                <td>
                  <slider-input id="styleStatesHaloOpacity" min="0" max="1" step="0.01"></slider-input>
                </td>
              </tr>

              <tr data-tip="Select halo effect power (blur). Set to 0 to make it solid line" style="margin-bottom: 1em">
                <td>Halo blur</td>
                <td>
                  <slider-input id="styleStatesHaloBlur" min="0" max="10" step="0.01"></slider-input>
                </td>
              </tr>
            </tbody>

            <tbody id="styleArmies">
              <tr data-tip="Set fill transparency. Set to 0 to make it fully transparent">
                <td>Fill opacity</td>
                <td>
                  <slider-input id="styleArmiesFillOpacity" min="0" max="1" step=".01"></slider-input>
                </td>
              </tr>
              <tr data-tip="Set regiment box size. All regiments will be redrawn on change (position will defaulted)">
                <td>Box Size</td>
                <td>
                  <slider-input id="styleArmiesSize" min="0" max="10" step=".1"></slider-input>
                </td>
              </tr>
            </tbody>

            <tbody id="styleEmblems">
              <tr data-tip="Set state emblems size multiplier">
                <td>State size</td>
                <td>
                  <slider-input id="emblemsStateSizeInput" min="0" max="5" step=".01"></slider-input>
                </td>
              </tr>

              <tr data-tip="Set province emblems size multiplier">
                <td>Province size</td>
                <td>
                  <slider-input id="emblemsProvinceSizeInput" min="0" max="5" step=".01"></slider-input>
                </td>
              </tr>

              <tr data-tip="Set burg emblems size multiplier">
                <td>Burg size</td>
                <td>
                  <slider-input id="emblemsBurgSizeInput" min="0" max="5" step=".01"></slider-input>
                </td>
              </tr>

              <tr data-tip="Allow system to hide emblem groups if their size in too small or too big on that scale">
                <td colspan="2">
                  <input id="hideEmblems" class="checkbox" type="checkbox" onchange="invokeActiveZooming()" checked />
                  <label for="hideEmblems" class="checkbox-label">Toggle visibility automatically</label>
                </td>
              </tr>
            </tbody>

            <tbody id="styleFilter" style="display: block">
              <tr data-tip="Select filter for element. Please note filters may cause performance issues!">
                <td>Filter</td>
                <td><select id="styleFilterInput" /></td>
              </tr>
            </tbody>

            <tbody id="styleClipping">
              <tr data-tip="Set clipping. Only non-clipped part will be visible">
                <td>Clipping</td>
                <td>
                  <select id="styleClippingInput">
                    <option value="" selected>No clipping</option>
                    <option value="url(#land)">Clip water</option>
                    <option value="url(#water)">Clip land</option>
                  </select>
                </td>
              </tr>
            </tbody>

            <tbody id="styleMarkers">
              <tr data-tip="Try to keep the same size on any map scale, turn off to get size change depending on scale">
                <td colspan="2">
                  <input id="styleRescaleMarkers" class="checkbox" type="checkbox" />
                  <label for="styleRescaleMarkers" class="checkbox-label">Keep initial size on zoom change</label>
                </td>
              </tr>
            </tbody>

            <tbody id="styleVisibility">
              <tr data-tip="Allow system to hide labels if their size in too small or too big on that scale">
                <td colspan="2">
                  <input id="hideLabels" class="checkbox" type="checkbox" onchange="invokeActiveZooming()" checked />
                  <label for="hideLabels" class="checkbox-label">Toggle visibility automatically</label>
                </td>
              </tr>

              <tr data-tip="Allow system to rescale labels on zoom">
                <td colspan="2">
                  <input id="rescaleLabels" class="checkbox" type="checkbox" onchange="invokeActiveZooming()" checked />
                  <label for="rescaleLabels" class="checkbox-label">Rescale on zoom</label>
                </td>
              </tr>
            </tbody>

            <tbody id="styleScaleBar">
              <tr data-tip="Set bar and font size">
                <td>Size</td>
                <td>
                  <span>Bar </span>
                  <input id="styleScaleBarSize" type="number" min=".5" max="5" step=".1" />
                  <span>Font </span>
                  <input id="styleScaleBarFontSize" type="number" min="1" max="100" step=".1" />
                </td>
              </tr>

              <tr data-tip="Set position of the Scale bar bottom right corner (in percents)">
                <td>Position</td>
                <td>
                  <span>x </span>
                  <input id="styleScaleBarPositionX" type="number" min="0" max="100" step="0.1" style="width: 5em" />
                  <span>y </span>
                  <input id="styleScaleBarPositionY" type="number" min="0" max="100" step="0.1" style="width: 5em" />
                </td>
              </tr>

              <tr data-tip="Type scale bar label, leave blank to hide label">
                <td>Label</td>
                <td>
                  <input id="styleScaleBarLabel" type="text" />
                </td>
              </tr>

              <tr data-tip="Set background opacity. 0: transparent, 1: solid">
                <td>Back opacity</td>
                <td>
                  <slider-input id="styleScaleBarBackgroundOpacity" min="0" max="1" step=".01"></slider-input>
                </td>
              </tr>

              <tr data-tip="Set background fill color">
                <td>Back fill</td>
                <td>
                  <input id="styleScaleBarBackgroundFill" type="color" />
                  <output id="styleScaleBarBackgroundFillOutput"></output>
                </td>
              </tr>

              <tr data-tip="Set background stroke color and width">
                <td>Back stroke</td>
                <td>
                  <input id="styleScaleBarBackgroundStroke" type="color" />
                  <output id="styleScaleBarBackgroundStrokeOutput"></output>

                  <span>Width </span>
                  <input
                    id="styleScaleBarBackgroundStrokeWidth"
                    type="number"
                    min="0"
                    max="10"
                    step="0.1"
                    style="width: 5em"
                  />
                </td>
              </tr>

              <tr data-tip="Set background element padding: top, right, bottom, left (in pixels)">
                <td>Back padding</td>
                <td style="display: flex; gap: 4px">
                  <input id="styleScaleBarBackgroundPaddingTop" type="number" min="0" max="100" style="width: 5em" />
                  <input id="styleScaleBarBackgroundPaddingRight" type="number" min="0" max="100" style="width: 5em" />
                  <input id="styleScaleBarBackgroundPaddingBottom" type="number" min="0" max="100" style="width: 5em" />
                  <input id="styleScaleBarBackgroundPaddingLeft" type="number" min="0" max="100" style="width: 5em" />
                </td>
              </tr>

              <tr data-tip="Select background filter">
                <td>Back filter</td>
                <td><select id="styleScaleBarBackgroundFilter" /></td>
              </tr>
            </tbody>
          </table>

          <div id="mapFilters" data-tip="Set a filter to be applied to the map in general">
            <p>Toggle global filters:</p>
            <button id="grayscale" class="radio">Grayscale</button>
            <button id="sepia" class="radio">Sepia</button>
            <button id="dingy" class="radio">Dingy</button>
            <button id="tint" class="radio">Tint</button>
          </div>
        </div>

        <div id="optionsContent" class="tabcontent">
          <p data-tip="Map generation settings. Generate a new map to apply the settings">
            Map settings (new map to apply):
          </p>
          <table>
            <tr
              data-tip="Set original map size on generation. It cannot be changed later. Always keep canvas size equal to your screen size or less. The best option is to use the default value. For full-globe maps use aspect ratio 2:1"
            >
              <td>
                <i data-tip="Restore default canvas size" id="restoreDefaultCanvasSize" class="icon-ccw"></i>
              </td>
              <td>Canvas size</td>
              <td>
                <input id="mapWidthInput" class="paired" type="number" min="240" value="960" />
                <span>x</span>
                <input id="mapHeightInput" class="paired" type="number" min="135" value="540" />
                <span>px</span>
              </td>
              <td></td>
            </tr>

            <tr
              data-tip="Map seed number. Press 'Enter' to apply. Seed produces the same map only if canvas size and options are the same"
            >
              <td>
                <i
                  data-tip="Show seed history to apply a previous seed"
                  id="optionsMapHistory"
                  class="icon-hourglass-1"
                ></i>
              </td>
              <td>Map seed</td>
              <td>
                <input id="optionsSeed" class="long" type="number" min="1" max="999999999" step="1" />
              </td>
              <td>
                <i
                  data-tip="Copy map seed as URL. It will produce the same map only if options are default or the same"
                  id="optionsCopySeed"
                  class="icon-docs"
                ></i>
              </td>
            </tr>

            <tr
              data-tip="Set number of points to be used for graph generation. Highly affects performance. 10K is the only recommended value"
            >
              <td>
                <i data-locked="0" id="lock_points" class="icon-lock-open"></i>
              </td>
              <td>Points number</td>
              <td>
                <input
                  id="pointsInput"
                  data-stored="points"
                  type="range"
                  min="1"
                  max="13"
                  value="4"
                  data-cells="10000"
                />
              </td>
              <td>
                <output id="pointsOutputFormatted" style="color: #053305">10K</output>
              </td>
            </tr>

            <tr data-tip="Define map name (will be used to name downloaded files)">
              <td>
                <i data-locked="0" id="lock_mapName" class="icon-lock-open"></i>
              </td>
              <td>Map name</td>
              <td>
                <input
                  id="mapName"
                  data-stored="mapName"
                  class="long"
                  autocorrect="off"
                  spellcheck="false"
                  type="text"
                />
              </td>
              <td>
                <i data-tip="Regenerate map name" onclick="Names.getMapName(true)" class="icon-arrows-cw"></i>
              </td>
            </tr>

            <tr data-tip="Define current year and era name">
              <td>
                <i data-locked="0" id="lock_year" data-ids="year,era" class="icon-lock-open"></i>
              </td>
              <td>Year and era</td>
              <td>
                <input
                  id="yearInput"
                  data-stored="year"
                  type="number"
                  step="1"
                  class="paired"
                  style="width: 24%; float: left; font-size: smaller"
                />
                <input
                  id="eraInput"
                  data-stored="era"
                  autocorrect="off"
                  spellcheck="false"
                  type="text"
                  style="width: 75%; float: right"
                  class="long"
                />
              </td>
              <td>
                <i id="optionsEraRegenerate" data-tip="Regenerate era" class="icon-arrows-cw"></i>
              </td>
            </tr>

            <tr data-tip="Select template or precreated heightmap to be used on generation">
              <td>
                <i data-locked="0" id="lock_template" class="icon-lock-open"></i>
              </td>
              <td>Heightmap</td>
              <td id="templateInputContainer" class="pointer">
                <select id="templateInput" data-stored="template" style="pointer-events: none"></select>
              </td>
              <td></td>
            </tr>

            <tr data-tip="Define how many Cultures should be generated">
              <td>
                <i data-locked="0" id="lock_cultures" class="icon-lock-open"></i>
              </td>
              <td>Cultures number</td>
              <td>
                <input id="culturesInput" data-stored="cultures" type="range" min="1" />
              </td>
              <td>
                <input id="culturesOutput" data-stored="cultures" type="number" min="1" />
              </td>
            </tr>

            <tr data-tip="Select a set of cultures to be used for names and cultures generation">
              <td>
                <i data-locked="0" id="lock_culturesSet" class="icon-lock-open"></i>
              </td>
              <td>Cultures set</td>
              <td>
                <select id="culturesSet" data-stored="culturesSet">
                  <option value="world" data-max="32" selected>All-world</option>
                  <option value="european" data-max="15">European</option>
                  <option value="oriental" data-max="13">Oriental</option>
                  <option value="english" data-max="10">English</option>
                  <option value="antique" data-max="10">Antique</option>
                  <option value="highFantasy" data-max="17">High Fantasy</option>
                  <option value="darkFantasy" data-max="18">Dark Fantasy</option>
                  <option value="random" data-max="100">Random</option>
                </select>
              </td>
              <td></td>
            </tr>

            <tr data-tip="Define how many states and capitals should be generated">
              <td>
                <i data-locked="0" id="lock_statesNumber" class="icon-lock-open"></i>
              </td>
              <td>States number</td>
              <td colspan="2">
                <slider-input id="statesNumber" data-stored="statesNumber" min="0" max="100"></slider-input>
              </td>
            </tr>

            <tr data-tip="Define burgs percentage to form a separate province">
              <td>
                <i data-locked="0" id="lock_provincesRatio" class="icon-lock-open"></i>
              </td>
              <td>Provinces ratio</td>
              <td colspan="2">
                <slider-input id="provincesRatio" data-stored="provincesRatio" min="0" max="100"></slider-input>
              </td>
            </tr>

            <tr data-tip="Define how much states and cultures can vary in size. Defines expansionism value">
              <td>
                <i data-locked="0" id="lock_sizeVariety" class="icon-lock-open"></i>
              </td>
              <td>Size variety</td>
              <td colspan="2">
                <slider-input id="sizeVariety" data-stored="sizeVariety" min="0" max="10" step=".1"></slider-input>
              </td>
            </tr>

            <tr data-tip="Set state and cultures growth rate. Defines how many lands will stay neutral">
              <td>
                <i data-locked="0" id="lock_growthRate" class="icon-lock-open"></i>
              </td>
              <td>Growth rate</td>
              <td colspan="2">
                <slider-input id="growthRate" data-stored="growthRate" min=".1" max="2" step=".1"></slider-input>
              </td>
            </tr>

            <tr data-tip="Define a number of towns to be placed (if enough suitable land exists)">
              <td>
                <i data-locked="0" id="lock_manors" class="icon-lock-open"></i>
              </td>
              <td>Towns number</td>
              <td>
                <input id="manorsInput" data-stored="manors" type="range" min="0" max="1000" step="1" value="1000" />
              </td>
              <td>
                <output id="manorsOutput" data-stored="manors" value="auto"></output>
              </td>
            </tr>

            <tr
              data-tip="Define how many organized religions and cults should be generated. Cultures will have their own folk religions in any case"
            >
              <td>
                <i data-locked="0" id="lock_religionsNumber" class="icon-lock-open"></i>
              </td>
              <td>Religions number</td>
              <td colspan="2">
                <slider-input
                  id="religionsNumber"
                  data-stored="religionsNumber"
                  min="0"
                  max="50"
                  step="1"
                ></slider-input>
              </td>
            </tr>

            <tr data-tip="Select state labels mode: display short or full names">
              <td>
                <i data-locked="0" id="lock_stateLabelsMode" class="icon-lock-open"></i>
              </td>
              <td>State labels</td>
              <td>
                <select id="stateLabelsModeInput" data-stored="stateLabelsMode">
                  <option value="auto">Auto</option>
                  <option value="short">Short names</option>
                  <option value="full">Full names</option>
                </select>
              </td>
              <td></td>
            </tr>
          </table>

          <p data-tip="Tool settings that don't affect maps. Changes are getting applied immediately">
            Generator settings:
          </p>
          <table>
            <tr
              data-tip="Set user interface size. Please note browser zoom also affects interface size (Ctrl + or Ctrl - to change)"
            >
              <td></td>
              <td>Interface size</td>
              <td colspan="2">
                <slider-input id="uiSize" data-stored="uiSize" min=".6" max="3" step=".1"></slider-input>
              </td>
            </tr>

            <tr data-tip="Set tooltip size">
              <td></td>
              <td>Tooltip size</td>
              <td colspan="2">
                <slider-input id="tooltipSize" data-stored="tooltipSize" min="1" max="32" value="14"></slider-input>
              </td>
            </tr>

            <tr data-tip="Set theme hue for dialogs and tool windows">
              <td>
                <i data-tip="Restore default theme color: pale magenta" id="themeColorRestore" class="icon-ccw"></i>
              </td>
              <td>Theme color</td>
              <td>
                <input id="themeHueInput" type="range" min="0" max="359" />
              </td>
              <td>
                <input id="themeColorInput" data-stored="themeColor" type="color" />
              </td>
            </tr>

            <tr data-tip="Set dialog and tool windows transparency">
              <td></td>
              <td>Transparency</td>
              <td colspan="2">
                <slider-input id="transparencyInput" data-stored="transparency" min="0" max="100"></slider-input>
              </td>
            </tr>

            <tr data-tip="Set autosave interval in minutes. Set 0 to disable autosave. Map is saved to browser memory">
              <td></td>
              <td>Autosave interval</td>
              <td>
                <input
                  id="autosaveIntervalInput"
                  data-stored="autosaveInterval"
                  type="range"
                  min="0"
                  max="60"
                  step="1"
                  value="15"
                />
              </td>
              <td>
                <input
                  id="autosaveIntervalOutput"
                  data-stored="autosaveInterval"
                  type="number"
                  min="0"
                  max="60"
                  step="1"
                  value="15"
                />
              </td>
            </tr>

            <tr data-tip="Set what Generator should do on load">
              <td></td>
              <td>Onload behavior</td>
              <td>
                <select id="onloadBehavior" data-stored="onloadBehavior">
                  <option value="random" selected>Generate random map</option>
                  <option value="lastSaved">Open last saved map</option>
                </select>
              </td>
              <td></td>
            </tr>

            <tr data-tip="Toggle Azgaar Assistant (help bubble on the bottom right corner)">
              <td></td>
              <td>Azgaar assistant</td>
              <td>
                <select id="azgaarAssistant" data-stored="azgaarAssistant">
                  <option value="show" selected>Show</option>
                  <option value="hide">Hide</option>
                </select>
              </td>
            </tr>

            <tr data-tip="Select speech synthesis voice to pronounce generated names">
              <td></td>
              <td>Speaker voice</td>
              <td>
                <select id="speakerVoice" data-stored="speakerVoice"></select>
              </td>
              <td>
                <span id="speakerTest" data-tip="Click to test the voice" style="cursor: pointer">🔊</span>
              </td>
            </tr>

            <tr data-tip="Select emblem shape. Can be changed indivudually in Emblem editor">
              <td>
                <i data-locked="0" id="lock_emblemShape" class="icon-lock"></i>
              </td>
              <td>Emblem shape</td>
              <td>
                <select id="emblemShape" data-stored="emblemShape">
                  <optgroup label="Diversiform">
                    <option value="culture" selected>Culture-specific</option>
                    <option value="random">Culture-random</option>
                    <option value="state">State-specific</option>
                  </optgroup>
                  <optgroup label="Basic">
                    <option value="heater">Heater</option>
                    <option value="spanish">Spanish</option>
                    <option value="french">French</option>
                  </optgroup>
                  <optgroup label="Regional">
                    <option value="horsehead">Horsehead</option>
                    <option value="horsehead2">Horsehead Edgy</option>
                    <option value="polish">Polish</option>
                    <option value="hessen">Hessen</option>
                    <option value="swiss">Swiss</option>
                  </optgroup>
                  <optgroup label="Historical">
                    <option value="boeotian">Boeotian</option>
                    <option value="roman">Roman</option>
                    <option value="kite">Kite</option>
                    <option value="oldFrench">Old French</option>
                    <option value="renaissance">Renaissance</option>
                    <option value="baroque">Baroque</option>
                  </optgroup>
                  <optgroup label="Specific">
                    <option value="targe">Targe</option>
                    <option value="targe2">Targe2</option>
                    <option value="pavise">Pavise</option>
                    <option value="wedged">Wedged</option>
                  </optgroup>
                  <optgroup label="Banner">
                    <option value="flag">Flag</option>
                    <option value="pennon">Pennon</option>
                    <option value="guidon">Guidon</option>
                    <option value="banner">Banner</option>
                    <option value="dovetail">Dovetail</option>
                    <option value="gonfalon">Gonfalon</option>
                    <option value="pennant">Pennant</option>
                  </optgroup>
                  <optgroup label="Simple">
                    <option value="round">Round</option>
                    <option value="oval">Oval</option>
                    <option value="vesicaPiscis">Vesica Piscis</option>
                    <option value="square">Square</option>
                    <option value="diamond">Diamond</option>
                  </optgroup>
                  <optgroup label="Fantasy">
                    <option value="fantasy1">Fantasy1</option>
                    <option value="fantasy2">Fantasy2</option>
                    <option value="fantasy3">Fantasy3</option>
                    <option value="fantasy4">Fantasy4</option>
                    <option value="fantasy5">Fantasy5</option>
                  </optgroup>
                  <optgroup label="Middle Earth">
                    <option value="noldor">Noldor</option>
                    <option value="gondor">Gondor</option>
                    <option value="easterling">Easterling</option>
                    <option value="erebor">Erebor</option>
                    <option value="ironHills">Iron Hills</option>
                    <option value="urukHai">UrukHai</option>
                    <option value="moriaOrc">Moria Orc</option>
                  </optgroup>
                </select>
              </td>
              <td>
                <svg class="emblemShapePreview" viewBox="0 0 200 210"><path id="emblemShapeImage" /></svg>
              </td>
            </tr>

            <tr data-tip="Set minimum and maximum possible zoom level">
              <td>
                <i data-tip="Restore default zoom extent: [1, 20]" id="zoomExtentDefault" class="icon-ccw"></i>
              </td>
              <td>Zoom extent</td>
              <td>
                <span data-tip="Mimimal possible zoom level (should be > 0)">min</span>
                <input
                  data-tip="Mimimal possible zoom level (should be > 0)"
                  id="zoomExtentMin"
                  class="paired"
                  type="number"
                  min=".2"
                  step=".1"
                  max="20"
                  value="1"
                />
                <span data-tip="Maximal possible zoom level (should be > 1)">max</span>
                <input
                  data-tip="Maximal possible zoom level (should be > 1)"
                  id="zoomExtentMax"
                  class="paired"
                  type="number"
                  min="1"
                  max="50"
                  value="20"
                />
              </td>
              <td>
                <i
                  data-tip="Allow to drag map beyond canvas borders"
                  id="translateExtent"
                  data-on="0"
                  class="icon-hand-paper-o"
                ></i>
              </td>
            </tr>

            <tr data-tip="Select rendering model. Try to set to 'optimized' if you face performance issues">
              <td></td>
              <td>Rendering</td>
              <td>
                <select id="shapeRendering" data-stored="shapeRendering">
                  <option value="geometricPrecision">Best quality</option>
                  <option value="optimizeSpeed" selected>Best performance</option>
                </select>
              </td>
              <td></td>
            </tr>

            <tr
              data-tip="Load Google Translate and select language. Note that automatic translation can break some page functional. In this case reset the language back to English or refresh the page"
            >
              <td>
                <i data-tip="Reset language to English" id="resetLanguage" class="icon-ccw"></i>
              </td>
              <td>Language</td>
              <td>
                <button id="loadGoogleTranslateButton">Init Google Translate</button>
                <div id="google_translate_element"></div>
              </td>
              <td></td>
            </tr>
          </table>

          <div>
            <button
              id="configureWorld"
              data-tip="Click to open world configurator to setup map position on Globe and World climate"
              onclick="editWorld()"
            >
              Configure World
            </button>
            <button
              id="optionsReset"
              data-tip="Click to restore default options and reload the page"
              onclick="cleanupData()"
            >
              Reset to defaults
            </button>
          </div>
        </div>

        <div id="toolsContent" class="tabcontent">
          <div class="separator">Edit</div>
          <div class="grid">
            <button id="editBiomesButton" data-tip="Click to open Biomes Editor" data-shortcut="Shift + B">
              Biomes
            </button>
            <button id="overviewBurgsButton" data-tip="Click to open Burgs Overview" data-shortcut="Shift + T">
              Burgs
            </button>
            <button id="editCulturesButton" data-tip="Click to open Cultures Editor" data-shortcut="Shift + C">
              Cultures
            </button>
            <button
              id="editDiplomacyButton"
              data-tip="Click to open Diplomatical relationships Editor"
              data-shortcut="Shift + D"
            >
              Diplomacy
            </button>
            <button id="editEmblemButton" data-tip="Click to open Emblem Editor" data-shortcut="Shift + Y">
              Emblems
            </button>
            <button
              id="editHeightmapButton"
              data-tip="Click to open Heightmap customization menu"
              data-shortcut="Shift + H"
            >
              Heightmap
            </button>
            <button id="overviewMarkersButton" data-tip="Click to open Markers Overview" data-shortcut="Shift + K">
              Markers
            </button>
            <button
              id="overviewMilitaryButton"
              data-tip="Click to open Military Forces Overview"
              data-shortcut="Shift + M"
            >
              Military
            </button>
            <button id="editNamesBaseButton" data-tip="Click to open Namesbase Editor" data-shortcut="Shift + N">
              Namesbase
            </button>
            <button id="editNotesButton" data-tip="Click to open Notes Editor" data-shortcut="Shift + O">Notes</button>
            <button id="editProvincesButton" data-tip="Click to open Provinces Editor" data-shortcut="Shift + P">
              Provinces
            </button>
            <button id="editReligions" data-tip="Click to open Religions Editor" data-shortcut="Shift + R">
              Religions
            </button>
            <button id="overviewRiversButton" data-tip="Click to open Rivers Overview" data-shortcut="Shift + V">
              Rivers
            </button>
            <button id="overviewRoutesButton" data-tip="Click to open Routes Overview" data-shortcut="Shift + U">
              Routes
            </button>
            <button id="editStatesButton" data-tip="Click to open States Editor" data-shortcut="Shift + S">
              States
            </button>
            <button id="editUnitsButton" data-tip="Click to open Units Editor" data-shortcut="Shift + Q">Units</button>
            <button id="editZonesButton" data-tip="Click to open Zones Editor" data-shortcut="Shift + Z">Zones</button>
          </div>

          <div class="separator">Regenerate</div>
          <div id="regenerateFeature" class="grid">
            <button
              id="regenerateBurgs"
              data-tip="Click to regenerate all unlocked burgs and routes. States will remain as they are. Note: burgs are only generated in populated areas with culture assigned"
            >
              Burgs
            </button>
            <button id="regenerateCultures" data-tip="Click to regenerate non-locked cultures">Cultures</button>
            <button id="regenerateEmblems" data-tip="Click to regenerate all emblems">Emblems</button>
            <button id="regenerateIce" data-tip="Click to regenerate icebergs and glaciers">Ice</button>
            <button
              id="regenerateStateLabels"
              data-tip="Click to update state labels placement based on current borders"
            >
              State Labels
            </button>
            <button id="regenerateMarkers" data-tip="Click to regenerate unlocked markers">
              Markers <i id="configRegenerateMarkers" class="icon-cog" data-tip="Click to set number multiplier"></i>
            </button>
            <button
              id="regenerateMilitary"
              data-tip="Click to recalculate military forces based on current military options"
            >
              Military
            </button>
            <button id="regeneratePopulation" data-tip="Click to recalculate rural and urban population">
              Population
            </button>
            <button
              id="regenerateProvinces"
              data-tip="Click to regenerate non-locked provinces. States will remain as they are"
            >
              Provinces
            </button>
            <button
              id="regenerateReliefIcons"
              data-tip="Click to regenerate all relief icons based on current cell biome and elevation"
            >
              Relief
            </button>
            <button id="regenerateReligions" data-tip="Click to regenerate non-locked religions">Religions</button>
            <button id="regenerateRivers" data-tip="Click to regenerate all rivers (restore default state)">
              Rivers
            </button>
            <button id="regenerateRoutes" data-tip="Click to regenerate all unlocked routes">Routes</button>
            <button
              id="regenerateStates"
              data-tip="Click to regenerate non-locked states. Emblems and military forces will be regenerated as well, burgs will remain as they are, but capitals will be different"
            >
              States
            </button>
            <button
              id="regenerateZones"
              data-tip="Click to regenerate zones. Hold Ctrl and click to set zones number multiplier"
            >
              Zones
            </button>
          </div>

          <div class="separator">Add</div>
          <div id="addFeature" class="grid">
            <button
              id="addBurgTool"
              data-tip="Click on map to place a burg. Hold Shift to add multiple"
              data-shortcut="Shift + 1"
            >
              Burg
            </button>
            <button
              id="addLabel"
              data-tip="Click on map to place label. Hold Shift to add multiple"
              data-shortcut="Shift + 2"
            >
              Label
            </button>
            <button
              id="addMarker"
              data-tip="Click on map to place a marker. Hold Shift to add multiple"
              data-shortcut="Shift + 5"
            >
              Marker
            </button>
            <button
              id="addRiver"
              data-tip="Click on map to place a river. Hold Shift to add multiple"
              data-shortcut="Shift + 3"
            >
              River
            </button>
            <button id="addRoute" data-tip="Open route creation dialog" data-shortcut="Shift + 4">Route</button>
          </div>

          <div class="separator">Show</div>
          <div class="grid">
            <button id="overviewCellsButton" data-tip="Click to open Cell details view" data-shortcut="Shift + E">
              Cells
            </button>
            <button
              id="overviewChartsButton"
              data-tip="Click to open Charts to overview cells data"
              data-shortcut="Shift + A"
            >
              Charts
            </button>
          </div>

          <div class="separator">Create</div>
          <div class="grid">
            <button id="openSubmapTool" data-tip="Click to generate a submap from the current viewport">Submap</button>
            <button id="openTransformTool" data-tip="Click to transform the map">Transform</button>
          </div>
        </div>

        <div id="customizationMenu" class="tabcontent">
          <p>Heightmap customization tools:</p>
          <div id="customizeTools">
            <button data-tip="Display brushes panel" id="paintBrushes">Paint Brushes</button>
            <button data-tip="Open template editor" id="applyTemplate" style="display: none">Template Editor</button>
            <button data-tip="Open Image Converter" id="convertImage" style="display: none">Image Converter</button>
            <button data-tip="Render heightmap data as a small monochrome image" id="heightmapPreview">Preview</button>
            <button data-tip="Preview heightmap in 3D scene" id="heightmap3DView">3D scene</button>
          </div>

          <p>Options:</p>
          <div id="customizeOptions">
            <div data-tip="Heightmap edit mode">Edit mode: <span id="heightmapEditMode"></span></div>
            <div data-tip="Render cells below the sea level (with height less than 20)">
              <input id="renderOcean" class="checkbox" type="checkbox" />
              <label for="renderOcean" class="checkbox-label">Render ocean cells</label>
            </div>
            <div
              id="allowErosionBox"
              data-tip="Regenerate rivers and allow water flow to change heights and form new lakes. Better to keep checked"
            >
              <input id="allowErosion" class="checkbox" type="checkbox" checked />
              <label for="allowErosion" class="checkbox-label">Allow water erosion</label>
            </div>
            <div
              data-tip="Maximum number of iterations taken to resolve depressions. Increase if you have rivers ending nowhere"
            >
              <div>Depressions filling max iterations:</div>
              <input
                id="resolveDepressionsStepsInput"
                data-stored="resolveDepressionsSteps"
                type="range"
                min="0"
                max="500"
                value="250"
              />
              <input
                id="resolveDepressionsStepsOutput"
                data-stored="resolveDepressionsSteps"
                type="number"
                min="0"
                max="1000"
                value="250"
              />
            </div>

            <div data-tip="Depression depth to form a new lake. Increase to reduce number of lakes added by system">
              <div>Depression depth threshold:</div>
              <input
                id="lakeElevationLimitInput"
                data-stored="lakeElevationLimit"
                type="range"
                min="0"
                max="80"
                value="20"
              />
              <input
                id="lakeElevationLimitOutput"
                data-stored="lakeElevationLimit"
                type="number"
                min="0"
                max="80"
                value="20"
              />
            </div>
          </div>

          <p>Statistics:</p>
          <div>
            <span>Land cells: </span><span id="landmassCounter">0</span>
            <span style="margin-left: 0.9em">Mean height: </span><span id="landmassAverage">0</span>
          </div>

          <p>Cell info:</p>
          <div>
            <span>Coord: </span><span id="heightmapInfoX"></span>/<span id="heightmapInfoY"></span><br />
            <span>Cell: </span><span id="heightmapInfoCell"></span><br />
            <span>Height: </span><span id="heightmapInfoHeight"></span>
          </div>
        </div>

        <div id="aboutContent" class="tabcontent">
          <p>
            <a href="https://github.com/Azgaar/Fantasy-Map-Generator" target="_blank">Fantasy Map Generator</a> is an
            <a href="https://github.com/Azgaar/Fantasy-Map-Generator/blob/master/LICENSE" target="_blank"
              >open source</a
            >
            tool by Azgaar. You may use auto-generated maps as they are, edit them or even create a new map from
            scratch. Check out the
            <a href="https://github.com/Azgaar/Fantasy-Map-Generator/wiki/Quick-Start-Tutorial" target="_blank"
              >Quick start</a
            >, <a href="https://github.com/Azgaar/Fantasy-Map-Generator/wiki/Q&A" target="_blank">Q&A</a>,
            <a href="https://youtube.com/playlist?list=PLtgiuDC8iVR2gIG8zMTRn7T_L0arl9h1C" target="_blank"
              >Video tutorial</a
            >, and
            <a href="https://github.com/Azgaar/Fantasy-Map-Generator/wiki/Hotkeys" target="_blank">hotkeys</a> for
            guidance.
          </p>

          <p>
            Join our <a href="https://discordapp.com/invite/X7E84HU" target="_blank">Discord server</a> and
            <a href="https://www.reddit.com/r/FantasyMapGenerator/" target="_blank">Reddit community</a> to ask
            questions, get help and share maps. The created maps can be used for free, even for commercial purposes.
          </p>

          <p>
            The project is under active development. Creator and main maintainer: Azgaar. To track the development
            progress see the
            <a href="https://trello.com/b/7x832DG4/fantasy-map-generator" target="_blank">devboard</a>. For older
            versions see the
            <a href="https://github.com/Azgaar/Fantasy-Map-Generator/wiki/Changelog" target="_blank">changelog</a>.
            Please report bugs
            <a href="https://github.com/Azgaar/Fantasy-Map-Generator/issues" target="_blank">here</a>. You can also
            contact me directly via <a href="mailto:azgaar.fmg@yandex.by" target="_blank">email</a>.
          </p>

          <div
            style="
              background-color: #e85b46;
              padding: 0.4em;
              width: max-content;
              margin: 0.6em auto 0 auto;
              border: 1px solid #943838;
            "
          >
            <a
              href="https://www.patreon.com/azgaar"
              target="_blank"
              style="color: white; text-decoration: none; font-family: sans-serif"
            >
              <div>
                <div style="width: 0.8em; display: inline-block; padding: 0 0.2em; fill: white">
                  <svg viewBox="0 0 569 546">
                    <circle cx="362.589996" cy="204.589996" data-fill="1" id="Oval" r="204.589996" />
                    <rect data-fill="2" height="545.799988" id="Rectangle" width="100" x="0" y="0" />
                  </svg>
                </div>
                SUPPORT ON PATREON
              </div>
            </a>
          </div>

          <p>
            Special thanks to
            <a data-tip="Click to see list of supporters" onclick="showSupporters()">all supporters</a> on Patreon!
          </p>

          <div style="display: flex; justify-content: center; padding: 0.8em 0.4em 0.4em; font-family: cursive">
            <a
              href="https://war.ukraine.ua/support-ukraine"
              style="width: 80%"
              data-tip="Support Ukraine"
              target="_blank"
            >
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 350">
                <rect width="100%" height="100%" fill="#005bbb"></rect>
                <rect y="50%" width="100%" height="50%" fill="#ffd500"></rect>
                <text x="50%" text-anchor="middle" font-size="8em" y="32%" fill="#f5f5f5">Support Ukraine</text>
                <text x="50%" text-anchor="middle" font-size="4em" y="78%" fill="#005bdd">
                  war.ukraine.ua/support-ukraine
                </text>
              </svg>
            </a>
          </div>

          <div style="text-align: left">
            <p>Check out our other projects:</p>
            <div>
              • <a href="https://azgaar.github.io/Armoria" target="_blank">Armoria</a>: a tool for creating heraldic
              coats of arms
            </div>
            <div>
              • <a href="https://deorum.vercel.app" target="_blank">Deorum</a>: a vast gallery of customizable fantasy
              characters
            </div>
          </div>

          <div style="text-align: left; margin-top: 0.5em">
            Chinese localization: <a href="https://www.8desk.top" target="_blank">8desk.top</a>
          </div>

          <ul class="share-buttons">
            <li>
              <a
                href="https://www.facebook.com/sharer/sharer.php?u=https%3A%2F%2Fazgaar.github.io%2FFantasy-Map-Generator%2F&quote="
                data-tip="Share on Facebook"
                target="_blank"
                ><img alt="Share on Facebook" src="images/Facebook.png" loading="lazy"
              /></a>
            </li>
            <li>
              <a
                href="https://twitter.com/intent/tweet?source=https%3A%2F%2Fazgaar.github.io%2FFantasy-Map-Generator&text=%23FantasyMapGenerator%0A%0Ahttps%3A//azgaar.github.io/Fantasy-Map-Generator"
                target="_blank"
                data-tip="Tweet"
                ><img alt="Tweet" src="images/Twitter.png" loading="lazy"
              /></a>
            </li>
            <li>
              <a
                href="http://pinterest.com/pin/create/button/?url=https%3A%2F%2Fazgaar.github.io%2FFantasy-Map-Generator"
                target="_blank"
                data-tip="Pin it"
                ><img alt="Pin it" src="images/Pinterest.png" loading="lazy"
              /></a>
            </li>
            <li>
              <a
                href="http://www.reddit.com/submit?url=https%3A%2F%2Fazgaar.github.io%2FFantasy-Map-Generator"
                target="_blank"
                data-tip="Submit to Reddit"
                ><img alt="Submit to Reddit" src="images/Reddit.png" loading="lazy"
              /></a>
            </li>
            <li>
              <a href="https://discord.gg/X7E84HU" target="_blank" data-tip="Join Discord server"
                ><img alt="Join Discord server" src="images/Discord.png" loading="lazy"
              /></a>
            </li>
          </ul>
        </div>

        <div id="sticked">
          <button id="newMapButton" data-tip="Generate a new map based on options" data-shortcut="F2">New Map</button>
          <button id="exportButton" data-tip="Select format to download image or export map data">Export</button>
          <button id="saveButton" data-tip="Save fully-functional map file">Save</button>
          <button id="loadButton" data-tip="Load fully-functional map (.map or .gz formats)">Load</button>
          <button id="zoomReset" data-tip="Reset map zoom" data-shortcut="0 (zero)">Reset Zoom</button>
        </div>
      </div>
    </div>

    <div id="exitCustomization">
      <div data-tip="Drag to move the pane">
        <button data-tip="Finalize the heightmap and exit the edit mode" id="finalizeHeightmap">
          Exit Customization
        </button>
      </div>
    </div>

    <div id="dialogs">
      <div id="worldConfigurator" class="dialog stable" style="display: none">
        <div style="display: flex">
          <div id="worldControls">
            <div>
              <i data-locked="0" id="lock_temperatureEquator" class="icon-lock-open"></i>
              <label data-tip="Set temperature at equator">
                <i>Equator:</i>
                <input id="temperatureEquatorInput" data-stored="temperatureEquator" type="number" min="-50" max="50" />
                <span>°C = <span id="temperatureEquatorF"></span></span>
                <input id="temperatureEquatorOutput" data-stored="temperatureEquator" type="range" min="-50" max="50" />
              </label>
            </div>
            <div>
              <label data-tip="Set the North Pole average yearly temperature">
                <i data-locked="0" id="lock_temperatureNorthPole" class="icon-lock-open"></i>
                <i>North Pole:</i>
                <input
                  id="temperatureNorthPoleInput"
                  data-stored="temperatureNorthPole"
                  type="number"
                  min="-50"
                  max="50"
                />
                <span>°C = <span id="temperatureNorthPoleF"></span></span>
                <input
                  id="temperatureNorthPoleOutput"
                  data-stored="temperatureNorthPole"
                  type="range"
                  min="-50"
                  max="50"
                />
              </label>
            </div>

            <div>
              <label data-tip="Set the South Pole average yearly temperature">
                <i data-locked="0" id="lock_temperatureSouthPole" class="icon-lock-open"></i>
                <i>South Pole:</i>
                <input
                  id="temperatureSouthPoleInput"
                  data-stored="temperatureSouthPole"
                  type="number"
                  min="-50"
                  max="50"
                />
                <span>°C = <span id="temperatureSouthPoleF"></span></span>
                <input
                  id="temperatureSouthPoleOutput"
                  data-stored="temperatureSouthPole"
                  type="range"
                  min="-50"
                  max="50"
                />
              </label>
            </div>
            <div>
              <i data-locked="0" id="lock_mapSize" class="icon-lock-open"></i>
              <label data-tip="Set map size relative to the world size">
                <i>Map size:</i>
                <input id="mapSizeInput" data-stored="mapSize" type="number" min="1" max="100" step="0.1" />%
                <input id="mapSizeOutput" data-stored="mapSize" type="range" min="1" max="100" step="0.1" />
              </label>
            </div>
            <div>
              <i data-locked="0" id="lock_latitude" class="icon-lock-open"></i>
              <label data-tip="Set a North-South map shift, set to 50 to make map center lie on Equator">
                <i>Latitudes:</i>
                <input id="latitudeInput" data-stored="latitude" type="number" min="0" max="100" step="0.1" />
                <br /><i>N</i
                ><input
                  id="latitudeOutput"
                  data-stored="latitude"
                  type="range"
                  min="0"
                  max="100"
                  step="0.1"
                  style="width: 10.3em"
                /><i>S</i>
              </label>
            </div>

            <div>
              <i data-locked="0" id="lock_longitude" class="icon-lock-open"></i>
              <label data-tip="Set a West-East map shift, set to 50 to make map center lie on Prime meridian">
                <i>Longitudes:</i>
                <input
                  id="longitudeInput"
                  data-stored="longitude"
                  type="number"
                  min="0"
                  max="100"
                  value="50"
                  step="0.1"
                />
                <br /><i>W</i
                ><input
                  id="longitudeOutput"
                  data-stored="longitude"
                  type="range"
                  min="0"
                  max="100"
                  step="0.1"
                  style="width: 10.3em"
                /><i>E</i>
              </label>
            </div>

            <div>
              <label
                data-tip="Set precipitation - water amount clouds can bring. Defines rivers and biomes generation. Keep around 100% for default generation"
              >
                <i data-locked="0" id="lock_prec" class="icon-lock-open"></i>
                <i>Precipitation:</i>
                <input id="precInput" data-stored="prec" type="number" />%
                <input id="precOutput" data-stored="prec" type="range" min="0" max="500" value="50" />
              </label>
            </div>
            <div data-tip="Canvas size. Can be changed in general options on new map generation">
              <i>Canvas size:</i><br />
              <span id="mapSize"></span> px = <span id="mapSizeFriendly"></span>
            </div>
            <div>
              <i data-tip="Length of Meridian. Almost half of the equator length">Meridian length:</i><br />
              <span id="meridianLength" data-tip="Length of Meridian in pixels"></span> px =
              <span
                id="meridianLengthFriendly"
                data-tip="Length of Meridian is friendly units (depends on user configuration)"
              ></span>
              <span
                id="meridianLengthEarth"
                data-tip="Fantasy world Meridian length relative to real-world Earth (20k km)"
              ></span>
            </div>
            <div data-tip="Map coordinates on globe"><i>Coords:</i> <span id="mapCoordinates"></span></div>
          </div>

          <div style="display: flex; flex-direction: column; align-items: flex-end">
            <svg id="globe" width="22em" viewBox="-20 -25 240 240">
              <defs>
                <linearGradient id="temperatureGradient" x1="0" x2="0" y1="0" y2="1">
                  <stop id="grad90" offset="0%" stop-color="blue" />
                  <stop id="grad60" offset="16.6%" stop-color="green" />
                  <stop id="grad30" offset="33.3%" stop-color="yellow" />
                  <stop id="grad0" offset="50%" stop-color="red" />
                  <stop id="grad-30" offset="66.6%" stop-color="yellow" />
                  <stop id="grad-60" offset="83.3%" stop-color="green" />
                  <stop id="grad-90" offset="100%" stop-color="blue" />
                </linearGradient>
              </defs>
              <g id="globeNoteLines">
                <line x1="5" x2="220" y1="0" y2="0" />
                <line x1="5" x2="220" y1="13" y2="13" />
                <line x1="5" x2="220" y1="49.5" y2="49.5" />
                <line x1="-5" x2="220" y1="100" y2="100" />
                <line x1="5" x2="220" y1="150.5" y2="150.5" />
                <line x1="5" x2="220" y1="187" y2="187" />
                <line x1="5" x2="220" y1="200" y2="200" />
              </g>
              <g id="globeWindArrows" data-tip="Click to change wind direction" stroke-linejoin="round">
                <circle cx="210" cy="6" r="12" />
                <path data-tier="0" d="M210,11 v-10 l-3,3 m6,0 l-3,-3" transform="rotate(225 210 6)" />
                <circle cx="210" cy="30" r="12" />
                <path data-tier="1" d="M210,35 v-10 l-3,3 m6,0 l-3,-3" transform="rotate(45 210 30)" />
                <circle cx="210" cy="75" r="12" />
                <path data-tier="2" d="M210,80 v-10 l-3,3 m6,0 l-3,-3" transform="rotate(225 210 75)" />
                <circle cx="210" cy="130" r="12" />
                <path data-tier="3" d="M210,135 v-10 l-3,3 m6,0 l-3,-3" transform="rotate(315 210 130)" />
                <circle cx="210" cy="173" r="12" />
                <path data-tier="4" d="M210,178 v-10 l-3,3 m6,0 l-3,-3" transform="rotate(135 210 173)" />
                <circle cx="210" cy="194" r="12" />
                <path data-tier="5" d="M210,199 v-10 l-3,3 m6,0 l-3,-3" transform="rotate(315 210 194)" />
              </g>
              <g id="globaAxisLabels">
                <text x="82%" y="-4%">wind</text>
                <text x="-8%" y="-4%">latitude</text>
              </g>
              <g id="globeLatLabels">
                <text x="-15" y="5">90°</text>
                <text x="-15" y="18">60°</text>
                <text x="-15" y="53">30°</text>
                <text x="-15" y="103">0°</text>
                <text x="-15" y="153">30°</text>
                <text x="-15" y="190">60°</text>
                <text x="-15" y="204">90°</text>
              </g>
              <circle id="globeGradient" cx="100" cy="100" r="100" fill="url(#temperatureGradient)" stroke="none" />
              <line id="globePrimeMeridian" x1="100" x2="100" y1="0" y2="200" />
              <line id="globeEquator" x1="1" x2="200" y1="100" y2="100" />
              <circle id="globeOutline" cx="100" cy="100" r="100" fill="none" />
              <path id="globeGraticule" />
              <path id="globeArea" />
            </svg>

            <button id="restoreWinds" data-tip="Click to restore default (Earth-based) wind directions">
              Restore winds
            </button>
          </div>
        </div>

        <div style="margin-top: 0.3em">
          <i>Presets:</i>
          <button id="wcWholeWorld" data-tip="Click to set map size to cover the whole world">Whole world</button>
          <button id="wcNorthern" data-tip="Click to set map size to cover the Northern latitudes">Northern</button>
          <button id="wcTropical" data-tip="Click to set map size to cover the Tropical latitudes">Tropical</button>
          <button id="wcSouthern" data-tip="Click to set map size to cover the Southern latitudes">Southern</button>
        </div>
      </div>

      <div id="labelEditor" class="dialog" style="display: none">
        <button id="labelGroupShow" data-tip="Show the group selection" class="icon-tags"></button>
        <div id="labelGroupSection" style="display: none">
          <button id="labelGroupHide" data-tip="Hide the group selection" class="icon-tags"></button>
          <select id="labelGroupSelect" data-tip="Select a group for this label" style="width: 10em"></select>
          <input
            id="labelGroupInput"
            placeholder="new group name"
            data-tip="Provide a name for the new group"
            style="display: none; width: 10em"
          />
          <span id="labelGroupNew" data-tip="Create a new group for this label" class="icon-plus pointer"></span>
          <span
            id="labelGroupRemove"
            data-tip="Remove the Group with all labels"
            class="icon-trash-empty pointer"
          ></span>
        </div>

        <button id="labelTextShow" data-tip="Show the edit label text section" class="icon-pencil"></button>
        <div id="labelTextSection" style="display: none">
          <button id="labelTextHide" data-tip="Hide the edit label text section" class="icon-pencil"></button>
          <input
            id="labelText"
            data-tip='Type to change the label. Enter "|" to move to a new line'
            style="width: 12em"
          />
          <span data-tip="Speak the name. You can change voice and language in options" class="speaker">🔊</span>
          <span id="labelTextRandom" data-tip="Generate random name" class="icon-shuffle pointer"></span>
        </div>

        <button id="labelEditStyle" data-tip="Edit label group style in Style Editor" class="icon-brush"></button>

        <button id="labelSizeShow" data-tip="Show the font size section" class="icon-text-height"></button>
        <div id="labelSizeSection" style="display: none">
          <button id="labelSizeHide" data-tip="Hide the font size section" class="icon-text-height"></button>
          <input
            id="labelStartOffset"
            data-tip="Set starting offset for the particular label"
            type="range"
            min="20"
            max="80"
            style="width: 8em"
          />
          <i class="icon-text-height"></i>
          <input
            id="labelRelativeSize"
            data-tip="Set relative size for the particular label"
            type="number"
            min="30"
            max="300"
            step="1"
            style="width: 4.5em"
          />
        </div>

        <button id="labelLetterSpacingShow" data-tip="Show the letter spacing section" class="icon-text-width"></button>
        <div id="labelLetterSpacingSection" style="display: none">
          <button
            id="labelLetterSpacingHide"
            data-tip="Hide the letter spacing section"
            class="icon-text-width"
          ></button>
          <slider-input
            id="labelLetterSpacingSize"
            style="display: inline-block"
            data-tip="Set the letter spacing size for this label"
            min="0"
            max="20"
            step=".01"
            value="0"
          ></slider-input>
        </div>

        <button id="labelAlign" data-tip="Turn text path into a straight line" class="icon-resize-horizontal"></button>
        <button id="labelLegend" data-tip="Edit free text notes (legend) for this label" class="icon-edit"></button>
        <button
          id="labelRemoveSingle"
          data-tip="Remove the label"
          data-shortcut="Delete"
          class="icon-trash fastDelete"
        ></button>
      </div>

      <div id="riverEditor" class="dialog" style="display: none">
        <div id="riverBody" style="padding-bottom: 0.3em">
          <div>
            <div class="label" style="width: 4.8em">Name:</div>
            <span
              id="riverNameCulture"
              data-tip="Generate culture-specific name for the river"
              class="icon-book pointer"
            ></span>
            <span id="riverNameRandom" data-tip="Generate random name for the river" class="icon-globe pointer"></span>
            <input id="riverName" data-tip="Type to rename the river" autocorrect="off" spellcheck="false" />
            <span data-tip="Speak the name. You can change voice and language in options" class="speaker">🔊</span>
          </div>

          <div data-tip="Type to change river type (e.g. fork, creek, river, brook, stream)">
            <div class="label">Type:</div>
            <input id="riverType" autocorrect="off" spellcheck="false" />
          </div>

          <div data-tip="Select parent river">
            <div class="label">Mainstem:</div>
            <select id="riverMainstem"></select>
          </div>

          <div data-tip="River drainage basin (watershed)">
            <div class="label">Basin:</div>
            <input id="riverBasin" disabled />
          </div>

          <div data-tip="River discharge (flux power)">
            <div class="label">Discharge:</div>
            <input id="riverDischarge" disabled />
          </div>

          <div data-tip="River length in selected units">
            <div class="label">Length:</div>
            <input id="riverLength" disabled />
          </div>

          <div data-tip="River mouth width in selected units">
            <div class="label">Mouth width:</div>
            <input id="riverWidth" disabled />
          </div>

          <div data-tip="River source additional width. Default value is 0">
            <div class="label">Source width:</div>
            <input id="riverSourceWidth" type="number" min="0" max="3" step=".01" />
          </div>

          <div data-tip="River width multiplier. Default value is 1">
            <div class="label">Width modifier:</div>
            <input id="riverWidthFactor" type="number" min=".1" max="4" step=".1" />
          </div>
        </div>

        <div id="riverBottom">
          <button
            id="riverCreateSelectingCells"
            data-tip="Create a new river selecting river cells"
            class="icon-map-pin"
          ></button>
          <button id="riverEditStyle" data-tip="Edit style for all rivers in Style Editor" class="icon-brush"></button>
          <button
            id="riverElevationProfile"
            data-tip="Show the elevation profile for the river"
            class="icon-chart-area"
          ></button>
          <button id="riverLegend" data-tip="Edit free text notes (legend) for the river" class="icon-edit"></button>
          <button
            id="riverRemove"
            data-tip="Remove river"
            data-shortcut="Delete"
            class="icon-trash fastDelete"
          ></button>
        </div>
      </div>

      <div id="riverCreator" class="dialog" style="display: none">
        <div id="riverCreatorBody" class="table"></div>
        <div id="riverCreatorBottom">
          <button id="riverCreatorComplete" data-tip="Complete river creation" class="icon-check"></button>
          <button id="riverCreatorCancel" data-tip="Cancel the creation" class="icon-cancel"></button>
        </div>
      </div>

      <div id="lakeEditor" class="dialog" style="display: none">
        <div id="lakeBody" style="padding-bottom: 0.3em">
          <div>
            <div class="label" style="width: 4.8em">Name:</div>
            <span
              id="lakeNameCulture"
              data-tip="Generate culture-specific name for the lake"
              class="icon-book pointer"
            ></span>
            <span id="lakeNameRandom" data-tip="Generate random name for the lake" class="icon-globe pointer"></span>
            <input id="lakeName" data-tip="Type to rename the lake" autocorrect="off" spellcheck="false" />
            <span data-tip="Speak the name. You can change voice and language in options" class="speaker">🔊</span>
          </div>

          <div data-tip="Type to change lake type (group)">
            <div class="label" style="width: 4.8em">Type:</div>
            <span id="lakeGroupRemove" data-tip="Remove the group" class="icon-trash-empty pointer"></span>
            <span id="lakeGroupAdd" data-tip="Create a new type (group) for the lake" class="icon-plus pointer"></span>
            <select id="lakeGroup" data-tip="Select lake type (group)"></select>
            <input
              id="lakeGroupName"
              placeholder="type name"
              data-tip="Provide a name for the new group"
              style="display: none"
            />
            <span id="lakeEditStyle" data-tip="Edit lake group style in Style Editor" class="icon-brush pointer"></span>
          </div>

          <div data-tip="Lake area in selected units">
            <div class="label">Area:</div>
            <input id="lakeArea" disabled />
          </div>

          <div data-tip="Lake shore length in selected units">
            <div class="label">Shore length:</div>
            <input id="lakeShoreLength" disabled />
          </div>

          <div data-tip="Lake elevation in selected units">
            <div class="label">Elevation:</div>
            <input id="lakeElevation" disabled />
          </div>

          <div data-tip="Lake average depth in selected units">
            <div class="label">Average depth:</div>
            <input id="lakeAverageDepth" disabled />
          </div>

          <div data-tip="Lake maximum depth in selected units">
            <div class="label">Max depth:</div>
            <input id="lakeMaxDepth" disabled />
          </div>

          <div
            data-tip="Lake water supply. If supply > evaporation and there is an outlet, the lake water is fresh. If supply is very low, the lake becomes dry"
          >
            <div class="label">Supply:</div>
            <input id="lakeFlux" disabled />
          </div>

          <div
            data-tip="Evaporation from lake surface. If evaporation > supply, the lake water is saline. If difference is high, the lake becomes dry"
          >
            <div class="label">Evaporation:</div>
            <input id="lakeEvaporation" disabled />
          </div>

          <div data-tip="Number of lake inlet rivers">
            <div class="label">Inlets:</div>
            <input id="lakeInlets" disabled />
          </div>

          <div data-tip="Lake outlet river">
            <div class="label">Outlet:</div>
            <input id="lakeOutlet" disabled />
          </div>
        </div>

        <div id="lakeBottom">
          <button id="lakeLegend" data-tip="Edit free text notes (legend) for the lake" class="icon-edit"></button>
        </div>
      </div>

      <div id="elevationProfile" class="dialog" style="display: none" width="100%">
        <div id="elevationGraph" data-tip="Elevation profile"></div>
        <div style="text-align: center">
          <div id="epControls">
            <span data-tip="Set height scale"
              >Height scale: <input id="epScaleRange" type="range" min="1" max="100" value="50"
            /></span>
            <span data-tip="Set curve profile"
              >Curve:
              <select id="epCurve">
                <option>Linear</option>
                <option selected>Basis spline</option>
                <option>Bundle</option>
                <option>Cubic Catmull-Rom</option>
                <option>Monotone X</option>
                <option>Natural</option>
              </select>
            </span>
            <span
              ><button id="epSave" data-tip="Download the chart data as a CSV file" class="icon-download"></button
            ></span>
          </div>
        </div>
      </div>

      <div id="routeEditor" class="dialog" style="display: none">
        <div id="routeBody" style="padding-bottom: 0.3em">
          <div>
            <div class="label">Name:</div>
            <input id="routeName" data-tip="Type to rename the route" autocorrect="off" spellcheck="false" />
            <span data-tip="Speak the name. You can change voice and language in options" class="speaker">🔊</span>
            <span id="routeGenerateName" data-tip="Generate route name" class="icon-globe pointer"></span>
          </div>

          <div data-tip="Select route group">
            <div class="label">Group:</div>
            <select id="routeGroup"></select>
            <span id="routeGroupEdit" data-tip="Edit route groups" class="icon-pencil pointer"></span>
            <span id="routeEditStyle" data-tip="Edit style for the route group" class="icon-brush pointer"></span>
          </div>

          <div data-tip="Route length in selected units">
            <div class="label">Length:</div>
            <input id="routeLength" disabled />
          </div>
        </div>

        <div id="routeBottom">
          <button
            id="routeCreateSelectingCells"
            data-tip="Create a new route selecting route cells"
            class="icon-map-pin"
          ></button>
          <button
            id="routeJoin"
            data-tip="Click to join the route to another route that starts or ends at the same cell"
            class="icon-link"
          ></button>
          <button
            id="routeSplit"
            data-tip="Click on a control point to split the route there"
            class="icon-unlink"
          ></button>
          <button
            id="routeElevationProfile"
            data-tip="Show the elevation profile for the route"
            class="icon-chart-area"
          ></button>
          <button id="routeLegend" data-tip="Edit free text notes (legend) for the route" class="icon-edit"></button>
          <button id="routeLock" class="icon-lock-open" onmouseover="showElementLockTip(event)"></button>
          <button
            id="routeRemove"
            data-tip="Remove route"
            data-shortcut="Delete"
            class="icon-trash fastDelete"
          ></button>
        </div>
      </div>

      <div id="routeCreator" class="dialog" style="display: none">
        <div>Click on map to add/remove route points</div>
        <div id="routeCreatorBody" class="table" style="margin: 0.3em 0"></div>
        <div id="routeCreatorBottom">
          <button id="routeCreatorComplete" data-tip="Complete route creation" class="icon-check"></button>
          <button id="routeCreatorCancel" data-tip="Cancel the creation" class="icon-cancel"></button>
          <div style="display: inline-block">
            Group:
            <select id="routeCreatorGroupSelect"></select>
            <span id="routeCreatorGroupEdit" data-tip="Edit route groups" class="icon-pencil pointer"></span>
          </div>
        </div>
      </div>

      <div id="routeGroupsEditor" class="dialog" style="display: none">
        <div id="routeGroupsEditorBody" class="table" style="padding: 0.3em 0; width: 100%"></div>
        <div id="routeGroupsEditorBottom">
          <button id="routeGroupsEditorAdd" data-tip="Add route group" class="icon-plus"></button>
        </div>
      </div>

      <div id="iceEditor" class="dialog" style="display: none">
        <button id="iceEditStyle" data-tip="Edit style in Style Editor" class="icon-brush"></button>
        <button id="iceRandomize" data-tip="Randomize Iceberg shape" class="icon-shuffle"></button>
        <input id="iceSize" data-tip="Change Iceberg size" type="range" min=".05" max="2" step=".01" />
        <button id="iceNew" data-tip="Add an Iceberg (click on map)" class="icon-plus"></button>
        <button
          id="iceRemove"
          data-tip="Remove the element"
          data-shortcut="Delete"
          class="icon-trash fastDelete"
        ></button>
      </div>

      <div id="coastlineEditor" class="dialog" style="display: none">
        <button id="coastlineGroupsShow" data-tip="Show the group selection" class="icon-tags"></button>
        <div id="coastlineGroupsSelection" style="display: none">
          <button id="coastlineGroupsHide" data-tip="Hide the group section" class="icon-tags"></button>
          <select id="coastlineGroup" data-tip="Select a group for this coastline" style="width: 9em"></select>
          <input
            id="coastlineGroupName"
            placeholder="new group name"
            data-tip="Provide a name for the new group"
            style="display: none; width: 9em"
          />
          <span
            id="coastlineGroupAdd"
            data-tip="Create a new group for this coastline"
            class="icon-plus pointer"
          ></span>
          <span id="coastlineGroupRemove" data-tip="Remove the group" class="icon-trash-empty pointer"></span>
        </div>

        <button
          id="coastlineEditStyle"
          data-tip="Edit coastline group style in Style Editor"
          class="icon-brush"
        ></button>
        <button id="coastlineArea" data-tip="Landmass area in selected units">0</button>
      </div>

      <div id="reliefEditor" class="dialog" style="display: none">
        <div id="reliefTools" data-tip="Select mode of operation">
          <div class="reliefEditorLabel">Mode:</div>
          <button id="reliefIndividual" data-tip="Edit individual selected icon" class="icon-info pressed"></button>
          <button id="reliefBulkAdd" data-tip="Place icons in a bulk" class="icon-brush"></button>
          <button id="reliefBulkRemove" data-tip="Remove icons in a bulk" class="icon-eraser"></button>

          <div style="margin-left: 4.6em">Set:</div>
          <select id="reliefEditorSet">
            <option value="simple">Simple</option>
            <option value="colored">Colored</option>
            <option value="gray">Gray</option>
          </select>
        </div>

        <div id="reliefSizeDiv" data-tip="Set icon size for individual icon or for bulk placement">
          <div class="reliefEditorLabel">Size:</div>
          <input
            id="reliefSize"
            oninput="reliefSizeNumber.value = this.value"
            type="range"
            min="2"
            max="50"
            value="5"
          />
          <input id="reliefSizeNumber" oninput="reliefSize.value = this.value" type="number" min="2" value="5" />
        </div>

        <div id="reliefRadiusDiv" data-tip="Set brush radius for icons placement on deletion" style="display: none">
          <div class="reliefEditorLabel">Radius:</div>
          <input
            id="reliefRadius"
            oninput="reliefRadiusNumber.value = this.value"
            type="range"
            min="1"
            max="100"
            value="15"
          />
          <input id="reliefRadiusNumber" oninput="reliefRadius.value = this.value" type="number" min="1" value="15" />
        </div>

        <div id="reliefSpacingDiv" data-tip="Set spacing between relief icons" style="display: none">
          <div class="reliefEditorLabel">Spacing:</div>
          <input
            id="reliefSpacing"
            oninput="reliefSpacingNumber.value = this.value"
            type="range"
            min="2"
            max="20"
            value="5"
          />
          <input id="reliefSpacingNumber" oninput="reliefSpacing.value = this.value" type="number" min="2" value="5" />
        </div>

        <div id="reliefIconsDiv" data-tip="Select icon">
          <div data-type="simple" style="display: none">
            <svg data-type="#relief-mount-1" data-tip="Select Mountain icon">
              <use href="#relief-mount-1" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-hill-1" data-tip="Select Hill icon">
              <use href="#relief-hill-1" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-deciduous-1" data-tip="Select Deciduous Tree icon">
              <use href="#relief-deciduous-1" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-conifer-1" data-tip="Select Conifer Tree icon">
              <use href="#relief-conifer-1" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-palm-1" data-tip="Select Palm icon">
              <use href="#relief-palm-1" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-acacia-1" data-tip="Select Acacia icon">
              <use href="#relief-acacia-1" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-swamp-1" data-tip="Select Swamp icon">
              <use href="#relief-swamp-1" x="-50%" y="-50%" width="80" height="80"></use>
            </svg>
            <svg data-type="#relief-grass-1" data-tip="Select Grass icon">
              <use href="#relief-grass-1" x="-100%" y="-100%" width="120" height="120"></use>
            </svg>
            <svg data-type="#relief-dune-1" data-tip="Select Dune icon">
              <use href="#relief-dune-1" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
          </div>

          <div data-type="colored" style="display: none">
            <svg data-type="#relief-mount-2" data-tip="Select Mountain icon">
              <use href="#relief-mount-2" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mount-3" data-tip="Select Mountain icon">
              <use href="#relief-mount-3" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mount-4" data-tip="Select Mountain icon">
              <use href="#relief-mount-4" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mount-5" data-tip="Select Mountain icon">
              <use href="#relief-mount-5" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mount-6" data-tip="Select Mountain icon">
              <use href="#relief-mount-6" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mount-7" data-tip="Select Mountain icon">
              <use href="#relief-mount-7" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mountSnow-1" data-tip="Select Snow Mountain icon">
              <use href="#relief-mountSnow-1" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mountSnow-2" data-tip="Select Snow Mountain icon">
              <use href="#relief-mountSnow-2" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mountSnow-3" data-tip="Select Snow Mountain icon">
              <use href="#relief-mountSnow-3" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mountSnow-4" data-tip="Select Snow Mountain icon">
              <use href="#relief-mountSnow-4" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mountSnow-5" data-tip="Select Snow Mountain icon">
              <use href="#relief-mountSnow-5" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mountSnow-6" data-tip="Select Snow Mountain icon">
              <use href="#relief-mountSnow-6" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-vulcan-1" data-tip="Select Volcano icon">
              <use href="#relief-vulcan-1" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-vulcan-2" data-tip="Select Volcano icon">
              <use href="#relief-vulcan-2" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-vulcan-3" data-tip="Select Volcano icon">
              <use href="#relief-vulcan-3" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-hill-2" data-tip="Select Hill icon">
              <use href="#relief-hill-2" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-hill-3" data-tip="Select Hill icon">
              <use href="#relief-hill-3" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-hill-4" data-tip="Select Hill icon">
              <use href="#relief-hill-4" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-hill-5" data-tip="Select Hill icon">
              <use href="#relief-hill-5" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-dune-2" data-tip="Select Dune icon">
              <use href="#relief-dune-2" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-deciduous-2" data-tip="Select Deciduous Tree icon">
              <use href="#relief-deciduous-2" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-deciduous-3" data-tip="Select Deciduous Tree icon">
              <use href="#relief-deciduous-3" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-conifer-2" data-tip="Select Conifer Tree icon">
              <use href="#relief-conifer-2" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-coniferSnow-1" data-tip="Select Snow Conifer Tree icon">
              <use href="#relief-coniferSnow-1" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-acacia-2" data-tip="Select Acacia icon">
              <use href="#relief-acacia-2" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-palm-2" data-tip="Select Palm icon">
              <use href="#relief-palm-2" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-grass-2" data-tip="Select Grass icon">
              <use href="#relief-grass-2" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-swamp-2" data-tip="Select Swamp icon">
              <use href="#relief-swamp-2" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-swamp-3" data-tip="Select Swamp icon">
              <use href="#relief-swamp-3" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-cactus-1" data-tip="Select Cactus icon">
              <use href="#relief-cactus-1" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-cactus-2" data-tip="Select Cactus icon">
              <use href="#relief-cactus-2" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-cactus-3" data-tip="Select Cactus icon">
              <use href="#relief-cactus-3" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-deadTree-1" data-tip="Select Dead Tree icon">
              <use href="#relief-deadTree-1" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-deadTree-2" data-tip="Select Dead Tree icon">
              <use href="#relief-deadTree-2" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
          </div>

          <div data-type="gray" style="display: none">
            <svg data-type="#relief-mount-2-bw" data-tip="Select Mountain icon">
              <use href="#relief-mount-2-bw" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mount-3-bw" data-tip="Select Mountain icon">
              <use href="#relief-mount-3-bw" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mount-4-bw" data-tip="Select Mountain icon">
              <use href="#relief-mount-4-bw" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mount-5-bw" data-tip="Select Mountain icon">
              <use href="#relief-mount-5-bw" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mount-6-bw" data-tip="Select Mountain icon">
              <use href="#relief-mount-6-bw" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mount-7-bw" data-tip="Select Mountain icon">
              <use href="#relief-mount-7-bw" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mountSnow-1-bw" data-tip="Select Snow Mountain icon">
              <use href="#relief-mountSnow-1-bw" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mountSnow-2-bw" data-tip="Select Snow Mountain icon">
              <use href="#relief-mountSnow-2-bw" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mountSnow-3-bw" data-tip="Select Snow Mountain icon">
              <use href="#relief-mountSnow-3-bw" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mountSnow-4-bw" data-tip="Select Snow Mountain icon">
              <use href="#relief-mountSnow-4-bw" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mountSnow-5-bw" data-tip="Select Snow Mountain icon">
              <use href="#relief-mountSnow-5-bw" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-mountSnow-6-bw" data-tip="Select Snow Mountain icon">
              <use href="#relief-mountSnow-6-bw" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-vulcan-1-bw" data-tip="Select Volcano icon">
              <use href="#relief-vulcan-1-bw" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-vulcan-2-bw" data-tip="Select Volcano icon">
              <use href="#relief-vulcan-2-bw" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-vulcan-3-bw" data-tip="Select Volcano icon">
              <use href="#relief-vulcan-3-bw" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-hill-2-bw" data-tip="Select Hill icon">
              <use href="#relief-hill-2-bw" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-hill-3-bw" data-tip="Select Hill icon">
              <use href="#relief-hill-3-bw" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-hill-4-bw" data-tip="Select Hill icon">
              <use href="#relief-hill-4-bw" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-hill-5-bw" data-tip="Select Hill icon">
              <use href="#relief-hill-5-bw" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-dune-2-bw" data-tip="Select Dune icon">
              <use href="#relief-dune-2-bw" width="40" height="40"></use>
            </svg>
            <svg data-type="#relief-deciduous-2-bw" data-tip="Select Deciduous Tree icon">
              <use href="#relief-deciduous-2-bw" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-deciduous-3-bw" data-tip="Select Deciduous Tree icon">
              <use href="#relief-deciduous-3-bw" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-conifer-2-bw" data-tip="Select Conifer Tree icon">
              <use href="#relief-conifer-2-bw" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-coniferSnow-1-bw" data-tip="Select Snow Conifer Tree icon">
              <use href="#relief-coniferSnow-1-bw" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-acacia-2-bw" data-tip="Select Acacia icon">
              <use href="#relief-acacia-2-bw" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-palm-2-bw" data-tip="Select Palm icon">
              <use href="#relief-palm-2-bw" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-grass-2-bw" data-tip="Select Grass icon">
              <use href="#relief-grass-2-bw" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-swamp-2-bw" data-tip="Select Swamp icon">
              <use href="#relief-swamp-2-bw" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-swamp-3-bw" data-tip="Select Swamp icon">
              <use href="#relief-swamp-3-bw" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-cactus-1-bw" data-tip="Select Cactus icon">
              <use href="#relief-cactus-1-bw" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-cactus-2-bw" data-tip="Select Cactus icon">
              <use href="#relief-cactus-2-bw" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-cactus-3-bw" data-tip="Select Cactus icon">
              <use href="#relief-cactus-3-bw" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-deadTree-1-bw" data-tip="Select Dead Tree icon">
              <use href="#relief-deadTree-1-bw" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
            <svg data-type="#relief-deadTree-2-bw" data-tip="Select Dead Tree icon">
              <use href="#relief-deadTree-2-bw" x="-25%" y="-25%" width="60" height="60"></use>
            </svg>
          </div>

          <svg id="reliefIconsSeletionAny" data-tip="Select any type of icons"><text x="50%" y="50%">Any</text></svg>
        </div>

        <div id="reliefBottom">
          <button id="reliefEditStyle" data-tip="Edit Relief Icons style in Style Editor" class="icon-adjust"></button>
          <button id="reliefCopy" data-tip="Copy selected relief icon" class="icon-clone"></button>
          <button id="reliefMoveFront" data-tip="Move selected relief icon to front" class="icon-level-up"></button>
          <button id="reliefMoveBack" data-tip="Move selected relief icon back" class="icon-level-down"></button>
          <button
            id="reliefRemove"
            data-tip="Remove selected relief icon or icon type"
            data-shortcut="Delete"
            class="icon-trash fastDelete"
          ></button>
        </div>
      </div>

      <div id="burgEditor" class="dialog" style="display: none">
        <div id="burgBody" style="padding-bottom: 0.3em">
          <div style="display: flex; align-items: center">
            <svg data-tip="Burg emblem. Click to edit" class="pointer" viewBox="0 0 200 200" width="13em" height="13em">
              <use id="burgEmblem"></use>
            </svg>
            <div style="display: grid; grid-auto-rows: minmax(1.6em, auto)">
              <div id="burgProvinceAndState" style="font-weight: bold; max-width: 16em"></div>

              <div>
                <div class="label">Name:</div>
                <input
                  id="burgName"
                  data-tip="Type to rename the burg"
                  autocorrect="off"
                  spellcheck="false"
                  style="width: 9em"
                />
                <span data-tip="Speak the name. You can change voice and language in options" class="speaker">🔊</span>
                <span
                  id="burgNameReRandom"
                  data-tip="Generate random name for the burg"
                  class="icon-globe pointer"
                ></span>
              </div>

              <div data-tip="Select burg type. Type slightly affects emblem generation">
                <div class="label">Type:</div>
                <select id="burgType" style="width: 9em">
                  <option value="Generic">Generic</option>
                  <option value="River">River</option>
                  <option value="Lake">Lake</option>
                  <option value="Naval">Naval</option>
                  <option value="Nomadic">Nomadic</option>
                  <option value="Hunting">Hunting</option>
                  <option value="Highland">Highland</option>
                </select>
              </div>

              <div data-tip="Select dominant culture">
                <div class="label">Culture:</div>
                <select id="burgCulture" style="width: 9em"></select>
                <span
                  id="burgNameReCulture"
                  data-tip="Generate culture-specific name for the burg"
                  class="icon-book pointer"
                ></span>
              </div>

              <div data-tip="Set burg population">
                <div class="label">Population:</div>
                <input id="burgPopulation" type="number" min="0" step="1" style="width: 9em" />
              </div>

              <div data-tip="Burg average yearly temperature" style="display: flex; justify-content: space-between">
                <div>
                  <div class="label">Temperature:</div>
                  <span id="burgTemperature"></span>
                </div>
                <div style="display: flex; gap: 0.5em">
                  <i class="icon-info-circled" id="burgTemperatureLikeIn"></i>
                  <i
                    id="burgTemperatureGraph"
                    data-tip="Show temperature graph for the burg"
                    class="icon-chart-area pointer"
                  ></i>
                </div>
              </div>

              <div data-tip="Burg height above mean sea level">
                <div class="label">Elevation:</div>
                <span id="burgElevation"></span> above sea level
              </div>

              <div>
                <div class="label">Features:</div>
                <span
                  id="burgCapital"
                  data-tip="Shows whether the burg is a state capital. Click to toggle"
                  data-feature="capital"
                  class="burgFeature icon-star"
                ></span>
                <span
                  id="burgPort"
                  data-tip="Shows whether the burg is a port. Click to toggle"
                  data-feature="port"
                  class="burgFeature icon-anchor"
                ></span>
                <span
                  id="burgCitadel"
                  data-tip="Shows whether the burg has a citadel (castle). Click to toggle"
                  data-feature="citadel"
                  class="burgFeature icon-chess-rook"
                  style="font-size: 1.1em"
                ></span>
                <span
                  id="burgWalls"
                  data-tip="Shows whether the burg is walled. Click to toggle"
                  data-feature="walls"
                  class="burgFeature icon-fort-awesome"
                ></span>
                <span
                  id="burgPlaza"
                  data-tip="Shows whether the burg is a trade center (has big marketplace). Click to toggle"
                  data-feature="plaza"
                  class="burgFeature icon-store"
                  style="font-size: 1em"
                ></span>
                <span
                  id="burgTemple"
                  data-tip="Shows whether the burg is a religious center. Click to toggle"
                  data-feature="temple"
                  class="burgFeature icon-chess-bishop"
                  style="font-size: 1.1em; margin-left: 3px"
                ></span>
                <span
                  id="burgShanty"
                  data-tip="Shows whether the burg has a shanty town. Click to toggle"
                  data-feature="shanty"
                  class="burgFeature icon-campground"
                  style="font-size: 1em"
                ></span>
              </div>
            </div>
          </div>

          <div id="burgPreviewSection" data-tip="Burg map preview" style="display: flex; flex-direction: column">
            <div style="display: flex; justify-content: space-between">
              <span>Burg preview:</span>
              <div style="display: flex; gap: 0.5em">
                <i
                  id="burgLinkEdit"
                  data-tip="Provide custom link to the burg map"
                  class="icon-pencil pointer"
                  style="margin-top: -0.1em"
                ></i>
                <i id="burgLinkOpen" data-tip="Open burg map in a new tab" class="icon-link-ext pointer"></i>
              </div>
            </div>
            <div id="burgPreviewObject" style="pointer-events: none"></div>
          </div>
        </div>

        <div id="burgBottom">
          <button id="burgGroupShow" data-tip="Show group change section" class="icon-tags"></button>
          <div id="burgGroupSection" style="display: none">
            <button id="burgGroupHide" data-tip="Hide group change section" class="icon-tags"></button>
            <select id="burgSelectGroup" data-tip="Select a group for this burg" style="width: 10em"></select>
            <input
              id="burgInputGroup"
              placeholder="new group name"
              data-tip="Create a new Group for the Burg"
              style="display: none; width: 10em"
            />
            <i id="burgAddGroup" data-tip="Create a new group for the burg" class="icon-plus pointer"></i>
            <i id="burgRemoveGroup" data-tip="Remove selected burg group" class="icon-trash pointer"></i>
          </div>

          <button id="burgStyleShow" data-tip="Show style edit section" class="icon-brush"></button>
          <div id="burgStyleSection" style="display: none">
            <button id="burgStyleHide" data-tip="Hide style edit section" class="icon-brush"></button>
            <button
              id="burgEditLabelStyle"
              data-tip="Edit label style for burg group in Style Editor"
              class="icon-font"
            ></button>
            <button
              id="burgEditIconStyle"
              data-tip="Edit icon style for burg group in Style Editor"
              class="icon-dot-circled"
            ></button>
            <button
              id="burgEditAnchorStyle"
              data-tip="Edit port icon (anchor) style for burg group in Style Editor"
              class="icon-anchor"
            ></button>
          </div>

          <button id="burgEditEmblem" data-tip="Edit emblem" class="icon-shield-alt"></button>
          <button id="burgTogglePreview" data-tip="Toggle preview" class="icon-map"></button>
          <button id="burgLocate" data-tip="Zoom map and center view in the burg" class="icon-target"></button>
          <button
            id="burgRelocate"
            data-tip="Relocate burg. Click on map to move the burg"
            class="icon-map-pin"
          ></button>
          <button id="burglLegend" data-tip="Edit free text notes (legend) for this burg" class="icon-edit"></button>
          <button id="burgLock" class="icon-lock-open" onmouseover="showElementLockTip(event)"></button>
          <button
            id="burgRemove"
            data-tip="Remove non-capital burg"
            data-shortcut="Delete"
            class="icon-trash fastDelete"
          ></button>
        </div>
      </div>

      <div id="markerEditor" class="dialog" style="display: none">
        <div id="markerBody" style="padding-bottom: 0.3em">
          <div
            data-tip="Marker type. Style changes will apply to all markers of the same type. Leave blank if the marker is unique"
          >
            <div class="label">Type:</div>
            <input id="markerType" style="width: 10.3em" />
          </div>

          <div data-tip="Marker icon" style="display: flex; align-items: center">
            <div class="label">Icon:</div>
            <div id="markerIcon" style="font-size: 1.5em; width: 3.7em">👑</div>
            <button id="markerIconSelect" style="width: 5em">select</button>
          </div>

          <div data-tip="Marker marker element and icon sizes in pixels">
            <div class="label">Size:</div>
            <input
              data-tip="Marker element size in pixels"
              id="markerSize"
              type="number"
              min="2"
              max="500"
              style="width: 5em"
            />
            <input
              data-tip="Marker icon sizes in pixels"
              id="markerIconSize"
              type="number"
              min="2"
              max="20"
              step="0.5"
              style="width: 5em"
            />
          </div>

          <div data-tip="Marker icon shift (by X and by Y axis), percent. Set to 50 to position icon in center">
            <div class="label">Icon shift:</div>
            <input id="markerIconShiftX" type="number" min="0" max="100" step="1" style="width: 5em" />
            <input id="markerIconShiftY" type="number" min="0" max="100" step="1" style="width: 5em" />
          </div>

          <div data-tip="Marker pin shape">
            <div class="label">Pin shape:</div>
            <select id="markerPin" style="width: 10.3em">
              <option value="bubble">Bubble</option>
              <option value="pin">Pin</option>
              <option value="square">Square</option>
              <option value="squarish">Squarish</option>
              <option value="diamond">Diamond</option>
              <option value="hex">Hex</option>
              <option value="hexy">Hexy</option>
              <option value="shieldy">Shieldy</option>
              <option value="shield">Shield</option>
              <option value="pentagon">Pentagon</option>
              <option value="heptagon">Heptagon</option>
              <option value="circle">Circle</option>
              <option value="no">No</option>
            </select>
          </div>

          <div data-tip="Pin fill and stroke colors">
            <div class="label">Pin colors:</div>
            <input id="markerFill" type="color" style="width: 5em; height: 1.6em" />
            <input id="markerStroke" type="color" style="width: 5em; height: 1.6em" />
          </div>
        </div>

        <div id="markerBottom">
          <button id="markerNotes" data-tip="Edit place legend (notes)" class="icon-edit"></button>
          <button id="markerLock" class="icon-lock-open" onmouseover="showElementLockTip(event)"></button>
          <button id="markerAdd" data-tip="Add additional marker of that type" class="icon-plus"></button>
          <button
            id="markerRemove"
            data-tip="Remove the marker"
            data-shortcut="Delete"
            class="icon-trash fastDelete"
          ></button>
        </div>
      </div>

      <div id="regimentEditor" class="dialog" style="display: none">
        <div id="regimentBody" style="padding-bottom: 0.3em">
          <div style="padding-bottom: 0.2em">
            <button id="regimentType" data-tip="Regiment type (land or naval). Click to change"></button>
            <input
              id="regimentName"
              data-tip="Type to rename the regiment"
              autocorrect="off"
              spellcheck="false"
              style="width: 13em"
            />
            <span data-tip="Speak the name. You can change voice and language in options" class="speaker">🔊</span>
            <i
              id="regimentNameRestore"
              data-tip="Click to restore regiment's default name"
              class="icon-ccw pointer"
            ></i>
          </div>

          <div data-tip="Regiment emblem" style="display: flex; align-items: center">
            <div class="label">Emblem:</div>
            <div id="regimentEmblem" style="font-size: 1.5em; width: 3.7em"></div>
            <button id="regimentEmblemChange" style="padding: 0; width: 4.5em">change</button>
          </div>

          <div id="regimentComposition" class="table"></div>
        </div>

        <div id="regimentBottom">
          <button id="regimentAttack" data-tip="Attack foreign regiment" class="icon-target"></button>
          <button id="regimentAdd" data-tip="Create a new regiment or fleet" class="icon-user-plus"></button>
          <button id="regimentSplit" data-tip="Split regiment into 2 separate ones" class="icon-half"></button>
          <button
            id="regimentAttach"
            data-tip="Attach regiment to another one (include this regiment to another one)"
            class="icon-attach"
          ></button>
          <button
            id="regimentRegenerateLegend"
            data-tip="Regenerate legend for this regiment"
            class="icon-retweet"
          ></button>
          <button
            id="regimentLegend"
            data-tip="Edit free text notes (legend) for this regiment"
            class="icon-edit"
          ></button>
          <button
            id="regimentRemove"
            data-tip="Remove regiment"
            data-shortcut="Delete"
            class="icon-trash fastDelete"
          ></button>
        </div>
      </div>

      <div id="battleScreen" class="dialog stable" style="display: none">
        <div id="battleBody">
          <template id="battlePhases_field">
            <button
              data-tip="Skirmish phase. Ranged units excel"
              data-phase="skirmish"
              class="icon-button-skirmish"
            ></button>
            <button data-tip="Melee phase. Melee units excel" data-phase="melee" class="icon-button-melee"></button>
            <button
              data-tip="Pursue phase. Mounted units excel"
              data-phase="pursue"
              class="icon-button-pursue"
            ></button>
            <button
              data-tip="Retreat phase. Units strength reduced"
              data-phase="retreat"
              class="icon-button-retreat"
            ></button>
          </template>

          <template id="battlePhases_naval">
            <button
              data-tip="Shelling phase. Naval artillery bombardment of enemy fleet"
              data-phase="shelling"
              class="icon-button-shelling"
            ></button>
            <button
              data-tip="Boarding phase. Melee units go aboard"
              data-phase="boarding"
              class="icon-button-boarding"
            ></button>
            <button
              data-tip="Сhase phase. Naval units pursue and rarely shell enemy fleet"
              data-phase="chase"
              class="icon-button-chase"
            ></button>
            <button
              data-tip="Withdrawal phase. Naval units try to escape enemy fleet"
              data-phase="withdrawal"
              class="icon-button-withdrawal"
            ></button>
          </template>

          <template id="battlePhases_siege_attackers">
            <button
              data-tip="Blockade phase. Prepare or hold the blockade"
              data-phase="blockade"
              class="icon-button-blockade"
            ></button>
            <button
              data-tip="Bombardment phase. Attack enemy with machinery units"
              data-phase="bombardment"
              class="icon-button-bombardment"
            ></button>
            <button
              data-tip="Storming phase. Storm enemy town. Melee units excel"
              data-phase="storming"
              class="icon-button-storming"
            ></button>
            <button
              data-tip="Looting phase. Plunder the town. Units strength increased"
              data-phase="looting"
              class="icon-button-looting"
            ></button>
            <button
              data-tip="Retreat phase. Units strength reduced"
              data-phase="retreat"
              class="icon-button-retreat"
            ></button>
          </template>

          <template id="battlePhases_siege_defenders">
            <button
              data-tip="Sheltering phase. Hide behind the walls and wait"
              data-phase="sheltering"
              class="icon-button-sheltering"
            ></button>
            <button
              data-tip="Sortie phase. Make a sortie from besieged town. Melee units excel"
              data-phase="sortie"
              class="icon-button-sortie"
            ></button>
            <button
              data-tip="Bombardment phase. Attack enemy with machinery units"
              data-phase="bombardment"
              class="icon-button-bombardment"
            ></button>
            <button
              data-tip="Defense phase. Ranged and melee units excel"
              data-phase="defense"
              class="icon-button-defense"
            ></button>
            <button
              data-tip="Surrendering phase. Give up the defense. Units strength reduced"
              data-phase="surrendering"
              class="icon-button-surrendering"
            ></button>
            <button
              data-tip="Pursue phase. Mounted units excel"
              data-phase="pursue"
              class="icon-button-pursue"
            ></button>
          </template>

          <template id="battlePhases_ambush_attackers">
            <button
              data-tip="Shock phase. Units strength reduced"
              data-phase="shock"
              class="icon-button-shock"
            ></button>
            <button data-tip="Melee phase. Melee units excel" data-phase="melee" class="icon-button-melee"></button>
            <button
              data-tip="Pursue phase. Mounted units excel"
              data-phase="pursue"
              class="icon-button-pursue"
            ></button>
            <button
              data-tip="Retreat phase. Units strength reduced"
              data-phase="retreat"
              class="icon-button-retreat"
            ></button>
          </template>

          <template id="battlePhases_ambush_defenders">
            <button
              data-tip="Surprice attack phase. Units strength increased, ranged units excel"
              data-phase="surprise"
              class="icon-button-surprise"
            ></button>
            <button data-tip="Melee phase. Melee units excel" data-phase="melee" class="icon-button-melee"></button>
            <button
              data-tip="Pursue phase. Mounted units excel"
              data-phase="pursue"
              class="icon-button-pursue"
            ></button>
            <button
              data-tip="Retreat phase. Units strength reduced"
              data-phase="retreat"
              class="icon-button-retreat"
            ></button>
          </template>

          <template id="battlePhases_landing_attackers">
            <button
              data-tip="Landing phase. Amphibious attack. Units are vulnerable against prepared defense"
              data-phase="landing"
              class="icon-button-landing"
            ></button>
            <button data-tip="Melee phase. Melee units excel" data-phase="melee" class="icon-button-melee"></button>
            <button
              data-tip="Pursue phase. Mounted units excel"
              data-phase="pursue"
              class="icon-button-pursue"
            ></button>
            <button data-tip="Flee phase. Units strength reduced" data-phase="flee" class="icon-button-flee"></button>
          </template>

          <template id="battlePhases_landing_defenders">
            <button
              data-tip="Shock phase. Units are not prepared for a defense"
              data-phase="shock"
              class="icon-button-shock"
            ></button>
            <button
              data-tip="Defense phase. Prepared defense. Units strength increased"
              data-phase="defense"
              class="icon-button-defense"
            ></button>
            <button data-tip="Melee phase. Melee units excel" data-phase="melee" class="icon-button-melee"></button>
            <button
              data-tip="Waiting phase. Cannot pursue fleeing naval"
              data-phase="waiting"
              class="icon-button-waiting"
            ></button>
            <button
              data-tip="Pursue phase. Try to intercept fleeing attackers. Mounted units excel"
              data-phase="pursue"
              class="icon-button-pursue"
            ></button>
            <button
              data-tip="Retreat phase. Units strength reduced"
              data-phase="retreat"
              class="icon-button-retreat"
            ></button>
          </template>

          <template id="battlePhases_air">
            <button
              data-tip="Maneuvering phase. Units strength reduced"
              data-phase="maneuvering"
              class="icon-button-maneuvering"
            ></button>
            <button
              data-tip="Dogfight phase. Units strength increased"
              data-phase="dogfight"
              class="icon-button-dogfight"
            ></button>
            <button
              data-tip="Pursue phase. Units strength increased"
              data-phase="pursue"
              class="icon-button-pursue"
            ></button>
            <button
              data-tip="Retreat phase. Units strength reduced"
              data-phase="retreat"
              class="icon-button-retreat"
            ></button>
          </template>

          <div style="font-size: 1.2em; font-weight: bold; width: unset">
            <span>Attackers</span>
            <div style="float: right; font-size: 0.7em">
              <meter
                id="battleMorale_attackers"
                data-tip="Attackers morale: "
                min="0"
                max="100"
                low="33"
                high="66"
                optimum="80"
              ></meter>
              <div
                id="battlePower_attackers"
                data-tip="Attackers strength during this phase. Strength defines dealt damage"
                style="display: inline-block; text-align: center"
                class="icon-button-power"
              ></div>
              <div style="display: inline-block">
                <button id="battlePhase_attackers" style="width: 3.2em"></button>
                <div class="battlePhases" style="display: none"></div>
              </div>
              <button
                id="battleDie_attackers"
                data-tip="Random factor for attackers. Click to re-roll"
                style="padding: 0.1em 0.2em; width: 3.2em"
                class="icon-button-die"
              ></button>
            </div>
          </div>
          <table id="battleAttackers"></table>
          <div style="font-size: 1.2em; font-weight: bold; width: unset">
            <span>Defenders</span>
            <div style="float: right; font-size: 0.7em">
              <meter
                id="battleMorale_defenders"
                data-tip="Defenders morale: "
                min="0"
                max="100"
                low="33"
                high="66"
                optimum="80"
              ></meter>
              <div
                id="battlePower_defenders"
                data-tip="Defenders strength during this phase. Strength defines dealt damage"
                style="display: inline-block; text-align: center"
                class="icon-button-power"
              ></div>
              <div style="display: inline-block">
                <button id="battlePhase_defenders" style="width: 3.2em"></button>
                <div class="battlePhases" style="display: none"></div>
              </div>
              <button
                id="battleDie_defenders"
                data-tip="Random factor for defenders. Click to re-roll"
                style="padding: 0.1em 0.2em; width: 3.2em"
                class="icon-button-die"
              ></button>
            </div>
          </div>
          <table id="battleDefenders"></table>
        </div>

        <div id="battleBottom">
          <button id="battleType" data-tip="Battle type. Click to change"></button>
          <div class="battleTypes" style="display: none">
            <button
              data-tip="Field Battle: a standard type of combat"
              data-type="field"
              class="icon-button-field"
            ></button>
            <button data-tip="Naval Battle: naval units combat" data-type="naval" class="icon-button-naval"></button>
            <button data-tip="Siege: burg blockade and storming" data-type="siege" class="icon-button-siege"></button>
            <button data-tip="Ambush: surprise attack" data-type="ambush" class="icon-button-ambush"></button>
            <button data-tip="Landing: amphibious attack" data-type="landing" class="icon-button-landing"></button>
            <button
              data-tip="Air Battle: maneuring fight of avia units"
              data-type="air"
              class="icon-button-air"
            ></button>
          </div>

          <button id="battleNameShow" data-tip="Set battle name" class="icon-font"></button>
          <div id="battleNameSection" style="display: none">
            <button id="battleNameHide" data-tip="Hide the battle name section" class="icon-font"></button>
            <input id="battleNamePlace" data-tip="Type place name" style="width: 30%" />
            <input id="battleNameFull" data-tip="Type full battle name" style="width: 46%" />
            <button
              id="battleNameCulture"
              data-tip="Generate culture-specific name for place and battle"
              class="icon-book"
            ></button>
            <button
              id="battleNameRandom"
              data-tip="Generate random name for place and battle"
              class="icon-globe"
            ></button>
          </div>

          <button id="battleAddRegiment" data-tip="Add regiment to the battle" class="icon-user-plus"></button>
          <button id="battleRoll" data-tip="Roll dice to update random factor" class="icon-die"></button>
          <button id="battleRun" data-tip="Iterate battle" class="icon-play"></button>
          <button
            id="battleApply"
            data-tip="End battle: apply current results and close the screen"
            class="icon-check"
          ></button>
          <button
            id="battleCancel"
            data-tip="Cancel battle: roll back results and close the screen"
            class="icon-cancel"
          ></button>
          <button id="battleWiki" data-tip="Open Battle Simulation Tutorial" class="icon-info"></button>
        </div>
      </div>

      <div id="regimentSelectorScreen" class="dialog" style="display: none">
        <div id="regimentSelectorHeader" class="header" style="grid-template-columns: 9em 13em 4em 6em">
          <div data-tip="Click to sort by state name" class="sortable alphabetically" data-sortby="state">
            State&nbsp;
          </div>
          <div data-tip="Click to sort by regiment name" class="sortable alphabetically" data-sortby="regiment">
            Regiment&nbsp;
          </div>
          <div data-tip="Click to sort by total military forces" class="sortable" data-sortby="total">Total&nbsp;</div>
          <div
            data-tip="Click to sort by distance to the battlefield"
            class="sortable icon-sort-number-up"
            data-sortby="distance"
          >
            Distance&nbsp;
          </div>
        </div>
        <div id="regimentSelectorBody" class="table"></div>
      </div>

      <div id="brushesPanel" class="dialog stable" style="display: none">
        <div id="brushesButtons" style="display: inline-block">
          <button id="brushRaise" data-tip="Raise brush: increase height of cells in radius by Power value">
            <svg viewBox="15 15 70 70" height="1em" width="1.6em">
              <path d="m20,39 h60 M50,85 v-35 l-12,8 m12,-8 l12,8" fill="none" stroke="#000" stroke-width="5" />
            </svg>
          </button>

          <button
            id="brushElevate"
            data-tip="Elevate brush: drag to gradually increase height of cells in radius by Power value"
          >
            <svg viewBox="15 15 70 70" height="1em" width="1.6em">
              <path
                d="m20,50 q30,-35 60,0 M50,85 v-35 l-12,8 m12,-8 l12,8"
                fill="none"
                stroke="#000"
                stroke-width="5"
              />
            </svg>
          </button>

          <button id="brushLower" data-tip="Lower brush: drag to decrease height of cells in radius by Power value">
            <svg viewBox="15 15 70 70" height="1em" width="1.6em">
              <path d="M50,30 v35 l-12,-8 m12,8 l12,-8 M20,78 h60" fill="none" stroke="#000" stroke-width="5" />
            </svg>
          </button>

          <button
            id="brushDepress"
            data-tip="Depress brush: drag to gradually decrease height of cells in radius by Power value"
          >
            <svg viewBox="15 15 70 70" height="1em" width="1.6em">
              <path d="M50,30 v35 l-12,-8 m12,8 l12,-8 M20,63 q30,35 60,0" fill="none" stroke="#000" stroke-width="5" />
            </svg>
          </button>

          <button
            id="brushAlign"
            data-tip="Align brush: drag to set height of cells in radius to height of the cell at mousepoint"
          >
            <svg viewBox="15 15 70 70" height="1em" width="1.6em">
              <path d="m20,50 h56 m0,20 h-56" fill="none" stroke="#000" stroke-width="5" />
            </svg>
          </button>

          <button
            id="brushSmooth"
            data-tip="Smooth brush: drag to level height of cells in radius to height of adjacent cells"
          >
            <svg viewBox="15 15 70 70" height="1em" width="1.6em">
              <path d="m15,60 q15,-15 30,0 q15,15 35,0" fill="none" stroke="#000" stroke-width="5" />
            </svg>
          </button>

          <button
            id="brushDisrupt"
            data-tip="Disrupt brush: drag to randomize height of cells in radius based on Power value"
          >
            <svg viewBox="15 15 70 70" height="1em" width="1.6em">
              <path d="m15,63 l15,-13 15,20 15,-20 15,19 15,-14" fill="none" stroke="#000" stroke-width="5" />
            </svg>
          </button>

          <button id="brushLine" data-tip="Line: select two points to change heights along the line">
            <svg viewBox="0 -5 100 100" height="1em" width="1.6em">
              <path d="M0 90 L100 10" fill="none" stroke="#000" stroke-width="7"></path>
            </svg>
          </button>
        </div>

        <div id="brushesSliders" style="display: none">
          <div data-tip="Change brush size. Shortcut: + to increase; – to decrease">
            <slider-input id="heightmapBrushRadius" min="1" max="100" value="25">
              <div style="width: 3.5em">Radius:</div>
            </slider-input>
          </div>

          <div data-tip="Change brush power">
            <slider-input id="heightmapBrushPower" min="1" max="10" value="5">
              <div style="width: 3.5em">Power:</div>
            </slider-input>
          </div>
        </div>

        <div id="lineSlider" style="display: none">
          <div data-tip="Change tool power. Shortcut: + to increase; – to decrease">
            <slider-input id="heightmapLinePower" min="-100" max="100" value="30">
              <div style="width: 3.5em">Power:</div>
            </slider-input>
          </div>
        </div>

        <div
          data-tip="Allow brush to change only land cells and hence restrict the coastline modification"
          style="margin-bottom: 0.6em"
        >
          <input id="changeOnlyLand" class="checkbox" type="checkbox" />
          <label for="changeOnlyLand" class="checkbox-label"><i>change only land cells</i></label>
        </div>

        <div id="modifyButtons">
          <button id="undo" data-tip="Undo the latest action (Ctrl + Z)" class="icon-ccw" disabled></button>
          <button id="redo" data-tip="Redo the action (Ctrl + Y)" class="icon-cw" disabled></button>
          <button id="rescaleShow" data-tip="Show rescaler slider" class="icon-exchange"></button>
          <button
            id="rescaleCondShow"
            data-tip="Rescaler: change height if condition is fulfilled"
            class="icon-if"
          ></button>
          <button id="smoothHeights" data-tip="Smooth all heights a bit" class="icon-smooth"></button>
          <button id="disruptHeights" data-tip="Disrupt (randomize) heights a bit" class="icon-disrupt"></button>
          <button id="brushClear" data-tip="Set height for all cells to 0 (erase the map)" class="icon-eraser"></button>
        </div>

        <div id="rescaleSection" style="display: none">
          <button id="rescaleHide" data-tip="Hide rescaler slider" class="icon-exchange"></button>
          <input
            id="rescaler"
            data-tip="Change height for all cells"
            type="range"
            min="-10"
            max="10"
            step="1"
            value="0"
          />
        </div>

        <div
          id="rescaleCondSection"
          data-tip="If height is greater or equal to X and less or equal to Y, then perform an operation Z with operand V"
          style="display: none"
        >
          <button id="rescaleCondHide" data-tip="Hide rescaler" class="icon-if"></button>
          <label>h ≥</label>
          <input id="rescaleLower" value="20" type="number" min="0" max="100" />
          <label>≤</label>
          <input id="rescaleHigher" value="100" type="number" min="1" max="100" />
          <label>⇒</label>
          <select id="conditionSign">
            <option value="multiply" selected>×</option>
            <option value="divide">÷</option>
            <option value="add">+</option>
            <option value="subtract">-</option>
            <option value="exponent">^</option>
          </select>
          <input id="rescaleModifier" type="number" value="0.9" min="0" max="1.5" step="0.01" />
          <button id="rescaleExecute" data-tip="Click to perform an operation" class="icon-play-circled2"></button>
        </div>
      </div>

      <div id="templateEditor" class="dialog stable" style="display: none">
        <div id="templateTop">
          <i>Select template: </i>
          <select id="templateSelect" style="width: 16em" data-prev="templateCustom" data-tip="Select base template">
            <option value="custom" selected>Custom</option>
            <option value="volcano">Volcano</option>
            <option value="highIsland">High Island</option>
            <option value="lowIsland">Low Island</option>
            <option value="continents">Continents</option>
            <option value="archipelago">Archipelago</option>
            <option value="atoll">Atoll</option>
            <option value="mediterranean">Mediterranean</option>
            <option value="peninsula">Peninsula</option>
            <option value="pangea">Pangea</option>
            <option value="isthmus">Isthmus</option>
            <option value="shattered">Shattered</option>
            <option value="taklamakan">Taklamakan</option>
            <option value="oldWorld">Old World</option>
            <option value="fractious">Fractious</option>
          </select>
        </div>
        <div id="templateTools">
          <button data-type="Hill" data-tip="Hill: small blob">H</button>
          <button data-type="Pit" data-tip="Pit: round depression">P</button>
          <button data-type="Range" data-tip="Range: elongated elevation">R</button>
          <button data-type="Trough" data-tip="Trough: elongated depression">T</button>
          <button data-type="Strait" data-tip="Strait: centered vertical or horizontal depression">S</button>
          <button data-type="Mask" data-tip="Mask: lower cells near edges or in map center">M</button>
          <button data-type="Invert" data-tip="Invert heightmap along the axes">I</button>
          <button data-type="Add" data-tip="Add or subtract value from all heights in range">+</button>
          <button data-type="Multiply" data-tip="Multiply all heights in range by factor">*</button>
          <button
            data-type="Smooth"
            data-tip="Smooth the map replacing cell heights by an average values of its neighbors"
          >
            ~
          </button>
        </div>
        <div id="templateBody" data-changed="0" class="table" style="padding: 2px 0">
          <div data-type="Hill">
            <div class="icon-check" data-tip="Click to skip the step"></div>
            <div style="width: 4em">Hill</div>
            <i class="icon-trash-empty pointer" data-tip="Remove the step"></i>
            <i class="icon-resize-vertical" data-tip="Drag to reorder"></i>
            <span
              >y:<input class="templateY" data-tip="Y axis position in percentage (minY-maxY or Y)" value="47-53"
            /></span>
            <span
              >x:<input class="templateX" data-tip="X axis position in percentage (minX-maxX or X)" value="65-75"
            /></span>
            <span
              >h:<input
                class="templateHeight"
                data-tip="Blob maximum height, use hyphen to get a random number in range"
                value="90-100"
            /></span>
            <span
              >n:<input
                class="templateCount"
                data-tip="Blobs to add, use hyphen to get a random number in range"
                value="1"
            /></span>
          </div>
        </div>
        <div id="templateBottom">
          <button id="templateRun" data-tip="Execute the template" class="icon-play-circled2"></button>
          <button id="templateUndo" data-tip="Undo the latest action" class="icon-ccw" disabled></button>
          <button id="templateRedo" data-tip="Redo the action" class="icon-cw" disabled></button>
          <button id="templateSave" data-tip="Download the template as a text file" class="icon-download"></button>
          <button id="templateLoad" data-tip="Open previously downloaded template" class="icon-upload"></button>
          <button
            id="templateCA"
            data-tip="Find or share custom template on Cartography Assets portal"
            class="icon-drafting-compass"
            onclick="openURL('https://cartographyassets.com/asset-category/specific-assets/azgaars-generator/templates')"
          ></button>
          <button
            id="templateTutorial"
            data-tip="Open Template Editor Tutorial"
            class="icon-info"
            onclick="wiki('Heightmap-template-editor')"
          ></button>
          <label
            data-tip="Lock seed (click on lock icon) if you want template to generate the same heightmap each time"
          >
            Seed: <input id="templateSeed" value="" type="number" min="1" max="999999999" step="1" style="width: 8em" />
            <i data-locked="0" id="lock_templateSeed" class="icon-lock-open"></i>
          </label>
        </div>
      </div>

      <div id="imageConverter" class="dialog stable" style="display: none">
        <div id="convertImageButtons">
          <button id="convertImageLoad" data-tip="Load image to convert" class="icon-upload"></button>
          <button
            id="convertAutoLum"
            data-tip="Auto-assign colors based on liminosity (good for monochrome images)"
            class="icon-adjust"
          ></button>
          <button
            id="convertAutoHue"
            data-tip="Auto-assign colors based on hue (good for colored images)"
            class="icon-paint-roller"
          ></button>
          <button
            id="convertAutoFMG"
            data-tip="Auto-assign colors using generator scheme (for exported colored heightmaps)"
            class="icon-layer-group"
          ></button>
          <button id="convertColorsButton" data-tip="Set maximum number of colors" class="icon-signal"></button>
          <input id="convertColors" value="100" style="display: none" />
          <button
            id="convertCancel"
            data-tip="Cancel the conversion. Previous heightmap will be restored"
            class="icon-cancel"
          ></button>
        </div>

        <div data-tip="Set opacity of the loaded image" style="padding-top: 0.4em">
          <i>Overlay opacity:</i><br />
          <input id="convertOverlay" type="range" min="0" max="1" step=".01" value="0" style="width: 12.6em" />
          <input id="convertOverlayNumber" type="number" min="0" max="1" step=".01" value="0" style="width: 4.2em" />
        </div>

        <div data-tip="Select a color below and assign a height value for it" id="colorsSelect" style="display: none">
          <i>Set height: </i>
          <span id="colorsSelectValue"></span>
          <span>(<span id="colorsSelectFriendly">0</span>)</span><br />
          <div id="imageConverterPalette"></div>
        </div>

        <div data-tip="Select a color to re-assign the height value" id="colorsAssigned" style="display: none">
          <i>Assigned colors (<span id="colorsAssignedNumber"></span>):</i>
          <div id="colorsAssignedContainer" class="colorsContainer"></div>
        </div>

        <div data-tip="Select a color to assign a height value" id="colorsUnassigned" style="display: none">
          <i>Unassigned colors (<span id="colorsUnassignedNumber"></span>):</i>
          <div id="colorsUnassignedContainer" class="colorsContainer"></div>
        </div>

        <button
          id="convertComplete"
          data-tip="Complete the conversion. All unassigned colors will be considered as ocean"
          style="margin: 0.4em 0"
          class="glow"
        >
          Complete the conversion
        </button>
      </div>

      <div id="biomesEditor" class="dialog stable" style="display: none">
        <div id="biomesHeader" class="header" style="grid-template-columns: 13em 7em 5em 5em 7em">
          <div data-tip="Click to sort by biome name" class="sortable alphabetically" data-sortby="name">
            Biome&nbsp;
          </div>
          <div data-tip="Click to sort by biome habitability" class="sortable hide" data-sortby="habitability">
            Habitability&nbsp;
          </div>
          <div
            data-tip="Click to sort by biome cells number"
            class="sortable hide icon-sort-number-down"
            data-sortby="cells"
          >
            Cells&nbsp;
          </div>
          <div data-tip="Click to sort by biome area" class="sortable hide" data-sortby="area">Area&nbsp;</div>
          <div data-tip="Click to sort by biome population" class="sortable hide" data-sortby="population">
            Population&nbsp;
          </div>
        </div>

        <div id="biomesBody" class="table" data-type="absolute"></div>

        <div id="biomesFooter" class="totalLine">
          <div data-tip="Number of land biomes" style="margin-left: 12px">
            Biomes:&nbsp;<span id="biomesFooterBiomes">0</span>
          </div>
          <div data-tip="Total land cells number" style="margin-left: 12px">
            Cells:&nbsp;<span id="biomesFooterCells">0</span>
          </div>
          <div data-tip="Total land area" style="margin-left: 12px">
            Land Area:&nbsp;<span id="biomesFooterArea">0</span>
          </div>
          <div data-tip="Total population" style="margin-left: 12px">
            Population:&nbsp;<span id="biomesFooterPopulation">0</span>
          </div>
        </div>

        <div id="biomesBottom">
          <button id="biomesEditorRefresh" data-tip="Refresh the Editor" class="icon-cw"></button>
          <button id="biomesEditStyle" data-tip="Edit biomes style in Style Editor" class="icon-adjust"></button>
          <button id="biomesLegend" data-tip="Toggle Legend box" class="icon-list-bullet"></button>
          <button
            id="biomesPercentage"
            data-tip="Toggle percentage / absolute values views"
            class="icon-percent"
          ></button>
          <button
            id="biomesManually"
            data-tip="Manually re-assign biomes to not follow the default moisture/temperature pattern"
            class="icon-brush"
          ></button>
          <div id="biomesManuallyButtons" style="display: none">
            <div data-tip="Change brush size. Shortcut: + to increase; – to decrease" style="margin-block: 0.3em">
              Brush size:
              <slider-input id="biomesBrush" min="1" max="100" value="15"></slider-input>
            </div>
            <button id="biomesManuallyApply" data-tip="Apply current assignment" class="icon-check"></button>
            <button id="biomesManuallyCancel" data-tip="Cancel assignment" class="icon-cancel"></button>
          </div>
          <button id="biomesAdd" data-tip="Add a custom biome" class="icon-plus"></button>
          <button
            id="biomesRestore"
            data-tip="Restore the defaults and re-define biomes based on current moisture and temperature"
            class="icon-history"
          ></button>
          <button
            id="biomesRegenerateReliefIcons"
            data-tip="Regenerate relief icons based on current biomes and elevation"
            class="icon-tree"
          ></button>
          <button
            id="biomesExport"
            data-tip="Save biomes-related data as a text file (.csv)"
            class="icon-download"
          ></button>
        </div>
      </div>

      <div id="stateNameEditor" class="dialog" data-state="0" style="display: none">
        <div>
          <div data-tip="State short name" class="label">Short name:</div>
          <input
            id="stateNameEditorShort"
            data-tip="Type to change the short name"
            autocorrect="off"
            spellcheck="false"
            style="width: 11em"
          />
          <span data-tip="Speak the name. You can change voice and language in options" class="speaker">🔊</span>
          <span
            id="stateNameEditorShortCulture"
            data-tip="Generate culture-specific name"
            class="icon-book pointer"
          ></span>
          <span id="stateNameEditorShortRandom" data-tip="Generate random name" class="icon-globe pointer"></span>
        </div>

        <div data-tip="Select form name">
          <div data-tip="State form name" class="label">Form name:</div>
          <select id="stateNameEditorSelectForm" style="width: 11em">
            <option value="">blank</option>
            <optgroup label="Monarchy">
              <option value="Beylik">Beylik</option>
              <option value="Despotate">Despotate</option>
              <option value="Dominion">Dominion</option>
              <option value="Duchy">Duchy</option>
              <option value="Emirate">Emirate</option>
              <option value="Empire">Empire</option>
              <option value="Horde">Horde</option>
              <option value="Grand Duchy">Grand Duchy</option>
              <option value="Heptarchy">Heptarchy</option>
              <option value="Khaganate">Khaganate</option>
              <option value="Khanate">Khanate</option>
              <option value="Kingdom">Kingdom</option>
              <option value="Marches">Marches</option>
              <option value="Principality">Principality</option>
              <option value="Satrapy">Satrapy</option>
              <option value="Shogunate">Shogunate</option>
              <option value="Sultanate">Sultanate</option>
              <option value="Tsardom">Tsardom</option>
              <option value="Ulus">Ulus</option>
              <option value="Viceroyalty">Viceroyalty</option>
            </optgroup>
            <optgroup label="Republic">
              <option value="Chancellery">Chancellery</option>
              <option value="City-state">City-state</option>
              <option value="Diarchy">Diarchy</option>
              <option value="Federation">Federation</option>
              <option value="Free City">Free City</option>
              <option value="Most Serene Republic">Most Serene Republic</option>
              <option value="Oligarchy">Oligarchy</option>
              <option value="Protectorate">Protectorate</option>
              <option value="Republic">Republic</option>
              <option value="Tetrarchy">Tetrarchy</option>
              <option value="Trade Company">Trade Company</option>
              <option value="Triumvirate">Triumvirate</option>
            </optgroup>
            <optgroup label="Union">
              <option value="Confederacy">Confederacy</option>
              <option value="Confederation">Confederation</option>
              <option value="Conglomerate">Conglomerate</option>
              <option value="Commonwealth">Commonwealth</option>
              <option value="League">League</option>
              <option value="Union">Union</option>
              <option value="United Hordes">United Hordes</option>
              <option value="United Kingdom">United Kingdom</option>
              <option value="United Provinces">United Provinces</option>
              <option value="United Republic">United Republic</option>
              <option value="United States">United States</option>
              <option value="United Tribes">United Tribes</option>
            </optgroup>
            <optgroup label="Theocracy">
              <option value="Bishopric">Bishopric</option>
              <option value="Brotherhood">Brotherhood</option>
              <option value="Caliphate">Caliphate</option>
              <option value="Diocese">Diocese</option>
              <option value="Divine Duchy">Divine Duchy</option>
              <option value="Divine Grand Duchy">Divine Grand Duchy</option>
              <option value="Divine Principality">Divine Principality</option>
              <option value="Divine Kingdom">Divine Kingdom</option>
              <option value="Divine Empire">Divine Empire</option>
              <option value="Eparchy">Eparchy</option>
              <option value="Exarchate">Exarchate</option>
              <option value="Holy State">Holy State</option>
              <option value="Imamah">Imamah</option>
              <option value="Patriarchate">Patriarchate</option>
              <option value="Theocracy">Theocracy</option>
            </optgroup>
            <optgroup label="Anarchy">
              <option value="Commune">Commune</option>
              <option value="Community">Community</option>
              <option value="Council">Council</option>
              <option value="Free Territory">Free Territory</option>
              <option value="Tribes">Tribes</option>
            </optgroup>
          </select>
          <input
            id="stateNameEditorCustomForm"
            placeholder="type form name"
            data-tip="Enter custom form name"
            style="display: none; width: 11em"
          />
          <span
            id="stateNameEditorAddForm"
            data-tip="Click to add custom state form name to the list"
            class="icon-plus pointer"
          ></span>
        </div>

        <div>
          <div data-tip="State full name" class="label">Full name:</div>
          <input
            id="stateNameEditorFull"
            data-tip="Type to change the full name"
            autocorrect="off"
            spellcheck="false"
            style="width: 11em"
          />
          <span data-tip="Speak the name. You can change voice and language in options" class="speaker">🔊</span>
          <span
            id="stateNameEditorFullRegenerate"
            data-tip="Click to re-generate full name"
            data-tick="0"
            class="icon-arrows-cw pointer"
          ></span>
        </div>

        <div data-tip="Uncheck to not update state label on name change" style="padding-block: 0.2em">
          <input id="stateNameEditorUpdateLabel" class="checkbox" type="checkbox" checked />
          <label for="stateNameEditorUpdateLabel" class="checkbox-label"><i>Update label on Apply</i></label>
        </div>
      </div>

      <div id="provincesEditor" class="dialog stable" style="display: none">
        <div id="provincesHeader" class="header" style="grid-template-columns: 11em 8em 8em 6em 6em 6em 8em">
          <div data-tip="Click to sort by province name" class="sortable alphabetically" data-sortby="name">
            Province&nbsp;
          </div>
          <div data-tip="Click to sort by province form name" class="sortable alphabetically hide" data-sortby="form">
            Form&nbsp;
          </div>
          <div data-tip="Click to sort by province capital" class="sortable alphabetically hide" data-sortby="capital">
            Capital&nbsp;
          </div>
          <div data-tip="Click to sort by province owner" class="sortable alphabetically" data-sortby="state">
            State&nbsp;
          </div>
          <div data-tip="Click to sort by province burgs count" class="sortable hide" data-sortby="burgs">
            Burgs&nbsp;
          </div>
          <div data-tip="Click to sort by province area" class="sortable hide" data-sortby="area">Area&nbsp;</div>
          <div data-tip="Click to sort by province population" class="sortable hide" data-sortby="population">
            Population&nbsp;
          </div>
        </div>

        <div id="provincesBodySection" class="table" data-type="absolute"></div>

        <div id="provincesFooter" class="totalLine">
          <div data-tip="Provinces displayed" style="margin-left: 4px">
            Provinces:&nbsp;<span id="provincesFooterNumber">0</span>
          </div>
          <div data-tip="Total burgs number" style="margin-left: 12px">
            Burgs:&nbsp;<span id="provincesFooterBurgs">0</span>
          </div>
          <div data-tip="Average area" style="margin-left: 14px">
            Mean area:&nbsp;<span id="provincesFooterArea">0</span>
          </div>
          <div data-tip="Average population" style="margin-left: 14px">
            Mean population:&nbsp;<span id="provincesFooterPopulation">0</span>
          </div>
        </div>

        <div id="provincesBottom">
          <button id="provincesEditorRefresh" data-tip="Refresh the Editor" class="icon-cw"></button>
          <button id="provincesEditStyle" data-tip="Edit provinces style in Style Editor" class="icon-adjust"></button>
          <button
            id="provincesRecolor"
            data-tip="Recolor listed provinces based on state color"
            class="icon-paint-roller"
          ></button>
          <button
            id="provincesPercentage"
            data-tip="Toggle percentage / absolute values views"
            class="icon-percent"
          ></button>
          <button id="provincesChart" data-tip="Show provinces chart" class="icon-chart-area"></button>
          <button
            id="provincesToggleLabels"
            data-tip="Toggle province labels. Change size in Menu ⭢ Style ⭢ Provinces"
            class="icon-font"
          ></button>
          <button
            id="provincesExport"
            data-tip="Save provinces-related data as a text file (.csv)"
            class="icon-download"
          ></button>

          <button id="provincesManually" data-tip="Manually re-assign provinces" class="icon-brush"></button>
          <div id="provincesManuallyButtons" style="display: none">
            <div data-tip="Change brush size. Shortcut: + to increase; – to decrease" style="margin-block: 0.3em">
              Brush size:
              <slider-input id="provincesBrush" min="1" max="100" value="8"></slider-input>
            </div>
            <button id="provincesManuallyApply" data-tip="Apply assignment" class="icon-check"></button>
            <button id="provincesManuallyCancel" data-tip="Cancel assignment" class="icon-cancel"></button>
          </div>

          <button
            id="provincesRelease"
            data-tip="Release all provinces. It will make all provinces with burgs independent"
            class="icon-flag"
          ></button>
          <button
            id="provincesAdd"
            data-tip="Add a new province. Hold Shift to add multiple"
            class="icon-plus"
          ></button>
          <button
            id="provincesRemoveAll"
            data-tip="Remove all provinces. States will remain as they are"
            class="icon-trash"
          ></button>

          <span>State: </span>
          <select id="provincesFilterState"></select>
        </div>
      </div>

      <div id="diplomacyEditor" class="dialog stable" style="display: none">
        <div id="diplomacyHeader" class="header" style="grid-template-columns: 15em 6em">
          <div data-tip="Click to sort by state name" class="sortable alphabetically" data-sortby="name">
            State&nbsp;
          </div>
          <div
            data-tip="Click to sort by diplomatical relations"
            class="sortable alphabetically"
            data-sortby="relations"
          >
            Relations&nbsp;
          </div>
        </div>

        <div id="diplomacyBodySection" class="table"></div>
        <div class="info-line">Click on state name to see relations.<br />Click on relations name to change it</div>

        <div id="diplomacyBottom" style="margin-top: 0.1em">
          <button id="diplomacyEditorRefresh" data-tip="Refresh the Editor" class="icon-cw"></button>
          <button
            id="diplomacyEditStyle"
            data-tip="Edit states (including diplomacy view) style in Style Editor"
            class="icon-adjust"
          ></button>
          <button id="diplomacyRegenerate" data-tip="Regenerate diplomatical relations" class="icon-retweet"></button>
          <button
            id="diplomacyReset"
            data-tip="Reset diplomatical relations of selected state to Neutral"
            class="icon-eraser"
          ></button>
          <button id="diplomacyHistory" data-tip="Show relations history" class="icon-hourglass-1"></button>
          <button id="diplomacyShowMatrix" data-tip="Show relations matrix" class="icon-list-bullet"></button>
          <button
            id="diplomacyExport"
            data-tip="Save state relations matrix as a text file (.csv)"
            class="icon-download"
          ></button>
        </div>
      </div>

      <div id="diplomacyMatrix" class="dialog" style="display: none">
        <div id="diplomacyMatrixBody" class="matrix-table"></div>
      </div>

      <div id="provinceNameEditor" class="dialog" data-province="0" style="display: none">
        <div>
          <div data-tip="Province short name" class="label">Short name:</div>
          <input
            id="provinceNameEditorShort"
            data-tip="Type to change the short name"
            autocorrect="off"
            spellcheck="false"
            style="width: 11em"
          />
          <span data-tip="Speak the name. You can change voice and language in options" class="speaker">🔊</span>
          <span
            id="provinceNameEditorShortCulture"
            data-tip="Generate culture-specific name for the province"
            class="icon-book pointer"
          ></span>
          <span id="provinceNameEditorShortRandom" data-tip="Generate random name" class="icon-globe pointer"></span>
        </div>

        <div data-tip="Select form name">
          <div data-tip="Province form name" class="label">Form name:</div>
          <select id="provinceNameEditorSelectForm" style="display: inline-block; width: 11em; height: 1.645em">
            <option value="">blank</option>
            <option value="Area">Area</option>
            <option value="Autonomy">Autonomy</option>
            <option value="Barony">Barony</option>
            <option value="Canton">Canton</option>
            <option value="Captaincy">Captaincy</option>
            <option value="Chiefdom">Chiefdom</option>
            <option value="Clan">Clan</option>
            <option value="Colony">Colony</option>
            <option value="Council">Council</option>
            <option value="County">County</option>
            <option value="Deanery">Deanery</option>
            <option value="Department">Department</option>
            <option value="Dependency">Dependency</option>
            <option value="Diaconate">Diaconate</option>
            <option value="District">District</option>
            <option value="Earldom">Earldom</option>
            <option value="Governorate">Governorate</option>
            <option value="Island">Island</option>
            <option value="Islands">Islands</option>
            <option value="Land">Land</option>
            <option value="Landgrave">Landgrave</option>
            <option value="Mandate">Mandate</option>
            <option value="Margrave">Margrave</option>
            <option value="Municipality">Municipality</option>
            <option value="Occupation zone">Occupation zone</option>
            <option value="Parish">Parish</option>
            <option value="Prefecture">Prefecture</option>
            <option value="Province">Province</option>
            <option value="Region">Region</option>
            <option value="Republic">Republic</option>
            <option value="Reservation">Reservation</option>
            <option value="Seneschalty">Seneschalty</option>
            <option value="Shire">Shire</option>
            <option value="State">State</option>
            <option value="Territory">Territory</option>
            <option value="Tribe">Tribe</option>
          </select>
          <input
            id="provinceNameEditorCustomForm"
            placeholder="type form name"
            data-tip="Create custom province form name"
            style="display: none; width: 11em"
          />
          <span
            id="provinceNameEditorAddForm"
            data-tip="Click to add custom province form name to the list"
            class="icon-plus pointer"
          ></span>
        </div>

        <div>
          <div data-tip="Province full name" class="label">Full name:</div>
          <input
            id="provinceNameEditorFull"
            data-tip="Type to change the full name"
            autocorrect="off"
            spellcheck="false"
            style="width: 11em"
          />
          <span data-tip="Speak the name. You can change voice and language in options" class="speaker">🔊</span>
          <span
            id="provinceNameEditorFullRegenerate"
            data-tip="Click to re-generate full name"
            class="icon-arrows-cw pointer"
          ></span>
        </div>

        <div
          id="provinceCultureName"
          data-tip="Dominant culture in the province. This defines culture-based naming. Can be changed via the Cultures Editor"
          style="margin-top: 0.2em"
        >
          Dominant culture:&nbsp;<span id="provinceCultureDisplay"></span>
        </div>
      </div>

      <div id="namesbaseEditor" class="dialog stable textual" style="display: none">
        <div id="namesbaseBasesTop">
          <span>Select base: </span>
          <select id="namesbaseSelect" data-tip="Select base to edit" style="width: 12em" value="0"></select>
          <span style="margin-left: 2px">Names data: </span>
        </div>

        <div id="namesbaseBody" style="margin-block: 2px; width: auto">
          <textarea
            id="namesbaseTextarea"
            data-base="0"
            rows="13"
            data-tip="Names data: a comma separated list of source names used for names generation"
            placeholder="Provide a names data: a comma separated list of source names"
            autocorrect="off"
            spellcheck="false"
            style="resize: none"
          ></textarea>

          <div>
            <span>Name: </span>
            <input
              id="namesbaseName"
              data-tip="Type to change a base name"
              placeholder="Base name"
              autocorrect="off"
              spellcheck="false"
              style="width: 12em"
            />
            <span>Length: </span>
            <input id="namesbaseMin" data-tip="Recommended minimum name length" type="number" min="2" max="100" />
            <input id="namesbaseMax" data-tip="Recommended maximum name length" type="number" min="2" value="10" />
            <span>Doubled: </span>
            <input
              id="namesbaseDouble"
              data-tip="Populate with letters that can be used twice in a row (geminates)"
              autocorrect="off"
              spellcheck="false"
              style="width: 10em"
            />
          </div>

          <fieldset>
            <legend>Generated examples:</legend>
            <div id="namesbaseExamples" data-tip="Examples. Click to re-generate"></div>
          </fieldset>
        </div>

        <div id="namesbaseBottom">
          <button
            id="namesbaseUpdateExamples"
            data-tip="Re-generate examples based on provided data"
            class="icon-arrows-cw"
          ></button>
          <button id="namesbaseAdd" data-tip="Add new namesbase" class="icon-plus"></button>
          <button id="namesbaseDefault" data-tip="Restore default namesbase" class="icon-cancel"></button>
          <button id="namesbaseDownload" data-tip="Download namesbase to PC" class="icon-download"></button>
          <button
            id="namesbaseUpload"
            data-tip="Upload a namesbase from PC, replacing the current set"
            class="icon-upload"
          ></button>
          <button
            id="namesbaseUploadExtend"
            data-tip="Upload a namesbase from PC, extending the current set"
            class="icon-up-circled2"
          ></button>
          <button
            id="namesbaseCA"
            data-tip="Find or share custom namesbase on Cartography Assets portal"
            class="icon-drafting-compass"
          ></button>
          <button
            id="namesbaseAnalyze"
            data-tip="Analyze namesbase to get a validity and quality overview"
            class="icon-flask"
          ></button>
          <button
            id="namesbaseSpeak"
            data-tip="Speak the examples. You can change voice and language in options"
            class="icon-voice"
          ></button>
        </div>
      </div>

      <div id="zonesEditor" class="dialog stable" style="display: none">
        <div id="customHeader" class="header" style="grid-template-columns: 13em 7em 6em 5em 9em">
          <div data-tip="Zone description">Description&nbsp;</div>
          <div data-tip="Zone type">Type&nbsp;</div>
          <div data-tip="Zone cells count" class="hide">Cells&nbsp;</div>
          <div data-tip="Zone area" class="hide">Area&nbsp;</div>
          <div data-tip="Zone population" class="hide">Population&nbsp;</div>
        </div>

        <div id="zonesBodySection" class="table" data-type="absolute"></div>

        <div id="zonesFooter" class="totalLine">
          <div data-tip="Number of zones" style="margin-left: 5px">
            Zones:&nbsp;<span id="zonesFooterNumber">0</span>
          </div>
          <div data-tip="Total cells number" style="margin-left: 12px">
            Cells:&nbsp;<span id="zonesFooterCells">0</span>
          </div>
          <div data-tip="Total map area" style="margin-left: 12px">Area:&nbsp;<span id="zonesFooterArea">0</span></div>
          <div data-tip="Total map population" style="margin-left: 12px">
            Population:&nbsp;<span id="zonesFooterPopulation">0</span>
          </div>
        </div>

        <div id="zonesBottom">
          <button id="zonesEditorRefresh" data-tip="Refresh the Editor" class="icon-cw"></button>
          <button id="zonesEditStyle" data-tip="Edit zones style in Style Editor" class="icon-adjust"></button>
          <button
            id="zonesLegend"
            data-tip="Toggle Legend box (shows all non-hidden zones)"
            class="icon-list-bullet"
          ></button>
          <button
            id="zonesPercentage"
            data-tip="Toggle percentage / absolute values views"
            class="icon-percent"
          ></button>

          <button id="zonesManually" data-tip="Re-assign zones" class="icon-brush"></button>
          <div id="zonesManuallyButtons" style="display: none">
            <div data-tip="Change brush size. Shortcut: + to increase; – to decrease" style="margin-block: 0.3em">
              Brush size:
              <slider-input id="zonesBrush" min="1" max="100" value="8"></slider-input>
            </div>
            <div>
              <input id="zonesBrushLandOnly" class="checkbox" type="checkbox" checked />
              <label for="zonesBrushLandOnly" class="checkbox-label"><i>Change land only</i></label>
            </div>

            <div style="margin-top: 0.3em">
              <button id="zonesManuallyApply" data-tip="Apply assignment" class="icon-check"></button>
              <button id="zonesManuallyCancel" data-tip="Cancel assignment" class="icon-cancel"></button>
              <button
                id="zonesRemove"
                data-tip="Click to toggle the removal mode on brush dragging"
                data-shortcut="Ctrl"
                class="icon-eraser"
              ></button>
            </div>
          </div>

          <button id="zonesAdd" data-tip="Add new zone layer" class="icon-plus"></button>
          <button id="zonesExport" data-tip="Download zones-related data" class="icon-download"></button>

          <div id="zonesFilters" data-tip="Show only zones of selected type" style="display: inline-block">
            Type:
            <select id="zonesFilterType"></select>
          </div>
        </div>
      </div>

      <div id="notesEditor" class="dialog stable" style="display: none">
        <div style="margin-bottom: 0.3em">
          <strong>Element: </strong>
          <select id="notesSelect" data-tip="Select element id" style="width: 12em"></select>
          <strong>Element name: </strong>
          <input id="notesName" data-tip="Set element name" autocorrect="off" spellcheck="false" style="width: 16em" />
          <span data-tip="Speak the name. You can change voice and language in options" class="speaker">🔊</span>
        </div>
        <div id="notesLegend" contenteditable="true"></div>
        <div style="margin-top: 0.3em">
          <button id="notesFocus" data-tip="Focus on selected object" class="icon-target"></button>
          <button id="notesGenerateWithAi" data-tip="Generate note with AI" class="icon-robot"></button>
          <button
            id="notesPin"
            data-tip="Toggle notes box dispay: hide or do not hide the box on mouse move"
            class="icon-pin"
          ></button>
          <button id="notesDownload" data-tip="Download notes to PC" class="icon-download"></button>
          <button id="notesUpload" data-tip="Upload notes from PC" class="icon-upload"></button>
          <button id="notesRemove" data-tip="Remove this note" class="icon-trash fastDelete"></button>
        </div>
      </div>

      <div id="aiGenerator" class="dialog stable" style="display: none">
        <div style="display: flex; flex-direction: column; gap: 0.3em; width: 100%">
          <textarea id="aiGeneratorResult" placeholder="Generated text will appear here" cols="30" rows="10"></textarea>
          <textarea id="aiGeneratorPrompt" placeholder="Type a prompt here" cols="30" rows="5"></textarea>
          <div style="display: flex; align-items: center; gap: 1em">
            <label for="aiGeneratorModel"
              >Model:
              <select id="aiGeneratorModel"></select>
            </label>
            <label
              for="aiGeneratorTemperature"
              data-tip="Temperature controls response randomness; higher values mean more creativity, lower values mean more predictability"
            >
              Temperature:
              <input id="aiGeneratorTemperature" type="number" min="-1" max="2" step=".1" class="icon-key" />
            </label>
            <label for="aiGeneratorKey"
              >Key:
              <input
                id="aiGeneratorKey"
                placeholder="Enter API key"
                class="icon-key"
                data-tip="Enter API key. Note: the Generator doesn't store the key or any generated data"
              />
              <button
                id="aiGeneratorKeyHelp"
                class="icon-help-circled"
                data-tip="Click to see the usage instructions"
              />
            </label>
          </div>
        </div>
      </div>

      <div id="emblemEditor" class="dialog stable" style="display: none">
        <svg viewBox="0 0 200 200"><use id="emblemImage"></use></svg>
        <div id="emblemBody">
          <div>
            <b id="emblemArmiger"></b>
          </div>
          <hr />
          <div data-tip="Select state">
            <div class="label">State:</div>
            <select id="emblemStates"></select>
          </div>
          <div data-tip="Select province in state">
            <div class="label">Province:</div>
            <select id="emblemProvinces"></select>
          </div>
          <div data-tip="Select burg in province or state">
            <div class="label">Burg:</div>
            <select id="emblemBurgs"></select>
          </div>
          <hr />
          <div data-tip="Select shape of the emblem">
            <div class="label">Shape:</div>
            <select id="emblemShapeSelector">
              <optgroup label="Basic">
                <option value="heater">Heater</option>
                <option value="spanish">Spanish</option>
                <option value="french">French</option>
              </optgroup>
              <optgroup label="Regional">
                <option value="horsehead">Horsehead</option>
                <option value="horsehead2">Horsehead Edgy</option>
                <option value="polish">Polish</option>
                <option value="hessen">Hessen</option>
                <option value="swiss">Swiss</option>
              </optgroup>
              <optgroup label="Historical">
                <option value="boeotian">Boeotian</option>
                <option value="roman">Roman</option>
                <option value="kite">Kite</option>
                <option value="oldFrench">Old French</option>
                <option value="renaissance">Renaissance</option>
                <option value="baroque">Baroque</option>
              </optgroup>
              <optgroup label="Specific">
                <option value="targe">Targe</option>
                <option value="targe2">Targe2</option>
                <option value="pavise">Pavise</option>
                <option value="wedged">Wedged</option>
              </optgroup>
              <optgroup label="Banner">
                <option value="flag">Flag</option>
                <option value="pennon">Pennon</option>
                <option value="guidon">Guidon</option>
                <option value="banner">Banner</option>
                <option value="dovetail">Dovetail</option>
                <option value="gonfalon">Gonfalon</option>
                <option value="pennant">Pennant</option>
              </optgroup>
              <optgroup label="Simple">
                <option value="round">Round</option>
                <option value="oval">Oval</option>
                <option value="vesicaPiscis">Vesica Piscis</option>
                <option value="square">Square</option>
                <option value="diamond">Diamond</option>
              </optgroup>
              <optgroup label="Fantasy">
                <option value="fantasy1">Fantasy1</option>
                <option value="fantasy2">Fantasy2</option>
                <option value="fantasy3">Fantasy3</option>
                <option value="fantasy4">Fantasy4</option>
                <option value="fantasy5">Fantasy5</option>
              </optgroup>
              <optgroup label="Middle Earth">
                <option value="noldor">Noldor</option>
                <option value="gondor">Gondor</option>
                <option value="easterling">Easterling</option>
                <option value="erebor">Erebor</option>
                <option value="ironHills">Iron Hills</option>
                <option value="urukHai">UrukHai</option>
                <option value="moriaOrc">Moria Orc</option>
              </optgroup>
            </select>
          </div>

          <div
            data-tip="Set size of particular Emblem. To hide set to 0. To change the entire category go to Menu ⭢ Style ⭢ Emblems"
          >
            <div class="label" style="width: 2.8em">Size:</div>
            <input id="emblemSizeSlider" type="range" min="0" max="5" step=".1" style="width: 7em" />
            <input id="emblemSizeNumber" type="number" min="0" max="5" step=".1" />
          </div>
        </div>
        <div id="emblemsBottom">
          <button id="emblemsRegenerate" data-tip="Regenerate emblem" class="icon-shuffle"></button>
          <button
            id="emblemsArmoria"
            data-tip="Edit the emblem in Armoria - dedicated heraldry editor. Download emblem and upload it back map the generator"
            class="icon-brush"
          ></button>
          <button
            id="emblemsDownload"
            data-tip="Set size, select file format and download emblem image"
            class="icon-download"
          ></button>
          <button
            id="emblemsUpload"
            data-tip="Upload png, jpg or svg image from Armoria or other sources as emblem"
            class="icon-upload"
          ></button>
          <button
            id="emblemsGallery"
            data-tip="Download emblems gallery as html document (open in browser; downloading takes some time)"
            class="icon-layer-group"
          ></button>
          <button id="emblemsFocus" data-tip="Show emblem associated area or place" class="icon-target"></button>
        </div>
        <div id="emblemUploadControl" class="hidden">
          <button
            id="emblemsUploadImage"
            data-tip="Upload SVG or PNG image from any source. Make sure background is transparent"
          >
            Any image
          </button>
          <button
            id="emblemsUploadSVG"
            data-tip="Upload prepared SVG image (SVG from Armoria or SVG processed with 'Optimize vector' tool)"
          >
            Prepared SVG
          </button>
          <a
            href="https://www.iloveimg.com/compress-image"
            target="_blank"
            data-tip="Use external tool to compress/resize raster images before upload"
            >Comperess raster</a
          >
          <span> | </span>
          <a
            href="https://jakearchibald.github.io/svgomg"
            target="_blank"
            data-tip="Use external tool to optimize vector images before upload"
            >Optimize vector</a
          >
        </div>
        <div id="emblemDownloadControl" class="hidden">
          <input
            id="emblemsDownloadSize"
            data-tip="Set image size in pixels"
            type="number"
            value="500"
            step="100"
            min="100"
            max="10000"
          />
          <button
            id="emblemsDownloadSVG"
            data-tip="Download as SVG: scalable vector image. Best quality, can be opened in browser or Inkscape"
          >
            SVG
          </button>
          <button id="emblemsDownloadPNG" data-tip="Download as PNG: lossless raster image with transparent background">
            PNG
          </button>
          <button
            id="emblemsDownloadJPG"
            data-tip="Download as JPG: lossy compressed raster image with solid white background"
          >
            JPG
          </button>
        </div>
      </div>

      <div id="unitsEditor" class="dialog stable" style="display: none">
        <div id="unitsBody" style="margin-left: 1.1em">
          <div class="unitsHeader" style="margin-top: 0.4em">
            <span class="icon-map-signs"></span>
            <label>Distance:</label>
          </div>

          <div data-tip="Select a distance unit or provide a custom name">
            <label>Distance unit:</label>
            <select id="distanceUnitInput" data-stored="distanceUnit">
              <option value="mi" selected>Mile (mi)</option>
              <option value="km">Kilometer (km)</option>
              <option value="lg">League (lg)</option>
              <option value="vr">Versta (vr)</option>
              <option value="nmi">Nautical mile (nmi)</option>
              <option value="nlg">Nautical league (nlg)</option>
              <option value="custom_name">Custom name</option>
            </select>
          </div>

          <div data-tip="Select how many distance units are in one pixel">
            <i data-locked="0" id="lock_distanceScale" class="icon-lock-open"></i>
            <slider-input id="distanceScaleInput" data-stored="distanceScale" min=".01" max="20" step=".1" value="3">
              <label>1 map pixel:</label>
            </slider-input>
          </div>

          <div data-tip='Area unit name, type "square" to add ² to the distance unit'>
            <label>Area unit:</label>
            <input id="areaUnit" data-stored="areaUnit" type="text" value="square" />
          </div>

          <div class="unitsHeader">
            <span class="icon-signal"></span>
            <label>Altitude:</label>
          </div>

          <div data-tip="Select an altitude unit or provide a custom name">
            <label>Height unit:</label>
            <select id="heightUnit" data-stored="heightUnit">
              <option value="ft" selected>Feet (ft)</option>
              <option value="m">Meters (m)</option>
              <option value="f">Fathoms (f)</option>
              <option value="custom_name">Custom name</option>
            </select>
          </div>

          <div
            data-tip="Set height exponent, i.e. a value for altitude change sharpness. Altitude affects temperature and hence biomes"
          >
            <slider-input
              id="heightExponentInput"
              data-stored="heightExponent"
              min="1.5"
              max="2.2"
              step=".01"
              value="2"
            >
              <label>Exponent:</label>
            </slider-input>
          </div>

          <div class="unitsHeader" data-tip="Select Temperature scale">
            <span class="icon-temperature-high"></span>
            <label>Temperature:</label>
          </div>

          <div>
            <label>Temperature scale:</label>
            <select id="temperatureScale" data-stored="temperatureScale">
              <option value="°C" selected>degree Celsius (°C)</option>
              <option value="°F">degree Fahrenheit (°F)</option>
              <option value="K">Kelvin (K)</option>
              <option value="°R">degree Rankine (°R)</option>
              <option value="°De">degree Delisle (°De)</option>
              <option value="°N">degree Newton (°N)</option>
              <option value="°Ré">degree Réaumur (°Ré)</option>
              <option value="°Rø">degree Rømer (°Rø)</option>
            </select>
          </div>

          <div class="unitsHeader">
            <span class="icon-male"></span>
            <label>Population:</label>
          </div>

          <div data-tip="Set how many people are in one population point">
            <slider-input
              id="populationRateInput"
              data-stored="populationRate"
              min="10"
              max="10000"
              step="10"
              value="1000"
            >
              <label>1 population point:</label>
            </slider-input>
          </div>

          <div data-tip="Set urbanization rate: burgs population relative to all population">
            <slider-input id="urbanizationInput" data-stored="urbanization" min=".01" max="5" step=".01" value="1">
              <label>Urbanization rate:</label>
            </slider-input>
          </div>

          <div data-tip="Set urban density: average population per building in Medieval Fantasy City Generator">
            <slider-input id="urbanDensityInput" data-stored="urbanDensity" min="1" max="200" step="1" value="10">
              <label>Urban density:</label>
            </slider-input>
          </div>
        </div>

        <div id="unitsBottom">
          <button id="addLinearRuler" data-tip="Click to place a linear measurer (ruler)" class="icon-ruler"></button>
          <button
            id="addOpisometer"
            data-tip="Drag to measure a curve length (opisometer)"
            class="icon-drafting-compass"
          ></button>
          <button
            id="addRouteOpisometer"
            data-tip="Drag to measure a curve length that sticks to routes (route opisometer)"
          >
            <svg width="0.88em" height="0.88em">
              <use xlink:href="#icon-route" />
            </svg>
          </button>
          <button
            id="addPlanimeter"
            data-tip="Drag to measure a polygon area (planimeter)"
            class="icon-draw-polygon"
          ></button>
          <button
            id="removeRulers"
            data-tip="Remove all rulers from the map. Click on ruler label to remove a ruler separately"
            class="icon-trash"
          ></button>
          <button id="unitsRestore" data-tip="Restore default units settings" class="icon-ccw"></button>
        </div>
      </div>

      <div id="burgsOverview" class="dialog stable" style="display: none">
        <div id="burgsHeader" class="header" style="grid-template-columns: 8em 6em 6em 6em 8em 6em">
          <div data-tip="Click to sort by burg name" class="sortable alphabetically" data-sortby="name">Burg</div>
          <div data-tip="Click to sort by province name" class="sortable alphabetically" data-sortby="province">
            Province
          </div>
          <div data-tip="Click to sort by state name" class="sortable alphabetically" data-sortby="state">State</div>
          <div data-tip="Click to sort by culture name" class="sortable alphabetically" data-sortby="culture">
            Culture
          </div>
          <div
            data-tip="Click to sort by burg population"
            class="sortable icon-sort-number-down"
            data-sortby="population"
          >
            Population
          </div>
          <div data-tip="Click to sort by burg features" class="sortable alphabetically" data-sortby="features">
            Features&nbsp;
          </div>
        </div>

        <div id="burgsBody" class="table"></div>

        <div id="burgsFilters" data-tip="Apply a filter" style="padding-block: 0.1em">
          <label for="burgsFilterState">State:</label>
          <select id="burgsFilterState" style="width: 28%"></select>

          <label for="burgsFilterCulture">Culture:</label>
          <select id="burgsFilterCulture" style="width: 28%"></select>
        </div>

        <div id="burgsFooter" class="totalLine">
          <div data-tip="Burgs displayed" style="margin-left: 4px">
            Burgs:&nbsp;<span id="burgsFooterBurgs">0</span>
          </div>

          <div data-tip="Average population" style="margin-left: 14px">
            Average population:&nbsp;<span id="burgsFooterPopulation">0</span>
          </div>
        </div>

        <div id="burgsBottom">
          <button id="burgsOverviewRefresh" data-tip="Refresh the Editor" class="icon-cw"></button>
          <button id="burgsChart" data-tip="Show burgs bubble chart" class="icon-chart-area"></button>
          <button
            id="regenerateBurgNames"
            data-tip="Regenerate burg names based on assigned culture"
            class="icon-retweet"
          ></button>
          <button id="addNewBurg" data-tip="Add a new burg. Hold Shift to add multiple" class="icon-plus"></button>
          <button
            id="burgsExport"
            data-tip="Save burgs-related data as a text file (.csv)"
            class="icon-download"
          ></button>
          <button id="burgNamesImport" data-tip="Rename burgs in bulk" class="icon-upload"></button>
          <button id="burgsLockAll" data-tip="Lock or unlock all burgs" class="icon-lock"></button>
          <button
            id="burgsRemoveAll"
            data-tip="Remove all unlocked burgs except for capitals. To remove a capital remove its state first"
            class="icon-trash"
          ></button>
        </div>
      </div>

      <div id="routesOverview" class="dialog stable" style="display: none">
        <div id="routesHeader" class="header" style="grid-template-columns: 17em 8em 8em">
          <div data-tip="Click to sort by route name" class="sortable alphabetically" data-sortby="name">
            Route&nbsp;
          </div>
          <div data-tip="Click to sort by route group" class="sortable alphabetically" data-sortby="group">
            Group&nbsp;
          </div>
          <div data-tip="Click to sort by route length" class="sortable icon-sort-number-down" data-sortby="length">
            Length&nbsp;
          </div>
        </div>

        <div id="routesBody" class="table"></div>

        <div id="routesFooter" class="totalLine">
          <div data-tip="Routes number" style="margin-left: 4px">
            Total routes:&nbsp;<span id="routesFooterNumber">0</span>
          </div>
          <div data-tip="Average length" style="margin-left: 12px">
            Average length:&nbsp;<span id="routesFooterLength">0</span>
          </div>
        </div>

        <div id="routesBottom">
          <button id="routesOverviewRefresh" data-tip="Refresh the Editor" class="icon-cw"></button>
          <button
            id="routesCreateNew"
            data-tip="Create a new route selecting route cells"
            class="icon-map-pin"
          ></button>
          <button
            id="routesExport"
            data-tip="Save routes-related data as a text file (.csv)"
            class="icon-download"
          ></button>
          <button id="routesLockAll" data-tip="Lock or unlock all routes" class="icon-lock"></button>
          <button id="routesRemoveAll" data-tip="Remove all routes" class="icon-trash"></button>
        </div>
      </div>

      <div id="riversOverview" class="dialog stable" style="display: none">
        <div id="riversHeader" class="header" style="grid-template-columns: 9em 4em 6em 6em 5em 9em">
          <div data-tip="Click to sort by river name" class="sortable alphabetically" data-sortby="name">
            River&nbsp;
          </div>
          <div data-tip="Click to sort by river type name" class="sortable alphabetically" data-sortby="type">
            Type&nbsp;
          </div>
          <div
            data-tip="Click to sort by discharge (flux in m3/s)"
            class="sortable icon-sort-number-down"
            data-sortby="discharge"
          >
            Discharge&nbsp;
          </div>
          <div data-tip="Click to sort by river length" class="sortable" data-sortby="length">Length&nbsp;</div>
          <div data-tip="Click to sort by river mouth width" class="sortable" data-sortby="width">Width&nbsp;</div>
          <div data-tip="Click to sort by river basin" class="sortable alphabetically" data-sortby="basin">
            Basin&nbsp;
          </div>
        </div>

        <div id="riversBody" class="table"></div>

        <div id="riversFooter" class="totalLine">
          <div data-tip="Rivers number" style="margin-left: 4px">
            Rivers:&nbsp;<span id="riversFooterNumber">0</span>
          </div>
          <div data-tip="Average discharge" style="margin-left: 12px">
            Average discharge:&nbsp;<span id="riversFooterDischarge">0</span>
          </div>
          <div data-tip="Average length" style="margin-left: 12px">
            Length:&nbsp;<span id="riversFooterLength">0</span>
          </div>
          <div data-tip="Average mouth width" style="margin-left: 12px">
            Width:&nbsp;<span id="riversFooterWidth">0</span>
          </div>
        </div>

        <div id="riversBottom">
          <button id="riversOverviewRefresh" data-tip="Refresh the Editor" class="icon-cw"></button>
          <button
            id="addNewRiver"
            data-tip="Automatically add river starting from clicked cell. Hold Shift to add multiple"
            class="icon-plus"
          ></button>
          <button id="riverCreateNew" data-tip="Create a new river selecting river cells" class="icon-map-pin"></button>
          <button id="riversBasinHighlight" data-tip="Toggle basin highlight mode" class="icon-sitemap"></button>
          <button
            id="riversExport"
            data-tip="Save rivers-related data as a text file (.csv)"
            class="icon-download"
          ></button>
          <button id="riversRemoveAll" data-tip="Remove all rivers" class="icon-trash"></button>
        </div>
      </div>

      <div id="militaryOverview" class="dialog stable" style="display: none">
        <div id="militaryHeader" class="header">
          <div data-tip="State name. Click to sort" class="sortable alphabetically" data-sortby="state">
            State&nbsp;
          </div>
          <div
            data-tip="Total military personnel (considering crew). Click to sort"
            id="militaryTotal"
            class="sortable icon-sort-number-down"
            data-sortby="total"
          >
            Total&nbsp;
          </div>
          <div data-tip="State population. Click to sort" class="sortable" data-sortby="population">
            Population&nbsp;
          </div>
          <div
            data-tip="Military personnel rate (% of state population). Depends on war alert. Click to sort"
            class="sortable"
            data-sortby="rate"
          >
            Rate&nbsp;
          </div>
          <div
            data-tip="War Alert. Modifier to military forces number, depends of political situation. Click to sort"
            class="sortable"
            data-sortby="alert"
          >
            War Alert&nbsp;
          </div>
        </div>

        <div id="militaryBody" class="table" data-type="absolute"></div>

        <div id="militaryFooter" class="totalLine">
          <div data-tip="States number" style="margin-left: 4px">
            States:&nbsp;<span id="militaryFooterStates">0</span>
          </div>
          <div data-tip="Total military forces" style="margin-left: 14px">
            Total forces:&nbsp;<span id="militaryFooterForcesTotal">0</span>
          </div>
          <div data-tip="Average military forces per state" style="margin-left: 14px">
            Average forces:&nbsp;<span id="militaryFooterForces">0</span>
          </div>
          <div data-tip="Average forces rate per state" style="margin-left: 14px">
            Average rate:&nbsp;<span id="militaryFooterRate">0%</span>
          </div>
          <div data-tip="Average War Alert" style="margin-left: 14px">
            Average alert:&nbsp;<span id="militaryFooterAlert">0</span>
          </div>
        </div>

        <div id="militaryBottom">
          <button id="militaryOverviewRefresh" data-tip="Refresh the overview screen" class="icon-cw"></button>
          <button id="militaryOptionsButton" data-tip="Edit Military units" class="icon-cog"></button>
          <button id="militaryRegimentsList" data-tip="Show regiments list" class="icon-list-bullet"></button>
          <button
            id="militaryPercentage"
            data-tip="Toggle percentage / absolute values views"
            class="icon-percent"
          ></button>
          <button
            id="militaryOverviewRecalculate"
            data-tip="Recalculate military forces based on current options"
            class="icon-retweet"
          ></button>
          <button
            id="militaryExport"
            data-tip="Save military-related data as a text file (.csv)"
            class="icon-download"
          ></button>
          <button id="militaryWiki" data-tip="Open Military Forces Tutorial" class="icon-info"></button>
        </div>
      </div>

      <div id="regimentsOverview" class="dialog stable" style="display: none">
        <div id="regimentsHeader" class="header">
          <div data-tip="State name. Click to sort" class="sortable alphabetically" data-sortby="state">
            State&nbsp;
          </div>
          <div
            data-tip="Regiment emblem and name. Click to sort by name"
            class="sortable alphabetically"
            data-sortby="name"
          >
            Name&nbsp;
          </div>
          <div
            data-tip="Total military personnel (not considering crew). Click to sort"
            id="regimentsTotal"
            class="sortable icon-sort-number-down"
            data-sortby="total"
          >
            Total&nbsp;
          </div>
        </div>

        <div id="regimentsBody" class="table" data-type="absolute"></div>

        <div id="regimentsBottom">
          <button id="regimentsOverviewRefresh" data-tip="Refresh the overview screen" class="icon-cw"></button>
          <button
            id="regimentsPercentage"
            data-tip="Toggle percentage / absolute values views"
            class="icon-percent"
          ></button>
          <button id="regimentsAddNew" data-tip="Add new Regiment" class="icon-user-plus"></button>
          <div data-tip="Select state" style="display: inline-block">
            <span>State: </span
            ><select id="regimentsFilter"></select>
          </div>
          <button
            id="regimentsExport"
            data-tip="Save military-related data as a text file (.csv)"
            class="icon-download"
          ></button>
        </div>
      </div>

      <div id="militaryOptions" class="dialog stable" style="display: none">
        <div class="table">
          <table id="militaryOptionsTable">
            <thead>
              <tr>
                <th data-tip="Unit icon">Icon</th>
                <th data-tip="Unit name. If name is changed for existing unit, old unit will be replaced">Unit name</th>
                <th style="width: 5em" data-tip="Select allowed biomes">Biomes</th>
                <th style="width: 5em" data-tip="Select allowed states">States</th>
                <th style="width: 5em" data-tip="Select allowed cultures">Cultures</th>
                <th style="width: 5em" data-tip="Select allowed religions">Religions</th>
                <th data-tip="Conscription percentage for rural population">Rural</th>
                <th data-tip="Conscription percentage for urban population">Urban</th>
                <th data-tip="Average number of people in crew (used for total personnel calculation)">Crew</th>
                <th data-tip="Unit military power (used for battle simulation)">Power</th>
                <th data-tip="Unit type to apply special rules on forces recalculation">Type</th>
                <th data-tip="Check if unit is separate and can be stacked only with units of the same type">
                  Separate
                </th>
              </tr>
            </thead>
            <tbody></tbody>
          </table>
        </div>
      </div>

      <div id="markersOverview" class="dialog stable" style="display: none">
        <div id="markersHeader" class="header" style="grid-template-columns: 15em 1em 3em">
          <div data-tip="Click to sort by marker type" class="sortable alphabetically" data-sortby="type">
            Type&nbsp;
          </div>
          <div
            id="markersInverPin"
            style="color: #6e5e66"
            data-tip="Click to invert pin state for all markers"
            class="icon-pin pointer"
          ></div>
          <div
            id="markersInverLock"
            style="color: #6e5e66"
            data-tip="Click to invert lock state for all markers"
            class="icon-lock pointer"
          ></div>
        </div>

        <div id="markersBody" class="table"></div>

        <div id="markersFooter" class="totalLine">
          <div data-tip="Markers number" style="margin-left: 4px">
            Total:&nbsp;<span id="markersFooterNumber">0</span>&nbsp;markers
          </div>
        </div>

        <div id="markersBottom">
          <button id="markersOverviewRefresh" data-tip="Refresh the Overview screen" class="icon-cw"></button>
          <input type="hidden" id="addedMarkerType" name="addedMarkerType" value="" />
          <span id="markerTypeSelectorWrapper">
            <button id="markerTypeSelector" data-tip="Select marker type for newly added markers.">❓</button>
            <div id="markerTypeSelectMenu"></div>
          </span>
          <button
            id="markersAddFromOverview"
            data-tip="Add a new marker. Hold Shift to add multiple"
            class="icon-plus"
          ></button>
          <button id="markersGenerationConfig" data-tip="Config markers generation options" class="icon-cog"></button>
          <button id="markersRemoveAll" data-tip="Remove all unlocked markers" class="icon-trash"></button>
          <button id="markersExport" data-tip="Save markers data as a text file (.csv)" class="icon-download"></button>
        </div>
      </div>

      <div id="styleSaver" class="dialog stable textual" style="display: none">
        <div id="styleSaverHeader" style="padding: 2px 0">
          <span>Preset name:</span>
          <input
            id="styleSaverName"
            data-tip="Enter style preset name"
            placeholder="Preset name"
            style="width: 12em"
            required
          />
          <span
            id="styleSaverTip"
            data-tip="Shows whether there is already a preset with this name"
            class="italic"
          ></span>
        </div>

        <div id="styleSaverBody" style="padding: 2px 0; width: 100%">
          <span>Style JSON:</span>
          <textarea
            id="styleSaverJSON"
            rows="18"
            data-tip="Style JSON is getting formed based the current settings, but can be entered manually"
            placeholder="Paste any valid style data in JSON format"
            autocorrect="off"
            spellcheck="false"
          ></textarea>
        </div>

        <div id="styleSaverBottom">
          <button id="styleSaverSave" data-tip="Save current JSON as a new style preset" class="icon-check"></button>
          <button
            id="styleSaverDownload"
            data-tip="Download the style as a .json file (can be opened in any text editor)"
            class="icon-download"
          ></button>
          <button id="styleSaverLoad" data-tip="Open previously downloaded style file" class="icon-upload"></button>
          <button
            id="styleSaverCA"
            data-tip="Find or share custom style preset on Cartography Assets portal"
            class="icon-drafting-compass"
            onclick="openURL('https://cartographyassets.com/asset-category/specific-assets/azgaars-generator/styles/')"
          ></button>
        </div>
      </div>

      <div id="addFontDialog" style="display: none" class="dialog">
        <span>There are 3 ways to add a custom font:</span>
        <p>
          <strong>Google font</strong>. Open <a href="https://fonts.google.com/" target="_blank">Google Fonts</a>, find
          a font you like and enter its name to the field below.
        </p>
        <p>
          <strong>Local font</strong>. If you have a font
          <a
            href="https://faqs.skillcrush.com/article/275-downloading-installing-a-font-on-your-computer"
            target="_blank"
            >installed on your computer</a
          >, just provide the font name. Make sure the browser is reloaded after the installation. The font won't work
          on machines not having it installed. Good source of fonts are
          <a href="https://fontesk.com" target="_blank">Fontdesk</a> and
          <a href="https://www.dafont.com" target="_blank">DaFont</a>.
        </p>
        <p>
          <strong>Font URL</strong>. Provide font name and link to the font file hosted online. The best free font
          hostings are <a href="https://fonts.google.com/" target="_blank">Google Fonts</a> and
          <a target="_blank" href="https://www.cdnfonts.com">CDN Fonts</a>. To get font file open the link to css
          provided by these services and manually copy the link to <code>woff2</code> of desired variant. To add another
          variant (e.g. Cyrillic), add the font one more time under the same name, but with another URL
        </p>
        <div style="margin-top: 0.3em" data-tip="Select font adding method">
          <select id="addFontMethod">
            <option value="googleFont" selected>Google font</option>
            <option value="localFont">Local font</option>
            <option value="fontURL">Font URL</option>
          </select>
          <input id="addFontNameInput" placeholder="font family" style="width: 15em" />
          <div>
            <input
              id="addFontURLInput"
              placeholder="font file URL"
              style="width: 22.6em; margin-top: 0.1em; display: none"
            />
          </div>
        </div>
      </div>

      <div id="cellInfo" style="display: none" class="dialog stable">
        <p>
          <b>Cell:</b> <span id="infoCell"></span> <b>X:</b> <span id="infoX"></span> <b>Y:</b> <span id="infoY"></span>
        </p>
        <p><b>Latitude:</b> <span id="infoLat"></span></p>
        <p><b>Longitude:</b> <span id="infoLon"></span></p>
        <p><b>Geozone:</b> <span id="infoGeozone"></span></p>
        <p><b>Area:</b> <span id="infoArea">0</span></p>
        <p><b>Type:</b> <span id="infoFeature">n/a</span></p>
        <p><b>Precipitation:</b> <span id="infoPrec">0</span></p>
        <p><b>River:</b> <span id="infoRiver">no</span></p>
        <p><b>Population:</b> <span id="infoPopulation">0</span></p>
        <p><b>Elevation:</b> <span id="infoElevation">0</span></p>
        <p><b>Depth:</b> <span id="infoDepth">0</span></p>
        <p><b>Temperature:</b> <span id="infoTemp">0</span></p>
        <p><b>Biome:</b> <span id="infoBiome">n/a</span></p>
        <p><b>State:</b> <span id="infoState">n/a</span></p>
        <p><b>Province:</b> <span id="infoProvince">n/a</span></p>
        <p><b>Culture:</b> <span id="infoCulture">n/a</span></p>
        <p><b>Religion:</b> <span id="infoReligion">n/a</span></p>
        <p><b>Burg:</b> <span id="infoBurg">n/a</span></p>
      </div>

      <div id="iconSelector" style="display: none" class="dialog">
        <div>
          <b>Unicode emojis</b>
          <div style="font-style: italic">
            <span>Select from the list or paste a Unicode character here: </span>
            <input id="iconInput" style="width: 2.5em" />
            <span>. See <a href="https://emojidb.org" target="_blank">EmojiDB</a> to search for emojis</span>
          </div>
          <table id="iconTable" class="table pointer" style="font-size: 2em; text-align: center; width: 100%"></table>
        </div>

        <div style="margin-top: 0.5em">
          <b>External images</b>
          <div style="font-style: italic">
            <span>Paste link to the image here: </span>
            <input id="imageInput" style="width: 20em" />
            <button id="addImage" type="button">Add</button>
          </div>
          <div id="addedIcons" class="pointer" style="display: flex; flex-wrap: wrap; max-width: 420px"></div>
        </div>
      </div>

      <div id="submapTool" style="display: none" class="dialog">
        <p style="font-weight: bold">
          This operation is destructive and irreversible. It will create a completely new map based on the current one.
          Don't forget to save the .map file to your machine first!
        </p>

        <div style="display: flex; flex-direction: column; gap: 0.5em">
          <div data-tip="Set points (cells) number of the submap" style="display: flex; gap: 1em">
            <div>Points number</div>
            <div>
              <input id="submapPointsInput" type="range" min="1" max="13" value="4" />
              <output id="submapPointsFormatted" style="color: #053305">10K</output>
            </div>
          </div>

          <div data-tip="Check to fit burg styles (icon and label size) to the submap scale">
            <input type="checkbox" class="checkbox" id="submapRescaleBurgStyles" checked />
            <label for="submapRescaleBurgStyles" class="checkbox-label">Rescale burg styles</label>
          </div>
        </div>
      </div>

      <div id="transformTool" style="display: none" class="dialog">
        <div style="padding-top: 0.5em; width: 40em; font-weight: bold">
          This operation is destructive and irreversible. It will create a completely new map based on the current one.
          Don't forget to save the .map file to your machine first!
        </div>

        <div
          id="transformToolBody"
          style="
            padding: 0.5em 0;
            width: 100%;
            display: grid;
            grid-template-columns: 1fr 1fr;
            grid-template-rows: repeat(5, 1fr);
            align-items: center;
          "
        >
          <div>Points number</div>
          <div>
            <input id="transformPointsInput" type="range" min="1" max="13" value="4" />
            <output id="transformPointsFormatted" style="color: #053305">10K</output>
          </div>

          <div>Shift</div>
          <div>
            <label>X: <input id="transformShiftX" type="number" size="4" value="0" /></label>
            <label>Y: <input id="transformShiftY" type="number" size="4" value="0" /></label>
          </div>

          <div>Rotate</div>
          <div>
            <input id="transformAngleInput" type="range" min="0" max="359" value="0" />
            <output id="transformAngleOutput">0</output>°
          </div>

          <div>Scale</div>
          <div>
            <input id="transformScaleInput" type="range" min="-25" max="25" value="0" />
            <output id="transformScaleResult">1</output>x
          </div>

          <div>Mirror</div>
          <div style="display: flex; gap: 0.5em">
            <input type="checkbox" class="checkbox" id="transformMirrorH" />
            <label for="transformMirrorH" class="checkbox-label">horizontally</label>
            <input type="checkbox" class="checkbox" id="transformMirrorV" />
            <label for="transformMirrorV" class="checkbox-label">vertically</label>
          </div>
        </div>

        <div id="transformPreview" style="position: relative; overflow: hidden; outline: 1px solid #666">
          <canvas id="transformPreviewCanvas" style="position: absolute; transform-origin: center"></canvas>
        </div>
      </div>

      <div id="options3d" class="dialog stable" style="display: none">
        <div id="options3dMesh" style="display: none">
          <div data-tip="Set map rotation speed. Set to 0 is you want to toggle off the rotation">
            <div>Rotation:</div>
            <input id="options3dMeshRotationRange" type="range" min="0" max="10" step=".1" />
            <input id="options3dMeshRotationNumber" type="number" min="0" max="10" step=".1" style="width: 4em" />
          </div>

          <div data-tip="Set height scale">
            <div>Height scale:</div>
            <input id="options3dScaleRange" type="range" min="0" max="100" />
            <input id="options3dScaleNumber" type="number" min="0" max="1000" style="width: 4em" />
          </div>

          <div data-tip="Set scene lightness">
            <div>Lightness:</div>
            <input id="options3dLightnessRange" type="range" min="0" max="100" />
            <input id="options3dLightnessNumber" type="number" min="0" max="500" style="width: 4em" />
          </div>

          <div data-tip="Set mesh texture resolution">
            <div>Texture resolution:</div>
            <select id="options3dMeshSkinResolution" style="width: 10em">
              <option value="512">512x512px</option>
              <option value="1024">1024x1024px</option>
              <option value="2048">2048x2048px</option>
              <option value="4096">4096x4096px</option>
              <option value="8192">8192x8192px</option>
            </select>
          </div>

          <div data-tip="Set sun position (x, y) and color" style="margin-top: 0.4em">
            <label>Sun position and color:</label>
            <div style="display: flex; gap: 0.2em">
              <input id="options3dSunX" type="number" min="-2500" max="2500" step="100" style="width: 4.7em" />
              <input id="options3dSunY" type="number" min="0" max="5000" step="100" style="width: 4.7em" />
              <input id="options3dSunColor" type="color" style="padding: 0; height: 1.5em; border: none" />
            </div>
          </div>

          <div data-tip="Toggle 3d labels" style="margin: 0.6em 0 0.3em -0.2em">
            <input id="options3dMeshLabels3d" class="checkbox" type="checkbox" />
            <label for="options3dMeshLabels3d" class="checkbox-label"><i>Show 3D labels</i></label>
          </div>

          <div data-tip="Toggle sky mode" style="margin: 0.6em 0 0.3em -0.2em">
            <input id="options3dMeshSkyMode" class="checkbox" type="checkbox" />
            <label for="options3dMeshSkyMode" class="checkbox-label"><i>Show sky and extend water</i></label>
          </div>

          <div
            data-tip="Increases the polygon count to smooth the sharp points. Please note that it can take some time to calculate"
            style="margin: 0.6em 0 0.3em -0.2em"
          >
            <input id="options3dSubdivide" class="checkbox" type="checkbox" />
            <label for="options3dSubdivide" class="checkbox-label"
              ><i>Smooth geometry <small style="color: darkred">[slow]</small></i></label
            >
          </div>

          <div data-tip="Set sky and water color" id="options3dColorSection" style="display: none">
            <span>Sky:</span
            ><input
              id="options3dMeshSky"
              type="color"
              style="width: 4.4em; height: 1em; border: 0; padding: 0; margin: 0 0.2em"
            />
            <span>Water:</span
            ><input
              id="options3dMeshWater"
              type="color"
              style="width: 4.4em; height: 1em; border: 0; padding: 0; margin: 0 0.2em"
            />
          </div>
        </div>

        <div id="options3dGlobe" style="display: none">
          <div data-tip="Set globe rotation speed. Set to 0 is you want to toggle off the rotation">
            <div>Rotation:</div>
            <input id="options3dGlobeRotationRange" type="range" min="0" max="10" step=".1" />
            <input id="options3dGlobeRotationNumber" type="number" min="0" max="10" step=".1" style="width: 4em" />
          </div>

          <div data-tip="Set globe texture resolution">
            <div>Texture resolution:</div>
            <select id="options3dGlobeResolution" style="width: 5em">
              <option value="0.5">0.5x</option>
              <option value="1">1x</option>
              <option value="2">2x</option>
              <option value="4">4x</option>
              <option value="8">8x</option>
            </select>
          </div>

          <div
            data-tip="Equirectangular projection is used: distortion is maximum on poles. Use map with aspect ratio 2:1 for best result"
            style="font-style: italic; margin: 0.2em 0"
          >
            Equirectangular projection is used
          </div>
        </div>

        <div id="options3dBottom" style="margin-top: 0.2em">
          <button id="options3dUpdate" data-tip="Update the scene" class="icon-cw"></button>
          <button
            data-tip="Configure world and map size and climate settings"
            onclick="editWorld()"
            class="icon-globe"
          ></button>
          <button id="options3dSave" data-tip="Save screenshot of the 3d scene" class="icon-button-screenshot"></button>
          <button id="options3dOBJSave" data-tip="Save OBJ file of the 3d scene" class="icon-download"></button>
        </div>
      </div>

      <div id="preview3d" class="dialog stable" style="display: none; padding: 0px"></div>

      <div id="exportMapData" style="display: none" class="dialog">
        <div style="margin-bottom: 0.3em; font-weight: bold">Download image</div>
        <div>
          <button
            onclick="exportToSvg()"
            data-tip="Download the map as vector image (open directly in browser or Inkscape)"
          >
            .svg
          </button>
          <button onclick="exportToPng()" data-tip="Download visible part of the map as .png (lossless compressed)">
            .png
          </button>
          <button
            onclick="exportToJpeg()"
            data-tip="Download visible part of the map as .jpeg (lossy compressed) image"
          >
            .jpeg
          </button>
          <button
            onclick="openExportToPngTiles()"
            data-tip="Split map into smaller png tiles and download as zip archive"
          >
            tiles
          </button>
          <span data-tip="Check to not allow system to automatically hide labels">
            <input
              id="showLabels"
              class="checkbox"
              type="checkbox"
              onchange="hideLabels.checked = !this.checked; invokeActiveZooming()"
              checked=""
            />
            <label for="showLabels" class="checkbox-label">Show all labels</label>
          </span>
        </div>

        <div
          data-tip="Define scale of a saved png/jpeg image (e.g. 5x). Saving big images is slow and may cause a browser crash!"
          style="margin-bottom: 0.3em"
        >
          PNG / JPEG scale:
          <input
            id="pngResolutionInput"
            data-stored="pngResolution"
            type="range"
            min="1"
            max="8"
            value="1"
            style="width: 10em"
          />
          <input id="pngResolutionOutput" data-stored="pngResolution" type="number" min="1" max="8" value="1" />
        </div>

        <p>Generator uses pop-up window to download files. Please ensure your browser does not block popups.</p>

        <div style="margin: 1em 0 0.3em; font-weight: bold">Export to GeoJSON</div>
        <div>
          <button onclick="saveGeoJsonCells()" data-tip="Download cells data in GeoJSON format">cells</button>
          <button onclick="saveGeoJsonRoutes()" data-tip="Download routes data in GeoJSON format">routes</button>
          <button onclick="saveGeoJsonRivers()" data-tip="Download rivers data in GeoJSON format">rivers</button>
          <button onclick="saveGeoJsonMarkers()" data-tip="Download markers data in GeoJSON format">markers</button>
        </div>
        <p>
          GeoJSON format is used in GIS tools such as QGIS. Check out
          <a href="https://github.com/Azgaar/Fantasy-Map-Generator/wiki/GIS-data-export" target="_blank">wiki-page</a>
          for guidance.
        </p>

        <div style="margin: 1em 0 0.3em; font-weight: bold">Export To JSON</div>
        <div>
          <button onclick="exportToJson('Full')" data-tip="Download full data in JSON">full</button>
          <button onclick="exportToJson('Minimal')" data-tip="Download minimal data in JSON">minimal</button>
          <button onclick="exportToJson('PackCells')" data-tip="Download map metadata and pack cells data in JSON">
            pack cells
          </button>
          <button onclick="exportToJson('GridCells')" data-tip="Download map metadata and grid cells data in JSON">
            grid cells
          </button>
        </div>
        <p>Export in JSON format can be used as an API replacement.</p>

        <p>
          It's also possible to export map to <i>Foundry VTT</i>, see
          <a href="https://github.com/Ethck/azgaar-foundry" target="_blank">the module.</a>
        </p>
      </div>

      <div id="saveMapData" style="display: none" class="dialog">
        <div style="margin-top: 0.3em">
          <strong>Save map to</strong>
          <button onclick="saveMap('machine')" data-tip="Download map file to your local disk" data-shortcut="Ctrl + S">
            machine
          </button>
          <button onclick="saveMap('dropbox')" data-tip="Save map file to your Dropbox" data-shortcut="Ctrl + C">
            dropbox
          </button>
          <button onclick="saveMap('storage')" data-tip="Save the project to browser storage only" data-shortcut="F6">
            browser
          </button>
        </div>
        <p>
          Maps are saved in <i>.map</i> format, that can be loaded back via the <i>Load</i> in menu. There is no way to
          restore the progress if file is lost. Please keep old save files on your machine or cloud storage as backups.
        </p>
      </div>

      <div id="loadMapData" style="display: none" class="dialog">
        <div>
          <strong>Load map from</strong>
          <button onclick="mapToLoad.click()" data-tip="Load map file (.map or .gz) from your local disk">
            machine
          </button>
          <button
            onclick="loadURL()"
            data-tip="Load map file (.map or .gz) file from URL. Note that the server should allow CORS"
          >
            URL
          </button>
          <button onclick="quickLoad()" data-tip="Load map from browser storage (if saved before)">storage</button>
        </div>

        <p>Click on <i>storage</i> to open the last saved map.</p>

        <div id="loadFromDropbox">
          <p style="margin-bottom: 0.3em">
            Or load from your Dropbox account
            <button
              id="dropboxConnectButton"
              onclick="connectToDropbox()"
              data-tip="Connect your Dropbox account to be able to load maps from it"
            >
              Connect
            </button>
          </p>

          <select id="loadFromDropboxSelect" style="width: 22em"></select>
          <div id="loadFromDropboxButtons" style="margin-bottom: 0.6em">
            <button onclick="loadFromDropbox()" data-tip="Load map file (.map or .gz) from your Dropbox">Load</button>
            <button
              onclick="createSharableDropboxLink()"
              data-tip="Select file and create a link to share with your friends"
            >
              Share
            </button>
          </div>

          <div style="margin-top: 0.3em">
            <div id="sharableLinkContainer" style="display: none">
              <a id="sharableLink" target="_blank"></a>
              <i data-tip="Copy link to the clipboard" onclick="copyLinkToClickboard()" class="icon-clone pointer"></i>
            </div>
          </div>
        </div>
      </div>

      <div id="exportToPngTilesScreen" style="display: none" class="dialog">
        <p>Map will be split into tiles and downloaded as a single zip file. Avoid saving too large images</p>
        <div data-tip="Number of columns" style="margin-bottom: 0.3em">
          <div class="label">Columns:</div>
          <input
            id="tileColsInput"
            data-stored="tileCols"
            type="range"
            min="2"
            max="26"
            value="8"
            style="width: 10em"
          />
          <input id="tileColsOutput" data-stored="tileCols" type="number" min="2" value="8" />
        </div>
        <div data-tip="Number of rows" style="margin-bottom: 0.3em">
          <div class="label">Rows:</div>
          <input
            id="tileRowsInput"
            data-stored="tileRows"
            type="range"
            min="2"
            max="26"
            value="8"
            style="width: 10em"
          />
          <input id="tileRowsOutput" data-stored="tileRows" type="number" min="2" value="8" />
        </div>
        <div data-tip="Image scale relative to image size (e.g. 5x)" style="margin-bottom: 0.3em">
          <div class="label">Scale:</div>
          <input
            id="tileScaleInput"
            data-stored="tileScale"
            type="range"
            min="1"
            max="4"
            value="1"
            style="width: 10em"
          />
          <input id="tileScaleOutput" data-stored="tileScale" type="number" min="1" value="1" />
        </div>
        <div data-tip="Calculated size of image if combined" style="margin-bottom: 0.3em">
          <div class="label">Total size:</div>
          <div id="tileSize" style="display: inline-block">1000 x 1000 px</div>
        </div>
        <div id="tileStatus" style="font-style: italic"></div>
      </div>

      <div id="alert" style="display: none" class="dialog">
        <p id="alertMessage">Warning!</p>
      </div>

      <div id="prompt" style="display: none" class="dialog">
        <form id="promptForm">
          <div id="promptText"></div>
          <input id="promptInput" type="number" step=".01" placeholder="type value" autocomplete="off" />
          <button type="submit">Confirm</button>
          <button type="button" id="promptCancel" formnovalidate>Cancel</button>
        </form>
      </div>
    </div>

    <div id="notes">
      <div id="notesHeader"></div>
      <div id="notesBody"></div>
    </div>

    <div
      id="tooltip"
      style="opacity: 0"
      data-main="Сlick the arrow button for options. Zoom in to see the map in details"
    ></div>

    <div id="mapOverlay" style="display: none">Drop a map file to open</div>

    <div id="fileInputs" style="display: none">
      <input type="file" accept=".map,.gz" id="mapToLoad" />
      <input type="file" accept=".txt,.csv" id="burgsListToLoad" />
      <input type="file" accept=".txt" id="legendsToLoad" />
      <input type="file" accept="image/*" id="imageToLoad" />
      <input type="file" accept="image/*" id="emblemImageToLoad" />
      <input type="file" accept=".svg" id="emblemSVGToLoad" />
      <input type="file" accept=".txt" id="templateToLoad" />
      <input type="file" accept=".txt" id="namesbaseToLoad" />
      <input type="file" accept=".json" id="styleToLoad" />
      <input type="file" accept=".csv" id="culturesCSVToLoad" />
    </div>

    <!-- svg elements not required for map display -->
    <svg id="defElements" width="0" height="0" style="position: absolute">
      <defs>
        <marker id="end-arrow" viewBox="0 -5 10 10" refX="6" markerWidth="7" markerHeight="7" orient="auto">
          <path d="M0,-5L10,0L0,5" fill="#000" />
        </marker>
        <marker id="end-arrow-small" viewBox="0 -5 10 10" refX="6" markerWidth="2" markerHeight="2" orient="auto">
          <path d="M0,-5L10,0L0,5" fill="#555" />
        </marker>

        <symbol id="icon-store" viewBox="0 0 616 512">
          <path
            d="M602 118.6L537.1 15C531.3 5.7 521 0 510 0H106C95 0 84.7 5.7 78.9 15L14 118.6c-33.5 53.5-3.8 127.9 58.8 136.4 4.5.6 9.1.9 13.7.9 29.6 0 55.8-13 73.8-33.1 18 20.1 44.3 33.1 73.8 33.1 29.6 0 55.8-13 73.8-33.1 18 20.1 44.3 33.1 73.8 33.1 29.6 0 55.8-13 73.8-33.1 18.1 20.1 44.3 33.1 73.8 33.1 4.7 0 9.2-.3 13.7-.9 62.8-8.4 92.6-82.8 59-136.4zM529.5 288c-10 0-19.9-1.5-29.5-3.8V384H116v-99.8c-9.6 2.2-19.5 3.8-29.5 3.8-6 0-12.1-.4-18-1.2-5.6-.8-11.1-2.1-16.4-3.6V480c0 17.7 14.3 32 32 32h448c17.7 0 32-14.3 32-32V283.2c-5.4 1.6-10.8 2.9-16.4 3.6-6.1.8-12.1 1.2-18.2 1.2z"
          />
        </symbol>

        <symbol id="icon-anchor" viewBox="0 0 30 28">
          <title>Port</title>
          <path
            d="M15 4c0-0.547-0.453-1-1-1s-1 0.453-1 1 0.453 1 1 1 1-0.453 1-1zM28 18.5v5.5c0 0.203-0.125 0.391-0.313 0.469-0.063 0.016-0.125 0.031-0.187 0.031-0.125 0-0.25-0.047-0.359-0.141l-1.453-1.453c-2.453 2.953-6.859 4.844-11.688 4.844s-9.234-1.891-11.688-4.844l-1.453 1.453c-0.094 0.094-0.234 0.141-0.359 0.141-0.063 0-0.125-0.016-0.187-0.031-0.187-0.078-0.313-0.266-0.313-0.469v-5.5c0-0.281 0.219-0.5 0.5-0.5h5.5c0.203 0 0.391 0.125 0.469 0.313s0.031 0.391-0.109 0.547l-1.563 1.563c1.406 1.891 4.109 3.266 7.203 3.687v-10.109h-3c-0.547 0-1-0.453-1-1v-2c0-0.547 0.453-1 1-1h3v-2.547c-1.188-0.688-2-1.969-2-3.453 0-2.203 1.797-4 4-4s4 1.797 4 4c0 1.484-0.812 2.766-2 3.453v2.547h3c0.547 0 1 0.453 1 1v2c0 0.547-0.453 1-1 1h-3v10.109c3.094-0.422 5.797-1.797 7.203-3.687l-1.563-1.563c-0.141-0.156-0.187-0.359-0.109-0.547s0.266-0.313 0.469-0.313h5.5c0.281 0 0.5 0.219 0.5 0.5z"
          />
        </symbol>

        <symbol id="icon-route" viewBox="0 0 512 512">
          <path
            d="M416 320h-96c-17.6 0-32-14.4-32-32s14.4-32 32-32h96s96-107 96-160-43-96-96-96-96 43-96 96c0 25.5 22.2 63.4 45.3 96H320c-52.9 0-96 43.1-96 96s43.1 96 96 96h96c17.6 0 32 14.4 32 32s-14.4 32-32 32H185.5c-16 24.8-33.8 47.7-47.3 64H416c52.9 0 96-43.1 96-96s-43.1-96-96-96zm0-256c17.7 0 32 14.3 32 32s-14.3 32-32 32-32-14.3-32-32 14.3-32 32-32zM96 256c-53 0-96 43-96 96s96 160 96 160 96-107 96-160-43-96-96-96zm0 128c-17.7 0-32-14.3-32-32s14.3-32 32-32 32 14.3 32 32-14.3 32-32 32z"
          />
        </symbol>

        <g id="defs-relief">
          <symbol id="relief-mount-1" viewBox="0 0 100 100">
            <path d="m3,69 16,-12 31,-32 15,20 30,24" fill="#fff" stroke="#5c5c70" stroke-width="1" />
            <path d="m3,69 16,-12 31,-32 -14,44" fill="#999999" />
            <path d="m3,71 h92 m-83,3 h83" stroke="#5c5c70" stroke-dasharray="7, 11" stroke-width="1" />
          </symbol>
          <symbol id="relief-hill-1" viewBox="0 0 100 100">
            <path d="m20,55 q30,-28 60,0" fill="#999999" stroke="#5c5c70" />
            <path d="m38,55 q13,-24 40,0" fill="#fff" />
            <path d="m20,58 h70 m-62,3 h50" stroke="#5c5c70" stroke-dasharray="7, 11" stroke-width="1" />
          </symbol>
          <symbol id="relief-deciduous-1" viewBox="0 0 100 100">
            <path d="m49.5,52 v7 h1 v-7 h-0.5 q13,-7 0,-16 q-13,9 0,16" fill="#fff" stroke="#5c5c70" />
            <path d="M 50,51.5 C 44,49 40,43 50,36.5" fill="#999999" />
          </symbol>
          <symbol id="relief-conifer-1" viewBox="0 0 100 100">
            <path d="m49.5,55 v4 h1 v-4 l4.5,0 -4,-8 l3.5,0 -4.5,-9 -4,9 3,0 -3.5,8 7,0" fill="#fff" stroke="#5c5c70" />
            <path d="m 46,54.5 3.5,-8 H 46.6 L 50,39 v 15.5 z" fill="#999999" />
          </symbol>
          <symbol id="relief-acacia-1" viewBox="0 0 100 100">
            <path
              d="m34.5 44.5 c 1.8, -3 8.1, -5.7 12.6, -5.4 6, -2.2 9.3, -0.9 11.9, 1.3 1.7, 0.2 3.2,-0.3 5.2, 2.2 2.7, 1.2 3.7, 2.4 2.7, 3.7 -1.6, 0.3 -2.2, 0 -4.7, -1.6 -5.2, 0.1 -7, 0.7 -8.7, -0.9 -2.8, 1 -3.6, 0 -9.7, 0.2 -4.6, 0 -8, 1.6 -9.3, 0.4 z"
              fill="#fff"
            />
            <path
              d="m52 38 c-2.3 -0.1 -4.3 1.1 -4.9 1.1 -2.2 -0.2 -5 0.2 -6.4 1 -1.3 0.7 -2.8 1.6 -3.7 2.1 -1 0.6 -3.4 1.8 -2.2 2.7 1.1 0.9 3.1 -0.2 4.2 0.3 1.4 0.8 2.9 1 4.5 0.9 1.1 -0.1 2.2 -0.4 2.4 1 0.3 1.9 1.1 3.5 2.1 5.1 0.8 2.4 1 2.8 1 6.8 l2 0 c 0 -1.1 -0.1 -4 1.2 -5.7 1.1 -1.4 1.4 -3.4 3 -4.4 0.9 -1.4 2 -2.6 3.8 -2.7 1.7 -0.3 3.8 0.8 5.1 0.3 0.9 -0.1 3.2 1 3.5 -1 0.1 -2 -2.2 -2.1 -3.2 -3.3 -1.1 -1.5 -3.3 -1.9 -4.9 -1.8 -1 -0.5 -2 -2.5 -7.3 -2.5 z m -0.5 0.4 c2.7338 -0.2 5.6 0.2 7.5 2.4 1.7 0 3.7 0 4.8 1.5 1 1.2 3.4 1.8 3.4 3 0 2.1 -3.2 0.5 -3.6 0.1 -1.3 -1.4 -2.9 -0.6 -4.5 -0.7 -1.6 -0.1 -3.2 0.4 -4.6 -0.6 -1.1 -0.7 -2.5 0.1 -3.8 -0.1 -1.8 -0.2 -4 -0.4 -5.9 -0.1 -1.4 0 -2.8 0.1 -4.2 0 -1.7 0.5 -5.5 1.1 -5.4 0.4 0.2 -1.1 4.5 -3.2 5.9 -3.9 1.9 -0.9 3.7 -1.1 6.2 -0.8 0.7 -0.2 1.7 -1.1 4.3 -1.3 z m2 6 c1.6 0.3 2 2.2 1.2 3.3 -1 1.3 -1 -1.3 -1.3 -2 -0.2 -0.5 -0.8 -1.3 0.1 -1.3 z m -12.9 0.2 c1 -0.1 3.5 -0.3 3.1 0.9 -1.4 0 -3.4 0.1 -4.4 -0.6 0.4 -0.2 0.9 -0.2 1.3 -0.3 z m5.6 -0.1 c0.8 0.1 3.1 -0.3 3 0.5 -1.3 0.6 -1.6 2.2 -2.1 3.1 -0.4 -1.2 -0.7 -2.7 -2.1 -3.2 -0.9 -0.6 1 -0.5 1.3 -0.4 z m5.3 0.3 c1.1 0.1 1.6 2.4 0.1 1.3 -1.6 -1.2 -0.6 -1.3 -0.1 -1.3 z m7.5 0.4 c1.2 0 3.3 -0.2 2.9 0.2 -1.4 1.2 -3 -0.3 -4.8 0.8 -0.9 0.5 -2 0.8 -1.1 -0.4 0.5 -0.6 1.3 -0.5 3 -0.6 z m -8.9 0.1 c0.7 1.2 2.1 1.5 2.9 2.1 0.9 1.6 -0.5 3.1 -1.3 4.5 -0.9 1.5 -1.9 2.2 -2.4 0.3 -0.1 -0.5 -1.8 -2.2 -1.2 -3.7 0.3 -1.3 0.6 -2.6 2 -3.2 z m12.5 0.1 c0.6 0.2 1.3 1.1 0.2 0.9 -1.4 -0.1 -1.4 -0.3 -0.2 -0.9 z"
              fill="#5c5c70"
            />
            <path
              d="m47 42.33 c2 0.1 4.1 0.5 6.1 -0.3 1.4 -0.3 2.6 0.8 3.6 1.6 0.7 0.4 2.5 0.7 2.7 1.2 -2.2 -0.1 -3.6 0.4 -4.8 -0.4 -1 -0.7 -2.2 -0.3 -3 -0.2 -0.9 0.1 -3 -0.4 -5.5 -0.2 -2.6 0.2 -5.1 -0.1 -7.2 0.5 -3.6 0.6 -3.7 0 -3.7 0 2.2 -2 9.1 -1.7 11.9 -2.2 z"
              fill="#999999"
            />
          </symbol>
          <symbol id="relief-palm-1" viewBox="0 0 100 100">
            <path
              d="m 48.1,55.5 2.1,0 c 0,0 1.3,-5.5 1.2,-8.6 0,-3.2 -1.1,-5.5 -1.1,-5.5 l -0.5,-0.4 -0.2,0.1 c 0,0 0.9,2.7 0.5,6.2 -0.5,3.8 -2.1,8.2 -2.1,8.2 z"
              fill="#5c5c70"
            />
            <path
              d="m 54.9,48.8 c 0,0 1.9,-2.5 0.3,-5.4 -1.4,-2.6 -4.3,-3.2 -4.3,-3.2 0,0 1.6,-0.6 3.3,-0.3 1.7,0.3 4.1,2.5 4.1,2.5 0,0 -0.6,-3.6 -3.6,-4.4 -2.2,-0.6 -4.2,1.3 -4.2,1.3 0,0 0.3,-1.5 -0.2,-2.9 -0.6,-1.4 -2.6,-1.9 -2.6,-1.9 0,0 0.8,1.1 1.2,2.2 0.3,0.9 0.3,2 0.3,2 0,0 -1.3,-1.8 -3.7,-1.5 -2.5,0.2 -3.7,2.5 -3.7,2.5 0,0 2.3,-0.6 3.4,-0.6 1.1,0.1 2.6,0.8 2.6,0.8 l -0.4,0.2 c 0,0 -1.2,-0.4 -2.7,0.4 -1.9,1.1 -2.9,3.7 -2.9,3.7 0,0 1.4,-1.4 2.3,-1.9 0.5,-0.3 1.8,-0.7 1.8,-0.7 0,0 -0.7,1.3 -0.9,3.1 -0.1,2.5 1.1,4.6 1.1,4.6 0,0 0.1,-3.4 1.2,-5.6 1,-1.9 2.3,-2.6 2.3,-2.6 l 0.4,-0.2 c 0,0 1.5,0.7 2.8,2.8 1,1.7 2.3,5 2.3,5 z"
              fill="#fff"
              stroke="#5c5c70"
              stroke-width=".6"
            />
            <path
              d="m 47.75,34.61 c 0,0 0.97,1.22 1.22,2.31 0.2,0.89 0.35,2.81 0.35,2.81 0,0 -1.59,-1.5 -3.2,-1.61 -1.82,-0.13 -3.97,1.31 -3.97,1.31 0,0 2.11,-0.49 3.34,-0.47 1.51,0.03 3.33,1.21 3.33,1.21 0,0 -1.7,0.83 -2.57,2.8 -0.88,1.97 -0.34,6.01 -0.34,6.01 0,0 0.04,-2.95 0.94,-4.96 0.8,-1.78 2.11,-2.67 2.44,-2.85 0.66,-0.34 0.49,-1.09 0.49,-1.09 0,0 -0.1,-2.18 -0.52,-3.37 -0.42,-1.21 -1.51,-2.11 -1.51,-2.11 z"
              fill="#999"
            />
            <path
              d="m 42,43.7 c 0,0 1.2,-1.1 1.8,-1.5 0.7,-0.4 2,-0.8 2,-0.8 L 46.5,40.5 c 0,0 -0.8,0 -2.3,0.8 -1.3,0.8 -2.2,2.3 -2.2,2.3 z"
              fill="#999"
            />
          </symbol>
          <symbol id="relief-grass-1" viewBox="0 0 100 100">
            <path
              d="m 49.5,53.1 c 0,-3.4 -2.4,-4.8 -3,-5.4 1,1.8 2.4,3.7 1.8,5.4 z M 51,53.2 C 51.4,49.6 49.6,47.9 48,46.8 c 1.1,1.8 2.8,4.6 1.8,6.5 z M 51.4,51.4 c 0.6,-1.9 1.8,-3.4 3,-4.3 -0.8,0.3 -2.9,1.5 -3.4,2.8 0.2,0.4 0.3,0.8 0.4,1.5 z M 52.9,53.2 c -0.7,-1.9 0.5,-3.3 1.5,-4.4 -1.7,1 -3,2.2 -2.7,4.4 z"
              fill="#5c5c70"
              stroke="none"
            />
          </symbol>
          <symbol id="relief-swamp-1" viewBox="0 0 100 100">
            <path
              d="m 50,46 v 6 m 0,0 3,-4 m -3,4 -3,-4 m -6,4.5 h 3 m 4,0 h 4 m 4,0 3,0"
              fill="none"
              stroke="#5c5c70"
              stroke-linecap="round"
            />
          </symbol>
          <symbol id="relief-dune-1" viewBox="0 0 100 100">
            <path
              d="m 28.7,52.8 c 5,-3.9 10,-8.2 15.8,-8.3 4.5,0 10.8,3.8 15.2,6.5 3.5,2.2 6.8,2 6.8,2"
              fill="none"
              stroke="#5c5c70"
              stroke-width="1.8"
            />
            <path d="m 44.2,47.6 c -3.2,3.2 3.5,5.7 5.9,7.8" fill="none" stroke="#5c5c70" />
          </symbol>

          <symbol id="relief-mount-2-bw" viewBox="-5 -5 50 50">
            <polygon
              fill="#fff"
              stroke="#5c5c70"
              stroke-width=".2"
              points="23.2198,13.2844 25.0296,15.5958 25.7023,16.6348 26.9007,17.3503 27.6924,18.8671 28.6339,19.544 29.6416,21.2874 30.1793,22.9204 30.7341,23.1774 31.5491,24.0589 31.9489,25.0324 32.4734,26.4994 33.8428,27.4678 34.673,28.5353 34.8847,28.7856 34.8285,28.9234 29.5625,31.5852 22.3428,32.6 17.9672,32.2587 6.7332,31.3779 4.2787,30.6699 0.3152,28.4746 6.2326,22.923 6.8631,18.7876 8.5478,17.0127 9.4447,14.5301 10.1033,13.4603 10.0987,12.7193 10.3459,12.4623 10.8502,12.3291 11.2616,9.4996 12.2382,9.5462 12.8014,9.7331 13.2941,9.6207 13.6109,9.8041 14.1481,9.9827 15.2052,7.9497 15.8578,7.6333 16.1761,6.4592 16.6967,5.5584 17.9672,2.6 19.2707,4.5745 23.008,12.5807 "
            />
            <polygon
              fill="#a6a6a6"
              points="23.2198,13.2844 25.0296,15.5958 25.7023,16.6348 26.9007,17.3503 27.6924,18.8671 28.6339,19.544 29.6416,21.2874 30.1793,22.9204 30.7341,23.1774 31.5491,24.0589 31.9489,25.0324 32.4734,26.4994 33.8428,27.4678 34.673,28.5353 34.8847,28.7856 34.8285,28.9234 29.5625,31.5852 22.3428,32.6 17.9672,32.2587 21.0737,27.7521 21.7612,26.7547 21.895,24.2875 20.5482,19.4183 18.3111,15.2733 19.9099,12.3973 17.9672,2.6 19.2707,4.5745 23.008,12.5807 "
            />
          </symbol>

          <symbol id="relief-mount-3-bw" viewBox="-5 -3 45 45">
            <polygon
              fill="#fff"
              stroke="#5c5c70"
              stroke-width=".2"
              points="25.3915,13.976 26.9002,15.9029 27.4611,16.769 28.4601,17.3655 29.12,18.63 29.9049,19.1943 30.745,20.6477 31.1932,22.0089 31.6557,22.2232 32.3351,22.9581 32.6684,23.7696 33.1056,24.9927 34.2473,25.7998 34.9393,26.6898 35.1158,26.8985 35.0689,27.0133 30.679,29.2324 24.6604,30.0782 21.0127,29.7937 14.3249,29.2694 12.5343,29.5211 10.0779,29.3295 3.7712,28.8351 2.3933,28.4376 0.1682,27.2051 3.4902,24.0885 3.8441,21.7669 4.7899,20.7706 5.6813,18.303 7.6713,17.3287 10.0779,12.6794 10.8097,13.7878 12.616,17.6576 13.1603,17.0841 13.8282,12.5327 14.8701,12.8548 15.3517,12.6401 16.0651,11.1879 16.9674,11.3732 17.4851,11.2365 17.793,11.2992 21.0127,5.069 22.0994,6.7151 25.2149,13.3894"
            />
            <path
              fill="#a6a6a6"
              d="M13.0266 18.6774l1.0161 1.2977 0.3775 0.5832 0.6729 0.4017 0.4443 0.8515 0.5286 0.38 0.5657 0.9788 1.365 -0.2171 0.852 0.9077 0.8012 0.7006 1.0769 -0.4987 0.587 0.888 1.3143 1.1862 1.6837 -1.1473 -3.2991 4.8038 -6.6879 -0.5243 -1.7906 0.2516 -2.4564 -0.1915 1.7439 -2.53 0.386 -0.56 0.0751 -1.3851 -0.756 -2.7335 -1.2559 -2.3269 0.8975 -1.6146 -1.0906 -5.5001 0.7318 1.1084 2.098 4.4946 0.1189 0.395zm12.3648 -4.7014l1.5087 1.9269 0.5609 0.8661 0.999 0.5965 0.6599 1.2645 0.7849 0.5643 0.8401 1.4534 0.4482 1.3613 0.4625 0.2143 0.6794 0.7349 0.3333 0.8115 0.4371 1.2231 1.1417 0.8072 0.6921 0.89 0.1764 0.2087 -0.0468 0.1148 -4.3899 2.2191 -6.0187 0.8458 -3.6476 -0.2845 2.5896 -3.7569 0.5732 -0.8316 0.1114 -2.0567 -1.1227 -4.0591 -1.8649 -3.4554 1.3328 -2.3976 -1.6195 -8.1675 1.0867 1.6461 3.1155 6.6743 0.1765 0.5866z"
            />
          </symbol>

          <symbol id="relief-mount-4-bw" viewBox="-5 -15 50 50">
            <polygon
              fill="#fff"
              stroke="#5c5c70"
              stroke-width=".2"
              points="35.1337,17.58 34.122,18.8623 31.5268,19.3968 28.6951,19.562 25.2025,19.4911 22.0686,19.053 19.2643,20.1212 14.8201,19.849 10.9897,18.983 7.7168,18.0396 4.4391,18.4829 1.598,17.8161 0.2005,16.9864 5.3775,14.1114 6.9445,13.6145 9.7551,10.1143 10.7985,9.9008 11.1418,9.0682 12.5645,7.9945 13.6885,4.6225 17.0605,0.1265 19.3086,1.2504 19.5301,1.868 20.0211,2.0967 20.0211,2.0967 22.6805,4.6225 22.7195,6.0067 23.6307,6.3628 25.5645,8.9605 27.9106,10.6515 27.912,11.4444 28.1901,12.0933 29.0346,11.8883 29.8293,12.2096"
            />
            <path
              fill="#a6a6a6"
              d="m 17.6643,2.2612 -0.3434,1.3675 0.2294,0.1158 0.1559,0.1471 0.0199,0.7745 0.1926,0.9377 -0.9604,1.4775 -0.6513,0.6353 1.7115,-0.7977 0.1556,-0.7421 0.4118,1.3885 1.1335,1.9731 0.7278,1.7545 -0.2079,1.6338 0.7769,0.6722 0.3099,1.1103 0.7775,0.5155 -0.6186,2.4264 0.5834,1.4019 3.1339,0.4381 3.4927,0.0709 2.8316,-0.1651 2.5952,-0.5346 1.0117,-1.2823 -5.3044,-5.3703 C 29.5416,12.0883 28.989155,11.867689 28.989155,11.867689 L 28.1899,12.0933 27.9117,11.4444 27.9103,10.6515 25.5643,8.9604 23.6304,6.3628 22.699656,6.0693513 22.6802,4.6224 20.0208,2.0966 19.52972,1.9051879 19.3082,1.2504 17.0601,0.1264 17.6639,2.2611 Z"
            />
          </symbol>

          <symbol id="relief-mount-5-bw" viewBox="-5 -12 45 45">
            <polygon
              fill="#fff"
              stroke="#999999"
              stroke-width=".2"
              points=".1806,16.7402 3.5087,13.7123 4.239,13.7226 5.6739,11.608 7.2317,11.0365 8.5763,9.1019 11.2204,5.1632 11.5727,4.0521 14.4278,0.1139 14.7002,0.1847 15.5903,0.6964 17.3404,2.3788 19.0704,4.6029 19.8528,4.6768 21.1765,3.7877 21.6878,3.1801 22.2862,3.3991 23.2631,4.3576 23.6605,5.4693 24.1225,6.6796 27.0001,10.5869 28.8156,9.4183 30.9325,11.9224 31.9742,13.5284 32.7597,14.0214 35.7881,17.4522 35.0629,18.009 30.1283,18.9281 26.9306,18.8548 20.8774,19.2757 15.3532,18.9995 11.8111,18.7356 9.9342,18.4948 6.0759,18.7277 3.5217,18.2204 "
            />
            <path
              fill="#a6a6a6"
              d="m 35.7881,17.4522 -3.0284,-3.4308 -0.7855,-0.493 -1.0417,-1.606 -2.1169,-2.5041 -0.1069,1.6658 -0.5815,0.9516 0.6344,0.4229 -0.1543,1.2251 0.5772,0.7838 0.6872,0.8986 -1.2159,0.8459 0.5287,0.5287 1.0044,0.6344 0.4757,0.7929 0.1189,0.6381 1.8119,-0.3376 2.4673,-0.4596 0.7252,-0.5568 z M 19.90794,4.7681953 19.028058,4.6865232 17.314205,2.4013976 15.478,0.7228 14.4279,0.1139 l -0.806,3.5794 -0.1188,1.5355 0.8458,0.7402 0.5287,-0.6344 -0.5287,2.5375 -1.2158,2.1675 2.2732,-1.9032 0.8458,0.6872 -0.2114,1.4803 -0.0528,1.0573 -0.6344,1.2688 0.2114,0.7929 -1.163,2.009 -0.6344,1.2688 -0.1615,2.1686 2.9143,0.1885 0.2605,-1.5112 -0.2115,-1.6918 2.0478,-2.1712 0.1726,-2.0052 0.7929,1.1101 0.8987,-1.3216 -0.2643,-1.3745 -0.6344,-0.37 0,-0.6344 L 18.617,8.6884 18.5253,6.9734 18.952763,5.4143697 Z M 22.2862,3.3991 21.6878,3.1801 21.651,4.264 l -0.9781,1.3217 0.6344,0.6079 -0.2379,1.4538 0.5287,1.1366 -0.1851,1.1631 0.7402,1.5331 0.7929,1.6124 -0.4757,1.2159 0.2643,0.8458 1.3216,1.2424 0.9516,0.1322 1.6457,2.3451 0.601,-0.0118 -0.5021,-1.3289 -0.0529,-0.7666 -1.0044,-0.9252 0.0528,-1.0044 0.5815,-0.0264 -1.1631,-2.4847 0.7402,0.3436 0.5551,-0.3964 0.1322,-1.0574 L 27,10.5868 24.1224,6.6796 23.263,4.3575 22.2861,3.399 Z"
            />
          </symbol>

          <symbol id="relief-mount-6-bw" viewBox="-3 -10 40 40">
            <polygon
              fill="#fff"
              stroke="#5c5c70"
              stroke-width=".1"
              points=".147,15.0385 1.6442,13.0243 3.3151,11.642 4.1434,10.0376 4.9806,9.9224 6.8955,7.0031 8.6059,5.1501 9.0229,3.7256 10.0368,2.3148 12.4348,4.6748 14.6687,3.6743 18.1604,1.3295 20.0044,0.1303 23.5192,4.0044 24.3981,3.1572 25.3939,4.067 27.6095,6.6459 28.7754,8.0029 30.309,8.9148 31.4894,10.6345 32.5909,12.0136 33.1688,13.2271 33.746,13.7886 34.1887,14.9298 35.1672,15.7874 33.2794,16.9613 30.2507,17.8494 27.9082,18.0142 25.5124,18.5408 24.1945,18.5184 22.0666,17.9886 20.7224,17.5522 19.3848,17.2692 18.0714,17.4921 16.8448,17.9273 14.923,18.4833 11.9731,18.4984 8.0901,18.2949 4.9114,17.2688 1.9652,16.102 "
            />
            <path
              fill="#a6a6a6"
              d="M 12.423779,4.7797 10.0368,2.3148 l 0.0783,5.0656 1.3012,1.3786 0.7863,1.6846 -0.3263,3.3158 2.6701,3.0025 0.4888,1.689 2.977826,-0.979118 1.371774,-0.202582 -2.8,-2.7401 1.3192,-1.0636 -2.4117,-2.9452 -0.9667,-2.0026 -1.6114,-0.9253 1.046346,-1.4408776 z"
            />
            <path
              fill="#a6a6a6"
              d="M 23.585688,4.0917598 20.0044,0.1303 l -0.048,3.1913 -0.5259,0.2023 -0.536,2.5174 0.2051,1.1566 0.7041,1.9039 0.7728,0.5503 -0.4438,2.1921 0.3455,0.8895 2.2986,1.8632 -0.6779,-1.6541 -0.0237,-0.6287 0.634,-1.5809 -0.2487,-1.5727 0.1626,-0.8586 -0.3977,-1.3888 1.3613,-1.8674 z"
            />
            <path
              fill="#a6a6a6"
              d="M 35.1672,15.7874 34.1887,14.9298 33.746,13.7886 33.1688,13.2271 32.5909,12.0136 30.309,8.9148 28.7754,8.0029 25.3939,4.067 24.3981,3.1572 24.8,5.3815 23.8709,6.152 l 1.6017,2.4409 0.4413,1.8051 -0.1898,2.2076 -1.0919,1.6288 0.2971,1.2311 1.2697,0.8769 1.9009,0.4744 0.083,1.1781 2.0678,-0.1455 3.0287,-0.8881 z"
            />
          </symbol>

          <symbol id="relief-mount-7-bw" viewBox="-8 -10 40 40">
            <polygon
              fill="#a6a6a6"
              stroke="#5c5c70"
              stroke-width=".1"
              points="22.529,16.6581 21.9433,15.0851 21.8084,13.5984 21.4921,11.5468 20.7584,9.2608 18.1129,5.2497 17.7604,4.1287 14.9038,0.1126 14.6313,0.1761 13.7407,0.6645 11.9897,2.3012 10.8187,3.7756 10.2754,4.1491 9.5595,3.9239 8.7609,3.5562 7.64,2.9875 7.0412,3.1907 6.0639,4.1237 5.6662,5.2254 5.204,6.4241 2.3249,10.2569 1.7062,11.6374 2.3144,13.0024 2.1506,13.6978 1.1772,13.673 1.0735,15.1182 0.4367,16.8402 0.1318,17.5293 2.3944,18.5311 8.4508,19.113 13.9779,18.9836 17.5219,18.8136 19.3998,18.6226 "
            />
            <path
              fill="#fff"
              d="M9.7866 4.7504l0.7194 -0.1357 1.627 -2.2285 1.7201 -1.6924 1.0506 -0.5812 0.8064 3.6027 0.1188 1.5394 -0.8462 0.7182 -0.529 -0.6488 0.529 2.553 1.2165 2.2009 -2.2744 -1.9646 -0.8462 0.6652 0.2115 1.4867 0.0529 1.0592 0.6347 1.2863 -0.2115 0.7877 1.1636 2.041 0.6347 1.2862 0.1616 2.1741 -2.9158 0.1112 -0.2607 -1.5189 0.2116 -1.6871 -2.0489 -2.2267 -0.1727 -2.0108 -0.7934 1.0896 -0.8992 -1.3462 0.2645 -1.3681 0.6347 -0.3534 0 -0.6347 0.9661 -0.3741 0.0918 -1.7136 -0.1058 -1.431 -0.9118 -0.6854zm-2.7454 -1.5597l0.5987 -0.2032 0.0368 1.0853 0.9786 1.3484 -0.6347 0.5914 0.238 1.4609 -0.529 1.1231 0.1852 1.1687 -0.7406 1.5142 -0.7934 1.5922 1.5431 0.6224 1.2433 0.621 0.0153 0.9133 -0.2397 0.777 1.8113 0.1046 1.0597 0.4823 0.9965 2.6186 -4.3596 0.1022 -6.0565 -0.5819 -2.2625 -1.0018 0.3049 -0.6891 0.6368 -1.722 0.1037 -1.4452 0.8463 0.5647 0.2909 -1.2353 -0.6082 -1.365 0.6187 -1.3805 2.8791 -3.8328 0.8598 -2.3004 0.9774 -0.933z"
            />
          </symbol>

          <symbol id="relief-mountSnow-1-bw" viewBox="-5 -5 50 50">
            <polygon
              fill="#fff"
              stroke="#999999"
              stroke-width=".2"
              points="23.2198,13.2844 25.0296,15.5958 25.7023,16.6348 26.9007,17.3503 27.6924,18.8671 28.6339,19.544 29.6416,21.2874 30.1793,22.9204 30.7341,23.1774 31.5491,24.0589 31.9489,25.0324 32.4734,26.4994 33.8428,27.4678 34.673,28.5353 34.8847,28.7856 34.8285,28.9234 29.5625,31.5852 22.3428,32.6 17.9672,32.2587 6.7332,31.3779 4.2787,30.6699 0.3152,28.4746 6.2326,22.923 6.8631,18.7876 8.5478,17.0127 9.4447,14.5301 10.1033,13.4603 10.0987,12.7193 10.3459,12.4623 10.8502,12.3291 11.2616,9.4996 12.2382,9.5462 12.8014,9.7331 13.2941,9.6207 13.6109,9.8041 14.1481,9.9827 15.2052,7.9497 15.8578,7.6333 16.1761,6.4592 16.6967,5.5584 17.9672,2.6 19.2707,4.5745 23.008,12.5807 "
            />
            <polygon
              fill="#a6a6a6"
              points="23.2198,13.2844 25.0296,15.5958 25.7023,16.6348 26.9007,17.3503 27.6924,18.8671 28.6339,19.544 29.6416,21.2874 30.1793,22.9204 30.7341,23.1774 31.5491,24.0589 31.9489,25.0324 32.4734,26.4994 33.8428,27.4678 34.673,28.5353 34.8847,28.7856 34.8285,28.9234 29.5625,31.5852 22.3428,32.6 17.9672,32.2587 21.0737,27.7521 21.7612,26.7547 21.895,24.2875 20.5482,19.4183 18.3111,15.2733 19.9099,12.3973 17.9672,2.6 19.2707,4.5745 23.008,12.5807 "
            />
            <polygon
              fill="#fff"
              stroke="#999999"
              stroke-width=".15"
              points="13.6805,10.8818 11.2616,9.4996 11.0559,10.9144 11.8389,12.3618 13.3272,12.0311 14.0879,13.8832 16.1715,12.0311 16.6014,13.7839 17.9244,11.1712 18.1228,12.3618 19.4457,11.2042 19.5775,10.7214 17.9672,2.6 16.6967,5.5584 16.1761,6.4592 15.8578,7.6333 15.2052,7.9497"
            ></polygon>
            <polygon
              fill="#e6e6e6"
              stroke="#BDBFC1"
              stroke-width=".15"
              points="17.9672,2.6 18.0463,6.2528 18.383,4.6971 18.8561,7.083 18.5661,9.6743 19.0983,8.3046 19.5775,10.7214 20.0823,11.6761 20.8761,12.106 21.1407,10.9815 21.5375,11.8084 21.8021,11.0808 22.4764,11.4421 19.2707,4.5745 "
            ></polygon>
          </symbol>

          <symbol id="relief-mountSnow-2-bw" viewBox="-5 -8 45 45">
            <polygon
              fill="#fff"
              stroke="#999999"
              stroke-width=".2"
              points="25.3915,9.1042 26.9002,11.0311 27.4611,11.8972 28.4601,12.4937 29.12,13.7582 29.9049,14.3225 30.745,15.7759 31.1932,17.1372 31.6557,17.3514 32.3351,18.0863 32.6684,18.8978 33.1056,20.1209 34.2473,20.9281 34.9393,21.818 35.1158,22.0267 35.0689,22.1415 30.679,24.3606 24.6604,25.2064 16.2214,24.5482 14.3198,24.3984 12.5343,24.6493 6.8513,24.206 3.7712,23.9633 2.3933,23.5658 0.1682,22.3334 3.4902,19.2167 3.8441,16.8951 4.7899,15.8988 5.6813,13.4312 7.6713,12.4569 8.6899,10.5168 10.0779,7.8076 10.8097,8.916 12.616,12.7858 13.1603,12.2124 13.8282,7.6609 14.983,8.5189 16.0651,6.3161 17.4391,7.1013 18.9517,4.2204 21.0127,0.1972 22.0994,1.8433 25.2149,8.5176 "
            />
            <path
              fill="#999999"
              d="M13.0266 13.8057l1.0161 1.2977 0.3775 0.5832 0.6729 0.4017 0.4443 0.8515 0.5286 0.38 0.5657 0.9788 1.365 -0.2171 0.852 0.9077 0.8012 0.7006 1.0769 -0.4987 0.587 0.888 1.3143 1.1862 1.6837 -1.1473 -3.2991 4.8038 -6.6879 -0.5243 -1.7906 0.2516 -2.4564 -0.1915 1.7439 -2.53 0.386 -0.56 0.0751 -1.3851 -0.756 -2.7335 -1.2559 -2.3269 0.8975 -1.6146 -1.0906 -5.5001 0.7318 1.1084 2.098 4.4946 0.1189 0.395zm12.3648 -4.7014l1.5087 1.9269 0.5609 0.8661 0.999 0.5965 0.6599 1.2645 0.7849 0.5643 0.8401 1.4534 0.4482 1.3613 0.4625 0.2143 0.6794 0.7349 0.3333 0.8115 0.4371 1.2231 1.1417 0.8072 0.6921 0.89 0.1764 0.2087 -0.0468 0.1148 -4.3899 2.2191 -6.0187 0.8458 -3.6476 -0.2845 2.5896 -3.7569 0.5732 -0.8316 0.1114 -2.0567 -1.1227 -4.0591 -1.8649 -3.4554 1.3328 -2.3976 -1.6195 -8.1675 1.0867 1.6461 3.1155 6.6743 0.1765 0.5866z"
            />
            <path
              fill="#e6e6e6"
              stroke="#999999"
              stroke-width=".1"
              d="M10.0779 7.8076l1.0906 5.5 0.4152 -0.4101 1.205 0.2576 -1.9788 -4.2391 -0.7319 -1.1084zm12.5157 0.4025l-1.5808 -8.0129 1.0867 1.6461 2.7072 5.7999 -0.3838 0.5883 -0.4636 -0.296 -0.311 0.8985 -0.5241 -0.3498 -0.264 1.1861 -0.2771 -0.6052 -0.4468 0.1919 0.2592 -0.4664 0.1982 -0.5806zm-5.5775 -1.7214l-0.951 -0.1724 1.374 0.785 0.362 -0.6894 -0.3159 -0.047 -0.4691 0.1238zm-2.1029 1.4753l-1.0849 -0.303 1.1548 0.858 0.3482 -0.7086 -0.4181 0.1537z"
            />
            <path
              fill="#FEFEFE"
              stroke="#BDBFC1"
              stroke-width=".2"
              d="M13.4943 9.9367l-0.0192 0.1307 0.773 1.6295 0.9687 -1.1448 0.5504 0.5063 1.0347 -1.2109 0.5504 1.8934 1.0128 -1.387 0.8365 -0.2862 0.4623 0.7926 0.7045 -1.5412 0.9308 1.4432 1.3328 -2.3976 -1.6195 -8.1675 -3.5736 6.904 -1.374 -0.785 -1.0821 2.2027 -1.1548 -0.858 -0.3339 2.2758zm-3.4165 -2.1291l-2.4065 4.6492 0.742 0.5232 1.1558 -0.2973 1.5993 0.6249 -1.0906 -5.5z"
            />
          </symbol>

          <symbol id="relief-mountSnow-3-bw" viewBox="-5 -15 50 50">
            <polygon
              fill="#fff"
              stroke="#999999"
              stroke-width=".2"
              points="35.1337,17.58 34.122,18.8623 31.5268,19.3968 28.6951,19.562 25.2025,19.4911 22.0686,19.053 19.2643,20.1212 14.8201,19.849 10.9897,18.983 7.7168,18.0396 4.4391,18.4829 1.598,17.8161 0.2005,16.9864 5.3775,14.1114 6.9445,13.6145 9.7551,10.1143 10.7985,9.9008 11.1418,9.0682 12.5645,7.9945 13.6885,4.6225 17.0605,0.1265 19.3086,1.2504 19.5301,1.868 20.0211,2.0967 20.0211,2.0967 22.6805,4.6225 22.7195,6.0067 23.6307,6.3628 25.5645,8.9605 27.9106,10.6515 27.912,11.4444 28.1901,12.0933 29.0346,11.8883 29.8293,12.2096 "
            />
            <path
              fill="#a6a6a6"
              d="M17.6643 2.2612l-0.3434 1.3675 0.2294 0.1158 -0.1215 0.4558 0.0287 0.4166 0.2487 -0.7253 0.0199 0.7745 0.1926 0.9377 -0.9604 1.4775 -0.6513 0.6353 1.7115 -0.7977 0.1556 -0.7421 0.4118 1.3885 1.1335 1.9731 0.7278 1.7545 -0.2079 1.6338 0.7769 0.6722 0.3099 1.1103 0.7775 0.5155 -0.6186 2.4264 0.5834 1.4019 3.1339 0.4381 3.4927 0.0709 2.8316 -0.1651 2.5952 -0.5346 1.0117 -1.2823 -5.3044 -5.3703c-0.2875,-0.1214 -0.5799,-0.2431 -0.8727,-0.3502l-0.3389 0.6201 -0.3658 -0.0155 -0.0618 -0.3708 -0.2782 -0.6489 -0.0014 -0.7929 -2.346 -1.6911 -1.9339 -2.5976 -0.5212 0.0497 -0.3686 0.3529 -0.0604 -2.143 -2.6594 -2.5258 -0.1784 0.6424 -0.5342 -1.4886 -2.2481 -1.124 0.6038 2.1347z"
            />
            <polygon
              fill="#e6e6e6"
              stroke="#999999"
              stroke-width=".1"
              points="19.3086,1.2504 17.0605,0.1265 17.3208,3.6287 17.4576,4.6169 18.2355,6.3837 18.4568,7.1297 19.5555,7.6994 19.9956,6.8192 20.3478,7.1273 21.0519,7.0392 21.7122,7.6554 21.8442,6.0709 22.7409,6.7655 22.6805,4.6225 20.0211,2.0967 19.8426,2.7391 "
            />
            <polygon
              fill="#FEFEFE"
              stroke="#BDBFC1"
              stroke-width=".2"
              points="12.5645,7.9945 12.3831,8.1314 13.3341,8.871 14.0824,8.3429 15.3587,9.2232 16.3071,7.7165 18.0186,6.9189 18.2355,6.3837 17.9188,5.6039 17.7262,4.6661 17.708,3.9637 17.4576,4.6169 17.4288,4.2003 17.5502,3.7445 17.3208,3.6287 17.6643,2.2612 17.0605,0.1265 13.6885,4.6225 "
            />
          </symbol>

          <symbol id="relief-mountSnow-4-bw" viewBox="-5 -12 45 45">
            <polygon
              fill="#fff"
              stroke="#999999"
              stroke-width=".2"
              points=".1806,16.758 3.5087,13.7301 3.9652,14.1439 5.6739,11.6258 7.2317,11.0543 8.5763,9.1197 11.2204,5.181 11.5727,4.0699 14.4278,0.1317 15.4779,0.7406 17.2215,2.5024 18.8233,4.7482 19.5423,4.903 21.1765,3.8055 21.6878,3.1979 22.2862,3.4169 23.2631,4.3754 23.6605,5.4871 24.1225,6.6974 27.0001,10.6046 28.8156,9.4361 30.9325,11.9401 31.9742,13.5462 32.7597,14.0392 35.7881,17.47 35.0629,18.0268 30.1283,18.9459 26.9306,18.8725 20.8774,19.2934 15.3532,19.0173 11.8111,18.7534 9.9342,18.5126 6.0759,18.7455 3.5217,18.2382 "
            />
            <path
              fill="#a6a6a6"
              d="M35.7881 17.47l-3.0284 -3.4308 -0.7855 -0.493 -1.0417 -1.606 -2.1169 -2.5041 -0.1069 1.6658 -0.5815 0.9516 0.6344 0.4229 -0.1543 1.2251 0.5772 0.7838 0.6872 0.8986 -1.2159 0.8459 0.5287 0.5287 1.0044 0.6344 0.4757 0.7929 0.1189 0.6381 1.8119 -0.3376 2.4673 -0.4596 0.7252 -0.5568zm-16.2458 -12.567l-0.719 -0.1548 -1.6261 -2.2705 -1.7192 -1.7371 -1.0501 -0.6089 -0.806 3.5794 -0.1188 1.5355 0.8458 0.7402 0.5287 -0.6344 -0.5287 2.5375 -1.2158 2.1675 2.2732 -1.9032 0.8458 0.6872 -0.2114 1.4803 -0.0528 1.0573 -0.6344 1.2688 0.2114 0.7929 -1.163 2.009 -0.6344 1.2688 -0.1615 2.1686 2.9143 0.1885 0.2605 -1.5112 -0.2115 -1.6918 2.0478 -2.1712 0.1726 -2.0052 0.7929 1.1101 0.8987 -1.3216 -0.2643 -1.3745 -0.6344 -0.37 0 -0.6344 -0.9656 -0.3996 -0.0917 -1.715 0.1057 -1.4274 0.9113 -0.6609zm2.7439 -1.4861l-0.5984 -0.219 -0.0368 1.0839 -0.9781 1.3217 0.6344 0.6079 -0.2379 1.4538 0.5287 1.1366 -0.1851 1.1631 0.7402 1.5331 0.7929 1.6124 -0.4757 1.2159 0.2643 0.8458 1.3216 1.2424 0.9516 0.1322 1.6457 2.3451 0.601 -0.0118 -0.5021 -1.3289 -0.0529 -0.7666 -1.0044 -0.9252 0.0528 -1.0044 0.5815 -0.0264 -1.1631 -2.4847 0.7402 0.3436 0.5551 -0.3964 0.1322 -1.0574 0.4061 -0.629 -2.8776 -3.9072 -0.8594 -2.3221 -0.9769 -0.9585z"
            />
            <polygon
              fill="#FEFEFE"
              stroke="#BDBFC1"
              stroke-width=".2"
              points="13.6218,3.7111 14.4278,0.1317 11.5727,4.0699 11.2204,5.181 10.2231,6.6667 11.5706,6.2509 11.13,8.3655 12.0332,7.6827 11.8349,10.1277 13.2509,9.9588 14.3488,7.89 14.8775,5.3524 14.3338,5.9737 13.503,5.2466"
            />
            <polygon
              fill="#e6e6e6"
              stroke="#999999"
              stroke-width=".1"
              points="14.3488,7.89 13.2509,9.9588 15.4062,8.1543 16.252,8.8415 16.9456,9.555 17.7385,8.718 18.617,8.7063 18.5357,6.8509 18.631,5.5638 19.5423,4.903 18.8233,4.7482 17.1189,2.3987 16.3376,1.6091 15.4779,0.7406 14.4278,0.1317 13.6218,3.7111 13.503,5.2466 14.3488,5.9868 14.8775,5.3524 "
            />
            <polygon
              fill="#FEFEFE"
              stroke="#BDBFC1"
              stroke-width=".2"
              points="18.5357,6.8509 18.617,8.7063 19.5826,9.1059 19.5826,9.7403 20.5423,9.1255 21.4131,9.9649 21.5982,8.8018 21.0695,7.6652 21.3074,6.2114 20.673,5.6035 21.6511,4.2818 21.6878,3.1979 21.1765,3.8055 19.5423,4.903 18.631,5.5638 "
            />
            <polygon
              fill="#e6e6e6"
              stroke="#999999"
              stroke-width=".1"
              points="22.2862,3.4169 21.6878,3.1979 21.6511,4.2818 20.673,5.6035 21.3074,6.2114 21.0695,7.6652 21.5982,8.8018 21.4131,9.9649 22.4095,10.3424 23.0704,9.1529 23.6651,9.4173 24.2158,8.2718 24.8766,8.448 25.0536,7.9618 24.1225,6.6974 23.2631,4.3754 "
            />
          </symbol>

          <symbol id="relief-mountSnow-5-bw" viewBox="-3 -10 40 40">
            <polygon
              fill="#fff"
              stroke="#999999"
              stroke-width=".2"
              points=".147,15.0422 1.6442,13.028 3.3151,11.6457 4.1434,10.0413 4.7098,10.3389 6.8955,7.0068 8.6059,5.1538 9.0229,3.7293 10.0368,2.3185 12.2006,4.7834 14.6687,3.678 18.1604,1.3332 20.0044,0.134 23.2333,4.2834 24.3981,3.1609 25.3939,4.0708 27.6095,6.6496 28.7754,8.0066 30.309,8.9186 31.4894,10.6382 32.5909,12.0173 33.1688,13.2308 33.746,13.7923 34.1887,14.9335 35.1672,15.7911 33.2794,16.965 30.2507,17.8531 27.9082,18.0179 25.5124,18.5445 24.1945,18.5221 22.0666,17.9923 20.7224,17.5559 19.3848,17.2729 18.0714,17.4958 16.8448,17.931 14.923,18.487 11.9731,18.5021 8.0901,18.2986 4.9114,17.2725 1.9652,16.1057 "
            />
            <polygon
              fill="#a6a6a6"
              points="12.2006,4.7834 10.0368,2.3185 10.1151,7.3841 11.4163,8.7627 12.2026,10.4473 11.8763,13.7632 14.5464,16.7656 15.0352,18.4546 19.3848,17.2729 16.5848,14.5328 17.904,13.4692 15.4923,10.524 14.5256,8.5214 12.9142,7.5961 13.9488,6.2257 "
            />
            <polygon
              fill="#a6a6a6"
              points="23.2333,4.2834 20.0044,0.134 19.9564,3.3253 19.4305,3.5276 18.8945,6.045 19.0996,7.2016 19.8037,9.1055 20.5765,9.6558 20.1327,11.8479 20.4782,12.7374 22.7768,14.6006 22.0989,12.9465 22.0752,12.3178 22.7092,10.7369 22.4605,9.1642 22.6231,8.3056 22.2254,6.9168 23.5867,5.0494 "
            />
            <polygon
              fill="#a6a6a6"
              points="35.1672,15.7911 34.1887,14.9335 33.746,13.7923 33.1688,13.2308 32.5909,12.0173 30.309,8.9186 28.7754,8.0066 25.3939,4.0708 24.3981,3.1609 24.8,5.3852 23.8709,6.1557 25.4726,8.5966 25.9139,10.4017 25.7241,12.6093 24.6322,14.2381 24.9293,15.4692 26.199,16.3461 28.0999,16.8205 28.1829,17.9986 30.2507,17.8531 33.2794,16.965 "
            />
            <path
              fill="#FEFEFE"
              stroke="#BDBFC1"
              stroke-width=".2"
              d="M23.5867 5.0494l-0.3534 -0.766 1.1648 -1.1224 0.4019 2.2243 -0.9291 0.7703 -0.625 0.3316 0.3847 -0.5987 -0.6602 0.0063 0.6163 -0.8453zm-13.4716 2.3346l-0.0783 -5.0655 -1.0139 1.4107 -0.417 1.4245 -1.7104 1.8531 -0.1947 0.8318 0.728 -0.2978 0.1765 0.728 0.7942 -1.2465 0.0883 0.4854 0.4413 -0.5405 0.5736 1.5994 0.6126 -1.1826zm4.5536 -3.706l-2.4681 1.1052 1.7481 1.4424 -0.5173 0.6852 0.2957 0.3987 0.75 -0.706 0.364 0.3641 0.5516 -1.2024 0.1875 0.5295 0.2096 -0.2317 0.386 0.4192 0.6398 0.3199 0.2427 -0.9597 0.5736 1.4009 0.5074 -0.7943 0.3089 0.5074 0.5227 -0.4801 -0.0765 -0.4315 0.536 -2.5174 0.5259 -0.2023 0.0479 -3.1913 -5.3356 3.544z"
            />
            <path
              fill="#e6e6e6"
              stroke="#999999"
              stroke-width=".1"
              d="M24.3981 3.1609l0.4019 2.2243 -0.9291 0.7703 0.6886 0.5329 0.6056 0.4387 0.0221 -1.0588 0.4412 0.5735 0.0833 -0.7817 0.5106 0.4833 0.4121 -0.8287 -1.0977 -1.2778 -1.1387 -1.076zm-14.3613 -0.8424l0.0783 5.0655 0.3029 0.8298 0.4744 -0.8494 0.7721 0.6288 0.4523 -1.3898 1.3147 0.3075 0.5173 -0.6852 -1.7481 -1.4424 -2.1638 -2.4647zm8.8577 3.7265l0.0765 0.4315 0.591 -0.3692 0.375 0.7943 0.728 -1.3679 0.1765 0.4413 0.3971 -0.7942 0.3971 0.9045 0.5515 -0.6619 0.1765 0.6619 0.5295 -0.6178 0.077 0.4271 0.6163 -0.8453 -0.3534 -0.766 -3.229 -4.1494 -0.0479 3.1913 -0.5259 0.2023 -0.536 2.5174z"
            />
          </symbol>

          <symbol id="relief-mountSnow-6-bw" viewBox="-8 -10 40 40">
            <polygon
              fill="#a6a6a6"
              points="22.529,16.6762 21.9433,15.1032 21.8165,13.7052 21.6735,12.1298 20.7584,9.2788 18.1129,5.2678 17.7604,4.1468 14.9038,0.1306 13.8531,0.7119 12.1086,2.4283 10.506,4.6328 9.7866,4.7685 8.1515,3.6271 7.64,3.0056 7.0412,3.2088 6.0639,4.1418 5.6662,5.2435 5.204,6.4422 2.3249,10.275 1.7062,11.6555 2.3144,13.0205 2.0235,14.2558 1.1772,13.6911 1.0735,15.1363 0.4367,16.8583 0.138,17.55 2.3944,18.5492 8.4508,19.1311 13.9779,19.0017 17.5219,18.8317 19.3998,18.6407 "
            />
            <path
              fill="#fff"
              stroke="#999999"
              stroke-width=".1"
              d="M9.7866 4.7685l0.7194 -0.1357 1.627 -2.2285 1.7201 -1.6924 1.0506 -0.5812 0.8064 3.6027 0.1188 1.5394 -0.8462 0.7182 -0.529 -0.6488 0.529 2.553 1.2165 2.2009 -2.2744 -1.9646 -0.8462 0.6652 0.2115 1.4867 0.0529 1.0592 0.6347 1.2863 -0.2115 0.7877 1.1636 2.041 0.6347 1.2862 0.1616 2.1741 -2.9158 0.1112 -0.2607 -1.5189 0.2116 -1.6871 -2.0489 -2.2267 -0.1727 -2.0108 -0.7934 1.0896 -0.8992 -1.3462 0.2645 -1.3681 0.6347 -0.3534 0 -0.6347 0.9661 -0.3741 0.0918 -1.7136 -0.1058 -1.431 -0.9118 -0.6854zm-2.7454 -1.5597l0.5987 -0.2032 0.0368 1.0853 0.9786 1.3484 -0.6347 0.5914 0.238 1.4609 -0.529 1.1231 0.1852 1.1687 -0.7406 1.5142 -0.7934 1.5922 1.5431 0.6224 1.2433 0.621 0.0153 0.9133 -0.2397 0.777 1.8113 0.1046 1.0597 0.4823 0.9965 2.6186 -4.3596 0.1022 -6.0565 -0.5819 -2.2625 -1.0018 0.3049 -0.6891 0.6368 -1.722 0.1037 -1.4452 0.8463 0.5647 0.2909 -1.2353 -0.6082 -1.365 0.6187 -1.3805 2.8791 -3.8328 0.8598 -2.3004 0.9774 -0.933z"
            />
            <polygon
              fill="#FEFEFE"
              stroke="#BDBFC1"
              stroke-width=".2"
              points="6.0639,4.1418 5.204,6.4422 5.4977,7.1815 6.6217,6.7187 6.6217,8.1952 7.3049,7.7104 7.6135,8.2393 8.2586,7.4916 8.0206,6.0308 8.6553,5.4393 7.6767,4.0909 7.64,3.0056 7.0412,3.2088"
            />
            <polygon
              fill="#FEFEFE"
              stroke="#BDBFC1"
              stroke-width=".2"
              points="10.506,4.6328 9.7866,4.7685 10.6984,5.4539 10.7907,6.7013 10.7583,7.7417 11.3161,7.2916 11.6687,8.3715 12.4841,6.7847 12.8809,7.7104 13.7183,6.5423 14.2693,7.3137 14.9829,7.8952 14.4539,5.3422 14.9829,5.991 15.8291,5.2728 15.7102,3.7334 14.9038,0.1306 13.8531,0.7119 12.1086,2.4283 "
            />
            <polygon
              fill="#e6e6e6"
              stroke="#999999"
              stroke-width=".1"
              points="7.6767,4.0909 7.64,3.0056 8.0828,3.5436 10.6984,5.4539 10.7907,6.7013 10.7583,7.7417 10.236,6.9831 10.0156,7.3799 9.8613,6.7187 9.3985,8.1512 9.2443,7.2476 8.5831,7.9528 8.2586,7.4916 8.0206,6.0308 8.6553,5.4393"
            />
            <polygon
              fill="#e6e6e6"
              stroke="#999999"
              stroke-width=".1"
              points="15.7144,3.789 15.7102,3.7334 14.9038,0.1306 17.7604,4.1468 18.1129,5.2678 18.4803,5.8251 18.0375,6.4433 17.5306,5.5507 17.2662,6.333 16.4727,6.9392 16.5168,6.1236 15.9768,6.7518 14.9829,5.991 15.8291,5.2728"
            />
          </symbol>

          <symbol id="relief-vulcan-1-bw" viewBox="-5 -10 110 110">
            <ellipse fill="#999999" opacity=".5" cx="50" cy="64" rx="30" ry="4"></ellipse>
            <path
              fill="#fff"
              stroke="#5c5c70"
              stroke-width=".1"
              d="m 40.318,43.0945 1.2624,1.4851 2.2879,1.7295 3.6464,2.047 0.7864,2.661 1.4661,1.7722 2.5083,1.3532 2.7505,0.3824 4.548,2.8992 4.3962,2.9284 4.26,2.533 0.0746,0.7449 L 55.9019,63.906275 34.0507,63.6698 18.4326,63.9645 C 12.828851,63.668708 7.2014518,63.758742 1.6058,63.3217 l 6.2682,-4.7224 1.9305,-0.55 3.4543,-2.435 1.6264,-1.9274 1.8235,-2.4455 3.3521,-1.8555 3.2709,-1.0652 1.9097,-2.384 3.0893,-2.7945 c 3.9306,0.6688 7.9292,0.6208 11.9872,-0.0477 z"
            />
            <path
              fill="#ccced1"
              d="m 49.5039,15.24 c 4.126703,7.052655 8.039095,13.804219 12.155745,20.862742 1.488026,-0.891499 3.410852,-3.023567 6.036874,-2.472897 2.428268,0.509201 4.651275,-2.255062 4.159839,-4.78358 -0.217013,-2.829685 3.079909,-3.305126 3.604522,-5.767821 1.199165,-1.401687 4.285792,-0.670495 4.300237,-3.289515 1.317092,-3.046435 4.612248,0.247252 6.586644,0.779407 2.59062,0.607246 4.174976,-3.029778 6.829551,-2.126519 1.641144,0.31721 3.28076,-1.413401 4.889632,-0.472092 0.899819,-0.602875 2.556726,-1.262629 3.057376,-1.606987 -0.0938,-2.129258 -1.275026,-3.744355 -2.898687,-4.950311 0.231204,-1.150324 0.401964,-1.114283 -0.873573,-1.2106 C 95.554729,8.7767013 93.878043,7.2634405 91.390175,7.641688 89.344758,6.9717881 88.477997,4.4543316 86.10117,4.3466882 81.981911,3.3946205 77.938067,1.9937993 73.709246,1.6052857 71.108742,0.94989087 68.393797,-0.77510509 65.682632,0.42725723 63.303424,0.88219116 60.548455,-0.08283459 58.507815,1.5652706 c -2.11057,0.5972 -2.698897,2.7373648 -4.21029,4.0606937 -1.394921,1.4065359 0.4728,2.8050874 0.99098,3.5161668 C 53.757109,9.7455849 54.166,12.790671 51.884625,12.985492 51.002361,13.616529 50.47659,14.713814 49.5039,15.24 Z"
            />
            <path
              fill="#babcbf"
              d="m 49.5044,15.2403 c 1.872188,-0.138196 2.425637,-2.845949 4.57073,-2.201258 1.144577,-1.239645 1.265218,-3.6735644 2.316299,-4.609529 -2.750165,-1.309054 0.09506,-3.2190069 0.839232,-4.8872084 2.490924,-0.9535868 5.115499,-2.55017169 8.057631,-1.7612421 2.695454,-0.85754135 5.305909,0.7870874 7.773131,0.8026466 2.409706,0.8458431 4.451711,2.5306898 6.680161,3.7956721 2.296373,1.6938053 6.468639,1.0207559 6.988137,4.7481988 1.338125,1.622767 3.237548,3.048988 2.244679,5.537294 0.679868,3.02407 -3.661575,3.975327 -5.196628,1.728355 -2.133084,-2.611082 -5.551095,1.155994 -6.569356,2.71362 -2.323326,1.338206 -3.135934,3.85674 -5.292457,5.674255 -1.358773,2.083033 0.458567,5.947891 -3.336796,6.161344 -2.570722,-0.224246 -5.261874,-0.123487 -6.325269,2.757753 -1.891404,1.772211 -4.914889,1.91023 -7.451697,1.999909 -3.066782,0.108414 -6.090481,0.05214 -8.834187,1.704591 -2.2624,1.362577 -4.755417,2.854218 -5.662414,3.901477 -4.174179,1.077038 -7.897276,0.780504 -12.093528,0.04834 0,0 3.350593,-3.582697 3.163478,-5.042706 0.406132,-3.386301 3.499175,-5.702031 4.108846,-8.738619 0.971591,-2.557705 0.952214,-5.995887 2.953555,-7.863737 2.36467,-0.738408 4.092762,-2.156665 6.402735,-2.934491 0.879172,-2.130542 2.48838,-2.667714 4.663718,-3.534667 z"
            />
            <path
              fill="#acafb1"
              d="m 48.8842,16.8699 c -1.785997,0.666059 -3.779594,1.246295 -4.301192,3.452184 -0.540223,2.017352 -3.325715,0.423824 -4.4494,2.229627 -2.494158,-0.673487 -2.019728,1.842576 -2.548911,3.383955 -1.030703,1.62935 -1.137361,3.670141 -1.837647,5.502122 -1.455888,1.8507 -2.889787,3.789023 -3.24835,6.150212 -0.642322,1.376996 -2.934697,4.232379 -0.743197,5.002756 3.276226,0.386491 6.865778,0.297294 9.668135,-1.671956 1.992411,-0.789487 3.045587,-2.751047 4.759962,-3.9329 1.189858,-0.552573 2.437218,-0.990001 3.777113,-0.811 1.907845,-0.01586 3.785152,-0.37634 5.672187,0.08659 1.978298,0.05321 -0.985275,-1.72622 0.908237,-2.032705 1.474101,-0.686901 1.911031,0.604732 2.789914,1.139442 0.72917,-0.07521 2.250626,0.907421 2.007947,-0.440847 0.758787,-1.773464 1.770613,-4.072587 4.142983,-2.926051 2.333406,0.19823 4.47649,-1.394758 4.631923,-3.803654 0.362029,-1.471587 0.276981,-3.115583 2.276446,-2.98201 1.962019,-0.748148 2.294241,-3.385233 1.73135,-5.017763 -1.101666,-1.371396 0.2507,-2.912999 1.327975,-3.832219 C 76.753843,15.865967 76.05046,14.539717 75.8076,13.5526 75.093304,12.114215 75.790908,10.071743 73.619081,9.8482516 73.01701,8.9737297 73.441083,9.1741347 73.177475,8.0910547 73.369945,6.7516759 71.308021,6.5289859 70.544363,5.961525 69.388061,5.7732631 68.393705,5.6084929 67.935746,4.3663653 66.967743,3.8236661 65.71194,4.1429299 64.948956,3.4639047 63.291625,3.3657328 61.428814,3.5574961 60.282876,4.8581076 58.121173,5.7094079 58.85032,7.8874864 58.599915,9.5497793 57.986956,10.324235 56.222784,10.545705 57.2655,11.7578 c -1.231347,1.555102 -2.786541,2.706743 -4.5422,3.6878 -1.39291,0.193194 -2.512881,1.045804 -3.8391,1.4243 z"
            />
            <path
              fill="#babcbf"
              d="M62.0795 7.1509c-3.6626,10.7376 -8.7984,12.2353 -17.6693,17.6735 -3.1861,1.9533 -5.9317,3.3553 -6.0646,7.1857 -0.1229,3.5442 -4.6114,6.1599 -6.1924,10.645 1.2102,-4.6426 5.7709,-7.1396 5.8438,-10.622 0.0846,-4.0368 2.831,-5.5158 6.1732,-7.6137 8.6206,-5.4111 13.739,-6.9169 17.2433,-17.4406 0.0476,-0.1838 0.2352,-0.2944 0.419,-0.2468 0.1838,0.0476 0.2944,0.2352 0.2468,0.419z"
              fill="#A9ABAE"
            />
            <path
              fill="#babcbf"
              d="M55.2664 26.6297c-0.3962,6.424 -6.9302,8.2863 -11.8461,10.3709 -3.1118,1.3196 -3.876,2.2974 -4.5665,5.5404 0.5003,-3.3107 1.3827,-4.3655 4.4858,-5.7312 4.7065,-2.0713 11.2241,-3.9743 11.5587,-10.1758 -0.0012,-0.1016 0.0803,-0.1849 0.1819,-0.1861 0.1016,-0.0012 0.1849,0.0802 0.1861,0.1819z"
              fill="#A9ABAE"
            />
            <path
              fill="#babcbf"
              d="M77.8011 15.273c-9.036,5.077 -3.2037,7.3106 -11.9378,11.6614 -0.669,0.3332 -9.2121,4.0942 -8.7423,5.3387 -1.2201,-1.0082 8.3483,-5.6097 8.5733,-5.7275 8.4526,-4.4217 2.552,-6.5294 11.8181,-11.8967 0.1724,-0.0797 0.3767,-0.0046 0.4564,0.1678 0.0797,0.1724 0.0046,0.3767 -0.1678,0.4564z"
              fill="#A9ABAE"
            />
            <path
              fill="#babcbf"
              d="M57.112 21.9726c-7.7181,2.2071 -6.6191,0.6747 -9.488,6.388 -1.8363,3.6568 -4.9682,3.61 -5.427,4.8676 -0.13,-1.0711 3.4686,-1.6665 5.0386,-5.0251 2.7917,-5.9721 1.9202,-4.5158 9.6561,-6.8819 0.1799,-0.0608 0.3751,0.0356 0.4359,0.2155 0.0608,0.1799 -0.0356,0.3751 -0.2155,0.4359z"
              fill="#A9ABAE"
            />
            <path
              fill="#babcbf"
              d="M76.6844 8.0828c-1.4038,6.3969 -6.7659,5.3479 -9.1709,10.9842 -1.8722,4.3877 -5.6435,3.475 -7.1686,5.4454 0.5824,-1.7866 5.0761,-1.3574 6.763,-5.58 2.3337,-5.8416 7.6745,-4.9594 8.8951,-10.9432 0.0259,-0.1882 0.1994,-0.3198 0.3875,-0.2939 0.1882,0.0259 0.3198,0.1994 0.2939,0.3875z"
              fill="#A9ABAE"
            />
            <path
              fill="#babcbf"
              fill="#A9ABAE"
              d="M68.804 3.1899c-1.0348,4.1371 -2.6419,2.8465 -3.0558,7.4307 -0.4114,4.556 0.4939,2.3646 -3.4931,6.4894 3.6446,-4.6394 2.7458,-1.9022 3.016,-6.5223 0.2786,-4.7653 1.9687,-3.5801 2.8522,-7.4959 0.0271,-0.188 0.2014,-0.3183 0.3894,-0.2912 0.188,0.0271 0.3183,0.2014 0.2912,0.3894z"
            />
            <path
              fill="#d2d3d5"
              d="m 45.7612,48.0915 c 0.0019,0.0017 0.0039,0.0034 0.0058,0.0051 z M 26.501,46.9652 c -0.0014,0.003 -0.0028,0.006 -0.0042,0.0091 z m -0.6925,6.4672 c -5e-4,0.0013 -0.0011,0.0025 -0.0015,0.0038 z m 3.1367,-7.2612 c 0.0012,0.0021 0.0023,0.0041 0.0034,0.006 z m 0.1546,-0.2241 c 0.0014,0.0016 0.0027,0.0032 0.004,0.0049 z m 11.8023,1.9363 c 1.373,1.0631 2.7431,2.1294 4.1107,3.1992 0.1277,0.1125 0.2003,0.2226 0.2528,0.3846 0.046,0.1653 0.0461,0.2971 0.0013,0.4626 0.0051,0.0308 -0.8731,3.3974 -0.9854,3.7918 0.0262,-0.0903 0.0364,-0.1684 0.0326,-0.2626 0,-1e-4 5e-4,0.0062 6e-4,0.0082 0.0971,1.2511 0.1578,2.4982 0.2127,3.7516 0.0056,0.1633 -0.0172,0.2888 -0.0799,0.4398 -0.068,0.1493 -0.1432,0.2507 -0.2667,0.3586 -1.1022,0.9093 -3.87315,3.1833 -5.05715,3.9851 -0.2016,0.1338 -1.34695,-0.0779 -1.34695,-0.0779 0,0 2.5301,-2.6917 3.2995,-3.4461 l 1.7344,-1.5281 -0.2456,-3.4034 c -0.0056,-0.1318 0.0122,-0.1998 0.0393,-0.3246 0.3683,-1.1652 0.7371,-2.3296 1.0991,-3.4969 0.0248,-0.0804 0.05,-0.1608 0.0745,-0.2413 -0.0416,0.1511 -0.0415,0.2728 0,0.424 0.0476,0.1477 0.1132,0.2503 0.2295,0.3531 0.0616,0.0741 -3.9595,-3.4677 -5.737,-5.1321 -1.049,-0.9821 -1.037925,-1.066622 -2.005425,-2.122022 0.874485,-1.222855 3.008176,1.61658 4.637125,2.876422 z M 25.9867,63.7102 24.4736,63.7063 c -0.7068,0.2897 -1.5241,0.5416 -1.3493,0.0369 0.0057,-0.0134 0.0117,-0.0268 0.018,-0.0403 l -5.0331,-0.0128 c -0.6658,0.3023 -1.4936,0.6221 -1.6134,0.382 -0.2698,0.0853 -0.5138,0.1089 -0.6058,-0.0392 -0.1007,0.0375 -0.2069,0.0561 -0.3294,0.0598 -3.3817,0.0568 -6.862,0.0909 -10.2354,-0.1242 -0.1254,-0.0092 -4.5764,-0.1163 -3.4882,-0.72 1.346,-0.6498 4.3583,-0.6611 5.8204,-0.7454 1.4794,-0.083 2.9452,-0.131 4.413,-0.1595 l 0.2745,-0.1779 1.8114,-0.4876 0.3962,-1.2597 1.3585,-0.5282 1.5849,-0.1219 0.9057,-0.6908 0.9907,0.1556 -0.0511,-0.1321 c -0.588,-1.52 -1.1666,-3.0439 -1.7546,-4.5636 -0.0788,-0.218 -0.0822,-0.3985 -0.0107,-0.619 0.0827,-0.2163 0.1994,-0.3552 0.3976,-0.475 1.9454,-1.0791 3.8873,-2.13 5.8532,-3.1704 0.2608,-0.1379 0.5286,-0.2704 0.7873,-0.4106 -0.1006,0.0615 -0.1643,0.1317 -0.2148,0.2383 0.8009,-1.5586 1.6239,-3.0427 2.4849,-4.5646 0.0075,-0.0127 0.4447,-0.7805 0.4932,-0.4277 -0.7053,1.7943 -1.423,3.5853 -2.1436,5.3734 -0.0377,0.0814 -0.0856,0.1346 -0.162,0.1814 -0.0038,0.0147 -3.4802,2.1749 -3.8212,2.3846 -0.8611,0.5295 -1.7259,1.0782 -2.5946,1.5922 0.1105,-0.0665 0.1754,-0.143 0.2219,-0.2634 0.0403,-0.1218 0.0392,-0.2242 -0.0042,-0.3451 0,0 1.7011,3.931 2.1937,5.1211 0.375,-0.2535 0.7509,-0.5077 1.1253,-0.7679 0.3836,-0.2665 0.7711,-0.529 1.1535,-0.7966 -0.1153,0.0867 -0.1888,0.179 -0.2457,0.3117 0.4471,-1.02 0.8899,-1.9723 1.3912,-2.9651 0.393,-0.7762 0.8307,-1.4288 1.315,-2.1416 0.0713,-0.0955 0.2279,-0.2771 0.3424,-0.1193 -0.3629,1.3549 -0.7445,2.7053 -1.1641,4.0438 -0.1514,0.4744 -0.304,0.9485 -0.4574,1.4223 0.4593,-0.2688 0.9217,-0.5383 1.3881,-0.8119 -0.1054,0.0651 -0.1795,0.1359 -0.2492,0.2382 0,0 1.0334,-1.5106 1.5453,-2.269 1.1687,-1.7312 2.359,-3.4283 3.5433,-5.1455 -0.0676,0.1077 -0.0967,0.2019 -0.1032,0.3288 -0.0011,0.1266 0.022,0.2209 0.0826,0.3321 0,0 -0.5188,-1.0154 -0.7725,-1.5191 -0.6463,-1.2824 -1.179,-2.5556 -1.7237,-3.8788 -0.0236,-0.0622 -0.2233,-0.5734 0.0354,-0.4899 l 0.0042,0.0061 c 0.0069,-1e-4 0.0144,2e-4 0.0225,9e-4 1.514,1.5564 3.015,3.1339 4.4842,4.7324 0.0963,0.1054 0.1984,0.2118 0.2914,0.3193 0.0803,0.1 0.1197,0.1924 0.1361,0.3197 0.0112,0.1282 -0.0078,0.2273 -0.0649,0.3425 0.0018,0.0089 -2.6532,5.6465 -2.9315,6.1963 0.0406,-0.0776 0.0633,-0.145 0.0785,-0.2313 0.0012,-0.0014 -0.1007,0.7978 -0.1313,1.0286 -0.1335,1.0053 -0.2936,2.0037 -0.4615,3.0037 -0.0279,0.1561 -0.0741,0.2699 -0.1621,0.4021 -0.0921,0.1286 -0.1829,0.2124 -0.3188,0.2933 -1.1877,0.6688 -2.3952,1.3313 -3.6449,1.8796 l 0.4111,0.492 z m -6.5129,-4.4641 0.1529,0.024 c 0.0522,-0.1289 0.1264,-0.2248 0.2441,-0.317 z m 3.4591,1.9275 0.1669,0.1797 1.0189,1.0972 0.1111,0.0418 c 0.5896,-0.4654 1.268,-0.8748 1.7208,-1.1858 0.7705,-0.5264 1.5677,-1.0478 2.3718,-1.5214 -0.1115,0.0662 -0.1849,0.1347 -0.2606,0.24 -0.0717,0.1074 -0.1107,0.2013 -0.1333,0.3285 -0.0468,0.0935 0.5059,-2.9473 0.6892,-4.0133 0.0173,-0.1008 0.0506,-0.2065 0.1008,-0.296 0.3756,-0.6714 0.7441,-1.3498 1.1113,-2.026 l 0.173,-0.3177 c -0.9648,1.6073 -1.9345,3.2117 -2.9136,4.8097 -0.0856,0.1257 -0.1702,0.2069 -0.2996,0.2869 -0.001,0.0025 -0.6916,0.4433 -0.766,0.4906 -0.994,0.6267 -2.0331,1.2685 -3.0904,1.8858 z m 21.6795,-14.158 c 0.8938,0.7045 1.7841,1.4134 2.6728,2.1244 0.0582,0.0528 0.0889,0.106 0.1073,0.1822 0.0015,0.0013 0.6917,2.6436 0.7444,2.8755 -0.0168,-0.0793 -0.0496,-0.1352 -0.1099,-0.1893 -5e-4,-0.0027 0.9606,0.7144 1.1481,0.8553 0.5241,0.394 1.0672,0.7868 1.5812,1.1913 -0.0521,-0.0424 -0.0995,-0.0679 -0.1631,-0.0891 0,0 3.5221,0.9115 4.3455,1.147 0.083,0.0255 0.1481,0.0567 0.2209,0.1039 0.0125,-0.0016 2.8665,1.7712 3.1975,1.9797 2.3623,1.4973 4.7629,3.0939 6.9724,4.8058 0.0017,0.0012 -0.1708,-0.0988 -0.2361,-0.0931 0,1e-4 0.3695,0.1055 0.506,0.1468 0.2054,0.0626 3.3876,0.8241 2.4806,1.2387 -0.9807,0.3718 -2.236,0.1163 -3.2507,-10e-5 -0.1089,-0.0211 -0.19,-0.054 -0.2837,-0.1131 -0.0037,9e-4 -0.9925,-0.5699 -1.0766,-0.6187 -3.1963,-1.8526 -6.1286,-3.9744 -9.1885,-6.0299 0.0634,0.0414 0.1231,0.0694 0.1952,0.0921 0,0 -0.2064,-0.0652 -0.3093,-0.0975 -1.3251,-0.4163 -2.6464,-0.8446 -3.9708,-1.2616 -0.1181,-0.0383 -0.2038,-0.0839 -0.3006,-0.1618 -0.8675,-0.737 -1.7257,-1.4772 -2.5786,-2.2309 -0.1496,-0.1302 -0.2295,-0.2639 -0.2718,-0.4578 -0.0675,-0.4205 -0.134,-0.841 -0.2,-1.2618 -0.0865,-0.5585 -0.1638,-1.1145 -0.2329,-1.6753 0.0245,0.1017 0.0673,0.1759 0.1449,0.2465 -0.6851,-0.7266 -1.33,-1.4546 -1.9886,-2.2027 -0.0335,-0.0396 -0.4475,-0.5208 -0.1554,-0.5067 z m -12.7976,3.4025 3e-4,0.0022 0.2813,0.3698 c -0.0897,-0.1126 -0.1331,-0.2168 -0.151,-0.3596 -0.0119,-0.1437 0.0091,-0.2542 0.0736,-0.3832 l -0.2041,0.3708 z m 2.5515,8.528 c -0.079,-0.6791 -0.1623,-1.358 -0.246,-2.0365 -0.0045,-0.0447 -0.0021,-0.0788 0.0092,-0.1223 0.0027,-0.0353 0.0543,-0.1046 0.0553,-0.1106 1.3536,-1.8017 2.691,-3.61 4.0031,-5.4423 -0.0257,0.0334 -0.0406,0.0629 -0.0529,0.1032 -0.0163,0.0319 -0.0071,0.0785 -0.0102,0.1119 -0.0031,0.0338 0.0234,0.0795 0.0318,0.1082 0.0193,0.037 0.0412,0.0646 0.0726,0.0921 -1.2585,-0.9711 -2.7186,-2.1244 -4.0785,-2.9358 -0.7384,-0.4627 -4.2016,-3.3514 -3.8525,-4.1363 1.5454,-0.4456 4.0924,2.1976 5.0112,3.1002 1.1274,1.1404 2.2598,2.2689 3.4112,3.3851 0.0487,0.0432 0.0796,0.0824 0.1099,0.1401 0.0273,0.0554 0.0412,0.1029 0.0477,0.1643 0.0051,0.062 5e-4,0.1096 -0.0159,0.1695 -0.0023,0.0241 -0.0621,0.146 -0.0804,0.1558 -1.5051,1.6933 -2.9505,3.3949 -4.3869,5.1465 -0.0067,0.0084 -0.0064,0.0108 -0.0109,0.019 -0.002,0.0035 -0.0023,0.022 -0.0025,0.0222 -0.0032,0.003 0.1569,1.8069 0.1717,1.9699 0.138,1.6198 0.2761,3.2396 0.4141,4.8594 -0.2003,-1.588 -0.4005,-3.1758 -0.6009,-4.7638 z"
            />
            <path
              fill="#a6a6a6"
              d="m 35.51055,43.935956 9.08155,7.730644 -1.1462,3.8206 0.191,3.8206 -5.34205,4.7118 L 68.4924,64.03675 68.2303,62.8856 55.0261,54.525 53.6509,54.3338 52.2757,54.1426 49.7674,52.7894 48.3013,51.0172 47.5149,48.3562 44.084,46.4303 41.7744,44.7264 40.229712,43.382062 c -1.841275,0.483307 -3.63078,0.512538 -4.719162,0.553894 z M 20.2129,59.3621 l -1.8114,-0.2845 2.1834,1.2358 0.7979,0.7999 -0.959,0.4474 0.8375,1.1781 -4.53735,1.23235 9.26255,-0.07345 -0.6792,-1.0003 -1.1888,-0.447 -2.1509,-2.3162 z"
            />
            <polygon
              fill="#D2D3D5"
              points="50.236,58.692 48.7077,58.3578 50.5499,59.8101 51.2231,60.7502 50.414,61.2759 51.1206,62.6605 48.3734,63.7782 55.1073,63.8021 54.5342,62.8469 53.5313,62.3216 51.7165,59.5994 "
            />
            <path
              fill="#808080"
              d="m 28.9597,55.8827 -3e-4,-7e-4 0.102,-0.1141 c 0.7095,-0.7938 1.1291,-1.709 1.3673,-2.7399 0.4441,-1.9223 0.1983,-3.9097 0.552,-5.8266 l 0.0227,-0.1229 0.118,-0.0409 c 0.3547,-0.1229 0.8258,-0.6708 1.057,-0.9512 0.2835,-0.3437 0.6214,-0.625 1.0089,-0.8443 0.385,-0.2179 0.7072,0.2027 1.0282,0.3405 l 0.0789,0.0338 0.0338,0.0789 c 0.2416,0.5642 0.5103,1.1239 0.8237,1.6519 l 0.0907,0.1527 -2e-4,2e-4 0.0992,0.1532 c 0.4049,0.6249 0.8833,1.1924 1.5255,1.5823 0.3805,0.231 0.8447,0.3808 1.1939,0.6362 0.4213,0.3082 0.6037,0.7456 0.7127,1.2425 0.0232,0.1057 0.035,0.2133 0.0356,0.3215 0.004,0.7151 -0.4926,1.404 -0.9158,1.9426 -0.5364,0.6826 -1.1209,1.3191 -1.5873,2.0556 -0.0623,0.0984 -0.1223,0.1983 -0.1793,0.2997 0.3591,-0.5128 0.7694,-1.0011 1.0815,-1.3894 0.597,-0.7429 1.8668,-2.2306 1.6684,-3.2538 -0.0955,-0.4929 -0.2441,-0.9666 -0.6697,-1.269 -0.2045,-0.1453 -0.4512,-0.2524 -0.675,-0.366 C 37.2067,49.2904 36.9157,49.1116 36.6358,48.8751 35.65,48.042 34.983,46.6537 34.5165,45.4796 l -0.0312,-0.0787 0.0309,-0.0788 c 0.0575,-0.1467 0.0976,-0.3061 0.1304,-0.46 0.0188,-0.0878 0.0639,-0.1654 0.139,-0.2167 0.3391,-0.2316 1.0744,0.3829 1.3421,0.573 0.134,0.0951 0.7467,0.5358 0.8998,0.5153 0.006,-0.0011 0.0161,-0.0031 0.0254,-0.0057 -0.0063,-0.0703 -0.072,-0.2341 -0.0899,-0.2819 -0.1306,-0.3487 -0.186,-0.7283 0.2597,-0.8701 0.3919,-0.1247 1.0616,0.3491 1.3735,0.5575 l 0.0687,0.0459 0.0201,0.0801 c 0.0319,0.1267 0.0986,0.2402 0.1934,0.3302 l 0.0065,0.0061 0.006,0.0067 c 0.5613,0.6297 1.0214,1.3223 1.2439,2.1432 0.1504,0.5548 0.1551,1.0705 0.236,1.6278 0.1344,0.9256 0.5686,1.4808 1.2867,2.0653 l 0.076,0.0619 0.0032,0.1073 c 0.1951,1.3962 0.1355,2.692 -0.2097,4.057 -0.095,0.3755 -0.2103,0.7424 -0.3171,1.1133 0.1335,-0.3379 0.2582,-0.6792 0.3683,-1.0246 l 0.1751,-0.5491 -0.0068,-0.0292 0.0129,-0.0505 c 0.2457,-0.9604 0.3239,-1.8905 0.2794,-2.8817 L 42.0145,51.7 l 0.3886,0.3803 c 1.589,1.5547 2.8197,4.0309 3.8675,5.9879 l 0.046,0.0861 -0.0347,0.0913 c -0.0129,0.034 -0.0104,0.071 0.0051,0.1038 0.0333,0.0703 0.0577,0.1411 0.0801,0.2106 l 0.3472,-0.2532 -0.2451,0.6651 c -0.1448,0.3929 -0.8958,0.0591 -1.0196,1.3741 l -0.0085,0.0901 -0.0705,0.0569 c -0.1298,0.1045 -0.2606,0.2068 -0.3934,0.3062 0.1937,-0.1059 0.5175,-0.2853 0.5628,-0.3455 0.2534,-0.6225 0.4974,-0.9456 1.0363,-1.3216 l 0.1952,-0.1363 0.1152,0.2083 c 0.9415,1.7019 2.6189,4.7629 4.8509,4.8411 1.8489,0.0649 3.6982,-0.0051 5.5457,-0.1055 C 56.8057,63.9009 56.3281,63.8622 55.8505,63.8234 54.8227,63.7399 53.795,63.6564 52.7673,63.5715 52.4261,63.5433 52.0847,63.515 51.7435,63.4856 51.6551,63.478 51.3663,63.4649 51.2873,63.4361 49.9888,62.9617 49.0599,61.5255 48.4142,60.3744 47.5151,58.7717 46.7908,57.0538 45.9492,55.4166 45.0624,53.6915 43.9633,51.8274 42.4515,50.578 42.0411,50.2389 41.7521,49.8623 41.6229,49.3401 41.5271,48.9527 41.527,48.5361 41.491,48.1394 41.4433,47.6141 41.3387,47.1463 41.1368,46.6567 l -0.113,-0.2739 0.2955,-0.0218 c 0.27,-0.0199 1.4086,-0.1515 1.5077,-0.4652 -0.0764,-0.1356 -0.4904,-0.4531 -0.5998,-0.5359 -0.1825,-0.1381 -0.3691,-0.2704 -0.5527,-0.4069 -0.0634,-0.0473 -0.1291,-0.096 -0.1885,-0.1483 -0.0361,-0.0318 -0.0679,-0.0702 -0.0903,-0.1116 l -1.1606,-1.3652 c -3.9357,0.719 -8.11975,0.697825 -12.05695,-0.0029 l -0.77055,0.9418 -0.0242,0.0126 c -0.0419,0.0219 -0.0684,0.0645 -0.0695,0.1119 l -2e-4,0.0108 -0.0014,0.0107 c -0.3313,2.6921 -2.186,5.0844 -4.7021,6.0879 -0.517364,0.208407 -1.522972,0.817048 -1.750063,1.061794 C 21.041775,51.440231 22.2431,50.7746 22.6514,50.6203 c 0.947,-0.358 1.8103,-0.9067 2.5437,-1.6038 l 0.2229,-0.2118 -0.0015,-0.0058 0.0812,-0.0861 c 0.6171,-0.6547 1.1191,-1.4134 1.4816,-2.2368 l 0.0643,-0.146 0.1559,0.0194 c 0.278,-0.0154 0.9104,-1.3164 1.5016,-1.2446 0.4679,0.0568 1.6962,0.4935 1.8043,1.0044 0.0513,0.242 0.1297,0.564 0.2617,0.7755 l 0.0442,0.071 -0.0154,0.0822 c -0.555,2.949 0.3724,6.1837 -1.7661,8.7078 -0.4004,0.4725 -0.8121,0.9317 -1.2416,1.376 0.3453,-0.3457 0.6814,-0.6997 1.0106,-1.062 l 0.1611,-0.1773 z"
            />
          </symbol>

          <symbol id="relief-vulcan-2-bw" viewBox="-5 -10 110 110">
            <ellipse fill="#999999" opacity=".5" cx="50" cy="64" rx="30" ry="4"></ellipse>
            <path
              fill="#fff"
              stroke="#5c5c70"
              stroke-width=".2"
              d="m 40.318,43.0945 1.2624,1.4851 2.2879,1.7295 3.6464,2.047 0.7864,2.661 1.4661,1.7722 2.5083,1.3532 2.7505,0.3824 4.548,2.8992 4.3962,2.9284 4.26,2.533 0.0746,0.7449 L 55.9019,63.906275 34.0507,63.6698 18.4326,63.9645 C 12.828851,63.668708 7.2014518,63.758742 1.6058,63.3217 l 6.2682,-4.7224 1.9305,-0.55 3.4543,-2.435 1.6264,-1.9274 1.8235,-2.4455 3.3521,-1.8555 3.2709,-1.0652 1.9097,-2.384 3.0893,-2.7945 c 3.9306,0.6688 7.9292,0.6208 11.9872,-0.0477 z"
            />
            <path
              fill="#d2d3d5"
              d="m 45.7612,48.0915 c 0.0019,0.0017 0.0039,0.0034 0.0058,0.0051 z M 26.501,46.9652 c -0.0014,0.003 -0.0028,0.006 -0.0042,0.0091 z m -0.6925,6.4672 c -5e-4,0.0013 -0.0011,0.0025 -0.0015,0.0038 z m 3.1367,-7.2612 c 0.0012,0.0021 0.0023,0.0041 0.0034,0.006 z m 0.1546,-0.2241 c 0.0014,0.0016 0.0027,0.0032 0.004,0.0049 z m 11.8023,1.9363 c 1.373,1.0631 2.7431,2.1294 4.1107,3.1992 0.1277,0.1125 0.2003,0.2226 0.2528,0.3846 0.046,0.1653 0.0461,0.2971 0.0013,0.4626 0.0051,0.0308 -0.8731,3.3974 -0.9854,3.7918 0.0262,-0.0903 0.0364,-0.1684 0.0326,-0.2626 0,-1e-4 5e-4,0.0062 6e-4,0.0082 0.0971,1.2511 0.1578,2.4982 0.2127,3.7516 0.0056,0.1633 -0.0172,0.2888 -0.0799,0.4398 -0.068,0.1493 -0.1432,0.2507 -0.2667,0.3586 -1.1022,0.9093 -3.87315,3.1833 -5.05715,3.9851 -0.2016,0.1338 -1.34695,-0.0779 -1.34695,-0.0779 0,0 2.5301,-2.6917 3.2995,-3.4461 l 1.7344,-1.5281 -0.2456,-3.4034 c -0.0056,-0.1318 0.0122,-0.1998 0.0393,-0.3246 0.3683,-1.1652 0.7371,-2.3296 1.0991,-3.4969 0.0248,-0.0804 0.05,-0.1608 0.0745,-0.2413 -0.0416,0.1511 -0.0415,0.2728 0,0.424 0.0476,0.1477 0.1132,0.2503 0.2295,0.3531 0.0616,0.0741 -3.9595,-3.4677 -5.737,-5.1321 -1.049,-0.9821 -1.037925,-1.066622 -2.005425,-2.122022 0.874485,-1.222855 3.008176,1.61658 4.637125,2.876422 z M 25.9867,63.7102 24.4736,63.7063 c -0.7068,0.2897 -1.5241,0.5416 -1.3493,0.0369 0.0057,-0.0134 0.0117,-0.0268 0.018,-0.0403 l -5.0331,-0.0128 c -0.6658,0.3023 -1.4936,0.6221 -1.6134,0.382 -0.2698,0.0853 -0.5138,0.1089 -0.6058,-0.0392 -0.1007,0.0375 -0.2069,0.0561 -0.3294,0.0598 -3.3817,0.0568 -6.862,0.0909 -10.2354,-0.1242 -0.1254,-0.0092 -4.5764,-0.1163 -3.4882,-0.72 1.346,-0.6498 4.3583,-0.6611 5.8204,-0.7454 1.4794,-0.083 2.9452,-0.131 4.413,-0.1595 l 0.2745,-0.1779 1.8114,-0.4876 0.3962,-1.2597 1.3585,-0.5282 1.5849,-0.1219 0.9057,-0.6908 0.9907,0.1556 -0.0511,-0.1321 c -0.588,-1.52 -1.1666,-3.0439 -1.7546,-4.5636 -0.0788,-0.218 -0.0822,-0.3985 -0.0107,-0.619 0.0827,-0.2163 0.1994,-0.3552 0.3976,-0.475 1.9454,-1.0791 3.8873,-2.13 5.8532,-3.1704 0.2608,-0.1379 0.5286,-0.2704 0.7873,-0.4106 -0.1006,0.0615 -0.1643,0.1317 -0.2148,0.2383 0.8009,-1.5586 1.6239,-3.0427 2.4849,-4.5646 0.0075,-0.0127 0.4447,-0.7805 0.4932,-0.4277 -0.7053,1.7943 -1.423,3.5853 -2.1436,5.3734 -0.0377,0.0814 -0.0856,0.1346 -0.162,0.1814 -0.0038,0.0147 -3.4802,2.1749 -3.8212,2.3846 -0.8611,0.5295 -1.7259,1.0782 -2.5946,1.5922 0.1105,-0.0665 0.1754,-0.143 0.2219,-0.2634 0.0403,-0.1218 0.0392,-0.2242 -0.0042,-0.3451 0,0 1.7011,3.931 2.1937,5.1211 0.375,-0.2535 0.7509,-0.5077 1.1253,-0.7679 0.3836,-0.2665 0.7711,-0.529 1.1535,-0.7966 -0.1153,0.0867 -0.1888,0.179 -0.2457,0.3117 0.4471,-1.02 0.8899,-1.9723 1.3912,-2.9651 0.393,-0.7762 0.8307,-1.4288 1.315,-2.1416 0.0713,-0.0955 0.2279,-0.2771 0.3424,-0.1193 -0.3629,1.3549 -0.7445,2.7053 -1.1641,4.0438 -0.1514,0.4744 -0.304,0.9485 -0.4574,1.4223 0.4593,-0.2688 0.9217,-0.5383 1.3881,-0.8119 -0.1054,0.0651 -0.1795,0.1359 -0.2492,0.2382 0,0 1.0334,-1.5106 1.5453,-2.269 1.1687,-1.7312 2.359,-3.4283 3.5433,-5.1455 -0.0676,0.1077 -0.0967,0.2019 -0.1032,0.3288 -0.0011,0.1266 0.022,0.2209 0.0826,0.3321 0,0 -0.5188,-1.0154 -0.7725,-1.5191 -0.6463,-1.2824 -1.179,-2.5556 -1.7237,-3.8788 -0.0236,-0.0622 -0.2233,-0.5734 0.0354,-0.4899 l 0.0042,0.0061 c 0.0069,-1e-4 0.0144,2e-4 0.0225,9e-4 1.514,1.5564 3.015,3.1339 4.4842,4.7324 0.0963,0.1054 0.1984,0.2118 0.2914,0.3193 0.0803,0.1 0.1197,0.1924 0.1361,0.3197 0.0112,0.1282 -0.0078,0.2273 -0.0649,0.3425 0.0018,0.0089 -2.6532,5.6465 -2.9315,6.1963 0.0406,-0.0776 0.0633,-0.145 0.0785,-0.2313 0.0012,-0.0014 -0.1007,0.7978 -0.1313,1.0286 -0.1335,1.0053 -0.2936,2.0037 -0.4615,3.0037 -0.0279,0.1561 -0.0741,0.2699 -0.1621,0.4021 -0.0921,0.1286 -0.1829,0.2124 -0.3188,0.2933 -1.1877,0.6688 -2.3952,1.3313 -3.6449,1.8796 l 0.4111,0.492 z m -6.5129,-4.4641 0.1529,0.024 c 0.0522,-0.1289 0.1264,-0.2248 0.2441,-0.317 z m 3.4591,1.9275 0.1669,0.1797 1.0189,1.0972 0.1111,0.0418 c 0.5896,-0.4654 1.268,-0.8748 1.7208,-1.1858 0.7705,-0.5264 1.5677,-1.0478 2.3718,-1.5214 -0.1115,0.0662 -0.1849,0.1347 -0.2606,0.24 -0.0717,0.1074 -0.1107,0.2013 -0.1333,0.3285 -0.0468,0.0935 0.5059,-2.9473 0.6892,-4.0133 0.0173,-0.1008 0.0506,-0.2065 0.1008,-0.296 0.3756,-0.6714 0.7441,-1.3498 1.1113,-2.026 l 0.173,-0.3177 c -0.9648,1.6073 -1.9345,3.2117 -2.9136,4.8097 -0.0856,0.1257 -0.1702,0.2069 -0.2996,0.2869 -0.001,0.0025 -0.6916,0.4433 -0.766,0.4906 -0.994,0.6267 -2.0331,1.2685 -3.0904,1.8858 z m 21.6795,-14.158 c 0.8938,0.7045 1.7841,1.4134 2.6728,2.1244 0.0582,0.0528 0.0889,0.106 0.1073,0.1822 0.0015,0.0013 0.6917,2.6436 0.7444,2.8755 -0.0168,-0.0793 -0.0496,-0.1352 -0.1099,-0.1893 -5e-4,-0.0027 0.9606,0.7144 1.1481,0.8553 0.5241,0.394 1.0672,0.7868 1.5812,1.1913 -0.0521,-0.0424 -0.0995,-0.0679 -0.1631,-0.0891 0,0 3.5221,0.9115 4.3455,1.147 0.083,0.0255 0.1481,0.0567 0.2209,0.1039 0.0125,-0.0016 2.8665,1.7712 3.1975,1.9797 2.3623,1.4973 4.7629,3.0939 6.9724,4.8058 0.0017,0.0012 -0.1708,-0.0988 -0.2361,-0.0931 0,1e-4 0.3695,0.1055 0.506,0.1468 0.2054,0.0626 3.3876,0.8241 2.4806,1.2387 -0.9807,0.3718 -2.236,0.1163 -3.2507,-10e-5 -0.1089,-0.0211 -0.19,-0.054 -0.2837,-0.1131 -0.0037,9e-4 -0.9925,-0.5699 -1.0766,-0.6187 -3.1963,-1.8526 -6.1286,-3.9744 -9.1885,-6.0299 0.0634,0.0414 0.1231,0.0694 0.1952,0.0921 0,0 -0.2064,-0.0652 -0.3093,-0.0975 -1.3251,-0.4163 -2.6464,-0.8446 -3.9708,-1.2616 -0.1181,-0.0383 -0.2038,-0.0839 -0.3006,-0.1618 -0.8675,-0.737 -1.7257,-1.4772 -2.5786,-2.2309 -0.1496,-0.1302 -0.2295,-0.2639 -0.2718,-0.4578 -0.0675,-0.4205 -0.134,-0.841 -0.2,-1.2618 -0.0865,-0.5585 -0.1638,-1.1145 -0.2329,-1.6753 0.0245,0.1017 0.0673,0.1759 0.1449,0.2465 -0.6851,-0.7266 -1.33,-1.4546 -1.9886,-2.2027 -0.0335,-0.0396 -0.4475,-0.5208 -0.1554,-0.5067 z m -12.7976,3.4025 3e-4,0.0022 0.2813,0.3698 c -0.0897,-0.1126 -0.1331,-0.2168 -0.151,-0.3596 -0.0119,-0.1437 0.0091,-0.2542 0.0736,-0.3832 l -0.2041,0.3708 z m 2.5515,8.528 c -0.079,-0.6791 -0.1623,-1.358 -0.246,-2.0365 -0.0045,-0.0447 -0.0021,-0.0788 0.0092,-0.1223 0.0027,-0.0353 0.0543,-0.1046 0.0553,-0.1106 1.3536,-1.8017 2.691,-3.61 4.0031,-5.4423 -0.0257,0.0334 -0.0406,0.0629 -0.0529,0.1032 -0.0163,0.0319 -0.0071,0.0785 -0.0102,0.1119 -0.0031,0.0338 0.0234,0.0795 0.0318,0.1082 0.0193,0.037 0.0412,0.0646 0.0726,0.0921 -1.2585,-0.9711 -2.7186,-2.1244 -4.0785,-2.9358 -0.7384,-0.4627 -4.2016,-3.3514 -3.8525,-4.1363 1.5454,-0.4456 4.0924,2.1976 5.0112,3.1002 1.1274,1.1404 2.2598,2.2689 3.4112,3.3851 0.0487,0.0432 0.0796,0.0824 0.1099,0.1401 0.0273,0.0554 0.0412,0.1029 0.0477,0.1643 0.0051,0.062 5e-4,0.1096 -0.0159,0.1695 -0.0023,0.0241 -0.0621,0.146 -0.0804,0.1558 -1.5051,1.6933 -2.9505,3.3949 -4.3869,5.1465 -0.0067,0.0084 -0.0064,0.0108 -0.0109,0.019 -0.002,0.0035 -0.0023,0.022 -0.0025,0.0222 -0.0032,0.003 0.1569,1.8069 0.1717,1.9699 0.138,1.6198 0.2761,3.2396 0.4141,4.8594 -0.2003,-1.588 -0.4005,-3.1758 -0.6009,-4.7638 z"
            />
            <path
              fill="#a6a6a6"
              d="m 35.51055,43.935956 9.08155,7.730644 -1.1462,3.8206 0.191,3.8206 -5.34205,4.7118 L 68.4924,64.03675 68.2303,62.8856 55.0261,54.525 53.6509,54.3338 52.2757,54.1426 49.7674,52.7894 48.3013,51.0172 47.5149,48.3562 44.084,46.4303 41.7744,44.7264 40.229712,43.382062 c -1.841275,0.483307 -3.63078,0.512538 -4.719162,0.553894 z M 20.2129,59.3621 l -1.8114,-0.2845 2.1834,1.2358 0.7979,0.7999 -0.959,0.4474 0.8375,1.1781 -4.53735,1.23235 9.26255,-0.07345 -0.6792,-1.0003 -1.1888,-0.447 -2.1509,-2.3162 z"
            />
            <polygon
              fill="#D2D3D5"
              points="50.236,58.692 48.7077,58.3578 50.5499,59.8101 51.2231,60.7502 50.414,61.2759 51.1206,62.6605 48.3734,63.7782 55.1073,63.8021 54.5342,62.8469 53.5313,62.3216 51.7165,59.5994 "
            />
            <path
              fill="#808080"
              d="m 28.9597,55.8827 -3e-4,-7e-4 0.102,-0.1141 c 0.7095,-0.7938 1.1291,-1.709 1.3673,-2.7399 0.4441,-1.9223 0.1983,-3.9097 0.552,-5.8266 l 0.0227,-0.1229 0.118,-0.0409 c 0.3547,-0.1229 0.8258,-0.6708 1.057,-0.9512 0.2835,-0.3437 0.6214,-0.625 1.0089,-0.8443 0.385,-0.2179 0.7072,0.2027 1.0282,0.3405 l 0.0789,0.0338 0.0338,0.0789 c 0.2416,0.5642 0.5103,1.1239 0.8237,1.6519 l 0.0907,0.1527 -2e-4,2e-4 0.0992,0.1532 c 0.4049,0.6249 0.8833,1.1924 1.5255,1.5823 0.3805,0.231 0.8447,0.3808 1.1939,0.6362 0.4213,0.3082 0.6037,0.7456 0.7127,1.2425 0.0232,0.1057 0.035,0.2133 0.0356,0.3215 0.004,0.7151 -0.4926,1.404 -0.9158,1.9426 -0.5364,0.6826 -1.1209,1.3191 -1.5873,2.0556 -0.0623,0.0984 -0.1223,0.1983 -0.1793,0.2997 0.3591,-0.5128 0.7694,-1.0011 1.0815,-1.3894 0.597,-0.7429 1.8668,-2.2306 1.6684,-3.2538 -0.0955,-0.4929 -0.2441,-0.9666 -0.6697,-1.269 -0.2045,-0.1453 -0.4512,-0.2524 -0.675,-0.366 C 37.2067,49.2904 36.9157,49.1116 36.6358,48.8751 35.65,48.042 34.983,46.6537 34.5165,45.4796 l -0.0312,-0.0787 0.0309,-0.0788 c 0.0575,-0.1467 0.0976,-0.3061 0.1304,-0.46 0.0188,-0.0878 0.0639,-0.1654 0.139,-0.2167 0.3391,-0.2316 1.0744,0.3829 1.3421,0.573 0.134,0.0951 0.7467,0.5358 0.8998,0.5153 0.006,-0.0011 0.0161,-0.0031 0.0254,-0.0057 -0.0063,-0.0703 -0.072,-0.2341 -0.0899,-0.2819 -0.1306,-0.3487 -0.186,-0.7283 0.2597,-0.8701 0.3919,-0.1247 1.0616,0.3491 1.3735,0.5575 l 0.0687,0.0459 0.0201,0.0801 c 0.0319,0.1267 0.0986,0.2402 0.1934,0.3302 l 0.0065,0.0061 0.006,0.0067 c 0.5613,0.6297 1.0214,1.3223 1.2439,2.1432 0.1504,0.5548 0.1551,1.0705 0.236,1.6278 0.1344,0.9256 0.5686,1.4808 1.2867,2.0653 l 0.076,0.0619 0.0032,0.1073 c 0.1951,1.3962 0.1355,2.692 -0.2097,4.057 -0.095,0.3755 -0.2103,0.7424 -0.3171,1.1133 0.1335,-0.3379 0.2582,-0.6792 0.3683,-1.0246 l 0.1751,-0.5491 -0.0068,-0.0292 0.0129,-0.0505 c 0.2457,-0.9604 0.3239,-1.8905 0.2794,-2.8817 L 42.0145,51.7 l 0.3886,0.3803 c 1.589,1.5547 2.8197,4.0309 3.8675,5.9879 l 0.046,0.0861 -0.0347,0.0913 c -0.0129,0.034 -0.0104,0.071 0.0051,0.1038 0.0333,0.0703 0.0577,0.1411 0.0801,0.2106 l 0.3472,-0.2532 -0.2451,0.6651 c -0.1448,0.3929 -0.8958,0.0591 -1.0196,1.3741 l -0.0085,0.0901 -0.0705,0.0569 c -0.1298,0.1045 -0.2606,0.2068 -0.3934,0.3062 0.1937,-0.1059 0.5175,-0.2853 0.5628,-0.3455 0.2534,-0.6225 0.4974,-0.9456 1.0363,-1.3216 l 0.1952,-0.1363 0.1152,0.2083 c 0.9415,1.7019 2.6189,4.7629 4.8509,4.8411 1.8489,0.0649 3.6982,-0.0051 5.5457,-0.1055 C 56.8057,63.9009 56.3281,63.8622 55.8505,63.8234 54.8227,63.7399 53.795,63.6564 52.7673,63.5715 52.4261,63.5433 52.0847,63.515 51.7435,63.4856 51.6551,63.478 51.3663,63.4649 51.2873,63.4361 49.9888,62.9617 49.0599,61.5255 48.4142,60.3744 47.5151,58.7717 46.7908,57.0538 45.9492,55.4166 45.0624,53.6915 43.9633,51.8274 42.4515,50.578 42.0411,50.2389 41.7521,49.8623 41.6229,49.3401 41.5271,48.9527 41.527,48.5361 41.491,48.1394 41.4433,47.6141 41.3387,47.1463 41.1368,46.6567 l -0.113,-0.2739 0.2955,-0.0218 c 0.27,-0.0199 1.4086,-0.1515 1.5077,-0.4652 -0.0764,-0.1356 -0.4904,-0.4531 -0.5998,-0.5359 -0.1825,-0.1381 -0.3691,-0.2704 -0.5527,-0.4069 -0.0634,-0.0473 -0.1291,-0.096 -0.1885,-0.1483 -0.0361,-0.0318 -0.0679,-0.0702 -0.0903,-0.1116 l -1.1606,-1.3652 c -3.9357,0.719 -8.11975,0.697825 -12.05695,-0.0029 l -0.77055,0.9418 -0.0242,0.0126 c -0.0419,0.0219 -0.0684,0.0645 -0.0695,0.1119 l -2e-4,0.0108 -0.0014,0.0107 c -0.3313,2.6921 -2.186,5.0844 -4.7021,6.0879 -0.517364,0.208407 -1.522972,0.817048 -1.750063,1.061794 C 21.041775,51.440231 22.2431,50.7746 22.6514,50.6203 c 0.947,-0.358 1.8103,-0.9067 2.5437,-1.6038 l 0.2229,-0.2118 -0.0015,-0.0058 0.0812,-0.0861 c 0.6171,-0.6547 1.1191,-1.4134 1.4816,-2.2368 l 0.0643,-0.146 0.1559,0.0194 c 0.278,-0.0154 0.9104,-1.3164 1.5016,-1.2446 0.4679,0.0568 1.6962,0.4935 1.8043,1.0044 0.0513,0.242 0.1297,0.564 0.2617,0.7755 l 0.0442,0.071 -0.0154,0.0822 c -0.555,2.949 0.3724,6.1837 -1.7661,8.7078 -0.4004,0.4725 -0.8121,0.9317 -1.2416,1.376 0.3453,-0.3457 0.6814,-0.6997 1.0106,-1.062 l 0.1611,-0.1773 z"
            />
          </symbol>

          <symbol id="relief-vulcan-3-bw" viewBox="-5 -10 110 110">
            <ellipse fill="#999999" opacity=".5" cx="50" cy="64" rx="30" ry="4"></ellipse>
            <path
              fill="#fff"
              stroke="#5c5c70"
              stroke-width=".2"
              d="m 40.318,43.0945 1.2624,1.4851 2.2879,1.7295 3.6464,2.047 0.7864,2.661 1.4661,1.7722 2.5083,1.3532 2.7505,0.3824 4.548,2.8992 4.3962,2.9284 4.26,2.533 0.0746,0.7449 L 55.9019,63.906275 34.0507,63.6698 18.4326,63.9645 C 12.828851,63.668708 7.2014518,63.758742 1.6058,63.3217 l 6.2682,-4.7224 1.9305,-0.55 3.4543,-2.435 1.6264,-1.9274 1.8235,-2.4455 3.3521,-1.8555 3.2709,-1.0652 1.9097,-2.384 3.0893,-2.7945 c 3.9306,0.6688 7.9292,0.6208 11.9872,-0.0477 z"
            />
            <path
              fill="#d2d3d5"
              d="m 45.7612,48.0915 c 0.0019,0.0017 0.0039,0.0034 0.0058,0.0051 z M 26.501,46.9652 c -0.0014,0.003 -0.0028,0.006 -0.0042,0.0091 z m -0.6925,6.4672 c -5e-4,0.0013 -0.0011,0.0025 -0.0015,0.0038 z m 3.1367,-7.2612 c 0.0012,0.0021 0.0023,0.0041 0.0034,0.006 z m 0.1546,-0.2241 c 0.0014,0.0016 0.0027,0.0032 0.004,0.0049 z m 11.8023,1.9363 c 1.373,1.0631 2.7431,2.1294 4.1107,3.1992 0.1277,0.1125 0.2003,0.2226 0.2528,0.3846 0.046,0.1653 0.0461,0.2971 0.0013,0.4626 0.0051,0.0308 -0.8731,3.3974 -0.9854,3.7918 0.0262,-0.0903 0.0364,-0.1684 0.0326,-0.2626 0,-1e-4 5e-4,0.0062 6e-4,0.0082 0.0971,1.2511 0.1578,2.4982 0.2127,3.7516 0.0056,0.1633 -0.0172,0.2888 -0.0799,0.4398 -0.068,0.1493 -0.1432,0.2507 -0.2667,0.3586 -1.1022,0.9093 -3.87315,3.1833 -5.05715,3.9851 -0.2016,0.1338 -1.34695,-0.0779 -1.34695,-0.0779 0,0 2.5301,-2.6917 3.2995,-3.4461 l 1.7344,-1.5281 -0.2456,-3.4034 c -0.0056,-0.1318 0.0122,-0.1998 0.0393,-0.3246 0.3683,-1.1652 0.7371,-2.3296 1.0991,-3.4969 0.0248,-0.0804 0.05,-0.1608 0.0745,-0.2413 -0.0416,0.1511 -0.0415,0.2728 0,0.424 0.0476,0.1477 0.1132,0.2503 0.2295,0.3531 0.0616,0.0741 -3.9595,-3.4677 -5.737,-5.1321 -1.049,-0.9821 -1.037925,-1.066622 -2.005425,-2.122022 0.874485,-1.222855 3.008176,1.61658 4.637125,2.876422 z M 25.9867,63.7102 24.4736,63.7063 c -0.7068,0.2897 -1.5241,0.5416 -1.3493,0.0369 0.0057,-0.0134 0.0117,-0.0268 0.018,-0.0403 l -5.0331,-0.0128 c -0.6658,0.3023 -1.4936,0.6221 -1.6134,0.382 -0.2698,0.0853 -0.5138,0.1089 -0.6058,-0.0392 -0.1007,0.0375 -0.2069,0.0561 -0.3294,0.0598 -3.3817,0.0568 -6.862,0.0909 -10.2354,-0.1242 -0.1254,-0.0092 -4.5764,-0.1163 -3.4882,-0.72 1.346,-0.6498 4.3583,-0.6611 5.8204,-0.7454 1.4794,-0.083 2.9452,-0.131 4.413,-0.1595 l 0.2745,-0.1779 1.8114,-0.4876 0.3962,-1.2597 1.3585,-0.5282 1.5849,-0.1219 0.9057,-0.6908 0.9907,0.1556 -0.0511,-0.1321 c -0.588,-1.52 -1.1666,-3.0439 -1.7546,-4.5636 -0.0788,-0.218 -0.0822,-0.3985 -0.0107,-0.619 0.0827,-0.2163 0.1994,-0.3552 0.3976,-0.475 1.9454,-1.0791 3.8873,-2.13 5.8532,-3.1704 0.2608,-0.1379 0.5286,-0.2704 0.7873,-0.4106 -0.1006,0.0615 -0.1643,0.1317 -0.2148,0.2383 0.8009,-1.5586 1.6239,-3.0427 2.4849,-4.5646 0.0075,-0.0127 0.4447,-0.7805 0.4932,-0.4277 -0.7053,1.7943 -1.423,3.5853 -2.1436,5.3734 -0.0377,0.0814 -0.0856,0.1346 -0.162,0.1814 -0.0038,0.0147 -3.4802,2.1749 -3.8212,2.3846 -0.8611,0.5295 -1.7259,1.0782 -2.5946,1.5922 0.1105,-0.0665 0.1754,-0.143 0.2219,-0.2634 0.0403,-0.1218 0.0392,-0.2242 -0.0042,-0.3451 0,0 1.7011,3.931 2.1937,5.1211 0.375,-0.2535 0.7509,-0.5077 1.1253,-0.7679 0.3836,-0.2665 0.7711,-0.529 1.1535,-0.7966 -0.1153,0.0867 -0.1888,0.179 -0.2457,0.3117 0.4471,-1.02 0.8899,-1.9723 1.3912,-2.9651 0.393,-0.7762 0.8307,-1.4288 1.315,-2.1416 0.0713,-0.0955 0.2279,-0.2771 0.3424,-0.1193 -0.3629,1.3549 -0.7445,2.7053 -1.1641,4.0438 -0.1514,0.4744 -0.304,0.9485 -0.4574,1.4223 0.4593,-0.2688 0.9217,-0.5383 1.3881,-0.8119 -0.1054,0.0651 -0.1795,0.1359 -0.2492,0.2382 0,0 1.0334,-1.5106 1.5453,-2.269 1.1687,-1.7312 2.359,-3.4283 3.5433,-5.1455 -0.0676,0.1077 -0.0967,0.2019 -0.1032,0.3288 -0.0011,0.1266 0.022,0.2209 0.0826,0.3321 0,0 -0.5188,-1.0154 -0.7725,-1.5191 -0.6463,-1.2824 -1.179,-2.5556 -1.7237,-3.8788 -0.0236,-0.0622 -0.2233,-0.5734 0.0354,-0.4899 l 0.0042,0.0061 c 0.0069,-1e-4 0.0144,2e-4 0.0225,9e-4 1.514,1.5564 3.015,3.1339 4.4842,4.7324 0.0963,0.1054 0.1984,0.2118 0.2914,0.3193 0.0803,0.1 0.1197,0.1924 0.1361,0.3197 0.0112,0.1282 -0.0078,0.2273 -0.0649,0.3425 0.0018,0.0089 -2.6532,5.6465 -2.9315,6.1963 0.0406,-0.0776 0.0633,-0.145 0.0785,-0.2313 0.0012,-0.0014 -0.1007,0.7978 -0.1313,1.0286 -0.1335,1.0053 -0.2936,2.0037 -0.4615,3.0037 -0.0279,0.1561 -0.0741,0.2699 -0.1621,0.4021 -0.0921,0.1286 -0.1829,0.2124 -0.3188,0.2933 -1.1877,0.6688 -2.3952,1.3313 -3.6449,1.8796 l 0.4111,0.492 z m -6.5129,-4.4641 0.1529,0.024 c 0.0522,-0.1289 0.1264,-0.2248 0.2441,-0.317 z m 3.4591,1.9275 0.1669,0.1797 1.0189,1.0972 0.1111,0.0418 c 0.5896,-0.4654 1.268,-0.8748 1.7208,-1.1858 0.7705,-0.5264 1.5677,-1.0478 2.3718,-1.5214 -0.1115,0.0662 -0.1849,0.1347 -0.2606,0.24 -0.0717,0.1074 -0.1107,0.2013 -0.1333,0.3285 -0.0468,0.0935 0.5059,-2.9473 0.6892,-4.0133 0.0173,-0.1008 0.0506,-0.2065 0.1008,-0.296 0.3756,-0.6714 0.7441,-1.3498 1.1113,-2.026 l 0.173,-0.3177 c -0.9648,1.6073 -1.9345,3.2117 -2.9136,4.8097 -0.0856,0.1257 -0.1702,0.2069 -0.2996,0.2869 -0.001,0.0025 -0.6916,0.4433 -0.766,0.4906 -0.994,0.6267 -2.0331,1.2685 -3.0904,1.8858 z m 21.6795,-14.158 c 0.8938,0.7045 1.7841,1.4134 2.6728,2.1244 0.0582,0.0528 0.0889,0.106 0.1073,0.1822 0.0015,0.0013 0.6917,2.6436 0.7444,2.8755 -0.0168,-0.0793 -0.0496,-0.1352 -0.1099,-0.1893 -5e-4,-0.0027 0.9606,0.7144 1.1481,0.8553 0.5241,0.394 1.0672,0.7868 1.5812,1.1913 -0.0521,-0.0424 -0.0995,-0.0679 -0.1631,-0.0891 0,0 3.5221,0.9115 4.3455,1.147 0.083,0.0255 0.1481,0.0567 0.2209,0.1039 0.0125,-0.0016 2.8665,1.7712 3.1975,1.9797 2.3623,1.4973 4.7629,3.0939 6.9724,4.8058 0.0017,0.0012 -0.1708,-0.0988 -0.2361,-0.0931 0,1e-4 0.3695,0.1055 0.506,0.1468 0.2054,0.0626 3.3876,0.8241 2.4806,1.2387 -0.9807,0.3718 -2.236,0.1163 -3.2507,-10e-5 -0.1089,-0.0211 -0.19,-0.054 -0.2837,-0.1131 -0.0037,9e-4 -0.9925,-0.5699 -1.0766,-0.6187 -3.1963,-1.8526 -6.1286,-3.9744 -9.1885,-6.0299 0.0634,0.0414 0.1231,0.0694 0.1952,0.0921 0,0 -0.2064,-0.0652 -0.3093,-0.0975 -1.3251,-0.4163 -2.6464,-0.8446 -3.9708,-1.2616 -0.1181,-0.0383 -0.2038,-0.0839 -0.3006,-0.1618 -0.8675,-0.737 -1.7257,-1.4772 -2.5786,-2.2309 -0.1496,-0.1302 -0.2295,-0.2639 -0.2718,-0.4578 -0.0675,-0.4205 -0.134,-0.841 -0.2,-1.2618 -0.0865,-0.5585 -0.1638,-1.1145 -0.2329,-1.6753 0.0245,0.1017 0.0673,0.1759 0.1449,0.2465 -0.6851,-0.7266 -1.33,-1.4546 -1.9886,-2.2027 -0.0335,-0.0396 -0.4475,-0.5208 -0.1554,-0.5067 z m -12.7976,3.4025 3e-4,0.0022 0.2813,0.3698 c -0.0897,-0.1126 -0.1331,-0.2168 -0.151,-0.3596 -0.0119,-0.1437 0.0091,-0.2542 0.0736,-0.3832 l -0.2041,0.3708 z m 2.5515,8.528 c -0.079,-0.6791 -0.1623,-1.358 -0.246,-2.0365 -0.0045,-0.0447 -0.0021,-0.0788 0.0092,-0.1223 0.0027,-0.0353 0.0543,-0.1046 0.0553,-0.1106 1.3536,-1.8017 2.691,-3.61 4.0031,-5.4423 -0.0257,0.0334 -0.0406,0.0629 -0.0529,0.1032 -0.0163,0.0319 -0.0071,0.0785 -0.0102,0.1119 -0.0031,0.0338 0.0234,0.0795 0.0318,0.1082 0.0193,0.037 0.0412,0.0646 0.0726,0.0921 -1.2585,-0.9711 -2.7186,-2.1244 -4.0785,-2.9358 -0.7384,-0.4627 -4.2016,-3.3514 -3.8525,-4.1363 1.5454,-0.4456 4.0924,2.1976 5.0112,3.1002 1.1274,1.1404 2.2598,2.2689 3.4112,3.3851 0.0487,0.0432 0.0796,0.0824 0.1099,0.1401 0.0273,0.0554 0.0412,0.1029 0.0477,0.1643 0.0051,0.062 5e-4,0.1096 -0.0159,0.1695 -0.0023,0.0241 -0.0621,0.146 -0.0804,0.1558 -1.5051,1.6933 -2.9505,3.3949 -4.3869,5.1465 -0.0067,0.0084 -0.0064,0.0108 -0.0109,0.019 -0.002,0.0035 -0.0023,0.022 -0.0025,0.0222 -0.0032,0.003 0.1569,1.8069 0.1717,1.9699 0.138,1.6198 0.2761,3.2396 0.4141,4.8594 -0.2003,-1.588 -0.4005,-3.1758 -0.6009,-4.7638 z"
            />
            <path
              fill="#a6a6a6"
              d="m 35.51055,43.935956 9.08155,7.730644 -1.1462,3.8206 0.191,3.8206 -5.34205,4.7118 L 68.4924,64.03675 68.2303,62.8856 55.0261,54.525 53.6509,54.3338 52.2757,54.1426 49.7674,52.7894 48.3013,51.0172 47.5149,48.3562 44.084,46.4303 41.7744,44.7264 40.229712,43.382062 c -1.841275,0.483307 -3.63078,0.512538 -4.719162,0.553894 z M 20.2129,59.3621 l -1.8114,-0.2845 2.1834,1.2358 0.7979,0.7999 -0.959,0.4474 0.8375,1.1781 -4.53735,1.23235 9.26255,-0.07345 -0.6792,-1.0003 -1.1888,-0.447 -2.1509,-2.3162 z"
            />
            <polygon
              fill="#D2D3D5"
              points="50.236,58.692 48.7077,58.3578 50.5499,59.8101 51.2231,60.7502 50.414,61.2759 51.1206,62.6605 48.3734,63.7782 55.1073,63.8021 54.5342,62.8469 53.5313,62.3216 51.7165,59.5994 "
            />
          </symbol>

          <symbol id="relief-hill-2-bw" viewBox="-1 -3 8 8">
            <ellipse opacity=".5" fill="#999999" ry="0.3351" rx="3.0743999" cy="1.8791" cx="3.0804" />
            <path
              fill="#ffffff"
              stroke="#999999"
              stroke-width=".02"
              d="M 2.7066,2.0352 C 2.7573,2.0405 2.788,2.0628 2.8782,2.069 3.3845,2.1035 4.4496,2.1292 4.7849,2.1263 5.1303,1.9669 5.2365,2.0027 4.91,1.685 4.768,1.5467 4.5243,1.4165 4.4651,1.24 L 4.0699,0.6097 C 3.5404,0.0812 3.4194,-0.1558 2.7112,0.1216 2.5027,0.2032 2.0357,0.1483 1.8793,0.385 L 1.7729,0.4597 1.6557,0.4832 C 1.253,0.7265 0.4907,1.2966 0.2344,1.6189 L -10e-5,1.9137 c 0.1493,0.0717 0.0843,-0.008 0.4743,0.0567 0.457,0.0758 1.0204,0.045 1.4852,0.0258 0.1785,-0.0098 0.537,0.0316 0.7472,0.0391 z"
            />
            <path
              fill="#a6a6a6"
              d="M 2.7255,1.4371 C 2.8227,1.5043 2.7491,1.4088 2.7712,1.5241 2.8686,1.4105 2.7861,1.4291 2.9136,1.3797 3.0935,1.6682 2.9201,1.6363 2.962,1.768 L 3.0069,1.9091 2.878,2.0689 3.1722,2.0972 C 3.1736,2.0987 4.7764,2.1218 4.7905,2.1217 5.136,1.9623 5.2421,1.9982 4.9156,1.6804 4.7736,1.5421 4.5299,1.4119 4.4707,1.2354 L 4.1029437,0.65588125 C 3.9960355,0.47122161 3.4417827,-0.04766763 3.4248515,0.06566779 c 0,0 0.1315782,0.14855025 0.1129341,0.17248171 -0.065811,0.0844749 -0.063435,0.30870883 -0.140794,0.34697916 C 3.1795801,0.69268484 3.1067492,0.88723142 3.0105664,0.97217062 2.9083739,1.0624171 2.8679064,1.1197473 2.8441054,1.1727881 Z M 3.9746,1.2289 C 3.7716,1.1814 3.7285,1.1717 3.5693,1.1065 3.6063,1.1851 3.6565,1.2662 3.6964,1.3066 3.7033,1.3136 4.1045,1.5611 3.725,1.7516 3.6411,1.7937 3.775,1.7952 3.6661,1.7674 3.6449,1.6925 3.6336,1.6769 3.6684,1.6077 3.7131,1.5189 3.6048,1.508 3.7729,1.562 L 3.7343,1.4797 C 3.6627,1.5157 3.6325,1.4836 3.5121,1.4814 3.1457,1.4747 3.3999,1.5306 3.1149,1.3064 3.1884,1.161 3.2309,1.1603 3.3219,1.063 3.4077,0.9615 3.4101,1.0571 3.6824,0.9843 4.0352,0.892 3.8839,1.087 4.0165,0.9275 l 0.063,0.121 C 3.9514,1.0291 3.9345,1.0221 3.8696,1.0582 3.878,1.1447 3.8717,1.1592 3.8746,1.1611 L 3.9745,1.229 Z"
            />
          </symbol>

          <symbol id="relief-hill-3-bw" viewBox="-1 -17 55 55">
            <ellipse fill="#999999" opacity=".5" cx="34.078" cy="14.5565" rx="17.5383" ry="2.4977" />
            <path
              fill="#fff"
              stroke="#999999"
              stroke-width=".15"
              d="M9.5101 10.696c-1.1371,-0.616 -2.0817,0.8736 -2.3778,1.983 2.316,1.1116 1.9087,-0.5195 7.8443,1.2694 1.893,0.5705 5.3152,2.5047 7.2126,2.0188 0.7716,0.8915 -0.8074,0.2993 1.3361,0.9441 0.9262,0.2787 1.3524,0.1052 2.2303,-0.0233 4.793,-0.0412 7.0949,-0.2386 11.5203,-0.7434l9.7932 -2.476c0.058,-0.0401 0.1681,-0.1253 0.2451,-0.1968 -1.0428,-2.3377 -2.2374,-2.3426 -3.6846,-3.9623l-2.5719 -2.6229c-2.3783,-2.3827 -2.1842,-1.4462 -4.5382,-2.9906 -2.2547,-1.4793 -3.7909,-3.6402 -7.2099,-3.8961l-1.3963 0c-0.1659,0.0108 -0.3346,0.026 -0.5081,0.045 -2.9309,0.3275 -4.9194,0.7402 -7.3265,2.2081 -1.2629,0.7705 -1.0411,1.1393 -2.1929,1.1886 -2.1831,0.0949 -6.7923,-4.2893 -9.5649,0.1226 -1.5845,-0.5314 -1.9841,0.1518 -4.761,1.5807 -1.4169,0.7288 -3.1099,1.4918 -3.5599,3.176 1.6951,0.3942 2.4781,1.1593 4.7551,1.1713 1.6962,1.1225 3.5935,-0.5488 4.7551,1.2038z"
            />
            <path
              fill="#a6a6a6"
              d="M8.321 3.5643c1.3481,-0.5748 2.6842,-1.4527 3.9644,-1.2288 1.6561,1.0005 0.7922,0.3254 1.2266,2.7948 2.0888,0.0081 0.0933,-0.2196 2.2281,-0.3487 -0.892,0.7179 -0.9283,0.7283 -1.8719,1.7596l-2.3903 -0.7678c0.6073,1.6523 0.9847,1.9825 -0.7277,3.888 -0.0607,0.0678 -0.1708,0.1822 -0.2212,0.237 -0.0515,0.0553 -0.1648,0.147 -0.2267,0.2375 1.8529,-1.3361 2.7769,-1.6376 3.824,-2.7341 1.3556,-1.4202 1.7125,-1.5481 3.8148,-2.8886 3.2367,-2.0628 4.5246,-3.4715 9.8192,-3.7427 3.2389,0.0944 3.0377,0.7809 5.5457,2.0215 -0.5997,1.3828 0.4956,-0.1779 -1.6973,1.0981 3.3951,0.3883 1.9624,1.9847 3.766,1.906l0.9397 -0.116c0.4799,0.0428 1.4934,0.468 2.1311,0.6366 0.019,2.3203 0.4289,3.9227 0.597,6.4615 -1.7699,-0.6176 -1.3887,-0.9506 -2.8333,-1.8301 -0.9273,-0.5645 -2.0411,-0.8085 -3.15,-1.1978 0.8551,0.9175 0.9457,0.5368 1.9299,1.1523 0.969,0.6062 1.1333,1.0872 1.8242,1.7835l-1.3307 0.6377c-0.0607,0.0304 -0.1892,0.09 -0.2755,0.148 1.1523,0.7619 1.7352,0.783 2.7959,1.61 -0.815,0.5932 -0.2343,0.2527 -0.7272,1.0628l9.7932 -2.476c0.058,-0.0401 0.1681,-0.1253 0.2451,-0.1968 -1.0428,-2.3377 -2.2374,-2.3426 -3.6846,-3.9623l-2.5719 -2.6229c-2.3783,-2.3827 -2.1842,-1.4462 -4.5382,-2.9906 -2.2547,-1.4793 -3.7909,-3.6402 -7.2099,-3.8961l-1.3963 0c-0.1659,0.0108 -0.3346,0.026 -0.5081,0.045 -2.9309,0.3275 -4.9194,0.7402 -7.3265,2.2081 -1.2629,0.7705 -1.0411,1.1393 -2.1929,1.1886 -2.1831,0.0949 -6.7923,-4.2893 -9.5649,0.1226z"
            />
          </symbol>

          <symbol id="relief-hill-4-bw" viewBox="-0.3 -2 5 5">
            <ellipse fill="#999999" opacity=".5" cx="2.6747" cy="1.0184" rx="1.9077" ry=".342" />
            <path
              fill="#a6a6a6"
              d="M2.2044 1.3541c-0.1954,-0.0321 -0.4239,0.0192 -0.6394,0.0064 -0.199,-0.0118 -0.3908,-0.0241 -0.5739,-0.0608 -0.0888,-0.01 -0.1874,-0.0432 -0.2716,-0.0656 -0.0826,-0.0219 -0.1876,-0.0277 -0.2635,-0.0505 -0.0536,-0.0161 -0.0695,-0.0305 -0.119,-0.0399 -0.0517,-0.0098 -0.0881,-0.0106 -0.1393,-0.0285 -0.0673,-0.0236 -0.1656,-0.0681 -0.1977,-0.1154 0.0201,-0.0316 0.0837,-0.0955 0.1144,-0.1309 0.1504,-0.1731 0.3051,-0.3572 0.5179,-0.4616 0.0654,-0.0321 0.1139,-0.0438 0.1651,-0.0802 0.0565,-0.0401 0.0848,-0.067 0.1373,-0.1072 0.0217,-0.0166 0.05,-0.0352 0.0699,-0.053 0.0345,-0.0309 0.0185,-0.032 0.0682,-0.0525 0.0626,-0.0548 0.1482,-0.0752 0.2398,-0.1026 0.1339,-0.0134 0.1379,-0.0191 0.2832,0.0039 0.0944,0.0149 0.1869,0.0288 0.2822,0.0441 0.2056,0.0328 0.3306,0.0881 0.4927,0.1654l0.1875 0.075c0.0209,-0.0159 0.023,0.0033 0,-0.0213 0.0257,0.006 0.0563,0.0125 0.0816,0.0194 0.0833,0.0185 0.1814,0.0344 0.2806,0.0163 0.1007,-0.0184 0.123,-0.0498 0.2495,-0.0498 0.3406,-0.0001 0.5977,0.1486 0.8473,0.3509 0.0315,0.0256 0.0537,0.0398 0.0763,0.0734 0.0448,0.0667 0.1432,0.2195 0.1361,0.2972 -0.2027,0.1549 -0.5328,0.094 -0.7013,0.1811 -0.0616,0.0318 -0.154,0.0618 -0.198,0.1013 -0.0952,0.0855 -0.0629,0.057 -0.2107,0.0749 -0.2659,0.0323 -0.0629,0.0115 -0.262,0.009 -0.0936,-0.0011 -0.1844,0.0171 -0.2669,0.0346 -0.035,0.0074 -0.2023,-0.0064 -0.2742,-0.0064 -0.0102,-0.0046 -0.0204,-0.0076 -0.0311,-0.0125 -0.0313,-0.0145 -0.018,-0.0082 -0.0332,-0.0185l-0.0477 0.0043z"
            />
            <path
              fill="#fff"
              stroke="#999999"
              stroke-width=".02"
              d="M2.5582 0.2788c0.0257,0.006 0.0563,0.0125 0.0816,0.0194l-0.0467 0.0148c0.0989,0.0238 0.1701,0.0383 0.2783,0.0346 0.0927,-0.0032 0.1605,-0.0355 0.2563,-0.0416 0.0059,0.0681 0.0125,0.0546 0.0803,0.0661l0.3034 0.0735c0.2633,0.0879 0.1601,0.091 0.2872,0.1905 -0.0072,-0.0011 -0.2077,-0.1381 -0.2253,-0.0385 -0.007,0.0395 -0.0011,0.0619 0.043,0.0938 0.0291,0.0211 0.0671,0.0438 0.088,0.0405 -0.0384,0.0004 -0.0569,0.0018 -0.0921,-0.004 -0.024,-0.0039 0.0064,-0.0164 -0.0725,-0.0038 -0.0034,0.0005 -0.0099,0.0081 -0.0124,0.0042 -0.0042,-0.0066 -0.0582,0.0303 0.0019,0.1273 -0.0375,-0.0202 -0.0361,-0.0156 -0.0868,-0.0167 -0.0071,0.0087 -0.0283,0.0056 -0.0238,0.0831 -0.0556,0.0012 -0.0535,0.009 -0.0913,0.0299 0.0024,0.077 0.0051,0.0621 0.0496,0.0999 0.0394,0.0335 0.0647,0.125 0.1648,0.0333l0.0588 -0.0499c0,0 0.0278,0.0448 0.0854,0.0231 0.0806,-0.0303 0.0129,-0.1125 0.0099,-0.1178 0.0355,0.0244 0.0617,0.086 0.0845,0.1037 0.0046,0.0035 -0.0166,0.0192 0.0438,0.016 0.0518,-0.0028 0.0194,0.008 0.0396,-0.0218 0.0158,-0.0234 0.0088,-0.0578 0.0079,-0.0856 0.0039,0.0148 0.0561,0.1419 0.1436,0.1089 0.0935,-0.0353 -0.0041,-0.1155 -0.0211,-0.1773 0.0367,0.0117 0.0589,0.0515 0.0853,0.0766 0.0256,0.0244 0.1168,0.0761 0.1231,-0.0023l0.027 0.0273c-0.2027,0.1549 -0.5328,0.094 -0.7013,0.1811 -0.0616,0.0318 -0.154,0.0618 -0.198,0.1013 -0.0952,0.0855 -0.0629,0.057 -0.2107,0.0749 -0.2659,0.0323 -0.0629,0.0115 -0.262,0.009 -0.0936,-0.0011 -0.1844,0.0171 -0.2669,0.0346 -0.035,0.0074 -0.2023,-0.0064 -0.2742,-0.0064 -0.0102,-0.0046 -0.0204,-0.0076 -0.0311,-0.0125 -0.0313,-0.0145 -0.018,-0.0082 -0.0332,-0.0185 0.0891,0.0002 0.081,0.01 0.1771,-0.0035 0.0554,-0.0078 0.0792,0.0219 0.1781,0.0153 -0.0012,-0.1141 -0.0431,-0.1159 -0.0838,-0.1919 0.0736,0.0596 0.1594,0.1743 0.2952,0.1568 0.0087,-0.0222 0.019,-0.061 0.0253,-0.0724 0.0339,0.0425 0.0832,0.0686 0.1632,0.0681 0.0244,-0.0261 0.0098,0.0013 0.0138,-0.048 0.0333,0.0216 0.031,0.0326 0.0777,0.0235 0.076,-0.0149 0.0343,-0.0074 0.0465,-0.0393 -0.0461,-0.0577 -0.023,-0.0086 -0.0857,-0.0409l0.0014 -0.2034c-0.0355,0.0147 -0.0311,0.0231 -0.0523,0.0541 -0.0025,-0.0025 -0.0053,-0.0064 -0.0067,-0.0081l-0.169 -0.2127c-0.0859,-0.0724 -0.0239,-0.1127 -0.123,-0.0992l0.0251 0.0999c-0.1164,-0.0645 0.0039,-0.0841 -0.2276,-0.1398 -0.0076,-0.0589 0.0139,-0.0981 -0.0272,-0.134 -0.0531,-0.0464 -0.014,0.0293 -0.1724,-0.0642 0.0111,-0.0489 0.1259,-0.0586 0.032,-0.1513 -0.0164,-0.0162 -0.0359,-0.0275 -0.0442,-0.03l0.0589 0.004c0.0321,-0.0062 0.0135,0.0017 0.0356,-0.0132 0.0008,-0.0636 0.0089,-0.0413 -0.0194,-0.0945l0.1875 0.075c0.0209,-0.0159 0.023,0.0033 0,-0.0213zm-0.3538 1.0753c-0.1954,-0.0321 -0.4239,0.0192 -0.6394,0.0064 -0.199,-0.0118 -0.3908,-0.0241 -0.5739,-0.0608 -0.0888,-0.01 -0.1874,-0.0432 -0.2716,-0.0656 -0.0826,-0.0219 -0.1876,-0.0277 -0.2635,-0.0505 -0.0536,-0.0161 -0.0695,-0.0305 -0.119,-0.0399 -0.0517,-0.0098 -0.0881,-0.0106 -0.1393,-0.0285 -0.0673,-0.0236 -0.1656,-0.0681 -0.1977,-0.1154 0.0201,-0.0316 0.0837,-0.0955 0.1144,-0.1309 0.1504,-0.1731 0.3051,-0.3572 0.5179,-0.4616 0.0654,-0.0321 0.1139,-0.0438 0.1651,-0.0802 0.0565,-0.0401 0.0848,-0.067 0.1373,-0.1072 0.0217,-0.0166 0.05,-0.0352 0.0699,-0.053 0.0345,-0.0309 0.0185,-0.032 0.0682,-0.0525 0.0626,-0.0548 0.1482,-0.0752 0.2398,-0.1026 0.0123,0.038 0,0.0906 0.0726,0.0885 0.0489,-0.0014 0.0688,-0.0207 0.1504,-0.0092 0.1236,0.0175 0.1629,0.0134 0.2608,0.0655 -0.1347,0.3666 0.1384,0.2279 0.2222,0.2672 -0.0111,0.128 -0.062,-0.0039 -0.1137,0.1523 -0.0107,0.0323 0.0054,0.0077 -0.0132,0.034 -0.0641,-0.0115 -0.1919,-0.0698 -0.2164,-0.001 -0.0343,0.0963 0.0971,0.1029 0.151,0.1324 -0.027,0.0223 -0.0775,0.0132 -0.1011,0.0376 -0.0221,0.023 -0.0184,0.0643 -0.0172,0.1052l0.0784 0.0476c-0.0095,0.0791 -0.0071,0.0636 0.0043,0.144 -0.1394,-0.0074 -0.0164,-0.047 -0.164,-0.0413 -0.0305,0.1067 0.0115,-0.0011 0.0135,0.2172 -0.034,0.0162 -0.0766,0.0336 -0.0801,0.0769 0.0768,0.0049 0.0838,-0.0031 0.1494,-0.0132 0.0783,-0.012 0.066,0.0121 0.1545,0.0122 0.1465,0 0.2584,-0.0519 0.3406,0.0265z"
            />
          </symbol>

          <symbol id="relief-hill-5-bw" viewBox="-5 -17 39 39">
            <ellipse fill="#999999" opacity=".5" cx="18.5104" cy="8.2102" rx="11.6925" ry="2.0964" />
            <path
              fill="#fff"
              stroke="#999999"
              stroke-width=".15"
              d="M2.6664 8.569l6.6798 1.0468c1.4368,0.1034 1.6554,-0.5235 4.6148,-0.5235l3.4373 0.5804c2.3733,0.4005 4.8164,-0.0146 7.2145,-0.5751 0.893,-0.209 1.8708,-0.4082 2.0891,-1.2267 -0.6616,-0.4433 -3.0827,-0.9749 -3.4846,-1.2219l-3.9205 -4.6365c-1.6138,-1.5379 -2.386,-2.5369 -5.0705,-1.7203 -1.2608,0.3838 -2.6905,1.3614 -3.9599,1.9773 -0.9728,0.4719 -0.5971,-0.1545 -1.818,0.0743 -1.0217,0.1913 -1.2501,0.6291 -1.4676,1.1634 -2.2544,0.5262 -1.6372,0.4547 -3.4443,1.9663 -0.9647,0.8068 -3.2527,1.1607 -3.5364,2.2228l0.6095 0.2632 2.0569 0.6095z"
            />
            <path
              fill="#a6a6a6"
              d="M6.9807 3.5071c0.8323,-0.3105 1.0225,-0.6742 1.5214,-0.5228 -0.1684,0.4101 -0.1168,0.2931 -0.4328,0.582 -1.3408,1.2267 -0.4657,0.4693 -0.8362,1.7841 -0.4626,1.6418 -2.0311,1.1235 -2.0325,1.1235l0.0086 1.2088c-1.2701,-0.2257 -0.6401,-0.6776 -2.5429,0.8863 1.5832,0.7156 4.745,0.7674 6.6798,1.0468l2.1397 -0.914c-0.3337,-0.6582 -0.1337,-0.027 -0.3091,-0.8347 -0.4497,-2.0724 -0.3922,-0.2204 -0.0607,-2.8923 0.0067,-0.0798 0.0244,-0.1027 0.0533,-0.1459 0.2861,0.1328 0.5641,-0.224 0.5274,1.2952 -0.0105,0.4366 -0.1068,0.385 0.0406,0.8233 0.1839,0.5467 0.0712,0.2508 0.348,0.4693 -0.1223,-0.8276 0.1904,-1.5961 -0.0399,-2.3841 -0.1354,-0.4636 -0.3659,-0.461 -0.284,-2.0483l1.209 -0.5235c-0.9178,-0.4863 -1.294,-0.0822 -2.2687,0.0891l2.9155 -1.7906c1.1801,-0.417 2.3153,-0.8054 3.3989,-0.106l0.3676 0.7225c-0.5436,0.2446 -1.1201,0.39 -2.0258,0.3786 -0.562,0.7683 -0.8409,0.6506 -1.1381,0.8811 0.0779,1.2646 -0.0929,0.5594 0.5414,1.1361 1.0146,0.9226 0.1753,1.4158 0.0537,1.6489l-0.0229 0.9993c-1.8749,0.1574 -0.8842,0.3953 -1.0724,1.7156 -0.8787,0.3071 -0.4001,0.4079 -1.3277,0.1376l0.0762 0.2778 1.4927 0.5417c0.2479,0.2778 2.7858,0.5028 3.4373,0.5804 2.3898,0.2859 4.8164,-0.0146 7.2145,-0.5751 0.893,-0.209 1.8708,-0.4082 2.0891,-1.2267 -0.6616,-0.4433 -3.0827,-0.9749 -3.4846,-1.2219l-3.9205 -4.6365c-1.6138,-1.5379 -2.386,-2.5369 -5.0705,-1.7203 -1.3728,0.4175 -2.5522,1.2943 -3.9599,1.9773 -0.9728,0.4717 -0.5971,-0.1545 -1.818,0.0743 -1.0217,0.1913 -1.2501,0.6291 -1.4676,1.1634z"
            />
          </symbol>

          <symbol id="relief-dune-2-bw" viewBox="-5 -17 40 40">
            <ellipse fill="#999999" opacity=".5" cx="17.1027" cy="5.3226" rx="17.1027" ry=".5194" />
            <polygon
              fill="#fff"
              stroke="#999999"
              stroke-width=".1"
              points="15.2112,0 22.8169,2.667 30.4225,5.334 15.2112,5.334 -0,5.334 7.6057,2.667"
            />
            <path
              fill="#a6a6a6"
              d="M15.2112 0c-0.1987,1.1209 -3.4329,1.1587 -1.0819,2.2964 1.1972,0.5794 -1.7799,1.4239 -1.9267,1.5482 -0.5158,0.4369 -3.2959,1.0761 -3.4438,1.4894l6.4524 0 15.2113 0 -7.6057 -2.667 -7.6057 -2.667z"
            />
          </symbol>

          <symbol id="relief-deciduous-2-bw" viewBox="-27 -25 70 70">
            <ellipse fill="#999999" opacity=".5" cx="9.3273" cy="18.4825" rx="5.534" ry="1.0889" />
            <polygon
              fill="#808080"
              points="8.6754,13.1329 9.4092,11.4084 10.6975,12.1523 8.8545,14.6027 9.3274,18.4825 6.2627,18.4825 6.8826,13.3966 5.2563,11.2344 6.4063,10.5705 7.0983,12.1967 8.2623,12.1967 8.5971,10.4211 9.2152,10.5814 8.5924,12.4519"
            />
            <path
              fill="#fff"
              stroke="#999999"
              stroke-width=".2"
              d="M 7.15625,0.001953 C 5.947743,0.051633 4.777378,0.866372 4.541016,2.291016 1.697616,1.720116 1.251953,5.136719 1.251953,5.136719 0.715975,5.415425 -0.025896,6.473322 0,7.443359 0.02091,8.22648 0.328216,8.934547 0.853516,9.435547 c -0.08115,0.334708 -0.002,1.216797 -0.002,1.216797 0.575571,2.696047 4.099448,3.07453 5.234376,0.447265 1.003399,0.3758 2.118546,0.375554 3.123046,0.002 0.0961,1.432601 1.233993,2.55516 2.746094,2.566407 1.485443,0.01105 2.604681,-1.013788 2.738281,-2.486328 1.9961,-0.5986 2.626179,-3.12715 1.142579,-4.59375 0.411446,-1.23286 0.403633,-1.864377 -0.51171,-2.949274 C 14.962812,3.227083 14.592119,2.82906 13.603479,2.761711 13.005579,1.152311 11.087816,0.485048 9.626916,1.347648 9.059872,0.387598 8.096163,-0.036697 7.156213,0.001945 Z"
            />
            <path
              fill="#b3b3b3"
              d="m 15.287006,3.6862427 c 0.780869,0.8257791 0.968452,1.9254248 0.493751,2.9018573 1.4836,1.4666 0.908743,3.9945 -1.087357,4.5931 -0.1336,1.3952 -1.3087,2.4863 -2.7389,2.4863 -1.4569,0 -2.6492,-1.1324 -2.7453,-2.565 C 8.2047,11.4761 7.0895,11.4745 6.0861,11.0987 5.0853,13.6233 1.48555,13.303294 0.92815,10.649694 6.1764485,10.111351 12.017072,7.3675453 15.287006,3.6862427 Z"
            />
          </symbol>

          <symbol id="relief-deciduous-3-bw" viewBox="-27 -25 70 70">
            <ellipse opacity=".5" fill="#999999" ry="1.0889" rx="5.5339999" cy="18.4825" cx="9.3273001" />
            <polygon
              fill="#808080"
              points="10.6975,12.1523 8.8545,14.6027 9.3274,18.4825 6.2627,18.4825 6.8826,13.3966 5.2563,11.2344 6.4063,10.5705 7.0983,12.1967 8.2623,12.1967 8.5971,10.4211 9.2152,10.5814 8.5924,12.4519 8.6754,13.1329 9.4092,11.4084 "
            />
            <path
              fill="#fff"
              stroke="#999999"
              stroke-width=".2"
              d="M 7.15625,0.001953 C 5.947743,0.051633 4.777378,0.866372 4.541016,2.291016 1.697616,1.720116 1.251953,5.136719 1.251953,5.136719 0.715975,5.415425 -0.025896,6.473322 0,7.443359 0.02091,8.22648 0.328216,8.934547 0.853516,9.435547 c -0.08115,0.334708 -0.002,1.216797 -0.002,1.216797 0.575571,2.696047 4.099448,3.07453 5.234376,0.447265 1.003399,0.3758 2.118546,0.375554 3.123046,0.002 0.0961,1.432601 1.233993,2.55516 2.746094,2.566407 1.485443,0.01105 2.604681,-1.013788 2.738281,-2.486328 1.9961,-0.5986 2.626179,-3.12715 1.142579,-4.59375 0.411446,-1.23286 0.403633,-1.864377 -0.51171,-2.949274 C 14.962812,3.227083 14.592119,2.82906 13.603479,2.761711 13.005579,1.152311 11.087816,0.485048 9.626916,1.347648 9.059872,0.387598 8.096163,-0.036697 7.156213,0.001945 Z"
            />
            <path
              fill="#b3b3b3"
              d="m 15.287006,3.6862427 c 0.780869,0.8257791 0.968452,1.9254248 0.493751,2.9018573 1.4836,1.4666 0.908743,3.9945 -1.087357,4.5931 -0.1336,1.3952 -1.3087,2.4863 -2.7389,2.4863 -1.4569,0 -2.6492,-1.1324 -2.7453,-2.565 C 8.2047,11.4761 7.0895,11.4745 6.0861,11.0987 5.0853,13.6233 1.48555,13.303294 0.92815,10.649694 6.1764485,10.111351 12.017072,7.3675453 15.287006,3.6862427 Z"
            />
            <g fill="#808080">
              <circle r=".5" cy="8.3897734" cx="2.4284508" />
              <circle r=".5" cy="7.3032885" cx="7.146461" />
              <circle r=".5" cy="7.5826468" cx="13.668243" />
              <circle r=".5" cy="10.326545" cx="11.61261" />
              <circle r=".5" cy="6.656527" cx="10.684683" />
              <circle r=".5" cy="3.3609581" cx="7.6241026" />
              <circle r=".5" cy="5.1369228" cx="3.9471674" />
              <circle r=".5" cy="4.1185794" cx="11.777494" />
              <circle r=".5" cy="10.220185" cx="4.8988838" />
            </g>
          </symbol>

          <symbol id="relief-conifer-2-bw" viewBox="-29 -22 72 72">
            <ellipse fill="#999999" ry="1.0889" rx="5.534" cy="22.0469" cx="9.257" opacity=".5" />
            <rect fill="#808080" height="3.8506" width="2.5553999" y="18.378901" x="6.1294999" />
            <path
              fill="#fff"
              stroke="#999999"
              stroke-width=".2"
              d="M 7.4340812,0.00390625 2.7791,8.1383 l 1.8745,0 -2.8102,4.7786 1.4306,0 -3.274,5.7789 3.7081,0 -0.0157,0.1578 -0.163,1.6315 1.3679,-0.9533 1.1999,-0.836 1.3546874,-0.01105 z"
            />
            <path
              fill="#b3b3b3"
              d="m 10.4603,8.1383 2.7736,4.7786 -1.5107,0 3.2298,5.7789 -3.5851,0 c 0.0635,0.63718 0.127242,1.274336 0.1909,1.9115 L 10.1909,19.654 8.8229,18.7009 C 8.399397,18.690076 7.8667262,18.6958 7.4072,18.6958 L 7.43,0 12.1753,8.1383 Z"
            />
          </symbol>

          <symbol id="relief-coniferSnow-1-bw" viewBox="-40 -33 100 100">
            <ellipse opacity=".5" fill="#999999" ry="1.2864" rx="6.5377998" cy="26.225401" cx="11.2836" />
            <rect fill="#808080" height="4.5489998" width="3.0188999" y="21.892099" x="7.5889001" />
            <path
              fill="#ffffff"
              stroke="#999999"
              stroke-width=".3"
              d="m 9.162109,0 -5.882812,9.996094 2.210937,0 -3.318359,5.646484 1.695313,0 L 0,22.46875 l 4.503906,0 -0.232422,2.330078 1.976563,-1.378906 1.367187,-0.951172 1.279297,0 0.570313,0 1.234375,0 1.572265,1.095703 1.976563,1.378906 -0.246094,-2.474609 4.355469,0 -3.814453,-6.826172 1.791015,0 -3.277343,-5.646484 2.027343,0 L 9.162109,0 Z"
            />
            <path
              fill="#cccccc"
              d="M 6.5951823,6.0195125 7.5469804,6.4667104 9.1405,5.8391 9.1169,9.7773 8.552,9.4859 8.3637,8.2407 7.4421,9.6992 6.8464,8.8302 6.0831,10.3216 5.6688004,9.8927321 3.4283446,9.8979233 5.2938502,6.7648265 Z M 4.603612,22.380706 0.16061807,22.359941 1.5538414,19.928206 3.3194,19.3188 4.21,21.258 5.7238,19.9809 6.3802,21.6688 9.115,19.1959 9.1085823,22.380706 7.581747,22.365132 4.3703321,24.632083 Z M 2.3197404,15.54208 3.8518545,13.002948 5.0889,13.3977 6.6027,12.1206 7.2591,13.8086 9.1447,11.8712 9.1169,16.5061 8.2922,15.2732 7.1877,16.7735 6.5249,15.0589 6.0831,15.9966 5.3456,15.9519 3.348006,16.76238 3.9658919,15.556763 Z"
            />
            <path
              fill="#b3b3b3"
              d="M 18.192172,22.380612 16.667913,19.642582 15.0363,20.5793 14.237,19.838 l -0.8708,1.3664 -1.4648,-0.7323 -1.2246,-1.4677 -0.4951,1.9892 -1.0754414,-1.782525 -0.013251,3.16953 1.6157154,5e-6 3.421234,2.381538 -0.228295,-2.376108 z M 12.95855,6.6024 12.1509,5.9991 11.1016,6.4009 9.1403,5.839 9.1167,9.7772 l 0.8802,-1.233 1.1046,1.5004 0.6627,-1.7147 0.4418,0.9377 0.7733,-0.6162 1.959503,1.2633353 z M 16.172777,15.54218 14.629945,12.897283 13.2003,13.3978 12.1509,12.728 11.1016,13.1299 9.1005515,11.885882 9.0989858,16.5061 9.997,15.2732 l 1.1046,1.5003 0.6627,-1.7146 0.4418,0.9377 0.7733,-0.6163 2.063911,1.342831 -0.612634,-1.166368 z"
            />
          </symbol>

          <symbol id="relief-acacia-2-bw" viewBox="-25 -25 70 70">
            <ellipse fill="#999999" opacity=".5" cx="11.8845" cy="14.9969" rx="9.8385" ry=".9674" />
            <polygon
              fill="#808080"
              points="10.5615,11.0945 10.5829,11.0945 12.2991,7.8722 10.169,4.0939 10.3125,4.0095 12.478,7.5361 13.4213,5.7652 13.4149,5.6589 13.4148,5.6586 13.4149,5.6586 13.3389,4.3771 13.6356,4.3312 13.934,5.5138 17.4746,4.5262 17.5871,4.7584 13.7287,6.092 11.3715,11.2549 11.3489,15.121 9.7272,15.121 10.2179,12.7528 7.0146,6.7865 2.9196,5.5604 2.9861,5.3123 6.8814,6.2337 6.9778,4.8164 7.2348,4.8164 7.3396,6.359 7.7405,6.9989 9.0507,3.8628 9.3276,3.9662 8.1262,7.6071 8.1199,7.6047 10.4554,11.3337 10.548,11.1601 "
            />
            <path
              fill="#b3b3b3"
              d="M17.24 4.6771c0.136,0.1019 0.2845,0.1998 0.443,0.2908 0.9287,0.5331 1.8546,0.6285 2.0681,0.2131 0.3808,-0.7405 -1.3199,-1.8023 -1.9781,-2.0335 -0.6052,-1.333 -3.794,-1.9852 -5.2015,-1.7397 -1.2498,-1.425 -6.9085,-0.6433 -6.9145,1.0269 -1.0033,-0.0836 -2.9136,0.277 -3.2587,1.3145 -0.5348,0.2836 -2.068,1.3687 -1.6854,2.1132 0.4575,0.8898 2.5826,-0.2585 3.1902,-0.7762 0.5807,0.0788 1.2092,0.0303 1.7764,-0.1188 0.9067,0.5316 2.4273,0.3711 2.9534,-0.6075 1.2601,0.574 3.2016,0.6057 4.5418,0.2512 1.1523,0.2578 2.8891,0.2519 4.0653,0.0661z"
            />
          </symbol>

          <symbol id="relief-palm-2-bw" viewBox="-27 -25 70 70">
            <ellipse fill="#999999" opacity=".5" cx="10.1381" cy="16.686" rx="6.176" ry="1.0271" />
            <path
              fill="#b3b3b3"
              d="M11.289 0.09c-1.2071,0.9898 -2.5231,2.5278 -3.1763,3.6163 -0.0463,-0.0865 -0.0877,-0.1708 -0.126,-0.2537l-6.5578 -1.8672c2.4316,-1.0619 4.8486,-1.347 6.2847,1.0194 -0.3892,-2.3401 2.8747,-2.8412 3.5754,-2.5147zm-11.289 7.6813l7.6896 -3.943c-3.1531,-1.6911 -7.1655,0.9025 -7.6896,3.943zm4.8314 3.1553c1.6467,-1.9 2.7841,-3.9718 2.7217,-6.4483 -3.3941,1.1324 -3.7342,4.899 -2.7217,6.4483zm6.5246 -0.3669c-1.8863,-2.4506 0.0568,-3.042 -3.0585,-5.9451 3.3784,-0.3062 5.1525,1.8059 3.0585,5.9451zm4.0962 -4.9207c-2.5616,-0.0001 -4.7634,-0.6542 -6.7787,-1.6477 4.523,-1.795 6.6868,0.7704 6.7787,1.6477zm1.1549 -4.3378l-7.9602 2.6334c0.8957,-3.4641 5.2694,-3.6955 7.9602,-2.6334z"
            />
            <path
              fill="#808080"
              d="M8.8323 5.3c0.3946,0 0.7145,-0.3199 0.7145,-0.7145 0,-0.3946 -0.3199,-0.7145 -0.7145,-0.7145 -0.0253,0 -0.0503,0.0013 -0.0749,0.0039 0.0473,-0.0954 0.0738,-0.203 0.0738,-0.3167 0,-0.3946 -0.3199,-0.7145 -0.7145,-0.7145 -0.3946,0 -0.7145,0.3199 -0.7145,0.7145 0,0.0844 0.0148,0.1653 0.0416,0.2405 -0.0427,-0.008 -0.087,-0.0122 -0.1321,-0.0122 -0.3946,0 -0.7145,0.3199 -0.7145,0.7145 0,0.3946 0.3199,0.7145 0.7145,0.7145 0.2723,0 0.509,-0.1524 0.6296,-0.3764 0.7194,3.9586 0.8226,7.8738 0.1215,11.7329l1.2482 0.0022c0.2847,-3.6277 0.2392,-7.3464 -0.6033,-11.2851 0.0404,0.0072 0.0821,0.0109 0.1246,0.0109z"
            />
          </symbol>

          <symbol id="relief-grass-2-bw" viewBox="-50 -50 130 130">
            <path
              fill="#b3b3b3"
              d="M8.006 9.9689c0.01,0.1224 0.2562,0.6142 0.3168,0.7806 0.1951,0.5354 0.1473,0.2936 0.0182,0.823 -0.0735,0.3015 -0.1633,0.593 -0.2331,0.8796 -0.0469,0.1924 -0.1471,0.7957 -0.2314,0.9 -0.2344,-0.4506 -0.4442,-0.9086 -0.6939,-1.3471 -0.1591,-0.2793 -0.6042,-1.0566 -0.8075,-1.2337 -0.027,0.3721 0.3191,1.9295 0.4091,2.2876 0.2439,0.9703 0.4829,1.7317 0.7253,2.648 0.0492,0.1862 0.0075,0.4256 -0.003,0.6304 -0.0445,0.8712 -0.0559,1.7966 0.0131,2.6635 0.0307,0.3842 0.1223,0.8417 0.1284,1.2016l0.1024 0.5881c0.0029,0.0075 0.0086,0.0171 0.0112,0.0231 0.0026,0.0061 0.0069,0.0161 0.0121,0.0229 -0.0201,0.1409 0.3189,1.5864 0.3765,1.7054 0.0612,0.1268 0.0114,0.0405 0.0791,0.0918l-0.0379 -1.2668 0.0028 -1.5257c0.0722,-0.204 -0.0201,-1.142 0.0982,-1.4492l0.4611 1.6129c0.1818,0.5322 0.3534,1.028 0.5451,1.5638 0.0597,-0.071 0.0533,-0.0927 0.071,-0.2157 0.1947,-1.3511 0.0668,-2.8802 -0.189,-4.1914 -0.0678,-0.3476 -0.1555,-0.6369 -0.241,-0.9833 -0.0601,-0.2431 -0.2712,-0.7233 -0.2313,-0.9674 0.0582,-0.357 0.1448,-0.6613 0.2123,-1.0091 0.0546,-0.2811 0.1565,-0.7292 0.2424,-0.9837 0.1078,0.1108 0.4968,1.7381 0.5634,2.0399 0.3158,1.4317 0.4477,3.1118 0.644,4.58 0.0302,0.226 0.2616,2.1642 0.3146,2.3266 0.0248,-0.0338 0.0036,0.0249 0.0403,-0.076 0.0751,-0.2062 0.2653,-1.3853 0.2934,-1.5866 0.3244,-2.3247 0.1769,-5.002 -0.5336,-7.1701 -0.2609,-0.7959 -0.3821,-1.096 -0.7028,-1.7968 -0.0741,-0.162 -0.1159,-0.1782 -0.0489,-0.3857l0.4829 -1.5332c0.0488,-0.156 0.2436,-0.6378 0.256,-0.7337l0.1925 2.3718c0.0494,0.7686 0.1347,1.5966 0.2136,2.3623 0.0805,0.7816 0.1609,1.5731 0.2173,2.339 0.058,0.7884 0.183,1.5648 0.2406,2.343 0.0575,0.776 0.1742,1.5495 0.2513,2.3048l0.7845 6.9541c0.0617,-0.1477 0.9814,-6.953 0.9883,-7.0128 0.0893,-0.7707 0.2394,-1.5785 0.3252,-2.3506 0.112,0.5882 0.1575,1.1641 0.3065,1.7461 0.0398,0.1551 0.3674,1.4344 0.5327,1.5545l0.0617 -2.3153c0.0245,-0.3683 0.0303,-0.7359 0.0476,-1.1077 0.0447,-0.964 0.1773,-2.2719 0.3848,-3.1701 0.0875,-0.379 0.3809,-1.6006 0.5287,-1.8412 0.132,0.2798 0.2531,1.6127 0.2982,2.009 0.1201,1.0555 0.1258,3.4769 0.0559,4.556l-0.1185 2.2153c0.251,0.0329 0.9582,0.1558 1.1849,0.1215 0.0303,-0.0714 0.1058,-0.6785 0.1264,-0.8113 0.2594,-1.6732 0.4863,-3.3522 0.7616,-5.0316 0.0214,-0.1304 0.0473,-0.2766 0.0686,-0.4156 0.0157,-0.1018 0.0233,-0.2382 0.067,-0.3309 0.025,-0.0531 0.0105,-0.0337 0.04,-0.0694 0.1873,0.626 0.0716,1.8797 0.0618,2.5119l-0.1128 5.2565c-0.018,0.8181 -0.091,1.8066 -0.0418,2.6146 0.1147,-0.1814 1.3959,-4.3477 1.5767,-4.9006l0.7049 -2.0785c0.1608,-0.4479 0.3427,-0.9066 0.5472,-1.3256 0.1626,-0.333 0.5024,-0.8236 0.7601,-1.0852 0.3655,-0.3712 0.6129,-0.5671 1.2842,-0.5902 -0.8746,-0.4681 -1.8535,0.3689 -2.2598,0.7793 -0.2665,0.2692 -0.5145,0.5958 -0.7389,0.9385 -0.2337,0.357 -0.4033,0.6698 -0.6011,1.058 -0.1232,-0.266 0.0664,-1.8232 -0.6104,-3.5206 -0.4097,-1.0277 -0.4293,-0.7108 -0.2398,-1.5439 0.0682,-0.2999 0.1235,-0.5615 0.2058,-0.8484 0.0697,-0.2431 0.2306,-0.5792 0.2694,-0.7712 -0.4432,0.4059 -0.7179,1.2818 -0.9318,1.664 -0.0594,-0.0312 -0.2359,-0.3425 -0.2841,-0.4048 -0.0471,0.1146 0.1605,0.5585 0.1358,0.7746 -0.0102,0.0883 -0.2029,0.5981 -0.2507,0.7454l-0.4816 1.5262c-0.0598,-0.1425 -0.0699,-0.5906 -0.0856,-0.7876 -0.0761,-0.9568 -0.3857,-2.0152 -0.7118,-2.8963 -0.2156,-0.5824 -0.3107,-0.4252 -0.0598,-0.9737l0.4293 -0.9123 0.1352 -0.258c0.0352,-0.0635 0.0899,-0.1571 0.1339,-0.233 0.0651,-0.1123 0.2579,-0.3769 0.284,-0.4735 0.2499,-0.3174 0.4001,-0.6152 0.7209,-0.964 0.0946,-0.1028 0.2308,-0.2068 0.2869,-0.3007 -0.8031,0.1081 -1.9073,1.3062 -2.4276,1.9965 -0.0998,0.1323 -0.1788,0.2727 -0.268,0.3818 -0.0957,-0.0695 -0.3155,-0.5096 -0.4017,-0.6465 -0.1802,-0.2861 -0.0988,-0.3491 -0.0004,-0.8342 0.2597,-1.2819 0.6949,-2.7994 1.3548,-3.8989 0.1186,-0.1975 0.3456,-0.4924 0.4143,-0.6494 -0.4149,0.204 -1.1763,1.513 -1.4167,1.9752 -0.423,0.8133 -0.4558,1.0521 -0.7359,1.7951 -0.0367,0.0973 -0.1645,0.5451 -0.237,0.6227 -0.1537,-0.0895 -0.3924,-0.5679 -0.5678,-0.6617 0.0322,0.1402 0.1504,0.3661 0.2209,0.5158 0.3343,0.7092 0.2771,0.3999 -0.0743,1.7054 -0.2868,1.0653 -0.884,3.8898 -1.0382,4.9878 -0.0539,0.3833 -0.4366,2.3809 -0.427,2.5467 -0.0805,-0.394 -0.1065,-0.7929 -0.1571,-1.2144l-0.4637 -3.7082c-0.2118,-1.6323 -0.4588,-3.2351 -0.6682,-4.8653 -0.2162,-1.683 -0.2809,-0.8009 0.1957,-2.2675 0.0942,-0.2897 0.2658,-0.7185 0.3818,-1.009 0.1374,-0.3442 0.2404,-0.6702 0.3713,-1.0216 0.2551,-0.6852 0.52,-1.3285 0.761,-2.0231 0.1398,-0.4033 0.7296,-1.8322 0.763,-2.0313 -0.3354,0.1699 -1.918,3.0615 -2.2394,3.7079 -0.1032,0.2076 -0.2149,0.4192 -0.3313,0.6609 -0.0848,0.1764 -0.235,0.5506 -0.3346,0.6597 -0.0894,-0.1864 -0.3719,-2.7916 -0.3047,-3.4028 0.0097,-0.0873 0.0319,-0.1378 -0.0068,-0.208 -0.4978,1.4841 -0.1261,4.3856 -0.2115,4.7997l-0.7467 1.8056c-0.171,0.4381 -0.559,1.5984 -0.6942,1.89 -0.0155,-0.01 -1.3331,-1.7727 -2.0467,-1.9895 0.0785,0.1951 0.6092,0.8361 0.7782,1.2903l0.333 0.6734c0.0542,0.0927 0.0073,0.0353 0.0738,0.0817zm13.0512 11.8827c0.0536,-1.3603 -0.0071,-3.1476 0.8463,-4.2995 0.5114,-0.6901 0.6324,-0.5515 0.9169,-0.8091 -1.1337,-0.0648 -1.7274,1.0616 -2.0289,1.8806 -0.1635,0.4445 -0.2622,1.2108 -0.2241,1.7503 0.0323,0.4579 0.1972,1.2068 0.4898,1.4778zm-21.0572 -4.891c0.0398,0.1282 0.3436,0.3131 0.5603,0.529 0.5272,0.5249 1.061,1.1995 1.3065,1.9899 0.1823,0.587 0.3424,1.0807 0.4692,1.7194 0.0536,0.2706 0.3253,1.7034 0.3987,1.8101 0.1145,-0.2387 0.1545,-1.4669 0.1547,-1.841 0.0009,-1.3861 -0.4413,-3.0513 -1.5172,-3.8375 -0.144,-0.1052 -0.3813,-0.2519 -0.5644,-0.3128 -0.1371,-0.0457 -0.6992,-0.1375 -0.8078,-0.0572zm4.3825 -1.6528l-0.4513 -0.4783c-0.4141,-0.4094 -1.0223,-1.0085 -1.6092,-1.1756 0.5264,0.3551 1.5091,1.9709 1.8078,2.5966 0.1382,0.2897 0.0976,0.4283 0.0658,0.7851 -0.0512,0.5729 -0.0546,1.1227 -0.0848,1.7046l-0.7856 -1.203c-0.287,-0.4012 -0.563,-0.7655 -0.9027,-1.114 -0.3226,-0.331 -0.639,-0.6473 -1.0634,-0.9542 -0.2604,-0.1883 -0.9718,-0.6549 -1.3452,-0.6858 0.242,0.2369 0.4647,0.2793 1.0477,0.9271 0.327,0.3633 0.6136,0.7011 0.882,1.1349 1.0718,1.7321 1.4957,2.9592 2.1959,4.8201l1.3132 3.6646c0.0302,0.0453 0.014,0.0239 0.0449,0.053l-0.1851 -5.1476c0.1155,0.2152 0.2186,0.664 0.295,0.9284 0.0485,0.1672 0.2307,0.7957 0.309,0.9096l1.007 -0.2398c0.0172,-0.0049 0.0446,-0.0142 0.0623,-0.0223l0.0785 -0.0465 -1.0348 -6.081c-0.0483,-0.3585 -0.0857,-0.7015 -0.1213,-1.0675 -0.064,-0.6593 0.0266,-0.6608 0.0703,-1.0886 -0.6079,0.3463 -0.5436,2.7286 -0.5832,3.4022 -0.12,-0.1348 -0.2714,-0.5002 -0.2813,-0.7044 -0.0827,-1.707 0.1145,-3.1263 0.2169,-4.8307 0.018,-0.2998 0.0499,-0.6403 0.0772,-0.9377 0.0262,-0.2836 0.0851,-0.6533 0.0701,-0.9262l-0.3242 1.3574c-0.1432,0.7087 -0.7194,4.3376 -0.7718,4.4197zm10.1304 -2.9075c0.1037,-0.0678 0.1724,-0.3043 0.226,-0.4236 0.2754,-0.6141 0.3861,-0.5432 0.2613,-0.8881 -0.0539,-0.1494 -0.1004,-0.3571 -0.1914,-0.462 -0.0739,0.1333 -0.2958,1.5435 -0.2959,1.7736z"
            />
          </symbol>

          <symbol id="relief-swamp-2-bw" viewBox="-15 -15 40 40">
            <path
              fill="#999999"
              d="M6.7214 3.6274l0.2974 -1.246c0.0125,0.0018 0.0257,0.0026 0.0392,0.0026l0.0722 0 0.0017 0 -0.2183 0.9141c-0.0646,0.1067 -0.1305,0.2187 -0.1923,0.3293zm0.6589 -2.7597l0.0731 -0.3064 0.1137 0 -0.0725 0.3037 -0.0017 0 -0.0722 0c-0.0135,0 -0.027,0.0009 -0.0403,0.0026z"
            />
            <path
              fill="#5c5c70"
              d="M7.4207 0.8651l0.0722 0c0.126,0 0.2104,0.0787 0.1873,0.175l-0.2791 1.169c-0.0229,0.0962 -0.1448,0.175 -0.2709,0.175l-0.0722 0c-0.126,0 -0.2104,-0.0787 -0.1874,-0.175l0.2791 -1.169c0.023,-0.0962 0.1449,-0.175 0.271,-0.175z"
            />
            <rect
              fill="#999999"
              transform="matrix(-0.939683 -0 0.0671203 0.763489 5.89737 4.35244E-05)"
              width=".1137"
              height="7.4462"
            />
            <rect
              fill="#5c5c70"
              transform="matrix(-0.939683 -0 0.0671203 0.763489 6.10204 0.303724)"
              width=".5305"
              height="1.9895"
              rx=".2292"
              ry=".2292"
            />
            <path
              fill="#b3b3b3"
              d="M5.6178 4.8049c-0.1679,-0.208 -0.383,-0.5796 -0.5433,-0.8263 -0.1936,-0.298 -0.4232,-0.5766 -0.5848,-0.8489l-0.9815 0.3056c-0.5605,-0.3496 -1.0382,-0.8091 -1.7154,-1.1437 0.1982,0.2144 0.5147,0.3846 0.7658,0.5837 0.2565,0.2034 0.4549,0.3975 0.7175,0.6332l-1.7204 0.7493c-0.2861,0.1365 -0.5417,0.2743 -0.7905,0.4197l-0.6765 0.422c-0.1001,0.095 0.0047,-0.0492 -0.0888,0.1093l1.6642 -0.8211c0.5858,-0.2699 1.1939,-0.4706 1.7655,-0.7272 0.3702,0.2065 2.2853,2.1742 2.4896,2.645 0.2815,0.0964 0.5399,0.0802 0.7835,-0.0071 0.1711,-1.0885 0.5199,-2.1608 1.1254,-3.1061 0.1892,-0.2953 0.4614,-0.6218 0.6108,-0.9103l-0.1471 0.1016c-0.4466,0.3599 -1.3762,1.709 -1.4848,2.1317 0.027,-0.3821 0.4922,-1.2446 0.6983,-1.6164 0.3692,-0.6659 0.7759,-1.1199 0.9917,-1.4896 -0.4499,0.2861 -1.2108,1.2966 -1.4397,1.6572 -0.1784,0.2813 -0.4033,0.6582 -0.5347,0.9472 -0.1451,0.3189 -0.2561,0.796 -0.3948,1.077 -0.4754,-1.2016 -0.9581,-3.1053 -2.1105,-4.1177 -0.0085,-0.0074 -0.1118,-0.0899 -0.1174,-0.0941l-0.185 -0.1184c0.2319,0.3027 0.4313,0.5344 0.6578,0.8699 0.4173,0.6178 1.1832,2.5842 1.2451,3.1745zm-1.9272 -1.2197c0.0276,0.0352 1.0203,0.8641 1.4665,1.3489l0.2084 0.187c0.0085,0.0062 0.0253,0.0173 0.0382,0.0257l-1.1212 -1.7614 -0.5918 0.1998z"
            />
            <path
              fill="#999999"
              d="M6.3074 6.8936c1.5063,0 2.7274,-0.1667 2.7274,-0.3725 0,-0.0972 -0.2722,-0.1856 -0.7181,-0.2518 0.2711,0.0449 0.43,0.0993 0.43,0.158 0,0.1539 -1.0921,0.2787 -2.4393,0.2787 -1.3473,0 -2.4395,-0.1248 -2.4395,-0.2787 0,-0.0587 0.1589,-0.1131 0.4301,-0.158 -0.4459,0.0663 -0.7182,0.1548 -0.7182,0.2518 0,0.2058 1.2212,0.3725 2.7275,0.3725z"
            />
            <path
              fill="#999999"
              d="M6.3074 6.6001c0.8298,0 1.5026,-0.0919 1.5026,-0.2052 0,-0.0535 -0.15,-0.1023 -0.3956,-0.1388 0.1494,0.0247 0.2369,0.0547 0.2369,0.0871 0,0.0847 -0.6016,0.1534 -1.3439,0.1534 -0.7422,0 -1.3439,-0.0687 -1.3439,-0.1534 0,-0.0324 0.0874,-0.0623 0.2368,-0.0871 -0.2455,0.0365 -0.3955,0.0852 -0.3955,0.1388 0,0.1133 0.6727,0.2052 1.5026,0.2052z"
            />
          </symbol>

          <symbol id="relief-swamp-3-bw" viewBox="-4 -3.5 9 9">
            <rect
              fill="#999999"
              transform="matrix(-0.939683 -0 -0.0316337 0.763489 0.643293 9.91602E-06)"
              width=".0259"
              height="1.6965"
            />
            <rect
              fill="#5c5c70"
              transform="matrix(-0.939683 -0 -0.0316337 0.763489 0.680973 0.0691964)"
              width=".1209"
              height=".4533"
              rx=".0522"
              ry=".0522"
            />
            <path
              fill="#b3b3b3"
              d="M0.6587 1.102c0.1102,-0.2132 0.1717,-0.3927 0.3066,-0.6211 -0.0607,0.1599 -0.2665,0.6844 -0.2488,0.6649 0.2213,-0.2987 0.2022,-0.374 0.5309,-0.6322 -0.2144,0.2835 -0.3551,0.5968 -0.5235,0.886 -0.055,0.0555 -0.1634,0.0382 -0.2015,0.0031 -0.1446,-0.3525 -0.2572,-0.3752 -0.4702,-0.6162 0.1033,0.0385 0.3336,0.2256 0.3813,0.3151 -0.0476,-0.1539 -0.3112,-0.345 -0.4261,-0.4622 0.2831,0.0935 0.4085,0.3418 0.5708,0.5327 0.0455,-0.269 0.0508,-0.6339 0.2634,-0.8413 -0.1045,0.2155 -0.2096,0.543 -0.1829,0.7713z"
            />
            <path
              fill="#999999"
              d="M0.6214 1.5706c0.3432,0 0.6214,-0.038 0.6214,-0.0849 0,-0.0221 -0.062,-0.0423 -0.1636,-0.0574 0.0618,0.0102 0.098,0.0226 0.098,0.036 0,0.0351 -0.2488,0.0635 -0.5557,0.0635 -0.307,0 -0.5558,-0.0284 -0.5558,-0.0635 0,-0.0134 0.0362,-0.0258 0.098,-0.036 -0.1016,0.0151 -0.1636,0.0353 -0.1636,0.0574 0,0.0469 0.2782,0.0849 0.6214,0.0849z"
            />
            <path
              fill="#999999"
              d="M0.6214 1.5037c0.189,0 0.3423,-0.0209 0.3423,-0.0468 0,-0.0122 -0.0342,-0.0233 -0.0901,-0.0316 0.034,0.0056 0.054,0.0125 0.054,0.0198 0,0.0193 -0.1371,0.035 -0.3062,0.035 -0.1691,0 -0.3062,-0.0157 -0.3062,-0.035 0,-0.0074 0.0199,-0.0142 0.054,-0.0198 -0.0559,0.0083 -0.0901,0.0194 -0.0901,0.0316 0,0.0258 0.1533,0.0468 0.3423,0.0468z"
            />
          </symbol>

          <symbol id="relief-cactus-1-bw" viewBox="-50 -38 120 120">
            <ellipse fill="#999999" opacity=".5" cx="11.6624" cy="30.5346" rx="11.2558" ry="1.3184" />
            <polygon
              fill="#5c5c70"
              points="10.5474,0 10.2885,0.8968 8.9818,0.1755 9.8281,1.8655 11.2667,1.8655 12.113,0.1755 10.8062,0.8968"
            />
            <path
              fill="#b3b3b3"
              d="M18.8889 30.0026c0.3115,-0.3161 0.5627,-0.7559 0.7223,-1.2724 0.0619,0.0171 0.1258,0.0263 0.1913,0.0263 0.5329,0 0.9647,-0.5965 0.9647,-1.3324 0,-0.7359 -0.4318,-1.3326 -0.9647,-1.3326 -0.0655,0 -0.1293,0.0093 -0.1912,0.0263 -0.1171,-0.3791 -0.2837,-0.717 -0.4871,-0.9948 0.5401,-0.2953 1.1411,-0.8939 1.6308,-1.6806 0.854,-1.3719 1.0461,-2.7956 0.4288,-3.1801 -0.4598,-0.2862 -1.2385,0.0849 -1.9589,0.8593 0.0024,-0.0412 0.0037,-0.083 0.0037,-0.1254 0,-0.6869 -0.3358,-1.2436 -0.7499,-1.2436 -0.4141,0 -0.7498,0.5567 -0.7498,1.2436 0,0.6477 0.2987,1.1799 0.68,1.2382 -0.4346,0.7516 -0.6691,1.5041 -0.6797,2.0791l-0.0003 0c-0.5002,0 -0.9592,0.2657 -1.3173,0.7081 -0.0107,-0.0344 -0.0221,-0.069 -0.0344,-0.1036 -0.2936,-0.8281 -0.9175,-1.3628 -1.3935,-1.194 -0.476,0.1687 -0.6239,0.977 -0.3301,1.8053 0.2271,0.6405 0.6516,1.1054 1.0528,1.205 -0.0334,0.2219 -0.0513,0.4527 -0.0513,0.6898 0,1.0732 0.3624,2.0194 0.9136,2.5785 -0.5911,0.1126 -0.9827,0.3089 -0.9827,0.532l2.1429 0 2.1428 0c0,-0.2233 -0.3915,-0.4193 -0.9828,-0.532zm-10.9784 0.532l5.2738 0 0 -17.364 5.9327 0c1.0878,0 1.9778,-0.8898 1.9778,-1.9776l0 -3.9552c0,-1.0877 -0.89,-1.9777 -1.9778,-1.9777l0 0c-1.0877,0 -1.9776,0.89 -1.9776,1.9777l0 1.9776 -3.9551 0 0 -5.0493c0,-1.4503 -1.1867,-2.6367 -2.6369,-2.6367l0 0c-1.4504,0 -2.6369,1.1864 -2.6369,2.6367l0 14.0111 -3.9552 0 0 -1.9776c0,-1.0878 -0.89,-1.9778 -1.9776,-1.9778l0 0c-1.0878,0 -1.9777,0.89 -1.9777,1.9778l0 3.9552 0 0c0,1.0875 0.8899,1.9777 1.9777,1.9777l5.9328 0 0 8.4021zm13.1843 -19.3416l0 0z"
            />
            <path
              fill="#999999"
              d="M18.8889 30.0026c0.3115,-0.3161 0.5627,-0.7559 0.7223,-1.2724 0.0619,0.0171 0.1258,0.0263 0.1913,0.0263 0.5329,0 0.9647,-0.5965 0.9647,-1.3324 0,-0.7359 -0.4318,-1.3326 -0.9647,-1.3326 -0.0655,0 -0.1293,0.0093 -0.1912,0.0263 -0.1171,-0.3791 -0.2837,-0.717 -0.4871,-0.9948 0.5401,-0.2953 1.1411,-0.8939 1.6308,-1.6806 0.854,-1.3719 1.0461,-2.7956 0.4288,-3.1801 -0.1593,-0.0992 -0.3572,-0.1194 -0.5773,-0.0713 0.0585,0.016 0.1135,0.0395 0.1646,0.0713 0.6172,0.3845 0.4252,1.8082 -0.4289,3.1801 -0.4896,0.7867 -1.0906,1.3853 -1.6308,1.6806 0.2035,0.2778 0.3701,0.6157 0.4872,0.9948 0.0619,-0.017 0.1257,-0.0263 0.1912,-0.0263 0.5328,0 0.9647,0.5967 0.9647,1.3326 0,0.7359 -0.4319,1.3324 -0.9647,1.3324 -0.0655,0 -0.1294,-0.0092 -0.1914,-0.0263 -0.1595,0.5165 -0.4107,0.9563 -0.7222,1.2724 0.5913,0.1127 0.9828,0.3087 0.9828,0.532l0.4127 0c0,-0.2233 -0.3915,-0.4193 -0.9828,-0.532zm-16.5174 -7.9252c0.896,-0.1875 1.5746,-0.9864 1.5746,-1.9361l0 -3.9552c0,-0.9608 -0.6946,-1.7673 -1.6065,-1.9423l0 0.0115 0 1.9308 0 0.5782 0 2.8041 0.0319 0 0 2.509zm9.2062 8.4572l1.6064 0 0 -17.364 0.0002 0c0,-1.3183 0,-2.6369 0,-3.9552l-0.0002 0 0 -5.0493c0,-1.0851 -0.6643,-2.0226 -1.6064,-2.4258l0 2.4258c0,8.7895 0,17.5791 0,26.3685zm7.9425 -17.4055c0.8961,-0.1875 1.5746,-0.9864 1.5746,-1.9361l0 -3.9552c0,-0.9609 -0.6946,-1.7673 -1.6065,-1.9423l0 0.0114 0 1.9309 0 0.5782 0 2.804 0.0319 0 0 2.5091zm-0.308 7.6085c-0.0718,-0.5627 -0.373,-0.985 -0.7335,-0.985 -0.0716,0 -0.1408,0.0166 -0.2064,0.0477 0.3138,0.1486 0.5436,0.6278 0.5436,1.1959 0,0.0424 -0.0013,0.0842 -0.0038,0.1254 0.1322,-0.1422 0.2662,-0.2706 0.4001,-0.384zm-2.916 3.9775c-0.3167,-0.7104 -0.8766,-1.1457 -1.3125,-0.9911l-0.0145 0.0057c0.3836,0.1275 0.779,0.5782 0.9953,1.1883 0.0122,0.0346 0.0237,0.0692 0.0344,0.1036 0.0927,-0.1144 0.192,-0.2172 0.2973,-0.3065z"
            />
          </symbol>

          <symbol id="relief-cactus-2-bw" viewBox="-49 -41 120 120">
            <polygon
              fill="#5c5c70"
              points="3.9483,14.2784 3.6984,15.1439 2.4374,14.4478 3.2541,16.0787 4.6425,16.0787 5.4592,14.4478 4.1982,15.1439"
            />
            <ellipse fill="#BDBFC1" cx="10.5348" cy="27.9924" rx="10.5348" ry="1.2724" />
            <path
              fill="#b3b3b3"
              d="M9.1307 27.9925l5.0895 0 0 -12.5588 5.7257 0c1.0497,0 1.9085,-0.8588 1.9085,-1.9085l0 -3.8172c0,-1.0497 -0.8589,-1.9085 -1.9085,-1.9085l0 0c-1.0497,0 -1.9086,0.8589 -1.9086,1.9085l0 1.9086 -3.8171 0 0 -9.0718c0,-1.3996 -1.1452,-2.5448 -2.5448,-2.5448l0 0c-1.3996,0 -2.5447,1.1452 -2.5447,2.5448 0,8.4826 0,16.9651 0,25.4477zm12.7238 -14.4674l0 0z"
            />
            <path
              fill="#b3b3b3"
              d="M6.8427 23.5745c0.5187,0.1819 1.2323,-0.5066 1.5937,-1.5377 0.3614,-1.031 0.2339,-2.0143 -0.2848,-2.1961 -0.5187,-0.1819 -1.2322,0.5066 -1.5937,1.5376 -0.0555,0.1582 -0.0994,0.3153 -0.1322,0.4685 -0.204,-0.4516 -0.4675,-0.7946 -0.7661,-0.98 0.3423,-0.5575 0.5494,-1.2841 0.5494,-2.0787 0,-1.7568 -1.0122,-3.1809 -2.2607,-3.1809 -1.2487,0 -2.2608,1.4241 -2.2608,3.1809 0,1.6948 0.942,3.0799 2.1296,3.1755 -0.243,0.5892 -0.3889,1.3428 -0.3889,2.1642 0,1.3665 0.4035,2.5453 0.9868,3.0916 -0.7731,0.0885 -1.3212,0.3101 -1.3212,0.5695l4.1359 0c0,-0.2624 -0.5609,-0.4862 -1.3481,-0.5725 0.5814,-0.5476 0.9836,-1.7246 0.9836,-3.0886 0,-0.1884 -0.0078,-0.3732 -0.0226,-0.5533l0.0001 0z"
            />
            <path
              fill="#999999"
              d="M5.4882 20.7795c0.2721,-0.5451 0.4349,-1.2376 0.4349,-1.9914 0,-1.7568 -0.8841,-3.1809 -1.9747,-3.1809 -0.666,0 -1.2058,1.4241 -1.2058,3.1809 0,1.6442 0.4729,2.997 1.0795,3.1636l0.0165 -0.0389c-0.2703,-0.2796 -0.4747,-1.5721 -0.4747,-3.1247 0,-1.7568 0.2617,-3.1809 0.5846,-3.1809 0.949,0 1.7183,1.4241 1.7183,3.1809 0,0.73 -0.1329,1.4025 -0.3563,1.9394 0.0602,0.0113 0.1195,0.0288 0.1778,0.0521zm-0.3414 6.7643c0.829,-0.0001 1.501,-1.5294 1.501,-3.416 0,-0.2568 -0.0125,-0.5069 -0.0361,-0.7475 0.0607,0.0945 0.1379,0.1615 0.2312,0.1942 0.134,0.0471 0.5357,-0.7507 0.8972,-1.7818 0.3615,-1.031 0.5458,-1.9049 0.4117,-1.952 -0.3943,-0.1382 -1.007,0.5856 -1.3684,1.6166 -0.1717,0.49 -0.2558,0.9611 -0.2545,1.3355 0.0303,0.1617 0.055,0.3297 0.0741,0.5031 0.0525,0.1431 0.1326,0.241 0.24,0.2787 0.2765,0.097 0.7938,-0.6602 1.1553,-1.6913 0.3615,-1.0311 0.4303,-1.9455 0.1536,-2.0425 -0.4531,-0.1588 -1.1134,0.5483 -1.4748,1.5793 -0.1272,0.3627 -0.2004,0.7172 -0.2221,1.0313 -0.2575,-1.0382 -0.7467,-1.7393 -1.308,-1.7393 -0.5062,0 -0.9165,1.5293 -0.9165,3.4159 0,1.8866 0.4103,3.416 0.9165,3.416zm0 -6.8319c-0.2454,0 -0.4444,1.5293 -0.4444,3.4159 0,1.8866 0.1989,3.416 0.4444,3.416 0.7213,-0.0001 1.3062,-1.5294 1.3062,-3.416 0,-1.8865 -0.5848,-3.4159 -1.3062,-3.4159zm0 0c-0.8291,0 -1.5012,1.5293 -1.5011,3.4159 0,1.8866 0.672,3.416 1.5011,3.416 0.2454,-0.0001 0.4442,-1.5294 0.4442,-3.416 0,-1.8865 -0.1988,-3.4159 -0.4442,-3.4159 -0.7215,0 -1.3062,1.5293 -1.3062,3.4159 0,1.8866 0.5848,3.416 1.3062,3.416 0.5061,-0.0001 0.9164,-1.5294 0.9164,-3.416 0,-1.8865 -0.4103,-3.4159 -0.9164,-3.4159zm1.696 2.8626c0.453,0.1588 1.1133,-0.5482 1.4748,-1.5794 0.3615,-1.031 0.2871,-1.9956 -0.1659,-2.1545 -0.2767,-0.097 -0.794,0.6602 -1.1555,1.6912 -0.3615,1.0312 -0.4302,1.9456 -0.1535,2.0426zm1.3089 -3.7338c-0.1341,-0.047 -0.5359,0.7507 -0.8974,1.7817 -0.3614,1.0311 -0.5458,1.9051 -0.4115,1.9521 0.3942,0.1382 1.0069,-0.5856 1.3683,-1.6167 0.3615,-1.031 0.3349,-1.9789 -0.0593,-2.1171zm-4.2034 -4.2335c-1.0907,0 -1.9748,1.4241 -1.9748,3.1809 0,1.6862 0.8144,3.0656 1.8442,3.1738l0.0008 -0.0019c-0.8884,-0.1229 -1.5886,-1.496 -1.5886,-3.172 0,-1.7568 0.7693,-3.1809 1.7184,-3.1809 0.3228,0 0.5845,1.4241 0.5845,3.1809 0,0.9114 -0.0705,1.7331 -0.1833,2.313 0.1684,-0.1756 0.3532,-0.2971 0.5486,-0.3534 0.1603,-0.5401 0.2558,-1.2204 0.2558,-1.9596 0,-1.7568 -0.5398,-3.1809 -1.2057,-3.1809z"
            />
            <path
              fill="#999999"
              d="M12.5713 27.9925l1.649 0c0,-11.8861 0,-14.658 0,-25.4477 0,-1.0847 -0.688,-2.0165 -1.649,-2.381l0 27.6858 0 0.1428zm8.1168 -12.7099c0.6837,-0.291 1.1664,-0.9707 1.1664,-1.7575l0 -3.8172c0,-0.7868 -0.4827,-1.4665 -1.1664,-1.7575l0 7.3322zm1.1664 -1.7575l0 0z"
            />
          </symbol>

          <symbol id="relief-cactus-3-bw" viewBox="-50 -41 120 120">
            <ellipse fill="#999999" opacity=".5" cx="11.8434" cy="27.4564" rx="10.1211" ry="1.1855" />
            <path
              fill="#b3b3b3"
              d="M22.2067 13.2778l-0.7113 0 -1.1706 0 0 4.5937c0,0.978 -0.8002,1.7782 -1.7783,1.7782l-5.3348 0 0 7.8067 -4.742 0 0 -7.5551 -3.6988 0c-0.978,0 -1.7783,-0.8002 -1.7783,-1.7783l0 0 0 -2.7652 -1.57 0 -0.7113 0c-0.0061,0 -0.0122,0 -0.0183,-0.0002 -0.0061,-0.0001 -0.0121,-0.0004 -0.0182,-0.0007 -0.006,-0.0003 -0.012,-0.0007 -0.018,-0.0011 -0.006,-0.0005 -0.012,-0.001 -0.018,-0.0017 -0.0059,-0.0006 -0.0118,-0.0012 -0.0178,-0.002 -0.0059,-0.0008 -0.0118,-0.0016 -0.0176,-0.0025 -0.0059,-0.0009 -0.0118,-0.0019 -0.0176,-0.0029l0 0c-0.0058,-0.0011 -0.0116,-0.0022 -0.0174,-0.0034 -0.0058,-0.0011 -0.0115,-0.0024 -0.0172,-0.0038l0 0c-0.0057,-0.0013 -0.0114,-0.0027 -0.0171,-0.0042l0 0c-0.0057,-0.0014 -0.0113,-0.0029 -0.0169,-0.0046l-0.0001 0c-0.0056,-0.0015 -0.0111,-0.0033 -0.0167,-0.005l0 0c-0.0056,-0.0017 -0.0111,-0.0035 -0.0166,-0.0054l-0.0164 -0.0058 0 0 -0.0162 -0.0062 -0.0161 -0.0066c-0.0053,-0.0022 -0.0106,-0.0046 -0.0158,-0.0069l0 0c-0.0053,-0.0024 -0.0105,-0.0049 -0.0157,-0.0074l-0.0154 -0.0077 -0.0152 -0.008c-0.0051,-0.0028 -0.0101,-0.0056 -0.015,-0.0085l-0.0148 -0.0087 0 0c-0.0049,-0.003 -0.0097,-0.006 -0.0146,-0.0091 -0.0048,-0.0031 -0.0095,-0.0063 -0.0143,-0.0095 -0.0047,-0.0032 -0.0094,-0.0064 -0.014,-0.0097l-0.0001 0c-0.0046,-0.0034 -0.0092,-0.0067 -0.0138,-0.0101l-0.0135 -0.0105 -0.0001 0c-0.0044,-0.0035 -0.0089,-0.0071 -0.0133,-0.0107l-0.013 -0.0111 0 0c-0.0043,-0.0037 -0.0086,-0.0075 -0.0128,-0.0113l-0.0125 -0.0117 0 0 -0.0122 -0.0119 -0.0001 0 -0.0119 -0.0122c-0.0039,-0.0041 -0.0078,-0.0083 -0.0116,-0.0125l-0.0001 0 -0.0113 -0.0128 -0.011 -0.0131 -0.0108 -0.0133c-0.0035,-0.0045 -0.007,-0.009 -0.0104,-0.0136l-0.0101 -0.0138c-0.0033,-0.0047 -0.0066,-0.0093 -0.0098,-0.0141 -0.0032,-0.0047 -0.0064,-0.0095 -0.0094,-0.0143l-0.0091 -0.0145c-0.003,-0.0049 -0.0059,-0.0099 -0.0088,-0.0148l-0.0084 -0.015c-0.0028,-0.0051 -0.0054,-0.0101 -0.0081,-0.0153l-0.0077 -0.0154c-0.0025,-0.0052 -0.0049,-0.0104 -0.0073,-0.0156 -0.0024,-0.0053 -0.0047,-0.0106 -0.007,-0.0159 -0.0023,-0.0053 -0.0044,-0.0106 -0.0065,-0.016 -0.0022,-0.0054 -0.0043,-0.0108 -0.0063,-0.0162l-0.0058 -0.0165c-0.0018,-0.0055 -0.0036,-0.011 -0.0054,-0.0165 -0.0017,-0.0056 -0.0034,-0.0112 -0.005,-0.0168l-0.0046 -0.0169c-0.0015,-0.0057 -0.0029,-0.0114 -0.0042,-0.0171 -0.0013,-0.0057 -0.0026,-0.0115 -0.0038,-0.0173 -0.0012,-0.0058 -0.0023,-0.0115 -0.0033,-0.0174 -0.0011,-0.0058 -0.0021,-0.0116 -0.003,-0.0175 -0.0009,-0.0059 -0.0017,-0.0118 -0.0025,-0.0177 -0.0007,-0.0059 -0.0014,-0.0118 -0.002,-0.0178 -0.0006,-0.006 -0.0012,-0.012 -0.0016,-0.0179 -0.0005,-0.006 -0.0009,-0.012 -0.0012,-0.0181 -0.0003,-0.006 -0.0005,-0.0121 -0.0007,-0.0182 -0.0001,-0.006 -0.0002,-0.0121 -0.0002,-0.0183l0 -0.7113 0 -1.9228c0,-0.3912 0.3201,-0.7113 0.7113,-0.7113l0 0c0.3912,0 0.7113,0.3201 0.7113,0.7113l0 1.9228 1.57 0 0 -4.0946c0,-0.978 0.8003,-1.7783 1.7783,-1.7783l0 0c0.978,0 1.7783,0.8003 1.7783,1.7783l0 6.5042 1.9205 0 0 -12.5985c0,-1.3041 1.0669,-2.3711 2.371,-2.3711l0 0c1.3041,0 2.371,1.067 2.371,2.3711l0 2.5355 1.9971 0 0 -1.9229c0,-0.3912 0.3202,-0.7113 0.7114,-0.7113l0 0c0.3912,0 0.7113,0.3201 0.7113,0.7113l0 1.9229 0 0.7113c0,0.0061 -0.0001,0.0122 -0.0003,0.0182 -0.0001,0.0061 -0.0003,0.0122 -0.0006,0.0182 -0.0004,0.0061 -0.0007,0.0121 -0.0012,0.0181 -0.0005,0.006 -0.001,0.0119 -0.0016,0.0179 -0.0006,0.006 -0.0013,0.0119 -0.0021,0.0178 -0.0007,0.0059 -0.0016,0.0118 -0.0025,0.0177 -0.0009,0.0059 -0.0018,0.0117 -0.0029,0.0176 -0.001,0.0058 -0.0021,0.0116 -0.0033,0.0173 -0.0012,0.0058 -0.0025,0.0116 -0.0038,0.0173 -0.0014,0.0057 -0.0028,0.0114 -0.0042,0.0171l-0.0046 0.0169c-0.0016,0.0056 -0.0033,0.0112 -0.0051,0.0168 -0.0017,0.0055 -0.0035,0.0111 -0.0054,0.0166l-0.0058 0.0164c-0.002,0.0054 -0.0041,0.0108 -0.0062,0.0162 -0.0021,0.0054 -0.0043,0.0107 -0.0065,0.016 -0.0023,0.0053 -0.0046,0.0107 -0.007,0.0159 -0.0024,0.0052 -0.0049,0.0104 -0.0073,0.0156l-0.0077 0.0155c-0.0027,0.0051 -0.0054,0.0102 -0.0081,0.0152l-0.0084 0.015c-0.0029,0.0049 -0.0058,0.0099 -0.0088,0.0148l-0.0091 0.0145c-0.0031,0.0048 -0.0062,0.0096 -0.0094,0.0143 -0.0032,0.0048 -0.0065,0.0095 -0.0098,0.0141l-0.0101 0.0138c-0.0034,0.0046 -0.0069,0.0091 -0.0104,0.0136l-0.0108 0.0133 -0.011 0.0131 -0.0114 0.0128 0 0c-0.0038,0.0042 -0.0077,0.0084 -0.0116,0.0125 -0.004,0.0041 -0.008,0.0082 -0.012,0.0122l-0.0122 0.012 0 0 -0.0125 0.0116c-0.0042,0.0039 -0.0085,0.0076 -0.0128,0.0114l0 0 -0.0131 0.011c-0.0044,0.0036 -0.0088,0.0072 -0.0133,0.0107l0 0 -0.0135 0.0105c-0.0046,0.0034 -0.0092,0.0068 -0.0139,0.0101l0 0c-0.0046,0.0033 -0.0093,0.0065 -0.014,0.0097 -0.0048,0.0032 -0.0096,0.0064 -0.0144,0.0095 -0.0048,0.0031 -0.0096,0.0061 -0.0145,0.0091l0 0 -0.0148 0.0088c-0.005,0.0028 -0.01,0.0056 -0.015,0.0084l-0.0152 0.008 -0.0155 0.0077c-0.0052,0.0026 -0.0103,0.005 -0.0156,0.0074l0 0 -0.0159 0.0069 -0.016 0.0066 -0.0162 0.0062 0 0 -0.0164 0.0058c-0.0055,0.0019 -0.011,0.0037 -0.0166,0.0054l0 0c-0.0056,0.0018 -0.0112,0.0035 -0.0168,0.0051l0 0c-0.0056,0.0016 -0.0112,0.0031 -0.0169,0.0046l0 0c-0.0057,0.0014 -0.0114,0.0028 -0.0171,0.0042l0 0c-0.0057,0.0013 -0.0115,0.0026 -0.0173,0.0038 -0.0057,0.0011 -0.0115,0.0023 -0.0173,0.0033l-0.0001 0c-0.0058,0.001 -0.0116,0.002 -0.0175,0.0029 -0.0059,0.0009 -0.0118,0.0018 -0.0177,0.0025 -0.0059,0.0008 -0.0118,0.0015 -0.0178,0.0021 -0.0059,0.0006 -0.0119,0.0011 -0.0179,0.0016 -0.006,0.0004 -0.012,0.0008 -0.0181,0.0011 -0.006,0.0003 -0.0121,0.0006 -0.0181,0.0007 -0.0061,0.0002 -0.0122,0.0003 -0.0183,0.0003l-0.7114 0 -1.9971 0 0 8.3888 3.5566 0 0 -1.6774 -1.9035 0c-0.3912,0 -0.7113,-0.32 -0.7113,-0.7113l0 -0.0226 0 -0.6887 0 -1.9454c0,-0.3912 0.3201,-0.7113 0.7113,-0.7113l0 0c0.3912,0 0.7114,0.3201 0.7114,0.7113l0 1.9454 1.1921 0 0 -1.8317c0,-0.978 0.8002,-1.7783 1.7782,-1.7783l0 0c0.9781,0 1.7783,0.8002 1.7783,1.7783l0 0.6936 1.1706 0 0 -1.9228c0,-0.3912 0.3201,-0.7113 0.7113,-0.7113l0 0c0.3912,0 0.7113,0.3201 0.7113,0.7113l0 1.9228 0 0.7113c0,0.0061 -0.0001,0.0123 -0.0002,0.0183 -0.0002,0.0061 -0.0004,0.0122 -0.0007,0.0182 -0.0003,0.0061 -0.0007,0.0121 -0.0012,0.0181 -0.0005,0.006 -0.001,0.012 -0.0016,0.0179 -0.0006,0.006 -0.0013,0.0119 -0.002,0.0178 -0.0008,0.0059 -0.0016,0.0118 -0.0025,0.0177 -0.0009,0.0059 -0.0019,0.0117 -0.003,0.0175 -0.001,0.0059 -0.0021,0.0116 -0.0033,0.0174 -0.0012,0.0058 -0.0025,0.0115 -0.0038,0.0173 -0.0013,0.0057 -0.0027,0.0114 -0.0042,0.0171 -0.0015,0.0056 -0.003,0.0113 -0.0046,0.0169l-0.005 0.0168c-0.0018,0.0055 -0.0036,0.011 -0.0054,0.0165 -0.0019,0.0056 -0.0039,0.011 -0.0058,0.0165 -0.002,0.0054 -0.0041,0.0108 -0.0063,0.0162l-0.0065 0.016 -0.007 0.0159c-0.0024,0.0052 -0.0048,0.0104 -0.0073,0.0156l-0.0077 0.0154 -0.0081 0.0153c-0.0027,0.005 -0.0055,0.01 -0.0084,0.015 -0.0029,0.0049 -0.0058,0.0099 -0.0088,0.0148 -0.0029,0.0049 -0.006,0.0097 -0.0091,0.0145 -0.003,0.0048 -0.0062,0.0096 -0.0094,0.0143 -0.0032,0.0048 -0.0065,0.0095 -0.0098,0.0141l-0.0101 0.0138c-0.0034,0.0046 -0.0069,0.0091 -0.0104,0.0136l-0.0108 0.0133c-0.0036,0.0044 -0.0073,0.0088 -0.011,0.0131 -0.0037,0.0043 -0.0075,0.0085 -0.0113,0.0128l-0.0001 0 -0.0116 0.0125 -0.0119 0.0122 -0.0001 0 -0.0122 0.0119 0 0 -0.0125 0.0117 -0.0128 0.0113 0 0c-0.0043,0.0038 -0.0086,0.0075 -0.013,0.0111l-0.0133 0.0107 -0.0001 0c-0.0044,0.0036 -0.0089,0.0071 -0.0135,0.0105 -0.0046,0.0034 -0.0092,0.0067 -0.0138,0.0101l-0.0001 0c-0.0046,0.0033 -0.0093,0.0065 -0.014,0.0097 -0.0048,0.0032 -0.0095,0.0064 -0.0143,0.0095 -0.0049,0.0031 -0.0097,0.0061 -0.0146,0.0091l0 0c-0.0049,0.003 -0.0098,0.0059 -0.0148,0.0087l-0.015 0.0085c-0.005,0.0027 -0.0101,0.0054 -0.0152,0.008l-0.0154 0.0077c-0.0052,0.0025 -0.0104,0.005 -0.0157,0.0074l0 0c-0.0053,0.0024 -0.0105,0.0047 -0.0158,0.0069 -0.0053,0.0023 -0.0107,0.0045 -0.0161,0.0066 -0.0053,0.0021 -0.0107,0.0042 -0.0162,0.0062l0 0 -0.0164 0.0058c-0.0055,0.0019 -0.011,0.0037 -0.0166,0.0054l0 0c-0.0056,0.0018 -0.0111,0.0034 -0.0167,0.0051l-0.0001 0 -0.0169 0.0046 0 0c-0.0057,0.0014 -0.0114,0.0028 -0.0171,0.0041l0 0c-0.0057,0.0014 -0.0114,0.0027 -0.0172,0.0038 -0.0058,0.0012 -0.0116,0.0023 -0.0174,0.0034l0 0c-0.0059,0.0011 -0.0117,0.002 -0.0176,0.0029 -0.0058,0.0009 -0.0117,0.0018 -0.0176,0.0025 -0.0059,0.0008 -0.0119,0.0014 -0.0178,0.0021 -0.006,0.0006 -0.012,0.0011 -0.018,0.0016 -0.006,0.0004 -0.012,0.0008 -0.018,0.0011 -0.0061,0.0003 -0.0122,0.0005 -0.0182,0.0007 -0.0061,0.0002 -0.0122,0.0003 -0.0183,0.0003zm-1.8819 4.5937l0 0z"
            />
            <polygon
              fill="#5c5c70"
              points="10.8407,0 10.6079,0.8065 9.4329,0.1579 10.1939,1.6775 11.4875,1.6775 12.2485,0.1579 11.0735,0.8065"
            />
            <path
              fill="#999999"
              d="M20.3248 13.2778l0 1.8688 0 2.7249c0,0.8014 -0.5374,1.4832 -1.2696,1.7034l0 -3.8992 0 -0.5291 0 -5.6886c0.7322,0.2202 1.2696,0.902 1.2696,1.7035l0 0.6936 0 1.4227zm-7.1131 6.3719l0 2.7286 0 5.0781 -1.5649 0 0 -25.9392c0.9104,0.3318 1.5649,1.2077 1.5649,2.2291l0 2.5355 0 1.4226 0 0.3866 0 6.9671 0 1.0351 0 3.5565zm2.7126 -16.0021c0.3893,0.0022 0.7072,0.3215 0.7072,0.7113l0 1.9229 0 0.7113c0,0.0061 -0.0001,0.0122 -0.0003,0.0182 -0.0001,0.0061 -0.0003,0.0122 -0.0006,0.0182 -0.0004,0.0061 -0.0007,0.0121 -0.0012,0.0181 -0.0005,0.006 -0.001,0.0119 -0.0016,0.0179 -0.0006,0.006 -0.0013,0.0119 -0.0021,0.0178 -0.0007,0.0059 -0.0016,0.0118 -0.0025,0.0177 -0.0009,0.0059 -0.0018,0.0117 -0.0029,0.0176 -0.001,0.0058 -0.0021,0.0116 -0.0033,0.0173 -0.0012,0.0058 -0.0025,0.0116 -0.0038,0.0173 -0.0014,0.0057 -0.0028,0.0114 -0.0042,0.0171l-0.0046 0.0169c-0.0016,0.0056 -0.0033,0.0112 -0.0051,0.0168 -0.0017,0.0055 -0.0035,0.0111 -0.0054,0.0166l-0.0058 0.0164c-0.002,0.0054 -0.0041,0.0108 -0.0062,0.0162 -0.0021,0.0054 -0.0043,0.0107 -0.0065,0.016 -0.0023,0.0053 -0.0046,0.0107 -0.007,0.0159 -0.0024,0.0052 -0.0049,0.0104 -0.0073,0.0156l-0.0077 0.0155c-0.0027,0.0051 -0.0054,0.0102 -0.0081,0.0152l-0.0084 0.015c-0.0029,0.0049 -0.0058,0.0099 -0.0088,0.0148l-0.0091 0.0145c-0.0031,0.0048 -0.0062,0.0096 -0.0094,0.0143 -0.0032,0.0048 -0.0065,0.0095 -0.0098,0.0141l-0.0101 0.0138c-0.0034,0.0046 -0.0069,0.0091 -0.0104,0.0136l-0.0108 0.0133 -0.011 0.0131 -0.0114 0.0128 0 0c-0.0038,0.0042 -0.0077,0.0084 -0.0116,0.0125 -0.004,0.0041 -0.008,0.0082 -0.012,0.0122l-0.0122 0.012 0 0 -0.0125 0.0116c-0.0042,0.0039 -0.0085,0.0076 -0.0128,0.0114l0 0 -0.0131 0.011c-0.0044,0.0036 -0.0088,0.0072 -0.0133,0.0107l0 0 -0.0135 0.0105c-0.0046,0.0034 -0.0092,0.0068 -0.0139,0.0101l0 0c-0.0046,0.0033 -0.0093,0.0065 -0.014,0.0097 -0.0048,0.0032 -0.0096,0.0064 -0.0144,0.0095 -0.0048,0.0031 -0.0096,0.0061 -0.0145,0.0091l0 0 -0.0148 0.0088c-0.005,0.0028 -0.01,0.0056 -0.015,0.0084l-0.0152 0.008 -0.0155 0.0077c-0.0052,0.0026 -0.0103,0.005 -0.0156,0.0074l0 0 -0.0159 0.0069 -0.016 0.0066 -0.0162 0.0062 0 0 -0.0164 0.0058c-0.0055,0.0019 -0.011,0.0037 -0.0166,0.0054l0 0c-0.0056,0.0018 -0.0112,0.0035 -0.0168,0.0051l0 0c-0.0056,0.0016 -0.0112,0.0031 -0.0169,0.0046l0 0c-0.0057,0.0014 -0.0114,0.0028 -0.0171,0.0042l0 0c-0.0057,0.0013 -0.0115,0.0026 -0.0173,0.0038 -0.0057,0.0011 -0.0115,0.0023 -0.0173,0.0033l-0.0001 0c-0.0058,0.001 -0.0116,0.002 -0.0175,0.0029 -0.0059,0.0009 -0.0118,0.0018 -0.0177,0.0025 -0.0059,0.0008 -0.0118,0.0015 -0.0178,0.0021 -0.0059,0.0006 -0.0119,0.0011 -0.0179,0.0016 -0.006,0.0004 -0.012,0.0008 -0.0181,0.0011 -0.006,0.0003 -0.0121,0.0006 -0.0181,0.0007l-0.0142 0.0003 0 -4.0568zm-0.3481 10.7682l-0.7114 0 0 -4.0793 0 0c0.3912,0 0.7114,0.3201 0.7114,0.7113l0 1.9454 0 1.4226zm6.8745 -5.1515c0.272,0.1001 0.4673,0.3624 0.4673,0.668l0 1.9228 0 0.7113c0,0.0061 -0.0001,0.0123 -0.0002,0.0183 -0.0002,0.0061 -0.0004,0.0122 -0.0007,0.0182 -0.0003,0.0061 -0.0007,0.0121 -0.0012,0.0181 -0.0005,0.006 -0.001,0.012 -0.0016,0.0179 -0.0006,0.006 -0.0013,0.0119 -0.002,0.0178 -0.0008,0.0059 -0.0016,0.0118 -0.0025,0.0177 -0.0009,0.0059 -0.0019,0.0117 -0.003,0.0175 -0.001,0.0059 -0.0021,0.0116 -0.0033,0.0174 -0.0012,0.0058 -0.0025,0.0115 -0.0038,0.0173 -0.0013,0.0057 -0.0027,0.0114 -0.0042,0.0171 -0.0015,0.0056 -0.003,0.0113 -0.0046,0.0169l-0.005 0.0168c-0.0018,0.0055 -0.0036,0.011 -0.0054,0.0165 -0.0019,0.0056 -0.0039,0.011 -0.0058,0.0165 -0.002,0.0054 -0.0041,0.0108 -0.0063,0.0162l-0.0065 0.016 -0.007 0.0159c-0.0024,0.0052 -0.0048,0.0104 -0.0073,0.0156l-0.0077 0.0154 -0.0081 0.0153c-0.0027,0.005 -0.0055,0.01 -0.0084,0.015 -0.0029,0.0049 -0.0058,0.0099 -0.0088,0.0148 -0.0029,0.0049 -0.006,0.0097 -0.0091,0.0145 -0.003,0.0048 -0.0062,0.0096 -0.0094,0.0143 -0.0032,0.0048 -0.0065,0.0095 -0.0098,0.0141l-0.0101 0.0138c-0.0034,0.0046 -0.0069,0.0091 -0.0104,0.0136l-0.0108 0.0133c-0.0036,0.0044 -0.0073,0.0088 -0.011,0.0131 -0.0037,0.0043 -0.0075,0.0085 -0.0113,0.0128l-0.0001 0 -0.0116 0.0125 -0.0119 0.0122 -0.0001 0 -0.0122 0.0119 0 0 -0.0125 0.0117 -0.0128 0.0113 0 0c-0.0043,0.0038 -0.0086,0.0075 -0.013,0.0111l-0.0133 0.0107 -0.0001 0c-0.0044,0.0036 -0.0089,0.0071 -0.0135,0.0105 -0.0046,0.0034 -0.0092,0.0067 -0.0138,0.0101l-0.0001 0c-0.0046,0.0033 -0.0093,0.0065 -0.014,0.0097 -0.0048,0.0032 -0.0095,0.0064 -0.0143,0.0095 -0.0049,0.0031 -0.0097,0.0061 -0.0146,0.0091l0 0c-0.0049,0.003 -0.0098,0.0059 -0.0148,0.0087l-0.015 0.0085c-0.005,0.0027 -0.0101,0.0054 -0.0152,0.008l-0.0154 0.0077c-0.0052,0.0025 -0.0104,0.005 -0.0157,0.0074l0 0c-0.0053,0.0024 -0.0105,0.0047 -0.0158,0.0069 -0.0053,0.0023 -0.0107,0.0045 -0.0161,0.0066l-0.0161 0.0062 0 -3.9701zm-15.9015 10.637l-0.9878 0 0 -11.6523c0.5842,0.2923 0.9878,0.8971 0.9878,1.5916l0 3.7623 0 2.7419 0 3.5565zm-5.1266 -4.5435l-0.3812 0 0 -3.9749c0.2262,0.1194 0.3812,0.3573 0.3812,0.6295l0 1.2818 0 0.641 0 1.4226zm18.9022 2.5137l0 0z"
            />
          </symbol>

          <symbol id="relief-deadTree-1-bw" viewBox="-10 -9 30 30">
            <ellipse fill="#999999" opacity=".5" cx="6.0917" cy="7.5182" rx="2.8932" ry=".3408" />
            <path
              fill="#b3b3b3"
              d="M3.5153 1.3458c0.2543,-0.0013 0.7916,0.129 0.6583,0.3396 -0.0857,0.1354 -0.6435,1.074 -0.6404,1.114 0.0042,0.0531 0.341,0.6425 0.3357,1.0671 -0.005,0.4 -0.4393,0.5902 -0.7445,0.6156l-0.1526 -0.7164 -0.8522 -0.3727c0.1354,-0.828 0.3493,-0.4466 -0.2112,-1.4572 -0.1448,-0.261 0.2666,-0.5992 0.4246,-0.6946l-0.2495 0.0682 0.2497 -0.3491c-0.0387,0.0257 -0.0763,0.0603 -0.12,0.0839l0.0471 -0.2236 -0.4834 0.8931c-0.0975,0.1868 -0.1224,0.1338 0.005,0.2843 0.4911,0.5805 0.3652,0.7545 0.1577,1.3533l-0.57 -0.258c-0.0654,-0.3528 -0.0606,-0.8702 -0.2831,-1.0414 -0.1952,-0.1502 -0.2072,-0.1461 -0.1229,-0.535 0.0474,-0.2188 0.2619,-0.2628 0.4506,-0.4999 -0.2195,0.1614 -0.4687,0.2928 -0.4917,0.4311 -0.126,0.7587 -0.2153,0.3823 -0.9225,0.3141l0.5598 0.2152 -0.2753 0.1191c0.4778,-0.0459 1.0244,-0.3067 0.9364,1.1042l1.422 0.566c0.2198,0.0889 0.16,0.0419 0.2147,0.2873 0.0473,0.2124 0.2648,1.1447 0.2621,1.2321 0.0348,0.1295 1.1372,1.5251 1.0567,1.6851l-0.6487 0.534c0.2003,0.0023 0.3874,0.0799 0.5356,0.2115 0.321,-0.1964 0.6523,-0.1739 0.933,0.0841 0.0279,-0.0963 -0.0348,-0.2065 0.1893,-0.1382 -0.0511,-0.1825 0.0636,-0.3019 0.3652,-0.2167l-0.5587 -0.6647c-0.335,-0.4654 0.0657,-0.5361 0.3232,-0.8874 0.3199,-0.4366 0.4947,-1.3297 0.9872,-1.2478 0.166,0.0276 0.544,0.3328 0.6681,0.3902 -0.0526,-0.0727 -0.3251,-0.2763 -0.3757,-0.3471 1.1234,-0.3172 0.6664,-0.9833 1.0576,-1.1403 0.3553,-0.1426 0.4178,-0.1125 0.7358,0.0071 -0.0447,-0.0408 -0.1272,-0.083 -0.1599,-0.1386 0.0608,-0.1125 0.1637,-0.2309 0.2168,-0.3457 -0.4288,0.3352 0.1565,0.1887 -0.9798,0.3409 -0.076,0.1367 -0.2062,0.5445 -0.2709,0.7293 -0.0474,0.1354 -0.4617,0.3359 -0.5939,0.4082l-0.5365 -0.0954 0.4903 -0.4019c-0.7228,0.343 -0.6671,0.5239 -1.2151,1.3647 -0.1089,0.1629 -0.0654,0.1629 -0.2597,0.2666 -0.1824,0.0973 -0.5098,0.2844 -0.6886,0.3561 -0.0734,-0.0726 -0.3395,-0.5036 -0.3932,-0.5868 -0.1102,-0.1707 -0.1243,-0.1282 -0.0443,-0.3189 0.4751,-1.1814 0.3432,-0.7881 0.0867,-1.6479 -0.1573,-0.5272 0.5708,0.047 0.89,0.1609 -0.1139,-0.1055 -0.9469,-0.6786 -0.9647,-0.7257 -0.0096,-0.0255 0.0803,-0.5765 0.4293,-0.6942 0.2215,-0.0746 0.7565,-0.1045 0.9396,0.0794 0.0928,0.0932 0.1646,0.2261 0.2324,0.3401l-0.1008 -0.3823c0.5352,-0.1142 0.5229,-0.3132 1.2351,-0.1707 0.3041,0.0609 0.9743,0.2752 1.2277,0.2822l-0.1733 -0.1642 0.2597 -0.0104 -0.2894 -0.0697 0.3033 -0.1079c-0.3524,-0.0086 -0.4157,0.1266 -0.8613,0.037 -0.1587,-0.0319 -0.7112,-0.1209 -0.823,-0.1706l0.8073 -0.3358c0.0347,-0.1549 -0.0285,-0.6678 0.0729,-0.7688 0.104,-0.1035 0.4286,0.0056 0.7823,-0.0293 -0.6035,-0.1089 -0.758,-0.0385 -0.201,-0.6082 0.0264,-0.027 0.106,-0.1209 0.1223,-0.1483l-0.7942 0.7068c-0.1806,0.835 0.0273,0.6738 -0.5709,0.9316 -0.3515,0.1515 -0.684,0.3171 -1.0625,0.4386 -0.2353,0.0756 -1.005,-0.0716 -1.2564,-0.1546 0.1802,-0.3685 0.3858,-0.7438 0.5712,-1.1089 0.0411,-0.0808 0.394,-0.3205 0.7318,-0.2844l0.1679 0.0147c-0.041,-0.0393 -0.097,-0.0652 -0.1266,-0.1087l0.1758 -0.0375 -0.1404 -0.0163c0.0637,-0.0888 0.1594,-0.1402 0.2279,-0.2235l-0.9849 0.4772c-0.1089,0.0534 -0.4306,0.5672 -0.5266,0.6922 -0.1802,0.2202 -0.5124,-0.2033 -0.7609,-0.3405l0.2762 0.3034c-0.1828,-0.0025 -0.4046,-0.0156 -0.5464,0.0752l0.2056 -0.0195z"
            />
            <path
              fill="#999999"
              d="M4.3375 7.6026l0.2401 -0.5118c0.0457,-0.0936 -0.0794,-0.2034 -0.1891,-0.3729 -0.0782,-0.121 -0.1611,-0.2395 -0.2481,-0.3677l-0.7328 -1.0888c-0.0268,-0.06 -0.1063,-0.4167 -0.1183,-0.4971 0.0936,-0.0606 0.1753,-0.082 0.3393,-0.197 0.1022,-0.0717 0.2115,-0.1589 0.2639,-0.2777 0.1007,-0.2281 0.0424,-0.7261 -0.0353,-0.9525 -0.0455,-0.1327 -0.093,-0.2647 -0.1366,-0.4022 -0.0524,-0.1652 -0.0621,-0.0948 0.0823,-0.3767 0.0557,-0.1089 0.35,-0.6707 0.3658,-0.7401 -0.0687,0.0461 -0.4823,0.7693 -0.5446,0.8713 -0.0548,0.0896 -0.0792,0.0842 -0.0263,0.1979 0.1713,0.3682 0.4361,0.9622 0.1819,1.2915 -0.1916,0.2482 -0.4358,0.3122 -0.7357,0.388l-0.1851 -0.6512c-0.0024,0.1012 0.2128,1.0065 0.2534,1.1899 0.0276,0.1246 0.026,0.1801 0.0921,0.2672 0.0555,0.0732 0.1032,0.1447 0.1557,0.2167 0.1043,0.1427 0.2011,0.2764 0.3071,0.4238 0.0998,0.1386 0.1978,0.2817 0.2931,0.4252 0.4653,0.6996 0.2999,0.6121 -0.3393,1.0732 0.1665,0.0216 0.3185,0.095 0.4423,0.2048 0.081,-0.0363 0.1852,-0.101 0.2742,-0.1139z"
            />
          </symbol>

          <symbol id="relief-deadTree-2-bw" viewBox="-10 -9 30 30">
            <ellipse fill="#999999" opacity=".5" cx="5.5691" cy="9.506" rx="4.825" ry=".5684" />
            <path
              fill="#b3b3b3"
              d="M1.679 3.5305l-0.5914 -0.2423c0.2049,0.3227 0.8568,0.3529 0.9257,1.1466 0.0188,0.2166 0.0334,0.2874 0.0274,0.2877l-0.0627 0.003c-0.1741,-0.114 -0.0803,-0.0814 -0.125,-0.5035l-0.149 0.4333c-0.884,-0.1024 -1.1345,-0.9856 -1.522,-1.157 0.0945,0.4164 0.1069,0.1444 0.3065,0.5819 0.1329,0.2913 0.1234,0.3803 0.3235,0.5433 -0.3018,-0.0152 -0.2722,-0.2108 -0.7765,-0.1333l0.8518 0.3089c0.3411,0.0711 0.4473,0.3096 0.8873,0.4034 0.7297,0.1555 0.8304,0.9419 0.8039,1.9517 -1.2559,0.0858 -1.1471,-1.4021 -1.1869,-1.4946l-0.0817 -0.1897 -0.0372 0.8722c-0.1953,-0.0862 -0.4195,-0.0759 -0.6206,-0.204 -0.3275,-0.2086 -0.1479,-0.3863 -0.4882,-0.4596 0.0371,0.5904 0.7744,0.7122 1.0801,1.012 0.2091,0.2051 0.2487,0.4467 0.4605,0.6561 0.1976,0.1955 0.3922,0.1808 0.5932,0.3942 -0.2392,0.1554 -0.2456,0.0512 -0.4157,0.2941 0.2789,0.2135 0.6512,-0.3638 0.6968,0.3659l-0.0753 0.1314 0.0057 0.3037c-0.0765,0.082 -0.1103,0.0108 -0.2853,-0.0638l0.1248 0.4129c-0.2614,0.0823 -0.2086,0.0986 -0.4283,0.26 -0.0687,-0.1591 -0.0574,-0.341 -0.0575,-0.3416 -0.1973,0.1955 -0.041,0.0251 -0.1724,0.3157l-0.2807 0.0375 -0.2353 0.172c0.0166,0.0305 0.0231,0.0503 0.0259,0.0641 0.5892,-0.1981 1.3769,-0.2863 2.2319,-0.2183 0.517,0.0411 1.0007,0.1347 1.4241,0.266 -0.2093,-0.1379 -0.4154,-0.3068 -0.6089,-0.2809 0.3384,-0.0334 0.557,0.1266 0.7762,-0.0291 -0.0116,-0.0171 -0.0336,-0.0585 -0.0414,-0.04 -0.2183,-0.1297 -0.1296,-0.0991 -0.3828,-0.1369 -0.8341,-0.0913 -1.0623,-1.1991 -0.6846,-2.1715 0.1148,-0.2957 0.15,-0.1675 0.1954,-0.3631 0.7256,-0.0816 1.4521,0.6923 1.8913,-0.18 -0.32,-0.0118 -0.3601,0.198 -0.7796,0.1439 -0.2875,-0.037 -0.5949,-0.1322 -0.7655,-0.3165 1.2886,-0.6494 1.0806,-0.8912 1.489,-1.4573 0.2383,-0.3304 0.3236,-0.1176 0.4895,-0.5992 -0.3842,0.0962 -0.668,0.5411 -0.923,0.8001 0.0294,-0.8219 0.5645,-1.0809 0.2601,-1.7852 -0.1194,0.3583 0.0793,0.3008 -0.2716,0.9492 -0.1488,0.2751 -0.2304,0.6341 -0.3535,0.8937 -0.1749,0.369 -1.0145,0.7821 -1.3429,0.6432 -0.2625,-1.5704 1.2608,-1.4244 1.7171,-2.9858 0.1082,-0.3703 -0.0046,-0.34 0.2521,-0.4762 -0.2374,-0.2138 -0.1318,0.1284 -0.1516,-0.3055 0.4125,-0.5937 0.4463,-0.2996 0.6287,-0.9535l0.1667 -0.4867c-0.3642,0.1212 -0.1886,0.2262 -0.3853,0.5867 -0.0991,0.1815 -0.2777,0.3195 -0.4897,0.3478 -0.1484,-0.1486 -0.3404,-0.415 -0.4219,-0.6144 -0.1726,-0.4224 -0.0332,-0.515 0.0165,-0.9229 -0.2513,0.1258 -0.2673,0.4884 -0.2032,0.8657 0.0777,0.4568 0.259,0.4728 0.3536,0.7365 0.2036,0.5674 -0.1231,1.5803 -0.4923,1.669 -0.2599,-0.6178 -0.1389,-0.5099 -0.0559,-1.1514 -0.3962,0.467 -0.0305,1.0251 -0.1346,1.3145 -0.1475,0.182 -0.526,0.4221 -0.7103,0.5992 -0.1897,0.1821 -0.1458,0.1848 -0.2987,0.3948 -0.1358,0.1867 -0.1887,0.203 -0.3348,0.4176 -0.1315,-0.6385 -0.4597,-1.0413 -0.7405,-1.3874 0.2,-0.2285 0.2784,-0.3478 0.6312,-0.4772 0.3178,-0.1166 0.5361,-0.1513 0.5389,-0.5903 -0.212,0.0746 -0.2207,0.3469 -0.6704,0.4752 0.0799,-0.2322 0.0813,-0.1298 0.1373,-0.4444 -0.2906,0.3241 -0.0801,0.3381 -0.3802,0.514 -0.1557,0.0913 -0.33,0.1116 -0.4702,0.2076 -0.1232,-0.402 -0.1303,-0.3989 -0.0658,-0.8723l0.1533 -0.2038c0.1132,-0.1545 0.1626,-0.2402 0.3489,-0.3217 0.3073,-0.1346 0.5114,-0.0923 0.5563,-0.4919 -0.2809,0.1498 -0.387,0.2416 -0.7518,0.3749 -0.3568,0.1303 -0.4097,0.3449 -0.7091,0.4842 -0.114,-0.3646 -0.271,-0.3342 -0.3815,-0.786 -0.1449,-0.5926 -0.0026,-0.7687 0.0853,-1.1817 -0.3132,0.2088 -0.3149,0.4188 -0.3345,0.9648 -0.4693,0.0005 -0.4863,-0.8063 -0.5087,-1.0178l-0.1143 0.5467c-0.2289,-0.099 -0.3561,-0.1846 -0.5848,-0.0251 0.1017,0.0842 0.7571,0.2068 1.1046,1.029 0.3769,0.8922 0.686,0.9642 0.5744,1.8877z"
            />
            <path
              fill="#999999"
              d="M4.8565 9.7405c-0.2093,-0.1378 -0.4153,-0.3069 -0.6089,-0.2811 0.3383,-0.0334 0.5569,0.1266 0.7761,-0.0291 -0.0116,-0.0171 -0.0336,-0.0585 -0.0414,-0.04 -0.2183,-0.1297 -0.1296,-0.0991 -0.3827,-0.1369 -0.8341,-0.0913 -1.0624,-1.1991 -0.6847,-2.1715 0.1148,-0.2957 0.1501,-0.1675 0.1954,-0.3631 -0.0467,-0.123 0.0439,-0.1513 -0.2166,-0.132 -0.4837,0.0358 -0.4335,0.3011 -0.4749,0.451 -0.043,0.1554 -0.3572,0.7239 -0.3816,1.4623 -0.011,0.3289 0.0331,0.246 -0.0081,0.6595 -0.0107,0.1082 -0.031,0.2048 -0.0477,0.2933 0.0721,0.0012 0.1448,0.0035 0.218,0.007 -0.0003,-0.4729 -0.0122,-1.0018 0.0855,-1.2875 0.1016,-0.2975 -0.0153,-0.1074 0.1875,-0.3203 0,0.6477 -0.0814,1.158 -0.139,1.6153l0.0989 0.0072c0.5171,0.0411 1.0008,0.1346 1.4242,0.2661z"
            />
          </symbol>

          <symbol id="relief-mount-2" viewBox="-5 -5 50 50">
            <polygon
              fill="#96989A"
              stroke="#96989A"
              stroke-width=".2"
              points="23.2198,13.2844 25.0296,15.5958 25.7023,16.6348 26.9007,17.3503 27.6924,18.8671 28.6339,19.544 29.6416,21.2874 30.1793,22.9204 30.7341,23.1774 31.5491,24.0589 31.9489,25.0324 32.4734,26.4994 33.8428,27.4678 34.673,28.5353 34.8847,28.7856 34.8285,28.9234 29.5625,31.5852 22.3428,32.6 17.9672,32.2587 6.7332,31.3779 4.2787,30.6699 0.3152,28.4746 6.2326,22.923 6.8631,18.7876 8.5478,17.0127 9.4447,14.5301 10.1033,13.4603 10.0987,12.7193 10.3459,12.4623 10.8502,12.3291 11.2616,9.4996 12.2382,9.5462 12.8014,9.7331 13.2941,9.6207 13.6109,9.8041 14.1481,9.9827 15.2052,7.9497 15.8578,7.6333 16.1761,6.4592 16.6967,5.5584 17.9672,2.6 19.2707,4.5745 23.008,12.5807 "
            />
            <polygon
              fill="#BDBFC1"
              points="23.2198,13.2844 25.0296,15.5958 25.7023,16.6348 26.9007,17.3503 27.6924,18.8671 28.6339,19.544 29.6416,21.2874 30.1793,22.9204 30.7341,23.1774 31.5491,24.0589 31.9489,25.0324 32.4734,26.4994 33.8428,27.4678 34.673,28.5353 34.8847,28.7856 34.8285,28.9234 29.5625,31.5852 22.3428,32.6 12.2198,31.8104 6.7332,31.3779 4.2787,30.6699 0.3152,28.4746 6.2326,22.923 6.8631,18.7876 8.5478,17.0127 9.4447,14.5301 9.6678,14.1183 10.1033,13.4603 10.0987,12.7193 10.3459,12.4623 10.8502,12.3291 10.9552,11.4205 11.2616,9.4996 13.6805,10.8818 15.2052,7.9497 15.8578,7.6333 16.1761,6.4592 16.6967,5.5584 17.9672,2.6 19.2707,4.5745 23.008,12.5807 "
            />
            <polygon
              fill="#a8a8a8"
              points="13.4787,27.0815 15.3508,21.8824 18.3111,15.2733 25.171,25.3682 21.3156,32.1469"
            />
            <polygon
              fill="#999999"
              points="23.2198,13.2844 25.0296,15.5958 25.7023,16.6348 26.9007,17.3503 27.6924,18.8671 28.6339,19.544 29.6416,21.2874 30.1793,22.9204 30.7341,23.1774 31.5491,24.0589 31.9489,25.0324 32.4734,26.4994 33.8428,27.4678 34.673,28.5353 34.8847,28.7856 34.8285,28.9234 29.5625,31.5852 22.3428,32.6 17.9672,32.2587 21.0737,27.7521 21.7612,26.7547 21.895,24.2875 20.5482,19.4183 18.3111,15.2733 19.9099,12.3973 17.9672,2.6 19.2707,4.5745 23.008,12.5807 "
            />
            <polygon
              fill="#a8a8a8"
              points="18.2474,32.2806 6.7332,31.3779 13.2414,24.6909 15.3508,21.8824 18.5651,27.4046 20.2242,29.0369"
            />
          </symbol>

          <symbol id="relief-mount-3" viewBox="-5 -3 45 45">
            <polygon
              fill="#96989A"
              stroke="#96989A"
              stroke-width=".2"
              points="25.3915,13.976 26.9002,15.9029 27.4611,16.769 28.4601,17.3655 29.12,18.63 29.9049,19.1943 30.745,20.6477 31.1932,22.0089 31.6557,22.2232 32.3351,22.9581 32.6684,23.7696 33.1056,24.9927 34.2473,25.7998 34.9393,26.6898 35.1158,26.8985 35.0689,27.0133 30.679,29.2324 24.6604,30.0782 21.0127,29.7937 14.3249,29.2694 12.5343,29.5211 10.0779,29.3295 3.7712,28.8351 2.3933,28.4376 0.1682,27.2051 3.4902,24.0885 3.8441,21.7669 4.7899,20.7706 5.6813,18.303 7.6713,17.3287 10.0779,12.6794 10.8097,13.7878 12.616,17.6576 13.1603,17.0841 13.8282,12.5327 14.8701,12.8548 15.3517,12.6401 16.0651,11.1879 16.9674,11.3732 17.4851,11.2365 17.793,11.2992 21.0127,5.069 22.0994,6.7151 25.2149,13.3894 "
            />
            <polygon
              fill="#BDBFC1"
              points="25.3915,13.976 26.9002,15.9029 27.4611,16.769 28.4601,17.3655 29.12,18.63 29.9049,19.1943 30.745,20.6477 31.1932,22.0089 31.6557,22.2232 32.3351,22.9581 32.6684,23.7696 33.1056,24.9927 34.2473,25.7998 34.9393,26.6898 35.1158,26.8985 35.0689,27.0133 30.679,29.2324 24.6604,30.0782 16.2214,29.42 14.3198,29.2701 12.5343,29.5211 6.8513,29.0778 3.7712,28.8351 2.3933,28.4376 0.1682,27.2051 3.4902,24.0885 3.8441,21.7669 4.7899,20.7706 5.6813,18.303 7.6713,17.3287 8.6899,15.3886 10.0779,12.6794 10.8097,13.7878 12.616,17.6576 13.1603,17.0841 13.8282,12.5327 14.983,13.3907 16.0651,11.1879 17.4391,11.9731 18.9517,9.0921 21.0127,5.069 22.0994,6.7151 25.2149,13.3894 "
            />
            <path
              fill="#999999"
              d="M13.0266 18.6774l1.0161 1.2977 0.3775 0.5832 0.6729 0.4017 0.4443 0.8515 0.5286 0.38 0.5657 0.9788 1.365 -0.2171 0.852 0.9077 0.8012 0.7006 1.0769 -0.4987 0.587 0.888 1.3143 1.1862 1.6837 -1.1473 -3.2991 4.8038 -6.6879 -0.5243 -1.7906 0.2516 -2.4564 -0.1915 1.7439 -2.53 0.386 -0.56 0.0751 -1.3851 -0.756 -2.7335 -1.2559 -2.3269 0.8975 -1.6146 -1.0906 -5.5001 0.7318 1.1084 2.098 4.4946 0.1189 0.395zm12.3648 -4.7014l1.5087 1.9269 0.5609 0.8661 0.999 0.5965 0.6599 1.2645 0.7849 0.5643 0.8401 1.4534 0.4482 1.3613 0.4625 0.2143 0.6794 0.7349 0.3333 0.8115 0.4371 1.2231 1.1417 0.8072 0.6921 0.89 0.1764 0.2087 -0.0468 0.1148 -4.3899 2.2191 -6.0187 0.8458 -3.6476 -0.2845 2.5896 -3.7569 0.5732 -0.8316 0.1114 -2.0567 -1.1227 -4.0591 -1.8649 -3.4554 1.3328 -2.3976 -1.6195 -8.1675 1.0867 1.6461 3.1155 6.6743 0.1765 0.5866z"
            />
          </symbol>

          <symbol id="relief-mount-4" viewBox="-5 -15 50 50">
            <polygon
              fill="#96989A"
              stroke="#96989A"
              stroke-width=".2"
              points="35.1337,17.58 34.122,18.8623 31.5268,19.3968 28.6951,19.562 25.2025,19.4911 22.0686,19.053 19.2643,20.1212 14.8201,19.849 10.9897,18.983 7.7168,18.0396 4.4391,18.4829 1.598,17.8161 0.2005,16.9864 5.3775,14.1114 6.9445,13.6145 9.7551,10.1143 10.7985,9.9008 11.1418,9.0682 12.5645,7.9945 13.6885,4.6225 17.0605,0.1265 19.3086,1.2504 19.5301,1.868 20.0211,2.0967 20.0211,2.0967 22.6805,4.6225 22.7195,6.0067 23.6307,6.3628 25.5645,8.9605 27.9106,10.6515 27.912,11.4444 28.1901,12.0933 29.0346,11.8883 29.8293,12.2096"
            />
            <polygon
              fill="#BDBFC1"
              points="35.1337,17.58 34.122,18.8623 31.5268,19.3968 28.6951,19.562 25.2025,19.4911 22.0686,19.053 19.2643,20.1212 14.8201,19.849 10.9897,18.983 7.7168,18.0396 4.4391,18.4829 1.598,17.8161 0.2005,16.9864 5.3775,14.1114 6.9445,13.6145 9.7551,10.1143 10.6513,10.2579 11.1418,9.0682 12.5645,7.9945 13.6885,4.6225 17.0605,0.1265 19.3086,1.2504 19.8426,2.7391 20.0211,2.0967 22.6805,4.6225 22.7409,6.7655 25.5645,8.9605 27.9106,10.6515 27.6061,13.0536 29.9394,12.3212"
            />
            <path
              fill="#999999"
              d="M17.6643 2.2612l-0.3434 1.3675 0.2294 0.1158 -0.1215 0.4558 0.0287 0.4166 0.2487 -0.7253 0.0199 0.7745 0.1926 0.9377 -0.9604 1.4775 -0.6513 0.6353 1.7115 -0.7977 0.1556 -0.7421 0.4118 1.3885 1.1335 1.9731 0.7278 1.7545 -0.2079 1.6338 0.7769 0.6722 0.3099 1.1103 0.7775 0.5155 -0.6186 2.4264 0.5834 1.4019 3.1339 0.4381 3.4927 0.0709 2.8316 -0.1651 2.5952 -0.5346 1.0117 -1.2823 -5.3044 -5.3703c-0.2875,-0.1214 -0.5799,-0.2431 -0.8727,-0.3502l-0.3389 0.6201 -0.3658 -0.0155 -0.0618 -0.3708 -0.2782 -0.6489 -0.0014 -0.7929 -2.346 -1.6911 -1.9339 -2.5976 -0.5212 0.0497 -0.3686 0.3529 -0.0604 -2.143 -2.6594 -2.5258 -0.1784 0.6424 -0.5342 -1.4886 -2.2481 -1.124 0.6038 2.1347z"
            />
          </symbol>

          <symbol id="relief-mount-5" viewBox="-5 -12 45 45">
            <polygon
              fill="#96989A"
              stroke="#96989A"
              stroke-width=".2"
              points=".1806,16.7402 3.5087,13.7123 4.239,13.7226 5.6739,11.608 7.2317,11.0365 8.5763,9.1019 11.2204,5.1632 11.5727,4.0521 14.4278,0.1139 14.7002,0.1847 15.5903,0.6964 17.3404,2.3788 19.0704,4.6029 19.8528,4.6768 21.1765,3.7877 21.6878,3.1801 22.2862,3.3991 23.2631,4.3576 23.6605,5.4693 24.1225,6.6796 27.0001,10.5869 28.8156,9.4183 30.9325,11.9224 31.9742,13.5284 32.7597,14.0214 35.7881,17.4522 35.0629,18.009 30.1283,18.9281 26.9306,18.8548 20.8774,19.2757 15.3532,18.9995 11.8111,18.7356 9.9342,18.4948 6.0759,18.7277 3.5217,18.2204 "
            />
            <polygon
              fill="#BDBFC1"
              points=".1806,16.7402 3.5087,13.7123 3.9652,14.1261 5.6739,11.608 7.2317,11.0365 8.5763,9.1019 11.2204,5.1632 11.5727,4.0521 14.4278,0.1139 15.4779,0.7228 17.2215,2.4846 18.8233,4.7304 19.5423,4.8852 21.1765,3.7877 21.6878,3.1801 22.2862,3.3991 23.2631,4.3576 23.6605,5.4693 24.1225,6.6796 27.0001,10.5869 28.8156,9.4183 30.9325,11.9224 31.9742,13.5284 32.7597,14.0214 35.7881,17.4522 35.0629,18.009 30.1283,18.9281 26.9306,18.8548 20.8774,19.2757 15.3532,18.9995 11.8111,18.7356 9.9342,18.4948 6.0759,18.7277 3.5217,18.2204 "
            />
            <path
              fill="#999999"
              d="M35.7881 17.4522l-3.0284 -3.4308 -0.7855 -0.493 -1.0417 -1.606 -2.1169 -2.5041 -0.1069 1.6658 -0.5815 0.9516 0.6344 0.4229 -0.1543 1.2251 0.5772 0.7838 0.6872 0.8986 -1.2159 0.8459 0.5287 0.5287 1.0044 0.6344 0.4757 0.7929 0.1189 0.6381 1.8119 -0.3376 2.4673 -0.4596 0.7252 -0.5568zm-16.2458 -12.567l-0.719 -0.1548 -1.6261 -2.2705 -1.7192 -1.7371 -1.0501 -0.6089 -0.806 3.5794 -0.1188 1.5355 0.8458 0.7402 0.5287 -0.6344 -0.5287 2.5375 -1.2158 2.1675 2.2732 -1.9032 0.8458 0.6872 -0.2114 1.4803 -0.0528 1.0573 -0.6344 1.2688 0.2114 0.7929 -1.163 2.009 -0.6344 1.2688 -0.1615 2.1686 2.9143 0.1885 0.2605 -1.5112 -0.2115 -1.6918 2.0478 -2.1712 0.1726 -2.0052 0.7929 1.1101 0.8987 -1.3216 -0.2643 -1.3745 -0.6344 -0.37 0 -0.6344 -0.9656 -0.3996 -0.0917 -1.715 0.1057 -1.4274 0.9113 -0.6609zm2.7439 -1.4861l-0.5984 -0.219 -0.0368 1.0839 -0.9781 1.3217 0.6344 0.6079 -0.2379 1.4538 0.5287 1.1366 -0.1851 1.1631 0.7402 1.5331 0.7929 1.6124 -0.4757 1.2159 0.2643 0.8458 1.3216 1.2424 0.9516 0.1322 1.6457 2.3451 0.601 -0.0118 -0.5021 -1.3289 -0.0529 -0.7666 -1.0044 -0.9252 0.0528 -1.0044 0.5815 -0.0264 -1.1631 -2.4847 0.7402 0.3436 0.5551 -0.3964 0.1322 -1.0574 0.4061 -0.629 -2.8776 -3.9072 -0.8594 -2.3221 -0.9769 -0.9585z"
            />
          </symbol>

          <symbol id="relief-mount-6" viewBox="-3 -10 40 40">
            <polygon
              fill="#96989A"
              stroke="#96989A"
              stroke-width=".2"
              points=".147,15.0385 1.6442,13.0243 3.3151,11.642 4.1434,10.0376 4.9806,9.9224 6.8955,7.0031 8.6059,5.1501 9.0229,3.7256 10.0368,2.3148 12.4348,4.6748 14.6687,3.6743 18.1604,1.3295 20.0044,0.1303 23.5192,4.0044 24.3981,3.1572 25.3939,4.067 27.6095,6.6459 28.7754,8.0029 30.309,8.9148 31.4894,10.6345 32.5909,12.0136 33.1688,13.2271 33.746,13.7886 34.1887,14.9298 35.1672,15.7874 33.2794,16.9613 30.2507,17.8494 27.9082,18.0142 25.5124,18.5408 24.1945,18.5184 22.0666,17.9886 20.7224,17.5522 19.3848,17.2692 18.0714,17.4921 16.8448,17.9273 14.923,18.4833 11.9731,18.4984 8.0901,18.2949 4.9114,17.2688 1.9652,16.102 "
            />
            <polygon
              fill="#BDBFC1"
              points=".147,15.0385 1.6442,13.0243 3.3151,11.642 4.1434,10.0376 4.7098,10.3352 6.8955,7.0031 8.6059,5.1501 9.0229,3.7256 10.0368,2.3148 12.2006,4.7797 14.6687,3.6743 18.1604,1.3295 20.0044,0.1303 23.2333,4.2797 24.3981,3.1572 25.3939,4.067 27.6095,6.6459 28.7754,8.0029 30.309,8.9148 31.4894,10.6345 32.5909,12.0136 33.1688,13.2271 33.746,13.7886 34.1887,14.9298 35.1672,15.7874 33.2794,16.9613 30.2507,17.8494 27.9082,18.0142 25.5124,18.5408 24.1945,18.5184 22.0666,17.9886 20.7224,17.5522 19.3848,17.2692 18.0714,17.4921 16.8448,17.9273 14.923,18.4833 11.9731,18.4984 8.0901,18.2949 4.9114,17.2688 1.9652,16.102 "
            />
            <polygon
              fill="#999999"
              points="12.2006,4.7797 10.0368,2.3148 10.1151,7.3804 11.4163,8.759 12.2026,10.4436 11.8763,13.7594 14.5464,16.7619 15.0352,18.4509 19.3848,17.2692 16.5848,14.5291 17.904,13.4655 15.4923,10.5203 14.5256,8.5177 12.9142,7.5924 13.9488,6.222 "
            />
            <polygon
              fill="#999999"
              points="23.2333,4.2797 20.0044,0.1303 19.9564,3.3216 19.4305,3.5239 18.8945,6.0413 19.0996,7.1979 19.8037,9.1018 20.5765,9.6521 20.1327,11.8442 20.4782,12.7337 22.7768,14.5969 22.0989,12.9428 22.0752,12.3141 22.7092,10.7332 22.4605,9.1605 22.6231,8.3019 22.2254,6.9131 23.5867,5.0457 "
            />
            <polygon
              fill="#999999"
              points="35.1672,15.7874 34.1887,14.9298 33.746,13.7886 33.1688,13.2271 32.5909,12.0136 30.309,8.9148 28.7754,8.0029 25.3939,4.067 24.3981,3.1572 24.8,5.3815 23.8709,6.152 25.4726,8.5929 25.9139,10.398 25.7241,12.6056 24.6322,14.2344 24.9293,15.4655 26.199,16.3424 28.0999,16.8168 28.1829,17.9949 30.2507,17.8494 33.2794,16.9613 "
            />
          </symbol>

          <symbol id="relief-mount-7" viewBox="-8 -10 40 40">
            <polygon
              fill="#96989A"
              stroke="#96989A"
              stroke-width=".2"
              points="22.529,16.6581 21.9433,15.0851 21.8084,13.5984 21.4921,11.5468 20.7584,9.2608 18.1129,5.2497 17.7604,4.1287 14.9038,0.1126 14.6313,0.1761 13.7407,0.6645 11.9897,2.3012 10.8187,3.7756 10.2754,4.1491 9.5595,3.9239 8.7609,3.5562 7.64,2.9875 7.0412,3.1907 6.0639,4.1237 5.6662,5.2254 5.204,6.4241 2.3249,10.2569 1.7062,11.6374 2.3144,13.0024 2.1506,13.6978 1.1772,13.673 1.0735,15.1182 0.4367,16.8402 0.1318,17.5293 2.3944,18.5311 8.4508,19.113 13.9779,18.9836 17.5219,18.8136 19.3998,18.6226 "
            />
            <polygon
              fill="#999999"
              points="22.529,16.6581 21.9433,15.0851 21.8165,13.6871 21.6735,12.1117 20.7584,9.2608 18.1129,5.2497 17.7604,4.1287 14.9038,0.1126 13.8531,0.6938 12.1086,2.4102 10.506,4.6147 9.7866,4.7504 8.1515,3.609 7.64,2.9875 7.0412,3.1907 6.0639,4.1237 5.6662,5.2254 5.204,6.4241 2.3249,10.2569 1.7062,11.6374 2.3144,13.0024 2.0235,14.2377 1.1772,13.673 1.0735,15.1182 0.4367,16.8402 0.138,17.5319 2.3944,18.5311 8.4508,19.113 13.9779,18.9836 17.5219,18.8136 19.3998,18.6226 "
            />
            <path
              fill="#BDBFC1"
              d="M9.7866 4.7504l0.7194 -0.1357 1.627 -2.2285 1.7201 -1.6924 1.0506 -0.5812 0.8064 3.6027 0.1188 1.5394 -0.8462 0.7182 -0.529 -0.6488 0.529 2.553 1.2165 2.2009 -2.2744 -1.9646 -0.8462 0.6652 0.2115 1.4867 0.0529 1.0592 0.6347 1.2863 -0.2115 0.7877 1.1636 2.041 0.6347 1.2862 0.1616 2.1741 -2.9158 0.1112 -0.2607 -1.5189 0.2116 -1.6871 -2.0489 -2.2267 -0.1727 -2.0108 -0.7934 1.0896 -0.8992 -1.3462 0.2645 -1.3681 0.6347 -0.3534 0 -0.6347 0.9661 -0.3741 0.0918 -1.7136 -0.1058 -1.431 -0.9118 -0.6854zm-2.7454 -1.5597l0.5987 -0.2032 0.0368 1.0853 0.9786 1.3484 -0.6347 0.5914 0.238 1.4609 -0.529 1.1231 0.1852 1.1687 -0.7406 1.5142 -0.7934 1.5922 1.5431 0.6224 1.2433 0.621 0.0153 0.9133 -0.2397 0.777 1.8113 0.1046 1.0597 0.4823 0.9965 2.6186 -4.3596 0.1022 -6.0565 -0.5819 -2.2625 -1.0018 0.3049 -0.6891 0.6368 -1.722 0.1037 -1.4452 0.8463 0.5647 0.2909 -1.2353 -0.6082 -1.365 0.6187 -1.3805 2.8791 -3.8328 0.8598 -2.3004 0.9774 -0.933z"
            />
          </symbol>

          <symbol id="relief-mountSnow-1" viewBox="-5 -5 50 50">
            <polygon
              fill="#96989A"
              stroke="#96989A"
              stroke-width=".2"
              points="23.2198,13.2844 25.0296,15.5958 25.7023,16.6348 26.9007,17.3503 27.6924,18.8671 28.6339,19.544 29.6416,21.2874 30.1793,22.9204 30.7341,23.1774 31.5491,24.0589 31.9489,25.0324 32.4734,26.4994 33.8428,27.4678 34.673,28.5353 34.8847,28.7856 34.8285,28.9234 29.5625,31.5852 22.3428,32.6 17.9672,32.2587 6.7332,31.3779 4.2787,30.6699 0.3152,28.4746 6.2326,22.923 6.8631,18.7876 8.5478,17.0127 9.4447,14.5301 10.1033,13.4603 10.0987,12.7193 10.3459,12.4623 10.8502,12.3291 11.2616,9.4996 12.2382,9.5462 12.8014,9.7331 13.2941,9.6207 13.6109,9.8041 14.1481,9.9827 15.2052,7.9497 15.8578,7.6333 16.1761,6.4592 16.6967,5.5584 17.9672,2.6 19.2707,4.5745 23.008,12.5807 "
            />
            <polygon
              fill="#BDBFC1"
              points="23.2198,13.2844 25.0296,15.5958 25.7023,16.6348 26.9007,17.3503 27.6924,18.8671 28.6339,19.544 29.6416,21.2874 30.1793,22.9204 30.7341,23.1774 31.5491,24.0589 31.9489,25.0324 32.4734,26.4994 33.8428,27.4678 34.673,28.5353 34.8847,28.7856 34.8285,28.9234 29.5625,31.5852 22.3428,32.6 12.2198,31.8104 6.7332,31.3779 4.2787,30.6699 0.3152,28.4746 6.2326,22.923 6.8631,18.7876 8.5478,17.0127 9.4447,14.5301 9.6678,14.1183 10.1033,13.4603 10.0987,12.7193 10.3459,12.4623 10.8502,12.3291 10.9552,11.4205 11.2616,9.4996 13.6805,10.8818 15.2052,7.9497 15.8578,7.6333 16.1761,6.4592 16.6967,5.5584 17.9672,2.6 19.2707,4.5745 23.008,12.5807 "
            />
            <polygon
              fill="#bdbec0"
              points="13.4787,27.0815 15.3508,21.8824 18.3111,15.2733 25.171,25.3682 21.3156,32.1469"
            />
            <polygon
              fill="#999999"
              points="23.2198,13.2844 25.0296,15.5958 25.7023,16.6348 26.9007,17.3503 27.6924,18.8671 28.6339,19.544 29.6416,21.2874 30.1793,22.9204 30.7341,23.1774 31.5491,24.0589 31.9489,25.0324 32.4734,26.4994 33.8428,27.4678 34.673,28.5353 34.8847,28.7856 34.8285,28.9234 29.5625,31.5852 22.3428,32.6 17.9672,32.2587 21.0737,27.7521 21.7612,26.7547 21.895,24.2875 20.5482,19.4183 18.3111,15.2733 19.9099,12.3973 17.9672,2.6 19.2707,4.5745 23.008,12.5807 "
            />
            <polygon
              fill="#bdbec0"
              points="18.2474,32.2806 6.7332,31.3779 13.2414,24.6909 15.3508,21.8824 18.5651,27.4046 20.2242,29.0369"
            />
            <polygon
              fill="#e6e6e6"
              points="12.8246,9.719 12.2711,9.5441 11.3343,9.513 13.6886,10.794 14.1481,9.9526 13.6202,9.7854 13.3088,9.6138"
            />
            <polygon
              fill="#FEFEFE"
              points="13.6805,10.8818 11.2616,9.4996 11.0559,10.9144 11.8389,12.3618 13.3272,12.0311 14.0879,13.8832 16.1715,12.0311 16.6014,13.7839 17.9244,11.1712 18.1228,12.3618 19.4457,11.2042 19.5775,10.7214 17.9672,2.6 16.6967,5.5584 16.1761,6.4592 15.8578,7.6333 15.2052,7.9497 "
            />
            <polygon
              fill="#e6e6e6"
              stroke="#BDBFC1"
              stroke-width=".0762"
              points="17.9672,2.6 18.0463,6.2528 18.383,4.6971 18.8561,7.083 18.5661,9.6743 19.0983,8.3046 19.5775,10.7214 20.0823,11.6761 20.8761,12.106 21.1407,10.9815 21.5375,11.8084 21.8021,11.0808 22.4764,11.4421 19.2707,4.5745 "
            />
          </symbol>

          <symbol id="relief-mountSnow-2" viewBox="-5 -8 45 45">
            <polygon
              fill="#96989A"
              stroke="#96989A"
              stroke-width=".2"
              points="25.3915,9.1042 26.9002,11.0311 27.4611,11.8972 28.4601,12.4937 29.12,13.7582 29.9049,14.3225 30.745,15.7759 31.1932,17.1372 31.6557,17.3514 32.3351,18.0863 32.6684,18.8978 33.1056,20.1209 34.2473,20.9281 34.9393,21.818 35.1158,22.0267 35.0689,22.1415 30.679,24.3606 24.6604,25.2064 21.0127,24.922 14.3249,24.3977 12.5343,24.6493 10.0779,24.4578 3.7712,23.9633 2.3933,23.5658 0.1682,22.3334 3.4902,19.2167 3.8441,16.8951 4.7899,15.8988 5.6813,13.4312 7.6713,12.4569 10.0779,7.8076 10.8097,8.916 12.616,12.7858 13.1603,12.2124 13.8282,7.6609 14.8701,7.983 15.3517,7.7683 16.0651,6.3161 16.9674,6.5014 17.4851,6.3647 17.793,6.4274 21.0127,0.1972 22.0994,1.8433 25.2149,8.5176 "
            />
            <polygon
              fill="#BDBFC1"
              points="25.3915,9.1042 26.9002,11.0311 27.4611,11.8972 28.4601,12.4937 29.12,13.7582 29.9049,14.3225 30.745,15.7759 31.1932,17.1372 31.6557,17.3514 32.3351,18.0863 32.6684,18.8978 33.1056,20.1209 34.2473,20.9281 34.9393,21.818 35.1158,22.0267 35.0689,22.1415 30.679,24.3606 24.6604,25.2064 16.2214,24.5482 14.3198,24.3984 12.5343,24.6493 6.8513,24.206 3.7712,23.9633 2.3933,23.5658 0.1682,22.3334 3.4902,19.2167 3.8441,16.8951 4.7899,15.8988 5.6813,13.4312 7.6713,12.4569 8.6899,10.5168 10.0779,7.8076 10.8097,8.916 12.616,12.7858 13.1603,12.2124 13.8282,7.6609 14.983,8.5189 16.0651,6.3161 17.4391,7.1013 18.9517,4.2204 21.0127,0.1972 22.0994,1.8433 25.2149,8.5176 "
            />
            <path
              fill="#999999"
              d="M13.0266 13.8057l1.0161 1.2977 0.3775 0.5832 0.6729 0.4017 0.4443 0.8515 0.5286 0.38 0.5657 0.9788 1.365 -0.2171 0.852 0.9077 0.8012 0.7006 1.0769 -0.4987 0.587 0.888 1.3143 1.1862 1.6837 -1.1473 -3.2991 4.8038 -6.6879 -0.5243 -1.7906 0.2516 -2.4564 -0.1915 1.7439 -2.53 0.386 -0.56 0.0751 -1.3851 -0.756 -2.7335 -1.2559 -2.3269 0.8975 -1.6146 -1.0906 -5.5001 0.7318 1.1084 2.098 4.4946 0.1189 0.395zm12.3648 -4.7014l1.5087 1.9269 0.5609 0.8661 0.999 0.5965 0.6599 1.2645 0.7849 0.5643 0.8401 1.4534 0.4482 1.3613 0.4625 0.2143 0.6794 0.7349 0.3333 0.8115 0.4371 1.2231 1.1417 0.8072 0.6921 0.89 0.1764 0.2087 -0.0468 0.1148 -4.3899 2.2191 -6.0187 0.8458 -3.6476 -0.2845 2.5896 -3.7569 0.5732 -0.8316 0.1114 -2.0567 -1.1227 -4.0591 -1.8649 -3.4554 1.3328 -2.3976 -1.6195 -8.1675 1.0867 1.6461 3.1155 6.6743 0.1765 0.5866z"
            />
            <path
              fill="#e6e6e6"
              d="M10.0779 7.8076l1.0906 5.5 0.4152 -0.4101 1.205 0.2576 -1.9788 -4.2391 -0.7319 -1.1084zm12.5157 0.4025l-1.5808 -8.0129 1.0867 1.6461 2.7072 5.7999 -0.3838 0.5883 -0.4636 -0.296 -0.311 0.8985 -0.5241 -0.3498 -0.264 1.1861 -0.2771 -0.6052 -0.4468 0.1919 0.2592 -0.4664 0.1982 -0.5806zm-5.5775 -1.7214l-0.951 -0.1724 1.374 0.785 0.362 -0.6894 -0.3159 -0.047 -0.4691 0.1238zm-2.1029 1.4753l-1.0849 -0.303 1.1548 0.858 0.3482 -0.7086 -0.4181 0.1537z"
            />
            <path
              fill="#FEFEFE"
              d="M13.4943 9.9367l-0.0192 0.1307 0.773 1.6295 0.9687 -1.1448 0.5504 0.5063 1.0347 -1.2109 0.5504 1.8934 1.0128 -1.387 0.8365 -0.2862 0.4623 0.7926 0.7045 -1.5412 0.9308 1.4432 1.3328 -2.3976 -1.6195 -8.1675 -3.5736 6.904 -1.374 -0.785 -1.0821 2.2027 -1.1548 -0.858 -0.3339 2.2758zm-3.4165 -2.1291l-2.4065 4.6492 0.742 0.5232 1.1558 -0.2973 1.5993 0.6249 -1.0906 -5.5z"
            />
          </symbol>

          <symbol id="relief-mountSnow-3" viewBox="-5 -15 50 50">
            <polygon
              fill="#96989A"
              stroke="#96989A"
              stroke-width=".2"
              points="35.1337,17.58 34.122,18.8623 31.5268,19.3968 28.6951,19.562 25.2025,19.4911 22.0686,19.053 19.2643,20.1212 14.8201,19.849 10.9897,18.983 7.7168,18.0396 4.4391,18.4829 1.598,17.8161 0.2005,16.9864 5.3775,14.1114 6.9445,13.6145 9.7551,10.1143 10.7985,9.9008 11.1418,9.0682 12.5645,7.9945 13.6885,4.6225 17.0605,0.1265 19.3086,1.2504 19.5301,1.868 20.0211,2.0967 20.0211,2.0967 22.6805,4.6225 22.7195,6.0067 23.6307,6.3628 25.5645,8.9605 27.9106,10.6515 27.912,11.4444 28.1901,12.0933 29.0346,11.8883 29.8293,12.2096 "
            />
            <polygon
              fill="#BDBFC1"
              points="35.1337,17.58 34.122,18.8623 31.5268,19.3968 28.6951,19.562 25.2025,19.4911 22.0686,19.053 19.2643,20.1212 14.8201,19.849 10.9897,18.983 7.7168,18.0396 4.4391,18.4829 1.598,17.8161 0.2005,16.9864 5.3775,14.1114 6.9445,13.6145 9.7551,10.1143 10.6513,10.2579 11.1418,9.0682 12.5645,7.9945 13.6885,4.6225 17.0605,0.1265 19.3086,1.2504 19.8426,2.7391 20.0211,2.0967 22.6805,4.6225 22.7409,6.7655 25.5645,8.9605 27.9106,10.6515 27.6061,13.0536 29.9394,12.3212 "
            />
            <path
              fill="#999999"
              d="M17.6643 2.2612l-0.3434 1.3675 0.2294 0.1158 -0.1215 0.4558 0.0287 0.4166 0.2487 -0.7253 0.0199 0.7745 0.1926 0.9377 -0.9604 1.4775 -0.6513 0.6353 1.7115 -0.7977 0.1556 -0.7421 0.4118 1.3885 1.1335 1.9731 0.7278 1.7545 -0.2079 1.6338 0.7769 0.6722 0.3099 1.1103 0.7775 0.5155 -0.6186 2.4264 0.5834 1.4019 3.1339 0.4381 3.4927 0.0709 2.8316 -0.1651 2.5952 -0.5346 1.0117 -1.2823 -5.3044 -5.3703c-0.2875,-0.1214 -0.5799,-0.2431 -0.8727,-0.3502l-0.3389 0.6201 -0.3658 -0.0155 -0.0618 -0.3708 -0.2782 -0.6489 -0.0014 -0.7929 -2.346 -1.6911 -1.9339 -2.5976 -0.5212 0.0497 -0.3686 0.3529 -0.0604 -2.143 -2.6594 -2.5258 -0.1784 0.6424 -0.5342 -1.4886 -2.2481 -1.124 0.6038 2.1347z"
            />
            <polygon
              fill="#e6e6e6"
              points="19.3086,1.2504 17.0605,0.1265 17.3208,3.6287 17.4576,4.6169 18.2355,6.3837 18.4568,7.1297 19.5555,7.6994 19.9956,6.8192 20.3478,7.1273 21.0519,7.0392 21.7122,7.6554 21.8442,6.0709 22.7409,6.7655 22.6805,4.6225 20.0211,2.0967 19.8426,2.7391 "
            />
            <polygon
              fill="#FEFEFE"
              points="12.5645,7.9945 12.3831,8.1314 13.3341,8.871 14.0824,8.3429 15.3587,9.2232 16.3071,7.7165 18.0186,6.9189 18.2355,6.3837 17.9188,5.6039 17.7262,4.6661 17.708,3.9637 17.4576,4.6169 17.4288,4.2003 17.5502,3.7445 17.3208,3.6287 17.6643,2.2612 17.0605,0.1265 13.6885,4.6225 "
            />
          </symbol>

          <symbol id="relief-mountSnow-4" viewBox="-5 -12 45 45">
            <polygon
              fill="#96989A"
              stroke="#96989A"
              stroke-width=".2"
              points=".1806,16.758 3.5087,13.7301 4.239,13.7404 5.6739,11.6258 7.2317,11.0543 8.5763,9.1197 11.2204,5.181 11.5727,4.0699 14.4278,0.1317 15.4779,0.7406 17.1972,2.4777 18.8233,4.7482 19.5423,4.903 21.1765,3.8055 21.6878,3.1979 22.2862,3.4169 23.2631,4.3754 23.6605,5.4871 24.1225,6.6974 27.0001,10.6046 28.8156,9.4361 30.9325,11.9401 31.9742,13.5462 32.7597,14.0392 35.7881,17.47 35.0629,18.0268 30.1283,18.9459 26.9306,18.8725 20.8774,19.2934 15.3532,19.0173 11.8111,18.7534 9.9342,18.5126 6.0759,18.7455 3.5217,18.2382 "
            />
            <polygon
              fill="#BDBFC1"
              points=".1806,16.758 3.5087,13.7301 3.9652,14.1439 5.6739,11.6258 7.2317,11.0543 8.5763,9.1197 11.2204,5.181 11.5727,4.0699 14.4278,0.1317 15.4779,0.7406 17.2215,2.5024 18.8233,4.7482 19.5423,4.903 21.1765,3.8055 21.6878,3.1979 22.2862,3.4169 23.2631,4.3754 23.6605,5.4871 24.1225,6.6974 27.0001,10.6046 28.8156,9.4361 30.9325,11.9401 31.9742,13.5462 32.7597,14.0392 35.7881,17.47 35.0629,18.0268 30.1283,18.9459 26.9306,18.8725 20.8774,19.2934 15.3532,19.0173 11.8111,18.7534 9.9342,18.5126 6.0759,18.7455 3.5217,18.2382 "
            />
            <path
              fill="#999999"
              d="M35.7881 17.47l-3.0284 -3.4308 -0.7855 -0.493 -1.0417 -1.606 -2.1169 -2.5041 -0.1069 1.6658 -0.5815 0.9516 0.6344 0.4229 -0.1543 1.2251 0.5772 0.7838 0.6872 0.8986 -1.2159 0.8459 0.5287 0.5287 1.0044 0.6344 0.4757 0.7929 0.1189 0.6381 1.8119 -0.3376 2.4673 -0.4596 0.7252 -0.5568zm-16.2458 -12.567l-0.719 -0.1548 -1.6261 -2.2705 -1.7192 -1.7371 -1.0501 -0.6089 -0.806 3.5794 -0.1188 1.5355 0.8458 0.7402 0.5287 -0.6344 -0.5287 2.5375 -1.2158 2.1675 2.2732 -1.9032 0.8458 0.6872 -0.2114 1.4803 -0.0528 1.0573 -0.6344 1.2688 0.2114 0.7929 -1.163 2.009 -0.6344 1.2688 -0.1615 2.1686 2.9143 0.1885 0.2605 -1.5112 -0.2115 -1.6918 2.0478 -2.1712 0.1726 -2.0052 0.7929 1.1101 0.8987 -1.3216 -0.2643 -1.3745 -0.6344 -0.37 0 -0.6344 -0.9656 -0.3996 -0.0917 -1.715 0.1057 -1.4274 0.9113 -0.6609zm2.7439 -1.4861l-0.5984 -0.219 -0.0368 1.0839 -0.9781 1.3217 0.6344 0.6079 -0.2379 1.4538 0.5287 1.1366 -0.1851 1.1631 0.7402 1.5331 0.7929 1.6124 -0.4757 1.2159 0.2643 0.8458 1.3216 1.2424 0.9516 0.1322 1.6457 2.3451 0.601 -0.0118 -0.5021 -1.3289 -0.0529 -0.7666 -1.0044 -0.9252 0.0528 -1.0044 0.5815 -0.0264 -1.1631 -2.4847 0.7402 0.3436 0.5551 -0.3964 0.1322 -1.0574 0.4061 -0.629 -2.8776 -3.9072 -0.8594 -2.3221 -0.9769 -0.9585z"
            />
            <polygon
              fill="#FEFEFE"
              points="13.6218,3.7111 14.4278,0.1317 11.5727,4.0699 11.2204,5.181 10.2231,6.6667 11.5706,6.2509 11.13,8.3655 12.0332,7.6827 11.8349,10.1277 13.2509,9.9588 14.3488,7.89 14.8775,5.3524 14.3338,5.9737 13.503,5.2466"
            />
            <polygon
              fill="#e6e6e6"
              points="14.3488,7.89 13.2509,9.9588 15.4062,8.1543 16.252,8.8415 16.9456,9.555 17.7385,8.718 18.617,8.7063 18.5357,6.8509 18.631,5.5638 19.5423,4.903 18.8233,4.7482 17.1189,2.3987 16.3376,1.6091 15.4779,0.7406 14.4278,0.1317 13.6218,3.7111 13.503,5.2466 14.3488,5.9868 14.8775,5.3524 "
            />
            <polygon
              fill="#FEFEFE"
              points="18.5357,6.8509 18.617,8.7063 19.5826,9.1059 19.5826,9.7403 20.5423,9.1255 21.4131,9.9649 21.5982,8.8018 21.0695,7.6652 21.3074,6.2114 20.673,5.6035 21.6511,4.2818 21.6878,3.1979 21.1765,3.8055 19.5423,4.903 18.631,5.5638 "
            />
            <polygon
              fill="#e6e6e6"
              points="22.2862,3.4169 21.6878,3.1979 21.6511,4.2818 20.673,5.6035 21.3074,6.2114 21.0695,7.6652 21.5982,8.8018 21.4131,9.9649 22.4095,10.3424 23.0704,9.1529 23.6651,9.4173 24.2158,8.2718 24.8766,8.448 25.0536,7.9618 24.1225,6.6974 23.2631,4.3754 "
            />
          </symbol>

          <symbol id="relief-mountSnow-5" viewBox="-3 -10 40 40">
            <polygon
              fill="#96989A"
              stroke="#96989A"
              stroke-width=".2"
              points=".147,15.0422 1.6442,13.028 3.3151,11.6457 4.1434,10.0413 4.9806,9.9261 6.8955,7.0068 8.6059,5.1538 9.0229,3.7293 10.0368,2.3185 12.2006,4.7833 14.6687,3.678 18.1604,1.3332 20.0044,0.134 23.2333,4.2834 24.3981,3.1609 25.3939,4.0708 27.6095,6.6496 28.7754,8.0066 30.309,8.9186 31.4894,10.6382 32.5909,12.0173 33.1688,13.2308 33.746,13.7923 34.1887,14.9335 35.1672,15.7911 33.2794,16.965 30.2507,17.8531 27.9082,18.0179 25.5124,18.5445 24.1945,18.5221 22.0666,17.9923 20.7224,17.5559 19.3848,17.2729 18.0714,17.4958 16.8448,17.931 14.923,18.487 11.9731,18.5021 8.0901,18.2986 4.9114,17.2725 1.9652,16.1057 "
            />
            <polygon
              fill="#BDBFC1"
              points=".147,15.0422 1.6442,13.028 3.3151,11.6457 4.1434,10.0413 4.7098,10.3389 6.8955,7.0068 8.6059,5.1538 9.0229,3.7293 10.0368,2.3185 12.2006,4.7834 14.6687,3.678 18.1604,1.3332 20.0044,0.134 23.2333,4.2834 24.3981,3.1609 25.3939,4.0708 27.6095,6.6496 28.7754,8.0066 30.309,8.9186 31.4894,10.6382 32.5909,12.0173 33.1688,13.2308 33.746,13.7923 34.1887,14.9335 35.1672,15.7911 33.2794,16.965 30.2507,17.8531 27.9082,18.0179 25.5124,18.5445 24.1945,18.5221 22.0666,17.9923 20.7224,17.5559 19.3848,17.2729 18.0714,17.4958 16.8448,17.931 14.923,18.487 11.9731,18.5021 8.0901,18.2986 4.9114,17.2725 1.9652,16.1057 "
            />
            <polygon
              fill="#999999"
              points="12.2006,4.7834 10.0368,2.3185 10.1151,7.3841 11.4163,8.7627 12.2026,10.4473 11.8763,13.7632 14.5464,16.7656 15.0352,18.4546 19.3848,17.2729 16.5848,14.5328 17.904,13.4692 15.4923,10.524 14.5256,8.5214 12.9142,7.5961 13.9488,6.2257 "
            />
            <polygon
              fill="#999999"
              points="23.2333,4.2834 20.0044,0.134 19.9564,3.3253 19.4305,3.5276 18.8945,6.045 19.0996,7.2016 19.8037,9.1055 20.5765,9.6558 20.1327,11.8479 20.4782,12.7374 22.7768,14.6006 22.0989,12.9465 22.0752,12.3178 22.7092,10.7369 22.4605,9.1642 22.6231,8.3056 22.2254,6.9168 23.5867,5.0494 "
            />
            <polygon
              fill="#999999"
              points="35.1672,15.7911 34.1887,14.9335 33.746,13.7923 33.1688,13.2308 32.5909,12.0173 30.309,8.9186 28.7754,8.0066 25.3939,4.0708 24.3981,3.1609 24.8,5.3852 23.8709,6.1557 25.4726,8.5966 25.9139,10.4017 25.7241,12.6093 24.6322,14.2381 24.9293,15.4692 26.199,16.3461 28.0999,16.8205 28.1829,17.9986 30.2507,17.8531 33.2794,16.965 "
            />
            <path
              fill="#FEFEFE"
              d="M23.5867 5.0494l-0.3534 -0.766 1.1648 -1.1224 0.4019 2.2243 -0.9291 0.7703 -0.625 0.3316 0.3847 -0.5987 -0.6602 0.0063 0.6163 -0.8453zm-13.4716 2.3346l-0.0783 -5.0655 -1.0139 1.4107 -0.417 1.4245 -1.7104 1.8531 -0.1947 0.8318 0.728 -0.2978 0.1765 0.728 0.7942 -1.2465 0.0883 0.4854 0.4413 -0.5405 0.5736 1.5994 0.6126 -1.1826zm4.5536 -3.706l-2.4681 1.1052 1.7481 1.4424 -0.5173 0.6852 0.2957 0.3987 0.75 -0.706 0.364 0.3641 0.5516 -1.2024 0.1875 0.5295 0.2096 -0.2317 0.386 0.4192 0.6398 0.3199 0.2427 -0.9597 0.5736 1.4009 0.5074 -0.7943 0.3089 0.5074 0.5227 -0.4801 -0.0765 -0.4315 0.536 -2.5174 0.5259 -0.2023 0.0479 -3.1913 -5.3356 3.544z"
            />
            <path
              fill="#e6e6e6"
              d="M24.3981 3.1609l0.4019 2.2243 -0.9291 0.7703 0.6886 0.5329 0.6056 0.4387 0.0221 -1.0588 0.4412 0.5735 0.0833 -0.7817 0.5106 0.4833 0.4121 -0.8287 -1.0977 -1.2778 -1.1387 -1.076zm-14.3613 -0.8424l0.0783 5.0655 0.3029 0.8298 0.4744 -0.8494 0.7721 0.6288 0.4523 -1.3898 1.3147 0.3075 0.5173 -0.6852 -1.7481 -1.4424 -2.1638 -2.4647zm8.8577 3.7265l0.0765 0.4315 0.591 -0.3692 0.375 0.7943 0.728 -1.3679 0.1765 0.4413 0.3971 -0.7942 0.3971 0.9045 0.5515 -0.6619 0.1765 0.6619 0.5295 -0.6178 0.077 0.4271 0.6163 -0.8453 -0.3534 -0.766 -3.229 -4.1494 -0.0479 3.1913 -0.5259 0.2023 -0.536 2.5174z"
            />
          </symbol>

          <symbol id="relief-mountSnow-6" viewBox="-8 -10 40 40">
            <polygon
              fill="#96989A"
              stroke="#96989A"
              stroke-width=".2"
              points="22.529,16.6762 21.9433,15.1032 21.8084,13.6165 21.4921,11.5648 20.7584,9.2788 18.1129,5.2678 17.7604,4.1468 14.9038,0.1306 13.8531,0.7119 12.1086,2.4283 10.506,4.6328 9.7866,4.7685 8.102,3.5668 7.64,3.0056 7.0412,3.2088 6.0639,4.1418 5.6662,5.2435 5.204,6.4422 2.3249,10.275 1.7062,11.6555 2.3144,13.0205 2.1506,13.7159 1.1772,13.6911 1.0735,15.1363 0.4367,16.8583 0.1318,17.5474 2.3944,18.5492 8.4508,19.1311 13.9779,19.0017 17.5219,18.8317 19.3998,18.6407 "
            />
            <polygon
              fill="#999999"
              points="22.529,16.6762 21.9433,15.1032 21.8165,13.7052 21.6735,12.1298 20.7584,9.2788 18.1129,5.2678 17.7604,4.1468 14.9038,0.1306 13.8531,0.7119 12.1086,2.4283 10.506,4.6328 9.7866,4.7685 8.1515,3.6271 7.64,3.0056 7.0412,3.2088 6.0639,4.1418 5.6662,5.2435 5.204,6.4422 2.3249,10.275 1.7062,11.6555 2.3144,13.0205 2.0235,14.2558 1.1772,13.6911 1.0735,15.1363 0.4367,16.8583 0.138,17.55 2.3944,18.5492 8.4508,19.1311 13.9779,19.0017 17.5219,18.8317 19.3998,18.6407 "
            />
            <path
              fill="#BDBFC1"
              d="M9.7866 4.7685l0.7194 -0.1357 1.627 -2.2285 1.7201 -1.6924 1.0506 -0.5812 0.8064 3.6027 0.1188 1.5394 -0.8462 0.7182 -0.529 -0.6488 0.529 2.553 1.2165 2.2009 -2.2744 -1.9646 -0.8462 0.6652 0.2115 1.4867 0.0529 1.0592 0.6347 1.2863 -0.2115 0.7877 1.1636 2.041 0.6347 1.2862 0.1616 2.1741 -2.9158 0.1112 -0.2607 -1.5189 0.2116 -1.6871 -2.0489 -2.2267 -0.1727 -2.0108 -0.7934 1.0896 -0.8992 -1.3462 0.2645 -1.3681 0.6347 -0.3534 0 -0.6347 0.9661 -0.3741 0.0918 -1.7136 -0.1058 -1.431 -0.9118 -0.6854zm-2.7454 -1.5597l0.5987 -0.2032 0.0368 1.0853 0.9786 1.3484 -0.6347 0.5914 0.238 1.4609 -0.529 1.1231 0.1852 1.1687 -0.7406 1.5142 -0.7934 1.5922 1.5431 0.6224 1.2433 0.621 0.0153 0.9133 -0.2397 0.777 1.8113 0.1046 1.0597 0.4823 0.9965 2.6186 -4.3596 0.1022 -6.0565 -0.5819 -2.2625 -1.0018 0.3049 -0.6891 0.6368 -1.722 0.1037 -1.4452 0.8463 0.5647 0.2909 -1.2353 -0.6082 -1.365 0.6187 -1.3805 2.8791 -3.8328 0.8598 -2.3004 0.9774 -0.933z"
            />
            <polygon
              fill="#FEFEFE"
              points="6.0639,4.1418 5.204,6.4422 5.4977,7.1815 6.6217,6.7187 6.6217,8.1952 7.3049,7.7104 7.6135,8.2393 8.2586,7.4916 8.0206,6.0308 8.6553,5.4393 7.6767,4.0909 7.64,3.0056 7.0412,3.2088"
            />
            <polygon
              fill="#FEFEFE"
              points="10.506,4.6328 9.7866,4.7685 10.6984,5.4539 10.7907,6.7013 10.7583,7.7417 11.3161,7.2916 11.6687,8.3715 12.4841,6.7847 12.8809,7.7104 13.7183,6.5423 14.2693,7.3137 14.9829,7.8952 14.4539,5.3422 14.9829,5.991 15.8291,5.2728 15.7102,3.7334 14.9038,0.1306 13.8531,0.7119 12.1086,2.4283 "
            />
            <polygon
              fill="#e6e6e6"
              points="7.6767,4.0909 7.64,3.0056 8.0828,3.5436 10.6984,5.4539 10.7907,6.7013 10.7583,7.7417 10.236,6.9831 10.0156,7.3799 9.8613,6.7187 9.3985,8.1512 9.2443,7.2476 8.5831,7.9528 8.2586,7.4916 8.0206,6.0308 8.6553,5.4393"
            />
            <polygon
              fill="#e6e6e6"
              points="15.7144,3.789 15.7102,3.7334 14.9038,0.1306 17.7604,4.1468 18.1129,5.2678 18.4803,5.8251 18.0375,6.4433 17.5306,5.5507 17.2662,6.333 16.4727,6.9392 16.5168,6.1236 15.9768,6.7518 14.9829,5.991 15.8291,5.2728"
            />
          </symbol>

          <symbol id="relief-vulcan-1" viewBox="-5 -10 110 110">
            <ellipse fill="#999999" opacity=".5" cx="50" cy="64" rx="30" ry="4"></ellipse>
            <path
              fill="#e6e7e8"
              d="m 40.318,43.0945 1.2624,1.4851 2.2879,1.7295 3.6464,2.047 0.7864,2.661 1.4661,1.7722 2.5083,1.3532 2.7505,0.3824 4.548,2.8992 4.3962,2.9284 4.26,2.533 0.0746,0.7449 L 55.9019,63.906275 34.0507,63.6698 18.4326,63.9645 C 12.828851,63.668708 7.2014518,63.758742 1.6058,63.3217 l 6.2682,-4.7224 1.9305,-0.55 3.4543,-2.435 1.6264,-1.9274 1.8235,-2.4455 3.3521,-1.8555 3.2709,-1.0652 1.9097,-2.384 3.0893,-2.7945 c 3.9306,0.6688 7.9292,0.6208 11.9872,-0.0477 z"
            />
            <path
              fill="#ccced1"
              d="m 49.5039,15.24 c 4.126703,7.052655 8.039095,13.804219 12.155745,20.862742 1.488026,-0.891499 3.410852,-3.023567 6.036874,-2.472897 2.428268,0.509201 4.651275,-2.255062 4.159839,-4.78358 -0.217013,-2.829685 3.079909,-3.305126 3.604522,-5.767821 1.199165,-1.401687 4.285792,-0.670495 4.300237,-3.289515 1.317092,-3.046435 4.612248,0.247252 6.586644,0.779407 2.59062,0.607246 4.174976,-3.029778 6.829551,-2.126519 1.641144,0.31721 3.28076,-1.413401 4.889632,-0.472092 0.899819,-0.602875 2.556726,-1.262629 3.057376,-1.606987 -0.0938,-2.129258 -1.275026,-3.744355 -2.898687,-4.950311 0.231204,-1.150324 0.401964,-1.114283 -0.873573,-1.2106 C 95.554729,8.7767013 93.878043,7.2634405 91.390175,7.641688 89.344758,6.9717881 88.477997,4.4543316 86.10117,4.3466882 81.981911,3.3946205 77.938067,1.9937993 73.709246,1.6052857 71.108742,0.94989087 68.393797,-0.77510509 65.682632,0.42725723 63.303424,0.88219116 60.548455,-0.08283459 58.507815,1.5652706 c -2.11057,0.5972 -2.698897,2.7373648 -4.21029,4.0606937 -1.394921,1.4065359 0.4728,2.8050874 0.99098,3.5161668 C 53.757109,9.7455849 54.166,12.790671 51.884625,12.985492 51.002361,13.616529 50.47659,14.713814 49.5039,15.24 Z"
            />
            <path
              fill="#babcbf"
              d="m 49.5044,15.2403 c 1.872188,-0.138196 2.425637,-2.845949 4.57073,-2.201258 1.144577,-1.239645 1.265218,-3.6735644 2.316299,-4.609529 -2.750165,-1.309054 0.09506,-3.2190069 0.839232,-4.8872084 2.490924,-0.9535868 5.115499,-2.55017169 8.057631,-1.7612421 2.695454,-0.85754135 5.305909,0.7870874 7.773131,0.8026466 2.409706,0.8458431 4.451711,2.5306898 6.680161,3.7956721 2.296373,1.6938053 6.468639,1.0207559 6.988137,4.7481988 1.338125,1.622767 3.237548,3.048988 2.244679,5.537294 0.679868,3.02407 -3.661575,3.975327 -5.196628,1.728355 -2.133084,-2.611082 -5.551095,1.155994 -6.569356,2.71362 -2.323326,1.338206 -3.135934,3.85674 -5.292457,5.674255 -1.358773,2.083033 0.458567,5.947891 -3.336796,6.161344 -2.570722,-0.224246 -5.261874,-0.123487 -6.325269,2.757753 -1.891404,1.772211 -4.914889,1.91023 -7.451697,1.999909 -3.066782,0.108414 -6.090481,0.05214 -8.834187,1.704591 -2.2624,1.362577 -4.755417,2.854218 -5.662414,3.901477 -4.174179,1.077038 -7.897276,0.780504 -12.093528,0.04834 0,0 3.350593,-3.582697 3.163478,-5.042706 0.406132,-3.386301 3.499175,-5.702031 4.108846,-8.738619 0.971591,-2.557705 0.952214,-5.995887 2.953555,-7.863737 2.36467,-0.738408 4.092762,-2.156665 6.402735,-2.934491 0.879172,-2.130542 2.48838,-2.667714 4.663718,-3.534667 z"
            />
            <path
              fill="#acafb1"
              d="m 48.8842,16.8699 c -1.785997,0.666059 -3.779594,1.246295 -4.301192,3.452184 -0.540223,2.017352 -3.325715,0.423824 -4.4494,2.229627 -2.494158,-0.673487 -2.019728,1.842576 -2.548911,3.383955 -1.030703,1.62935 -1.137361,3.670141 -1.837647,5.502122 -1.455888,1.8507 -2.889787,3.789023 -3.24835,6.150212 -0.642322,1.376996 -2.934697,4.232379 -0.743197,5.002756 3.276226,0.386491 6.865778,0.297294 9.668135,-1.671956 1.992411,-0.789487 3.045587,-2.751047 4.759962,-3.9329 1.189858,-0.552573 2.437218,-0.990001 3.777113,-0.811 1.907845,-0.01586 3.785152,-0.37634 5.672187,0.08659 1.978298,0.05321 -0.985275,-1.72622 0.908237,-2.032705 1.474101,-0.686901 1.911031,0.604732 2.789914,1.139442 0.72917,-0.07521 2.250626,0.907421 2.007947,-0.440847 0.758787,-1.773464 1.770613,-4.072587 4.142983,-2.926051 2.333406,0.19823 4.47649,-1.394758 4.631923,-3.803654 0.362029,-1.471587 0.276981,-3.115583 2.276446,-2.98201 1.962019,-0.748148 2.294241,-3.385233 1.73135,-5.017763 -1.101666,-1.371396 0.2507,-2.912999 1.327975,-3.832219 C 76.753843,15.865967 76.05046,14.539717 75.8076,13.5526 75.093304,12.114215 75.790908,10.071743 73.619081,9.8482516 73.01701,8.9737297 73.441083,9.1741347 73.177475,8.0910547 73.369945,6.7516759 71.308021,6.5289859 70.544363,5.961525 69.388061,5.7732631 68.393705,5.6084929 67.935746,4.3663653 66.967743,3.8236661 65.71194,4.1429299 64.948956,3.4639047 63.291625,3.3657328 61.428814,3.5574961 60.282876,4.8581076 58.121173,5.7094079 58.85032,7.8874864 58.599915,9.5497793 57.986956,10.324235 56.222784,10.545705 57.2655,11.7578 c -1.231347,1.555102 -2.786541,2.706743 -4.5422,3.6878 -1.39291,0.193194 -2.512881,1.045804 -3.8391,1.4243 z"
            />
            <path
              fill="#babcbf"
              d="M62.0795 7.1509c-3.6626,10.7376 -8.7984,12.2353 -17.6693,17.6735 -3.1861,1.9533 -5.9317,3.3553 -6.0646,7.1857 -0.1229,3.5442 -4.6114,6.1599 -6.1924,10.645 1.2102,-4.6426 5.7709,-7.1396 5.8438,-10.622 0.0846,-4.0368 2.831,-5.5158 6.1732,-7.6137 8.6206,-5.4111 13.739,-6.9169 17.2433,-17.4406 0.0476,-0.1838 0.2352,-0.2944 0.419,-0.2468 0.1838,0.0476 0.2944,0.2352 0.2468,0.419z"
              fill="#A9ABAE"
            />
            <path
              fill="#babcbf"
              d="M55.2664 26.6297c-0.3962,6.424 -6.9302,8.2863 -11.8461,10.3709 -3.1118,1.3196 -3.876,2.2974 -4.5665,5.5404 0.5003,-3.3107 1.3827,-4.3655 4.4858,-5.7312 4.7065,-2.0713 11.2241,-3.9743 11.5587,-10.1758 -0.0012,-0.1016 0.0803,-0.1849 0.1819,-0.1861 0.1016,-0.0012 0.1849,0.0802 0.1861,0.1819z"
              fill="#A9ABAE"
            />
            <path
              fill="#babcbf"
              d="M77.8011 15.273c-9.036,5.077 -3.2037,7.3106 -11.9378,11.6614 -0.669,0.3332 -9.2121,4.0942 -8.7423,5.3387 -1.2201,-1.0082 8.3483,-5.6097 8.5733,-5.7275 8.4526,-4.4217 2.552,-6.5294 11.8181,-11.8967 0.1724,-0.0797 0.3767,-0.0046 0.4564,0.1678 0.0797,0.1724 0.0046,0.3767 -0.1678,0.4564z"
              fill="#A9ABAE"
            />
            <path
              fill="#babcbf"
              d="M57.112 21.9726c-7.7181,2.2071 -6.6191,0.6747 -9.488,6.388 -1.8363,3.6568 -4.9682,3.61 -5.427,4.8676 -0.13,-1.0711 3.4686,-1.6665 5.0386,-5.0251 2.7917,-5.9721 1.9202,-4.5158 9.6561,-6.8819 0.1799,-0.0608 0.3751,0.0356 0.4359,0.2155 0.0608,0.1799 -0.0356,0.3751 -0.2155,0.4359z"
              fill="#A9ABAE"
            />
            <path
              fill="#babcbf"
              d="M76.6844 8.0828c-1.4038,6.3969 -6.7659,5.3479 -9.1709,10.9842 -1.8722,4.3877 -5.6435,3.475 -7.1686,5.4454 0.5824,-1.7866 5.0761,-1.3574 6.763,-5.58 2.3337,-5.8416 7.6745,-4.9594 8.8951,-10.9432 0.0259,-0.1882 0.1994,-0.3198 0.3875,-0.2939 0.1882,0.0259 0.3198,0.1994 0.2939,0.3875z"
              fill="#A9ABAE"
            />
            <path
              fill="#babcbf"
              fill="#A9ABAE"
              d="M68.804 3.1899c-1.0348,4.1371 -2.6419,2.8465 -3.0558,7.4307 -0.4114,4.556 0.4939,2.3646 -3.4931,6.4894 3.6446,-4.6394 2.7458,-1.9022 3.016,-6.5223 0.2786,-4.7653 1.9687,-3.5801 2.8522,-7.4959 0.0271,-0.188 0.2014,-0.3183 0.3894,-0.2912 0.188,0.0271 0.3183,0.2014 0.2912,0.3894z"
            />
            <path
              fill="#d2d3d5"
              d="m 45.7612,48.0915 c 0.0019,0.0017 0.0039,0.0034 0.0058,0.0051 z M 26.501,46.9652 c -0.0014,0.003 -0.0028,0.006 -0.0042,0.0091 z m -0.6925,6.4672 c -5e-4,0.0013 -0.0011,0.0025 -0.0015,0.0038 z m 3.1367,-7.2612 c 0.0012,0.0021 0.0023,0.0041 0.0034,0.006 z m 0.1546,-0.2241 c 0.0014,0.0016 0.0027,0.0032 0.004,0.0049 z m 11.8023,1.9363 c 1.373,1.0631 2.7431,2.1294 4.1107,3.1992 0.1277,0.1125 0.2003,0.2226 0.2528,0.3846 0.046,0.1653 0.0461,0.2971 0.0013,0.4626 0.0051,0.0308 -0.8731,3.3974 -0.9854,3.7918 0.0262,-0.0903 0.0364,-0.1684 0.0326,-0.2626 0,-1e-4 5e-4,0.0062 6e-4,0.0082 0.0971,1.2511 0.1578,2.4982 0.2127,3.7516 0.0056,0.1633 -0.0172,0.2888 -0.0799,0.4398 -0.068,0.1493 -0.1432,0.2507 -0.2667,0.3586 -1.1022,0.9093 -3.87315,3.1833 -5.05715,3.9851 -0.2016,0.1338 -1.34695,-0.0779 -1.34695,-0.0779 0,0 2.5301,-2.6917 3.2995,-3.4461 l 1.7344,-1.5281 -0.2456,-3.4034 c -0.0056,-0.1318 0.0122,-0.1998 0.0393,-0.3246 0.3683,-1.1652 0.7371,-2.3296 1.0991,-3.4969 0.0248,-0.0804 0.05,-0.1608 0.0745,-0.2413 -0.0416,0.1511 -0.0415,0.2728 0,0.424 0.0476,0.1477 0.1132,0.2503 0.2295,0.3531 0.0616,0.0741 -3.9595,-3.4677 -5.737,-5.1321 -1.049,-0.9821 -1.037925,-1.066622 -2.005425,-2.122022 0.874485,-1.222855 3.008176,1.61658 4.637125,2.876422 z M 25.9867,63.7102 24.4736,63.7063 c -0.7068,0.2897 -1.5241,0.5416 -1.3493,0.0369 0.0057,-0.0134 0.0117,-0.0268 0.018,-0.0403 l -5.0331,-0.0128 c -0.6658,0.3023 -1.4936,0.6221 -1.6134,0.382 -0.2698,0.0853 -0.5138,0.1089 -0.6058,-0.0392 -0.1007,0.0375 -0.2069,0.0561 -0.3294,0.0598 -3.3817,0.0568 -6.862,0.0909 -10.2354,-0.1242 -0.1254,-0.0092 -4.5764,-0.1163 -3.4882,-0.72 1.346,-0.6498 4.3583,-0.6611 5.8204,-0.7454 1.4794,-0.083 2.9452,-0.131 4.413,-0.1595 l 0.2745,-0.1779 1.8114,-0.4876 0.3962,-1.2597 1.3585,-0.5282 1.5849,-0.1219 0.9057,-0.6908 0.9907,0.1556 -0.0511,-0.1321 c -0.588,-1.52 -1.1666,-3.0439 -1.7546,-4.5636 -0.0788,-0.218 -0.0822,-0.3985 -0.0107,-0.619 0.0827,-0.2163 0.1994,-0.3552 0.3976,-0.475 1.9454,-1.0791 3.8873,-2.13 5.8532,-3.1704 0.2608,-0.1379 0.5286,-0.2704 0.7873,-0.4106 -0.1006,0.0615 -0.1643,0.1317 -0.2148,0.2383 0.8009,-1.5586 1.6239,-3.0427 2.4849,-4.5646 0.0075,-0.0127 0.4447,-0.7805 0.4932,-0.4277 -0.7053,1.7943 -1.423,3.5853 -2.1436,5.3734 -0.0377,0.0814 -0.0856,0.1346 -0.162,0.1814 -0.0038,0.0147 -3.4802,2.1749 -3.8212,2.3846 -0.8611,0.5295 -1.7259,1.0782 -2.5946,1.5922 0.1105,-0.0665 0.1754,-0.143 0.2219,-0.2634 0.0403,-0.1218 0.0392,-0.2242 -0.0042,-0.3451 0,0 1.7011,3.931 2.1937,5.1211 0.375,-0.2535 0.7509,-0.5077 1.1253,-0.7679 0.3836,-0.2665 0.7711,-0.529 1.1535,-0.7966 -0.1153,0.0867 -0.1888,0.179 -0.2457,0.3117 0.4471,-1.02 0.8899,-1.9723 1.3912,-2.9651 0.393,-0.7762 0.8307,-1.4288 1.315,-2.1416 0.0713,-0.0955 0.2279,-0.2771 0.3424,-0.1193 -0.3629,1.3549 -0.7445,2.7053 -1.1641,4.0438 -0.1514,0.4744 -0.304,0.9485 -0.4574,1.4223 0.4593,-0.2688 0.9217,-0.5383 1.3881,-0.8119 -0.1054,0.0651 -0.1795,0.1359 -0.2492,0.2382 0,0 1.0334,-1.5106 1.5453,-2.269 1.1687,-1.7312 2.359,-3.4283 3.5433,-5.1455 -0.0676,0.1077 -0.0967,0.2019 -0.1032,0.3288 -0.0011,0.1266 0.022,0.2209 0.0826,0.3321 0,0 -0.5188,-1.0154 -0.7725,-1.5191 -0.6463,-1.2824 -1.179,-2.5556 -1.7237,-3.8788 -0.0236,-0.0622 -0.2233,-0.5734 0.0354,-0.4899 l 0.0042,0.0061 c 0.0069,-1e-4 0.0144,2e-4 0.0225,9e-4 1.514,1.5564 3.015,3.1339 4.4842,4.7324 0.0963,0.1054 0.1984,0.2118 0.2914,0.3193 0.0803,0.1 0.1197,0.1924 0.1361,0.3197 0.0112,0.1282 -0.0078,0.2273 -0.0649,0.3425 0.0018,0.0089 -2.6532,5.6465 -2.9315,6.1963 0.0406,-0.0776 0.0633,-0.145 0.0785,-0.2313 0.0012,-0.0014 -0.1007,0.7978 -0.1313,1.0286 -0.1335,1.0053 -0.2936,2.0037 -0.4615,3.0037 -0.0279,0.1561 -0.0741,0.2699 -0.1621,0.4021 -0.0921,0.1286 -0.1829,0.2124 -0.3188,0.2933 -1.1877,0.6688 -2.3952,1.3313 -3.6449,1.8796 l 0.4111,0.492 z m -6.5129,-4.4641 0.1529,0.024 c 0.0522,-0.1289 0.1264,-0.2248 0.2441,-0.317 z m 3.4591,1.9275 0.1669,0.1797 1.0189,1.0972 0.1111,0.0418 c 0.5896,-0.4654 1.268,-0.8748 1.7208,-1.1858 0.7705,-0.5264 1.5677,-1.0478 2.3718,-1.5214 -0.1115,0.0662 -0.1849,0.1347 -0.2606,0.24 -0.0717,0.1074 -0.1107,0.2013 -0.1333,0.3285 -0.0468,0.0935 0.5059,-2.9473 0.6892,-4.0133 0.0173,-0.1008 0.0506,-0.2065 0.1008,-0.296 0.3756,-0.6714 0.7441,-1.3498 1.1113,-2.026 l 0.173,-0.3177 c -0.9648,1.6073 -1.9345,3.2117 -2.9136,4.8097 -0.0856,0.1257 -0.1702,0.2069 -0.2996,0.2869 -0.001,0.0025 -0.6916,0.4433 -0.766,0.4906 -0.994,0.6267 -2.0331,1.2685 -3.0904,1.8858 z m 21.6795,-14.158 c 0.8938,0.7045 1.7841,1.4134 2.6728,2.1244 0.0582,0.0528 0.0889,0.106 0.1073,0.1822 0.0015,0.0013 0.6917,2.6436 0.7444,2.8755 -0.0168,-0.0793 -0.0496,-0.1352 -0.1099,-0.1893 -5e-4,-0.0027 0.9606,0.7144 1.1481,0.8553 0.5241,0.394 1.0672,0.7868 1.5812,1.1913 -0.0521,-0.0424 -0.0995,-0.0679 -0.1631,-0.0891 0,0 3.5221,0.9115 4.3455,1.147 0.083,0.0255 0.1481,0.0567 0.2209,0.1039 0.0125,-0.0016 2.8665,1.7712 3.1975,1.9797 2.3623,1.4973 4.7629,3.0939 6.9724,4.8058 0.0017,0.0012 -0.1708,-0.0988 -0.2361,-0.0931 0,1e-4 0.3695,0.1055 0.506,0.1468 0.2054,0.0626 3.3876,0.8241 2.4806,1.2387 -0.9807,0.3718 -2.236,0.1163 -3.2507,-10e-5 -0.1089,-0.0211 -0.19,-0.054 -0.2837,-0.1131 -0.0037,9e-4 -0.9925,-0.5699 -1.0766,-0.6187 -3.1963,-1.8526 -6.1286,-3.9744 -9.1885,-6.0299 0.0634,0.0414 0.1231,0.0694 0.1952,0.0921 0,0 -0.2064,-0.0652 -0.3093,-0.0975 -1.3251,-0.4163 -2.6464,-0.8446 -3.9708,-1.2616 -0.1181,-0.0383 -0.2038,-0.0839 -0.3006,-0.1618 -0.8675,-0.737 -1.7257,-1.4772 -2.5786,-2.2309 -0.1496,-0.1302 -0.2295,-0.2639 -0.2718,-0.4578 -0.0675,-0.4205 -0.134,-0.841 -0.2,-1.2618 -0.0865,-0.5585 -0.1638,-1.1145 -0.2329,-1.6753 0.0245,0.1017 0.0673,0.1759 0.1449,0.2465 -0.6851,-0.7266 -1.33,-1.4546 -1.9886,-2.2027 -0.0335,-0.0396 -0.4475,-0.5208 -0.1554,-0.5067 z m -12.7976,3.4025 3e-4,0.0022 0.2813,0.3698 c -0.0897,-0.1126 -0.1331,-0.2168 -0.151,-0.3596 -0.0119,-0.1437 0.0091,-0.2542 0.0736,-0.3832 l -0.2041,0.3708 z m 2.5515,8.528 c -0.079,-0.6791 -0.1623,-1.358 -0.246,-2.0365 -0.0045,-0.0447 -0.0021,-0.0788 0.0092,-0.1223 0.0027,-0.0353 0.0543,-0.1046 0.0553,-0.1106 1.3536,-1.8017 2.691,-3.61 4.0031,-5.4423 -0.0257,0.0334 -0.0406,0.0629 -0.0529,0.1032 -0.0163,0.0319 -0.0071,0.0785 -0.0102,0.1119 -0.0031,0.0338 0.0234,0.0795 0.0318,0.1082 0.0193,0.037 0.0412,0.0646 0.0726,0.0921 -1.2585,-0.9711 -2.7186,-2.1244 -4.0785,-2.9358 -0.7384,-0.4627 -4.2016,-3.3514 -3.8525,-4.1363 1.5454,-0.4456 4.0924,2.1976 5.0112,3.1002 1.1274,1.1404 2.2598,2.2689 3.4112,3.3851 0.0487,0.0432 0.0796,0.0824 0.1099,0.1401 0.0273,0.0554 0.0412,0.1029 0.0477,0.1643 0.0051,0.062 5e-4,0.1096 -0.0159,0.1695 -0.0023,0.0241 -0.0621,0.146 -0.0804,0.1558 -1.5051,1.6933 -2.9505,3.3949 -4.3869,5.1465 -0.0067,0.0084 -0.0064,0.0108 -0.0109,0.019 -0.002,0.0035 -0.0023,0.022 -0.0025,0.0222 -0.0032,0.003 0.1569,1.8069 0.1717,1.9699 0.138,1.6198 0.2761,3.2396 0.4141,4.8594 -0.2003,-1.588 -0.4005,-3.1758 -0.6009,-4.7638 z"
            />
            <path
              fill="#999999"
              d="m 35.51055,43.935956 9.08155,7.730644 -1.1462,3.8206 0.191,3.8206 -5.34205,4.7118 L 68.4924,64.03675 68.2303,62.8856 55.0261,54.525 53.6509,54.3338 52.2757,54.1426 49.7674,52.7894 48.3013,51.0172 47.5149,48.3562 44.084,46.4303 41.7744,44.7264 40.229712,43.382062 c -1.841275,0.483307 -3.63078,0.512538 -4.719162,0.553894 z M 20.2129,59.3621 l -1.8114,-0.2845 2.1834,1.2358 0.7979,0.7999 -0.959,0.4474 0.8375,1.1781 -4.53735,1.23235 9.26255,-0.07345 -0.6792,-1.0003 -1.1888,-0.447 -2.1509,-2.3162 z"
            />
            <polygon
              fill="#D2D3D5"
              points="50.236,58.692 48.7077,58.3578 50.5499,59.8101 51.2231,60.7502 50.414,61.2759 51.1206,62.6605 48.3734,63.7782 55.1073,63.8021 54.5342,62.8469 53.5313,62.3216 51.7165,59.5994 "
            />
            <path
              fill="#d82509"
              d="m 28.9597,55.8827 -3e-4,-7e-4 0.102,-0.1141 c 0.7095,-0.7938 1.1291,-1.709 1.3673,-2.7399 0.4441,-1.9223 0.1983,-3.9097 0.552,-5.8266 l 0.0227,-0.1229 0.118,-0.0409 c 0.3547,-0.1229 0.8258,-0.6708 1.057,-0.9512 0.2835,-0.3437 0.6214,-0.625 1.0089,-0.8443 0.385,-0.2179 0.7072,0.2027 1.0282,0.3405 l 0.0789,0.0338 0.0338,0.0789 c 0.2416,0.5642 0.5103,1.1239 0.8237,1.6519 l 0.0907,0.1527 -2e-4,2e-4 0.0992,0.1532 c 0.4049,0.6249 0.8833,1.1924 1.5255,1.5823 0.3805,0.231 0.8447,0.3808 1.1939,0.6362 0.4213,0.3082 0.6037,0.7456 0.7127,1.2425 0.0232,0.1057 0.035,0.2133 0.0356,0.3215 0.004,0.7151 -0.4926,1.404 -0.9158,1.9426 -0.5364,0.6826 -1.1209,1.3191 -1.5873,2.0556 -0.0623,0.0984 -0.1223,0.1983 -0.1793,0.2997 0.3591,-0.5128 0.7694,-1.0011 1.0815,-1.3894 0.597,-0.7429 1.8668,-2.2306 1.6684,-3.2538 -0.0955,-0.4929 -0.2441,-0.9666 -0.6697,-1.269 -0.2045,-0.1453 -0.4512,-0.2524 -0.675,-0.366 C 37.2067,49.2904 36.9157,49.1116 36.6358,48.8751 35.65,48.042 34.983,46.6537 34.5165,45.4796 l -0.0312,-0.0787 0.0309,-0.0788 c 0.0575,-0.1467 0.0976,-0.3061 0.1304,-0.46 0.0188,-0.0878 0.0639,-0.1654 0.139,-0.2167 0.3391,-0.2316 1.0744,0.3829 1.3421,0.573 0.134,0.0951 0.7467,0.5358 0.8998,0.5153 0.006,-0.0011 0.0161,-0.0031 0.0254,-0.0057 -0.0063,-0.0703 -0.072,-0.2341 -0.0899,-0.2819 -0.1306,-0.3487 -0.186,-0.7283 0.2597,-0.8701 0.3919,-0.1247 1.0616,0.3491 1.3735,0.5575 l 0.0687,0.0459 0.0201,0.0801 c 0.0319,0.1267 0.0986,0.2402 0.1934,0.3302 l 0.0065,0.0061 0.006,0.0067 c 0.5613,0.6297 1.0214,1.3223 1.2439,2.1432 0.1504,0.5548 0.1551,1.0705 0.236,1.6278 0.1344,0.9256 0.5686,1.4808 1.2867,2.0653 l 0.076,0.0619 0.0032,0.1073 c 0.1951,1.3962 0.1355,2.692 -0.2097,4.057 -0.095,0.3755 -0.2103,0.7424 -0.3171,1.1133 0.1335,-0.3379 0.2582,-0.6792 0.3683,-1.0246 l 0.1751,-0.5491 -0.0068,-0.0292 0.0129,-0.0505 c 0.2457,-0.9604 0.3239,-1.8905 0.2794,-2.8817 L 42.0145,51.7 l 0.3886,0.3803 c 1.589,1.5547 2.8197,4.0309 3.8675,5.9879 l 0.046,0.0861 -0.0347,0.0913 c -0.0129,0.034 -0.0104,0.071 0.0051,0.1038 0.0333,0.0703 0.0577,0.1411 0.0801,0.2106 l 0.3472,-0.2532 -0.2451,0.6651 c -0.1448,0.3929 -0.8958,0.0591 -1.0196,1.3741 l -0.0085,0.0901 -0.0705,0.0569 c -0.1298,0.1045 -0.2606,0.2068 -0.3934,0.3062 0.1937,-0.1059 0.5175,-0.2853 0.5628,-0.3455 0.2534,-0.6225 0.4974,-0.9456 1.0363,-1.3216 l 0.1952,-0.1363 0.1152,0.2083 c 0.9415,1.7019 2.6189,4.7629 4.8509,4.8411 1.8489,0.0649 3.6982,-0.0051 5.5457,-0.1055 C 56.8057,63.9009 56.3281,63.8622 55.8505,63.8234 54.8227,63.7399 53.795,63.6564 52.7673,63.5715 52.4261,63.5433 52.0847,63.515 51.7435,63.4856 51.6551,63.478 51.3663,63.4649 51.2873,63.4361 49.9888,62.9617 49.0599,61.5255 48.4142,60.3744 47.5151,58.7717 46.7908,57.0538 45.9492,55.4166 45.0624,53.6915 43.9633,51.8274 42.4515,50.578 42.0411,50.2389 41.7521,49.8623 41.6229,49.3401 41.5271,48.9527 41.527,48.5361 41.491,48.1394 41.4433,47.6141 41.3387,47.1463 41.1368,46.6567 l -0.113,-0.2739 0.2955,-0.0218 c 0.27,-0.0199 1.4086,-0.1515 1.5077,-0.4652 -0.0764,-0.1356 -0.4904,-0.4531 -0.5998,-0.5359 -0.1825,-0.1381 -0.3691,-0.2704 -0.5527,-0.4069 -0.0634,-0.0473 -0.1291,-0.096 -0.1885,-0.1483 -0.0361,-0.0318 -0.0679,-0.0702 -0.0903,-0.1116 l -1.1606,-1.3652 c -3.9357,0.719 -8.11975,0.697825 -12.05695,-0.0029 l -0.77055,0.9418 -0.0242,0.0126 c -0.0419,0.0219 -0.0684,0.0645 -0.0695,0.1119 l -2e-4,0.0108 -0.0014,0.0107 c -0.3313,2.6921 -2.186,5.0844 -4.7021,6.0879 -0.517364,0.208407 -1.522972,0.817048 -1.750063,1.061794 C 21.041775,51.440231 22.2431,50.7746 22.6514,50.6203 c 0.947,-0.358 1.8103,-0.9067 2.5437,-1.6038 l 0.2229,-0.2118 -0.0015,-0.0058 0.0812,-0.0861 c 0.6171,-0.6547 1.1191,-1.4134 1.4816,-2.2368 l 0.0643,-0.146 0.1559,0.0194 c 0.278,-0.0154 0.9104,-1.3164 1.5016,-1.2446 0.4679,0.0568 1.6962,0.4935 1.8043,1.0044 0.0513,0.242 0.1297,0.564 0.2617,0.7755 l 0.0442,0.071 -0.0154,0.0822 c -0.555,2.949 0.3724,6.1837 -1.7661,8.7078 -0.4004,0.4725 -0.8121,0.9317 -1.2416,1.376 0.3453,-0.3457 0.6814,-0.6997 1.0106,-1.062 l 0.1611,-0.1773 z"
            />
          </symbol>

          <symbol id="relief-vulcan-2" viewBox="-5 -10 110 110">
            <ellipse fill="#999999" opacity=".5" cx="50" cy="64" rx="30" ry="4"></ellipse>
            <path
              fill="#e6e7e8"
              d="m 40.318,43.0945 1.2624,1.4851 2.2879,1.7295 3.6464,2.047 0.7864,2.661 1.4661,1.7722 2.5083,1.3532 2.7505,0.3824 4.548,2.8992 4.3962,2.9284 4.26,2.533 0.0746,0.7449 L 55.9019,63.906275 34.0507,63.6698 18.4326,63.9645 C 12.828851,63.668708 7.2014518,63.758742 1.6058,63.3217 l 6.2682,-4.7224 1.9305,-0.55 3.4543,-2.435 1.6264,-1.9274 1.8235,-2.4455 3.3521,-1.8555 3.2709,-1.0652 1.9097,-2.384 3.0893,-2.7945 c 3.9306,0.6688 7.9292,0.6208 11.9872,-0.0477 z"
            />
            <path
              fill="#d2d3d5"
              d="m 45.7612,48.0915 c 0.0019,0.0017 0.0039,0.0034 0.0058,0.0051 z M 26.501,46.9652 c -0.0014,0.003 -0.0028,0.006 -0.0042,0.0091 z m -0.6925,6.4672 c -5e-4,0.0013 -0.0011,0.0025 -0.0015,0.0038 z m 3.1367,-7.2612 c 0.0012,0.0021 0.0023,0.0041 0.0034,0.006 z m 0.1546,-0.2241 c 0.0014,0.0016 0.0027,0.0032 0.004,0.0049 z m 11.8023,1.9363 c 1.373,1.0631 2.7431,2.1294 4.1107,3.1992 0.1277,0.1125 0.2003,0.2226 0.2528,0.3846 0.046,0.1653 0.0461,0.2971 0.0013,0.4626 0.0051,0.0308 -0.8731,3.3974 -0.9854,3.7918 0.0262,-0.0903 0.0364,-0.1684 0.0326,-0.2626 0,-1e-4 5e-4,0.0062 6e-4,0.0082 0.0971,1.2511 0.1578,2.4982 0.2127,3.7516 0.0056,0.1633 -0.0172,0.2888 -0.0799,0.4398 -0.068,0.1493 -0.1432,0.2507 -0.2667,0.3586 -1.1022,0.9093 -3.87315,3.1833 -5.05715,3.9851 -0.2016,0.1338 -1.34695,-0.0779 -1.34695,-0.0779 0,0 2.5301,-2.6917 3.2995,-3.4461 l 1.7344,-1.5281 -0.2456,-3.4034 c -0.0056,-0.1318 0.0122,-0.1998 0.0393,-0.3246 0.3683,-1.1652 0.7371,-2.3296 1.0991,-3.4969 0.0248,-0.0804 0.05,-0.1608 0.0745,-0.2413 -0.0416,0.1511 -0.0415,0.2728 0,0.424 0.0476,0.1477 0.1132,0.2503 0.2295,0.3531 0.0616,0.0741 -3.9595,-3.4677 -5.737,-5.1321 -1.049,-0.9821 -1.037925,-1.066622 -2.005425,-2.122022 0.874485,-1.222855 3.008176,1.61658 4.637125,2.876422 z M 25.9867,63.7102 24.4736,63.7063 c -0.7068,0.2897 -1.5241,0.5416 -1.3493,0.0369 0.0057,-0.0134 0.0117,-0.0268 0.018,-0.0403 l -5.0331,-0.0128 c -0.6658,0.3023 -1.4936,0.6221 -1.6134,0.382 -0.2698,0.0853 -0.5138,0.1089 -0.6058,-0.0392 -0.1007,0.0375 -0.2069,0.0561 -0.3294,0.0598 -3.3817,0.0568 -6.862,0.0909 -10.2354,-0.1242 -0.1254,-0.0092 -4.5764,-0.1163 -3.4882,-0.72 1.346,-0.6498 4.3583,-0.6611 5.8204,-0.7454 1.4794,-0.083 2.9452,-0.131 4.413,-0.1595 l 0.2745,-0.1779 1.8114,-0.4876 0.3962,-1.2597 1.3585,-0.5282 1.5849,-0.1219 0.9057,-0.6908 0.9907,0.1556 -0.0511,-0.1321 c -0.588,-1.52 -1.1666,-3.0439 -1.7546,-4.5636 -0.0788,-0.218 -0.0822,-0.3985 -0.0107,-0.619 0.0827,-0.2163 0.1994,-0.3552 0.3976,-0.475 1.9454,-1.0791 3.8873,-2.13 5.8532,-3.1704 0.2608,-0.1379 0.5286,-0.2704 0.7873,-0.4106 -0.1006,0.0615 -0.1643,0.1317 -0.2148,0.2383 0.8009,-1.5586 1.6239,-3.0427 2.4849,-4.5646 0.0075,-0.0127 0.4447,-0.7805 0.4932,-0.4277 -0.7053,1.7943 -1.423,3.5853 -2.1436,5.3734 -0.0377,0.0814 -0.0856,0.1346 -0.162,0.1814 -0.0038,0.0147 -3.4802,2.1749 -3.8212,2.3846 -0.8611,0.5295 -1.7259,1.0782 -2.5946,1.5922 0.1105,-0.0665 0.1754,-0.143 0.2219,-0.2634 0.0403,-0.1218 0.0392,-0.2242 -0.0042,-0.3451 0,0 1.7011,3.931 2.1937,5.1211 0.375,-0.2535 0.7509,-0.5077 1.1253,-0.7679 0.3836,-0.2665 0.7711,-0.529 1.1535,-0.7966 -0.1153,0.0867 -0.1888,0.179 -0.2457,0.3117 0.4471,-1.02 0.8899,-1.9723 1.3912,-2.9651 0.393,-0.7762 0.8307,-1.4288 1.315,-2.1416 0.0713,-0.0955 0.2279,-0.2771 0.3424,-0.1193 -0.3629,1.3549 -0.7445,2.7053 -1.1641,4.0438 -0.1514,0.4744 -0.304,0.9485 -0.4574,1.4223 0.4593,-0.2688 0.9217,-0.5383 1.3881,-0.8119 -0.1054,0.0651 -0.1795,0.1359 -0.2492,0.2382 0,0 1.0334,-1.5106 1.5453,-2.269 1.1687,-1.7312 2.359,-3.4283 3.5433,-5.1455 -0.0676,0.1077 -0.0967,0.2019 -0.1032,0.3288 -0.0011,0.1266 0.022,0.2209 0.0826,0.3321 0,0 -0.5188,-1.0154 -0.7725,-1.5191 -0.6463,-1.2824 -1.179,-2.5556 -1.7237,-3.8788 -0.0236,-0.0622 -0.2233,-0.5734 0.0354,-0.4899 l 0.0042,0.0061 c 0.0069,-1e-4 0.0144,2e-4 0.0225,9e-4 1.514,1.5564 3.015,3.1339 4.4842,4.7324 0.0963,0.1054 0.1984,0.2118 0.2914,0.3193 0.0803,0.1 0.1197,0.1924 0.1361,0.3197 0.0112,0.1282 -0.0078,0.2273 -0.0649,0.3425 0.0018,0.0089 -2.6532,5.6465 -2.9315,6.1963 0.0406,-0.0776 0.0633,-0.145 0.0785,-0.2313 0.0012,-0.0014 -0.1007,0.7978 -0.1313,1.0286 -0.1335,1.0053 -0.2936,2.0037 -0.4615,3.0037 -0.0279,0.1561 -0.0741,0.2699 -0.1621,0.4021 -0.0921,0.1286 -0.1829,0.2124 -0.3188,0.2933 -1.1877,0.6688 -2.3952,1.3313 -3.6449,1.8796 l 0.4111,0.492 z m -6.5129,-4.4641 0.1529,0.024 c 0.0522,-0.1289 0.1264,-0.2248 0.2441,-0.317 z m 3.4591,1.9275 0.1669,0.1797 1.0189,1.0972 0.1111,0.0418 c 0.5896,-0.4654 1.268,-0.8748 1.7208,-1.1858 0.7705,-0.5264 1.5677,-1.0478 2.3718,-1.5214 -0.1115,0.0662 -0.1849,0.1347 -0.2606,0.24 -0.0717,0.1074 -0.1107,0.2013 -0.1333,0.3285 -0.0468,0.0935 0.5059,-2.9473 0.6892,-4.0133 0.0173,-0.1008 0.0506,-0.2065 0.1008,-0.296 0.3756,-0.6714 0.7441,-1.3498 1.1113,-2.026 l 0.173,-0.3177 c -0.9648,1.6073 -1.9345,3.2117 -2.9136,4.8097 -0.0856,0.1257 -0.1702,0.2069 -0.2996,0.2869 -0.001,0.0025 -0.6916,0.4433 -0.766,0.4906 -0.994,0.6267 -2.0331,1.2685 -3.0904,1.8858 z m 21.6795,-14.158 c 0.8938,0.7045 1.7841,1.4134 2.6728,2.1244 0.0582,0.0528 0.0889,0.106 0.1073,0.1822 0.0015,0.0013 0.6917,2.6436 0.7444,2.8755 -0.0168,-0.0793 -0.0496,-0.1352 -0.1099,-0.1893 -5e-4,-0.0027 0.9606,0.7144 1.1481,0.8553 0.5241,0.394 1.0672,0.7868 1.5812,1.1913 -0.0521,-0.0424 -0.0995,-0.0679 -0.1631,-0.0891 0,0 3.5221,0.9115 4.3455,1.147 0.083,0.0255 0.1481,0.0567 0.2209,0.1039 0.0125,-0.0016 2.8665,1.7712 3.1975,1.9797 2.3623,1.4973 4.7629,3.0939 6.9724,4.8058 0.0017,0.0012 -0.1708,-0.0988 -0.2361,-0.0931 0,1e-4 0.3695,0.1055 0.506,0.1468 0.2054,0.0626 3.3876,0.8241 2.4806,1.2387 -0.9807,0.3718 -2.236,0.1163 -3.2507,-10e-5 -0.1089,-0.0211 -0.19,-0.054 -0.2837,-0.1131 -0.0037,9e-4 -0.9925,-0.5699 -1.0766,-0.6187 -3.1963,-1.8526 -6.1286,-3.9744 -9.1885,-6.0299 0.0634,0.0414 0.1231,0.0694 0.1952,0.0921 0,0 -0.2064,-0.0652 -0.3093,-0.0975 -1.3251,-0.4163 -2.6464,-0.8446 -3.9708,-1.2616 -0.1181,-0.0383 -0.2038,-0.0839 -0.3006,-0.1618 -0.8675,-0.737 -1.7257,-1.4772 -2.5786,-2.2309 -0.1496,-0.1302 -0.2295,-0.2639 -0.2718,-0.4578 -0.0675,-0.4205 -0.134,-0.841 -0.2,-1.2618 -0.0865,-0.5585 -0.1638,-1.1145 -0.2329,-1.6753 0.0245,0.1017 0.0673,0.1759 0.1449,0.2465 -0.6851,-0.7266 -1.33,-1.4546 -1.9886,-2.2027 -0.0335,-0.0396 -0.4475,-0.5208 -0.1554,-0.5067 z m -12.7976,3.4025 3e-4,0.0022 0.2813,0.3698 c -0.0897,-0.1126 -0.1331,-0.2168 -0.151,-0.3596 -0.0119,-0.1437 0.0091,-0.2542 0.0736,-0.3832 l -0.2041,0.3708 z m 2.5515,8.528 c -0.079,-0.6791 -0.1623,-1.358 -0.246,-2.0365 -0.0045,-0.0447 -0.0021,-0.0788 0.0092,-0.1223 0.0027,-0.0353 0.0543,-0.1046 0.0553,-0.1106 1.3536,-1.8017 2.691,-3.61 4.0031,-5.4423 -0.0257,0.0334 -0.0406,0.0629 -0.0529,0.1032 -0.0163,0.0319 -0.0071,0.0785 -0.0102,0.1119 -0.0031,0.0338 0.0234,0.0795 0.0318,0.1082 0.0193,0.037 0.0412,0.0646 0.0726,0.0921 -1.2585,-0.9711 -2.7186,-2.1244 -4.0785,-2.9358 -0.7384,-0.4627 -4.2016,-3.3514 -3.8525,-4.1363 1.5454,-0.4456 4.0924,2.1976 5.0112,3.1002 1.1274,1.1404 2.2598,2.2689 3.4112,3.3851 0.0487,0.0432 0.0796,0.0824 0.1099,0.1401 0.0273,0.0554 0.0412,0.1029 0.0477,0.1643 0.0051,0.062 5e-4,0.1096 -0.0159,0.1695 -0.0023,0.0241 -0.0621,0.146 -0.0804,0.1558 -1.5051,1.6933 -2.9505,3.3949 -4.3869,5.1465 -0.0067,0.0084 -0.0064,0.0108 -0.0109,0.019 -0.002,0.0035 -0.0023,0.022 -0.0025,0.0222 -0.0032,0.003 0.1569,1.8069 0.1717,1.9699 0.138,1.6198 0.2761,3.2396 0.4141,4.8594 -0.2003,-1.588 -0.4005,-3.1758 -0.6009,-4.7638 z"
            />
            <path
              fill="#999999"
              d="m 35.51055,43.935956 9.08155,7.730644 -1.1462,3.8206 0.191,3.8206 -5.34205,4.7118 L 68.4924,64.03675 68.2303,62.8856 55.0261,54.525 53.6509,54.3338 52.2757,54.1426 49.7674,52.7894 48.3013,51.0172 47.5149,48.3562 44.084,46.4303 41.7744,44.7264 40.229712,43.382062 c -1.841275,0.483307 -3.63078,0.512538 -4.719162,0.553894 z M 20.2129,59.3621 l -1.8114,-0.2845 2.1834,1.2358 0.7979,0.7999 -0.959,0.4474 0.8375,1.1781 -4.53735,1.23235 9.26255,-0.07345 -0.6792,-1.0003 -1.1888,-0.447 -2.1509,-2.3162 z"
            />
            <polygon
              fill="#D2D3D5"
              points="50.236,58.692 48.7077,58.3578 50.5499,59.8101 51.2231,60.7502 50.414,61.2759 51.1206,62.6605 48.3734,63.7782 55.1073,63.8021 54.5342,62.8469 53.5313,62.3216 51.7165,59.5994 "
            />
            <path
              fill="#d82509"
              d="m 28.9597,55.8827 -3e-4,-7e-4 0.102,-0.1141 c 0.7095,-0.7938 1.1291,-1.709 1.3673,-2.7399 0.4441,-1.9223 0.1983,-3.9097 0.552,-5.8266 l 0.0227,-0.1229 0.118,-0.0409 c 0.3547,-0.1229 0.8258,-0.6708 1.057,-0.9512 0.2835,-0.3437 0.6214,-0.625 1.0089,-0.8443 0.385,-0.2179 0.7072,0.2027 1.0282,0.3405 l 0.0789,0.0338 0.0338,0.0789 c 0.2416,0.5642 0.5103,1.1239 0.8237,1.6519 l 0.0907,0.1527 -2e-4,2e-4 0.0992,0.1532 c 0.4049,0.6249 0.8833,1.1924 1.5255,1.5823 0.3805,0.231 0.8447,0.3808 1.1939,0.6362 0.4213,0.3082 0.6037,0.7456 0.7127,1.2425 0.0232,0.1057 0.035,0.2133 0.0356,0.3215 0.004,0.7151 -0.4926,1.404 -0.9158,1.9426 -0.5364,0.6826 -1.1209,1.3191 -1.5873,2.0556 -0.0623,0.0984 -0.1223,0.1983 -0.1793,0.2997 0.3591,-0.5128 0.7694,-1.0011 1.0815,-1.3894 0.597,-0.7429 1.8668,-2.2306 1.6684,-3.2538 -0.0955,-0.4929 -0.2441,-0.9666 -0.6697,-1.269 -0.2045,-0.1453 -0.4512,-0.2524 -0.675,-0.366 C 37.2067,49.2904 36.9157,49.1116 36.6358,48.8751 35.65,48.042 34.983,46.6537 34.5165,45.4796 l -0.0312,-0.0787 0.0309,-0.0788 c 0.0575,-0.1467 0.0976,-0.3061 0.1304,-0.46 0.0188,-0.0878 0.0639,-0.1654 0.139,-0.2167 0.3391,-0.2316 1.0744,0.3829 1.3421,0.573 0.134,0.0951 0.7467,0.5358 0.8998,0.5153 0.006,-0.0011 0.0161,-0.0031 0.0254,-0.0057 -0.0063,-0.0703 -0.072,-0.2341 -0.0899,-0.2819 -0.1306,-0.3487 -0.186,-0.7283 0.2597,-0.8701 0.3919,-0.1247 1.0616,0.3491 1.3735,0.5575 l 0.0687,0.0459 0.0201,0.0801 c 0.0319,0.1267 0.0986,0.2402 0.1934,0.3302 l 0.0065,0.0061 0.006,0.0067 c 0.5613,0.6297 1.0214,1.3223 1.2439,2.1432 0.1504,0.5548 0.1551,1.0705 0.236,1.6278 0.1344,0.9256 0.5686,1.4808 1.2867,2.0653 l 0.076,0.0619 0.0032,0.1073 c 0.1951,1.3962 0.1355,2.692 -0.2097,4.057 -0.095,0.3755 -0.2103,0.7424 -0.3171,1.1133 0.1335,-0.3379 0.2582,-0.6792 0.3683,-1.0246 l 0.1751,-0.5491 -0.0068,-0.0292 0.0129,-0.0505 c 0.2457,-0.9604 0.3239,-1.8905 0.2794,-2.8817 L 42.0145,51.7 l 0.3886,0.3803 c 1.589,1.5547 2.8197,4.0309 3.8675,5.9879 l 0.046,0.0861 -0.0347,0.0913 c -0.0129,0.034 -0.0104,0.071 0.0051,0.1038 0.0333,0.0703 0.0577,0.1411 0.0801,0.2106 l 0.3472,-0.2532 -0.2451,0.6651 c -0.1448,0.3929 -0.8958,0.0591 -1.0196,1.3741 l -0.0085,0.0901 -0.0705,0.0569 c -0.1298,0.1045 -0.2606,0.2068 -0.3934,0.3062 0.1937,-0.1059 0.5175,-0.2853 0.5628,-0.3455 0.2534,-0.6225 0.4974,-0.9456 1.0363,-1.3216 l 0.1952,-0.1363 0.1152,0.2083 c 0.9415,1.7019 2.6189,4.7629 4.8509,4.8411 1.8489,0.0649 3.6982,-0.0051 5.5457,-0.1055 C 56.8057,63.9009 56.3281,63.8622 55.8505,63.8234 54.8227,63.7399 53.795,63.6564 52.7673,63.5715 52.4261,63.5433 52.0847,63.515 51.7435,63.4856 51.6551,63.478 51.3663,63.4649 51.2873,63.4361 49.9888,62.9617 49.0599,61.5255 48.4142,60.3744 47.5151,58.7717 46.7908,57.0538 45.9492,55.4166 45.0624,53.6915 43.9633,51.8274 42.4515,50.578 42.0411,50.2389 41.7521,49.8623 41.6229,49.3401 41.5271,48.9527 41.527,48.5361 41.491,48.1394 41.4433,47.6141 41.3387,47.1463 41.1368,46.6567 l -0.113,-0.2739 0.2955,-0.0218 c 0.27,-0.0199 1.4086,-0.1515 1.5077,-0.4652 -0.0764,-0.1356 -0.4904,-0.4531 -0.5998,-0.5359 -0.1825,-0.1381 -0.3691,-0.2704 -0.5527,-0.4069 -0.0634,-0.0473 -0.1291,-0.096 -0.1885,-0.1483 -0.0361,-0.0318 -0.0679,-0.0702 -0.0903,-0.1116 l -1.1606,-1.3652 c -3.9357,0.719 -8.11975,0.697825 -12.05695,-0.0029 l -0.77055,0.9418 -0.0242,0.0126 c -0.0419,0.0219 -0.0684,0.0645 -0.0695,0.1119 l -2e-4,0.0108 -0.0014,0.0107 c -0.3313,2.6921 -2.186,5.0844 -4.7021,6.0879 -0.517364,0.208407 -1.522972,0.817048 -1.750063,1.061794 C 21.041775,51.440231 22.2431,50.7746 22.6514,50.6203 c 0.947,-0.358 1.8103,-0.9067 2.5437,-1.6038 l 0.2229,-0.2118 -0.0015,-0.0058 0.0812,-0.0861 c 0.6171,-0.6547 1.1191,-1.4134 1.4816,-2.2368 l 0.0643,-0.146 0.1559,0.0194 c 0.278,-0.0154 0.9104,-1.3164 1.5016,-1.2446 0.4679,0.0568 1.6962,0.4935 1.8043,1.0044 0.0513,0.242 0.1297,0.564 0.2617,0.7755 l 0.0442,0.071 -0.0154,0.0822 c -0.555,2.949 0.3724,6.1837 -1.7661,8.7078 -0.4004,0.4725 -0.8121,0.9317 -1.2416,1.376 0.3453,-0.3457 0.6814,-0.6997 1.0106,-1.062 l 0.1611,-0.1773 z"
            />
          </symbol>

          <symbol id="relief-vulcan-3" viewBox="-5 -10 110 110">
            <ellipse fill="#999999" opacity=".5" cx="50" cy="64" rx="30" ry="4"></ellipse>
            <path
              fill="#e6e7e8"
              d="m 40.318,43.0945 1.2624,1.4851 2.2879,1.7295 3.6464,2.047 0.7864,2.661 1.4661,1.7722 2.5083,1.3532 2.7505,0.3824 4.548,2.8992 4.3962,2.9284 4.26,2.533 0.0746,0.7449 L 55.9019,63.906275 34.0507,63.6698 18.4326,63.9645 C 12.828851,63.668708 7.2014518,63.758742 1.6058,63.3217 l 6.2682,-4.7224 1.9305,-0.55 3.4543,-2.435 1.6264,-1.9274 1.8235,-2.4455 3.3521,-1.8555 3.2709,-1.0652 1.9097,-2.384 3.0893,-2.7945 c 3.9306,0.6688 7.9292,0.6208 11.9872,-0.0477 z"
            />
            <path
              fill="#d2d3d5"
              d="m 45.7612,48.0915 c 0.0019,0.0017 0.0039,0.0034 0.0058,0.0051 z M 26.501,46.9652 c -0.0014,0.003 -0.0028,0.006 -0.0042,0.0091 z m -0.6925,6.4672 c -5e-4,0.0013 -0.0011,0.0025 -0.0015,0.0038 z m 3.1367,-7.2612 c 0.0012,0.0021 0.0023,0.0041 0.0034,0.006 z m 0.1546,-0.2241 c 0.0014,0.0016 0.0027,0.0032 0.004,0.0049 z m 11.8023,1.9363 c 1.373,1.0631 2.7431,2.1294 4.1107,3.1992 0.1277,0.1125 0.2003,0.2226 0.2528,0.3846 0.046,0.1653 0.0461,0.2971 0.0013,0.4626 0.0051,0.0308 -0.8731,3.3974 -0.9854,3.7918 0.0262,-0.0903 0.0364,-0.1684 0.0326,-0.2626 0,-1e-4 5e-4,0.0062 6e-4,0.0082 0.0971,1.2511 0.1578,2.4982 0.2127,3.7516 0.0056,0.1633 -0.0172,0.2888 -0.0799,0.4398 -0.068,0.1493 -0.1432,0.2507 -0.2667,0.3586 -1.1022,0.9093 -3.87315,3.1833 -5.05715,3.9851 -0.2016,0.1338 -1.34695,-0.0779 -1.34695,-0.0779 0,0 2.5301,-2.6917 3.2995,-3.4461 l 1.7344,-1.5281 -0.2456,-3.4034 c -0.0056,-0.1318 0.0122,-0.1998 0.0393,-0.3246 0.3683,-1.1652 0.7371,-2.3296 1.0991,-3.4969 0.0248,-0.0804 0.05,-0.1608 0.0745,-0.2413 -0.0416,0.1511 -0.0415,0.2728 0,0.424 0.0476,0.1477 0.1132,0.2503 0.2295,0.3531 0.0616,0.0741 -3.9595,-3.4677 -5.737,-5.1321 -1.049,-0.9821 -1.037925,-1.066622 -2.005425,-2.122022 0.874485,-1.222855 3.008176,1.61658 4.637125,2.876422 z M 25.9867,63.7102 24.4736,63.7063 c -0.7068,0.2897 -1.5241,0.5416 -1.3493,0.0369 0.0057,-0.0134 0.0117,-0.0268 0.018,-0.0403 l -5.0331,-0.0128 c -0.6658,0.3023 -1.4936,0.6221 -1.6134,0.382 -0.2698,0.0853 -0.5138,0.1089 -0.6058,-0.0392 -0.1007,0.0375 -0.2069,0.0561 -0.3294,0.0598 -3.3817,0.0568 -6.862,0.0909 -10.2354,-0.1242 -0.1254,-0.0092 -4.5764,-0.1163 -3.4882,-0.72 1.346,-0.6498 4.3583,-0.6611 5.8204,-0.7454 1.4794,-0.083 2.9452,-0.131 4.413,-0.1595 l 0.2745,-0.1779 1.8114,-0.4876 0.3962,-1.2597 1.3585,-0.5282 1.5849,-0.1219 0.9057,-0.6908 0.9907,0.1556 -0.0511,-0.1321 c -0.588,-1.52 -1.1666,-3.0439 -1.7546,-4.5636 -0.0788,-0.218 -0.0822,-0.3985 -0.0107,-0.619 0.0827,-0.2163 0.1994,-0.3552 0.3976,-0.475 1.9454,-1.0791 3.8873,-2.13 5.8532,-3.1704 0.2608,-0.1379 0.5286,-0.2704 0.7873,-0.4106 -0.1006,0.0615 -0.1643,0.1317 -0.2148,0.2383 0.8009,-1.5586 1.6239,-3.0427 2.4849,-4.5646 0.0075,-0.0127 0.4447,-0.7805 0.4932,-0.4277 -0.7053,1.7943 -1.423,3.5853 -2.1436,5.3734 -0.0377,0.0814 -0.0856,0.1346 -0.162,0.1814 -0.0038,0.0147 -3.4802,2.1749 -3.8212,2.3846 -0.8611,0.5295 -1.7259,1.0782 -2.5946,1.5922 0.1105,-0.0665 0.1754,-0.143 0.2219,-0.2634 0.0403,-0.1218 0.0392,-0.2242 -0.0042,-0.3451 0,0 1.7011,3.931 2.1937,5.1211 0.375,-0.2535 0.7509,-0.5077 1.1253,-0.7679 0.3836,-0.2665 0.7711,-0.529 1.1535,-0.7966 -0.1153,0.0867 -0.1888,0.179 -0.2457,0.3117 0.4471,-1.02 0.8899,-1.9723 1.3912,-2.9651 0.393,-0.7762 0.8307,-1.4288 1.315,-2.1416 0.0713,-0.0955 0.2279,-0.2771 0.3424,-0.1193 -0.3629,1.3549 -0.7445,2.7053 -1.1641,4.0438 -0.1514,0.4744 -0.304,0.9485 -0.4574,1.4223 0.4593,-0.2688 0.9217,-0.5383 1.3881,-0.8119 -0.1054,0.0651 -0.1795,0.1359 -0.2492,0.2382 0,0 1.0334,-1.5106 1.5453,-2.269 1.1687,-1.7312 2.359,-3.4283 3.5433,-5.1455 -0.0676,0.1077 -0.0967,0.2019 -0.1032,0.3288 -0.0011,0.1266 0.022,0.2209 0.0826,0.3321 0,0 -0.5188,-1.0154 -0.7725,-1.5191 -0.6463,-1.2824 -1.179,-2.5556 -1.7237,-3.8788 -0.0236,-0.0622 -0.2233,-0.5734 0.0354,-0.4899 l 0.0042,0.0061 c 0.0069,-1e-4 0.0144,2e-4 0.0225,9e-4 1.514,1.5564 3.015,3.1339 4.4842,4.7324 0.0963,0.1054 0.1984,0.2118 0.2914,0.3193 0.0803,0.1 0.1197,0.1924 0.1361,0.3197 0.0112,0.1282 -0.0078,0.2273 -0.0649,0.3425 0.0018,0.0089 -2.6532,5.6465 -2.9315,6.1963 0.0406,-0.0776 0.0633,-0.145 0.0785,-0.2313 0.0012,-0.0014 -0.1007,0.7978 -0.1313,1.0286 -0.1335,1.0053 -0.2936,2.0037 -0.4615,3.0037 -0.0279,0.1561 -0.0741,0.2699 -0.1621,0.4021 -0.0921,0.1286 -0.1829,0.2124 -0.3188,0.2933 -1.1877,0.6688 -2.3952,1.3313 -3.6449,1.8796 l 0.4111,0.492 z m -6.5129,-4.4641 0.1529,0.024 c 0.0522,-0.1289 0.1264,-0.2248 0.2441,-0.317 z m 3.4591,1.9275 0.1669,0.1797 1.0189,1.0972 0.1111,0.0418 c 0.5896,-0.4654 1.268,-0.8748 1.7208,-1.1858 0.7705,-0.5264 1.5677,-1.0478 2.3718,-1.5214 -0.1115,0.0662 -0.1849,0.1347 -0.2606,0.24 -0.0717,0.1074 -0.1107,0.2013 -0.1333,0.3285 -0.0468,0.0935 0.5059,-2.9473 0.6892,-4.0133 0.0173,-0.1008 0.0506,-0.2065 0.1008,-0.296 0.3756,-0.6714 0.7441,-1.3498 1.1113,-2.026 l 0.173,-0.3177 c -0.9648,1.6073 -1.9345,3.2117 -2.9136,4.8097 -0.0856,0.1257 -0.1702,0.2069 -0.2996,0.2869 -0.001,0.0025 -0.6916,0.4433 -0.766,0.4906 -0.994,0.6267 -2.0331,1.2685 -3.0904,1.8858 z m 21.6795,-14.158 c 0.8938,0.7045 1.7841,1.4134 2.6728,2.1244 0.0582,0.0528 0.0889,0.106 0.1073,0.1822 0.0015,0.0013 0.6917,2.6436 0.7444,2.8755 -0.0168,-0.0793 -0.0496,-0.1352 -0.1099,-0.1893 -5e-4,-0.0027 0.9606,0.7144 1.1481,0.8553 0.5241,0.394 1.0672,0.7868 1.5812,1.1913 -0.0521,-0.0424 -0.0995,-0.0679 -0.1631,-0.0891 0,0 3.5221,0.9115 4.3455,1.147 0.083,0.0255 0.1481,0.0567 0.2209,0.1039 0.0125,-0.0016 2.8665,1.7712 3.1975,1.9797 2.3623,1.4973 4.7629,3.0939 6.9724,4.8058 0.0017,0.0012 -0.1708,-0.0988 -0.2361,-0.0931 0,1e-4 0.3695,0.1055 0.506,0.1468 0.2054,0.0626 3.3876,0.8241 2.4806,1.2387 -0.9807,0.3718 -2.236,0.1163 -3.2507,-10e-5 -0.1089,-0.0211 -0.19,-0.054 -0.2837,-0.1131 -0.0037,9e-4 -0.9925,-0.5699 -1.0766,-0.6187 -3.1963,-1.8526 -6.1286,-3.9744 -9.1885,-6.0299 0.0634,0.0414 0.1231,0.0694 0.1952,0.0921 0,0 -0.2064,-0.0652 -0.3093,-0.0975 -1.3251,-0.4163 -2.6464,-0.8446 -3.9708,-1.2616 -0.1181,-0.0383 -0.2038,-0.0839 -0.3006,-0.1618 -0.8675,-0.737 -1.7257,-1.4772 -2.5786,-2.2309 -0.1496,-0.1302 -0.2295,-0.2639 -0.2718,-0.4578 -0.0675,-0.4205 -0.134,-0.841 -0.2,-1.2618 -0.0865,-0.5585 -0.1638,-1.1145 -0.2329,-1.6753 0.0245,0.1017 0.0673,0.1759 0.1449,0.2465 -0.6851,-0.7266 -1.33,-1.4546 -1.9886,-2.2027 -0.0335,-0.0396 -0.4475,-0.5208 -0.1554,-0.5067 z m -12.7976,3.4025 3e-4,0.0022 0.2813,0.3698 c -0.0897,-0.1126 -0.1331,-0.2168 -0.151,-0.3596 -0.0119,-0.1437 0.0091,-0.2542 0.0736,-0.3832 l -0.2041,0.3708 z m 2.5515,8.528 c -0.079,-0.6791 -0.1623,-1.358 -0.246,-2.0365 -0.0045,-0.0447 -0.0021,-0.0788 0.0092,-0.1223 0.0027,-0.0353 0.0543,-0.1046 0.0553,-0.1106 1.3536,-1.8017 2.691,-3.61 4.0031,-5.4423 -0.0257,0.0334 -0.0406,0.0629 -0.0529,0.1032 -0.0163,0.0319 -0.0071,0.0785 -0.0102,0.1119 -0.0031,0.0338 0.0234,0.0795 0.0318,0.1082 0.0193,0.037 0.0412,0.0646 0.0726,0.0921 -1.2585,-0.9711 -2.7186,-2.1244 -4.0785,-2.9358 -0.7384,-0.4627 -4.2016,-3.3514 -3.8525,-4.1363 1.5454,-0.4456 4.0924,2.1976 5.0112,3.1002 1.1274,1.1404 2.2598,2.2689 3.4112,3.3851 0.0487,0.0432 0.0796,0.0824 0.1099,0.1401 0.0273,0.0554 0.0412,0.1029 0.0477,0.1643 0.0051,0.062 5e-4,0.1096 -0.0159,0.1695 -0.0023,0.0241 -0.0621,0.146 -0.0804,0.1558 -1.5051,1.6933 -2.9505,3.3949 -4.3869,5.1465 -0.0067,0.0084 -0.0064,0.0108 -0.0109,0.019 -0.002,0.0035 -0.0023,0.022 -0.0025,0.0222 -0.0032,0.003 0.1569,1.8069 0.1717,1.9699 0.138,1.6198 0.2761,3.2396 0.4141,4.8594 -0.2003,-1.588 -0.4005,-3.1758 -0.6009,-4.7638 z"
            />
            <path
              fill="#999999"
              d="m 35.51055,43.935956 9.08155,7.730644 -1.1462,3.8206 0.191,3.8206 -5.34205,4.7118 L 68.4924,64.03675 68.2303,62.8856 55.0261,54.525 53.6509,54.3338 52.2757,54.1426 49.7674,52.7894 48.3013,51.0172 47.5149,48.3562 44.084,46.4303 41.7744,44.7264 40.229712,43.382062 c -1.841275,0.483307 -3.63078,0.512538 -4.719162,0.553894 z M 20.2129,59.3621 l -1.8114,-0.2845 2.1834,1.2358 0.7979,0.7999 -0.959,0.4474 0.8375,1.1781 -4.53735,1.23235 9.26255,-0.07345 -0.6792,-1.0003 -1.1888,-0.447 -2.1509,-2.3162 z"
            />
            <polygon
              fill="#D2D3D5"
              points="50.236,58.692 48.7077,58.3578 50.5499,59.8101 51.2231,60.7502 50.414,61.2759 51.1206,62.6605 48.3734,63.7782 55.1073,63.8021 54.5342,62.8469 53.5313,62.3216 51.7165,59.5994 "
            />
          </symbol>

          <symbol id="relief-hill-2" viewBox="-1 -3 8 8">
            <ellipse fill="#999999" opacity=".5" cx="3.0804" cy="1.8791" rx="3.0744" ry=".3351" />
            <path
              fill="#7C802D"
              d="M2.7066 2.0352c0.0507,0.0053 0.0814,0.0276 0.1716,0.0338 0.5063,0.0345 1.5714,0.0602 1.9067,0.0573 0.3454,-0.1594 0.4516,-0.1236 0.1251,-0.4413 -0.142,-0.1383 -0.3857,-0.2685 -0.4449,-0.445l-0.3952 -0.6303c-0.5295,-0.5285 -0.6505,-0.7655 -1.3587,-0.4881 -0.2085,0.0816 -0.6755,0.0267 -0.8319,0.2634l-0.1064 0.0747 -0.1172 0.0235c-0.4027,0.2433 -1.165,0.8134 -1.4213,1.1357l-0.2345 0.2948c0.1493,0.0717 0.0843,-0.008 0.4743,0.0567 0.457,0.0758 1.0204,0.045 1.4852,0.0258 0.1785,-0.0098 0.537,0.0316 0.7472,0.0391z"
            />
            <path
              fill="#5E6124"
              d="M2.6023 1.0536l-0.1404 0.0308c-0.1027,-0.1205 -0.2075,-0.2115 -0.2284,-0.3454 0.2548,-0.0401 0.1212,0.0112 0.2376,0.0467 0.1308,0.0398 0.0619,-0.0292 0.1811,0.0262l-0.0304 0.1357c0.1886,-0.1811 0.0078,-0.3317 -0.0091,-0.4026 -0.0391,-0.1638 0.0917,-0.1773 -0.2157,-0.278l0.1861 -0.0674c0.2433,-0.035 0.4954,-0.2367 0.7563,-0.1135 0.0247,0.102 0.0491,0.0185 -0.0945,0.1211l0.0182 0.2066c-0.0141,0.1059 0.0214,0.1189 0.0442,0.3253 -0.0849,0.0574 -0.1571,0.0022 -0.3924,0.2133 -0.1145,0.1028 -0.0609,0.0901 -0.117,0.1998 -0.192,-0.0115 -0.1789,-0.0559 -0.1957,-0.0985zm-0.717 -0.6732l-0.1064 0.0747c0.1659,-0.0352 0.0405,0.0015 0.2126,-0.0977 -0.0471,0.132 0.0295,0.1113 -0.1292,0.147 0.1093,0.0256 0.0542,0.088 0.143,0.1483 0.1134,0.0768 0.07,-0.0567 0.1355,0.1927l-0.231 0.0709c0.1175,0.1045 0.2102,0.1537 0.2187,0.3233l0.2335 0.0166c0.0212,0.3138 -0.0008,0.1036 0.0938,0.288 -0.554,0.1197 -0.1053,0.1818 -0.5379,0.335 -0.5313,0.1882 -0.116,-0.0362 -0.443,0.0326 -0.1434,0.0301 0.042,0.0205 -0.1569,0.0776l-0.0709 -0.1517c-0.0704,0.0825 -0.0367,0.0712 -0.147,0.1121 0.0237,-0.1353 0.0127,-0.0754 0.074,-0.1815 -0.1955,0.0511 -0.2431,0.1394 -0.2816,0.1683 -0.0758,-0.1022 -0.0395,-0.1305 -0.0228,-0.2436 -0.0666,0.0899 -0.3259,0.3423 -0.4274,0.1727 -0.0695,-0.1162 -0.0185,-0.0281 0.0143,-0.1466 -0.1384,0.0024 -0.1035,0.0215 -0.188,0.0967 -0.2089,0.1858 -0.1663,0.0597 -0.1691,0.0577 0.0822,-0.0433 0.0401,-0.051 0.0728,-0.1743l-0.1664 0.2098c0.1493,0.0716 0.0843,-0.0081 0.4743,0.0567 0.457,0.0758 1.0205,0.045 1.4852,0.0258l0.2521 0.0105c0.1099,-0.1237 0.2927,-0.0773 0.3491,-0.2155 0.0325,-0.0796 -0.0427,-0.0474 0.0393,-0.1802 0.0476,-0.0772 0.0738,-0.0848 0.1196,-0.1692 0.0972,0.0672 0.0236,-0.0283 0.0457,0.087 0.0974,-0.1136 0.0149,-0.095 0.1424,-0.1444 0.1799,0.2885 0.0065,0.2566 0.0484,0.3883l0.0449 0.1411 -0.1289 0.1598 0.2942 0.0283c0.0014,0.0015 1.6042,0.0246 1.6183,0.0245 0.3455,-0.1594 0.4516,-0.1235 0.1251,-0.4413 -0.142,-0.1383 -0.3857,-0.2685 -0.4449,-0.445l-0.3951 -0.6303c-0.5295,-0.5285 -0.6505,-0.7655 -1.3587,-0.4881 -0.2085,0.0816 -0.6755,0.0267 -0.8319,0.2634zm2.0893 0.8485c-0.203,-0.0475 -0.2461,-0.0572 -0.4053,-0.1224 0.037,0.0786 0.0872,0.1597 0.1271,0.2001 0.0069,0.007 0.4081,0.2545 0.0286,0.445 -0.0839,0.0421 0.05,0.0436 -0.0589,0.0158 -0.0212,-0.0749 -0.0325,-0.0905 0.0023,-0.1597 0.0447,-0.0888 -0.0636,-0.0997 0.1045,-0.0457l-0.0386 -0.0823c-0.0716,0.036 -0.1018,0.0039 -0.2222,0.0017 -0.3664,-0.0067 -0.1122,0.0492 -0.3972,-0.175 0.0735,-0.1454 0.116,-0.1461 0.207,-0.2434 0.0858,-0.1015 0.0882,-0.0059 0.3605,-0.0787 0.3528,-0.0923 0.2015,0.1027 0.3341,-0.0568l0.063 0.121c-0.1281,-0.0194 -0.145,-0.0264 -0.2099,0.0097 0.0084,0.0865 0.0021,0.101 0.005,0.1029l0.0999 0.0679z"
            />
          </symbol>

          <symbol id="relief-hill-3" viewBox="-1 -17 55 55">
            <ellipse fill="#999999" opacity=".5" cx="34.078" cy="14.5565" rx="17.5383" ry="2.4977" />
            <path
              fill="#7C802D"
              d="M9.5101 10.696c-1.1371,-0.616 -2.0817,0.8736 -2.3778,1.983 2.316,1.1116 1.9087,-0.5195 7.8443,1.2694 1.893,0.5705 5.3152,2.5047 7.2126,2.0188 0.7716,0.8915 -0.8074,0.2993 1.3361,0.9441 0.9262,0.2787 1.3524,0.1052 2.2303,-0.0233 4.793,-0.0412 7.0949,-0.2386 11.5203,-0.7434l9.7932 -2.476c0.058,-0.0401 0.1681,-0.1253 0.2451,-0.1968 -1.0428,-2.3377 -2.2374,-2.3426 -3.6846,-3.9623l-2.5719 -2.6229c-2.3783,-2.3827 -2.1842,-1.4462 -4.5382,-2.9906 -2.2547,-1.4793 -3.7909,-3.6402 -7.2099,-3.8961l-1.3963 0c-0.1659,0.0108 -0.3346,0.026 -0.5081,0.045 -2.9309,0.3275 -4.9194,0.7402 -7.3265,2.2081 -1.2629,0.7705 -1.0411,1.1393 -2.1929,1.1886 -2.1831,0.0949 -6.7923,-4.2893 -9.5649,0.1226 -1.5845,-0.5314 -1.9841,0.1518 -4.761,1.5807 -1.4169,0.7288 -3.1099,1.4918 -3.5599,3.176 1.6951,0.3942 2.4781,1.1593 4.7551,1.1713 1.6962,1.1225 3.5935,-0.5488 4.7551,1.2038z"
            />
            <path
              fill="#5E6124"
              d="M8.321 3.5643c1.3481,-0.5748 2.6842,-1.4527 3.9644,-1.2288 1.6561,1.0005 0.7922,0.3254 1.2266,2.7948 2.0888,0.0081 0.0933,-0.2196 2.2281,-0.3487 -0.892,0.7179 -0.9283,0.7283 -1.8719,1.7596l-2.3903 -0.7678c0.6073,1.6523 0.9847,1.9825 -0.7277,3.888 -0.0607,0.0678 -0.1708,0.1822 -0.2212,0.237 -0.0515,0.0553 -0.1648,0.147 -0.2267,0.2375 1.8529,-1.3361 2.7769,-1.6376 3.824,-2.7341 1.3556,-1.4202 1.7125,-1.5481 3.8148,-2.8886 3.2367,-2.0628 4.5246,-3.4715 9.8192,-3.7427 3.2389,0.0944 3.0377,0.7809 5.5457,2.0215 -0.5997,1.3828 0.4956,-0.1779 -1.6973,1.0981 3.3951,0.3883 1.9624,1.9847 3.766,1.906l0.9397 -0.116c0.4799,0.0428 1.4934,0.468 2.1311,0.6366 0.019,2.3203 0.4289,3.9227 0.597,6.4615 -1.7699,-0.6176 -1.3887,-0.9506 -2.8333,-1.8301 -0.9273,-0.5645 -2.0411,-0.8085 -3.15,-1.1978 0.8551,0.9175 0.9457,0.5368 1.9299,1.1523 0.969,0.6062 1.1333,1.0872 1.8242,1.7835l-1.3307 0.6377c-0.0607,0.0304 -0.1892,0.09 -0.2755,0.148 1.1523,0.7619 1.7352,0.783 2.7959,1.61 -0.815,0.5932 -0.2343,0.2527 -0.7272,1.0628l9.7932 -2.476c0.058,-0.0401 0.1681,-0.1253 0.2451,-0.1968 -1.0428,-2.3377 -2.2374,-2.3426 -3.6846,-3.9623l-2.5719 -2.6229c-2.3783,-2.3827 -2.1842,-1.4462 -4.5382,-2.9906 -2.2547,-1.4793 -3.7909,-3.6402 -7.2099,-3.8961l-1.3963 0c-0.1659,0.0108 -0.3346,0.026 -0.5081,0.045 -2.9309,0.3275 -4.9194,0.7402 -7.3265,2.2081 -1.2629,0.7705 -1.0411,1.1393 -2.1929,1.1886 -2.1831,0.0949 -6.7923,-4.2893 -9.5649,0.1226z"
            />
          </symbol>

          <symbol id="relief-hill-4" viewBox="-0.3 -2 5 5">
            <ellipse fill="#999999" opacity=".5" cx="2.6747" cy="1.0184" rx="1.9077" ry=".342" />
            <path
              fill="#5E6124"
              d="M2.2044 1.3541c-0.1954,-0.0321 -0.4239,0.0192 -0.6394,0.0064 -0.199,-0.0118 -0.3908,-0.0241 -0.5739,-0.0608 -0.0888,-0.01 -0.1874,-0.0432 -0.2716,-0.0656 -0.0826,-0.0219 -0.1876,-0.0277 -0.2635,-0.0505 -0.0536,-0.0161 -0.0695,-0.0305 -0.119,-0.0399 -0.0517,-0.0098 -0.0881,-0.0106 -0.1393,-0.0285 -0.0673,-0.0236 -0.1656,-0.0681 -0.1977,-0.1154 0.0201,-0.0316 0.0837,-0.0955 0.1144,-0.1309 0.1504,-0.1731 0.3051,-0.3572 0.5179,-0.4616 0.0654,-0.0321 0.1139,-0.0438 0.1651,-0.0802 0.0565,-0.0401 0.0848,-0.067 0.1373,-0.1072 0.0217,-0.0166 0.05,-0.0352 0.0699,-0.053 0.0345,-0.0309 0.0185,-0.032 0.0682,-0.0525 0.0626,-0.0548 0.1482,-0.0752 0.2398,-0.1026 0.1339,-0.0134 0.1379,-0.0191 0.2832,0.0039 0.0944,0.0149 0.1869,0.0288 0.2822,0.0441 0.2056,0.0328 0.3306,0.0881 0.4927,0.1654l0.1875 0.075c0.0209,-0.0159 0.023,0.0033 0,-0.0213 0.0257,0.006 0.0563,0.0125 0.0816,0.0194 0.0833,0.0185 0.1814,0.0344 0.2806,0.0163 0.1007,-0.0184 0.123,-0.0498 0.2495,-0.0498 0.3406,-0.0001 0.5977,0.1486 0.8473,0.3509 0.0315,0.0256 0.0537,0.0398 0.0763,0.0734 0.0448,0.0667 0.1432,0.2195 0.1361,0.2972 -0.2027,0.1549 -0.5328,0.094 -0.7013,0.1811 -0.0616,0.0318 -0.154,0.0618 -0.198,0.1013 -0.0952,0.0855 -0.0629,0.057 -0.2107,0.0749 -0.2659,0.0323 -0.0629,0.0115 -0.262,0.009 -0.0936,-0.0011 -0.1844,0.0171 -0.2669,0.0346 -0.035,0.0074 -0.2023,-0.0064 -0.2742,-0.0064 -0.0102,-0.0046 -0.0204,-0.0076 -0.0311,-0.0125 -0.0313,-0.0145 -0.018,-0.0082 -0.0332,-0.0185l-0.0477 0.0043z"
            />
            <path
              fill="#7C802D"
              d="M2.5582 0.2788c0.0257,0.006 0.0563,0.0125 0.0816,0.0194l-0.0467 0.0148c0.0989,0.0238 0.1701,0.0383 0.2783,0.0346 0.0927,-0.0032 0.1605,-0.0355 0.2563,-0.0416 0.0059,0.0681 0.0125,0.0546 0.0803,0.0661l0.3034 0.0735c0.2633,0.0879 0.1601,0.091 0.2872,0.1905 -0.0072,-0.0011 -0.2077,-0.1381 -0.2253,-0.0385 -0.007,0.0395 -0.0011,0.0619 0.043,0.0938 0.0291,0.0211 0.0671,0.0438 0.088,0.0405 -0.0384,0.0004 -0.0569,0.0018 -0.0921,-0.004 -0.024,-0.0039 0.0064,-0.0164 -0.0725,-0.0038 -0.0034,0.0005 -0.0099,0.0081 -0.0124,0.0042 -0.0042,-0.0066 -0.0582,0.0303 0.0019,0.1273 -0.0375,-0.0202 -0.0361,-0.0156 -0.0868,-0.0167 -0.0071,0.0087 -0.0283,0.0056 -0.0238,0.0831 -0.0556,0.0012 -0.0535,0.009 -0.0913,0.0299 0.0024,0.077 0.0051,0.0621 0.0496,0.0999 0.0394,0.0335 0.0647,0.125 0.1648,0.0333l0.0588 -0.0499c0,0 0.0278,0.0448 0.0854,0.0231 0.0806,-0.0303 0.0129,-0.1125 0.0099,-0.1178 0.0355,0.0244 0.0617,0.086 0.0845,0.1037 0.0046,0.0035 -0.0166,0.0192 0.0438,0.016 0.0518,-0.0028 0.0194,0.008 0.0396,-0.0218 0.0158,-0.0234 0.0088,-0.0578 0.0079,-0.0856 0.0039,0.0148 0.0561,0.1419 0.1436,0.1089 0.0935,-0.0353 -0.0041,-0.1155 -0.0211,-0.1773 0.0367,0.0117 0.0589,0.0515 0.0853,0.0766 0.0256,0.0244 0.1168,0.0761 0.1231,-0.0023l0.027 0.0273c-0.2027,0.1549 -0.5328,0.094 -0.7013,0.1811 -0.0616,0.0318 -0.154,0.0618 -0.198,0.1013 -0.0952,0.0855 -0.0629,0.057 -0.2107,0.0749 -0.2659,0.0323 -0.0629,0.0115 -0.262,0.009 -0.0936,-0.0011 -0.1844,0.0171 -0.2669,0.0346 -0.035,0.0074 -0.2023,-0.0064 -0.2742,-0.0064 -0.0102,-0.0046 -0.0204,-0.0076 -0.0311,-0.0125 -0.0313,-0.0145 -0.018,-0.0082 -0.0332,-0.0185 0.0891,0.0002 0.081,0.01 0.1771,-0.0035 0.0554,-0.0078 0.0792,0.0219 0.1781,0.0153 -0.0012,-0.1141 -0.0431,-0.1159 -0.0838,-0.1919 0.0736,0.0596 0.1594,0.1743 0.2952,0.1568 0.0087,-0.0222 0.019,-0.061 0.0253,-0.0724 0.0339,0.0425 0.0832,0.0686 0.1632,0.0681 0.0244,-0.0261 0.0098,0.0013 0.0138,-0.048 0.0333,0.0216 0.031,0.0326 0.0777,0.0235 0.076,-0.0149 0.0343,-0.0074 0.0465,-0.0393 -0.0461,-0.0577 -0.023,-0.0086 -0.0857,-0.0409l0.0014 -0.2034c-0.0355,0.0147 -0.0311,0.0231 -0.0523,0.0541 -0.0025,-0.0025 -0.0053,-0.0064 -0.0067,-0.0081l-0.169 -0.2127c-0.0859,-0.0724 -0.0239,-0.1127 -0.123,-0.0992l0.0251 0.0999c-0.1164,-0.0645 0.0039,-0.0841 -0.2276,-0.1398 -0.0076,-0.0589 0.0139,-0.0981 -0.0272,-0.134 -0.0531,-0.0464 -0.014,0.0293 -0.1724,-0.0642 0.0111,-0.0489 0.1259,-0.0586 0.032,-0.1513 -0.0164,-0.0162 -0.0359,-0.0275 -0.0442,-0.03l0.0589 0.004c0.0321,-0.0062 0.0135,0.0017 0.0356,-0.0132 0.0008,-0.0636 0.0089,-0.0413 -0.0194,-0.0945l0.1875 0.075c0.0209,-0.0159 0.023,0.0033 0,-0.0213zm-0.3538 1.0753c-0.1954,-0.0321 -0.4239,0.0192 -0.6394,0.0064 -0.199,-0.0118 -0.3908,-0.0241 -0.5739,-0.0608 -0.0888,-0.01 -0.1874,-0.0432 -0.2716,-0.0656 -0.0826,-0.0219 -0.1876,-0.0277 -0.2635,-0.0505 -0.0536,-0.0161 -0.0695,-0.0305 -0.119,-0.0399 -0.0517,-0.0098 -0.0881,-0.0106 -0.1393,-0.0285 -0.0673,-0.0236 -0.1656,-0.0681 -0.1977,-0.1154 0.0201,-0.0316 0.0837,-0.0955 0.1144,-0.1309 0.1504,-0.1731 0.3051,-0.3572 0.5179,-0.4616 0.0654,-0.0321 0.1139,-0.0438 0.1651,-0.0802 0.0565,-0.0401 0.0848,-0.067 0.1373,-0.1072 0.0217,-0.0166 0.05,-0.0352 0.0699,-0.053 0.0345,-0.0309 0.0185,-0.032 0.0682,-0.0525 0.0626,-0.0548 0.1482,-0.0752 0.2398,-0.1026 0.0123,0.038 0,0.0906 0.0726,0.0885 0.0489,-0.0014 0.0688,-0.0207 0.1504,-0.0092 0.1236,0.0175 0.1629,0.0134 0.2608,0.0655 -0.1347,0.3666 0.1384,0.2279 0.2222,0.2672 -0.0111,0.128 -0.062,-0.0039 -0.1137,0.1523 -0.0107,0.0323 0.0054,0.0077 -0.0132,0.034 -0.0641,-0.0115 -0.1919,-0.0698 -0.2164,-0.001 -0.0343,0.0963 0.0971,0.1029 0.151,0.1324 -0.027,0.0223 -0.0775,0.0132 -0.1011,0.0376 -0.0221,0.023 -0.0184,0.0643 -0.0172,0.1052l0.0784 0.0476c-0.0095,0.0791 -0.0071,0.0636 0.0043,0.144 -0.1394,-0.0074 -0.0164,-0.047 -0.164,-0.0413 -0.0305,0.1067 0.0115,-0.0011 0.0135,0.2172 -0.034,0.0162 -0.0766,0.0336 -0.0801,0.0769 0.0768,0.0049 0.0838,-0.0031 0.1494,-0.0132 0.0783,-0.012 0.066,0.0121 0.1545,0.0122 0.1465,0 0.2584,-0.0519 0.3406,0.0265z"
            />
          </symbol>

          <symbol id="relief-hill-5" viewBox="-5 -17 39 39">
            <ellipse fill="#999999" opacity=".5" cx="18.5104" cy="8.2102" rx="11.6925" ry="2.0964" />
            <path
              fill="#7C802D"
              d="M2.6664 8.569l6.6798 1.0468c1.4368,0.1034 1.6554,-0.5235 4.6148,-0.5235l3.4373 0.5804c2.3733,0.4005 4.8164,-0.0146 7.2145,-0.5751 0.893,-0.209 1.8708,-0.4082 2.0891,-1.2267 -0.6616,-0.4433 -3.0827,-0.9749 -3.4846,-1.2219l-3.9205 -4.6365c-1.6138,-1.5379 -2.386,-2.5369 -5.0705,-1.7203 -1.2608,0.3838 -2.6905,1.3614 -3.9599,1.9773 -0.9728,0.4719 -0.5971,-0.1545 -1.818,0.0743 -1.0217,0.1913 -1.2501,0.6291 -1.4676,1.1634 -2.2544,0.5262 -1.6372,0.4547 -3.4443,1.9663 -0.9647,0.8068 -3.2527,1.1607 -3.5364,2.2228l0.6095 0.2632 2.0569 0.6095z"
            />
            <path
              fill="#5E6124"
              d="M6.9807 3.5071c0.8323,-0.3105 1.0225,-0.6742 1.5214,-0.5228 -0.1684,0.4101 -0.1168,0.2931 -0.4328,0.582 -1.3408,1.2267 -0.4657,0.4693 -0.8362,1.7841 -0.4626,1.6418 -2.0311,1.1235 -2.0325,1.1235l0.0086 1.2088c-1.2701,-0.2257 -0.6401,-0.6776 -2.5429,0.8863 1.5832,0.7156 4.745,0.7674 6.6798,1.0468l2.1397 -0.914c-0.3337,-0.6582 -0.1337,-0.027 -0.3091,-0.8347 -0.4497,-2.0724 -0.3922,-0.2204 -0.0607,-2.8923 0.0067,-0.0798 0.0244,-0.1027 0.0533,-0.1459 0.2861,0.1328 0.5641,-0.224 0.5274,1.2952 -0.0105,0.4366 -0.1068,0.385 0.0406,0.8233 0.1839,0.5467 0.0712,0.2508 0.348,0.4693 -0.1223,-0.8276 0.1904,-1.5961 -0.0399,-2.3841 -0.1354,-0.4636 -0.3659,-0.461 -0.284,-2.0483l1.209 -0.5235c-0.9178,-0.4863 -1.294,-0.0822 -2.2687,0.0891l2.9155 -1.7906c1.1801,-0.417 2.3153,-0.8054 3.3989,-0.106l0.3676 0.7225c-0.5436,0.2446 -1.1201,0.39 -2.0258,0.3786 -0.562,0.7683 -0.8409,0.6506 -1.1381,0.8811 0.0779,1.2646 -0.0929,0.5594 0.5414,1.1361 1.0146,0.9226 0.1753,1.4158 0.0537,1.6489l-0.0229 0.9993c-1.8749,0.1574 -0.8842,0.3953 -1.0724,1.7156 -0.8787,0.3071 -0.4001,0.4079 -1.3277,0.1376l0.0762 0.2778 1.4927 0.5417c0.2479,0.2778 2.7858,0.5028 3.4373,0.5804 2.3898,0.2859 4.8164,-0.0146 7.2145,-0.5751 0.893,-0.209 1.8708,-0.4082 2.0891,-1.2267 -0.6616,-0.4433 -3.0827,-0.9749 -3.4846,-1.2219l-3.9205 -4.6365c-1.6138,-1.5379 -2.386,-2.5369 -5.0705,-1.7203 -1.3728,0.4175 -2.5522,1.2943 -3.9599,1.9773 -0.9728,0.4717 -0.5971,-0.1545 -1.818,0.0743 -1.0217,0.1913 -1.2501,0.6291 -1.4676,1.1634z"
            />
          </symbol>

          <symbol id="relief-dune-2" viewBox="-5 -17 40 40">
            <ellipse fill="#999999" opacity=".5" cx="17.1027" cy="5.3226" rx="17.1027" ry=".5194" />
            <polygon
              fill="#D8B976"
              points="15.2112,0 22.8169,2.667 30.4225,5.334 15.2112,5.334 -0,5.334 7.6057,2.667"
            />
            <path
              fill="#6D5924"
              d="M15.2112 0c-0.1987,1.1209 -3.4329,1.1587 -1.0819,2.2964 1.1972,0.5794 -1.7799,1.4239 -1.9267,1.5482 -0.5158,0.4369 -3.2959,1.0761 -3.4438,1.4894l6.4524 0 15.2113 0 -7.6057 -2.667 -7.6057 -2.667z"
            />
          </symbol>

          <symbol id="relief-deciduous-2" viewBox="-27 -25 70 70">
            <ellipse fill="#999999" opacity=".5" cx="9.3273" cy="18.4825" rx="5.534" ry="1.0889" />
            <polygon
              fill="#7C5125"
              points="8.6754,13.1329 9.4092,11.4084 10.6975,12.1523 8.8545,14.6027 9.3274,18.4825 6.2627,18.4825 6.8826,13.3966 5.2563,11.2344 6.4063,10.5705 7.0983,12.1967 8.2623,12.1967 8.5971,10.4211 9.2152,10.5814 8.5924,12.4519"
            />
            <path
              fill="#676A27"
              d="M 7.15625,0.001953 C 5.947743,0.051633 4.777378,0.866372 4.541016,2.291016 1.697616,1.720116 1.251953,5.136719 1.251953,5.136719 0.715975,5.415425 -0.025896,6.473322 0,7.443359 0.02091,8.22648 0.328216,8.934547 0.853516,9.435547 c -0.08115,0.334708 -0.002,1.216797 -0.002,1.216797 0.575571,2.696047 4.099448,3.07453 5.234376,0.447265 1.003399,0.3758 2.118546,0.375554 3.123046,0.002 0.0961,1.432601 1.233993,2.55516 2.746094,2.566407 1.485443,0.01105 2.604681,-1.013788 2.738281,-2.486328 1.9961,-0.5986 2.626179,-3.12715 1.142579,-4.59375 0.411446,-1.23286 0.403633,-1.864377 -0.51171,-2.949274 C 14.962812,3.227083 14.592119,2.82906 13.603479,2.761711 13.005579,1.152311 11.087816,0.485048 9.626916,1.347648 9.059872,0.387598 8.096163,-0.036697 7.156213,0.001945 Z"
            />
            <path
              fill="#5E6124"
              d="m 15.287006,3.6862427 c 0.780869,0.8257791 0.968452,1.9254248 0.493751,2.9018573 1.4836,1.4666 0.908743,3.9945 -1.087357,4.5931 -0.1336,1.3952 -1.3087,2.4863 -2.7389,2.4863 -1.4569,0 -2.6492,-1.1324 -2.7453,-2.565 C 8.2047,11.4761 7.0895,11.4745 6.0861,11.0987 5.0853,13.6233 1.48555,13.303294 0.92815,10.649694 6.1764485,10.111351 12.017072,7.3675453 15.287006,3.6862427 Z"
            />
          </symbol>

          <symbol id="relief-deciduous-3" viewBox="-27 -25 70 70">
            <ellipse opacity=".5" fill="#999999" ry="1.0889" rx="5.5339999" cy="18.4825" cx="9.3273001" />
            <polygon
              fill="#7c5125"
              points="10.6975,12.1523 8.8545,14.6027 9.3274,18.4825 6.2627,18.4825 6.8826,13.3966 5.2563,11.2344 6.4063,10.5705 7.0983,12.1967 8.2623,12.1967 8.5971,10.4211 9.2152,10.5814 8.5924,12.4519 8.6754,13.1329 9.4092,11.4084 "
            />
            <path
              fill="#676a27"
              d="M 7.15625,0.001953 C 5.947743,0.051633 4.777378,0.866372 4.541016,2.291016 1.697616,1.720116 1.251953,5.136719 1.251953,5.136719 0.715975,5.415425 -0.025896,6.473322 0,7.443359 0.02091,8.22648 0.328216,8.934547 0.853516,9.435547 c -0.08115,0.334708 -0.002,1.216797 -0.002,1.216797 0.575571,2.696047 4.099448,3.07453 5.234376,0.447265 1.003399,0.3758 2.118546,0.375554 3.123046,0.002 0.0961,1.432601 1.233993,2.55516 2.746094,2.566407 1.485443,0.01105 2.604681,-1.013788 2.738281,-2.486328 1.9961,-0.5986 2.626179,-3.12715 1.142579,-4.59375 0.411446,-1.23286 0.403633,-1.864377 -0.51171,-2.949274 C 14.962812,3.227083 14.592119,2.82906 13.603479,2.761711 13.005579,1.152311 11.087816,0.485048 9.626916,1.347648 9.059872,0.387598 8.096163,-0.036697 7.156213,0.001945 Z"
            />
            <path
              fill="#5e6124"
              d="m 15.287006,3.6862427 c 0.780869,0.8257791 0.968452,1.9254248 0.493751,2.9018573 1.4836,1.4666 0.908743,3.9945 -1.087357,4.5931 -0.1336,1.3952 -1.3087,2.4863 -2.7389,2.4863 -1.4569,0 -2.6492,-1.1324 -2.7453,-2.565 C 8.2047,11.4761 7.0895,11.4745 6.0861,11.0987 5.0853,13.6233 1.48555,13.303294 0.92815,10.649694 6.1764485,10.111351 12.017072,7.3675453 15.287006,3.6862427 Z"
            />
            <g fill="#d82e32">
              <circle r=".5" cy="8.3897734" cx="2.4284508" />
              <circle r=".5" cy="7.3032885" cx="7.146461" />
              <circle r=".5" cy="7.5826468" cx="13.668243" />
              <circle r=".5" cy="10.326545" cx="11.61261" />
              <circle r=".5" cy="6.656527" cx="10.684683" />
              <circle r=".5" cy="3.3609581" cx="7.6241026" />
              <circle r=".5" cy="5.1369228" cx="3.9471674" />
              <circle r=".5" cy="4.1185794" cx="11.777494" />
              <circle r=".5" cy="10.220185" cx="4.8988838" />
            </g>
          </symbol>

          <symbol id="relief-conifer-2" viewBox="-29 -22 72 72">
            <ellipse fill="#999999" ry="1.0889" rx="5.534" cy="22.0469" cx="9.257" opacity=".5" />
            <rect fill="#7c5125" height="3.8506" width="2.5553999" y="18.378901" x="6.1294999" />
            <path
              fill="#798136"
              d="M 7.4340812,0.00390625 2.7791,8.1383 l 1.8745,0 -2.8102,4.7786 1.4306,0 -3.274,5.7789 3.7081,0 -0.0157,0.1578 -0.163,1.6315 1.3679,-0.9533 1.1999,-0.836 1.3546874,-0.01105 z"
            />
            <path
              fill="#5e6124"
              d="m 10.4603,8.1383 2.7736,4.7786 -1.5107,0 3.2298,5.7789 -3.5851,0 c 0.0635,0.63718 0.127242,1.274336 0.1909,1.9115 L 10.1909,19.654 8.8229,18.7009 C 8.399397,18.690076 7.8667262,18.6958 7.4072,18.6958 L 7.43,0 12.1753,8.1383 Z"
            />
          </symbol>

          <symbol id="relief-coniferSnow-1" viewBox="-40 -33 100 100">
            <polygon
              fill="#5E6124"
              points="13.0568,9.9964 16.3335,15.6419 14.5424,15.6419 18.358,22.469 14.0011,22.469 14.2482,24.9424 12.2712,23.5647 10.6985,22.469 8.8946,22.469 8.9674,9.9964 8.9613,9.9964 9.1622,0 15.0838,9.9964"
            />
            <ellipse fill="#999999" opacity=".5" cx="11.2836" cy="26.2254" rx="6.5378" ry="1.2864" />
            <rect fill="#7C5125" x="7.5889" y="21.8921" width="3.0189" height="4.549" />
            <polygon
              fill="#798136"
              points="9.4642,22.469 7.6143,22.469 6.249,23.4203 4.2719,24.7981 4.5045,22.469 -0,22.469 3.8679,15.6419 2.1713,15.6419 5.4911,9.9964 3.2788,9.9964 9.1622,0"
            />
            <path
              fill="#FEFEFE"
              d="M9.1645 0.1661l-5.5338 9.6278 2.2145 0 -3.32 5.6454 1.6901 0 -3.8679 6.8272 4.3807 0 -0.0186 0.1863 -0.1925 1.9275 1.616 -1.1263 1.4176 -0.9875 1.7114 0c0.0137,-7.5342 -0.0142,-14.9526 -0.0976,-22.1004z"
            />
            <path
              fill="#ECF7FD"
              d="M12.7052 9.7939l3.2767 5.6454 -1.7848 0 3.8157 6.8272 -4.2354 0 0.033 0.3307 0.1925 1.9275 -1.616 -1.1263 -1.6161 -1.1259 0.0107 -0.006 -1.6832 0c0.0431,-7.3795 0.0651,-14.7237 0.0662,-22.1004l5.5668 9.6278 -2.0261 0z"
            />
            <path
              fill="#798136"
              stroke="#798136"
              stroke-width=".2031"
              d="M5.382 6.7803l1.2028 -0.4597 0.6743 0.7591 1.1928 -0.7537 0.6886 -0.4869 -0.0236 3.9382 -0.5649 -0.2914 -0.1883 -1.2452 -0.9216 1.4585 -0.5957 -0.869 -0.7633 1.4914 -0.2378 -0.5275 -2.2145 0 1.7513 -3.0137zm-0.6538 15.4862l-4.3807 0 1.2894 -2.276 1.6825 -0.6717 0.8906 1.9392 1.5138 -1.2771 0.6564 1.6879 2.7348 -2.4729 -0.0168 3.0706 -1.5476 0 -3.2789 2.5317 0.1949 -0.9859 0.2616 -1.5457zm-0.5128 -6.8272l-1.6901 0 1.4587 -2.4804 1.1049 0.4388 1.5138 -1.2771 0.6564 1.688 1.8856 -1.9374 -0.0278 4.6349 -0.8247 -1.2329 -1.1045 1.5003 -0.6628 -1.7146 -0.4418 0.9377 -0.7375 -0.0447 -1.8214 0.7077 0.6913 -1.2203z"
            />
            <path
              fill="#5E6124"
              stroke="#5E6124"
              stroke-width=".2031"
              d="M14.0011 22.469l4.3568 0 -1.7839 -2.7767 -1.5377 0.887 -0.7993 -0.7413 -0.8708 1.3664 -1.4648 -0.7323 -1.2246 -1.4677 -0.4951 1.9892 -1.0681 -1.5476 -0.0154 2.8204 1.6832 0 3.2215 2.2582 -0.0018 -2.0557zm-1.1308 -15.8666l-0.7194 -0.6033 -1.0493 0.4018 -1.9613 -0.5619 -0.0236 3.9382 0.8802 -1.233 1.1046 1.5004 0.6627 -1.7147 0.4418 0.9377 0.7733 -0.6162 1.9024 1.2841 -2.0115 -3.3332zm1.3696 8.837l1.742 0 -1.4841 -2.5568 -1.2975 0.5152 -1.0494 -0.6698 -1.0493 0.4019 -1.957 -1.2587 0.0278 4.6349 0.8246 -1.2329 1.1046 1.5003 0.6627 -1.7146 0.4418 0.9377 0.7733 -0.6163 1.9024 1.2841 -0.642 -1.2251z"
            />
          </symbol>

          <symbol id="relief-acacia-2" viewBox="-25 -25 70 70">
            <ellipse fill="#999999" opacity=".5" cx="11.8845" cy="14.9969" rx="9.8385" ry=".9674" />
            <polygon
              fill="#7C5125"
              points="10.5615,11.0945 10.5829,11.0945 12.2991,7.8722 10.169,4.0939 10.3125,4.0095 12.478,7.5361 13.4213,5.7652 13.4149,5.6589 13.4148,5.6586 13.4149,5.6586 13.3389,4.3771 13.6356,4.3312 13.934,5.5138 17.4746,4.5262 17.5871,4.7584 13.7287,6.092 11.3715,11.2549 11.3489,15.121 9.7272,15.121 10.2179,12.7528 7.0146,6.7865 2.9196,5.5604 2.9861,5.3123 6.8814,6.2337 6.9778,4.8164 7.2348,4.8164 7.3396,6.359 7.7405,6.9989 9.0507,3.8628 9.3276,3.9662 8.1262,7.6071 8.1199,7.6047 10.4554,11.3337 10.548,11.1601 "
            />
            <path
              fill="#798136"
              stroke="#798136"
              stroke-width=".2"
              d="M19.1214 5.4391c0.5257,0.1242 0.9419,0.0529 1.079,-0.2328 0.2248,-0.4681 -0.3854,-1.3347 -1.363,-1.9355 -0.2439,-0.1499 -0.4875,-0.2689 -0.7194,-0.3561 -0.3005,-0.7087 -1.5134,-1.4638 -3.0393,-1.8272 -0.9235,-0.22 -1.7867,-0.2549 -2.4361,-0.1335 -0.4996,-0.6097 -1.8962,-0.9589 -3.5411,-0.8166 -2.0623,0.1784 -3.7343,1.0619 -3.7373,1.9739 -0.2951,-0.0263 -0.6121,-0.0223 -0.9401,0.017 -1.2604,0.1508 -2.2744,0.7703 -2.4902,1.4642 -0.0553,0.0313 -0.1106,0.0641 -0.166,0.0981 -1.1534,0.7089 -1.8734,1.7313 -1.6082,2.2836 0.1971,0.4105 0.8831,0.4457 1.6957,0.1458 -0.5575,0.11 -0.9948,0.03 -1.1427,-0.2575 -0.2519,-0.4902 0.432,-1.3974 1.5277,-2.0263 0.0525,-0.0302 0.1053,-0.0591 0.1577,-0.0869 0.2049,-0.6158 1.1682,-1.1656 2.3657,-1.2994 0.3116,-0.0349 0.6127,-0.0385 0.893,-0.0151 0.0029,-0.8093 1.5913,-1.5931 3.5505,-1.7515 1.5626,-0.1263 2.8895,0.1836 3.364,0.7246 0.6169,-0.1076 1.4369,-0.0766 2.3142,0.1185 1.4496,0.3224 2.6018,0.9923 2.8873,1.6212 0.2203,0.0774 0.4517,0.1832 0.6833,0.3162 0.9287,0.5331 1.5084,1.302 1.2948,1.7174 -0.0934,0.1817 -0.3232,0.2658 -0.6298,0.258z"
            />
            <path
              fill="#5E6124"
              stroke="#5E6124"
              stroke-width=".2"
              d="M17.24 4.6771c0.136,0.1019 0.2845,0.1998 0.443,0.2908 0.9287,0.5331 1.8546,0.6285 2.0681,0.2131 0.3808,-0.7405 -1.3199,-1.8023 -1.9781,-2.0335 -0.6052,-1.333 -3.794,-1.9852 -5.2015,-1.7397 -1.2498,-1.425 -6.9085,-0.6433 -6.9145,1.0269 -1.0033,-0.0836 -2.9136,0.277 -3.2587,1.3145 -0.5348,0.2836 -2.068,1.3687 -1.6854,2.1132 0.4575,0.8898 2.5826,-0.2585 3.1902,-0.7762 0.5807,0.0788 1.2092,0.0303 1.7764,-0.1188 0.9067,0.5316 2.4273,0.3711 2.9534,-0.6075 1.2601,0.574 3.2016,0.6057 4.5418,0.2512 1.1523,0.2578 2.8891,0.2519 4.0653,0.0661z"
            />
          </symbol>

          <symbol id="relief-palm-2" viewBox="-27 -25 70 70">
            <ellipse fill="#999999" opacity=".5" cx="10.1381" cy="16.686" rx="6.176" ry="1.0271" />
            <path
              fill="#798136"
              d="M11.289 0.09c-1.2071,0.9898 -2.5231,2.5278 -3.1763,3.6163 -0.0463,-0.0865 -0.0877,-0.1708 -0.126,-0.2537l-6.5578 -1.8672c2.4316,-1.0619 4.8486,-1.347 6.2847,1.0194 -0.3892,-2.3401 2.8747,-2.8412 3.5754,-2.5147zm-11.289 7.6813l7.6896 -3.943c-3.1531,-1.6911 -7.1655,0.9025 -7.6896,3.943zm4.8314 3.1553c1.6467,-1.9 2.7841,-3.9718 2.7217,-6.4483 -3.3941,1.1324 -3.7342,4.899 -2.7217,6.4483zm6.5246 -0.3669c-1.8863,-2.4506 0.0568,-3.042 -3.0585,-5.9451 3.3784,-0.3062 5.1525,1.8059 3.0585,5.9451zm4.0962 -4.9207c-2.5616,-0.0001 -4.7634,-0.6542 -6.7787,-1.6477 4.523,-1.795 6.6868,0.7704 6.7787,1.6477zm1.1549 -4.3378l-7.9602 2.6334c0.8957,-3.4641 5.2694,-3.6955 7.9602,-2.6334z"
            />
            <path
              fill="#7C5125"
              d="M8.8323 5.3c0.3946,0 0.7145,-0.3199 0.7145,-0.7145 0,-0.3946 -0.3199,-0.7145 -0.7145,-0.7145 -0.0253,0 -0.0503,0.0013 -0.0749,0.0039 0.0473,-0.0954 0.0738,-0.203 0.0738,-0.3167 0,-0.3946 -0.3199,-0.7145 -0.7145,-0.7145 -0.3946,0 -0.7145,0.3199 -0.7145,0.7145 0,0.0844 0.0148,0.1653 0.0416,0.2405 -0.0427,-0.008 -0.087,-0.0122 -0.1321,-0.0122 -0.3946,0 -0.7145,0.3199 -0.7145,0.7145 0,0.3946 0.3199,0.7145 0.7145,0.7145 0.2723,0 0.509,-0.1524 0.6296,-0.3764 0.7194,3.9586 0.8226,7.8738 0.1215,11.7329l1.2482 0.0022c0.2847,-3.6277 0.2392,-7.3464 -0.6033,-11.2851 0.0404,0.0072 0.0821,0.0109 0.1246,0.0109z"
            />
          </symbol>

          <symbol id="relief-grass-2" viewBox="-50 -50 130 130">
            <path
              fill="#669A2C"
              d="M8.006 9.9689c0.01,0.1224 0.2562,0.6142 0.3168,0.7806 0.1951,0.5354 0.1473,0.2936 0.0182,0.823 -0.0735,0.3015 -0.1633,0.593 -0.2331,0.8796 -0.0469,0.1924 -0.1471,0.7957 -0.2314,0.9 -0.2344,-0.4506 -0.4442,-0.9086 -0.6939,-1.3471 -0.1591,-0.2793 -0.6042,-1.0566 -0.8075,-1.2337 -0.027,0.3721 0.3191,1.9295 0.4091,2.2876 0.2439,0.9703 0.4829,1.7317 0.7253,2.648 0.0492,0.1862 0.0075,0.4256 -0.003,0.6304 -0.0445,0.8712 -0.0559,1.7966 0.0131,2.6635 0.0307,0.3842 0.1223,0.8417 0.1284,1.2016l0.1024 0.5881c0.0029,0.0075 0.0086,0.0171 0.0112,0.0231 0.0026,0.0061 0.0069,0.0161 0.0121,0.0229 -0.0201,0.1409 0.3189,1.5864 0.3765,1.7054 0.0612,0.1268 0.0114,0.0405 0.0791,0.0918l-0.0379 -1.2668 0.0028 -1.5257c0.0722,-0.204 -0.0201,-1.142 0.0982,-1.4492l0.4611 1.6129c0.1818,0.5322 0.3534,1.028 0.5451,1.5638 0.0597,-0.071 0.0533,-0.0927 0.071,-0.2157 0.1947,-1.3511 0.0668,-2.8802 -0.189,-4.1914 -0.0678,-0.3476 -0.1555,-0.6369 -0.241,-0.9833 -0.0601,-0.2431 -0.2712,-0.7233 -0.2313,-0.9674 0.0582,-0.357 0.1448,-0.6613 0.2123,-1.0091 0.0546,-0.2811 0.1565,-0.7292 0.2424,-0.9837 0.1078,0.1108 0.4968,1.7381 0.5634,2.0399 0.3158,1.4317 0.4477,3.1118 0.644,4.58 0.0302,0.226 0.2616,2.1642 0.3146,2.3266 0.0248,-0.0338 0.0036,0.0249 0.0403,-0.076 0.0751,-0.2062 0.2653,-1.3853 0.2934,-1.5866 0.3244,-2.3247 0.1769,-5.002 -0.5336,-7.1701 -0.2609,-0.7959 -0.3821,-1.096 -0.7028,-1.7968 -0.0741,-0.162 -0.1159,-0.1782 -0.0489,-0.3857l0.4829 -1.5332c0.0488,-0.156 0.2436,-0.6378 0.256,-0.7337l0.1925 2.3718c0.0494,0.7686 0.1347,1.5966 0.2136,2.3623 0.0805,0.7816 0.1609,1.5731 0.2173,2.339 0.058,0.7884 0.183,1.5648 0.2406,2.343 0.0575,0.776 0.1742,1.5495 0.2513,2.3048l0.7845 6.9541c0.0617,-0.1477 0.9814,-6.953 0.9883,-7.0128 0.0893,-0.7707 0.2394,-1.5785 0.3252,-2.3506 0.112,0.5882 0.1575,1.1641 0.3065,1.7461 0.0398,0.1551 0.3674,1.4344 0.5327,1.5545l0.0617 -2.3153c0.0245,-0.3683 0.0303,-0.7359 0.0476,-1.1077 0.0447,-0.964 0.1773,-2.2719 0.3848,-3.1701 0.0875,-0.379 0.3809,-1.6006 0.5287,-1.8412 0.132,0.2798 0.2531,1.6127 0.2982,2.009 0.1201,1.0555 0.1258,3.4769 0.0559,4.556l-0.1185 2.2153c0.251,0.0329 0.9582,0.1558 1.1849,0.1215 0.0303,-0.0714 0.1058,-0.6785 0.1264,-0.8113 0.2594,-1.6732 0.4863,-3.3522 0.7616,-5.0316 0.0214,-0.1304 0.0473,-0.2766 0.0686,-0.4156 0.0157,-0.1018 0.0233,-0.2382 0.067,-0.3309 0.025,-0.0531 0.0105,-0.0337 0.04,-0.0694 0.1873,0.626 0.0716,1.8797 0.0618,2.5119l-0.1128 5.2565c-0.018,0.8181 -0.091,1.8066 -0.0418,2.6146 0.1147,-0.1814 1.3959,-4.3477 1.5767,-4.9006l0.7049 -2.0785c0.1608,-0.4479 0.3427,-0.9066 0.5472,-1.3256 0.1626,-0.333 0.5024,-0.8236 0.7601,-1.0852 0.3655,-0.3712 0.6129,-0.5671 1.2842,-0.5902 -0.8746,-0.4681 -1.8535,0.3689 -2.2598,0.7793 -0.2665,0.2692 -0.5145,0.5958 -0.7389,0.9385 -0.2337,0.357 -0.4033,0.6698 -0.6011,1.058 -0.1232,-0.266 0.0664,-1.8232 -0.6104,-3.5206 -0.4097,-1.0277 -0.4293,-0.7108 -0.2398,-1.5439 0.0682,-0.2999 0.1235,-0.5615 0.2058,-0.8484 0.0697,-0.2431 0.2306,-0.5792 0.2694,-0.7712 -0.4432,0.4059 -0.7179,1.2818 -0.9318,1.664 -0.0594,-0.0312 -0.2359,-0.3425 -0.2841,-0.4048 -0.0471,0.1146 0.1605,0.5585 0.1358,0.7746 -0.0102,0.0883 -0.2029,0.5981 -0.2507,0.7454l-0.4816 1.5262c-0.0598,-0.1425 -0.0699,-0.5906 -0.0856,-0.7876 -0.0761,-0.9568 -0.3857,-2.0152 -0.7118,-2.8963 -0.2156,-0.5824 -0.3107,-0.4252 -0.0598,-0.9737l0.4293 -0.9123 0.1352 -0.258c0.0352,-0.0635 0.0899,-0.1571 0.1339,-0.233 0.0651,-0.1123 0.2579,-0.3769 0.284,-0.4735 0.2499,-0.3174 0.4001,-0.6152 0.7209,-0.964 0.0946,-0.1028 0.2308,-0.2068 0.2869,-0.3007 -0.8031,0.1081 -1.9073,1.3062 -2.4276,1.9965 -0.0998,0.1323 -0.1788,0.2727 -0.268,0.3818 -0.0957,-0.0695 -0.3155,-0.5096 -0.4017,-0.6465 -0.1802,-0.2861 -0.0988,-0.3491 -0.0004,-0.8342 0.2597,-1.2819 0.6949,-2.7994 1.3548,-3.8989 0.1186,-0.1975 0.3456,-0.4924 0.4143,-0.6494 -0.4149,0.204 -1.1763,1.513 -1.4167,1.9752 -0.423,0.8133 -0.4558,1.0521 -0.7359,1.7951 -0.0367,0.0973 -0.1645,0.5451 -0.237,0.6227 -0.1537,-0.0895 -0.3924,-0.5679 -0.5678,-0.6617 0.0322,0.1402 0.1504,0.3661 0.2209,0.5158 0.3343,0.7092 0.2771,0.3999 -0.0743,1.7054 -0.2868,1.0653 -0.884,3.8898 -1.0382,4.9878 -0.0539,0.3833 -0.4366,2.3809 -0.427,2.5467 -0.0805,-0.394 -0.1065,-0.7929 -0.1571,-1.2144l-0.4637 -3.7082c-0.2118,-1.6323 -0.4588,-3.2351 -0.6682,-4.8653 -0.2162,-1.683 -0.2809,-0.8009 0.1957,-2.2675 0.0942,-0.2897 0.2658,-0.7185 0.3818,-1.009 0.1374,-0.3442 0.2404,-0.6702 0.3713,-1.0216 0.2551,-0.6852 0.52,-1.3285 0.761,-2.0231 0.1398,-0.4033 0.7296,-1.8322 0.763,-2.0313 -0.3354,0.1699 -1.918,3.0615 -2.2394,3.7079 -0.1032,0.2076 -0.2149,0.4192 -0.3313,0.6609 -0.0848,0.1764 -0.235,0.5506 -0.3346,0.6597 -0.0894,-0.1864 -0.3719,-2.7916 -0.3047,-3.4028 0.0097,-0.0873 0.0319,-0.1378 -0.0068,-0.208 -0.4978,1.4841 -0.1261,4.3856 -0.2115,4.7997l-0.7467 1.8056c-0.171,0.4381 -0.559,1.5984 -0.6942,1.89 -0.0155,-0.01 -1.3331,-1.7727 -2.0467,-1.9895 0.0785,0.1951 0.6092,0.8361 0.7782,1.2903l0.333 0.6734c0.0542,0.0927 0.0073,0.0353 0.0738,0.0817zm13.0512 11.8827c0.0536,-1.3603 -0.0071,-3.1476 0.8463,-4.2995 0.5114,-0.6901 0.6324,-0.5515 0.9169,-0.8091 -1.1337,-0.0648 -1.7274,1.0616 -2.0289,1.8806 -0.1635,0.4445 -0.2622,1.2108 -0.2241,1.7503 0.0323,0.4579 0.1972,1.2068 0.4898,1.4778zm-21.0572 -4.891c0.0398,0.1282 0.3436,0.3131 0.5603,0.529 0.5272,0.5249 1.061,1.1995 1.3065,1.9899 0.1823,0.587 0.3424,1.0807 0.4692,1.7194 0.0536,0.2706 0.3253,1.7034 0.3987,1.8101 0.1145,-0.2387 0.1545,-1.4669 0.1547,-1.841 0.0009,-1.3861 -0.4413,-3.0513 -1.5172,-3.8375 -0.144,-0.1052 -0.3813,-0.2519 -0.5644,-0.3128 -0.1371,-0.0457 -0.6992,-0.1375 -0.8078,-0.0572zm4.3825 -1.6528l-0.4513 -0.4783c-0.4141,-0.4094 -1.0223,-1.0085 -1.6092,-1.1756 0.5264,0.3551 1.5091,1.9709 1.8078,2.5966 0.1382,0.2897 0.0976,0.4283 0.0658,0.7851 -0.0512,0.5729 -0.0546,1.1227 -0.0848,1.7046l-0.7856 -1.203c-0.287,-0.4012 -0.563,-0.7655 -0.9027,-1.114 -0.3226,-0.331 -0.639,-0.6473 -1.0634,-0.9542 -0.2604,-0.1883 -0.9718,-0.6549 -1.3452,-0.6858 0.242,0.2369 0.4647,0.2793 1.0477,0.9271 0.327,0.3633 0.6136,0.7011 0.882,1.1349 1.0718,1.7321 1.4957,2.9592 2.1959,4.8201l1.3132 3.6646c0.0302,0.0453 0.014,0.0239 0.0449,0.053l-0.1851 -5.1476c0.1155,0.2152 0.2186,0.664 0.295,0.9284 0.0485,0.1672 0.2307,0.7957 0.309,0.9096l1.007 -0.2398c0.0172,-0.0049 0.0446,-0.0142 0.0623,-0.0223l0.0785 -0.0465 -1.0348 -6.081c-0.0483,-0.3585 -0.0857,-0.7015 -0.1213,-1.0675 -0.064,-0.6593 0.0266,-0.6608 0.0703,-1.0886 -0.6079,0.3463 -0.5436,2.7286 -0.5832,3.4022 -0.12,-0.1348 -0.2714,-0.5002 -0.2813,-0.7044 -0.0827,-1.707 0.1145,-3.1263 0.2169,-4.8307 0.018,-0.2998 0.0499,-0.6403 0.0772,-0.9377 0.0262,-0.2836 0.0851,-0.6533 0.0701,-0.9262l-0.3242 1.3574c-0.1432,0.7087 -0.7194,4.3376 -0.7718,4.4197zm10.1304 -2.9075c0.1037,-0.0678 0.1724,-0.3043 0.226,-0.4236 0.2754,-0.6141 0.3861,-0.5432 0.2613,-0.8881 -0.0539,-0.1494 -0.1004,-0.3571 -0.1914,-0.462 -0.0739,0.1333 -0.2958,1.5435 -0.2959,1.7736z"
            />
          </symbol>

          <symbol id="relief-swamp-2" viewBox="-15 -15 40 40">
            <path
              fill="#585142"
              d="M6.7214 3.6274l0.2974 -1.246c0.0125,0.0018 0.0257,0.0026 0.0392,0.0026l0.0722 0 0.0017 0 -0.2183 0.9141c-0.0646,0.1067 -0.1305,0.2187 -0.1923,0.3293zm0.6589 -2.7597l0.0731 -0.3064 0.1137 0 -0.0725 0.3037 -0.0017 0 -0.0722 0c-0.0135,0 -0.027,0.0009 -0.0403,0.0026z"
            />
            <path
              fill="#83340B"
              d="M7.4207 0.8651l0.0722 0c0.126,0 0.2104,0.0787 0.1873,0.175l-0.2791 1.169c-0.0229,0.0962 -0.1448,0.175 -0.2709,0.175l-0.0722 0c-0.126,0 -0.2104,-0.0787 -0.1874,-0.175l0.2791 -1.169c0.023,-0.0962 0.1449,-0.175 0.271,-0.175z"
            />
            <rect
              fill="#585142"
              transform="matrix(-0.939683 -0 0.0671203 0.763489 5.89737 4.35244E-05)"
              width=".1137"
              height="7.4462"
            />
            <rect
              fill="#83340B"
              transform="matrix(-0.939683 -0 0.0671203 0.763489 6.10204 0.303724)"
              width=".5305"
              height="1.9895"
              rx=".2292"
              ry=".2292"
            />
            <path
              fill="#5E6124"
              d="M5.6178 4.8049c-0.1679,-0.208 -0.383,-0.5796 -0.5433,-0.8263 -0.1936,-0.298 -0.4232,-0.5766 -0.5848,-0.8489l-0.9815 0.3056c-0.5605,-0.3496 -1.0382,-0.8091 -1.7154,-1.1437 0.1982,0.2144 0.5147,0.3846 0.7658,0.5837 0.2565,0.2034 0.4549,0.3975 0.7175,0.6332l-1.7204 0.7493c-0.2861,0.1365 -0.5417,0.2743 -0.7905,0.4197l-0.6765 0.422c-0.1001,0.095 0.0047,-0.0492 -0.0888,0.1093l1.6642 -0.8211c0.5858,-0.2699 1.1939,-0.4706 1.7655,-0.7272 0.3702,0.2065 2.2853,2.1742 2.4896,2.645 0.2815,0.0964 0.5399,0.0802 0.7835,-0.0071 0.1711,-1.0885 0.5199,-2.1608 1.1254,-3.1061 0.1892,-0.2953 0.4614,-0.6218 0.6108,-0.9103l-0.1471 0.1016c-0.4466,0.3599 -1.3762,1.709 -1.4848,2.1317 0.027,-0.3821 0.4922,-1.2446 0.6983,-1.6164 0.3692,-0.6659 0.7759,-1.1199 0.9917,-1.4896 -0.4499,0.2861 -1.2108,1.2966 -1.4397,1.6572 -0.1784,0.2813 -0.4033,0.6582 -0.5347,0.9472 -0.1451,0.3189 -0.2561,0.796 -0.3948,1.077 -0.4754,-1.2016 -0.9581,-3.1053 -2.1105,-4.1177 -0.0085,-0.0074 -0.1118,-0.0899 -0.1174,-0.0941l-0.185 -0.1184c0.2319,0.3027 0.4313,0.5344 0.6578,0.8699 0.4173,0.6178 1.1832,2.5842 1.2451,3.1745zm-1.9272 -1.2197c0.0276,0.0352 1.0203,0.8641 1.4665,1.3489l0.2084 0.187c0.0085,0.0062 0.0253,0.0173 0.0382,0.0257l-1.1212 -1.7614 -0.5918 0.1998z"
            />
            <path
              fill="#585142"
              d="M6.3074 6.8936c1.5063,0 2.7274,-0.1667 2.7274,-0.3725 0,-0.0972 -0.2722,-0.1856 -0.7181,-0.2518 0.2711,0.0449 0.43,0.0993 0.43,0.158 0,0.1539 -1.0921,0.2787 -2.4393,0.2787 -1.3473,0 -2.4395,-0.1248 -2.4395,-0.2787 0,-0.0587 0.1589,-0.1131 0.4301,-0.158 -0.4459,0.0663 -0.7182,0.1548 -0.7182,0.2518 0,0.2058 1.2212,0.3725 2.7275,0.3725z"
            />
            <path
              fill="#585142"
              d="M6.3074 6.6001c0.8298,0 1.5026,-0.0919 1.5026,-0.2052 0,-0.0535 -0.15,-0.1023 -0.3956,-0.1388 0.1494,0.0247 0.2369,0.0547 0.2369,0.0871 0,0.0847 -0.6016,0.1534 -1.3439,0.1534 -0.7422,0 -1.3439,-0.0687 -1.3439,-0.1534 0,-0.0324 0.0874,-0.0623 0.2368,-0.0871 -0.2455,0.0365 -0.3955,0.0852 -0.3955,0.1388 0,0.1133 0.6727,0.2052 1.5026,0.2052z"
            />
          </symbol>

          <symbol id="relief-swamp-3" viewBox="-4 -3.5 9 9">
            <rect
              fill="#585142"
              transform="matrix(-0.939683 -0 -0.0316337 0.763489 0.643293 9.91602E-06)"
              width=".0259"
              height="1.6965"
            />
            <rect
              fill="#83340B"
              transform="matrix(-0.939683 -0 -0.0316337 0.763489 0.680973 0.0691964)"
              width=".1209"
              height=".4533"
              rx=".0522"
              ry=".0522"
            />
            <path
              fill="#5E6124"
              d="M0.6587 1.102c0.1102,-0.2132 0.1717,-0.3927 0.3066,-0.6211 -0.0607,0.1599 -0.2665,0.6844 -0.2488,0.6649 0.2213,-0.2987 0.2022,-0.374 0.5309,-0.6322 -0.2144,0.2835 -0.3551,0.5968 -0.5235,0.886 -0.055,0.0555 -0.1634,0.0382 -0.2015,0.0031 -0.1446,-0.3525 -0.2572,-0.3752 -0.4702,-0.6162 0.1033,0.0385 0.3336,0.2256 0.3813,0.3151 -0.0476,-0.1539 -0.3112,-0.345 -0.4261,-0.4622 0.2831,0.0935 0.4085,0.3418 0.5708,0.5327 0.0455,-0.269 0.0508,-0.6339 0.2634,-0.8413 -0.1045,0.2155 -0.2096,0.543 -0.1829,0.7713z"
            />
            <path
              fill="#585142"
              d="M0.6214 1.5706c0.3432,0 0.6214,-0.038 0.6214,-0.0849 0,-0.0221 -0.062,-0.0423 -0.1636,-0.0574 0.0618,0.0102 0.098,0.0226 0.098,0.036 0,0.0351 -0.2488,0.0635 -0.5557,0.0635 -0.307,0 -0.5558,-0.0284 -0.5558,-0.0635 0,-0.0134 0.0362,-0.0258 0.098,-0.036 -0.1016,0.0151 -0.1636,0.0353 -0.1636,0.0574 0,0.0469 0.2782,0.0849 0.6214,0.0849z"
            />
            <path
              fill="#585142"
              d="M0.6214 1.5037c0.189,0 0.3423,-0.0209 0.3423,-0.0468 0,-0.0122 -0.0342,-0.0233 -0.0901,-0.0316 0.034,0.0056 0.054,0.0125 0.054,0.0198 0,0.0193 -0.1371,0.035 -0.3062,0.035 -0.1691,0 -0.3062,-0.0157 -0.3062,-0.035 0,-0.0074 0.0199,-0.0142 0.054,-0.0198 -0.0559,0.0083 -0.0901,0.0194 -0.0901,0.0316 0,0.0258 0.1533,0.0468 0.3423,0.0468z"
            />
          </symbol>

          <symbol id="relief-cactus-1" viewBox="-50 -38 120 120">
            <ellipse fill="#999999" opacity=".5" cx="11.6624" cy="30.5346" rx="11.2558" ry="1.3184" />
            <polygon
              fill="#E85051"
              points="10.5474,0 10.2885,0.8968 8.9818,0.1755 9.8281,1.8655 11.2667,1.8655 12.113,0.1755 10.8062,0.8968"
            />
            <path
              fill="#63C072"
              d="M18.8889 30.0026c0.3115,-0.3161 0.5627,-0.7559 0.7223,-1.2724 0.0619,0.0171 0.1258,0.0263 0.1913,0.0263 0.5329,0 0.9647,-0.5965 0.9647,-1.3324 0,-0.7359 -0.4318,-1.3326 -0.9647,-1.3326 -0.0655,0 -0.1293,0.0093 -0.1912,0.0263 -0.1171,-0.3791 -0.2837,-0.717 -0.4871,-0.9948 0.5401,-0.2953 1.1411,-0.8939 1.6308,-1.6806 0.854,-1.3719 1.0461,-2.7956 0.4288,-3.1801 -0.4598,-0.2862 -1.2385,0.0849 -1.9589,0.8593 0.0024,-0.0412 0.0037,-0.083 0.0037,-0.1254 0,-0.6869 -0.3358,-1.2436 -0.7499,-1.2436 -0.4141,0 -0.7498,0.5567 -0.7498,1.2436 0,0.6477 0.2987,1.1799 0.68,1.2382 -0.4346,0.7516 -0.6691,1.5041 -0.6797,2.0791l-0.0003 0c-0.5002,0 -0.9592,0.2657 -1.3173,0.7081 -0.0107,-0.0344 -0.0221,-0.069 -0.0344,-0.1036 -0.2936,-0.8281 -0.9175,-1.3628 -1.3935,-1.194 -0.476,0.1687 -0.6239,0.977 -0.3301,1.8053 0.2271,0.6405 0.6516,1.1054 1.0528,1.205 -0.0334,0.2219 -0.0513,0.4527 -0.0513,0.6898 0,1.0732 0.3624,2.0194 0.9136,2.5785 -0.5911,0.1126 -0.9827,0.3089 -0.9827,0.532l2.1429 0 2.1428 0c0,-0.2233 -0.3915,-0.4193 -0.9828,-0.532zm-10.9784 0.532l5.2738 0 0 -17.364 5.9327 0c1.0878,0 1.9778,-0.8898 1.9778,-1.9776l0 -3.9552c0,-1.0877 -0.89,-1.9777 -1.9778,-1.9777l0 0c-1.0877,0 -1.9776,0.89 -1.9776,1.9777l0 1.9776 -3.9551 0 0 -5.0493c0,-1.4503 -1.1867,-2.6367 -2.6369,-2.6367l0 0c-1.4504,0 -2.6369,1.1864 -2.6369,2.6367l0 14.0111 -3.9552 0 0 -1.9776c0,-1.0878 -0.89,-1.9778 -1.9776,-1.9778l0 0c-1.0878,0 -1.9777,0.89 -1.9777,1.9778l0 3.9552 0 0c0,1.0875 0.8899,1.9777 1.9777,1.9777l5.9328 0 0 8.4021zm13.1843 -19.3416l0 0z"
            />
            <path
              fill="#5BAB68"
              d="M18.8889 30.0026c0.3115,-0.3161 0.5627,-0.7559 0.7223,-1.2724 0.0619,0.0171 0.1258,0.0263 0.1913,0.0263 0.5329,0 0.9647,-0.5965 0.9647,-1.3324 0,-0.7359 -0.4318,-1.3326 -0.9647,-1.3326 -0.0655,0 -0.1293,0.0093 -0.1912,0.0263 -0.1171,-0.3791 -0.2837,-0.717 -0.4871,-0.9948 0.5401,-0.2953 1.1411,-0.8939 1.6308,-1.6806 0.854,-1.3719 1.0461,-2.7956 0.4288,-3.1801 -0.1593,-0.0992 -0.3572,-0.1194 -0.5773,-0.0713 0.0585,0.016 0.1135,0.0395 0.1646,0.0713 0.6172,0.3845 0.4252,1.8082 -0.4289,3.1801 -0.4896,0.7867 -1.0906,1.3853 -1.6308,1.6806 0.2035,0.2778 0.3701,0.6157 0.4872,0.9948 0.0619,-0.017 0.1257,-0.0263 0.1912,-0.0263 0.5328,0 0.9647,0.5967 0.9647,1.3326 0,0.7359 -0.4319,1.3324 -0.9647,1.3324 -0.0655,0 -0.1294,-0.0092 -0.1914,-0.0263 -0.1595,0.5165 -0.4107,0.9563 -0.7222,1.2724 0.5913,0.1127 0.9828,0.3087 0.9828,0.532l0.4127 0c0,-0.2233 -0.3915,-0.4193 -0.9828,-0.532zm-16.5174 -7.9252c0.896,-0.1875 1.5746,-0.9864 1.5746,-1.9361l0 -3.9552c0,-0.9608 -0.6946,-1.7673 -1.6065,-1.9423l0 0.0115 0 1.9308 0 0.5782 0 2.8041 0.0319 0 0 2.509zm9.2062 8.4572l1.6064 0 0 -17.364 0.0002 0c0,-1.3183 0,-2.6369 0,-3.9552l-0.0002 0 0 -5.0493c0,-1.0851 -0.6643,-2.0226 -1.6064,-2.4258l0 2.4258c0,8.7895 0,17.5791 0,26.3685zm7.9425 -17.4055c0.8961,-0.1875 1.5746,-0.9864 1.5746,-1.9361l0 -3.9552c0,-0.9609 -0.6946,-1.7673 -1.6065,-1.9423l0 0.0114 0 1.9309 0 0.5782 0 2.804 0.0319 0 0 2.5091zm-0.308 7.6085c-0.0718,-0.5627 -0.373,-0.985 -0.7335,-0.985 -0.0716,0 -0.1408,0.0166 -0.2064,0.0477 0.3138,0.1486 0.5436,0.6278 0.5436,1.1959 0,0.0424 -0.0013,0.0842 -0.0038,0.1254 0.1322,-0.1422 0.2662,-0.2706 0.4001,-0.384zm-2.916 3.9775c-0.3167,-0.7104 -0.8766,-1.1457 -1.3125,-0.9911l-0.0145 0.0057c0.3836,0.1275 0.779,0.5782 0.9953,1.1883 0.0122,0.0346 0.0237,0.0692 0.0344,0.1036 0.0927,-0.1144 0.192,-0.2172 0.2973,-0.3065z"
            />
          </symbol>

          <symbol id="relief-cactus-2" viewBox="-49 -41 120 120">
            <polygon
              fill="#E68139"
              points="3.9483,14.2784 3.6984,15.1439 2.4374,14.4478 3.2541,16.0787 4.6425,16.0787 5.4592,14.4478 4.1982,15.1439"
            />
            <ellipse fill="#BDBFC1" cx="10.5348" cy="27.9924" rx="10.5348" ry="1.2724" />
            <path
              fill="#63C072"
              d="M9.1307 27.9925l5.0895 0 0 -12.5588 5.7257 0c1.0497,0 1.9085,-0.8588 1.9085,-1.9085l0 -3.8172c0,-1.0497 -0.8589,-1.9085 -1.9085,-1.9085l0 0c-1.0497,0 -1.9086,0.8589 -1.9086,1.9085l0 1.9086 -3.8171 0 0 -9.0718c0,-1.3996 -1.1452,-2.5448 -2.5448,-2.5448l0 0c-1.3996,0 -2.5447,1.1452 -2.5447,2.5448 0,8.4826 0,16.9651 0,25.4477zm12.7238 -14.4674l0 0z"
            />
            <path
              fill="#63C072"
              d="M6.8427 23.5745c0.5187,0.1819 1.2323,-0.5066 1.5937,-1.5377 0.3614,-1.031 0.2339,-2.0143 -0.2848,-2.1961 -0.5187,-0.1819 -1.2322,0.5066 -1.5937,1.5376 -0.0555,0.1582 -0.0994,0.3153 -0.1322,0.4685 -0.204,-0.4516 -0.4675,-0.7946 -0.7661,-0.98 0.3423,-0.5575 0.5494,-1.2841 0.5494,-2.0787 0,-1.7568 -1.0122,-3.1809 -2.2607,-3.1809 -1.2487,0 -2.2608,1.4241 -2.2608,3.1809 0,1.6948 0.942,3.0799 2.1296,3.1755 -0.243,0.5892 -0.3889,1.3428 -0.3889,2.1642 0,1.3665 0.4035,2.5453 0.9868,3.0916 -0.7731,0.0885 -1.3212,0.3101 -1.3212,0.5695l4.1359 0c0,-0.2624 -0.5609,-0.4862 -1.3481,-0.5725 0.5814,-0.5476 0.9836,-1.7246 0.9836,-3.0886 0,-0.1884 -0.0078,-0.3732 -0.0226,-0.5533l0.0001 0z"
            />
            <path
              fill="#5BAB68"
              d="M5.4882 20.7795c0.2721,-0.5451 0.4349,-1.2376 0.4349,-1.9914 0,-1.7568 -0.8841,-3.1809 -1.9747,-3.1809 -0.666,0 -1.2058,1.4241 -1.2058,3.1809 0,1.6442 0.4729,2.997 1.0795,3.1636l0.0165 -0.0389c-0.2703,-0.2796 -0.4747,-1.5721 -0.4747,-3.1247 0,-1.7568 0.2617,-3.1809 0.5846,-3.1809 0.949,0 1.7183,1.4241 1.7183,3.1809 0,0.73 -0.1329,1.4025 -0.3563,1.9394 0.0602,0.0113 0.1195,0.0288 0.1778,0.0521zm-0.3414 6.7643c0.829,-0.0001 1.501,-1.5294 1.501,-3.416 0,-0.2568 -0.0125,-0.5069 -0.0361,-0.7475 0.0607,0.0945 0.1379,0.1615 0.2312,0.1942 0.134,0.0471 0.5357,-0.7507 0.8972,-1.7818 0.3615,-1.031 0.5458,-1.9049 0.4117,-1.952 -0.3943,-0.1382 -1.007,0.5856 -1.3684,1.6166 -0.1717,0.49 -0.2558,0.9611 -0.2545,1.3355 0.0303,0.1617 0.055,0.3297 0.0741,0.5031 0.0525,0.1431 0.1326,0.241 0.24,0.2787 0.2765,0.097 0.7938,-0.6602 1.1553,-1.6913 0.3615,-1.0311 0.4303,-1.9455 0.1536,-2.0425 -0.4531,-0.1588 -1.1134,0.5483 -1.4748,1.5793 -0.1272,0.3627 -0.2004,0.7172 -0.2221,1.0313 -0.2575,-1.0382 -0.7467,-1.7393 -1.308,-1.7393 -0.5062,0 -0.9165,1.5293 -0.9165,3.4159 0,1.8866 0.4103,3.416 0.9165,3.416zm0 -6.8319c-0.2454,0 -0.4444,1.5293 -0.4444,3.4159 0,1.8866 0.1989,3.416 0.4444,3.416 0.7213,-0.0001 1.3062,-1.5294 1.3062,-3.416 0,-1.8865 -0.5848,-3.4159 -1.3062,-3.4159zm0 0c-0.8291,0 -1.5012,1.5293 -1.5011,3.4159 0,1.8866 0.672,3.416 1.5011,3.416 0.2454,-0.0001 0.4442,-1.5294 0.4442,-3.416 0,-1.8865 -0.1988,-3.4159 -0.4442,-3.4159 -0.7215,0 -1.3062,1.5293 -1.3062,3.4159 0,1.8866 0.5848,3.416 1.3062,3.416 0.5061,-0.0001 0.9164,-1.5294 0.9164,-3.416 0,-1.8865 -0.4103,-3.4159 -0.9164,-3.4159zm1.696 2.8626c0.453,0.1588 1.1133,-0.5482 1.4748,-1.5794 0.3615,-1.031 0.2871,-1.9956 -0.1659,-2.1545 -0.2767,-0.097 -0.794,0.6602 -1.1555,1.6912 -0.3615,1.0312 -0.4302,1.9456 -0.1535,2.0426zm1.3089 -3.7338c-0.1341,-0.047 -0.5359,0.7507 -0.8974,1.7817 -0.3614,1.0311 -0.5458,1.9051 -0.4115,1.9521 0.3942,0.1382 1.0069,-0.5856 1.3683,-1.6167 0.3615,-1.031 0.3349,-1.9789 -0.0593,-2.1171zm-4.2034 -4.2335c-1.0907,0 -1.9748,1.4241 -1.9748,3.1809 0,1.6862 0.8144,3.0656 1.8442,3.1738l0.0008 -0.0019c-0.8884,-0.1229 -1.5886,-1.496 -1.5886,-3.172 0,-1.7568 0.7693,-3.1809 1.7184,-3.1809 0.3228,0 0.5845,1.4241 0.5845,3.1809 0,0.9114 -0.0705,1.7331 -0.1833,2.313 0.1684,-0.1756 0.3532,-0.2971 0.5486,-0.3534 0.1603,-0.5401 0.2558,-1.2204 0.2558,-1.9596 0,-1.7568 -0.5398,-3.1809 -1.2057,-3.1809z"
            />
            <path
              fill="#5BAB68"
              d="M12.5713 27.9925l1.649 0c0,-11.8861 0,-14.658 0,-25.4477 0,-1.0847 -0.688,-2.0165 -1.649,-2.381l0 27.6858 0 0.1428zm8.1168 -12.7099c0.6837,-0.291 1.1664,-0.9707 1.1664,-1.7575l0 -3.8172c0,-0.7868 -0.4827,-1.4665 -1.1664,-1.7575l0 7.3322zm1.1664 -1.7575l0 0z"
            />
          </symbol>

          <symbol id="relief-cactus-3" viewBox="-50 -41 120 120">
            <ellipse fill="#999999" opacity=".5" cx="11.8434" cy="27.4564" rx="10.1211" ry="1.1855" />
            <path
              fill="#63C072"
              d="M22.2067 13.2778l-0.7113 0 -1.1706 0 0 4.5937c0,0.978 -0.8002,1.7782 -1.7783,1.7782l-5.3348 0 0 7.8067 -4.742 0 0 -7.5551 -3.6988 0c-0.978,0 -1.7783,-0.8002 -1.7783,-1.7783l0 0 0 -2.7652 -1.57 0 -0.7113 0c-0.0061,0 -0.0122,0 -0.0183,-0.0002 -0.0061,-0.0001 -0.0121,-0.0004 -0.0182,-0.0007 -0.006,-0.0003 -0.012,-0.0007 -0.018,-0.0011 -0.006,-0.0005 -0.012,-0.001 -0.018,-0.0017 -0.0059,-0.0006 -0.0118,-0.0012 -0.0178,-0.002 -0.0059,-0.0008 -0.0118,-0.0016 -0.0176,-0.0025 -0.0059,-0.0009 -0.0118,-0.0019 -0.0176,-0.0029l0 0c-0.0058,-0.0011 -0.0116,-0.0022 -0.0174,-0.0034 -0.0058,-0.0011 -0.0115,-0.0024 -0.0172,-0.0038l0 0c-0.0057,-0.0013 -0.0114,-0.0027 -0.0171,-0.0042l0 0c-0.0057,-0.0014 -0.0113,-0.0029 -0.0169,-0.0046l-0.0001 0c-0.0056,-0.0015 -0.0111,-0.0033 -0.0167,-0.005l0 0c-0.0056,-0.0017 -0.0111,-0.0035 -0.0166,-0.0054l-0.0164 -0.0058 0 0 -0.0162 -0.0062 -0.0161 -0.0066c-0.0053,-0.0022 -0.0106,-0.0046 -0.0158,-0.0069l0 0c-0.0053,-0.0024 -0.0105,-0.0049 -0.0157,-0.0074l-0.0154 -0.0077 -0.0152 -0.008c-0.0051,-0.0028 -0.0101,-0.0056 -0.015,-0.0085l-0.0148 -0.0087 0 0c-0.0049,-0.003 -0.0097,-0.006 -0.0146,-0.0091 -0.0048,-0.0031 -0.0095,-0.0063 -0.0143,-0.0095 -0.0047,-0.0032 -0.0094,-0.0064 -0.014,-0.0097l-0.0001 0c-0.0046,-0.0034 -0.0092,-0.0067 -0.0138,-0.0101l-0.0135 -0.0105 -0.0001 0c-0.0044,-0.0035 -0.0089,-0.0071 -0.0133,-0.0107l-0.013 -0.0111 0 0c-0.0043,-0.0037 -0.0086,-0.0075 -0.0128,-0.0113l-0.0125 -0.0117 0 0 -0.0122 -0.0119 -0.0001 0 -0.0119 -0.0122c-0.0039,-0.0041 -0.0078,-0.0083 -0.0116,-0.0125l-0.0001 0 -0.0113 -0.0128 -0.011 -0.0131 -0.0108 -0.0133c-0.0035,-0.0045 -0.007,-0.009 -0.0104,-0.0136l-0.0101 -0.0138c-0.0033,-0.0047 -0.0066,-0.0093 -0.0098,-0.0141 -0.0032,-0.0047 -0.0064,-0.0095 -0.0094,-0.0143l-0.0091 -0.0145c-0.003,-0.0049 -0.0059,-0.0099 -0.0088,-0.0148l-0.0084 -0.015c-0.0028,-0.0051 -0.0054,-0.0101 -0.0081,-0.0153l-0.0077 -0.0154c-0.0025,-0.0052 -0.0049,-0.0104 -0.0073,-0.0156 -0.0024,-0.0053 -0.0047,-0.0106 -0.007,-0.0159 -0.0023,-0.0053 -0.0044,-0.0106 -0.0065,-0.016 -0.0022,-0.0054 -0.0043,-0.0108 -0.0063,-0.0162l-0.0058 -0.0165c-0.0018,-0.0055 -0.0036,-0.011 -0.0054,-0.0165 -0.0017,-0.0056 -0.0034,-0.0112 -0.005,-0.0168l-0.0046 -0.0169c-0.0015,-0.0057 -0.0029,-0.0114 -0.0042,-0.0171 -0.0013,-0.0057 -0.0026,-0.0115 -0.0038,-0.0173 -0.0012,-0.0058 -0.0023,-0.0115 -0.0033,-0.0174 -0.0011,-0.0058 -0.0021,-0.0116 -0.003,-0.0175 -0.0009,-0.0059 -0.0017,-0.0118 -0.0025,-0.0177 -0.0007,-0.0059 -0.0014,-0.0118 -0.002,-0.0178 -0.0006,-0.006 -0.0012,-0.012 -0.0016,-0.0179 -0.0005,-0.006 -0.0009,-0.012 -0.0012,-0.0181 -0.0003,-0.006 -0.0005,-0.0121 -0.0007,-0.0182 -0.0001,-0.006 -0.0002,-0.0121 -0.0002,-0.0183l0 -0.7113 0 -1.9228c0,-0.3912 0.3201,-0.7113 0.7113,-0.7113l0 0c0.3912,0 0.7113,0.3201 0.7113,0.7113l0 1.9228 1.57 0 0 -4.0946c0,-0.978 0.8003,-1.7783 1.7783,-1.7783l0 0c0.978,0 1.7783,0.8003 1.7783,1.7783l0 6.5042 1.9205 0 0 -12.5985c0,-1.3041 1.0669,-2.3711 2.371,-2.3711l0 0c1.3041,0 2.371,1.067 2.371,2.3711l0 2.5355 1.9971 0 0 -1.9229c0,-0.3912 0.3202,-0.7113 0.7114,-0.7113l0 0c0.3912,0 0.7113,0.3201 0.7113,0.7113l0 1.9229 0 0.7113c0,0.0061 -0.0001,0.0122 -0.0003,0.0182 -0.0001,0.0061 -0.0003,0.0122 -0.0006,0.0182 -0.0004,0.0061 -0.0007,0.0121 -0.0012,0.0181 -0.0005,0.006 -0.001,0.0119 -0.0016,0.0179 -0.0006,0.006 -0.0013,0.0119 -0.0021,0.0178 -0.0007,0.0059 -0.0016,0.0118 -0.0025,0.0177 -0.0009,0.0059 -0.0018,0.0117 -0.0029,0.0176 -0.001,0.0058 -0.0021,0.0116 -0.0033,0.0173 -0.0012,0.0058 -0.0025,0.0116 -0.0038,0.0173 -0.0014,0.0057 -0.0028,0.0114 -0.0042,0.0171l-0.0046 0.0169c-0.0016,0.0056 -0.0033,0.0112 -0.0051,0.0168 -0.0017,0.0055 -0.0035,0.0111 -0.0054,0.0166l-0.0058 0.0164c-0.002,0.0054 -0.0041,0.0108 -0.0062,0.0162 -0.0021,0.0054 -0.0043,0.0107 -0.0065,0.016 -0.0023,0.0053 -0.0046,0.0107 -0.007,0.0159 -0.0024,0.0052 -0.0049,0.0104 -0.0073,0.0156l-0.0077 0.0155c-0.0027,0.0051 -0.0054,0.0102 -0.0081,0.0152l-0.0084 0.015c-0.0029,0.0049 -0.0058,0.0099 -0.0088,0.0148l-0.0091 0.0145c-0.0031,0.0048 -0.0062,0.0096 -0.0094,0.0143 -0.0032,0.0048 -0.0065,0.0095 -0.0098,0.0141l-0.0101 0.0138c-0.0034,0.0046 -0.0069,0.0091 -0.0104,0.0136l-0.0108 0.0133 -0.011 0.0131 -0.0114 0.0128 0 0c-0.0038,0.0042 -0.0077,0.0084 -0.0116,0.0125 -0.004,0.0041 -0.008,0.0082 -0.012,0.0122l-0.0122 0.012 0 0 -0.0125 0.0116c-0.0042,0.0039 -0.0085,0.0076 -0.0128,0.0114l0 0 -0.0131 0.011c-0.0044,0.0036 -0.0088,0.0072 -0.0133,0.0107l0 0 -0.0135 0.0105c-0.0046,0.0034 -0.0092,0.0068 -0.0139,0.0101l0 0c-0.0046,0.0033 -0.0093,0.0065 -0.014,0.0097 -0.0048,0.0032 -0.0096,0.0064 -0.0144,0.0095 -0.0048,0.0031 -0.0096,0.0061 -0.0145,0.0091l0 0 -0.0148 0.0088c-0.005,0.0028 -0.01,0.0056 -0.015,0.0084l-0.0152 0.008 -0.0155 0.0077c-0.0052,0.0026 -0.0103,0.005 -0.0156,0.0074l0 0 -0.0159 0.0069 -0.016 0.0066 -0.0162 0.0062 0 0 -0.0164 0.0058c-0.0055,0.0019 -0.011,0.0037 -0.0166,0.0054l0 0c-0.0056,0.0018 -0.0112,0.0035 -0.0168,0.0051l0 0c-0.0056,0.0016 -0.0112,0.0031 -0.0169,0.0046l0 0c-0.0057,0.0014 -0.0114,0.0028 -0.0171,0.0042l0 0c-0.0057,0.0013 -0.0115,0.0026 -0.0173,0.0038 -0.0057,0.0011 -0.0115,0.0023 -0.0173,0.0033l-0.0001 0c-0.0058,0.001 -0.0116,0.002 -0.0175,0.0029 -0.0059,0.0009 -0.0118,0.0018 -0.0177,0.0025 -0.0059,0.0008 -0.0118,0.0015 -0.0178,0.0021 -0.0059,0.0006 -0.0119,0.0011 -0.0179,0.0016 -0.006,0.0004 -0.012,0.0008 -0.0181,0.0011 -0.006,0.0003 -0.0121,0.0006 -0.0181,0.0007 -0.0061,0.0002 -0.0122,0.0003 -0.0183,0.0003l-0.7114 0 -1.9971 0 0 8.3888 3.5566 0 0 -1.6774 -1.9035 0c-0.3912,0 -0.7113,-0.32 -0.7113,-0.7113l0 -0.0226 0 -0.6887 0 -1.9454c0,-0.3912 0.3201,-0.7113 0.7113,-0.7113l0 0c0.3912,0 0.7114,0.3201 0.7114,0.7113l0 1.9454 1.1921 0 0 -1.8317c0,-0.978 0.8002,-1.7783 1.7782,-1.7783l0 0c0.9781,0 1.7783,0.8002 1.7783,1.7783l0 0.6936 1.1706 0 0 -1.9228c0,-0.3912 0.3201,-0.7113 0.7113,-0.7113l0 0c0.3912,0 0.7113,0.3201 0.7113,0.7113l0 1.9228 0 0.7113c0,0.0061 -0.0001,0.0123 -0.0002,0.0183 -0.0002,0.0061 -0.0004,0.0122 -0.0007,0.0182 -0.0003,0.0061 -0.0007,0.0121 -0.0012,0.0181 -0.0005,0.006 -0.001,0.012 -0.0016,0.0179 -0.0006,0.006 -0.0013,0.0119 -0.002,0.0178 -0.0008,0.0059 -0.0016,0.0118 -0.0025,0.0177 -0.0009,0.0059 -0.0019,0.0117 -0.003,0.0175 -0.001,0.0059 -0.0021,0.0116 -0.0033,0.0174 -0.0012,0.0058 -0.0025,0.0115 -0.0038,0.0173 -0.0013,0.0057 -0.0027,0.0114 -0.0042,0.0171 -0.0015,0.0056 -0.003,0.0113 -0.0046,0.0169l-0.005 0.0168c-0.0018,0.0055 -0.0036,0.011 -0.0054,0.0165 -0.0019,0.0056 -0.0039,0.011 -0.0058,0.0165 -0.002,0.0054 -0.0041,0.0108 -0.0063,0.0162l-0.0065 0.016 -0.007 0.0159c-0.0024,0.0052 -0.0048,0.0104 -0.0073,0.0156l-0.0077 0.0154 -0.0081 0.0153c-0.0027,0.005 -0.0055,0.01 -0.0084,0.015 -0.0029,0.0049 -0.0058,0.0099 -0.0088,0.0148 -0.0029,0.0049 -0.006,0.0097 -0.0091,0.0145 -0.003,0.0048 -0.0062,0.0096 -0.0094,0.0143 -0.0032,0.0048 -0.0065,0.0095 -0.0098,0.0141l-0.0101 0.0138c-0.0034,0.0046 -0.0069,0.0091 -0.0104,0.0136l-0.0108 0.0133c-0.0036,0.0044 -0.0073,0.0088 -0.011,0.0131 -0.0037,0.0043 -0.0075,0.0085 -0.0113,0.0128l-0.0001 0 -0.0116 0.0125 -0.0119 0.0122 -0.0001 0 -0.0122 0.0119 0 0 -0.0125 0.0117 -0.0128 0.0113 0 0c-0.0043,0.0038 -0.0086,0.0075 -0.013,0.0111l-0.0133 0.0107 -0.0001 0c-0.0044,0.0036 -0.0089,0.0071 -0.0135,0.0105 -0.0046,0.0034 -0.0092,0.0067 -0.0138,0.0101l-0.0001 0c-0.0046,0.0033 -0.0093,0.0065 -0.014,0.0097 -0.0048,0.0032 -0.0095,0.0064 -0.0143,0.0095 -0.0049,0.0031 -0.0097,0.0061 -0.0146,0.0091l0 0c-0.0049,0.003 -0.0098,0.0059 -0.0148,0.0087l-0.015 0.0085c-0.005,0.0027 -0.0101,0.0054 -0.0152,0.008l-0.0154 0.0077c-0.0052,0.0025 -0.0104,0.005 -0.0157,0.0074l0 0c-0.0053,0.0024 -0.0105,0.0047 -0.0158,0.0069 -0.0053,0.0023 -0.0107,0.0045 -0.0161,0.0066 -0.0053,0.0021 -0.0107,0.0042 -0.0162,0.0062l0 0 -0.0164 0.0058c-0.0055,0.0019 -0.011,0.0037 -0.0166,0.0054l0 0c-0.0056,0.0018 -0.0111,0.0034 -0.0167,0.0051l-0.0001 0 -0.0169 0.0046 0 0c-0.0057,0.0014 -0.0114,0.0028 -0.0171,0.0041l0 0c-0.0057,0.0014 -0.0114,0.0027 -0.0172,0.0038 -0.0058,0.0012 -0.0116,0.0023 -0.0174,0.0034l0 0c-0.0059,0.0011 -0.0117,0.002 -0.0176,0.0029 -0.0058,0.0009 -0.0117,0.0018 -0.0176,0.0025 -0.0059,0.0008 -0.0119,0.0014 -0.0178,0.0021 -0.006,0.0006 -0.012,0.0011 -0.018,0.0016 -0.006,0.0004 -0.012,0.0008 -0.018,0.0011 -0.0061,0.0003 -0.0122,0.0005 -0.0182,0.0007 -0.0061,0.0002 -0.0122,0.0003 -0.0183,0.0003zm-1.8819 4.5937l0 0z"
            />
            <polygon
              fill="#E85051"
              points="10.8407,0 10.6079,0.8065 9.4329,0.1579 10.1939,1.6775 11.4875,1.6775 12.2485,0.1579 11.0735,0.8065"
            />
            <path
              fill="#5BAB68"
              d="M20.3248 13.2778l0 1.8688 0 2.7249c0,0.8014 -0.5374,1.4832 -1.2696,1.7034l0 -3.8992 0 -0.5291 0 -5.6886c0.7322,0.2202 1.2696,0.902 1.2696,1.7035l0 0.6936 0 1.4227zm-7.1131 6.3719l0 2.7286 0 5.0781 -1.5649 0 0 -25.9392c0.9104,0.3318 1.5649,1.2077 1.5649,2.2291l0 2.5355 0 1.4226 0 0.3866 0 6.9671 0 1.0351 0 3.5565zm2.7126 -16.0021c0.3893,0.0022 0.7072,0.3215 0.7072,0.7113l0 1.9229 0 0.7113c0,0.0061 -0.0001,0.0122 -0.0003,0.0182 -0.0001,0.0061 -0.0003,0.0122 -0.0006,0.0182 -0.0004,0.0061 -0.0007,0.0121 -0.0012,0.0181 -0.0005,0.006 -0.001,0.0119 -0.0016,0.0179 -0.0006,0.006 -0.0013,0.0119 -0.0021,0.0178 -0.0007,0.0059 -0.0016,0.0118 -0.0025,0.0177 -0.0009,0.0059 -0.0018,0.0117 -0.0029,0.0176 -0.001,0.0058 -0.0021,0.0116 -0.0033,0.0173 -0.0012,0.0058 -0.0025,0.0116 -0.0038,0.0173 -0.0014,0.0057 -0.0028,0.0114 -0.0042,0.0171l-0.0046 0.0169c-0.0016,0.0056 -0.0033,0.0112 -0.0051,0.0168 -0.0017,0.0055 -0.0035,0.0111 -0.0054,0.0166l-0.0058 0.0164c-0.002,0.0054 -0.0041,0.0108 -0.0062,0.0162 -0.0021,0.0054 -0.0043,0.0107 -0.0065,0.016 -0.0023,0.0053 -0.0046,0.0107 -0.007,0.0159 -0.0024,0.0052 -0.0049,0.0104 -0.0073,0.0156l-0.0077 0.0155c-0.0027,0.0051 -0.0054,0.0102 -0.0081,0.0152l-0.0084 0.015c-0.0029,0.0049 -0.0058,0.0099 -0.0088,0.0148l-0.0091 0.0145c-0.0031,0.0048 -0.0062,0.0096 -0.0094,0.0143 -0.0032,0.0048 -0.0065,0.0095 -0.0098,0.0141l-0.0101 0.0138c-0.0034,0.0046 -0.0069,0.0091 -0.0104,0.0136l-0.0108 0.0133 -0.011 0.0131 -0.0114 0.0128 0 0c-0.0038,0.0042 -0.0077,0.0084 -0.0116,0.0125 -0.004,0.0041 -0.008,0.0082 -0.012,0.0122l-0.0122 0.012 0 0 -0.0125 0.0116c-0.0042,0.0039 -0.0085,0.0076 -0.0128,0.0114l0 0 -0.0131 0.011c-0.0044,0.0036 -0.0088,0.0072 -0.0133,0.0107l0 0 -0.0135 0.0105c-0.0046,0.0034 -0.0092,0.0068 -0.0139,0.0101l0 0c-0.0046,0.0033 -0.0093,0.0065 -0.014,0.0097 -0.0048,0.0032 -0.0096,0.0064 -0.0144,0.0095 -0.0048,0.0031 -0.0096,0.0061 -0.0145,0.0091l0 0 -0.0148 0.0088c-0.005,0.0028 -0.01,0.0056 -0.015,0.0084l-0.0152 0.008 -0.0155 0.0077c-0.0052,0.0026 -0.0103,0.005 -0.0156,0.0074l0 0 -0.0159 0.0069 -0.016 0.0066 -0.0162 0.0062 0 0 -0.0164 0.0058c-0.0055,0.0019 -0.011,0.0037 -0.0166,0.0054l0 0c-0.0056,0.0018 -0.0112,0.0035 -0.0168,0.0051l0 0c-0.0056,0.0016 -0.0112,0.0031 -0.0169,0.0046l0 0c-0.0057,0.0014 -0.0114,0.0028 -0.0171,0.0042l0 0c-0.0057,0.0013 -0.0115,0.0026 -0.0173,0.0038 -0.0057,0.0011 -0.0115,0.0023 -0.0173,0.0033l-0.0001 0c-0.0058,0.001 -0.0116,0.002 -0.0175,0.0029 -0.0059,0.0009 -0.0118,0.0018 -0.0177,0.0025 -0.0059,0.0008 -0.0118,0.0015 -0.0178,0.0021 -0.0059,0.0006 -0.0119,0.0011 -0.0179,0.0016 -0.006,0.0004 -0.012,0.0008 -0.0181,0.0011 -0.006,0.0003 -0.0121,0.0006 -0.0181,0.0007l-0.0142 0.0003 0 -4.0568zm-0.3481 10.7682l-0.7114 0 0 -4.0793 0 0c0.3912,0 0.7114,0.3201 0.7114,0.7113l0 1.9454 0 1.4226zm6.8745 -5.1515c0.272,0.1001 0.4673,0.3624 0.4673,0.668l0 1.9228 0 0.7113c0,0.0061 -0.0001,0.0123 -0.0002,0.0183 -0.0002,0.0061 -0.0004,0.0122 -0.0007,0.0182 -0.0003,0.0061 -0.0007,0.0121 -0.0012,0.0181 -0.0005,0.006 -0.001,0.012 -0.0016,0.0179 -0.0006,0.006 -0.0013,0.0119 -0.002,0.0178 -0.0008,0.0059 -0.0016,0.0118 -0.0025,0.0177 -0.0009,0.0059 -0.0019,0.0117 -0.003,0.0175 -0.001,0.0059 -0.0021,0.0116 -0.0033,0.0174 -0.0012,0.0058 -0.0025,0.0115 -0.0038,0.0173 -0.0013,0.0057 -0.0027,0.0114 -0.0042,0.0171 -0.0015,0.0056 -0.003,0.0113 -0.0046,0.0169l-0.005 0.0168c-0.0018,0.0055 -0.0036,0.011 -0.0054,0.0165 -0.0019,0.0056 -0.0039,0.011 -0.0058,0.0165 -0.002,0.0054 -0.0041,0.0108 -0.0063,0.0162l-0.0065 0.016 -0.007 0.0159c-0.0024,0.0052 -0.0048,0.0104 -0.0073,0.0156l-0.0077 0.0154 -0.0081 0.0153c-0.0027,0.005 -0.0055,0.01 -0.0084,0.015 -0.0029,0.0049 -0.0058,0.0099 -0.0088,0.0148 -0.0029,0.0049 -0.006,0.0097 -0.0091,0.0145 -0.003,0.0048 -0.0062,0.0096 -0.0094,0.0143 -0.0032,0.0048 -0.0065,0.0095 -0.0098,0.0141l-0.0101 0.0138c-0.0034,0.0046 -0.0069,0.0091 -0.0104,0.0136l-0.0108 0.0133c-0.0036,0.0044 -0.0073,0.0088 -0.011,0.0131 -0.0037,0.0043 -0.0075,0.0085 -0.0113,0.0128l-0.0001 0 -0.0116 0.0125 -0.0119 0.0122 -0.0001 0 -0.0122 0.0119 0 0 -0.0125 0.0117 -0.0128 0.0113 0 0c-0.0043,0.0038 -0.0086,0.0075 -0.013,0.0111l-0.0133 0.0107 -0.0001 0c-0.0044,0.0036 -0.0089,0.0071 -0.0135,0.0105 -0.0046,0.0034 -0.0092,0.0067 -0.0138,0.0101l-0.0001 0c-0.0046,0.0033 -0.0093,0.0065 -0.014,0.0097 -0.0048,0.0032 -0.0095,0.0064 -0.0143,0.0095 -0.0049,0.0031 -0.0097,0.0061 -0.0146,0.0091l0 0c-0.0049,0.003 -0.0098,0.0059 -0.0148,0.0087l-0.015 0.0085c-0.005,0.0027 -0.0101,0.0054 -0.0152,0.008l-0.0154 0.0077c-0.0052,0.0025 -0.0104,0.005 -0.0157,0.0074l0 0c-0.0053,0.0024 -0.0105,0.0047 -0.0158,0.0069 -0.0053,0.0023 -0.0107,0.0045 -0.0161,0.0066l-0.0161 0.0062 0 -3.9701zm-15.9015 10.637l-0.9878 0 0 -11.6523c0.5842,0.2923 0.9878,0.8971 0.9878,1.5916l0 3.7623 0 2.7419 0 3.5565zm-5.1266 -4.5435l-0.3812 0 0 -3.9749c0.2262,0.1194 0.3812,0.3573 0.3812,0.6295l0 1.2818 0 0.641 0 1.4226zm18.9022 2.5137l0 0z"
            />
          </symbol>

          <symbol id="relief-deadTree-1" viewBox="-10 -9 30 30">
            <ellipse fill="#999999" opacity=".5" cx="6.0917" cy="7.5182" rx="2.8932" ry=".3408" />
            <path
              fill="#585142"
              d="M3.5153 1.3458c0.2543,-0.0013 0.7916,0.129 0.6583,0.3396 -0.0857,0.1354 -0.6435,1.074 -0.6404,1.114 0.0042,0.0531 0.341,0.6425 0.3357,1.0671 -0.005,0.4 -0.4393,0.5902 -0.7445,0.6156l-0.1526 -0.7164 -0.8522 -0.3727c0.1354,-0.828 0.3493,-0.4466 -0.2112,-1.4572 -0.1448,-0.261 0.2666,-0.5992 0.4246,-0.6946l-0.2495 0.0682 0.2497 -0.3491c-0.0387,0.0257 -0.0763,0.0603 -0.12,0.0839l0.0471 -0.2236 -0.4834 0.8931c-0.0975,0.1868 -0.1224,0.1338 0.005,0.2843 0.4911,0.5805 0.3652,0.7545 0.1577,1.3533l-0.57 -0.258c-0.0654,-0.3528 -0.0606,-0.8702 -0.2831,-1.0414 -0.1952,-0.1502 -0.2072,-0.1461 -0.1229,-0.535 0.0474,-0.2188 0.2619,-0.2628 0.4506,-0.4999 -0.2195,0.1614 -0.4687,0.2928 -0.4917,0.4311 -0.126,0.7587 -0.2153,0.3823 -0.9225,0.3141l0.5598 0.2152 -0.2753 0.1191c0.4778,-0.0459 1.0244,-0.3067 0.9364,1.1042l1.422 0.566c0.2198,0.0889 0.16,0.0419 0.2147,0.2873 0.0473,0.2124 0.2648,1.1447 0.2621,1.2321 0.0348,0.1295 1.1372,1.5251 1.0567,1.6851l-0.6487 0.534c0.2003,0.0023 0.3874,0.0799 0.5356,0.2115 0.321,-0.1964 0.6523,-0.1739 0.933,0.0841 0.0279,-0.0963 -0.0348,-0.2065 0.1893,-0.1382 -0.0511,-0.1825 0.0636,-0.3019 0.3652,-0.2167l-0.5587 -0.6647c-0.335,-0.4654 0.0657,-0.5361 0.3232,-0.8874 0.3199,-0.4366 0.4947,-1.3297 0.9872,-1.2478 0.166,0.0276 0.544,0.3328 0.6681,0.3902 -0.0526,-0.0727 -0.3251,-0.2763 -0.3757,-0.3471 1.1234,-0.3172 0.6664,-0.9833 1.0576,-1.1403 0.3553,-0.1426 0.4178,-0.1125 0.7358,0.0071 -0.0447,-0.0408 -0.1272,-0.083 -0.1599,-0.1386 0.0608,-0.1125 0.1637,-0.2309 0.2168,-0.3457 -0.4288,0.3352 0.1565,0.1887 -0.9798,0.3409 -0.076,0.1367 -0.2062,0.5445 -0.2709,0.7293 -0.0474,0.1354 -0.4617,0.3359 -0.5939,0.4082l-0.5365 -0.0954 0.4903 -0.4019c-0.7228,0.343 -0.6671,0.5239 -1.2151,1.3647 -0.1089,0.1629 -0.0654,0.1629 -0.2597,0.2666 -0.1824,0.0973 -0.5098,0.2844 -0.6886,0.3561 -0.0734,-0.0726 -0.3395,-0.5036 -0.3932,-0.5868 -0.1102,-0.1707 -0.1243,-0.1282 -0.0443,-0.3189 0.4751,-1.1814 0.3432,-0.7881 0.0867,-1.6479 -0.1573,-0.5272 0.5708,0.047 0.89,0.1609 -0.1139,-0.1055 -0.9469,-0.6786 -0.9647,-0.7257 -0.0096,-0.0255 0.0803,-0.5765 0.4293,-0.6942 0.2215,-0.0746 0.7565,-0.1045 0.9396,0.0794 0.0928,0.0932 0.1646,0.2261 0.2324,0.3401l-0.1008 -0.3823c0.5352,-0.1142 0.5229,-0.3132 1.2351,-0.1707 0.3041,0.0609 0.9743,0.2752 1.2277,0.2822l-0.1733 -0.1642 0.2597 -0.0104 -0.2894 -0.0697 0.3033 -0.1079c-0.3524,-0.0086 -0.4157,0.1266 -0.8613,0.037 -0.1587,-0.0319 -0.7112,-0.1209 -0.823,-0.1706l0.8073 -0.3358c0.0347,-0.1549 -0.0285,-0.6678 0.0729,-0.7688 0.104,-0.1035 0.4286,0.0056 0.7823,-0.0293 -0.6035,-0.1089 -0.758,-0.0385 -0.201,-0.6082 0.0264,-0.027 0.106,-0.1209 0.1223,-0.1483l-0.7942 0.7068c-0.1806,0.835 0.0273,0.6738 -0.5709,0.9316 -0.3515,0.1515 -0.684,0.3171 -1.0625,0.4386 -0.2353,0.0756 -1.005,-0.0716 -1.2564,-0.1546 0.1802,-0.3685 0.3858,-0.7438 0.5712,-1.1089 0.0411,-0.0808 0.394,-0.3205 0.7318,-0.2844l0.1679 0.0147c-0.041,-0.0393 -0.097,-0.0652 -0.1266,-0.1087l0.1758 -0.0375 -0.1404 -0.0163c0.0637,-0.0888 0.1594,-0.1402 0.2279,-0.2235l-0.9849 0.4772c-0.1089,0.0534 -0.4306,0.5672 -0.5266,0.6922 -0.1802,0.2202 -0.5124,-0.2033 -0.7609,-0.3405l0.2762 0.3034c-0.1828,-0.0025 -0.4046,-0.0156 -0.5464,0.0752l0.2056 -0.0195z"
            />
            <path
              fill="#3D3A31"
              d="M4.3375 7.6026l0.2401 -0.5118c0.0457,-0.0936 -0.0794,-0.2034 -0.1891,-0.3729 -0.0782,-0.121 -0.1611,-0.2395 -0.2481,-0.3677l-0.7328 -1.0888c-0.0268,-0.06 -0.1063,-0.4167 -0.1183,-0.4971 0.0936,-0.0606 0.1753,-0.082 0.3393,-0.197 0.1022,-0.0717 0.2115,-0.1589 0.2639,-0.2777 0.1007,-0.2281 0.0424,-0.7261 -0.0353,-0.9525 -0.0455,-0.1327 -0.093,-0.2647 -0.1366,-0.4022 -0.0524,-0.1652 -0.0621,-0.0948 0.0823,-0.3767 0.0557,-0.1089 0.35,-0.6707 0.3658,-0.7401 -0.0687,0.0461 -0.4823,0.7693 -0.5446,0.8713 -0.0548,0.0896 -0.0792,0.0842 -0.0263,0.1979 0.1713,0.3682 0.4361,0.9622 0.1819,1.2915 -0.1916,0.2482 -0.4358,0.3122 -0.7357,0.388l-0.1851 -0.6512c-0.0024,0.1012 0.2128,1.0065 0.2534,1.1899 0.0276,0.1246 0.026,0.1801 0.0921,0.2672 0.0555,0.0732 0.1032,0.1447 0.1557,0.2167 0.1043,0.1427 0.2011,0.2764 0.3071,0.4238 0.0998,0.1386 0.1978,0.2817 0.2931,0.4252 0.4653,0.6996 0.2999,0.6121 -0.3393,1.0732 0.1665,0.0216 0.3185,0.095 0.4423,0.2048 0.081,-0.0363 0.1852,-0.101 0.2742,-0.1139z"
            />
          </symbol>

          <symbol id="relief-deadTree-2" viewBox="-10 -9 30 30">
            <ellipse fill="#999999" opacity=".5" cx="5.5691" cy="9.506" rx="4.825" ry=".5684" />
            <path
              fill="#585142"
              d="M1.679 3.5305l-0.5914 -0.2423c0.2049,0.3227 0.8568,0.3529 0.9257,1.1466 0.0188,0.2166 0.0334,0.2874 0.0274,0.2877l-0.0627 0.003c-0.1741,-0.114 -0.0803,-0.0814 -0.125,-0.5035l-0.149 0.4333c-0.884,-0.1024 -1.1345,-0.9856 -1.522,-1.157 0.0945,0.4164 0.1069,0.1444 0.3065,0.5819 0.1329,0.2913 0.1234,0.3803 0.3235,0.5433 -0.3018,-0.0152 -0.2722,-0.2108 -0.7765,-0.1333l0.8518 0.3089c0.3411,0.0711 0.4473,0.3096 0.8873,0.4034 0.7297,0.1555 0.8304,0.9419 0.8039,1.9517 -1.2559,0.0858 -1.1471,-1.4021 -1.1869,-1.4946l-0.0817 -0.1897 -0.0372 0.8722c-0.1953,-0.0862 -0.4195,-0.0759 -0.6206,-0.204 -0.3275,-0.2086 -0.1479,-0.3863 -0.4882,-0.4596 0.0371,0.5904 0.7744,0.7122 1.0801,1.012 0.2091,0.2051 0.2487,0.4467 0.4605,0.6561 0.1976,0.1955 0.3922,0.1808 0.5932,0.3942 -0.2392,0.1554 -0.2456,0.0512 -0.4157,0.2941 0.2789,0.2135 0.6512,-0.3638 0.6968,0.3659l-0.0753 0.1314 0.0057 0.3037c-0.0765,0.082 -0.1103,0.0108 -0.2853,-0.0638l0.1248 0.4129c-0.2614,0.0823 -0.2086,0.0986 -0.4283,0.26 -0.0687,-0.1591 -0.0574,-0.341 -0.0575,-0.3416 -0.1973,0.1955 -0.041,0.0251 -0.1724,0.3157l-0.2807 0.0375 -0.2353 0.172c0.0166,0.0305 0.0231,0.0503 0.0259,0.0641 0.5892,-0.1981 1.3769,-0.2863 2.2319,-0.2183 0.517,0.0411 1.0007,0.1347 1.4241,0.266 -0.2093,-0.1379 -0.4154,-0.3068 -0.6089,-0.2809 0.3384,-0.0334 0.557,0.1266 0.7762,-0.0291 -0.0116,-0.0171 -0.0336,-0.0585 -0.0414,-0.04 -0.2183,-0.1297 -0.1296,-0.0991 -0.3828,-0.1369 -0.8341,-0.0913 -1.0623,-1.1991 -0.6846,-2.1715 0.1148,-0.2957 0.15,-0.1675 0.1954,-0.3631 0.7256,-0.0816 1.4521,0.6923 1.8913,-0.18 -0.32,-0.0118 -0.3601,0.198 -0.7796,0.1439 -0.2875,-0.037 -0.5949,-0.1322 -0.7655,-0.3165 1.2886,-0.6494 1.0806,-0.8912 1.489,-1.4573 0.2383,-0.3304 0.3236,-0.1176 0.4895,-0.5992 -0.3842,0.0962 -0.668,0.5411 -0.923,0.8001 0.0294,-0.8219 0.5645,-1.0809 0.2601,-1.7852 -0.1194,0.3583 0.0793,0.3008 -0.2716,0.9492 -0.1488,0.2751 -0.2304,0.6341 -0.3535,0.8937 -0.1749,0.369 -1.0145,0.7821 -1.3429,0.6432 -0.2625,-1.5704 1.2608,-1.4244 1.7171,-2.9858 0.1082,-0.3703 -0.0046,-0.34 0.2521,-0.4762 -0.2374,-0.2138 -0.1318,0.1284 -0.1516,-0.3055 0.4125,-0.5937 0.4463,-0.2996 0.6287,-0.9535l0.1667 -0.4867c-0.3642,0.1212 -0.1886,0.2262 -0.3853,0.5867 -0.0991,0.1815 -0.2777,0.3195 -0.4897,0.3478 -0.1484,-0.1486 -0.3404,-0.415 -0.4219,-0.6144 -0.1726,-0.4224 -0.0332,-0.515 0.0165,-0.9229 -0.2513,0.1258 -0.2673,0.4884 -0.2032,0.8657 0.0777,0.4568 0.259,0.4728 0.3536,0.7365 0.2036,0.5674 -0.1231,1.5803 -0.4923,1.669 -0.2599,-0.6178 -0.1389,-0.5099 -0.0559,-1.1514 -0.3962,0.467 -0.0305,1.0251 -0.1346,1.3145 -0.1475,0.182 -0.526,0.4221 -0.7103,0.5992 -0.1897,0.1821 -0.1458,0.1848 -0.2987,0.3948 -0.1358,0.1867 -0.1887,0.203 -0.3348,0.4176 -0.1315,-0.6385 -0.4597,-1.0413 -0.7405,-1.3874 0.2,-0.2285 0.2784,-0.3478 0.6312,-0.4772 0.3178,-0.1166 0.5361,-0.1513 0.5389,-0.5903 -0.212,0.0746 -0.2207,0.3469 -0.6704,0.4752 0.0799,-0.2322 0.0813,-0.1298 0.1373,-0.4444 -0.2906,0.3241 -0.0801,0.3381 -0.3802,0.514 -0.1557,0.0913 -0.33,0.1116 -0.4702,0.2076 -0.1232,-0.402 -0.1303,-0.3989 -0.0658,-0.8723l0.1533 -0.2038c0.1132,-0.1545 0.1626,-0.2402 0.3489,-0.3217 0.3073,-0.1346 0.5114,-0.0923 0.5563,-0.4919 -0.2809,0.1498 -0.387,0.2416 -0.7518,0.3749 -0.3568,0.1303 -0.4097,0.3449 -0.7091,0.4842 -0.114,-0.3646 -0.271,-0.3342 -0.3815,-0.786 -0.1449,-0.5926 -0.0026,-0.7687 0.0853,-1.1817 -0.3132,0.2088 -0.3149,0.4188 -0.3345,0.9648 -0.4693,0.0005 -0.4863,-0.8063 -0.5087,-1.0178l-0.1143 0.5467c-0.2289,-0.099 -0.3561,-0.1846 -0.5848,-0.0251 0.1017,0.0842 0.7571,0.2068 1.1046,1.029 0.3769,0.8922 0.686,0.9642 0.5744,1.8877z"
            />
            <path
              fill="#3D3A31"
              d="M4.8565 9.7405c-0.2093,-0.1378 -0.4153,-0.3069 -0.6089,-0.2811 0.3383,-0.0334 0.5569,0.1266 0.7761,-0.0291 -0.0116,-0.0171 -0.0336,-0.0585 -0.0414,-0.04 -0.2183,-0.1297 -0.1296,-0.0991 -0.3827,-0.1369 -0.8341,-0.0913 -1.0624,-1.1991 -0.6847,-2.1715 0.1148,-0.2957 0.1501,-0.1675 0.1954,-0.3631 -0.0467,-0.123 0.0439,-0.1513 -0.2166,-0.132 -0.4837,0.0358 -0.4335,0.3011 -0.4749,0.451 -0.043,0.1554 -0.3572,0.7239 -0.3816,1.4623 -0.011,0.3289 0.0331,0.246 -0.0081,0.6595 -0.0107,0.1082 -0.031,0.2048 -0.0477,0.2933 0.0721,0.0012 0.1448,0.0035 0.218,0.007 -0.0003,-0.4729 -0.0122,-1.0018 0.0855,-1.2875 0.1016,-0.2975 -0.0153,-0.1074 0.1875,-0.3203 0,0.6477 -0.0814,1.158 -0.139,1.6153l0.0989 0.0072c0.5171,0.0411 1.0008,0.1346 1.4242,0.2661z"
            />
          </symbol>
        </g>

        <g id="defs-compass-rose" stroke-width="1.1">
          <g id="rose-coord-line" stroke="#3f3f3f">
            <line id="sL1" x1="0" y1="-20000" x2="0" y2="20000" />
            <line id="sL2" x1="-20000" y1="0" x2="20000" y2="0" />
          </g>
          <use href="#rose-coord-line" transform="rotate(45)" />
          <use href="#rose-coord-line" transform="rotate(22.5)" />
          <use href="#rose-coord-line" transform="rotate(-22.5)" />
          <use href="#rose-coord-line" transform="rotate(11.25)" />
          <use href="#rose-coord-line" transform="rotate(-11.25)" />
          <use href="#rose-coord-line" transform="rotate(56.25)" />
          <use href="#rose-coord-line" transform="rotate(-56.25)" />

          <g stroke-width="8" stroke-opacity="1" shape-rendering="geometricprecision">
            <circle r="9" stroke="#000000" fill="#1b1b1b" />
            <circle r="75" stroke="#008000" fill="#ffffff" fill-opacity=".1" />
            <circle r="212" stroke="#1b1b1b" />
            <circle r="211" stroke="#008000" fill="#ffffff" fill-opacity=".1" />
          </g>
          <g stroke="#1b1b1b" stroke-opacity="1" shape-rendering="geometricprecision">
            <circle r="71" />
            <circle r="79" />
            <circle r="94" />
            <circle r="152" />
            <circle r="164" />
            <circle r="207" />
          </g>
          <g id="s3" stroke-opacity="1" shape-rendering="geometricprecision">
            <g id="s2">
              <g id="s1" stroke="#1b1b1b">
                <path
                  d="M 39.416,95.16 C 33.65,103.95 30.76,110.5 28.93,117.18 C 15.24,113.43 13.54,127.15 23.04,131 C 13.71,145.8 7.84,173.93 0,212 L 0,103 A 103,103 0 0,0 39.416,95.16 z"
                  fill="#47a3d1"
                />
                <path
                  d="M 39.416,95.16 C 33.65,103.95 30.76,110.5 28.93,117.18 C 15.24,113.43 13.54,127.15 23.04,131 C 13.71,145.8 7.84,173.93 0,212 L 0,103 A 103,103 0 0,0 39.416,95.16 z"
                  fill="black"
                  transform="scale(-1,1)"
                />
                <path
                  d="M -31.995,160.849 A 164,164 0 0,0 31.995,160.849 C 18.9,170.1 8.4,176.3 0,207 C -8.4,176.3 -18.9,170.1 -31.995,160.849 z"
                  fill="#c2390f"
                  transform="rotate(22.5)"
                />
              </g>
              <use href="#s1" transform="rotate(45)" />
            </g>
            <use href="#s2" transform="rotate(90)" />
          </g>
          <use href="#s3" transform="scale(-1)" />
        </g>

        <g id="coas"></g>

        <g id="gridPatterns">
          <pattern id="pattern_square" width="25" height="25" patternUnits="userSpaceOnUse" fill="none">
            <path d="M 25 0 L 0 0 0 25" />
          </pattern>

          <pattern id="pattern_pointyHex" width="25" height="43.4" patternUnits="userSpaceOnUse" fill="none">
            <path d="M 0,0 12.5,7.2 25,0 M 12.5,21.7 V 7.2 Z M 0,43.4 V 28.9 L 12.5,21.7 25,28.9 v 14.5" />
          </pattern>

          <pattern id="pattern_flatHex" width="43.4" height="25" patternUnits="userSpaceOnUse" fill="none">
            <path d="M 43.4,0 36.2,12.5 43.4,25 M 21.7,12.5 H 36.2 Z M 0,0 H 14.5 L 21.7,12.5 14.5,25 H 0" />
          </pattern>

          <pattern id="pattern_square45deg" width="35.355" height="35.355" patternUnits="userSpaceOnUse" fill="none">
            <path d="M 0 0 L 35.355 35.355 M 0 35.355 L 35.355 0" />
          </pattern>

          <pattern id="pattern_squareTruncated" width="25" height="25" patternUnits="userSpaceOnUse" fill="none">
            <path
              d="M 8.33 25 L 0 16.66 V 8.33 L 8.33 0 16.66 0 25 8.33  M 16.66 25 L 25 16.66 L 25 8.33 M 8.33 25 L 16.66 25"
            />
          </pattern>

          <pattern id="pattern_squareTetrakis" width="25" height="25" patternUnits="userSpaceOnUse" fill="none">
            <path
              d="M 25 0 L 0 0 0 25 M 0 0 L 25 25 M 0 25 L 25 0 M 12.5 0 L 12.5 25 M 0 12.5 L 25 12.5 M 0 25 L 25 25 L 25 0"
            />
          </pattern>

          <pattern
            id="pattern_triangleHorizontal"
            width="41.76"
            height="72.33"
            patternUnits="userSpaceOnUse"
            fill="none"
          >
            <path
              d="M 41.76 36.165 H 0 L 20.88 0 41.76 36.165 20.88 72.33 0 36.165 M 0 0 H 72.33 M 0 72.33 L 41.76 72.33"
            />
          </pattern>

          <pattern id="pattern_triangleVertical" width="72.33" height="41.76" patternUnits="userSpaceOnUse" fill="none">
            <path
              d="M 36.165 0 L 0 20.88 36.165 41.76 72.33 20.88 36.165 0 V 41.76 M 0 0 V 72.33 M 72.33 0 L 72.33 41.76"
            />
          </pattern>

          <pattern id="pattern_trihexagonal" width="25" height="43.4" patternUnits="userSpaceOnUse" fill="none">
            <path d="M 25 10.85 H 0 L 18.85 43.4 25 32.55 H 0 L 18.85 0 25 10.85" />
          </pattern>

          <pattern id="pattern_rhombille" width="82.5" height="50" patternUnits="userSpaceOnUse" fill="none">
            <path
              d="M 13.8 50 L 0 25 13.8 0 H 41.2 L 27.5 25 41.2 50 55 25 41.2 0 68.8 0 82.5 25 68.8 50 M 0 25 H 27.5 M 55 25 H 82.5 M 13.8 50 H 41.2 L 68.8 50"
            />
          </pattern>
        </g>

        <g id="defs-hatching">
          <pattern id="hatch0" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="0" y1="0" x2="0" y2="4" style="stroke: black; stroke-width: 2" />
          </pattern>
          <pattern id="hatch1" patternTransform="rotate(45 0 0)" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="0" y1="0" x2="0" y2="4" style="stroke: black; stroke-width: 2" />
          </pattern>
          <pattern id="hatch2" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="0" y1="0" x2="4" y2="0" style="stroke: black; stroke-width: 2" />
          </pattern>
          <pattern id="hatch3" patternTransform="rotate(-45 0 0)" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="0" y1="0" x2="0" y2="4" style="stroke: black; stroke-width: 2" />
          </pattern>
          <pattern id="hatch4" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="0" y1="0" x2="0" y2="4" style="stroke: black; stroke-width: 1.5" />
            <line x1="0" y1="0" x2="4" y2="0" style="stroke: black; stroke-width: 1.5" />
          </pattern>
          <pattern id="hatch5" patternTransform="rotate(45 0 0)" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="0" y1="0" x2="0" y2="4" style="stroke: black; stroke-width: 1.5" />
            <line x1="0" y1="0" x2="4" y2="0" style="stroke: black; stroke-width: 1.5" />
          </pattern>
          <pattern id="hatch6" patternUnits="userSpaceOnUse" width="5" height="5">
            <circle cx="2.5" cy="2.5" r="1" style="fill: black" />
          </pattern>
          <pattern id="hatch7" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="0" y1="0" x2="0" y2="3" transform="rotate(-45 0 0)" style="stroke: black; stroke-width: 1.5" />
          </pattern>
          <pattern id="hatch8" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="0" y1="0" x2="0" y2="3" style="stroke: black; stroke-width: 2.5" />
          </pattern>
          <pattern id="hatch9" patternTransform="rotate(45 0 0)" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="0" y1="0" x2="0" y2="3" style="stroke: black; stroke-width: 2.5" />
          </pattern>
          <pattern id="hatch10" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="0" y1="0" x2="3" y2="0" style="stroke: black; stroke-width: 2.5" />
          </pattern>
          <pattern id="hatch11" patternTransform="rotate(-45 0 0)" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="0" y1="0" x2="0" y2="3" style="stroke: black; stroke-width: 2.5" />
          </pattern>
          <pattern id="hatch12" patternTransform="rotate(45 0 0)" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="0" y1="1" x2="0" y2="3" style="stroke: black; stroke-width: 1.5" />
            <line x1="1" y1="0" x2="3" y2="0" style="stroke: black; stroke-width: 1.5" />
          </pattern>
          <pattern id="hatch13" patternTransform="rotate(45 0 0)" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="0" y1="0" x2="0" y2="3" style="stroke: black; stroke-width: 1.5" />
            <line x1="0" y1="0" x2="3" y2="0" style="stroke: black; stroke-width: 1.5" />
          </pattern>
          <pattern id="hatch14" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="1" y1="0" x2="0" y2="4" style="stroke: black; stroke-width: 2" />
          </pattern>
          <pattern id="hatch15" patternTransform="rotate(45 0 0)" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="1" y1="0" x2="0" y2="4" style="stroke: black; stroke-width: 2" />
          </pattern>
          <pattern id="hatch16" patternTransform="rotate(-45 0 0)" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="1" y1="0" x2="0" y2="4" style="stroke: black; stroke-width: 2" />
          </pattern>
          <pattern id="hatch17" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="1" y1="0" x2="0" y2="4" style="stroke: black; stroke-width: 1.5" />
            <line x1="1" y1="0" x2="4" y2="0" style="stroke: black; stroke-width: 1.5" />
          </pattern>
          <pattern id="hatch18" patternTransform="rotate(45 0 0)" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="1" y1="0" x2="0" y2="4" style="stroke: black; stroke-width: 1.5" />
            <line x1="1" y1="0" x2="4" y2="0" style="stroke: black; stroke-width: 1.5" />
          </pattern>
          <pattern id="hatch19" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="2" y1="0" x2="0" y2="4" style="stroke: black; stroke-width: 2" />
          </pattern>
          <pattern id="hatch20" patternTransform="rotate(45 0 0)" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="2" y1="0" x2="0" y2="4" style="stroke: black; stroke-width: 2" />
          </pattern>
          <pattern id="hatch21" patternTransform="rotate(-45 0 0)" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="2" y1="0" x2="0" y2="4" style="stroke: black; stroke-width: 2" />
          </pattern>
          <pattern id="hatch22" patternTransform="rotate(45 0 0)" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="2" y1="0" x2="0" y2="4" style="stroke: black; stroke-width: 1.5" />
            <line x1="2" y1="0" x2="4" y2="0" style="stroke: black; stroke-width: 1.5" />
          </pattern>
          <pattern id="hatch23" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="0" y1="0" x2="0" y2="3" style="stroke: black; stroke-width: 1.5" />
            <line x1="0" y1="0" x2="3" y2="0" style="stroke: black; stroke-width: 1.5" />
          </pattern>
          <pattern id="hatch24" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="2" y1="0" x2="0" y2="4" style="stroke: black; stroke-width: 1.5" />
            <line x1="2" y1="0" x2="4" y2="0" style="stroke: black; stroke-width: 1.5" />
          </pattern>
          <pattern id="hatch25" patternTransform="rotate(-45 0 0)" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="2" y1="0" x2="4" y2="0" style="stroke: black; stroke-width: 2" />
          </pattern>
          <pattern id="hatch26" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="2" y1="0" x2="4" y2="0" style="stroke: black; stroke-width: 2" />
          </pattern>
          <pattern id="hatch27" patternTransform="rotate(45 0 0)" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="2" y1="0" x2="4" y2="0" style="stroke: black; stroke-width: 2" />
          </pattern>
          <pattern id="hatch28" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="2" y1="0" x2="0" y2="2" style="stroke: black; stroke-width: 2" />
          </pattern>
          <pattern id="hatch29" patternTransform="rotate(30 0 0)" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="0" y1="1" x2="0" y2="3" style="stroke: black; stroke-width: 1.5" />
            <line x1="1" y1="0" x2="3" y2="0" style="stroke: black; stroke-width: 1.5" />
          </pattern>
          <pattern id="hatch30" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="1" y1="0" x2="0" y2="3" style="stroke: black; stroke-width: 1.5" />
            <line x1="1" y1="0" x2="3" y2="0" style="stroke: black; stroke-width: 1.5" />
          </pattern>
          <pattern id="hatch31" patternTransform="rotate(45 0 0)" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="1" y1="0" x2="0" y2="3" style="stroke: black; stroke-width: 1.5" />
            <line x1="1" y1="0" x2="3" y2="0" style="stroke: black; stroke-width: 1.5" />
          </pattern>
          <pattern id="hatch32" patternUnits="userSpaceOnUse" width="5" height="5">
            <circle cx="2.5" cy="2.5" r="0.5" style="fill: black" />
          </pattern>
          <pattern id="hatch33" patternUnits="userSpaceOnUse" width="5" height="5">
            <circle cx="2.5" cy="2.5" r="1.5" style="fill: black" />
          </pattern>
          <pattern id="hatch34" patternUnits="userSpaceOnUse" width="5" height="5">
            <circle cx="3" cy="3" r="1" style="fill: black" />
            <circle cx="1" cy="1" r="1" style="fill: black" />
          </pattern>
          <pattern id="hatch35" patternUnits="userSpaceOnUse" width="5" height="5">
            <circle cx="3" cy="3" r="1.5" style="fill: black" />
            <circle cx="1" cy="1" r="1.5" style="fill: black" />
          </pattern>
          <pattern id="hatch36" patternTransform="rotate(-45 0 0)" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="0" y1="0" x2="0" y2="3" transform="rotate(-45 0 0)" style="stroke: black; stroke-width: 1.5" />
          </pattern>
          <pattern id="hatch37" patternTransform="rotate(45 0 0)" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="0" y1="0" x2="0" y2="3" transform="rotate(-45 0 0)" style="stroke: black; stroke-width: 1.5" />
          </pattern>
          <pattern id="hatch38" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="0" y1="0" x2="4" y2="4" style="stroke: black; stroke-width: 1.5" />
            <line x1="0" y1="0" x2="4" y2="0" style="stroke: black; stroke-width: 1.5" />
          </pattern>
          <pattern id="hatch39" patternTransform="rotate(45 0 0)" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="0" y1="0" x2="4" y2="4" style="stroke: black; stroke-width: 1.5" />
            <line x1="0" y1="0" x2="4" y2="0" style="stroke: black; stroke-width: 1.5" />
          </pattern>
          <pattern id="hatch40" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="0" y1="0" x2="3" y2="3" style="stroke: black; stroke-width: 1.5" />
            <line x1="0" y1="0" x2="4" y2="0" style="stroke: black; stroke-width: 1.5" />
          </pattern>
          <pattern id="hatch41" patternTransform="rotate(45 0 0)" patternUnits="userSpaceOnUse" width="4" height="4">
            <line x1="0" y1="0" x2="3" y2="3" style="stroke: black; stroke-width: 1.5" />
            <line x1="0" y1="0" x2="4" y2="0" style="stroke: black; stroke-width: 1.5" />
          </pattern>
        </g>
      </defs>`;
}
function interpolateSpectral(t) {
  if (t < 0.2) {
    const s = t / 0.2;
    return interpolateRgb("#d7191c", "#fdae61")(s);
  } else if (t < 0.4) {
    const s = (t - 0.2) / 0.2;
    return interpolateRgb("#fdae61", "#abdda4")(s);
  } else if (t < 0.6) {
    const s = (t - 0.4) / 0.2;
    return interpolateRgb("#abdda4", "#2b83ba")(s);
  } else {
    const s = (t - 0.6) / 0.4;
    return interpolateRgb("#2b83ba", "#5e4fa2")(s);
  }
}
function interpolateRdYlGn(t) {
  if (t < 0.5) {
    return interpolateRgb("#d7191c", "#ffffbf")(t * 2);
  } else {
    return interpolateRgb("#ffffbf", "#1a9641")((t - 0.5) * 2);
  }
}
function interpolateGreens(t) {
  return interpolateRgb("#f7fcf5", "#00441b")(t);
}
function interpolateGreys(t) {
  return interpolateRgb("#ffffff", "#000000")(t);
}
function interpolateParchment(t) {
  if (t < 0.33) {
    const s = t / 0.33;
    return interpolateRgb("#f5f5dc", "#d2b48c")(s);
  } else if (t < 0.67) {
    const s = (t - 0.33) / 0.34;
    return interpolateRgb("#d2b48c", "#a0826d")(s);
  } else {
    const s = (t - 0.67) / 0.33;
    return interpolateRgb("#a0826d", "#5c4a3a")(s);
  }
}
const colorSchemes = {
  bright: sequential(interpolateSpectral),
  light: sequential(interpolateRdYlGn),
  natural: sequential(rgbBasis(["white", "#EEEECC", "tan", "green", "teal"])),
  green: sequential(interpolateGreens),
  olive: sequential(rgbBasis(["#ffffff", "#cea48d", "#d5b085", "#0c2c19", "#151320"])),
  livid: sequential(rgbBasis(["#BBBBDD", "#2A3440", "#17343B", "#0A1E24"])),
  monochrome: sequential(interpolateGreys),
  parchment: sequential(interpolateParchment)
  // Parchment-style muted earth tones
};
function getColorScheme(scheme = "bright") {
  if (scheme in colorSchemes) {
    return colorSchemes[scheme];
  }
  if (scheme.includes(",")) {
    const colors2 = scheme.split(",").map((c) => c.trim());
    if (!(scheme in colorSchemes)) {
      colorSchemes[scheme] = sequential(rgbBasis(colors2));
    }
    return colorSchemes[scheme];
  }
  return colorSchemes.bright;
}
function getColor(value, scheme = "bright") {
  const colorScale = typeof scheme === "function" ? scheme : getColorScheme(scheme);
  const normalized = 1 - (value < 20 ? value - 5 : value) / 100;
  return colorScale(Math.max(0, Math.min(1, normalized)));
}
function getBiomeColor(biomeIndex, defaultColors, colorScheme = null, height2 = null, moisture = null, temperature = null) {
  if (!colorScheme && biomeIndex >= 0 && biomeIndex < defaultColors.length) {
    return defaultColors[biomeIndex];
  }
  if (height2 !== null && moisture !== null && temperature !== null && colorScheme) {
    return getAdvancedBiomeColor(biomeIndex, defaultColors, colorScheme, height2, moisture, temperature);
  }
  if (height2 !== null && colorScheme) {
    return getColor(height2, colorScheme);
  }
  return biomeIndex >= 0 && biomeIndex < defaultColors.length ? defaultColors[biomeIndex] : "#cccccc";
}
function getAdvancedBiomeColor(biomeIndex, defaultColors, colorScheme, height2, moisture, temperature) {
  const baseColor = biomeIndex >= 0 && biomeIndex < defaultColors.length ? defaultColors[biomeIndex] : "#cccccc";
  const heightColor = getColor(height2, colorScheme);
  const moistureNormalized = Math.max(0, Math.min(1, moisture / 100));
  const moistureColor = interpolateRgb("#d4a574", "#2d8659")(moistureNormalized);
  const tempNormalized = Math.max(0, Math.min(1, (temperature + 50) / 100));
  const tempColor = interpolateRgb("#b3d9ff", "#ff6b6b")(tempNormalized);
  const heightMoisture = blendColors(heightColor, moistureColor, 0.5);
  const climateBlend = blendColors(heightMoisture, tempColor, 0.6);
  const finalColor = blendColors(climateBlend, baseColor, 0.7);
  return finalColor;
}
function blendColors(color1, color2, ratio) {
  const hex1 = color1.replace("#", "");
  const hex2 = color2.replace("#", "");
  const r1 = parseInt(hex1.substr(0, 2), 16);
  const g1 = parseInt(hex1.substr(2, 2), 16);
  const b1 = parseInt(hex1.substr(4, 2), 16);
  const r2 = parseInt(hex2.substr(0, 2), 16);
  const g2 = parseInt(hex2.substr(2, 2), 16);
  const b2 = parseInt(hex2.substr(4, 2), 16);
  const r = Math.round(r1 * ratio + r2 * (1 - ratio));
  const g = Math.round(g1 * ratio + g2 * (1 - ratio));
  const b = Math.round(b1 * ratio + b2 * (1 - ratio));
  return `#${[r, g, b].map((x2) => {
    const hex3 = x2.toString(16);
    return hex3.length === 1 ? "0" + hex3 : hex3;
  }).join("")}`;
}
function getOceanColor(depth, colorScheme = null) {
  const baseColor = "#b4d2f3";
  if (!colorScheme || depth >= 0) {
    return baseColor;
  }
  const depthNormalized = Math.abs(depth) / 9;
  typeof colorScheme === "function" ? colorScheme : getColorScheme(colorScheme);
  const oceanInterpolator = rgbBasis([baseColor, "#7fa8d9", "#4a7fb0", "#2a4f7f"]);
  return oceanInterpolator(depthNormalized);
}
function drawOceanLayersSVG(pack, options = {}) {
  const { cells, vertices } = pack;
  if (!cells || !vertices || !cells.t || !cells.b) {
    return "";
  }
  const layers = options.oceanLayers || "random";
  if (layers === "none") return "";
  const pointsN = cells.i.length;
  const limits = layers === "random" ? randomizeOutline() : layers.split(",").map((s) => +s);
  if (limits.length === 0) return "";
  const opacity = rn(0.4 / limits.length, 2);
  const used = new Uint8Array(pointsN);
  const chains = [];
  for (const i of cells.i) {
    const t = cells.t[i];
    if (t > 0) continue;
    if (used[i] || !limits.includes(t)) continue;
    const start2 = findStart(i, t, cells, vertices, pointsN);
    if (!start2) continue;
    used[i] = 1;
    const chain = connectVertices$1(start2, t, cells, vertices, used, pointsN);
    if (chain.length < 4) continue;
    const relax = 1 + t * -2;
    const relaxed = chain.filter((v, idx) => !(idx % relax) || vertices.c[v].some((c) => c >= pointsN));
    if (relaxed.length < 4) continue;
    const rawPoints = relaxed.map((v) => vertices.p[v]);
    const graphWidth = options.width || 1e3;
    const graphHeight = options.height || 600;
    const points = clipPoly(rawPoints, graphWidth, graphHeight, 1);
    if (points.length < 3) continue;
    chains.push([t, points]);
  }
  const lineGen = line().x((d) => d[0]).y((d) => d[1]).curve(curveBasisClosed);
  const colorScheme = options.colorScheme || null;
  const gradientDefs = generateOceanGradients(limits, colorScheme);
  const svgPaths = [];
  for (const t of limits) {
    const layer = chains.filter((c) => c[0] === t);
    if (layer.length === 0) continue;
    const pathStrings = layer.map(([_, points]) => {
      if (points.length < 3) return "";
      const path = lineGen(points);
      return path || "";
    }).filter((p) => p);
    const pathStr = pathStrings.join(" ");
    if (pathStr) {
      const gradientId = `oceanGradient-${Math.abs(t)}`;
      const fillColor = colorScheme && options.width && options.height ? `url(#${gradientId})` : "#ecf2f9";
      const fillOpacity = colorScheme ? opacity * 1.2 : opacity;
      svgPaths.push(`<path d="${pathStr}" fill="${fillColor}" fill-opacity="${fillOpacity}" />`);
    }
  }
  return gradientDefs + svgPaths.join("");
}
function findStart(i, t, cells, vertices, pointsN) {
  if (cells.b && cells.b[i]) {
    const cellVertices = cells.v[i];
    if (cellVertices) {
      for (const v of cellVertices) {
        if (vertices.c[v] && vertices.c[v].some((c) => c >= pointsN)) {
          return v;
        }
      }
    }
  }
  const cellNeighbors = cells.c[i];
  if (cellNeighbors && cells.v[i]) {
    for (let idx = 0; idx < cellNeighbors.length; idx++) {
      const neighborId = cellNeighbors[idx];
      if (neighborId < 0 || neighborId >= pointsN) continue;
      const neighborT = cells.t[neighborId];
      if (neighborT < t || !neighborT) {
        return cells.v[i][idx];
      }
    }
  }
  return null;
}
function connectVertices$1(start2, t, cells, vertices, used, pointsN) {
  const chain = [];
  let current = start2;
  let iterations = 0;
  const maxIterations = 1e4;
  while (iterations < maxIterations) {
    const prev = chain.length > 0 ? chain[chain.length - 1] : null;
    chain.push(current);
    const vertexCells = vertices.c[current];
    if (vertexCells) {
      vertexCells.forEach((c3) => {
        if (c3 >= 0 && c3 < pointsN && cells.t[c3] === t) {
          used[c3] = 1;
        }
      });
    }
    const vertexNeighbors = vertices.v[current];
    if (!vertexNeighbors || vertexNeighbors.length < 3) break;
    const c = vertices.c[current];
    if (!c || c.length < 3) break;
    const c0 = !cells.t[c[0]] || cells.t[c[0]] === t - 1;
    const c1 = !cells.t[c[1]] || cells.t[c[1]] === t - 1;
    const c2 = !cells.t[c[2]] || cells.t[c[2]] === t - 1;
    let next = null;
    if (vertexNeighbors[0] !== void 0 && vertexNeighbors[0] !== prev && c0 !== c1) {
      next = vertexNeighbors[0];
    } else if (vertexNeighbors[1] !== void 0 && vertexNeighbors[1] !== prev && c1 !== c2) {
      next = vertexNeighbors[1];
    } else if (vertexNeighbors[2] !== void 0 && vertexNeighbors[2] !== prev && c0 !== c2) {
      next = vertexNeighbors[2];
    }
    if (!next || next === current) {
      break;
    }
    current = next;
    iterations++;
    if (current === start2 && chain.length > 3) {
      break;
    }
  }
  if (chain.length > 0 && chain[0] !== chain[chain.length - 1]) {
    chain.push(chain[0]);
  }
  return chain;
}
function randomizeOutline() {
  const limits = [];
  let odd = 0.2;
  for (let l = -9; l < 0; l++) {
    if (Math.random() < odd) {
      odd = 0.2;
      limits.push(l);
    } else {
      odd *= 2;
    }
  }
  return limits;
}
function generateOceanGradients(limits, colorScheme) {
  if (!colorScheme || limits.length === 0) return "";
  const gradients = [];
  for (const t of limits) {
    if (t >= 0) continue;
    const depth = Math.abs(t);
    const gradientId = `oceanGradient-${depth}`;
    const topColor = getOceanColor(-depth + 1, colorScheme) || "#b4d2f3";
    const bottomColor = getOceanColor(-depth, colorScheme) || "#4a7fb0";
    gradients.push(
      `<linearGradient id="${gradientId}" x1="0%" y1="0%" x2="0%" y2="100%">`,
      `  <stop offset="0%" stop-color="${topColor}" stop-opacity="0.6" />`,
      `  <stop offset="100%" stop-color="${bottomColor}" stop-opacity="0.8" />`,
      `</linearGradient>`
    );
  }
  if (gradients.length === 0) return "";
  return `<defs>${gradients.join("")}</defs>`;
}
const defaultRenderConfig = {
  colors: {
    oceanBase: "#d2b48c",
    // Tan/sand for ocean (parchment-style)
    landBase: "#f5f5dc",
    // Beige for land
    lakeFreshwater: "#d4a574",
    // Muted tan for freshwater
    lakeSaltwater: "#c9a671",
    // Slightly darker tan for saltwater
    stateBorderStroke: "#654321",
    // Dark brown ink for borders (parchment-style)
    provinceBorderStroke: "#654321",
    // Same for provinces
    riverStroke: "#a0826d",
    // Muted brown for rivers
    riverFill: "#d4a574",
    // Light tan for river fill
    burgCapitalColor: "#5c4a3a",
    // Dark brown for capitals
    burgTownColor: "#7d6b5a",
    // Medium brown for towns
    routeStroke: "#8b7355",
    // Muted brown for routes
    reliefShadow: "#4a4a3a"
    // Dark brown/gray for relief shadows
  },
  layers: {
    biomes: {
      opacity: 0.6,
      // Lower opacity for parchment look
      showShadows: true
      // Enable relief shadows
    },
    states: {
      opacity: 0.4
      // Lower opacity for parchment look (reduced from 0.5)
    },
    borders: {
      stateWidth: 1,
      stateDashArray: "2",
      provinceWidth: 0.5,
      provinceDashArray: "0 2"
    },
    rivers: {
      strokeWidth: 0.5,
      showLabels: false
    },
    burgs: {
      capitalSize: 1,
      townSize: 0.5,
      showLabels: true
    },
    relief: {
      density: 1.2,
      // Increased density multiplier for dense shaded mountains
      size: 1,
      shadow: true,
      // Enable shadows for depth
      heightScaling: true
      // Scale relief icons based on height
    },
    coast: {
      enabled: true,
      // Enable white glowing coast outline
      stroke: "#ffffff",
      // White stroke for glow
      width: 2,
      // Stroke width
      opacity: 0.8,
      // Stroke opacity
      glowWidth: 3
      // Outer glow width (wider behind main border)
    },
    labels: {
      stateLabelColor: "#5c4a3a",
      // Dark brown for text
      stateLabelStroke: "#f5f5dc",
      // Beige for text outline
      stateLabelStrokeWidth: 0.3
    }
  },
  effects: {
    parchment: {
      enabled: true,
      // Enabled by default with parchment texture
      // Try Azgaar's classic pergamena texture (fallback to transparenttextures if CORS issues)
      textureUrl: "https://i2.wp.com/azgaar.files.wordpress.com/2019/07/pergamena-small.jpg",
      opacity: 0.65,
      // Slightly lower opacity for stronger parchment grain
      blendMode: "multiply",
      // SVG blend mode (ensures multiply for parchment effect)
      // Fallback texture URL (used if primary URL fails to load)
      fallbackTextureUrl: "https://www.transparenttextures.com/patterns/old-paper.png"
      // Note: If both URLs fail, set textureUrl to null and provide local asset later
    },
    pseudo3D: {
      enabled: true,
      // Enabled by default for depth effect
      heightExaggeration: 1,
      shadowOffsetX: 2,
      // Stronger shadow offset X (increased from 1.5)
      shadowOffsetY: 3,
      // Stronger shadow offset Y (increased from 2)
      shadowBlur: 4,
      // Stronger shadow blur (increased from 3)
      shadowOpacity: 0.5
      // Stronger shadow opacity (increased from 0.4)
    },
    sepia: {
      enabled: true,
      // Enable sepia tone filter by default
      amount: 0.4
      // 0-1, higher = more sepia
    }
  },
  colorScheme: "parchment"
  // Default color scheme name
};
const originalRenderConfig = {
  colors: {
    oceanBase: "#b4d2f3",
    landBase: "#eef6fb",
    lakeFreshwater: "#a8c8e0",
    lakeSaltwater: "#9bb5d1",
    stateBorderStroke: "#56566d",
    provinceBorderStroke: "#56566d",
    riverStroke: "#6b93d6",
    riverFill: "#a8c8e0",
    burgCapitalColor: "#333",
    burgTownColor: "#666",
    routeStroke: "#8b7355",
    reliefShadow: "#666666"
  },
  layers: {
    biomes: {
      opacity: 0.7,
      showShadows: false
    },
    states: {
      opacity: 0.5
    },
    borders: {
      stateWidth: 1,
      stateDashArray: "2",
      provinceWidth: 0.5,
      provinceDashArray: "0 2"
    },
    rivers: {
      strokeWidth: 0.5,
      showLabels: false
    },
    burgs: {
      capitalSize: 1,
      townSize: 0.5,
      showLabels: true
    },
    relief: {
      density: 0.3,
      size: 1,
      shadow: false
    },
    labels: {
      stateLabelColor: "#000000",
      stateLabelStroke: "#ffffff",
      stateLabelStrokeWidth: 0.3
    }
  },
  effects: {
    parchment: {
      enabled: false,
      textureUrl: null,
      opacity: 0.8,
      blendMode: "multiply"
    },
    pseudo3D: {
      enabled: false,
      heightExaggeration: 1
    },
    sepia: {
      enabled: false,
      amount: 0.4
    }
  },
  colorScheme: "bright"
};
function isFullConfig(config) {
  var _a, _b, _c, _d, _e, _f;
  if (!config || typeof config !== "object") {
    return false;
  }
  const requiredKeys = ["colors", "layers", "effects"];
  const hasAllKeys = requiredKeys.every(
    (key) => config[key] && typeof config[key] === "object"
  );
  if (!hasAllKeys) {
    return false;
  }
  const hasParchmentIndicator = (
    // Parchment tan ocean color
    ((_a = config.colors) == null ? void 0 : _a.oceanBase) === "#d2b48c" || // Parchment effect enabled
    ((_c = (_b = config.effects) == null ? void 0 : _b.parchment) == null ? void 0 : _c.enabled) === true || // Or original style (bright ocean color)
    ((_d = config.colors) == null ? void 0 : _d.oceanBase) === "#b4d2f3" || // Or explicitly set colorScheme
    config.colorScheme && ["parchment", "bright"].includes(config.colorScheme) || // Or relief density set to parchment value (1.2)
    ((_f = (_e = config.layers) == null ? void 0 : _e.relief) == null ? void 0 : _f.density) === 1.2
  );
  return hasParchmentIndicator;
}
function mergeRenderConfig(userConfig = {}, baseConfig = defaultRenderConfig) {
  if (isFullConfig(userConfig)) {
    if (typeof console !== "undefined" && console.log) {
      console.log("[mergeRenderConfig] Using: FULL USER CONFIG (bypass)");
    }
    return deepCopy(userConfig);
  }
  if (typeof console !== "undefined" && console.log) {
    console.log("[mergeRenderConfig] Using: MERGED CONFIG");
  }
  const merged = deepCopy(baseConfig);
  if (userConfig.colors) {
    Object.assign(merged.colors, userConfig.colors);
  }
  if (userConfig.layers) {
    for (const layerKey in userConfig.layers) {
      if (merged.layers[layerKey] && typeof merged.layers[layerKey] === "object") {
        Object.assign(merged.layers[layerKey], userConfig.layers[layerKey]);
      } else {
        merged.layers[layerKey] = userConfig.layers[layerKey];
      }
    }
  }
  if (userConfig.effects) {
    for (const effectKey in userConfig.effects) {
      if (merged.effects[effectKey] && typeof merged.effects[effectKey] === "object") {
        Object.assign(merged.effects[effectKey], userConfig.effects[effectKey]);
      } else {
        merged.effects[effectKey] = userConfig.effects[effectKey];
      }
    }
  }
  if (userConfig.colorScheme !== void 0) {
    merged.colorScheme = userConfig.colorScheme;
  }
  return merged;
}
function getDefaultRenderConfig() {
  return deepCopy(defaultRenderConfig);
}
function getOriginalRenderConfig() {
  return deepCopy(originalRenderConfig);
}
const LEGACY_STYLE_CONSTANTS = {
  landBase: "#eef6fb",
  lakeFreshwater: "#a8c8e0",
  lakeSaltwater: "#9bb5d1",
  stateBorderStroke: "#56566d",
  stateBorderWidth: 1,
  stateBorderDashArray: "2",
  provinceBorderStroke: "#56566d",
  provinceBorderWidth: 0.5,
  provinceBorderDashArray: "0 2",
  riverStroke: "#6b93d6",
  riverFill: "#a8c8e0",
  burgCapitalSize: 1,
  burgTownSize: 0.5,
  burgCapitalColor: "#333",
  burgTownColor: "#666"
};
const MIN_LAND_HEIGHT = 20;
function getIsolines(pack, getType, options = { fill: false, waterGap: false, halo: false }) {
  var _a, _b, _c, _d, _e;
  const { cells, vertices } = pack;
  if (!vertices || !vertices.c || !Array.isArray(vertices.c) || vertices.c.length === 0) {
    if (typeof console !== "undefined" && console.log) {
      console.warn("[getIsolines] Vertex graph not available, returning empty isolines");
    }
    return {};
  }
  let verticesWith3Adj = 0;
  let verticesWithMoreAdj = 0;
  let verticesWithLessAdj = 0;
  const sampleSize = Math.min(100, vertices.v.length);
  for (let i = 0; i < sampleSize; i++) {
    if (vertices.v[i] && Array.isArray(vertices.v[i])) {
      const count = vertices.v[i].length;
      if (count === 3) verticesWith3Adj++;
      else if (count > 3) verticesWithMoreAdj++;
      else if (count < 3 && count > 0) verticesWithLessAdj++;
    }
  }
  if (typeof console !== "undefined" && console.log) {
    console.log("[getIsolines:diagnostics] Vertex structure:", {
      totalVertices: vertices.v.length,
      sampleSize,
      verticesWith3Adj,
      verticesWithMoreAdj,
      verticesWithLessAdj,
      threeAdjPercent: (verticesWith3Adj / sampleSize * 100).toFixed(1) + "%"
    });
  }
  const isolines = {};
  let connectVerticesErrors = 0;
  let isolineCount = 0;
  let skippedCount = 0;
  function addIsoline(type, vertices2, vertexChain) {
    if (!isolines[type]) isolines[type] = {};
    if (options.fill) {
      if (!isolines[type].fill) isolines[type].fill = "";
      isolines[type].fill += getFillPath(vertices2, vertexChain);
    }
    if (options.waterGap) {
      if (!isolines[type].waterGap) isolines[type].waterGap = "";
      const isLandVertex = (vertexId) => {
        if (vertexId < 0 || vertexId >= vertices2.c.length || !vertices2.c[vertexId]) return false;
        return vertices2.c[vertexId].every((i) => i >= 0 && i < cells.h.length && cells.h[i] >= MIN_LAND_HEIGHT);
      };
      isolines[type].waterGap += getBorderPath(vertices2, vertexChain, isLandVertex);
    }
    if (options.halo) {
      if (!isolines[type].halo) isolines[type].halo = "";
      const isBorderVertex = (vertexId) => {
        if (vertexId < 0 || vertexId >= vertices2.c.length || !vertices2.c[vertexId]) return false;
        return vertices2.c[vertexId].some((i) => i >= 0 && i < cells.b.length && cells.b[i]);
      };
      isolines[type].halo += getBorderPath(vertices2, vertexChain, isBorderVertex);
    }
  }
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
    const startingVertex = (_e = cells.v[cellId]) == null ? void 0 : _e.find((v) => {
      var _a2;
      return (_a2 = vertices.c[v]) == null ? void 0 : _a2.some(ofDifferentType);
    });
    if (startingVertex === void 0) continue;
    try {
      const vertexChain = connectVertices({
        vertices,
        startingVertex,
        ofSameType,
        addToChecked,
        closeRing: true
      });
      if (vertexChain.length < 3) {
        skippedCount++;
        continue;
      }
      addIsoline(type, vertices, vertexChain);
      isolineCount++;
    } catch (error) {
      connectVerticesErrors++;
      console.warn(`Failed to connect vertices for cell ${cellId}:`, error.message);
      continue;
    }
  }
  if (typeof console !== "undefined" && console.log) {
    const totalTypes = Object.keys(isolines).length;
    console.log("[getIsolines:diagnostics] Results:", {
      totalTypes,
      isolineCount,
      skippedCount,
      connectVerticesErrors
    });
  }
  return isolines;
}
function connectVertices({ vertices, startingVertex, ofSameType, addToChecked, closeRing }) {
  const MAX_ITERATIONS = vertices.c.length;
  const chain = [];
  let next = startingVertex;
  for (let i = 0; i === 0 || next !== startingVertex; i++) {
    const previous = chain.at(-1);
    const current = next;
    chain.push(current);
    const neibCells = vertices.c[current];
    if (addToChecked) neibCells.filter(ofSameType).forEach(addToChecked);
    const [c1, c2, c3] = neibCells.map(ofSameType);
    const [v1, v2, v3] = vertices.v[current];
    if (v1 !== previous && c1 !== c2) next = v1;
    else if (v2 !== previous && c2 !== c3) next = v2;
    else if (v3 !== previous && c1 !== c3) next = v3;
    if (next >= vertices.c.length) {
      console.error("ConnectVertices: next vertex is out of bounds");
      break;
    }
    if (next === current) {
      console.error("ConnectVertices: next vertex is not found");
      break;
    }
    if (i === MAX_ITERATIONS) {
      console.error("ConnectVertices: max iterations reached", MAX_ITERATIONS);
      break;
    }
  }
  chain.push(startingVertex);
  return chain;
}
function getFillPath(vertices, vertexChain) {
  const points = vertexChain.map((vertexId) => vertices.p[vertexId]);
  if (points.length === 0) return "";
  const firstPoint = points[0];
  const restPoints = points.slice(1);
  return `M${firstPoint[0]},${firstPoint[1]} L${restPoints.map((p) => `${p[0]},${p[1]}`).join(" ")} Z`;
}
function getBorderPath(vertices, vertexChain, discontinue) {
  let discontinued = true;
  const pathParts = [];
  for (const vertexId of vertexChain) {
    if (vertexId < 0 || vertexId >= vertices.p.length || !vertices.p[vertexId]) {
      continue;
    }
    if (discontinue(vertexId)) {
      discontinued = true;
      continue;
    }
    const operation = discontinued ? "M" : "L";
    discontinued = false;
    const point2 = vertices.p[vertexId];
    if (point2 && point2.length >= 2) {
      pathParts.push(`${operation}${point2[0]},${point2[1]}`);
    }
  }
  return pathParts.join(" ").trim();
}
function getGappedFillPaths(elementName, fill, waterGap, color2, index) {
  let html = "";
  if (fill) {
    html += `<path d="${fill}" fill="${color2}" id="${elementName}${index}" class="${elementName}-${index}" />`;
  }
  if (waterGap) {
    html += `<path d="${waterGap}" fill="none" stroke="${color2}" stroke-width="3" id="${elementName}-gap${index}" class="${elementName}-gap-${index}" />`;
  }
  return html;
}
function drawBiomesSVG(pack, biomesData, colorScheme = null, renderConfig2 = null) {
  var _a, _b;
  if (!pack.cells || !pack.cells.biome) return "";
  try {
    const cells = pack.cells;
    const bodyPaths = [];
    const hasVertexGraph = pack.vertices && pack.vertices.c && Array.isArray(pack.vertices.c) && pack.vertices.c.length > 0;
    const hasVertexIndices = cells.v && cells.v.length > 0 && cells.v[0] && Array.isArray(cells.v[0]) && cells.v[0].length > 0 && typeof cells.v[0][0] === "number";
    if (hasVertexGraph && hasVertexIndices) {
      const isolines = getIsolines(pack, (cellId) => cells.biome[cellId], {
        fill: true,
        waterGap: true
      });
      const hasIsolines = Object.keys(isolines).length > 0;
      if (hasIsolines) {
        Object.entries(isolines).forEach(([index, { fill, waterGap }]) => {
          const biomeIndex = parseInt(index);
          if (biomeIndex >= 0 && biomeIndex < biomesData.color.length) {
            let color2 = biomesData.color[biomeIndex];
            if (colorScheme && cells.h) {
              let avgHeight = 50;
              let avgMoisture = 50;
              let avgTemp = 15;
              let cellCount = 0;
              for (const cellId of cells.i) {
                if (cells.biome[cellId] === biomeIndex && cells.h[cellId] >= 20) {
                  avgHeight += cells.h[cellId];
                  if (cells.flux && cells.flux[cellId] !== void 0) {
                    avgMoisture += cells.flux[cellId];
                  }
                  const gridIndex = cells.g && cells.g[cellId] !== void 0 ? cells.g[cellId] : void 0;
                  if (gridIndex !== void 0 && pack.grid && pack.grid.cells && pack.grid.cells.temp) {
                    const temp = pack.grid.cells.temp[gridIndex];
                    if (temp !== void 0 && !isNaN(temp)) {
                      avgTemp += temp;
                    }
                  }
                  cellCount++;
                }
              }
              if (cellCount > 0) {
                avgHeight = avgHeight / cellCount;
                avgMoisture = avgMoisture / cellCount;
                avgTemp = avgTemp / cellCount;
                color2 = getBiomeColor(biomeIndex, biomesData.color, colorScheme, avgHeight, avgMoisture, avgTemp);
              }
            }
            const pathStr = getGappedFillPaths("biome", fill, waterGap, color2, biomeIndex);
            bodyPaths.push(pathStr || "");
          }
        });
        return bodyPaths.join("");
      }
    }
    const biomeGroups = {};
    for (let i = 0; i < cells.i.length; i++) {
      const biomeId = cells.biome[i];
      if (biomeId === void 0 || biomeId < 0) continue;
      if (!biomeGroups[biomeId]) {
        biomeGroups[biomeId] = [];
      }
      let polygon = null;
      if (cells.vCoords && cells.vCoords[i] && Array.isArray(cells.vCoords[i]) && cells.vCoords[i].length > 0) {
        polygon = cells.vCoords[i];
      } else if (cells.v && cells.v[i] && pack.vertices && pack.vertices.p) {
        const vertexIndices = cells.v[i];
        if (Array.isArray(vertexIndices) && vertexIndices.length > 0) {
          if (Array.isArray(vertexIndices[0]) && vertexIndices[0].length === 2) {
            polygon = vertexIndices;
          } else {
            polygon = vertexIndices.map((vId) => {
              if (typeof vId !== "number" || vId < 0 || !pack.vertices.p || !pack.vertices.p[vId]) return null;
              const vertex = pack.vertices.p[vId];
              if (!Array.isArray(vertex) || vertex.length < 2) return null;
              return vertex;
            }).filter((p) => p !== null && p !== void 0 && Array.isArray(p) && p.length >= 2);
          }
        }
      }
      if (!polygon || polygon.length < 3) continue;
      if (polygon && polygon.length > 0) {
        const path = polygon.map(
          ([x2, y2], idx) => idx === 0 ? `M${x2},${y2}` : `L${x2},${y2}`
        ).join(" ") + " Z";
        let color2 = biomeId < biomesData.color.length ? biomesData.color[biomeId] : biomesData.color[0];
        if (colorScheme && cells.h && cells.h[i] >= 20) {
          const height2 = cells.h[i];
          const moisture = cells.flux && cells.flux[i] !== void 0 ? cells.flux[i] : 50;
          const gridIndex = cells.g && cells.g[i] !== void 0 ? cells.g[i] : void 0;
          let temperature = 15;
          if (gridIndex !== void 0 && pack.vertices && pack.grid && pack.grid.cells && pack.grid.cells.temp) {
            const temp = pack.grid.cells.temp[gridIndex];
            if (temp !== void 0 && !isNaN(temp)) {
              temperature = temp;
            }
          }
          color2 = getBiomeColor(biomeId, biomesData.color, colorScheme, height2, moisture, temperature);
        }
        const biomeOpacity = ((_b = (_a = renderConfig2 == null ? void 0 : renderConfig2.layers) == null ? void 0 : _a.biomes) == null ? void 0 : _b.opacity) ?? 0.7;
        biomeGroups[biomeId].push(`<path d="${path}" fill="${color2}" stroke="${color2}" stroke-width="0.5" opacity="${biomeOpacity}" />`);
      }
    }
    Object.entries(biomeGroups).forEach(([biomeId, paths]) => {
      bodyPaths.push(`<g id="biome-${biomeId}" class="biome-${biomeId}">${paths.join("")}</g>`);
    });
    return bodyPaths.join("");
  } catch (error) {
    console.error("Error in drawBiomesSVG (possibly from cached build):", error.message);
    console.error("Stack:", error.stack);
    return "";
  }
}
function drawStatesSVG(pack, renderConfig2 = null) {
  var _a, _b;
  if (!pack.cells || !pack.cells.state || !pack.states) return "";
  try {
    const { cells, states } = pack;
    const bodyPaths = [];
    const hasVertexGraph = pack.vertices && pack.vertices.c && Array.isArray(pack.vertices.c) && pack.vertices.c.length > 0;
    const hasVertexIndices = cells.v && cells.v.length > 0 && cells.v[0] && Array.isArray(cells.v[0]) && cells.v[0].length > 0 && typeof cells.v[0][0] === "number";
    if (hasVertexGraph && hasVertexIndices) {
      const isolines = getIsolines(pack, (cellId) => cells.state[cellId], {
        fill: true,
        waterGap: true
      });
      const hasIsolines = Object.keys(isolines).length > 0;
      if (hasIsolines) {
        Object.entries(isolines).forEach(([index, { fill, waterGap }]) => {
          const stateIndex = parseInt(index);
          if (stateIndex > 0 && stateIndex < states.length && states[stateIndex]) {
            const color2 = states[stateIndex].color || "#cccccc";
            const pathStr = getGappedFillPaths("state", fill, waterGap, color2, stateIndex);
            bodyPaths.push(pathStr || "");
          }
        });
        return bodyPaths.join("");
      }
    }
    const stateGroups = {};
    for (let i = 0; i < cells.i.length; i++) {
      const stateId = cells.state[i];
      if (stateId === void 0 || stateId < 0 || !states[stateId]) continue;
      if (!stateGroups[stateId]) {
        stateGroups[stateId] = [];
      }
      let polygon = null;
      if (cells.vCoords && cells.vCoords[i] && Array.isArray(cells.vCoords[i]) && cells.vCoords[i].length > 0) {
        polygon = cells.vCoords[i];
      } else if (cells.v && cells.v[i] && pack.vertices && pack.vertices.p) {
        const vertexIndices = cells.v[i];
        if (Array.isArray(vertexIndices) && vertexIndices.length > 0) {
          if (Array.isArray(vertexIndices[0]) && vertexIndices[0].length === 2) {
            polygon = vertexIndices;
          } else {
            polygon = vertexIndices.map((vId) => pack.vertices.p[vId]).filter((p) => p !== void 0);
          }
        }
      }
      if (polygon && polygon.length > 0) {
        const path = polygon.map(
          ([x2, y2], idx) => idx === 0 ? `M${x2},${y2}` : `L${x2},${y2}`
        ).join(" ") + " Z";
        const color2 = states[stateId].color || "#cccccc";
        const stateOpacity = ((_b = (_a = renderConfig2 == null ? void 0 : renderConfig2.layers) == null ? void 0 : _a.states) == null ? void 0 : _b.opacity) ?? 0.6;
        stateGroups[stateId].push(`<path d="${path}" fill="${color2}" stroke="${color2}" stroke-width="0.5" opacity="${stateOpacity}" />`);
      }
    }
    Object.entries(stateGroups).forEach(([stateId, paths]) => {
      bodyPaths.push(`<g id="state-${stateId}">${paths.join("")}</g>`);
    });
    return bodyPaths.join("");
  } catch (error) {
    console.error("Error in drawStatesSVG (possibly from cached build):", error.message);
    console.error("Stack:", error.stack);
    return "";
  }
}
function drawBordersSVG(pack, renderConfig2 = null) {
  var _a, _b, _c, _d;
  if (!pack.cells || !pack.cells.state) {
    if (typeof console !== "undefined" && console.log) {
      console.log("[drawBordersSVG] No cells.state, returning empty");
    }
    return { stateBorders: "", provinceBorders: "" };
  }
  const { cells, vertices } = pack;
  const hasVertexGraph = vertices && vertices.c && Array.isArray(vertices.c) && vertices.c.length > 0 && cells.v && cells.v.length > 0;
  if (!hasVertexGraph) {
    if (typeof console !== "undefined" && console.log) {
      console.log("[drawBordersSVG] No vertex graph, using simplified rendering");
    }
    return drawBordersSVGSimplified(pack);
  }
  const statePath = [];
  const provincePath = [];
  const checked = {};
  if (typeof console !== "undefined" && console.log) {
    const statesCount = pack.states ? pack.states.length : 0;
    const provincesCount = pack.provinces ? pack.provinces.length : 0;
    const uniqueStates = /* @__PURE__ */ new Set();
    const uniqueProvinces = /* @__PURE__ */ new Set();
    for (let i = 0; i < Math.min(cells.i.length, 1e3); i++) {
      if (cells.state[i] !== void 0) uniqueStates.add(cells.state[i]);
      if (cells.province && cells.province[i] !== void 0) uniqueProvinces.add(cells.province[i]);
    }
    console.log("[drawBordersSVG] Border data:", {
      statesCount,
      provincesCount,
      uniqueStatesInSample: uniqueStates.size,
      uniqueProvincesInSample: uniqueProvinces.size,
      hasVertexGraph
    });
  }
  const isLand2 = (cellId) => cells.h[cellId] >= MIN_LAND_HEIGHT;
  for (let cellId = 0; cellId < cells.i.length; cellId++) {
    if (!cells.state[cellId]) continue;
    const provinceId = (_a = cells.province) == null ? void 0 : _a[cellId];
    const stateId = cells.state[cellId];
    if (provinceId) {
      const provToCell = (_b = cells.c[cellId]) == null ? void 0 : _b.find((neibId) => {
        var _a2;
        const neibProvinceId = (_a2 = cells.province) == null ? void 0 : _a2[neibId];
        return neibProvinceId && provinceId > neibProvinceId && !checked[`prov-${provinceId}-${neibProvinceId}-${cellId}`] && cells.state[neibId] === stateId;
      });
      if (provToCell !== void 0) {
        const addToChecked = (cId) => checked[`prov-${provinceId}-${cells.province[provToCell]}-${cId}`] = true;
        const border = getBorder({ type: "province", fromCell: cellId, toCell: provToCell, addToChecked });
        if (border) {
          provincePath.push(border);
          continue;
        }
      }
    }
    const stateToCell = (_c = cells.c[cellId]) == null ? void 0 : _c.find((neibId) => {
      const neibStateId = cells.state[neibId];
      const isRegularBorder = isLand2(neibId) && stateId > neibStateId && neibStateId !== 0;
      const isNeutralBorder = isLand2(neibId) && (stateId === 0 || neibStateId === 0) && stateId !== neibStateId;
      const isCoastlineBorder = !isLand2(neibId) && stateId === 0;
      return (isRegularBorder || isNeutralBorder || isCoastlineBorder) && !checked[`state-${stateId}-${neibStateId}-${cellId}`];
    });
    if (stateToCell !== void 0) {
      const addToChecked = (cId) => checked[`state-${stateId}-${cells.state[stateToCell]}-${cId}`] = true;
      const border = getBorder({ type: "state", fromCell: cellId, toCell: stateToCell, addToChecked });
      if (border) {
        statePath.push(border);
        continue;
      }
    }
  }
  function getBorder({ type, fromCell, toCell, addToChecked }) {
    const getType = (cellId) => {
      var _a2;
      return (_a2 = cells[type]) == null ? void 0 : _a2[cellId];
    };
    const isTypeFrom = (cellId) => cellId < cells.i.length && getType(cellId) === getType(fromCell);
    const isTypeTo = (cellId) => cellId < cells.i.length && getType(cellId) === getType(toCell);
    addToChecked(fromCell);
    const cellVertices = cells.v[fromCell];
    if (!cellVertices || cellVertices.length === 0) {
      if (typeof console !== "undefined" && console.warn) {
        console.warn(`[getBorder] Cell ${fromCell} has no vertices`);
      }
      return null;
    }
    const startingVertex = cellVertices.find((v) => {
      if (typeof v !== "number" || v < 0 || v >= vertices.c.length || !vertices.c[v] || !Array.isArray(vertices.c[v])) {
        return false;
      }
      return vertices.c[v].some((i) => isLand2(i) && isTypeTo(i));
    });
    if (startingVertex === void 0) {
      if (typeof console !== "undefined" && console.warn) {
        console.warn(`[getBorder] No starting vertex found for ${type} border from cell ${fromCell} to ${toCell}`);
      }
      return null;
    }
    const checkVertex = (vertex) => {
      var _a2, _b2;
      return ((_a2 = vertices.c[vertex]) == null ? void 0 : _a2.some(isTypeFrom)) && ((_b2 = vertices.c[vertex]) == null ? void 0 : _b2.some((c) => isLand2(c) && isTypeTo(c)));
    };
    const chain = getVerticesLine({
      vertices,
      startingVertex,
      checkCell: isTypeFrom,
      checkVertex,
      addToChecked
    });
    if (chain.length > 1) {
      return "M" + chain.map((vId) => `${vertices.p[vId][0]},${vertices.p[vId][1]}`).join(" ");
    }
    return null;
  }
  function getVerticesLine({ vertices: vertices2, startingVertex, checkCell, checkVertex, addToChecked }) {
    let chain = [];
    let next = startingVertex;
    const MAX_ITERATIONS = vertices2.c.length;
    for (let run = 0; run < 2; run++) {
      chain = [];
      for (let i = 0; i < MAX_ITERATIONS; i++) {
        const previous = chain[chain.length - 1];
        const current = next;
        if (current < 0 || current >= vertices2.c.length || !vertices2.c[current] || !Array.isArray(vertices2.c[current])) {
          break;
        }
        chain.push(current);
        const neibCells = vertices2.c[current];
        if (neibCells) neibCells.forEach(addToChecked);
        const [c1, c2, c3] = (neibCells == null ? void 0 : neibCells.map(checkCell)) || [false, false, false];
        const [v1, v2, v3] = vertices2.v[current] || [null, null, null];
        if (v1 !== void 0 && v1 !== previous && v1 < vertices2.c.length && vertices2.c[v1] && c1 !== c2) {
          next = v1;
        } else if (v2 !== void 0 && v2 !== previous && v2 < vertices2.c.length && vertices2.c[v2] && c2 !== c3) {
          next = v2;
        } else if (v3 !== void 0 && v3 !== previous && v3 < vertices2.c.length && vertices2.c[v3] && c1 !== c3) {
          next = v3;
        } else {
          break;
        }
        if (next === current || next === startingVertex) {
          if (next === startingVertex) chain.push(startingVertex);
          startingVertex = next;
          break;
        }
      }
    }
    return chain;
  }
  const coastlineBorders = [];
  for (let cellId = 0; cellId < cells.i.length; cellId++) {
    if (!cells.state || cells.state[cellId] !== 0 || !isLand2(cellId)) continue;
    const hasWaterNeighbor = cells.c && cells.c[cellId] && cells.c[cellId].some((neibId) => {
      return neibId >= 0 && neibId < cells.i.length && !isLand2(neibId);
    });
    if (hasWaterNeighbor && !checked[`coastline-${cellId}`]) {
      const coastlineBorder = getCoastlineBorder(cellId, cells, vertices, isLand2);
      if (coastlineBorder) {
        coastlineBorders.push(coastlineBorder);
        checked[`coastline-${cellId}`] = true;
      }
    }
  }
  const allStateBorders = [...statePath, ...coastlineBorders];
  const borderColors = (renderConfig2 == null ? void 0 : renderConfig2.colors) || {};
  const borderLayers = ((_d = renderConfig2 == null ? void 0 : renderConfig2.layers) == null ? void 0 : _d.borders) || {};
  const stateBorderStroke = borderColors.stateBorderStroke || LEGACY_STYLE_CONSTANTS.stateBorderStroke;
  const stateBorderWidth = borderLayers.stateWidth ?? LEGACY_STYLE_CONSTANTS.stateBorderWidth;
  const stateBorderDashArray = borderLayers.stateDashArray || LEGACY_STYLE_CONSTANTS.stateBorderDashArray;
  const provinceBorderStroke = borderColors.provinceBorderStroke || LEGACY_STYLE_CONSTANTS.provinceBorderStroke;
  const provinceBorderWidth = borderLayers.provinceWidth ?? LEGACY_STYLE_CONSTANTS.provinceBorderWidth;
  const provinceBorderDashArray = borderLayers.provinceDashArray || LEGACY_STYLE_CONSTANTS.provinceBorderDashArray;
  const stateBordersSVG = allStateBorders.length ? `<path d="${allStateBorders.join(" ")}" stroke="${stateBorderStroke}" stroke-width="${stateBorderWidth}" stroke-dasharray="${stateBorderDashArray}" fill="none" />` : "";
  const provinceBordersSVG = provincePath.length ? `<path d="${provincePath.join(" ")}" stroke="${provinceBorderStroke}" stroke-width="${provinceBorderWidth}" stroke-dasharray="${provinceBorderDashArray}" fill="none" />` : "";
  return { stateBorders: stateBordersSVG, provinceBorders: provinceBordersSVG };
}
function getCoastlineBorder(cellId, cells, vertices, isLand2) {
  if (!cells.v || !cells.v[cellId] || !vertices || !vertices.p) return null;
  const cellVertices = cells.v[cellId];
  if (!Array.isArray(cellVertices) || cellVertices.length < 3) return null;
  const coastlineVertices = [];
  for (const vId of cellVertices) {
    if (typeof vId !== "number" || vId < 0 || vId >= (vertices.c ? vertices.c.length : 0)) continue;
    const adjCells = vertices.c && vertices.c[vId] ? vertices.c[vId] : [];
    const hasWaterNeighbor = adjCells.some((cId) => cId >= 0 && cId < cells.i.length && !isLand2(cId));
    if (hasWaterNeighbor) {
      coastlineVertices.push(vId);
    }
  }
  if (coastlineVertices.length < 2) return null;
  const points = coastlineVertices.map((vId) => vertices.p && vertices.p[vId] ? vertices.p[vId] : null).filter((p) => p && Array.isArray(p) && p.length >= 2);
  if (points.length < 2) return null;
  return "M" + points.map(([x2, y2]) => `${rn(x2, 2)},${rn(y2, 2)}`).join(" ");
}
function drawCoastOutlineSVG(pack, renderConfig2 = null) {
  var _a;
  if (!pack.cells || !pack.cells.h) return "";
  const coastConfig = ((_a = renderConfig2 == null ? void 0 : renderConfig2.layers) == null ? void 0 : _a.coast) || {};
  if (coastConfig.enabled === false) return "";
  const isLand2 = (cellId) => pack.cells.h[cellId] >= MIN_LAND_HEIGHT;
  const { cells, vertices } = pack;
  if (!vertices || !vertices.c || !Array.isArray(vertices.c) || vertices.c.length === 0) {
    return "";
  }
  const coastPaths = [];
  const checked = {};
  for (let cellId = 0; cellId < cells.i.length; cellId++) {
    if (!isLand2(cellId)) continue;
    const hasWaterNeighbor = cells.c && cells.c[cellId] && cells.c[cellId].some((neibId) => {
      return neibId >= 0 && neibId < cells.i.length && !isLand2(neibId);
    });
    if (hasWaterNeighbor && !checked[`coast-${cellId}`]) {
      const coastlineBorder = getCoastlineBorder(cellId, cells, vertices, isLand2);
      if (coastlineBorder && !checked[`coast-${cellId}`]) {
        coastPaths.push(coastlineBorder);
        checked[`coast-${cellId}`] = true;
      }
    }
  }
  if (coastPaths.length === 0) return "";
  const stroke = coastConfig.stroke || "#ffffff";
  const width2 = coastConfig.width ?? 2;
  const opacity = coastConfig.opacity ?? 0.8;
  const glowWidth = coastConfig.glowWidth ?? 3;
  const coastPath = coastPaths.join(" ");
  return `
    <path d="${coastPath}" stroke="${stroke}" stroke-width="${glowWidth}" opacity="${opacity * 0.6}" fill="none" class="coast-glow" />
    <path d="${coastPath}" stroke="${stroke}" stroke-width="${width2}" opacity="${opacity}" fill="none" class="coast-outline" />
  `;
}
function drawBordersSVGSimplified(pack) {
  var _a, _b, _c;
  const { cells } = pack;
  const statePath = [];
  const provincePath = [];
  const checked = {};
  if (typeof console !== "undefined" && console.log) {
    console.log("[drawBordersSVGSimplified] Starting simplified border rendering");
  }
  const isLand2 = (cellId) => cells.h[cellId] >= MIN_LAND_HEIGHT;
  for (let cellId = 0; cellId < cells.i.length; cellId++) {
    if (!cells.state[cellId] || !isLand2(cellId)) continue;
    const provinceId = (_a = cells.province) == null ? void 0 : _a[cellId];
    const stateId = cells.state[cellId];
    let polygon = null;
    if (cells.vCoords && cells.vCoords[cellId]) {
      polygon = cells.vCoords[cellId];
    } else if (cells.v && cells.v[cellId] && pack.vertices && pack.vertices.p) {
      const vertexIndices = cells.v[cellId];
      if (Array.isArray(vertexIndices) && vertexIndices.length > 0) {
        if (Array.isArray(vertexIndices[0]) && vertexIndices[0].length === 2) {
          polygon = vertexIndices;
        } else {
          polygon = vertexIndices.map((vId) => pack.vertices.p[vId]).filter((p) => p !== void 0);
        }
      }
    }
    if (!polygon || polygon.length < 3) continue;
    const neighbors = cells.c[cellId] || [];
    for (const neibId of neighbors) {
      if (neibId >= cells.i.length || !isLand2(neibId)) continue;
      const neibStateId = cells.state[neibId];
      const neibProvinceId = (_b = cells.province) == null ? void 0 : _b[neibId];
      if (provinceId && neibProvinceId && provinceId !== neibProvinceId && stateId === neibStateId) {
        const key = `prov-${Math.min(provinceId, neibProvinceId)}-${Math.max(provinceId, neibProvinceId)}-${cellId}`;
        if (!checked[key]) {
          checked[key] = true;
          const sharedEdge = findSharedEdge(polygon, neibId, pack);
          if (sharedEdge) {
            provincePath.push(`M${sharedEdge[0][0]},${sharedEdge[0][1]} L${sharedEdge[1][0]},${sharedEdge[1][1]}`);
          }
        }
      }
      if (stateId !== neibStateId && stateId > neibStateId) {
        const key = `state-${neibStateId}-${stateId}-${cellId}`;
        if (!checked[key]) {
          checked[key] = true;
          const sharedEdge = findSharedEdge(polygon, neibId, pack);
          if (sharedEdge) {
            statePath.push(`M${sharedEdge[0][0]},${sharedEdge[0][1]} L${sharedEdge[1][0]},${sharedEdge[1][1]}`);
          }
        }
      }
    }
  }
  const borderColors = (renderConfig == null ? void 0 : renderConfig.colors) || {};
  const borderLayers = ((_c = renderConfig == null ? void 0 : renderConfig.layers) == null ? void 0 : _c.borders) || {};
  const stateBorderStroke = borderColors.stateBorderStroke || LEGACY_STYLE_CONSTANTS.stateBorderStroke;
  const stateBorderWidth = borderLayers.stateWidth ?? LEGACY_STYLE_CONSTANTS.stateBorderWidth;
  const stateBorderDashArray = borderLayers.stateDashArray || LEGACY_STYLE_CONSTANTS.stateBorderDashArray;
  const provinceBorderStroke = borderColors.provinceBorderStroke || LEGACY_STYLE_CONSTANTS.provinceBorderStroke;
  const provinceBorderWidth = borderLayers.provinceWidth ?? LEGACY_STYLE_CONSTANTS.provinceBorderWidth;
  const provinceBorderDashArray = borderLayers.provinceDashArray || LEGACY_STYLE_CONSTANTS.provinceBorderDashArray;
  const stateBordersSVG = statePath.length ? `<path d="${statePath.join(" ")}" stroke="${stateBorderStroke}" stroke-width="${stateBorderWidth}" stroke-dasharray="${stateBorderDashArray}" fill="none" />` : "";
  const provinceBordersSVG = provincePath.length ? `<path d="${provincePath.join(" ")}" stroke="${provinceBorderStroke}" stroke-width="${provinceBorderWidth}" stroke-dasharray="${provinceBorderDashArray}" fill="none" />` : "";
  return { stateBorders: stateBordersSVG, provinceBorders: provinceBordersSVG };
}
function findSharedEdge(polygon1, cellId2, pack) {
  if (!polygon1 || polygon1.length < 2) return null;
  let polygon2 = null;
  if (pack.cells.vCoords && pack.cells.vCoords[cellId2]) {
    polygon2 = pack.cells.vCoords[cellId2];
  } else if (pack.cells.v && pack.cells.v[cellId2] && pack.vertices && pack.vertices.p) {
    const vertexIndices = pack.cells.v[cellId2];
    if (Array.isArray(vertexIndices) && vertexIndices.length > 0) {
      if (Array.isArray(vertexIndices[0]) && vertexIndices[0].length === 2) {
        polygon2 = vertexIndices;
      } else {
        polygon2 = vertexIndices.map((vId) => pack.vertices.p[vId]).filter((p) => p !== void 0);
      }
    }
  }
  if (!polygon2 || polygon2.length < 2) return null;
  let minDist = Infinity;
  let closestEdge = null;
  for (let i = 0; i < polygon1.length; i++) {
    const p1 = polygon1[i];
    const p1Next = polygon1[(i + 1) % polygon1.length];
    for (let j = 0; j < polygon2.length; j++) {
      const p2 = polygon2[j];
      const p2Next = polygon2[(j + 1) % polygon2.length];
      const dist1 = Math.sqrt((p1[0] - p2[0]) ** 2 + (p1[1] - p2[1]) ** 2);
      const dist22 = Math.sqrt((p1Next[0] - p2Next[0]) ** 2 + (p1Next[1] - p2Next[1]) ** 2);
      if (dist1 < 1 && dist22 < 1) {
        return [[p1[0], p1[1]], [p1Next[0], p1Next[1]]];
      }
      const avgDist = (dist1 + dist22) / 2;
      if (avgDist < minDist) {
        minDist = avgDist;
        closestEdge = [[p1[0], p1[1]], [p1Next[0], p1Next[1]]];
      }
    }
  }
  return minDist < 5 ? closestEdge : null;
}
function drawRiversSVG(pack, renderConfig2 = null) {
  if (!pack.rivers || !Array.isArray(pack.rivers)) return "";
  const riverPaths = pack.rivers.map((river) => {
    var _a, _b;
    if (!river.cells || river.cells.length < 2) return null;
    const points = river.cells.map((cellId) => {
      if (cellId < 0 || cellId >= pack.cells.p.length) return null;
      return pack.cells.p[cellId];
    }).filter((p) => p !== null);
    if (points.length < 2) return null;
    const meanderedPoints = addMeandering(points);
    const path = getRiverPath(meanderedPoints, river.widthFactor || 1, river.sourceWidth || 1);
    const riverColors = (renderConfig2 == null ? void 0 : renderConfig2.colors) || {};
    const riverFill = riverColors.riverFill || LEGACY_STYLE_CONSTANTS.riverFill;
    const riverStroke = riverColors.riverStroke || LEGACY_STYLE_CONSTANTS.riverStroke;
    const riverStrokeWidth = ((_b = (_a = renderConfig2 == null ? void 0 : renderConfig2.layers) == null ? void 0 : _a.rivers) == null ? void 0 : _b.strokeWidth) ?? 0.5;
    return `<path id="river${river.i}" d="${path}" fill="${riverFill}" stroke="${riverStroke}" stroke-width="${riverStrokeWidth}" />`;
  }).filter((p) => p !== null);
  return riverPaths.join("");
}
function addMeandering(points) {
  if (points.length < 2) return points;
  const meandered = [];
  const meanderingAmount = 0.3;
  for (let i = 0; i < points.length; i++) {
    const [x2, y2] = points[i];
    meandered.push([x2, y2]);
    if (i < points.length - 1) {
      const [x1, y1] = points[i];
      const [x22, y22] = points[i + 1];
      const dx = x22 - x1;
      const dy = y22 - y1;
      const midX = (x1 + x22) / 2;
      const midY = (y1 + y22) / 2;
      const perpX = -dy * meanderingAmount;
      const perpY = dx * meanderingAmount;
      meandered.push([midX + perpX, midY + perpY]);
    }
  }
  return meandered;
}
function getRiverPath(points, widthFactor, startingWidth) {
  if (points.length < 2) return "";
  const lineGen = line().x((d) => d[0]).y((d) => d[1]).curve(curveCatmullRom.alpha(0.1));
  const cleanPoints = points.map((p) => {
    if (Array.isArray(p) && p.length >= 2) {
      return [p[0], p[1]];
    }
    return p;
  }).filter((p) => p && p.length >= 2);
  if (cleanPoints.length < 2) return "";
  const path = lineGen(cleanPoints);
  return path || "";
}
function drawRoutesSVG(pack) {
  if (!pack || !Array.isArray(pack.routes) || !pack.cells || !pack.cells.p) return "";
  const routes = pack.routes;
  if (!routes.length) return "";
  const lineGen = line().x((d) => d[0]).y((d) => d[1]).curve(curveCatmullRom.alpha(0.1));
  const paths = [];
  for (const route of routes) {
    if (!route) continue;
    let points = null;
    if (Array.isArray(route.points) && route.points.length) {
      points = route.points.filter((p) => Array.isArray(p) && p.length >= 2);
    } else if (Array.isArray(route.cells) && route.cells.length) {
      points = route.cells.map((cellId) => cellId >= 0 && cellId < pack.cells.p.length ? pack.cells.p[cellId] : null).filter((p) => Array.isArray(p) && p.length >= 2);
    }
    if (!points || points.length < 2) continue;
    const d = lineGen(points);
    if (!d) continue;
    paths.push(
      `<path d="${d}" fill="none" stroke="#ff8c00" stroke-width="0.6" stroke-dasharray="3,2" opacity="0.8" />`
    );
  }
  return paths.join("");
}
function drawMarkersSVG(pack) {
  if (!pack || !Array.isArray(pack.markers) || !pack.cells || !pack.cells.p) return "";
  const markers = pack.markers;
  if (!markers.length) return "";
  const elements = [];
  for (const marker of markers) {
    if (!marker) continue;
    const cellId = marker.cell;
    if (cellId == null || cellId < 0 || cellId >= pack.cells.p.length) continue;
    const [x2, y2] = pack.cells.p[cellId] || [];
    if (x2 == null || y2 == null) continue;
    const type = marker.type || "marker";
    if (type === "volcanoes" || type === "eruption") {
      const size = 5;
      const points = [
        [x2, y2 - size],
        [x2 - size, y2 + size],
        [x2 + size, y2 + size]
      ].map((p) => `${rn(p[0], 2)},${rn(p[1], 2)}`).join(" ");
      elements.push(
        `<polygon points="${points}" fill="#ff5555" stroke="#660000" stroke-width="0.6" opacity="0.9" />`
      );
    } else if (type === "disaster" || type === "Disaster") {
      const r = 4;
      elements.push(
        `<g stroke="#cc0000" stroke-width="0.6" opacity="0.9"><line x1="${rn(x2 - r, 2)}" y1="${rn(y2 - r, 2)}" x2="${rn(x2 + r, 2)}" y2="${rn(y2 + r, 2)}" /><line x1="${rn(x2 - r, 2)}" y1="${rn(y2 + r, 2)}" x2="${rn(x2 + r, 2)}" y2="${rn(y2 - r, 2)}" /></g>`
      );
    } else {
      elements.push(
        `<circle cx="${rn(x2, 2)}" cy="${rn(y2, 2)}" r="2.5" fill="#222" stroke="#ffffff" stroke-width="0.6" opacity="0.9" />`
      );
    }
  }
  return elements.join("");
}
function drawBurgsSVG(pack, renderConfig2 = null) {
  var _a;
  if (!pack.burgs || !Array.isArray(pack.burgs)) return "";
  const burgElements = [];
  for (const burg of pack.burgs) {
    if (!burg || burg.removed || !burg.x || !burg.y) continue;
    const isCapital = burg.capital;
    const burgLayers = ((_a = renderConfig2 == null ? void 0 : renderConfig2.layers) == null ? void 0 : _a.burgs) || {};
    const burgColors = (renderConfig2 == null ? void 0 : renderConfig2.colors) || {};
    const size = isCapital ? burgLayers.capitalSize ?? LEGACY_STYLE_CONSTANTS.burgCapitalSize : burgLayers.townSize ?? LEGACY_STYLE_CONSTANTS.burgTownSize;
    const color2 = isCapital ? burgColors.burgCapitalColor || LEGACY_STYLE_CONSTANTS.burgCapitalColor : burgColors.burgTownColor || LEGACY_STYLE_CONSTANTS.burgTownColor;
    const population = burg.population || 0;
    const showLabel = isCapital || population > 500;
    burgElements.push(
      `<circle id="burg${burg.i}" cx="${rn(burg.x, 2)}" cy="${rn(burg.y, 2)}" r="${size}" fill="${color2}" stroke="#fff" stroke-width="0.5" />`
    );
    if (burg.name && showLabel) {
      const labelOffset = isCapital ? size * 2.5 : size * 2;
      const fontSize = isCapital ? 10 : 8;
      const labelY = burg.y - labelOffset;
      if (isCapital) {
        const arcRadius = labelOffset * 0.8;
        const startAngle = -Math.PI / 6;
        const endAngle = Math.PI / 6;
        const pathId = `burgLabelPath${burg.i}`;
        const startX = burg.x + arcRadius * Math.cos(startAngle);
        const startY = burg.y - labelOffset + arcRadius * Math.sin(startAngle);
        const endX = burg.x + arcRadius * Math.cos(endAngle);
        const endY = burg.y - labelOffset + arcRadius * Math.sin(endAngle);
        const midX = burg.x;
        const midY = burg.y - labelOffset - arcRadius * 0.3;
        const pathD = `M ${rn(startX, 2)},${rn(startY, 2)} Q ${rn(midX, 2)},${rn(midY, 2)} ${rn(endX, 2)},${rn(endY, 2)}`;
        burgElements.push(
          `<defs><path id="${pathId}" d="${pathD}" /></defs>`,
          `<text id="burgLabel${burg.i}"><textPath href="#${pathId}" startOffset="50%" text-anchor="middle" font-size="${fontSize}" font-weight="bold" fill="${color2}" stroke="#fff" stroke-width="0.3">${burg.name}</textPath></text>`
        );
      } else {
        burgElements.push(
          `<text id="burgLabel${burg.i}" x="${rn(burg.x, 2)}" y="${rn(labelY, 2)}" font-size="${fontSize}" text-anchor="middle" fill="${color2}" stroke="#fff" stroke-width="0.3">${burg.name}</text>`
        );
      }
    }
  }
  return burgElements.join("");
}
function drawFeaturesSVG(pack, width2 = 1e3, height2 = 600, renderConfig2 = null) {
  if (!pack.features || !Array.isArray(pack.features)) return "";
  const featurePaths = [];
  for (const feature of pack.features) {
    if (!feature || feature.type === "ocean") continue;
    if (feature.vertices && feature.vertices.length > 0 && pack.vertices) {
      const rawPoints = feature.vertices.map((vId) => pack.vertices.p[vId]).filter((p) => p !== void 0);
      if (rawPoints.length >= 3) {
        const points = clipPoly(rawPoints, width2, height2, 1);
        if (points.length < 3) continue;
        const path = `M${points[0][0]},${points[0][1]} L${points.slice(1).map((p) => `${p[0]},${p[1]}`).join(" ")} Z`;
        const featureColors = (renderConfig2 == null ? void 0 : renderConfig2.colors) || {};
        const fillColor = feature.type === "lake" ? feature.group === "saltwater" ? featureColors.lakeSaltwater || LEGACY_STYLE_CONSTANTS.lakeSaltwater : featureColors.lakeFreshwater || LEGACY_STYLE_CONSTANTS.lakeFreshwater : featureColors.landBase || LEGACY_STYLE_CONSTANTS.landBase;
        featurePaths.push(
          `<path id="feature_${feature.i}" d="${path}" fill="${fillColor}" stroke="${fillColor}" stroke-width="0.5" />`
        );
      }
    }
  }
  return featurePaths.join("");
}
function drawStateLabelsSVG(pack) {
  if (!pack.states || !pack.burgs || !pack.cells) return "";
  const labels = [];
  const states = pack.states;
  const burgs = pack.burgs;
  const cells = pack.cells;
  const lineGen = line().x((d) => d[0]).y((d) => d[1]).curve(curveNatural);
  for (const state2 of states) {
    if (!state2.i || state2.removed || state2.i === 0) continue;
    if (!state2.name) continue;
    const capitalBurg = state2.capital && burgs[state2.capital];
    if (!capitalBurg || !capitalBurg.x || !capitalBurg.y) continue;
    const [poleX, poleY] = [capitalBurg.x, capitalBurg.y];
    const stateName = state2.name || state2.fullName || `State${state2.i}`;
    const color2 = "#000000";
    const stateCells = [];
    for (let i = 0; i < cells.i.length; i++) {
      if (cells.state[i] === state2.i && cells.h[i] >= 20) {
        if (cells.p && cells.p[i]) {
          stateCells.push(cells.p[i]);
        }
      }
    }
    if (stateCells.length === 0) continue;
    const arcWidth = Math.max(stateName.length * 6, 60);
    const arcHeight = 20;
    const pathPoints = [];
    pathPoints.push([poleX - arcWidth / 2, poleY - 5]);
    const midPoint1 = [poleX - arcWidth / 4, poleY - 10 - arcHeight / 2];
    const midPoint2 = [poleX, poleY - 10 - arcHeight];
    const midPoint3 = [poleX + arcWidth / 4, poleY - 10 - arcHeight / 2];
    pathPoints.push(midPoint1);
    pathPoints.push(midPoint2);
    pathPoints.push(midPoint3);
    pathPoints.push([poleX + arcWidth / 2, poleY - 5]);
    const pathId = `stateLabelPath${state2.i}`;
    const pathD = lineGen(pathPoints);
    if (!pathD) continue;
    const fullName = state2.fullName || stateName;
    const pathLength = pathPoints.length > 0 ? Math.sqrt(Math.pow(pathPoints[pathPoints.length - 1][0] - pathPoints[0][0], 2) + Math.pow(pathPoints[pathPoints.length - 1][1] - pathPoints[0][1], 2)) : stateName.length * 6;
    const [lines, ratio] = getLabelLinesAndRatio(stateName, fullName, pathLength / 6);
    let adjustedPath = pathPoints;
    let collisionOffset = 0;
    if (pack.burgs) {
      const hasCollision = checkLabelCollision(poleX, poleY, arcWidth, arcHeight, pack.burgs, pack.cells);
      if (hasCollision) {
        collisionOffset = -15;
        adjustedPath = pathPoints.map(([x2, y2]) => [x2, y2 + collisionOffset]);
      }
    }
    const adjustedPathD = lineGen(adjustedPath);
    if (!adjustedPathD) continue;
    const top = (lines.length - 1) / -2;
    const tspanElements = lines.map(
      (line2, index) => `<tspan x="0" dy="${index ? 1 : top}em">${line2}</tspan>`
    ).join("");
    labels.push(
      `<defs><path id="${pathId}" d="${adjustedPathD}" /></defs>`,
      `<text id="stateLabel${state2.i}" fill="${color2}" stroke="#ffffff" stroke-width="0.3" font-size="${rn(ratio, 0)}%" font-weight="bold" text-rendering="optimizeSpeed">`,
      `<textPath href="#${pathId}" startOffset="50%" text-anchor="middle">${tspanElements}</textPath>`,
      `</text>`
    );
  }
  return labels.join("");
}
function getLabelLinesAndRatio(name, fullName, pathLength) {
  if (pathLength > fullName.length * 2) {
    const ratio = Math.max(70, Math.min(170, pathLength / fullName.length * 70));
    return [[fullName], ratio];
  } else {
    const lines = splitInTwo(fullName);
    const longestLineLength = Math.max(...lines.map((l) => l.length));
    const ratio = Math.max(70, Math.min(150, pathLength / longestLineLength * 60));
    return [lines, ratio];
  }
}
function splitInTwo(str) {
  const half = str.length / 2;
  const ar = str.split(" ");
  if (ar.length < 2) return ar;
  let first = "";
  let last = "";
  let middle = "";
  let rest = "";
  ar.forEach((w, d) => {
    if (d + 1 !== ar.length) w += " ";
    rest += w;
    if (!first || rest.length < half) first += w;
    else if (!middle) middle = w;
    else last += w;
  });
  if (!last) return [first, middle];
  if (first.length < last.length) return [first + middle, last];
  return [first, middle + last];
}
function checkLabelCollision(x2, y2, width2, height2, burgs, cells) {
  if (!burgs || !cells) return false;
  const labelBox = {
    x: x2 - width2 / 2,
    y: y2 - height2 / 2,
    width: width2,
    height: height2
  };
  for (const burg of burgs) {
    if (!burg || !burg.x || !burg.y || burg.removed) continue;
    const burgBox = {
      x: burg.x - 5,
      // Approximate burg size
      y: burg.y - 5,
      width: 10,
      height: 10
    };
    if (boxesOverlap(labelBox, burgBox)) {
      return true;
    }
  }
  return false;
}
function boxesOverlap(box1, box2) {
  return !(box1.x + box1.width < box2.x || box2.x + box2.width < box1.x || box1.y + box1.height < box2.y || box2.y + box2.height < box1.y);
}
function renderMapSVG(data, options = {}) {
  var _a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s, _t, _u, _v, _w, _x, _y, _z, _A, _B, _C, _D, _E, _F, _G, _H, _I, _J, _K, _L, _M, _N, _O, _P, _Q, _R, _S, _T, _U, _V, _W, _X, _Y, _Z, __, _$, _aa, _ba, _ca, _da, _ea, _fa, _ga, _ha, _ia, _ja, _ka, _la, _ma;
  if (!data || !data.pack) {
    throw new Error("Map data with pack is required");
  }
  const { pack, options: genOptions } = data;
  const { mapWidth, mapHeight } = genOptions || options;
  const width2 = options.width || mapWidth || 1e3;
  const height2 = options.height || mapHeight || 600;
  let renderConfig2;
  if (typeof console !== "undefined" && console.log) {
    console.log("[renderMapSVG] Config check:", {
      hasRenderConfig: !!options.renderConfig,
      hasColors: !!(options.renderConfig && options.renderConfig.colors),
      hasLayers: !!(options.renderConfig && options.renderConfig.layers),
      hasEffects: !!(options.renderConfig && options.renderConfig.effects),
      oceanColor: (_b = (_a = options.renderConfig) == null ? void 0 : _a.colors) == null ? void 0 : _b.oceanBase
    });
  }
  renderConfig2 = mergeRenderConfig(options.renderConfig || {});
  if (typeof console !== "undefined" && console.log) {
    console.log("[renderMapSVG] Effective config check:");
    console.log("  - Ocean color:", (_c = renderConfig2.colors) == null ? void 0 : _c.oceanBase);
    console.log("  - Parchment texture:", ((_e = (_d = renderConfig2.effects) == null ? void 0 : _d.parchment) == null ? void 0 : _e.enabled) ? "ENABLED" : "DISABLED");
    console.log("  - Pseudo-3D shadows:", ((_g = (_f = renderConfig2.effects) == null ? void 0 : _f.pseudo3D) == null ? void 0 : _g.enabled) ? "ENABLED" : "DISABLED");
    console.log("  - Relief density:", (_i = (_h = renderConfig2.layers) == null ? void 0 : _h.relief) == null ? void 0 : _i.density);
    console.log("  - Coast outline:", ((_k = (_j = renderConfig2.layers) == null ? void 0 : _j.coast) == null ? void 0 : _k.enabled) ? "ENABLED" : "DISABLED");
  }
  if (typeof console !== "undefined" && console.log) {
    console.log("[renderMapSVG] Render config applied:", {
      colorScheme: renderConfig2.colorScheme,
      oceanColor: (_l = renderConfig2.colors) == null ? void 0 : _l.oceanBase,
      parchmentEnabled: (_n = (_m = renderConfig2.effects) == null ? void 0 : _m.parchment) == null ? void 0 : _n.enabled,
      parchmentUrl: (_p = (_o = renderConfig2.effects) == null ? void 0 : _o.parchment) == null ? void 0 : _p.textureUrl,
      pseudo3DEnabled: (_r = (_q = renderConfig2.effects) == null ? void 0 : _q.pseudo3D) == null ? void 0 : _r.enabled,
      reliefDensity: (_t = (_s = renderConfig2.layers) == null ? void 0 : _s.relief) == null ? void 0 : _t.density,
      coastEnabled: (_v = (_u = renderConfig2.layers) == null ? void 0 : _u.coast) == null ? void 0 : _v.enabled,
      biomeOpacity: (_x = (_w = renderConfig2.layers) == null ? void 0 : _w.biomes) == null ? void 0 : _x.opacity
    });
  }
  const colorSchemeName = options.colorScheme || renderConfig2.colorScheme || "parchment";
  const colorScheme = getColorScheme(colorSchemeName);
  const biomesData = getDefaultBiomes();
  const layers = [];
  const parchmentEffect = (_y = renderConfig2.effects) == null ? void 0 : _y.parchment;
  if ((parchmentEffect == null ? void 0 : parchmentEffect.enabled) && (parchmentEffect == null ? void 0 : parchmentEffect.textureUrl)) {
    const blendMode = parchmentEffect.blendMode || "multiply";
    const textureUrl = parchmentEffect.textureUrl;
    const textureOpacity = parchmentEffect.opacity ?? 0.65;
    layers.push(
      `<image id="texture-overlay" xlink:href="${textureUrl}" x="0" y="0" width="${width2}" height="${height2}" preserveAspectRatio="xMidYMid slice" opacity="${textureOpacity}" style="mix-blend-mode: ${blendMode};" />`
    );
    if (typeof console !== "undefined" && console.log) {
      console.log("[renderMapSVG] Parchment texture overlay added:", { textureUrl, opacity: textureOpacity, blendMode });
    }
  } else {
    if (typeof console !== "undefined" && console.warn) {
      console.warn("[renderMapSVG] Parchment texture NOT added:", {
        enabled: parchmentEffect == null ? void 0 : parchmentEffect.enabled,
        textureUrl: parchmentEffect == null ? void 0 : parchmentEffect.textureUrl
      });
    }
  }
  const oceanColor = renderConfig2.colors.oceanBase;
  if (typeof console !== "undefined" && console.log) {
    console.log("[renderMapSVG] Using ocean color:", oceanColor);
  }
  layers.push(`<rect x="0" y="0" width="${width2}" height="${height2}" fill="${oceanColor}" />`);
  if (options.showOceanLayers !== false) {
    try {
      const oceanLayersSVG = drawOceanLayersSVG(pack, {
        oceanLayers: options.oceanLayers || "random",
        width: width2,
        height: height2,
        colorScheme
      });
      if (oceanLayersSVG) {
        layers.push(`<g id="ocean-layers">${oceanLayersSVG}</g>`);
      }
    } catch (error) {
      console.warn("Ocean layers rendering failed:", error.message);
    }
  }
  const featuresSVG = drawFeaturesSVG(pack, width2, height2, renderConfig2);
  if (featuresSVG) {
    layers.push(`<g id="features">${featuresSVG}</g>`);
  }
  let biomesSVG = "";
  try {
    biomesSVG = drawBiomesSVG(pack, biomesData, colorScheme, renderConfig2);
  } catch (error) {
    console.warn("Biome rendering failed (possibly from cached build), using empty layer:", error.message);
    console.warn("Error stack:", error.stack);
    biomesSVG = "";
  }
  const biomeOpacity = ((_A = (_z = renderConfig2.layers) == null ? void 0 : _z.biomes) == null ? void 0 : _A.opacity) ?? 0.7;
  layers.push(`<g id="biomes" class="biomes-layer" opacity="${biomeOpacity}">${biomesSVG}</g>`);
  const statesSVG = drawStatesSVG(pack, renderConfig2);
  if (statesSVG) {
    const stateOpacity = ((_C = (_B = renderConfig2.layers) == null ? void 0 : _B.states) == null ? void 0 : _C.opacity) ?? 0.4;
    layers.push(`<g id="states" class="states-layer" opacity="${stateOpacity}">${statesSVG}</g>`);
  }
  const riversEnabled = ((_E = (_D = renderConfig2.layers) == null ? void 0 : _D.rivers) == null ? void 0 : _E.enabled) !== false;
  if (typeof console !== "undefined" && console.log) {
    console.log("[renderMapSVG] Rivers config:", {
      enabled: riversEnabled,
      opacity: (_G = (_F = renderConfig2.layers) == null ? void 0 : _F.rivers) == null ? void 0 : _G.opacity,
      strokeWidth: (_I = (_H = renderConfig2.layers) == null ? void 0 : _H.rivers) == null ? void 0 : _I.strokeWidth,
      strokeColor: (_J = renderConfig2.colors) == null ? void 0 : _J.riverStroke
    });
  }
  if (riversEnabled) {
    const riversSVG = drawRiversSVG(pack, renderConfig2);
    if (riversSVG) {
      layers.push(`<g id="rivers">${riversSVG}</g>`);
      if (typeof console !== "undefined" && console.log) {
        console.log("[renderMapSVG] Rivers SVG added (length: " + riversSVG.length + ")");
      }
    } else {
      if (typeof console !== "undefined" && console.warn) {
        console.warn("[renderMapSVG] Rivers enabled but no SVG generated");
      }
    }
  } else {
    if (typeof console !== "undefined" && console.log) {
      console.log("[renderMapSVG] Rivers disabled by config");
    }
  }
  const coastEnabled = ((_L = (_K = renderConfig2.layers) == null ? void 0 : _K.coast) == null ? void 0 : _L.enabled) !== false;
  if (typeof console !== "undefined" && console.log) {
    console.log("[renderMapSVG] Coast outline config:", {
      enabled: coastEnabled,
      stroke: (_N = (_M = renderConfig2.layers) == null ? void 0 : _M.coast) == null ? void 0 : _N.stroke,
      width: (_P = (_O = renderConfig2.layers) == null ? void 0 : _O.coast) == null ? void 0 : _P.width,
      opacity: (_R = (_Q = renderConfig2.layers) == null ? void 0 : _Q.coast) == null ? void 0 : _R.opacity
    });
  }
  if (coastEnabled) {
    const coastOutlineSVG = drawCoastOutlineSVG(pack, renderConfig2);
    if (coastOutlineSVG) {
      layers.push(`<g id="coast-outline" class="coast-layer">${coastOutlineSVG}</g>`);
      if (typeof console !== "undefined" && console.log) {
        console.log("[renderMapSVG] Coast outline SVG added (length: " + coastOutlineSVG.length + ")");
      }
    } else {
      if (typeof console !== "undefined" && console.warn) {
        console.warn("[renderMapSVG] Coast outline enabled but no SVG generated");
      }
    }
  } else {
    if (typeof console !== "undefined" && console.log) {
      console.log("[renderMapSVG] Coast outline disabled by config");
    }
  }
  const borders = drawBordersSVG(pack, renderConfig2);
  if (borders.stateBorders || borders.provinceBorders) {
    layers.push(`<g id="borders">${borders.stateBorders}${borders.provinceBorders}</g>`);
  }
  const routesSVG = drawRoutesSVG(data.pack || pack);
  if (routesSVG) {
    layers.push(`<g id="routes">${routesSVG}</g>`);
  }
  let reliefSVG = "";
  const reliefEnabled = ((_T = (_S = renderConfig2.layers) == null ? void 0 : _S.relief) == null ? void 0 : _T.enabled) !== false;
  if (typeof console !== "undefined" && console.log) {
    console.log("[renderMapSVG] Relief config:", {
      enabled: reliefEnabled,
      density: (_V = (_U = renderConfig2.layers) == null ? void 0 : _U.relief) == null ? void 0 : _V.density,
      size: (_X = (_W = renderConfig2.layers) == null ? void 0 : _W.relief) == null ? void 0 : _X.size,
      heightScaling: (_Z = (_Y = renderConfig2.layers) == null ? void 0 : _Y.relief) == null ? void 0 : _Z.heightScaling,
      pseudo3D: (_$ = (__ = renderConfig2.effects) == null ? void 0 : __.pseudo3D) == null ? void 0 : _$.enabled,
      shadowOffsetX: (_ba = (_aa = renderConfig2.effects) == null ? void 0 : _aa.pseudo3D) == null ? void 0 : _ba.shadowOffsetX,
      shadowOffsetY: (_da = (_ca = renderConfig2.effects) == null ? void 0 : _ca.pseudo3D) == null ? void 0 : _da.shadowOffsetY,
      shadowBlur: (_fa = (_ea = renderConfig2.effects) == null ? void 0 : _ea.pseudo3D) == null ? void 0 : _fa.shadowBlur
    });
  }
  if (reliefEnabled) {
    try {
      const baseDensity = 0.3;
      const densityMultiplier = ((_ha = (_ga = renderConfig2.layers) == null ? void 0 : _ga.relief) == null ? void 0 : _ha.density) ?? 1;
      const finalDensity = baseDensity * densityMultiplier;
      const reliefOptions = {
        density: baseDensity,
        // Base density (multiplied by config.layers.relief.density in function)
        size: ((_ja = (_ia = renderConfig2.layers) == null ? void 0 : _ia.relief) == null ? void 0 : _ja.size) ?? 1,
        renderConfig: renderConfig2
        // Pass config for pseudo3D effects and density multiplier
      };
      if (typeof console !== "undefined" && console.log) {
        console.log("[renderMapSVG] Relief rendering options:", { baseDensity, densityMultiplier, finalDensity, pseudo3D: (_la = (_ka = renderConfig2.effects) == null ? void 0 : _ka.pseudo3D) == null ? void 0 : _la.enabled });
      }
      reliefSVG = drawReliefIconsSVG(pack, biomesData, data.grid || null, reliefOptions);
      if (typeof console !== "undefined" && console.log && reliefSVG) {
        console.log("[renderMapSVG] Relief SVG generated (length: " + reliefSVG.length + ")");
      }
    } catch (error) {
      console.warn("Relief rendering failed:", error.message);
    }
    if (reliefSVG) {
      layers.push(`<g id="relief" class="relief-layer">${reliefSVG}</g>`);
      if (typeof console !== "undefined" && console.log) {
        console.log("[renderMapSVG] Relief layer added to SVG");
      }
    } else {
      if (typeof console !== "undefined" && console.warn) {
        console.warn("[renderMapSVG] Relief enabled but no SVG generated");
      }
    }
  } else {
    if (typeof console !== "undefined" && console.log) {
      console.log("[renderMapSVG] Relief disabled by config");
    }
  }
  const burgsSVG = drawBurgsSVG(pack, renderConfig2);
  if (burgsSVG) {
    layers.push(`<g id="burgs">${burgsSVG}</g>`);
  }
  const stateLabelsSVG = drawStateLabelsSVG(pack);
  if (stateLabelsSVG) {
    layers.push(`<g id="labels" class="state-labels">${stateLabelsSVG}</g>`);
  }
  const markersSVG = drawMarkersSVG(data.pack || pack);
  if (markersSVG) {
    layers.push(`<g id="markers">${markersSVG}</g>`);
  }
  const baseDefsStr = getSVGDefs();
  const baseDefsContent = baseDefsStr.replace(/^<defs>|<\/defs>$/g, "").trim();
  const reliefDefsStr = getReliefIconDefs();
  const reliefDefsContent = reliefDefsStr.replace(/^<defs>|<\/defs>$/g, "").trim();
  let defs = `<defs>
${baseDefsContent}
${reliefDefsContent}`;
  const pseudo3D = ((_ma = renderConfig2.effects) == null ? void 0 : _ma.pseudo3D) || {};
  if (pseudo3D.enabled !== false) {
    const shadowBlur = pseudo3D.shadowBlur ?? 4;
    const shadowOpacity = pseudo3D.shadowOpacity ?? 0.5;
    const shadowOffsetX = pseudo3D.shadowOffsetX ?? 2;
    const shadowOffsetY = pseudo3D.shadowOffsetY ?? 3;
    defs += `
    <filter id="dropShadowEnhanced" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur in="SourceAlpha" stdDeviation="${shadowBlur}" result="blur"/>
      <feOffset dx="${shadowOffsetX}" dy="${shadowOffsetY}" in="blur" result="offsetblur"/>
      <feComponentTransfer in="offsetblur" result="shadow">
        <feFuncA type="linear" slope="${shadowOpacity}" intercept="0"/>
      </feComponentTransfer>
      <feMerge>
        <feMergeNode in="shadow"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>`;
  }
  defs += "\n</defs>";
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="${width2}" height="${height2}" viewBox="0 0 ${width2} ${height2}">
${defs}
${layers.join("\n")}
</svg>`;
  return svg;
}
let state = {
  // canvas: null, // DEPRECATED: Canvas rendering is deprecated, use container for SVG instead
  container: null,
  // SVG container element (optional)
  options: getDefaultOptions(),
  data: null,
  // { grid, pack, seed }
  initialized: false
};
function generateMapInternal(options, DelaunatorClass) {
  var _a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s, _t;
  const seed = options.seed || String(Date.now());
  const rng = new RNG(seed);
  if (!DelaunatorClass) {
    throw new GenerationError(
      "Delaunator is required as a peer dependency. Install: npm install delaunator, then pass Delaunator as the second parameter to generateMap()"
    );
  }
  const grid = createVoronoiDiagram(
    {
      mapWidth: options.mapWidth,
      mapHeight: options.mapHeight,
      cellsDesired: options.cellsDesired
    },
    rng,
    DelaunatorClass
  );
  const heights = generateHeightmap({ grid, options, rng, template: options.template });
  grid.cells.h = heights;
  markupGrid({ grid });
  const mapCoordinates = calculateMapCoordinates(options, options.mapWidth, options.mapHeight);
  const temperatures = calculateTemperatures({ grid, options, mapCoordinates });
  grid.cells.temp = temperatures;
  const precipitation = generatePrecipitation({ grid, options, rng, mapCoordinates });
  grid.cells.prec = precipitation;
  const useFullPack = true;
  if (typeof console !== "undefined" && console.log) {
    console.log("[generator] Pack creation decision:", {
      useFullPack,
      fullRendering: options.fullRendering,
      hasContainer: state.container !== null,
      forcedFullPack: true
    });
  }
  let pack;
  {
    pack = createPackFromGrid({ grid, options, DelaunatorClass });
    const targetLandPercentage = options.landPercentage || 40;
    const landThreshold = 20;
    let packLandCells = 0;
    for (let i = 0; i < pack.cells.i.length; i++) {
      if (pack.cells.h[i] >= landThreshold) packLandCells++;
    }
    const packLandPercentage = packLandCells / pack.cells.i.length * 100;
    if (packLandPercentage > targetLandPercentage) {
      const excessRatio = packLandPercentage / targetLandPercentage;
      const reductionMultiplier = Math.max(0.5, Math.min(0.7, targetLandPercentage / packLandPercentage));
      for (let i = 0; i < pack.cells.i.length; i++) {
        if (pack.cells.h[i] >= landThreshold) {
          const newH = (pack.cells.h[i] - landThreshold) * reductionMultiplier + landThreshold;
          pack.cells.h[i] = Math.max(landThreshold - 1, Math.min(100, Math.round(newH)));
        }
      }
      packLandCells = 0;
      for (let i = 0; i < pack.cells.i.length; i++) {
        if (pack.cells.h[i] >= landThreshold) packLandCells++;
      }
      let adjustedPackLandPercentage = packLandCells / pack.cells.i.length * 100;
      if (adjustedPackLandPercentage > targetLandPercentage) {
        const landIndices = [];
        for (let i = 0; i < pack.cells.i.length; i++) {
          if (pack.cells.h[i] >= landThreshold) {
            landIndices.push(i);
          }
        }
        landIndices.sort((a, b) => pack.cells.h[a] - pack.cells.h[b]);
        const targetLandCells = Math.floor(pack.cells.i.length * (targetLandPercentage / 100));
        const cellsToReduce = Math.max(0, landIndices.length - targetLandCells);
        for (let j = 0; j < cellsToReduce && j < landIndices.length; j++) {
          pack.cells.h[landIndices[j]] = landThreshold - 1;
        }
        packLandCells = 0;
        for (let i = 0; i < pack.cells.i.length; i++) {
          if (pack.cells.h[i] >= landThreshold) packLandCells++;
        }
        adjustedPackLandPercentage = packLandCells / pack.cells.i.length * 100;
      }
      if (typeof console !== "undefined" && console.log) {
        console.log("[generator:post-pack-land-adjust] Post-pack land percentage adjustment:", {
          target: targetLandPercentage,
          initial: packLandPercentage.toFixed(1),
          adjusted: adjustedPackLandPercentage.toFixed(1),
          reductionMultiplier: reductionMultiplier.toFixed(3),
          excessRatio: excessRatio.toFixed(2)
        });
      }
    }
    if (typeof console !== "undefined" && console.log) {
      console.log("[generator:lifecycle] Post-creation (immediately after createPackFromGrid):", {
        cellsCount: pack.cells.i.length,
        hasVCoords: Array.isArray(pack.cells.vCoords),
        vCoordsLength: ((_a = pack.cells.vCoords) == null ? void 0 : _a.length) || 0,
        hasV: Array.isArray(pack.cells.v),
        vLength: ((_b = pack.cells.v) == null ? void 0 : _b.length) || 0,
        vCoordsSample: ((_d = (_c = pack.cells.vCoords) == null ? void 0 : _c[0]) == null ? void 0 : _d.length) || 0,
        vSample: ((_f = (_e = pack.cells.v) == null ? void 0 : _e[0]) == null ? void 0 : _f.length) || 0,
        verticesPLength: ((_h = (_g = pack.vertices) == null ? void 0 : _g.p) == null ? void 0 : _h.length) || 0,
        v0Exists: ((_i = pack.cells.v) == null ? void 0 : _i[0]) !== void 0,
        vCoords0Exists: ((_j = pack.cells.vCoords) == null ? void 0 : _j[0]) !== void 0,
        v0Sample: ((_k = pack.cells.v) == null ? void 0 : _k[0]) ? JSON.stringify(pack.cells.v[0].slice(0, 3)) : "undefined",
        vCoords0Sample: ((_l = pack.cells.vCoords) == null ? void 0 : _l[0]) ? JSON.stringify(pack.cells.vCoords[0].slice(0, 2)) : "undefined",
        packCellsKeys: pack.cells ? Object.keys(pack.cells) : []
      });
    }
  }
  generateRivers({
    grid,
    pack,
    options,
    rng,
    precipitation: grid.cells.prec,
    allowErosion: options.allowErosion !== false
  });
  const biomesData = getDefaultBiomes();
  assignBiomes({ pack, grid, options, biomesData });
  markupPack({ pack });
  const templateId = options.template || "continent";
  const isCohesionStyle = templateId === "continent" || templateId === "pangea";
  const isFragmentedStyle = templateId === "archipelago" || templateId === "shattered";
  const initialClusters = pack.features ? pack.features.filter((f) => f && f.land).length : 0;
  if (isCohesionStyle && initialClusters > 5) {
    const mergesPerformed = mergeNearbyClusters(pack, {
      mergeDistance: 6,
      // Aggressive: merge features up to 6 cells apart
      maxMergeDistance: 10,
      // Maximum distance to consider
      minClusterSize: 5,
      // Include smaller isles
      maxIterations: 10,
      // Allow up to 10 iterations for convergence
      maxClusterSize: pack.cells.i.length * 0.6
      // Prevent supercontinents (60% of cells)
    });
    if (mergesPerformed > 0) {
      markupPack({ pack });
      specifyFeatures({ pack, grid, options });
      const finalClusters = pack.features ? pack.features.filter((f) => f && f.land).length : 0;
      if (typeof console !== "undefined" && console.log) {
        console.log("[cluster-merge] Template-aware merge:", {
          template: templateId,
          style: isCohesionStyle ? "cohesion" : "fragmented",
          initialClusters,
          mergesPerformed,
          finalClusters,
          reduction: initialClusters - finalClusters
        });
      }
    } else {
      specifyFeatures({ pack, grid, options });
    }
  } else if (isFragmentedStyle && initialClusters > 20) {
    const mergesPerformed = mergeNearbyClusters(pack, {
      mergeDistance: 1,
      // Very conservative: only merge features 1 cell apart
      maxMergeDistance: 2,
      // Maximum distance to consider
      minClusterSize: 20,
      // Only merge larger clusters (preserve small islands)
      maxIterations: 1,
      // Single pass only (no iteration)
      maxClusterSize: pack.cells.i.length * 0.3
      // Prevent large landmasses (30% max)
    });
    if (mergesPerformed > 0) {
      markupPack({ pack });
      specifyFeatures({ pack, grid, options });
      const finalClusters = pack.features ? pack.features.filter((f) => f && f.land).length : 0;
      if (typeof console !== "undefined" && console.log) {
        console.log("[cluster-merge] Minimal merge (fragmented style):", {
          template: templateId,
          initialClusters,
          mergesPerformed,
          finalClusters,
          reduction: initialClusters - finalClusters
        });
      }
    } else {
      specifyFeatures({ pack, grid, options });
    }
  } else {
    specifyFeatures({ pack, grid, options });
  }
  rankCells({ pack, grid, options, biomesData });
  generateCultures({ pack, grid, options, rng, biomesData });
  expandCultures({ pack, options, biomesData });
  generateBurgs({ pack, grid, options, rng });
  generateStates({ pack, options, rng });
  generateProvinces({ pack, options, rng });
  if (options.religionsNumber > 0) {
    generateReligions({ pack, options, rng });
  } else {
    pack.religions = [{ name: "No religion", i: 0 }];
    if (!pack.cells.religion) {
      pack.cells.religion = createTypedArray({ maxValue: 65535, length: pack.cells.i.length });
    }
  }
  generateEmblems({ pack, options, rng });
  if (typeof console !== "undefined" && console.log) {
    const landCells = pack.cells.i.filter((i) => pack.cells.h[i] >= 20);
    const landPercentage = (landCells.length / pack.cells.i.length * 100).toFixed(1);
    const features = pack.features || [];
    const landFeatures = features.filter((f) => f && f.land);
    const landClusters = landFeatures.length;
    const cellsDesired = grid.cellsDesired || 1e4;
    const blobPowerMap = {
      1e3: 0.93,
      2e3: 0.95,
      5e3: 0.97,
      1e4: 0.98,
      2e4: 0.99,
      3e4: 0.991,
      4e4: 0.993,
      5e4: 0.994,
      6e4: 0.995,
      7e4: 0.9955,
      8e4: 0.996,
      9e4: 0.9964,
      1e5: 0.9973
    };
    const linePowerMap = {
      1e3: 0.75,
      2e3: 0.77,
      5e3: 0.79,
      1e4: 0.81,
      2e4: 0.82,
      3e4: 0.83,
      4e4: 0.84,
      5e4: 0.86,
      6e4: 0.87,
      7e4: 0.88,
      8e4: 0.91,
      9e4: 0.92,
      1e5: 0.93
    };
    const blobPower = blobPowerMap[cellsDesired] || 0.98;
    const linePower = linePowerMap[cellsDesired] || 0.81;
    console.log("[diagnostics] Generation complete:", {
      packCells: pack.cells.i.length,
      landCells: landCells.length,
      landPercentage: `${landPercentage}%`,
      targetLandPercentage: options.landPercentage || 40,
      landClusters,
      features: features.length,
      verticesCount: ((_n = (_m = pack.vertices) == null ? void 0 : _m.p) == null ? void 0 : _n.length) || 0,
      verticesVSample: ((_q = (_p = (_o = pack.vertices) == null ? void 0 : _o.v) == null ? void 0 : _p[0]) == null ? void 0 : _q.length) || 0,
      verticesCSample: ((_t = (_s = (_r = pack.vertices) == null ? void 0 : _r.c) == null ? void 0 : _s[0]) == null ? void 0 : _t.length) || 0,
      heightMin: pack.cells.h ? Math.min(...Array.from(pack.cells.h).filter((h) => h !== void 0)) : "N/A",
      heightMax: pack.cells.h ? Math.max(...Array.from(pack.cells.h).filter((h) => h !== void 0)) : "N/A",
      heightMean: pack.cells.h ? (Array.from(pack.cells.h).reduce((a, b) => (a || 0) + (b || 0), 0) / pack.cells.h.length).toFixed(1) : "N/A",
      blobPower,
      linePower,
      cellsDesired
    });
  }
  return {
    grid,
    pack,
    options,
    seed
  };
}
function requireInitialized() {
  if (!state.initialized) {
    throw new InitializationError();
  }
}
function initGenerator({ canvas = null, container: container2 = null } = {}) {
  if (state.initialized) {
    throw new InitializationError(
      "Generator already initialized. Cannot initialize multiple times."
    );
  }
  if (canvas !== null) {
    if (typeof console !== "undefined" && console.warn) {
      console.warn(
        "⚠️ DEPRECATED: Canvas rendering is deprecated. Use container parameter for SVG rendering instead. Canvas parameter will be ignored."
      );
    }
  }
  if (container2 !== null && !(container2 instanceof HTMLElement)) {
    throw new InitializationError(
      `Invalid container element. Expected HTMLElement, got ${typeof container2}`
    );
  }
  state.container = container2;
  state.initialized = true;
}
function loadOptions(curatedParams = {}) {
  requireInitialized();
  try {
    const merged = mergeOptions(curatedParams);
    if (merged.mapWidth <= 0 || merged.mapHeight <= 0) {
      throw new InvalidOptionError(
        "mapWidth/mapHeight",
        `${merged.mapWidth}x${merged.mapHeight}`,
        "Map dimensions must be positive"
      );
    }
    state.options = merged;
  } catch (error) {
    if (error instanceof InvalidOptionError || error instanceof InitializationError) {
      throw error;
    }
    throw new InvalidOptionError(
      "options",
      curatedParams,
      `Failed to load options: ${error.message}`
    );
  }
}
function generateMap(DelaunatorClass = null) {
  var _a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s, _t, _u, _v;
  requireInitialized();
  try {
    const data = generateMapInternal(state.options, DelaunatorClass);
    if (typeof console !== "undefined" && console.log) {
      console.log("[generator:lifecycle] After generateMapInternal, before storing in state:", {
        dataHasPack: "pack" in data,
        packHasCells: data.pack && "cells" in data.pack,
        packCellsHasV: ((_a = data.pack) == null ? void 0 : _a.cells) && "v" in data.pack.cells,
        packCellsHasVCoords: ((_b = data.pack) == null ? void 0 : _b.cells) && "vCoords" in data.pack.cells,
        packCellsVLength: (_e = (_d = (_c = data.pack) == null ? void 0 : _c.cells) == null ? void 0 : _d.v) == null ? void 0 : _e.length,
        packCellsVCoordsLength: (_h = (_g = (_f = data.pack) == null ? void 0 : _f.cells) == null ? void 0 : _g.vCoords) == null ? void 0 : _h.length,
        packCellsKeys: ((_i = data.pack) == null ? void 0 : _i.cells) ? Object.keys(data.pack.cells) : []
      });
    }
    state.data = data;
    if (typeof console !== "undefined" && console.log) {
      console.log("[generator:lifecycle] After storing in state.data:", {
        stateDataHasPack: state.data && "pack" in state.data,
        packHasCells: ((_j = state.data) == null ? void 0 : _j.pack) && "cells" in state.data.pack,
        packCellsHasV: ((_l = (_k = state.data) == null ? void 0 : _k.pack) == null ? void 0 : _l.cells) && "v" in state.data.pack.cells,
        packCellsHasVCoords: ((_n = (_m = state.data) == null ? void 0 : _m.pack) == null ? void 0 : _n.cells) && "vCoords" in state.data.pack.cells,
        packCellsVLength: (_r = (_q = (_p = (_o = state.data) == null ? void 0 : _o.pack) == null ? void 0 : _p.cells) == null ? void 0 : _q.v) == null ? void 0 : _r.length,
        packCellsVCoordsLength: (_v = (_u = (_t = (_s = state.data) == null ? void 0 : _s.pack) == null ? void 0 : _t.cells) == null ? void 0 : _u.vCoords) == null ? void 0 : _v.length
      });
    }
    return data;
  } catch (error) {
    if (error instanceof GenerationError || error instanceof InitializationError) {
      throw error;
    }
    throw new GenerationError(`Map generation failed: ${error.message}`);
  }
}
function getMapData() {
  requireInitialized();
  if (!state.data) {
    throw new NoDataError();
  }
  const { grid, pack, seed, options } = state.data;
  const json = {
    seed: String(seed),
    options: deepCopy(options),
    grid: {
      cells: {
        i: Array.from(grid.cells.i),
        h: Array.from(grid.cells.h),
        t: grid.cells.t ? Array.from(grid.cells.t) : [],
        temp: grid.cells.temp ? Array.from(grid.cells.temp) : [],
        prec: grid.cells.prec ? Array.from(grid.cells.prec) : [],
        f: grid.cells.f ? Array.from(grid.cells.f) : [],
        b: grid.cells.b ? Array.from(grid.cells.b) : []
      },
      points: grid.points ? grid.points.map((p) => [...p]) : [],
      vertices: grid.vertices ? {
        p: grid.vertices.p ? grid.vertices.p.map((v) => [...v]) : [],
        v: grid.vertices.v ? deepCopy(grid.vertices.v) : [],
        c: grid.vertices.c ? deepCopy(grid.vertices.c) : []
      } : {},
      features: grid.features ? deepCopy(grid.features) : []
    },
    pack: {
      cells: {
        i: Array.from(pack.cells.i),
        h: Array.from(pack.cells.h),
        t: pack.cells.t ? Array.from(pack.cells.t) : [],
        f: pack.cells.f ? Array.from(pack.cells.f) : [],
        b: pack.cells.b ? Array.from(pack.cells.b) : [],
        g: pack.cells.g ? Array.from(pack.cells.g) : [],
        area: pack.cells.area ? Array.from(pack.cells.area) : [],
        // Additional fields for SVG rendering
        p: pack.cells.p ? pack.cells.p.map((p) => [...p]) : [],
        c: pack.cells.c ? pack.cells.c.map((c) => Array.isArray(c) ? [...c] : c) : [],
        v: pack.cells.v ? pack.cells.v.map((v) => Array.isArray(v) ? [...v] : v) : [],
        state: pack.cells.state ? Array.from(pack.cells.state) : [],
        province: pack.cells.province ? Array.from(pack.cells.province) : [],
        biome: pack.cells.biome ? Array.from(pack.cells.biome) : [],
        culture: pack.cells.culture ? Array.from(pack.cells.culture) : [],
        religion: pack.cells.religion ? Array.from(pack.cells.religion) : []
      },
      vertices: pack.vertices ? {
        p: pack.vertices.p ? pack.vertices.p.map((v) => [...v]) : [],
        v: pack.vertices.v ? deepCopy(pack.vertices.v) : [],
        c: pack.vertices.c ? deepCopy(pack.vertices.c) : []
      } : {},
      features: pack.features ? deepCopy(pack.features) : [],
      burgs: pack.burgs ? deepCopy(pack.burgs) : [],
      states: pack.states ? deepCopy(pack.states) : [],
      rivers: pack.rivers ? deepCopy(pack.rivers) : [],
      cultures: pack.cultures ? deepCopy(pack.cultures) : [],
      religions: pack.religions ? deepCopy(pack.religions) : [],
      provinces: pack.provinces ? deepCopy(pack.provinces) : []
    }
  };
  return json;
}
function renderPreview() {
  if (typeof console !== "undefined" && console.warn) {
    console.warn(
      "⚠️ DEPRECATED: renderPreview() is deprecated. Use renderPreviewSVG() instead for production-quality SVG rendering."
    );
  }
  return renderPreviewSVG();
}
function renderPreviewSVG(options = {}) {
  requireInitialized();
  if (!state.data) {
    throw new NoDataError();
  }
  try {
    let width2 = options.width;
    let height2 = options.height;
    const container2 = options.container || state.container;
    if (container2) {
      if (!width2 || !height2) {
        const rect = container2.getBoundingClientRect();
        width2 = width2 || rect.width || state.data.options.mapWidth || 1e3;
        height2 = height2 || rect.height || state.data.options.mapHeight || 600;
      }
    } else {
      width2 = width2 || state.data.options.mapWidth || 1e3;
      height2 = height2 || state.data.options.mapHeight || 600;
    }
    const svgString = renderMapSVG(state.data, {
      width: width2,
      height: height2,
      renderConfig: options.renderConfig,
      colorScheme: options.colorScheme,
      showOceanLayers: options.showOceanLayers,
      oceanLayers: options.oceanLayers
    });
    if (container2) {
      container2.innerHTML = svgString;
      return null;
    } else {
      return svgString;
    }
  } catch (error) {
    if (typeof console !== "undefined" && console.error) {
      console.error("SVG rendering failed:", error);
      console.error("Error stack:", error.stack);
    }
    try {
      const { pack, options: genOptions } = state.data;
      const mapWidth = width || genOptions.mapWidth || 1e3;
      const mapHeight = height || genOptions.mapHeight || 600;
      const minimalLayers = [
        `<rect x="0" y="0" width="${mapWidth}" height="${mapHeight}" fill="#d4d4aa" />`,
        `<text x="${mapWidth / 2}" y="${mapHeight / 2}" text-anchor="middle" fill="#666" font-size="16">Map rendered with errors - some layers may be missing</text>`
      ];
      const minimalSVG = `<svg xmlns="http://www.w3.org/2000/svg" width="${mapWidth}" height="${mapHeight}" viewBox="0 0 ${mapWidth} ${mapHeight}">
${minimalLayers.join("\n")}
</svg>`;
      if (container) {
        container.innerHTML = minimalSVG;
        console.warn("SVG rendered with minimal fallback due to error");
        return null;
      }
      return minimalSVG;
    } catch (fallbackError) {
      throw new GenerationError(`SVG rendering failed: ${error.message}`);
    }
  }
}
function renderToSVG(options = {}) {
  return renderPreviewSVG({ ...options, container: null });
}
function loadMapData(jsonData) {
  requireInitialized();
  if (!jsonData || typeof jsonData !== "object") {
    throw new InvalidOptionError("jsonData", jsonData, "JSON data must be an object");
  }
  try {
    if (!jsonData.pack || !jsonData.grid) {
      throw new InvalidOptionError(
        "jsonData",
        jsonData,
        "JSON data must contain pack and grid objects"
      );
    }
    const requiredPackFields = ["cells", "states", "burgs", "rivers"];
    const missingFields = requiredPackFields.filter((field) => !jsonData.pack[field]);
    if (missingFields.length > 0) {
      if (typeof console !== "undefined" && console.warn) {
        console.warn(`loadMapData: Missing pack fields: ${missingFields.join(", ")}. Rendering may be incomplete.`);
      }
    }
    if (!jsonData.pack.cells || !Array.isArray(jsonData.pack.cells.i)) {
      throw new InvalidOptionError(
        "jsonData",
        jsonData,
        "JSON data must contain pack.cells.i array"
      );
    }
    const renderingFields = ["state", "biome", "culture", "religion", "province", "p", "c", "v"];
    const missingRenderingFields = renderingFields.filter((field) => !jsonData.pack.cells[field]);
    if (missingRenderingFields.length > 0 && typeof console !== "undefined" && console.warn) {
      console.warn(`loadMapData: Missing rendering fields in pack.cells: ${missingRenderingFields.join(", ")}. Some layers may not render.`);
    }
    if (!jsonData.pack.vertices || !jsonData.pack.vertices.p) {
      if (typeof console !== "undefined" && console.warn) {
        console.warn("loadMapData: Missing pack.vertices.p. Border rendering may fail.");
      }
    }
    const reconstructTypedArray = (arr, TypedArray, maxValue) => {
      if (!arr || !Array.isArray(arr)) return null;
      const typed = createTypedArray({ maxValue, length: arr.length });
      typed.set(arr);
      return typed;
    };
    const grid = {
      cells: {
        i: reconstructTypedArray(jsonData.grid.cells.i, Uint16Array, 65535) || new Uint16Array(0),
        h: reconstructTypedArray(jsonData.grid.cells.h, Uint8Array, 255) || new Uint8Array(0),
        t: reconstructTypedArray(jsonData.grid.cells.t, Int8Array, 127) || new Int8Array(0),
        temp: jsonData.grid.cells.temp ? new Float32Array(jsonData.grid.cells.temp) : null,
        prec: jsonData.grid.cells.prec ? new Float32Array(jsonData.grid.cells.prec) : null,
        f: reconstructTypedArray(jsonData.grid.cells.f, Uint16Array, 65535) || new Uint16Array(0),
        b: reconstructTypedArray(jsonData.grid.cells.b, Uint8Array, 255) || new Uint8Array(0)
      },
      points: jsonData.grid.points || [],
      vertices: jsonData.grid.vertices || {},
      features: jsonData.grid.features || []
    };
    const pack = {
      cells: {
        i: reconstructTypedArray(jsonData.pack.cells.i, Uint16Array, 65535) || new Uint16Array(0),
        h: reconstructTypedArray(jsonData.pack.cells.h, Uint8Array, 255) || new Uint8Array(0),
        t: reconstructTypedArray(jsonData.pack.cells.t, Int8Array, 127) || new Int8Array(0),
        f: reconstructTypedArray(jsonData.pack.cells.f, Uint16Array, 65535) || new Uint16Array(0),
        b: reconstructTypedArray(jsonData.pack.cells.b, Uint8Array, 255) || new Uint8Array(0),
        g: reconstructTypedArray(jsonData.pack.cells.g, Uint16Array, 65535) || new Uint16Array(0),
        area: jsonData.pack.cells.area ? new Float32Array(jsonData.pack.cells.area) : new Float32Array(0),
        p: jsonData.pack.cells.p || [],
        // Add cell arrays that may be needed for rendering
        state: jsonData.pack.cells.state ? reconstructTypedArray(jsonData.pack.cells.state, Uint16Array, 65535) : null,
        province: jsonData.pack.cells.province ? reconstructTypedArray(jsonData.pack.cells.province, Uint16Array, 65535) : null,
        biome: jsonData.pack.cells.biome ? reconstructTypedArray(jsonData.pack.cells.biome, Uint8Array, 255) : null,
        culture: jsonData.pack.cells.culture ? reconstructTypedArray(jsonData.pack.cells.culture, Uint16Array, 65535) : null,
        religion: jsonData.pack.cells.religion ? reconstructTypedArray(jsonData.pack.cells.religion, Uint16Array, 65535) : null,
        c: jsonData.pack.cells.c || [],
        v: jsonData.pack.cells.v || []
      },
      vertices: jsonData.pack.vertices || {},
      features: jsonData.pack.features || [],
      burgs: jsonData.pack.burgs || [],
      states: jsonData.pack.states || [],
      rivers: jsonData.pack.rivers || [],
      cultures: jsonData.pack.cultures || [],
      religions: jsonData.pack.religions || [],
      provinces: jsonData.pack.provinces || []
    };
    const options = jsonData.options || getDefaultOptions();
    state.data = {
      grid,
      pack,
      options,
      seed: jsonData.seed || String(Date.now())
    };
    state.options = options;
  } catch (error) {
    if (error instanceof InvalidOptionError || error instanceof InitializationError) {
      throw error;
    }
    throw new InvalidOptionError("jsonData", jsonData, `Failed to load map data: ${error.message}`);
  }
}
export {
  RNG,
  Voronoi$1 as Voronoi,
  assignBiomes,
  assignColors,
  calculateMapCoordinates,
  calculateTemperatures,
  collectStatistics,
  createPackFromGrid,
  createVoronoiDiagram,
  expandCultures,
  expandStates,
  findGridCell,
  generateBurgs,
  generateCultureEmblems,
  generateCultures,
  generateEmblem,
  generateEmblems,
  generateHeightmap,
  generateMap,
  generatePrecipitation,
  generateProvinces,
  generateReligionEmblems,
  generateReligions,
  generateRivers,
  generateStateEmblems,
  generateStates,
  getDefaultBiomes,
  getDefaultOptions,
  getDefaultRenderConfig,
  getMapData,
  getOriginalRenderConfig,
  getTemplate,
  initGenerator,
  listTemplates,
  loadMapData,
  loadOptions,
  markupGrid,
  markupPack,
  mergeNearbyClusters,
  mergeOptions,
  mergeRenderConfig,
  normalizeStates,
  rankCells,
  renderPreview,
  renderPreviewSVG,
  renderToSVG,
  specifyFeatures
};
//# sourceMappingURL=azgaar-genesis.esm.js.map
