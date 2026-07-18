# Vermeer — szkielet gry (Godot 4)

Szkielet projektu do dalszej rozbudowy — puste (placeholder) ekrany
połączone nawigacją, ale z realnymi danymi ekonomicznymi z `docs/`
(miasta, czasy podróży, plony, obrazy) wpiętymi w autoloady.

## Jak otworzyć

1. Zainstaluj Godot 4.3+ (stable, wersja "Standard" wystarczy na start —
   eksport na Android wymaga doinstalowania szablonów eksportu w Godocie
   oraz Android SDK/JDK, ale to dopiero na etapie budowania APK).
2. Otwórz `game/project.godot` w Godot Engine.
3. Scena startowa to `scenes/main_menu/MainMenu.tscn`.

## Struktura

```
scenes/        — ekrany gry (Control + skrypt), na razie placeholdery UI
scripts/autoload/ — globalny stan gry (ekonomia, kalendarz, miasta, obrazy...)
scripts/ui/    — wspólne budowniczowie prostego UI (ScreenHelpers)
```

## Co dalej

Kolejność wg `docs/GDD.md` pkt. 10: zastąpić placeholdery właściwą grafiką
(`docs/GRAFIKA_LEONARDO.md`), zacząć od ekranu Hub/Mapa świata, potem
kolejno pozostałe ekrany. Logika biznesowa (autoloady) już zawiera realne
dane źródłowe — do rozbudowy o pełne UI i interakcje.
