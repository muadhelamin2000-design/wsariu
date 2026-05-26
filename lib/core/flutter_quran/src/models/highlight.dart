class Highlight {
  final int ayahId;
  final int colorCode;
  final String? label;
  final List<int>? wordIndices;
  final int? start;
  final int? end;

  Highlight({
    required this.ayahId,
    required this.colorCode,
    this.label,
    this.wordIndices,
    this.start,
    this.end,
  });

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      ayahId: json['ayahId'],
      colorCode: json['colorCode'],
      label: json['label'],
      wordIndices: json['wordIndices'] != null ? List<int>.from(json['wordIndices']) : null,
      start: json['start'],
      end: json['end'],
    );
  }

  Map<String, dynamic> toJson() => {
    'ayahId': ayahId,
    'colorCode': colorCode,
    'label': label,
    'wordIndices': wordIndices,
    'start': start,
    'end': end,
  };
}
