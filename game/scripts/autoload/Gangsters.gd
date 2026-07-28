extends Node
## Gangsterzy do wynajęcia przeciw rywalom (SecurityScreen.gd) — tożsamość
## (nazwa/portret) + szansa powodzenia, która dryfuje dziennie, DOKŁADNIE tak
## samo jak kursy koni (Horses.gd)/ceny towarów (Crops.gd/ShippingCompanies.gd).
## Zgłoszenie użytkownika: "niech dynamicznie się zmienia ten procent szansy,
## powiedzmy od 20 do 50" — szansa WSPÓLNA dla wszystkich graczy (Tor A,
## podłączony do Calendar.day_advanced, NIE do per-gracz
## Players.advance_active_player_time) — ten sam dzień = ta sama szansa,
## niezależnie który gracz akurat wysyła gangstera.
##
## Osobny autoload (nie stała w Security.gd) jest konieczny właśnie dlatego,
## że dryf ma płynąć cały czas w tle, także gdy gracz nie stoi na ekranie
## Ochrony — a skrypt sceny żyje tylko, gdy ta scena jest otwarta, autoloady
## żyją przez całą grę.

const GANGSTERS := {
	"vito": {"name": "Vito \"Brzytwa\"", "image": "res://art/gangsters/vito.jpg"},
	"rosa": {"name": "Rosa Cień", "image": "res://art/gangsters/rosa.jpg"},
	"karl": {"name": "Karl Żelazna Ręka", "image": "res://art/gangsters/karl.jpg"},
}

const STARTING_CHANCE := {
	"vito": 0.35,
	"rosa": 0.30,
	"karl": 0.40,
}

const DAILY_DRIFT_RANGE := 0.05  ## losowe wahanie szansy ±5% dziennie, ten sam wzorzec co Horses.DAILY_DRIFT_RANGE
## Zgłoszenie użytkownika: szansa ma się mieścić w przedziale 20-50%.
const MIN_CHANCE := 0.20
const MAX_CHANCE := 0.50

var current_chance: Dictionary = {}


func _ready() -> void:
	Calendar.day_advanced.connect(_on_day_advanced)


func reset_new_game() -> void:
	current_chance = STARTING_CHANCE.duplicate()


func get_success_chance(gangster_id: String) -> float:
	return current_chance.get(gangster_id, STARTING_CHANCE.get(gangster_id, 0.3))


func _on_day_advanced(days_elapsed: int, _current_day: int) -> void:
	var weeks: float = float(days_elapsed) / 7.0
	for gangster_id in GANGSTERS.keys():
		var change := randf_range(-DAILY_DRIFT_RANGE, DAILY_DRIFT_RANGE) * weeks
		current_chance[gangster_id] = clampf(get_success_chance(gangster_id) * (1.0 + change), MIN_CHANCE, MAX_CHANCE)
