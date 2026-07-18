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

**Konsekwencja projektowa:** miasta blisko Europy/Ameryki (Richmond, St.
Louis, Rio, Meksyk, Gwatemala, Bogota) są wygodne i "bezpieczne" — dobre na
start. Miasta odległe (Ankara, Bombaj, Colombo, Afryka) są ryzykowne, wolno
się do nich dojeżdża, ale (patrz pkt. 3) czasem mają lepsze plony. To dobry,
naturalny gradient trudności geograficznej zamiast sztucznego "poziomu".

## 3. Plantacje — plony wg lokalizacji

Każde miasto plantacyjne ma inny profil upraw (kawa / tytoń / herbata /
kakao). Z tabeli źródłowej (500 robotników, 30 dni, pola przy rzece):

- **Najlepszy tytoń:** Richmond, St. Louis, Rio, Bombaj, Meksyk
- **Najlepsza kawa:** Abidżan, Gwatemala, Rio, Bogota, Duala
- **Najlepsza herbata:** Ankara, Bombaj, Mombasa, Colombo
- **Najlepsze kakao:** Abidżan, Duala, Bogota, Rio

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
