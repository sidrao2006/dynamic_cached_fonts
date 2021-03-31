import 'dart:developer' as dev;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show required;
import 'package:flutter_cache_manager/flutter_cache_manager.dart' show CacheManager, Config;

/// The name for for [dev.log].
const String kLoggerName = 'DynamicCachedFonts';

/// The default `cacheStalePeriod`.
const Duration kDefaultCacheStalePeriod = Duration(days: 365);

/// The default `maxCacheObjects`.
const int kDefaultMaxCacheObjects = 200;

/// Logs a message to the console.
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
/// assigns [defaultCacheKey] to [Config.cacheKey], [kDefaultCacheStalePeriod]
/// to [Config.stalePeriod] and [kDefaultMaxCacheObjects] to [Config.maxNrOfCacheObjects].
/// The instance is added to [cacheManagers] with [defaultCacheKey] as the key.
///
/// The default instance can be easily accessed with [defaultCacheManager].
///
/// When caching/loading a font, if `cacheStalePeriod` or `maxCacheObjects` is modified
/// by the caller, a new instance of [CacheManager] is created and added to [cacheManagers].
/// This instance uses the sanitized url (see [Utils.sanitizeUrl]) as [Config.cacheKey] and
/// as the key when adding the instance to [cacheManagers].
class DynamicCachedFontsCacheManager {
  DynamicCachedFontsCacheManager._();

  /// The default cache key for cache managers' configurations
  static const String defaultCacheKey = 'DynamicCachedFontsFontCacheKey';

  /// A map of [CacheManager]s used throughout the package. The key used
  /// will correspond to [Config.cacheKey] of the respective [CacheManager].
  static Map<String, CacheManager> cacheManagers = <String, CacheManager>{
    defaultCacheKey: CacheManager(
      Config(
        DynamicCachedFontsCacheManager.defaultCacheKey,
        stalePeriod: kDefaultCacheStalePeriod,
        maxNrOfCacheObjects: kDefaultMaxCacheObjects,
      ),
    ),
  };

  /// The getter for the default instance of [CacheManager] in [cacheManagers].
  static CacheManager get defaultCacheManager => cacheManagers[defaultCacheKey];
}

/// Returns a custom [CacheManager], if present, or
CacheManager getCacheManager(String cacheKey) =>
    DynamicCachedFontsCacheManager.cacheManagers[cacheKey] ??
    DynamicCachedFontsCacheManager.defaultCacheManager;

/// Creates a new instance of [CacheManager] if the default can't be used.
void handleCacheManager(String cacheKey, Duration cacheStalePeriod, int maxCacheObjects) {
  if (cacheStalePeriod != kDefaultCacheStalePeriod && maxCacheObjects != kDefaultMaxCacheObjects) {
    DynamicCachedFontsCacheManager.cacheManagers[cacheKey] ??= CacheManager(
      Config(
        cacheKey,
        stalePeriod: cacheStalePeriod,
        maxNrOfCacheObjects: maxCacheObjects,
      ),
    );
  }
}

/// A class for [DynamicCachedFonts] which performs actions which are not exposed as APIs.
class Utils {
  Utils._();

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

  /// Checks whether the [fileFormat] is valid and supported by flutter.
  static bool verifyFileFormat(String url) {
    final String fileName = Uri.parse(url).pathSegments.last;
    final String fileFormat = fileName.split('.').last;

    if (fileFormat == 'otf' || fileFormat == 'ttf') {
      return true;
    } else {
      dev.log(
        'Bad File Format',
        error: <String>[
          'The provided file format is not supported',
          'Received file format: $fileFormat',
        ].join('\n'),
        name: kLoggerName,
      );
      return false;
    }
  }

  /// Remove `/` or `:` from url which can cause errors when used as storage paths
  /// in some operating systems.
  static String sanitizeUrl(String url) => url.replaceAll(RegExp(r'\/|:'), '');
}
