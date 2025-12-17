# ╔═══════════════════════════════════════════════════════════
# ║ UIConstants.gd
# ║ Desc: Centralized UI sizing constants for consistent, responsive UI
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name UIConstants
extends Object

## Standard UI sizing constants for Genesis Mythos GUI system.
## All UI elements should use these constants instead of hard-coded pixel values.
## See GUI Specification (res://audit/updated_gui_spec.md) for usage guidelines.

# Button Heights
const BUTTON_HEIGHT_SMALL: int = 50   ## Small action buttons
const BUTTON_HEIGHT_MEDIUM: int = 80  ## Standard menu buttons
const BUTTON_HEIGHT_LARGE: int = 120  ## Prominent calls-to-action (e.g., Generate World)

# Label Widths
const LABEL_WIDTH_NARROW: int = 80    ## Value displays (numbers, short tags)
const LABEL_WIDTH_STANDARD: int = 150 ## Most descriptive labels
const LABEL_WIDTH_WIDE: int = 200     ## Long text fields (e.g., seed input)

# Spacing / Margins
const SPACING_SMALL: int = 10  ## Tight grouping
const SPACING_MEDIUM: int = 20 ## Standard separation
const SPACING_LARGE: int = 40  ## Section breaks

# Icon Sizes
const ICON_SIZE_SMALL: int = 32   ## Inline icons
const ICON_SIZE_MEDIUM: int = 64  ## Buttons, previews
const ICON_SIZE_LARGE: int = 128  ## Hero icons, logos

# Panel Widths (for sidebars and content panels)
const PANEL_WIDTH_NAV: int = 250     ## Navigation sidebar width
const PANEL_WIDTH_CONTENT: int = 400 ## Right content panel width

# List Heights (for scrollable lists)
const LIST_HEIGHT_STANDARD: int = 200 ## Standard list height

# Special Label Widths
const LABEL_WIDTH_COMPACT: int = 60  ## Very compact labels
const LABEL_WIDTH_MEDIUM: int = 120  ## Medium-width labels

# Button Sizes (width x height)
const BUTTON_SIZE_TYPE: Vector2 = Vector2(150, 100) ## Type selection buttons

# Dialog Sizes
const DIALOG_WIDTH_MEDIUM: int = 500  ## Medium dialog width
const DIALOG_WIDTH_LARGE: int = 600   ## Large dialog width
const DIALOG_HEIGHT_STANDARD: int = 400 ## Standard dialog height
