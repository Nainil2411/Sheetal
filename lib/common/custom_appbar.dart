import 'package:flutter/material.dart';

import 'app_string.dart';
import 'common_font_style.dart';
import 'custom_color.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final dynamic title;
  final Function()? onPressed;
  final Color backgroundColor;
  final Function(String)? onMenuSelected;
  final bool showPopupMenu;
  final bool showSortMenu;
  final Function(String)? onSearch;
  final bool showSearchBar;
  final List<Widget>? actions;
  final Widget? icon;
  final TabBar? bottom;
  final bool showLeadingIcon;
  final Widget? leading;
  final TextStyle? titleStyle;
  final TextOverflow? overflow;
  final int? maxLines;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onPressed,
    this.onMenuSelected,
    this.backgroundColor = CustomColors.background,
    this.showPopupMenu = false,
    this.showSortMenu = false,
    this.onSearch,
    this.showSearchBar = false,
    this.icon,
    this.actions,
    this.bottom,
    this.showLeadingIcon = true,
    this.leading,
    this.titleStyle,
    this.overflow,
    this.maxLines,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(bottom == null ? kToolbarHeight : kToolbarHeight + 48);

  @override
  _CustomAppBarState createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  final bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: widget.backgroundColor,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: widget.leading ??
          (widget.showLeadingIcon
              ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onPressed ?? () => Navigator.pop(context),
          )
              : null),
      title: widget.showSearchBar && _isSearching
          ? TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: AppStrings.search,
          border: InputBorder.none,
        ),
        onChanged: widget.onSearch,
      )
          : widget.title is String
          ? Text(
        widget.title,
        style: widget.titleStyle ?? AppTextStyles.headline3,
        overflow: widget.overflow,
        maxLines: widget.maxLines,
      )
          : widget.title,
      actions: widget.actions,
      bottom: widget.bottom,
    );
  }
}
