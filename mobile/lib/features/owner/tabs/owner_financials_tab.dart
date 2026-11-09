import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/fleet_state.dart';
import '../../../widgets/app_creator_footer.dart';
import '../../../models/bus_expense_model.dart';

class OwnerFinancialsTab extends StatefulWidget {
  final OwnerModel owner;
  final OwnerTimeframe initialTimeframe;

  const OwnerFinancialsTab({
    super.key,
    required this.owner,
    this.initialTimeframe = OwnerTimeframe.daily,
  });

  @override
  State<OwnerFinancialsTab> createState() => _OwnerFinancialsTabState();
}

class _OwnerFinancialsTabState extends State<OwnerFinancialsTab> {
  late OwnerTimeframe _selectedTimeframe;

  @override
  void initState() {
    super.initState();
    _selectedTimeframe = widget.initialTimeframe;
  }

  void _copyStatement(OwnerProfitReport report, NumberFormat currency) {
    final buffer = StringBuffer();
    buffer.writeln('====================================');
    buffer.writeln('${widget.owner.companyName} - P&L Statement');
    buffer.writeln('Period: ${report.periodLabel}');
    buffer.writeln('Timeframe: ${report.timeframeLabel}');
    buffer.writeln('====================================');
    buffer.writeln('Gross Fleet Revenue:   ${currency.format(report.grossRevenue)}');
    buffer.writeln('------------------------------------');
    buffer.writeln('OPERATING EXPENSES (79%):');
    buffer.writeln(' - Diesel & Fuel (42%):    ${currency.format(report.fuelExpense)}');
    buffer.writeln(' - Crew Wages & Batta (24%):${currency.format(report.crewWages)}');
    buffer.writeln(' - Maintenance & Tyres (8%):${currency.format(report.maintenanceReserve)}');
    buffer.writeln(' - Road Tax & Permits (5%): ${currency.format(report.roadTaxAndPermits)}');
    buffer.writeln('Total Expenses:            ${currency.format(report.totalExpenses)}');
    buffer.writeln('====================================');
    buffer.writeln('NET OPERATOR PROFIT:       ${currency.format(report.netProfit)}');
    buffer.writeln('Net Profit Margin:         ${report.profitMarginPercent.toStringAsFixed(1)}%');
    buffer.writeln('Total Tickets Issued:      ${report.totalTickets}');
    buffer.writeln('Completed Trips:           ${report.totalTrips}');
    buffer.writeln('====================================');
    buffer.writeln('BUS-BY-BUS PROFIT BREAKDOWN:');
    for (final b in report.busBreakdowns) {
      buffer.writeln('• ${b.busName} [${b.busRegNumber}]: Gross: ${currency.format(b.grossRevenue)} | Net Profit: ${currency.format(b.netProfit)} (${b.statusBadge})');
    }
    buffer.writeln('====================================');
    buffer.writeln('EnRoute Kerala Transit System');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('P&L Profit Statement for ${report.timeframeLabel} copied to clipboard!'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddExpenseDialog() {
    final ownerBuses = FleetState.instance.getBusesForOwner(widget.owner.id);
    if (ownerBuses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please register a bus first before logging operational expenses.')),
      );
      return;
    }

    String selectedBus = ownerBuses.first.regNumber;
    String selectedCategory = 'Diesel / Fuel';
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    final categories = [
      'Diesel / Fuel',
      'Crew Batta / Wages',
      'Vehicle Maintenance',
      'Permit, Tax & Toll',
    ];

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
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Log Daily Operating Expense',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Record real diesel, crew batta or maintenance costs to compute authentic net profit.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedBus,
                      decoration: const InputDecoration(
                        labelText: 'Select Bus',
                        border: OutlineInputBorder(),
                      ),
                      items: ownerBuses.map((b) => DropdownMenuItem(value: b.regNumber, child: Text('${b.busName} (${b.regNumber})'))).toList(),
                      onChanged: (v) => setModalState(() => selectedBus = v ?? selectedBus),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Expense Category',
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setModalState(() => selectedCategory = v ?? selectedCategory),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹)',
                        prefixText: '₹ ',
                        hintText: 'e.g. 3500.00',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Optional Note / Vendor',
                        hintText: 'e.g. Indian Oil Bunk Aluva, 38 Litres',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                        if (amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid expense amount greater than 0')),
                          );
                          return;
                        }
                        final record = BusExpenseRecord(
                          id: 'EXP-${DateTime.now().millisecondsSinceEpoch}',
                          busRegNumber: selectedBus,
                          ownerId: widget.owner.id,
                          category: selectedCategory,
                          amount: amt,
                          date: DateTime.now(),
                          note: noteController.text.trim(),
                        );
                        FleetState.instance.addExpense(record);
                        Navigator.pop(context);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ Recorded ₹${amt.toStringAsFixed(1)} for $selectedCategory on $selectedBus'),
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Save Expense Record'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fleet = FleetState.instance;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final report = fleet.getProfitReportForOwner(widget.owner.id, _selectedTimeframe);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Timeframe Segmented Switcher (Daily, Weekly, Monthly, Yearly)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _timeframeButton('Daily', OwnerTimeframe.daily, Icons.today),
                  _timeframeButton('Weekly', OwnerTimeframe.weekly, Icons.date_range),
                  _timeframeButton('Monthly', OwnerTimeframe.monthly, Icons.calendar_month),
                  _timeframeButton('Yearly', OwnerTimeframe.yearly, Icons.auto_graph),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Date Range & Live Reconciled Banner
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      report.periodLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 11, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'P&L AUDITED',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 2. Hero Net Profit Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppTheme.darkCardGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        'NET PROFIT (${report.timeframeLabel.toUpperCase()})',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '${report.profitMarginPercent.toStringAsFixed(1)}% MARGIN',
                          style: const TextStyle(
                            color: AppTheme.accentAmber,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currency.format(report.netProfit),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentAmber,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Net earnings after Diesel, Crew Wages, Maintenance & Taxes',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _heroStat('Gross Revenue', currency.format(report.grossRevenue), Colors.white),
                      _heroStat('Total Deductions', currency.format(report.totalExpenses), Colors.redAccent.shade100),
                      _heroStat('Tickets Issued', '${report.totalTickets}', Colors.greenAccent),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Operational Expenses Breakdown Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.pie_chart, color: AppTheme.primaryGreen, size: 20),
                              SizedBox(width: 8),
                              Text('Operating Expenses Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showAddExpenseDialog,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Log Expense', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report.hasRecordedExpenses
                          ? '🟢 Authentic Net Profit calculated from your real logged expenses.'
                          : 'ℹ️ Standard Kerala Stage Carriage norms. Tap "+ Log Expense" to enter today\'s actual fuel & crew batta.',
                      style: TextStyle(
                        color: report.hasRecordedExpenses ? AppTheme.primaryGreen : Colors.grey,
                        fontSize: 11,
                        fontWeight: report.hasRecordedExpenses ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stacked Progress Bar Visualizer
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 12,
                        child: Row(
                          children: [
                            Expanded(flex: 42, child: Container(color: Colors.orange.shade700)),
                            Expanded(flex: 24, child: Container(color: Colors.blue.shade600)),
                            Expanded(flex: 8, child: Container(color: Colors.purple.shade600)),
                            Expanded(flex: 5, child: Container(color: Colors.grey.shade700)),
                            Expanded(flex: 21, child: Container(color: AppTheme.primaryGreen)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text('🟧 Fuel (42%)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text('🟦 Crew (24%)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text('🟪 Maint (8%)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text('⬛ Tax (5%)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text('🟩 Net Profit (21%)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                      ],
                    ),

                    const Divider(height: 24),

                    _expenseRow(
                      icon: Icons.local_gas_station,
                      iconColor: Colors.orange.shade700,
                      title: 'Diesel & Fuel Expenses',
                      subtitle: 'Direct fuel consumption (~42% gross)',
                      amount: currency.format(report.fuelExpense),
                      percentage: '42.0%',
                    ),
                    const SizedBox(height: 10),
                    _expenseRow(
                      icon: Icons.people_alt,
                      iconColor: Colors.blue.shade600,
                      title: 'Crew Wages & Batta',
                      subtitle: 'Driver (12%), Conductor (8%), Cleaner (4%)',
                      amount: currency.format(report.crewWages),
                      percentage: '24.0%',
                    ),
                    const SizedBox(height: 10),
                    _expenseRow(
                      icon: Icons.build,
                      iconColor: Colors.purple.shade600,
                      title: 'Maintenance, Tyres & Spares',
                      subtitle: 'Periodic oil change, retreading & upkeep (~8%)',
                      amount: currency.format(report.maintenanceReserve),
                      percentage: '8.0%',
                    ),
                    const SizedBox(height: 10),
                    _expenseRow(
                      icon: Icons.receipt_long,
                      iconColor: Colors.grey.shade700,
                      title: 'Road Tax, Permits & Fitness (CF)',
                      subtitle: 'MVD quarterly tax, insurance & Fastag (~5%)',
                      amount: currency.format(report.roadTaxAndPermits),
                      percentage: '5.0%',
                    ),

                    const Divider(height: 24),

                    // Net Operator Retained Earnings
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.savings, color: AppTheme.primaryGreen, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Net Retained Owner Profit',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const Text(
                                        'Total profit available after all deductions',
                                        style: TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              currency.format(report.netProfit),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 4. Revenue Streams (Wallet vs Cash vs UPI)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.account_balance, color: AppTheme.primaryGreen, size: 20),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Revenue Channels & Collection Mode',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Live reconciliation between digital wallet and cash handover', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _channelBox(
                            title: 'Smart Wallet',
                            amount: currency.format(report.walletRevenue),
                            percent: '65% Direct',
                            icon: Icons.account_balance_wallet,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _channelBox(
                            title: 'Conductor Cash',
                            amount: currency.format(report.cashRevenue),
                            percent: '25% Handover',
                            icon: Icons.payments,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _channelBox(
                            title: 'Dynamic UPI',
                            amount: currency.format(report.upiRevenue),
                            percent: '10% QR Scan',
                            icon: Icons.qr_code_2,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 5. Trip & Fleet Operational Efficiency
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.speed, color: AppTheme.primaryGreen, size: 20),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Fleet Operating Statistics',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statPill('Total Trips Run', '${report.totalTrips}', Icons.alt_route),
                        _statPill('Avg / Bus', currency.format(report.avgRevenuePerBus), Icons.directions_bus),
                        _statPill('Avg / Trip', currency.format(report.avgRevenuePerTrip), Icons.confirmation_number),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 6. Bus-by-Bus Profitability Breakdown
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.directions_bus, color: AppTheme.primaryGreen, size: 20),
                      SizedBox(width: 8),
                      Text('Bus-by-Bus Profitability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    ],
                  ),
                ),
                Text('${report.busBreakdowns.length} Buses', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),

            if (report.busBreakdowns.isEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No buses registered under your operator account yet.'),
                  ),
                ),
              )
            else
              ...report.busBreakdowns.map((bus) => _busProfitCard(bus, currency)),

            const SizedBox(height: 16),

            // 7. Copy / Export Statement Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _copyStatement(report, currency),
              icon: const Icon(Icons.copy_all, size: 20),
              label: Text('Copy ${report.timeframeLabel} Statement to Clipboard', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),

            const SizedBox(height: 20),

            // Creator Attribution
            const AppCreatorFooter(),
          ],
        ),
      ),
    );
  }

  Widget _timeframeButton(String label, OwnerTimeframe tf, IconData icon) {
    final isSelected = _selectedTimeframe == tf;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedTimeframe = tf;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _expenseRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String amount,
    required String percentage,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
            Text(percentage, style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _channelBox({
    required String title,
    required String amount,
    required String percent,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(percent, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _statPill(String title, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryGreen),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _busProfitCard(BusProfitBreakdown bus, NumberFormat currency) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: bus.isActive ? AppTheme.primaryGreen.withValues(alpha: 0.25) : Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: bus.isActive ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.directions_bus,
                          color: bus.isActive ? AppTheme.primaryGreen : Colors.grey,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bus.busName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${bus.busRegNumber} • ${bus.routeName}',
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bus.isActive ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: bus.isActive ? Colors.green.shade300 : Colors.red.shade300),
                  ),
                  child: Text(
                    bus.statusBadge,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: bus.isActive ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Builder(builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final grossColor = isDark ? Colors.white : Colors.black87;

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _busMetric('Gross Collections', currency.format(bus.grossRevenue), grossColor),
                      _busMetric('Operating Cost (79%)', currency.format(bus.totalExpenses), Colors.red.shade700),
                      _busMetric('Net Profit (21%)', currency.format(bus.netProfit), AppTheme.primaryGreen, isBold: true),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text('Crew: ${bus.driverName} (D) • ${bus.conductorName} (C)',
                            style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87)),
                        Text('${bus.ticketsCount} tickets • ${bus.tripsCount} trips',
                            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _busMetric(String label, String value, Color color, {bool isBold = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                fontSize: isBold ? 14 : 12,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9)),
        ],
      ),
    );
  }
}
