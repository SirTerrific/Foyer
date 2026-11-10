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

import 'dart:convert';
import 'dart:io';

import 'package:flauncher/providers/unsplash_slideshow.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Bing markets offered in the settings. The empty key lets Bing pick the
/// market from the network location.
const List<String> bingMarkets = [
  '', 'en-US', 'en-GB', 'en-CA', 'fr-CA', 'fr-FR', 'de-DE', 'es-ES',
  'it-IT', 'pt-BR', 'ja-JP', 'zh-CN', 'en-AU', 'en-IN',
];

/// How many recent images the Bing archive endpoint returns at most.
const int bingArchiveSize = 8;

class BingImage {
  /// Day the image was published, as `yyyyMMdd`. Unique per market and used as file name.
  final String startDate;
  final String urlBase;
  final String title;
  final String copyright;

  const BingImage({required this.startDate, required this.urlBase, required this.title, required this.copyright});

  /// Full HD rendition: the TV output resolution, and a quarter of the memory of the UHD one.
  String get imageUrl => "https://www.bing.com${urlBase}_1920x1080.jpg";

  String get thumbnailUrl => "https://www.bing.com${urlBase}_400x240.jpg";

  static BingImage? fromJson(Map<String, dynamic> json) {
    final startDate = json['startdate'];
    final urlBase = json['urlbase'];
    // Only accept site-relative paths, so a malformed answer can never point the download elsewhere.
    if (startDate is! String || !RegExp(r'^\d{8}$').hasMatch(startDate)) return null;
    if (urlBase is! String || !urlBase.startsWith('/')) return null;
    return BingImage(
      startDate: startDate,
      urlBase: urlBase,
      title: (json['title'] as String?)?.trim() ?? '',
      copyright: (json['copyright'] as String?)?.trim() ?? '',
    );
  }
}

class BingWallpaper {
  final Directory cacheDir;
  final http.Client _client;

  /// A hung request would keep the "busy" flag of the wallpaper service up forever.
  final Duration requestTimeout;

  BingWallpaper(this.cacheDir, {http.Client? client, this.requestTimeout = const Duration(seconds: 30)})
      : _client = client ?? http.Client();

  /// The [bingArchiveSize] most recent images, newest first. Empty on any failure.
  Future<List<BingImage>> archive(String market) async {
    try {
      final response = await _client.get(Uri.https('www.bing.com', '/HPImageArchive.aspx', {
        'format': 'js',
        'idx': '0',
        'n': '$bingArchiveSize',
        if (market.isNotEmpty) 'mkt': market,
      })).timeout(requestTimeout);
      if (response.statusCode != 200) return const [];
      final images = (jsonDecode(response.body) as Map<String, dynamic>)['images'];
      if (images is! List) return const [];
      return images.whereType<Map<String, dynamic>>().map(BingImage.fromJson).whereType<BingImage>().toList();
    } catch (e) {
      debugPrint("Bing wallpaper: $e");
      return const [];
    }
  }

  /// Downloads [image] into [cacheDir] and prunes older files. Null on failure,
  /// so the caller keeps the current wallpaper.
  Future<File?> download(BingImage image) async {
    try {
      final response = await _client.get(Uri.parse(image.imageUrl)).timeout(requestTimeout);
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return null;
      await cacheDir.create(recursive: true);
      // Write to a temp name first so a half-written file is never displayed.
      final tmp = File("${cacheDir.path}/${image.startDate}.part");
      await tmp.writeAsBytes(response.bodyBytes, flush: true);
      final file = await tmp.rename("${cacheDir.path}/${image.startDate}.jpg");
      // rename keeps the old mtime when the file already existed; touch it so it ranks newest.
      await file.setLastModified(DateTime.now());
      await pruneCache(cacheDir, keep: slideshowMaxCachedFiles);
      return file;
    } catch (e) {
      debugPrint("Bing wallpaper: $e");
      return null;
    }
  }
}
