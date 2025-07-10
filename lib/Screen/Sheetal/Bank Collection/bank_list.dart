import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/Bank%20Collection/bank.dart';
import 'package:sheetal/Screen/Sheetal/Bank%20Collection/bank_add.dart';
import 'package:sheetal/Screen/Sheetal/Bank%20Collection/bank_detail.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';
import 'package:sheetal/common/amount_format.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/custom_color.dart';
import 'package:sheetal/common/custom_listview.dart';
import 'package:sheetal/common/elevated_button.dart';

class BankListScreen extends StatefulWidget {
  const BankListScreen({super.key});

  @override
  State<BankListScreen> createState() => _BankListScreenState();
}

class _BankListScreenState extends State<BankListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  String _searchText = '';
  Stream<List<Bank>>? _banksStream;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _banksStream = _firebaseService.getBanks();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Bank Collection'),
      ),
      body: StreamBuilder<List<Bank>>(
        stream: _banksStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Utility.circleloading();
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          List<Bank> banks = snapshot.data ?? [];
          final filteredBanks = banks.where((bank) {
            return (bank.selectedDate?.toLowerCase().contains(_searchText) ?? false) ||
                bank.total.toString().contains(_searchText);
          }).toList();

          return GenericListView<Bank>(
            items: filteredBanks,
            isLoading: false,
            emptyMessage: 'No bank collections found',
            searchController: _searchController,
            onSearch: (text) {
              setState(() {
                _searchText = text.toLowerCase();
              });
            },
            searchText: _searchText,
            getTitle: (bank) => bank.selectedDate ?? 'No Date',
            getAmount: (bank) => '₹${Global.formatAmount(bank.total)}',
            getAmountColor: (bank) => CustomColors.green1,
            getSubtitle: (bank) => 'Invoice: ₹${Global.formatAmount(bank.invoiceTotal)}',
            getInitials: (bank) => bank.selectedDate?.isNotEmpty == true
                ? bank.selectedDate!.substring(0, min(2, bank.selectedDate!.length)).toUpperCase()
                : 'BC',
            getDateString: (bank) => 'Cash: ₹${Global.formatAmount(bank.cash)} | Online: ₹${Global.formatAmount(bank.online)}',
            enableSorting: true,
            sortAscending: _sortAscending,
            onSortChanged: (ascending) {
              setState(() {
                _sortAscending = ascending;
              });
            },
            onItemTap: (bank) async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BankDetailScreen(bank: bank),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: CustomFAB(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddBankScreen(),
            ),
          );
        },
      ),
    );
  }
}