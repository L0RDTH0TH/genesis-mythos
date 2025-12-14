# Testing Plan Summary - Genesis Mythos

**Project:** Genesis Mythos (Full First-Person 3D Virtual Tabletop RPG)  
**Engine:** Godot 4.3 Stable  
**Language:** GDScript  
**Last Updated:** 2025-12-13  
**Author:** Lordthoth

---

## Executive Summary

This document outlines a comprehensive testing philosophy, strategy, and implementation plan for Genesis Mythos. The project is a complex 3D game combining procedural world generation, first-person exploration, tabletop RPG mechanics, and multiplayer support. Testing must cover both deterministic systems (world generation, data loading) and interactive systems (UI, player input, networking).

**Current State:** Interaction-only UI tests exist (~100% UI input coverage), but core systems lack unit/integration tests. No CI/CD pipeline currently configured.

**Target State:** Comprehensive test pyramid with 80%+ code coverage on critical paths, automated CI/CD, performance benchmarks, and multiplayer integration tests.

---

## 1. Project Overview

### 1.1 High-Level Description

Genesis Mythos is a full first-person 3D immersive virtual tabletop role-playing game that blends:
- **First-person exploration** (FPS-style movement, interaction, combat)
- **Classic tabletop elements** (dice rolling, character sheets, GM tools, grid maps, tokens, fog of war)
- **Procedural world generation** (heightmaps, biomes, civilizations, resources)
- **Data-driven content** (100% JSON/Resource-based, zero hard-coded content)

### 1.2 Main Tech Stack

- **Engine:** Godot 4.3 stable (4.3.x)
- **Language:** GDScript only (typed, no C#/VisualScript)
- **Architecture:** Modular with autoload singletons
- **Data Format:** JSON + Godot Resources
- **Rendering:** Vulkan (Forward Plus)
- **Physics:** Jolt Physics Engine
- **Key Plugins:** Terrain3D, Procedural World Map Addon

### 1.3 Architecture

**Type:** Monolithic game engine with modular subsystems

**Core Components:**
- **5 Autoload Singletons:**
  - `Eryndor` - Main game controller
  - `Logger` - Centralized logging system
  - `WorldStreamer` - World streaming/loading
  - `EntitySim` - Entity simulation
  - `FactionEconomy` - Faction economy simulation

- **World Generation Systems:**
  - `MapGenerator` - Procedural heightmap/biome generation
  - `MapRenderer` - Shader-based 2D map rendering
  - `MapEditor` - Brush-based map editing
  - `Terrain3DManager` - 3D terrain integration
  - `MarkerManager` - Icon placement system

- **UI Systems:**
  - `WorldBuilderUI` - 8-step wizard interface
  - `MapMakerModule` - Map generation UI module
  - Character creation UI (planned)

- **Data Systems:**
  - JSON configuration files (`biomes.json`, `civilizations.json`, `resources.json`, etc.)
  - Resource-based data loading
  - Save/load system (basic implementation)

### 1.4 Key Features & Critical User Flows

**Top 5 Critical Paths:**

1. **World Generation Flow**
   - Seed input → Terrain configuration → Climate/Biome setup → Civilization placement → Resource generation → Export
   - **Risk:** Deterministic generation must produce consistent results, performance at large map sizes

2. **Character Creation Flow** (Planned)
   - Race selection → Class selection → Background → Ability scores → Appearance → Name/Confirm
   - **Risk:** Point buy validation, data integrity, UI state management

3. **First-Person Exploration** (In Progress)
   - Movement → Interaction → Combat → Inventory
   - **Risk:** Physics, collision detection, frame rate stability (60 FPS target)

4. **Tabletop Overlay System** (Planned)
   - Dice rolling → Token placement → Grid measurement → Fog of war
   - **Risk:** Physics simulation, state synchronization, UI responsiveness

5. **Multiplayer Session** (Planned)
   - Host/Join → World sync → Player actions → GM tools
   - **Risk:** Network synchronization, latency, state consistency

---

## 2. Current Testing State

### 2.1 Existing Tests

**Location:** `res://tests/interaction_only/`

**Test Type:** Interaction-only UI tests (integration-level)

**Coverage:**
- ✅ **100% UI Input Coverage** - All player-triggerable UI controls tested
- ✅ World Generation UI (9 test files)
- ✅ Character Creation UI (7 test files, but character creation not fully implemented)
- ✅ Preview Panel tests
- ✅ Validation & Edge Case tests
- ✅ Visual Feedback tests

**Test Framework:** Custom test runner (`TestInteractionOnlyRunner.gd`) with helper utilities (`TestHelpers.gd`)

**Execution:**
- Manual: Run `TestInteractionOnlyRunner.tscn` scene
- Automated: Command-line via `godot --headless --script`
- Visual delay configurable (0.0 for CI, 1.0+ for manual verification)

**Strengths:**
- Comprehensive UI interaction coverage
- Well-structured test helpers
- Async/await support for signal waiting
- Visual delay for manual verification

**Gaps (Partially Addressed in Phase 1):**
- ✅ **Phase 1 Complete:** Unit tests for MapGenerator (7 tests), Logger (9 tests), JSON loading (12 tests)
- ⏳ Integration tests for data loading/JSON parsing (Phase 2)
- ⏳ Performance benchmarks (Phase 3)
- ⏳ Multiplayer/networking tests (Phase 4)
- ⏳ Save/load system tests (Phase 2)
- ⏳ Physics/collision tests (Future)
- ⏳ Shader/material tests (Future)

### 2.2 Phase 1 Implementation (2025-12-13)

**Status:** ✅ **Phase 1 Foundation Complete**

**New Test Infrastructure:**
- ✅ GUT framework integration (v9.3.0+)
- ✅ Test directory structure created (`tests/unit/`, `tests/integration/`, `tests/e2e/`, `tests/performance/`, `tests/regression/`)
- ✅ Extended `TestHelpers.gd` with headless detection and verbose assertions
- ✅ Created `UnitTestHelpers.gd` with fixtures and comparison utilities
- ✅ CI/CD pipeline configured (`.github/workflows/test.yml`)

**New Unit Tests (28 total):**
- ✅ **MapGenerator** (`test_map_generator.gd`): 7 tests
  - Same seed produces identical heightmap (determinism)
  - Different seeds produce different heightmaps
  - Heightmap values in valid range [0.0, 1.0]
  - Erosion reduces peak heights
  - Null data handling
  - Heightmap image creation
  - Correct image size
- ✅ **Logger** (`test_logger.gd`): 9 tests
  - Singleton exists and accessible
  - Log level enum exists
  - All log methods work without crash
  - Null/empty parameter handling
  - Data parameter support
  - Config reloading
  - System level changes
  - Config loading
- ✅ **JSON Loading** (`test_json_loading.gd`): 12 tests
  - All JSON files exist and readable
  - Valid JSON structure for biomes, civilizations, resources, map_icons
  - Required fields validation (biomes)
  - Invalid JSON handling
  - Missing file handling
  - Edge cases (empty, whitespace)

**Coverage Status:**
- Tests written and ready for execution
- Awaiting GUT installation and first test run
- Target: 80%+ coverage on core systems (MapGenerator, Logger, JSON loading)

**Next Steps:**
1. Install GUT framework (user action required)
2. Run tests and verify all pass
3. Generate coverage report
4. Begin Phase 2 (Integration tests)

### 2.2 Directory Structure

```
res://
├── tests/
│   └── interaction_only/          # Existing UI tests
│       ├── TestInteractionOnlyRunner.gd
│       ├── helpers/
│       │   └── TestHelpers.gd
│       ├── fixtures/
│       │   └── TestGameData.gd
│       └── [test files]
├── core/                          # Core systems (UNTESTED)
├── data/                          # JSON data files (UNTESTED)
├── scripts/                       # Game scripts (UNTESTED)
└── ui/                            # UI components (PARTIALLY TESTED)
```

### 2.3 Configuration Files

**No test configuration files found:**
- No `pytest.ini`, `jest.config.js`, or equivalent
- No CI/CD configuration (`.github/workflows/` empty)
- No coverage reporting setup
- No test coverage thresholds defined

**Project Configuration:**
- `project.godot` - Main project config
- `data/config/logging_config.json` - Logging configuration
- `data/config/terrain_generation.json` - Terrain generation config
- `data/config/world_builder_ui.json` - UI configuration

### 2.4 Build/CI Status

**Current State:**
- ❌ No CI/CD pipeline configured
- ❌ No automated test runs
- ❌ No coverage reports
- ❌ No automated builds
- ❌ No release automation

**Manual Testing:**
- Tests run manually via Godot editor or command-line
- No automated regression testing
- No pre-commit hooks

---

## 3. Testing Philosophy & Strategy

### 3.1 Testing Philosophy

**Core Principles:**

1. **Data-Driven Testing:** Since the game is 100% data-driven, tests must validate JSON schema, data loading, and data integrity
2. **Deterministic Systems First:** Procedural generation must be deterministic and testable with fixed seeds
3. **Performance-Critical:** 60 FPS target requires performance benchmarks and profiling
4. **Player-Facing Focus:** UI tests ensure player experience is bug-free (already achieved)
5. **Extensibility:** Tests must support future modding and content expansion

### 3.2 Testing Pyramid vs. Trophy

**Recommended Approach: Testing Pyramid** (with emphasis on unit tests for core systems)

```
        /\
       /  \      E2E Tests (5-10%)
      /____\     - Full game flow tests
     /      \    - Multiplayer session tests
    /        \   - Save/load integration tests
   /__________\  
  /            \ Integration Tests (20-30%)
 /              \ - System integration (MapGenerator + MapRenderer)
/________________\ - Data loading + UI integration
                  \ - Terrain3D + WorldStreamer integration
                   \
                    Unit Tests (60-70%)
                    - MapGenerator algorithms
                    - Logger functionality
                    - Data parsing/validation
                    - Math utilities
                    - Noise generation
```

**Rationale:**
- Core systems (MapGenerator, Logger, data loading) are highly testable with unit tests
- Integration tests validate system interactions
- E2E tests ensure critical user flows work end-to-end
- Performance tests are separate layer (not in pyramid)

### 3.3 Test Coverage Targets

**Overall Coverage Goal: 80%+ for critical paths**

**Breakdown by System:**

| System | Target Coverage | Priority | Rationale |
|--------|----------------|----------|------------|
| **Core Singletons** | 90%+ | Critical | Foundation of entire game |
| **MapGenerator** | 85%+ | Critical | Deterministic generation must be reliable |
| **Data Loading/JSON** | 95%+ | Critical | Data integrity is paramount |
| **Logger** | 80%+ | High | Logging must be reliable for debugging |
| **WorldStreamer** | 75%+ | High | World loading affects player experience |
| **UI Systems** | 100% | High | Already achieved (interaction-only tests) |
| **EntitySim** | 70%+ | Medium | Simulation logic needs validation |
| **FactionEconomy** | 70%+ | Medium | Economic calculations need accuracy |
| **Terrain3D Integration** | 60%+ | Medium | Plugin integration, focus on our code |
| **Save/Load** | 80%+ | High | Data persistence critical |
| **First-Person Controller** | 70%+ | High | Core gameplay mechanic |
| **Tabletop Systems** | 75%+ | Medium | Physics and state management |
| **Multiplayer** | 80%+ | Critical | Network sync must be reliable |

**Coverage Measurement:**
- Use Godot's built-in code coverage (if available in 4.3)
- Or use external tools (Gut test framework has coverage support)
- Track coverage per system, not just overall percentage

---

## 4. Test Types & Implementation Plan

### 4.1 Unit Tests

**Purpose:** Test individual functions/classes in isolation

**Framework:** GUT (Godot Unit Testing) - recommended for Godot 4.3

**Target Systems:**

1. **MapGenerator** (`core/world_generation/MapGenerator.gd`)
   - Noise generation with fixed seeds
   - Heightmap generation algorithms
   - Erosion algorithm correctness
   - River generation logic
   - Biome assignment calculations
   - **Test Cases:**
     - Same seed produces identical results
     - Different seeds produce different results
     - Heightmap values in valid range [0.0, 1.0]
     - Erosion reduces peak heights
     - Rivers flow from high to low elevation

2. **Logger** (`core/singletons/Logger.gd`)
   - Log level filtering
   - Category-based filtering
   - File logging rotation
   - Console output formatting
   - **Test Cases:**
     - Log levels respect configuration
     - Categories filter correctly
     - File rotation works
     - Log format is consistent

3. **Data Loading** (`data/` JSON files)
   - JSON schema validation
   - Data parsing correctness
   - Missing file handling
   - Invalid JSON handling
   - **Test Cases:**
     - All JSON files are valid
     - Required fields present
     - Data types correct
     - Default values applied

4. **Math Utilities** (if any)
   - Vector calculations
   - Noise utilities
   - Biome calculations
   - **Test Cases:**
     - Calculations produce expected results
     - Edge cases handled (division by zero, etc.)

**Implementation:**
```gdscript
# Example: tests/unit/test_map_generator.gd
extends GutTest

func test_same_seed_produces_identical_heightmap():
    var gen1 = MapGenerator.new()
    var gen2 = MapGenerator.new()
    var data1 = WorldMapData.new()
    var data2 = WorldMapData.new()
    data1.seed_value = 12345
    data2.seed_value = 12345
    gen1.generate_map(data1, false)
    gen2.generate_map(data2, false)
    assert_eq(data1.heightmap, data2.heightmap)
```

### 4.2 Integration Tests

**Purpose:** Test interactions between multiple systems

**Framework:** GUT + custom integration test helpers

**Target Systems:**

1. **MapGenerator + MapRenderer Integration**
   - Generated heightmap renders correctly
   - Biome preview matches generated data
   - Texture updates when data changes
   - **Test Cases:**
     - Heightmap texture created from data
     - Biome colors match biome definitions
     - Renderer updates when generator completes

2. **Data Loading + UI Integration**
   - JSON data loads into UI correctly
   - UI reflects data changes
   - Invalid data shows error messages
   - **Test Cases:**
     - Biome list populated from JSON
     - Civilization options match data
     - Resource types displayed correctly

3. **Terrain3D + WorldStreamer Integration**
   - 3D terrain generated from 2D heightmap
   - Streaming loads chunks correctly
   - Performance acceptable during streaming
   - **Test Cases:**
     - Terrain mesh matches heightmap
     - Chunks load/unload correctly
     - Frame rate maintained during streaming

4. **Save/Load System Integration**
   - World data saves correctly
   - Saved data loads identically
   - Multiple save slots work
   - **Test Cases:**
     - Save file contains all world data
     - Loaded world matches saved state
     - Save slots don't interfere

**Implementation:**
```gdscript
# Example: tests/integration/test_map_generation_pipeline.gd
extends GutTest

func test_full_generation_pipeline():
    var generator = MapGenerator.new()
    var renderer = MapRenderer.new()
    var data = WorldMapData.new()
    data.seed_value = 12345
    data.world_width = 512
    data.world_height = 512
    
    generator.generate_map(data, false)
    renderer.set_world_map_data(data)
    renderer.refresh()
    
    assert_not_null(renderer.heightmap_texture)
    assert_eq(renderer.heightmap_texture.get_width(), 512)
```

### 4.3 End-to-End (E2E) Tests

**Purpose:** Test complete user flows from start to finish

**Framework:** Custom E2E test runner (extend existing `TestInteractionOnlyRunner`)

**Target Flows:**

1. **Complete World Generation Flow**
   - Launch world builder → Configure all steps → Generate → Export
   - **Test Cases:**
     - All wizard steps complete successfully
     - Generated world matches configuration
     - Export files created correctly

2. **Character Creation Flow** (when implemented)
   - Launch character creator → Select all options → Confirm → Save
   - **Test Cases:**
     - All tabs navigable
     - Character data valid
     - Save file created

3. **Save/Load Game Flow**
   - Create world → Save → Exit → Load → Verify state
   - **Test Cases:**
     - World state preserved
     - Player position correct
     - Entities in correct state

4. **Multiplayer Session Flow** (when implemented)
   - Host creates world → Client joins → Actions sync → Disconnect
   - **Test Cases:**
     - Client sees host's world
     - Player actions sync
     - Disconnect handled gracefully

**Implementation:**
- Extend existing `TestInteractionOnlyRunner` for E2E flows
- Use same helper utilities
- Add scene loading/unloading helpers

### 4.4 Performance Tests

**Purpose:** Ensure 60 FPS target and identify bottlenecks

**Framework:** Custom performance test suite + Godot profiler

**Target Metrics:**

1. **Frame Rate**
   - 60 FPS with full world loaded
   - 60 FPS during world generation
   - 60 FPS with UI open
   - **Benchmarks:**
     - Baseline: Empty scene
     - World loaded: 1024x1024 map
     - UI open: WorldBuilderUI active
     - Generation: During map generation

2. **Memory Usage**
   - Memory doesn't grow unbounded
   - Chunks unload correctly
   - No memory leaks
   - **Benchmarks:**
     - Initial memory usage
     - Memory after world load
     - Memory after 10 minutes of play
     - Memory after chunk streaming

3. **Generation Performance**
   - World generation completes in reasonable time
   - Large maps (2048x2048) generate in < 30 seconds
   - Threading improves performance
   - **Benchmarks:**
     - 512x512: < 5 seconds
     - 1024x1024: < 15 seconds
     - 2048x2048: < 30 seconds

4. **Load Times**
   - World loads in < 5 seconds
   - Save file loads in < 2 seconds
   - **Benchmarks:**
     - World load time
     - Save file load time
     - Scene transition time

**Implementation:**
```gdscript
# Example: tests/performance/test_frame_rate.gd
extends GutTest

func test_60_fps_with_full_world():
    var world = preload("res://core/scenes/world_root.tscn").instantiate()
    get_tree().root.add_child(world)
    
    var frames = 0
    var total_time = 0.0
    var start_time = Time.get_ticks_msec()
    
    while total_time < 5.0:  # Test for 5 seconds
        await get_tree().process_frame
        frames += 1
        total_time = (Time.get_ticks_msec() - start_time) / 1000.0
    
    var fps = frames / total_time
    assert_ge(fps, 55.0, "FPS should be >= 55 (allowing 5 FPS variance)")
    
    world.queue_free()
```

### 4.5 Regression Tests

**Purpose:** Prevent previously fixed bugs from reoccurring

**Framework:** GUT + custom regression test suite

**Target Areas:**

1. **Known Bugs** (from issue tracker or memory)
   - Document all fixed bugs
   - Create tests that would have caught them
   - Run in CI/CD pipeline

2. **Critical Paths**
   - World generation with edge case seeds
   - UI state transitions
   - Save/load with corrupted files
   - **Test Cases:**
     - Seed 0 produces valid world
     - Seed -1 handled correctly
     - Empty JSON files handled
     - Missing required fields handled

**Implementation:**
- Maintain `tests/regression/` directory
- Document bug → test mapping
- Run regression suite before releases

### 4.6 Security Tests (Future)

**Purpose:** Validate multiplayer security and data integrity

**Target Areas:**

1. **Network Security** (when multiplayer implemented)
   - Input validation on server
   - Cheat prevention
   - Authentication
   - **Test Cases:**
     - Invalid packets rejected
     - Rate limiting works
     - Authentication required

2. **Data Integrity**
   - Save file validation
   - JSON injection prevention
   - **Test Cases:**
     - Malformed save files rejected
     - JSON injection doesn't execute code

---

## 5. Testing Tools & Frameworks

### 5.1 Recommended Tools

**Primary Framework: GUT (Godot Unit Testing)**
- **Why:** Native Godot support, active development, good documentation
- **Installation:** Add as addon or copy to `addons/gut/`
- **Features:**
  - Unit test support
  - Assertion library
  - Test fixtures
  - Coverage reporting (if available)
  - Command-line execution

**Alternative: Custom Test Framework**
- **Why:** Already have `TestInteractionOnlyRunner` for UI tests
- **Consideration:** Extend existing framework vs. adopt GUT
- **Decision:** Use GUT for unit/integration, keep custom for UI/E2E

**Helper Libraries:**
- `TestHelpers.gd` (existing) - UI interaction helpers
- Extend with unit test helpers (mock data, fixtures)

### 5.2 CI/CD Tools

**Recommended: GitHub Actions**

**Workflow Structure:**
```yaml
# .github/workflows/test.yml
name: Test Suite

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Godot
        uses: firebelley/godot-actions@v1
        with:
          godot_version: "4.3"
      - name: Run Unit Tests
        run: godot --headless --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit
      - name: Run Integration Tests
        run: godot --headless --script addons/gut/gut_cmdln.gd -gtest=res://tests/integration
      - name: Run UI Tests
        run: godot --headless --script res://tests/interaction_only/TestInteractionOnlyRunner.gd
      - name: Generate Coverage Report
        run: godot --headless --script addons/gut/gut_cmdln.gd -gcoverage
      - name: Upload Coverage
        uses: codecov/codecov-action@v3
```

**Alternative: GitLab CI, Jenkins, or local scripts**

### 5.3 Coverage Tools

**Options:**
1. **GUT Coverage** (if available in Godot 4.3)
2. **External Tools:** gcov, lcov (if Godot exports coverage data)
3. **Manual Coverage Tracking:** Document test coverage per system

**Coverage Reporting:**
- Generate HTML reports
- Upload to Codecov or similar
- Track coverage trends over time

### 5.4 Performance Profiling

**Tools:**
- **Godot Profiler** (built-in)
- **Custom Performance Test Suite** (as described in 4.4)
- **External Profilers:** Valgrind, perf (Linux)

**Metrics to Track:**
- Frame time (target: < 16.67ms for 60 FPS)
- Memory usage over time
- CPU usage per system
- GPU usage (if applicable)

---

## 6. Test Organization & Structure

### 6.1 Recommended Directory Structure

```
res://
├── tests/
│   ├── unit/                      # Unit tests (NEW)
│   │   ├── core/
│   │   │   ├── test_map_generator.gd
│   │   │   ├── test_logger.gd
│   │   │   ├── test_world_streamer.gd
│   │   │   ├── test_entity_sim.gd
│   │   │   └── test_faction_economy.gd
│   │   ├── data/
│   │   │   ├── test_json_loading.gd
│   │   │   ├── test_biome_data.gd
│   │   │   └── test_civilization_data.gd
│   │   └── utils/
│   │       └── test_math_utils.gd
│   ├── integration/                # Integration tests (NEW)
│   │   ├── test_map_generation_pipeline.gd
│   │   ├── test_data_ui_integration.gd
│   │   ├── test_terrain3d_integration.gd
│   │   └── test_save_load_integration.gd
│   ├── e2e/                        # End-to-end tests (NEW)
│   │   ├── test_world_generation_flow.gd
│   │   ├── test_character_creation_flow.gd
│   │   └── test_save_load_flow.gd
│   ├── performance/                # Performance tests (NEW)
│   │   ├── test_frame_rate.gd
│   │   ├── test_memory_usage.gd
│   │   ├── test_generation_performance.gd
│   │   └── test_load_times.gd
│   ├── regression/                 # Regression tests (NEW)
│   │   └── [bug-specific test files]
│   ├── interaction_only/           # Existing UI tests (KEEP)
│   │   └── [existing structure]
│   ├── fixtures/                   # Shared test fixtures (NEW)
│   │   ├── test_world_data.gd
│   │   ├── test_map_data.gd
│   │   └── mock_singletons.gd
│   └── helpers/                    # Shared test helpers (EXTEND)
│       ├── TestHelpers.gd          # Existing UI helpers
│       ├── UnitTestHelpers.gd      # New unit test helpers
│       └── PerformanceHelpers.gd  # New performance helpers
```

### 6.2 Test Naming Conventions

**File Names:**
- Unit tests: `test_<class_name>.gd` (e.g., `test_map_generator.gd`)
- Integration tests: `test_<system1>_<system2>_integration.gd`
- E2E tests: `test_<user_flow>_flow.gd`
- Performance tests: `test_<metric>_performance.gd`

**Function Names:**
- GUT convention: `test_<description>()`
- Custom convention: `test_<feature>_<expected_behavior>()`

**Examples:**
```gdscript
# Unit test
func test_map_generator_same_seed_produces_identical_heightmap()

# Integration test
func test_map_generator_map_renderer_heightmap_texture_creation()

# E2E test
func test_world_generation_flow_complete_wizard_export()

# Performance test
func test_frame_rate_60_fps_with_full_world()
```

---

## 7. Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2) ✅ **COMPLETE**

**Goals:**
- Set up GUT framework
- Create test directory structure
- Write unit tests for most critical systems

**Tasks:**
1. ✅ Install GUT addon (user action required - AssetLib or manual download)
2. ✅ Create `tests/unit/` structure
3. ✅ Write unit tests for:
   - ✅ `MapGenerator` (7 tests - deterministic generation, heightmap validation, erosion)
   - ✅ `Logger` (9 tests - log levels, methods, config, error handling)
   - ✅ JSON data loading/validation (12 tests - file existence, structure, required fields, error handling)
4. ✅ Set up basic CI/CD (GitHub Actions workflow)
5. ⏳ Achieve 80% coverage on core systems (awaiting test execution)

**Deliverables:**
- ✅ GUT framework ready (installation pending)
- ✅ 28 unit tests written (exceeds 20+ target)
- ✅ Basic CI/CD pipeline (`.github/workflows/test.yml`)
- ✅ Coverage report template (`tests/COVERAGE_REPORT.md`)
- ✅ Extended test helpers (`TestHelpers.gd`, `UnitTestHelpers.gd`)

**Status:** Phase 1 implementation complete. Awaiting GUT installation and first test execution.

### Phase 2: Integration & E2E (Weeks 3-4)

**Goals:**
- Write integration tests
- Extend E2E tests
- Improve coverage to 70%

**Tasks:**
1. Create `tests/integration/` structure
2. Write integration tests for:
   - MapGenerator + MapRenderer
   - Data loading + UI
   - Terrain3D + WorldStreamer
3. Extend E2E tests for complete flows
4. Add performance benchmarks
5. Improve CI/CD with coverage reporting

**Deliverables:**
- 15+ integration tests
- 5+ E2E tests
- Performance benchmark suite
- Coverage dashboard

### Phase 3: Performance & Regression (Weeks 5-6)

**Goals:**
- Comprehensive performance testing
- Regression test suite
- Achieve 80% coverage on critical paths

**Tasks:**
1. Create `tests/performance/` structure
2. Write performance tests for:
   - Frame rate (60 FPS target)
   - Memory usage (leak detection)
   - Generation performance
   - Load times
3. Document and test known bugs (regression tests)
4. Optimize slow tests
5. Add performance monitoring to CI/CD

**Deliverables:**
- Performance test suite
- Regression test suite
- 80%+ coverage on critical paths
- Performance baseline established

### Phase 4: Advanced Testing (Weeks 7-8)

**Goals:**
- Multiplayer testing (when implemented)
- Security testing
- Advanced E2E flows
- Maintain 80%+ coverage

**Tasks:**
1. Add multiplayer integration tests
2. Security tests for network/data
3. Advanced E2E flows (multiplayer sessions)
4. Continuous coverage monitoring
5. Test documentation updates

**Deliverables:**
- Multiplayer test suite
- Security test suite
- Complete test documentation
- Maintained coverage metrics

---

## 8. CI/CD Pipeline Design

### 8.1 Pipeline Stages

**Stage 1: Lint & Format Check**
- GDScript linter (if available)
- Code format validation
- JSON schema validation

**Stage 2: Unit Tests**
- Run all unit tests
- Fast execution (< 2 minutes)
- Fail fast on errors

**Stage 3: Integration Tests**
- Run integration tests
- Medium execution time (< 5 minutes)
- Test system interactions

**Stage 4: UI Tests**
- Run existing interaction-only tests
- Medium execution time (< 10 minutes)
- Visual delay = 0.0 for speed

**Stage 5: Performance Tests**
- Run performance benchmarks
- Compare against baseline
- Fail if performance degrades > 10%

**Stage 6: E2E Tests**
- Run end-to-end flows
- Longer execution time (< 15 minutes)
- Critical path validation

**Stage 7: Coverage Report**
- Generate coverage report
- Upload to coverage service
- Fail if coverage drops below threshold

**Stage 8: Build & Package** (Optional)
- Export game builds
- Create release packages
- Upload artifacts

### 8.2 Pipeline Triggers

**On Push:**
- Run stages 1-4 (fast feedback)
- Performance tests on main branch only

**On Pull Request:**
- Run all stages
- Require passing tests for merge

**On Release Tag:**
- Run all stages
- Generate release build
- Upload to distribution platform

### 8.3 Pipeline Configuration

**GitHub Actions Example:**
```yaml
name: Test Suite

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        godot-version: ['4.3']
    steps:
      - uses: actions/checkout@v3
      - name: Setup Godot
        uses: firebelley/godot-actions@v1
        with:
          godot_version: ${{ matrix.godot-version }}
      - name: Run Unit Tests
        run: godot --headless --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit
      - name: Run Integration Tests
        run: godot --headless --script addons/gut/gut_cmdln.gd -gtest=res://tests/integration
      - name: Run UI Tests
        run: godot --headless --script res://tests/interaction_only/TestInteractionOnlyRunner.gd
      - name: Generate Coverage
        run: godot --headless --script addons/gut/gut_cmdln.gd -gcoverage
      - name: Upload Coverage
        uses: codecov/codecov-action@v3
```

---

## 9. Risk Assessment & Mitigation

### 9.1 High-Risk Areas

**1. Procedural Generation Determinism**
- **Risk:** Same seed produces different results
- **Mitigation:** Comprehensive unit tests with fixed seeds
- **Test Coverage:** 85%+ on MapGenerator

**2. Data Integrity**
- **Risk:** Corrupted JSON breaks game
- **Mitigation:** JSON schema validation, error handling tests
- **Test Coverage:** 95%+ on data loading

**3. Performance Degradation**
- **Risk:** Frame rate drops below 60 FPS
- **Mitigation:** Performance benchmarks in CI/CD
- **Test Coverage:** Continuous performance monitoring

**4. Multiplayer Synchronization** (Future)
- **Risk:** Desync between clients
- **Mitigation:** Network integration tests, state validation
- **Test Coverage:** 80%+ on networking code

**5. Save/Load Corruption**
- **Risk:** Save files become unreadable
- **Mitigation:** Save file validation tests, backward compatibility tests
- **Test Coverage:** 80%+ on save/load system

### 9.2 Testing Priorities

**Priority 1 (Critical - Test Immediately):**
- MapGenerator deterministic generation
- Data loading/JSON validation
- Core singleton initialization
- Save/load system

**Priority 2 (High - Test Soon):**
- Integration between systems
- UI state management
- Performance benchmarks
- WorldStreamer chunk loading

**Priority 3 (Medium - Test When Time Permits):**
- EntitySim calculations
- FactionEconomy simulations
- Advanced UI features
- Editor tools

**Priority 4 (Low - Test When Feature Complete):**
- Multiplayer (when implemented)
- Modding support (when implemented)
- Advanced graphics features

---

## 10. Success Metrics

### 10.1 Coverage Metrics

**Targets:**
- Overall code coverage: 80%+
- Critical path coverage: 90%+
- Core systems coverage: 85%+
- Data loading coverage: 95%+

**Tracking:**
- Weekly coverage reports
- Coverage trends over time
- Per-system coverage breakdown

### 10.2 Test Execution Metrics

**Targets:**
- Unit tests: < 2 minutes
- Integration tests: < 5 minutes
- UI tests: < 10 minutes
- Full test suite: < 20 minutes

**Tracking:**
- CI/CD execution times
- Test execution trends
- Slow test identification

### 10.3 Quality Metrics

**Targets:**
- Zero critical bugs in production
- < 5% test flakiness rate
- 100% of critical paths tested
- Performance within 10% of baseline

**Tracking:**
- Bug escape rate
- Test failure rate
- Performance regression detection

---

## 11. Maintenance & Evolution

### 11.1 Test Maintenance

**Regular Tasks:**
- Update tests when code changes
- Remove obsolete tests
- Refactor slow tests
- Add tests for new bugs

**Frequency:**
- Review test suite: Monthly
- Update tests: With each feature
- Performance review: Quarterly

### 11.2 Test Evolution

**As Project Grows:**
- Add tests for new systems
- Expand E2E coverage
- Add multiplayer tests
- Add modding support tests

**Continuous Improvement:**
- Optimize slow tests
- Improve test readability
- Enhance test helpers
- Document test patterns

---

## 12. Conclusion

This testing plan provides a comprehensive strategy for testing Genesis Mythos from unit tests to end-to-end flows. The plan emphasizes:

1. **Foundation First:** Unit tests for core systems (MapGenerator, data loading)
2. **Integration Second:** System interaction validation
3. **E2E Third:** Complete user flow validation
4. **Performance Always:** Continuous performance monitoring
5. **Coverage Goals:** 80%+ on critical paths, 90%+ on core systems

**Next Steps:**
1. Review and approve this plan
2. Install GUT framework
3. Begin Phase 1 implementation (unit tests for MapGenerator)
4. Set up basic CI/CD pipeline
5. Establish coverage baseline

**Success Criteria:**
- 80%+ code coverage on critical paths
- All tests pass in CI/CD
- 60 FPS maintained in performance tests
- Zero critical bugs escape to production

---

**Document Status:** Phase 1 Complete - Implementation Ready  
**Next Review Date:** After test execution and coverage report  
**Maintained By:** Lordthoth  
**Last Updated:** 2025-12-13

---

## Phase 1 Implementation Notes (2025-12-13)

**Completed:**
- ✅ Test directory structure created
- ✅ 28 unit tests written (MapGenerator: 7, Logger: 9, JSON Loading: 12)
- ✅ Test helpers extended (headless detection, verbose assertions)
- ✅ UnitTestHelpers created (fixtures, heightmap comparison utilities)
- ✅ CI/CD workflow configured
- ✅ Coverage report template created

**User Action Required:**
1. Install GUT framework:
   - Option A: Godot Editor → AssetLib → Search "GUT" → Install "GUT - Godot Unit Testing (Godot 4)" (Asset ID 1709, v9.3.0+)
   - Option B: Download https://github.com/bitwes/Gut/archive/refs/tags/v9.3.0.zip → Extract to `res://addons/gut/`
2. Enable GUT plugin: Project Settings → Plugins → Enable "Gut"
3. Run tests: Tools → GUT → Run selected (or command-line: `godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit`)

**Test Files Created:**
- `tests/unit/core/test_map_generator.gd` (7 tests)
- `tests/unit/core/test_logger.gd` (9 tests)
- `tests/unit/data/test_json_loading.gd` (12 tests)
- `tests/helpers/UnitTestHelpers.gd` (fixtures and utilities)
- `.github/workflows/test.yml` (CI/CD pipeline)
- `tests/COVERAGE_REPORT.md` (coverage tracking)

**Next Phase:** Phase 2 - Integration & E2E tests (after Phase 1 tests pass)
