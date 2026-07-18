extends Node
## Przeciwnicy AI, w tym nazwany rywal-fałszerz Vico.
## Patrz docs/MECHANIKI_EKONOMICZNE.md pkt. 9.
##
## TODO fabularne (docs/DODATKOWE_MECHANIKI.md): rozważyć twist na koniec
## gry, w którym Vico okazuje się być tą samą postacią co Walther von
## Grünschild — do zaimplementowania w warstwie scenariusza/zakończenia,
## nie w tym systemie ekonomicznym.

var rivals: Array[Dictionary] = []


func reset_new_game() -> void:
	rivals = [
		{"id": "vico", "name": "Vico Vermeer", "money": 50000.0, "paintings": [], "is_named_rival": true},
		{"id": "rival_2", "name": "Rywal II", "money": 50000.0, "paintings": [], "is_named_rival": false},
		{"id": "rival_3", "name": "Rywal III", "money": 50000.0, "paintings": [], "is_named_rival": false},
	]


func get_rival(id: String) -> Dictionary:
	for rival in rivals:
		if rival["id"] == id:
			return rival
	return {}
