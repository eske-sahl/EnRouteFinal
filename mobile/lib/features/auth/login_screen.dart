import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/fleet_state.dart';
import '../../widgets/app_creator_footer.dart';

class LoginScreen extends StatefulWidget {
  final Function(String role, String email, String name, String userId) onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignUp = false;
  bool _isOwnerSignUp = false;
  bool _obscurePassword = true;

  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  void _fillAccount(String identifier, String pass, String name, String phone, String role, [String company = '']) {
    setState(() {
      _identifierController.text = identifier;
      _passwordController.text = pass;
      _nameController.text = name;
      _phoneController.text = phone;
      _companyController.text = company;
      _isSignUp = false;
      _isOwnerSignUp = false;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _handleAuth() {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    // -------------------------------------------------------------------------
    // 1. SIGN-UP LOGIC
    // -------------------------------------------------------------------------
    if (_isSignUp) {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      if (name.isEmpty) {
        _showError('Please enter your full name to register.');
        return;
      }
      if (phone.isEmpty || phone.length < 10) {
        _showError('Please enter a valid 10-digit mobile number.');
        return;
      }
      if (password.isEmpty || password.length < 6) {
        _showError('Password must be at least 6 characters.');
        return;
      }

      // 1A. Owner Registration Form
      if (_isOwnerSignUp) {
        final company = _companyController.text.trim();
        if (company.isEmpty) {
          _showError('Please enter your Bus Firm or Company Name (e.g. Kondody Motors).');
          return;
        }

        final existingOwner = FleetState.instance.findOwnerByIdOrPhone(phone) ??
            FleetState.instance.findOwnerByIdOrPhone(identifier);
        if (existingOwner != null) {
          _showError('An operator account with this phone or email already exists. Please sign in instead.');
          return;
        }

        final newOwner = FleetState.instance.registerOwner(
          name: name,
          email: identifier.contains('@') ? identifier : '$phone@enroute.transit',
          phone: phone,
          password: password,
          companyName: company,
        );

        widget.onLoginSuccess('OWNER', newOwner.email, '${newOwner.name} (${newOwner.companyName})', newOwner.id);
        return;
      }

      // 1B. Passenger Registration Form (Default)
      final existing = FleetState.instance.findPassengerByIdOrPhone(phone) ??
          FleetState.instance.findPassengerByIdOrPhone(identifier);
      if (existing != null) {
        _showError('A passenger account with this phone or email already exists. Please sign in instead.');
        return;
      }

      final newPassenger = FleetState.instance.registerPassenger(
        name: name,
        phone: phone,
        email: identifier.contains('@') ? identifier : '$phone@enroute.transit',
        password: password,
      );

      widget.onLoginSuccess('PASSENGER', newPassenger.email, newPassenger.name, newPassenger.id);
      return;
    }

    // -------------------------------------------------------------------------
    // 2. UNIFIED SINGLE SIGN-IN LOGIC (Auto-detects Conductor, Owner, or Passenger)
    // -------------------------------------------------------------------------
    final result = FleetState.instance.authenticateUnifiedUser(
      identifier: identifier,
      password: password,
    );

    if (result.success && result.role != null) {
      if (result.role == 'CONDUCTOR') {
        final conductor = result.userModel as ConductorModel;
        final assignedBus = FleetState.instance.getBusByReg(conductor.assignedBusReg);
        if (assignedBus != null && assignedBus.isWaitingForVerification) {
          _showError(
            'Access Restricted: Assigned bus "${assignedBus.busName}" (${assignedBus.regNumber}) '
            'is currently WAITING FOR ADMIN VERIFICATION. '
            'Conductor operations will be activated once the vehicle is approved by Admin.',
          );
          return;
        }
        widget.onLoginSuccess('CONDUCTOR', conductor.email, conductor.name, conductor.id);
      } else if (result.role == 'OWNER') {
        final owner = result.userModel as OwnerModel;
        widget.onLoginSuccess('OWNER', owner.email, '${owner.name} (${owner.companyName})', owner.id);
      } else if (result.role == 'PASSENGER') {
        final passenger = result.userModel as PassengerModel;
        widget.onLoginSuccess('PASSENGER', passenger.email, passenger.name, passenger.id);
      }
    } else {
      _showError(result.errorMessage ?? 'Invalid login credentials. Please check your credentials or register.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF060E18), const Color(0xFF003824), const Color(0xFF0B1120)]
                : [const Color(0xFF003824), const Color(0xFF005A3A), const Color(0xFFF8FAFC)],
            stops: const [0.0, 0.35, 0.35],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),

                // Top Branding Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accentAmber,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.directions_bus, color: Color(0xFF0F172A), size: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'EnRoute',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Smart Kerala Transit & Live Ticketing',
                            style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Unified Auth Card
                Card(
                  elevation: 6,
                  color: cardBg,
                  shadowColor: Colors.black.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card Title & Subtitle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _isSignUp
                                    ? (_isOwnerSignUp ? 'Register Bus Operator' : 'Create Passenger Account')
                                    : 'Sign In to Portal',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _isSignUp ? (_isOwnerSignUp ? 'FLEET OWNER' : 'PASSENGER') : 'SMART LOGIN',
                                style: const TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isSignUp
                              ? (_isOwnerSignUp
                                  ? 'Enter firm credentials to manage your bus fleet and crew'
                                  : 'Register with mobile number to start riding & ticketing')
                              : 'Conductors, Owners & Passengers log in seamlessly here',
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 20),

                        // SIGN UP EXTRA FIELDS
                        if (_isSignUp) ...[
                          if (_isOwnerSignUp) ...[
                            TextField(
                              controller: _companyController,
                              style: TextStyle(color: textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Bus Firm / Fleet Operator Name',
                                labelStyle: TextStyle(color: textSecondary),
                                hintText: 'e.g. Kondody Motors, St. George',
                                hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
                                prefixIcon: const Icon(Icons.business_rounded, color: AppTheme.primaryGreen),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          TextField(
                            controller: _nameController,
                            style: TextStyle(color: textPrimary),
                            decoration: InputDecoration(
                              labelText: _isOwnerSignUp ? 'Operator Owner Full Name' : 'Full Name',
                              labelStyle: TextStyle(color: textSecondary),
                              hintText: 'Enter your legal name',
                              hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
                              prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.primaryGreen),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(color: textPrimary),
                            decoration: InputDecoration(
                              labelText: '10-Digit Mobile Number',
                              labelStyle: TextStyle(color: textSecondary),
                              hintText: '9847000004',
                              hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
                              prefixText: '+91 ',
                              prefixStyle: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
                              prefixIcon: const Icon(Icons.phone_android, color: AppTheme.primaryGreen),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // UNIFIED IDENTIFIER FIELD
                        TextField(
                          key: const Key('login_id_field'),
                          controller: _identifierController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            labelText: _isSignUp ? 'Email Address (Optional)' : 'User ID / Mobile / Email',
                            labelStyle: TextStyle(color: textSecondary),
                            hintText: _isSignUp
                                ? 'passenger@gmail.com'
                                : 'Conductor ID, Owner email, or Passenger phone',
                            hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
                            prefixIcon: Icon(
                              _isSignUp ? Icons.alternate_email : Icons.account_circle_outlined,
                              color: AppTheme.primaryGreen,
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // PASSWORD FIELD
                        TextField(
                          key: const Key('login_password_field'),
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: textSecondary),
                            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryGreen),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: textSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Primary Action Button (Sign In / Register)
                        ElevatedButton(
                          key: const Key('login_submit_button'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          onPressed: _handleAuth,
                          child: Text(
                            _isSignUp
                                ? (_isOwnerSignUp ? 'Register as Bus Operator' : 'Create Passenger Account')
                                : 'Sign In to EnRoute',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Switch between Sign-In and Sign-Up
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _isSignUp ? 'Already registered?' : "Don't have an account?",
                              style: TextStyle(color: textSecondary, fontSize: 13),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isSignUp = !_isSignUp;
                                  if (!_isSignUp) _isOwnerSignUp = false;
                                });
                              },
                              child: Text(
                                _isSignUp ? 'Sign In' : 'Create New Account',
                                style: const TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // SEMI-HIDDEN / KEY OPTION FOR BUS OPERATOR CREATION
                        if (_isSignUp) ...[
                          const Divider(height: 20),
                          if (!_isOwnerSignUp)
                            Center(
                              child: TextButton.icon(
                                icon: const Icon(Icons.vpn_key_rounded, size: 15, color: AppTheme.accentAmber),
                                label: const Text(
                                  'Bus Operator / Fleet Owner Sign Up',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() => _isOwnerSignUp = true);
                                },
                              ),
                            )
                          else
                            Center(
                              child: TextButton.icon(
                                icon: const Icon(Icons.arrow_back, size: 14),
                                label: const Text(
                                  'Back to Passenger Sign Up',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                onPressed: () {
                                  setState(() => _isOwnerSignUp = false);
                                },
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 1-TAP DEMO ACCOUNT ACCELERATORS
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bolt, size: 16, color: AppTheme.accentAmber),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '1-Tap Test Accounts (Automatic Role Routing)',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          _accountFillBtn('Fathima (Passenger)', () => _fillAccount('9847000004', 'password123', 'Fathima', '9847000004', 'PASSENGER'), isDark),
                          _accountFillBtn('Adhil KM (Student)', () => _fillAccount('9847000005', 'password123', 'Adhil KM', '9847000005', 'PASSENGER'), isDark),
                          _accountFillBtn('Shamil K (Conductor)', () => _fillAccount('shamil.conductor', 'password123', 'Shamil K', '9847011001', 'CONDUCTOR'), isDark),
                          _accountFillBtn('Sahl (Owner)', () => _fillAccount('sahl@gmail.com', 'password123', 'Sahl', '9447012345', 'OWNER', 'Sahl Motors Kozhikode'), isDark),
                          _accountFillBtn('Fathima Riyas (Owner)', () => _fillAccount('fathima.owner@gmail.com', 'password123', 'Fathima Riyas', '9447054321', 'OWNER', 'Fathima Riyas Transit'), isDark),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                const AppCreatorFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _accountFillBtn(String label, VoidCallback onTap, bool isDark) {
    return ActionChip(
      avatar: const Icon(Icons.person_pin, size: 14, color: AppTheme.primaryGreen),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
      side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
      onPressed: onTap,
    );
  }
}
