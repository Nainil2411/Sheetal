import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../common/custom_color.dart';
import '../common/app_string.dart';
import '../common/common_font_style.dart';
import '../common/search_highlighted.dart';
import '../utils/utility.dart';

class GenericListView<T> extends StatelessWidget {
  final List<T> items;
  final bool isLoading;
  final String emptyMessage;
  final TextEditingController searchController;
  final Function(String) onSearch;
  final String searchText;
  final Widget? filterWidget;
  final String Function(T item) getTitle;
  final String? Function(T item) getSubtitle;
  final String Function(T item) getInitials;
  final String? Function(T item)? getAmount;
  final Color? Function(T item)? getAmountColor;
  final Function(T item) onItemTap;
  final Function(T item)? onItemLongPress;
  final bool isSelectionMode;
  final Set<String> selectedIds;
  final String Function(T item)? getId;
  final Function(T item)? onSelectionToggle;
  final IconData Function(T item)? getTrailingIcon;
  final bool showTrailingIcon;
  final bool showSearch;

  // New sorting properties
  final String? Function(T item)? getDateString;
  final bool enableSorting;
  final bool sortAscending;
  final Function(bool)? onSortChanged;

  // New select all properties
  final Function()? onSelectAll;
  final Function()? onDeselectAll;

  const GenericListView({
    super.key,
    required this.items,
    required this.isLoading,
    required this.emptyMessage,
    required this.searchController,
    required this.onSearch,
    required this.searchText,
    required this.getTitle,
    required this.getInitials,
    required this.onItemTap,
    required this.getSubtitle,
    this.getAmount,
    this.getAmountColor,
    this.filterWidget,
    this.onItemLongPress,
    this.isSelectionMode = false,
    this.selectedIds = const <String>{},
    this.getId,
    this.onSelectionToggle,
    this.getTrailingIcon,
    this.showTrailingIcon = true,
    this.showSearch = true,
    // Sorting parameters
    this.getDateString,
    this.enableSorting = false,
    this.sortAscending = false,
    this.onSortChanged,
    // Select all parameters
    this.onSelectAll,
    this.onDeselectAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showSearch)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      fillColor: Colors.grey.shade100,
                      filled: true,
                      hintText: AppStrings.searchby,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                    onChanged: onSearch,
                  ),
                ),
                if (enableSorting && getDateString != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => onSortChanged?.call(!sortAscending),
                    icon: Icon(
                      sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      color: CustomColors.textPrimary,
                    ),
                    tooltip: sortAscending ? 'Oldest First' : 'Latest First',
                  ),
                ],
              ],
            ),
          ),

        // Selection mode header with select all button
        if (isSelectionMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: CustomColors.textPrimary.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${selectedIds.length} selected',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: CustomColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _isAllSelected() ? onDeselectAll : onSelectAll,
                  icon: Icon(
                    _isAllSelected() ? Icons.deselect : Icons.select_all,
                    size: 18,
                  ),
                  label: Text(_isAllSelected() ? 'Deselect All' : 'Select All'),
                  style: TextButton.styleFrom(
                    foregroundColor: CustomColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

        if (filterWidget != null) filterWidget!,
        Expanded(
          child: isLoading ? Utility.circleloading() : _buildList(),
        ),
      ],
    );
  }

  bool _isAllSelected() {
    if (items.isEmpty || getId == null) return false;

    // Get all valid item IDs
    final allItemIds = items
        .map((item) => getId!(item))
        .where((id) => id != null)
        .cast<String>()
        .toSet();

    // Check if all items are selected
    return allItemIds.isNotEmpty && allItemIds.every((id) => selectedIds.contains(id));
  }

  Widget _buildList() {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: AppTextStyles.subtitle,
        ),
      );
    }

    // Sort items if sorting is enabled and getDateString is provided
    List<T> sortedItems = List.from(items);
    if (enableSorting && getDateString != null) {
      sortedItems = _sortItemsByDate(sortedItems);
    }

    return ListView.builder(
      itemCount: sortedItems.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final item = sortedItems[index];
        final itemId = getId?.call(item);
        final isSelected = itemId != null && selectedIds.contains(itemId);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelectionMode && isSelected
                  ? CustomColors.textPrimary
                  : Colors.grey.shade300,
              width: isSelectionMode && isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelectionMode && isSelected
                ? CustomColors.textPrimary.withOpacity(0.05)
                : CustomColors.background,
          ),
          child: InkWell(
            onTap: () {
              if (isSelectionMode) {
                onSelectionToggle?.call(item);
              } else {
                onItemTap(item);
              }
            },
            onLongPress: () {
              if (!isSelectionMode) {
                onItemLongPress?.call(item);
              }
            },
            child: Row(
              children: [
                if (isSelectionMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onSelectionToggle?.call(item),
                    activeColor: CustomColors.textPrimary,
                  )
                else
                  CircleAvatar(
                    backgroundColor: CustomColors.textPrimary,
                    child: Text(
                      getInitials(item),
                      style: const TextStyle(
                        color: CustomColors.background,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HighlightedText(
                        text: getTitle(item),
                        highlightText: searchText,
                      ),
                      if (getSubtitle(item) != null)
                        Text(
                          getSubtitle(item)!,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (getAmount != null && getAmount!(item) != null)
                      Text(
                        getAmount!(item)!,
                        style: TextStyle(
                          color: getAmountColor != null
                              ? getAmountColor!(item)
                              : CustomColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (!isSelectionMode && showTrailingIcon)
                      Icon(
                        getTrailingIcon?.call(item) ?? Icons.arrow_forward,
                        color: CustomColors.textPrimary,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<T> _sortItemsByDate(List<T> items) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    items.sort((a, b) {
      final dateStringA = getDateString!(a);
      final dateStringB = getDateString!(b);

      // Handle null dates - put them at the end
      if (dateStringA == null && dateStringB == null) return 0;
      if (dateStringA == null) return 1;
      if (dateStringB == null) return -1;

      try {
        final dateA = dateFormat.parse(dateStringA);
        final dateB = dateFormat.parse(dateStringB);
        return sortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    return items;
  }
}