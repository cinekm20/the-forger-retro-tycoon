extends Control
## Ochrona (ochroniarz) i Rywale (gangster) — wydzielone z Gallery.gd na
## zgłoszenie użytkownika: to nie ma nic wspólnego z przeglądaniem samej
## kolekcji obrazów, więc dostaje WŁASNY ekran, osiągalny z Huba (menu
## "Miejsca »", dostępne z każdego miasta — ochroniarza/gangstera można
## wysłać niezależnie od lokalizacji, tak jak Wyścigi konne).
##
## Nazwa pliku CELOWO "SecurityScreen", nie "Security" — `Security.gd` w
## scripts/autoload/ to już istniejący globalny singleton
## (Security.hire_bodyguard()/send_gangster() itd., używany tu wprost),
## więc drugi plik o identycznej nazwie w innym folderze byłby mylący dla
## człowieka, mimo że technicznie nie kolidowałby (Godot rozróżnia po
## pełnej ścieżce res://, nie po samej nazwie pliku).

var security_label: Label


func _ready() -> void:
	ScreenHelpers.make_background(self, "res://art/backgrounds/gallery.jpg")

	## ALIGNMENT_BEGIN + JEDEN rozpychacz na końcu: zgłoszone przez
	## użytkownika — ten ekran miał już usuniętą ozdobną ramkę, ale nie
	## dostał przypięcia tytułu/przycisku jak reszta ("dalej ochrona nie ma
	## tak zrobione jak wszystkie"), bo w poprzednim przeglądzie wszystkich
	## ekranów pominięto go (już wcześniej wywoływał make_root z false, więc
	## nie pasował do wyszukiwania miejsc z jeszcze WŁĄCZONĄ ramką). Patrz
	## Races.gd po uzasadnienie, czemu JEDEN rozpychacz (nie dwa).
	var root := ScreenHelpers.make_root(self, false)
	root.alignment = BoxContainer.ALIGNMENT_BEGIN
	ScreenHelpers.make_title(root, "Ochrona")
	ScreenHelpers.make_turn_indicator(root)

	security_label = ScreenHelpers.make_label(root, "")
	var bodyguard_btn := ScreenHelpers.make_button(
		root,
		tr("Zatrudnij ochroniarza (%.0f M)") % Security.BODYGUARD_COST,
		_on_hire_bodyguard_pressed,
	)
	bodyguard_btn.disabled = Security.has_bodyguard
	_update_security_label()

	ScreenHelpers.make_title(root, "Rywale")
	for rival in AIPlayers.rivals:
		var rival_row := HBoxContainer.new()
		rival_row.alignment = BoxContainer.ALIGNMENT_CENTER
		root.add_child(rival_row)
		var rival_label := Label.new()
		rival_label.text = tr("%s: %d obrazów") % [rival["name"], AIPlayers.get_rival_painting_count(rival["id"])]
		rival_row.add_child(rival_label)
		var gangster_btn := Button.new()
		gangster_btn.text = tr("Wyślij gangstera (%.0f M)") % Security.GANGSTER_COST
		gangster_btn.pressed.connect(_on_send_gangster_pressed.bind(rival["id"]))
		rival_row.add_child(gangster_btn)

	root.add_child(ScreenHelpers.make_expand_spacer())
	ScreenHelpers.make_back_button(root)


func _on_hire_bodyguard_pressed() -> void:
	if Security.hire_bodyguard():
		_update_security_label()
		SceneRouter.goto_scene(SceneRouter.SECURITY)  # przeładuj, żeby odświeżyć stan przycisku


func _on_send_gangster_pressed(rival_id: String) -> void:
	var success := Security.send_gangster(rival_id)
	security_label.text = (
		tr("Gangster wraca z obrazem!") if success else tr("Gangster wraca z pustymi rękami — pieniądze przepadły.")
	)


func _update_security_label() -> void:
	security_label.text = (
		tr("Masz ochroniarza — obrazy chronione przed kradzieżą.")
		if Security.has_bodyguard
		else tr("Bez ochrony — Twoja kolekcja jest narażona na kradzież (~%.0f%% szans/tydzień).") % [
			Security.WEEKLY_THEFT_CHANCE_UNPROTECTED * 100.0,
		]
	)
