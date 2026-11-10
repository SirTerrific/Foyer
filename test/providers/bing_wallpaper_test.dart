import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flauncher/providers/bing_wallpaper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('bing_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  final archiveJson = jsonEncode({
    'images': [
      {'startdate': '20261108', 'urlbase': '/th?id=OHR.Fox_FR-FR123', 'title': 'Renard', 'copyright': 'Un renard (© Photographe)'},
      {'startdate': '20261107', 'urlbase': '/th?id=OHR.Lake_FR-FR456', 'title': 'Lac', 'copyright': 'Un lac (© Autre)'},
      // Rejected: absolute URL could point the download to another host.
      {'startdate': '20261106', 'urlbase': 'https://evil.example/x', 'title': 'Bad', 'copyright': ''},
      // Rejected: malformed date.
      {'startdate': 'yesterday', 'urlbase': '/th?id=OHR.X', 'title': 'Bad', 'copyright': ''},
    ],
  });

  test("archive parses images, sends market, drops malformed entries", () async {
    Uri? requested;
    final client = MockClient((request) async {
      requested = request.url;
      return http.Response(archiveJson, 200, headers: {'content-type': 'application/json; charset=utf-8'});
    });
    final images = await BingWallpaper(dir, client: client).archive('fr-FR');

    expect(requested!.host, 'www.bing.com');
    expect(requested!.queryParameters['mkt'], 'fr-FR');
    expect(requested!.queryParameters['n'], '$bingArchiveSize');
    expect(images.map((i) => i.startDate), ['20261108', '20261107']);
    expect(images.first.imageUrl, 'https://www.bing.com/th?id=OHR.Fox_FR-FR123_1920x1080.jpg');
    expect(images.first.copyright, 'Un renard (© Photographe)');
  });

  test("archive omits mkt in auto mode and returns empty on error", () async {
    Uri? requested;
    final client = MockClient((request) async {
      requested = request.url;
      return http.Response('oops', 500);
    });
    expect(await BingWallpaper(dir, client: client).archive(''), isEmpty);
    expect(requested!.queryParameters.containsKey('mkt'), isFalse);
  });

  test("download writes the image named after its date", () async {
    final client = MockClient((request) async => http.Response.bytes([1, 2, 3], 200));
    const image = BingImage(startDate: '20261108', urlBase: '/th?id=OHR.Fox', title: 'Renard', copyright: '');
    final file = await BingWallpaper(dir, client: client).download(image);

    expect(file, isNotNull);
    expect(file!.path.endsWith('20261108.jpg'), isTrue);
    expect(file.readAsBytesSync(), [1, 2, 3]);
    expect(dir.listSync().where((f) => f.path.endsWith('.part')), isEmpty);
  });

  test("download returns null on HTTP failure", () async {
    final client = MockClient((request) async => http.Response('', 404));
    const image = BingImage(startDate: '20261108', urlBase: '/th?id=OHR.Fox', title: '', copyright: '');
    expect(await BingWallpaper(dir, client: client).download(image), isNull);
  });

  // A request that never answers: the wallpaper service keeps a "busy" flag
  // while one is in flight, so it must give up by itself.
  final hung = MockClient((_) => Completer<http.Response>().future);

  test("archive gives up on a hung request instead of waiting forever", () async {
    final bing = BingWallpaper(dir, client: hung, requestTimeout: const Duration(milliseconds: 50));
    expect(await bing.archive('fr-FR'), isEmpty);
  });

  test("download gives up on a hung request and leaves the cache clean", () async {
    final bing = BingWallpaper(dir, client: hung, requestTimeout: const Duration(milliseconds: 50));
    const image = BingImage(startDate: '20261108', urlBase: '/th?id=OHR.X', title: 't', copyright: 'c');
    expect(await bing.download(image), isNull);
    expect(dir.listSync(), isEmpty);
  });
}
