# ╔═══════════════════════════════════════════════════════════
# ║ UIConstants.gd
# ║ Desc: Semantic UI sizing constants for responsive layouts
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

## UI sizing constants for semantic, responsive layouts.
## Use these constants instead of magic numbers for all UI sizing.
## Reference: GUI Specification Section 2.2 (Standard Sizes table)
class_name UIConstants

# Button Heights
const BUTTON_HEIGHT_SMALL: int = 50  ## Small action buttons
const BUTTON_HEIGHT_MEDIUM: int = 80  ## Standard menu buttons
const BUTTON_HEIGHT_LARGE: int = 120  ## Prominent calls-to-action (e.g., Generate World)

# Label Widths
const LABEL_WIDTH_NARROW: int = 80  ## Value displays (numbers, short tags)
const LABEL_WIDTH_STANDARD: int = 150  ## Most descriptive labels
const LABEL_WIDTH_WIDE: int = 200  ## Long text fields (e.g., seed input)

# Spacing / Margins
const SPACING_SMALL: int = 10  ## Tight grouping
const SPACING_MEDIUM: int = 20  ## Standard separation
const SPACING_LARGE: int = 40  ## Section breaks

# Icon Sizes
const ICON_SIZE_SMALL: int = 32  ## Inline icons
const ICON_SIZE_MEDIUM: int = 64  ## Buttons, previews
const ICON_SIZE_LARGE: int = 128  ## Hero icons, logos

# Panel Widths
const PANEL_WIDTH_NAV: int = 250  ## Left navigation panel width
const PANEL_WIDTH_CONTENT: int = 300  ## Right content panel width

# Additional Label Widths
const LABEL_WIDTH_COMPACT: int = 60  ## Compact labels (e.g., X/Y coordinates)
const LABEL_WIDTH_MEDIUM: int = 120  ## Medium-width labels

# List Heights
const LIST_HEIGHT_STANDARD: int = 200  ## Standard list/scroll container height

# Dialog Sizes
const DIALOG_WIDTH_MEDIUM: int = 400  ## Medium dialog width
const DIALOG_WIDTH_LARGE: int = 600  ## Large dialog width
const DIALOG_HEIGHT_STANDARD: int = 300  ## Standard dialog height

# Button Sizes (Vector2)
const BUTTON_SIZE_TYPE: Vector2 = Vector2(100, 40)  ## Type selection button size

# Overlay Sizes
const OVERLAY_MIN_WIDTH: int = 450  ## Minimum width for performance monitor overlay
const OVERLAY_MARGIN_LARGE: int = 50  ## Larger margin to prevent clipping

# Performance Monitor Constants
const PERF_OVERLAY_PADDING: int = 10  ## Padding for performance monitor overlay
const PERF_GRAPH_WIDTH_RATIO: float = 0.2  ## 20% of viewport width for graphs
const PERF_GRAPH_HEIGHT: int = 100  ## Fixed height for performance graphs
const PERF_LABEL_FONT_SIZE: int = 18  ## Smaller font size for performance text
const PERF_HISTORY_SIZE: int = 120  ## ~2 seconds at 60 FPS for smoother graphs
const PERF_BOTTOM_BAR_HEIGHT: int = 180  ## Height for DETAILED mode bottom bar overlay
const PERF_BOTTOM_MARGIN: int = 20  ## Bottom margin for DETAILED mode overlay
const PERF_REFRESH_THRESHOLD: float = 10.0  ## Threshold (ms) for color-coding refresh time (red if >10ms)
const BOTTOM_GRAPH_BAR_HEIGHT: int = 160  ## Height for bottom graph bar in DETAILED mode
const BOTTOM_GRAPH_BAR_MARGIN: int = 20  ## Bottom margin for graph bar
