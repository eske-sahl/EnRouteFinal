/// Model representing a lost and found report for passenger belongings on private buses.
class LostItemReport {
  final String id;
  final String busRegNumber;
  final String busName;
  final String itemCategory; // 'Bag / Backpack', 'Smartphone / Electronics', 'Wallet / Cash', 'Documents / ID', 'Umbrella', 'Clothing / Other'
  final String description;
  final String reporterName;
  final String reporterPhone;
  final DateTime dateReported;
  final String status; // 'SEARCHING', 'FOUND_IN_BUS', 'RETURNED_TO_OWNER'
  final String resolutionNotes;

  const LostItemReport({
    required this.id,
    required this.busRegNumber,
    required this.busName,
    required this.itemCategory,
    required this.description,
    required this.reporterName,
    required this.reporterPhone,
    required this.dateReported,
    this.status = 'SEARCHING',
    this.resolutionNotes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'busRegNumber': busRegNumber,
        'busName': busName,
        'itemCategory': itemCategory,
        'description': description,
        'reporterName': reporterName,
        'reporterPhone': reporterPhone,
        'dateReported': dateReported.toIso8601String(),
        'status': status,
        'resolutionNotes': resolutionNotes,
      };

  factory LostItemReport.fromJson(Map<String, dynamic> json) => LostItemReport(
        id: json['id'] as String? ?? 'LOST-${DateTime.now().millisecondsSinceEpoch}',
        busRegNumber: json['busRegNumber'] as String? ?? '',
        busName: json['busName'] as String? ?? '',
        itemCategory: json['itemCategory'] as String? ?? 'Bag / Backpack',
        description: json['description'] as String? ?? '',
        reporterName: json['reporterName'] as String? ?? '',
        reporterPhone: json['reporterPhone'] as String? ?? '',
        dateReported: DateTime.tryParse(json['dateReported'] as String? ?? '') ?? DateTime.now(),
        status: json['status'] as String? ?? 'SEARCHING',
        resolutionNotes: json['resolutionNotes'] as String? ?? '',
      );

  LostItemReport copyWith({
    String? status,
    String? resolutionNotes,
  }) {
    return LostItemReport(
      id: id,
      busRegNumber: busRegNumber,
      busName: busName,
      itemCategory: itemCategory,
      description: description,
      reporterName: reporterName,
      reporterPhone: reporterPhone,
      dateReported: dateReported,
      status: status ?? this.status,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
    );
  }
}
