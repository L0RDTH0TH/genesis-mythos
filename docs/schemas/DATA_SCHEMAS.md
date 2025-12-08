# Data Schema Documentation

This document describes the JSON schema for all data files used in the project.

## Table of Contents

- [races.json](#racesjson)
- [classes.json](#classesjson)
- [backgrounds.json](#backgroundsjson)
- [abilities.json](#abilitiesjson)
- [point_buy.json](#point_buyjson)
- [skills.json](#skillsjson)
- [voices.json](#voicesjson)
- [appearance_presets.json](#appearance_presetsjson)

---

## races.json

**Type:** Array of Race Objects  
**Path:** `res://data/races.json`  
**Loaded by:** `GameData._load_json_array()`

### Race Object Schema

```json
{
  "id": "string",                    // Required: Unique identifier (e.g., "dwarf", "elf")
  "name": "string",                  // Required: Display name (e.g., "Dwarf", "Elf")
  "description": "string",           // Required: Race description text
  "speed": "string",                 // Required: Movement speed (e.g., "7.5m / 25ft")
  "size": "string",                  // Required: Size category (e.g., "Medium", "Small")
  "features": ["string"],            // Required: Array of feature descriptions
  "ability_bonuses": {               // Required: Ability score bonuses
    "strength": 0,                   // Integer bonus (can be negative, zero, or positive)
    "dexterity": 0,
    "constitution": 0,
    "intelligence": 0,
    "wisdom": 0,
    "charisma": 0
  },
  "subraces": [                      // Optional: Array of subrace objects
    {
      "id": "string",                // Required: Unique subrace identifier
      "name": "string",              // Required: Subrace display name
      "description": "string",       // Optional: Subrace description (overrides race description if provided)
      "features": ["string"],        // Optional: Additional features beyond race features
      "ability_bonuses": {           // Optional: Additional ability bonuses (added to race bonuses)
        "strength": 0,
        "dexterity": 0,
        "constitution": 0,
        "intelligence": 0,
        "wisdom": 0,
        "charisma": 0
      }
    }
  ]
}
```

### Example

```json
{
  "id": "dwarf",
  "name": "Dwarf",
  "description": "Dwarves are short humanoid people...",
  "speed": "7.5m / 25ft",
  "size": "Medium",
  "features": [
    "Darkvision up to 12m",
    "Dwarven Resilience: Advantage on saving throws against poison"
  ],
  "ability_bonuses": {
    "constitution": 2
  },
  "subraces": [
    {
      "id": "hill_dwarf",
      "name": "Hill Dwarf",
      "description": "Hill dwarves have keen senses...",
      "features": ["Dwarven Toughness: Hit point maximum increases by 1 per level"],
      "ability_bonuses": {
        "wisdom": 1
      }
    }
  ]
}
```

---

## classes.json

**Type:** Array of Class Objects  
**Path:** `res://data/classes.json`  
**Loaded by:** `GameData._load_json_array()`

### Class Object Schema

```json
{
  "id": "string",                    // Required: Unique identifier (e.g., "fighter", "wizard")
  "name": "string",                  // Required: Display name (e.g., "Fighter", "Wizard")
  "hit_die": "string",              // Required: Hit die notation (e.g., "1d12", "1d8")
  "description": "string",           // Required: Class description text
  "proficiencies": ["string"],       // Required: Array of proficiency names
  "features": ["string"],           // Required: Array of class feature descriptions
  "subclasses": [                    // Optional: Array of subclass objects
    {
      "id": "string",                // Required: Unique subclass identifier
      "name": "string",              // Required: Subclass display name
      "description": "string"        // Required: Subclass description
    }
  ]
}
```

### Example

```json
{
  "id": "fighter",
  "name": "Fighter",
  "hit_die": "1d10",
  "description": "A master of martial combat...",
  "proficiencies": [
    "Light Armor",
    "Medium Armor",
    "Heavy Armor",
    "Shields",
    "Simple Weapons",
    "Martial Weapons"
  ],
  "features": [
    "Fighting Style",
    "Second Wind"
  ],
  "subclasses": [
    {
      "id": "champion",
      "name": "Champion",
      "description": "Focuses on raw physical power..."
    }
  ]
}
```

---

## backgrounds.json

**Type:** Array of Background Objects  
**Path:** `res://data/backgrounds.json`  
**Loaded by:** `GameData._load_json_array()`

### Background Object Schema

```json
{
  "id": "string",                    // Required: Unique identifier (e.g., "acolyte", "criminal")
  "name": "string",                  // Required: Display name (e.g., "Acolyte", "Criminal")
  "description": "string",           // Required: Background description text
  "skill_proficiencies": ["string"], // Required: Array of skill names granted
  "feature": "string",               // Required: Background feature name
  "feature_description": "string",    // Required: Feature description text
  "languages": 0,                    // Required: Number of languages granted (integer)
  "tools": ["string"],               // Required: Array of tool proficiencies (can be empty)
  "inspiration": "string"            // Optional: Inspiration trigger description
}
```

### Example

```json
{
  "id": "acolyte",
  "name": "Acolyte",
  "description": "You have spent your life in service to a temple...",
  "skill_proficiencies": ["Insight", "Religion"],
  "feature": "Shelter of the Faithful",
  "feature_description": "You and your companions can expect free healing...",
  "languages": 2,
  "tools": [],
  "inspiration": "You gain inspiration whenever you aid a fellow devotee..."
}
```

---

## abilities.json

**Type:** Dictionary  
**Path:** `res://data/abilities.json`  
**Loaded by:** `GameData._load_json_dict()`

### Schema

```json
{
  "strength": {
    "short": "STR",
    "full": "Strength"
  },
  "dexterity": {
    "short": "DEX",
    "full": "Dexterity"
  },
  "constitution": {
    "short": "CON",
    "full": "Constitution"
  },
  "intelligence": {
    "short": "INT",
    "full": "Intelligence"
  },
  "wisdom": {
    "short": "WIS",
    "full": "Wisdom"
  },
  "charisma": {
    "short": "CHA",
    "full": "Charisma"
  }
}
```

**Note:** All six abilities must be present. The keys must match exactly as shown.

---

## point_buy.json

**Type:** Dictionary  
**Path:** `res://data/point_buy.json`  
**Loaded by:** `GameData._load_json_dict()`

### Schema

```json
{
  "starting_points": 27,             // Required: Initial point-buy points
  "min_base_score": 6,              // Required: Minimum base ability score (before racial bonuses)
  "max_base_score": 25,              // Required: Maximum base ability score (before racial bonuses)
  "costs": {                         // Required: Cost to reach each score
    "6": -4,                         // Negative values = refund when decreasing
    "7": -2,
    "8": 0,                          // Baseline (no cost)
    "9": 1,
    "10": 2,
    "11": 3,
    "12": 4,
    "13": 5,
    "14": 7,
    "15": 9,
    "16": 12,
    "17": 15,
    "18": 19,
    "19": 24,
    "20": 30,
    "21": 37,
    "22": 45,
    "23": 54,
    "24": 64,
    "25": 75
  }
}
```

**Notes:**
- All scores from `min_base_score` to `max_base_score` must have entries in `costs`
- Cost values are cumulative (cost to go from 8 to 9 is 1, from 8 to 10 is 2, etc.)
- Negative costs for scores below 8 represent refunds when decreasing

---

## skills.json

**Type:** Dictionary  
**Path:** `res://data/skills.json`  
**Loaded by:** `GameData._load_json_dict()`

### Schema

```json
{
  "skill_id": {
    "name": "string",                // Required: Display name (e.g., "Athletics", "Stealth")
    "ability": "string",             // Required: Associated ability key (e.g., "strength", "dexterity")
    "description": "string"          // Optional: Skill description text
  }
}
```

### Example

```json
{
  "athletics": {
    "name": "Athletics",
    "ability": "strength",
    "description": "Your Strength (Athletics) check covers difficult situations..."
  },
  "stealth": {
    "name": "Stealth",
    "ability": "dexterity",
    "description": "Make a Dexterity (Stealth) check when you attempt to conceal yourself..."
  }
}
```

**Note:** Skill IDs should match the skill names used in classes.json and backgrounds.json.

---

## voices.json

**Type:** Array of Voice Objects  
**Path:** `res://data/voices.json`  
**Loaded by:** `GameData._load_json_array()`

### Voice Object Schema

```json
{
  "id": "string",                    // Required: Unique identifier
  "name": "string",                  // Required: Display name
  "description": "string"           // Optional: Voice description
}
```

### Example

```json
[
  {
    "id": "voice_male_1",
    "name": "Voice 1",
    "description": "A deep, commanding voice"
  },
  {
    "id": "voice_female_1",
    "name": "Voice 1",
    "description": "A clear, melodic voice"
  }
]
```

---

## appearance_presets.json

**Type:** Dictionary  
**Path:** `res://data/appearance_presets.json`  
**Loaded by:** `GameData._load_json_dict()`

### Schema

```json
{
  "preset_id": {
    "name": "string",                // Required: Preset display name
    "appearance_data": {             // Required: Appearance configuration
      "head_preset": 0,              // Head preset index
      "hair_style": 0,                // Hair style index
      "skin_color": [r, g, b, a],    // Skin color RGBA array
      "hair_color": [r, g, b, a],    // Hair color RGBA array
      // ... other appearance fields
    }
  }
}
```

**Note:** Structure may vary based on appearance system implementation.

---

## Data Loading

All data files are loaded automatically by `GameData` singleton during `_ready()`:

1. `GameData._ready()` is called when the engine starts
2. `GameData.load_all_data()` is called
3. Each JSON file is loaded using `_load_json_array()` or `_load_json_dict()`
4. Data is stored in corresponding properties (e.g., `GameData.races`, `GameData.classes`)
5. Assertion checks that races were loaded successfully

**Error Handling:**
- Missing files: Logs error, returns empty array/dictionary
- Parse errors: Logs error with line number, returns empty array/dictionary
- Invalid structure: Logs error, skips invalid entries

**Access Pattern:**
```gdscript
# Access races
for race in GameData.races:
    print(race.name)

# Access specific race
var dwarf_race = GameData.races.filter(func(r): return r.id == "dwarf")[0]

# Access point-buy config
var starting_points = GameData.point_buy_data.get("starting_points", 27)
```

