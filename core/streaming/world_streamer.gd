# ╔═══════════════════════════════════════════════════════════
# ║ WorldStreamer.gd
# ║ Desc: World streaming system for dynamic loading/unloading
# ║ Author: Lordthoth
# ╚═══════════════════════════════════════════════════════════

extends Node

func _ready() -> void:
	Logger.verbose("World/Streaming", "_ready() called")
	Logger.info("World/Streaming", "World streaming system initialized")
