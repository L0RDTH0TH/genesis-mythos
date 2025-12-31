function aleaPRNG(...args) {
  var r, t, e, o, a, u = new Uint32Array(3), i = "";
  function c(n) {
    var a2 = function() {
      var n2 = 4022871197, r2 = function(r3) {
        r3 = r3.toString();
        for (var t2 = 0, e2 = r3.length; t2 < e2; t2++) {
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
  randInt(min, max) {
    if (min === void 0 && max === void 0) {
      return Math.floor(this.random() * Number.MAX_SAFE_INTEGER);
    }
    if (max === void 0) {
      max = min;
      min = 0;
    }
    return Math.floor(this.random() * (max - min + 1)) + min;
  }
  /**
   * Generate a random float in range [min, max)
   * @param {number} min - Minimum value (default: 0)
   * @param {number} max - Maximum value
   * @returns {number} Random float
   */
  randFloat(min, max) {
    if (min === void 0 && max === void 0) {
      return this.random();
    }
    if (max === void 0) {
      max = min;
      min = 0;
    }
    return this.random() * (max - min) + min;
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
  pick(array) {
    if (!array || array.length === 0) {
      throw new Error("Cannot pick from empty array");
    }
    return array[this.randInt(0, array.length - 1)];
  }
  /**
   * Pick a random element from a weighted object {key: weight}
   * @param {Object} weights - Object with key-value pairs (key: weight)
   * @returns {string} Random key based on weights
   */
  pickWeighted(weights) {
    const array = [];
    for (const key in weights) {
      for (let i = 0; i < weights[key]; i++) {
        array.push(key);
      }
    }
    return this.pick(array);
  }
  /**
   * Generate a random number with bias towards one end
   * @param {number} min - Minimum value
   * @param {number} max - Maximum value
   * @param {number} exponent - Bias exponent (higher = more bias towards min)
   * @returns {number} Biased random number
   */
  biased(min, max, exponent) {
    return Math.round(min + (max - min) * Math.pow(this.random(), exponent));
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
function minmax(value, min, max) {
  return Math.min(Math.max(value, min), max);
}
function lim(v) {
  return minmax(v, 0, 100);
}
function dist2(p1, p2) {
  const dx = p2[0] - p1[0];
  const dy = p2[1] - p1[1];
  return dx * dx + dy * dy;
}
function gauss(expected = 100, deviation = 30, min = 0, max = 300, round = 0, rng = null) {
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
  return rn(minmax(value, min, max), round);
}
function deepCopy(obj) {
  const id = (x) => x;
  const dcTArray = (a) => a.slice();
  const dcObject = (x) => Object.fromEntries(Object.entries(x).map(([k, d]) => [k, dcAny(d)]));
  const isTypedArray = (x) => x instanceof Int8Array || x instanceof Uint8Array || x instanceof Uint8ClampedArray || x instanceof Int16Array || x instanceof Uint16Array || x instanceof Int32Array || x instanceof Uint32Array || x instanceof Float32Array || x instanceof Float64Array;
  const dcAny = (x) => {
    if (!(x instanceof Object)) return x;
    if (isTypedArray(x)) return dcTArray(x);
    return cf.get(x.constructor) ? cf.get(x.constructor)(x) : id(x);
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
class Voronoi {
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
        this.cells.v[p] = edges.map((e2) => this.triangleOfEdge(e2));
        this.cells.c[p] = edges.map((e2) => this.delaunay.triangles[e2]).filter((c) => c < this.pointsN);
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
    let triangles = [];
    for (let edge of this.edgesOfTriangle(t)) {
      let opposite = this.delaunay.halfedges[edge];
      if (opposite !== -1) {
        triangles.push(this.triangleOfEdge(opposite));
      }
    }
    return triangles;
  }
  edgesAroundPoint(start) {
    const result = [];
    let incoming = start;
    do {
      result.push(incoming);
      const outgoing = this.nextHalfedge(incoming);
      incoming = this.delaunay.halfedges[outgoing];
    } while (incoming !== -1 && incoming !== start && result.length < 20);
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
}
function getBoundaryPoints(width, height, spacing) {
  const offset = rn(-1 * spacing);
  const bSpacing = spacing * 2;
  const w = width - offset * 2;
  const h = height - offset * 2;
  const numberX = Math.ceil(w / bSpacing) - 1;
  const numberY = Math.ceil(h / bSpacing) - 1;
  const points = [];
  for (let i = 0.5; i < numberX; i++) {
    let x = Math.ceil(w * i / numberX + offset);
    points.push([x, offset], [x, h + offset]);
  }
  for (let i = 0.5; i < numberY; i++) {
    let y = Math.ceil(h * i / numberY + offset);
    points.push([offset, y], [w + offset, y]);
  }
  return points;
}
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
function placePoints(width, height, cellsDesired, rng) {
  const spacing = rn(Math.sqrt(width * height / cellsDesired), 2);
  const boundary = getBoundaryPoints(width, height, spacing);
  const points = getJitteredGrid(width, height, spacing, rng);
  const cellsX = Math.floor((width + 0.5 * spacing - 1e-10) / spacing);
  const cellsY = Math.floor((height + 0.5 * spacing - 1e-10) / spacing);
  return { spacing, cellsDesired, boundary, points, cellsX, cellsY };
}
function createVoronoiDiagram(options, rng, DelaunatorClass = null) {
  const width = options.mapWidth;
  const height = options.mapHeight;
  const cellsDesired = getCellsDesired(options);
  const { spacing, boundary, points, cellsX, cellsY } = placePoints(width, height, cellsDesired, rng);
  if (!DelaunatorClass) {
    throw new Error(
      "Delaunator is required as a peer dependency. Pass it as the third parameter or install: npm install delaunator"
    );
  }
  const Delaunator = DelaunatorClass;
  const allPoints = points.concat(boundary);
  const delaunay = Delaunator.from(allPoints);
  const voronoi = new Voronoi(delaunay, allPoints, points.length);
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
function findGridCell(x, y, grid) {
  return Math.floor(Math.min(y / grid.spacing, grid.cellsY - 1)) * grid.cellsX + Math.floor(Math.min(x / grid.spacing, grid.cellsX - 1));
}
function generateBasicHeightmap(grid, options, rng) {
  const { points, cellsDesired } = grid;
  const heights = createTypedArray({ maxValue: 100, length: points.length });
  for (let i = 0; i < heights.length; i++) {
    let height = rng.randInt(0, 100);
    if (rng.probability(0.6)) {
      height = rng.randInt(0, 40);
    } else {
      height = rng.randInt(20, 100);
    }
    heights[i] = lim(height);
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
function maskHeights(heights, grid, width, height, power = 1) {
  const fr = Math.abs(power) || 1;
  for (let i = 0; i < heights.length; i++) {
    const [x, y] = grid.points[i];
    const nx = 2 * x / width - 1;
    const ny = 2 * y / height - 1;
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
  const heights = generateBasicHeightmap(grid, options, rng);
  smoothHeights(heights, grid, 2);
  maskHeights(heights, grid, options.mapWidth, options.mapHeight, 1);
  return heights;
}
function calculateMapCoordinates(options, width, height) {
  const sizeFraction = (options.mapSize || 50) / 100;
  const latShift = options.latitude / 100;
  const lonShift = (options.longitude || 50) / 100;
  const latT = rn(sizeFraction * 180, 1);
  const latN = rn(90 - (180 - latT) * latShift, 1);
  const latS = rn(latN - latT, 1);
  const lonT = rn(Math.min(width / height * latT, 360), 1);
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
  return Array.from(h).map((height, i) => {
    if (height < 20 || !t || t[i] < 1) return height;
    const neighborAvg = c[i] ? c[i].map((cell) => t[cell] || 0).reduce((a, b) => a + b, 0) / c[i].length : 0;
    return height + t[i] / 100 + neighborAvg / 1e4;
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
      const minHeight = Math.min(...cells.c[i].map((c) => h[c]));
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
      if (!cells.c[i] || cells.c[i].length === 0) return;
      const min = cells.c[i].sort((a, b) => h[a] - h[b])[0];
      if (h[i] <= h[min]) return;
      if (cells.fl[i] < MIN_FLUX_TO_FORM_RIVER) {
        if (h[min] >= 20) cells.fl[min] += cells.fl[i];
        return;
      }
      if (!cells.r[i]) {
        cells.r[i] = riverNext;
        addCellToRiver(i, riverNext);
        riverNext++;
      }
      flowDown(min, cells.fl[i], cells.r[i]);
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
      const width = getWidth(getOffset({ flux: discharge, pointIndex: riverCells.length, widthFactor, startingWidth: sourceWidth }));
      pack.rivers.push({
        i: riverId,
        source,
        mouth,
        discharge,
        length,
        width,
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
      const sortedInflux = cells.c[i].filter((c) => cells.r[c] && h[c] > h[i]).map((c) => cells.fl[c]).sort((a, b) => b - a);
      cells.conf[i] = sortedInflux.reduce((acc, flux, index) => index ? acc + flux : acc, 0);
    }
  }
  function downcutRivers() {
    const MAX_DOWNCUT = 5;
    for (const i of cells.i) {
      if (cells.h[i] < 35) continue;
      if (!cells.fl[i]) continue;
      if (!cells.c[i] || cells.c[i].length === 0) continue;
      const higherCells = cells.c[i].filter((c) => cells.h[c] > cells.h[i]);
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
function getAltitudeTemperatureDrop(height, heightExponent) {
  if (height < 20) return 0;
  const heightInMeters = Math.pow(height - 18, heightExponent);
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
  const height = options.mapHeight || 540;
  for (let rowCellId = 0; rowCellId < cells.i.length; rowCellId += grid.cellsX) {
    const [, y] = grid.points[rowCellId];
    const rowLatitude = mapCoordinates.latN - y / height * mapCoordinates.latT;
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
  const color = [
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
    color,
    biomesMatrix,
    habitability,
    iconsDensity,
    icons: parsedIcons,
    cost
  };
}
function isWetland(moisture, temperature, height) {
  if (temperature <= -2) return false;
  if (moisture > 40 && height < 25) return true;
  if (moisture > 24 && height > 24 && height < 60) return true;
  return false;
}
function getBiomeId(moisture, temperature, height, hasRiver, biomesData) {
  if (height < 20) return 0;
  if (temperature < -5) return 11;
  if (temperature >= 25 && !hasRiver && moisture < 8) return 1;
  if (isWetland(moisture, temperature, height)) return 12;
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
  const mean = moistAround.reduce((a, b) => a + b, 0) / moistAround.length;
  return rn(4 + mean);
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
    const height = heights[cellId];
    const moisture = height < MIN_LAND_HEIGHT$1 ? 0 : calculateMoisture(cellId, pack, grid);
    const temperature = temp[gridReference[cellId]];
    biome[cellId] = getBiomeId(moisture, temperature, height, Boolean(riverIds[cellId]), biomesData);
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
function markupDistance({ distanceField, neighbors, start, increment, limit = INT8_MAX }) {
  for (let distance = start, marked = Infinity; marked > 0 && distance !== limit; distance += increment) {
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
    const distances = waterCells.map((neibCellId) => dist2(cells.p[cellId], cells.p[neibCellId]));
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
  const max = Math.floor(sorted.length / 2);
  let cellId = 0;
  let currentSpacing = spacing;
  for (let i = 0; i < MAX_ATTEMPTS; i++) {
    cellId = rng.biased(0, max, 5);
    currentSpacing *= 0.9;
    if (!cultureIds[cellId]) {
      const [x, y] = pack.cells.p[cellId];
      let tooClose = false;
      for (const center of centers) {
        const [cx, cy] = pack.cells.p[center];
        const dist = Math.sqrt((x - cx) ** 2 + (y - cy) ** 2);
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
    const newId = i + 1;
    const sortingFn = c.sort || ((i2) => baseScore[i2]);
    const center = placeCenter(sortingFn, populated, count, pack, options, rng, cultureIds, centers);
    centers.push(center);
    c.center = center;
    c.i = newId;
    delete c.odd;
    delete c.sort;
    c.color = `hsl(${rng.randInt(0, 360)}, 70%, 50%)`;
    c.type = defineCultureType(center, pack, rng);
    c.expansionism = defineCultureExpansionism(c.type, options, rng);
    c.origins = [0];
    c.code = abbreviate(c.name, codes);
    codes.push(c.code);
    c.shield = c.shield || "heater";
    cultureIds[center] = newId;
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
  add(point) {
    this.points.push(point);
  }
  find(x, y, radius) {
    for (const [px, py] of this.points) {
      const dist = Math.sqrt((x - px) ** 2 + (y - py) ** 2);
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
  const x = rn(x0 + 0.95 * (xEdge - x0), 2);
  const y = rn(y0 + 0.95 * (yEdge - y0), 2);
  return [x, y];
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
  const burgs = [null];
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
  const burgsTree = new SimpleQuadtree$1();
  let spacing = (options.mapWidth + options.mapHeight) / 2 / count;
  for (let i = 0; i < sorted.length && burgs.length < count + 1; i++) {
    const cell = sorted[i];
    const [x, y] = cells.p[cell];
    if (!burgsTree.find(x, y, spacing)) {
      burgs.push({ cell, x, y });
      burgsTree.add([x, y]);
    }
  }
  if (burgs.length < count + 1 && spacing > 1) {
    burgsTree = new SimpleQuadtree$1();
    burgs = [null];
    spacing /= 1.2;
    for (let i = 0; i < sorted.length && burgs.length < count + 1; i++) {
      const cell = sorted[i];
      const [x, y] = cells.p[cell];
      if (!burgsTree.find(x, y, spacing)) {
        burgs.push({ cell, x, y });
        burgsTree.add([x, y]);
      }
    }
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
      const [x, y] = cells.p[cell];
      const s = spacing * gauss(1, 0.3, 0.2, 2, 2, rng);
      if (burgsTree.find(x, y, s)) continue;
      const burg = burgs.length;
      const culture = cells.culture[cell];
      const name = `Town${burg}`;
      burgs.push({
        cell,
        x,
        y,
        state: 0,
        i: burg,
        culture,
        name,
        capital: 0,
        feature: cells.f[cell]
      });
      burgsTree.add([x, y]);
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
      const [x, y] = getCloseToEdgePoint(i, haven, pack);
      b.x = x;
      b.y = y;
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
  for (let i = 1; i < burgs.length; i++) {
    if (!burgs[i]) continue;
    const b = burgs[i];
    b.i = i;
    b.state = i;
    b.culture = cells.culture[b.cell];
    b.name = `Capital${i}`;
    b.feature = cells.f[b.cell];
    b.capital = 1;
    cells.burg[b.cell] = i;
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
  const colors2 = ["#66c2a5", "#fc8d62", "#8da0cb", "#e78ac3", "#a6d854", "#ffd92f"];
  return rng.pick(colors2);
}
function createStates({ pack, options, rng }) {
  const { cells, burgs, cultures } = pack;
  const states = [{ i: 0, name: "Neutrals" }];
  const colors2 = ["#66c2a5", "#fc8d62", "#8da0cb", "#e78ac3", "#a6d854", "#ffd92f"];
  const capitals = burgs.filter((b) => b && b.capital);
  capitals.forEach((b, i) => {
    const stateId = i + 1;
    const culture = cells.culture[b.cell];
    const cultureData = cultures[culture];
    const sizeVariety = options.sizeVariety || 1;
    const expansionism = rn(rng.random() * sizeVariety + 1, 1);
    const type = cultureData ? cultureData.type : "Generic";
    const name = `State${stateId}`;
    states.push({
      i: stateId,
      color: colors2[(stateId - 1) % colors2.length],
      name,
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
  const colors2 = ["#66c2a5", "#fc8d62", "#8da0cb", "#e78ac3", "#a6d854", "#ffd92f"];
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
  const array = [];
  for (const key in weights) {
    for (let i = 0; i < weights[key]; i++) {
      array.push(key);
    }
  }
  return rng.pick(array);
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
  const max = provincesRatio === 100 ? 1e3 : gauss(20, 5, 5, 100, 0, rng) * Math.pow(provincesRatio, 0.5);
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
      const color = getMixedColor$1(s.color);
      provinces.push({
        i: provinceId,
        state: s.i,
        center,
        burg: burgId,
        name,
        formName,
        fullName,
        color,
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
      if (totalCost > max) return;
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
          if (totalCost > max) return;
          if (!wildCost[nextCellId] || totalCost < wildCost[nextCellId]) {
            if (land && cells.state && cells.state[nextCellId] === s.i) provinceIds[nextCellId] = provinceId;
            wildCost[nextCellId] = totalCost;
            wildQueue.push({ e: nextCellId, p: totalCost }, totalCost);
          }
        });
      }
      cells.culture && cells.culture[center] !== void 0 ? cells.culture[center] : 0;
      const f = pack.features && cells.f && cells.f[center] !== void 0 ? pack.features[cells.f[center]] : null;
      const color = getMixedColor$1(s.color);
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
        color,
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
  add(point) {
    this.points.push(point);
  }
  find(x, y, radius) {
    for (const [px, py] of this.points) {
      const dist = Math.sqrt((x - px) ** 2 + (y - py) ** 2);
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
      const [x, y] = cells.p[cellId];
      if (!religionsTree.find(x, y, spacing)) {
        religionCells.push(cellId);
        religionsTree.add([x, y]);
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
    let color = getRandomColor(rng);
    if (culture) {
      if (type === "Folk") {
        color = culture.color || color;
      } else if (type === "Heresy") {
        color = getMixedColor(culture.color || color, 0.35, 0.2);
      } else if (type === "Cult") {
        color = getMixedColor(culture.color || color, 0.5, 0);
      } else {
        color = getMixedColor(culture.color || color, 0.25, 0.4);
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
      color
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
const STYLE_CONSTANTS$1 = {
  oceanBase: "#b4d2f3",
  landBase: "#eef6fb",
  lakeFreshwater: "#a8c8e0",
  lakeSaltwater: "#9bb5d1"
};
function renderMap(canvas, data) {
  if (!canvas || !(canvas instanceof HTMLCanvasElement)) {
    throw new Error("Canvas element is required");
  }
  if (!data || !data.grid || !data.pack) {
    throw new Error("Map data with grid and pack is required");
  }
  const ctx = canvas.getContext("2d");
  if (!ctx) {
    throw new Error("Could not get 2D rendering context from canvas");
  }
  const { grid, pack, options } = data;
  const { mapWidth, mapHeight } = options;
  canvas.width = mapWidth;
  canvas.height = mapHeight;
  ctx.clearRect(0, 0, mapWidth, mapHeight);
  drawOceans(ctx, { grid, pack, options });
  drawLakes(ctx, { grid, pack, options });
  drawLandmass(ctx, { grid, pack, options });
}
function drawOceans(ctx, { grid, pack, options }) {
  const { mapWidth, mapHeight } = options;
  const { cells } = grid;
  ctx.fillStyle = STYLE_CONSTANTS$1.oceanBase;
  ctx.fillRect(0, 0, mapWidth, mapHeight);
}
function drawLakes(ctx, { grid, pack, options }) {
  if (!pack.features || !pack.cells) {
    return;
  }
  const features = pack.features;
  const { cells, p: cellPoints } = pack.cells;
  for (const feature of features) {
    if (!feature || feature.type !== "lake") {
      continue;
    }
    const lakeGroup = feature.group || "freshwater";
    ctx.fillStyle = lakeGroup === "saltwater" ? STYLE_CONSTANTS$1.lakeSaltwater : STYLE_CONSTANTS$1.lakeFreshwater;
    for (let i = 0; i < cells.f.length; i++) {
      if (cells.f[i] === feature.i) {
        const [x, y] = cellPoints[i];
        if (x !== void 0 && y !== void 0) {
          const radius = cells.area && cells.area[i] ? Math.sqrt(cells.area[i]) * 0.5 : 3;
          ctx.beginPath();
          ctx.arc(x, y, radius, 0, Math.PI * 2);
          ctx.fill();
        }
      }
    }
  }
}
function drawLandmass(ctx, { grid, pack, options }) {
  const { mapWidth, mapHeight } = options;
  ctx.fillStyle = STYLE_CONSTANTS$1.landBase;
  ctx.fillRect(0, 0, mapWidth, mapHeight);
}
const STYLE_CONSTANTS = {
  oceanBase: "#b4d2f3",
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
  function addIsoline(type, vertices2, vertexChain) {
    if (!isolines[type]) isolines[type] = {};
    if (options.fill) {
      if (!isolines[type].fill) isolines[type].fill = "";
      isolines[type].fill += getFillPath(vertices2, vertexChain);
    }
    if (options.waterGap) {
      if (!isolines[type].waterGap) isolines[type].waterGap = "";
      const isLandVertex = (vertexId) => {
        var _a2;
        return (_a2 = vertices2.c[vertexId]) == null ? void 0 : _a2.every((i) => cells.h[i] >= MIN_LAND_HEIGHT);
      };
      isolines[type].waterGap += getBorderPath(vertices2, vertexChain, isLandVertex);
    }
    if (options.halo) {
      if (!isolines[type].halo) isolines[type].halo = "";
      const isBorderVertex = (vertexId) => {
        var _a2;
        return (_a2 = vertices2.c[vertexId]) == null ? void 0 : _a2.some((i) => cells.b[i]);
      };
      isolines[type].halo += getBorderPath(vertices2, vertexChain, isBorderVertex);
    }
  }
}
function connectVertices({ vertices, startingVertex, ofSameType, addToChecked, closeRing }) {
  const MAX_ITERATIONS = vertices.c.length;
  const chain = [];
  let next = startingVertex;
  for (let i = 0; i === 0 || next !== startingVertex; i++) {
    const previous = chain[chain.length - 1];
    const current = next;
    chain.push(current);
    const neibCells = vertices.c[current];
    if (addToChecked && neibCells) {
      neibCells.filter(ofSameType).forEach(addToChecked);
    }
    const [c1, c2, c3] = (neibCells == null ? void 0 : neibCells.map(ofSameType)) || [false, false, false];
    const [v1, v2, v3] = vertices.v[current] || [null, null, null];
    if (v1 !== void 0 && v1 !== previous && c1 !== c2) next = v1;
    else if (v2 !== void 0 && v2 !== previous && c2 !== c3) next = v2;
    else if (v3 !== void 0 && v3 !== previous && c1 !== c3) next = v3;
    if (next >= vertices.c.length || next === current) break;
    if (i >= MAX_ITERATIONS) break;
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
    if (discontinue(vertexId)) {
      discontinued = true;
      continue;
    }
    const operation = discontinued ? "M" : "L";
    discontinued = false;
    const point = vertices.p[vertexId];
    pathParts.push(`${operation}${point[0]},${point[1]}`);
  }
  return pathParts.join(" ").trim();
}
function getGappedFillPaths(elementName, fill, waterGap, color, index) {
  let html = "";
  if (fill) {
    html += `<path d="${fill}" fill="${color}" id="${elementName}${index}" />`;
  }
  if (waterGap) {
    html += `<path d="${waterGap}" fill="none" stroke="${color}" stroke-width="3" id="${elementName}-gap${index}" />`;
  }
  return html;
}
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
function drawBordersSVG(pack) {
  var _a, _b, _c;
  if (!pack.cells || !pack.cells.state) {
    return { stateBorders: "", provinceBorders: "" };
  }
  const { cells, vertices } = pack;
  const statePath = [];
  const provincePath = [];
  const checked = {};
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
      return isLand2(neibId) && stateId > neibStateId && !checked[`state-${stateId}-${neibStateId}-${cellId}`];
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
    var _a2;
    const getType = (cellId) => {
      var _a3;
      return (_a3 = cells[type]) == null ? void 0 : _a3[cellId];
    };
    const isTypeFrom = (cellId) => cellId < cells.i.length && getType(cellId) === getType(fromCell);
    const isTypeTo = (cellId) => cellId < cells.i.length && getType(cellId) === getType(toCell);
    addToChecked(fromCell);
    const startingVertex = (_a2 = cells.v[fromCell]) == null ? void 0 : _a2.find(
      (v) => {
        var _a3;
        return (_a3 = vertices.c[v]) == null ? void 0 : _a3.some((i) => isLand2(i) && isTypeTo(i));
      }
    );
    if (startingVertex === void 0) return null;
    const checkVertex = (vertex) => {
      var _a3, _b2;
      return ((_a3 = vertices.c[vertex]) == null ? void 0 : _a3.some(isTypeFrom)) && ((_b2 = vertices.c[vertex]) == null ? void 0 : _b2.some((c) => isLand2(c) && isTypeTo(c)));
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
        chain.push(current);
        const neibCells = vertices2.c[current];
        if (neibCells) neibCells.forEach(addToChecked);
        const [c1, c2, c3] = (neibCells == null ? void 0 : neibCells.map(checkCell)) || [false, false, false];
        const [v1, v2, v3] = vertices2.v[current] || [null, null, null];
        if (v1 !== void 0 && v1 !== previous && c1 !== c2) next = v1;
        else if (v2 !== void 0 && v2 !== previous && c2 !== c3) next = v2;
        else if (v3 !== void 0 && v3 !== previous && c1 !== c3) next = v3;
        if (next === current || next === startingVertex) {
          if (next === startingVertex) chain.push(startingVertex);
          startingVertex = next;
          break;
        }
      }
    }
    return chain;
  }
  const stateBordersSVG = statePath.length ? `<path d="${statePath.join(" ")}" stroke="${STYLE_CONSTANTS.stateBorderStroke}" stroke-width="${STYLE_CONSTANTS.stateBorderWidth}" stroke-dasharray="${STYLE_CONSTANTS.stateBorderDashArray}" fill="none" />` : "";
  const provinceBordersSVG = provincePath.length ? `<path d="${provincePath.join(" ")}" stroke="${STYLE_CONSTANTS.provinceBorderStroke}" stroke-width="${STYLE_CONSTANTS.provinceBorderWidth}" stroke-dasharray="${STYLE_CONSTANTS.provinceBorderDashArray}" fill="none" />` : "";
  return { stateBorders: stateBordersSVG, provinceBorders: provinceBordersSVG };
}
function drawRiversSVG(pack) {
  if (!pack.rivers || !Array.isArray(pack.rivers)) return "";
  const riverPaths = pack.rivers.map((river) => {
    if (!river.cells || river.cells.length < 2) return null;
    const points = river.cells.map((cellId) => {
      if (cellId < 0 || cellId >= pack.cells.p.length) return null;
      return pack.cells.p[cellId];
    }).filter((p) => p !== null);
    if (points.length < 2) return null;
    const meanderedPoints = addMeandering(points);
    const path = getRiverPath(meanderedPoints, river.widthFactor || 1, river.sourceWidth || 1);
    return `<path id="river${river.i}" d="${path}" fill="${STYLE_CONSTANTS.riverFill}" stroke="${STYLE_CONSTANTS.riverStroke}" stroke-width="0.5" />`;
  }).filter((p) => p !== null);
  return riverPaths.join("");
}
function addMeandering(points) {
  if (points.length < 2) return points;
  const meandered = [];
  const meanderingAmount = 0.3;
  for (let i = 0; i < points.length; i++) {
    const [x, y] = points[i];
    meandered.push([x, y]);
    if (i < points.length - 1) {
      const [x1, y1] = points[i];
      const [x2, y2] = points[i + 1];
      const dx = x2 - x1;
      const dy = y2 - y1;
      const midX = (x1 + x2) / 2;
      const midY = (y1 + y2) / 2;
      const perpX = -dy * meanderingAmount;
      const perpY = dx * meanderingAmount;
      meandered.push([midX + perpX, midY + perpY]);
    }
  }
  return meandered;
}
function getRiverPath(points, widthFactor, startingWidth) {
  if (points.length < 2) return "";
  let path = `M${points[0][0]},${points[0][1]}`;
  for (let i = 1; i < points.length; i++) {
    if (i === 1) {
      path += ` L${points[i][0]},${points[i][1]}`;
    } else {
      const [x1, y1] = points[i - 1];
      const [x2, y2] = points[i];
      const [x0, y0] = points[i - 2] || points[i - 1];
      const cpX = (x1 + x2) / 2;
      const cpY = (y1 + y2) / 2;
      path += ` Q${cpX},${cpY} ${x2},${y2}`;
    }
  }
  return path;
}
function drawBurgsSVG(pack) {
  if (!pack.burgs || !Array.isArray(pack.burgs)) return "";
  const burgElements = [];
  for (const burg of pack.burgs) {
    if (!burg || burg.removed || !burg.x || !burg.y) continue;
    const isCapital = burg.capital;
    const size = isCapital ? STYLE_CONSTANTS.burgCapitalSize : STYLE_CONSTANTS.burgTownSize;
    const color = isCapital ? STYLE_CONSTANTS.burgCapitalColor : STYLE_CONSTANTS.burgTownColor;
    burgElements.push(
      `<circle id="burg${burg.i}" cx="${rn(burg.x, 2)}" cy="${rn(burg.y, 2)}" r="${size}" fill="${color}" />`
    );
    if (burg.name) {
      const labelY = burg.y - size * 1.5;
      burgElements.push(
        `<text id="burgLabel${burg.i}" x="${rn(burg.x, 2)}" y="${rn(labelY, 2)}" font-size="${size * 3}" text-anchor="middle" fill="${color}">${burg.name}</text>`
      );
    }
  }
  return burgElements.join("");
}
function drawFeaturesSVG(pack) {
  if (!pack.features || !Array.isArray(pack.features)) return "";
  const featurePaths = [];
  for (const feature of pack.features) {
    if (!feature || feature.type === "ocean") continue;
    if (feature.vertices && feature.vertices.length > 0 && pack.vertices) {
      const points = feature.vertices.map((vId) => pack.vertices.p[vId]).filter((p) => p !== void 0);
      if (points.length >= 3) {
        const path = `M${points[0][0]},${points[0][1]} L${points.slice(1).map((p) => `${p[0]},${p[1]}`).join(" ")} Z`;
        const fillColor = feature.type === "lake" ? feature.group === "saltwater" ? STYLE_CONSTANTS.lakeSaltwater : STYLE_CONSTANTS.lakeFreshwater : STYLE_CONSTANTS.landBase;
        featurePaths.push(
          `<path id="feature_${feature.i}" d="${path}" fill="${fillColor}" stroke="${fillColor}" stroke-width="0.5" />`
        );
      }
    }
  }
  return featurePaths.join("");
}
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
let state = {
  canvas: null,
  container: null,
  // SVG container element (optional)
  options: getDefaultOptions(),
  data: null,
  // { grid, pack, seed }
  initialized: false
};
function createBasicPack(grid, options) {
  const { cells: gridCells, points, vertices } = grid;
  const packCells = {
    i: createTypedArray({ maxValue: gridCells.i.length, length: gridCells.i.length }).map((_, i) => i),
    p: points.slice(),
    g: createTypedArray({ maxValue: gridCells.i.length, length: gridCells.i.length }).map((_, i) => i),
    h: new Uint8Array(gridCells.h.length),
    c: gridCells.c ? gridCells.c.slice() : [],
    b: gridCells.b ? new Uint8Array(gridCells.b.length) : new Uint8Array(gridCells.i.length),
    t: gridCells.t ? new Int8Array(gridCells.t.length) : new Int8Array(gridCells.i.length),
    f: gridCells.f ? new Uint16Array(gridCells.f.length) : new Uint16Array(gridCells.i.length),
    area: new Float32Array(gridCells.i.length)
  };
  packCells.h.set(gridCells.h);
  if (gridCells.t) packCells.t.set(gridCells.t);
  if (gridCells.f) packCells.f.set(gridCells.f);
  if (gridCells.b) packCells.b.set(gridCells.b);
  for (let i = 0; i < gridCells.i.length; i++) {
    packCells.area[i] = 1;
  }
  const pack = {
    cells: packCells,
    vertices: vertices || {},
    features: grid.features || []
  };
  return pack;
}
function generateMapInternal(options, DelaunatorClass) {
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
  let pack = createBasicPack(grid);
  pack.cells.h = grid.cells.h;
  for (let i = 0; i < pack.cells.i.length; i++) {
    pack.cells.g[i] = i;
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
  specifyFeatures({ pack, grid, options });
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
function initGenerator({ canvas = null, container = null } = {}) {
  if (state.initialized) {
    throw new InitializationError(
      "Generator already initialized. Cannot initialize multiple times."
    );
  }
  if (canvas !== null && !(canvas instanceof HTMLCanvasElement)) {
    throw new InitializationError(
      `Invalid canvas element. Expected HTMLCanvasElement, got ${typeof canvas}`
    );
  }
  if (container !== null && !(container instanceof HTMLElement)) {
    throw new InitializationError(
      `Invalid container element. Expected HTMLElement, got ${typeof container}`
    );
  }
  state.canvas = canvas;
  state.container = container;
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
  requireInitialized();
  try {
    const data = generateMapInternal(state.options, DelaunatorClass);
    state.data = data;
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
  requireInitialized();
  if (!state.data) {
    throw new NoDataError();
  }
  if (!state.canvas) {
    if (typeof console !== "undefined" && console.warn) {
      console.warn("renderPreview() called but no canvas was provided during initialization. Skipping render.");
    }
    return;
  }
  try {
    renderMap(state.canvas, state.data);
  } catch (error) {
    throw new GenerationError(`Rendering failed: ${error.message}`);
  }
}
function renderPreviewSVG(options = {}) {
  requireInitialized();
  if (!state.data) {
    throw new NoDataError();
  }
  try {
    let width = options.width;
    let height = options.height;
    const container = options.container || state.container;
    if (container) {
      if (!width || !height) {
        const rect = container.getBoundingClientRect();
        width = width || rect.width || state.data.options.mapWidth || 1e3;
        height = height || rect.height || state.data.options.mapHeight || 600;
      }
    } else {
      width = width || state.data.options.mapWidth || 1e3;
      height = height || state.data.options.mapHeight || 600;
    }
    const svgString = renderMapSVG(state.data, { width, height });
    if (container) {
      container.innerHTML = svgString;
      return null;
    } else {
      return svgString;
    }
  } catch (error) {
    if (typeof console !== "undefined" && console.error) {
      console.error("SVG rendering failed:", error);
    }
    throw new GenerationError(`SVG rendering failed: ${error.message}`);
  }
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
  Voronoi,
  assignBiomes,
  assignColors,
  calculateMapCoordinates,
  calculateTemperatures,
  collectStatistics,
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
  getMapData,
  initGenerator,
  loadMapData,
  loadOptions,
  markupGrid,
  markupPack,
  mergeOptions,
  normalizeStates,
  renderPreview,
  renderPreviewSVG,
  specifyFeatures
};
//# sourceMappingURL=azgaar-genesis.esm.js.map
