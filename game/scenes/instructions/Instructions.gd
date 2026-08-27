extends Control
## Ekran instrukcji — pełny podręcznik mechanik gry, jedno wspólne źródło
## prawdy zamiast rozproszonych wskazówek. Dostępny z każdego głównego
## ekranu nawigacyjnego przez przycisk „?” w prawym górnym rogu
## (ScreenHelpers.make_instructions_button). Treść to własna, skrócona
## redakcja oparta na docs/GDD.md, docs/DODATKOWE_MECHANIKI.md i
## docs/MECHANIKI_EKONOMICZNE.md (a dla dokładnych liczb — na samym kodzie
## mechanik, np. PlayerPlantations.gd/Crops.gd) — nie przedruk żadnego z
## tych dokumentów. Zawiera WYŁĄCZNIE ekrany nawigacyjne (zgłoszone przez
## użytkownika) — bez modali/animacji (karty wydarzeń, animacja podróży,
## ekran zakończenia, Noworoczna Loteria mają własny, samowyjaśniający się
## kontekst na ekranie).
##
## Zgłoszone przez użytkownika: ekran ma być "w ramce" (jak Hub/TravelMap) i
## rozszerzony o zrzuty ekranu z rzeczywistej gry, żeby dokładnie pokazać, co
## robi każdy przycisk — stąd (inaczej niż większość dzisiejszych "płaskich"
## ekranów w tej grze) użyty jest tu use_menu_frame=true: jedyny wariant
## make_root() z WBUDOWANYM ScrollContainerem (patrz screen_helpers.gd), co
## akurat tu jest zaletą, bo treści jest sporo więcej niż mieści się na
## jednym ekranie. Przycisk powrotu jest zwykłym guzikiem NA KOŃCU treści
## (nie osobną, pływającą skrzynką jak ScreenHelpers.make_boxed_back_button
## gdzie indziej) — druga ozdobna ramka w tym samym rogu co ramka główna
## nakładałaby się na nią wizualnie.

## Zrzuty ekranu (game/art/instructions/*.jpg) — 960×540, przechwycone
## bezpośrednio z działającej gry (nie generowane w Leonardo.ai), więc
## zawsze wiernie pokazują aktualny wygląd/rozmieszczenie przycisków.
## IMAGE_WIDTH dobrany tak, żeby zmieścił się z zapasem nawet w wąskiej,
## portretowej ramce na telefonie (90% ekranu minus wcięcie ramki, patrz
## ScreenHelpers.CONTENT_INSET_WITH_FRAME).
const IMAGE_WIDTH := 560.0
const IMAGE_HEIGHT := IMAGE_WIDTH * 9.0 / 16.0
const SECTION_TEXT_WIDTH := 620.0
const IMAGES_DIR := "res://art/instructions/"


func _ready() -> void:
	ScreenHelpers.make_background(self, "res://art/backgrounds/settings.jpg")

	var root := ScreenHelpers.make_root(self, true)
	ScreenHelpers.make_title(root, tr("Instrukcja"))

	_add_section(root, tr("Cel gry"), ["hub"], [
		tr("Grasz jako spadkobierca/spadkobierczyni wuja Walthera von Rabensteina, odbudowując rodzinną fortunę i szukając rozproszonej kolekcji 40 obrazów. Zarabiasz na plantacjach, giełdzie i wyścigach, a zdobyte pieniądze inwestujesz w licytacje na aukcjach, żeby skompletować kolekcję przed rywalami — w tym fałszerzem Vico Falsarim, który podrzuca na aukcje podróbki."),
	])
	_add_section(root, tr("Zwycięstwo i porażka"), [], [
		tr("Wygrywasz, gdy zdobędziesz wszystkie obrazy z głównego katalogu (40 w trybie standardowym, 15 w trybie łatwym). Przegrywasz, jeśli przez 60 kolejnych dni gry masz ujemną gotówkę (bankructwo) albo jeśli rywal skompletuje kolekcję pierwszy. W grze wieloosobowej (hot-seat, do 4 graczy) wygrywa ten gracz, który jako pierwszy skompletuje kolekcję."),
	])
	_add_section(root, tr("Hub i mapa świata"), ["hub_places", "travel_map"], [
		tr("Hub to ekran startowy każdej tury — w rogach widać Twoją lokalizację i datę, liczbę zebranych obrazów, termin następnej aukcji oraz gotówkę. Menu w prawym dolnym rogu ma cztery stałe przyciski: „Jedź »” (otwiera mapę świata), „Miejsca »” (rozwija podmenu lokacji), „Koniec tury »” (przesuwa kalendarz) i „Zapisz i wyjdź do menu” (zapisuje grę)."),
		tr("Przycisk „Miejsca »” pokazuje wszystkie akcje dostępne w Twojej bieżącej lokalizacji: Plantacje i Spichlerz tylko w miastach plantacyjnych, Dom aukcyjny i Galeria tylko w miastach aukcyjnych, Giełda i Rynek w Nowym Jorku i miastach aukcyjnych, Szkoła sztuki wyłącznie w Paryżu — a Wyścigi konne i Ochrona są dostępne zawsze, z każdej lokalizacji. Niedostępna tu akcja po prostu nie pokazuje się na liście, zamiast być wyszarzona."),
		tr("„Jedź »” otwiera mapę świata z 18 lokacjami — dotknij pinezkę, żeby zobaczyć czas podróży (od ok. 1,5 dnia między sąsiednimi miastami Europy do prawie miesiąca na najdłuższych trasach) i potwierdzić przyciskiem „Jedź »” na dole ekranu. Mapę można przybliżać (uszczypnięcie/kółko myszy) i przesuwać przeciąganiem. „Koniec tury »” przesuwa kalendarz o 7 dni, chyba że w tym oknie wypada zaplanowana aukcja w Twoim mieście — wtedy tura skraca się, żeby jej nie przegapić."),
	])
	_add_section(root, tr("Plantacje"), ["plantation"], [
		tr("Każde miasto plantacyjne ma własną siatkę 16×16 pól, wspólną dla wszystkich graczy i wylosowaną raz na całą grę — rzeka (niebieski pas) przecina siatkę po przekątnej. Pole kosztuje 500 M i kupujesz je, dotykając wolnego pola (ikonka „+”); kto pierwszy kupi dane pole, ten jest jego właścicielem na resztę gry. Pola leżące obok rzeki — poziomo, pionowo lub po przekątnej — dają DWA RAZY większy plon niż pola zwykłe, więc miejsce przy rzece jest najcenniejszą działką na planszy."),
		tr("Kupione, ale puste pole (goła ziemia) zasadzasz, dotykając go — obsiewa się uprawą wybraną w rozwijanej liście „Sadzić:” (Kawa, Tytoń, Herbata, Kakao, a w Ankarze i Gwatemali dodatkowo ryzykowna „Przemycana uprawa”). Jedna plantacja może uprawiać kilka różnych roślin naraz, każdą na innych polach. Pole „Robotnicy:” ustawia liczbę zatrudnionych na CAŁEJ plantacji (do 500) — każdy kosztuje 1 M dziennie, płatne automatycznie z Twojej gotówki. Plon rośnie WPROST proporcjonalnie do liczby robotników: przy 500 robotnikach dostajesz pełny plon z tabeli referencyjnej, przy 250 — połowę, przy 0 — nic, niezależnie od tego, ile masz obsianych pól."),
		tr("Poza robotnikami na wielkość zbiorów wpływają jeszcze trzy czynniki: pora roku (zimą i latem plon spada nawet do 30-40% normy, wiosną i jesienią jest najwyższy), czas od ostatnich zbiorów (plon liczy się proporcjonalnie do dni, jakie minęły) oraz sama liczba i jakość Twoich pól (pole przy rzece liczy się podwójnie). Każde miasto ma inny profil upraw — np. Ankara/Bombaj/Colombo dają dużo herbaty i mało kawy, Rio/Abidżan/Duala odwrotnie — więc opłaca się sprawdzić, co w danym mieście rośnie najlepiej."),
		tr("„Kup pompę wodną (5000 M)” to jednorazowa inwestycja na całą plantację: podnosi CAŁY jej plon o 20% i całkowicie chroni przed suszą/powodzią (bez pompy ryzyko klęski pogodowej wynosi ok. 3% na tydzień). Jeśli zabraknie Ci gotówki na wypłaty dla robotników, grozi strajk — plantacja traci wszystkie zebrane zapasy i połowę załogi; w niespokojnych regionach (m.in. Ankara, Bombaj, Colombo) to samo mogą wywołać zamieszki. Trzy takie uderzenia z rzędu (strajk lub zamieszki, liczone łącznie) kosztują całą plantację."),
		tr("„Zbierz plony” zbiera od razu wszystkie dojrzałe uprawy z tej plantacji (może być kilka naraz) i pokazuje łączną ilość. „Wyślij i sprzedaj” wysyła cały zebrany zapas do sprzedaży w Nowym Jorku. Legenda po prawej tłumaczy każdą ikonkę pola, a przycisk „Spichlerz »” prowadzi do zbiorczego magazynu wszystkich Twoich plantacji w tym mieście (opisany niżej)."),
	])
	_add_section(root, tr("Spichlerz"), ["warehouse"], [
		tr("Spichlerz zbiera w jednym miejscu plony ze WSZYSTKICH Twoich plantacji w danym mieście — każda uprawa ma własny „silos” pokazujący ilość i aktualną cenę za jednostkę. Przycisk „Wyślij i sprzedaj” pod danym silosem sprzedaje od razu cały jego zapas do Nowego Jorku po bieżącej cenie rynkowej. Towar, który zaległ w magazynie dłużej niż rok, psuje się i przepada — nie warto go magazynować w nieskończoność."),
	])
	_add_section(root, tr("Giełda"), ["stock_market"], [
		tr("Cztery „sejfy” to cztery linie żeglugowe: Lloyd (Azja), Star (Afryka), Hanse (Ameryka Południowa) i Royal (Ameryka Północna). Przy każdym widzisz aktualny kurs i liczbę posiadanych udziałów, a przyciski „Kup 10”/„Sprzedaj 10” handlują zawsze pakietami po 10 sztuk. Kursy rosną, gdy jesteś aktywny/-a na plantacjach danego regionu, a do tego codziennie lekko dryfują losowo — rzadkie krachy i hossy potrafią poruszyć wszystkie cztery kursy naraz nawet o 25-45%. Wykres pod spodem pokazuje historię kursów."),
	])
	_add_section(root, tr("Rynek"), ["market"], [
		tr("Ceny czterech towarów (plus przemycanej uprawy) zmieniają się co dzień losowo o kilka procent — wykres pokazuje ich historię. Sekcja „Kontrakty terminowe” pozwala zawrzeć umowę na dostawę 100 jednostek danej uprawy za 30 dni, po cenie ustalonej DZIŚ (z 10% premią ponad bieżącą cenę) — ta cena NIE zmienia się nawet po reformie walutowej, więc kontrakt to dobre zabezpieczenie przed nadchodzącą inflacją. Niedostarczenie towaru w terminie kosztuje karę w wysokości 20% wartości kontraktu."),
	])
	_add_section(root, tr("Dom aukcyjny"), ["auction_house"], [
		tr("Aukcje odbywają się według harmonogramu — jedno miasto i jeden dzień na raz, Hub zawsze pokazuje termin następnej. Gdy trwa aukcja w Twoim mieście, masz 20 sekund na każdą rundę licytacji: „Podbij” podnosi Twoją ofertę o 10% szacowanej wartości obrazu, „Rezygnuję” wycofuje Cię z tej rundy (pozostali obecni licytują dalej). Rywale AI — w tym fałszerz Vico Falsari — też podbijają losowo w trakcie odliczania. Część wystawionych obrazów to podróbki; wyższa eksperckość ze Szkoły sztuki daje szansę na wczesne ostrzeżenie „⚠ możliwa podróbka!” we własnej ramce, zanim zalicytujesz. Obraz trafia do kolekcji tylko wtedy, gdy naprawdę wygrasz i to nie jest podróbka — czasem trafia się też rzadki, bonusowy „ulubiony obraz wuja”, który nie liczy się do kompletu, ale daje dodatkową nagrodę pieniężną."),
	])
	_add_section(root, tr("Szkoła sztuki"), ["art_school"], [
		tr("Dostępna wyłącznie w Paryżu. „Kurs (2000 M, 28 dni)” płatny z góry, dni mijają natychmiast po zapisaniu się. Po kursie czeka mini-gra: dwa niemal identyczne obrazy obok siebie, prawdziwy i jego podróbka — trzeba wskazać, który to falsyfikat, przyciskiem „Ta jest podróbką” pod właściwym. Trafiona odpowiedź daje +15% eksperckości, nietrafiona tylko +5%. Eksperckość (widoczna jako układanka, im wyższa tym bardziej poukładana) rośnie do maksymalnie 90% i wpływa WYŁĄCZNIE na szansę wczesnego ostrzeżenia o podróbce w Domu aukcyjnym — nie na szacowaną wartość obrazu."),
	])
	_add_section(root, tr("Galeria"), ["gallery"], [
		tr("Ekran ma trzy poziomy: siatka 8 kategorii stylistycznych (każda 0-5 obrazów) → miniaturki Twoich obrazów w wybranej kategorii → duży podgląd z tytułem, autorem, rokiem i muzeum. Kategoria jest klikalna dopiero, gdy masz w niej choć jeden obraz. Przycisk w prawym dolnym rogu zawsze cofa jeden poziom wyżej (z podglądu do miniaturek, z miniaturek do kategorii, z kategorii do Huba). Im pełniejsza kolekcja, tym jaśniejsza i „żywsza” staje się sama sala — czysto kosmetyczny, ale przyjemny efekt."),
	])
	_add_section(root, tr("Ochrona"), ["security"], [
		tr("„Zatrudnij ochroniarza (5000 M)” to jednorazowa opłata, która całkowicie eliminuje ryzyko kradzieży (bez ochroniarza masz ok. 5% szans na tydzień, że ktoś ukradnie Ci obraz). Trzej gangsterzy do wynajęcia — Vito „Brzytwa”, Rosa Cień i Karl Żelazna Ręka — mają różną, zmieniającą się codziennie szansę powodzenia (widoczną przy każdym portrecie). Wybierz gangstera i rywala z rozwijanych list, potem „Wyślij gangstera (3000 M)” — animacja skoku pokaże wynik. Sukces oznacza kradzież obrazu rywalowi; porażka ma około 50% szans skończyć się złapaniem Twojego gangstera i dodatkową grzywną 2000 M, w pozostałych przypadkach tracisz tylko opłatę za wysłanie."),
	])
	_add_section(root, tr("Wyścigi konne"), ["races"], [
		tr("Sześć koni ma własne, zmieniające się codziennie kursy — im wyższy kurs, tym większa wygrana, ale mniejsza szansa na trafienie. Wybierz konia z listy, ustaw kwotę zakładu (od 100 do 50 000 M) i naciśnij „Postaw zakład” — po ok. 30-sekundowej animacji wyścigu wygrana to zakład pomnożony przez kurs wybranego konia, przegrana zabiera cały zakład. Po każdym zakładzie obowiązuje 7-dniowy okres odnowienia, zanim będzie można postawić kolejny."),
	])
	_add_section(root, tr("Reformy walutowe i inflacja"), [], [
		tr("Kurs dolara rośnie z czasem; gdy przekroczy próg 14,0, Hub ostrzega o zbliżającej się reformie walutowej. Każda reforma gwałtownie przelicza gotówkę wszystkich graczy w stosunku 5:1 — kontrakty terminowe zawarte przed reformą zachowują swoją pierwotną cenę, więc doświadczeni gracze traktują je jako zabezpieczenie."),
	])
	_add_section(root, tr("Nowy Rok"), [], [
		tr("Na przełomie roku w grze najpierw pojawia się animowana Noworoczna Loteria — jeden zwycięzca spośród wszystkich graczy losowo otrzymuje gotówkę, a czasem także rzadki, autentyczny obraz z głównego katalogu. Zaraz po niej pokazuje się Podsumowanie roku z przeglądem Twoich wyników."),
	])
	_add_section(root, tr("Gra wieloosobowa"), [], [
		tr("Do 4 osób może grać na jednym urządzeniu na zmianę (hot-seat) — pasek stanu zawsze pokazuje, czyja jest tura. Siatki plantacji są wspólne dla wszystkich graczy: kto pierwszy zajmie dobre pole przy rzece, ten ma przewagę."),
	])
	_add_section(root, tr("Ustawienia"), ["settings"], [
		tr("W Ustawieniach zmienisz język interfejsu (polski/angielski/niemiecki) i wyciszysz muzykę. Grę można w każdej chwili zapisać i wyjść z poziomu Huba."),
	])

	ScreenHelpers.make_button(root, "« Powrót", func(): SceneRouter.goto_hub())


func _add_section(container: VBoxContainer, title_text: String, image_names: Array, paragraphs: Array) -> void:
	var section := VBoxContainer.new()
	section.alignment = BoxContainer.ALIGNMENT_CENTER
	section.add_theme_constant_override("separation", 10)
	container.add_child(section)

	var header := Label.new()
	header.text = title_text
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 28)
	header.add_theme_color_override("font_color", ScreenHelpers.COLOR_GOLD_BRIGHT)
	header.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	header.add_theme_constant_override("shadow_offset_x", 1)
	header.add_theme_constant_override("shadow_offset_y", 1)
	section.add_child(header)

	for image_name in image_names:
		_add_screenshot(section, IMAGES_DIR + image_name + ".jpg")

	for paragraph in paragraphs:
		var body := ScreenHelpers.make_label(section, paragraph)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD
		body.custom_minimum_size = Vector2(SECTION_TEXT_WIDTH, 0)


## Prawdziwy zrzut ekranu z działającej gry (nie grafika z Leonardo.ai) —
## przechwycony narzędziem deweloperskim (patrz historia commitów), w tym
## samym stylu Art Deco co reszta gry, bo to po prostu ta sama gra. Rama
## (art/icons/frame.png, używana dla obrazów w Domu aukcyjnym/Galerii) tutaj
## NIE pasuje — to zrzut interfejsu, nie obraz z kolekcji — więc zwykła
## złota obwódka (StyleBoxFlat), spójna z resztą oprawionych skrzynek w grze.
func _add_screenshot(container: VBoxContainer, path: String) -> void:
	var frame := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.05, 0.4)
	style.border_color = ScreenHelpers.COLOR_GOLD
	style.set_border_width_all(3)
	style.set_corner_radius_all(4)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	frame.add_theme_stylebox_override("panel", style)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	container.add_child(frame)

	var rect := TextureRect.new()
	rect.custom_minimum_size = Vector2(IMAGE_WIDTH, IMAGE_HEIGHT)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(path):
		rect.texture = load(path)
	frame.add_child(rect)
