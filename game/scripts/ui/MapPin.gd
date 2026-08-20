class_name MapPin
extends Button
## Prosta pinezka na mapę, rysowana natywnie w Godocie (bez zewnętrznej
## grafiki) — po kilku nieudanych próbach wygenerowania małej, wyizolowanej
## ikony w Leonardo.ai (model uparcie tworzył pełne sceny zamiast ikon),
## okazało się prostsze i bardziej czytelne zrobić to bezpośrednio w kodzie.

const PIN_SIZE := Vector2(22, 30)
## Złoty akcent zgodny z resztą UI gry (ScreenHelpers.COLOR_GOLD_BRIGHT) —
## obwódka-halo wokół zaznaczonej pinezki (TravelMap._update_pin_selection_visuals).
const COLOR_SELECTED_HALO := Color(1.0, 0.83, 0.4)

var pin_color: Color = Color(0.85, 0.65, 0.2)
## Ustawiane przez TravelMap przy kliknięciu — patrz set_selected() niżej.
## Powiększenie zaznaczonej pinezki robi TravelMap._update_pin_scale
## (mnoży zoom-owe `scale`, ta sama zasada co reszta skalowania pinezek),
## tu tylko wizualne podświetlenie (jaśniejszy kolor + złota obwódka).
var selected: bool = false


func _init() -> void:
	custom_minimum_size = PIN_SIZE
	size = PIN_SIZE
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


## Ustawia stan zaznaczenia i wymusza przerysowanie — samo przypisanie
## `pin.selected = true` bez queue_redraw() nie zmieniłoby niczego na ekranie,
## Godot nie odświeża Control-i automatycznie przy zmianie zwykłej zmiennej.
func set_selected(value: bool) -> void:
	if selected == value:
		return
	selected = value
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var head_radius := w * 0.5
	var center := Vector2(w * 0.5, head_radius)

	if selected:
		draw_arc(center, head_radius * 1.3, 0.0, TAU, 24, COLOR_SELECTED_HALO, 3.0, true)

	var fill_color := pin_color.lightened(0.35) if selected else pin_color
	draw_circle(center, head_radius, fill_color)
	draw_arc(center, head_radius, 0.0, TAU, 24, Color.BLACK, 1.5, true)

	var tip := Vector2(w * 0.5, size.y)
	var left := Vector2(w * 0.5 - head_radius * 0.55, head_radius * 1.15)
	var right := Vector2(w * 0.5 + head_radius * 0.55, head_radius * 1.15)
	draw_colored_polygon(PackedVector2Array([left, right, tip]), fill_color)

	draw_circle(center, head_radius * 0.35, Color.WHITE)
