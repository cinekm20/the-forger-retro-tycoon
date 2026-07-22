extends Node
## Harmonogram aukcji — w oryginale gry aukcja odbywa się w JEDNYM konkretnym
## mieście w JEDNYM konkretnym dniu (patrz zrzut ekranu użytkownika: skrzynka
## "NEXT AUCTION IS: 17.1.1918 BERLIN"), a nie na żądanie gracza w dowolnej
## chwili — wcześniej przycisk "Nowa aukcja" w AuctionHouse.gd pozwalał kupować
## obrazy bez ograniczeń, co użytkownik zgłosił jako niezgodne z oryginałem.
## Ten autoload trzyma harmonogram; AuctionHouse.gd tylko go odczytuje.
## Patrz docs/MECHANIKI_EKONOMICZNE.md pkt. 9.

const MIN_DAYS_AHEAD := 4
const MAX_DAYS_AHEAD := 12

## Ile dni po terminie aukcja jeszcze "czeka" (gdyby gracz akurat dojeżdżał),
## zanim uznajemy ją za przegapioną i losujemy nowy termin automatycznie —
## bez tego, jeśli gracz po prostu stał w miejscu i nie odwiedził miasta
## aukcji, wyświetlana data następnej aukcji zostawała na zawsze w przeszłości
## (zgłoszone przez testera: "aktualną datę mam np. 27 stycznia, a poniżej
## informacja, że następna aukcja to 20 stycznia").
const MISSED_GRACE_DAYS := 3

var next_auction_city: String = ""
var next_auction_day: int = 0

## Obraz wystawiony na sprzedaż w bieżącym/najbliższym terminie — losowany
## dopiero przy pierwszym wejściu do otwartej aukcji (get_current_painting_number),
## nie z góry, ale ten sam numer zostaje przy kolejnych wejściach do tego
## samego terminu (np. gracz wraca do Hub w trakcie licytacji i wchodzi
## ponownie) — dopóki resolve_and_reschedule() go nie wyzeruje.
var current_painting_number: int = -1


func _ready() -> void:
	Calendar.day_advanced.connect(_on_day_advanced)


func reset_new_game() -> void:
	current_painting_number = -1
	_pick_new_schedule(0)


func _on_day_advanced(_days_elapsed: int, current_day: int) -> void:
	if next_auction_city != "" and current_day > next_auction_day + MISSED_GRACE_DAYS:
		current_painting_number = -1
		_pick_new_schedule(current_day)


func _pick_new_schedule(from_day: int) -> void:
	var auction_cities := Cities.get_auction_cities()
	next_auction_city = auction_cities[randi() % auction_cities.size()]
	next_auction_day = from_day + MIN_DAYS_AHEAD + randi() % (MAX_DAYS_AHEAD - MIN_DAYS_AHEAD + 1)


## Czy w podanym mieście trwa właśnie zaplanowana aukcja — termin nadszedł
## (albo minął, jeśli gracz spóźnił się i akurat tam jest) i jeszcze nie
## został rozstrzygnięty.
func is_open(city_id: String) -> bool:
	return city_id == next_auction_city and Calendar.current_day >= next_auction_day


func get_current_painting_number() -> int:
	if current_painting_number == -1:
		current_painting_number = 1 + randi() % Paintings.CATALOG.size()
	return current_painting_number


## Zamyka bieżący termin (ktoś wygrał albo nikt nie licytował) i losuje
## kolejny — inne miasto, dzień w przyszłości — żeby ten sam termin nie dało
## się rozstrzygać w nieskończoność.
func resolve_and_reschedule() -> void:
	current_painting_number = -1
	_pick_new_schedule(Calendar.current_day)


func get_schedule_string() -> String:
	return "Następna aukcja: %s — %s" % [
		Calendar.format_day(next_auction_day), Cities.get_city_name(next_auction_city),
	]


## Skraca planowany skok dni "Końca tury" (Players.DAYS_PER_TURN = 7 dni na
## raz), jeśli gracz stoi w mieście, gdzie ma się odbyć następna aukcja, a
## normalny skok przeleciałby od razu przez cały ten termin bez zatrzymania —
## użytkownik zgłosił, że stojąc w takim mieście i klikając "Koniec tury",
## nigdy nie trafiał dokładnie na dzień aukcji, żeby zdążyć wejść i
## zalicytować. Zwraca requested_days bez zmian, jeśli gracz jest gdzie
## indziej albo termin już minął (nic nie ma co ciąć).
func cap_turn_advance(requested_days: int, city_id: String) -> int:
	if city_id != next_auction_city or Calendar.current_day >= next_auction_day:
		return requested_days
	var days_to_auction := next_auction_day - Calendar.current_day
	return mini(requested_days, days_to_auction)
