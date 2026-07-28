extends Control
## Ochrona (ochroniarz) i Rywale (gangster) — wydzielone z Gallery.gd na
## zgłoszenie użytkownika: to nie ma nic wspólnego z przeglądaniem samej
## kolekcji obrazów, więc dostaje WŁASNY ekran, osiągalny z Huba (menu
## "Miejsca »", dostępne z każdego miasta — ochroniarza/gangstera można
## wysłać niezależnie od lokalizacji, tak jak Wyścigi konne).
##
## Nazwa pliku CELOWO "SecurityScreen", nie "Security" — `Security.gd` w
## scripts/autoload/ to już istniejący globalny singleton
## (Security.hire_bodyguard()/resolve_gangster_attempt() itd., używany tu
## wprost), więc drugi plik o identycznej nazwie w innym folderze byłby
## mylący dla człowieka, mimo że technicznie nie kolidowałby (Godot
## rozróżnia po pełnej ścieżce res://, nie po samej nazwie pliku).
##
## Zgłoszenie użytkownika: "ataki na innych" mają dostać animowaną scenę
## skoku (HeistView.gd) + prawdziwy roster wybieralnych gangsterów
## (Gangsters.gd, dryfująca szansa 20-50% jak kursy koni w Horses.gd) zamiast
## gołego przycisku "Wyślij gangstera" z jedną stałą szansą na rywala. Ten
## sam podział odpowiedzialności co Races.gd/RaceTrackView:
## Security.resolve_gangster_attempt() ustala wynik OD RAZU (przed
## animacją), HeistView tylko go wizualizuje, Security.apply_gangster_result()
## nalicza faktyczne skutki (kradzież obrazu ALBO grzywna za złapanie)
## DOPIERO po zakończeniu animacji.

const HeistViewScript := preload("res://scripts/ui/HeistView.gd")

var security_label: Label
var gangster_option: OptionButton
var rival_option: OptionButton
var send_btn: Button
var back_btn: Button
var rival_ids: Array[String] = []
var rival_count_labels: Array[Label] = []

## Widok animacji, budowany dopiero w _on_send_gangster_pressed (ten sam
## powód co race_track w Races.gd — nie trzymamy pustego węzła czekającego
## bezczynnie, tylko tworzymy go w momencie, gdy faktycznie jest potrzebny).
## is_attacking to DODATKOWE zabezpieczenie przed drugą próbą w trakcie
## animacji (send_btn i tak jest disabled, patrz _on_send_gangster_pressed).
var heist_view: Control
var is_attacking: bool = false


func _ready() -> void:
	ScreenHelpers.make_background(self, "res://art/backgrounds/gallery.jpg")

	## ALIGNMENT_BEGIN + JEDEN rozpychacz na końcu — patrz Races.gd po
	## uzasadnienie, czemu JEDEN rozpychacz (nie dwa).
	var root := ScreenHelpers.make_root(self, false)
	root.alignment = BoxContainer.ALIGNMENT_BEGIN
	ScreenHelpers.make_title(root, "Ochrona")
	ScreenHelpers.make_turn_indicator(root)

	security_label = ScreenHelpers.make_label(root, "")
	_update_security_label()

	## Roster gangsterów do wynajęcia — portret + nazwa + dryfująca szansa
	## powodzenia (Gangsters.gd), TEN SAM układ co konie w Races.gd (portret,
	## pod nim nazwa, jeszcze niżej kurs/szansa). Sam wybór KTÓREGO wysłać
	## dzieje się przez gangster_option niżej (w skrzynce z przyciskiem
	## powrotu) — te karty to podgląd/porównanie, nie klikalne przyciski.
	## _make_subheading (nie make_title, 38px) — zgłoszony bug: z pełnymi
	## tytułami ekranu ("Gangsterzy"/"Rywale" OBOK już istniejącego "Ochrona")
	## treść rosła na tyle wysoko, że nachodziła na powiększoną skrzynkę w
	## rogu (4 kontrolki zamiast 2, patrz corner_box niżej).
	_make_subheading(root, "Gangsterzy")
	var gangsters_row := HBoxContainer.new()
	gangsters_row.alignment = BoxContainer.ALIGNMENT_CENTER
	gangsters_row.add_theme_constant_override("separation", 28)
	root.add_child(gangsters_row)

	for gangster_id in Gangsters.GANGSTERS.keys():
		var gangster: Dictionary = Gangsters.GANGSTERS[gangster_id]
		var card := VBoxContainer.new()
		card.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_theme_constant_override("separation", 4)
		gangsters_row.add_child(card)

		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(96, 96)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var image_path: String = gangster["image"]
		if ResourceLoader.exists(image_path):
			portrait.texture = load(image_path)
		card.add_child(portrait)

		var name_label := Label.new()
		name_label.text = gangster["name"]
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
		name_label.add_theme_color_override("font_color", ScreenHelpers.COLOR_CREAM)
		card.add_child(name_label)

		var chance_label := Label.new()
		chance_label.text = tr("szansa %.0f%%") % [Gangsters.get_success_chance(gangster_id) * 100.0]
		chance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chance_label.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
		chance_label.add_theme_color_override("font_color", ScreenHelpers.COLOR_GOLD_BRIGHT)
		card.add_child(chance_label)

	_make_subheading(root, "Rywale")
	rival_ids.clear()
	rival_count_labels.clear()
	## JEDEN poziomy rząd (nie oddzielny wiersz na rywala) — oszczędza
	## dodatkowe miejsce w pionie, patrz komentarz przy "Gangsterzy" wyżej.
	var rivals_row := HBoxContainer.new()
	rivals_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rivals_row.add_theme_constant_override("separation", 28)
	root.add_child(rivals_row)
	for rival in AIPlayers.rivals:
		rival_ids.append(rival["id"])
		var rival_label := Label.new()
		rival_label.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
		rivals_row.add_child(rival_label)
		rival_count_labels.append(rival_label)
	_update_rival_labels()

	## Zgłoszenie użytkownika: "Zatrudnij ochroniarza" i "Wyślij gangstera"
	## mają wylądować w TEJ SAMEJ skrzynce co przycisk powrotu — dokładnie
	## jak zakład w Races.gd/kurs w ArtSchool.gd.
	var corner_box := ScreenHelpers.make_root_bottom(self, true)

	var bodyguard_btn := ScreenHelpers.make_button(
		corner_box,
		tr("Zatrudnij ochroniarza (%.0f M)") % Security.BODYGUARD_COST,
		_on_hire_bodyguard_pressed,
	)
	bodyguard_btn.disabled = Security.has_bodyguard

	var attack_row := HBoxContainer.new()
	attack_row.alignment = BoxContainer.ALIGNMENT_CENTER
	corner_box.add_child(attack_row)

	gangster_option = OptionButton.new()
	gangster_option.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
	for gangster_id in Gangsters.GANGSTERS.keys():
		gangster_option.add_item(Gangsters.GANGSTERS[gangster_id]["name"])
	attack_row.add_child(gangster_option)

	rival_option = OptionButton.new()
	rival_option.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
	for rival_id in rival_ids:
		rival_option.add_item(AIPlayers.get_rival(rival_id)["name"])
	attack_row.add_child(rival_option)

	## send_btn W TYM SAMYM rzędzie co dropdowny (nie osobny wiersz pod
	## spodem) — jedna kontrolka mniej w pionie w corner_box, patrz komentarz
	## przy "Gangsterzy" wyżej o nachodzeniu na treść ekranu.
	send_btn = ScreenHelpers.make_button(
		attack_row,
		tr("Wyślij gangstera (%.0f M)") % Security.GANGSTER_COST,
		_on_send_gangster_pressed,
	)

	back_btn = ScreenHelpers.make_back_button(corner_box)


## Nagłówek śródekranowy MNIEJSZY niż make_title (38px) — używany dla
## "Gangsterzy"/"Rywale" zamiast pełnego tytułu ekranu, żeby zostawić więcej
## miejsca w pionie na resztę treści (patrz komentarz przy "Gangsterzy" w
## _ready()).
func _make_subheading(root: Container, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", ScreenHelpers.COLOR_GOLD_BRIGHT)
	root.add_child(label)


func _on_hire_bodyguard_pressed() -> void:
	if Security.hire_bodyguard():
		_update_security_label()
		SceneRouter.goto_scene(SceneRouter.SECURITY)  # przeładuj, żeby odświeżyć stan przycisku


func _on_send_gangster_pressed() -> void:
	## Podwójne zabezpieczenie — send_btn i tak jest disabled w trakcie
	## animacji (patrz niżej), ale gdyby coś odświeżyło stan między
	## kliknięciami, druga próba i tak nie powinna przejść.
	if is_attacking:
		return
	if not Economy.spend(Security.GANGSTER_COST):
		security_label.text = tr("Za mało gotówki na gangstera.")
		return

	## Wynik skoku ustalony OD RAZU, dokładnie jak zwycięzca wyścigu w
	## Races.gd — HeistView tylko wizualizuje ten JUŻ ustalony wynik, nigdy
	## go nie zmienia. Wypłata/tekst wyniku czekają na _on_heist_finished.
	var gangster_ids: Array = Gangsters.GANGSTERS.keys()
	var gangster_id: String = gangster_ids[gangster_option.selected]
	var rival_id: String = rival_ids[rival_option.selected]
	var result := Security.resolve_gangster_attempt(gangster_id, rival_id)

	security_label.text = ""
	is_attacking = true
	send_btn.disabled = true
	gangster_option.disabled = true
	rival_option.disabled = true
	back_btn.disabled = true

	var outcome := "success"
	if not result["success"]:
		outcome = "failure_caught" if result["caught"] else "failure_escaped"

	## Zgłoszenie użytkownika: informacja o wyniku (w tym grzywna za złapanie)
	## ma być widoczna w ramce PODCZAS animacji — komunikat liczony OD RAZU
	## (wynik już ustalony) i przekazany do HeistView.setup(), a nie dopiero
	## po jej zakończeniu.
	var message := _format_gangster_result_message(result)

	heist_view = HeistViewScript.new()
	add_child(heist_view)
	heist_view.finished.connect(_on_heist_finished.bind(result, message))
	heist_view.setup(Gangsters.GANGSTERS[gangster_id]["image"], AIPlayers.get_portrait_path(rival_id), outcome, message, get_viewport_rect().size)


func _on_heist_finished(result: Dictionary, message: String) -> void:
	heist_view.queue_free()
	heist_view = null
	is_attacking = false
	send_btn.disabled = false
	gangster_option.disabled = false
	rival_option.disabled = false
	back_btn.disabled = false

	Security.apply_gangster_result(result)
	_update_rival_labels()
	security_label.text = message


func _format_gangster_result_message(result: Dictionary) -> String:
	if result["success"]:
		return tr("Gangster wraca z obrazem!")
	if result["caught"]:
		return tr("Gangster złapany! Dodatkowa grzywna %.0f M.") % Security.CAUGHT_FINE
	return tr("Gangster wraca z pustymi rękami — pieniądze przepadły.")


func _update_rival_labels() -> void:
	for i in rival_ids.size():
		var rival: Dictionary = AIPlayers.get_rival(rival_ids[i])
		rival_count_labels[i].text = tr("%s: %d obrazów") % [rival["name"], AIPlayers.get_rival_painting_count(rival_ids[i])]


func _update_security_label() -> void:
	security_label.text = (
		tr("Masz ochroniarza — obrazy chronione przed kradzieżą.")
		if Security.has_bodyguard
		else tr("Bez ochrony — Twoja kolekcja jest narażona na kradzież (~%.0f%% szans/tydzień).") % [
			Security.WEEKLY_THEFT_CHANCE_UNPROTECTED * 100.0,
		]
	)
