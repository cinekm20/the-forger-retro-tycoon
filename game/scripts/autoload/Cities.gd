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


## Pozycje pinezek na mapie świata — ułamek szerokości/wysokości ekranu
## (0,0 = lewy górny róg). Skalibrowane bezpośrednio na pikselach
## game/art/backgrounds/hub_map.jpg (1368×768) — dla każdego miasta
## znaleziono piksel leżący na właściwym lądzie na TYM konkretnym obrazku
## (analiza kolorów: ląd = odcienie niebiesko-turkusowe, morze = beż/sepia),
## nie na czystej geografii w oderwaniu od grafiki. Poprzednie wartości były
## szacowane "na ślepo" bez podglądu grafiki i wypadały w oceanie/złym
## miejscu (zgłoszone przez użytkownika na zrzucie ekranu).
##
## Zweryfikowane ponownie programowo (próbkowanie koloru piksela pod każdą
## z tych współrzędnych) po kolejnym zgłoszeniu użytkownika — berlin i
## st_louis faktycznie wypadały na kolorze morza (beż), mimo że reszta miast
## była poprawna; poprawione na najbliższy ląd w promieniu kilku pikseli od
## oryginalnej pozycji (patrz też TravelMap.gd — pinezki są teraz zakotwiczone
## na tych ułamkach przez anchor_left/right/top/bottom, więc RAZ dobrze
## skalibrowane współrzędne zostają poprawne przy każdej rozdzielczości).
##
## Kolejna poprawka: berlin/paryż/amsterdam/londyn (region "europe") leżały
## wszystkie na wąskim, wysuniętym na północ półwyspie przypominającym
## Norwegię/Skandynawię (zgłoszone przez użytkownika: "londyn, paryż i
## amsterdam lądują w norwegii") — przesunięte wtedy w dół, ale za daleko: na
## szeroki ląd, który jest wizualnie Afryką (zgłoszone: "a teraz są w
## Afryce"). Przesunięte na wąski pas lądu POMIĘDZY tymi dwoma skrajnościami,
## a potem jeszcze trochę wyżej (bliżej nasady półwyspu, ale wciąż na
## jednoznacznie kontynentalnym lądzie, nie na samej wąskiej odnodze) —
## zgłoszone przez użytkownika: "jeszcze trochę wyżej te europejskie". Nadal
## wymagając "głębokiego lądu" (margines koloru ląd/morze dodatni w całym
## promieniu ~6px wokół punktu, nie tylko w jednym pikselu), żeby nie trafić
## na wąski przesmyk/zatoczkę widoczny dokładnie w tym pasie.
const MAP_POSITION := {
	"berlin": Vector2(0.55, 0.327),
	"paris": Vector2(0.493, 0.405),
	"amsterdam": Vector2(0.539, 0.361),
	"lisbon": Vector2(0.48, 0.42),
	"london": Vector2(0.526, 0.367),
	"ankara": Vector2(0.60, 0.31),
	"bombay": Vector2(0.66, 0.49),
	"colombo": Vector2(0.67, 0.53),
	"mombasa": Vector2(0.59, 0.58),
	"duala": Vector2(0.52, 0.54),
	"abidjan": Vector2(0.48, 0.52),
	"rio": Vector2(0.41, 0.68),
	"bogota": Vector2(0.36, 0.55),
	"guatemala": Vector2(0.33, 0.51),
	"mexico": Vector2(0.29, 0.46),
	"new_york": Vector2(0.38, 0.33),
	"richmond": Vector2(0.36, 0.31),
	"st_louis": Vector2(0.307, 0.302),
}


func get_map_position(city_id: String) -> Vector2:
	return MAP_POSITION.get(city_id, Vector2(0.5, 0.5))


const MAP_BACKGROUND_PATH := "res://art/backgrounds/hub_map.jpg"

## Tła wg regionu (docs/GRAFIKA_LEONARDO.md §2.1). south_america i
## central_america dzielą jeden szablon "tropikalny port" (Rio/Bogota/
## Gwatemala/Meksyk w oryginalnym planie to jedna grupa stylistyczna, mimo
## dwóch różnych kluczy region). Współdzielone przez Hub.gd (tło aktualnej
## lokalizacji) i TravelAnimation.gd (zoom-in na tło miasta docelowego).
const REGION_BACKGROUNDS := {
	"europe": "res://art/backgrounds/region_europe.jpg",
	"south_america": "res://art/backgrounds/region_tropical_port.jpg",
	"central_america": "res://art/backgrounds/region_tropical_port.jpg",
	"africa": "res://art/backgrounds/region_africa.jpg",
	"asia": "res://art/backgrounds/region_asia.jpg",
	"north_america": "res://art/backgrounds/region_north_america.jpg",
}
const FALLBACK_BACKGROUND := "res://art/backgrounds/hub_map.jpg"

## Tła unikalne dla konkretnego miasta (docs/GRAFIKA_LEONARDO.md §2.2) —
## każde z 18 miast ma własną, rozpoznawalną grafikę (charakterystyczny
## zabytek/ulica) zamiast dzielenia jednego szablonu regionalnego z kilkoma
## innymi miastami. Miasto bez wpisu tutaj spadłoby do get_region_background().
const CITY_BACKGROUNDS := {
	"berlin": "res://art/backgrounds/city_berlin.jpg",
	"paris": "res://art/backgrounds/city_paris.jpg",
	"amsterdam": "res://art/backgrounds/city_amsterdam.jpg",
	"lisbon": "res://art/backgrounds/city_lisbon.jpg",
	"london": "res://art/backgrounds/city_london.jpg",
	"ankara": "res://art/backgrounds/city_ankara.jpg",
	"bombay": "res://art/backgrounds/city_bombay.jpg",
	"colombo": "res://art/backgrounds/city_colombo.jpg",
	"mombasa": "res://art/backgrounds/city_mombasa.jpg",
	"duala": "res://art/backgrounds/city_duala.jpg",
	"abidjan": "res://art/backgrounds/city_abidjan.jpg",
	"rio": "res://art/backgrounds/city_rio.jpg",
	"bogota": "res://art/backgrounds/city_bogota.jpg",
	"guatemala": "res://art/backgrounds/city_guatemala.jpg",
	"mexico": "res://art/backgrounds/city_mexico.jpg",
	"new_york": "res://art/backgrounds/city_new_york.jpg",
	"richmond": "res://art/backgrounds/city_richmond.jpg",
	"st_louis": "res://art/backgrounds/city_st_louis.jpg",
}


func get_region_background(city_id: String) -> String:
	var region: String = CITIES.get(city_id, {}).get("region", "")
	return REGION_BACKGROUNDS.get(region, FALLBACK_BACKGROUND)


## Preferuje tło konkretnego miasta (CITY_BACKGROUNDS), spada do tła
## regionalnego, jeśli to miasto nie ma jeszcze własnej grafiki. To
## docelowa funkcja do wywoływania z Hub.gd/TravelAnimation.gd — zastępuje
## get_region_background() jako główne źródło tła lokalizacji.
func get_city_background(city_id: String) -> String:
	return CITY_BACKGROUNDS.get(city_id, get_region_background(city_id))


## Wszyscy sąsiedzi miasta z bezpośrednią trasą (w obie strony macierzy).
func get_direct_neighbors(city_id: String) -> Dictionary:
	var neighbors := {}
	if TRAVEL_DAYS.has(city_id):
		for other in TRAVEL_DAYS[city_id]:
			neighbors[other] = TRAVEL_DAYS[city_id][other]
	for other in TRAVEL_DAYS:
		if TRAVEL_DAYS[other].has(city_id):
			neighbors[other] = TRAVEL_DAYS[other][city_id]
	return neighbors


## Najkrótsza trasa (Dijkstra) między dwoma miastami — dane źródłowe nie mają
## bezpośredniej trasy dla każdej pary (patrz get_travel_days), więc realna
## podróż często wymaga przesiadki (np. przez Londyn). Zwraca
## {"path": [miasto, miasto, ...], "total_days": float}, albo pustą ścieżkę
## i total_days = -1.0, jeśli miasto jest nieosiągalne.
func find_route(from_city: String, to_city: String) -> Dictionary:
	if from_city == to_city:
		return {"path": [from_city], "total_days": 0.0}

	var distances := {}
	var previous := {}
	var unvisited := {}
	for city_id in CITIES.keys():
		distances[city_id] = INF
		unvisited[city_id] = true
	distances[from_city] = 0.0

	while not unvisited.is_empty():
		var current := ""
		var current_dist := INF
		for city_id in unvisited:
			if distances[city_id] < current_dist:
				current_dist = distances[city_id]
				current = city_id
		if current == "" or current_dist == INF:
			break
		unvisited.erase(current)
		if current == to_city:
			break
		var neighbors := get_direct_neighbors(current)
		for neighbor in neighbors:
			var alt: float = distances[current] + neighbors[neighbor]
			if alt < distances.get(neighbor, INF):
				distances[neighbor] = alt
				previous[neighbor] = current

	if distances.get(to_city, INF) == INF:
		return {"path": [], "total_days": -1.0}

	var path: Array[String] = []
	var step := to_city
	while step != from_city:
		path.push_front(step)
		step = previous[step]
	path.push_front(from_city)
	return {"path": path, "total_days": distances[to_city]}
