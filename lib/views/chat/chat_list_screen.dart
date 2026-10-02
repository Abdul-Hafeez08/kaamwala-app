import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/chat_provider.dart';

import 'chat_room_screen.dart';
import 'package:kaamwala/views/widgets/custom_loading_indicator.dart';

class ChatListScreen extends ConsumerWidget {
  final bool isWorker; // To determine which stream to use

  const ChatListScreen({super.key, required this.isWorker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = isWorker
        ? ref.watch(workerChatsStreamProvider)
        : ref.watch(userChatsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        leading: Navigator.canPop(context)
            ? null
            : IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
      ),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 80,
                      color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No messages yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your recent conversations will appear here',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 750),
              child: ListView.builder(
                itemCount: chats.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
              final chat = chats[index];
              final title = isWorker ? chat.userName : chat.workerName;
              final image = isWorker ? chat.userImage : chat.workerImage;
              final unreadCount = isWorker
                  ? chat.unreadCountWorker
                  : chat.unreadCountUser;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomScreen(
                          chatId: chat.chatId,
                          chatTitle: title,
                          chatImage: image,
                          isWorker: isWorker,
                          currentUserId: isWorker ? chat.workerId : chat.userId,
                        ),
                      ),
                    );
                  },
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Stack(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: image.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(image),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                        ),
                        child: image.isEmpty
                            ? const Icon(
                                Icons.person_rounded,
                                size: 28,
                                color: Color(0xFFFF9800),
                              )
                            : null,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    title.isNotEmpty ? title : 'User',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    chat.lastMessage.isNotEmpty
                        ? chat.lastMessage
                        : 'Tap to chat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unreadCount > 0
                          ? (isDark ? Colors.white : Colors.black87)
                          : (isDark ? Colors.white60 : Colors.black54),
                      fontWeight: unreadCount > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(chat.lastMessageTime),
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
        },
        loading: () => const Center(child: CustomLoadingIndicator()),
        error: (err, _) => Center(child: SelectableText('Error: $err')),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.year == time.year &&
        now.month == time.month &&
        now.day == time.day) {
      return DateFormat('hh:mm a').format(time); // Today
    } else {
      return DateFormat('MMM dd').format(time); // Older
    }
  }
}
