import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recommendation.dart';
import '../services/user_service.dart';

class RecommendationsService {
  final FirebaseFirestore _firestore;
  final UserService _userService;

  RecommendationsService(this._firestore) : _userService = UserService();

  // Get the user's recommendations collection reference
  Future<CollectionReference<Map<String, dynamic>>> get _recommendationsRef async {
    final username = _userService.getUsernameFromStorage();
    if (username == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(username).collection('dailyRecos');
  }

  Future<void> saveRecommendation(Recommendation recommendation) async {
    try {
      final docId = _formatDate(recommendation.date);
      final recommendationsRef = await _recommendationsRef;
      print('Saving recommendation to dailyRecos collection with ID: $docId');
      await recommendationsRef.doc(docId).set(recommendation.toMap());
    } catch (e) {
      print('Error saving recommendation: $e');
      rethrow;
    }
  }

  Future<Recommendation?> getRecommendations(DateTime date) async {
    try {
      final docId = _formatDate(date);
      final recommendationsRef = await _recommendationsRef;
      final doc = await recommendationsRef.doc(docId).get();
      
      if (doc.exists) {
        return Recommendation.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting recommendations: $e');
      return null;
    }
  }

  Stream<Recommendation?> watchRecommendations(DateTime date) {
    final docId = _formatDate(date);
    return Stream.fromFuture(_recommendationsRef).asyncExpand((recommendationsRef) {
      return recommendationsRef.doc(docId).snapshots().map((doc) {
        if (doc.exists) {
          return Recommendation.fromMap(doc.data()!);
        }
        return null;
      });
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
} 