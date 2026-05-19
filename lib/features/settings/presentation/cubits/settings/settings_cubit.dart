import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_codex/features/settings/domain/entities/settings_user_entity.dart';
import 'package:test_codex/features/settings/domain/repos/settings_repo.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this.settingsRepo) : super(SettingsInitial());

  final SettingsRepo settingsRepo;
  SettingsUserEntity? currentUser;
  bool _isLoadingCurrentUser = false;

  Future<void> getCurrentUserIfNeeded() async {
    if (currentUser != null || _isLoadingCurrentUser) {
      return;
    }

    await getCurrentUser();
  }

  Future<void> getCurrentUser() async {
    _isLoadingCurrentUser = true;
    emit(SettingsLoadingState());
    final result = await settingsRepo.getCurrentUser();
    result.fold(
      (failure) {
        _isLoadingCurrentUser = false;
        emit(SettingsErrorState(failure.message));
      },
      (user) {
        _isLoadingCurrentUser = false;
        currentUser = user;
        emit(SettingsSuccessState(user));
      },
    );
  }

  Future<void> updateProfile({
    required String name,
    String? imagePath,
    bool deletePhoto = false,
  }) async {
    emit(SettingsUpdateLoadingState(currentUser));
    final result = await settingsRepo.updateProfile(
      name: name,
      imagePath: imagePath,
      deletePhoto: deletePhoto,
    );
    result.fold(
      (failure) => emit(SettingsErrorState(failure.message)),
      (user) {
        currentUser = user;
        emit(SettingsUpdateSuccessState(user));
      },
    );
  }

  Future<void> logout() async {
    emit(SettingsLogoutLoadingState(currentUser));
    final result = await settingsRepo.logout();
    result.fold(
      (failure) => emit(SettingsErrorState(failure.message)),
      (_) {
        clearCache();
        emit(SettingsLogoutSuccessState());
      },
    );
  }

  void clearCache() {
    _isLoadingCurrentUser = false;
    currentUser = null;
  }
}
