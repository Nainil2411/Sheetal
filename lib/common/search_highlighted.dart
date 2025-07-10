import 'package:flutter/material.dart';

class CustomSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String)? onChanged;
  final EdgeInsetsGeometry padding;
  final Color? fillColor;

  const CustomSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: fillColor ?? Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
class HighlightedText extends StatelessWidget {
  final String text;
  final String highlightText;
  final TextStyle? textStyle;
  final TextStyle? highlightStyle;

  const HighlightedText({
    super.key,
    required this.text,
    required this.highlightText,
    this.textStyle,
    this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = textStyle ?? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
    final defaultHighlightStyle = highlightStyle ??
        const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red);

    if (highlightText.isEmpty) {
      return Text(text, style: defaultTextStyle);
    }

    final matchIndex = text.toLowerCase().indexOf(highlightText.toLowerCase());
    if (matchIndex == -1) {
      return Text(text, style: defaultTextStyle);
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, matchIndex), style: defaultTextStyle),
          TextSpan(
            text: text.substring(matchIndex, matchIndex + highlightText.length),
            style: defaultHighlightStyle,
          ),
          TextSpan(text: text.substring(matchIndex + highlightText.length), style: defaultTextStyle),
        ],
      ),
    );
  }
}