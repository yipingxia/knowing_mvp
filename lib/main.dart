import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCL8C6_q3CtPkg33xXA4SUxmDOSnW-dOH4",
        authDomain: "knowing-v1.firebaseapp.com",
        projectId: "knowing-v1",
        storageBucket: "knowing-v1.firebasestorage.app",
        messagingSenderId: "349439956510",
        appId: "1:349439956510:web:158dcfc3b5aad153f2c00f",
        measurementId: "G-B2DPWC59MJ",
      ),
    );

    // Connect to Firestore emulator
    String host = kIsWeb ? 'localhost' : '10.0.2.2';
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);

    // Configure Firestore settings
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      sslEnabled: false,  // Disable SSL for emulator
    );

    // Then try to enable persistence
    if (kIsWeb) {
      try {
        await FirebaseFirestore.instance.enablePersistence(
          const PersistenceSettings(synchronizeTabs: true),
        );
      } catch (e) {
        print('Persistence already enabled or not supported: $e');
      }
    }

    // Explicitly enable network
    await FirebaseFirestore.instance.enableNetwork();

    print('Firebase initialized successfully with emulator');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Knowing',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(),
    );
  }
}
