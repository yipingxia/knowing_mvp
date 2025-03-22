import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recommendation.dart';

class RecommendationsService {
  final FirebaseFirestore _firestore;
  static const String _collection = 'dailyRecos';

  RecommendationsService(this._firestore);

  // Get recommendations for a specific date
  Future<Recommendation?> getRecommendations(dynamic date) async {
    final formattedDate = _formatDate(date is DateTime ? date : DateTime.parse(date.toString()));
    try {
      print('Getting recommendations for date: $formattedDate');
      final doc = await _firestore.collection(_collection).doc(formattedDate).get();
      print('Document exists: ${doc.exists}');
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        print('Raw data: $data');
        return Recommendation.fromJson(data);
      }
      return null;
    } catch (e, stackTrace) {
      print('Error getting recommendations: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Watch recommendations for a specific date
  Stream<Recommendation?> watchRecommendations(dynamic date) {
    final formattedDate = _formatDate(date is DateTime ? date : DateTime.parse(date.toString()));
    print('Watching recommendations for date: $formattedDate');
    return _firestore
        .collection(_collection)
        .doc(formattedDate)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            print('Received recommendation data: $data');
            return Recommendation.fromJson(data);
          }
          print('No recommendation document exists for date: $formattedDate');
          return null;
        })
        .handleError((error, stackTrace) {
          print('Error in watchRecommendations: $error');
          print('Stack trace: $stackTrace');
          return null;
        });
  }

  // Helper function to format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
} 