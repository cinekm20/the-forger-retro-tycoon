# The Forger: Retro Tycoon — remake na Androida

Graficzny remake ekonomicznej gry strategicznej *Vermeer* (Ariolasoft,
1987, C64), teraz pod własnym tytułem *The Forger: Retro Tycoon* — na
Androida, w Godot 4. Gracz jako spadkobierca odbudowuje
fortunę (plantacje, giełda, wyścigi) i wykupuje na aukcjach rozproszoną
kolekcję 40 obrazów wuja Walthera von Rabensteina, rywalizując z fałszerzem
imieniem Vico Falsari i innymi spadkobiercami.

## Struktura repo

```
docs/   — dokumentacja projektowa (patrz niżej)
game/   — projekt Godot 4 (kod gry)
```

## Dokumentacja (`docs/`)

- **`GDD.md`** — dokument projektowy: ekrany, mechaniki, kierunek
  artystyczny, etapy budowy. Zacznij tutaj.
- **`MECHANIKI_EKONOMICZNE.md`** — pełne dane liczbowe z oryginału: mapa i
  czasy podróży, plony upraw, koszty transportu, linie żeglugowe, kontrakty
  terminowe, reformy walutowe.
- **`DODATKOWE_MECHANIKI.md`** — dodatkowe ustalenia (sezonowość zbiorów,
  bonus rzeki, kara za niedostarczony kontrakt, twist fabularny na
  zakończenie).
- **`GRAFIKA_LEONARDO.md`** — gotowe prompty i plan produkcji grafik w
  Leonardo.ai (spójny styl, ustawienia techniczne, checklista ~90 assetów).
- **`MUZYKA_PROMPTY.md`** — gotowe prompty na ścieżki muzyczne (Suno/Udio),
  jeden wpis na ekran/nastrój.
- **`ZRODLA_C64_WIKI.md`**, **`PODSUMOWANIE_ARTYKULU.md`** — materiały
  źródłowe z c64-wiki.de (streszczone/sparafrazowane, nie przedrukowane —
  to cudza, licencjonowana treść).

## Gra (`game/`)

Godot 4 — **logicznie kompletny i grywalny**, wszystkie ekrany mają już
podpiętą docelową grafikę tła (`docs/GRAFIKA_LEONARDO.md`) i muzykę
przełączającą się per ekran (`docs/MUZYKA_PROMPTY.md`). Ekrany: Hub +
osobna mapa świata z podróżami między miastami (z przesiadkami i animacją
podróży), plantacje (siatka 16×16 z losową rzeką, bonus rzeki, robotnicy,
zbiory) + Spichlerz (zbiorczy magazyn upraw), giełda (akcje + kontrakty
terminowe), dom aukcyjny (licytacja wg stałego harmonogramu przeciw 3
rywalom AI, w tym Vico, z wizualnie odrębnymi fałszywkami dla części
obrazów), szkoła sztuki (eksperckość), wyścigi konne, galeria (+ system
ochrony/kradzieży), ustawienia (wybór języka) — każdy z tych głównych
ekranów ma w prawym górnym rogu przycisk "?" z pełną instrukcją gry
(`scenes/instructions/Instructions.gd`), jedno wspólne źródło opisu
wszystkich mechanik. Ma pętlę wygrana/przegrana
(kompletna kolekcja / bankructwo / rywal wygrywa pierwszy), 5 poziomów
trudności wybieranych przy nowej grze (`Difficulty.gd` — skalują częstość
i surowość losowego ryzyka, plon z plantacji i próg zwycięstwa), hot-seat
multiplayer do 4 graczy, zapis/odczyt gry i pełny interfejs w trzech
językach (polski/angielski/niemiecki).

Jak uruchomić: `game/README.md`.

## Status i następne kroki

1. ✅ Projekt gry (GDD)
2. ✅ Szkielet Godot z pełną logiką wszystkich systemów + multiplayer,
   lokalizacja PL/EN/DE, zapis/odczyt
3. ✅ Grafiki (Leonardo.ai) — kompletne: wszystkie tła ekranów, wszystkie
   tła miast (18), wszystkie 40 obrazów kolekcji i 12 faz wzrostu roślin
   wygenerowane i podpięte; szczegóły w tabeli "Plan produkcji" w
   `docs/GRAFIKA_LEONARDO.md`
4. ✅ Podpięcie gotowych grafik pod ekrany
5. ✅ Muzyka (`docs/MUZYKA_PROMPTY.md`) — wszystkie 8 ścieżek wygenerowane i
   podpięte, przełączają się automatycznie per ekran (`Music.gd`)
6. ✅ Eksport APK debug działa (`.github/workflows/android-build.yml`,
   debug keystore, do szybkich instalacji testowych)
7. ✅ Build release `.aab` podpisany kluczem produkcyjnym
   (`.github/workflows/android-release-build.yml`) — auto-bump wersji,
   pierwsze wersje już wgrane do zamkniętego testu w Google Play Console
8. 🔄 W trakcie: zbieranie 12 testerów na 14 dni (wymóg Google Play dla
   nowych kont deweloperskich), zanim odblokuje się publikacja produkcyjna
