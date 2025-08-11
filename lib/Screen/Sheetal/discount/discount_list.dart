import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheetal/Screen/Sheetal/discount/discount.dart';
import 'package:sheetal/Screen/Sheetal/discount/discount_add.dart';
import 'package:sheetal/Screen/Sheetal/discount/discount_detail.dart';
import 'package:sheetal/common/amount_format.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/custom_color.dart';
import 'package:sheetal/common/custom_listview.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class DiscountListScreen extends StatefulWidget {
  const DiscountListScreen({super.key});

  @override
  State<DiscountListScreen> createState() => _DiscountListScreenState();
}

class _DiscountListScreenState extends State<DiscountListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  String _searchText = '';
  Stream<List<Discount>>? _stream;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _stream = _firebaseService.getDiscounts();
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.toLowerCase());
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
      appBar: CustomAppBar(title: const Text('Discounts')),
      body: StreamBuilder<List<Discount>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Utility.circleloading();
          }

          if (snapshot.hasError) {
            return Center(child: Text(AppStrings.genericError + snapshot.error.toString()));
          }

          final items = (snapshot.data ?? [])
              .where((d) => d.month.toLowerCase().contains(_searchText))
              .toList();

          int _compareByMonth(Discount a, Discount b) {
            DateTime? parseMonth(String s) {
              try {
                return DateFormat('MMMM yyyy').parse(s);
              } catch (_) {
                return null;
              }
            }

            final da = parseMonth(a.month);
            final db = parseMonth(b.month);
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return da.compareTo(db);
          }

          final sorted = [...items];
          sorted.sort((a, b) => _sortAscending ? _compareByMonth(a, b) : _compareByMonth(b, a));

          return GenericListView<Discount>(
            items: sorted,
            isLoading: false,
            emptyMessage: 'No Discount Found',
            searchController: _searchController,
            onSearch: (text) => setState(() => _searchText = text.toLowerCase()),
            searchText: _searchText,
            getTitle: (d) => d.month,
            getAmount: (d) => '₹${Global.formatAmount(d.amount)}',
            getAmountColor: (_) => CustomColors.green1,
            getSubtitle: (d) => d.notes ?? '',
            getInitials: (d) => d.month.isNotEmpty
                ? d.month.substring(0, min(2, d.month.length)).toUpperCase()
                : '',
            getDateString: (d) => d.month,
            enableSorting: true,
            sortAscending: _sortAscending,
            onSortChanged: (ascending) => setState(() => _sortAscending = ascending),
            onItemTap: (d) async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DiscountDetailScreen(discount: d),
                ),
              );
              if (result == true) {}
            },
          );
        },
      ),
      floatingActionButton: CustomFAB(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddDiscountScreen()),
          );
        },
      ),
    );
  }
}


