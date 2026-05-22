import 'package:flutter/material.dart';
import 'package:test_codex/core/utils/route_names.dart';
import 'package:test_codex/features/home/domain/entities/conversation_entity.dart';
import 'package:test_codex/features/message/presentation/widgets/message_contact_info_view_body.dart';

class MessageContactInfoView extends StatelessWidget {
  const MessageContactInfoView({required this.conversation, super.key});

  static const String route = RouteNames.messageContactInfo;

  final ConversationEntity conversation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MessageContactInfoViewBody(conversation: conversation),
    );
  }
}
