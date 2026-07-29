class_name ScreenHelpers
## Wspólne, minimalne budowniczowie UI dla placeholderowych ekranów.
## Docelowo zastąpione właściwymi scenami z grafiką (docs/GRAFIKA_LEONARDO.md).


## Pełnoekranowe tło + półprzezroczysta nakładka (dla czytelności tekstu na
## bogatej w szczegóły grafice). Wywoływać PRZED make_root, żeby tło zostało
## dodane jako pierwsze dziecko (czyli renderuje się pod resztą UI).
static func make_background(parent: Control, texture_path: String) -> TextureRect:
	return make_background_with_overlay(parent, texture_path)["background"]


## Jak make_background(), ale zwraca też nakładkę — potrzebne tam, gdzie
## tło animuje się osobno od reszty ekranu (np. zoom-out/zoom-in między
## Hub.gd a TravelAnimation.gd) i trzeba wygasić nakładkę razem z nim,
## zamiast zostawiać ją jako samotny ciemny prostokąt na wierzchu.
static func make_background_with_overlay(parent: Control, texture_path: String) -> Dictionary:
	var bg := TextureRect.new()
	bg.texture = load(texture_path)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	parent.add_child(bg)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.45)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(overlay)
	return {"background": bg, "overlay": overlay}


const MenuFrameScript := preload("res://scripts/ui/MenuFrame.gd")
## 380 (nie 320) — dopasowane do większych przycisków z make_button (320px
## min. szerokości) + CONTENT_INSET_WITH_FRAME z obu stron, żeby przyciski
## boczne (Hub.gd) mieściły się w panelu zamiast go rozpychać.
const SIDE_PANEL_WIDTH := 380.0
## Odstęp treści od narysowanej krawędzi MenuFrame — patrz make_root_side.
const CONTENT_INSET_WITH_FRAME := 26.0

## mouse_filter = IGNORE na kontenerze jest ważne: bez tego niewidzialne tło
## pełnoekranowego VBoxContainer przechwytuje kliknięcia na CAŁYM ekranie
## (nawet w miejscach bez żadnego widocznego elementu UI), blokując np.
## pinezki mapy leżące pod spodem. Same przyciski/etykiety w środku mają
## własny filtr i nadal reagują na dotyk normalnie.
##
## use_menu_frame=true (domyślne) wyśrodkowuje treść w tej samej ozdobnej
## ramce co Hub.gd/TravelMap.gd (MenuFrame) — dla spójności wizualnej na
## WSZYSTKICH ekranach placeholderowych (Galeria, Dom aukcyjny, Szkoła
## sztuki, Plantacje, Giełda, Wyścigi, Ending, MainMenu), nie tylko w menu
## nawigacyjnym Huba.
##
## Ramka (content) ma STAŁY rozmiar — 90% ekranu w obu wymiarach (anchory
## 0.05..0.95), NIE rośnie z treścią. Wcześniej robił to CenterContainer
## (rozmiar = rozmiar treści), co dla ekranów z dużo treścią (Galeria z
## listą rywali, Giełda z listą spółek) dawało ramkę WIĘKSZĄ niż ekran —
## dolne przyciski (np. "Powrót") wypadały poza widoczny obszar,
## niewidoczne i nieklikalne (zgłoszone przez użytkownika na zrzucie
## ekranu). Treść (root) jest teraz w ScrollContainer — jeśli mieści się
## w 90% ekranu, wygląda tak samo jak wcześniej; jeśli nie, dostaje pasek
## przewijania zamiast wypadać poza kadr.
static func make_root(parent: Control, use_menu_frame: bool = true) -> VBoxContainer:
	if not use_menu_frame:
		var plain_root := VBoxContainer.new()
		plain_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		plain_root.alignment = BoxContainer.ALIGNMENT_CENTER
		plain_root.add_theme_constant_override("separation", 16)
		plain_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(plain_root)
		return plain_root

	var wrapper := Control.new()
	wrapper.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(wrapper)

	var content := PanelContainer.new()
	content.anchor_left = 0.05
	content.anchor_top = 0.05
	content.anchor_right = 0.95
	content.anchor_bottom = 0.95
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	wrapper.add_child(content)

	var frame: Control = MenuFrameScript.new()
	content.add_child(frame)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := int(CONTENT_INSET_WITH_FRAME)
	margin.add_theme_constant_override("margin_left", m)
	margin.add_theme_constant_override("margin_right", m)
	margin.add_theme_constant_override("margin_top", m)
	margin.add_theme_constant_override("margin_bottom", m)
	content.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 16)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(root)
	return root

## Wąski panel przy krawędzi ekranu (stała szerokość, pełna wysokość) z
## tłem pod przyciskami — dla ekranów, gdzie reszta ekranu (np. mapa z
## klikalnymi pinezkami) musi zostać odsłonięta, a nie tylko odsłonięta w
## pionie jak przy make_root() (ten pełną szerokością i tak zasłaniał
## grafikę pod spodem). Anchory/offsety ustawiane RĘCZNIE, nie przez
## set_anchors_preset() — ten liczy offsety na podstawie rozmiaru
## kontenera W MOMENCIE WYWOŁANIA (czyli 0×0, zanim dojdą jakiekolwiek
## dzieci), więc dla non-pełnoekranowych presetów zostaje trwale
## zablokowany na zerowym rozmiarze. Ręczne anchory z ułamkowym anchor +
## stałym pikselowym offsetem nie mają tego problemu.
##
## use_menu_frame=true podmienia zwykłe półprzezroczyste tło na ozdobną
## ramkę rysowaną natywnie (MenuFrame.gd) — próba z gotową grafiką z
## Leonardo (NinePatchRect na rozciąganym obrazku) wyglądała źle: pojedyncze
## motywy zdobne przy krawędziach zniekształcały się przy rozciąganiu do
## wąskiego, wysokiego panelu. Rysowana w kodzie ramka skaluje się
## bez artefaktów do dowolnej wysokości (różne miasta mają różną liczbę
## pozycji w menu). Używane przez Hub.gd i TravelAnimation.gd — TravelMap
## ma analogiczną ramkę, ale w poziomym pasku u dołu ekranu (patrz
## make_root_bottom niżej).
##
## Z ramką pasek jest domyślnie dodatkowo wcięty od góry o
## TOP_OFFSET_WITH_FRAME — bez tego pełnowysokościowa ramka w Hub.gd
## renderowała się NAD skrzynką gotówki z _build_top_row (obie leżą w tej
## samej, prawej kolumnie ekranu, a ramka jest dodawana do drzewa później,
## więc rysuje się na wierzchu). top_offset_override pozwala to wyłączyć
## (np. TravelAnimation.gd, który nie ma żadnego top_row) — wartość < 0.0
## (domyślna) oznacza "użyj TOP_OFFSET_WITH_FRAME, jeśli use_menu_frame".
## Same przyciski (root) dostają dodatkowo CONTENT_INSET_WITH_FRAME z każdej
## strony, żeby nie nachodziły na narysowaną krawędź ramki
## (MenuFrame.INNER_MARGIN = 13px). CONTENT_INSET_WITH_FRAME zdefiniowany
## wyżej, przy make_root().
const TOP_OFFSET_WITH_FRAME := 190.0

static func make_root_side(
	parent: Control, on_right: bool = true, use_menu_frame: bool = false, top_offset_override: float = -1.0
) -> VBoxContainer:
	var top_offset := top_offset_override
	if top_offset < 0.0:
		top_offset = TOP_OFFSET_WITH_FRAME if use_menu_frame else 0.0
	if use_menu_frame:
		var frame: Control = MenuFrameScript.new()
		_anchor_side_strip(frame, on_right, top_offset)
		parent.add_child(frame)
	else:
		var panel_bg := ColorRect.new()
		panel_bg.color = Color(COLOR_BURGUNDY_DARK.r, COLOR_BURGUNDY_DARK.g, COLOR_BURGUNDY_DARK.b, 0.8)
		panel_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_anchor_side_strip(panel_bg, on_right, top_offset)
		parent.add_child(panel_bg)

	## ScrollContainer — bez tego lista przycisków (np. Hub.gd: "Jedź »" + do
	## 3 bramkowane wg miasta + 3 darmowe + "Koniec tury" + "Zapisz i wyjdź" —
	## do 8 przycisków naraz) mogła przekroczyć wysokość dostępnego paska,
	## zwłaszcza po powiększeniu przycisków (patrz make_button, 46 -> 58px) —
	## nadmiarowe przyciski wypadały wtedy poza dolną krawędź ekranu, niewidoczne
	## i nieklikalne. Zgłoszone przez użytkownika: przyciski muszą być zawsze
	## widoczne/osiągalne, na każdej rozdzielczości.
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_anchor_side_strip(scroll, on_right, top_offset, CONTENT_INSET_WITH_FRAME if use_menu_frame else 0.0)
	parent.add_child(scroll)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 14)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(root)
	return root


static func _anchor_side_strip(control: Control, on_right: bool, top_offset: float = 0.0, inset: float = 0.0) -> void:
	control.anchor_top = 0.0
	control.anchor_bottom = 1.0
	control.offset_top = top_offset + inset
	control.offset_bottom = -inset
	if on_right:
		control.anchor_left = 1.0
		control.anchor_right = 1.0
		control.offset_left = -SIDE_PANEL_WIDTH + inset
		control.offset_right = -inset
	else:
		control.anchor_left = 0.0
		control.anchor_right = 0.0
		control.offset_left = inset
		control.offset_right = SIDE_PANEL_WIDTH - inset


## Poziomy pasek u dołu ekranu, przyklejony do rogu (domyślnie prawego, tak
## jak w oryginale i w Hub.gd) — dla ekranów typu TravelMap, gdzie pinezki
## rozrzucone są po całej mapie i pełnowysokościowy boczny pasek
## (make_root_side) zasłaniał część z nich. Róg zamiast wyśrodkowania: żadna
## pinezka w Cities.MAP_POSITION nie wypada dalej niż x≈0.67, więc pasek
## przy prawej krawędzi ich nie zasłania (wyśrodkowany zasłaniałby środek
## mapy, gdzie akurat kilka miast wypada). Wysokość dopasowuje się
## automatycznie do treści: content to PanelContainer, który (inaczej niż
## zwykły Control) liczy swój rozmiar jako maksimum rozmiarów dzieci — więc
## tło/ramka (dodane jako pierwsze dziecko) i lista przycisków (drugie, we
## własnym MarginContainer dla odstępu od krawędzi ramki) automatycznie
## dostają tę samą, właściwą wysokość, bez ręcznego liczenia jak w
## _anchor_side_strip.
static func make_root_bottom(parent: Control, use_menu_frame: bool = false, width: float = 420.0, on_right: bool = true) -> VBoxContainer:
	var wrapper := VBoxContainer.new()
	wrapper.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(wrapper)

	var top_spacer := Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(top_spacer)

	var content := PanelContainer.new()
	content.size_flags_horizontal = Control.SIZE_SHRINK_END if on_right else Control.SIZE_SHRINK_BEGIN
	content.custom_minimum_size = Vector2(width, 0)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	wrapper.add_child(content)

	if use_menu_frame:
		var frame: Control = MenuFrameScript.new()
		content.add_child(frame)
	else:
		var panel_bg := ColorRect.new()
		panel_bg.color = Color(COLOR_BURGUNDY_DARK.r, COLOR_BURGUNDY_DARK.g, COLOR_BURGUNDY_DARK.b, 0.8)
		panel_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(panel_bg)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if use_menu_frame:
		var m := int(CONTENT_INSET_WITH_FRAME)
		margin.add_theme_constant_override("margin_left", m)
		margin.add_theme_constant_override("margin_right", m)
		margin.add_theme_constant_override("margin_top", m)
		margin.add_theme_constant_override("margin_bottom", m)
	content.add_child(margin)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 14)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(root)
	return root


## Ta sama skrzynka Art Deco co make_root_bottom (ramka + margines + stała
## szerokość), ale WEWNĄTRZ istniejącego układu (dokładana zwykłym
## `parent.add_child`), NIE zakotwiczona niezależnie od reszty ekranu —
## zgłoszone przez użytkownika: MainMenu.gd ma wyglądać tak samo (ta sama
## szerokość/ramka co skrzynka powrotu na innych ekranach), ale jego treść
## (logo + podtytuł + ta skrzynka) jest naturalnie wyśrodkowana pionowo jako
## JEDNA całość przez ALIGNMENT_CENTER nadrzędnego roota — inaczej niż
## make_root_bottom, które zawsze zakotwicza się osobno w rogu/na dole
## ekranu, niezależnie od reszty treści.
##
## Zwraca Dictionary {"box", "content"} (ten sam patent co
## make_corner_status_row) zamiast samego VBoxContainera: "content" to
## miejsce, gdzie wołający dokłada/czyści swoje przyciski, ale gdy trzeba
## SCHOWAĆ całą skrzynkę (np. MainMenu.gd przełączające setup_section /
## name_section), trzeba ukryć "box" (zewnętrzny PanelContainer z ramką),
## NIE samo "content" — inaczej sama ozdobna ramka (MenuFrame._draw(),
## rysowana niezależnie od widoczności dzieci) zostałaby wiszącym, pustym
## prostokątem na ekranie.
static func make_boxed_panel(parent: Container, width: float = 420.0) -> Dictionary:
	var content := PanelContainer.new()
	content.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.custom_minimum_size = Vector2(width, 0)

	var frame: Control = MenuFrameScript.new()
	content.add_child(frame)

	var margin := MarginContainer.new()
	var m := int(CONTENT_INSET_WITH_FRAME)
	margin.add_theme_constant_override("margin_left", m)
	margin.add_theme_constant_override("margin_right", m)
	margin.add_theme_constant_override("margin_top", m)
	margin.add_theme_constant_override("margin_bottom", m)
	content.add_child(margin)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	parent.add_child(content)
	return {"box": content, "content": root}


## Paleta art déco (docs/GRAFIKA_LEONARDO.md — złoto/burgund/sepia).
const COLOR_GOLD := Color(0.85, 0.65, 0.2)
const COLOR_GOLD_BRIGHT := Color(1.0, 0.83, 0.4)
const COLOR_CREAM := Color(0.95, 0.88, 0.72)
const COLOR_BURGUNDY_DARK := Color(0.13, 0.04, 0.06)

## Zgłoszone przez użytkownika: w Plantacjach fonty zostały powiększone do
## 22px (patrz dawne Plantation.gd BODY_FONT_SIZE) — ten sam rozmiar ma być
## teraz WSZĘDZIE w grze, żadne pole tekstowe nie powinno być mniejsze.
## Jedno wspólne źródło prawdy zamiast rozrzuconych osobnych stałych po
## poszczególnych ekranach.
const BODY_FONT_SIZE := 22


static func make_title(root: VBoxContainer, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 38)
	label.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(label)
	return label


## root: Container (nie tylko VBoxContainer) — pozwala budować etykietę
## bezpośrednio w HBoxContainerze (np. wiersz ikona+tekst eksperckości w
## ArtSchool.gd), oba dziedziczą po Container/BoxContainer.
static func make_label(root: Container, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	## BODY_FONT_SIZE (22, dawniej 19) — zgłoszone przez użytkownika: fonty w
	## Plantacjach zostały powiększone do 22px, ten sam rozmiar ma być
	## wszędzie w grze, żadne pole tekstowe nie powinno być mniejsze.
	label.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	label.add_theme_color_override("font_color", COLOR_CREAM)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	root.add_child(label)
	return label


const StatIconScript := preload("res://scripts/ui/StatIcon.gd")
const STAT_ICON_SEPARATION := 6.0

## Etykieta w osobnej oprawionej "skrzynce" (złota ramka + ciemne tło) —
## tak jak w oryginale pasek stanu to kilka osobnych skrzynek (imię gracza +
## lokalizacja, gotówka, data), nie jeden zbity ciąg tekstu. Używać dla
## pojedynczych, krótkich informacji statusu (patrz Hub.gd).
## min_width/font_size opcjonalne (0 = nie nadpisuj). min_width > 0 to
## NAPRAWDĘ stała szerokość (nie tylko minimum) — bez tego PanelContainer i
## tak rośnie ponad min_width, gdy treść etykiety (bez zawijania) tego
## wymaga, więc np. skrzynka terminu aukcji miała różną szerokość zależnie
## od długości nazwy miasta (Amsterdam vs Berlin — zgłoszone przez
## użytkownika, kilka takich skrzynek w rzędzie MUSI mieć zawsze tę samą
## szerokość). Ustawiamy custom_minimum_size.x na SAMEJ etykiecie (nie tylko
## na panelu) + autowrap, więc dłuższy tekst zawija się na kolejny wiersz
## zamiast rozpychać skrzynkę.
## icon_kind opcjonalny (StatIcon.Kind, domyślnie -1 = brak ikony) — dokleja
## StatIcon.gd po lewej stronie tekstu wewnątrz tej samej skrzynki, patrz
## docs/GRAFIKA_LEONARDO.md wiersz 7b (ikony statystyk zamiast grafiki z
## Leonardo, ten sam powód co MapPin.gd/VaultIcon.gd).
static func make_info_box(root: Container, text: String, min_width: float = 0.0, font_size: int = 0, icon_kind: int = -1) -> Label:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(COLOR_BURGUNDY_DARK.r, COLOR_BURGUNDY_DARK.g, COLOR_BURGUNDY_DARK.b, 0.85)
	box.border_color = COLOR_GOLD
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 6
	box.content_margin_bottom = 6

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box)
	if min_width > 0.0:
		panel.custom_minimum_size = Vector2(min_width, 0)
	root.add_child(panel)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", COLOR_CREAM)
	## BODY_FONT_SIZE domyślnie (patrz make_label) — żadna skrzynka nie
	## powinna zostać na mniejszym rozmiarze.
	label.add_theme_font_size_override("font_size", font_size if font_size > 0 else BODY_FONT_SIZE)
	if min_width > 0.0:
		var reserved_for_icon := (StatIconScript.ICON_SIZE.x + STAT_ICON_SEPARATION) if icon_kind >= 0 else 0.0
		label.custom_minimum_size = Vector2(min_width - box.content_margin_left - box.content_margin_right - reserved_for_icon, 0)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD

	if icon_kind >= 0:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", STAT_ICON_SEPARATION)
		panel.add_child(row)
		row.add_child(StatIconScript.new(icon_kind))
		row.add_child(label)
	else:
		panel.add_child(label)
	return label


## Dwie skrzynki w przeciwległych górnych rogach (lewy: krótszy tekst typu
## lokalizacja/data, prawy: gotówka) — ten sam układ co Hub.gd _build_top_row,
## współdzielony tu, bo tego samego rozkładu (patrz zrzuty ekranu oryginału
## dostarczone przez użytkownika) potrzebują też inne ekrany (np.
## StockMarket.gd). SIZE_SHRINK_BEGIN na kolumnach + spacer z
## SIZE_EXPAND_FILL — te same triki co w Hub.gd, patrz komentarz tam.
static func make_corner_status_row(parent: Control, left_text: String, right_text: String) -> Dictionary:
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	## Margines od krawędzi ekranu — patrz ten sam fix w Hub.gd _build_top_row
	## (bez niego skrzynka w prawym rogu ucinała się na telefonach z
	## zaokrąglonymi rogami/notchem).
	row.offset_left = 16
	row.offset_right = -16
	row.offset_top = 12
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)

	var left_column := VBoxContainer.new()
	left_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(left_column)
	## left_text to zawsze "Miasto\nData" (patrz wywołania w Warehouse.gd/
	## ArtSchool.gd/Races.gd/StockMarket.gd/Market.gd/SecurityScreen.gd) —
	## ikona kalendarza pasuje, mimo że pierwsza linia to lokalizacja.
	var left_label := make_info_box(left_column, left_text, 0.0, 0, StatIconScript.Kind.DATE)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)

	var right_column := VBoxContainer.new()
	right_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(right_column)
	var right_label := make_info_box(right_column, right_text, 0.0, 0, StatIconScript.Kind.MONEY)

	return {"left": left_label, "right": right_label}


## Jak make_info_box, ale dla całego WIERSZA (kilka dzieci obok siebie —
## etykieta + przyciski), nie pojedynczej etykiety — potrzebne tam, gdzie
## cała pozycja (np. spółka żeglugowa: nazwa, cena, przyciski kup/sprzedaj)
## ma być w jednej oprawionej "skrzynce", tak jak w oryginale (patrz
## StockMarket.gd).
static func make_boxed_row(root: Container) -> HBoxContainer:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(COLOR_BURGUNDY_DARK.r, COLOR_BURGUNDY_DARK.g, COLOR_BURGUNDY_DARK.b, 0.85)
	box.border_color = COLOR_GOLD
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 6
	box.content_margin_bottom = 6

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box)
	root.add_child(panel)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	return row


## Jak make_boxed_row, ale PIONOWA skrzynka (VBoxContainer) — dla treści,
## która ma być listą wierszy w jednej ramce (np. ramka gracza na aukcji:
## awatar, imię, gotówka, status, przyciski — patrz AuctionHouse.gd).
static func make_boxed_column(root: Container) -> VBoxContainer:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(COLOR_BURGUNDY_DARK.r, COLOR_BURGUNDY_DARK.g, COLOR_BURGUNDY_DARK.b, 0.85)
	box.border_color = COLOR_GOLD
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 10
	box.content_margin_bottom = 10

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box)
	root.add_child(panel)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	return column


## Przyciski w stylu art déco (ciemny burgund + złota ramka) zamiast
## domyślnego szarego wyglądu Godota — jeden wspólny styl dla całej gry.
static func _style_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(COLOR_BURGUNDY_DARK.r, COLOR_BURGUNDY_DARK.g, COLOR_BURGUNDY_DARK.b, 0.88)
	normal.border_color = COLOR_GOLD
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 20
	normal.content_margin_right = 20
	normal.content_margin_top = 14
	normal.content_margin_bottom = 14

	var hover := normal.duplicate()
	hover.bg_color = Color(0.28, 0.09, 0.13, 0.92)
	hover.border_color = COLOR_GOLD_BRIGHT

	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.06, 0.02, 0.03, 0.95)
	pressed.border_color = COLOR_GOLD_BRIGHT

	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.2, 0.2, 0.2, 0.55)
	disabled.border_color = Color(0.45, 0.45, 0.45)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", COLOR_CREAM)
	btn.add_theme_color_override("font_hover_color", COLOR_GOLD_BRIGHT)
	btn.add_theme_color_override("font_pressed_color", COLOR_GOLD_BRIGHT)
	btn.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.6))
	btn.add_theme_font_size_override("font_size", BODY_FONT_SIZE)


## Rozmiar/czcionka podniesione z (280, 46)/18px — tester zgłosił, że
## przyciski były za małe, mimo że na większości ekranów było sporo wolnego
## miejsca dookoła nich. width opcjonalna (domyślnie 320, jak wszędzie) —
## potrzebna tam, gdzie guzik siedzi w węższej niż zwykle kolumnie (patrz
## Plantation.gd, kolumny obok kwadratowej siatki) i musi się realnie
## zmieścić, zamiast rozpychać kolumnę ponad wyliczoną szerokość.
static func make_button(root: Container, text: String, on_pressed: Callable, width: float = 320.0) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(width, 58)
	btn.pressed.connect(on_pressed)
	_style_button(btn)
	root.add_child(btn)
	return btn


static func make_back_button(root: Container) -> Button:
	return make_button(root, "« Powrót", func(): SceneRouter.goto_hub())


## Przycisk powrotu w TYM SAMYM stylu co boczny panel na TravelMap.gd/Hub.gd
## (make_root_bottom: ozdobna ramka Art Deco, bez żadnego tytułu/opisu) —
## zgłoszone przez użytkownika po wprowadzeniu tego stylu w AuctionHouse.gd:
## "to teraz powrót ma tak samo wyglądać w galerii, w szkole sztuki, giełda,
## rynek i wszystkie inne oprócz plantacji" (tam zostaje węższy przycisk
## dopasowany do kolumny legendy, patrz Plantation.gd). `parent` to CAŁY
## ekran (zwykle `self`), NIE `root` danego ekranu — skrzynka jest
## zakotwiczona NIEZALEŻNIE od głównej kolumny treści, więc nie trzeba już
## rozpychacza wypychającego przycisk na sam dół (pozycja jest stała).
static func make_boxed_back_button(parent: Control) -> Button:
	return make_back_button(make_root_bottom(parent, true))


## W hot-seat multiplayer pokazuje, czyja jest tura — ważne, żeby osoba
## trzymająca telefon wiedziała, w czyim imieniu działa. W solo nic nie
## dodaje (zwraca null).
static func make_turn_indicator(root: VBoxContainer) -> Label:
	if not Players.is_multiplayer():
		return null
	return make_label(root, TranslationServer.translate("Tura: %s") % Players.active_name())


## Rozpychacz SIZE_EXPAND_FILL do przypinania stałej zawartości do krawędzi
## ekranu wewnątrz VBoxContainera z ALIGNMENT_BEGIN — wstawiany PRZED i PO
## zmiennej zawartości środkowej (np. tytuł ekranu / nazwa miejsca -> ten
## rozpychacz -> zmienna treść -> drugi taki sam rozpychacz -> przycisk
## powrotu). Oba rozpychacze dostają RÓWNY udział w zostającej przestrzeni,
## więc środek zostaje wyśrodkowany, a skrajne elementy przyklejone do
## górnej/dolnej krawędzi niezależnie od tego, ile jest treści pomiędzy.
## Wyodrębnione tu (wcześniej osobne kopie w AuctionHouse.gd/Gallery.gd/
## Plantation.gd) po tym, jak ten sam wzorzec zaczął być potrzebny na
## wszystkich ekranach bez ozdobnej ramki (zgłoszone przez użytkownika:
## "wszystkie miejsca powinny mieć usunięta ta ramka i zrobione że nazwa
## miejsca na samej górze a powrót na samym dole tak jak to zrobiliśmy w
## galerii w konkretnej kategorii").
static func make_expand_spacer() -> Control:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


## Oprawiona "skrzynka" (złota ramka + ciemne tło) na dowolną zawartość —
## ten sam wzorzec co grid_frame w Plantation.gd i silo frame w
## Warehouse.gd, tu wydzielony jako współdzielony helper na potrzeby ramki
## pod wykresem cen + legendą w Market.gd/StockMarket.gd (zgłoszone przez
## użytkownika: "w rynku i giełdzie pod samym wykresem z legendą powinna
## być ramka"). Zwraca WEWNĘTRZNY VBoxContainer — wołający dokłada do
## niego dzieci (wykres, legendę), nie do zwróconego PanelContainera.
static func make_framed_box(root: Container) -> VBoxContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.6)
	style.border_color = COLOR_GOLD
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(panel)

	var inner := VBoxContainer.new()
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 8)
	panel.add_child(inner)
	return inner
