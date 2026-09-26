extends Node
## Sprawdzanie aktualizacji z Google Play przy starcie gry (zgłoszone przez
## użytkownika: "czy da się zrobić tak żeby gra jak się uruchamia sprawdzała
## czy ma aktualizacje w google play?"). Owija natywny plugin Androida
## `InAppUpdate` (android_plugins/in_app_update/, kompilowany do
## res://android/plugins/InAppUpdate.aar przy Custom Gradle Build — patrz
## .github/workflows/android-release-build.yml), który z kolei owija
## Google Play In-App Updates (biblioteka Play Core, AppUpdateManager).
##
## Wariant "flexible" (nie "immediate"): aktualizacja ściąga się W TLE, nie
## blokując rozgrywki pełnoekranowym widokiem — gracz dostaje tylko
## niewielki przycisk w Hubie, gdy pobieranie się zakończy (patrz Hub.gd,
## update_ready niżej), i sam decyduje, kiedy zrestartować grę, żeby ją
## zainstalować.
##
## Plugin istnieje WYŁĄCZNIE w wersji Androida zbudowanej Custom Gradle
## Build (preset "Android Release" w export_presets.cfg) I TYLKO gdy apka
## jest zainstalowana z Google Play (Play Core nie działa dla APK
## sideloadowanych/debug — zwraca po prostu "brak aktualizacji" bez
## błędu). Na każdej innej platformie/eksporcie (Web, edytor, testy
## headless, debug APK) Engine.has_singleton() poniżej jest false i ten
## autoload jest w pełni bezpiecznym no-opem — WSZYSTKIE publiczne funkcje
## poniżej muszą działać (nic nie robiąc) bez tego singletonu, żeby nie
## wywalić reszty gry na platformach, gdzie plugin nie istnieje.

const SINGLETON_NAME := "InAppUpdate"

## Ustawiane na true po sygnale "update_downloaded" z pluginu — Hub.gd
## odpytuje to pole (nie łączy się bezpośrednio z sygnałem pluginu), żeby
## dawało poprawny wynik również przy WEJŚCIU do Huba PO tym, jak
## pobieranie zakończyło się w tle, a nie tylko w momencie samego sygnału.
var update_ready: bool = false


func _ready() -> void:
	if not Engine.has_singleton(SINGLETON_NAME):
		return
	var plugin := Engine.get_singleton(SINGLETON_NAME)
	## connect() z nazwą sygnału jako String (nie składnia plugin.update_downloaded.connect(...))
	## — singleton to obiekt natywny (Java/Kotlin, patrz android_plugins/in_app_update/),
	## nie skrypt GDScript ze statycznie znanymi sygnałami, więc tylko ta,
	## ogólna forma Object.connect() jest gwarantowana, że zadziała.
	plugin.connect("update_downloaded", _on_update_downloaded)
	plugin.connect("update_available", _on_update_available)


## Wywołać raz przy starcie gry (patrz MainMenu.gd) — pyta Google Play, czy
## jest nowsza wersja. Bez efektu na platformach bez pluginu.
func check_for_update() -> void:
	if not Engine.has_singleton(SINGLETON_NAME):
		return
	Engine.get_singleton(SINGLETON_NAME).checkForUpdate()


## Gracz kliknął "Zainstaluj aktualizację" w Hubie — Play Core sam
## restartuje aplikację, żeby dokończyć instalację pobranej aktualizacji.
func complete_update() -> void:
	if not Engine.has_singleton(SINGLETON_NAME):
		return
	Engine.get_singleton(SINGLETON_NAME).completeUpdate()


## Aktualizacja jest dostępna (wykryta przez checkForUpdate) — od razu
## zaczynamy ją ściągać w tle (wariant "flexible" nie pyta gracza o zgodę na
## SAM start pobierania, tylko na instalację po ściągnięciu, patrz komentarz
## nagłówkowy), więc plugin natychmiast woła startUpdate() sam z siebie.
func _on_update_available(_available_version_code: int) -> void:
	if not Engine.has_singleton(SINGLETON_NAME):
		return
	Engine.get_singleton(SINGLETON_NAME).startUpdate()


func _on_update_downloaded() -> void:
	update_ready = true
