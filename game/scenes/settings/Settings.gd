extends Control
## Ekran ustawień — na razie wybór języka interfejsu (Localization.gd).
## Miejsce na przyszłe opcje. Dostępny z menu głównego (MainMenu.gd).


func _ready() -> void:
	## use_menu_frame=false + ALIGNMENT_BEGIN + JEDEN rozpychacz na końcu:
	## zgłoszone przez użytkownika — ozdobna ramka znika, nazwa ekranu zostaje
	## przypięta na samej górze, przycisk powrotu na samym dole. Treść leci
	## zaraz pod tytułem (bez rozpychacza między nimi) — patrz Races.gd po
	## szczegółowe uzasadnienie, czemu JEDEN rozpychacz (nie dwa).
	var root := ScreenHelpers.make_root(self, false)
	root.alignment = BoxContainer.ALIGNMENT_BEGIN
	ScreenHelpers.make_title(root, "Ustawienia")

	ScreenHelpers.make_label(root, "Język / Language / Sprache")

	var lang_option := OptionButton.new()
	lang_option.add_theme_font_size_override("font_size", ScreenHelpers.BODY_FONT_SIZE)
	var lang_codes: Array[String] = []
	for code in Localization.LANGUAGES.keys():
		lang_option.add_item(Localization.LANGUAGES[code])
		lang_codes.append(code)
		if code == Localization.current_language:
			lang_option.select(lang_codes.size() - 1)
	lang_option.item_selected.connect(func(index: int) -> void: Localization.set_language(lang_codes[index]))
	root.add_child(lang_option)

	## Ozdobna skrzynka Art Deco w prawym dolnym rogu, TA SAMA co boczny
	## panel na TravelMap.gd/Hub.gd — zgłoszone przez użytkownika: przycisk
	## powrotu ma wyglądać tak samo na wszystkich ekranach (oprócz Plantacji).
	## Zakotwiczona niezależnie od `root`, więc bez rozpychacza.
	ScreenHelpers.make_button(ScreenHelpers.make_root_bottom(self, true), "« Powrót", func(): SceneRouter.goto_scene(SceneRouter.MAIN_MENU))
