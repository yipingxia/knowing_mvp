import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recommendation.dart';

class RecommendationsService {
  final FirebaseFirestore _firestore;
  static const String _collection = 'dailyEntries';

  RecommendationsService(this._firestore);

  Stream<Recommendation?> watchRecommendations(DateTime date) {
    final formattedDate = _formatDate(date);
    
    return _firestore
        .collection(_collection)
        .doc(formattedDate)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || !snapshot.data()!.containsKey('recommendations')) {
            return null;
          }
          
          final data = snapshot.data()!['recommendations'] as Map<String, dynamic>;
          return Recommendation.fromJson(data);
        });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
} 