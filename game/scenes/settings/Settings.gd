extends Control
## Ekran ustawień — wybór języka interfejsu (Localization.gd) i wyciszenie
## muzyki (Music.gd). Miejsce na przyszłe opcje. Dostępny z menu głównego
## (MainMenu.gd).


func _ready() -> void:
	## Zgłoszone przez użytkownika: tło i skrzynka opcji mają wyglądać tak
	## samo jak wszędzie indziej w grze, nie goły ekran bez tła. Dedykowana
	## grafika (docs/GRAFIKA_LEONARDO.md §11) jeszcze nie wygenerowana — po
	## cichu spada na tło Giełdy, tak jak WorldEventCard.gd, dopóki plik nie
	## zostanie wgrany.
	var background_path := "res://art/backgrounds/settings.jpg"
	if not ResourceLoader.exists(background_path):
		background_path = "res://art/backgrounds/stock_market.jpg"
	ScreenHelpers.make_background(self, background_path)

	## use_menu_frame=false + ALIGNMENT_BEGIN + JEDEN rozpychacz na końcu:
	## zgłoszone przez użytkownika — ozdobna ramka znika, nazwa ekranu zostaje
	## przypięta na samej górze, przycisk powrotu na samym dole. Treść leci
	## zaraz pod tytułem (bez rozpychacza między nimi) — patrz Races.gd po
	## szczegółowe uzasadnienie, czemu JEDEN rozpychacz (nie dwa).
	var root := ScreenHelpers.make_root(self, false)
	root.alignment = BoxContainer.ALIGNMENT_BEGIN
	ScreenHelpers.make_title(root, "Ustawienia")

	## Skrzynka Art Deco, TA SAMA co wszędzie indziej (ScreenHelpers.make_boxed_panel)
	## — zgłoszone przez użytkownika: opcje mają być w ładnym, oprawionym
	## menu, nie luźno na tle.
	var options_box: VBoxContainer = ScreenHelpers.make_boxed_panel(root)["content"]

	ScreenHelpers.make_label(options_box, "Język / Language / Sprache")

	var lang_option := OptionButton.new()
	lang_option.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lang_option.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
	var lang_codes: Array[String] = []
	for code in Localization.LANGUAGES.keys():
		lang_option.add_item(Localization.LANGUAGES[code])
		lang_codes.append(code)
		if code == Localization.current_language:
			lang_option.select(lang_codes.size() - 1)
	lang_option.item_selected.connect(func(index: int) -> void: Localization.set_language(lang_codes[index]))
	options_box.add_child(lang_option)

	var mute_check := CheckBox.new()
	mute_check.text = tr("Wycisz muzykę")
	mute_check.button_pressed = Music.muted
	mute_check.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mute_check.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
	mute_check.toggled.connect(Music.set_muted)
	options_box.add_child(mute_check)

	## Ozdobna skrzynka Art Deco w prawym dolnym rogu, TA SAMA co boczny
	## panel na TravelMap.gd/Hub.gd — zgłoszone przez użytkownika: przycisk
	## powrotu ma wyglądać tak samo na wszystkich ekranach (oprócz Plantacji).
	## Zakotwiczona niezależnie od `root`, więc bez rozpychacza.
	ScreenHelpers.make_button(ScreenHelpers.make_root_bottom(self, true), "« Powrót", func(): SceneRouter.goto_scene(SceneRouter.MAIN_MENU))
