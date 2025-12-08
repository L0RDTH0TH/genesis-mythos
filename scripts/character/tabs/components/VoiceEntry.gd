# ╔═══════════════════════════════════════════════════════════
# ║ VoiceEntry.gd
# ║ Desc: Single voice selection entry with audio preview on click
# ║ Author: Grok + Cursor
# ╚═══════════════════════════════════════════════════════════
extends Button

signal voice_selected(voice_id: String)

@onready var voice_name: Label = $VBoxContainer/VoiceName

var voice_data: Dictionary
var audio_player: AudioStreamPlayer

func setup(data: Dictionary) -> void:
	voice_data = data
	
	# Ensure voice_name is ready (in case setup is called before _ready)
	if not voice_name:
		voice_name = get_node_or_null("VBoxContainer/VoiceName") as Label
	
	if voice_name:
		voice_name.text = data.get("name", "")
	else:
		push_warning("VoiceEntry: VoiceName label not found!")
	
	var sample_path: String = data.get("sample", "")
	if sample_path != "":
		var stream := load(sample_path) as AudioStream
		if stream:
			audio_player = AudioStreamPlayer.new()
			audio_player.stream = stream
			add_child(audio_player)
	
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if audio_player and audio_player.stream:
		audio_player.play()
	voice_selected.emit(voice_data.get("id", ""))

