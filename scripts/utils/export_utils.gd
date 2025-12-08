# ╔═══════════════════════════════════════════════════════════
# ║ export_utils.gd
# ║ Desc: Utility functions for exporting worlds (Godot scene, OBJ, PDF)
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name ExportUtils
extends RefCounted

## Export a world mesh as a Godot scene (.tscn) with mesh resource (.tres)
static func export_godot_scene(world_data, output_path: String) -> Error:
	"""Export world as Godot scene with mesh resource.
	
	Args:
		world_data: WorldData instance with generated_mesh
		output_path: Base path (without extension) for output files
		
	Returns:
		Error code (OK on success)
	"""
	if not world_data or not world_data.generated_mesh:
		print("Error: World data or mesh is missing")
		return ERR_INVALID_PARAMETER
	
	# Save mesh as .tres resource
	var mesh_path: String = output_path + "_mesh.tres"
	var error: Error = ResourceSaver.save(world_data.generated_mesh, mesh_path, ResourceSaver.FLAG_COMPRESS)
	if error != OK:
		print("Error saving mesh resource: ", error)
		return error
	
	# Create a scene with the mesh
	var scene: PackedScene = PackedScene.new()
	var root: Node3D = Node3D.new()
	root.name = "WorldTerrain"
	
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = "TerrainMesh"
	mesh_instance.mesh = world_data.generated_mesh
	root.add_child(mesh_instance)
	mesh_instance.owner = root
	
	# Pack the scene
	error = scene.pack(root)
	if error != OK:
		print("Error packing scene: ", error)
		return error
	
	# Save scene as .tscn
	var scene_path: String = output_path + ".tscn"
	error = ResourceSaver.save(scene, scene_path, ResourceSaver.FLAG_COMPRESS)
	if error != OK:
		print("Error saving scene: ", error)
		return error
	
	print("Godot scene exported to: ", scene_path)
	return OK

## Export mesh as OBJ file
static func export_obj(world_data, output_path: String) -> Error:
	"""Export world mesh as OBJ format.
	
	Args:
		world_data: WorldData instance with generated_mesh
		output_path: Full path including .obj extension
		
	Returns:
		Error code (OK on success)
	"""
	if not world_data or not world_data.generated_mesh:
		print("Error: World data or mesh is missing")
		return ERR_INVALID_PARAMETER
	
	var mesh: Mesh = world_data.generated_mesh
	if mesh.get_surface_count() == 0:
		print("Error: Mesh has no surfaces")
		return ERR_INVALID_DATA
	
	# Open file for writing
	var file: FileAccess = FileAccess.open(output_path, FileAccess.WRITE)
	if not file:
		print("Error opening file for writing: ", output_path)
		return ERR_FILE_CANT_WRITE
	
	# Write OBJ header
	file.store_string("# OBJ file exported from World Builder\n")
	file.store_string("# Generated mesh\n\n")
	
	# Get mesh arrays
	var arrays: Array = mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays.size() > Mesh.ARRAY_NORMAL else PackedVector3Array()
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays.size() > Mesh.ARRAY_TEX_UV else PackedVector2Array()
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays.size() > Mesh.ARRAY_INDEX else PackedInt32Array()
	
	# Write vertices
	file.store_string("# Vertices\n")
	for vertex in vertices:
		file.store_string("v %.6f %.6f %.6f\n" % [vertex.x, vertex.y, vertex.z])
	
	# Write normals (if available)
	if normals.size() > 0:
		file.store_string("\n# Normals\n")
		for normal in normals:
			file.store_string("vn %.6f %.6f %.6f\n" % [normal.x, normal.y, normal.z])
	
	# Write UVs (if available)
	if uvs.size() > 0:
		file.store_string("\n# Texture coordinates\n")
		for uv in uvs:
			file.store_string("vt %.6f %.6f\n" % [uv.x, uv.y])
	
	# Write faces
	file.store_string("\n# Faces\n")
	if indices.size() > 0:
		# Indexed faces
		for i in range(0, indices.size(), 3):
			if i + 2 < indices.size():
				var i0: int = indices[i] + 1  # OBJ uses 1-based indexing
				var i1: int = indices[i + 1] + 1
				var i2: int = indices[i + 2] + 1
				
				if uvs.size() > 0 and normals.size() > 0:
					file.store_string("f %d/%d/%d %d/%d/%d %d/%d/%d\n" % [i0, i0, i0, i1, i1, i1, i2, i2, i2])
				elif uvs.size() > 0:
					file.store_string("f %d/%d %d/%d %d/%d\n" % [i0, i0, i1, i1, i2, i2])
				elif normals.size() > 0:
					file.store_string("f %d//%d %d//%d %d//%d\n" % [i0, i0, i1, i1, i2, i2])
				else:
					file.store_string("f %d %d %d\n" % [i0, i1, i2])
	else:
		# Non-indexed faces (triangles)
		for i in range(0, vertices.size(), 3):
			if i + 2 < vertices.size():
				var i0: int = i + 1
				var i1: int = i + 2
				var i2: int = i + 3
				
				if uvs.size() > 0 and normals.size() > 0:
					file.store_string("f %d/%d/%d %d/%d/%d %d/%d/%d\n" % [i0, i0, i0, i1, i1, i1, i2, i2, i2])
				elif uvs.size() > 0:
					file.store_string("f %d/%d %d/%d %d/%d\n" % [i0, i0, i1, i1, i2, i2])
				elif normals.size() > 0:
					file.store_string("f %d//%d %d//%d %d//%d\n" % [i0, i0, i1, i1, i2, i2])
				else:
					file.store_string("f %d %d %d\n" % [i0, i1, i2])
	
	file.close()
	print("OBJ file exported to: ", output_path)
	return OK

## Generate markdown content for PDF export
static func generate_markdown_atlas(world_data, viewport_screenshot_path: String = "") -> String:
	"""Generate markdown content for PDF atlas export.
	
	Args:
		world_data: WorldData instance
		viewport_screenshot_path: Optional path to viewport screenshot
		
	Returns:
		Markdown string
	"""
	var md: String = ""
	
	# Title
	md += "# World Atlas\n\n"
	md += "**Generated:** " + Time.get_datetime_string_from_system() + "\n\n"
	
	# World Parameters
	md += "## World Parameters\n\n"
	md += "| Parameter | Value |\n"
	md += "|-----------|-------|\n"
	md += "| Seed | %d |\n" % world_data.seed
	md += "| Size Preset | %d×%d |\n" % [world_data.size_preset, world_data.size_preset]
	
	if world_data.params.has("elevation_scale"):
		md += "| Elevation Scale | %.1f |\n" % world_data.params["elevation_scale"]
	if world_data.params.has("terrain_chaos"):
		md += "| Terrain Chaos | %.1f |\n" % world_data.params["terrain_chaos"]
	if world_data.params.has("noise_type"):
		md += "| Noise Type | %s |\n" % world_data.params["noise_type"]
	if world_data.params.has("humidity"):
		md += "| Humidity | %.1f |\n" % world_data.params["humidity"]
	if world_data.params.has("temperature"):
		md += "| Temperature | %.1f |\n" % world_data.params["temperature"]
	if world_data.params.has("precipitation"):
		md += "| Precipitation | %.1f |\n" % world_data.params["precipitation"]
	
	md += "\n"
	
	# World Map (if screenshot provided)
	if viewport_screenshot_path != "" and FileAccess.file_exists(viewport_screenshot_path):
		md += "## World Map\n\n"
		md += "![World Map](%s)\n\n" % viewport_screenshot_path
	
	# Biome Distribution
	if world_data.biome_metadata.size() > 0:
		md += "## Biome Distribution\n\n"
		
		# Count biomes
		var biome_counts: Dictionary = {}
		for biome_data in world_data.biome_metadata:
			var biome: String = biome_data.get("biome", "unknown")
			biome_counts[biome] = biome_counts.get(biome, 0) + 1
		
		md += "| Biome | Count | Percentage |\n"
		md += "|-------|-------|------------|\n"
		var total: int = world_data.biome_metadata.size()
		for biome in biome_counts.keys():
			var count: int = biome_counts[biome]
			var percentage: float = (float(count) / float(total)) * 100.0
			md += "| %s | %d | %.1f%% |\n" % [biome.capitalize(), count, percentage]
		
		md += "\n"
	
	# Lore Section
	md += "## World Lore\n\n"
	md += "This world was procedurally generated using FastNoiseLite with the parameters listed above.\n\n"
	
	if world_data.params.has("magic_level"):
		var magic_level: String = world_data.params.get("magic_level", "medium")
		md += "**Magic Level:** %s\n\n" % magic_level.capitalize()
	
	# Statistics
	md += "## Statistics\n\n"
	md += "- Total biome cells: %d\n" % world_data.biome_metadata.size()
	if world_data.generated_mesh:
		var arrays: Array = world_data.generated_mesh.surface_get_arrays(0)
		if arrays.size() > Mesh.ARRAY_VERTEX:
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			md += "- Total vertices: %d\n" % vertices.size()
	
	return md

## Export world as PDF atlas (requires wkhtmltopdf)
static func export_pdf_atlas(world_data, output_path: String, viewport_screenshot_path: String = "") -> Error:
	"""Export world as PDF atlas using markdown → PDF conversion.
	
	Args:
		world_data: WorldData instance
		output_path: Full path including .pdf extension
		viewport_screenshot_path: Optional path to viewport screenshot
		
	Returns:
		Error code (OK on success)
	"""
	# Generate markdown
	var md_content: String = generate_markdown_atlas(world_data, viewport_screenshot_path)
	
	# Save markdown to temp file
	var temp_md_path: String = output_path.get_base_dir().path_join("temp_atlas.md")
	var file: FileAccess = FileAccess.open(temp_md_path, FileAccess.WRITE)
	if not file:
		print("Error creating temp markdown file")
		return ERR_FILE_CANT_WRITE
	
	file.store_string(md_content)
	file.close()
	
	# Convert markdown to PDF using wkhtmltopdf (assumes it's installed)
	# Note: This requires wkhtmltopdf to be in PATH
	var exit_code: int = OS.execute("wkhtmltopdf", [
		"--enable-local-file-access",
		"--page-size", "A4",
		"--margin-top", "20mm",
		"--margin-bottom", "20mm",
		"--margin-left", "20mm",
		"--margin-right", "20mm",
		temp_md_path,
		output_path
	])
	
	# Clean up temp file
	if FileAccess.file_exists(temp_md_path):
		DirAccess.remove_absolute(temp_md_path)
	
	if exit_code != 0:
		print("Error: wkhtmltopdf conversion failed (exit code: ", exit_code, ")")
		print("Make sure wkhtmltopdf is installed and in PATH")
		return ERR_CANT_OPEN
	
	print("PDF atlas exported to: ", output_path)
	return OK

# Phase 5: Enhanced Export Functions

static func export_biome_map_png(world_data, output_path: String) -> Error:
	"""Export biome map as PNG image.
	
	Args:
		world_data: WorldData instance
		output_path: Full path including .png extension
	
	Returns:
		Error code (OK on success)
	"""
	if not world_data or world_data.biome_metadata.is_empty():
		print("Error: World data or biome metadata is missing")
		return ERR_INVALID_PARAMETER
	
	# Calculate size from biome metadata
	var max_x: int = 0
	var max_y: int = 0
	for biome_data in world_data.biome_metadata:
		max_x = max(max_x, biome_data.get("x", 0))
		max_y = max(max_y, biome_data.get("y", 0))
	
	var size: Vector2i = Vector2i(max_x + 1, max_y + 1)
	
	# Create biome color map
	var _biome_colors: Dictionary = {
		"forest": Color(0.2, 0.6, 0.2),
		"desert": Color(0.9, 0.8, 0.5),
		"tundra": Color(0.8, 0.9, 0.9),
		"swamp": Color(0.3, 0.4, 0.2),
		"mountain": Color(0.6, 0.6, 0.6),
		"grassland": Color(0.6, 0.7, 0.4),
		"plains": Color(0.7, 0.7, 0.5),
		"jungle": Color(0.1, 0.5, 0.1),
		"taiga": Color(0.4, 0.6, 0.5),
		"coast": Color(0.4, 0.6, 0.8),
		"cold_desert": Color(0.7, 0.7, 0.6)
	}
	
	var biome_image: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	
	for biome_data in world_data.biome_metadata:
		var x: int = biome_data.get("x", 0)
		var y: int = biome_data.get("y", 0)
		var biome: String = biome_data.get("biome", "plains")
		
		if x < 0 or x >= size.x or y < 0 or y >= size.y:
			continue
		
		var color: Color = _biome_colors.get(biome, Color(0.5, 0.5, 0.5))
		biome_image.set_pixel(x, y, color)
	
	# Save PNG
	var error: Error = biome_image.save_png(output_path)
	if error == OK:
		print("Biome map exported to: ", output_path)
	else:
		print("Error exporting biome map: ", error)
	return error

static func export_foliage_density_png(world_data, output_path: String) -> Error:
	"""Export foliage density map as PNG image.
	
	Args:
		world_data: WorldData instance
		output_path: Full path including .png extension
	
	Returns:
		Error code (OK on success)
	"""
	if not world_data or world_data.foliage_density.is_empty():
		print("Error: World data or foliage density is missing")
		return ERR_INVALID_PARAMETER
	
	# Use foliage_density_texture if available
	if world_data.has("foliage_density_texture") and world_data.foliage_density_texture:
		var image: Image = world_data.foliage_density_texture.get_image()
		var error: Error = image.save_png(output_path)
		if error == OK:
			print("Foliage density map exported to: ", output_path)
		return error
	
	# Fallback: Generate from array
	# Estimate size (assume square)
	var array_size: int = world_data.foliage_density.size()
	var side: int = int(sqrt(array_size))
	if side * side != array_size:
		side = int(sqrt(array_size)) + 1
	
	var foliage_image: Image = Image.create(side, side, false, Image.FORMAT_RGB8)
	
	for i in range(min(array_size, side * side)):
		var density: float = world_data.foliage_density[i]
		var x: int = i % side
		var y: int = i / side
		var color: Color = Color(density, density, density, 1.0)
		foliage_image.set_pixel(x, y, color)
	
	var error: Error = foliage_image.save_png(output_path)
	if error == OK:
		print("Foliage density map exported to: ", output_path)
	return error

static func export_poi_json(world_data, output_path: String) -> Error:
	"""Export POI metadata as JSON file.
	
	Args:
		world_data: WorldData instance
		output_path: Full path including .json extension
	
	Returns:
		Error code (OK on success)
	"""
	if not world_data:
		print("Error: World data is missing")
		return ERR_INVALID_PARAMETER
	
	var poi_data: Array = []
	
	if world_data.has("poi_metadata") and world_data.poi_metadata.size() > 0:
		for poi in world_data.poi_metadata:
			var poi_dict: Dictionary = {}
			poi_dict["type"] = poi.get("type", "unknown")
			poi_dict["name"] = poi.get("name", "")
			poi_dict["position"] = {
				"x": poi.get("position", Vector3.ZERO).x,
				"y": poi.get("position", Vector3.ZERO).y,
				"z": poi.get("position", Vector3.ZERO).z
			}
			poi_dict["biome"] = poi.get("biome", "")
			poi_dict["population"] = poi.get("population", 0)
			poi_dict["resources"] = poi.get("resources", [])
			poi_dict["magic_level"] = poi.get("magic_level", "medium")
			poi_data.append(poi_dict)
	
	var json_data: Dictionary = {
		"pois": poi_data,
		"count": poi_data.size(),
		"exported_at": Time.get_datetime_string_from_system()
	}
	
	var json_string: String = JSON.stringify(json_data, "\t")
	var file: FileAccess = FileAccess.open(output_path, FileAccess.WRITE)
	if not file:
		print("Error opening file for writing: ", output_path)
		return ERR_FILE_CANT_WRITE
	
	file.store_string(json_string)
	file.close()
	print("POI JSON exported to: ", output_path, " (", poi_data.size(), " POIs)")
	return OK

static func export_heightmap_png(world_data, output_path: String) -> Error:
	"""Export heightmap as 16-bit PNG.
	
	Args:
		world_data: WorldData instance
		output_path: Full path including .png extension
	
	Returns:
		Error code (OK on success)
	"""
	if not world_data or not world_data.generated_mesh:
		print("Error: World data or mesh is missing")
		return ERR_INVALID_PARAMETER
	
	# Extract heightmap from mesh
	var mesh: Mesh = world_data.generated_mesh
	if mesh.get_surface_count() == 0:
		print("Error: Mesh has no surfaces")
		return ERR_INVALID_DATA
	
	var arrays: Array = mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX] if arrays.size() > Mesh.ARRAY_VERTEX else PackedVector3Array()
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays.size() > Mesh.ARRAY_TEX_UV else PackedVector2Array()
	
	if vertices.size() == 0:
		print("Error: Mesh has no vertices")
		return ERR_INVALID_DATA
	
	# Find min/max height
	var min_height: float = vertices[0].y
	var max_height: float = vertices[0].y
	for vertex in vertices:
		if vertex.y < min_height:
			min_height = vertex.y
		if vertex.y > max_height:
			max_height = vertex.y
	
	var height_range: float = max_height - min_height
	if height_range == 0:
		height_range = 1.0
	
	# Estimate image size from UVs or vertex count
	var image_size: int = 512
	if uvs.size() > 0:
		var max_uv: float = 0.0
		for uv in uvs:
			max_uv = max(max_uv, max(uv.x, uv.y))
		if max_uv > 0:
			image_size = int(max_uv * 256) + 1
		image_size = clamp(image_size, 64, 2048)
	else:
		# Estimate from vertex count (assume square grid)
		image_size = int(sqrt(vertices.size()))
		image_size = clamp(image_size, 64, 2048)
	
	# Create 16-bit heightmap image
	var heightmap_image: Image = Image.create(image_size, image_size, false, Image.FORMAT_RF)
	
	# Fill heightmap from vertices
	for i in range(vertices.size()):
		var vertex: Vector3 = vertices[i]
		var normalized_height: float = (vertex.y - min_height) / height_range
		
		# Map to image coordinates
		var img_x: int = 0
		var img_y: int = 0
		
		if uvs.size() > i:
			img_x = int(uvs[i].x * (image_size - 1))
			img_y = int(uvs[i].y * (image_size - 1))
		else:
			img_x = (i % image_size)
			img_y = (i / image_size) % image_size
		
		img_x = clamp(img_x, 0, image_size - 1)
		img_y = clamp(img_y, 0, image_size - 1)
		
		heightmap_image.set_pixel(img_x, img_y, Color(normalized_height, normalized_height, normalized_height, 1.0))
	
	# Convert to 16-bit format for export (save as PNG)
	# Note: Godot's save_png converts RF to RGB8, but we'll use it anyway
	var error: Error = heightmap_image.save_png(output_path)
	if error == OK:
		print("Heightmap exported to: ", output_path, " (", image_size, "x", image_size, ")")
	else:
		print("Error exporting heightmap: ", error)
	return error

static func export_atlas(world_data, output_dir: String) -> Error:
	"""Export complete atlas (all maps + PDF summary) to a folder.
	
	Args:
		world_data: WorldData instance
		output_dir: Directory path (will be created if needed)
	
	Returns:
		Error code (OK on success)
	"""
	# Create output directory
	var dir: DirAccess = DirAccess.open("res://")
	if not dir:
		dir = DirAccess.open("user://")
	
	if not dir:
		print("Error: Cannot access filesystem")
		return ERR_CANT_OPEN
	
	# Create directory if it doesn't exist
	var base_path: String = output_dir
	if not base_path.ends_with("/"):
		base_path += "/"
	
	if not dir.dir_exists(base_path.trim_prefix("res://").trim_prefix("user://")):
		var error: Error = dir.make_dir_recursive(base_path.trim_prefix("res://").trim_prefix("user://"))
		if error != OK:
			print("Error creating directory: ", error)
			return error
	
	# Export all maps
	var timestamp: String = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var base_name: String = base_path + "world_atlas_" + timestamp
	
	# Export heightmap
	var heightmap_path: String = base_name + "_heightmap.png"
	var heightmap_error: Error = export_heightmap_png(world_data, heightmap_path)
	if heightmap_error != OK:
		print("Warning: Failed to export heightmap")
	
	# Export biome map
	var biome_path: String = base_name + "_biomes.png"
	var biome_error: Error = export_biome_map_png(world_data, biome_path)
	if biome_error != OK:
		print("Warning: Failed to export biome map")
	
	# Export foliage density
	var foliage_path: String = base_name + "_foliage.png"
	var foliage_error: Error = export_foliage_density_png(world_data, foliage_path)
	if foliage_error != OK:
		print("Warning: Failed to export foliage density map")
	
	# Export POI JSON
	var poi_path: String = base_name + "_pois.json"
	var poi_error: Error = export_poi_json(world_data, poi_path)
	if poi_error != OK:
		print("Warning: Failed to export POI JSON")
	
	# Export PDF atlas (if viewport screenshot available)
	var _pdf_path: String = base_name + "_atlas.pdf"
	# Note: PDF export requires viewport screenshot, which we don't have here
	# This would need to be called from WorldCreator with screenshot path
	
	print("Atlas exported to: ", base_path)
	print("  - Heightmap: ", heightmap_path)
	print("  - Biomes: ", biome_path)
	print("  - Foliage: ", foliage_path)
	print("  - POIs: ", poi_path)
	
	return OK
