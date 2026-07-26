extends Control

var easy_mode_check: CheckBox
var player_count_option: OptionButton
var setup_section: VBoxContainer
var name_section: VBoxContainer
var name_edits: Array[LineEdit] = []
var gender_options: Array[OptionButton] = []
var avatar_options: Array[OptionButton] = []
var avatar_previews: Array[TextureRect] = []
var root: VBoxContainer


func _ready() -> void:
	ScreenHelpers.make_background(self, "res://art/backgrounds/main_menu_title.jpg")
	## use_menu_frame=false: zgłoszone przez użytkownika — ozdobna ramka na
	## cały ekran ma zniknąć na wszystkich ekranach (ten sam fix co wcześniej
	## w AuctionHouse.gd/Gallery.gd). Menu główne nie ma przycisku powrotu
	## (to pierwszy ekran gry), więc bez dodatkowego przypinania tytułu/
	## przycisku do krawędzi — samo logo pełni rolę tytułu i zostaje
	## wyśrodkowane jak dotychczas (root.alignment domyślnie CENTER).
	root = ScreenHelpers.make_root(self, false)

	var subtitle_label := ScreenHelpers.make_label(root, "Ekonomiczna gra strategiczna — lata 20. XX wieku")

	setup_section = VBoxContainer.new()
	root.add_child(setup_section)

	var player_row := HBoxContainer.new()
	player_row.alignment = BoxContainer.ALIGNMENT_CENTER
	setup_section.add_child(player_row)
	var player_caption := Label.new()
	player_caption.text = "Liczba graczy (hot-seat):"
	player_row.add_child(player_caption)
	player_count_option = OptionButton.new()
	for count in range(1, Players.MAX_PLAYERS + 1):
		player_count_option.add_item(str(count))
	player_row.add_child(player_count_option)

	easy_mode_check = CheckBox.new()
	easy_mode_check.text = tr("Tryb łatwy (%d/%d obrazów do wygranej)") % [Paintings.EASY_WIN_THRESHOLD, Paintings.CATALOG.size()]
	setup_section.add_child(easy_mode_check)

	ScreenHelpers.make_button(setup_section, "Nowa gra", _show_name_entry)

	var continue_btn := ScreenHelpers.make_button(setup_section, "Wczytaj grę", func():
		SaveGame.load_game()
		SceneRouter.goto_hub()
	)
	continue_btn.disabled = not SaveGame.has_save()

	ScreenHelpers.make_button(setup_section, "Ustawienia", func(): SceneRouter.goto_scene(SceneRouter.SETTINGS))
	ScreenHelpers.make_button(setup_section, "Wyjdź z gry", func(): get_tree().quit())

	name_section = VBoxContainer.new()
	name_section.visible = false
	root.add_child(name_section)

	## MainMenu to PIERWSZY ekran gry, ładowany od razu przy zimnym starcie —
	## w przeciwieństwie do Hub.gd/Plantation.gd/TravelAnimation.gd (ten sam
	## wzorzec get_viewport_rect(), ale osiągalne dopiero PO tym, jak okno
	## aplikacji na Androidzie zdąży się już w pełni ustabilizować do
	## docelowego rozmiaru). Tu, w _ready(), get_viewport_rect() potrafi
	## jeszcze zwracać nieostateczny rozmiar (immersive mode/wcięcia na
	## ekranie ustawiają się asynchronicznie) — stąd dwukrotne zgłoszenie
	## użytkownika, że logo dalej wychodziło za duże mimo poprawnej matematyki
	## (liczone od złego, tymczasowego rozmiaru viewportu). await
	## process_frame (dwa razy dla pewności) odkłada pomiar/budowę logo na
	## moment, gdy silnik zdążył już przeliczyć docelowy rozmiar okna.
	await get_tree().process_frame
	await get_tree().process_frame
	_build_logo(subtitle_label, setup_section)


## Logo ma już wpisany napis "THE FORGER: RETRO TYCOON" w swojej grafice
## (kinowa scena z kurtynami, styl art déco zgodny z resztą gry) —
## zastępuje zwykły tekstowy tytuł zamiast leżeć obok niego. Zgłoszone przez
## użytkownika: ma zajmować MAKS. 1/3 wysokości ekranu, więc reszta menu
## (napis, wybór graczy, przyciski) zawsze mieści się bez przewijania.
## Twardy limit 1/3 wysokości ramki, NIEZALEŻNY od pomiaru reszty menu —
## poprzednia wersja liczyła dokładnie tyle miejsca, ile zostaje po
## zmierzeniu subtitle_label/setup_section, ale to nadal potrafiło wyjść
## zbyt duże (patrz komentarz w _ready() o niegotowym jeszcze rozmiarze
## viewportu przy starcie), a użytkownik i tak chce jawny, przewidywalny
## sufit rozmiaru, nie wyliczaną resztę.
func _build_logo(subtitle_label: Label, setup_section_ref: VBoxContainer) -> void:
	## Bez ozdobnej ramki (use_menu_frame=false, zgłoszone przez użytkownika)
	## root wypełnia CAŁY ekran bez wcięcia (patrz plain_root w
	## screen_helpers.gd), więc liczone wprost z viewport_size — wcześniejsze
	## 0.9 * ekran - 2×CONTENT_INSET_WITH_FRAME odpowiadało geometrii ramki,
	## która już nie istnieje.
	var viewport_size := get_viewport_rect().size
	var frame_content_width := viewport_size.x
	var frame_content_height := viewport_size.y

	var logo_texture: Texture2D = load("res://art/backgrounds/logo.jpg")
	var logo_aspect := logo_texture.get_width() / float(logo_texture.get_height())
	var logo_height := frame_content_height / 3.0
	var logo_width := minf(logo_height * logo_aspect, frame_content_width * 0.85)
	logo_height = logo_width / logo_aspect

	var logo := TextureRect.new()
	logo.texture = logo_texture
	logo.custom_minimum_size = Vector2(logo_width, logo_height)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(logo)
	root.move_child(logo, 0)

	## Kontrola przy debugowaniu: bez ozdobnej ramki (use_menu_frame=false)
	## root NIE MA już ScrollContainera jako zabezpieczenia (patrz plain_root
	## w screen_helpers.gd) — gdyby logo + reszta menu i tak nie mieściły się
	## na ekranie, po prostu by się obcięły. Twardy limit 1/3 wysokości na
	## logo nie powinien do tego dopuścić, ale ostrzeżenie zostaje jako
	## kontrola przy debugowaniu.
	var root_separation := root.get_theme_constant("separation")
	var total_height := logo_height + subtitle_label.get_minimum_size().y + setup_section_ref.get_minimum_size().y + root_separation * 2.0
	if total_height > frame_content_height:
		push_warning("MainMenu: treść (%.0fpx) przekracza wysokość ramki (%.0fpx) mimo limitu na logo." % [total_height, frame_content_height])


## Zamiast od razu startować grę z domyślnymi nazwami "Gracz 1"/"Gracz 2"...,
## po kliknięciu "Nowa gra" pytamy o imiona graczy (tyle pól, ile wybrano w
## "Liczba graczy") — ważne zwłaszcza w hot-seat, żeby każdy wiedział, kiedy
## jest jego tura (patrz Hub.gd _update_status, Gallery.gd lista graczy).
func _show_name_entry() -> void:
	for child in name_section.get_children():
		child.queue_free()
	name_edits.clear()
	gender_options.clear()
	avatar_options.clear()
	avatar_previews.clear()

	ScreenHelpers.make_title(name_section, "Podaj imiona graczy")

	## HFlowContainer zamiast pionowego stosu boksów per gracz — zgłoszone
	## przez użytkownika: przy 2+ graczach boksy stackowały się jeden pod
	## drugim, a w orientacji poziomej (mało miejsca w pionie) ekran nie
	## mieścił wszystkiego do przycisku "Rozpocznij grę" bez przewijania,
	## które na tym ekranie (tak jak wcześniej na Hub.gd) zawodzi dotykiem.
	## Boksy graczy obok siebie w POZIOMIE (do 4, Players.MAX_PLAYERS,
	## mieszczą się swobodnie na szerokim ekranie) — wysokość rośnie tylko o
	## wysokość JEDNEGO boksu, niezależnie od liczby graczy.
	var players_row := HFlowContainer.new()
	players_row.alignment = FlowContainer.ALIGNMENT_CENTER
	players_row.add_theme_constant_override("h_separation", 20)
	players_row.add_theme_constant_override("v_separation", 16)
	name_section.add_child(players_row)

	## Każdy gracz dostaje: DUŻY podgląd awatara na górze (96×96, było 48×48,
	## stłoczone w jednym rzędzie z resztą — zgłoszone przez użytkownika, że
	## wybór powinien być większy i awatar może stać w innym miejscu niż
	## kontrolki wyboru), a pod nim imię i wybór płci/wariantu. Awatary to ta
	## sama pula 6 gotowych portretów co rywale AI (2 płcie × 3 warianty,
	## patrz Players.GENDERS/AVATAR_VARIANTS) — nie trzeba generować nowej
	## grafiki, chyba że kiedyś zabraknie wariantów (wtedy dopisać kolejne
	## prompty w docs/GRAFIKA_LEONARDO.md §6).
	var count := player_count_option.selected + 1
	for i in count:
		var box := ScreenHelpers.make_boxed_row(players_row)
		var column := VBoxContainer.new()
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_theme_constant_override("separation", 8)
		box.add_child(column)

		var avatar_preview := TextureRect.new()
		avatar_preview.custom_minimum_size = Vector2(96, 96)
		avatar_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		avatar_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		avatar_preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(avatar_preview)
		avatar_previews.append(avatar_preview)

		var name_row := HBoxContainer.new()
		name_row.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_child(name_row)

		var caption := Label.new()
		caption.text = tr("Gracz %d:") % (i + 1)
		name_row.add_child(caption)

		var edit := LineEdit.new()
		edit.placeholder_text = tr("Gracz %d") % (i + 1)
		edit.custom_minimum_size = Vector2(160, 0)
		name_row.add_child(edit)
		name_edits.append(edit)

		var choice_row := HBoxContainer.new()
		choice_row.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_child(choice_row)

		var gender_option := OptionButton.new()
		for gender in Players.GENDERS:
			gender_option.add_item(Players.GENDER_NAMES[gender])
		gender_option.item_selected.connect(_on_avatar_choice_changed.bind(i))
		choice_row.add_child(gender_option)
		gender_options.append(gender_option)

		var avatar_option := OptionButton.new()
		for variant in Players.AVATAR_VARIANTS:
			avatar_option.add_item(Players.AVATAR_VARIANT_NAMES[variant])
		avatar_option.item_selected.connect(_on_avatar_choice_changed.bind(i))
		choice_row.add_child(avatar_option)
		avatar_options.append(avatar_option)

		_update_avatar_preview(i)

	ScreenHelpers.make_button(name_section, "Rozpocznij grę", _on_start_confirmed)
	ScreenHelpers.make_button(name_section, "Anuluj", func():
		name_section.visible = false
		setup_section.visible = true
	)

	setup_section.visible = false
	name_section.visible = true


func _on_avatar_choice_changed(_selected_index: int, player_index: int) -> void:
	_update_avatar_preview(player_index)


func _update_avatar_preview(player_index: int) -> void:
	var gender: String = Players.GENDERS[gender_options[player_index].selected]
	var variant: String = Players.AVATAR_VARIANTS[avatar_options[player_index].selected]
	var path := "res://art/characters/%s_%s.jpg" % [gender, variant]
	avatar_previews[player_index].texture = load(path) if ResourceLoader.exists(path) else null


func _on_start_confirmed() -> void:
	Calendar.reset_new_game()
	Economy.reset_new_game()
	Crops.reset_new_game()
	Paintings.reset_new_game(easy_mode_check.button_pressed)
	Auctions.reset_new_game()
	ShippingCompanies.reset_new_game()
	ForwardContracts.reset_new_game()
	YearlyReport.reset_new_game()
	WorldEvents.reset_new_game()
	AIPlayers.reset_new_game()
	PlayerPlantations.reset_new_game()
	Travel.reset_new_game()
	Security.reset_new_game()
	Players.reset_new_game(player_count_option.selected + 1)
	GameState.reset_new_game()
	for i in name_edits.size():
		Players.set_player_name(i, name_edits[i].text)
		Players.set_player_gender(i, Players.GENDERS[gender_options[i].selected])
		Players.set_player_avatar(i, Players.AVATAR_VARIANTS[avatar_options[i].selected])
	SceneRouter.goto_hub()
