extends Node
## Katalog 40 obrazów w 8 kategoriach stylistycznych + system autentykacji
## oparty na numerze katalogowym. Źródło: docs/ZRODLA_C64_WIKI.md (w tym
## prawdziwe tytuły/autorzy/lata/muzea z rewersów oryginalnych kart gry —
## PAINTING_INFO niżej).

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

## number -> kategoria. Zweryfikowane wg prawdziwych opisów z rewersów 40
## kart obrazów dołączonych do oryginalnej gry (Ariolasoft, patrz
## docs/ZRODLA_C64_WIKI.md, fragment "Gemäldekarten") — wcześniejsza wersja
## tego słownika (bloki 1–5/6–10/…) była szacunkiem sprzed dostępu do tych
## danych i NIE zgadzała się z prawdziwym przypisaniem numerów katalogowych
## do konkretnych obrazów. Każdy numer przypisany do kategorii wg
## faktycznego stylu/epoki malarza z karty, zbalansowane do 5 na kategorię.
## Nazwiska malarzy z tabeli źródłowej służą tylko jako wewnętrzna wskazówka
## stylu (patrz GRAFIKA_LEONARDO.md pkt. 7 — w promptach do generowania
## grafik opisujemy styl/epokę, nie nazwisko/nie kopiujemy oryginalnych
## reprodukcji, część obrazów np. Picassa/Braque'a wciąż podlega prawom
## autorskim w części krajów).
const CATALOG := {
	1: "baroque", 2: "baroque", 3: "vermeer", 4: "vermeer", 5: "baroque",
	6: "vermeer", 7: "impressionism", 8: "impressionism", 9: "vermeer", 10: "vermeer",
	11: "impressionism", 12: "impressionism", 13: "impressionism", 14: "symbolism", 15: "romanticism",
	16: "romanticism", 17: "symbolism", 18: "symbolism", 19: "romanticism", 20: "romanticism",
	21: "symbolism", 22: "symbolism", 23: "romanticism", 24: "classicism", 25: "modern",
	26: "expressionism", 27: "classicism", 28: "classicism", 29: "modern", 30: "modern",
	31: "classicism", 32: "classicism", 33: "expressionism", 34: "modern", 35: "baroque",
	36: "baroque", 37: "expressionism", 38: "expressionism", 39: "expressionism", 40: "modern",
}

## number -> {title, artist, year, museum}. Prawdziwe dane z rewersów kart
## (docs/ZRODLA_C64_WIKI.md) — pokazywane graczowi jako oprawa tematyczna
## podczas licytacji (AuctionHouse.gd). Same fakty (tytuł/autor/rok/muzeum)
## nie podlegają prawom autorskim, w odróżnieniu od reprodukcji samego
## obrazu — dlatego GRAFIKA jest naszą własną reinterpretacją stylu
## (GRAFIKA_LEONARDO.md §7), a nie zeskanowaną kartą.
const PAINTING_INFO := {
	1: {"title": "Salwa armatnia", "artist": "Willem van de Velde", "year": "ok. 1670", "museum": "Amsterdam, Rijksmuseum"},
	2: {"title": "Porwanie córek Leukipposa", "artist": "Rubens", "year": "ok. 1619", "museum": "Monachium, Alte Pinakothek"},
	3: {"title": "Pracownia malarska", "artist": "Vermeer", "year": "1666", "museum": "Wiedeń, Kunsthistorisches Museum"},
	4: {"title": "Koronczarka", "artist": "Vermeer", "year": "1665", "museum": "Paryż, Luwr"},
	5: {"title": "Starzec w fotelu", "artist": "Rembrandt", "year": "1652", "museum": "Londyn, National Gallery"},
	6: {"title": "Czytająca list kobieta w błękicie", "artist": "Vermeer", "year": "1662–1663", "museum": "Amsterdam, Rijksmuseum"},
	7: {"title": "Wanna", "artist": "Degas", "year": "1886", "museum": "Paryż, Luwr"},
	8: {"title": "Portret malarza Waltera Leistikowa", "artist": "Corinth", "year": "1900", "museum": "Berlin, Muzea Państwowe"},
	9: {"title": "Astronom", "artist": "Vermeer", "year": "1668", "museum": "Paryż, kolekcja prywatna"},
	10: {"title": "Dziewczyna z perłą", "artist": "Vermeer", "year": "1665", "museum": "Haga, Mauritshuis"},
	11: {"title": "Gabrielle w rozpiętej bluzce", "artist": "Renoir", "year": "ok. 1907", "museum": "Paryż, kolekcja Durand-Ruel"},
	12: {"title": "Klify pod Pourville", "artist": "Monet", "year": "1882", "museum": "kolekcja prywatna"},
	13: {"title": "Grający w karty", "artist": "Cézanne", "year": "1890–1892", "museum": "Paryż, Luwr"},
	14: {"title": "Symfonia w bieli", "artist": "Whistler", "year": "1864", "museum": "Londyn, Tate Gallery"},
	15: {"title": "Morze lodu (Rozbite nadzieje)", "artist": "Friedrich", "year": "1823–1824", "museum": "Hamburg, Kunsthalle"},
	16: {"title": "Latarnia morska w Harwich", "artist": "Constable", "year": "ok. 1820", "museum": "Londyn, Tate Gallery"},
	17: {"title": "Kobieta jedząca ostrygi", "artist": "Ensor", "year": "1882", "museum": "Antwerpia, Musée des Beaux-Arts"},
	18: {"title": "Portret Emilie Flöge", "artist": "Klimt", "year": "1902", "museum": "Wiedeń, Muzeum Historyczne Miasta Wiednia"},
	19: {"title": "Pożar Izb Parlamentu w Londynie, 16 października 1834", "artist": "Turner", "year": "1835", "museum": "Cleveland Museum of Art"},
	20: {"title": "Grecja na ruinach Missolungi", "artist": "Delacroix", "year": "ok. 1826–1827", "museum": "Bordeaux, Musée des Beaux-Arts"},
	21: {"title": "Tryton i Nereida", "artist": "Böcklin", "year": "1895", "museum": "Florencja, Villa Roma"},
	22: {"title": "Zamykam się w sobie", "artist": "Khnopff", "year": "1891", "museum": "Monachium, Neue Pinakothek"},
	23: {"title": "Autoportret", "artist": "Runge", "year": "1802", "museum": "Hamburg, Kunsthalle"},
	24: {"title": "Dziedziniec zamku Warwick", "artist": "Canaletto", "year": "1751", "museum": "Warwick, kolekcja Księcia Warwick"},
	25: {"title": "Dwie Tahitanki", "artist": "Gauguin", "year": "1899", "museum": "Nowy Jork, Metropolitan Museum of Art"},
	26: {"title": "Zwodzony most", "artist": "Van Gogh", "year": "1888", "museum": "Kolonia, Wallraf-Richartz-Museum"},
	27: {"title": "Autoportret", "artist": "Chardin", "year": "1775", "museum": "Paryż, Luwr"},
	28: {"title": "Kąpiąca się z Valpinçon", "artist": "Ingres", "year": "1808", "museum": "Paryż, Luwr"},
	29: {"title": "Złote rybki i rzeźba", "artist": "Matisse", "year": "1911", "museum": "Nowy Jork, MoMA"},
	30: {"title": "Tancerka", "artist": "Derain", "year": "1906", "museum": "Kopenhaga, Statens Museum for Kunst"},
	31: {"title": "Skruszony święty Piotr", "artist": "Goya", "year": "1823–1825", "museum": "Waszyngton, The Phillips Collection"},
	32: {"title": "Śmierć Marata", "artist": "David", "year": "1793", "museum": "Bruksela, Musées royaux des Beaux-Arts"},
	33: {"title": "Madonna", "artist": "Munch", "year": "1893–1894", "museum": "Oslo, Munch Museet"},
	34: {"title": "Fryzura", "artist": "Picasso", "year": "1906", "museum": "Nowy Jork, Metropolitan Museum of Art"},
	35: {"title": "Żniwa", "artist": "Brueghel", "year": "1565", "museum": "Nowy Jork, Metropolitan Museum"},
	36: {"title": "Młodzieniec trzymający czaszkę", "artist": "Hals", "year": "ok. 1626", "museum": "Londyn, National Gallery"},
	37: {"title": "Kościół wiejski", "artist": "Kandinsky", "year": "1908", "museum": "Wuppertal, Von der Heydt-Museum"},
	38: {"title": "Koń w krajobrazie", "artist": "Marc", "year": "1910", "museum": "Essen, Museum Folkwang"},
	39: {"title": "Targ w Tunisie", "artist": "Macke", "year": "1914", "museum": "Bielefeld, Kunsthalle"},
	40: {"title": "Wiadukt w L'Estaque", "artist": "Braque", "year": "1908", "museum": "kolekcja prywatna"},
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


## Tytuł/autor/rok/muzeum obrazu nr `number` (patrz PAINTING_INFO wyżej) —
## pusty słownik, jeśli numer spoza katalogu.
func get_painting_info(number: int) -> Dictionary:
	return PAINTING_INFO.get(number, {})


## Ścieżka do grafiki obrazu nr `number` (docs/GRAFIKA_LEONARDO.md §7) —
## AuctionHouse.gd/Gallery.gd nakładają ją jako osobną warstwę na puste
## płótno na sztaludze w tle, więc nazwa pliku musi się zgadzać co do joty
## z konwencją `painting_NN.jpg` (dwucyfrowy numer katalogowy). Dopóki
## grafiki nie istnieją, wywołujący musi sam sprawdzić
## ResourceLoader.exists() przed load() — funkcja tylko liczy ścieżkę.
func get_texture_path(number: int) -> String:
	return "res://art/paintings/painting_%02d.jpg" % number
