import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/journal_entry.dart';

class JournalService {
  final FirebaseFirestore _firestore;
  
  // Constructor that takes the Firestore instance
  JournalService(this._firestore);
  
  // Collection reference for journal entries
  CollectionReference<Map<String, dynamic>> get _entriesCollection => 
      _firestore.collection('journal_entries');

  // Add or update a journal entry
  Future<void> saveEntry(JournalEntry entry) async {
    try {
      print('Attempting to save journal entry for date: ${entry.date}');
      
      final String documentId = entry.date.toIso8601String().split('T')[0];
      print('Using document ID: $documentId');
      
      final Map<String, dynamic> entryData = {
        'date': entry.date,
        'phase': entry.phase,
        'energyLevel': entry.energyLevel,
        'sleepQualityIndex': entry.sleepQualityIndex,
        'exercise': entry.exercise,
        'emotion': entry.emotion,
        'symptoms': entry.symptoms,
        'nutrition': entry.nutrition,
        'notes': entry.notes,
        'fiberGrams': entry.fiberGrams,
        'proteinGrams': entry.proteinGrams,
        'bodyStressLevel': entry.bodyStressLevel,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await _entriesCollection.doc(documentId).set(entryData, SetOptions(merge: true));
      print('Successfully saved journal entry to Firestore with ID: $documentId');
    } catch (e, stackTrace) {
      print('Error saving journal entry: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get a specific journal entry by date
  Future<JournalEntry?> getEntryByDate(DateTime date) async {
    try {
      final String documentId = date.toIso8601String().split('T')[0];
      print('Fetching entry for date: $documentId');
      
      final doc = await _entriesCollection.doc(documentId).get();
      
      if (doc.exists && doc.data() != null) {
        print('Found entry for date: $documentId');
        return _convertToJournalEntry(doc.data()!);
      }
      print('No entry found for date: $documentId');
      return null;
    } catch (e, stackTrace) {
      print('Error getting journal entry: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get all journal entries
  Stream<List<JournalEntry>> getAllEntries() {
    print('Setting up stream to listen for journal entries');
    return _entriesCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          print('Received ${snapshot.docs.length} entries from Firestore');
          return snapshot.docs
              .map((doc) => _convertToJournalEntry(doc.data()))
              .toList();
        });
  }

  // Convert Firestore data to JournalEntry object
  JournalEntry _convertToJournalEntry(Map<String, dynamic> data) {
    return JournalEntry(
      date: (data['date'] as Timestamp).toDate(),
      phase: data['phase'] as String,
      energyLevel: (data['energyLevel'] as num).toDouble(),
      sleepQualityIndex: data['sleepQualityIndex'] as int,
      exercise: data['exercise'] as String? ?? '',
      emotion: data['emotion'] as String? ?? '',
      symptoms: data['symptoms'] as String? ?? '',
      nutrition: data['nutrition'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      fiberGrams: data['fiberGrams'] as double?,
      proteinGrams: data['proteinGrams'] as double?,
      bodyStressLevel: data['bodyStressLevel'] as double?,
    );
  }
} 