# horror-game

First-Person-Horrorspiel in Godot 4 im Stil von Fears to Fathom.
Episode 1: **"The Observer" / "Der Beobachter"**, frei nach einem realen Fall, komplett fiktionalisiert.

Konzept: siehe [docs/konzept.md](docs/konzept.md). Stand, Regeln und geplante Features (Übergabe-Datei): [docs/ROADMAP.md](docs/ROADMAP.md).

## Projekt öffnen

1. Godot 4 (Standard-Version, nicht .NET) von https://godotengine.org/download installieren.
2. Git LFS einmalig einrichten: `git lfs install`
3. Repo klonen: `git clone https://github.com/M-Lehmen/horror-game.git`
4. In Godot auf **Importieren** klicken und `project.godot` auswählen.

Beim ersten Öffnen erzeugt Godot den Ordner `.godot/` und die Übersetzungsdateien. Beides wird nicht committet bzw. automatisch neu gebaut.

## Steuerung

| Taste | Aktion |
| --- | --- |
| WASD | laufen |
| Maus | umsehen |
| E | interagieren |
| Strg | ducken |
| F2 | Sprache wechseln (DE/EN) |
| Esc | Maus freigeben (Klick fängt sie wieder) |

Die Tastenbelegung steht in `scripts/game.gd` und wird beim Start per Code registriert.

## Ordnerstruktur

| Ordner | Inhalt |
| --- | --- |
| `scenes/` | Godot-Szenen (`.tscn`): Level, Spieler, UI |
| `scripts/` | GDScript-Dateien (`.gd`) |
| `assets/` | Modelle, Texturen, Audio, Schriften (über Git LFS) |
| `localization/` | Texte auf Deutsch und Englisch |
| `docs/` | Konzept und Notizen |

## Texte und Übersetzung (DE/EN)

Alle sichtbaren Texte stehen in `localization/strings.csv`: eine Zeile pro Text, eine Spalte pro Sprache.
Im Code oder in einem Label nutzt du nur den Key, zum Beispiel `tr("TASK_GET_MAIL")`. Godot zeigt dann automatisch die passende Sprache an.

Neue Sprache umschalten (z. B. für einen Test):

```gdscript
TranslationServer.set_locale("de")
```

## Assets und Lizenzen

Nur Assets mit passender Lizenz verwenden (z. B. CC0) und jede Quelle in `assets/CREDITS.md` eintragen.

## Spannungsdramaturgie

Recherche, Quellen und konkrete Verbesserungen für Kapitel 1: [docs/SPANNUNGSANALYSE.md](docs/SPANNUNGSANALYSE.md). Umsetzung und Video-Vollsichtung sind dort getrennt vom geprüften Stand markiert.
