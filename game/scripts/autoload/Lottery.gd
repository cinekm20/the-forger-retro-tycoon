extends Node
## Wynik Noworocznej Loterii (Neujahrstombola, docs/GDD.md pkt. 4.8) czekający
## na pokazanie graczowi — ten sam wzorzec co YearlyReport.gd: migawka do
## JEDNORAZOWEGO wyświetlenia w Hubie, nie dane samej mechaniki. Samo
## losowanie (kto wygrywa, ile, czy trafia się obraz z katalogu 1-40) odbywa
## się w Economy._on_new_year (Players.grant_new_year_to_random_player) —
## ten plik tylko przechowuje gotowy wynik do animowanego ekranu
## (scenes/new_year_lottery/NewYearLottery.gd, patrz Hub.gd _ready).

var pending: Dictionary = {}


func reset_new_game() -> void:
	pending = {}


func has_pending() -> bool:
	return not pending.is_empty()


func set_pending(result: Dictionary) -> void:
	pending = result


## Wywoływać RAZ, tuż przed zbudowaniem ekranu loterii — czyści `pending`,
## żeby ten sam wynik nie pokazał się drugi raz przy kolejnym wejściu do Huba.
func consume_pending() -> Dictionary:
	var data := pending
	pending = {}
	return data
