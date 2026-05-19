
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_codex/features/auth/domain/entities/user_entity.dart';
import 'package:test_codex/features/auth/domain/repos/auth_repo.dart';

part 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit(this.authRepo) : super(RegisterInitialState());

  final AuthRepo authRepo;

  Future<void> createUserWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    String? imagePath,
  }) async {
    emit(RegisterLoadingState());
    final result = await authRepo.createUserWithEmailAndPassword(
      name: name,
      email: email,
      password: password,
      imagePath: imagePath,
    );
    result.fold(
      (failure) => emit(RegisterErrorState(failure.message)),
      (user) => emit(RegisterSuccessState(user)),
    );
  }
}
