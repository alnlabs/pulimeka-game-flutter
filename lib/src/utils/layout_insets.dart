import 'package:flutter/material.dart';

/// Bottom padding for fixed footers (banner ads, labels) inside [SafeArea].
double bottomChromePadding(BuildContext context) {
  final padding = MediaQuery.paddingOf(context).bottom;
  if (padding > 0) {
    return padding;
  }
  // iPhone apps on iPad can report zero bottom inset; keep a small buffer.
  return 8;
}
