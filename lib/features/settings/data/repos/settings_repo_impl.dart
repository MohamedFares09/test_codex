import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:test_codex/core/errors/custom_exception.dart';
import 'package:test_codex/core/errors/failure.dart';
import 'package:test_codex/features/settings/data/services/settings_firebase_service.dart';
import 'package:test_codex/features/settings/domain/entities/settings_user_entity.dart';
import 'package:test_codex/features/settings/domain/repos/settings_repo.dart';

class SettingsRepoImpl extends SettingsRepo {
  SettingsRepoImpl({required this.settingsFirebaseService});

  final SettingsFirebaseService settingsFirebaseService;

  @override
  Future<Either<Failure, SettingsUserEntity>> getCurrentUser() async {
    try {
      final user = await settingsFirebaseService.getCurrentUser();
      return right(user);
    } on CustomException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      log('Exception SettingsRepoImpl - getCurrentUser: $e');
      return left(const ServerFailure('Something went wrong. Please try again.'));
    }
  }

  @override
  Future<Either<Failure, SettingsUserEntity>> updateProfile({
    required String name,
    String? imagePath,
    bool deletePhoto = false,
  }) async {
    try {
      final user = await settingsFirebaseService.updateProfile(
        name: name,
        imagePath: imagePath,
        deletePhoto: deletePhoto,
      );
      return right(user);
    } on CustomException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      log('Exception SettingsRepoImpl - updateProfile: $e');
      return left(const ServerFailure('Something went wrong. Please try again.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await settingsFirebaseService.logout();
      return right(unit);
    } on CustomException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      log('Exception SettingsRepoImpl - logout: $e');
      return left(const ServerFailure('Something went wrong. Please try again.'));
    }
  }
}
