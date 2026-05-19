import 'package:flutter/material.dart';
import 'package:test_codex/core/utils/app_colors.dart';
import 'package:test_codex/features/home/presentation/widgets/initials_avatar.dart';

class HomeUserAvatar extends StatelessWidget {
  const HomeUserAvatar({
    required this.name,
    this.size = 56,
    this.showOnlineDot = false,
    this.backgroundColor,
    this.photoUrl,
    super.key,
  });

  final String name;
  final double size;
  final bool showOnlineDot;
  final Color? backgroundColor;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final imageUrl = photoUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: backgroundColor == null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, Color(0xff5203d5)],
                  )
                : null,
            color: backgroundColor,
            border: Border.all(color: AppColors.mutedBorder),
          ),
          child: ClipOval(
            child: hasImage
                ? Image.network(
                    imageUrl!,
                    key: ValueKey(imageUrl),
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return InitialsAvatar(
                        initials: _initials,
                        fontSize: size * 0.32,
                      );
                    },
                  )
                : InitialsAvatar(initials: _initials, fontSize: size * 0.32),
          ),
        ),
        if (showOnlineDot)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xff4ade80),
                border: Border.all(color: AppColors.scaffold, width: 2),
                borderRadius: BorderRadius.circular(5),
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
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
