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
- **Noworoczna Loteria może wylosować konkretny, prawdziwy obraz** (w opisie
  gracz wygrywa autentycznego Mackego) — nie tylko gotówkę. Potwierdza naszą
  wcześniejszą decyzję (GDD 4.8), dodaje konkretny wariant nagrody.
- **Zwrot fabularny w zakończeniu oryginału:** według tej relacji z rozgrywki,
  na koniec gry testament ujawnia, że **wuj Walther von Grünschild i
  fałszerz Vico Vermeer to ta sama osoba** — cały "polowanie na fałszerza"
  było w istocie testem zaaranżowanym przez samego wuja dla przyszłego
  spadkobiercy. ✅ **Zaimplementowane niemal dosłownie** w ekranie zwycięstwa
  (`scenes/ending/Ending.gd::_build_win`) — nie jest to już tylko rekomendacja
  do rozważenia.

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
  ochroniarza, akcja "wyślij gangstera" przeciw wybranemu rywalowi), dostępny
  z ekranu Galerii. Brak jedynie osobnej "wieży strażniczej" jako wizualnego
  elementu — mechanicznie system działa w całości.
- ⬜ **Pompy wodne**: inwestycja podnosząca plon i chroniąca przed klęskami
  (susza/powódź) — wciąż niezaimplementowane, rozszerzenie mechaniki ryzyka
  pogodowego z GDD 4.2 (która sama w sobie też jeszcze nie istnieje, patrz
  tam).
- ⬜ **Towar zalegający na magazynie dłużej niż rok psuje się** — wciąż
  niezaimplementowane; `stored_goods` w `PlayerPlantations.gd`/Spichlerzu nie
  ma żadnego mechanizmu starzenia/zepsucia.
- ⬜ **Akademia Sztuki w konkretnym mieście** (w sequelu: Rzym) z dłuższymi
  kursami — wciąż niezaimplementowane; `ArtSchool.gd` jest dostępna z
  dowolnego miasta, nie tylko jednego.
- ⬜ **Ukryte, "nielegalne" lokalne uprawy** (w sequelu: konopie w Ankarze) —
  wciąż niezaimplementowane; `PlayerPlantations.gd`/`Crops.gd` nie mają
  wariantu nielegalnej uprawy ani mechaniki konfiskaty.
- ⬜ **3 "ulubione obrazy wuja"** — specjalne obrazy bonusowe (poza
  katalogiem 40), bez fałszywek, dające dodatkową nagrodę/punkty uznania,
  gdy trafią do kolekcji. W oryginalnym materiale wymienione jako prawdziwe,
  historyczne (domena publiczna) dzieła: *"Zabawa na lodzie przy fosie
  miejskiej"* Adriaena van de Velde (1659), *"Canale Grande w Wenecji"*
  Canaletta (1730), *"Dentysta"* Gerarda van Honthorsta (1622). Wciąż
  niezaimplementowane — `Paintings.CATALOG`/`PAINTING_INFO` obejmują tylko
  40 numerów katalogowych, bez osobnej puli bonusowej.

## Status rekomendacji (zaktualizowane)

Zamiast pierwotnej listy "co dopisać do GDD" — te rekomendacje zostały już
zrealizowane i sam GDD.md (sekcje 4.2, 4.7, 10, 11) je odzwierciedla:
sezonowość zbiorów, kara umowna za niezrealizowany kontrakt terminowy,
kradzieże/ochrona (choć jako pełny system, nie tylko "odłożone na później") i
twist fabularny (wuj = Vico) jako faktyczne zakończenie w `Ending.gd`. Jedyne,
co realnie zostaje otwarte/odłożone: pompy wodne, psucie się towaru w
magazynie, Akademia Sztuki przypisana do jednego miasta, nielegalne uprawy i
3 bonusowe obrazy wuja — patrz oznaczenia ⬜ wyżej.
