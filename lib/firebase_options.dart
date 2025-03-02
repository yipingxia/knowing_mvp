import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // Add other platforms if needed
    throw UnsupportedError(
      'DefaultFirebaseOptions are not configured for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCL8C6_q3CtPkg33xXA4SUxmDOSnW-dOH4",
    authDomain: "knowing-v1.firebaseapp.com",
    projectId: "knowing-v1",
    storageBucket: "knowing-v1.firebasestorage.app",
    messagingSenderId: "349439956510",
    appId: "1:349439956510:web:158dcfc3b5aad153f2c00f",
    measurementId: "G-B2DPWC59MJ"
  );
} 