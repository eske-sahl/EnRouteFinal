import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../services/fleet_state.dart';
import '../../../widgets/app_creator_footer.dart';
import '../../../widgets/app_settings_section.dart';
import '../../../widgets/emergency_sos_dialog.dart';
import '../../../widgets/lost_and_found_dialog.dart';

class ConductorProfileTab extends StatefulWidget {
  final ConductorModel conductor;
  final VoidCallback onLogout;

  const ConductorProfileTab({
    super.key,
    required this.conductor,
    required this.onLogout,
  });

  @override
  State<ConductorProfileTab> createState() => _ConductorProfileTabState();
}

class _ConductorProfileTabState extends State<ConductorProfileTab> {
  void _showReviewsModal() {
    setState(() {
      FleetState.instance.markReviewsAsReadForConductor(widget.conductor.assignedBusReg);
    });

    final reviews = FleetState.instance.reviews
        .where((r) => r.busRegNumber == widget.conductor.assignedBusReg)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollCtrl) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ListView(
                controller: scrollCtrl,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.star, color: AppTheme.accentAmber),
                          SizedBox(width: 8),
                          Text('Passenger Reviews & Ratings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        ],
                      ),
                      Text('${reviews.length} reviews', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Direct feedback submitted by passengers for ${widget.conductor.assignedBusName}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const Divider(height: 24),

                  if (reviews.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: const Column(
                        children: [
                          Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 10),
                          Text('No passenger reviews yet for this bus.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  else
                    ...reviews.map((r) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                        child: Text(
                                          r.passengerName.isNotEmpty ? r.passengerName[0] : 'P',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryGreen),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(r.passengerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                  Row(
                                    children: List.generate(5, (starIdx) {
                                      return Icon(
                                        starIdx < r.rating.round() ? Icons.star : Icons.star_border,
                                        color: AppTheme.accentAmber,
                                        size: 16,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('"${r.comment}"', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(r.busName, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  Text(DateFormat('dd MMM, hh:mm a').format(r.createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bus = FleetState.instance.getBusByReg(widget.conductor.assignedBusReg);
    final unreadReviews = FleetState.instance.getUnreadReviewsCountForConductor(widget.conductor.assignedBusReg);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conductor Profile Header
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppTheme.darkCardGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  child: const Icon(Icons.qr_code_scanner, color: AppTheme.accentAmber, size: 38),
                ),
                const SizedBox(height: 12),
                Text(widget.conductor.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Badge: ${widget.conductor.licenseNumber}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    'Assigned Bus: ${widget.conductor.assignedBusName} (${widget.conductor.assignedBusReg})',
                    style: const TextStyle(color: AppTheme.accentAmber, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(color: Colors.white12, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _headerMetric('Login ID', widget.conductor.userId),
                    _headerMetric('Mobile Phone', widget.conductor.phone),
                    _headerMetric('Shift Revenue', '₹${widget.conductor.todayCollection.toStringAsFixed(0)}'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Options Menu List
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                // 1. REVIEWS & PASSENGER RATINGS (WITH UNREAD NOTIFICATION BADGE)
                ListTile(
                  leading: const Icon(Icons.star_rate, color: AppTheme.accentAmber),
                  title: const Text('Passenger Reviews & Ratings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('View ratings and feedback submitted by passengers'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (unreadReviews > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                          child: Text('$unreadReviews New', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  onTap: _showReviewsModal,
                ),
                const Divider(height: 1),

                // 2. Assigned Bus Specifications & Owner Details
                ListTile(
                  leading: const Icon(Icons.directions_bus, color: AppTheme.primaryGreen),
                  title: const Text('Assigned Bus Specifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${bus?.busName} • Owner: ${bus?.ownerName} (${bus?.ownerPhone})'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text('${bus?.busName} Specs'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reg Plate: ${bus?.regNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Category: ${bus?.category}'),
                            Text('Route: ${bus?.routeName}'),
                            Text('Owner: ${bus?.ownerName} (${bus?.ownerPhone})'),
                            Text('Owner Email: ${bus?.ownerEmail}'),
                            Text('Seating Capacity: ${bus?.seatingCapacity} Seats'),
                          ],
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),

                // 3. Device Location & GPS Broadcast Settings
                ListTile(
                  leading: const Icon(Icons.gps_fixed, color: Colors.blue),
                  title: const Text('Device GPS Telemetry Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Automatic live location broadcast active for passengers & owner'),
                  trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                ),
                const Divider(height: 1),

                // 4. Lost & Found Reporting Desk
                ListTile(
                  leading: const Icon(Icons.luggage, color: Colors.teal),
                  title: const Text('Lost & Found Desk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Review items left behind or mark passengers\' lost items as recovered'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => LostAndFoundDialog.show(
                    context,
                    busRegNumber: widget.conductor.assignedBusReg,
                    busName: widget.conductor.assignedBusName,
                    contactPhone: widget.conductor.phone,
                  ),
                ),
                const Divider(height: 1),

                // 5. Emergency Assistance SOS (112)
                ListTile(
                  leading: const Icon(Icons.emergency, color: Colors.red),
                  title: const Text('Emergency SOS Assistance (112)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
                  subtitle: const Text('National Emergency, Kerala Women Helpline & MVD Desk'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => EmergencySosDialog.show(
                    context,
                    busRegNumber: widget.conductor.assignedBusReg,
                    busName: widget.conductor.assignedBusName,
                  ),
                ),
                const Divider(height: 1),

                // 6. Conductor Badge & Kerala MVD Guidelines
                ListTile(
                  leading: const Icon(Icons.verified_user, color: Colors.blueGrey),
                  title: const Text('MVD Kerala Conductor Guidelines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Uniform badge, student concessions & spot ticketing norms'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kerala Motor Vehicle Department (MVD) rules compliant.')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // App Settings & Preferences with Data Management
          AppSettingsSection(
            additionalOptions: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_forever, color: Colors.red, size: 22),
                ),
                title: const Text('Delete Conductor Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Permanently remove this conductor profile & credentials', style: TextStyle(fontSize: 12, color: Colors.grey)),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _confirmDeleteAccount(context),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Sign Out Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('End conductor terminal session'),
              onTap: widget.onLogout,
            ),
          ),
          const SizedBox(height: 10),
          const AppCreatorFooter(),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Delete Conductor Account?', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete the conductor profile for ${widget.conductor.name} (${widget.conductor.userId})?'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'Badge ${widget.conductor.licenseNumber} and authorization to issue tickets on ${widget.conductor.assignedBusName} (${widget.conductor.assignedBusReg}) will be removed.',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade900, fontWeight: FontWeight.w500),
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
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                FleetState.instance.deleteConductor(widget.conductor.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Conductor profile for ${widget.conductor.name} has been deleted.'),
                    backgroundColor: Colors.red.shade800,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                widget.onLogout();
              },
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );
  }

  Widget _headerMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }
}
