import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/openai_service.dart';
import '../services/daily_log_service.dart';
import '../models/recommendation.dart';
import '../models/journal_entry.dart';
import '../widgets/tarot_card.dart';
import '../screens/interactive_input.dart';
import 'journal_entries_list.dart';
import '../services/recommendations_service.dart';
import '../services/user_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({
    super.key, 
    required this.username,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Color scheme
  static const Color primaryColor = Color(0xFF2C2C2C);
  static const Color secondaryColor = Color(0xFF4A4A4A);
  static const Color surfaceColor = Color(0xFFF5F5F5);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF2C2C2C);
  static const Color subtitleColor = Color(0xFF757575);

  // Update text styles with Unna font
  TextStyle get titleStyle => GoogleFonts.unna(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryColor,
    letterSpacing: 0.15,
  );

  TextStyle get subtitleStyle => GoogleFonts.unna(
    fontSize: 18,
    color: subtitleColor,
    letterSpacing: 0.15,
  );

  TextStyle get phaseHeaderStyle => GoogleFonts.unna(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: subtitleColor,
    letterSpacing: 1.5,
  );

  TextStyle get phaseTextStyle => GoogleFonts.unna(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: primaryColor,
    letterSpacing: 0.5,
  );

  TextStyle get pillTextStyle => GoogleFonts.unna(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static final cardDecoration = BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  final TextEditingController _journalController = TextEditingController();
  DateTime? _lastPeriodDate;
  final OpenAIService _openAIService = OpenAIService();
  final DailyLogService _dailyLogService;
  final RecommendationsService _recommendationsService;
  bool _isLoading = false;
  bool _isEditing = true;
  Recommendation? _recommendation;
  late TabController _tabController;
  final PageController _pageController = PageController();
  final ScrollController _pillScrollController = ScrollController();
  late AnimationController _shimmerController;
  late Map<String, List<String>> sortedRecommendations = {};
  JournalEntry? _todayEntry;
  late final UserService _userService;

  _HomeScreenState()
      : _dailyLogService = DailyLogService(FirebaseFirestore.instance),
        _recommendationsService = RecommendationsService(FirebaseFirestore.instance);

  @override
  void initState() {
    super.initState();
    _userService = UserService();
    _tabController = TabController(length: 7, vsync: this);
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1000));
    
    // Initialize sortedRecommendations
    final cardOrder = [
      'symptoms_management',
      'exercise',
      'nutrition',
      'relationship',
      'emotional_wellbeing',
      'stress_management',
      'tell_partner',
    ];
    sortedRecommendations = Map.fromEntries(
      cardOrder.map((key) => MapEntry(key, [])),
    );

    // Sync TabBar with PageView
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    // Load today's data
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    try {
      print('Starting to load today\'s data...');
      // Load recommendations for today first
      final today = DateTime.now();
      print('Fetching recommendations for: ${today.toIso8601String()}');
      
      // Use watchRecommendations instead of getRecommendations for real-time updates
      _recommendationsService.watchRecommendations(today).listen(
        (recommendations) {
          print('Recommendations loaded: ${recommendations != null ? 'yes' : 'no'}');
          if (recommendations != null) {
            print('Raw recommendations data: ${recommendations.toMap()}');
            print('Current phase: ${recommendations.currentPhase}');
            print('Poetic message: ${recommendations.poeticMessage}');
            print('Recommendations map: ${recommendations.recommendations}');
            if (mounted) {
              setState(() {
                _recommendation = recommendations;
                // Update sortedRecommendations if needed
                if (_recommendation != null) {
                  final cardOrder = [
                    'exercise',
                    'nutrition',
                    'relationship',
                    'emotional_wellbeing',
                    'stress_management',
                    'symptoms_management',
                    'tell_partner',
                  ];
                  print('Updating sorted recommendations with card order: $cardOrder');
                  sortedRecommendations = Map.fromEntries(
                    cardOrder.map((key) {
                      final value = _recommendation!.recommendations[key] ?? [];
                      print('Category $key has ${value.length} recommendations');
                      return MapEntry(key, value);
                    }),
                  );
                  print('Final sorted recommendations: $sortedRecommendations');
                }
              });
            }
          }
        },
        onError: (error) {
          print('Error watching recommendations: $error');
        },
      );

      // Then load today's log
      print('Fetching today\'s log...');
      final todayLog = await _dailyLogService.getTodayLog();
      print('Today\'s log loaded: ${todayLog != null ? 'yes' : 'no'}');
      if (todayLog != null) {
        print('Log content - notes: ${todayLog.notes}, nutrition: ${todayLog.nutrition}, exercise: ${todayLog.exercise}');
      }
      if (todayLog != null && mounted) {
        setState(() {
          _lastPeriodDate = todayLog.lastPeriodDate;
          _journalController.text = todayLog.notes;
          _isEditing = false;  // Set to false since we have data
          _todayEntry = todayLog;  // Store the entry
        });
      } else if (mounted) {
        setState(() {
          _isEditing = true;  // Set to true since we need input
          _todayEntry = null;
        });
      }
    } catch (e, stackTrace) {
      print('Error loading today\'s data: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading today\'s data: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pillScrollController.dispose();
    _tabController.dispose();
    _pageController.dispose();
    _journalController.dispose();
    super.dispose();
  }

  void _scrollPillIntoView(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      double pillPosition = 0;
      
      // Calculate position by summing widths of previous pills
      for (int i = 0; i < index; i++) {
        final String title = sortedRecommendations.keys.toList()[i].replaceAll('_', ' ').toUpperCase();
        // Estimate width: text width + horizontal padding + margins
        final textWidth = TextPainter(
          text: TextSpan(text: title, style: pillTextStyle),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();
        pillPosition += textWidth.width + 32 + 8; // 32 for padding, 8 for margins
      }

      // Add half of the current pill's width
      final currentTitle = sortedRecommendations.keys.toList()[index].replaceAll('_', ' ').toUpperCase();
      final currentTextWidth = TextPainter(
        text: TextSpan(text: currentTitle, style: pillTextStyle),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      pillPosition += (currentTextWidth.width + 32 + 8) / 2;

      // Center the pill
      final scrollTo = pillPosition - (screenWidth / 2);
      
      _pillScrollController.animateTo(
        scrollTo.clamp(0, _pillScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  Widget _buildRecommendationCard(MapEntry<String, List<String>> entry) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.key.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...entry.value.map(
              (recommendation) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(recommendation)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    if (_recommendation == null) return SizedBox.shrink();

    // Define the order of cards
    final cardOrder = [
      'exercise',
      'nutrition',
      'relationship',
      'emotional_wellbeing',
      'stress_management',
      'symptoms_management',
      'tell_partner',
    ];

    // Update sortedRecommendations with new data
    sortedRecommendations = Map.fromEntries(
      cardOrder.map((key) => MapEntry(
        key, 
        _recommendation!.recommendations[key] ?? [],
      )),
    );

    return Column(
      children: [
        const SizedBox(height: 16),
        // Pill-style Tab Bar
        Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: ListView(
            controller: _pillScrollController,
            scrollDirection: Axis.horizontal,
            children: sortedRecommendations.keys.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final title = entry.value.replaceAll('_', ' ').toUpperCase();
              final isSelected = _tabController.index == index;
              
              return GestureDetector(
                onTap: () {
                  if (index < sortedRecommendations.length) {
                    _tabController.animateTo(index);
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    _scrollPillIntoView(index);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? primaryColor : borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: pillTextStyle.copyWith(
                            color: isSelected ? Colors.white : secondaryColor,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        if (title == 'TELL PARTNER') ...[
                          const SizedBox(width: 4),
                          ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(
                                colors: [
                                  Colors.amber.shade300,
                                  Colors.amber.shade100,
                                  Colors.amber.shade300,
                                ],
                                stops: const [0.2, 0.5, 0.8],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds);
                            },
                            child: Icon(
                              Icons.star,
                              size: 14,
                              color: isSelected ? Colors.white : Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Swipeable Cards
        SizedBox(
          height: 500,
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                // Swipe right - go to previous
                if (_tabController.index > 0) {
                  _tabController.animateTo(_tabController.index - 1);
                }
              } else if (details.primaryVelocity! < 0) {
                // Swipe left - go to next
                if (_tabController.index < _tabController.length - 1) {
                  _tabController.animateTo(_tabController.index + 1);
                }
              }
            },
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _tabController.animateTo(index);
                  _scrollPillIntoView(index);
                });
              },
              children: sortedRecommendations.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 24.0,
                  ),
                  child: TarotCard(
                    title: entry.key.replaceAll('_', ' '),
                    recommendations: entry.value,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    String? title,
    required Widget content,
  }) {
    return Container(
      decoration: cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title, style: titleStyle),
              const SizedBox(height: 12),
            ],
            content,
          ],
        ),
      ),
    );
  }

  BoxDecoration get _shimmerGradient => BoxDecoration(
    gradient: LinearGradient(
      colors: [
        surfaceColor,
        Colors.white,
        surfaceColor,
      ],
      stops: const [0.1, 0.3, 0.4],
      begin: const Alignment(-1.0, -0.3),
      end: const Alignment(1.0, 0.3),
      transform: _SlidingGradientTransform(_shimmerController.value),
    ),
    borderRadius: BorderRadius.circular(8),
  );

  Widget _buildLoadingSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Column(
          children: [
            // Phase Skeleton
            Center(
              child: Column(
                children: [
                  Container(
                    width: 150,
                    height: 16,
                    decoration: _shimmerGradient,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 200,
                    height: 32,
                    decoration: _shimmerGradient,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Pills Skeleton
            Container(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: _shimmerGradient.copyWith(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Card Skeleton
            Container(
              height: 500,
              decoration: _shimmerGradient.copyWith(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToJournalEntries() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const JournalEntriesListScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(
              'Daily Lifestyle Logs',
              style: GoogleFonts.unna(
                color: primaryColor,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart),
            onPressed: _navigateToJournalEntries,
            tooltip: 'Journal Entries',
          ),
        ],
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show either summary tile or input fields
                if (_isEditing)
                  _buildInputFields()
                else
                  _buildTodaySummaryTile(),

                // Submit Button
                if (_isEditing) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _submitEntry,
                      child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Submit Entry',
                            style: GoogleFonts.unna(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                    ),
                  ),
                ],

                if (_recommendation != null || _isLoading) ...[
                  const SizedBox(height: 24),
                  
                  if (_isLoading)
                    _buildLoadingSkeleton()
                  else
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'CURRENT PHASE (estimated)',
                            style: phaseHeaderStyle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _recommendation!.currentPhase.toUpperCase(),
                            style: phaseTextStyle,
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: primaryColor.withOpacity(0.1), width: 1),
                                  bottom: BorderSide(color: primaryColor.withOpacity(0.1), width: 1),
                                ),
                              ),
                              child: Text(
                                _recommendation!.poeticMessage,
                                style: GoogleFonts.unna(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: primaryColor,
                                  height: 1.6,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    _buildRecommendationsSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitEntry() async {
    if (_lastPeriodDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your last period date')),
      );
      return;
    }

    if (_journalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text in your journal')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      
      // Create initial journal entry
      final initialEntry = JournalEntry(
        date: now,
        notes: _journalController.text,
        lastPeriodDate: _lastPeriodDate,
      );

      // Save to daily logs
      await _dailyLogService.saveLog(initialEntry);

      // Start getting recommendations in the background without awaiting
      _openAIService.getRecommendations(
        journalEntry: _journalController.text,
        lastPeriodDate: _lastPeriodDate!,
      ).then((recommendationsData) async {
        try {
          print('Received recommendations data: $recommendationsData');
          
          // Create a Recommendation object from the OpenAI response
          final recommendation = Recommendation(
            date: now,
            currentPhase: recommendationsData['current_phase'] ?? 'Unknown',
            daysSinceLastPeriod: recommendationsData['days_since_last_period'] ?? now.difference(_lastPeriodDate!).inDays,
            keywords: (recommendationsData['keywords'] as List<dynamic>?)?.cast<String>() ?? ['health', 'wellness'],
            poeticMessage: recommendationsData['poetic_message'] ?? '',
            recommendations: Map<String, List<String>>.from(
              (recommendationsData['recommendations'] as Map<String, dynamic>? ?? {}).map(
                (key, value) => MapEntry(key, (value as List<dynamic>).cast<String>())
              )
            ),
          );
          
          print('Saving recommendation: ${recommendation.toMap()}');
          
          // Save the recommendation to Firestore
          await _recommendationsService.saveRecommendation(recommendation);
          
          // After recommendations are saved, reload today's data
          if (mounted) {
            _loadTodayData();
          }
        } catch (e, stackTrace) {
          print('Error saving recommendations: $e');
          print('Stack trace: $stackTrace');
        }
      }).catchError((e) {
        print('Error getting recommendations: $e');
        // Don't show error to user since this is background processing
      });

      // Navigate to interactive input screen immediately
      if (!mounted) return;
      final result = await Navigator.push<JournalEntry>(
        context,
        MaterialPageRoute(
          builder: (context) => InteractiveInputScreen(
            selectedDate: now,
            initialEntry: initialEntry,
          ),
        ),
      );

      // Update the state with the returned entry
      if (result != null && mounted) {
        setState(() {
          _todayEntry = result;
          _isEditing = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error submitting entry: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting entry: $e')),
      );
    }
  }

  // Add this method to handle the edit button tap
  Future<void> _handleEditTap() async {
    if (_todayEntry == null) return;
    
    final result = await Navigator.push<JournalEntry>(
      context,
      MaterialPageRoute(
        builder: (context) => InteractiveInputScreen(
          selectedDate: DateTime.now(),
          initialEntry: _todayEntry,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _todayEntry = result;
        _isEditing = false;
      });
      // Reload today's data to get fresh recommendations
      _loadTodayData();
    }
  }

  // Update the summary tile to use the new edit handler
  Widget _buildTodaySummaryTile() {
    if (_todayEntry == null) return SizedBox.shrink();
    
    return Container(
      decoration: cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Summary",
                  style: GoogleFonts.unna(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: secondaryColor,
                  ),
                ),
                TextButton.icon(
                  onPressed: _handleEditTap,
                  icon: const Icon(Icons.edit, color: secondaryColor, size: 20),
                  label: Text(
                    'Edit',
                    style: subtitleStyle.copyWith(color: secondaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_todayEntry!.notes.isNotEmpty)
              Text(
                _todayEntry!.notes,
              ),
            if (_todayEntry!.nutrition.isNotEmpty || _todayEntry!.exercise.isNotEmpty || 
                _todayEntry!.emotion.isNotEmpty || _todayEntry!.symptoms.isNotEmpty) ...[
              const Divider(height: 1),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_todayEntry!.nutrition.isNotEmpty)
                    _buildTag('Nutrition', _todayEntry!.nutrition, entry: _todayEntry),
                  if (_todayEntry!.exercise.isNotEmpty)
                    _buildTag('Exercise', _todayEntry!.exercise, entry: _todayEntry),
                  if (_todayEntry!.emotion.isNotEmpty)
                    _buildTag('Emotion', _todayEntry!.emotion),
                  if (_todayEntry!.symptoms.isNotEmpty)
                    _buildTag('Symptoms', _todayEntry!.symptoms),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // Add this method to build input fields
  Widget _buildInputFields() {
    return Column(
      children: [
        _buildInfoCard(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's Log", style: titleStyle),
              const SizedBox(height: 12),
              TextField(
                controller: _journalController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'How are you today?',
                  hintStyle: subtitleStyle,
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'Last Period Start Date',
          content: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _lastPeriodDate != null
                  ? '${_lastPeriodDate!.day}/${_lastPeriodDate!.month}/${_lastPeriodDate!.year}'
                  : 'Not set',
              style: subtitleStyle,
            ),
            trailing: const Icon(Icons.calendar_today, color: secondaryColor),
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _lastPeriodDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: primaryColor,
                        onPrimary: Colors.white,
                        surface: surfaceColor,
                        onSurface: primaryColor,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _lastPeriodDate = picked;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  // Add the _buildTag method
  Widget _buildTag(String label, String value, {JournalEntry? entry}) {
    // For nutrition tag, show fiber and protein content
    String displayValue = value;
    if (label == 'Nutrition' && entry != null) {
      if (entry.fiberGrams != null || entry.proteinGrams != null) {
        displayValue = 'Fiber: ${entry.fiberGrams?.toStringAsFixed(1) ?? '0'}g, '
                      'Protein: ${entry.proteinGrams?.toStringAsFixed(1) ?? '0'}g';
      }
    }
    // For exercise tag, show body stress level if available
    if (label == 'Exercise' && entry?.bodyStressLevel != null) {
      displayValue = '$value (Stress: ${entry!.bodyStressLevel!.toStringAsFixed(1)}/10)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            displayValue,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    _userService.clearUsernameFromStorage();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
} 