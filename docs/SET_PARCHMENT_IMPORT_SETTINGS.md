# Setting Parchment Texture Import Settings

## Overview

The parchment texture files (`parchment_background.png` and `parchment_stain_overlay.png`) need specific import settings configured for optimal performance and quality.

## Recommended Settings

- **Filter:** Enabled (smooth texture filtering)
- **Mipmaps:** Enabled (better performance at distance)
- **Compress:** Lossless or VRAM Compressed (ETC2/ASTC)

## Method 1: Manual Configuration (Recommended)

**Fastest and most reliable method:**

1. Open Godot Editor
2. Navigate to `res://assets/textures/` in FileSystem dock
3. Select `parchment_background.png`
4. In the **Import** tab (bottom panel):
   - ✅ Enable **Filter**
   - ✅ Enable **Mipmaps**
   - Set **Compress Mode** to `Lossless` or `VRAM Compressed (ETC2/ASTC)`
   - Click **Reimport**
5. Repeat for `parchment_stain_overlay.png`

**Time:** ~30 seconds total

## Method 2: Automated Script (Alternative)

If you prefer automation, you can use the editor script, but it has limitations:

1. In Godot Editor: **Script > Run Script**
2. Select `scripts/editor/set_parchment_import_settings.gd`
3. Run it

**Note:** This script provides a template but may require manual verification since Godot's import API is limited.

## Method 3: Direct .import File Editing (Advanced - Not Recommended)

You can manually edit the `.import` files in `.godot/imported/`, but this is:
- ❌ Fragile (format can change)
- ❌ Error-prone
- ❌ Not officially supported

## Why These Settings Matter

- **Filter:** Ensures smooth texture rendering without pixelation
- **Mipmaps:** Provides better performance when texture is viewed at distance/zoomed out
- **Lossless/VRAM Compressed:** Maintains quality while optimizing GPU memory usage

## Verification

After setting import settings:

1. Select the texture in FileSystem
2. Check Import tab - settings should be visible
3. The parchment shader will automatically use the correctly imported texture

**The parchment feature will work even without optimal import settings**, but performance may be slightly reduced.
