# ╔═══════════════════════════════════════════════════════════
# ║ CharacterPreview3D.gd
# ║ Desc: Full real-time 3D character preview with morph targets and attachment system
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

@tool
extends SubViewport

class_name CharacterPreview3D

@export var current_race: String = "human"
@export var current_gender: String = "male"

@onready var character_root: Node3D = $CharacterRoot
@onready var skeleton: Skeleton3D = $CharacterRoot/CharacterSkeleton
@onready var body_mesh: MeshInstance3D = $CharacterRoot/CharacterSkeleton/BodyMesh
@onready var camera: Camera3D = $PreviewCamera

var morph_targets: Dictionary = {}
var current_sliders: Dictionary = {}

signal preview_ready()

func _ready() -> void:
	load_base_model()
	preview_ready.emit()

func load_base_model() -> void:
	"""Load the base model for current race and gender - tries .glb first, then .tscn"""
	var glb_path := "res://assets/models/character_bases/%s-body-%s.glb" % [current_race, current_gender]
	var tscn_path := "res://assets/models/character_bases/%s-body-%s.tscn" % [current_race, current_gender]
	
	var path: String = ""
	var scene: PackedScene = null
	
	# Try .glb first - attempt to load directly (ResourceLoader.exists may not work for GLB)
	var glb_resource = load(glb_path)
	if glb_resource:
		scene = glb_resource as PackedScene
		if scene:
			path = glb_path
			Logger.debug("CharacterPreview3D: Found .glb model: " + path, "character_creation")
		else:
			Logger.debug("CharacterPreview3D: GLB file exists but is not a PackedScene: " + glb_path, "character_creation")
	else:
		Logger.debug("CharacterPreview3D: Could not load GLB file: " + glb_path, "character_creation")
	
	# Fall back to .tscn if .glb not found or failed to load
	if not scene:
		var tscn_resource = load(tscn_path)
		if tscn_resource:
			scene = tscn_resource as PackedScene
			if scene:
				path = tscn_path
				Logger.debug("CharacterPreview3D: Found .tscn model: " + path, "character_creation")
			else:
				Logger.debug("CharacterPreview3D: TSCN file exists but is not a PackedScene: " + tscn_path, "character_creation")
		else:
			Logger.debug("CharacterPreview3D: Could not load TSCN file: " + tscn_path, "character_creation")
	
	# If still no model, create placeholder
	if not scene:
		Logger.warning("CharacterPreview3D: Base model not found - tried %s and %s, using placeholder" % [glb_path, tscn_path], "character_creation")
		_create_placeholder_mesh()
		return
	
	# Clear all existing character model children
	for child in character_root.get_children():
		child.queue_free()
	
	# Instantiate the new rigged model
	var instance = scene.instantiate()
	character_root.add_child(instance)
	
	# Update skeleton and mesh references from the loaded Rigify model
	_update_skeleton_references()
	
	# Optional: Find and play idle animation if available
	var anim_player: AnimationPlayer = character_root.find_child("AnimationPlayer", true, false)
	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")

func _create_placeholder_mesh() -> void:
	"""Create a simple placeholder mesh for testing when model files are not available"""
	Logger.debug("CharacterPreview3D: Creating placeholder mesh", "character_creation")
	
	# Clear existing children
	for child in character_root.get_children():
		child.queue_free()
	
	# Create a simple capsule mesh as placeholder
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = 0.3
	capsule_mesh.height = 1.6
	
	# Create a simple material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.7, 0.6, 1.0)  # Skin tone
	
	# Create MeshInstance3D node
	var placeholder_mesh = MeshInstance3D.new()
	placeholder_mesh.name = "PlaceholderBody"
	placeholder_mesh.mesh = capsule_mesh
	placeholder_mesh.material_override = material
	
	# Add to character root
	character_root.add_child(placeholder_mesh)
	
	# Update body_mesh reference for compatibility
	body_mesh = placeholder_mesh
	
	Logger.info("CharacterPreview3D: Placeholder mesh created", "character_creation")

func _update_skeleton_references() -> void:
	"""Update skeleton and mesh references after loading Rigify-rigged model"""
	# Find skeleton in the loaded model (Rigify creates armatures with various naming patterns)
	var found_skeleton: Skeleton3D = null
	
	# Search recursively for any Skeleton3D node
	found_skeleton = _find_skeleton_recursive(character_root)
	
	if found_skeleton:
		skeleton = found_skeleton
		var bone_count = skeleton.get_bone_count()
		print("CharacterPreview3D: Found skeleton '%s' with %d bones" % [skeleton.name, bone_count])
		Logger.debug("CharacterPreview3D: Loaded rigged %s %s - %d bones" % [current_race.capitalize(), current_gender.capitalize(), bone_count], "character_creation")
	
	# Find body mesh - look for MeshInstance3D that's not a widget/deform helper
	var found_body: MeshInstance3D = null
	found_body = _find_mesh_recursive(character_root)
	
	if found_body:
		body_mesh = found_body
		print("CharacterPreview3D: Found body mesh: ", body_mesh.name)

func _find_skeleton_recursive(node: Node) -> Skeleton3D:
	"""Recursively search for a Skeleton3D node"""
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result = _find_skeleton_recursive(child)
		if result:
			return result
	return null

func _find_mesh_recursive(node: Node) -> MeshInstance3D:
	"""Recursively search for a MeshInstance3D node (skip widgets/deform helpers)"""
	if node is MeshInstance3D:
		# Skip Rigify widget/deform helpers (they contain WGT or DEF in name)
		if not ("WGT" in node.name or "DEF" in node.name):
			return node
	for child in node.get_children():
		var result = _find_mesh_recursive(child)
		if result:
			return result
	return null

func apply_slider(id: String, value: float) -> void:
	"""Apply a slider value to morph the character in real-time"""
	current_sliders[id] = value
	
	# === REAL-TIME MORPH BINDINGS ===
	match id:
		"height":
			if character_root:
				character_root.scale = Vector3(1, 1, 1) * lerp(0.9, 1.1, value)
		"weight":
			if body_mesh:
				body_mesh.scale.x = lerp(0.9, 1.2, value)
		"muscle":
			if body_mesh:
				body_mesh.scale = Vector3(lerp(1.0, 1.15, value), 1, lerp(1.0, 1.15, value))
		"head_size":
			if skeleton:
				var head_bone = skeleton.find_bone("Head")
				if head_bone >= 0:
					skeleton.set_bone_pose_scale(head_bone, Vector3.ONE * lerp(0.9, 1.1, value))
		"horn_length":
			if current_race == "tiefling":
				var horns = character_root.get_node_or_null("HornsMesh")
				if horns:
					horns.scale = Vector3.ONE * value
		"head_width":
			if skeleton:
				var head_bone = skeleton.find_bone("Head")
				if head_bone >= 0:
					var current_scale = skeleton.get_bone_pose_scale(head_bone)
					skeleton.set_bone_pose_scale(head_bone, Vector3(lerp(0.9, 1.1, value), current_scale.y, current_scale.z))
		"head_height":
			if skeleton:
				var head_bone = skeleton.find_bone("Head")
				if head_bone >= 0:
					var current_scale = skeleton.get_bone_pose_scale(head_bone)
					skeleton.set_bone_pose_scale(head_bone, Vector3(current_scale.x, lerp(0.9, 1.1, value), current_scale.z))
		"head_depth":
			if skeleton:
				var head_bone = skeleton.find_bone("Head")
				if head_bone >= 0:
					var current_scale = skeleton.get_bone_pose_scale(head_bone)
					skeleton.set_bone_pose_scale(head_bone, Vector3(current_scale.x, current_scale.y, lerp(0.9, 1.1, value)))
		"neck_length":
			if skeleton:
				var neck_bone = skeleton.find_bone("Neck")
				if neck_bone >= 0:
					skeleton.set_bone_pose_scale(neck_bone, Vector3(1, lerp(0.9, 1.1, value), 1))
		"shoulder_width":
			if skeleton:
				var shoulder_bone = skeleton.find_bone("Shoulder")
				if shoulder_bone >= 0:
					skeleton.set_bone_pose_scale(shoulder_bone, Vector3(lerp(0.9, 1.1, value), 1, 1))
		"chest_width":
			if body_mesh:
				var current_scale = body_mesh.scale
				body_mesh.scale = Vector3(lerp(0.9, 1.15, value), current_scale.y, current_scale.z)
		"waist_width":
			if body_mesh:
				var current_scale = body_mesh.scale
				body_mesh.scale = Vector3(lerp(0.9, 1.1, value), current_scale.y, current_scale.z)
		"hip_width":
			if body_mesh:
				var current_scale = body_mesh.scale
				body_mesh.scale = Vector3(lerp(0.9, 1.1, value), current_scale.y, current_scale.z)
		"arm_length":
			if skeleton:
				var arm_bone = skeleton.find_bone("Arm")
				if arm_bone >= 0:
					skeleton.set_bone_pose_scale(arm_bone, Vector3(1, lerp(0.9, 1.1, value), 1))
		"leg_length":
			if skeleton:
				var leg_bone = skeleton.find_bone("Leg")
				if leg_bone >= 0:
					skeleton.set_bone_pose_scale(leg_bone, Vector3(1, lerp(0.9, 1.1, value), 1))
		"foot_size":
			if skeleton:
				var foot_bone = skeleton.find_bone("Foot")
				if foot_bone >= 0:
					skeleton.set_bone_pose_scale(foot_bone, Vector3(lerp(0.9, 1.1, value), 1, lerp(0.9, 1.1, value)))
		"nose_size":
			if skeleton:
				var nose_bone = skeleton.find_bone("Nose")
				if nose_bone >= 0:
					skeleton.set_bone_pose_scale(nose_bone, Vector3.ONE * lerp(0.9, 1.1, value))
		"eye_size":
			if skeleton:
				var eye_bone = skeleton.find_bone("Eye")
				if eye_bone >= 0:
					skeleton.set_bone_pose_scale(eye_bone, Vector3.ONE * lerp(0.9, 1.1, value))
		"mouth_size":
			if skeleton:
				var mouth_bone = skeleton.find_bone("Mouth")
				if mouth_bone >= 0:
					skeleton.set_bone_pose_scale(mouth_bone, Vector3.ONE * lerp(0.9, 1.1, value))
		"ear_size":
			if skeleton:
				var ear_bone = skeleton.find_bone("Ear")
				if ear_bone >= 0:
					skeleton.set_bone_pose_scale(ear_bone, Vector3.ONE * lerp(0.9, 1.1, value))
		"jaw_width":
			if skeleton:
				var jaw_bone = skeleton.find_bone("Jaw")
				if jaw_bone >= 0:
					skeleton.set_bone_pose_scale(jaw_bone, Vector3(lerp(0.9, 1.1, value), 1, 1))
		"cheekbone_height":
			if skeleton:
				var cheek_bone = skeleton.find_bone("Cheek")
				if cheek_bone >= 0:
					skeleton.set_bone_pose_scale(cheek_bone, Vector3(1, lerp(0.9, 1.1, value), 1))
		"brow_height":
			if skeleton:
				var brow_bone = skeleton.find_bone("Brow")
				if brow_bone >= 0:
					skeleton.set_bone_pose_scale(brow_bone, Vector3(1, lerp(0.9, 1.1, value), 1))
		"chin_height":
			if skeleton:
				var chin_bone = skeleton.find_bone("Chin")
				if chin_bone >= 0:
					skeleton.set_bone_pose_scale(chin_bone, Vector3(1, lerp(0.9, 1.1, value), 1))
		"lip_fullness":
			if skeleton:
				var lip_bone = skeleton.find_bone("Lip")
				if lip_bone >= 0:
					skeleton.set_bone_pose_scale(lip_bone, Vector3(1, lerp(0.7, 1.4, value), 1))
		"lip_thickness":
			if skeleton:
				var lip_bone = skeleton.find_bone("Lip")
				if lip_bone >= 0:
					skeleton.set_bone_pose_scale(lip_bone, Vector3(1, lerp(0.7, 1.4, value), 1))
		"body_fat":
			if body_mesh:
				var current_scale = body_mesh.scale
				body_mesh.scale = Vector3(lerp(0.9, 1.2, value), lerp(0.9, 1.2, value), lerp(0.9, 1.2, value))
		"chin_prominence":
			if skeleton:
				var chin_bone = skeleton.find_bone("Chin")
				if chin_bone >= 0:
					skeleton.set_bone_pose_scale(chin_bone, Vector3(1, lerp(0.7, 1.4, value), lerp(0.7, 1.4, value)))
		"cheek_bones":
			if skeleton:
				var cheek_bone = skeleton.find_bone("Cheek")
				if cheek_bone >= 0:
					skeleton.set_bone_pose_scale(cheek_bone, Vector3(lerp(0.7, 1.4, value), lerp(0.7, 1.4, value), 1))
		"eye_distance":
			if skeleton:
				var eye_bone = skeleton.find_bone("Eye")
				if eye_bone >= 0:
					# Move eyes apart/closer
					var current_pos = skeleton.get_bone_pose_position(eye_bone)
					skeleton.set_bone_pose_position(eye_bone, Vector3(lerp(-0.1, 0.1, value), current_pos.y, current_pos.z))
		"mouth_width":
			if skeleton:
				var mouth_bone = skeleton.find_bone("Mouth")
				if mouth_bone >= 0:
					skeleton.set_bone_pose_scale(mouth_bone, Vector3(lerp(0.85, 1.15, value), 1, 1))
		"snout_length":
			if current_race == "dragonborn":
				if skeleton:
					var snout_bone = skeleton.find_bone("Snout")
					if snout_bone >= 0:
						skeleton.set_bone_pose_scale(snout_bone, Vector3(1, 1, lerp(0.8, 1.4, value)))
		"ear_length":
			if current_race == "drow":
				if skeleton:
					var ear_bone = skeleton.find_bone("Ear")
					if ear_bone >= 0:
						skeleton.set_bone_pose_scale(ear_bone, Vector3(1, lerp(1.0, 1.8, value), 1))
		_:
			# Generic fallback for any unmapped slider
			pass
	
	# Debug camera spin so you KNOW it's live
	if camera:
		var current_transform: Transform3D = camera.transform
		camera.transform = current_transform.rotated(Vector3.UP, 0.005)

func reset_all_sliders() -> void:
	"""Reset all sliders to default values"""
	for id in current_sliders.keys():
		apply_slider(id, 0.5)
	current_sliders.clear()

func set_race(race_id: String) -> void:
	"""Change the character's race - properly cleans up old model and loads new GLB"""
	var normalized_race: String = race_id.to_lower()
	Logger.debug("CharacterPreview3D: set_race() called with race_id: %s (normalized: %s, current: %s)" % [race_id, normalized_race, current_race], "character_creation")
	
	if current_race == normalized_race:
		Logger.debug("CharacterPreview3D: Already showing race %s, skipping reload" % normalized_race, "character_creation")
		return  # Already showing this race, skip reload
	
	current_race = normalized_race
	
	# Clean up old model completely
	Logger.debug("CharacterPreview3D: Cleaning up old model", "character_creation")
	for child in character_root.get_children():
		child.queue_free()
	
	# Build correct path (male fallback for preview if gender not set)
	var gender: String = "male"
	if PlayerData and PlayerData.gender != "":
		gender = PlayerData.gender.to_lower()
	
	var glb_path := "res://assets/models/character_bases/%s-body-%s.glb" % [current_race, gender]
	var tscn_path := "res://assets/models/character_bases/%s-body-%s.tscn" % [current_race, gender]
	
	var model_path: String = ""
	var packed: PackedScene = null
	
	# Try .glb first - attempt to load directly (ResourceLoader.exists may not work for GLB)
	var glb_resource = load(glb_path)
	if glb_resource:
		packed = glb_resource as PackedScene
		if packed:
			model_path = glb_path
			Logger.debug("CharacterPreview3D: Found .glb model: %s" % model_path, "character_creation")
		else:
			Logger.debug("CharacterPreview3D: GLB file exists but is not a PackedScene: %s" % glb_path, "character_creation")
	else:
		Logger.debug("CharacterPreview3D: Could not load GLB file: %s" % glb_path, "character_creation")
	
	# Fall back to .tscn if .glb not found or failed to load
	if not packed:
		var tscn_resource = load(tscn_path)
		if tscn_resource:
			packed = tscn_resource as PackedScene
			if packed:
				model_path = tscn_path
				Logger.debug("CharacterPreview3D: Found .tscn model: %s" % model_path, "character_creation")
			else:
				Logger.debug("CharacterPreview3D: TSCN file exists but is not a PackedScene: %s" % tscn_path, "character_creation")
		else:
			Logger.debug("CharacterPreview3D: Could not load TSCN file: %s" % tscn_path, "character_creation")
	
	# If still no model, create placeholder
	if packed == null:
		Logger.warning("CharacterPreview3D: Race model not found: %s (tried %s and %s) - using placeholder" % [race_id, glb_path, tscn_path], "character_creation")
		_create_placeholder_mesh()
		return
	
	# Instantiate and add the new model
	Logger.debug("CharacterPreview3D: Model loaded successfully, instantiating...", "character_creation")
	var instance: Node3D = packed.instantiate()
	if instance:
		character_root.add_child(instance)
		
		# Reset rotation so every race starts facing forward
		character_root.rotation = Vector3.ZERO
		
		# Update skeleton and mesh references from the loaded model
		_update_skeleton_references()
		
		# Optional: Find and play idle animation if available
		var anim_player: AnimationPlayer = character_root.find_child("AnimationPlayer", true, false)
		if anim_player and anim_player.has_animation("idle"):
			anim_player.play("idle")
			Logger.debug("CharacterPreview3D: Playing idle animation", "character_creation")
		
		Logger.info("CharacterPreview3D: Successfully loaded race model: %s" % model_path, "character_creation")
	else:
		Logger.error("CharacterPreview3D: Failed to instantiate model: %s" % model_path, "character_creation")
		_create_placeholder_mesh()

func set_gender(gender: String) -> void:
	"""Change the character's gender"""
	current_gender = gender
	load_base_model()

