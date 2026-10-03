import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web config — appId from Firebase Console > Project Settings > Web App
  // apiKey is same across platforms for this project
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBvErB96xb_' 'ityQflE8KaDPP68lE0jEF58',
    appId: '1:1081530084240:web:' 'a88d9fdf6e3c643166a115',
    messagingSenderId: '1081530084240',
    projectId: 'myapp-3da2e',
    authDomain: 'myapp-3da2e.firebaseapp.com',
    storageBucket: 'myapp-3da2e.firebasestorage.app',
    measurementId: 'G-DXRFDRJR9Z',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBvErB96xb_' 'ityQflE8KaDPP68lE0jEF58',
    appId: '1:1081530084240:android:a88d9fdf6e3c643166a115',
    messagingSenderId: '1081530084240',
    projectId: 'myapp-3da2e',
    storageBucket: 'myapp-3da2e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBvErB96xb_' 'ityQflE8KaDPP68lE0jEF58',
    appId: '1:1081530084240:ios:a88d9fdf6e3c643166a115',
    messagingSenderId: '1081530084240',
    projectId: 'myapp-3da2e',
    storageBucket: 'myapp-3da2e.firebasestorage.app',
    iosBundleId: 'com.example.kaamwala',
  );
}
