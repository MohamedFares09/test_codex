import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_codex/core/widgets/build_snack_bar.dart';
import 'package:test_codex/features/auth/presentation/cubits/register/register_cubit.dart';
import 'package:test_codex/core/widgets/app_background.dart';
import 'package:test_codex/features/auth/presentation/widgets/register_card.dart';
import 'package:test_codex/features/auth/presentation/widgets/register_footer.dart';
import 'package:test_codex/features/auth/presentation/widgets/register_header.dart';
import 'package:test_codex/features/auth/presentation/widgets/register_top_bar.dart';

class RegisterViewBody extends StatefulWidget {
  const RegisterViewBody({super.key});

  @override
  State<RegisterViewBody> createState() => _RegisterViewBodyState();
}

class _RegisterViewBodyState extends State<RegisterViewBody> {
  late String name;
  late String email;
  late String password;
  late String confirmPassword;
  String? selectedImagePath;
  bool agreedToTerms = false;
  AutovalidateMode autovalidateMode = AutovalidateMode.disabled;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      useRegisterColor: true,
      child: SafeArea(
        child: Column(
          children: [
            const RegisterTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const RegisterHeader(),
                    const SizedBox(height: 32),
                    RegisterCard(
                      formKey: formKey,
                      autovalidateMode: autovalidateMode,
                      agreedToTerms: agreedToTerms,
                      onTermsChanged: (value) {
                        setState(() => agreedToTerms = value ?? false);
                      },
                      onNameSaved: (value) => name = value!.trim(),
                      onEmailSaved: (value) => email = value!.trim(),
                      onPasswordSaved: (value) => password = value!,
                      onConfirmSaved: (value) => confirmPassword = value!,
                      imagePath: selectedImagePath,
                      onImageTap: _pickImage,
                      onImageRemove: _removeImage,
                      onSubmit: _submit,
                    ),
                    const SizedBox(height: 32),
                    const RegisterFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!agreedToTerms) {
      autovalidateMode = AutovalidateMode.always;
      setState(() {});
      buildSnackBar(
        context,
        message: 'Please accept the Terms of Service and Privacy Policy.',
        color: Colors.redAccent,
      );
      return;
    }
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if (password != confirmPassword) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Passwords do not match.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        return;
      }
      context.read<RegisterCubit>().createUserWithEmailAndPassword(
            name: name,
            email: email,
            password: password,
            imagePath: selectedImagePath,
          );
    } else {
      autovalidateMode = AutovalidateMode.always;
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) {
      return;
    }

    setState(() => selectedImagePath = image.path);
  }

  void _removeImage() {
    setState(() => selectedImagePath = null);
  }
}
