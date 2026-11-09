import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/fleet_state.dart';
import '../../widgets/bus_live_map_widget.dart';
import '../conductor/conductor_portal.dart';

class BusDetailPage extends StatefulWidget {
  final BusModel bus;
  final VoidCallback onNavigateToConductors;
  final VoidCallback? onBack;

  const BusDetailPage({
    super.key,
    required this.bus,
    required this.onNavigateToConductors,
    this.onBack,
  });

  @override
  State<BusDetailPage> createState() => _BusDetailPageState();
}

class _BusDetailPageState extends State<BusDetailPage> {
  late String _busName;
  late String _category;
  late String _startPoint;
  late String _destPoint;
  late List<BusStopSchedule> _stops;
  late int _seats;
  late String _driver;
  late String _driverPhone;
  late String _cleaner;
  late String _cleanerPhone;
  late String _conductor;
  late bool _isActive;
  late String _upiId;
  late String _payeeName;
  late bool _isUpiEnabled;

  @override
  void initState() {
    super.initState();
    _syncFromBus();
    FleetState.instance.addListener(_onFleetChanged);
  }

  @override
  void dispose() {
    FleetState.instance.removeListener(_onFleetChanged);
    super.dispose();
  }

  void _onFleetChanged() {
    if (mounted) {
      setState(() {
        _syncFromBus();
      });
    }
  }

  void _syncFromBus() {
    widget.bus.sortStops();
    _busName = widget.bus.busName;
    _category = widget.bus.category;
    _startPoint = widget.bus.startPoint;
    _destPoint = widget.bus.destPoint;
    _stops = List.from(widget.bus.stops);
    _stops.sort((a, b) => parseTimeToMinutes(a.time).compareTo(parseTimeToMinutes(b.time)));
    _seats = widget.bus.seatingCapacity;
    _driver = widget.bus.driverName;
    _driverPhone = widget.bus.driverPhone;
    _cleaner = widget.bus.cleanerName;
    _cleanerPhone = widget.bus.cleanerPhone;
    _conductor = widget.bus.conductorName;
    _isActive = widget.bus.isActive;
    _upiId = widget.bus.upiId;
    _payeeName = widget.bus.payeeName;
    _isUpiEnabled = widget.bus.isUpiEnabled;
  }

  Color _getCategoryColor(String category) {
    if (category.contains('Red') || category.contains('Limited')) {
      return const Color(0xFFC62828);
    } else if (category.contains('Blue') || category.contains('Ordinary')) {
      return const Color(0xFF1565C0);
    } else if (category.contains('Yellow') || category.contains('Rural') || category.contains('Gramavandi')) {
      return const Color(0xFFF57F17);
    } else {
      return const Color(0xFF2E7D32);
    }
  }

  void _toggleActiveStatus(bool active) {
    setState(() {
      _isActive = active;
      widget.bus.isActive = active;
      widget.bus.status = active ? 'RUNNING_NOW' : 'IN_DEPOT';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bus status set to ${active ? "ACTIVE (Running on Route)" : "INACTIVE (In Depot)"}'),
        backgroundColor: active ? AppTheme.primaryGreen : Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showEditUpiModal() {
    final upiCtrl = TextEditingController(text: _upiId);
    final payeeCtrl = TextEditingController(text: _payeeName.isNotEmpty ? _payeeName : widget.bus.busName);
    bool enableUpi = _isUpiEnabled || _upiId.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final currentVpa = upiCtrl.text.trim();
            final currentPayee = payeeCtrl.text.trim().isNotEmpty ? payeeCtrl.text.trim() : widget.bus.busName;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.qr_code_2, color: AppTheme.primaryGreen),
                            SizedBox(width: 8),
                            Text('Bus Banking & Direct UPI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                      ],
                    ),
                    const Text(
                      'Assign your business UPI ID and payee name for this bus. When configured, your conductor POS will generate dynamic QR codes depositing directly to your account.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    // Enable / Disable UPI Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable UPI Dynamic QR for this Bus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(
                        enableUpi
                            ? 'Conductor can accept Google Pay, PhonePe & Paytm'
                            : 'UPI disabled. Conductor portal restricted to Cash & Wallet',
                        style: TextStyle(fontSize: 11, color: enableUpi ? AppTheme.primaryGreen : Colors.grey),
                      ),
                      value: enableUpi,
                      activeTrackColor: AppTheme.primaryGreen.withValues(alpha: 0.5),
                      activeThumbColor: AppTheme.primaryGreen,
                      onChanged: (val) {
                        setModalState(() => enableUpi = val);
                      },
                    ),

                    const SizedBox(height: 12),

                    // Payee Business Name
                    TextField(
                      controller: payeeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Business / Payee Name',
                        hintText: 'e.g. Sana Bus Lines or Sahl Motors',
                        prefixIcon: const Icon(Icons.business, color: AppTheme.primaryGreen),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),

                    const SizedBox(height: 14),

                    // UPI ID / VPA
                    TextField(
                      controller: upiCtrl,
                      decoration: InputDecoration(
                        labelText: 'Owner UPI ID (VPA)',
                        hintText: 'e.g. yourname@okaxis or yourbusiness@okhdfcbank',
                        prefixIcon: const Icon(Icons.account_balance, color: AppTheme.primaryGreen),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        helperText: 'Leave empty to keep UPI disabled/unassigned',
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),

                    const SizedBox(height: 16),

                    // Live QR Preview inside sheet (only if VPA is typed)
                    if (currentVpa.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: QrImageView(
                                data: 'upi://pay?pa=$currentVpa&pn=${Uri.encodeComponent(currentPayee)}&cu=INR',
                                size: 70,
                                version: QrVersions.auto,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Owner Assigned QR Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text('Payee: $currentPayee', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  Text('VPA: $currentVpa', style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Enter a UPI ID above to configure the official owner-assigned QR scanner for this bus.',
                                style: TextStyle(fontSize: 11, color: Colors.brown),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        final newUpi = upiCtrl.text.trim();
                        final newPayee = payeeCtrl.text.trim().isNotEmpty ? payeeCtrl.text.trim() : widget.bus.busName;
                        final isEnabled = enableUpi && newUpi.isNotEmpty;

                        FleetState.instance.updateBusUpiDetails(
                          regNumber: widget.bus.regNumber,
                          upiId: newUpi,
                          payeeName: newUpi.isNotEmpty ? newPayee : '',
                          isUpiEnabled: isEnabled,
                        );

                        setState(() {
                          _syncFromBus();
                        });

                        Navigator.pop(sheetCtx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  isEnabled ? Icons.check_circle : Icons.info_outline,
                                  color: isEnabled ? Colors.greenAccent : Colors.orangeAccent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isEnabled
                                        ? 'Banking details assigned! Conductor POS will now use $newUpi.'
                                        : 'UPI scanner disabled/cleared for ${widget.bus.busName}. Conductor cannot show UPI QR.',
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: AppTheme.darkSlate,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Text(
                        enableUpi && upiCtrl.text.trim().isNotEmpty ? 'Save & Assign to Conductor POS' : 'Save Changes (Scanner Disabled)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditBusModal() {
    final nameCtrl = TextEditingController(text: _busName);
    String selectedCat = _category;
    final startCtrl = TextEditingController(text: _startPoint);
    final destCtrl = TextEditingController(text: _destPoint);
    final seatsCtrl = TextEditingController(text: '$_seats');
    final driverCtrl = TextEditingController(text: _driver);
    final driverPhoneCtrl = TextEditingController(text: _driverPhone);
    final cleanerCtrl = TextEditingController(text: _cleaner);
    final cleanerPhoneCtrl = TextEditingController(text: _cleanerPhone);
    String selectedCond = _conductor;
    bool editIsActive = _isActive;

    // Editable copy of stops
    List<Map<String, String>> editStops = _stops.map((s) {
      return {'stop': s.stopName, 'time': s.time};
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.edit_note, color: AppTheme.primaryGreen),
                            SizedBox(width: 8),
                            Text('Edit Bus Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                      ],
                    ),
                    const Text(
                      'Owners can modify any vehicle parameters except the permanent RTO Registration Number.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    // Immutable Reg Number Display
                    Builder(builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock, color: isDark ? Colors.white60 : Colors.grey, size: 20),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'REGISTRATION NUMBER (LOCKED)',
                                  style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.grey, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  widget.bus.regNumber,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black87),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'IMMUTABLE',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 14),

                    // Active / Inactive Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Bus Operational Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(editIsActive ? 'ACTIVE (Operating on Route)' : 'INACTIVE (Off Route / In Depot)',
                          style: TextStyle(color: editIsActive ? Colors.green : Colors.grey, fontSize: 12)),
                      value: editIsActive,
                      activeThumbColor: AppTheme.primaryGreen,
                      onChanged: (val) {
                        setModalState(() => editIsActive = val);
                      },
                    ),
                    const Divider(height: 16),

                    // Bus Name
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Bus Display Name',
                        prefixIcon: const Icon(Icons.directions_bus, color: AppTheme.primaryGreen),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Kerala Bus Category & Livery',
                        prefixIcon: const Icon(Icons.palette, color: AppTheme.primaryGreen),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      initialValue: selectedCat,
                      items: const [
                        DropdownMenuItem(
                          value: 'Limited Stop Bus (Red-Whiteline)',
                          child: Row(
                            children: [
                              Icon(Icons.circle, color: Color(0xFFC62828), size: 14),
                              SizedBox(width: 8),
                              Text('Limited Stop Bus (Red-Whiteline)', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Ordinary Bus (Blue-Whiteline)',
                          child: Row(
                            children: [
                              Icon(Icons.circle, color: Color(0xFF1565C0), size: 14),
                              SizedBox(width: 8),
                              Text('Ordinary Bus (Blue-Whiteline)', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'City Bus (Green-Whiteline)',
                          child: Row(
                            children: [
                              Icon(Icons.circle, color: Color(0xFF2E7D32), size: 14),
                              SizedBox(width: 8),
                              Text('City Bus (Green-Whiteline)', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Rural Feeder / Gramavandi (Yellow-Whiteline)',
                          child: Row(
                            children: [
                              Icon(Icons.circle, color: Color(0xFFF57F17), size: 14),
                              SizedBox(width: 8),
                              Text('Rural Feeder / Gramavandi (Yellow-Whiteline)', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedCat = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Route: Start Point - Destination Point
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startCtrl,
                            decoration: InputDecoration(
                              labelText: 'Start Point',
                              prefixIcon: const Icon(Icons.trip_origin, color: AppTheme.primaryGreen, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: destCtrl,
                            decoration: InputDecoration(
                              labelText: 'Destination Point',
                              prefixIcon: const Icon(Icons.location_on, color: Colors.red, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Intermediate Stops & Timings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Intermediate Stops & Timetable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              editStops.add({'stop': 'New Stop', 'time': '08:00 AM'});
                            });
                          },
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add Stop', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...editStops.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                initialValue: item['stop'],
                                decoration: InputDecoration(
                                  labelText: 'Stop #${idx + 1}',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onChanged: (val) => editStops[idx]['stop'] = val,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: item['time'],
                                decoration: InputDecoration(
                                  labelText: 'Departure',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onChanged: (val) => editStops[idx]['time'] = val,
                              ),
                            ),
                            if (editStops.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red, size: 18),
                                onPressed: () {
                                  setModalState(() {
                                    editStops.removeAt(idx);
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 10),

                    // Seats
                    TextField(
                      controller: seatsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Passenger Seating Capacity',
                        prefixIcon: const Icon(Icons.event_seat, color: AppTheme.primaryGreen),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Workers: Driver
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: driverCtrl,
                            decoration: InputDecoration(
                              labelText: 'Driver Name',
                              prefixIcon: const Icon(Icons.airline_seat_recline_normal, color: AppTheme.primaryGreen, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: driverPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Driver Phone (Optional)',
                              prefixIcon: const Icon(Icons.phone, color: AppTheme.primaryGreen, size: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Workers: Cleaner
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: cleanerCtrl,
                            decoration: InputDecoration(
                              labelText: 'Cleaner Name',
                              prefixIcon: const Icon(Icons.cleaning_services, color: AppTheme.primaryGreen, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: cleanerPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Cleaner Phone (Optional)',
                              prefixIcon: const Icon(Icons.phone, color: AppTheme.primaryGreen, size: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Workers: Conductor
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Assigned Conductor',
                        prefixIcon: const Icon(Icons.badge, color: AppTheme.primaryGreen),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      initialValue: (FleetState.instance.getConductorsForOwner(widget.bus.ownerId).any((c) => c.name == selectedCond))
                          ? selectedCond
                          : 'Unassigned',
                      items: [
                        const DropdownMenuItem(value: 'Unassigned', child: Text('Unassigned')),
                        ...FleetState.instance.getConductorsForOwner(widget.bus.ownerId).map((c) {
                          return DropdownMenuItem(value: c.name, child: Text('${c.name} (${c.userId})'));
                        }),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedCond = val);
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        final updatedStops = editStops.map((s) {
                          return BusStopSchedule(stopName: s['stop'] ?? 'Stop', time: s['time'] ?? '08:00 AM');
                        }).toList();
                        updatedStops.sort((a, b) => parseTimeToMinutes(a.time).compareTo(parseTimeToMinutes(b.time)));

                        FleetState.instance.updateBus(
                          regNumber: widget.bus.regNumber,
                          busName: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : _busName,
                          category: selectedCat,
                          startPoint: startCtrl.text.trim().isNotEmpty ? startCtrl.text.trim() : _startPoint,
                          destPoint: destCtrl.text.trim().isNotEmpty ? destCtrl.text.trim() : _destPoint,
                          seats: int.tryParse(seatsCtrl.text.trim()) ?? _seats,
                          driver: driverCtrl.text.trim().isNotEmpty ? driverCtrl.text.trim() : _driver,
                          cleaner: cleanerCtrl.text.trim().isNotEmpty ? cleanerCtrl.text.trim() : _cleaner,
                          conductor: selectedCond,
                          isActive: editIsActive,
                          stops: updatedStops,
                        );

                        FleetState.instance.updateBusCrew(
                          regNumber: widget.bus.regNumber,
                          driverName: driverCtrl.text.trim().isNotEmpty ? driverCtrl.text.trim() : _driver,
                          driverPhone: driverPhoneCtrl.text.trim().isNotEmpty ? driverPhoneCtrl.text.trim() : _driverPhone,
                          cleanerName: cleanerCtrl.text.trim().isNotEmpty ? cleanerCtrl.text.trim() : _cleaner,
                          cleanerPhone: cleanerPhoneCtrl.text.trim().isNotEmpty ? cleanerPhoneCtrl.text.trim() : _cleanerPhone,
                        );

                        // If conductor was selected, update their assigned bus
                        if (selectedCond != 'Unassigned') {
                          final cIdx = FleetState.instance.conductors.indexWhere((c) => c.name == selectedCond);
                          if (cIdx != -1) {
                            FleetState.instance.conductors[cIdx].assignedBusReg = widget.bus.regNumber;
                            FleetState.instance.conductors[cIdx].assignedBusName = widget.bus.busName;
                          }
                        }

                        setState(() {
                          _syncFromBus();
                        });

                        Navigator.pop(sheetCtx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${widget.bus.busName} updated successfully! (Reg Num ${widget.bus.regNumber} preserved)'),
                            backgroundColor: AppTheme.primaryGreen,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Save & Apply Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditCrewModal() {
    final dNameCtrl = TextEditingController(text: _driver == 'Unassigned' ? '' : _driver);
    final dPhoneCtrl = TextEditingController(text: _driverPhone);
    final cNameCtrl = TextEditingController(text: _cleaner == 'Unassigned' ? '' : _cleaner);
    final cPhoneCtrl = TextEditingController(text: _cleanerPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.badge, color: AppTheme.primaryGreen),
                      SizedBox(width: 8),
                      Text('Assigned Bus Crew & Workers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                ],
              ),
              const Text(
                'Assign primary driver and vehicle attendant/cleaner names and optional phone numbers.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              // Driver
              const Text('PRIMARY DRIVER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 6),
              TextField(
                controller: dNameCtrl,
                decoration: InputDecoration(
                  labelText: 'Driver Name',
                  hintText: 'e.g. Venu Pillai',
                  prefixIcon: const Icon(Icons.airline_seat_recline_normal, color: Colors.blue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Driver Contact Phone (Optional)',
                  hintText: 'e.g. +91 94470 55112',
                  prefixIcon: const Icon(Icons.phone, color: Colors.blue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),
              // Cleaner
              const Text('CLEANER / ATTENDANT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
              const SizedBox(height: 6),
              TextField(
                controller: cNameCtrl,
                decoration: InputDecoration(
                  labelText: 'Cleaner Name',
                  hintText: 'e.g. Manoj Kumar',
                  prefixIcon: const Icon(Icons.cleaning_services, color: Colors.orange),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Cleaner Contact Phone (Optional)',
                  hintText: 'e.g. +91 94470 55113',
                  prefixIcon: const Icon(Icons.phone, color: Colors.orange),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final newDriver = dNameCtrl.text.trim().isNotEmpty ? dNameCtrl.text.trim() : 'Unassigned';
                  final newDPhone = dPhoneCtrl.text.trim();
                  final newCleaner = cNameCtrl.text.trim().isNotEmpty ? cNameCtrl.text.trim() : 'Unassigned';
                  final newCPhone = cPhoneCtrl.text.trim();

                  FleetState.instance.updateBusCrew(
                    regNumber: widget.bus.regNumber,
                    driverName: newDriver,
                    driverPhone: newDPhone,
                    cleanerName: newCleaner,
                    cleanerPhone: newCPhone,
                  );

                  setState(() {
                    _syncFromBus();
                  });

                  Navigator.pop(sheetCtx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bus crew details updated successfully.'),
                      backgroundColor: AppTheme.primaryGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Save Crew Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openConductorDetails() {
    ConductorModel? conductor;
    try {
      conductor = FleetState.instance.conductors.firstWhere(
        (c) =>
            c.name.trim().toLowerCase() == _conductor.trim().toLowerCase() ||
            c.assignedBusReg.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase() ==
                widget.bus.regNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase(),
      );
    } catch (_) {}

    conductor ??= ConductorModel(
      id: 'COND-PROXY-${widget.bus.regNumber}',
      ownerId: widget.bus.ownerId,
      name: _conductor != 'Unassigned' ? _conductor : 'Shamil K',
      email: widget.bus.conductorEmail.isNotEmpty ? widget.bus.conductorEmail : 'shamil@enroute.com',
      userId: '${widget.bus.regNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase()}.conductor',
      password: 'cond_${widget.bus.regNumber.length >= 4 ? widget.bus.regNumber.substring(widget.bus.regNumber.length - 4) : "1234"}',
      phone: widget.bus.conductorPhone.isNotEmpty ? widget.bus.conductorPhone : '+91 98470 11001',
      licenseNumber: 'KL-10-COND-2024-8891',
      assignedBusReg: widget.bus.regNumber,
      assignedBusName: widget.bus.busName,
      todayCollection: widget.bus.todayCollection,
    );

    _showConductorDetailsModal(conductor);
  }

  void _showConductorDetailsModal(ConductorModel cond) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                child: const Icon(Icons.badge, color: AppTheme.primaryGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cond.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                    Text('Badge: ${cond.licenseNumber}', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _modalRow('Assigned Bus', '${cond.assignedBusName} [${cond.assignedBusReg}]', isDark),
                _modalRow('Email', cond.email, isDark),
                _modalRow('Phone Number', cond.phone, isDark),
                _modalRow('License Number', cond.licenseNumber, isDark),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2B2416) : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? Colors.amber.shade700.withValues(alpha: 0.5) : Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OWNER ASSIGNED APP LOGIN CREDENTIALS',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: isDark ? Colors.amber.shade300 : Colors.brown.shade800),
                      ),
                      const SizedBox(height: 4),
                      _modalRow('User ID', cond.userId, isDark, true),
                      _modalRow('Password', cond.password, isDark, true),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _modalRow('Today\'s Collections', '₹${cond.todayCollection.toStringAsFixed(1)}', isDark),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryGreen, Colors.teal.shade700],
                    ),
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.swap_horiz, color: Colors.white),
                    label: const Text(
                      'Switch to Conductor Portal as Owner',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      _confirmSwitchToConductorPortal(cond);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _modalRow(String label, String value, bool isDark, [bool isHighlight = false]) {
    final valColor = isHighlight
        ? (isDark ? Colors.amber.shade200 : Colors.brown.shade900)
        : (isDark ? Colors.white : Colors.black87);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 11)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: valColor),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSwitchToConductorPortal(ConductorModel conductor) {
    showDialog(
      context: context,
      builder: (cautionCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text('Caution: Switch to Conductor Mode?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are currently signed in as Fleet Owner (${widget.bus.ownerName}).',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                'Entering Conductor Mode grants you active operational ticketing, stage advancement, and live GPS broadcast control for ${widget.bus.busName} (${widget.bus.regNumber}).',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Text(
                  'Caution: All issued tickets and passenger handovers made during this session will reflect in live bus collections.',
                  style: TextStyle(fontSize: 11, color: Colors.brown, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(cautionCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              icon: const Icon(Icons.login, size: 16, color: Colors.white),
              label: const Text('Proceed to Conductor Portal', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              onPressed: () {
                Navigator.pop(cautionCtx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConductorPortal(
                      conductor: conductor,
                      onLogout: () => Navigator.pop(context),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLiveGpsRadarHUD(BuildContext context) {
    final isGpsLive = widget.bus.isLiveGpsActive && widget.bus.isTripActive;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGpsLive ? Colors.greenAccent.withValues(alpha: 0.6) : Colors.white12,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isGpsLive ? Colors.greenAccent.withValues(alpha: 0.15) : Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isGpsLive ? Colors.greenAccent : Colors.amber,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isGpsLive ? Colors.greenAccent.withValues(alpha: 0.8) : Colors.amber.withValues(alpha: 0.8),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isGpsLive ? 'LIVE CONDUCTOR GPS BROADCAST' : 'GPS BROADCAST INACTIVE / IDLE',
                    style: TextStyle(
                      color: isGpsLive ? Colors.greenAccent : Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isGpsLive ? Colors.green.withValues(alpha: 0.2) : Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isGpsLive ? Colors.greenAccent : Colors.white24),
                ),
                child: Text(
                  isGpsLive ? '42 km/h' : 'Standing / Depot',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                ),
                child: Icon(
                  isGpsLive ? Icons.radar : Icons.gps_off,
                  color: isGpsLive ? AppTheme.accentAmber : Colors.white54,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'APPROACHING NEXT STAGE',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9, letterSpacing: 1),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.bus.currentStop} ➔ ${widget.bus.nextStop}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Estimated Arrival: ${widget.bus.eta} • Conductor Device GPS Active',
                      style: const TextStyle(color: AppTheme.accentAmber, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Real Live Interactive Map Semi-Window
          BusLiveMapWidget(
            bus: widget.bus,
            height: 220,
            showControls: true,
          ),

          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Lat: ${widget.bus.currentLatitude.toStringAsFixed(4)}° N, Lon: ${widget.bus.currentLongitude.toStringAsFixed(4)}° E',
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isGpsLive ? Icons.satellite_alt : Icons.location_disabled, color: isGpsLive ? Colors.greenAccent : Colors.grey, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      isGpsLive ? 'GNSS Lock' : 'GPS standby',
                      style: const TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(_category);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$_busName Details', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.bus.regNumber, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Bus Configuration',
            onPressed: _showEditBusModal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Live Operational Status & Collection Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.darkCardGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Active/Inactive toggle chip
                      GestureDetector(
                        onTap: () => _toggleActiveStatus(!_isActive),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _isActive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isActive ? Colors.greenAccent : Colors.redAccent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isActive ? Icons.sensors : Icons.power_settings_new,
                                color: _isActive ? Colors.greenAccent : Colors.redAccent,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isActive ? 'ACTIVE ON ROUTE' : 'INACTIVE / DEPOT',
                                style: TextStyle(
                                  color: _isActive ? Colors.greenAccent : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Immutable Reg Plate
                      Row(
                        children: [
                          const Icon(Icons.lock, color: AppTheme.accentAmber, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            widget.bus.regNumber,
                            style: const TextStyle(color: AppTheme.accentAmber, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TODAY\'S LIVE EARNINGS', style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1.1)),
                          const SizedBox(height: 4),
                          Text(
                            '₹${widget.bus.todayCollection.toStringAsFixed(1)}',
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('TICKETS ISSUED', style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1.1)),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.bus.ticketsCount} tickets',
                            style: const TextStyle(color: AppTheme.accentAmber, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Current: ${widget.bus.currentStop}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Next: ${widget.bus.nextStop}',
                          textAlign: TextAlign.end,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Live Conductor GPS Radar Telemetry HUD (Semi-Window)
            _buildLiveGpsRadarHUD(context),

            const SizedBox(height: 18),

            // 2. Kerala Livery & Category Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.directions_bus, color: AppTheme.primaryGreen),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text('Bus Classification & Category', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _showEditBusModal,
                          icon: const Icon(Icons.edit, size: 14, color: AppTheme.primaryGreen),
                          label: const Text('Edit', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Divider(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: catColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.palette, color: catColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _category,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: catColor, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow('Bus Name', _busName),
                    _infoRow('Registration No.', '${widget.bus.regNumber} (Immutable)'),
                    _infoRow('Seating Capacity', '$_seats Passenger Seats'),
                    _infoRow('Owner Company', widget.bus.companyName),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 3. Route & Stops Timetable Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.alt_route, color: AppTheme.primaryGreen),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text('Route & Timetable', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _showEditBusModal,
                          icon: const Icon(Icons.edit, size: 14, color: AppTheme.primaryGreen),
                          label: const Text('Modify', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Divider(),
                    _infoRow('Route Corridor', '$_startPoint ➔ $_destPoint'),
                    _infoRow('Service Timings', '${widget.bus.startTime} to ${widget.bus.endTime}'),
                    const SizedBox(height: 12),
                    const Text('Stops & Timing Schedule:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    if (_stops.isEmpty)
                      const Text('No intermediate stops scheduled yet. Assigned conductor can add stops.', style: TextStyle(color: Colors.grey, fontSize: 12))
                    else
                      Column(
                        children: _stops.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final stop = entry.value;
                          final isFirst = idx == 0;
                          final isLast = idx == _stops.length - 1;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  isFirst ? Icons.trip_origin : (isLast ? Icons.location_on : Icons.circle),
                                  size: 14,
                                  color: isFirst ? AppTheme.primaryGreen : (isLast ? Colors.red : Colors.grey),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    stop.stopName,
                                    style: TextStyle(
                                      fontWeight: (isFirst || isLast) ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Builder(builder: (context) {
                                  final isDark = Theme.of(context).brightness == Brightness.dark;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      stop.time,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 4. Workers / Crew Assigned Section
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.badge, color: AppTheme.primaryGreen),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Assigned Bus Crew & Workers',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _showEditCrewModal,
                          icon: const Icon(Icons.edit, size: 14, color: AppTheme.primaryGreen),
                          label: const Text('Edit Crew', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Conductor Item
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                        child: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryGreen),
                      ),
                      title: Text(_conductor, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Conductor • App Login ID assigned by Owner'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: const BorderSide(color: AppTheme.primaryGreen),
                            ),
                            onPressed: _openConductorDetails,
                            child: const Text('More', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, color: AppTheme.primaryGreen),
                        ],
                      ),
                      onTap: _openConductorDetails,
                    ),

                    const Divider(height: 16),

                    // Driver Details
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withValues(alpha: 0.15),
                        child: const Icon(Icons.airline_seat_recline_normal, color: Colors.blue),
                      ),
                      title: Text(_driver, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Primary Driver • ${_driverPhone.isNotEmpty ? _driverPhone : "Tap to add phone (optional)"}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryGreen),
                        tooltip: 'Edit Driver & Cleaner',
                        onPressed: _showEditCrewModal,
                      ),
                      onTap: _showEditCrewModal,
                    ),

                    const Divider(height: 16),

                    // Cleaner Details
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.withValues(alpha: 0.15),
                        child: const Icon(Icons.cleaning_services, color: Colors.orange),
                      ),
                      title: Text(_cleaner, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Cleaner / Vehicle Attendant • ${_cleanerPhone.isNotEmpty ? _cleanerPhone : "Tap to add phone (optional)"}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryGreen),
                        tooltip: 'Edit Driver & Cleaner',
                        onPressed: _showEditCrewModal,
                      ),
                      onTap: _showEditCrewModal,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 5. Business Banking & Dynamic UPI Payments
            Builder(builder: (context) {
              final bool hasValidUpi = _isUpiEnabled && _upiId.trim().isNotEmpty;
              final isDark = Theme.of(context).brightness == Brightness.dark;

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryGreen),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Business Banking & Direct UPI',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _showEditUpiModal,
                            icon: Icon(hasValidUpi ? Icons.edit : Icons.add_link, size: 14, color: AppTheme.primaryGreen),
                            label: Text(hasValidUpi ? 'Edit' : 'Assign', style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const Divider(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: hasValidUpi ? Colors.green.withValues(alpha: 0.1) : Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: hasValidUpi ? Colors.green.withValues(alpha: 0.3) : Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasValidUpi ? Icons.check_circle : Icons.warning_amber_rounded,
                              color: hasValidUpi ? Colors.green : Colors.amber.shade800,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hasValidUpi
                                    ? 'Active: Conductor POS generates dynamic UPI QR codes'
                                    : 'Unassigned: Conductor POS disabled (Cash & Wallet only)',
                                style: TextStyle(
                                  color: hasValidUpi ? Colors.green.shade800 : Colors.amber.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _infoRow('Business Payee Name', _payeeName.isNotEmpty ? _payeeName : 'Not Assigned (Empty)'),
                      _infoRow('Assigned UPI ID (VPA)', _upiId.isNotEmpty ? _upiId : 'Not Assigned (Empty)'),
                      const SizedBox(height: 14),

                      // Owner-Assigned QR Code Card (or Unassigned State)
                      if (hasValidUpi) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white12 : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: QrImageView(
                                  data: 'upi://pay?pa=$_upiId&pn=${Uri.encodeComponent(_payeeName)}&cu=INR',
                                  size: 84,
                                  version: QrVersions.auto,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.verified, size: 14, color: AppTheme.primaryGreen),
                                        SizedBox(width: 4),
                                        Text(
                                          'Owner Assigned QR Code',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Directly credits to $_upiId on passenger scan.',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        side: const BorderSide(color: AppTheme.primaryGreen),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: _showEditUpiModal,
                                      icon: const Icon(Icons.edit, size: 14, color: AppTheme.primaryGreen),
                                      label: const Text('Configure / Change UPI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Empty state when owner hasn't assigned a scanner yet
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.qr_code_2, size: 40, color: Colors.grey),
                              const SizedBox(height: 6),
                              const Text(
                                'No UPI QR Configured for this Bus',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'The conductor cannot receive money by UPI until you configure a UPI ID for this bus.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                onPressed: _showEditUpiModal,
                                icon: const Icon(Icons.qr_code_scanner, size: 16),
                                label: const Text('Configure UPI / QR Code'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
