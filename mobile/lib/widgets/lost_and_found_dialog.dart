import 'package:flutter/material.dart';
import '../models/lost_item_model.dart';
import '../services/fleet_state.dart';
import '../theme/app_theme.dart';

/// Lost & Found Desk for passengers and crew
class LostAndFoundDialog extends StatefulWidget {
  final String? initialBusReg;
  final bool isCrew;
  final String? passengerId;
  final String? passengerName;
  final String? contactPhone;

  const LostAndFoundDialog({
    super.key,
    this.initialBusReg,
    this.isCrew = false,
    this.passengerId,
    this.passengerName,
    this.contactPhone,
  });

  static void show(
    BuildContext context, {
    String? initialBusReg,
    String? busRegNumber,
    String? busName,
    bool isCrew = false,
    String? passengerId,
    String? passengerName,
    String? contactPhone,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => LostAndFoundDialog(
        initialBusReg: initialBusReg ?? busRegNumber,
        isCrew: isCrew,
        passengerId: passengerId,
        passengerName: passengerName,
        contactPhone: contactPhone,
      ),
    );
  }

  @override
  State<LostAndFoundDialog> createState() => _LostAndFoundDialogState();
}

class _LostAndFoundDialogState extends State<LostAndFoundDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _descController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedCategory = 'Bag / Backpack';
  String? _selectedBusReg;

  final List<String> _categories = [
    'Bag / Backpack',
    'Smartphone / Electronics',
    'Wallet / Cash',
    'Documents / ID Card',
    'Umbrella',
    'Clothing / Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final buses = FleetState.instance.buses;
    if (widget.initialBusReg != null) {
      _selectedBusReg = widget.initialBusReg;
    } else if (buses.isNotEmpty) {
      _selectedBusReg = buses.first.regNumber;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submitReport() {
    final desc = _descController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (desc.isEmpty || name.isEmpty || phone.isEmpty || _selectedBusReg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields to submit lost item report.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final bus = FleetState.instance.getBusByReg(_selectedBusReg!);
    final busName = bus?.busName ?? _selectedBusReg!;

    final report = LostItemReport(
      id: 'LOST-${DateTime.now().millisecondsSinceEpoch}',
      busRegNumber: _selectedBusReg!,
      busName: busName,
      itemCategory: _selectedCategory,
      description: desc,
      reporterName: name,
      reporterPhone: phone,
      dateReported: DateTime.now(),
    );

    FleetState.instance.reportLostItem(report);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Lost item reported for bus $busName. Conductor and depot alerted.'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );

    _descController.clear();
    _nameController.clear();
    _phoneController.clear();
    _tabController.animateTo(0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = FleetState.instance.lostItems;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.luggage, color: AppTheme.primaryGreen, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lost & Found Desk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('നഷ്ടപ്പെട്ട സാധനങ്ങൾ • Private Bus Transit', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryGreen,
              tabs: const [
                Tab(text: 'Reported Items'),
                Tab(text: '+ Report Lost Item'),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: List
                  items.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('No lost items currently reported.', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final item = items[idx];
                            final isFound = item.status == 'FOUND_IN_BUS' || item.status == 'RETURNED_TO_OWNER';

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                                color: theme.cardColor,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item.itemCategory,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isFound ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isFound ? '✅ FOUND IN BUS' : '🔍 SEARCHING',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isFound ? Colors.green : Colors.orangeAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Bus: ${item.busName} (${item.busRegNumber}) • Reported by ${item.reporterName}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  if (widget.isCrew && !isFound) ...[
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          FleetState.instance.resolveLostItem(item.id, 'FOUND_IN_BUS', 'Found by conductor, kept at bus stand office');
                                          setState(() {});
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Item marked as FOUND. Passenger notified.')),
                                          );
                                        },
                                        icon: const Icon(Icons.check, size: 16),
                                        label: const Text('Mark as Found in Bus'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryGreen,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),

                  // Tab 2: Form
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Item Category',
                            border: OutlineInputBorder(),
                          ),
                          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v ?? _selectedCategory),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: _selectedBusReg,
                          decoration: const InputDecoration(
                            labelText: 'Bus Traveled In',
                            border: OutlineInputBorder(),
                          ),
                          items: FleetState.instance.buses
                              .map((b) => DropdownMenuItem(value: b.regNumber, child: Text('${b.busName} (${b.regNumber})')))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedBusReg = v),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _descController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Item Description & Seat Location',
                            hintText: 'e.g. Black Lenovo laptop bag left near rear window seats',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Your Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Contact Phone Number',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _submitReport,
                          icon: const Icon(Icons.send),
                          label: const Text('Submit Lost Item Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
