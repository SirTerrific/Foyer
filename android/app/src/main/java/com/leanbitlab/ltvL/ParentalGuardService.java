package com.sirterrific.foyer;

import android.accessibilityservice.AccessibilityService;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import android.provider.Settings;
import android.text.TextUtils;
import android.view.accessibility.AccessibilityEvent;

import java.util.Calendar;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Watches which app comes to the foreground, wherever it was opened from
 * (recents, another app, voice assistant), and brings Foyer's code prompt up
 * over a protected app that Foyer did not just unlock.
 *
 * The protection settings are pushed here by Flutter ({@link #saveConfig}) and
 * kept in native preferences so the guard keeps working when Flutter is not running.
 * The unlocked package lives in memory only: a process restart locks everything.
 */
public class ParentalGuardService extends AccessibilityService {
    static final String EXTRA_LOCKED_PACKAGE = "foyer.parental_locked_package";

    private static final String PREFS = "foyer_parental_guard";
    private static final String KEY_ACTIVE = "active";
    private static final String KEY_PACKAGES = "packages";
    private static final String KEY_PROTECT_SETTINGS = "protect_settings";
    private static final String KEY_WINDOW_ENABLED = "window_enabled";

    /** Android settings apps: they hold "Force stop" and the accessibility switch. */
    private static final Set<String> SETTINGS_PACKAGES = new HashSet<>(java.util.Arrays.asList(
            "com.android.settings", "com.android.tv.settings"));
    private static final String KEY_WINDOW_START = "window_start";
    private static final String KEY_WINDOW_END = "window_end";

    /** Package Foyer launched after a correct code; cleared as soon as another app shows. */
    private static volatile String allowedPackage;
    /** Package waiting for the code, read once by Flutter. */
    private static volatile String pendingLock;

    private BroadcastReceiver screenOffReceiver;

    static void allow(String packageName) {
        allowedPackage = packageName;
    }

    static String takePendingLock() {
        String p = pendingLock;
        pendingLock = null;
        return p;
    }

    static void saveConfig(Context context, boolean active, List<String> packages, boolean protectSettings,
                           boolean windowEnabled, int windowStart, int windowEnd) {
        context.getSharedPreferences(PREFS, MODE_PRIVATE).edit()
                .putBoolean(KEY_ACTIVE, active)
                .putStringSet(KEY_PACKAGES, new HashSet<>(packages))
                .putBoolean(KEY_PROTECT_SETTINGS, protectSettings)
                .putBoolean(KEY_WINDOW_ENABLED, windowEnabled)
                .putInt(KEY_WINDOW_START, windowStart)
                .putInt(KEY_WINDOW_END, windowEnd)
                .apply();
    }

    /** True when this build declares the service (github flavor only). */
    static boolean isAvailable(Context context) {
        try {
            context.getPackageManager().getServiceInfo(new ComponentName(context, ParentalGuardService.class), 0);
            return true;
        } catch (PackageManager.NameNotFoundException e) {
            return false;
        }
    }

    /** True when the user switched the service on in the accessibility settings. */
    static boolean isEnabled(Context context) {
        String enabled = Settings.Secure.getString(context.getContentResolver(),
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES);
        if (TextUtils.isEmpty(enabled)) return false;
        ComponentName me = new ComponentName(context, ParentalGuardService.class);
        for (String s : enabled.split(":")) {
            ComponentName c = ComponentName.unflattenFromString(s);
            if (me.equals(c)) return true;
        }
        return false;
    }

    /**
     * Android removes an app's accessibility service when the app is force-stopped.
     * With WRITE_SECURE_SETTINGS (granted once over adb, see README) Foyer puts it
     * back itself while parental control is on. Without it, this does nothing.
     */
    static void tryReenable(Context context) {
        if (context.checkSelfPermission(android.Manifest.permission.WRITE_SECURE_SETTINGS)
                != PackageManager.PERMISSION_GRANTED) return;
        if (!isAvailable(context) || isEnabled(context)) return;
        if (!context.getSharedPreferences(PREFS, MODE_PRIVATE).getBoolean(KEY_ACTIVE, false)) return;
        try {
            String me = new ComponentName(context, ParentalGuardService.class).flattenToString();
            String current = Settings.Secure.getString(context.getContentResolver(),
                    Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES);
            String updated = TextUtils.isEmpty(current) ? me : current + ":" + me;
            Settings.Secure.putString(context.getContentResolver(),
                    Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, updated);
            Settings.Secure.putInt(context.getContentResolver(), Settings.Secure.ACCESSIBILITY_ENABLED, 1);
        } catch (SecurityException ignored) {
            // Permission revoked between the check and the write.
        }
    }

    @Override
    protected void onServiceConnected() {
        super.onServiceConnected();
        screenOffReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                allowedPackage = null;
            }
        };
        IntentFilter filter = new IntentFilter(Intent.ACTION_SCREEN_OFF);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenOffReceiver, filter, Context.RECEIVER_NOT_EXPORTED);
        } else {
            registerReceiver(screenOffReceiver, filter);
        }
    }

    @Override
    public void onDestroy() {
        if (screenOffReceiver != null) {
            try { unregisterReceiver(screenOffReceiver); } catch (IllegalArgumentException ignored) { }
            screenOffReceiver = null;
        }
        super.onDestroy();
    }

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        if (event.getEventType() != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return;
        CharSequence pkgSeq = event.getPackageName();
        CharSequence clsSeq = event.getClassName();
        if (pkgSeq == null || clsSeq == null) return;
        String pkg = pkgSeq.toString();
        // Only full-screen activities count: keyboards, toasts, volume panels and
        // dialogs of other packages must neither lock nor end an unlock.
        if (!isActivity(pkg, clsSeq.toString())) return;

        if (pkg.equals(getPackageName())) {
            allowedPackage = null;
            return;
        }
        if (pkg.equals(allowedPackage)) return;
        boolean locked = isProtectedNow(pkg);
        // A system screen passing over the unlocked app (account picker,
        // permission prompt) must not ask the code again on the way back.
        if (!locked && isSystemSupportApp(pkg)) return;
        allowedPackage = null;
        if (!locked) return;

        pendingLock = pkg;
        Intent intent = new Intent(this, MainActivity.class)
                .putExtra(EXTRA_LOCKED_PACKAGE, pkg)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        startActivity(intent);
    }

    @Override
    public void onInterrupt() { }

    private boolean isActivity(String pkg, String cls) {
        try {
            getPackageManager().getActivityInfo(new ComponentName(pkg, cls), 0);
            return true;
        } catch (PackageManager.NameNotFoundException e) {
            return false;
        }
    }

    /**
     * A preinstalled package with no launcher entry: a permission prompt, an
     * account picker. A launchable app (YouTube, a home screen) is not one, so
     * switching to it still ends the unlock.
     */
    private boolean isSystemSupportApp(String pkg) {
        PackageManager pm = getPackageManager();
        try {
            if ((pm.getApplicationInfo(pkg, 0).flags & ApplicationInfo.FLAG_SYSTEM) == 0) return false;
        } catch (PackageManager.NameNotFoundException e) {
            return false;
        }
        return pm.getLeanbackLaunchIntentForPackage(pkg) == null && pm.getLaunchIntentForPackage(pkg) == null;
    }

    private boolean isSettingsPackage(String pkg) {
        if (SETTINGS_PACKAGES.contains(pkg)) return true;
        // Some vendors ship their own settings app: ask who answers ACTION_SETTINGS.
        ComponentName c = new Intent(Settings.ACTION_SETTINGS).resolveActivity(getPackageManager());
        return c != null && pkg.equals(c.getPackageName());
    }

    private boolean isProtectedNow(String pkg) {
        SharedPreferences p = getSharedPreferences(PREFS, MODE_PRIVATE);
        if (!p.getBoolean(KEY_ACTIVE, false)) return false;
        Set<String> packages = p.getStringSet(KEY_PACKAGES, null);
        boolean listed = packages != null && packages.contains(pkg);
        boolean settings = p.getBoolean(KEY_PROTECT_SETTINGS, false) && isSettingsPackage(pkg);
        if (!listed && !settings) return false;
        if (!p.getBoolean(KEY_WINDOW_ENABLED, false)) return true;
        int start = p.getInt(KEY_WINDOW_START, 8 * 60);
        int end = p.getInt(KEY_WINDOW_END, 20 * 60);
        if (start == end) return true;
        Calendar now = Calendar.getInstance();
        int minutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE);
        // Same rule as ParentalControlService.windowActiveNow: wraps over midnight.
        return start < end ? (minutes >= start && minutes < end) : (minutes >= start || minutes < end);
    }
}
