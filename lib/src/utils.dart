import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:meta/meta.dart';

/// Gets the sanitized url from [url] which is used as `cacheKey` when
/// downloading, caching or loading.
@visibleForTesting
String cacheKeyFromUrl(String url) => Utils.sanitizeUrl(url);

/// The name for for [dev.log].
@internal
const String kLoggerName = 'DynamicCachedFonts';

/// The default `cacheStalePeriod`.
const Duration kDefaultCacheStalePeriod = Duration(days: 365);

/// The default `maxCacheObjects`.
const int kDefaultMaxCacheObjects = 200;

/// Logs a message to the console.
@internal
void devLog(List<String> messageList, {@required bool verboseLog}) {
  if (verboseLog) {
    final String message = messageList.join('\n');
    dev.log(
      message,
      name: kLoggerName,
    );
  }
}

/// A class to manage [CacheManager]s used throughout the package.
/// This approach prevents the creation of multiple instance of [CacheManager] using
/// the same [Config.cacheKey].`
///
/// When `cacheStalePeriod` or `maxCacheObjects` is not modified, a default instance
/// of [CacheManager] is created when a font cache/load is requested. This instance
/// assigns [_defaultCacheKey] to [Config.cacheKey], [kDefaultCacheStalePeriod]
/// to [Config.stalePeriod] and [kDefaultMaxCacheObjects] to [Config.maxNrOfCacheObjects].
/// The instance is added to [_cacheManagers] with [_defaultCacheKey] as the key.
///
/// The default instance can be easily accessed with [defaultCacheManager].
///
/// When caching/loading a font, if `cacheStalePeriod` or `maxCacheObjects` is modified
/// by the caller, a new instance of [CacheManager] is created and added to [_cacheManagers].
/// This instance uses the sanitized url (see [Utils.sanitizeUrl]) as [Config.cacheKey] and
/// as the key when adding the instance to [_cacheManagers].
@internal
class DynamicCachedFontsCacheManager {
  DynamicCachedFontsCacheManager._();

  /// The default cache key for cache managers' configurations
  static const String _defaultCacheKey = 'DynamicCachedFontsFontCacheKey';

  /// A map of [CacheManager]s used throughout the package. The key used
  /// will correspond to [Config.cacheKey] of the respective [CacheManager].
  static final Map<String, CacheManager> _cacheManagers = <String, CacheManager>{
    _defaultCacheKey: CacheManager(
      Config(
        _defaultCacheKey,
        stalePeriod: kDefaultCacheStalePeriod,
        maxNrOfCacheObjects: kDefaultMaxCacheObjects,
      ),
    ),
  };

  static String _customCacheKey;

  /// The getter for the default instance of [CacheManager] in [_cacheManagers].
  static CacheManager get defaultCacheManager => _cacheManagers[_defaultCacheKey];

  /// The getter for the custom instance of [CacheManager] in [_cacheManagers].
  static CacheManager get customCacheManager => _cacheManagers[_customCacheKey];

  /// The setter for the custom instance of [CacheManager] in [_cacheManagers].
  /// [Config.cacheKey] will be used as the key when adding the instance to
  /// [_cacheManagers].
  static set customCacheManager(CacheManager cacheManager) {
    _customCacheKey =
        cacheManager.store.storeKey; // This is the same key provided to Config.cacheKey.
    _cacheManagers[_customCacheKey] = cacheManager;
  }
  }
}

class _FontFileExtensionManager {
  _FontFileExtensionManager();

  final Map<String, List<int>> _validExtensions = <String, List<int>>{};

  void addExtension({String extension, List<int> magicNumber}) {
    _validExtensions[extension] = magicNumber;
  }

  bool matchesFileExtension(String path, Uint8List fileBytes) {
    String fontExtension;

    final int index = path.lastIndexOf('.');
    if (index < 0 || index + 1 >= path.length) fontExtension = '';
    fontExtension = path.substring(index + 1).toLowerCase();

    final List<int> headerBytes = fileBytes.sublist(0, 5).toList();

    return _validExtensions.keys.contains(fontExtension) ||
        _validExtensions.values.any(
          (List<int> magicNumber) => listEquals(headerBytes, magicNumber),
        );
  }
}

/// A class for [DynamicCachedFonts] which performs actions which are not exposed as APIs.
@internal
class Utils {
  Utils._();

  static final _FontFileExtensionManager _fontFileExtensionManager = _FontFileExtensionManager()
    ..addExtension(
      extension: 'ttf',
      magicNumber: <int>[
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
      ],
    )
    ..addExtension(
      extension: 'otf',
      magicNumber: <int>[
        0x4F,
        0x54,
        0x54,
        0x4F,
        0x00,
      ],
    );

  /// Checks whether the received [url] is a Cloud Storage url or an https url.
  /// If the url points to a Cloud Storage bucket, then a download url
  /// is generated using the Firebase SDK.
  static Future<String> handleUrl(
    String url, {
    @required bool verboseLog,
  }) async {
    final Reference ref = FirebaseStorage.instance.refFromURL(url);

    devLog(
      <String>[
        'Created Firebase Storage reference with following values -\n',
        'Bucket name - ${ref.bucket}',
        'Object name - ${ref.name}',
        'Object path - ${ref.fullPath}',
      ],
      verboseLog: verboseLog,
    );

    return ref.getDownloadURL();
  }

  /// Checks whether the [font] has a valid extension which is supported by Flutter.
  static bool verifyFileExtension(File font) {
    if (_fontFileExtensionManager.matchesFileExtension(font.basename, font.readAsBytesSync())) {
      return true;
    } else {
      dev.log(
        'Bad File Format',
        error: <String>['The provided file format is not supported'],
        name: kLoggerName,
      );
      return false;
    }
  }

  /// Remove `/` or `:` from url which can cause errors when used as storage paths
  /// in some operating systems.
  static String sanitizeUrl(String url) => url.replaceAll(RegExp(r'\/|:'), '');

  /// Returns a custom [CacheManager], if present, or
  static CacheManager getCacheManager(String cacheKey) =>
      DynamicCachedFontsCacheManager.customCacheManager ??
      DynamicCachedFontsCacheManager.cacheManagers[cacheKey] ??
      DynamicCachedFontsCacheManager.defaultCacheManager;

  /// Creates a new instance of [CacheManager] if the default can't be used.
  static void handleCacheManager(String cacheKey, Duration cacheStalePeriod, int maxCacheObjects) {
    if (cacheStalePeriod != kDefaultCacheStalePeriod ||
        maxCacheObjects != kDefaultMaxCacheObjects) {
      DynamicCachedFontsCacheManager.cacheManagers[cacheKey] ??= CacheManager(
        Config(
          cacheKey,
          stalePeriod: cacheStalePeriod,
          maxNrOfCacheObjects: maxCacheObjects,
        ),
      );
    }
  }
}
