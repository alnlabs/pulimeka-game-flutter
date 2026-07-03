import 'package:flutter/material.dart';

/// Snack bars that stay visible on iPad (iPhone compatibility window) and phones.
void showAppSnackBar(BuildContext context, String message) {
  final bottom = MediaQuery.paddingOf(context).bottom;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
    ),
  );
}
