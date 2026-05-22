import 'package:flutter/material.dart';
import 'package:test_codex/core/utils/app_colors.dart';
import 'package:test_codex/features/home/domain/entities/conversation_entity.dart';
import 'package:test_codex/features/message/presentation/views/message_contact_info_view.dart';
import 'package:test_codex/features/message/presentation/widgets/message_user_avatar.dart';

class MessageHeader extends StatelessWidget {
  const MessageHeader({required this.conversation, super.key});

  final ConversationEntity conversation;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.scaffold.withValues(alpha: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0d000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: AppColors.accent),
          ),
          GestureDetector(
            onTap: () => _openContactInfo(context),
            child: MessageUserAvatar(
              name: conversation.otherUser.name,
              photoUrl: conversation.otherUser.photoUrl,
              isOnline: conversation.isOnline,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openContactInfo(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.otherUser.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.title,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  Text(
                    conversation.isOnline ? 'ONLINE' : 'OFFLINE',
                    style: TextStyle(
                      color: conversation.isOnline
                          ? const Color(0xff22c55e)
                          : AppColors.body,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.videocam_outlined, color: AppColors.accent),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.call_outlined, color: AppColors.accent),
          ),
        ],
      ),
    );
  }

  void _openContactInfo(BuildContext context) {
    Navigator.pushNamed(
      context,
      MessageContactInfoView.route,
      arguments: conversation,
    );
  }
}
