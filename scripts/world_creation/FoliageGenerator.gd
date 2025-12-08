# ╔═══════════════════════════════════════════════════════════
# ║ FoliageGenerator.gd
# ║ Desc: Foliage density calculation based on biomes and noise
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
class_name FoliageGenerator
extends RefCounted

## Generate foliage density map for world.
##
## Args:
## 	world_data: WorldData resource with biome_metadata and params
##
## Stores result in world_data.foliage_density (Array[float], 0.0-1.0 per cell)
static func generate_foliage_density(world_data) -> void:
	if not world_data:
		return
	
	# Get parameters
	var enable_foliage: bool = world_data.params.get("enable_foliage", true)
	var base_density: float = world_data.params.get("foliage_density", 0.6)  # 0.0-1.0
	var variation: float = world_data.params.get("foliage_variation", 0.4)  # 0.0-1.0
	
	# Initialize foliage density array
	var size: int = world_data.biome_metadata.size()
	var foliage_array: Array = []
	foliage_array.resize(size)
	
	if not enable_foliage:
		# Set all to 0.0 if disabled
		for i in range(size):
			foliage_array[i] = 0.0
		# Use direct assignment
		world_data.foliage_density = foliage_array
		return
	
	# Create noise for variation
	var variation_noise: FastNoiseLite = FastNoiseLite.new()
	variation_noise.seed = world_data.seed + 3000
	variation_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	variation_noise.frequency = 0.05
	
	# Calculate foliage density per cell
	for i in range(size):
		var biome_data: Dictionary = world_data.biome_metadata[i]
		var biome_name: String = biome_data.get("biome", "plains")
		
		# Base density by biome type
		var biome_density: float = _get_biome_foliage_density(biome_name)
		
		# Apply base density setting (scales all biomes)
		biome_density *= base_density
		
		# Add noise variation
		var x: int = biome_data.get("x", 0)
		var y: int = biome_data.get("y", 0)
		var noise_value: float = variation_noise.get_noise_2d(x, y)
		var variation_amount: float = (noise_value + 1.0) * 0.5 * variation  # 0-1 range, scaled by variation
		
		# Combine: biome density + variation
		var final_density: float = biome_density + (variation_amount - 0.5) * 0.3  # Variation adds ±15%
		final_density = clamp(final_density, 0.0, 1.0)
		
		foliage_array[i] = final_density
	
	# Assign array to world_data (direct assignment)
	world_data.foliage_density = foliage_array

## Get base foliage density for a biome type.
static func _get_biome_foliage_density(biome: String) -> float:
	match biome:
		"forest":
			return 0.9  # Very high
		"jungle":
			return 1.0  # Maximum
		"taiga":
			return 0.7  # High
		"swamp":
			return 0.8  # High
		"grassland":
			return 0.5  # Medium
		"plains":
			return 0.3  # Low-medium
		"mountain":
			return 0.2  # Low (trees at lower elevations)
		"coast":
			return 0.1  # Very low
		"desert":
			return 0.05  # Minimal
		"cold_desert":
			return 0.05  # Minimal
		"tundra":
			return 0.1  # Very low
		_:
			return 0.4  # Default medium
