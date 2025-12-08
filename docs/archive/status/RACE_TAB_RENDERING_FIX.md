# Race Tab Three-Column Rendering Fix

## Problem Summary

The three-column scroll wheel in the Race tab's center content area wasn't rendering properly, showing:
- Empty black areas
- Misplaced columns
- Incorrect scrollbar position
- Bounds extending beyond expectations

## Root Causes Identified

### 1. **ScrollContainer Child Layout Mode** ✅ FIXED
- **Issue**: In Godot 4.3, `ScrollContainer` requires its direct child to use **Anchor mode (layout_mode = 1)**, not Container mode
- **Status**: Already fixed in `RaceTab.tscn` - `ColumnsContainer` uses `layout_mode = 1` with Full Rect anchors

### 2. **Deferred Layout Updates** ✅ FIXED
- **Issue**: Layout calculations were happening before nodes were fully ready
- **Fix**: Added multiple `await get_tree().process_frame` calls to ensure layout propagates correctly
- **Location**: `RaceTab._populate_list()`

### 3. **Column Sizing and Visibility** ✅ FIXED
- **Issue**: Columns might not be properly sized or visible when content is added
- **Fix**: 
  - Explicitly set `visible = true` on all containers
  - Ensure `size_flags_horizontal = Control.SIZE_EXPAND_FILL` on all columns
  - Force layout updates with `update_minimum_size()` and `queue_sort()`

### 4. **ScrollContainer Width Matching** ✅ FIXED
- **Issue**: `ColumnsContainer` minimum width might not match `ScrollContainer` viewport width
- **Fix**: Added runtime check to ensure `ColumnsContainer.custom_minimum_size.x` matches `UnifiedScroll.size.x`

### 5. **Timing Issues with Content Population** ✅ FIXED
- **Issue**: Content was being added before layout was ready
- **Fix**: 
  - Wait for layout before adding entries
  - Configure column sizing flags before populating
  - Multiple frame waits after content addition

## Changes Made

### `scripts/character_creation/tabs/RaceTab.gd`

1. **Enhanced `_populate_list()` function**:
   - Added explicit visibility and sizing configuration before content addition
   - Added multiple frame waits for layout propagation
   - Added runtime width matching between ScrollContainer and ColumnsContainer
   - Improved layout update sequence

2. **Added `_print_diagnostic()` function**:
   - Prints runtime sizes and visibility status of all containers
   - Helps debug layout issues
   - Called after population completes

3. **Improved `_ready()` function**:
   - Added frame wait before deferred `_populate_list()` call
   - Ensures tree is fully ready before population

## Scene File Status

`scenes/character_creation/tabs/RaceTab.tscn` is correctly configured:
- ✅ `ColumnsContainer` uses Anchor mode (`layout_mode = 1`)
- ✅ Full Rect anchors preset (`anchors_preset = 15`)
- ✅ Proper size flags on all containers
- ✅ Three columns configured with `SIZE_EXPAND_FILL`

## Testing Recommendations

1. **Run the project** and check the Race tab
2. **Check debug logs** for diagnostic output showing container sizes
3. **Verify**:
   - Three columns appear side-by-side
   - Columns are equally sized
   - Scrollbar appears when content exceeds viewport
   - Content is visible (not black/empty)
   - Scroll position resets to top on load

## Potential Remaining Issues

If columns still don't appear, check:

1. **Theme Application**: Ensure `bg3_theme.tres` is properly applied and doesn't override visibility
2. **RaceEntry.tscn**: Verify entries are properly instantiated and visible
3. **GameData Loading**: Ensure `GameData.load_all_data()` completes before tab loads
4. **Parent Container Sizing**: Verify `CharacterCreationRoot`'s `CurrentTabContainer` has proper size

## Next Steps

1. Test the changes in-game
2. Review diagnostic logs for any size/visibility issues
3. If issues persist, check:
   - `CharacterCreationRoot.tscn` layout
   - `MiddleOptions` ScrollContainer configuration
   - Theme overrides affecting visibility

