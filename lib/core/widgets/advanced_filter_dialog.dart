import 'package:flutter/material.dart';
import '../models/filter_model.dart';

class AdvancedFilterDialog extends StatefulWidget {
  final AppliedFilters initialFilters;
  final List<FilterOption> dateOptions;
  final List<FilterOption> categoryOptions;
  final List<FilterOption> statusOptions;
  final Function(AppliedFilters) onApply;

  const AdvancedFilterDialog({
    required this.initialFilters,
    required this.dateOptions,
    required this.categoryOptions,
    required this.statusOptions,
    required this.onApply,
    Key? key,
  }) : super(key: key);

  @override
  State<AdvancedFilterDialog> createState() => _AdvancedFilterDialogState();
}

class _AdvancedFilterDialogState extends State<AdvancedFilterDialog> {
  late AppliedFilters _filters;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    _searchController = TextEditingController(text: _filters.searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان
              const Text(
                'الفلاتر المتقدمة',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // البحث
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // نطاق التاريخ
              _buildFilterSection(
                'نطاق التاريخ',
                widget.dateOptions,
                _filters.dateRanges,
                (selected) {
                  setState(() => _filters = _filters.copyWith(dateRanges: selected));
                },
              ),
              const SizedBox(height: 16),

              // الفئات
              _buildFilterSection(
                'الفئات',
                widget.categoryOptions,
                _filters.categories,
                (selected) {
                  setState(() => _filters = _filters.copyWith(categories: selected));
                },
              ),
              const SizedBox(height: 16),

              // الحالة
              _buildFilterSection(
                'الحالة',
                widget.statusOptions,
                _filters.statuses,
                (selected) {
                  setState(() => _filters = _filters.copyWith(statuses: selected));
                },
              ),
              const SizedBox(height: 24),

              // الأزرار
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      widget.onApply(_filters.copyWith(
                        searchQuery: _searchController.text.isEmpty 
                            ? null 
                            : _searchController.text,
                      ));
                      Navigator.pop(context);
                    },
                    child: const Text('تطبيق'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    List<FilterOption> options,
    List<String> selectedIds,
    Function(List<String>) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedIds.contains(option.id);
            return FilterChip(
              label: Text(option.label),
              selected: isSelected,
              onSelected: (selected) {
                final updatedIds = List<String>.from(selectedIds);
                if (selected) {
                  updatedIds.add(option.id);
                } else {
                  updatedIds.remove(option.id);
                }
                onChanged(updatedIds);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
