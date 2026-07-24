extends Node
## Muzyka w tle — na razie JEDEN wspólny utwór na całą grę (zgłoszone przez
## użytkownika: "podepnij wszędzie to"), dopóki nie powstaną osobne ścieżki
## per ekran (prompty już czekają w docs/MUZYKA_PROMPTY.md). Autoload gra
## utwór raz, w pętli, i przetrwa zmiany scen bez przerywania/restartu —
## żaden ekran nie musi nic wołać, żeby muzyka leciała.

const DEFAULT_TRACK := "res://audio/music/hub.mp3"
const VOLUME_DB := -10.0  ## ciszej niż domyślne 0dB, żeby nie zagłuszało SFX/dialogów w przyszłości

var player: AudioStreamPlayer


func _ready() -> void:
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
	player.volume_db = VOLUME_DB
	player.play()


## Chwilowe podbicie/przyciszenie głośności względem VOLUME_DB — używane
## przez Gallery.gd, żeby muzyka w tle robiła się "żywsza" wraz z
## wypełnieniem kolekcji (zgłoszone przez użytkownika: reaktywna Galeria).
## Wywołujący MUSI przywrócić offset_db=0.0 przy wyjściu z ekranu (patrz
## Gallery._exit_tree) — inaczej zmiana głośności zostałaby też na innych
## ekranach.
func set_volume_offset(offset_db: float) -> void:
	player.volume_db = VOLUME_DB + offset_db
