import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_codex/features/home/domain/entities/conversation_entity.dart';
import 'package:test_codex/features/home/domain/entities/home_story_entity.dart';
import 'package:test_codex/features/home/domain/entities/home_user_entity.dart';
import 'package:test_codex/features/home/domain/repos/home_repo.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this.homeRepo) : super(HomeInitialState());

  final HomeRepo homeRepo;
  static const Duration _presenceRefreshInterval = Duration(seconds: 30);

  StreamSubscription<List<ConversationEntity>>? _conversationsSubscription;
  StreamSubscription<List<HomeStoryEntity>>? _storiesSubscription;
  Timer? _presenceRefreshTimer;
  List<ConversationEntity> conversations = [];
  List<HomeStoryEntity> stories = [];
  List<HomeUserEntity> searchResults = [];
  bool _isRefreshingPresence = false;

  void watchHome() {
    emit(HomeLoadingState());
    _startPresenceRefreshTimer();
    _conversationsSubscription?.cancel();
    _conversationsSubscription = homeRepo.watchConversations().listen(
      (items) {
        conversations = items;
        _watchStoriesForCurrentConversations();
        _emitSuccess();
      },
      onError: (_) {
        emit(HomeErrorState('Something went wrong. Please try again.'));
      },
    );
  }

  Future<void> _refreshConversationsPresence() async {
    if (_isRefreshingPresence) {
      return;
    }

    _isRefreshingPresence = true;
    final result = await homeRepo.getConversations();
    result.fold(
      (_) {},
      (items) {
        conversations = items;
        _watchStoriesForCurrentConversations();
        _emitSuccess();
      },
    );
    _isRefreshingPresence = false;
  }

  void _startPresenceRefreshTimer() {
    _presenceRefreshTimer?.cancel();
    _presenceRefreshTimer = Timer.periodic(_presenceRefreshInterval, (_) {
      unawaited(_refreshConversationsPresence());
    });
  }

  Future<void> getConversations() async {
    emit(HomeLoadingState());
    final result = await homeRepo.getConversations();
    result.fold(
      (failure) => emit(HomeErrorState(failure.message)),
      (items) {
        conversations = items;
        _watchStoriesForCurrentConversations();
        _emitSuccess();
      },
    );
  }

  Future<void> searchUsersByEmail(String email) async {
    emit(HomeSearchLoadingState(conversations: conversations));
    final result = await homeRepo.searchUsersByEmail(email);
    result.fold(
      (failure) => emit(HomeErrorState(failure.message)),
      (users) {
        searchResults = users;
        _emitSuccess();
      },
    );
  }

  Future<void> createConversationWithUser(HomeUserEntity user) async {
    emit(HomeActionLoadingState(conversations: conversations));
    final result = await homeRepo.createConversationWithUser(user);
    result.fold(
      (failure) => emit(HomeErrorState(failure.message)),
      (conversation) async {
        searchResults = [];
        emit(HomeConversationCreatedState(conversation));
      },
    );
  }

  Future<void> addStory(String content) async {
    emit(HomeStoryActionLoadingState());
    final result = await homeRepo.addStory(content);
    result.fold(
      (failure) => emit(HomeErrorState(failure.message)),
      (_) => _emitSuccess(),
    );
  }

  Future<void> addMediaStory({
    required String filePath,
    required String type,
    String content = '',
  }) async {
    emit(HomeStoryActionLoadingState());
    final result = await homeRepo.addMediaStory(
      filePath: filePath,
      type: type,
      content: content,
    );
    result.fold(
      (failure) => emit(HomeErrorState(failure.message)),
      (_) => _emitSuccess(),
    );
  }

  Future<void> markStoryAsSeen(HomeStoryEntity story) async {
    if (story.isSeen) {
      return;
    }

    final result = await homeRepo.markStoryAsSeen(story.id);
    result.fold(
      (failure) => emit(HomeErrorState(failure.message)),
      (_) {},
    );
  }

  void clearSearch() {
    searchResults = [];
    _emitSuccess();
  }

  void _watchStoriesForCurrentConversations() {
    _storiesSubscription?.cancel();
    _storiesSubscription = homeRepo
        .watchStoriesForChattedUsers(conversations)
        .listen(
          (items) {
            stories = items;
            _emitSuccess();
          },
          onError: (_) {
            emit(HomeErrorState('Something went wrong. Please try again.'));
          },
        );
  }

  void _emitSuccess() {
    emit(
      HomeSuccessState(
        conversations: conversations,
        searchResults: searchResults,
        stories: stories,
      ),
    );
  }

  @override
  Future<void> close() {
    _presenceRefreshTimer?.cancel();
    _conversationsSubscription?.cancel();
    _storiesSubscription?.cancel();
    return super.close();
  }
}
