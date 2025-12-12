# API Reference Documentation

Complete API reference for all public classes, methods, signals, and properties in the project.

## Table of Contents

- [Singletons](#singletons)
  - [Eryndor](#eryndor)
  - [Logger](#logger)
  - [WorldStreamer](#worldstreamer)
  - [EntitySim](#entitysim)
  - [FactionEconomy](#factioneconomy)
- [World Builder](#world-builder)
  - [WorldBuilderUI](#worldbuilderui)
  - [MapMakerModule](#mapmakermodule)
  - [Terrain3DManager](#terrain3dmanager)
  - [IconNode](#iconnode)
- [Resources](#resources)
  - [WorldMapData](#worldmapdata)

---

## Singletons

### Eryndor

**Path:** `res://core/singletons/eryndor.gd`  
**Type:** Autoload Singleton (Node)

Core game singleton and main entry point for Eryndor 4.0 Final.

#### Methods

##### `_ready() -> void`

Initializes core systems on startup. Logs initialization messages.

---

### WorldStreamer

**Path:** `res://core/streaming/world_streamer.gd`  
**Type:** Autoload Singleton (Node)

World streaming and loading system for dynamic content management.

---

### Logger

**Path:** `res://core/singletons/Logger.gd`  
**Type:** Autoload Singleton (Node)

Centralized logging system with configurable levels and outputs.

#### Enums

```gdscript
enum LOG_LEVEL {
    DEBUG,      # Detailed debugging information
    INFO,       # General information
    WARNING,    # Warning messages
    ERROR       # Error messages
}
```

#### Signals

```gdscript
signal log_event(level: LOG_LEVEL, message: String, module: String)
```

#### Methods

##### `debug(message: String, module: String = "") -> void`

Logs a DEBUG level message.

##### `info(message: String, module: String = "") -> void`

Logs an INFO level message.

##### `warning(message: String, module: String = "") -> void`

Logs a WARNING level message.

##### `error(message: String, module: String = "") -> void`

Logs an ERROR level message.

##### `start_timer(timer_id: String, module: String = "") -> void`

Starts a performance timer.

**Parameters:**
- `timer_id` (String): Unique timer identifier
- `module` (String): Optional module name

##### `end_timer(timer_id: String, log_result: bool = true) -> float`

Ends a performance timer and optionally logs the result.

**Parameters:**
- `timer_id` (String): Timer identifier
- `log_result` (bool): Whether to log the result

**Returns:**
- `float`: Elapsed time in milliseconds, or -1.0 if timer not found

---

## World Builder

### WorldBuilderUI

**Path:** `res://ui/world_builder/WorldBuilderUI.gd`  
**Type:** Control

Main wizard controller for the World Builder system. Manages 9-step wizard flow.

#### Properties

```gdscript
var current_step: int                   # Current wizard step (1-9)
var world_data: Dictionary              # Collected world data from all steps
```

#### Methods

##### `next_step() -> void`

Advances to the next wizard step.

##### `previous_step() -> void`

Returns to the previous wizard step.

##### `save_world(name: String) -> void`

Saves the current world configuration to JSON.

**Parameters:**
- `name` (String): World name for file naming

---

### MapMakerModule

**Path:** `res://ui/world_builder/MapMakerModule.gd`  
**Type:** Control

2D map editor module with parchment styling and brush tools.

#### Methods

##### `generate_heightmap() -> void`

Generates heightmap from current map data.

##### `export_to_3d() -> void`

Exports 2D map to 3D terrain format.

---

### Terrain3DManager

**Path:** `res://core/world_generation/Terrain3DManager.gd`  
**Type:** Node

Manages Terrain3D plugin integration and terrain generation.

#### Methods

##### `generate_from_noise(seed: int, frequency: float, min_height: float, max_height: float) -> void`

Generates terrain from noise parameters.

**Parameters:**
- `seed` (int): Random seed for noise generation
- `frequency` (float): Noise frequency
- `min_height` (float): Minimum terrain height
- `max_height` (float): Maximum terrain height

##### `generate_from_heightmap(heightmap_image: Image) -> void`

Generates terrain from a heightmap image.

**Parameters:**
- `heightmap_image` (Image): Heightmap image data

---

### IconNode

**Path:** `res://ui/world_builder/IconNode.gd`  
**Type:** Node2D

Icon node class for 2D map canvas icon placement.

#### Properties

```gdscript
var icon_id: String                     # Icon identifier from map_icons.json
var icon_type: String                   # Icon type variant
var position: Vector2                   # Position on map
```

---

## Resources

### WorldMapData

**Path:** `res://core/world_generation/WorldMapData.gd`  
**Type:** Resource

Resource class for storing 2D map data including heightmaps and markers.

#### Properties

```gdscript
@export var heightmap_image: Image     # Heightmap image data
@export var markers: Array[Dictionary] # Icon markers on map
@export var noise_parameters: Dictionary # Noise generation parameters
```

## Usage Examples

### Logging

```gdscript
# Simple logging
Logger.info("World generated", "world_builder")
Logger.error("Failed to load terrain", "terrain")

# Performance timing
Logger.start_timer("generate_terrain", "terrain")
# ... do work ...
var elapsed = Logger.end_timer("generate_terrain")
```

### World Builder Flow

```gdscript
# In WorldBuilderUI
func _on_step_completed(step_data: Dictionary):
    world_data[step_data.step_name] = step_data.data
    next_step()
```

### Terrain Generation

```gdscript
# Generate terrain from noise
Terrain3DManager.generate_from_noise(12345, 0.05, -100.0, 100.0)

# Generate terrain from heightmap
var heightmap = preload("res://heightmaps/world.png")
Terrain3DManager.generate_from_heightmap(heightmap)
```

---

*For detailed implementation, see source code comments in each file.*

