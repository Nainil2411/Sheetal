import 'package:cloud_firestore/cloud_firestore.dart';

class Discount {
  String? id;
  String month; // e.g., 'September 2025'
  double amount;
  String? notes;
  Timestamp? createdAt;

  Discount({
    this.id,
    required this.month,
    required this.amount,
    this.notes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'amount': amount,
      'notes': notes,
      'createdAt': createdAt ?? Timestamp.fromDate(DateTime.now()),
    };
  }

  factory Discount.fromMap(Map<String, dynamic> map, String documentId) {
    return Discount(
      id: documentId,
      month: map['month'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      notes: map['notes'],
      createdAt: map['createdAt'] is Timestamp
          ? map['createdAt']
          : Timestamp.fromDate(DateTime.now()),
    );
  }
}


