extends Node
## Globalny kalendarz gry. Uproszczony model turowy z upływem dni
## (patrz docs/MECHANIKI_EKONOMICZNE.md pkt. 8 — pełny event-driven
## scheduler oryginału to rozważane rozszerzenie post-MVP).

signal day_advanced(days_elapsed: int, current_day: int)
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
	day_advanced.emit(n, current_day)
	var year := get_year()
	if year > prev_year:
		new_year.emit(year)


func get_year() -> int:
	@warning_ignore("integer_division")  ## celowe: liczymy pełne lata z dni
	return START_YEAR + current_day / (DAYS_PER_MONTH * 12)


func get_month() -> int:
	@warning_ignore("integer_division")  ## celowe: liczymy pełne miesiące z dni
	return 1 + (current_day / DAYS_PER_MONTH) % 12


## Miesiąc DOWOLNEGO dnia (nie tylko current_day) — mirror get_month(),
## potrzebne np. dla plantacji liczonych wg dnia AKTYWNEGO GRACZA
## (Players.active_day()), nie globalnego zegara (patrz Tor B w
## per-graczowej architekturze czasu, PlayerPlantations.gd).
func get_month_for_day(day: int) -> int:
	@warning_ignore("integer_division")
	return 1 + (day / DAYS_PER_MONTH) % 12


func get_day_of_month() -> int:
	return 1 + current_day % DAYS_PER_MONTH


func get_date_string() -> String:
	return format_day(current_day)


## Formatuje DOWOLNY dzień (nie tylko current_day) tym samym schematem co
## get_date_string() — potrzebne dla dat w przyszłości/przeszłości, np.
## zaplanowanego terminu aukcji w Auctions.gd ("NEXT AUCTION IS: 17.1.1918").
func format_day(day: int) -> String:
	@warning_ignore("integer_division")
	var month_index := (day / DAYS_PER_MONTH) % 12
	@warning_ignore("integer_division")
	var year := START_YEAR + day / (DAYS_PER_MONTH * 12)
	var day_of_month := 1 + day % DAYS_PER_MONTH
	return "%02d.%02d.%d" % [day_of_month, 1 + month_index, year]
