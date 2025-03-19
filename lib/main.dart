import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Connect to Firestore emulator
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  
  // Connect to Functions emulator
  FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
  
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Knowing',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
