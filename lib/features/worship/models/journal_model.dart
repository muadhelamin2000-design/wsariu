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
  final String headline;
  final String content;
  final bool isFavorite;
  final double fontSize;
  final int colorValue;
  final int? highlightColorValue;
  final List<MistakeWithEffect> mistakesWithEffects;
  final List<JournalItem> blessings;

  JournalEntry({
    required this.id,
    required this.userId,
    required this.date,
    this.headline = '',
    this.content = '',
    this.isFavorite = false,
    this.fontSize = 16.0,
    this.colorValue = 0xFF000000,
    this.highlightColorValue,
    this.mistakesWithEffects = const [],
    this.blessings = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'headline': headline,
      'content': content,
      'isFavorite': isFavorite,
      'fontSize': fontSize,
      'colorValue': colorValue,
      'highlightColorValue': highlightColorValue,
      'mistakesWithEffects': mistakesWithEffects.map((e) => e.toMap()).toList(),
      'blessings': blessings.map((e) => e.toMap()).toList(),
    };
  }

  factory JournalEntry.fromMap(Map<dynamic, dynamic> map) {
    return JournalEntry(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      headline: map['headline'] ?? map['note'] ?? '', // Compatibility with old 'note'
      content: map['content'] ?? '',
      isFavorite: map['isFavorite'] ?? false,
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 16.0,
      colorValue: map['colorValue'] ?? 0xFF000000,
      highlightColorValue: map['highlightColorValue'],
      mistakesWithEffects: (map['mistakesWithEffects'] as List?)
              ?.map((e) => MistakeWithEffect.fromMap(Map<dynamic, dynamic>.from(e)))
              .toList() ??
          [],
      blessings: (map['blessings'] as List?)
              ?.map((e) => JournalItem.fromMap(Map<dynamic, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  JournalEntry copyWith({
    String? headline,
    String? content,
    bool? isFavorite,
    double? fontSize,
    int? colorValue,
    int? highlightColorValue,
    List<MistakeWithEffect>? mistakesWithEffects,
    List<JournalItem>? blessings,
    bool clearHighlight = false,
  }) {
    return JournalEntry(
      id: id,
      userId: userId,
      date: date,
      headline: headline ?? this.headline,
      content: content ?? this.content,
      isFavorite: isFavorite ?? this.isFavorite,
      fontSize: fontSize ?? this.fontSize,
      colorValue: colorValue ?? this.colorValue,
      highlightColorValue: clearHighlight ? null : (highlightColorValue ?? this.highlightColorValue),
      mistakesWithEffects: mistakesWithEffects ?? this.mistakesWithEffects,
      blessings: blessings ?? this.blessings,
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
