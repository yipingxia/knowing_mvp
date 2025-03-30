import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../services/openai_service.dart';
import '../services/daily_log_service.dart';
import '../models/recommendation.dart';
import '../models/journal_entry.dart';
import '../widgets/glass_card.dart';
import '../screens/interactive_input.dart';
import 'journal_entries_list.dart';
import '../services/recommendations_service.dart';
import '../services/user_service.dart';
import 'login_screen.dart';
import 'package:flutter/rendering.dart';
import 'user_info_screen.dart';
import '../services/user_info_service.dart';
import '../models/user_info.dart';
import '../theme/app_theme.dart';

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
  int _currentPage = 0;
  final UserInfoService _userInfoService = UserInfoService(FirebaseFirestore.instance);
  UserInfo? _userInfo;

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

    // Load user info
    _loadUserInfo();
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

  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await _userInfoService.getUserInfo();
      if (mounted) {
        setState(() {
          _userInfo = userInfo;
        });
      }
    } catch (e) {
      print('Error loading user info: $e');
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
          text: TextSpan(text: title, style: AppTheme.pillTextStyle),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();
        pillPosition += textWidth.width + 32 + 8; // 32 for padding, 8 for margins
      }

      // Add half of the current pill's width
      final currentTitle = sortedRecommendations.keys.toList()[index].replaceAll('_', ' ').toUpperCase();
      final currentTextWidth = TextPainter(
        text: TextSpan(text: currentTitle, style: AppTheme.pillTextStyle),
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
    if (_recommendation == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppTheme.spacingMedium),
        // Grid of recommendation cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.0,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
          children: sortedRecommendations.entries.map((entry) {
            final title = entry.key.replaceAll('_', ' ').toUpperCase();
            return GlassCard(
              title: title,
              recommendations: entry.value,
              rotationAngle: 0,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    String? title,
    required Widget content,
  }) {
    return Container(
      decoration: AppTheme.glassCardDecoration,
      child: Padding(
        padding: AppTheme.glassCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title, style: AppTheme.titleStyle),
              const SizedBox(height: AppTheme.spacingMedium),
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
        AppTheme.surfaceColor,
        Colors.white,
        AppTheme.surfaceColor,
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
                  const SizedBox(height: AppTheme.spacingMedium),
                  Container(
                    width: 200,
                    height: 32,
                    decoration: _shimmerGradient,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingXLarge),

            // Pills Skeleton
            Container(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSmall),
                    decoration: _shimmerGradient.copyWith(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),

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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Center(
          child: ConstrainedBox(
            constraints: AppTheme.maxWidthConstraint,
            child: Text(
              'Get Knowing',
              style: AppTheme.appBarTitleStyle,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserInfoScreen(),
                ),
              );
            },
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.add_chart),
            onPressed: _navigateToJournalEntries,
            tooltip: 'Journal Entries',
          ),
        ],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppTheme.backgroundGradientColors,
            stops: const [0.0, 0.4, 0.8, 1.0],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: AppTheme.maxWidthConstraint,
            child: SingleChildScrollView(
              padding: AppTheme.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isEditing)
                    _buildInputFields()
                  else
                    _buildTodaySummaryTile(),

                  if (_isEditing) ...[
                    const SizedBox(height: AppTheme.spacingMedium),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: AppTheme.elevatedButtonStyle,
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
                              style: AppTheme.cardTitleStyle,
                            ),
                      ),
                    ),
                  ],

                  if (_recommendation != null || _isLoading) ...[
                    const SizedBox(height: AppTheme.spacingLarge),
                    
                    if (_isLoading)
                      _buildLoadingSkeleton()
                    else
                      Center(
                        child: Column(
                          children: [
                            Text(
                              "YOUR MESSAGE TODAY",
                              style: AppTheme.phaseHeaderStyle,
                            ),
                            const SizedBox(height: AppTheme.spacingSmall),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: AppTheme.primaryColor.withOpacity(0.1), width: 1),
                                    bottom: BorderSide(color: AppTheme.primaryColor.withOpacity(0.1), width: 1),
                                  ),
                                ),
                                child: Text(
                                  _recommendation!.poeticMessage,
                                  style: AppTheme.poeticMessageStyle,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: AppTheme.spacingXLarge),

                    _buildRecommendationsSection(),
                  ],
                ],
              ),
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
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: AppTheme.glassCardDecoration,
          child: Padding(
            padding: AppTheme.glassCardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Your day",
                      style: AppTheme.cardTitleStyle,
                    ),
                    TextButton.icon(
                      onPressed: _handleEditTap,
                      icon: const Icon(Icons.edit, color: AppTheme.secondaryColor, size: 20),
                      label: Text(
                        'Edit',
                        style: AppTheme.tagValueStyle,
                      ),
                    ),
                  ],
                ),
                if (_todayEntry!.notes.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingMedium),
                  Text(
                    _todayEntry!.notes,
                    style: AppTheme.cardBodyStyle,
                  ),
                ],
                if (_todayEntry!.energyLevel > 0 || _todayEntry!.sleepQualityIndex > 0 || 
                    _todayEntry!.nutrition.isNotEmpty || _todayEntry!.exercise.isNotEmpty || 
                    _todayEntry!.emotion.isNotEmpty || _todayEntry!.symptoms.isNotEmpty ||
                    _todayEntry!.stressors.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingMedium),
                  Wrap(
                    spacing: AppTheme.spacingSmall,
                    runSpacing: AppTheme.spacingSmall,
                    children: [
                      if (_todayEntry!.energyLevel > 0)
                        _buildTag('Energy', '${_todayEntry!.energyLevel.round()}%'),
                      if (_todayEntry!.sleepQualityIndex > 0)
                        _buildTag('Sleep', _getSleepQualityText(_todayEntry!.sleepQualityIndex), entry: _todayEntry),
                      if (_todayEntry!.nutrition.isNotEmpty)
                        _buildTag('Nutrition', _todayEntry!.nutrition, entry: _todayEntry),
                      if (_todayEntry!.exercise.isNotEmpty)
                        _buildTag('Exercise', _todayEntry!.exercise, entry: _todayEntry),
                      if (_todayEntry!.emotion.isNotEmpty)
                        _buildTag('Emotion', _todayEntry!.emotion),
                      if (_todayEntry!.symptoms.isNotEmpty)
                        _buildTag('Symptoms', _todayEntry!.symptoms),
                      if (_todayEntry!.stressors.isNotEmpty)
                        _buildTag('Stressors', '${_todayEntry!.stressors.length} selected'),
                      if (_recommendation != null)
                        _buildTag('Phase', _recommendation!.currentPhase.toUpperCase()),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  String _getSleepQualityText(int index) {
    final qualities = ['Poor', 'Barely', 'Fair', 'Good', 'Great'];
    return qualities[index];
  }
  
  // Add this method to build input fields
  Widget _buildInputFields() {
    return Column(
      children: [
        _buildInfoCard(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's Log", style: AppTheme.titleStyle),
              const SizedBox(height: AppTheme.spacingMedium),
              TextField(
                controller: _journalController,
                maxLines: 5,
                decoration: AppTheme.textFieldDecoration.copyWith(
                  hintText: 'How are you today?',
                  hintStyle: AppTheme.subtitleStyle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        _buildInfoCard(
          title: 'Last Period Start Date',
          content: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _lastPeriodDate != null
                  ? '${_lastPeriodDate!.day}/${_lastPeriodDate!.month}/${_lastPeriodDate!.year}'
                  : 'Not set',
              style: AppTheme.subtitleStyle,
            ),
            trailing: const Icon(Icons.calendar_today, color: AppTheme.secondaryColor),
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
                        primary: AppTheme.primaryColor,
                        onPrimary: Colors.white,
                        surface: AppTheme.surfaceColor,
                        onSurface: AppTheme.primaryColor,
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

  // Add this helper function
  Color _getStatusColor({
    required double? currentValue,
    required double? recommendedValue,
    required bool isExerciseStress,
  }) {
    if (currentValue == null || recommendedValue == null) return AppTheme.statusRed;
    
    if (isExerciseStress) {
      // For exercise stress, lower is better
      if (currentValue <= 6) return AppTheme.statusBlue;
      if (currentValue <= 8) return AppTheme.statusYellow;
      return AppTheme.statusRed;
    } else {
      // For fiber and protein, higher is better
      final percentage = (currentValue / recommendedValue) * 100;
      if (percentage >= 100) return AppTheme.statusGreen;
      if (percentage >= 80) return AppTheme.statusBlue;
      return AppTheme.statusRed;
    }
  }

  Color _getSleepQualityColor(int index) {
    switch (index) {
      case 0: return AppTheme.statusRed;    // Poor
      case 1: return AppTheme.statusYellow; // Barely
      case 2: return AppTheme.statusBlue;   // Fair
      case 3: return AppTheme.statusGreen;  // Good
      case 4: return AppTheme.statusGreen;  // Great
      default: return AppTheme.statusRed;
    }
  }

  // Add this widget class before _buildTag
  Widget _buildStatusIndicator(Color color) {
    return Text(
      ' ●',
      style: TextStyle(
        color: color,
        fontSize: 14,
      ),
    );
  }

  Widget _buildTag(String label, String value, {JournalEntry? entry}) {
    List<Widget> children = [];

    if (label == 'Nutrition' && entry != null) {
      if (entry.fiberGrams != null || entry.proteinGrams != null) {
        final fiberColor = _getStatusColor(
          currentValue: entry.fiberGrams,
          recommendedValue: _userInfo?.recommendedFiberIntake,
          isExerciseStress: false,
        );
        final proteinColor = _getStatusColor(
          currentValue: entry.proteinGrams,
          recommendedValue: _userInfo?.recommendedProteinIntake,
          isExerciseStress: false,
        );
        
        children = [
          Text(
            '$label: ',
            style: AppTheme.tagLabelStyle,
          ),
          Text(
            'Fiber: ${entry.fiberGrams?.toStringAsFixed(1) ?? '0'}g',
            style: AppTheme.tagValueStyle,
          ),
          _buildStatusIndicator(fiberColor),
          Text(
            ', Protein: ${entry.proteinGrams?.toStringAsFixed(1) ?? '0'}g',
            style: AppTheme.tagValueStyle,
          ),
          _buildStatusIndicator(proteinColor),
        ];
      }
    } else if (label == 'Exercise' && entry?.bodyStressLevel != null) {
      final stressColor = _getStatusColor(
        currentValue: entry!.bodyStressLevel,
        recommendedValue: 6,
        isExerciseStress: true,
      );
      children = [
        Text(
          '$label: ',
          style: AppTheme.tagLabelStyle,
        ),
        Text(
          'Stress: ${entry.bodyStressLevel!.toStringAsFixed(1)}/10',
          style: AppTheme.tagValueStyle,
        ),
        _buildStatusIndicator(stressColor),
      ];
    } else if (label == 'Sleep' && entry != null) {
      final sleepColor = _getSleepQualityColor(entry.sleepQualityIndex);
      children = [
        Text(
          '$label: ',
          style: AppTheme.tagLabelStyle,
        ),
        Text(
          value,
          style: AppTheme.tagValueStyle,
        ),
        _buildStatusIndicator(sleepColor),
      ];
    } else {
      children = [
        Text(
          '$label: ',
          style: AppTheme.tagLabelStyle,
        ),
        Text(
          value,
          style: AppTheme.tagValueStyle,
        ),
      ];
    }

    return Container(
      padding: AppTheme.tagPadding,
      decoration: AppTheme.tagDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
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