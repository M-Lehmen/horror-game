extends Node
## Adapter für später importierte AnimationPlayer (z. B. FBX / glTF).
## Ohne importierte Figuren passiert bewusst nichts.

@export var animation_player_path: NodePath
@export var idle_name := "Idle"
@export var walk_name := "Walking"
@export var wave_name := "Waving"
@export var attack_name := "Attack"

var _anim: AnimationPlayer

func _ready() -> void:
	if not animation_player_path.is_empty():
		_anim = get_node_or_null(animation_player_path) as AnimationPlayer

func play_state(state: String) -> bool:
	if _anim == null:
		return false
	var clip := ""
	match state:
		"idle": clip = idle_name
		"walk": clip = walk_name
		"wave": clip = wave_name
		"attack": clip = attack_name
		_: return false
	if not _anim.has_animation(clip):
		return false
	if _anim.current_animation != clip:
		_anim.play(clip, 0.2)
	return true
