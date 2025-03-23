import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('Starting Firebase initialization...');
    
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
    print('Firebase core initialized');

    // Configure Firestore settings
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    print('Firestore settings configured');

    // Wait a moment for connection to establish
    await Future.delayed(const Duration(seconds: 2));

    // Test Firestore connection with retries
    bool connected = false;
    int retries = 3;
    
    while (!connected && retries > 0) {
      try {
        // Try to get documents with server-side validation
        final result = await FirebaseFirestore.instance
            .collection('usernames')
            .limit(1)
            .get(const GetOptions(source: Source.server));
        print('Firestore server connection successful. Documents found: ${result.docs.length}');
        connected = true;
      } catch (e) {
        retries--;
        if (e is FirebaseException && e.code == 'unavailable') {
          print('Server unavailable, checking cache...');
          try {
            final cacheResult = await FirebaseFirestore.instance
                .collection('usernames')
                .limit(1)
                .get(const GetOptions(source: Source.cache));
            print('Cache access successful. Documents in cache: ${cacheResult.docs.length}');
            connected = true;
          } catch (cacheError) {
            print('Cache access failed: $cacheError');
          }
        } else {
          print('Firestore connection attempt failed ($retries retries left): $e');
        }
      }
    }

    // Set up connection state monitoring
    FirebaseFirestore.instance.snapshotsInSync().listen(
      (_) {
        print('Firestore is in sync with server');
      },
      onError: (error) {
        print('Firestore sync error: $error');
        if (error is FirebaseException) {
          print('Firebase error code: ${error.code}');
          print('Firebase error message: ${error.message}');
        }
      },
    );

    print('Firebase initialization completed. Connection state: ${connected ? "ONLINE" : "OFFLINE"}');
  } catch (e, stackTrace) {
    print('Error initializing Firebase: $e');
    print('Stack trace: $stackTrace');
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
      home: const SplashScreen(),
    );
  }
}
