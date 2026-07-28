extends Control
class_name ExpertisePuzzle
## Wizualizacja Paintings.expertise w Szkole sztuki (ArtSchool.gd) jako
## układanka — obraz stopniowo "składa się" z kafelków w miarę wzrostu
## eksperckości, zamiast gołej liczby procent. Zgłoszenie użytkownika: "żeby
## ten obraz się randomowo układał" — kolejność odkrywania kafelków jest
## przetasowana (nie rząd po rzędzie), ale ZAWSZE ta sama (stały
## REVEAL_SEED), więc przy każdej wizycie na ekranie widać ten sam, stabilny
## układ — zmienia się wyłącznie LICZBA odkrytych kafelków, przekazywana
## przez set_progress(fraction). Mini-gra "znajdź podróbkę" (jedyny sposób
## zdobywania eksperckości) zostaje bez zmian — to WYŁĄCZNIE nowy sposób
## POKAZANIA już istniejącej wartości Paintings.expertise.

const GRID := 5
const REVEAL_SEED := 20260728
const TILE_GAP := 3.0

## Ta sama ozdobna rama obrazu co Galeria/Dom aukcyjny (art/icons/frame.png)
## — zgłoszenie użytkownika: "dodaj ramkę obrazów tutaj", żeby układanka
## wyglądała jak oprawiony obraz, tak jak wszystkie inne obrazy w grze,
## zamiast gołej ramki systemowej. Stałe identyczne jak w Gallery.gd/
## AuctionHouse.gd (holder_size to CAŁKOWITY rozmiar łącznie z ramą, inset
## to ułamek szerokości, jaki rama zajmuje z każdej strony).
const FRAME_TEXTURE_PATH := "res://art/icons/frame.png"
const FRAME_INNER_INSET := 0.145

## tile_index (row*GRID+col) -> ranga odkrycia (0 = odkrywany jako
## pierwszy). Odwrócenie przetasowanej kolejności, żeby set_progress mogła
## sprawdzić "czy ten kafelek mieści się w already-revealed_count" jednym
## porównaniem, zamiast szukać w tablicy za każdym razem.
var reveal_rank: Array[int] = []
var tiles: Array[TextureRect] = []


## holder_size: CAŁKOWITY rozmiar (rama + wnętrze), ta sama konwencja co
## holder_size w Gallery.gd/AuctionHouse.gd _build_framed_image.
func setup(image_path: String, holder_size: Vector2) -> void:
	custom_minimum_size = holder_size
	## SHRINK_CENTER — bez tego VBoxContainer nadrzędny (ArtSchool.gd root)
	## rozciągnąłby tę kontrolkę na pełną szerokość kolumny, a kafelki
	## (pozycjonowane wprost względem obszaru obrazu, patrz _build_tiles)
	## wylądowałyby przy lewej krawędzi zamiast na środku ekranu — ten sam
	## patent co portret konia w Races.gd.
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	## Kolejność przypisań WAŻNA: expand_mode/stretch_mode MUSZĄ być ustawione
	## PRZED size — frame.png ma naturalny rozmiar 1024×1024, a Control.size
	## przy przypisaniu jest usztywniany do combined_minimum_size W TYM
	## MOMENCIE; jeśli expand_mode wciąż jest domyślne (respektujące rozmiar
	## tekstury), przypisanie size=holder_size (np. 240×240) i tak zostaje
	## podbite z powrotem do 1024×1024 i już się nie cofa, mimo że
	## expand_mode zmienia się o linijkę niżej (stąd olbrzymia, wychodząca
	## poza ekran rama zamiast 240×240 — znaleziony i naprawiony przez
	## wizualną weryfikację zrzutem ekranu).
	var frame_rect := TextureRect.new()
	frame_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame_rect.stretch_mode = TextureRect.STRETCH_SCALE
	frame_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_rect.texture = load(FRAME_TEXTURE_PATH)
	frame_rect.position = Vector2.ZERO
	frame_rect.size = holder_size
	add_child(frame_rect)

	## Obszar obrazu (kafelki) leży WEWNĄTRZ ramy, wcięty o FRAME_INNER_INSET
	## z każdej strony — dokładnie tak samo jak inner_rect w
	## Gallery.gd/AuctionHouse.gd _build_framed_image.
	var picture_offset := holder_size * FRAME_INNER_INSET
	var picture_size := holder_size * (1.0 - 2.0 * FRAME_INNER_INSET)

	## Ciemne tło pod spodem — puste (jeszcze nieodkryte) miejsca w siatce
	## mają wyglądać jak wnętrze ramy czekające na obraz, nie czarna dziura.
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(ScreenHelpers.COLOR_BURGUNDY_DARK.r, ScreenHelpers.COLOR_BURGUNDY_DARK.g, ScreenHelpers.COLOR_BURGUNDY_DARK.b, 0.85)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", bg)
	panel.position = picture_offset
	panel.size = picture_size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var texture: Texture2D = null
	if ResourceLoader.exists(image_path):
		texture = load(image_path)

	_build_reveal_order()
	_build_tiles(texture, picture_offset, picture_size)


func _build_reveal_order() -> void:
	var order: Array[int] = []
	for i in GRID * GRID:
		order.append(i)

	## Fisher-Yates z RandomNumberGenerator o STAŁYM seedzie — "losowa", ale
	## powtarzalna kolejność (patrz komentarz nagłówkowy: ten sam układ przy
	## każdej wizycie na ekranie).
	var rng := RandomNumberGenerator.new()
	rng.seed = REVEAL_SEED
	for i in range(order.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = order[i]
		order[i] = order[j]
		order[j] = tmp

	reveal_rank.resize(GRID * GRID)
	for rank in order.size():
		reveal_rank[order[rank]] = rank


func _build_tiles(texture: Texture2D, picture_offset: Vector2, picture_size: Vector2) -> void:
	var tile_size := (picture_size - Vector2(TILE_GAP, TILE_GAP) * (GRID - 1)) / float(GRID)
	for row in GRID:
		for col in GRID:
			var tile := TextureRect.new()
			tile.position = picture_offset + Vector2(col * (tile_size.x + TILE_GAP), row * (tile_size.y + TILE_GAP))
			tile.size = tile_size
			tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tile.stretch_mode = TextureRect.STRETCH_SCALE
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tile.visible = false
			if texture:
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				var tw := texture.get_width() / float(GRID)
				var th := texture.get_height() / float(GRID)
				atlas.region = Rect2(col * tw, row * th, tw, th)
				tile.texture = atlas
			add_child(tile)
			tiles.append(tile)


## fraction: 0.0–1.0 (Paintings.expertise trafia tu WPROST — pułap
## Paintings.MAX_EXPERTISE=0.9 oznacza, że układanka też nigdy nie dojdzie
## do kompletu, dokładnie tak samo jak etykieta procentowa obok niej nigdy
## nie pokaże 100%).
func set_progress(fraction: float) -> void:
	var revealed_count := int(round(clampf(fraction, 0.0, 1.0) * (GRID * GRID)))
	for tile_index in tiles.size():
		tiles[tile_index].visible = reveal_rank[tile_index] < revealed_count
