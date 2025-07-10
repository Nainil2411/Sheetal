import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Invoice {
  String? id;
  String customerName;
  String categoryId;
  String categoryName;
  double amount;
  String date;
  Timestamp createdAt;

  Invoice({
    this.id,
    required this.customerName,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'amount': amount,
      'createdAt': createdAt,
      'date': date,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, String documentId) {
    Timestamp created = map['createdAt'] is Timestamp
        ? map['createdAt']
        : Timestamp.fromDate(DateTime.now());

    String formattedDate;
    if (map['date'] is Timestamp) {
      formattedDate =
          DateFormat('dd/MM/yyyy').format((map['date'] as Timestamp).toDate());
    } else if (map['date'] is String) {
      DateTime? parsed = DateTime.tryParse(map['date']);
      formattedDate = parsed != null
          ? DateFormat('dd/MM/yyyy').format(parsed)
          : map['date'];
    } else {
      formattedDate =
          DateFormat('dd/MM/yyyy').format(DateTime.now());
    }

    return Invoice(
      id: documentId,
      customerName: map['customerName'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: formattedDate,
      createdAt: created,
    );
  }
}
