
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sheetal/Screen/Sheetal/collection/collection.dart';
import 'package:sheetal/Screen/Sheetal/Invoices/invoice.dart';
import 'package:sheetal/Screen/Sheetal/expense/expense.dart';
import 'package:sheetal/common/export_progress_dialog.dart';
import 'package:intl/intl.dart';

class ExportUtility {
  static Future<void> exportToExcel<T>({
    required BuildContext context,
    required List<T> data,
    required ExportConfig<T> config,
    String? dateRangeText,
  }) async {
    print('Export started with ${data.length} items');

    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show progress dialog
    final ValueNotifier<int> progressNotifier = ValueNotifier<int>(0);
    final int totalSteps = 3 + data.length; // headers, rows loop, save
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return ExportProgressDialog(
          totalItems: totalSteps,
          currentProgressNotifier: progressNotifier,
          onCancel: () {
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );

    try {
      // Request permissions
      bool hasPermission = await _requestPermissions();
      if (!hasPermission) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission required to export file'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('Permissions granted, creating Excel file...');

      // Step 1: Create Excel file
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];
      progressNotifier.value = 1;

      // Step 2: Add title
      var titleCell = sheetObject.cell(CellIndex.indexByString("A1"));
      titleCell.value = TextCellValue(config.title);
      titleCell.cellStyle = CellStyle(bold: true, fontSize: 16);

      int currentRow = 2;
      progressNotifier.value = 2;

      // Step 3: Add date range if provided
      if (dateRangeText != null && dateRangeText.isNotEmpty) {
        var dateCell = sheetObject.cell(CellIndex.indexByString("A$currentRow"));
        dateCell.value = TextCellValue('Date Range: $dateRangeText');
        dateCell.cellStyle = CellStyle(bold: true);
        currentRow++;
      }

      // Step 4: Add export date
      var exportDateCell = sheetObject.cell(CellIndex.indexByString("A$currentRow"));
      exportDateCell.value = TextCellValue('Exported on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
      currentRow += 2; // Skip a row

      // Step 5: Add headers
      List<String> headers = config.headers;
      for (int i = 0; i < headers.length; i++) {
        var headerCell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow - 1));
        headerCell.value = TextCellValue(headers[i]);
        headerCell.cellStyle = CellStyle(bold: true, backgroundColorHex: ExcelColor.grey);
      }
      progressNotifier.value = 3;

      // Step 6: Add data rows
      int serialNumber = 1;
      for (final item in data) {
        final rowData = config.getRowData(item);
        for (int i = 0; i < rowData.length; i++) {
          var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow));
          if (i == 0) {
            // First column is serial number
            cell.value = IntCellValue(serialNumber);
          } else {
            final cellValue = rowData[i];
            if (cellValue is num) {
              cell.value = DoubleCellValue(cellValue.toDouble());
            } else {
              cell.value = TextCellValue(cellValue.toString());
            }
          }
        }
        currentRow++;
        serialNumber++;
        progressNotifier.value = (3 + serialNumber - 1).clamp(0, totalSteps);
      }

      // Step 7: Add total row if applicable
      if (config.showTotal) {
        currentRow++; // Skip a row

        var totalLabelCell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
        totalLabelCell.value = TextCellValue('TOTAL');
        totalLabelCell.cellStyle = CellStyle(bold: true);

        final totalAmount = config.calculateTotal(data);
        var totalAmountCell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: config.amountColumnIndex, rowIndex: currentRow));
        totalAmountCell.value = DoubleCellValue(totalAmount);
        totalAmountCell.cellStyle = CellStyle(bold: true);
      }

      print('Excel file created, saving...');

      // Step 8: Get directory and save file
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        directory ??= await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = '${config.fileName}_$timestamp.xlsx';
      final filePath = '${directory.path}/$fileName';

      print('Saving file to: $filePath');

      final file = File(filePath);
      List<int>? fileBytes = excel.encode();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        print('File saved successfully');
      } else {
        throw Exception('Failed to encode Excel file');
      }

      // finalize progress
      progressNotifier.value = totalSteps;

      // Close progress dialog
      Navigator.of(context).pop();

      // Show success dialog
      _showExportSuccessDialog(context, filePath, fileName);

    } catch (e) {
      print('Export error: $e');

      // Close progress dialog if open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // For Android 11+ (API 30+)
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      // Try to request manage external storage permission
      var status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        return true;
      }

      // Fallback to regular storage permissions
      status = await Permission.storage.request();
      return status.isGranted;
    }
    return true; // iOS doesn't need these permissions
  }

  static void _showExportSuccessDialog(
      BuildContext context,
      String filePath,
      String fileName,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Export Successful'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('File exported successfully as:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  fileName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Location: ${filePath}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await Share.shareXFiles(
                    [XFile(filePath)],
                    text: 'Exported $fileName',
                  );
                } catch (e) {
                  print('Share error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Share failed: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.share),
              label: const Text('Share'),
            ),
          ],
        );
      },
    );
  }
}

// Export configuration classes remain the same
abstract class ExportConfig<T> {
  String get title;
  String get fileName;
  List<String> get headers;
  bool get showTotal;
  int get amountColumnIndex;

  List<dynamic> getRowData(T item);
  double calculateTotal(List<T> items);
}

class ExportConfigs {
  static final collectionConfig = CollectionExportConfig();
  static final invoiceConfig = InvoiceExportConfig();
  static final expenseConfig = ExpenseExportConfig();
}

class CollectionExportConfig extends ExportConfig<Collection> {
  @override
  String get title => 'Collections Report';

  @override
  String get fileName => 'collections_export';

  @override
  List<String> get headers => [
    'Sr. No.',
    'Customer Name',
    'Amount (₹)',
    'Date',
    'Payment Mode',
  ];

  @override
  bool get showTotal => true;

  @override
  int get amountColumnIndex => 2;

  @override
  List<dynamic> getRowData(Collection collection) {
    return [
      '', // Sr. No. will be filled automatically
      collection.customerName,
      collection.amount,
      collection.date,
      collection.paymentMode,
    ];
  }

  @override
  double calculateTotal(List<Collection> items) {
    return items.fold(0.0, (sum, collection) => sum + collection.amount);
  }
}

class InvoiceExportConfig extends ExportConfig<Invoice> {
  @override
  String get title => 'Invoices Report';

  @override
  String get fileName => 'invoices_export';

  @override
  List<String> get headers => [
    'Sr. No.',
    'Customer Name',
    'Amount (₹)',
    'Date',
    'Category',
  ];

  @override
  bool get showTotal => true;

  @override
  int get amountColumnIndex => 2;

  @override
  List<dynamic> getRowData(Invoice invoice) {
    return [
      '', // Sr. No. will be filled automatically
      invoice.customerName,
      invoice.amount,
      invoice.date,
      invoice.categoryName,
    ];
  }

  @override
  double calculateTotal(List<Invoice> items) {
    return items.fold(0.0, (sum, invoice) => sum + invoice.amount);
  }
}

class ExpenseExportConfig extends ExportConfig<Expense> {
  @override
  String get title => 'Expenses Report';

  @override
  String get fileName => 'expenses_export';

  @override
  List<String> get headers => [
        'Sr. No.',
        'Title',
        'Amount (₹)',
        'Date',
        'Payment Mode',
      ];

  @override
  bool get showTotal => true;

  @override
  int get amountColumnIndex => 2;

  @override
  List<dynamic> getRowData(Expense expense) {
    return [
      '',
      expense.title,
      expense.amount,
      expense.expenseDate ?? '',
      expense.paymentMode,
    ];
  }

  @override
  double calculateTotal(List<Expense> items) {
    return items.fold(0.0, (sum, e) => sum + e.amount);
  }
}