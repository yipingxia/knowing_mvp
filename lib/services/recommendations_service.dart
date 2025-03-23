import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recommendation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecommendationsService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  RecommendationsService(this._firestore) : _auth = FirebaseAuth.instance;

  // Get the user's recommendations collection reference
  CollectionReference<Map<String, dynamic>> get _recommendationsRef {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(userId).collection('recommendations');
  }

  Future<void> saveRecommendation(Recommendation recommendation) async {
    try {
      final docId = _formatDate(recommendation.date);
      await _recommendationsRef.doc(docId).set(recommendation.toMap());
    } catch (e) {
      print('Error saving recommendation: $e');
      rethrow;
    }
  }

  Future<Recommendation?> getRecommendations(DateTime date) async {
    try {
      final docId = _formatDate(date);
      final doc = await _recommendationsRef.doc(docId).get();
      
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
    return _recommendationsRef.doc(docId).snapshots().map((doc) {
      if (doc.exists) {
        return Recommendation.fromMap(doc.data()!);
      }
      return null;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
} 