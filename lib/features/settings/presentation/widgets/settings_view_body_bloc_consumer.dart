import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_codex/core/services/get_it_service.dart';
import 'package:test_codex/core/widgets/build_snack_bar.dart';
import 'package:test_codex/core/widgets/custom_progress_hud.dart';
import 'package:test_codex/features/auth/presentation/views/login_view.dart';
import 'package:test_codex/features/settings/presentation/cubits/settings/settings_cubit.dart';
import 'package:test_codex/features/settings/presentation/widgets/settings_view_body.dart';

class SettingsViewBodyBlocConsumer extends StatelessWidget {
  const SettingsViewBodyBlocConsumer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsCubit, SettingsState>(
      listener: (context, state) {
        if (state is SettingsErrorState) {
          buildSnackBar(
            context,
            message: state.message,
            color: Colors.redAccent,
          );
        } else if (state is SettingsUpdateSuccessState) {
          buildSnackBar(
            context,
            message: 'Profile updated successfully.',
            color: Colors.green,
          );
        } else if (state is SettingsLogoutSuccessState) {
          clearAppDataCache();
          Navigator.pushNamedAndRemoveUntil(
            context,
            LoginView.route,
            (route) => false,
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<SettingsCubit>();
        return CustomProgressHud(
          isLoading: state is SettingsLoadingState ||
              state is SettingsUpdateLoadingState ||
              state is SettingsLogoutLoadingState,
          child: SettingsViewBody(user: cubit.currentUser),
        );
      },
    );
  }
}
