# Regeln für KI-Assistenten (Claude, Codex, ChatGPT)

Diese Datei gilt für jede KI, die in diesem Repo arbeitet. Codex liest sie automatisch, Claude Code über `CLAUDE.md`. Projektstand, Technik und Spielregeln stehen in `docs/ROADMAP.md` (auf `grafik/kapitel-1`, nach dem Merge auf `main`). Lies beide, bevor du etwas änderst.

## Rollen

| Wer | Aufgabe | Branches |
| --- | --- | --- |
| Claude (Claude Code) | Hauptentwickler: Features, Kapitel, Welt, Refactorings, PRs | `claude/<thema>` |
| Codex (Plugin oder CLI) | Review jedes Claude-PRs; kleine, klar abgegrenzte Aufgaben (Bugfix, Test); Vertretung, wenn Claude nicht verfügbar ist | `codex/<thema>` |
| ChatGPT (Chat) | Story, Briefe, Dialoge, Recherche. Ändert keinen Code direkt, Ergebnisse gehen als Text an Claude oder Codex | keine |
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
