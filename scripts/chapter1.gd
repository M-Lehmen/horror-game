extends "res://scripts/chapter1_world.gd"
## Kapitel 1: Der Schlüssel (Prototyp).
## Die Welt besteht aus einfachen Blöcken (Graybox). Später ersetzen wir sie durch Modelle.
##
## Ablauf: Ankunft am Auto -> 3 Kartons ins Haus tragen (Nachbar Walter Greaves hört auf
## zu mähen und starrt) -> Haus erkunden (Kinderzimmer oben, verschlossener Keller)
## -> Harriet Price winkt -> Post holen -> Brief lesen -> Gestalt hinter der Hecke
## -> Motor hinter dem Haus gegenüber -> zurück zum Auto -> derselbe Mann rollt im
## dunklen Wagen vorbei -> Kapitelende.
## Abweichung: Wer nach dem Brief in den Garten gegenüber geht, wird angegriffen.
## Die Welt baut chapter1_world.gd, die Bausteine liegen in world_kit.gd.

const PlayerScript := preload("res://scripts/player.gd")
const UIScript := preload("res://scripts/ui.gd")

const LETTER_KEYS: Array[String] = [
	"LETTER_1", "LETTER_2", "LETTER_3", "LETTER_4", "LETTER_5", "LETTER_SIGNATURE",
]
const BOX_COUNT := 3

enum State { BOXES, EXPLORE, MAIL, READING, AFTER_LETTER, CAR, DONE, DEAD }

var state: State = State.BOXES
var player
var carry_box: CSGBox3D

var boxes_left := BOX_COUNT
var boxes_placed := 0
var carrying := false
var saw_kidsroom := false
var saw_cellar := false
var walter_staring := false
var walter_dir := 1.0
var harriet_waved := false
var wave_time := 0.0
## 0 versteckt, 1 sichtbar, 2 gesehen, 3 verschwunden, 4 "Weg"-Gedanke gezeigt
var observer_phase := 0
var look_time := 0.0
var seen_time := 0.0
var gone_time := 0.0
var letter_time := 0.0
var watched_hint_shown := false
var engine_started := false
var drive_index := 1
var street_thought_shown := false
var same_man_shown := false
var garden_warning_armed := false
var garden_warning_timer := 0.0


func _ready() -> void:
	_build_environment()
	_build_world()

	ui = UIScript.new()
	add_child(ui)
	player = PlayerScript.new()
	add_child(player)
	player.focus_changed.connect(Callable(ui, "set_prompt"))
	carry_box = _box(player.camera, Vector3(0.5, 0.38, 0.4), Vector3(0, -0.45, -0.7), CARDBOARD, false)
	carry_box.visible = false

	if Game.checkpoint == "after_letter":
		boxes_left = 0
		for _i in BOX_COUNT:
			_place_box()
		saw_kidsroom = true
		saw_cellar = true
		player.position = Vector3(2.5, 0.1, 13.5)
		player.rotation.y = PI
		_after_letter()
	else:
		trunk.enabled = true
		player.position = Vector3(-2.2, 0.1, 14.2)
		_update_box_task()
		ui.show_thought("THOUGHT_ARRIVE", 5.0)
		ui.show_hint("HINT_CONTROLS", 12.0)
		get_tree().create_timer(5.5).timeout.connect(func() -> void:
			if state == State.BOXES and boxes_left == BOX_COUNT:
				ui.show_thought("THOUGHT_UNLOAD", 5.0)
		)


# --- Ablauf ---------------------------------------------------------------

func _update_box_task() -> void:
	ui.set_task("TASK_BOXES", " (%d/%d)" % [boxes_placed, BOX_COUNT])


func _on_trunk_used() -> void:
	if state != State.BOXES or carrying or boxes_left == 0:
		return
	boxes_left -= 1
	carrying = true
	carry_box.visible = true
	trunk.enabled = false
	drop_spot.enabled = true
	# Beim zweiten Gang hat Walter aufgehört zu mähen.
	if boxes_placed == 1 and not walter_staring:
		walter_staring = true
		ui.show_thought("THOUGHT_WALTER", 5.0)


func _on_drop_used() -> void:
	if not carrying:
		return
	carrying = false
	carry_box.visible = false
	drop_spot.enabled = false
	_place_box()
	_update_box_task()
	if boxes_placed < BOX_COUNT:
		trunk.enabled = true
		return
	walter_staring = false
	state = State.EXPLORE
	ui.set_task("TASK_EXPLORE")
	ui.show_thought("THOUGHT_BOXES", 6.0)
	_check_explore()


func _place_box() -> void:
	var spots := [Vector3(1.3, 0.3, 2.8), Vector3(1.9, 0.3, 2.8), Vector3(1.6, 0.7, 2.8)]
	_crate(Vector3(0.5, 0.38, 0.4), spots[boxes_placed])
	boxes_placed += 1


func _on_kidsroom_used() -> void:
	saw_kidsroom = true
	ui.show_thought("THOUGHT_KIDSROOM", 6.0)
	_check_explore()


func _on_cellar_used() -> void:
	saw_cellar = true
	ui.show_thought("THOUGHT_CELLAR", 4.0)
	_check_explore()


func _check_explore() -> void:
	if state != State.EXPLORE or not saw_kidsroom or not saw_cellar:
		return
	state = State.MAIL
	mailbox.enabled = true
	ui.set_task("TASK_GET_MAIL")
	get_tree().create_timer(6.0).timeout.connect(func() -> void:
		if state == State.MAIL:
			ui.show_thought("THOUGHT_HOUSE_DONE", 5.0)
	)


func _on_mailbox_used() -> void:
	if state != State.MAIL:
		return
	state = State.READING
	mailbox.enabled = false
	player.can_move = false
	player.focused = null
	ui.show_letter(LETTER_KEYS)


func _unhandled_input(event: InputEvent) -> void:
	if state == State.READING and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		ui.hide_letter()
		player.can_move = true
		Game.checkpoint = "after_letter"
		_after_letter()


func _after_letter() -> void:
	state = State.AFTER_LETTER
	ui.set_task("")
	ui.show_thought("THOUGHT_WHO_WRITES", 5.0)
	observer.visible = true
	observer_phase = 1


func _on_garden_entered() -> void:
	if state != State.AFTER_LETTER:
		return
	if not garden_warning_armed:
		garden_warning_armed = true
		garden_warning_timer = 3.0
		ui.show_thought("THOUGHT_GARDEN_WARNING", 4.0)
	elif garden_warning_timer <= 0.0:
		_attack()


func _start_engine() -> void:
	engine_started = true
	dark_car.visible = true
	ui.show_thought("THOUGHT_ENGINE", 5.0)
	ui.set_task("TASK_TO_CAR")


func _process(delta: float) -> void:
	garden_warning_timer = maxf(0.0, garden_warning_timer - delta)
	_update_walter(delta)
	_update_harriet(delta)
	match state:
		State.AFTER_LETTER:
			_update_observer(delta)
			_update_after_letter(delta)
		State.CAR:
			_update_car(delta)


func _update_walter(delta: float) -> void:
	if walter_staring:
		var p: Vector3 = player.global_position
		walter.look_at(Vector3(p.x, walter.global_position.y, p.z), Vector3.UP)
		return
	walter.position.x += walter_dir * 0.9 * delta
	if walter.position.x > -11.5 or walter.position.x < -19.5:
		walter_dir = -walter_dir
		walter.position.x = clampf(walter.position.x, -19.5, -11.5)
	walter.look_at(walter.global_position + Vector3(walter_dir, 0, 0), Vector3.UP)


func _update_harriet(delta: float) -> void:
	var arm: Node3D = harriet.get_meta("arm")
	if state == State.MAIL:
		var p: Vector3 = player.global_position
		harriet.look_at(Vector3(p.x, 0, p.z), Vector3.UP)
		var head := harriet.global_position + Vector3(0, 1.6, 0)
		if not harriet_waved and p.z > 5.5 and _is_looking_at(head, 50.0, 0.97):
			harriet_waved = true
			wave_time = 5.0
			ui.show_thought("THOUGHT_HARRIET", 5.0)
	if wave_time > 0.0:
		wave_time -= delta
		arm.rotation.z = 2.6 + 0.35 * sin(wave_time * 9.0)
	else:
		arm.rotation.z = lerpf(arm.rotation.z, 0.0, 4.0 * delta)


func _update_observer(delta: float) -> void:
	var head := observer.global_position + Vector3(0, 1.75, 0)
	var looking := _is_looking_at(head, 45.0, 0.97)
	match observer_phase:
		1:
			if looking:
				look_time += delta
				if look_time > 0.5:
					observer_phase = 2
					ui.show_thought("THOUGHT_SOMEONE_THERE", 4.0)
		2:
			seen_time += delta
			if seen_time > 1.5 and not looking:
				observer.visible = false
				observer_phase = 3
		3:
			if looking:
				observer_phase = 4
				gone_time = 0.0
				ui.show_thought("THOUGHT_GONE", 4.0)


func _update_after_letter(delta: float) -> void:
	letter_time += delta
	# Falls die Spielerin die Gestalt nicht bemerkt, ein kleiner Schubs.
	if observer_phase == 1 and letter_time > 20.0 and not watched_hint_shown:
		watched_hint_shown = true
		ui.show_thought("THOUGHT_WATCHED", 4.0)
	# Fortschritt darf nicht davon abhaengen, ob der Spieler die Gestalt sieht.
	if observer_phase == 1 and letter_time >= 32.0:
		observer.visible = false
		observer_phase = 3
	if observer_phase == 2 and letter_time >= 40.0:
		observer.visible = false
		observer_phase = 3
	if observer_phase >= 3 and not engine_started:
		gone_time += delta
		if gone_time > (4.5 if observer_phase == 4 else 7.0):
			_start_engine()
	if engine_started and _flat_distance(player.global_position, CAR_SPOT) < 4.5:
		state = State.CAR
		ui.set_task("")


func _update_car(delta: float) -> void:
	var target: Vector3 = DRIVE_PATH[drive_index]
	var to_target := target - dark_car.position
	var distance := _flat_distance(dark_car.global_position, player.global_position)
	# In der Nähe von Claire wird der Wagen auffällig langsam.
	var step := (1.6 if distance < 14.0 else 5.0) * delta
	if to_target.length() <= step:
		dark_car.position = target
		drive_index += 1
		if drive_index >= DRIVE_PATH.size():
			_end_chapter()
			return
	else:
		dark_car.position += to_target.normalized() * step
		var goal := Basis.looking_at(to_target.normalized()).get_rotation_quaternion()
		dark_car.quaternion = dark_car.quaternion.slerp(goal, minf(1.0, 3.0 * delta))
	driver_head.look_at(player.camera.global_position, Vector3.UP)
	if not street_thought_shown and drive_index >= 3:
		street_thought_shown = true
		ui.show_thought("THOUGHT_STREET_CAR", 4.0)
	var player_x: float = player.global_position.x
	if not same_man_shown and drive_index >= 3 and dark_car.position.x < player_x + 2.0:
		same_man_shown = true
		ui.show_thought("THOUGHT_SAME_MAN", 5.0)


func _end_chapter() -> void:
	state = State.DONE
	player.can_move = false
	Game.checkpoint = ""
	await ui.fade_to(1.0, 2.0).finished
	ui.show_center("CHAPTER1_END")
	await get_tree().create_timer(3.5).timeout
	ui.show_center("DEMO_END")


func _attack() -> void:
	state = State.DEAD
	player.can_move = false
	var cam: Camera3D = player.camera
	var forward := -cam.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var feet: Vector3 = player.global_position
	observer.global_position = Vector3(cam.global_position.x, feet.y, cam.global_position.z) + forward * 0.8
	observer.look_at(Vector3(cam.global_position.x, observer.global_position.y, cam.global_position.z), Vector3.UP)
	observer.visible = true
	ui.flash_red()
	await get_tree().create_timer(0.35).timeout
	ui.fade_to(1.0, 0.05)
	ui.show_center("GAME_OVER_FOLLOWED")
	await get_tree().create_timer(3.5).timeout
	Game.restart_from_checkpoint()


func _is_looking_at(target: Vector3, max_distance: float, min_dot: float) -> bool:
	var cam: Camera3D = player.camera
	var to_target := target - cam.global_position
	if to_target.length() > max_distance:
		return false
	var forward := -cam.global_transform.basis.z
	if forward.dot(to_target.normalized()) <= min_dot:
		return false
	var query := PhysicsRayQueryParameters3D.create(cam.global_position, target)
	query.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or (hit.position as Vector3).distance_to(target) < 0.8


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
