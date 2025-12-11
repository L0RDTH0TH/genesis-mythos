# Parchment Texture Assets - Download Instructions

## Required Assets for Phase 0

Download these free CC0/compatible parchment textures:

1. **Primary Background:**
   - Source: https://oddsents.itch.io/paper-texture-backgrounds
   - File: Choose best 2048×2048 stained parchment (e.g., "paper_07.png" or similar)
   - Save as: `res://assets/textures/parchment_background.png`

2. **Optional Stain Overlay:**
   - Source: https://thomasnovosel.itch.io/beer-paper-scanpack
   - File: Pick one high-res stained paper texture
   - Save as: `res://assets/textures/parchment_stain_overlay.png` (optional)

## Import Settings in Godot

1. Select the texture in FileSystem
2. Import tab → Set as:
   - **Filter:** Enabled
   - **Mipmaps:** Enabled
   - **Compress:** Lossless or VRAM Compressed (ETC2/ASTC)

## Fallback

If assets are not available, the shader will work with any texture assigned to `parchment_texture` uniform. A simple beige ColorRect can serve as temporary placeholder.
