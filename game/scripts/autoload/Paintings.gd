extends Node
## Katalog 40 obrazów w 8 kategoriach stylistycznych + system autentykacji
## oparty na numerze katalogowym. Źródło: docs/ZRODLA_C64_WIKI.md.

const CATEGORIES := [
	"vermeer", "baroque", "classicism", "romanticism",
	"impressionism", "symbolism", "expressionism", "modern",
]

const CATEGORY_NAMES := {
	"vermeer": "Vermeer",
	"baroque": "Barok",
	"classicism": "Klasycyzm",
	"romanticism": "Romantyzm",
	"impressionism": "Impresjonizm",
	"symbolism": "Symbolizm",
	"expressionism": "Ekspresjonizm",
	"modern": "Moderna",
}

## number -> {category, era_note}. Nazwiska malarzy z tabeli źródłowej są tu
## tylko jako wewnętrzna wskazówka stylu (patrz GRAFIKA_LEONARDO.md pkt. 7 —
## w promptach do generowania grafik opisujemy styl/epokę, nie nazwisko).
const CATALOG := {
	1: "vermeer", 2: "vermeer", 3: "vermeer", 4: "vermeer", 5: "vermeer",
	6: "baroque", 7: "baroque", 8: "baroque", 9: "baroque", 10: "baroque",
	11: "classicism", 12: "classicism", 13: "classicism", 14: "classicism", 15: "classicism",
	16: "romanticism", 17: "romanticism", 18: "romanticism", 19: "romanticism", 20: "romanticism",
	21: "impressionism", 22: "impressionism", 23: "impressionism", 24: "impressionism", 25: "impressionism",
	26: "symbolism", 27: "symbolism", 28: "symbolism", 29: "symbolism", 30: "symbolism",
	31: "expressionism", 32: "expressionism", 33: "expressionism", 34: "expressionism", 35: "expressionism",
	36: "modern", 37: "modern", 38: "modern", 39: "modern", 40: "modern",
}

## Szacunkowa wartość bazowa wg kategorii — nasza własna wycena do
## balansowania, nie dane źródłowe.
const CATEGORY_BASE_VALUE := {
	"vermeer": 15000.0,
	"baroque": 8000.0,
	"classicism": 6000.0,
	"romanticism": 6000.0,
	"impressionism": 9000.0,
	"symbolism": 5000.0,
	"expressionism": 7000.0,
	"modern": 12000.0,
}

const MAX_EXPERTISE := 0.9

const EASY_WIN_THRESHOLD := 15  ## docs/GDD.md pkt. 6: tryb łatwy = 15/40 obrazów

## Numery obrazów aktualnie skatalogowanych przez gracza (nieodwracalne —
## patrz docs/ZRODLA_C64_WIKI.md pkt. "Fragment 4", bug #4 oryginału,
## który u nas świadomie staje się zamierzoną mechaniką).
var catalogued_numbers: Array[int] = []

## Eksperckość (0.0–0.9) — patrz GDD.md pkt. 4.6: podnosi szansę na wczesne
## ostrzeżenie o duplikacie numeru katalogowego przed licytacją.
var expertise: float = 0.0

## Ile obrazów trzeba skatalogować, by wygrać — CATALOG.size() (40) w trybie
## normalnym, EASY_WIN_THRESHOLD (15) w trybie łatwym.
var win_threshold: int = CATALOG.size()


func reset_new_game(easy_mode: bool = false) -> void:
	catalogued_numbers.clear()
	expertise = 0.0
	win_threshold = EASY_WIN_THRESHOLD if easy_mode else CATALOG.size()


func increase_expertise(amount: float) -> void:
	expertise = min(MAX_EXPERTISE, expertise + amount)


## Zwraca true, jeśli szkoła sztuki zdąży ostrzec gracza przed podróbką
## (tylko ma sens, gdy is_forgery_by_duplicate(number) == true).
func warns_about_forgery(number: int) -> bool:
	return is_forgery_by_duplicate(number) and randf() < expertise


func get_estimated_value(number: int) -> float:
	return CATEGORY_BASE_VALUE.get(get_category(number), 5000.0)


## Zwraca true, jeśli próba katalogowania tego numeru ujawnia fałszywkę
## (numer już posiadany).
func is_forgery_by_duplicate(number: int) -> bool:
	return catalogued_numbers.has(number)


func catalogue(number: int) -> void:
	if not catalogued_numbers.has(number):
		catalogued_numbers.append(number)


func owned_count() -> int:
	return catalogued_numbers.size()


func has_all_paintings() -> bool:
	return owned_count() >= win_threshold


func get_category(number: int) -> String:
	return CATALOG.get(number, "")
