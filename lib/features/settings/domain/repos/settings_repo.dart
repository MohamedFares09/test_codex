import 'package:dartz/dartz.dart';
import 'package:test_codex/core/errors/failure.dart';
import 'package:test_codex/features/settings/domain/entities/settings_user_entity.dart';

abstract class SettingsRepo {
  Future<Either<Failure, SettingsUserEntity>> getCurrentUser();

  Future<Either<Failure, SettingsUserEntity>> updateProfile({
    required String name,
    String? imagePath,
    bool deletePhoto = false,
  });

  Future<Either<Failure, Unit>> logout();
}
