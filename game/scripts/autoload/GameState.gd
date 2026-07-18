extends Node
## Centralny punkt sprawdzania warunków zakończenia gry — patrz GDD.md pkt. 6.
## Sprawdza WSZYSTKICH graczy (Players), nie tylko aktualnie aktywnego —
## ważne w hot-seat multiplayer (docs/GDD.md pkt. 11).

var last_outcome: String = ""  ## "win:<idx>", "bankrupt:<idx>", "rival_win:<id>", albo ""


## Wywoływać po każdej akcji, która może zmienić stan gry na "koniec"
## (upływ czasu, wygrana aukcja itd.). Zwraca true, jeśli gra się skończyła —
## wywołujący powinien wtedy przejść do ekranu zakończenia.
func check_game_over() -> bool:
	var winner := Players.get_winning_player()
	if winner != -1:
		last_outcome = "win:%d" % winner
		return true
	var bankrupt_player := Players.get_bankrupt_player()
	if bankrupt_player != -1:
		last_outcome = "bankrupt:%d" % bankrupt_player
		return true
	var winning_rival_id := AIPlayers.get_rival_who_won()
	if winning_rival_id != "":
		last_outcome = "rival_win:" + winning_rival_id
		return true
	return false


func reset_new_game() -> void:
	last_outcome = ""
