import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const String _androidApiKey = String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
  static const String _androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const String _androidMessagingSenderId = String.fromEnvironment('FIREBASE_ANDROID_MESSAGING_SENDER_ID');
  static const String _androidProjectId = String.fromEnvironment('FIREBASE_ANDROID_PROJECT_ID');
  static const String _androidDatabaseUrl = String.fromEnvironment('FIREBASE_ANDROID_DATABASE_URL');
  static const String _androidStorageBucket = String.fromEnvironment('FIREBASE_ANDROID_STORAGE_BUCKET');

  static const String _iosApiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const String _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const String _iosMessagingSenderId = String.fromEnvironment('FIREBASE_IOS_MESSAGING_SENDER_ID');
  static const String _iosProjectId = String.fromEnvironment('FIREBASE_IOS_PROJECT_ID');
  static const String _iosDatabaseUrl = String.fromEnvironment('FIREBASE_IOS_DATABASE_URL');
  static const String _iosStorageBucket = String.fromEnvironment('FIREBASE_IOS_STORAGE_BUCKET');
  static const String _iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

  static FirebaseOptions get currentPlatform {
    final options = maybeCurrentPlatform;
    if (options == null) {
      throw StateError(
        'Missing Firebase config for ${_platformName(defaultTargetPlatform)}. '
        'Run Flutter with --dart-define-from-file=config/firebase.json '
        'or use the platform Firebase config file.',
      );
    }
    return options;
  }

  static FirebaseOptions? get maybeCurrentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return maybeAndroid;
      case TargetPlatform.iOS:
        return maybeIos;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get android => maybeAndroid ?? _missingPlatformConfig('android');

  static FirebaseOptions? get maybeAndroid {
    if (!_hasAndroidConfig) {
      return null;
    }
    return FirebaseOptions(
      apiKey: _androidApiKey,
      appId: _androidAppId,
      messagingSenderId: _androidMessagingSenderId,
      projectId: _androidProjectId,
      databaseURL: _androidDatabaseUrl,
      storageBucket: _androidStorageBucket,
    );
  }

  static FirebaseOptions get ios => maybeIos ?? _missingPlatformConfig('iOS');

  static FirebaseOptions? get maybeIos {
    if (!_hasIosConfig) {
      return null;
    }
    return FirebaseOptions(
      apiKey: _iosApiKey,
      appId: _iosAppId,
      messagingSenderId: _iosMessagingSenderId,
      projectId: _iosProjectId,
      databaseURL: _iosDatabaseUrl,
      storageBucket: _iosStorageBucket,
      iosBundleId: _iosBundleId,
    );
  }

  static bool get _hasAndroidConfig =>
      _androidApiKey.isNotEmpty &&
      _androidAppId.isNotEmpty &&
      _androidMessagingSenderId.isNotEmpty &&
      _androidProjectId.isNotEmpty &&
      _androidDatabaseUrl.isNotEmpty &&
      _androidStorageBucket.isNotEmpty;

  static bool get _hasIosConfig =>
      _iosApiKey.isNotEmpty &&
      _iosAppId.isNotEmpty &&
      _iosMessagingSenderId.isNotEmpty &&
      _iosProjectId.isNotEmpty &&
      _iosDatabaseUrl.isNotEmpty &&
      _iosStorageBucket.isNotEmpty &&
      _iosBundleId.isNotEmpty;

  static Never _missingPlatformConfig(String platform) {
    throw StateError(
      'Missing Firebase config for $platform. '
      'Run Flutter with --dart-define-from-file=config/firebase.json '
      'or add the native Firebase config file for that platform.',
    );
  }

  static String _platformName(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}
