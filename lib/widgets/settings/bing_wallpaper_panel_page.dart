/*
 * Foyer
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/bing_wallpaper.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/widgets/ensure_visible.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Bing image of the day: follow it automatically or pin one of the recent images.
class BingWallpaperPanelPage extends StatefulWidget {
  static const String routeName = "bing_wallpaper_panel";

  const BingWallpaperPanelPage({super.key});

  @override
  State<BingWallpaperPanelPage> createState() => _BingWallpaperPanelPageState();
}

class _BingWallpaperPanelPageState extends State<BingWallpaperPanelPage> {
  late Future<List<BingImage>> _archive;
  late String _market;
  String? _loadingDate;

  @override
  void initState() {
    super.initState();
    _market = context.read<SettingsService>().bingMarket;
    _archive = context.read<WallpaperService>().bingArchive();
  }

  void _reloadIfMarketChanged(String market) {
    if (market == _market) return;
    _market = market;
    _archive = context.read<WallpaperService>().bingArchive();
  }

  Future<void> _select(BingImage image, AppLocalizations localizations) async {
    setState(() => _loadingDate = image.startDate);
    final ok = await context.read<WallpaperService>().selectBingImage(image);
    if (!mounted) return;
    setState(() => _loadingDate = null);
    if (!ok) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(localizations.bingDownloadFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Consumer<SettingsService>(
      builder: (context, settings, _) {
        _reloadIfMarketChanged(settings.bingMarket);
        return Column(
          children: [
            SettingsPageHeader(title: localizations.bingWallpaper),
            Expanded(
              child: ListView(
                children: [
                  RoundedSwitchListTile(
                    autofocus: true,
                    title: Text(localizations.bingEnable),
                    secondary: const Icon(Icons.travel_explore),
                    value: settings.bingWallpaperEnabled,
                    onChanged: settings.setBingWallpaperEnabled,
                  ),
                  RoundedSwitchListTile(
                    title: Text(localizations.bingAutoDaily),
                    subtitle: Text(localizations.bingAutoDailyHelp),
                    secondary: const Icon(Icons.today),
                    value: settings.bingAutoDaily,
                    onChanged: settings.setBingAutoDaily,
                  ),
                  FocusableSettingsTile(
                    leading: const Icon(Icons.public),
                    title: Text(localizations.bingMarket),
                    trailing: Text(settings.bingMarket.isEmpty ? localizations.bingMarketAuto : settings.bingMarket),
                    onPressed: () => settings.setBingMarket(_nextMarket(settings.bingMarket)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
                    child: Text(localizations.bingRecentImages, style: Theme.of(context).textTheme.titleSmall),
                  ),
                  FutureBuilder<List<BingImage>>(
                    future: _archive,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final images = snapshot.data ?? const <BingImage>[];
                      if (images.isEmpty) {
                        return Padding(padding: const EdgeInsets.all(8), child: Text(localizations.bingUnavailable));
                      }
                      return Column(
                        children: [
                          for (final image in images)
                            EnsureVisible(
                              alignment: 0.5,
                              child: FocusableSettingsTile(
                                frameLeading: false,
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    image.thumbnailUrl,
                                    width: 64,
                                    height: 38,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const SizedBox(width: 64, height: 38),
                                  ),
                                ),
                                title: Text(image.title.isEmpty ? _formatDate(image.startDate) : image.title,
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text(_formatDate(image.startDate)),
                                trailing: _loadingDate == image.startDate
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : settings.bingWallpaperEnabled && settings.bingCurrentDate == image.startDate
                                        ? const Icon(Icons.check_circle, size: 20)
                                        : null,
                                onPressed: _loadingDate == null ? () => _select(image, localizations) : null,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static String _formatDate(String yyyymmdd) =>
      "${yyyymmdd.substring(0, 4)}-${yyyymmdd.substring(4, 6)}-${yyyymmdd.substring(6, 8)}";

  static String _nextMarket(String current) {
    final index = bingMarkets.indexOf(current);
    return bingMarkets[(index + 1) % bingMarkets.length];
  }
}
