class_name PriceChart
extends Control
## Prosty wykres liniowy cen w czasie, rysowany natywnie — ten sam powód co
## MapPin.gd/VaultIcon.gd/MenuFrame.gd/PlantationTileIcon.gd (Leonardo.ai
## generuje tu pełne sceny zamiast czystego wykresu, patrz
## docs/GRAFIKA_LEONARDO.md). Rysuje N serii (linii) na WSPÓLNEJ osi Y,
## znormalizowanej do wspólnego zakresu min/max WSZYSTKICH serii naraz —
## różne serie (np. 4 linie żeglugowe) są więc porównywalne na jednym
## wykresie. Legenda (kolor + nazwa) to osobne Label-e budowane przez
## wywołującego (patrz StockMarket.gd) — czysty tekst wygodniej robić
## zwykłymi węzłami niż draw_string() w środku tego Controla.

const COLOR_GRID := Color(1, 1, 1, 0.12)
const COLOR_FRAME := Color(1, 1, 1, 0.25)
const LINE_WIDTH := 2.0
const GRID_LINE_COUNT := 3  ## poziome linie siatki MIĘDZY górą a dołem (bez krawędzi)

## {label: {"values": Array[float], "color": Color}} — jeden wpis na serię
## (np. jedną linię żeglugową albo jedną uprawę). Wszystkie serie powinny
## mieć tę samą liczbę punktów (tak jest w tej grze — patrz
## ShippingCompanies.gd/Crops.gd, wszystkie serie rosną w tym samym rytmie).
var series: Dictionary = {}


func _init() -> void:
	## IGNORE — wykres jest czysto wizualny, bez interakcji.
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_series(new_series: Dictionary) -> void:
	series = new_series
	queue_redraw()


func _draw() -> void:
	var s := size
	if s.x <= 0.0 or s.y <= 0.0:
		return

	draw_rect(Rect2(Vector2.ZERO, s), COLOR_FRAME, false, 1.0)
	for i in range(1, GRID_LINE_COUNT + 1):
		var y := s.y * i / float(GRID_LINE_COUNT + 1)
		draw_line(Vector2(0, y), Vector2(s.x, y), COLOR_GRID, 1.0)

	if series.is_empty():
		return

	var min_value := INF
	var max_value := -INF
	var max_points := 0
	for key in series:
		var values: Array = series[key]["values"]
		max_points = maxi(max_points, values.size())
		for v in values:
			min_value = minf(min_value, v)
			max_value = maxf(max_value, v)

	## Za mało punktów na sensowną linię (np. tuż po nowej grze) — sama
	## ramka/siatka wyżej wystarczy, żeby wykres nie wyglądał jak błąd.
	if max_points < 2 or min_value == INF:
		return

	## Wszystkie ceny identyczne (skrajny przypadek, np. tuż po starcie) —
	## bez tego dzielenie przez (max-min)=0 dałoby NaN i nic by się nie
	## narysowało.
	if is_equal_approx(min_value, max_value):
		max_value = min_value + 1.0

	for key in series:
		var values: Array = series[key]["values"]
		if values.size() < 2:
			continue
		var color: Color = series[key].get("color", Color.WHITE)
		var points := PackedVector2Array()
		for i in values.size():
			var x := s.x * i / float(max_points - 1)
			var normalized := (float(values[i]) - min_value) / (max_value - min_value)
			var y := s.y * (1.0 - normalized)
			points.append(Vector2(x, y))
		draw_polyline(points, color, LINE_WIDTH, true)
