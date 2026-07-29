class_name StatIcon
extends Control
## Małe ikonki statystyk (gotówka/data/eksperckość) rysowane natywnie w
## Godocie — ten sam powód co MapPin.gd/VaultIcon.gd/PlantationTileIcon.gd
## (Leonardo.ai uparcie generuje pełne sceny zamiast małych, wyizolowanych
## ikon, patrz docs/GRAFIKA_LEONARDO.md, wiersz 7b "Plan produkcji"). Jedna
## klasa z enum Kind (jak PlantationTileIcon.gd), nie osobny plik na ikonę —
## trzy warianty dzielą ten sam rozmiar/paletę i zawsze stoją tuż obok
## etykiety tekstowej tej samej wysokości (ScreenHelpers.BODY_FONT_SIZE).

enum Kind { MONEY, DATE, EXPERTISE }

const ICON_SIZE := Vector2(22, 22)

const COLOR_GOLD := Color(0.85, 0.65, 0.2)
const COLOR_GOLD_BRIGHT := Color(1.0, 0.83, 0.4)
const COLOR_BURGUNDY_DARK := Color(0.13, 0.04, 0.06)

var kind: int = Kind.MONEY


func _init(icon_kind: int = Kind.MONEY) -> void:
	kind = icon_kind
	custom_minimum_size = ICON_SIZE
	size = ICON_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	match kind:
		Kind.MONEY:
			_draw_money()
		Kind.DATE:
			_draw_date()
		Kind.EXPERTISE:
			_draw_expertise()


## Moneta: wypełnione złote kółko + ciemniejszy rąbek + rombowy "wygrawerowany"
## akcent na środku (zamiast dosłownego symbolu waluty — czytelne we
## wszystkich trzech językach gry, PL/EN/DE).
func _draw_money() -> void:
	var center := size * 0.5
	var r := size.x * 0.42
	draw_circle(center, r, COLOR_GOLD)
	draw_arc(center, r, 0.0, TAU, 20, COLOR_BURGUNDY_DARK, 1.5, true)
	var d := r * 0.42
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -d),
		center + Vector2(d, 0),
		center + Vector2(0, d),
		center + Vector2(-d, 0),
	]), COLOR_BURGUNDY_DARK)


## Kalendarzyk: prostokąt z nagłówkiem u góry + dwie "uszka" spirali + trzy
## kropki siatki dni.
func _draw_date() -> void:
	var body := Rect2(Vector2(size.x * 0.1, size.y * 0.22), Vector2(size.x * 0.8, size.y * 0.68))
	draw_rect(body, COLOR_GOLD_BRIGHT, false, 1.6)
	var header := Rect2(body.position, Vector2(body.size.x, body.size.y * 0.28))
	draw_rect(header, COLOR_GOLD)
	for i in 2:
		var x := size.x * (0.3 + i * 0.4)
		draw_line(Vector2(x, size.y * 0.12), Vector2(x, size.y * 0.3), COLOR_GOLD_BRIGHT, 1.6)
	var dot_r := size.x * 0.045
	for i in 3:
		var dot_x := body.position.x + body.size.x * (0.22 + i * 0.28)
		var dot_y := body.position.y + body.size.y * 0.68
		draw_circle(Vector2(dot_x, dot_y), dot_r, COLOR_GOLD_BRIGHT)


## Lupa (badanie autentyczności obrazu): pierścień + rączka po przekątnej.
func _draw_expertise() -> void:
	var lens_center := size * Vector2(0.42, 0.42)
	var lens_r := size.x * 0.28
	draw_arc(lens_center, lens_r, 0.0, TAU, 20, COLOR_GOLD_BRIGHT, 2.2, true)
	var dir := Vector2(1, 1).normalized()
	var handle_start := lens_center + dir * lens_r
	var handle_end := handle_start + dir * size.x * 0.34
	draw_line(handle_start, handle_end, COLOR_GOLD_BRIGHT, 2.6)
