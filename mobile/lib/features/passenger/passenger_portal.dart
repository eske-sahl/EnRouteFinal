import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/fleet_state.dart';
import '../../widgets/emergency_sos_dialog.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/search_tab.dart';
import 'tabs/wallet_tab.dart';
import 'tabs/profile_tab.dart';
import 'passenger_ticket_history_page.dart';
import 'bus_location_screen.dart';
import 'widgets/passenger_ai_sheet.dart';

class PassengerPortal extends StatefulWidget {
  final PassengerModel passenger;
  final bool isOnline;
  final Function(double) onTopUp;
  final VoidCallback onLogout;

  const PassengerPortal({
    super.key,
    required this.passenger,
    required this.isOnline,
    required this.onTopUp,
    required this.onLogout,
  });

  @override
  State<PassengerPortal> createState() => _PassengerPortalState();
}

class _PassengerPortalState extends State<PassengerPortal> {
  int _selectedTabIndex = 0;
  bool _viewingAllTickets = false;
  BusModel? _trackingBus;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      // Tab 1: Dashboard
      DashboardTab(
        passenger: widget.passenger,
        onTopUp: widget.onTopUp,
        onViewAllTickets: () {
          setState(() {
            _viewingAllTickets = true;
          });
        },
      ),

      // Tab 2: Bus Search (with 2 inner tabs: Route Search & Bus by Reg No)
      SearchTab(
        passenger: widget.passenger,
        onTrackBus: (bus) {
          setState(() {
            _trackingBus = bus;
          });
        },
      ),

      // Tab 3: Wallet Details (All transactions, recharge, upi, cash, travel history)
      WalletTab(
        passenger: widget.passenger,
        onTopUp: widget.onTopUp,
      ),

      // Tab 4: Profile & Settings & Logout
      ProfileTab(
        passenger: widget.passenger,
        onLogout: widget.onLogout,
      ),
    ];

    final tabTitles = [
      'Passenger Dashboard',
      'Bus & Route Search',
      'Wallet & Travel Ledger',
      'My Profile & Settings',
    ];

    Widget activeBody;
    if (_viewingAllTickets) {
      activeBody = PassengerTicketHistoryPage(
        passenger: widget.passenger,
        onBack: () => setState(() => _viewingAllTickets = false),
      );
    } else if (_trackingBus != null) {
      activeBody = BusLocationScreen(
        busRegNumber: _trackingBus!.regNumber,
        busName: _trackingBus!.busName,
        routeName: _trackingBus!.routeName,
        companyName: _trackingBus!.companyName,
        currentStop: _trackingBus!.currentStop,
        nextStop: _trackingBus!.nextStop,
        eta: _trackingBus!.eta,
        stops: _trackingBus!.stops,
        category: _trackingBus!.category,
        driverName: _trackingBus!.driverName,
        conductorName: _trackingBus!.conductorName,
        onBack: () => setState(() => _trackingBus = null),
      );
    } else {
      activeBody = tabs[_selectedTabIndex];
    }

    final isSubpageActive = _viewingAllTickets || _trackingBus != null;

    return Scaffold(
      appBar: isSubpageActive
          ? null
          : AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tabTitles[_selectedTabIndex], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.isOnline ? AppTheme.accentAmber : Colors.orangeAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.passenger.name} • ${widget.passenger.id}',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.emergency, color: Colors.redAccent),
                  tooltip: 'Emergency SOS (112)',
                  onPressed: () => EmergencySosDialog.show(context),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Sign Out',
                  onPressed: widget.onLogout,
                ),
              ],
            ),
      body: activeBody,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildMetaStyleAiButton(context),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _viewingAllTickets = false;
            _trackingBus = null;
            _selectedTabIndex = index;
          });
        },
        indicatorColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryGreen),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search, color: AppTheme.primaryGreen),
            label: 'Bus Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet, color: AppTheme.primaryGreen),
            label: 'Wallet Details',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.primaryGreen),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildMetaStyleAiButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 2),
      child: Material(
        key: const Key('passenger_ai_floating_button'),
        color: Colors.transparent,
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: const Color(0xFF0072FF).withValues(alpha: 0.45),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => PassengerAiSheet.show(context, passenger: widget.passenger),
          child: Tooltip(
            message: 'Ask EnRoute AI Assistant',
            child: Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Color(0xFF00C6FF),
                    Color(0xFF0072FF),
                    Color(0xFF8E2DE2),
                    Color(0xFFF355DA),
                    Color(0xFF00C6FF),
                  ],
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1B222A) : Colors.white,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF00C6FF), Color(0xFF8E2DE2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      right: 3,
                      bottom: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
