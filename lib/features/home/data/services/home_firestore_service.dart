import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:test_codex/core/errors/custom_exception.dart';
import 'package:test_codex/features/home/data/models/conversation_model.dart';
import 'package:test_codex/features/home/data/models/home_story_model.dart';
import 'package:test_codex/features/home/data/models/home_user_model.dart';
import 'package:test_codex/features/home/domain/entities/conversation_entity.dart';
import 'package:test_codex/features/home/domain/entities/home_user_entity.dart';

class HomeFirestoreService {
  HomeFirestoreService({
    required this.firestore,
    required this.firebaseAuth,
    required this.firebaseStorage,
  });

  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;
  final FirebaseStorage firebaseStorage;

  Stream<List<ConversationModel>> watchConversations() {
    final currentUserId = _currentUserId;
    return firestore
        .collection('conversations')
        .where('participantIds', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      unawaited(_markIncomingMessagesAsDelivered(snapshot.docs));
      final conversations = await Future.wait(
        snapshot.docs.map(
          (doc) => _conversationFromDoc(
            doc: doc,
            currentUserId: currentUserId,
          ),
        ),
      );
      return _sortConversations(
        conversations,
      );
    });
  }

  Future<List<ConversationModel>> getConversations() async {
    final currentUserId = _currentUserId;
    final snapshot = await firestore
        .collection('conversations')
        .where('participantIds', arrayContains: currentUserId)
        .get();

    unawaited(_markIncomingMessagesAsDelivered(snapshot.docs));
    final conversations = await Future.wait(
      snapshot.docs.map(
        (doc) => _conversationFromDoc(
          doc: doc,
          currentUserId: currentUserId,
        ),
      ),
    );
    return _sortConversations(
      conversations,
    );
  }

  Future<ConversationModel> _conversationFromDoc({
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required String currentUserId,
  }) async {
    final data = Map<String, dynamic>.from(doc.data());
    final participantIds = List<String>.from(data['participantIds'] ?? []);
    final otherUserId = participantIds.firstWhere(
      (uId) => uId != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isNotEmpty) {
      await _mergeLatestUserProfile(
        conversationRef: doc.reference,
        conversationData: data,
        userId: otherUserId,
      );
    }

    return ConversationModel.fromFirestore(
      id: doc.id,
      currentUserId: currentUserId,
      json: data,
    );
  }

  Future<void> _mergeLatestUserProfile({
    required DocumentReference<Map<String, dynamic>> conversationRef,
    required Map<String, dynamic> conversationData,
    required String userId,
  }) async {
    final userDoc = await _getLatestUserDoc(userId);
    final userData = userDoc.data();
    if (userData == null) {
      return;
    }

    final participantNames = Map<String, dynamic>.from(
      conversationData['participantNames'] ?? {},
    );
    final participantEmails = Map<String, dynamic>.from(
      conversationData['participantEmails'] ?? {},
    );
    final participantPhotoUrls = Map<String, dynamic>.from(
      conversationData['participantPhotoUrls'] ?? {},
    );
    final latestName = userData['name'];
    final latestEmail = userData['email'];
    final latestPhotoUrl = userData['photoUrl'];
    var hasChanges = false;

    if (latestName is String &&
        latestName.trim().isNotEmpty &&
        participantNames[userId] != latestName) {
      participantNames[userId] = latestName;
      hasChanges = true;
    }
    if (latestEmail is String &&
        latestEmail.trim().isNotEmpty &&
        participantEmails[userId] != latestEmail) {
      participantEmails[userId] = latestEmail;
      hasChanges = true;
    }
    if (userData.containsKey('photoUrl')) {
      if (latestPhotoUrl is String && latestPhotoUrl.trim().isNotEmpty) {
        if (participantPhotoUrls[userId] != latestPhotoUrl) {
          participantPhotoUrls[userId] = latestPhotoUrl;
          hasChanges = true;
        }
      } else if (participantPhotoUrls[userId] != null) {
        participantPhotoUrls[userId] = null;
        hasChanges = true;
      }
    }

    conversationData['participantNames'] = participantNames;
    conversationData['participantEmails'] = participantEmails;
    conversationData['participantPhotoUrls'] = participantPhotoUrls;

    if (hasChanges) {
      unawaited(
        conversationRef.set({
          'participantNames': participantNames,
          'participantEmails': participantEmails,
          'participantPhotoUrls': participantPhotoUrls,
        }, SetOptions(merge: true)),
      );
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getLatestUserDoc(
    String userId,
  ) async {
    final userRef = firestore.collection('users').doc(userId);
    try {
      return await userRef.get(const GetOptions(source: Source.server));
    } catch (_) {
      return userRef.get();
    }
  }

  Future<void> _markIncomingMessagesAsDelivered(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> conversations,
  ) async {
    final currentUserId = _currentUserId;
    for (final conversation in conversations) {
      final messages = await conversation.reference
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'sent')
          .get();
      final legacyMessages = await conversation.reference
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isNull: true)
          .get();
      final deliveredMessages = [
        ...messages.docs,
        ...legacyMessages.docs,
      ];
      if (deliveredMessages.isEmpty) {
        continue;
      }

      final batch = firestore.batch();
      for (final message in deliveredMessages) {
        batch.update(message.reference, {'status': 'delivered'});
      }
      await batch.commit();
    }
  }

  List<ConversationModel> _sortConversations(
    List<ConversationModel> conversations,
  ) {
    conversations.sort((a, b) {
      final firstDate = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final secondDate = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return secondDate.compareTo(firstDate);
    });

    return conversations;
  }

  Stream<List<HomeStoryModel>> watchStoriesForChattedUsers(
    List<ConversationEntity> conversations,
  ) {
    final userIds = {
      _currentUserId,
      ...conversations
          .map((conversation) => conversation.otherUser.uId)
          .where((uId) => uId.isNotEmpty),
    }.take(10).toList();

    if (userIds.isEmpty) {
      return Stream.value([]);
    }

    return firestore
        .collection('stories')
        .where('uId', whereIn: userIds)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final expiredStories = snapshot.docs.where((doc) {
        return !_isStoryActive(doc.data(), now);
      }).toList();
      unawaited(_deleteExpiredStories(expiredStories));

      final stories = snapshot.docs
          .where((doc) {
            return _isStoryActive(doc.data(), now);
          })
          .map(
            (doc) => HomeStoryModel.fromFirestore(
              id: doc.id,
              json: doc.data(),
              currentUserId: _currentUserId,
            ),
          )
          .toList();
      stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return stories;
    });
  }

  bool _isStoryActive(Map<String, dynamic> data, DateTime now) {
    final expiresAt = data['expiresAt'];
    if (expiresAt is Timestamp) {
      return expiresAt.toDate().isAfter(now);
    }

    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) {
      return createdAt.toDate().add(const Duration(hours: 24)).isAfter(now);
    }

    return false;
  }

  Future<void> addStory(String content) async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw CustomException('Please sign in again.');
    }

    final storyContent = content.trim();
    if (storyContent.isEmpty) {
      throw CustomException('Please write a story first.');
    }

    final userName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.email?.split('@').first ?? 'You';

    await firestore.collection('stories').add({
      'uId': user.uid,
      'userName': userName,
      'userEmail': user.email ?? '',
      'photoUrl': user.photoURL,
      'content': storyContent,
      'type': 'text',
      'mediaUrl': null,
      'viewedBy': [user.uid],
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 24)),
      ),
    });
  }

  Future<void> addMediaStory({
    required String filePath,
    required String type,
    required String content,
  }) async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw CustomException('Please sign in again.');
    }

    final storyType = type.trim().toLowerCase();
    if (storyType != 'image' && storyType != 'video') {
      throw CustomException('Unsupported story type.');
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      throw CustomException('Story file was not found.');
    }

    final userName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.email?.split('@').first ?? 'You';
    final extension = filePath.split('.').last;
    final ref = firebaseStorage.ref(
      'stories/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.$extension',
    );
    await ref.putFile(file);
    final mediaUrl = await ref.getDownloadURL();

    await firestore.collection('stories').add({
      'uId': user.uid,
      'userName': userName,
      'userEmail': user.email ?? '',
      'photoUrl': user.photoURL,
      'content': content.trim(),
      'type': storyType,
      'mediaUrl': mediaUrl,
      'viewedBy': [user.uid],
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 24)),
      ),
    });
  }

  Future<void> markStoryAsSeen(String storyId) async {
    if (storyId.isEmpty) {
      return;
    }

    await firestore.collection('stories').doc(storyId).set({
      'viewedBy': FieldValue.arrayUnion([_currentUserId]),
    }, SetOptions(merge: true));
  }

  Future<void> _deleteExpiredStories(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> stories,
  ) async {
    if (stories.isEmpty) {
      return;
    }

    final batch = firestore.batch();
    final mediaDeletes = <Future<void>>[];
    for (final story in stories) {
      final mediaUrl = story.data()['mediaUrl'];
      if (mediaUrl is String && mediaUrl.trim().isNotEmpty) {
        mediaDeletes.add(_deleteStoryMedia(mediaUrl));
      }
      batch.delete(story.reference);
    }

    await Future.wait(mediaDeletes);
    await batch.commit();
  }

  Future<void> _deleteStoryMedia(String mediaUrl) async {
    try {
      await firebaseStorage.refFromURL(mediaUrl).delete();
    } catch (_) {}
  }

  Future<List<HomeUserModel>> searchUsersByEmail(String email) async {
    final query = email.trim().toLowerCase();
    if (query.isEmpty) {
      return [];
    }

    final snapshot = await firestore
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) => HomeUserModel.fromJson(doc.data()))
        .where((user) => user.uId != _currentUserId)
        .toList();
  }

  Future<ConversationModel> createConversationWithUser(
    HomeUserEntity user,
  ) async {
    final currentUser = firebaseAuth.currentUser;
    if (currentUser == null) {
      throw CustomException('Please sign in again.');
    }

    final currentName = currentUser.displayName?.trim().isNotEmpty == true
        ? currentUser.displayName!.trim()
        : currentUser.email?.split('@').first ?? 'You';
    final conversationId = _conversationId(currentUser.uid, user.uId);
    final conversationRef = firestore.collection('conversations').doc(
          conversationId,
        );

    await conversationRef.set({
      'participantIds': [currentUser.uid, user.uId],
      'participantEmails': {
        currentUser.uid: currentUser.email ?? '',
        user.uId: user.email,
      },
      'participantPhotoUrls': {
        currentUser.uid: currentUser.photoURL,
        user.uId: user.photoUrl,
      },
      'participantNames': {
        currentUser.uid: currentName,
        user.uId: user.name,
      },
      'lastMessage': '',
      'unreadCounts': {
        currentUser.uid: 0,
        user.uId: 0,
      },
      'onlineUsers': <String>[],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final doc = await conversationRef.get();
    return ConversationModel.fromFirestore(
      id: doc.id,
      currentUserId: currentUser.uid,
      json: doc.data() ?? {},
    );
  }

  String get _currentUserId {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw CustomException('Please sign in again.');
    }
    return user.uid;
  }

  String _conversationId(String firstUserId, String secondUserId) {
    final ids = [firstUserId, secondUserId]..sort();
    return ids.join('_');
  }
}
