import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/discount/discount.dart';
import 'package:sheetal/Screen/Sheetal/scheme/scheme_edit.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/detail_card.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class SchemeDetailScreen extends StatefulWidget {
  final Discount scheme;
  const SchemeDetailScreen({super.key, required this.scheme});

  @override
  State<SchemeDetailScreen> createState() => _SchemeDetailScreenState();
}

class _SchemeDetailScreenState extends State<SchemeDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Discount _scheme;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scheme = widget.scheme;
  }

  Future<void> _delete() async {
    await Utility.showDeleteConfirmationDialog(
      context: context,
      onConfirm: () async {
        setState(() => _isLoading = true);
        try {
          await _firebaseService.deleteScheme(_scheme.id!);
          if (mounted) Navigator.pop(context, true);
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _edit() async {
    final result = await Navigator.push<Discount>(
      context,
      MaterialPageRoute(
        builder: (context) => EditSchemeScreen(scheme: _scheme),
      ),
    );
    if (result != null) setState(() => _scheme = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Scheme Detail'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _isLoading ? null : _edit),
          IconButton(icon: const Icon(Icons.delete), onPressed: _isLoading ? null : _delete),
        ],
      ),
      body: _isLoading
          ? Utility.circleloading()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: DetailCard(
                amount: _scheme.amount,
                isExpense: false,
                amountLabel: "Scheme Amount",
                detailRows: [
                  DetailRow(label: 'Month', value: _scheme.month),
                  if ((_scheme.notes ?? '').isNotEmpty)
                    DetailRow(label: AppStrings.notes, value: _scheme.notes!),
                ],
              ),
            ),
    );
  }
}


