import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheetal/utils/utility.dart';

import '../Screen/Sheetal/Invoices/invoice.dart';
import '../Screen/Sheetal/collection/collection.dart';
import '../Screen/Sheetal/customer/customer_module.dart';
import '../Screen/Sheetal/expense/expense.dart';
import '../common/import_progress_dialog.dart';
import '../utils/firebase_service.dart';
import '../Screen/Sheetal/discount/discount.dart';
import '../Screen/Sheetal/Purchase/purchase.dart';

class ImportConfig<T> {
  final String entityName;
  final int requiredColumns;
  final Future<Map<String, String>?> Function(List<String> values) parseRow;
  final Future<bool> Function(Map<String, String> data) processData;
  final Future<List<T>> Function()? getExistingData;
  final bool Function(T existing, Map<String, String> newData)? isDuplicate;

  ImportConfig({
    required this.entityName,
    required this.requiredColumns,
    required this.parseRow,
    required this.processData,
    this.getExistingData,
    this.isDuplicate,
  });
}

class ImportResult {
  final int addedCount;
  final int skippedCount;
  final int duplicateCount;
  final List<String> errors;

  ImportResult({
    required this.addedCount,
    required this.skippedCount,
    required this.duplicateCount,
    required this.errors,
  });

  bool get hasSuccess => addedCount > 0;
  bool get hasErrors => errors.isNotEmpty;
  bool get hasSkipped => skippedCount > 0 || duplicateCount > 0;
}

class ImportUtility {
  static Future<void> importFromFile<T>({
    required BuildContext context,
    required ImportConfig<T> config,
    required VoidCallback onComplete,
  }) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      List<Map<String, String>> parsedData = [];

      try {
        final file = File(filePath);
        final content = await file.readAsString();
        final lines = const LineSplitter().convert(content);

        // Parse file content
        for (var line in lines.skip(1)) {
          final values = line.split(RegExp(r'[,\t;]'));
          if (values.length >= config.requiredColumns) {
            final parsedRow = await config.parseRow(values);
            if (parsedRow != null) {
              parsedData.add(parsedRow);
            }
          }
        }

        if (parsedData.isNotEmpty) {
          final importResult = await _processImport<T>(
            context: context,
            config: config,
            parsedData: parsedData,
          );

          await _showImportResults(context, config.entityName, importResult);
          onComplete();
        } else {
          await Utility.showErrorDialog(
            context: context,
            message: "No valid data found in file.",
          );
        }
      } catch (e) {
        await Utility.showErrorDialog(
          context: context,
          message: "Error importing file: $e",
        );
      }
    }
  }

  static Future<ImportResult> _processImport<T>({
    required BuildContext context,
    required ImportConfig<T> config,
    required List<Map<String, String>> parsedData,
  }) async {
    final ValueNotifier<int> progressNotifier = ValueNotifier<int>(0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return ImportProgressDialog(
          totalItems: parsedData.length,
          currentProgressNotifier: progressNotifier,
          onCancel: () {
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );

    int addedCount = 0;
    int skippedCount = 0;
    int duplicateCount = 0;
    List<String> errors = [];

    // Get existing data for duplicate checking if needed
    List<T>? existingData;
    if (config.getExistingData != null) {
      try {
        existingData = await config.getExistingData!();
      } catch (e) {
        errors.add("Error loading existing data: $e");
      }
    }

    // Process each item
    for (int i = 0; i < parsedData.length; i++) {
      final data = parsedData[i];

      try {
        // Check for duplicates if applicable
        bool isDuplicate = false;
        if (existingData != null && config.isDuplicate != null) {
          isDuplicate = existingData.any((existing) => config.isDuplicate!(existing, data));
        }

        if (isDuplicate) {
          duplicateCount++;
        } else {
          // Process the data
          final success = await config.processData(data);
          if (success) {
            addedCount++;
          } else {
            skippedCount++;
          }
        }
      } catch (e) {
        errors.add("Error processing ${data.values.first}: ${e.toString()}");
        skippedCount++;
      }

      progressNotifier.value = i + 1;
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Close progress dialog
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    return ImportResult(
      addedCount: addedCount,
      skippedCount: skippedCount,
      duplicateCount: duplicateCount,
      errors: errors,
    );
  }

  static Future<void> _showImportResults(
      BuildContext context,
      String entityName,
      ImportResult result,
      ) async {
    List<String> messageParts = [];

    if (result.addedCount > 0) {
      messageParts.add("Added ${result.addedCount} $entityName");
    }
    if (result.duplicateCount > 0) {
      messageParts.add("skipped ${result.duplicateCount} duplicates");
    }
    if (result.skippedCount > 0) {
      messageParts.add("skipped ${result.skippedCount} items");
    }

    if (result.hasSuccess) {
      await Utility.showSuccessDialog(
        context: context,
        message: messageParts.isEmpty ? "No $entityName processed" : messageParts.join(", "),
      );
    } else if (result.hasSkipped && !result.hasErrors) {
      await Utility.showErrorDialog(
        context: context,
        message: messageParts.join(", "),
        title: 'Import Results',
      );
    }

    // Show errors if any
    if (result.hasErrors) {
      String errorMessage = result.errors.length > 5
          ? "${result.errors.length} errors occurred during import"
          : result.errors.join("\n\n");

      await Utility.showErrorDialog(
        context: context,
        message: errorMessage,
        title: 'Import Errors',
      );
    }
  }
}

class ImportConfigs {
  static ImportConfig<Invoice> get invoiceConfig {
    final firebaseService = FirebaseService();

    return ImportConfig<Invoice>(
      entityName: "invoices",
      requiredColumns: 4,
      parseRow: (values) async {
        return {
          'customerName': values[0].trim(),
          'categoryName': values[1].trim(),
          'amount': values[2].trim(),
          'date': values[3].trim(),
        };
      },
      processData: (data) async {
        try {
          final amountStr = data['amount']!;
          final amount = amountStr.isEmpty ? 0.0 : double.tryParse(amountStr) ?? 0.0;

          DateTime parsedDate;
          try {
            parsedDate = DateFormat('MMM dd yyyy').parseStrict(data['date']!);
          } catch (_) {
            try {
              parsedDate = DateFormat('yyyy-MM-dd').parseStrict(data['date']!);
            } catch (_) {
              try {
                parsedDate = DateFormat('dd/MM/yyyy').parseStrict(data['date']!);
              } catch (_) {
                parsedDate = DateTime.now();
              }
            }
          }

          final outputDateFormat = DateFormat('dd/MM/yyyy');
          final formattedDate = outputDateFormat.format(parsedDate);

          // Look up category ID by category name
          String? categoryId;
          if (data['categoryName']!.isNotEmpty) {
            categoryId = await _getCategoryIdByName(data['categoryName']!);
          }

          // Create the invoice data
          Map<String, dynamic> invoiceData = {
            'customerName': data['customerName'],
            'categoryName': data['categoryName'],
            'amount': amount,
            'date': formattedDate,
            'createdAt': Timestamp.fromDate(parsedDate),
          };

          // Add categoryId if found
          if (categoryId != null) {
            invoiceData['categoryId'] = categoryId;
          }

          await firebaseService.invoiceCollection?.add(invoiceData);

          return true;
        } catch (e) {
          return false;
        }
      },
      // Add duplicate checking for invoices
      getExistingData: () async {
        try {
          final snapshot = await firebaseService.invoiceCollection!.get();
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Invoice(
              id: doc.id,
              customerName: data['customerName'] ?? '',
              categoryName: data['categoryName'] ?? '',
              amount: (data['amount'] ?? 0.0).toDouble(),
              date: data['date'] ?? '',
              createdAt: data['createdAt'] ?? Timestamp.now(),
              categoryId: data['categoryId'],
            );
          }).toList();
        } catch (e) {
          return <Invoice>[];
        }
      },
      // Define what makes an invoice a duplicate
      // You can customize this logic based on your requirements
      isDuplicate: (existing, newData) {
        // Consider duplicates based on customer name, amount, and date
        final newAmount = double.tryParse(newData['amount']!) ?? 0.0;
        final formattedNewDate = _formatDateForComparison(newData['date']!);

        return existing.customerName.toLowerCase() == newData['customerName']!.toLowerCase() &&
            existing.amount == newAmount &&
            existing.date == formattedNewDate;
      },
    );
  }

  // Helper method to format date for comparison
  static String _formatDateForComparison(String dateStr) {
    try {
      DateTime parsedDate;
      try {
        parsedDate = DateFormat('MMM dd yyyy').parseStrict(dateStr);
      } catch (_) {
        try {
          parsedDate = DateFormat('yyyy-MM-dd').parseStrict(dateStr);
        } catch (_) {
          try {
            parsedDate = DateFormat('dd/MM/yyyy').parseStrict(dateStr);
          } catch (_) {
            return dateStr; // Return original if can't parse
          }
        }
      }
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return dateStr;
    }
  }

  // Helper method to get category ID by name
  static Future<String?> _getCategoryIdByName(String categoryName) async {
    try {
      final firebaseService = FirebaseService();

      // Query categories collection by name
      final querySnapshot = await firebaseService.categoryCollection
          ?.where('name', isEqualTo: categoryName)
          .limit(1)
          .get();

      if (querySnapshot != null && querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }

      // If category doesn't exist, optionally create it
      // Uncomment the following lines if you want to auto-create categories
      /*
      final docRef = await firebaseService.categoryCollection?.add({
        'name': categoryName,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
      return docRef?.id;
      */

      return null;
    } catch (e) {
      print('Error getting category ID: $e');
      return null;
    }
  }

  static ImportConfig<Collection> get collectionConfig {
    final firebaseService = FirebaseService();

    return ImportConfig<Collection>(
      entityName: "collections",
      requiredColumns: 4,
      parseRow: (values) async {
        return {
          'customerName': values[0].trim(),
          'amount': values[1].trim(),
          'paymentMode': values[2].trim(),
          'date': values[3].trim(),
        };
      },
      processData: (data) async {
        try {
          final amountStr = data['amount']!;
          final amount = amountStr.isEmpty ? 0.0 : double.tryParse(amountStr) ?? 0.0;

          DateTime parsedDate;
          try {
            parsedDate = DateFormat('MMM dd yyyy').parseStrict(data['date']!);
          } catch (_) {
            try {
              parsedDate = DateFormat('yyyy-MM-dd').parseStrict(data['date']!);
            } catch (_) {
              try {
                parsedDate = DateFormat('dd/MM/yyyy').parseStrict(data['date']!);
              } catch (_) {
                parsedDate = DateTime.now();
              }
            }
          }

          final dateFormat = DateFormat('dd/MM/yyyy');
          final formattedDate = dateFormat.format(parsedDate);

          await firebaseService.collectionCollection?.add({
            'customerName': data['customerName'],
            'amount': amount,
            'paymentMode': data['paymentMode'],
            'date': formattedDate,
            'createdAt': Timestamp.fromDate(parsedDate),
          });

          return true;
        } catch (e) {
          return false;
        }
      },
      // Add duplicate checking for collections
      getExistingData: () async {
        try {
          final snapshot = await firebaseService.collectionCollection!.get();
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Collection(
              id: doc.id,
              customerName: data['customerName'] ?? '',
              amount: (data['amount'] ?? 0.0).toDouble(),
              paymentMode: data['paymentMode'] ?? '',
              date: data['date'] ?? '',
              createdAt: data['createdAt'] ?? Timestamp.now(),
            );
          }).toList();
        } catch (e) {
          return <Collection>[];
        }
      },
      // Define what makes a collection a duplicate
      isDuplicate: (existing, newData) {
        // Consider duplicates based on customer name, amount, and date
        return existing.customerName == newData['customerName'] &&
            existing.amount.toString() == newData['amount'] &&
            existing.date == _formatDateForComparison(newData['date']!);
      },
    );
  }

  static ImportConfig<Customer> get customerConfig {
    final firebaseService = FirebaseService();

    return ImportConfig<Customer>(
      entityName: "customers",
      requiredColumns: 2,
      parseRow: (values) async {
        final name = values[0].trim();
        final phone = values[1].trim();
        if (name.isNotEmpty && phone.isNotEmpty) {
          return {'name': name, 'phone': phone};
        }
        return null;
      },
      processData: (data) async {
        try {
          await firebaseService.customerCollection?.add({
            'name': data['name'],
            'phone': data['phone'],
            'createdAt': Timestamp.fromDate(DateTime.now()),
          });
          return true;
        } catch (e) {
          return false;
        }
      },
      getExistingData: () async {
        try {
          final snapshot = await firebaseService.customerCollection!.get();
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Customer(
              id: doc.id,
              name: data['name'] ?? '',
              phone: data['phone'] ?? '',
              createdAt: data['createdAt'] ?? Timestamp.now(),
            );
          }).toList();
        } catch (e) {
          return <Customer>[];
        }
      },
      isDuplicate: (existing, newData) {
        // Both name and phone must match to be considered duplicate
        return existing.phone == newData['phone'] &&
            existing.name.toLowerCase() == newData['name']!.toLowerCase();
      },
    );
  }

  static ImportConfig<Expense> get expenseConfig {
    final firebaseService = FirebaseService();

    return ImportConfig<Expense>(
      entityName: "expenses",
      requiredColumns: 4,
      // Expected columns: Title, Amount, Payment Mode, Date
      parseRow: (values) async {
        return {
          'title': values[0].trim(),
          'amount': values[1].trim(),
          'paymentMode': values[2].trim(),
          'date': values[3].trim(),
        };
      },
      processData: (data) async {
        try {
          final amountStr = data['amount'] ?? '0';
          final amount = amountStr.isEmpty ? 0.0 : double.tryParse(amountStr) ?? 0.0;

          DateTime parsedDate;
          try {
            parsedDate = DateFormat('MMM dd yyyy').parseStrict(data['date']!);
          } catch (_) {
            try {
              parsedDate = DateFormat('yyyy-MM-dd').parseStrict(data['date']!);
            } catch (_) {
              try {
                parsedDate = DateFormat('dd/MM/yyyy').parseStrict(data['date']!);
              } catch (_) {
                parsedDate = DateTime.now();
              }
            }
          }

          final outputDateFormat = DateFormat('dd/MM/yyyy');
          final formattedDate = outputDateFormat.format(parsedDate);

          await firebaseService.expenseCollection?.add({
            'title': data['title'],
            'amount': amount,
            'paymentMode': data['paymentMode'],
            'expenseDate': formattedDate,
            'createdAt': Timestamp.fromDate(parsedDate),
          });

          return true;
        } catch (e) {
          return false;
        }
      },
      getExistingData: () async {
        try {
          final snapshot = await firebaseService.expenseCollection!.get();
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Expense(
              id: doc.id,
              title: data['title'] ?? '',
              amount: (data['amount'] ?? 0.0).toDouble(),
              paymentMode: data['paymentMode'] ?? 'Cash',
              expenseDate: data['expenseDate'] ?? '',
              createdAt: data['createdAt'] ?? Timestamp.now(),
            );
          }).toList();
        } catch (e) {
          return <Expense>[];
        }
      },
      isDuplicate: (existing, newData) {
        final newAmount = double.tryParse(newData['amount'] ?? '0') ?? 0.0;
        final formattedNewDate = _formatDateForComparison(newData['date'] ?? '');
        return existing.title.toLowerCase() == (newData['title'] ?? '').toLowerCase() &&
            existing.amount == newAmount &&
            (existing.expenseDate ?? '') == formattedNewDate;
      },
    );
  }

  static ImportConfig<Discount> get discountConfig {
    final firebaseService = FirebaseService();
    return ImportConfig<Discount>(
      entityName: "discounts",
      requiredColumns: 3,
      parseRow: (values) async {
        return {
          'month': values[0].trim(),
          'amount': values[1].trim(),
          'notes': values.length > 2 ? values[2].trim() : '',
        };
      },
      processData: (data) async {
        try {
          final amountStr = data['amount'] ?? '0';
          final amount = amountStr.isEmpty ? 0.0 : double.tryParse(amountStr) ?? 0.0;
          await firebaseService.addDiscount(
            Discount(
              month: data['month'] ?? '',
              amount: amount,
              notes: (data['notes'] ?? '').isEmpty ? null : data['notes'],
            ),
          );
          return true;
        } catch (e) {
          return false;
        }
      },
      getExistingData: () async {
        try {
          final snapshot = await firebaseService.discountCollection!.get();
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Discount.fromMap(data, doc.id);
          }).toList();
        } catch (e) {
          return <Discount>[];
        }
      },
      isDuplicate: (existing, newData) {
        final newAmount = double.tryParse(newData['amount'] ?? '0') ?? 0.0;
        return existing.month.toLowerCase() == (newData['month'] ?? '').toLowerCase() &&
            existing.amount == newAmount;
      },
    );
  }

  static ImportConfig<Discount> get schemeConfig {
    final firebaseService = FirebaseService();
    return ImportConfig<Discount>(
      entityName: "schemes",
      requiredColumns: 3,
      parseRow: (values) async {
        return {
          'month': values[0].trim(),
          'amount': values[1].trim(),
          'notes': values.length > 2 ? values[2].trim() : '',
        };
      },
      processData: (data) async {
        try {
          final amountStr = data['amount'] ?? '0';
          final amount = amountStr.isEmpty ? 0.0 : double.tryParse(amountStr) ?? 0.0;
          await firebaseService.addScheme(
            Discount(
              month: data['month'] ?? '',
              amount: amount,
              notes: (data['notes'] ?? '').isEmpty ? null : data['notes'],
            ),
          );
          return true;
        } catch (e) {
          return false;
        }
      },
      getExistingData: () async {
        try {
          final snapshot = await firebaseService.schemeCollection!.get();
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Discount.fromMap(data, doc.id);
          }).toList();
        } catch (e) {
          return <Discount>[];
        }
      },
      isDuplicate: (existing, newData) {
        final newAmount = double.tryParse(newData['amount'] ?? '0') ?? 0.0;
        return existing.month.toLowerCase() == (newData['month'] ?? '').toLowerCase() &&
            existing.amount == newAmount;
      },
    );
  }

  static ImportConfig<Discount> get creditConfig {
    final firebaseService = FirebaseService();
    return ImportConfig<Discount>(
      entityName: "credits",
      requiredColumns: 3,
      parseRow: (values) async {
        return {
          'month': values[0].trim(),
          'amount': values[1].trim(),
          'notes': values.length > 2 ? values[2].trim() : '',
        };
      },
      processData: (data) async {
        try {
          final amountStr = data['amount'] ?? '0';
          final amount = amountStr.isEmpty ? 0.0 : double.tryParse(amountStr) ?? 0.0;
          await firebaseService.addCredit(
            Discount(
              month: data['month'] ?? '',
              amount: amount,
              notes: (data['notes'] ?? '').isEmpty ? null : data['notes'],
            ),
          );
          return true;
        } catch (e) {
          return false;
        }
      },
      getExistingData: () async {
        try {
          final snapshot = await firebaseService.creditCollection!.get();
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Discount.fromMap(data, doc.id);
          }).toList();
        } catch (e) {
          return <Discount>[];
        }
      },
      isDuplicate: (existing, newData) {
        final newAmount = double.tryParse(newData['amount'] ?? '0') ?? 0.0;
        return existing.month.toLowerCase() == (newData['month'] ?? '').toLowerCase() &&
            existing.amount == newAmount;
      },
    );
  }

  static ImportConfig<Purchase> get purchaseConfig {
    final firebaseService = FirebaseService();
    return ImportConfig<Purchase>(
      entityName: "purchases",
      requiredColumns: 4,
      // Expected columns: Date, Category, Amount, GRA Number
      parseRow: (values) async {
        return {
          'date': values[0].trim(),
          'categoryName': values[1].trim(),
          'amount': values[2].trim(),
          'graNumber': values.length > 3 ? values[3].trim() : '',
        };
      },
      processData: (data) async {
        try {
          final amountStr = data['amount'] ?? '0';
          final amount = amountStr.isEmpty ? 0.0 : double.tryParse(amountStr) ?? 0.0;

          // Normalize date to dd/MM/yyyy
          DateTime parsedDate;
          try {
            parsedDate = DateFormat('MMM dd yyyy').parseStrict(data['date']!);
          } catch (_) {
            try {
              parsedDate = DateFormat('yyyy-MM-dd').parseStrict(data['date']!);
            } catch (_) {
              try {
                parsedDate = DateFormat('dd/MM/yyyy').parseStrict(data['date']!);
              } catch (_) {
                parsedDate = DateTime.now();
              }
            }
          }
          final formattedDate = DateFormat('dd/MM/yyyy').format(parsedDate);

          // Look up category ID by name
          String? categoryId;
          if ((data['categoryName'] ?? '').isNotEmpty) {
            categoryId = await _getCategoryIdByName(data['categoryName']!);
          }

          final purchaseMap = {
            'date': formattedDate,
            'categoryId': categoryId ?? '',
            'categoryName': data['categoryName'] ?? '',
            'amount': amount,
            'graNumber': (data['graNumber'] ?? '').isEmpty ? null : data['graNumber'],
            'createdAt': Timestamp.fromDate(parsedDate),
          };

          await firebaseService.purchaseCollection?.add(purchaseMap);
          return true;
        } catch (e) {
          return false;
        }
      },
      getExistingData: () async {
        try {
          final snapshot = await firebaseService.purchaseCollection!.get();
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Purchase.fromMap(data, doc.id);
          }).toList();
        } catch (e) {
          return <Purchase>[];
        }
      },
      isDuplicate: (existing, newData) {
        final newAmount = double.tryParse(newData['amount'] ?? '0') ?? 0.0;
        final normalizedDate = _formatDateForComparison(newData['date'] ?? '');
        final newCategory = (newData['categoryName'] ?? '').toLowerCase();
        return existing.categoryName.toLowerCase() == newCategory &&
            existing.amount == newAmount &&
            existing.date == normalizedDate;
      },
    );
  }
}