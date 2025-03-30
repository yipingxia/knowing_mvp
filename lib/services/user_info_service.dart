import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_info.dart';
import '../services/user_service.dart';

class UserInfoService {
  final FirebaseFirestore _firestore;
  final UserService _userService;
  
  UserInfoService(this._firestore) : _userService = UserService();
  
  // Get the user's info document reference
  Future<DocumentReference<Map<String, dynamic>>> get _userInfoRef async {
    final username = _userService.getUsernameFromStorage();
    if (username == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('users')
        .doc(username)
        .collection('userInfo')
        .doc('profile');
  }

  // Save or update user info
  Future<void> saveUserInfo(UserInfo userInfo) async {
    try {
      final userInfoRef = await _userInfoRef;
      await userInfoRef.set(userInfo.toMap(), SetOptions(merge: true));
      print('Successfully saved user info');
    } catch (e, stackTrace) {
      print('Error saving user info: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get user info
  Future<UserInfo?> getUserInfo() async {
    try {
      final userInfoRef = await _userInfoRef;
      final doc = await userInfoRef.get();
      
      if (doc.exists && doc.data() != null) {
        return UserInfo.fromMap(doc.data()!);
      }
      return null;
    } catch (e, stackTrace) {
      print('Error getting user info: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Stream user info for real-time updates
  Stream<UserInfo?> watchUserInfo() {
    return Stream.fromFuture(_userInfoRef).asyncExpand((userInfoRef) {
      return userInfoRef.snapshots().map((doc) {
        if (doc.exists && doc.data() != null) {
          return UserInfo.fromMap(doc.data()!);
        }
        return null;
      });
    });
  }
} 