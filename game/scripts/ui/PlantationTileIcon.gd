class_name PlantationTileIcon
extends Control
## Ikonka pojedynczego pola plantacji, rysowana natywnie — ten sam powód co
## VaultIcon.gd/MapPin.gd/MenuFrame.gd (Leonardo.ai nie generuje małych,
## wyizolowanych ikon, patrz docs/GRAFIKA_LEONARDO.md). Zastępuje poprzednie
## symbole tekstowe (~/+/✓/✓+), które wymagały osobnej legendy tłumaczącej
## ich znaczenie (zgłoszone przez użytkownika: usunąć opis, zrobić ikonki) —
## kolor/kształt ma być czytelny sam z siebie: niebieska "fala" = rzeka,
## jasna, dzika ziemia z krzakami = wolne pole do kupienia, ciemna, zaorana
## ziemia = Twoje pole, kolorowa roślinka na ziemi = obsiane pole (kolor wg
## uprawy), cienka jasnoniebieska obwódka = pole sąsiaduje z rzeką (większy
## plon przy zbiorach).

enum Kind { RIVER, VACANT, SOIL, CROP }

const COLOR_RIVER := Color(0.25, 0.45, 0.75)
const COLOR_RIVER_WAVE := Color(0.75, 0.88, 0.97)
const COLOR_VACANT := Color(0.55, 0.52, 0.35)
const COLOR_VACANT_SCRUB := Color(0.65, 0.62, 0.4)
const COLOR_SOIL := Color(0.4, 0.27, 0.15)
const COLOR_SOIL_CLOD := Color(0.32, 0.21, 0.11)
const COLOR_RIVER_ADJACENT_RING := Color(0.4, 0.75, 0.95)

const CROP_COLORS := {
	"coffee": Color(0.32, 0.18, 0.09),
	"tobacco": Color(0.68, 0.62, 0.22),
	"tea": Color(0.28, 0.55, 0.28),
	"cocoa": Color(0.42, 0.22, 0.12),
}

var kind: int = Kind.VACANT
var crop: String = ""
var river_adjacent: bool = false


func _init() -> void:
	## IGNORE — ikonka jest czysto wizualna, tylko rodzic (Button w
	## Plantation.gd) obsługuje kliknięcia zakupu pola.
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var s := size
	if s.x <= 0.0 or s.y <= 0.0:
		return
	match kind:
		Kind.RIVER:
			draw_rect(Rect2(Vector2.ZERO, s), COLOR_RIVER)
			for i in 2:
				var y := s.y * (0.32 + i * 0.36)
				draw_line(Vector2(s.x * 0.1, y), Vector2(s.x * 0.9, y), COLOR_RIVER_WAVE, maxf(1.0, s.x * 0.08))
		Kind.VACANT:
			draw_rect(Rect2(Vector2.ZERO, s), COLOR_VACANT)
			draw_circle(s * Vector2(0.3, 0.6), s.x * 0.12, COLOR_VACANT_SCRUB)
			draw_circle(s * Vector2(0.65, 0.35), s.x * 0.12, COLOR_VACANT_SCRUB)
		Kind.SOIL:
			draw_rect(Rect2(Vector2.ZERO, s), COLOR_SOIL)
			for i in 3:
				var y := s.y * (0.25 + i * 0.25)
				draw_line(Vector2(s.x * 0.1, y), Vector2(s.x * 0.9, y), COLOR_SOIL_CLOD, maxf(1.0, s.x * 0.06))
		Kind.CROP:
			draw_rect(Rect2(Vector2.ZERO, s), COLOR_SOIL)
			var plant_color: Color = CROP_COLORS.get(crop, Color.FOREST_GREEN)
			draw_circle(s * 0.5, s.x * 0.32, plant_color)
			draw_circle(s * Vector2(0.5, 0.32), s.x * 0.14, plant_color.lightened(0.3))
	if river_adjacent:
		draw_arc(s * 0.5, s.x * 0.42, 0.0, TAU, 12, COLOR_RIVER_ADJACENT_RING, maxf(1.0, s.x * 0.1), true)
