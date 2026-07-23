# The Forger: Retro Tycoon — szkielet gry (Godot 4)

Wszystkie ekrany mają już działającą logikę (nie tylko nawigację) —
plantacje + spichlerz, giełda, rynek, dom aukcyjny, szkoła sztuki, wyścigi,
galeria (+ ochrona), ustawienia (język). Hub pokazuje pasek stanu (dwie
skrzynki w przeciwległych górnych rogach) i dwupoziomowe menu w wąskim
panelu bocznym: górny poziom to "Jedź »", "Miejsca »", "Koniec tury »" i
"Zapisz i wyjdź do menu"; "Miejsca »" otwiera podmenu z ekranami
zależnymi od typu miasta (Plantacje, Spichlerz — tylko miasta plantacyjne;
Dom aukcyjny, Galeria, Szkoła sztuki — tylko miasta aukcyjne; Giełda, Rynek —
Nowy Jork i miasta aukcyjne) i zawsze dostępnym (Wyścigi), z przyciskiem
"« Powrót" — zastąpiło to jedną, długą, przewijaną listę, bo przewijanie
dotykiem na telefonie okazało się niewiarygodne. Tło Huba unikalne dla
każdego z 18 miast (rozpoznawalny zabytek/motyw, np. Big Ben w Londynie
czy wieża Eiffla w Paryżu); mapa świata z klikalnymi pinezkami żyje na
osobnym ekranie, otwieranym przyciskiem "Jedź »" — tło Huba zwęża się
(zoom-out) do pinezki na mapie, a po wybraniu celu leci animacja podróży
(pociąg w obrębie tego samego regionu, samolot między regionami/przez
ocean) lecąca dokładnie między pinezką startową a docelową, po czym tło
nowego miasta "wjeżdża" (zoom-in) z tej pinezki z powrotem na cały ekran
— cała podróż kończy się w trakcie animacji (dni naliczają się od razu w
całości), nie trzeba klikać "Koniec tury", żeby dotrzeć na miejsce.
Większość ekranów ma już podpięte docelowe tło graficzne (patrz
`docs/GRAFIKA_LEONARDO.md` — status w tabeli "Plan produkcji"), nie tylko
Hub i menu główne. Zapis/odczyt gry, hot-seat multiplayer (1-4 graczy),
pełny interfejs w 3 językach (polski/angielski/niemiecki, ekran
Ustawień) i pętla wygrana/przegrana (kompletna kolekcja / bankructwo /
rywal wygrywa pierwszy) działają.

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
2. **Hub:** powinieneś trafić na ekran z tłem Londynu (Big Ben) i
   oprawionymi w złotą ramkę skrzynkami rozrzuconymi po rogach, tak jak w
   oryginale: **lewy górny róg** — "Gracz 1 / w: Londyn", pod tym data
   "01.01.1918" i "Obrazy: 0/40"; **prawy górny róg** — gotówka "50000 M".
   Menu (lista przycisków, w tym **Jedź »**) zostaje w wąskim panelu w
   **prawym dolnym rogu** (nie na całą szerokość).
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
   wrócić do Hubu — **od razu** ze statusem "Jesteś w: [nowe miasto]" (cała
   podróż liczy się w trakcie animacji, nie trzeba klikać "Koniec tury",
   żeby dotrzeć na miejsce — dni podróży i tak w pełni naliczają płace/
   wzrost upraw/kursy akcji, tylko naliczone w jednym momencie zamiast
   rozbite na kilka kliknięć) — i po kliknięciu **Miejsca »** przyciski
   **Plantacje**/**Spichlerz** widoczne w podmenu (tylko w miastach
   plantacyjnych, tak jak w oryginale — poza nimi w ogóle ich tam nie ma,
   nie są tylko wyszarzone). To duża, nowa animacja — jeśli coś tu wygląda
   źle (skok, migotanie, zły punkt startowy/końcowy, złe tło po
   przełączeniu), koniecznie daj znać dokładnie na którym etapie.
4. **Plantacje:** wejdź, kup kilka pól w siatce 16×16 (kafelki to ikonki,
   nie tekst — jasna "dzika" ziemia = wolne pole do kupienia, niebieska
   "fala" to rzeka wijąca się losowo, nie da się jej kupić; pole tuż obok
   rzeki dostaje cienką niebieską obwódkę i po zakupie daje podwójny
   plon), wybierz uprawę (np. Tytoń) — powinna pojawić się na polu jako
   kolorowa roślinka, ustaw robotników suwakiem (np. 500), kliknij
   **Zbierz plony** — na razie 0, bo nie minął
   żaden czas. Wróć do Hubu, kliknij **Koniec tury** kilka razy (np. 5×),
   wróć do Plantacji i zbierz ponownie — tym razem plon powinien być > 0.
   Wejdź w **Spichlerz** (z Hubu: Miejsca » Spichlerz, albo bezpośrednio
   przyciskiem z ekranu Plantacji) — powinieneś zobaczyć zebrany zapas w
   odpowiednim "silosie", kliknij **Wyślij i sprzedaj** przy tej uprawie —
   gotówka powinna wzrosnąć.
5. **Giełda:** z Hubu wejdź w Giełdę — kup/sprzedaj kilka akcji linii
   żeglugowych, sprawdź wykres kursu poniżej. **Rynek:** osobna pozycja w
   Hubie — sprawdź ceny towarów i wykres, zawrzyj kontrakt terminowy na
   dowolny towar (sprawdź, czy pojawia się na liście aktywnych kontraktów).
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
10. **Multiplayer (opcjonalnie):** zacznij nową grę z "Liczba graczy" = 2 —
    powinien pojawić się krok z polami na imiona graczy przed startem. Na
    każdym ekranie powinien pojawić się napis "Tura: Gracz N". Po "Koniec
    tury" na Hubie gra powinna przełączyć się na Gracza 2 z jego własnym
    (świeżym) stanem — gotówka/kolekcja Gracza 1 nie powinny być widoczne.
11. **Ustawienia/język:** w menu głównym kliknij **Ustawienia** (obok "Nowa
    gra"/"Wczytaj grę"), zmień język na English albo Deutsch — cały
    interfejs powinien się natychmiast przetłumaczyć, wybór powinien
    przetrwać restart gry. **Wyjdź z gry** powinno całkiem zakończyć
    proces aplikacji (zwolnić pamięć), nie tylko wrócić do menu.

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
Powinno wypisać listę `OK`/`FAIL` dla ok. 60 asercji i zakończyć się kodem
wyjścia 0. To samo odpala się automatycznie w GitHub Actions przy każdym
pushu (`.github/workflows/godot-check.yml`).

## 5. Uruchomienie na telefonie

- **Szybko, bez Android SDK:** eksport Web (`Project > Export`, preset
  "Web" — już skonfigurowany w `export_presets.cfg`), potem otwórz
  wyeksportowaną stronę w przeglądarce na telefonie (w tej samej sieci
  Wi-Fi, przez prosty serwer HTTP, np. `python3 -m http.server`).
- **Prawdziwy APK, lokalnie:** wymaga JDK 17 + Android SDK (najprościej przez
  Android Studio) skonfigurowanych w Godocie, potem `Project > Export` z
  presetem "Android" (już przygotowanym w `export_presets.cfg` — zmień
  `package/unique_name` przed prawdziwą publikacją) albo one-click deploy na
  podłączony telefon z włączonym debugowaniem USB.
- **Prawdziwy APK, bez lokalnego SDK:** workflow `.github/workflows/
  android-build.yml` (uruchamiany ręcznie, `workflow_dispatch`, w GitHub
  Actions) buduje debug APK od zera (Godot headless + export templates +
  Android SDK, wszystko cachowane) i wystawia go jako artefakt do pobrania —
  wygodne, gdy nie chcesz stawiać całego środowiska Android lokalnie.

## Struktura

```
project.godot
export_presets.cfg — startowa konfiguracja eksportu Web + Android
translations/ui.csv — tłumaczenia PL/EN/DE (Localization.gd, TranslationServer)
art/backgrounds/   — grafiki teł (większość ekranów + 18 miast, patrz
                     docs/GRAFIKA_LEONARDO.md)
art/paintings/     — 40 obrazów kolekcji + warianty podróbek (painting_NN.jpg,
                     painting_NN_fake.jpg)
scenes/            — ekrany gry (Control + skrypt): main_menu, hub,
                     travel_map, travel_animation, plantation, warehouse,
                     stock_market, market, races, auction_house, art_school,
                     gallery, ending, settings
scripts/autoload/  — globalny stan gry: SceneRouter, Calendar, Cities,
                     Travel, Crops, Economy, PlayerPlantations, Paintings,
                     Auctions, ShippingCompanies, ForwardContracts,
                     AIPlayers, Security, Players, GameState, SaveGame,
                     Localization
scripts/ui/        — wspólne budowniczowie UI (ScreenHelpers) + natywnie
                     rysowane ikonki tam, gdzie Leonardo.ai uparcie
                     generowało pełne sceny zamiast wyizolowanych ikon:
                     MapPin, MenuFrame, VaultIcon, TravelVehicle,
                     PlantationTileIcon, PriceChart
tests/             — run_tests.tscn/.gd, testy autoloadów uruchamiane w CI
```

## Co dalej

Wszystkie tła ekranów z "priorytetu 2" (Plantacje, Dom aukcyjny, Giełda,
Wyścigi, Szkoła sztuki, Galeria, Spichlerz) są już wygenerowane i podpięte —
patrz tabela "Plan produkcji" w `docs/GRAFIKA_LEONARDO.md` po aktualny status.
Zostały mniejsze/dodatkowe assety: ramka obrazu (do aukcji/galerii), ikony UI
ogólne, portrety rywali AI, fazy wzrostu roślin, konie/dżokeje i reszta
wariantów podróbek obrazów — logika biznesowa jest gotowa i nie powinna
wymagać większych zmian przy ich dodawaniu.
