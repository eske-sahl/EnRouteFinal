import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService extends ChangeNotifier {
  static final AppSettingsService instance = AppSettingsService._();
  AppSettingsService._();

  ThemeMode _themeMode = ThemeMode.light;
  String _language = 'en'; // 'en' or 'ml'
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get language => _language;
  bool get isMalayalam => _language == 'ml';
  String get languageDisplayName => _language == 'ml' ? 'മലയാളം (Malayalam)' : 'English';

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('enroute_theme_mode');
      if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }

      final savedLang = prefs.getString('enroute_language');
      if (savedLang == 'ml') {
        _language = 'ml';
      } else {
        _language = 'en';
      }
    } catch (_) {}
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('enroute_theme_mode', _themeMode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('enroute_language', lang);
    } catch (_) {}
  }

  Future<void> toggleLanguage() async {
    await setLanguage(_language == 'en' ? 'ml' : 'en');
  }

  // Translation lookup dictionary
  String t(String key) {
    if (_language == 'ml') {
      return _malayalamTranslations[key] ?? key;
    }
    return _englishTranslations[key] ?? key;
  }

  static const Map<String, String> _englishTranslations = {
    'appName': 'EnRoute',
    'appTagline': 'Smart Kerala Transit & Live Ticketing',
    'findBus': 'Find Your Bus',
    'searchPlaceholder': 'Search by stop, route, or bus name...',
    'walletBalance': 'Wallet Balance',
    'rechargeWallet': 'Recharge Wallet',
    'recentTrips': 'Recent Trips & Ledger',
    'startTrip': 'Start Trip & Broadcast GPS',
    'stopTrip': 'Stop / End Current Trip',
    'issueTicket': 'Issue Digital Ticket',
    'scanQr': 'Scan Passenger QR Code',
    'manualId': 'Manual Passenger ID',
    'fleetManagement': 'Fleet Management',
    'routesTimetable': 'Routes & Timetables',
    'conductors': 'Conductor Staff',
    'darkMode': 'Dark Mode',
    'lightMode': 'Light Mode',
    'theme': 'Theme Mode',
    'language': 'App Language',
    'shareApp': 'Share EnRoute App',
    'rateUs': 'Rate Us & Review',
    'reportIssue': 'Report an Issue',
    'suggestFeature': 'Suggest a Feature',
    'howToUse': 'How to Use This App',
    'creators': 'Created by Sahl Saleem & Fathima Riyas',
    'logout': 'Log Out',
    'currentStop': 'CURRENT STAGE / STOP',
    'nextStop': 'APPROACHING NEXT',
    'setManualStop': 'Set Current Stop Manually',
    'emergencySos': 'Emergency SOS Assistance (112)',
    'lostAndFound': 'Lost & Found Desk',
    'seatsAvailable': 'Seats Available',
    'standingAvailable': 'Standing Only',
    'heavilyCrowded': 'Crowded',
    'ruralFeeder': 'Rural Feeder / Gramavandi',
    'logExpense': 'Log Operating Expense',
  };

  static const Map<String, String> _malayalamTranslations = {
    'appName': 'എൻറൂട്ട് (EnRoute)',
    'appTagline': 'കേരള സ്മാർട്ട് ബസ്സ് സർവീസ് & ടിക്കറ്റിംഗ്',
    'findBus': 'ബസ്സ് കണ്ടെത്തുക',
    'searchPlaceholder': 'സ്റ്റോപ്പ്, റൂട്ട് അല്ലെങ്കിൽ ബസ്സിന്റെ പേര് തിരയുക...',
    'walletBalance': 'വാലറ്റ് ബാലൻസ്',
    'rechargeWallet': 'വാലറ്റ് റീചാർജ് ചെയ്യുക',
    'recentTrips': 'യാത്രാ ചരിത്രവും ഇടപാടുകളും',
    'startTrip': 'യാത്ര ആരംഭിച്ച് ലൈവ് GPS നൽകുക',
    'stopTrip': 'യാത്ര അവസാനിപ്പിക്കുക',
    'issueTicket': 'ഡിജിറ്റൽ ടിക്കറ്റ് നൽകുക',
    'scanQr': 'യാത്രക്കാരന്റെ QR കോഡ് സ്കാൻ ചെയ്യുക',
    'manualId': 'യാത്രക്കാരന്റെ ഐഡി ടൈപ്പ് ചെയ്യുക',
    'fleetManagement': 'ബസ്സ് മാനേജ്മെന്റ്',
    'routesTimetable': 'റൂട്ടുകളും സമയക്രമവും',
    'conductors': 'കണ്ടക്ടർ വിവരങ്ങൾ',
    'darkMode': 'ഡാർക്ക് മോഡ്',
    'lightMode': 'ലൈറ്റ് മോഡ്',
    'theme': 'തീം മോഡ്',
    'language': 'ഭാഷ മാറ്റുക',
    'shareApp': 'എൻറൂട്ട് ആപ്പ് സുഹൃത്തുക്കളുമായി പങ്കിടുക',
    'rateUs': 'ഞങ്ങളെ വിലയിരുത്തുക (Rate Us)',
    'reportIssue': 'പ്രശ്നങ്ങൾ അറിയിക്കുക (Report Bug)',
    'suggestFeature': 'പുതിയ ഫീച്ചറുകൾ നിർദ്ദേശിക്കുക',
    'howToUse': 'ആപ്പ് ഉപയോഗിക്കേണ്ട വിധം (ഗൈഡ്)',
    'creators': 'സാഹിൽ സലീം & ഫാത്തിമ റിയാസ് തയ്യാറാക്കിയത്',
    'logout': 'ലോഗ് ഔട്ട്',
    'currentStop': 'നിലവിലെ സ്റ്റോപ്പ്',
    'nextStop': 'അടുത്ത സ്റ്റോപ്പ്',
    'setManualStop': 'നിലവിലെ സ്റ്റോപ്പ് നേരിട്ട് സെറ്റ് ചെയ്യുക',
    'emergencySos': 'അടിയന്തര സഹായം (112)',
    'lostAndFound': 'നഷ്ടപ്പെട്ട സാധനങ്ങളുടെ ഡെസ്ക്',
    'seatsAvailable': 'സീറ്റുകൾ ലഭ്യമാണ്',
    'standingAvailable': 'നിൽക്കാൻ മാത്രം സ്ഥലം',
    'heavilyCrowded': 'കൂടുതൽ തിരക്ക്',
    'ruralFeeder': 'ഗ്രാമവണ്ടി / റൂറൽ ഫീഡർ',
    'logExpense': 'ചിലവുകൾ രേഖപ്പെടുത്തുക',
  };

  // ---------------------------------------------------------------------------
  // INTERACTIVE DIALOGS / SHEETS
  // ---------------------------------------------------------------------------

  void showShareModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00875A).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.share_rounded, color: Color(0xFF00875A), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('shareApp'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Invite passengers, conductors & bus owners',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 20, color: Color(0xFF00875A)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'https://enroute-kerala.app/download',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: 'Copy Link',
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: 'https://enroute-kerala.app/download'));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('EnRoute download link copied to clipboard!'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Color(0xFF00875A),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00875A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.send_rounded),
                label: const Text('Share Link via WhatsApp / Social', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Clipboard.setData(const ClipboardData(
                    text: 'Join EnRoute - Smart Kerala Bus Transit & QR Ticketing App: https://enroute-kerala.app/download',
                  ));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share text copied! Paste it in WhatsApp or Telegram.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Color(0xFF00875A),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void showRateUsModal(BuildContext context) {
    int rating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text('Rate EnRoute', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'How was your experience using EnRoute Kerala Transit?',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        icon: Icon(
                          starValue <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setModalState(() => rating = starValue);
                        },
                      );
                    }),
                  ),
                  Center(
                    child: Text(
                      rating == 5
                          ? '🌟 Excellent! Seamless Transit!'
                          : rating >= 4
                              ? '👍 Great Experience'
                              : rating >= 3
                                  ? '👌 Good, with room to improve'
                                  : '💬 Needs Improvement',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Share optional feedback or compliments...',
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00875A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Thank you for rating EnRoute $rating/5 stars! ❤️'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF00875A),
                      ),
                    );
                  },
                  child: const Text('Submit Rating'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showReportIssueModal(BuildContext context) {
    String category = 'GPS / Live Tracking';
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.bug_report_rounded, color: Colors.red, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Report an Issue or Glitch',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'GPS / Live Tracking', child: Text('GPS / Live Tracking Drifting')),
                      DropdownMenuItem(value: 'Camera QR Scanner', child: Text('Camera QR Scanner Recognition')),
                      DropdownMenuItem(value: 'Ticket Generation', child: Text('Ticket Generation / Calculation')),
                      DropdownMenuItem(value: 'Wallet & Top-up', child: Text('Wallet Top-up & Ledger')),
                      DropdownMenuItem(value: 'Timetable / Schedule', child: Text('Incorrect Timetable / Bus Stops')),
                      DropdownMenuItem(value: 'Other Bug', child: Text('Other App Crash / UI Issue')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe what happened, bus number, or stop location...',
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      final randomTicket = 'ENR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Issue submitted successfully! Ticket ID #$randomTicket created.'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF00875A),
                        ),
                      );
                    },
                    child: const Text('Submit Report to Dev Team', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void showSuggestFeatureModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final ideaCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB800).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lightbulb_rounded, color: Color(0xFFFFB800), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Suggest a New Feature',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Feature Idea Title',
                  hintText: 'e.g. Bus Seat Availability Preview',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ideaCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Why would this be useful?',
                  hintText: 'Explain how this would help Kerala passengers, conductors, or bus owners...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00875A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Great idea! Feature suggestion sent to Sahl Saleem & Fathima Riyas.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Color(0xFF00875A),
                    ),
                  );
                },
                child: const Text('Send Idea to Creators', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void showHowToUseModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DefaultTabController(
          length: 3,
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.6,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollCtrl) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00875A).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.help_center_rounded, color: Color(0xFF00875A), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'How to Use EnRoute',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const TabBar(
                      indicatorColor: Color(0xFF00875A),
                      labelColor: Color(0xFF00875A),
                      unselectedLabelColor: Colors.grey,
                      labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: [
                        Tab(text: 'Passenger'),
                        Tab(text: 'Conductor'),
                        Tab(text: 'Bus Owner'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // 1. PASSENGER GUIDE
                          ListView(
                            controller: scrollCtrl,
                            children: const [
                              _GuideStep(
                                step: 1,
                                title: 'Find Your Bus',
                                description:
                                    'Search buses by boarding & destination stops, bus name (e.g. City Express), or vehicle registration number. Real-time autocomplete helps you pick stops instantly.',
                              ),
                              _GuideStep(
                                step: 2,
                                title: 'Live Timeline & ETA',
                                description:
                                    'Tap any running bus to view its live timetable. See where the bus has reached, upcoming stops, and estimated arrival times.',
                              ),
                              _GuideStep(
                                step: 3,
                                title: 'Contactless QR Boarding',
                                description:
                                    'Open your Profile to find your unique permanent Passenger QR code. Present it to the conductor for instantaneous 1-tap ticket issuance without cash hassle.',
                              ),
                              _GuideStep(
                                step: 4,
                                title: 'Smart Transit Wallet',
                                description:
                                    'Top up your balance using UPI or Cash. When the conductor scans your code, fares are auto-debited securely with instant tamper-proof receipts.',
                              ),
                            ],
                          ),

                          // 2. CONDUCTOR GUIDE
                          ListView(
                            controller: scrollCtrl,
                            children: const [
                              _GuideStep(
                                step: 1,
                                title: 'Start Trip & GPS Broadcasting',
                                description:
                                    'Log in using credentials given by your bus owner. Tap "Start Trip & Broadcast Live GPS" when your trip commences so passengers can track your bus.',
                              ),
                              _GuideStep(
                                step: 2,
                                title: 'Manual Stop Override (If GPS Drifts)',
                                description:
                                    'If GPS is weak or inaccurate, tap "Set Current Stop Manually" right on your dashboard to select your actual stop in 1 tap.',
                              ),
                              _GuideStep(
                                step: 3,
                                title: 'Scan Passenger QR or Type ID',
                                description:
                                    'Use the built-in camera scanner to read passenger QR codes. If camera is unavailable, simply type their Passenger ID.',
                              ),
                              _GuideStep(
                                step: 4,
                                title: 'Rapid Fare Calculation',
                                description:
                                    'Start typing boarding and destination stops. The app automatically suggests stops on your route and computes Kerala tariff stages and student concessions.',
                              ),
                            ],
                          ),

                          // 3. BUS OWNER GUIDE
                          ListView(
                            controller: scrollCtrl,
                            children: const [
                              _GuideStep(
                                step: 1,
                                title: 'Fleet Registration',
                                description:
                                    'Register all your private or KSRTC buses with registration number, seating capacity, category (Ordinary, Limited Stop, City), and crew names.',
                              ),
                              _GuideStep(
                                step: 2,
                                title: 'Chronological Timetables',
                                description:
                                    'Set up intermediate stops and timings. The app automatically sorts all stops in ascending chronological order.',
                              ),
                              _GuideStep(
                                step: 3,
                                title: 'Conductor Credential Management',
                                description:
                                    'Create conductor accounts with unique IDs and passwords. Each conductor logs in securely to manage their assigned bus.',
                              ),
                              _GuideStep(
                                step: 4,
                                title: 'Live Fleet Revenue & Analytics',
                                description:
                                    'Monitor today\'s total collections, active running buses, and unread commuter reviews directly from your dashboard.',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _GuideStep extends StatelessWidget {
  final int step;
  final String title;
  final String description;

  const _GuideStep({
    required this.step,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF00875A),
            child: Text(
              '$step',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
