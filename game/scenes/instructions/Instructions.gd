extends Control
## Ekran instrukcji — pełny podręcznik mechanik gry, jedno wspólne źródło
## prawdy zamiast rozproszonych wskazówek. Dostępny z każdego głównego
## ekranu nawigacyjnego przez przycisk „?” w prawym górnym rogu
## (ScreenHelpers.make_instructions_button). Treść to własna, skrócona
## redakcja oparta na docs/GDD.md, docs/DODATKOWE_MECHANIKI.md i
## docs/MECHANIKI_EKONOMICZNE.md — nie przedruk żadnego z tych dokumentów.
## Zawiera WYŁĄCZNIE ekrany nawigacyjne (zgłoszone przez użytkownika) — bez
## modali/animacji (karty wydarzeń, animacja podróży, ekran zakończenia,
## Noworoczna Loteria mają własny, samowyjaśniający się kontekst na ekranie).

## Stała szerokość zawijania tekstu — ten sam patent co
## Ending.gd::NARRATIVE_LABEL_WIDTH (autowrap bez ograniczenia szerokości nic
## nie daje, patrz komentarz tam), tu nieco szerzej (920 vs 900), bo sekcje
## instrukcji są liczniejsze i krótsze niż akapity zakończenia gry.
const SECTION_TEXT_WIDTH := 920.0


func _ready() -> void:
	ScreenHelpers.make_background(self, "res://art/backgrounds/settings.jpg")

	var root := ScreenHelpers.make_root(self, false)
	root.alignment = BoxContainer.ALIGNMENT_BEGIN
	ScreenHelpers.make_title(root, tr("Instrukcja"))

	## ScrollContainer własny (nie z make_root, który go nie daje przy
	## use_menu_frame=false — patrz screen_helpers.gd) — TEN ekran, w
	## przeciwieństwie do reszty "flat" ekranów, ma z założenia więcej treści
	## niż mieści się na jednym widoku (pełny podręcznik wszystkich mechanik).
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var sections := VBoxContainer.new()
	sections.alignment = BoxContainer.ALIGNMENT_CENTER
	sections.add_theme_constant_override("separation", 26)
	scroll.add_child(sections)

	_add_section(sections, tr("Cel gry"), tr("Grasz jako spadkobierca/spadkobierczyni wuja Walthera von Rabensteina, odbudowując rodzinną fortunę i szukając rozproszonej kolekcji 40 obrazów. Zarabiasz na plantacjach, giełdzie i wyścigach, a zdobyte pieniądze inwestujesz w licytacje na aukcjach, żeby skompletować kolekcję przed rywalami — w tym fałszerzem Vico Falsarim, który podrzuca na aukcje podróbki."))
	_add_section(sections, tr("Zwycięstwo i porażka"), tr("Wygrywasz, gdy zdobędziesz wszystkie obrazy z głównego katalogu (40 w trybie standardowym, 15 w trybie łatwym). Przegrywasz, jeśli przez 60 kolejnych dni gry masz ujemną gotówkę (bankructwo) albo jeśli rywal skompletuje kolekcję pierwszy. W grze wieloosobowej (hot-seat, do 4 graczy) wygrywa ten gracz, który jako pierwszy skompletuje kolekcję."))
	_add_section(sections, tr("Hub i mapa świata"), tr("Hub to ekran startowy każdej tury — pokazuje Twoją lokalizację, datę i gotówkę oraz menu z dostępnymi akcjami (część z nich, np. Plantacje czy Dom aukcyjny, widać tylko w odpowiednim typie miasta). Przycisk „Jedź »” otwiera mapę świata z klikalnymi pinezkami miast — dotknij pinezkę, żeby zobaczyć czas podróży i potwierdzić wyjazd. „Koniec tury »” przesuwa kalendarz o 7 dni (albo mniej, jeśli w tym czasie wypada zaplanowana aukcja w Twoim mieście)."))
	_add_section(sections, tr("Plantacje"), tr("Każde miasto plantacyjne ma własną siatkę pól 16×16 ze wspólną, wylosowaną raz na grę rzeką — pola leżące obok rzeki (poziomo, pionowo lub po przekątnej) dają podwójny plon. Siatka jest współdzielona między wszystkimi graczami: kto pierwszy kupi pole, ten jest jego właścicielem. Kup pola, zatrudnij robotników i zbieraj plony — wydajność zależy od pory roku, a plantacje bez pompy wodnej są narażone na suszę/powódź. W Ankarze i Gwatemali dostępna jest dodatkowo ryzykowna, „przemycana” uprawa. Jeśli zabraknie Ci gotówki na wypłaty, grozi strajk (utrata zapasów i połowy załogi), a w niespokojnych regionach — także zamieszki; trzy takie uderzenia z rzędu kosztują całą plantację."))
	_add_section(sections, tr("Spichlerz"), tr("Spichlerz to zbiorczy magazyn zebranych plonów ze wszystkich Twoich plantacji w danym mieście. Stąd wysyłasz towar do sprzedaży — koszt transportu zależy od miasta i celu (Londyn albo Nowy Jork). Towar, który zaległ w magazynie dłużej niż rok, psuje się i przepada."))
	_add_section(sections, tr("Giełda"), tr("Na giełdzie kupujesz i sprzedajesz akcje czterech linii żeglugowych: Lloyd (Azja), Star (Afryka), Hanse (Ameryka Południowa) i Royal (Ameryka Północna). Twoja aktywność na plantacjach danego regionu podbija kurs odpowiedniej linii, a rzadkie krachy i hossy potrafią zmienić kursy wszystkich czterech naraz. Giełda oferuje też kontrakty terminowe — zobowiązujesz się dostarczyć towar w przyszłości po dziś ustalonej cenie (z premią), co chroni przed reformą walutową, ale niedostarczenie towaru w terminie kosztuje karę umowną."))
	_add_section(sections, tr("Rynek"), tr("Rynek to miejsce bieżącej sprzedaży towarów po aktualnych, zmieniających się cenach — wykres pokazuje historię cen każdej uprawy. W przeciwieństwie do kontraktów terminowych z Giełdy, sprzedaż na Rynku jest natychmiastowa, ale po cenie dnia, bez gwarancji."))
	_add_section(sections, tr("Dom aukcyjny"), tr("Aukcje odbywają się w miastach aukcyjnych według harmonogramu — Hub pokazuje termin następnej. Licytujesz przeciw trzem rywalom AI, w tym Vico Falsariemu, w rundach z 20-sekundowym limitem czasu. Część wystawionych obrazów to podróbki — wyższa eksperckość (patrz Szkoła sztuki) zwiększa szansę na wczesne ostrzeżenie, choć nie ujawnia wprost wartości obrazu."))
	_add_section(sections, tr("Szkoła sztuki"), tr("Dostępna wyłącznie w Paryżu. Kurs trwa 28 dni i podnosi Twoją eksperckość — im wyższa, tym większa szansa na wykrycie fałszywki na aukcji, zanim zalicytujesz."))
	_add_section(sections, tr("Galeria"), tr("Galeria pokazuje Twoją kolekcję podzieloną na 8 kategorii po 5 obrazów (40 łącznie) oraz to, co brakuje. Poza głównym katalogiem na aukcjach rzadko trafiają się też 3 bonusowe, autentyczne obrazy „ulubione wuja” — nie liczą się do kompletu, ale dają dodatkową nagrodę pieniężną."))
	_add_section(sections, tr("Ochrona"), tr("Twoja kolekcja może paść ofiarą kradzieży — cotygodniowe ryzyko rośnie bez ochroniarza, którego możesz wynająć na tym ekranie. Możesz też wysłać własnego gangstera po obraz rywala: wybierz jednego z trzech dostępnych, a animacja skoku pokaże wynik próby (ustalony wcześniej na podstawie dryfującej dziennie szansy powodzenia). Nieudana próba niesie ryzyko złapania Twojego gangstera i dodatkowej grzywny."))
	_add_section(sections, tr("Wyścigi konne"), tr("Obstawiasz konie o kursach zmieniających się z dnia na dzień (od 1,3 do 20,0) — im wyższy kurs, tym większa wygrana przy trafieniu, ale mniejsza szansa. Po obstawieniu danego konia obowiązuje 7-dniowy okres odnowienia."))
	_add_section(sections, tr("Reformy walutowe i inflacja"), tr("Kurs dolara rośnie z czasem; gdy przekroczy próg 14,0, Hub ostrzega o zbliżającej się reformie walutowej. Każda reforma gwałtownie przelicza gotówkę wszystkich graczy w stosunku 5:1 — kontrakty terminowe zawarte przed reformą zachowują swoją pierwotną cenę, więc doświadczeni gracze traktują je jako zabezpieczenie."))
	_add_section(sections, tr("Nowy Rok"), tr("Na przełomie roku w grze najpierw pojawia się animowana Noworoczna Loteria — jeden zwycięzca spośród wszystkich graczy losowo otrzymuje gotówkę, a czasem także rzadki, autentyczny obraz z głównego katalogu. Zaraz po niej pokazuje się Podsumowanie roku z przeglądem Twoich wyników."))
	_add_section(sections, tr("Gra wieloosobowa"), tr("Do 4 osób może grać na jednym urządzeniu na zmianę (hot-seat) — pasek stanu zawsze pokazuje, czyja jest tura. Siatki plantacji są wspólne dla wszystkich graczy: kto pierwszy zajmie dobre pole przy rzece, ten ma przewagę."))
	_add_section(sections, tr("Ustawienia"), tr("W Ustawieniach zmienisz język interfejsu (polski/angielski/niemiecki) i wyciszysz muzykę. Grę można w każdej chwili zapisać i wyjść z poziomu Huba."))

	## Ozdobna skrzynka Art Deco w prawym dolnym rogu, TA SAMA co wszędzie
	## indziej (ScreenHelpers.make_boxed_back_button) — zawsze wraca do Huba,
	## tak jak każdy inny generyczny przycisk powrotu w tej grze.
	ScreenHelpers.make_boxed_back_button(self)


func _add_section(container: VBoxContainer, title_text: String, body_text: String) -> void:
	var section := VBoxContainer.new()
	section.alignment = BoxContainer.ALIGNMENT_CENTER
	section.add_theme_constant_override("separation", 6)
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

	var body := ScreenHelpers.make_label(section, body_text)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.custom_minimum_size = Vector2(SECTION_TEXT_WIDTH, 0)
