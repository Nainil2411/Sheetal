import 'package:flutter/material.dart';

import '../utils/utility.dart';
import 'custom_color.dart';

class CustomFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final double iconSize;
  final EdgeInsets margin;
  final Widget? label;
  final bool isExtended;
  final String? heroTag;

  const CustomFAB({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.tooltip,
    this.backgroundColor = CustomColors.textPrimary,
    this.iconColor = CustomColors.background,
    this.size = 56.0,
    this.iconSize = 24.0,
    this.margin = EdgeInsets.zero,
    this.label,
    this.isExtended = false,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    if (isExtended && label != null) {
      return Container(
        margin: margin,
        child: FloatingActionButton.extended(
          onPressed: onPressed,
          heroTag: heroTag,
          backgroundColor: backgroundColor,
          tooltip: tooltip,
          icon: Icon(icon, color: iconColor, size: iconSize),
          label: label!,
        ),
      );
    }

    return Container(
      margin: margin,
      child: SizedBox(
        width: size,
        height: size,
        child: FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: backgroundColor,
          tooltip: tooltip,
          child: Icon(icon, color: iconColor, size: iconSize),
        ),
      ),
    );
  }
}

class CustomElevatedButton extends StatelessWidget {
  final String label;
  final Function()? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double padding;
  final double borderRadius;
  final bool? isLoading;
  final Widget? icon;
  final bool showBorder;

  const CustomElevatedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor = CustomColors.textPrimary,
    this.textColor = CustomColors.background,
    this.padding = 16.0,
    this.borderRadius = 30.0,
    this.isLoading,
    this.icon,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading == true ? () {} : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          side: showBorder ? BorderSide(color: CustomColors.textPrimary) : BorderSide.none,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: EdgeInsets.symmetric(horizontal: padding),
      ),
      child: isLoading == true
          ? Utility.circleloading(color: CustomColors.background)
          : Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(color: textColor),
          ),
        ],
      ),
    );
  }
}