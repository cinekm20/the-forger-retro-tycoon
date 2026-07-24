# Prompty na muzykę (Suno/Udio/podobne)

Ten plik zbiera prompty na ścieżki muzyczne w tym samym duchu co
`docs/GRAFIKA_LEONARDO.md` dla grafiki — jeden wpis na ekran/sytuację, gotowy
do wklejenia. `game/audio` jest na razie puste (patrz `GDD.md`), więc to
pierwszy komplet do wygenerowania.

**Format docelowy:** `.ogg` (Vorbis) — Godot 4 obsługuje natywnie i lepiej
kompresuje pętle niż mp3. Każdy utwór ma być **instrumentalny** (bez wokalu —
rozprasza przy dłuższym słuchaniu w tle) i **zapętlający się** (bez wyraźnego
wybrzmienia na końcu, żeby pętla nie było słychać). 60–90 sekund w pętli
wystarczy na każdy ekran.

**Wspólny sznyt stylistyczny** (dopisywać do każdego promptu): lata 20. XX
wieku, hot jazz / ragtime / swing, brzmienie epoki (gramofon, lekki szum
winylu), elegancki, ale nie ckliwy — to samo "art déco" co w warstwie
graficznej (`docs/GRAFIKA_LEONARDO.md`), tylko w dźwięku.

---

### 1. Ekran startowy (`MainMenu.gd`)
Uroczyste, zapraszające otwarcie — jak czołówka filmu z epoki.
```
1920s jazz age orchestral overture, grand welcoming main title theme, brass fanfare intro settling into elegant swing rhythm, piano and upright bass, warm vintage gramophone texture, instrumental, no vocals, sophisticated Art Deco mood, loopable, 90 seconds
```

### 2. Hub / mapa świata (`Hub.gd`, `TravelMap.gd`)
Spokojne tło pod nawigację między miastami — ma nie męczyć przy długim słuchaniu.
```
1920s cafe jazz loop, relaxed background ambiance, soft clarinet and piano over gentle walking bass, light brushed drums, unobtrusive and calm, subtle vintage vinyl crackle, instrumental, no vocals, seamless loop, 60-90 seconds
```

### 3. Plantacje / Spichlerz (`Plantation.gd`, `Warehouse.gd`)
Cieplejszy, bardziej "pracowity" nastrój — bez utraty klimatu epoki.
```
1920s jazz with a warm pastoral undertone, acoustic guitar and light percussion, relaxed work-song rhythm, gentle brass accents, tropical plantation atmosphere filtered through Art Deco elegance, instrumental, no vocals, loopable, 60-90 seconds
```

### 4. Dom aukcyjny (`AuctionHouse.gd`)
Napięcie licytacji — ma rosnąć w energii, nie usypiać.
```
1920s suspenseful jazz, tense staccato strings and piano building tension, ticking rhythmic pulse like an auctioneer's gavel, occasional swelling brass hit for dramatic bid moments, exciting but sophisticated, instrumental, no vocals, loopable, 60-90 seconds
```

### 5. Giełda / Rynek (`StockMarket.gd`, `Market.gd`)
Ruchliwa energia parkietu handlowego.
```
Fast-paced 1920s ragtime piano, driving rhythm section, energetic bustling trading-floor atmosphere, bright brass stabs, slightly frantic swing tempo, instrumental, no vocals, loopable, 60-90 seconds
```

### 6. Wyścigi konne (`Races.gd`)
Żywiołowe, galopujące tempo.
```
Upbeat 1920s big band swing, galloping rhythmic drive, triumphant brass stabs, energetic crowd excitement, fast tempo, instrumental, no vocals, loopable, 60-90 seconds
```

### 7. Zakończenie — wygrana (`Ending.gd`, win)
Wielki, satysfakcjonujący finał.
```
Triumphant 1920s big band finale, full brass fanfare, grand satisfying resolution, celebratory swing rhythm building to a warm orchestral climax, instrumental, no vocals, 60-90 seconds, not necessarily loopable (ending cue)
```

### 8. Zakończenie — przegrana / game over (`Ending.gd`, lose)
Stonowane, eleganckie zamknięcie, bez taniej melancholii.
```
Melancholic solo piano with muted trumpet, slow tempo, understated 1920s jazz ballad, bittersweet and elegant, quiet vintage gramophone texture, instrumental, no vocals, 45-60 seconds, not necessarily loopable (ending cue)
```

---

## Krótkie dźwięki UI (SFX, nie muzyka)

Oryginał miał (patrz `docs/PODSUMOWANIE_ARTYKULU.md`): sygnał przy nawigacji w
menu, wyższy dźwięk przy zatwierdzeniu wyboru, "tykanie" jak dalekopis przy
katalogowaniu obrazów. To osobna kategoria od pętli muzycznych wyżej —
krótkie (<1s) stingery raczej NIE wymagają generatora muzyki AI, prostszy
i szybszy będzie gotowy pakiet darmowych SFX (np. Kenney UI Audio, freesound.org)
niż generowanie ich od zera. Można do tego wrócić osobno, jeśli zależy Ci na
konkretnym brzmieniu z epoki (np. faktyczny dźwięk mechanicznego dalekopisu).
