// ignore_for_file: public_member_api_docs
import 'dart:developer' as dev;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show required;

/// The name for for [dev.log].
const String kLoggerName = 'DynamicCachedFonts';

/// Logs a message to the console
void devLog(List<String> messageList, {@required bool verboseLog}) {
  if (verboseLog) {
    final String message = messageList.join('\n');
    dev.log(
      message,
      name: kLoggerName,
    );
  }
}

/// A class for [DynamicCachedFonts] which performs actions
/// which are not exposed as APIs.
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
        error: FlutterError(
          <String>[
            'The provided file format is not supported',
            'Received file format: $fileFormat',
          ].join('\n'),
        ),
        name: kLoggerName,
      );
      return false;
    }
  }

  static String sanitizeUrl(String url) => url.replaceAll(RegExp(r'\/|:'), '');
}
