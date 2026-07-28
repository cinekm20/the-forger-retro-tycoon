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

## tile_index (row*GRID+col) -> ranga odkrycia (0 = odkrywany jako
## pierwszy). Odwrócenie przetasowanej kolejności, żeby set_progress mogła
## sprawdzić "czy ten kafelek mieści się w already-revealed_count" jednym
## porównaniem, zamiast szukać w tablicy za każdym razem.
var reveal_rank: Array[int] = []
var tiles: Array[TextureRect] = []


func setup(image_path: String, puzzle_size: Vector2) -> void:
	custom_minimum_size = puzzle_size
	## SHRINK_CENTER — bez tego VBoxContainer nadrzędny (ArtSchool.gd root)
	## rozciągnąłby tę kontrolkę na pełną szerokość kolumny, a kafelki
	## (pozycjonowane wprost względem puzzle_size, patrz _build_tiles)
	## wylądowałyby przy lewej krawędzi zamiast na środku ekranu — ten sam
	## patent co portret konia w Races.gd.
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	## Ciemne obramowanie Art Deco pod spodem — puste (jeszcze nieodkryte)
	## miejsca w siatce mają wyglądać jak oprawione, puste gniazda układanki,
	## nie czarna dziura na tle.
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(ScreenHelpers.COLOR_BURGUNDY_DARK.r, ScreenHelpers.COLOR_BURGUNDY_DARK.g, ScreenHelpers.COLOR_BURGUNDY_DARK.b, 0.85)
	frame.border_color = ScreenHelpers.COLOR_GOLD
	frame.set_border_width_all(2)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", frame)
	panel.position = Vector2.ZERO
	panel.size = puzzle_size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var texture: Texture2D = null
	if ResourceLoader.exists(image_path):
		texture = load(image_path)

	_build_reveal_order()
	_build_tiles(texture, puzzle_size)


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


func _build_tiles(texture: Texture2D, puzzle_size: Vector2) -> void:
	var tile_size := (puzzle_size - Vector2(TILE_GAP, TILE_GAP) * (GRID - 1)) / float(GRID)
	for row in GRID:
		for col in GRID:
			var tile := TextureRect.new()
			tile.position = Vector2(col * (tile_size.x + TILE_GAP), row * (tile_size.y + TILE_GAP))
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
