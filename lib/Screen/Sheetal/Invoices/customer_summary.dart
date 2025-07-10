class CustomerSummary {
  final String customerName;
  final double totalAmount;
  final int invoiceCount;
  final String month;
  final int year;

  CustomerSummary({
    required this.customerName,
    required this.totalAmount,
    required this.invoiceCount,
    required this.month,
    required this.year,
  });

  String get id => '${customerName}_${month}_$year';
}