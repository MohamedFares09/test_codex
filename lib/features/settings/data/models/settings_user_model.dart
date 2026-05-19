import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_codex/features/settings/domain/entities/settings_user_entity.dart';

class SettingsUserModel extends SettingsUserEntity {
  const SettingsUserModel({
    required super.uId,
    required super.name,
    required super.email,
    super.photoUrl,
  });

  factory SettingsUserModel.fromFirebaseUser(User user) {
    final email = user.email ?? '';
    return SettingsUserModel(
      uId: user.uid,
      name: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : email.split('@').first,
      email: email,
      photoUrl: user.photoURL,
    );
  }

  factory SettingsUserModel.fromJson({
    required Map<String, dynamic> json,
    required User fallbackUser,
  }) {
    final fallback = SettingsUserModel.fromFirebaseUser(fallbackUser);
    return SettingsUserModel(
      uId: json['uId'] ?? fallback.uId,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : fallback.name,
      email: (json['email'] as String?)?.trim().isNotEmpty == true
          ? (json['email'] as String).trim()
          : fallback.email,
      photoUrl: json.containsKey('photoUrl')
          ? json['photoUrl']
          : fallback.photoUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uId': uId,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
    };
  }
}
