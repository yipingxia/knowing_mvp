import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/journal_entry.dart';
import '../services/user_service.dart';

class DailyLogService {
  final FirebaseFirestore _firestore;
  final UserService _userService;
  
  // Constructor that takes the Firestore instance
  DailyLogService(this._firestore) : _userService = UserService();
  
  // Get the user's daily logs collection reference
  Future<CollectionReference<Map<String, dynamic>>> get _dailyLogsRef async {
    final username = _userService.getUsernameFromStorage();
    if (username == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(username).collection('dailyLogs');
  }

  // Add or update a daily log
  Future<void> saveLog(JournalEntry entry) async {
    try {
      print('Attempting to save daily log for date: ${entry.date}');
      
      // Format date as YYYY-MM-DD
      final String documentId = _formatDate(entry.date);
      print('Using document ID: $documentId');
      
      final logsRef = await _dailyLogsRef;
      
      // Get existing document to merge correctly
      final existingDoc = await logsRef.doc(documentId).get();
      final existingData = existingDoc.data() ?? {};
      
      // Create update data based on what fields are provided
      final Map<String, dynamic> updateData = {
        'date': documentId,  // Store as string YYYY-MM-DD
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Update fields from InteractiveInputScreen if they are provided
      if (entry.emotion.isNotEmpty) updateData['emotion'] = entry.emotion;
      if (entry.energyLevel > 0) updateData['energyLevel'] = entry.energyLevel;
      if (entry.exercise.isNotEmpty) updateData['exercise'] = entry.exercise;
      if (entry.bodyStressLevel != null) updateData['bodyStressLevel'] = entry.bodyStressLevel;
      if (entry.nutrition.isNotEmpty) updateData['nutrition'] = entry.nutrition;
      if (entry.fiberGrams != null) updateData['fiberGrams'] = entry.fiberGrams;
      if (entry.proteinGrams != null) updateData['proteinGrams'] = entry.proteinGrams;
      if (entry.sleepQualityIndex > 0) updateData['sleepQuality'] = entry.sleepQualityIndex;
      if (entry.symptoms.isNotEmpty) updateData['symptoms'] = entry.symptoms;
      
      // Update fields from HomeScreen if they are provided
      if (entry.lastPeriodDate != null) {
        updateData['lastPeriodDate'] = entry.lastPeriodDate?.toIso8601String();
      }
      if (entry.notes.isNotEmpty) updateData['notes'] = entry.notes;
      if (entry.stressors.isNotEmpty) updateData['stressors'] = entry.stressors;

      // Keep existing phase if it exists
      if (existingData['currentPhase'] != null) {
        updateData['currentPhase'] = existingData['currentPhase'];
      }

      await logsRef.doc(documentId).set(updateData, SetOptions(merge: true));
      print('Successfully saved daily log to Firestore with ID: $documentId');
    } catch (e, stackTrace) {
      print('Error saving daily log: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get today's log
  Future<JournalEntry?> getTodayLog() async {
    try {
      final docId = _formatDate(DateTime.now());
      print('Fetching today\'s log with ID: $docId');
      
      final logsRef = await _dailyLogsRef;
      final doc = await logsRef.doc(docId).get();
      
      if (doc.exists && doc.data() != null) {
        print('Found today\'s log');
        return JournalEntry.fromMap(doc.data()!);
      }
      print('No log found for today');
      return null;
    } catch (e, stackTrace) {
      print('Error getting today\'s log: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get all daily logs
  Stream<List<JournalEntry>> getAllLogs() {
    print('Setting up stream to listen for daily logs');
    return Stream.fromFuture(_dailyLogsRef).asyncExpand((logsRef) {
      return logsRef
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
            print('Received ${snapshot.docs.length} logs from Firestore');
            return snapshot.docs
                .map((doc) => JournalEntry.fromMap(doc.data()))
                .toList();
          });
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
} 