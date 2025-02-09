import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TarotCard extends StatelessWidget {
  static const Color primaryColor = Color(0xFF2C2C2C);
  static const Color secondaryColor = Color(0xFF4A4A4A);
  static const Color surfaceColor = Color(0xFFF5F5F5);
  static const Color borderColor = Color(0xFFE0E0E0);

  final String title;
  final List<String> recommendations;
  final double rotationAngle;

  const TarotCard({
    super.key,
    required this.title,
    required this.recommendations,
    this.rotationAngle = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotationAngle,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: borderColor,
            width: 2,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                surfaceColor,
                Colors.white,
                surfaceColor,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Decorative border at the top
                Center(
                  child: Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: secondaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Title with decorative elements
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: secondaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.unna(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, color: secondaryColor),
                  ],
                ),
                const SizedBox(height: 20),
                // Recommendations
                Expanded(
                  child: ListView(
                    children: recommendations.map((recommendation) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: secondaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                recommendation,
                                style: GoogleFonts.unna(
                                  fontSize: 18,
                                  color: primaryColor,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Decorative border at the bottom
                Center(
                  child: Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: secondaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 