# ╔═══════════════════════════════════════════════════════════
# ║ UIConstants.gd
# ║ Desc: Central constants for UI sizing and spacing - eliminates magic numbers
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name UIConstants

## Standard UI sizing constants for consistent, responsive layouts.
## Use these instead of hard-coded pixel values throughout the project.
## All values are in pixels and represent semantic sizes for different UI elements.

# ═══════════════════════════════════════════════════════════
# BUTTON HEIGHTS
# ═══════════════════════════════════════════════════════════

## Small action buttons (e.g., +/- controls, icon buttons)
const BUTTON_HEIGHT_SMALL: int = 50

## Standard menu buttons (e.g., navigation, standard actions)
const BUTTON_HEIGHT_MEDIUM: int = 80

## Prominent calls-to-action (e.g., Generate World, Create Character)
const BUTTON_HEIGHT_LARGE: int = 120

# ═══════════════════════════════════════════════════════════
# LABEL WIDTHS
# ═══════════════════════════════════════════════════════════

## Value displays (numbers, short tags, status indicators)
const LABEL_WIDTH_NARROW: int = 80

## Most descriptive labels (standard text fields, descriptions)
const LABEL_WIDTH_STANDARD: int = 150

## Long text fields (e.g., seed input, extended descriptions)
const LABEL_WIDTH_WIDE: int = 200

# ═══════════════════════════════════════════════════════════
# SPACING / MARGINS
# ═══════════════════════════════════════════════════════════

## Tight grouping (e.g., related controls, compact layouts)
const SPACING_SMALL: int = 10

## Standard separation (e.g., between form fields, menu items)
const SPACING_MEDIUM: int = 20

## Section breaks (e.g., between major UI sections, panels)
const SPACING_LARGE: int = 40

# ═══════════════════════════════════════════════════════════
# ICON SIZES
# ═══════════════════════════════════════════════════════════

## Inline icons (e.g., status indicators, small decorations)
const ICON_SIZE_SMALL: int = 32

## Buttons, previews (e.g., button icons, thumbnail previews)
const ICON_SIZE_MEDIUM: int = 64

## Hero icons, logos (e.g., main menu logo, large decorative elements)
const ICON_SIZE_LARGE: int = 128
