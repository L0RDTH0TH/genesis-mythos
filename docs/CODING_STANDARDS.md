# ╔═══════════════════════════════════════════════════════════
# ║ CODING_STANDARDS.md
# ║ Desc: Complete coding standards and conventions for Genesis Mythos
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

# Coding Standards

This document defines the mandatory coding standards for the Genesis Mythos project. All code must follow these rules 100% with zero exceptions.

## Language & Version

- **Godot Version**: 4.3 stable only (4.3.0 or any 4.3.x patch)
- **Language**: GDScript only (no C#, no VisualScript)
- **Typing**: Typed GDScript everywhere

## Naming Conventions

### Variables and Functions
- Use `snake_case` for all variables and functions
- Examples:
  ```gdscript
  var player_health: int = 100
  var is_game_running: bool = false
  
  func calculate_damage(base_damage: int, multiplier: float) -> int:
      return int(base_damage * multiplier)
  ```

### Classes, Nodes, and Resources
- Use `PascalCase` for all classes, nodes, and resources
- Examples:
  ```gdscript
  class_name PlayerController
  extends Node
  
  # Node names in scenes: "PlayerController", "HealthBar", "InventoryPanel"
  ```

### Constants
- Use `ALL_CAPS` with underscores for constants
- Examples:
  ```gdscript
  const MAX_HEALTH: int = 100
  const DEFAULT_SPEED: float = 5.0
  const GRAVITY: Vector3 = Vector3(0, -9.8, 0)
  ```

## File Structure

### One Class Per File
- Exactly one class per file
- File name must match class name exactly
- Example: `PlayerController.gd` contains `class_name PlayerController`

### File Naming
- Scripts: `ClassName.gd`
- Scenes: `ClassName.tscn`
- Resources: `ResourceName.tres`

## Script Header

**EVERY script MUST start with this exact header format:**

```gdscript
# ╔═══════════════════════════════════════════════════════════
# ║ MyClassName.gd
# ║ Desc: One-line description
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
```

Example:
```gdscript
# ╔═══════════════════════════════════════════════════════════
# ║ PlayerController.gd
# ║ Desc: Handles player input and movement
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
extends CharacterBody3D

# ... rest of code
```

## Typed GDScript

### Variable Declarations
Always use type hints:
```gdscript
var health: int = 100
var player_name: String = "Player"
var position: Vector3 = Vector3.ZERO
var inventory: Array[Dictionary] = []
```

### Function Declarations
Always specify return types:
```gdscript
func calculate_damage(base: int, multiplier: float) -> int:
    return int(base * multiplier)

func get_player_name() -> String:
    return player_name

func process_input() -> void:
    # No return value
    pass
```

### @onready Variables
Use `@onready var` (never the old `onready var`):
```gdscript
@onready var health_bar: ProgressBar = $HealthBar
@onready var player_sprite: Sprite2D = $PlayerSprite
```

## Documentation

### Function Docstrings
Every public function must have a docstring:
```gdscript
func calculate_damage(base_damage: int, multiplier: float) -> int:
    """Calculate final damage with multiplier.
    
    Args:
        base_damage: Base damage value
        multiplier: Damage multiplier (1.0 = no change)
    
    Returns:
        Final damage as integer
    """
    return int(base_damage * multiplier)
```

### Inline Comments
Use inline comments for complex logic:
```gdscript
# Calculate damage with critical hit chance
var final_damage: int = base_damage
if randf() < critical_chance:
    final_damage *= 2  # Critical hit doubles damage
```

## No Magic Numbers

### Use Constants
Never use magic numbers. Always define constants:
```gdscript
# BAD
if health > 50:
    player.speed = 10.0

# GOOD
const HEALTH_THRESHOLD: int = 50
const FAST_SPEED: float = 10.0

if health > HEALTH_THRESHOLD:
    player.speed = FAST_SPEED
```

### Use Theme Overrides
For UI values, use theme overrides instead of hard-coded values:
```gdscript
# BAD
label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))

# GOOD - Define in theme, reference by name
label.add_theme_color_override("font_color", get_theme_color("error_color"))
```

## No Hard-Coded Colors

All colors must come from the theme or constants:
```gdscript
# BAD
label.modulate = Color(0.5, 0.5, 0.5)

# GOOD
const DISABLED_COLOR: Color = Color(0.5, 0.5, 0.5)
label.modulate = DISABLED_COLOR

# OR BETTER - from theme
label.modulate = get_theme_color("disabled_color")
```

## Data-Driven Design

### Load from JSON
Never hard-code game data. Load from JSON files:
```gdscript
# BAD
var biomes = ["forest", "desert", "tundra"]

# GOOD
var biomes: Array[Dictionary] = []
func _ready() -> void:
    var file = FileAccess.open("res://data/biomes.json", FileAccess.READ)
    if file:
        var json = JSON.new()
        json.parse(file.get_as_text())
        biomes = json.data
        file.close()
```

### Use Resources
For complex data structures, use Resource classes:
```gdscript
# Define in Resource
class_name ItemData
extends Resource

@export var id: String
@export var name: String
@export var value: int

# Load and use
var item: ItemData = load("res://data/items/sword.tres")
```

## UI Theme

### Single Theme
- All UI uses the single theme: `res://themes/bg3_theme.tres`
- Never create additional themes
- Apply theme globally in project settings

### Theme Usage
```gdscript
# Apply theme to node
node.theme = preload("res://themes/bg3_theme.tres")

# Use theme constants
var color: Color = get_theme_color("font_color")
var font_size: int = get_theme_font_size("font_size")
```

## Code Organization

### Class Structure
Organize class members in this order:
1. Class declaration and extends
2. Constants
3. Signals
4. Exported variables
5. Public variables
6. Private variables
7. @onready variables
8. _ready() and _enter_tree()
9. Public functions
10. Private functions (prefixed with _)
11. Signal handlers

Example:
```gdscript
# ╔═══════════════════════════════════════════════════════════
# ║ PlayerController.gd
# ║ Desc: Handles player input and movement
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
extends CharacterBody3D

# Constants
const MAX_SPEED: float = 10.0
const ACCELERATION: float = 20.0

# Signals
signal health_changed(new_health: int)
signal player_died

# Exported variables
@export var health: int = 100

# Public variables
var is_alive: bool = true

# Private variables
var _current_speed: float = 0.0

# @onready variables
@onready var health_bar: ProgressBar = $HealthBar

# _ready()
func _ready() -> void:
    pass

# Public functions
func take_damage(amount: int) -> void:
    """Apply damage to player."""
    health -= amount
    health_changed.emit(health)
    if health <= 0:
        die()

# Private functions
func _process_movement(delta: float) -> void:
    """Process player movement."""
    pass

# Signal handlers
func _on_health_changed(new_health: int) -> void:
    """Handle health change."""
    pass
```

## Best Practices

### Error Handling
Always check for null and valid values:
```gdscript
if not node:
    push_error("Node is null")
    return

if node.has_method("do_something"):
    node.do_something()
```

### Performance
- Use object pooling for frequently created/destroyed objects
- Cache node references in @onready variables
- Avoid creating objects in _process() or _physics_process()

### Readability
- Keep functions short and focused (single responsibility)
- Use descriptive variable names
- Group related code together
- Add comments for complex algorithms

## Summary Checklist

Before submitting code, ensure:

- [ ] All variables and functions use `snake_case`
- [ ] All classes use `PascalCase`
- [ ] All constants use `ALL_CAPS`
- [ ] Script header is present and correct
- [ ] All variables have type hints
- [ ] All functions have return types
- [ ] Using `@onready var` (not `onready var`)
- [ ] No magic numbers (use constants)
- [ ] No hard-coded colors (use theme)
- [ ] All public functions have docstrings
- [ ] Code is data-driven (no hard-coded content)
- [ ] UI uses single theme (`bg3_theme.tres`)

---

**These standards are MANDATORY and must be followed 100% with zero exceptions.**
