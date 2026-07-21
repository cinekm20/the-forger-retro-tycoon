class_name TravelVehicle
extends Control
## Prosty, rysowany natywnie pojazd do animacji podróży (pociąg/samolot) —
## ta sama logika co MapPin: zamiast walczyć z Leonardo o małą, wyizolowaną
## ikonę, rysujemy silhouette bezpośrednio w kodzie.

const ICON_SIZE := Vector2(56, 34)

var is_plane: bool = false
var vehicle_color: Color = Color(0.85, 0.65, 0.2)


func _init() -> void:
	custom_minimum_size = ICON_SIZE
	size = ICON_SIZE


func _draw() -> void:
	if is_plane:
		_draw_plane()
	else:
		_draw_train()


func _draw_train() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(w * 0.05, h * 0.15, w * 0.9, h * 0.5), vehicle_color)
	draw_rect(Rect2(w * 0.75, 0.0, w * 0.18, h * 0.2), vehicle_color)
	draw_circle(Vector2(w * 0.25, h * 0.75), h * 0.14, Color.BLACK)
	draw_circle(Vector2(w * 0.75, h * 0.75), h * 0.14, Color.BLACK)
	draw_circle(Vector2(w * 0.25, h * 0.75), h * 0.14, vehicle_color, false, 2.0)
	draw_circle(Vector2(w * 0.75, h * 0.75), h * 0.14, vehicle_color, false, 2.0)


func _draw_plane() -> void:
	var w := size.x
	var h := size.y
	var body := PackedVector2Array([
		Vector2(0.0, h * 0.5),
		Vector2(w * 0.75, h * 0.38),
		Vector2(w, h * 0.5),
		Vector2(w * 0.75, h * 0.62),
	])
	draw_colored_polygon(body, vehicle_color)
	var wing := PackedVector2Array([
		Vector2(w * 0.35, h * 0.5),
		Vector2(w * 0.55, 0.0),
		Vector2(w * 0.68, h * 0.5),
	])
	draw_colored_polygon(wing, vehicle_color)
	var tail := PackedVector2Array([
		Vector2(w * 0.05, h * 0.5),
		Vector2(w * 0.18, h * 0.15),
		Vector2(w * 0.22, h * 0.5),
	])
	draw_colored_polygon(tail, vehicle_color)
