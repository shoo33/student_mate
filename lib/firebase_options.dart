import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB-he2X5GF2IFknqe__Fuu6-e4fPRsfc0Y',
    appId: '1:757155236599:web:697eee7a87b7c92837a1f2',
    messagingSenderId: '757155236599',
    projectId: 'studentmate-9ef99',
    authDomain: 'studentmate-9ef99.firebaseapp.com',
    storageBucket: 'studentmate-9ef99.firebasestorage.app',
    measurementId: 'G-ZL32L6P6WP',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB-he2X5GF2IFknqe__Fuu6-e4fPRsfc0Y',
    appId: '1:757155236599:android:5904abf27818553037a1f2',
    messagingSenderId: '757155236599',
    projectId: 'studentmate-9ef99',
    storageBucket: 'studentmate-9ef99.firebasestorage.app',
  );
}