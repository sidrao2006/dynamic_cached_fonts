import 'dart:typed_data';

import 'package:dynamic_cached_fonts/dynamic_cached_fonts.dart';
import 'package:dynamic_cached_fonts_example/constants.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart' show IntegrationTestWidgetsFlutterBinding;

const String fontUrl = cascadiaCodeUrl,
    fontName = cascadiaCode,
    altFontUrl = notoSansUrl,
    altFontName = notoSans,
    firebaseFontUrl = firaCodeUrl,
    firebaseFontName = firaCode;

final String cacheKey = cacheKeyFromUrl(fontUrl);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late final CacheManager cacheManager;

  setUpAll(() {
    cacheManager = CacheManager(Config(cacheKey));

    DynamicCachedFonts.custom(cacheManager: cacheManager);
  });

  tearDown(() => cacheManager.emptyCache());

  group('DynamicCachedFonts.load', () {
    late FileInfo font;
    late DynamicCachedFonts cachedFontLoader;

    setUp(() async {
      cachedFontLoader = DynamicCachedFonts(url: fontUrl, fontFamily: fontName);

      font = (await cachedFontLoader.load()).first;
    });

    testWidgets('should load font file with a valid extension', (_) async {
      final String fontFileName = font.file.basename;

      expect(fontFileName, endsWith('ttf'));
    });

    testWidgets('should allow font to be loaded only once', (_) async {
      expect(cachedFontLoader.load(), throwsStateError);
    });

    testWidgets('should load valid font file', (_) async {
      final FileInfo downloadedFont = await cacheManager.downloadFile(
        fontUrl,
        key: '$cacheKey-test',
      );

      expect(
        downloadedFont.file.readAsBytesSync(),
        orderedEquals(font.file.readAsBytesSync()),
      );
    });
  });

  group('DynamicCachedFonts.loadStream', () {
    late DynamicCachedFonts cachedFontLoader;

    const List<String> fontUrls = <String>[
      firaSansBoldUrl,
      firaSansItalicUrl,
      firaSansRegularUrl,
      firaSansThinUrl,
    ];

    const List<String> altFontUrls = <String>[
      robotoBoldUrl,
      robotoItalicUrl,
      robotoRegularUrl,
      robotoThinUrl,
    ];

    setUp(() async {
      cachedFontLoader = DynamicCachedFonts.family(
        urls: fontUrls,
        fontFamily: firaSans,
      );
    });

    testWidgets('should load font file with a valid extension', (_) async {
      final Stream<FileInfo> fontStream = cachedFontLoader.loadStream();

      final Stream<String> fontFileNameStream = fontStream.map((font) => font.file.basename);

      await expectLater(fontFileNameStream, emitsThrough(endsWith('ttf')));
    });

    testWidgets('should allow font to be loaded only once', (_) async {
      await cachedFontLoader.loadStream().listen((event) {}).asFuture();
      await expectLater(cachedFontLoader.loadStream(), emitsError(isStateError));
    });

    testWidgets('should load valid font files', (_) async {
      final Stream<FileInfo> fontStream = cachedFontLoader.loadStream();

      final List<Uint8List> downloadedFontBytes = await awaitedMap(fontUrls, (String url) async {
        final String generatedCacheKey = cacheKeyFromUrl(url);
        final FileInfo donwloadedFont =
            await cacheManager.downloadFile(url, key: '$generatedCacheKey-test');

        return donwloadedFont.file.readAsBytes();
      });

      final Stream<Uint8List> fontBytes =
          fontStream.map((FileInfo font) => font.file.readAsBytesSync());

      await expectLater(fontBytes, emitsInOrder(downloadedFontBytes));
    });

    testWidgets('should emit downloadProgress events', (_) async {
      final List<DownloadProgress> progressListener = [];
      final Set<String> downloadedfontUrls = {};

      final altCachedFontLoader = DynamicCachedFonts.family(
        urls: altFontUrls,
        fontFamily: roboto,
      );

      final Stream<FileInfo> fontStream = altCachedFontLoader.loadStream(
        downloadProgressListener: (progress) {
          progressListener.add(progress);
          downloadedfontUrls.add(progress.originalUrl);
        },
      );

      await fontStream.listen((_) {}).asFuture();

      expect(downloadedfontUrls, unorderedEquals(altFontUrls.toSet()));
      expect(
        progressListener,
        anyElement(
          predicate<DownloadProgress>(
            (progress) => progress.progress != null && progress.progress! > 0,
            'has a progress value greater than 0',
          ),
        ),
      );
    });

    testWidgets('should emit itemCountProgress events', (_) async {
      final List<List<num>> progressListener = [];

      final Stream<FileInfo> fontStream = cachedFontLoader.loadStream(
        itemCountProgressListener: ((progress, totalItems, downloadedItems) =>
            progressListener.add([progress, totalItems, downloadedItems])),
      );

      await fontStream.listen((_) {}).asFuture();

      expect(progressListener, hasLength(equals(fontUrls.length)));
      expect(
        progressListener,
        everyElement(predicate<List<num>>(
          (event) => event[0] == event[2] / event[1],
          'has a progress value equal to the number of downloaded items divided by the total number of items',
        )),
      );
      expect(progressListener.first, orderedEquals([0.25, fontUrls.length, 1]));
      expect(progressListener.last, orderedEquals([1.0, fontUrls.length, fontUrls.length]));
    });
  });

  group('DynamicCachedFonts.family', () {
    late Iterable<FileInfo> fonts;
    late DynamicCachedFonts cachedFontLoader;

    const List<String> fontUrls = <String>[
      firaSansBoldUrl,
      firaSansItalicUrl,
      firaSansRegularUrl,
      firaSansThinUrl,
    ];

    setUp(() async {
      cachedFontLoader = DynamicCachedFonts.family(
        urls: fontUrls,
        fontFamily: firaSans,
      );

      fonts = await cachedFontLoader.load();
    });

    testWidgets('should load valid font files', (_) async {
      final List<Uint8List> downloadedFontBytes = await awaitedMap(fontUrls, (String url) async {
        final String generatedCacheKey = cacheKeyFromUrl(url);
        final FileInfo donwloadedFont =
            await cacheManager.downloadFile(url, key: '$generatedCacheKey-test');

        return donwloadedFont.file.readAsBytes();
      });

      final List<Uint8List> fontBytes =
          fonts.map((FileInfo font) => font.file.readAsBytesSync()).toList();

      for (int i = 0; i < fontUrls.length; i++) {
        expect(fontBytes[i], orderedEquals(downloadedFontBytes[i]));
      }
    });

    testWidgets('should load the font family into the Flutter Engine', (_) async {
      expect(cachedFontLoader.load(), throwsStateError);
    });
  });

  group('DynamicCachedFonts.fromFirebase', () {
    late FileInfo font;
    late Reference bucketRef;

    setUp(() async {
      await Firebase.initializeApp();

      font = (await DynamicCachedFonts.fromFirebase(
        bucketUrl: firebaseFontUrl,
        fontFamily: firebaseFontName,
      ).load())
          .first;

      bucketRef = FirebaseStorage.instance.refFromURL(firebaseFontUrl);
    });

    testWidgets('should parse Firebase Bucket URL', (_) async {
      expect(font.originalUrl, equals(await bucketRef.getDownloadURL()));
    });

    testWidgets('should load font into cache', (_) async {
      expect(font, isNotNull);
    });

    testWidgets('should load valid font file from Firebase', (_) async {
      expect(
        font.file.readAsBytesSync(),
        orderedEquals((await bucketRef.getData())!),
      );
    });
  },
      skip: ThemeData().platform == TargetPlatform.windows ||
          ThemeData().platform == TargetPlatform.linux);

  group('DynamicCachedFonts.cacheFont', () {
    FileInfo? font;

    setUp(() async {
      await DynamicCachedFonts.cacheFont(fontUrl);

      font = await cacheManager.getFileFromCache(cacheKey);
    });

    testWidgets('should load font into cache', (_) async {
      expect(font, isNotNull);
    });

    testWidgets('should load font file with a valid extension', (_) async {
      final String fontFileName = font!.file.basename;

      expect(fontFileName, endsWith('ttf'));
    });

    testWidgets('should throw UnsupportedError if file extension is not valid', (_) async {
      const String woffUrl =
          'https://cdn.jsdelivr.net/gh/mozilla/Fira@4.202/woff/FiraMono-Regular.woff';

      expect(DynamicCachedFonts.cacheFont(woffUrl), throwsUnsupportedError);
    });
  });

  group('DynamicCachedFonts.cacheFontStream', () {
    late Stream<FileInfo> fontStream;

    setUp(() => fontStream = DynamicCachedFonts.cacheFontStream(fontUrl));

    testWidgets('should load font into cache', (_) async {
      await fontStream.listen((_) {}).asFuture();

      final FileInfo? font = await cacheManager.getFileFromCache(cacheKey);

      expect(font, isNotNull);
    });
    testWidgets('should load valid font file', (_) async {
      final FileInfo downloadedFont = await cacheManager.downloadFile(
        fontUrl,
        key: cacheKey,
      );

      await expectLater(
        fontStream.map((font) => font.file.readAsBytesSync()),
        emits(orderedEquals(downloadedFont.file.readAsBytesSync())),
      );
    });

    testWidgets('should load font file with a valid extension', (_) async {
      final Stream<String> fontFileNameStream = fontStream.map((font) => font.file.basename);

      await expectLater(fontFileNameStream, emits(endsWith('ttf')));
    });

    testWidgets('should throw UnsupportedError if file extension is not valid', (_) async {
      const String woffUrl =
          'https://cdn.jsdelivr.net/gh/mozilla/Fira@4.202/woff/FiraMono-Regular.woff';

      await expectLater(
          DynamicCachedFonts.cacheFontStream(woffUrl), emitsError(isUnsupportedError));
    });

    testWidgets('should emit downloadProgress events', (_) async {
      final List<DownloadProgress> progressListener = [];
      final Set<String> downloadedfontUrl = {};

      final Stream<FileInfo> fontStream = DynamicCachedFonts.cacheFontStream(
        altFontUrl,
        progressListener: (progress) {
          progressListener.add(progress);
          downloadedfontUrl.add(progress.originalUrl);
        },
      );

      await fontStream.listen((_) {}).asFuture();

      expect(downloadedfontUrl, equals({altFontUrl}));
      expect(
        progressListener,
        anyElement(
          predicate<DownloadProgress>(
            (progress) => progress.progress != null && progress.progress! > 0,
            'has a progress value greater than 0',
          ),
        ),
      );
    });
  });

  group('DynamicCachedFonts.canLoadFont', () {
    setUp(() => cacheManager.downloadFile(
          fontUrl,
          key: cacheKey,
        ));

    testWidgets('should return true when font is available in cache', (_) async {
      await expectLater(
        DynamicCachedFonts.canLoadFont(fontUrl),
        completion(isTrue),
      );
    });

    testWidgets('should return false when font is not available in cache', (_) async {
      final FileInfo? font = await cacheManager.getFileFromCache(cacheKey);

      font?.file.deleteSync();
      await cacheManager.removeFile(cacheKey);

      await expectLater(
        DynamicCachedFonts.canLoadFont(fontUrl),
        completion(isFalse),
      );
    });
  });

  group('DynamicCachedFonts.loadCachedFont', () {
    late FontLoader fontLoader;
    late FileInfo font;
    late FileInfo downloadedFont;

    setUp(() async {
      fontLoader = FontLoader(fontName);

      downloadedFont = await cacheManager.downloadFile(fontUrl, key: cacheKey);

      font = await DynamicCachedFonts.loadCachedFont(
        fontUrl,
        fontFamily: fontName,
        fontLoader: fontLoader,
      );
    });

    testWidgets('should load valid font file', (_) async {
      expect(
        downloadedFont.file.readAsBytesSync(),
        orderedEquals(font.file.readAsBytesSync()),
      );
    });

    testWidgets('should load font into the Flutter Engine', (_) async {
      // This tests that load() is being called in loadCachedFamily.
      // A single instance of FontLoader can only be loaded once, so if
      // StateError is thrown, it means that load() has already been called.
      expect(fontLoader.load(), throwsStateError);
    });
  });

  group('DynamicCachedFonts.loadCachedFamily', () {
    late FontLoader fontLoader;
    late Iterable<FileInfo> fonts;
    late Iterable<FileInfo> downloadedFonts;

    const List<String> fontUrls = <String>[
      firaSansBoldUrl,
      firaSansItalicUrl,
      firaSansRegularUrl,
      firaSansThinUrl,
    ];

    setUp(() async {
      fontLoader = FontLoader(fontName);

      downloadedFonts = await awaitedMap(fontUrls, (String url) {
        final String generatedCacheKey = cacheKeyFromUrl(url);
        return cacheManager.downloadFile(url, key: generatedCacheKey);
      });

      fonts = await DynamicCachedFonts.loadCachedFamily(
        fontUrls,
        fontFamily: firaSans,
        fontLoader: fontLoader,
      );
    });

    testWidgets('should load all fonts into cache', (_) async {
      expect(fonts, everyElement(isNotNull));
    });

    testWidgets('should load valid font files', (_) async {
      final List<Uint8List> downloadedFontBytes = downloadedFonts
          .map((FileInfo downloadedFont) => downloadedFont.file.readAsBytesSync())
          .toList();

      final List<Uint8List> fontBytes =
          fonts.map((FileInfo font) => font.file.readAsBytesSync()).toList();

      for (int i = 0; i < fontUrls.length; i++) {
        expect(fontBytes[i], orderedEquals(downloadedFontBytes[i]));
      }
    });

    testWidgets('should load the font family into the Flutter Engine', (_) async {
      // This tests that load() is being called in loadCachedFamily.
      // A single instance of FontLoader can only be loaded once, so if
      // StateError is thrown, it means that load() has already been called.
      expect(fontLoader.load(), throwsStateError);
    });
  });

  group('DynamicCachedFonts.loadCachedFamilyStream', () {
    late FontLoader fontLoader;
    late Stream<FileInfo> fontStream;

    const List<String> fontUrls = <String>[
      firaSansBoldUrl,
      firaSansItalicUrl,
      firaSansRegularUrl,
      firaSansThinUrl,
    ];

    setUp(() async {
      fontLoader = FontLoader(fontName);

      await awaitedMap(fontUrls, (String url) {
        final String generatedCacheKey = cacheKeyFromUrl(url);
        return cacheManager.downloadFile(url, key: generatedCacheKey);
      });

      fontStream = DynamicCachedFonts.loadCachedFamilyStream(
        fontUrls,
        fontFamily: firaSans,
        fontLoader: fontLoader,
      );
    });

    testWidgets('should load font files with a valid extension', (_) async {
      final Stream<String> fontFileNameStream = fontStream.map((font) => font.file.basename);

      await expectLater(fontFileNameStream, emitsThrough(endsWith('ttf')));
    });

    testWidgets('should load valid font files', (_) async {
      final List<Uint8List> downloadedFontBytes = await awaitedMap(fontUrls, (String url) async {
        final String generatedCacheKey = cacheKeyFromUrl(url);
        final FileInfo donwloadedFont =
            await cacheManager.downloadFile(url, key: '$generatedCacheKey-test');

        return donwloadedFont.file.readAsBytes();
      });

      final Stream<Uint8List> fontBytes =
          fontStream.map((FileInfo font) => font.file.readAsBytesSync());

      await expectLater(fontBytes, emitsInOrder(downloadedFontBytes));
    });

    testWidgets('should load the font family into the Flutter Engine', (_) async {
      await fontStream.listen((_) {}).asFuture();

      // This tests that load() is being called in loadCachedFamily.
      // A single instance of FontLoader can only be loaded once, so if
      // StateError is thrown, it means that load() has already been called.
      expect(fontLoader.load(), throwsStateError);
    });

    testWidgets('should emit itemCountProgress events', (_) async {
      final List<List<num>> progressListener = [];

      final Stream<FileInfo> fontStream = DynamicCachedFonts.loadCachedFamilyStream(
        fontUrls,
        fontFamily: firaSans,
        progressListener: ((progress, totalItems, downloadedItems) =>
            progressListener.add([progress, totalItems, downloadedItems])),
      );

      await fontStream.listen((_) {}).asFuture();

      expect(progressListener, hasLength(equals(fontUrls.length)));
      expect(
        progressListener,
        everyElement(predicate<List<num>>((event) => event[0] == event[2] / event[1])),
      );
      expect(progressListener.first, orderedEquals([0.25, fontUrls.length, 1]));
      expect(progressListener.last, orderedEquals([1.0, fontUrls.length, fontUrls.length]));
    });
  });

  testWidgets('DynamicCachedFonts.removeCachedFont should remove the font from cache', (_) async {
    await cacheManager.downloadFile(fontUrl, key: cacheKey);

    await DynamicCachedFonts.removeCachedFont(fontUrl);

    await expectLater(
      cacheManager.getFileFromCache(cacheKey, ignoreMemCache: true),
      completion(isNull),
    );
  });
}

// Helpers

Future<List<T>> awaitedMap<T, E>(
  Iterable<E> iterable,
  Future<T> Function(E) f,
) =>
    Future.wait(iterable.map(f));
