# Regeln für KI-Assistenten (Claude, Codex, ChatGPT)

Diese Datei gilt für jede KI, die in diesem Repo arbeitet. Codex liest sie automatisch, Claude Code über `CLAUDE.md`. Projektstand, Technik und Spielregeln stehen in `docs/ROADMAP.md` (auf `grafik/kapitel-1`, nach dem Merge auf `main`). Lies beide, bevor du etwas änderst.

## Rollen

| Wer | Aufgabe | Branches |
| --- | --- | --- |
| Claude (Claude Code) | Hauptentwickler: Features, Kapitel, Welt, Refactorings, PRs | `claude/<thema>` |
| Codex (Plugin oder CLI) | Review jedes Claude-PRs; kleine, klar abgegrenzte Aufgaben (Bugfix, Test); eigene 3D-Modelle per Blender-Skript (siehe unten); Vertretung, wenn Claude nicht verfügbar ist | `codex/<thema>`, Modelle auf `codex/assets-<thema>` |
| ChatGPT (Chat) | Story, Briefe, Dialoge, Recherche; Bilder für Texturen, Poster, Briefe, Schilder. Ändert keinen Code direkt, Ergebnisse gehen an Claude oder Codex | keine |
| Marcelo | Entscheidet, testet, merged | – |

## Branches und Pull Requests

1. Ein Branch gehört genau einer KI. Die andere pusht dort nie, sondern schreibt Review-Kommentare oder macht einen eigenen Branch.
2. Neue Arbeit startet von `main`. Höchstens zwei PRs übereinander stapeln.
3. Ein Thema pro PR, grob unter 400 Zeilen Code (Assets zählen nicht).
4. Draft-PR = in Arbeit, Ready for review = fertig für das Review.
5. Jeder PR-Text füllt die Vorlage aus, vor allem den Abschnitt "Übergabe".
6. Nie direkt auf `main` pushen, nie force-pushen. Nur Marcelo merged.
7. Keine Passwörter, Tokens, API-Keys oder `export_credentials.cfg` committen.

## Reviews

- Claude-PR: Codex prüft, z. B. mit `/codex:adversarial-review --base <basis-branch>`.
- Codex-PR: Claude prüft.
- Der Reviewer ändert nichts selbst, sondern listet Funde mit Datei und Zeile als PR-Kommentar. Der Autor behebt sie auf seinem Branch.
- Danach testet Marcelo im Spiel und merged.

## Eigene Modelle und Texturen

Ziel: Modelle selbst erzeugen, statt Packs zu kaufen. Codex baut sie, Claude prüft sie.

- Codex erzeugt Modelle als **Blender-Python-Skript** (`tools/blender/<name>.py`), das eine `.glb` exportiert. Skript und `.glb` kommen beide ins Repo, damit das Modell reproduzierbar und änderbar bleibt.
- Ablage: `assets/models/generated/<name>.glb`, Eintrag in `assets/CREDITS.md` als "selbst erzeugt (Codex/ChatGPT)".
- Texturen und Bilder aus ChatGPT: `assets/textures/generated/`, ebenfalls in `assets/CREDITS.md`.
- Menschen mit Skelett und Animation bleiben bei Mixamo.
- Vorgaben pro Modell: Maßstab in Metern, Y nach oben, Ursprung am Boden, sinnvolle Namen, PBR-Material, Poly-Budget (Kleinteile unter 5 000, Möbel unter 20 000, Häuser und Autos unter 60 000 Dreiecke), Dateigröße unter 20 MB.
- Claude prüft jedes Modell vor dem Einbau: Import in Godot ohne Fehler, Maße und Ausrichtung, Dreiecke und Dateigröße, Kollision, Screenshot im Spiel neben bestehenden Assets. Ergebnis als Review-Kommentar mit Screenshot.

## Konflikte vermeiden

- Pro Aufgabe ein GitHub-Issue mit Label `claude` oder `codex`. Arbeite nur an Issues mit deinem Label.
- Nicht gleichzeitig dieselben Dateien wie ein offener PR der anderen KI ändern. Falls nötig, im PR oder Issue absprechen (über Marcelo).
- `docs/ROADMAP.md` nur in dem PR aktualisieren, der eine Etappe abschließt. Laufende Übergaben stehen im PR-Text.
- Formatierung laut `.editorconfig`: GDScript mit Tabs (Godot-Standard), LF-Zeilenenden. Nie Tabs und Leerzeichen in einer Datei mischen.

## Vor jedem Push

- Godot headless importieren und starten (Befehle in `docs/ROADMAP.md`, Abschnitt "Testen"): 0 Fehler, 0 Warnungen.
- Vorhandene Tests unter `tests/` laufen lassen.
- Sichtbare Texte nur als Keys in `localization/strings.csv`, immer Deutsch und Englisch.
- Neue Assets nur CC0 (Ausnahme Mixamo, siehe ROADMAP) und in `assets/CREDITS.md` eintragen.
