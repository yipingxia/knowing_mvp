import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/openai_service.dart';
import '../models/recommendation.dart';
import '../widgets/tarot_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
  bool _isLoading = false;
  bool _isEditing = true;
  Recommendation? _recommendation;
  late TabController _tabController;
  final PageController _pageController = PageController();
  final ScrollController _pillScrollController = ScrollController();
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1000));
    
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
    final screenWidth = MediaQuery.of(context).size.width;
    final scrollTo = (index * 120.0) - (screenWidth / 2) + 60.0;
    _pillScrollController.animateTo(
      scrollTo.clamp(0, _pillScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
    if (_recommendation == null) return const SizedBox.shrink();

    // Define the order of cards
    final cardOrder = [
      'symptoms_management',
      'exercise',
      'nutrition',
      'relationship',
      'emotional_wellbeing',
      'stress_management',
      'tell_partner',
    ];

    // Sort the recommendations based on our order
    final sortedRecommendations = Map.fromEntries(
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
                  setState(() {
                    _tabController.animateTo(index);
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    _scrollPillIntoView(index);
                  });
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
          height: 400,
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
              height: 400,
              decoration: _shimmerGradient.copyWith(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        );
      },
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
                // Today's Log
                _buildInfoCard(
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Today's Log", style: titleStyle),
                          if (!_isEditing)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isEditing = true;
                                });
                              },
                              icon: const Icon(Icons.edit, color: secondaryColor, size: 20),
                              label: Text(
                                'Edit',
                                style: subtitleStyle.copyWith(color: secondaryColor),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _isEditing
                        ? TextField(
                            controller: _journalController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: 'Share your mood, symptoms, food intake, sleep quality, stress levels...',
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
                          )
                        : Text(_journalController.text, style: subtitleStyle),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Last Period Date
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

                const SizedBox(height: 16),

                // Submit Button
                if (_isEditing)
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
                        ? const SizedBox(
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

                if (_recommendation != null || _isLoading) ...[
                  const SizedBox(height: 24),
                  
                  if (_isLoading)
                    _buildLoadingSkeleton()
                  else
                    // Your existing recommendation content
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Keep the Tarot cards section colorful
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

    if (_journalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your journal entry')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isEditing = false;  // Immediately switch to view mode
    });

    try {
      final response = await _openAIService.getRecommendations(
        journalEntry: _journalController.text,
        lastPeriodDate: _lastPeriodDate!,
      );

      if (response.containsKey('error')) {
        throw Exception(response['error']);
      }

      setState(() {
        _recommendation = Recommendation.fromJson(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isEditing = true;  // Return to edit mode on error
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
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