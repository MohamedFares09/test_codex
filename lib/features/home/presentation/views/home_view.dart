import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_codex/core/services/get_it_service.dart';
import 'package:test_codex/core/utils/route_names.dart';
import 'package:test_codex/features/home/presentation/cubits/home/home_cubit.dart';
import 'package:test_codex/features/home/presentation/widgets/home_view_body_bloc_consumer.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  static const String route = RouteNames.home;

  @override
  Widget build(BuildContext context) {
    final homeCubit = getIt<HomeCubit>()..watchHomeIfNeeded();
    return BlocProvider.value(
      value: homeCubit,
      child: const Scaffold(
        body: HomeViewBodyBlocConsumer(),
      ),
    );
  }
}
