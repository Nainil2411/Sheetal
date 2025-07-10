import 'package:flutter/material.dart';
import 'common_font_style.dart';
import 'custom_color.dart';

Widget buildCard({
  required String value,
  required String subtitle,
  bool isBlackCard = false,
  IconData? icon,
  String? imagePath,
  bool hideCurrencySymbol = false,
}) {
  final backgroundColor = isBlackCard
      ? CustomColors.textPrimary
      : CustomColors.background;

  final textColor = isBlackCard
      ? CustomColors.background
      : CustomColors.textPrimary;

  final subtitleColor = isBlackCard
      ? Colors.white70
      : Colors.grey[600];

  final shadowColor = isBlackCard
      ? Colors.grey.withOpacity(0.7)
      : CustomColors.textSecondary.withOpacity(0.7);

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          spreadRadius: 1,
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon or Image - now supports both for black and white cards
        if (icon != null)
          Icon(
            icon,
            color: textColor,
            size: 30,
          )
        else if (imagePath != null)
          Image.asset(
            imagePath,
            color: textColor,
            width: 30,
            height: 30,
          ),
        const SizedBox(height: 8),
        Text(
          hideCurrencySymbol ? value : '₹$value',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: isBlackCard ? 14 : 12,
            color: subtitleColor,
          ),
        ),
      ],
    ),
  );
}

Widget buildFeatureCard({
  required String title,
  required String subtitle,
  bool isDarkCard = false,
  IconData? icon,
  String? imagePath,
}) {
  final backgroundColor = isDarkCard
      ? CustomColors.textPrimary
      : CustomColors.background;

  final textColor = isDarkCard
      ? CustomColors.background
      : CustomColors.textPrimary;

  final TextStyle titleStyle = isDarkCard
      ? AppTextStyles.headline4white
      : AppTextStyles.headline4;

  final TextStyle subtitleStyle = AppTextStyles.labelSmallgrey;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.7),
          spreadRadius: 3,
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon or Image - now supports both for dark and light cards
        if (icon != null)
          Icon(
            icon,
            size: 24,
            color: textColor,
          )
        else if (imagePath != null)
          Image.asset(
            imagePath,
            width: 24,
            height: 24,
            color: textColor,
          ),
        const SizedBox(height: 12),
        Text(title, style: titleStyle),
        const SizedBox(height: 4),
        Text(subtitle, style: subtitleStyle),
      ],
    ),
  );
}