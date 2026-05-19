import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:test_codex/core/errors/custom_exception.dart';

class FirebaseAuthService {
  FirebaseAuthService({
    required this.firebaseAuth,
    required this.firestore,
    required this.firebaseStorage,
  });

  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final FirebaseStorage firebaseStorage;

  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _saveUserDataIfNeeded(credential.user!);
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw CustomException(_firebaseAuthMessage(e));
    } catch (_) {
      throw CustomException('Something went wrong. Please try again.');
    }
  }

  Future<User> createUserWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    String? imagePath,
  }) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final photoUrl = await _uploadProfileImage(
        uid: credential.user!.uid,
        imagePath: imagePath,
      );
      await credential.user!.updateDisplayName(name);
      if (photoUrl != null) {
        await credential.user!.updatePhotoURL(photoUrl);
      }
      await credential.user!.reload();
      final user = firebaseAuth.currentUser ?? credential.user!;
      await _saveUserDataIfNeeded(user, name: name, photoUrl: photoUrl);
      return user;
    } on FirebaseAuthException catch (e) {
      throw CustomException(_firebaseAuthMessage(e));
    } on CustomException {
      rethrow;
    } catch (_) {
      throw CustomException('Something went wrong. Please try again.');
    }
  }

  String _firebaseAuthMessage(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'Please check your internet connection.';
      default:
        return exception.message ?? 'Authentication failed. Please try again.';
    }
  }

  Future<void> _saveUserDataIfNeeded(
    User user, {
    String? name,
    String? photoUrl,
  }) async {
    final userName = name?.trim().isNotEmpty == true
        ? name!.trim()
        : user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : user.email?.split('@').first ?? 'User';
    await firestore.collection('users').doc(user.uid).set({
      'uId': user.uid,
      'name': userName,
      'email': user.email?.toLowerCase() ?? '',
      'photoUrl': photoUrl ?? user.photoURL,
    }, SetOptions(merge: true));
  }

  Future<String?> _uploadProfileImage({
    required String uid,
    required String? imagePath,
  }) async {
    final cleanPath = imagePath?.trim();
    if (cleanPath == null || cleanPath.isEmpty) {
      return null;
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
}
