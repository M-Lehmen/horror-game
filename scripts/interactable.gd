extends StaticBody3D
## Etwas, das der Spieler mit E benutzen kann.

signal used

## Übersetzungs-Key für den Hinweis, z. B. "[E] Ansehen".
@export var prompt: String = "PROMPT_LOOK"
@export var enabled: bool = true


func interact() -> void:
	if enabled:
		used.emit()
