extends SceneTree
## Spieltest Kapitel 1: Treppe begehbar, kompletter Ablauf bis Kapitelende, Garten-Warnung und -Angriff.
## Start: godot --headless --path . -s res://tests/selftest.gd   (Exit-Code 0 = alles bestanden)

var failures := 0


func check(cond: bool, msg: String) -> void:
	print(("PASS " if cond else "FAIL ") + msg)
	if not cond:
		failures += 1


func frames(n: int) -> void:
	for _i in n:
		await physics_frame


func _initialize() -> void:
	_run()


func _new_scene():
	var scene = load("res://scenes/chapter1.tscn").instantiate()
	root.add_child(scene)
	await frames(10)
	return scene


func _run() -> void:
	var scene = await _new_scene()
	var p = scene.player

	# Treppe: unten vor der ersten Stufe, Blick nach -x, laufen
	p.global_position = Vector3(1.6, 0.1, -4.0)
	p.rotation.y = PI / 2
	Input.action_press("move_forward")
	await frames(240)
	check(p.global_position.y > 2.9, "Treppe hoch, y=%.2f x=%.2f" % [p.global_position.y, p.global_position.x])
	# Vom Podest ins Obergeschoss (+z)
	p.rotation.y = PI
	await frames(150)
	Input.action_release("move_forward")
	await frames(30)
	var pos: Vector3 = p.global_position
	check(pos.y > 2.9 and pos.z > -3.0, "Obergeschoss erreicht, pos=%s" % pos)

	# Ablauf
	p.global_position = Vector3(-2.2, 0.1, 14.2)
	for _i in 3:
		scene._on_trunk_used()
		check(scene.carrying, "Karton aufgenommen")
		scene._on_drop_used()
	check(scene.boxes_placed == 3 and scene.state == scene.State.EXPLORE, "3 Kartons, Erkunden")
	scene._on_kidsroom_used()
	check(scene.state == scene.State.EXPLORE, "nur Kinderzimmer reicht nicht")
	scene._on_cellar_used()
	check(scene.state == scene.State.MAIL and scene.mailbox.enabled, "Post holen")
	scene._on_mailbox_used()
	check(scene.state == scene.State.READING, "Brief lesen")
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	scene._unhandled_input(ev)
	check(scene.state == scene.State.AFTER_LETTER and scene.observer.visible, "Gestalt sichtbar")
	scene.observer_phase = 3
	scene.gone_time = 10.0
	await frames(3)
	check(scene.engine_started and scene.dark_car.visible, "Motor startet")
	p.global_position = Vector3(-3.0, 0.1, 14.0)
	await frames(3)
	check(scene.state == scene.State.CAR, "Wagen fährt los")
	Engine.time_scale = 8.0
	for _i in 120:
		await create_timer(1.0).timeout
		if scene.state == scene.State.DONE:
			break
	check(scene.same_man_shown, "Fahrer erkannt")
	check(scene.state == scene.State.DONE, "Kapitelende")
	Engine.time_scale = 1.0
	scene.queue_free()
	await frames(5)

	# Garten: erst Warnung, wer drin bleibt, wird nach Ablauf des Timers angegriffen
	scene = await _new_scene()
	p = scene.player
	scene._after_letter()
	p.global_position = Vector3(6, 0.1, 27)
	await frames(10)
	check(scene.garden_warning_armed and scene.state == scene.State.AFTER_LETTER, "Garten: Warnung statt Angriff")
	await create_timer(3.3).timeout
	check(scene.state == scene.State.DEAD, "Garten: Angriff nach Warnung, wenn man bleibt")

	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)
