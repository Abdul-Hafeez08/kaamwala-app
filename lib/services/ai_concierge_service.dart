import '../models/user_model.dart';
import 'firestore_service.dart';
import 'location_service.dart';
import 'worker_ranking_service.dart';
import '../controllers/booking_controller.dart';

enum AIActionType {
  none,
  showWorkers,
  confirmBooking,
  bookingSuccess,
  noWorkersFound,
  marketplaceSuccess,
}

class AIActionPayload {
  final AIActionType type;
  final String message;
  final String serviceType;
  final List<RankedWorker> rankedWorkers;
  final RankedWorker? targetWorker;
  final DateTime? scheduledDate;
  final String scheduledTime;
  final String address;
  final String? createdJobId;

  AIActionPayload({
    required this.type,
    required this.message,
    this.serviceType = '',
    this.rankedWorkers = const [],
    this.targetWorker,
    this.scheduledDate,
    this.scheduledTime = '',
    this.address = '',
    this.createdJobId,
  });
}

class AIConciergeService {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final WorkerRankingService _rankingService = WorkerRankingService();
  final BookingController _bookingController = BookingController();

  // Temporary conversational session context for multi-turn booking flows
  RankedWorker? lastSelectedWorker;
  String lastServiceType = '';
  DateTime? lastScheduledDate;
  String lastScheduledTime = '';
  String lastAddress = '';
  List<RankedWorker> lastRankedWorkers = [];

  void resetSession() {
    lastSelectedWorker = null;
    lastServiceType = '';
    lastScheduledDate = null;
    lastScheduledTime = '';
    lastAddress = '';
    lastRankedWorkers = [];
  }

  /// Process natural language input and execute backend operations
  Future<AIActionPayload> processUserQuery({
    required String query,
    required UserModel? currentUser,
  }) async {
    final lower = query.toLowerCase().trim();
    final isUrdu = _isUrduScript(query);
    final isRoman = _isRomanUrdu(lower);

    // 1. Check for Confirmation / Rejection in pending booking flow
    if (lastSelectedWorker != null) {
      if (_isAffirmative(lower)) {
        return await _executeConfirmedBooking(currentUser, isUrdu, isRoman);
      } else if (_isNegative(lower)) {
        final workerName = lastSelectedWorker?.worker.name ?? 'worker';
        lastSelectedWorker = null;
        if (isUrdu) {
          return AIActionPayload(
            type: AIActionType.none,
            message: 'ٹھیک ہے، $workerName کی بکنگ منسوخ کر دی گئی۔ آپ کوئی اور ورکر منتخب کر سکتے ہیں یا نئی سروس تلاش کر سکتے ہیں۔',
          );
        } else if (isRoman) {
          return AIActionPayload(
            type: AIActionType.none,
            message: 'Theek hai, $workerName ki booking cancel kar di gayi. Aap koi doosra worker choose kar sakte hain.',
          );
        } else {
          return AIActionPayload(
            type: AIActionType.none,
            message: 'No problem, booking for $workerName was cancelled. You can choose another worker or search again.',
          );
        }
      }
    }

    // 2. Check for Direct "Book the first / best worker" intent if workers were recently shown
    if (lastRankedWorkers.isNotEmpty && (_matches(lower, ['best wala', 'pehla wala', 'first one', 'book best', 'book him', 'book karo', 'book first', 'book ahmed', 'book worker', 'yeh wala book']))) {
      final bestWorker = lastRankedWorkers.first;
      lastSelectedWorker = bestWorker;
      return _createConfirmationPayload(bestWorker, isUrdu, isRoman);
    }

    // 3. Extract Service Category
    final detectedService = _detectServiceCategory(lower);

    // If a service was requested or user wants to find/book workers
    if (detectedService.isNotEmpty) {
      lastServiceType = detectedService;

      // Extract schedule & location details
      final extractedDate = _extractDate(lower) ?? DateTime.now();
      final extractedTime = _extractTime(lower) ?? _formatDefaultTime();
      final extractedAddress = _extractAddress(query, currentUser?.address ?? currentUser?.location ?? '');

      lastScheduledDate = extractedDate;
      lastScheduledTime = extractedTime;
      lastAddress = extractedAddress;

      // Fetch approved workers from real database
      final allWorkers = await _firestoreService.getAllWorkers();
      
      // Get user coordinates if available
      double? userLat;
      double? userLng;
      try {
        final pos = await _locationService.getCurrentPosition();
        userLat = pos.latitude;
        userLng = pos.longitude;
      } catch (_) {
        // GPS permission disabled or fallback
      }

      // Rank workers using AI ranking service
      final ranked = await _rankingService.rankWorkers(
        workers: allWorkers,
        targetService: detectedService,
        userLat: userLat,
        userLng: userLng,
        userLocationAddress: extractedAddress,
      );

      lastRankedWorkers = ranked;

      // Check if user specifically requested immediate booking
      final isBookingIntent = _matches(lower, ['book', 'hire', 'send request', 'bhejo', 'mangwao', 'book karna', 'book kardo', 'بک']);

      if (ranked.isEmpty) {
        // No nearby workers found in database
        String noWorkersMsg;
        if (isUrdu) {
          noWorkersMsg = 'فی الوقت آپ کے علاقے میں کوئی آن لائن $detectedService دستیاب نہیں ہے۔ آپ جاب مارکیٹ میں اپنی ریکویسٹ پوسٹ کر سکتے ہیں، قریبی ورکرز اسے دیکھ کر فوراً رابطہ کریں گے!';
        } else if (isRoman) {
          noWorkersMsg = 'Filhal aapke area mein koi online $detectedService available nahi hai. Aap Job Marketplace par request post kar sakte hain taake qareebi experts accept kar sakein!';
        } else {
          noWorkersMsg = 'No ${detectedService}s are currently online near your location. You can post your job request to the marketplace and we will notify you as soon as a worker accepts!';
        }

        return AIActionPayload(
          type: AIActionType.noWorkersFound,
          message: noWorkersMsg,
          serviceType: detectedService,
          scheduledDate: extractedDate,
          scheduledTime: extractedTime,
          address: extractedAddress,
        );
      }

      // If user directly said "Book an electrician today at 5pm..."
      if (isBookingIntent) {
        final bestWorker = ranked.first;
        lastSelectedWorker = bestWorker;

        return _createConfirmationPayload(bestWorker, isUrdu, isRoman);
      }

      // Normal search intent: Show ranked workers
      String headerMsg;
      if (isUrdu) {
        headerMsg = 'مجھے آپ کے قریب ${ranked.length} بہترین $detectedService مل گئے ہیں جو اس وقت دستیاب ہیں:';
      } else if (isRoman) {
        headerMsg = 'Mujhe aapke qareeb ${ranked.length} best available $detectedService mil gaye hain:';
      } else {
        headerMsg = 'I found ${ranked.length} verified ${detectedService}s available near you:';
      }

      return AIActionPayload(
        type: AIActionType.showWorkers,
        message: headerMsg,
        serviceType: detectedService,
        rankedWorkers: ranked,
        scheduledDate: extractedDate,
        scheduledTime: extractedTime,
        address: extractedAddress,
      );
    }

    // 4. Default informational conversation handler (handled by smart conversational fallback)
    return AIActionPayload(
      type: AIActionType.none,
      message: '', // Will fallback to chat service natural response
    );
  }

  AIActionPayload _createConfirmationPayload(RankedWorker worker, bool isUrdu, bool isRoman) {
    final workerName = worker.worker.name;
    final rating = worker.worker.rating > 0 ? '${worker.worker.rating.toStringAsFixed(1)}⭐' : 'Top rated';
    final dist = worker.distanceInKm != null ? '${worker.distanceInKm} km away' : 'nearby';

    String confirmMsg;
    if (isUrdu) {
      confirmMsg = 'سب سے بہترین میچ **$workerName** ($rating، فاصلہ $dist) ہیں۔ کیا میں ان کو $lastScheduledTime کے لیے بکنگ ریکویسٹ بھیج دوں؟';
    } else if (isRoman) {
      confirmMsg = 'Aapke liye best match **$workerName** ($rating, $dist) hain. Kya main inko $lastScheduledTime ke liye booking request send kar doon?';
    } else {
      confirmMsg = 'The best match for you is **$workerName** ($rating, $dist, currently online). Would you like me to send a booking request for $lastScheduledTime?';
    }

    return AIActionPayload(
      type: AIActionType.confirmBooking,
      message: confirmMsg,
      serviceType: lastServiceType,
      targetWorker: worker,
      scheduledDate: lastScheduledDate ?? DateTime.now(),
      scheduledTime: lastScheduledTime,
      address: lastAddress,
      rankedWorkers: lastRankedWorkers,
    );
  }

  Future<AIActionPayload> _executeConfirmedBooking(UserModel? currentUser, bool isUrdu, bool isRoman) async {
    final worker = lastSelectedWorker?.worker;
    if (worker == null || currentUser == null) {
      return AIActionPayload(
        type: AIActionType.none,
        message: isUrdu
            ? 'بکنگ بنانے کے لیے لاگ ان ہونا ضروری ہے۔'
            : 'Please make sure you are logged in to complete the booking.',
      );
    }

    try {
      final jobId = await _bookingController.createBooking(
        userId: currentUser.userId,
        workerId: worker.workerId,
        serviceType: worker.serviceType.isNotEmpty ? worker.serviceType : lastServiceType,
        description: 'Direct AI booking for ${worker.serviceType}',
        address: lastAddress.isNotEmpty ? lastAddress : (currentUser.address.isNotEmpty ? currentUser.address : 'Customer address'),
        location: currentUser.location,
        userName: currentUser.name,
        userPhone: currentUser.phone,
        workerName: worker.name,
        workerImage: worker.profileImage,
        scheduledDate: lastScheduledDate ?? DateTime.now(),
        scheduledTime: lastScheduledTime.isNotEmpty ? lastScheduledTime : _formatDefaultTime(),
        isGeneralRequest: false,
      );

      final workerName = worker.name;
      resetSession();

      String successMsg;
      if (isUrdu) {
        successMsg = '✅ زبردست! آپ کی بکنگ ریکویسٹ **$workerName** کو کامیابی سے بھیج دی گئی ہے (Job ID: ${jobId.substring(0, 6)}...)۔ ورکر کے قبول کرتے ہی آپ کو مطلع کر دیا جائے گا۔';
      } else if (isRoman) {
        successMsg = '✅ Done! Aapki booking request **$workerName** ko successfully bhej di gayi hai. Worker ke accept karte hi aapko update mil jayegi.';
      } else {
        successMsg = '✅ Success! Your booking request has been sent to **$workerName** (Job ID: ${jobId.substring(0, 6)}...). You will be notified as soon as they accept!';
      }

      return AIActionPayload(
        type: AIActionType.bookingSuccess,
        message: successMsg,
        createdJobId: jobId,
        serviceType: worker.serviceType,
        targetWorker: RankedWorker(
          worker: worker,
          matchScore: 98,
          recommendationReasonEn: 'Booking request sent',
          recommendationReasonUrdu: 'بکنگ ریکویسٹ بھیجی گئی',
          recommendationReasonRoman: 'Booking request sent',
        ),
      );
    } catch (e) {
      return AIActionPayload(
        type: AIActionType.none,
        message: 'Could not create booking: ${e.toString()}',
      );
    }
  }

  /// Post a job directly to marketplace from AI assistant
  Future<AIActionPayload> postGeneralMarketplaceJob({
    required UserModel currentUser,
    required String serviceType,
    required String address,
    required String description,
    DateTime? date,
    String? time,
  }) async {
    try {
      final jobId = await _bookingController.createBooking(
        userId: currentUser.userId,
        workerId: '',
        serviceType: serviceType,
        description: description.isNotEmpty ? description : 'Job request posted via Kaamwala AI Concierge',
        address: address.isNotEmpty ? address : currentUser.address,
        location: currentUser.location,
        userName: currentUser.name,
        userPhone: currentUser.phone,
        workerName: '',
        workerImage: '',
        scheduledDate: date ?? DateTime.now().add(const Duration(hours: 2)),
        scheduledTime: time ?? _formatDefaultTime(),
        isGeneralRequest: true,
      );

      return AIActionPayload(
        type: AIActionType.marketplaceSuccess,
        message: '🚀 Your request for **$serviceType** has been posted to the Job Marketplace! All available $serviceType experts in your area will be notified.',
        createdJobId: jobId,
        serviceType: serviceType,
      );
    } catch (e) {
      return AIActionPayload(
        type: AIActionType.none,
        message: 'Could not post to marketplace: $e',
      );
    }
  }

  // --- NLP Utilities ---

  String _detectServiceCategory(String text) {
    if (_matches(text, ['electric', 'bijli', 'short circuit', 'fan', 'wiring', 'switch', 'الیکٹریشن', 'بجلی'])) {
      return 'Electrician';
    }
    if (_matches(text, ['plumb', 'nalka', 'leakage', 'pipe', 'tanki', 'sanitary', 'motor', 'پلمبر', 'نل'])) {
      return 'Plumber';
    }
    if (_matches(text, ['ac ', 'ac\n', 'ac.', 'air conditioner', 'cooling', 'gas charge', 'filter', 'اے سی'])) {
      return 'AC Technician';
    }
    if (_matches(text, ['solar', 'inverter', 'battery', 'plate', 'سولر'])) {
      return 'Solar Panel Service';
    }
    if (_matches(text, ['paint', 'color', 'rang', 'distemper', 'پینٹر', 'رنگ'])) {
      return 'Painter';
    }
    if (_matches(text, ['clean', 'safai', 'washroom', 'deep clean', 'صفائی'])) {
      return 'House Cleaning';
    }
    if (_matches(text, ['maid', 'masi', 'housekeeper', 'cooking', 'ماسی'])) {
      return 'Maid Service';
    }
    if (_matches(text, ['carpenter', 'lakri', 'door', 'lock', 'furniture', 'کارپینٹر', 'لکڑی'])) {
      return 'Carpenter';
    }
    if (_matches(text, ['cctv', 'camera', 'security', 'کیمرہ'])) {
      return 'CCTV Service';
    }
    if (_matches(text, ['tutor', 'tuition', 'study', 'teacher', 'maths', 'science', 'استاد', 'ٹیوٹر'])) {
      return 'Home Tutor';
    }
    if (_matches(text, ['car wash', 'gari', 'car clean', 'کار واش'])) {
      return 'Car Wash at Home';
    }
    if (_matches(text, ['beauty', 'salon', 'haircut', 'facial', 'parlour', 'بیوٹی'])) {
      return 'Beauty Salon / Haircut';
    }
    if (_matches(text, ['event', 'decoration', 'birthday', 'shadi', 'stage', 'ڈیکوریشن'])) {
      return 'Event Decoration';
    }
    if (_matches(text, ['laundry', 'iron', 'istri', 'clothes', 'استری', 'لانڈری'])) {
      return 'Laundry & Ironing';
    }
    return '';
  }

  DateTime? _extractDate(String text) {
    if (text.contains('tomorrow') || text.contains('kal') || text.contains('کل')) {
      return DateTime.now().add(const Duration(days: 1));
    }
    if (text.contains('today') || text.contains('aaj') || text.contains('abhi') || text.contains('آج') || text.contains('ابھی')) {
      return DateTime.now();
    }
    return null;
  }

  String? _extractTime(String text) {
    final timeRegex = RegExp(r'(\d{1,2}(:\d{2})?\s*(am|pm|AM|PM))');
    final match = timeRegex.firstMatch(text);
    if (match != null) {
      return match.group(0);
    }
    if (text.contains('morning') || text.contains('subah') || text.contains('صبح')) {
      return '10:00 AM';
    }
    if (text.contains('evening') || text.contains('sham') || text.contains('شام')) {
      return '05:00 PM';
    }
    if (text.contains('afternoon') || text.contains('dopahar') || text.contains('دوپہر')) {
      return '02:00 PM';
    }
    return null;
  }

  String _extractAddress(String query, String fallback) {
    final lower = query.toLowerCase();
    final atIndex = lower.indexOf(' at ');
    if (atIndex != -1) {
      final potential = query.substring(atIndex + 4).trim();
      if (potential.isNotEmpty && potential.length < 50) {
        return potential;
      }
    }
    final inIndex = lower.indexOf(' in ');
    if (inIndex != -1) {
      final potential = query.substring(inIndex + 4).trim();
      if (potential.isNotEmpty && potential.length < 50) {
        return potential;
      }
    }
    return fallback;
  }

  String _formatDefaultTime() {
    final now = DateTime.now().add(const Duration(hours: 1));
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:00 $period';
  }

  bool _isAffirmative(String text) {
    return _matches(text, ['yes', 'yeah', 'yep', 'confirm', 'book', 'ha', 'haan', 'han', 'theek hai', 'krdo', 'kar do', 'bhej do', 'ji', 'جی', 'ہاں', 'کنفرم']);
  }

  bool _isNegative(String text) {
    return _matches(text, ['no', 'nope', 'cancel', 'nahi', 'na', 'choose another', 'dusra', 'doosra', 'nahin', 'نہیں', 'منسوخ']);
  }

  bool _matches(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  bool _isUrduScript(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  bool _isRomanUrdu(String text) {
    final romanKeywords = [
      'kya', 'kia', 'kese', 'kaise', 'kaisay', 'chahiye', 'hai', 'hain', 'mein', 'karna',
      'karein', 'kare', 'mujhe', 'hum', 'ap', 'aap', 'kaam', 'kitna', 'shukria', 'wala', 'wali', 'batao', 'krdo', 'kar'
    ];
    for (final word in romanKeywords) {
      if (text.contains(word)) return true;
    }
    return false;
  }
}
