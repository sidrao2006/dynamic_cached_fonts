import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/cache_store.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:mockito/mockito.dart';

class _FakeCacheStore extends Fake implements CacheStore {}

/// A class which mocks [CacheManager].
class MockCacheManager extends Mock implements CacheManager {
  @override
  CacheStore get store =>
      super.noSuchMethod(Invocation.getter(#store), returnValue: _FakeCacheStore()) as CacheStore;

  @override
  Future<void> removeFile(String? key) async =>
      super.noSuchMethod(Invocation.method(#removeFile, [key]));
}

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async {
    return './mocked/temp';
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return './mocked/app_support';
  }
}
