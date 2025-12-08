# Running Tests

**Last Updated:** 2025-01-06  
**Status:** ✅ **Complete Guide**

This document provides step-by-step instructions for running the test suite in various scenarios.

---

## Quick Start

### Visual Verification (Recommended for First Run)

1. **Open Godot 4.3**
2. **Open the project:** `res://project.godot`
3. **Open test runner scene:** `res://tests/interaction_only/TestInteractionOnlyRunner.tscn`
4. **Press F5** or click "Run Project"
5. **Watch tests execute** with visual delays

---

## Step-by-Step Instructions

### 1. Configure Visual Delay

**File:** `res://tests/interaction_only/TestInteractionOnlyRunner.gd`

**Line 13:**
```gdscript
const VISUAL_DELAY: float = 1.0
```

**Options:**
- `0.0` = No delay (fast, CI-style)
- `0.5` = Half-second delay (quick check)
- `1.0` = One-second delay (default, comfortable)
- `2.0+` = Longer delays (detailed inspection)

**Note:** Some tests use `VISUAL_DELAY * 1.5` or `VISUAL_DELAY * 2.0` for generation operations.

---

### 2. Run with 0.0 Delay (CI-Style)

**Use Case:** Fast automated runs, CI/CD pipelines

**Steps:**
1. Set `VISUAL_DELAY = 0.0` in `TestInteractionOnlyRunner.gd`
2. Run via command line:
   ```bash
   godot --headless --script res://tests/interaction_only/TestInteractionOnlyRunner.tscn
   ```
3. Check output for pass/fail results

**Expected Time:** 10-30 seconds (depending on system)

---

### 3. Run with 1.0+ Delay (Visual Verification)

**Use Case:** Visual confirmation, debugging, demonstration

**Steps:**
1. Set `VISUAL_DELAY = 1.0` (or higher) in `TestInteractionOnlyRunner.gd`
2. Open `res://tests/interaction_only/TestInteractionOnlyRunner.tscn` in Godot
3. Press F5 or click "Run Project"
4. Watch tests execute with visual delays

**Expected Time:** 5-15 minutes (depending on delay and test count)

---

### 4. Using Godot MCP

**Use Case:** Automated testing via MCP server

**Commands:**
```bash
# Run project (will execute tests automatically)
mcp_user-godot_run_project --projectPath /path/to/project

# Get debug output
mcp_user-godot_get_debug_output

# Stop project
mcp_user-godot_stop_project
```

**Note:** Tests run automatically when `TestInteractionOnlyRunner.tscn` is the main scene.

---

## Adding a New UI Control

When adding a new UI control, follow these steps to automatically get test coverage:

### Step 1: Identify the Test File

Find the appropriate test file based on the control's location:

- **World Generation:**
  - Seed & Size → `test_seed_size.gd`
  - Terrain → `test_terrain.gd`
  - Climate → `test_climate.gd`
  - Biome → `test_biome.gd`
  - Civilization → `test_civilization.gd`
  - Resources → `test_resources.gd`
  - Fantasy Styles → `test_fantasy_styles.gd`
  - Mesh Spawning → `test_mesh_spawning.gd`

- **Character Creation:**
  - Tab Navigation → `test_tab_navigation.gd`
  - Race → `test_race_tab.gd`
  - Class → `test_class_tab.gd`
  - Background → `test_background_tab.gd`
  - Ability Score → `test_ability_score_tab.gd`
  - Appearance → `test_appearance_tab.gd`
  - Name/Confirm → `test_name_confirm_tab.gd`

### Step 2: Add Test Function

Add a test function to the appropriate test file:

```gdscript
func test_your_new_control() -> Dictionary:
    """Test description"""
    var result := {"name": "your_new_control", "passed": false, "message": ""}
    
    # Load scene
    var scene_path := "res://scenes/YourScene.tscn"
    if not ResourceLoader.exists(scene_path):
        result["message"] = "Scene not found"
        return result
    
    var scene: Node = load(scene_path).instantiate()
    add_child(scene)
    await get_tree().process_frame
    await get_tree().process_frame
    await TestHelpers.wait_visual(visual_delay)
    
    # Find control
    var control := scene.find_child("YourControl", true, false) as YourControlType
    if not control:
        result["message"] = "Control not found"
        scene.queue_free()
        return result
    
    # Test interaction
    TestHelpers.log_step("Testing your control")
    TestHelpers.simulate_your_interaction(control, value)
    await TestHelpers.wait_visual(visual_delay)
    await get_tree().process_frame
    
    # Verify result
    result["passed"] = true
    result["message"] = "Your control works"
    
    scene.queue_free()
    return result
```

### Step 3: Use TestHelpers

Use appropriate TestHelpers utilities:

- **Button:** `TestHelpers.simulate_button_click(button)`
- **Slider:** `TestHelpers.simulate_slider_drag(slider, value)`
- **Text Input:** `TestHelpers.simulate_text_input(line_edit, text)`
- **Option Button:** `TestHelpers.simulate_option_selection(option_button, index)`
- **Checkbox:** `TestHelpers.simulate_checkbox_toggle(checkbox, checked)`
- **SpinBox:** `TestHelpers.simulate_spinbox_change(spinbox, value)`
- **Wait:** `TestHelpers.wait_visual(delay)`

### Step 4: Update Documentation

Update these files:

1. **TEST_COVERAGE_MATRIX.md** - Add control to matrix
2. **README.md** - Update coverage status if needed
3. **This file (RUNNING_TESTS.md)** - Add example if needed

---

## Troubleshooting

### Common Failures

#### 1. "Scene not found"

**Symptoms:**
```
[FAIL] Scene not found
```

**Causes:**
- Scene path changed
- Scene doesn't exist
- Wrong path in test file

**Solutions:**
- Verify scene path in test file matches actual location
- Check scene exists in project
- Use `ResourceLoader.exists()` to verify

---

#### 2. "Control not found"

**Symptoms:**
```
[FAIL] Control not found
```

**Causes:**
- Control name changed
- Node structure changed
- Control not accessible

**Solutions:**
- Use `find_child()` with wildcards: `"*Name*"`
- Check node structure in scene
- Verify control is accessible (not hidden/disabled)

---

#### 3. "Test passed but UI didn't update"

**Symptoms:**
- Test passes but UI doesn't visually update

**Causes:**
- Missing `await get_tree().process_frame`
- Missing `await TestHelpers.wait_visual(delay)`
- UI update happens asynchronously

**Solutions:**
- Add `await get_tree().process_frame` after each interaction
- Add `await TestHelpers.wait_visual(visual_delay)` for visual updates
- Increase `VISUAL_DELAY` if needed

---

#### 4. "Generation didn't complete"

**Symptoms:**
- Mesh generation tests fail
- World generation incomplete

**Causes:**
- `VISUAL_DELAY` too short
- Generation takes longer than expected
- Threading issues

**Solutions:**
- Use `VISUAL_DELAY * 2.0` or `VISUAL_DELAY * 3.0` for generation tests
- Add additional `await get_tree().process_frame` calls
- Check generation signals are connected

---

#### 5. "Signal not received"

**Symptoms:**
- Signal-based tests fail
- Signals not emitted

**Causes:**
- Signal not connected
- Generation didn't trigger
- Signal name changed

**Solutions:**
- Verify signal connection in scene
- Check signal is emitted during generation
- Verify signal name matches test

---

#### 6. "Test hangs/freezes"

**Symptoms:**
- Test never completes
- Godot freezes

**Causes:**
- Infinite loop in test
- Missing `await` statements
- Deadlock in threading

**Solutions:**
- Check for infinite loops
- Ensure all async operations use `await`
- Verify threading code doesn't deadlock
- Add timeouts if needed

---

### Debug Tips

1. **Enable Verbose Logging:**
   - Check `TestHelpers.log_step()` calls
   - Look for debug output in console

2. **Increase Visual Delay:**
   - Set `VISUAL_DELAY = 2.0` or higher
   - Watch tests execute slowly

3. **Test Individual Functions:**
   - Comment out other tests
   - Run single test function

4. **Check Scene Structure:**
   - Open scene in Godot editor
   - Verify node names match test expectations

5. **Use Breakpoints:**
   - Set breakpoints in test functions
   - Step through execution

---

## Test Execution Flow

1. **Test Runner Starts** → `TestInteractionOnlyRunner._ready()`
2. **Setup Debug Overlay** → `_setup_debug_overlay()`
3. **Start Tests** → `_start_tests()`
4. **Run Test Suites:**
   - World Generation Tests (9 files)
   - Character Creation Tests (7 files)
   - Preview Panel Tests (1 file)
   - Validation & Edge Case Tests (1 file)
   - Visual Feedback Tests (1 file)
5. **Log Results** → Final summary with pass/fail counts
6. **Display Coverage** → Coverage statistics by category

---

## Expected Output

### Successful Run

```
╔═══════════════════════════════════════════════════════════
║ Interaction-Only Test Suite STARTED
║ Visual Delay: 1.0 seconds
╚═══════════════════════════════════════════════════════════

=== WORLD GENERATION TESTS ===
[World Generation] Running 9 test files...

  → Running: test_seed_spinbox_change
    [PASS] Seed spinbox changes work

  → Running: test_fresh_seed_button
    [PASS] Fresh seed button works

...

=== CHARACTER CREATION TESTS ===
[Character Creation] Running 7 test files...

  → Running: test_tab_button_clicks
    [PASS] Tab button clicks work

...

╔═══════════════════════════════════════════════════════════
║ FINAL RESULTS
║ PASSED: 100
║ FAILED: 0
║ TOTAL: 100
║ COVERAGE: 100.0%
╚═══════════════════════════════════════════════════════════

=== COVERAGE BY CATEGORY ===
  World_gen: 24/24 (100.0%)
  Char_creation: 46/46 (100.0%)
  Preview: 3/3 (100.0%)
  Validation: 8/8 (100.0%)
  Visual: 5/5 (100.0%)

All interaction-only paths tested!
```

---

## Related Documentation

- **[README.md](./README.md)** - Test suite overview
- **[TEST_COVERAGE_MATRIX.md](./TEST_COVERAGE_MATRIX.md)** - Complete coverage matrix
- **[CHANGELOG.md](./CHANGELOG.md)** - Test suite history

---

**Maintained by:** Lordthoth  
**Last Audit:** 2025-01-06
