# Vermeer — Game Design Document (Android)

## 1. Punkt wyjścia

Inspiracja: *Vermeer* (Ariolasoft, 1987, C64) — niemiecka gra ekonomiczno-strategiczna.
Oryginał był niemal wyłącznie tekstowy (tryb znakowy, zmodyfikowany fonty, minimalna
grafika, sygnały dźwiękowe przy nawigacji w menu). Seria miała potem kontynuacje:
*Vermeer: Die Kunst zu erben* (1997) i *Vermeer: The Great Art Race* (2004), już
bardziej graficzne.

Cel tego projektu: **stworzyć od nowa, w pełni graficzną wersję na Androida**,
zachowując rdzeń mechaniki (ekonomia + kolekcjonowanie sztuki), ale z nowoczesnym UI,
animacjami i oprawą wizualną w klimacie lat 20. XX wieku (art déco).

## 2. High concept

> Jesteś jednym ze spadkobierców rodzinnej fortuny roztrwonionej i rozproszonej po
> I wojnie światowej. Budujesz imperium biznesowe (plantacje, giełda, wyścigi konne),
> by zdobyć kapitał potrzebny do odkupienia rozproszonej kolekcji 40 obrazów na
> aukcjach — zanim zrobią to twoi rywale.

Gatunek: **ekonomiczna gra strategiczna / symulacja biznesowa, turowa, jednoosobowa
rozgrywka przeciw AI**, sesje 10–30 min, grywalna epizodycznie (dobra pod mobile).

## 3. Pętla rozgrywki (core loop)

1. Zarządzaj plantacjami → generuj towar (kawa, tytoń, herbata, kakao).
2. Sprzedaj towar w Nowym Jorku / Londynie → zdobądź gotówkę.
3. Pomnażaj kapitał na giełdzie lub wyścigach konnych (ryzyko/nagroda).
4. Śledź kalendarz aukcji → licytuj obrazy, uważając na fałszywki.
5. Odwiedzaj szkoły sztuki, by podnosić umiejętność rozpoznawania autentyczności.
6. Powtarzaj, rywalizując z AI o te same 40 obrazów, aż ktoś skompletuje kolekcję.

## 4. Ekrany i mechaniki

### 4.1 Hub / Mapa świata
Ekran startowy — stylizowana mapa świata (art déco, sepiowe odcienie + akcenty
złota/turkusu) z pinezkami: Twoje plantacje, giełdy (NY/Londyn), tor wyścigowy, dom
aukcyjny, szkoła sztuki. Tap na pinezkę = wejście w dany ekran. Górny pasek: gotówka,
data w grze (tura = tydzień/miesiąc), licznik posiadanych obrazów (np. "7/40").

### 4.2 Plantacje
Widok izometryczny/rzutu z góry pojedynczej plantacji z polami uprawnymi.
Mechaniki: wybór uprawy, inwestycja w robotników/narzędzia, ryzyko pogodowe
(susza, szkodniki — losowe zdarzenia z ilustrowanym popupem), zbiory i wysyłka
towaru do portu. Animacja wzrostu upraw (etapy graficzne: zasiew → wzrost →
zbiory).

### 4.3 Giełda
Ekran z wykresem cen (świece/linia, animowana), lista spółek/surowców, przyciski
kupna/sprzedaży. Wydarzenia makro (krach 1929, hiperinflacja, reformy walutowe)
jako karty zdarzeń z ilustracją gazety/nagłówka epoki.

### 4.4 Tor wyścigów konnych
Prosty ekran zakładów: lista koni z kursami, animowana scena wyścigu (można
zacząć od uproszczonej animacji 2D — sylwetki koni przesuwające się po torze),
wynik i wypłata.

### 4.5 Dom aukcyjny
Najbardziej "grafozależny" ekran. Prezentacja obrazu (w pełnej krasie, w ramie),
licytacja w czasie rzeczywistym z paskiem czasu i konkurencyjnymi ofertami AI
(z portretami rywali i ich "bid" bąbelkami). Opcja: wysłać pośrednika zamiast
licytować osobiście (ryzyko przepłacenia/przegapienia). Wśród licytujących
może pojawić się **Vico** — nazwany rywal-fałszerz, rozpoznawalna postać z
własnym portretem/animacją, który świadomie podbija ceny lub sprzedaje
podróbki.

**System autentykacji (na bazie mechaniki oryginału):** każdy z 40 obrazów ma
unikalny numer katalogowy w obrębie swojej kategorii stylistycznej. Jeśli
gracz kupi/skataloguje obraz o numerze, który już posiada — zostaje on
**automatycznie ujawniony jako fałszywka** (usuwany z kolekcji lub oznaczany).
To główny, "systemowy" mechanizm wykrywania podróbek. Szkoła sztuki (patrz
4.6) nie zastępuje tego systemu, tylko go wspiera — podnosi szansę, że gra
*ostrzeże* gracza przed zakupem podejrzanego obrazu na aukcji, zanim ten
padnie ofiarą duplikatu.

### 4.6 Szkoła sztuki / autentykacja
Mini-gra "znajdź różnicę" lub quiz porównawczy: dwa podobne obrazy, gracz uczy się
wskazówek (pociągnięcia pędzla, sygnatura, patyna) — podnosi statystykę
"eksperckość", która zwiększa szansę na wczesne ostrzeżenie o duplikacie numeru
katalogowego (patrz 4.5) przed przybiciem młotka na aukcji.

### 4.7 Galeria / kolekcja
Ekran-nagroda: wirtualna galeria z **8 sekcjami stylistycznymi** (Vermeer,
Barok, Klasycyzm, Romantyzm, Impresjonizm, Symbolizm, Ekspresjonizm, Moderna),
po 5 slotów na obraz każda — układ gabloty/ściany tematycznej, nie płaska
lista 40. Zdobyty i skatalogowany obraz **zostaje przypisany do gracza na
stałe w statystykach kolekcji**, nawet jeśli fizycznie zmieni właściciela w
dalszej rozgrywce (tak jak w oryginale — katalogowanie jest nieodwracalne).
Im więcej wypełnionych sekcji, tym bardziej "żywa" galeria (zmieniające się
oświetlenie, ambient muzyka).

### 4.8 Noworoczna Loteria (Neujahrstombola)
Coroczne wydarzenie, osobne od aukcji i giełdy — losowanie/loteria na przełomie
roku w grze, dodatkowe źródło pieniędzy lub nawet obrazu-niespodzianki. Dobry
moment na krótką, satysfakcjonującą animację (fajerwerki, konfetti, kalendarz
przewracający rok).

### 4.9 Podróże między lokacjami
Przemieszczanie się między miastami/plantacjami na mapie świata nie jest
natychmiastowe — zajmuje dni gry i jest wizualizowane (np. płynący statek po
trasie na mapie). Krótkie podróże można "przyspieszyć" płacąc więcej, długie
wymagają dłuższego oczekiwania — dobry haczyk na decyzje ekonomiczne
("czy warto lecieć osobiście na aukcję, czy wysłać pośrednika?").

## 5. Systemy ekonomiczne

- Waluta w grze podlega inflacji (nawiązanie do lat 20./30.) — wpływa na ceny
  towarów i obrazów w czasie.
- **40 obrazów w 8 kategoriach stylistycznych po 5 sztuk** (Vermeer, Barok,
  Klasycyzm, Romantyzm, Impresjonizm, Symbolizm, Ekspresjonizm, Moderna),
  każdy z unikalnym numerem katalogowym 1–40 — pełna lista w
  `docs/ZRODLA_C64_WIKI.md`. Numer decyduje o systemie autentykacji (patrz
  4.5).
- Ekonomia AI-rywali: mają własny kapitał, też inwestują i licytują — muszą
  sprawiać wrażenie żywych konkurentów (widoczne w rankingu bocznym). Jeden z
  rywali to nazwana postać **Vico** — rywal-fałszerz z własną osobowością.
- **Noworoczna Loteria** — coroczny dodatkowy zastrzyk gotówki/nagród, system
  niezależny od giełdy i aukcji.

## 6. Warunki zwycięstwa/porażki

Wygrana: gracz jako pierwszy zdobywa wszystkie 40 obrazów (lub tryb skrócony:
np. 15/40 na łatwym poziomie). Porażka: bankructwo (ujemny kapitał przez X tur)
lub rywal komplementuje kolekcję pierwszy.

## 7. Sterowanie i UX (mobile)

- Wyłącznie dotyk: tap/drag, brak zależności od fizycznych przycisków.
- Duże, czytelne elementy UI (target dla ekranów 5–7").
- Krótkie sesje: gra pauzuje się sama w tle, autosave po każdej turze.
- Powiadomienia push (opcjonalnie): "Aukcja za 2 dni", "Twoje plantacje gotowe
  do zbioru".

## 8. Stos technologiczny

**Silnik: Godot 4 (GDScript)**
- Natywny eksport na Android, brak opłat licencyjnych, lekki APK.
- Dobry do gier 2D/UI-heavy (dokładnie taki typ, co Vermeer).
- Architektura: autoloady na stan gry (Economy, Calendar, Paintings, AIPlayers),
  osobne sceny na każdy ekran z pkt. 4, wspólny UI-theme (art déco).

Struktura katalogów (proponowana, do stworzenia w kolejnym kroku):
```
/project.godot
/scenes
  /hub, /plantation, /stock_market, /races, /auction_house, /art_school, /gallery
/scripts
  /autoload  (Economy.gd, Calendar.gd, Paintings.gd, AIPlayers.gd, SaveGame.gd)
/art
  /ui, /characters, /paintings, /backgrounds, /icons
/audio
```

## 9. Kierunek artystyczny

**Styl: Art Déco lat 20., ciepła paleta (sepia, złoto, głęboka zieleń, burgund,
turkus jako akcent), płaskie ilustracje z lekką teksturą papieru/gwaszu** —
spójne z epoką i tematem sztuki/kolekcjonerstwa. Unikać realistycznego 3D —
stylizowana ilustracja 2D będzie szybsza do wygenerowania spójnie i lżejsza na
mobile.

## 10. Etapy budowy (proponowana kolejność)

1. ✅ GDD (ten dokument)
2. Szkielet projektu Godot + nawigacja między pustymi ekranami
3. Systemy danych (autoloady: ekonomia, kalendarz, 40 obrazów, AI)
4. Ekran Hub + Mapa świata (pierwszy w pełni ograficzniony ekran)
5. Plantacje → Giełda → Wyścigi → Dom aukcyjny → Szkoła sztuki → Galeria
6. Dźwięk/muzyka, polish, testy na urządzeniu
7. Eksport APK / AAB, podpisywanie, ewentualnie Google Play

## 11. Otwarte pytania projektowe

- **Multiplayer:** oryginał obsługiwał do 4 graczy lokalnie (hot-seat na
  jednym C64). Wersja mobilna na start zakłada 1 gracza + 3 AI (patrz sekcja
  6), ale hot-seat pass-and-play na jednym telefonie jest tanim rozszerzeniem
  do rozważenia later — wymaga decyzji przed projektowaniem UI tur.
- **Vico jako antagonista:** czy to zwykły, mocniejszy przeciwnik AI, czy
  dedykowany "boss" z unikalnymi zachowaniami (np. czasem świadomie
  podstawia fałszywki)? Do doprecyzowania fabularnego.
