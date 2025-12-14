# Testing Directory - Genesis Mythos

**Last Updated:** 2025-12-13  
**Phase:** Phase 1 Complete - Foundation

---

## Directory Structure

```
tests/
├── unit/                    # Unit tests (isolated function/class tests)
│   ├── core/               # Core system tests
│   │   ├── test_map_generator.gd
│   │   └── test_logger.gd
│   ├── data/               # Data loading tests
│   │   └── test_json_loading.gd
│   └── utils/              # Utility tests (future)
├── integration/            # Integration tests (system interactions)
├── e2e/                    # End-to-end tests (complete user flows)
├── performance/            # Performance benchmarks
├── regression/             # Regression tests (prevent bug recurrence)
├── interaction_only/       # Existing UI interaction tests
│   ├── TestInteractionOnlyRunner.gd
│   ├── helpers/
│   │   └── TestHelpers.gd
│   └── fixtures/
├── helpers/               # Shared test helpers
│   └── UnitTestHelpers.gd
└── fixtures/               # Shared test fixtures
```

---

## Running Tests

### Prerequisites

1. **Install GUT Framework:**
   - Godot Editor → AssetLib → Search "GUT" → Install "GUT - Godot Unit Testing (Godot 4)" (Asset ID 1709, v9.3.0+)
   - Or download: https://github.com/bitwes/Gut/archive/refs/tags/v9.3.0.zip
   - Extract to `res://addons/gut/`

2. **Enable GUT Plugin:**
   - Project Settings → Plugins → Enable "Gut"

### Manual Execution (Visual)

1. Open Godot Editor
2. Tools → GUT → Run selected
3. Select test directory (e.g., `res://tests/unit`)
4. View results in GUT panel

### Automated Execution (CI/Headless)

```bash
# Run all unit tests
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit

# Run specific test file
godot --headless --script addons/gut/gut_cmdln.gd -gtest=res://tests/unit/core/test_map_generator.gd -gexit

# Run with coverage (if available)
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gcoverage
```

### UI Tests (Existing)

```bash
# Run interaction-only UI tests
godot --headless --script res://tests/interaction_only/TestInteractionOnlyRunner.gd
```

---

## Test Coverage

See `COVERAGE_REPORT.md` for current coverage status.

**Phase 1 Targets:**
- MapGenerator: 85%+ (7 tests written)
- Logger: 80%+ (9 tests written)
- JSON Loading: 95%+ (12 tests written)

---

## Writing New Tests

### Unit Test Template

```gdscript
# ╔═══════════════════════════════════════════════════════════
# ║ test_my_class.gd
# ║ Desc: Unit tests for MyClass
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends GutTest

var test_instance: MyClass

func before_each() -> void:
	"""Setup test fixtures."""
	test_instance = MyClass.new()

func after_each() -> void:
	"""Cleanup."""
	if test_instance:
		test_instance = null

func test_my_feature() -> void:
	"""Test description."""
	var result = test_instance.my_method()
	assert_eq(result, expected_value, "FAIL: Expected [desc], got [actual]. Context: [inputs]. Why: [reason]. Hint: [tip]")
```

### Verbose Assertions

All assertions should include detailed failure messages:
- **Expected:** What should happen
- **Got:** What actually happened
- **Context:** Input parameters, state
- **Why:** Business reason for the test
- **Hint:** Debugging tip

---

## CI/CD

Tests run automatically on push/PR via GitHub Actions (`.github/workflows/test.yml`).

---

## Related Documentation

- [Testing Plan Summary](../docs/testing/TESTING_PLAN_SUMMARY.md)
- [Coverage Report](COVERAGE_REPORT.md)
- [Existing UI Tests](interaction_only/README.md)
