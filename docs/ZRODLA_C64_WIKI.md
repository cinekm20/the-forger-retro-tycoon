# Materiały źródłowe z c64-wiki.de (wklejone przez użytkownika)

Ten plik zbiera surowe fragmenty treści z https://www.c64-wiki.de/wiki/Vermeer,
których nie dało się pobrać bezpośrednio (host zablokowany przez politykę
sieciową tego środowiska). Użytkownik wkleja fragmenty ręcznie, ja je tu
archiwizuję i wyciągam z nich wnioski do GDD/grafiki.

## Fragment 1: system fałszerstw + katalog 40 obrazów

> [...] vorhandenen Nummer wird das gekaufte Bild als Fälschung entlarvt.

Czyli: każdy obraz ma unikalny **numer katalogowy**. Jeśli gracz kupi/skataloguje
obraz o numerze, który już posiada (w kolekcji), zostaje on **ujawniony jako
fałszywka**. To jest właściwy mechanizm rozpoznawania podróbek w oryginale —
prostszy i bardziej "systemowy" niż to, co założyliśmy wcześniej (quiz wizualny).

### Pełna lista 40 obrazów wg kategorii (styl/epoka):

| # | Vermeer | # | Barok | # | Klasycyzm | # | Romantyzm |
|---|---------|---|-------|---|-----------|---|-----------|
| 1 | Vermeer | 6 | Rembrandt | 11 | David | 16 | Turner |
| 2 | Vermeer | 7 | Hals | 12 | Goya | 17 | Constable |
| 3 | Vermeer | 8 | Rubens | 13 | Ingres | 18 | Géricault |
| 4 | Vermeer | 9 | Brueghel | 14 | Chardin | 19 | Friedrich |
| 5 | Vermeer | 10 | Murillo | 15 | Millet | 20 | Runge |

| # | Impresjonizm | # | Symbolizm | # | Ekspresjonizm | # | Moderna |
|---|---------------|---|-----------|---|-----------------|---|---------|
| 21 | Monet | 26 | Moreau | 31 | Derain | 36 | Van Gogh |
| 22 | Pissarro | 27 | Klimt | 32 | Kirchner | 37 | Gauguin |
| 23 | Cézanne | 28 | Hodler | 33 | Marc | 38 | Klee |
| 24 | Degas | 29 | Whistler | 34 | Macke | 39 | Picasso |
| 25 | Renoir | 30 | Khnopff | 35 | Munch | 40 | Braque |

8 kategorii × 5 obrazów = 40. Kategorie idą chronologicznie/stylistycznie:
Vermeer (XVII w., malarstwo holenderskie) → Barok → Klasycyzm → Romantyzm →
Impresjonizm → Symbolizm → Ekspresjonizm → Moderna (wczesny XX w.).

## Fragment 2: postać Vico

Wcześniej ustalone (Wikipedia): **Vico Vermeer** to fikcyjny fałszerz sztuki
pojawiający się w grze — najwyraźniej rywal/NPC, który też bierze udział w
sprzedaży obrazów (patrz bug #2 niżej: "Vico das Bild ersteigert" = "Vico
licytuje/kupuje obraz").

## Fragment 3: Tipy (VICE-specyficzne, nieistotne dla remake'u)

Uwaga o zapisie stanu gry na tej samej dyskietce co gra w emulatorze VICE —
czysto techniczna ciekawostka związana z emulacją C64, nie wpływa na design.

## Fragment 4: Bugi oryginału (przydatne jako źródło wiedzy o mechanikach!)

1. W trybie jednego gracza gra nie kończy się nawet po zdobyciu wszystkich 40
   obrazów — crash przy kolejnej **"Neujahrstombola"** (dorocznej noworocznej
   loterii/losowaniu). → **Wniosek dla nas:** w oryginale istnieje coroczne
   wydarzenie "Noworoczna Loteria", osobny system od aukcji.
2. Jeśli gracz jest obecny przy sprzedaży obrazu innego gracza i **Vico**
   wylicytuje ten obraz, sprzedający nie dostaje zapłaty (bug, naprawialny
   pokem w monitorze VICE).
3. Jeśli gracz jest w danym mieście podczas sprzedaży obrazu innego gracza,
   ale nie idzie na aukcję, sprzedający i tak nic nie dostaje.
4. Obraz raz **"skatalogowany"** (einsortiert) pozostaje skatalogowany do
   końca gry, nawet jeśli zostanie sprzedany innemu graczowi. Dotyczy to też
   fałszywek/oryginału tego samego numeru. → **Wniosek:** katalogowanie to
   osobna, trwała akcja/system (jak "album/gablota" w kolekcji), niezależna
   od aktualnego właściciela.
5. Jeśli w jednej kategorii jest skatalogowanych więcej niż 6 obrazów, pokazuje
   się tylko pierwszych 6 (techniczne ograniczenie C64, nieistotne dla nas —
   ale potwierdza, że **UI kolekcji jest podzielone na te same 8 kategorii**
   stylistyczne co tabela wyżej, wyświetlane jako siatka/gablota).
6. System podróży: jeśli nie stać gracza na podróż, dostaje pytanie o 14-dniowy
   postój; różne animacje/diagramy w zależności od wyboru (statek na mapie
   podróży vs. motyw postoju). → **Wniosek:** podróż między miastami jest
   wizualizowana na mapie (np. płynący statek), z jednostką czasu ok. 14 dni
   jako "postój".

## Co to zmienia w naszym designie (do przeniesienia do GDD.md)

- Kolekcja/galeria dzieli się na **8 kategorii stylistycznych**, każda z 5
  slotami — nie płaska lista 40.
- Autentykacja obrazu = **sprawdzenie numeru katalogowego** względem tego, co
  już masz skatalogowane (prostszy, bardziej strategiczny system niż quiz —
  możemy quiz z "szkoły sztuki" potraktować jako dodatkowy sposób na
  *podniesienie szansy wykrycia* przed zakupem, a nie jedyny mechanizm).
- **Vico** to nazwany rywal/antagonista (nie tylko anonimowe AI) — dobry hak
  fabularny na "boss rywala" w wersji mobilnej.
- Osobne wydarzenie **Noworoczna Loteria** — dodatkowe roczne źródło
  pieniędzy/nagród, oprócz plantacji/giełdy/wyścigów.
- Podróże między miastami to nie tylko przeskok ekranu, ale wizualizowana
  trasa (statek), z realnym upływem czasu (dni) — dobry kandydat na animowaną
  scenę przejścia między lokacjami na mapie świata.

**Jeśli masz więcej fragmentów strony (zasady gry krok po kroku, opis miast,
opis interfejsu/menu, początkowy kapitał, ceny plantacji) — wklejaj dalej,
dopiszę je tutaj i zaktualizuję GDD.**

## Fragment 5: prawdziwe opisy 40 obrazów (rewersy kart z pudełka gry)

Użytkownik podesłał skany fizycznych "Gemäldekarten" dołączonych do
oryginalnego wydania Ariolasoft (1987) — 40 kart z reprodukcją obrazu na
przodzie i opisem (tytuł/malarz/rok/muzeum) na rewersie. **Same skany
(fotograficzne reprodukcje obrazów) NIE są używane jako grafika w naszej
grze** — część przedstawionych dzieł (np. Picasso 1906, Braque 1908,
Matisse 1911) może wciąż podlegać prawom autorskim w niektórych krajach, a
poza tym cały projekt konsekwentnie używa własnych, wygenerowanych
reinterpretacji stylu zamiast kopiować oryginalne assety (patrz
GRAFIKA_LEONARDO.md). Same FAKTY (tytuł/autor/rok/muzeum) nie podlegają
prawom autorskim i **są** wykorzystane — jako `Paintings.PAINTING_INFO` w
kodzie, pokazywane graczowi podczas licytacji (AuctionHouse.gd).

Ten materiał **koryguje** tabelę z Fragmentu 1 wyżej — tamta była
przybliżoną rekonstrukcją sprzed dostępu do prawdziwych danych i nie
zgadzała się z faktycznym przypisaniem numerów katalogowych do konkretnych
obrazów (np. numer 6 to nie Rembrandt tylko Vermeer). Poprawiony
`Paintings.CATALOG` (numer → kategoria) w kodzie jest zbalansowany do 5 na
kategorię wg prawdziwego stylu/epoki malarza z każdej karty.

Pełna lista (numer / malarz / tytuł / rok / muzeum), tłumaczenie własne z
niemieckich rewersów kart:

| # | Malarz | Tytuł | Rok | Muzeum |
|---|--------|-------|-----|--------|
| 01 | Willem van de Velde | Salwa armatnia | ok. 1670 | Amsterdam, Rijksmuseum |
| 02 | Rubens | Porwanie córek Leukipposa | ok. 1619 | Monachium, Alte Pinakothek |
| 03 | Vermeer | Pracownia malarska | 1666 | Wiedeń, Kunsthistorisches Museum |
| 04 | Vermeer | Koronczarka | 1665 | Paryż, Luwr |
| 05 | Rembrandt | Starzec w fotelu | 1652 | Londyn, National Gallery |
| 06 | Vermeer | Czytająca list kobieta w błękicie | 1662–1663 | Amsterdam, Rijksmuseum |
| 07 | Degas | Wanna | 1886 | Paryż, Luwr |
| 08 | Corinth | Portret malarza Waltera Leistikowa | 1900 | Berlin, Muzea Państwowe |
| 09 | Vermeer | Astronom | 1668 | Paryż, kolekcja prywatna |
| 10 | Vermeer | Dziewczyna z perłą | 1665 | Haga, Mauritshuis |
| 11 | Renoir | Gabrielle w rozpiętej bluzce | ok. 1907 | Paryż, kolekcja Durand-Ruel |
| 12 | Monet | Klify pod Pourville | 1882 | kolekcja prywatna |
| 13 | Cézanne | Grający w karty | 1890–1892 | Paryż, Luwr |
| 14 | Whistler | Symfonia w bieli | 1864 | Londyn, Tate Gallery |
| 15 | Friedrich | Morze lodu (Rozbite nadzieje) | 1823–1824 | Hamburg, Kunsthalle |
| 16 | Constable | Latarnia morska w Harwich | ok. 1820 | Londyn, Tate Gallery |
| 17 | Ensor | Kobieta jedząca ostrygi | 1882 | Antwerpia, Musée des Beaux-Arts |
| 18 | Klimt | Portret Emilie Flöge | 1902 | Wiedeń, Muzeum Historyczne Miasta Wiednia |
| 19 | Turner | Pożar Izb Parlamentu w Londynie, 16 października 1834 | 1835 | Cleveland Museum of Art |
| 20 | Delacroix | Grecja na ruinach Missolungi | ok. 1826–1827 | Bordeaux, Musée des Beaux-Arts |
| 21 | Böcklin | Tryton i Nereida | 1895 | Florencja, Villa Roma |
| 22 | Khnopff | Zamykam się w sobie | 1891 | Monachium, Neue Pinakothek |
| 23 | Runge | Autoportret | 1802 | Hamburg, Kunsthalle |
| 24 | Canaletto | Dziedziniec zamku Warwick | 1751 | Warwick, kolekcja Księcia Warwick |
| 25 | Gauguin | Dwie Tahitanki | 1899 | Nowy Jork, Metropolitan Museum of Art |
| 26 | Van Gogh | Zwodzony most | 1888 | Kolonia, Wallraf-Richartz-Museum |
| 27 | Chardin | Autoportret | 1775 | Paryż, Luwr |
| 28 | Ingres | Kąpiąca się z Valpinçon | 1808 | Paryż, Luwr |
| 29 | Matisse | Złote rybki i rzeźba | 1911 | Nowy Jork, MoMA |
| 30 | Derain | Tancerka | 1906 | Kopenhaga, Statens Museum for Kunst |
| 31 | Goya | Skruszony święty Piotr | 1823–1825 | Waszyngton, The Phillips Collection |
| 32 | David | Śmierć Marata | 1793 | Bruksela, Musées royaux des Beaux-Arts |
| 33 | Munch | Madonna | 1893–1894 | Oslo, Munch Museet |
| 34 | Picasso | Fryzura | 1906 | Nowy Jork, Metropolitan Museum of Art |
| 35 | Brueghel | Żniwa | 1565 | Nowy Jork, Metropolitan Museum |
| 36 | Hals | Młodzieniec trzymający czaszkę | ok. 1626 | Londyn, National Gallery |
| 37 | Kandinsky | Kościół wiejski | 1908 | Wuppertal, Von der Heydt-Museum |
| 38 | Marc | Koń w krajobrazie | 1910 | Essen, Museum Folkwang |
| 39 | Macke | Targ w Tunisie | 1914 | Bielefeld, Kunsthalle |
| 40 | Braque | Wiadukt w L'Estaque | 1908 | kolekcja prywatna |
