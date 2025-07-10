class Category {
  String? id;
  String name;
  double percentage;

  Category({
    this.id,
    required this.name,
    required this.percentage,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'percentage': percentage,
    };
  }

  // Create from Firestore document
  factory Category.fromMap(Map<String, dynamic> map, String documentId) {
    return Category(
      id: documentId,
      name: map['name'] ?? '',
      percentage: (map['percentage'] ?? 0.0).toDouble(),
    );
  }
}
