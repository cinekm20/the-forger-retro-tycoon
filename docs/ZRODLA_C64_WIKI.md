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
