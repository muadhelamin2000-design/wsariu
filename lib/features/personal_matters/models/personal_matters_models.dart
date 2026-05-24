import '../../discipline/models/habit_model.dart';

class RelationshipPerson {
  final String id;
  final String name;
  final String phone;
  final String subCategory;
  final DateTime? lastContacted;
  
  // Reminder Fields
  final ReminderType reminderType;
  final int? reminderHour;
  final int? reminderMinute;
  final int? flexibleStartHour;
  final int? flexibleEndHour;
  final int? flexibleCount;
  final String? linkedPrayer;
  final bool isRepeatable;

  RelationshipPerson({
    required this.id, 
    required this.name, 
    this.phone = '', 
    this.subCategory = '',
    this.lastContacted,
    this.reminderType = ReminderType.fixed,
    this.reminderHour,
    this.reminderMinute,
    this.flexibleStartHour,
    this.flexibleEndHour,
    this.flexibleCount,
    this.linkedPrayer,
    this.isRepeatable = true,
  });

  bool get contactedToday {
    if (lastContacted == null) return false;
    final now = DateTime.now();
    return lastContacted!.year == now.year &&
           lastContacted!.month == now.month &&
           lastContacted!.day == now.day;
  }

  RelationshipPerson copyWith({
    String? name, 
    String? phone, 
    String? subCategory, 
    DateTime? lastContacted, 
    bool clearLastContacted = false,
    ReminderType? reminderType,
    int? reminderHour,
    int? reminderMinute,
    int? flexibleStartHour,
    int? flexibleEndHour,
    int? flexibleCount,
    String? linkedPrayer,
    bool? isRepeatable,
    bool clearReminder = false,
  }) {
    return RelationshipPerson(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      subCategory: subCategory ?? this.subCategory,
      lastContacted: clearLastContacted ? null : (lastContacted ?? this.lastContacted),
      reminderType: reminderType ?? this.reminderType,
      reminderHour: clearReminder ? null : (reminderHour ?? this.reminderHour),
      reminderMinute: clearReminder ? null : (reminderMinute ?? this.reminderMinute),
      flexibleStartHour: clearReminder ? null : (flexibleStartHour ?? this.flexibleStartHour),
      flexibleEndHour: clearReminder ? null : (flexibleEndHour ?? this.flexibleEndHour),
      flexibleCount: clearReminder ? null : (flexibleCount ?? this.flexibleCount),
      linkedPrayer: clearReminder ? null : (linkedPrayer ?? this.linkedPrayer),
      isRepeatable: isRepeatable ?? this.isRepeatable,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'subCategory': subCategory,
    'lastContacted': lastContacted?.toIso8601String(),
    'reminderType': reminderType.index,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'flexibleStartHour': flexibleStartHour,
    'flexibleEndHour': flexibleEndHour,
    'flexibleCount': flexibleCount,
    'linkedPrayer': linkedPrayer,
    'isRepeatable': isRepeatable,
  };

  factory RelationshipPerson.fromMap(Map<dynamic, dynamic> map) => RelationshipPerson(
    id: map['id'],
    name: map['name'],
    phone: map['phone'] ?? '',
    subCategory: map['subCategory'] ?? '',
    lastContacted: map['lastContacted'] != null ? DateTime.parse(map['lastContacted']) : null,
    reminderType: ReminderType.values[map['reminderType'] ?? 0],
    reminderHour: map['reminderHour'],
    reminderMinute: map['reminderMinute'],
    flexibleStartHour: map['flexibleStartHour'],
    flexibleEndHour: map['flexibleEndHour'],
    flexibleCount: map['flexibleCount'],
    linkedPrayer: map['linkedPrayer'],
    isRepeatable: map['isRepeatable'] ?? true,
  );
}

class RelationshipList {
  final String id;
  final String title;
  final List<RelationshipPerson> members;
  
  // Reminder Fields
  final ReminderType reminderType;
  final int? reminderHour;
  final int? reminderMinute;
  final int? flexibleStartHour;
  final int? flexibleEndHour;
  final int? flexibleCount;
  final String? linkedPrayer;
  final bool isRepeatable;

  RelationshipList({
    required this.id, 
    required this.title, 
    required this.members,
    this.reminderType = ReminderType.fixed,
    this.reminderHour,
    this.reminderMinute,
    this.flexibleStartHour,
    this.flexibleEndHour,
    this.flexibleCount,
    this.linkedPrayer,
    this.isRepeatable = true,
  });

  int get contactedCount => members.where((m) => m.contactedToday).length;
  double get progress => members.isEmpty ? 0 : contactedCount / members.length;

  RelationshipList copyWith({
    String? title, 
    List<RelationshipPerson>? members,
    ReminderType? reminderType,
    int? reminderHour,
    int? reminderMinute,
    int? flexibleStartHour,
    int? flexibleEndHour,
    int? flexibleCount,
    String? linkedPrayer,
    bool? isRepeatable,
    bool clearReminder = false,
  }) {
    return RelationshipList(
      id: id,
      title: title ?? this.title,
      members: members ?? this.members,
      reminderType: reminderType ?? this.reminderType,
      reminderHour: clearReminder ? null : (reminderHour ?? this.reminderHour),
      reminderMinute: clearReminder ? null : (reminderMinute ?? this.reminderMinute),
      flexibleStartHour: clearReminder ? null : (flexibleStartHour ?? this.flexibleStartHour),
      flexibleEndHour: clearReminder ? null : (flexibleEndHour ?? this.flexibleEndHour),
      flexibleCount: clearReminder ? null : (flexibleCount ?? this.flexibleCount),
      linkedPrayer: clearReminder ? null : (linkedPrayer ?? this.linkedPrayer),
      isRepeatable: isRepeatable ?? this.isRepeatable,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'members': members.map((m) => m.toMap()).toList(),
    'reminderType': reminderType.index,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'flexibleStartHour': flexibleStartHour,
    'flexibleEndHour': flexibleEndHour,
    'flexibleCount': flexibleCount,
    'linkedPrayer': linkedPrayer,
    'isRepeatable': isRepeatable,
  };

  factory RelationshipList.fromMap(Map<dynamic, dynamic> map) => RelationshipList(
    id: map['id'],
    title: map['title'],
    members: (map['members'] as List).map((m) => RelationshipPerson.fromMap(m)).toList(),
    reminderType: ReminderType.values[map['reminderType'] ?? 0],
    reminderHour: map['reminderHour'],
    reminderMinute: map['reminderMinute'],
    flexibleStartHour: map['flexibleStartHour'],
    flexibleEndHour: map['flexibleEndHour'],
    flexibleCount: map['flexibleCount'],
    linkedPrayer: map['linkedPrayer'],
    isRepeatable: map['isRepeatable'] ?? true,
  );
}

enum FinanceType { income, expense, debt, owed }
enum Proximity { near, far }
enum Priority { important, normal, trivial }

class FinanceTransaction {
  final String id;
  final double amount;
  final FinanceType type;
  final String category;
  final String description;
  final DateTime date;
  final bool isSettled;
  final Proximity proximity;
  final Priority priority;

  FinanceTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    this.isSettled = true,
    this.proximity = Proximity.near,
    this.priority = Priority.normal,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'type': type.index,
    'category': category,
    'description': description,
    'date': date.toIso8601String(),
    'isSettled': isSettled,
    'proximity': proximity.index,
    'priority': priority.index,
  };

  factory FinanceTransaction.fromMap(Map<dynamic, dynamic> map) => FinanceTransaction(
    id: map['id'],
    amount: (map['amount'] as num).toDouble(),
    type: FinanceType.values[map['type'] ?? 1],
    category: map['category'] ?? '',
    description: map['description'] ?? '',
    date: DateTime.parse(map['date']),
    isSettled: map['isSettled'] ?? true,
    proximity: Proximity.values[map['proximity'] ?? 0],
    priority: Priority.values[map['priority'] ?? 1],
  );

  FinanceTransaction copyWith({
    double? amount,
    FinanceType? type,
    String? category,
    String? description,
    DateTime? date,
    bool? isSettled,
    Proximity? proximity,
    Priority? priority,
  }) {
    return FinanceTransaction(
      id: id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      isSettled: isSettled ?? this.isSettled,
      proximity: proximity ?? this.proximity,
      priority: priority ?? this.priority,
    );
  }
}

class FinanceSummary {
  final double currentBalance;
  final List<String> customExpenseCategories;

  FinanceSummary({
    this.currentBalance = 0,
    this.customExpenseCategories = const ['طعام', 'مواصلات', 'اشتراكات', 'أخرى'],
  });

  Map<String, dynamic> toMap() => {
    'currentBalance': currentBalance,
    'customExpenseCategories': customExpenseCategories,
  };

  factory FinanceSummary.fromMap(Map<dynamic, dynamic> map) => FinanceSummary(
    currentBalance: (map['currentBalance'] as num).toDouble(),
    customExpenseCategories: List<String>.from(map['customExpenseCategories'] ?? []),
  );
}

class Subscription {
  final String id;
  final String name;
  final double amount;
  final DateTime startDate;
  final List<String> paidMonths; // Format: "yyyy-MM"
  final bool autoDeduct;
  
  // Reminder Fields
  final ReminderType reminderType;
  final int? reminderHour;
  final int? reminderMinute;
  final int? flexibleStartHour;
  final int? flexibleEndHour;
  final int? flexibleCount;
  final String? linkedPrayer;
  final bool isRepeatable;

  Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.startDate,
    this.paidMonths = const [],
    this.autoDeduct = true,
    this.reminderType = ReminderType.fixed,
    this.reminderHour,
    this.reminderMinute,
    this.flexibleStartHour,
    this.flexibleEndHour,
    this.flexibleCount,
    this.linkedPrayer,
    this.isRepeatable = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'amount': amount,
    'startDate': startDate.toIso8601String(),
    'paidMonths': paidMonths,
    'autoDeduct': autoDeduct,
    'reminderType': reminderType.index,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'flexibleStartHour': flexibleStartHour,
    'flexibleEndHour': flexibleEndHour,
    'flexibleCount': flexibleCount,
    'linkedPrayer': linkedPrayer,
    'isRepeatable': isRepeatable,
  };

  factory Subscription.fromMap(Map<dynamic, dynamic> map) => Subscription(
    id: map['id'],
    name: map['name'],
    amount: (map['amount'] as num).toDouble(),
    startDate: DateTime.parse(map['startDate'] ?? DateTime.now().toIso8601String()),
    paidMonths: List<String>.from(map['paidMonths'] ?? []),
    autoDeduct: map['autoDeduct'] ?? true,
    reminderType: ReminderType.values[map['reminderType'] ?? 0],
    reminderHour: map['reminderHour'],
    reminderMinute: map['reminderMinute'],
    flexibleStartHour: map['flexibleStartHour'],
    flexibleEndHour: map['flexibleEndHour'],
    flexibleCount: map['flexibleCount'],
    linkedPrayer: map['linkedPrayer'],
    isRepeatable: map['isRepeatable'] ?? true,
  );

  Subscription copyWith({
    String? name,
    double? amount,
    DateTime? startDate,
    List<String>? paidMonths,
    bool? autoDeduct,
    ReminderType? reminderType,
    int? reminderHour,
    int? reminderMinute,
    int? flexibleStartHour,
    int? flexibleEndHour,
    int? flexibleCount,
    String? linkedPrayer,
    bool? isRepeatable,
    bool clearReminder = false,
  }) {
    return Subscription(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      paidMonths: paidMonths ?? this.paidMonths,
      autoDeduct: autoDeduct ?? this.autoDeduct,
      reminderType: reminderType ?? this.reminderType,
      reminderHour: clearReminder ? null : (reminderHour ?? this.reminderHour),
      reminderMinute: clearReminder ? null : (reminderMinute ?? this.reminderMinute),
      flexibleStartHour: clearReminder ? null : (flexibleStartHour ?? this.flexibleStartHour),
      flexibleEndHour: clearReminder ? null : (flexibleEndHour ?? this.flexibleEndHour),
      flexibleCount: clearReminder ? null : (flexibleCount ?? this.flexibleCount),
      linkedPrayer: clearReminder ? null : (linkedPrayer ?? this.linkedPrayer),
      isRepeatable: isRepeatable ?? this.isRepeatable,
    );
  }
}
