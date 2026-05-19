import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:test_codex/core/services/theme_service.dart';
import 'package:test_codex/features/auth/data/repos/auth_repo_impl.dart';
import 'package:test_codex/features/auth/data/services/firebase_auth_service.dart';
import 'package:test_codex/features/auth/domain/repos/auth_repo.dart';
import 'package:test_codex/features/groups/data/repos/groups_repo_impl.dart';
import 'package:test_codex/features/groups/data/services/groups_firebase_service.dart';
import 'package:test_codex/features/groups/domain/repos/groups_repo.dart';
import 'package:test_codex/features/home/data/repos/home_repo_impl.dart';
import 'package:test_codex/features/home/data/services/home_firestore_service.dart';
import 'package:test_codex/features/home/domain/repos/home_repo.dart';
import 'package:test_codex/features/home/presentation/cubits/home/home_cubit.dart';
import 'package:test_codex/features/message/data/repos/message_repo_impl.dart';
import 'package:test_codex/features/message/data/services/message_firestore_service.dart';
import 'package:test_codex/features/message/domain/repos/message_repo.dart';
import 'package:test_codex/features/settings/data/repos/settings_repo_impl.dart';
import 'package:test_codex/features/settings/data/services/settings_firebase_service.dart';
import 'package:test_codex/features/settings/domain/repos/settings_repo.dart';
import 'package:test_codex/features/settings/presentation/cubits/settings/settings_cubit.dart';

final GetIt getIt = GetIt.instance;

void setupGetIt() {
  if (!getIt.isRegistered<FirebaseAuth>()) {
    getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  }
  if (!getIt.isRegistered<FirebaseFirestore>()) {
    getIt.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
    );
  }
  if (!getIt.isRegistered<FirebaseStorage>()) {
    getIt.registerLazySingleton<FirebaseStorage>(
      () => FirebaseStorage.instance,
    );
  }
  if (!getIt.isRegistered<ThemeService>()) {
    getIt.registerLazySingleton<ThemeService>(
      () => ThemeService(
        firebaseAuth: getIt<FirebaseAuth>(),
        firestore: getIt<FirebaseFirestore>(),
      ),
    );
  }
  if (!getIt.isRegistered<FirebaseAuthService>()) {
    getIt.registerLazySingleton<FirebaseAuthService>(
      () => FirebaseAuthService(
        firebaseAuth: getIt<FirebaseAuth>(),
        firestore: getIt<FirebaseFirestore>(),
        firebaseStorage: getIt<FirebaseStorage>(),
      ),
    );
  }
  if (!getIt.isRegistered<AuthRepo>()) {
    getIt.registerLazySingleton<AuthRepo>(
      () => AuthRepoImpl(authService: getIt<FirebaseAuthService>()),
    );
  }
  if (!getIt.isRegistered<HomeFirestoreService>()) {
    getIt.registerLazySingleton<HomeFirestoreService>(
      () => HomeFirestoreService(
        firestore: getIt<FirebaseFirestore>(),
        firebaseAuth: getIt<FirebaseAuth>(),
        firebaseStorage: getIt<FirebaseStorage>(),
      ),
    );
  }
  if (!getIt.isRegistered<HomeRepo>()) {
    getIt.registerLazySingleton<HomeRepo>(
      () => HomeRepoImpl(homeFirestoreService: getIt<HomeFirestoreService>()),
    );
  }
  if (!getIt.isRegistered<HomeCubit>()) {
    getIt.registerLazySingleton<HomeCubit>(
      () => HomeCubit(getIt<HomeRepo>()),
    );
  }
  if (!getIt.isRegistered<GroupsFirebaseService>()) {
    getIt.registerLazySingleton<GroupsFirebaseService>(
      () => GroupsFirebaseService(
        firestore: getIt<FirebaseFirestore>(),
        firebaseAuth: getIt<FirebaseAuth>(),
        firebaseStorage: getIt<FirebaseStorage>(),
      ),
    );
  }
  if (!getIt.isRegistered<GroupsRepo>()) {
    getIt.registerLazySingleton<GroupsRepo>(
      () =>
          GroupsRepoImpl(groupsFirebaseService: getIt<GroupsFirebaseService>()),
    );
  }
  if (!getIt.isRegistered<MessageFirestoreService>()) {
    getIt.registerLazySingleton<MessageFirestoreService>(
      () => MessageFirestoreService(
        firestore: getIt<FirebaseFirestore>(),
        firebaseAuth: getIt<FirebaseAuth>(),
        firebaseStorage: getIt<FirebaseStorage>(),
      ),
    );
  }
  if (!getIt.isRegistered<MessageRepo>()) {
    getIt.registerLazySingleton<MessageRepo>(
      () => MessageRepoImpl(
        messageFirestoreService: getIt<MessageFirestoreService>(),
      ),
    );
  }
  if (!getIt.isRegistered<SettingsFirebaseService>()) {
    getIt.registerLazySingleton<SettingsFirebaseService>(
      () => SettingsFirebaseService(
        firebaseAuth: getIt<FirebaseAuth>(),
        firestore: getIt<FirebaseFirestore>(),
        firebaseStorage: getIt<FirebaseStorage>(),
      ),
    );
  }
  if (!getIt.isRegistered<SettingsRepo>()) {
    getIt.registerLazySingleton<SettingsRepo>(
      () => SettingsRepoImpl(
        settingsFirebaseService: getIt<SettingsFirebaseService>(),
      ),
    );
  }
  if (!getIt.isRegistered<SettingsCubit>()) {
    getIt.registerLazySingleton<SettingsCubit>(
      () => SettingsCubit(getIt<SettingsRepo>()),
    );
  }
}

void preloadAppData() {
  getIt<HomeCubit>().watchHomeIfNeeded();
  unawaited(getIt<SettingsCubit>().getCurrentUserIfNeeded());
}

void clearAppDataCache() {
  getIt<HomeCubit>().clearCache();
  getIt<SettingsCubit>().clearCache();
}
