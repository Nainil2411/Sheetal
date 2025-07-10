import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheetal/Screen/Sheetal/Invoices/invoice.dart';
import 'package:sheetal/Screen/Sheetal/collection/collection.dart';
import 'package:sheetal/Screen/Sheetal/customer/customer_module.dart';
import 'package:sheetal/Screen/Sheetal/customer/edit_sheetalcustomer.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/common_font_style.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/custom_color.dart';
import 'package:sheetal/common/user_detail_common.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  bool _isLoading = false;
  Map<String, dynamic> _customerSummary = {
    'totalInvoice': 0.0,
    'totalCollection': 0.0,
    'balance': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadCustomerSummary();
  }

  Future<void> _loadCustomerSummary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final invoices = await _loadInvoicesTotalForCustomer(widget.customer.id!);
      final collections =
      await _loadCollectionsTotalForCustomer(widget.customer.id!);

      setState(() {
        _customerSummary = {
          'totalInvoice': invoices,
          'totalCollection': collections,
          'balance': invoices - collections,
        };
      });
    } catch (e) {
      log('Error loading customer summary: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<double> _loadInvoicesTotalForCustomer(String customerId) async {
    try {
      final allInvoices = await _firebaseService.getInvoices().first;
      final customerInvoices = allInvoices
          .where((invoice) => invoice.customerName == widget.customer.name)
          .toList();
      double total = 0.0;
      for (var invoice in customerInvoices) {
        total += invoice.amount;
      }
      return total;
    } catch (e) {
      log('Error calculating invoice total: $e');
      return 0.0;
    }
  }

  Future<double> _loadCollectionsTotalForCustomer(String customerId) async {
    try {
      final allCollections = await _firebaseService.getCollections().first;
      final customerCollections = allCollections
          .where(
              (collection) => collection.customerName == widget.customer.name)
          .toList();
      double total = 0.0;
      for (var collection in customerCollections) {
        total += collection.amount;
      }
      return total;
    } catch (e) {
      log('Error calculating collection total: $e');
      return 0.0;
    }
  }

  Future<void> _deleteCustomer() async {
    await Utility.showDeleteConfirmationDialog(
      context: context,
      onConfirm: () async {
        setState(() {
          _isLoading = true;
        });
        final success =
        await _firebaseService.deleteSheetalCustomer(widget.customer.id!);
        if (mounted) {
          if (success) {
            Navigator.pop(context, true);
          } else {
            setState(() {
              _isLoading = false;
            });
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text(AppStrings.customerdetails),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditCustomerScreen(customer: widget.customer),
                ),
              );
              if (result == true) {
                _loadCustomerSummary();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteCustomer,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingPlaceholder()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomerHeader(),
            const SizedBox(height: 15),
            _buildInfoCard(),
            const SizedBox(height: 15),
            _buildFinanceSummaryCard(),
            const SizedBox(height: 15),
            _buildTransactionHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerHeader() {
    return Row(
      children: [
        UserAvatar(name: widget.customer.name),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.customer.name,
                style: AppTextStyles.headline4,
              ),
              const SizedBox(height: 4),
              Text(
                widget.customer.phone,
                style: AppTextStyles.amountsmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return ShadowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: AppStrings.userinfo,
            style: AppTextStyles.amountMedium,
          ),
          InfoRow(label: AppStrings.name, value: widget.customer.name),
          InfoRow(label: AppStrings.phoneHint, value: widget.customer.phone),
          InfoRow(
            label: 'Created On',
            value: _dateFormat
                .format(widget.customer.createdAt?.toDate() ?? DateTime.now()),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceSummaryCard() {
    return ShadowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: AppStrings.financesummary),
          Row(
            children: [
              Expanded(
                child: FinancialItem(
                  label: AppStrings.invoices,
                  amount: _customerSummary['totalInvoice'],
                  color: CustomColors.error,
                ),
              ),
              Expanded(
                child: FinancialItem(
                  label: AppStrings.collections,
                  amount: _customerSummary['totalCollection'],
                  color: CustomColors.green1,
                ),
              ),
            ],
          ),
          const Divider(),
          FinancialItem(
            label: AppStrings.pending,
            amount: _customerSummary['balance'],
            color: _customerSummary['balance'] <= 0
                ? CustomColors.green1
                : CustomColors.error,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return ShadowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: AppStrings.transactionshistory),
          _buildTransactionTabs(),
        ],
      ),
    );
  }

  Widget _buildTransactionTabs() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: CustomColors.textPrimary,
            unselectedLabelColor: CustomColors.textSecondary,
            indicatorColor: CustomColors.textPrimary,
            tabs: [
              Tab(text: AppStrings.invoicehistory),
              Tab(text: AppStrings.collectionhistory),
            ],
          ),
          SizedBox(
            height: 300,
            child: TabBarView(
              children: [
                _buildInvoiceList(),
                _buildCollectionList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceList() {
    return StreamBuilder<List<Invoice>>(
      stream: _firebaseService.getInvoices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPlaceholder();
        }

        if (snapshot.hasError) {
          return Center(
              child: Text(AppStrings.genericError + snapshot.error.toString()));
        }

        final invoices = snapshot.data ?? [];
        final customerInvoices = invoices
            .where((invoice) => invoice.customerName == widget.customer.name)
            .toList();

        if (customerInvoices.isEmpty) {
          return const Center(child: Text(AppStrings.noinvoicesfound));
        }

        return ListView.builder(
          itemCount: customerInvoices.length,
          itemBuilder: (context, index) {
            final invoice = customerInvoices[index];
            DateTime parsedDate;
            try {
              final dateFormat = DateFormat('dd/MM/yyyy');
              parsedDate = dateFormat.parse(invoice.date);
            } catch (e) {
              parsedDate = DateTime.now();
              print('Error parsing date: ${invoice.date}, using current date');
            }

            return TransactionItem(
              amount: invoice.amount,
              date: parsedDate,
              description: invoice.categoryName,
              isCredit: false,
            );
          },
        );
      },
    );
  }

  Widget _buildCollectionList() {
    return StreamBuilder<List<Collection>>(
      stream: _firebaseService.getCollections(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPlaceholder();
        }

        if (snapshot.hasError) {
          return Center(
              child: Text(AppStrings.genericError + snapshot.error.toString()));
        }

        final collections = snapshot.data ?? [];
        final customerCollections = collections
            .where(
                (collection) => collection.customerName == widget.customer.name)
            .toList();

        if (customerCollections.isEmpty) {
          return const Center(child: Text(AppStrings.nocollectionsfound));
        }

        return ListView.builder(
          itemCount: customerCollections.length,
          itemBuilder: (context, index) {
            final collection = customerCollections[index];
            DateTime parsedDate;
            try {
              final dateFormat = DateFormat('dd/MM/yyyy');
              parsedDate = dateFormat.parse(collection.date);
            } catch (e) {
              parsedDate = DateTime.now();
              print('Error parsing collection date: ${collection.date}, using current date');
            }
            return TransactionItem(
              amount: collection.amount,
              date: parsedDate,
              description: collection.paymentMode,
              isCredit: true,
            );
          },
        );
      },
    );
  }
}
