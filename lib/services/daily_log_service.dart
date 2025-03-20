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
      
      final String documentId = entry.date.toIso8601String().split('T')[0];
      print('Using document ID: $documentId');
      
      final Map<String, dynamic> logData = {
        'date': Timestamp.fromDate(entry.date),
        'phase': entry.phase,
        'energyLevel': entry.energyLevel,
        'sleepQualityIndex': entry.sleepQualityIndex,
        'exercise': entry.exercise,
        'emotion': entry.emotion,
        'symptoms': entry.symptoms,
        'nutrition': entry.nutrition,
        'notes': entry.notes,
        'lastPeriodDate': entry.lastPeriodDate?.toIso8601String(),
        'recommendations': entry.recommendations,
        'fiberGrams': entry.fiberGrams,
        'proteinGrams': entry.proteinGrams,
        'bodyStressLevel': entry.bodyStressLevel,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await _logsCollection.doc(documentId).set(logData, SetOptions(merge: true));
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
    final date = data['date'] is Timestamp 
        ? (data['date'] as Timestamp).toDate()
        : DateTime.parse(data['date'].toString());
    
    final lastPeriodDate = data['lastPeriodDate'] != null
        ? DateTime.parse(data['lastPeriodDate'].toString())
        : null;

    // Get fields directly from the document data
    final exercise = data['exercise'] as String? ?? '';
    final emotion = data['emotion'] as String? ?? '';
    final symptoms = data['symptoms'] as String? ?? '';
    final nutrition = data['nutrition'] as String? ?? '';
    final notes = data['notes'] as String? ?? '';
        
    return JournalEntry(
      date: date,
      phase: data['phase'] ?? '',
      energyLevel: (data['energyLevel'] as num?)?.toDouble() ?? 0,
      sleepQualityIndex: (data['sleepQualityIndex'] as num?)?.toInt() ?? 0,
      exercise: exercise,
      emotion: emotion,
      symptoms: symptoms,
      nutrition: nutrition,
      notes: notes,
      fiberGrams: data['fiberGrams'] as double?,
      proteinGrams: data['proteinGrams'] as double?,
      bodyStressLevel: data['bodyStressLevel'] as double?,
      lastPeriodDate: lastPeriodDate,
      recommendations: data['recommendations'] as Map<String, dynamic>?,
    );
  }
} 