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
- **`ZRODLA_C64_WIKI.md`**, **`PODSUMOWANIE_ARTYKULU.md`** — materiały
  źródłowe z c64-wiki.de (streszczone/sparafrazowane, nie przedrukowane —
  to cudza, licencjonowana treść).

## Gra (`game/`)

Godot 4 — **logicznie kompletny i grywalny**, większość ekranów ma już
podpiętą docelową grafikę tła (`docs/GRAFIKA_LEONARDO.md`). Ekrany: Hub +
osobna mapa świata z podróżami między miastami (z przesiadkami i animacją
podróży), plantacje (siatka 16×16 z losową rzeką, bonus rzeki, robotnicy,
zbiory) + Spichlerz (zbiorczy magazyn upraw), giełda (akcje + kontrakty
terminowe), dom aukcyjny (licytacja wg stałego harmonogramu przeciw 3
rywalom AI, w tym Vico, z wizualnie odrębnymi fałszywkami dla części
obrazów), szkoła sztuki (eksperckość), wyścigi konne, galeria (+ system
ochrony/kradzieży), ustawienia (wybór języka). Ma pętlę wygrana/przegrana
(kompletna kolekcja / bankructwo / rywal wygrywa pierwszy), hot-seat
multiplayer do 4 graczy, zapis/odczyt gry i pełny interfejs w trzech
językach (polski/angielski/niemiecki).

Jak uruchomić: `game/README.md`.

## Status i następne kroki

1. ✅ Projekt gry (GDD)
2. ✅ Szkielet Godot z pełną logiką wszystkich systemów + multiplayer,
   lokalizacja PL/EN/DE, zapis/odczyt
3. ✅ Grafiki (Leonardo.ai) — większość teł ekranów, wszystkie tła miast (18)
   i wszystkie 40 obrazów kolekcji już wygenerowane i podpięte; status
   szczegółowy (co jeszcze zostało: ramka obrazu, część ikon UI, portrety
   rywali, fazy wzrostu roślin, konie/dżokeje) w tabeli "Plan produkcji" w
   `docs/GRAFIKA_LEONARDO.md`
4. ✅ Podpięcie gotowych grafik pod ekrany
5. ✅ Eksport APK działa (`.github/workflows/android-build.yml`, debug
   keystore) — podpisywanie pod Google Play/AAB wciąż do zrobienia
