import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:test_codex/core/errors/custom_exception.dart';
import 'package:test_codex/features/settings/data/models/settings_user_model.dart';

class SettingsFirebaseService {
  SettingsFirebaseService({
    required this.firebaseAuth,
    required this.firestore,
    required this.firebaseStorage,
  });

  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final FirebaseStorage firebaseStorage;

  Future<SettingsUserModel> getCurrentUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw CustomException('Please sign in again.');
    }

    final userDoc = await firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    if (userData == null) {
      return SettingsUserModel.fromFirebaseUser(user);
    }

    return SettingsUserModel.fromJson(
      json: userData,
      fallbackUser: user,
    );
  }

  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  Future<SettingsUserModel> updateProfile({
    required String name,
    String? imagePath,
    bool deletePhoto = false,
  }) async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw CustomException('Please sign in again.');
    }

    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw CustomException('Please enter your name.');
    }

    final userDoc = await firestore.collection('users').doc(user.uid).get();
    final savedPhotoUrl = userDoc.data()?['photoUrl'];
    final currentPhotoUrl = user.photoURL ??
        (savedPhotoUrl is String && savedPhotoUrl.trim().isNotEmpty
            ? savedPhotoUrl
            : null);
    final photoUrl = deletePhoto
        ? null
        : await _uploadProfileImage(
            uid: user.uid,
            imagePath: imagePath,
            fallbackPhotoUrl: currentPhotoUrl,
          );

    await user.updateDisplayName(cleanName);
    if (deletePhoto || photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }
    await user.reload();

    final refreshedUser = firebaseAuth.currentUser ?? user;
    final userModel = SettingsUserModel(
      uId: refreshedUser.uid,
      name: cleanName,
      email: refreshedUser.email ?? user.email ?? '',
      photoUrl: photoUrl,
    );

    await firestore.collection('users').doc(user.uid).set(
          userModel.toMap(),
          SetOptions(merge: true),
        );
    if (deletePhoto && currentPhotoUrl != null) {
      await _deleteProfileImage(currentPhotoUrl);
    }
    await _syncProfileToConversations(
      uid: user.uid,
      name: cleanName,
      photoUrl: photoUrl,
    );

    return userModel;
  }

  Future<String?> _uploadProfileImage({
    required String uid,
    required String? imagePath,
    required String? fallbackPhotoUrl,
  }) async {
    final cleanPath = imagePath?.trim();
    if (cleanPath == null || cleanPath.isEmpty) {
      return fallbackPhotoUrl;
    }

    final file = File(cleanPath);
    if (!await file.exists()) {
      throw CustomException('Selected profile image was not found.');
    }

    final fileName = file.uri.pathSegments.last;
    final extension = fileName.contains('.') ? fileName.split('.').last : 'jpg';
    final ref = firebaseStorage.ref(
      'users/$uid/profile_${DateTime.now().millisecondsSinceEpoch}.$extension',
    );
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> _deleteProfileImage(String photoUrl) async {
    try {
      await firebaseStorage.refFromURL(photoUrl).delete();
    } catch (_) {}
  }

  Future<void> _syncProfileToConversations({
    required String uid,
    required String name,
    required String? photoUrl,
  }) async {
    final conversations = await firestore
        .collection('conversations')
        .where('participantIds', arrayContains: uid)
        .get();
    if (conversations.docs.isEmpty) {
      return;
    }

    final batch = firestore.batch();
    for (final doc in conversations.docs) {
      batch.set(
        doc.reference,
        {
          'participantNames': {uid: name},
          'participantPhotoUrls': {uid: photoUrl},
          'participantProfileUpdatedAt': {uid: FieldValue.serverTimestamp()},
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }
}
