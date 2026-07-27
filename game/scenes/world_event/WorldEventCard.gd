extends Control
## Karta wydarzenia "gazetowego" — reforma walutowa, kryzys na plantacji
## (strajk/zamieszki) albo krach/hossa na giełdzie, pokazywana jako
## pełnoekranowy popup MIĘDZY TURAMI,
## zanim Hub zbuduje normalny widok (patrz Hub.gd _ready, ten sam wzorzec co
## YearSummary.gd). Zgłoszone przez użytkownika: "w formie gazety i popup
## między turami". Kolejka zdarzeń (WorldEvents.gd) może mieć więcej niż
## jedno naraz (np. po długiej podróży) — "Kontynuuj" po prostu wraca do
## Huba, którego _ready() sam sprawdzi, czy jest kolejna karta do pokazania,
## zanim w końcu zbuduje normalny Hub.

var event: Dictionary = {}


func _ready() -> void:
	event = WorldEvents.consume_next()

	## Ilustracja nagłówka gazety — po cichu spada na tło Giełdy, dopóki
	## dedykowane grafiki (docs/GRAFIKA_LEONARDO.md §4) nie zostaną wgrane,
	## tak jak wszystkie opcjonalne grafiki w tej grze.
	var background_path := _background_path()
	if not ResourceLoader.exists(background_path):
		background_path = "res://art/backgrounds/stock_market.jpg"
	ScreenHelpers.make_background(self, background_path)

	## use_menu_frame=false + ALIGNMENT_BEGIN + jeden rozpychacz na końcu —
	## ten sam wzorzec co reszta ekranów gry (patrz np. Races.gd): nagłówek
	## zawsze na samej górze, przycisk "Kontynuuj" zawsze na samym dole.
	var root := ScreenHelpers.make_root(self, false)
	root.alignment = BoxContainer.ALIGNMENT_BEGIN
	ScreenHelpers.make_title(root, _headline())

	var body_label := ScreenHelpers.make_label(root, _body_text())
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	body_label.custom_minimum_size = Vector2(700, 0)

	## Ozdobna skrzynka Art Deco w prawym dolnym rogu, TA SAMA co boczny
	## panel na TravelMap.gd/Hub.gd — zgłoszone przez użytkownika: przycisk
	## powrotu ma wyglądać tak samo na wszystkich ekranach (oprócz Plantacji).
	## Zakotwiczona niezależnie od `root`, więc bez rozpychacza.
	ScreenHelpers.make_button(ScreenHelpers.make_root_bottom(self, true), tr("Kontynuuj »"), func(): SceneRouter.goto_hub())


func _background_path() -> String:
	match event.get("kind", ""):
		"reform":
			return "res://art/events/reform.jpg"
		"crisis":
			return "res://art/events/strike.jpg" if event.get("cause", "") == "wages" else "res://art/events/riot.jpg"
		"crash":
			return "res://art/events/crash.jpg"
		"boom":
			return "res://art/events/boom.jpg"
		_:
			return ""


func _headline() -> String:
	match event.get("kind", ""):
		"reform":
			return tr("Reforma walutowa!")
		"crisis":
			if event.get("cause", "") == "wages":
				return tr("Strajk w %s!") % Cities.get_city_name(event.get("city", ""))
			return tr("Zamieszki w %s!") % Cities.get_city_name(event.get("city", ""))
		"crash":
			return tr("Krach giełdowy!")
		"boom":
			return tr("Hossa na giełdzie!")
		_:
			return tr("Wiadomości")


func _body_text() -> String:
	match event.get("kind", ""):
		"reform":
			return tr("Rząd wprowadza nowy przelicznik marki na dolara: %d:1. Nowy kurs dolara: %.2f M.") % [
				int(event.get("ratio", 1.0)), event.get("dollar_rate", 0.0),
			]
		"crisis":
			return _crisis_body_text()
		"crash", "boom":
			return _market_shock_body_text()
		_:
			return ""


func _market_shock_body_text() -> String:
	var change_ratio: float = event.get("change_ratio", 0.0)
	if change_ratio < 0.0:
		return tr("Panika na parkiecie! Kursy WSZYSTKICH linii żeglugowych spadają naraz o %.0f%%.") % [-change_ratio * 100.0]
	return tr("Euforia inwestorów! Kursy WSZYSTKICH linii żeglugowych rosną naraz o %.0f%%.") % [change_ratio * 100.0]


func _crisis_body_text() -> String:
	var lines: Array[String] = []
	if event.get("cause", "") == "wages":
		lines.append(tr("Robotnicy porzucają pracę wobec zaległych wypłat."))
	else:
		lines.append(tr("Niepokoje społeczne uderzają w plantację."))

	var workers_lost: int = int(event.get("workers_lost", 0))
	if workers_lost > 0:
		lines.append(tr("Straciłeś/-aś %d robotników.") % workers_lost)
	if event.get("crops_lost", false):
		lines.append(tr("Zebrane zapasy zostały skonfiskowane."))
	if event.get("plantation_lost", false):
		lines.append(tr("Sytuacja wymknęła się spod kontroli — plantacja została całkowicie utracona."))

	return "\n".join(lines)
