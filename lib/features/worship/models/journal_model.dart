enum SoulState { calm, fluctuating, weak }

class MistakeWithEffect {
  final String mistake;
  final String effect;
  final int colorValue;

  MistakeWithEffect({
    required this.mistake, 
    required this.effect,
    this.colorValue = 0xFF000000,
  });

  Map<String, dynamic> toMap() => {
    'mistake': mistake, 
    'effect': effect,
    'colorValue': colorValue,
  };
  
  factory MistakeWithEffect.fromMap(Map<dynamic, dynamic> map) => MistakeWithEffect(
    mistake: map['mistake'] ?? '',
    effect: map['effect'] ?? '',
    colorValue: map['colorValue'] ?? 0xFF000000,
  );
}

class JournalEntry {
  final String id;
  final String userId;
  final DateTime date;
  final String note;
  final List<String> goodDeeds;
  final List<MistakeWithEffect> mistakesWithEffects;
  final List<JournalItem> blessings;
  final List<JournalItem> shortcomings;
  final String lessonsLearned;
  final String tomorrowPlan;
  final SoulState soulState;

  JournalEntry({
    required this.id,
    required this.userId,
    required this.date,
    this.note = '',
    this.goodDeeds = const [],
    this.mistakesWithEffects = const [],
    this.blessings = const [],
    this.shortcomings = const [],
    this.lessonsLearned = '',
    this.tomorrowPlan = '',
    this.soulState = SoulState.calm,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'note': note,
      'goodDeeds': goodDeeds,
      'mistakesWithEffects': mistakesWithEffects.map((e) => e.toMap()).toList(),
      'blessings': blessings.map((e) => e.toMap()).toList(),
      'shortcomings': shortcomings.map((e) => e.toMap()).toList(),
      'lessonsLearned': lessonsLearned,
      'tomorrowPlan': tomorrowPlan,
      'soulState': soulState.index,
    };
  }

  factory JournalEntry.fromMap(Map<dynamic, dynamic> map) {
    List<MistakeWithEffect> mwe = [];
    if (map.containsKey('mistakesWithEffects')) {
      mwe = (map['mistakesWithEffects'] as List).map((e) => MistakeWithEffect.fromMap(e)).toList();
    } else if (map.containsKey('mistakes')) {
      mwe = (map['mistakes'] as List).map((e) => MistakeWithEffect(mistake: e.toString(), effect: '')).toList();
    }

    List<JournalItem> bls = [];
    if (map.containsKey('blessings')) {
      final b = map['blessings'] as List;
      if (b.isNotEmpty && b.first is String) {
        bls = b.map((e) => JournalItem(text: e.toString())).toList();
      } else {
        bls = b.map((e) => JournalItem.fromMap(e)).toList();
      }
    }

    List<JournalItem> sht = [];
    if (map.containsKey('shortcomings')) {
      final s = map['shortcomings'] as List;
      if (s.isNotEmpty && s.first is String) {
        sht = s.map((e) => JournalItem(text: e.toString())).toList();
      } else {
        sht = s.map((e) => JournalItem.fromMap(e)).toList();
      }
    }

    return JournalEntry(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      note: map['note'] ?? '',
      goodDeeds: List<String>.from(map['goodDeeds'] ?? []),
      mistakesWithEffects: mwe,
      blessings: bls,
      shortcomings: sht,
      lessonsLearned: map['lessonsLearned'] ?? '',
      tomorrowPlan: map['tomorrowPlan'] ?? '',
      soulState: SoulState.values[map['soulState'] ?? 0],
    );
  }
}

class JournalItem {
  final String text;
  final int colorValue;

  JournalItem({required this.text, this.colorValue = 0xFF000000});

  Map<String, dynamic> toMap() => {'text': text, 'colorValue': colorValue};
  factory JournalItem.fromMap(Map<dynamic, dynamic> map) => JournalItem(
    text: map['text'] ?? '',
    colorValue: map['colorValue'] ?? 0xFF000000,
  );
}
