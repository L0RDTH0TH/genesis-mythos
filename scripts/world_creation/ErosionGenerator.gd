# ╔═══════════════════════════════════════════════════════════
# ║ ErosionGenerator.gd
# ║ Desc: Hydrological erosion simulation (thermal + hydraulic)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
class_name ErosionGenerator
extends RefCounted

## Apply erosion simulation to heightmap.
## 
## Args:
## 	heightmap: Array of height values (row-major: y * size.x + x)
## 	size: Grid dimensions (width, height)
## 	strength: Erosion strength (0.0 to 1.0)
## 	iterations: Number of erosion passes (1-10)
##
## Returns:
## 	Modified heightmap array
static func apply_erosion(heightmap: Array[float], size: Vector2i, strength: float, iterations: int) -> Array[float]:
	var result: Array[float] = heightmap.duplicate()
	
	# Thermal erosion: slope-based material movement
	_apply_thermal_erosion(result, size, strength, iterations)
	
	# Hydraulic erosion: water particle simulation
	_apply_hydraulic_erosion(result, size, strength, iterations)
	
	return result

## Thermal erosion: material moves downhill based on slope.
static func _apply_thermal_erosion(heightmap: Array[float], size: Vector2i, strength: float, iterations: int) -> void:
	var thermal_strength: float = strength * 0.3  # Thermal is gentler
	var talus_angle: float = 0.5  # Slope threshold (radians, ~28 degrees)
	
	for iteration in range(iterations):
		var new_heightmap: Array[float] = heightmap.duplicate()
		
		for y in range(1, size.y - 1):
			for x in range(1, size.x - 1):
				var idx: int = y * size.x + x
				var current_height: float = heightmap[idx]
				
				# Check 4 neighbors (N, S, E, W)
				var neighbors: Array[Vector2i] = [
					Vector2i(x, y - 1),  # North
					Vector2i(x, y + 1),  # South
					Vector2i(x - 1, y),  # West
					Vector2i(x + 1, y)   # East
				]
				
				var steepest_direction: Vector2i = Vector2i.ZERO
				var max_slope: float = 0.0
				
				# Find steepest downhill direction
				for neighbor in neighbors:
					if neighbor.x < 0 or neighbor.x >= size.x or neighbor.y < 0 or neighbor.y >= size.y:
						continue
					
					var n_idx: int = neighbor.y * size.x + neighbor.x
					var neighbor_height: float = heightmap[n_idx]
					var height_diff: float = current_height - neighbor_height
					
					if height_diff > 0:  # Downhill
						var distance: float = 1.0  # Grid distance
						var slope: float = height_diff / distance
						
						if slope > max_slope:
							max_slope = slope
							steepest_direction = neighbor
				
				# Move material if slope exceeds talus angle
				if max_slope > talus_angle and steepest_direction != Vector2i.ZERO:
					var move_amount: float = (max_slope - talus_angle) * thermal_strength * 0.1
					move_amount = clamp(move_amount, 0.0, current_height * 0.1)  # Limit movement
					
					var n_idx: int = steepest_direction.y * size.x + steepest_direction.x
					new_heightmap[idx] -= move_amount
					new_heightmap[n_idx] += move_amount
		
		# Update heightmap for next iteration
		for i in range(heightmap.size()):
			heightmap[i] = new_heightmap[i]

## Hydraulic erosion: water particles erode and deposit sediment.
static func _apply_hydraulic_erosion(heightmap: Array[float], size: Vector2i, strength: float, iterations: int) -> void:
	var particle_count: int = int(size.x * size.y * 0.1)  # 10% of cells
	particle_count = clamp(particle_count, 100, 5000)  # Reasonable range
	
	for iteration in range(iterations):
		# Drop particles from random high points
		for particle_idx in range(particle_count):
			# Random starting position (prefer higher elevations)
			var start_x: int = randi_range(0, size.x - 1)
			var start_y: int = randi_range(0, size.y - 1)
			
			var x: float = float(start_x)
			var y: float = float(start_y)
			var water: float = 1.0  # Water volume
			var sediment: float = 0.0  # Carried sediment
			var velocity: Vector2 = Vector2.ZERO
			
			var max_steps: int = 100  # Prevent infinite loops
			var step: int = 0
			
			# Simulate particle flow
			while step < max_steps and water > 0.01:
				# Check bounds
				if x < 1.0 or x >= float(size.x - 1) or y < 1.0 or y >= float(size.y - 1):
					break
				
				# Get height at current position (bilinear interpolation)
				var h: float = _get_height_interpolated(heightmap, size, x, y)
				
				# Calculate gradient (steepest descent direction)
				var h_left: float = _get_height_interpolated(heightmap, size, x - 1.0, y)
				var h_right: float = _get_height_interpolated(heightmap, size, x + 1.0, y)
				var h_up: float = _get_height_interpolated(heightmap, size, x, y - 1.0)
				var h_down: float = _get_height_interpolated(heightmap, size, x, y + 1.0)
				
				var gradient_x: float = (h_right - h_left) * 0.5
				var gradient_y: float = (h_down - h_up) * 0.5
				var gradient: Vector2 = Vector2(gradient_x, gradient_y)
				
				# Update velocity (gravity + momentum)
				velocity = velocity * 0.9 + gradient * 0.1
				
				# Erode: pick up sediment based on velocity and capacity
				var capacity: float = length(velocity) * water * 0.1
				var erosion_amount: float = min((capacity - sediment) * strength * 0.1, h * 0.01)
				erosion_amount = max(erosion_amount, 0.0)
				
				# Update heightmap (erode)
				var idx: int = int(y) * size.x + int(x)
				heightmap[idx] -= erosion_amount
				sediment += erosion_amount
				
				# Deposit: if capacity < sediment, deposit excess
				if capacity < sediment:
					var deposit_amount: float = (sediment - capacity) * 0.5
					heightmap[idx] += deposit_amount
					sediment -= deposit_amount
				
				# Move particle
				x += velocity.x * 0.5
				y += velocity.y * 0.5
				
				# Evaporation
				water *= 0.99
				step += 1

## Get interpolated height at fractional coordinates.
static func _get_height_interpolated(heightmap: Array[float], size: Vector2i, x: float, y: float) -> float:
	var x0: int = int(floor(x))
	var y0: int = int(floor(y))
	var x1: int = min(x0 + 1, size.x - 1)
	var y1: int = min(y0 + 1, size.y - 1)
	
	var fx: float = x - float(x0)
	var fy: float = y - float(y0)
	
	var h00: float = heightmap[y0 * size.x + x0]
	var h10: float = heightmap[y0 * size.x + x1]
	var h01: float = heightmap[y1 * size.x + x0]
	var h11: float = heightmap[y1 * size.x + x1]
	
	# Bilinear interpolation
	var h0: float = lerp(h00, h10, fx)
	var h1: float = lerp(h01, h11, fx)
	return lerp(h0, h1, fy)
