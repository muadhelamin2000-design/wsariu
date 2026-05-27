import 'package:hive_flutter/hive_flutter.dart';
import '../models/personal_matters_models.dart';
import '../../profile/services/user_service.dart';
import 'package:uuid/uuid.dart';

class PersonalMattersService {
  static const String relBoxName = 'relationship_lists_box';
  static const String finBoxName = 'finance_box';
  static const String transBoxName = 'finance_transactions_box';
  static const String subBoxName = 'subscriptions_box';

  static Future<void> init() async {
    await Hive.openBox(relBoxName);
    await Hive.openBox(finBoxName);
    await Hive.openBox(transBoxName);
    await Hive.openBox(subBoxName);
  }

  // --- Relationships ---
  static List<RelationshipList> getRelationshipLists() {
    final box = Hive.box(relBoxName);
    return box.values
        .map((e) => RelationshipList.fromMap(Map<dynamic, dynamic>.from(e)))
        .toList();
  }

  static Future<void> saveRelationshipList(RelationshipList list) async {
    final box = Hive.box(relBoxName);
    await box.put(list.id, list.toMap());
  }

  static Future<void> deleteRelationshipList(String id) async {
    final box = Hive.box(relBoxName);
    await box.delete(id);
  }

  // --- Finance ---
  static FinanceSummary getFinanceSummary() {
    final box = Hive.box(finBoxName);
    final data = box.get('summary');
    if (data != null) {
      return FinanceSummary.fromMap(Map<dynamic, dynamic>.from(data));
    }
    return FinanceSummary();
  }

  static Future<void> saveFinanceSummary(FinanceSummary summary) async {
    final box = Hive.box(finBoxName);
    await box.put('summary', summary.toMap());
  }

  static List<FinanceTransaction> getTransactions() {
    final box = Hive.box(transBoxName);
    return box.values
        .map((e) => FinanceTransaction.fromMap(Map<dynamic, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> addTransaction(FinanceTransaction trans) async {
    final box = Hive.box(transBoxName);
    await box.put(trans.id, trans.toMap());
    await _recalculateBalance();
  }

  static Future<void> updateTransaction(FinanceTransaction oldTrans, FinanceTransaction newTrans) async {
    final box = Hive.box(transBoxName);
    await box.put(newTrans.id, newTrans.toMap());
    await _recalculateBalance();
  }

  static Future<void> deleteTransaction(String id) async {
    final box = Hive.box(transBoxName);
    await box.delete(id);
    await _recalculateBalance();
  }

  static Future<void> toggleSettled(String id) async {
    final box = Hive.box(transBoxName);
    final transMap = box.get(id);
    if (transMap != null) {
      final trans = FinanceTransaction.fromMap(Map<dynamic, dynamic>.from(transMap));
      await box.put(id, trans.copyWith(isSettled: !trans.isSettled).toMap());
      await _recalculateBalance();
    }
  }

  static Future<void> addDetailsToTransaction(String id, double additionalAmount, String detail) async {
    final box = Hive.box(transBoxName);
    final transMap = box.get(id);
    if (transMap != null) {
      final trans = FinanceTransaction.fromMap(Map<dynamic, dynamic>.from(transMap));
      List<String> newDetails = List.from(trans.details);
      newDetails.add(detail);
      final updated = trans.copyWith(
        amount: trans.amount + additionalAmount,
        details: newDetails,
      );
      await box.put(id, updated.toMap());
      await _recalculateBalance();
    }
  }

  static Future<void> _recalculateBalance() async {
    final transactions = getTransactions();
    final subscriptions = getSubscriptions();
    final summary = getFinanceSummary();
    
    double balance = 0;
    
    for (var t in transactions) {
      if (!t.isSettled) continue; // Only settled items affect "Cash"
      
      switch (t.type) {
        case FinanceType.income:
          balance += t.amount;
          break;
        case FinanceType.expense:
          balance -= t.amount;
          break;
        case FinanceType.debt:
          // Debt is settled = I paid my debt = money leaves my pocket
          balance -= t.amount;
          break;
        case FinanceType.owed:
          // Owed (Right) is settled = I received my money = money enters pocket
          balance += t.amount;
          break;
      }
    }
    
    // Deduct paid subscription months
    for (var sub in subscriptions) {
      balance -= (sub.amount * sub.paidMonths.length);
    }

    await saveFinanceSummary(FinanceSummary(
      currentBalance: balance,
      customExpenseCategories: summary.customExpenseCategories,
    ));
  }

  // --- Subscriptions ---
  static List<Subscription> getSubscriptions() {
    final box = Hive.box(subBoxName);
    return box.values
        .map((e) => Subscription.fromMap(Map<dynamic, dynamic>.from(e)))
        .toList();
  }

  static Future<void> saveSubscription(Subscription sub) async {
    final box = Hive.box(subBoxName);
    await box.put(sub.id, sub.toMap());
    await _recalculateBalance();
  }

  static Future<void> deleteSubscription(String id) async {
    final box = Hive.box(subBoxName);
    await box.delete(id);
    await _recalculateBalance();
  }

  static Future<void> toggleSubscriptionMonth(String subId, String monthKey) async {
    final box = Hive.box(subBoxName);
    final map = box.get(subId);
    if (map != null) {
      final sub = Subscription.fromMap(Map<dynamic, dynamic>.from(map));
      List<String> paid = List.from(sub.paidMonths);
      if (paid.contains(monthKey)) {
        paid.remove(monthKey);
      } else {
        paid.add(monthKey);
      }
      await saveSubscription(sub.copyWith(paidMonths: paid));
    }
  }

  static Future<void> processSubscriptions() async {
    // This could check for auto-deduct, but we'll stick to manual toggle per month for now as requested
    await _recalculateBalance();
  }
}
