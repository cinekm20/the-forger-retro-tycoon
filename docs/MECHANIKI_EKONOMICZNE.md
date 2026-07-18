# Mechaniki ekonomiczne — na bazie pełnej instrukcji/wiki oryginału

Synteza treści strony c64-wiki.de wklejonej przez użytkownika (nie kopiujemy
tekstu 1:1 — wiki jest na licencji GFDL, więc parafrazujemy i wyciągamy
mechaniki do własnego projektu). Surowe fragmenty z poprzedniej tury są w
`docs/ZRODLA_C64_WIKI.md`.

## 1. Twórcy i fakty podstawowe

Paul Förterer, Andreas Kemnitz, Ralf Glau (Ariolasoft, 1987). Platformy:
Amstrad CPC, Atari ST, Amiga, C64, PC (DOS). Do 4 graczy, **na zmianę** (nie
jednocześnie — patrz pkt. 7, kolejność tur zależy od czasu podróży/pobytu, nie
od stałej rundy).

## 2. Mapa świata — konkretne lokacje

**Miasta plantacyjne (zamorskie), 12:**
Ankara, Bombaj, Colombo, Mombasa, Duala, Abidżan, Rio de Janeiro, Bogota,
Gwatemala (miasto), Meksyk (miasto), Richmond (USA), St. Louis (USA).

**Huby handlowe / aukcyjne:**
- Ameryka: **Nowy Jork** (magazyn/giełda USA)
- Europa: **Londyn, Lizbona, Amsterdam, Paryż, Berlin** — miasta aukcyjne

Razem ok. **18 unikalnych lokacji** na mapie świata. Podróż między nimi zajmuje
**dni gry** (nie jest natychmiastowa) — czasy wahają się od ~1,5 dnia
(Paryż–Berlin) do prawie **34 dni** (Colombo–Nowy Jork). Oryginał modeluje
nawet losową wariancję (10% szans na przybycie dzień wcześniej) — u nas
wystarczy prosty przedział/losowanie ±1 dzień dla klimatu, bez przesadnej
symulacji.

### 2.1 Pełna macierz czasów podróży (w dniach gry)

Surowe dane liczbowe z oryginału — macierz symetryczna (czas A→B = B→A), więc
każda para miast podana jest tylko raz, w wierszu "dalszego" miasta. "—"
oznacza brak bezpośredniej trasy w tabeli źródłowej (prawdopodobnie brak
bezpośredniego połączenia w grze — trzeba jechać przez miasto pośrednie).

| z \ do | St.Louis | Richmond | N.Jork | Meksyk | Gwatemala | Bogota | Rio | Abidżan | Duala | Mombasa | Colombo | Bombaj | Ankara | Londyn | Lizbona | Amsterdam | Paryż |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Berlin** | — | — | — | — | — | — | — | — | — | — | — | — | 5,1 | 3,0 | 5,5 | 1,5 | 2,3 |
| **Paryż** | — | — | — | — | — | — | — | — | — | — | — | — | 6,5 | 1,5 | 3,4 | 1,3 | — |
| **Amsterdam** | — | — | 15,4 | 21,8 | 20,5 | 18,8 | 18,7 | 11,0 | 11,1 | 14,1 | 17,5 | 15,6 | 6,5 | 1,5 | 4,7 | — | — |
| **Lizbona** | — | — | 12,3 | 18,0 | 16,5 | 14,3 | 14,0 | 6,9 | 7,9 | 12,5 | 17,9 | 16,5 | 8,1 | 4,1 | — | — | — |
| **Londyn** | — | — | 13,9 | 20,4 | 19,2 | 17,6 | 18,0 | 10,8 | 11,3 | 14,8 | 18,7 | 16,9 | 7,8 | — | — | — | — |
| **Ankara** | — | — | 20,4 | 25,9 | 24,4 | 21,7 | 19,4 | 10,4 | 8,9 | 9,0 | 11,1 | 9,2 | — | — | — | — | — |
| **Bombaj** | — | — | 28,7 | 33,3 | 31,5 | 28,1 | 23,8 | 15,5 | 12,9 | 8,1 | 2,5 | — | — | — | — | — | — |
| **Colombo** | — | — | 29,8 | 34,0 | 32,1 | 28,5 | 23,7 | 15,9 | 13,2 | 7,7 | — | — | — | — | — | — | — |
| **Mombasa** | — | — | 23,2 | 26,7 | 24,8 | 21,0 | 16,0 | 8,6 | 5,9 | — | — | — | — | — | — | — | — |
| **Duala** | — | — | 17,4 | 20,9 | 19,0 | 15,3 | 11,1 | 2,7 | — | — | — | — | — | — | — | — | — |
| **Abidżan** | — | — | 14,9 | 18,2 | 16,3 | 12,6 | 9,0 | — | — | — | — | — | — | — | — | — | — |
| **Rio** | — | — | 14,1 | 13,3 | 11,3 | 7,0 | — | — | — | — | — | — | — | — | — | — | — |
| **Bogota** | — | — | 8,4 | 6,3 | 4,3 | — | — | — | — | — | — | — | — | — | — | — | — |
| **Gwatemala** | — | — | 6,8 | 2,0 | — | — | — | — | — | — | — | — | — | — | — | — | — |
| **Meksyk** | — | — | 7,2 | — | — | — | — | — | — | — | — | — | — | — | — | — | — |
| **N.Jork** | 3,1 | 1,9 | — | — | — | — | — | — | — | — | — | — | — | — | — | — | — |
| **Richmond** | 1,9 | — | — | — | — | — | — | — | — | — | — | — | — | — | — | — | — |

Przykład odczytu: Richmond → St. Louis = 1,9 dnia; Nowy Jork → St. Louis =
3,1 dnia, Nowy Jork → Richmond = 1,9 dnia; Colombo → Nowy Jork = 29,8 dnia
(najdłuższa trasa w tabeli); Berlin → Amsterdam = 1,5 dnia (najkrótsza,
razem z Paryż → Amsterdam = 1,3 dnia).

Wartości ułamkowe wynikają z tego, że w oryginale data w grze jest liczona z
częścią dziesiętną — np. 14,9 dnia oznacza zwykle 15 pełnych dni podróży, ale
średnio raz na 10 podróży tylko 14 (bardzo wczesny wyjazd rano). Do naszego
remake'u wystarczy zaokrąglać w górę i ew. dodać drobną losowość ±1 dzień,
bez modelowania ułamków dnia.

**Konsekwencja projektowa:** miasta blisko Europy/Ameryki (Richmond, St.
Louis, Rio, Meksyk, Gwatemala, Bogota) są wygodne i "bezpieczne" — dobre na
start. Miasta odległe (Ankara, Bombaj, Colombo, Afryka) są ryzykowne, wolno
się do nich dojeżdża, ale (patrz pkt. 3) czasem mają lepsze plony. To dobry,
naturalny gradient trudności geograficznej zamiast sztucznego "poziomu".

## 3. Plantacje — plony wg lokalizacji

Każde miasto plantacyjne ma inny profil upraw (kawa / tytoń / herbata /
kakao). Poniżej pełna tabela źródłowa: plon przy 500 robotnikach po 30
dniach, dla plantacji złożonej ze wszystkich pól przylegających (poziomo/
pionowo/po przekątnej) do pola rzeki — to nie jest optymalna plantacja, tylko
punkt odniesienia pokazujący profil regionu. "total" = łączny plon, "/ha" =
plon na hektar, "ha" = liczba branych pod uwagę hektarów przy rzece.

| Miasto | Kawa (total) | Kawa (/ha) | Tytoń (total) | Tytoń (/ha) | Herbata (total) | Herbata (/ha) | Kakao (total) | Kakao (/ha) | ha przy rzece |
|---|---|---|---|---|---|---|---|---|---|
| Ankara | 16 | 0,4 | 318 | 7,2 | 206 | 4,7 | 15 | 0,3 | 44 |
| Bombaj | 18 | 0,3 | 362 | 5,7 | 235 | 3,7 | 17 | 0,3 | 64 |
| Colombo | 17 | 0,4 | 30 | 0,7 | 215 | 5,1 | 15 | 0,4 | 42 |
| Mombasa | 207 | 3,8 | 33 | 0,6 | 242 | 4,4 | 17 | 0,3 | 55 |
| Duala | 208 | 3,9 | 34 | 0,6 | 22 | 0,4 | 188 | 3,5 | 54 |
| Abidżan | 240 | 3,6 | 39 | 0,6 | 26 | 0,4 | 218 | 3,3 | 66 |
| Rio | 220 | 3,3 | 396 | 5,9 | 24 | 0,4 | 199 | 3,0 | 67 |
| Bogota | 215 | 4,5 | 35 | 0,7 | 23 | 0,5 | 195 | 4,1 | 48 |
| Gwatemala | 226 | 4,5 | 37 | 0,7 | 24 | 0,5 | 19 | 0,4 | 50 |
| Meksyk | 206 | 3,6 | 373 | 6,5 | 22 | 0,4 | 17 | 0,3 | 57 |
| Richmond | 22 | 0,3 | 428 | 6,8 | 25 | 0,4 | 20 | 0,3 | 63 |
| St. Louis | 22 | 0,3 | 433 | 6,6 | 26 | 0,4 | 20 | 0,3 | 66 |

Odczyt skrócony (najlepsze lokacje per uprawa, na bazie tabeli):

- **Najlepszy tytoń:** St. Louis (433), Richmond (428), Rio (396), Bombaj (362), Meksyk (373)
- **Najlepsza kawa:** Abidżan (240), Rio (220), Gwatemala (226), Mombasa (207), Duala (208)
- **Najlepsza herbata:** Mombasa (242), Bombaj (235), Colombo (215), Ankara (206)
- **Najlepsze kakao:** Abidżan (218), Rio (199), Bogota (195), Duala (188)

**Bonus rzeki:** pola przylegające (poziomo/pionowo/po przekątnej) do pola
rzeki mają wyraźnie wyższy plon na hektar. To sugeruje **siatkowy/kafelkowy
system plantacji** (grid), gdzie gracz układa pola względem rzeki — ciekawy,
lekki mechanicznie, ale wizualnie satysfakcjonujący system budowania (drag &
drop kafelków upraw na planszy z rzeką).

**Skalowanie plonu robotnikami:** plon rośnie **liniowo** z liczbą
robotników (50 robotników → 12 plonu, 500 robotników na tym samym polu → 120
plonu). Duże pola bez odpowiedniej liczby robotników są nieefektywne —
recenzenci oryginału zwracają uwagę, że przesadnie duże plantacje bywają
marnotrawstwem pieniędzy względem zwartych pól przy rzece. **Wniosek na
remake:** zamiast "im większe pole tym lepiej", nagradzajmy kompaktowe,
dobrze zaopatrzone w robotników plantacje blisko rzeki — ciekawszy
puzzle/optymalizacyjny mikro-management niż czysty grind powierzchni.

## 4. Robotnicy i ryzyko regionalne

- Robotnicy pracują za dniówkę; płaca rośnie wraz z inflacją w grze — warto ją
  podnosić (opłaca się przez rosnące ceny sprzedaży).
- **Strajk:** jeśli gracz nie stać na wypłatę (np. po reformie walutowej),
  robotnicy strajkują — traci się bieżące zbiory, ale nie trzeba płacić
  zaległości; można później zatrudnić nowych taniej.
- **Podkupywanie robotników:** przy współdzielonej plantacji między graczami,
  wyższa płaca = trudniej podkupić Twoich robotników konkurencji. Ładny,
  pośredni PvP bez bezpośredniej walki.
- **Niestabilność polityczna / wywłaszczenia:** trudniejsze regiony (Ankara,
  Afryka) niosą ryzyko zamieszek/wywłaszczeń plantacji — kompensowane
  potencjalnie lepszym plonem herbaty/kawy. Dobry haczyk risk/reward osadzony
  w fabule (lata 20./30., niestabilność kolonialna/gospodarcza).

## 5. Kontrakty terminowe (forward contracts) — osobny system finansowy

Trzeci filar ekonomii obok sprzedaży spot i giełdy: gracz zobowiązuje się
dostarczyć określoną ilość towaru w przyszłości po **z góry ustalonej cenie**.
Kluczowa przewaga: ta cena **nie zmienia się nawet po reformie walutowej** —
świetne zabezpieczenie (hedge) i potencjalne źródło ogromnego zysku, jeśli
trafi się moment tuż przed reformą. Ryzyko: trzeba faktycznie dostarczyć
towar (kupić zboże/nasiona, jeśli własna plantacja nie starczy).

## 6. Reformy walutowe i inflacja

Nawiązanie do historycznej hiperinflacji Republiki Weimarskiej — okresowe
reformy walutowe (np. przelicznik 5:1) gwałtownie tną gotówkę graczy.
Doświadczeni gracze **wyprzedzają reformę** kontraktami terminowymi z
maksymalną wartością tuż przed nią, a "chowają się" przed płaceniem
robotnikom tuż po reformie (akceptując krótki strajk zamiast płacić w nowej,
droższej walucie). To najciekawszy, najbardziej "insider" system oryginału —
warto go zachować jako mechanikę wysokiego ryzyka/nagrody dla zaawansowanych
graczy, z czytelnym sygnałem ostrzegawczym w UI (np. rosnący kurs dolara jako
wskaźnik nadchodzącej reformy).

## 7. Linie żeglugowe — połączenie plantacji z giełdą

4 fikcyjne linie żeglugowe, każda przypisana do regionu:
- **Lloyd** — Azja
- **Star** — Afryka
- **Hanse** — Ameryka Południowa
- **Royal** — Ameryka Północna

Aktywność graczy na plantacjach danego regionu **podbija kurs akcji
odpowiedniej linii żeglugowej**. To spina plantacje i giełdę w jeden system —
dobra mechanika sprzężenia zwrotnego do zaimplementowania w remake'u (giełda
przestaje być osobną minigrą, tylko realnie reaguje na Twoje działania w
świecie).

### 7.1 Koszty transportu towaru (pełna tabela)

Koszt transportu **jednej jednostki towaru** z danego miasta plantacyjnego do
magazynu w Londynie lub Nowym Jorku. W przeciwieństwie do cen sprzedaży,
koszty transportu są **stałe przez całą grę** (nie rosną z inflacją) — "-"
oznacza brak/nie dotyczy (miasto własnego magazynu).

| Do ↓ / Z miasta → | St.Louis | Richmond | N.Jork | Meksyk | Gwatemala | Bogota | Rio | Abidżan | Duala | Mombasa | Colombo | Bombaj | Ankara | Londyn |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Londyn** | 23 | 21 | 18 | 30 | 29 | 27 | 26 | 12 | 14 | 22 | 29 | 25 | 11 | – |
| **Nowy Jork** | 4 | 3 | – | 11 | 10 | 9 | 20 | 22 | 26 | 34 | 40 | 37 | 23 | 18 |

Odczyt: wysyłka towaru z Richmond do Nowego Jorku kosztuje 3, ale z Richmond
do Londynu już 21 — stąd sensowność trzymania plantacji blisko "swojego"
magazynu (amerykańskie miasta → Nowy Jork, afrykańskie/bliskie Europie →
Londyn).

## 8. Struktura tur — kolejność wg czasu podróży (ważna decyzja projektowa)

Oryginał **nie ma** stałych rund miesiąc/rok na gracza. Kolejność ruchów
wyznacza to, czyja podróż/pobyt kończy się najwcześniej — gra działa jak
kolejka zdarzeń w czasie ciągłym (event-driven scheduling), nie klasyczny
"I gracz, potem II gracz". To elegancki system, ale bardziej złożony do
zaimplementowania niż zwykłe tury.

**Rekomendacja na MVP:** uprościć do modelu turowego z globalnym kalendarzem
(1 tura = decyzja + upływ dni podróży/pobytu), ale **zachować ideę**, że różne
akcje zajmują różną liczbę dni, więc gracze/AI nie poruszają się w idealnym
rytmie — to i tak da dużo tej samej dynamiki bez pełnej złożoności kolejki
zdarzeń. Pełny event-driven scheduler można rozważyć jako rozszerzenie po
MVP.

## 9. Vico Vermeer — rozszerzony profil postaci

Vico Vermeer to **jeden z najlepszych fałszerzy sztuki swoich czasów** —
jedyny trop prowadzący do zaginionej kolekcji. To on (pośrednio) odpowiada za
falszywki pojawiające się na aukcjach. W oryginale ma osobowość: pojawia się
w scenkach przestojów ("Meanwhile") z zadowoloną z siebie pozą, czasem
**zaprasza gracza bez pytania na "przejażdżkę"** (Spazierfahrt) — czysto
kosmetyczne wydarzenie zabierające czas, ale budujące klimat i "skurrylny
humor" (określenie recenzentów). To rywal z osobowością, nie tylko pasek AI.

**Rekomendacja:** Vico jako rozpoznawalna postać z własnymi ilustrowanymi
scenkami (miniaturowe "cutscenki" na loading screenach lub między turami),
czasem pojawia się na aukcjach i licytuje, czasem "zaprasza" gracza na
przerywnik. Dobry kandydat na osobny plik grafik w Leonardo (portret + 2-3
pozy/wyrazy twarzy).

## 10. Referencyjny tytuł i inspiracja wizualna

Oryginalny ekran tytułowy zawierał "tajemniczo mrugającą damę" — nawiązanie
do obrazu **"Dziewczyna z perłą"** Jana Vermeera (namalowany ok. 1665, od
dawna w domenie publicznej). Dobry, bezpieczny motyw na nasz ekran tytułowy —
własna, stylizowana reinterpretacja tego słynnego motywu (nie kopia obrazu 1:1,
tylko homage w naszym stylu art déco), jako mrugnięcie do oryginału i do
prawdziwego malarza Vermeera.

## 11. Uwagi projektowe z recenzji graczy (balans)

Kilka realnych opinii graczy o oryginale, przydatnych jako lekcje przy
projektowaniu balansu remake'u:

- Kawa i kakao są w oryginale wyraźnie mniej opłacalne niż tytoń — jeden z
  recenzentów krytykuje ten brak balansu. **W remake'u warto realnie
  wyrównać rentowność upraw**, zamiast biernie kopiować stare liczby.
- Trudne regiony (Ankara, Afryka) "rzadko się opłacają" — potwierdza to, co
  napisaliśmy w pkt. 2/4: warto świadomie zaprojektować risk/reward, a nie
  zostawić je przypadkowo słabszymi.
- To, co grającym podobało się najbardziej: różnorodność systemów (plantacje
  + giełda + aukcje) połączona w jedną całość, brak bezpośredniej wojny/PvP
  (rywalizacja przez licytacje i podkupywanie robotników, nie przemoc),
  oraz grywalność solo (ważne dla nas — potwierdza słuszność decyzji o
  jednym graczu + AI na start).
- Gra została później doceniona (PC Games: lista 50 najbardziej wpływowych
  gier wszech czasów) głównie za **połączenie kilku systemów ekonomicznych w
  spójną całość**, a nie za pojedynczą mechanikę — to nasz priorytet #1 przy
  polerowaniu rozgrywki.

## 12. Sterowanie oryginału (tylko jako kontekst historyczny)

W pełni menu, joystick/klawiatura, wybór cyfra-po-cyfrze przy wpisywaniu
liczb, zablokowane opcje menu oznaczone strzałką. **Nie przenosimy tego 1:1**
— na Androidzie zastępujemy: przyciski dotykowe, suwaki/steppery do liczb,
wyszarzone przyciski dla zablokowanych opcji. Zachowujemy tylko *ideę*
czytelnego stanu (podświetlenie wybranej opcji, wyraźny stan "zablokowane").
