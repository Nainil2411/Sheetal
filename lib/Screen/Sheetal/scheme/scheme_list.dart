import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheetal/Screen/Sheetal/discount/discount.dart';
import 'package:sheetal/Screen/Sheetal/scheme/scheme_add.dart';
import 'package:sheetal/Screen/Sheetal/scheme/scheme_detail.dart';
import 'package:sheetal/common/amount_format.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/custom_color.dart';
import 'package:sheetal/common/custom_listview.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';
import 'package:sheetal/common/common_import.dart';
import 'package:sheetal/common/export_utility.dart';

class SchemeListScreen extends StatefulWidget {
  const SchemeListScreen({super.key});

  @override
  State<SchemeListScreen> createState() => _SchemeListScreenState();
}

class _SchemeListScreenState extends State<SchemeListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  String _searchText = '';
  Stream<List<Discount>>? _stream;
  bool _sortAscending = false;
  List<Discount> _allSchemes = [];
  List<Discount> _filteredSchemes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _stream = _firebaseService.getSchemes();
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.toLowerCase());
    });
    _loadSchemes();
  }

  void _loadSchemes() {
    _stream?.listen((schemes) {
      if (mounted) {
        setState(() {
          _allSchemes = _sortSchemesByDate(schemes);
          _filteredSchemes = _allSchemes.where((d) => d.month.toLowerCase().contains(_searchText)).toList();
          _isLoading = false;
        });
      }
    });
  }

  // Helper method to sort schemes by date (latest first)
  List<Discount> _sortSchemesByDate(List<Discount> schemes) {
    final dateFormat = DateFormat('MMMM yyyy');

    List<Discount> sortedSchemes = List.from(schemes);
    sortedSchemes.sort((a, b) {
      try {
        final dateA = dateFormat.parse(a.month);
        final dateB = dateFormat.parse(b.month);
        return dateB.compareTo(dateA); // Latest first (descending order)
      } catch (e) {
        // If there's an error parsing dates, maintain original order
        return 0;
      }
    });

    return sortedSchemes;
  }

  Future<void> _importSchemesFromFile(BuildContext context) async {
    await ImportUtility.importFromFile<Discount>(
      context: context,
      config: ImportConfigs.schemeConfig,
      onComplete: () {
        setState(() {});
      },
    );
  }

  Future<void> _exportSchemesToExcel(BuildContext context) async {
    await ExportUtility.exportToExcel<Discount>(
      context: context,
      data: _filteredSchemes,
      config: ExportConfigs.schemeConfig,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: const Text('Schemes')),
      body: StreamBuilder<List<Discount>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Utility.circleloading();
          }

          if (snapshot.hasError) {
            return Center(child: Text(AppStrings.genericError + snapshot.error.toString()));
          }

          final items = (_sortSchemesByDate(snapshot.data ?? []))
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

          return Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: GenericListView<Discount>(
              items: sorted,
              isLoading: false,
              emptyMessage: 'No Scheme Found',
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
                    builder: (context) => SchemeDetailScreen(scheme: d),
                  ),
                );
                if (result == true) {}
              },
            ),
          );
        },
      ),
      bottomSheet: BottomSheet(
        shape: Border.all(color: CustomColors.background),
        backgroundColor: CustomColors.background,
        onClosing: () {},
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                FloatingActionButton(
                  heroTag: 'importSchemeFab',
                  onPressed: () => _importSchemesFromFile(context),
                  backgroundColor: CustomColors.textSecondary,
                  child: const Icon(Icons.upload_file, color: Colors.white),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  heroTag: 'exportSchemeFab',
                  onPressed: () => _exportSchemesToExcel(context),
                  backgroundColor: CustomColors.textSecondary,
                  child: const Icon(Icons.download, color: Colors.white),
                ),
                const SizedBox(width: 200),
                CustomFAB(
                  heroTag: 'addSchemeFab',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddSchemeScreen()),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}