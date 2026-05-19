import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_codex/core/services/get_it_service.dart';
import 'package:test_codex/core/utils/route_names.dart';
import 'package:test_codex/features/settings/presentation/cubits/settings/settings_cubit.dart';
import 'package:test_codex/features/settings/presentation/widgets/settings_view_body_bloc_consumer.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  static const String route = RouteNames.settings;

  @override
  Widget build(BuildContext context) {
    final settingsCubit = getIt<SettingsCubit>()..getCurrentUserIfNeeded();
    return BlocProvider.value(
      value: settingsCubit,
      child: const Scaffold(
        body: SettingsViewBodyBlocConsumer(),
      ),
    );
  }
}
