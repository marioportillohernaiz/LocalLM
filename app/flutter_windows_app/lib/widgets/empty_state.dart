import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.subtitle,
    this.title,
  });

  final Widget icon;
  final String? title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 96, height: 96, child: Center(child: icon)),
            if (title != null) ...[
              const SizedBox(height: 20),
              Text(
                title!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
            ] else
              const SizedBox(height: 18),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppPalette.mutedText,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyStateIcon extends StatelessWidget {
  const EmptyStateIcon({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppPalette.dustGrey,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Icon(icon, size: 46, color: AppPalette.gunmetal),
    );
  }
}
