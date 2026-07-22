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

var next_auction_city: String = ""
var next_auction_day: int = 0

## Obraz wystawiony na sprzedaż w bieżącym/najbliższym terminie — losowany
## dopiero przy pierwszym wejściu do otwartej aukcji (get_current_painting_number),
## nie z góry, ale ten sam numer zostaje przy kolejnych wejściach do tego
## samego terminu (np. gracz wraca do Hub w trakcie licytacji i wchodzi
## ponownie) — dopóki resolve_and_reschedule() go nie wyzeruje.
var current_painting_number: int = -1


func reset_new_game() -> void:
	current_painting_number = -1
	_pick_new_schedule(0)


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
