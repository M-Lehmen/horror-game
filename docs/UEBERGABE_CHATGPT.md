# Übergabe ChatGPT → Claude / nächste Sitzung

Stand: 02.11.2026, Draft-PR #5: https://github.com/M-Lehmen/horror-game/pull/5. Branch `feature/audio-gameplay-systeme-20261102` (Basis `recherche/spannungsdramaturgie`, PR #4).
Auf Basis von Claudes PR-Kette #2 → #3 und Recherche #4. Keine Änderungen an fremden Branches, kein Merge nach main, kein force-push.

## Fertig im Arbeitsbranch (noch nicht Godot-laufzeitgetestet)
1. **Gameplay:** `scripts/chapter1.gd` hat eine 32-/40-Sekunden-Ausweichlogik für eine übersehene Gestalt, physikalischen Raycast für Sichtprüfung, Gartenwarnung beim ersten Eintritt und Angriff erst beim erneuten Eintritt nach mindestens 3 Sekunden. `scripts/horror_rules.gd` kapselt diese Regeln. Neue Gartenwarnung in DE/EN.
2. **Audio:** `scripts/ambient_audio.gd` erzeugt und spielt leise Wind-/Mäher- und Motor-Platzhalter ohne Fremd-Samples; Mäher stoppt/wird wieder hörbar bei Walters Reaktion. `tools/generate_audio.py` erzeugt sieben WAV-Soundeffekte nach `assets/audio/generated/` (Python 3 + numpy): Wind, Mäher, Motorstart, Holzschritt, Kieseltritt, Türknarren, Briefkastenklick. WAV-Dateien **nicht** in GitHub-Branch committed: als lokales ZIP erstellt, jederzeit per Generator reproduzierbar. Für Godot sind noch räumliche Quellen und Integration aller WAVs nötig.
3. **Tests:** `tests/smoke.gd` führt Godot-Headless-Prüfungen von Dateien, Sicht-Raycasts und der reinen Spielregeln durch; kein vollautomatisierter Leveldurchlauf.
4. **Menü / Einstellungen:** `scripts/pause_menu.gd` wird in Kapitel 1 eingebunden: Pause über Esc, Lautstärke, Mausempfindlichkeit, Sprachwechsel und Neustart vom Checkpoint. `scripts/game.gd` speichert Optionen in `user://settings.cfg`; `scripts/player.gd` verwendet die eingestellte Sensitivität. Menü-Keys in DE/EN.
5. **Mehrere Kapitel:** `Game.CHAPTER_PATHS` und `open_chapter(index)` prüfen den Szenenpfad und wechseln sicher zu vorhandenen Szenen. Noch keine echte Kapitel-Basisklasse, keine weiteren Kapitel.
6. **Charaktere:** `scripts/character_animation_adapter.gd` kann optionale vorhandene AnimationPlayer-Clips ansprechen; **nicht** an Figuren gebunden, keine externen Charaktermodelle hinzugefügt.
7. **Grafik/Umgebung:** `docs/FIGUREN_GRAFIK_HANDOFF.md` enthält Integrations- und Modellprioritäten. Noch **keine** neuen Modelle/Grafikänderungen; Claudes Weltbau-Dateien unangetastet.

## Noch zu erledigen, in dieser Reihenfolge
1. Godot-Import, statischer Syntax-/Headless-Test, vollständiger Durchlauf: Gestalt ignorieren, Garten betreten/umkehren/erneut betreten, Text/Checkpoint/Ende prüfen. Dabei Fehler beheben, bevor neue Features kommen.
2. Audio in 3D an Gebäude, Gehweg, Briefkasten und Auto binden; Schritte getrennt nach Boden, Innenraumdämpfung, dynamische Mischung. Anschließend echte WAVs über Git LFS importieren und Credits für selbst generierte Dateien ergänzen.
3. Menü auf kleinen Displays und bei Brief-UI/Pause testen; optional Grafikqualität und Hauptmenü ergänzen.
4. Wiederverwendbare Basisklasse für Kapitel / echte Kapitelwechsel und Save/Load nach Tests.
5. Nach Absprache mit Claude Modelle/Animationen einbauen; Mixamo-Dateien nicht unbesehen ins öffentliche Repo laden.
6. Umgebung weiter ausbauen, ohne `scripts/chapter1_world.gd` auf parallelen Branches zu überschreiben; FPS messen.

## Tests / Validierungsstatus
Godot ist in der ChatGPT-Umgebung **nicht installiert**; auch externer Git-Clone über die Containerverbindung war nicht erreichbar. Darum wurden die Godot-Tests **nicht ausgeführt**. GitHub konnte den Branch, Dateiinhalte und Commits erfolgreich zurückgeben. Damit ist weder 0 Warnungen noch 60 FPS belegt.

Lokal:
```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . -s res://tests/selftest.gd
godot --headless --path . --quit-after 600
```

Nachtrag (Claude, Reparaturetappe): `tools/generate_audio.py` wurde entfernt, weil das Spiel die WAVs nicht nutzte. Der ursprüngliche Stand dieses Branches startete wegen gemischter Einrückung in `scripts/game.gd` nicht. Details und Ergebnisse in [ROADMAP.md](ROADMAP.md), Abschnitt "Claude-Prüf- und Reparaturetappe".
Danach 1920×1080 mit Fenster spielen, Pausenmenü und Checkpoint ausprobieren und Leistung protokollieren. Falls Parser-Fehler auftreten, zuerst `scripts/ambient_audio.gd`, `scripts/pause_menu.gd` und `scripts/chapter1.gd` kontrollieren.

## Zusammenarbeit / Merge
PR dieses Branches gegen `recherche/spannungsdramaturgie`, damit keine Arbeiten aus #2/#3/#4 dupliziert im Diff erscheinen. Nach Merge der PR-Kette PR-Basis ggf. anpassen. Claude soll vor Fortsetzung diese Datei, offene PRs und Commits erneut einsehen. Keine automatische Wiederaufnahme nach Chat-Ende; nächste ChatGPT-Sitzung muss neu gestartet werden.

## Hinweis zum PR
Draft-PR #5 angelegt. GitHub meldete beim Erstellen `mergeable=false`; Ursache ist noch nicht geklärt. Vor Merge Konflikte / Status und Godot-Abnahme prüfen. Nach Erstellen des PR wurde `tests/smoke.gd` noch auf eine konstante Preload-Referenz umgestellt; Änderung liegt auf demselben PR-Branch.
