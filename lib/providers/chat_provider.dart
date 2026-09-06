import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'auth_provider.dart';

final userChatsStreamProvider = StreamProvider<List<ChatModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      final firestoreService = ref.read(firestoreServiceProvider);
      return firestoreService.streamChatsForUser(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, _) => Stream.value([]),
  );
});

final workerChatsStreamProvider = StreamProvider<List<ChatModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      final firestoreService = ref.read(firestoreServiceProvider);
      return firestoreService.streamChatsForWorker(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, _) => Stream.value([]),
  );
});

final chatMessagesStreamProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.streamMessages(chatId);
});

final totalUnreadCountUserProvider = Provider<int>((ref) {
  final chatsAsync = ref.watch(userChatsStreamProvider);
  return chatsAsync.when(
    data: (chats) => chats.where((c) => c.unreadCountUser > 0).length,
    loading: () => 0,
    error: (_, _) => 0,
  );
});

final totalUnreadCountWorkerProvider = Provider<int>((ref) {
  final chatsAsync = ref.watch(workerChatsStreamProvider);
  return chatsAsync.when(
    data: (chats) => chats.where((c) => c.unreadCountWorker > 0).length,
    loading: () => 0,
    error: (_, _) => 0,
  );
});
