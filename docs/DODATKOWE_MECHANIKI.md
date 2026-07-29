# Dodatkowe ustalenia — z materiałów przesłanych w ZIP-ie

Źródła: skan fan-mapy (© skdluxe.de, zawiera też zrzut oryginalnego ekranu
tytułowego C64), plik cheatów (Ariolasoft), notatki taktyczne Johannesa
Wieswega (dot. sequela *Vermeer: Die Kunst zu erben*, 1997) i artykuł
"Kopfnuss" Petera Brauna z magazynu ASM Special 1 (opis przejścia gry
oryginalnej z 1987). Jak poprzednio: parafraza i wyciągnięte fakty/mechaniki,
nie przedruk cudzych tekstów — zwłaszcza artykuł ASM to rozbudowana,
autorska relacja z rozgrywki, więc cytuję z niej tylko twarde fakty
mechaniczne, nie prozę.

## Mapa (skan) — status

Obrazek `Vermeer_(Ariolasoft)_Karte.jpg` to fanowska mapa referencyjna (© 2004
skdluxe.de) plus zrzut ekranu tytułowego oryginału z odręcznym szkicem
nawiązującym do "Dziewczyny z perłą". **Nie kopiujemy/nie re-używamy tego
pliku** jako assetu — potwierdza za to nasze wcześniejsze ustalenia (te same
18 lokacji, ten sam podział plantacje/miasta aukcyjne) i dorzuca jedną nową
liczbę: **współczynnik opłacalności per uprawa** podany na mapie:
Kawa ×1,12, Tytoń ×2,00, Herbata ×1,29, Kakao ×1,00 (kakao jako baza). To
zgadza się z tym, co ustaliliśmy z recenzji graczy — tytoń jest wyraźnie
najbardziej opłacalny w oryginale. **W remake'u warto to świadomie
spłaszczyć** (patrz `GDD.md` pkt. 11), a nie kopiować ten sam przechył.

Nowa mapa świata do gry: generujemy od zera w Leonardo.ai wg
`GRAFIKA_LEONARDO.md` — mamy już poprawną listę miast, więc nic z oryginalnej
grafiki nie jest nam potrzebne jako referencja wizualna.

## Nowe mechaniki z artykułu ASM (Kopfnuss, dot. gry z 1987)

- Gra zaczyna się dokładnie **1 stycznia 1918, w Londynie**, z kursem
  dolara ok. 4 marki i akcjami linii żeglugowych w okolicach 100 marek —
  potwierdza naszą tabelę giełdy jako punkt startowy do zbalansowania.
  Podróż Londyn→Ankara zajmuje w tej relacji ok. 8 dni (spójne z naszą
  macierzą: 7,8 dnia).
- **Kontrakty terminowe mają karę umowną za niedostarczenie towaru**
  ("Konventionalstrafe") — nie tylko brak zysku, ale realna strata przy
  niepowodzeniu. ✅ **Zaimplementowane:** kara = 20% wartości kontraktu
  (`ForwardContracts.PENALTY_RATIO`), patrz `MECHANIKI_EKONOMICZNE.md` pkt. 5.
- **Reforma walutowa powtarza się średnio co ~3 lata**, zapowiadana
  wzrostem inflacji i kursem dolara zbliżającym się do ok. 14 marek —
  konkretna liczba progowa do zasygnalizowania w UI ("kurs dolara > X = uwaga,
  zbliża się reforma"). ✅ **Zaimplementowane z dokładnie tym progiem**
  (`Economy.REFORM_WARNING_DOLLAR_RATE = 14.0`), patrz
  `MECHANIKI_EKONOMICZNE.md` pkt. 6.
- **Posiadanie kilku plantacji (2–3) jako zabezpieczenie ryzyka** —
  potwierdzona strategia: jeśli jedna zostanie dotknięta strajkiem,
  szkodnikami czy wywłaszczeniem, pozostałe dalej dają dochód. Dobry,
  organiczny powód, by zachęcać gracza do dywersyfikacji zamiast jednej
  megaplantacji.
- ✅ **Noworoczna Loteria może wylosować konkretny, prawdziwy obraz** (w opisie
  gracz wygrywa autentycznego Mackego) — nie tylko gotówkę. Potwierdza naszą
  wcześniejszą decyzję (GDD 4.8), dodaje konkretny wariant nagrody.
  **Zaimplementowane**: jedno wspólne losowanie na przełomie roku
  (`Calendar.new_year`, Tor A), zwycięzca wybierany losowo spośród
  WSZYSTKICH graczy (`Players.grant_new_year_to_random_player`) — zawsze
  gotówka (`Economy.NEW_YEAR_MONEY_RANGE`), z dodatkową szansą
  (`Economy.NEW_YEAR_PAINTING_CHANCE`) na losowy, autentyczny obraz z
  głównego katalogu 1-40 (liczy się do warunku zwycięstwa, nigdy nie
  trafia w numer, który zwycięzca już ma). Wynik czeka w `Lottery.gd` do
  najbliższego wejścia do Huba, które pokazuje animowany ekran
  (`scenes/new_year_lottery/NewYearLottery.gd`: konfetti, fajerwerki,
  kalendarz przewracający rok) PRZED Podsumowaniem roku.
- **Zwrot fabularny w zakończeniu oryginału:** według tej relacji z rozgrywki,
  na koniec gry testament ujawnia, że **wuj Walther von Grünschild i
  fałszerz Vico Vermeer to ta sama osoba** — cały "polowanie na fałszerza"
  było w istocie testem zaaranżowanym przez samego wuja dla przyszłego
  spadkobiercy. ✅ **Zaimplementowane niemal dosłownie** w ekranie zwycięstwa
  (`scenes/ending/Ending.gd::_build_win`) — nie jest to już tylko rekomendacja
  do rozważenia. **Nazwiska zmienione** w naszej wersji (zgłoszone przez
  użytkownika: te z oryginału niosą to samo ryzyko co dawny tytuł gry
  "Vermeer") — u nas to **Walther von Rabenstein** i **Vico Falsari**, sam
  twist fabularny (ta sama osoba pod dwiema tożsamościami) zostaje identyczny.

## Nowe mechaniki z tipów do sequela (1997)

Poniższe pochodzą z notatek do *Vermeer: Die Kunst zu erben* (kontynuacja, nie
oryginał z 1987). Część z nich od czasu pierwszej wersji tego dokumentu
**wyszła poza status "kandydata" i została faktycznie zaimplementowana** —
oznaczone ✅/⬜ przy każdej pozycji, żeby nie trzeba było zgadywać.

- ✅ **Sezonowa wydajność zbiorów w ciągu roku** (nie tylko liczba
  robotników) — **zaimplementowane dokładnie wg tej tabeli**
  (`Crops.SEASONAL_YIELD_FACTOR`, zużywane w
  `PlayerPlantations.calculate_harvest`):
  | Miesiąc | I | II | III | IV | V | VI | VII | VIII | IX | X | XI | XII |
  |---|---|---|---|---|---|---|---|---|---|---|---|---|
  | Wydajność | 40% | 70% | 100% | 100% | 80% | 60% | 80% | 100% | 100% | 70% | 40% | 30% |
- ✅ **Pola przy rzece dają podwójny plon** — zaimplementowane
  (`Crops.RIVER_YIELD_MULTIPLIER = 2.0`).
- ✅ **Kradzieże obrazów i ochrona (bodyguard)** — wbrew wcześniejszej
  klasyfikacji "post-MVP, nie rdzeń" w tym dokumencie, **to już pełny,
  wpięty system**: `Security.gd` (cotygodniowa szansa kradzieży, wynajęcie
  ochroniarza), na osobnym ekranie Ochrony (`SecurityScreen.gd`, dostępny z
  Huba niezależnie od lokalizacji). ✅ **Zgłoszenie użytkownika — akcja
  "wyślij gangstera" przerobiona z gołego przycisku na animowaną scenę
  skoku**: roster 3 wybieralnych gangsterów (`Gangsters.gd`, portret +
  nazwa), szansa powodzenia dryfuje dziennie 20-50% (Tor A, jak kursy koni w
  `Horses.gd`). Wynik ustalony PRZED animacją (`Security.resolve_gangster_attempt`),
  `HeistView.gd` tylko go wizualizuje (skradanie się, reflektor ochrony,
  pasek napięcia). Nieudana próba ma ~50% szans skończyć się złapaniem
  WŁASNEGO gangstera — dodatkowa grzywna (`CAUGHT_FINE`) ponad utraconą
  opłatę, rywal bez zmian. Brak jedynie osobnej "wieży strażniczej" jako
  stałego wizualnego elementu tła — mechanicznie system działa w całości.
- ✅ **Pompy wodne**: inwestycja podnosząca plon i chroniąca przed klęskami
  (susza/powódź) — zaimplementowane (`PlayerPlantations.has_water_pump`,
  `WEATHER_RISK_CHANCE_PER_WEEK`); posiadanie pompy blokuje całkowicie
  ryzyko pogodowe na danej plantacji.
- ✅ **Towar zalegający na magazynie dłużej niż rok psuje się** —
  zaimplementowane; `stored_goods` w `PlayerPlantations.gd` śledzi wiek
  partii towaru i usuwa ją po roku (`WorldEvents.report_spoilage`
  informuje gracza kartą wydarzenia).
- ✅ **Akademia Sztuki w konkretnym mieście** — zaimplementowane, u nas
  **Paryż** zamiast Rzymu z sequela (świadoma zmiana, spójna z resztą
  naszej listy 18 lokacji), z dłuższym kursem (`ArtSchool.TRAINING_DAYS`
  14→28 dni). `Hub.gd` blokuje dostęp do Akademii poza Paryżem
  (`LOCATION_GATED_DESTINATIONS` + `requires_cities`).
- ✅ **Ukryte, "nielegalne" lokalne uprawy** — zaimplementowane jako
  ogólna **"przemycana uprawa"** (celowo bez nazwania konkretnej
  substancji z sequela), dostępna w **Ankarze i Gwatemali**
  (`Crops.RESTRICTED_CROP_CITIES`, `is_crop_available`), z ryzykiem
  konfiskaty (`PlayerPlantations` + `WorldEvents.report_confiscation`).
- ✅ **3 "ulubione obrazy wuja"** — specjalne obrazy bonusowe (poza
  katalogiem 40), bez fałszywek, dające dodatkową nagrodę pieniężną, gdy
  trafią do kolekcji. Prawdziwe, historyczne (domena publiczna) dzieła:
  *"Zabawa na lodzie przy fosie miejskiej"* Adriaena van de Velde (1659),
  *"Canale Grande w Wenecji"* Canaletta (1730), *"Dentysta"* Gerarda van
  Honthorsta (1622). Zaimplementowane jako rzadka pozycja losowana na
  aukcji (`Paintings.BONUS_CATALOG`, `Auctions.BONUS_PAINTING_CHANCE`) —
  OBOK pełnej Loterii Noworocznej (GDD 4.8, patrz wyżej), która ma własną,
  osobną szansę na losowy obraz z głównego katalogu 1-40 (inna pula, inny
  mechanizm losowania).

## Status rekomendacji (zaktualizowane)

Zamiast pierwotnej listy "co dopisać do GDD" — te rekomendacje zostały już
zrealizowane i sam GDD.md (sekcje 4.2, 4.7, 4.8, 10, 11) je odzwierciedla:
sezonowość zbiorów, kara umowna za niezrealizowany kontrakt terminowy,
kradzieże/ochrona (choć jako pełny system, nie tylko "odłożone na później"),
Noworoczna Loteria i twist fabularny (wuj = Vico) jako faktyczne zakończenie
w `Ending.gd`. Z pierwotnie otwartej listy (pompy wodne, psucie się towaru w
magazynie, Akademia Sztuki przypisana do jednego miasta, nielegalne uprawy, 3
bonusowe obrazy wuja) **wszystkie pięć pozycji jest już zaimplementowanych** —
patrz oznaczenia ✅ wyżej. Loteria Noworoczna (GDD 4.8), wcześniej jedyny
otwarty temat z tego dokumentu, jest teraz również zaimplementowana.
