# Stat Buy System - Total Spent Calculation Bug Report

## Executive Summary

**Bug:** Clicking to increase a stat twice causes `total_spent` to increase by 3 instead of 2.

**Root Cause:** The cost table in `point_buy.json` stores CUMULATIVE costs (total cost from base 8 to reach each score), but `get_cost_to_increase()` treats these as the cost to pay when increasing, leading to over-deduction.

**Example:** 
- Start: STR = 8 (cost 0)
- After first +1: STR = 9, pays 1 point (correct)
- After second +1: STR = 10, pays 2 points (WRONG - should pay only 1 more point)

The second increase should deduct the DIFFERENCE between cumulative costs (2 - 1 = 1), not the full cumulative cost (2).

---

## 1. Cost Calculation Analysis

### 1.1 Cost Table Structure (`point_buy.json`)

```json
{
  "starting_points": 27,
  "min_base_score": 8,
  "max_base_score": 15,
  "costs": {
    "8": 0,
    "9": 1,
    "10": 2,
    "11": 3,
    "12": 4,
    "13": 5,
    "14": 7,
    "15": 9
  }
}
```

**Interpretation:** The values represent CUMULATIVE costs from the base score (8) to reach each score level.

- Score 8: 0 points (base, no cost)
- Score 9: 1 point (total cost from 8 to 9)
- Score 10: 2 points (total cost from 8 to 10)
- Score 11: 3 points (total cost from 8 to 11)

### 1.2 Current Cost Calculation Functions

#### `PlayerData.get_cost_to_increase(current_score: int) -> int`
**Location:** `scripts/singletons/PlayerData.gd:105-123`

```gdscript
func get_cost_to_increase(current_score: int) -> int:
    var next_score: int = current_score + 1
    if cost_table.has(str(next_score)):
        return cost_table.get(str(next_score), 999)
```

**Problem:** Returns the CUMULATIVE cost of the target score, not the INCREMENTAL cost.

- If current = 8, returns cost for 9 = 1 ✓ (correct)
- If current = 9, returns cost for 10 = 2 ✗ (should return 2 - 1 = 1)

#### `AbilityScoreTab._get_cost_for_score(score: int) -> int`
**Location:** `scripts/character_creation/tabs/AbilityScoreTab.gd:167-178`

```gdscript
func _get_cost_for_score(score: int) -> int:
    if cost_table.has(str(score)):
        return cost_table.get(str(score), 0)
```

**Usage:** Used in `_recalculate_points()` to compute total spent by summing cumulative costs for all abilities. This is CORRECT for recalculation.

---

## 2. Total Spent Calculation Flow

### 2.1 When Increasing a Stat (Incremental)

**Flow:**
1. User clicks + button in `AbilityScoreEntry`
2. `_on_plus_pressed()` emits `value_changed(ability_key, 1)`
3. `AbilityScoreTab._on_entry_value_changed()` calls `PlayerData.increase_ability_score(ability_key)`
4. `PlayerData.increase_ability_score()`:
   - Gets current score (e.g., 8)
   - Calls `get_cost_to_increase(8)` → returns 1 ✓
   - Deducts 1 from `points_remaining`
   - Updates score to 9
5. Second click repeats:
   - Gets current score (9)
   - Calls `get_cost_to_increase(9)` → returns 2 ✗ (BUG HERE)
   - Deducts 2 from `points_remaining` (should deduct only 1)

**Bug Location:** `PlayerData.gd:151` - Uses cumulative cost instead of marginal cost.

### 2.2 When Displaying Total Spent (Recalculation)

**Flow:**
1. `AbilityScoreTab._update_preview()` is called
2. Calculates: `total_spent = starting_points - remaining_points`
3. OR uses `_recalculate_points()` which sums cumulative costs for all abilities

**Location:** `AbilityScoreTab.gd:187` and `AbilityScoreTab.gd:317-330`

Both methods are correct because they work with cumulative costs.

### 2.3 Signal Chain Analysis

**Signals:**
- `PlayerData.increase_ability_score()` emits `stats_changed` and `points_changed`
- `AbilityScoreTab._on_stats_changed()` calls `_refresh_all()` → `_update_preview()`
- `AbilityScoreTab._on_points_changed()` calls `_update_preview()` and `_refresh_all()`

**Potential Double-Update:** `_on_points_changed()` calls both `_update_preview()` and `_refresh_all()`, which calls `_update_preview()` again. This could cause double calculations, but it's not the root cause of the bug.

---

## 3. Exact Cost Curve/Formula

### 3.1 Cost Table Values

| Score | Cumulative Cost | Marginal Cost (8→9, 9→10, etc.) |
|-------|----------------|----------------------------------|
| 8     | 0              | N/A (base)                       |
| 9     | 1              | 1 (0→1)                          |
| 10    | 2              | 1 (1→2)                          |
| 11    | 3              | 1 (2→3)                          |
| 12    | 4              | 1 (3→4)                          |
| 13    | 5              | 1 (4→5)                          |
| 14    | 7              | 2 (5→7)                          |
| 15    | 9              | 2 (7→9)                          |

**Formula:** The cost table defines cumulative costs. To get marginal cost:
```
marginal_cost = cumulative_cost[next] - cumulative_cost[current]
```

### 3.2 Expected Behavior

**Scenario:** User clicks + twice on STR starting from 8

1. First click: 8 → 9
   - Marginal cost: 1 - 0 = 1
   - Points remaining: 27 - 1 = 26
   - Total spent: 1

2. Second click: 9 → 10
   - Marginal cost: 2 - 1 = 1
   - Points remaining: 26 - 1 = 25
   - Total spent: 2 (1 + 1)

**Actual Behavior (BUGGY):**

1. First click: 8 → 9
   - Deducts: 1 ✓
   - Points remaining: 26 ✓
   - Total spent: 1 ✓

2. Second click: 9 → 10
   - Deducts: 2 ✗ (should be 1)
   - Points remaining: 24 ✗ (should be 25)
   - Total spent: 3 ✗ (should be 2)

---

## 4. Bug Reproduction Steps

1. Start character creation
2. Navigate to Ability Score tab
3. All stats should be at 8 (base)
4. Click + button on STR twice
5. **Expected:** Total spent = 2, Points remaining = 25
6. **Actual:** Total spent = 3, Points remaining = 24

---

## 5. Root Cause Analysis

### 5.1 The Bug

**File:** `scripts/singletons/PlayerData.gd`
**Function:** `get_cost_to_increase(current_score: int)`
**Line:** 120-122

```gdscript
var next_score: int = current_score + 1
if cost_table.has(str(next_score)):
    return cost_table.get(str(next_score), 999)
```

**Issue:** Returns the cumulative cost of `next_score` instead of the marginal cost (difference between cumulative costs).

### 5.2 Why It Happens

The cost table stores cumulative costs, but `get_cost_to_increase()` doesn't account for the current score's cost when calculating what to deduct. It assumes each increase should pay the full cumulative cost to reach the target score.

### 5.3 Side Effects

- Points are over-deducted on every increase except the first
- `total_spent` becomes incorrect (over-counted)
- Users run out of points prematurely
- The recalculation method (`_recalculate_points()`) works correctly but can't fix the already-incorrect `points_remaining` if called after increases

---

## 6. Proposed Fix

### 6.1 Fix Strategy

Calculate marginal cost by finding the difference between cumulative costs:

```gdscript
func get_cost_to_increase(current_score: int) -> int:
    """Get cost to increase ability score from current value"""
    var cost_table: Dictionary = {}
    if GameData.point_buy_data.has("costs"):
        cost_table = GameData.point_buy_data.get("costs", {})
    elif GameData.point_buy_data.has("cost_table"):
        cost_table = GameData.point_buy_data.get("cost_table", {})
    
    if cost_table.is_empty():
        return 999
    
    if current_score >= get_max_score():
        return 999
    
    var next_score: int = current_score + 1
    if not cost_table.has(str(next_score)):
        return 999
    
    # Get cumulative cost for next score
    var next_cost: int = cost_table.get(str(next_score), 999)
    
    # Get cumulative cost for current score (default 0 for base score)
    var current_cost: int = cost_table.get(str(current_score), 0)
    
    # Return marginal cost (difference)
    return next_cost - current_cost
```

### 6.2 Fix for Decrease Function

Similarly, `get_cost_to_decrease()` should return the difference:

```gdscript
func get_cost_to_decrease(current_score: int) -> int:
    """Get points refunded when decreasing ability score"""
    var cost_table: Dictionary = {}
    if GameData.point_buy_data.has("costs"):
        cost_table = GameData.point_buy_data.get("costs", {})
    elif GameData.point_buy_data.has("cost_table"):
        cost_table = GameData.point_buy_data.get("cost_table", {})
    
    if cost_table.is_empty():
        return 0
    
    if current_score <= get_min_score():
        return 0
    
    # Get cumulative cost for current score
    var current_cost: int = cost_table.get(str(current_score), 0)
    
    # Get cumulative cost for previous score (default 0 for base)
    var prev_score: int = current_score - 1
    var prev_cost: int = cost_table.get(str(prev_score), 0)
    
    # Return marginal cost that was paid (difference)
    return current_cost - prev_cost
```

### 6.3 Testing Plan

1. Start with all stats at 8 (27 points remaining)
2. Increase STR from 8 → 9: Should deduct 1 point (26 remaining)
3. Increase STR from 9 → 10: Should deduct 1 point (25 remaining)
4. Increase STR from 10 → 11: Should deduct 1 point (24 remaining)
5. Increase STR from 13 → 14: Should deduct 2 points (7-5=2)
6. Increase STR from 14 → 15: Should deduct 2 points (9-7=2)
7. Decrease STR from 15 → 14: Should refund 2 points
8. Verify total_spent = starting_points - remaining_points at all times

---

## 7. Code Locations Summary

### 7.1 Key Files

1. **`data/point_buy.json`** - Cost table configuration
2. **`scripts/singletons/PlayerData.gd`** - Core calculation logic (BUG HERE)
   - `get_cost_to_increase()` - Line 105-123 (NEEDS FIX)
   - `get_cost_to_decrease()` - Line 125-142 (NEEDS FIX)
   - `increase_ability_score()` - Line 144-159 (Uses buggy function)
   - `decrease_ability_score()` - Line 161-173 (Uses buggy function)
3. **`scripts/character_creation/tabs/AbilityScoreTab.gd`** - UI display
   - `_update_preview()` - Line 180-233 (Correct - uses difference method)
   - `_recalculate_points()` - Line 317-330 (Correct - sums cumulative costs)
   - `_get_cost_for_score()` - Line 167-178 (Correct - returns cumulative)
4. **`scripts/character_creation/tabs/components/AbilityScoreEntry.gd`** - UI component
   - `_on_plus_pressed()` - Line 136-137 (Triggers increase)

### 7.2 Signal Flow

```
AbilityScoreEntry._on_plus_pressed()
  → emits value_changed(ability_key, 1)
  → AbilityScoreTab._on_entry_value_changed()
    → PlayerData.increase_ability_score()
      → emits stats_changed
      → emits points_changed
        → AbilityScoreTab._on_stats_changed() → _refresh_all() → _update_preview()
        → AbilityScoreTab._on_points_changed() → _update_preview() + _refresh_all()
```

---

## 8. Conclusion

The bug is caused by treating cumulative cost table values as marginal costs during incremental increases/decreases. The fix requires calculating the difference between cumulative costs to get the true marginal cost for each operation.

**Impact:** High - Affects core gameplay mechanic, prevents proper point-buy usage.

**Fix Complexity:** Low - Single function modification with clear logic.

**Testing Required:** Yes - Verify all cost transitions (8→9, 9→10, 13→14, 14→15, etc.)

---

---

## 9. Fix Implementation Summary

### 9.1 Changes Made

**File:** `scripts/singletons/PlayerData.gd`

**Functions Fixed:**
1. `get_cost_to_increase(current_score: int)` - Lines 105-123
   - **Before:** Returned cumulative cost of next score directly
   - **After:** Calculates marginal cost as difference: `next_cost - current_cost`
   
2. `get_cost_to_decrease(current_score: int)` - Lines 125-142
   - **Before:** Returned cumulative cost of current score directly
   - **After:** Calculates marginal cost as difference: `current_cost - prev_cost`

### 9.2 Testing Status

✅ **Code Changes:** Implemented and saved
✅ **Syntax Check:** No linter errors
✅ **Project Launch:** Successful (no runtime errors on startup)

⚠️ **Manual Testing Required:** 
- Navigate to Ability Score tab
- Increase a stat from 8→9→10 and verify:
  - First increase: deducts 1 point (26 remaining)
  - Second increase: deducts 1 point (25 remaining)
  - Total spent: 2 points (not 3)

### 9.3 Expected Behavior After Fix

**Scenario:** Increase STR from 8 to 10 (two clicks)

1. Click 1: 8 → 9
   - `get_cost_to_increase(8)` = cost[9] - cost[8] = 1 - 0 = **1** ✓
   - Points deducted: 1
   - Remaining: 26

2. Click 2: 9 → 10
   - `get_cost_to_increase(9)` = cost[10] - cost[9] = 2 - 1 = **1** ✓
   - Points deducted: 1
   - Remaining: 25

**Total spent:** 1 + 1 = **2 points** (correct!)

### 9.4 Additional Test Cases

- Increase from 13→14: Should deduct 2 points (7-5=2)
- Increase from 14→15: Should deduct 2 points (9-7=2)
- Decrease from 15→14: Should refund 2 points
- Decrease from 10→9: Should refund 1 point (2-1=1)

---

*Report Generated: 2025-01-28*
*Analyzed by: Grok + Cursor AI*
*Fix Implemented: 2025-01-28*
