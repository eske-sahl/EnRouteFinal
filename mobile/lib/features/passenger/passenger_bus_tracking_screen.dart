import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../services/fleet_state.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/emergency_sos_dialog.dart';

class PassengerBusTrackingScreen extends StatefulWidget {
  final BusModel bus;

  const PassengerBusTrackingScreen({
    super.key,
    required this.bus,
  });

  /// Static helper to request location permission and launch live tracking screen
  static Future<void> startTracking(BuildContext context, BusModel bus) async {
    final hasPerm = await LocationService.instance.checkAndRequestPermission(context);
    if (!hasPerm) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device location permission required to track distance between you and the bus.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PassengerBusTrackingScreen(bus: bus),
        ),
      );
    }
  }

  @override
  State<PassengerBusTrackingScreen> createState() => _PassengerBusTrackingScreenState();
}

class _PassengerBusTrackingScreenState extends State<PassengerBusTrackingScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  Position? _passengerPosition;
  bool _isLoadingGps = true;
  StreamSubscription<Position>? _passengerStream;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initPassengerLocation();
    FleetState.instance.addListener(_onFleetUpdated);
  }

  void _onFleetUpdated() {
    if (mounted) setState(() {});
  }

  Future<void> _initPassengerLocation() async {
    setState(() {
      _isLoadingGps = true;
    });

    try {
      final pos = await LocationService.instance.getCurrentPosition();
      if (pos != null) {
        setState(() {
          _passengerPosition = pos;
          _isLoadingGps = false;
        });
        _fitPassengerAndBus();
      } else {
        // Fallback to default Kerala position if simulator has no GPS fix
        setState(() {
          _passengerPosition = Position(
            latitude: 10.0234,
            longitude: 76.3082,
            timestamp: DateTime.now(),
            accuracy: 5.0,
            altitude: 10.0,
            altitudeAccuracy: 1.0,
            heading: 0.0,
            headingAccuracy: 1.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          );
          _isLoadingGps = false;
        });
        _fitPassengerAndBus();
      }

      // Continuous stream for passenger device location
      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
      _passengerStream?.cancel();
      _passengerStream = Geolocator.getPositionStream(locationSettings: settings).listen(
        (Position updated) {
          if (mounted) {
            setState(() {
              _passengerPosition = updated;
            });
          }
        },
        onError: (_) {},
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGps = false;
        });
      }
    }
  }

  void _fitPassengerAndBus() {
    if (_passengerPosition == null) return;
    final bus = FleetState.instance.getBusByReg(widget.bus.regNumber) ?? widget.bus;

    final passengerLatLng = LatLng(_passengerPosition!.latitude, _passengerPosition!.longitude);
    final busLatLng = LatLng(bus.currentLatitude, bus.currentLongitude);

    final southWest = LatLng(
      math.min(passengerLatLng.latitude, busLatLng.latitude) - 0.015,
      math.min(passengerLatLng.longitude, busLatLng.longitude) - 0.015,
    );
    final northEast = LatLng(
      math.max(passengerLatLng.latitude, busLatLng.latitude) + 0.015,
      math.max(passengerLatLng.longitude, busLatLng.longitude) + 0.015,
    );

    final bounds = LatLngBounds(southWest, northEast);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      ),
    );
  }

  @override
  void dispose() {
    _passengerStream?.cancel();
    FleetState.instance.removeListener(_onFleetUpdated);
    _pulseCtrl.dispose();
    super.dispose();
  }

  double _computeDistanceMeters(BusModel bus) {
    if (_passengerPosition == null) return 0.0;
    return Geolocator.distanceBetween(
      _passengerPosition!.latitude,
      _passengerPosition!.longitude,
      bus.currentLatitude,
      bus.currentLongitude,
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatEta(double meters, double busSpeedKmh) {
    // Effective speed accounting for city traffic (minimum 25 km/h = ~416 m/min)
    final effectiveMpm = busSpeedKmh > 10 ? (busSpeedKmh * 1000 / 60) : 450.0;
    final minutes = (meters / effectiveMpm).ceil();
    if (minutes <= 1) {
      return 'Arriving now (< 1 min)';
    } else if (minutes <= 2) {
      return 'Arriving in ~2 mins';
    }
    return '~$minutes mins away';
  }

  Color _getCategoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('limited stop') || lower.contains('red')) {
      return const Color(0xFFD32F2F);
    } else if (lower.contains('city') || lower.contains('green')) {
      return const Color(0xFF2E7D32);
    }
    return const Color(0xFF1976D2);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBus = FleetState.instance.getBusByReg(widget.bus.regNumber) ?? widget.bus;
    final catColor = _getCategoryColor(activeBus.category);

    final distanceMeters = _computeDistanceMeters(activeBus);
    final distanceText = _formatDistance(distanceMeters);
    final etaText = _formatEta(distanceMeters, activeBus.speedKmh);

    final passengerLatLng = _passengerPosition != null
        ? LatLng(_passengerPosition!.latitude, _passengerPosition!.longitude)
        : LatLng(activeBus.currentLatitude, activeBus.currentLongitude);
    final busLatLng = LatLng(activeBus.currentLatitude, activeBus.currentLongitude);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Track ${activeBus.busName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.greenAccent, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      const Text('LIVE RADAR', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              '${activeBus.regNumber} • ${activeBus.routeName}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emergency, color: Colors.redAccent),
            tooltip: 'Emergency SOS (112)',
            onPressed: () => EmergencySosDialog.show(
              context,
              busRegNumber: activeBus.regNumber,
              busName: activeBus.busName,
              currentStop: activeBus.currentStop,
              latitude: activeBus.currentLatitude,
              longitude: activeBus.currentLongitude,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Location',
            onPressed: _initPassengerLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Fullscreen Interactive Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: busLatLng,
              initialZoom: 13.5,
              minZoom: 7,
              maxZoom: 18,
            ),
            children: [
              // Standard OSM Tile Layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.enroute.kerala.smartbus',
              ),

              // Connecting Polyline between Passenger and Bus
              if (_passengerPosition != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [passengerLatLng, busLatLng],
                      color: AppTheme.primaryGreen.withValues(alpha: 0.85),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),

              // Markers Layer: Passenger (You) and Bus
              MarkerLayer(
                markers: [
                  // Passenger Marker (You are here)
                  if (_passengerPosition != null)
                    Marker(
                      point: passengerLatLng,
                      width: 70,
                      height: 70,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade900,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: const Text('You', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 2),
                          AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (ctx, _) {
                              return Container(
                                width: 28 + (_pulseCtrl.value * 6),
                                height: 28 + (_pulseCtrl.value * 6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  border: Border.all(color: Colors.blue, width: 2),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                  // Conductor Live Bus Marker
                  Marker(
                    point: busLatLng,
                    width: 90,
                    height: 80,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: catColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                          ),
                          child: Text(
                            activeBus.busName,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: catColor, width: 3),
                            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                          ),
                          child: Icon(Icons.directions_bus_rounded, color: catColor, size: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Floating Action Controls (Recenter, Fit All)
          Positioned(
            top: 14,
            right: 14,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'recenter_fit_all',
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  onPressed: _fitPassengerAndBus,
                  tooltip: 'Fit Both You & Bus',
                  child: const Icon(Icons.center_focus_strong, size: 18),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'recenter_bus',
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: AppTheme.accentAmber,
                  onPressed: () => _mapController.move(busLatLng, 15.0),
                  tooltip: 'Center on Bus',
                  child: const Icon(Icons.directions_bus, size: 18),
                ),
                const SizedBox(height: 8),
                if (_passengerPosition != null)
                  FloatingActionButton.small(
                    heroTag: 'recenter_me',
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.blueAccent,
                    onPressed: () => _mapController.move(passengerLatLng, 15.0),
                    tooltip: 'Center on You',
                    child: const Icon(Icons.my_location, size: 18),
                  ),
              ],
            ),
          ),

          // 3. Zomato / Swiggy / Uber Style Live Telemetry Monitoring Card (Bottom)
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Proximity Banner (Zomato / Rapido style)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryGreen.withValues(alpha: 0.15),
                          Colors.blue.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.radar, color: AppTheme.primaryGreen, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'DISTANCE: $distanceText',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGreen),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accentAmber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            etaText,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.brown),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: activeBus.occupancyColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            activeBus.occupancyLabel,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: activeBus.occupancyColor),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Main Status & Approaching Stop
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.directions_bus, color: catColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeBus.isTripActive ? 'Bus is en route towards you' : 'Bus is in depot / standby',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Approaching: ${activeBus.nextStop}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Current stage: ${activeBus.currentStop} • Speed: ${activeBus.speedKmh.toStringAsFixed(0)} km/h',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 20),

                  // Crew Details & Live Conductor GPS Ping
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_pin, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'Crew: ${activeBus.conductorName}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            activeBus.isLiveGpsActive ? Icons.check_circle : Icons.gps_fixed,
                            size: 14,
                            color: activeBus.isLiveGpsActive ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            activeBus.isLiveGpsActive ? 'Conductor Device GPS Active' : 'Station Telemetry',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: activeBus.isLiveGpsActive ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isLoadingGps)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text('Acquiring device GPS location...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
