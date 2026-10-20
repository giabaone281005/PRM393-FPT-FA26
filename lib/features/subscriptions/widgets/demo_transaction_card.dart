import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/commerce_models.dart';

class DemoTransactionCard extends StatelessWidget {
  const DemoTransactionCard({
    super.key,
    required this.order,
    this.onResume,
    this.showParent = false,
  });
  final LearningOrder order;
  final VoidCallback? onResume;
  final bool showParent;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DEMO · ${order.label}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text('${formatVnd(order.amountVnd)} · không thu tiền thật'),
          Text(order.displayStatus),
          SelectableText('Mã đơn demo: ${order.id}'),
          if (order.transactionId != null)
            SelectableText('Giao dịch: ${order.transactionId}'),
          if (showParent) SelectableText('Phụ huynh: ${order.parentId}'),
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt.toLocal()),
          ),
          if (order.canResume && onResume != null)
            TextButton(
              onPressed: onResume,
              child: const Text('Tiếp tục thanh toán mô phỏng'),
            ),
        ],
      ),
    ),
  );
}
