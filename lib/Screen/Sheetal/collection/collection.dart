import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Collection {
  String? id;
  String customerName;
  double amount;
  String paymentMode;
  String date;
  String? chequeDate; // Optional field
  final Timestamp? createdAt;

  Collection({
    this.id,
    required this.customerName,
    required this.amount,
    required this.paymentMode,
    required this.date,
    this.chequeDate,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final formattedDate = createdAt != null
        ? DateFormat('dd/MM/yyyy').format(createdAt!.toDate())
        : date;

    return {
      'customerName': customerName,
      'amount': amount,
      'paymentMode': paymentMode,
      'date': formattedDate,
      'chequeDate': chequeDate,
      'createdAt': createdAt,
    };
  }

  factory Collection.fromMap(Map<String, dynamic> map, String documentId) {
    Timestamp? created = _parseTimestamp(map['createdAt']);
    String formattedDate;
    if (map['date'] is Timestamp) {
      formattedDate =
          DateFormat('dd/MM/yyyy').format((map['date'] as Timestamp).toDate());
    } else if (map['date'] is String) {
      DateTime? parsed = DateTime.tryParse(map['date']);
      formattedDate = parsed != null
          ? DateFormat('dd/MM/yyyy').format(parsed)
          : map['date'];
    } else if (created != null) {
      formattedDate = DateFormat('dd/MM/yyyy').format(created.toDate());
    } else {
      formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    }

    return Collection(
      id: documentId,
      customerName: map['customerName'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentMode: map['paymentMode'] ?? '',
      date: formattedDate,
      chequeDate: map['chequeDate'],
      createdAt: created,
    );
  }

  static Timestamp? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value;
    if (value is int) return Timestamp.fromMillisecondsSinceEpoch(value);
    return null;
  }

  // Helper method to check if cheque is pending
  bool get isPendingCheque {
    if (paymentMode.toLowerCase() != 'cheque') return false;

    // If no cheque date set, it's pending
    if (chequeDate == null || chequeDate!.isEmpty) return true;

    // If cheque date is in future, it's pending
    try {
      final chequeDateParsed = DateFormat('dd/MM/yyyy').parse(chequeDate!);
      return chequeDateParsed.isAfter(DateTime.now());
    } catch (e) {
      return true;
    }
  }
}