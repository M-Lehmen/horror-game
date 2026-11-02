extends RefCounted
## Reine Regeln ohne Welt- und UI-Abhaengigkeiten; separat testbar.

static func should_hide_observer(phase: int, elapsed: float) -> bool:
    return (phase == 1 and elapsed >= 32.0) or (phase == 2 and elapsed >= 40.0)

static func should_warn_garden(armed: bool) -> bool:
    return not armed

static func should_attack_garden(armed: bool, warning_timer: float) -> bool:
    return armed and warning_timer <= 0.0
