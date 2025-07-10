import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:sheetal/Screen/Sheetal/collection/collection.dart';
import 'package:sheetal/common/amount_format.dart';
import 'package:sheetal/common/custom_listview.dart';

import '../../common/app_string.dart';
import '../../common/custom_appbar.dart';
import '../../common/custom_color.dart';
import '../../utils/firebase_service.dart';
import '../../utils/utility.dart';

class FinancePortfolioScreen extends StatefulWidget {
  const FinancePortfolioScreen({super.key});

  @override
  State<FinancePortfolioScreen> createState() => _FinancePortfolioScreenState();
}

class _FinancePortfolioScreenState extends State<FinancePortfolioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _firebaseService = FirebaseService();
  bool isLoading = true;

  List<Map<String, dynamic>> allReminders = [];
  List<Map<String, dynamic>> filteredReminders = [];
  String selectedReminderRange = '';
  List<Collection> allChequeCollections = [];
  List<Collection> filteredChequeCollections = [];
  String selectedChequeRange = '';
  List<Map<String, dynamic>> allDateWiseRemaining = [];
  List<Map<String, dynamic>> filteredDateWiseRemaining = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Changed to 3 tabs
    _loadFinanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFinanceData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await Future.wait([
        _loadReminders(),
        _loadPendingCheques(),
        _loadDateWiseRemainingCollections(),
      ]);
    } catch (e) {
      log('Error loading finance data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadDateWiseRemainingCollections() async {
    try {
      final invoices = await _firebaseService.getInvoices().first;
      final bankCollections = await _firebaseService.getBanks().first;

      // Group invoices by date
      Map<String, double> invoiceAmountByDate = {};
      for (var invoice in invoices) {
        invoiceAmountByDate[invoice.date] =
            (invoiceAmountByDate[invoice.date] ?? 0) + invoice.amount;
      }

      // Group bank collections by date
      Map<String, double> bankCollectionAmountByDate = {};
      for (var bank in bankCollections) {
        bankCollectionAmountByDate[bank.selectedDate ?? ''] =
            (bankCollectionAmountByDate[bank.selectedDate ?? ''] ?? 0) + bank.total;
      }

      // Calculate remaining amounts by date
      List<Map<String, dynamic>> dateWiseRemaining = [];
      invoiceAmountByDate.forEach((date, invoiceAmount) {
        double collectedAmount = bankCollectionAmountByDate[date] ?? 0;
        double remainingAmount = invoiceAmount - collectedAmount;

        if (remainingAmount > 0) {
          dateWiseRemaining.add({
            'date': date,
            'invoiceAmount': invoiceAmount,
            'collectedAmount': collectedAmount,
            'remainingAmount': remainingAmount,
            'collectionPercentage': (collectedAmount / invoiceAmount * 100).round(),
          });
        }
      });

      // Sort by date (newest first)
      dateWiseRemaining.sort((a, b) {
        try {
          DateTime dateA = DateFormat('dd/MM/yyyy').parse(a['date']);
          DateTime dateB = DateFormat('dd/MM/yyyy').parse(b['date']);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

      setState(() {
        allDateWiseRemaining = dateWiseRemaining;
        filteredDateWiseRemaining = List.from(dateWiseRemaining);
      });
    } catch (e) {
      log('Error loading date-wise remaining collections: $e');
    }
  }

  Future<void> _loadReminders() async {
    try {
      final invoices = await _firebaseService.getInvoices().first;
      final collections = await _firebaseService.getCollections().first;

      Map<String, double> invoiceAmountByCustomer = {};
      Map<String, double> collectionAmountByCustomer = {};

      for (var invoice in invoices) {
        invoiceAmountByCustomer[invoice.customerName] =
            (invoiceAmountByCustomer[invoice.customerName] ?? 0) +
                invoice.amount;
      }

      for (var collection in collections) {
        collectionAmountByCustomer[collection.customerName] =
            (collectionAmountByCustomer[collection.customerName] ?? 0) +
                collection.amount;
      }

      List<Map<String, dynamic>> pendingReminders = [];
      invoiceAmountByCustomer.forEach((customer, invoiceAmount) {
        double collectionAmount = collectionAmountByCustomer[customer] ?? 0;
        double pendingAmount = invoiceAmount - collectionAmount;

        if (pendingAmount > 0) {
          pendingReminders.add({
            'customerName': customer,
            'pendingAmount': pendingAmount,
            'type': 'collection',
            'dateCreated': DateTime.now().toString(),
          });
        }
      });

      setState(() {
        allReminders = pendingReminders;
        filteredReminders = List.from(pendingReminders);
      });
    } catch (e) {
      log('Error loading reminders: $e');
    }
  }

  Future<void> _loadPendingCheques() async {
    try {
      final collections = await _firebaseService.getCollections().first;

      List<Collection> pendingCheques = collections.where((collection) {
        return collection.isPendingCheque;
      }).toList();

      setState(() {
        allChequeCollections = pendingCheques;
        filteredChequeCollections = List.from(pendingCheques);
      });
    } catch (e) {
      log('Error loading pending cheques: $e');
    }
  }

  Future<void> _updateChequeDate(Collection collection) async {
    final BuildContext ctx = context; // or use Get.context! if you're in GetX
    final DateTime? picked = await showDatePicker(
      context: ctx,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      final formattedDate = DateFormat('dd/MM/yyyy').format(picked);

      await Utility.showDeleteConfirmationDialog(
        context: ctx,
        title: 'Confirm Cheque Date',
        content: 'Are you sure you want to set the cheque date to $formattedDate?',
        onConfirm: () async {
          try {
            final updatedCollection = Collection(
              id: collection.id,
              customerName: collection.customerName,
              amount: collection.amount,
              paymentMode: collection.paymentMode,
              date: collection.date,
              chequeDate: formattedDate,
              createdAt: collection.createdAt,
            );

            final success =
            await _firebaseService.updateCollection(updatedCollection);
            if (success) {
              _loadPendingCheques();

              // Optional: show feedback
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Cheque date updated to $formattedDate')),
              );
            }
          } catch (e) {
            log('Error updating cheque date: $e');
          }
        },
      );
    }
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(symbol: '\u20B9', decimalDigits: 2);
    return format.format(amount);
  }

  Future<void> _exportDateWiseRemainingToPdf() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Utility.circleloading();
        },
      );

      final pdf = pw.Document();
      final ttf = pw.Font.ttf(
        await rootBundle
            .load('assets/fonts/Noto_Sans/static/NotoSans-Regular.ttf'),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Date-wise Remaining Collections Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Generated on: ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Divider(),
            ],
          ),
          build: (context) => [
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
              headers: ['Date', 'Invoice Amount', 'Collected', 'Remaining', 'Progress'],
              cellStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf),
              data: filteredDateWiseRemaining.map((item) {
                return [
                  item['date'] ?? '',
                  _formatCurrency(item['invoiceAmount'] ?? 0.0),
                  _formatCurrency(item['collectedAmount'] ?? 0.0),
                  _formatCurrency(item['remainingAmount'] ?? 0.0),
                  '${item['collectionPercentage']}%',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Total Dates with Pending Collections: ${filteredDateWiseRemaining.length}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf),
            ),
            pw.Text(
              'Total Remaining Amount: ${_formatCurrency(filteredDateWiseRemaining.fold(0.0, (sum, item) => sum + (item['remainingAmount'] as double)))}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf),
            ),
          ],
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final dateStr = DateTime.now()
          .toString()
          .replaceAll(':', '_')
          .replaceAll(' ', '_')
          .substring(0, 19);
      final file = File('${directory.path}/datewise_remaining_report_$dateStr.pdf');

      await file.writeAsBytes(await pdf.save());
      Navigator.of(context).pop();
      await Share.shareXFiles([XFile(file.path)],
          text: 'Date-wise Remaining Collections Report');
    } catch (e) {
      Navigator.of(context).pop();
      log('Error exporting date-wise remaining to PDF: $e');
    }
  }

  Future<void> _exportRemindersToPdf() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Utility.circleloading();
        },
      );

      final pdf = pw.Document();
      final ttf = pw.Font.ttf(
        await rootBundle
            .load('assets/fonts/Noto_Sans/static/NotoSans-Regular.ttf'),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Collection Reminders Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Generated on: ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Divider(),
            ],
          ),
          build: (context) => [
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerLeft,
              },
              headers: ['Customer Name', 'Pending Amount', 'Status'],
              cellStyle:
              pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf),
              data: filteredReminders.map((reminder) {
                return [
                  reminder['customerName'] ?? '',
                  _formatCurrency(reminder['pendingAmount'] ?? 0.0),
                  'Collection Pending',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Total Reminders: ${filteredReminders.length}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf),
            ),
            pw.Text(
              'Total Pending Amount: ${_formatCurrency(filteredReminders.fold(0.0, (sum, reminder) => sum + (reminder['pendingAmount'] as double)))}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf),
            ),
          ],
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final dateStr = DateTime.now()
          .toString()
          .replaceAll(':', '_')
          .replaceAll(' ', '_')
          .substring(0, 19);
      final file = File('${directory.path}/reminders_report_$dateStr.pdf');

      await file.writeAsBytes(await pdf.save());
      Navigator.of(context).pop();
      await Share.shareXFiles([XFile(file.path)],
          text: 'Collection Reminders Report');
    } catch (e) {
      Navigator.of(context).pop();
      log('Error exporting reminders to PDF: $e');
    }
  }

  Future<void> _exportChequesToPdf() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Utility.circleloading();
        },
      );

      final pdf = pw.Document();
      final ttf = pw.Font.ttf(
        await rootBundle
            .load('assets/fonts/Noto_Sans/static/NotoSans-Regular.ttf'),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Pending Cheques Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Generated on: ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Divider(),
            ],
          ),
          build: (context) => [
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
              },
              headers: [
                'Customer Name',
                'Amount',
                'Collection Date',
                'Cheque Date',
                'Payment Mode'
              ],
              cellStyle:
              pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf),
              data: filteredChequeCollections.map((cheque) {
                return [
                  cheque.customerName,
                  _formatCurrency(cheque.amount),
                  cheque.date,
                  cheque.chequeDate ?? 'Not Set',
                  cheque.paymentMode,
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Total Pending Cheques: ${filteredChequeCollections.length}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf),
            ),
            pw.Text(
              'Total Cheque Amount: ${_formatCurrency(filteredChequeCollections.fold(0.0, (sum, cheque) => sum + cheque.amount))}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf),
            ),
          ],
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final dateStr = DateTime.now()
          .toString()
          .replaceAll(':', '_')
          .replaceAll(' ', '_')
          .substring(0, 19);

      final file =
      File('${directory.path}/pending_cheques_report_$dateStr.pdf');

      await file.writeAsBytes(await pdf.save());
      Navigator.of(context).pop();
      await Share.shareXFiles([XFile(file.path)],
          text: 'Pending Cheques Report');
    } catch (e) {
      Navigator.of(context).pop();
      log('Error exporting cheques to PDF: $e');
    }
  }

  Widget _buildDateWiseRemainingTab() {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      bottomSheet: BottomSheet(
        shape: Border.all(color: CustomColors.background),
        backgroundColor: CustomColors.background,
        onClosing: () {},
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (filteredDateWiseRemaining.isNotEmpty)
                  FloatingActionButton(
                    heroTag: 'exportDateWiseRemainingPdfFab',
                    onPressed: _exportDateWiseRemainingToPdf,
                    backgroundColor: CustomColors.textPrimary,
                    child: const Icon(Icons.picture_as_pdf,
                        color: CustomColors.background),
                  ),
              ],
            ),
          );
        },
      ),
      body: RefreshIndicator(
        color: CustomColors.textPrimary,
        onRefresh: _loadFinanceData,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: GenericListView<Map<String, dynamic>>(
            showTrailingIcon: false,
            showSearch: false,
            items: List<Map<String, dynamic>>.from(filteredDateWiseRemaining)
              ..sort((a, b) {
                final dateA = dateFormat.parse(a['date']);
                final dateB = dateFormat.parse(b['date']);
                return dateB.compareTo(dateA); // descending
              }),
            isLoading: isLoading,
            emptyMessage: 'No remaining collections found',
            searchController: TextEditingController(),
            onSearch: (_) {},
            searchText: '',
            getTitle: (item) => item['date'] ?? '',
            getSubtitle: (item) =>
            'Collected: ₹${Global.formatAmount(item['collectedAmount'])} (${item['collectionPercentage']}%)\n'
                'Invoice Total: ₹${Global.formatAmount(item['invoiceAmount'])}',
            getInitials: (item) =>
            (item['date']?.isNotEmpty ?? false) ? item['date'].substring(0, 2) : '?',
            getAmount: (item) =>
            '₹${Global.formatAmount(item['remainingAmount'])}',
            getAmountColor: (_) => CustomColors.error1,
            onItemTap: (_) {},
            isSelectionMode: false,
          ),
        ),
      ),
    );
  }

  Widget _buildPendingChequesTab() {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      bottomSheet: BottomSheet(
        shape: Border.all(color: CustomColors.background),
        backgroundColor: CustomColors.background,
        onClosing: () {},
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (filteredChequeCollections.isNotEmpty)
                  FloatingActionButton(
                    heroTag: 'exportChequesPdfFab',
                    onPressed: _exportChequesToPdf,
                    backgroundColor: CustomColors.textPrimary,
                    child: const Icon(Icons.picture_as_pdf,
                        color: CustomColors.background),
                  ),
              ],
            ),
          );
        },
      ),
      body: RefreshIndicator(
        color: CustomColors.textPrimary,
        onRefresh: _loadFinanceData,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: GenericListView<Collection>(
            showSearch: false,
            items: List<Collection>.from(filteredChequeCollections)
              ..sort((a, b) {
                final dateA = dateFormat.parse(a.date);
                final dateB = dateFormat.parse(b.date);
                return dateB.compareTo(dateA); // descending
              }),
            isLoading: isLoading,
            emptyMessage: 'No pending cheques found',
            searchController: TextEditingController(),
            onSearch: (_) {},
            searchText: '',
            getTitle: (item) => item.customerName,
            getSubtitle: (item) => 'Collection Date: ${item.date}\n'
                'Cheque Date: ${item.chequeDate ?? "Not Set"}',
            getInitials: (item) =>
            item.customerName.isNotEmpty ? item.customerName[0] : '?',
            getAmount: (item) => '₹ ${Global.formatAmount(item.amount)}',
            getAmountColor: (item) => item.chequeDate == null
                ? CustomColors.error1
                : CustomColors.textSecondary,
            onItemTap: (item) => _updateChequeDate(item),
            getTrailingIcon: (_) => Icons.calendar_today,
          ),
        ),
      ),
    );
  }

  Widget _buildRemindersTab() {
    return Scaffold(
      bottomSheet: BottomSheet(
        shape: Border.all(color: CustomColors.background),
        backgroundColor: CustomColors.background,
        onClosing: () {},
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (filteredReminders.isNotEmpty)
                  FloatingActionButton(
                    heroTag: 'exportRemindersPdfFab',
                    onPressed: _exportRemindersToPdf,
                    backgroundColor: CustomColors.textPrimary,
                    child: const Icon(Icons.picture_as_pdf,
                        color: CustomColors.background),
                  ),
              ],
            ),
          );
        },
      ),
      body: RefreshIndicator(
        color: CustomColors.textPrimary,
        onRefresh: _loadFinanceData,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: GenericListView<Map<String, dynamic>>(
            showTrailingIcon: false,
            showSearch: false,
            items: filteredReminders,
            isLoading: isLoading,
            emptyMessage: 'No reminders found',
            searchController: TextEditingController(),
            onSearch: (_) {},
            searchText: '',
            getTitle: (item) => item['customerName'] ?? '',
            getSubtitle: (_) => 'Collection Pending',
            getInitials: (item) => (item['customerName']?.isNotEmpty ?? false)
                ? item['customerName'][0]
                : '?',
            getAmount: (item) =>
            '₹ ${Global.formatAmount(item['pendingAmount'])}',
            getAmountColor: (_) => CustomColors.error1,
            onItemTap: (_) {},
            isSelectionMode: false,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text(AppStrings.portfolio),
        bottom: TabBar(
          controller: _tabController,
          labelColor: CustomColors.textPrimary,
          unselectedLabelColor: CustomColors.textSecondary,
          indicatorColor: CustomColors.textPrimary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Reminders'),
            Tab(text: 'Pending Cheques'),
            Tab(text: 'Bank Collection'), // New tab
          ],
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? Utility.circleloading()
            : TabBarView(
          controller: _tabController,
          children: [
            _buildRemindersTab(),
            _buildPendingChequesTab(),
            _buildDateWiseRemainingTab(),
          ],
        ),
      ),
    );
  }
}