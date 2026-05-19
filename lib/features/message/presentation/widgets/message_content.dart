import 'package:flutter/material.dart';
import 'package:test_codex/features/message/domain/entities/message_entity.dart';
import 'package:test_codex/features/message/domain/entities/message_type.dart';
import 'package:test_codex/features/message/presentation/widgets/message_image_content.dart';
import 'package:test_codex/features/message/presentation/widgets/message_video_content.dart';
import 'package:test_codex/features/message/presentation/widgets/message_voice_content.dart';

class MessageContent extends StatelessWidget {
  const MessageContent({
    required this.message,
    required this.timeLabel,
    super.key,
  });

  final MessageEntity message;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final mediaUrl = message.mediaUrl?.trim();
    return switch (message.type) {
      MessageType.image when mediaUrl != null && mediaUrl.isNotEmpty =>
        MessageImageContent(
          imageUrl: mediaUrl,
          heroTag: 'message-image-${message.id}',
          timeLabel: timeLabel,
        ),
      MessageType.video when mediaUrl != null && mediaUrl.isNotEmpty =>
        MessageVideoContent(
          videoUrl: mediaUrl,
          timeLabel: timeLabel,
        ),
      MessageType.voice when mediaUrl != null && mediaUrl.isNotEmpty =>
        MessageVoiceContent(
          voiceUrl: mediaUrl,
        ),
      _ => Text(
        message.text,
        style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.47),
      ),
    };
  }
}
