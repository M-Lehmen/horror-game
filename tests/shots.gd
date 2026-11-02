extends SceneTree
## Misst die FPS im Fenster und speichert Screenshots aus Spielerposition.
## Start: godot --path . --resolution 1920x1080 -s res://tests/shots.gd -- <name> [<zielordner>]
## Ohne Zielordner landen die Bilder im Godot-Benutzerordner unter screens/.

var tag := "shots"
var out := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		tag = args[0]
	out = args[1] if args.size() > 1 else OS.get_user_data_dir() + "/screens"
	if not out.ends_with("/"):
		out += "/"
	_run()


func frames(n: int) -> void:
	for _i in n:
		await process_frame


func _shot(name: String) -> void:
	root.get_viewport().get_texture().get_image().save_png(out + "%s_%s.png" % [tag, name])


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	var scene = load("res://scenes/chapter1.tscn").instantiate()
	root.add_child(scene)
	await frames(10)
	var p = scene.player
	var views := [
		["einfahrt", Vector3(-2.2, 0.1, 14.2), 0.0, -0.05],
		["strasse", Vector3(2.5, 0.1, 13.5), PI + 0.35, 0.0],
		["wohnzimmer", Vector3(-4.5, 0.1, 3.5), -2.3, -0.15],
		["sofa", Vector3(-1.5, 0.1, 3.8), 0.73, -0.25],
		["vorgarten", Vector3(-1.0, 0.1, 22.0), 2.6, -0.1],
		["kueche", Vector3(0.8, 0.1, -1.0), -1.9, -0.2],
		["kinderzimmer", Vector3(0.0, 3.1, 1.0), -1.79, -0.3],
		["strasse_ost", Vector3(40, 0.1, 20), -PI / 2, 0.0],
		["strasse_west", Vector3(-100, 0.1, 20), PI / 2, 0.0],
		["absperrung", Vector3(-170, 0.1, 19), PI / 2 - 0.25, 0.0],
		["sackgasse", Vector3(170, 0.1, 21), -PI / 2 + 0.25, 0.0],
	]
	var fps_sum := 0.0
	for v in views:
		p.global_position = v[1]
		p.rotation.y = v[2]
		p.camera.rotation.x = v[3]
		await frames(180)  # SDFGI und Schatten einschwingen lassen
		fps_sum += Engine.get_frames_per_second()
		_shot(v[0])
	# Walter beim Mähen, dann die Gestalt hinter der Hecke nach dem Brief
	p.global_position = Vector3(-6.5, 0.1, 12.5)
	p.rotation.y = 1.35
	p.camera.rotation.x = -0.05
	await frames(90)
	_shot("walter")
	scene._after_letter()
	p.global_position = Vector3(2.5, 0.1, 14.5)
	p.rotation.y = -2.715
	p.camera.rotation.x = 0.0
	await frames(20)
	_shot("beobachter")
	print("FPS_AVG %.0f" % (fps_sum / views.size()))
	quit()
