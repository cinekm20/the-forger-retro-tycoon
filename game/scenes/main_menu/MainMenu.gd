extends Control

## Zgłoszenie użytkownika: bardzo długa nazwa gracza rozpychała ramkę
## gracza na Domu aukcyjnym (AuctionHouse.gd — szerokość skrzynki rosła i
## malała zależnie od tego, czyja ramka akurat się przebudowywała) i
## przesuwała przycisk "Powrót" poza ekran (dłuższy tekst "prowadzi: <imię>"
## zajmował więcej linii). Twarde ograniczenie TU, przy wpisywaniu — żadne
## pojedyncze miejsce wyświetlające nazwę gracza w grze nie musi już samo
## bronić się przed dowolnie długim wejściem.
const MAX_PLAYER_NAME_LENGTH := 16

var easy_mode_check: CheckBox
var player_count_option: OptionButton
var setup_section: VBoxContainer
var name_section: VBoxContainer
## Zewnętrzne skrzynki (PanelContainer + ramka) opakowujące setup_section/
## name_section (patrz ScreenHelpers.make_boxed_panel) — przełączanie
## widoczności musi działać na TYCH, nie na samych VBoxContainerach z
## przyciskami, inaczej ozdobna ramka zostałaby widoczna nawet po ukryciu
## zawartości.
var setup_box: Control
var name_box: Control
var name_edits: Array[LineEdit] = []
var gender_options: Array[OptionButton] = []
var avatar_options: Array[OptionButton] = []
var avatar_previews: Array[TextureRect] = []
var root: VBoxContainer
## Boczne, narożne kolumny z ramką KAŻDEGO gracza (patrz
## _build_player_corner_frames) — zgłoszone przez użytkownika: ekran
## wpisywania imion ma pokazywać każdego gracza tak jak w Domu aukcyjnym
## (AuctionHouse.gd _make_side_column), nie w rzędzie boksów na środku.
## Dzieci `self`, NIE name_section — więc trzeba je jawnie sprzątać osobno
## przy każdej przebudowie/anulowaniu ekranu wpisywania imion.
var player_corner_columns: Array[Control] = []


func _ready() -> void:
	Music.play_track(Music.MAIN_MENU_TRACK)
	## Zgłoszenie użytkownika: tytuł "THE FORGER: RETRO TYCOON" ma być wpisany
	## bezpośrednio w tym tle (patrz docs/GRAFIKA_LEONARDO.md §1, zaktualizowany
	## prompt), zamiast osobno dogrywanej grafiki logo — jedno tło zamiast
	## dwóch nakładających się obrazów. Dawne logo.jpg i cała logika
	## _build_logo (limit 1/3 wysokości, wyliczanie rozmiaru z opóźnieniem o
	## dwie klatki) zostały usunięte.
	ScreenHelpers.make_background(self, "res://art/backgrounds/main_menu_title.jpg")
	## use_menu_frame=false: zgłoszone przez użytkownika — ozdobna ramka na
	## cały ekran ma zniknąć na wszystkich ekranach (ten sam fix co wcześniej
	## w AuctionHouse.gd/Gallery.gd). Menu główne nie ma przycisku powrotu
	## (to pierwszy ekran gry).
	root = ScreenHelpers.make_root(self, false)

	## ALIGNMENT_BEGIN + rozpychacz na SAMYM POCZĄTKU (nie na końcu jak
	## gdzie indziej w grze) — zgłoszone przez użytkownika: skrzynka menu ma
	## być przyklejona do SAMEGO DOŁU ekranu, tak jak było wcześniej, zamiast
	## wyśrodkowana pionowo na środku. Wyśrodkowanie (poprzedni, przejściowy
	## wygląd) zasłaniało tytuł "THE FORGER: RETRO TYCOON" wpisany teraz w
	## tło (patrz komentarz o main_menu_title.jpg wyżej) — dół ekranu jest od
	## niego bezpiecznie z dala.
	root.alignment = BoxContainer.ALIGNMENT_BEGIN
	root.add_child(ScreenHelpers.make_expand_spacer())

	## Skrzynka Art Deco, TA SAMA co wszędzie indziej (ScreenHelpers.make_boxed_back_button/
	## make_root_bottom) — zgłoszone przez użytkownika: te dwa "menu" (wybór
	## trybu gry i wpisywanie imion graczy) mają wyglądać tak samo. Wariant
	## "inline" (make_boxed_panel, nie make_root_bottom) — treść ma zostać
	## naturalnie wyśrodkowana RAZEM z podtytułem (i tytułem wpisanym w tło,
	## patrz komentarz w _ready() wyżej), a nie zakotwiczona osobno w rogu
	## ekranu.
	var setup_panel := ScreenHelpers.make_boxed_panel(root)
	setup_box = setup_panel["box"]
	setup_section = setup_panel["content"]

	var player_row := HBoxContainer.new()
	player_row.alignment = BoxContainer.ALIGNMENT_CENTER
	setup_section.add_child(player_row)
	var player_caption := Label.new()
	player_caption.text = "Liczba graczy (hot-seat):"
	player_caption.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
	player_row.add_child(player_caption)
	player_count_option = OptionButton.new()
	player_count_option.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
	for count in range(1, Players.MAX_PLAYERS + 1):
		player_count_option.add_item(str(count))
	player_row.add_child(player_count_option)

	easy_mode_check = CheckBox.new()
	easy_mode_check.text = tr("Tryb łatwy (%d/%d obrazów do wygranej)") % [Paintings.EASY_WIN_THRESHOLD, Paintings.CATALOG.size()]
	easy_mode_check.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
	setup_section.add_child(easy_mode_check)

	ScreenHelpers.make_button(setup_section, "Nowa gra", _show_name_entry)

	var continue_btn := ScreenHelpers.make_button(setup_section, "Wczytaj grę", func():
		SaveGame.load_game()
		SceneRouter.goto_hub()
	)
	continue_btn.disabled = not SaveGame.has_save()

	ScreenHelpers.make_button(setup_section, "Ustawienia", func(): SceneRouter.goto_scene(SceneRouter.SETTINGS))
	ScreenHelpers.make_button(setup_section, "Wyjdź z gry", func(): Music.quit_game())

	var name_panel := ScreenHelpers.make_boxed_panel(root)
	name_box = name_panel["box"]
	name_section = name_panel["content"]
	name_box.visible = false


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

	## Zgłoszone przez użytkownika: gracze mają być pokazani tak jak w Domu
	## aukcyjnym — każdy w OSOBNEJ ramce w rogu ekranu (1 -> prawy dół,
	## 2 -> lewy dół, 3 -> prawy góra, 4 -> lewy góra), zamiast rzędu boksów
	## na środku. _build_player_corner_frames zwraca te 4 sloty w TEJ
	## kolejności (ten sam patent co AuctionHouse.gd _build_player_frames).
	var count := player_count_option.selected + 1
	var slots := _build_player_corner_frames()

	## Każdy gracz dostaje: DUŻY podgląd awatara na górze (96×96, było 48×48,
	## stłoczone w jednym rzędzie z resztą — zgłoszone przez użytkownika, że
	## wybór powinien być większy i awatar może stać w innym miejscu niż
	## kontrolki wyboru), a pod nim imię i wybór płci/wariantu. Awatary to ta
	## sama pula 6 gotowych portretów co rywale AI (2 płcie × 3 warianty,
	## patrz Players.GENDERS/AVATAR_VARIANTS) — nie trzeba generować nowej
	## grafiki, chyba że kiedyś zabraknie wariantów (wtedy dopisać kolejne
	## prompty w docs/GRAFIKA_LEONARDO.md §6).
	for i in count:
		var column := ScreenHelpers.make_boxed_column(slots[i])

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
		caption.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
		name_row.add_child(caption)

		var edit := LineEdit.new()
		edit.placeholder_text = tr("Gracz %d") % (i + 1)
		edit.custom_minimum_size = Vector2(160, 0)
		edit.max_length = MAX_PLAYER_NAME_LENGTH
		edit.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
		name_row.add_child(edit)
		name_edits.append(edit)

		var choice_row := HBoxContainer.new()
		choice_row.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_child(choice_row)

		var gender_option := OptionButton.new()
		gender_option.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
		for gender in Players.GENDERS:
			gender_option.add_item(Players.GENDER_NAMES[gender])
		gender_option.item_selected.connect(_on_avatar_choice_changed.bind(i))
		choice_row.add_child(gender_option)
		gender_options.append(gender_option)

		var avatar_option := OptionButton.new()
		avatar_option.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
		for variant in Players.AVATAR_VARIANTS:
			avatar_option.add_item(Players.AVATAR_VARIANT_NAMES[variant])
		avatar_option.item_selected.connect(_on_avatar_choice_changed.bind(i))
		choice_row.add_child(avatar_option)
		avatar_options.append(avatar_option)

		_update_avatar_preview(i)

	ScreenHelpers.make_button(name_section, "Rozpocznij grę", _on_start_confirmed)
	ScreenHelpers.make_button(name_section, "Anuluj", func():
		name_box.visible = false
		setup_box.visible = true
		_clear_player_corner_frames()
	)

	setup_box.visible = false
	name_box.visible = true


## Boczne kolumny na ramki graczy — dokładnie ten sam mechanizm co
## AuctionHouse.gd _make_side_column/_build_player_frames (dwie
## pełnowysokościowe kolumny, każda podzielona rozpychaczem na GÓRNY/DOLNY
## slot), tylko top_offset=0 (MainMenu, w przeciwieństwie do Domu
## aukcyjnego, nie ma żadnej skrzynki w lewym górnym rogu, z którą trzeba by
## nie kolidować). Zwraca sloty w kolejności [prawy_dół, lewy_dół,
## prawy_góra, lewy_góra] — patrz komentarz w _show_name_entry, czemu
## akurat ta kolejność.
func _build_player_corner_frames() -> Array[VBoxContainer]:
	_clear_player_corner_frames()

	var left_root := _make_corner_column(false)
	var right_root := _make_corner_column(true)
	player_corner_columns = [left_root, right_root]

	## Rozpychacz PRZED oboma slotami (nie MIĘDZY nimi jak w AuctionHouse.gd)
	## — zgłoszone przez użytkownika: ramki gracza 3/4 (górny slot) mają być
	## obniżone tak, żeby stykały się z ramkami gracza 1/2 (dolny slot), a nie
	## rozjeżdżać się do samej góry ekranu z dużą pustą przerwą pośrodku.
	## Rozpychacz na początku pcha OBA sloty razem w dół, do samego dołu
	## kolumny — dokładnie tak samo, jak przy 1-2 graczach (tam górny slot
	## jest pusty, więc już wcześniej wyglądało to dobrze).
	left_root.add_child(ScreenHelpers.make_expand_spacer())
	var left_top := VBoxContainer.new()
	left_root.add_child(left_top)
	var left_bottom := VBoxContainer.new()
	left_root.add_child(left_bottom)

	right_root.add_child(ScreenHelpers.make_expand_spacer())
	var right_top := VBoxContainer.new()
	right_root.add_child(right_top)
	var right_bottom := VBoxContainer.new()
	right_root.add_child(right_bottom)

	var slots: Array[VBoxContainer] = [right_bottom, left_bottom, right_top, left_top]
	return slots


func _make_corner_column(on_right: bool) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.anchor_top = 0.0
	column.anchor_bottom = 1.0
	if on_right:
		column.anchor_left = 1.0
		column.anchor_right = 1.0
		column.offset_left = -ScreenHelpers.SIDE_PANEL_WIDTH
		column.offset_right = 0.0
	else:
		column.anchor_left = 0.0
		column.anchor_right = 0.0
		column.offset_left = 0.0
		column.offset_right = ScreenHelpers.SIDE_PANEL_WIDTH
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	return column


## Dzieci `self`, NIE name_section — więc _show_name_entry (które czyści
## tylko name_section.get_children()) i "Anuluj" muszą je sprzątać osobno.
func _clear_player_corner_frames() -> void:
	for column in player_corner_columns:
		column.queue_free()
	player_corner_columns.clear()


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
	Horses.reset_new_game()
	Gangsters.reset_new_game()
	ForwardContracts.reset_new_game()
	YearlyReport.reset_new_game()
	Lottery.reset_new_game()
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
