import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheetal/Screen/Sheetal/collection/collection.dart';
import 'package:sheetal/common/amount_format.dart';
import 'package:sheetal/common/custom_color.dart';
import 'package:sheetal/utils/firebase_service.dart';

class TallyReviewScreen extends StatefulWidget {
  final DateTimeRange dateRange;
  final List<Collection> collections;

  const TallyReviewScreen({
    super.key,
    required this.dateRange,
    required this.collections,
  });

  @override
  State<TallyReviewScreen> createState() => _TallyReviewScreenState();
}

class _TallyReviewScreenState extends State<TallyReviewScreen> {
  // ==================== State Variables ====================
  final FirebaseService _firebase = FirebaseService();
  final Map<String, Map<String, dynamic>?> _approvalCache = {};
  final Map<String, bool> _approvedTransactions = {};
  final Map<String, bool> _declinedTransactions = {};
  final Map<String, String> _transactionComments = {};
  final Set<String> _processingTransactions = {};
  bool _isLoading = true;

  // ==================== Lifecycle Methods ====================
  @override
  void initState() {
    super.initState();
    _loadApprovalStatuses();
  }

  // ==================== Data Loading Methods ====================
  Future<void> _loadApprovalStatuses() async {
    setState(() => _isLoading = true);

    try {
      final uniqueDates = widget.collections.map((c) => c.date).toSet();

      for (final date in uniqueDates) {
        final approvalData = await _firebase.getDepositApprovalByDate(date);
        _approvalCache[date] = approvalData;

        if (approvalData != null) {
          _loadCommentsFromCache(date, approvalData);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error loading approval statuses: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadCommentsFromCache(String date, Map<String, dynamic> approvalData) {
    if (approvalData['cashComment'] != null) {
      _transactionComments['${date}_cash'] = approvalData['cashComment'];
    }
    if (approvalData['onlineComment'] != null) {
      _transactionComments['${date}_online'] = approvalData['onlineComment'];
    }
  }

  // ==================== Dialog Methods ====================
  Future<void> _showApprovalDialog(
      String transactionId,
      List<Collection> transactions,
      bool isCash,
      ) async {
    final result = await _showTransactionDialog(
      title: 'Approve ${isCash ? 'Cash' : 'Online'} Payment',
      transactions: transactions,
      actionLabel: 'Approve',
      actionColor: null,
      hintText: 'Enter your comment here...',
    );

    if (result != null) {
      await _approveTransaction(transactionId, transactions.first, result);
    }
  }

  Future<void> _showDeclineDialog(
      String transactionId,
      List<Collection> transactions,
      bool isCash,
      ) async {
    final result = await _showTransactionDialog(
      title: 'Decline ${isCash ? 'Cash' : 'Online'} Payment',
      transactions: transactions,
      actionLabel: 'Decline',
      actionColor: Colors.red,
      hintText: 'Enter reason for decline...',
    );

    if (result != null) {
      await _declineTransaction(transactionId, transactions.first, result);
    }
  }

  Future<String?> _showTransactionDialog({
    required String title,
    required List<Collection> transactions,
    required String actionLabel,
    required Color? actionColor,
    required String hintText,
  }) async {
    final TextEditingController commentController = TextEditingController();
    final totalAmount = transactions.fold<double>(0, (sum, t) => sum + t.amount);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Amount: ₹${Global.formatAmount(totalAmount)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Add a ${actionLabel.toLowerCase() == 'approve' ? 'comment' : 'reason'} (optional):'),
            const SizedBox(height: 8),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: hintText,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: actionColor != null
                ? ElevatedButton.styleFrom(backgroundColor: actionColor)
                : null,
            child: Text(
              actionLabel,
              style: actionColor != null
                  ? const TextStyle(color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );

    return confirmed == true ? commentController.text.trim() : null;
  }

  // ==================== Transaction Action Methods ====================
  Future<void> _approveTransaction(
      String transactionId,
      Collection collection,
      String? comment,
      ) async {
    await _processTransaction(
      transactionId: transactionId,
      collection: collection,
      comment: comment,
      isApproval: true,
      approvalValue: true,
    );
  }

  Future<void> _declineTransaction(
      String transactionId,
      Collection collection,
      String? comment,
      ) async {
    await _processTransaction(
      transactionId: transactionId,
      collection: collection,
      comment: comment,
      isApproval: false,
      approvalValue: false,
    );
  }

  Future<void> _deApproveTransaction(
      String transactionId,
      Collection collection,
      ) async {
    if (_processingTransactions.contains(transactionId)) return;

    _setProcessingState(transactionId, isProcessing: true, clearStatus: true);

    try {
      final isCash = collection.paymentMode.toLowerCase() == 'cash';

      await _firebase.deleteDepositApproval(
        dateDdMmYyyy: collection.date,
        deleteCashApproval: isCash ? true : null,
        deleteOnlineApproval: !isCash ? true : null,
      );

      _updateCacheAfterDeApproval(collection.date, isCash);
    } catch (e) {
      _showErrorSnackBar('Error removing approval: $e');
      await _loadApprovalStatuses();
    } finally {
      _setProcessingState(transactionId, isProcessing: false);
    }
  }

  Future<void> _processTransaction({
    required String transactionId,
    required Collection collection,
    required String? comment,
    required bool isApproval,
    required bool approvalValue,
  }) async {
    if (_processingTransactions.contains(transactionId)) return;

    _setTransactionState(
      transactionId: transactionId,
      comment: comment,
      isApproval: isApproval,
      approvalValue: approvalValue,
    );

    try {
      final isCash = collection.paymentMode.toLowerCase() == 'cash';

      await _firebase.setDepositApproval(
        dateDdMmYyyy: collection.date,
        cashApproved: isCash ? approvalValue : null,
        onlineApproved: !isCash ? approvalValue : null,
        cashComment: isCash ? comment : null,
        onlineComment: !isCash ? comment : null,
      );

      _updateCacheAfterAction(collection.date, isCash, approvalValue, comment);
    } catch (e) {
      _revertTransactionState(transactionId, comment);
      _showErrorSnackBar('Error ${isApproval ? 'approving' : 'declining'} transaction: $e');
    } finally {
      _setProcessingState(transactionId, isProcessing: false);
    }
  }

  // ==================== State Management Helper Methods ====================
  void _setProcessingState(String transactionId, {required bool isProcessing, bool clearStatus = false}) {
    setState(() {
      if (isProcessing) {
        _processingTransactions.add(transactionId);
        if (clearStatus) {
          _approvedTransactions.remove(transactionId);
          _declinedTransactions.remove(transactionId);
          _transactionComments.remove(transactionId);
        }
      } else {
        _processingTransactions.remove(transactionId);
      }
    });
  }

  void _setTransactionState({
    required String transactionId,
    required String? comment,
    required bool isApproval,
    required bool approvalValue,
  }) {
    setState(() {
      _processingTransactions.add(transactionId);

      if (isApproval) {
        _approvedTransactions[transactionId] = approvalValue;
        _declinedTransactions.remove(transactionId);
      } else {
        _declinedTransactions[transactionId] = approvalValue;
        _approvedTransactions.remove(transactionId);
      }

      if (comment != null && comment.isNotEmpty) {
        _transactionComments[transactionId] = comment;
      }
    });
  }

  void _revertTransactionState(String transactionId, String? comment) {
    if (mounted) {
      setState(() {
        _approvedTransactions.remove(transactionId);
        _declinedTransactions.remove(transactionId);
        if (comment != null) {
          _transactionComments.remove(transactionId);
        }
      });
    }
  }

  void _updateCacheAfterAction(String date, bool isCash, bool approvalValue, String? comment) {
    _approvalCache[date] = {
      ...(_approvalCache[date] ?? {}),
      if (isCash) 'cashApproved': approvalValue,
      if (!isCash) 'onlineApproved': approvalValue,
      if (isCash && comment != null) 'cashComment': comment,
      if (!isCash && comment != null) 'onlineComment': comment,
    };
  }

  void _updateCacheAfterDeApproval(String date, bool isCash) {
    final updatedCache = Map<String, dynamic>.from(_approvalCache[date] ?? {});
    if (isCash) {
      updatedCache.remove('cashApproved');
      updatedCache.remove('cashComment');
    } else {
      updatedCache.remove('onlineApproved');
      updatedCache.remove('onlineComment');
    }
    _approvalCache[date] = updatedCache;
  }

  // ==================== Status Check Methods ====================
  bool _isApproved(String transactionId, String date, bool isCash) {
    final approvalData = _approvalCache[date];
    if (approvalData == null) return false;

    final key = isCash ? 'cashApproved' : 'onlineApproved';
    return approvalData[key] == true;
  }

  bool _isDeclined(String transactionId, String date, bool isCash) {
    final approvalData = _approvalCache[date];
    if (approvalData == null) return false;

    final key = isCash ? 'cashApproved' : 'onlineApproved';
    return approvalData[key] == false;
  }

  String? _getComment(String date, bool isCash) {
    final approvalData = _approvalCache[date];
    if (approvalData == null) return null;

    final key = isCash ? 'cashComment' : 'onlineComment';
    return approvalData[key];
  }

  // ==================== UI Helper Methods ====================
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  String _getDisplayNames(List<Collection> transactions) {
    final customerNames = transactions.map((t) => t.customerName).toSet().toList();
    return customerNames.length <= 3
        ? customerNames.join(', ')
        : '${customerNames.take(2).join(', ')} +${customerNames.length - 2} others';
  }

  String _getOnlinePaymentMethods(List<Collection> transactions) {
    final methods = transactions
        .map((t) => _getPaymentMethodLabel(t.paymentMode))
        .toSet()
        .toList();
    return methods.join(', ');
  }

  String _getPaymentMethodLabel(String paymentMode) {
    switch (paymentMode.toLowerCase()) {
      case 'upi': return 'UPI';
      case 'card': return 'Card';
      case 'bank transfer': return 'Bank Transfer';
      case 'cheque': return 'Cheque';
      case 'others': return 'Others';
      default: return paymentMode;
    }
  }

  // ==================== Data Processing Methods ====================
  List<Collection> _getFilteredCollections() {
    return widget.collections.where((collection) {
      final paymentMode = collection.paymentMode.toLowerCase();
      return ['cash', 'upi', 'card', 'bank transfer', 'cheque', 'others']
          .contains(paymentMode);
    }).toList();
  }

  Map<String, Map<bool, List<Collection>>> _groupTransactionsByDateAndType(
      List<Collection> collections,
      ) {
    final grouped = <String, Map<bool, List<Collection>>>{};

    for (final collection in collections) {
      final date = collection.date;
      final isCash = collection.paymentMode.toLowerCase() == 'cash';

      grouped.putIfAbsent(date, () => <bool, List<Collection>>{});
      grouped[date]!.putIfAbsent(isCash, () => []).add(collection);
    }

    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Map.fromEntries(sortedEntries);
  }

  // ==================== Build Methods ====================
  @override
  Widget build(BuildContext context) {
    final filteredCollections = _getFilteredCollections();
    final groupedTransactions = _groupTransactionsByDateAndType(filteredCollections);

    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(groupedTransactions),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: CustomColors.background,
      scrolledUnderElevation: 0,
      title: Text(
        'Review ${DateFormat('dd MMM').format(widget.dateRange.start)} - ${DateFormat('dd MMM yyyy').format(widget.dateRange.end)}',
      ),
    );
  }

  Widget _buildContent(Map<String, Map<bool, List<Collection>>> groupedTransactions) {
    if (groupedTransactions.isEmpty) {
      return const Center(
        child: Text('No transactions to review for this period.'),
      );
    }

    return ListView(
      children: groupedTransactions.entries
          .map((dateEntry) => _buildDateSection(dateEntry.key, dateEntry.value))
          .toList(),
    );
  }

  Widget _buildDateSection(String date, Map<bool, List<Collection>> typeGroups) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateHeader(date),
        if (typeGroups[true]?.isNotEmpty == true)
          _buildGroupedTransactionCard(date, typeGroups[true]!, true),
        if (typeGroups[false]?.isNotEmpty == true)
          _buildGroupedTransactionCard(date, typeGroups[false]!, false),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        date,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildGroupedTransactionCard(
      String date,
      List<Collection> transactions,
      bool isCash,
      ) {
    final transactionId = '${date}_${isCash ? 'cash' : 'online'}';
    final totalAmount = transactions.fold<double>(0, (sum, t) => sum + t.amount);
    final isApproved = _isApproved(transactionId, date, isCash) ||
        _approvedTransactions[transactionId] == true;
    final isDeclined = _isDeclined(transactionId, date, isCash) ||
        _declinedTransactions[transactionId] == true;
    final isProcessing = _processingTransactions.contains(transactionId);
    final comment = _getComment(date, isCash) ?? _transactionComments[transactionId];

    return Card(
      elevation: 0,
      color: CustomColors.background,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Adjust radius as needed
        side: BorderSide(
          color: CustomColors.textSecondary.withOpacity(0.7),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(transactions, totalAmount, isCash),
            const SizedBox(height: 12),
            _buildCardActions(transactionId, transactions, isProcessing, isApproved, isDeclined, isCash, comment),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(List<Collection> transactions, double totalAmount, bool isCash) {
    final paymentTypeLabel = isCash ? 'Cash' : 'Online';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$paymentTypeLabel Payment${transactions.length > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${transactions.length} transaction${transactions.length > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _showTransactionDetailsDialog(transactions, isCash),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Text(
          '₹${Global.formatAmount(totalAmount)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showTransactionDetailsDialog(List<Collection> transactions, bool isCash) {
    final paymentTypeLabel = isCash ? 'Cash' : 'Online';
    final totalAmount = transactions.fold<double>(0, (sum, t) => sum + t.amount);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$paymentTypeLabel Transaction Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total: ₹${Global.formatAmount(totalAmount)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Transaction Details:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    transaction.customerName,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  if (!isCash)
                                    Text(
                                      _getPaymentMethodLabel(transaction.paymentMode),
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${Global.formatAmount(transaction.amount)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardActions(
      String transactionId,
      List<Collection> transactions,
      bool isProcessing,
      bool isApproved,
      bool isDeclined,
      bool isCash,
      String? comment,
      ) {
    if (isProcessing) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 8),
          Text('Processing...', style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    if (isApproved) {
      return _buildApprovedState(transactionId, transactions, comment);
    }

    if (isDeclined) {
      return _buildDeclinedState(transactionId, transactions, comment);
    }

    return _buildPendingState(transactionId, transactions, isCash);
  }

  Widget _buildApprovedState(String transactionId, List<Collection> transactions, String? comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Approved', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            TextButton.icon(
              onPressed: () => _deApproveTransaction(transactionId, transactions.first),
              icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
              label: const Text('De-approve', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
        if (comment != null && comment.isNotEmpty) _buildCommentContainer(comment, CustomColors.textSecondary.withValues(alpha:
        0.6), 'Comment:'),
      ],
    );
  }

  Widget _buildDeclinedState(String transactionId, List<Collection> transactions, String? comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.cancel, color: Colors.red),
                SizedBox(width: 8),
                Text('Declined', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            TextButton.icon(
              onPressed: () => _deApproveTransaction(transactionId, transactions.first),
              icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
              label: const Text('Remove Status', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
        if (comment != null && comment.isNotEmpty) _buildCommentContainer(comment, Colors.red, 'Reason:'),
      ],
    );
  }

  Widget _buildPendingState(String transactionId, List<Collection> transactions, bool isCash) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => _showDeclineDialog(transactionId, transactions, isCash),
          child: const Text('Decline'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _showApprovalDialog(transactionId, transactions, isCash),
          child: const Text('Approve'),
        ),
      ],
    );
  }

  Widget _buildCommentContainer(String comment, Color color, String label) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CustomColors.textSecondary.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            comment,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}