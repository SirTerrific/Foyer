# Foyer

[![Release](https://img.shields.io/github/v/release/SirTerrific/Foyer?style=flat-square&color=C2410C)](https://github.com/SirTerrific/Foyer/releases/latest)
[![CI](https://img.shields.io/github/actions/workflow/status/SirTerrific/Foyer/ci.yml?branch=main&label=CI&style=flat-square)](https://github.com/SirTerrific/Foyer/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/SirTerrific/Foyer?style=flat-square&color=blue)](LICENSE)
[![Downloads](https://img.shields.io/github/downloads/SirTerrific/Foyer/total?style=flat-square&color=2ea44f)](https://github.com/SirTerrific/Foyer/releases)
[![Stars](https://img.shields.io/github/stars/SirTerrific/Foyer?style=flat-square)](https://github.com/SirTerrific/Foyer/stargazers)
[![Last commit](https://img.shields.io/github/last-commit/SirTerrific/Foyer?style=flat-square)](https://github.com/SirTerrific/Foyer/commits/main)
[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.11-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Android TV](https://img.shields.io/badge/Android%20TV-API%2024%2B-3DDC84?style=flat-square&logo=androidtv&logoColor=white)](https://www.android.com/tv/)
[![Languages](https://img.shields.io/badge/languages-6-F59E0B?style=flat-square)](lib/l10n)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20me%20a%20coffee-menelikIII-FFDD00?style=flat-square&logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/menelikIII)

<picture>
  <img alt="Foyer Preview" src="docs/images/home.webp">
</picture>

**Foyer** is an open-source family launcher for Android TV with built-in parental control. It is a fork of [Arc Launcher](https://github.com/meddouribadis/arclauncher) by meddouribadis, itself built on [LTvLauncher](https://github.com/LeanBitLab/LtvLauncher) and originally [FLauncher](https://gitlab.com/flauncher/flauncher).

It keeps the modern grid layout, customizable video and slideshow wallpapers, OLED screensaver protection and remote-friendly navigation, and adds a parental control that locks chosen apps behind a code you enter with the remote's D-pad.

## Installation

Foyer is distributed as an APK built from this repository. Build it yourself, or download a release from the [Releases page](https://github.com/SirTerrific/Foyer/releases) when one is published.

```bash
flutter pub get
flutter gen-l10n
flutter build apk --flavor github
```

Requires Flutter 3.41.x and JDK 17. The app id is `com.sirterrific.foyer`.

## Parental Control

- **D-pad code** - The code is a combination of arrow keys (Up, Down, Left, Right) and digits, entered with the remote, like Projectivy.
- **Protected apps** - Choose which apps (YouTube, etc.) need the code. Watch Next items from unknown apps are protected too.
- **Grace period** - After a correct code, protected apps stay open for 15 minutes.
- **Lockout** - 5 wrong codes lock entry, with a growing delay capped at 15 minutes.
- **Time window** - Optional daily window (default 08:00-20:00) during which protection applies.
- **Settings protection** - Optionally ask for the code before opening the launcher settings.
- **Storage** - The code is stored as a salted SHA-256 hash and compared in constant time.

## Features

### Interface & Navigation
- **Grid Layout** - Clean smart TV app grid with configurable row and column sizing.
- **Watch Next** - Continue watching shows directly from a top-row carousel.
- **Remote Navigation** - High-visibility double-border focus indicators with smooth D-pad navigation.
- **Custom Categories** - Group apps into favorites or custom sections; reorder categories with Left/Right keys.
- **Quick Status Bar** - Displays time, daily data usage, and a shortcut to system Wi-Fi settings.
- **Auto-Hide Status Bar** - Hides the status bar when scrolling into the app grid to maximize screen space.
- **Accent Colors** - Personalize the UI with multiple color presets.
- **Multilingual** - Available in English, French, Spanish, Turkish, Vietnamese, and Simplified Chinese.

### Wallpapers & Screensavers
- **Video Wallpapers** - Set animated video files (MP4/WebM) as the home screen background.
- **Slideshows** - Rotate wallpapers from custom subreddits or Unsplash categories with configurable intervals.
- **OLED Protection** - Pitch-black theme option and screensaver with position-shifting clock to prevent burn-in.
- **Dynamic Wallpapers** - Automatically switch wallpapers or enable dark mode based on the time of day.

### System & Tools
- **No Ads & No Tracking** - Completely open source with zero sponsored content or ads.
- **In-App Updater** - Check for new releases and read changelogs directly inside the app.
- **Sideloaded App Support** - Displays and launches non-TV Android apps without extra workarounds.
- **Brightness Scheduler (Experimental)** - Automatically adjust brightness based on time (requires ADB `WRITE_SETTINGS` permission).

> [!NOTE]
> Because Android's `WallpaperManager` is not available on some Android TV devices, Foyer manages its own wallpapers. Changing the wallpaper requires a file explorer installed on the device.

> [!TIP]
> **Video Wallpaper Performance:** Video wallpapers are loaded into memory for smooth playback. Use compressed clips (ideally under 10MB) on lower-powered TV sticks. If you experience UI stutter, disable the backdrop blur filter in settings.

## Screenshots

<table>
  <tr>
    <td align="center">Settings panel</td>
    <td align="center">Accent colors</td>
    <td align="center">Multiple wallpapers</td>
  </tr>
  <tr>
    <td><img src="docs/images/screen_settings1.png" width="100%" alt="Settings screen 1"/></td>
    <td><img src="docs/images/screen_settings2.png" width="100%" alt="Settings screen 2"/></td>
    <td><img src="docs/images/screen_settings3.png" width="100%" alt="Settings screen 3"/></td>
  </tr>
  <tr>
    <td align="center">Backdrop blur</td>
    <td align="center">Without blur</td>
    <td align="center">Custom banner</td>
  </tr>
  <tr>
    <td><img src="docs/images/screen_settings4.png" width="100%" alt="Settings screen 4"/></td>
    <td><img src="docs/images/screen_settings5.png" width="100%" alt="Settings screen 5"/></td>
    <td><img src="docs/images/screen_settings6.png" width="100%" alt="Settings screen 6"/></td>
  </tr>
  <tr>
    <td align="center">Home</td>
    <td align="center">Wallpaper Options</td>
    <td align="center">Watch Next</td>
  </tr>
  <tr>
    <td><img src="docs/images/home2.png" width="100%" alt="Another home page"/></td>
    <td><img src="docs/images/wallpapers_options.png" width="100%" alt="Different wallpaper options"/></td>
    <td><img src="docs/images/watch_next.png" width="100%" alt="Watch next section"/></td>
  </tr>
</table>

## Set Foyer as default launcher

### Method 1: Remap the Home button

This is the "safer" and easiest way. Use [Button Mapper](https://play.google.com/store/apps/details?id=flar2.homebutton) to remap the Home button of the remote to launch Foyer.

### Method 2: Set Foyer as the home activity over ADB

This is the recommended way to make Foyer your actual home screen. It is a single command, it leaves the
stock launcher untouched, and it can be undone just as easily.

```shell
$ adb shell cmd package set-home-activity com.sirterrific.foyer/.MainActivity
```

This assigns Foyer to the system `HOME` role, so the Home button on the remote goes straight to Foyer. Nothing gets
disabled, which means nothing needs to be re-enabled if you change your mind.

To check which launcher is currently set as home:

```shell
$ adb shell cmd package resolve-activity -c android.intent.category.HOME -a android.intent.action.MAIN
```

To go back to the stock launcher, point the home activity at it instead. List the launchers installed on the
box and copy the one you want back straight from the output:

```shell
$ adb shell cmd package query-activities -c android.intent.category.HOME -a android.intent.action.MAIN
```

```shell
$ adb shell cmd package set-home-activity <package>/<activity>
```

> [!NOTE]
> `set-home-activity` requires Android 8.1 or newer, and what it accepts differs by version. On Android 10 and
> above it assigns the `HOME` role through `RoleManager` and the package name alone is enough. On Android 8.1 to
> 9 it sets a preferred activity directly and needs the full `<package>/<activity>` form. On older systems, use
> Method 1 or the fallback below.

> [!TIP]
> On Android 15 and newer you can also clear the assignment entirely with
> `adb shell cmd package clear-package-preferred-activities`, which makes the system ask again on the next
> Home press.

### Method 3: GUI tools (no command line)

#### TV Box Tools (Android TV / Google TV)

TV Box Tools sets Foyer as the home activity without typing ADB commands manually. Pick Foyer
Launcher in the tool, and it installs the latest release and sets it as the default launcher. It runs on
Windows, macOS, Linux, Android phones, or directly in a TV browser:

- [Google Play](https://play.google.com/store/apps/details?id=com.tv.launcher.manager.adb.tvboxtools)
- [tvboxtools.com](https://tvboxtools.com)

#### Launcher Manager (Amazon Fire TV Stick / Fire OS)

On Amazon Fire TV devices, standard Android launcher switching commands are restricted by Fire OS.
Use **Launcher Manager (FireOS)** (available on [XDA Developers](https://xdaforums.com/t/app-firetv-noroot-launcher-manager-change-launcher-without-root.4176349/))
to set Foyer as your default home screen and override the stock Fire TV launcher.

> [!NOTE]
> Third-party tools are not affiliated with or endorsed by this project. Review device permissions and wireless debugging access before running external management utilities.

### Fallback: Disable the default launcher

Use this only if Methods 2 and 3 do not work on your device. It is more invasive: it disables the stock
launcher, and it is the cause of the "YouTube" remote button issue described below.

> [!WARNING]
> **Disclaimer:** You are doing this at your own risk, and you'll be responsible in any case of malfunction on your device. The following commands have been tested on Chromecast with Google TV only and may differ on other devices.

Once the default launcher is disabled, press the Home button on the remote, and you'll be prompted by the system to choose which app to set as default.

#### Disable default launcher

```shell
# Disable com.google.android.apps.tv.launcherx which is the default launcher on CCwGTV
$ adb shell pm disable-user --user 0 com.google.android.apps.tv.launcherx
# com.google.android.tungsten.setupwraith will then be used as a 'fallback' and will automatically
# re-enable the default launcher, so disable it as well
$ adb shell pm disable-user --user 0 com.google.android.tungsten.setupwraith
```

#### Re-enable default launcher

```shell
$ adb shell pm enable com.google.android.apps.tv.launcherx
$ adb shell pm enable com.google.android.tungsten.setupwraith
```

#### Known issues

On Chromecast with Google TV (maybe others), the "YouTube" remote button will stop working if the default launcher is disabled. As a workaround, you can use [Button Mapper](https://play.google.com/store/apps/details?id=flar2.homebutton) to remap it correctly.

## Contributing

Contributions are welcome! Please check our [Contributing Guidelines](CONTRIBUTING.md) to get started and learn about our commit conventions and Pull Request process.

## Credits and contributors

<a href="https://github.com/SirTerrific/Foyer/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=SirTerrific/Foyer" alt="Contributors" />
</a>

### Original Projects

- **[FLauncher](https://gitlab.com/flauncher/flauncher)** by [etienn01](https://github.com/etienn01) - The original project
- **[FLauncher (Fork)](https://github.com/osrosal/flauncher)** by [osrosal](https://github.com/osrosal) - Community fork with additional features
- **[LTvLauncher](https://github.com/LeanBitLab/LtvLauncher)** by [LeanBitLab](https://github.com/LeanBitLab) - The base for this fork
- **[Arc Launcher](https://github.com/meddouribadis/arclauncher)** by [meddouribadis](https://github.com/meddouribadis) - Direct upstream of this fork

---
