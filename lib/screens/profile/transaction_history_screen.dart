import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Updated dummy data to match new TransactionModel
    final List<TransactionModel> transactions = [
      TransactionModel(
        id: 'TXN1001',
        userId: 'USER123',
        toolId: 'TOOL_DRILL_01',
        toolName: 'Bosch Drill',
        toolImage: 'assets/images/drill.jpg',
        amount: 240.0,
        date: DateTime.now().subtract(const Duration(days: 2)),
        status: TransactionStatus.completed,
        paymentMethod: 'UPI',
        transactionReference: 'user@okaxis',
      ),
      TransactionModel(
        id: 'TXN1002',
        userId: 'USER123',
        toolId: 'TOOL_LADDER_01',
        toolName: 'Foldable Ladder',
        toolImage: 'assets/images/ladder.jpg',
        amount: 160.0,
        date: DateTime.now().subtract(const Duration(days: 5)),
        status: TransactionStatus.completed,
        paymentMethod: 'Card',
        transactionReference: '**** 1234',
      ),
      TransactionModel(
        id: 'TXN1003',
        userId: 'USER123',
        toolId: 'TOOL_GARDEN_01',
        toolName: 'Garden Tool Set',
        toolImage: 'assets/images/garderning.jpg',
        amount: 60.0,
        date: DateTime.now().subtract(const Duration(days: 10)),
        status: TransactionStatus.cancelled,
        paymentMethod: 'UPI',
        transactionReference: 'user@okaxis',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        elevation: 0,
      ),
      body: transactions.isEmpty
          ? const Center(
              child: Text('No transactions yet'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return _buildTransactionCard(tx);
              },
            ),
    );
  }

  Widget _buildTransactionCard(TransactionModel tx) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  tx.toolImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.toolName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tx.paymentMethod} • ${_formatDate(tx.date)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  Text(
                    'Ref: ${tx.transactionReference}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${tx.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 4),
                _buildStatusChip(tx.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(TransactionStatus status) {
    Color color;
    String label;

    switch (status) {
      case TransactionStatus.completed:
        color = Colors.green;
        label = 'Completed';
        break;
      case TransactionStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case TransactionStatus.cancelled:
        color = Colors.red;
        label = 'Cancelled';
        break;
      case TransactionStatus.failed:
        color = Colors.redAccent;
        label = 'Failed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
