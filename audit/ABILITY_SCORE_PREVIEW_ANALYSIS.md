# Ability Score Tab Preview Panel - Logic Flow Analysis

## Overview
The Ability Score tab has a preview panel that displays point-buy costs, not ability scores themselves. This analysis traces the complete logic flow to identify where "999" values might appear.

## Preview Panel Components

### 1. UI Structure (from AbilityScoreTab.tscn)
- `PreviewPanel` (PanelContainer)
  - `PreviewVBox` (VBoxContainer)
    - `TotalSpentLabel` - Shows total points spent
    - `RemainingLabel` - Shows remaining points
    - `SpentBreakdown` (VBoxContainer) - Shows cost breakdown per ability

### 2. Data Sources
- **PlayerData.ability_scores** (Dictionary) - Base ability scores (default: 8 each)
- **point_buy_table** (PointBuyCostTable Resource) - Cost lookup table
- **GameData.abilities** (Dictionary) - Ability metadata (short names, full names)

## Logic Flow Breakdown

### Initialization Flow (AbilityScoreTab._ready())

```
1. _ready() called
   ├─> Load point_buy_table from "res://data/point_buy_costs.tres"
   ├─> _initialize_stats_to_default() - Sets all stats to 8
   ├─> _recalculate_points() - Calculates total points spent
   ├─> _populate_list() - Creates ability entry UI elements
   │   └─> For each ability:
   │       ├─> Instantiate AbilityScoreEntry scene
   │       ├─> entry.setup(ability_key, name, base, racial)
   │       └─> Connect value_changed signal
   └─> _refresh_all() - Updates all displays
       └─> _update_preview() - Updates preview panel
```

### Preview Update Flow (_update_preview())

```
1. _update_preview() called (line 239)
   ├─> Validate UI nodes exist
   ├─> Calculate remaining_points = POINT_BUY_TOTAL - current_points_spent
   ├─> Update TotalSpentLabel: "Total Points Spent: {total_spent}"
   ├─> Update RemainingLabel: "Points Remaining: {remaining} / 27"
   └─> Update SpentBreakdown (lines 279-292):
       └─> For each ability in ABILITY_ORDER:
           ├─> Get base score: PlayerData.ability_scores.get(ability_key, 8)
           ├─> Get cost: get_cost(base)  ⚠️ CAN RETURN 999
           ├─> Get short name: GameData.abilities[ability_key].short
           └─> Create label: "{SHORT}: {cost}"  ⚠️ SHOWS COST, NOT SCORE
```

### Cost Calculation Flow (get_cost())

```
1. get_cost(stat_value) called (line 230)
   ├─> Check if point_buy_table is valid
   │   └─> If invalid → return 999 ⚠️ ERROR CASE 1
   ├─> Call point_buy_table.get_cost(stat_value)
   │   └─> PointBuyCostTable.get_cost() (line 16):
   │       ├─> Check if cost_table.has(stat_value)
   │       │   └─> If yes → return cost_table[stat_value]
   │       └─> If no → return 999 ⚠️ ERROR CASE 2 (out of bounds)
   └─> Return cost value
```

### Point Recalculation Flow (_recalculate_points())

```
1. _recalculate_points() called (line 459)
   ├─> Reset current_points_spent = 0
   ├─> For each ability:
   │   ├─> Get base: PlayerData.ability_scores.get(ability_key, 8)
   │   ├─> Get cost: get_cost(base)  ⚠️ CAN RETURN 999
   │   └─> Add cost to current_points_spent
   ├─> Clamp current_points_spent to [0, POINT_BUY_TOTAL]
   └─> Emit PlayerData.points_changed signal
```

### Stat Change Flow (User Interaction)

```
1. User clicks +/- button on AbilityScoreEntry
   ├─> AbilityScoreEntry emits value_changed(ability_key, delta)
   ├─> AbilityScoreTab._on_entry_value_changed() receives signal
   ├─> Calculate desired_value = current_value + delta
   ├─> Check can_afford(current_value, desired_value)
   │   └─> Uses get_cost() which can return 999
   ├─> If affordable → apply_stat_change()
   │   ├─> Update PlayerData.ability_scores[ability_key]
   │   ├─> Calculate cost_difference = get_cost(new) - get_cost(old)
   │   ├─> Update current_points_spent
   │   └─> Emit PlayerData.stats_changed and points_changed
   └─> _refresh_all() → _update_preview()
```

## Where 999 Can Appear

### Error Case 1: Invalid point_buy_table Resource
**Location:** `AbilityScoreTab.get_cost()` line 232-234
```gdscript
if not point_buy_table or not point_buy_table.has_method("get_cost"):
    Logger.error("AbilityScoreTab: get_cost() called but point_buy_table is invalid! Returning 999", "character_creation")
    return 999
```

**Causes:**
- Resource file not found or failed to load
- Resource is not a PointBuyCostTable instance
- Resource doesn't have get_cost() method

**Impact:**
- ALL ability costs show as 999
- Point calculation breaks
- Preview breakdown shows "STR: 999", "DEX: 999", etc.

### Error Case 2: Stat Value Out of Bounds
**Location:** `PointBuyCostTable.get_cost()` line 16-20
```gdscript
func get_cost(stat_value: int) -> int:
    if cost_table.has(stat_value):
        return cost_table[stat_value]
    return 999  # Out of bounds
```

**Causes:**
- Stat value < 6 or > 26 (outside point-buy range)
- Invalid data in PlayerData.ability_scores
- Data corruption or initialization error

**Impact:**
- Only affected abilities show 999
- Other abilities show correct costs

### Error Case 3: Missing Ability Data
**Location:** `AbilityScoreTab._update_preview()` line 281
```gdscript
var base: int = PlayerData.ability_scores.get(ability_key, 8)
```

**Note:** This has a fallback (8), so won't cause 999 directly, but if base is invalid and get_cost(8) fails, it could cascade.

## Data Flow Diagram

```
PlayerData.ability_scores (Dictionary)
    ↓
_get base value (default: 8)
    ↓
get_cost(base) → PointBuyCostTable.get_cost()
    ↓
    ├─> Valid stat (6-26) → Return cost from cost_table
    └─> Invalid stat OR invalid resource → Return 999
    ↓
_update_preview() creates label: "{SHORT}: {cost}"
    ↓
Preview panel displays: "STR: 999" (if error occurred)
```

## Signal Chain

```
User clicks +/- button
    ↓
AbilityScoreEntry.value_changed emitted
    ↓
AbilityScoreTab._on_entry_value_changed()
    ↓
apply_stat_change() → Updates PlayerData.ability_scores
    ↓
PlayerData.stats_changed.emit()
    ↓
AbilityScoreTab._on_stats_changed() → _refresh_all()
    ↓
_update_preview() → Shows updated costs
```

## Potential Issues Identified

1. **No validation of point_buy_table on load** - Should verify resource loaded correctly
2. **No fallback for invalid costs** - Should handle 999 gracefully
3. **Preview shows costs, not scores** - May confuse users expecting ability scores
4. **No error recovery** - If resource fails, entire system breaks

## Recommended Fixes

1. Add validation in `_ready()` to ensure point_buy_table loaded correctly
2. Add defensive checks in `_update_preview()` to handle 999 costs
3. Add logging when 999 is returned to help debug
4. Consider showing both score AND cost in preview for clarity
5. Add error recovery: if resource fails, show error message instead of 999











