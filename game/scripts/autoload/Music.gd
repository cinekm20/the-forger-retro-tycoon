extends Node
## Muzyka w tle — na razie JEDEN wspólny utwór na całą grę (zgłoszone przez
## użytkownika: "podepnij wszędzie to"), dopóki nie powstaną osobne ścieżki
## per ekran (prompty już czekają w docs/MUZYKA_PROMPTY.md). Autoload gra
## utwór raz, w pętli, i przetrwa zmiany scen bez przerywania/restartu —
## żaden ekran nie musi nic wołać, żeby muzyka leciała.

const DEFAULT_TRACK := "res://audio/music/hub.mp3"
const VOLUME_DB := -10.0  ## ciszej niż domyślne 0dB, żeby nie zagłuszało SFX/dialogów w przyszłości
const MUTED_VOLUME_DB := -80.0  ## praktycznie cisza — AudioStreamPlayer nie ma osobnego "mute"

## Osobny plik ustawień od Localization.gd (user://the_forger_settings.json)
## — TAMTEN plik jest niebezpiecznie nadpisywany w całości przy każdym
## zapisie (Localization._save_settings pisze tylko klucz "language"), więc
## dopisanie tu drugiego klucza do TEGO SAMEGO pliku ryzykowałoby ubicie
## zapisanego wyciszenia przy każdej zmianie języka (i na odwrót).
const SETTINGS_PATH := "user://the_forger_audio_settings.json"

var player: AudioStreamPlayer
var muted: bool = false
## Chwilowe podbicie/przyciszenie względem VOLUME_DB (patrz set_volume_offset
## niżej) — wydzielone do osobnej zmiennej, żeby _apply_volume() mogło
## przeliczyć końcową głośność z uwzględnieniem ZARÓWNO tego przesunięcia,
## JAK I wyciszenia, niezależnie od tego, które zmieniło się ostatnie.
var volume_offset_db: float = 0.0


func _ready() -> void:
	_load_settings()
	player = AudioStreamPlayer.new()
	add_child(player)
	play_track(DEFAULT_TRACK)


## Osobna funkcja (nie tylko wywołanie w _ready) — gdy dojdą osobne ścieżki
## per ekran (patrz komentarz wyżej), poszczególne sceny będą mogły wywołać
## Music.play_track(...) przy wejściu, zamiast przerabiać cały autoload.
func play_track(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	player.stream = stream
	_apply_volume()
	player.play()


## Chwilowe podbicie/przyciszenie głośności względem VOLUME_DB — używane
## przez Gallery.gd, żeby muzyka w tle robiła się "żywsza" wraz z
## wypełnieniem kolekcji (zgłoszone przez użytkownika: reaktywna Galeria).
## Wywołujący MUSI przywrócić offset_db=0.0 przy wyjściu z ekranu (patrz
## Gallery._exit_tree) — inaczej zmiana głośności zostałaby też na innych
## ekranach. Wyciszenie (patrz set_muted) ma pierwszeństwo — offset i tak
## nic nie da słychać, dopóki gracz nie odznaczy "Wycisz muzykę".
func set_volume_offset(offset_db: float) -> void:
	volume_offset_db = offset_db
	_apply_volume()


## Zgłoszone przez użytkownika: ekran Ustawień ma dawać możliwość wyciszenia
## muzyki. Trwałe (zapisywane na dysk, patrz _save_settings) — w
## przeciwieństwie do set_volume_offset, które jest tylko chwilowym efektem
## danego ekranu.
func set_muted(value: bool) -> void:
	muted = value
	_apply_volume()
	_save_settings()


func _apply_volume() -> void:
	if not player:
		return
	player.volume_db = MUTED_VOLUME_DB if muted else (VOLUME_DB + volume_offset_db)


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary:
		muted = bool(data.get("muted", false))


func _save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"muted": muted}))
	file.close()
