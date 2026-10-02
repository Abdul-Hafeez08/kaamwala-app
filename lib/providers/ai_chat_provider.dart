import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/ai_chat_service.dart';
import '../services/ai_concierge_service.dart';
import '../services/worker_ranking_service.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

class AIChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final dynamic actionPayload;

  AIChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.actionPayload,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AIChatState {
  final List<AIChatMessage> messages;
  final bool isLoading;

  const AIChatState({this.messages = const [], this.isLoading = false});

  AIChatState copyWith({List<AIChatMessage>? messages, bool? isLoading}) {
    return AIChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AIChatNotifier extends StateNotifier<AIChatState> {
  final Ref ref;
  final AIChatService _chatService;
  final AIConciergeService _conciergeService;
  final FirestoreService _firestoreService;

  StreamSubscription<List<Map<String, dynamic>>>? _aiMessagesSub;
  String? _currentUserId;

  AIChatNotifier(this.ref)
    : _chatService = AIChatService(),
      _conciergeService = AIConciergeService(),
      _firestoreService = ref.read(firestoreServiceProvider),
      super(const AIChatState()) {
    _initWelcome();
    _attachAuthListener();
  }

  void _initWelcome() {
    state = AIChatState(
      messages: [
        AIChatMessage(
          text:
              'Hi! 👋 I\'m your Kaamwala AI Concierge. I can find top-rated nearby workers, compare ratings, and book services directly for you in English, اردو, or Roman Urdu.\n\nTry saying: "I need an electrician today at 5 PM" or "Mujhe plumber chahiye"!',
          isUser: false,
        ),
      ],
    );
  }

  void _attachAuthListener() {
    ref.listen(authStateProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user == null) {
            _stopListeningAndClear();
          } else {
            _startListeningForUser(user.uid);
          }
        },
        loading: () {},
        error: (_, __) {},
      );
    });
  }

  void _stopListeningAndClear() {
    _aiMessagesSub?.cancel();
    _aiMessagesSub = null;
    _currentUserId = null;
    _initWelcome();
  }

  Future<void> _startListeningForUser(String userId) async {
    if (userId.isEmpty) return;
    _currentUserId = userId;
    await _firestoreService.ensureAiSessionForUser(userId);

    _aiMessagesSub?.cancel();
    _aiMessagesSub = _firestoreService.streamAiMessagesForUser(userId).listen((
      docs,
    ) {
      final messages = docs.map((m) {
        return AIChatMessage(
          text: m['text'] ?? '',
          isUser: m['isUser'] ?? false,
          timestamp: m['createdAt'] ?? DateTime.now(),
        );
      }).toList();

      if (messages.isEmpty) {
        _initWelcome();
      } else {
        state = state.copyWith(messages: messages);
      }
    });
  }

  Future<void> sendMessage(String text, {UserModel? user}) async {
    if (text.trim().isEmpty) return;
    final uid = user?.userId ?? _currentUserId;
    if (uid == null || uid.isEmpty) {
      final aiMessage = AIChatMessage(
        text: 'Please sign in to use the AI assistant.',
        isUser: false,
      );
      state = state.copyWith(messages: [...state.messages, aiMessage]);
      return;
    }

    await _firestoreService.addAiMessageForUser(
      userId: uid,
      text: text.trim(),
      isUser: true,
    );

    final userMessage = AIChatMessage(text: text.trim(), isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    try {
      final currentUserModel = user;
      final actionPayload = await _conciergeService.processUserQuery(
        query: text.trim(),
        currentUser: currentUserModel,
      );

      if (actionPayload.type != AIActionType.none) {
        final aiMessage = AIChatMessage(
          text: actionPayload.message,
          isUser: false,
          actionPayload: actionPayload,
        );
        await _firestoreService.addAiMessageForUser(
          userId: uid,
          text: actionPayload.message,
          isUser: false,
          payloadType: actionPayload.type.toString(),
          payload: {
            'serviceType': actionPayload.serviceType,
            'scheduledTime': actionPayload.scheduledTime,
          },
        );

        state = state.copyWith(
          messages: [...state.messages, aiMessage],
          isLoading: false,
        );
        return;
      }

      // Build recent conversation history for memory context (last 6 messages)
      final recentHistory = state.messages
          .where((m) => m.text.isNotEmpty)
          .take(6)
          .map((m) => {
                'role': m.isUser ? 'user' : 'model',
                'text': m.text,
              })
          .toList();

      // Build dynamic context with all workers and their reviews
      String workersContext = 'Here is the current database of all workers in Kaamwala app:\n\n';
      try {
        final allWorkers = await _firestoreService.getAllWorkers();
        for (final w in allWorkers) {
          final reviews = await _firestoreService.getWorkerReviews(w.workerId);
          workersContext += 'Worker Name: ${w.name}\n';
          workersContext += 'Service: ${w.serviceType}\n';
          workersContext += 'Experience: ${w.experience}\n';
          workersContext += 'Rating: ${w.rating}\n';
          workersContext += 'Hourly Rate: Rs. ${w.hourlyRate}\n';
          
          if (reviews.isNotEmpty) {
            workersContext += 'Reviews:\n';
            for (final r in reviews) {
              workersContext += '- Rating: ${r.rating}, Review: "${r.review}"\n';
            }
          } else {
            workersContext += 'Reviews: No reviews yet.\n';
          }
          workersContext += '\n';
        }
      } catch (e) {
        debugPrint('Error fetching worker context: $e');
      }

      final response = await _chatService.sendMessage(
        text.trim(),
        history: recentHistory,
        additionalContext: workersContext,
      );
      final aiMessage = AIChatMessage(text: response, isUser: false);
      await _firestoreService.addAiMessageForUser(
        userId: uid,
        text: response,
        isUser: false,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } catch (e, st) {
      debugPrint('AIChatNotifier.sendMessage error: $e');
      debugPrint('$st');

      final aiMessage = AIChatMessage(
        text:
            'Sorry, I couldn\'t connect to the AI assistant right now. Please try again.',
        isUser: false,
      );
      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    }
  }

  void selectWorkerToBook(RankedWorker rankedWorker, UserModel? user) {
    final worker = rankedWorker.worker;
    _conciergeService.lastSelectedWorker = rankedWorker;
    _conciergeService.lastServiceType = worker.serviceType;
    _conciergeService.lastAddress = user?.address ?? user?.location ?? '';

    final confirmPayload = AIActionPayload(
      type: AIActionType.confirmBooking,
      message:
          'Would you like me to send a booking request to **${worker.name}** for **${worker.serviceType}**?',
      serviceType: worker.serviceType,
      targetWorker: rankedWorker,
      address: user?.address ?? user?.location ?? '',
    );

    final aiMessage = AIChatMessage(
      text: confirmPayload.message,
      isUser: false,
      actionPayload: confirmPayload,
    );
    state = state.copyWith(messages: [...state.messages, aiMessage]);
  }

  Future<void> confirmPendingBooking(UserModel? user) async {
    state = state.copyWith(isLoading: true);
    final actionPayload = await _conciergeService.processUserQuery(
      query: 'yes',
      currentUser: user,
    );

    final aiMessage = AIChatMessage(
      text: actionPayload.message,
      isUser: false,
      actionPayload: actionPayload,
    );
    state = state.copyWith(
      messages: [...state.messages, aiMessage],
      isLoading: false,
    );
  }

  void cancelPendingBooking() {
    _conciergeService.lastSelectedWorker = null;
    final aiMessage = AIChatMessage(
      text:
          'Booking request cancelled. You can choose another worker or search again anytime! 😊',
      isUser: false,
    );
    state = state.copyWith(messages: [...state.messages, aiMessage]);
  }

  Future<void> postJobToMarketplace({
    required UserModel user,
    required String serviceType,
    required String address,
    required String description,
  }) async {
    state = state.copyWith(isLoading: true);
    final actionPayload = await _conciergeService.postGeneralMarketplaceJob(
      currentUser: user,
      serviceType: serviceType,
      address: address,
      description: description,
    );

    final aiMessage = AIChatMessage(
      text: actionPayload.message,
      isUser: false,
      actionPayload: actionPayload,
    );
    state = state.copyWith(
      messages: [...state.messages, aiMessage],
      isLoading: false,
    );
  }

  void clearChat() {
    _chatService.resetChat();
    _conciergeService.resetSession();
    _stopListeningAndClear();
  }
}

final aiChatProvider = StateNotifierProvider<AIChatNotifier, AIChatState>((
  ref,
) {
  return AIChatNotifier(ref);
});
