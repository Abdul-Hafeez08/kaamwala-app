import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIChatService {
  // Read Gemini API key from .env file
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  GenerativeModel? _model;
  ChatSession? _chatSession;

  AIChatService() {
    _initGemini();
  }

  void _initGemini() {
    if (_apiKey.isNotEmpty && _apiKey != 'YOUR_GEMINI_API_KEY') {
      try {
        _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: _apiKey,
          systemInstruction: Content.system(_systemPrompt),
          generationConfig: GenerationConfig(
            temperature: 0.7,
            maxOutputTokens: 1024,
          ),
        );
        _chatSession = _model?.startChat();
      } catch (e) {
        debugPrint('AIChatService: failed to initialize Gemini model: $e');
        _model = null;
        _chatSession = null;
      }
    }
  }

  static const String _systemPrompt = '''
You are Kaamwala AI Assistant (کام والا اسسٹنٹ) — a friendly, helpful bilingual (English, Urdu, and Roman Urdu) chatbot for the Kaamwala home services app.

About Kaamwala:
- Kaamwala connects customers with verified home service providers in Pakistan.
- Services available: Electrician (الیکٹریشن), Plumber (پلمبر), AC Technician (اے سی), Solar Panel Service (سولر پینل), Home Tutor (ہوم ٹیوٹر), Car Wash (کار واش), Painter (پینٹر), CCTV Service (سی سی ٹی وی), Event Decoration (ایونٹ ڈیکوریشن), Beauty Salon / Haircut (بیوٹی سیلون), House Cleaning (گھر کی صفائی), Maid Service (میڈ / ماسی), Carpenter (کارپینٹر), Laundry & Ironing (لانڈری / استری).
- Features: Direct booking, Nearby Workers Map, General Job Marketplace, In-app live chat, Reviews and Ratings, Worker Dashboard with earnings.
- Pricing: Set by each worker (Fixed quote or Hourly rate).

Instructions:
- Remember previous context and answers given during the ongoing conversation.
- If user speaks Urdu (اردو), reply in fluent polite Urdu.
- If user speaks Roman Urdu (e.g. "booking karni hai"), reply in helpful Roman Urdu.
- If user speaks English, reply in clear polite English.
- Keep responses concise (2 to 4 sentences) and add relevant emojis.
''';

  Future<String> sendMessage(
    String userMessage, {
    List<Map<String, dynamic>> history = const [],
    String? additionalContext,
  }) async {
    final cleanMsg = userMessage.trim();
    if (cleanMsg.isEmpty) {
      return 'Please ask a question! / براہ کرم اپنا سوال لکھیں۔';
    }

    // If real Gemini API key is configured, try calling it with session
    if (_chatSession != null) {
      try {
        final prompt = additionalContext != null && additionalContext.isNotEmpty
            ? "BACKGROUND APP DATA (Use this data to answer the user's query if relevant):\n$additionalContext\n\nUser Query:\n$cleanMsg"
            : cleanMsg;

        final response = await _chatSession!.sendMessage(
          Content.text(prompt),
        );
        if (response.text != null && response.text!.trim().isNotEmpty) {
          return response.text!.trim();
        }
      } catch (e, st) {
        debugPrint('AIChatService.sendMessage Gemini API error: $e');
        debugPrint('$st');
        // Fallback to built-in intelligent engine on any API error or quota limit
      }
    }

    // Built-in intelligent bilingual conversational AI response engine
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // natural typing feel
    return _generateSmartResponse(cleanMsg, history: history);
  }

  void resetChat() {
    _initGemini();
  }

  String _generateSmartResponse(
    String input, {
    List<Map<String, dynamic>> history = const [],
  }) {
    final lower = input.toLowerCase();

    // 1. Language Detection & Greetings (English, Roman Urdu, Urdu Script)
    if (_matches(lower, [
      'slam',
      'salam',
      'assalam',
      'aoa',
      'hello',
      'hi',
      'hey',
      'kia hal',
      'kya hal',
      'kaisay ho',
      'kaise ho',
      'kaise hen',
      'کیسے',
      'سلام',
      'السلام',
    ])) {
      if (_isUrduScript(input)) {
        return 'وعلیکم السلام! میں کام والا (Kaamwala) کا AI اسسٹنٹ ہوں۔ میں آپ کی کیا مدد کر سکتا ہوں؟ آپ سروسز، بکنگ، ورکرز اور ریٹس کے بارے میں پوچھ سکتے ہیں 😊';
      } else if (_isRomanUrdu(lower)) {
        return 'Walaikum Assalam! 👋 Main Kaamwala AI Assistant hoon. Main aap ko services dhondnay, booking karnay aur workers se rabta karnay mein madad kar sakta hoon. Batayein main aap ki kya madad karoon? 😊';
      } else {
        return 'Hello! 👋 I am your Kaamwala AI Assistant. How can I help you today? You can ask about our services, booking a worker, checking prices, or tracking jobs! 😊';
      }
    }

    // 2. How to Book a Service / Booking help
    if (_matches(lower, [
      'how to book',
      'book a service',
      'booking kais',
      'booking kase',
      'booking kese',
      'book kaise',
      'book krna',
      'order kaise',
      'بکنگ',
      'کیسے بک',
      'طریقہ',
    ])) {
      if (_isUrduScript(input)) {
        return '📋 **بکنگ کا آسان طریقہ:**\n1. ہوم اسکرین پر اپنی مطلوبہ سروس (جیسے الیکٹریشن، پلمبر) منتخب کریں۔\n2. ماہر ورکرز کی لسٹ اور ان کی ریٹنگز دیکھیں۔\n3. ورکر کی پروفائل کھول کر "Book Now" پر کلک کریں، تاریخ اور وقت درج کریں اور بکنگ کنفرم کریں!';
      } else if (_isRomanUrdu(lower)) {
        return '📋 **Booking ka asaan tareeqa:**\n1. Home screen par apni zaroorat ki service (e.g. Electrician, Plumber) choose karein.\n2. Workers ki ratings aur profiles check karein.\n3. Worker profile mein "Book Now" dabayein, date aur time select karke confirm karein!';
      } else {
        return '📋 **How to Book a Service:**\n1. Select your required category from the Home screen (e.g., Electrician, Plumber).\n2. Browse approved worker profiles and ratings.\n3. Tap on a worker and click "Book Now", select your date/time and confirm!';
      }
    }

    // 3. Find Services / All Categories List
    if (_matches(lower, [
      'find a service',
      'services',
      'service list',
      'konsi service',
      'kya kaam',
      'tamam services',
      'سروسز',
      'کام',
      'کونسی سروس',
    ])) {
      if (_isUrduScript(input)) {
        return '🔧 **کام والا کی دستیاب سروسز:**\n⚡ الیکٹریشن\n🚰 پلمبر\n❄️ اے سی ٹیکنیشن\n☀️ سولر پینل سروس\n📚 ہوم ٹیوٹر\n🚗 کار واش ایٹ ہوم\n🎨 پینٹر\n📹 سی سی ٹی وی کیمرہ\n🎉 ایونٹ ڈیکوریشن\n💇 بیوٹی سیلون / ہیئر کٹ\n🧹 گھر کی صفائی\n🏠 ماسی / میڈ سروس\n🪚 کارپینٹر\n👔 لانڈری اور استری\n\nآپ کسی بھی سروس کے بارے میں مزید تفصیل پوچھ سکتے ہیں!';
      } else if (_isRomanUrdu(lower)) {
        return '🔧 **Kaamwala par available services:**\n⚡ Electrician\n🚰 Plumber\n❄️ AC Technician\n☀️ Solar Panel Service\n📚 Home Tutor\n🚗 Car Wash at Home\n🎨 Painter\n📹 CCTV Service\n🎉 Event Decoration\n💇 Beauty Salon / Haircut\n🧹 House Cleaning\n🏠 Maid Service\n🪚 Carpenter\n👔 Laundry & Ironing\n\nAap jis service ki zaroorat ho, batayein main guide kar deta hoon!';
      } else {
        return '🔧 **Available Services on Kaamwala:**\n⚡ Electrician\n🚰 Plumber\n❄️ AC Technician\n☀️ Solar Panel Service\n📚 Home Tutor\n🚗 Car Wash at Home\n🎨 Painter\n📹 CCTV Service\n🎉 Event Decoration\n💇 Beauty Salon / Haircut\n🧹 House Cleaning\n🏠 Maid Service\n🪚 Carpenter\n👔 Laundry & Ironing\n\nWhich service are you looking for today?';
      }
    }

    // 4. Electrician
    if (_matches(lower, [
      'electric',
      'bijli',
      'short circuit',
      'fan',
      'wiring',
      'switch',
      'الیکٹریشن',
      'بجلی',
    ])) {
      if (_isUrduScript(input)) {
        return '⚡ **الیکٹریشن سروس:** ہمارے پاس ماہر الیکٹریشن دستیاب ہیں جو وائرنگ، پنکھے کی فٹنگ، سوئچ بورڈ، بریکر، یو پی ایس اور شارٹ سرکٹ کی مرمت کے لیے حاضر ہیں۔ ہوم اسکرین پر "Electrician" پر کلک کریں اور قریبی ماہر بک کریں۔';
      } else if (_isRomanUrdu(lower)) {
        return '⚡ **Electrician Service:** Hamare verified electricians wiring, fans, switches, UPS, aur short circuit theek karne ke liye available hain. Home screen par "Electrician" category mein jakar book karein!';
      } else {
        return '⚡ **Electrician Service:** Our verified electricians handle wiring, switchboards, fan repair, circuit breakers, and UPS installations. Go to the "Electrician" category on the home screen to book now!';
      }
    }

    // 5. Plumber
    if (_matches(lower, [
      'plumb',
      'nalka',
      'leakage',
      'pipe',
      'tanki',
      'sanitary',
      'motor',
      'پلمبر',
      'نل',
    ])) {
      if (_isUrduScript(input)) {
        return '🚰 **پلمبر سروس:** پانی کی لیکیج، پائپ فٹنگ، نلکے، واش روم سینٹری، گیزر اور واٹر موٹر کی تنصیب اور مرمت کے لیے بہترین پلمبرز دستیاب ہیں۔ "Plumber" سیکشن میں جائیں!';
      } else if (_isRomanUrdu(lower)) {
        return '🚰 **Plumber Service:** Water leakage, pipe repairs, tap fittings, sanitary work, aur geyser/motor issues ke liye expert plumbers available hain. "Plumber" category open karein!';
      } else {
        return '🚰 **Plumber Service:** We provide skilled plumbers for water pipe repairs, tap leaking, sanitary fixtures, water motor and geyser maintenance. Select "Plumber" to find top-rated workers!';
      }
    }

    // 6. AC Technician
    if (_matches(lower, [
      'ac',
      'air conditioner',
      'cooling',
      'gas charge',
      'filter',
      'اے سی',
    ])) {
      if (_isUrduScript(input)) {
        return '❄️ **اے سی ٹیکنیشن:** اے سی سروس، کولنگ کے مسائل، گیس چارجنگ، انسٹالیشن اور انورٹر فالٹ ٹھیک کروانے کے لیے ہمارے تصدیق شدہ اے سی ماہرین کو بک کریں۔';
      } else if (_isRomanUrdu(lower)) {
        return '❄️ **AC Technician:** AC ki general service, cooling issues, gas refilling, aur split installation ke liye "AC Technician" category check karein!';
      } else {
        return '❄️ **AC Technician:** Book professional AC technicians for routine servicing, gas refilling, cooling diagnostics, and split/inverter AC installation.';
      }
    }

    // 7. Solar Panel
    if (_matches(lower, ['solar', 'inverter', 'battery', 'plate', 'سولر'])) {
      if (_isUrduScript(input)) {
        return '☀️ **سولر پینل سروس:** سولر پلیٹس کی صفائی، انورٹر سیٹنگ، بیٹری وائرنگ اور نئے سولر سسٹم کی انسٹالیشن کے لیے ماہرین دستیاب ہیں۔ "Solar Panel Service" سیکشن وزٹ کریں۔';
      } else if (_isRomanUrdu(lower)) {
        return '☀️ **Solar Panel Service:** Solar plates installation, inverter setup, wiring aur maintenance ke liye "Solar Panel Service" se expert book karein!';
      } else {
        return '☀️ **Solar Panel Service:** Hire solar specialists for plate cleaning, inverter wiring, net metering setups, and maintenance from the "Solar Panel Service" section!';
      }
    }

    // 8. Painter
    if (_matches(lower, [
      'paint',
      'color',
      'rang',
      'distemper',
      'پینٹر',
      'رنگ',
    ])) {
      if (_isUrduScript(input)) {
        return '🎨 **پینٹر سروس:** گھر اور دفتر کے اندرونی و بیرونی پینٹ، ڈسٹیمپر، ویدر شیٹ اور وال پٹی کے کام کے لیے تجربہ کار پینٹرز موجود ہیں۔ "Painter" کیٹیگری دیکھیں!';
      } else if (_isRomanUrdu(lower)) {
        return '🎨 **Painter Service:** Ghar aur office ke interior/exterior paint, wall putty aur weather-sheet ke liye expert painters available hain!';
      } else {
        return '🎨 **Painter Service:** Get interior & exterior painting, weather-sheet, polish, and wall repair done by experienced painters from the "Painter" category!';
      }
    }

    // 9. House Cleaning / Maid
    if (_matches(lower, [
      'clean',
      'safai',
      'maid',
      'masi',
      'jharo',
      'pocha',
      'صفائی',
      'ماسی',
    ])) {
      if (_isUrduScript(input)) {
        return '🧹 **گھر کی صفائی اور ماسی سروس:** گہرے گھر کی صفائی، فرش، کچن اور واش رومز کی صفائی کے لیے قابل اعتماد ہیلپرز دستیاب ہیں۔ "House Cleaning" یا "Maid Service" منتخب کریں۔';
      } else if (_isRomanUrdu(lower)) {
        return '🧹 **Cleaning & Maid Service:** Ghar ki deep cleaning, kitchen/washroom safai aur daily maid services ke liye "House Cleaning" ya "Maid Service" par jayein!';
      } else {
        return '🧹 **Cleaning & Maid Service:** Book trusted helpers for deep home cleaning, kitchen hygiene, washrooms, and routine housekeeping under "House Cleaning" or "Maid Service".';
      }
    }

    // 10. Carpenter / CCTV / Tutor / Car wash / Salon / Laundry
    if (_matches(lower, [
      'carpenter',
      'lakri',
      'door',
      'lock',
      'furniture',
      'کارپینٹر',
      'لکڑی',
    ])) {
      return _isUrduScript(input)
          ? '🪚 **کارپینٹر:** فرنیچر، دروازے، تالے کی فٹنگ اور الماری کے کام کے لیے ماہر کارپینٹر بک کریں۔'
          : '🪚 **Carpenter:** Book skilled carpenters for furniture repair, wooden doors, locks, and custom woodwork in the "Carpenter" section.';
    }

    if (_matches(lower, ['cctv', 'camera', 'security', 'کیمرہ'])) {
      return _isUrduScript(input)
          ? '📹 **سی سی ٹی وی سروس:** کیمرہ انسٹالیشن، ڈی وی آر کنفیگریشن اور موبائل پر کیمرہ سیٹ اپ کے لیے "CCTV Service" منتخب کریں۔'
          : '📹 **CCTV Service:** Secure your home or office. Book technicians for CCTV installation, DVR wiring, and live mobile view setup under "CCTV Service".';
    }

    if (_matches(lower, [
      'tutor',
      'tuition',
      'study',
      'teacher',
      'پڑھائی',
      'استاد',
    ])) {
      return _isUrduScript(input)
          ? '📚 **ہوم ٹیوٹر:** بچوں کی اسکول، کالج اور قرآن پاک کی تعلیم کے لیے قابل ٹیوٹرز دستیاب ہیں۔ "Home Tutor" کیٹیگری دیکھیں۔'
          : '📚 **Home Tutor:** Find qualified tutors for school, college subjects, and Quran classes at your home from the "Home Tutor" section.';
    }

    if (_matches(lower, ['car wash', 'gari dhow', 'car cleaning', 'کار واش'])) {
      return _isUrduScript(input)
          ? '🚗 **کار واش:** آپ کی دہلیز پر کار کی صفائی، واش اور اندرونی ویکیوم کے لیے "Car Wash at Home" سے سروس بک کریں۔'
          : '🚗 **Car Wash at Home:** Get waterless/foam car wash, interior vacuuming, and detailing right at your doorstep!';
    }

    // 11. Service Pricing / Rates / Charges
    if (_matches(lower, [
      'service pricing',
      'price',
      'pricing',
      'rate',
      'cost',
      'kitne paise',
      'kitna kharcha',
      'charges',
      'پیسے',
      'ریٹ',
      'قیمت',
    ])) {
      if (_isUrduScript(input)) {
        return '💰 **سروس چارجز کی تفصیل:**\nکام والا پر ورکرز دو طرح سے ریٹس فراہم کرتے ہیں:\n1. **فکسڈ ریٹ (Fixed Quote):** مخصوص کام کا طے شدہ معاوضہ۔\n2. **گھنٹہ وار ریٹ (Hourly Rate):** کام کے وقت کے مطابق فی گھنٹہ چارجز۔\n\nآپ ورکر کی پروفائل میں اس کے درست ریٹس دیکھ سکتے ہیں اور ان سے چیٹ میں بھی ڈسکس کر سکتے ہیں!';
      } else if (_isRomanUrdu(lower)) {
        return '💰 **Service Pricing / Rates:**\nKaamwala par workers do tarah ke rates offer karte hain:\n1. **Fixed Price:** Kaam ka mutayyan bill.\n2. **Hourly Rate:** Kaam ke time ke hisab se per hour rate.\n\nAap worker ki profile mein ja kar unke exact rates check kar sakte hain!';
      } else {
        return '💰 **Service Pricing on Kaamwala:**\nWorkers specify their pricing type on their profile:\n1. **Fixed Quote:** Set price for standard service jobs.\n2. **Hourly Rate:** Charged per hour of work completed.\n\nCheck individual worker profiles to see exact rates and negotiate via live chat!';
      }
    }

    // 12. Nearby Workers / Map
    if (_matches(lower, [
      'nearby',
      'map',
      'location',
      'qareeb',
      'aas paas',
      'open to work',
      'نقشہ',
      'قریبی',
    ])) {
      if (_isUrduScript(input)) {
        return '🗺️ **قریبی ورکرز کا نقشہ:** ہوم اسکرین پر موجود "Nearby Workers" کارڈ پر کلک کریں۔ آپ کو اپنے جی پی ایس مقام کے قریب کام کے لیے دستیاب (Open to Work) تمام ورکرز لائیو میپ پر نظر آئیں گے!';
      } else if (_isRomanUrdu(lower)) {
        return '🗺️ **Nearby Workers Map:** Home screen par "Nearby Workers" wale card par click karein. Aapko apne qareeb available (Open to Work) workers live map par dikh jayenge!';
      } else {
        return '🗺️ **Nearby Workers Map:** Tap the "Nearby Workers" banner on the Home screen to view a live interactive map of verified workers available near your current GPS location!';
      }
    }

    // 13. How Reviews Work
    if (_matches(lower, [
      'review',
      'rating',
      'star',
      'feedback',
      'how reviews work',
      'ریٹنگ',
      'ریویو',
    ])) {
      if (_isUrduScript(input)) {
        return '⭐ **ریٹنگ اور ریویوز کا طریقہ:** جب ورکر آپ کا کام مکمل کر لیتا ہے تو آپ بکنگ سیکشن میں جا کر ورکر کو 1 سے 5 سٹار ریٹنگ اور تفصیلی ریویو دے سکتے ہیں۔ اس سے دیگر کسٹمرز کو بہترین ورکر چننے میں مدد ملتی ہے!';
      } else if (_isRomanUrdu(lower)) {
        return '⭐ **Reviews aur Ratings:** Kaam mukammal hone par aap "Bookings" tab mein jakar worker ko 1 se 5 stars aur review de sakte hain. Is se service quality behtar rehti hai!';
      } else {
        return '⭐ **How Reviews Work:** Once a job is marked completed, you can rate the worker from 1 to 5 stars and write a review in the Bookings tab to help the community!';
      }
    }

    // 14. Support / Complaints / Contact
    if (_matches(lower, [
      'support',
      'complaint',
      'contact',
      'help',
      'shikayat',
      'masla',
      'rabta',
      'شکایت',
      'مدد',
      'رابطہ',
    ])) {
      if (_isUrduScript(input)) {
        return '📞 **کسٹمر سپورٹ اور شکایات:** اگر آپ کو کسی سروس یا ورکر سے کوئی مسئلہ ہو تو بائیں جانب کی مینو (Drawer) کھول کر "Complaints & Support" پر کلک کریں اور اپنی شکایت درج کریں۔ ہماری ایڈمن ٹیم فوری ایکشن لے گی!';
      } else if (_isRomanUrdu(lower)) {
        return '📞 **Complaints & Support:** Agar koi masla ya shikayat ho to App Drawer (Menu) open karein aur "Complaints & Support" par tap karke apni complaint darj karein. Admin team foran check karegi!';
      } else {
        return '📞 **Contact Support & Complaints:** If you face any issue with a booking or worker, open the app side menu (Drawer) and select "Complaints & Support" to file a ticket directly with our admin!';
      }
    }

    // 15. General Request / Marketplace
    if (_matches(lower, [
      'marketplace',
      'general post',
      'broadcast',
      'post job',
      'request',
    ])) {
      if (_isUrduScript(input)) {
        return '🚀 **جاب مارکیٹ پلیس:** ہوم اسکرین پر "Post General Request" پر کلک کر کے آپ اپنا کام پوسٹ کر سکتے ہیں۔ اس کیٹیگری کے تمام دستیاب ورکرز آپ کی پوسٹ دیکھ کر خود رابطہ کریں گے!';
      } else {
        return '🚀 **Job Marketplace:** You can post a "General Request" from the home screen banner. All available workers in that category will receive your job post and can accept it directly!';
      }
    }

    // 16. Worker Help (How to earn / find jobs)
    if (_matches(lower, [
      'worker',
      'kamai',
      'earning',
      'find jobs',
      'orders',
      'ورکر',
    ])) {
      if (_isUrduScript(input)) {
        return '💼 **ورکرز کے لیے رہنمائی:** اگر آپ ورکر ہیں تو "Find Jobs" میں جا کر اوپن جابز قبول کر سکتے ہیں اور اپنے ڈیش بورڈ میں روزانہ کی کمائی (Earnings) اور ایکٹو کام ٹریک کر سکتے ہیں!';
      } else {
        return '💼 **For Workers:** Check the "Find Jobs" tab to accept open customer requests, track your ongoing tasks in "Active", and view your revenue in the "Earnings" dashboard!';
      }
    }

    // 17. Thank you & Goodbye
    if (_matches(lower, [
      'thank',
      'shukriya',
      'dhanyawad',
      'shukria',
      'bye',
      'allah hafiz',
      'شکریہ',
      'اللہ حافظ',
    ])) {
      return _isUrduScript(input)
          ? 'آپ کا بہت شکریہ! کام والا (Kaamwala) استعمال کرنے پر خوش آمدید۔ اگر کوئی اور مدد چاہیے ہو تو ضرور بتائیں! 😊'
          : 'You are most welcome! Glad I could help. Wishing you a great experience on Kaamwala! 😊';
    }

    // Default intelligent fallback in matching language
    if (_isUrduScript(input)) {
      return 'میں آپ کی بات سمجھ گیا۔ آپ کام والا پر کسی بھی سروس (جیسے الیکٹریشن، پلمبر، اے سی)، بکنگ کے طریقے، یا ریٹس کے متعلق بلا جھجھک پوچھ سکتے ہیں! 😊';
    } else if (_isRomanUrdu(lower)) {
      return 'Main samajh gaya! Aap Kaamwala app par kisi bhi service (Electrician, Plumber, AC, Painter wagera), booking ke tareeqay, ya prices ke baray mein bejhijhak pooch saktay hain 😊';
    } else {
      return 'I am here to help! You can ask me about any service category (Electrician, Plumber, AC, Cleaning), how to book a worker, check pricing, or find nearby experts. 😊';
    }
  }

  bool _matches(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  bool _isUrduScript(String text) {
    // Check for Arabic/Urdu Unicode range
    final regex = RegExp(r'[\u0600-\u06FF]');
    return regex.hasMatch(text);
  }

  bool _isRomanUrdu(String text) {
    final romanKeywords = [
      'kya',
      'kia',
      'kese',
      'kaise',
      'kaisay',
      'chahiye',
      'chaheay',
      'hai',
      'hain',
      'mein',
      'karna',
      'karein',
      'kare',
      'mujhe',
      'hum',
      'ap',
      'aap',
      'kaam',
      'kitna',
      'kitne',
      'paise',
      'shukria',
      'shukriya',
      'wala',
      'wali',
      'batao',
      'batayein',
      'bataen',
      'bhi',
      'nahi',
      'krna',
      'par',
    ];
    for (final word in romanKeywords) {
      if (text.contains(word)) return true;
    }
    return false;
  }
}
