# Vermeer (C64, 1987) — pełne streszczenie artykułu c64-wiki.de

Uwaga: to jest **streszczenie/parafraza wszystkich sekcji** artykułu, nie
dosłowne tłumaczenie — oryginalny tekst jest cudzą twórczością (opis,
strategie, cytowane recenzje użytkowników), więc przepisuję fakty i sens
własnymi słowami, zamiast kopiować zdania 1:1. Wszystkie informacje z tego,
co wkleiłeś, są tutaj ujęte.

## Dane podstawowe

Gra nr 84 w katalogu c64-wiki, ocena 8,34/10 (41 głosów, ranking #45).
Twórcy: Paul Förterer, Andreas Kemnitz, Ralf Glau. Wydawca: Ariolasoft, 1987.
Platformy: Amstrad CPC, Atari ST, Amiga, C64, PC (DOS). Gatunek: strategiczna
symulacja ekonomiczna. Tryb: do 4 graczy, na zmianę. Wersje językowe: niemiecka
i angielska (nieoficjalna wersja "+1ED" od grupy Laxity z 2014).

## Opis (fabuła i cel gry)

Akcja zaraz po I wojnie światowej. Cenna kolekcja sztuki zaginęła w
zawierusze wojennej. Jej dawny właściciel, Walther von Grünschild, daje
potencjalnym spadkobiercom kapitał startowy i zapowiada, że zapisze swoje
światowe imperium gospodarcze temu, kto tak pomnoży pieniądze, by odzyskać
obrazy. Spadkobiercy prowadzą interesy na całym świecie: zakładają plantacje
kawy, tytoniu, herbaty i kakao, dodatkowo zarabiają na spekulacjach
giełdowych. Gra osadzona jest w realiach Wielkiego Kryzysu — okresowe fale
inflacji i reformy walutowe przynoszą czasem straty, czasem ogromne zyski.
Jedynym tropem prowadzącym do zaginionej kolekcji jest niejaki **Vico
Vermeer**, jeden z najlepszych fałszerzy sztuki swojej epoki. Zaginione
obrazy (wraz z podróbkami) zaczynają się pojawiać na międzynarodowych
aukcjach. Zyski z plantacji i giełdy służą głównemu celowi — wykupywaniu
obrazów na aukcjach. Gracze rywalizują zarówno o najlepsze plantacje za
granicą, jak i o przybicie młotka na europejskich aukcjach. Gdy wszystkie 40
obrazów trafi w ręce graczy, von Grünschild spisuje testament, wskazując
zwycięzcę jako spadkobiercę — i gra się kończy.

## Oprawa graficzna i dźwiękowa

Grafika jest bardzo minimalistyczna — gra działa głównie w trybie tekstowym
ze zmodyfikowanym zestawem znaków, ale wykorzystanym z dużą dbałością o
szczegóły (autor artykułu porównuje to korzystnie do prostszych,
amatorskich symulacji ekonomicznych pisanych w BASIC-u). Ekrany są
podzielone na czytelne okna; wybrana opcja menu jest podświetlana inwersją
kolorów. Nieliczne odstępstwa od czystego trybu tekstowego to proste,
jednokolorowe grafiki: tajemniczo mrugająca postać kobiety na ekranie
tytułowym (nawiązanie do obrazu Jana Vermeera "Dziewczyna z perłą"),
zadowolony z siebie Vico Vermeer pojawiający się w scenkach przerywnikowych,
mapa w menu podróży oraz drobne animacje podczas podróży statkiem/pociągiem.
Te elementy są subtelne i szybko się wczytują — w przeciwieństwie do
wcześniejszej gry Ariolasoftu w tym gatunku ("Hanse"), gdzie rysowanie mapy
po każdej turze trwało bardzo długo.

Warstwa dźwiękowa jest równie oszczędna: kilka mini-dżingli, sygnał
dźwiękowy przy poruszaniu się po menu i przy zmianach w plantacji (wyższy
dźwięk przy zatwierdzeniu wyboru — pełni funkcję potwierdzenia, że sterowanie
zadziałało), oraz dźwięk "tykania" (jak dalekopis) towarzyszący wypisywaniu
się raportów miesięcznych, ofert kontraktów terminowych czy wiadomości —
buduje poczucie wagi wydarzenia. Ogólnie: nacisk położony jest na
funkcjonalność, nie efektowność (autor porównuje to do innych symulacji
ekonomicznych epoki — bardziej rozbudowanych niż "Vermeer", jak "Oil
Imperium", ale i bardziej surowych, jak "Oel").

## Sterowanie

Gra w pełni sterowana menu — klawiszami kursora + Enter, albo joystickiem
(ruch w przód/tył wybiera pozycję menu, przycisk ognia zatwierdza). Przy
wpisywaniu liczb: ruch w lewo/prawo wybiera cyfrę, w przód/tył zmienia jej
wartość, ogień zatwierdza. Opcja "Wyjście" zawsze cofa do poprzedniego menu
(wpisanie samych zer też liczy się jako wyjście). Imiona/nazwy wpisuje się z
klawiatury. Zablokowane opcje menu (np. niemożliwa trasa z miasta
śródlądowego wprost do portu zamorskiego) są oznaczone podwójną strzałką.

## Instrukcja pełna

Pełna instrukcja gry (autorstwa H.T.W.) oraz rozwiązania dostępne są online
na stronie C64Games.de (gra nr 190) — artykuł odsyła tam po szczegóły, sam
podaje streszczenie kluczowych mechanik (opisane niżej i w
`MECHANIKI_EKONOMICZNE.md`).

## Czasy podróży

Podróż między dwoma miastami nie zawsze trwa tyle samo — wewnętrznie data w
grze jest zapisywana z częścią ułamkową, więc np. wpis "14,9 dnia" z
Abidżanu do Nowego Jorku oznacza, że zwykle podróż trwa 15 dni, ale średnio
raz na 10 razy tylko 14 (bardzo wczesny wyjazd). Pełna macierz miast i
czasów podróży (17 lokacji) jest podsumowana w `MECHANIKI_EKONOMICZNE.md`
pkt. 2 — najkrótsze trasy to te między europejskimi stolicami (rząd 1,5–2,3
dnia), najdłuższe to trasy międzykontynentalne do Azji (rząd 30+ dni).

## Co gdzie najlepiej rośnie

Tabela w artykule pokazuje plony przy 500 robotnikach po 30 dniach, dla
plantacji złożonej z pól przylegających do rzeki (nie jest to plantacja
optymalna, tylko punkt odniesienia). Wnioski: Ankara i Bombaj dobre pod
tytoń i herbatę; Mombasa i Duala dobre pod herbatę/kakao; Abidżan bardzo
dobry pod kawę i kakao; Rio doskonałe pod tytoń i dobre pod kawę; Bogota i
Gwatemala dobre pod kawę; Meksyk dobry pod tytoń; Richmond i St. Louis mają
najwyższe plony tytoniu ze wszystkich lokacji. Rekomendacja z artykułu:
zaczynać plantację od pola przy rzece (wyższy plon), a przy mniejszych
plantacjach i tak opłaca się zatrudnić maksymalnie 500 robotników, bo
produkcja na robotnika jest stała przy polach powyżej ok. 30 ha.

## Koszty transportu

Koszty transportu pojedynczej jednostki towaru do Londynu i Nowego Jorku są
**stałe przez całą grę** — nie zależą od inflacji, w przeciwieństwie do cen
sprzedaży towarów.

## Linie żeglugowe

Cztery fikcyjne linie żeglugowe działają regionalnie: Lloyd (głównie Azja),
Star (Afryka), Hanse (Ameryka Południowa), Royal (Ameryka Północna).
Wykorzystywanie odpowiednich plantacji pozytywnie wpływa na kurs akcji danej
linii żeglugowej na giełdzie.

## Aukcje obrazów

Każdy obraz ma numer katalogowy. Próba wylicytowania obrazu o numerze, który
gracz już posiada, automatycznie ujawnia go jako fałszywkę. Pełna lista 40
obrazów w 8 kategoriach stylistycznych (Vermeer, Barok, Klasycyzm,
Romantyzm, Impresjonizm, Symbolizm, Ekspresjonizm, Moderna) — w
`docs/ZRODLA_C64_WIKI.md`.

## Wskazówki techniczne (tipy)

Jedna wskazówka dotyczy wyłącznie emulatora VICE: jeśli zapisuje się stan
gry na tej samej dyskietce/pliku .d64 co samą grę, trzeba zamknąć emulator
przed wyłączeniem Windows, inaczej zapis może się uszkodzić. Czysto
techniczna ciekawostka, nieistotna dla remake'u.

## Błędy (bugi) oryginału

1. W trybie jednoosobowym gra nie kończy się mimo zdobycia wszystkich 40
   obrazów — przy kolejnej Noworocznej Loterii komputer się zawiesza.
2. Jeśli gracz jest obecny przy sprzedaży obrazu innego gracza i Vico
   wylicytuje ten obraz, sprzedający nie dostaje zapłaty (błąd, naprawialny
   ręczną ingerencją w pamięć emulatora).
3. Jeśli gracz jest w danym mieście podczas sprzedaży obrazu innego gracza,
   ale nie idzie na aukcję, sprzedający i tak nic nie dostaje.
4. Raz skatalogowany obraz pozostaje skatalogowany do końca gry, nawet po
   zmianie właściciela — dotyczy to też podróbek/oryginału tego samego
   numeru.
5. Jeśli w jednej kategorii skatalogowanych jest więcej niż 6 obrazów,
   pokazuje się tylko pierwszych 6 — reszta jest niedostępna do przeglądania
   czy sprzedaży (ograniczenie techniczne C64).
6. Przy próbie podróży bez wystarczających środków gra pyta o 14-dniowy
   postój; różne wybory prowadzą do różnych (czasem niespójnych) animacji na
   mapie podróży.

## Strategie/rozwiązania opisane w artykule (streszczenie ogólnej logiki, nie krok po kroku)

Artykuł zawiera trzy warianty strategii zaproponowane przez społeczność,
ogólna logika wszystkich trzech: (1) na starcie zainwestować część kapitału
w akcje linii żeglugowych jako zabezpieczenie, (2) zaciągnąć kredyt i szybko
założyć solidną plantację tytoniu w łatwo dostępnym mieście (typowo Richmond,
St. Louis lub Ankara), zatrudniając adekwatną liczbę robotników, (3)
powtarzać cykl: zbiory → sprzedaż w Nowym Jorku/Londynie → rozbudowa
plantacji, w rytmie ok. 30-dniowym, aż zgromadzi się duży kapitał, (4)
dopiero potem zacząć regularnie kupować obrazy na aukcjach. Dodatkowe
wskazówki: zawsze zgadzać się na podwyżki płac robotników (opłaca się przez
rosnące ceny sprzedaży), po reformie walutowej lepiej przeczekać strajk niż
płacić w nowej walucie, kontrakty terminowe warto zawierać zawsze gdy to
możliwe (a agresywnie tuż przed spodziewaną reformą walutową, sygnalizowaną
rosnącym kursem dolara), a przy współdzielonej plantacji z innym graczem —
podbijać płace, by nie dać się podkupić. Dodatkowa uwaga z artykułu: plon
rośnie liniowo z liczbą robotników, a pola blisko rzeki są wydajniejsze —
więc bardzo duże plantacje bywają nieopłacalne względem mniejszych, dobrze
zaopatrzonych w robotników pól przy rzece.

## Cheaty i easter eggi

Jeśli nie stać gracza na podróż, gra proponuje 14-dniowy postój — zgoda
czasem kończy się prezentem pieniężnym od "przyjaciela" (przydatne w
trudnej sytuacji finansowej). Gracz, którego imię zaczyna się na literę "P"
(przy kilku takich — ten z najwyższym numerem gracza), zyskuje ukryte
bonusy, jeśli jako pierwszą czynność w Londynie odwiedzi rynek/giełdę: +10%
do plonów plantacji, brak wymuszonych "przejażdżek" z Vico, większa szansa
na darowizny w pierwszych 200 dniach gry, mniejsza szansa na strajki
robotników. Bonusy te znikają po Noworocznej Loterii. Istnieją też crackowane
wersje z funkcją trenera (na stronie CSDb).

## Kody/pokey do edycji pamięci (tylko techniczna ciekawostka retro)

Czasopismo "64'er" (wydanie 12/91) publikowało kody do edycji stanu gry
poprzez freezer/monitor pamięci — nieaktualne względem wersji dostępnej na
C64Games.de. Dla tej ostatniej wersji artykuł podaje adresy pamięci, pod
którymi przechowywany jest stan gotówki czterech graczy (liczby
zmiennoprzecinkowe) oraz adres, pod którym można ustawić liczbę dostępnych
robotników na plantacji powyżej domyślnego limitu 500. To czysto retro/
emulacyjna ciekawostka, bez znaczenia dla remake'u na Androida.

## Oceny

c64-wiki: 8,34/10 (41 głosów, ranking #45). C64Games.de: 6/10 (12 426
pobrań, ocena z 2006). Lemon64: 8,53/10 (15 głosów). Kultboy.com: 8,41/10
(22 głosy).

## Sentyment recenzji użytkowników (streszczenie ogólne, bez cytowania)

Kilku recenzentów chwali grę jako wciągającą symulację handlową, z której
"można się czegoś nauczyć o historii" — jeden zaznacza jednak, że kawa i
kakao są wyraźnie mniej opłacalne niż tytoń. Kilku recenzentów wskazuje ją
jako swoją ulubioną grę na C64 wszech czasów, z dużą liczbą przegranych
godzin i sentymentem także do późniejszej wersji PC. Jeden recenzent
zauważa, że trudniejsze regiony (Ankara, Afryka) rzadko się opłacają, co
przypisuje brakowi dopracowanego balansu (typowe dla gier tamtej epoki).
Inny podkreśla wyjątkową prezentację audiowizualną — mimo prostoty (albo
właśnie dzięki niej) budującą wyraźny klimat, lepszy niż w późniejszych
portach na PC czy Amigę. Jedna recenzja szczegółowo chwali połączenie kilku
systemów (budowa produkcji, zarządzanie zasobami, gra na giełdzie, aukcje) w
spójną całość, docenia dynamiczną kolejność ruchów zależną od czasu
podróży/pobytu zamiast sztywnych rund, dobrze zaprojektowaną rywalizację
graczy przez licytacje i podkupywanie robotników (bez bezpośredniej wojny,
w odróżnieniu od innych ówczesnych tytułów ekonomicznych), oraz postać Vico
Vermeera jako źródło swoistego, ekscentrycznego humoru. Ta sama recenzja
wspomina, że magazyn "PC Games" umieścił kiedyś tę grę na liście 50
najbardziej wpływowych gier wszech czasów.

## Highscore

Artykuł zaznacza, że klasyczny ranking wyników nie ma tu większego sensu —
zwycięzcą jest gracz wskazany w testamencie jako spadkobierca, bez
dodatkowego podliczania punktów na koniec.

## Materiały dodatkowe wspomniane w artykule

Artykuł linkuje do: strony Wikipedii o grze, pełnej instrukcji na
C64Games.de, wpisów na Lemon64, Gamebase64, ready64, Kultboy.com, TheLegacy,
CSDb (w tym nieoficjalna poprawiona wersja "+1ED" od grupy Laxity z 2014) i
MobyGames, a także do nagrań rozgrywki na YouTube (w tym materiału z okazji
35-lecia gry z wywiadem z Ralfem Glau).
