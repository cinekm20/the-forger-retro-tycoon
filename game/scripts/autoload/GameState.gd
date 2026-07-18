extends Node
## Centralny punkt sprawdzania warunków zakończenia gry — patrz GDD.md pkt. 6.

var last_outcome: String = ""  ## "win", "bankrupt", "rival_win:<id>", albo ""


## Wywoływać po każdej akcji, która może zmienić stan gry na "koniec"
## (upływ czasu, wygrana aukcja itd.). Zwraca true, jeśli gra się skończyła —
## wywołujący powinien wtedy przejść do ekranu zakończenia.
func check_game_over() -> bool:
	if Paintings.has_all_paintings():
		last_outcome = "win"
		return true
	if Economy.is_bankrupt():
		last_outcome = "bankrupt"
		return true
	var winning_rival_id := AIPlayers.get_rival_who_won()
	if winning_rival_id != "":
		last_outcome = "rival_win:" + winning_rival_id
		return true
	return false


func reset_new_game() -> void:
	last_outcome = ""
