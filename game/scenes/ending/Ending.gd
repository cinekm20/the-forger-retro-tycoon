extends Control
## Ekran zakończenia — trzy warianty wg GameState.last_outcome.
## Tekst zakończenia "win" to nasza własna, oryginalna scena inspirowana
## twistem fabularnym udokumentowanym w docs/DODATKOWE_MECHANIKI.md
## (Walther von Grünschild = Vico Vermeer), a nie przedruk żadnego
## konkretnego źródła.

func _ready() -> void:
	var root := ScreenHelpers.make_root(self)

	var outcome := GameState.last_outcome
	if outcome.begins_with("win:"):
		_build_win(root, int(outcome.substr(4)))
	elif outcome.begins_with("bankrupt:"):
		_build_bankrupt(root, int(outcome.substr(9)))
	elif outcome.begins_with("rival_win:"):
		_build_rival_win(root, outcome.substr(10))
	else:
		ScreenHelpers.make_title(root, "Koniec gry")

	ScreenHelpers.make_button(root, "Powrót do menu głównego", func(): SceneRouter.goto_scene(SceneRouter.MAIN_MENU))


## player_index wskazuje, KTO wygrał — w multiplayerze może to nie być ten
## gracz, który akurat kończył turę, gdy wygrana została wykryta.
## NARRATIVE_LABEL_WIDTH: te akapity to długie zdania (do ~250 znaków) —
## ScreenHelpers.make_label() sam z siebie NIE zawija tekstu (autowrap bez
## ograniczenia szerokości nic nie daje), więc bez stałej szerokości
## renderowały się jako jeden, bardzo szeroki wiersz wychodzący poza ramkę
## ekranu (przegląd czytelności/dopasowania do rozdzielczości na żądanie
## użytkownika) — dokładnie na ekranie ZAKOŃCZENIA gry, gdzie to najbardziej
## widoczne. Wysokość zostaje 0 (rośnie do treści) — te etykiety ustawiane są
## raz w _ready() i nigdy się później nie zmieniają, więc nie ma ryzyka
## przesunięcia layoutu przy kolejnej aktualizacji tekstu (w przeciwieństwie
## do etykiet statusu na innych ekranach).
const NARRATIVE_LABEL_WIDTH := 900.0


func _build_win(root: VBoxContainer, player_index: int) -> void:
	var name_prefix := (Players.player_names[player_index] + ": ") if Players.is_multiplayer() else ""
	ScreenHelpers.make_title(root, "Kolekcja kompletna")
	_make_narrative_label(
		root,
		name_prefix + tr("Ostatni obraz trafia do gabloty. Posłaniec przynosi wiadomość: wuj Walther chce Cię widzieć natychmiast."),
	)
	_make_narrative_label(
		root,
		tr("W gabinecie czeka na Ciebie zapieczętowany testament. Notariusz czyta go na głos, a przy podpisie zawodowo się zawiesza — obok nazwiska \"Walther von Grünschild\" widnieje dopisek innym charakterem pisma: \"znany też jako Vico Vermeer\"."),
	)
	_make_narrative_label(
		root,
		tr("Cała pogoń za fałszerzem, każda podróbka podsunięta na aukcji, każda niechciana przejażdżka — to był test, który sam sobie zaplanował dla następcy, zanim zaufa mu swoje imperium. Właśnie go zdałeś/zdałaś."),
	)
	ScreenHelpers.make_label(
		root,
		tr("Dni gry: %d | Gotówka: %.0f M | Obrazy: %d") % [
			Calendar.current_day, Economy.player_money, Players.get_painting_count(player_index),
		],
	)


func _build_bankrupt(root: VBoxContainer, player_index: int) -> void:
	var name_prefix := (Players.player_names[player_index] + ": ") if Players.is_multiplayer() else ""
	ScreenHelpers.make_title(root, "Bankructwo")
	_make_narrative_label(
		root,
		name_prefix + tr("Wierzyciele stracili cierpliwość. Twoje interesy zostają przejęte, a marzenie o spadku po wuju Waltherze przechodzi na innego, sprawniejszego kandydata."),
	)
	ScreenHelpers.make_label(root, tr("Dni gry: %d | Obrazy zebrane: %d") % [
		Calendar.current_day, Players.get_painting_count(player_index),
	])


func _build_rival_win(root: VBoxContainer, rival_id: String) -> void:
	var rival_name: String = AIPlayers.get_rival(rival_id).get("name", rival_id)
	ScreenHelpers.make_title(root, "Przegrana")
	_make_narrative_label(
		root,
		tr("%s dociera do ostatniego brakującego obrazu pierwszy/-a. Testament wuja Walthera zostaje spisany na czyjeś inne nazwisko.") % rival_name,
	)
	ScreenHelpers.make_label(root, tr("Dni gry: %d | Twoje obrazy: %d") % [Calendar.current_day, Paintings.owned_count()])


func _make_narrative_label(root: VBoxContainer, text: String) -> Label:
	var label := ScreenHelpers.make_label(root, text)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.custom_minimum_size = Vector2(NARRATIVE_LABEL_WIDTH, 0)
	return label
