# Vermeer — szkielet gry (Godot 4)

Wszystkie ekrany mają już działającą logikę (nie tylko nawigację) —
plantacje, giełda, dom aukcyjny, szkoła sztuki, wyścigi, galeria. Hub
pokazuje tylko pasek stanu i nawigację w wąskim panelu bocznym (tło
zależne od regionu, gdzie aktualnie jesteś); mapa świata z klikalnymi
pinezkami żyje na osobnym ekranie, otwieranym przyciskiem "Jedź »" — tło
Huba zwęża się (zoom-out) do pinezki na mapie, a po wybraniu celu leci
animacja podróży (pociąg w obrębie tego samego regionu, samolot między
regionami/przez ocean) lecąca dokładnie między pinezką startową a
docelową, po czym tło nowego miasta "wjeżdża" (zoom-in) z tej pinezki z
powrotem na cały ekran. Menu główne i mapa mają już prawdziwe tło
graficzne, reszta ekranów wciąż na surowym UI Godota (przyciski, etykiety,
listy). Zapis/odczyt gry, hot-seat multiplayer (1-4 graczy) i pętla
wygrana/przegrana (kompletna kolekcja / bankructwo / rywal wygrywa
pierwszy) działają.

## 1. Instalacja i otwarcie

1. Zainstaluj Godot 4.3+ (stable, wersja "Standard" wystarczy — projekt jest
   w czystym GDScript, bez C#): https://godotengine.org/download
2. W Godot Engine kliknij **Import** (nie "New Project") i wskaż folder
   `game/` w tym repo — to tu jest `project.godot`.
3. Naciśnij **F5** (albo przycisk Play w prawym górnym rogu). Scena
   startowa to `scenes/main_menu/MainMenu.tscn`.

## 2. Przewodnik testowy — pełne przejście przez grę (10-15 min)

Poniższe kroki sprawdzają, czy wszystkie systemy realnie działają, nie
tylko się uruchamiają. Jeśli coś na którymś kroku wygląda inaczej niż
opisano — to sygnał, że coś jest nie tak (zrzut ekranu + krok, na którym
się wywaliło, bardzo ułatwi mi naprawę).

1. **Start:** po F5 powinno pojawić się menu główne z tłem (kobieta przy
   sztaludze i globusem). Zostaw "Liczba graczy" na 1, tryb łatwy
   odznaczony, kliknij **Nowa gra**.
2. **Hub:** powinieneś trafić na ekran z tłem regionu i wąskim panelem po
   prawej (nie na całą szerokość, tak jak w oryginale) z paskiem stanu
   (gotówka 50000 M, data 01.01.1918, obrazy 0/40) i listą przycisków, w
   tym **Jedź »**.
3. **Podróż:** kliknij **Jedź »** — tło Huba powinno skurczyć się i
   "wjechać" w pinezkę na mapie świata, która pojawia się pod spodem (ok.
   1 sekundy animacji), a dopiero potem powinna otworzyć się mapa z ok. 18
   kolorowymi pinezkami: jedna **biała** dokładnie w miejscu, gdzie
   skurczyło się tło (Twoja aktualna lokalizacja, Londyn), reszta złota
   (miasta plantacyjne) i burgundowa (miasta aukcyjne). Po prawej
   krawędzi ekranu wąski panel z przyciskiem **« Powrót** — reszta mapy
   zostaje odsłonięta. Kliknij dowolną **złotą** pinezkę (np. Richmond
   albo St. Louis — najbliżej) — w panelu powinna pojawić się informacja,
   ile dni potrwa podróż i jakim środkiem transportu, oraz przyciski
   **Jedź »** i **Anuluj**. Kliknij **Jedź »** — powinna polecieć
   animacja pociągu albo samolotu (w zależności od odległości), lecącego
   po mapie DOKŁADNIE między pinezką startową a docelową — mały tuż po
   starcie, rośnie w połowie drogi, znowu mały tuż przy dotarciu. Zaraz
   potem tło miasta docelowego powinno "wyjechać" z tej samej pinezki na
   cały ekran (odwrotność animacji z kroku wcześniej) i dopiero wtedy
   wrócić do Hubu ze statusem "Jesteś w: [nowe miasto]". To duża, nowa
   animacja — jeśli coś tu wygląda źle (skok, migotanie, zły punkt
   startowy/końcowy), koniecznie daj znać dokładnie na którym etapie.
   Kliknij **Koniec tury** kilka razy, aż status zmieni się na "Jesteś w:
   [miasto]" — teraz na liście przycisków powinien pojawić się
   **Plantacje** (widoczny tylko w miastach plantacyjnych, tak jak w
   oryginale — poza nimi w ogóle go nie ma na liście, nie jest tylko
   wyszarzony).
4. **Plantacje:** wejdź, kup kilka pól (klikaj "+" w siatce; pola z "~" to
   rzeka, nie da się ich kupić — pola tuż obok rzeki oznaczone "✓+" po
   zakupie dają podwójny plon), wybierz uprawę (np. Tytoń), ustaw
   robotników suwakiem (np. 500), kliknij **Zbierz plony** — na razie 0,
   bo nie minął żaden czas. Wróć do Hubu, kliknij **Koniec tury** kilka
   razy (np. 5×), wróć do Plantacji i zbierz ponownie — tym razem plon
   powinien być > 0. Kliknij **Wyślij i sprzedaj** — gotówka powinna
   wzrosnąć.
5. **Giełda:** z Hubu wejdź w Giełdę — kup/sprzedaj kilka akcji linii
   żeglugowych, zawrzyj kontrakt terminowy na dowolny towar (sprawdź, czy
   pojawia się na liście aktywnych kontraktów).
6. **Dom aukcyjny:** pojedź pinezką do **burgundowego** miasta (np.
   Londyn, Paryż), wejdź do Domu aukcyjnego. Podbijaj ofertę, klikaj
   "Zakończ rundę" aż licytacja się rozstrzygnie — sprawdź komunikat
   (wygrana/fałszywka/przegrana z rywalem).
7. **Szkoła sztuki i wyścigi:** kup kurs w Szkole Sztuki (eksperckość
   powinna wzrosnąć), postaw zakład w Wyścigach (gotówka się zmienia po
   rozstrzygnięciu).
8. **Galeria:** dostępna tylko w miastach aukcyjnych (tak jak Dom
   aukcyjny — w oryginale to jedna grupa opcji menu), więc rób ten krok
   od razu po poprzednim, bez podróży. Sprawdź podział kolekcji na 8
   kategorii, sekcję "Ochrona" (zatrudnienie ochroniarza) i "Rywale" (ich
   postęp w zbieraniu obrazów).
9. **Zapis/odczyt:** z Hubu kliknij **Zapisz i wyjdź do menu**, potem w
   menu głównym **Wczytaj grę** — stan powinien się zgadzać z tym, co
   zostawiłeś.
10. **Multiplayer (opcjonalnie):** zacznij nową grę z "Liczba graczy" = 2.
    Na każdym ekranie powinien pojawić się napis "Tura: Gracz N". Po
    "Koniec tury" na Hubie gra powinna przełączyć się na Gracza 2 z jego
    własnym (świeżym) stanem — gotówka/kolekcja Gracza 1 nie powinny być
    widoczne.

## 3. Czego szukać, jeśli coś nie działa

- **Czerwony tekst w panelu "Debugger" / "Output"** na dole edytora =
  błąd skryptu. Skopiuj cały komunikat (nazwa pliku + numer linii) — to
  wystarczy, żebym to naprawił bez zgadywania.
- **Czarny/pusty ekran** = prawdopodobnie błąd w `_ready()` sceny, sprawdź
  panel Output.
- **Pinezka w złym miejscu na mapie** = znany, spodziewany problem —
  współrzędne w `scripts/autoload/Cities.gd` (`MAP_POSITION`) są
  policzone matematycznie, nie sprawdzone wizualnie. Podaj, o ile trzeba
  przesunąć (np. "Ankara wypada za wysoko, o jakieś 5%"), poprawię.
- **Brak przycisku "Plantacje" albo "Dom aukcyjny" na liście** = to
  zamierzone, nie błąd — tak jak w oryginale, te przyciski są widoczne
  tylko w mieście właściwego typu (plantacyjnym/aukcyjnym), w innych
  miastach w ogóle się nie pokazują (patrz krok 3 wyżej).

## 4. Testy automatyczne (bez klikania)

W terminalu, z poziomu folderu `game/`:
```
godot --headless --path . res://tests/run_tests.tscn
```
Powinno wypisać listę `OK`/`FAIL` dla ok. 30 asercji i zakończyć się kodem
wyjścia 0. To samo odpala się automatycznie w GitHub Actions przy każdym
pushu (`.github/workflows/godot-check.yml`).

## 5. Uruchomienie na telefonie

- **Szybko, bez Android SDK:** eksport Web (`Project > Export`, preset
  "Web" — już skonfigurowany w `export_presets.cfg`), potem otwórz
  wyeksportowaną stronę w przeglądarce na telefonie (w tej samej sieci
  Wi-Fi, przez prosty serwer HTTP, np. `python3 -m http.server`).
- **Prawdziwy APK:** wymaga JDK 17 + Android SDK (najprościej przez Android
  Studio) skonfigurowanych w Godocie, potem `Project > Export` z presetem
  "Android" (już przygotowanym w `export_presets.cfg` — zmień
  `package/unique_name` przed prawdziwą publikacją) albo one-click deploy na
  podłączony telefon z włączonym debugowaniem USB.

## Struktura

```
project.godot
export_presets.cfg — startowa konfiguracja eksportu Web + Android
art/backgrounds/   — grafiki teł (main_menu_title.jpg, hub_map.jpg, ...)
scenes/            — ekrany gry (Control + skrypt): main_menu, hub,
                     plantation, stock_market, races, auction_house,
                     art_school, gallery, ending
scripts/autoload/  — globalny stan gry: Calendar, Cities, Travel, Crops,
                     Economy, PlayerPlantations, Paintings,
                     ShippingCompanies, ForwardContracts, AIPlayers,
                     Security, Players, GameState, SaveGame, SceneRouter
scripts/ui/        — wspólne budowniczowie prostego UI (ScreenHelpers,
                     MapPin — pinezki rysowane natywnie, bez grafiki)
tests/             — run_tests.tscn/.gd, testy autoloadów uruchamiane w CI
```

## Co dalej

Generowanie pozostałych teł ekranów (`docs/GRAFIKA_LEONARDO.md`, priorytet
2: Plantacje, Dom aukcyjny, Giełda, Wyścigi, Szkoła sztuki, Galeria) i
podpięcie ich tak samo jak menu główne/Hub — logika biznesowa jest gotowa
i nie powinna wymagać większych zmian przy dodawaniu grafiki.
