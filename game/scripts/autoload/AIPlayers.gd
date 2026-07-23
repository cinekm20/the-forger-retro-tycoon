extends Node
## Przeciwnicy AI, w tym nazwany rywal-fałszerz Vico.
## Patrz docs/MECHANIKI_EKONOMICZNE.md pkt. 9.
##
## Twist fabularny (docs/DODATKOWE_MECHANIKI.md): Vico okazuje się być tą
## samą postacią co Walther von Rabenstein — zaimplementowane w warstwie
## zakończenia, patrz scenes/ending/Ending.gd, nie w tym systemie ekonomicznym.

const WEEKLY_INCOME_RANGE := Vector2(2000.0, 8000.0)  ## uproszczenie: AI nie symuluje własnych plantacji

## Pula generycznych rywali (docs/GRAFIKA_LEONARDO.md §6: 6 portretów, 2 płcie
## × 3 dodatki) — klucz to jednocześnie identyfikator wariantu portretu, więc
## nazwa i grafika zawsze trafiają do tego samego rywala. Imiona losowane przy
## KAŻDEJ nowej grze (patrz reset_new_game), zamiast statycznego "Rywal II" —
## zgłoszone przez użytkownika: imiona przeciwników powinny nadawać się same.
const GENERIC_RIVAL_POOL := {
	"male_tophat": "Baron Heinrich von Falkenstein",
	"male_monocle": "Lord Edmund Ashcombe",
	"male_boa": "Hrabia Alessandro Ricci",
	"female_tophat": "Lady Wilhelmina Hartog",
	"female_monocle": "Contessa Isabella Moreau",
	"female_boa": "Madame Colette Dubois",
}

## Vico ma 3 gotowe warianty portretu (vico_1/2/3.jpg, wygenerowane z tym
## samym seedem — patrz docs/GRAFIKA_LEONARDO.md §6), losowane przy każdej
## nowej grze tak samo jak portrety generycznych rywali, zamiast jednego
## sztywnego pliku.
const VICO_PORTRAIT_VARIANTS := 3

var rivals: Array[Dictionary] = []


func _ready() -> void:
	Calendar.day_advanced.connect(_on_day_advanced)


func reset_new_game() -> void:
	var portrait_ids: Array = GENERIC_RIVAL_POOL.keys()
	portrait_ids.shuffle()
	var vico_portrait := "vico_%d" % (randi() % VICO_PORTRAIT_VARIANTS + 1)
	rivals = [
		{"id": "vico", "name": "Vico Falsari", "portrait": vico_portrait, "money": 50000.0, "is_named_rival": true, "paintings": []},
		{"id": "rival_2", "name": GENERIC_RIVAL_POOL[portrait_ids[0]], "portrait": portrait_ids[0], "money": 50000.0, "is_named_rival": false, "paintings": []},
		{"id": "rival_3", "name": GENERIC_RIVAL_POOL[portrait_ids[1]], "portrait": portrait_ids[1], "money": 50000.0, "is_named_rival": false, "paintings": []},
	]


## Ścieżka do portretu rywala (docs/GRAFIKA_LEONARDO.md §6) —
## AuctionHouse.gd sam sprawdza ResourceLoader.exists() przed load(), więc
## brakujący plik po prostu nie pokazuje portretu, zamiast crashować.
func get_portrait_path(rival_id: String) -> String:
	var rival := get_rival(rival_id)
	return "res://art/characters/%s.jpg" % rival.get("portrait", rival_id)


func get_rival(id: String) -> Dictionary:
	for rival in rivals:
		if rival["id"] == id:
			return rival
	return {}


## Rywal wygrywa aukcję: płaci i katalog jego kolekcji rośnie (obraz może
## być fałszywką tak samo jak u gracza — patrz Paintings.is_forgery_by_duplicate,
## ale to nie blokuje rywala przed dalszym graniem, tylko go nie liczy do
## jego postępu, tak jak u gracza).
func award_painting(rival_id: String, number: int, price: float) -> void:
	var rival := get_rival(rival_id)
	if rival.is_empty():
		return
	rival["money"] -= price
	var paintings: Array = rival["paintings"]
	if not paintings.has(number):
		paintings.append(number)


func get_rival_painting_count(rival_id: String) -> int:
	var rival := get_rival(rival_id)
	return rival.get("paintings", []).size()


## Zwraca id pierwszego rywala, który skompletował całą wymaganą liczbę
## obrazów (Paintings.win_threshold) — pusty string, jeśli żaden.
func get_rival_who_won() -> String:
	for rival in rivals:
		if get_rival_painting_count(rival["id"]) >= Paintings.win_threshold:
			return rival["id"]
	return ""


func _on_day_advanced(days_elapsed: int, _current_day: int) -> void:
	var weeks: float = float(days_elapsed) / 7.0
	for rival in rivals:
		rival["money"] += randf_range(WEEKLY_INCOME_RANGE.x, WEEKLY_INCOME_RANGE.y) * weeks


## Decyduje, czy rywal podbija licytację ponad current_bid, i o ile.
## Zwraca 0.0, jeśli rywal rezygnuje (za drogo albo brak środków).
## Vico bywa bardziej agresywny — czasem podbija cenę bez realnego zamiaru
## kupna (patrz docs/DODATKOWE_MECHANIKI.md).
func decide_bid(rival_id: String, current_bid: float, estimated_value: float) -> float:
	var rival := get_rival(rival_id)
	if rival.is_empty():
		return 0.0
	var willingness_multiplier := randf_range(0.8, 1.3)
	if rival_id == "vico":
		willingness_multiplier = randf_range(0.9, 1.6)
	var willingness: float = estimated_value * willingness_multiplier
	var next_bid: float = current_bid + estimated_value * randf_range(0.05, 0.15)
	if next_bid > willingness or next_bid > rival["money"]:
		return 0.0
	return next_bid
