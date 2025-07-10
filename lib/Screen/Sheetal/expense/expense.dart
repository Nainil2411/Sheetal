import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  String? id;
  String title;
  double amount;
  String paymentMode;
  String? expenseDate;
  Timestamp? createdAt;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.paymentMode,
    this.expenseDate,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'paymentMode': paymentMode,
      'expenseDate': expenseDate,
      'createdAt': createdAt,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map, String documentId) {
    return Expense(
      id: documentId,
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentMode: map['paymentMode'] ?? 'Cash',
      expenseDate: map['expenseDate'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? map['createdAt']
          : Timestamp.fromDate(DateTime.now()),
    );
  }
}