import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_codex/core/services/get_it_service.dart';
import 'package:test_codex/features/auth/presentation/cubits/login/login_cubit.dart';
import 'package:test_codex/core/widgets/custom_progress_hud.dart';
import 'package:test_codex/core/widgets/build_snack_bar.dart';
import 'package:test_codex/features/auth/presentation/widgets/login_view_body.dart';
import 'package:test_codex/features/home/presentation/views/home_view.dart';

class LoginViewBodyBlocConsumer extends StatelessWidget {
  const LoginViewBodyBlocConsumer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state is LoginErrorState) {
          buildSnackBar(
            context,
            message: state.message,
            color: Colors.redAccent,
          );
        } else if (state is LoginSuccessState) {
          clearAppDataCache();
          preloadAppData();
          buildSnackBar(
            context,
            message: 'Signed in successfully.',
            color: Colors.green,
          );
          Navigator.pushReplacementNamed(context, HomeView.route);
        }
      },
      builder: (context, state) {
        return CustomProgressHud(
          isLoading: state is LoginLoadingState,
          child: const LoginViewBody(),
        );
      },
    );
  }
}
