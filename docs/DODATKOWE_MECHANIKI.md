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
  niepowodzeniu. Warto to dodać jako jawne ryzyko w UI kontraktu.
- **Reforma walutowa powtarza się średnio co ~3 lata**, zapowiadana
  wzrostem inflacji i kursem dolara zbliżającym się do ok. 14 marek —
  konkretna liczba progowa do zasygnalizowania w UI ("kurs dolara > X = uwaga,
  zbliża się reforma").
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
  spadkobiercy. **Rekomendacja:** to świetny, gotowy twist fabularny — warto
  go świadomie zaadaptować (własnymi słowami/scenariuszem) jako zakończenie
  naszej wersji, zamiast wymyślać nowe zakończenie od zera.

## Nowe mechaniki z tipów do sequela (1997) — kandydaci na rozszerzenia po MVP

Poniższe pochodzą z notatek do *Vermeer: Die Kunst zu erben* (kontynuacja, nie
oryginał z 1987) — traktujemy je jako **opcjonalne pomysły na rozszerzenie**,
nie rdzeń MVP:

- **Sezonowa wydajność zbiorów w ciągu roku** (nie tylko liczba robotników):
  | Miesiąc | I | II | III | IV | V | VI | VII | VIII | IX | X | XI | XII |
  |---|---|---|---|---|---|---|---|---|---|---|---|---|
  | Wydajność | 40% | 70% | 100% | 100% | 80% | 60% | 80% | 100% | 100% | 70% | 40% | 30% |

  To ciekawy, gotowy system: wiosna/lato/wczesna jesień = szczyt sezonu,
  zima = zastój. Dobry kandydat do MVP (nie tylko sequela) — wzmacnia
  planowanie w czasie bez dużego kosztu implementacyjnego.
- **Pola przy rzece dają podwójny plon** (potwierdzenie naszej wcześniejszej
  mechaniki bonusu rzeki z konkretnym mnożnikiem: ×2).
- **Pompy wodne**: inwestycja podnosząca plon i chroniąca przed klęskami
  (susza/powódź) — rozszerzenie mechaniki ryzyka pogodowego z GDD 4.2.
- **Towar zalegający na magazynie dłużej niż rok psuje się** — zachęca do
  regularnej sprzedaży zamiast czekania na "idealną" cenę w nieskończoność.
- **Akademia Sztuki w konkretnym mieście** (w sequelu: Rzym) z dłuższymi
  kursami — dobrze pasuje do naszej mechaniki Szkoły Sztuki (GDD 4.6),
  możemy przypisać ją do jednej, tematycznej lokacji zamiast rozpraszać po
  mapie.
- **Kradzieże obrazów i ochrona (bodyguard/wieża strażnicza)** — ciekawy,
  ale poważnie rozszerzający zakres systemu ryzyka; kandydat na
  post-MVP, nie rdzeń.
- **Ukryte, "nielegalne" lokalne uprawy** (w sequelu: konopie w Ankarze) —
  wysoki zysk, wysokie ryzyko konfiskaty przy zbyt dużej skali. Fajny
  smaczek do rozważenia jako opcjonalny, ryzykowny wariant plantacji w
  jednym mieście — ale też post-MVP, nie rdzeń.
- **3 "ulubione obrazy wuja"** — specjalne obrazy bonusowe (poza katalogiem
  40), bez fałszywek, dające dodatkową nagrodę/punkty uznania, gdy trafią do
  kolekcji. W oryginalnym materiale wymienione jako prawdziwe, historyczne
  (domena publiczna) dzieła: *"Zabawa na lodzie przy fosie miejskiej"*
  Adriaena van de Velde (1659), *"Canale Grande w Wenecji"* Canaletta (1730),
  *"Dentysta"* Gerarda van Honthorsta (1622). Możemy je zachować jako
  smaczek historyczny albo zastąpić własnym zestawem — mechanika (rzadkie,
  niepodrabialne, bonusowe obrazy) jest ciekawsza niż konkretny wybór dzieł.

## Aktualizacja rekomendacji

W `GDD.md` pkt. 10 (etapy budowy) i pkt. 11 (otwarte pytania) warto dopisać:
sezonowość zbiorów i kara umowna za niezrealizowany kontrakt terminowy jako
część MVP; kradzieże/ochrona/nielegalne uprawy jako jawnie odłożone na
później; twist fabularny (wuj = Vico) jako rekomendowane zakończenie fabuły.
