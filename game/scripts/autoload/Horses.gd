extends Node
## Konie na torze wyścigowym (Races.gd) — tożsamość (nazwa/portret) + kurs,
## który TERAZ dryfuje dziennie (zgłoszenie użytkownika: "kursy nie zawsze
## mają być te same, jak na giełdzie i rynku"), zamiast być raz na zawsze
## ustawioną stałą jak wcześniej. Ten sam wzorzec dryfu co ShippingCompanies.gd/
## Crops.gd. Kurs jest WSPÓLNY dla wszystkich graczy (Tor A, podłączony do
## Calendar.day_advanced, NIE do per-gracz Players.advance_active_player_time)
## — ten sam dzień = ten sam kurs, niezależnie który gracz akurat stawia
## zakład, zgodnie z tą samą zasadą co ceny towarów/akcji.
##
## Osobny autoload (nie stała w Races.gd) jest konieczny właśnie dlatego, że
## dryf ma płynąć cały czas w tle, także gdy gracz nie stoi na ekranie
## Wyścigów — a skrypt sceny żyje tylko, gdy ta scena jest otwarta, autoloady
## żyją przez całą grę.

const HORSES := {
	"komet": {"name": "Komet", "image": "res://art/horses/komet.jpg"},
	"grom": {"name": "Grom", "image": "res://art/horses/grom.jpg"},
	"cyklon": {"name": "Cyklon", "image": "res://art/horses/cyklon.jpg"},
	"blyskawica": {"name": "Błyskawica", "image": "res://art/horses/blyskawica.jpg"},
	"wicher": {"name": "Wicher", "image": "res://art/horses/wicher.jpg"},
}

const STARTING_ODDS := {
	"komet": 2.0,
	"grom": 3.5,
	"cyklon": 5.0,
	"blyskawica": 8.0,
	"wicher": 12.0,
}

const DAILY_DRIFT_RANGE := 0.05  ## losowe wahanie kursu ±5% dziennie — koń, nie akcja, ma być trochę żywszy niż giełda
## Granice kursu — bez tego dryf mógłby zjechać faworyta do "pewniaka" (kurs
## bliski zeru rozwala wagę 1.0/odds w _pick_winner_index) albo wywindować
## underdoga do absurdalnej wypłaty.
const MIN_ODDS := 1.3
const MAX_ODDS := 20.0

var current_odds: Dictionary = {}


func _ready() -> void:
	Calendar.day_advanced.connect(_on_day_advanced)


func reset_new_game() -> void:
	current_odds = STARTING_ODDS.duplicate()


func get_odds(horse_id: String) -> float:
	return current_odds.get(horse_id, STARTING_ODDS.get(horse_id, 1.0))


func _on_day_advanced(days_elapsed: int, _current_day: int) -> void:
	var weeks: float = float(days_elapsed) / 7.0
	for horse_id in HORSES.keys():
		var change := randf_range(-DAILY_DRIFT_RANGE, DAILY_DRIFT_RANGE) * weeks
		current_odds[horse_id] = clampf(get_odds(horse_id) * (1.0 + change), MIN_ODDS, MAX_ODDS)
