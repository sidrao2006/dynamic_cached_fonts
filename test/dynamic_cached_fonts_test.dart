

import 'package:dynamic_cached_fonts/dynamic_cached_fonts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String firebaseMockUrl = 'gs://mockurl.appspot.com/a.ttf';
  const String mockUrl = 'https://example.com/font.ttf';
  const String mockFontFamily = 'FontFamily';

  test('Default constructor applies default values', () {
    final DynamicCachedFonts fontLoader =
        DynamicCachedFonts(url: mockUrl, fontFamily: mockFontFamily);

    expect(fontLoader.urls.length, 1);
    expect(fontLoader.maxCacheObjects, 200);
    expect(fontLoader.cacheStalePeriod, const Duration(days: 365));
  });

  test('Firebase constructor applies default values', () {
    final DynamicCachedFonts fontLoader = DynamicCachedFonts.fromFirebase(
      bucketUrl: firebaseMockUrl,
      fontFamily: 'Font',
    );

    expect(fontLoader.urls.length, 1);
    expect(fontLoader.maxCacheObjects, 200);
    expect(fontLoader.cacheStalePeriod, const Duration(days: 365));
  });
}
