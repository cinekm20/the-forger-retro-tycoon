extends Control
## Docelowo 8 sekcji stylistycznych, po 5 slotów. Patrz GDD.md pkt. 4.7.
## Ochrona/kradzieże: docs/DODATKOWE_MECHANIKI.md.
##
## Zgłoszone przez użytkownika: "reaktywna Galeria" — oświetlenie sali
## (nakładka na tło) i głośność muzyki w tle reagują na to, jak bardzo
## kolekcja jest zapełniona (Paintings.owned_count()/win_threshold), zamiast
## samego liczbowego postępu X/5. Pusta/początkowa kolekcja = ciemna,
## przygaszona sala i cichsza muzyka; pełna kolekcja = ciepła, złota
## poświata i głośniejsza, "żywsza" muzyka. Każda w pełni skompletowana
## kategoria (5/5) dodatkowo podświetla się na złoto zamiast zwykłej kremowej
## etykiety.

## Kolor nakładki przy pustej kolekcji — ciemny, chłodny (przygaszona sala).
const DIM_OVERLAY_COLOR := Color(0.0, 0.0, 0.05, 0.6)
## Kolor nakładki przy pełnej kolekcji — ciepły, prawie przezroczysty (złota poświata).
const LIT_OVERLAY_COLOR := Color(0.55, 0.4, 0.1, 0.05)
## Maks. podbicie głośności muzyki w tle przy pełnej kolekcji (patrz Music.gd).
const MAX_MUSIC_VOLUME_BOOST_DB := 6.0

var security_label: Label
var overlay: ColorRect


func _ready() -> void:
	var bg_layers := ScreenHelpers.make_background_with_overlay(self, "res://art/backgrounds/gallery.jpg")
	overlay = bg_layers["overlay"]

	var fill_ratio := float(Paintings.owned_count()) / float(Paintings.win_threshold)
	overlay.color = DIM_OVERLAY_COLOR.lerp(LIT_OVERLAY_COLOR, fill_ratio)
	Music.set_volume_offset(fill_ratio * MAX_MUSIC_VOLUME_BOOST_DB)

	var root := ScreenHelpers.make_root(self)
	ScreenHelpers.make_title(root, "Galeria")
	ScreenHelpers.make_turn_indicator(root)

	ScreenHelpers.make_label(root, tr("Twoja kolekcja: %d/%d (próg zwycięstwa)") % [
		Paintings.owned_count(), Paintings.win_threshold,
	])

	for category_id in Paintings.CATEGORIES:
		var category_name: String = Paintings.CATEGORY_NAMES[category_id]
		var owned_in_category := 0
		for number in Paintings.catalogued_numbers:
			if Paintings.get_category(number) == category_id:
				owned_in_category += 1
		var category_label := ScreenHelpers.make_label(root, tr("%s: %d/5") % [category_name, owned_in_category])
		if owned_in_category >= 5:
			category_label.add_theme_color_override("font_color", ScreenHelpers.COLOR_GOLD_BRIGHT)

	if Players.is_multiplayer():
		ScreenHelpers.make_title(root, "Gracze")
		for i in Players.player_count:
			var marker := tr(" (Ty)") if i == Players.active_index else ""
			ScreenHelpers.make_label(root, tr("%s%s: %d obrazów") % [
				Players.player_names[i], marker, Players.get_painting_count(i),
			])

	ScreenHelpers.make_title(root, "Ochrona")
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

	ScreenHelpers.make_back_button(root)


## Podbicie głośności ustawione w _ready() dotyczy TYLKO tego ekranu — bez
## przywrócenia tutaj zostałoby też na Hubie/innych ekranach po wyjściu z
## Galerii, cichnąc/głośniejąc dopiero przy następnym wejściu do niej.
func _exit_tree() -> void:
	Music.set_volume_offset(0.0)


func _on_hire_bodyguard_pressed() -> void:
	if Security.hire_bodyguard():
		_update_security_label()
		SceneRouter.goto_scene(SceneRouter.GALLERY)  # przeładuj, żeby odświeżyć stan przycisku


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
