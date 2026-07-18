extends Node
## Miasta na mapie świata i czasy podróży między nimi (w dniach).
## Dane liczbowe: docs/MECHANIKI_EKONOMICZNE.md pkt. 2.1.

const CITIES := {
	"berlin": {"name": "Berlin", "type": "auction", "region": "europe"},
	"paris": {"name": "Paryż", "type": "auction", "region": "europe"},
	"amsterdam": {"name": "Amsterdam", "type": "auction", "region": "europe"},
	"lisbon": {"name": "Lizbona", "type": "auction", "region": "europe"},
	"london": {"name": "Londyn", "type": "auction", "region": "europe"},
	"ankara": {"name": "Ankara", "type": "plantation", "region": "asia"},
	"bombay": {"name": "Bombaj", "type": "plantation", "region": "asia"},
	"colombo": {"name": "Colombo", "type": "plantation", "region": "asia"},
	"mombasa": {"name": "Mombasa", "type": "plantation", "region": "africa"},
	"duala": {"name": "Duala", "type": "plantation", "region": "africa"},
	"abidjan": {"name": "Abidżan", "type": "plantation", "region": "africa"},
	"rio": {"name": "Rio de Janeiro", "type": "plantation", "region": "south_america"},
	"bogota": {"name": "Bogota", "type": "plantation", "region": "south_america"},
	"guatemala": {"name": "Gwatemala", "type": "plantation", "region": "central_america"},
	"mexico": {"name": "Meksyk", "type": "plantation", "region": "central_america"},
	"new_york": {"name": "Nowy Jork", "type": "hub", "region": "north_america"},
	"richmond": {"name": "Richmond", "type": "plantation", "region": "north_america"},
	"st_louis": {"name": "St. Louis", "type": "plantation", "region": "north_america"},
}

## Macierz trójkątna (symetryczna) — każda para podana raz.
const TRAVEL_DAYS := {
	"berlin": {"ankara": 5.1, "london": 3.0, "lisbon": 5.5, "amsterdam": 1.5, "paris": 2.3},
	"paris": {"ankara": 6.5, "london": 1.5, "lisbon": 3.4, "amsterdam": 1.3},
	"amsterdam": {
		"new_york": 15.4, "mexico": 21.8, "guatemala": 20.5, "bogota": 18.8,
		"rio": 18.7, "abidjan": 11.0, "duala": 11.1, "mombasa": 14.1,
		"colombo": 17.5, "bombay": 15.6, "ankara": 6.5, "london": 1.5, "lisbon": 4.7,
	},
	"lisbon": {
		"new_york": 12.3, "mexico": 18.0, "guatemala": 16.5, "bogota": 14.3,
		"rio": 14.0, "abidjan": 6.9, "duala": 7.9, "mombasa": 12.5,
		"colombo": 17.9, "bombay": 16.5, "ankara": 8.1, "london": 4.1,
	},
	"london": {
		"new_york": 13.9, "mexico": 20.4, "guatemala": 19.2, "bogota": 17.6,
		"rio": 18.0, "abidjan": 10.8, "duala": 11.3, "mombasa": 14.8,
		"colombo": 18.7, "bombay": 16.9, "ankara": 7.8,
	},
	"ankara": {
		"new_york": 20.4, "mexico": 25.9, "guatemala": 24.4, "bogota": 21.7,
		"rio": 19.4, "abidjan": 10.4, "duala": 8.9, "mombasa": 9.0,
		"colombo": 11.1, "bombay": 9.2,
	},
	"bombay": {
		"new_york": 28.7, "mexico": 33.3, "guatemala": 31.5, "bogota": 28.1,
		"rio": 23.8, "abidjan": 15.5, "duala": 12.9, "mombasa": 8.1, "colombo": 2.5,
	},
	"colombo": {
		"new_york": 29.8, "mexico": 34.0, "guatemala": 32.1, "bogota": 28.5,
		"rio": 23.7, "abidjan": 15.9, "duala": 13.2, "mombasa": 7.7,
	},
	"mombasa": {
		"new_york": 23.2, "mexico": 26.7, "guatemala": 24.8, "bogota": 21.0,
		"rio": 16.0, "abidjan": 8.6, "duala": 5.9,
	},
	"duala": {
		"new_york": 17.4, "mexico": 20.9, "guatemala": 19.0, "bogota": 15.3, "rio": 11.1, "abidjan": 2.7,
	},
	"abidjan": {"new_york": 14.9, "mexico": 18.2, "guatemala": 16.3, "bogota": 12.6, "rio": 9.0},
	"rio": {"new_york": 14.1, "mexico": 13.3, "guatemala": 11.3, "bogota": 7.0},
	"bogota": {"new_york": 8.4, "mexico": 6.3, "guatemala": 4.3},
	"guatemala": {"new_york": 6.8, "mexico": 2.0},
	"mexico": {"new_york": 7.2},
	"new_york": {"st_louis": 3.1, "richmond": 1.9},
	"richmond": {"st_louis": 1.9},
}


## Zwraca liczbę dni podróży, albo -1 jeśli brak bezpośredniej trasy
## w danych źródłowych (w grze może to oznaczać konieczność przesiadki).
func get_travel_days(from_city: String, to_city: String) -> float:
	if from_city == to_city:
		return 0.0
	if TRAVEL_DAYS.has(from_city) and TRAVEL_DAYS[from_city].has(to_city):
		return TRAVEL_DAYS[from_city][to_city]
	if TRAVEL_DAYS.has(to_city) and TRAVEL_DAYS[to_city].has(from_city):
		return TRAVEL_DAYS[to_city][from_city]
	return -1.0


func get_city_name(city_id: String) -> String:
	return CITIES.get(city_id, {}).get("name", city_id)


func get_plantation_cities() -> Array:
	return CITIES.keys().filter(func(id): return CITIES[id]["type"] == "plantation")


func get_auction_cities() -> Array:
	return CITIES.keys().filter(func(id): return CITIES[id]["type"] == "auction")
