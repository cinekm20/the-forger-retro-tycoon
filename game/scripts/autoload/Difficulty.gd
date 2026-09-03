extends Node
## Poziom trudności — JEDEN wspólny wybór na całą rozgrywkę (nie per gracz,
## zgłoszone przez użytkownika: "jeden wspólny poziom trudności dla całej
## gry"), wybierany WYŁĄCZNIE przy zakładaniu nowej gry (MainMenu.gd), nie
## zmienialny w trakcie. Zastępuje dawny osobny checkbox "tryb łatwy" —
## `is_easy_win()` niżej daje dokładnie tę samą wartość, jaką dawniej dawał
## ten checkbox wprost.
##
## Steruje TRZEMA osiami naraz, każda pochodna z tego samego poziomu:
## - risk_multiplier(): mnoży WSZYSTKIE tygodniowe szanse na negatywne
##   zdarzenia losowe (pogoda, niepokoje regionalne, konfiskata przemytu,
##   kradzież obrazu bez ochrony, złapanie własnego gangstera, reforma
##   walutowa, krach/hossa na giełdzie) — 0.0 na najłatwiejszym poziomie
##   wyłącza je CAŁKOWICIE (randf() nigdy nie jest ujemne, więc
##   `randf() < cokolwiek * 0.0` nigdy nie jest prawdą). TA SAMA wartość
##   skaluje też SUROWOŚĆ skutków, gdy już do nich dojdzie (patrz
##   PlayerPlantations._apply_crisis_hit) — zgłoszone przez użytkownika jako
##   część tego samego pakietu "mniej losowych rzeczy" na łatwiejszych
##   poziomach, nie tylko rzadsze, ale i łagodniejsze.
## - yield_multiplier(): mnoży plon z plantacji (PlayerPlantations.calculate_harvest)
##   — zgłoszone przez użytkownika: "więcej musi rosnąć na plantacjach,
##   nawet w najtrudniejszym poziomie, a w najłatwiejszym sporo więcej",
##   bo dotychczasowy (niezmieniony na poziomie VERY_HARD) balans "nic nie
##   dawał". VERY_HARD i tak dostaje ×1,5 względem starego balansu, nie ×1 —
##   to CELOWE, nie błąd.
## - is_easy_win(): próg zwycięstwa 15/40 zamiast 40/40 (Paintings.EASY_WIN_THRESHOLD)
##   na dwóch najłatwiejszych poziomach — dokładnie to, co dawniej robił
##   sam checkbox "tryb łatwy".
##
## VERY_HARD = dzisiejszy, niezmieniony balans ryzyka (mnożnik 1.0) —
## zgłoszone przez użytkownika: "tak jak teraz to musi być najtrudniejszy
## poziom" — więc domyślna wartość `level` (na wypadek odczytu przed
## reset_new_game(), np. stary zapis sprzed tej mechaniki, patrz SaveGame.gd)
## to właśnie VERY_HARD, nie NORMAL — brak jawnego wyboru ma zachowywać się
## tak jak przed wprowadzeniem tej funkcji, nie po cichu ułatwiać grę.

enum Level { VERY_EASY, EASY, NORMAL, HARD, VERY_HARD }

const LEVEL_NAMES := {
	Level.VERY_EASY: "Bardzo łatwy",
	Level.EASY: "Łatwy",
	Level.NORMAL: "Normalny",
	Level.HARD: "Trudny",
	Level.VERY_HARD: "Bardzo trudny",
}

## Kolejność w OptionButton (MainMenu.gd) — od najłatwiejszego do
## najtrudniejszego, dopasowana do intuicyjnego porządku wyboru "im niżej,
## tym trudniej".
const LEVEL_ORDER: Array[int] = [Level.VERY_EASY, Level.EASY, Level.NORMAL, Level.HARD, Level.VERY_HARD]

const RISK_MULTIPLIER := {
	Level.VERY_EASY: 0.0,
	Level.EASY: 0.25,
	Level.NORMAL: 0.5,
	Level.HARD: 0.75,
	Level.VERY_HARD: 1.0,
}

const YIELD_MULTIPLIER := {
	Level.VERY_EASY: 4.0,
	Level.EASY: 3.0,
	Level.NORMAL: 2.5,
	Level.HARD: 2.0,
	Level.VERY_HARD: 1.5,
}

## Te same dwa poziomy, na których dawny checkbox "tryb łatwy" byłby
## zaznaczony.
const EASY_WIN_LEVELS: Array[int] = [Level.VERY_EASY, Level.EASY]

var level: int = Level.VERY_HARD


func reset_new_game(new_level: int) -> void:
	level = new_level


func risk_multiplier() -> float:
	return RISK_MULTIPLIER[level]


func yield_multiplier() -> float:
	return YIELD_MULTIPLIER[level]


func is_easy_win() -> bool:
	return level in EASY_WIN_LEVELS
