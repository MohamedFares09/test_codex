import 'package:flutter/material.dart';
import 'package:test_codex/core/utils/validators.dart';
import 'package:test_codex/core/widgets/custom_button.dart';
import 'package:test_codex/core/utils/app_colors.dart';
import 'package:test_codex/features/auth/presentation/widgets/register_avatar_upload.dart';
import 'package:test_codex/features/auth/presentation/widgets/register_labeled_field.dart';
import 'package:test_codex/features/auth/presentation/widgets/register_terms_row.dart';

class RegisterCard extends StatelessWidget {
  const RegisterCard({
    required this.formKey,
    required this.autovalidateMode,
    required this.agreedToTerms,
    required this.onTermsChanged,
    required this.onNameSaved,
    required this.onEmailSaved,
    required this.onPasswordSaved,
    required this.onConfirmSaved,
    required this.onImageTap,
    required this.onSubmit,
    this.imagePath,
    this.onImageRemove,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final AutovalidateMode autovalidateMode;
  final bool agreedToTerms;
  final ValueChanged<bool?> onTermsChanged;
  final FormFieldSetter<String> onNameSaved;
  final FormFieldSetter<String> onEmailSaved;
  final FormFieldSetter<String> onPasswordSaved;
  final FormFieldSetter<String> onConfirmSaved;
  final String? imagePath;
  final VoidCallback onImageTap;
  final VoidCallback? onImageRemove;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 34),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 50,
            offset: Offset(0, 25),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        autovalidateMode: autovalidateMode,
        child: Column(
          children: [
            RegisterAvatarUpload(
              imagePath: imagePath,
              onTap: onImageTap,
              onRemove: onImageRemove,
            ),
            const SizedBox(height: 32),
            RegisterLabeledField(
              label: 'FULL NAME',
              hintText: 'Alex Rivers',
              prefixIcon: Icon(
                Icons.person_outline,
                color: AppColors.body,
                size: 18,
              ),
              onSaved: onNameSaved,
            ),
            const SizedBox(height: 16),
            RegisterLabeledField(
              label: 'EMAIL ADDRESS',
              hintText: 'alex@chatflow.io',
              prefixIcon: Icon(
                Icons.alternate_email,
                color: AppColors.body,
                size: 18,
              ),
              keyboardType: TextInputType.emailAddress,
              onSaved: onEmailSaved,
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            RegisterLabeledField(
              label: 'PASSWORD',
              hintText: 'Password',
              prefixIcon: Icon(
                Icons.lock_outline,
                color: AppColors.body,
                size: 18,
              ),
              obscureText: true,
              onSaved: onPasswordSaved,
              validator: Validators.password,
            ),
            const SizedBox(height: 16),
            RegisterLabeledField(
              label: 'CONFIRM PASSWORD',
              hintText: 'Confirm password',
              prefixIcon: Icon(
                Icons.shield_outlined,
                color: AppColors.body,
                size: 18,
              ),
              obscureText: true,
              onSaved: onConfirmSaved,
              validator: Validators.password,
            ),
            const SizedBox(height: 24),
            RegisterTermsRow(
              agreedToTerms: agreedToTerms,
              onChanged: onTermsChanged,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Create Account',
              borderRadius: 16,
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
