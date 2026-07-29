extends Control
## Dom aukcyjny — działająca licytacja przeciw AI (w tym Vico).
## Patrz GDD.md pkt. 4.5, docs/MECHANIKI_EKONOMICZNE.md pkt. 9.
##
## Aukcje trzyma harmonogram w Auctions.gd (jedno miasto + jeden dzień na
## raz, tak jak w oryginale — patrz zrzut ekranu użytkownika z boksem
## "NEXT AUCTION IS: 17.1.1918 BERLIN"). Ten ekran już NIE pozwala klikać
## "Nowa aukcja" bez ograniczeń (użytkownik: "aucje powinny być dostępne
## tylko w wybranym czasie, nie żeby mogę ileś obrazów na raz kupić") —
## jeśli gracz jest w mieście aukcyjnym poza terminem, widzi tylko
## informację, kiedy i gdzie jest następna aukcja.
##
## Zgłoszone przez użytkownika: skoro kilku graczy może niezależnym tempem
## dotrzeć do TEJ SAMEJ aukcji (patrz GDD.md pkt. 11, Auctions.get_present_players),
## ekran pokazuje osobną ramkę dla KAŻDEGO fizycznie obecnego gracza (do 4,
## 2 po lewej i 2 po prawej) — z własnym przyciskiem podbicia i rezygnacji.
## Czas na reakcję jest jeden, wspólny dla wszystkich (jeden zegar odliczania
## na całą rundę), tak jak w oryginale ("gracze siedzący przed jednym
## komputerem C64 po kolei wpisują swoje oferty").

const BID_INCREMENT_RATIO := 0.1  ## gracz podbija o 10% szacunkowej wartości
const BID_TIME_LIMIT := 20.0  ## sekundy realnego czasu na podbicie oferty
const StatIconScript := preload("res://scripts/ui/StatIcon.gd")

var current_number: int = -1
var current_bid: float = 0.0
## "" = nikt, "player:<idx>" = gracz o indeksie <idx> (może być KAŻDY
## fizycznie obecny gracz, nie tylko aktywny), albo id rywala.
var current_leader: String = ""

## Indeksy graczy fizycznie obecnych na TEJ aukcji (Auctions.get_present_players)
## — liczone RAZ przy wejściu na ekran, bo obecność (miasto + własny dzień)
## nie zmienia się w trakcie samej licytacji.
var present_players: Array[int] = []
## index -> bool, czy DANY gracz zrezygnował z TEJ rundy — reset co nowy
## obraz w _start_new_auction. Rezygnacja jest per gracz: pozostali obecni
## mogą dalej licytować, dopóki nie zrezygnują wszyscy (wtedy runda
## rozstrzyga się od razu, tak jak dawniej przy jednym graczu).
var withdrawn_players: Dictionary = {}
## index -> bool, czy DANY numer jest dla NIEGO duplikatem — losowane raz na
## aukcję w _start_new_auction (każdy obecny gracz ma OSOBNĄ kolekcję).
var player_forgery_duplicate: Dictionary = {}
## index -> bool, czy Szkoła Sztuki zdążyła OSTRZEC akurat TEGO gracza —
## zależy od jego własnej eksperckości (Players.get_player_expertise).
var player_forgery_warning: Dictionary = {}
## index -> {"money_label", "status_label", "bid_btn", "resign_btn"} — węzły
## ramki KAŻDEGO obecnego gracza, budowane raz w _build_player_frame,
## odświeżane w _update_frame.
var player_frames: Dictionary = {}

var auction_active: bool = false  ## true = odlicza czas na kolejny ruch
var bid_time_remaining: float = 0.0
## Rywal nie czeka już zawsze do samego końca licznika, żeby ewentualnie
## podbić — losowy moment w trakcie odliczania, w którym sprawdzamy, czy
## któryś rywal podbija (patrz _start_bid_timer/_process).
var rival_check_threshold: float = 0.0
var rival_checked_this_round: bool = false

var schedule_label: Label
var painting_label: Label
var bid_label: Label
var timer_label: Label
var timer_bar: ProgressBar
var painting_texture_rect: TextureRect
var leader_portrait_rect: TextureRect
var back_btn: Button
## Obie boczne kolumny ramek graczy (patrz _build_player_frames) — schowane
## CAŁKOWICIE po rozstrzygnięciu rundy (patrz _resolve_auction), zgłoszone
## przez użytkownika: po zakończeniu aukcji ramki graczy powinny zniknąć,
## zostawiając tylko przycisk powrotu.
var left_frames_column: VBoxContainer
var right_frames_column: VBoxContainer

## 268 = 190 (poprzedni rozmiar samego obrazu, patrz historia komentarza w
## _build_active_auction_ui) powiększone tak, żeby po doliczeniu ramki
## (art/icons/frame.png) WNĘTRZE ramki znów wychodziło na ~190×190.
const FRAME_HOLDER_SIZE := Vector2(268, 268)
const FRAME_TEXTURE_PATH := "res://art/icons/frame.png"
## Ułamek FRAME_HOLDER_SIZE zajęty przez sam brzeg ramy z każdej strony —
## zmierzone na art/icons/frame.png (kwadratowy plik, kwadratowy otwór w
## środku, przezroczyste tło dookoła ramy — patrz poprawiony prompt w
## docs/GRAFIKA_LEONARDO.md §6).
const FRAME_INNER_INSET := 0.145

## Szerokość ramek graczy po bokach ekranu (patrz _make_side_column/
## _build_player_frames). Środkowa treść (obraz + opis) zwężona odpowiednio
## (patrz painting_label/bid_label niżej), żeby zmieściła się między dwiema
## takimi kolumnami.
##
## 200 (nie 130) — musi zostawić miejsce na tytuł + wskaźnik tury + skrzynkę
## terminu aukcji, które leżą NAD bocznymi kolumnami (te trzy zajmują razem
## ok. 180px wysokości) — za mała wartość powodowała, że górna krawędź
## pierwszej ramki gracza zachodziła na skrzynkę terminu (zgłoszone przez
## użytkownika, zrzut ekranu).
const SIDE_FRAMES_TOP_OFFSET := 200.0


func _ready() -> void:
	ScreenHelpers.make_background(self, "res://art/backgrounds/auction_house.jpg")

	## use_menu_frame=false: użytkownik zgłosił, że ozdobna ramka na cały
	## ekran (ta sama co w Hub/TravelMap) tu tylko przeszkadzała.
	var root := ScreenHelpers.make_root(self, false)
	ScreenHelpers.make_title(root, "Dom aukcyjny")

	## "Tura: Gracz X" i termin aukcji (miasto + data) w lewym górnym rogu
	## (patrz _build_top_left_corner), NIE w głównej, wyśrodkowanej kolumnie
	## — zgłoszone przez użytkownika: ta kolumna jest już wysoka (obraz +
	## pasek czasu + skrzynka oferty), a każdy dodatkowy wiersz na górze
	## spychał skrzynkę oferty na dole poza widoczny ekran. Róg ma zapas
	## miejsca i niczego innego nie przesuwa.
	_build_top_left_corner()

	if not Auctions.is_open(Travel.current_city):
		## ALIGNMENT_BEGIN: zgłoszone przez użytkownika ("jeszcze tak nie ma
		## dom aukcyjny jak nie ma aukcji") — ten wczesny return (brak aukcji
		## akurat teraz) nigdy nie dochodzi do _build_active_auction_ui, gdzie
		## root.alignment jest normalnie ustawiane na BEGIN, więc zostawał na
		## domyślnym CENTER.
		root.alignment = BoxContainer.ALIGNMENT_BEGIN
		ScreenHelpers.make_label(root, tr("W tym mieście nie odbywa się teraz żadna aukcja.\nWróć w podanym terminie."))
		schedule_label.text = Auctions.get_schedule_string()
		_build_bottom_menu_box(false)
		return

	present_players = Auctions.get_present_players()
	_build_active_auction_ui(root)
	_build_player_frames()
	_start_new_auction()


## Mała skrzynka w lewym górnym rogu ekranu — "Tura: Gracz X" (jak wszędzie
## indziej, ScreenHelpers.make_turn_indicator, puste w trybie solo) i termin
## aukcji (schedule_label). Pozycjonowana bezpośrednio (position), nie przez
## Container-owy layout — te same wartości offsetu co make_corner_status_row
## (16, 12) dla spójności z resztą gry.
func _build_top_left_corner() -> void:
	var corner := VBoxContainer.new()
	corner.position = Vector2(16, 12)
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner.add_theme_constant_override("separation", 6)
	add_child(corner)

	ScreenHelpers.make_turn_indicator(corner)
	schedule_label = ScreenHelpers.make_info_box(corner, "", 0.0, 0, StatIconScript.Kind.DATE)


## Skrzynka z przyciskiem(-ami) powrotu, w TYM SAMYM stylu co boczny panel
## na TravelMap.gd/Hub.gd (ScreenHelpers.make_root_bottom, ozdobna ramka Art
## Deco, bez żadnego tytułu/opisu — zgłoszone przez użytkownika: "jak tu, bez
## tekstu u góry, żeby to było jakby menu", z odniesieniem do zrzutu ekranu
## TravelMap). Budowana DOPIERO gdy naprawdę ma się pokazać (wywołania: raz w
## _ready() dla "brak aukcji dziś", raz w _resolve_auction() po rozstrzygnięciu)
## — NIE budowana z góry z ukrytymi przyciskami jak poprzednia wersja, bo
## make_root_bottom zawsze rysuje samą ramkę (MenuFrame._draw(), niezależnie
## od widoczności przycisków w środku), co podczas trwającej licytacji
## wisiałoby jako pusta złota skrzynka w prawym dolnym rogu, akurat tam gdzie
## w tym momencie są jeszcze widoczne ramki graczy (right_frames_column).
##
## show_gallery_button: zgłoszone przez użytkownika — po WYGRANEJ aukcji
## (obraz trafia do kolekcji, nie fałszywka/nie rywal AI/nie brak ofert)
## dodatkowo pokazuje przycisk "Galeria »", żeby od razu zobaczyć nowy obraz.
func _build_bottom_menu_box(show_gallery_button: bool) -> void:
	var box := ScreenHelpers.make_root_bottom(self, true)
	if show_gallery_button:
		ScreenHelpers.make_button(box, tr("Galeria »"), func(): SceneRouter.goto_scene(SceneRouter.GALLERY))
	back_btn = ScreenHelpers.make_back_button(box)


## Buduje UI aktywnej licytacji BEZ ramek graczy (patrz _build_player_frames
## niżej, budowane osobno na bokach ekranu). Pasek czasu, nazwa/opis obrazu,
## skrzynka "kto prowadzi" i przycisk powrotu zostają jako wspólne,
## WYŚRODKOWANE podsumowanie na środku ekranu (między bocznymi kolumnami
## ramek graczy — SIZE_SHRINK_CENTER na panelach, patrz komentarze niżej,
## inaczej rozciągają się na pełną szerokość i chowają się pod bocznymi
## ramkami) — po bokach dochodzą osobne ramki per gracz z ich WŁASNYMI
## przyciskami podbicia/rezygnacji (patrz _build_player_frame).
func _build_active_auction_ui(root: VBoxContainer) -> void:
	root.alignment = BoxContainer.ALIGNMENT_BEGIN

	## Pasek czasu budowany TU, zaraz przy tytule/terminie — nie na dole
	## ekranu (gdzie był wcześniej): suma elementów w dolnej części (obraz +
	## skrzynka oferty + status) już sama w sobie przekracza wysokość ekranu
	## na wariancie BEZ ScrollContainera (make_root(self, false) go nie ma, w
	## odróżnieniu od wariantu z ozdobną ramką), więc pasek czasu i tak
	## renderował się poza widocznym obszarem (zgłoszone przez użytkownika:
	## "nigdzie nie widać czasu"). Góra ekranu zawsze ma zapas miejsca (patrz
	## zrzuty ekranu), więc jest tu bezpiecznie. Budowane dopiero tutaj (nie
	## w _ready) — na ekranie "brak aukcji teraz" (wczesny return w _ready)
	## w ogóle nie ma czasu do odliczania, więc pasek by tam nie miał sensu.
	timer_label = ScreenHelpers.make_label(root, "")
	timer_label.add_theme_color_override("font_color", ScreenHelpers.COLOR_GOLD_BRIGHT)

	timer_bar = ProgressBar.new()
	timer_bar.custom_minimum_size = Vector2(220, 20)
	timer_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	timer_bar.show_percentage = false
	timer_bar.min_value = 0.0
	timer_bar.max_value = BID_TIME_LIMIT
	timer_bar.step = 0.01
	var timer_bar_bg := StyleBoxFlat.new()
	timer_bar_bg.bg_color = Color(ScreenHelpers.COLOR_BURGUNDY_DARK.r, ScreenHelpers.COLOR_BURGUNDY_DARK.g, ScreenHelpers.COLOR_BURGUNDY_DARK.b, 0.9)
	timer_bar_bg.border_color = ScreenHelpers.COLOR_GOLD
	timer_bar_bg.set_border_width_all(2)
	timer_bar_bg.set_corner_radius_all(4)
	var timer_bar_fill := StyleBoxFlat.new()
	timer_bar_fill.bg_color = ScreenHelpers.COLOR_GOLD_BRIGHT
	timer_bar_fill.set_corner_radius_all(4)
	timer_bar.add_theme_stylebox_override("background", timer_bar_bg)
	timer_bar.add_theme_stylebox_override("fill", timer_bar_fill)
	root.add_child(timer_bar)

	painting_label = ScreenHelpers.make_info_box(root, "")
	painting_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	## 1000 (nie 500 jak wcześniej) — zgłoszone przez użytkownika: ta
	## skrzynka może być prawie na całą szerokość ekranu. Bezpieczne mimo
	## bocznych kolumn ramek graczy (SIDE_PANEL_WIDTH=380 każda), bo te
	## zaczynają się dopiero od SIDE_FRAMES_TOP_OFFSET=200px od góry, a ta
	## skrzynka siedzi wyżej — szerszy limit oznacza MNIEJ zawijanych linii
	## (zwykle 1 zamiast 3), co dodatkowo zostawia więcej zapasu w tym
	## górnym pasie i przesuwa obraz niżej w kodzie = wyżej na ekranie.
	## SIZE_SHRINK_CENTER na PANELU (nie tylko custom_minimum_size na
	## etykiecie) — bez tego panel i tak rozciąga się na pełną szerokość
	## VBoxContainera (ten sam fix co przy schedule_label wyżej).
	painting_label.custom_minimum_size = Vector2(1000, 0)
	painting_label.get_parent().size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	## BEZ rozpychacza tutaj (był wcześniej) — zgłoszone przez użytkownika:
	## obraz powinien być wyżej. Obraz teraz leci od razu pod skrzynką opisu,
	## z samym naturalnym odstępem VBoxContainera (separation=16, patrz
	## ScreenHelpers.make_root).
	var painting_center := CenterContainer.new()
	root.add_child(painting_center)

	var frame_holder := Control.new()
	frame_holder.custom_minimum_size = FRAME_HOLDER_SIZE
	frame_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painting_center.add_child(frame_holder)

	## Rama dodana PIERWSZA (rysuje się pod spodem) — jej wnętrze na
	## frame.png jest w całości nieprzezroczyste, więc dopiero obraz DODANY
	## PO NIEJ (rysuje się na wierzchu) w pełni je zasłania.
	var frame_rect := TextureRect.new()
	frame_rect.texture = load(FRAME_TEXTURE_PATH)
	frame_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame_rect.stretch_mode = TextureRect.STRETCH_SCALE
	frame_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_holder.add_child(frame_rect)

	painting_texture_rect = TextureRect.new()
	painting_texture_rect.anchor_left = FRAME_INNER_INSET
	painting_texture_rect.anchor_top = FRAME_INNER_INSET
	painting_texture_rect.anchor_right = 1.0 - FRAME_INNER_INSET
	painting_texture_rect.anchor_bottom = 1.0 - FRAME_INNER_INSET
	painting_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	painting_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	painting_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_holder.add_child(painting_texture_rect)

	root.add_child(ScreenHelpers.make_expand_spacer())

	## Jedna wspólna, oprawiona skrzynka na portret PROWADZĄCEGO (może być
	## KTÓRYKOLWIEK z obecnych graczy, nie tylko "Ty") + tekst oferty.
	var bid_row := ScreenHelpers.make_boxed_row(root)
	bid_row.get_parent().size_flags_horizontal = Control.SIZE_SHRINK_CENTER  ## patrz schedule_label wyżej

	leader_portrait_rect = TextureRect.new()
	leader_portrait_rect.custom_minimum_size = Vector2(84, 84)
	leader_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	leader_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	## visible ZAWSZE true — tylko modulate.a przełącza widoczność OBRAZKA,
	## żeby bid_row miał zawsze tę samą szerokość niezależnie od tego, kto
	## akurat prowadzi.
	leader_portrait_rect.modulate.a = 0.0
	bid_row.add_child(leader_portrait_rect)

	bid_label = Label.new()
	bid_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bid_label.add_theme_color_override("font_color", ScreenHelpers.COLOR_CREAM)
	bid_label.add_theme_font_size_override("font_size", 26)
	## Zgłoszone przez użytkownika: ta skrzynka poszerzała się i zwężała
	## zależnie od długości nazwy aktualnego lidera — "(prowadzi: %s)" może
	## wstawić nazwę rywala AI (GENERIC_RIVAL_POOL w AIPlayers.gd, do 30
	## znaków, np. "Baron Heinrich von Falkenstein" — stałe nazwy, nie da
	## się ich skrócić jak nazwy gracza w MainMenu.gd). Poprzednia próba
	## (AUTOWRAP_ARBITRARY) trzymała szerokość, ale łamała długie nazwy w
	## środku słowa ("Falke"/"nstein") — brzydko.
	##
	## Trochę szersza (520, nie 500) — NIE dużo więcej, bo ta skrzynka
	## siedzi MIĘDZY dwiema bocznymi kolumnami ramek graczy (SIDE_PANEL_WIDTH
	## =380 każda), więc bezpieczny środkowy pas to tylko ok. 520px; szerzej
	## i skrzynka zaczęłaby wchodzić POD boczne ramki (dodane później w
	## drzewie, więc rysują się na wierzchu — inaczej niż painting_label
	## wyżej, która jest bezpieczna do pełnej szerokości WŁAŚNIE dlatego, że
	## siedzi WYŻEJ niż SIDE_FRAMES_TOP_OFFSET). Zamiast gonić szerokość, by
	## najdłuższa nazwa zmieściła się w jednej linii (fizycznie niemożliwe w
	## tym pasie), AUTOWRAP_WORD (łamie tylko na spacjach) + custom_minimum_size.y
	## na STAŁE 3 linie ("Oferta: X" + do 2 linii "(prowadzi: ...)") —
	## skrzynka ma więc zawsze TĘ SAMĄ wysokość, niezależnie czy tekst
	## faktycznie potrzebuje 2 czy 3 linii.
	bid_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	bid_label.custom_minimum_size = Vector2(520, 115)
	bid_row.add_child(bid_label)

	## Skrzynka z przyciskiem powrotu (i ewentualnie "Galeria »") budowana
	## DOPIERO w _resolve_auction() — patrz komentarz przy
	## _build_bottom_menu_box, dlaczego nie tutaj z góry.


## Boczna kolumna ramek graczy — TA SAMA szerokość/pozycja co
## ScreenHelpers.make_root_side, ale BEZ ScrollContainera. make_root_side
## opakowuje swój VBoxContainer w ScrollContainer, a ScrollContainer NIE
## rozciąga dziecka na pełną wysokość w osi przewijania (daje mu tylko jego
## naturalny, minimalny rozmiar) — więc "rozpychający" spacer wewnątrz nie
## miał czego rozpychać i cała kolumna zbijała się na samej górze zamiast
## rozjechać się na górny/dolny slot (zgłoszone przez użytkownika, zrzut
## ekranu: ramka jedynego gracza wylądowała u góry zamiast w prawym dole).
## Tu VBoxContainer jest zakotwiczony BEZPOŚREDNIO (anchor na całą wysokość
## paska, jak plain_root w ScreenHelpers.make_root) — dokładnie ten sam
## mechanizm co ScreenHelpers.make_root_bottom (który z tego samego powodu
## też nie używa ScrollContainera), więc expand-fill spacer faktycznie ma
## się czym rozepchnąć.
func _make_side_column(on_right: bool) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.anchor_top = 0.0
	column.anchor_bottom = 1.0
	column.offset_top = SIDE_FRAMES_TOP_OFFSET
	column.offset_bottom = 0.0
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


## Buduje boczne kolumny ramek graczy, każda podzielona na GÓRNY i DOLNY
## slot rozdzielony rozpychającym spacerem. Kolejność zajmowania miejsc
## (zgłoszone przez użytkownika): 1. gracz -> prawy dół, 2. gracz -> lewy
## dół, 3. gracz -> prawy góra, 4. gracz -> lewy góra. Sloty budowane ZAWSZE
## wszystkie cztery, niezależnie od liczby obecnych graczy — dzięki temu np.
## przy jednym graczu jego ramka zawsze ląduje w prawym dole, a nie na
## środku/górze kolumny.
func _build_player_frames() -> void:
	var left_root := _make_side_column(false)
	var right_root := _make_side_column(true)
	left_frames_column = left_root
	right_frames_column = right_root

	var left_top := VBoxContainer.new()
	left_root.add_child(left_top)
	left_root.add_child(ScreenHelpers.make_expand_spacer())
	var left_bottom := VBoxContainer.new()
	left_root.add_child(left_bottom)

	var right_top := VBoxContainer.new()
	right_root.add_child(right_top)
	right_root.add_child(ScreenHelpers.make_expand_spacer())
	var right_bottom := VBoxContainer.new()
	right_root.add_child(right_bottom)

	var slots: Array[VBoxContainer] = [right_bottom, left_bottom, right_top, left_top]
	for i in present_players.size():
		_build_player_frame(slots[i], present_players[i])


## Jedna ramka gracza: awatar + imię (identyfikacja, zgłoszone przez
## użytkownika: "w ramkach powinna być informacja który to jest gracz"),
## własna gotówka, status (zrezygnował/ostrzeżenie o podróbce — BEZ "kto
## prowadzi", patrz _update_frame) i własne przyciski Podbij/Rezygnuję —
## .bind(index) wiąże każdy przycisk z KONKRETNYM graczem, więc
## _on_bid_pressed/_on_resign_pressed zawsze wiedzą,
## w czyim imieniu działają, niezależnie od tego, kto jest aktualnie
## "aktywnym" graczem hot-seatu (Players.active_index).
##
## Celowo zwarta (zgłoszone przez użytkownika: "dolny kwadrat wychodzi poza"
## — dwie ramki jedna pod drugą w kolumnie nie mieściły się w pionie):
## awatar 48×48 (nie 84), przyciski OBOK SIEBIE w jednym wierszu (nie jeden
## pod drugim), a pusta linia statusu jest CHOWANA (nie tylko pusta), gdy
## akurat nic nie ma do pokazania — patrz _update_frame.
func _build_player_frame(parent: Container, index: int) -> void:
	var column := ScreenHelpers.make_boxed_column(parent)

	var name_suffix := tr(" (aktywny)") if index == Players.active_index else ""
	var name_label := ScreenHelpers.make_label(column, Players.player_names[index] + name_suffix)
	## Zgłoszone przez użytkownika: bardzo długa nazwa gracza rozpychała całą
	## ramkę (boxed_column) szerzej niż SIDE_PANEL_WIDTH, więc widocznie
	## "pływała" w szerokości między rundami zależnie od tego, czyja akurat
	## ramka się przebudowywała. MainMenu.gd teraz ogranicza długość nazwy
	## przy wpisywaniu (MAX_PLAYER_NAME_LENGTH), ale to tu i tak zostaje jako
	## twarde zabezpieczenie na wypadek starszego zapisu gry sprzed tego
	## limitu — AUTOWRAP_ARBITRARY (nie WORD) łamie tekst w DOWOLNYM miejscu,
	## więc nawet jeden długi ciąg znaków bez spacji nigdy nie przekroczy
	## zadanej szerokości (WORD nie potrafiłby go złamać w ogóle).
	name_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	name_label.custom_minimum_size = Vector2(ScreenHelpers.SIDE_PANEL_WIDTH - 24.0, 0)

	var avatar_center := CenterContainer.new()
	column.add_child(avatar_center)
	var avatar_rect := TextureRect.new()
	avatar_rect.custom_minimum_size = Vector2(48, 48)
	avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var avatar_path := Players.get_avatar_path(index)
	if ResourceLoader.exists(avatar_path):
		avatar_rect.texture = load(avatar_path)
	avatar_center.add_child(avatar_rect)

	var money_label := ScreenHelpers.make_label(column, "")
	var status_label_frame := ScreenHelpers.make_label(column, "")
	## Wysokość ZAWSZE stała (nigdy nie chowana/pokazywana) — zgłoszone przez
	## użytkownika: rozmiar ramki nie może się nigdy zmieniać. Rezerwuje
	## miejsce na jedną linijkę niezależnie od tego, czy akurat jest coś do
	## pokazania (patrz _update_frame — tekst może być pusty, ale wysokość
	## etykiety zostaje ta sama).
	status_label_frame.custom_minimum_size = Vector2(0, 24)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 8)
	column.add_child(button_row)
	## Sam tekst skrócony do "Podbij" (bez powtarzania "+10%" w każdej z do
	## 4 ramek) — przy szerokości 150px (nie 320 jak domyślnie) dłuższy
	## napis albo się przycinał, albo wymuszał zawijanie i wyższy przycisk.
	var bid_btn := ScreenHelpers.make_button(button_row, tr("Podbij"), _on_bid_pressed.bind(index), 150.0)
	var resign_btn := ScreenHelpers.make_button(button_row, tr("Rezygnuję"), _on_resign_pressed.bind(index), 150.0)

	player_frames[index] = {
		"money_label": money_label,
		"status_label": status_label_frame,
		"bid_btn": bid_btn,
		"resign_btn": resign_btn,
	}


func _process(delta: float) -> void:
	if not auction_active:
		return
	bid_time_remaining -= delta
	if bid_time_remaining <= 0.0:
		bid_time_remaining = 0.0
		auction_active = false
		timer_label.text = tr("Czas minął!")
		timer_bar.value = 0.0
		_on_time_expired()
		return

	timer_label.text = tr("Czas na podbicie: %d s") % int(ceil(bid_time_remaining))
	timer_bar.value = bid_time_remaining

	if not rival_checked_this_round and bid_time_remaining <= rival_check_threshold:
		rival_checked_this_round = true
		_try_rival_counter_bid()


func _start_bid_timer() -> void:
	bid_time_remaining = BID_TIME_LIMIT
	auction_active = true
	timer_bar.value = BID_TIME_LIMIT
	rival_checked_this_round = false
	rival_check_threshold = randf_range(2.0, BID_TIME_LIMIT - 3.0)


## Zgłoszone przez użytkownika: pod skrzynką oferty (bid_row/bid_label)
## czasem wisiał napis "Zabrakło czasu..." — ustawiany tu, ale NIC go nie
## czyściło, gdy rywal akurat podbijał (_try_rival_counter_bid zwraca true i
## zaczyna NOWĄ, w pełni aktywną rundę z odliczaniem) — napis o zabrakłym
## czasie zostawał więc wyświetlony przez całą kolejną rundę, mimo że czasu
## jawnie nie zabrakło. Kto teraz prowadzi widać już w bid_label
## (_update_labels), więc ten status w ogóle nie jest tu potrzebny.
func _on_time_expired() -> void:
	if _try_rival_counter_bid():
		return
	_resolve_auction()


## Sama logika "czy ktoś z rywali podbija current_bid" — liczy najlepszą
## ofertę i, jeśli jest wyższa, STOSUJE ją (current_bid/current_leader), ale
## NIE decyduje, co dalej — to zależy od wywołującego.
func _apply_best_rival_counter_bid() -> bool:
	var estimated_value := Paintings.get_estimated_value(current_number)
	var best_rival_id := ""
	var best_rival_bid := current_bid
	for rival in AIPlayers.rivals:
		## Rywal, który już prowadzi, nie może "podbić samego siebie" —
		## musi ustąpić miejsca komuś innemu (albo nikomu).
		if rival["id"] == current_leader:
			continue
		var rival_bid: float = AIPlayers.decide_bid(rival["id"], current_bid, estimated_value)
		if rival_bid > best_rival_bid:
			best_rival_bid = rival_bid
			best_rival_id = rival["id"]

	if best_rival_id == "":
		return false

	current_bid = best_rival_bid
	current_leader = best_rival_id
	return true


## Wywoływane z losowego, wcześniejszego momentu w trakcie odliczania
## (_process) i z wygaśnięcia czasu (_on_time_expired) — jeśli rywal
## podbija, runda się NIE kończy, tylko zaczyna nową (wspólny czas wraca do
## BID_TIME_LIMIT dla wszystkich obecnych graczy).
func _try_rival_counter_bid() -> bool:
	if not _apply_best_rival_counter_bid():
		return false
	## _start_bid_timer() PRZED _update_labels() — bez tego auction_active
	## byłoby jeszcze false w momencie liczenia frame["bid_btn"].disabled
	## (patrz _update_frame), więc przyciski zostawałyby zablokowane aż do
	## KOLEJNEGO odświeżenia etykiet (zgłoszone przez użytkownika: "na
	## początku aukcji nie mogłem nic nacisnąć, dopiero jak bot podbił się
	## odblokowały").
	_start_bid_timer()
	_update_labels()
	return true


func _start_new_auction() -> void:
	current_number = Auctions.get_current_painting_number()
	var estimated_value := Paintings.get_estimated_value(current_number)
	current_bid = estimated_value * 0.2
	current_leader = ""
	withdrawn_players.clear()

	## Duplikat/ostrzeżenie o podróbce to teraz stan PER GRACZ (każdy obecny
	## ma własną kolekcję i własną eksperckość) — losowane raz na aukcję,
	## tak jak dawniej current_forgery_warning dla jedynego gracza.
	player_forgery_duplicate.clear()
	player_forgery_warning.clear()
	for index in present_players:
		var is_duplicate := Players.player_has_number(index, current_number)
		player_forgery_duplicate[index] = is_duplicate
		player_forgery_warning[index] = is_duplicate and randf() < Players.get_player_expertise(index)

	## _start_bid_timer() PRZED _update_labels() — patrz ten sam komentarz w
	## _try_rival_counter_bid, dokładnie ten sam błąd na starcie KAŻDEJ
	## aukcji (nie tylko pierwszej): auction_active musi być true ZANIM
	## _update_labels() policzy, czy przyciski mają być zablokowane.
	_start_bid_timer()
	_update_labels()


## Podbicie w imieniu KONKRETNEGO gracza (index, przypięty przez .bind() w
## _build_player_frame) — sprawdzane jest WŁASNE stać go na to (Players.
## player_can_afford), nie stać AKTYWNEGO gracza, bo licytować może każdy
## fizycznie obecny.
func _on_bid_pressed(index: int) -> void:
	var estimated_value := Paintings.get_estimated_value(current_number)
	var next_bid := current_bid + estimated_value * BID_INCREMENT_RATIO
	if not Players.player_can_afford(index, next_bid):
		player_frames[index]["status_label"].text = tr("Za mało gotówki na taką ofertę.")
		return
	current_bid = next_bid
	current_leader = "player:%d" % index
	_update_labels()
	_start_bid_timer()


## Rezygnacja jest PER GRACZ (zgłoszone przez użytkownika): ten konkretny
## gracz nie może już podbijać w tej rundzie, ale pozostali obecni licytują
## dalej. Dopiero gdy WSZYSCY obecni zrezygnują, runda rozstrzyga się od
## razu (ten sam mechanizm co dawniej przy jednym graczu — jeszcze jedno
## sprawdzenie kontrofert rywali, potem wynik).
func _on_resign_pressed(index: int) -> void:
	withdrawn_players[index] = true
	_update_labels()
	if _all_present_withdrawn():
		_apply_best_rival_counter_bid()
		_resolve_auction()


func _all_present_withdrawn() -> bool:
	for index in present_players:
		if not withdrawn_players.get(index, false):
			return false
	return true


func _resolve_auction() -> void:
	auction_active = false
	timer_label.text = ""
	## visible = false (nie tylko value = 0) — pusty pasek czasu nie
	## powinien już wisieć na ekranie po rozstrzygnięciu.
	timer_bar.visible = false

	## Zgłoszone przez użytkownika: po zakończeniu aukcji ramki WSZYSTKICH
	## graczy mają zniknąć, zostawiając tylko przycisk powrotu — dalsze
	## podbijanie/rezygnacja i tak nie mają już sensu (auction_active=false
	## blokuje oba przyciski w każdej ramce, patrz _update_frame), więc same
	## puste, zablokowane skrzynki tylko zaśmiecały ekran.
	left_frames_column.visible = false
	right_frames_column.visible = false

	## Zgłoszone przez użytkownika: pod skrzynką oferty nie może być żaden
	## napis (patrz wcześniejsze usunięcie "Zabrakło czasu..." w
	## _on_time_expired) — wynik rundy i tak widać w bid_label (kto
	## prowadzi/za ile), więc osobne zdanie podsumowujące jest zbędne.
	## won_for_collection: TYLKO gdy obraz naprawdę trafił do kolekcji
	## gracza (nie fałszywka, nie rywal AI, nie brak licytujących) — steruje
	## przyciskiem "Galeria »" w _build_bottom_menu_box niżej.
	## Bonusowy "obraz wuja" (docs/DODATKOWE_MECHANIKI.md) — celowo NIE
	## przechodzi przez Players.catalogue_for_player/AIPlayers.award_painting
	## (nie ma liczyć się do win_threshold ani do widocznego stanu kolekcji,
	## patrz komentarz przy Paintings.BONUS_CATALOG) — tylko globalnie znika
	## z rotacji (Paintings.award_bonus_painting) i (dla ludzkiego gracza)
	## daje jednorazową nagrodę gotówkową.
	var is_bonus := Paintings.is_bonus_painting(current_number)
	var bonus_message := ""

	var won_for_collection := false
	if current_leader.begins_with("player:"):
		var winner_index := int(current_leader.substr(7))
		Players.spend_player_money(winner_index, current_bid)
		if is_bonus:
			Paintings.award_bonus_painting(current_number)
			Players.earn_player_money(winner_index, Paintings.BONUS_REWARD_MONEY)
			bonus_message = tr("Ulubiony obraz wuja! Bonus: %.0f M.") % Paintings.BONUS_REWARD_MONEY
		elif not Players.player_has_number(winner_index, current_number):
			Players.catalogue_for_player(winner_index, current_number)
			won_for_collection = true
	elif current_leader != "":
		if is_bonus:
			Paintings.award_bonus_painting(current_number)
		else:
			AIPlayers.award_painting(current_leader, current_number, current_bid)
	_update_labels()
	## won_for_collection zostaje false przy bonusie — nie trafia do Galerii,
	## więc przycisk "Galeria »" po aukcji byłby mylący. bid_label
	## dopisywany DOPIERO teraz (PO _update_labels), bo ta funkcja i tak
	## nadpisuje bid_label.text od zera.
	if bonus_message != "":
		bid_label.text += "\n" + bonus_message
	_build_bottom_menu_box(won_for_collection)

	Auctions.resolve_and_reschedule()
	schedule_label.text = Auctions.get_schedule_string()

	if GameState.check_game_over():
		SceneRouter.goto_scene(SceneRouter.ENDING)


func _update_labels() -> void:
	## Data pokazuje TERMIN aukcji (Auctions.next_auction_day), nie
	## Players.active_day() jednego konkretnego gracza — przy kilku obecnych
	## graczach na różnych własnych dniach (byle >= termin) sam termin jest
	## jedyną datą wspólną i jednoznaczną dla całej rundy.
	schedule_label.text = tr("Aukcja w toku: %s — %s") % [Cities.get_city_name(Travel.current_city), Calendar.format_day(Auctions.next_auction_day)]

	var category: String = Paintings.get_category(current_number)
	## Bonusowe obrazy wuja nie mają kategorii stylistycznej (CATALOG.get
	## zwraca "" dla ujemnych numerów) — własna, wyróżniająca etykieta
	## zamiast pustych nawiasów w painting_label niżej.
	var category_name: String = tr("Bonus") if Paintings.is_bonus_painting(current_number) else tr(Paintings.CATEGORY_NAMES.get(category, category))
	var info := Paintings.get_painting_info(current_number)
	if not info.is_empty():
		painting_label.text = tr("Na sprzedaż: „%s” — %s, %s (%s) — szac. wartość %.0f M") % [
			tr(info["title"]), info["artist"], info["year"], category_name, Paintings.get_estimated_value(current_number),
		]
	else:
		painting_label.text = tr("Na sprzedaż: obraz nr %d (%s) — szac. wartość %.0f M") % [
			current_number, category_name, Paintings.get_estimated_value(current_number),
		]

	## Wariant graficzny "podróbka" pokazywany, jeśli KTÓRYKOLWIEK z obecnych
	## graczy już ma ten numer skatalogowany — bez jednego "aktywnego gracza"
	## nie ma jednej perspektywy, z której dobieralibyśmy grafikę, więc
	## bierzemy sumę ryzyka wszystkich obecnych (per gracz i tak widać
	## własne ostrzeżenie w jego ramce, patrz _update_frame).
	var any_present_has_duplicate := false
	for index in present_players:
		if player_forgery_duplicate.get(index, false):
			any_present_has_duplicate = true
			break
	var texture_path := Paintings.get_texture_path(current_number, any_present_has_duplicate)
	painting_texture_rect.texture = load(texture_path) if ResourceLoader.exists(texture_path) else null

	var leader_text := tr("nikt")
	leader_portrait_rect.visible = true
	leader_portrait_rect.modulate.a = 0.0
	leader_portrait_rect.texture = null
	if current_leader.begins_with("player:"):
		var leader_index := int(current_leader.substr(7))
		leader_text = Players.player_names[leader_index]
		var avatar_path := Players.get_avatar_path(leader_index)
		if ResourceLoader.exists(avatar_path):
			leader_portrait_rect.texture = load(avatar_path)
			leader_portrait_rect.modulate.a = 1.0
	elif current_leader != "":
		leader_text = AIPlayers.get_rival(current_leader)["name"]
		var portrait_path := AIPlayers.get_portrait_path(current_leader)
		if ResourceLoader.exists(portrait_path):
			leader_portrait_rect.texture = load(portrait_path)
			leader_portrait_rect.modulate.a = 1.0
	bid_label.text = tr("Oferta: %.0f M\n(prowadzi: %s)") % [current_bid, leader_text]

	for index in present_players:
		_update_frame(index)


## Odświeża ramkę JEDNEGO obecnego gracza: własna gotówka, status
## (TYLKO ostrzeżenie o podróbce — patrz niżej) i czy jego przyciski są
## aktywne. Bez osobnego "Prowadzi!" (kto prowadzi widać już w centralnej
## skrzynce oferty, _update_labels/bid_label) i bez "Zrezygnował(a)"
## (zgłoszone przez użytkownika: zablokowane przyciski wystarczą, osobny
## napis niepotrzebny) — is_leader/withdrawn nadal liczone niżej, tylko do
## blokowania przycisków, nie do wyświetlania.
##
## status_label_frame ma STAŁĄ wysokość (custom_minimum_size w
## _build_player_frame) i NIGDY nie jest chowana (visible zawsze true) —
## zgłoszone przez użytkownika: rozmiar ramki nie może się nigdy zmieniać,
## więc pusty/niepusty tekst nie może wpływać na wysokość.
func _update_frame(index: int) -> void:
	var frame: Dictionary = player_frames[index]
	frame["money_label"].text = tr("Gotówka: %.0f M") % Players.get_player_money(index)

	var withdrawn: bool = withdrawn_players.get(index, false)
	var is_leader := current_leader == "player:%d" % index
	frame["status_label"].text = tr("⚠ możliwa podróbka!") if (not withdrawn and player_forgery_warning.get(index, false)) else ""

	## Prowadzący nie może "podbić samego siebie" — ta sama zasada co dla
	## rywali w _apply_best_rival_counter_bid.
	frame["bid_btn"].disabled = withdrawn or is_leader or not auction_active
	frame["resign_btn"].disabled = withdrawn or not auction_active
