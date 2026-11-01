extends CharacterBody3D
## First-Person-Spieler: laufen, umsehen, ducken, interagieren.

signal focus_changed(prompt: String)

const SPEED := 3.0
const CROUCH_SPEED := 1.4
const MOUSE_SENS := 0.002
const GRAVITY := 9.8
const STAND_HEIGHT := 1.6
const CROUCH_HEIGHT := 1.0

var camera: Camera3D
var ray: RayCast3D
var can_move := true
var focused: Node = null


func _ready() -> void:
	add_to_group("player")
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)

	camera = Camera3D.new()
	camera.position.y = STAND_HEIGHT
	camera.fov = 70.0
	add_child(camera)
	camera.make_current()

	ray = RayCast3D.new()
	ray.target_position = Vector3(0, 0, -2.2)
	ray.add_exception(self)
	camera.add_child(ray)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if not can_move:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		camera.rotate_x(-event.relative.y * MOUSE_SENS)
		camera.rotation.x = clampf(camera.rotation.x, -1.4, 1.4)
	elif event.is_action_pressed("interact") and focused != null:
		get_viewport().set_input_as_handled()
		focused.interact()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var crouching := can_move and Input.is_action_pressed("crouch")
	var target_height := CROUCH_HEIGHT if crouching else STAND_HEIGHT
	camera.position.y = lerpf(camera.position.y, target_height, 10.0 * delta)

	var direction := Vector3.ZERO
	if can_move:
		var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		direction = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	var speed := CROUCH_SPEED if crouching else SPEED
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	move_and_slide()

	if can_move:
		_update_focus()


## Prüft, ob der Spieler gerade auf etwas Benutzbares schaut.
func _update_focus() -> void:
	var new_focus: Node = null
	if ray.is_colliding():
		var hit := ray.get_collider()
		if hit != null and hit.has_method("interact") and hit.get("enabled"):
			new_focus = hit
	if new_focus != focused:
		focused = new_focus
		focus_changed.emit(focused.get("prompt") if focused != null else "")
