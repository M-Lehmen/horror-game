# Übergabe: ChatGPT-Arbeitsbranch (02.11.2026)

## Branch / Stand
- Branch: `feature/audio-gameplay-systeme-20261102` auf Basis `recherche/spannungsdramaturgie` (PR #4); dadurch enthält er Vorarbeiten aus PR #2/#3/#4. **Nicht** nach main mergen, solange die PR-Kette nicht sauber abgeglichen ist.
- Keine Änderungen an Claudes eigenen Branches. Niemals force-push.
- Arbeitsweise: Aufgaben einzeln erledigen und nach jedem Abschnitt hier dokumentieren.

## Bisher umgesetzt
1. Gameplay in `scripts/chapter1.gd`:
   - nach dem Brief verschwindet die unbemerkte Gestalt nach 32 Sekunden, beziehungsweise nach 40 Sekunden bei erkannter Gestalt. Danach startet der Motor wie gewohnt; Blicken ist keine Fortschrittsbedingung mehr.
   - Garten: erster Eintritt warnt; erst erneuter Eintritt nach mindestens drei Sekunden löst Angriff aus. Kein zusätzlicher äußerer Warnungsbereich vorhanden; unbedingt im Gameplay prüfen.
   - `_is_looking_at` prüft zusätzlich Physik-Raycast gegen Hindernisse. Noch auf Godot/Collision-Masken testen.
   - `THOUGHT_GARDEN_WARNING` in DE/EN hinzugefügt.
2. Prozedurales Audio in `scripts/ambient_audio.gd`: leiser Wind und Rasenmäher, Motor-Cue. Keine fremden Samples. Mäher stoppt beim Beobachten und setzt nach Kartons wieder ein. **Noch kein vollständiges Audio-Paket / keine fertigen WAVs**.
3. `tests/smoke.gd`: assetfreier Headless-Strukturtest, **noch nicht in Godot ausgeführt**.

## Noch offen
- Audio: echte räumliche Quellen, Schritte je Untergrund, Türen, Post, Kartons; hochwertigere SFX-Dateien, Mix und dynamische Dämpfung.
- Gameplay: Garden-Trigger-Geometrie und tatsächliche Warnung/Umkehr vor Ort prüfen, Sichtlinien; Checkpoint/Ende durchspielen.
- Tests: vollständigen Gameplay-Selbsttest, Import und Godot-Headless-Lauf sowie FPS auf Zielhardware.
- Menü, Optionen, Persistenz, Kapitel-Basisklasse, animierte Figuren, Haus-/Fahrzeug-Modelle, weitere Deko.
- Assets strikt nach Projekt-Lizenzregeln; Mixamo nicht ins öffentliche Repo hochladen. Keine Kosten auslösen.

## Testanleitung
```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/smoke.gd
godot --headless --path . --quit-after 600
```
Zusätzlich Kapitel 1 im Fenster vollständig durchspielen, bewusst die Gestalt ignorieren, den Garten betreten/umkehren/erneut betreten und auf Fehlwarnungen prüfen. Diese Tests wurden in dieser Cloud-Umgebung mangels Godot nicht ausgeführt.

## Kollaboration
Vor jeder weiteren Änderung aktuelle Branches/PRs und diese Datei lesen. Claude arbeitet weiter an Figuren/Grafik; parallele Änderungen derselben Dateien vermeiden. PR auf `recherche/spannungsdramaturgie` richten. Nach PR-Merges die Basis per Git anpassen.
