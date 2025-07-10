import 'package:cloud_firestore/cloud_firestore.dart';

class Bank {
  String? id;
  String? selectedDate;
  double invoiceTotal;
  double cash;
  double online;
  double cheque;
  double others;
  double total;
  Timestamp? createdAt;

  Bank({
    this.id,
    this.selectedDate,
    required this.invoiceTotal,
    required this.cash,
    required this.online,
    required this.cheque,
    required this.others,
    required this.total,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'selectedDate': selectedDate,
      'invoiceTotal': invoiceTotal,
      'cash': cash,
      'online': online,
      'cheque': cheque,
      'others': others,
      'total': total,
      'createdAt': createdAt ?? Timestamp.now(),
    };
  }

  factory Bank.fromMap(Map<String, dynamic> map, String documentId) {
    return Bank(
      id: documentId,
      selectedDate: map['selectedDate'],
      invoiceTotal: (map['invoiceTotal'] ?? 0.0).toDouble(),
      cash: (map['cash'] ?? 0.0).toDouble(),
      online: (map['online'] ?? 0.0).toDouble(),
      cheque: (map['cheque'] ?? 0.0).toDouble(),
      others: (map['others'] ?? 0.0).toDouble(),
      total: (map['total'] ?? 0.0).toDouble(),
      createdAt: map['createdAt'] is Timestamp
          ? map['createdAt']
          : Timestamp.fromDate(DateTime.now()),
    );
  }
}
