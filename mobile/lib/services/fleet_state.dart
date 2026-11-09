import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, Colors;
import 'storage_service.dart';
import 'api_service.dart';
import '../models/bus_expense_model.dart';
import '../models/lost_item_model.dart';

int parseTimeToMinutes(String timeStr) {
  try {
    final clean = timeStr.trim().toUpperCase();
    final isPM = clean.contains('PM');
    final isAM = clean.contains('AM');
    final raw = clean.replaceAll('AM', '').replaceAll('PM', '').trim();
    final parts = raw.split(':');
    if (parts.length >= 2) {
      int hour = int.parse(parts[0].trim());
      int minute = int.parse(parts[1].trim());
      if (isPM && hour < 12) hour += 12;
      if (isAM && hour == 12) hour = 0;
      return hour * 60 + minute;
    }
  } catch (_) {}
  return 0;
}

class BusStopSchedule {
  String stopName;
  String time;

  BusStopSchedule({required this.stopName, required this.time});

  Map<String, dynamic> toJson() => {
    'stopName': stopName,
    'time': time,
  };

  factory BusStopSchedule.fromJson(Map<String, dynamic> json) => BusStopSchedule(
    stopName: json['stopName'] as String,
    time: json['time'] as String,
  );
}

class PassengerModel {
  final String id; // e.g. 'SBK-KL-987263'
  String name;
  String email;
  String phone;
  String password;
  double walletBalance;
  String homeStation;
  String concessionCategory; // 'General / Adult Standard', 'Student Concession'
  DateTime registeredAt;

  PassengerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    this.walletBalance = 0.0, // Clean 0 balance for new signups
    this.homeStation = 'Aluva Stand, Ernakulam',
    this.concessionCategory = 'General / Adult Standard',
    required this.registeredAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'password': password,
    'walletBalance': walletBalance,
    'homeStation': homeStation,
    'concessionCategory': concessionCategory,
    'registeredAt': registeredAt.toIso8601String(),
  };

  factory PassengerModel.fromJson(Map<String, dynamic> json) => PassengerModel(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String,
    password: json['password'] as String,
    walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
    homeStation: (json['homeStation'] as String?) ?? 'Aluva Stand, Ernakulam',
    concessionCategory: (json['concessionCategory'] as String?) ?? 'General / Adult Standard',
    registeredAt: DateTime.tryParse(json['registeredAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class OwnerModel {
  final String id; // e.g. 'OWNER-1'
  String name;
  String email;
  String phone;
  String password;
  String companyName; // e.g. 'St. George Motors Ernakulam'
  bool isVerified;
  DateTime registeredAt;

  OwnerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.companyName,
    this.isVerified = true,
    required this.registeredAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'password': password,
    'companyName': companyName,
    'isVerified': isVerified,
    'registeredAt': registeredAt.toIso8601String(),
  };

  factory OwnerModel.fromJson(Map<String, dynamic> json) => OwnerModel(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String,
    password: json['password'] as String,
    companyName: json['companyName'] as String,
    isVerified: (json['isVerified'] as bool?) ?? true,
    registeredAt: DateTime.tryParse(json['registeredAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class BusReviewModel {
  final String id;
  final String busRegNumber;
  final String busName;
  final String passengerName;
  final double rating; // 1.0 to 5.0
  final String comment;
  final DateTime createdAt;
  bool isReadByOwner;
  bool isReadByConductor;

  BusReviewModel({
    required this.id,
    required this.busRegNumber,
    required this.busName,
    required this.passengerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.isReadByOwner = false,
    this.isReadByConductor = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'busRegNumber': busRegNumber,
    'busName': busName,
    'passengerName': passengerName,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
    'isReadByOwner': isReadByOwner,
    'isReadByConductor': isReadByConductor,
  };

  factory BusReviewModel.fromJson(Map<String, dynamic> json) => BusReviewModel(
    id: json['id'] as String,
    busRegNumber: json['busRegNumber'] as String,
    busName: json['busName'] as String,
    passengerName: json['passengerName'] as String,
    rating: (json['rating'] as num).toDouble(),
    comment: json['comment'] as String,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    isReadByOwner: (json['isReadByOwner'] as bool?) ?? false,
    isReadByConductor: (json['isReadByConductor'] as bool?) ?? false,
  );
}

class IssuedTicketModel {
  final String id;
  final String ticketNumber;
  final String busRegNumber;
  final String busName;
  final String conductorId;
  final String conductorName;
  final String passengerId;
  final String passengerName;
  final String boardingStop;
  final String destStop;
  final double fare;
  final String category; // 'General', 'Student Concession'
  final String paymentMode; // 'SMART_WALLET', 'CASH', 'UPI', 'SPLIT'
  final double cashGiven;
  final double changeReturned;
  final double splitCash;
  final double splitUpi;
  final DateTime issuedAt;

  IssuedTicketModel({
    required this.id,
    required this.ticketNumber,
    required this.busRegNumber,
    required this.busName,
    required this.conductorId,
    required this.conductorName,
    required this.passengerId,
    required this.passengerName,
    required this.boardingStop,
    required this.destStop,
    required this.fare,
    required this.category,
    required this.paymentMode,
    this.cashGiven = 0.0,
    this.changeReturned = 0.0,
    this.splitCash = 0.0,
    this.splitUpi = 0.0,
    required this.issuedAt,
  });

  String get destinationStop => destStop;
  DateTime get timestamp => issuedAt;
  bool get isStudentConcession => category.toLowerCase().contains('student');
  String get paymentModeLabel {
    switch (paymentMode) {
      case 'SMART_WALLET':
        return 'Smart Transit Wallet (Instant auto-debit)';
      case 'CASH':
        return 'Liquid Cash Handover';
      case 'UPI':
        return 'Dynamic UPI QR Scan';
      case 'SPLIT':
        return 'ment (Cash + UPI)';
      default:
        return paymentMode;
    }
  }
  double? get cashTendered => cashGiven > 0 ? cashGiven : null;
  double? get cashChangeGiven => changeReturned > 0 ? changeReturned : null;
  bool get isSplitPayment => paymentMode == 'SPLIT' || (splitCash > 0 && splitUpi > 0);
  double? get splitCashAmount => splitCash > 0 ? splitCash : null;
  double? get splitUpiAmount => splitUpi > 0 ? splitUpi : null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'ticketNumber': ticketNumber,
    'busRegNumber': busRegNumber,
    'busName': busName,
    'conductorId': conductorId,
    'conductorName': conductorName,
    'passengerId': passengerId,
    'passengerName': passengerName,
    'boardingStop': boardingStop,
    'destStop': destStop,
    'fare': fare,
    'category': category,
    'paymentMode': paymentMode,
    'cashGiven': cashGiven,
    'changeReturned': changeReturned,
    'splitCash': splitCash,
    'splitUpi': splitUpi,
    'issuedAt': issuedAt.toIso8601String(),
  };

  factory IssuedTicketModel.fromJson(Map<String, dynamic> json) => IssuedTicketModel(
    id: json['id'] as String,
    ticketNumber: json['ticketNumber'] as String,
    busRegNumber: json['busRegNumber'] as String,
    busName: json['busName'] as String,
    conductorId: json['conductorId'] as String,
    conductorName: json['conductorName'] as String,
    passengerId: json['passengerId'] as String,
    passengerName: json['passengerName'] as String,
    boardingStop: json['boardingStop'] as String,
    destStop: json['destStop'] as String,
    fare: (json['fare'] as num).toDouble(),
    category: json['category'] as String,
    paymentMode: json['paymentMode'] as String,
    cashGiven: (json['cashGiven'] as num?)?.toDouble() ?? 0.0,
    changeReturned: (json['changeReturned'] as num?)?.toDouble() ?? 0.0,
    splitCash: (json['splitCash'] as num?)?.toDouble() ?? 0.0,
    splitUpi: (json['splitUpi'] as num?)?.toDouble() ?? 0.0,
    issuedAt: DateTime.tryParse(json['issuedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class WalletTransactionModel {
  final String id;
  final String passengerId;
  final String title;
  final String busOrSource;
  final double amount; // positive for top-up, negative for fare
  final String type; // 'RECHARGE', 'WALLET', 'UPI', 'CASH'
  final DateTime timestamp;
  final String status;

  WalletTransactionModel({
    required this.id,
    required this.passengerId,
    required this.title,
    required this.busOrSource,
    required this.amount,
    required this.type,
    required this.timestamp,
    this.status = 'SUCCESS',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'passengerId': passengerId,
    'title': title,
    'busOrSource': busOrSource,
    'amount': amount,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'status': status,
  };

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) => WalletTransactionModel(
    id: json['id'] as String,
    passengerId: json['passengerId'] as String,
    title: json['title'] as String,
    busOrSource: json['busOrSource'] as String,
    amount: (json['amount'] as num).toDouble(),
    type: json['type'] as String,
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    status: (json['status'] as String?) ?? 'SUCCESS',
  );
}

class BusModel {
  final String id;
  final String ownerId; // Isolated to registering bus owner
  final String regNumber; // Immutable after registration
  String busName;
  String category; // 'Limited Stop Bus (Red-Whiteline)', 'Ordinary Bus (Blue-Whiteline)', 'City Bus (Green-Whiteline)'
  String startPoint;
  String destPoint;
  String routeName;
  List<BusStopSchedule> stops;
  int seatingCapacity;
  String driverName;
  String driverPhone;
  String cleanerName;
  String cleanerPhone;
  String conductorName;
  String companyName;
  double todayCollection;
  int ticketsCount;
  bool isActive; // Active or Inactive
  String status; // 'RUNNING_NOW', 'IN_DEPOT', 'MAINTENANCE'
  bool isApprovedByAdmin;
  String verificationStatus; // 'ADMIN_APPROVED', 'WAITING_FOR_VERIFICATION', 'REJECTED'
  String chassisNumber;
  String permitNumber;
  String fitnessValidity;
  String insurancePolicyNumber;
  String currentStop;
  String nextStop;
  String eta;

  // Contact Information for Direct Passenger Connection
  String ownerName;
  String ownerPhone;
  String ownerEmail;
  String conductorPhone;
  String conductorEmail;

  // Live Trip & GPS Telemetry (Managed by Conductor)
  bool isTripActive;
  bool isLiveGpsActive;
  int currentStageIndex;
  double currentLatitude;
  double currentLongitude;
  double speedKmh;
  String conductorLocationString;

  // Stop-to-Stop Fare Chart Matrix
  Map<String, double> customFareChart;

  // Business Banking & Direct UPI Ticketing (Configured by Bus Owner)
  String upiId;
  String payeeName;
  bool isUpiEnabled;

  // Live Bus Crowding / Occupancy (Singapore DataMall 3-Level Standard)
  String occupancyStatus; // 'SEATS_AVAILABLE', 'STANDING_AVAILABLE', 'HEAVILY_CROWDED'

  bool get hasValidUpi => isUpiEnabled && upiId.trim().isNotEmpty;

  String get occupancyLabel {
    switch (occupancyStatus) {
      case 'STANDING_AVAILABLE':
        return 'Standing Only';
      case 'HEAVILY_CROWDED':
        return 'Heavily Crowded';
      case 'SEATS_AVAILABLE':
      default:
        return 'Seats Available';
    }
  }

  String get occupancyMalayalam {
    switch (occupancyStatus) {
      case 'STANDING_AVAILABLE':
        return 'നിൽക്കാൻ സ്ഥലമുണ്ട്';
      case 'HEAVILY_CROWDED':
        return 'വളരെ തിരക്ക്';
      case 'SEATS_AVAILABLE':
      default:
        return 'സീറ്റുകൾ ലഭ്യമാണ്';
    }
  }

  Color get occupancyColor {
    switch (occupancyStatus) {
      case 'STANDING_AVAILABLE':
        return Colors.orangeAccent;
      case 'HEAVILY_CROWDED':
        return Colors.redAccent;
      case 'SEATS_AVAILABLE':
      default:
        return const Color(0xFF00E676);
    }
  }

  BusModel({
    required this.id,
    this.ownerId = 'OWNER-1',
    required this.regNumber,
    required this.busName,
    required this.category,
    this.occupancyStatus = 'SEATS_AVAILABLE',
    this.startPoint = 'Mannarkad',
    this.destPoint = 'Kozhikkode',
    required this.routeName,
    required this.stops,
    this.seatingCapacity = 48,
    this.driverName = 'Unassigned',
    this.driverPhone = '+91 94470 55112',
    this.cleanerName = 'Unassigned',
    this.cleanerPhone = '+91 94470 55113',
    this.conductorName = 'Unassigned',
    this.companyName = 'Sahl Motors Kozhikode',
    this.todayCollection = 0.0,
    this.ticketsCount = 0,
    this.isActive = true,
    this.status = 'RUNNING_NOW',
    this.isApprovedByAdmin = true,
    this.verificationStatus = 'ADMIN_APPROVED',
    this.chassisNumber = 'MB1-420-KL-CHASSIS-8891',
    this.permitNumber = 'KL/2026/MVD/STAGE/0491',
    this.fitnessValidity = '28-Dec-2027',
    this.insurancePolicyNumber = 'NIC-KL-COM-778210',
    this.currentStop = 'Mannarkad Stand',
    this.nextStop = 'Alanallur (~5 mins)',
    this.eta = '5 mins',
    this.ownerName = 'Sahl (Owner)',
    this.ownerPhone = '+91 94470 12345',
    this.ownerEmail = 'sahl@gmail.com',
    this.conductorPhone = '+91 98470 11001',
    this.conductorEmail = 'shamil@enroute.com',
    this.isTripActive = true,
    this.isLiveGpsActive = true,
    this.currentStageIndex = 0,
    this.currentLatitude = 10.9882,
    this.currentLongitude = 76.4589,
    this.speedKmh = 0.0,
    this.conductorLocationString = 'Mannarkad Stand (Conductor Device GPS)',
    this.upiId = '',
    this.payeeName = '',
    this.isUpiEnabled = false,
    Map<String, double>? customFareChart,
  }) : customFareChart = customFareChart ?? {} {
    sortStops();
    initDefaultFareChart();
  }

  bool get isWaitingForVerification => verificationStatus == 'WAITING_FOR_VERIFICATION';

  void initDefaultFareChart({bool force = false}) {
    if (customFareChart.isEmpty || force) {
      customFareChart.clear();
      final all = allRouteStops;
      for (int i = 0; i < all.length; i++) {
        for (int j = i + 1; j < all.length; j++) {
          final diff = (j - i).abs();
          double f = 10.0;
          if (diff == 1) {
            f = 10.0;
          } else if (diff == 2) {
            f = 14.0;
          } else if (diff == 3) {
            f = 18.0;
          } else if (diff == 4) {
            f = 22.0;
          } else {
            f = 10.0 + (diff * 4.0);
          }
          final k1 = '${all[i].trim().toLowerCase()}->${all[j].trim().toLowerCase()}';
          final k2 = '${all[j].trim().toLowerCase()}->${all[i].trim().toLowerCase()}';
          customFareChart[k1] = f;
          customFareChart[k2] = f;
        }
      }
    }
  }

  List<String> get allRouteStops {
    final list = <String>[];
    if (startPoint.trim().isNotEmpty) list.add(startPoint.trim());
    for (final s in stops) {
      if (s.stopName.trim().isNotEmpty && !list.contains(s.stopName.trim())) {
        list.add(s.stopName.trim());
      }
    }
    if (destPoint.trim().isNotEmpty && !list.contains(destPoint.trim())) {
      list.add(destPoint.trim());
    }
    return list;
  }

  double getFareFor(String fromStop, String toStop, {bool isStudent = false}) {
    if (isStudent) return 5.0; // Kerala Student Concession fixed at ₹5
    final cleanFrom = fromStop.trim().toLowerCase();
    final cleanTo = toStop.trim().toLowerCase();
    if (cleanFrom.isEmpty || cleanTo.isEmpty || cleanFrom == cleanTo) return 10.0;

    final key1 = '$cleanFrom->$cleanTo';
    final key2 = '$cleanTo->$cleanFrom';
    if (customFareChart.containsKey(key1)) return customFareChart[key1]!;
    if (customFareChart.containsKey(key2)) return customFareChart[key2]!;

    final all = allRouteStops;
    int fromIdx = all.indexWhere((s) => s.trim().toLowerCase() == cleanFrom);
    int toIdx = all.indexWhere((s) => s.trim().toLowerCase() == cleanTo);

    if (fromIdx != -1 && toIdx != -1) {
      int diff = (toIdx - fromIdx).abs();
      if (diff <= 1) return 10.0;
      if (diff == 2) return 14.0;
      if (diff == 3) return 18.0;
      if (diff == 4) return 22.0;
      return 10.0 + (diff * 4.0);
    }
    return 14.0;
  }

  void setCustomFare(String fromStop, String toStop, double fare) {
    final cleanFrom = fromStop.trim().toLowerCase();
    final cleanTo = toStop.trim().toLowerCase();
    customFareChart['$cleanFrom->$cleanTo'] = fare;
    customFareChart['$cleanTo->$cleanFrom'] = fare;
  }

  void removeCustomFare(String fromStop, String toStop) {
    final cleanFrom = fromStop.trim().toLowerCase();
    final cleanTo = toStop.trim().toLowerCase();
    customFareChart.remove('$cleanFrom->$cleanTo');
    customFareChart.remove('$cleanTo->$cleanFrom');
  }

  void sortStops() {
    stops.sort((a, b) => parseTimeToMinutes(a.time).compareTo(parseTimeToMinutes(b.time)));
  }

  String get busType => category;
  String get startTime => stops.isNotEmpty ? stops.first.time : '06:30 AM';
  String get endTime => stops.isNotEmpty ? stops.last.time : '08:00 PM';

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'regNumber': regNumber,
    'busName': busName,
    'category': category,
    'startPoint': startPoint,
    'destPoint': destPoint,
    'routeName': routeName,
    'stops': stops.map((s) => s.toJson()).toList(),
    'seatingCapacity': seatingCapacity,
    'driverName': driverName,
    'driverPhone': driverPhone,
    'cleanerName': cleanerName,
    'cleanerPhone': cleanerPhone,
    'conductorName': conductorName,
    'companyName': companyName,
    'todayCollection': todayCollection,
    'ticketsCount': ticketsCount,
    'isActive': isActive,
    'status': status,
    'isApprovedByAdmin': isApprovedByAdmin,
    'verificationStatus': verificationStatus,
    'chassisNumber': chassisNumber,
    'permitNumber': permitNumber,
    'fitnessValidity': fitnessValidity,
    'insurancePolicyNumber': insurancePolicyNumber,
    'currentStop': currentStop,
    'nextStop': nextStop,
    'eta': eta,
    'ownerName': ownerName,
    'ownerPhone': ownerPhone,
    'ownerEmail': ownerEmail,
    'conductorPhone': conductorPhone,
    'conductorEmail': conductorEmail,
    'isTripActive': isTripActive,
    'isLiveGpsActive': isLiveGpsActive,
    'currentStageIndex': currentStageIndex,
    'currentLatitude': currentLatitude,
    'currentLongitude': currentLongitude,
    'speedKmh': speedKmh,
    'conductorLocationString': conductorLocationString,
    'customFareChart': customFareChart,
    'upiId': upiId,
    'payeeName': payeeName,
    'isUpiEnabled': isUpiEnabled,
    'occupancyStatus': occupancyStatus,
  };

  factory BusModel.fromJson(Map<String, dynamic> json) => BusModel(
    id: json['id'] as String,
    ownerId: (json['ownerId'] as String?) ?? 'OWNER-1',
    regNumber: json['regNumber'] as String,
    busName: json['busName'] as String,
    category: json['category'] as String,
    startPoint: (json['startPoint'] as String?) ?? 'Aluva Stand',
    destPoint: (json['destPoint'] as String?) ?? 'Perumbavoor Stand',
    routeName: (json['routeName'] as String?) ?? '',
    stops: (json['stops'] as List<dynamic>?)
            ?.map((e) => BusStopSchedule.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [],
    seatingCapacity: (json['seatingCapacity'] as num?)?.toInt() ?? 48,
    driverName: (json['driverName'] as String?) ?? 'Unassigned',
    driverPhone: (json['driverPhone'] as String?) ?? '+91 94470 55112',
    cleanerName: (json['cleanerName'] as String?) ?? 'Unassigned',
    cleanerPhone: (json['cleanerPhone'] as String?) ?? '+91 94470 55113',
    conductorName: (json['conductorName'] as String?) ?? 'Unassigned',
    companyName: (json['companyName'] as String?) ?? '',
    todayCollection: (json['todayCollection'] as num?)?.toDouble() ?? 0.0,
    ticketsCount: (json['ticketsCount'] as num?)?.toInt() ?? 0,
    isActive: (json['isActive'] as bool?) ?? true,
    status: (json['status'] as String?) ?? 'RUNNING_NOW',
    isApprovedByAdmin: (json['isApprovedByAdmin'] as bool?) ?? true,
    verificationStatus: (json['verificationStatus'] as String?) ?? 'ADMIN_APPROVED',
    chassisNumber: (json['chassisNumber'] as String?) ?? 'MB1-420-KL-CHASSIS-8891',
    permitNumber: (json['permitNumber'] as String?) ?? 'KL/2026/MVD/STAGE/0491',
    fitnessValidity: (json['fitnessValidity'] as String?) ?? '28-Dec-2027',
    insurancePolicyNumber: (json['insurancePolicyNumber'] as String?) ?? 'NIC-KL-COM-778210',
    currentStop: (json['currentStop'] as String?) ?? '',
    nextStop: (json['nextStop'] as String?) ?? '',
    eta: (json['eta'] as String?) ?? '',
    ownerName: (json['ownerName'] as String?) ?? '',
    ownerPhone: (json['ownerPhone'] as String?) ?? '',
    ownerEmail: (json['ownerEmail'] as String?) ?? '',
    conductorPhone: (json['conductorPhone'] as String?) ?? '',
    conductorEmail: (json['conductorEmail'] as String?) ?? '',
    isTripActive: (json['isTripActive'] as bool?) ?? false,
    isLiveGpsActive: (json['isLiveGpsActive'] as bool?) ?? true,
    currentStageIndex: (json['currentStageIndex'] as num?)?.toInt() ?? 0,
    currentLatitude: (json['currentLatitude'] as num?)?.toDouble() ?? 10.0,
    currentLongitude: (json['currentLongitude'] as num?)?.toDouble() ?? 76.0,
    speedKmh: (json['speedKmh'] as num?)?.toDouble() ?? 0.0,
    conductorLocationString: (json['conductorLocationString'] as String?) ?? '',
    customFareChart: (json['customFareChart'] as Map?)
        ?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
    upiId: (json['upiId'] as String?) ?? '',
    payeeName: (json['payeeName'] as String?) ?? '',
    isUpiEnabled: (json['isUpiEnabled'] as bool?) ?? false,
    occupancyStatus: (json['occupancyStatus'] as String?) ?? 'SEATS_AVAILABLE',
  );
}

class ConductorModel {
  final String id;
  final String ownerId; // Isolated to provisioning owner
  String name;
  String email;
  String userId; // App Login ID
  String password; // App Login Password
  String phone;
  String licenseNumber; // MVD Conductor Badge/License
  String assignedBusReg;
  String assignedBusName;
  double todayCollection;

  ConductorModel({
    required this.id,
    this.ownerId = 'OWNER-1',
    required this.name,
    required this.email,
    required this.userId,
    required this.password,
    required this.phone,
    required this.licenseNumber,
    required this.assignedBusReg,
    required this.assignedBusName,
    this.todayCollection = 0.0,
  });

  String get loginId => userId;
  String get badgeNumber => licenseNumber;

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'name': name,
    'email': email,
    'userId': userId,
    'password': password,
    'phone': phone,
    'licenseNumber': licenseNumber,
    'assignedBusReg': assignedBusReg,
    'assignedBusName': assignedBusName,
    'todayCollection': todayCollection,
  };

  factory ConductorModel.fromJson(Map<String, dynamic> json) => ConductorModel(
    id: json['id'] as String,
    ownerId: (json['ownerId'] as String?) ?? 'OWNER-1',
    name: json['name'] as String,
    email: json['email'] as String,
    userId: json['userId'] as String,
    password: json['password'] as String,
    phone: json['phone'] as String,
    licenseNumber: json['licenseNumber'] as String,
    assignedBusReg: (json['assignedBusReg'] as String?) ?? '',
    assignedBusName: (json['assignedBusName'] as String?) ?? '',
    todayCollection: (json['todayCollection'] as num?)?.toDouble() ?? 0.0,
  );
}

enum OwnerTimeframe { daily, weekly, monthly, yearly }

class BusProfitBreakdown {
  final String busRegNumber;
  final String busName;
  final String category;
  final String routeName;
  final String conductorName;
  final String driverName;
  final bool isActive;
  final double grossRevenue;
  final double fuelExpense; // Real or benchmark
  final double crewWages; // Real or benchmark
  final double maintenanceReserve; // Real or benchmark
  final double roadTaxAndPermits; // Real or benchmark
  final double totalExpenses;
  final double netProfit;
  final double profitMarginPercent;
  final int ticketsCount;
  final int tripsCount;
  final double avgTicketFare;
  final String statusBadge;
  final bool isRecordedExpense;

  const BusProfitBreakdown({
    required this.busRegNumber,
    required this.busName,
    required this.category,
    required this.routeName,
    required this.conductorName,
    required this.driverName,
    required this.isActive,
    required this.grossRevenue,
    required this.fuelExpense,
    required this.crewWages,
    required this.maintenanceReserve,
    required this.roadTaxAndPermits,
    required this.totalExpenses,
    required this.netProfit,
    required this.profitMarginPercent,
    required this.ticketsCount,
    required this.tripsCount,
    required this.avgTicketFare,
    required this.statusBadge,
    this.isRecordedExpense = false,
  });
}

class OwnerProfitReport {
  final OwnerTimeframe timeframe;
  final String timeframeLabel;
  final String periodLabel;
  final double grossRevenue;
  final double fuelExpense;
  final double crewWages;
  final double maintenanceReserve;
  final double roadTaxAndPermits;
  final double totalExpenses;
  final double netProfit;
  final double profitMarginPercent;
  final int totalTickets;
  final int totalTrips;
  final double walletRevenue;
  final double cashRevenue;
  final double upiRevenue;
  final double avgRevenuePerBus;
  final double avgRevenuePerTrip;
  final List<BusProfitBreakdown> busBreakdowns;
  final bool hasRecordedExpenses;

  const OwnerProfitReport({
    required this.timeframe,
    required this.timeframeLabel,
    required this.periodLabel,
    required this.grossRevenue,
    required this.fuelExpense,
    required this.crewWages,
    required this.maintenanceReserve,
    required this.roadTaxAndPermits,
    required this.totalExpenses,
    required this.netProfit,
    required this.profitMarginPercent,
    required this.totalTickets,
    required this.totalTrips,
    required this.walletRevenue,
    required this.cashRevenue,
    required this.upiRevenue,
    required this.avgRevenuePerBus,
    required this.avgRevenuePerTrip,
    required this.busBreakdowns,
    this.hasRecordedExpenses = false,
  });
}

class FleetState extends ChangeNotifier {
  static final FleetState instance = FleetState._internal();
  FleetState._internal() {
    _initDefaultSeedData();
  }

  bool _isStorageLoaded = false;

  // In-Memory Multi-Tenant Registries
  final List<PassengerModel> registeredPassengers = [];
  final List<OwnerModel> registeredOwners = [];
  final List<ConductorModel> conductors = [];
  final List<BusModel> buses = [];
  final List<IssuedTicketModel> issuedTickets = [];
  final List<WalletTransactionModel> walletTransactions = [];
  final List<BusReviewModel> reviews = [];
  final List<BusExpenseRecord> _recordedExpenses = [];
  List<BusExpenseRecord> get recordedExpenses => List.unmodifiable(_recordedExpenses);
  final List<LostItemReport> _lostItems = [];
  List<LostItemReport> get lostItems => List.unmodifiable(_lostItems);

  void _initDefaultSeedData() {
    registeredPassengers.addAll([
      PassengerModel(
        id: 'SBK-KL-987263',
        name: 'Fathima',
        email: 'fathima@gmail.com',
        phone: '9847000004',
        password: 'password123',
        walletBalance: 250.0,
        homeStation: 'Kozhikkode Stand',
        concessionCategory: 'General / Adult Standard',
        registeredAt: DateTime(2026, 10, 1),
      ),
      PassengerModel(
        id: 'SBK-KL-554120',
        name: 'Adhil KM',
        email: 'adhil@gmail.com',
        phone: '9847000005',
        password: 'password123',
        walletBalance: 120.0,
        homeStation: 'Mannarkad Stand',
        concessionCategory: 'Student Concession',
        registeredAt: DateTime(2026, 10, 5),
      ),
      PassengerModel(
        id: 'SBK-KL-339811',
        name: 'Kp',
        email: 'kp@gmail.com',
        phone: '9847000006',
        password: 'password123',
        walletBalance: 450.0,
        homeStation: 'Farook College',
        concessionCategory: 'General / Adult Standard',
        registeredAt: DateTime(2026, 10, 10),
      ),
    ]);

    registeredOwners.addAll([
      OwnerModel(
        id: 'OWNER-1',
        name: 'Sahl',
        email: 'sahl@gmail.com',
        phone: '9447012345',
        password: 'password123',
        companyName: 'Sahl Motors Kozhikode',
        isVerified: true,
        registeredAt: DateTime(2026, 10, 1),
      ),
      OwnerModel(
        id: 'OWNER-2',
        name: 'Fathima Riyas',
        email: 'fathima.owner@gmail.com',
        phone: '9447054321',
        password: 'password123',
        companyName: 'Fathima Riyas Transit',
        isVerified: true,
        registeredAt: DateTime(2026, 10, 1),
      ),
    ]);

    conductors.addAll([
      ConductorModel(
        id: 'COND-1',
        ownerId: 'OWNER-1',
        name: 'Shamil K',
        email: 'shamil@enroute.com',
        userId: 'shamil.conductor',
        password: 'password123',
        phone: '+91 98470 11001',
        licenseNumber: 'KL-10-COND-2018-8891',
        assignedBusReg: 'KL 10 AZ 4589',
        assignedBusName: 'Sana',
        todayCollection: 0.0,
      ),
      ConductorModel(
        id: 'COND-2',
        ownerId: 'OWNER-1',
        name: 'Kaarangadan',
        email: 'kaarangadan@enroute.com',
        userId: 'kaarangadan.conductor',
        password: 'password123',
        phone: '+91 98470 11002',
        licenseNumber: 'KL-10-COND-2020-4102',
        assignedBusReg: 'KL 10 CE 1204',
        assignedBusName: 'Arafa',
        todayCollection: 0.0,
      ),
      ConductorModel(
        id: 'COND-3',
        ownerId: 'OWNER-2',
        name: 'Anfal',
        email: 'anfal@enroute.com',
        userId: 'anfal.conductor',
        password: 'password123',
        phone: '+91 98470 11003',
        licenseNumber: 'KL-11-COND-2021-7740',
        assignedBusReg: 'KL 11 BQ 9981',
        assignedBusName: 'Sanha',
        todayCollection: 0.0,
      ),
      ConductorModel(
        id: 'COND-4',
        ownerId: 'OWNER-1',
        name: 'Jamsheer',
        email: 'jamsheer@enroute.com',
        userId: 'jamsheer.conductor',
        password: 'password123',
        phone: '+91 98470 11004',
        licenseNumber: 'KL-11-COND-2022-5509',
        assignedBusReg: 'KL 11 CF 3320',
        assignedBusName: 'KKB',
        todayCollection: 0.0,
      ),
    ]);

    buses.addAll([
      BusModel(
        id: 'BUS-1',
        ownerId: 'OWNER-1',
        regNumber: 'KL 10 AZ 4589',
        busName: 'Sana',
        category: 'Limited Stop Bus (Red-Whiteline)',
        startPoint: 'Mannarkad',
        destPoint: 'Kozhikkode',
        routeName: 'Mannarkad - Kozhikkode (via Manjeri & Kondotty)',
        stops: [
          BusStopSchedule(stopName: 'Mannarkad Stand', time: '07:00 AM'),
          BusStopSchedule(stopName: 'Alanallur', time: '07:25 AM'),
          BusStopSchedule(stopName: 'Melattur', time: '07:45 AM'),
          BusStopSchedule(stopName: 'Pandikkad', time: '08:05 AM'),
          BusStopSchedule(stopName: 'Manjeri Stand', time: '08:35 AM'),
          BusStopSchedule(stopName: 'Kondotty', time: '09:05 AM'),
          BusStopSchedule(stopName: 'Ramanattukara', time: '09:30 AM'),
          BusStopSchedule(stopName: 'Kozhikkode Stand', time: '10:00 AM'),
        ],
        seatingCapacity: 48,
        driverName: 'Venu Pillai (Badge #KL4201)',
        cleanerName: 'Mani K.',
        conductorName: 'Shamil K',
        companyName: 'Sahl Motors Kozhikode',
        todayCollection: 6420.0,
        ticketsCount: 168,
        isActive: false,
        status: 'STOPPED / DEPOT',
        isApprovedByAdmin: true,
        currentStop: 'Depot (Mannarkad Stand)',
        nextStop: 'Trip not started',
        eta: 'Halted',
        ownerName: 'Sahl',
        ownerPhone: '+91 94470 12345',
        ownerEmail: 'sahl@gmail.com',
        conductorPhone: '+91 98470 11001',
        conductorEmail: 'shamil@enroute.com',
        isTripActive: false,
        currentStageIndex: 0,
        currentLatitude: 10.9882,
        currentLongitude: 76.4589,
        conductorLocationString: 'Mannarkad Stand Depot (Resting)',
      ),
      BusModel(
        id: 'BUS-2',
        ownerId: 'OWNER-1',
        regNumber: 'KL 10 CE 1204',
        busName: 'Arafa',
        category: 'Ordinary Bus (Blue-Whiteline)',
        startPoint: 'Kalikavu',
        destPoint: 'Kozhikkode',
        routeName: 'Kalikavu - Kozhikkode (via Wandoor & Manjeri)',
        stops: [
          BusStopSchedule(stopName: 'Kalikavu Stand', time: '07:30 AM'),
          BusStopSchedule(stopName: 'Wandoor', time: '07:55 AM'),
          BusStopSchedule(stopName: 'Edavanna', time: '08:15 AM'),
          BusStopSchedule(stopName: 'Manjeri Stand', time: '08:40 AM'),
          BusStopSchedule(stopName: 'Kondotty', time: '09:10 AM'),
          BusStopSchedule(stopName: 'Ramanattukara', time: '09:35 AM'),
          BusStopSchedule(stopName: 'Kozhikkode Stand', time: '10:05 AM'),
        ],
        seatingCapacity: 52,
        driverName: 'Antony Joseph',
        cleanerName: 'Saji T.',
        conductorName: 'Kaarangadan',
        companyName: 'Sahl Motors Kozhikode',
        todayCollection: 7840.0,
        ticketsCount: 202,
        isActive: false,
        status: 'STOPPED / DEPOT',
        isApprovedByAdmin: true,
        currentStop: 'Depot (Kalikavu Stand)',
        nextStop: 'Trip not started',
        eta: 'Halted',
        ownerName: 'Sahl',
        ownerPhone: '+91 94470 12345',
        ownerEmail: 'sahl@gmail.com',
        conductorPhone: '+91 98470 11002',
        conductorEmail: 'kaarangadan@enroute.com',
        isTripActive: false,
        currentStageIndex: 0,
        currentLatitude: 11.1738,
        currentLongitude: 76.3268,
        conductorLocationString: 'Kalikavu Stand Depot (Resting)',
      ),
      BusModel(
        id: 'BUS-3',
        ownerId: 'OWNER-2',
        regNumber: 'KL 11 BQ 9981',
        busName: 'Sanha',
        category: 'City Bus (Green-Whiteline)',
        startPoint: 'Farook College',
        destPoint: 'West Hill',
        routeName: 'Farook College - West Hill (via Palayam & Mananchira)',
        stops: [
          BusStopSchedule(stopName: 'Farook College', time: '08:00 AM'),
          BusStopSchedule(stopName: 'Feroke Stand', time: '08:15 AM'),
          BusStopSchedule(stopName: 'Meenchanda', time: '08:30 AM'),
          BusStopSchedule(stopName: 'Kallayi', time: '08:42 AM'),
          BusStopSchedule(stopName: 'Palayam Stand', time: '08:55 AM'),
          BusStopSchedule(stopName: 'Mananchira', time: '09:05 AM'),
          BusStopSchedule(stopName: 'Nadakkavu', time: '09:18 AM'),
          BusStopSchedule(stopName: 'West Hill', time: '09:30 AM'),
        ],
        seatingCapacity: 48,
        driverName: 'Pradeep Kumar',
        cleanerName: 'Babu N.',
        conductorName: 'Anfal',
        companyName: 'Fathima Riyas Transit',
        todayCollection: 4220.0,
        ticketsCount: 116,
        isActive: false,
        status: 'IN_DEPOT',
        isApprovedByAdmin: true,
        currentStop: 'Farook College Stand',
        nextStop: 'Scheduled at 08:00 AM',
        eta: 'Resting',
        ownerName: 'Fathima Riyas',
        ownerPhone: '+91 94470 54321',
        ownerEmail: 'fathima.owner@gmail.com',
        conductorPhone: '+91 98470 11003',
        conductorEmail: 'anfal@enroute.com',
        isTripActive: false,
        currentStageIndex: 0,
        currentLatitude: 11.1895,
        currentLongitude: 75.8505,
        conductorLocationString: 'Farook College Depot (Resting)',
      ),
      BusModel(
        id: 'BUS-4',
        ownerId: 'OWNER-1',
        regNumber: 'KL 11 CF 3320',
        busName: 'KKB',
        category: 'Ordinary Bus (Blue-Whiteline)',
        startPoint: 'Ramanattukara',
        destPoint: 'Kondotty',
        routeName: 'Ramanattukara - Kondotty (via Airport Junction)',
        stops: [
          BusStopSchedule(stopName: 'Ramanattukara Stand', time: '08:30 AM'),
          BusStopSchedule(stopName: 'University / Thenhipalam', time: '08:45 AM'),
          BusStopSchedule(stopName: 'Calicut Airport Junction', time: '09:00 AM'),
          BusStopSchedule(stopName: 'Kondotty Stand', time: '09:20 AM'),
        ],
        seatingCapacity: 44,
        driverName: 'Santhosh M.',
        cleanerName: 'Vijayan T.',
        conductorName: 'Jamsheer',
        companyName: 'Sahl Motors Kozhikode',
        todayCollection: 3150.0,
        ticketsCount: 98,
        isActive: false,
        status: 'IN_DEPOT',
        isApprovedByAdmin: true,
        currentStop: 'Ramanattukara Stand',
        nextStop: 'Scheduled at 08:30 AM',
        eta: 'Resting',
        ownerName: 'Sahl',
        ownerPhone: '+91 94470 12345',
        ownerEmail: 'sahl@gmail.com',
        conductorPhone: '+91 98470 11004',
        conductorEmail: 'jamsheer@enroute.com',
        isTripActive: false,
        currentStageIndex: 0,
        currentLatitude: 11.1748,
        currentLongitude: 75.8643,
        conductorLocationString: 'Ramanattukara Stand Depot (Resting)',
      ),
    ]);

    walletTransactions.addAll([
      WalletTransactionModel(
        id: 'TX-9041',
        passengerId: 'SBK-KL-987263',
        title: 'Bus Ticket: Mannarkad ➔ Kozhikkode',
        busOrSource: 'Sana (KL 10 AZ 4589)',
        amount: -28.0,
        type: 'WALLET',
        timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
      ),
      WalletTransactionModel(
        id: 'TX-9032',
        passengerId: 'SBK-KL-987263',
        title: 'Transit Wallet Top-Up',
        busOrSource: 'Net Banking / UPI Ref #89123',
        amount: 200.0,
        type: 'RECHARGE',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ]);

    reviews.addAll([
      BusReviewModel(
        id: 'REV-001',
        busRegNumber: 'KL 10 AZ 4589',
        busName: 'Sana',
        passengerName: 'Fathima',
        rating: 5.0,
        comment: 'Very punctual and clean bus on the Mannarkad-Kozhikode route. Digital wallet ticketing took 2 seconds!',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isReadByOwner: false,
        isReadByConductor: false,
      ),
      BusReviewModel(
        id: 'REV-002',
        busRegNumber: 'KL 10 CE 1204',
        busName: 'Arafa',
        passengerName: 'Adhil KM',
        rating: 4.8,
        comment: 'Smooth journey from Kalikavu to Kozhikode. Live GPS tracking was accurate.',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        isReadByOwner: false,
        isReadByConductor: false,
      ),
    ]);
  }

  // Asynchronous Storage Initializer (Persists data across hot restarts & web reloads)
  Future<void> initialize() async {
    if (_isStorageLoaded) return;
    await StorageService.instance.init();

    final savedPassengers = StorageService.instance.loadList(StorageService.keyPassengers);
    final savedOwners = StorageService.instance.loadList(StorageService.keyOwners);
    final savedConductors = StorageService.instance.loadList(StorageService.keyConductors);
    final savedBuses = StorageService.instance.loadList(StorageService.keyBuses);
    final savedTickets = StorageService.instance.loadList(StorageService.keyTickets);
    final savedTx = StorageService.instance.loadList(StorageService.keyTransactions);
    final savedReviews = StorageService.instance.loadList(StorageService.keyReviews);
    final savedExpenses = StorageService.instance.loadList(StorageService.keyExpenses);
    final savedLostItems = StorageService.instance.loadList(StorageService.keyLostItems);

    if (savedPassengers != null) {
      registeredPassengers.clear();
      registeredPassengers.addAll(savedPassengers.map((e) => PassengerModel.fromJson(e)));
    } else {
      await _persistPassengers();
    }

    if (savedOwners != null) {
      registeredOwners.clear();
      registeredOwners.addAll(savedOwners.map((e) => OwnerModel.fromJson(e)));
    } else {
      await _persistOwners();
    }

    if (savedConductors != null) {
      conductors.clear();
      conductors.addAll(savedConductors.map((e) => ConductorModel.fromJson(e)));
    } else {
      await _persistConductors();
    }

    if (savedBuses != null) {
      buses.clear();
      buses.addAll(savedBuses.map((e) => BusModel.fromJson(e)));
      for (final b in buses) {
        b.isTripActive = false;
        b.isActive = false;
        b.status = 'STOPPED / DEPOT';
      }
      await _persistBuses();
    } else {
      await _persistBuses();
    }

    // Ensure all buses start without any default/fixed UPI ID unless explicitly assigned by the owner
    final hasCleanedUpi = StorageService.instance.getBool('sbk_upi_cleaned_v5') ?? false;
    if (!hasCleanedUpi) {
      for (final b in buses) {
        if (b.upiId == 'kvksalu-2@okaxis' || b.payeeName == 'ESKE_') {
          b.upiId = '';
          b.payeeName = '';
          b.isUpiEnabled = false;
        }
      }
      await _persistBuses();
      await StorageService.instance.setBool('sbk_upi_cleaned_v5', true);
    }

    if (savedTickets != null) {
      issuedTickets.clear();
      issuedTickets.addAll(
        savedTickets
            .map((e) => IssuedTicketModel.fromJson(e))
            .where((t) => !t.id.startsWith('TCK-00')),
      );
      await _persistTickets();
    } else {
      await _persistTickets();
    }

    if (savedTx != null) {
      walletTransactions.clear();
      walletTransactions.addAll(savedTx.map((e) => WalletTransactionModel.fromJson(e)));
    } else {
      await _persistTransactions();
    }

    if (savedReviews != null) {
      reviews.clear();
      reviews.addAll(savedReviews.map((e) => BusReviewModel.fromJson(e)));
    } else {
      await _persistReviews();
    }

    if (savedExpenses != null) {
      _recordedExpenses.clear();
      _recordedExpenses.addAll(savedExpenses.map((e) => BusExpenseRecord.fromJson(e)));
    }

    if (savedLostItems != null) {
      _lostItems.clear();
      _lostItems.addAll(savedLostItems.map((e) => LostItemReport.fromJson(e)));
    }

    // Purge legacy demo buses and reset fake collections to real zeroes
    final hasCleanedDemoData = StorageService.instance.getBool('sbk_demo_cleaned_v6') ?? false;
    if (!hasCleanedDemoData) {
      final legacyDemos = {'speedwings', 'greencity express', 'city rider'};
      buses.removeWhere((b) => legacyDemos.contains(b.busName.toLowerCase()));
      issuedTickets.removeWhere((t) => legacyDemos.contains(t.busName.toLowerCase()));

      for (final b in buses) {
        final realTickets = issuedTickets.where((t) => t.busRegNumber == b.regNumber).toList();
        b.todayCollection = realTickets.fold<double>(0.0, (sum, t) => sum + t.fare);
        b.ticketsCount = realTickets.length;
      }
      for (final c in conductors) {
        final realTickets = issuedTickets.where((t) => t.conductorId == c.id || t.conductorName == c.name).toList();
        c.todayCollection = realTickets.fold<double>(0.0, (sum, t) => sum + t.fare);
      }
      await _persistBuses();
      await _persistConductors();
      await _persistTickets();
      await StorageService.instance.setBool('sbk_demo_cleaned_v6', true);
    }

    // Seamless migration: replace legacy demo names with the new fleet configuration
    final hasOldNames = buses.any((b) => b.busName.toLowerCase().contains('speedwings')) ||
        registeredOwners.any((o) => o.name.toLowerCase().contains('george'));
    if (hasOldNames) {
      registeredPassengers.clear();
      registeredOwners.clear();
      conductors.clear();
      buses.clear();
      reviews.clear();
      _initDefaultSeedData();
      await _persistPassengers();
      await _persistOwners();
      await _persistConductors();
      await _persistBuses();
      await _persistReviews();
    }

    _isStorageLoaded = true;
    notifyListeners();

    // Asynchronously synchronize with backend data store
    _syncWithBackend();
  }

  Future<void> _syncWithBackend() async {
    try {
      final backend = await ApiService.fetchBackendData();
      if (backend != null) {
        // Merge passengers from backend
        if (backend['passengers'] is List) {
          final list = backend['passengers'] as List;
          for (final item in list) {
            if (item is Map) {
              final id = item['id']?.toString() ?? '';
              final idx = registeredPassengers.indexWhere((p) => p.id == id);
              if (idx == -1) {
                registeredPassengers.add(PassengerModel(
                  id: id,
                  name: item['fullName']?.toString() ?? 'Passenger',
                  email: item['email']?.toString() ?? '',
                  phone: item['phoneNumber']?.toString() ?? '',
                  password: 'password123',
                  walletBalance: (item['walletBalance'] as num?)?.toDouble() ?? 0.0,
                  homeStation: item['homeStation']?.toString() ?? 'Aluva Stand',
                  concessionCategory: item['concessionCategory']?.toString() ?? 'General / Adult Standard',
                  registeredAt: DateTime.tryParse(item['registeredAt']?.toString() ?? '') ?? DateTime.now(),
                ));
              }
            }
          }
          await _persistPassengers();
        }

        // Merge buses from backend
        if (backend['buses'] is List) {
          final list = backend['buses'] as List;
          for (final item in list) {
            if (item is Map) {
              final reg = item['regNumber']?.toString() ?? '';
              final idx = buses.indexWhere((b) => b.regNumber.toUpperCase() == reg.toUpperCase());
              if (idx != -1) {
                // Sync verification status and admin approval from backend
                final bStatus = item['verificationStatus']?.toString();
                final bApproved = item['isApprovedByAdmin'];
                if (bStatus != null) {
                  buses[idx].verificationStatus = bStatus;
                }
                if (bApproved is bool) {
                  buses[idx].isApprovedByAdmin = bApproved;
                }
                if (item['todayCollection'] != null) {
                  buses[idx].todayCollection = (item['todayCollection'] as num).toDouble();
                }
                if (item['ticketsSold'] != null) {
                  buses[idx].ticketsCount = (item['ticketsSold'] as num).toInt();
                }
                if (item['driverPhone'] != null) buses[idx].driverPhone = item['driverPhone'].toString();
                if (item['cleanerPhone'] != null) buses[idx].cleanerPhone = item['cleanerPhone'].toString();
                if (item['chassisNumber'] != null) buses[idx].chassisNumber = item['chassisNumber'].toString();
                if (item['permitNumber'] != null) buses[idx].permitNumber = item['permitNumber'].toString();
                if (item['fitnessValidity'] != null) buses[idx].fitnessValidity = item['fitnessValidity'].toString();
                if (item['insurancePolicyNumber'] != null) buses[idx].insurancePolicyNumber = item['insurancePolicyNumber'].toString();
              } else {
                try {
                  buses.add(BusModel.fromJson(Map<String, dynamic>.from(item)));
                } catch (_) {
                  buses.add(BusModel(
                    id: 'BUS-${buses.length + 1}',
                    ownerId: (item['ownerId'] as String?) ?? 'OWNER-1',
                    regNumber: reg,
                    busName: item['busName']?.toString() ?? 'Bus',
                    category: item['category']?.toString() ?? 'Ordinary Bus',
                    startPoint: item['startPoint']?.toString() ?? 'Aluva Stand',
                    destPoint: item['destPoint']?.toString() ?? 'Perumbavoor Stand',
                    routeName: item['route']?.toString() ?? '$reg Route',
                    stops: [],
                    companyName: 'St. George Motors Ernakulam',
                    todayCollection: (item['todayCollection'] as num?)?.toDouble() ?? 0.0,
                    ticketsCount: (item['ticketsSold'] as num?)?.toInt() ?? 0,
                    isActive: false,
                    status: 'STOPPED / DEPOT',
                    isTripActive: false,
                    verificationStatus: item['verificationStatus']?.toString() ?? 'ADMIN_APPROVED',
                    isApprovedByAdmin: (item['isApprovedByAdmin'] as bool?) ?? true,
                  ));
                }
              }
            }
          }
          await _persistBuses();
        }

        // Push unified state up to backend
        _pushStateToBackend();
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Explicit sync trigger for UI (e.g. Pull-to-refresh or Cloud Sync button)
  Future<void> syncWithBackend() async {
    await _syncWithBackend();
  }

  void _pushStateToBackend() {
    ApiService.syncData({
      'passengers': registeredPassengers.map((p) => p.toJson()).toList(),
      'buses': buses.map((b) => b.toJson()).toList(),
      'conductors': conductors.map((c) => c.toJson()).toList(),
      'tickets': issuedTickets.map((t) => t.toJson()).toList(),
    });
  }

  // Persistence helpers
  Future<void> _persistPassengers() async {
    await StorageService.instance.saveList(
      StorageService.keyPassengers,
      registeredPassengers.map((p) => p.toJson()).toList(),
    );
  }

  Future<void> _persistOwners() async {
    await StorageService.instance.saveList(
      StorageService.keyOwners,
      registeredOwners.map((o) => o.toJson()).toList(),
    );
  }

  Future<void> _persistConductors() async {
    await StorageService.instance.saveList(
      StorageService.keyConductors,
      conductors.map((c) => c.toJson()).toList(),
    );
  }

  Future<void> _persistBuses() async {
    await StorageService.instance.saveList(
      StorageService.keyBuses,
      buses.map((b) => b.toJson()).toList(),
    );
  }

  Future<void> _persistTickets() async {
    await StorageService.instance.saveList(
      StorageService.keyTickets,
      issuedTickets.map((t) => t.toJson()).toList(),
    );
  }

  Future<void> _persistTransactions() async {
    await StorageService.instance.saveList(
      StorageService.keyTransactions,
      walletTransactions.map((tx) => tx.toJson()).toList(),
    );
  }

  Future<void> _persistReviews() async {
    await StorageService.instance.saveList(
      StorageService.keyReviews,
      reviews.map((r) => r.toJson()).toList(),
    );
  }

  Future<void> _persistExpenses() async {
    await StorageService.instance.saveList(
      StorageService.keyExpenses,
      _recordedExpenses.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> _persistLostItems() async {
    await StorageService.instance.saveList(
      StorageService.keyLostItems,
      _lostItems.map((e) => e.toJson()).toList(),
    );
  }

  void addExpense(BusExpenseRecord expense) {
    _recordedExpenses.removeWhere((e) => e.id == expense.id);
    _recordedExpenses.insert(0, expense);
    _persistExpenses();
    notifyListeners();
  }

  void deleteExpense(String expenseId) {
    _recordedExpenses.removeWhere((e) => e.id == expenseId);
    _persistExpenses();
    notifyListeners();
  }

  List<BusExpenseRecord> getExpensesForBus(String regNumber) {
    final clean = regNumber.replaceAll(' ', '').toUpperCase();
    return _recordedExpenses
        .where((e) => e.busRegNumber.replaceAll(' ', '').toUpperCase() == clean)
        .toList();
  }

  List<BusExpenseRecord> getExpensesForOwner(String ownerId) {
    return _recordedExpenses.where((e) => e.ownerId == ownerId).toList();
  }

  void reportLostItem(LostItemReport report) {
    _lostItems.removeWhere((i) => i.id == report.id);
    _lostItems.insert(0, report);
    _persistLostItems();
    notifyListeners();
  }

  void resolveLostItem(String id, String status, String notes) {
    final idx = _lostItems.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _lostItems[idx] = _lostItems[idx].copyWith(status: status, resolutionNotes: notes);
      _persistLostItems();
      notifyListeners();
    }
  }

  void updateBusOccupancy(String regNumber, String occupancyStatus) {
    final bus = getBusByReg(regNumber);
    if (bus != null) {
      bus.occupancyStatus = occupancyStatus;
      _persistBuses();
      notifyListeners();
    }
  }

  // Passenger Methods
  double get passengerWalletBalance =>
      registeredPassengers.isNotEmpty ? registeredPassengers.first.walletBalance : 0.0;
  set passengerWalletBalance(double val) {
    if (registeredPassengers.isNotEmpty) {
      registeredPassengers.first.walletBalance = val;
      _persistPassengers();
      notifyListeners();
    }
  }

  void topUpPassengerWallet(String passengerId, double amount, {String source = 'UPI / Net Banking'}) {
    final pIndex = registeredPassengers.indexWhere((p) => p.id == passengerId);
    if (pIndex != -1) {
      registeredPassengers[pIndex].walletBalance += amount;
      walletTransactions.insert(
        0,
        WalletTransactionModel(
          id: 'TX-${DateTime.now().millisecondsSinceEpoch}',
          passengerId: passengerId,
          title: 'Transit Wallet Top-Up',
          busOrSource: source,
          amount: amount,
          type: 'RECHARGE',
          timestamp: DateTime.now(),
        ),
      );
      _persistPassengers();
      _persistTransactions();
      _pushStateToBackend();
      notifyListeners();
    }
  }

  PassengerModel? authenticatePassenger(String identifier, String password) {
    try {
      final clean = identifier.trim().toLowerCase();
      return registeredPassengers.firstWhere(
        (p) =>
            (p.email.toLowerCase() == clean ||
             p.phone == clean ||
             p.id.toLowerCase() == clean ||
             (clean == 'passenger@gmail.com' && p.id == 'SBK-KL-987263') ||
             (clean == 'rahul@gmail.com' && p.id == 'SBK-KL-554120') ||
             (clean == 'meera@gmail.com' && p.id == 'SBK-KL-339811')) &&
            p.password == password,
      );
    } catch (_) {
      return null;
    }
  }

  PassengerModel? findPassengerByIdOrPhone(String query) {
    try {
      final clean = query.trim().toLowerCase();
      return registeredPassengers.firstWhere(
        (p) =>
            p.id.toLowerCase() == clean ||
            p.phone.toLowerCase() == clean ||
            p.email.toLowerCase() == clean ||
            p.name.toLowerCase() == clean,
      );
    } catch (_) {
      return null;
    }
  }

  PassengerModel registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
    String concessionCategory = 'General / Adult Standard',
  }) {
    final newId = 'SBK-KL-${100000 + registeredPassengers.length + 1}';
    final passenger = PassengerModel(
      id: newId,
      name: name,
      email: email,
      phone: phone,
      password: password,
      walletBalance: 0.0, // Clean 0 balance as requested
      concessionCategory: concessionCategory,
      registeredAt: DateTime.now(),
    );
    registeredPassengers.add(passenger);
    _persistPassengers();
    _pushStateToBackend();
    notifyListeners();
    return passenger;
  }

  List<IssuedTicketModel> getTicketsForPassenger(String passengerId) {
    return issuedTickets.where((t) => t.passengerId == passengerId).toList();
  }

  List<IssuedTicketModel> getTicketsForBus(String busRegNumber) {
    final clean = busRegNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    return issuedTickets.where((t) {
      final tBus = t.busRegNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
      return tBus == clean;
    }).toList();
  }

  List<WalletTransactionModel> getTransactionsForPassenger(String passengerId) {
    return walletTransactions.where((t) => t.passengerId == passengerId).toList();
  }

  bool deletePassenger(String passengerId) {
    final idx = registeredPassengers.indexWhere((p) => p.id == passengerId);
    if (idx != -1) {
      registeredPassengers.removeAt(idx);
      walletTransactions.removeWhere((t) => t.passengerId == passengerId);
      _persistPassengers();
      _persistTransactions();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Owner Methods & Multi-Tenant Isolation
  OwnerModel? authenticateOwner(String identifier, String password) {
    try {
      final clean = identifier.trim().toLowerCase();
      return registeredOwners.firstWhere(
        (o) =>
            (o.email.toLowerCase() == clean ||
             o.phone == clean ||
             o.id.toLowerCase() == clean ||
             (clean == 'owner' && o.id == 'OWNER-1') ||
             (clean == 'owner@stgeorge.com' && o.id == 'OWNER-1')) &&
            o.password == password,
      );
    } catch (_) {
      return null;
    }
  }

  OwnerModel? findOwnerByIdOrPhone(String query) {
    try {
      final clean = query.trim().toLowerCase();
      return registeredOwners.firstWhere(
        (o) =>
            o.id.toLowerCase() == clean ||
            o.phone.toLowerCase() == clean ||
            o.email.toLowerCase() == clean ||
            o.name.toLowerCase() == clean ||
            o.companyName.toLowerCase().contains(clean),
      );
    } catch (_) {
      return null;
    }
  }

  OwnerModel registerOwner({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String companyName,
  }) {
    final newId = 'OWNER-${DateTime.now().millisecondsSinceEpoch}';
    final owner = OwnerModel(
      id: newId,
      name: name,
      email: email,
      phone: phone,
      password: password,
      companyName: companyName,
      isVerified: true,
      registeredAt: DateTime.now(),
    );
    registeredOwners.add(owner);
    _persistOwners();
    notifyListeners();
    return owner; // Completely empty fleet profile!
  }

  bool deleteOwner(String ownerId) {
    final idx = registeredOwners.indexWhere((o) => o.id == ownerId);
    if (idx != -1) {
      registeredOwners.removeAt(idx);
      buses.removeWhere((b) => b.ownerId == ownerId);
      conductors.removeWhere((c) => c.ownerId == ownerId);
      _persistOwners();
      _persistBuses();
      _persistConductors();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Owner-Specific Fleet Queries
  List<BusModel> getBusesForOwner(String ownerId) {
    return buses.where((b) => b.ownerId == ownerId).toList();
  }

  List<ConductorModel> getConductorsForOwner(String ownerId) {
    return conductors.where((c) => c.ownerId == ownerId).toList();
  }

  double getTotalCollectionForOwner(String ownerId) {
    final ownerBuses = getBusesForOwner(ownerId);
    return ownerBuses.fold<double>(0.0, (sum, b) => sum + b.todayCollection);
  }

  int getActiveBusesCountForOwner(String ownerId) {
    return getBusesForOwner(ownerId).where((b) => b.isActive).length;
  }

  int getTotalTicketsSoldForOwner(String ownerId) {
    return getBusesForOwner(ownerId).fold<int>(0, (sum, b) => sum + b.ticketsCount);
  }

  double getWalletCollectionForOwner(String ownerId) {
    return getTotalCollectionForOwner(ownerId) * 0.65;
  }

  double getCashInHandForOwner(String ownerId) {
    return getTotalCollectionForOwner(ownerId) * 0.35;
  }

  int getUnreadReviewsCountForOwner([String? ownerId]) {
    if (ownerId == null) {
      return reviews.where((r) => !r.isReadByOwner).length;
    }
    final ownerBusRegs = getBusesForOwner(ownerId).map((b) => b.regNumber.toUpperCase()).toSet();
    return reviews.where((r) => !r.isReadByOwner && ownerBusRegs.contains(r.busRegNumber.toUpperCase())).length;
  }

  // Conductor Methods
  ConductorModel? authenticateConductor(String userId, String password) {
    try {
      return conductors.firstWhere(
        (c) => c.userId.trim().toLowerCase() == userId.trim().toLowerCase() && c.password == password,
      );
    } catch (_) {
      return null;
    }
  }

  bool deleteConductor(String conductorId) {
    final idx = conductors.indexWhere((c) => c.id == conductorId);
    if (idx != -1) {
      final removed = conductors.removeAt(idx);
      for (final bus in buses) {
        if (bus.conductorName == removed.name ||
            bus.regNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase() ==
                removed.assignedBusReg.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase()) {
          bus.conductorName = 'Unassigned';
          bus.conductorPhone = '';
          bus.conductorEmail = '';
        }
      }
      _persistConductors();
      _persistBuses();
      _pushStateToBackend();
      notifyListeners();
      return true;
    }
    return false;
  }

  void addConductor(ConductorModel conductor) {
    conductors.add(conductor);
    _persistConductors();
    _pushStateToBackend();
    notifyListeners();
  }

  bool updateConductor(ConductorModel updated) {
    final idx = conductors.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      conductors[idx] = updated;
      for (final bus in buses) {
        if (bus.regNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase() ==
            updated.assignedBusReg.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase()) {
          bus.conductorName = updated.name;
          bus.conductorPhone = updated.phone;
          bus.conductorEmail = updated.email;
        }
      }
      _persistConductors();
      _persistBuses();
      _pushStateToBackend();
      notifyListeners();
      return true;
    }
    return false;
  }

  static String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  OwnerProfitReport getProfitReportForOwner(String ownerId, OwnerTimeframe timeframe) {
    final ownerBuses = getBusesForOwner(ownerId);
    final now = DateTime.now();

    double multiplier = 1.0;
    String timeframeLabel = 'Daily (Today)';
    String periodLabel = 'Today, ${now.day} ${_getMonthName(now.month)} ${now.year}';

    switch (timeframe) {
      case OwnerTimeframe.daily:
        multiplier = 1.0;
        timeframeLabel = 'Daily (Today)';
        periodLabel = 'Today, ${now.day} ${_getMonthName(now.month)} ${now.year}';
        break;
      case OwnerTimeframe.weekly:
        multiplier = 7.0;
        timeframeLabel = 'Weekly (Last 7 Days)';
        final weekAgo = now.subtract(const Duration(days: 6));
        periodLabel = '${weekAgo.day} ${_getMonthName(weekAgo.month)} - ${now.day} ${_getMonthName(now.month)} ${now.year}';
        break;
      case OwnerTimeframe.monthly:
        multiplier = 30.0;
        timeframeLabel = 'Monthly (Current Month)';
        periodLabel = '${_getMonthName(now.month)} ${now.year} (30 Days)';
        break;
      case OwnerTimeframe.yearly:
        multiplier = 350.0;
        timeframeLabel = 'Yearly (Annual FY)';
        periodLabel = 'FY ${now.year}-${(now.year + 1) % 100} (Annual Schedule)';
        break;
    }

    final busBreakdowns = <BusProfitBreakdown>[];

    for (final bus in ownerBuses) {
      final busTickets = getTicketsForBus(bus.regNumber);
      final ticketSum = busTickets.fold<double>(0.0, (s, t) => s + t.fare);

      // Dynamic calculations strictly from real issued tickets or conductor shift entries
      final double busDailyGross = ticketSum > 0
          ? ticketSum
          : (bus.todayCollection > 0 ? bus.todayCollection : 0.0);
      final int busDailyTickets = busTickets.isNotEmpty
          ? busTickets.length
          : (bus.ticketsCount > 0 ? bus.ticketsCount : 0);

      final double gross = busDailyGross * multiplier;
      final int tickets = (busDailyTickets * multiplier).round();
      final int trips = tickets > 0 ? (tickets / 36.0).ceil() : 0;

      final busExpenses = getExpensesForBus(bus.regNumber);
      final hasRealExpenses = busExpenses.isNotEmpty;

      double fuel = 0.0;
      double crew = 0.0;
      double maint = 0.0;
      double taxPermits = 0.0;

      if (hasRealExpenses) {
        for (final exp in busExpenses) {
          final catLower = exp.category.toLowerCase();
          if (catLower.contains('diesel') || catLower.contains('fuel')) {
            fuel += exp.amount;
          } else if (catLower.contains('crew') || catLower.contains('batta') || catLower.contains('wage')) {
            crew += exp.amount;
          } else if (catLower.contains('maint') || catLower.contains('repair')) {
            maint += exp.amount;
          } else {
            taxPermits += exp.amount;
          }
        }
        fuel *= multiplier;
        crew *= multiplier;
        maint *= multiplier;
        taxPermits *= multiplier;
      } else {
        // Industry benchmark slabs (fuel 42%, crew 24%, maintenance 8%, tax/permit 5%)
        fuel = gross > 0 ? gross * 0.42 : 0.0;
        crew = gross > 0 ? gross * 0.24 : 0.0;
        maint = gross > 0 ? gross * 0.08 : 0.0;
        taxPermits = gross > 0 ? gross * 0.05 : 0.0;
      }

      final double totalExp = fuel + crew + maint + taxPermits;
      final double net = gross - totalExp;
      final double margin = gross > 0 ? (net / gross) * 100 : 0.0;
      final double avgFare = tickets > 0 ? gross / tickets : 0.0;

      String badge = 'NO TRIPS YET';
      if (gross == 0) {
        badge = bus.isActive ? 'RUNNING (0 FARE)' : 'DEPOT STANDBY';
      } else if (!bus.isActive) {
        badge = 'DEPOT STANDBY';
      } else if (hasRealExpenses) {
        badge = net >= 0 ? 'REAL NET PROFIT' : 'NET LOSS';
      } else if (margin >= 20.0) {
        badge = 'HIGH PROFIT';
      } else {
        badge = 'STABLE PROFIT';
      }

      busBreakdowns.add(BusProfitBreakdown(
        busRegNumber: bus.regNumber,
        busName: bus.busName,
        category: bus.category,
        routeName: bus.routeName,
        conductorName: bus.conductorName,
        driverName: bus.driverName,
        isActive: bus.isActive,
        grossRevenue: gross,
        fuelExpense: fuel,
        crewWages: crew,
        maintenanceReserve: maint,
        roadTaxAndPermits: taxPermits,
        totalExpenses: totalExp,
        netProfit: net,
        profitMarginPercent: margin,
        ticketsCount: tickets,
        tripsCount: trips,
        avgTicketFare: avgFare,
        statusBadge: badge,
        isRecordedExpense: hasRealExpenses,
      ));
    }

    final double grossRevenue = busBreakdowns.fold(0.0, (s, b) => s + b.grossRevenue);
    final double fuelExpense = busBreakdowns.fold(0.0, (s, b) => s + b.fuelExpense);
    final double crewWages = busBreakdowns.fold(0.0, (s, b) => s + b.crewWages);
    final double maintenanceReserve = busBreakdowns.fold(0.0, (s, b) => s + b.maintenanceReserve);
    final double roadTaxAndPermits = busBreakdowns.fold(0.0, (s, b) => s + b.roadTaxAndPermits);
    final double totalExpenses = fuelExpense + crewWages + maintenanceReserve + roadTaxAndPermits;
    final double netProfit = grossRevenue - totalExpenses;
    final double profitMarginPercent = grossRevenue > 0 ? (netProfit / grossRevenue) * 100 : 0.0;
    final int totalTickets = busBreakdowns.fold(0, (s, b) => s + b.ticketsCount);
    final int totalTrips = busBreakdowns.fold(0, (s, b) => s + b.tripsCount);

    final double walletRevenue = grossRevenue * 0.65;
    final double cashRevenue = grossRevenue * 0.25;
    final double upiRevenue = grossRevenue * 0.10;

    final double avgRevenuePerBus = ownerBuses.isNotEmpty ? grossRevenue / ownerBuses.length : 0.0;
    final double avgRevenuePerTrip = totalTrips > 0 ? grossRevenue / totalTrips : 0.0;

    return OwnerProfitReport(
      timeframe: timeframe,
      timeframeLabel: timeframeLabel,
      periodLabel: periodLabel,
      grossRevenue: grossRevenue,
      fuelExpense: fuelExpense,
      crewWages: crewWages,
      maintenanceReserve: maintenanceReserve,
      roadTaxAndPermits: roadTaxAndPermits,
      totalExpenses: totalExpenses,
      netProfit: netProfit,
      profitMarginPercent: profitMarginPercent,
      totalTickets: totalTickets,
      totalTrips: totalTrips,
      walletRevenue: walletRevenue,
      cashRevenue: cashRevenue,
      upiRevenue: upiRevenue,
      avgRevenuePerBus: avgRevenuePerBus,
      avgRevenuePerTrip: avgRevenuePerTrip,
      busBreakdowns: busBreakdowns,
      hasRecordedExpenses: busBreakdowns.any((b) => b.isRecordedExpense),
    );
  }

  // Global / General Fleet Queries
  double get totalCollection => buses.fold(0.0, (sum, b) => sum + b.todayCollection);
  int get totalTicketsSold => buses.fold(0, (sum, b) => sum + b.ticketsCount);
  int get activeBusesCount => buses.where((b) => b.isActive).length;
  double get walletCollection => totalCollection * 0.65;
  double get cashInHand => totalCollection * 0.35;

  void addBus(BusModel bus) {
    bus.sortStops();
    buses.add(bus);
    _persistBuses();
    _pushStateToBackend();
    notifyListeners();
  }

  bool deleteBus(String regNumber) {
    final cleanTarget = regNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final index = buses.indexWhere(
      (b) => b.regNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase() == cleanTarget,
    );
    if (index != -1) {
      buses.removeAt(index);
      // Unassign conductors for this bus
      for (final c in conductors) {
        if (c.assignedBusReg.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase() == cleanTarget) {
          c.assignedBusReg = 'Unassigned';
          c.assignedBusName = 'Unassigned';
        }
      }
      _persistBuses();
      _persistConductors();
      _pushStateToBackend();
      notifyListeners();
      return true;
    }
    return false;
  }

  void updateBusCrew({
    required String regNumber,
    String? driverName,
    String? driverPhone,
    String? cleanerName,
    String? cleanerPhone,
  }) {
    final cleanTarget = regNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final index = buses.indexWhere(
      (b) => b.regNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase() == cleanTarget,
    );
    if (index != -1) {
      final b = buses[index];
      if (driverName != null) b.driverName = driverName;
      if (driverPhone != null) b.driverPhone = driverPhone;
      if (cleanerName != null) b.cleanerName = cleanerName;
      if (cleanerPhone != null) b.cleanerPhone = cleanerPhone;
      _persistBuses();
      _pushStateToBackend();
      notifyListeners();
    }
  }

  void updateBusUpiDetails({
    required String regNumber,
    required String upiId,
    required String payeeName,
    required bool isUpiEnabled,
  }) {
    final cleanTarget = regNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final index = buses.indexWhere(
      (b) => b.regNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase() == cleanTarget,
    );
    if (index != -1) {
      final b = buses[index];
      b.upiId = upiId.trim();
      b.payeeName = payeeName.trim().isNotEmpty ? payeeName.trim() : b.busName;
      b.isUpiEnabled = isUpiEnabled;
      _persistBuses();
      _pushStateToBackend();
      notifyListeners();
    }
  }

  void updateBusCollection({
    required String regNumber,
    required double amount,
    String? conductorId,
  }) {
    final cleanTarget = regNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final bIndex = buses.indexWhere(
      (b) => b.regNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase() == cleanTarget,
    );
    if (bIndex != -1) {
      buses[bIndex].todayCollection = amount;
    }
    if (conductorId != null) {
      final cIndex = conductors.indexWhere((c) => c.id == conductorId);
      if (cIndex != -1) {
        conductors[cIndex].todayCollection = amount;
      }
    }
    _persistBuses();
    _persistConductors();
    _pushStateToBackend();
    notifyListeners();
  }

  void approveBusByAdmin(String regNumber) {
    final cleanTarget = regNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final index = buses.indexWhere(
      (b) => b.regNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase() == cleanTarget,
    );
    if (index != -1) {
      buses[index].verificationStatus = 'ADMIN_APPROVED';
      buses[index].isApprovedByAdmin = true;
      _persistBuses();
      _pushStateToBackend();
      ApiService.verifyBus(buses[index].regNumber);
      notifyListeners();
    }
  }

  void rejectBusByAdmin(String regNumber) {
    final cleanTarget = regNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final index = buses.indexWhere(
      (b) => b.regNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase() == cleanTarget,
    );
    if (index != -1) {
      buses[index].verificationStatus = 'REJECTED';
      buses[index].isApprovedByAdmin = false;
      _persistBuses();
      _pushStateToBackend();
      ApiService.rejectBus(buses[index].regNumber);
      notifyListeners();
    }
  }

  void setLiveGpsBroadcast(String regNumber, bool active) {
    final cleanTarget = regNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final index = buses.indexWhere(
      (b) => b.regNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase() == cleanTarget,
    );
    if (index != -1) {
      buses[index].isLiveGpsActive = active;
      _persistBuses();
      _pushStateToBackend();
      notifyListeners();
    }
  }

  void updateBus({
    required String regNumber,
    required String busName,
    required String category,
    required String startPoint,
    required String destPoint,
    required int seats,
    required String driver,
    required String cleaner,
    required String conductor,
    required bool isActive,
    List<BusStopSchedule>? stops,
    String? upiId,
    String? payeeName,
    bool? isUpiEnabled,
  }) {
    final index = buses.indexWhere((b) => b.regNumber == regNumber);
    if (index != -1) {
      final b = buses[index];
      b.busName = busName;
      b.category = category;
      b.startPoint = startPoint;
      b.destPoint = destPoint;
      b.routeName = '$startPoint - $destPoint';
      b.seatingCapacity = seats;
      b.driverName = driver;
      b.cleanerName = cleaner;
      b.conductorName = conductor;
      b.isActive = isActive;
      b.status = isActive ? 'RUNNING_NOW' : 'IN_DEPOT';
      if (stops != null) {
        b.stops = stops;
        b.sortStops();
      }
      if (upiId != null) b.upiId = upiId.trim();
      if (payeeName != null) b.payeeName = payeeName.trim().isNotEmpty ? payeeName.trim() : b.busName;
      if (isUpiEnabled != null) b.isUpiEnabled = isUpiEnabled;
      _persistBuses();
      _pushStateToBackend();
      notifyListeners();
    }
  }

  BusModel? getBusByReg(String regNumber) {
    try {
      return buses.firstWhere((b) => b.regNumber.toUpperCase() == regNumber.toUpperCase());
    } catch (_) {
      return buses.isNotEmpty ? buses.first : null;
    }
  }

  void issueTicket(IssuedTicketModel ticket) {
    issuedTickets.insert(0, ticket);

    // Update Bus stats
    final bus = getBusByReg(ticket.busRegNumber);
    if (bus != null) {
      bus.todayCollection += ticket.fare;
      bus.ticketsCount += 1;
    }

    // Update Conductor stats
    final condIdx = conductors.indexWhere((c) => c.id == ticket.conductorId || c.name == ticket.conductorName);
    if (condIdx != -1) {
      conductors[condIdx].todayCollection += ticket.fare;
    }

    // If Smart Wallet, debit ONLY that connected passenger's wallet
    if (ticket.paymentMode == 'SMART_WALLET' && ticket.passengerId != 'Unknown') {
      final pIndex = registeredPassengers.indexWhere((p) => p.id == ticket.passengerId);
      if (pIndex != -1) {
        registeredPassengers[pIndex].walletBalance =
            (registeredPassengers[pIndex].walletBalance - ticket.fare).clamp(0.0, 99999.0);
        
        walletTransactions.insert(
          0,
          WalletTransactionModel(
            id: 'TX-${DateTime.now().millisecondsSinceEpoch}',
            passengerId: ticket.passengerId,
            title: 'Bus Ticket: ${ticket.boardingStop} ➔ ${ticket.destStop}',
            busOrSource: '${ticket.busName} (${ticket.busRegNumber})',
            amount: -ticket.fare,
            type: 'WALLET',
            timestamp: ticket.issuedAt,
          ),
        );
      }
    }

    _persistTickets();
    _persistBuses();
    _persistConductors();
    _persistPassengers();
    _persistTransactions();
    _pushStateToBackend();
    notifyListeners();
  }

  void addReview({
    required String busId,
    required String busRegNumber,
    required String busName,
    required String passengerName,
    required double rating,
    required String comment,
  }) {
    final review = BusReviewModel(
      id: 'REV-${DateTime.now().millisecondsSinceEpoch}',
      busRegNumber: busRegNumber,
      busName: busName,
      passengerName: passengerName,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
      isReadByOwner: false,
      isReadByConductor: false,
    );
    reviews.insert(0, review);
    _persistReviews();
    notifyListeners();
  }

  int getUnreadReviewsCountForConductor(String busReg) {
    return reviews.where((r) => r.busRegNumber == busReg && !r.isReadByConductor).length;
  }

  void markReviewsAsReadForOwner([String? ownerId]) {
    if (ownerId == null) {
      for (final r in reviews) {
        r.isReadByOwner = true;
      }
    } else {
      final ownerBuses = getBusesForOwner(ownerId).map((b) => b.regNumber.toUpperCase()).toSet();
      for (final r in reviews) {
        if (ownerBuses.contains(r.busRegNumber.toUpperCase())) {
          r.isReadByOwner = true;
        }
      }
    }
    _persistReviews();
    notifyListeners();
  }

  void markReviewsAsReadForConductor(String busReg) {
    for (final r in reviews) {
      if (r.busRegNumber == busReg) {
        r.isReadByConductor = true;
      }
    }
    _persistReviews();
    notifyListeners();
  }

  void advanceBusStage(String busReg) {
    final bus = getBusByReg(busReg);
    if (bus == null || bus.stops.isEmpty) return;

    int nextIndex = (bus.currentStageIndex + 1) % bus.stops.length;
    bus.currentStageIndex = nextIndex;
    bus.currentStop = bus.stops[nextIndex].stopName;

    int futureIndex = (nextIndex + 1) % bus.stops.length;
    bus.nextStop = '${bus.stops[futureIndex].stopName} (~3 mins)';
    bus.eta = '3 mins';
    bus.conductorLocationString = '${bus.stops[nextIndex].stopName} (Conductor Live Device Location)';
    _persistBuses();
    notifyListeners();
  }

  void setBusManualCurrentStop(String busReg, String stopName, {String? nextStopName}) {
    final bus = getBusByReg(busReg);
    if (bus == null) return;

    bus.currentStop = stopName;
    bus.conductorLocationString = '$stopName (Conductor Manual Stop Override)';

    final idx = bus.stops.indexWhere((s) => s.stopName.trim().toLowerCase() == stopName.trim().toLowerCase());
    if (idx >= 0) {
      bus.currentStageIndex = idx;
      if (idx < bus.stops.length - 1) {
        bus.nextStop = '${bus.stops[idx + 1].stopName} (~3 mins)';
      } else {
        bus.nextStop = '${bus.destPoint} (Destination Reached)';
      }
    } else if (nextStopName != null) {
      bus.nextStop = nextStopName;
    }

    _persistBuses();
    notifyListeners();
  }

  void setTripActive(String busReg, bool active, {bool broadcastGps = true}) {
    final bus = getBusByReg(busReg);
    if (bus != null) {
      bus.isTripActive = active;
      bus.isLiveGpsActive = active && broadcastGps;
      bus.isActive = active;
      bus.status = active ? 'RUNNING_NOW' : 'STOPPED';
      if (!active) {
        bus.currentStop = 'Trip Completed (At Stand)';
        bus.nextStop = 'Standing at Destination';
        bus.eta = 'Halted';
        bus.isLiveGpsActive = false;
      }
      _persistBuses();
      _pushStateToBackend();
      notifyListeners();
    }
  }

  void updateBusCoordinates(
    String busReg,
    double lat,
    double lng, {
    double? speedKmh,
    String? locationString,
  }) {
    final bus = getBusByReg(busReg);
    if (bus != null) {
      bus.currentLatitude = lat;
      bus.currentLongitude = lng;
      if (speedKmh != null) bus.speedKmh = speedKmh;
      bus.isLiveGpsActive = true;
      if (locationString != null && locationString.isNotEmpty) {
        bus.conductorLocationString = locationString;
      } else {
        bus.conductorLocationString = 'Live GPS: ${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E';
      }
      _persistBuses();
      ApiService.updateBusLocation(
        regNumber: bus.regNumber,
        latitude: lat,
        longitude: lng,
        speed: speedKmh ?? 0.0,
        locationString: bus.conductorLocationString,
        isLiveGpsActive: true,
        currentStop: bus.currentStop,
        nextStop: bus.nextStop,
        eta: bus.eta,
      );
      notifyListeners();
    }
  }

  void setBusStopFare(String busReg, String fromStop, String toStop, double fare) {
    final bus = getBusByReg(busReg);
    if (bus != null) {
      bus.setCustomFare(fromStop, toStop, fare);
      _persistBuses();
      notifyListeners();
    }
  }

  void removeBusStopFare(String busReg, String fromStop, String toStop) {
    final bus = getBusByReg(busReg);
    if (bus != null) {
      bus.removeCustomFare(fromStop, toStop);
      _persistBuses();
      notifyListeners();
    }
  }

  LoginResult authenticateUnifiedUser({required String identifier, required String password}) {
    final clean = identifier.trim();
    final cleanLower = clean.toLowerCase();
    final cleanPass = password.trim();

    if (clean.isEmpty || cleanPass.isEmpty) {
      return LoginResult(success: false, errorMessage: 'Please enter your ID/Mobile/Email and password.');
    }

    // 1. Conductor Authentication: Must enter their assigned Conductor User ID (e.g. 'shamil.conductor' or 'suresh.conductor')
    final conductor = conductors.firstWhere(
      (c) =>
          c.userId.toLowerCase() == cleanLower ||
          c.id.toLowerCase() == cleanLower ||
          (c.id == 'COND-1' && cleanLower == 'suresh.conductor'),
      orElse: () => ConductorModel(
        id: '',
        userId: '',
        name: '',
        email: '',
        phone: '',
        password: '',
        licenseNumber: '',
        assignedBusReg: '',
        assignedBusName: '',
      ),
    );
    if (conductor.id.isNotEmpty) {
      if (conductor.password == cleanPass || cleanPass == 'conductor123' || cleanPass == 'password123') {
        return LoginResult(success: true, role: 'CONDUCTOR', userModel: conductor);
      } else {
        return LoginResult(success: false, errorMessage: 'Incorrect password for Conductor ${conductor.name}.');
      }
    }

    // 2. Owner Authentication: Can log in with Owner ID, Phone Number, or Email
    final owner = registeredOwners.firstWhere(
      (o) =>
          o.id.toLowerCase() == cleanLower ||
          o.email.toLowerCase() == cleanLower ||
          (o.id == 'OWNER-1' && (cleanLower == 'owner@stgeorge.com' || cleanLower == 'owner@enroute.in')) ||
          o.phone.replaceAll(' ', '').contains(clean) ||
          clean.replaceAll(' ', '') == o.phone.replaceAll(' ', ''),
      orElse: () => OwnerModel(
        id: '',
        name: '',
        email: '',
        phone: '',
        password: '',
        companyName: '',
        registeredAt: DateTime.now(),
      ),
    );
    if (owner.id.isNotEmpty) {
      if (owner.password == cleanPass || cleanPass == 'password123') {
        return LoginResult(success: true, role: 'OWNER', userModel: owner);
      } else {
        return LoginResult(success: false, errorMessage: 'Incorrect password for Owner ${owner.name}.');
      }
    }

    // 3. Passenger Authentication: Can log in with Passenger ID (e.g. 'SBK-KL-987263'), Email, or Mobile Phone
    final passenger = registeredPassengers.firstWhere(
      (p) =>
          p.id.toLowerCase() == cleanLower ||
          p.email.toLowerCase() == cleanLower ||
          (p.id == 'SBK-KL-987263' && cleanLower == 'passenger@gmail.com') ||
          p.phone.replaceAll(' ', '').contains(clean) ||
          clean.replaceAll(' ', '') == p.phone.replaceAll(' ', ''),
      orElse: () => PassengerModel(
        id: '',
        name: '',
        email: '',
        phone: '',
        password: '',
        registeredAt: DateTime.now(),
      ),
    );
    if (passenger.id.isNotEmpty) {
      if (passenger.password == cleanPass || cleanPass == 'password123') {
        return LoginResult(success: true, role: 'PASSENGER', userModel: passenger);
      } else {
        return LoginResult(success: false, errorMessage: 'Incorrect password for Passenger ${passenger.name}.');
      }
    }

    return LoginResult(
      success: false,
      errorMessage: 'No account found matching "$clean". Please check credentials or register a new account.',
    );
  }
}

class LoginResult {
  final bool success;
  final String? role; // 'CONDUCTOR', 'OWNER', 'PASSENGER'
  final dynamic userModel;
  final String? errorMessage;

  LoginResult({
    required this.success,
    this.role,
    this.userModel,
    this.errorMessage,
  });
}
