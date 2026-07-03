import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HelpSection extends StatelessWidget {
  const HelpSection({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.text(size: 18, weight: FontWeight.bold, color: AppTheme.primaryLight),
        ),
        const SizedBox(height: 10),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }
}

class HelpParagraph extends StatelessWidget {
  const HelpParagraph(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTheme.text(size: 15, color: AppTheme.textPrimary),
      ),
    );
  }
}

class HelpBullet extends StatelessWidget {
  const HelpBullet(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: AppTheme.text(size: 15, color: AppTheme.primary)),
          Expanded(
            child: Text(
              text,
              style: AppTheme.text(size: 15, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
