import 'package:hive_flutter/hive_flutter.dart';
import '../models/memo_model.dart';
import '../../profile/services/user_service.dart';
import '../../../core/services/security_service.dart';

class MemoService {
  static const String boxName = 'memos_box_v2';

  static Future<void> init() async {
    await SecurityService.openEncryptedBox(boxName);
  }

  static List<Memo> getAllMemos() {
    final box = Hive.box(boxName);
    final String? currentUserId = UserService.currentUser?.id;
    if (currentUserId == null) return [];

    return box.values
        .map((e) => Memo.fromMap(Map<dynamic, dynamic>.from(e)))
        .where((e) => e.userId == currentUserId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> saveMemo(Memo memo) async {
    final box = Hive.box(boxName);
    await box.put(memo.id, memo.toMap());
  }

  static Future<void> deleteMemo(String id) async {
    final box = Hive.box(boxName);
    await box.delete(id);
  }
}
