import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/fleet_state.dart';
import '../../../services/qr_security_service.dart';
import '../../../widgets/app_creator_footer.dart';
import '../../../widgets/upi_payment_dialog.dart';

class DashboardTab extends StatefulWidget {
  final PassengerModel passenger;
  final Function(double) onTopUp;
  final VoidCallback? onViewAllTickets;

  const DashboardTab({
    super.key,
    required this.passenger,
    required this.onTopUp,
    this.onViewAllTickets,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  Timer? _rotationTimer;
  int _secondsLeft = 60;
  late String _currentSignedQr;

  @override
  void initState() {
    super.initState();
    _refreshQr();
    _rotationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft <= 1) {
          _refreshQr();
        } else {
          _secondsLeft--;
        }
      });
    });
  }

  void _refreshQr() {
    _secondsLeft = 60;
    _currentSignedQr = QrSecurityService.instance.generateSignedPassengerQr(widget.passenger.id);
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  void _showTopUpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetCtx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add Money via Dynamic UPI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Select an amount to generate your Google Pay / UPI QR:', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [50.0, 100.0, 200.0, 500.0].map((amt) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(bottomSheetCtx);
                      UpiPaymentDialog.show(
                        context: context,
                        amount: amt,
                        title: 'UPI Wallet Recharge',
                        subtitle: 'Payee: ${UpiPaymentDialog.payeeName} (EnRoute Wallet)',
                        transactionNote: 'EnRoute Wallet Recharge for ${widget.passenger.name}',
                        confirmButtonText: 'I Have Paid • Credit ₹${amt.toInt()}',
                        onPaymentConfirmed: () {
                          widget.onTopUp(amt);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.greenAccent),
                                  const SizedBox(width: 8),
                                  Text('₹${amt.toInt()} added to Smart Wallet via UPI!'),
                                ],
                              ),
                              backgroundColor: AppTheme.darkSlate,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      );
                    },
                    child: Text('₹${amt.toInt()}'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  void _showQrFullscreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Passenger Identity Pass', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('${widget.passenger.name} • ${widget.passenger.concessionCategory}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.5), width: 2),
                      ),
                      child: QrImageView(
                        data: _currentSignedQr,
                        version: QrVersions.auto,
                        size: 220.0,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shield, size: 14, color: AppTheme.primaryGreen),
                        const SizedBox(width: 6),
                        Text(
                          'Dynamic Rotating Pass (${_secondsLeft}s left)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Cryptographically signed • Screenshots expire automatically',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
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

  void _showTicketDetails(BuildContext context, IssuedTicketModel ticket) {
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.confirmation_num, color: AppTheme.primaryGreen, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Digital Bus Ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(ticket.ticketNumber, style: const TextStyle(fontFamily: 'monospace', color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: const Text('PAID & VALID', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Bus & Route
              _ticketRow('Bus Vehicle', '${ticket.busName} (${ticket.busRegNumber})'),
              _ticketRow('Boarding Stop', ticket.boardingStop),
              _ticketRow('Destination Stop', ticket.destinationStop),
              _ticketRow('Issued At', fmt.format(ticket.timestamp)),
              _ticketRow('Passenger ID', ticket.passengerId),
              _ticketRow('Concession Category', ticket.isStudentConcession ? 'Student Concession (₹5 Concession)' : 'General Fare'),
              _ticketRow('Payment Mode', ticket.paymentModeLabel),
              if (ticket.cashTendered != null && ticket.cashTendered! > 0)
                _ticketRow('Cash Handed', '₹${ticket.cashTendered!.toStringAsFixed(1)} (Change: ₹${(ticket.cashChangeGiven ?? 0).toStringAsFixed(1)})'),
              if (ticket.isSplitPayment)
                _ticketRow('Split Breakdown', 'Cash: ₹${ticket.splitCashAmount?.toStringAsFixed(1)} + UPI: ₹${ticket.splitUpiAmount?.toStringAsFixed(1)}'),
              _ticketRow('Conductor Crew', ticket.conductorName),

              const Divider(height: 24),

              // Total Fare Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Fare Paid', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      '₹${ticket.fare.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ticketRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    // Fetch ONLY tickets issued for this specific passenger
    final issuedTickets = FleetState.instance.getTicketsForPassenger(widget.passenger.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Wallet Balance Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppTheme.busGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('DIGITAL TRANSIT WALLET',
                        style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('ACTIVE', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  currency.format(widget.passenger.walletBalance),
                  style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showTopUpSheet(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Money'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showTopUpSheet(context),
                      icon: const Icon(Icons.bolt, size: 18),
                      label: const Text('Quick Recharge'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. Personal Scanner / Dynamic Cryptographic QR Code Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              children: [
                                const Text('Personal Digital Pass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${_secondsLeft}s',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                  ),
                                ),
                              ],
                            ),
                            const Text('Dynamic rotating token • Defeats screenshots',
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
                        tooltip: 'Rotate Pass Now',
                        onPressed: () => setState(() => _refreshQr()),
                      ),
                      IconButton(
                        icon: const Icon(Icons.fullscreen, color: AppTheme.primaryGreen),
                        tooltip: 'Enlarge QR',
                        onPressed: () => _showQrFullscreen(context),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  GestureDetector(
                    onTap: () => _showQrFullscreen(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4), width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: _currentSignedQr,
                        version: QrVersions.auto,
                        size: 150.0,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.passenger.id,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 3. Ticket History Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text('Recent Ticket History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              if (widget.onViewAllTickets != null)
                InkWell(
                  onTap: widget.onViewAllTickets,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View More (${issuedTickets.length})',
                          style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.arrow_forward_ios, size: 11, color: AppTheme.primaryGreen),
                      ],
                    ),
                  ),
                )
              else
                Text('${issuedTickets.length} journeys', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),

          if (issuedTickets.isEmpty)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: const Padding(
                padding: EdgeInsets.all(28.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.confirmation_num_outlined, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No tickets issued yet.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            )
          else
            ...issuedTickets.take(4).map((ticket) {
              final dateStr = DateFormat('dd MMM, hh:mm a').format(ticket.timestamp);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: ListTile(
                  onTap: () => _showTicketDetails(context, ticket),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.confirmation_num, color: AppTheme.primaryGreen),
                  ),
                  title: Text(
                    '${ticket.boardingStop} ➔ ${ticket.destinationStop}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${ticket.busRegNumber} (${ticket.busName}) • $dateStr',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${ticket.fare.toStringAsFixed(1)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 15),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ticket.paymentMode,
                          style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 10),
          const AppCreatorFooter(),
        ],
      ),
    );
  }
}

