import 'package:flutter/material.dart';
import 'package:sheetal/common/amount_format.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/custom_color.dart';
import 'pendingcollection_detail.dart';

class AllPendingCollectionsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> pendingCollections;

  const
  AllPendingCollectionsScreen({
    super.key,
    required this.pendingCollections,
  });

  @override
  State<AllPendingCollectionsScreen> createState() => _AllPendingCollectionsScreenState();
}

class _AllPendingCollectionsScreenState extends State<AllPendingCollectionsScreen> {
  late List<Map<String, dynamic>> _pendingCollections;

  @override
  void initState() {
    super.initState();
    _pendingCollections = List.from(widget.pendingCollections);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text(AppStrings.pendingCollections),
      ),
      body: _pendingCollections.isEmpty
          ? const Center(child: Text(AppStrings.nopendingcollections))
          : ListView.builder(
        itemCount: _pendingCollections.length,
        itemBuilder: (context, index) {
          final item = _pendingCollections[index];
          return _buildPendingCollectionItem(item, index);
        },
      ),
    );
  }

  Widget _buildPendingCollectionItem(Map<String, dynamic> item, int index) {
    return Card(
      elevation: 2,
      color: CustomColors.background,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PendingCollectionDetailScreen(
                pendingCollection: item,
              ),
            ),
          );
          if (result == true) {
            setState(() {
              _pendingCollections.removeAt(index);
            });
          }
        },
        title: Text(item['customerName']),
        subtitle: const Text(AppStrings.pendingamount),
        trailing: Text(
          '₹${Global.formatAmount(item['pendingAmount'])}',
          style: const TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
