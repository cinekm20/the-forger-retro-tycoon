class_name MenuFrame
extends Control
## Ozdobna ramka Art Deco wokół panelu menu, rysowana natywnie w Godocie —
## po nieudanej próbie z grafiką z Leonardo (pojedyncze motywy zdobne przy
## krawędziach kwadratowego obrazka zniekształcały się przy rozciąganiu
## przez NinePatchRect do wąskiego, wysokiego panelu) okazało się prościej
## i pewniej zrobić to bezpośrednio w kodzie, tak jak MapPin.gd/
## TravelVehicle.gd. _draw() liczy wszystko na bieżąco z aktualnego `size`,
## więc skaluje się idealnie do dowolnej wysokości panelu (różne miasta
## mają różną liczbę pozycji w menu) — zero artefaktów rozciągania.

const BORDER_COLOR := Color(0.85, 0.65, 0.2)
const BG_COLOR := Color(0.13, 0.04, 0.06, 0.85)
const MARGIN := 6.0
const INNER_MARGIN := 13.0
const CORNER_SIZE := 22.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var w := size.x
	var h := size.y

	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)

	draw_rect(Rect2(Vector2(MARGIN, MARGIN), Vector2(w, h) - Vector2(MARGIN, MARGIN) * 2.0), BORDER_COLOR, false, 2.0)
	draw_rect(Rect2(Vector2(INNER_MARGIN, INNER_MARGIN), Vector2(w, h) - Vector2(INNER_MARGIN, INNER_MARGIN) * 2.0), BORDER_COLOR, false, 1.0)

	_draw_corner(Vector2(MARGIN, MARGIN), Vector2(1, 1))
	_draw_corner(Vector2(w - MARGIN, MARGIN), Vector2(-1, 1))
	_draw_corner(Vector2(MARGIN, h - MARGIN), Vector2(1, -1))
	_draw_corner(Vector2(w - MARGIN, h - MARGIN), Vector2(-1, -1))


## Mały złamany akcent w rogu (charakterystyczny dla art déco "stepped"
## narożnik) — linia łamana odsunięta od prostej ramki, skierowana do
## środka zgodnie z `dir` (znak określa, w którą stronę od narożnika
## biegnie każde ramię kątownika).
func _draw_corner(corner: Vector2, dir: Vector2) -> void:
	var points := PackedVector2Array([
		corner + Vector2(CORNER_SIZE, 0.0) * dir,
		corner + Vector2(6.0, 0.0) * dir,
		corner + Vector2(6.0, 6.0) * dir,
		corner + Vector2(0.0, 6.0) * dir,
		corner + Vector2(0.0, CORNER_SIZE) * dir,
	])
	draw_polyline(points, BORDER_COLOR, 2.0)
