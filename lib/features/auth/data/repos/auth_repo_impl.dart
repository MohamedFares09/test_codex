import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:test_codex/core/errors/custom_exception.dart';
import 'package:test_codex/core/errors/failure.dart';
import 'package:test_codex/features/auth/data/models/user_model.dart';
import 'package:test_codex/features/auth/data/services/firebase_auth_service.dart';
import 'package:test_codex/features/auth/domain/entities/user_entity.dart';
import 'package:test_codex/features/auth/domain/repos/auth_repo.dart';

class AuthRepoImpl extends AuthRepo {
  AuthRepoImpl({required this.authService});

  final FirebaseAuthService authService;

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return right(UserModel.fromFirebaseUser(user));
    } on CustomException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      log('Exception AuthRepoImpl - signInWithEmailAndPassword: $e');
      return left(const ServerFailure('Something went wrong. Please try again.'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> createUserWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    String? imagePath,
  }) async {
    try {
      final user = await authService.createUserWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
        imagePath: imagePath,
      );
      return right(UserModel.fromFirebaseUser(user));
    } on CustomException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      log('Exception AuthRepoImpl - createUserWithEmailAndPassword: $e');
      return left(const ServerFailure('Something went wrong. Please try again.'));
    }
  }
}
