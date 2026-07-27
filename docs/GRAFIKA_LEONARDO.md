# Plan grafik — generowanie w Leonardo.ai

Dokument roboczy: lista wszystkich assetów graficznych potrzebnych do gry oraz
gotowe prompty pod Leonardo.ai, tak by wszystko trzymało spójny styl.

## Ustawienia techniczne w Leonardo.ai

Nazwy modeli w Leonardo zmieniają się dość często, więc zamiast sztywno
wskazywać jeden model, szukaj takiego, który pasuje do poniższego opisu (w
razie wątpliwości dobrym punktem startu są modele typu "Phoenix" lub inne
opisane jako dobre do stylizowanej ilustracji/concept-artu):

- **Typ modelu:** stylizowana ilustracja / concept art / "flat illustration" —
  **nie** fotorealizm, **nie** anime, **nie** 3D render.
- **PhotoReal:** wyłączony (chcemy płaską ilustrację, nie zdjęcie).
- **Alchemy:** włączony, jeśli dostępny — zwykle poprawia spójność kompozycji
  i nasycenie kolorów przy stylizowanych promptach.
- **Preset stylu (jeśli model go oferuje):** "Illustration" / "Concept Art" /
  "Graphic Design Art" — unikać presetów "Cinematic", "Photography", "3D".
- **Liczba generacji na prompt:** 4 na raz — wybierz najlepszą, dopiero ją
  upscaluj (oszczędza kredyty/tokeny względem upscalowania wszystkiego).
- **Upscaling:** finalnie wybrany obraz przepuść przez "Universal Upscaler"
  (albo odpowiednik) do docelowej rozdzielczości z sekcji "Format eksportu"
  na końcu dokumentu.

### Negative prompt (wklej do pola "Negative Prompt" przy KAŻDYM promencie)

```
blurry, low quality, photorealistic photo, modern smartphone, modern clothing,
contemporary fashion, text, watermark, signature, logo, extra fingers,
deformed hands, cropped, oversaturated, 3D render, video game HUD, UI overlay,
photo, realistic skin texture
```

### Workflow zachowania spójności między generacjami

1. Wygeneruj **1 obraz referencyjny** (najlepiej ekran tytułowy/logo, punkt 1
   niżej) bez żadnej referencji stylu — to on ustala paletę i kreskę.
2. Dodaj go jako **Style Reference / Image Guidance** (w zależności od wersji
   UI Leonardo bywa to nazwane "Elements" albo "Image Guidance → Style
   Reference") przy wadze ok. **30–50%** dla wszystkich kolejnych generacji.
3. Dla **wariantów tego samego obiektu** (np. 3 fazy wzrostu tej samej
   rośliny, 3 wyrazy twarzy Vico) używaj trybu **Image-to-Image** na bazie
   poprzedniego wariantu z niskim **Strength ~20–35%**, zamiast generować od
   zera — dużo lepsza spójność kształtu/koloru.
4. Dla ikon/sprite'ów z przezroczystym tłem: generuj na jednolitym,
   kontrastowym tle (czysta zieleń albo magenta) i usuń tło narzędziem
   "Remove Background" (Leonardo ma wbudowane, ewentualnie remove.bg).
5. Trzymaj się **jednego aspect ratio na kategorię assetu** (patrz tabela w
   sekcji "Plan produkcji" na końcu) — łatwiej potem poskładać w silniku.

## Spójność stylu — najważniejsza zasada

Leonardo.ai generuje różne obrazy za każdym razem, więc żeby cała gra nie
wyglądała jak zbiór przypadkowych grafik:

1. **Zdefiniuj jeden "kotwiczący" prompt stylu** (patrz niżej: *Base style
   tag*) — w tym dokumencie każdy gotowy prompt ma go już doklejonego na
   końcu, więc kopiujesz tylko jeden blok kodu, nic nie trzeba doklejać
   ręcznie z innego miejsca.
2. Użyj tego samego **modelu** przez cały projekt (polecane: Leonardo Phoenix
   lub Leonardo Anime XL / PhotoReal — do ilustracji 2D najlepiej sprawdzi się
   model nastawiony na "illustration"/"concept art", nie fotorealizm).
3. Włącz **"Image Guidance" / "Style Reference"** — wygeneruj 1 obraz-wzorzec
   (np. plakat gry) i podawaj go jako referencję stylu przy kolejnych
   generacjach, żeby paleta barw i kreska się nie rozjeżdżały.
4. Trzymaj stały **seed** przy wariantach tego samego assetu (np. 3 warianty
   tego samego pola uprawnego w różnych fazach wzrostu).
5. Do ikon/UI z przezroczystym tłem używaj trybu z alpha channel (Leonardo ma
   opcję "transparent background" / PNG z usuniętym tłem) albo generuj na
   jednolitym tle i usuwaj je narzędziem do usuwania tła.

### Base style tag (już doklejony na końcu każdego gotowego promptu niżej — ta sekcja to tylko podgląd, do czego wraca każdy prompt w dokumencie)

```
Art Deco 1920s illustration style, warm sepia and gold palette with deep
green, burgundy and turquoise accents, flat vector-gouache texture, subtle
paper grain, elegant geometric ornamentation, mobile game asset, clean
silhouette, no photorealism
```

## Lista assetów wg ekranu

### 1. Ekran startowy / tło menu głównego
Zgłoszone przez użytkownika: gra zmieniła tytuł na **"The Forger: Retro
Tycoon"** (wcześniej *Vermeer*, po tytule oryginału z 1987) — powód: niepewny
status nazwy "Vermeer" jako marki. Katalog obrazów i kategoria "vermeer"
(prawdziwy malarz Jan Vermeer) **zostają bez zmian** — to osobna sprawa od
tytułu gry.

✅ **Tytuł wpisany bezpośrednio w tło — zaimplementowane** (`MainMenu.gd`):
zgłoszone przez użytkownika — zamiast dwóch osobnych obrazów (pełnoekranowe
tło + osobno dogrywana grafika logo na wierzchu), `main_menu_title.jpg`
teraz SAM ma zawierać duży napis "THE FORGER: RETRO TYCOON" u góry. Dawne
`logo.jpg` (kinowa scena z kurtynami i wypukłym napisem, oddzielnie
kompozytowana w kodzie) i cała logika `_build_logo` (limit 1/3 wysokości
ekranu, wyliczanie rozmiaru z opóźnieniem o dwie klatki) zostały usunięte —
`logo.jpg` nie jest już używane nigdzie w kodzie, plik można zostawić w
repo jako martwy zasób albo usunąć.
- Opcjonalny motyw (nadal aktualny, niezależnie od zmiany tytułu): własna,
  stylizowana reinterpretacja "Dziewczyny z perłą" Jana Vermeera (obraz z
  ok. 1665, domena publiczna) — subtelne mrugnięcie do oryginalnej gry,
  która miała podobny motyw na ekranie tytułowym. To ma być **inspirowana
  reinterpretacja w naszym stylu art déco**, nie kopia obrazu.

**Prompt (`main_menu_title.jpg`, regeneracja z tytułem wpisanym w tło)** —
scena zachowuje dotychczasowy motyw (gabinet kolekcjonera z mapami świata na
ścianach, kompas, globus, sylwetka miasta u dołu), z dużym, pogrubionym
napisem tytułu u góry. TA SAMA zasada co przy kartach wydarzeń
(docs/GRAFIKA_LEONARDO.md §4): krótki tytuł w cudzysłowie, nie opisowe
zdanie — modele obrazkowe renderują krótkie hasła dużo wierniej. **Usuń
"text, watermark, signature, logo" ze standardowego Negative Prompt TYLKO
dla tego jednego promptu** (patrz sekcja "Negative prompt" na górze
dokumentu) — inaczej model będzie aktywnie unikać rysowania tytułu, którego
tu właśnie chcemy.

Poprawka #1 (zgłoszenie użytkownika, patrz zrzuty ekranu): "spanning the
full width across the top"/"touching the top border" model dalej
potraktował zbyt swobodnie — tytuł i tak wychodził wyśrodkowany pionowo w
środku kadru, z mapami i NAD, i POD nim. Opisowe/przymiotnikowe instrukcje
pozycji ("at the top", "not centered") okazały się za słabe.

Poprawka #2 — zamiast opisywać SCENĘ i osobno DOKLEJAĆ do niej pozycję
tytułu, prompt teraz opisuje kompozycję jako DWA WYRAŹNIE ROZDZIELONE
PASY (skuteczniejszy trik dla modeli obrazkowych niż same przymiotniki
pozycji): górny pas to OSOBNY, jednolity baner na całą szerokość, dolny
pas to scena. Modelowi dużo łatwiej utrzymać podział na dwa bloki niż
"dopilnować", żeby jeden element sceny wylądował akurat przy krawędzi:
```
Widescreen game title card split into two horizontal bands. TOP BAND (top 20% of the image, full width): a solid dark green banner strip stretching edge to edge, containing large bold gold Art Deco lettering reading "THE FORGER: RETRO TYCOON", the banner's top edge touches the very top border of the image with zero margin above it. BOTTOM BAND (remaining 80% of the image, below the banner): a 1920s art collector's study, world maps on the walls, a brass compass and a globe in the corner, a city skyline silhouette along the bottom edge. Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Prompt logo.jpg (nieużywane, zapis historyczny — patrz wyżej, dlaczego
zrezygnowano):**
```
Art Deco game logo title screen, elegant gold typography reading "THE FORGER: RETRO TYCOON",
1920s art collector silhouette standing before an easel, world map background,
Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

### 2. Mapa świata (Hub)
- Stylizowana mapa świata jako plansza gry, z oznaczonymi lokacjami (plantacje,
  Nowy Jork, Londyn, tor wyścigowy, dom aukcyjny, szkoła sztuki)
- Osobne ikony-pinezki dla każdej lokacji

**Prompt (tło mapy):**
```
Stylized vintage world map game board, Art Deco cartography, sepia ocean,
gold coastlines, decorative compass rose, empty pins slots for cities,
top-down board game map, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```
**Prompt (ikony pinezek) — ⚠ NIE GENERUJ:** patrz Plan produkcji niżej,
wiersz 5 — pinezki są już rozwiązane natywnie w kodzie (`MapPin.gd`),
Leonardo uparcie robiło pełne sceny zamiast wyizolowanych ikon. Zostawione
tu tylko jako zapis, dlaczego zrezygnowaliśmy z tego assetu.

### 2.1 Tła miast (lokacje na mapie — ~18 sztuk, patrz `MECHANIKI_EKONOMICZNE.md`)

18 unikalnych, w pełni bespoke teł miast to dużo pracy ręcznej w Leonardo —
rozsądniej **wygenerować 5 tematycznych szablonów regionalnych** i tylko
lekko wariantować per miasto (inny akcent koloru/rekwizyt), zamiast 18 zupełnie
osobnych scen od zera:

1. **Port tropikalny — Ameryka** (Rio, Bogota, Gwatemala, Meksyk)
2. **Port zachodnioafrykański** (Abidżan, Duala, Mombasa)
3. **Port południowo/wschodnioazjatycki** (Bombaj, Colombo, Ankara jako
   pomost Europa/Azja)
4. **Amerykańskie miasteczko śródlądowe** (Richmond, St. Louis)
5. **Europejska stolica** (Londyn, Lizbona, Amsterdam, Paryż, Berlin, Nowy Jork
   jako wariant "wielka metropolia")

**Prompty (5 szablonów regionalnych, gotowe do wklejenia — po jednym na
region z listy wyżej):**

**1. Port tropikalny — Ameryka**
```
1920s tropical Latin American port town, establishing shot game background, warm afternoon light, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**2. Port zachodnioafrykański**
```
1920s West African colonial port, establishing shot game background, warm afternoon light, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**3. Port południowo/wschodnioazjatycki**
```
1920s South Asian trading port, establishing shot game background, warm afternoon light, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**4. Amerykańskie miasteczko śródlądowe**
```
1920s American heartland riverside town, establishing shot game background, warm afternoon light, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**5. Europejska stolica**
```
1920s grand European capital street, establishing shot game background, warm afternoon light, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

### 2.2 Tła miast — unikalne per miasto (zastępuje §2.1)

Mimo przewidywanego dużego nakładu pracy, ostatecznie wygenerowano **osobne,
w pełni unikalne tło dla każdego z 18 miast** zamiast 5 współdzielonych
szablonów regionalnych — każde z rozpoznawalnym, charakterystycznym
zabytkiem/motywem: Big Ben (Londyn), wieża Eiffla (Paryż), Brama
Brandenburska (Berlin), kanały (Amsterdam), tramwaj i katedra (Lizbona),
Kocatepe Mosque (Ankara), Statua Wolności (Nowy Jork), Chrystus Odkupiciel
(Rio), piramida aztecka (Meksyk), wulkan (Gwatemala), itd. `Cities.gd`
`CITY_BACKGROUNDS` mapuje każde miasto na plik w `game/art/backgrounds/`
(`city_<id>.jpg`) i ma pierwszeństwo przed `REGION_BACKGROUNDS` z §2.1 —
te zostają jako czysty fallback, gdyby kiedyś doszło nowe miasto bez
własnej grafiki.

| Miasto | Plik |
|---|---|
| Berlin | `city_berlin.jpg` |
| Paryż | `city_paris.jpg` |
| Amsterdam | `city_amsterdam.jpg` |
| Lizbona | `city_lisbon.jpg` |
| Londyn | `city_london.jpg` |
| Ankara | `city_ankara.jpg` |
| Bombaj | `city_bombay.jpg` |
| Colombo | `city_colombo.jpg` |
| Mombasa | `city_mombasa.jpg` |
| Duala | `city_duala.jpg` |
| Abidżan | `city_abidjan.jpg` |
| Rio de Janeiro | `city_rio.jpg` |
| Bogota | `city_bogota.jpg` |
| Gwatemala | `city_guatemala.jpg` |
| Meksyk | `city_mexico.jpg` |
| Nowy Jork | `city_new_york.jpg` |
| Richmond | `city_richmond.jpg` |
| St. Louis | `city_st_louis.jpg` |

### 3. Plantacje
- Tło plantacji (pola uprawne, rzut izometryczny/z góry)
- 3 fazy wzrostu rośliny (kawa, tytoń, herbata, kakao) — po 3 grafiki na
  roślinę (zasiew, wzrost, zbiory)
- Ikony narzędzi/robotników

**Prompt (tło):**
```
Isometric plantation field background, 1920s tropical farmland, rows of crops,
small worker huts, warm afternoon light, game background art,
Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```
**Prompty (12 = 4 uprawy × 3 fazy wzrostu, gotowe do wklejenia):**

**Kawa — zasiew**
```
Coffee plant, seedling stage, isolated game sprite, simple flat illustration, transparent background, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Kawa — wzrost**
```
Coffee plant, growing stage, isolated game sprite, simple flat illustration, transparent background, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Kawa — zbiory**
```
Coffee plant, ready to harvest stage, isolated game sprite, simple flat illustration, transparent background, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Tytoń — zasiew**
```
Tobacco plant, seedling stage, isolated game sprite, simple flat illustration, transparent background, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Tytoń — wzrost**
```
Tobacco plant, growing stage, isolated game sprite, simple flat illustration, transparent background, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Tytoń — zbiory**
```
Tobacco plant, ready to harvest stage, isolated game sprite, simple flat illustration, transparent background, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Herbata — zasiew**
```
Tea plant, seedling stage, isolated game sprite, simple flat illustration, transparent background, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Herbata — wzrost**
```
Tea plant, growing stage, isolated game sprite, simple flat illustration, transparent background, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Herbata — zbiory**
```
Tea plant, ready to harvest stage, isolated game sprite, simple flat illustration, transparent background, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Kakao — zasiew**
```
Cocoa plant, seedling stage, isolated game sprite, simple flat illustration, transparent background, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Kakao — wzrost**
```
Cocoa plant, growing stage, isolated game sprite, simple flat illustration, transparent background, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Kakao — zbiory**
```
Cocoa plant, ready to harvest stage, isolated game sprite, simple flat illustration, transparent background, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

### 4. Giełda i Rynek
Zgłoszone przez użytkownika: dawny wspólny ekran Giełdy rozdzielony na dwie
osobne plansze — Giełda (akcje linii żeglugowych, `StockMarket.gd`,
tło `stock_market.jpg`) i Rynek (ceny towarów + kontrakty terminowe,
`scenes/market/Market.gd`, własne tło `market.jpg` — dostarczone przez
użytkownika, wygenerowane z promptu niżej).
- Tło: sala giełdy / tablica z kursami
- Ikona wykresu/świec (UI, nie musi być z Leonardo — można zrobić natywnie w
  silniku), ale tło sceny i karty wydarzeń (krach, hossa) tak
- ✅ **Wykres cen w czasie — zrobiony i podpięty, natywnie, bez grafiki**
  (`scripts/ui/PriceChart.gd` — prosty wykres liniowy rysowany przez _draw(),
  ten sam powód co pinezki/sejfy/ramka menu: Leonardo generowałoby pełną
  scenę zamiast czystego wykresu). Osobny wykres na każdym z dwóch ekranów:
  kursy 4 linii żeglugowych w `StockMarket.gd`, ceny 4 towarów w `Market.gd`,
  każdy z historią cen (`ShippingCompanies.price_history`/`Crops.price_history`,
  jeden punkt na każdy skok kalendarza) i legendą kolor+nazwa pod wykresem.

**Prompt (Giełda — tło `stock_market.jpg`):**
```
1920s stock exchange trading floor, Art Deco architecture, chalkboard with
numbers, bustling brokers in background (silhouettes only, no detailed faces),
game background art, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Prompt (Rynek — tło `market.jpg`) — ✅ wygenerowane i podpięte:**
```
1920s commodity trading hall, burlap sacks of coffee beans and cocoa pods, stacked wooden crates of tobacco leaves and tea chests along the walls, large weighing scales, a chalkboard listing crop prices, port warehouse atmosphere, bustling traders and dockworkers in background (silhouettes only, no detailed faces), game background art, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```
**Prompty (karty zdarzeń gospodarczych):** zgłoszone przez użytkownika —
karty wydarzeń "w formie gazety" pokazywane jako popup MIĘDZY TURAMI (patrz
`scenes/world_event/WorldEventCard.gd`, `WorldEvents.gd`). Wszystkie pięć —
reforma walutowa, kryzys na plantacji (strajk/zamieszki, docs/GDD.md pkt.
4.2) i krach/hossa na giełdzie (`ShippingCompanies.apply_market_shock`,
docs/GDD.md pkt. 4.3) — są PODPIĘTE w kodzie i mają wgrane grafiki.

Poprawka promptu (zgłoszenie użytkownika po pierwszych próbach —
za mały tytuł i pusta/geometryczna kompozycja bez żadnego tekstu artykułu):
zamiast opisowego zdania ("headline about...") prompt teraz podaje krótki,
konkretny nagłówek W CUDZYSŁOWIE (2–3 słowa — modele obrazkowe renderują
krótkie hasła dużo wierniej niż całe zdania) i wprost każe narysować go
JAKO OGROMNY, POGRUBIONY tytuł przez całą szerokość strony, a pod nim gęste
kolumny drobnego tekstu — nawet jeśli nieczytelny, ma wyglądać jak
prawdziwa kolumna gazety, nie pusty ornament.

**Reforma walutowa** — `events/reform.jpg`
```
Vintage newspaper front page illustration, huge bold Art Deco masthead headline in capital letters reading "CURRENCY REFORM" spanning the full width of the page, dense columns of small newspaper body text filling the rest of the page below the headline, Art Deco newspaper layout, game event card art, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Strajk (plantacja)** — `events/strike.jpg`
```
Vintage newspaper front page illustration, huge bold Art Deco masthead headline in capital letters reading "WORKERS STRIKE" spanning the full width of the page, dense columns of small newspaper body text filling the rest of the page below the headline, silhouettes of plantation workers marching in protest, Art Deco newspaper layout, game event card art, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Zamieszki (plantacja)** — `events/riot.jpg`
```
Vintage newspaper front page illustration, huge bold Art Deco masthead headline in capital letters reading "CIVIL UNREST" spanning the full width of the page, dense columns of small newspaper body text filling the rest of the page below the headline, silhouettes of a crowd clashing in a colonial trading town square, Art Deco newspaper layout, game event card art, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Krach** — `events/crash.jpg`
```
Vintage newspaper front page illustration, huge bold Art Deco masthead headline in capital letters reading "MARKET CRASH" spanning the full width of the page, dense columns of small newspaper body text filling the rest of the page below the headline, Art Deco newspaper layout, game event card art, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Hossa** — `events/boom.jpg`
```
Vintage newspaper front page illustration, huge bold Art Deco masthead headline in capital letters reading "MARKET BOOM" spanning the full width of the page, dense columns of small newspaper body text filling the rest of the page below the headline, Art Deco newspaper layout, game event card art, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

### 5. Tor wyścigów konnych
- Tło toru
- Sylwetki 4–6 różnych koni + dżokejów (do prostej animacji przesuwania)

**Prompt (tło):**
```
1920s horse racetrack, grandstands with spectators (silhouettes), starting
gate, side-view racing background for 2D game, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```
**Prompty (6 koni + dżokejów, różne barwy jeźdźców, gotowe do wklejenia):**

**Czerwone jedwabie**
```
Side-view horse and jockey sprite in red racing silks, running pose, isolated on transparent background, simple flat game sprite, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Niebieskie jedwabie**
```
Side-view horse and jockey sprite in blue racing silks, running pose, isolated on transparent background, simple flat game sprite, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Zielone jedwabie**
```
Side-view horse and jockey sprite in green racing silks, running pose, isolated on transparent background, simple flat game sprite, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Złote jedwabie**
```
Side-view horse and jockey sprite in gold racing silks, running pose, isolated on transparent background, simple flat game sprite, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Fioletowe jedwabie**
```
Side-view horse and jockey sprite in purple racing silks, running pose, isolated on transparent background, simple flat game sprite, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Czarno-białe jedwabie w paski**
```
Side-view horse and jockey sprite in black-and-white striped racing silks, running pose, isolated on transparent background, simple flat game sprite, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

### 6. Dom aukcyjny
- Tło sali aukcyjnej — sztaluga ma mieć WYRAŹNIE puste, jednolite płótno
  (nie tylko "empty easel", bo model czasem i tak coś na nie maluje) — na to
  miejsce w kodzie nałożymy jeden z 40 obrazów niżej jako osobną warstwę
  (TextureRect), więc płótno musi być czyste i mieć wyraźne krawędzie do
  skalibrowania pozycji.
- Portrety 4–6 rywali (AI) w stylu epoki, do dymków licytacyjnych
- 40 unikalnych obrazów, po jednym na numer katalogowy (patrz §6b niżej) —
  wstawiane w kodzie NA WIERZCH pustego płótna z tła, nie wypalone w tle

**Prompt (tło):**
```
Elegant 1920s auction house interior, Art Deco wood paneling, podium, gathered
silhouette crowd, single spotlighted empty easel in center, game background
art, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```
**Prompty (6 portretów rywali, 2 płcie × 3 dodatki, gotowe do wklejenia).**
✅ **Podpięte w kodzie**: `AIPlayers.GENERIC_RIVAL_POOL` losuje przy KAŻDEJ
nowej grze 2 z tych 6 wariantów dla `rival_2`/`rival_3` (imię + portret
zawsze razem, z tego samego wariantu) — 6 portretów to zapas puli, z
którego co grę wybierane są tylko 2, nie sztywny rozmiar rosteru. Zapisz
każdy pod nazwą z tabeli niżej w `game/art/characters/` — `AuctionHouse.gd`
sam sprawdza, czy plik istnieje, więc może być ich mniej niż 6 (brakujące
warianty po prostu nie pokażą portretu, gdy zostaną wylosowane).

✅ **Ta sama pula ponownie użyta jako awatary GRACZA** (zgłoszone przez
użytkownika: wybór płci + awatara przy wpisywaniu imienia) —
`Players.GENDERS`/`AVATAR_VARIANTS` w `MainMenu.gd` _show_name_entry, bez
generowania nowej grafiki. Jeśli kiedyś zabraknie wariantów (więcej niż 3
dodatki na płeć, albo więcej niż 2 płcie), dopisać kolejne prompty w tej
samej konwencji nazw plików.

| Wariant | Plik | Przypisane imię |
|---|---|---|
| Mężczyzna, cylinder | `characters/male_tophat.jpg` | Baron Heinrich von Falkenstein |
| Mężczyzna, monokl | `characters/male_monocle.jpg` | Lord Edmund Ashcombe |
| Mężczyzna, boa z piór | `characters/male_boa.jpg` | Hrabia Alessandro Ricci |
| Kobieta, cylinder | `characters/female_tophat.jpg` | Lady Wilhelmina Hartog |
| Kobieta, monokl | `characters/female_monocle.jpg` | Contessa Isabella Moreau |
| Kobieta, boa z piór | `characters/female_boa.jpg` | Madame Colette Dubois |

**Mężczyzna, cylinder** (`characters/male_tophat.jpg`)
```
1920s art collector character portrait, male, distinctive top hat accessory, bust portrait, game character icon, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Mężczyzna, monokl** (`characters/male_monocle.jpg`)
```
1920s art collector character portrait, male, distinctive monocle accessory, bust portrait, game character icon, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Mężczyzna, boa z piór** (`characters/male_boa.jpg`)
```
1920s art collector character portrait, male, distinctive feather boa accessory, bust portrait, game character icon, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Kobieta, cylinder** (`characters/female_tophat.jpg`)
```
1920s art collector character portrait, female, distinctive top hat accessory, bust portrait, game character icon, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Kobieta, monokl** (`characters/female_monocle.jpg`)
```
1920s art collector character portrait, female, distinctive monocle accessory, bust portrait, game character icon, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Kobieta, boa z piór** (`characters/female_boa.jpg`)
```
1920s art collector character portrait, female, distinctive feather boa accessory, bust portrait, game character icon, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Prompt (Vico Falsari — nazwany rywal-fałszerz, patrz `MECHANIKI_EKONOMICZNE.md`
pkt. 9). ✅ 3 warianty gotowe i podpięte** (`characters/vico_1.jpg`,
`vico_2.jpg`, `vico_3.jpg`) — losowane przy każdej nowej grze, tak samo jak
portrety generycznych rywali (`AIPlayers.VICO_PORTRAIT_VARIANTS`), zamiast
jednego stałego pliku:
```
1920s dapper art forger character portrait, sly confident smirk, slicked
hair, pencil moustache, fine tailored suit with pocket square, bust portrait,
game character icon, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Prompt (rama):**

⚠ **Poprawione drugi raz** — pierwsza poprawka (cienki brzeg + duży pusty
środek) usunęła kolorowe tło, ale otwór w środku dalej wychodził jako
PIONOWY PROSTOKĄT (portretowe proporcje, jak zwykła ramka na zdjęcie), mimo
że całe płótno jest kwadratowe — model domyślnie rysuje "picture frame" z
proporcjami pionowego portretu, niezależnie od kształtu całego obrazka.
Problem wyszedł dopiero przy realnym wklejeniu kwadratowego obrazu (896×896,
patrz `Paintings`/`art/paintings/`) w ten otwór: malowidło trzeba było
przeskalować do szerokości otworu, zostawiając puste pasy płótna u góry i u
dołu (zgłoszone przez użytkownika po podglądzie kompozytu). Rama MUSI mieć
KWADRATOWY otwór w środku, żeby kwadratowe obrazy wypełniały go idealnie,
bez żadnych pasów. Prompt niżej dopisuje to wprost + pilnuje RÓWNEJ
szerokości brzegu ze wszystkich 4 stron (bez tego rama bywa "cięższa" u
dołu, co też psuje kwadrat otworu).

```
Ornate thin gold Art Deco picture frame border only, perfectly square inner
opening exactly matching the square outer canvas proportions (NOT a tall
portrait window), the frame border is the EXACT SAME width on all four
sides — top, bottom, left, and right — frame lines running close to the
very edges of the square canvas, the frame border itself no more than 10%
of the image width, one huge empty flat SQUARE opening filling the
remaining center of the canvas edge to edge, plain flat cream fill inside
the opening, isolated on pure flat empty background, no background color,
no background pattern, no scenery, no wall, no shadow, game UI asset, Art
Deco 1920s illustration style, gold with deep green and burgundy accent
details only on the frame itself, flat vector-gouache texture, subtle paper
grain, elegant geometric ornamentation, mobile game asset, clean
silhouette, no photorealism
```
Dodatkowa linijka do Negative Prompt (tylko ten asset):
```
background color, background pattern, colored background, gradient background, wall, backdrop, vignette, thick frame, wide frame border, small center opening, portrait frame, tall rectangular opening, non-square opening, uneven border width, wider bottom rail, decorative scene, canvas texture, painting inside frame
```
Jeśli mimo to otwór dalej wyjdzie niekwadratowy (albo tło się pojawi),
najszybciej po prostu przytnij wygenerowany obraz w edytorze — WAŻNE: przytnij
tak, żeby otwór w środku był kwadratowy (dociąć nadmiar u góry/dołu albo po
bokach, cokolwiek jest dłuższe), a nie tylko przyciąć tło dookoła całej ramy.

### 7. 40 obrazów kolekcji (8 kategorii × 5 obrazów)

⚠ **Poprawione** — poprzednia wersja tej sekcji grupowała obrazy w bloki po
numerach (1–5, 6–10, …), zgodnie z ÓWCZESNYM (błędnym) `Paintings.CATALOG`.
Po weryfikacji prawdziwymi danymi z rewersów kart (`docs/ZRODLA_C64_WIKI.md`,
Fragment 5) kategorie NIE idą już blokami — patrz tabela w §6b/Fragment 5.
Prompty niżej pogrupowane wg **prawdziwej** kategorii z kodu i mają temat
(subject) dopasowany do **prawdziwej kompozycji** oryginalnego obrazu (nie
losowej puli 6 tematów jak poprzednio) — bez nazywania konkretnego malarza,
tylko opis sceny/kompozycji, zgodnie z zasadą "styl/okres, nie nazwisko"
(część obrazów, np. Picasso czy Braque, wciąż podlega prawom autorskim w
wielu krajach).

Każda z 40 grafik NIE dostaje "Base style tag" gry — mają wyglądać jak
prawdziwe malarstwo muzealne, nie jak ikony gry, żeby kontrastowały z resztą
UI.

⚠ **"museum piece" w prompcie potrafi skłonić model do wygenerowania całej
scenografii muzealnej wokół obrazu** (aksamitna kurtyna, cokół z wazami w
tle) zamiast płaskiego płótna — to NIE jest klasyczna "ramka", więc dopisanie
samego `border` do Negative Prompt nic nie daje (zgłoszone przez
użytkownika). Prompty niżej mają to już naprawione ("flat single painting
filling the entire square canvas edge to edge, no curtain, no pedestal, no
display stand..." zamiast "museum piece"), ale jeśli mimo to coś podobnego
się pojawi, dopisz dodatkowo do Negative Prompt (tylko przy tych 40
obrazach, nie globalnie — inne assety, np. tło Domu aukcyjnego, celowo MAJĄ
kurtyny):
```
stage curtain, theater curtain, curtain fabric, vignette, plinth, pedestal, display stand, gallery interior, vases, bottles, decorative objects in foreground, picture frame border
```
Ewentualnie po prostu przytnij wygenerowany obraz do samego środka (obraz
bez otoczenia) w dowolnym edytorze — szybsze niż walka z promptem.

Poniżej **wszystkich 40 gotowych promptów**, po jednym na obraz — kopiuj-wklej
bez żadnych zmian. Numeracja zgodna z `Paintings.CATALOG`/`PAINTING_INFO` w
kodzie i z `docs/ZRODLA_C64_WIKI.md` Fragment 5. Zapisz jako `painting_NN.jpg`
(patrz konwencja nazw w sekcji "Gdzie odkładać pliki").

**1) Vermeer — obrazy 3, 4, 6, 9, 10** — malarstwo holenderskie złotego wieku

Obraz 3
```
17th century Dutch Golden Age genre painting, domestic interior scene, soft window light, muted earthy palette, oil painting texture, intimate composition, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: an artist seen from behind painting a model in historical dress in a studio
```

Obraz 4
```
17th century Dutch Golden Age genre painting, domestic interior scene, soft window light, muted earthy palette, oil painting texture, intimate composition, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a young woman intently making lace with bobbins at a table
```

Obraz 6
```
17th century Dutch Golden Age genre painting, domestic interior scene, soft window light, muted earthy palette, oil painting texture, intimate composition, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a woman in a blue jacket reading a letter by a window
```

Obraz 9
```
17th century Dutch Golden Age genre painting, domestic interior scene, soft window light, muted earthy palette, oil painting texture, intimate composition, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a scholar in a robe reaching toward a celestial globe on a table
```

Obraz 10
```
17th century Dutch Golden Age genre painting, domestic interior scene, soft window light, muted earthy palette, oil painting texture, intimate composition, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a young woman in a turban looking over her shoulder, wearing a pearl earring
```

**2) Barok — obrazy 1, 2, 5, 35, 36**

Obraz 1
```
Baroque oil painting, dramatic chiaroscuro lighting, rich dark background, opulent fabric and gesture, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a dramatic marine scene with sailing ships, one firing a cannon, stormy sky
```

Obraz 2
```
Baroque oil painting, dramatic chiaroscuro lighting, rich dark background, opulent fabric and gesture, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a dynamic mythological scene of horsemen abducting struggling women, swirling drapery
```

Obraz 5
```
Baroque oil painting, dramatic chiaroscuro lighting, rich dark background, opulent fabric and gesture, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: an elderly man resting in an armchair, hand on his face, deep shadow
```

Obraz 35
```
Baroque oil painting, dramatic chiaroscuro lighting, rich dark background, opulent fabric and gesture, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: peasants harvesting wheat in a golden summer field, some resting under a tree
```

Obraz 36
```
Baroque oil painting, dramatic chiaroscuro lighting, rich dark background, opulent fabric and gesture, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a young man in a wide-brimmed hat holding a skull, memento mori
```

**3) Klasycyzm — obrazy 24, 27, 28, 31, 32**

Obraz 24
```
Neoclassical oil painting, balanced formal composition, clean idealized figures, restrained noble color palette, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a precise architectural view of a castle courtyard with small figures for scale
```

Obraz 27
```
Neoclassical oil painting, balanced formal composition, clean idealized figures, restrained noble color palette, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: an elderly artist's self-portrait wearing spectacles and a soft cap
```

Obraz 28
```
Neoclassical oil painting, balanced formal composition, clean idealized figures, restrained noble color palette, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a nude woman seen from behind seated on draped cloth, smooth idealized form
```

Obraz 31
```
Neoclassical oil painting, balanced formal composition, clean idealized figures, restrained noble color palette, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: an old bearded man in penitent prayer, hands clasped, solemn mood
```

Obraz 32
```
Neoclassical oil painting, balanced formal composition, clean idealized figures, restrained noble color palette, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a man lifeless in a bathtub, arm hanging, holding a paper, stark composition
```

**4) Romantyzm — obrazy 15, 16, 19, 20, 23**

Obraz 15
```
Romantic era oil painting, dramatic sky and landscape or portrait, sublime nature, emotional atmosphere, sweeping brushwork, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: shattered ice floes piled dramatically under a cold pale sky
```

Obraz 16
```
Romantic era oil painting, dramatic sky and landscape or portrait, sublime nature, emotional atmosphere, sweeping brushwork, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a lighthouse on a windswept coast under a cloudy sky
```

Obraz 19
```
Romantic era oil painting, dramatic sky and landscape or portrait, sublime nature, emotional atmosphere, sweeping brushwork, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a burning government building at night reflected over a river, glowing flames
```

Obraz 20
```
Romantic era oil painting, dramatic sky and landscape or portrait, sublime nature, emotional atmosphere, sweeping brushwork, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: an allegorical woman in flowing robes standing on rubble with arms open, dramatic ruins behind
```

Obraz 23
```
Romantic era oil painting, dramatic sky and landscape or portrait, sublime nature, emotional atmosphere, sweeping brushwork, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a young man's direct self-portrait bust, sharp gaze, plain background
```

**5) Impresjonizm — obrazy 7, 8, 11, 12, 13**

Obraz 7
```
Impressionist oil painting, loose visible brushstrokes, dappled natural light, outdoor or intimate interior scene, soft vibrant palette, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a woman crouching and bathing in a low round tub, seen from above
```

Obraz 8
```
Impressionist oil painting, loose visible brushstrokes, dappled natural light, outdoor or intimate interior scene, soft vibrant palette, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a bust portrait of a bearded painter in a dark coat, confident gaze
```

Obraz 11
```
Impressionist oil painting, loose visible brushstrokes, dappled natural light, outdoor or intimate interior scene, soft vibrant palette, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a young woman with dark hair in a loosely open blouse, soft warm lighting
```

Obraz 12
```
Impressionist oil painting, loose visible brushstrokes, dappled natural light, outdoor or intimate interior scene, soft vibrant palette, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: coastal cliffs above a beach, sea and sky in shimmering light
```

Obraz 13
```
Impressionist oil painting, loose visible brushstrokes, dappled natural light, outdoor or intimate interior scene, soft vibrant palette, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: two men seated at a table playing cards, still and contemplative
```

**6) Symbolizm — obrazy 14, 17, 18, 21, 22**

Obraz 14
```
Symbolist oil painting, dreamlike mysterious mood, decorative ornamental detail, muted jewel-tone palette, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a woman in a flowing white dress standing on a bearskin rug, tonal harmony
```

Obraz 17
```
Symbolist oil painting, dreamlike mysterious mood, decorative ornamental detail, muted jewel-tone palette, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a woman seated at a table eating oysters, expressive loose brushwork
```

Obraz 18
```
Symbolist oil painting, dreamlike mysterious mood, decorative ornamental detail, muted jewel-tone palette, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a stylish woman in an ornate patterned dress with a gold decorative background
```

Obraz 21
```
Symbolist oil painting, dreamlike mysterious mood, decorative ornamental detail, muted jewel-tone palette, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a mythological merman and sea nymph embracing among ocean waves
```

Obraz 22
```
Symbolist oil painting, dreamlike mysterious mood, decorative ornamental detail, muted jewel-tone palette, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a solitary woman with a distant gaze surrounded by sparse symbolic objects
```

**7) Ekspresjonizm — obrazy 26, 33, 37, 38, 39**

Obraz 26
```
Expressionist oil painting, bold distorted forms, intense unnatural color contrasts, emotional raw brushwork, early 20th century avant-garde, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a drawbridge over a canal with a horse-drawn cart, vivid swirling color
```

Obraz 33
```
Expressionist oil painting, bold distorted forms, intense unnatural color contrasts, emotional raw brushwork, early 20th century avant-garde, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a woman with flowing dark hair in a haunting sensual pose, halo-like border
```

Obraz 37
```
Expressionist oil painting, bold distorted forms, intense unnatural color contrasts, emotional raw brushwork, early 20th century avant-garde, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a small village church among colorful hills, bold simplified shapes
```

Obraz 38
```
Expressionist oil painting, bold distorted forms, intense unnatural color contrasts, emotional raw brushwork, early 20th century avant-garde, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a vividly colored horse standing in an abstracted rolling landscape
```

Obraz 39
```
Expressionist oil painting, bold distorted forms, intense unnatural color contrasts, emotional raw brushwork, early 20th century avant-garde, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a bustling market scene with figures in flowing robes under awnings, warm saturated color
```

**8) Moderna — obrazy 25, 29, 30, 34, 40**

Obraz 25
```
Early modernist oil painting, simplified geometric or fragmented forms, flattened perspective, bold unconventional color blocks, early 20th century avant-garde composition, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: two women in a tropical setting, one holding a tray of fruit, bold flat color
```

Obraz 29
```
Early modernist oil painting, simplified geometric or fragmented forms, flattened perspective, bold unconventional color blocks, early 20th century avant-garde composition, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a glass bowl of goldfish beside a small sculpture on a table, vivid decorative color
```

Obraz 30
```
Early modernist oil painting, simplified geometric or fragmented forms, flattened perspective, bold unconventional color blocks, early 20th century avant-garde composition, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a dancer in a colorful dress mid-pose, bold flattened color shapes
```

Obraz 34
```
Early modernist oil painting, simplified geometric or fragmented forms, flattened perspective, bold unconventional color blocks, early 20th century avant-garde composition, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a woman having her hair styled by another figure, fragmented cubist forms
```

Obraz 40
```
Early modernist oil painting, simplified geometric or fragmented forms, flattened perspective, bold unconventional color blocks, early 20th century avant-garde composition, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: an angular viaduct bridge over a village, faceted cubist landscape
```

Do wariantu "podróbka" tego samego obrazu (opcjonalne, ~8–10 sztuk, patrz
Plan produkcji wiersz 12): powtórz dokładnie ten sam prompt z tym samym
seedem, dopisując na końcu `, slightly different brushwork, subtle color
mismatch, forged reproduction`. **Zapisz jako `painting_NN_fake.jpg`**
(ta sama konwencja co oryginały, plus `_fake`) — `AuctionHouse.gd` faktycznie
podmienia grafikę na tę fałszywą wersję, gdy dany numer trafi się drugi raz
w kolekcji (`Paintings.is_forgery_by_duplicate`), NIEZALEŻNIE od tego, czy
akurat wyświetliło się ostrzeżenie z ekspertyzy — więc uważny gracz może
rozpoznać podróbkę "na oko". 10 z ~8–10 gotowe: obrazy 7, 10, 11, 16, 21, 25,
29, 30, 32, 33. Dla numerów bez wariantu gra po cichu pokazuje zwykłą grafikę
(bez różnicy wizualnej), więc brakujące warianty nie są pilne.

### 8. Szkoła sztuki (mini-gra autentykacji)
- Tło: pracownia/atelier
- Pary obrazów oryginał/fałszywka (patrz punkt 7)

**Prompt (tło):**
```
Art academy studio interior, easels, reference paintings on walls, warm
natural window light, 1920s art school, game background art,
Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

### 9. Galeria (kolekcja gracza)
- Tło pustej galerii + wariant "wypełnionej" (opcjonalnie kilka etapów
  zapełnienia)

**Prompt:**
```
Art Deco private gallery hall interior, marble floor, empty wall space for
hanging paintings, soft gallery lighting, elegant benches, game background
art, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

⚠ **Zgłoszone przez użytkownika** — obrazek z promptu wyżej wychodzi ZBYT
wypełniony (ściany obwieszone własnymi obrazami w ramach, ławki, żyrandol,
rośliny), więc konkuruje wizualnie z kafelkami/dużym podglądem, które gra i
tak nakłada na wierzchu (patrz Gallery.gd _build_framed_image). Potrzebny
PROŚCIEJSZY wariant, nazwany osobno (`gallery_empty.jpg`, patrz konwencja
nazw niżej) — kod (`Gallery.gd`) próbuje najpierw tego wariantu, a jeśli
pliku jeszcze nie ma, po cichu spada z powrotem na zwykły `gallery.jpg`
powyżej, więc podmiana jest bezpieczna do wgrania w dowolnym momencie.

⚠ **UWAGA przy generowaniu wariantu pustego** — pierwsza próba z "no
paintings/no benches/no chandelier" WPROST w opisie i tak wyszła pełna tych
elementów (ten sam mechanizm co ostrzeżenie przy §7: samo wymienienie
obiektu w prompcie, nawet zaprzeczone, potrafi go przywołać — model łapie
rzeczownik, nie zaprzeczenie). Prompt NIŻEJ jest już poprawiony pod tym
kątem — użyj GO, nie żadnej wcześniejszej wersji z historii generacji w
Leonardo (jeśli edytujesz istniejący node z poprzednią próbą, upewnij się,
że CAŁY tekst promptu został nadpisany, nie tylko dopisany na końcu).

**Prompt (wariant pusty — jedyny właściwy, nie wymienia zakazanych obiektów):**
```
Empty Art Deco room interior background, blank flat wall panels in muted teal and gold tones, polished marble floor with geometric inlay, soft warm ambient lighting, completely bare and uncluttered, large open negative space filling the center and lower half of the frame, minimalist architecture, game background art, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation on cornices only, mobile game asset, clean silhouette, no photorealism
```

**Negative Prompt DODATKOWY dla tego promptu** (wklej OBOK stałego z sekcji
"Ustawienia techniczne" na górze dokumentu, nie zamiast niego):
```
paintings, framed artwork, picture frames, art on wall, wall decorations, benches, seating, furniture, pedestals, plinths, sculptures, statues, chandelier, hanging lamp, ceiling light fixture, potted plants, vases, people, crowd, figures
```

### 9b. Ikony kategorii stylistycznych w Galerii (8 sztuk)

Zgłoszone przez użytkownika: w Galerii kafelek każdej z 8 kategorii
(Vermeer, Barok, Klasycyzm, Romantyzm, Impresjonizm, Symbolizm,
Ekspresjonizm, Moderna) ma pokazywać obrazek reprezentujący DANĄ EPOKĘ/STYL
— nie konkretny numer katalogowy z §7, tylko emblematyczną, ogólną scenę w
tym stylu, służącą jako "okładka" kategorii w siatce Galerii. Kod (patrz
`Gallery.gd`) po cichu nie pokazuje obrazka, dopóki plik nie istnieje —
można dorabiać pojedynczo, w dowolnej kolejności.

Ta sama zasada anty-diorama co przy §7 (model lubi dorysować aksamitną
kurtynę/cokół zamiast płaskiego płótna) — prompty niżej mają to już
naprawione.

⚠ **Zgłoszone przez użytkownika (Symbolizm)** — model zamiast płaskiego
płótna dorysował ozdobną złotą ramę w stylu Art Nouveau dookoła całej sceny.
Winna fraza to prawdopodobnie "decorative ornamental detail" w prompcie
Symbolizmu — miała opisywać ZDOBIENIA WEWNĄTRZ sceny (jak u Klimta), ale
model zinterpretował ją jako ramę. Prompt Symbolizmu niżej już poprawiony
(fraza zamieniona + explicit "no ornamental border/frame"). Jeśli mimo to
któryś z 8 promptów (nie tylko Symbolizm) znowu doda ramę, dopisz do Negative
Prompt (oprócz stałego z sekcji "Ustawienia techniczne" na górze dokumentu):
```
ornamental frame, gold frame, art nouveau frame border, decorative border, picture frame, framed artwork, vignette border
```

**Vermeer**
```
17th century Dutch Golden Age genre painting, domestic interior scene, soft window light, muted earthy palette, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a woman standing at a sunlit window reading a letter, quiet domestic moment
```

**Barok**
```
Baroque oil painting, dramatic chiaroscuro lighting, rich dark background, opulent fabric and gesture, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a richly dressed nobleman in candlelight, dramatic shadow across half the face
```

**Klasycyzm**
```
Neoclassical oil painting, balanced formal composition, clean idealized figures, restrained noble color palette, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a formal garden with a classical marble statue and symmetrical hedges
```

**Romantyzm**
```
Romantic era oil painting, dramatic sky and landscape, sublime nature, emotional atmosphere, sweeping brushwork, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a lone ship battling a stormy sea under a dramatic, glowing sunset sky
```

**Impresjonizm**
```
Impressionist oil painting, loose visible brushstrokes, dappled natural light, outdoor scene, soft vibrant palette, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a riverside garden path with figures strolling under dappled sunlight through trees
```

**Symbolizm**
```
Symbolist oil painting, dreamlike mysterious mood, rich symbolic imagery, muted jewel-tone palette, oil painting texture, flat single painting filling the entire square canvas edge to edge, no ornamental border, no gold frame, no picture frame, painting reaches all four edges of the canvas with no decorative border of any kind, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a solitary robed figure gazing at a glowing moon over a still, dark lake
```

**Ekspresjonizm**
```
Expressionist oil painting, bold distorted forms, intense unnatural color contrasts, emotional raw brushwork, early 20th century avant-garde, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a lone anguished figure on a bridge under a swirling, violently colored sky
```

**Moderna**
```
Early modernist oil painting, simplified geometric or fragmented forms, flattened perspective, bold unconventional color blocks, early 20th century avant-garde composition, oil painting texture, flat single painting filling the entire square canvas edge to edge, no curtain, no pedestal, no display stand, no surrounding objects, not a staged museum display, subject: a fragmented cubist still life of a guitar and fruit bowl on a table
```

### 10. UI ogólne
- Przyciski, ramki paneli, ikony waluty, ikony statystyk (kapitał, ekspertyza,
  data), pasek postępu aukcji

**Ramka menu Huba — ⚠ NIE GENERUJ**, patrz Plan produkcji wiersz 7:
próba z gotową grafiką (NinePatchRect na rozciąganym obrazku 896×896)
wyglądała źle — pojedyncze motywy zdobne przy krawędziach (diamenciki,
narożne łuki) zniekształcały się przy rozciąganiu do wąskiego, wysokiego
panelu menu. Rozwiązane bez grafiki, natywnie w `MenuFrame.gd`
(analogicznie do `MapPin.gd`) — rysowana na bieżąco ramka skaluje się
bez artefaktów do dowolnej wysokości panelu.

**Prompt (ogólny, na inne elementy UI — ikony statystyk, pasek postępu):**
```
Art Deco UI panel frame with geometric gold border ornamentation, empty
center for text, transparent background, mobile game UI element,
Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

### 11. Ekran ustawień
Zgłoszone przez użytkownika: ekranowi Ustawień (`Settings.gd` — wybór
języka + wyciszenie muzyki) brakowało własnego tła; dotąd po cichu spadał
na `stock_market.jpg` (ten sam fallback co karta wydarzenia,
`WorldEventCard.gd`). Motyw: control room/warsztat kolekcjonera z
gramofonem (nawiązanie do muzyki) i globusem (nawiązanie do wyboru
języka) — dopasowany tematycznie do samej zawartości ekranu, nie tylko
"kolejny wystrój wnętrza".

**Prompt (`settings.jpg`):**
```
1920s art deco study, a wall panel with polished brass dials, gauges and toggle switches, an antique gramophone with a large brass horn speaker on a side table, a small globe on a stand suggesting language/travel, warm lamplight, game background art, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

## Gotowe prompty do wklejenia — priorytet 2 (tła 6 pozostałych ekranów)

✅ **Wszystkie 6 gotowe i podpięte w kodzie** (Plantacje, Dom aukcyjny, Giełda,
Wyścigi, Szkoła sztuki, Galeria) — patrz status w tabeli "Plan produkcji"
niżej. Prompty zostają tu jako zapis/punkt odniesienia na wypadek potrzeby
regeneracji.

Poniżej **pełne, złożone prompty** (base style tag już doklejony na końcu) —
kopiuj-wklej całość bezpośrednio do pola "Prompt" w Leonardo, nic więcej nie
trzeba dopisywać. Do pola "Negative Prompt" wklej treść z sekcji "Negative
prompt" na samej górze dokumentu — ta sama dla wszystkich sześciu. Format:
16:9, generuj, wybierz najlepszy z 4 wyników, upscaluj do 1920×1080.

Dla spójności z już gotowymi grafikami dodaj `main_menu_title.jpg` (albo
`hub_map.jpg`) jako Style Reference / Image Guidance przy wadze ok. 30–50%
(patrz "Workflow zachowania spójności" wyżej) — to ten sam styl co reszta gry.

**1. Plantacje** (docelowo `game/art/backgrounds/plantation.jpg`)
```
Isometric plantation field background, 1920s tropical farmland, rows of crops, small worker huts, warm afternoon light, game background art, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**2. Dom aukcyjny** (`auction_house.jpg`) — dopracowane pod zrzut ekranu
oryginału podesłany przez użytkownika: świeczniki na ścianach, oprawiony
sztych na lewej ścianie, ozdobne lustro na prawej, aukcjoner przy mównicy.
Płótno na sztaludze ma być jednolite/puste (BEZ żadnego motywu) — w kodzie
nakładamy na nie jeden z 40 obrazów z §6b jako osobną warstwę, więc model
nie może nic na nie "domalować".
```
Elegant 1920s auction house interior, Art Deco wood paneling, wall sconces with lit candles on either side, a small ornately framed print on the left wall, an ornate gilded mirror on the right wall, an auctioneer figure standing at a podium gesturing mid-sale, gathered silhouette crowd, an easel in the center holding a blank plain unpainted canvas with a simple wooden frame, flat solid cream canvas surface with no image or texture on it, game background art, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**3. Giełda** (`stock_market.jpg`)
```
1920s stock exchange trading floor, Art Deco architecture, chalkboard with numbers, bustling brokers in background (silhouettes only, no detailed faces), game background art, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**4. Wyścigi konne** (`races.jpg`)
```
1920s horse racetrack, grandstands with spectators (silhouettes), starting gate, side-view racing background for 2D game, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**5. Szkoła sztuki** (`art_school.jpg`)
```
Art academy studio interior, easels, reference paintings on walls, warm natural window light, 1920s art school, game background art, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**6. Galeria** (`gallery.jpg`)
```
Art Deco private gallery hall interior, marble floor, empty wall space for hanging paintings, soft gallery lighting, elegant benches, game background art, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

### 7. Spichlerz (magazyn zebranych plonów) — ✅ zrobione i podpięte (`warehouse.jpg`)

Zbiorczy widok zapasów ze wszystkich plantacji gracza (4 "silosy":
kawa/tytoń/herbata/kakao), patrz zrzut ekranu oryginału podesłany przez
użytkownika ("KAFFEE/TABAK/TEE/KAKAO" + menu ANKAUF/TRANSPORT/TERMINE/
AUSGANG). Na razie bez tła (`scenes/warehouse/Warehouse.gd`) — same silosy
(poziom wypełnienia zapasami) są już rozwiązane natywnie w kodzie
(kolorowe `ColorRect` w ramce, patrz `Warehouse.gd`), więc generować trzeba
tylko TŁO sceny, nie same silosy.

**Prompt (tło):**
```
1920s colonial trading warehouse interior, wooden crop storage silos and sacks along the walls, tall arched windows, warm afternoon light, game background art, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

Docelowa nazwa pliku: `game/art/backgrounds/warehouse.jpg` — po podesłaniu
podepnę tak samo jak resztę (`ScreenHelpers.make_background` na początku
`Warehouse.gd::_ready()`).

Jak wygenerujesz i wybierzesz najlepsze — wyślij mi je (tak jak menu główne i
mapę), a podepnę je w kodzie.

## Plan produkcji — pełna lista do odhaczania

Kolejność = priorytet (1 = rób najpierw). "Szt." to liczba **unikalnych**
finalnych grafik (nie liczba generacji — na każdą liczyć ~4 generacje w
Leonardo, żeby mieć z czego wybrać).

| # | Priorytet | Asset | Szt. | Format / proporcje | Sekcja promptu | Status |
|---|---|---|---|---|---|---|
| 1 | 1 | Obraz referencyjny stylu / tło menu głównego (z tytułem wpisanym w tło) | 1 | 16:9, docelowo 1920×1080 | §1 | ✅ zrobione i podpięte — `main_menu_title.jpg` wgrane z tytułem wpisanym bezpośrednio w tło |
| 2 | 1 | ~~Logo "The Forger: Retro Tycoon"~~ | 1 | dowolne, JPG | §1 | ⛔ wycofane — zastąpione tytułem wpisanym w tło (wiersz 1), `logo.jpg` nieużywane w kodzie |
| 3a | 2 | Tło Plantacji | 1 | 16:9, 1920×1080 | §3 | ✅ zrobione i podpięte (`plantation.jpg`) |
| 3b | 2 | Tło Domu aukcyjnego | 1 | 16:9, 1920×1080 | §6 | ✅ zrobione i podpięte (`auction_house.jpg`) |
| 3c | 2 | Tło Giełdy | 1 | 16:9, 1920×1080 | §4 | ✅ zrobione i podpięte (`stock_market.jpg`) |
| 3d | 2 | Tło Wyścigów | 1 | 16:9, 1920×1080 | §5 | ✅ zrobione i podpięte (`races.jpg`) |
| 3e | 2 | Tło Szkoły sztuki | 1 | 16:9, 1920×1080 | §8 | ✅ zrobione i podpięte (`art_school.jpg`) |
| 3f | 2 | Tło Galerii | 1 | 16:9, 1920×1080 | §9 | ✅ zrobione i podpięte (`gallery.jpg`) |
| 3g | 2 | Tło Spichlerza (nowy ekran, patrz §7 w sekcji priorytet 2) | 1 | 16:9, 1920×1080 | §7 | ✅ zrobione i podpięte (`warehouse.jpg`) |
| 3h | 2 | Tło Rynku (nowy ekran, wydzielony z Giełdy — patrz §4) | 1 | 16:9, 1920×1080 | §4 | ✅ zrobione i podpięte (`market.jpg`) |
| — | — | Tło Mapy świata (Hub) | 1 | 16:9, 1920×1080 | §2 | ✅ zrobione (`hub_map.jpg`) |
| 4 | 3 | Szablony regionalne teł miast (`Cities.gd` `REGION_BACKGROUNDS`) | 5 | 16:9, 1920×1080 | §2.1 | ✅ zrobione — zastąpione przez unikalne tła per miasto (wiersz niżej), zostają jako czysty fallback na wypadek nowego miasta bez własnej grafiki: Europa (`region_europe.jpg`), Ameryka Płd./Środk. (`region_tropical_port.jpg`, jeden plik dla obu), Afryka (`region_africa.jpg`), Azja (`region_asia.jpg`), Ameryka Płn. (`region_north_america.jpg`) |
| 4b | 2 | Unikalne tła **per miasto** (`Cities.gd` `CITY_BACKGROUNDS`, ma priorytet nad tłem regionu) | 18 | 16:9, 1920×1080 | §2.2 | ✅ zrobione — wszystkie 18 miast: Berlin, Paryż, Amsterdam, Lizbona, Londyn, Ankara, Bombaj, Colombo, Mombasa, Duala, Abidżan, Rio, Bogota, Gwatemala, Meksyk, Nowy Jork, Richmond, St. Louis |
| 5 | — | ~~Ikony pinezek mapy~~ | — | — | §2 | ✅ **rozwiązane w kodzie**, nie generować — Leonardo uparcie robiło pełne sceny zamiast ikon, więc pinezki są teraz rysowane natywnie w Godocie (`MapPin.gd`), bez grafiki |
| 6 | 3 | Ramka obrazu (do aukcji/galerii) | 1 | 1:1, transparent | §6 | ✅ zrobione i podpięte (`art/icons/frame.png`) — kwadratowy otwór w środku, przezroczyste tło; użyta w `AuctionHouse.gd` (obraz na sprzedaż dodany NA WIERZCH ramy, żeby zasłonić jej nieprzezroczyste wnętrze) |
| 7 | — | ~~Ramka menu Huba (grafika z Leonardo)~~ | — | — | §10 | ✅ **rozwiązane w kodzie**, nie generować — NinePatchRect na rozciąganym obrazku wyglądał źle (pojedyncze motywy zdobne przy krawędziach zniekształcały się przy rozciąganiu do wąskiego, wysokiego panelu). Ramka rysowana natywnie w `MenuFrame.gd`, tak jak pinezki (`MapPin.gd`) — bez grafiki, skaluje się bez artefaktów do dowolnej wysokości |
| 7b | 3 | Pozostałe elementy UI ogólne (ikony statystyk, pasek postępu aukcji) | ~5 | 1:1, transparent | §10 | ⬜ do zrobienia — **uwaga**, ten sam typ zadania co pinezki/ramka menu (mały, wyizolowany element), może mieć ten sam problem ze "sceną" zamiast czystej ikony |
| 8 | 4 | Portrety rywali AI (w tym Vico, 2–3 warianty mimiki) | ~7 | 3:4, transparent lub jednolite tło | §6 | ✅ zrobione i podpięte — 6 portretów generycznych rywali + 3 warianty Vico, wszystkie losowane przy nowej grze (`AIPlayers.GENERIC_RIVAL_POOL`/`VICO_PORTRAIT_VARIANTS`) i wyświetlane w `AuctionHouse.gd` |
| 9 | 4 | Fazy wzrostu roślin (4 uprawy × 3 fazy) | 12 | 1:1, 512×512, transparent | §3 | ⬜ do zrobienia — **uwaga**, jak pinezki: mały wyizolowany obiekt, ryzyko tego samego problemu |
| 10 | 5 | Konie + dżokeje (różne barwy jeźdźców) | 4–6 | 1:1 lub 4:3, transparent | §5 | ✅ zrobione i podpięte — 5/6 (`horses/komet.jpg`/`grom.jpg`/`cyklon.jpg`/`blyskawica.jpg`/`wicher.jpg`, po jednym na konia z `Races.gd`); szósty wariant (czarno-białe paski) wgrany na zapas jako `horses/spare_stripes.jpg`, bez przypisanego konia |
| 11 | 6 | 40 obrazów kolekcji (na końcu, seriami po 5 per kategoria) | 40 | 1:1, min. 1024×1024 | §7 | ✅ zrobione i podpięte — wszystkie 40 (`painting_01.jpg`…`painting_40.jpg`, patrz `Paintings.get_texture_path`) |
| 12 | 7 (opcjonalnie) | Warianty "fałszywka" wybranych obrazów (do szkoły sztuki) | ~8–10 | 1:1, jak oryginał | §7, §8 | ✅ 10/~8–10 zrobione i podpięte — obrazy 7, 10, 11, 16, 21, 25, 29, 30, 32, 33 (`painting_NN_fake.jpg`); reszta katalogu dalej pokazuje zwykłą grafikę przy fałszywce (`Paintings.get_texture_path` po cichu spada na oryginał, gdy wariantu brak) |
| 13 | 6 | Ikony 8 kategorii stylistycznych (okładki kafelków w Galerii) | 8 | 1:1, min. 1024×1024 | §9b | ✅ zrobione i podpięte — wszystkie 8 (`vermeer.jpg`, `baroque.jpg`, `classicism.jpg`, `romanticism.jpg`, `impressionism.jpg`, `symbolism.jpg`, `expressionism.jpg`, `modern.jpg`) |
| 14 | 2 | Pusty wariant tła Galerii (bez obrazów/ławek/żyrandola na ścianach) | 1 | 16:9, 1920×1080 | §9 | ✅ zrobione i podpięte (`gallery_empty.jpg`) — zwykły `gallery.jpg` zostaje jako czysty fallback, gdyby plik kiedyś zniknął |
| 15 | 4 | Karty wydarzeń: reforma walutowa, strajk, zamieszki, krach, hossa (docs/GDD.md pkt. 4.2, 4.3, 4.3.1) | 5 | 16:9, 1920×1080 | §4 | ✅ zrobione i podpięte — wszystkie 5 (`events/reform.jpg`/`events/strike.jpg`/`events/riot.jpg`/`events/crash.jpg`/`events/boom.jpg`) wgrane, `WorldEventCard.gd` je wyświetla zamiast fallbacku na tło Giełdy. Krach/hossa: `ShippingCompanies.apply_market_shock` |
| 16 | 4 | Tło ekranu Ustawień | 1 | 16:9, 1920×1080 | §11 | ✅ zrobione i podpięte — `settings.jpg` wgrane |

**Zasada dla wierszy oznaczonych "uwaga" (7 i 9):** jeśli Leonardo znowu
zacznie robić pełne sceny zamiast wyizolowanych ikon/sprite'ów mimo
poprawionego promptu (patrz workflow wyżej), nie trzeba dalej walczyć z
modelem — dam znać, że można to zrobić prościej bezpośrednio w kodzie, tak
jak pinezki.

**Następne 6 grafik do wygenerowania (priorytet 2):** tła sześciu
pozostałych ekranów (3a–3f wyżej). Polecam zacząć od **Plantacji** i **Domu
aukcyjnego** — to dwa ekrany z najwięcej interakcji, największy zysk
wizualny na wygenerowaną grafikę.

## Format eksportu

- Tła: 1920×1080 lub 2048×1152 (potem skalowane w silniku)
- Ikony/sprite'y: kwadratowe, potęgi 2 (128×128, 256×256, 512×512), PNG z
  kanałem alfa
- Portrety postaci: 3:4, min. 768×1024, PNG z alfa lub jednolitym tłem do
  łatwego wycięcia
- Obrazy kolekcji: kwadrat 1:1, min. 1024×1024 (będą powiększane w widoku
  galerii/aukcji)

## Gdzie odkładać pliki w projekcie

Po wygenerowaniu wrzucaj gotowe PNG-i do `game/art/` wg podfolderów z
`game/README.md` (`ui/`, `characters/`, `paintings/`, `backgrounds/`,
`icons/`) — nazywaj pliki opisowo i po angielsku, zgodnie z id używanymi w
kodzie (np. `backgrounds/hub_map.png`, `characters/vico_smirk.png`), żeby
łatwo było je później podpiąć w skryptach ekranów.

**40 obrazów kolekcji — konwencja nazw:** `paintings/painting_NN.jpg`, gdzie
`NN` to numer katalogowy z dwoma cyframi wiodącym zerem (`painting_01.jpg` …
`painting_40.jpg`, zgodnie z numeracją z §7 i `docs/ZRODLA_C64_WIKI.md`) —
`Paintings.get_texture_path(number)` w kodzie liczy tę ścieżkę wprost ze
wzoru, więc nazwy MUSZĄ się zgadzać co do joty, bez dopisków w rodzaju
nazwiska malarza.

**8 ikon kategorii (§9b) — konwencja nazw:** nowy podfolder
`categories/<id>.jpg`, gdzie `<id>` to identyfikator kategorii z
`Paintings.CATEGORIES` (`vermeer`, `baroque`, `classicism`, `romanticism`,
`impressionism`, `symbolism`, `expressionism`, `modern`) — `Gallery.gd`
liczy tę ścieżkę wprost ze wzoru (`"res://art/categories/%s.jpg" % category_id`).

**Pusty wariant tła Galerii (§9) — konwencja nazwy:** `backgrounds/gallery_empty.jpg`
— `Gallery.gd` próbuje go NAJPIERW, z fallbackiem na zwykły
`backgrounds/gallery.jpg`, jeśli plik jeszcze nie istnieje.

**Karty wydarzeń (§4) — konwencja nazw:** nowy podfolder `events/<id>.jpg`,
gdzie `<id>` to `reform`/`strike`/`riot` — `WorldEventCard.gd` liczy tę
ścieżkę wprost ze wzoru, z fallbackiem na `backgrounds/stock_market.jpg`,
jeśli plik jeszcze nie istnieje.
