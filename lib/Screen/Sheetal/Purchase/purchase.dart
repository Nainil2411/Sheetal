class Purchase {
  String? id;
  String date;
  String categoryId;
  String categoryName;
  double amount;
  DateTime? createdAt;

  Purchase({
    this.id,
    required this.date,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    this.createdAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'amount': amount,
      'createdAt': createdAt ?? DateTime.now(),
    };
  }

  // Create from Firestore document
  factory Purchase.fromMap(Map<String, dynamic> map, String documentId) {
    return Purchase(
      id: documentId,
      date: map['date'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      createdAt: map['createdAt']?.toDate(),
    );
  }
}