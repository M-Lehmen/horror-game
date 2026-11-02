# Figuren- und Grafik-Übergabe an Claude

Stand: 02.11.2026. Kein direkter Eingriff in Claudes `scripts/chapter1_world.gd` oder `scripts/chapter1_decor.gd`.

## Figuren
- Ein allgemeiner AnimationPlayer-Adapter liegt unter `scripts/character_animation_adapter.gd`. Er spielt nur Clips, die im importierten Modell existieren. Noch nicht an Walter/Harriet/Observer angeschlossen.
- Benötigt: Walter (Idle, Walk/Mowing/Stare), Harriet (Idle/Wave), Beobachter (Idle/Walk/Attack), Fahrer (Idle/Drive).
- Import-Verzeichnis: `assets/characters/`. **Nicht** ungeprüfte FBX-Dateien von Mixamo ins öffentliche Repository hochladen: laut Projektregel nicht CC0, privat halten bzw. rechtliche Prüfung.
- Nach Import NodePaths und Animation-Namen zuordnen. Übergänge, Root Motion und Kollision beim Angriff im Spiel überprüfen.
- Figuren zu testbarem Maßstab (~1,6–1,9 m), Schatten, Augenhöhe und Blickrichtung ausrichten.

## Grafik und Umgebung
- Claudes bestehende Weltbau-Dateien nicht überschreiben. Freie Jobs: glaubwürdige Haus-Silhouetten und Dächer, echte Automobile, Innentüren, Briefkasten, Zaun-Lücken korrigieren; sichtbare Probleme erst mit Screenshots belegen.
- Präferenz: bestehende CC0-Assets wiederverwenden, keine neuen 100-MB-Bäume ohne Performance-/Größenprüfung.
- Priorität: Sichtlinien zur Gestalt (Raycast), lokale Klangquellen, glaubwürdige Vegetation und stabile 60+ FPS.
- Der aktuelle ChatGPT-Branch enthält **keine** neuen externen 3D-Modelle oder Figur-Assets und behauptet keine gerenderten Grafikverbesserungen.

## Aufgabenfolge nach diesem PR
1. Godot-Syntaxcheck, Szene durchspielen (einschließlich Gestalt übersehen), Fehlwarnungen im Garten.
2. Audiofiles final mischen und räumliche Wiedergabe anpassen, Schritte/Türen/Briefkasten ergänzen.
3. Animations-Adapter erst nach Modellimport verbinden; Animationen separat prüfen.
4. Visuelle Nacharbeit per Screenshots und gemessener Framerate iterieren.

Verantwortung für Mixamo-Zugang, Einkäufe und Lizenzen bleibt beim Repository-Eigentümer.
