extends SceneTree
## Schneller, assetfreier Smoke-Test: godot --headless --path . --script res://tests/smoke.gd

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var required := [
        "res://scripts/chapter1.gd",
        "res://scripts/ambient_audio.gd",
        "res://scripts/game.gd",
        "res://localization/strings.csv"
    ]
    for path in required:
        if not FileAccess.file_exists(path):
            push_error("Datei fehlt: " + path)
            quit(1)
            return
    var gameplay := FileAccess.get_file_as_string(required[0])
    var localization := FileAccess.get_file_as_string(required[3])
    var checks := [
        ["observer-fallback", "letter_time >= 32.0" in gameplay],
        ["garten-warnung", "garden_warning_armed" in gameplay],
        ["raycast-sichtlinie", "intersect_ray(query)" in gameplay],
        ["uebersetzung", "THOUGHT_GARDEN_WARNING" in localization],
        ["motor-audio", "ambient_audio.engine_cue()" in gameplay]
    ]
    var failed := false
    for check in checks:
        if not check[1]:
            push_error("FEHLER: " + check[0])
            failed = true
        else:
            print("OK: " + check[0])
    quit(1 if failed else 0)
