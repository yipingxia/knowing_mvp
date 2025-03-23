import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class UserService {
  static const String _usernameKey = 'knowing_username';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hash password
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Check if username exists and verify password
  Future<bool> verifyUser(String username, String password) async {
    try {
      print('Verifying user: $username');
      final doc = await _firestore
          .collection('users')
          .doc(username)
          .get(const GetOptions(source: Source.server));
      
      if (!doc.exists) {
        print('User does not exist');
        return false;
      }

      final userData = doc.data();
      // If no password is set (legacy user) or password matches
      if (userData?['password'] == null || userData?['password'] == _hashPassword(password)) {
        saveUsernameToStorage(username);
        return true;
      }

      print('Password verification failed');
      return false;
    } catch (e) {
      print('Error verifying user: $e');
      return false;
    }
  }

  // Register new username with password
  Future<bool> registerUsername(String username, String password) async {
    print('Starting username registration for: $username');
    
    try {
      // Use a transaction to ensure atomicity
      bool success = await _firestore.runTransaction<bool>((transaction) async {
        final usernameDoc = await transaction.get(_firestore.collection('usernames').doc(username));
        
        if (usernameDoc.exists) {
          print('Username is already taken (transaction check): $username');
          return false;
        }

        print('Username is available, creating documents');

        final hashedPassword = _hashPassword(password);
        final timestamp = FieldValue.serverTimestamp();

        transaction.set(_firestore.collection('usernames').doc(username), {
          'username': username,
          'createdAt': timestamp,
        });

        transaction.set(_firestore.collection('users').doc(username), {
          'username': username,
          'password': hashedPassword,
          'createdAt': timestamp,
        });

        return true;
      });

      if (success) {
        saveUsernameToStorage(username);
        print('Username registration successful');
      }

      return success;
    } catch (e) {
      print('Error registering username: $e');
      return false;
    }
  }

  // Save username to localStorage
  void saveUsernameToStorage(String username) {
    try {
      print('Saving username to localStorage: $username');
      html.window.localStorage[_usernameKey] = username;
    } catch (e) {
      print('Error saving to localStorage: $e');
    }
  }

  // Get username from localStorage
  String? getUsernameFromStorage() {
    try {
      final username = html.window.localStorage[_usernameKey];
      print('Retrieved username from localStorage: $username');
      return username;
    } catch (e) {
      print('Error getting username from localStorage: $e');
      return null;
    }
  }

  // Clear username from localStorage
  void clearUsernameFromStorage() {
    try {
      print('Clearing username from localStorage');
      html.window.localStorage.remove(_usernameKey);
    } catch (e) {
      print('Error clearing localStorage: $e');
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String username) async {
    try {
      print('Fetching user data for: $username');
      final doc = await _firestore
          .collection('users')
          .doc(username)
          .get(const GetOptions(source: Source.serverAndCache));
      print('User data retrieved: ${doc.data()}');
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
} 