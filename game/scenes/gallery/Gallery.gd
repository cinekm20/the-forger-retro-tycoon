extends Control
## Docelowo 8 sekcji stylistycznych, po 5 slotów. Patrz GDD.md pkt. 4.7.
## Ochrona/kradzieże: docs/DODATKOWE_MECHANIKI.md.
##
## Zgłoszone przez użytkownika: "reaktywna Galeria" — oświetlenie sali
## (nakładka na tło) i głośność muzyki w tle reagują na to, jak bardzo
## kolekcja jest zapełniona (Paintings.owned_count()/win_threshold), zamiast
## samego liczbowego postępu X/5. Pusta/początkowa kolekcja = ciemna,
## przygaszona sala i cichsza muzyka; pełna kolekcja = ciepła, złota
## poświata i głośniejsza, "żywsza" muzyka. Każda w pełni skompletowana
## kategoria (5/5) dodatkowo podświetla się na złoto zamiast zwykłej kremowej
## etykiety.
##
## Zgłoszone przez użytkownika: możliwość ZOBACZENIA obrazów, nie tylko
## liczb. Trzy poziomy nawigacji w tym samym ekranie (bez osobnych scen,
## content_root czyszczony/odbudowywany przy zmianie widoku — ten sam
## wzorzec co ArtSchool.gd _start_quiz/_close_quiz):
## 1. CATEGORIES — kafelek na styl/epokę (obrazek reprezentujący epokę,
##    docs/GRAFIKA_LEONARDO.md §9b), klikalny TYLKO jeśli gracz ma już choć
##    jeden obraz w tej kategorii.
## 2. CATEGORY_DETAIL — miniaturki WŁASNYCH obrazów w wybranej kategorii.
## 3. PAINTING_DETAIL — duży obraz w tej samej ramie co Dom aukcyjny +
##    tytuł/autor/rok/muzeum (Paintings.PAINTING_INFO).

enum ViewState { CATEGORIES, CATEGORY_DETAIL, PAINTING_DETAIL }

## Kolor nakładki przy pustej kolekcji — ciemny, chłodny (przygaszona sala).
const DIM_OVERLAY_COLOR := Color(0.0, 0.0, 0.05, 0.6)
## Kolor nakładki przy pełnej kolekcji — ciepły, prawie przezroczysty (złota poświata).
const LIT_OVERLAY_COLOR := Color(0.55, 0.4, 0.1, 0.05)
## Maks. podbicie głośności muzyki w tle przy pełnej kolekcji (patrz Music.gd).
const MAX_MUSIC_VOLUME_BOOST_DB := 6.0

const CATEGORY_CARD_SIZE := Vector2(150, 170)
const CATEGORY_COVER_SIZE := Vector2(110, 110)
const THUMBNAIL_SIZE := Vector2(120, 120)
## Mniejsza niż w AuctionHouse.gd (268) — tu nie ma bocznych ramek graczy do
## zmieszczenia, więc obraz może być większy, wypełniając środek ekranu.
const PAINTING_FRAME_HOLDER_SIZE := Vector2(340, 340)
## Ta sama rama co Dom aukcyjny (art/icons/frame.png) — patrz jej komentarz
## tam co do ułamka INNER_INSET (zmierzony na samej grafice ramy).
const PAINTING_FRAME_INNER_INSET := 0.145
const FRAME_TEXTURE_PATH := "res://art/icons/frame.png"

var security_label: Label
var overlay: ColorRect
var content_root: VBoxContainer

var view_state: ViewState = ViewState.CATEGORIES
var selected_category: String = ""
var selected_number: int = -1


func _ready() -> void:
	var bg_layers := ScreenHelpers.make_background_with_overlay(self, "res://art/backgrounds/gallery.jpg")
	overlay = bg_layers["overlay"]

	var fill_ratio := float(Paintings.owned_count()) / float(Paintings.win_threshold)
	overlay.color = DIM_OVERLAY_COLOR.lerp(LIT_OVERLAY_COLOR, fill_ratio)
	Music.set_volume_offset(fill_ratio * MAX_MUSIC_VOLUME_BOOST_DB)

	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "Galeria")
	ScreenHelpers.make_turn_indicator(root)

	## Wszystko poniżej tytułu/tury żyje w content_root, czyszczonym i
	## odbudowywanym przy KAŻDEJ zmianie view_state (patrz _rebuild_content) —
	## dzięki temu przeglądanie kategorii/obrazów nie wymaga osobnej sceny
	## ani przeładowania całego ekranu.
	content_root = VBoxContainer.new()
	content_root.alignment = BoxContainer.ALIGNMENT_CENTER
	content_root.add_theme_constant_override("separation", 16)
	root.add_child(content_root)

	_rebuild_content()


## Podbicie głośności ustawione w _ready() dotyczy TYLKO tego ekranu — bez
## przywrócenia tutaj zostałoby też na Hubie/innych ekranach po wyjściu z
## Galerii, cichnąc/głośniejąc dopiero przy następnym wejściu do niej.
func _exit_tree() -> void:
	Music.set_volume_offset(0.0)


func _rebuild_content() -> void:
	for child in content_root.get_children():
		child.queue_free()
	match view_state:
		ViewState.CATEGORIES:
			_build_categories_view()
		ViewState.CATEGORY_DETAIL:
			_build_category_detail_view()
		ViewState.PAINTING_DETAIL:
			_build_painting_detail_view()


## Widok domyślny: siatka 8 kategorii (kafelek = okładka epoki + "Nazwa:
## X/5"), klikalna TYLKO gdy gracz ma tam już choć jeden obraz — plus reszta
## Galerii (postęp graczy w multiplayer, ochrona, rywale), tak jak dawniej.
func _build_categories_view() -> void:
	ScreenHelpers.make_label(content_root, tr("Twoja kolekcja: %d/%d (próg zwycięstwa)") % [
		Paintings.owned_count(), Paintings.win_threshold,
	])

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	content_root.add_child(grid)

	for category_id in Paintings.CATEGORIES:
		_build_category_card(grid, category_id)

	if Players.is_multiplayer():
		ScreenHelpers.make_title(content_root, "Gracze")
		for i in Players.player_count:
			var marker := tr(" (Ty)") if i == Players.active_index else ""
			ScreenHelpers.make_label(content_root, tr("%s%s: %d obrazów") % [
				Players.player_names[i], marker, Players.get_painting_count(i),
			])

	ScreenHelpers.make_title(content_root, "Ochrona")
	security_label = ScreenHelpers.make_label(content_root, "")
	var bodyguard_btn := ScreenHelpers.make_button(
		content_root,
		tr("Zatrudnij ochroniarza (%.0f M)") % Security.BODYGUARD_COST,
		_on_hire_bodyguard_pressed,
	)
	bodyguard_btn.disabled = Security.has_bodyguard
	_update_security_label()

	ScreenHelpers.make_title(content_root, "Rywale")
	for rival in AIPlayers.rivals:
		var rival_row := HBoxContainer.new()
		rival_row.alignment = BoxContainer.ALIGNMENT_CENTER
		content_root.add_child(rival_row)
		var rival_label := Label.new()
		rival_label.text = tr("%s: %d obrazów") % [rival["name"], AIPlayers.get_rival_painting_count(rival["id"])]
		rival_row.add_child(rival_label)
		var gangster_btn := Button.new()
		gangster_btn.text = tr("Wyślij gangstera (%.0f M)") % Security.GANGSTER_COST
		gangster_btn.pressed.connect(_on_send_gangster_pressed.bind(rival["id"]))
		rival_row.add_child(gangster_btn)

	ScreenHelpers.make_back_button(content_root)


## Jeden kafelek kategorii: okładka epoki (art/categories/<id>.jpg, docs/
## GRAFIKA_LEONARDO.md §9b — po cichu pusta, jeśli plik jeszcze nie istnieje,
## jak wszystkie opcjonalne grafiki w tej grze) + nazwa + "X/5". Klikalny
## TYLKO jeśli owned_in_category > 0 (zgłoszone przez użytkownika: "po
## kliknięciu jak są tam jakieś obrazy") — niewidzialny, płaski Button
## dodany NA WIERZCH całej skrzynki (ten sam trik co Plantation.gd
## _rebuild_grid: PanelContainer daje WSZYSTKIM dzieciom tę samą wypełnioną
## powierzchnię, więc button-na-wierzchu przechwytuje kliknięcia z całego
## kafelka, nie tylko samego obrazka).
func _build_category_card(parent: Container, category_id: String) -> void:
	var owned_in_category := 0
	for number in Paintings.catalogued_numbers:
		if Paintings.get_category(number) == category_id:
			owned_in_category += 1

	var column := ScreenHelpers.make_boxed_column(parent)
	column.custom_minimum_size = CATEGORY_CARD_SIZE

	var cover_center := CenterContainer.new()
	column.add_child(cover_center)
	var cover_rect := TextureRect.new()
	cover_rect.custom_minimum_size = CATEGORY_COVER_SIZE
	cover_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cover_rect.stretch_mode = TextureRect.STRETCH_SCALE
	cover_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cover_path := "res://art/categories/%s.jpg" % category_id
	if ResourceLoader.exists(cover_path):
		cover_rect.texture = load(cover_path)
	## Wyszarzona okładka, gdy nic jeszcze nie skatalogowano w tej kategorii
	## — wizualna podpowiedź, że kafelek NIE jest (jeszcze) klikalny.
	cover_rect.modulate = Color(1, 1, 1) if owned_in_category > 0 else Color(0.35, 0.35, 0.35)
	cover_center.add_child(cover_rect)

	var category_name: String = Paintings.CATEGORY_NAMES[category_id]
	var name_label := ScreenHelpers.make_label(column, tr("%s: %d/5") % [category_name, owned_in_category])
	if owned_in_category >= 5:
		name_label.add_theme_color_override("font_color", ScreenHelpers.COLOR_GOLD_BRIGHT)

	if owned_in_category > 0:
		var overlay_btn := Button.new()
		overlay_btn.flat = true
		overlay_btn.pressed.connect(_on_category_pressed.bind(category_id))
		column.get_parent().add_child(overlay_btn)


func _on_category_pressed(category_id: String) -> void:
	selected_category = category_id
	view_state = ViewState.CATEGORY_DETAIL
	_rebuild_content()


## Widok pośredni: miniaturki WŁASNYCH obrazów w wybranej kategorii —
## klikalne, otwierają duży podgląd (patrz _build_painting_detail_view).
func _build_category_detail_view() -> void:
	var category_name: String = Paintings.CATEGORY_NAMES.get(selected_category, selected_category)
	ScreenHelpers.make_title(content_root, category_name)

	var owned_numbers: Array[int] = []
	for number in Paintings.catalogued_numbers:
		if Paintings.get_category(number) == selected_category:
			owned_numbers.append(number)
	owned_numbers.sort()

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	content_root.add_child(grid)

	for number in owned_numbers:
		_build_painting_thumbnail(grid, number)

	ScreenHelpers.make_button(content_root, tr("« Wróć do galerii"), _on_back_to_categories_pressed)


## Miniaturka JEDNEGO obrazu — flat=true (bez zwykłego tła/ramki przycisku,
## widoczna tylko ikonka), TextureRect jako dziecko wypełniające cały
## przycisk (ten sam trik co kafelki Plantation.gd _rebuild_grid).
func _build_painting_thumbnail(parent: Container, number: int) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = THUMBNAIL_SIZE
	btn.flat = true
	btn.pressed.connect(_on_painting_pressed.bind(number))

	var thumb_rect := TextureRect.new()
	thumb_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	thumb_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb_rect.stretch_mode = TextureRect.STRETCH_SCALE
	thumb_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var texture_path := Paintings.get_texture_path(number)
	if ResourceLoader.exists(texture_path):
		thumb_rect.texture = load(texture_path)
	btn.add_child(thumb_rect)

	parent.add_child(btn)


func _on_painting_pressed(number: int) -> void:
	selected_number = number
	view_state = ViewState.PAINTING_DETAIL
	_rebuild_content()


func _on_back_to_categories_pressed() -> void:
	view_state = ViewState.CATEGORIES
	_rebuild_content()


func _on_back_to_category_detail_pressed() -> void:
	view_state = ViewState.CATEGORY_DETAIL
	_rebuild_content()


## Widok końcowy: duży obraz w tej samej ozdobnej ramie co Dom aukcyjny
## (art/icons/frame.png) + pełne informacje (tytuł/autor/rok/muzeum,
## Paintings.PAINTING_INFO). Zawsze prawdziwa grafika (is_fake=false) — obraz
## trafia do catalogued_numbers TYLKO gdy nie jest fałszywką (patrz
## AuctionHouse.gd _resolve_auction: podróbka nigdy nie wchodzi do kolekcji),
## więc w Galerii nie ma czego rozróżniać.
func _build_painting_detail_view() -> void:
	var number := selected_number
	var category: String = Paintings.get_category(number)
	var category_name: String = Paintings.CATEGORY_NAMES.get(category, category)
	var info := Paintings.get_painting_info(number)

	var frame_center := CenterContainer.new()
	content_root.add_child(frame_center)

	var frame_holder := Control.new()
	frame_holder.custom_minimum_size = PAINTING_FRAME_HOLDER_SIZE
	frame_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_center.add_child(frame_holder)

	## Rama dodana PIERWSZA (rysuje się pod spodem) — jej wnętrze na
	## frame.png jest w całości nieprzezroczyste, więc dopiero obraz DODANY
	## PO NIEJ (rysuje się na wierzchu) w pełni je zasłania (ten sam
	## dwuwarstwowy układ co AuctionHouse.gd _build_active_auction_ui).
	var frame_rect := TextureRect.new()
	frame_rect.texture = load(FRAME_TEXTURE_PATH)
	frame_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame_rect.stretch_mode = TextureRect.STRETCH_SCALE
	frame_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_holder.add_child(frame_rect)

	var painting_rect := TextureRect.new()
	painting_rect.anchor_left = PAINTING_FRAME_INNER_INSET
	painting_rect.anchor_top = PAINTING_FRAME_INNER_INSET
	painting_rect.anchor_right = 1.0 - PAINTING_FRAME_INNER_INSET
	painting_rect.anchor_bottom = 1.0 - PAINTING_FRAME_INNER_INSET
	painting_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	painting_rect.stretch_mode = TextureRect.STRETCH_SCALE
	painting_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var texture_path := Paintings.get_texture_path(number)
	if ResourceLoader.exists(texture_path):
		painting_rect.texture = load(texture_path)
	frame_holder.add_child(painting_rect)

	if not info.is_empty():
		ScreenHelpers.make_label(content_root, tr("„%s” — %s, %s") % [tr(info["title"]), info["artist"], info["year"]])
		ScreenHelpers.make_label(content_root, tr("%s — %s") % [category_name, info["museum"]])
	else:
		ScreenHelpers.make_label(content_root, tr("Obraz nr %d — %s") % [number, category_name])

	ScreenHelpers.make_button(content_root, tr("« Wróć"), _on_back_to_category_detail_pressed)


func _on_hire_bodyguard_pressed() -> void:
	if Security.hire_bodyguard():
		_update_security_label()
		SceneRouter.goto_scene(SceneRouter.GALLERY)  # przeładuj, żeby odświeżyć stan przycisku


func _on_send_gangster_pressed(rival_id: String) -> void:
	var success := Security.send_gangster(rival_id)
	security_label.text = (
		tr("Gangster wraca z obrazem!") if success else tr("Gangster wraca z pustymi rękami — pieniądze przepadły.")
	)


func _update_security_label() -> void:
	security_label.text = (
		tr("Masz ochroniarza — obrazy chronione przed kradzieżą.")
		if Security.has_bodyguard
		else tr("Bez ochrony — Twoja kolekcja jest narażona na kradzież (~%.0f%% szans/tydzień).") % [
			Security.WEEKLY_THEFT_CHANCE_UNPROTECTED * 100.0,
		]
	)
