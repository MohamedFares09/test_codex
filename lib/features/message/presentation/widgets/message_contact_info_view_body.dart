import 'package:flutter/material.dart';
import 'package:test_codex/core/utils/app_colors.dart';
import 'package:test_codex/core/widgets/app_background.dart';
import 'package:test_codex/features/home/domain/entities/conversation_entity.dart';

class MessageContactInfoViewBody extends StatelessWidget {
  const MessageContactInfoViewBody({required this.conversation, super.key});

  final ConversationEntity conversation;

  @override
  Widget build(BuildContext context) {
    final user = conversation.otherUser;
    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            _ContactInfoHeader(name: user.name),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  _ContactProfileCard(conversation: conversation),
                  const SizedBox(height: 16),
                  const _ContactActions(),
                  const SizedBox(height: 16),
                  _ContactInfoSection(
                    children: [
                      _ContactInfoTile(
                        icon: Icons.info_outline,
                        title: conversation.isOnline ? 'Online' : 'Offline',
                        subtitle: 'Status',
                      ),
                      _ContactInfoTile(
                        icon: Icons.alternate_email,
                        title: user.email,
                        subtitle: 'Email',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactInfoHeader extends StatelessWidget {
  const _ContactInfoHeader({required this.name});

  final String name;

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
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert, color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

class _ContactProfileCard extends StatelessWidget {
  const _ContactProfileCard({required this.conversation});

  final ConversationEntity conversation;

  @override
  Widget build(BuildContext context) {
    final user = conversation.otherUser;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _ContactAvatar(
            name: user.name,
            photoUrl: user.photoUrl,
            isOnline: conversation.isOnline,
          ),
          const SizedBox(height: 18),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.title,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.body,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactAvatar extends StatelessWidget {
  const _ContactAvatar({
    required this.name,
    required this.isOnline,
    this.photoUrl,
  });

  final String name;
  final bool isOnline;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final imageUrl = photoUrl?.trim();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 58,
          backgroundColor: AppColors.input,
          backgroundImage: imageUrl == null || imageUrl.isEmpty
              ? null
              : NetworkImage(imageUrl),
          child: imageUrl == null || imageUrl.isEmpty
              ? Text(
                  _initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
        Positioned(
          right: 5,
          bottom: 5,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xff22c55e) : AppColors.hint,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.card, width: 3),
            ),
          ),
        ),
      ],
    );
  }

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _ContactActions extends StatelessWidget {
  const _ContactActions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ContactActionButton(
              icon: Icons.chat_outlined,
              label: 'Message',
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: _ContactActionButton(
              icon: Icons.call_outlined,
              label: 'Audio',
              onPressed: () {},
            ),
          ),
          Expanded(
            child: _ContactActionButton(
              icon: Icons.videocam_outlined,
              label: 'Video',
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactActionButton extends StatelessWidget {
  const _ContactActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ContactInfoSection extends StatelessWidget {
  const _ContactInfoSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _ContactInfoTile extends StatelessWidget {
  const _ContactInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accent),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.title,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.body, fontSize: 12),
      ),
    );
  }
}
