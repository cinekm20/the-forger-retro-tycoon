# The Forger: Retro Tycoon — Game Design Document (Android)

## 1. Punkt wyjścia

Inspiracja: *Vermeer* (Ariolasoft, 1987, C64) — niemiecka gra ekonomiczno-strategiczna.
Oryginał był niemal wyłącznie tekstowy (tryb znakowy, zmodyfikowany fonty, minimalna
grafika, sygnały dźwiękowe przy nawigacji w menu). Seria miała potem kontynuacje:
*Vermeer: Die Kunst zu erben* (1997) i *Vermeer: The Great Art Race* (2004), już
bardziej graficzne.

Cel tego projektu: **stworzyć od nowa, w pełni graficzną wersję na Androida**,
zachowując rdzeń mechaniki (ekonomia + kolekcjonowanie sztuki), ale z nowoczesnym UI,
animacjami i oprawą wizualną w klimacie lat 20. XX wieku (art déco).

Ten dokument opisuje ekrany i strukturę projektu. Szczegółowe dane
ekonomiczne oryginału (miasta, czasy podróży, plony wg lokalizacji, kontrakty
terminowe, reformy walutowe, linie żeglugowe) są rozpisane osobno w
`docs/MECHANIKI_EKONOMICZNE.md` — surowe fragmenty źródłowe w
`docs/ZRODLA_C64_WIKI.md`.

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
**Zaimplementowane jako dwa osobne ekrany**, nie jeden: Hub (`scenes/hub`) pokazuje
tło aktualnego miasta + pasek stanu + menu nawigacyjne, a klikalna mapa świata z
pinezkami żyje na osobnym ekranie (`scenes/travel_map`), otwieranym przyciskiem
"Jedź »" — z animowanym przejściem zoom-in/zoom-out między nimi
(`scenes/travel_animation`), żeby zachować ciągłość wizualną pinezki aktualnego
miasta. Mapa obejmuje **ok. 18 lokacji** (12 miast plantacyjnych + Nowy Jork + 5
miast aukcyjnych w Europie) — pełna lista i czasy podróży w
`docs/MECHANIKI_EKONOMICZNE.md`. Podróż między lokacjami zajmuje dni gry i
jest wizualizowana (patrz 4.9), nie jest natychmiastowym przeskokiem.

Pasek stanu Huba to dwie skrzynki w przeciwległych górnych rogach (nie jeden
pasek): lewa — imię gracza + lokalizacja (lub trasa w trakcie podróży), data w
grze, licznik posiadanych obrazów (np. "7/40") i termin najbliższej aukcji;
prawa — gotówka, plus ostrzegawcza etykieta, gdy zbliża się reforma walutowa
(patrz 4.3.1).

Menu nawigacyjne Huba jest dwupoziomowe: górny poziom to tylko "Jedź »",
"Miejsca »", "Koniec tury »" i "Zapisz i wyjdź do menu"; przycisk "Miejsca »"
otwiera podmenu z ekranami zależnymi od typu miasta (Plantacje, **Spichlerz** —
patrz 4.2.1, Dom aukcyjny, Galeria i Szkoła sztuki tylko w miastach
aukcyjnych; Giełda i Rynek w Nowym Jorku i miastach aukcyjnych — zgłoszone
przez użytkownika, bez sensu byłoby handlować akcjami na plantacji) i
zawsze dostępnym (Wyścigi), z przyciskiem "« Powrót". Ten dwupoziomowy układ zastąpił jedną, długą,
przewijaną listę — przewijanie dotykiem na telefonie okazało się niewiarygodne.

### 4.2 Plantacje
Widok siatkowy (grid) **16×16 pól** pojedynczej plantacji, płaski od góry (nie
izometryczny), z rzeką przebiegającą przez pole jako losowo wygenerowana,
wijąca się ścieżka (błądzenie losowe kolumnami, inna przy każdym założeniu
plantacji) — **pola przylegające do rzeki dają ×2 plonu** (patrz
`MECHANIKI_EKONOMICZNE.md` pkt. 3–4), co zachęca do zwartego, przemyślanego
układania upraw zamiast maksymalizowania powierzchni. Każde pole to natywnie
rysowana ikonka (rzeka/dzika ziemia do kupienia/zaorana ziemia/roślinka w
kolorze zależnym od uprawy), nie tekst czy zewnętrzna grafika. Mechaniki:
wybór uprawy (kawa/tytoń/herbata/kakao — profil plonu zależny od lokalizacji
i **pory roku**, tabela sezonowej wydajności w `MECHANIKI_EKONOMICZNE.md`),
zatrudnianie robotników (plon skaluje się liniowo z ich liczbą), zbiory i
wysyłka towaru do magazynu (Nowy Jork).

✅ **Ryzyko regionalne — zaimplementowane** (`PlayerPlantations._apply_crisis_hit`,
`Cities.REGION_UNREST_CHANCE_PER_WEEK`): strajk (brak wypłat robotnikom —
gotówka na minusie PRZY zatrudnionej załodze) i zamieszki (losowane co
tydzień wg niestabilności regionu — dziś Afryka i postimperialna Azja, reszta
świata bez ryzyka) mają te same konsekwencje: zabrane zapasy z magazynu tej
plantacji + ucieczka połowy załogi. Jeden wspólny licznik uderzeń na
plantację (niezależnie od przyczyny) — po 3 uderzeniach kolejne zabiera CAŁĄ
plantację. Zgłaszane jako karta gazety między turami (patrz 4.3 niżej,
`WorldEvents.gd`).

⏳ **Zaplanowane, jeszcze niezaimplementowane:** animacja wzrostu upraw
(etapy graficzne: zasiew → wzrost → zbiory) — na razie zbiory liczą się
natychmiast po upływie czasu, bez animowanych faz.

### 4.2.1 Spichlerz
Osobny ekran (dostępny tak jak Plantacje, tylko w miastach typu plantacyjnego)
pokazujący zbiorczy stan magazynów **ze wszystkich plantacji gracza naraz**,
po jednym "silosie" na uprawę (kawa/tytoń/herbata/kakao) z wizualnym poziomem
wypełnienia, aktualną ceną rynkową i przyciskiem "Wyślij i sprzedaj" — sprzedaje
od razu cały zapas danej uprawy ze wszystkich plantacji, każdą partię z jej
własnym kosztem transportu zależnym od miasta pochodzenia.

### 4.3 Giełda
Ekran z listą **4 fikcyjnych linii żeglugowych** — Lloyd (Azja), Star (Afryka),
Hanse (Ameryka Płd.), Royal (Ameryka Płn.) — i przyciskami kupna/sprzedaży
akcji. Kurs każdej spółki realnie rośnie wraz z aktywnością gracza na
plantacjach w danym regionie, co spina giełdę z plantacjami w jeden system
zamiast dwóch osobnych minigier (szczegóły: `MECHANIKI_EKONOMICZNE.md` pkt. 7).
Pod listą spółek: wykres kursu w czasie (jedna linia na spółkę, natywnie
rysowany, `scripts/ui/PriceChart.gd`) z legendą kolor+nazwa.

Zgłoszone przez użytkownika: ceny towarów i kontrakty terminowe, wcześniej
druga część tego samego ekranu, mają teraz **osobny ekran — Rynek** (patrz
4.3a), dostępny z Huba obok Giełdy.

✅ **Karta zdarzenia dla reformy walutowej — zaimplementowana** (`WorldEvents.gd`,
`scenes/world_event/WorldEventCard.gd`): reforma (patrz 4.3.1 niżej) trafiała
dotąd jako cicha zmiana liczbowa z jedną etykietą ostrzegawczą w Hubie —
teraz zamiast/obok tego pokazuje się pełnoekranowa "karta gazety" MIĘDZY
TURAMI (Hub sprawdza kolejkę WorldEvents PRZED zbudowaniem normalnego
widoku, ten sam wzorzec co Podsumowanie roku). Ta sama karta pokazuje też
kryzysy na plantacjach (patrz 4.2 wyżej). Ilustracja nagłówka gazety po
cichu spada na tło Giełdy, dopóki `events/reform.jpg` nie zostanie wgrane
(prompt w `docs/GRAFIKA_LEONARDO.md` §4).

⏳ **Zaplanowane, jeszcze niezaimplementowane:** krach giełdowy (np. krach
1929) i hiperinflacja jako osobne, nowe typy zdarzeń (nie tylko oprawa
istniejącej reformy) — prompty na te dwie dodatkowe karty ("Krach"/"Hossa")
już czekają gotowe w `docs/GRAFIKA_LEONARDO.md` §4, ale bez własnej
mechaniki w kodzie.

### 4.3a Rynek
Osobny ekran (wydzielony z dawnej Giełdy) z cenami towarów (kawa/tytoń/
herbata/kakao) i własnym wykresem cen w czasie (jedna linia na towar,
`scripts/ui/PriceChart.gd`, ten sam wzorzec co na Giełdzie).

**Kontrakty terminowe (forward contracts):** osobna zakładka Rynku — gracz
zobowiązuje się dostarczyć określoną ilość towaru w przyszłości po ustalonej
dziś cenie. Cena nie zmienia się nawet po reformie walutowej, co czyni je
kluczowym narzędziem zabezpieczenia (i ryzykownej spekulacji) wokół
nadchodzących reform (patrz 4.3.1 niżej i `MECHANIKI_EKONOMICZNE.md` pkt. 5–6).

### 4.3.1 Reformy walutowe
Okresowe, historycznie umotywowane reformy walutowe (np. przelicznik 5:1)
gwałtownie tną gotówkę graczy — z wyraźnym sygnałem ostrzegawczym w UI (np.
rosnący kurs dolara). Doświadczeni gracze mogą się zabezpieczyć kontraktami
terminowymi zawartymi tuż przed reformą.

### 4.4 Tor wyścigów konnych
Prosty ekran zakładów: lista koni z kursami, animowana scena wyścigu (można
zacząć od uproszczonej animacji 2D — sylwetki koni przesuwające się po torze),
wynik i wypłata.

### 4.5 Dom aukcyjny
Najbardziej "grafozależny" ekran. Prezentacja obrazu (w pełnej krasie, na
sztaludze) i licytacja w czasie rzeczywistym z paskiem czasu (limit 20 s na
rundę) i konkurencyjnymi ofertami **3 rywali AI** (nie ~7 — patrz niżej).
⏳ **Zaplanowane, jeszcze niezaimplementowane:** opcja wysłania pośrednika
zamiast osobistej licytacji.

Aukcje odbywają się wg **stałego harmonogramu** (jedno miasto + jeden dzień na
raz, losowany z wyprzedzeniem 4–12 dni), widocznego w Hubie jako "Następna
aukcja: ...". Jeśli gracz przesiedzi termin, harmonogram sam się przesuwa po
kilku dniach zwłoki zamiast pokazywać nieaktualną datę; "Koniec tury" w
mieście aukcyjnym zatrzymuje się dokładnie na dniu aukcji zamiast go
przeskakiwać.

Wśród licytujących zawsze bierze udział **Vico** — nazwany rywal-fałszerz,
zawsze pod tym samym imieniem, ale z portretem losowanym przy każdej nowej
grze z 3 gotowych wariantów (ten sam charakter, inne ujęcie), agresywniejszym
i bardziej nieprzewidywalnym stylem licytacji niż pozostałych dwóch
(generycznych) rywali AI. Pozostali dwaj rywale dostają **losowo, przy każdej
nowej grze**, imię i portret z puli 6 gotowych wariantów (2 płcie × 3 dodatki
— cylinder/monokl/boa z piór, patrz `docs/GRAFIKA_LEONARDO.md` §6), zamiast
statycznych "Rywal II"/"Rywal III" — imię i portret zawsze pochodzą z tego
samego wariantu.

**System autentykacji (na bazie mechaniki oryginału):** każdy z 40 obrazów ma
unikalny numer katalogowy w obrębie swojej kategorii stylistycznej. Jeśli
gracz kupi/skataloguje obraz o numerze, który już posiada — zostaje on
**automatycznie ujawniony jako fałszywka** (pieniądze przepadają, obraz nie
trafia do kolekcji). To główny, "systemowy" mechanizm wykrywania podróbek.
Szkoła sztuki (patrz 4.6) nie zastępuje tego systemu, tylko go wspiera —
podnosi szansę, że gra *ostrzeże* gracza przed zakupem podejrzanego obrazu na
aukcji, zanim ten padnie ofiarą duplikatu. Niezależnie od tego ostrzeżenia,
część obrazów (rosnąca z czasem pula, patrz `docs/GRAFIKA_LEONARDO.md` §7) ma
**dedykowaną, wizualnie subtelnie inną grafikę podróbki** — więc uważny gracz
może czasem rozpoznać fałszywkę "na oko", nawet bez ostrzeżenia z ekspertyzy.

### 4.6 Szkoła sztuki / autentykacja
Kurs (koszt + czas trwania) podnoszący statystykę "eksperckość" o stały
przyrost — zwiększa szansę na wczesne ostrzeżenie o duplikacie numeru
katalogowego (patrz 4.5) przed przybiciem młotka na aukcji. Ważne: podnosi
tylko szansę na *ostrzeżenie*, NIE dokładność szacowanej wartości obrazu —
to częsta pomyłka testerów, więc ekran wprost tłumaczy tę różnicę.
✅ **Zrobione i podpięte:** kurs to teraz mini-gra "znajdź podróbkę" —
`ArtSchool.gd::_start_quiz` losuje numer katalogowy z dedykowanym wariantem
grafiki podróbki (`Paintings.get_numbers_with_fake_variant()`, na razie 10 z
40) i pokazuje oba obrazy obok siebie w losowej kolejności; gracz wskazuje,
który to fałszywka. Trafna odpowiedź daje więcej eksperckości
(`EXPERTISE_GAIN_CORRECT`, 15%) niż nietrafiona (`EXPERTISE_GAIN_WRONG`, 5%)
— uczy realnie patrzeć na obraz, zamiast dawać eksperckość za sam fakt
kliknięcia przycisku kursu.

### 4.7 Galeria / kolekcja
Ekran-nagroda: wirtualna galeria z **8 sekcjami stylistycznymi** (Vermeer,
Barok, Klasycyzm, Romantyzm, Impresjonizm, Symbolizm, Ekspresjonizm, Moderna),
po 5 slotów na obraz każda — układ gabloty/ściany tematycznej, nie płaska
lista 40. Zdobyty i skatalogowany obraz **zostaje przypisany do gracza na
stałe w statystykach kolekcji**, nawet jeśli fizycznie zmieni właściciela w
dalszej rozgrywce (tak jak w oryginale — katalogowanie jest nieodwracalne).
Im więcej wypełnionych sekcji, tym bardziej "żywa" galeria — ✅ **oświetlenie
i głośność muzyki w tle już reagują na wypełnienie** (`Gallery.gd`: nakładka
na tło przechodzi od ciemnej/chłodnej przy pustej kolekcji do ciepłej/złotej
przy pełnej, `Music.set_volume_offset` podbija głośność proporcjonalnie do
`owned_count()/win_threshold`; w pełni skompletowana kategoria 5/5 podświetla
się na złoto). ⏳ **Wciąż niezaimplementowane:** fizyczny układ
gabloty/ściany tematycznej zamiast płaskiej listy etykiet X/5 na kategorię.

Ten sam ekran hostuje też system **Ochrony/kradzieży**: gracz może zatrudnić
ochroniarza (stały koszt, chroni przed okradzeniem) i wysłać "gangstera"
przeciwko wybranemu rywalowi (ryzykowna próba osłabienia jego kolekcji) —
patrz `docs/DODATKOWE_MECHANIKI.md`.

### 4.8 Noworoczna Loteria (Neujahrstombola)
Coroczne wydarzenie, osobne od aukcji i giełdy — losowanie/loteria na przełomie
roku w grze, dodatkowe źródło pieniędzy lub nawet obrazu-niespodzianki. Dobry
moment na krótką, satysfakcjonującą animację (fajerwerki, konfetti, kalendarz
przewracający rok).

### 4.9 Podróże między lokacjami
Przemieszczanie się między ~18 miastami na mapie świata (lista i czasy
podróży: `MECHANIKI_EKONOMICZNE.md` pkt. 2) nie jest natychmiastowe — zajmuje
od ok. 1,5 dnia (np. Paryż–Berlin) do ponad 30 dni (np. Colombo–Nowy Jork) i
jest wizualizowane (płynący statek/pociąg po trasie na mapie). Miasta bliżej
Europy/Ameryki są wygodniejsze, ale odległe (Ankara, Afryka, Azja) bywają
bardziej opłacalne pod konkretne uprawy — naturalny gradient trudności
geograficznej. Dobry haczyk na decyzje ekonomiczne ("czy warto lecieć
osobiście na aukcję, czy wysłać pośrednika?").

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
**15/40 na łatwym poziomie**, `Paintings.EASY_WIN_THRESHOLD`, przełącznik przy
zakładaniu nowej gry). Porażka: bankructwo (**ujemny kapitał przez 60 kolejnych
dni gry**, `Economy.BANKRUPTCY_THRESHOLD_DAYS`) lub rywal komplementuje
kolekcję pierwszy.

## 7. Sterowanie i UX (mobile)

- Wyłącznie dotyk: tap/drag, brak zależności od fizycznych przycisków.
- Duże, czytelne elementy UI (target dla ekranów 5–7").
- Krótkie sesje: zapis ręczny (przycisk "Zapisz i wyjdź do menu"), nie
  automatyczny autosave co turę.
- **Interfejs trójjęzyczny: polski (język źródłowy) / angielski / niemiecki**,
  przełączany w ekranie Ustawień (dostępnym z menu głównego, obok "Nowa
  gra"/"Wczytaj grę") — `Localization.gd` + `translations/ui.csv`, wybór
  języka zapisywany trwale między sesjami.
- ⏳ **Zaplanowane, jeszcze niezaimplementowane:** powiadomienia push
  ("Aukcja za 2 dni", "Twoje plantacje gotowe do zbioru").

## 8. Stos technologiczny

**Silnik: Godot 4 (GDScript)**
- Natywny eksport na Android, brak opłat licencyjnych, lekki APK.
- Dobry do gier 2D/UI-heavy (dokładnie taki typ, co Vermeer).
- Architektura: autoloady na stan gry (Economy, Calendar, Paintings, AIPlayers),
  osobne sceny na każdy ekran z pkt. 4, wspólny UI-theme (art déco).

Struktura katalogów (szkielet już utworzony w `game/`, patrz `game/README.md`):
```
game/project.godot
game/scenes
  /main_menu, /hub, /travel_map, /travel_animation, /plantation, /warehouse,
  /stock_market, /market, /races, /auction_house, /art_school, /gallery, /ending,
  /settings  — każdy: Scene.tscn + Scene.gd
game/scripts
  /autoload  (SceneRouter, Calendar, Cities, Travel, Crops, Economy,
              PlayerPlantations, Paintings, Auctions, ShippingCompanies,
              ForwardContracts, AIPlayers, Security, Players, GameState,
              SaveGame, Localization, Music)
  /ui  (screen_helpers.gd — wspólne budowniczowie UI; MapPin.gd, MenuFrame.gd,
        VaultIcon.gd, TravelVehicle.gd, PlantationTileIcon.gd — natywnie
        rysowane ikonki tam, gdzie Leonardo.ai uparcie generowało pełne sceny
        zamiast wyizolowanych ikon)
game/art        — grafiki z Leonardo.ai (docs/GRAFIKA_LEONARDO.md), większość
                  teł/obrazów już podpięta — status w tabeli "Plan produkcji"
  /ui, /characters, /paintings, /backgrounds, /icons
game/audio      — /music, /sfx (oba na razie puste, katalogi już założone) —
                  prompty na muzykę gotowe w docs/MUZYKA_PROMPTY.md
```

Autoloady mają wpięte realne dane źródłowe (miasta i czasy podróży, plony
upraw, koszty transportu, katalog 40 obrazów, linie żeglugowe) oraz działającą
logikę wszystkich mechanik z sekcji 4 (plantacje, giełda, aukcje z
harmonogramem, kontrakty terminowe, ochrona/kradzieże, hot-seat multiplayer,
zapis/odczyt, lokalizacja) — większość ekranów ma już podpiętą docelową
grafikę teł (patrz `docs/GRAFIKA_LEONARDO.md`), zamiast czysto tekstowych
placeholderów z wcześniejszych etapów projektu.

## 9. Kierunek artystyczny

**Styl: Art Déco lat 20., ciepła paleta (sepia, złoto, głęboka zieleń, burgund,
turkus jako akcent), płaskie ilustracje z lekką teksturą papieru/gwaszu** —
spójne z epoką i tematem sztuki/kolekcjonerstwa. Unikać realistycznego 3D —
stylizowana ilustracja 2D będzie szybsza do wygenerowania spójnie i lżejsza na
mobile.

## 10. Etapy budowy (proponowana kolejność) — status

1. ✅ GDD (ten dokument)
2. ✅ Szkielet projektu Godot + nawigacja między ekranami (`SceneRouter.gd`)
3. ✅ Systemy danych (wszystkie autoloady z sekcji 8, z działającą logiką, nie
   tylko surowymi danymi) + zestaw testów regresyjnych (`game/tests/`,
   uruchamiany automatycznie w CI, patrz `.github/workflows/godot-check.yml`)
4. ✅ Hub + osobny ekran Mapy świata (`travel_map`) + animacja podróży
   (`travel_animation`) — w pełni zaimplementowane i podpięte grafiką
5. ✅ Wszystkie ekrany z sekcji 4 zaimplementowane i grywalne: Plantacje +
   Spichlerz, Giełda, Rynek, Wyścigi, Dom aukcyjny, Szkoła sztuki, Galeria (+
   Ochrona), Ustawienia (język) — większość ma podpiętą docelową grafikę tła
   (`docs/GRAFIKA_LEONARDO.md`); pozostałe braki oznaczone ⏳ przy
   poszczególnych mechanikach w sekcji 4 (karty zdarzeń makro, animacja
   wzrostu upraw, mini-gra autentykacji, ryzyko regionalne na plantacjach,
   powiadomienia push)
6. ⏳ Dźwięk/muzyka, dalszy polish, testy na urządzeniu — częściowo w toku
   (build Android już działa, patrz punkt 7). Pierwszy utwór (`hub.mp3`)
   już podpięty jako wspólna muzyka w tle na WSZYSTKICH ekranach
   (`Music.gd` autoload, gra w pętli) — placeholder do czasu, aż powstaną
   osobne ścieżki per ekran z `docs/MUZYKA_PROMPTY.md`.
7. ✅ Eksport APK działa (`android-build.yml`, debug keystore) — podpisywanie
   pod Google Play i AAB wciąż do zrobienia

## 11. Pytania projektowe — rozstrzygnięte

Sekcja historycznie nazywała się "otwarte pytania"; wszystkie cztery poniższe
zostały już rozstrzygnięte i zaimplementowane, zapisane tu jako notatka o
przyjętym rozwiązaniu (nie żeby je ponownie rozważać):

- **Multiplayer:** hot-seat pass-and-play (do 4 graczy na jednym telefonie)
  **jest zaimplementowany** (`Players.gd`). Uproszczenie świadomie przyjęte:
  zamiast symulować wszystkich graczy równolegle, gra **przełącza, kto jest
  aktywny** — autoloady ekonomiczne (Economy, Travel, PlayerPlantations,
  Paintings...) zawsze reprezentują aktualnie grającego, a stan pozostałych
  graczy leży w snapshotach między ich turami. Efekty zależne od upływu czasu
  (płace, dług, kontrakty) naliczają się tylko przy końcu czyjejś tury, nie
  "jednocześnie" dla wszystkich w tle.
- **Vico jako antagonista:** zaimplementowany jako jeden z 3 rywali AI
  (`AIPlayers.rivals`), oznaczony `is_named_rival = true`, z bardziej
  agresywnym/nieprzewidywalnym stylem licytacji niż pozostałych dwóch
  (szerszy zakres mnożnika ofert) — patrz `MECHANIKI_EKONOMICZNE.md` pkt. 9
  po pełny profil fabularny.
- **Struktura tur:** przyjęto uproszczony model z globalnym kalendarzem dni —
  jedna tura = 7 dni gry (`Players.DAYS_PER_TURN`), z wyjątkiem sytuacji, gdy
  gracz stoi w mieście z zaplanowaną aukcją w tym oknie: wtedy tura skraca się
  tak, by wylądować dokładnie na dniu aukcji (`Auctions.cap_turn_advance`),
  zamiast ją przeskoczyć. Pełny event-driven scheduler pozostaje możliwym
  rozszerzeniem, ale nie jest planowany na najbliższy etap.
- **Balans ekonomiczny:** rentowność upraw została świadomie spłaszczona —
  wszystkie 4 uprawy startują z tą samą bazową ceną rynkową
  (`Crops.BASE_CROP_PRICE`), zamiast kopiować historyczny przechył na korzyść
  tytoniu z oryginału.
