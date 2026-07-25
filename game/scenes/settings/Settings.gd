extends Control
## Ekran ustawień — na razie wybór języka interfejsu (Localization.gd).
## Miejsce na przyszłe opcje. Dostępny z menu głównego (MainMenu.gd).


func _ready() -> void:
	## use_menu_frame=false + ALIGNMENT_BEGIN + rozpychacze: zgłoszone przez
	## użytkownika — ozdobna ramka znika, nazwa ekranu zostaje przypięta na
	## samej górze, przycisk powrotu na samym dole (ten sam wzorzec co
	## Gallery.gd _build_category_detail_view).
	var root := ScreenHelpers.make_root(self, false)
	root.alignment = BoxContainer.ALIGNMENT_BEGIN
	ScreenHelpers.make_title(root, "Ustawienia")
	root.add_child(ScreenHelpers.make_expand_spacer())

	ScreenHelpers.make_label(root, "Język / Language / Sprache")

	var lang_option := OptionButton.new()
	var lang_codes: Array[String] = []
	for code in Localization.LANGUAGES.keys():
		lang_option.add_item(Localization.LANGUAGES[code])
		lang_codes.append(code)
		if code == Localization.current_language:
			lang_option.select(lang_codes.size() - 1)
	lang_option.item_selected.connect(func(index: int) -> void: Localization.set_language(lang_codes[index]))
	root.add_child(lang_option)

	root.add_child(ScreenHelpers.make_expand_spacer())
	ScreenHelpers.make_button(root, "« Powrót", func(): SceneRouter.goto_scene(SceneRouter.MAIN_MENU))
