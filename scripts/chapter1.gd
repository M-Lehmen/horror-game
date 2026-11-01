extends Node3D
## Kapitel 1: Der Schlüssel (Prototyp).
## Die Welt besteht aus einfachen Blöcken (Graybox). Später ersetzen wir sie durch Modelle.
##
## Ablauf: Ankunft am Auto -> 3 Kartons ins Haus tragen (Nachbar Walter Greaves hört auf
## zu mähen und starrt) -> Haus erkunden (Kinderzimmer oben, verschlossener Keller)
## -> Harriet Price winkt -> Post holen -> Brief lesen -> Gestalt hinter der Hecke
## -> Motor hinter dem Haus gegenüber -> zurück zum Auto -> derselbe Mann rollt im
## dunklen Wagen vorbei -> Kapitelende.
## Abweichung: Wer nach dem Brief in den Garten gegenüber geht, wird angegriffen.

const PlayerScript := preload("res://scripts/player.gd")
const UIScript := preload("res://scripts/ui.gd")
const InteractableScript := preload("res://scripts/interactable.gd")
const POST_SHADER := preload("res://assets/shaders/post_process.gdshader")

const LETTER_KEYS: Array[String] = [
	"LETTER_1", "LETTER_2", "LETTER_3", "LETTER_4", "LETTER_5", "LETTER_SIGNATURE",
]
const BOX_COUNT := 3
const CARDBOARD := Color(0.55, 0.42, 0.28)
## Claires Auto in der Einfahrt.
const CAR_SPOT := Vector3(-4, 0, 11)
## Weg des dunklen Wagens: hinter dem Haus gegenüber hervor, auf die Straße, an Claire vorbei.
const DRIVE_PATH: Array[Vector3] = [
	Vector3(13.5, 0, 44), Vector3(13.5, 0, 23), Vector3(11, 0, 18.5), Vector3(-50, 0, 18.5),
]

enum State { BOXES, EXPLORE, MAIL, READING, AFTER_LETTER, CAR, DONE, DEAD }

var state: State = State.BOXES
var player
var ui
var mailbox
var trunk
var drop_spot
var carry_box: CSGBox3D
var observer: Node3D
var walter: Node3D
var harriet: Node3D
var dark_car: Node3D
var driver_head: Node3D
var surf := {}

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
	if state == State.AFTER_LETTER:
		_attack()


func _start_engine() -> void:
	engine_started = true
	dark_car.visible = true
	ui.show_thought("THOUGHT_ENGINE", 5.0)
	ui.set_task("TASK_TO_CAR")


func _process(delta: float) -> void:
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
	return forward.dot(to_target.normalized()) > min_dot


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# --- Welt bauen -------------------------------------------------------------

func _build_environment() -> void:
	# Bedeckter Spätnachmittag: grauer Himmel, gedämpfte Farben, wenig Kontrast in den Schatten
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.36, 0.4, 0.45)
	sky_mat.sky_horizon_color = Color(0.58, 0.58, 0.56)
	sky_mat.ground_horizon_color = Color(0.5, 0.5, 0.48)
	sky_mat.ground_bottom_color = Color(0.18, 0.18, 0.17)
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.95
	env.sdfgi_enabled = true
	env.sdfgi_use_occlusion = true
	env.ssao_enabled = true
	env.ssao_intensity = 1.6
	env.ssil_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.05
	env.fog_enabled = true
	env.fog_light_color = Color(0.52, 0.54, 0.55)
	env.fog_density = 0.018
	env.fog_sky_affect = 0.4
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.8
	env.adjustment_contrast = 1.06
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-28, 40, 0)
	sun.light_energy = 0.7
	sun.light_color = Color(1.0, 0.88, 0.72)
	sun.light_angular_distance = 2.0  # weiche Schattenkanten
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 60.0
	sun.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY  # bedeckt: keine sichtbare Sonnenscheibe
	add_child(sun)

	# Nachbearbeitung unter der UI (UI liegt auf Ebene 10)
	var post_layer := CanvasLayer.new()
	post_layer.layer = 5
	add_child(post_layer)
	var post := ColorRect.new()
	post.set_anchors_preset(Control.PRESET_FULL_RECT)
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var post_mat := ShaderMaterial.new()
	post_mat.shader = POST_SHADER
	post.material = post_mat
	post_layer.add_child(post)


## CC0-Texturen von Poly Haven (assets/CREDITS.md), Rest prozedural.
func _make_surfaces() -> void:
	surf = {
		"grass": _pbr("leafy_grass", 0.4),
		"asphalt": _pbr("asphalt_02", 0.3),
		"concrete": _pbr("concrete_pavement", 0.5),
		"siding": _pbr("weathered_plank_siding", 0.5, Color(0.85, 0.82, 0.75)),
		"roof": _pbr("grey_roof_tiles", 0.5),
		"wood": _pbr("wood_floor_worn", 0.5),
		"hedge": _pbr("forest_leaves_03", 0.8, Color(0.6, 0.75, 0.55)),
		"bark": _surface(Color(0.24, 0.18, 0.13), Vector3(0.6, 0.05, 0.6), 6.0, 0.06),
		"soil": _surface(Color(0.17, 0.12, 0.09), Vector3.ONE * 0.8, 5.0, 0.12),
	}
	var lit := StandardMaterial3D.new()
	lit.albedo_color = Color(0.3, 0.25, 0.15)
	lit.emission_enabled = true
	lit.emission = Color(1.0, 0.72, 0.42)
	lit.emission_energy_multiplier = 1.4
	surf.lit_window = lit
	# Nachbarfenster: dunkel spiegelnd (kein Innenraum dahinter)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.04, 0.05, 0.07)
	glass.roughness = 0.08
	glass.metallic = 0.5
	surf.glass = glass
	# Eigenes Haus: durchsichtige Scheiben
	var pane := StandardMaterial3D.new()
	pane.albedo_color = Color(0.6, 0.65, 0.7, 0.12)
	pane.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pane.roughness = 0.05
	surf.pane = pane
	var shade := StandardMaterial3D.new()
	shade.albedo_color = Color(0.9, 0.85, 0.7)
	shade.emission_enabled = true
	shade.emission = Color(1.0, 0.8, 0.55)
	shade.emission_energy_multiplier = 0.6
	surf.lamp_shade = shade


func _build_world() -> void:
	_make_surfaces()
	var grass: Material = surf.grass
	var asphalt: Material = surf.asphalt
	var concrete: Material = surf.concrete

	# Boden, Straße, Gehwege, Einfahrt
	_box(self, Vector3(120, 1, 120), Vector3(5, -0.5, 15), grass, true)
	_box(self, Vector3(120, 0.02, 6), Vector3(5, 0.01, 20), asphalt, false)
	_box(self, Vector3(120, 0.03, 1), Vector3(5, 0.015, 16.5), concrete, false)
	_box(self, Vector3(120, 0.03, 1), Vector3(5, 0.015, 23.5), concrete, false)
	_box(self, Vector3(3, 0.02, 11), Vector3(-4, 0.01, 10.5), concrete, false)
	_box(self, Vector3(1.4, 0.02, 8), Vector3(0, 0.01, 12), concrete, false)

	_build_house()
	_build_stairs()

	# Veranda
	_box(self, Vector3(6, 0.04, 3), Vector3(0, 0.02, 6.5), Color(0.35, 0.27, 0.2), false)

	# Briefkasten an der Straße
	_box(self, Vector3(0.1, 1.0, 0.1), Vector3(2.5, 0.5, 15.5), Color(0.15, 0.15, 0.15), false)
	mailbox = _interactable(Vector3(2.5, 1.15, 15.5), Vector3(0.35, 0.3, 0.5), Color(0.1, 0.2, 0.12), "PROMPT_MAILBOX")
	mailbox.enabled = false
	mailbox.used.connect(_on_mailbox_used)

	# Claires Auto mit Kofferraum voller Kartons
	_car(CAR_SPOT, 0.0, Color(0.35, 0.4, 0.45), true)
	trunk = _interactable(CAR_SPOT + Vector3(0, 0.6, 2.27), Vector3(1.4, 0.4, 0.06), Color(0.3, 0.35, 0.4), "PROMPT_TRUNK")
	trunk.enabled = false
	trunk.used.connect(_on_trunk_used)

	_build_neighborhood()

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

	# Sein dunkler Wagen wartet hinter dem Haus gegenüber, die Kabine ist leicht durchsichtig.
	dark_car = _car(DRIVE_PATH[0], 0.0, Color(0.06, 0.06, 0.07), false, true)
	_box(dark_car, Vector3(0.4, 0.45, 0.3), Vector3(-0.4, 0.98, 0.3), Color(0.03, 0.03, 0.03), false)
	driver_head = Node3D.new()
	driver_head.position = Vector3(-0.4, 1.2, 0.3)
	dark_car.add_child(driver_head)
	var skull := CSGSphere3D.new()
	skull.radius = 0.12
	skull.material = _mat(Color(0.55, 0.5, 0.45))
	driver_head.add_child(skull)
	_box(driver_head, Vector3(0.3, 0.03, 0.18), Vector3(0, 0.1, -0.06), Color(0.03, 0.03, 0.03), false)
	_box(driver_head, Vector3(0.05, 0.05, 0.08), Vector3(0, -0.01, -0.13), Color(0.55, 0.5, 0.45), false)
	dark_car.visible = false

	# Auslöser: Garten hinter der Hecke
	_area(Vector3(12, 3, 6), Vector3(6, 1.5, 28), _on_garden_entered)

	_add_bounds()


func _build_neighborhood() -> void:
	# Eigene Straßenseite (Hausfront +z), links wohnt Walter Greaves
	_neighbor_house(-16, 0, Color(0.5, 0.45, 0.4), false, true)
	_neighbor_house(16, 0, Color(0.42, 0.4, 0.38), false, true)
	_neighbor_house(32, 0, Color(0.47, 0.44, 0.36), false, true)
	# Gegenüber (Hausfront -z): Harriet Price, der Beobachter und zwei weitere
	_neighbor_house(-25, 36, Color(0.38, 0.4, 0.44), true, true)
	_neighbor_house(-9, 36, Color(0.52, 0.48, 0.44), true, true)
	_neighbor_house(7, 36, Color(0.4, 0.42, 0.45), true, false)
	_neighbor_house(23, 36, Color(0.45, 0.41, 0.4), true, true)

	# Hecke vor dem Haus des Beobachters, Einfahrt daneben bleibt frei
	_box(self, Vector3(12, 1.6, 1), Vector3(6, 0.8, 24.5), surf.hedge, true)

	# Zäune
	_fence(Vector3(-7.5, 0, -5), Vector3(-7.5, 0, 15.5))
	_fence(Vector3(7.5, 0, -5), Vector3(7.5, 0, 15.5))
	_fence(Vector3(-30, 0, 25), Vector3(-20, 0, 25))
	_fence(Vector3(-14, 0, 25), Vector3(-4, 0, 25))
	_fence(Vector3(18, 0, 25), Vector3(28, 0, 25))

	# Geparkte Autos
	_car(Vector3(-22.5, 0, 10), 0.0, Color(0.3, 0.32, 0.25), true)
	_car(Vector3(-30, 0, 21.8), PI / 2, Color(0.2, 0.25, 0.35), true)
	_car(Vector3(29.5, 0, 28), PI, Color(0.4, 0.15, 0.12), true)

	# Laternen auf beiden Gehwegen
	for x in [-32.0, -8.0, 20.0, 44.0]:
		_lamp(Vector3(x, 0, 16.2))
	for x in [-20.0, 4.0, 36.0]:
		_lamp(Vector3(x, 0, 23.8))

	for pos in [Vector3(-9.5, 0, 2), Vector3(13, 0, 13), Vector3(-6, 0, 30), Vector3(20, 0, 28),
			Vector3(-30, 0, 8), Vector3(40, 0, 12), Vector3(-17, 0, 28), Vector3(36, 0, 27)]:
		_tree(pos)

	# Walter Greaves mäht den Rasen
	walter = _person(Vector3(-15, 0, 10), Color(0.3, 0.33, 0.4), Color(0.75, 0.62, 0.52))
	_box(walter, Vector3(0.5, 0.35, 0.6), Vector3(0, 0.2, -0.75), Color(0.55, 0.12, 0.08), false)

	# Harriet Price steht in ihrem Vorgarten gegenüber
	harriet = _person(Vector3(-9, 0, 29), Color(0.45, 0.3, 0.4), Color(0.8, 0.68, 0.6))

	_build_decor()


## Vorgärten und Straße: Büsche, Beete, Mülltonnen, Hydranten, Schilder, Fahrrad, Gartenmöbel, Laub.
func _build_decor() -> void:
	for x0 in [-16.0, 16.0, 32.0]:
		for dx in [-3.5, 3.5]:
			_bush(Vector3(x0 + dx, 0, 4.7), 0.7)
	for x0 in [-25.0, -9.0, 7.0, 23.0]:
		for dx in [-3.5, 3.5]:
			_bush(Vector3(x0 + dx, 0, 31.3), 0.7)
	for x in [4.0, 5.3]:
		_bush(Vector3(x, 0, 5.5), 0.55)
	_flower_bed(Vector3(-12, 0, 28.6), Vector2(3, 0.9))
	_flower_bed(Vector3(12.3, 0, 6.5), Vector2(2, 0.8))

	const M := "res://assets/models/%s/%s_1k.gltf"
	var bins := [Vector3(-6.3, 0, 15.2), Vector3(-24.8, 0, 15.2), Vector3(11.6, 0, 15.2), Vector3(27.6, 0, 15.2),
			Vector3(-0.5, 0, 24.6), Vector3(-16.4, 0, 24.6), Vector3(31.6, 0, 24.6)]
	for i in bins.size():
		var p: Vector3 = bins[i]
		_model(M % ["metal_trash_can", "metal_trash_can"], p, 1.0, i * 1.3)
		_solid(Vector3(0.6, 1.0, 0.6), p + Vector3(0, 0.5, 0))
		if i % 2 == 0:
			_model(M % ["trashbag", "trashbag"], p + Vector3(0.55, 0, 0.1), 0.5, i)

	for p in [Vector3(-12, 0, 16.3), Vector3(26, 0, 23.7)]:
		_model(M % ["fire_hydrant", "fire_hydrant"], p, 0.75)
		_solid(Vector3(0.35, 0.75, 0.35), p + Vector3(0, 0.375, 0))

	_sign(Vector3(12, 0, 16.3), "SPEED\nLIMIT\n25", Color(0.9, 0.9, 0.88))
	_sign(Vector3(-36, 0, 23.7), "NEIGHBORHOOD\nWATCH", Color(0.85, 0.75, 0.2))
	_bike(Vector3(19.6, 0, 5.3))

	# Gartenmöbel, Bank, Zwerg, Pflanzen auf den Veranden
	_model(M % ["outdoor_table_chair_set_01", "outdoor_table_chair_set_01"], Vector3(-27, 0, 28.5), 0.9)
	_solid(Vector3(1.8, 0.9, 1.8), Vector3(-27, 0.45, 28.5))
	_model(M % ["painted_wooden_bench", "painted_wooden_bench"], Vector3(-19.5, 0.04, 5.3), 0.9)
	_solid(Vector3(1.5, 0.9, 0.6), Vector3(-19.5, 0.45, 5.3))
	_model(M % ["garden_gnome", "garden_gnome"], Vector3(-11, 0, 27.5), 0.4, PI)
	_model(M % ["tree_stump_01", "tree_stump_01"], Vector3(5, 0, 12), 0.45)
	_model(M % ["planter_box_01", "planter_box_01"], Vector3(2.4, 0.04, 7.5), 0.5)
	for p in [Vector3(-14.3, 0.04, 5.4), Vector3(17.6, 0.04, 5.4), Vector3(-7.4, 0.04, 30.6), Vector3(-23.4, 0.04, 30.6)]:
		_model(M % ["potted_plant_02", "potted_plant_02"], p, 0.8, p.x)

	# Abgedecktes Auto in der Einfahrt von Haus 32
	_model(M % ["covered_car", "covered_car"], Vector3(25.5, 0, 10), 1.5)
	_solid(Vector3(1.9, 1.5, 4.4), Vector3(25.5, 0.75, 10))

	# Gras- und Farnbüschel an Zäunen und Hausfronten
	var rng := RandomNumberGenerator.new()
	rng.seed = 112
	for _i in 60:
		var spot := Vector3(rng.randf_range(-38, 46), 0, rng.randf_range(-6, 46))
		if _inside_house(spot) or (spot.z > 16.0 and spot.z < 24.0):
			continue  # nicht in Häusern, nicht auf Straße und Gehweg
		var kind := "fern_02" if rng.randf() < 0.3 else "grass_medium_01"
		_model(M % [kind, kind], spot, rng.randf_range(0.3, 0.6), rng.randf() * TAU)

	_leaves(1600)
	_grass_field(14000)


func _bush(pos: Vector3, r: float) -> void:
	var variant := 1 + int(absf(pos.x + pos.z)) % 2
	_model("res://assets/models/shrub_0%d/shrub_0%d_1k.gltf" % [variant, variant], pos, r * 1.8, pos.x)


func _flower_bed(pos: Vector3, size: Vector2) -> void:
	_box(self, Vector3(size.x, 0.12, size.y), pos + Vector3(0, 0.06, 0), surf.soil, false)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(pos.x * 100.0)
	var colors := [Color(0.7, 0.1, 0.12), Color(0.85, 0.75, 0.2), Color(0.85, 0.85, 0.8), Color(0.45, 0.25, 0.6)]
	for _i in 16:
		var f := CSGSphere3D.new()
		f.radius = 0.07
		f.position = pos + Vector3(rng.randf_range(-0.45, 0.45) * size.x, 0.2, rng.randf_range(-0.4, 0.4) * size.y)
		f.material = _mat(colors[rng.randi() % colors.size()])
		add_child(f)


## Schild an einem Pfahl, Schrift auf beiden Seiten lesbar.
func _sign(pos: Vector3, text: String, color: Color) -> void:
	_cyl(self, 0.04, 2.4, pos + Vector3(0, 1.2, 0), Color(0.45, 0.45, 0.45), true)
	_box(self, Vector3(0.62, 0.78, 0.03), pos + Vector3(0, 2.2, 0), color, false)
	for side in [1.0, -1.0]:
		var label := Label3D.new()
		label.text = text
		label.font_size = 40
		label.pixel_size = 0.0035
		label.modulate = Color(0.05, 0.05, 0.05)
		label.outline_size = 0
		label.double_sided = false
		label.position = pos + Vector3(0, 2.2, 0.02 * side)
		label.rotation.y = 0.0 if side > 0.0 else PI
		add_child(label)


func _bike(pos: Vector3) -> void:
	var frame := Color(0.45, 0.08, 0.07)
	for dx in [-0.5, 0.5]:
		var wheel := CSGTorus3D.new()
		wheel.inner_radius = 0.27
		wheel.outer_radius = 0.32
		wheel.rotation.x = PI / 2
		wheel.position = pos + Vector3(dx, 0.32, 0)
		wheel.material = _mat(Color(0.05, 0.05, 0.05))
		add_child(wheel)
	_box(self, Vector3(0.75, 0.04, 0.04), pos + Vector3(0, 0.7, 0), frame, false)
	var down := _box(self, Vector3(0.7, 0.04, 0.04), pos + Vector3(0.05, 0.5, 0), frame, false)
	down.rotation.z = 0.6
	_box(self, Vector3(0.22, 0.05, 0.1), pos + Vector3(-0.3, 0.85, 0), Color(0.05, 0.05, 0.05), false)
	_box(self, Vector3(0.04, 0.04, 0.45), pos + Vector3(0.42, 0.9, 0), Color(0.3, 0.3, 0.3), false)


## Herbstlaub als MultiMesh: viele kleine flache Blätter, nicht in Häusern.
func _leaves(count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1987
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	var quad := QuadMesh.new()
	quad.size = Vector2(0.14, 0.1)
	quad.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = count
	mm.mesh = quad
	var colors := [Color(0.45, 0.25, 0.08), Color(0.55, 0.35, 0.1), Color(0.35, 0.2, 0.1), Color(0.5, 0.42, 0.15)]
	var i := 0
	while i < count:
		var pos := Vector3(rng.randf_range(-40, 48), 0.04, rng.randf_range(-10, 48))
		if _inside_house(pos):
			continue
		var rot := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, -PI / 2)
		mm.set_instance_transform(i, Transform3D(rot, pos))
		mm.set_instance_color(i, colors[rng.randi() % colors.size()])
		i += 1
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(inst)


func _inside_house(p: Vector3) -> bool:
	var rects := [Vector4(0, 0, 6.2, 5.2)]  # x, z, halbe Breite, halbe Tiefe
	for x0 in [-16.0, 16.0, 32.0]:
		rects.append(Vector4(x0, 0, 5.2, 4.2))
	for x0 in [-25.0, -9.0, 7.0, 23.0]:
		rects.append(Vector4(x0, 36, 5.2, 4.2))
	for r in rects:
		if absf(p.x - r.x) < r.z and absf(p.z - r.y) < r.w:
			return true
	return false


func _build_house() -> void:
	var wall: Material = surf.siding
	var ground := CSGCombiner3D.new()
	ground.use_collision = true
	add_child(ground)
	# Erdgeschoss: Außenbox minus Innenraum ergibt Wände, Boden und Decke
	_box(ground, Vector3(12, 3, 10), Vector3(0, 1.4, 0), wall, false)
	_sub(ground, Vector3(11.6, 2.8, 9.6), Vector3(0, 1.4, 0), wall)
	_sub(ground, Vector3(1.2, 2.2, 0.6), Vector3(0, 1.1, 4.9), wall)       # Haustür
	_sub(ground, Vector3(1.6, 1.2, 0.6), Vector3(-3.5, 1.5, 4.9), wall)    # Fenster vorne
	_sub(ground, Vector3(1.6, 1.2, 0.6), Vector3(3.5, 1.5, 4.9), wall)
	_sub(ground, Vector3(0.6, 1.2, 1.6), Vector3(-5.9, 1.5, 2.5), wall)    # Fenster Seiten
	_sub(ground, Vector3(0.6, 1.2, 1.6), Vector3(5.9, 1.5, -2.5), wall)
	_sub(ground, Vector3(5.3, 0.4, 1.4), Vector3(-3.15, 2.85, -4.0), wall) # Treppenloch
	_box(ground, Vector3(11.6, 2.8, 0.15), Vector3(0, 1.4, 0), wall, false) # Innenwand
	_sub(ground, Vector3(1.2, 2.2, 0.4), Vector3(2.5, 1.1, 0), wall)       # Durchgang Küche

	_box(self, Vector3(11.6, 0.02, 9.6), Vector3(0, 0.01, 0), surf.wood, false)
	# Dielen oben, ohne das Treppenloch (x -5,8 bis -0,5, z -4,7 bis -3,3)
	_box(self, Vector3(11.6, 0.02, 8.1), Vector3(0, 3.01, 0.75), surf.wood, false)
	_box(self, Vector3(6.3, 0.02, 1.5), Vector3(2.65, 3.01, -4.05), surf.wood, false)

	# Obergeschoss, begehbar: Boden auf y = 3
	var upper := CSGCombiner3D.new()
	upper.use_collision = true
	add_child(upper)
	_box(upper, Vector3(12, 3, 10), Vector3(0, 4.4, 0), wall, false)
	_sub(upper, Vector3(11.6, 2.8, 9.6), Vector3(0, 4.4, 0), wall)
	_sub(upper, Vector3(5.3, 0.4, 1.4), Vector3(-3.15, 2.95, -4.0), wall)  # Treppenloch
	for x in [-3.5, 0.0, 3.5]:
		_sub(upper, Vector3(1.4, 1.2, 0.6), Vector3(x, 4.5, 4.9), wall)
	_box(upper, Vector3(11.6, 2.8, 0.15), Vector3(0, 4.4, 0), wall, false) # Innenwand
	_sub(upper, Vector3(1.2, 2.2, 0.4), Vector3(-4.0, 4.1, 0), wall)       # Tür Kinderzimmer

	# Scheiben und Zierleisten an den Fensteröffnungen, Rahmen um die Haustür
	for w in [[Vector3(-3.5, 1.5, 4.9), Vector2(1.6, 1.2)], [Vector3(3.5, 1.5, 4.9), Vector2(1.6, 1.2)],
			[Vector3(-3.5, 4.5, 4.9), Vector2(1.4, 1.2)], [Vector3(0, 4.5, 4.9), Vector2(1.4, 1.2)],
			[Vector3(3.5, 4.5, 4.9), Vector2(1.4, 1.2)]]:
		var size: Vector2 = w[1]
		_box(self, Vector3(size.x, size.y, 0.02), w[0], surf.pane, false)
		_frame(self, w[0] + Vector3(0, 0, 0.13), size)
	_frame(self, Vector3(0, 1.1, 5.03), Vector2(1.2, 2.2))
	for side in [[Vector3(-5.9, 1.5, 2.5), PI / 2], [Vector3(5.9, 1.5, -2.5), -PI / 2]]:
		var p := _box(self, Vector3(1.6, 1.2, 0.02), side[0], surf.pane, false)
		p.rotation.y = side[1]

	# Giebel, Veranda mit Dach und Pfosten, Schornstein
	for x in [-5.95, 5.95]:
		_gable(self, Vector3(x, 5.9, 0), 5.0, 3.5, wall)
	for x in [-2.8, 2.8]:
		_cyl(self, 0.08, 2.5, Vector3(x, 1.25, 7.85), Color(0.88, 0.86, 0.82), true)
	var porch_roof := _box(self, Vector3(6.4, 0.12, 3.2), Vector3(0, 2.62, 6.5), surf.roof, false)
	porch_roof.rotation.x = 0.1
	_box(self, Vector3(0.8, 2.6, 0.8), Vector3(3.5, 8.4, -1.5), surf.concrete, false)

	var roof: Material = surf.roof
	var front := _box(self, Vector3(12.8, 0.2, 6.4), Vector3(0, 7.65, 2.5), roof, false)
	front.rotation.x = deg_to_rad(35)
	var back := _box(self, Vector3(12.8, 0.2, 6.4), Vector3(0, 7.65, -2.5), roof, false)
	back.rotation.x = deg_to_rad(-35)

	# Umzugskartons im Wohnzimmer
	_crate(Vector3(0.6, 0.5, 0.5), Vector3(-3, 0.25, 2))
	_crate(Vector3(0.6, 0.5, 0.5), Vector3(-3, 0.75, 2))
	_crate(Vector3(0.8, 0.6, 0.6), Vector3(-2, 0.3, 3.5))
	_crate(Vector3(0.6, 0.5, 0.5), Vector3(4, 0.25, 1.2))
	var photos = _interactable(Vector3(3.2, 0.25, 2.8), Vector3(0.6, 0.5, 0.5), CARDBOARD, "PROMPT_LOOK")
	photos.used.connect(func() -> void: ui.show_thought("THOUGHT_PHOTOS", 4.0))

	# Teppich, auf dem die Kartons aus dem Auto landen
	drop_spot = _interactable(Vector3(1.6, 0.05, 2.8), Vector3(1.6, 0.1, 1.2), Color(0.35, 0.15, 0.12), "PROMPT_DROP")
	drop_spot.enabled = false
	drop_spot.used.connect(_on_drop_used)

	# Küche und verschlossene Kellertür
	var counter = _interactable(Vector3(5.4, 0.45, -2.0), Vector3(0.7, 0.9, 2.0), Color(0.5, 0.5, 0.48), "PROMPT_LOOK")
	counter.used.connect(func() -> void: ui.show_thought("THOUGHT_KITCHEN", 4.0))
	var cellar = _interactable(Vector3(4.0, 1.05, -4.74), Vector3(1.0, 2.1, 0.1), Color(0.3, 0.22, 0.16), "PROMPT_DOOR")
	cellar.used.connect(_on_cellar_used)

	# Kinderzimmer oben: Bleistiftstriche an der Wand
	var marks = _interactable(Vector3(-3.0, 4.0, 0.12), Vector3(0.25, 1.0, 0.06), Color(0.8, 0.78, 0.7), "PROMPT_LOOK")
	marks.used.connect(_on_kidsroom_used)

	# Licht innen
	for l in [[Vector3(0, 2.5, 2.5), 0.8], [Vector3(0, 2.5, -2.5), 0.4],
			[Vector3(0, 5.4, 2.5), 0.6], [Vector3(-2, 5.4, -2.5), 0.4]]:
		var lamp := OmniLight3D.new()
		lamp.position = l[0]
		lamp.light_color = Color(1.0, 0.85, 0.65)
		lamp.light_energy = l[1]
		lamp.omni_range = 7.0
		add_child(lamp)
		_cyl(self, 0.18, 0.12, l[0] + Vector3(0, 0.2, 0), surf.lamp_shade)

	_build_interior()


## Möbel und Kleinkram im Haus.
func _build_interior() -> void:
	var wood: Material = surf.wood

	# Wohnzimmer: Sofa an der Innenwand, Couchtisch, Stehlampe, Regal, Bilder
	_model("res://assets/models/Sofa_01/Sofa_01_1k.gltf", Vector3(-4.4, 0, 0.6), 0.85)
	_solid(Vector3(2.0, 0.85, 0.85), Vector3(-4.4, 0.425, 0.6))
	_box(self, Vector3(1.0, 0.05, 0.55), Vector3(-4.5, 0.42, 1.9), wood, true)
	for dx in [-0.45, 0.45]:
		for dz in [-0.22, 0.22]:
			_cyl(self, 0.025, 0.4, Vector3(-4.5 + dx, 0.2, 1.9 + dz), wood)
	_cyl(self, 0.02, 1.5, Vector3(-5.5, 0.75, 1.4), Color(0.1, 0.1, 0.1))
	_cyl(self, 0.2, 0.3, Vector3(-5.5, 1.6, 1.4), surf.lamp_shade)
	var floor_lamp := OmniLight3D.new()
	floor_lamp.position = Vector3(-5.5, 1.5, 1.4)
	floor_lamp.light_color = Color(1.0, 0.78, 0.5)
	floor_lamp.light_energy = 0.5
	floor_lamp.omni_range = 4.0
	add_child(floor_lamp)
	const M := "res://assets/models/%s/%s_1k.gltf"
	_model(M % ["wooden_bookshelf_worn", "wooden_bookshelf_worn"], Vector3(5.5, 0, 3.5), 1.8, -PI / 2)
	_solid(Vector3(0.4, 1.8, 1.2), Vector3(5.6, 0.9, 3.5))
	_model(M % ["drawer_cabinet", "drawer_cabinet"], Vector3(3.6, 0, 0.35), 0.9)
	_solid(Vector3(1.0, 0.9, 0.5), Vector3(3.6, 0.45, 0.35))
	_model(M % ["Television_01", "Television_01"], Vector3(3.6, 0.9, 0.35), 0.45)
	_model(M % ["ArmChair_01", "ArmChair_01"], Vector3(-2.0, 0, 1.0), 0.9, -PI / 2)
	_solid(Vector3(0.8, 0.9, 0.8), Vector3(-2.0, 0.45, 1.0))
	_model(M % ["ceramic_vase_01", "ceramic_vase_01"], Vector3(-4.5, 0.445, 1.9), 0.25)
	_model(M % ["ceiling_fan", "ceiling_fan"], Vector3(-2.5, 2.45, 2.5), 0.35)
	_model(M % ["hanging_picture_frame_01", "hanging_picture_frame_01"], Vector3(1.2, 1.35, 0.1), 0.5)
	_model(M % ["hanging_picture_frame_02", "hanging_picture_frame_02"], Vector3(-5.75, 1.35, 3.2), 0.5, PI / 2)

	# Küche: Kühlschrank, Herd, Hängeschrank, Uhr, Tisch mit zwei Stühlen
	_box(self, Vector3(0.7, 1.8, 0.7), Vector3(5.35, 0.9, -4.3), Color(0.82, 0.82, 0.78), true)
	_model(M % ["electric_stove", "electric_stove"], Vector3(5.4, 0, -0.6), 0.9, -PI / 2)
	_solid(Vector3(0.65, 0.9, 0.65), Vector3(5.4, 0.45, -0.6))
	_box(self, Vector3(0.4, 0.7, 2.0), Vector3(5.6, 2.0, -2.0), wood, false)
	_model(M % ["wall_clock", "wall_clock"], Vector3(4.5, 1.8, -0.1), 0.3, PI)
	_model(M % ["WoodenTable_01", "WoodenTable_01"], Vector3(2.8, 0, -2.2), 0.77, PI / 2)
	_solid(Vector3(0.8, 0.77, 1.2), Vector3(2.8, 0.385, -2.2))
	for side in [[-0.65, 0.0], [0.65, PI]]:
		_model(M % ["WoodenChair_01", "WoodenChair_01"], Vector3(2.8, 0, -2.2 + side[0] * 1.1), 0.9, side[1])
		_solid(Vector3(0.45, 0.9, 0.45), Vector3(2.8, 0.45, -2.2 + side[0] * 1.1))

	# Kinderzimmer: Bettgestell, Teppich, Schreibtisch, Spielzeugkiste; Kartons im Flur oben
	_model(M % ["old_bed_frame", "old_bed_frame"], Vector3(4.5, 3.0, 2.0), 0.9)
	_solid(Vector3(1.0, 0.5, 2.0), Vector3(4.5, 3.25, 2.0))
	_box(self, Vector3(1.6, 0.02, 1.2), Vector3(2.4, 3.03, 2.3), _surface(Color(0.45, 0.35, 0.55), Vector3.ONE * 2.0, 1.0, 0.3), false)
	_box(self, Vector3(1.0, 0.75, 0.5), Vector3(1.0, 3.375, 4.4), wood, true)
	_box(self, Vector3(0.6, 0.4, 0.4), Vector3(-1.5, 3.2, 4.3), Color(0.7, 0.25, 0.2), true)
	_crate(Vector3(0.6, 0.5, 0.5), Vector3(3.5, 3.25, -2.5))
	_crate(Vector3(0.6, 0.5, 0.5), Vector3(3.5, 3.75, -2.5))


## Umzugskarton: CC0-Modell plus Kollision; pos ist die Mitte.
func _crate(size: Vector3, pos: Vector3) -> void:
	_model("res://assets/models/cardboard_box_01/cardboard_box_01_1k.gltf", pos - Vector3(0, size.y / 2.0, 0), size.y, pos.x)
	_solid(size, pos)


## Treppe an der Rückwand: sichtbare Stufen, Kollision ist eine glatte Rampe
## über die Stufenkanten, damit der CharacterBody3D hochkommt.
func _build_stairs() -> void:
	var wood := Color(0.35, 0.26, 0.18)
	var steps := 12
	var rise := 3.0 / steps
	var run := 0.425
	var nose_x := 0.5  # Vorderkante der untersten Stufe
	for i in steps:
		var h := rise * (i + 1)
		# Kollision verhindert, dass man unter die Treppe läuft. Die Stufen liegen nie über der Rampe.
		_box(self, Vector3(run, h, 1.4), Vector3(nose_x - (i + 0.5) * run, h / 2.0, -4.0), wood, true)

	var start := Vector2(nose_x + run, 0.0)
	var end := Vector2(nose_x - (steps - 1) * run, 3.0)
	var angle := atan2(end.y - start.y, start.x - end.x)
	var mid := (start + end) / 2.0
	var ramp := StaticBody3D.new()
	# Oberseite der 0,2 m dicken Rampe liegt genau auf der Linie der Stufenkanten.
	ramp.position = Vector3(mid.x - 0.1 * sin(angle), mid.y - 0.1 * cos(angle), -4.0)
	ramp.rotation.z = -angle
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(start.distance_to(end), 0.2, 1.4)
	shape.shape = box
	ramp.add_child(shape)
	add_child(ramp)

	# Podest oben und Geländer am Treppenloch
	_box(self, Vector3(5.8 + end.x, 0.2, 1.4), Vector3((end.x - 5.8) / 2.0, 2.9, -4.0), wood, true)
	_box(self, Vector3(-0.5 - end.x, 1.0, 0.06), Vector3((end.x - 0.5) / 2.0, 3.5, -3.27), wood, true)
	_box(self, Vector3(0.06, 1.0, 1.4), Vector3(-0.47, 3.5, -4.0), wood, true)


## Graybox-Nachbarhaus. flipped: Front zeigt nach -z (andere Straßenseite).
func _neighbor_house(x: float, z: float, color: Color, flipped: bool, with_mailbox: bool) -> void:
	var h := Node3D.new()
	h.position = Vector3(x, 0, z)
	h.rotation.y = PI if flipped else 0.0
	add_child(h)
	var sidewalk := 12.0 if flipped else 16.0  # Abstand Hausmitte bis Gehweg
	_box(h, Vector3(10, 5.5, 8), Vector3(0, 2.75, 0), _surface(color, Vector3.ONE * 0.4, 2.0, 0.06), true)
	var roof: Material = surf.roof
	var front := _box(h, Vector3(10.6, 0.2, 5.2), Vector3(0, 7.0, 2.1), roof, false)
	front.rotation.x = deg_to_rad(35)
	var back := _box(h, Vector3(10.6, 0.2, 5.2), Vector3(0, 7.0, -2.1), roof, false)
	back.rotation.x = deg_to_rad(-35)
	for gx in [-4.95, 4.95]:
		_gable(h, Vector3(gx, 5.5, 0), 4.0, 3.0, h.get_child(0).material)
	for px in [-1.8, 1.8]:
		_cyl(h, 0.07, 2.4, Vector3(px, 1.2, 5.9), Color(0.88, 0.86, 0.82), true)
	var porch_roof := _box(h, Vector3(4.4, 0.12, 2.2), Vector3(0, 2.5, 5.0), surf.roof, false)
	porch_roof.rotation.x = 0.1
	_box(h, Vector3(1.1, 2.1, 0.06), Vector3(0, 1.05, 4.02), Color(0.2, 0.14, 0.1), false)
	for wx in [-3.0, 3.0]:
		for wy in [1.6, 4.1]:
			# Ein Fenster pro Haus ist von innen beleuchtet.
			var pane: Variant = surf.lit_window if wx > 0.0 and wy < 2.0 else surf.glass
			_box(h, Vector3(1.4, 1.1, 0.06), Vector3(wx, wy, 4.02), pane, false)
			_frame(h, Vector3(wx, wy, 4.06), Vector2(1.4, 1.1))
	_frame(h, Vector3(0, 1.05, 4.06), Vector2(1.1, 2.1))
	_box(h, Vector3(4, 0.04, 2), Vector3(0, 0.02, 5), Color(0.35, 0.27, 0.2), false)
	_box(h, Vector3(3, 0.02, sidewalk + 9), Vector3(-6.5, 0.012, (sidewalk - 9) / 2.0), surf.concrete, false)
	if with_mailbox:
		_box(h, Vector3(0.1, 1.0, 0.1), Vector3(2.5, 0.5, sidewalk - 0.3), Color(0.15, 0.15, 0.15), false)
		_box(h, Vector3(0.35, 0.3, 0.5), Vector3(2.5, 1.15, sidewalk - 0.3), Color(0.2, 0.2, 0.22), false)


## Dreieckiger Giebel unter dem Satteldach: Grundlinie half_depth nach vorn und hinten, Spitze height darüber.
func _gable(parent: Node, pos: Vector3, half_depth: float, height: float, look: Variant) -> void:
	var g := CSGPolygon3D.new()
	g.polygon = PackedVector2Array([Vector2(-half_depth, 0), Vector2(half_depth, 0), Vector2(0, height)])
	g.depth = 0.2
	g.position = pos + Vector3(0.1, 0, 0)
	g.rotation.y = PI / 2
	g.material = _look(look)
	parent.add_child(g)


## Weiße Zierleiste um ein Fenster oder eine Tür in der xy-Ebene (Front zeigt nach +z).
func _frame(parent: Node, center: Vector3, size: Vector2) -> void:
	var trim := Color(0.88, 0.86, 0.82)
	var t := 0.09
	_box(parent, Vector3(size.x + t * 2.0, t, 0.06), center + Vector3(0, size.y / 2.0 + t / 2.0, 0), trim, false)
	_box(parent, Vector3(size.x + t * 3.0, t * 1.3, 0.12), center - Vector3(0, size.y / 2.0 + t / 2.0, -0.03), trim, false)
	for side in [-1.0, 1.0]:
		_box(parent, Vector3(t, size.y, 0.06), center + Vector3(side * (size.x / 2.0 + t / 2.0), 0, 0), trim, false)


## Einfache Figur, die Nase zeigt die Blickrichtung (-z). Der rechte Arm liegt in meta "arm".
func _person(pos: Vector3, body_color: Color, skin: Color) -> Node3D:
	var p := Node3D.new()
	p.position = pos
	add_child(p)
	_cyl(p, 0.24, 1.5, Vector3(0, 0.75, 0), body_color)
	var head := CSGSphere3D.new()
	head.radius = 0.14
	head.position.y = 1.68
	head.material = _mat(skin)
	p.add_child(head)
	_box(p, Vector3(0.06, 0.06, 0.1), Vector3(0, 1.66, -0.15), skin, false)
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(0.3 * side, 1.42, 0)
		p.add_child(pivot)
		_box(pivot, Vector3(0.1, 0.6, 0.1), Vector3(0, -0.3, 0), body_color, false)
		if side > 0.0:
			p.set_meta("arm", pivot)
	return p


## Limousine der 80er, Front zeigt nach -z. see_through: Seitenscheiben durchsichtig (Fahrer sichtbar).
func _car(pos: Vector3, rot_y: float, color: Color, collide: bool, see_through: bool = false) -> Node3D:
	var c := Node3D.new()
	c.position = pos
	c.rotation.y = rot_y
	add_child(c)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	paint.metallic = 0.5
	paint.roughness = 0.35
	paint.clearcoat_enabled = true
	var glass: Material = surf.pane if see_through else surf.glass
	var dark := Color(0.05, 0.05, 0.05)
	_box(c, Vector3(1.8, 0.55, 4.5), Vector3(0, 0.55, 0), paint, collide)          # Karosserie
	_box(c, Vector3(1.64, 0.5, 1.7), Vector3(0, 1.07, 0.3), glass, false)          # Seitenscheiben
	_box(c, Vector3(1.66, 0.06, 1.6), Vector3(0, 1.34, 0.3), paint, false)         # Dach
	var front := _box(c, Vector3(1.6, 0.62, 0.04), Vector3(0, 1.06, -0.72), glass, false)
	front.rotation.x = -0.65
	var rear := _box(c, Vector3(1.6, 0.58, 0.04), Vector3(0, 1.06, 1.3), glass, false)
	rear.rotation.x = 0.6
	for z in [-2.28, 2.28]:
		_box(c, Vector3(1.86, 0.18, 0.12), Vector3(0, 0.38, z), dark, false)       # Stoßstangen
	for x in [-0.62, 0.62]:
		_box(c, Vector3(0.36, 0.14, 0.03), Vector3(x, 0.66, -2.26), surf.lamp_shade, false)
		_box(c, Vector3(0.36, 0.12, 0.03), Vector3(x, 0.66, 2.26), Color(0.45, 0.04, 0.03), false)
	for wx in [-0.84, 0.84]:
		for wz in [-1.4, 1.4]:
			var wheel := _cyl(c, 0.33, 0.24, Vector3(wx, 0.33, wz), dark)
			wheel.rotation.z = PI / 2
			var hub := _cyl(c, 0.19, 0.25, Vector3(wx * 1.01, 0.33, wz), Color(0.55, 0.55, 0.55))
			hub.rotation.z = PI / 2
	return c


func _lamp(pos: Vector3) -> void:
	_model("res://assets/models/street_lamp_01/street_lamp_01_1k.gltf", pos, 4.4)
	_solid(Vector3(0.2, 4.0, 0.2), pos + Vector3(0, 2.0, 0))
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 4.0, 0)
	light.light_color = Color(1.0, 0.8, 0.55)
	light.light_energy = 0.6
	light.omni_range = 9.0
	add_child(light)


## Weißer Lattenzaun zwischen zwei Punkten auf einer Achse: Latten als MultiMesh, eine Kollisionsbox.
func _fence(a: Vector3, b: Vector3) -> void:
	var paint := _pbr("weathered_plank_siding", 2.0, Color(0.92, 0.9, 0.86))
	var length := a.distance_to(b)
	var dir := (b - a).normalized()
	var along_x := absf(dir.x) > 0.5
	_solid(Vector3(length if along_x else 0.1, 1.0, 0.1 if along_x else length), (a + b) / 2.0 + Vector3(0, 0.5, 0))
	for y in [0.3, 0.75]:
		_box(self, Vector3(length if along_x else 0.04, 0.07, 0.04 if along_x else length), (a + b) / 2.0 + Vector3(0, y, 0), paint, false)
	var picket := BoxMesh.new()
	picket.size = Vector3(0.08, 1.0, 0.025) if along_x else Vector3(0.025, 1.0, 0.08)
	picket.material = paint
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = int(length / 0.14)
	mm.mesh = picket
	for i in mm.instance_count:
		mm.set_instance_transform(i, Transform3D(Basis(), a + dir * (i * 0.14 + 0.07) + Vector3(0, 0.5, 0)))
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	add_child(inst)


## Baum: Stamm und eine unregelmäßige Krone aus mehreren Laubkugeln.
func _tree(pos: Vector3) -> void:
	var trunk_node := CSGCylinder3D.new()
	trunk_node.radius = 0.2
	trunk_node.height = 3.4
	trunk_node.position = pos + Vector3(0, 1.7, 0)
	trunk_node.material = surf.bark
	trunk_node.use_collision = true
	add_child(trunk_node)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(pos.x * 31.0 + pos.z * 17.0)
	for _i in 7:
		var crown := CSGSphere3D.new()
		crown.radius = rng.randf_range(0.9, 1.5)
		crown.radial_segments = 16
		crown.rings = 10
		crown.position = pos + Vector3(rng.randf_range(-1.2, 1.2), rng.randf_range(3.4, 5.0), rng.randf_range(-1.2, 1.2))
		crown.material = surf.hedge
		add_child(crown)


## Dichtes Gras auf den Rasenflächen: das CC0-Grasbüschel als MultiMesh.
func _grass_field(count: int) -> void:
	var scene: Node3D = load("res://assets/models/grass_medium_01/grass_medium_01_1k.gltf").instantiate()
	var source: MeshInstance3D = scene.find_children("*", "MeshInstance3D", true, false)[0]
	var mesh: Mesh = source.mesh
	var base_scale := 0.35 / maxf(mesh.get_aabb().size.y, 0.001)
	scene.free()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = count
	mm.mesh = mesh
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var i := 0
	while i < count:
		var p := Vector3(rng.randf_range(-40, 48), 0, rng.randf_range(-12, 48))
		if _inside_house(p) or _on_pavement(p):
			continue
		var s := base_scale * rng.randf_range(0.7, 1.4)
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * s), p))
		i += 1
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(inst)


## Straße, Gehwege, Einfahrten und Wege, auf denen kein Gras wächst.
func _on_pavement(p: Vector3) -> bool:
	if p.z > 15.8 and p.z < 24.2:
		return true
	if absf(p.x + 4.0) < 1.7 and p.z > 4.5 or absf(p.x) < 0.9 and p.z > 4.5:
		return true
	for x0 in [-16.0, 16.0, 32.0]:
		if absf(p.x - (x0 - 6.5)) < 1.7 and p.z < 16.0:
			return true
	for x0 in [-25.0, -9.0, 7.0, 23.0]:
		if absf(p.x - (x0 + 6.5)) < 1.7 and p.z > 24.0:
			return true
	return false


# --- Hilfsfunktionen ------------------------------------------------------

func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


## Prozedurale Oberfläche: Rauschen als Farbvariation und Normal-Map, weltbezogen triplanar.
## scale streckt das Muster (z. B. flach und breit für Bretter), freq bestimmt die Körnung.
func _surface(color: Color, scale: Vector3, bump: float, freq: float = 0.04,
		noise_type: FastNoiseLite.NoiseType = FastNoiseLite.TYPE_SIMPLEX_SMOOTH) -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.noise_type = noise_type
	noise.frequency = freq
	noise.fractal_octaves = 5
	var ramp := Gradient.new()
	ramp.set_color(0, color.darkened(0.3))
	ramp.set_color(1, color.lightened(0.12))
	var albedo := NoiseTexture2D.new()
	albedo.noise = noise
	albedo.seamless = true
	albedo.color_ramp = ramp
	var normal := NoiseTexture2D.new()
	normal.noise = noise
	normal.seamless = true
	normal.as_normal_map = true
	normal.bump_strength = bump
	var m := StandardMaterial3D.new()
	m.albedo_texture = albedo
	m.normal_enabled = true
	m.normal_texture = normal
	m.roughness = 0.95
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = scale
	return m


## PBR-Material aus assets/textures/<id>/ (Farbe, Normal-Map, Rauheit), weltbezogen triplanar.
## scale = Kacheln pro Meter, tint färbt die Textur ein.
func _pbr(id: String, scale: float, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var base := "res://assets/textures/%s/%s_" % [id, id]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(base + "diff_1k.jpg")
	m.albedo_color = tint
	m.normal_enabled = true
	m.normal_texture = load(base + "nor_gl_1k.jpg")
	m.roughness_texture = load(base + "rough_1k.jpg")
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * scale
	return m


## Lädt ein glTF-Modell, skaliert es auf die gewünschte Höhe und stellt es mit der Unterseite auf pos.
func _model(path: String, pos: Vector3, height: float, rot_y: float = 0.0) -> Node3D:
	var inst: Node3D = load(path).instantiate()
	add_child(inst)
	var box := AABB()
	var first := true
	for mesh in inst.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = mesh.global_transform * mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	var s := height / maxf(box.size.y, 0.001)
	inst.scale = Vector3.ONE * s
	inst.rotation.y = rot_y
	inst.position = pos - Vector3(0, box.position.y * s, 0)
	return inst


## Unsichtbare Kollision für Modelle.
func _solid(size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)


func _look(look: Variant) -> Material:
	return look if look is Material else _mat(look)


## look: Farbe oder fertiges Material.
func _box(parent: Node, size: Vector3, pos: Vector3, look: Variant, collide: bool) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.material = _look(look)
	b.use_collision = collide
	parent.add_child(b)
	return b


func _cyl(parent: Node, radius: float, height: float, pos: Vector3, look: Variant, collide: bool = false) -> CSGCylinder3D:
	var c := CSGCylinder3D.new()
	c.radius = radius
	c.height = height
	c.position = pos
	c.material = _look(look)
	c.use_collision = collide
	parent.add_child(c)
	return c


func _sub(parent: Node, size: Vector3, pos: Vector3, look: Variant) -> void:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.material = _look(look)
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
		[Vector3(100, 10, 1), Vector3(4, 5, -15)],
		[Vector3(100, 10, 1), Vector3(4, 5, 50)],
		[Vector3(1, 10, 70), Vector3(-42, 5, 17)],
		[Vector3(1, 10, 70), Vector3(50, 5, 17)],
	]
	for w in walls:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = w[0]
		shape.shape = box
		shape.position = w[1]
		bounds.add_child(shape)
