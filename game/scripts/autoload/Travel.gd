extends Node
## Stan podróży gracza — aktualna lokalizacja, trasa w toku i pozostałe dni.
## Wieloetapowa podróż (przesiadki) jest liczona automatycznie przez
## Cities.find_route. Postęp podróży posuwa się wraz z każdym
## Calendar.advance_days (Hub "Tydzień naprzód", kurs w Szkole Sztuki itd.)
## Patrz docs/MECHANIKI_EKONOMICZNE.md pkt. 2.

signal departed(route: Array, total_days: float)
signal arrived(city_id: String)

const START_CITY := "london"  ## zgodnie z realiami startu gry (1 stycznia 1918)

var current_city: String = START_CITY
var route: Array[String] = []  ## pozostałe przystanki do odwiedzenia (bez aktualnego miasta)
var days_remaining: float = 0.0


func _ready() -> void:
	Calendar.day_advanced.connect(_on_day_advanced)


func reset_new_game() -> void:
	current_city = START_CITY
	route.clear()
	days_remaining = 0.0


func is_traveling() -> bool:
	return not route.is_empty()


## Rozpoczyna podróż do destination_city (może obejmować kilka przesiadek).
## Zwraca false, jeśli już w podróży albo miasto nieosiągalne.
func start_travel(destination_city: String) -> bool:
	if is_traveling() or destination_city == current_city:
		return false
	var result := Cities.find_route(current_city, destination_city)
	var path: Array = result["path"]
	if path.is_empty():
		return false

	route.clear()
	for i in range(1, path.size()):
		route.append(path[i])
	days_remaining = Cities.get_travel_days(current_city, route[0])
	departed.emit(route.duplicate(), result["total_days"])
	return true


func get_destination() -> String:
	return route[-1] if is_traveling() else ""


func _on_day_advanced(days_elapsed: int, _current_day: int) -> void:
	if not is_traveling():
		return
	days_remaining -= days_elapsed
	while is_traveling() and days_remaining <= 0.0:
		var leftover_days: float = -days_remaining
		current_city = route.pop_front()
		arrived.emit(current_city)
		if is_traveling():
			days_remaining = Cities.get_travel_days(current_city, route[0]) - leftover_days
		else:
			days_remaining = 0.0
