extends Node
## Wybór języka interfejsu (Polski / English / Deutsch). Polski jest językiem
## "źródłowym" — to dokładnie taki tekst jest wpisany na sztywno w kodzie
## (label.text = "..."). Godot automatycznie tłumaczy właściwości typu
## Label.text/Button.text przez TranslationServer (Control.auto_translate_mode
## domyślnie ALWAYS), pod warunkiem że w projekcie są wczytane pliki tłumaczeń
## z DOKŁADNIE takim polskim tekstem jako kluczem (patrz translations/ui.csv)
## — więc reszta kodu nie musi wywoływać tr() ręcznie przy statycznych
## napisach. Sformatowane teksty (z %d/%s) MUSZĄ jawnie wołać tr("szablon")
## PRZED podstawieniem wartości, inaczej klucz (już z podstawioną liczbą) nie
## trafi w tłumaczenie — patrz odpowiednie miejsca w kodzie ekranów.

const LANGUAGES := {
	"pl": "Polski",
	"en": "English",
	"de": "Deutsch",
}

const SETTINGS_PATH := "user://vermeer_settings.json"

var current_language: String = "pl"


func _ready() -> void:
	_load_settings()
	TranslationServer.set_locale(current_language)


func set_language(lang: String) -> void:
	if not LANGUAGES.has(lang):
		return
	current_language = lang
	TranslationServer.set_locale(lang)
	_save_settings()


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary and LANGUAGES.has(data.get("language", "")):
		current_language = data["language"]


func _save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"language": current_language}))
	file.close()
