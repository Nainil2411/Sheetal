import 'package:flutter/material.dart';

import 'custom_color.dart';

class AppTextStyles {
  // Headline styles
  static const TextStyle titlewhite = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: CustomColors.background,
  );
  static const TextStyle headline1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: CustomColors.textPrimary,
  );
  static const TextStyle headline1white = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: CustomColors.background,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: CustomColors.textPrimary,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: CustomColors.textPrimary,
  );
  static const TextStyle headline4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: CustomColors.textPrimary,
  );
static const TextStyle headline4white = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: CustomColors.background,
  );

  // Body text styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    color: CustomColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    color: CustomColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: CustomColors.textPrimary,
  );

  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: CustomColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: CustomColors.textPrimary,
  );

  static TextStyle labelSmallgrey = TextStyle(
    fontSize: 12,
    color: Colors.grey[600],
  );
  static TextStyle labelSmall500 = TextStyle(
    fontSize: 14,
    color: Colors.grey[600],
  );
  static TextStyle labelmedium500 = TextStyle(
    fontSize: 16,
    color: Colors.grey[600],
  );
  static TextStyle labelmediumgrey = TextStyle(
    fontSize: 12,
    color: Colors.grey[600],
  );

  // Amount/currency styles
  static const TextStyle amountLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: CustomColors.textPrimary,
  );

  static const TextStyle amountMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: CustomColors.textPrimary,
  );
  static const TextStyle amountsmall = TextStyle(
    fontSize: 16,
    color: CustomColors.textSecondary,
  );
static const TextStyle labelgrey = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: CustomColors.textSecondary,
  );

  // Subtitle styles
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    color: Colors.grey,
  );

  static const TextStyle subtitleSmall = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  // Button text styles
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  static const TextStyle whitebuttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle buttonTextblack = TextStyle(
    fontSize: 14,
    color: Colors.black,
  );

  // Card title and subtitle
  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: CustomColors.textPrimary,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );
static const TextStyle Subtitlesmall = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );
static const TextStyle Subtitlesmallblack = TextStyle(
    fontSize: 12,
    color: Colors.black,
  );

  // Error and warning text
  static const TextStyle errorText = TextStyle(
    fontSize: 14,
    color: Colors.red,
  );
static const TextStyle redtext = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.red,
  );
static const TextStyle redtextlarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.red,
  );
static const TextStyle greentextlarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.green,
  );
static const TextStyle greentextsmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.green,
  );

  // Helper functions to modify existing styles
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }
}
