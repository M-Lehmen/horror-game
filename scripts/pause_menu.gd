extends CanvasLayer
## Pause und Einstellungen. Alle sichtbaren Strings sind Übersetzungs-Keys.

var panel: Control
var pause_open := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    layer = 30
    panel = CenterContainer.new()
    panel.set_anchors_preset(Control.PRESET_FULL_RECT)
    panel.visible = false
    add_child(panel)
    var backdrop := PanelContainer.new()
    backdrop.custom_minimum_size = Vector2(390, 340)
    panel.add_child(backdrop)
    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 14)
    backdrop.add_child(layout)
    _label(layout, "MENU_PAUSED")
    _button(layout, "MENU_RESUME", _toggle)
    _label(layout, "MENU_VOLUME")
    var volume := HSlider.new()
    volume.min_value = 0
    volume.max_value = 1
    volume.step = 0.05
    volume.value = Game.master_volume
    volume.value_changed.connect(func(v: float) -> void: Game.set_master_volume(v))
    layout.add_child(volume)
    _label(layout, "MENU_SENSITIVITY")
    var sensitivity := HSlider.new()
    sensitivity.min_value = 0.0005
    sensitivity.max_value = 0.01
    sensitivity.step = 0.0005
    sensitivity.value = Game.mouse_sensitivity
    sensitivity.value_changed.connect(func(v: float) -> void:
        Game.mouse_sensitivity = v
        Game.save_settings()
    )
    layout.add_child(sensitivity)
    _button(layout, "MENU_LANGUAGE", func() -> void:
        var lang := TranslationServer.get_locale()
        TranslationServer.set_locale("en" if lang.begins_with("de") else "de")
        Game.save_settings()
    )
    _button(layout, "MENU_RESTART", func() -> void:
        _close()
        Game.restart_from_checkpoint()
    )

func _label(parent: Node, key: String) -> void:
    var label := Label.new()
    label.text = key
    parent.add_child(label)

func _button(parent: Node, key: String, action: Callable) -> void:
    var button := Button.new()
    button.text = key
    button.pressed.connect(action)
    parent.add_child(button)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        get_viewport().set_input_as_handled()
        _toggle()

func _toggle() -> void:
    pause_open = not pause_open
    panel.visible = pause_open
    get_tree().paused = pause_open
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if pause_open else Input.MOUSE_MODE_CAPTURED

func _close() -> void:
    if pause_open:
        _toggle()
