extends Node
## Globalny kalendarz gry. Uproszczony model turowy z upływem dni
## (patrz docs/MECHANIKI_EKONOMICZNE.md pkt. 8 — pełny event-driven
## scheduler oryginału to rozważane rozszerzenie post-MVP).

signal day_advanced(current_day: int)
signal new_year(year: int)  ## okazja do Noworocznej Loterii (GDD 4.8)

const START_YEAR := 1918
const START_MONTH := 1
const START_DAY := 1
const DAYS_PER_MONTH := 30  ## uproszczenie: miesiąc w grze = 30 dni

var current_day: int = 0  ## dni od startu gry


func reset_new_game() -> void:
	current_day = 0


func advance_days(n: int) -> void:
	var prev_year := get_year()
	current_day += n
	day_advanced.emit(current_day)
	var year := get_year()
	if year > prev_year:
		new_year.emit(year)


func get_year() -> int:
	return START_YEAR + int(current_day / (DAYS_PER_MONTH * 12))


func get_month() -> int:
	return 1 + int((current_day / DAYS_PER_MONTH)) % 12


func get_day_of_month() -> int:
	return 1 + current_day % DAYS_PER_MONTH


func get_date_string() -> String:
	return "%02d.%02d.%d" % [get_day_of_month(), get_month(), get_year()]
