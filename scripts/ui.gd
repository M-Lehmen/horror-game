extends CanvasLayer
## Bildschirmanzeigen: Aufgabe, Gedanken (Untertitel), Hinweise, Brief, Überblendungen.
## Alle Texte sind Übersetzungs-Keys. Labels übersetzen sie automatisch und
## aktualisieren sich, wenn die Sprache wechselt.

var task_label: Label
var subtitle: Label
var prompt_label: Label
var hint_label: Label
var crosshair: Label
var letter_root: CenterContainer
var letter_box: VBoxContainer
var fade: ColorRect
var flash: ColorRect
var center_label: Label
var _subtitle_id := 0
var _hint_id := 0
var _task_key := ""
var _task_suffix := ""
var _typewriter: SystemFont


func _ready() -> void:
	layer = 10
	_typewriter = SystemFont.new()
	_typewriter.font_names = PackedStringArray(["Courier New", "Courier", "Liberation Mono", "monospace"])

	task_label = _make_label(22)
	task_label.position = Vector2(24, 20)
	add_child(task_label)

	crosshair = _make_label(20)
	crosshair.text = "·"
	_fill_center(crosshair)
	add_child(crosshair)

	prompt_label = _make_label(20)
	_fill_center(prompt_label)
	prompt_label.offset_top = 80
	add_child(prompt_label)

	subtitle = _make_label(26)
	subtitle.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	subtitle.offset_left = 80
	subtitle.offset_right = -80
	subtitle.offset_top = -160
	subtitle.offset_bottom = -70
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(subtitle)

	hint_label = _make_label(16)
	hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint_label.offset_top = -40
	hint_label.offset_bottom = -12
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint_label)

	letter_root = CenterContainer.new()
	letter_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	letter_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	letter_root.visible = false
	add_child(letter_root)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.93, 0.9, 0.82)
	style.set_content_margin_all(40)
	panel.add_theme_stylebox_override("panel", style)
	letter_root.add_child(panel)
	letter_box = VBoxContainer.new()
	letter_box.add_theme_constant_override("separation", 14)
	panel.add_child(letter_box)

	flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.6, 0.0, 0.0, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	fade = ColorRect.new()
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)

	center_label = _make_label(36)
	_fill_center(center_label)
	add_child(center_label)


func _make_label(size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _fill_center(l: Label) -> void:
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


## suffix wird unübersetzt angehängt, z. B. " (1/3)".
func set_task(key: String, suffix: String = "") -> void:
	_task_key = key
	_task_suffix = suffix
	_refresh_task()


func _refresh_task() -> void:
	task_label.text = tr(_task_key) + _task_suffix if _task_key != "" else ""


func _notification(what: int) -> void:
	# Mit Suffix ist der Text kein Key mehr, deshalb beim Sprachwechsel selbst neu setzen.
	if what == NOTIFICATION_TRANSLATION_CHANGED and task_label != null:
		_refresh_task()


func set_prompt(key: String) -> void:
	prompt_label.text = key


## Zeigt einen Gedanken der Spielfigur als Untertitel.
func show_thought(key: String, duration: float = 4.0) -> void:
	_subtitle_id += 1
	var id := _subtitle_id
	subtitle.text = key
	await get_tree().create_timer(duration).timeout
	if id == _subtitle_id:
		subtitle.text = ""


func show_hint(key: String, duration: float = 8.0) -> void:
	_hint_id += 1
	var id := _hint_id
	hint_label.text = key
	await get_tree().create_timer(duration).timeout
	if id == _hint_id:
		hint_label.text = ""


func show_letter(keys: Array[String]) -> void:
	for child in letter_box.get_children():
		child.queue_free()
	for key in keys:
		var l := Label.new()
		l.text = key
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(560, 0)
		l.add_theme_font_override("font", _typewriter)
		l.add_theme_font_size_override("font_size", 20)
		l.add_theme_color_override("font_color", Color(0.12, 0.1, 0.1))
		letter_box.add_child(l)
	letter_root.visible = true
	crosshair.visible = false
	set_prompt("PROMPT_CLOSE")


func hide_letter() -> void:
	letter_root.visible = false
	crosshair.visible = true
	set_prompt("")


func fade_to(alpha: float, duration: float) -> Tween:
	var t := create_tween()
	t.tween_property(fade, "color:a", alpha, duration)
	return t


func flash_red() -> void:
	var t := create_tween()
	t.tween_property(flash, "color:a", 0.7, 0.08)
	t.tween_property(flash, "color:a", 0.0, 0.4)


func show_center(key: String) -> void:
	crosshair.visible = false
	set_task("")
	set_prompt("")
	center_label.text = key
