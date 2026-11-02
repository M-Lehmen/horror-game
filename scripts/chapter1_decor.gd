extends "res://scripts/world_kit.gd"
## Kapitel 1: Außendeko der Nachbarschaft (Pflanzen, Zäune, Laternen, Straßenmöbel, Gras, Laub).

## Hausmitten (x) der eigenen Straßenseite (z = 0, ohne Claires Haus bei x = 0) und gegenüber (z = 36).
var near_row: Array[float] = []
var far_row: Array[float] = []


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


func _inside_house(p: Vector3) -> bool:
	if absf(p.x) < 6.2 and absf(p.z) < 5.2:  # Claires Haus
		return true
	var row: Array[float] = near_row if p.z < 18.0 else far_row
	var z0 := 0.0 if p.z < 18.0 else 36.0
	for x0 in row:
		if absf(p.x - x0) < 5.2 and absf(p.z - z0) < 4.2:
			return true
	return false


func _lamp(pos: Vector3) -> void:
	_model("res://assets/models/street_lamp_01/street_lamp_01_1k.gltf", pos, 4.4)
	_solid(Vector3(0.2, 4.0, 0.2), pos + Vector3(0, 2.0, 0))
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 4.0, 0)
	light.light_color = Color(1.0, 0.8, 0.55)
	light.light_energy = 0.6
	light.omni_range = 9.0
	light.distance_fade_enabled = true
	light.distance_fade_begin = 60.0
	light.distance_fade_length = 20.0
	add_child(light)
