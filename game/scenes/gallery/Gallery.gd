extends Control
## Docelowo 8 sekcji stylistycznych, po 5 slotów. Patrz GDD.md pkt. 4.7.
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
## 1. CATEGORIES — kafelek na styl/epokę, w tej samej ozdobnej ramie co
##    obrazy w Domu aukcyjnym (obrazek reprezentujący epokę, docs/
##    GRAFIKA_LEONARDO.md §9b), klikalny TYLKO jeśli gracz ma już choć
##    jeden obraz w tej kategorii. Kafelki rozciągnięte równomiernie na
##    całą szerokość ekranu (SIZE_EXPAND_FILL) — zgłoszone przez użytkownika.
## 2. CATEGORY_DETAIL — miniaturki WŁASNYCH obrazów w wybranej kategorii.
## 3. PAINTING_DETAIL — duży obraz w tej samej ramie + tytuł/autor/rok/
##    muzeum (Paintings.PAINTING_INFO).
##
## Ochrona (ochroniarz) i Rywale (gangster) NIE są już częścią tego ekranu —
## zgłoszone przez użytkownika: to nie ma nic wspólnego z przeglądaniem
## kolekcji, więc dostały własny ekran (scenes/security/SecurityScreen.gd),
## osiągalny z Huba niezależnie od Galerii. Ta sama zmiana usunęła też
## ozdobną ramkę na cały ekran (make_root(self, false), jak Dom aukcyjny).

enum ViewState { CATEGORIES, CATEGORY_DETAIL, PAINTING_DETAIL }

## Kolor nakładki przy pustej kolekcji — ciemny, chłodny (przygaszona sala).
const DIM_OVERLAY_COLOR := Color(0.0, 0.0, 0.05, 0.6)
## Kolor nakładki przy pełnej kolekcji — ciepły, prawie przezroczysty (złota poświata).
const LIT_OVERLAY_COLOR := Color(0.55, 0.4, 0.1, 0.05)
## Maks. podbicie głośności muzyki w tle przy pełnej kolekcji (patrz Music.gd).
const MAX_MUSIC_VOLUME_BOOST_DB := 6.0

const CATEGORY_CARD_SIZE := Vector2(160, 190)
const CATEGORY_FRAME_SIZE := Vector2(140, 140)
## Zgłoszone przez użytkownika: miniaturki w widoku kategorii mają być
## większe (poprzednio 120x120) — do 3 w rzędzie mieszczą się wygodnie w
## logicznej szerokości ekranu razem z odstępami z _build_category_detail_view.
const THUMBNAIL_SIZE := Vector2(210, 210)
## Większa niż okładka kategorii — tu nie ma siatki, tylko jeden obraz
## wypełniający środek ekranu. Zgłoszone przez użytkownika: obraz w
## podglądzie ma być większy (poprzednio 340x340).
const PAINTING_FRAME_SIZE := Vector2(480, 480)
## Ta sama rama co Dom aukcyjny (art/icons/frame.png) — patrz jej komentarz
## tam co do ułamka INNER_INSET (zmierzony na samej grafice ramy).
const FRAME_INNER_INSET := 0.145
const FRAME_TEXTURE_PATH := "res://art/icons/frame.png"

var overlay: ColorRect
var content_root: VBoxContainer
## Przycisk powrotu we WSPÓLNEJ, ozdobnej skrzynce Art Deco (patrz
## ScreenHelpers.make_boxed_back_button) — zgłoszone przez użytkownika:
## wygląda tak samo jak wszędzie indziej w grze. Budowany RAZ w _ready()
## (poza content_root, który sam jest czyszczony/odbudowywany przy każdej
## zmianie widoku), tekst/cel podmieniany w _rebuild_content() zależnie od
## view_state — inaczej trzy osobne widoki próbowałyby dokładać trzy osobne
## takie skrzynki jedna na drugą.
var boxed_back_btn: Button

var view_state: ViewState = ViewState.CATEGORIES
var selected_category: String = ""
var selected_number: int = -1


func _ready() -> void:
	## Zgłoszone przez użytkownika: zwykłe tło Galerii wyszło zbyt wypełnione
	## (ściany już obwieszone własnymi obrazami/ławkami/żyrandolem), więc
	## konkurowało wizualnie z kafelkami/podglądem, które gra nakłada na
	## wierzchu (_build_framed_image). Preferowany prostszy wariant
	## (docs/GRAFIKA_LEONARDO.md §9) — po cichu spada z powrotem na zwykłe
	## tło, dopóki plik nie istnieje, tak jak wszystkie opcjonalne grafiki.
	var background_path := "res://art/backgrounds/gallery_empty.jpg"
	if not ResourceLoader.exists(background_path):
		background_path = "res://art/backgrounds/gallery.jpg"
	var bg_layers := ScreenHelpers.make_background_with_overlay(self, background_path)
	overlay = bg_layers["overlay"]

	var fill_ratio := float(Paintings.owned_count()) / float(Paintings.win_threshold)
	overlay.color = DIM_OVERLAY_COLOR.lerp(LIT_OVERLAY_COLOR, fill_ratio)
	Music.set_volume_offset(fill_ratio * MAX_MUSIC_VOLUME_BOOST_DB)

	## use_menu_frame=false: zgłoszone przez użytkownika — ozdobna ramka na
	## cały ekran ma zniknąć (ten sam fix co wcześniej w AuctionHouse.gd).
	var root := ScreenHelpers.make_root(self, false)
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

	boxed_back_btn = ScreenHelpers.make_button(ScreenHelpers.make_root_bottom(self, true), "", _on_boxed_back_pressed)

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
			boxed_back_btn.text = "« Powrót"
		ViewState.CATEGORY_DETAIL:
			_build_category_detail_view()
			boxed_back_btn.text = tr("« Wróć do galerii")
		ViewState.PAINTING_DETAIL:
			_build_painting_detail_view()
			boxed_back_btn.text = tr("« Wróć")


## Dispatcher jednego wspólnego przycisku (boxed_back_btn, patrz _ready) —
## co dokładnie robi zależy od AKTUALNEGO view_state w momencie kliknięcia,
## nie od tego, jaki widok był aktywny, gdy przycisk zbudowano (budowany
## tylko RAZ, patrz komentarz przy zmiennej).
func _on_boxed_back_pressed() -> void:
	match view_state:
		ViewState.CATEGORIES:
			SceneRouter.goto_hub()
		ViewState.CATEGORY_DETAIL:
			_on_back_to_categories_pressed()
		ViewState.PAINTING_DETAIL:
			_on_back_to_category_detail_pressed()


## Widok domyślny: siatka 8 kategorii (kafelek = okładka epoki w ramie +
## "Nazwa: X/5"), klikalna TYLKO gdy gracz ma tam już choć jeden obraz.
## BEZ podsumowania postępu innych graczy (zgłoszone przez użytkownika: to
## jest galeria WŁASNYCH obrazów, nie ma tu co pokazywać, kto ile ma —
## wcześniej pokazywane w multiplayer, teraz usunięte na każdym ekranie).
func _build_categories_view() -> void:
	## Zgłoszone przez użytkownika: ten sam ekran ("Galeria") też ma mieć
	## przycisk powrotu przypięty do samego dołu — wcześniej content_root
	## (ALIGNMENT_CENTER + domyślne SIZE_FILL, czyli kurczy się do naturalnego
	## rozmiaru treści) tylko WYGLĄDAŁ na przypięty, kiedy siatka 8 kategorii
	## akurat wypełniała prawie cały ekran; przy mniejszej treści (np. mniej
	## kategorii, krótsza lista graczy) przycisk floatowałby wyżej. "Galeria"
	## u góry jest już przypięte NA ZEWNĄTRZ content_root (patrz _ready), więc
	## tu wystarczy JEDEN rozpychacz na samym końcu — treść zaczyna się od
	## razu pod nagłówkiem, przycisk zostaje przyklejony do dołu.
	content_root.alignment = BoxContainer.ALIGNMENT_BEGIN
	content_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ScreenHelpers.make_label(content_root, tr("Twoja kolekcja: %d/%d (próg zwycięstwa)") % [
		Paintings.owned_count(), Paintings.win_threshold,
	])

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	content_root.add_child(grid)

	for category_id in Paintings.CATEGORIES:
		_build_category_card(grid, category_id)


## Rama identyczna jak w Domu aukcyjnym (art/icons/frame.png) wokół
## dowolnego kwadratowego obrazka — dodana PIERWSZA (rysuje się pod spodem,
## jej wnętrze jest w całości nieprzezroczyste), obraz DODANY PO NIEJ
## zasłania je w pełni. dim=true wygasza WEWNĘTRZNY obraz (nie samą ramę) —
## używane dla kategorii bez żadnego skatalogowanego obrazu, jako wizualna
## podpowiedź "jeszcze nieklikalne".
## parent: Control (NIE Container) — wywoływane zarówno z Containerów
## (CenterContainer w _build_category_card/_build_painting_detail_view) jak
## i z płaskiego Button (_build_painting_thumbnail, Button NIE dziedziczy po
## Container), a funkcja tylko dodaje dziecko, więc wystarczy najszerszy
## wspólny typ.
func _build_framed_image(parent: Control, texture_path: String, holder_size: Vector2, dim: bool = false) -> void:
	var frame_holder := Control.new()
	frame_holder.custom_minimum_size = holder_size
	frame_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(frame_holder)

	var frame_rect := TextureRect.new()
	frame_rect.texture = load(FRAME_TEXTURE_PATH)
	frame_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame_rect.stretch_mode = TextureRect.STRETCH_SCALE
	frame_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_holder.add_child(frame_rect)

	var inner_rect := TextureRect.new()
	inner_rect.anchor_left = FRAME_INNER_INSET
	inner_rect.anchor_top = FRAME_INNER_INSET
	inner_rect.anchor_right = 1.0 - FRAME_INNER_INSET
	inner_rect.anchor_bottom = 1.0 - FRAME_INNER_INSET
	inner_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	inner_rect.stretch_mode = TextureRect.STRETCH_SCALE
	inner_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(texture_path):
		inner_rect.texture = load(texture_path)
	inner_rect.modulate = Color(0.35, 0.35, 0.35) if dim else Color(1, 1, 1)
	frame_holder.add_child(inner_rect)


## Jeden kafelek kategorii: okładka epoki w ramie (art/categories/<id>.jpg,
## docs/GRAFIKA_LEONARDO.md §9b — po cichu pusta, jeśli plik jeszcze nie
## istnieje, jak wszystkie opcjonalne grafiki w tej grze) + nazwa + "X/5".
## BEZ dodatkowej burgundowo-złotej skrzynki dookoła (zgłoszone przez
## użytkownika: "te ramki systemowe pod obrazami zlikwiduj") — sama rama
## obrazu (frame.png, _build_framed_image) już wystarcza, druga rama byłaby
## zbędnym dublowaniem. Klikalny TYLKO jeśli owned_in_category > 0
## (zgłoszone przez użytkownika: "po kliknięciu jak są tam jakieś obrazy") —
## flat Button jako NAJBARDZIEJ ZEWNĘTRZNY węzeł z resztą jako dzieckiem
## (ten sam trik co kafelki Plantation.gd _rebuild_grid), więc cały kafelek
## jest klikalny, nie tylko sam obrazek. size_flags_horizontal NA PRZYCISKU
## — zgłoszone przez użytkownika: kafelki mają się rozłożyć równomiernie na
## całą szerokość ekranu, nie zbić w ciasną grupkę po lewej.
func _build_category_card(parent: Container, category_id: String) -> void:
	var owned_in_category := 0
	for number in Paintings.catalogued_numbers:
		if Paintings.get_category(number) == category_id:
			owned_in_category += 1

	var card_btn := Button.new()
	card_btn.custom_minimum_size = CATEGORY_CARD_SIZE
	card_btn.flat = true
	card_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_btn.disabled = owned_in_category == 0
	if owned_in_category > 0:
		card_btn.pressed.connect(_on_category_pressed.bind(category_id))
	parent.add_child(card_btn)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_btn.add_child(column)

	var cover_center := CenterContainer.new()
	column.add_child(cover_center)
	var cover_path := "res://art/categories/%s.jpg" % category_id
	_build_framed_image(cover_center, cover_path, CATEGORY_FRAME_SIZE, owned_in_category == 0)

	var category_name: String = tr(Paintings.CATEGORY_NAMES[category_id])
	var name_label := ScreenHelpers.make_label(column, tr("%s: %d/5") % [category_name, owned_in_category])
	if owned_in_category >= 5:
		name_label.add_theme_color_override("font_color", ScreenHelpers.COLOR_GOLD_BRIGHT)


func _on_category_pressed(category_id: String) -> void:
	selected_category = category_id
	view_state = ViewState.CATEGORY_DETAIL
	_rebuild_content()


## Widok pośredni: miniaturki WŁASNYCH obrazów w wybranej kategorii, w tej
## samej ramie co Dom aukcyjny — klikalne, otwierają duży podgląd (patrz
## _build_painting_detail_view). Układ zawsze WYŚRODKOWANY, w kształcie
## odwróconej piramidy (zgłoszone przez użytkownika) — każda kategoria ma z
## założenia dokładnie 5 obrazów (GDD.md pkt. 4.7: "8 kategorii × 5 slotów"),
## więc liczba miniatur tu to zawsze 1-5, stąd zamknięty podział na wiersze
## zamiast ogólnej siatki (patrz _split_into_centered_rows).
func _build_category_detail_view() -> void:
	## Zgłoszone przez użytkownika: tytuł kategorii ma być ZAWSZE na samej
	## górze ekranu, przycisk powrotu ZAWSZE na samym dole, i oba nigdy nie
	## powinny się ruszać niezależnie od liczby miniatur pomiędzy nimi.
	## ALIGNMENT_BEGIN + rozpychacz SIZE_EXPAND_FILL po obu stronach środkowej
	## zawartości — ten sam wzorzec co ScreenHelpers.make_expand_spacer.
	## Samo ALIGNMENT_BEGIN NIE WYSTARCZY: content_root domyślnie (SIZE_FILL)
	## kurczy się do naturalnego rozmiaru własnej treści, więc cały ten blok
	## (tytuł+rozpychacze+przycisk) i tak wypadał wyśrodkowany na środku
	## ekranu przez ALIGNMENT_CENTER nadrzędnego root (zgłoszone przez
	## użytkownika po poprzedniej, niepełnej poprawce: "napis miał być na
	## samej górze ekranu w guzik na samym dole"). SIZE_EXPAND_FILL sprawia,
	## że content_root wypełnia CAŁĄ dostępną wysokość poniżej "Galeria"/
	## wskaźnika tury w root — dopiero wtedy rozpychacze w środku mają czym
	## rozepchnąć tytuł i przycisk do prawdziwych krawędzi ekranu.
	content_root.alignment = BoxContainer.ALIGNMENT_BEGIN
	content_root.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var category_name: String = tr(Paintings.CATEGORY_NAMES.get(selected_category, selected_category))
	ScreenHelpers.make_title(content_root, category_name)

	content_root.add_child(ScreenHelpers.make_expand_spacer())

	var owned_numbers: Array[int] = []
	for number in Paintings.catalogued_numbers:
		if Paintings.get_category(number) == selected_category:
			owned_numbers.append(number)
	owned_numbers.sort()

	var rows_root := VBoxContainer.new()
	rows_root.alignment = BoxContainer.ALIGNMENT_CENTER
	rows_root.add_theme_constant_override("separation", 12)
	content_root.add_child(rows_root)

	for row_numbers in _split_into_centered_rows(owned_numbers):
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 12)
		rows_root.add_child(row)
		for number in row_numbers:
			_build_painting_thumbnail(row, number)

	content_root.add_child(ScreenHelpers.make_expand_spacer())


## Dzieli listę numerów (1-5 elementów) na wiersze do wyśrodkowanej
## "piramidy": 1/2/3 -> jeden wiersz (HBoxContainer z ALIGNMENT_CENTER sam
## wyśrodkuje 1 element na środku, 2 elementy tak, że środek wypada MIĘDZY
## nimi, 3 elementy tak, że środkowy trafia na środek — zgłoszone przez
## użytkownika, dokładnie te trzy przypadki); 4 -> [3, 1] (3 u góry, 1 na
## dole na środku); 5 -> [3, 2] (3 u góry, 2 na dole, środek między nimi).
## Domyślna gałąź (>5) nie powinna wystąpić przy obecnym katalogu (5/kategoria),
## ale defensywnie dzieli po 3, żeby funkcja nigdy nie ucięła obrazów.
func _split_into_centered_rows(numbers: Array[int]) -> Array:
	match numbers.size():
		1, 2, 3:
			return [numbers]
		4:
			return [numbers.slice(0, 3), numbers.slice(3, 4)]
		5:
			return [numbers.slice(0, 3), numbers.slice(3, 5)]
		_:
			var rows: Array = []
			var i := 0
			while i < numbers.size():
				rows.append(numbers.slice(i, mini(i + 3, numbers.size())))
				i += 3
			return rows


## Miniaturka JEDNEGO obrazu w tej samej ramie co Dom aukcyjny/okładki
## kategorii (_build_framed_image) — flat Button jako najbardziej
## zewnętrzny węzeł (ten sam trik co kafelki kategorii/Plantation.gd
## _rebuild_grid), więc cały kafelek jest klikalny.
func _build_painting_thumbnail(parent: Container, number: int) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = THUMBNAIL_SIZE
	btn.flat = true
	btn.pressed.connect(_on_painting_pressed.bind(number))
	parent.add_child(btn)
	_build_framed_image(btn, Paintings.get_texture_path(number), THUMBNAIL_SIZE)


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


## Widok końcowy: duży obraz w tej samej ozdobnej ramie co kafelki kategorii
## + pełne informacje (tytuł/autor/rok/muzeum, Paintings.PAINTING_INFO).
## Zawsze prawdziwa grafika (is_fake=false) — obraz trafia do
## catalogued_numbers TYLKO gdy nie jest fałszywką (patrz AuctionHouse.gd
## _resolve_auction: podróbka nigdy nie wchodzi do kolekcji), więc w
## Galerii nie ma czego rozróżniać.
func _build_painting_detail_view() -> void:
	## Ten sam wzorzec przypięcia co _build_category_detail_view (zgłoszone
	## przez użytkownika: "w podglądzie jednego obrazu tak samo trzeba
	## zrobić") — content_root wypełnia całą dostępną wysokość, obraz+opis
	## trzymają się góry (zaraz pod "Galeria"/wskaźnikiem tury), przycisk
	## "Wróć" zawsze na samym dole, niezależnie od długości podpisu.
	content_root.alignment = BoxContainer.ALIGNMENT_BEGIN
	content_root.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var number := selected_number
	var category: String = Paintings.get_category(number)
	var category_name: String = tr(Paintings.CATEGORY_NAMES.get(category, category))
	var info := Paintings.get_painting_info(number)

	var frame_center := CenterContainer.new()
	content_root.add_child(frame_center)
	_build_framed_image(frame_center, Paintings.get_texture_path(number), PAINTING_FRAME_SIZE)

	if not info.is_empty():
		ScreenHelpers.make_label(content_root, tr("„%s” — %s, %s") % [tr(info["title"]), info["artist"], info["year"]])
		ScreenHelpers.make_label(content_root, tr("%s — %s") % [category_name, info["museum"]])
	else:
		ScreenHelpers.make_label(content_root, tr("Obraz nr %d — %s") % [number, category_name])

	content_root.add_child(ScreenHelpers.make_expand_spacer())
