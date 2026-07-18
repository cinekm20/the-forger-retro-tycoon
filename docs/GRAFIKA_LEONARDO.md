# Plan grafik — generowanie w Leonardo.ai

Dokument roboczy: lista wszystkich assetów graficznych potrzebnych do gry oraz
gotowe prompty pod Leonardo.ai, tak by wszystko trzymało spójny styl.

## Spójność stylu — najważniejsza zasada

Leonardo.ai generuje różne obrazy za każdym razem, więc żeby cała gra nie
wyglądała jak zbiór przypadkowych grafik:

1. **Zdefiniuj jeden "kotwiczący" prompt stylu** i doklejaj go do każdego
   promptu (patrz niżej: *Base style tag*).
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

### Base style tag (dokleić na końcu każdego promptu)

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

**Prompt:**
```
Art Deco game logo title screen, elegant gold typography reading "VERMEER",
1920s art collector silhouette standing before an easel, world map background,
[Base style tag]
```

### 2. Mapa świata (Hub)
- Stylizowana mapa świata jako plansza gry, z oznaczonymi lokacjami (plantacje,
  Nowy Jork, Londyn, tor wyścigowy, dom aukcyjny, szkoła sztuki)
- Osobne ikony-pinezki dla każdej lokacji

**Prompt (tło mapy):**
```
Stylized vintage world map game board, Art Deco cartography, sepia ocean,
gold coastlines, decorative compass rose, empty pins slots for cities,
top-down board game map, [Base style tag]
```
**Prompt (ikony pinezek, generować osobno per typ):**
```
Small game map pin icon of a [coffee plantation / stock exchange building /
horse racetrack / auction house / art academy], simple flat icon, transparent
background, [Base style tag]
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
[Base style tag]
```
**Prompt (etap rośliny):**
```
[coffee / tobacco / tea / cocoa] plant, [seedling / growing / ready to
harvest] stage, isolated game sprite, simple flat illustration, transparent
background, [Base style tag]
```

### 4. Giełda
- Tło: sala giełdy / tablica z kursami
- Ikona wykresu/świec (UI, nie musi być z Leonardo — można zrobić natywnie w
  silniku), ale tło sceny i karty wydarzeń (krach, hossa) tak

**Prompt:**
```
1920s stock exchange trading floor, Art Deco architecture, chalkboard with
numbers, bustling brokers in background (silhouettes only, no detailed faces),
game background art, [Base style tag]
```
**Prompt (karta zdarzenia gospodarczego):**
```
Vintage newspaper front page illustration, headline about stock market
[crash / boom / currency reform], Art Deco newspaper layout, game event card
art, [Base style tag]
```

### 5. Tor wyścigów konnych
- Tło toru
- Sylwetki 4–6 różnych koni + dżokejów (do prostej animacji przesuwania)

**Prompt (tło):**
```
1920s horse racetrack, grandstands with spectators (silhouettes), starting
gate, side-view racing background for 2D game, [Base style tag]
```
**Prompt (koń + dżokej):**
```
Side-view horse and jockey sprite in [color] racing silks, running pose,
isolated on transparent background, simple flat game sprite,
[Base style tag]
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
art, [Base style tag]
```
**Prompt (portret rywala):**
```
1920s art collector character portrait, [male/female], distinctive [top hat /
monocle / feather boa] accessory, bust portrait, game character icon,
[Base style tag]
```
**Prompt (rama):**
```
Ornate gold Art Deco picture frame, empty center, isolated on transparent
background, game UI asset, [Base style tag]
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
[Base style tag]
```

### 9. Galeria (kolekcja gracza)
- Tło pustej galerii + wariant "wypełnionej" (opcjonalnie kilka etapów
  zapełnienia)

**Prompt:**
```
Art Deco private gallery hall interior, marble floor, empty wall space for
hanging paintings, soft gallery lighting, elegant benches, game background
art, [Base style tag]
```

### 10. UI ogólne
- Przyciski, ramki paneli, ikony waluty, ikony statystyk (kapitał, ekspertyza,
  data), pasek postępu aukcji

**Prompt:**
```
Art Deco UI panel frame with geometric gold border ornamentation, empty
center for text, transparent background, mobile game UI element,
[Base style tag]
```

## Praktyczna kolejność generowania

1. Najpierw 1 grafika referencyjna stylu (logo lub ekran tytułowy) → ustal
   "Style Reference" w Leonardo.
2. Tła ekranów (7 sztuk) — największy wpływ na odbiór gry, rób je najpierw.
3. Ikony mapy i UI.
4. Postacie/portrety rywali.
5. Rośliny/plantacje (fazy wzrostu).
6. Konie.
7. 40 obrazów kolekcji — rób na końcu, seriami po ~5, żeby łatwiej kontrolować
   spójność rodziny (nie muszą pasować stylistycznie do reszty gry, tylko do
   siebie nawzajem).

## Format eksportu

- Tła: 1920×1080 lub 2048×1152 (potem skalowane w silniku)
- Ikony/sprite'y: kwadratowe, potęgi 2 (128×128, 256×256, 512×512), PNG z
  kanałem alfa
- Obrazy kolekcji: kwadrat 1:1, min. 1024×1024 (będą powiększane w widoku
  galerii/aukcji)
