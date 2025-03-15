class JournalEntry {
  final DateTime date;
  final String phase;
  final double energyLevel;
  final int sleepQualityIndex;
  final String exercise;
  final String emotion;
  final String symptoms;
  final String nutrition;
  final double? fiberGrams;
  final double? proteinGrams;
  final double? bodyStressLevel;
  final String notes;

  JournalEntry({
    required this.date,
    required this.phase,
    required this.energyLevel,
    required this.sleepQualityIndex,
    this.exercise = '',
    this.emotion = '',
    this.symptoms = '',
    this.nutrition = '',
    this.fiberGrams,
    this.proteinGrams,
    this.bodyStressLevel,
    this.notes = '',
  });

  // Create a copy of this JournalEntry with some fields updated
  JournalEntry copyWith({
    DateTime? date,
    String? phase,
    double? energyLevel,
    int? sleepQualityIndex,
    String? exercise,
    String? emotion,
    String? symptoms,
    String? nutrition,
    double? fiberGrams,
    double? proteinGrams,
    double? bodyStressLevel,
    String? notes,
  }) {
    return JournalEntry(
      date: date ?? this.date,
      phase: phase ?? this.phase,
      energyLevel: energyLevel ?? this.energyLevel,
      sleepQualityIndex: sleepQualityIndex ?? this.sleepQualityIndex,
      exercise: exercise ?? this.exercise,
      emotion: emotion ?? this.emotion,
      symptoms: symptoms ?? this.symptoms,
      nutrition: nutrition ?? this.nutrition,
      fiberGrams: fiberGrams ?? this.fiberGrams,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      bodyStressLevel: bodyStressLevel ?? this.bodyStressLevel,
      notes: notes ?? this.notes,
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'phase': phase,
      'energyLevel': energyLevel,
      'sleepQualityIndex': sleepQualityIndex,
      'exercise': exercise,
      'emotion': emotion,
      'symptoms': symptoms,
      'nutrition': nutrition,
      'fiberGrams': fiberGrams,
      'proteinGrams': proteinGrams,
      'bodyStressLevel': bodyStressLevel,
      'notes': notes,
    };
  }

  // Create from Map for retrieval
  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      date: DateTime.parse(map['date']),
      phase: map['phase'],
      energyLevel: map['energyLevel'],
      sleepQualityIndex: map['sleepQualityIndex'],
      exercise: map['exercise'] ?? '',
      emotion: map['emotion'] ?? '',
      symptoms: map['symptoms'] ?? '',
      nutrition: map['nutrition'] ?? '',
      fiberGrams: map['fiberGrams']?.toDouble(),
      proteinGrams: map['proteinGrams']?.toDouble(),
      bodyStressLevel: map['bodyStressLevel']?.toDouble(),
      notes: map['notes'] ?? '',
    );
  }
} 