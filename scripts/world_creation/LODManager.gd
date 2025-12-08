# ╔═══════════════════════════════════════════════════════════
# ║ LODManager.gd
# ║ Desc: Static functions for LOD mesh creation and chunk blending
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name LODManager
extends RefCounted

"""Static utility class for Level-of-Detail (LOD) mesh generation and chunk management."""

static func create_lod_mesh(heightmap: Array[float], size: Vector2i, lod_level: int, horizontal_scale: float) -> Mesh:
	"""Create a mesh from heightmap with specified LOD level.
	
	Args:
		heightmap: Array of height values (row-major: y * size.x + x)
		size: Original heightmap size (width, height)
		lod_level: LOD level (0 = full res, 1 = half, 2 = quarter, etc.)
		horizontal_scale: World units between vertices
	
	Returns:
		ArrayMesh with line-based network rendering
	"""
	var step: int = 1 << lod_level  # 1, 2, 4, 8, etc.
	var lod_size: Vector2i = Vector2i(
		(size.x + step - 1) / step,  # Ceiling division
		(size.y + step - 1) / step
	)
	
	# Create SurfaceTool for line-based network
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	
	# Calculate half-dimensions for centering
	var half_width: float = (lod_size.x - 1) * horizontal_scale * 0.5
	var half_height: float = (lod_size.y - 1) * horizontal_scale * 0.5
	
	# Generate vertices with downsampled heightmap
	var vertex_positions: Array[Vector3] = []
	vertex_positions.resize(lod_size.x * lod_size.y)
	
	for y in range(lod_size.y):
		for x in range(lod_size.x):
			var src_x: int = x * step
			var src_y: int = y * step
			
			# Clamp to original heightmap bounds
			src_x = clamp(src_x, 0, size.x - 1)
			src_y = clamp(src_y, 0, size.y - 1)
			
			var src_idx: int = src_y * size.x + src_x
			var height: float = heightmap[src_idx] if src_idx < heightmap.size() else 0.0
			
			# Position in world space
			var pos_x: float = x * horizontal_scale * step - half_width
			var pos_z: float = y * horizontal_scale * step - half_height
			var vertex_pos: Vector3 = Vector3(pos_x, height, pos_z)
			vertex_positions[y * lod_size.x + x] = vertex_pos
			
			# UV coordinates
			var uv_x: float = float(x) / float(lod_size.x - 1) if lod_size.x > 1 else 0.0
			var uv_y: float = float(y) / float(lod_size.y - 1) if lod_size.y > 1 else 0.0
			
			st.set_uv(Vector2(uv_x, uv_y))
			st.add_vertex(vertex_pos)
	
	# Generate lines for network effect (horizontal, vertical, diagonal)
	var line_count: int = 0
	
	# Horizontal lines
	for y in range(lod_size.y):
		for x in range(lod_size.x - 1):
			var i: int = y * lod_size.x + x
			var i_right: int = i + 1
			st.add_index(i)
			st.add_index(i_right)
			line_count += 1
	
	# Vertical lines
	for y in range(lod_size.y - 1):
		for x in range(lod_size.x):
			var i: int = y * lod_size.x + x
			var i_bottom: int = i + lod_size.x
			st.add_index(i)
			st.add_index(i_bottom)
			line_count += 1
	
	# Diagonal lines (both diagonals per quad)
	for y in range(lod_size.y - 1):
		for x in range(lod_size.x - 1):
			var i: int = y * lod_size.x + x
			var i_bottom_right: int = i + lod_size.x + 1
			var i_bottom: int = i + lod_size.x
			var i_right: int = i + 1
			
			# First diagonal: top-left to bottom-right
			st.add_index(i)
			st.add_index(i_bottom_right)
			
			# Second diagonal: top-right to bottom-left
			st.add_index(i_right)
			st.add_index(i_bottom)
			
			line_count += 2
	
	return st.commit()

static func downsample_heightmap(heightmap: Array[float], size: Vector2i, lod_level: int) -> Array[float]:
	"""Downsample heightmap for lower LOD levels.
	
	Args:
		heightmap: Original heightmap array
		size: Original size
		lod_level: LOD level (0 = full, 1 = half, 2 = quarter)
	
	Returns:
		Downsampled heightmap array
	"""
	var step: int = 1 << lod_level
	var lod_size: Vector2i = Vector2i(
		(size.x + step - 1) / step,
		(size.y + step - 1) / step
	)
	
	var lod_heightmap: Array[float] = []
	lod_heightmap.resize(lod_size.x * lod_size.y)
	
	for y in range(lod_size.y):
		for x in range(lod_size.x):
			var src_x: int = x * step
			var src_y: int = y * step
			
			# Clamp to original bounds
			src_x = clamp(src_x, 0, size.x - 1)
			src_y = clamp(src_y, 0, size.y - 1)
			
			var src_idx: int = src_y * size.x + src_x
			lod_heightmap[y * lod_size.x + x] = heightmap[src_idx] if src_idx < heightmap.size() else 0.0
	
	return lod_heightmap

static func get_lod_for_distance(distance: float, lod_distances: Array[float]) -> int:
	"""Get LOD level based on camera distance.
	
	Args:
		distance: Distance from camera to chunk center
		lod_distances: Array of distance thresholds (e.g., [500.0, 2000.0])
	
	Returns:
		LOD level (0 = closest, higher = farther)
	"""
	if lod_distances.is_empty():
		return 0
	
	for i in range(lod_distances.size()):
		if distance < lod_distances[i]:
			return i
	
	# Farther than all thresholds, use highest LOD
	return lod_distances.size()

static func create_chunk_key(chunk_x: int, chunk_y: int) -> String:
	"""Create a unique key for a chunk.
	
	Args:
		chunk_x: Chunk X coordinate
		chunk_y: Chunk Y coordinate
	
	Returns:
		Unique string key for chunk
	"""
	return "chunk_%d_%d" % [chunk_x, chunk_y]
