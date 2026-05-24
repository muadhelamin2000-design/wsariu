import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:typed_data';

class SecurityService {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'hive_encryption_key';
  static final LocalAuthentication _auth = LocalAuthentication();
  
  static Uint8List? _cachedKey;

  /// تهيئة مفتاح التشفير أو استرجاعه
  static Future<Uint8List> getEncryptionKey() async {
    if (_cachedKey != null) return _cachedKey!;

    String? key = await _storage.read(key: _keyName);
    if (key == null) {
      final newKey = Hive.generateSecureKey();
      await _storage.write(key: _keyName, value: base64UrlEncode(newKey));
      _cachedKey = Uint8List.fromList(newKey);
    } else {
      _cachedKey = base64Url.decode(key);
    }
    return _cachedKey!;
  }

  /// التحقق من البصمة أو الـ PIN
  static Future<bool> authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      final List<BiometricType> enrolledBiometrics = await _auth.getAvailableBiometrics();

      debugPrint("Security: canBiometric=$canAuthenticateWithBiometrics, isSupported=$isDeviceSupported, enrolled=$enrolledBiometrics");

      // إذا كان الجهاز لا يدعم أي نوع من الحماية أو لا توجد بصمات مسجلة
      // سنسمح بالدخول مؤقتاً لتجنب قفل المستخدم خارج التطبيق
      if (!isDeviceSupported && enrolledBiometrics.isEmpty) {
        debugPrint("Security: No biometrics or device protection available. Bypassing lock.");
        return true;
      }

      return await _auth.authenticate(
        localizedReason: 'يرجى تأكيد هويتك للدخول إلى التطبيق حمايةً لخصوصيتك',
      );
    } catch (e) {
      debugPrint("Security: Authentication failed with error: $e");
      // في حالة حدوث خطأ تقني، نفتح التطبيق لكي لا يغضب المستخدم من القفل
      return true;
    }
  }

  /// فتح صندوق Hive مشفر
  static Future<Box<T>> openEncryptedBox<T>(String boxName) async {
    final key = await getEncryptionKey();
    return await Hive.openBox<T>(boxName, encryptionCipher: HiveAesCipher(key));
  }
}
