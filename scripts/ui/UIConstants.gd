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
const BOTTOM_GRAPH_BAR_HEIGHT: int = 480  ## Height for bottom graph bar in DETAILED mode
const BOTTOM_GRAPH_BAR_MARGIN: int = 20  ## Bottom margin for graph bar
const GRAPH_INNER_HEIGHT: int = 140  ## Individual graph height with padding

# Progress Bar Constants
const PROGRESS_BAR_WIDTH: int = 400  ## Width for progress bars
const PROGRESS_BAR_HEIGHT: int = 40  ## Height for progress bars
const PROGRESS_BAR_MARGIN_TOP: int = 100  ## Top margin for progress bar positioning

# Waterfall View Constants (v4 Specification)
const WATERFALL_LANE_HEIGHT: int = 60  ## Height per lane in waterfall view
const WATERFALL_FRAME_WIDTH_MIN: int = 32  ## Minimum frame width for hover accuracy
const WATERFALL_TARGET_FRAME_MS: float = 16.67  ## Target frame time (60 FPS)
const WATERFALL_DRAW_CALLS_MAX: int = 2000  ## Maximum draw calls for scaling
const WATERFALL_BUFFER_MAX: int = 10  ## Maximum size for metric buffers
const WATERFALL_TOOLTIP_DELAY_MS: int = 200  ## Tooltip display delay in milliseconds

# World Builder UI Constants
const LEFT_PANEL_WIDTH: int = 220  ## Left panel width for category tabs
const LEFT_PANEL_WIDTH_MIN: int = 180  ## Minimum left panel width
const LEFT_PANEL_WIDTH_MAX: int = 300  ## Maximum left panel width
const RIGHT_PANEL_WIDTH: int = 240  ## Right panel width for parameter controls
const RIGHT_PANEL_WIDTH_MIN: int = 200  ## Minimum right panel width
const RIGHT_PANEL_WIDTH_MAX: int = 350  ## Maximum right panel width
const BOTTOM_BAR_HEIGHT: int = 50  ## Bottom bar height for buttons and status
const STEP_BUTTON_HEIGHT: int = 40  ## Height for step navigation buttons
const BUTTON_WIDTH_SMALL: int = 120  ## Small button width (Back/Next)
const BUTTON_WIDTH_MEDIUM: int = 180  ## Medium button width (Bake to 3D)
const BUTTON_WIDTH_LARGE: int = 250  ## Large button width (Generate)
const SEED_SPIN_WIDTH: int = 200  ## Seed spinbox width
const RANDOMIZE_BTN_SIZE: Vector2 = Vector2(64, 50)  ## Randomize button size

# Azgaar Integration Constants
const MAX_POINTS_LOW_HW: int = 500000  ## Maximum points for low-end hardware
const MAX_POINTS_HIGH_HW: int = 2000000  ## Maximum points for high-end hardware
const AZGAAR_BASE_URL: String = "https://azgaar.github.io/Fantasy-Map-Generator/"
const AZGAAR_JSON_URL: String = AZGAAR_BASE_URL + "?json=user://azgaar/options.json#"
const DOWNLOADS_DIR: String = "user://azgaar/downloads/"

## Get clamped value based on hardware capabilities.
static func get_clamped_points(base_points: int) -> int:
	var ram_bytes: int = OS.get_static_memory_usage()
	var ram_gb: int = ram_bytes / (1024 * 1024 * 1024)
	var cores: int = OS.get_processor_count()
	if ram_gb < 8 or cores < 8:
		return min(base_points, MAX_POINTS_LOW_HW)
	return min(base_points, MAX_POINTS_HIGH_HW)
