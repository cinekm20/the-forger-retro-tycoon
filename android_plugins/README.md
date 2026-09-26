# Pluginy Androida

Natywne pluginy Androida (Java, `org.godotengine.godot.plugin.GodotPlugin`)
dla Godota — żyją TU, poza `game/` (`res://`), żeby ich kod
źródłowy/Gradle nie mieszał się z zasobami gry skanowanymi przez Godota.
Każdy plugin to WŁASNY, samodzielny projekt Gradle (z własnym wrapperem,
`./gradlew`), budowany NIEZALEŻNIE od głównego projektu gry.

Skompilowany wynik (`.aar`) trzeba skopiować do `game/android/plugins/`,
razem z odpowiadającym mu deskryptorem `.gdap` (ten JEST już trackowany w
repo, bo to mały plik konfiguracyjny, nie build binarny) — dopiero wtedy
Godot włącza plugin przy eksporcie (patrz `plugins/<Nazwa>=true` w
`game/export_presets.cfg`, preset "Android Release").

## in_app_update

Sprawdzanie aktualizacji z Google Play przy starcie gry (zgłoszone przez
użytkownika) — owija bibliotekę Play Core (`com.google.android.play:app-update`),
wariant "flexible" (ściąga w tle, nie blokuje rozgrywki). Strona GDScript:
`game/scripts/autoload/InAppUpdate.gd` — tam pełny opis przepływu
(checkForUpdate -> update_available -> startUpdate -> update_downloaded ->
completeUpdate) i dlaczego działa TYLKO w wersji zainstalowanej z Google
Play.

### Budowanie (CI)

`.github/workflows/android-release-build.yml` buduje ten plugin
automatycznie przy KAŻDYM przebiegu, PRZED eksportem `.aab` — nie trzeba
nic robić ręcznie dla normalnego releasu.

### Budowanie ręczne (lokalnie, do testów)

Wymaga zainstalowanego Android SDK (`ANDROID_HOME`/`ANDROID_SDK_ROOT`
ustawione) z `platforms;android-34` i `build-tools;34.0.0`:

```
cd android_plugins/in_app_update
./gradlew assembleRelease
cp build/outputs/aar/in_app_update-release.aar ../../game/android/plugins/InAppUpdate.aar
```

Potem normalny eksport presetu "Android Release" (edytor albo
`godot --headless --export-release "Android Release" ...`) automatycznie
go podłączy.

### Testowanie w praktyce

Play Core (In-App Updates) działa WYŁĄCZNIE dla apki zainstalowanej z
Google Play — sideload/debug/APK budowany lokalnie zawsze widzi "brak
aktualizacji", bez błędu. Żeby faktycznie przetestować cały przepływ,
trzeba wgrać dwie różne wersje (niższą i wyższą) na tor testowy Google Play
(np. Internal testing) i zainstalować starszą z Play, poczekać na
propagację, potem uruchomić grę.
