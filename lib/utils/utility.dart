import 'package:flutter/material.dart';

import '../common/app_string.dart';
import '../common/common_font_style.dart';
import '../common/custom_color.dart';

class Utility {
  static Widget? keyboardDismiss(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
    return null;
  }

  static Widget circleloading({Color? color}) {
    return Center(
      child: CircularProgressIndicator(
        color: color ?? CustomColors.textPrimary,
      ),
    );
  }

  static Future<void> showDeleteConfirmationDialog({
    required BuildContext context,
    required Function onConfirm,
    String title = AppStrings.confirmdelete,
    String content = AppStrings.suredelete,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(
            content,
            style: AppTextStyles.buttonTextblack,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                AppStrings.cancel,
                style: AppTextStyles.buttonTextblack,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                AppStrings.yes,
                style: AppTextStyles.errorText,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  // New success dialog method
  static Future<void> showSuccessDialog({
    required BuildContext context,
    required String message,
    String title = 'Success',
    VoidCallback? onDismiss,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: CustomColors.green1),
              const SizedBox(width: 10),
              Text(title),
            ],
          ),
          content: Text(
            message,
            style: AppTextStyles.buttonTextblack,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: CustomColors.green1),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                if (onDismiss != null) {
                  onDismiss();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // New error dialog method
  static Future<void> showErrorDialog({
    required BuildContext context,
    required String message,
    String title = 'Error',
    VoidCallback? onDismiss,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: CustomColors.error),
              const SizedBox(width: 10),
              Text(title),
            ],
          ),
          content: Text(
            message,
            style: AppTextStyles.buttonTextblack,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK',
                style: AppTextStyles.errorText,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                if (onDismiss != null) {
                  onDismiss();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
