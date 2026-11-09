/// Bus Expense Record for real Kerala private bus operations.
/// Replaces arbitrary fixed percentage formulas with actual recorded operating expenses.
class BusExpenseRecord {
  final String id;
  final String busRegNumber;
  final String ownerId;
  final String category; // 'Diesel / Fuel', 'Crew Batta / Wages', 'Vehicle Maintenance', 'Permit, Tax & Toll'
  final double amount;
  final DateTime date;
  final String note;

  const BusExpenseRecord({
    required this.id,
    required this.busRegNumber,
    required this.ownerId,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'busRegNumber': busRegNumber,
        'ownerId': ownerId,
        'category': category,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory BusExpenseRecord.fromJson(Map<String, dynamic> json) => BusExpenseRecord(
        id: json['id'] as String? ?? 'EXP-${DateTime.now().millisecondsSinceEpoch}',
        busRegNumber: json['busRegNumber'] as String? ?? '',
        ownerId: json['ownerId'] as String? ?? '',
        category: json['category'] as String? ?? 'Diesel / Fuel',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        note: json['note'] as String? ?? '',
      );
}
