# Vermeer — szkielet gry (Godot 4)

Wszystkie 7 ekranów ma już działającą logikę (nie tylko nawigację) —
plantacje, giełda, dom aukcyjny, szkoła sztuki, wyścigi, galeria, mapa
świata z podróżami. Brakuje tylko grafiki — UI to na razie surowe kontrolki
Godota (przyciski, etykiety, listy). Zapis/odczyt gry i pętla
wygrana/przegrana (kompletna kolekcja / bankructwo / rywal wygrywa
pierwszy) działają.

## Jak otworzyć

1. Zainstaluj Godot 4.3+ (stable, wersja "Standard" wystarczy — projekt jest
   w czystym GDScript, bez C#).
2. Otwórz (Import) folder `game/` w Godot Engine — to tu jest `project.godot`.
3. Naciśnij F5. Scena startowa to `scenes/main_menu/MainMenu.tscn`.

## Uruchomienie na telefonie

- **Szybko, bez Android SDK:** eksport Web (`Project > Export`, preset
  "Web" — już skonfigurowany w `export_presets.cfg`), potem otwórz
  wyeksportowaną stronę w przeglądarce na telefonie (w tej samej sieci
  Wi-Fi, przez prosty serwer HTTP).
- **Prawdziwy APK:** wymaga JDK 17 + Android SDK (najprościej przez Android
  Studio) skonfigurowanych w Godocie, potem `Project > Export` z presetem
  "Android" (już przygotowanym w `export_presets.cfg` — zmień
  `package/unique_name` przed prawdziwą publikacją) albo one-click deploy na
  podłączony telefon z włączonym debugowaniem USB.

## Struktura

```
project.godot
export_presets.cfg — startowa konfiguracja eksportu Web + Android
scenes/            — ekrany gry (Control + skrypt): main_menu, hub,
                     plantation, stock_market, races, auction_house,
                     art_school, gallery, ending
scripts/autoload/  — globalny stan gry: Calendar, Cities, Travel, Crops,
                     Economy, PlayerPlantations, Paintings,
                     ShippingCompanies, ForwardContracts, AIPlayers,
                     GameState, SaveGame, SceneRouter
scripts/ui/        — wspólne budowniczowie prostego UI (ScreenHelpers)
```

## Co dalej

Generowanie grafik (`docs/GRAFIKA_LEONARDO.md`) i podpięcie ich pod
istniejące ekrany — logika biznesowa jest gotowa i nie powinna wymagać
większych zmian przy dodawaniu grafiki, tylko podmianę prostych
kontrolek na `TextureRect`/`AnimatedSprite2D`/stylizowany `Theme`.
