# ╔═══════════════════════════════════════════════════════════
# ║ EventBus.gd
# ║ Desc: Central event bus for World Builder UI module communication
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

## World Builder UI signals for cross-module communication
signal world_builder_step_changed(step_index: int)
signal world_builder_parameter_changed(azgaar_key: String, value: Variant)
signal world_builder_generate_requested(options: Dictionary)
signal world_builder_generation_complete()
signal world_builder_generation_failed(reason: String)
signal world_builder_archetype_changed(archetype_name: String)
signal world_builder_seed_changed(seed_value: int)
signal world_builder_bake_to_3d_requested()

