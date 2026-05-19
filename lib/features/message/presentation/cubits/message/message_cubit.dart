import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_codex/features/home/domain/entities/conversation_entity.dart';
import 'package:test_codex/features/message/domain/entities/message_entity.dart';
import 'package:test_codex/features/message/domain/repos/message_repo.dart';
import 'package:test_codex/features/message/presentation/cubits/message/message_state.dart';

class MessageCubit extends Cubit<MessageState> with WidgetsBindingObserver {
  MessageCubit(this.messageRepo) : super(MessageInitialState()) {
    WidgetsBinding.instance.addObserver(this);
  }

  final MessageRepo messageRepo;
  static const Duration _presenceRefreshInterval = Duration(seconds: 45);

  StreamSubscription<List<MessageEntity>>? _messagesSubscription;
  StreamSubscription<ConversationEntity>? _conversationSubscription;
  Timer? _presenceTimer;
  List<MessageEntity> messages = [];
  ConversationEntity? activeConversation;
  String? activeConversationId;
  bool _isConversationOnline = false;

  void openConversation(ConversationEntity conversation) {
    activeConversation = conversation;
    getMessages(conversation.id);
    watchConversation(conversation.id);
  }

  void getMessages(String conversationId) {
    emit(MessageLoadingState());
    final previousConversationId = activeConversationId;
    activeConversationId = conversationId;
    if (previousConversationId != null &&
        previousConversationId != conversationId) {
      unawaited(
        updateConversationPresence(
          conversationId: previousConversationId,
          isOnline: false,
        ),
      );
    }
    _setActiveConversationOnline(conversationId);
    _messagesSubscription?.cancel();
    _messagesSubscription = messageRepo
        .getMessages(conversationId)
        .listen(
          (items) {
            messages = items;
            emit(MessageSuccessState(messages));
            markConversationAsRead(conversationId);
          },
          onError: (_) {
            emit(MessageErrorState('Something went wrong. Please try again.'));
          },
        );
  }

  void watchConversation(String conversationId) {
    _conversationSubscription?.cancel();
    _conversationSubscription = messageRepo
        .watchConversation(conversationId)
        .listen(
          (conversation) {
            activeConversation = conversation;
            emit(MessageConversationUpdatedState(conversation));
          },
          onError: (_) {
            emit(MessageErrorState('Something went wrong. Please try again.'));
          },
        );
  }

  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String text,
  }) async {
    emit(MessageSendLoadingState(messages));
    final result = await messageRepo.sendMessage(
      conversationId: conversationId,
      receiverId: receiverId,
      text: text,
    );
    result.fold(
      (failure) => emit(MessageErrorState(failure.message)),
      (_) => emit(MessageSentState(messages)),
    );
  }

  Future<void> sendMediaMessage({
    required String conversationId,
    required String receiverId,
    required String filePath,
    required String type,
    String text = '',
  }) async {
    emit(MessageSendLoadingState(messages));
    final result = await messageRepo.sendMediaMessage(
      conversationId: conversationId,
      receiverId: receiverId,
      filePath: filePath,
      type: type,
      text: text,
    );
    result.fold(
      (failure) => emit(MessageErrorState(failure.message)),
      (_) => emit(MessageSentState(messages)),
    );
  }

  Future<void> updateMessage({
    required String messageId,
    required String text,
  }) async {
    final conversationId = activeConversationId;
    if (conversationId == null) {
      emit(MessageErrorState('Conversation was not found.'));
      return;
    }
    emit(MessageSendLoadingState(messages));
    final result = await messageRepo.updateMessage(
      conversationId: conversationId,
      messageId: messageId,
      text: text,
    );
    result.fold(
      (failure) => emit(MessageErrorState(failure.message)),
      (_) => emit(MessageSentState(messages)),
    );
  }

  Future<void> deleteMessage(String messageId) async {
    final conversationId = activeConversationId;
    if (conversationId == null) {
      emit(MessageErrorState('Conversation was not found.'));
      return;
    }
    emit(MessageSendLoadingState(messages));
    final result = await messageRepo.deleteMessage(
      conversationId: conversationId,
      messageId: messageId,
    );
    result.fold(
      (failure) => emit(MessageErrorState(failure.message)),
      (_) => emit(MessageSentState(messages)),
    );
  }

  Future<void> markConversationAsRead(String conversationId) async {
    await messageRepo.markConversationAsRead(conversationId);
  }

  Future<void> updateConversationPresence({
    required String conversationId,
    required bool isOnline,
  }) async {
    await messageRepo.updateConversationPresence(
      conversationId: conversationId,
      isOnline: isOnline,
    );
  }

  void _setActiveConversationOnline(String conversationId) {
    _isConversationOnline = true;
    unawaited(
      updateConversationPresence(
        conversationId: conversationId,
        isOnline: true,
      ),
    );
    _startPresenceTimer();
  }

  void _startPresenceTimer() {
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(_presenceRefreshInterval, (_) {
      final conversationId = activeConversationId;
      if (conversationId == null || !_isConversationOnline) {
        return;
      }

      unawaited(
        updateConversationPresence(
          conversationId: conversationId,
          isOnline: true,
        ),
      );
    });
  }

  Future<void> _setActiveConversationOffline() async {
    final conversationId = activeConversationId;
    _isConversationOnline = false;
    _presenceTimer?.cancel();
    _presenceTimer = null;

    if (conversationId == null) {
      return;
    }

    await updateConversationPresence(
      conversationId: conversationId,
      isOnline: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final conversationId = activeConversationId;
    if (conversationId == null) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _setActiveConversationOnline(conversationId);
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(_setActiveConversationOffline());
    }
  }

  @override
  Future<void> close() async {
    await _messagesSubscription?.cancel();
    await _conversationSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    await _setActiveConversationOffline();
    return super.close();
  }
}
