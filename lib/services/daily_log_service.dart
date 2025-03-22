import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/journal_entry.dart';

class DailyLogService {
  final FirebaseFirestore _firestore;
  
  // Constructor that takes the Firestore instance
  DailyLogService(this._firestore);
  
  // Collection reference for daily logs
  CollectionReference<Map<String, dynamic>> get _logsCollection => 
      _firestore.collection('dailyLogs');

  // Add or update a daily log
  Future<void> saveLog(JournalEntry entry) async {
    try {
      print('Attempting to save daily log for date: ${entry.date}');
      
      // Format date as YYYY-MM-DD
      final String documentId = entry.date.toIso8601String().split('T')[0];
      print('Using document ID: $documentId');
      
      // Get existing document to merge correctly
      final existingDoc = await _logsCollection.doc(documentId).get();
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

      // Keep existing phase if it exists
      if (existingData['currentPhase'] != null) {
        updateData['currentPhase'] = existingData['currentPhase'];
      }

      await _logsCollection.doc(documentId).set(updateData, SetOptions(merge: true));
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
      final String documentId = DateTime.now().toIso8601String().split('T')[0];
      print('Fetching today\'s log with ID: $documentId');
      
      final doc = await _logsCollection.doc(documentId).get();
      
      if (doc.exists && doc.data() != null) {
        print('Found today\'s log');
        return _convertToJournalEntry(doc.data()!);
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
    return _logsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          print('Received ${snapshot.docs.length} logs from Firestore');
          return snapshot.docs
              .map((doc) => _convertToJournalEntry(doc.data()))
              .toList();
        });
  }

  // Convert Firestore data to JournalEntry object
  JournalEntry _convertToJournalEntry(Map<String, dynamic> data) {
    // Parse date from string YYYY-MM-DD
    final date = DateTime.parse(data['date']);
    
    // Parse lastPeriodDate if it exists
    final lastPeriodDate = data['lastPeriodDate'] != null
        ? DateTime.parse(data['lastPeriodDate'])
        : null;

    return JournalEntry(
      date: date,
      phase: data['currentPhase'] ?? '',
      energyLevel: (data['energyLevel'] as num?)?.toDouble() ?? 0,
      sleepQualityIndex: (data['sleepQuality'] as num?)?.toInt() ?? 0,
      exercise: data['exercise'] as String? ?? '',
      emotion: data['emotion'] as String? ?? '',
      symptoms: data['symptoms'] as String? ?? '',
      nutrition: data['nutrition'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      fiberGrams: (data['fiberGrams'] as num?)?.toDouble(),
      proteinGrams: (data['proteinGrams'] as num?)?.toDouble(),
      bodyStressLevel: (data['bodyStressLevel'] as num?)?.toDouble(),
      lastPeriodDate: lastPeriodDate,
    );
  }
} 