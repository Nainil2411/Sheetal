import 'package:flutter/material.dart';
import 'common_font_style.dart';
import 'custom_color.dart';

class CustomDropdown<T> extends StatefulWidget {
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(dynamic value) validator;
  final bool showSearchBar;
  final String? title;
  final bool showTitle;
  final Widget Function(T? value)? selectedItemBuilder;
  final String? errorText;
  // Add this parameter to provide search text for each item
  final String Function(T value)? getSearchText;

  const CustomDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.validator,
    this.showSearchBar = true,
    this.title,
    this.showTitle = false,
    this.selectedItemBuilder,
    this.errorText,
    this.getSearchText, // Add this parameter
  });

  @override
  _CustomDropdownState<T> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  bool _isDropdownOpen = false;
  String _searchText = '';
  String? _errorText;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildSelectedItem() {
    if (widget.value == null) {
      return Text(
        widget.hint,
        style: AppTextStyles.amountsmall,
      );
    }

    if (widget.selectedItemBuilder != null) {
      return widget.selectedItemBuilder!(widget.value);
    }

    return Text(
      widget.value.toString(),
      style: AppTextStyles.bodyMedium,
    );
  }

  void _validate() {
    setState(() {
      _errorText = widget.validator(widget.value);
    });
  }

  // Helper method to extract text from widget safely
  String _extractTextFromWidget(Widget widget) {
    if (widget is Text) {
      return widget.data ?? '';
    } else if (widget is RichText) {
      return widget.text.toPlainText();
    }
    // Fallback to toString() but this should be avoided in release mode
    return widget.toString();
  }

  // Better filtering method
  bool _itemMatchesSearch(DropdownMenuItem<T> item) {
    if (_searchText.isEmpty) return true;

    final searchLower = _searchText.toLowerCase();

    // Method 1: Use custom getSearchText function if provided
    if (widget.getSearchText != null && item.value != null) {
      return widget.getSearchText!(item.value!)
          .toLowerCase()
          .contains(searchLower);
    }

    // Method 2: Try to extract text from the child widget
    final childText = _extractTextFromWidget(item.child);
    if (childText.isNotEmpty) {
      return childText.toLowerCase().contains(searchLower);
    }

    // Method 3: Fallback to item.value.toString()
    if (item.value != null) {
      return item.value.toString().toLowerCase().contains(searchLower);
    }

    return false;
  }

  @override
  void didUpdateWidget(covariant CustomDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _validate();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.showSearchBar
        ? widget.items.where(_itemMatchesSearch).toList()
        : widget.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle && widget.title != null)
          Text(
            widget.title!,
            style: AppTextStyles.labelMedium,
          ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isDropdownOpen = !_isDropdownOpen;
            });

            // Auto-focus search field when dropdown opens
            if (_isDropdownOpen && widget.showSearchBar) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _searchFocusNode.requestFocus();
              });
            } else {
              _searchFocusNode.unfocus();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              border: Border.all(
                color: _errorText != null
                    ? Colors.red
                    : CustomColors.textSecondary.withOpacity(0.5),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildSelectedItem(),
                ),
                Icon(_isDropdownOpen
                    ? Icons.arrow_drop_up
                    : Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 12),
            child: Text(
              _errorText!,
              style: AppTextStyles.errorText,
            ),
          ),
        if (_isDropdownOpen)
          Container(
            constraints: const BoxConstraints(
              maxHeight: 300,
            ),
            decoration: BoxDecoration(
              color: CustomColors.textPrimary.withOpacity(0.05),
              border: Border.all(
                color: CustomColors.textSecondary.withOpacity(0.1),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showSearchBar)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: TextField(
                      focusNode: _searchFocusNode,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchText = value;
                        });
                      },
                    ),
                  ),
                Flexible(
                  child: filteredItems.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No items found'),
                  )
                      : ListView(
                    shrinkWrap: true,
                    children: filteredItems.map((item) {
                      return ListTile(
                        title: item.child,
                        onTap: () {
                          widget.onChanged(item.value);
                          _validate();
                          setState(() {
                            _isDropdownOpen = false;
                            _searchText = '';
                          });
                          _searchFocusNode.unfocus();
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}