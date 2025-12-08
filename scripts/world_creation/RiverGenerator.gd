# ╔═══════════════════════════════════════════════════════════
# ║ RiverGenerator.gd
# ║ Desc: River system generation using AStar2D pathfinding
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════
class_name RiverGenerator
extends RefCounted

## Generate river paths from high to low elevation.
##
## Args:
## 	heightmap: Array of height values (row-major: y * size.x + x)
## 	size: Grid dimensions (width, height)
## 	carve: If true, carve rivers into heightmap (default: true)
##
## Returns:
## 	Array of river paths, each path is Array[Vector2i] of cell coordinates
static func generate_rivers(heightmap: Array[float], size: Vector2i, carve: bool = true) -> Array:
	var river_paths: Array = []
	
	# Find starting points (high elevation with slope)
	var start_points: Array = _find_river_starts(heightmap, size, 5)  # Find 5 starting points
	
	# Generate main rivers
	for start_point in start_points:
		var path: Array[Vector2i] = _find_river_path(heightmap, size, start_point)
		if path.size() > 10:  # Only keep rivers with minimum length
			river_paths.append(path)
	
	# Generate tributaries (branch from main rivers)
	var tributary_paths: Array = _generate_tributaries(heightmap, size, river_paths, 3)
	river_paths.append_array(tributary_paths)
	
	# Carve rivers into heightmap if requested
	if carve:
		_carve_rivers(heightmap, size, river_paths)
	
	return river_paths

## Find potential river starting points (high elevation, good slope).
static func _find_river_starts(heightmap: Array[float], size: Vector2i, count: int) -> Array:
	var starts: Array = []
	var candidates: Array = []
	
	# Sample grid points, prefer high elevation with slope
	for y in range(10, size.y - 10, 20):  # Sample every 20 cells
		for x in range(10, size.x - 10, 20):
			var idx: int = y * size.x + x
			var height: float = heightmap[idx]
			
			# Check if has good slope (downhill neighbor)
			var has_slope: bool = false
			var neighbors: Array = [
				Vector2i(x, y - 1),
				Vector2i(x, y + 1),
				Vector2i(x - 1, y),
				Vector2i(x + 1, y)
			]
			
			for neighbor in neighbors:
				if neighbor.x < 0 or neighbor.x >= size.x or neighbor.y < 0 or neighbor.y >= size.y:
					continue
				var n_idx: int = neighbor.y * size.x + neighbor.x
				if heightmap[n_idx] < height - 1.0:  # Has downhill
					has_slope = true
					break
			
			if has_slope:
				candidates.append({"pos": Vector2i(x, y), "height": height})
	
	# Sort by height (highest first) and take top candidates
	candidates.sort_custom(func(a, b): return a["height"] > b["height"])
	
	for i in range(min(count, candidates.size())):
		starts.append(candidates[i]["pos"])
	
	return starts

## Find river path using AStar2D pathfinding.
static func _find_river_path(heightmap: Array[float], size: Vector2i, start: Vector2i) -> Array:
	var astar: AStar2D = AStar2D.new()
	
	# Add all points to AStar
	var point_ids: Dictionary = {}
	var id_counter: int = 0
	
	for y in range(size.y):
		for x in range(size.x):
			var pos: Vector2i = Vector2i(x, y)
			var id: int = id_counter
			point_ids[pos] = id
			astar.add_point(id, Vector2(x, y))
			id_counter += 1
	
	# Connect neighbors (4-directional)
	for y in range(size.y):
		for x in range(size.x):
			var pos: Vector2i = Vector2i(x, y)
			var id: int = point_ids[pos]
			var height: float = heightmap[y * size.x + x]
			
			var neighbors: Array[Vector2i] = [
				Vector2i(x, y - 1),  # North
				Vector2i(x, y + 1),  # South
				Vector2i(x - 1, y),  # West
				Vector2i(x + 1, y)   # East
			]
			
			for neighbor in neighbors:
				if neighbor.x < 0 or neighbor.x >= size.x or neighbor.y < 0 or neighbor.y >= size.y:
					continue
				
				var n_id: int = point_ids[neighbor]
				var n_height: float = heightmap[neighbor.y * size.x + neighbor.x]
				
				# Cost based on height difference (prefer downhill)
				var height_diff: float = n_height - height
				var cost: float = 1.0
				
				if height_diff < 0:  # Downhill - very cheap
					cost = 0.1
				elif height_diff > 5.0:  # Uphill - expensive
					cost = 10.0
				else:  # Flat or slight uphill
					cost = 1.0 + height_diff * 0.5
				
				astar.connect_points(id, n_id, false)  # Bidirectional
				astar.set_point_weight_scale(id, cost)
	
	# Find lowest point as goal (or edge of map)
	var goal: Vector2i = _find_lowest_point(heightmap, size, start)
	
	# Get path
	var start_id: int = point_ids[start]
	var goal_id: int = point_ids[goal]
	var path_points: PackedVector2Array = astar.get_point_path(start_id, goal_id)
	
	# Convert to Vector2i array
	var path: Array[Vector2i] = []
	for point in path_points:
		path.append(Vector2i(int(point.x), int(point.y)))
	
	return path

## Find lowest point near start (for river destination).
static func _find_lowest_point(heightmap: Array[float], size: Vector2i, start: Vector2i) -> Vector2i:
	var lowest_pos: Vector2i = start
	var lowest_height: float = heightmap[start.y * size.x + start.x]
	
	# Search in a radius around start, or find edge
	var search_radius: int = min(size.x, size.y) / 4
	
	for y in range(max(0, start.y - search_radius), min(size.y, start.y + search_radius)):
		for x in range(max(0, start.x - search_radius), min(size.x, start.x + search_radius)):
			var idx: int = y * size.x + x
			var height: float = heightmap[idx]
			
			if height < lowest_height:
				lowest_height = height
				lowest_pos = Vector2i(x, y)
	
	# If no lower point found, use edge of map
	if lowest_pos == start:
		# Find edge with lowest height
		for y in [0, size.y - 1]:
			for x in range(size.x):
				var idx: int = y * size.x + x
				var height: float = heightmap[idx]
				if height < lowest_height:
					lowest_height = height
					lowest_pos = Vector2i(x, y)
		
		for x in [0, size.x - 1]:
			for y in range(size.y):
				var idx: int = y * size.x + x
				var height: float = heightmap[idx]
				if height < lowest_height:
					lowest_height = height
					lowest_pos = Vector2i(x, y)
	
	return lowest_pos

## Generate tributaries branching from main rivers.
static func _generate_tributaries(heightmap: Array[float], size: Vector2i, main_rivers: Array, count: int) -> Array:
	var tributaries: Array = []
	
	for river_path in main_rivers:
		# Try to branch from points along the river
		for i in range(0, river_path.size(), max(1, river_path.size() / count)):
			if randf() < 0.3:  # 30% chance to branch
				var branch_point: Vector2i = river_path[i]
				
				# Find nearby high point for tributary start
				var start: Vector2i = _find_nearby_high_point(heightmap, size, branch_point, 20)
				
				if start != branch_point:
					var path: Array = _find_river_path(heightmap, size, start)
					# Connect to main river
					if path.size() > 5:
						# Extend path to meet main river
						var last_point: Vector2i = path[path.size() - 1] as Vector2i
						var nearest_river_point: Vector2i = _find_nearest_river_point(last_point, river_path)
						path.append(nearest_river_point)
						tributaries.append(path)
	
	return tributaries

## Find nearby high point for tributary start.
static func _find_nearby_high_point(heightmap: Array[float], size: Vector2i, center: Vector2i, radius: int) -> Vector2i:
	var best_pos: Vector2i = center
	var best_height: float = heightmap[center.y * size.x + center.x]
	
	for y in range(max(0, center.y - radius), min(size.y, center.y + radius)):
		for x in range(max(0, center.x - radius), min(size.x, center.x + radius)):
			var idx: int = y * size.x + x
			var height: float = heightmap[idx]
			
			if height > best_height:
				best_height = height
				best_pos = Vector2i(x, y)
	
	return best_pos

## Find nearest point on river path.
static func _find_nearest_river_point(pos: Vector2i, river_path: Array) -> Vector2i:
	var nearest: Vector2i = river_path[0]
	var min_dist: float = pos.distance_to(nearest)
	
	for point in river_path:
		var dist: float = pos.distance_to(point)
		if dist < min_dist:
			min_dist = dist
			nearest = point
	
	return nearest

## Carve rivers into heightmap (subtract depth).
static func _carve_rivers(heightmap: Array[float], size: Vector2i, river_paths: Array) -> void:
	# Track flow accumulation for width calculation
	var flow_accumulation: Dictionary = {}
	
	# Count how many rivers pass through each cell
	for river_path in river_paths:
		for point in river_path:
			var key: String = str(point.x) + "," + str(point.y)
			if not flow_accumulation.has(key):
				flow_accumulation[key] = 0
			flow_accumulation[key] += 1
	
	# Carve based on accumulation (more flow = wider/deeper)
	for river_path in river_paths:
		for point in river_path:
			if point.x < 0 or point.x >= size.x or point.y < 0 or point.y >= size.y:
				continue
			
			var idx: int = point.y * size.x + point.x
			var key: String = str(point.x) + "," + str(point.y)
			var flow: int = flow_accumulation.get(key, 1)
			
			# Depth based on flow (more flow = deeper, but cap it)
			var depth: float = 2.0 + float(flow) * 0.5
			depth = min(depth, 10.0)  # Max depth
			
			# Carve river (subtract from height)
			heightmap[idx] -= depth
			
			# Also carve neighbors slightly for width
			var neighbors: Array[Vector2i] = [
				Vector2i(point.x, point.y - 1),
				Vector2i(point.x, point.y + 1),
				Vector2i(point.x - 1, point.y),
				Vector2i(point.x + 1, point.y)
			]
			
			for neighbor in neighbors:
				if neighbor.x >= 0 and neighbor.x < size.x and neighbor.y >= 0 and neighbor.y < size.y:
					var n_idx: int = neighbor.y * size.x + neighbor.x
					heightmap[n_idx] -= depth * 0.3  # Carve edges less

## Get river width at a cell (based on flow accumulation).
static func get_river_width(x: int, y: int, river_paths: Array) -> float:
	var flow: int = 0
	var point: Vector2i = Vector2i(x, y)
	
	for river_path in river_paths:
		if point in river_path:
			flow += 1
	
	# Width: base 1.0 + flow accumulation
	return 1.0 + float(flow) * 0.5

## Check if a cell is on a river.
static func is_river_cell(x: int, y: int, river_paths: Array) -> bool:
	var point: Vector2i = Vector2i(x, y)
	
	for river_path in river_paths:
		if point in river_path:
			return true
	
	return false
