import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const SplashScreen({super.key, required this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'badge': 'REAL-TIME GPS TELEMATICS',
      'title': 'Live Kerala Bus Tracking',
      'malayalamTitle': 'തത്സമയ ബസ് ട്രാക്കിംഗും സമയക്രമവും',
      'description':
          'Track Kerala stage carriage buses live on interactive maps. View accurate arrival times, current stage progress, and stop schedules before leaving home.',
      'icon': Icons.directions_bus_rounded,
      'accentColor': AppTheme.primaryGreen,
      'tags': ['Live GPS Map', 'Stop Schedules', 'Arrival ETAs'],
    },
    {
      'badge': 'CASHLESS CONTACTLESS TRAVEL',
      'title': 'Instant QR & Smart Wallet',
      'malayalamTitle': 'വേഗത്തിലുള്ള ക്യുആർ ടിക്കറ്റിംഗും വാലറ്റും',
      'description':
          'Board buses without the hassle of physical change. Present your secure dynamic passenger QR code, manage your digital wallet, and avail student concessions as per Kerala Stage Carriage fare notifications.',
      'icon': Icons.qr_code_scanner_rounded,
      'accentColor': const Color(0xFF3B82F6),
      'tags': ['Passenger QR', 'Digital Wallet', 'Concessions'],
    },
    {
      'badge': 'ALL-IN-ONE PUBLIC TRANSIT',
      'title': 'Unified Transit Ecosystem',
      'malayalamTitle': 'യാത്രക്കാർക്കും കണ്ടക്ടർമാർക്കും ബസ്സുടമകൾക്കും',
      'description':
          'One single platform seamlessly connecting Passengers, Conductors, and Fleet Owners. Experience digital ticketing, live stop-to-stop fare management, and fleet collection ledgers.',
      'icon': Icons.hub_rounded,
      'accentColor': AppTheme.accentAmber,
      'tags': ['Unified 3-in-1', 'Fare Chart Editor', 'Fleet Ledger'],
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      widget.onFinish();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060E18),
      body: SafeArea(
        child: Column(
          children: [
            // ---------------------------------------------------------------
            // 1. TOP HEADER (BRAND & SKIP BUTTON)
            // ---------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Image.asset(
                                'web/icons/Icon-192.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.directions_bus,
                                  color: AppTheme.primaryGreen,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'EnRoute',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Text(
                                'സ്മാർട്ട് കേരള ബസ്സ് സർവീസ് & ടിക്കറ്റിംഗ്',
                                style: TextStyle(
                                  color: AppTheme.accentAmber.withValues(alpha: 0.9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: widget.onFinish,
                    label: const Text(
                      'Skip',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    icon: const Icon(Icons.arrow_forward_ios, size: 12),
                  ),
                ],
              ),
            ),

            // ---------------------------------------------------------------
            // 2. INTERACTIVE SLIDES CAROUSEL (PAGEVIEW)
            // ---------------------------------------------------------------
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) {
                  setState(() {
                    _currentPage = idx;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  final accent = slide['accentColor'] as Color;
                  final tags = slide['tags'] as List<String>;

                  return Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Glowing Illustrated Hero Circle
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      accent.withValues(alpha: 0.25),
                                      accent.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF131E2E),
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.5),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.35),
                                      blurRadius: 24,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  slide['icon'] as IconData,
                                  size: 44,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Slide Pill Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: accent.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              slide['badge'] as String,
                              style: TextStyle(
                                color: accent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Main Slide Title
                          Text(
                            slide['title'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 5),

                          // Malayalam Subtitle
                          Text(
                            slide['malayalamTitle'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.accentAmber.withValues(alpha: 0.95),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Description
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              slide['description'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                                height: 1.45,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Highlight Feature Tags
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: tags.map((t) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 11, color: accent),
                                    const SizedBox(width: 4),
                                    Text(
                                      t,
                                      style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ---------------------------------------------------------------
            // 3. BOTTOM CAROUSEL CONTROLS & INDICATOR DOTS
            // ---------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                children: [
                  // Smooth Animated Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.primaryGreen : Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Navigation Action Row
                  if (_currentPage < _slides.length - 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentPage > 0)
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _prevPage,
                            child: const Text('Back'),
                          )
                        else
                          const SizedBox(width: 80),

                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                          onPressed: _nextPage,
                          label: const Text(
                            'Next',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          icon: const Icon(Icons.arrow_forward, size: 16),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 6,
                          shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.5),
                        ),
                        onPressed: widget.onFinish,
                        icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                        label: const Text(
                          'Get Started • ആരംഭിക്കുക',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ---------------------------------------------------------------
            // 4. CREATOR CREDITS FOOTER
            // ---------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Opacity(
                opacity: 0.45,
                child: Column(
                  children: const [
                    Text(
                      'Created by Sahl Saleem & Fathima Riyas',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'v2.1.0 • Kerala Stage Carriage Network',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Colors.white70,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
