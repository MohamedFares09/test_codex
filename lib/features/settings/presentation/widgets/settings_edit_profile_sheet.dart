import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_codex/core/utils/app_colors.dart';
import 'package:test_codex/core/utils/validators.dart';
import 'package:test_codex/core/widgets/custom_button.dart';
import 'package:test_codex/features/settings/domain/entities/settings_user_entity.dart';
import 'package:test_codex/features/settings/presentation/models/settings_profile_update_data.dart';
import 'package:test_codex/features/settings/presentation/widgets/settings_profile_avatar.dart';

class SettingsEditProfileSheet extends StatefulWidget {
  const SettingsEditProfileSheet({
    required this.user,
    super.key,
  });

  final SettingsUserEntity? user;

  @override
  State<SettingsEditProfileSheet> createState() =>
      _SettingsEditProfileSheetState();
}

class _SettingsEditProfileSheetState extends State<SettingsEditProfileSheet> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  String? selectedImagePath;
  bool deletePhoto = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user?.name ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit Profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.title,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 22),
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      selectedImagePath == null
                          ? SettingsProfileAvatar(
                              name: nameController.text.trim().isEmpty
                                  ? 'User'
                                  : nameController.text,
                              photoUrl: deletePhoto
                                  ? null
                                  : widget.user?.photoUrl,
                              size: 104,
                            )
                          : CircleAvatar(
                              radius: 52,
                              backgroundImage:
                                  FileImage(File(selectedImagePath!)),
                            ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: IconButton.filled(
                          onPressed: pickImage,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.photo_camera_outlined),
                        ),
                      ),
                      if (_canDeletePhoto)
                        Positioned(
                          left: -2,
                          bottom: -2,
                          child: IconButton.filled(
                            onPressed: removePhoto,
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.input,
                              foregroundColor: Colors.redAccent,
                            ),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                TextFormField(
                  controller: nameController,
                  validator: Validators.requiredField,
                  onChanged: (_) => setState(() {}),
                  cursorColor: AppColors.accent,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.input,
                    hintText: 'Username',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: AppColors.body,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accent),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Save Changes',
                  onPressed: submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) {
      return;
    }
    setState(() {
      selectedImagePath = image.path;
      deletePhoto = false;
    });
  }

  void removePhoto() {
    setState(() {
      selectedImagePath = null;
      deletePhoto = true;
    });
  }

  void submit() {
    if (!formKey.currentState!.validate()) {
      return;
    }
    Navigator.pop(
      context,
      SettingsProfileUpdateData(
        name: nameController.text,
        imagePath: selectedImagePath,
        deletePhoto: deletePhoto,
      ),
    );
  }

  bool get _canDeletePhoto {
    if (selectedImagePath != null) {
      return true;
    }

    final photoUrl = widget.user?.photoUrl?.trim();
    return !deletePhoto && photoUrl != null && photoUrl.isNotEmpty;
  }
}
