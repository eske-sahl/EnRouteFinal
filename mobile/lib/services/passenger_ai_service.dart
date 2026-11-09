import 'dart:math';
import 'package:flutter/material.dart';
import 'fleet_state.dart';

class AiQuickAction {
  final String label;
  final IconData icon;
  final String query;

  AiQuickAction({
    required this.label,
    required this.icon,
    required this.query,
  });
}

class AiMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? highlightBullets;
  final List<BusStopSchedule>? scheduleList;
  final String? busName;
  final String? busRegNumber;
  final String? routeTitle;
  final double? estimatedFare;
  final List<String>? quickSuggestions;
  final List<AiQuickAction>? quickActions;

  AiMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.highlightBullets,
    this.scheduleList,
    this.busName,
    this.busRegNumber,
    this.routeTitle,
    this.estimatedFare,
    this.quickSuggestions,
    this.quickActions,
  });
}

class PassengerAiService {
  PassengerAiService._();
  static final PassengerAiService instance = PassengerAiService._();

  List<String> getSuggestedPrompts() {
    return [
      'Full list of Sana bus timings',
      'I want to go from Mannarkad to Kozhikkode, what should I do?',
      'I don’t have any previous experience of bus journey, what should I do?',
      'How to go from Farook College to West Hill?',
      'What is the fare from Mannarkad to Kozhikkode?',
      'Which buses are running right now?',
      'How do I use and recharge my Smart Wallet?',
    ];
  }

  Future<AiMessage> processQuery(String rawQuery, {PassengerModel? passenger}) async {
    // Artificial micro-delay for realistic AI thinking animation
    await Future.delayed(const Duration(milliseconds: 350));

    final query = rawQuery.trim().toLowerCase();
    final now = DateTime.now();
    final id = 'AI-${now.millisecondsSinceEpoch}-${Random().nextInt(9999)}';

    // 1. BEGINNER / FIRST TIME BUS JOURNEY GUIDE
    if (_isBeginnerGuideQuery(query)) {
      return _buildBeginnerGuideResponse(id, now, passenger);
    }

    // 2. BUS TIMINGS / SCHEDULE QUERY
    if (_isTimingsQuery(query)) {
      final bus = _findMatchingBus(query);
      if (bus != null) {
        return _buildBusTimingsResponse(id, now, bus);
      } else {
        return _buildAllBusesTimingsOverview(id, now);
      }
    }

    // 3. JOURNEY PLANNER ("I want to go from there to there, what should i do")
    if (_isJourneyQuery(query)) {
      return _buildJourneyResponse(id, now, query, passenger);
    }

    // 4. FARE & TICKET MATRIX INQUIRY
    if (_isFareQuery(query)) {
      return _buildFareResponse(id, now, query, passenger);
    }

    // 5. LIVE RUNNING STATUS INQUIRY
    if (_isLiveStatusQuery(query)) {
      return _buildLiveStatusResponse(id, now);
    }

    // 6. WALLET, BALANCE & RECHARGE INQUIRY
    if (_isWalletQuery(query)) {
      return _buildWalletResponse(id, now, passenger);
    }

    // 7. COMPLAINTS, SAFETY & MVD HELPLINE
    if (_isSafetyQuery(query)) {
      return _buildSafetyResponse(id, now);
    }

    // 8. SPECIFIC BUS NAME MENTIONED WITHOUT TIMING KEYWORD
    final directBus = _findMatchingBus(query);
    if (directBus != null) {
      return _buildBusTimingsResponse(id, now, directBus);
    }

    // 9. GENERAL TRANSIT ASSISTANT FALLBACK
    return _buildGeneralFallbackResponse(id, now, rawQuery, passenger);
  }

  // ==========================================
  // QUERY INTENT DETECTORS
  // ==========================================

  bool _isBeginnerGuideQuery(String q) {
    final matchesExperience = q.contains('experience') ||
        q.contains('first time') ||
        q.contains('never') ||
        q.contains('beginner') ||
        q.contains('new to bus') ||
        q.contains('aadyam') ||
        q.contains('first bus') ||
        q.contains('dont know how to travel') ||
        q.contains("don't have any previous experience");

    final matchesBusContext = q.contains('bus') ||
        q.contains('journey') ||
        q.contains('destination') ||
        q.contains('reach') ||
        q.contains('travel') ||
        q.contains('what should i do');

    return matchesExperience && matchesBusContext;
  }

  bool _isTimingsQuery(String q) {
    return q.contains('timing') ||
        q.contains('timings') ||
        q.contains('schedule') ||
        q.contains('time table') ||
        q.contains('timetable') ||
        q.contains('what time') ||
        q.contains('when will') ||
        q.contains('arrival') ||
        q.contains('departure') ||
        q.contains('full list of') ||
        q.contains('stops list');
  }

  bool _isJourneyQuery(String q) {
    return q.contains('go from') ||
        q.contains('from there to there') ||
        q.contains('how to reach') ||
        q.contains('how to go') ||
        q.contains('reach from') ||
        q.contains('route from') ||
        q.contains('travel to') ||
        q.contains('direction') ||
        q.contains('what should i do to reach') ||
        (q.contains('to') && (q.contains('want to go') || q.contains('how can i go')));
  }

  bool _isFareQuery(String q) {
    return q.contains('fare') ||
        q.contains('ticket price') ||
        q.contains('charge') ||
        q.contains('cost') ||
        q.contains('how much') ||
        q.contains('concession rate');
  }

  bool _isLiveStatusQuery(String q) {
    return q.contains('running now') ||
        q.contains('running right now') ||
        q.contains('live status') ||
        q.contains('where is') ||
        q.contains('current location') ||
        q.contains('active bus') ||
        q.contains('gps');
  }

  bool _isWalletQuery(String q) {
    return q.contains('wallet') ||
        q.contains('recharge') ||
        q.contains('balance') ||
        q.contains('top up') ||
        q.contains('smart pass') ||
        q.contains('refund') ||
        q.contains('cash change');
  }

  bool _isSafetyQuery(String q) {
    return q.contains('emergency') ||
        q.contains('complaint') ||
        q.contains('lost') ||
        q.contains('mvd') ||
        q.contains('police') ||
        q.contains('helpline') ||
        q.contains('safety') ||
        q.contains('women helpline');
  }

  BusModel? _findMatchingBus(String q) {
    final buses = FleetState.instance.buses;
    for (final b in buses) {
      final name = b.busName.toLowerCase();
      final reg = b.regNumber.toLowerCase().replaceAll(' ', '');
      final cleanReg = b.regNumber.toLowerCase();
      final cleanQ = q.replaceAll(' ', '');

      if (q.contains(name) ||
          cleanQ.contains(reg) ||
          q.contains(cleanReg) ||
          (name.contains('sana') && (q.contains('sana') || q.contains('speedwings') || q.contains('speed'))) ||
          (name.contains('arafa') && (q.contains('arafa') || q.contains('greencity') || q.contains('green'))) ||
          (name.contains('sanha') && (q.contains('sanha') || q.contains('city rider') || q.contains('rider'))) ||
          (name.contains('kkb') && q.contains('kkb')) ||
          (name.contains('eske') && q.contains('eske'))) {
        return b;
      }
    }
    return null;
  }

  // ==========================================
  // RESPONSE BUILDERS
  // ==========================================

  AiMessage _buildBeginnerGuideResponse(String id, DateTime now, PassengerModel? passenger) {
    final passengerName = passenger?.name ?? 'Traveler';
    final text = StringBuffer()
      ..writeln('👋 **Hello $passengerName! Welcome to Kerala Bus Travel.**')
      ..writeln('')
      ..writeln('Traveling by bus in Kerala is comfortable, safe, and very easy once you know these essential steps:')
      ..writeln('')
      ..writeln('1️⃣ **Locate Your Bus Stop**')
      ..writeln('• Stand at the official bus waiting shed or stand along the correct side of the road facing your travel direction.')
      ..writeln('')
      ..writeln('2️⃣ **Spotting Your Bus & Route Colors**')
      ..writeln('• Look at the front LED / glass destination board (displayed in Malayalam & English).')
      ..writeln('• Notice the Kerala color classification:')
      ..writeln('  - 🔴 **Red-Whiteline**: Limited Stop (Faster, skips minor stops).')
      ..writeln('  - 🔵 **Blue-Whiteline**: Ordinary Stage Carriage (Stops at all official stages).')
      ..writeln('  - 🟢 **Green-Whiteline**: City Bus (Frequent city connection).')
      ..writeln('')
      ..writeln('3️⃣ **Signaling & Boarding Safely**')
      ..writeln('• As the bus approaches, raise your hand or give a clear polite wave to signal the driver.')
      ..writeln('• Wait until the bus comes to a **complete halt** before stepping onto the footboard.')
      ..writeln('• Ladies and senior citizens usually enter through the rear door; general boarding is at both entrances.')
      ..writeln('')
      ..writeln('4️⃣ **Ticketing & Payment**')
      ..writeln('• Once inside, the conductor (wearing a khaki uniform) will approach with an electronic ticketing machine.')
      ..writeln('• Say your destination stop clearly (e.g., *"Aluva"*, *"Perumbavoor"*, or *"Menaka"*).')
      ..writeln('• **Payment Methods Available**:')
      ..writeln('  - 💳 **EnRoute Smart Transit Wallet**: Tell the conductor "Smart Wallet" or show your ticket barcode for instant cashless debit.')
      ..writeln('  - 📱 **UPI QR**: Ask to scan the conductor’s dynamic UPI QR code.')
      ..writeln('  - 💵 **Cash**: Hand over cash; change can be received in cash or auto-credited to your EnRoute Wallet.')
      ..writeln('')
      ..writeln('5️⃣ **During Your Journey & Live Tracking**')
      ..writeln('• Find a seat or hold overhead grab rails securely.')
      ..writeln('• Use this EnRoute app to track the bus\'s live GPS and watch stops arrive in real time.')
      ..writeln('• The conductor will also loudly call out upcoming major stages.')
      ..writeln('')
      ..writeln('6️⃣ **Getting Down at Your Destination**')
      ..writeln('• Move towards the exit door 1–2 minutes before your stop.')
      ..writeln('• The conductor rings the bell cord (one bell = prepare to stop, two bells = start).')
      ..writeln('• Step down onto the curb facing forward with your left foot first after the bus has stopped completely.')
      ..writeln('')
      ..writeln('🌟 *Have a safe and pleasant journey! Feel free to ask me for any bus timings or route directions!*');

    return AiMessage(
      id: id,
      text: text.toString(),
      isUser: false,
      timestamp: now,
      highlightBullets: [
        'Board only after the bus stops completely',
        'State your destination clearly to the conductor',
        'EnRoute Smart Wallet allows instant contactless payment',
        'Watch live GPS updates inside this app during the ride',
      ],
      quickSuggestions: [
        'Full list of ${_sampleBusName()} bus timings',
        'I want to go from Aluva to Perumbavoor',
        'How to go from Kaloor to Thoppumpady',
        'What is the fare from Aluva to Kizhakkambalam?',
      ],
      quickActions: [
        AiQuickAction(label: 'Search Routes', icon: Icons.search, query: 'Search all routes'),
        AiQuickAction(label: 'Open Wallet', icon: Icons.account_balance_wallet, query: 'Show wallet balance'),
      ],
    );
  }

  AiMessage _buildBusTimingsResponse(String id, DateTime now, BusModel bus) {
    final text = StringBuffer()
      ..writeln('🚍 **Timetable for ${bus.busName} (${bus.regNumber})**')
      ..writeln('')
      ..writeln('📍 **Route**: ${bus.routeName}')
      ..writeln('🎨 **Service Type**: ${bus.category} • ${bus.seatingCapacity} Seats')
      ..writeln('🏢 **Operator**: ${bus.companyName}')
      ..writeln('👨‍✈️ **Crew**: Driver: ${bus.driverName} • Conductor: ${bus.conductorName} (${bus.conductorPhone})')
      ..writeln('⚡ **Live Status**: ${bus.isActive ? "🟢 Running on Route" : "🔴 In Depot / Resting"}')
      ..writeln('📍 **Current Stage**: ${bus.currentStop} • **Next**: ${bus.nextStop}')
      ..writeln('')
      ..writeln('⏱️ **Complete Stop-by-Stop Schedule**:');

    for (int i = 0; i < bus.stops.length; i++) {
      final s = bus.stops[i];
      final isFirst = i == 0;
      final isLast = i == bus.stops.length - 1;
      final badge = isFirst ? ' (Origin / Starts)' : (isLast ? ' (Terminal Stop)' : '');
      text.writeln('  ${i + 1}. **${s.stopName}** — `${s.time}`$badge');
    }

    text
      ..writeln('')
      ..writeln('💡 *Tip: Ordinary and Limited Stop buses adhere to MVD Kerala time-table permits. You can track this bus live on map or pay with EnRoute Smart Wallet.*');

    return AiMessage(
      id: id,
      text: text.toString(),
      isUser: false,
      timestamp: now,
      busName: bus.busName,
      busRegNumber: bus.regNumber,
      routeTitle: bus.routeName,
      scheduleList: bus.stops,
      quickSuggestions: [
        'I want to go from ${bus.startPoint} to ${bus.destPoint}, what should I do?',
        'What is the fare on ${bus.busName}?',
        'Call conductor ${bus.conductorName}',
        'Show all other buses running',
      ],
      quickActions: [
        AiQuickAction(label: 'Track on Map', icon: Icons.navigation, query: 'Track ${bus.busName} live'),
        AiQuickAction(label: 'View Route', icon: Icons.alt_route, query: 'Show route ${bus.busName}'),
      ],
    );
  }

  AiMessage _buildAllBusesTimingsOverview(String id, DateTime now) {
    final buses = FleetState.instance.buses;
    final text = StringBuffer()
      ..writeln('📋 **EnRoute Kerala Fleet Timetable Overview**')
      ..writeln('')
      ..writeln('Here are the registered stage carriages and their primary departure schedules:')
      ..writeln('');

    for (int i = 0; i < buses.length; i++) {
      final b = buses[i];
      final firstStop = b.stops.isNotEmpty ? b.stops.first : null;
      final timeStr = firstStop != null ? firstStop.time : 'Scheduled';
      text.writeln('${i + 1}. **${b.busName}** (`${b.regNumber}`)');
      text.writeln('   • **Route**: ${b.startPoint} ➔ ${b.destPoint}');
      text.writeln('   • **First Departure**: `$timeStr` at ${b.startPoint}');
      text.writeln('   • **Type**: ${b.category}');
      text.writeln('   • **Status**: ${b.isActive ? "🟢 Running Now" : "🟡 Depot / Stand"}');
      text.writeln('');
    }

    text.writeln('💬 *To see the full stop-by-stop schedule for any bus, just ask: "Timings for Sana" or tap a suggestion below!*');

    return AiMessage(
      id: id,
      text: text.toString(),
      isUser: false,
      timestamp: now,
      quickSuggestions: buses.map((b) => 'Full list of ${b.busName} timings').take(4).toList(),
      quickActions: [
        AiQuickAction(label: 'Search Buses', icon: Icons.directions_bus, query: 'Search all buses'),
      ],
    );
  }

  AiMessage _buildJourneyResponse(String id, DateTime now, String q, PassengerModel? passenger) {
    final buses = FleetState.instance.buses;

    // Try to detect known stops mentioned in the user's query
    String? origin;
    String? destination;

    // Known popular stops & fleet registered stops
    final stopKeywords = <String>{
      'mannarkad',
      'kozhikkode',
      'kozhikode',
      'kalikavu',
      'farook college',
      'west hill',
      'ramanattukara',
      'kondotty',
      'manjeri',
      'wandoor',
      'edavanna',
      'alanallur',
      'melattur',
      'pandikkad',
      'feroke',
      'meenchanda',
      'kallayi',
      'palayam',
      'mananchira',
      'nadakkavu',
      'university',
      'thenhipalam',
      'calicut airport',
      'aluva',
      'perumbavoor',
      'kaloor',
      'menaka',
      'thevara',
      'thoppumpady',
      'vytilla',
      'palarivattom',
      'kakkanad',
      'infopark',
      'pump junction',
      'bank junction',
      'kizhakkambalam',
      'pattimattom',
      'fort kochi',
      'edappally',
    };

    // Dynamically expand with all fleet stop names
    for (final b in buses) {
      for (final s in b.allRouteStops) {
        final clean = s.trim().toLowerCase();
        if (clean.isNotEmpty) stopKeywords.add(clean);
        final base = clean.replaceAll('stand', '').replaceAll('junction', '').replaceAll('depot', '').trim();
        if (base.length >= 3) stopKeywords.add(base);
      }
    }

    // Sort keywords by length descending so longer phrases match first
    final sortedKeywords = stopKeywords.toList()..sort((a, b) => b.length.compareTo(a.length));

    // Parse 'from X to Y' pattern first if present in query
    final fromToMatch = RegExp(r'from\s+([a-zA-Z\s]+?)\s+to\s+([a-zA-Z\s,]+)', caseSensitive: false).firstMatch(q);
    if (fromToMatch != null) {
      final rawFrom = fromToMatch.group(1)?.trim() ?? '';
      final rawTo = fromToMatch.group(2)?.split(RegExp(r'[,?.]')).first.replaceAll('what should i do', '').trim() ?? '';

      for (final s in sortedKeywords) {
        if (origin == null && (rawFrom.contains(s) || s.contains(rawFrom))) {
          origin = s;
        }
        if (destination == null && (rawTo.contains(s) || s.contains(rawTo))) {
          destination = s;
        }
      }
    }

    // Search for pairs if not already matched
    if (origin == null || destination == null) {
      for (final s in sortedKeywords) {
        if (q.contains(s)) {
          if (origin == null) {
            origin = s;
          } else if (destination == null && s != origin) {
            destination = s;
          }
        }
      }
    }

    // Direct Route Search
    if (origin != null && destination != null) {
      BusModel? directBus;
      String matchedOriginName = origin;
      String matchedDestName = destination;
      double directFare = 14.0;

      for (final b in buses) {
        final allStops = b.allRouteStops.map((e) => e.toLowerCase()).toList();
        final origIdx = allStops.indexWhere((s) => s.contains(origin!));
        final destIdx = allStops.indexWhere((s) => s.contains(destination!));

        if (origIdx != -1 && destIdx != -1 && origIdx < destIdx) {
          directBus = b;
          matchedOriginName = b.allRouteStops[origIdx];
          matchedDestName = b.allRouteStops[destIdx];
          directFare = directBus.getFareFor(
            matchedOriginName,
            matchedDestName,
            isStudent: passenger?.concessionCategory.toLowerCase().contains('student') ?? false,
          );
          break;
        }
      }

      if (directBus != null) {
        final depStop = directBus.stops.firstWhere(
          (s) => s.stopName.toLowerCase().contains(origin!),
          orElse: () => BusStopSchedule(stopName: matchedOriginName, time: '10:00 AM'),
        );
        final arrStop = directBus.stops.firstWhere(
          (s) => s.stopName.toLowerCase().contains(destination!),
          orElse: () => BusStopSchedule(stopName: matchedDestName, time: '10:45 AM'),
        );

        final text = StringBuffer()
          ..writeln('🎯 **Journey Plan: $matchedOriginName ➔ $matchedDestName**')
          ..writeln('')
          ..writeln('🚌 **Direct Bus Available**: **${directBus.busName}** (`${directBus.regNumber}`)')
          ..writeln('🎨 **Service**: ${directBus.category}')
          ..writeln('⏰ **Boarding Time**: `${depStop.time}` at **$matchedOriginName**')
          ..writeln('🏁 **Arrival Time**: `${arrStop.time}` at **$matchedDestName**')
          ..writeln('💵 **Standard Ticket Fare**: `₹${directFare.toStringAsFixed(2)}` (Student Concession: `₹5.00`)')
          ..writeln('👨‍✈️ **Conductor**: ${directBus.conductorName} (Phone: `${directBus.conductorPhone}`)')
          ..writeln('⚡ **Live Bus Status**: ${directBus.isActive ? "🟢 Running at ${directBus.currentStop}" : "🟡 At Depot (${directBus.currentStop})" }')
          ..writeln('')
          ..writeln('📋 **Step-by-Step Instructions**:')
          ..writeln('1. Reach **$matchedOriginName** bus stop before `${depStop.time}`.')
          ..writeln('2. Watch for **${directBus.busName}** with route board: *"${directBus.routeName}"*.')
          ..writeln('3. Board the bus and tell Conductor ${directBus.conductorName} you are traveling to **$matchedDestName**.')
          ..writeln('4. Pay ₹${directFare.toStringAsFixed(0)} via your EnRoute Smart Wallet (Current Balance: `₹${(passenger?.walletBalance ?? 0.0).toStringAsFixed(2)}`) or cash/UPI.')
          ..writeln('5. Stay seated and disembark when the bus halts at **$matchedDestName**.');

        return AiMessage(
          id: id,
          text: text.toString(),
          isUser: false,
          timestamp: now,
          busName: directBus.busName,
          busRegNumber: directBus.regNumber,
          routeTitle: directBus.routeName,
          estimatedFare: directFare,
          quickSuggestions: [
            'Full list of ${directBus.busName} timings',
            'What is the fare from $matchedOriginName to $matchedDestName?',
            'Which buses are running right now?',
          ],
          quickActions: [
            AiQuickAction(label: 'Track ${directBus.busName}', icon: Icons.location_on, query: 'Track ${directBus.busName}'),
            AiQuickAction(label: 'Check Wallet', icon: Icons.account_balance_wallet, query: 'Wallet balance'),
          ],
        );
      }

      // Connecting Route (e.g. Aluva to Fort Kochi / Thoppumpady)
      final allBuses = FleetState.instance.buses;
      final bus1 = allBuses.isNotEmpty ? allBuses.first : null;
      final bus2 = allBuses.length > 1 ? allBuses[1] : bus1;
      final leg1BusName = bus1 != null ? '${bus1.busName} (${bus1.regNumber})' : 'Kerala Stage Carriage';
      final leg2BusName = bus2 != null ? '${bus2.busName} (${bus2.regNumber})' : 'Connecting Route Bus';

      final text = StringBuffer()
        ..writeln('🔄 **Connecting Route: ${_capitalize(origin)} ➔ ${_capitalize(destination)}**')
        ..writeln('')
        ..writeln('No single direct private bus covers the entire stretch, but you have a quick 2-step connection:')
        ..writeln('')
        ..writeln('**Leg 1**: Take **$leg1BusName** or Ordinary from ${_capitalize(origin)} towards the junction hub.')
        ..writeln('• Duration: ~30-35 mins • Fare: ~₹18.00')
        ..writeln('')
        ..writeln('**Leg 2**: From the junction, board **$leg2BusName** towards ${_capitalize(destination)}.')
        ..writeln('• Duration: ~25 mins • Fare: ~₹14.00')
        ..writeln('')
        ..writeln('💳 **Total Estimated Fare**: `₹32.00`')
        ..writeln('💡 *Both buses support EnRoute Smart Transit Wallet instant contactless ticketing!*');

      return AiMessage(
        id: id,
        text: text.toString(),
        isUser: false,
        timestamp: now,
        quickSuggestions: [
          if (bus1 != null) 'Full list of ${bus1.busName} timings',
          if (bus2 != null && bus2 != bus1) 'Full list of ${bus2.busName} timings',
          'I don’t have any previous experience of bus journey, what should I do?',
        ],
      );
    }

    // Generic Journey Guidance
    final text = StringBuffer()
      ..writeln('🗺️ **EnRoute Smart Journey Planner**')
      ..writeln('')
      ..writeln('I will find the best bus, timings, fare, and platform guidance for you!')
      ..writeln('Where would you like to travel from and to? For example:')
      ..writeln('• *"I want to go from Aluva to Perumbavoor"*\n• *"How to reach Kakkanad InfoPark from Vytilla Hub"*\n• *"How to travel from Kaloor to Thoppumpady"*')
      ..writeln('')
      ..writeln('💡 *Tell me your starting stop and destination, or tap one of the common routes below:*');

    return AiMessage(
      id: id,
      text: text.toString(),
      isUser: false,
      timestamp: now,
      quickSuggestions: [
        'I want to go from Aluva to Perumbavoor, what should I do?',
        'How to go from Kaloor to Thoppumpady?',
        'How to reach InfoPark from Vytilla Hub?',
        'I don’t have any previous experience of bus journey, what should I do?',
      ],
    );
  }

  AiMessage _buildFareResponse(String id, DateTime now, String q, PassengerModel? passenger) {
    final text = StringBuffer()
      ..writeln('💰 **Kerala Stage Carriage Fare Structure (MVD Approved)**')
      ..writeln('')
      ..writeln('• **Ordinary Stage Carriage (Blue-Whiteline)**:')
      ..writeln('  - Minimum Fare: `₹10.00` (First 2.5 km stage)')
      ..writeln('  - 2 Stages: `₹14.00`')
      ..writeln('  - 3 Stages: `₹18.00`')
      ..writeln('  - 4 Stages: `₹22.00` (₹1.00 / km subsequently)')
      ..writeln('')
      ..writeln('• **Limited Stop Fast Passenger (Red-Whiteline)**:')
      ..writeln('  - Minimum Fare: `₹12.00`')
      ..writeln('')
      ..writeln('• **Student Concession Rates**:')
      ..writeln('  - Standard Stage Rate: Flat `₹5.00` concession with valid student ID')
      ..writeln('')
      ..writeln('💳 **Digital Wallet Benefits**:')
      ..writeln('• Zero convenience fees or extra surcharge on EnRoute Smart Wallet.')
      ..writeln('• Conductor cash change is automatically credited back to your digital balance without coins.')
      ..writeln('• Your Current Balance: `₹${(passenger?.walletBalance ?? 0.0).toStringAsFixed(2)}`');

    return AiMessage(
      id: id,
      text: text.toString(),
      isUser: false,
      timestamp: now,
      quickSuggestions: [
        'What is the fare from Aluva to Perumbavoor?',
        'Full list of ${_sampleBusName()} bus timings',
        'How do I recharge my wallet?',
      ],
      quickActions: [
        AiQuickAction(label: 'Recharge Wallet', icon: Icons.add_card, query: 'Top up wallet'),
      ],
    );
  }

  AiMessage _buildLiveStatusResponse(String id, DateTime now) {
    final buses = FleetState.instance.buses;
    final activeBuses = buses.where((b) => b.isActive).toList();

    final text = StringBuffer()
      ..writeln('📡 **Live Fleet Telemetry & Active Status**')
      ..writeln('')
      ..writeln('Total Registered Fleet: **${buses.length} Stage Carriages**')
      ..writeln('Currently Active on Route: **${activeBuses.length} Buses**')
      ..writeln('');

    for (final b in buses) {
      final statusIcon = b.isActive ? '🟢 [RUNNING]' : '🟡 [IN DEPOT]';
      text.writeln('• **${b.busName}** (`${b.regNumber}`) — $statusIcon');
      text.writeln('  Route: ${b.routeName}');
      text.writeln('  Live Location: ${b.conductorLocationString}');
      text.writeln('  Current Stage: ${b.currentStop} (Next: ${b.nextStop})');
      text.writeln('');
    }

    return AiMessage(
      id: id,
      text: text.toString(),
      isUser: false,
      timestamp: now,
      quickSuggestions: [
        'Full list of ${_sampleBusName()} bus timings',
        'Which buses are running right now?',
        'I want to go from Aluva to Perumbavoor',
      ],
      quickActions: [
        AiQuickAction(label: 'Open Live Radar', icon: Icons.radar, query: 'Show live map'),
      ],
    );
  }

  AiMessage _buildWalletResponse(String id, DateTime now, PassengerModel? passenger) {
    final balance = passenger?.walletBalance ?? 0.0;
    final passengerName = passenger?.name ?? 'Passenger';

    final text = StringBuffer()
      ..writeln('💳 **EnRoute Smart Transit Wallet**')
      ..writeln('')
      ..writeln('👤 **Account Holder**: $passengerName (`${passenger?.id ?? "Guest"}`)')
      ..writeln('💰 **Available Wallet Balance**: `₹${balance.toStringAsFixed(2)}`')
      ..writeln('')
      ..writeln('⚡ **How to Use Your Wallet Onboard**:')
      ..writeln('1. When the conductor arrives with the ticket machine, simply say: *"EnRoute Smart Wallet"* or show your ticket QR from the app.')
      ..writeln('2. The exact fare is auto-debited in under 2 seconds—no cash or coin change hassles!')
      ..writeln('3. Digital receipt and ticket are saved immediately into your Travel Ledger.')
      ..writeln('')
      ..writeln('🔄 **How to Recharge**:')
      ..writeln('• Go to the **Wallet Details** tab in this app.')
      ..writeln('• Choose a quick recharge amount (₹100, ₹200, ₹500) and complete via Google Pay, PhonePe, Paytm, or Card.');

    return AiMessage(
      id: id,
      text: text.toString(),
      isUser: false,
      timestamp: now,
      quickSuggestions: [
        'Recharge ₹100 to wallet',
        'What is the fare from Aluva to Perumbavoor?',
        'Full list of ${_sampleBusName()} bus timings',
      ],
      quickActions: [
        AiQuickAction(label: 'Recharge Now', icon: Icons.account_balance_wallet, query: 'Top up wallet'),
      ],
    );
  }

  AiMessage _buildSafetyResponse(String id, DateTime now) {
    final text = StringBuffer()
      ..writeln('🛡️ **Safety, Complaints & Kerala MVD Helplines**')
      ..writeln('')
      ..writeln('For any emergencies, lost items, fare overcharging, or safety concerns:')
      ..writeln('')
      ..writeln('📞 **Official Helplines**:')
      ..writeln('• **Kerala Motor Vehicles Dept (MVD) Toll-Free**: `1800-425-4740`')
      ..writeln('• **Emergency Police Response**: `112`')
      ..writeln('• **Women Helpline (Pink Patrol)**: `1091` / `1515`')
      ..writeln('• **Ambulance**: `108`')
      ..writeln('')
      ..writeln('🚌 **Fleet Operators Contacts**:')
      ..writeln('• Registered Fleet Control Desk & Conductor In-App Calling')
      ..writeln('')
      ..writeln('📝 *You can also report any issue directly through Profile ➔ Lost & Found Desk or Emergency SOS.*');

    return AiMessage(
      id: id,
      text: text.toString(),
      isUser: false,
      timestamp: now,
      quickSuggestions: [
        'Full list of ${_sampleBusName()} bus timings',
        'Which buses are running right now?',
      ],
    );
  }

  AiMessage _buildGeneralFallbackResponse(String id, DateTime now, String rawQuery, PassengerModel? passenger) {
    final sampleName = _sampleBusName();
    final text = StringBuffer()
      ..writeln('🤖 **EnRoute Transit AI Assistant**')
      ..writeln('')
      ..writeln('I am connected to the entire EnRoute Kerala real-time fleet database!')
      ..writeln('Here is what you can ask me:')
      ..writeln('')
      ..writeln('🕒 **Bus Timings & Schedules**')
      ..writeln('• *"I want full list of $sampleName bus timings"*\n• *"Which buses are running right now?"*\n• *"When does the next bus arrive?"*')
      ..writeln('')
      ..writeln('🗺️ **Journey Planning**')
      ..writeln('• *"I want to go from Aluva to Perumbavoor, what should I do?"*\n• *"How to reach Kakkanad from Vytilla?"*')
      ..writeln('')
      ..writeln('🔰 **First-Time Bus Travel Guide**')
      ..writeln('• *"I don’t have any previous experience of bus journey, what should I do?"*')
      ..writeln('')
      ..writeln('💰 **Fare & Wallet**')
      ..writeln('• *"What is the fare between Aluva and Kizhakkambalam?"*\n• *"How to pay using Smart Wallet?"*')
      ..writeln('')
      ..writeln('💬 *Try tapping any of the quick suggestions below or type your question!*');

    return AiMessage(
      id: id,
      text: text.toString(),
      isUser: false,
      timestamp: now,
      quickSuggestions: [
        'Full list of $sampleName bus timings',
        'I want to go from Aluva to Perumbavoor, what should I do?',
        'I don’t have any previous experience of bus journey, what should I do?',
        'Which buses are running right now?',
      ],
    );
  }

  String _sampleBusName() {
    final buses = FleetState.instance.buses;
    if (buses.isNotEmpty) return buses.first.busName;
    return 'Sana';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
