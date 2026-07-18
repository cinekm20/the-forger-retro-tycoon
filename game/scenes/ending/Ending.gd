extends Control
## Ekran zakończenia — trzy warianty wg GameState.last_outcome.
## Tekst zakończenia "win" to nasza własna, oryginalna scena inspirowana
## twistem fabularnym udokumentowanym w docs/DODATKOWE_MECHANIKI.md
## (Walther von Grünschild = Vico Vermeer), a nie przedruk żadnego
## konkretnego źródła.

func _ready() -> void:
	var root := ScreenHelpers.make_root(self)

	match GameState.last_outcome:
		"win":
			_build_win(root)
		"bankrupt":
			_build_bankrupt(root)
		_:
			if GameState.last_outcome.begins_with("rival_win:"):
				_build_rival_win(root, GameState.last_outcome.substr(10))
			else:
				ScreenHelpers.make_title(root, "Koniec gry")

	ScreenHelpers.make_button(root, "Powrót do menu głównego", func(): SceneRouter.goto_scene(SceneRouter.MAIN_MENU))


func _build_win(root: VBoxContainer) -> void:
	ScreenHelpers.make_title(root, "Kolekcja kompletna")
	ScreenHelpers.make_label(
		root,
		"Ostatni obraz trafia do gabloty. Posłaniec przynosi wiadomość: " +
		"wuj Walther chce Cię widzieć natychmiast.",
	)
	ScreenHelpers.make_label(
		root,
		"W gabinecie czeka na Ciebie zapieczętowany testament. Notariusz " +
		"czyta go na głos, a przy podpisie zawodowo się zawiesza — obok " +
		"nazwiska \"Walther von Grünschild\" widnieje dopisek innym charakterem " +
		"pisma: \"znany też jako Vico Vermeer\".",
	)
	ScreenHelpers.make_label(
		root,
		"Cała pogoń za fałszerzem, każda podróbka podsunięta na aukcji, " +
		"każda niechciana przejażdżka — to był test, który sam sobie " +
		"zaplanował dla następcy, zanim zaufa mu swoje imperium. Właśnie go " +
		"zdałeś/zdałaś.",
	)
	ScreenHelpers.make_label(
		root,
		"Dni gry: %d | Gotówka: %.0f M | Obrazy: %d" % [
			Calendar.current_day, Economy.player_money, Paintings.owned_count(),
		],
	)


func _build_bankrupt(root: VBoxContainer) -> void:
	ScreenHelpers.make_title(root, "Bankructwo")
	ScreenHelpers.make_label(
		root,
		"Wierzyciele stracili cierpliwość. Twoje interesy zostają przejęte, " +
		"a marzenie o spadku po wuju Waltherze przechodzi na innego, " +
		"sprawniejszego kandydata.",
	)
	ScreenHelpers.make_label(root, "Dni gry: %d | Obrazy zebrane: %d" % [Calendar.current_day, Paintings.owned_count()])


func _build_rival_win(root: VBoxContainer, rival_id: String) -> void:
	var rival_name: String = AIPlayers.get_rival(rival_id).get("name", rival_id)
	ScreenHelpers.make_title(root, "Przegrana")
	ScreenHelpers.make_label(
		root,
		"%s dociera do ostatniego brakującego obrazu pierwszy/-a. Testament wuja Walthera zostaje spisany na czyjeś inne nazwisko." % rival_name,
	)
	ScreenHelpers.make_label(root, "Dni gry: %d | Twoje obrazy: %d" % [Calendar.current_day, Paintings.owned_count()])
