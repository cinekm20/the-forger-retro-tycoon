# Vermeer — remake na Androida

Graficzny remake ekonomicznej gry strategicznej *Vermeer* (Ariolasoft,
1987, C64) — na Androida, w Godot 4. Gracz jako spadkobierca odbudowuje
fortunę (plantacje, giełda, wyścigi) i wykupuje na aukcjach rozproszoną
kolekcję 40 obrazów wuja Walthera von Grünschilda, rywalizując z fałszerzem
Vico Vermeerem i innymi spadkobiercami.

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

Szkielet Godot 4 — **logicznie kompletny i grywalny już teraz**, tylko bez
grafiki (samo UI: przyciski, etykiety, listy). Wszystkie 7 ekranów działa:
mapa świata z podróżami między miastami (z przesiadkami), plantacje (siatka
pól, bonus rzeki, robotnicy, zbiory), giełda (akcje + kontrakty terminowe),
dom aukcyjny (licytacja przeciw AI, w tym Vico), szkoła sztuki
(eksperckość), wyścigi konne, galeria. Ma pętlę wygrana/przegrana
(kompletna kolekcja / bankructwo / rywal wygrywa pierwszy) i zapis/odczyt
gry.

Jak uruchomić: `game/README.md`.

## Status i następne kroki

1. ✅ Projekt gry (GDD)
2. ✅ Szkielet Godot z pełną logiką wszystkich systemów
3. ⏳ Grafiki (Leonardo.ai) — plan gotowy w `docs/GRAFIKA_LEONARDO.md`,
   generowanie po stronie użytkownika
4. ⏳ Podpięcie grafik pod istniejące ekrany
5. ⏳ Eksport na Androida (konfiguracja startowa: `game/export_presets.cfg`)
