import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/job_model.dart';
import '../models/service_model.dart';
import '../models/review_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/complaint_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUserDocument(UserModel userModel) async {
    await _firestore
        .collection('users')
        .doc(userModel.userId)
        .set(userModel.toMap());
  }

  Future<UserModel?> getUserDocument(String userId) async {
    final documentSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .get();

    if (documentSnapshot.exists && documentSnapshot.data() != null) {
      return UserModel.fromMap(documentSnapshot.data()!);
    }
    return null;
  }

  Future<void> updateUserDocument(
    String userId,
    Map<String, dynamic> updatedData,
  ) async {
    await _firestore.collection('users').doc(userId).update(updatedData);
  }

  Future<String?> getUserRole(String userId) async {
    final userModel = await getUserDocument(userId);
    return userModel?.role;
  }

  Future<List<UserModel>> getAllUsers() async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'user')
        .get();
    return querySnapshot.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> createWorkerDocument(WorkerModel workerModel) async {
    await _firestore
        .collection('workers')
        .doc(workerModel.workerId)
        .set(workerModel.toMap());
  }

  Future<WorkerModel?> getWorkerDocument(String workerId) async {
    final documentSnapshot = await _firestore
        .collection('workers')
        .doc(workerId)
        .get();

    if (documentSnapshot.exists && documentSnapshot.data() != null) {
      return WorkerModel.fromMap(documentSnapshot.data()!);
    }
    return null;
  }

  Future<void> updateWorkerDocument(
    String workerId,
    Map<String, dynamic> updatedData,
  ) async {
    await _firestore.collection('workers').doc(workerId).update(updatedData);
  }

  Stream<WorkerModel?> streamWorkerDocument(String workerId) {
    return _firestore.collection('workers').doc(workerId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        return WorkerModel.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  Future<String> getWorkerApprovalStatus(String workerId) async {
    final workerModel = await getWorkerDocument(workerId);
    return workerModel?.approvalStatus ?? 'pending';
  }

  Future<List<WorkerModel>> getAllWorkers() async {
    final querySnapshot = await _firestore.collection('workers').get();
    return querySnapshot.docs
        .map((doc) => WorkerModel.fromMap(doc.data()))
        .toList();
  }

  Future<List<WorkerModel>> getWorkersByApprovalStatus(String status) async {
    final querySnapshot = await _firestore
        .collection('workers')
        .where('approvalStatus', isEqualTo: status)
        .get();
    return querySnapshot.docs
        .map((doc) => WorkerModel.fromMap(doc.data()))
        .toList();
  }

  Future<List<WorkerModel>> getApprovedWorkersByService(
    String serviceType,
  ) async {
    final querySnapshot = await _firestore
        .collection('workers')
        .where('approvalStatus', isEqualTo: 'approved')
        .where('serviceType', isEqualTo: serviceType)
        .get();
    return querySnapshot.docs
        .map((doc) => WorkerModel.fromMap(doc.data()))
        .toList();
  }

  Future<List<JobModel>> getAllJobs() async {
    final querySnapshot = await _firestore.collection('jobs').get();
    return querySnapshot.docs
        .map((doc) => JobModel.fromMap(doc.data()))
        .toList();
  }

  Future<List<JobModel>> getJobsByStatus(String status) async {
    final querySnapshot = await _firestore
        .collection('jobs')
        .where('status', isEqualTo: status)
        .get();
    return querySnapshot.docs
        .map((doc) => JobModel.fromMap(doc.data()))
        .toList();
  }

  Future<String> createJob(JobModel job) async {
    final docRef = _firestore.collection('jobs').doc();
    final jobData = job.toMap();
    jobData['jobId'] = docRef.id;
    // If it's a general request, set status to 'open' instead of 'pending'
    if (job.isGeneralRequest) {
      jobData['status'] = 'open';
    }
    await docRef.set(jobData);
    return docRef.id;
  }

  Future<void> updateJob(String jobId, Map<String, dynamic> data) async {
    await _firestore.collection('jobs').doc(jobId).update(data);
  }

  Future<List<JobModel>> getUserJobs(String userId) async {
    final querySnapshot = await _firestore
        .collection('jobs')
        .where('userId', isEqualTo: userId)
        .get();
    final jobs = querySnapshot.docs
        .map((doc) => JobModel.fromMap(doc.data()))
        .toList();
    jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return jobs;
  }

  Stream<List<JobModel>> streamUserJobs(String userId) {
    return _firestore
        .collection('jobs')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final jobs = snapshot.docs
              .map((doc) => JobModel.fromMap(doc.data()))
              .toList();
          jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return jobs;
        });
  }

  Stream<List<JobModel>> streamWorkerJobs(String workerId) {
    return _firestore
        .collection('jobs')
        .where('workerId', isEqualTo: workerId)
        .snapshots()
        .map((snapshot) {
          final jobs = snapshot.docs
              .map((doc) => JobModel.fromMap(doc.data()))
              .toList();
          jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return jobs;
        });
  }

  Stream<List<JobModel>> streamOpenJobsByCategory(String serviceType) {
    return _firestore
        .collection('jobs')
        .where('isGeneralRequest', isEqualTo: true)
        .where('status', isEqualTo: 'open')
        .where('serviceType', isEqualTo: serviceType)
        .snapshots()
        .map((snapshot) {
          final jobs = snapshot.docs
              .map((doc) => JobModel.fromMap(doc.data()))
              .toList();
          jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return jobs;
        });
  }

  Future<void> recordJobView(String jobId, String workerId) async {
    if (jobId.isEmpty || workerId.isEmpty) return;
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'viewedByWorkerIds': FieldValue.arrayUnion([workerId]),
      });
    } catch (_) {}
  }

  Future<void> declineJob(String jobId, String workerId) async {
    if (jobId.isEmpty || workerId.isEmpty) return;
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'declinedByWorkerIds': FieldValue.arrayUnion([workerId]),
      });
    } catch (_) {}
  }

  Future<List<JobModel>> getWorkerJobs(String workerId) async {
    final querySnapshot = await _firestore
        .collection('jobs')
        .where('workerId', isEqualTo: workerId)
        .get();
    final jobs = querySnapshot.docs
        .map((doc) => JobModel.fromMap(doc.data()))
        .toList();
    jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return jobs;
  }

  Future<void> createReview(ReviewModel review) async {
    final docRef = _firestore.collection('reviews').doc();
    final reviewData = review.toMap();
    reviewData['reviewId'] = docRef.id;
    await docRef.set(reviewData);
  }

  Future<List<ReviewModel>> getWorkerReviews(String workerId) async {
    final querySnapshot = await _firestore
        .collection('reviews')
        .where('workerId', isEqualTo: workerId)
        .get();
    final reviews = querySnapshot.docs
        .map((doc) => ReviewModel.fromMap(doc.data()))
        .toList();
    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews;
  }

  Future<void> updateWorkerRating(String workerId) async {
    final reviews = await getWorkerReviews(workerId);
    if (reviews.isEmpty) return;

    double totalRating = 0;
    for (final review in reviews) {
      totalRating += review.rating;
    }
    final averageRating = totalRating / reviews.length;

    await updateWorkerDocument(workerId, {
      'rating': double.parse(averageRating.toStringAsFixed(1)),
    });
  }

  Future<List<ServiceCategory>> getServices() async {
    final querySnapshot = await _firestore.collection('services').get();

    if (querySnapshot.docs.isEmpty) {
      return allServiceCategories;
    }

    return querySnapshot.docs
        .map((doc) => ServiceCategory.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> addService(ServiceCategory service) async {
    final docRef = _firestore.collection('services').doc();
    final serviceData = service.toMap();
    serviceData['id'] = docRef.id;
    await docRef.set(serviceData);
  }

  Future<void> deleteService(String serviceId) async {
    await _firestore.collection('services').doc(serviceId).delete();
  }

  // --- Chat Methods ---

  Future<ChatModel> createOrGetChat({
    required String userId,
    required String workerId,
    required String userName,
    required String userImage,
    required String workerName,
    required String workerImage,
  }) async {
    // Check if chat exists
    final querySnapshot = await _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .get();

    for (var doc in querySnapshot.docs) {
      final chat = ChatModel.fromMap(doc.data(), doc.id);
      if (chat.workerId == workerId) {
        return chat; // Chat already exists
      }
    }

    // Create new chat
    final docRef = _firestore.collection('chats').doc();
    final newChat = ChatModel(
      chatId: docRef.id,
      userId: userId,
      workerId: workerId,
      userName: userName,
      userImage: userImage,
      workerName: workerName,
      workerImage: workerImage,
      lastMessage: '',
      lastMessageTime: DateTime.now(),
    );

    await docRef.set(newChat.toMap());
    return newChat;
  }

  Future<void> sendMessage(MessageModel message) async {
    // Save message
    final docRef = _firestore.collection('messages').doc();
    final msgData = message.toMap();
    msgData['messageId'] = docRef.id;
    await docRef.set(msgData);

    // Update last message and unread count in chat
    final isWorkerSender = message.senderType == 'worker';

    await _firestore.collection('chats').doc(message.chatId).update({
      'lastMessage': message.text,
      'lastMessageTime': msgData['createdAt'],
      if (isWorkerSender) 'unreadCountUser': FieldValue.increment(1),
      if (!isWorkerSender) 'unreadCountWorker': FieldValue.increment(1),
    });
  }

  Future<void> markChatAsRead(String chatId, bool isWorker) async {
    await _firestore.collection('chats').doc(chatId).update({
      if (isWorker) 'unreadCountWorker': 0,
      if (!isWorker) 'unreadCountUser': 0,
    });
  }

  Stream<List<ChatModel>> streamChatsForUser(String userId) {
    return _firestore
        .collection('chats')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
              .toList();
          chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          return chats;
        });
  }

  Stream<List<ChatModel>> streamChatsForWorker(String workerId) {
    return _firestore
        .collection('chats')
        .where('workerId', isEqualTo: workerId)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
              .toList();
          chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          return chats;
        });
  }

  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
              .toList();
          messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return messages;
        });
  }

  // --- AI Assistant (per-user) ---

  /// Ensure an AI session document exists for the user (doc id == userId)
  Future<void> ensureAiSessionForUser(String userId) async {
    if (userId.isEmpty) return;
    final docRef = _firestore.collection('ai_sessions').doc(userId);
    final snap = await docRef.get();
    if (!snap.exists) {
      await docRef.set({
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> addAiMessageForUser({
    required String userId,
    required String text,
    required bool isUser,
    String? payloadType,
    Map<String, dynamic>? payload,
  }) async {
    if (userId.isEmpty) return;
    final messagesRef = _firestore
        .collection('ai_sessions')
        .doc(userId)
        .collection('messages');
    final docRef = messagesRef.doc();
    final data = {
      'text': text,
      'isUser': isUser,
      'payloadType': payloadType ?? '',
      'payload': payload ?? {},
      'createdAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(data);
  }

  Stream<List<Map<String, dynamic>>> streamAiMessagesForUser(String userId) {
    if (userId.isEmpty) return const Stream.empty();
    return _firestore
        .collection('ai_sessions')
        .doc(userId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((d) {
            final m = d.data();
            return {
              'id': d.id,
              'text': m['text'] ?? '',
              'isUser': m['isUser'] ?? false,
              'payloadType': m['payloadType'] ?? '',
              'payload': (m['payload'] is Map)
                  ? Map<String, dynamic>.from(m['payload'])
                  : {},
              'createdAt': (m['createdAt'] as Timestamp?)?.toDate(),
            };
          }).toList();
        });
  }
  // --- Complaints Methods ---

  Future<void> createComplaint(ComplaintModel complaint) async {
    final docRef = _firestore.collection('complaints').doc();
    final complaintData = complaint.toMap();
    complaintData['complaintId'] = docRef.id;
    await docRef.set(complaintData);
  }

  Stream<List<ComplaintModel>> streamAllComplaints() {
    return _firestore
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> updateComplaintStatus(String complaintId, String status) async {
    await _firestore.collection('complaints').doc(complaintId).update({
      'status': status,
    });
  }

  // --- Nearby Workers Real-Time Streams ---

  /// Stream all workers who are available (open to work).
  /// This is a REAL-TIME stream — any change in Firestore triggers an update.
  Stream<List<WorkerModel>> streamAvailableWorkers() {
    return _firestore
        .collection('workers')
        .where('availability', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WorkerModel.fromMap(doc.data()))
          .toList();
    });
  }

  /// Stream available workers filtered by service type.
  Stream<List<WorkerModel>> streamAvailableWorkersByService(
      String serviceType) {
    return _firestore
        .collection('workers')
        .where('availability', isEqualTo: true)
        .where('serviceType', isEqualTo: serviceType)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WorkerModel.fromMap(doc.data()))
          .toList();
    });
  }

  /// Update worker's geographic coordinates in Firestore.
  Future<void> updateWorkerLocation(
    String workerId,
    double latitude,
    double longitude,
  ) async {
    await _firestore.collection('workers').doc(workerId).update({
      'latitude': latitude,
      'longitude': longitude,
      'lastSeen': Timestamp.fromDate(DateTime.now()),
    });
  }
}
