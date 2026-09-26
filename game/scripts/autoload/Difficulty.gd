extends Node
## Poziom trudności — JEDEN wspólny wybór na całą rozgrywkę (nie per gracz,
## zgłoszone przez użytkownika: "jeden wspólny poziom trudności dla całej
## gry"), wybierany WYŁĄCZNIE przy zakładaniu nowej gry (MainMenu.gd), nie
## zmienialny w trakcie. Zastępuje dawny osobny checkbox "tryb łatwy" —
## `is_easy_win()` niżej daje dokładnie tę samą wartość, jaką dawniej dawał
## ten checkbox wprost.
##
## Steruje CZTEREMA osiami naraz, każda pochodna z tego samego poziomu:
## - risk_multiplier(): mnoży WSZYSTKIE tygodniowe szanse na negatywne
##   zdarzenia losowe (pogoda, niepokoje regionalne, konfiskata przemytu,
##   kradzież obrazu bez ochrony, złapanie własnego gangstera, reforma
##   walutowa, krach/hossa na giełdzie) — 0.0 na najłatwiejszym poziomie
##   wyłącza je CAŁKOWICIE (randf() nigdy nie jest ujemne, więc
##   `randf() < cokolwiek * 0.0` nigdy nie jest prawdą). TA SAMA wartość
##   skaluje też SUROWOŚĆ skutków, gdy już do nich dojdzie (patrz
##   PlayerPlantations._apply_crisis_hit) — zgłoszone przez użytkownika jako
##   część tego samego pakietu "mniej losowych rzeczy" na łatwiejszych
##   poziomach, nie tylko rzadsze, ale i łagodniejsze. Zgłoszone przez
##   użytkownika OSOBNO, później: "ogólnie wszędzie muszą być niższe poziomy
##   trudności" — VERY_HARD (1.0 -> 0.6) już NIE odtwarza dokładnie
##   dotychczasowego, niezmienionego balansu ryzyka (to był stan PRZED tym
##   zgłoszeniem, patrz historia komentarza niżej).
## - yield_multiplier(): mnoży plon z plantacji (PlayerPlantations.calculate_harvest)
##   — zgłoszone przez użytkownika: "więcej musi rosnąć na plantacjach,
##   nawet w najtrudniejszym poziomie, a w najłatwiejszym sporo więcej", a
##   później (to samo zgłoszenie "niższe poziomy trudności" jak wyżej)
##   podniesione o kolejny krok skali (VERY_HARD ×1,5 -> ×2,5, VERY_EASY
##   ×4,0 -> ×5,0).
## - is_easy_win(): próg zwycięstwa 15/40 zamiast 40/40 (Paintings.EASY_WIN_THRESHOLD)
##   na dwóch najłatwiejszych poziomach — dokładnie to, co dawniej robił
##   sam checkbox "tryb łatwy".
## - rival_bid_aggressiveness(): mnoży, jak wysoko rywale (AIPlayers.decide_bid)
##   są skłonni podbić licytację obrazu ponad jego szacunkową wartość —
##   zgłoszone przez użytkownika: "trzeba też zrobić rozróżnienie poziomu
##   trudności przy licytacji obrazu", potem obniżone o kolejny krok skali
##   tym samym zgłoszeniem "niższe poziomy trudności" (HARD ×1,0 -> ×0,75 —
##   już NIE odtwarza dokładnie balansu AIPlayers.decide_bid sprzed tej
##   całej mechaniki, to był stan PRZED tym zgłoszeniem).
##
## Domyślna wartość `level` (na wypadek odczytu przed reset_new_game(), np.
## stary zapis sprzed tej mechaniki, patrz SaveGame.gd) to NORMAL —
## zgłoszone przez użytkownika: "niech defaultowy to będzie poziom
## pośredni, czyli normalny".

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
	Level.EASY: 0.15,
	Level.NORMAL: 0.3,
	Level.HARD: 0.45,
	Level.VERY_HARD: 0.6,
}

const YIELD_MULTIPLIER := {
	Level.VERY_EASY: 5.0,
	Level.EASY: 4.0,
	Level.NORMAL: 3.5,
	Level.HARD: 3.0,
	Level.VERY_HARD: 2.5,
}

## Te same dwa poziomy, na których dawny checkbox "tryb łatwy" byłby
## zaznaczony.
const EASY_WIN_LEVELS: Array[int] = [Level.VERY_EASY, Level.EASY]

## Mnożnik skłonności rywali do podbijania licytacji (patrz komentarz
## nagłówkowy) — obniżony o kolejny krok skali (zgłoszenie "niższe poziomy
## trudności"), więc HARD=0,75 już NIE odtwarza dokładnie balansu
## AIPlayers.decide_bid sprzed tej mechaniki (to był stan sprzed tego
## zgłoszenia, ×1,0). Niżej rywale poddają się coraz szybciej, na
## VERY_HARD upierają się jeszcze bardziej i podbijają wyżej.
const RIVAL_AGGRESSIVENESS_MULTIPLIER := {
	Level.VERY_EASY: 0.3,
	Level.EASY: 0.45,
	Level.NORMAL: 0.6,
	Level.HARD: 0.75,
	Level.VERY_HARD: 0.9,
}

var level: int = Level.NORMAL


func reset_new_game(new_level: int) -> void:
	level = new_level


func risk_multiplier() -> float:
	return RISK_MULTIPLIER[level]


func yield_multiplier() -> float:
	return YIELD_MULTIPLIER[level]


func is_easy_win() -> bool:
	return level in EASY_WIN_LEVELS


func rival_bid_aggressiveness() -> float:
	return RIVAL_AGGRESSIVENESS_MULTIPLIER[level]
