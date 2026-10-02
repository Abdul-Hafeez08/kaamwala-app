import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: 'AIzaSyBvErB96xb_ityQflE8KaDPP68lE0jEF58',
    appId: dotenv.env['FIREBASE_WEB_APP_ID'] ?? '',
    messagingSenderId: '1081530084240',
    projectId: 'myapp-3da2e',
    authDomain: 'myapp-3da2e.firebaseapp.com',
    storageBucket: 'myapp-3da2e.firebasestorage.app',
    measurementId: 'G-DXRFDRJR9Z',
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: 'AIzaSyBvErB96xb_ityQflE8KaDPP68lE0jEF58',
    appId: '1:1081530084240:android:794c18ab839126f366a115',
    messagingSenderId: '1081530084240',
    projectId: 'myapp-3da2e',
    storageBucket: 'myapp-3da2e.firebasestorage.app',
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_IOS_API_KEY'] ?? '',
    appId: dotenv.env['FIREBASE_IOS_APP_ID'] ?? '',
    messagingSenderId: '1081530084240',
    projectId: 'myapp-3da2e',
    storageBucket: 'myapp-3da2e.firebasestorage.app',
    iosBundleId: dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? '',
  );
}
