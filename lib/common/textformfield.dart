import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'custom_color.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final bool obscureText;
  final String? errorText;
  final Function(String)? onChanged;
  final Function()? onPressed;
  final Function()? onTap;
  final String? Function(String?)? validator;
  final bool showSuffixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final Color? borderColor;
  final Color? fillColor;
  final String? hintText;
  final bool showBorders;
  final List<TextInputFormatter>? inputFormatters;
  final Color? hintStyle;
  final bool readOnly;
  final bool enabled;
  final TextInputAction? textInputAction;
  final InputDecoration? decoration;
  final String? title;
  final bool showTitle;
  final int? maxLines;

  const CustomTextFormField({
    super.key,
    required this.controller,
    this.label,
    this.obscureText = false,
    this.errorText,
    this.onChanged,
    this.onPressed,
    this.onTap,
    this.validator,
    this.showSuffixIcon = false,
    this.suffixIcon,
    this.keyboardType,
    this.borderColor,
    this.fillColor = Colors.transparent,
    this.hintText,
    this.showBorders = true,
    this.inputFormatters,
    this.hintStyle,
    this.readOnly = false,
    this.enabled = true,
    this.textInputAction,
    this.decoration,
    this.title,
    this.showTitle = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              title!,
              style: TextStyle(
                  color: CustomColors.textPrimary, fontWeight: FontWeight.bold),
            ),
          ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          enabled: enabled,
          obscureText: obscureText,
          onChanged: onChanged,
          onTap: onTap,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            labelText: label,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: showBorders
                    ? (borderColor ?? CustomColors.grey300)
                    : Colors.transparent,
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: showBorders
                    ? (borderColor ??
                        CustomColors.textSecondary.withOpacity(0.5))
                    : Colors.transparent,
                width: 1.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: showBorders ? CustomColors.error1
                    : Colors.transparent,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color:
                    showBorders ? CustomColors.textPrimary : Colors.transparent,
                width: 1.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: showBorders ? CustomColors.error1 : Colors.transparent,
                width: 1.0,
              ),
            ),
            errorText: errorText?.isEmpty == true ? null : errorText,
            errorMaxLines: 3,
            errorStyle: TextStyle(color: CustomColors.error1),
            filled: true,
            hintText: hintText,
            hintStyle: TextStyle(color: CustomColors.textSecondary),
            suffixIcon: showSuffixIcon
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: onPressed,
                  )
                : suffixIcon,
          ),
        ),
      ],
    );
  }
}
