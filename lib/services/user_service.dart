import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'dart:io' show Platform;

class UserService {
  static final _log = Logger('UserService');
  static const _userIdKey = 'user_id';
  static UserService? _instance;
  late final SharedPreferences _prefs;
  
  UserService._();
  
  static Future<UserService> getInstance() async {
    if (_instance == null) {
      _instance = UserService._();
      await _instance!._init();
    }
    return _instance!;
  }
  
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<String> getUserId() async {
    String? userId = _prefs.getString(_userIdKey);
    
    if (userId == null) {
      userId = await _generateDeviceId();
      await _prefs.setString(_userIdKey, userId);
      _log.info('새로운 사용자 ID 생성: $userId');
    }
    
    return userId;
  }

  Future<String> _generateDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios_device';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else {
        final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
        _log.warning('지원되지 않는 플랫폼. 타임스탬프 사용: $deviceId');
        return deviceId;
      }
    } catch (e, stackTrace) {
      _log.severe('디바이스 ID 생성 실패', e, stackTrace);
      return 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
} 