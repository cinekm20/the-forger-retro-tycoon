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

### 1. Ekran startowy / logo
- Logo gry "VERMEER" w liternictwie art déco, złote litery na sepiowym tle
- Ekran tytułowy: sylwetka kolekcjonera sztuki przed sztalugą, mapa świata w tle
- Opcjonalny motyw: własna, stylizowana reinterpretacja "Dziewczyny z perłą"
  Jana Vermeera (obraz z ok. 1665, domena publiczna) — subtelne mrugnięcie do
  oryginalnej gry, która miała podobny motyw na ekranie tytułowym. To ma być
  **inspirowana reinterpretacja w naszym stylu art déco**, nie kopia obrazu.

**Prompt:**
```
Art Deco game logo title screen, elegant gold typography reading "VERMEER",
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
**Prompt (ikony pinezek, generować osobno per typ):**
```
Small game map pin icon of a [coffee plantation / stock exchange building /
horse racetrack / auction house / art academy], simple flat icon, transparent
background, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

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

**Prompt (szablon regionalny, podmieniać nawias):**
```
1920s [tropical Latin American port town / West African colonial port /
South Asian trading port / American heartland riverside town / grand
European capital street], establishing shot game background, warm afternoon
light, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

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
**Prompt (etap rośliny):**
```
[coffee / tobacco / tea / cocoa] plant, [seedling / growing / ready to
harvest] stage, isolated game sprite, simple flat illustration, transparent
background, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

### 4. Giełda
- Tło: sala giełdy / tablica z kursami
- Ikona wykresu/świec (UI, nie musi być z Leonardo — można zrobić natywnie w
  silniku), ale tło sceny i karty wydarzeń (krach, hossa) tak

**Prompt:**
```
1920s stock exchange trading floor, Art Deco architecture, chalkboard with
numbers, bustling brokers in background (silhouettes only, no detailed faces),
game background art, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```
**Prompt (karta zdarzenia gospodarczego):**
```
Vintage newspaper front page illustration, headline about stock market
[crash / boom / currency reform], Art Deco newspaper layout, game event card
art, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

### 5. Tor wyścigów konnych
- Tło toru
- Sylwetki 4–6 różnych koni + dżokejów (do prostej animacji przesuwania)

**Prompt (tło):**
```
1920s horse racetrack, grandstands with spectators (silhouettes), starting
gate, side-view racing background for 2D game, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```
**Prompt (koń + dżokej):**
```
Side-view horse and jockey sprite in [color] racing silks, running pose,
isolated on transparent background, simple flat game sprite,
Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

### 6. Dom aukcyjny
- Tło sali aukcyjnej
- Portrety 4–6 rywali (AI) w stylu epoki, do dymków licytacyjnych
- Rama obrazu (pusta, do wstawienia grafiki obrazu w środku)
- 40 unikalnych "obrazów" (to największy pakiet — patrz niżej)

**Prompt (tło):**
```
Elegant 1920s auction house interior, Art Deco wood paneling, podium, gathered
silhouette crowd, single spotlighted empty easel in center, game background
art, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```
**Prompt (portret rywala):**
```
1920s art collector character portrait, [male/female], distinctive [top hat /
monocle / feather boa] accessory, bust portrait, game character icon,
Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Prompt (Vico Vermeer — nazwany rywal-fałszerz, patrz `MECHANIKI_EKONOMICZNE.md`
pkt. 9, generować 2–3 warianty min z tym samym seedem: neutralny/uśmiechnięty/
podejrzliwy, do scenek "Meanwhile"):**
```
1920s dapper art forger character portrait, sly confident smirk, slicked
hair, pencil moustache, fine tailored suit with pocket square, bust portrait,
game character icon, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

**Prompt (rama):**
```
Ornate gold Art Deco picture frame, empty center, isolated on transparent
background, game UI asset, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

### 7. 40 obrazów kolekcji (8 kategorii × 5 obrazów)

Pełna lista i numeracja: `docs/ZRODLA_C64_WIKI.md`. Zamiast jednego ogólnego
szablonu — **osobny prompt-szablon na każdą z 8 kategorii stylistycznych**,
tak żeby galeria realnie wyglądała jak przekrój historii sztuki (co jest
sensem tej mechaniki w oryginale). Nazwiska konkretnych malarzy z tabeli
źródłowej służą tylko jako **wewnętrzna wskazówka stylu dla nas** (część z
nich, np. Picasso czy Braque, wciąż podlega prawom autorskim w wielu krajach
— w promptach do Leonardo opisujemy więc **styl/okres**, nie generujemy
bezpośrednio "w stylu [nazwisko]").

Każda z 40 grafik NIE dostaje "Base style tag" gry — mają wyglądać jak
prawdziwe malarstwo muzealne, nie jak ikony gry, żeby kontrastowały z resztą
UI.

**1) Vermeer (obrazy 1–5)** — malarstwo holenderskie złotego wieku:
```
17th century Dutch Golden Age genre painting, domestic interior scene, soft
window light, muted earthy palette, oil painting texture, intimate
composition, museum piece, square canvas, no frame
```

**2) Barok (6–10):**
```
Baroque oil painting, dramatic chiaroscuro lighting, rich dark background,
opulent fabric and gesture, portrait or group scene, oil painting texture,
museum piece, square canvas, no frame
```

**3) Klasycyzm (11–15):**
```
Neoclassical oil painting, balanced formal composition, clean idealized
figures, restrained noble color palette, historical or genre subject, oil
painting texture, museum piece, square canvas, no frame
```

**4) Romantyzm (16–20):**
```
Romantic era oil painting, dramatic sky and landscape, sublime nature,
emotional atmosphere, sweeping brushwork, oil painting texture, museum piece,
square canvas, no frame
```

**5) Impresjonizm (21–25):**
```
Impressionist oil painting, loose visible brushstrokes, dappled natural
light, outdoor or garden scene, vibrant pastel palette, oil painting texture,
museum piece, square canvas, no frame
```

**6) Symbolizm (26–30):**
```
Symbolist oil painting, dreamlike mysterious mood, decorative ornamental
detail, muted jewel-tone palette, allegorical figure or landscape, oil
painting texture, museum piece, square canvas, no frame
```

**7) Ekspresjonizm (31–35):**
```
Expressionist oil painting, bold distorted forms, intense unnatural color
contrasts, emotional raw brushwork, early 20th century avant-garde, oil
painting texture, museum piece, square canvas, no frame
```

**8) Moderna (36–40):**
```
Early modernist oil painting, simplified geometric forms, flattened
perspective, bold unconventional color blocks, early 20th century avant-garde
composition, oil painting texture, museum piece, square canvas, no frame
```

Do konkretnego obrazu dopisz temat z zamiennika: `subject: [portrait of a
woman / countryside landscape / bowl of fruit / harbor scene / self-portrait
/ still life with flowers]`.

Do wariantu "podróbka" tego samego obrazu: powtórz prompt z tym samym seedem,
dopisując `slightly different brushwork, subtle color mismatch, forged
reproduction` — przyda się do mechaniki rozpoznawania fałszywek.

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

### 10. UI ogólne
- Przyciski, ramki paneli, ikony waluty, ikony statystyk (kapitał, ekspertyza,
  data), pasek postępu aukcji

**Prompt:**
```
Art Deco UI panel frame with geometric gold border ornamentation, empty
center for text, transparent background, mobile game UI element,
Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
```

## Gotowe prompty do wklejenia — priorytet 2 (tła 6 pozostałych ekranów)

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

**2. Dom aukcyjny** (`auction_house.jpg`)
```
Elegant 1920s auction house interior, Art Deco wood paneling, podium, gathered silhouette crowd, single spotlighted empty easel in center, game background art, Art Deco 1920s illustration style, warm sepia and gold palette with deep green, burgundy and turquoise accents, flat vector-gouache texture, subtle paper grain, elegant geometric ornamentation, mobile game asset, clean silhouette, no photorealism
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

Jak wygenerujesz i wybierzesz najlepsze — wyślij mi je (tak jak menu główne i
mapę), a podepnę je w kodzie tych sześciu ekranów tym samym sposobem, co przy
menu głównym/Hubie.

## Plan produkcji — pełna lista do odhaczania

Kolejność = priorytet (1 = rób najpierw). "Szt." to liczba **unikalnych**
finalnych grafik (nie liczba generacji — na każdą liczyć ~4 generacje w
Leonardo, żeby mieć z czego wybrać).

| # | Priorytet | Asset | Szt. | Format / proporcje | Sekcja promptu | Status |
|---|---|---|---|---|---|---|
| 1 | 1 | Obraz referencyjny stylu / tło menu głównego | 1 | 16:9, docelowo 1920×1080 | §1 | ✅ zrobione (`main_menu_title.jpg`) |
| 2 | 1 | Logo "VERMEER" | 1 | dowolne, PNG transparent | §1 | ⏸ zastąpione na razie tekstem w kodzie (Label), nie pilne |
| 3a | **2 (następne)** | Tło Plantacji | 1 | 16:9, 1920×1080 | §3 | ⬜ do zrobienia |
| 3b | **2 (następne)** | Tło Domu aukcyjnego | 1 | 16:9, 1920×1080 | §6 | ⬜ do zrobienia |
| 3c | 2 | Tło Giełdy | 1 | 16:9, 1920×1080 | §4 | ⬜ do zrobienia |
| 3d | 2 | Tło Wyścigów | 1 | 16:9, 1920×1080 | §5 | ⬜ do zrobienia |
| 3e | 2 | Tło Szkoły sztuki | 1 | 16:9, 1920×1080 | §8 | ⬜ do zrobienia |
| 3f | 2 | Tło Galerii | 1 | 16:9, 1920×1080 | §9 | ⬜ do zrobienia |
| — | — | Tło Mapy świata (Hub) | 1 | 16:9, 1920×1080 | §2 | ✅ zrobione (`hub_map.jpg`) |
| 4 | 3 (opcjonalnie) | Szablony regionalne teł miast (osobny ekran "przyjazdu" do miasta — na razie nieużywane) | 5 | 16:9, 1920×1080 | §2.1 | ⬜ opcjonalne, niski priorytet |
| 5 | — | ~~Ikony pinezek mapy~~ | — | — | §2 | ✅ **rozwiązane w kodzie**, nie generować — Leonardo uparcie robiło pełne sceny zamiast ikon, więc pinezki są teraz rysowane natywnie w Godocie (`MapPin.gd`), bez grafiki |
| 6 | 3 | Ramka obrazu (do aukcji/galerii) | 1 | 1:1, transparent | §6 | ⬜ do zrobienia |
| 7 | 3 | Elementy UI ogólne (panel, ramka, ikony statystyk) | ~6 | 1:1, transparent | §10 | ⬜ do zrobienia — **uwaga**, ten sam typ zadania co pinezki (mały, wyizolowany element), może mieć ten sam problem ze "sceną" |
| 8 | 4 | Portrety rywali AI (w tym Vico, 2–3 warianty mimiki) | ~7 | 3:4, transparent lub jednolite tło | §6 | ⬜ do zrobienia — portrety zwykle nie mają problemu ze "sceną" |
| 9 | 4 | Fazy wzrostu roślin (4 uprawy × 3 fazy) | 12 | 1:1, 512×512, transparent | §3 | ⬜ do zrobienia — **uwaga**, jak pinezki: mały wyizolowany obiekt, ryzyko tego samego problemu |
| 10 | 5 | Konie + dżokeje (różne barwy jeźdźców) | 4–6 | 1:1 lub 4:3, transparent | §5 | ⬜ do zrobienia |
| 11 | 6 | 40 obrazów kolekcji (na końcu, seriami po 5 per kategoria) | 40 | 1:1, min. 1024×1024 | §7 | ⬜ do zrobienia, na sam koniec |
| 12 | 7 (opcjonalnie) | Warianty "fałszywka" wybranych obrazów (do szkoły sztuki) | ~8–10 | 1:1, jak oryginał | §7, §8 | ⬜ opcjonalne |

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
kodzie (np. `backgrounds/hub_map.png`, `characters/vico_smirk.png`,
`paintings/painting_06_rembrandt.png`), żeby łatwo było je później podpiąć
w skryptach ekranów.
