# Parchment Texture Assets - Selection Instructions

## Assets Status: ✅ EXTRACTED

**Location:** `res://assets/textures/`

Two beer paper texture packs have been extracted:
- **BeerPaper1/**: 21 images (Image_001.png through Image_021.png)
- **BeerPaper2/**: 25 images (Image_022.png through Image_044.png, plus Letter_001.png, Letter_002.png)

**Total:** 46 high-resolution parchment texture images ready for selection.

## Manual Selection Required

1. **Primary Background:**
   - Browse `BeerPaper1/` and `BeerPaper2/` directories
   - Select your favorite stained parchment texture
   - Copy/rename it to: `res://assets/textures/parchment_background.png`
   - Recommended: Look for images with good contrast and interesting stains

2. **Optional Stain Overlay:**
   - Select a different texture for additional stain effects (optional)
   - Copy/rename it to: `res://assets/textures/parchment_stain_overlay.png`
   - This can be the same or different from the primary background

**Note:** The parchment shader will automatically use a beige fallback if `parchment_background.png` is not found, so the feature works even before selection.

## Import Settings in Godot

1. Select the texture in FileSystem
2. Import tab → Set as:
   - **Filter:** Enabled
   - **Mipmaps:** Enabled
   - **Compress:** Lossless or VRAM Compressed (ETC2/ASTC)

## Fallback

If assets are not available, the shader will work with any texture assigned to `parchment_texture` uniform. A simple beige ColorRect can serve as temporary placeholder.
