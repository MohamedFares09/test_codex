import 'dart:io';

import 'package:flutter/material.dart';
import 'package:test_codex/core/widgets/custom_asset_image.dart';
import 'package:test_codex/core/utils/app_images.dart';
import 'package:test_codex/core/utils/app_colors.dart';

class RegisterAvatarUpload extends StatelessWidget {
  const RegisterAvatarUpload({
    required this.onTap,
    this.imagePath,
    this.onRemove,
    super.key,
  });

  final String? imagePath;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final cleanImagePath = imagePath?.trim();
    final hasImage = cleanImagePath != null && cleanImagePath.isNotEmpty;
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.input,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xff414754),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: hasImage
                      ? Image.file(
                          File(cleanImagePath),
                          fit: BoxFit.cover,
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            const Opacity(
                              opacity: 0.5,
                              child: CustomAssetImage(
                                AppImages.registerProfile,
                                fit: BoxFit.cover,
                              ),
                            ),
                            ColoredBox(
                              color: AppColors.scaffold.withValues(alpha: 0.4),
                            ),
                            Center(
                              child: Icon(
                                Icons.photo_camera_outlined,
                                color: AppColors.accent,
                                size: 25,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.primary,
                  child: Icon(
                    hasImage ? Icons.edit : Icons.add,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              if (hasImage && onRemove != null)
                Positioned(
                  left: -2,
                  bottom: -2,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: AppColors.input,
                      child: const Icon(
                        Icons.close,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasImage ? 'CHANGE PHOTO' : 'UPLOAD PHOTO',
          style: TextStyle(
            color: AppColors.body,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            height: 1.33,
          ),
        ),
      ],
    );
  }
}
