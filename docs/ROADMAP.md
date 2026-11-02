# Roadmap und Übergabe

Diese Datei hält fest, wo das Projekt steht, was geplant ist und welche Regeln gelten. Sie ist so geschrieben, dass eine andere KI (z. B. ChatGPT) oder ein Mensch die Arbeit ohne Vorwissen fortsetzen kann. Bitte nach jeder Arbeitsetappe aktualisieren.

Stand: 2026-11-02, Branch `grafik/kapitel-1` (Commit b3b80b9).

## Ziel

Ein First-Person-Horrorspiel **1:1 im Stil von Fears to Fathom** (realistische Grafik, düsteres Licht, Filmkorn, ruhige Alltagsszenen, die kippen), aber mit eigener Story. Die Struktur soll später **weitere Geschichten/Kapitel** aufnehmen können.

Episode 1: "The Observer" / "Der Beobachter". Kurzkonzept in [konzept.md](konzept.md): Claire Calloway zieht mit Familie in die Linden Avenue 112, ein Unbekannter schreibt Briefe. 5 Kapitel: Der Schlüssel, Die Polizei, Der Keller, Die Nacht im Haus, Das Ende. Wer der Geschichte folgt, überlebt; Abweichungen führen zu einem Angriff (Game Over, Neustart am Checkpoint).

## Technik und Projektstruktur

- Godot 4.7.2 (Standard, nicht .NET), GDScript, Renderer Forward+. Godot liegt auf Marcelos PC unter `C:\Users\Marcelo\Documents\Godot_v4.7.2-stable_win64.exe\` (Ordner, darin die .exe).
- Die Welt wird komplett **per Code** gebaut (keine handgebauten Szenen): `scenes/chapter1.tscn` enthält nur den Wurzelknoten mit `scripts/chapter1.gd`.
- Vererbungskette der Skripte:
  - `scripts/world_kit.gd`: wiederverwendbare Bausteine für alle Kapitel (Materialien `_mat`, `_pbr`, `_surface`, CSG-Formen `_box`, `_cyl`, `_sub`, Modelle laden `_model`, Kollision `_solid`, Auslöser `_area`, Interaktion `_interactable`, `_fade_far`).
  - `scripts/chapter1_decor.gd`: einige Deko-Helfer (Büsche, Beete, Fahrrad, Laternen, Hausreihen-Listen `near_row`/`far_row`).
  - `scripts/chapter1_world.gd`: Aufbau von Kapitel 1 (Licht, Himmel, Haus, Treppe, Innenräume, Nachbarschaft, lange Straße, Straßenenden, Autos, Figuren, Zäune, Bäume, Gras, unsichtbare Wände).
  - `scripts/chapter1.gd`: nur der Ablauf (Zustandsmaschine, Gedanken, Aufgaben, Checkpoint, Angriff, Kapitelende).
- Weitere Skripte: `player.gd` (First-Person, Ducken, Interaktion per Raycast), `ui.gd` (Aufgabe, Untertitel, Brief, Überblendungen), `game.gd` (Autoload: Tastenbelegung, Sprache, Checkpoint), `interactable.gd`.
- Nachbearbeitung: `assets/shaders/post_process.gdshader` (Filmkorn, Vignette, chromatische Aberration).
- Texte nur als Keys in `localization/strings.csv` (Spalten `keys,en,de`). **Immer beide Sprachen pflegen.**

## Regeln für alle, die weiterarbeiten

1. **Assets nur CC0** (Poly Haven, ambientCG u. Ä.). Jede Datei in `assets/CREDITS.md` eintragen. Einzige erlaubte Ausnahme: Mixamo (Adobe) für Figuren/Animationen, separat als "Mixamo / Adobe, nicht CC0, nicht weitergeben" kennzeichnen. Das Repo muss dann privat bleiben.
2. Binärdateien (png, jpg, glb, gltf, bin, hdr, fbx, Audio, Schriften) laufen über **Git LFS** (`.gitattributes`). Neue Dateitypen dort ergänzen.
3. Git: auf Feature-Branches arbeiten und pushen, **nie direkt auf `main`, nie force-push**. Commit-Nachrichten auf Deutsch. PRs erstellt Marcelo bzw. der Projekt-Assistent.
4. Nach jeder Etappe testen (Befehle unten): 0 Fehler, 0 Warnungen, Selbsttest grün, im Fenster 60+ FPS.
5. Keine Passwörter eingeben oder speichern; nichts kaufen.
6. Code-Stil: deutschsprachige Kommentare nur für das Warum, Dateien unter 800 Zeilen.

## Testen

```
<godot>_console.exe --headless --path . --import            (zweimal)
<godot>_console.exe --headless --path . --quit-after 600    (Skriptfehler)
<godot>_console.exe --path . --quit-after 900               (mit Fenster)
```

Bisher gab es einen Selbsttest und ein Screenshot-Skript außerhalb des Repos (Treppe hochlaufen, kompletter Ablauf bis Kapitelende, FPS-Messung). Empfehlung: beide als `tests/selftest.gd` und `tests/shots.gd` ins Repo holen (siehe offene Punkte).

## Erledigt (Kapitel 1)

- Ablauf: Ankunft am Auto, 3 Kartons ins Haus tragen (Walter Greaves hört auf zu mähen und starrt), Haus erkunden (Obergeschoss über Treppe, Kinderzimmer mit Bleistiftstrichen von 1987, verschlossene Kellertür), Harriet Price winkt, Post holen, Brief lesen (Checkpoint `after_letter`), Gestalt hinter der Hecke, Motor hinter dem Haus gegenüber, zurück zum Auto, derselbe Mann rollt im dunklen Wagen vorbei, Kapitelende. Folgen in den Garten = Angriff.
- Grafik: HDRI-Himmel (bedeckt), SDFGI, SSAO/SSIL, Glow, Nebel, weiche Schatten, Filmkorn/Vignette; PBR-Texturen; 30+ CC0-Modelle (Möbel, Kartons, Mülltonnen, Hydranten, Laternen, Pflanzen, abgedecktes Auto); Gras als MultiMesh; Lattenzäune; Fenster mit Rahmen und Glas; Giebel, Verandadächer.
- Lange Straße (~380 m, 44 Häuser), Enden mit Absperrung "Road Closed" bzw. Sackgasse und Waldrand, Sichtschutzzäune und Bäume hinter den Gärten, Hügel am Horizont; unsichtbare Wände nur hinter sichtbaren Hindernissen.

## Geplant / offen (nach Priorität)

1. **Echte animierte Figuren (Mixamo).** Marcelo ist in Chrome bei Adobe angemeldet. Benötigt: Walter (älterer Mann), Harriet (ältere Frau), der Beobachter (dunkler Mantel, Hut; er fährt auch den dunklen Wagen). Animationen: Idle, Walking (Walter mäht), Waving (Harriet), Driving (Fahrer), Angriff (Beobachter), evtl. Stare/Turn. Download als FBX (Charakter "With Skin", Animationen "Without Skin"), nach `assets/characters/` legen, per AnimationPlayer abspielen (Mixamo-Skelette haben gleiche Knotennamen, Animationen lassen sich daher zwischen den Figuren teilen). Die bisherigen Grundformen-Figuren entstehen in `_person()` und beim Beobachter in `_build_world()` (beide in `chapter1_world.gd`); `walter`, `harriet`, `observer`, `driver_head` werden in `chapter1.gd` bewegt (look_at, Arm-Pivot `meta "arm"`).
2. **Struktur für mehrere Kapitel/Geschichten:** gemeinsame Basisklasse `scripts/chapter_base.gd` (Spieler, UI, Checkpoint, Interaktion, Gedanken), jedes Kapitel als eigene Szene + Skript, Auswahl/Übergang über `game.gd`. `world_kit.gd` bleibt die gemeinsame Bausteinsammlung.
3. **Kapitel 2 bis 5** laut Konzept (Polizei, Keller, Nacht im Haus, Ende).
4. **Ton:** Wind, Schritte (je Untergrund), Rasenmäher, Motor des dunklen Wagens, Türen, Briefkasten, leise Musikflächen. Nur CC0 (z. B. freesound.org mit CC0-Filter).
5. **Hauptmenü, Pause, Einstellungen** (Lautstärke, Mausempfindlichkeit, Grafikqualität, Sprache), Speichern/Laden.
6. Grafik verfeinern Richtung Fears to Fathom: echte Haus- und Baummodelle statt CSG (CC0-Bäume von Poly Haven sind 475 MB+, daher bisher Kugelkronen), echte Autos, Dachrinnen/Dachüberstände, Innentüren, Lichtschalter, mehr Kleinkram (Bücher, Geschirr), Briefkasten-Modell, gebackenes Licht oder Volumennebel.
7. Selbsttest und Screenshot-Skript ins Repo (`tests/`), Spieldauer messen (Ziel Kapitel 1: ca. 10 Minuten).

## Wünsche und Änderungen von Marcelo (Feedback-Log)

- Nach erstem Durchspielen: zu kurz; Auto und Mann hinter der Hecke wirkten wie zwei getrennte Bedrohungen (gelöst: derselbe Mann fährt das Auto); Nachbarschaft zu leer (gelöst, weiter ausbauen).
- Grafik soll "ziemlich genau" auf Fears-to-Fathom-Niveau sein; Nachbarschaft und Haus gründlich ausdekorieren.
- Straße darf nicht sichtbar abschneiden; man soll weit laufen können und erst an natürlichen Hindernissen stoppen (umgesetzt in b3b80b9, weiter verfeinern).
- Arbeit läuft lokal auf seinem PC, nicht in der Cloud.
- Langfristig: Spiel im Stil von Fears to Fathom mit eigener Story und Platz für weitere Geschichten.
