extends Node
## Autoload "Game": globale Einstellungen, Steuerung und Checkpoints.

## Letzter erreichter Checkpoint. Bleibt beim Neuladen der Szene erhalten.
var checkpoint: String = ""
var mouse_sensitivity := 0.002
var master_volume := 0.65
const CONFIG_PATH := "user://settings.cfg"
const CHAPTER_PATHS := ["res://scenes/chapter1.tscn"]

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
	load_settings()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_language"):
		var current := TranslationServer.get_locale()
		TranslationServer.set_locale("en" if current.begins_with("de") else "de")
		save_settings()
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func restart_from_checkpoint() -> void:
	get_tree().reload_current_scene()

func load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(CONFIG_PATH)
	var lang := OS.get_locale_language()
	if error == OK:
		mouse_sensitivity = clampf(float(config.get_value("game", "sensitivity", mouse_sensitivity)), 0.0005, 0.01)
		master_volume = clampf(float(config.get_value("audio", "master", master_volume)), 0.0, 1.0)
		lang = str(config.get_value("game", "language", lang))
	TranslationServer.set_locale("de" if lang.begins_with("de") else "en")
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.001)))
	AudioServer.set_bus_mute(0, master_volume <= 0.0)

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "sensitivity", mouse_sensitivity)
	config.set_value("game", "language", TranslationServer.get_locale())
	config.set_value("audio", "master", master_volume)
	var error := config.save(CONFIG_PATH)
	if error != OK:
		push_warning("Einstellungen konnten nicht gespeichert werden.")

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.001)))
	AudioServer.set_bus_mute(0, master_volume <= 0.0)
	save_settings()

func open_chapter(index: int) -> bool:
	if index < 0 or index >= CHAPTER_PATHS.size():
		return false
	var path: String = CHAPTER_PATHS[index]
	if not ResourceLoader.exists(path):
		return false
	checkpoint = ""
	get_tree().paused = false
	return get_tree().change_scene_to_file(path) == OK
