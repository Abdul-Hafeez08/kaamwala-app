import '../models/message_model.dart';
import '../services/firestore_service.dart';

class ChatController {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> sendInitialMessageOrGetChat({
    required String userId,
    required String workerId,
    required String userName,
    required String userImage,
    required String workerName,
    required String workerImage,
    required String initialMessageText,
  }) async {
    // 1. Create or get existing chat room
    final chat = await _firestoreService.createOrGetChat(
      userId: userId,
      workerId: workerId,
      userName: userName,
      userImage: userImage,
      workerName: workerName,
      workerImage: workerImage,
    );

    // 2. Send initial message if provided
    if (initialMessageText.trim().isNotEmpty) {
      final msg = MessageModel(
        messageId: '',
        chatId: chat.chatId,
        senderId: userId,
        senderType: 'user',
        text: initialMessageText.trim(),
      );
      await _firestoreService.sendMessage(msg);
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderType,
    required String text,
  }) async {
    final msg = MessageModel(
      messageId: '',
      chatId: chatId,
      senderId: senderId,
      senderType: senderType,
      text: text.trim(),
    );
    await _firestoreService.sendMessage(msg);
  }

  Future<void> markAsRead(String chatId, bool isWorker) async {
    await _firestoreService.markChatAsRead(chatId, isWorker);
  }
}
