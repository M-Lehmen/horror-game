extends Node3D
## Kapitel 1: Der Schlüssel (Prototyp).
## Die Welt besteht aus einfachen Blöcken (Graybox). Später ersetzen wir sie durch Modelle.
##
## Ablauf: Haus erkunden -> Post holen -> Brief lesen -> zurück zur Veranda
## -> Auto fährt langsam vorbei -> Kapitelende.
## Abweichung: Wer nach der Sichtung in den Nachbargarten geht, wird angegriffen.

const PlayerScript := preload("res://scripts/player.gd")
const UIScript := preload("res://scripts/ui.gd")
const InteractableScript := preload("res://scripts/interactable.gd")

const LETTER_KEYS: Array[String] = [
	"LETTER_1", "LETTER_2", "LETTER_3", "LETTER_4", "LETTER_5", "LETTER_SIGNATURE",
]

enum State { EXPLORE, MAIL, READING, PORCH, CAR, DONE, DEAD }

var state: State = State.EXPLORE
var player
var ui
var mailbox
var observer: Node3D
var car: Node3D
## 0 versteckt, 1 sichtbar, 2 gesehen, 3 verschwunden, 4 "Weg"-Gedanke gezeigt
var observer_phase := 0
var look_time := 0.0
var seen_time := 0.0
var car_thought_shown := false


func _ready() -> void:
	_build_environment()
	_build_world()

	ui = UIScript.new()
	add_child(ui)
	player = PlayerScript.new()
	add_child(player)
	player.focus_changed.connect(Callable(ui, "set_prompt"))

	if Game.checkpoint == "after_letter":
		player.position = Vector3(2.5, 0.1, 13.5)
		player.rotation.y = PI
		_after_letter()
	else:
		player.position = Vector3(-3.0, 0.1, 15.0)
		ui.set_task("TASK_EXPLORE")
		ui.show_thought("THOUGHT_ARRIVE", 5.0)
		ui.show_hint("HINT_CONTROLS", 12.0)


# --- Ablauf ---------------------------------------------------------------

func _on_house_entered() -> void:
	if state != State.EXPLORE:
		return
	state = State.MAIL
	mailbox.enabled = true
	ui.set_task("TASK_GET_MAIL")
	ui.show_thought("THOUGHT_BOXES", 6.0)


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
	state = State.PORCH
	ui.set_task("TASK_PORCH")
	ui.show_thought("THOUGHT_WHO_WRITES", 5.0)
	observer.visible = true
	observer_phase = 1


func _on_garden_entered() -> void:
	if state == State.PORCH and observer_phase >= 1:
		_attack()


func _on_porch_entered() -> void:
	if state != State.PORCH:
		return
	state = State.CAR
	ui.set_task("")
	car.position.x = -30.0
	car.visible = true


func _process(delta: float) -> void:
	if state == State.PORCH or state == State.CAR:
		_update_observer(delta)
	if state == State.CAR:
		_update_car(delta)


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
				ui.show_thought("THOUGHT_GONE", 4.0)


func _update_car(delta: float) -> void:
	# In der Nähe des Hauses wird der Wagen auffällig langsam.
	var speed := 1.6 if absf(car.position.x) < 10.0 else 4.0
	car.position.x += speed * delta
	if not car_thought_shown and car.position.x > -12.0:
		car_thought_shown = true
		ui.show_thought("THOUGHT_STREET_CAR", 5.0)
	if car.position.x > 30.0:
		_end_chapter()


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
	return forward.dot(to_target.normalized()) > min_dot


# --- Welt bauen -------------------------------------------------------------

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.45, 0.48, 0.5)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.52, 0.55)
	env.ambient_light_energy = 0.4
	env.fog_enabled = true
	env.fog_light_color = Color(0.45, 0.48, 0.5)
	env.fog_density = 0.025
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 40, 0)
	sun.light_energy = 0.8
	sun.light_color = Color(1.0, 0.9, 0.75)
	sun.shadow_enabled = true
	add_child(sun)


func _build_world() -> void:
	var grass := Color(0.22, 0.3, 0.18)
	var asphalt := Color(0.12, 0.12, 0.13)
	var concrete := Color(0.45, 0.45, 0.43)

	# Boden, Straße, Gehwege, Einfahrt
	_box(self, Vector3(120, 1, 120), Vector3(5, -0.5, 15), grass, true)
	_box(self, Vector3(120, 0.02, 6), Vector3(5, 0.01, 20), asphalt, false)
	_box(self, Vector3(120, 0.03, 1), Vector3(5, 0.015, 16.5), concrete, false)
	_box(self, Vector3(120, 0.03, 1), Vector3(5, 0.015, 23.5), concrete, false)
	_box(self, Vector3(3, 0.02, 11), Vector3(-4, 0.01, 10.5), concrete, false)
	_box(self, Vector3(1.4, 0.02, 8), Vector3(0, 0.01, 12), concrete, false)

	_build_house()

	# Veranda
	_box(self, Vector3(6, 0.04, 3), Vector3(0, 0.02, 6.5), Color(0.35, 0.27, 0.2), false)

	# Briefkasten an der Straße
	_box(self, Vector3(0.1, 1.0, 0.1), Vector3(2.5, 0.5, 15.5), Color(0.15, 0.15, 0.15), false)
	mailbox = _interactable(Vector3(2.5, 1.15, 15.5), Vector3(0.35, 0.3, 0.5), Color(0.1, 0.2, 0.12), "PROMPT_MAILBOX")
	mailbox.enabled = false
	mailbox.used.connect(_on_mailbox_used)

	# Nachbarschaft gegenüber: Hecke, Garten, Haus
	_box(self, Vector3(14, 1.6, 1), Vector3(7, 0.8, 24.5), Color(0.1, 0.2, 0.08), true)
	_box(self, Vector3(10, 5.5, 8), Vector3(7, 2.75, 36), Color(0.4, 0.42, 0.45), true)
	_box(self, Vector3(10, 5.5, 8), Vector3(-16, 2.75, 0), Color(0.5, 0.45, 0.4), true)
	_box(self, Vector3(10, 5.5, 8), Vector3(16, 2.75, 0), Color(0.42, 0.4, 0.38), true)
	for pos in [Vector3(-9, 0, 14), Vector3(10, 0, 12), Vector3(-6, 0, 30), Vector3(20, 0, 28)]:
		_tree(pos)

	# Der Beobachter: dunkle Gestalt hinter der Hecke
	observer = Node3D.new()
	observer.position = Vector3(8, 0, 25.6)
	add_child(observer)
	var dark := _mat(Color(0.02, 0.02, 0.02))
	var body := CSGCylinder3D.new()
	body.radius = 0.25
	body.height = 1.65
	body.position.y = 0.825
	body.material = dark
	observer.add_child(body)
	var head := CSGSphere3D.new()
	head.radius = 0.14
	head.position.y = 1.8
	head.material = dark
	observer.add_child(head)
	observer.visible = false

	# Auto, das später langsam vorbeifährt
	car = Node3D.new()
	car.position = Vector3(-30, 0, 19)
	add_child(car)
	_box(car, Vector3(4.2, 0.9, 1.8), Vector3(0, 0.75, 0), Color(0.3, 0.05, 0.05), false)
	_box(car, Vector3(2.2, 0.7, 1.6), Vector3(-0.3, 1.5, 0), Color(0.05, 0.05, 0.07), false)
	car.visible = false

	# Auslöser (unsichtbare Zonen)
	_area(Vector3(10, 2, 4), Vector3(0, 1, 2.5), _on_house_entered)
	_area(Vector3(6, 2, 3), Vector3(0, 1, 6.5), _on_porch_entered)
	_area(Vector3(14, 3, 6), Vector3(7, 1.5, 28), _on_garden_entered)

	_add_bounds()


func _build_house() -> void:
	var wall := Color(0.55, 0.52, 0.47)
	var house := CSGCombiner3D.new()
	house.use_collision = true
	add_child(house)
	# Erdgeschoss: Außenbox minus Innenraum ergibt Wände, Boden und Decke
	_box(house, Vector3(12, 3, 10), Vector3(0, 1.4, 0), wall, false)
	_sub(house, Vector3(11.6, 2.8, 9.6), Vector3(0, 1.4, 0), wall)
	_sub(house, Vector3(1.2, 2.2, 0.6), Vector3(0, 1.1, 4.9), wall)       # Haustür
	_sub(house, Vector3(1.6, 1.2, 0.6), Vector3(-3.5, 1.5, 4.9), wall)    # Fenster vorne
	_sub(house, Vector3(1.6, 1.2, 0.6), Vector3(3.5, 1.5, 4.9), wall)
	_sub(house, Vector3(0.6, 1.2, 1.6), Vector3(-5.9, 1.5, 2.5), wall)    # Fenster Seiten
	_sub(house, Vector3(0.6, 1.2, 1.6), Vector3(5.9, 1.5, -2.5), wall)
	_box(house, Vector3(11.6, 2.8, 0.15), Vector3(0, 1.4, 0), wall, false) # Innenwand
	_sub(house, Vector3(1.2, 2.2, 0.4), Vector3(2.5, 1.1, 0), wall)       # Durchgang Küche

	_box(self, Vector3(11.6, 0.02, 9.6), Vector3(0, 0.01, 0), Color(0.3, 0.22, 0.15), false)

	# Obergeschoss und Dach (nur von außen sichtbar)
	_box(self, Vector3(12, 3, 10), Vector3(0, 4.4, 0), wall, false)
	for x in [-3.5, 0.0, 3.5]:
		_box(self, Vector3(1.4, 1.2, 0.05), Vector3(x, 4.5, 5.03), Color(0.08, 0.08, 0.1), false)
	var roof := Color(0.25, 0.2, 0.2)
	var front := _box(self, Vector3(12.8, 0.2, 6.4), Vector3(0, 7.65, 2.5), roof, false)
	front.rotation.x = deg_to_rad(35)
	var back := _box(self, Vector3(12.8, 0.2, 6.4), Vector3(0, 7.65, -2.5), roof, false)
	back.rotation.x = deg_to_rad(-35)

	# Umzugskartons im Wohnzimmer
	var cardboard := Color(0.55, 0.42, 0.28)
	_box(self, Vector3(0.6, 0.5, 0.5), Vector3(-3, 0.25, 2), cardboard, true)
	_box(self, Vector3(0.6, 0.5, 0.5), Vector3(-3, 0.75, 2), cardboard, true)
	_box(self, Vector3(0.8, 0.6, 0.6), Vector3(-2, 0.3, 3.5), cardboard, true)
	_box(self, Vector3(0.6, 0.5, 0.5), Vector3(4, 0.25, 1.2), cardboard, true)
	var photos = _interactable(Vector3(3.2, 0.25, 2.8), Vector3(0.6, 0.5, 0.5), cardboard, "PROMPT_LOOK")
	photos.used.connect(func() -> void: ui.show_thought("THOUGHT_PHOTOS", 4.0))

	# Licht innen
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 2.5, 2.5)
	lamp.light_color = Color(1.0, 0.85, 0.65)
	lamp.light_energy = 0.8
	lamp.omni_range = 7.0
	add_child(lamp)
	var lamp2 := OmniLight3D.new()
	lamp2.position = Vector3(0, 2.5, -2.5)
	lamp2.light_color = Color(1.0, 0.85, 0.65)
	lamp2.light_energy = 0.4
	lamp2.omni_range = 6.0
	add_child(lamp2)


func _tree(pos: Vector3) -> void:
	var trunk := CSGCylinder3D.new()
	trunk.radius = 0.2
	trunk.height = 3.0
	trunk.position = pos + Vector3(0, 1.5, 0)
	trunk.material = _mat(Color(0.25, 0.18, 0.12))
	trunk.use_collision = true
	add_child(trunk)
	var crown := CSGSphere3D.new()
	crown.radius = 1.8
	crown.position = pos + Vector3(0, 3.8, 0)
	crown.material = _mat(Color(0.12, 0.22, 0.1))
	add_child(crown)


# --- Hilfsfunktionen ------------------------------------------------------

func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	return m


func _box(parent: Node, size: Vector3, pos: Vector3, color: Color, collide: bool) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.material = _mat(color)
	b.use_collision = collide
	parent.add_child(b)
	return b


func _sub(parent: Node, size: Vector3, pos: Vector3, color: Color) -> void:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.material = _mat(color)
	b.operation = CSGShape3D.OPERATION_SUBTRACTION
	parent.add_child(b)


func _interactable(pos: Vector3, size: Vector3, color: Color, prompt: String):
	var it = InteractableScript.new()
	it.position = pos
	it.prompt = prompt
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	it.add_child(shape)
	var visual := CSGBox3D.new()
	visual.size = size
	visual.material = _mat(color)
	it.add_child(visual)
	add_child(it)
	return it


func _area(size: Vector3, pos: Vector3, callback: Callable) -> void:
	var area := Area3D.new()
	area.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(func(body: Node3D) -> void:
		if body.is_in_group("player"):
			callback.call()
	)


## Unsichtbare Wände, damit niemand aus der Welt läuft.
func _add_bounds() -> void:
	var bounds := StaticBody3D.new()
	add_child(bounds)
	var walls := [
		[Vector3(80, 10, 1), Vector3(5, 5, -15)],
		[Vector3(80, 10, 1), Vector3(5, 5, 45)],
		[Vector3(1, 10, 60), Vector3(-30, 5, 15)],
		[Vector3(1, 10, 60), Vector3(40, 5, 15)],
	]
	for w in walls:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = w[0]
		shape.shape = box
		shape.position = w[1]
		bounds.add_child(shape)
