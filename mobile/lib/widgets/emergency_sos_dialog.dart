import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/fleet_state.dart';
import '../theme/app_theme.dart';

/// Comprehensive Emergency Assistance & SOS Dialog
/// Complies with Kerala Motor Vehicles & National Emergency guidelines (CMVR / 112).
class EmergencySosDialog extends StatelessWidget {
  final String? busRegNumber;
  final String? busName;
  final String? currentStop;
  final double? latitude;
  final double? longitude;

  const EmergencySosDialog({
    super.key,
    this.busRegNumber,
    this.busName,
    this.currentStop,
    this.latitude,
    this.longitude,
  });

  static void show(
    BuildContext context, {
    String? busRegNumber,
    String? busName,
    String? currentStop,
    double? latitude,
    double? longitude,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => EmergencySosDialog(
        busRegNumber: busRegNumber,
        busName: busName,
        currentStop: currentStop,
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  void _shareEmergencyDetails(BuildContext context) {
    final reg = busRegNumber ?? 'Public Bus';
    final name = busName ?? '';
    final stop = currentStop ?? 'Unknown Location';
    final coords = (latitude != null && longitude != null)
        ? 'GPS: $latitude, $longitude (https://maps.google.com/?q=$latitude,$longitude)'
        : 'GPS: Live on EnRoute';

    final emergencyMessage =
        '🚨 EMERGENCY ALERT: I need immediate assistance on bus $name ($reg). Current Stage: $stop. $coords. Sent via EnRoute Kerala Emergency SOS.';

    Clipboard.setData(ClipboardData(text: emergencyMessage));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Emergency details copied to clipboard! Ready to paste into SMS or WhatsApp.'),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? const Color(0xFF1E1010) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emergency_outlined, color: Colors.red, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency SOS',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      Text(
                        'അടിയന്തര സഹായം • 24x7 Assistance',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 28),

            // Bus info chip if available
            if (busRegNumber != null && busRegNumber!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_bus, color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${busName ?? 'Bus'} • $busRegNumber\nNear: ${currentStop ?? 'Kerala Route'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Direct Call Actions
            _buildCallTile(
              context,
              number: '112',
              title: 'National Emergency Helpline (112)',
              subtitle: 'Police, Ambulance & Fire Rescue',
              color: Colors.red,
            ),
            const SizedBox(height: 10),
            _buildCallTile(
              context,
              number: '1091',
              title: 'Kerala Women Helpline (1091)',
              subtitle: 'Dedicated women safety assistance',
              color: Colors.purple,
            ),
            const SizedBox(height: 10),
            _buildCallTile(
              context,
              number: '1800-425-4740',
              title: 'Kerala Motor Vehicles Dept (MVD)',
              subtitle: 'Transport grievance & complaint cell',
              color: Colors.blueGrey,
            ),

            const SizedBox(height: 16),

            // Share Location & Bus Info Button
            ElevatedButton.icon(
              onPressed: () => _shareEmergencyDetails(context),
              icon: const Icon(Icons.share_location, color: Colors.white),
              label: const Text('Share Location & Bus Reg via SMS/WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallTile(
    BuildContext context, {
    required String number,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: number));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📞 Helpline number $number copied to dialer!'),
            backgroundColor: color,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(Icons.phone, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                number,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
