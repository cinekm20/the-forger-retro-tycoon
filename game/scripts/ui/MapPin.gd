class_name MapPin
extends Button
## Prosta pinezka na mapę, rysowana natywnie w Godocie (bez zewnętrznej
## grafiki) — po kilku nieudanych próbach wygenerowania małej, wyizolowanej
## ikony w Leonardo.ai (model uparcie tworzył pełne sceny zamiast ikon),
## okazało się prostsze i bardziej czytelne zrobić to bezpośrednio w kodzie.

const PIN_SIZE := Vector2(22, 30)

var pin_color: Color = Color(0.85, 0.65, 0.2)


func _init() -> void:
	custom_minimum_size = PIN_SIZE
	size = PIN_SIZE
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _draw() -> void:
	var w := size.x
	var head_radius := w * 0.5
	var center := Vector2(w * 0.5, head_radius)

	draw_circle(center, head_radius, pin_color)
	draw_arc(center, head_radius, 0.0, TAU, 24, Color.BLACK, 1.5, true)

	var tip := Vector2(w * 0.5, size.y)
	var left := Vector2(w * 0.5 - head_radius * 0.55, head_radius * 1.15)
	var right := Vector2(w * 0.5 + head_radius * 0.55, head_radius * 1.15)
	draw_colored_polygon(PackedVector2Array([left, right, tip]), pin_color)

	draw_circle(center, head_radius * 0.35, Color.WHITE)
