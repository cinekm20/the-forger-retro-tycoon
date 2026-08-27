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

## Zrzuty ekranu (game/art/instructions/*.jpg) — 1000×375 (proporcje
## 1920×720), przechwycone bezpośrednio z działającej gry (nie generowane w
## Leonardo.ai), więc zawsze wiernie pokazują aktualny wygląd/rozmieszczenie
## przycisków. Przechwycone celowo SZERZEJ niż domyślna rozdzielczość gry
## (1280×720) — przy standardowej szerokości legenda Plantacji i rząd cen na
## Rynku wychodziły poza prawą krawędź ekranu (zgłoszone przez użytkownika,
## „odcięte są po prawej stronie”); silnik w trybie stretch/aspect=expand
## daje ekranowi WIĘCEJ faktycznej szerokości logicznej przy szerszym oknie
## (bez zmiany referencyjnej wysokości 720), więc dokładnie to samo dzieje
## się realnie na szerokim telefonie/tablecie w orientacji poziomej — tu
## tylko świadomie wymuszone przy przechwytywaniu, żeby żaden zrzut nie był
## ucięty. IMAGE_WIDTH: zgłoszone przez użytkownika "trochę większe te
## screeny muszą być" — podniesiony z 600 do 900 (ramka ma miejsca aż
## nadto: 0.9 ekranu minus 2×CONTENT_INSET_WITH_FRAME to przy referencyjnej
## szerokości 1280 wciąż ponad 1150px zapasu).
const IMAGE_WIDTH := 900.0
const IMAGE_HEIGHT := IMAGE_WIDTH * 720.0 / 1920.0
const SECTION_TEXT_WIDTH := 620.0
const IMAGES_DIR := "res://art/instructions/"

## Legendy (ikonka + rozwinięty opis) — zgłoszone przez użytkownika: "tak jak
## w plantacji jest legenda, to tam też powinna być z rozwinięciem co i jak,
## tak samo inne miejsca". Ikonki to te SAME klasy co w prawdziwej grze
## (PlantationTileIcon.gd/StatIcon.gd/MapPin.gd — natywnie rysowane, patrz
## uzasadnienie w tych plikach), nie osobne, zduplikowane rysunki — więc
## legenda tu zawsze wygląda dokładnie tak samo jak w grze.
const PlantationTileIconScript := preload("res://scripts/ui/PlantationTileIcon.gd")
const StatIconScript := preload("res://scripts/ui/StatIcon.gd")
const MapPinScript := preload("res://scripts/ui/MapPin.gd")
## Tylko żeby odczytać TYPE_PIN_COLORS/CURRENT_CITY_PIN_COLOR (stałe, bez
## efektów ubocznych) — preload NIE tworzy instancji sceny, tylko ładuje
## definicję klasy, więc to bezpieczne mimo że to skrypt pełnego ekranu.
const TravelMapScript := preload("res://scenes/travel_map/TravelMap.gd")
const LEGEND_TILE_ICON_SIZE := 28.0


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
	var hub_section := _add_section(root, tr("Hub i mapa świata"), ["hub_places", "travel_map"], [
		tr("Hub to ekran startowy każdej tury — w rogach widać Twoją lokalizację i datę, liczbę zebranych obrazów, termin następnej aukcji oraz gotówkę. Menu w prawym dolnym rogu ma cztery stałe przyciski: „Jedź »” (otwiera mapę świata), „Miejsca »” (rozwija podmenu lokacji), „Koniec tury »” (przesuwa kalendarz) i „Zapisz i wyjdź do menu” (zapisuje grę)."),
		tr("Przycisk „Miejsca »” pokazuje wszystkie akcje dostępne w Twojej bieżącej lokalizacji: Plantacje i Spichlerz tylko w miastach plantacyjnych, Dom aukcyjny i Galeria tylko w miastach aukcyjnych, Giełda i Rynek w Nowym Jorku i miastach aukcyjnych, Szkoła sztuki wyłącznie w Paryżu — a Wyścigi konne i Ochrona są dostępne zawsze, z każdej lokalizacji. Niedostępna tu akcja po prostu nie pokazuje się na liście, zamiast być wyszarzona."),
		tr("„Jedź »” otwiera mapę świata z 18 lokacjami — dotknij pinezkę, żeby zobaczyć czas podróży (od ok. 1,5 dnia między sąsiednimi miastami Europy do prawie miesiąca na najdłuższych trasach) i potwierdzić przyciskiem „Jedź »” na dole ekranu. Mapę można przybliżać (uszczypnięcie/kółko myszy) i przesuwać przeciąganiem. „Koniec tury »” przesuwa kalendarz o 7 dni, chyba że w tym oknie wypada zaplanowana aukcja w Twoim mieście — wtedy tura skraca się, żeby jej nie przegapić."),
	])
	_add_legend(hub_section, tr("Legenda: ikony statystyk"), [
		{"icon": StatIconScript.new(StatIconScript.Kind.MONEY), "text": tr("Złota moneta — Twoja gotówka.")},
		{"icon": StatIconScript.new(StatIconScript.Kind.DATE), "text": tr("Kalendarzyk — aktualna data w grze.")},
		{"icon": StatIconScript.new(StatIconScript.Kind.EXPERTISE), "text": tr("Lupa — Twoja eksperckość (patrz sekcja „Szkoła sztuki” niżej).")},
	])
	_add_legend(hub_section, tr("Legenda: kolory pinezek na mapie"), [
		{"icon": _make_pin(TravelMapScript.TYPE_PIN_COLORS["plantation"]), "text": tr("Miasto plantacyjne — dostępne tu Plantacje i Spichlerz.")},
		{"icon": _make_pin(TravelMapScript.TYPE_PIN_COLORS["auction"]), "text": tr("Miasto aukcyjne — dostępny tu Dom aukcyjny i Galeria (a w Paryżu dodatkowo Szkoła sztuki).")},
		{"icon": _make_pin(TravelMapScript.TYPE_PIN_COLORS["hub"]), "text": tr("Nowy Jork — jedyne miasto typu „hub”, dostępne tu Giełda i Rynek (razem z miastami aukcyjnymi).")},
		{"icon": _make_pin(TravelMapScript.CURRENT_CITY_PIN_COLOR), "text": tr("Twoja aktualna lokalizacja.")},
	])
	var plantation_section := _add_section(root, tr("Plantacje"), ["plantation"], [
		tr("Każde miasto plantacyjne ma własną siatkę 16×16 pól, wspólną dla wszystkich graczy i wylosowaną raz na całą grę — rzeka (niebieski pas) przecina siatkę po przekątnej. Pole kosztuje 500 M i kupujesz je, dotykając wolnego pola (ikonka „+”); kto pierwszy kupi dane pole, ten jest jego właścicielem na resztę gry. Pola leżące obok rzeki — poziomo, pionowo lub po przekątnej — dają DWA RAZY większy plon niż pola zwykłe, więc miejsce przy rzece jest najcenniejszą działką na planszy."),
		tr("Kupione, ale puste pole (goła ziemia) zasadzasz, dotykając go — obsiewa się uprawą wybraną w rozwijanej liście „Sadzić:” (Kawa, Tytoń, Herbata, Kakao, a w Ankarze i Gwatemali dodatkowo ryzykowna „Przemycana uprawa”). Jedna plantacja może uprawiać kilka różnych roślin naraz, każdą na innych polach. Pole „Robotnicy:” ustawia liczbę zatrudnionych na CAŁEJ plantacji (do 500) — każdy kosztuje 1 M dziennie, płatne automatycznie z Twojej gotówki. Plon rośnie WPROST proporcjonalnie do liczby robotników: przy 500 robotnikach dostajesz pełny plon z tabeli referencyjnej, przy 250 — połowę, przy 0 — nic, niezależnie od tego, ile masz obsianych pól."),
		tr("Poza robotnikami na wielkość zbiorów wpływają jeszcze trzy czynniki: pora roku (zimą i latem plon spada nawet do 30-40% normy, wiosną i jesienią jest najwyższy), czas od ostatnich zbiorów (plon liczy się proporcjonalnie do dni, jakie minęły) oraz sama liczba i jakość Twoich pól (pole przy rzece liczy się podwójnie). Każde miasto ma inny profil upraw — np. Ankara/Bombaj/Colombo dają dużo herbaty i mało kawy, Rio/Abidżan/Duala odwrotnie — więc opłaca się sprawdzić, co w danym mieście rośnie najlepiej."),
		tr("„Kup pompę wodną (5000 M)” to jednorazowa inwestycja na całą plantację: podnosi CAŁY jej plon o 20% i całkowicie chroni przed suszą/powodzią (bez pompy ryzyko klęski pogodowej wynosi ok. 3% na tydzień). Jeśli zabraknie Ci gotówki na wypłaty dla robotników, grozi strajk — plantacja traci wszystkie zebrane zapasy i połowę załogi; w niespokojnych regionach (m.in. Ankara, Bombaj, Colombo) to samo mogą wywołać zamieszki. Trzy takie uderzenia z rzędu (strajk lub zamieszki, liczone łącznie) kosztują całą plantację."),
		tr("„Zbierz plony” zbiera od razu wszystkie dojrzałe uprawy z tej plantacji (może być kilka naraz) i pokazuje łączną ilość. „Wyślij i sprzedaj” wysyła cały zebrany zapas do sprzedaży w Nowym Jorku. Przycisk „Spichlerz »” prowadzi do zbiorczego magazynu wszystkich Twoich plantacji w tym mieście (opisany niżej). Poniżej — pełna legenda wyglądu pól."),
	])
	_add_legend(plantation_section, tr("Legenda: pola na siatce"), [
		{"icon": _make_tile_icon(PlantationTileIconScript.Kind.RIVER), "text": tr("Rzeka — niedostępna do kupienia; pola obok niej (poziomo, pionowo lub po przekątnej) dają dwa razy większy plon.")},
		{"icon": _make_tile_icon(PlantationTileIconScript.Kind.VACANT), "text": tr("Wolne pole — kosztuje 500 M, dotknij, żeby je kupić.")},
		{"icon": _make_tile_icon(PlantationTileIconScript.Kind.SOIL), "text": tr("Twoje pole, jeszcze niezasiane — dotknij, żeby zasiać uprawę wybraną w liście „Sadzić:”.")},
		{"icon": _make_tile_icon(PlantationTileIconScript.Kind.SOIL, true), "text": tr("Twoje pole sąsiadujące z rzeką (jasna obwódka) — po zasianiu da dwa razy większy plon niż zwykłe pole.")},
		{"icon": _make_tile_icon(PlantationTileIconScript.Kind.CROP, false, "coffee"), "text": tr("Obsiane pole — kolor rośliny pokazuje uprawę (tu: kawa); z czasem wygląd „dojrzewa”, czysto kosmetycznie, bez wpływu na plon.")},
		{"icon": _make_tile_icon(PlantationTileIconScript.Kind.CROP, false, "tobacco"), "text": tr("Tytoń")},
		{"icon": _make_tile_icon(PlantationTileIconScript.Kind.CROP, false, "tea"), "text": tr("Herbata")},
		{"icon": _make_tile_icon(PlantationTileIconScript.Kind.CROP, false, "cocoa"), "text": tr("Kakao")},
		{"icon": _make_tile_icon(PlantationTileIconScript.Kind.CROP, false, "contraband"), "text": tr("Przemycana uprawa — dostępna tylko w Ankarze i Gwatemali; wyższa cena sprzedaży, ale ryzyko konfiskaty.")},
		{"icon": _make_tile_icon(PlantationTileIconScript.Kind.OWNED_BY_OTHER), "text": tr("Tylko w grze wieloosobowej: pole zajęte przez innego gracza (kolor + inicjał imienia) — nie da się go kupić ani na nim sadzić.")},
	])
	_add_section(root, tr("Spichlerz"), ["warehouse"], [
		tr("Spichlerz to ekran widoczny tylko w mieście plantacyjnym — zbiera w jednym miejscu zebrane plony ze WSZYSTKICH Twoich plantacji w tym mieście, nie tylko z jednej. Pięć „silosów” (Kawa, Tytoń, Herbata, Kakao i — jeśli akurat masz coś zebrane — Przemycana uprawa) pokazuje ilość zapasów i aktualną cenę sprzedaży za jednostkę; poziom wypełnienia paska w silosie rośnie wraz z zapasami (czysto wizualne, bez twardego limitu pojemności)."),
		tr("Przycisk „Wyślij i sprzedaj” pod danym silosem sprzedaje NATYCHMIAST cały jego zapas do magazynu w Nowym Jorku po dzisiejszej cenie rynkowej (tej samej, którą widzisz też na ekranie Rynek) — nie da się sprzedać tylko części zapasu. Towar, który zaległ w magazynie dłużej niż rok (360 dni gry), psuje się i przepada bez ostrzeżenia poza kartą wydarzenia informującą o stracie — regularne wysyłanie zapasów jest więc ważniejsze niż czekanie na lepszą cenę."),
	])
	_add_section(root, tr("Giełda"), ["stock_market"], [
		tr("Cztery „sejfy” to cztery fikcyjne linie żeglugowe, każda przypisana do regionu świata: Lloyd (Azja), Star (Afryka), Hanse (Ameryka Południowa) i Royal (Ameryka Północna). Pod każdym widzisz aktualny kurs (w markach za akcję) i liczbę udziałów, które już posiadasz. Przyciski „Kup 10”/„Sprzedaj 10” zawsze handlują pakietem po 10 sztuk naraz, po aktualnym kursie — nie da się kupić/sprzedać innej liczby."),
		tr("Kursy nie są przypadkowe: rosną, gdy jesteś aktywny/-a na plantacjach w regionie danej linii (kupujesz pola, zatrudniasz robotników), a do tego każdego dnia lekko dryfują losowo o kilka procent w górę lub w dół. Raz na jakiś czas (rzadko, ok. 2% szans na tydzień) zdarza się krach albo hossa — jednorazowa, gwałtowna zmiana kursu WSZYSTKICH czterech linii naraz o 25-45%, w tę samą stronę. Wykres pod przyciskami pokazuje historię wszystkich czterech kursów w czasie, z kolorową legendą pod nim."),
	])
	_add_section(root, tr("Rynek"), ["market"], [
		tr("Górny wiersz pokazuje bieżącą cenę sprzedaży każdego z czterech towarów (plus przemycanej uprawy, jeśli akurat coś zebrałeś/-aś) w markach za jednostkę — dokładnie tę samą cenę, jaką dostaniesz sprzedając w Spichlerzu. Ceny zmieniają się co dzień losowo o kilka procent; wykres z kolorową legendą pod spodem pokazuje ich historię, żeby ocenić, czy dziś jest dobry moment na sprzedaż, czy lepiej poczekać."),
		tr("Sekcja „Kontrakty terminowe” to osobny mechanizm: przycisk „Zawrzyj: [uprawa]” zobowiązuje Cię do dostarczenia 100 jednostek tej uprawy za 30 dni, po cenie ustalonej DZIŚ (z 10% premią ponad bieżącą cenę rynkową) — ta cena jest zamrożona i NIE zmienia się nawet po reformie walutowej, więc to dobre zabezpieczenie przed nadchodzącą inflacją. Aktywne kontrakty widać na liście pod przyciskami. Niedostarczenie w terminie kosztuje karę w wysokości 20% wartości kontraktu."),
	])
	_add_section(root, tr("Dom aukcyjny"), ["auction_house"], [
		tr("Aukcje odbywają się według harmonogramu — jedno miasto i jeden dzień na raz, losowane z wyprzedzeniem 4-12 dni. Skrzynka w lewym górnym rogu zawsze pokazuje termin i miasto następnej aukcji; jeśli wejdziesz na ten ekran poza tym terminem, zobaczysz tylko ten komunikat i przycisk powrotu — licytacja jeszcze się nie zaczęła."),
		tr("Gdy aukcja trwa w Twoim mieście, na środku widać obraz w ramie z szacowaną wartością i pasek 20-sekundowego licznika na każdą rundę. Każdy fizycznie obecny gracz (do 4 w hot-seat) ma WŁASNĄ ramkę po bokach ekranu z przyciskami „Podbij” (podnosi Twoją ofertę o 10% szacowanej wartości obrazu) i „Rezygnuję” (wycofuje Cię z tej rundy — pozostali licytują dalej). Rywale AI, w tym fałszerz Vico Falsari, też podbijają losowo w trakcie odliczania — czasem tuż przed końcem licznika."),
		tr("Część wystawionych obrazów to podróbki — wygrana licytacja fałszywki NIE dodaje obrazu do kolekcji, mimo zapłaty. Wyższa eksperckość ze Szkoły sztuki daje szansę na wczesne, własne ostrzeżenie „⚠ możliwa podróbka!” widoczne w Twojej ramce, zanim zalicytujesz — to jedyny efekt eksperckości, nie wpływa na szacowaną wartość. Po rozstrzygnięciu rundy pojawia się przycisk „Galeria »” (jeśli naprawdę wygrałeś obraz do kolekcji) i „« Powrót”. Czasem zamiast zwykłego obrazu trafia się rzadki, bonusowy „ulubiony obraz wuja” — nie liczy się do kompletu 40 obrazów, ale daje dodatkową nagrodę pieniężną."),
	])
	_add_section(root, tr("Szkoła sztuki"), ["art_school"], [
		tr("Dostępna wyłącznie w Paryżu (Hub nie pokaże tej opcji nigdzie indziej). Przycisk „Kurs (2000 M, 28 dni)” w prawym dolnym rogu pobiera opłatę z góry i od razu przesuwa kalendarz o 28 dni — blokuje się (staje się nieaktywny), gdy Twoja eksperckość osiągnie maksimum 90%, żeby nie płacić za kurs, który już nic nie da."),
		tr("Po opłaceniu kursu ekran pokazuje mini-grę: dwa niemal identyczne obrazy obok siebie — jeden prawdziwy, drugi jego podróbka. Trzeba wskazać fałszywkę przyciskiem „Ta jest podróbką” pod właściwym obrazem. Trafiona odpowiedź daje +15% eksperckości, nietrafiona tylko +5% — więc nawet pomyłka trochę pomaga, ale dużo mniej niż trafne rozpoznanie."),
		tr("Eksperckość pokazana jest jako układanka pod obrazem centralnym — im wyższa wartość procentowa, tym bardziej „poukładana” wygląda (czysto kosmetyczny wskaźnik postępu). Wpływa WYŁĄCZNIE na szansę wczesnego ostrzeżenia o podróbce w Domu aukcyjnym — nigdy na szacowaną wartość obrazu ani na ceny."),
	])
	_add_section(root, tr("Galeria"), ["gallery"], [
		tr("Ekran główny pokazuje siatkę 8 kategorii stylistycznych z licznikiem X/5 obrazów zebranych w każdej. Kategoria staje się klikalna dopiero, gdy masz w niej choć jeden obraz — puste kategorie są widoczne, ale nieaktywne, żeby od razu było widać, ile jeszcze zostało do zdobycia w każdym stylu."),
		tr("Dotknięcie odblokowanej kategorii pokazuje miniaturki Twoich obrazów w tym stylu; dotknięcie miniaturki otwiera duży podgląd z pełnym opisem — tytułem, autorem, rokiem powstania i muzeum. Przycisk w prawym dolnym rogu zawsze cofa dokładnie jeden poziom wyżej (z podglądu do miniaturek, z miniaturek do kategorii, z kategorii do Huba) — nigdy nie przeskakuje od razu do Huba z głębszego poziomu."),
		tr("Im pełniejsza Twoja kolekcja (0 do 40 obrazów), tym jaśniejsza i bardziej „żywa” staje się cała sala galerii oraz głośniejsza podkładająca ją muzyka — czysto kosmetyczny, ale satysfakcjonujący sygnał postępu w stronę zwycięstwa."),
	])
	_add_section(root, tr("Ochrona"), ["security"], [
		tr("Górna część ekranu pokazuje Twój aktualny status ochrony: bez ochroniarza masz ok. 5% szans na tydzień, że ktoś ukradnie Ci obraz z kolekcji. „Zatrudnij ochroniarza (5000 M)” to jednorazowa opłata, która całkowicie eliminuje to ryzyko na resztę gry — przycisk blokuje się, gdy już go masz."),
		tr("Sekcja „Gangsterzy” pokazuje trzech najemników do wyboru — Vito „Brzytwa”, Rosa Cień i Karl Żelazna Ręka — każdy z inną szansą powodzenia napadu, widoczną przy portrecie i zmieniającą się codziennie (tak jak kursy koni). Wybierz gangstera i rywala AI z dwóch rozwijanych list na dole, potem „Wyślij gangstera (3000 M)” — animacja skoku pokaże wynik próby."),
		tr("Sukces oznacza kradzież jednego obrazu wybranemu rywalowi (liczba obrazów każdego rywala widoczna w sekcji „Rywale” powyżej). Nieudana próba ma ok. 50% szans zakończyć się złapaniem Twojego gangstera — wtedy płacisz dodatkową grzywnę 2000 M; w pozostałych przypadkach tracisz tylko opłatę za wysłanie, bez dalszych konsekwencji."),
	])
	_add_section(root, tr("Wyścigi konne"), ["races"], [
		tr("Sześć koni ma własne portrety i kursy (np. ×2,0 do ×16,0 w typowym układzie, w praktyce od 1,3 do 20,0) — kursy zmieniają się codziennie, dryfując losowo, tak jak ceny na Giełdzie. Im wyższy kurs przy koniu, tym większa potencjalna wygrana, ale mniejsza szansa, że akurat on wygra wyścig."),
		tr("Wybierz konia z rozwijanej listy, ustaw kwotę zakładu (od 100 do 50 000 M, krokiem po 100) i naciśnij „Postaw zakład” — rusza ok. 30-sekundowa animacja wyścigu z przewijanym torem. Wygrana wypłaca zakład pomnożony przez kurs wybranego konia; przegrana zabiera cały zakład bez zwrotu. Po każdym postawionym zakładzie obowiązuje 7-dniowy okres odnowienia (widoczny jako odliczanie pod przyciskiem), zanim będzie można postawić kolejny."),
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


func _add_section(container: VBoxContainer, title_text: String, image_names: Array, paragraphs: Array) -> VBoxContainer:
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

	return section


## Oprawiona skrzynka (ScreenHelpers.make_framed_box, ta sama co ramka pod
## wykresem w Market.gd/StockMarket.gd) z wierszami ikonka+opis — zgłoszone
## przez użytkownika: instrukcja ma mieć PRAWDZIWE legendy (ikonka + rozwinięty
## tekst), nie tylko prozę. `rows`: Array of {"icon": Control, "text": String}.
## Ikonka dostaje własny, stały "slot" (CenterContainer) zamiast wymuszania
## jednego rozmiaru na WSZYSTKIE ikonki — PlantationTileIcon/StatIcon/MapPin
## mają różne naturalne proporcje (kwadratowe kafelki vs. pinezka), więc
## wymuszony wspólny rozmiar zniekształcałby część z nich.
const LEGEND_ICON_SLOT := 40.0

func _add_legend(container: VBoxContainer, legend_title: String, rows: Array) -> void:
	var box := ScreenHelpers.make_framed_box(container)

	var heading := Label.new()
	heading.text = legend_title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 24)
	heading.add_theme_color_override("font_color", ScreenHelpers.COLOR_GOLD_BRIGHT)
	box.add_child(heading)

	for row in rows:
		var hrow := HBoxContainer.new()
		hrow.add_theme_constant_override("separation", 12)
		box.add_child(hrow)

		var icon_slot := CenterContainer.new()
		icon_slot.custom_minimum_size = Vector2(LEGEND_ICON_SLOT, LEGEND_ICON_SLOT)
		icon_slot.add_child(row["icon"])
		hrow.add_child(icon_slot)

		var label := ScreenHelpers.make_label(hrow, row["text"])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.custom_minimum_size = Vector2(SECTION_TEXT_WIDTH - LEGEND_ICON_SLOT - 12.0, 0)


func _make_tile_icon(kind: int, river_adjacent: bool = false, crop: String = "") -> Control:
	var icon: Control = PlantationTileIconScript.new()
	icon.custom_minimum_size = Vector2(LEGEND_TILE_ICON_SIZE, LEGEND_TILE_ICON_SIZE)
	icon.kind = kind
	icon.river_adjacent = river_adjacent
	icon.crop = crop
	return icon


func _make_pin(color: Color) -> Control:
	var pin: Control = MapPinScript.new()
	pin.pin_color = color
	return pin


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
