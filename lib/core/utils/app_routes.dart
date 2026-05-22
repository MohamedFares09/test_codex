import 'package:flutter/material.dart';
import 'package:test_codex/features/auth/presentation/views/login_view.dart';
import 'package:test_codex/features/auth/presentation/views/register_view.dart';
import 'package:test_codex/features/auth/presentation/views/splash_view.dart';
import 'package:test_codex/features/groups/domain/entities/group_entity.dart';
import 'package:test_codex/features/groups/presentation/views/group_chat_view.dart';
import 'package:test_codex/features/groups/presentation/views/group_details_view.dart';
import 'package:test_codex/features/groups/presentation/views/groups_view.dart';
import 'package:test_codex/features/groups/presentation/views/new_group_view.dart';
import 'package:test_codex/features/home/domain/entities/conversation_entity.dart';
import 'package:test_codex/features/home/presentation/views/home_view.dart';
import 'package:test_codex/features/message/presentation/views/message_contact_info_view.dart';
import 'package:test_codex/features/message/presentation/views/message_view.dart';
import 'package:test_codex/features/settings/presentation/views/settings_view.dart';

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case SplashView.route:
      return MaterialPageRoute(builder: (_) => const SplashView());
    case LoginView.route:
      return MaterialPageRoute(builder: (_) => const LoginView());
    case RegisterView.route:
      return MaterialPageRoute(builder: (_) => const RegisterView());
    case HomeView.route:
      return MaterialPageRoute(builder: (_) => const HomeView());
    case GroupsView.route:
      return MaterialPageRoute(builder: (_) => const GroupsView());
    case NewGroupView.route:
      return MaterialPageRoute(builder: (_) => const NewGroupView());
    case GroupChatView.route:
      final group = settings.arguments as GroupEntity;
      return MaterialPageRoute(builder: (_) => GroupChatView(group: group));
    case GroupDetailsView.route:
      final group = settings.arguments as GroupEntity;
      return MaterialPageRoute(builder: (_) => GroupDetailsView(group: group));
    case MessageView.route:
      final conversation = settings.arguments as ConversationEntity;
      return MaterialPageRoute(
        builder: (_) => MessageView(conversation: conversation),
      );
    case MessageContactInfoView.route:
      final conversation = settings.arguments as ConversationEntity;
      return MaterialPageRoute(
        builder: (_) => MessageContactInfoView(conversation: conversation),
      );
    case SettingsView.route:
      return MaterialPageRoute(builder: (_) => const SettingsView());
    default:
      return MaterialPageRoute(builder: (_) => const SplashView());
  }
}
