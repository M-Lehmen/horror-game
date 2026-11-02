extends Node3D
## Bausteine für die Graybox-Welt: Materialien, CSG-Formen, Modelle, Kollision, Auslöser.

const InteractableScript := preload("res://scripts/interactable.gd")

## Oberflächen-Materialien, gefüllt von _make_surfaces() in chapter1_world.gd.
var surf := {}
## Einfarbige Materialien nach Farbe, damit gleiche Farben dasselbe Material teilen.
var _mat_cache := {}


func _mat(color: Color) -> StandardMaterial3D:
	if _mat_cache.has(color):
		return _mat_cache[color]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_cache[color] = m
	return m


## Blendet alle sichtbaren Teile unter node ab dieser Entfernung aus (weit weg steht ohnehin Nebel).
func _fade_far(node: Node, distance: float = 130.0) -> void:
	for g in node.find_children("*", "GeometryInstance3D", true, false):
		g.visibility_range_end = distance
	if node is GeometryInstance3D:
		node.visibility_range_end = distance


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
## only_first: Modelle mit mehreren Varianten nebeneinander (z. B. Hydrant neu/alt) auf die erste kürzen.
func _model(path: String, pos: Vector3, height: float, rot_y: float = 0.0, only_first: bool = false) -> Node3D:
	var inst: Node3D = load(path).instantiate()
	if only_first:
		var meshes := inst.find_children("*", "MeshInstance3D", true, false)
		for i in range(1, meshes.size()):
			meshes[i].free()
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
