# UI Sizing and Positioning Audit Report
**Genesis Mythos - Full First Person 3D Virtual Tabletop RPG**  
**Date:** 2025-01-13  
**Godot Version:** 4.5.1

---

## Executive Summary

This audit evaluates UI component sizing and positioning across the Genesis Mythos project, focusing on consistency, adherence to project rules, best practices, and potential issues. The audit covers all UI-related scenes, scripts, and theme usage.

**Overall Assessment:** The project demonstrates good use of anchors and layout containers, with consistent theme application. However, there are numerous hard-coded pixel values that should be replaced with theme constants or configuration values to improve maintainability and responsiveness.

---

## 1. Overview: UI Sizing/Positioning Approach

### Current Approach

The project uses a **hybrid approach** combining:

1. **Anchors and Presets:** Most root UI elements use `anchors_preset = 15` (PRESET_FULL_RECT) for full-screen coverage
2. **Layout Containers:** Heavy use of `VBoxContainer`, `HBoxContainer`, `HSplitContainer`, `MarginContainer`, and `CenterContainer` for responsive layouts
3. **Theme-Driven Styling:** Central theme at `res://themes/bg3_theme.tres` is consistently applied
4. **Custom Minimum Sizes:** Extensive use of `custom_minimum_size` for fixed-width/height constraints
5. **Hard-Coded Offsets:** Many UI elements use fixed pixel offsets (`offset_left`, `offset_top`, etc.)

### Layout Mode Distribution

- **Anchors Mode (layout_mode = 1):** Used for root containers and full-screen elements
- **Container Mode (layout_mode = 2):** Used for child elements within containers
- **Layout Mode 3:** Used for some root Control nodes

---

## 2. Strengths

### ✅ Theme Consistency

- **Central Theme:** All major UI scenes reference `res://themes/bg3_theme.tres`
  - `MainMenu.tscn` ✓
  - `WorldBuilderUI.tscn` ✓
  - `AbilityScoreRow.tscn` ✓
  - `progress_dialog.tscn` ✓

- **Theme Application:** Scripts properly load and apply theme:
  ```gdscript
  # WorldBuilderUI.gd:283-287
  func _apply_theme() -> void:
      var bg3_theme: Theme = load("res://themes/bg3_theme.tres")
      if bg3_theme != null:
          self.theme = bg3_theme
  ```

### ✅ Responsive Root Containers

- **Full-Screen Anchors:** Most root UI elements properly use full-rect anchors:
  ```tscn
  # MainMenu.tscn:8-12
  anchors_preset = 15
  anchor_right = 1.0
  anchor_bottom = 1.0
  ```

- **Container-Based Layouts:** Effective use of layout containers for responsive sizing:
  - `VBoxContainer` with `theme_override_constants/separation` for spacing
  - `HSplitContainer` for resizable panels
  - `CenterContainer` for centered content

### ✅ Typed GDScript

- All scripts use proper type hints (`: Control`, `: Button`, `: Dictionary`, etc.)
- Script headers follow project rules format

### ✅ Documentation

- All public functions have docstrings
- Code is well-commented

---

## 3. Issues

### 🔴 HIGH SEVERITY

#### 3.1 Extensive Hard-Coded Pixel Values

**Location:** Throughout UI scenes and scripts

**Problem:** Hundreds of hard-coded pixel values make the UI brittle and difficult to maintain.

**Examples:**

1. **WorldBuilderUI.tscn:**
   ```tscn
   offset_top = 10.0
   offset_bottom = 50.0
   offset_left = -150.0
   offset_top = -50.0
   offset_right = 150.0
   offset_bottom = -10.0
   ```

2. **WorldBuilderUI.gd:** Over 50 instances of hard-coded `custom_minimum_size`:
   ```gdscript
   # Line 319
   step_button.custom_minimum_size = Vector2(0, 50)
   
   # Line 753
   seed_label.custom_minimum_size = Vector2(150, 0)
   
   # Line 870
   noise_freq_label.custom_minimum_size = Vector2(150, 0)
   ```

3. **AbilityScoreRow.tscn:**
   ```tscn
   custom_minimum_size = Vector2(150, 0)  # NameLabel
   custom_minimum_size = Vector2(40, 0)   # BaseLabel
   custom_minimum_size = Vector2(40, 40)  # Buttons
   ```

4. **Main.tscn:**
   ```tscn
   offset_left = -200.0
   offset_top = -150.0
   offset_right = 200.0
   offset_bottom = 150.0
   custom_minimum_size = Vector2(400, 300)
   ```

**Impact:** 
- UI breaks on different screen resolutions
- Difficult to maintain consistent spacing
- Violates project rule: "No magic numbers → use constants or theme overrides"

**Recommendation:** Create theme constants for common sizes (button heights, label widths, margins) and use them consistently.

---

#### 3.2 Inconsistent Spacing and Sizing

**Location:** Multiple UI components

**Problem:** Similar UI elements use different sizes without clear rationale.

**Examples:**

1. **Button Heights:**
   - `MainMenu.tscn`: `custom_minimum_size = Vector2(0, 120)` (120px)
   - `Main.tscn`: `custom_minimum_size = Vector2(300, 80)` (80px)
   - `WorldBuilderUI.gd:319`: `Vector2(0, 50)` (50px)

2. **Label Widths:**
   - `WorldBuilderUI.gd:753`: `Vector2(150, 0)` (seed label)
   - `WorldBuilderUI.gd:1036`: `Vector2(200, 0)` (seed label in different step)
   - `WorldBuilderUI.gd:2146`: `Vector2(120, 0)` (generic label)

3. **Margins/Offsets:**
   - `WorldBuilderUI.tscn:70-72`: `offset_top = 10.0`, `offset_bottom = 50.0`
   - `progress_dialog.tscn:19-22`: `offset_left = 20.0`, `offset_right = 380.0`

**Impact:** Inconsistent visual appearance, poor user experience

**Recommendation:** Standardize sizes using theme constants:
- `BUTTON_HEIGHT_SMALL = 50`
- `BUTTON_HEIGHT_MEDIUM = 80`
- `BUTTON_HEIGHT_LARGE = 120`
- `LABEL_WIDTH_STANDARD = 150`
- `LABEL_WIDTH_WIDE = 200`

---

#### 3.3 Magic Numbers in Scripts

**Location:** `DebugMenuScaler.gd`, `MapEditor.gd`, `WorldBuilderUI.gd`

**Problem:** Hard-coded values in scripts that should be constants or theme values.

**Examples:**

1. **DebugMenuScaler.gd:**
   ```gdscript
   # Line 9-10
   @export var scale_factor: float = 1.5
   @export var x_offset_pixels: int = -20
   
   # Line 17
   debug_canvas.offset = Vector2(x_offset_pixels, 20)  # Magic number 20
   ```

2. **MapEditor.gd:**
   ```gdscript
   # Line 43-50 - Hard-coded anchor setup
   canvas.anchor_left = 0.5
   canvas.anchor_top = 0.5
   # ... (should use preset)
   ```

3. **WorldBuilderUI.gd:**
   ```gdscript
   # Line 600
   compass_container.position = Vector2(-450, -450)  # Magic numbers
   
   # Line 380
   preview_camera.size = 200.0  # Should be configurable
   ```

**Impact:** Difficult to adjust for different screen sizes or preferences

**Recommendation:** Extract magic numbers to constants or configuration files.

---

### 🟡 MEDIUM SEVERITY

#### 3.4 Inconsistent Anchor Usage

**Location:** Multiple scenes

**Problem:** Some elements use manual anchor setup instead of presets, leading to inconsistency.

**Examples:**

1. **Main.tscn:**
   ```tscn
   # Line 27-35 - Manual anchor setup
   anchors_preset = 8
   anchor_left = 0.5
   anchor_top = 0.5
   anchor_right = 0.5
   anchor_bottom = 0.5
   offset_left = -200.0
   offset_top = -150.0
   offset_right = 200.0
   offset_bottom = 150.0
   ```
   Should use `PRESET_CENTER` with proper sizing.

2. **WorldBuilderUI.tscn:**
   ```tscn
   # Line 64-72 - Manual anchor setup for title
   anchors_preset = 6
   anchor_left = 0.0
   anchor_top = 0.0
   anchor_right = 1.0
   anchor_bottom = 0.0
   offset_top = 10.0
   offset_bottom = 50.0
   ```
   Could use `PRESET_TOP_WIDE` with margin.

**Impact:** More verbose code, potential for errors

**Recommendation:** Prefer anchor presets where possible, document when manual setup is necessary.

---

#### 3.5 Fixed Window Sizes

**Location:** `progress_dialog.tscn`

**Problem:** Dialog windows use fixed pixel sizes instead of responsive sizing.

**Example:**
```tscn
# progress_dialog.tscn:8
size = Vector2i(400, 120)
```

**Impact:** May not scale well on different screen sizes

**Recommendation:** Use minimum size with expand flags, or calculate size based on content.

---

#### 3.6 Viewport Size Hard-Coding

**Location:** `WorldBuilderUI.gd`, `MapMakerModule.gd`

**Problem:** Viewport sizes are hard-coded instead of calculated from container sizes.

**Examples:**

1. **WorldBuilderUI.tscn:**
   ```tscn
   # Line 143
   size = Vector2(1920, 1080)  # Fixed 1080p size
   ```

2. **MapMakerModule.gd:**
   ```gdscript
   # Line 80
   map_viewport.size = Vector2i(1920, 1080)  # Hard-coded
   ```

**Impact:** May not adapt to different screen resolutions

**Recommendation:** Calculate viewport size from parent container size or use resolution-independent scaling.

---

### 🟢 LOW SEVERITY

#### 3.7 Theme Override Inconsistency

**Location:** Various scenes

**Problem:** Some elements use theme overrides while others use hard-coded values for similar properties.

**Examples:**

1. **WorldBuilderUI.tscn:**
   ```tscn
   # Line 75-79 - Theme overrides used
   theme_override_font_sizes/font_size = 32
   theme_override_colors/font_color = Color(1, 0.843137, 0, 1)
   ```

2. **Main.tscn:**
   ```tscn
   # Line 45 - Theme override used
   theme_override_font_sizes/font_size = 48
   ```

3. **MainMenu.tscn:**
   ```tscn
   # Line 39-43 - Theme overrides used
   theme_override_colors/font_color = Color(0.95, 0.85, 0.6, 1)
   theme_override_font_sizes/font_size = 48
   ```

**Impact:** Minor - theme overrides are acceptable, but should be documented

**Recommendation:** Document when theme overrides are intentional design choices vs. temporary workarounds.

---

#### 3.8 Missing Size Flags

**Location:** Some container children

**Problem:** Not all container children explicitly set `size_flags_horizontal` and `size_flags_vertical`.

**Example:**
- `WorldBuilderUI.tscn:103` - `RightSplit` uses `size_flags_horizontal = 3` (good)
- But many child elements don't set size flags explicitly

**Impact:** Minor - Godot defaults may be sufficient, but explicit is better

**Recommendation:** Explicitly set size flags for clarity and maintainability.

---

## 4. Recommendations

### 4.1 Create Theme Constants

**Priority:** HIGH

**Action:** Add constants to `bg3_theme.tres` or create a separate constants file:

```gdscript
# res://scripts/ui/ui_constants.gd
class_name UIConstants

# Button sizes
const BUTTON_HEIGHT_SMALL: int = 50
const BUTTON_HEIGHT_MEDIUM: int = 80
const BUTTON_HEIGHT_LARGE: int = 120

# Label widths
const LABEL_WIDTH_NARROW: int = 80
const LABEL_WIDTH_STANDARD: int = 150
const LABEL_WIDTH_WIDE: int = 200

# Spacing
const MARGIN_SMALL: int = 10
const MARGIN_MEDIUM: int = 20
const MARGIN_LARGE: int = 40

# Icon sizes
const ICON_SIZE_SMALL: int = 32
const ICON_SIZE_MEDIUM: int = 64
const ICON_SIZE_LARGE: int = 128
```

**Usage:**
```gdscript
# Replace:
step_button.custom_minimum_size = Vector2(0, 50)

# With:
step_button.custom_minimum_size = Vector2(0, UIConstants.BUTTON_HEIGHT_SMALL)
```

---

### 4.2 Standardize Button Sizes

**Priority:** HIGH

**Action:** Create a button size system:

1. Define standard button heights in constants
2. Update all buttons to use these constants
3. Document when custom sizes are needed (e.g., special UI elements)

**Files to Update:**
- `scenes/MainMenu.tscn`
- `scenes/Main.tscn`
- `ui/world_builder/WorldBuilderUI.gd` (all step buttons)
- `ui/world_builder/WorldBuilderUI.tscn`

---

### 4.3 Replace Hard-Coded Offsets with Margins

**Priority:** MEDIUM

**Action:** Use `MarginContainer` or theme margin constants instead of hard-coded offsets.

**Example:**

**Before:**
```tscn
offset_left = -150.0
offset_top = -50.0
offset_right = 150.0
offset_bottom = -10.0
```

**After:**
```tscn
# Use MarginContainer or:
margin_left = -150
margin_top = -50
margin_right = 150
margin_bottom = -10
# Or better: use theme constants
```

---

### 4.4 Create Responsive Viewport System

**Priority:** MEDIUM

**Action:** Calculate viewport sizes from container dimensions instead of hard-coding.

**Example:**

**Before:**
```gdscript
map_viewport.size = Vector2i(1920, 1080)
```

**After:**
```gdscript
var container_size: Vector2 = get_viewport().get_visible_rect().size
map_viewport.size = Vector2i(int(container_size.x), int(container_size.y))
```

**Note:** `MapMakerModule.gd:794` already does this correctly - apply pattern elsewhere.

---

### 4.5 Document Theme Override Rationale

**Priority:** LOW

**Action:** Add comments explaining when and why theme overrides are used.

**Example:**
```gdscript
# Title uses larger font for visual hierarchy (design requirement)
theme_override_font_sizes/font_size = 48
```

---

### 4.6 Audit and Standardize Label Widths

**Priority:** MEDIUM

**Action:** Review all label `custom_minimum_size` values and standardize to:
- 80px for value labels
- 150px for standard labels
- 200px for wide labels (long text)

**Files to Update:**
- `ui/world_builder/WorldBuilderUI.gd` (50+ instances)

---

## 5. Compliance Check

### ✅ Project Rules Adherence

| Rule | Status | Notes |
|------|--------|-------|
| Typed GDScript | ✅ PASS | All scripts use proper type hints |
| Script Headers | ✅ PASS | All scripts have correct header format |
| Theme Usage | ⚠️ PARTIAL | Theme is used, but many hard-coded values bypass it |
| No Magic Numbers | ❌ FAIL | Hundreds of hard-coded pixel values found |
| Layout Containers | ✅ PASS | Good use of containers for responsive layouts |
| Anchors | ✅ PASS | Proper use of anchor presets (mostly) |
| Folder Structure | ✅ PASS | All files in correct locations |
| Docstrings | ✅ PASS | All public functions documented |

### ⚠️ Areas Needing Improvement

1. **Magic Numbers:** Extensive use of hard-coded values violates project rules
2. **Theme Constants:** Need to add size constants to theme or separate constants file
3. **Consistency:** Similar UI elements use different sizes without clear rationale

---

## 6. File-by-File Summary

### Scenes

| File | Issues | Severity | Notes |
|------|--------|----------|-------|
| `scenes/MainMenu.tscn` | Hard-coded button height (120px), theme overrides | MEDIUM | Good anchor usage |
| `scenes/Main.tscn` | Hard-coded offsets, button size (80px) | MEDIUM | Manual anchor setup could use preset |
| `scenes/ui/progress_dialog.tscn` | Fixed window size (400x120) | MEDIUM | Should be responsive |
| `ui/world_builder/WorldBuilderUI.tscn` | Multiple hard-coded offsets, fixed viewport size | HIGH | Many magic numbers |
| `ui/components/AbilityScoreRow.tscn` | Hard-coded label/button sizes | MEDIUM | Good theme usage |

### Scripts

| File | Issues | Severity | Notes |
|------|--------|----------|-------|
| `ui/world_builder/WorldBuilderUI.gd` | 50+ hard-coded `custom_minimum_size` values | HIGH | Needs constants refactor |
| `scripts/MapEditor.gd` | Hard-coded anchor setup, magic numbers | MEDIUM | Good overall structure |
| `scripts/core/DebugMenuScaler.gd` | Magic number (20px) in offset | LOW | Minor issue |
| `ui/main_menu/main_menu_controller.gd` | No sizing issues | ✅ PASS | Clean code |
| `ui/components/AbilityScoreRow.gd` | No sizing issues | ✅ PASS | Good theme integration |

---

## 7. Priority Action Items

### Immediate (High Priority)

1. **Create `UIConstants.gd`** with standard sizes
2. **Refactor `WorldBuilderUI.gd`** to use constants (50+ instances)
3. **Standardize button heights** across all scenes
4. **Replace hard-coded offsets** in `WorldBuilderUI.tscn` with margins

### Short Term (Medium Priority)

5. **Audit and standardize label widths** in `WorldBuilderUI.gd`
6. **Make viewport sizes responsive** (calculate from containers)
7. **Replace manual anchor setups** with presets where possible
8. **Make `progress_dialog.tscn` responsive** (remove fixed size)

### Long Term (Low Priority)

9. **Document theme override rationale** with comments
10. **Explicitly set size flags** on all container children
11. **Create UI style guide** documenting standard sizes and spacing

---

## 8. Conclusion

The Genesis Mythos project demonstrates **good foundational practices** with consistent theme usage, proper anchor implementation, and effective use of layout containers. However, **extensive hard-coded pixel values** throughout the codebase violate project rules and create maintenance challenges.

**Key Strengths:**
- ✅ Consistent theme application
- ✅ Good use of layout containers
- ✅ Proper anchor usage (mostly)
- ✅ Well-documented code

**Key Weaknesses:**
- ❌ Hundreds of magic numbers
- ❌ Inconsistent sizing across similar elements
- ❌ Fixed sizes that don't adapt to screen resolution

**Recommended Next Steps:**
1. Create `UIConstants.gd` with standard sizes
2. Refactor `WorldBuilderUI.gd` as highest priority (most instances)
3. Standardize button and label sizes across all UI
4. Replace hard-coded offsets with margin containers or theme constants

With these improvements, the UI will be more maintainable, consistent, and responsive across different screen sizes.

---

**Audit Completed:** 2025-01-13  
**Auditor:** Cursor AI (Auto)  
**Project:** Genesis Mythos - Full First Person 3D Virtual Tabletop RPG  
**Godot Version:** 4.5.1
