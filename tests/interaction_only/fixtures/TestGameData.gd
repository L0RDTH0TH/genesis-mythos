# ╔═══════════════════════════════════════════════════════════
# ║ TestGameData.gd
# ║ Desc: Mock GameData fixtures for testing
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

class_name TestGameData
extends RefCounted

## Get minimal test race data
static func get_test_races() -> Array:
	"""Return minimal test race data"""
	return [
		{
			"id": "human",
			"name": "Human",
			"description": "Versatile and ambitious",
			"ability_bonuses": {"strength": 1, "dexterity": 1, "constitution": 1, "intelligence": 1, "wisdom": 1, "charisma": 1},
			"speed": "30 ft",
			"size": "Medium",
			"subraces": []
		},
		{
			"id": "elf",
			"name": "Elf",
			"description": "Graceful and long-lived",
			"ability_bonuses": {"dexterity": 2},
			"speed": "30 ft",
			"size": "Medium",
			"subraces": [
				{
					"id": "wood_elf",
					"name": "Wood Elf",
					"description": "Elves of the deep forests",
					"ability_bonuses": {"wisdom": 1},
					"features": ["Fleet of Foot", "Mask of the Wild"]
				},
				{
					"id": "high_elf",
					"name": "High Elf",
					"description": "Elves of the high courts",
					"ability_bonuses": {"intelligence": 1},
					"features": ["Elf Weapon Training", "Cantrip"]
				}
			],
			"features": ["Darkvision", "Keen Senses", "Fey Ancestry", "Trance"]
		},
		{
			"id": "dwarf",
			"name": "Dwarf",
			"description": "Hardy and traditional",
			"ability_bonuses": {"constitution": 2},
			"speed": "25 ft",
			"size": "Medium",
			"subraces": [
				{
					"id": "mountain_dwarf",
					"name": "Mountain Dwarf",
					"description": "Dwarves of the mountains",
					"ability_bonuses": {"strength": 2},
					"features": ["Dwarven Armor Training"]
				}
			],
			"features": ["Darkvision", "Dwarven Resilience", "Dwarven Combat Training", "Stonecunning"]
		},
		{
			"id": "tiefling",
			"name": "Tiefling",
			"description": "Descendants of fiends",
			"ability_bonuses": {"intelligence": 1, "charisma": 2},
			"speed": "30 ft",
			"size": "Medium",
			"subraces": [],
			"features": ["Darkvision", "Hellish Resistance", "Infernal Legacy"]
		}
	]

## Get minimal test class data
static func get_test_classes() -> Array:
	"""Return minimal test class data"""
	return [
		{
			"id": "fighter",
			"name": "Fighter",
			"description": "Master of weapons and armor",
			"hit_die": 10,
			"primary_ability": "strength",
			"saving_throws": ["strength", "constitution"],
			"subclasses": [
				{
					"id": "champion",
					"name": "Champion",
					"description": "Simple and effective warrior"
				},
				{
					"id": "battle_master",
					"name": "Battle Master",
					"description": "Tactical combat expert"
				}
			]
		},
		{
			"id": "wizard",
			"name": "Wizard",
			"description": "Master of arcane magic",
			"hit_die": 6,
			"primary_ability": "intelligence",
			"saving_throws": ["intelligence", "wisdom"],
			"subclasses": [
				{
					"id": "evocation",
					"name": "School of Evocation",
					"description": "Master of destructive magic"
				},
				{
					"id": "abjuration",
					"name": "School of Abjuration",
					"description": "Master of protective magic"
				}
			]
		},
		{
			"id": "rogue",
			"name": "Rogue",
			"description": "Sneaky and skilled",
			"hit_die": 8,
			"primary_ability": "dexterity",
			"saving_throws": ["dexterity", "intelligence"],
			"subclasses": [
				{
					"id": "thief",
					"name": "Thief",
					"description": "Master of stealth and theft"
				}
			]
		}
	]

## Get minimal test background data
static func get_test_backgrounds() -> Array:
	"""Return minimal test background data"""
	return [
		{
			"id": "acolyte",
			"name": "Acolyte",
			"description": "You spent your life in service to a temple",
			"skill_proficiencies": ["insight", "religion"],
			"languages": 2
		},
		{
			"id": "criminal",
			"name": "Criminal",
			"description": "You are a practiced criminal",
			"skill_proficiencies": ["deception", "stealth"],
			"languages": 0
		},
		{
			"id": "folk_hero",
			"name": "Folk Hero",
			"description": "You come from a humble social rank",
			"skill_proficiencies": ["animal_handling", "survival"],
			"languages": 0
		}
	]

## Get minimal test abilities data
static func get_test_abilities() -> Dictionary:
	"""Return minimal test abilities data"""
	return {
		"strength": {"name": "Strength", "short": "STR", "description": "Physical power"},
		"dexterity": {"name": "Dexterity", "short": "DEX", "description": "Agility and reflexes"},
		"constitution": {"name": "Constitution", "short": "CON", "description": "Endurance and health"},
		"intelligence": {"name": "Intelligence", "short": "INT", "description": "Reasoning and memory"},
		"wisdom": {"name": "Wisdom", "short": "WIS", "description": "Awareness and intuition"},
		"charisma": {"name": "Charisma", "short": "CHA", "description": "Force of personality"}
	}

## Get empty/invalid test data (for edge case testing)
static func get_empty_races() -> Array:
	"""Return empty races array for edge case testing"""
	return []

static func get_empty_classes() -> Array:
	"""Return empty classes array for edge case testing"""
	return []

static func get_empty_backgrounds() -> Array:
	"""Return empty backgrounds array for edge case testing"""
	return []

static func get_invalid_race_data() -> Dictionary:
	"""Return invalid race data (missing required fields)"""
	return {
		"id": "invalid_race",
		# Missing name, description, etc.
	}

static func get_invalid_class_data() -> Dictionary:
	"""Return invalid class data (missing required fields)"""
	return {
		"id": "invalid_class",
		# Missing name, description, etc.
	}

## Get fantasy style presets (hardcoded + JSON)
static func get_fantasy_styles() -> Dictionary:
	"""Return all fantasy style presets for testing"""
	return {
		"High Fantasy": {
			"elevation": [38.0, 52.0],
			"frequency": [0.004, 0.007],
			"octaves": 8,
			"lacunarity": 2.3,
			"gain": 0.55,
			"chaos": 0.75,
			"floating_islands": true,
			"particle_color": Color(0.6, 0.9, 1.0),
			"particle_density": 800,
			"bloom_intensity": 1.2,
			"fog_density": 0.01,
			"tint": Color(0.5, 0.8, 1.2)
		},
		"Mythic Fantasy": {
			"elevation": [40.0, 55.0],
			"frequency": [0.003, 0.006],
			"octaves": 9,
			"lacunarity": 2.5,
			"gain": 0.6,
			"chaos": 0.7,
			"floating_islands": true,
			"particle_color": Color(1.0, 0.8, 0.4),
			"particle_density": 1200,
			"bloom_intensity": 1.8,
			"fog_density": 0.03,
			"tint": Color(1.2, 1.0, 0.9)
		},
		"Grimdark": {
			"elevation": [32.0, 48.0],
			"frequency": [0.02, 0.04],
			"octaves": 10,
			"lacunarity": 3.0,
			"gain": 0.7,
			"chaos": 0.98,
			"floating_islands": false,
			"particle_color": Color(0.3, 0.0, 0.0),
			"particle_density": 200,
			"bloom_intensity": 0.3,
			"fog_density": 0.15,
			"tint": Color(0.4, 0.3, 0.5)
		},
		"Weird Fantasy": {
			"elevation": [15.0, 70.0],
			"frequency": [0.04, 0.1],
			"octaves": 12,
			"lacunarity": 4.0,
			"gain": 0.85,
			"chaos": 1.0,
			"domain_warp": 40.0,
			"particle_color": Color(1.0, 0.2, 1.0),
			"particle_density": 1500,
			"bloom_intensity": 2.5,
			"fog_density": 0.08,
			"tint": Color(2.0, 0.5, 2.0)
		},
		"Low Fantasy": {
			"elevation": [10.0, 30.0],
			"frequency": [0.01, 0.03],
			"chaos": 0.3,
			"floating_islands": false
		},
		"Dark Fantasy": {
			"elevation": [18.0, 45.0],
			"frequency": [0.01, 0.04],
			"chaos": 0.95,
			"floating_islands": false
		},
		"Sword and Sorcery": {
			"elevation": [15.0, 40.0],
			"frequency": [0.008, 0.025],
			"chaos": 0.6,
			"floating_islands": false
		}
	}

## Get invalid seed values for testing
static func get_invalid_seeds() -> Array:
	"""Return invalid seed values for validation testing"""
	return [
		-1,  # Negative
		-999999,  # Very negative
		"not_a_number",  # String
		"",  # Empty string
		null  # Null
	]

## Get valid seed values for testing
static func get_valid_seeds() -> Array:
	"""Return valid seed values for testing"""
	return [
		0,
		42,
		12345,
		999999,
		2147483647  # Max int32
	]
