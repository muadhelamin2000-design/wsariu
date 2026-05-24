class FilterOption {
  final String id;
  final String label;
  final dynamic value;
  final String? icon;

  FilterOption({
    required this.id,
    required this.label,
    required this.value,
    this.icon,
  });
}

class AppliedFilters {
  final List<String> dateRanges; // "today", "week", "month", "year"
  final List<String> categories; // مثلاً: "نوم", "عادات"، إلخ
  final List<String> statuses; // "completed", "pending", "failed"
  final String? searchQuery;

  AppliedFilters({
    this.dateRanges = const [],
    this.categories = const [],
    this.statuses = const [],
    this.searchQuery,
  });

  AppliedFilters copyWith({
    List<String>? dateRanges,
    List<String>? categories,
    List<String>? statuses,
    String? searchQuery,
  }) {
    return AppliedFilters(
      dateRanges: dateRanges ?? this.dateRanges,
      categories: categories ?? this.categories,
      statuses: statuses ?? this.statuses,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
