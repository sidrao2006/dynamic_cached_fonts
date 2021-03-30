/// An asset loader which dynamically loads font from the given url and caches it.
/// It can be easily fetched from cache and loaded on demand.
library dynamic_cached_fonts;

import 'dart:typed_data' show Uint8List;

import 'package:file/file.dart' show File;
import 'package:flutter/foundation.dart' show kReleaseMode, FlutterError;
import 'package:flutter/services.dart' show ByteData, FontLoader;
import 'package:flutter/widgets.dart'
    show TextStyle, WidgetsFlutterBinding, required, FontWeight, FontStyle;
import 'package:flutter_cache_manager/flutter_cache_manager.dart' show CacheManager, Config;

import 'src/raw_dynamic_cached_fonts.dart' show RawDynamicCachedFonts;
import 'src/utils.dart' show Utils, devLog;

export 'src/raw_dynamic_cached_fonts.dart';

/// Allows dynamically loading fonts from the given url.
///
/// Fetching fonts from Firebase Storage is also supported.
///
/// For ready to use, simple interface, initialize [DynamicCachedFonts] and call
/// the [load] method either in you `initState()` or just before `runApp()` itself.
///
/// ```dart
/// class _SomeStateFulWidgetState extends State<_SomeStateFulWidget> {
///   @override
///   void initState() {
///     const DynamicCachedFonts dynamicCachedFont = DynamicCachedFonts(
///       fontFamily: 'font',
///       url: // Add url to a font
///     );
///     dynamicCachedFont.load();
///
///     super.initState();
///   }
/// ```
///
/// ```dart
/// void main() async {
///   final DynamicCachedFont dynamicCachedFont = DynamicCachedFont(
///     fontFamily: 'font',
///     url: // Add url to a font
///   );
///   dynamicCachedFont.load();
///
///   runApp(
///     YourAppHere(
///       ...
///       TextStyle(
///         fontFamily: 'font'
///       ),
///       ...
///     ),
///   );
/// }
/// ```
///
/// For greater customization, use static methods.
///
/// - [cacheFont] to download a font file and cache it.
/// - [canLoadFont] to check whether a font is available
///   and can be used by calling [loadCachedFont].
/// - [loadCachedFont] to load a downloaded font.
/// - [removeCachedFont] to delete the font file.
class DynamicCachedFonts {
  /// Allows dynamically loading fonts from the given url and caching them.
  ///
  /// - **REQUIRED** The [url] property is used to specify the download url
  ///   for the required font. It should be a valid http/https url which points to
  ///   a font file.
  ///   Currently, only OpenType (OTF) and TrueType (TTF) fonts are supported.
  ///
  /// - **REQUIRED** The [fontFamily] property is used to specify the name
  ///   of the font family which is to be used as [TextStyle.fontFamily].
  ///
  /// - The [maxCacheObjects] property defines how large the cache is allowed to be.
  ///   If there are more files the files that haven't been used for the longest
  ///   time will be removed.
  ///
  ///   It is used to specify the cache configuration, [Config],
  ///   for [CacheManager].
  ///
  /// - [cacheStalePeriod] is the time duration in which
  ///   a cache object is considered 'stale'. When a file is cached but
  ///   not being used for a certain time the file will be deleted
  ///
  ///   Defaults to 365 days.
  ///
  ///   It is used to specify the cache configuration, [Config],
  ///   for [CacheManager].
  ///
  /// - The [verboseLog] is a debug property used to specify whether detailed
  ///   logs should be printed for debugging.
  ///
  ///   Defaults to false.
  ///
  ///   _Tip: To log only in debug mode, set [verboseLog]'s value to [kReleaseMode]_.
  DynamicCachedFonts({
    @required String url,
    @required this.fontFamily,
    this.maxCacheObjects = 200,
    this.cacheStalePeriod = const Duration(days: 365),
    bool verboseLog = false,
  })  : assert(
          fontFamily != null && fontFamily != '',
          'fontFamily cannot be null or empty',
        ),
        assert(
          url != null && url != '',
          'url cannot be null or empty',
        ),
        assert(verboseLog != null),
        urls = <String>[url],
        _fontLoader = FontLoader(fontFamily),
        _verboseLog = verboseLog,
        _isFirebaseURL = false;

  /// Allows dynamically loading fonts from the given list of url and caching them.
  /// The [fontFamily] groups a series of related font assets, each of which defines
  /// how to render a specific [FontWeight] and [FontStyle] within the family.
  ///
  /// - **REQUIRED** The [urls] property is used to specify the download urls
  ///   for the required fonts. It should be a list of valid http/https urls
  ///   which point to font files.
  ///
  ///   Currently, only OpenType (OTF) and TrueType (TTF) fonts are supported.
  ///
  /// - **REQUIRED** The [fontFamily] property is used to specify the name
  ///   of the font family which is to be used as [TextStyle.fontFamily].
  ///
  /// - The [maxCacheObjects] property defines how large the cache is allowed to be.
  ///   If there are more files the files that haven't been used for the longest
  ///   time will be removed.
  ///
  ///   It is used to specify the cache configuration, [Config],
  ///   for [CacheManager].
  ///
  /// - [cacheStalePeriod] is the time duration in which
  ///   a cache object is considered 'stale'. When a file is cached but
  ///   not being used for a certain time the file will be deleted
  ///
  ///   Defaults to 365 days.
  ///
  ///   It is used to specify the cache configuration, [Config],
  ///   for [CacheManager].
  ///
  /// - The [verboseLog] is a debug property used to specify whether detailed
  ///   logs should be printed for debugging.
  ///
  ///   Defaults to false.
  ///
  ///   _Tip: To log only in debug mode, set [verboseLog]'s value to [kReleaseMode]_.
  DynamicCachedFonts.family({
    @required this.urls,
    @required this.fontFamily,
    this.maxCacheObjects = 200,
    this.cacheStalePeriod = const Duration(days: 365),
    bool verboseLog = false,
  })  : assert(
          fontFamily != null && fontFamily != '',
          'fontFamily cannot be null or empty',
        ),
        assert(
          urls.length > 1,
          'At least 2 urls have to be provided. To load a single font url, use the default constructor',
        ),
        assert(
          urls.every(
            (String url) => url != null && url != '',
          ),
          'url cannot be null or empty',
        ),
        assert(verboseLog != null),
        _fontLoader = FontLoader(fontFamily),
        _verboseLog = verboseLog,
        _isFirebaseURL = false;

  /// Allows dynamically loading fonts from firebase storage with the given
  /// firebase storage url, and caching them.
  ///
  /// _**Firebase app must be initialized before loading the font!!**_
  ///
  /// - **REQUIRED** The [bucketUrl] property is used to specify the download url
  ///   for the required font. It should be a valid Google Cloud Storage (gs://) url
  ///   which points to a font file.
  ///   Currently, only OpenType (OTF) and TrueType (TTF) fonts are supported.
  ///
  /// - **REQUIRED** The [fontFamily] property is used to specify the name
  ///   of the font family which is to be used as [TextStyle.fontFamily].
  ///
  /// - The [maxCacheObjects] property defines how large the cache is allowed to be.
  ///   If there are more files the files that haven't been used for the longest
  ///   time will be removed.
  ///
  ///   It is used to specify the cache configuration, [Config],
  ///   for [CacheManager].
  ///
  /// - [cacheStalePeriod] is the time duration in which
  ///   a cache object is considered 'stale'. When a file is cached but
  ///   not being used for a certain time the file will be deleted
  ///
  ///   Defaults to 365 days.
  ///
  ///   It is used to specify the cache configuration, [Config],
  ///   for [CacheManager].
  ///
  /// - The [verboseLog] is a debug property used to specify whether detailed
  ///   logs should be printed for debugging.
  ///
  ///   Defaults to false.
  ///
  ///   _Tip: To log only in debug mode, set [verboseLog]'s value to [kReleaseMode]_.
  DynamicCachedFonts.fromFirebase({
    @required String bucketUrl,
    @required this.fontFamily,
    this.maxCacheObjects = 200,
    this.cacheStalePeriod = const Duration(days: 365),
    bool verboseLog = false,
  })  : assert(
          fontFamily != null && fontFamily != '',
          'fontFamily cannot be null or empty',
        ),
        assert(
          bucketUrl != null && bucketUrl != '',
          'bucketUrl cannot be null or empty',
        ),
        assert(verboseLog != null),
        _fontLoader = FontLoader(fontFamily),
        _verboseLog = verboseLog,
        urls = <String>[bucketUrl],
        _isFirebaseURL = true;

  /// Used to specify the download url(s) for the required font(s).
  ///
  /// It should be a valid http/https url or a Google Cloud Storage (gs://) url,
  /// when using [DynamicCachedFonts.fromFirebase], which points to
  /// a font file.
  ///
  /// Currently, only OpenType (OTF) and TrueType (TTF) fonts are supported.
  ///
  /// To load multiple fonts in a family, use [DynamicCachedFonts.family].
  final List<String> urls;

  /// Used to specify the name of the font family
  /// which is to be used as [TextStyle.fontFamily].
  final String fontFamily;

  /// Defines how large the cache is allowed to be.
  ///
  /// If there are more files the files that haven't been used for the longest
  /// time will be removed.
  ///
  /// It is used to specify the cache configuration, [Config],
  /// for [CacheManager].
  final int maxCacheObjects;

  /// The time duration in which
  /// a cache object is considered 'stale'. When a file is cached but
  /// not being used for a certain time the file will be deleted
  ///
  /// Defaults to 365 days.
  ///
  /// It is used to specify the cache configuration, [Config],
  /// for [CacheManager].
  final Duration cacheStalePeriod;

  /// A debug property used to specify whether detailed
  /// logs should be printed for debugging.
  ///
  /// Defaults to false.
  ///
  /// _Tip: To log only in debug mode, set the value to [kReleaseMode]_.
  final bool _verboseLog;

  /// Font loader provided by the SDK to add fonts to the engine,
  /// link them to a font name and load them on demand. The [load] method
  /// calls [FontLoader.load] to load the fonts into the engine.
  final FontLoader _fontLoader;

  /// Determines whether [url] is a firebase storage bucket url.
  final bool _isFirebaseURL;

  /// Used to download and load a font into the
  /// app with the given [url] and cache configuration.
  ///
  /// This method can be called in `main()`, `initState()` or on button tap/click
  /// as needed.
  Future<void> load() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (!urls.every(
      (String url) => Utils.verifyFileFormat(url),
    )) {
      throw FlutterError(
        'Invalid url. Unsupported file format. Supported file formats - otf and ttf',
      );
    }

    final Iterable<Future<ByteData>> cachedFontBytes = urls.map(
      (String url) => _handleCache(url),
    );

    if (_verboseLog)
      devLog(
        <String>['Font has been downloaded and cached!'],
        verboseLog: _verboseLog,
      );

    for (final Future<ByteData> bytes in cachedFontBytes) _fontLoader.addFont(bytes);
    await _fontLoader.load();

    devLog(
      <String>['Font has been loaded!'],
      verboseLog: _verboseLog,
    );
  }

  /// Uses [CacheManager.getSingleFile] to either download the file
  /// if it isn't in the cache, or returns the file (as bytes) from cache.
  Future<ByteData> _handleCache(String url) async {
    final String cacheKey = Utils.sanitizeUrl(url);

    final Config cacheConfig = Config(
      cacheKey,
      stalePeriod: cacheStalePeriod,
      maxNrOfCacheObjects: maxCacheObjects,
    );

    final String downloadUrl =
        _isFirebaseURL ? await Utils.handleUrl(url, verboseLog: _verboseLog) : url;

    final File font = await CacheManager(cacheConfig).getSingleFile(
      downloadUrl,
      key: cacheKey,
    );

    devLog(
      <String>[
        'Font has been downloaded!\n',
        'Font file path - ${font.path}',
        font.statSync().toString(),
      ],
      verboseLog: _verboseLog,
    );

    final Uint8List fontBytes = await font.readAsBytes();

    return ByteData.view(fontBytes.buffer);
  }

  /// Downloads and caches font from the [url] with the given configuration.
  ///
  /// - **REQUIRED** The [url] property is used to specify the download url
  ///   for the required font. It should be a valid http/https url which points to
  ///   a font file.
  ///   Currently, only OpenType (OTF) and TrueType (TTF) fonts are supported.
  ///
  /// - The [maxCacheObjects] property defines how large the cache is allowed to be.
  ///   If there are more files the files that haven't been used for the longest
  ///   time will be removed.
  ///
  ///   It is used to specify the cache configuration, [Config],
  ///   for [CacheManager].
  ///
  /// - [cacheStalePeriod] is the time duration in which
  ///   a cache object is considered 'stale'. When a file is cached but
  ///   not being used for a certain time the file will be deleted
  ///
  ///   Defaults to 365 days.
  ///
  ///   It is used to specify the cache configuration, [Config],
  ///   for [CacheManager].
  ///
  /// - The [verboseLog] is a debug property used to specify whether detailed
  ///   logs should be printed for debugging.
  ///
  ///   Defaults to false.
  ///
  ///   _Tip: To log only in debug mode, set [verboseLog]'s value to [kReleaseMode]_.
  static Future<void> cacheFont(
    String url, {
    Duration cacheStalePeriod = const Duration(days: 365),
    int maxCacheObjects = 200,
    bool verboseLog = false,
  }) =>
      RawDynamicCachedFonts.cacheFont(
        url,
        cacheStalePeriod: cacheStalePeriod,
        maxCacheObjects: maxCacheObjects,
        verboseLog: verboseLog,
      );

  /// Checks whether the given [url] can be loaded directly from cache.
  ///
  /// - **REQUIRED** The [url] property is used to specify the url
  ///   for the required font. It should be a valid http/https url which points to
  ///   a font file. The [url] should match the url passed to [cacheFont].
  ///
  /// - The [verboseLog] is a debug property used to specify whether detailed
  ///   logs should be printed for debugging.
  ///
  ///   Defaults to false.
  ///
  ///   _Tip: To log only in debug mode, set [verboseLog]'s value to [kReleaseMode]_.
  static Future<bool> canLoadFont(
    String url, {
    bool verboseLog = false,
  }) =>
      RawDynamicCachedFonts.canLoadFont(
        url,
        verboseLog: verboseLog,
      );

  /// Fetches the given [url] from cache and loads it as an asset.
  ///
  /// - **REQUIRED** The [url] property is used to specify the url
  ///   for the required font. It should be a valid http/https url which points to
  ///   a font file. The [url] should match the url passed to [cacheFont].
  ///
  /// - **REQUIRED** The [fontFamily] property is used to specify the name
  ///   of the font family which is to be used as [TextStyle.fontFamily].
  ///
  /// - The [verboseLog] is a debug property used to specify whether detailed
  ///   logs should be printed for debugging.
  ///
  ///   Defaults to false.
  ///
  ///   _Tip: To log only in debug mode, set [verboseLog]'s value to [kReleaseMode]_.
  static Future<void> loadCachedFont(
    String url, {
    @required String fontFamily,
    bool verboseLog = false,
  }) =>
      RawDynamicCachedFonts.loadCachedFont(
        url,
        fontFamily: fontFamily,
        verboseLog: verboseLog,
      );

  /// Fetches the given [urls] from cache and loads them into the engine to be used.
  ///
  /// [urls] should be a series of related font assets,
  /// each of which defines how to render a specific [FontWeight] and [FontStyle]
  /// within the family.
  ///
  /// Call [canLoadFont] before calling this method to make sure the font is
  /// available in cache.
  ///
  /// - **REQUIRED** The [urls] property is used to specify the urls
  ///   for the required family. It should be a list of valid http/https urls
  ///   which point to font files.
  ///   Every url in [urls] should be loaded into cache by calling [cacheFont] for each.
  ///
  /// - **REQUIRED** The [fontFamily] property is used to specify the name
  ///   of the font family which is to be used as [TextStyle.fontFamily].
  ///
  /// - The [verboseLog] is a debug property used to specify whether detailed
  ///   logs should be printed for debugging.
  ///
  ///   Defaults to false.
  ///
  ///   _Tip: To log only in debug mode, set [verboseLog]'s value to [kReleaseMode]_.
  static Future<void> loadCachedFamily(
    List<String> urls, {
    @required String fontFamily,
    bool verboseLog = false,
  }) =>
      RawDynamicCachedFonts.loadCachedFamily(
        urls,
        fontFamily: fontFamily,
      );

  /// Removes the given [url] can be loaded directly from cache.
  ///
  /// - **REQUIRED** The [url] property is used to specify the url
  ///   for the required font. It should be a valid http/https url which points to
  ///   a font file. The [url] should match the url passed to [cacheFont].
  static Future<void> removeCachedFont(String url) => RawDynamicCachedFonts.removeCachedFont(
        url,
      );
}
