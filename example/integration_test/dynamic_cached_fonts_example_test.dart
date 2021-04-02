import 'package:dynamic_cached_fonts/dynamic_cached_fonts.dart';
import 'package:dynamic_cached_fonts_example/constants.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart' show IntegrationTestWidgetsFlutterBinding;

const String fontUrl = cascadiaCodeUrl,
    fontName = cascadiaCode,
    firebaseFontUrl = firaCodeUrl,
    firebaseFontName = firaCode;

final String cacheKey = fontUrl.replaceAll(RegExp(r'\/|:'), '');

const String fontFileValidatorFailureReason =
    'Difference in the actual validity of file and expected validity is greater than 10 seconds.\nThis might be a speed/performance issue with host device or the test device';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  CacheManager cacheManager;

  setUpAll(() {
    cacheManager = CacheManager(Config(cacheKey));
  });

  group('DynamicCachedFonts.load', () {
    FileInfo fontFile;
    DynamicCachedFonts fontLoader;

    setUpAll(() async {
      DynamicCachedFonts.custom(cacheManager: cacheManager);

      fontLoader = DynamicCachedFonts(url: fontUrl, fontFamily: fontName);

      await fontLoader.load();

      fontFile = await cacheManager.getFileFromCache(cacheKey);
    });

    testWidgets('Font file is loaded into cache', (_) async {
      expect(fontFile, isNotNull);
    });

    testWidgets('Loaded font file has a valid extension', (_) async {
      final String fontExtension = fontFile.file.uri.pathSegments.last.split('.').last;

      expect(fontExtension, 'ttf');
    });

    testWidgets('Font can be loaded only once', (_) async {
      expect(fontLoader.load(), throwsStateError);
    });

    testWidgets('Font loader loads valid font file', (_) async {
      final FileInfo downloadedFontFile = await cacheManager.downloadFile(
        fontUrl,
        key: cacheKey,
      );

      expect(
        await downloadedFontFile.file.readAsBytes(),
        await fontFile.file.readAsBytes(),
      );
    });
  });

  testWidgets('DynamicCachedFonts.family loads all fonts into cache', (_) async {
    const List<String> fontUrls = <String>[
      firaSansBoldUrl,
      firaSansItalicUrl,
      firaSansRegularUrl,
      firaSansThinUrl,
    ];

    DynamicCachedFonts.custom(
      cacheManager: cacheManager,
    );

    await DynamicCachedFonts.family(
      urls: fontUrls,
      fontFamily: firaSans,
    ).load();

    final List<FileInfo> fontFiles = await Future.wait(fontUrls.map(
      (String url) async {
        final String generatedCacheKey = url.replaceAll(RegExp(r'\/|:'), '');

        return cacheManager.getFileFromCache(generatedCacheKey);
      },
    ));

    expect(fontFiles.every((FileInfo file) => file != null), isTrue);
  });

  group('DynamicCachedFonts.fromFirebase constructor', () {
    FileInfo fontFile;

    setUpAll(() async {
      await Firebase.initializeApp();

      DynamicCachedFonts.custom(cacheManager: cacheManager);

      await DynamicCachedFonts.fromFirebase(
        bucketUrl: firebaseFontUrl,
        fontFamily: firebaseFontName,
      ).load();
      final String cacheKey = firebaseFontUrl.replaceAll(RegExp(r'\/|:'), '');

      fontFile = await cacheManager.getFileFromCache(cacheKey);
    });

    testWidgets('load() method parses Firebase Bucket Url and loads font', (_) async {
      expect(fontFile, isNotNull);
    });

    testWidgets('Font loader loads valid font file from Firebase', (_) async {
      final Reference bucketRef = FirebaseStorage.instance.refFromURL(firebaseFontUrl);

      expect(
        await fontFile.file.readAsBytes(),
        await bucketRef.getData(),
      );
    });
  });

  group('DynamicCachedFonts.cacheFont', () {
    FileInfo fontFile;

    setUpAll(() async {
      DynamicCachedFonts.custom(cacheManager: cacheManager);

      DynamicCachedFonts.cacheFont(fontUrl);

      fontFile = await cacheManager.getFileFromCache(cacheKey);
    });

    testWidgets('DynamicCachedFonts.cacheFont loads font into cache', (_) async {
      expect(fontFile, isNotNull);
    });

    testWidgets('DynamicCachedFonts.cacheFont loads font with a valid extension', (_) async {
      final String fontExtension = fontFile.file.uri.pathSegments.last.split('.').last;

      expect(fontExtension, 'ttf');
    });
  });

  group('DynamicCachedFonts.canLoadFont', () {
    setUpAll(() {
      DynamicCachedFonts.custom(cacheManager: cacheManager);
    });

    testWidgets('DynamicCachedFonts.canLoadFont returns true when font is available in cache',
        (_) async {
      await cacheManager.downloadFile(
        fontUrl,
        key: cacheKey,
      );

      expect(
        await DynamicCachedFonts.canLoadFont(fontUrl),
        true,
      );
    });

    testWidgets('DynamicCachedFonts.canLoadFont returns false when font is not available in cache',
        (_) async {
      await cacheManager.removeFile(cacheKey);

      expect(
        await DynamicCachedFonts.canLoadFont(fontUrl),
        false,
      );
    });
  });

  testWidgets('DynamicCachedFonts.removeCachedFont removes the font from cache', (_) async {
    await cacheManager.downloadFile(fontUrl, key: cacheKey);

    expect(
      await cacheManager.getFileFromCache(cacheKey),
      isNotNull,
    );

    DynamicCachedFonts.custom(cacheManager: cacheManager);

    await DynamicCachedFonts.removeCachedFont(fontUrl);

    expect(
      await cacheManager.getFileFromCache(cacheKey),
      isNull,
    );
  });
}
