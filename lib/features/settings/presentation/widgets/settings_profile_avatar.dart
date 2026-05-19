import 'package:flutter/material.dart';
import 'package:test_codex/core/utils/app_colors.dart';

class SettingsProfileAvatar extends StatelessWidget {
  const SettingsProfileAvatar({
    required this.name,
    required this.size,
    this.photoUrl,
    this.showOnlineDot = false,
    super.key,
  });

  final String name;
  final double size;
  final String? photoUrl;
  final bool showOnlineDot;

  @override
  Widget build(BuildContext context) {
    final imageUrl = photoUrl?.trim();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.06),
          decoration:  BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accent, Color(0xffcdbdff)],
            ),
          ),
          child: CircleAvatar(
            backgroundColor: AppColors.scaffold,
            backgroundImage: imageUrl == null || imageUrl.isEmpty
                ? null
                : NetworkImage(imageUrl),
            child: imageUrl == null || imageUrl.isEmpty
                ? Text(
                    _initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.28,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
        ),
        if (showOnlineDot)
          Positioned(
            right: size * 0.04,
            bottom: size * 0.04,
            child: Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: BoxDecoration(
                color: const Color(0xff22c55e),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.scaffold,
                  width: size * 0.04,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }
    return parts.first.substring(0, 1).toUpperCase();
  }
}
