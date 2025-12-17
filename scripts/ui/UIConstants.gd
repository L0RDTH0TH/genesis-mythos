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

# Panel Widths (for WorldBuilderUI)
const PANEL_WIDTH_NAV: int = 250     ## Left navigation panel width
const PANEL_WIDTH_CONTENT: int = 400 ## Right content panel width

# List Heights
const LIST_HEIGHT_STANDARD: int = 200 ## Standard list/scroll area height
