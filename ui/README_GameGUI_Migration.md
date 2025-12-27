# GameGUI Migration to class_name - Complete

## Overview

The GameGUI addon has been successfully migrated from the legacy `add_custom_type()` EditorPlugin registration system to the modern Godot 4 `class_name`-based global class system. This provides full runtime support and eliminates "Cannot get class" errors at runtime/export.

## Migration Date

**Completed:** 2025-12-16

## What Changed

### Phase 1: Plugin Disabled
- **project.godot**: GameGUI plugin removed from `[editor_plugins]` enabled list
- **project.godot**: GameGUI plugin entry in `[plugins]` section commented out
- **addons/GameGUI/plugin.gd**: All `add_custom_type()` and `remove_custom_type()` calls commented out

### Phase 2: class_name Declarations
All 15 GameGUI component scripts already had `class_name` declarations in place:
- ✅ `GGComponent.gd` (base class)
- ✅ `GGButton.gd`
- ✅ `GGFiller.gd`
- ✅ `GGHBox.gd`
- ✅ `GGInitialWindowSize.gd`
- ✅ `GGLabel.gd`
- ✅ `GGLayoutConfig.gd`
- ✅ `GGLimitedSizeComponent.gd`
- ✅ `GGMarginLayout.gd`
- ✅ `GGNinePatchRect.gd`
- ✅ `GGOverlay.gd`
- ✅ `GGParameterSetter.gd`
- ✅ `GGRichTextLabel.gd`
- ✅ `GGTextureRect.gd`
- ✅ `GGVBox.gd`

### Phase 3: Scene Verification
All existing scenes using GameGUI nodes are correctly configured:
- ✅ `scenes/MainMenu.tscn` - Uses `GGVBox` and `GGLabel`
- ✅ `ui/world_builder/WorldBuilderUI.tscn` - Uses `GGLabel`, `GGHBox`, and `GGButton`

All scene files use the correct `type="GG*"` attributes which work seamlessly with `class_name`.

## Benefits

1. **Full Runtime Support**: GameGUI classes are now available at runtime and in exported builds
2. **No More "Cannot get class" Errors**: Eliminated runtime errors that occurred with `add_custom_type()`
3. **Modern Godot 4 Approach**: Uses the recommended `class_name` system
4. **Better Editor Integration**: Classes appear in "Create New Node" dialog automatically
5. **Simplified Maintenance**: No plugin registration needed

## Usage

### Creating GameGUI Nodes

**Method 1: Via Node Dialog (Recommended)**
1. Right-click in Scene dock → "Add Child Node"
2. Search for "GG" in the search box
3. Select any GameGUI node (e.g., `GGVBox`, `GGLabel`, `GGButton`)
4. Node is created with the correct type automatically

**Method 2: Via Code**
```gdscript
# Direct instantiation - works at runtime
var vbox = GGVBox.new()
var label = GGLabel.new()
var button = GGButton.new()
```

**Method 3: Via Scene Files**
```gdscript
# In .tscn files, use type="GGVBox", type="GGLabel", etc.
# These are automatically recognized via class_name
```

### Type Annotations

You can now use GameGUI classes in type annotations:
```gdscript
@onready var vbox_container: GGVBox = $CenterContainer/VBoxContainer
@onready var title_label: GGLabel = $TitleLabel
```

## Technical Details

### Runtime Loading

The `core/singletons/eryndor.gd` and `addons/GameGUI/runtime_loader.gd` files still preload GameGUI scripts for early initialization. This ensures proper script parsing order, though with `class_name` it's not strictly necessary.

### @tool Directive

All GameGUI scripts retain the `@tool` directive for editor features and previews. This works seamlessly with `class_name`.

### Plugin Status

The `addons/GameGUI/plugin.gd` file is kept for reference but is no longer active. The plugin is disabled in Project Settings.

## Verification Checklist

- [x] Plugin disabled in `project.godot`
- [x] All `add_custom_type()` calls commented out
- [x] All 15 component scripts have `class_name` declarations
- [x] Existing scenes verified and working
- [x] Runtime loader comments updated
- [x] Documentation created

## Testing

To verify the migration:

1. **Editor Test**: Open Godot editor, search for "GG" in Create Node dialog - all GameGUI nodes should appear
2. **Scene Test**: Open `scenes/MainMenu.tscn` - should load without errors
3. **Runtime Test**: Run the project - no "Cannot get class" errors should occur
4. **Export Test**: Export the project - GameGUI nodes should work in exported builds

## Future Development

- Always use `class_name` for new GameGUI components (if any are added)
- No need to modify `plugin.gd` - it's kept for historical reference only
- GameGUI nodes can be used freely in scenes, scripts, and at runtime
- Consider removing runtime_loader.gd preloading in the future if not needed (currently kept for safety)

## Related Files

- `addons/GameGUI/plugin.gd` - Disabled plugin (kept for reference)
- `addons/GameGUI/runtime_loader.gd` - Runtime preloader (still active, ensures early init)
- `core/singletons/eryndor.gd` - Core singleton that preloads GameGUI classes
- `scenes/MainMenu.tscn` - Example scene using GameGUI nodes
- `ui/world_builder/WorldBuilderUI.tscn` - Example scene using GameGUI nodes

---

**Migration Status**: ✅ **COMPLETE** - All phases successfully completed.












