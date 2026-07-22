class_name VaultIcon
extends Control
## Ikona sejfu (skrytka na akcje spółki żeglugowej) rysowana natywnie w
## Godocie, tak jak MapPin.gd/TravelVehicle.gd/MenuFrame.gd — te same
## powody (Leonardo.ai uparcie generuje pełne sceny zamiast małych,
## wyizolowanych ikon, patrz docs/GRAFIKA_LEONARDO.md). Nawiązuje do
## sejfów z ekranu giełdy w oryginale (zrzut ekranu użytkownika: 5
## fioletowo-niebieskich sejfów z tarczą szyfrową, po jednym na spółkę).

const ICON_SIZE := Vector2(96, 96)

const COLOR_BORDER := Color(0.14, 0.1, 0.32)
const COLOR_FACE := Color(0.42, 0.38, 0.78)
const COLOR_FACE_HIGHLIGHT := Color(0.52, 0.48, 0.86)
const COLOR_DIAL := Color(0.2, 0.15, 0.42)
const COLOR_HANDLE := Color(0.85, 0.65, 0.2)


func _init() -> void:
	custom_minimum_size = ICON_SIZE
	size = ICON_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var w := size.x
	var h := size.y

	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BORDER)

	var inset := w * 0.07
	var face_rect := Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0)
	draw_rect(face_rect, COLOR_FACE)

	## Cienki jaśniejszy pasek u góry — sugeruje metaliczny połysk drzwiczek
	## sejfu, bez potrzeby gradientu.
	var highlight_rect := Rect2(Vector2(inset, inset), Vector2(size.x - inset * 2.0, h * 0.12))
	draw_rect(highlight_rect, COLOR_FACE_HIGHLIGHT)

	var center := size * 0.5
	var dial_radius := w * 0.26
	draw_circle(center, dial_radius, COLOR_DIAL)
	draw_arc(center, dial_radius, 0.0, TAU, 24, COLOR_BORDER, 2.0, true)

	## Wskazówka tarczy szyfrowej pod stałym kątem — dekoracja, nie
	## interaktywna, akcent koloru złota jak reszta UI.
	var handle_angle := -PI * 0.35
	var handle_end := center + Vector2(cos(handle_angle), sin(handle_angle)) * dial_radius * 0.75
	draw_line(center, handle_end, COLOR_HANDLE, 3.0)
	draw_circle(center, 3.0, COLOR_HANDLE)

	## Cztery narożne nity — akcent, żeby sejf nie wyglądał jak płaski
	## kwadrat.
	var rivet_inset := inset * 1.8
	var rivet_positions := [
		Vector2(rivet_inset, rivet_inset),
		Vector2(w - rivet_inset, rivet_inset),
		Vector2(rivet_inset, h - rivet_inset),
		Vector2(w - rivet_inset, h - rivet_inset),
	]
	for pos in rivet_positions:
		draw_circle(pos, w * 0.02, COLOR_BORDER)
