extends Node
## Autoload "Game": globale Einstellungen, Steuerung und Checkpoints.

## Letzter erreichter Checkpoint. Bleibt beim Neuladen der Szene erhalten.
var checkpoint: String = ""

## Tastenbelegung. Wird beim Start per Code registriert.
const ACTIONS := {
	"move_forward": KEY_W,
	"move_back": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"interact": KEY_E,
	"crouch": KEY_CTRL,
	"toggle_language": KEY_F2,
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = ACTIONS[action]
		InputMap.action_add_event(action, ev)
	# Sprache des Betriebssystems übernehmen, sonst Englisch.
	var lang := OS.get_locale_language()
	TranslationServer.set_locale("de" if lang == "de" else "en")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_language"):
		var current := TranslationServer.get_locale()
		TranslationServer.set_locale("en" if current.begins_with("de") else "de")
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func restart_from_checkpoint() -> void:
	get_tree().reload_current_scene()
