import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:test_codex/core/errors/custom_exception.dart';
import 'package:test_codex/features/home/data/models/conversation_model.dart';
import 'package:test_codex/features/message/data/models/message_model.dart';

class MessageFirestoreService {
  MessageFirestoreService({
    required this.firestore,
    required this.firebaseAuth,
    required this.firebaseStorage,
  });

  static const Duration onlinePresenceTimeout = Duration(minutes: 2);

  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;
  final FirebaseStorage firebaseStorage;

  Stream<ConversationModel> watchConversation(String conversationId) {
    final currentUserId = _currentUserId;
    return firestore
        .collection('conversations')
        .doc(conversationId)
        .snapshots()
        .asyncMap(
          (doc) async => ConversationModel.fromFirestore(
            id: doc.id,
            currentUserId: currentUserId,
            json: await _conversationDataWithLatestProfile(
              conversationId: doc.id,
              currentUserId: currentUserId,
              data: doc.data() ?? {},
            ),
          ),
        );
  }

  Stream<List<MessageModel>> getMessages(String conversationId) {
    final currentUserId = _currentUserId;
    return firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => MessageModel.fromFirestore(
                  id: doc.id,
                  currentUserId: currentUserId,
                  json: doc.data(),
                ),
              )
              .toList(),
        );
  }

  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String text,
  }) async {
    final currentUserId = _currentUserId;
    final messageText = text.trim();
    if (messageText.isEmpty) {
      throw CustomException('Please write a message first.');
    }

    final conversationRef = firestore
        .collection('conversations')
        .doc(conversationId);
    final messageRef = conversationRef.collection('messages').doc();

    await firestore.runTransaction((transaction) async {
      final conversationSnapshot = await transaction.get(conversationRef);
      final conversationData = conversationSnapshot.data() ?? {};
      final onlineUsers = List<String>.from(
        conversationData['onlineUsers'] ?? [],
      );
      final onlineUserUpdatedAt = Map<String, dynamic>.from(
        conversationData['onlineUserUpdatedAt'] ?? {},
      );
      final receiverIsOnline = _isUserOnline(
        userId: receiverId,
        onlineUsers: onlineUsers,
        onlineUserUpdatedAt: onlineUserUpdatedAt,
      );
      final messageStatus = receiverIsOnline ? 'read' : 'sent';

      transaction.set(messageRef, {
        'text': messageText,
        'senderId': currentUserId,
        'receiverId': receiverId,
        'type': 'text',
        'mediaUrl': null,
        'status': messageStatus,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(conversationRef, {
        'lastMessage': messageText,
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCounts.$currentUserId': 0,
        'unreadCounts.$receiverId': receiverIsOnline
            ? 0
            : FieldValue.increment(1),
      });
    });
  }

  Future<void> sendMediaMessage({
    required String conversationId,
    required String receiverId,
    required String filePath,
    required String type,
    required String text,
  }) async {
    final currentUserId = _currentUserId;
    final messageType = type.trim().toLowerCase();
    if (!['image', 'video', 'voice'].contains(messageType)) {
      throw CustomException('Unsupported message type.');
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw CustomException('Selected file was not found.');
    }

    final extension = _fileExtension(filePath, messageType);
    final ref = firebaseStorage.ref(
      'messages/$conversationId/$currentUserId/'
      '${DateTime.now().millisecondsSinceEpoch}.$extension',
    );
    await ref.putFile(file);
    final mediaUrl = await ref.getDownloadURL();

    final conversationRef = firestore
        .collection('conversations')
        .doc(conversationId);
    final messageRef = conversationRef.collection('messages').doc();
    final previewText = _previewText(messageType, text);

    await firestore.runTransaction((transaction) async {
      final conversationSnapshot = await transaction.get(conversationRef);
      final conversationData = conversationSnapshot.data() ?? {};
      final onlineUsers = List<String>.from(
        conversationData['onlineUsers'] ?? [],
      );
      final onlineUserUpdatedAt = Map<String, dynamic>.from(
        conversationData['onlineUserUpdatedAt'] ?? {},
      );
      final receiverIsOnline = _isUserOnline(
        userId: receiverId,
        onlineUsers: onlineUsers,
        onlineUserUpdatedAt: onlineUserUpdatedAt,
      );
      final messageStatus = receiverIsOnline ? 'read' : 'sent';

      transaction.set(messageRef, {
        'text': text.trim(),
        'senderId': currentUserId,
        'receiverId': receiverId,
        'type': messageType,
        'mediaUrl': mediaUrl,
        'status': messageStatus,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(conversationRef, {
        'lastMessage': previewText,
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCounts.$currentUserId': 0,
        'unreadCounts.$receiverId': receiverIsOnline
            ? 0
            : FieldValue.increment(1),
      });
    });
  }

  Future<void> updateMessage({
    required String conversationId,
    required String messageId,
    required String text,
  }) async {
    final currentUserId = _currentUserId;
    final messageText = text.trim();
    if (messageText.isEmpty) {
      throw CustomException('Please write a message first.');
    }

    final conversationRef = firestore
        .collection('conversations')
        .doc(conversationId);
    final messageRef = conversationRef.collection('messages').doc(messageId);

    await firestore.runTransaction((transaction) async {
      final messageSnapshot = await transaction.get(messageRef);
      final conversationSnapshot = await transaction.get(conversationRef);
      final messageData = messageSnapshot.data();
      if (messageData == null) {
        throw CustomException('Message was not found.');
      }
      if (messageData['senderId'] != currentUserId) {
        throw CustomException('You can only edit your messages.');
      }
      if (messageData['type'] != 'text') {
        throw CustomException('Only text messages can be edited.');
      }

      transaction.update(messageRef, {
        'text': messageText,
        'editedAt': FieldValue.serverTimestamp(),
      });

      final conversationData = conversationSnapshot.data() ?? {};
      if (conversationData['lastMessage'] == messageData['text']) {
        transaction.update(conversationRef, {
          'lastMessage': messageText,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    final currentUserId = _currentUserId;
    final conversationRef = firestore
        .collection('conversations')
        .doc(conversationId);
    final messageRef = conversationRef.collection('messages').doc(messageId);

    await firestore.runTransaction((transaction) async {
      final messageSnapshot = await transaction.get(messageRef);
      final conversationSnapshot = await transaction.get(conversationRef);
      final messageData = messageSnapshot.data();
      if (messageData == null) {
        throw CustomException('Message was not found.');
      }
      if (messageData['senderId'] != currentUserId) {
        throw CustomException('You can only delete your messages.');
      }

      transaction.delete(messageRef);

      final conversationData = conversationSnapshot.data() ?? {};
      if (conversationData['lastMessage'] ==
          _previewText(
            messageData['type'] ?? 'text',
            messageData['text'] ?? '',
          )) {
        transaction.update(conversationRef, {
          'lastMessage': 'Message deleted',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> markConversationAsRead(String conversationId) async {
    await firestore.collection('conversations').doc(conversationId).update({
      'unreadCounts.$_currentUserId': 0,
    });
    await _markIncomingMessagesAsRead(conversationId);
  }

  Future<void> updateConversationPresence({
    required String conversationId,
    required bool isOnline,
  }) async {
    final currentUserId = _currentUserId;
    final presenceUpdatedAtPath = 'onlineUserUpdatedAt.$currentUserId';

    await firestore.collection('conversations').doc(conversationId).update({
      'onlineUsers': isOnline
          ? FieldValue.arrayUnion([currentUserId])
          : FieldValue.arrayRemove([currentUserId]),
      presenceUpdatedAtPath: isOnline
          ? FieldValue.serverTimestamp()
          : FieldValue.delete(),
      'unreadCounts.$currentUserId': 0,
    });
    if (isOnline) {
      await _markIncomingMessagesAsRead(conversationId);
    }
  }

  Future<void> _markIncomingMessagesAsRead(String conversationId) async {
    final snapshot = await firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('receiverId', isEqualTo: _currentUserId)
        .where('status', whereIn: ['sent', 'delivered'])
        .get();
    final legacySnapshot = await firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('receiverId', isEqualTo: _currentUserId)
        .where('status', isNull: true)
        .get();
    final unreadMessages = [...snapshot.docs, ...legacySnapshot.docs];
    if (unreadMessages.isEmpty) {
      return;
    }

    final batch = firestore.batch();
    for (final doc in unreadMessages) {
      batch.update(doc.reference, {'status': 'read'});
    }
    await batch.commit();
  }

  String get _currentUserId {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw CustomException('Please sign in again.');
    }
    return user.uid;
  }

  bool _isUserOnline({
    required String userId,
    required List<String> onlineUsers,
    required Map<String, dynamic> onlineUserUpdatedAt,
  }) {
    final updatedAt = onlineUserUpdatedAt[userId];
    if (updatedAt is! Timestamp) {
      return false;
    }

    return onlineUsers.contains(userId) &&
        DateTime.now().difference(updatedAt.toDate()) <= onlinePresenceTimeout;
  }

  Future<Map<String, dynamic>> _conversationDataWithLatestProfile({
    required String conversationId,
    required String currentUserId,
    required Map<String, dynamic> data,
  }) async {
    final conversationData = Map<String, dynamic>.from(data);
    final participantIds = List<String>.from(
      conversationData['participantIds'] ?? [],
    );
    final otherUserId = participantIds.firstWhere(
      (uId) => uId != currentUserId,
      orElse: () => '',
    );
    if (otherUserId.isEmpty) {
      return conversationData;
    }

    final userDoc = await firestore.collection('users').doc(otherUserId).get();
    final userData = userDoc.data();
    if (userData == null) {
      return conversationData;
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
        participantNames[otherUserId] != latestName) {
      participantNames[otherUserId] = latestName;
      hasChanges = true;
    }
    if (latestEmail is String &&
        latestEmail.trim().isNotEmpty &&
        participantEmails[otherUserId] != latestEmail) {
      participantEmails[otherUserId] = latestEmail;
      hasChanges = true;
    }
    if (latestPhotoUrl is String &&
        latestPhotoUrl.trim().isNotEmpty &&
        participantPhotoUrls[otherUserId] != latestPhotoUrl) {
      participantPhotoUrls[otherUserId] = latestPhotoUrl;
      hasChanges = true;
    }

    conversationData['participantNames'] = participantNames;
    conversationData['participantEmails'] = participantEmails;
    conversationData['participantPhotoUrls'] = participantPhotoUrls;

    if (hasChanges) {
      unawaited(
        firestore.collection('conversations').doc(conversationId).set({
          'participantNames': participantNames,
          'participantEmails': participantEmails,
          'participantPhotoUrls': participantPhotoUrls,
        }, SetOptions(merge: true)),
      );
    }

    return conversationData;
  }

  String _fileExtension(String filePath, String type) {
    final fileName = filePath.split(Platform.pathSeparator).last;
    if (fileName.contains('.')) {
      return fileName.split('.').last;
    }

    return switch (type) {
      'image' => 'jpg',
      'video' => 'mp4',
      'voice' => 'm4a',
      _ => 'file',
    };
  }

  String _previewText(String type, String text) {
    final cleanText = text.trim();
    if (cleanText.isNotEmpty) {
      return cleanText;
    }

    return switch (type) {
      'image' => 'Photo',
      'video' => 'Video',
      'voice' => 'Voice message',
      _ => 'Attachment',
    };
  }
}
