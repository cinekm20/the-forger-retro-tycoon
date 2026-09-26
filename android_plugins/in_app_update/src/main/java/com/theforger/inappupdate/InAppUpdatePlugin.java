package com.theforger.inappupdate;

import android.app.Activity;
import android.util.Log;

import com.google.android.play.core.appupdate.AppUpdateInfo;
import com.google.android.play.core.appupdate.AppUpdateManager;
import com.google.android.play.core.appupdate.AppUpdateManagerFactory;
import com.google.android.play.core.install.InstallStateUpdatedListener;
import com.google.android.play.core.install.model.AppUpdateType;
import com.google.android.play.core.install.model.InstallStatus;
import com.google.android.play.core.install.model.UpdateAvailability;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.HashSet;
import java.util.Set;

/**
 * Plugin Androida owinięty przez InAppUpdate.gd (res://scripts/autoload/InAppUpdate.gd)
 * — sprawdza w Google Play, czy jest nowsza wersja gry, i (wariant
 * "flexible") ściąga ją w tle, jeśli tak. Patrz komentarz nagłówkowy tego
 * pliku GDScript po wyjaśnienie CAŁEGO przepływu (checkForUpdate ->
 * update_available -> startUpdate -> update_downloaded -> completeUpdate).
 *
 * Działa TYLKO gdy apka jest zainstalowana z Google Play — w każdym innym
 * przypadku (sideload/debug/inny store) Play Core po prostu zgłasza
 * UPDATE_NOT_AVAILABLE, więc ten plugin nigdy nie "psuje" żadnej innej
 * ścieżki instalacji, tylko cicho nic nie robi.
 */
public class InAppUpdatePlugin extends GodotPlugin {

    private static final String TAG = "InAppUpdatePlugin";
    /** Losowa, ale ustalona wartość — Godot/Android nie pilnuje unikalności
     * requestCode globalnie, wystarczy, że nie koliduje z resztą TEGO
     * pluginu (żadnego innego requestCode tu nie używamy). */
    private static final int UPDATE_FLOW_REQUEST_CODE = 19760101;

    private AppUpdateManager appUpdateManager;
    private AppUpdateInfo pendingUpdateInfo;
    private final InstallStateUpdatedListener installStateListener = state -> {
        if (state.installStatus() == InstallStatus.DOWNLOADED) {
            emitSignal("update_downloaded");
        }
    };

    public InAppUpdatePlugin(Godot godot) {
        super(godot);
    }

    @Override
    public String getPluginName() {
        return "InAppUpdate";
    }

    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new HashSet<>();
        signals.add(new SignalInfo("update_available", Integer.class));
        signals.add(new SignalInfo("update_not_available"));
        signals.add(new SignalInfo("update_downloaded"));
        signals.add(new SignalInfo("update_check_failed", String.class));
        return signals;
    }

    /** Wołane raz na starcie gry (patrz MainMenu.gd::_ready). */
    @UsedByGodot
    public void checkForUpdate() {
        Activity activity = getActivity();
        if (activity == null) {
            emitSignal("update_check_failed", "no activity");
            return;
        }
        AppUpdateManager manager = AppUpdateManagerFactory.create(activity);
        appUpdateManager = manager;
        manager.registerListener(installStateListener);
        manager.getAppUpdateInfo()
                .addOnSuccessListener(info -> {
                    boolean available = info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE
                            && info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE);
                    if (available) {
                        pendingUpdateInfo = info;
                        emitSignal("update_available", info.availableVersionCode());
                    } else {
                        emitSignal("update_not_available");
                    }
                })
                .addOnFailureListener(e -> {
                    Log.w(TAG, "appUpdateInfo() failed", e);
                    emitSignal("update_check_failed", String.valueOf(e.getMessage()));
                });
    }

    /** Wołane przez InAppUpdate.gd natychmiast po sygnale "update_available"
     * — zaczyna ściąganie w tle (wariant "flexible" nie pyta gracza o zgodę
     * na SAM start pobierania, patrz komentarz nagłówkowy InAppUpdate.gd). */
    @UsedByGodot
    public void startUpdate() {
        Activity activity = getActivity();
        if (activity == null || appUpdateManager == null || pendingUpdateInfo == null) {
            return;
        }
        try {
            appUpdateManager.startUpdateFlowForResult(
                    pendingUpdateInfo, AppUpdateType.FLEXIBLE, activity, UPDATE_FLOW_REQUEST_CODE);
        } catch (Exception e) {
            Log.w(TAG, "startUpdateFlowForResult() failed", e);
        }
    }

    /** Gracz kliknął "Zainstaluj aktualizację" w Hubie (patrz Hub.gd) — Play
     * Core sam restartuje aplikację, żeby dokończyć instalację pobranej
     * aktualizacji. */
    @UsedByGodot
    public void completeUpdate() {
        if (appUpdateManager != null) {
            appUpdateManager.completeUpdate();
        }
    }

    @Override
    public void onMainDestroy() {
        super.onMainDestroy();
        if (appUpdateManager != null) {
            appUpdateManager.unregisterListener(installStateListener);
        }
    }
}
